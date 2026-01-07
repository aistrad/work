Mentis OS v3.0 part 2

8. API 设计8.1 API 总览╔═══════════════════════════════════════════════════════════════════════════════╗
║                              API OVERVIEW                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   BASE URL: https://api.mentis.ai/v3                                          ║
║                                                                               ║
║   AUTHENTICATION: Bearer Token (JWT)                                          ║
║   RATE LIMITS: Based on user tier (free/pro/premium)                          ║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                          PUBLIC ENDPOINTS                               │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  POST /auth/register          → 注册新用户                              │║
║   │  POST /auth/login             → 用户登录                                │║
║   │  POST /auth/refresh           → 刷新 Token                              │║
║   │  POST /landing/quick-insight  → 快速命盘洞察 (无需登录)                 │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                         STREAM ENDPOINTS                                │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  POST /stream                 → 发送 Stream 条目 (SSE 流式响应)        │║
║   │  GET  /stream                 → 获取 Stream 历史                        │║
║   │  GET  /stream/:id             → 获取单条 Stream                         │║
║   │  DELETE /stream/:id           → 删除 Stream 条目                        │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                         DECODE ENDPOINTS                                │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  POST /decode/bazi            → 八字计算                                │║
║   │  POST /decode/ziwei           → 紫微斗数计算                            │║
║   │  GET  /decode/fortune/today   → 今日运势                                │║
║   │  GET  /decode/fortune/:date   → 指定日期运势                            │║
║   │  GET  /decode/snapshot        → 获取命盘快照                            │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                         EVOLVE ENDPOINTS                                │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  GET  /tasks                  → 获取待办任务列表                        │║
║   │  POST /tasks/:id/complete     → 完成任务                                │║
║   │  POST /tasks/:id/dismiss      → 忽略任务                                │║
║   │  POST /checkin                → 手动打卡                                │║
║   │  GET  /momentum               → 获取动量历史                            │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                         USER ENDPOINTS                                  │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  GET  /user/profile           → 获取用户档案                            │║
║   │  PUT  /user/profile           → 更新用户档案                            │║
║   │  GET  /user/state             → 获取实时状态                            │║
║   │  GET  /user/insights          → 获取洞察列表                            │║
║   │  PUT  /user/preferences       → 更新偏好设置                            │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                        WEBSOCKET ENDPOINT                               │║
║   ├─────────────────────────────────────────────────────────────────────────┤║
║   │                                                                         │║
║   │  WS  /realtime                → 实时更新 (状态/Aura/任务推送)           │║
║   │                                                                         │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝8.2 核心 API 详细定义POST /stream (核心 Stream API)typescript// ═══════════════════════════════════════════════════════════════════════════
// POST /stream - 发送 Stream 条目
// ═══════════════════════════════════════════════════════════════════════════

// Request
interface StreamRequest {
  content: string;                    // 文本内容
  type?: 'vibe_diary' | 'chat';       // 类型，默认 vibe_diary
  media?: {
    type: 'image' | 'audio';
    data: string;                     // base64 或 URL
  }[];
  metadata?: {
    location?: { lat: number; lng: number };
    device?: string;
  };
}

// Response (Server-Sent Events)
// Content-Type: text/event-stream

// Event 1: stream_created
data: {
  "event": "stream_created",
  "data": {
    "id": "uuid",
    "type": "vibe_diary",
    "raw_content": "刚才开会真的气死我了",
    "created_at": "2026-01-04T10:30:00Z"
  }
}

// Event 2: extraction_complete
data: {
  "event": "extraction_complete",
  "data": {
    "emotion": {
      "primary": "anger",
      "intensity": 8,
      "secondary": ["frustration"]
    },
    "context": {
      "scene": "work",
      "trigger": "meeting",
      "target": "boss"
    },
    "tags": ["#Work", "#Anger"],
    "energy_delta": -3
  }
}

// Event 3: state_update
data: {
  "event": "state_update",
  "data": {
    "energy_score": 45,
    "momentum": 12,
    "aura_state": "alert"
  }
}

// Event 4: behavior_match (可选)
data: {
  "event": "behavior_match",
  "data": {
    "matched": true,
    "behavior": "meditation",
    "confidence": 0.92,
    "auto_checkin": true,
    "momentum_delta": 1
  }
}

// Event 5: agent_response (可选)
data: {
  "event": "agent_response",
  "data": {
    "type": "action_card",
    "card": {
      "id": "uuid",
      "type": "suggestion",
      "title": "3分钟呼吸法",
      "description": "检测到情绪波动，建议做个简短的呼吸练习",
      "momentum_reward": 1
    }
  }
}

// Event 6: done
data: {
  "event": "done"
}GET /user/state (实时状态 API)typescript// ═══════════════════════════════════════════════════════════════════════════
// GET /user/state - 获取用户实时状态
// ═══════════════════════════════════════════════════════════════════════════

// Response
interface UserStateResponse {
  energy_score: number;         // 0-100
  momentum: number;             // 累计动量
  streak_days: number;          // 连续天数
  
  current_mood: {
    primary: string;            // anger, joy, sadness, etc.
    intensity: number;          // 1-10
    detected_at: string;        // ISO timestamp
  };
  
  aura_state: 'calm' | 'alert' | 'happy' | 'anxious' | 'flow';
  
  today_stats: {
    stream_count: number;
    checkin_count: number;
    energy_high: number;
    energy_low: number;
  };
  
  pending_tasks: number;
  unread_insights: number;
  
  last_active_at: string;
}WebSocket /realtime (实时推送)typescript// ═══════════════════════════════════════════════════════════════════════════
// WebSocket /realtime - 实时更新订阅
// ═══════════════════════════════════════════════════════════════════════════

// Connection
// wss://api.mentis.ai/v3/realtime?token={jwt_token}

// Client → Server Messages
interface ClientMessage {
  type: 'subscribe' | 'unsubscribe' | 'ping';
  channels?: string[];  // ['stream', 'state', 'tasks', 'insights']
}

