# VibeLife LLM 架构 V5 设计文档

## 1. 设计原则

- **Claude Agent SDK 风格**：简单的 Agent 循环
- **Skill 是配置，不是独立 Agent**：CoreAgent + Skill 配置融合
- **CoreAgent ���定 Skill**：LLM 智能理解意图，自主决定使用哪些 Skill
- **严禁关键词意图识别**：不使用硬编码关键词匹配
- **模型路由极简化**：YAML 配置 + 可选数据库覆盖
- **配额控制**：入口检查 + 调用后记录，超限拒绝 + 提示升级

## 2. 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                      /chat/stream                                │
│  1. 配额检查 → 超限则拒绝 + 提示升级                              │
│  2. 创建 CoreAgent                                               │
│  3. 流式返回事件 (Vercel AI SDK 6 格式)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CoreAgent                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Tools:                                                     ││
│  │  - use_skill(skills, topic)  ← Skill 选择                   ││
│  │  - search_knowledge(query)   ← RAG                          ││
│  │  - show_report(...)          ← UI 工具                      ││
│  │  - show_bazi_chart(...)      ← Skill 专属工具               ││
│  │  - show_zodiac_chart(...)                                   ││
│  │  - ...                                                      ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Agent 循环 (Claude Agent SDK 风格)                         ││
│  │                                                             ││
│  │  while not done:                                            ││
│  │    response = await llm.chat(messages, tools)               ││
│  │                                                             ││
│  │    if tool_call == "use_skill":                             ││
│  │      if len(skills) == 1:                                   ││
│  │        # 单 Skill: 加载 context + tools，继续循环            ││
│  │        load_skill_context(skills[0])                        ││
│  │      else:                                                  ││
│  │        # 多 Skill: 启动 Subagents 并行执行                   ││
│  │        results = await parallel_subagents(skills)           ││
│  │        # 融合结果，继续循环                                  ││
│  │        messages.append(fused_result)                        ││
│  │                                                             ││
│  │    elif other_tool_call:                                    ││
│  │      result = await execute_tool(...)                       ││
│  │      messages.append(result)                                ││
│  │                                                             ││
│  │    else:                                                    ││
│  │      done = True                                            ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LLMClient                                   │
│  - 模型选择 (YAML 配置 + 可选数据库覆盖)                          │
│  - 调用提供商 (Zhipu/Gemini/Claude)                              │
│  - Fallback 处理                                                 │
│  - 记录 token/调用次数 → QuotaTracker                            │
└─────────────────────────────────────────────────────────────────┘
```

## 3. 文件结构

```
apps/api/
├── config/
│   ├── models.yaml              # 模型配置
│   └── skills/
│       ├── bazi.yaml            # 八字 Skill 配置
│       └── zodiac.yaml          # 星座 Skill 配置
│
├── services/
│   ├── llm/
│   │   ├── __init__.py
│   │   ├── client.py            # LLMClient
│   │   └── config.py            # ModelConfig
│   │
│   ├── agent/
│   │   ├── __init__.py
│   │   ├── core.py              # CoreAgent
│   │   ├── subagent.py          # SkillSubAgent (并行执行用)
│   │   ├── tools.py             # ToolRegistry
│   │   └── quota.py             # QuotaTracker (简化版)
│   │
│   └── vibe_engine/
│       ├── context.py           # ContextBuilder (保留)
│       └── tool_executor.py     # UI 工具执行 (保留)
│
└── routes/
    └── chat.py                  # 统一入口
