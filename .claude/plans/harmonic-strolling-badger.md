# 修复计划：Skill 激活后无法获取已有出生信息

## 问题描述

用户在 Phase 1 成功回答"我的生日是哪天"，但激活 jungastro 后系统又要求收集出生信息。

## 聊天记录注入机制

**是的，聊天记录会被注入！** 在 `core.py:531-539`：

```python
if context.history:
    filtered_history = self._filter_valid_history(context.history[-10:])
    for msg in filtered_history:
        messages.append(LLMMessage(...))  # 最多 10 条历史消息
```

**但问题是**：聊天记录只是 LLM 的输入消息，而 **SOP 规则**（`_build_sop_rules`）会在 System Prompt 中生成明确指令：

```python
# prompt_builder.py:302-311
if needs_birth and not status["has_birth_info"]:
    # 生成："用户还没有告诉你出生信息。下一步：调用 collect_birth_info"
elif needs_compute and not status["has_chart_data"]:
    # 生成："用户已提供出生信息，但还没有生成命盘。下一步：调用 calculate_zodiac"
```

**SOP 规则优先级高于聊天记录**，导致 LLM 忽略了用户在聊天中说过的生日信息。

## 根因分析

三层问题叠加：

| 层级 | 文件 | 问题 |
|-----|------|------|
| 1. 缓存加载 | `profile_cache.py:219` | `deps = [skill]` 只加载自身，不加载依赖 |
| 2. 配置缺失 | `jungastro/SKILL.md` | 缺少 `requires_skill_data: ["zodiac"]` |
| 3. 状态错判 | `prompt_builder.py:278-313` | SOP 规则基于不完整数据生成"需要收集出生信息" |

**数据流断裂点**：
```
Phase 2 激活 jungastro
  → get_cached_profile_with_skill(user_id, "jungastro")
  → deps = ["jungastro"]  ← 问题！应包含 zodiac
  → skill_data 缺少 zodiac 数据
  → _compute_sop_status: has_chart_data = False
  → LLM 被提示"需要收集出生信息"
```

## 修复方案

### 方案 A：配置驱动（推荐）

**P0 修复：让 Skill 声明自己的数据依赖**

1. **更新 `profile_cache.py:217-219`**：
```python
# 改前
deps = [skill]

# 改后
from services.agent.skill_loader import get_skill_required_data
deps = get_skill_required_data(skill) if skill else []
if skill and skill not in deps:
    deps.append(skill)
```

2. **更新各 Skill 的 SKILL.md**（添加 `requires_skill_data`）：
   - `jungastro/SKILL.md`: `requires_skill_data: ["zodiac"]`
   - `synastry/SKILL.md`: `requires_skill_data: ["zodiac", "bazi"]`（如需）

### 方案 B：双来源检查

**P1 优化：`_compute_sop_status` 同时检查 profile 和 skill_data**

```python
# core.py _compute_sop_status
identity = context.profile.get("identity", {}) if context.profile else {}
birth_info = identity.get("birth_info", {})
has_birth = bool(birth_info.get("birth_date") or birth_info.get("date"))

# 即使 skill_data 没有 chart，但 profile 有 birth_info 也算"有"
```

## 修改文件清单

| 文件 | 修改内容 |
|------|----------|
| `stores/profile_cache.py` | 使用 `get_skill_required_data` 加载依赖 |
| `skills/jungastro/SKILL.md` | 添加 `requires_skill_data: ["zodiac"]` |
| `skills/synastry/SKILL.md` | 检查并添加依赖声明 |
| `services/agent/skill_loader.py` | 确保 `get_skill_required_data` 被正确导出 |

## 验证步骤

1. 启动测试环境
2. 用户先说"我的生日是1990年1月15日下午2点30分"
3. 确认 Phase 1 正确保存出生信息
4. 用户说"帮我做荣格深度分析"
5. 验证 jungastro 激活后**不再**要求收集出生信息
6. 验证 jungastro 能正确调用 `calculate_zodiac` 进行计算

## 关于聊天记录的设计问题

**问题**：jungastro 的 SKILL.md 能从聊天上下文获取用户信息吗？

**答案**：理论上可以，但当前架构有障碍：

1. **聊天记录确实被注入**（`context.history` → 最多 10 条消息）
2. **但 SOP 规则覆盖了 LLM 的判断**：System Prompt 中明确写"用户还没有告诉你出生信息"
3. **LLM 倾向于遵循 System Prompt 的明确指令**，而非从聊天记录推断

**解决方案 C：LLM-First（修改 SKILL.md）**

在 `jungastro/SKILL.md` 增加规则：

```markdown
## 出生信息获取（重要！）

1. **优先检查聊天记录**：用户可能在本次对话中已说过生日
2. **其次调用 read**：`read(path="identity.birth_info")` 检查 profile
3. **若都没有**：才调用 `collect_birth_info`

**如果用户在聊天中说过生日，先用 `save` 保存，再进行分析。**
```

## 推荐修复顺序

| 优先级 | 修改 | 说明 |
|-------|------|------|
| P0 | `profile_cache.py` | 修复 Skill 依赖加载 |
| P0 | `jungastro/SKILL.md` | 添加依赖声明 + 出生信息获取规则 |
| P1 | 其他相关 Skill | 检查 synastry、vibe_id |
