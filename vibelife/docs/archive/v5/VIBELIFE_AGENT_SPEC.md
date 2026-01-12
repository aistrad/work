# VibeLife Agent 规范 v5.0

## 概述

VibeLife Agent 系统基于 Claude Agent SDK 的设计理念，实现了一个支持多 Skill 的对话 Agent 框架。

## 核心组件

### 1. CoreAgent

主 Agent，负责：
- 接收用户消息
- 选择合适的 Skill
- 执行工具调用
- 生成回复

```python
from services.agent import CoreAgent, AgentContext

agent = CoreAgent(max_iterations=10)

context = AgentContext(
    user_id="user-123",
    user_tier="pro",
    profile={...},
    skill_data={...},
    history=[...]
)

async for event in agent.run(message, context):
    handle_event(event)
```

### 2. AgentContext

执行上下文，包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | str | 用户 ID |
| `user_tier` | str | 用户等级 (free/pro/vip) |
| `profile` | dict | 用户画像 |
| `skill_data` | dict | Skill 相关数据 |
| `history` | list | 对话历史 |

### 3. AgentEvent

Agent 执行过程中产生的事件：

| 类型 | 说明 | 数据 |
|------|------|------|
| `thinking` | 思考中 | `{iteration: int}` |
| `content` | 文本内容 | `{content: str}` |
| `tool_call` | 工具调用 | `{id, name, arguments}` |
| `tool_result` | 工具结果 | `{id, name, result}` |
| `done` | 完成 | `{content: str}` |
| `error` | 错误 | `{error: str}` |

### 4. SkillLoader

Skill 加载器，负责：
- 解析 SKILL.md 文件
- 构建 System Prompt
- 管理 Skill 生命周期

```python
from services.agent import load_skill, build_system_prompt

# 加载单个 Skill
skill = load_skill("bazi")

# 构建 System Prompt
prompt = build_system_prompt(["bazi"], include_core=True)
```

## Agent 循环

```
┌─────────────────────────────────────────────────────────────┐
│                      Agent Loop                              │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Build   │───▶│  Call    │───▶│  Check   │              │
│  │ Messages │    │   LLM    │    │ Response │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│       ▲                               │                      │
│       │                               ▼                      │
│       │                    ┌──────────────────┐             │
│       │                    │  Has Tool Call?  │             │
│       │                    └──────────────────┘             │
│       │                      │           │                   │
│       │                     Yes          No                  │
│       │                      │           │                   │
│       │                      ▼           ▼                   │
│       │              ┌──────────┐  ┌──────────┐             │
│       └──────────────│ Execute  │  │  Return  │             │
│                      │   Tool   │  │  Result  │             │
│                      └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────────┘
```

### 循环流程

1. **构建消息**: System Prompt + History + User Message
2. **调用 LLM**: 发送消息和工具定义
3. **检查响应**:
   - 有 Tool Call → 执行工具 → 回到步骤 1
   - 无 Tool Call → 返回结果
4. **最大迭代**: 默认 10 次，防止无限循环

## 工具系统

### 工具定义

```python
TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "tool_name",
        "description": "工具描述",
        "parameters": {
            "type": "object",
            "properties": {
                "param1": {"type": "string", "description": "参数1"},
                "param2": {"type": "boolean", "default": True}
            },
            "required": ["param1"]
        }
    }
}
```

### 工具执行

```python
async def execute_tool(tool_name: str, tool_args: dict, context: AgentContext) -> dict:
    if tool_name == "use_skill":
        return await handle_use_skill(tool_args, context)
    elif is_ui_tool(tool_name):
        return await execute_ui_tool(tool_name, tool_args, context)
    else:
        return {"status": "unknown_tool"}
```

### 内置工具

| 工具 | 说明 |
|------|------|
| `use_skill` | 选择 Skill |
| `search_knowledge` | RAG 检索 |
| `show_report` | 展示报告 |
| `show_insight` | 展示洞察 |

## Skill 选择

### use_skill 工具

```python
USE_SKILL_TOOL = {
    "type": "function",
    "function": {
        "name": "use_skill",
        "description": "选择使用的技能来回答用户问题",
        "parameters": {
            "type": "object",
            "properties": {
                "skills": {
                    "type": "array",
                    "items": {"type": "string", "enum": ["bazi", "zodiac"]},
                    "description": "需要使用的技能列表"
                },
                "topic": {
                    "type": "string",
                    "enum": ["career", "relationship", "fortune", "health", "self", "general"],
                    "description": "用户关注的话题类型"
                }
            },
            "required": ["skills", "topic"]
        }
    }
}
```

### 选择流程

1. LLM 分析用户问题
2. 调用 `use_skill` 选择合适的 Skill
3. SkillLoader 加载选中的 Skill
4. 重新构建 System Prompt
5. 继续对话

## 多 Skill 融合

当选择多个 Skill 时，使用 SubAgent 并行分析：

```python
async def run_subagents(skills: List[str], topic: str, context: AgentContext):
    tasks = []
    for skill in skills:
        subagent = SkillSubAgent(skill)
        tasks.append(subagent.analyze(topic, context))

    results = await asyncio.gather(*tasks)
    return fuse_results(results)
```

## 配额管理

### QuotaTracker

```python
from services.agent import QuotaTracker

# 检查配额
ok, message = await QuotaTracker.check(user_id, tier)

# 记录使用
await QuotaTracker.record(user_id, usage)
```

### 配额限制

| 等级 | 每日对话 | 每日 Token |
|------|---------|-----------|
| free | 10 | 50,000 |
| pro | 100 | 500,000 |
| vip | 无限 | 无限 |

## SSE 事件格式

### Vercel AI SDK 6 兼容

```json
// 文本内容
{"type": "text-delta", "textDelta": "..."}

// 工具调用
{"type": "tool-input-available", "toolCallId": "...", "toolName": "...", "input": {...}}

// 工具结果
{"type": "tool-output-available", "toolCallId": "...", "output": {...}}

// 完成
{"type": "finish", "finishReason": "stop"}
```

## API 端点

### POST /chat/v5/stream

主要对话端点。

**请求**:
```json
{
  "message": "帮我看看我的八字",
  "conversation_id": "uuid (可选)"
}
```

**响应**: SSE 事件流

### POST /chat/v5/guest/stream

访客端点，无需认证，功能受限。

## 错误处理

### 错误类型

| 类型 | 说明 |
|------|------|
| `quota_exceeded` | 配额超限 |
| `agent-error` | Agent 执行错误 |
| `internal_error` | 内部错误 |

### 错误响应

```json
{
  "event": "error",
  "data": {
    "type": "quota_exceeded",
    "message": "今日对话次数已用完",
    "tier": "free"
  }
}
```

## 最佳实践

### 1. 合理设置 max_iterations

- 简单对话: 5
- 复杂分析: 10
- 访客模式: 3

### 2. 优化 System Prompt

- Core Skill 控制在 2000 tokens 以内
- 专业 Skill 控制在 1500 tokens 以内
- 总 System Prompt 不超过 5000 tokens

### 3. 工具设计原则

- 单一职责
- 清晰的参数定义
- 有意义的返回值

### 4. 错误恢复

- 工具执行失败时返回错误信息
- Agent 可以根据错误信息调整策略
- 设置合理的超时时间
