# VibeLife 架构决策文档

> **访谈日期**: 2026-01-07
> **基于文档**: matrix-strategy-architecture.md, implementation-status-analysis.md
> **决策状态**: 已确认

---

## 1. 访谈结论汇总

### 1.1 核心架构决策

| 决策点 | 选择 | 说明 |
|--------|------|------|
| **前端框架** | Vercel AI SDK 6 | 全面采用 useChat + SSE + Generative UI |
| **后端框架** | Python FastAPI | 保留 Vibe Engine、Portrait Service、Knowledge Retrieval |
| **认证方案** | Clerk | Vercel 生态首选，webhook 写入 PostgreSQL |
| **数据库** | 统一 PostgreSQL | Clerk + 支付 + 业务数据全部在同一 DB |
| **子域名架构** | Phase 1 必须 | bazi.vibelife.app / zodiac.vibelife.app |
| **支付系统** | Phase 1 必须 | 参照 matrix 文档实现 |
| **时间线** | 无硬性 deadline | 质量优先 |

### 1.2 功能决策

| 功能 | 决策 | 说明 |
|------|------|------|
| **Voice Mode** | Bug，需修复 | 前端需传递 voice_mode 给后端 |
| **RAG 知识库** | Phase 1 必须启用 | 八字/星座知识库是核心竞争力 |
| **访谈流程** | 深度服务默认 + 可跳过 | 给用户选择权 |
| **报告生成** | lite + full 两种 | lite 免费 + full 付费解锁 |
| **多语言** | 中英双语 | Phase 1 支持切换 |

### 1.3 UI 策略

| 组件类型 | 来源 | 说明 |
|----------|------|------|
| 品牌特色组件 | 保留现有 | LuminousPaper、BreathAura、InsightCard |
| 聊天状态管理 | AI SDK useChat | 自动流式、重试、中断 |
| 动态卡片生成 | AI SDK Generative UI | LLM 返回结构化数据，前端渲染组件 |
| 命盘/星盘图表 | 保留现有 | 专业可视化已实现 |

---

## 2. 代码 Review 发现的问题

### 2.1 Critical（必须修复）

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 1 | **API 字段不匹配** | 前端 `skill_id` vs 后端 `skill` | API 调用 400 错误 |
| 2 | **用户上下文缺失** | chat.py:164 `get_user_profile(None)` | 所有用户共享默认 profile |
| 3 | **Mock 支付暴露** | payment.py:245 `/mock-pay` | 任何人可标记支付完成 |
| 4 | **支付数据内存存储** | payment.py:136 `_payment_sessions = {}` | 重启丢失支付状态 |

### 2.2 High（Phase 1 需修复）

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 5 | **voice_mode 未传递** | ChatContainer.tsx | 用户切换无效 |
| 6 | **流式未使用** | ChatContainer.tsx | 长响应体验差 |
| 7 | **报告持久化 stub** | report.py:123+ | 报告无法保存/检索 |
| 8 | **会话列表 stub** | chat.py:396-424 | 用户无法查看历史会话 |
| 9 | **RAG 未启用** | context.py | knowledge_chunks 参数未使用 |

### 2.3 Medium（Phase 2 可修复）

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| 10 | **Token 刷新竞态** | api.ts | 多个 401 同时触发刷新 |
| 11 | **错误处理不一致** | 所有 routes | HTTPException vs Response model 混用 |
| 12 | **Profile 大小无限制** | portrait.py | 可能超出 token 预算 |
| 13 | **deep_merge 重复** | portrait.py + profile_repo.py | 维护性问题 |

---

## 3. Vercel AI SDK 6 集成方案

