# VibeLife UI/UX 架构设计 V4

> **版本**: 4.0
> **日期**: 2026-01-08
> **基于**: AI SDK 6 + Next.js 14 App Router
> **定位**: 前端架构设计的唯一真理来源

---

# Part 1: 需求总结

## 1.1 核心需求

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   核心需求                                                                  │
│                                                                             │
│   1. 独立站矩阵：bazi/zodiac/mbti 各自独立子域名，但共享用户数据            │
│   2. 单页全功能：所有功能在同一主界面，Chat 为核心 + Panel Tab 为辅         │
│   3. Chat 小程序：Chat 内可嵌入完整交互组件（如塔罗抽牌、K线图）            │
│   4. 深度定制：每个 Skill 需要 2-4 周开发专属组件和交互流程                 │
│   5. 共享基础：Auth/Payment/ChatEngine/ReportEngine 100% 复用              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 1.2 关键决策

| 决策点 | 方案 |
|-------|------|
| **页面模式** | 单页 AppShell：Chat 为核心 + 可扩展 Panel Tab |
| **Skill 切换** | 子域名跳转（独立站矩阵） |
| **共享功能** | Report/Relationship/Greeting/Interview 默认全部启用 |
| **专属功能** | 作为 Skill Plugin 的 `panels[]` 和 `tools[]` 注册 |
| **Chat 卡片** | 使用 AI SDK 6 Generative UI（Tool → React Component） |
| **开发流程** | 2-4 周深度定制，Plugin 模式解耦 |

---

# Part 2: AI SDK 6 兼容架构

## 2.1 AI SDK 6 核心特性

