# Fortune AI 系统架构设计（Claude MVP v1.1）

**文档类型**：System Design
**产品代号**：`Fortune AI - 精神数字孪生与人生智能OS`
**版本**：`MVP v1.1`
**日期**：2025-12-30
**输入依据**：`bp v1.md`（商业计划书）、`system_design_codex_v5.md`（技术参考）
**智能体框架**：Vercel AI SDK（独立编排服务）+ FastAPI（SSOT 后端）

---

## 0. 执行摘要

### 0.1 产品定位（来自 bp v1.md）

> **用AI智能体重构"心理成长"；智能体是你的"精神操作系统"，精神数字孪生是你的"角色面板"**

### 0.2 架构目标

本设计旨在实现商业计划书中的三大核心支柱：

| 支柱 | 描述 | 技术映射 |
|------|------|----------|
| **实体数字化** | 把心理状态变成结构化数字孪生 Avatar | Multi-Layer Twin Model + PostgreSQL SSOT |
| **深层次心理动机** | 把痛苦的"成长"变成爽感的"练级" | Gamification Engine + Social Graph |
| **主动化推理** | 基于数据的智能体主动预判与干预 | Vercel AI SDK Multi-Agent + JITAI |

### 0.3 技术选型决策（衔接现有代码）

| 层面 | 选型 | 理由 |
|------|------|------|
| **业务后端** | FastAPI（现有） | SSOT 保障、复用现有认证/数据层、避免大规模重构 |
| **智能体编排** | Vercel AI SDK（独立服务） | Tool Calling、Multi-Agent、流式输出 |
| **数据库** | PostgreSQL + pgvector | 现有基础设施复用、SSOT、语义检索 |
| **LLM Provider** | Multi-Provider (GLM-4/Claude/OpenAI) | Vercel AI SDK 统一接口、Provider 热切换 |
| **前端** | Jinja2 + 原生 JS（现有） | 复用 bazi2.html + ui.js，渐进增强 |
| **部署** | FastAPI + Agent Service 分离部署 | 独立扩缩、故障隔离 |

### 0.4 架构总览（FastAPI + Agent Service 分离）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户层                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │   Web UI        │    │   小程序/App    │    │   分享卡/QR     │         │
│  │  (Jinja2+JS)    │    │   (可选)        │    │   (扫码入口)    │         │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘         │
│           │                      │                      │                   │
└───────────┼──────────────────────┼──────────────────────┼───────────────────┘
            │                      │                      │
            ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FastAPI 业务后端（SSOT）                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Auth      │  │   User      │  │   Twin      │  │   Social    │        │
│  │   Routes    │  │   Routes    │  │   Routes    │  │   Routes    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Currency   │  │   Plan      │  │   KB        │  │  Tool API   │        │
│  │   Routes    │  │   Routes    │  │   Routes    │  │  (Internal) │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                              │                                              │
│                              ▼                                              │
│                    ┌─────────────────┐                                      │
│                    │   PostgreSQL    │                                      │
│                    │     SSOT        │                                      │
│                    └─────────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────┘
            │
            │ Agent Call (HTTP/gRPC)
            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Agent Orchestrator（Vercel AI SDK）                       │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                      Orchestrator Layer                             │     │
│  │   • 意图识别    • 安全检查    • Agent 路由    • A2UI 组装          │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│          │              │               │              │                    │
│          ▼              ▼               ▼              ▼                    │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │                   Agent Pool + Knowledge Base Registry            │      │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │      │
│  │  │  Coach   │  │ Analyst  │  │  Social  │  │  Expert  │         │      │
│  │  │ Agent    │  │ Agent    │  │ Agent    │  │ Factory  │         │      │
│  │  │ +KB[]    │  │ +KB[]    │  │ +KB[]    │  │ +KB[]    │         │      │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │      │
│  └──────────────────────────────────────────────────────────────────┘      │
│                              │                                              │
│                              ▼                                              │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │              Pluggable Knowledge Base System                      │      │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐    │      │
│  │  │ 八字KB │  │ 紫薇KB │  │ 星座KB │  │心理学KB│  │ 自定义 │    │      │
│  │  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘    │      │
│  └──────────────────────────────────────────────────────────────────┘      │
│                              │                                              │
│                    Tool Calls (via SERVICE_TOKEN)                           │
│                              │                                              │
└──────────────────────────────┼──────────────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   LLM Provider  │
                    │  GLM/Claude/GPT │
                    └─────────────────┘
```

---

## 1. 精神数字孪生模型（Spiritual Digital Twin）

> **核心资产**：一个随状态实时变化的结构化"角色面板"

### 1.1 三层孪生架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    L3 - 可视化展示层                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  数据看板    │  │  能量雷达图  │  │  时间序列    │           │
│  │  Dashboard   │  │  Aura Radar  │  │  Timeline    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                    L2 - 动态状态层                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  玄学分析    │  │  生物数据    │  │  社交状态    │           │
│  │  水逆/流年   │  │  睡眠/步数   │  │  关系图谱    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│           ↑               ↑               ↑                     │
│       智能体交互       外部API        社交系统                   │
├─────────────────────────────────────────────────────────────────┤
│                    L1 - 元数据层（出厂设置）                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  玄学元数据  │  │  心理学元数据 │  │  历史记忆    │           │
│  │  八字/星盘   │  │  PERMA/VIA   │  │  对话摘要    │           │
│  │  MBTI/紫薇   │  │  依附类型    │  │  关键事件    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 数据模型定义

```typescript
// types/twin.ts
interface SpiritualDigitalTwin {
  // L1 - 元数据层（相对稳定）
  metadata: {
    astrology: {
      bazi: BaziSnapshot;           // 八字四柱
      zodiac: ZodiacProfile;        // 星座星盘
      ziwei: ZiweiChart | null;     // 紫薇斗数（可选）
    };
    psychology: {
      mbti: MBTIProfile | null;
      perma: PERMAScores;           // 积极心理学五维度
      via_strengths: string[];      // 品格优势
      attachment_style: AttachmentType;
    };
    memory: {
      key_events: KeyEvent[];       // 关键人生事件
      conversation_summary: string; // 对话摘要（定期更新）
      last_updated: Date;
    };
  };

  // L2 - 动态状态层（实时变化）
  dynamic_state: {
    astro_context: {
      current_transit: TransitInfo;   // 当前行星过境
      retrograde_status: RetrogradeStatus[]; // 逆行状态
      daily_theme: string;
    };
    bio_state: {
      sleep_score: number | null;     // 0-100
      activity_level: number | null;
      stress_indicator: number | null;
    };
    social_state: {
      active_relationships: number;
      recent_interactions: number;
      support_network_score: number;
    };
    emotional_state: {
      current_mood: MoodType;
      mood_intensity: number;         // 0-10
      last_checkin: Date;
    };
  };

  // L3 - 聚合指标层（展示用）
  aggregated_metrics: {
    aura_points: number;              // 能量积分
    overall_wellbeing: number;        // 综合幸福指数 0-100
    growth_streak: number;            // 连续成长天数
    dimension_scores: {
      energy: number;                 // 能量维度
      clarity: number;                // 清晰度维度
      connection: number;             // 连接维度
      growth: number;                 // 成长维度
      balance: number;                // 平衡维度
    };
  };
}
```

### 1.3 孪生更新机制

```typescript
// services/twin-updater.ts
type TwinUpdateTrigger =
  | 'daily_refresh'      // 每日自动刷新
  | 'checkin_completed'  // 情绪打卡后
  | 'commitment_done'    // 完成承诺后
  | 'chat_insight'       // 对话中提取洞察
  | 'social_event'       // 社交事件发生
  | 'external_sync';     // 外部数据同步

interface TwinUpdateEvent {
  trigger: TwinUpdateTrigger;
  layer: 'L1' | 'L2' | 'L3';
  path: string;           // e.g., 'dynamic_state.emotional_state.current_mood'
  old_value: any;
  new_value: any;
  confidence: number;     // 0-1
  source: string;         // 来源追溯
  timestamp: Date;
}
```

---

## 2. AI 智能体系统架构（基于 Vercel AI SDK）

### 2.1 多智能体架构总览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Soul OS - 灵魂操作系统                           │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    Orchestrator Agent（编排层）                   │    │
│  │   • 意图识别与路由                                                │    │
│  │   • 上下文聚合                                                    │    │
│  │   • 多 Agent 协调                                                 │    │
│  │   • A2UI 输出组装                                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│          │              │               │              │                 │
│          ▼              ▼               ▼              ▼                 │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐             │
│  │  Coach   │   │ Analyst  │   │  Social  │   │  Expert  │             │
│  │  Agent   │   │  Agent   │   │  Agent   │   │  Agents  │             │
│  │          │   │          │   │          │   │          │             │
│  │ 对话陪伴 │   │ 数据分析 │   │ 社交匹配 │   │ 专家知识 │             │
│  │ 行动计划 │   │ 孪生更新 │   │ 群体机制 │   │ 可插拔   │             │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘             │
│                                                    │                     │
│                                    ┌───────────────┼───────────────┐    │
│                                    │               │               │    │
│                               ┌────┴────┐   ┌────┴────┐   ┌────┴────┐  │
│                               │  八字   │   │  紫薇   │   │  星座   │  │
│                               │ Expert  │   │ Expert  │   │ Expert  │  │
│                               └─────────┘   └─────────┘   └─────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Vercel AI SDK 实现架构

```typescript
// lib/ai/agents/index.ts
import { experimental_createModelRegistry as createModelRegistry } from 'ai';
import { openai } from '@ai-sdk/openai';
import { anthropic } from '@ai-sdk/anthropic';

// 模型注册（多 Provider 支持）
export const modelRegistry = createModelRegistry({
  openai,
  anthropic,
  // 自定义 GLM Provider
  glm: createGLMProvider({
    baseURL: process.env.GLM_BASE_URL,
    apiKey: process.env.GLM_API_KEY,
  }),
});

// Agent 基础配置
interface AgentConfig {
  id: string;
  name: string;
  model: string;                    // e.g., 'openai:gpt-4-turbo'
  systemPrompt: string;
  tools: Tool[];
  maxTokens?: number;
  temperature?: number;
}
```

### 2.3 核心 Agent 定义

#### 2.3.1 Coach Agent（教练智能体）

```typescript
// lib/ai/agents/coach-agent.ts
import { generateText, streamText, tool } from 'ai';
import { z } from 'zod';

export const coachAgent: AgentConfig = {
  id: 'coach',
  name: 'Fortune Coach',
  model: 'glm:glm-4',
  systemPrompt: `你是 Fortune AI 的核心教练智能体，角色定位：

【身份】
- 积极心理学教练（Performance Coach）
- 温暖而不讨好，直接而不冒犯
- 永远站在用户的成长角度

【核心职责】
1. 情绪承接：先共情，再分析
2. 洞察提供：基于孪生数据给出个性化解读
3. 行动推动：每次对话必须产出可执行的最小行动
4. 承诺邀请：引导用户做出承诺（commitment）

【输出规范】
- 必须使用 A2UI JSON 格式
- 每次输出包含：结论 + 依据 + ≤3条处方 + 承诺邀请
- 禁止恐吓、宿命论、绝对预测

【可用工具】
- query_twin: 查询用户数字孪生数据
- create_commitment: 创建行动承诺
- search_kb: 搜索知识库
- schedule_task: 安排任务到计划`,

  tools: [
    tool({
      name: 'query_twin',
      description: '查询用户的精神数字孪生数据',
      parameters: z.object({
        layer: z.enum(['L1', 'L2', 'L3']),
        path: z.string().optional(),
      }),
      execute: async ({ layer, path }) => {
        // 实现：从数据库获取孪生数据
      },
    }),

    tool({
      name: 'create_commitment',
      description: '为用户创建一个行动承诺',
      parameters: z.object({
        title: z.string(),
        type: z.enum(['start_task', 'schedule_task', 'daily_habit']),
        duration_minutes: z.number().optional(),
        due_at: z.string().optional(),
      }),
      execute: async (params) => {
        // 实现：写入 fortune_commitment 表
      },
    }),

    tool({
      name: 'search_kb',
      description: '搜索知识库获取专业内容',
      parameters: z.object({
        query: z.string(),
        domain: z.enum(['psychology', 'astrology', 'bazi', 'practice']),
        limit: z.number().default(3),
      }),
      execute: async ({ query, domain, limit }) => {
        // 实现：RAG 检索
      },
    }),
  ],

  temperature: 0.7,
  maxTokens: 1500,
};
```

#### 2.3.2 Analyst Agent（分析智能体）

```typescript
// lib/ai/agents/analyst-agent.ts
export const analystAgent: AgentConfig = {
  id: 'analyst',
  name: 'Twin Analyst',
  model: 'glm:glm-4',
  systemPrompt: `你是数字孪生分析师，职责是从用户对话和行为中提取结构化信息。

【核心任务】
1. 情绪状态识别：从对话中识别情绪类型和强度
2. 关键事件提取：识别影响用户状态的事件
3. 模式识别：发现用户行为/思维模式
4. 孪生更新建议：产出结构化的孪生更新指令

【输出格式】
{
  "insights": [...],           // 洞察列表
  "twin_updates": [...],       // 孪生更新指令
  "risk_flags": [...],         // 风险标记（如自伤倾向）
  "confidence": 0.0-1.0
}

【注意事项】
- 只提取明确表达或强烈暗示的信息
- 不做过度推断
- 风险检测优先级最高`,

  tools: [
    tool({
      name: 'update_twin',
      description: '更新用户数字孪生的特定字段',
      parameters: z.object({
        layer: z.enum(['L1', 'L2', 'L3']),
        path: z.string(),
        value: z.any(),
        confidence: z.number(),
        reason: z.string(),
      }),
      execute: async (params) => {
        // 实现：写入 twin_update_log 并触发更新
      },
    }),

    tool({
      name: 'flag_risk',
      description: '标记风险信号',
      parameters: z.object({
        risk_type: z.enum(['self_harm', 'crisis', 'dependency', 'medical']),
        severity: z.enum(['low', 'medium', 'high', 'critical']),
        evidence: z.string(),
      }),
      execute: async (params) => {
        // 实现：触发安全协议
      },
    }),
  ],

  temperature: 0.3,  // 低温度保证稳定性
  maxTokens: 800,
};
```

#### 2.3.3 Social Agent（社交智能体）

```typescript
// lib/ai/agents/social-agent.ts
export const socialAgent: AgentConfig = {
  id: 'social',
  name: 'Connection Agent',
  model: 'glm:glm-4',
  systemPrompt: `你是社交连接智能体，负责处理用户间的深度连接。

【核心功能】
1. 合盘分析：基于双方孪生数据分析关系动力学
2. 匹配推荐：基于深层特征而非表面兴趣
3. 群体机制：能量打赏、好运接龙、吐槽大会
4. 隐私保护：不泄露具体出生时间等敏感信息

【社交玩法】
- 能量打赏（Buff）：好友间的能量传递
- 好运接龙：群体仪式感 + 裂变
- 吐槽大会：安全宣泄 + 重评训练`,

  tools: [
    tool({
      name: 'generate_compatibility',
      description: '生成两人或多人合盘分析',
      parameters: z.object({
        user_ids: z.array(z.string()),
        relationship_type: z.enum(['romantic', 'friendship', 'work', 'family']),
        depth: z.enum(['quick', 'standard', 'deep']),
      }),
      execute: async (params) => {
        // 实现：合盘算法
      },
    }),

    tool({
      name: 'send_energy_buff',
      description: '发送能量打赏',
      parameters: z.object({
        from_user_id: z.string(),
        to_user_id: z.string(),
        buff_type: z.enum(['energy', 'luck', 'calm', 'focus']),
        amount: z.number(),
      }),
      execute: async (params) => {
        // 实现：写入 ledger + 触发通知
      },
    }),
  ],
};
```

#### 2.3.4 Expert Agent Factory（专家智能体工厂）

```typescript
// lib/ai/agents/expert-factory.ts
interface ExpertConfig {
  domain: 'bazi' | 'ziwei' | 'zodiac' | 'mbti' | 'perma';
  name: string;
  knowledgeBase: string;      // KB 路径
  systemPromptTemplate: string;
}

