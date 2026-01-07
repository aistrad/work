# Mentis OS v3.0 全新构建计划

> **核心决策:** 在 `/home/aiscend/work/mentis` 目录下**彻底独立重建** Mentis OS 项目，使用独立的 `mentis` 数据库；`fortune_ai` 项目**完整保留**，后续可作为参考或数据迁移源。

---

## 0. 一句话目标

构建一个全新的 **Stream-Centric Agentic Personal OS**：
**"Life is a Stream, not a Dashboard."** —— 生活流成为输入，进化成为输出；Dashboard 退居背景，Agent 主动干预成为灵魂。

---

## 1. 项目边界与决策

| 决策项 | 选择 |
|--------|------|
| 项目位置 | `/home/aiscend/work/mentis` (全新独立) |
| 数据库 | `mentis` (全新独立 PostgreSQL DB) |
| fortune_ai | **完整保留**，不做任何修改 |
| 规格对齐 | **严格对齐** Mentis OS v3.0 规格文档 |
| 主 Runtime | **Next.js API Routes** (Vercel AI SDK) |
| 向量存储 | **Pinecone** (DB 只存 embedding_id) |
| LLM 主力 | **GLM-4** (国内优先) + 多模型降级 |

---

## 2. 三层交互模型 (Mentis OS 核心不可变)

### Layer 1: THE STREAM (核心交互区，90% 时间)
- **Vibe Diary**（碎碎念/情绪日记）是最高频入口
- **Action Cards** 与 Chat 都"融入流中"
- 每次输入必须产生**即时微反馈**：AI Tag / 能量变化 / Aura 变化

### Layer 2: THE HUD (Ambient HUD，环境感知层)
- Dashboard 不再是独立页面，而是**围绕 Stream 的背景环境层**
- 常态隐形，以 Dynamic Aura、边缘微光、数字浮动等方式被动呈现
- 仅在状态剧烈变化或用户呼出时显现

### Layer 3: THE INTERVENTION (主动干预层)
- Agent 不等待提问，基于 Stream + 模块数据 + 时间节点主动插入 Action Cards
- 触发条件：时间节点 / 情绪阈值 / 能量变化 / 行为模式 / 运势窗口

---

## 3. 项目结构 (全新构建)

```
/home/aiscend/work/mentis/
├── apps/
│   └── web/                          # Next.js 16 (App Router)
│       ├── src/
│       │   ├── app/
│       │   │   ├── (stream)/         # Stream 主页面
│       │   │   │   ├── page.tsx      # StreamFeed + MagicInput + HUD
│       │   │   │   └── layout.tsx
│       │   │   ├── api/v3/           # Mentis v3 API (主 Runtime)
│       │   │   │   ├── auth/         # JWT 认证
│       │   │   │   ├── stream/       # POST (SSE) / GET
│       │   │   │   ├── decode/       # BaZi/ZiWei/Fortune
│       │   │   │   ├── evolve/       # Tasks/Checkin/Momentum
│       │   │   │   └── user/         # Profile/State
│       │   │   └── (landing)/        # 落地页
│       │   ├── components/
│       │   │   ├── stream/           # StreamFeed, StreamCard, MagicInput
│       │   │   ├── hud/              # DynamicAura, TopStatusBar
│       │   │   ├── intervention/     # ActionCard (Suggestion/Confirmation/Insight/Milestone)
│       │   │   └── ui/               # Radix + shadcn/ui
│       │   ├── lib/
│       │   │   ├── mentis/           # 核心引擎
│       │   │   │   ├── stream-processor.ts
│       │   │   │   ├── emotion-engine.ts
│       │   │   │   ├── behavior-matcher.ts
│       │   │   │   └── intervention-agent.ts
│       │   │   ├── db/               # Drizzle ORM
│       │   │   │   ├── schema.ts
│       │   │   │   └── client.ts
│       │   │   ├── vector/           # Pinecone 客户端
│       │   │   └── llm/              # 多模型路由
│       │   └── stores/               # Zustand
│       │       └── mentis-store.ts
│       ├── drizzle/                  # Drizzle Migrations
│       ├── public/
│       └── package.json
├── packages/
│   ├── decode-modules/               # DECODE 层模块
│   │   ├── bazi/                     # 八字 (可从 fortune_ai 迁移算法)
│   │   └── ziwei/                    # 紫微斗数
│   ├── reframe-modules/              # REFRAME 层模块
│   │   ├── cbt/                      # 认知行为疗法
│   │   └── act/                      # 接纳承诺疗法
│   └── evolve-modules/               # EVOLVE 层模块
│       ├── habit/                    # 习惯系统
│       └── momentum/                 # 动量系统
├── docs/
│   └── specs/                        # 规格文档
├── .env.example
├── package.json                      # Monorepo root (pnpm workspace)
├── pnpm-workspace.yaml
└── turbo.json                        # Turborepo 配置
```