基于 [AI SDK 6 官方文档](https://vercel.com/blog/ai-sdk-6)，核心特性包括：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   AI SDK 6 核心特性                                                         │
│                                                                             │
│   1. Generative UI                                                          │
│      • 工具结果渲染为自定义 React 组件                                      │
│      • streamUI API 支持流式 UI 生成                                        │
│      • 与 React Server Components 深度集成                                  │
│                                                                             │
│   2. Enhanced Tool Calling                                                  │
│      • needsApproval: 人类审批机制                                          │
│      • strict mode: 更可靠的输入生成                                        │
│      • toModelOutput: 分离工具结果与模型输入                                │
│                                                                             │
│   3. useChat Hook                                                           │
│      • 消息流式传输                                                         │
│      • 自动状态管理                                                         │
│      • 原生工具调用支持                                                     │
│      • addToolApprovalResponse: UI 审批响应                                 │
│                                                                             │
│   4. MCP Support                                                            │
│      • OAuth 认证                                                           │
│      • Resources, Prompts, Elicitation                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 2.2 架构映射：Chat Cards → Generative UI

**原设计（自定义 CardRenderer）：**
```
用户消息 → 后端返回 JSON { type: "bazi.kline", data: {...} } → 前端 CardRenderer 渲染
```

**AI SDK 6 方式（Generative UI）：**
```
用户消息 → 后端 Tool Call → Tool 返回数据 → AI SDK 自动渲染对应 React 组件
```

### 关键改动

| 组件 | 原设计 | AI SDK 6 兼容设计 |
|------|--------|------------------|
| Chat Cards | 自定义 `CardRenderer` | AI SDK `tools` + Generative UI |
| 卡片注册 | `CardRegistry.ts` | 工具定义中的 `render` 函数 |
| 交互状态 | `CardProps.onAction` | `addToolApprovalResponse` |
| 渲染时机 | 消息解析后 | 流式生成中 |

---

# Part 3: 架构全景图

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   VIBELIFE FRONTEND ARCHITECTURE (AI SDK 6 Compatible)                        ║
║                                                                               ║
║   ┌─────────────────────────────────────────────────────────────────────────┐ ║
║   │                                                                         │ ║
║   │                        Skill Plugin Layer                               │ ║
║   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │ ║
║   │   │  BaZi   │  │ Zodiac  │  │  MBTI   │  │  Tarot  │  │  ...    │     │ ║
║   │   │ Plugin  │  │ Plugin  │  │ Plugin  │  │ Plugin  │  │ Plugins │     │ ║
║   │   │         │  │         │  │         │  │         │  │         │     │ ║
║   │   │• Panels │  │• Panels │  │• Panels │  │• Panels │  │         │     │ ║
║   │   │• Tools  │  │• Tools  │  │• Tools  │  │• Tools  │  │         │     │ ║
║   │   │• Theme  │  │• Theme  │  │• Theme  │  │• Theme  │  │         │     │ ║
║   │   │• Config │  │• Config │  │• Config │  │• Config │  │         │     │ ║
║   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘     │ ║
║   │                              │                                         │ ║
║   └──────────────────────────────┼─────────────────────────────────────────┘ ║
║                                  ▼                                           ║
║   ┌─────────────────────────────────────────────────────────────────────────┐ ║
║   │                                                                         │ ║
║   │                        Shared App Shell                                 │ ║
║   │   ┌─────────────────────────────────────────────────────────────────┐   │ ║
║   │   │  ┌────────┐  ┌──────────────────────┐  ┌───────────────────┐   │   │ ║
║   │   │  │ NavBar │  │     ChatContainer    │  │   ResizablePanel  │   │   │ ║
║   │   │  │        │  │                      │  │                   │   │   │ ║
║   │   │  │ • Tab  │  │  ┌────────────────┐  │  │  Tab: Chat|Chart  │   │   │ ║
║   │   │  │ • Skill│  │  │  Message Flow  │  │  │      |Journey|Me  │   │   │ ║
║   │   │  │   Logo │  │  │  + Tool UIs    │  │  │      |Report|...  │   │   │ ║
║   │   │  │        │  │  │ (Generative UI)│  │  │                   │   │   │ ║
║   │   │  │        │  │  └────────────────┘  │  │  ┌─────────────┐  │   │   │ ║
║   │   │  │        │  │                      │  │  │ Panel       │  │   │   │ ║
║   │   │  │        │  │  ┌────────────────┐  │  │  │ Content     │  │   │   │ ║
║   │   │  │        │  │  │   ChatInput    │  │  │  │ (Dynamic)   │  │   │   │ ║
║   │   │  │        │  │  └────────────────┘  │  │  └─────────────┘  │   │   │ ║
║   │   │  └────────┘  └──────────────────────┘  └───────────────────┘   │   │ ║
║   │   └─────────────────────────────────────────────────────────────────┘   │ ║
║   │                                                                         │ ║
║   └─────────────────────────────────────────────────────────────────────────┘ ║
║                                  │                                           ║
║                                  ▼                                           ║
║   ┌─────────────────────────────────────────────────────────────────────────┐ ║
║   │                                                                         │ ║
║   │                      AI SDK 6 Integration Layer                         │ ║
║   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │ ║
║   │   │ useChat │  │ streamUI│  │  Tools  │  │ToolLoop │  │  MCP    │     │ ║
║   │   │  Hook   │  │   API   │  │ Registry│  │  Agent  │  │ Support │     │ ║
║   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘     │ ║
║   │                                                                         │ ║
║   └─────────────────────────────────────────────────────────────────────────┘ ║
║                                  │                                           ║
║                                  ▼                                           ║
║   ┌─────────────────────────────────────────────────────────────────────────┐ ║
║   │                                                                         │ ║
║   │                        Platform Foundation                              │ ║
║   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │ ║
║   │   │  Auth   │  │ Payment │  │  Vibe   │  │ Report  │  │  User   │     │ ║
║   │   │Provider │  │ Gateway │  │ Engine  │  │ Engine  │  │ Profile │     │ ║
║   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘     │ ║
║   │                                                                         │ ║
║   └─────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

---

# Part 4: 目录结构设计

```
apps/web/src/
│
├── app/                              # Next.js App Router
│   ├── (skill)/                      # Skill 路由组（动态）
│   │   └── [skill]/                  # 动态 Skill 参数
│   │       ├── layout.tsx            # Skill Layout（注入 theme + plugins）
│   │       └── page.tsx              # 主页面（AppShell）
│   │
│   ├── (shared)/                     # 共享路由
│   │   ├── auth/                     # 认证相关
│   │   ├── payment/                  # 支付相关
│   │   └── share/[token]/            # 分享链接
│   │
│   ├── api/                          # API Routes
│   │   └── chat/
│   │       └── route.ts              # AI SDK 6 streamUI endpoint
│   │
│   └── layout.tsx                    # 根 Layout
│
├── skills/                           # ⭐ Skill 插件系统
│   ├── registry.ts                   # Skill 注册中心
│   ├── types.ts                      # 类型定义
│   │
│   ├── bazi/                         # 八字 Skill 插件
│   │   ├── index.ts                  # 导出入口
│   │   ├── config.ts                 # 配置（主题、图标、快捷问题）
│   │   ├── panels/                   # 专属 Panel
│   │   │   ├── KLinePanel.tsx        # 人生 K 线 Panel
│   │   │   ├── FortunePanel.tsx      # 大运流年 Panel
│   │   │   └── index.ts
│   │   ├── tools/                    # ⭐ AI SDK 6 Tools（Generative UI）
│   │   │   ├── show-bazi-chart.tsx   # 命盘展示工具
│   │   │   ├── show-kline.tsx        # K 线展示工具
│   │   │   ├── show-fortune.tsx      # 大运流年工具
│   │   │   └── index.ts
│   │   ├── components/               # 专属组件（被 tools 使用）
│   │   │   ├── BaziChart.tsx
│   │   │   ├── KLineChart.tsx
│   │   │   └── FortuneTimeline.tsx
│   │   └── theme.css                 # Skill 主题变量
│   │
│   ├── zodiac/                       # 星座 Skill 插件
│   │   ├── index.ts
│   │   ├── config.ts
│   │   ├── panels/
│   │   │   ├── TransitPanel.tsx
│   │   │   └── SynastryPanel.tsx
│   │   ├── tools/
│   │   │   ├── show-zodiac-chart.tsx
│   │   │   ├── show-transit.tsx
│   │   │   └── show-synastry.tsx
│   │   └── components/
│   │
│   ├── tarot/                        # 塔罗 Skill 插件
│   │   ├── panels/
│   │   │   └── DrawPanel.tsx
│   │   ├── tools/
│   │   │   ├── start-tarot-draw.tsx  # ⭐ 交互式抽牌工具
│   │   │   └── show-tarot-result.tsx
│   │   └── components/
│   │       ├── TarotDeck.tsx
│   │       └── TarotSpread.tsx
│   │
│   └── mbti/                         # MBTI Skill 插件
│       ├── panels/
│       │   └── TestPanel.tsx
│       ├── tools/
│       │   ├── start-mbti-test.tsx   # ⭐ 交互式测试工具
│       │   └── show-mbti-result.tsx
│       └── components/
│
├── shell/                            # ⭐ 共享 App Shell
│   ├── AppShell.tsx                  # 主壳体
│   ├── NavBar.tsx                    # 左侧导航
│   ├── ChatArea.tsx                  # 中间对话区
│   ├── PanelArea.tsx                 # 右侧面板区
│   ├── PanelTabs.tsx                 # 面板 Tab 切换
│   └── hooks/
│       ├── useSkillPanels.ts
│       └── useActivePanel.ts
│
├── chat/                             # ⭐ Chat 引擎（AI SDK 6）
│   ├── ChatContainer.tsx             # Chat 容器
│   ├── ChatInput.tsx                 # 输入框
│   ├── MessageList.tsx               # 消息列表
│   ├── Message.tsx                   # 单条消息（支持 Tool UI）
│   │
│   ├── tools/                        # 共享 Tools（所有 Skill 可用）
│   │   ├── show-report.tsx           # 报告展示
│   │   ├── show-relationship.tsx     # 关系分析
│   │   ├── show-insight.tsx          # 洞察卡片
│   │   ├── request-info.tsx          # 信息采集
│   │   └── index.ts
│   │
│   └── hooks/
│       ├── useVibeChat.ts            # AI SDK 6 useChat wrapper
│       └── useToolApproval.ts        # 工具审批 Hook
│
├── components/                       # 共享组件
│   ├── core/                         # 核心视觉组件
│   ├── ui/                           # 基础 UI 组件
│   ├── chart/                        # 通用图表组件
│   └── report/                       # 报告组件
│
├── providers/                        # 全局 Provider
│   ├── SkillProvider.tsx             # Skill 上下文
│   ├── AuthProvider.tsx              # 认证上下文
│   └── ChatProvider.tsx              # Chat 状态
│
└── lib/
    ├── api.ts                        # API 客户端
    ├── skill-loader.ts               # Skill 动态加载
    └── tools-registry.ts             # ⭐ AI SDK 6 工具注册
```

---

# Part 5: AI SDK 6 集成详解

## 5.1 工具定义类型

```typescript
// skills/types.ts

import { ComponentType } from "react";
import { LucideIcon } from "lucide-react";
import { tool } from "ai";
import { z } from "zod";

// ═══════════════════════════════════════════════════════════════════════════
// Skill ID
// ═══════════════════════════════════════════════════════════════════════════

export type SkillId = "bazi" | "zodiac" | "mbti" | "tarot" | "attach" | "career";

// ═══════════════════════════════════════════════════════════════════════════
// Panel 定义
// ═══════════════════════════════════════════════════════════════════════════

export interface PanelDefinition {
  id: string;
  label: string;
  icon: LucideIcon;
  component: ComponentType<PanelProps>;
  order?: number;
  badge?: () => string | number | null;
  requireAuth?: boolean;
  requirePaid?: boolean;
}

export interface PanelProps {
  skill: SkillId;
  isActive: boolean;
}

// ═══════════════════════════════════════════════════════════════════════════
// AI SDK 6 Tool 定义
// ═══════════════════════════════════════════════════════════════════════════

export interface ToolDefinition<TParams = any, TResult = any> {
  // 工具元信息
  name: string;
  description: string;

  // Zod schema for parameters
  parameters: z.ZodSchema<TParams>;

  // 执行函数
  execute: (params: TParams) => Promise<TResult>;

  // ⭐ Generative UI: 渲染函数
  render?: (result: TResult) => React.ReactNode;

  // 审批配置
  needsApproval?: boolean | ((params: TParams) => boolean);

  // 模型输出转换（可选）
  toModelOutput?: (result: TResult) => string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Skill Plugin 完整定义
// ═══════════════════════════════════════════════════════════════════════════

export interface SkillPlugin {
  // 基础信息
  id: SkillId;
  name: string;
  subtitle: string;
  icon: LucideIcon;
  enabled: boolean;
  beta?: boolean;

  // 主题配置
  theme: {
    primary: string;
    secondary: string;
    glow: string;
    gradient: string;
  };

  // 功能配置
  features: {
    quickPrompts: string[];
    emptyState: {
      title: string;
      subtitle: string;
      image?: string;
    };
  };

  // 共享功能开关
  sharedFeatures?: {
    report?: boolean;
    relationship?: boolean;
    greeting?: boolean;
    interview?: boolean;
  };

  // ⭐ 专属 Panel 注册
  panels: PanelDefinition[];

  // ⭐ 专属 Tools 注册（AI SDK 6 Generative UI）
  tools: ToolDefinition[];

  // 输入表单配置
  inputForm?: {
    fields: FormFieldDefinition[];
    required: string[];
  };
}
```

## 5.2 八字工具示例（Generative UI）

```typescript
// skills/bazi/tools/show-kline.tsx

import { z } from "zod";
import { ToolDefinition } from "@/skills/types";
import { KLineChart } from "../components/KLineChart";

// 参数 Schema
const KLineParams = z.object({
  userId: z.string().describe("用户 ID"),
  startYear: z.number().optional().describe("起始年份"),
  endYear: z.number().optional().describe("结束年份"),
});

type KLineParamsType = z.infer<typeof KLineParams>;

// K 线数据结构
interface KLineResult {
  userId: string;
  data: {
    year: number;
    score: number;
    majorLuck: string;
    events: string[];
  }[];
  currentYear: number;
  highlights: {
    bestYear: number;
    worstYear: number;
    turningPoints: number[];
  };
}

export const showKLineTool: ToolDefinition<KLineParamsType, KLineResult> = {
  name: "show_bazi_kline",
  description: "展示用户的人生 K 线图，显示过去和未来的运势趋势",

  parameters: KLineParams,

  async execute({ userId, startYear, endYear }) {
    // 调用后端 API 获取 K 线数据
    const response = await fetch(`/api/v1/fortune/kline`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, startYear, endYear }),
    });

    if (!response.ok) {
      throw new Error("Failed to fetch K-line data");
    }

    return response.json();
  },

  // ⭐ Generative UI: 渲染 K 线图组件
  render(result) {
    return (
      <div className="kline-card bg-card rounded-xl p-4 border shadow-sm">
        <h3 className="text-lg font-semibold mb-4">你的人生 K 线</h3>
        <KLineChart
          data={result.data}
          currentYear={result.currentYear}
          highlights={result.highlights}
        />
        <div className="mt-4 flex gap-4 text-sm text-muted-foreground">
          <span>最佳年份: {result.highlights.bestYear}</span>
          <span>低谷年份: {result.highlights.worstYear}</span>
        </div>
      </div>
    );
  },

  // 返回给模型的摘要（减少 token）
  toModelOutput(result) {
    return `已展示用户的人生 K 线图。最佳年份: ${result.highlights.bestYear}，低谷年份: ${result.highlights.worstYear}，转折点: ${result.highlights.turningPoints.join(", ")}`;
  },
};
```

## 5.3 塔罗抽牌工具（交互式 Generative UI）

```typescript
// skills/tarot/tools/start-tarot-draw.tsx

import { z } from "zod";
import { ToolDefinition } from "@/skills/types";
import { TarotDrawInteractive } from "../components/TarotDrawInteractive";

const TarotDrawParams = z.object({
  question: z.string().describe("用户的问题"),
  spreadType: z.enum(["single", "three", "celtic"]).describe("牌阵类型"),
});

type TarotDrawParamsType = z.infer<typeof TarotDrawParams>;

interface TarotDrawResult {
  sessionId: string;
  question: string;
  spreadType: string;
  // 初始状态，卡片在用户抽取后填充
  cards: null;
}

export const startTarotDrawTool: ToolDefinition<TarotDrawParamsType, TarotDrawResult> = {
  name: "start_tarot_draw",
  description: "开始塔罗牌抽牌流程，用户可以交互式地抽取卡牌",

  parameters: TarotDrawParams,

  async execute({ question, spreadType }) {
    // 创建抽牌会话
    const response = await fetch(`/api/v1/tarot/session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question, spreadType }),
    });

    const session = await response.json();

    return {
      sessionId: session.id,
      question,
      spreadType,
      cards: null,
    };
  },

  // ⭐ 渲染交互式抽牌组件
  render(result) {
    return (
      <TarotDrawInteractive
        sessionId={result.sessionId}
        question={result.question}
        spreadType={result.spreadType as "single" | "three" | "celtic"}
        onComplete={(cards) => {
          // 抽牌完成后，可以触发新的消息或工具调用
          console.log("Tarot draw complete:", cards);
        }}
      />
    );
  },

  // 抽牌开始时返回给模型的信息
  toModelOutput(result) {
    return `已开始塔罗抽牌流程。问题: "${result.question}"，牌阵: ${result.spreadType}。等待用户抽牌...`;
  },

  // 需要用户交互，不需要模型审批
  needsApproval: false,
};
```

## 5.4 工具注册中心

```typescript
// lib/tools-registry.ts

