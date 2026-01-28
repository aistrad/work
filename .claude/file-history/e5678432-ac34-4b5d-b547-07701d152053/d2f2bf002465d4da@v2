# Vercel AI SDK 6.0 升级计划

**目标**: 将 Fortune AI 从 AI SDK v4.3.19 升级到 v6.0
**策略**: 尽快升级，可接受破坏性变更
**约束**: 保留 agent_service 观察，Nginx 已正确配置

---

## 核心问题

| 问题 | 位置 | 风险 |
|------|------|------|
| 手动流解析 | `lib/api.ts:540-668` | SDK 升级会直接断 |
| Tool 参数名 | `parameters` → `inputSchema` | 编译错误 |
| 响应方法 | `toDataStreamResponse()` 变更 | 格式不兼容 |
| 消息格式 | 需要 `UIMessage` + `convertToModelMessages()` | 解析错误 |

---

## 实施阶段

### Phase 1: 依赖升级与 Codemod (30min)

**文件**: `web-app/package.json`

```bash
cd /home/aiscend/work/fortune_ai/web-app
npm install ai@^6.0.0 @ai-sdk/openai@latest @ai-sdk/react@latest @ai-sdk/ui-utils@latest
npx @ai-sdk/codemod upgrade
```

**变更**:
```diff
- "ai": "^4.3.19",
- "@ai-sdk/openai": "^1.3.24",
+ "ai": "^6.0.0",
+ "@ai-sdk/openai": "^3.0.0",
+ "@ai-sdk/react": "^1.0.0",
+ "@ai-sdk/ui-utils": "^1.0.0",
```

---

### Phase 2: Tool 定义更新 (1h)

**文件**:
- `web-app/src/lib/skills/divine-skills.ts`
- `web-app/src/lib/skills/heal-skills.ts`
- `web-app/src/lib/skills/grow-skills.ts`

**变更**: `parameters` → `inputSchema`

```diff
// divine-skills.ts:52-59
calculate_bazi: tool({
  description: '计算用户的八字命盘...',
- parameters: z.object({
+ inputSchema: z.object({
    birth_datetime: z.string().describe('...'),
    ...
  }),
  execute: async ({ birth_datetime, ... }) => {...},
}),
```

**影响范围**:
- `calculate_bazi` (line 52)
- `get_yunshi` (line 131)
- `init_tieban` (line 187)
- `heal-skills.ts` 中所有 tool 定义
- `grow-skills.ts` 中所有 tool 定义

---

### Phase 3: 后端 API Route 更新 (1h)

**文件**: `web-app/src/app/api/chat/route.ts`

**3.1 导入更新**:
```diff
- import { streamText } from 'ai';
+ import { streamText, convertToModelMessages, UIMessage } from 'ai';
```

**3.2 消息转换** (line 116):
```diff
- const messages = buildMessages(context, message);
+ const rawMessages = buildMessages(context, message);
+ const messages = convertToModelMessages(rawMessages);
```

**3.3 响应方法** (line 188):
```diff
- const response = result.toDataStreamResponse();
+ const response = result.toUIMessageStreamResponse({
+   originalMessages: rawMessages,
+   generateMessageId: () => crypto.randomUUID(),
+ });
```

---

### Phase 4: 消息构建器更新 (30min)

**文件**: `web-app/src/lib/context/context-builder.ts`

**更新 `buildMessages()` 返回 `UIMessage[]`**:

```typescript
import { UIMessage } from 'ai';

export function buildMessages(
  context: UserContext,
  userMessage: string
): UIMessage[] {
  const messages: UIMessage[] = [];

  for (const msg of context.history) {
    if (msg.role === 'user' || msg.role === 'assistant') {
      messages.push({
        id: crypto.randomUUID(),
        role: msg.role as 'user' | 'assistant',
        parts: [{ type: 'text', text: msg.content }],
        createdAt: new Date(),
      });
    }
  }

  messages.push({
    id: crypto.randomUUID(),
    role: 'user',
    parts: [{ type: 'text', text: userMessage }],
    createdAt: new Date(),
  });

  return messages;
}
```

---

### Phase 5: 前端流解析替换 (2-3h) - 关键步骤

**文件**: `web-app/src/lib/api.ts`

**删除手动解析** (lines 540-668)，替换为 SDK 官方解析器：

```typescript
import { parseUIMessageStream } from '@ai-sdk/ui-utils';

export async function streamChatMessageV6(
  message: string,
  sessionId: string | undefined,
  command: string | undefined,
  callbacks: {
    onMessage: (message: UIMessage) => void;
    onChunk: (text: string) => void;
    onToolCall: (toolInvocation: ToolInvocation) => void;
    onDone: (sessionId: string) => void;
    onError: (error: Error) => void;
  }
): Promise<() => void> {
  const controller = new AbortController();

  try {
    const response = await fetch(`${BASE_PATH}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        session_id: sessionId || null,
        message,
        command: command || null,
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Request failed: ${response.status}`);
    }

    const resolvedSessionId = response.headers.get('X-Session-Id') || sessionId || '';

    // 使用 SDK 官方解析器
    const stream = parseUIMessageStream(response.body!);

    for await (const part of stream) {
      switch (part.type) {
        case 'text':
          callbacks.onChunk(part.text);
          break;
        case 'tool-invocation':
          callbacks.onToolCall({
            toolCallId: part.toolInvocation.toolCallId,
            toolName: part.toolInvocation.toolName,
            args: part.toolInvocation.args,
            result: part.toolInvocation.result,
          });
          break;
        case 'message':
          callbacks.onMessage(part.message);
          break;
        case 'error':
          callbacks.onError(new Error(part.error));
          return;
      }
    }

    callbacks.onDone(resolvedSessionId);
  } catch (err) {
    if (err.name !== 'AbortError') {
      callbacks.onError(err);
    }
  }

  return () => controller.abort();
}
```