---

## 4. 数据模型 (严格对齐 Mentis OS 规格)

### 4.1 核心实体命名 (规格强制)

| Mentis OS 规格实体 | 用途 |
|-------------------|------|
| `mentis_user` | 用户主表 |
| `user_profile` | 用户档案 (生辰/命盘缓存/MBTI/偏好/通知设置) |
| `user_state` | 用户实时状态 (energy/momentum/streak/mood/aura) |
| `stream_entry` | Stream 条目 (Vibe Diary/Chat/Action Log) |
| `action_task` | 任务卡片 (Suggestion/Confirmation/Insight/Milestone) |
| `checkin_log` | 行为打卡日志 |
| `insight_record` | 洞察沉淀 (Weekly Mirror/Pattern/Fortune) |

### 4.2 数据库 Schema (Drizzle ORM)

```typescript
// apps/web/src/lib/db/schema.ts
import { pgTable, uuid, text, integer, timestamp, jsonb, varchar, decimal, date, boolean } from 'drizzle-orm/pg-core';

// ═══════════════════════════════════════════════════════════════
// mentis_user - 用户主表
// ═══════════════════════════════════════════════════════════════
export const mentisUser = pgTable('mentis_user', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: varchar('name', { length: 100 }),
  tier: varchar('tier', { length: 20 }).notNull().default('free'), // free/pro/premium
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// ═══════════════════════════════════════════════════════════════
// user_profile - 用户档案
// ═══════════════════════════════════════════════════════════════
export const userProfile = pgTable('user_profile', {
  userId: uuid('user_id').primaryKey().references(() => mentisUser.id),
  birthTime: timestamp('birth_time'),              // 生辰
  birthLocation: jsonb('birth_location'),          // {lat, lng, timezone}
  baziData: jsonb('bazi_data'),                    // 八字缓存
  ziweiData: jsonb('ziwei_data'),                  // 紫微缓存
  mbtiType: varchar('mbti_type', { length: 4 }),
  jungArchetype: varchar('jung_archetype', { length: 50 }),
  preferences: jsonb('preferences').default({}),
  notificationSettings: jsonb('notification_settings').default({}),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// ═══════════════════════════════════════════════════════════════
// user_state - 用户实时状态
// ═══════════════════════════════════════════════════════════════
export const userState = pgTable('user_state', {
  userId: uuid('user_id').primaryKey().references(() => mentisUser.id),
  energyScore: integer('energy_score').notNull().default(50),    // 0-100
  momentum: integer('momentum').notNull().default(0),
  streakDays: integer('streak_days').notNull().default(0),
  currentMood: jsonb('current_mood'),               // {primary, intensity, detected_at}
  auraState: varchar('aura_state', { length: 20 }).default('calm'), // calm/alert/happy/anxious/flow
  todayStats: jsonb('today_stats').default({}),
  lastActiveAt: timestamp('last_active_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// ═══════════════════════════════════════════════════════════════
// stream_entry - Stream 条目
// ═══════════════════════════════════════════════════════════════
export const streamEntry = pgTable('stream_entry', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => mentisUser.id),
  type: varchar('type', { length: 20 }).notNull().default('vibe_diary'), // vibe_diary/chat/action_log
  rawContent: text('raw_content').notNull(),
  media: jsonb('media').default([]),               // [{type, url, transcription?}]

  // 情绪提取结果
  emotion: jsonb('emotion'),                        // {primary, intensity, secondary[], confidence}
  context: jsonb('context'),                        // {scene, trigger, target, time_of_day}
  tags: text('tags').array().default([]),
  energyDelta: integer('energy_delta').default(0),

  // 行为匹配
  matchedBehavior: varchar('matched_behavior', { length: 50 }),
  matchConfidence: decimal('match_confidence', { precision: 3, scale: 2 }),
  autoCheckin: boolean('auto_checkin').default(false),

  // 向量引用 (向量存 Pinecone，这里只存 ID)
  embeddingId: varchar('embedding_id', { length: 100 }),

  metadata: jsonb('metadata').default({}),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// ═══════════════════════════════════════════════════════════════
// action_task - 任务卡片
// ═══════════════════════════════════════════════════════════════
export const actionTask = pgTable('action_task', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => mentisUser.id),
  type: varchar('type', { length: 20 }).notNull(),  // suggestion/confirmation/insight/milestone
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description'),
  momentumReward: integer('momentum_reward').default(1),

  status: varchar('status', { length: 20 }).default('pending'), // pending/completed/dismissed/expired
  triggerType: varchar('trigger_type', { length: 20 }),         // time/state/behavior/fortune
  triggerTime: timestamp('trigger_time'),
  expiresAt: timestamp('expires_at'),

  relatedStreamId: uuid('related_stream_id').references(() => streamEntry.id),
  metadata: jsonb('metadata').default({}),
  createdAt: timestamp('created_at').defaultNow(),
  completedAt: timestamp('completed_at'),
});

// ═══════════════════════════════════════════════════════════════
// checkin_log - 行为打卡日志
// ═══════════════════════════════════════════════════════════════
export const checkinLog = pgTable('checkin_log', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => mentisUser.id),
  behaviorType: varchar('behavior_type', { length: 50 }).notNull(),
  source: varchar('source', { length: 20 }).notNull(), // auto/manual/confirmation
  momentumDelta: integer('momentum_delta').default(1),

  relatedStreamId: uuid('related_stream_id').references(() => streamEntry.id),
  relatedTaskId: uuid('related_task_id').references(() => actionTask.id),
  metadata: jsonb('metadata').default({}),
  createdAt: timestamp('created_at').defaultNow(),
});

// ═══════════════════════════════════════════════════════════════
// insight_record - 洞察沉淀
// ═══════════════════════════════════════════════════════════════
export const insightRecord = pgTable('insight_record', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => mentisUser.id),
  type: varchar('type', { length: 30 }).notNull(),  // weekly_mirror/pattern/fortune_insight/reflection
  title: varchar('title', { length: 255 }),
  content: text('content'),
  data: jsonb('data'),                              // 结构化数据

  periodStart: date('period_start'),
  periodEnd: date('period_end'),
  isRead: boolean('is_read').default(false),
  createdAt: timestamp('created_at').defaultNow(),
});

// 索引
// CREATE INDEX idx_stream_entry_user ON stream_entry(user_id, created_at DESC);
// CREATE INDEX idx_action_task_user ON action_task(user_id, status, created_at DESC);
// CREATE INDEX idx_checkin_log_user ON checkin_log(user_id, created_at DESC);
```