import { ToolDefinition, SkillId } from "@/skills/types";

// 共享工具（所有 Skill 可用）
import { showReportTool } from "@/chat/tools/show-report";
import { showRelationshipTool } from "@/chat/tools/show-relationship";
import { showInsightTool } from "@/chat/tools/show-insight";
import { requestInfoTool } from "@/chat/tools/request-info";

// Skill 专属工具
import { baziTools } from "@/skills/bazi/tools";
import { zodiacTools } from "@/skills/zodiac/tools";
import { tarotTools } from "@/skills/tarot/tools";
import { mbtiTools } from "@/skills/mbti/tools";

// 共享工具列表
const SHARED_TOOLS: ToolDefinition[] = [
  showReportTool,
  showRelationshipTool,
  showInsightTool,
  requestInfoTool,
];

// Skill 工具映射
const SKILL_TOOLS: Record<SkillId, ToolDefinition[]> = {
  bazi: baziTools,
  zodiac: zodiacTools,
  tarot: tarotTools,
  mbti: mbtiTools,
  attach: [],
  career: [],
};

/**
 * 获取指定 Skill 的所有可用工具
 */
export function getToolsForSkill(skillId: SkillId): ToolDefinition[] {
  const skillTools = SKILL_TOOLS[skillId] || [];
  return [...SHARED_TOOLS, ...skillTools];
}

