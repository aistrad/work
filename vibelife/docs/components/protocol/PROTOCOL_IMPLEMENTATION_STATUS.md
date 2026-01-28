# 协议流实施状态报告

> 日期: 2026-01-20
> 基于: REFACTOR_PLAN.md
> 状态: 后端核心完成 70%，需要完成 chat_v5.py 集成

---

## 已完成工作 ✅

### Phase 1: 通用工具实现 ✅

**1.1 global_handlers.py** (`/apps/api/services/agent/global_handlers.py`)
- ✅ 添加 `read_state` handler
- ✅ 添加 `write_state` handler
- ✅ 添加 `append_to_list` handler
- 位置：文件末尾（第323-488行）

**1.2 UnifiedProfileRepository 扩展** (`/apps/api/stores/unified_profile_repo.py`)
- ✅ 添加 `get_skill_state()` 方法
- ✅ 添加 `update_skill_state()` 方法（深度合并）
- ✅ 添加 `append_to_skill_list()` 方法
- 位置：文件第1418-1538行

**1.3 Core 工具注册** (`/apps/api/skills/core/tools/tools.yaml`)
- ✅ 注册 `read_state` 工具
- ✅ 注册 `write_state` 工具
- ✅ 注册 `append_to_list` 工具
- 位置：文件第89-214行

### Phase 2: 协议工具实现 ✅

**2.1 Lifecoach 工具定义** (`/apps/api/skills/lifecoach/tools/tools.yaml`)
- ✅ 添加 `show_protocol_invitation` 工具
- ✅ 添加 `advance_protocol_step` 工具
- ✅ 添加 `cancel_protocol` 工具
- 位置：文件第380-506行

**2.2 Lifecoach 工具 Handlers** (`/apps/api/skills/lifecoach/tools/handlers.py`)
- ✅ 实现 `show_protocol_invitation` handler
- ✅ 实现 `advance_protocol_step` handler
- ✅ 实现 `cancel_protocol` handler
- 位置：文件第484-601行

### Phase 3: chat_v5.py 路由层（部分完成）

**3.1 导入更新** ✅
- ✅ 添加 `yaml` 导入
- ✅ 添加 `Path` 导入
- ✅ 添加 `AgentEvent` 导入
- ✅ 添加 `UnifiedProfileRepository` 导入

**3.2 协议辅助函数** （待集成）
准备好的函数（在 `/tmp/protocol_helpers.py`）：
- `load_protocol_config(protocol_id)` - 加载协议配置
- `build_protocol_prompt(config, step, state)` - 构建协议 prompt
- `get_protocol_state(user_id, skill)` - 获取协议状态
- `emit_protocol_progress_event(state, config)` - 发送进度事件
- `async_generator(items)` - 辅助生成器

---

## 待完成工作 🔧

### Phase 3: chat_v5.py 主流程集成 ⚠️

需要在 `chat_stream_v5()` 函数中添加协议逻辑：

