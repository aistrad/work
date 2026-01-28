# Fortune AI → Mentis OS v3.0 重构计划

## Executive Summary

将 fortune_ai 项目彻底重构为 Mentis OS v3.0 - 一个 **Stream-Centric Agentic Personal OS**。

**核心转变:**
```
Dashboard-Centric → Stream-Centric
Chat-First → Vibe Diary First
手动打卡 → NLU 自动识别
被动响应 → 主动干预 Agent
```

**保留项:** 当前系统的视觉元素（颜色、动效、组件风格）

---

## Phase 1: 架构重构基础 (Foundation)

### 1.1 项目结构重组

```
mentis-os/
├── apps/
│   ├── web/                    # Next.js 16 前端 (重构)
│   ├── mobile/                 # React Native / Expo (新增)
│   └── wechat/                 # Taro 微信小程序 (新增)
├── packages/
│   ├── core/                   # 共享核心逻辑
│   │   ├── stream-processor/   # Stream 处理引擎
│   │   ├── emotion-engine/     # 情绪识别引擎
│   │   ├── behavior-matcher/   # 行为匹配引擎
│   │   └── intervention-agent/ # 主动干预 Agent
│   ├── decode-modules/         # DECODE 层模块
│   │   ├── bazi/              # 八字 (迁移 services/bazi_*)
│   │   ├── ziwei/             # 紫微斗数 (新增)
│   │   ├── mbti/              # MBTI (新增)
│   │   └── jung/              # 荣格原型 (新增)
│   ├── reframe-modules/        # REFRAME 层模块 (新增)
│   │   ├── cbt/               # 认知行为疗法
│   │   ├── act/               # 接纳承诺疗法
│   │   └── nlp-reword/        # 语言重构
│   ├── evolve-modules/         # EVOLVE 层模块
│   │   ├── habit/             # 习惯系统 (迁移 bento)
│   │   ├── momentum/          # 动量系统 (新增)
│   │   └── ifthen/            # If-Then 计划 (新增)
│   └── ui/                     # 共享 UI 组件库
├── services/
│   ├── api/                    # FastAPI 后端 (重构)
│   ├── agent-runtime/          # Agent Runtime (重构 agent_service)
│   ├── realtime/               # WebSocket 服务 (新增)
│   └── workers/                # 后台任务 (迁移 worker/)
├── infrastructure/
│   ├── database/               # PostgreSQL + Drizzle ORM
│   ├── cache/                  # Redis (Upstash)
│   ├── vector-store/           # Pinecone
│   └── storage/                # R2/S3
└── docs/
    └── .specs/                 # 规格文档
```

**关键文件迁移:**
- `services/soul_os.py` → `packages/core/stream-processor/`
- `services/bazi_*.py` → `packages/decode-modules/bazi/`
- `services/bento_service.py` → `packages/evolve-modules/habit/`
- `services/twin_service.py` → `packages/core/digital-twin/`
- `services/jitai_service.py` → `packages/core/intervention-agent/`
- `agent_service/` → `services/agent-runtime/`

### 1.2 数据库 Schema 重构

**新增核心表:**