// Server → Client Messages
interface ServerMessage {
  type: 'stream_new' | 'state_update' | 'aura_change' | 'task_push' | 'insight_ready' | 'pong';
  data: any;
  timestamp: string;
}

// Example: state_update
{
  "type": "state_update",
  "data": {
    "energy_score": 72,
    "momentum": 15,
    "aura_state": "calm"
  },
  "timestamp": "2026-01-04T10:30:00Z"
}

// Example: task_push
{
  "type": "task_push",
  "data": {
    "id": "uuid",
    "type": "suggestion",
    "title": "喝杯水",
    "description": "已经2小时没有补水了",
    "momentum_reward": 1,
    "expires_at": "2026-01-04T11:30:00Z"
  },
  "timestamp": "2026-01-04T10:30:00Z"
}8.3 错误处理规范typescript// ═══════════════════════════════════════════════════════════════════════════
// ERROR RESPONSE FORMAT
// ═══════════════════════════════════════════════════════════════════════════

interface ErrorResponse {
  error: {
    code: string;           // 错误代码
    message: string;        // 用户友好的错误信息
    details?: any;          // 详细信息 (仅开发环境)
    request_id: string;     // 请求追踪 ID
  };
}

// Error Codes
const ERROR_CODES = {
  // 认证错误 (401)
  AUTH_INVALID_TOKEN: 'auth/invalid-token',
  AUTH_TOKEN_EXPIRED: 'auth/token-expired',
  AUTH_MISSING_TOKEN: 'auth/missing-token',
  
  // 权限错误 (403)
  PERMISSION_DENIED: 'permission/denied',
  TIER_REQUIRED: 'permission/tier-required',
  
  // 资源错误 (404)
  USER_NOT_FOUND: 'resource/user-not-found',
  STREAM_NOT_FOUND: 'resource/stream-not-found',
  TASK_NOT_FOUND: 'resource/task-not-found',
  
  // 验证错误 (400)
  VALIDATION_ERROR: 'validation/error',
  INVALID_BIRTH_TIME: 'validation/invalid-birth-time',
  INVALID_CONTENT: 'validation/invalid-content',
  
  // 限流错误 (429)
  RATE_LIMIT_EXCEEDED: 'rate-limit/exceeded',
  
  // 服务器错误 (500)
  INTERNAL_ERROR: 'server/internal-error',
  AI_SERVICE_ERROR: 'server/ai-service-error',
  DATABASE_ERROR: 'server/database-error',
};

9. 核心算法9.1 情绪识别算法╔═══════════════════════════════════════════════════════════════════════════════╗
║                        EMOTION RECOGNITION ALGORITHM                           ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   PIPELINE OVERVIEW                                                           ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   ┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       ║
║   │  Input  │ →  │ Preprocess  │ →  │  LLM Call   │ →  │  Validate   │       ║
║   │  Text   │    │  & Clean    │    │  Structured │    │  & Score    │       ║
║   └─────────┘    └─────────────┘    └─────────────┘    └─────────────┘       ║
║                                                                               ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   EMOTION TAXONOMY                                                            ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   Primary Emotions (8 categories):                                            ║
║   ├─ joy (喜悦)        → energy_delta: +2 to +5                              ║
║   ├─ sadness (悲伤)    → energy_delta: -2 to -4                              ║
║   ├─ anger (愤怒)      → energy_delta: -3 to -5                              ║
║   ├─ fear (恐惧)       → energy_delta: -2 to -4                              ║
║   ├─ surprise (惊讶)   → energy_delta: -1 to +1                              ║
║   ├─ disgust (厌恶)    → energy_delta: -2 to -3                              ║
║   ├─ anxiety (焦虑)    → energy_delta: -2 to -4                              ║
║   └─ calm (平静)       → energy_delta: 0 to +1                               ║
║                                                                               ║
║   Secondary Emotions (contextual):                                            ║
║   ├─ frustration, helplessness, excitement, pride, guilt, shame              ║
║   └─ loneliness, gratitude, hope, relief, jealousy, contempt                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝typescript// 情绪识别实现

interface EmotionResult {
  primary: string;
  intensity: number;  // 1-10
  secondary: string[];
  confidence: number;
  energy_delta: number;
}

const EMOTION_PROMPT = `
分析以下文本的情绪，返回JSON格式：

文本: "{input}"

返回格式:
{
  "primary": "主要情绪 (joy/sadness/anger/fear/surprise/disgust/anxiety/calm)",
  "intensity": "强度 1-10",
  "secondary": ["次要情绪列表"],
  "reasoning": "简短分析"
}

注意:
1. intensity 反映情绪强烈程度
2. 考虑上下文和表达方式
3. 中文语境下的委婉表达可能隐藏强烈情绪
`;

async function detectEmotion(input: string): Promise<EmotionResult> {
  const response = await llm.complete({
    model: 'gpt-4-turbo',
    prompt: EMOTION_PROMPT.replace('{input}', input),
    response_format: { type: 'json_object' },
  });
  
  const parsed = JSON.parse(response);
  
  // 计算能量变化
  const energy_delta = calculateEnergyDelta(parsed.primary, parsed.intensity);
  
  return {
    primary: parsed.primary,
    intensity: parsed.intensity,
    secondary: parsed.secondary,
    confidence: 0.9,  // 可基于模型置信度调整
    energy_delta,
  };
}