```python
@router.post("/stream")
async def chat_stream_v5(...):
    # ... 现有代码 ...

    # ✅ 已有：skill 恢复逻辑
    active_skill = request.skill
    if not active_skill:
        conv = await conversation_repo.get_conversation(conversation_id)
        if conv and conv.skill and conv.skill != "core":
            active_skill = conv.skill

    # ⚠️ 需要添加：协议状态恢复
    protocol_state = None
    protocol_config = None

    if active_skill == "lifecoach" and user_id:
        protocol_state = await get_protocol_state(user_id, active_skill)
        if protocol_state:
            # 加载配置
            protocol_config = load_protocol_config(protocol_state["id"])

            # 构建 protocol_prompt
            lifecoach_data = await UnifiedProfileRepository.get_skill_state(
                user_id, "lifecoach"
            )
            context.protocol_prompt = build_protocol_prompt(
                protocol_config=protocol_config,
                step=protocol_state.get("step", 1),
                lifecoach_state=lifecoach_data
            )

    # ⚠️ 需要修改：流式生成函数
    async def generate():
        # 如果有协议状态，先发送进度事件
        if protocol_state and protocol_config:
            progress_event = await emit_protocol_progress_event(
                protocol_state, protocol_config
            )
            # 通过 adapter 转换为 SSE
            async for chunk in adapter.adapt(async_generator([progress_event])):
                yield chunk

        # 执行 CoreAgent
        async for event in core_agent.run(message, context):
            # ⚠️ 检测步骤完成（通过工具调用）
            if event.type == "tool_result":
                if event.data.get("tool_name") == "advance_protocol_step":
                    # 步骤完成，更新协议状态
                    current_step = protocol_state.get("step", 1)
                    total_steps = protocol_config.get("total_steps", 6)

                    if current_step < total_steps:
                        # 推进到下一步
                        await UnifiedProfileRepository.update_skill_state(
                            user_id,
                            "lifecoach",
                            "protocol",
                            {"step": current_step + 1}
                        )

                        # 发送进度更新
                        protocol_state["step"] = current_step + 1
                        progress_event = await emit_protocol_progress_event(
                            protocol_state, protocol_config
                        )
                        async for chunk in adapter.adapt(async_generator([progress_event])):
                            yield chunk
                    else:
                        # 协议完成
                        await UnifiedProfileRepository.update_skill_state(
                            user_id,
                            "lifecoach",
                            "protocol",
                            {"completed": True}
                        )

                        # 发送完成事件
                        complete_event = AgentEvent(
                            type="protocol_completed",
                            data={"protocol_id": protocol_state["id"]}
                        )
                        async for chunk in adapter.adapt(async_generator([complete_event])):
                            yield chunk

            # 正常事件流
            async for chunk in adapter.adapt(async_generator([event])):
                yield chunk

    return StreamingResponse(generate(), media_type="text/event-stream")
```

**实施位置**：
- 文件：`/apps/api/routes/chat_v5.py`
- 函数：`chat_stream_v5()` (约第182行开始)
- 需要在3个地方修改：
  1. skill 恢复后添加协议恢复（约第246-258行之后）
  2. 流式生成函数开头添加进度事件（约第280行）
  3. 事件循环中添加步骤推进逻辑（约第310行）

### Phase 4: SSE 事件扩展 ⚠️

需要在 `stream_adapter.py` 中添加协议事件支持：

```python
# /apps/api/services/agent/stream_adapter.py

class AISDKv6Adapter(BaseStreamAdapter):
    async def adapt(self, events: AsyncGenerator[AgentEvent, None]):
        # ... 现有逻辑 ...

        async for event in events:
            # ... 现有事件处理 ...

            elif event.type == "protocol_progress":
                # 协议进度更新
                yield self._format({
                    "type": "data",
                    "data": ["protocol_progress", {
                        "protocol_id": event.data.get("protocol_id"),
                        "step": event.data.get("step"),
                        "total_steps": event.data.get("total_steps"),
                        "phase": event.data.get("phase"),
                        "progress": event.data.get("progress"),
                        "step_name": event.data.get("step_name"),
                    }]
                })

            elif event.type == "protocol_completed":
                yield self._format({
                    "type": "data",
                    "data": ["protocol_completed", {
                        "protocol_id": event.data.get("protocol_id"),
                        "summary": event.data.get("summary"),
                    }]
                })
```

**实施位置**：
- 文件：`/apps/api/services/agent/stream_adapter.py`
- 类：`AISDKv6Adapter`
- 方法：`adapt()`
- 位置：在现有事件处理之后添加

---

## 前端集成（Phase 5-7）🔮

### Phase 5: useVibeChat 扩展

```typescript
// apps/web/src/hooks/useVibeChat.ts

export interface ProtocolState {
  id: string;
  step: number;
  totalSteps: number;
  phase: string;
  progress: number; // 0-1
  stepName: string;
}

export function useVibeChat(options) {
  const [protocolState, setProtocolState] = useState<ProtocolState | null>(null);

  const chat = useChat({
    // ... 现有配置 ...

    // 监听自定义数据事件
    onFinish: (message) => {
      // 检测 protocol_progress 事件
      if (message.data) {
        const events = Array.isArray(message.data) ? message.data : [message.data];

        for (const event of events) {
          if (Array.isArray(event) && event[0] === "protocol_progress") {
            setProtocolState(event[1]);
          } else if (Array.isArray(event) && event[0] === "protocol_completed") {
            setProtocolState(null);
          }
        }
      }
    },
  });

  return {
    ...chat,
    protocolState, // 新增
  };
}
```

### Phase 6: ProtocolProgressCard 组件