const expertConfigs: ExpertConfig[] = [
  {
    domain: 'bazi',
    name: '八字专家',
    knowledgeBase: 'kb/bazi',
    systemPromptTemplate: `你是八字命理专家，基于用户的八字数据提供解读。

【专业规范】
- 基于四柱（年月日时）进行分析
- 结合十神、神煞、大运流年
- 翻译为现代心理学语言
- 禁止绝对预测，使用概率语言`,
  },
  {
    domain: 'zodiac',
    name: '星座专家',
    knowledgeBase: 'kb/astrology',
    systemPromptTemplate: `你是占星学专家，基于星盘数据提供解读。

【专业规范】
- 分析太阳、月亮、上升等关键配置
- 关注当前行星过境影响
- 结合积极心理学框架
- 给出可行动的建议`,
  },
  // ... 更多专家配置
];

export function createExpertAgent(domain: ExpertConfig['domain']): AgentConfig {
  const config = expertConfigs.find(c => c.domain === domain);
  if (!config) throw new Error(`Unknown expert domain: ${domain}`);

  return {
    id: `expert-${domain}`,
    name: config.name,
    model: 'glm:glm-4',
    systemPrompt: config.systemPromptTemplate,
    tools: [
      tool({
        name: 'search_domain_kb',
        description: `搜索${config.name}知识库`,
        parameters: z.object({ query: z.string() }),
        execute: async ({ query }) => {
          // 实现：领域特定 RAG
        },
      }),
    ],
  };
}
```

### 2.4 可插拔知识库系统（Pluggable Knowledge Base）

> **核心设计**：每个 Agent 都可动态绑定多个知识库，用户可根据偏好/付费状态灵活配置

#### 2.4.1 知识库注册表架构

```typescript
// lib/kb/registry.ts

/**
 * 知识库类型定义
 */
interface KnowledgeBase {
  kb_id: string;                    // 唯一标识
  name: string;                     // 显示名称
  domain: KBDomain;                 // 领域分类
  description: string;

  // 访问控制
  access_level: 'free' | 'basic' | 'premium' | 'enterprise';
  price_coins: number;              // 解锁所需金币（0=免费）

  // 技术配置
  retrieval_config: {
    type: 'fts' | 'vector' | 'hybrid';  // 检索类型
    collection: string;                   // pgvector collection 或 FTS 表
    embedding_model?: string;             // 向量模型
    top_k: number;                        // 默认返回条数
    rerank?: boolean;                     // 是否重排序
  };

  // 元信息
  chunk_count: number;
  last_updated: Date;
  version: string;

  // 可用性
  is_active: boolean;
  compatible_agents: string[];      // 兼容的 Agent ID 列表
}

type KBDomain =
  | 'astrology'      // 占星/星座
  | 'bazi'           // 八字命理
  | 'ziwei'          // 紫薇斗数
  | 'psychology'     // 心理学
  | 'practice'       // 练习/仪式
  | 'relationship'   // 关系/合盘
  | 'custom';        // 用户自定义

/**
 * 知识库注册表
 */
class KBRegistry {
  private kbs: Map<string, KnowledgeBase> = new Map();

  // 注册知识库
  register(kb: KnowledgeBase): void {
    this.kbs.set(kb.kb_id, kb);
  }

  // 获取用户可用的知识库列表
  async getAvailableForUser(userId: string): Promise<KnowledgeBase[]> {
    const userAccess = await this.getUserAccessLevel(userId);
    const unlockedKBs = await this.getUserUnlockedKBs(userId);

    return Array.from(this.kbs.values()).filter(kb => {
      // 检查访问级别或已解锁
      return kb.is_active && (
        this.accessLevelSufficient(userAccess, kb.access_level) ||
        unlockedKBs.includes(kb.kb_id)
      );
    });
  }

  // 获取 Agent 绑定的知识库
  async getKBsForAgent(agentId: string, userId: string): Promise<KnowledgeBase[]> {
    const userKBs = await this.getAvailableForUser(userId);
    const userBindings = await this.getUserAgentKBBindings(userId, agentId);

    return userKBs.filter(kb =>
      kb.compatible_agents.includes(agentId) &&
      (userBindings.length === 0 || userBindings.includes(kb.kb_id))
    );
  }

  // 解锁知识库（付费）
  async unlockKB(userId: string, kbId: string): Promise<UnlockResult> {
    const kb = this.kbs.get(kbId);
    if (!kb) throw new Error('KB not found');

    // 扣除金币
    const deducted = await deductCurrency(userId, kb.price_coins, {
      category: 'spend',
      reason: 'unlock_kb',
      ref_type: 'kb',
      ref_id: kbId,
    });

    if (!deducted) {
      return { success: false, error: 'insufficient_balance' };
    }

    // 记录解锁
    await db.insert(fortune_user_kb, {
      user_id: userId,
      kb_id: kbId,
      unlocked_at: new Date(),
      unlock_source: 'purchase',
    });

    return { success: true, kb };
  }
}

export const kbRegistry = new KBRegistry();
```

#### 2.4.2 用户知识库配置

```typescript
// lib/kb/user-config.ts

/**
 * 用户 Agent-KB 绑定配置
 */
interface UserAgentKBConfig {
  user_id: string;
  agent_id: string;
  kb_ids: string[];           // 启用的知识库列表（有序）
  custom_weights?: Record<string, number>;  // 知识库权重
  updated_at: Date;
}

/**
 * 获取用户对特定 Agent 的知识库配置
 */
async function getUserAgentKBConfig(
  userId: string,
  agentId: string
): Promise<UserAgentKBConfig> {
  // 1. 查询用户配置
  const config = await db.query(
    `SELECT * FROM fortune_user_agent_kb WHERE user_id = $1 AND agent_id = $2`,
    [userId, agentId]
  );

  if (config) return config;

  // 2. 返回默认配置（所有可用 KB）
  const availableKBs = await kbRegistry.getKBsForAgent(agentId, userId);
  return {
    user_id: userId,
    agent_id: agentId,
    kb_ids: availableKBs.map(kb => kb.kb_id),
    updated_at: new Date(),
  };
}

/**
 * 更新用户 Agent-KB 配置
 */
async function updateUserAgentKBConfig(
  userId: string,
  agentId: string,
  kbIds: string[],
  weights?: Record<string, number>
): Promise<void> {
  // 验证用户有权限访问这些 KB
  const available = await kbRegistry.getAvailableForUser(userId);
  const availableIds = new Set(available.map(kb => kb.kb_id));

  const invalidKBs = kbIds.filter(id => !availableIds.has(id));
  if (invalidKBs.length > 0) {
    throw new Error(`Unauthorized KB access: ${invalidKBs.join(', ')}`);
  }

  await db.upsert(fortune_user_agent_kb, {
    user_id: userId,
    agent_id: agentId,
    kb_ids: kbIds,
    custom_weights: weights || {},
    updated_at: new Date(),
  });
}
```

#### 2.4.3 混合检索实现

```typescript
// lib/kb/retriever.ts

interface RetrievalRequest {
  query: string;
  userId: string;
  agentId: string;
  limit?: number;
  filters?: Record<string, any>;
}

interface RetrievalResult {
  chunks: KBChunk[];
  sources: { kb_id: string; kb_name: string; count: number }[];
  total_searched: number;
}

/**
 * 多知识库混合检索
 */
async function retrieveFromKBs(req: RetrievalRequest): Promise<RetrievalResult> {
  const config = await getUserAgentKBConfig(req.userId, req.agentId);
  const kbs = await Promise.all(
    config.kb_ids.map(id => kbRegistry.get(id))
  );

  const allChunks: KBChunk[] = [];
  const sources: RetrievalResult['sources'] = [];

  for (const kb of kbs) {
    if (!kb) continue;

    const weight = config.custom_weights?.[kb.kb_id] || 1.0;
    const kbLimit = Math.ceil((req.limit || 5) * weight);

    let chunks: KBChunk[];

    switch (kb.retrieval_config.type) {
      case 'fts':
        chunks = await ftsSearch(kb, req.query, kbLimit);
        break;
      case 'vector':
        chunks = await vectorSearch(kb, req.query, kbLimit);
        break;
      case 'hybrid':
        chunks = await hybridSearch(kb, req.query, kbLimit);
        break;
    }

    // 添加来源标记
    chunks.forEach(c => {
      c.source_kb_id = kb.kb_id;
      c.source_kb_name = kb.name;
      c.weight = weight;
    });

    allChunks.push(...chunks);
    sources.push({ kb_id: kb.kb_id, kb_name: kb.name, count: chunks.length });
  }

  // 重排序（如果配置了）
  const rerankedChunks = await rerankChunks(allChunks, req.query, req.limit || 5);

  return {
    chunks: rerankedChunks,
    sources,
    total_searched: kbs.length,
  };
}

/**
 * FTS 全文搜索
 */
async function ftsSearch(kb: KnowledgeBase, query: string, limit: number): Promise<KBChunk[]> {
  return db.query(`
    SELECT chunk_id, content, title, meta,
           ts_rank(content_tsv, plainto_tsquery('simple', $1)) as score
    FROM fortune_kb_chunk
    WHERE collection = $2 AND content_tsv @@ plainto_tsquery('simple', $1)
    ORDER BY score DESC
    LIMIT $3
  `, [query, kb.retrieval_config.collection, limit]);
}

/**
 * 向量搜索
 */
async function vectorSearch(kb: KnowledgeBase, query: string, limit: number): Promise<KBChunk[]> {
  // 生成查询向量
  const queryEmbedding = await generateEmbedding(query, kb.retrieval_config.embedding_model);

  return db.query(`
    SELECT chunk_id, content, title, meta,
           1 - (embedding <=> $1::vector) as score
    FROM fortune_kb_chunk
    WHERE collection = $2
    ORDER BY embedding <=> $1::vector
    LIMIT $3
  `, [queryEmbedding, kb.retrieval_config.collection, limit]);
}

/**
 * 混合搜索（FTS + Vector）
 */
async function hybridSearch(kb: KnowledgeBase, query: string, limit: number): Promise<KBChunk[]> {
  const [ftsResults, vectorResults] = await Promise.all([
    ftsSearch(kb, query, limit * 2),
    vectorSearch(kb, query, limit * 2),
  ]);

  // 融合得分（RRF - Reciprocal Rank Fusion）
  const merged = rrfMerge(ftsResults, vectorResults, limit);
  return merged;
}
```

#### 2.4.4 预置知识库配置

```typescript
// lib/kb/presets.ts

/**
 * 系统预置知识库
 */
const PRESET_KNOWLEDGE_BASES: KnowledgeBase[] = [
  // ===== 免费知识库 =====
  {
    kb_id: 'psychology-basics',
    name: '积极心理学基础',
    domain: 'psychology',
    description: 'PERMA 模型、优势理论、正念基础',
    access_level: 'free',
    price_coins: 0,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_psychology_basics',
      embedding_model: 'text-embedding-3-small',
      top_k: 5,
      rerank: true,
    },
    chunk_count: 500,
    is_active: true,
    compatible_agents: ['coach', 'analyst'],
  },
  {
    kb_id: 'bazi-basics',
    name: '八字入门',
    domain: 'bazi',
    description: '四柱基础、五行生克、十神概念',
    access_level: 'free',
    price_coins: 0,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_bazi_basics',
      top_k: 5,
    },
    chunk_count: 300,
    is_active: true,
    compatible_agents: ['coach', 'expert-bazi'],
  },

  // ===== 基础付费知识库 =====
  {
    kb_id: 'bazi-advanced',
    name: '八字进阶',
    domain: 'bazi',
    description: '格局分析、大运流年、神煞详解',
    access_level: 'basic',
    price_coins: 100,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_bazi_advanced',
      top_k: 8,
      rerank: true,
    },
    chunk_count: 1200,
    is_active: true,
    compatible_agents: ['expert-bazi'],
  },
  {
    kb_id: 'zodiac-transits',
    name: '星座行运',
    domain: 'astrology',
    description: '行星过境、逆行影响、相位解读',
    access_level: 'basic',
    price_coins: 80,
    retrieval_config: {
      type: 'vector',
      collection: 'kb_zodiac_transits',
      embedding_model: 'text-embedding-3-small',
      top_k: 6,
    },
    chunk_count: 800,
    is_active: true,
    compatible_agents: ['coach', 'expert-zodiac'],
  },

  // ===== 高级付费知识库 =====
  {
    kb_id: 'ziwei-master',
    name: '紫微斗数精解',
    domain: 'ziwei',
    description: '命宫详解、四化飞星、流年流月',
    access_level: 'premium',
    price_coins: 300,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_ziwei_master',
      top_k: 10,
      rerank: true,
    },
    chunk_count: 2000,
    is_active: true,
    compatible_agents: ['expert-ziwei'],
  },
  {
    kb_id: 'relationship-dynamics',
    name: '关系动力学',
    domain: 'relationship',
    description: '依附理论、合盘解读、关系修复',
    access_level: 'premium',
    price_coins: 200,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_relationship',
      top_k: 8,
      rerank: true,
    },
    chunk_count: 1500,
    is_active: true,
    compatible_agents: ['social', 'coach'],
  },
  {
    kb_id: 'shadow-work',
    name: '阴影工作坊',
    domain: 'psychology',
    description: '荣格阴影理论、内在小孩、创伤疗愈',
    access_level: 'premium',
    price_coins: 250,
    retrieval_config: {
      type: 'hybrid',
      collection: 'kb_shadow_work',
      top_k: 8,
      rerank: true,
    },
    chunk_count: 1000,
    is_active: true,
    compatible_agents: ['coach', 'analyst'],
  },
];