**更新 `streamChat()` (line 671)** 调用新函数。

---

### Phase 6: Zustand Store 适配 (1h)

**文件**: `web-app/src/stores/app-store.ts`

更新 `sendMessage` action 使用新的 `streamChatMessageV6`：

```typescript
sendMessage: async (content: string) => {
  // ... existing code ...

  api.streamChatMessageV6(
    messageText,
    sessionId,
    command,
    {
      onMessage: (msg) => {
        // 处理完整消息
      },
      onChunk: (chunk) => {
        // 更新流式文本
        set((state) => ({
          messages: state.messages.map((m) =>
            m.id === assistantMessage.id
              ? { ...m, content: m.content + chunk }
              : m
          ),
        }));
      },
      onToolCall: (invocation) => {
        // 处理工具调用
        console.log('[Tool]', invocation.toolName, invocation.result);
      },
      onDone: (newSessionId) => {
        set({ sessionId: newSessionId, isStreaming: false });
      },
      onError: (err) => {
        console.error('[Chat Error]', err);
        set({ isStreaming: false });
      },
    }
  );
},
```

---

### Phase 7: 清理旧代码 (30min)

**删除**:
- `lib/api.ts` 中的 `streamChatMessage()` (lines 435-537)
- `lib/api.ts` 中的 `streamChatMessageNew()` (lines 540-668)
- `USE_NEW_RUNTIME` 环境变量和相关逻辑

**更新 next.config.ts**:
删除不再需要的 legacy 重写：

```diff
// 删除这些重写 (lines 18-34)
- {
-   source: "/api/chat/stream",
-   destination: `${API_PROXY_TARGET}/api/chat/stream`,
- },
- {
-   source: "/api/chat/send",
-   destination: `${API_PROXY_TARGET}/api/chat/send`,
- },
- {
-   source: "/api/chat/ask",
-   destination: `${API_PROXY_TARGET}/api/chat/ask`,
- },
```

---

## 关键文件清单

| 文件 | 变更类型 | 优先级 |
|------|----------|--------|
| `web-app/package.json` | 依赖升级 | P0 |
| `web-app/src/lib/skills/divine-skills.ts` | parameters→inputSchema | P0 |
| `web-app/src/lib/skills/heal-skills.ts` | parameters→inputSchema | P0 |
| `web-app/src/lib/skills/grow-skills.ts` | parameters→inputSchema | P0 |
| `web-app/src/app/api/chat/route.ts` | 后端 API 更新 | P0 |
| `web-app/src/lib/context/context-builder.ts` | UIMessage 格式 | P0 |
| `web-app/src/lib/api.ts` | 替换手动解析器 | P0 |
| `web-app/src/stores/app-store.ts` | 适配新 API | P1 |
| `web-app/next.config.ts` | 删除 legacy 重写 | P2 |

---

## 验证清单

### 后端验证
- [ ] `npm run build` 无 TypeScript 错误
- [ ] `POST /new/api/chat` 返回 200
- [ ] 响应 Content-Type 为 `text/event-stream`
- [ ] Tool 调用正常执行
- [ ] `onFinish` 回调正常触发并持久化数据

### 前端验证
- [ ] 消息流式渲染正常
- [ ] Tool 结果显示正确（A2UI 卡片）
- [ ] Session ID 正确传递
- [ ] 错误处理正常

### E2E 验证
- [ ] 发送消息 → 收到流式响应
- [ ] 触发八字计算 → 显示命盘卡片
- [ ] 多步 Tool 调用正常

---

## 风险缓解

1. **编译失败**: Codemod 可能遗漏某些 `parameters`，需手动检查
2. **流格式变化**: 保留 24h 回滚窗口，旧解析器作为 fallback
3. **历史消息兼容**: `buildMessages()` 需处理两种格式

---

## 时间估算

| 阶段 | 时间 |
|------|------|
| Phase 1: 依赖升级 | 30min |
| Phase 2: Tool 定义 | 1h |
| Phase 3: 后端 Route | 1h |
| Phase 4: 消息构建器 | 30min |
| Phase 5: 前端解析器 | 2-3h |
| Phase 6: Store 适配 | 1h |
| Phase 7: 清理 | 30min |
| 测试验证 | 2h |
| **总计** | **8-10h** |

---

## 备注

- **agent_service**: 暂时保留，不参与本次迁移
- **useChat Hook**: 本计划采用渐进方式（替换解析器），未强制使用 `useChat()`。如需完全采用 `useChat()`，可作为后续优化