function calculateEnergyDelta(emotion: string, intensity: number): number {
  const ENERGY_MAP: Record<string, [number, number]> = {
    joy: [2, 5],
    sadness: [-4, -2],
    anger: [-5, -3],
    fear: [-4, -2],
    surprise: [-1, 1],
    disgust: [-3, -2],
    anxiety: [-4, -2],
    calm: [0, 1],
  };
  
  const [min, max] = ENERGY_MAP[emotion] || [0, 0];
  const ratio = intensity / 10;
  
  if (max > 0) {
    return Math.round(min + (max - min) * ratio);
  } else {
    return Math.round(max + (min - max) * ratio);
  }
}9.2 行为匹配算法╔═══════════════════════════════════════════════════════════════════════════════╗
║                        BEHAVIOR MATCHING ALGORITHM                             ║
║                        (NLU → Auto Checkin)                                    ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   MATCHING PIPELINE                                                           ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   User Input                                                                  ║
║       │                                                                       ║
║       ▼                                                                       ║
║   ┌───────────────────────────────────────────────────────────────────────┐  ║
║   │ Step 1: Embedding                                                      │  ║
║   │ ─────────────────                                                      │  ║
║   │ model: text-embedding-3-small                                          │  ║
║   │ output: 1536-dim vector                                                │  ║
║   └───────────────────────────────────────────────────────────────────────┘  ║
║       │                                                                       ║
║       ▼                                                                       ║
║   ┌───────────────────────────────────────────────────────────────────────┐  ║
║   │ Step 2: Pending Task Match (优先)                                      │  ║
║   │ ─────────────────────────────                                          │  ║
║   │ 如果用户有待完成任务，优先匹配这些任务                                 │  ║
║   │ threshold: 0.80                                                        │  ║
║   └───────────────────────────────────────────────────────────────────────┘  ║
║       │                                                                       ║
║       ▼                                                                       ║
║   ┌───────────────────────────────────────────────────────────────────────┐  ║
║   │ Step 3: Behavior Library Match                                         │  ║
║   │ ─────────────────────────────                                          │  ║
║   │ Pinecone namespace: behavior_library                                   │  ║
║   │ top_k: 3                                                               │  ║
║   │ threshold: 0.85 (auto), 0.60-0.85 (confirm card)                      │  ║
║   └───────────────────────────────────────────────────────────────────────┘  ║
║       │                                                                       ║
║       ▼                                                                       ║
║   ┌───────────────────────────────────────────────────────────────────────┐  ║
║   │ Step 4: Decision                                                       │  ║
║   │ ─────────────                                                          │  ║
║   │ score >= 0.85 → Auto Checkin                                          │  ║
║   │ score 0.60-0.85 → Generate Confirmation Card                          │  ║
║   │ score < 0.60 → No Match                                               │  ║
║   └───────────────────────────────────────────────────────────────────────┘  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝typescript// 行为匹配实现

interface BehaviorMatch {
  matched: boolean;
  behavior?: string;
  confidence: number;
  auto_checkin: boolean;
  task_id?: string;
}

// 行为库定义
const BEHAVIOR_LIBRARY = [
  {
    id: 'meditation',
    name: '冥想',
    aliases: ['打坐', '静心', '呼吸练习', '正念'],
    examples: [
      '刚才静下心来冥想了一会儿',
      '做了十分钟的呼吸练习',
      '今天冥想了',
    ],
    momentum_reward: 1,
  },
  {
    id: 'hydration',
    name: '补水',
    aliases: ['喝水', '补充水分'],
    examples: [
      '喝了杯水',
      '刚补了水',
      '终于记得喝水了',
    ],
    momentum_reward: 1,
  },
  {
    id: 'emotion_control',
    name: '情绪控制',
    aliases: ['忍住', '控制情绪', '没发火'],
    examples: [
      '忍住没发火',
      '今天控制住情绪了',
      '深呼吸让自己冷静下来了',
    ],
    momentum_reward: 2,
  },
  // ... more behaviors
];

async function matchBehavior(
  input: string,
  userId: string,
  pendingTasks: Task[]
): Promise<BehaviorMatch> {
  
  // Step 1: Generate embedding
  const inputEmbedding = await embed(input);
  
  // Step 2: Check pending tasks first
  if (pendingTasks.length > 0) {
    const taskMatch = await matchPendingTasks(inputEmbedding, pendingTasks);
    if (taskMatch && taskMatch.score >= 0.80) {
      return {
        matched: true,
        behavior: taskMatch.task.type,
        confidence: taskMatch.score,
        auto_checkin: taskMatch.score >= 0.85,
        task_id: taskMatch.task.id,
      };
    }
  }
  
  // Step 3: Match against behavior library
  const libraryMatch = await pinecone.query({
    namespace: 'behavior_library',
    vector: inputEmbedding,
    topK: 3,
    includeMetadata: true,
  });
  
  const topMatch = libraryMatch.matches[0];
  
  if (!topMatch || topMatch.score < 0.60) {
    return { matched: false, confidence: topMatch?.score || 0, auto_checkin: false };
  }
  
  return {
    matched: true,
    behavior: topMatch.metadata.behavior_id,
    confidence: topMatch.score,
    auto_checkin: topMatch.score >= 0.85,
  };
}
9.3 Agent 主动干预算法
╔═══════════════════════════════════════════════════════════════════════════════╗
║                     PROACTIVE INTERVENTION ALGORITHM                           ║
║                     (Agent 主动推送决策)                                       ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   TRIGGER CONDITIONS                                                          ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   1. TIME-BASED TRIGGERS                                                      ║
║   ──────────────────────                                                      ║
║   ├─ Morning (7-9am): 每日运势 + 早间建议                                    ║
║   ├─ Midday (12-1pm): 午休提醒 + 能量检查                                    ║
║   ├─ Afternoon (3-4pm): 下午茶/补水提醒                                      ║
║   └─ Evening (9-10pm): 今日回顾 + 明日准备                                   ║
║                                                                               ║
║   2. STATE-BASED TRIGGERS                                                     ║
║   ────────────────────────                                                    ║
║   ├─ energy_score < 30 → 紧急干预 (呼吸/休息建议)                            ║
║   ├─ anger detected (intensity > 7) → 情绪调节建议                           ║
║   ├─ anxiety detected (持续2小时+) → CBT 练习推送                            ║
║   └─ flow detected → 正强化 (不打断，延后推送)                               ║
║                                                                               ║
║   3. BEHAVIOR-BASED TRIGGERS                                                  ║
║   ──────────────────────────                                                  ║
║   ├─ 2小时未补水 → 补水提醒                                                  ║
║   ├─ 连续3天未冥想 → 习惯提醒                                                ║
║   ├─ 连续完成7天 → 里程碑庆祝                                                ║
║   └─ 发现负面模式 → 洞察分享                                                 ║
║                                                                               ║
║   4. FORTUNE-BASED TRIGGERS                                                   ║
║   ──────────────────────────                                                  ║
║   ├─ 运势特别好 → 建议积极行动                                               ║
║   ├─ 运势警告日 → 提前预警 + 保守建议                                        ║
║   └─ 特殊时间节点 (节气/月相) → 定制建议                                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
typescript// Agent 主动干预实现