### 4.3 向量存储策略 (严格对齐规格)

```
Pinecone Namespaces:
├── stream_embeddings     # Stream 条目向量
├── behavior_library      # 行为库向量 (用于 NLU 匹配)
└── knowledge_base        # 模块知识库向量

PostgreSQL 只存引用:
├── stream_entry.embedding_id  → Pinecone stream_embeddings
└── 行为库元数据可选存 DB，向量必须在 Pinecone
```

---

## 5. API 设计 (严格对齐 Mentis OS 规格)

### 5.1 路由版本化

```
BASE URL: /api/v3

PUBLIC:
├── POST /auth/register
├── POST /auth/login
├── POST /auth/refresh
└── POST /landing/quick-insight

STREAM:
├── POST /stream              → SSE 流式响应
├── GET  /stream              → 历史列表
├── GET  /stream/:id          → 单条详情
└── DELETE /stream/:id        → 删除

DECODE:
├── POST /decode/bazi         → 八字计算
├── POST /decode/ziwei        → 紫微计算
├── GET  /decode/fortune/today
└── GET  /decode/fortune/:date

EVOLVE:
├── GET  /tasks               → 待办列表
├── POST /tasks/:id/complete
├── POST /tasks/:id/dismiss
├── POST /checkin             → 手动打卡
└── GET  /momentum            → 动量历史

USER:
├── GET  /user/profile
├── PUT  /user/profile
├── GET  /user/state
└── PUT  /user/preferences

REALTIME:
└── WS   /realtime            → WebSocket
```

