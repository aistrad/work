---
id: skill-spec-v9
name: Skill 完整规范（V9）
impact: CRITICAL
tags: V9, 架构, SKILL.md, 工具定义
---

# VibeLife Skill 规范 V9

## 1. V9 核心变化

### 1.1 与 V12 对比

| 维度 | V12 | V9 |
|------|-----|-----|
| **Skill 依赖** | routing.yaml 的 `includes`/`skill_data` | LLM 调用 `activate_skills(["a","b"])` |
| **工具发现** | 硬编码配置 | description 内嵌工具列表 |
| **SOP 配置** | routing.yaml 的 `requires_*` 字段 | SKILL.md 的强制工具调用规则 |
| **全局工具** | routing.yaml 的 `global_tools` | Core 工具始终可用 |
| **加载方式** | 全量加载 | 渐进式（frontmatter → 完整内容） |

### 1.2 两层架构

```
┌─────────────────────────────────────────────────────────────┐
│  Core Layer (全程激活，全文加载)                              │
│  └─ core: 生命对话者 + 7 个原子工具                          │
├─────────────────────────────────────────────────────────────┤
│  Skill Layer (按需激活，渐进加载)                            │
│  └─ bazi, zodiac, synastry, lifecoach, ...                  │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Core 的 7 个原子工具

| 工具 | 用途 |
|-----|------|
| `activate_skills` | 激活一个或多个 Skill |
| `ask` | 向用户提问或请求信息 |
| `save` | 保存数据到用户档案 |
| `read` | 读取用户数据 |
| `search` | 检索知识库 |
| `show` | 展示内容（卡片/列表/推荐） |
| `remind` | 管理提醒 |

---

## 2. SKILL.md 规范

### 2.1 Frontmatter 必填字段

```yaml
---
id: {skill_id}           # 英文小写，kebab-case
name: {中文名称}
version: 1.0.0
description: |
  {一句话功能描述}。
  工具：{tool1}, {tool2}, {tool3}    # ← V9 要求：内嵌工具列表
triggers:
  - {触发词1}
  - {触发词2}
category: {astrology|wellness|professional|relationship}
---
```

### 2.2 内容结构（<500 tokens）

```markdown
# {Skill 中文名}

## 专家身份
{精简的专家角色描述}

**强制工具调用规则**：
- 禁止编造数据，必须调用 `{compute_tool}`
- 计算完成后必须调用 `{display_tool}` 展示卡片

## 核心能力索引
| 能力 | 规则文件 | 触发场景 |
|-----|---------|---------|
| {能力1} | `rules/{file}.md` | {场景} |

## 工具快速参考
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `{tool}` | {用途} | {场景} |

## 伦理边界
- {禁止事项}
```

### 2.3 精简原则

- **目标**：<500 tokens
- **方法**：详细规则移到 `rules/*.md`
- **保留**：专家身份、强制工具调用规则、能力索引表、工具快速参考

---

## 3. 目录结构

```
apps/api/skills/{skill_id}/
├── SKILL.md              # 精简版（<500 tokens）
├── rules/                # 详细规则（按需加载）
│   ├── _index.md         # 规则索引
│   └── {capability}.md   # 各能力规则
├── tools/
│   ├── tools.yaml        # 工具 Schema
│   └── handlers.py       # 工具执行器
└── services/             # 业务逻辑（可选）
    └── api.py
```

---

## 4. tools.yaml 规范

```yaml
version: "2.0"
skill_id: {skill_id}

tools:
  # 收集工具
  - name: collect_{skill_id}_info
    type: collect
    description: 收集用户信息
    card_type: collect_form
    when_to_call: 用户未提供必要信息时
    parameters:
      - name: form_type
        type: string
        required: true

  # 计算工具
  - name: calculate_{skill_id}
    type: compute
    description: 计算{功能}
    when_to_call: 用户提供信息后
    parameters:
      - name: data
        type: object
        required: true

  # 展示工具
  - name: show_{skill_id}_chart
    type: display
    description: 展示{结果}卡片
    card_type: {skill_id}_chart
    when_to_call: 计算完成后
    parameters:
      - name: chart_data
        type: object
        required: true
```

---

## 5. handlers.py 规范

```python
"""
{Skill Name} Tool Handlers
使用 @tool_handler 装饰器注册，自动被 ToolRegistry 发现。
"""
from typing import Dict, Any
from services.agent.tool_registry import tool_handler, ToolContext, ToolRegistry

@tool_handler("calculate_{skill_id}")
async def execute_calculate(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """计算工具"""
    # 1. 数据优先级链：args > profile
    profile = context.profile or {}
    data = args.get("data") or profile.get("identity", {}).get("data")

    # 2. 快速失败
    if not data:
        return {"status": "error", "error": "需要数据", "action": "collect_{skill_id}_info"}

    # 3. 执行计算
    result = do_calculation(data)

    # 4. 委托展示
    return await ToolRegistry.execute("show_card", {
        "card_type": "custom",
        "data_source": {"type": "inline", "data": result},
        "options": {"componentId": "{skill_id}_chart"}
    }, context)
```

---

## 6. 迁移检查清单

### SKILL.md
- [ ] description 包含工具列表
- [ ] 内容 <500 tokens
- [ ] 有强制工具调用规则
- [ ] 详细规则移到 rules/*.md

### routing.yaml
- [ ] 删除 `includes` 配置
- [ ] 删除 `skill_data` 配置
- [ ] 保留 `triggers`（供 Phase 1 使用）

### 代码
- [ ] handlers.py 使用 `@tool_handler` 装饰器
- [ ] 展示工具委托给 `show_card`
- [ ] 前端卡片使用懒加载注册