```sql
-- Stream 核心表
CREATE TABLE stream_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(20) NOT NULL DEFAULT 'vibe_diary', -- vibe_diary, chat, action_log
    raw_content TEXT NOT NULL,
    media JSONB DEFAULT '[]',

    -- 情绪提取结果
    emotion JSONB, -- {primary, intensity, secondary[], confidence}
    context JSONB, -- {scene, trigger, target}
    tags TEXT[] DEFAULT '{}',
    energy_delta INTEGER DEFAULT 0,

    -- 行为匹配
    behavior_match JSONB, -- {matched, behavior, confidence, auto_checkin}

    -- 元数据
    embedding VECTOR(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户实时状态表
CREATE TABLE user_states (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    energy_score INTEGER DEFAULT 50 CHECK (energy_score BETWEEN 0 AND 100),
    momentum INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,

    current_mood JSONB, -- {primary, intensity, detected_at}
    aura_state VARCHAR(20) DEFAULT 'calm', -- calm, alert, happy, anxious, flow

    today_stats JSONB DEFAULT '{}',
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Action Cards 表
CREATE TABLE action_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(20) NOT NULL, -- suggestion, confirmation, insight, milestone
    title VARCHAR(255) NOT NULL,
    description TEXT,
    momentum_reward INTEGER DEFAULT 1,

    status VARCHAR(20) DEFAULT 'pending', -- pending, completed, dismissed, expired
    trigger_type VARCHAR(20), -- time, state, behavior, fortune
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'
);

-- 动量历史表
CREATE TABLE momentum_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    date DATE NOT NULL,

    daily_momentum INTEGER DEFAULT 0,
    cumulative_momentum INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    streak_multiplier DECIMAL(3,2) DEFAULT 1.0,
    consistency_bonus DECIMAL(3,2) DEFAULT 0,

    action_rewards JSONB DEFAULT '[]', -- [{action, reward}]
    decay_applied BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- 行为库表 (用于 NLU 匹配)
CREATE TABLE behavior_library (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    aliases TEXT[] DEFAULT '{}',
    examples TEXT[] DEFAULT '{}',
    momentum_reward INTEGER DEFAULT 1,
    category VARCHAR(50),
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**迁移策略:**
- 保留 `fortune_user` 表，扩展字段
- `tasks` 表重命名为 `action_cards`，调整结构
- 新增 `stream_entries` 作为核心表
- PERMA 数据整合到 `user_states`

---

## Phase 2: 核心引擎实现

### 2.1 Stream Processor (流处理引擎)

**位置:** `packages/core/stream-processor/`

**职责:**
1. 接收用户输入 (语音/文字/图片)
2. 调用 STT (Whisper) 处理语音
3. 调用 NLP 提取实体和意图
4. 调用情绪检测引擎
5. 调用行为匹配引擎
6. 更新用户状态
7. 触发 Agent 干预检查
8. 返回 SSE 流式响应

**核心接口:**
```typescript
// packages/core/stream-processor/types.ts
interface StreamInput {
  content: string;
  type: 'vibe_diary' | 'chat';
  media?: { type: 'image' | 'audio'; data: string }[];
  metadata?: { location?: LatLng; device?: string };
}

interface StreamProcessResult {
  entry: StreamEntry;
  emotion: EmotionResult;
  behaviorMatch?: BehaviorMatch;
  stateUpdate: UserState;
  agentResponse?: ActionCard;
}
```

**迁移来源:**
- `services/soul_os.py` 的 L3 合成逻辑
- `agent_service/src/agents/coach.ts` 的流式处理

### 2.2 Emotion Engine (情绪识别引擎)

**位置:** `packages/core/emotion-engine/`

**实现:**
```typescript
// 情绪分类 (8 primary + secondary)
const EMOTION_TAXONOMY = {
  primary: ['joy', 'sadness', 'anger', 'fear', 'surprise', 'disgust', 'anxiety', 'calm'],
  secondary: ['frustration', 'helplessness', 'excitement', 'pride', 'guilt', 'shame',
              'loneliness', 'gratitude', 'hope', 'relief', 'jealousy', 'contempt']
};

