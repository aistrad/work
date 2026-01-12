# VibeLife Agent 框架技术设计

> ⚠️ **DEPRECATED** - 此文档描述的是 V4 架构，已被 V5 架构取代。
>
> **V5 架构文档**：
> - `llm-architecture-v5.md` - V5 架构设计
> - `apps/api/skills/README.md` - Skills 架构说明

---

> 版本：v1.0 (DEPRECATED)
> 日期：2026-01-11
> 基于：现有 LLMService + ModelRouter + Tool Use 架构

---

## 一、现有架构分析

### 1.1 已有能力

| 组件 | 位置 | 能力 |
|------|------|------|
| LLMService | `services/vibe_engine/llm.py` | 多提供商支持（Zhipu/Claude/Gemini）、流式/非流式、自动 fallback |
| ModelRouter | `services/model_router/router.py` | 智能路由、A/B 测试、配额管理 |
| QuotaManager | `services/model_router/quota.py` | 多维度配额控制、使用量追踪 |
| Tool Use | `services/vibe_engine/tools.py` | OpenAI 兼容的 Function Calling |
| ToolExecutor | `services/vibe_engine/tool_executor.py` | UI 工具后端执行 |
| ContextBuilder | `services/vibe_engine/context.py` | 智能上下文裁剪、话题检测 |

### 1.2 需要新增

| 能力 | 说明 |
|------|------|
| Agent 循环 | 多轮 Tool Use，直到任务完成 |
| Orchestrator | 协调多个 Skill Agent |
| 状态流式输出 | 思考过程、工具调用可见 |
| 统一使用量追踪 | 为精细计费准备 |

---

## 二、架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              routes/chat.py                                  │
│                           (HTTP 端点 / SSE 流式)                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         services/agent/orchestrator.py                       │
│                              Orchestrator Agent                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  职责：                                                              │   │
│  │  • 意图识别（单 Skill vs 多 Skill 融合）                            │   │
│  │  • 调度 Skill Agents                                                 │   │
│  │  • 聚合结果                                                          │   │
│  │  • 使用量追踪                                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│   BaziAgent          │ │   ZodiacAgent        �� │   FusionAgent        │
│   八字 Skill         │ │   星座 Skill         │ │   多维融合           │
├──────────────────────┤ ├──────────────────────┤ ├──────────────────────┤
│ • 八字专属工具       │ │ • 星座专属工具       │ │ • 跨 Skill 分析      │
│ • 八字知识库 RAG     │ │ • 星座知识库 RAG     │ │ • 综合洞察生成       │
│ • 八字 System Prompt │ │ • 星座 System Prompt │ │ • 矛盾调和           │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         services/agent/usage_tracker.py                      │
│                              UsageTracker                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  追踪：                                                              │   │
│  │  • 每个 Agent 的 LLM 调用次数                                       │   │
│  │  • Token 使用量（input/output）                                     │   │
│  │  • 工具调用次数                                                      │   │
│  │  • 估算成本                                                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 文件结构

```
apps/api/services/agent/
├── __init__.py
├── base.py              # BaseAgent 基类
├── orchestrator.py      # Orchestrator Agent
├── fusion_agent.py      # Fusion Agent
├── usage_tracker.py     # 使用量追踪
├── registry.py          # Skill Agent 注册中心
└── skills/
    ├── __init__.py
    ├── bazi_agent.py    # 八字 Skill Agent
    └── zodiac_agent.py  # 星座 Skill Agent
```

---

## 三、核心组件设计

### 3.1 BaseAgent 基类

