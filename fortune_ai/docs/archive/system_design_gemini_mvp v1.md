# Fortune AI 系统设计 (Gemini MVP v1)
**项目名称**: Fortune AI - 精神数字孪生与 Soul OS
**日期**: 2025-12-30
**基于**: `bp v1.md` (商业计划书) & `system_design_codex_v5.md` (技术底座)
**状态**: 草稿 (Draft)

---

## 1. 执行摘要 (Executive Summary)

本文档定义了 **Fortune AI MVP** 的技术架构。核心目标是将用户的心理与玄学数据转化为一个可视化的、游戏化的互动实体——**精神数字孪生 (Spiritual Digital Twin)**。

**核心架构升级**:
不同于传统的 Web 请求/响应模式，本版本采用 **Agent-Centric (智能体为中心)** 架构，利用 **Vercel AI SDK** (`github.com/vercel/ai`) 实现真正的 "Soul OS" 体验。系统支持实时流式对话、生成式 UI ("功能显化") 以及多模态交互。

**主要技术栈**:
*   **前端 (Soul OS)**: Next.js + Vercel AI SDK (React Server Components)。
*   **后端 (引擎)**: Python (FastAPI) + PostgreSQL (SSOT)。
*   **智能体协议**: Vercel Data Stream Protocol (流式数据协议)。

---

## 2. 顶层架构 (High-Level Architecture)

系统采用 **混合智能体架构 (Hybrid Agentic Architecture)**：

*   **前端 (Client)**: 负责渲染 "孪生" 形象，处理实时对话，以及渲染由 AI 动态生成的 UI 组件 (Generative UI)。
*   **后端 (Backend)**: 负责重计算 (八字/星盘)、数据持久化，以及作为 Agent 的大脑调度器。
*   **数据层 (Data)**: 沿用 `Codex v5` 的稳健设计，以 PostgreSQL 为单一事实来源 (SSOT)。

```mermaid
graph TD
    User[用户] -->|交互| Client[Next.js 前端 / Vercel AI SDK]
    
    subgraph "Soul OS (客户端层)"
        Client -->|流式文本/UI| ChatUI[对话界面]
        Client -->|渲染组件| GenUI[生成式 UI 卡片 (显化)]
        Client -->|可视化| TwinVis[3D/2D 孪生渲染]
    end

    subgraph "Edge/中间件 (Vercel)"
        NextAPI[Next.js API Routes] -->|鉴权 & 限流| Auth[Auth.js]
        NextAPI -->|转发请求| PythonAPI
    end

    subgraph "引擎 (Python 后端)"
        PythonAPI[FastAPI 网关 (Stream 兼容)]
        
        PythonAPI -->|调用| AgentRouter[智能体路由]
        
        subgraph "智能体核心 (Agent Core)"
            Coach[Coach Agent (L2 - 对话教练)]
            Analyst[Analyst Agent (L2 - 后台分析)]
            Social[Social Agent (L2 - 社交连接)]
        end
        
        AgentRouter --> Coach
        AgentRouter --> Analyst
        
        Coach -->|Tool Call| CalcEngine[计算引擎 (八字/星盘)]
        Analyst -->|Update| UserState[用户状态更新]
    end

    subgraph "数据层 (PostgreSQL SSOT)"
        PythonAPI --> DB[(PostgreSQL)]
        CalcEngine --> KB[知识库 (FTS/Vector)]
        
        %% 引用 Codex v5 的表结构
        DB --> T_User[fortune_user]
        DB --> T_Job[fortune_job]
        DB --> T_State[fortune_user_state]
        DB --> T_Content[fortune_content_item]
    end
```

---

## 3. 智能体系统 (基于 Vercel AI SDK)

为实现 BP 中描述的 **双模式交互 (Dual-Mode Interaction)**，我们将使用 Vercel AI SDK 的核心能力。

### 3.1 技术选型
*   **SDK 核心**: `ai` (Node.js/Edge) 用于前端，`ai-sdk-python` (或兼容协议) 用于 Python 后端。
*   **通信协议**: **Vercel Data Stream Protocol**。Python 后端将流式传输文本、工具调用 (Tool Calls) 和生成式 UI 数据。

### 3.2 智能体模式与实现

#### A. 聊天模式 (Chat Mode - "咨询室")
*   **功能**: 深度、共情的对话，具备长期记忆。
*   **实现**:
    *   前端使用 `useChat()` hook 连接后端。
    *   后端 Agent 配置 `system_prompt`，动态注入用户的 **L1 元数据** (八字格局、MBTI) 和 **L2 实时状态** (今日运势、能量值)。
    *   **记忆**: 使用 RAG (检索增强生成) 检索 `fortune_conversation_session` 中的历史上下文。

#### B. 功能模式 (Function Mode - "显化控制台")
*   **核心差异**: **生成式 UI (Generative UI)**。
*   **场景**: 用户说 "我最近很倒霉"，AI 不仅仅是安慰，而是直接在对话流中渲染一个 **[3分钟能量重启]** 的交互卡片。
*   **流程**:
    1.  Agent 识别意图，触发 `suggest_intervention` 工具。
    2.  后端计算并返回结构化数据 (JSON)。
    3.  前端 `tool-call` 收到数据，渲染 React 组件 (e.g., `<EnergyBoosterCard data={...} />`)。