### 5.2 `POST /v3/stream` SSE 事件契约 (规格强制)

```typescript
// apps/web/src/app/api/v3/stream/route.ts
import { StreamingTextResponse } from 'ai';

export async function POST(request: Request) {
  const { content, type, media } = await request.json();
  const userId = await getCurrentUserId(request);
  const requestId = generateRequestId();

  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      const send = (event: string, data: any) => {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ event, data, request_id: requestId })}\n\n`));
      };

      try {
        // Event 1: stream_created
        const entry = await createStreamEntry(userId, { content, type, media });
        send('stream_created', { id: entry.id, type, raw_content: content, created_at: entry.createdAt });

        // Event 2: extraction_complete
        const extraction = await extractEmotionAndContext(content);
        await updateStreamEntry(entry.id, extraction);
        send('extraction_complete', {
          emotion: extraction.emotion,
          context: extraction.context,
          tags: extraction.tags,
          energy_delta: extraction.energyDelta
        });

        // Event 3: state_update
        const state = await updateUserState(userId, extraction.energyDelta, extraction.emotion);
        send('state_update', {
          energy_score: state.energyScore,
          momentum: state.momentum,
          aura_state: state.auraState
        });

        // Event 4: behavior_match (可选)
        const match = await matchBehavior(content, userId);
        if (match.matched) {
          await recordCheckin(userId, match, entry.id);
          send('behavior_match', {
            matched: true,
            behavior: match.behavior,
            confidence: match.confidence,
            auto_checkin: match.autoCheckin,
            momentum_delta: match.momentumDelta
          });
        }

        // Event 5: agent_response (可选)
        const intervention = await evaluateIntervention(userId, extraction.emotion, state);
        if (intervention) {
          const task = await createActionTask(userId, intervention);
          send('agent_response', {
            type: 'action_card',
            card: task
          });
        }

        // Event 6: done
        send('done', {});

      } catch (error) {
        send('error', { code: 'server/internal-error', message: error.message, request_id: requestId });
      } finally {
        controller.close();
      }
    }
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Request-Id': requestId,
    }
  });
}
```

### 5.3 统一错误格式 (规格强制)

```typescript
interface ErrorResponse {
  error: {
    code: string;        // 错误代码
    message: string;     // 用户友好信息
    details?: any;       // 详细信息 (仅开发环境)
    request_id: string;  // 必须携带
  };
}

// Error Codes (规格定义)
const ERROR_CODES = {
  // Auth (401)
  'auth/invalid-token': 'Token 无效',
  'auth/token-expired': 'Token 已过期',
  'auth/missing-token': '缺少 Token',

  // Permission (403)
  'permission/denied': '权限不足',
  'permission/tier-required': '需要升级订阅',

  // Resource (404)
  'resource/user-not-found': '用户不存在',
  'resource/stream-not-found': 'Stream 不存在',

  // Validation (400)
  'validation/error': '参数校验失败',
  'validation/invalid-birth-time': '生辰格式错误',

  // Rate Limit (429)
  'rate-limit/exceeded': '请求过于频繁',

  // Server (500)
  'server/internal-error': '服务器内部错误',
  'server/ai-service-error': 'AI 服务异常',
};
```

### 5.4 认证策略 (规格对齐)

```typescript
// 认证方式
Web:     NextAuth v5 → Cookie 会话 + JWT 签发
API:     Bearer Token (JWT)
Mobile:  直接 Bearer Token