// 能量变化映射
const ENERGY_MAP = {
  joy: [2, 5],      // 正向
  sadness: [-4, -2],
  anger: [-5, -3],
  fear: [-4, -2],
  surprise: [-1, 1],
  disgust: [-3, -2],
  anxiety: [-4, -2],
  calm: [0, 1]
};
```

**迁移来源:** 新实现，参考 `services/jitai_service.py` 的状态检测逻辑

### 2.3 Behavior Matcher (行为匹配引擎)

**位置:** `packages/core/behavior-matcher/`

**职责:**
1. 用户输入向量化 (text-embedding-3-small)
2. 优先匹配待完成任务
3. 匹配行为库
4. 置信度阈值判断 (>0.85 自动打卡, 0.6-0.85 确认卡)

**迁移来源:** 新实现，替换 `services/bento_service.py` 的手动打卡逻辑

### 2.4 Intervention Agent (主动干预 Agent)

**位置:** `packages/core/intervention-agent/`

**触发条件:**
1. **时间触发:** 早间运势、午间补水、晚间回顾
2. **状态触发:** energy < 30、anger > 7、持续焦虑
3. **行为触发:** 2小时未补水、连续N天未完成习惯
4. **运势触发:** 运势警告、特殊节气

**迁移来源:** `services/jitai_service.py` 扩展重构

---

## Phase 3: 前端重构

### 3.1 三层交互模型实现

**Layer 1: THE STREAM (核心交互区) - 90% 时间**

**重构 `web-app/src/app/new/page.tsx`:**
```tsx
// 从 Dashboard-first 改为 Stream-first
export default function MainPage() {
  return (
    <StreamLayout>
      {/* 顶部状态栏 */}
      <TopStatusBar momentum={momentum} streak={streak} auraState={aura} />

      {/* 主体 Stream 区域 */}
      <StreamContainer>
        {entries.map(entry => (
          <StreamCard key={entry.id} entry={entry} />
        ))}
      </StreamContainer>

      {/* 底部魔法输入框 */}
      <MagicInput onSend={handleStreamInput} />
    </StreamLayout>
  );
}
```

**新增组件:**
- `components/stream/StreamContainer.tsx` - 无限滚动 Stream 容器
- `components/stream/StreamCard.tsx` - 统一卡片 (vibe_diary, action_card, insight)
- `components/stream/MagicInput.tsx` - 语音/文字/图片输入 (替代 Omnibar)

**迁移:** 保留 `components/chat/Omnibar.tsx` 的视觉风格，重构为 `MagicInput`

**Layer 2: THE HUD (环境感知区)**

**新增 Dynamic Aura System:**
```tsx
// components/hud/DynamicAura.tsx
const AURA_STATES = {
  calm: { gradient: ['#1a1a2e', '#2d3561'], particles: 'slow-rise' },
  alert: { gradient: ['#2e1a1a', '#613535'], particles: 'fast-pulse' },
  happy: { gradient: ['#2e2a1a', '#61553d'], particles: 'bounce' },
  anxious: { gradient: ['#1a1a2e', '#3d2d61'], particles: 'irregular' },
  flow: { gradient: ['#1a2e1a', '#2d6135'], particles: 'focus' }
};
```

**迁移:** 复用 `components/brand/OrbIndicator.tsx` 的粒子效果

**Layer 3: THE INTERVENTION (主动干预层)**

**新增 Action Cards 组件:**
```tsx
// components/intervention/ActionCard.tsx
type ActionCardType = 'suggestion' | 'confirmation' | 'insight' | 'milestone';

// 交互方式
- 长按充能完成 (ProgressHoldButton)
- 点击按钮快速响应
- 滑动忽略
```

**迁移:** 参考 `components/dashboard/tabs/QuestsTab.tsx` 的任务卡片，重新设计

### 3.2 状态管理重构

**重构 `stores/app-store.ts`:**

```typescript
interface MentisStore {
  // Stream 状态
  streamEntries: StreamEntry[];
  isStreaming: boolean;

  // 用户状态 (实时同步)
  userState: {
    energyScore: number;
    momentum: number;
    streakDays: number;
    currentMood: MoodState;
    auraState: AuraState;
  };

  // Action Cards
  pendingCards: ActionCard[];

  // Actions
  sendStreamInput: (input: StreamInput) => Promise<void>;
  completeActionCard: (cardId: string) => Promise<void>;
  dismissActionCard: (cardId: string) => Promise<void>;

  // WebSocket 订阅
  subscribeRealtime: () => void;
  unsubscribeRealtime: () => void;
}
```

### 3.3 API Client 重构

**重构 `lib/api.ts`:**

```typescript
// Stream API (SSE)
export async function* sendStream(input: StreamInput): AsyncGenerator<StreamEvent> {
  const response = await fetch('/api/stream', {
    method: 'POST',
    body: JSON.stringify(input),
    headers: { 'Content-Type': 'application/json' }
  });

  const reader = response.body!.getReader();
  // ... SSE 解析
}

// WebSocket 连接
export function connectRealtime(token: string): WebSocket {
  return new WebSocket(`wss://api.mentis.ai/v3/realtime?token=${token}`);
}
```

---

## Phase 4: 后端 API 重构

### 4.1 新增 Stream API

**新增 `api/stream_routes.py`:**

```python
@router.post("/stream")
async def create_stream_entry(
    request: StreamRequest,
    user: User = Depends(get_current_user)
) -> StreamingResponse:
    """
    SSE 流式响应:
    1. stream_created - 条目创建
    2. extraction_complete - 情绪/上下文提取
    3. state_update - 状态更新
    4. behavior_match - 行为匹配 (可选)
    5. agent_response - Agent 响应 (可选)
    6. done - 完成
    """
    async def event_generator():
        # 调用 Stream Processor
        async for event in stream_processor.process(request, user.id):
            yield f"data: {json.dumps(event)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream"
    )
