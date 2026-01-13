# 对话引擎设计文档 - 方案 A

> Version: 2.2 | 2026-01-12

## 概述

**方案 A: AI SDK 主导 + Python Context API**

前端使用 Vercel AI SDK 6 的 `streamText` 直接调用 LLM，Python 后端提供 Context 构建服务。

## 核心架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI SDK 主导 + Python Context                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Next.js route.ts                                               │
│  ├─ 1. 调用 Python /context/build API                           │
│  │      → 返回 system_prompt + messages + tools + llm_config    │
│  ├─ 2. 调用 AI SDK streamText()                                 │
│  │      → 动态创建 LLM provider (根据 llm_config.provider)      │
│  ├─ 3. 工具执行 → Python 数据 API                               │
│  └─ 4. 流式完成后 → 保存消息 + 记录配额                         │
│                                                                 │
│  Python Backend                                                 │
│  ├─ /context/build          → ContextBuilder (智能裁剪+Profile) │
│  ├─ /context/messages/save  → 消息持久化                        │
│  ├─ /context/quota/record   → 配额记录                          │
│  ├─ /bazi/chart             → 八字命盘 API                      │
│  ├─ /zodiac/chart           → 星盘 API                          │
│  ├─ /zodiac/transit         → 行运分析 API                      │
│  ├─ /fortune/*              → 运势数据 API                      │
│  ├─ /report/*               → 报告 API                          │
│  └─ /relationship/*         → 关系分析 API                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 数据流

```
用户输入 → useChat → /api/chat (Next.js)
                         │
                         ├─ 1. POST /context/build (Python)
                         │      ← system_prompt + messages + tools + llm_config
                         │
                         ├─ 2. streamText(动态 LLM provider)
                         │      → 根据 llm_config.provider 选择 API Key
                         │
                         ├─ 3. 工具调用 → Python 数据 API
                         │      ← 工具结果 → Generative UI
                         │
                         └─ 4. onFinish 回调
                                ├─ POST /context/messages/save (保存消息)
                                └─ POST /context/quota/record (记录配额)
                         │
                         ▼
                    toTextStreamResponse() → 前端渲染
```

## LLM 调用规范

**前后端统一使用 `config/models.yaml` 作为唯一配置源**

```
config/models.yaml       ← 唯一配置源
        │
        ├─ Python: services/llm/client.py (LLMClient)
        │
        └─ Next.js: /context/build API 返回 llm_config
           - base_url: LLM API 地址
           - model: 模型 ID
```

**工作流程**:
1. 前端调用 `/context/build` API
2. Python 根据 `models.yaml` 和用户 tier 解析 LLM 配置
3. 返回 `llm_config: { base_url, model }` 给前端
4. 前端动态创建 LLM provider 并调用

**优势**:
- 改 `models.yaml` 即可切换模型，前端自动生效
- 支持 tier 级别的模型路由 (free/paid 用不同模型)
- 前后端 LLM 配置完全一致

**禁止**:
- 前端硬编码模型名称或 API 地址
- 使用 AI SDK Gateway 模型 ID (如 `deepseek/deepseek-v3`)

## API 设计

### 1. Context Build API

**端点**: `POST /api/v1/context/build`

**请求**:
```json
{
  "skill": "bazi",
  "voice_mode": "warm",
  "message": "我最近工作压力很大",
  "conversation_id": "uuid"
}
```

**响应**:
```json
{
  "system_prompt": "# Vibe 人设\n...",
  "messages": [
    {"role": "user", "content": "上次的问题"},
    {"role": "assistant", "content": "上次的回答"},
    {"role": "user", "content": "我最近工作压力很大"}
  ],
  "tools": [...],
  "metadata": {
    "topic": "career",
    "has_birth_info": true,
    "active_skills": ["bazi"]
  }
}
```

### 2. 前端 route.ts 实现

```typescript
// apps/web/src/app/api/chat/route.ts
import { streamText, tool, LanguageModel } from 'ai';
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

const API_BASE = process.env.VIBELIFE_API_INTERNAL || 'http://127.0.0.1:8000/api/v1';

// 动态创建 LLM provider (根据 Python 返回的配置)
function createLLMProvider(baseUrl: string, provider: string) {
  const keyMap: Record<string, string | undefined> = {
    gemini: process.env.GEMINI_API_KEY,
    deepseek: process.env.DEEPSEEK_API_KEY,
    glm: process.env.GLM_API_KEY,
  };
  return createOpenAICompatible({
    name: 'vibelife-llm',
    baseURL: baseUrl,
    apiKey: keyMap[provider] || process.env.LLM_API_KEY || '',
  });
}

export async function POST(req: Request) {
  const { messages, skill, voice_mode, conversation_id } = await req.json();
  const authHeader = req.headers.get('authorization');

  // 1. 调用 Python API 构建 context (包含 LLM 配置)
  const contextRes = await fetch(`${API_BASE}/context/build`, { ... });
  const context = await contextRes.json();

  // 2. 动态创建 LLM provider (根据 llm_config.provider 选择 API Key)
  const llmProvider = createLLMProvider(
    context.llm_config.base_url,
    context.llm_config.provider
  );
  const model = llmProvider(context.llm_config.model) as unknown as LanguageModel;

  // 3. 使用 AI SDK streamText 调用 LLM
  const result = streamText({
    model,
    system: context.system_prompt,
    messages: context.messages,
    tools: createTools(authHeader),
    async onFinish({ text, usage }) {
      // 4. 流式完成后保存消息和记录配额
      await fetch(`${API_BASE}/context/messages/save`, { ... });
      await fetch(`${API_BASE}/context/quota/record`, { ... });
    },
  });

  return result.toTextStreamResponse();
}
```

## 工具系统

前端定义 8 个核心工具，执行时调用 Python 数据 API：

```typescript
const tools = {
  show_bazi_chart: tool({
    description: '展示用户的八字命盘',
    inputSchema: z.object({ userId: z.string().optional() }),
    execute: async (args) => executeToolOnPython('show_bazi_chart', args, authHeader),
  }),
  show_bazi_fortune: tool({ ... }),
  show_bazi_kline: tool({ ... }),
  show_zodiac_chart: tool({ ... }),
  show_zodiac_transit: tool({ ... }),
  show_report: tool({ ... }),
  show_relationship: tool({ ... }),
  request_info: tool({ ... }),
};
```

## 文件结构

```
apps/api/
├── routes/
│   ├── context.py        # /context/build API (核心)
│   ├── fortune.py        # 运势数据 API
│   ├── report.py         # 报告 API
│   └── relationship.py   # 关系分析 API
├── services/
│   └── vibe_engine/
│       ├── context.py    # ContextBuilder
│       └── tools.py      # 工具定义

apps/web/
└── src/app/api/chat/
    └── route.ts          # AI SDK streamText (核心)
```

## 与 AI SDK 6 集成

| 效果 | 实现方式 |
|------|---------|
| 打字机效果 | `streamText` 原生支持 |
| 工具调用 | `tool()` + `execute` |
| Generative UI | 工具结果 + 前端组件 |
| 多轮对话 | Context API 返回 messages |

## 方案优势

1. **Python ContextBuilder 复用** - 智能裁剪、话题检测、Profile 注入
2. **AI SDK 原生流式** - `streamText` 最佳体验
3. **LLM 调用规范统一** - 前后端使用相同的火山引擎配置
4. **改动最小** - 只需新增一个 API 端点