interface InterventionTrigger {
  type: 'time' | 'state' | 'behavior' | 'fortune';
  priority: 'high' | 'medium' | 'low';
  action: ActionCard;
}

interface AgentContext {
  user_state: UserState;
  recent_streams: StreamEntry[];
  pending_tasks: Task[];
  fortune_today: Fortune;
  last_intervention: Date;
}

async function evaluateInterventions(ctx: AgentContext): Promise<InterventionTrigger[]> {
  const triggers: InterventionTrigger[] = [];
  
  // 1. State-based triggers (highest priority)
  if (ctx.user_state.energy_score < 30) {
    triggers.push({
      type: 'state',
      priority: 'high',
      action: generateBreathingCard(),
    });
  }
  
  const recentAnger = ctx.recent_streams.find(
    s => s.emotion?.primary === 'anger' && 
         s.emotion.intensity > 7 &&
         Date.now() - new Date(s.created_at).getTime() < 30 * 60 * 1000
  );
  if (recentAnger) {
    triggers.push({
      type: 'state',
      priority: 'high',
      action: generateEmotionRegulationCard(),
    });
  }
  
  // 2. Time-based triggers
  const hour = new Date().getHours();
  if (hour >= 7 && hour < 9 && !hasRecentTrigger(ctx, 'morning')) {
    triggers.push({
      type: 'time',
      priority: 'medium',
      action: generateMorningCard(ctx.fortune_today),
    });
  }
  
  // 3. Behavior-based triggers
  const lastHydration = await getLastCheckin(ctx.user_state.user_id, 'hydration');
  if (!lastHydration || Date.now() - lastHydration.getTime() > 2 * 60 * 60 * 1000) {
    triggers.push({
      type: 'behavior',
      priority: 'low',
      action: generateHydrationCard(),
    });
  }
  
  // 4. Fortune-based triggers
  if (ctx.fortune_today.fortune_level === 'caution') {
    triggers.push({
      type: 'fortune',
      priority: 'medium',
      action: generateCautionCard(ctx.fortune_today),
    });
  }
  
  // Sort by priority and dedupe
  return prioritizeAndDedupe(triggers);
}

// 干预节流：避免过度打扰
function shouldIntervene(ctx: AgentContext, trigger: InterventionTrigger): boolean {
  const minutesSinceLastIntervention = 
    (Date.now() - ctx.last_intervention.getTime()) / (60 * 1000);
  
  const MIN_INTERVAL: Record<string, number> = {
    high: 5,      // 高优先级最少间隔5分钟
    medium: 30,   // 中优先级最少间隔30分钟
    low: 120,     // 低优先级最少间隔2小时
  };
  
  return minutesSinceLastIntervention >= MIN_INTERVAL[trigger.priority];
}
9.4 动量计算算法
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        MOMENTUM CALCULATION ALGORITHM                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   MOMENTUM FORMULA                                                            ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   Daily Momentum = Σ(action_rewards) × streak_multiplier × consistency_bonus  ║
║                                                                               ║
║   Where:                                                                      ║
║   ├─ action_rewards: 每个完成行为的奖励点数                                  ║
║   ├─ streak_multiplier: 连续天数乘数                                         ║
║   │   └─ days 1-3: 1.0x                                                      ║
║   │   └─ days 4-7: 1.2x                                                      ║
║   │   └─ days 8-14: 1.5x                                                     ║
║   │   └─ days 15-21: 1.8x                                                    ║
║   │   └─ days 22+: 2.0x                                                      ║
║   └─ consistency_bonus: 本周完成率奖励                                       ║
║       └─ 50-70%: +0%                                                         ║
║       └─ 70-90%: +10%                                                        ║
║       └─ 90%+: +20%                                                          ║
║                                                                               ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   DECAY RULES                                                                 ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   ├─ 断签1天: streak_multiplier 重置为 1.0x                                  ║
║   ├─ 断签2天: momentum × 0.9 (损失10%)                                       ║
║   ├─ 断签3天+: momentum × 0.8 + streak 重置                                  ║
║   └─ 断签7天+: momentum × 0.5 + 重新校准                                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
typescript// 动量计算实现

interface MomentumConfig {
  STREAK_MULTIPLIERS: Record<string, number>;
  CONSISTENCY_BONUSES: Record<string, number>;
  DECAY_RULES: Record<number, { momentum_factor: number; reset_streak: boolean }>;
}

const CONFIG: MomentumConfig = {
  STREAK_MULTIPLIERS: {
    '1-3': 1.0,
    '4-7': 1.2,
    '8-14': 1.5,
    '15-21': 1.8,
    '22+': 2.0,
  },
  CONSISTENCY_BONUSES: {
    '50-70': 0,
    '70-90': 0.10,
    '90+': 0.20,
  },
  DECAY_RULES: {
    1: { momentum_factor: 1.0, reset_streak: true },
    2: { momentum_factor: 0.9, reset_streak: true },
    3: { momentum_factor: 0.8, reset_streak: true },
    7: { momentum_factor: 0.5, reset_streak: true },
  },
};

function getStreakMultiplier(streakDays: number): number {
  if (streakDays <= 3) return 1.0;
  if (streakDays <= 7) return 1.2;
  if (streakDays <= 14) return 1.5;
  if (streakDays <= 21) return 1.8;
  return 2.0;
}