```

### 4.2 重构 Agent Runtime

**重构 `services/agent-runtime/`:**

```typescript
// Vercel AI SDK 4.0 + Multi-Step
const result = streamText({
  model: selectModel(userTier),
  system: await buildContext(userId),
  messages: conversationHistory,
  tools: {
    ...getDecodeTools(userId),    // 动态加载 DECODE 模块
    ...getReframeTools(userId),   // CBT/ACT/NLP 工具
    ...getEvolveTools(userId),    // 习惯/动量工具
    ...getSystemTools(),          // 系统工具
  },
  maxSteps: 5,
  onStepFinish: handleStepCallback,
});
```

**迁移:** `agent_service/src/agents/coach.ts` → 扩展支持 Multi-Step 和更多工具

### 4.3 新增 WebSocket 服务

**新增 `services/realtime/`:**

使用 Pusher Channels 实现:
- 状态变化广播
- Aura 状态同步
- Action Card 推送
- 洞察通知

---

## Phase 5: 模块化系统

### 5.1 标准模块接口

```typescript
// packages/core/module-interface.ts
interface MentisModule {
  meta: {
    id: string;
    name: string;
    tier: 'free' | 'pro' | 'premium';
    category: 'decode' | 'reframe' | 'evolve';
  };

  knowledge_base: {
    vector_namespace: string;
    rules: Rule[];
  };

  tools: ToolDefinition[];

  context_output: (userId: string) => Promise<ContextFragment>;
}
```

### 5.2 DECODE 模块迁移

**BaZi 模块:**
- 迁移 `services/bazi_engine.py` → `packages/decode-modules/bazi/engine.ts`
- 迁移 `services/bazi_facts.py` → `packages/decode-modules/bazi/facts.ts`
- 新增 tool 定义: `bazi_calculate`, `bazi_fortune_today`

**ZiWei 模块:** 新实现 (参考规格文档)

### 5.3 EVOLVE 模块迁移

**Habit 模块:**
- 迁移 `services/bento_service.py` → `packages/evolve-modules/habit/`
- 重构为 tool: `habit_suggest`, `checkin_auto`, `ifthen_create`

**Momentum 模块:** 新实现动量计算算法

---

## Phase 6: 数据迁移

### 6.1 用户数据迁移

```sql
-- 迁移现有用户
INSERT INTO user_states (user_id, energy_score, momentum)
SELECT id, 50, 0 FROM fortune_user;

-- 迁移 PERMA 数据
UPDATE user_states
SET today_stats = (
  SELECT jsonb_build_object(
    'perma', perma_scores,
    'migrated_from', 'fortune_ai'
  )
  FROM user_perma_history
  WHERE user_id = user_states.user_id
);
```

### 6.2 任务数据迁移

```sql
-- tasks → action_cards
INSERT INTO action_cards (user_id, type, title, description, status, created_at)
SELECT
  user_id,
  'suggestion',
  title,
  description,
  CASE status
    WHEN 'done' THEN 'completed'
    WHEN 'skipped' THEN 'dismissed'
    ELSE 'pending'
  END,
  created_at