// JWT Payload
interface JWTPayload {
  sub: string;      // user_id
  email: string;
  tier: 'free' | 'pro' | 'premium';
  iat: number;
  exp: number;
}

// 权限控制
const tierGating = {
  free: ['bazi', 'fortune_today', 'vibe_diary', 'basic_emotion'],
  pro: [...free, 'ziwei', 'weekly_mirror', 'photo_input', 'advanced_emotion'],
  premium: [...pro, 'cbt', 'act', 'voice_persona', 'calendar_sync']
};
```

---

## 6. 核心引擎实现

### 6.1 Stream Processor

```typescript
// apps/web/src/lib/mentis/stream-processor.ts
interface StreamInput {
  content: string;
  type: 'vibe_diary' | 'chat';
  media?: { type: 'image' | 'audio'; url: string }[];
  metadata?: { location?: LatLng; device?: string };
}

interface ExtractionResult {
  emotion: {
    primary: string;      // joy/sadness/anger/fear/surprise/disgust/anxiety/calm
    intensity: number;    // 1-10
    secondary: string[];
    confidence: number;
  };
  context: {
    scene: string;        // work/home/social/outdoor/...
    trigger: string;
    target: string;
    timeOfDay: string;
  };
  tags: string[];
  energyDelta: number;
}
```

### 6.2 Emotion Engine

```typescript
// apps/web/src/lib/mentis/emotion-engine.ts
const EMOTION_TAXONOMY = {
  primary: ['joy', 'sadness', 'anger', 'fear', 'surprise', 'disgust', 'anxiety', 'calm'],
  secondary: ['frustration', 'helplessness', 'excitement', 'pride', 'guilt', 'shame',
              'loneliness', 'gratitude', 'hope', 'relief', 'jealousy', 'contempt']
};

const ENERGY_MAP: Record<string, [number, number]> = {
  joy: [2, 5],
  sadness: [-4, -2],
  anger: [-5, -3],
  fear: [-4, -2],
  surprise: [-1, 1],
  disgust: [-3, -2],
  anxiety: [-4, -2],
  calm: [0, 1]
};

function calculateEnergyDelta(emotion: string, intensity: number): number {
  const [min, max] = ENERGY_MAP[emotion] || [0, 0];
  const ratio = intensity / 10;
  return Math.round(max > 0 ? min + (max - min) * ratio : max + (min - max) * ratio);
}
```

### 6.3 Behavior Matcher (NLU → Auto Checkin)

```typescript
// apps/web/src/lib/mentis/behavior-matcher.ts
// 向量匹配阈值 (规格定义)
const THRESHOLDS = {
  PENDING_TASK_PRIORITY: 0.80,  // 待办任务优先匹配
  AUTO_CHECKIN: 0.85,           // >= 0.85 自动确认
  CONFIRM_CARD: 0.60,           // 0.60-0.85 弹确认卡
  IGNORE: 0.60                  // < 0.60 忽略
};

async function matchBehavior(input: string, userId: string): Promise<BehaviorMatch> {
  // 1. 生成 embedding
  const embedding = await generateEmbedding(input);

  // 2. 优先匹配待办任务
  const pendingTasks = await getPendingTasks(userId);
  if (pendingTasks.length > 0) {
    const taskMatch = await matchAgainstTasks(embedding, pendingTasks);
    if (taskMatch && taskMatch.score >= THRESHOLDS.PENDING_TASK_PRIORITY) {
      return {
        matched: true,
        behavior: taskMatch.task.type,
        confidence: taskMatch.score,
        autoCheckin: taskMatch.score >= THRESHOLDS.AUTO_CHECKIN,
        taskId: taskMatch.task.id,
        momentumDelta: taskMatch.task.momentumReward
      };
    }
  }

  // 3. 匹配 Pinecone behavior_library
  const libraryMatch = await pinecone.query({
    namespace: 'behavior_library',
    vector: embedding,
    topK: 3
  });

  const top = libraryMatch.matches[0];
  if (!top || top.score < THRESHOLDS.IGNORE) {
    return { matched: false, confidence: top?.score || 0, autoCheckin: false };
  }

  return {
    matched: true,
    behavior: top.metadata.behaviorId,
    confidence: top.score,
    autoCheckin: top.score >= THRESHOLDS.AUTO_CHECKIN,
    momentumDelta: top.metadata.momentumReward
  };
}
```

### 6.4 多模型路由 (降级策略)

```typescript
// apps/web/src/lib/llm/model-router.ts
interface ModelConfig {
  model: string;
  provider: 'zhipu' | 'anthropic' | 'openai';
  apiKey: string;
}