### 3.1 架构概览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Vercel AI SDK 6 集成架构                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Frontend (Next.js + AI SDK 6)                                         │
│   ┌─────────────────────────────────────────────────────────┐           │
│   │                                                         │           │
│   │  useChat({                                              │           │
│   │    api: '/api/chat',        // Next.js Route Handler   │           │
│   │    streamProtocol: 'text',  // 或 'data' for tools     │           │
│   │  })                                                     │           │
│   │       │                                                 │           │
│   │       ▼                                                 │           │
│   │  /api/chat/route.ts (Next.js Route Handler)            │           │
│   │       │                                                 │           │
│   │       ▼ 转发请求到 Python 后端                          │           │
│   │  fetch('https://api.vibelife.app/chat/stream')         │           │
│   │       │                                                 │           │
│   │       ▼ 转换 SSE 格式为 AI SDK 协议                     │           │
│   │  return new StreamingTextResponse(transformedStream)   │           │
│   │                                                         │           │
│   └─────────────────────────────────────────────────────────┘           │
│                         │                                               │
│                         ▼                                               │
│   Python Backend (FastAPI)                                              │
│   ┌─────────────────────────────────────────────────────────┐           │
│   │                                                         │           │
│   │  POST /chat/stream                                      │           │
│   │       │                                                 │           │
│   │       ▼                                                 │           │
│   │  返回 AI SDK 兼容的 SSE 格式：                          │           │
│   │  data: {"type":"text-delta","textDelta":"你好"}        │           │
│   │  data: {"type":"text-delta","textDelta":"！"}          │           │
│   │  data: {"type":"finish","finishReason":"stop"}         │           │
│   │                                                         │           │
│   └─────────────────────────────────────────────────────────┘           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 后端 SSE 格式适配

**当前格式** (自定义):
```
data: {"type": "chunk", "content": "你好"}
data: {"type": "done", "conversation_id": "..."}
```

**AI SDK 要求格式**:
```
data: {"type": "text-delta", "textDelta": "你好"}
data: {"type": "finish", "finishReason": "stop", "usage": {...}}
```

**适配方案** - 修改 `apps/api/routes/chat.py`:

```python
# 新的 SSE 事件格式
async def stream_chat_sse(response_generator, conversation_id: str):
    async for chunk in response_generator:
        yield {
            "event": "message",
            "data": json.dumps({
                "type": "text-delta",
                "textDelta": chunk
            })
        }

    # 结束事件
    yield {
        "event": "message",
        "data": json.dumps({
            "type": "finish",
            "finishReason": "stop",
            "metadata": {"conversationId": str(conversation_id)}
        })
    }
```

### 3.3 前端 useChat 配置

```typescript
// apps/web/src/hooks/useVibeChat.ts
import { useChat } from '@ai-sdk/react';

export function useVibeChat(skillId: string, voiceMode: string) {
  return useChat({
    api: '/api/chat',
    body: {
      skill: skillId,           // 统一用 skill
      voice_mode: voiceMode,    // 传递 voice_mode
    },
    streamProtocol: 'data',     // AI SDK data stream protocol
    onFinish: (message) => {
      // 处理完成事件，提取 metadata
      const metadata = message.annotations?.[0];
      if (metadata?.conversationId) {
        // 更新会话 ID
      }
    },
    onError: (error) => {
      // 统一错误处理
      console.error('Chat error:', error);
    },
  });
}
```

### 3.4 Generative UI 实现（动态卡片）

```typescript
// apps/web/src/app/api/chat/route.ts
import { streamUI } from 'ai/rsc';
import { z } from 'zod';
import { InsightCard } from '@/components/core/InsightCard';
import { KLineChart } from '@/components/fortune/KLineChart';

export async function POST(req: Request) {
  const { messages, skill, voice_mode } = await req.json();

  const result = await streamUI({
    model: customModel, // 包装 Python 后端调用
    messages,
    tools: {
      showInsightCard: {
        description: '展示洞察卡片，用于呈现性格特点、运势分析等',
        parameters: z.object({
          title: z.string(),
          content: z.string(),
          type: z.enum(['personality', 'career', 'relationship', 'fortune']),
        }),
        generate: async ({ title, content, type }) => {
          return <InsightCard title={title} content={content} type={type} />;
        },
      },
      showKLine: {
        description: '展示人生K线图',
        parameters: z.object({
          userId: z.string(),
          startYear: z.number(),
          endYear: z.number(),
        }),
        generate: async ({ userId, startYear, endYear }) => {
          const data = await fetchKLineData(userId, startYear, endYear);
          return <KLineChart data={data} />;
        },
      },
      showRelationshipCard: {
        description: '展示关系分析卡片',
        parameters: z.object({
          score: z.number(),
          aspects: z.array(z.object({
            name: z.string(),
            score: z.number(),
            description: z.string(),
          })),
        }),
        generate: async ({ score, aspects }) => {
          return <RelationshipCard score={score} aspects={aspects} />;
        },
      },
    },
  });

  return result.toDataStreamResponse();
}
```

---

## 4. 实施路线图