```python
# services/agent/base.py

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import AsyncIterator, List, Dict, Any, Optional
from enum import Enum

class AgentState(Enum):
    IDLE = "idle"
    THINKING = "thinking"
    TOOL_CALLING = "tool_calling"
    WAITING_INPUT = "waiting_input"
    COMPLETED = "completed"
    ERROR = "error"

@dataclass
class AgentEvent:
    """Agent 事件，用于流式输出"""
    type: str  # "state_change", "thinking", "tool_call", "tool_result", "content", "done"
    data: Dict[str, Any]
    agent_id: str
    timestamp: float = field(default_factory=lambda: time.time())

@dataclass
class AgentContext:
    """Agent 执行上下文"""
    user_id: str
    user_tier: str  # free, pro, vip
    skill: str
    profile: Dict[str, Any]
    skill_data: Dict[str, Any]
    conversation_history: List[Dict[str, Any]]

class BaseAgent(ABC):
    """Skill Agent 基类"""

    def __init__(self, agent_id: str, name: str):
        self.agent_id = agent_id
        self.name = name
        self.state = AgentState.IDLE
        self.usage_tracker = UsageTracker()

    @abstractmethod
    def get_system_prompt(self, context: AgentContext) -> str:
        """返回该 Agent 的 System Prompt"""
        pass

    @abstractmethod
    def get_tools(self) -> List[Dict[str, Any]]:
        """返回该 Agent 可用的工具列表"""
        pass

    async def run(
        self,
        message: str,
        context: AgentContext,
        max_iterations: int = 5
    ) -> AsyncIterator[AgentEvent]:
        """
        执行 Agent 循环

        流程：
        1. 构建消息
        2. 调用 LLM
        3. 如果有 tool_call，执行工具
        4. 将工具结果加入消息，回到步骤 2
        5. 如果没有 tool_call，返回最终结果
        """
        messages = self._build_messages(message, context)
        tools = self.get_tools()

        for iteration in range(max_iterations):
            # 状态：思考中
            yield AgentEvent(
                type="state_change",
                data={"state": "thinking", "iteration": iteration + 1},
                agent_id=self.agent_id
            )

            # 调用 LLM
            response = await self._call_llm(messages, tools, context)
            self.usage_tracker.record_llm_call(response)

            # 检查是否有工具调用
            if response.tool_calls:
                for tool_call in response.tool_calls:
                    # 状态：工具调用中
                    yield AgentEvent(
                        type="tool_call",
                        data={
                            "tool_name": tool_call.function["name"],
                            "tool_args": tool_call.function["arguments"]
                        },
                        agent_id=self.agent_id
                    )

                    # 执行工具
                    result = await self._execute_tool(tool_call, context)
                    self.usage_tracker.record_tool_call(tool_call.function["name"])

                    yield AgentEvent(
                        type="tool_result",
                        data={"tool_name": tool_call.function["name"], "result": result},
                        agent_id=self.agent_id
                    )

                    # 将工具结果加入消息
                    messages.append({
                        "role": "assistant",
                        "tool_calls": [tool_call.to_dict()]
                    })
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": json.dumps(result)
                    })
            else:
                # 没有工具调用，返回最终内容
                yield AgentEvent(
                    type="content",
                    data={"content": response.content},
                    agent_id=self.agent_id
                )
                yield AgentEvent(
                    type="done",
                    data={"usage": self.usage_tracker.get_summary()},
                    agent_id=self.agent_id
                )
                return

        # 达到最大迭代次数
        yield AgentEvent(
            type="error",
            data={"error": "Max iterations reached"},
            agent_id=self.agent_id
        )
```

### 3.2 Orchestrator Agent

```python
# services/agent/orchestrator.py

class Orchestrator:
    """
    协调器 Agent

    职责：
    1. 意图识别：判断用户问题需要哪些 Skill
    2. 调度：并行或串行调用 Skill Agents
    3. 聚合：合并多个 Agent 的结果
    """

    def __init__(self):
        self.registry = AgentRegistry()
        self.usage_tracker = UsageTracker()

    async def process(
        self,
        message: str,
        context: AgentContext
    ) -> AsyncIterator[AgentEvent]:
        """处理用户消息"""

        # 1. 意图识别
        intent = await self._detect_intent(message, context)

        yield AgentEvent(
            type="intent_detected",
            data={"intent": intent.to_dict()},
            agent_id="orchestrator"
        )

        if intent.type == "single_skill":
            # 单 Skill 模式：直接调用对应 Agent
            agent = self.registry.get_agent(intent.skill)
            async for event in agent.run(message, context):
                yield event

        elif intent.type == "multi_skill":
            # 多 Skill 模式：并行调用，然后融合
            results = {}

            # 并行调用各 Skill Agent
            for skill in intent.skills:
                agent = self.registry.get_agent(skill)
                skill_result = []
                async for event in agent.run(message, context):
                    yield event  # 透传事件
                    if event.type == "content":
                        skill_result.append(event.data["content"])
                results[skill] = "\n".join(skill_result)

            # 调用 Fusion Agent 融合结果
            fusion_agent = FusionAgent()
            async for event in fusion_agent.fuse(results, message, context):
                yield event

        # 记录总使用量
        yield AgentEvent(
            type="orchestrator_done",
            data={"total_usage": self.usage_tracker.get_summary()},
            agent_id="orchestrator"
        )

    async def _detect_intent(self, message: str, context: AgentContext) -> Intent:
        """
        意图识别

        简单实现：基于关键词 + 当前 Skill
        复杂实现：调用 LLM 进行意图分类
        """
        # 关键词检测
        bazi_keywords = ["八字", "命盘", "日主", "十神", "大运", "流年"]
        zodiac_keywords = ["星座", "星盘", "上升", "月亮", "太阳", "行星"]
        fusion_keywords = ["综合", "结合", "融合", "全面", "多角度"]

        has_bazi = any(kw in message for kw in bazi_keywords)
        has_zodiac = any(kw in message for kw in zodiac_keywords)
        has_fusion = any(kw in message for kw in fusion_keywords)

        if has_fusion or (has_bazi and has_zodiac):
            return Intent(type="multi_skill", skills=["bazi", "zodiac"])
        elif has_bazi:
            return Intent(type="single_skill", skill="bazi")
        elif has_zodiac:
            return Intent(type="single_skill", skill="zodiac")
        else:
            # 默认使用当前 Skill
            return Intent(type="single_skill", skill=context.skill)
```