function getConsistencyBonus(weeklyCompletionRate: number): number {
  if (weeklyCompletionRate >= 0.9) return 0.20;
  if (weeklyCompletionRate >= 0.7) return 0.10;
  return 0;
}

function calculateDailyMomentum(
  actionRewards: number[],
  streakDays: number,
  weeklyCompletionRate: number
): number {
  const baseReward = actionRewards.reduce((sum, r) => sum + r, 0);
  const multiplier = getStreakMultiplier(streakDays);
  const bonus = 1 + getConsistencyBonus(weeklyCompletionRate);
  
  return Math.round(baseReward * multiplier * bonus);
}

function applyMomentumDecay(
  currentMomentum: number,
  daysMissed: number
): { newMomentum: number; resetStreak: boolean } {
  if (daysMissed === 0) {
    return { newMomentum: currentMomentum, resetStreak: false };
  }
  
  const decayRule = CONFIG.DECAY_RULES[Math.min(daysMissed, 7)];
  return {
    newMomentum: Math.round(currentMomentum * decayRule.momentum_factor),
    resetStreak: decayRule.reset_streak,
  };
}
9.5 运势计算算法
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        FORTUNE CALCULATION ALGORITHM                           ║
║                        (八字日运 + 紫微流日)                                   ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   CALCULATION PIPELINE                                                        ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   ┌─────────────────┐                                                         ║
║   │  User BirthTime │                                                         ║
║   └────────┬────────┘                                                         ║
║            │                                                                  ║
║            ▼                                                                  ║
║   ┌────────────────────────────────────────────────────────────────────────┐ ║
║   │  Step 1: BaZi Calculation (八字排盘)                                    │ ║
║   │  ────────────────────────────────────────────────────────────────────  │ ║
║   │  • 计算年柱、月柱、日柱、时柱                                          │ ║
║   │  • 确定日主 (日干)                                                     │ ║
║   │  • 分析五行强弱                                                        │ ║
║   │  • 确定用神、忌神                                                      │ ║
║   └────────────────────────────────────────────────────────────────────────┘ ║
║            │                                                                  ║
║            ▼                                                                  ║
║   ┌────────────────────────────────────────────────────────────────────────┐ ║
║   │  Step 2: Daily Pillar Analysis (日柱分析)                               │ ║
║   │  ────────────────────────────────────────────────────────────────────  │ ║
║   │  • 今日干支与命局的关系                                                │ ║
║   │  • 生克制化分析                                                        │ ║
║   │  • 神煞影响                                                            │ ║
║   └────────────────────────────────────────────────────────────────────────┘ ║
║            │                                                                  ║
║            ▼                                                                  ║
║   ┌────────────────────────────────────────────────────────────────────────┐ ║
║   │  Step 3: ZiWei Flow Day (紫微流日)                                      │ ║
║   │  ────────────────────────────────────────────────────────────────────  │ ║
║   │  • 流日宫位落点                                                        │ ║
║   │  • 四化飞星影响                                                        │ ║
║   │  • 吉凶星曜组合                                                        │ ║
║   └────────────────────────────────────────────────────────────────────────┘ ║
║            │                                                                  ║
║            ▼                                                                  ║
║   ┌────────────────────────────────────────────────────────────────────────┐ ║
║   │  Step 4: Score Synthesis (综合评分)                                     │ ║
║   │  ────────────────────────────────────────────────────────────────────  │ ║
║   │  fortune_score = bazi_score × 0.4 + ziwei_score × 0.4 + special × 0.2 │ ║
║   │                                                                        │ ║
║   │  Levels:                                                               │ ║
║   │  • 90-100: excellent (大吉)                                            │ ║
║   │  • 70-89: good (吉)                                                    │ ║
║   │  • 50-69: normal (平)                                                  │ ║
║   │  • 30-49: caution (需注意)                                             │ ║
║   │  • 0-29: difficult (不利)                                              │ ║
║   └────────────────────────────────────────────────────────────────────────┘ ║
║            │                                                                  ║
║            ▼                                                                  ║
║   ┌────────────────────────────────────────────────────────────────────────┐ ║
║   │  Step 5: Suggestion Generation (建议生成)                               │ ║
║   │  ────────────────────────────────────────────────────────────────────  │ ║
║   │  • 基于运势等级生成行动建议                                            │ ║
║   │  • 宜/忌事项                                                           │ ║
║   │  • 幸运元素 (颜色/数字/方位)                                           │ ║
║   └────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
typescript// 运势计算实现 (简化版)

interface FortuneResult {
  fortune_score: number;        // 1-100
  fortune_level: FortuneLevel;
  analysis: {
    overall: string;
    career: string;
    relationship: string;
    health: string;
    wealth: string;
  };
  suggestions: string[];
  avoid_items: string[];
  lucky_items: {
    color: string;
    number: number;
    direction: string;
  };
}

type FortuneLevel = 'excellent' | 'good' | 'normal' | 'caution' | 'difficult';

async function calculateDailyFortune(
  userId: string,
  date: Date
): Promise<FortuneResult> {
  // 获取用户命盘数据
  const userProfile = await getUserProfile(userId);
  const baziChart = userProfile.bazi_data;
  const ziweiChart = userProfile.ziwei_data;
  
  // 计算今日干支
  const todayPillar = calculateDayPillar(date);
  
  // Step 1: 八字日运评分
  const baziScore = calculateBaziDailyScore(baziChart, todayPillar);
  
  // Step 2: 紫微流日评分
  const ziweiScore = calculateZiweiFlowDayScore(ziweiChart, date);
  
  // Step 3: 特殊因素 (节气、月相等)
  const specialScore = calculateSpecialFactors(date);
  
  // Step 4: 综合评分
  const fortune_score = Math.round(
    baziScore * 0.4 + ziweiScore * 0.4 + specialScore * 0.2
  );
  
  // Step 5: 确定等级
  const fortune_level = getFortuneLevel(fortune_score);
  
  // Step 6: 生成分析和建议 (使用 LLM)
  const analysisAndSuggestions = await generateFortuneAnalysis({
    baziChart,
    todayPillar,
    fortune_score,
    fortune_level,
  });
  
  return {
    fortune_score,
    fortune_level,
    ...analysisAndSuggestions,
  };
}