FROM tasks;
```

---

## 用户决策

| 决策项 | 选择 |
|--------|------|
| 优先级 | **Stream + Vibe Diary** (核心差异点) |
| API 兼容性 | **全新架构** (直接 /api/v3) |
| LLM 模型 | **GLM-4 国内优先** |
| 多端支持 | **先 Web**，小程序后续迭代 |

---

## 实施顺序 (基于用户选择调整)

### Sprint 1: 基础架构 + Stream 核心 (Week 1-2)
**目标:** 建立新架构基础，实现 Stream 输入闭环

1. [ ] 项目结构重组 (monorepo 配置)
2. [ ] 数据库 Schema 创建 (stream_entries, user_states)
3. [ ] 核心类型定义 (TypeScript + Python)
4. [ ] **Stream Processor 核心实现**
5. [ ] **Emotion Engine 基础版**
6. [ ] **POST /api/v3/stream SSE 端点**

**关键交付物:**
- 用户可以发送文字输入 → 获得情绪识别结果
- SSE 流式响应正常工作

### Sprint 2: Vibe Diary UI + 实时状态 (Week 3-4)
**目标:** 完成前端 Stream 交互，实现实时状态同步

1. [ ] **MagicInput 组件** (文字输入，保留视觉风格)
2. [ ] **StreamCard 组件** (Vibe Diary 条目展示)
3. [ ] **TopStatusBar** (动量/连续天数/状态)
4. [ ] Zustand Store 重构 (StreamStore)
5. [ ] 用户状态实时更新 (energy_score, aura_state)
6. [ ] WebSocket 连接 (Pusher 集成)

**关键交付物:**
- 完整的 Vibe Diary 输入 → 展示流程
- 实时状态变化反馈

### Sprint 3: Dynamic Aura + 语音输入 (Week 5-6)
**目标:** 增强视觉反馈，支持语音输入

1. [ ] **Dynamic Aura System** (5 种状态 + 粒子效果)
2. [ ] 语音输入集成 (Whisper STT)
3. [ ] 图片输入 + Vision API 理解
4. [ ] Aura 状态转换动画 (2s 渐变)
5. [ ] 能量变化动画效果

**关键交付物:**
- 情绪变化触发背景 Aura 变换
- 语音/图片/文字三种输入方式

### Sprint 4: Agent 主动干预 (Week 7-8)
**目标:** 实现 Agent 主动推送能力

1. [ ] Behavior Matcher (NLU 行为识别)
2. [ ] Intervention Agent (触发条件评估)
3. [ ] **Action Cards 组件** (suggestion/confirmation/insight/milestone)
4. [ ] 长按充能完成交互
5. [ ] 干预节流逻辑 (避免过度打扰)
6. [ ] GLM-4 集成优化

**关键交付物:**
- Agent 主动推送任务卡片
- 自然语言自动识别行为并打卡

### Sprint 5: 模块系统 + BaZi 迁移 (Week 9-10)
**目标:** 建立模块化架构，迁移核心功能

1. [ ] MentisModule 接口定义
2. [ ] BaZi 模块重构 (保留算法逻辑)
3. [ ] Momentum 系统实现 (动量计算)
4. [ ] 每日运势 API 重构
5. [ ] Habit/Quest 模块迁移

**关键交付物:**
- 八字运势功能恢复
- 动量/连续天数追踪

### Sprint 6: 集成测试 + 上线 (Week 11-12)
**目标:** 确保稳定性，完成切换

1. [ ] 端到端测试 (Playwright)
2. [ ] 数据迁移脚本执行
3. [ ] 性能优化 (缓存策略)
4. [ ] 监控告警配置 (Sentry)
5. [ ] 文档更新
6. [ ] 灰度发布

**关键交付物:**
- 完整可用的 Mentis OS v3.0

---

## 技术栈确认 (基于用户选择)

| 层级 | 当前 | 目标 |
|------|------|------|
| Frontend | Next.js 16 + React 19 | **保持** (仅 Web) |
| UI | Tailwind + Radix + Framer | **保持视觉风格** |
| State | Zustand | **保持** |
| Backend | FastAPI | **全新 /api/v3** |
| Agent | Express + AI SDK | **升级到 AI SDK 4.0** |
| Database | PostgreSQL | **保持** + Drizzle ORM |
| Cache | (无) | **新增 Redis (Upstash)** |
| Vector | (无) | **新增 Pinecone** |
| Realtime | (无) | **新增 Pusher** |
| LLM | GLM-4 / Claude | **GLM-4 主力** (国内优先) |
| Mobile | (无) | **暂不实现** (后续迭代) |

---

## 风险与缓解

1. **数据迁移风险** → 分阶段迁移 + 回滚脚本
2. **用户体验断层** → 保持视觉一致性 + 渐进式发布
3. **性能下降** → 实时监控 + 缓存策略
4. **复杂度增加** → 模块化设计 + 清晰接口

---

## 验收标准

- [ ] Stream 输入到首次反馈 < 500ms (P95)
- [ ] 情绪检测准确率 > 85%
- [ ] 行为匹配准确率 > 80%
- [ ] Aura 状态切换流畅 (60fps)
- [ ] WebSocket 连接稳定性 > 99%
- [ ] 所有现有功能保持可用