// 初始化注册
PRESET_KNOWLEDGE_BASES.forEach(kb => kbRegistry.register(kb));
```

#### 2.4.5 Agent 知识库绑定增强

```typescript
// lib/ai/agents/base-agent.ts

/**
 * 增强版 Agent 基础配置（支持可插拔 KB）
 */
interface EnhancedAgentConfig extends AgentConfig {
  // 知识库配置
  kb_config: {
    required_domains: KBDomain[];     // 必需的知识库领域
    optional_domains: KBDomain[];     // 可选的知识库领域
    default_kb_ids: string[];         // 默认绑定的 KB
    max_kb_count: number;             // 最大可绑定 KB 数
  };

  // 检索配置
  retrieval_config: {
    enabled: boolean;
    max_chunks: number;
    min_score: number;
    include_sources: boolean;         // 是否在输出中包含来源引用
  };
}

/**
 * 创建带 KB 的 Agent 执行上下文
 */
async function createAgentContext(
  agentConfig: EnhancedAgentConfig,
  userId: string,
  query: string
): Promise<AgentContext> {
  // 1. 获取用户配置的知识库
  const kbConfig = await getUserAgentKBConfig(userId, agentConfig.id);

  // 2. 执行知识库检索
  let evidence: KBChunk[] = [];
  let sources: any[] = [];

  if (agentConfig.retrieval_config.enabled) {
    const retrieval = await retrieveFromKBs({
      query,
      userId,
      agentId: agentConfig.id,
      limit: agentConfig.retrieval_config.max_chunks,
    });

    evidence = retrieval.chunks.filter(
      c => c.score >= agentConfig.retrieval_config.min_score
    );
    sources = retrieval.sources;
  }

  // 3. 构建增强的系统提示词
  const enhancedSystemPrompt = buildEnhancedPrompt(agentConfig, evidence, sources);

  return {
    systemPrompt: enhancedSystemPrompt,
    evidence,
    sources,
    activeKBs: kbConfig.kb_ids,
  };
}

/**
 * 构建包含 KB 证据的增强提示词
 */
function buildEnhancedPrompt(
  config: EnhancedAgentConfig,
  evidence: KBChunk[],
  sources: any[]
): string {
  let prompt = config.systemPrompt;

  if (evidence.length > 0) {
    prompt += `\n\n【参考知识库】\n`;
    prompt += `已激活知识库：${sources.map(s => s.kb_name).join('、')}\n\n`;
    prompt += `【检索到的相关内容】\n`;

    evidence.forEach((chunk, i) => {
      prompt += `[${i + 1}] 来源：${chunk.source_kb_name}\n`;
      prompt += `${chunk.content}\n\n`;
    });

    prompt += `\n【引用规范】\n`;
    prompt += `- 回答中使用知识库内容时，请标注来源编号如 [1][2]\n`;
    prompt += `- 优先使用知识库中的准确表述\n`;
  }

  return prompt;
}
```

### 2.4 Orchestrator（编排层）实现

```typescript
// lib/ai/orchestrator.ts
import { generateObject, streamText } from 'ai';
import { z } from 'zod';

// 意图识别 Schema
const IntentSchema = z.object({
  primary_intent: z.enum([
    'emotional_support',    // 情绪支持
    'insight_seeking',      // 寻求洞察
    'action_planning',      // 行动规划
    'social_interaction',   // 社交互动
    'expert_consultation',  // 专家咨询
    'general_chat',         // 闲聊
  ]),
  sub_intent: z.string().optional(),
  required_agents: z.array(z.string()),
  expert_domains: z.array(z.string()).optional(),
  urgency: z.enum(['low', 'medium', 'high', 'critical']),
});

export async function orchestrate(
  userId: string,
  message: string,
  sessionContext: SessionContext,
): Promise<OrchestratorResult> {

  // Step 1: 加载用户孪生数据
  const twin = await loadTwinData(userId);

  // Step 2: 意图识别
  const { object: intent } = await generateObject({
    model: modelRegistry.get('glm:glm-4'),
    schema: IntentSchema,
    prompt: `分析用户意图：
用户消息：${message}
用户状态：${JSON.stringify(twin.dynamic_state)}
最近对话：${sessionContext.recentMessages.slice(-3).join('\n')}`,
  });

  // Step 3: 风险检查（优先级最高）
  if (await checkRiskSignals(message, twin)) {
    return handleCrisisProtocol(userId, message);
  }

  // Step 4: Agent 路由与执行
  const agentResults = await Promise.all(
    intent.required_agents.map(agentId =>
      executeAgent(agentId, { userId, message, twin, intent })
    )
  );

  // Step 5: 结果聚合与 A2UI 组装
  const a2uiOutput = assembleA2UI(agentResults, intent);

  // Step 6: 触发 Analyst 进行孪生更新（异步）
  queueTwinAnalysis(userId, message, agentResults);

  return {
    a2ui: a2uiOutput,
    metadata: {
      intent,
      agents_used: intent.required_agents,
      processing_time_ms: Date.now() - startTime,
    },
  };
}
```

### 2.5 双模式交互（来自 bp v1.md）

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai';

export async function POST(req: Request) {
  const { messages, mode, userId, sessionId } = await req.json();

  // 获取用户上下文
  const context = await buildUserContext(userId);

  if (mode === 'chat') {
    // Chat Mode（咨询室）：深度对话
    const result = await streamText({
      model: modelRegistry.get('glm:glm-4'),
      system: buildCoachSystemPrompt(context),
      messages,
      tools: coachAgent.tools,
      maxSteps: 5,  // 允许多轮 tool 调用
      onFinish: async ({ text, toolCalls }) => {
        // 持久化对话
        await saveConversation(sessionId, messages, text, toolCalls);
        // 触发孪生分析
        await queueTwinAnalysis(userId, text);
      },
    });

    return result.toDataStreamResponse();

  } else if (mode === 'function') {
    // Function Mode（显化控制台）：自动显化功能
    const orchestratorResult = await orchestrate(
      userId,
      messages[messages.length - 1].content,
      { recentMessages: messages.slice(-5) },
    );

    return Response.json(orchestratorResult.a2ui);
  }
}
```

---

## 3. 付费机制与商业闭环（Monetization System）

> **核心理念**（来自 bp v1.md）：虚拟货币资产与系统功能、社交玩法的深度融合

### 3.1 货币体系设计

#### 3.1.1 双币种架构

```typescript
// lib/currency/types.ts

/**
 * 货币类型
 */
type CurrencyType =
  | 'coins'       // 金币：可充值/可消耗/可转账
  | 'aura';       // 灵力：仅通过行动获得/不可充值/不可转账

/**
 * 货币来源分类
 */
type CurrencySource =
  // 金币来源
  | 'recharge'              // 充值
  | 'daily_bonus'           // 每日签到
  | 'streak_bonus'          // 连续打卡奖励
  | 'social_receive'        // 收到打赏
  | 'referral_reward'       // 邀请奖励
  | 'achievement_reward'    // 成就奖励
  | 'promotion'             // 活动赠送
  // 灵力来源
  | 'checkin_complete'      // 完成打卡
  | 'commitment_done'       // 完成承诺
  | 'plan_milestone'        // 计划里程碑
  | 'reflection_complete'   // 完成复盘
  | 'meditation_session';   // 冥想/仪式完成

/**
 * 货币消耗分类
 */
type CurrencyConsume =
  | 'expert_consult'        // 专家咨询
  | 'kb_unlock'             // 解锁知识库
  | 'deep_analysis'         // 深度分析
  | 'compatibility_report'  // 合盘报告
  | 'social_buff'           // 社交打赏
  | 'premium_content'       // 付费内容
  | 'feature_unlock';       // 功能解锁
```

#### 3.1.2 货币获取规则

```typescript
// lib/currency/earn-rules.ts

/**
 * 货币获取规则配置
 */
const EARN_RULES: EarnRule[] = [
  // ===== 金币获取 =====
  {
    id: 'daily_signin',
    currency: 'coins',
    source: 'daily_bonus',
    base_amount: 10,
    multiplier_rules: [
      { condition: 'streak >= 7', multiplier: 1.5 },
      { condition: 'streak >= 30', multiplier: 2.0 },
    ],
    cooldown: '24h',
    max_per_day: 1,
  },
  {
    id: 'streak_milestone',
    currency: 'coins',
    source: 'streak_bonus',
    triggers: [
      { streak: 7, amount: 50 },
      { streak: 21, amount: 150 },
      { streak: 30, amount: 300 },
      { streak: 100, amount: 1000 },
    ],
  },
  {
    id: 'referral_success',
    currency: 'coins',
    source: 'referral_reward',
    base_amount: 100,
    condition: 'referred_user_completed_onboarding',
  },

  // ===== 灵力获取 =====
  {
    id: 'daily_checkin',
    currency: 'aura',
    source: 'checkin_complete',
    base_amount: 5,
    multiplier_rules: [
      { condition: 'mood_improved', multiplier: 1.2 },
      { condition: 'detailed_note', multiplier: 1.3 },
    ],
  },
  {
    id: 'commitment_complete',
    currency: 'aura',
    source: 'commitment_done',
    base_amount: 10,
    multiplier_rules: [
      { condition: 'completed_early', multiplier: 1.2 },
      { condition: 'difficulty >= hard', multiplier: 1.5 },
    ],
  },
  {
    id: 'plan_day_complete',
    currency: 'aura',
    source: 'plan_milestone',
    triggers: [
      { day: 7, amount: 30 },
      { day: 14, amount: 50 },
      { day: 21, amount: 100 },
      { day: 30, amount: 200 },
    ],
  },
];

/**
 * 执行获取规则
 */
async function executeEarnRule(
  userId: string,
  ruleId: string,
  context: EarnContext
): Promise<EarnResult> {
  const rule = EARN_RULES.find(r => r.id === ruleId);
  if (!rule) throw new Error('Unknown earn rule');

  // 检查冷却期
  if (rule.cooldown && await isInCooldown(userId, ruleId)) {
    return { success: false, reason: 'cooldown' };
  }

  // 计算金额
  let amount = rule.base_amount || 0;

  // 应用乘数规则
  if (rule.multiplier_rules) {
    for (const mr of rule.multiplier_rules) {
      if (evaluateCondition(mr.condition, context)) {
        amount *= mr.multiplier;
      }
    }
  }

  // 触发式奖励
  if (rule.triggers) {
    const trigger = rule.triggers.find(t =>
      Object.entries(t).every(([k, v]) => k === 'amount' || context[k] === v)
    );
    if (trigger) {
      amount = trigger.amount;
    }
  }

  // 执行入账
  await addCurrency(userId, rule.currency, Math.floor(amount), {
    source: rule.source,
    rule_id: ruleId,
    context,
  });

  return { success: true, amount: Math.floor(amount), currency: rule.currency };
}
```

### 3.2 付费商品体系

#### 3.2.1 商品分类

```typescript
// lib/currency/products.ts

/**
 * 商品类型
 */
type ProductType =
  | 'expert_agent'        // 专家智能体
  | 'knowledge_base'      // 知识库
  | 'analysis_report'     // 分析报告
  | 'subscription'        // 订阅服务
  | 'feature_pack'        // 功能包
  | 'coin_pack';          // 金币包

/**
 * 商品定义
 */
interface Product {
  product_id: string;
  type: ProductType;
  name: string;
  description: string;

  // 定价
  price: {
    coins?: number;           // 金币价格
    aura?: number;            // 灵力价格（可选）
    rmb?: number;             // 人民币价格（直购）
  };

  // 折扣
  discount?: {
    type: 'percentage' | 'fixed';
    value: number;
    valid_until?: Date;
    condition?: string;       // 如 'new_user' / 'streak >= 30'
  };

  // 解锁内容
  unlocks: {
    type: 'expert' | 'kb' | 'feature' | 'report';
    ref_id: string;
    duration?: string;        // 如 '30d' / 'permanent'
  }[];

  // 限制
  limits?: {
    max_per_user?: number;
    total_stock?: number;
    available_from?: Date;
    available_until?: Date;
  };

  // 状态
  is_active: boolean;
  sort_order: number;
}

/**
 * 预置商品列表
 */
const PRODUCTS: Product[] = [
  // ===== 专家智能体 =====
  {
    product_id: 'expert-bazi-pro',
    type: 'expert_agent',
    name: '八字大师',
    description: '专业八字分析，含格局、大运、流年详解',
    price: { coins: 200, rmb: 19.9 },
    unlocks: [
      { type: 'expert', ref_id: 'expert-bazi', duration: 'permanent' },
      { type: 'kb', ref_id: 'bazi-advanced', duration: 'permanent' },
    ],
    is_active: true,
    sort_order: 1,
  },
  {
    product_id: 'expert-ziwei-pro',
    type: 'expert_agent',
    name: '紫微大师',
    description: '紫微斗数全面解析，命宫至疾厄宫详解',
    price: { coins: 300, rmb: 29.9 },
    unlocks: [
      { type: 'expert', ref_id: 'expert-ziwei', duration: 'permanent' },
      { type: 'kb', ref_id: 'ziwei-master', duration: 'permanent' },
    ],
    is_active: true,
    sort_order: 2,
  },

  // ===== 知识库 =====
  {
    product_id: 'kb-shadow-work',
    type: 'knowledge_base',
    name: '阴影工作坊',
    description: '荣格心理学深度内容，阴影整合练习',
    price: { coins: 150, rmb: 14.9 },
    unlocks: [
      { type: 'kb', ref_id: 'shadow-work', duration: 'permanent' },
    ],
    is_active: true,
    sort_order: 10,
  },

  // ===== 分析报告 =====
  {
    product_id: 'report-compatibility-deep',
    type: 'analysis_report',
    name: '深度合盘报告',
    description: '双人关系动力学全面分析（8000字+）',
    price: { coins: 100, rmb: 9.9 },
    unlocks: [
      { type: 'report', ref_id: 'compatibility-deep', duration: '1use' },
    ],
    is_active: true,
    sort_order: 20,
  },
  {
    product_id: 'report-year-forecast',
    type: 'analysis_report',
    name: '年度运势报告',
    description: '个人年度运势预测与行动建议',
    price: { coins: 80, rmb: 7.9 },
    unlocks: [
      { type: 'report', ref_id: 'year-forecast', duration: '1use' },
    ],
    is_active: true,
    sort_order: 21,
  },

  // ===== 订阅服务 =====
  {
    product_id: 'subscription-premium-monthly',
    type: 'subscription',
    name: '月度会员',
    description: '全专家解锁 + 全知识库 + 无限深度分析',
    price: { coins: 500, rmb: 49.9 },
    unlocks: [
      { type: 'feature', ref_id: 'premium-access', duration: '30d' },
    ],
    is_active: true,
    sort_order: 30,
  },
  {
    product_id: 'subscription-premium-yearly',
    type: 'subscription',
    name: '年度会员',
    description: '全专家解锁 + 全知识库 + 无限深度分析（省50%）',
    price: { coins: 3000, rmb: 299 },
    discount: { type: 'percentage', value: 50 },
    unlocks: [
      { type: 'feature', ref_id: 'premium-access', duration: '365d' },
    ],
    is_active: true,
    sort_order: 31,
  },

  // ===== 金币包 =====
  {
    product_id: 'coin-pack-small',
    type: 'coin_pack',
    name: '小额金币包',
    description: '100 金币',
    price: { rmb: 6 },
    unlocks: [
      { type: 'feature', ref_id: 'coins:100', duration: 'instant' },
    ],
    is_active: true,
    sort_order: 40,
  },
  {
    product_id: 'coin-pack-medium',
    type: 'coin_pack',
    name: '中额金币包',
    description: '500 金币 + 赠送 50',
    price: { rmb: 28 },
    unlocks: [
      { type: 'feature', ref_id: 'coins:550', duration: 'instant' },
    ],
    is_active: true,
    sort_order: 41,
  },
  {
    product_id: 'coin-pack-large',
    type: 'coin_pack',
    name: '大额金币包',
    description: '1000 金币 + 赠送 200',
    price: { rmb: 50 },
    unlocks: [
      { type: 'feature', ref_id: 'coins:1200', duration: 'instant' },
    ],
    is_active: true,
    sort_order: 42,
  },
];
```

