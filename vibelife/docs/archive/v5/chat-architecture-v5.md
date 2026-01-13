# VibeLife V5 Chat 架构设计

> Version: 1.0 | 2026-01-13
> 方案 B: Python V5 API 主导 + AI SDK 6 兼容

## 架构概述

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    方案 B: Python CoreAgent 主导                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Browser (AI SDK 6)                      Python API (8100)                      │
│       │                                        │                                │
│       │  useVibeChat                           │                                │
│       │  + DefaultChatTransport                │                                │
│       │────────────────────────────────────────>                                │
│       │  POST /api/v1/chat/v5/stream           │                                │
│       │                                        │                                │
│       │                                   CoreAgent                             │
│       │                                   ├─ Skill 选择                         │
│       │                                   ├─ Tool calling                       │
│       │                                   └─ Claude API                         │
│       │                                        │                                │
│       │<────────────────────────────────────────                                │
│       │  SSE (AI SDK 6 Data Stream Protocol)   │                                │
│       │                                        │                                │
│       │  useChat 解析 SSE                      │                                │
│       │  更新 messages 状态                    │                                │
│       │  渲染 ChatMessage + Tool UI            │                                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 核心设计原则

1. **LLM 调用统一在后端** - 符合 LLM 调用规范，配置集中管理
2. **CoreAgent 智能路由** - LLM 决定 Skill 选择，无关键词匹配
3. **AI SDK 6 兼容** - SSE 格式匹配 Data Stream Protocol
4. **Tool calling + Generative UI** - 后端返回 tool_call，前端渲染交互组件

## 时序图

### Chat 流程

```
┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐
│ Browser │          │ Next.js │          │ Python  │          │ Claude  │
│         │          │ (8232)  │          │ (8100)  │          │  API    │
└────┬────┘          └────┬────┘          └────┬────┘          └────┬���───┘
     │                    │                    │                    │
     │  用户输入消息       │                    │                    │
     │  sendMessage()     │                    │                    │
     │────────────────────┼────────────────────>                    │
     │  POST /api/v1/chat/v5/stream            │                    │
     │  (直接调用后端，绕过 Next.js)            │                    │
     │                    │                    │                    │
     │                    │                    │  CoreAgent.run()   │
     │                    │                    │────────────────────>
     │                    │                    │  stream messages   │
     │                    │                    │                    │
     │                    │                    │<────────────────────
     │                    │                    │  SSE chunks        │
     │                    │                    │                    │
     │<────────────────────────────────────────│                    │
     │  SSE: text-delta / tool-call / finish   │                    │
     │                    │                    │                    │
     │  useChat 解析      │                    │                    │
     │  更新 messages     │                    │                    │
     │  渲染 UI           │                    │                    │
     │                    │                    │                    │
```

### DailyGreeting 流程（独立）

```
┌─────────┐          ┌─────────┐          ┌────��────┐
│ Browser │          │ Next.js │          │ Python  │
│         │          │ (8232)  │          │ (8100)  │
└────┬────┘          └────┬────┘          └────┬────┘
     │                    │                    │
     │  页面加载           │                    │
     │  useDailyGreeting  │                    │
     │───────────────────>│                    │
     │  GET /api/fortune/greeting              │
     │                    │                    │
     │                    │───────────────────>│
     │                    │  POST /api/v1/fortune/greeting
     │                    │                    │
     │                    │<───────────────────│
     │                    │  JSON 响应          │
     │                    │                    │
     │<───────────────────│                    │
     │  JSON 响应          │                    │
     │                    │                    │
     │  渲染 DailyGreeting │                    │
     │                    │                    │
```

## SSE 格式规范

### AI SDK 6 Data Stream Protocol

后端必须返回符合 AI SDK 6 格式的 SSE：

