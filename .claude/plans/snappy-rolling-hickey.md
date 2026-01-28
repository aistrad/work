# Agent 服务 Review 计划 - 适配 VibeProfile v8.0 三层架构

## 核心问题

**Lifecoach 数据存储位置特殊**，导致 Layer 2 注入失效：

```
命理类 Skill (bazi, zodiac)：
  └─ profile.skills.{skill_id} 或 profile.skill_data.{skill_id}

教练类 Skill (lifecoach)：
  └─ profile.life_context._paths.lifecoach.content  ← 完全不同的路径！
```

当前 `_build_profile_context` 的 Layer 2 只读取 `skill_data`，**lifecoach 的数据（north_star, goals, identity 等）永远不会被注入到 prompt**。

---

## 问题清单

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 1 | lifecoach 数据在 life_context，不在 skills | 数据层 | **高** - 教练无法看到用户目标 |
| 2 | 遗留硬编码集合（未使用） | prompt_builder.py:43-46 | 低 - 仅影响代码整洁 |
| 3 | 兼容层代码未标记 | 多处 | 低 - 影响可维护性 |

---

## 修复方案：配置驱动 + Layer 2 扩展

### 原则
- 不新增硬编码（如 `LIFE_CONTEXT_SKILLS`）
- 在 SKILL.md 声明数据来源
- 代码根据配置从不同位置读取

### Step 1: 更新 SKILL.md 配置

```yaml
# skills/lifecoach/SKILL.md
---
name: lifecoach
data_source: life_context  # 新增：声明数据来源（默认 skills）
---
```

### Step 2: 添加配置查询函数

```python
# skill_loader.py
def get_skill_data_source(skill_id: str) -> str:
    """获取 Skill 数据来源（配置驱动）

    返回值：
    - "skills": 默认，从 profile.skills.{skill_id} 读取
    - "life_context": 从 profile.life_context._paths.{skill_id}.content 读取
    """
    skill = load_skill(skill_id)
    return skill.data_source if skill and skill.data_source else "skills"
```

### Step 3: 修改 _build_profile_context Layer 2

```python
# prompt_builder.py
def _build_profile_context(self, profile, skill_data, skill_id):
    # ...Layer 1...

    # Layer 2: Skills（配置驱动数据来源）
    skill_ids = get_skill_required_data(skill_id)

    for sid in skill_ids:
        data_source = get_skill_data_source(sid)

        if data_source == "life_context":
            # 从 life_context._paths.{skill_id}.content 读取
            data = profile.get("life_context", {}).get("_paths", {}).get(sid, {}).get("content", {})
        else:
            # 默认从 skills 读取，回退到 skill_data
            data = skill_data.get(sid, {})

        if data:
            # 过滤内部字段后注入
            ...
```

### Step 4: 清理遗留代码

删除 `prompt_builder.py` 中未使用的硬编码：
```python
# 删除这两行
PORTRAIT_FULL_SKILLS = {"lifecoach", "career"}
BIRTH_INFO_SKILLS = {"bazi", "zodiac", "jungastro"}
```

### Step 5: 添加迁移注释

在所有兼容层代码添加：
```python
# ⚠️ MIGRATION v8.0: [描述]
# TODO: v11.0 移除此回退逻辑
```

---

## 修改文件清单

| 文件 | 修改内容 |
|------|---------|
| `skills/lifecoach/SKILL.md` | 添加 `data_source: life_context` |
| `skill_loader.py` | 添加 `data_source` 字段和 `get_skill_data_source()` 函数 |
| `prompt_builder.py` | 修改 Layer 2 读取逻辑，删除硬编码集合 |
| `context_manager.py:394` | 添加迁移注释 |
| `skill_loader.py:955-961` | 添加迁移注释 |

---

## 验证方案

```bash
# 1. 语法检查
python -m py_compile services/agent/prompt_builder.py services/agent/skill_loader.py

# 2. 配置函数测试
python -c "
from services.agent.skill_loader import get_skill_data_source
assert get_skill_data_source('lifecoach') == 'life_context'
assert get_skill_data_source('bazi') == 'skills'
print('OK')
"

# 3. 集成测试
python scripts/test_coreagent_claude.py
```

---

## 数据流示意

```
修复前：
  profile.life_context._paths.lifecoach.content
       │
       └── 不被读取 ❌

修复后：
  profile.life_context._paths.lifecoach.content
       │
       └── data_source="life_context" 配置 → Layer 2 读取 ✓
```