const MODEL_PRIORITY = [
  { model: 'glm-4', provider: 'zhipu' },           // 主力 (国内)
  { model: 'claude-3.5-sonnet', provider: 'anthropic' },  // 降级
  { model: 'gpt-4-turbo', provider: 'openai' }    // 兜底
];

async function selectModel(tier: string, taskType: string): Promise<ModelConfig> {
  for (const config of MODEL_PRIORITY) {
    try {
      await healthCheck(config);
      return config;
    } catch {
      continue;
    }
  }
  throw new Error('All LLM providers unavailable');
}
```

---

## 7. 前端实现

### 7.1 Dynamic Aura System

```typescript
// apps/web/src/components/hud/DynamicAura.tsx
const AURA_STATES = {
  calm:    { gradient: ['#1a1a2e', '#2d3561'], particles: 'slow-rise', transition: '2s' },
  alert:   { gradient: ['#2e1a1a', '#613535'], particles: 'fast-pulse', transition: '0.5s' },
  happy:   { gradient: ['#2e2a1a', '#61553d'], particles: 'bounce', transition: '2s' },
  anxious: { gradient: ['#1a1a2e', '#3d2d61'], particles: 'irregular', transition: '1s' },
  flow:    { gradient: ['#1a2e1a', '#2d6135'], particles: 'focus', transition: '2s' }
};

// 状态转换逻辑
function getAuraState(emotion: string, energyScore: number): AuraState {
  if (emotion === 'anger' || energyScore < 30) return 'alert';
  if (emotion === 'joy' && energyScore > 80) return 'happy';
  if (emotion === 'anxiety') return 'anxious';
  if (emotion === 'focus' && energyScore > 70) return 'flow';
  return 'calm';
}
```

### 7.2 状态管理

```typescript
// apps/web/src/stores/mentis-store.ts
import { create } from 'zustand';

interface MentisStore {
  // Stream
  streamEntries: StreamEntry[];
  isStreaming: boolean;

  // User State (实时同步)
  userState: {
    energyScore: number;
    momentum: number;
    streakDays: number;
    currentMood: { primary: string; intensity: number } | null;
    auraState: 'calm' | 'alert' | 'happy' | 'anxious' | 'flow';
  };

  // Action Tasks
  pendingTasks: ActionTask[];

  // Actions
  sendStreamInput: (input: StreamInput) => Promise<void>;
  completeTask: (taskId: string) => Promise<void>;
  dismissTask: (taskId: string) => Promise<void>;

  // SSE 事件处理
  handleStreamEvent: (event: SSEEvent) => void;

  // WebSocket
  connectRealtime: () => void;
  disconnectRealtime: () => void;
}
```

---

## 8. 可观测性 (规格 SLO/SLI)

### 8.1 性能指标

| 指标 | SLO |
|------|-----|
| Stream Input → First Response | < 500ms (P95) |
| Stream Input → Complete | < 3000ms (P95) |
| Emotion Detection | < 300ms (P95) |
| Behavior Match | < 200ms (P95) |
| State Broadcast (WebSocket) | < 100ms (P95) |
| 5xx Error Rate | < 0.1% |
| AI Service Failures | < 0.5% |

### 8.2 落地手段

```typescript
// 所有请求/事件必须携带 request_id
const requestId = `req_${nanoid()}`;