function getFortuneLevel(score: number): FortuneLevel {
  if (score >= 90) return 'excellent';
  if (score >= 70) return 'good';
  if (score >= 50) return 'normal';
  if (score >= 30) return 'caution';
  return 'difficult';
}

function calculateBaziDailyScore(baziChart: BaZiChart, todayPillar: Pillar): number {
  let score = 50; // 基础分
  
  const dayMaster = baziChart.dayPillar.heavenlyStem;
  const todayStem = todayPillar.heavenlyStem;
  const todayBranch = todayPillar.earthlyBranch;
  
  // 判断今日天干与日主的关系
  const stemRelation = getStemRelation(dayMaster, todayStem);
  
  // 用神得令加分，忌神当值减分
  if (stemRelation === 'helps' && isUsefulGod(baziChart, todayStem)) {
    score += 20;
  } else if (stemRelation === 'hurts' || isHarmfulGod(baziChart, todayStem)) {
    score -= 20;
  }
  
  // 地支刑冲破害减分
  const branchConflict = checkBranchConflicts(baziChart, todayBranch);
  score -= branchConflict.penalty;
  
  // 神煞加减分
  const shenShaEffect = calculateShenShaEffect(baziChart, todayPillar);
  score += shenShaEffect;
  
  return Math.max(0, Math.min(100, score));
}

10. 部署架构
10.1 云原生部署架构
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        CLOUD-NATIVE DEPLOYMENT ARCHITECTURE                    ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   VERCEL (Frontend + Edge + API)                                              ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                          VERCEL EDGE NETWORK                            │║
║   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │║
║   │  │ Edge Config │  │ Edge Cache  │  │Edge Function│  │ Edge KV     │    │║
║   │  │ (A/B Test)  │  │ (Static)    │  │ (Auth/Rate) │  │ (Session)   │    │║
║   │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                           │                                   ║
║   ┌─────────────────────────────────────────────────────────────────────────┐║
║   │                          VERCEL FUNCTIONS                               │║
║   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │║
║   │  │ /api/stream │  │ /api/decode │  │ /api/user   │  │ /api/tasks  │    │║
║   │  │ (Streaming) │  │ (Standard)  │  │ (Standard)  │  │ (Standard)  │    │║
║   │  │ Max 60s     │  │ Max 10s     │  │ Max 10s     │  │ Max 10s     │    │║
║   │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │║
║   └─────────────────────────────────────────────────────────────────────────┘║
║                                                                               ║
║   EXTERNAL SERVICES                                                           ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        ║
║   │  Neon       │  │  Upstash    │  │  Pinecone   │  │  Cloudflare │        ║
║   │  PostgreSQL │  │  Redis      │  │  Vectors    │  │  R2 Storage │        ║
║   │  (Serverless│  │  (Serverless│  │  (Serverless│  │  (S3 compat)│        ║
║   │  Branching) │  │  QStash)    │  │  Index)     │  │             │        ║
║   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        ║
║                                                                               ║
║   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        ║
║   │  OpenAI     │  │  Anthropic  │  │  Pusher     │  │  Resend     │        ║
║   │  GPT-4 +    │  │  Claude     │  │  WebSocket  │  │  Email      │        ║
║   │  Whisper +  │  │  (Backup)   │  │  Realtime   │  │  (Transact) │        ║
║   │  Embedding  │  │             │  │             │  │             │        ║
║   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
10.2 技术栈总览
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              TECHNOLOGY STACK                                  ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   FRONTEND                                                                    ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Framework: Next.js 14 (App Router)                                      ║
║   ├─ Language: TypeScript 5.3                                                ║
║   ├─ Styling: Tailwind CSS 3.4 + Framer Motion                               ║
║   ├─ State: Zustand + React Query (TanStack Query)                           ║
║   ├─ Forms: React Hook Form + Zod                                            ║
║   ├─ UI Components: Radix UI + shadcn/ui                                     ║
║   └─ Mobile: React Native (Expo) / Taro (WeChat Mini)                        ║
║                                                                               ║
║   BACKEND                                                                     ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Runtime: Next.js API Routes + Vercel Functions                          ║
║   ├─ AI SDK: Vercel AI SDK 4.0                                               ║
║   ├─ ORM: Drizzle ORM                                                        ║
║   ├─ Validation: Zod                                                         ║
║   ├─ Auth: NextAuth.js v5 + JWT                                              ║
║   └─ Background Jobs: Upstash QStash                                         ║
║                                                                               ║
║   DATABASE                                                                    ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Primary: Neon PostgreSQL (Serverless, Auto-scaling)                     ║
║   ├─ Cache: Upstash Redis (Serverless, Global)                               ║
║   ├─ Vector: Pinecone (Serverless, Pod-based)                                ║
║   └─ Media: Cloudflare R2 (S3 Compatible)                                    ║
║                                                                               ║
║   AI/ML SERVICES                                                              ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Primary LLM: OpenAI GPT-4 Turbo                                         ║
║   ├─ Backup LLM: Anthropic Claude 3.5 Sonnet                                 ║
║   ├─ China Region: ZhiPu GLM-4                                               ║
║   ├─ STT: OpenAI Whisper API                                                 ║
║   ├─ Embedding: OpenAI text-embedding-3-small                                ║
║   └─ Vision: OpenAI GPT-4 Vision                                             ║
║                                                                               ║
║   INFRASTRUCTURE                                                              ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Hosting: Vercel (Edge + Functions)                                      ║
║   ├─ CDN: Vercel Edge Network + Cloudflare                                   ║
║   ├─ DNS: Cloudflare                                                         ║
║   ├─ SSL: Automatic (Vercel + Cloudflare)                                    ║
║   └─ Monitoring: Vercel Analytics + Sentry                                   ║
║                                                                               ║
║   REALTIME & NOTIFICATIONS                                                    ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ WebSocket: Pusher Channels                                              ║
║   ├─ Push: Firebase Cloud Messaging (FCM)                                    ║
║   ├─ Email: Resend                                                           ║
║   └─ SMS: Twilio (Optional)                                                  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
10.3 环境配置
bash# ═══════════════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES
# ═══════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# DATABASE
# ─────────────────────────────────────────────────────────────────────────────
DATABASE_URL="postgresql://user:pass@ep-xxx.us-east-1.aws.neon.tech/mentis?sslmode=require"
DATABASE_URL_UNPOOLED="postgresql://user:pass@ep-xxx.us-east-1.aws.neon.tech/mentis?sslmode=require"