### 3.3 UsageTracker

```python
# services/agent/usage_tracker.py

@dataclass
class UsageSummary:
    """使用量摘要"""
    llm_calls: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    tool_calls: Dict[str, int] = field(default_factory=dict)
    estimated_cost: float = 0.0

class UsageTracker:
    """使用量追踪器"""

    def __init__(self):
        self.summary = UsageSummary()
        self.details: List[Dict] = []

    def record_llm_call(self, response: LLMResponse):
        """记录 LLM 调用"""
        self.summary.llm_calls += 1
        if response.usage:
            self.summary.input_tokens += response.usage.get("input_tokens", 0)
            self.summary.output_tokens += response.usage.get("output_tokens", 0)

        # 估算成本（基于模型定价）
        cost = self._estimate_cost(response.model, response.usage)
        self.summary.estimated_cost += cost

        self.details.append({
            "type": "llm_call",
            "model": response.model,
            "usage": response.usage,
            "cost": cost,
            "timestamp": time.time()
        })

    def record_tool_call(self, tool_name: str):
        """记录工具调用"""
        if tool_name not in self.summary.tool_calls:
            self.summary.tool_calls[tool_name] = 0
        self.summary.tool_calls[tool_name] += 1

        self.details.append({
            "type": "tool_call",
            "tool_name": tool_name,
            "timestamp": time.time()
        })

    def get_summary(self) -> Dict[str, Any]:
        """获取使用量摘要"""
        return {
            "llm_calls": self.summary.llm_calls,
            "input_tokens": self.summary.input_tokens,
            "output_tokens": self.summary.output_tokens,
            "total_tokens": self.summary.input_tokens + self.summary.output_tokens,
            "tool_calls": self.summary.tool_calls,
            "estimated_cost": round(self.summary.estimated_cost, 6)
        }

    def _estimate_cost(self, model: str, usage: Dict) -> float:
        """估算成本"""
        # 定价表（每 1M tokens）
        PRICING = {
            "glm-4-flash": {"input": 0.1, "output": 0.1},
            "gemini-flash": {"input": 0.075, "output": 0.3},
            "claude-sonnet": {"input": 3.0, "output": 15.0},
            "claude-opus": {"input": 15.0, "output": 75.0},
        }

        pricing = PRICING.get(model, {"input": 0.1, "output": 0.1})
        input_cost = (usage.get("input_tokens", 0) / 1_000_000) * pricing["input"]
        output_cost = (usage.get("output_tokens", 0) / 1_000_000) * pricing["output"]
        return input_cost + output_cost
```

---

## 四、与 Vercel AI SDK 6 集成

### 4.1 前端流式协议

AI SDK 6 使用 `UIMessageChunk` 格式，我们的 Agent 事件需要转换：