// 结构化日志
logger.info('stream_processed', {
  request_id: requestId,
  user_id: userId,
  duration_ms: Date.now() - startTime,
  emotion: emotion.primary,
  energy_delta: energyDelta,
  behavior_matched: match.matched
});

// Sentry 集成
Sentry.captureException(error, {
  extra: { request_id: requestId, user_id: userId }
});
```

---

## 9. 实施路线图

### 第一周 TODO (最小闭环)

```
1. [ ] 初始化 /home/aiscend/work/mentis 项目结构 (pnpm + Turborepo)
2. [ ] 创建 mentis 数据库 + Drizzle Schema (mentis_user/user_profile/user_state/stream_entry)
3. [ ] 实现 POST /v3/stream (stream_created → extraction_complete → state_update → done)
4. [ ] 前端 StreamFeed 原型 (消费 SSE 事件)
5. [ ] HUD Aura 背景层 (calm/alert 两态)
6. [ ] 打通最小动量闭环 (user_state.momentum 更新)
```

### Sprint 1: 基础架构 + Stream 核心 (Week 1-2)

**目标:** 实现 Stream 输入闭环

| 任务 | SSE 事件 | 数据表 | 前端交互 |
|------|----------|--------|----------|
| 项目初始化 | - | - | - |
| 数据库创建 | - | mentis_user, user_profile, user_state, stream_entry | - |
| Stream API | stream_created, extraction_complete, state_update, done | stream_entry 写入 | - |
| Emotion Engine | extraction_complete | emotion/context 写入 | - |
| 前端原型 | 消费全部事件 | - | StreamFeed, MagicInput |

**验收:** 用户发送文字 → 情绪识别 → 状态更新 → SSE 完整响应

**回滚策略:** Feature flag `ENABLE_V3_STREAM`

### Sprint 2: Vibe Diary UI + 实时状态 (Week 3-4)

**目标:** 完成前端 Stream 交互

| 任务 | SSE 事件 | 数据表 | 前端交互 |
|------|----------|--------|----------|
| MagicInput 完整版 | - | - | 文字/语音/图片入口 |
| StreamCard 组件 | - | - | Vibe Diary / Chat 卡片 |
| TopStatusBar | - | - | 动量/连续天数/Aura 指示 |
| WebSocket 连接 | - | - | Pusher 实时同步 |
| user_state 实时更新 | state_update | user_state | Aura 变化 |

**验收:** 完整 Vibe Diary 输入→展示流程 + 实时状态同步

### Sprint 3: Dynamic Aura + 语音输入 (Week 5-6)

**目标:** 增强视觉反馈

| 任务 | SSE 事件 | 数据表 | 前端交互 |
|------|----------|--------|----------|
| Aura 5 种状态 | - | - | calm/alert/happy/anxious/flow |
| Whisper STT | - | media 字段 | 语音输入 |
| Vision API | - | media 字段 | 图片输入 |
| 粒子效果 | - | - | 状态转换动画 |

**验收:** 情绪变化触发 Aura 变换 + 三种输入方式

### Sprint 4: Agent 主动干预 (Week 7-8)

**目标:** 实现 Agent 推送能力

| 任务 | SSE 事件 | 数据表 | 前端交互 |
|------|----------|--------|----------|
| Behavior Matcher | behavior_match | checkin_log | 自动打卡反馈 |
| Intervention Agent | agent_response | action_task | Action Card 推送 |
| Action Cards UI | - | - | Suggestion/Confirmation |
| 长按完成交互 | - | action_task.status | 进度条 + 动量奖励 |
| Pinecone 集成 | - | embedding_id | 向量匹配 |

**验收:** Agent 主动推送卡片 + NLU 自动打卡

### Sprint 5: DECODE 模块 (Week 9-10)

**目标:** 迁移核心算法

| 任务 | API | 数据表 | 前端交互 |
|------|-----|--------|----------|
| BaZi 模块 | /decode/bazi | user_profile.bazi_data | 命盘展示 |
| Fortune 今日运势 | /decode/fortune/today | insight_record | 运势卡片 |
| Momentum 系统 | /momentum | checkin_log, user_state | 动量历史 |
| Weekly Mirror | - | insight_record | 周报卡片 |

**验收:** 八字运势功能完整 + 动量/连续天数追踪

### Sprint 6: 集成测试 + 上线 (Week 11-12)

**目标:** 稳定性保障

| 任务 | 验收标准 |
|------|----------|
| E2E 测试 | Playwright 覆盖核心链路 |
| 性能测试 | 达成 SLO 指标 |
| Sentry 监控 | 异常/性能/崩溃告警 |
| 文档更新 | API 文档 + 部署文档 |
| 灰度发布 | Feature flag 灰度 10% → 50% → 100% |

**验收:** Mentis OS v3.0 MVP 完整可用

---

## 10. 技术栈总览

| 层级 | 技术选型 |
|------|----------|
| **Monorepo** | pnpm workspace + Turborepo |
| **Frontend** | Next.js 16 (App Router) + React 19 |
| **Styling** | Tailwind CSS + Framer Motion |
| **UI Components** | Radix UI + shadcn/ui |
| **State** | Zustand + TanStack Query |
| **Backend Runtime** | Next.js API Routes + Vercel AI SDK |
| **ORM** | Drizzle ORM + Drizzle Kit |
| **Database** | PostgreSQL (Neon Serverless) |
| **Cache** | Upstash Redis |
| **Vector Store** | Pinecone |
| **Object Storage** | Cloudflare R2 |
| **Realtime** | Pusher Channels |
| **LLM** | GLM-4 (主) + Claude 3.5 (降级) + GPT-4 (兜底) |
| **STT** | OpenAI Whisper |
| **Embedding** | text-embedding-3-small |
| **Auth** | NextAuth v5 + JWT |
| **Monitoring** | Sentry + Vercel Analytics |

---

## 11. 环境变量

```bash
# Database
DATABASE_URL="postgresql://..."
DATABASE_URL_UNPOOLED="postgresql://..."

