# Profile 注入机制设计 - 简化版

> **目标**: 让所有 Skill 自动获得用户上下文
> **原则**: 简单、通用、无需配置

---

## 一、核心设计

### 1.1 统一注入所有 Skill

**不区分 Skill 类型**，统一注入以下信息：

```
## 用户画像

**称呼**: 小明
**当前关注**: 事业发展、健康管理
**用户目标**: 升职加薪、改善睡眠
**关注点**: 工作压力大、时间不够用
**行为特征**: 容易拖延、目标不清晰
**背景**: 30岁、互联网行业、已婚
```

### 1.2 数据来源

| 字段 | Profile 路径 | 说明 |
|------|-------------|------|
| 称呼 | `identity.display_name` | 用户昵称 |
| 当前关注 | `state.focus[]` | 最近关注的领域 |
| 用户目标 | `extracted.goals[]` | 从对话中提取的目标 |
| 关注点 | `extracted.concerns[]` | 用户关心的问题 |
| 行为特征 | `extracted.patterns[]` | 行为模式 |
| 背景 | `extracted.facts[]` | 基本事实 |

---

## 二、实现方案

### 2.1 修改 PromptBuilder

在 `prompt_builder.py` 的 `build()` 方法中添加：

```python
async def build(self, skill_id, rule_id, message, profile, ...):
    parts = []

    if skill_id:
        # 1. Skill 专家身份
        skill = load_skill(skill_id)
        parts.append(f"# {skill.name}\n\n{skill.expert_persona}")

        # 2. 用户画像注入（新增）
        if profile:
            portrait = self._build_user_portrait(profile)
            if portrait:
                parts.append(portrait)

        # 3. 规则/场景 ...
```

### 2.2 _build_user_portrait 方法

```python
def _build_user_portrait(self, profile: Dict[str, Any]) -> str:
    """构建用户画像 Prompt"""
    if not profile:
        return ""

    lines = ["## 用户画像\n"]

    # 称呼
    identity = profile.get("identity", {})
    if identity.get("display_name"):
        lines.append(f"**称呼**: {identity['display_name']}")

    # 当前关注
    state = profile.get("state", {})
    focus = state.get("focus", [])
    if focus:
        lines.append(f"**当前关注**: {', '.join(focus[:3])}")

    # 提取的信息
    extracted = profile.get("extracted", {})

    if extracted.get("goals"):
        lines.append(f"**用户目标**: {', '.join(extracted['goals'][:3])}")

    if extracted.get("concerns"):
        lines.append(f"**关注点**: {', '.join(extracted['concerns'][:3])}")

    if extracted.get("patterns"):
        lines.append(f"**行为特征**: {', '.join(extracted['patterns'][:2])}")

    if extracted.get("facts"):
        lines.append(f"**背景**: {'; '.join(extracted['facts'][:3])}")

    # 如果没有任何内容，返回空
    if len(lines) <= 1:
        return ""

    lines.append("\n---\n")
    return "\n".join(lines)
```

---

## 三、文件修改

| 文件 | 修改 |
|------|------|
| `services/agent/prompt_builder.py` | 添加 `_build_user_portrait()` 方法，在 `build()` 中调用 |

---

## 四、验证

```
1. 用户有 extracted 数据
2. 进入任意 Skill
3. 检查 System Prompt 包含「## 用户画像」section
4. 验证信息正确显示
```