#### 3.2.2 购买流程

```typescript
// lib/currency/purchase.ts

interface PurchaseRequest {
  user_id: string;
  product_id: string;
  payment_method: 'coins' | 'aura' | 'rmb';
  payment_channel?: 'wechat' | 'alipay' | 'apple_iap';
}

interface PurchaseResult {
  success: boolean;
  order_id?: string;
  unlocked?: { type: string; ref_id: string }[];
  error?: string;
}

/**
 * 执行购买
 */
async function purchaseProduct(req: PurchaseRequest): Promise<PurchaseResult> {
  const product = PRODUCTS.find(p => p.product_id === req.product_id);
  if (!product || !product.is_active) {
    return { success: false, error: 'product_not_found' };
  }

  // 检查限制
  if (product.limits) {
    if (product.limits.max_per_user) {
      const userPurchases = await countUserPurchases(req.user_id, product.product_id);
      if (userPurchases >= product.limits.max_per_user) {
        return { success: false, error: 'max_purchases_reached' };
      }
    }
  }

  // 计算价格（含折扣）
  const finalPrice = calculateFinalPrice(product, req.user_id);

  // 执行支付
  let paymentResult: PaymentResult;

  if (req.payment_method === 'coins') {
    paymentResult = await deductCurrency(req.user_id, 'coins', finalPrice.coins!, {
      category: 'spend',
      reason: 'purchase',
      ref_type: 'product',
      ref_id: product.product_id,
    });
  } else if (req.payment_method === 'aura') {
    paymentResult = await deductCurrency(req.user_id, 'aura', finalPrice.aura!, {
      category: 'spend',
      reason: 'purchase',
      ref_type: 'product',
      ref_id: product.product_id,
    });
  } else {
    // RMB 支付 - 创建第三方支付订单
    paymentResult = await createExternalPayment(req, finalPrice.rmb!);
    if (!paymentResult.success) {
      return { success: false, error: 'payment_failed' };
    }
  }

  if (!paymentResult.success) {
    return { success: false, error: 'insufficient_balance' };
  }

  // 创建订单
  const order = await createOrder({
    user_id: req.user_id,
    product_id: product.product_id,
    payment_method: req.payment_method,
    amount: finalPrice[req.payment_method] || 0,
    status: 'completed',
  });

  // 执行解锁
  const unlocked: { type: string; ref_id: string }[] = [];
  for (const unlock of product.unlocks) {
    await executeUnlock(req.user_id, unlock);
    unlocked.push({ type: unlock.type, ref_id: unlock.ref_id });
  }

  return {
    success: true,
    order_id: order.order_id,
    unlocked,
  };
}
```

### 3.3 消耗场景设计

#### 3.3.1 功能消耗定价

```typescript
// lib/currency/consume-rules.ts

/**
 * 功能消耗规则
 */
const CONSUME_RULES: ConsumeRule[] = [
  // ===== 专家咨询 =====
  {
    feature_id: 'expert_consult',
    name: '专家咨询',
    pricing: {
      free_quota: 3,          // 每日免费次数
      quota_period: '24h',
      per_use: { coins: 5 },  // 超额后每次消耗
    },
    premium_override: 'unlimited',  // 会员无限
  },

  // ===== 深度分析 =====
  {
    feature_id: 'deep_analysis_bazi',
    name: '八字深度分析',
    pricing: {
      free_quota: 1,
      quota_period: '7d',
      per_use: { coins: 20 },
    },
    premium_override: 'unlimited',
  },
  {
    feature_id: 'deep_analysis_zodiac',
    name: '星座深度分析',
    pricing: {
      free_quota: 1,
      quota_period: '7d',
      per_use: { coins: 15 },
    },
    premium_override: 'unlimited',
  },

  // ===== 合盘分析 =====
  {
    feature_id: 'compatibility_quick',
    name: '快速合盘',
    pricing: {
      free_quota: 5,
      quota_period: '24h',
      per_use: { coins: 3 },
    },
  },
  {
    feature_id: 'compatibility_deep',
    name: '深度合盘',
    pricing: {
      free_quota: 0,
      per_use: { coins: 30 },
    },
    premium_override: { per_use: { coins: 10 } },
  },

  // ===== 社交功能 =====
  {
    feature_id: 'energy_buff',
    name: '能量打赏',
    pricing: {
      min_amount: 1,
      max_amount: 1000,
      transfer_fee_rate: 0,   // 无手续费
    },
  },
  {
    feature_id: 'luck_chain_create',
    name: '创建好运接龙',
    pricing: {
      per_use: { coins: 10 },
      pool_contribution: true,  // 投入奖池
    },
  },

  // ===== 内容生成 =====
  {
    feature_id: 'share_card_premium',
    name: '高级分享卡',
    pricing: {
      free_quota: 3,
      quota_period: '24h',
      per_use: { coins: 2 },
    },
    premium_override: 'unlimited',
  },
];

/**
 * 检查并消耗配额
 */
async function checkAndConsume(
  userId: string,
  featureId: string
): Promise<ConsumeResult> {
  const rule = CONSUME_RULES.find(r => r.feature_id === featureId);
  if (!rule) return { allowed: true, consumed: false };

  // 检查会员状态
  const isPremium = await checkPremiumStatus(userId);
  if (isPremium && rule.premium_override === 'unlimited') {
    return { allowed: true, consumed: false, reason: 'premium' };
  }

  // 检查免费配额
  const usedQuota = await getUsedQuota(userId, featureId, rule.pricing.quota_period);
  if (usedQuota < (rule.pricing.free_quota || 0)) {
    await incrementQuota(userId, featureId);
    return { allowed: true, consumed: false, reason: 'free_quota' };
  }

  // 需要付费
  const price = isPremium && rule.premium_override?.per_use
    ? rule.premium_override.per_use
    : rule.pricing.per_use;

  if (!price) {
    return { allowed: false, reason: 'no_paid_option' };
  }

  // 尝试扣费
  const deducted = await deductCurrency(userId, 'coins', price.coins, {
    category: 'spend',
    reason: 'feature_use',
    ref_type: 'feature',
    ref_id: featureId,
  });

  if (!deducted) {
    return {
      allowed: false,
      reason: 'insufficient_balance',
      required: price.coins,
    };
  }

  return { allowed: true, consumed: true, amount: price.coins };
}
```

### 3.4 会员体系

```typescript
// lib/currency/membership.ts

/**
 * 会员等级定义
 */
interface MembershipTier {
  tier_id: string;
  name: string;
  level: number;

  // 获取条件（满足其一）
  requirements: {
    subscription?: string[];      // 订阅商品 ID
    total_spend_rmb?: number;     // 累计消费
    aura_total?: number;          // 累计灵力
  };

  // 权益
  benefits: {
    daily_coins_bonus: number;    // 每日签到加成
    expert_discount: number;      // 专家咨询折扣（0-1）
    kb_access: 'all' | string[];  // 知识库访问
    feature_quotas: Record<string, number | 'unlimited'>;
    exclusive_content: boolean;
    priority_support: boolean;
    badge: string;                // 徽章 ID
  };
}

const MEMBERSHIP_TIERS: MembershipTier[] = [
  {
    tier_id: 'free',
    name: '探索者',
    level: 0,
    requirements: {},
    benefits: {
      daily_coins_bonus: 10,
      expert_discount: 0,
      kb_access: ['psychology-basics', 'bazi-basics'],
      feature_quotas: {
        expert_consult: 3,
        deep_analysis: 1,
      },
      exclusive_content: false,
      priority_support: false,
      badge: 'badge-explorer',
    },
  },
  {
    tier_id: 'basic',
    name: '修行者',
    level: 1,
    requirements: {
      aura_total: 500,
      total_spend_rmb: 50,
    },
    benefits: {
      daily_coins_bonus: 15,
      expert_discount: 0.1,
      kb_access: ['psychology-basics', 'bazi-basics', 'zodiac-basics'],
      feature_quotas: {
        expert_consult: 10,
        deep_analysis: 3,
      },
      exclusive_content: false,
      priority_support: false,
      badge: 'badge-practitioner',
    },
  },
  {
    tier_id: 'premium',
    name: '觉醒者',
    level: 2,
    requirements: {
      subscription: ['subscription-premium-monthly', 'subscription-premium-yearly'],
      total_spend_rmb: 200,
      aura_total: 2000,
    },
    benefits: {
      daily_coins_bonus: 30,
      expert_discount: 0.3,
      kb_access: 'all',
      feature_quotas: {
        expert_consult: 'unlimited',
        deep_analysis: 'unlimited',
        compatibility_deep: 10,
      },
      exclusive_content: true,
      priority_support: true,
      badge: 'badge-awakened',
    },
  },
  {
    tier_id: 'elite',
    name: '开悟者',
    level: 3,
    requirements: {
      total_spend_rmb: 1000,
      aura_total: 10000,
    },
    benefits: {
      daily_coins_bonus: 50,
      expert_discount: 0.5,
      kb_access: 'all',
      feature_quotas: {
        expert_consult: 'unlimited',
        deep_analysis: 'unlimited',
        compatibility_deep: 'unlimited',
      },
      exclusive_content: true,
      priority_support: true,
      badge: 'badge-enlightened',
    },
  },
];

/**
 * 计算用户会员等级
 */
async function calculateMembershipTier(userId: string): Promise<MembershipTier> {
  const userStats = await getUserStats(userId);
  const activeSubscriptions = await getActiveSubscriptions(userId);

  // 从高到低检查
  for (const tier of [...MEMBERSHIP_TIERS].reverse()) {
    const req = tier.requirements;

    // 检查订阅
    if (req.subscription?.some(s => activeSubscriptions.includes(s))) {
      return tier;
    }

    // 检查消费
    if (req.total_spend_rmb && userStats.total_spend_rmb >= req.total_spend_rmb) {
      return tier;
    }

    // 检查灵力
    if (req.aura_total && userStats.aura_total >= req.aura_total) {
      return tier;
    }
  }

  return MEMBERSHIP_TIERS[0]; // 默认免费等级
}
```

### 3.5 数据库表结构（货币与商业相关）