```
# 文本内容
event: message
data: {"type":"text-delta","id":"msg_001","delta":"你好"}

# 工具调用开始
event: message
data: {"type":"tool-call","toolCallId":"tc_001","toolName":"show_bazi_chart","args":{}}

# 工具结果
event: message
data: {"type":"tool-result","toolCallId":"tc_001","result":{"chart":{...}}}

# 完成
event: message
data: {"type":"finish","finishReason":"stop"}
```

### 当前格式 vs 目标格式

| 字段 | 当前格式 | 目标格式 |
|------|---------|---------|
| 文本 | `{"type":"text-delta","textDelta":"你"}` | `{"type":"text-delta","id":"xxx","delta":"你"}` |
| 工具调用 | `{"type":"tool-input-available",...}` | `{"type":"tool-call",...}` |
| 工具结果 | `{"type":"tool-output-available",...}` | `{"type":"tool-result",...}` |

## 后端实现

### 文件结构

```
apps/api/
├── routes/
│   └── chat_v5.py           # V5 Chat 端点
├── services/
│   ├── agent/
│   │   ├── core.py          # CoreAgent 核心
│   │   ├── skill_loader.py  # Skill 加载器
│   │   └── quota.py         # 配额管理
│   └── llm/
│       ├── client.py        # 统一 LLM 客户端
│       └── config.py        # 模型配置
└── config/
    └── models.yaml          # 模型配置（唯一配置源）
```

### CoreAgent 核心逻辑

```python
class CoreAgent:
    """Claude Agent SDK 风格的核心 Agent"""

    async def run(self, message: str, context: AgentContext):
        """
        Agent 主循环

        1. 构建 system prompt (Core Skill + 用户画像)
        2. 调用 LLM (Claude API)
        3. 处理 tool calls
        4. 返回 SSE 流
        """
        messages = self._build_initial_messages(message, context)

        for iteration in range(self.max_iterations):
            # 流式调用 LLM
            async for chunk in self.llm.stream(messages, tools):
                if chunk["type"] == "content":
                    yield AgentEvent(type="content", data=chunk)
                elif chunk["type"] == "tool_call":
                    # 执行工具
                    result = await self._execute_tool(chunk)
                    yield AgentEvent(type="tool_result", data=result)

            # 无工具调用则完成
            if not tool_calls:
                yield AgentEvent(type="done")
                return
```

### SSE 格式转换

```python
# chat_v5.py - 修改 SSE 格式以匹配 AI SDK 6

async def generate():
    message_id = str(uuid4())

    async for event in agent.run(request.message, context):
        if event.type == "content":
            yield {
                "event": "message",
                "data": json.dumps({
                    "type": "text-delta",
                    "id": message_id,
                    "delta": event.data.get("content", "")
                })
            }

        elif event.type == "tool_call":
            yield {
                "event": "message",
                "data": json.dumps({
                    "type": "tool-call",
                    "toolCallId": event.data.get("id"),
                    "toolName": event.data.get("name"),
                    "args": json.loads(event.data.get("arguments", "{}"))
                })
            }

        elif event.type == "tool_result":
            yield {
                "event": "message",
                "data": json.dumps({
                    "type": "tool-result",
                    "toolCallId": event.data.get("id"),
                    "result": event.data.get("result")
                })
            }

        elif event.type == "done":
            yield {
                "event": "message",
                "data": json.dumps({
                    "type": "finish",
                    "finishReason": "stop"
                })
            }
```

## 前端实现

### 文件结构

```
apps/web/src/
├── hooks/
│   └── useVibeChat.ts       # AI SDK 6 useChat wrapper
├── components/
│   └── chat/
│       ├── ChatContainer.tsx
│       ├── ChatMessage.tsx
│       └── ChatInput.tsx
└── skills/
    ├── bazi/
    │   └── tools/
    │       └── show-bazi-chart.tsx  # Generative UI
    └── shared-tools.tsx
```

### useVibeChat Hook