```

## 4. 删除的组件

| 删除 | 原因 |
|------|------|
| `model_router/router.py` | 合并到 `ModelConfig` |
| `model_router/quota.py` | 简化为 `QuotaTracker` |
| `model_router/cache.py` | 配置静态化后不需要 |
| `agent/orchestrator.py` | 功能合并到 `CoreAgent` |
| `agent/skills/*.py` | Skill 变成 YAML 配置 |
| `agent/registry.py` | 不再需要动态注册 |
| `agent/fusion_agent.py` | 融合逻辑在 `CoreAgent._fuse_results()` |

## 5. 核心组件设计

### 5.1 CoreAgent

```python
class CoreAgent:
    """Claude Agent SDK 风格的核心 Agent"""

    CORE_TOOLS = [
        {
            "name": "use_skill",
            "description": "选择使用的技能来回答用户问题",
            "parameters": {
                "type": "object",
                "properties": {
                    "skills": {
                        "type": "array",
                        "items": {"enum": ["bazi", "zodiac"]},
                        "description": "需要使用的技能列表"
                    },
                    "topic": {
                        "type": "string",
                        "enum": ["career", "relationship", "fortune", "health", "general"],
                        "description": "用户关注的话题"
                    }
                },
                "required": ["skills", "topic"]
            }
        }
    ]

    async def run(self, message: str, context: AgentContext, max_iterations: int = 10):
        messages = [{"role": "user", "content": message}]
        active_skills = []

        for _ in range(max_iterations):
            yield AgentEvent(type="thinking")

            tools = self._get_current_tools(active_skills)
            response = await self.llm.chat(
                messages=messages,
                tools=tools,
                system=self._build_system_prompt(active_skills, context)
            )

            if not response.tool_calls:
                yield AgentEvent(type="content", data=response.content)
                yield AgentEvent(type="done")
                return

            for tool_call in response.tool_calls:
                yield AgentEvent(type="tool_call", data=tool_call)

                if tool_call.name == "use_skill":
                    skills = tool_call.args["skills"]
                    topic = tool_call.args["topic"]

                    if len(skills) == 1:
                        active_skills = skills
                        result = f"已激活 {skills[0]} 技能"
                    else:
                        result = await self._run_subagents(skills, topic, message, context)
                        yield AgentEvent(type="tool_result", data={"fused": result})
                else:
                    result = await ToolRegistry.execute(tool_call.name, tool_call.args, context)
                    yield AgentEvent(type="tool_result", data=result)

                messages.append({"role": "tool", "tool_call_id": tool_call.id, "content": str(result)})
```

### 5.2 ModelConfig

```python
class ModelConfig:
    _config: dict = None

    @classmethod
    def load(cls):
        if cls._config is None:
            cls._config = yaml.safe_load(open("config/models.yaml"))
        return cls._config

    @classmethod
    def resolve(cls, user_tier: str = "free", task: str = "chat") -> str:
        config = cls.load()

        # tier 配置
        if user_tier in config.get("tiers", {}):
            return config["tiers"][user_tier]

        # 默认
        return config["defaults"].get(task, config["defaults"]["chat"])
```

### 5.3 QuotaTracker

```python
class QuotaTracker:
    @classmethod
    async def check(cls, user_id: str, tier: str) -> tuple[bool, str]:
        usage = await cls._get_usage(user_id)
        limit = TIER_LIMITS.get(tier, TIER_LIMITS["free"])

        if usage["calls"] >= limit["calls"]:
            return False, "本月对话次数已用完，请升级会员"
        if usage["tokens"] >= limit["tokens"]:
            return False, "本月 Token 额度已用完，请升级会员"

        return True, ""

    @classmethod
    async def record(cls, user_id: str, usage: dict):
        await db.execute("""
            INSERT INTO usage_records (user_id, calls, tokens, created_at)
            VALUES ($1, $2, $3, NOW())
        """, user_id, usage["calls"], usage["tokens"])

TIER_LIMITS = {
    "free": {"calls": 50, "tokens": 100000},
    "premium": {"calls": 500, "tokens": 1000000},
    "vip": {"calls": -1, "tokens": -1},
}
```

### 5.4 Skill 配置 (YAML)

```yaml
# config/skills/bazi.yaml
name: bazi
display_name: 八字分析

system_prompt: |
  你是一位精通八字命理的专家...
  {identity_prism}
  {bazi_data}

tools:
  - show_bazi_chart
  - show_bazi_fortune
  - show_bazi_kline
  - search_knowledge
  - show_report
  - show_insight

context_fields:
  - identity_prism
  - bazi_data
```

## 6. 配额控制流程

```
┌───────────────────────────��─────────────────────────┐
│  /chat/stream                                       │
│    │                                                │
│    ├─ [A] 入口检查配额                               │
│    │     └─ 超限 → 返回 429 + 提示升级               │
│    │                                                │
│    ▼                                                │
│  CoreAgent.run()                                    │
│    │                                                │
│    ▼                                                │
│  LLMClient.chat()                                   │
│    │                                                │
│    └─ [C] 调用后记录使用量                           │
└─────────────────────────────────────────────────────┘
```

## 7. 对比：简化前 vs 简化后

| 组件 | 简化前 | 简化后 |
|------|--------|--------|
| 入口 | 2 个 | 1 个 |
| Agent | BaseAgent + SkillAgents + Orchestrator | CoreAgent |
| 模型路由 | ModelRouter + QuotaManager + RouteCache | ModelConfig |
| Skill | 独立 Agent 类 | YAML 配置 |
| 意图识别 | 关键词匹配 | LLM 自主决策 |
| Fallback | 双层 | 单层 |
| 配置源 | 4 个 | 2 个 |
| 文件数 | ~15 个 | ~6 个 |

## 8. 实施完成的文件

### 8.1 新增文件

| 文件 | 说明 |
|------|------|
| `config/skills/bazi.yaml` | 八字 Skill 配置 |
| `config/skills/zodiac.yaml` | 星座 Skill 配置 |
| `services/llm/__init__.py` | LLM 模块入口 |
| `services/llm/client.py` | 统一 LLMClient |
| `services/llm/config.py` | ModelConfig 配置加载 |
| `services/agent/core.py` | CoreAgent 核心实现 |
| `services/agent/subagent.py` | SkillSubAgent 并行执行 |
| `services/agent/quota.py` | QuotaTracker 配额管理 |
| `routes/chat_v5.py` | V5 统一路由入口 |

### 8.2 修改文件

| 文件 | 说明 |
|------|------|
| `services/agent/__init__.py` | 更新导出，兼容 V4 |

### 8.3 使用方式

V5 路由挂载在 `/chat/v5` 前缀下：

```python
# main.py
from routes.chat_v5 import router as chat_v5_router
app.include_router(chat_v5_router)
```

前端调用：

```typescript
// 使用 V5 API
const response = await fetch('/api/chat/v5/stream', {
  method: 'POST',
  body: JSON.stringify({ message: '分析我的事业运势' })
});
```

### 8.4 迁移路径

1. **阶段 1**：V5 路由与 V4 并行运行，前端可选择使用
2. **阶段 2**：前端切换到 V5 API
3. **阶段 3**：删除 V4 废弃组件（orchestrator, registry, skills/*.py）

## 9. 待完成事项

- [ ] 在 main.py 中注册 chat_v5 路由
- [ ] 前端适配 V5 API
- [ ] 添加 usage_records 数据库表（如果不存在）
- [ ] 性能测试和优化
- [ ] 删除 V4 废弃组件