### Phase 1 核心任务

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Phase 1 实施顺序                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Week 1: 基础架构                                                       │
│   ─────────────────                                                      │
│   [ ] 1.1 修复 skill_id → skill 字段名                                  │
│   [ ] 1.2 集成 Clerk 认证                                               │
│   [ ] 1.3 后端 SSE 格式适配 AI SDK                                      │
│   [ ] 1.4 前端 useChat hook 集成                                        │
│                                                                          │
│   Week 2: 核心功能                                                       │
│   ─────────────────                                                      │
│   [ ] 2.1 voice_mode 完整链路                                           │
│   [ ] 2.2 RAG 知识库启用                                                │
│   [ ] 2.3 访谈流程前端集成                                              │
│   [ ] 2.4 用户 profile 持久化                                           │
│                                                                          │
│   Week 3: 子域名 + 支付                                                  │
│   ─────────────────                                                      │
│   [ ] 3.1 路由组重构 (bazi)/ (zodiac)/                                  │
│   [ ] 3.2 middleware.ts 子域名路由                                       │
│   [ ] 3.3 Stripe 支付集成                                               │
│   [ ] 3.4 订阅状态管理                                                  │
│                                                                          │
│   Week 4: 报告 + 打磨                                                    │
│   ─────────────────                                                      │
│   [ ] 4.1 报告持久化完成                                                │
│   [ ] 4.2 lite/full 报告流程                                            │
│   [ ] 4.3 Generative UI 动态卡片                                        │
│   [ ] 4.4 中英双语切换                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 关键文件修改清单

| 文件 | 修改内容 | 优先级 |
|------|----------|--------|
| `apps/web/src/lib/api.ts` | `skill_id` → `skill` | P0 |
| `apps/web/src/components/chat/ChatContainer.tsx` | 改用 useChat + 传递 voice_mode | P0 |
| `apps/api/routes/chat.py` | SSE 格式适配 + 认证集成 | P0 |
| `apps/api/routes/chat.py:164` | 获取真实用户 profile | P0 |
| `apps/api/routes/payment.py` | 删除 mock-pay，完善 Stripe | P0 |
| `apps/api/services/vibe_engine/context.py` | 启用 knowledge_chunks | P1 |
| `apps/web/src/middleware.ts` | 完善子域名路由 | P1 |
| `apps/api/stores/report_repo.py` | 报告持久化 | P1 |

---

## 5. 技术栈确认

```
Frontend
────────
• Next.js 14+ (App Router)
• Vercel AI SDK 6
• TypeScript
• Tailwind CSS
• 现有品牌组件 (LuminousPaper, BreathAura, InsightCard)

Backend
───────
• Python 3.11+
• FastAPI
• asyncpg (PostgreSQL)
• httpx (LLM 调用)
• Vibe Engine (Context, Portrait, LLM)

Infrastructure
──────────────
• Vercel (Frontend)
• Railway/Render/自有服务器 (Python Backend)
• PostgreSQL (Supabase/Railway/自有)
• Clerk (认证)
• Stripe (支付)

LLM Providers
─────────────
• Primary: Zhipu GLM-4-Plus
• Fallback: Claude Sonnet
• Vision: GLM-4V-Plus (可选)
```

---

## 6. 待确认事项

以下问题在后续实施中需要确认：

1. **Clerk webhook 端点**: 放在 Python 后端还是 Next.js API Routes？
2. **Stripe webhook 端点**: 同上
3. **子域名 Cookie 域名**: `.vibelife.app` 还是各子域名独立？
4. **报告 PDF 生成**: 服务端生成还是客户端生成？
5. **命盘/星盘计算**: 继续用 Python 还是迁移到前端 JS 库？

---

## 7. Nano Banana 海报图生成架构

### 7.1 概述

| 决策点 | 选择 | 说明 |
|--------|------|------|
| **图像生成 API** | Google Gemini Imagen (Nano Banana) | 图文一体输出，支持中文 |
| **服务集成** | VibeLife 调用 gemini_tool API | gemini_tool 作为独立微服务 |
| **生成模式** | 混合（简单同步 + 复杂异步） | 按场景选择 |
| **存储位置** | 自有服务器 | 文件系统存储 |
| **缓存策略** | 永久存储 | 生成后永久保存 |

### 7.2 海报场景（Spec v3.0 定义）

| 场景 | 模板名称 | 比例 | 说明 |
|------|----------|------|------|
| 个人报告（八字）| `bazi_personal_poster` | 16:9 | 东方神秘风格，五行意象 |
| 个人报告（星座）| `zodiac_personal_poster` | 16:9 | 星空主题，星座符号 |
| 关系匹配 | `relationship_poster` | 1:1 | 双人元素互动 |
| 运势卡片 | `fortune_card` | 9:16 | 月/周/日运势，手机壁纸尺寸 |
| 社交分享 | `social_share_card` | 1:1 或 4:5 | 简洁符号化设计 |