# ─────────────────────────────────────────────────────────────────────────────
# REDIS (Upstash)
# ─────────────────────────────────────────────────────────────────────────────
UPSTASH_REDIS_REST_URL="https://xxx.upstash.io"
UPSTASH_REDIS_REST_TOKEN="xxx"

# ─────────────────────────────────────────────────────────────────────────────
# VECTOR DATABASE (Pinecone)
# ─────────────────────────────────────────────────────────────────────────────
PINECONE_API_KEY="xxx"
PINECONE_ENVIRONMENT="us-east-1-aws"
PINECONE_INDEX="mentis-vectors"

# ─────────────────────────────────────────────────────────────────────────────
# OBJECT STORAGE (Cloudflare R2)
# ─────────────────────────────────────────────────────────────────────────────
R2_ACCOUNT_ID="xxx"
R2_ACCESS_KEY_ID="xxx"
R2_SECRET_ACCESS_KEY="xxx"
R2_BUCKET_NAME="mentis-media"

# ─────────────────────────────────────────────────────────────────────────────
# AI SERVICES
# ─────────────────────────────────────────────────────────────────────────────
OPENAI_API_KEY="sk-xxx"
ANTHROPIC_API_KEY="sk-ant-xxx"
ZHIPU_API_KEY="xxx"  # 国内用户

# ─────────────────────────────────────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────────────────────────────────────
NEXTAUTH_SECRET="xxx"
NEXTAUTH_URL="https://mentis.ai"

# ─────────────────────────────────────────────────────────────────────────────
# REALTIME (Pusher)
# ─────────────────────────────────────────────────────────────────────────────
PUSHER_APP_ID="xxx"
PUSHER_KEY="xxx"
PUSHER_SECRET="xxx"
PUSHER_CLUSTER="us2"
NEXT_PUBLIC_PUSHER_KEY="xxx"

# ─────────────────────────────────────────────────────────────────────────────
# EMAIL (Resend)
# ─────────────────────────────────────────────────────────────────────────────
RESEND_API_KEY="re_xxx"

# ─────────────────────────────────────────────────────────────────────────────
# MONITORING
# ─────────────────────────────────────────────────────────────────────────────
SENTRY_DSN="https://xxx@sentry.io/xxx"
NEXT_PUBLIC_SENTRY_DSN="https://xxx@sentry.io/xxx"
10.4 性能指标 (SLO/SLI)
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        SERVICE LEVEL OBJECTIVES (SLO)                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   AVAILABILITY                                                                ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Overall System: 99.9% uptime (monthly)                                  ║
║   ├─ Core API: 99.95% uptime                                                 ║
║   └─ WebSocket: 99.5% uptime                                                 ║
║                                                                               ║
║   LATENCY (P95)                                                               ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Stream Input → First Response: < 500ms                                  ║
║   ├─ Stream Input → Complete Processing: < 3000ms                            ║
║   ├─ Emotion Detection: < 300ms                                              ║
║   ├─ Behavior Match: < 200ms                                                 ║
║   ├─ State Update Broadcast: < 100ms                                         ║
║   ├─ Fortune Query: < 500ms (cached) / < 2000ms (computed)                   ║
║   └─ Page Load (TTFB): < 200ms                                               ║
║                                                                               ║
║   THROUGHPUT                                                                  ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Concurrent Users: 10,000+                                               ║
║   ├─ Requests/Second: 1,000+ (API)                                           ║
║   └─ WebSocket Connections: 50,000+                                          ║
║                                                                               ║
║   ERROR RATES                                                                 ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ 5xx Errors: < 0.1%                                                      ║
║   ├─ AI Service Failures: < 0.5%                                             ║
║   └─ WebSocket Disconnects: < 1%/hour                                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