```sql
-- 用户货币余额（实时）
CREATE TABLE fortune_user_balance (
    user_id BIGINT PRIMARY KEY REFERENCES fortune_user(user_id),
    coins_balance INTEGER NOT NULL DEFAULT 0,
    aura_balance INTEGER NOT NULL DEFAULT 0,
    coins_total_earned INTEGER NOT NULL DEFAULT 0,
    coins_total_spent INTEGER NOT NULL DEFAULT 0,
    aura_total_earned INTEGER NOT NULL DEFAULT 0,
    aura_total_spent INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 货币流水账本
CREATE TABLE fortune_currency_ledger (
    entry_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    currency_type TEXT NOT NULL CHECK (currency_type IN ('coins', 'aura')),
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    category TEXT NOT NULL,       -- earn/spend/transfer_in/transfer_out
    reason TEXT NOT NULL,
    ref_type TEXT,
    ref_id TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ledger_user_time ON fortune_currency_ledger(user_id, created_at DESC);
CREATE INDEX idx_ledger_category ON fortune_currency_ledger(category, created_at DESC);

-- 商品表
CREATE TABLE fortune_product (
    product_id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price_coins INTEGER,
    price_aura INTEGER,
    price_rmb NUMERIC(10, 2),
    discount_config JSONB,
    unlocks JSONB NOT NULL DEFAULT '[]',
    limits JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 订单表
CREATE TABLE fortune_order (
    order_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    product_id TEXT NOT NULL REFERENCES fortune_product(product_id),
    payment_method TEXT NOT NULL,
    payment_channel TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',  -- pending/completed/refunded/cancelled
    external_order_id TEXT,
    unlocks_executed JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ
);

CREATE INDEX idx_order_user ON fortune_order(user_id, created_at DESC);
CREATE INDEX idx_order_status ON fortune_order(status, created_at DESC);

-- 用户解锁记录
CREATE TABLE fortune_user_unlock (
    unlock_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    unlock_type TEXT NOT NULL,    -- expert/kb/feature/report
    ref_id TEXT NOT NULL,
    source TEXT NOT NULL,         -- purchase/gift/promotion/achievement
    order_id TEXT REFERENCES fortune_order(order_id),
    expires_at TIMESTAMPTZ,       -- NULL = 永久
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, unlock_type, ref_id)
);

CREATE INDEX idx_unlock_user ON fortune_user_unlock(user_id, unlock_type);
CREATE INDEX idx_unlock_expires ON fortune_user_unlock(expires_at) WHERE expires_at IS NOT NULL;

-- 用户知识库配置
CREATE TABLE fortune_user_kb (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    kb_id TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unlock_source TEXT NOT NULL DEFAULT 'purchase',
    expires_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, kb_id)
);

-- 用户 Agent-KB 绑定
CREATE TABLE fortune_user_agent_kb (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    agent_id TEXT NOT NULL,
    kb_ids TEXT[] NOT NULL DEFAULT '{}',
    custom_weights JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, agent_id)
);

-- 功能使用配额
CREATE TABLE fortune_feature_quota (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    feature_id TEXT NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    used_count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, feature_id, period_start)
);

CREATE INDEX idx_quota_user_feature ON fortune_feature_quota(user_id, feature_id, period_start DESC);

-- 用户会员状态
CREATE TABLE fortune_user_membership (
    user_id BIGINT PRIMARY KEY REFERENCES fortune_user(user_id),
    tier_id TEXT NOT NULL DEFAULT 'free',
    tier_source TEXT NOT NULL DEFAULT 'default',  -- subscription/spend/aura/manual
    subscription_expires_at TIMESTAMPTZ,
    benefits_snapshot JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 3.6 商业闭环图示

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            商业闭环生态系统                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         货币获取（输入）                              │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │    │
│  │  │  RMB     │  │ 每日签到 │  │ 完成任务 │  │ 社交奖励 │            │    │
│  │  │  充值    │  │  +金币   │  │  +灵力   │  │ +金币    │            │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │    │
│  │       │             │             │             │                   │    │
│  └───────┼─────────────┼─────────────┼─────────────┼───────────────────┘    │
│          │             │             │             │                        │
│          ▼             ▼             ▼             ▼                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         用户钱包                                     │    │
│  │              ┌──────────────┐    ┌──────────────┐                   │    │
│  │              │   金币余额   │    │   灵力余额   │                   │    │
│  │              │   (可转账)   │    │  (不可转账)  │                   │    │
│  │              └──────────────┘    └──────────────┘                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│          │             │             │             │                        │
│          ▼             ▼             ▼             ▼                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         货币消耗（输出）                              │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │    │
│  │  │  解锁    │  │  专家    │  │  深度    │  │  社交    │            │    │
│  │  │  专家/KB │  │  咨询    │  │  报告    │  │  打赏    │            │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │    │
│  │       │             │             │             │                   │    │
│  └───────┼─────────────┼─────────────┼─────────────┼───────────────────┘    │
│          │             │             │             │                        │
│          ▼             ▼             ▼             ▼                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         价值交付                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │    │
│  │  │ 更深洞察 │  │ 专业指导 │  │ 关系分析 │  │ 社交连接 │            │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                              │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        用户成长 & 留存                               │    │
│  │                              │                                       │    │
│  │              ┌───────────────┼───────────────┐                      │    │
│  │              ▼               ▼               ▼                      │    │
│  │      更多行动完成 ──→ 更多灵力获得 ──→ 更高会员等级               │    │
│  │              │               │               │                      │    │
│  │              └───────────────┴───────────────┘                      │    │
│  │                              │                                       │    │
│  │                              ▼                                       │    │
│  │                        继续消费/推荐好友                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. 数据层设计（PostgreSQL SSOT）

### 3.1 核心表结构增量（在现有 MVP 基础上）

#### 3.1.1 精神数字孪生表

```sql
-- 孪生主表
CREATE TABLE fortune_digital_twin (
    twin_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES fortune_user(user_id),

    -- L1 元数据层
    metadata_astrology JSONB NOT NULL DEFAULT '{}',
    metadata_psychology JSONB NOT NULL DEFAULT '{}',
    metadata_memory JSONB NOT NULL DEFAULT '{}',

    -- L2 动态状态层
    dynamic_astro JSONB NOT NULL DEFAULT '{}',
    dynamic_bio JSONB NOT NULL DEFAULT '{}',
    dynamic_social JSONB NOT NULL DEFAULT '{}',
    dynamic_emotional JSONB NOT NULL DEFAULT '{}',

    -- L3 聚合指标
    aura_points INTEGER NOT NULL DEFAULT 0,
    overall_wellbeing NUMERIC(5,2) NOT NULL DEFAULT 50.00,
    growth_streak INTEGER NOT NULL DEFAULT 0,
    dimension_scores JSONB NOT NULL DEFAULT '{"energy":50,"clarity":50,"connection":50,"growth":50,"balance":50}',

    -- 元信息
    compute_version TEXT NOT NULL DEFAULT 'v1.0',
    last_full_refresh TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_twin_user ON fortune_digital_twin(user_id);

-- 孪生更新日志（事件溯源）
CREATE TABLE fortune_twin_update_log (
    log_id BIGSERIAL PRIMARY KEY,
    twin_id BIGINT NOT NULL REFERENCES fortune_digital_twin(twin_id),
    trigger_type TEXT NOT NULL,  -- daily_refresh/checkin_completed/chat_insight/...
    layer TEXT NOT NULL,         -- L1/L2/L3
    path TEXT NOT NULL,          -- e.g., 'dynamic_emotional.current_mood'
    old_value JSONB,
    new_value JSONB NOT NULL,
    confidence NUMERIC(3,2) NOT NULL,
    source TEXT NOT NULL,        -- agent_id/manual/external
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_twin_log_twin ON fortune_twin_update_log(twin_id, created_at DESC);
```

#### 3.1.2 社交关系表

```sql
-- 好友关系边（邻接表）
CREATE TABLE fortune_social_edge (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    peer_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    relationship_type TEXT NOT NULL DEFAULT 'friend',  -- friend/family/romantic/work
    status TEXT NOT NULL DEFAULT 'pending',  -- pending/accepted/blocked
    compatibility_score NUMERIC(5,2),  -- 合盘分数缓存
    compatibility_data JSONB,          -- 合盘详情缓存
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, peer_user_id)
);

CREATE INDEX idx_social_peer ON fortune_social_edge(peer_user_id, status);

-- 能量打赏记录
CREATE TABLE fortune_energy_buff (
    buff_id BIGSERIAL PRIMARY KEY,
    from_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    to_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    buff_type TEXT NOT NULL,  -- energy/luck/calm/focus
    amount INTEGER NOT NULL,
    message TEXT,
    source TEXT NOT NULL DEFAULT 'app',  -- app/share_card/qr_scan
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_buff_to ON fortune_energy_buff(to_user_id, created_at DESC);
CREATE INDEX idx_buff_from ON fortune_energy_buff(from_user_id, created_at DESC);
```

#### 3.1.3 虚拟货币账本

```sql
-- 货币账本（双向记账）
CREATE TABLE fortune_currency_ledger (
    entry_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    amount INTEGER NOT NULL,  -- 正=收入，负=支出
    balance_after INTEGER NOT NULL,  -- 交易后余额

    -- 来源/去向分类
    category TEXT NOT NULL,  -- earn/spend/transfer_in/transfer_out
    reason TEXT NOT NULL,    -- task_complete/daily_checkin/feature_use/social_buff/...

    -- 关联实体
    ref_type TEXT,           -- commitment/plan/social/feature/...
    ref_id TEXT,

    -- 元信息
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ledger_user ON fortune_currency_ledger(user_id, created_at DESC);

-- 用户货币余额视图（或物化视图）
CREATE VIEW fortune_user_balance AS
SELECT
    user_id,
    COALESCE(SUM(amount), 0) AS total_balance,
    COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) AS total_earned,
    COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) AS total_spent
FROM fortune_currency_ledger
GROUP BY user_id;
```

#### 3.1.4 专家知识库配置

```sql
-- 可插拔专家配置
CREATE TABLE fortune_expert_config (
    expert_id TEXT PRIMARY KEY,
    domain TEXT NOT NULL,  -- bazi/ziwei/zodiac/mbti/perma
    name TEXT NOT NULL,
    description TEXT,

    -- 模型配置
    model_id TEXT NOT NULL DEFAULT 'glm:glm-4',
    system_prompt TEXT NOT NULL,
    temperature NUMERIC(3,2) NOT NULL DEFAULT 0.7,
    max_tokens INTEGER NOT NULL DEFAULT 1000,

    -- 知识库配置
    kb_collection TEXT,    -- pgvector collection 名
    kb_filter JSONB,       -- 检索过滤条件

    -- 可用性
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,  -- 是否付费专属

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 用户已解锁专家
CREATE TABLE fortune_user_expert (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    expert_id TEXT NOT NULL REFERENCES fortune_expert_config(expert_id),
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unlock_source TEXT NOT NULL DEFAULT 'purchase',  -- purchase/gift/promotion
    PRIMARY KEY (user_id, expert_id)
);
```

### 3.2 pgvector 知识库扩展

```sql
-- 启用 vector 扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 统一知识库 chunk 表
CREATE TABLE fortune_kb_chunk (
    chunk_id BIGSERIAL PRIMARY KEY,
    collection TEXT NOT NULL,  -- bazi/psychology/astrology/practice
    source_doc TEXT NOT NULL,
    title TEXT,
    content TEXT NOT NULL,

    -- 向量嵌入
    embedding vector(1536),    -- OpenAI ada-002 / 其他模型维度

    -- 元数据
    meta JSONB NOT NULL DEFAULT '{}',

    -- 全文搜索
    content_tsv TSVECTOR GENERATED ALWAYS AS (to_tsvector('simple', content)) STORED,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kb_collection ON fortune_kb_chunk(collection);
CREATE INDEX idx_kb_tsv ON fortune_kb_chunk USING GIN(content_tsv);
CREATE INDEX idx_kb_embedding ON fortune_kb_chunk USING ivfflat (embedding vector_cosine_ops);
```

---

## 4. API 路由设计（Next.js App Router）

### 4.1 路由结构

```
app/
├── api/
│   ├── auth/
│   │   ├── register/route.ts
│   │   ├── login/route.ts
│   │   └── logout/route.ts
│   │
│   ├── chat/
│   │   └── route.ts              # 主对话端点（流式）
│   │
│   ├── twin/
│   │   ├── route.ts              # GET: 获取孪生数据
│   │   ├── refresh/route.ts      # POST: 触发孪生刷新
│   │   └── history/route.ts      # GET: 孪生更新历史
│   │
│   ├── commitment/
│   │   ├── route.ts              # GET: 列表, POST: 创建
│   │   └── [id]/
│   │       └── route.ts          # PATCH: 更新状态
│   │
│   ├── social/
│   │   ├── friends/route.ts      # 好友列表
│   │   ├── compatibility/route.ts # 合盘分析
│   │   ├── buff/route.ts         # 能量打赏
│   │   └── share/route.ts        # 生成分享卡
│   │
│   ├── plan/
│   │   ├── route.ts              # 计划列表
│   │   ├── [planId]/
│   │   │   └── route.ts          # 计划详情
│   │   └── enrollment/route.ts   # 参与管理
│   │
│   ├── currency/
│   │   ├── balance/route.ts      # 余额查询
│   │   └── history/route.ts      # 交易历史
│   │
│   ├── expert/
│   │   ├── route.ts              # 可用专家列表
│   │   └── [domain]/
│   │       └── route.ts          # 专家咨询
│   │
│   └── webhook/
│       ├── health/route.ts       # 健康数据同步（Apple/Fitbit）
│       └── notification/route.ts # 推送回调
│
├── (app)/                        # 应用页面（需认证）
│   ├── layout.tsx
│   ├── dashboard/page.tsx        # 主面板/数字孪生展示
│   ├── chat/page.tsx             # 对话界面
│   ├── plan/page.tsx             # 成长计划
│   ├── social/page.tsx           # 社交中心
│   └── profile/page.tsx          # 个人设置
│
└── (auth)/                       # 认证页面
    ├── login/page.tsx
    └── register/page.tsx
```

### 4.2 核心 API 实现示例

#### 4.2.1 对话 API（流式）

```typescript
// app/api/chat/route.ts
import { streamText, convertToCoreMessages } from 'ai';
import { modelRegistry, coachAgent } from '@/lib/ai/agents';
import { buildUserContext, saveConversation, queueTwinAnalysis } from '@/lib/services';
import { auth } from '@/lib/auth';

export async function POST(req: Request) {
  // 认证检查
  const session = await auth();
  if (!session?.user?.id) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { messages, sessionId, mode = 'chat' } = await req.json();
  const userId = session.user.id;

  // 构建用户上下文（孪生数据 + 偏好）
  const context = await buildUserContext(userId);

  // 准备系统提示词
  const systemPrompt = interpolatePrompt(coachAgent.systemPrompt, {
    user_context: JSON.stringify(context.summary),
    facts: JSON.stringify(context.twin.metadata_astrology),
    current_state: JSON.stringify(context.twin.dynamic_emotional),
    aura_points: context.twin.aura_points,
  });

  // 流式生成
  const result = await streamText({
    model: modelRegistry.get(coachAgent.model),
    system: systemPrompt,
    messages: convertToCoreMessages(messages),
    tools: coachAgent.tools,
    maxSteps: 5,

    // 完成回调
    onFinish: async ({ text, toolCalls, usage }) => {
      // 1. 持久化对话
      await saveConversation({
        sessionId,
        userId,
        userMessage: messages[messages.length - 1].content,
        assistantMessage: text,
        toolCalls,
        usage,
      });

      // 2. 异步触发孪生分析
      await queueTwinAnalysis(userId, text, toolCalls);

      // 3. 记录 LLM 使用成本
      await logLLMUsage(userId, usage);
    },
  });

  return result.toDataStreamResponse();
}
```

#### 4.2.2 孪生数据 API

```typescript
// app/api/twin/route.ts
import { auth } from '@/lib/auth';
import { getTwinData, getTwinMetrics } from '@/lib/services/twin';

export async function GET(req: Request) {
  const session = await auth();
  if (!session?.user?.id) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const layer = searchParams.get('layer') as 'L1' | 'L2' | 'L3' | 'all';

  const twin = await getTwinData(session.user.id, layer || 'all');

  return Response.json({
    twin,
    metrics: await getTwinMetrics(session.user.id),
    last_updated: twin.updated_at,
  });
}
```

#### 4.2.3 社交合盘 API

```typescript
// app/api/social/compatibility/route.ts
import { auth } from '@/lib/auth';
import { generateCompatibility, socialAgent } from '@/lib/ai/agents/social-agent';

export async function POST(req: Request) {
  const session = await auth();
  if (!session?.user?.id) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { peerId, relationshipType = 'friendship', depth = 'standard' } = await req.json();

  // 检查好友关系
  const relationship = await checkFriendship(session.user.id, peerId);
  if (!relationship || relationship.status !== 'accepted') {
    return new Response('Not friends', { status: 403 });
  }

  // 生成合盘分析（使用 Social Agent）
  const compatibility = await generateCompatibility({
    userIds: [session.user.id, peerId],
    relationshipType,
    depth,
  });

  // 缓存结果
  await cacheCompatibility(session.user.id, peerId, compatibility);

  return Response.json(compatibility);
}
```

---

## 5. A2UI 输出协议（扩展版）

### 5.1 组件类型定义

```typescript
// types/a2ui.ts
type A2UIComponentType =
  | 'markdown_text'      // 文本内容
  | 'action_buttons'     // 行动按钮
  | 'commitment_card'    // 承诺卡片
  | 'twin_snapshot'      // 孪生快照展示
  | 'aura_radar'         // 能量雷达图
  | 'timeline'           // 时间线
  | 'tarot_card'         // 塔罗卡
  | 'ritual_guide'       // 仪式引导
  | 'compatibility'      // 合盘结果
  | 'share_card'         // 可分享卡片
  | 'buff_animation'     // Buff 动画
  | 'progress_ring';     // 进度环

interface A2UIComponent {
  type: A2UIComponentType;
  id: string;
  title?: string;
  data: any;
  style?: {
    theme?: 'light' | 'dark' | 'cosmic';
    accent_color?: string;
  };
}

interface A2UIOutput {
  meta: {
    summary: string;
    intent?: string;
    agents_used?: string[];
    processing_time_ms?: number;
  };
  ui_components: A2UIComponent[];
}
```

### 5.2 组件示例

```typescript
// 承诺卡片
const commitmentCard: A2UIComponent = {
  type: 'commitment_card',
  id: 'commit-001',
  title: '今日最小行动',
  data: {
    task_id: 'uuid',
    title: '3分钟能量重启',
    description: '深呼吸 + 正念扫描',
    duration_minutes: 3,
    aura_reward: 10,
    status: 'suggested',
    actions: [
      { label: '立即开始', action_type: 'start_task' },
      { label: '加入日程', action_type: 'schedule_task' },
      { label: '换一个', action_type: 'refresh' },
    ],
  },
};

// 能量雷达图
const auraRadar: A2UIComponent = {
  type: 'aura_radar',
  id: 'radar-001',
  title: '当前状态',
  data: {
    dimensions: [
      { name: '能量', value: 72, max: 100 },
      { name: '清晰度', value: 85, max: 100 },
      { name: '连接', value: 60, max: 100 },
      { name: '成长', value: 78, max: 100 },
      { name: '平衡', value: 65, max: 100 },
    ],
    trend: 'rising',      // rising/stable/declining
    vs_yesterday: +5,
  },
  style: {
    theme: 'cosmic',
    accent_color: '#6366f1',
  },
};

// Buff 动画
const buffAnimation: A2UIComponent = {
  type: 'buff_animation',
  id: 'buff-001',
  data: {
    from_name: '小明',
    buff_type: 'energy',
    amount: 50,
    message: '加油！',
    animation: 'sparkle',  // sparkle/wave/glow
  },
};
```

---

## 6. 主动计算与推送（JITAI 算法）

### 6.1 Just-In-Time Adaptive Interventions

```typescript
// lib/jitai/engine.ts
interface JITAITrigger {
  id: string;
  name: string;
  conditions: JITAICondition[];
  intervention: JITAIIntervention;
  cooldown_hours: number;
  priority: number;
}

interface JITAICondition {
  type: 'time' | 'state' | 'behavior' | 'context';
  operator: 'eq' | 'gt' | 'lt' | 'in' | 'not_in';
  field: string;
  value: any;
}

interface JITAIIntervention {
  type: 'push_notification' | 'in_app_card' | 'chat_proactive' | 'email';
  template: string;
  content_generator?: string;  // Agent ID for dynamic content
  cta?: { label: string; action: string };
}

// 预定义触发器
const jitaiTriggers: JITAITrigger[] = [
  {
    id: 'morning_checkin',
    name: '晨间打卡提醒',
    conditions: [
      { type: 'time', operator: 'in', field: 'hour', value: [7, 8, 9] },
      { type: 'behavior', operator: 'eq', field: 'checked_in_today', value: false },
    ],
    intervention: {
      type: 'push_notification',
      template: 'morning_checkin',
      cta: { label: '打卡', action: 'open_checkin' },
    },
    cooldown_hours: 24,
    priority: 80,
  },

  {
    id: 'low_energy_intervention',
    name: '低能量干预',
    conditions: [
      { type: 'state', operator: 'lt', field: 'twin.dimension_scores.energy', value: 30 },
      { type: 'state', operator: 'gt', field: 'twin.dynamic_emotional.mood_intensity', value: 6 },
    ],
    intervention: {
      type: 'in_app_card',
      template: 'energy_boost',
      content_generator: 'coach',
    },
    cooldown_hours: 6,
    priority: 90,
  },

  {
    id: 'retrograde_warning',
    name: '水逆/逆行提醒',
    conditions: [
      { type: 'context', operator: 'eq', field: 'astro.mercury_retrograde', value: true },
      { type: 'behavior', operator: 'eq', field: 'notified_retrograde', value: false },
    ],
    intervention: {
      type: 'chat_proactive',
      template: 'retrograde_guidance',
      content_generator: 'expert-zodiac',
    },
    cooldown_hours: 168,  // 7 天
    priority: 70,
  },

  {
    id: 'streak_celebration',
    name: '连续打卡庆祝',
    conditions: [
      { type: 'behavior', operator: 'in', field: 'growth_streak', value: [7, 21, 30, 100] },
    ],
    intervention: {
      type: 'in_app_card',
      template: 'streak_celebration',
      cta: { label: '分享成就', action: 'share_achievement' },
    },
    cooldown_hours: 24,
    priority: 85,
  },
];

// JITAI 引擎
export async function evaluateJITAI(userId: string): Promise<JITAIIntervention[]> {
  const twin = await getTwinData(userId, 'all');
  const behavior = await getUserBehavior(userId);
  const context = await getAstroContext();
  const currentHour = new Date().getHours();

  const triggeredInterventions: JITAIIntervention[] = [];

  for (const trigger of jitaiTriggers) {
    // 检查冷却期
    if (await isInCooldown(userId, trigger.id)) continue;

    // 评估条件
    const allConditionsMet = trigger.conditions.every(cond =>
      evaluateCondition(cond, { twin, behavior, context, currentHour })
    );

    if (allConditionsMet) {
      triggeredInterventions.push({
        ...trigger.intervention,
        triggerId: trigger.id,
        priority: trigger.priority,
      });
    }
  }

  // 按优先级排序，返回最高优先级的干预
  return triggeredInterventions.sort((a, b) => b.priority - a.priority);
}
```

### 6.2 推送调度器（Vercel Cron）

```typescript
// app/api/cron/jitai/route.ts
import { evaluateJITAI, executeIntervention } from '@/lib/jitai';

export const dynamic = 'force-dynamic';
export const maxDuration = 60;

// Vercel Cron: 每 15 分钟执行
export async function GET(req: Request) {
  // 验证 Cron Secret
  const authHeader = req.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  // 获取活跃用户（最近 7 天有活动）
  const activeUsers = await getActiveUsers(7);

  let interventionCount = 0;

  for (const userId of activeUsers) {
    const interventions = await evaluateJITAI(userId);

    if (interventions.length > 0) {
      // 执行最高优先级的干预
      await executeIntervention(userId, interventions[0]);
      interventionCount++;
    }
  }

  return Response.json({
    evaluated: activeUsers.length,
    intervened: interventionCount,
    timestamp: new Date().toISOString(),
  });
}
```

---

## 7. 增长与病毒传播机制

### 7.1 分享卡系统

```typescript
// lib/share/generator.ts
interface ShareCardConfig {
  type: 'cosmic_roast' | 'bento_grid' | 'manifestation_diary' | 'compatibility' | 'streak';
  userId: string;
  customData?: any;
}

export async function generateShareCard(config: ShareCardConfig): Promise<ShareCardResult> {
  const twin = await getTwinData(config.userId, 'all');
  const template = await getShareTemplate(config.type);

  // 生成个性化内容（使用 Agent）
  let content: any;

  switch (config.type) {
    case 'cosmic_roast':
      // 毒舌报告 - 使用 Social Agent 生成
      content = await generateRoast(twin, config.customData?.targetUserId);
      break;

    case 'bento_grid':
      // 愿景板 - 聚合孪生数据
      content = {
        aura: twin.aura_points,
        dimensions: twin.dimension_scores,
        streak: twin.growth_streak,
        recent_wins: await getRecentWins(config.userId, 3),
      };
      break;

    case 'manifestation_diary':
      // 显化日记 - 最近的承诺完成记录
      content = await getManifestationContent(config.userId);
      break;
  }

  // 返回渲染数据（前端使用 html-to-image 导出）
  return {
    template_id: template.id,
    template_version: template.version,
    content,
    share_url: `${process.env.NEXT_PUBLIC_BASE_URL}/s/${encodeShareData(config)}`,
    qr_data: generateQRData(config),
  };
}
```

### 7.2 社交互动机制

```typescript
// lib/social/interactions.ts

// 能量打赏
export async function sendEnergyBuff(
  fromUserId: string,
  toUserId: string,
  buffType: BuffType,
  amount: number,
  message?: string,
  source: 'app' | 'share_card' | 'qr_scan' = 'app'
): Promise<BuffResult> {
  // 1. 扣除发送者货币
  await deductCurrency(fromUserId, amount, {
    category: 'transfer_out',
    reason: 'send_buff',
    ref_type: 'buff',
  });

  // 2. 增加接收者货币
  await addCurrency(toUserId, amount, {
    category: 'transfer_in',
    reason: 'receive_buff',
    ref_type: 'buff',
  });

  // 3. 记录 Buff
  const buff = await db.insert(fortune_energy_buff, {
    from_user_id: fromUserId,
    to_user_id: toUserId,
    buff_type: buffType,
    amount,
    message,
    source,
  });

  // 4. 更新接收者孪生状态
  await updateTwinDimension(toUserId, 'energy', amount * 0.1);  // Buff 转化为能量值

  // 5. 发送通知
  await sendNotification(toUserId, {
    type: 'buff_received',
    title: '收到能量！',
    body: `${await getUserName(fromUserId)} 给你充能 +${amount}`,
    data: { buff_id: buff.buff_id },
  });

  return buff;
}

// 好运接龙
export async function joinLuckChain(
  chainId: string,
  userId: string,
  contribution?: string  // 如：拍一张天空照片
): Promise<ChainResult> {
  const chain = await getChain(chainId);

  // 1. 加入接龙
  const position = await db.insert(fortune_luck_chain_participant, {
    chain_id: chainId,
    user_id: userId,
    position: chain.participant_count + 1,
    contribution,
  });

  // 2. 计算链条 Buff（参与人数越多，奖励越高）
  const chainMultiplier = Math.log2(chain.participant_count + 2);
  const reward = Math.floor(chain.base_reward * chainMultiplier);

  // 3. 给所有参与者发放奖励
  const participants = await getChainParticipants(chainId);
  for (const p of participants) {
    await addCurrency(p.user_id, reward, {
      category: 'earn',
      reason: 'luck_chain',
      ref_type: 'chain',
      ref_id: chainId,
    });
  }

  // 4. 更新接龙状态
  await updateChainStats(chainId);

  return {
    position: position.position,
    reward,
    total_participants: chain.participant_count + 1,
    chain_strength: chainMultiplier,
  };
}
```

### 7.3 增长飞轮数据追踪

```sql
-- 增长指标表
CREATE TABLE fortune_growth_metrics (
    metric_id BIGSERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,

    -- 用户指标
    new_users INTEGER NOT NULL DEFAULT 0,
    active_users_daily INTEGER NOT NULL DEFAULT 0,
    active_users_weekly INTEGER NOT NULL DEFAULT 0,
    active_users_monthly INTEGER NOT NULL DEFAULT 0,

    -- 参与指标
    total_checkins INTEGER NOT NULL DEFAULT 0,
    total_commitments_created INTEGER NOT NULL DEFAULT 0,
    total_commitments_completed INTEGER NOT NULL DEFAULT 0,

    -- 社交指标
    total_buffs_sent INTEGER NOT NULL DEFAULT 0,
    total_shares INTEGER NOT NULL DEFAULT 0,
    viral_coefficient NUMERIC(5,2) NOT NULL DEFAULT 0,  -- K因子

    -- 留存指标
    retention_d1 NUMERIC(5,2),
    retention_d7 NUMERIC(5,2),
    retention_d30 NUMERIC(5,2),

    -- 货币指标
    total_currency_earned INTEGER NOT NULL DEFAULT 0,
    total_currency_spent INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (metric_date)
);
```

---

## 8. 安全、合规与伦理

### 8.1 AI 安全围栏

```typescript
// lib/safety/guardrails.ts
interface SafetyCheck {
  passed: boolean;
  risk_level: 'none' | 'low' | 'medium' | 'high' | 'critical';
  flags: string[];
  action: 'proceed' | 'modify' | 'block' | 'crisis_protocol';
}

// 输入安全检查
export async function checkInputSafety(
  userId: string,
  message: string
): Promise<SafetyCheck> {
  const flags: string[] = [];
  let riskLevel: SafetyCheck['risk_level'] = 'none';

  // 1. 自伤/自杀关键词检测
  const crisisKeywords = ['自杀', '不想活', '结束生命', '死了算了', '跳楼', '割腕'];
  if (crisisKeywords.some(kw => message.includes(kw))) {
    flags.push('crisis_signal');
    riskLevel = 'critical';
    return {
      passed: false,
      risk_level: riskLevel,
      flags,
      action: 'crisis_protocol',
    };
  }

  // 2. 绝对预测请求检测
  const fortuneTellingPatterns = ['告诉我会不会', '我能不能', '我今年会', '什么时候能'];
  if (fortuneTellingPatterns.some(p => message.includes(p))) {
    flags.push('fortune_telling_request');
    riskLevel = 'medium';
  }

  // 3. 医疗/法律/投资咨询检测
  const professionalDomains = ['我得了', '应该吃什么药', '起诉', '律师', '股票', '投资'];
  if (professionalDomains.some(d => message.includes(d))) {
    flags.push('professional_advice_request');
    riskLevel = 'medium';
  }

  return {
    passed: riskLevel !== 'critical',
    risk_level: riskLevel,
    flags,
    action: riskLevel === 'critical' ? 'crisis_protocol' :
            flags.length > 0 ? 'modify' : 'proceed',
  };
}

// 输出安全检查
export async function checkOutputSafety(
  response: string
): Promise<SafetyCheck> {
  const flags: string[] = [];

  // 1. 绝对预测检测
  const absolutePredictions = ['你一定会', '肯定能', '必然发生', '百分之百'];
  if (absolutePredictions.some(p => response.includes(p))) {
    flags.push('absolute_prediction');
  }

  // 2. 恐吓性措辞检测
  const scarePatterns = ['大难临头', '劫难', '血光之灾', '必死无疑'];
  if (scarePatterns.some(p => response.includes(p))) {
    flags.push('scare_language');
  }

  // 3. 专业建议越界检测
  const professionalClaims = ['你应该吃', '建议服药', '去买这个股票'];
  if (professionalClaims.some(p => response.includes(p))) {
    flags.push('professional_overreach');
  }

  return {
    passed: flags.length === 0,
    risk_level: flags.length > 0 ? 'medium' : 'none',
    flags,
    action: flags.length > 0 ? 'modify' : 'proceed',
  };
}

// 危机干预协议
export async function handleCrisisProtocol(
  userId: string,
  message: string
): Promise<A2UIOutput> {
  // 1. 记录危机事件
  await logCrisisEvent(userId, message);

  // 2. 返回安全响应
  return {
    meta: {
      summary: '安全协议已触发',
      intent: 'crisis_intervention',
    },
    ui_components: [
      {
        type: 'markdown_text',
        id: 'crisis-response',
        title: '我在这里',
        data: `我听到了你正在经历的困难。如果你有伤害自己的想法，请立即寻求专业帮助：

**全国心理援助热线**
📞 400-161-9995（24小时）
📞 北京：010-82951332
📞 上海：021-12320-5

**你的生命很重要，专业的帮助就在身边。**

如果你愿意，我们可以聊聊你现在的感受。`,
      },
      {
        type: 'action_buttons',
        id: 'crisis-actions',
        title: '下一步',
        data: [
          { label: '拨打热线', action_type: 'call', value: '400-161-9995' },
          { label: '我想聊聊', action_type: 'continue_chat' },
          { label: '我现在安全', action_type: 'confirm_safe' },
        ],
      },
    ],
  };
}
```

### 8.2 反依赖机制

```typescript
// lib/safety/anti-dependency.ts
interface DependencyMetrics {
  daily_sessions: number;
  avg_session_length_minutes: number;
  repeated_questions_count: number;
  fortune_seeking_frequency: number;
  action_completion_rate: number;
}

export async function checkDependencySignals(
  userId: string
): Promise<{
  level: 'healthy' | 'mild' | 'moderate' | 'concerning';
  interventions: string[];
}> {
  const metrics = await calculateDependencyMetrics(userId);
  const interventions: string[] = [];
  let level: 'healthy' | 'mild' | 'moderate' | 'concerning' = 'healthy';

  // 1. 高频使用检测
  if (metrics.daily_sessions > 10) {
    level = 'moderate';
    interventions.push('usage_limit');
  }

  // 2. 重复追问检测
  if (metrics.repeated_questions_count > 5) {
    level = level === 'healthy' ? 'mild' : level;
    interventions.push('redirect_to_action');
  }

  // 3. 算命依赖检测
  if (metrics.fortune_seeking_frequency > 0.7) {
    level = level === 'healthy' ? 'mild' : level;
    interventions.push('diversify_content');
  }

  // 4. 行动完成率过低
  if (metrics.action_completion_rate < 0.2) {
    level = level === 'healthy' ? 'mild' : level;
    interventions.push('simplify_tasks');
  }

  return { level, interventions };
}

// 反依赖干预实现
export async function applyAntiDependencyIntervention(
  userId: string,
  intervention: string
): Promise<void> {
  switch (intervention) {
    case 'usage_limit':
      // 温和提示，不强制限制
      await sendInAppMessage(userId, {
        type: 'gentle_reminder',
        content: '今天你已经来了好多次了。不如出去走走，现实世界里也有很多美好在等着你。',
      });
      break;

    case 'redirect_to_action':
      // 强制插入行动实验
      await forceCommitmentSuggestion(userId, {
        title: '试试这个小实验',
        description: '在继续对话之前，先完成这个 5 分钟的练习',
        type: 'reality_experiment',
      });
      break;

    case 'diversify_content':
      // 减少命理内容，增加心理学内容
      await adjustContentMix(userId, {
        astrology: 0.3,
        psychology: 0.5,
        practice: 0.2,
      });
      break;

    case 'simplify_tasks':
      // 降低任务难度
      await adjustTaskDifficulty(userId, 'easier');
      break;
  }
}
```

### 8.3 隐私保护

```typescript
// lib/privacy/data-minimization.ts

// LLM 上下文注入时的数据最小化
export function buildSafeContext(twin: SpiritualDigitalTwin): SafeContext {
  return {
    // L1: 只提供摘要，不提供原始数据
    astrology_summary: summarizeAstrology(twin.metadata.astrology),
    psychology_traits: twin.metadata.psychology.mbti?.type || 'unknown',

    // L2: 只提供状态级别，不提供具体数值
    energy_level: categorize(twin.dynamic_state.emotional_state.mood_intensity, ['low', 'medium', 'high']),
    recent_mood_trend: 'stable',  // 或 improving/declining

    // L3: 可以完整提供（已是聚合数据）
    aura_points: twin.aggregated_metrics.aura_points,
    dimension_scores: twin.aggregated_metrics.dimension_scores,

    // 排除敏感信息
    // - 具体出生时间
    // - 原始对话内容
    // - 关键事件详情
  };
}

// 数据导出/删除（GDPR/PIPL 合规）
export async function exportUserData(userId: string): Promise<ExportPackage> {
  const userData = await collectAllUserData(userId);

  return {
    profile: userData.profile,
    twin: userData.twin,
    conversations: userData.conversations.map(c => ({
      ...c,
      messages: c.messages,  // 包含完整对话
    })),
    commitments: userData.commitments,
    currency_history: userData.ledger,
    social_connections: userData.social.map(s => ({
      type: s.relationship_type,
      created_at: s.created_at,
    })),
    export_date: new Date().toISOString(),
  };
}

export async function deleteUserData(userId: string): Promise<void> {
  // 1. 软删除主记录
  await softDeleteUser(userId);

  // 2. 匿名化关联数据（保留统计价值）
  await anonymizeConversations(userId);
  await anonymizeSocialEdges(userId);

  // 3. 硬删除敏感数据
  await hardDeleteTwinData(userId);
  await hardDeleteCurrencyLedger(userId);

  // 4. 记录删除事件
  await logDataDeletion(userId);
}
```

---

## 9. 部署与运维

### 9.1 Vercel 部署配置

```json
// vercel.json
{
  "framework": "nextjs",
  "buildCommand": "next build",
  "installCommand": "pnpm install",
  "regions": ["hkg1", "sin1"],  // 香港 + 新加坡

  "crons": [
    {
      "path": "/api/cron/jitai",
      "schedule": "*/15 * * * *"
    },
    {
      "path": "/api/cron/twin-refresh",
      "schedule": "0 0 * * *"
    },
    {
      "path": "/api/cron/metrics",
      "schedule": "0 1 * * *"
    }
  ],

  "functions": {
    "app/api/chat/route.ts": {
      "maxDuration": 60
    },
    "app/api/expert/*/route.ts": {
      "maxDuration": 30
    }
  },

  "env": {
    "DATABASE_URL": "@database-url",
    "GLM_API_KEY": "@glm-api-key",
    "OPENAI_API_KEY": "@openai-api-key",
    "ANTHROPIC_API_KEY": "@anthropic-api-key",
    "CRON_SECRET": "@cron-secret"
  }
}
```

### 9.2 数据库连接（Vercel Postgres 或 Neon）

```typescript
// lib/db/index.ts
import { neon, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';

// Serverless 优化
neonConfig.fetchConnectionCache = true;

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql);

// 连接池（用于 Cron 等长任务）
import { Pool } from '@neondatabase/serverless';

export const pool = new Pool({ connectionString: process.env.DATABASE_URL });
```

### 9.3 监控与可观测性

```typescript
// lib/observability/index.ts
import { trace, context, SpanStatusCode } from '@opentelemetry/api';

// Agent 调用追踪
export function traceAgentCall(agentId: string, fn: () => Promise<any>) {
  const tracer = trace.getTracer('fortune-ai');

  return tracer.startActiveSpan(`agent.${agentId}`, async (span) => {
    try {
      const result = await fn();
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
      throw error;
    } finally {
      span.end();
    }
  });
}

// LLM 调用指标
export async function logLLMUsage(
  userId: string,
  usage: { promptTokens: number; completionTokens: number },
  model: string
) {
  await db.insert(fortune_llm_usage).values({
    user_id: userId,
    model,
    prompt_tokens: usage.promptTokens,
    completion_tokens: usage.completionTokens,
    cost_usd: calculateCost(model, usage),
    created_at: new Date(),
  });
}
```

---

## 10. 实施路线图

### Phase 0: 基础迁移（1-2 周）

- [ ] Next.js 14 项目初始化
- [ ] Vercel AI SDK 集成
- [ ] PostgreSQL 数据库迁移脚本
- [ ] 现有认证系统适配
- [ ] 基础 API 路由搭建

### Phase 1: 核心 Agent 实现（2-3 周）

- [ ] Coach Agent 实现（对话 + 承诺）
- [ ] Analyst Agent 实现（孪生更新）
- [ ] Orchestrator 编排层
- [ ] A2UI 输出系统
- [ ] 基础 Tool Calling

### Phase 2: 数字孪生系统（2-3 周）

- [ ] 三层孪生模型实现
- [ ] 孪生更新日志
- [ ] 可视化组件（雷达图/时间线）
- [ ] 孪生数据 API

### Phase 3: 社交与增长（2-3 周）

- [ ] 好友系统
- [ ] 合盘分析（Social Agent）
- [ ] 能量打赏机制
- [ ] 分享卡生成
- [ ] 好运接龙

### Phase 4: 专家系统与高级功能（2-3 周）

- [ ] Expert Agent Factory
- [ ] 可插拔专家配置
- [ ] pgvector RAG
- [ ] 付费专家解锁

### Phase 5: 安全与合规（1-2 周）

- [ ] 输入/输出安全检查
- [ ] 危机干预协议
- [ ] 反依赖机制
- [ ] 数据导出/删除

### Phase 6: 优化与监控（持续）

- [ ] JITAI 引擎
- [ ] 推送调度优化
- [ ] 性能监控
- [ ] 增长指标追踪

---

## 10.5 FastAPI 衔接方案（渐进式迁移）

> 为了最大化复用现有 FastAPI 代码，同时引入 Vercel AI SDK 智能体系统，采用**双服务架构**进行渐进式迁移。

### 10.5.1 架构拓扑

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户请求层                                       │
│  ┌─────────────────┐                     ┌─────────────────┐                │
│  │   Web UI        │                     │   Agent 请求    │                │
│  │  (bazi2.html)   │                     │   (chat/expert) │                │
│  └────────┬────────┘                     └────────┬────────┘                │
│           │                                       │                          │
└───────────┼───────────────────────────────────────┼──────────────────────────┘
            │                                       │
            ▼                                       ▼
┌───────────────────────────────┐   ┌─────────────────────────────────────────┐
│                               │   │                                          │
│   FastAPI 业务后端 (现有)      │◄──│   Agent Service (Vercel AI SDK)         │
│   fortune_ai/api/             │   │   fortune_ai/agent_service/              │
│                               │   │                                          │
│   • 用户认证 (JWT)            │   │   • Agent 编排 (Coach/Analyst/Social)   │
│   • 八字/铁板计算              │   │   • Tool Calling                        │
│   • 对话历史存储               │   │   • KB 检索 (pgvector)                   │
│   • 承诺/计划管理              │   │   • A2UI 输出生成                        │
│   • 货币/打赏流水              │   │   • 多 Provider LLM                      │
│   • 社交关系图谱               │   │                                          │
│                               │   │   Internal API (SERVICE_TOKEN)           │
│   ┌───────────────────────┐   │   │   • POST /tool/commitment                │
│   │   Tool API 端点        │◄──────│   • POST /tool/twin_update               │
│   │   /api/agent/tool/*   │   │   │   • POST /tool/share_card                │
│   └───────────────────────┘   │   │   • GET /tool/context                    │
│                               │   │                                          │
│           │                   │   │                                          │
│           ▼                   │   │                                          │
│   ┌───────────────────────┐   │   │                                          │
│   │   PostgreSQL SSOT     │   │   │                                          │
│   │   (现有 + 增量表)      │   │   │                                          │
│   └───────────────────────┘   │   │                                          │
│                               │   │                                          │
└───────────────────────────────┘   └─────────────────────────────────────────┘
```

### 10.5.2 Tool API 规范（FastAPI 暴露给 Agent Service）

```python
# fortune_ai/api/routes/agent_tool.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
import hashlib
import hmac

router = APIRouter(prefix="/api/agent/tool", tags=["Agent Tools"])

# === 认证中间件 ===
async def verify_service_token(authorization: str = Header(...)):
    """验证 Agent Service 的服务令牌"""
    expected = f"Bearer {settings.AGENT_SERVICE_TOKEN}"
    if not hmac.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="Invalid service token")

# === Tool API 模型 ===
class ContextRequest(BaseModel):
    user_id: int
    layers: list[str] = ["L1", "L2", "L3"]
    include_recent_messages: int = 5

class ContextResponse(BaseModel):
    user_id: int
    twin: Dict[str, Any]
    recent_messages: list[Dict]
    active_commitments: list[Dict]
    current_plan: Optional[Dict]
    facts_hash: str

class CommitmentCreate(BaseModel):
    user_id: int
    title: str
    description: Optional[str]
    category: str  # energy_boost/reflection/practice/social
    duration_minutes: Optional[int]
    aura_reward: int
    due_date: Optional[str]
    source: str = "agent"

class TwinUpdateRequest(BaseModel):
    user_id: int
    layer: str  # L1/L2/L3
    path: str   # e.g., "dynamic_emotional.current_mood"
    new_value: Any
    confidence: float
    source: str
    trigger: str

class ShareCardCreate(BaseModel):
    user_id: int
    card_type: str  # cosmic_roast/bento_grid/streak/compatibility
    payload: Dict[str, Any]

# === Tool API 端点 ===
@router.get("/context", response_model=ContextResponse)
async def get_user_context(
    req: ContextRequest,
    _: None = Depends(verify_service_token)
):
    """获取用户上下文（孪生 + 对话历史 + 活跃承诺）"""
    twin = await twin_service.get_twin(req.user_id, req.layers)
    messages = await conversation_service.get_recent(req.user_id, req.include_recent_messages)
    commitments = await commitment_service.get_active(req.user_id)
    plan = await plan_service.get_current_enrollment(req.user_id)

    # 计算 facts hash（用于审计）
    facts_hash = hashlib.sha256(
        json.dumps(twin.metadata_astrology, sort_keys=True).encode()
    ).hexdigest()[:16]

    return ContextResponse(
        user_id=req.user_id,
        twin=twin.model_dump(),
        recent_messages=[m.model_dump() for m in messages],
        active_commitments=[c.model_dump() for c in commitments],
        current_plan=plan.model_dump() if plan else None,
        facts_hash=facts_hash,
    )

@router.post("/commitment")
async def create_commitment(
    req: CommitmentCreate,
    _: None = Depends(verify_service_token)
):
    """Agent 创建承诺任务"""
    commitment = await commitment_service.create(
        user_id=req.user_id,
        title=req.title,
        description=req.description,
        category=req.category,
        duration_minutes=req.duration_minutes,
        aura_reward=req.aura_reward,
        due_date=req.due_date,
        source=req.source,
    )
    return {"commitment_id": commitment.commitment_id, "status": "created"}

@router.post("/twin_update")
async def update_twin(
    req: TwinUpdateRequest,
    _: None = Depends(verify_service_token)
):
    """Agent 更新孪生状态"""
    result = await twin_service.update(
        user_id=req.user_id,
        layer=req.layer,
        path=req.path,
        new_value=req.new_value,
        confidence=req.confidence,
        source=req.source,
        trigger=req.trigger,
    )
    return {"updated": True, "log_id": result.log_id}

@router.post("/share_card")
async def create_share_card(
    req: ShareCardCreate,
    _: None = Depends(verify_service_token)
):
    """Agent 创建分享卡"""
    card = await share_service.create_card(
        user_id=req.user_id,
        card_type=req.card_type,
        payload=req.payload,
    )
    return {"card_id": card.card_id, "share_url": card.share_url}

@router.get("/facts/{user_id}")
async def get_facts(
    user_id: int,
    _: None = Depends(verify_service_token)
):
    """获取用户玄学元数据（八字快照）"""
    bazi = await bazi_service.get_snapshot(user_id)
    return {
        "bazi": bazi.model_dump() if bazi else None,
        "facts_hash": compute_facts_hash(bazi),
    }
```

### 10.5.3 Agent Service 调用 Tool API

```typescript
// agent_service/lib/tools/fastapi-client.ts
import { z } from 'zod';
import { tool } from 'ai';

const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || 'http://localhost:8000';
const SERVICE_TOKEN = process.env.AGENT_SERVICE_TOKEN;

/**
 * FastAPI Tool 客户端
 */
async function callFastAPITool<T>(
  endpoint: string,
  method: 'GET' | 'POST',
  body?: any
): Promise<T> {
  const url = `${FASTAPI_BASE_URL}/api/agent/tool${endpoint}`;

  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SERVICE_TOKEN}`,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    throw new Error(`FastAPI Tool error: ${response.status} ${await response.text()}`);
  }

  return response.json();
}

/**
 * Vercel AI SDK Tool 定义 - 创建承诺
 */
export const createCommitmentTool = tool({
  description: '为用户创建一个行动承诺任务',
  parameters: z.object({
    title: z.string().describe('任务标题'),
    description: z.string().optional().describe('任务描述'),
    category: z.enum(['energy_boost', 'reflection', 'practice', 'social']).describe('任务类别'),
    duration_minutes: z.number().optional().describe('预计时长（分钟）'),
    aura_reward: z.number().describe('完成奖励的能量值'),
  }),
  execute: async (params, { userId }) => {
    const result = await callFastAPITool('/commitment', 'POST', {
      user_id: userId,
      ...params,
      source: 'agent',
    });
    return result;
  },
});

/**
 * Vercel AI SDK Tool 定义 - 更新孪生状态
 */
export const updateTwinStateTool = tool({
  description: '更新用户的数字孪生状态',
  parameters: z.object({
    layer: z.enum(['L1', 'L2', 'L3']).describe('要更新的层级'),
    path: z.string().describe('状态路径，如 dynamic_emotional.current_mood'),
    new_value: z.any().describe('新值'),
    confidence: z.number().min(0).max(1).describe('置信度'),
    trigger: z.string().describe('触发原因'),
  }),
  execute: async (params, { userId }) => {
    const result = await callFastAPITool('/twin_update', 'POST', {
      user_id: userId,
      ...params,
      source: 'coach_agent',
    });
    return result;
  },
});

/**
 * Vercel AI SDK Tool 定义 - 获取用户上下文
 */
export const getUserContextTool = tool({
  description: '获取用户的完整上下文（孪生数据、对话历史、活跃承诺）',
  parameters: z.object({
    layers: z.array(z.enum(['L1', 'L2', 'L3'])).default(['L1', 'L2', 'L3']),
    include_recent_messages: z.number().default(5),
  }),
  execute: async (params, { userId }) => {
    const context = await callFastAPITool('/context', 'GET', {
      user_id: userId,
      ...params,
    });
    return context;
  },
});
```

### 10.5.4 数据库增量迁移脚本

```sql
-- fortune_ai/migrations/20251230_claude_mvp_increment.sql
-- 在现有 MVP 表基础上的增量迁移

-- 1. 数字孪生主表（如果不存在）
CREATE TABLE IF NOT EXISTS fortune_digital_twin (
    twin_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES fortune_user(user_id),
    metadata_astrology JSONB NOT NULL DEFAULT '{}',
    metadata_psychology JSONB NOT NULL DEFAULT '{}',
    metadata_memory JSONB NOT NULL DEFAULT '{}',
    dynamic_astro JSONB NOT NULL DEFAULT '{}',
    dynamic_bio JSONB NOT NULL DEFAULT '{}',
    dynamic_social JSONB NOT NULL DEFAULT '{}',
    dynamic_emotional JSONB NOT NULL DEFAULT '{}',
    aura_points INTEGER NOT NULL DEFAULT 0,
    overall_wellbeing NUMERIC(5,2) NOT NULL DEFAULT 50.00,
    growth_streak INTEGER NOT NULL DEFAULT 0,
    dimension_scores JSONB NOT NULL DEFAULT '{"energy":50,"clarity":50,"connection":50,"growth":50,"balance":50}',
    compute_version TEXT NOT NULL DEFAULT 'v1.0',
    last_full_refresh TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. 孪生更新日志
CREATE TABLE IF NOT EXISTS fortune_twin_update_log (
    log_id BIGSERIAL PRIMARY KEY,
    twin_id BIGINT NOT NULL REFERENCES fortune_digital_twin(twin_id),
    trigger_type TEXT NOT NULL,
    layer TEXT NOT NULL,
    path TEXT NOT NULL,
    old_value JSONB,
    new_value JSONB NOT NULL,
    confidence NUMERIC(3,2) NOT NULL,
    source TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. 社交关系边（增强现有表）
CREATE TABLE IF NOT EXISTS fortune_social_edge (
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    peer_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    relationship_type TEXT NOT NULL DEFAULT 'friend',
    status TEXT NOT NULL DEFAULT 'pending',
    compatibility_score NUMERIC(5,2),
    compatibility_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, peer_user_id)
);

-- 4. 能量打赏记录
CREATE TABLE IF NOT EXISTS fortune_energy_buff (
    buff_id BIGSERIAL PRIMARY KEY,
    from_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    to_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    buff_type TEXT NOT NULL,
    amount INTEGER NOT NULL,
    message TEXT,
    source TEXT NOT NULL DEFAULT 'app',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. 好运接龙表
CREATE TABLE IF NOT EXISTS fortune_luck_chain (
    chain_id BIGSERIAL PRIMARY KEY,
    creator_user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    title TEXT NOT NULL,
    description TEXT,
    ritual_type TEXT NOT NULL,  -- photo/gratitude/affirmation
    base_reward INTEGER NOT NULL DEFAULT 10,
    participant_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',  -- active/completed/expired
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fortune_luck_chain_participant (
    chain_id BIGINT NOT NULL REFERENCES fortune_luck_chain(chain_id),
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    position INTEGER NOT NULL,
    contribution TEXT,
    reward_earned INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (chain_id, user_id)
);

-- 6. Agent 运行审计
CREATE TABLE IF NOT EXISTS fortune_agent_run (
    run_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    session_id UUID REFERENCES fortune_conversation_session(session_id),
    agent_name TEXT NOT NULL,
    prompt_version TEXT NOT NULL,
    facts_hash TEXT,
    input JSONB NOT NULL,
    output JSONB NOT NULL,
    tool_calls JSONB,
    usage JSONB,
    latency_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. 分享卡记录
CREATE TABLE IF NOT EXISTS fortune_share_card (
    card_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id),
    card_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    share_url TEXT,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. 知识库 chunk（pgvector）
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS fortune_kb_chunk (
    chunk_id BIGSERIAL PRIMARY KEY,
    collection TEXT NOT NULL,
    source_doc TEXT NOT NULL,
    title TEXT,
    content TEXT NOT NULL,
    embedding vector(1536),
    meta JSONB NOT NULL DEFAULT '{}',
    content_tsv TSVECTOR GENERATED ALWAYS AS (to_tsvector('simple', content)) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. 索引
CREATE INDEX IF NOT EXISTS idx_twin_user ON fortune_digital_twin(user_id);
CREATE INDEX IF NOT EXISTS idx_twin_log_twin ON fortune_twin_update_log(twin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_peer ON fortune_social_edge(peer_user_id, status);
CREATE INDEX IF NOT EXISTS idx_buff_to ON fortune_energy_buff(to_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_run_user ON fortune_agent_run(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kb_collection ON fortune_kb_chunk(collection);
CREATE INDEX IF NOT EXISTS idx_kb_tsv ON fortune_kb_chunk USING GIN(content_tsv);

-- 10. 从现有数据初始化孪生
INSERT INTO fortune_digital_twin (user_id, metadata_astrology)
SELECT
    u.user_id,
    COALESCE(
        (SELECT row_to_json(b.*) FROM fortune_bazi_snapshot b WHERE b.user_id = u.user_id ORDER BY created_at DESC LIMIT 1),
        '{}'::jsonb
    )
FROM fortune_user u
WHERE NOT EXISTS (SELECT 1 FROM fortune_digital_twin t WHERE t.user_id = u.user_id)
ON CONFLICT (user_id) DO NOTHING;
```

### 10.5.5 部署拓扑

```yaml
# docker-compose.yml (开发环境)
version: '3.8'

services:
  # 现有 FastAPI 后端
  fastapi:
    build:
      context: ./fortune_ai
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - AGENT_SERVICE_TOKEN=${AGENT_SERVICE_TOKEN}
    depends_on:
      - postgres

  # 新增 Agent Service (Vercel AI SDK)
  agent-service:
    build:
      context: ./fortune_ai/agent_service
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - FASTAPI_BASE_URL=http://fastapi:8000
      - AGENT_SERVICE_TOKEN=${AGENT_SERVICE_TOKEN}
      - GLM_API_KEY=${GLM_API_KEY}
      - DATABASE_URL=${DATABASE_URL}  # 只读连接（用于 pgvector 检索）

  postgres:
    image: pgvector/pgvector:pg16
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### 10.5.6 迁移阶段

| 阶段 | 任务 | 风险控制 |
|------|------|----------|
| **Phase 0** | 部署 Agent Service，FastAPI 添加 Tool API | 双服务并行，Feature Flag 控制 |
| **Phase 1** | 对话流量逐步切换到 Agent Service | 灰度发布，10% → 50% → 100% |
| **Phase 2** | 社交/合盘功能迁移 | 数据双写，对比验证 |
| **Phase 3** | 考虑是否完全迁移到 Next.js | 根据团队能力和业务需求决定 |

---

## 11. 技术风险与缓解

| 风险 | 影响 | 缓解策略 |
|------|------|----------|
| Vercel 冷启动延迟 | 首次请求慢 | Edge Runtime + 预热 Cron |
| LLM 响应不稳定 | 用户体验差 | 多 Provider 故障转移 + 重试 |
| 数据库连接池耗尽 | 服务不可用 | Serverless Driver + 连接复用 |
| LLM 成本失控 | 财务风险 | 用量限制 + 缓存 + 用户配额 |
| 安全漏洞 | 合规风险 | 多层安全检查 + 审计日志 |

---

## 12. 附录

### A. 环境变量清单

```bash
# 数据库
DATABASE_URL=postgresql://...

# LLM Providers
GLM_BASE_URL=https://api.z.ai/api/paas/v4
GLM_API_KEY=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

# Vercel
CRON_SECRET=
NEXT_PUBLIC_BASE_URL=https://fortune.ai

# 可选：健康数据
APPLE_HEALTH_WEBHOOK_SECRET=
FITBIT_CLIENT_ID=
FITBIT_CLIENT_SECRET=

# 可选：推送
EXPO_ACCESS_TOKEN=
APNS_KEY_ID=
```

### B. 核心依赖

```json
{
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "ai": "^3.0.0",
    "@ai-sdk/openai": "^0.0.1",
    "@ai-sdk/anthropic": "^0.0.1",
    "@neondatabase/serverless": "^0.9.0",
    "drizzle-orm": "^0.30.0",
    "zod": "^3.22.0"
  }
}
```

### C. 参考资料

- [Vercel AI SDK 文档](https://sdk.vercel.ai/docs)
- [Next.js App Router](https://nextjs.org/docs/app)
- [pgvector 扩展](https://github.com/pgvector/pgvector)
- [JITAI 论文](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5977682/)

---

**文档版本**：MVP v1.1
**最后更新**：2025-12-30
**作者**：System Architect (Claude)

---

## 变更日志

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2025-12-30 | 初始版本，基于 bp v1.md 完成架构设计 |
| v1.1 | 2025-12-30 | 增加：可插拔知识库机制、完整付费体系、FastAPI 衔接方案、增强社交能量网络 |