### 7.3 集成架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        海报图生成架构                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   VibeLife Backend (FastAPI)                                            │
│   ┌─────────────────────────────────────────────────────────┐           │
│   │                                                         │           │
│   │  POST /api/v1/report/image                              │           │
│   │       │                                                 │           │
│   │       ▼                                                 │           │
│   │  1. 根据 skill + scene 选择 prompt 模板                 │           │
│   │  2. 填充用户数据（五行/星座/关系等）                    │           │
│   │  3. 调用 gemini_tool API                               │           │
│   │                                                         │           │
│   └─────────────────────────────────────────────────────────┘           │
│                         │                                               │
│                         ▼ POST /create_gemini_job                       │
│   ┌─────────────────────────────────────────────────────────┐           │
│   │  gemini_tool (独立微服务 :6222)                         │           │
│   │                                                         │           │
│   │  GeminiJobRequest {                                     │           │
│   │    job_name: "report_poster_user123",                   │           │
│   │    tasks: [{                                            │           │
│   │      model: "gemini-imagen",                            │           │
│   │      task_name: "bazi_poster",                          │           │
│   │      prompt: "东方神秘风格垂直海报...",                 │           │
│   │      output_file_type: "png"                            │           │
│   │    }],                                                  │           │
│   │    priority: 50                                         │           │
│   │  }                                                      │           │
│   │                                                         │           │
│   │  → Playwright 自动化 → Gemini Web → 生成图片            │           │
│   │  → 保存到服务器文件系统                                 │           │
│   │                                                         │           │
│   └─────────────────────────────────────────────────────────┘           │
│                         │                                               │
│                         ▼ 同步返回 或 轮询/Webhook                      │
│   ┌─────────────────────────────────────────────────────────┐           │
│   │  返回图片 URL                                           │           │
│   │  https://api.vibelife.app/static/posters/xxx.png       │           │
│   └─────────────────────────────────────────────────────────┘           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.4 Prompt 模板示例（八字个人海报）

```
东方神秘风格垂直海报，16:9 比例

主视觉：{daymaster_element}属性的意象化人物剪影
- 甲木：参天大树的剪影，向上生长
- 丙火：太阳光芒，温暖明亮
- 戊土：山峦起伏，稳重厚实
- 庚金：月光剑影，锐利清冷
- 壬水：流水波纹，灵动深邃

背景：水墨山水风格，{season}季节氛围
色调：{element_color}为主色调
- 木→青绿  火→朱红  土→赭黄  金→银白  水→玄黑

文字区域（下方 1/3）：
- 主标题：「{user_name}的命格解读」
- 副标题：{daymaster}日主 · {pattern}格局
- 金句：{core_insight}

风格要求：
- 东方美学，留白适度
- 意境深远，不写实
- 文字清晰可读
- 整体神秘而温暖
```

### 7.5 实施任务

| 任务 | 优先级 | 说明 |
|------|--------|------|
| VibeLife 后端添加 `/report/image` 端点 | P1 | 调用 gemini_tool |
| Prompt 模板管理（5 种场景） | P1 | 存储在数据库或配置文件 |
| gemini_tool 服务部署 | P1 | 确保 :6222 可访问 |
| 异步任务状态查询 | P2 | 前端轮询或 Webhook |
| 图片 CDN 加速 | P2 | 可选，提升加载速度 |

---

## 附录 A: Chat 流程技术参考