11. 演进路线图
11.1 版本演进计划
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           VERSION ROADMAP                                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   v3.0 MVP (Month 1-2)                                                        ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Core Stream Architecture                                                ║
║   ├─ Vibe Diary Input (Voice + Text)                                         ║
║   ├─ Basic Emotion Detection                                                 ║
║   ├─ Dynamic Aura System                                                     ║
║   ├─ Simple Action Cards                                                     ║
║   ├─ BaZi Daily Fortune                                                      ║
║   └─ Momentum Tracking                                                       ║
║                                                                               ║
║   v3.1 Enhancement (Month 3-4)                                                ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ NLU Auto Checkin                                                        ║
║   ├─ Proactive Agent Intervention                                            ║
║   ├─ ZiWei Module Integration                                                ║
║   ├─ Weekly Mirror Report                                                    ║
║   ├─ Pattern Detection                                                       ║
║   └─ Photo Input + Vision                                                    ║
║                                                                               ║
║   v3.2 Intelligence (Month 5-6)                                               ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ CBT Module (Cognitive Reframe)                                          ║
║   ├─ MBTI Assessment Integration                                             ║
║   ├─ Advanced Behavior Matching                                              ║
║   ├─ Personalized Habit Prescription                                         ║
║   ├─ Cross-device Sync                                                       ║
║   └─ Notification Optimization                                               ║
║                                                                               ║
║   v3.3 Social & Advanced (Month 7-9)                                          ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Social Features (Energy Boost)                                          ║
║   ├─ Couples/Team Mode                                                       ║
║   ├─ Voice Persona (TTS)                                                     ║
║   ├─ Advanced Analytics Dashboard                                            ║
║   ├─ Calendar Integration                                                    ║
║   └─ Third-party Wearable Integration                                        ║
║                                                                               ║
║   v4.0 Platform (Month 10-12)                                                 ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ Plugin Marketplace                                                      ║
║   ├─ Custom Module SDK                                                       ║
║   ├─ Enterprise Features                                                     ║
║   ├─ Advanced AI Persona                                                     ║
║   ├─ Multi-language Support                                                  ║
║   └─ White-label Solution                                                    ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
11.2 MVP 功能优先级矩阵
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        MVP FEATURE PRIORITY MATRIX                             ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║                           HIGH IMPACT                                         ║
║                              ▲                                                ║
║                              │                                                ║
║   ┌──────────────────────────┼──────────────────────────┐                    ║
║   │                          │                          │                    ║
║   │  P1: DO FIRST            │   P2: DO SECOND          │                    ║
║   │  ─────────────           │   ─────────────          │                    ║
║   │  • Stream Input          │   • NLU Auto Checkin     │                    ║
║   │  • Emotion Detection     │   • Weekly Report        │                    ║
║   │  • Dynamic Aura          │   • Pattern Detection    │                    ║
║   │  • Basic Action Cards    │   • Photo Input          │                    ║
║   │  • Real-time Sync        │   • Advanced Triggers    │                    ║
║   │                          │                          │                    ║
║ L ├──────────────────────────┼──────────────────────────┤ H                 ║
║ O │                          │                          │ I                 ║
║ W │  P4: DO LATER            │   P3: DO THIRD           │ G                 ║
║   │  ─────────────           │   ─────────────          │ H                 ║
║ E │  • Social Features       │   • CBT Module           │                    ║
║ F │  • Calendar Sync         │   • MBTI Integration     │ E                 ║
║ F │  • Voice Persona         │   • ZiWei Module         │ F                 ║
║ O │  • Wearable Integration  │   • Desktop App          │ F                 ║
║ R │  • Enterprise Features   │   • Advanced Analytics   │ O                 ║
║ T │                          │                          │ R                 ║
║   └──────────────────────────┼──────────────────────────┘ T                 ║
║                              │                                                ║
║                              ▼                                                ║
║                           LOW IMPACT                                          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
11.3 技术债务管理
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        TECHNICAL DEBT MANAGEMENT                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   MVP 阶段允许的技术债务                                                       ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ 简化的错误处理 → v3.1 统一错误框架                                      ║
║   ├─ 硬编码配置 → v3.1 配置中心                                              ║
║   ├─ 基础日志 → v3.1 结构化日志 + 追踪                                       ║
║   ├─ 简单缓存策略 → v3.2 多层缓存                                            ║
║   └─ 单一 AI 提供商 → v3.2 多模型路由                                        ║
║                                                                               ║
║   必须在 MVP 完成的基础设施                                                    ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   ├─ 数据库迁移系统 (Drizzle Migrations)                                     ║
║   ├─ API 版本控制 (/v3/...)                                                  ║
║   ├─ 认证/授权框架                                                           ║
║   ├─ CI/CD 流水线                                                            ║
║   ├─ 基础监控告警                                                            ║
║   └─ 数据备份策略                                                            ║
║                                                                               ║
║   技术债务偿还计划                                                            ║
║   ─────────────────────────────────────────────────────────────────────────   ║
║   • 每个 Sprint 预留 15% 时间处理技术债务                                     ║
║   • 大版本发布前进行技术债务审计                                              ║
║   • 保持测试覆盖率 > 70%                                                      ║
║   • 代码审查强制执行                                                          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

12. 附录
12.1 术语表 (Glossary)
术语英文定义StreamStream用户生活流，所有输入和反馈的时间线Vibe DiaryVibe Diary情绪日记，用户的碎碎念输入Action CardAction Card可交互的任务卡片，由 Agent 推送Dynamic AuraDynamic Aura动态光环，根据情绪变化的背景效果MomentumMomentum动量，用户行为积累的成长指数DECODEDECODE解码层，包含八字、紫微等命理模块REFRAMEREFRAME重塑层，包含 CBT、ACT 等认知重构EVOLVEEVOLVE进化层，包含习惯、行为处方模块HUDHeads-Up Display抬头显示，环境感知层NLUNatural Language Understanding自然语言理解
12.2 参考资料
Architecture References:
├─ Vercel AI SDK Documentation
├─ Next.js App Router Best Practices
├─ Drizzle ORM Documentation
├─ Pinecone Vector Database Guide
└─ Pusher Channels Documentation

Domain Knowledge:
├─ 八字命理基础理论
├─ 紫微斗数入门
├─ CBT 认知行为疗法
├─ ACT 接纳承诺疗法
└─ 微习惯理论 (BJ Fogg)

Design Patterns:
├─ Event-Driven Architecture
├─ CQRS Pattern
├─ Saga Pattern
└─ Domain-Driven Design
12.3 变更日志
v3.0.0 (2026-01-04)
─────────────────────
- Initial v3.0 Architecture Document
- Stream-Centric Design Philosophy
- Three-Layer Interaction Model
- Complete Data Model Design
- API Specification
- Core Algorithm Documentation
- Deployment Architecture
- MVP Roadmap

Based on v2.0 → v2.1 iterations:
- Dashboard → Ambient HUD transformation
- Chat-first → Stream-first paradigm shift
- Manual checkin → NLU auto-recognition
- Reactive → Proactive Agent model

╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                              END OF DOCUMENT                                  ║
║                                                                               ║
║                          MENTIS v3.0 Architecture                             ║
║                      Stream-Centric Agentic Platform                          ║
║                                                                               ║
║                         Decode. Reframe. Evolve.                              ║
║                     解码命运 · 重塑认知 · 进化人生                            ║
║                                                                               ║
║  ─────────────────────────────────────────────────────────────────────────   ║
║                                                                               ║
║  Document Version: 3.0                                                        ║
║  Last Updated: 2026-01-04                                                     ║
║  Author: Silicon Valley Principal Architect                                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