/**
 * 将 ToolDefinition 转换为 AI SDK 6 tool() 格式
 */
export function createAISDKTools(skillId: SkillId) {
  const tools = getToolsForSkill(skillId);

  return tools.reduce((acc, toolDef) => {
    acc[toolDef.name] = {
      description: toolDef.description,
      parameters: toolDef.parameters,
      execute: toolDef.execute,
      // AI SDK 6 需要 render 在 streamUI 中使用
    };
    return acc;
  }, {} as Record<string, any>);
}

/**
 * 获取工具的渲染函数
 */
export function getToolRenderer(toolName: string, skillId: SkillId) {
  const tools = getToolsForSkill(skillId);
  const tool = tools.find(t => t.name === toolName);
  return tool?.render;
}
```

## 5.5 streamUI API Route

```typescript
// app/api/chat/route.ts

import { streamUI } from "ai/rsc";
import { createAISDKTools, getToolRenderer } from "@/lib/tools-registry";
import { SkillId } from "@/skills/types";

export async function POST(request: Request) {
  const { messages, skill, voice_mode, conversation_id } = await request.json();

  const skillId = skill as SkillId;
  const tools = createAISDKTools(skillId);

  const result = await streamUI({
    model: openai("gpt-4o"),
    messages,
    tools,

    // 系统提示（注入 Skill 和语气）
    system: buildSystemPrompt(skillId, voice_mode),

    // 工具结果渲染
    toolChoice: "auto",

    // 文本流式输出
    text: ({ content, done }) => {
      return <div className="prose">{content}</div>;
    },

    // 工具调用渲染
    tools: Object.fromEntries(
      Object.entries(tools).map(([name, toolConfig]) => [
        name,
        {
          ...toolConfig,
          render: async function* (args) {
            // 显示加载状态
            yield <div className="animate-pulse">处理中...</div>;

            // 执行工具
            const result = await toolConfig.execute(args);

            // 获取渲染函数
            const render = getToolRenderer(name, skillId);

            // 返回最终 UI
            return render ? render(result) : <pre>{JSON.stringify(result, null, 2)}</pre>;
          },
        },
      ])
    ),
  });

  return result.toDataStreamResponse();
}
```

## 5.6 更新后的 useVibeChat Hook

```typescript
// chat/hooks/useVibeChat.ts