```tsx
// apps/web/src/components/lifecoach/ProtocolProgressCard.tsx

export function ProtocolProgressCard({
  protocol,
  step,
  totalSteps,
  phase,
  progress,
  stepName
}: ProtocolState) {
  return (
    <div className="my-4 rounded-lg border border-primary/20 bg-primary/5 p-4">
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm font-medium">
          📊 {getProtocolName(protocol)} - 进度 {step}/{totalSteps}
        </span>
        <span className="text-xs text-muted-foreground">{phase}</span>
      </div>

      {/* 进度条 */}
      <div className="h-2 bg-muted rounded-full overflow-hidden">
        <div
          className="h-full bg-primary transition-all duration-500"
          style={{ width: `${progress * 100}%` }}
        />
      </div>

      {stepName && (
        <p className="text-xs text-muted-foreground mt-2">
          当前步骤：{stepName}
        </p>
      )}
    </div>
  );
}
```

### Phase 7: ChatContainer 集成

```tsx
// apps/web/src/components/chat/ChatContainer.tsx

export function ChatContainer({ skillId }: ChatContainerProps) {
  const { messages, protocolState, sendMessage } = useVibeChat({ skillId });

  return (
    <div>
      {/* 协议进度条（内联在对话流中） */}
      {protocolState && (
        <ProtocolProgressCard {...protocolState} />
      )}

      {/* 消息列表 */}
      {messages.map(msg => <ChatMessage key={msg.id} message={msg} />)}
    </div>
  );
}
```

---

## 快速完成步骤

### 立即可做（15分钟）

1. **集成 chat_v5.py 协议辅助函数**
   ```bash
   # 将 /tmp/protocol_helpers.py 的内容插入到 chat_v5.py 的第175行之后
   ```

2. **修改 chat_v5.py 主流程**
   - 在 skill 恢复后添加协议恢复逻辑（约20行代码）
   - 在流式生成函数中添加进度事件和步骤推进（约40行代码）

3. **扩展 stream_adapter.py**
   - 添加 `protocol_progress` 和 `protocol_completed` 事件处理（约20行代码）

### 后续工作（1-2小时）

4. **前端 useVibeChat 扩展**
5. **前端 ProtocolProgressCard 组件**
6. **前端 ChatContainer 集成**
7. **端到端测试**

---

## 测试验证 ✓

### 后端测试

```bash
# 1. 启动 API
cd apps/api
source venv/bin/activate
uvicorn main:app --reload

# 2. 测试协议流
curl -X POST http://localhost:8000/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{
    "message": "我最近很迷茫",
    "skill": "lifecoach",
    "conversation_id": "00000000-0000-0000-0000-000000000001"
  }'
```

### 前端测试

```bash
# 1. 启动前端
cd apps/web
pnpm dev

# 2. 访问 http://localhost:3000/chat
# 3. 选择 lifecoach skill
# 4. 发送"我最近很迷茫"
# 5. 观察是否显示协议邀请卡片
# 6. 点击"开始重置"
# 7. 观察是否显示进度条
```

---

## 已知问题 ⚠️

1. **chat_v5.py 编辑中断**：由于文件有特殊字符，直接编辑遇到困难
2. **解决方案**：手动将 `/tmp/protocol_helpers.py` 的内容复制到文件中

---

## 架构设计验证 ✓

基于 REFACTOR_PLAN.md 的设计完全符合：

✅ **分层清晰**：协议逻辑在 chat_v5.py 路由层，CoreAgent 保持通用
✅ **工具通用化**：使用 read_state/write_state，不是 skill 专用
✅ **数据统一**：协议状态存储在 `skills.lifecoach.protocol`
✅ **前端内联**：进度卡片内嵌在对话流中，非独立页面

---

## 总结

**当前完成度**：70%（后端核心完成，前端待实施）

**剩余工作量**：约 2-3 小时
- chat_v5.py 集成：30分钟
- stream_adapter 扩展：15分钟
- 前端实施：1-2小时

**核心价值**：
- ✅ 通用工具系统已建立，所有 Skill 可复用
- ✅ 协议工具已实现，支持任意协议流
- ✅ 数据结构统一，简化查询和维护
- ⚠️ 需要完成路由层集成，协议流才能运行

**建议**：
1. 优先完成 chat_v5.py 和 stream_adapter（后端核心）
2. 使用 Postman 或 curl 测试后端流程
3. 确认后端工作后，再实施前端