### 3.3 后端智能体服务

1.  **Coach Agent (`services/agents/coach.py`)**:
    *   **职责**: 主对话接口，负责理解意图并调用计算工具。
    *   **工具箱**: `get_bazi_chart` (排盘), `get_daily_guidance` (今日指引), `search_psych_kb` (心理学知识库)。

2.  **Analyst Agent (`services/agents/analyst.py`)**:
    *   **职责**: 后台运行的 "观察者"。利用 `fortune_job` 队列异步处理对话日志。
    *   **行为**: 提取对话中的关键情绪、事件，更新用户的 **孪生状态 (User State)**。
    *   **输出**: 更新 `fortune_user_state` 表 (e.g., `mood_score`, `energy_level`)。

---

## 4. 数据架构 (数字孪生模型)

参考 `codex_v5` 的稳健设计，并适配 BP 的 "数字孪生" 需求。

### 4.1 L1: 元数据层 (Metadata - Static)
*   **核心**: 出生信息 (Time, Location)。
*   **衍生数据**: 八字命盘 (JSON)、紫微斗数、MBTI。
*   **存储**: `fortune_user` 表 + `fortune_bazi_snapshot` 表 (确定性计算快照)。

### 4.2 L2: 动态状态层 (Dynamic State - The "Health Bar")
这是 "数字孪生" 的核心，通过 **时间序列** 追踪用户的精神状态。
*   **指标**:
    *   `energy_level` (0-100): 综合睡眠、步数、星象流年。
    *   `mood_trend`: 基于对话情感分析。
    *   `luck_score`: 基于 `fortune_daily_context` (节气/流日)。
*   **存储**: 新增 `fortune_user_state` 表。
    ```sql
    create table fortune_user_state (
      user_id bigint not null,
      timestamp timestamptz not null default now(),
      metric_type text not null, -- 'energy', 'mood', 'luck'
      value numeric not null,
      source text, -- 'chat_analysis', 'bazi_calc', 'manual_checkin'
      primary key (user_id, metric_type, timestamp)
    );
    ```

### 4.3 核心业务表 (引用 Codex v5)
*   **`fortune_daily_context`**: 存储每日的节气、星象事实，作为全平台统一的 "天气预报"。
*   **`fortune_job`**: 异步任务队列，用于处理 Analyst Agent 的分析任务、推送任务等。
*   **`fortune_content_item`**: 存储生成的 "显化卡片" 内容，确保同一天生成的指引可复现、可追溯。

---

## 5. 实施路线图 (MVP)

### 第一阶段: 基础引擎 (The Engine)
*   [ ] **API 重构**: 将 `services/bazi_engine.py` 封装为 **AI Tools** (Function Calling 格式)。
*   [ ] **流式协议**: 在 `api/main.py` 中实现 Vercel Data Stream Protocol 兼容的 Endpoint。
*   [ ] **数据库**: 部署 `Codex v5` 定义的核心表结构 (`fortune_job`, `fortune_daily_context` 等)。

### 第二阶段: Soul OS (Frontend)
*   [ ] **脚手架**: 初始化 `fortune-web` (Next.js 15 + Tailwind)。
*   [ ] **对话 UI**: 集成 `useChat`，联通 Python 后端。
*   [ ] **显化卡片**: 开发首批生成式 UI 组件:
    *   `DailyFortuneCard` (今日运势)
    *   `ActionPrescription` (行动处方)
    *   `CheckInCard` (状态打卡)

### 第三阶段: 注入灵魂 (Active Agents)
*   [ ] **Analyst Loop**: 实现基于 `fortune_job` 的后台分析器，从对话中提取数据更新孪生状态。
*   [ ] **记忆系统**: 集成简单的向量检索，让 Agent "记得" 用户的历史承诺。

---

## 6. 目录结构提案

```
fortune_ai/
├── api/                  # Python Backend (FastAPI)
│   ├── main.py           # 入口 (Vercel Stream Compatible)
│   ├── agents/           # 智能体定义
│   │   ├── coach.py      # 对话 Agent
│   │   └── analyst.py    # 分析 Agent
│   └── tools/            # 暴露给 Agent 的工具
│       ├── bazi.py       # 八字计算工具
│       └── memory.py     # 记忆检索工具
├── services/             # 核心业务逻辑 (现有代码)
│   ├── bazi_engine.py
│   ├── task_service.py   # 适配 fortune_job
│   └── ...
├── web/                  # [NEW] Next.js 前端 (Soul OS)
│   ├── app/
│   │   ├── api/chat/     # Edge Proxy
│   │   └── page.tsx      # 主界面
│   ├── components/       # UI 组件
│   │   ├── generative/   # 生成式 UI 卡片
│   │   │   ├── fortune-card.tsx
│   │   │   └── energy-booster.tsx
│   │   └── twin-avatar.tsx
│   └── lib/              # Vercel AI SDK 配置
└── ...
```