# Redis
UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."

# Pinecone
PINECONE_API_KEY="..."
PINECONE_ENVIRONMENT="us-east-1-aws"
PINECONE_INDEX="mentis-vectors"

# Object Storage
R2_ACCOUNT_ID="..."
R2_ACCESS_KEY_ID="..."
R2_SECRET_ACCESS_KEY="..."
R2_BUCKET_NAME="mentis-media"

# LLM
ZHIPU_API_KEY="..."          # GLM-4
ANTHROPIC_API_KEY="..."      # Claude
OPENAI_API_KEY="..."         # GPT-4 + Whisper + Embedding

# Auth
NEXTAUTH_SECRET="..."
NEXTAUTH_URL="https://mentis.ai"

# Realtime
PUSHER_APP_ID="..."
PUSHER_KEY="..."
PUSHER_SECRET="..."
NEXT_PUBLIC_PUSHER_KEY="..."

# Monitoring
SENTRY_DSN="..."
NEXT_PUBLIC_SENTRY_DSN="..."
```

---

## 12. 与 fortune_ai 的关系

| 项目 | 状态 | 用途 |
|------|------|------|
| `/home/aiscend/work/fortune_ai` | **完整保留** | 参考代码 + 数据迁移源 |
| `/home/aiscend/work/mentis` | **全新构建** | Mentis OS v3.0 主项目 |

**可复用资源:**
- `fortune_ai/services/bazi_*.py` → 算法逻辑参考 (需用 TypeScript 重写)
- `fortune_ai/web-app/src/app/globals.css` → 视觉 token 参考
- `fortune_ai/web-app/src/components/brand/` → 品牌元素参考

**数据迁移 (可选，后续):**
```sql
-- fortune_ai.fortune_user → mentis.mentis_user
-- fortune_ai.fortune_commitment → mentis.action_task
-- fortune_ai.fortune_checkin → mentis.checkin_log
-- fortune_ai.fortune_conversation_* → mentis.stream_entry (type='chat')
```

---

> 本文档严格对齐 Mentis OS v3.0 规格，在全新独立项目中构建，fortune_ai 完整保留。