"use client";

import { useChat } from "@ai-sdk/react";
import { useCallback, useMemo } from "react";
import { getTokens } from "@/lib/api";

export type SkillId = "bazi" | "zodiac" | "mbti" | "tarot" | "attach" | "career";
export type VoiceMode = "warm" | "sarcastic";

export interface UseVibeChatOptions {
  skillId: SkillId;
  voiceMode?: VoiceMode;
  conversationId?: string;
  onConversationStart?: (id: string) => void;
  onError?: (error: Error) => void;
  onFinish?: () => void;
  // ⭐ AI SDK 6: 工具审批回调
  onToolCall?: (toolCall: ToolCallInfo) => void;
}

interface ToolCallInfo {
  toolName: string;
  args: any;
  toolCallId: string;
}

export function useVibeChat({
  skillId,
  voiceMode = "warm",
  conversationId,
  onConversationStart,
  onError,
  onFinish,
  onToolCall,
}: UseVibeChatOptions) {
  const { accessToken } = getTokens();

  // AI SDK 6 useChat hook
  const chat = useChat({
    id: conversationId,
    api: "/api/chat",
    headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : undefined,
    body: {
      skill: skillId,
      voice_mode: voiceMode,
      conversation_id: conversationId,
    },

    onFinish: (message) => {
      const metadata = message?.experimental_providerMetadata;
      if (metadata?.conversation_id && onConversationStart) {
        onConversationStart(metadata.conversation_id as string);
      }
      onFinish?.();
    },

    onError: (error) => {
      console.error("Chat error:", error);
      onError?.(error);
    },

    // ⭐ AI SDK 6: 工具调用处理
    onToolCall: ({ toolCall }) => {
      onToolCall?.({
        toolName: toolCall.toolName,
        args: toolCall.args,
        toolCallId: toolCall.toolCallId,
      });
    },
  });

  // ⭐ AI SDK 6: 添加工具审批响应
  const approveToolCall = useCallback(
    (toolCallId: string, approved: boolean, result?: any) => {
      chat.addToolResult({
        toolCallId,
        result: approved ? result : { error: "User rejected" },
      });
    },
    [chat]
  );

  // 发送消息
  const sendVibeMessage = useCallback(
    async (content: string) => {
      return chat.append({
        role: "user",
        content,
      });
    },
    [chat]
  );

  // 快捷提示
  const sendQuickPrompt = useCallback(
    async (content: string) => {
      chat.setMessages([]);
      return sendVibeMessage(content);
    },
    [chat, sendVibeMessage]
  );

  const isLoading = chat.isLoading;

  return {
    // Core state
    messages: chat.messages,
    isLoading,
    error: chat.error,

    // Actions
    sendMessage: sendVibeMessage,
    sendQuickPrompt,
    stop: chat.stop,
    reload: chat.reload,

    // ⭐ AI SDK 6: 工具审批
    approveToolCall,
    addToolResult: chat.addToolResult,

    // For advanced use
    setMessages: chat.setMessages,

    // Metadata
    conversationId,
    skillId,
    voiceMode,
  };
}

