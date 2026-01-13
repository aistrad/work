# CoreAgent 核心逻辑

> 源文件: `/home/aiscend/work/vibelife/apps/api/services/agent/core.py`

## 架构概述

CoreAgent 是 Claude Agent SDK 风格的单 Agent 架构，具备以下特性：

- Core Skill 始终加载（定义 Vibe 的人格）
- LLM 自主技能选择（无关键词匹配）
- 单 Agent 循环 + 工具调用
- 支持多技能融合的 Subagent

## use_skill 工具定义

```python
USE_SKILL_TOOL = {
    "type": "function",
    "function": {
        "name": "use_skill",
        "description": """激活专业技能来回答用户问题。

调用时机：
- 八字、命理、生辰、测算、算命、命盘 → skills: ["bazi"]
- 星座、星盘、占星、行星、上升 → skills: ["zodiac"]
- 职业、工作、跳槽、升职、创业 → skills: ["career"]
- 塔罗、牌阵、抽牌、占卜 → skills: ["tarot"]

重要：如果用户消息中已经包含了出生信息（如"我是1990年5月15日出生的"），
设置 birth_info_provided=true，系统将直接分析而不会弹出表单。""",
        "parameters": {
            "type": "object",
            "properties": {
                "skills": {
                    "type": "array",
                    "items": {"type": "string", "enum": ["bazi", "zodiac", "career", "tarot"]},
                    "description": "需要使用的技能列表"
                },
                "topic": {
                    "type": "string",
                    "enum": ["career", "relationship", "fortune", "health", "self", "general"],
                    "description": "用户关注的话题类型"
                },
                "birth_info_provided": {
                    "type": "boolean",
                    "description": "用户消息中是否已包含出生信息（年月日时）。如果用户说了出生日期，设为 true。"
                }
            },
            "required": ["skills", "topic"]
        }
    }
}
```

## System Prompt 构建流程

`_build_system_prompt(context)` 方法按以下顺序组装 prompt：

### 1. Core Skill (始终加载)

```python
if self._core_skill:
    parts.append(self._core_skill.content)
```

### 2. 技能触发规则 (无激活技能时)

```python
if triggers and not self._active_skills:
    trigger_rules = "\n## 技能触发规则\n\n当用户消息包含以下关键词时，必须调用 `use_skill` 工具激活对应技能：\n"
    for skill_name, keywords in triggers.items():
        trigger_rules += f"- **{skill_name}**: {', '.join(keywords)}\n"
    trigger_rules += "\n触发后，技能会自动收集必要信息。"
    parts.append(trigger_rules)
```

### 3. 专业 Skill (激活后)

```python
for skill_name in self._active_skills:
    skill = load_skill(skill_name)
    if skill:
        parts.append(f"\n---\n\n{skill.content}")
```

### 4. 用户上下文

#### 4.1 出生信息 (birth_info)

```python
birth_info = context.profile.get("birth_info", {})
if birth_info:
    prompt += f"\n\n## 用户出生信息\n用户已提供出生信息，可以直接调用展示工具：\n{json.dumps(birth_info, ensure_ascii=False)}"
```

#### 4.2 身份棱镜 (identity_prism)

```python
prism = context.profile.get("identity_prism", {})
if prism:
    identity_summary = {
        "core": prism.get("core", {}).get("summary", ""),
        "inner": prism.get("inner", {}).get("summary", ""),
        "outer": prism.get("outer", {}).get("summary", ""),
    }
    if any(identity_summary.values()):
        prompt += f"\n\n## 用户画像\n{json.dumps(identity_summary, ensure_ascii=False)}"
```

#### 4.3 生活上下文 (life_context)

```python
life_context = context.profile.get("life_context", {})
if life_context:
    lc_parts = []
    if life_context.get("concerns"):
        lc_parts.append(f"关注点: {', '.join(life_context['concerns'])}")
    if life_context.get("goals"):
        lc_parts.append(f"目标: {', '.join(life_context['goals'])}")
    if life_context.get("pain_points"):
        lc_parts.append(f"痛点: {', '.join(life_context['pain_points'])}")
    if lc_parts:
        prompt += f"\n\n## 用户生活上下文\n" + "\n".join(lc_parts)
```

#### 4.4 近期画像 (portrait - Hot Memory)

```python
if context.portrait and context.portrait.strip():
    prompt += f"\n\n## 用户画像 (近期)\n{context.portrait}"
```

#### 4.5 洞察记忆 (recent_insights - Cold Memory)

```python
if context.recent_insights:
    insights_text = "\n".join([
        f"- [{i.get('type', 'insight')}] {i.get('content', '')}"
        for i in context.recent_insights[:5]
    ])
    prompt += f"\n\n## 用户洞察记忆\n{insights_text}"
```

#### 4.6 命盘数据 (skill_data)

```python
if context.skill_data and self._active_skills:
    skill_data_parts = []
    for skill_name in self._active_skills:
        if skill_name == "bazi":
            bazi_data = context.skill_data.get("bazi", {})
            if bazi_data:
                chart = bazi_data.get("chart", {})
                if chart:
                    skill_data_parts.append(f"### 八字命盘数据\n{json.dumps(chart, ensure_ascii=False, indent=2)}")
        elif skill_name == "zodiac":
            zodiac_data = context.skill_data.get("zodiac", {})
            if zodiac_data:
                chart = zodiac_data.get("chart", {})
                if chart:
                    skill_data_parts.append(f"### 星盘数据\n{json.dumps(chart, ensure_ascii=False, indent=2)}")
    if skill_data_parts:
        prompt += "\n\n## 用户命盘数据\n" + "\n\n".join(skill_data_parts)
```

## 工具获取逻辑

`_get_current_tools(context)` 方法：

```python
def _get_current_tools(self, context: AgentContext) -> List[Dict[str, Any]]:
    tools = []

    # 无预设技能时，提供 use_skill 工具
    if not context.skill and not self._active_skills:
        tools.append(USE_SKILL_TOOL)

    # 添加技能专属工具
    for skill_name in self._active_skills:
        skill_tools = get_tools_for_skill(skill_name)
        tools.extend(skill_tools)

    return tools if tools else [USE_SKILL_TOOL]  # Fallback
```

## Hybrid Skill Switching

支持两种技能激活方式：

1. **前端指定** - `context.skill` 预设技能
2. **LLM 自主选择** - 通过 `use_skill` 工具

```python
# Hybrid skill switching: use context.skill if set, else let LLM decide
if context.skill:
    self._active_skills = [context.skill]
else:
    self._active_skills = []
```