### A.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FRONTEND (Next.js)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    onSend()    ┌──────────────────┐                       │
│  │  ChatInput   │ ─────────────► │  ChatContainer   │                       │
│  │  (textarea)  │                │   handleSend()   │                       │
│  └──────────────┘                └────────┬─────────┘                       │
│                                           │                                  │
│                                           ▼                                  │
│                                  ┌──────────────────┐                       │
│                                  │    api.ts        │                       │
│                                  │  sendMessage()   │                       │
│                                  └────────┬─────────┘                       │
│                                           │                                  │
└───────────────────────────────────────────┼─────────────────────────────────┘
                                            │ POST /api/v1/chat/
                                            │ Authorization: Bearer {token}
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND (FastAPI)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐                                                       │
│  │  routes/chat.py  │  POST /chat/                                          │
│  │  ───────────────                                                         │
│  │  1. parse_skill()                                                        │
│  │  2. get_user_profile()                                                   │
│  │  3. get_conversation_history()                                           │
│  │  4. save_message(user)                                                   │
│  └────────┬─────────┘                                                       │
│           │                                                                  │
│           ▼                                                                  │
│  ┌────────────────────────────────────────────────────────────┐             │
│  │              VIBE ENGINE (services/vibe_engine/)           │             │
│  │  ┌─────────────────┐      ┌─────────────────────────────┐  │             │
│  │  │  context.py     │      │  llm.py                     │  │             │
│  │  │  ContextBuilder │ ───► │  LLMService                 │  │             │
│  │  │  ─────────────  │      │  ────────────               │  │             │
│  │  │  • system_prompt│      │  • Zhipu (primary)         │  │             │
│  │  │  • topic分类    │      │  • Claude (fallback)       │  │             │
│  │  │  • profile选择  │      │  • Gemini (backup)         │  │             │
│  │  │  • history格式化│      └─────────────────────────────┘  │             │
│  │  └─────────────────┘                                       │             │
│  └────────────────────────────────────────────────────────────┘             │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────┐                                                       │
│  │  5. save_message │  (assistant response)                                 │
│  │  6. return JSON  │                                                       │
│  └──────────────────┘                                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### A.2 数据流转

```
用户输入          前端 Request            后端 Request
─────────         ────────────            ────────────
"我是90年         {                       ChatRequest(
 5月15日           message: "...",         message="...",
 出生的"           skill: "bazi",          skill="bazi",
                   conversation_id:null    conversation_id=None,
                 }                         voice_mode="warm"
                                         )

═══════════════════════════════════════════════════════════════

LLM Messages
────────────
[
  {role: "system", content: "# Vibe 人设\n你是Vibe..."},
  {role: "user", content: "[历史] 你好"},
  {role: "assistant", content: "[历史] 你好呀！..."},
  {role: "user", content: "我是90年5月15日出生的"}   ← current
]

═══════════════════════════════════════════════════════════════

后端 Response             前端 Response           UI 渲染
────────────              ────────────            ────────
ChatResponse(             {                       ┌──────────────────┐
  content="根据...",       content: "根据...",    │ 用户: 我是90年...│
  conversation_id=uuid,    conversation_id:uuid,  ├──────────────────┤
  skill="bazi",            skill: "bazi",         │ Vibe: 根据你的   │
  voice_mode="warm",       metadata: {...}        │      八字...     │
  metadata={...}         }                        └──────────────────┘
)
```

### A.3 关键代码文件清单

| 层级 | 文件路径 | 核心功能 |
|------|----------|----------|
| 前端输入 | `apps/web/src/components/chat/ChatInput.tsx` | 文本输入框组件 |
| 前端容器 | `apps/web/src/components/chat/ChatContainer.tsx` | 消息状态管理、API调用 |
| 前端消息 | `apps/web/src/components/chat/ChatMessage.tsx` | 消息气泡渲染 |
| API客户端 | `apps/web/src/lib/api.ts` | HTTP请求封装、token管理 |
| 后端路由 | `apps/api/routes/chat.py` | `/chat/` 端点处理 |
| 上下文构建 | `apps/api/services/vibe_engine/context.py` | system prompt、话题分类 |
| LLM调用 | `apps/api/services/vibe_engine/llm.py` | Zhipu/Claude 调用 |
| 用户画像 | `apps/api/services/vibe_engine/portrait.py` | profile 数据结构 |
| 会话存储 | `apps/api/stores/conversation_repo.py` | 会话持久化 |
| 消息存储 | `apps/api/stores/message_repo.py` | 消息持久化 |

### A.4 配置参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 历史消息限制 | 20条 | get_conversation_history limit |
| Profile上下文 | ~1000 tokens | 画像片段大小限制 |
| 总Token预算 | 8000 | 完整上下文窗口 |
| 响应Token | 4096 | max_tokens 默认值 |
| Primary LLM | glm-4-plus | Zhipu 智谱 |
| Fallback LLM | claude-sonnet | Anthropic Claude |

---

## 参考资源

- [AI SDK 6 Documentation](https://ai-sdk.dev/docs/introduction)
- [AI SDK 6 Blog Post](https://vercel.com/blog/ai-sdk-6)
- [AI Elements Components](https://vercel.com/changelog/introducing-ai-elements)
- [Clerk Documentation](https://clerk.com/docs)
- [Stripe Checkout](https://stripe.com/docs/payments/checkout)
- [gemini_tool 项目](~/work/gemini_tool/) - 海报图生成微服务