```typescript
// hooks/useVibeChat.ts
export function useVibeChat({ skillId, voiceMode, conversationId }) {
  const transport = useMemo(() => {
    const apiBase = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000';
    return new DefaultChatTransport({
      api: `${apiBase}/api/v1/chat/v5/stream`,
      headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : undefined,
      body: {
        skill: skillId,
        voice_mode: voiceMode,
        conversation_id: conversationId,
      },
    });
  }, [skillId, voiceMode, conversationId]);

  const chat = useChat({
    transport,
    onFinish: ({ message }) => { /* ... */ },
    onError: (error) => { /* ... */ },
  });

  return {
    messages: chat.messages,
    isLoading: chat.status === 'submitted' || chat.status === 'streaming',
    sendMessage: (content) => chat.sendMessage({ text: content }),
    // ...
  };
}
```

### Tool UI 渲染

```typescript
// components/chat/ChatMessage.tsx
function ChatMessage({ role, content, toolInvocations }) {
  return (
    <div data-role={role}>
      {/* 文本内容 */}
      {content && <div className="message-content">{content}</div>}

      {/* Tool UI */}
      {toolInvocations?.map((tool) => (
        <ToolRenderer key={tool.toolCallId} tool={tool} />
      ))}
    </div>
  );
}

function ToolRenderer({ tool }) {
  switch (tool.toolName) {
    case 'show_bazi_chart':
      return <BaziChartCard data={tool.result} />;
    case 'request_info':
      return <InfoRequestForm args={tool.args} />;
    // ...
  }
}
```

## 体验实现映射

| 体验需求 | 实现方式 |
|---------|---------|
| 打字机效果 | SSE `text-delta` 流式返回，前端控制渲染速度 |
| 墨水显影动画 | 纯前端 CSS/Framer Motion 动画 |
| 场景猜测卡片 | Tool calling: `request_info` → Generative UI |
| 洞察卡片 | Tool calling: `show_insight` → Generative UI |
| AI 头像状态 | 根据 SSE 事件类型切换 (thinking/streaming/done) |
| 消息气泡情感化 | 后端返回消息类型，前端渲染不同样式 |
| 记忆系统展示 | Tool calling: `save_memory` → UI 提示 |

## 配置

### models.yaml

```yaml
providers:
  claude:
    name: "Claude (代理)"
    base_url: "${CLAUDE_BASE_URL:https://www.zz166.cn/api/v1}"
    api_key_env: "CLAUDE_API_KEY"
    enabled: true
    timeout: 180

models:
  claude-opus:
    provider: claude
    model_name: "${CLAUDE_MODEL:claude-opus-4-5-20251101}"
    capabilities: [chat, analysis, tools]
    tier: premium

defaults:
  chat:
    primary: claude-opus
    fallback: [glm-4.7, deepseek-v3]
```

### .env.test

```bash
# Claude API
CLAUDE_API_KEY=cr_xxx
CLAUDE_BASE_URL=https://www.zz166.cn/api/v1
CLAUDE_MODEL=claude-opus-4-5-20251101

# 前端 API 地址
NEXT_PUBLIC_API_URL=http://106.37.170.238:8100
```

## 测试

### 端到端测试

```bash
# 启动测试环境
./scripts/start-test.sh

# 运行 Playwright 测试
npx playwright test tests/e2e/bazi-e2e-test.spec.ts
```

### API 测试

```bash
# 测试 V5 Chat 端点
curl -X POST http://localhost:8100/api/v1/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "你好"}'
```

## 迁移步骤

1. **修复 SSE 格式** - 修改 `chat_v5.py` 返回 AI SDK 6 兼容格式
2. **统一 LLM 调用** - 所有服务使用 `services/llm/client.py`
3. **测试验证** - 端到端测试确认前端正确渲染
4. **清理旧代码** - 移除 Next.js `/api/chat/route.ts` 中的 LLM 调用

## 参考

- [AI SDK 6 Documentation](https://sdk.vercel.ai/docs)
- [Claude API Documentation](https://docs.anthropic.com/claude/reference)
- [frontend-v5.md](../v0/frontend-v5.md) - 用户体验设计规范