```typescript
// apps/web/src/app/api/chat/route.ts

import { createUIMessageStreamResponse, UIMessageChunk } from 'ai';

export async function POST(req: Request) {
  // ... 解析请求

  return createUIMessageStreamResponse({
    async *stream() {
      const response = await fetch(`${API_URL}/chat/agent`, {
        method: 'POST',
        body: JSON.stringify({ message, context }),
      });

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const lines = decoder.decode(value).split('\n');
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;

          const event = JSON.parse(line.slice(6));

          // 转换 Agent 事件为 AI SDK 6 格式
          yield* convertAgentEvent(event);
        }
      }
    }
  });
}

function* convertAgentEvent(event: AgentEvent): Generator<UIMessageChunk> {
  switch (event.type) {
    case 'state_change':
      yield {
        type: 'step-start',
        stepId: `${event.agent_id}-${event.data.iteration}`,
        metadata: { state: event.data.state }
      };
      break;

    case 'thinking':
      yield {
        type: 'reasoning',
        textDelta: event.data.content
      };
      break;

    case 'tool_call':
      yield {
        type: 'tool-input-available',
        toolCallId: event.data.tool_call_id,
        toolName: event.data.tool_name,
        input: event.data.tool_args
      };
      break;

    case 'tool_result':
      yield {
        type: 'tool-output-available',
        toolCallId: event.data.tool_call_id,
        output: event.data.result
      };
      break;

    case 'content':
      yield {
        type: 'text-delta',
        textDelta: event.data.content
      };
      break;

    case 'done':
      yield {
        type: 'finish',
        finishReason: 'stop',
        usage: event.data.usage
      };
      break;
  }
}
```

### 4.2 前端状态展示

```typescript
// apps/web/src/components/chat/AgentStatus.tsx

interface AgentStatusProps {
  agentId: string;
  state: string;
  currentTool?: string;
}

export function AgentStatus({ agentId, state, currentTool }: AgentStatusProps) {
  const stateLabels = {
    thinking: '思考中...',
    tool_calling: `调用 ${currentTool}...`,
    waiting_input: '等待输入...',
  };

  return (
    <div className="flex items-center gap-2 text-sm text-gray-500">
      <Spinner size="sm" />
      <span>{stateLabels[state] || state}</span>
    </div>
  );
}
```

---

## 五、实施计划

### Phase 1: 基础框架

| 任务 | 文件 | 说明 |
|------|------|------|
| BaseAgent | `services/agent/base.py` | Agent 基类、事件定义 |
| UsageTracker | `services/agent/usage_tracker.py` | 使用量追踪 |
| Registry | `services/agent/registry.py` | Agent 注册中心 |

### Phase 2: Skill Agents

| 任务 | 文件 | 说明 |
|------|------|------|
| BaziAgent | `services/agent/skills/bazi_agent.py` | 八字 Agent |
| ZodiacAgent | `services/agent/skills/zodiac_agent.py` | 星座 Agent |

### Phase 3: Orchestrator + Fusion

| 任务 | 文件 | 说明 |
|------|------|------|
| Orchestrator | `services/agent/orchestrator.py` | 协调器 |
| FusionAgent | `services/agent/fusion_agent.py` | 融合 Agent |

### Phase 4: 前端集成

| 任务 | 文件 | 说明 |
|------|------|------|
| API Route | `apps/web/src/app/api/chat/route.ts` | AI SDK 6 集成 |
| AgentStatus | `apps/web/src/components/chat/AgentStatus.tsx` | 状态展示 |

---

## 六、与现有代码的关系

### 6.1 复用

| 现有组件 | 复用方式 |
|----------|----------|
| LLMService | Agent 内部调用 `llm.stream()` |
| ModelRouter | 通过 `client.py` 统一入口 |
| QuotaManager | 配额检查和记录 |
| tools.py | 工具定义直接复用 |
| tool_executor.py | UI 工具执行直接复用 |
| ContextBuilder | 上下文构建直接复用 |

### 6.2 新增

| 新组件 | 职责 |
|--------|------|
| BaseAgent | Agent 循环逻辑 |
| Orchestrator | 多 Agent 协调 |
| UsageTracker | 精细使用量追踪 |
| AgentEvent | 流式事件格式 |

### 6.3 修改

| 文件 | 修改内容 |
|------|----------|
| routes/chat.py | 新增 `/chat/agent` 端点 |
| 前端 route.ts | 支持 Agent 事件转换 |

---

*文档版本：v1.0*
*创建日期：2026-01-11*