export default useVibeChat;
```

---

# Part 6: 消息渲染（支持 Tool UI）

```typescript
// chat/Message.tsx

"use client";

import { Message as AIMessage } from "ai";
import { cn } from "@/lib/utils";
import { SkillId } from "@/skills/types";

interface MessageProps {
  message: AIMessage;
  skill: SkillId;
  isLast?: boolean;
}

export function Message({ message, skill, isLast }: MessageProps) {
  const isUser = message.role === "user";
  const isAssistant = message.role === "assistant";

  return (
    <div
      className={cn(
        "flex gap-3 p-4",
        isUser && "flex-row-reverse"
      )}
    >
      {/* Avatar */}
      <div className={cn(
        "w-8 h-8 rounded-full flex-shrink-0",
        isUser ? "bg-primary" : "bg-skill-primary"
      )}>
        {/* Avatar content */}
      </div>

      {/* Content */}
      <div className={cn(
        "flex-1 max-w-[80%]",
        isUser && "text-right"
      )}>
        {/* 文本内容 */}
        {message.content && (
          <div className={cn(
            "prose prose-sm",
            isUser && "bg-primary text-primary-foreground rounded-2xl px-4 py-2 inline-block"
          )}>
            {message.content}
          </div>
        )}

        {/* ⭐ AI SDK 6: 工具调用 UI (Generative UI) */}
        {message.toolInvocations?.map((toolInvocation) => (
          <div key={toolInvocation.toolCallId} className="mt-3">
            {toolInvocation.state === "pending" && (
              <div className="animate-pulse bg-muted rounded-xl p-4">
                正在处理...
              </div>
            )}

            {toolInvocation.state === "result" && (
              <div className="tool-result">
                {/* 工具结果由 streamUI 的 render 函数生成 */}
                {toolInvocation.result}
              </div>
            )}

            {/* 需要审批的工具 */}
            {toolInvocation.state === "call" && toolInvocation.toolName.startsWith("confirm_") && (
              <ToolApprovalCard
                toolName={toolInvocation.toolName}
                args={toolInvocation.args}
                toolCallId={toolInvocation.toolCallId}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

// 工具审批卡片
function ToolApprovalCard({ toolName, args, toolCallId }: {
  toolName: string;
  args: any;
  toolCallId: string;
}) {
  const { approveToolCall } = useVibeChat({ skillId: "bazi" }); // 从 context 获取

  return (
    <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4">
      <p className="font-medium">需要确认操作</p>
      <p className="text-sm text-muted-foreground mt-1">
        {toolName}: {JSON.stringify(args)}
      </p>
      <div className="flex gap-2 mt-3">
        <button
          onClick={() => approveToolCall(toolCallId, true)}
          className="px-3 py-1 bg-primary text-primary-foreground rounded"
        >
          确认
        </button>
        <button
          onClick={() => approveToolCall(toolCallId, false)}
          className="px-3 py-1 bg-muted rounded"
        >
          取消
        </button>
      </div>
    </div>
  );
}
```

---

# Part 7: Panel Tab 系统

```typescript
// shell/PanelTabs.tsx

"use client";

import { useMemo } from "react";
import { cn } from "@/lib/utils";
import { useSkillRegistry, useCurrentSkill } from "@/providers/SkillProvider";
import { PanelDefinition } from "@/skills/types";
import {
  MessageSquare,
  Target,
  FileText,
  Heart,
  Map,
  User,
} from "lucide-react";

// 共享 Panel
import { ChatPanel } from "@/components/layout/panels/ChatPanel";
import { ChartPanel } from "@/components/layout/panels/ChartPanel";
import { JourneyPanel } from "@/components/layout/panels/JourneyPanel";
import { MePanel } from "@/components/layout/panels/MePanel";
import { ReportPanel } from "@/components/layout/panels/ReportPanel";
import { RelationshipPanel } from "@/components/layout/panels/RelationshipPanel";

const SHARED_PANELS: PanelDefinition[] = [
  { id: "chat", label: "对话", icon: MessageSquare, component: ChatPanel, order: 0 },
  { id: "chart", label: "命盘", icon: Target, component: ChartPanel, order: 1 },
  { id: "report", label: "报告", icon: FileText, component: ReportPanel, order: 2 },
  { id: "relationship", label: "关系", icon: Heart, component: RelationshipPanel, order: 3 },
  { id: "journey", label: "旅程", icon: Map, component: JourneyPanel, order: 4 },
  { id: "me", label: "我", icon: User, component: MePanel, order: 100 },
];

interface PanelTabsProps {
  activePanel: string;
  onPanelChange: (panelId: string) => void;
}

export function PanelTabs({ activePanel, onPanelChange }: PanelTabsProps) {
  const registry = useSkillRegistry();
  const currentSkill = useCurrentSkill();

  // 合并共享 Panel 和 Skill 专属 Panel
  const allPanels = useMemo(() => {
    const skillPlugin = registry.get(currentSkill);
    const skillPanels = skillPlugin?.panels || [];

    // 过滤掉 Skill 禁用的共享功能
    const enabledSharedPanels = SHARED_PANELS.filter(panel => {
      if (panel.id === "report" && skillPlugin?.sharedFeatures?.report === false) {
        return false;
      }
      if (panel.id === "relationship" && skillPlugin?.sharedFeatures?.relationship === false) {
        return false;
      }
      return true;
    });

    // 合并并排序
    return [...enabledSharedPanels, ...skillPanels].sort((a, b) =>
      (a.order ?? 50) - (b.order ?? 50)
    );
  }, [registry, currentSkill]);

  return (
    <div className="flex items-center gap-1 p-1 bg-muted/50 rounded-lg overflow-x-auto">
      {allPanels.map(panel => (
        <button
          key={panel.id}
          onClick={() => onPanelChange(panel.id)}
          className={cn(
            "flex items-center gap-2 px-3 py-1.5 rounded-md text-sm transition-colors whitespace-nowrap",
            activePanel === panel.id
              ? "bg-background shadow-sm text-foreground"
              : "text-muted-foreground hover:text-foreground"
          )}
        >
          <panel.icon className="w-4 h-4" />
          <span className="hidden sm:inline">{panel.label}</span>
        </button>
      ))}
    </div>
  );
}
```

---

# Part 8: 新增 Skill 开发流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   新增 MBTI Skill 的开发步骤（2-4 周）                                      │
│                                                                             │
│   Week 1: 基础配置                                                          │
│   ─────────────────────────────────────────────────────────────────────     │
│   □ 创建 skills/mbti/ 目录                                                  │
│   □ 编写 config.ts（主题、图标、快捷问题）                                  │
│   □ 编写 theme.css（CSS 变量）                                              │
│   □ 在 registry.ts 注册                                                     │
│   □ 基础对话可用                                                            │
│                                                                             │
│   Week 2: 专属 Tools（Generative UI）                                       │
│   ─────────────────────────────────────────────────────────────────────     │
│   □ 开发 start-mbti-test.tsx（交互式测试工具）                              │
│   □ 开发 show-mbti-result.tsx（结果展示工具）                               │
│   □ 开发 show-cognitive-stack.tsx（认知功能栈）                             │
│   □ 在 tools/index.ts 导出                                                  │
│                                                                             │
│   Week 3: 专属 Panel + 组件                                                 │
│   ─────────────────────────────────────────────────────────────────────     │
│   □ 开发 TestPanel（完整测试流程面板）                                      │
│   □ 开发 CareerPanel（职业匹配面板）                                        │
│   □ 开发 MbtiRadarChart 组件                                                │
│   □ 开发 CognitiveStackChart 组件                                           │
│                                                                             │
│   Week 4: 联调测试                                                          │
│   ─────────────────────────────────────────────────────────────────────     │
│   □ 后端 API 联调                                                           │
│   □ 知识库 RAG 联调                                                         │
│   □ 端到端测试                                                              │
│   □ 上线 beta                                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

# Part 9: 兼容性检查清单

## AI SDK 6 特性兼容性

| AI SDK 6 特性 | 架构支持 | 实现状态 | 说明 |
|--------------|---------|---------|------|
| `useChat` Hook | ✅ | ✅ 已完成 | `useVibeChat` 基于 `useChat` |
| `UIMessageStream` | ✅ | ✅ 已完成 | `/api/chat/route.ts` 使用 `createUIMessageStreamResponse` |
| Tool Calling | ✅ | ✅ 已完成 | `ToolDefinition` 类型支持 |
| Generative UI | ✅ | ✅ 已完成 | `ToolDefinition.render` 渲染 React 组件 |
| `needsApproval` | ✅ | ✅ 已完成 | 工具定义支持审批配置 |
| `addToolResult` | ✅ | ✅ 已完成 | `useVibeChat.approveToolCall` 封装 |
| `toModelOutput` | ✅ | ✅ 已完成 | `ToolDefinition.toModelOutput` 支持 |
| Strict Mode | ✅ | ✅ 已完成 | Zod schema 自动严格 |
| MCP Support | ⚠️ | 🔜 待扩展 | 需要后续扩展 |

## V4 实现进度 (2026-01-08 更新)

### ✅ 已完成

| 任务 | 文件 | 说明 |
|------|------|------|
| Skill 插件系统 | `skills/types.ts` | 完整类型定义 |
| Registry 注册中心 | `skills/registry.ts` | Skill/Tool/Panel 统一注册 |
| BaZi Tools | `skills/bazi/tools/` | show_bazi_chart, show_kline, show_fortune |
| Zodiac Tools | `skills/zodiac/tools/` | show_zodiac_chart, show_transit, show_synastry |
| 共享 Tools | `skills/shared-tools.tsx` | show_report, show_relationship, show_insight, request_info |
| 共享 Panels | `skills/shared-panels.ts` | ChatPanel, ChartPanel, ReportPanel 等 |
| useVibeChat 更新 | `hooks/useVibeChat.ts` | `addToolResult`, `approveToolCall` |
| ChatMessage 更新 | `components/chat/ChatMessage.tsx` | `toolInvocations` 渲染, 审批 UI |
| ChatContainer 更新 | `components/chat/ChatContainer.tsx` | Tool invocations 提取和传递 |
| API Route 更新 | `app/api/chat/route.ts` | `tool-input-available`, `tool-output-available` |
| SkillProvider 更新 | `providers/SkillProvider.tsx` | Registry 集成, 主题 CSS 变量注入 |
| NavBar 更新 | `components/layout/NavBar.tsx` | 动态 Panel 加载 |
| MobileTabBar 更新 | `components/layout/MobileTabBar.tsx` | 动态 Panel 加载 |

### 🔜 待完成

| 任务 | 优先级 | 说明 |
|------|--------|------|
| MCP 集成 | P2 | 后续版本扩展 |
| 更多 Skill 插件 | P1 | MBTI, Tarot, Attach, Career |
| 后端 Tool 支持 | P1 | Python 后端返回 tool_call 事件 |

## 代码结构 (V4)

```
apps/web/src/
├── skills/                          # Skill 插件系统
│   ├── types.ts                     # ✅ 核心类型定义
│   ├── registry.ts                  # ✅ 注册中心
│   ├── shared-tools.tsx             # ✅ 共享 AI 工具
│   ├── shared-panels.ts             # ✅ 共享面板配置
│   ├── panels/
│   │   ├── ReportPanel.tsx          # ✅ 报告面板
│   │   └── RelationshipPanel.tsx    # ✅ 关系分析面板
│   ├── bazi/                        # ✅ 八字 Skill
│   │   ├── config.ts
│   │   ├── tools/
│   │   │   ├── show-bazi-chart.tsx
│   │   │   ├── show-kline.tsx
│   │   │   └── show-fortune.tsx
│   │   └── panels/
│   ├── zodiac/                      # ✅ 星座 Skill
│   │   ├── config.ts
│   │   ├── tools/
│   │   │   ├── show-zodiac-chart.tsx
│   │   │   ├── show-transit.tsx
│   │   │   └── show-synastry.tsx
│   │   └── panels/
│   └── index.ts                     # ✅ 统一导出
├── hooks/
│   └── useVibeChat.ts               # ✅ AI SDK 6 集成
├── components/
│   └── chat/
│       ├── ChatMessage.tsx          # ✅ Generative UI 渲染
│       └── ChatContainer.tsx        # ✅ Tool invocations 支持
├── providers/
│   └── SkillProvider.tsx            # ✅ Registry + 主题注入
└── app/
    └── api/
        └── chat/
            └── route.ts             # ✅ UIMessageStream
```

---

# Part 10: 参考资源

- [AI SDK 6 官方文档](https://ai-sdk.dev/docs/introduction)
- [AI SDK 6 发布博客](https://vercel.com/blog/ai-sdk-6)
- [Generative UI 教程](https://vercel.com/academy/ai-sdk/multi-step-and-generative-ui)
- [Tool Calling 文档](https://sdk.vercel.ai/docs/ai-sdk-ui/chatbot-with-tool-calling)
- [UIMessageStream 参考](https://ai-sdk.dev/docs/reference/ai-sdk-ui/create-ui-message-stream-response)

---

> **文档版本**: 4.1
> **创建日期**: 2026-01-08
> **最后更新**: 2026-01-08
> **作者**: Architecture Team
> **状态**: V4 核心架构已实现，待后端 Tool 支持后可完整测试
