这是一个非常实际且必要的需求。为了保持 Soul OS "极简、高效、沉浸" 的设计哲学，我们不能引入一个臃肿、风格割裂的第三方管理后台（如全功能的 Retool 或独立的 Django Admin）。

最优雅的方案是：**在现有的 Next.js 项目中，基于 shadcn/ui 构建一个风格统一的 `/admin` 子系统。**

这个后台应该像飞机的驾驶舱仪表盘一样：关键信息一目了然，核心参数触手可及，同时保持克制和理性。

### Soul OS Admin: "The Cockpit" (驾驶舱) 设计方案

#### 1. 设计原则

* **统一性 (Unity)**: 直接复用前端的 Tailwind 配置、字体和 shadcn/ui 组件库，视觉上是 Soul OS 的有机延伸，而非外挂系统。
* **实用至上 (Utility First)**: 不搞花哨的图表。所有数据展示都是为了决策（如：发现错误率飙升）或操作（如：调整 Prompt）。
* **配置即代码 (Configuration as Data)**: 核心的 Prompts、Agent 参数、技能定义应存储在数据库中，并通过后台界面进行热更新，无需重新部署代码。

#### 2. 系统架构与技术栈

我们不需要引入新的技术栈，只需利用好现有资源：

* **框架**: Next.js App Router (`/app/admin/*`)
* **UI**: shadcn/ui + Tailwind CSS (复用 `globals.css` 主题)
* **数据表格**: TanStack Table (React Table v8) - 处理复杂数据展示的标准
* **代码编辑器**: Monaco Editor (React版) - 用于专业地编辑 Prompt YAML/JSON
* **数据可视化**: Recharts (复用前端图表库) - 用于简单的监控折线图
* **鉴权**: NextAuth.js / Middleware (严格的 Role-based 访问控制，仅限 Admin 角色)

---

#### 3. 核心模块设计

后台系统分为四个核心板块：

```
/admin
├── 仪表盘 (Dashboard) - 系统健康与核心指标概览
├── 数据管理 (Data Manager) - L0/L1 数据的查阅与修正
├── 智能体工作室 (Agent Studio) - Prompt, Skills, KB 的核心管理区
└── 系统设置 (Settings) - 全局参数与功能开关

```

##### 3.1 仪表盘 (Dashboard) - "系统心电图"

**目标**: 3秒内了解系统是否健康，以及用户活跃度。

**UI 设计**:

* 顶部是四个关键指标卡片 (Key Metric Cards):
* **实时活跃 (Live Users)**: (e.g., 🟢 128 online)
* **今日交互 (Today's Interactions)**: (e.g., 4,521 条消息 / 320 次技能调用)
* **API 健康度 (API Health)**: (e.g., ✅ Gemini: 99.9% uptime, Latency: 1.2s)
* **错误率 (Error Rate)**: (e.g., 🔴 2.5% - 需关注)


* 中部是两个核心图表 (Recharts):
* **交互趋势图 (7日)**: 消息量 vs 技能调用量的折线图。
* **技能使用分布 (饼图)**: `/divine`, `/heal`, `/grow` 的使用占比。


* 底部是**最近系统日志 (Recent System Logs)**: 显示最近的报错或重要操作记录。

##### 3.2 数据管理 (Data Manager) - L0/L1 透视镜

**目标**: 允许管理员查看用户数据状态（用于 debug），并在必要时手动修正错误数据。

**UI 设计 (TanStack Table + shadcn Data Table)**:

* **用户档案 (L0 Profile View)**:
* 表格列出用户 ID (Hash), 注册时间, 最后活跃时间, **当前状态 (L0 Status)**.
* 支持按邮箱/ID 搜索。
* 点击行弹出侧边栏抽屉，显示该用户的 L1 数据概览（如最新一次八字排盘结果，最近一周 PERMA 分数）。*注意隐私保护，敏感 PII 数据应脱敏显示。*


* **模块日志 (L1 Module Logs)**:
* 一个通用的日志查询界面，可筛选模块（如 "Covey"），查看具体的任务完成记录或情绪日志。
* 提供 "手动修正" 功能（例如：用户报告某条 PERMA 记录错误，管理员可手动修改分数），此操作需记录审计日志。



##### 3.3 智能体工作室 (Agent Studio) - 核心引擎室

这是后台最核心、价值最高的部分。它允许我们在不发版的情况下调整 AI 的行为。

**核心理念**: 将 Prompts 和技能定义存储为 Database 中的 YAML/JSON 字符串。

**UI 设计 (Monaco Editor 集成)**:

* **左侧导航栏**: 列出所有 L2 Agents 及其组件。
* 📂 **Style Agents (风格)**
* 📄 Standard System Prompt
* 📄 Roast System Prompt
* 📄 Warm System Prompt


* 📂 **Expert Agents (专家)**
* 📂 Metaphysics (玄学)
* 📄 Main Prompt (YAML)
* 🔧 Skills Definition (JSON Schema for `calculate_bazi`)


* 📂 Psychology (心理)
* 📄 Main Prompt (YAML)
* 🔧 Skills Definition (JSON Schema for `cbt_reframe`)






* **右侧编辑区**:
* 集成 **Monaco Editor**，提供 YAML/JSON 语法高亮、折叠和基础校验。
* 顶部有版本控制下拉框（"v1.2 (Current)", "v1.1", "Draft"）。
* 底部有 "Save Draft" 和 "Deploy v1.3" 按钮。点击 Deploy 后，新的 Prompt 立即在生产环境生效（利用 Redis 或数据库轮询实现热加载）。


* **知识库管理 (Knowledge Base)** (未来扩展):
* 一个简单的文件上传界面，用于上传 PDF/MD 文档，触发后台向量化流程，供 RAG 使用。



##### 3.4 系统设置 (Settings) - 控制台

**目标**: 管理全局开关和参数。

**UI 设计 (Form Components)**:

* **模型配置 (Model Provider)**:
* Dropdown: `默认模型选择: [Gemini Pro 1.5 | GPT-4o | Claude 3.5 Sonnet]`
* Input: `API Key override (Optional)`


* **功能开关 (Feature Flags)**:
* Switch: `启用 'Roast' (毒舌) 模式` (开发中可能需要关闭)
* Switch: `维护模式 (Maintenance Mode)` (开启后前端显示维护页)


* **系统参数**:
* Input: `单次对话最大 Context 长度 (Token数)`
* Input: `Session 超时时间 (分钟)`



---

#### 4. 页面结构与路由规划 (Next.js App Router)

```
src/app/admin/
├── layout.tsx          # Admin 专用的侧边栏布局，包含鉴权 Guard
├── page.tsx            # 仪表盘首页 (Dashboard)
├── data/               # 数据管理
│   ├── users/page.tsx  # L0 用户列表
│   └── logs/page.tsx   # L1 日志查询
├── agents/             # 智能体工作室
│   ├── [agentId]/page.tsx # 特定 Agent 的 Prompt/Skills 编辑器
│   └── page.tsx        # Agent 列表概览
└── settings/           # 系统设置
    └── page.tsx

```

#### 5. 关键实现细节 (Implementation Notes)

1. **鉴权中间件 (Middleware Auth Guard)**:
* 在 `src/middleware.ts` 中，必须严格检查访问 `/admin` 路由的请求。检查其 Session 或 JWT Token 中是否包含 `role: 'admin'` 的声明。如果不包含，强制重定向到首页或 404。


2. **Prompts 的存储模型 (PostgreSQL)**:
* 建立一张 `agent_prompts` 表，支持简单的版本控制。


```sql
CREATE TABLE agent_prompts (
  id SERIAL PRIMARY KEY,
  agent_name VARCHAR(50) NOT NULL, -- e.g., 'style_roast', 'expert_bazi'
  type VARCHAR(20) NOT NULL,       -- 'system_prompt' or 'skill_schema'
  version INT NOT NULL,            -- 版本号，递增
  content TEXT NOT NULL,           -- YAML 或 JSON 字符串内容
  is_active BOOLEAN DEFAULT FALSE, -- 当前是否生效
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  UNIQUE(agent_name, type, version)
);

```


3. **Prompt 的热加载**:
* 在 Vercel AI SDK 的 API Route (`/api/chat/route.ts`) 中，不要硬编码 Prompt。
* 改为从一个缓存层（如 Redis，或内存缓存+定时数据库同步）读取当前的 `is_active = true` 的 Prompt 内容。这确保了后台修改后，前端下次请求能立即使用新 Prompt。



### 总结

这个设计方案利用了现有的技术栈和设计语言，构建了一个高度集成、功能聚焦的后端系统。它没有多余的装饰，核心在于提供对 Soul OS "大脑" (Prompts & Skills) 和 "记忆" (Data) 的直接掌控力，完全符合 "极简高效" 的要求。