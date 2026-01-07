# Fortune AI → Mentis OS v3.0 全量重构计划（Codex）

> 约束：视觉元素保持现状（现有品牌/字体/色板/组件气质不换）；交互范式、系统架构、数据模型、API、算法、部署与路线图严格遵循 Mentis OS v3.0 文档（`MENTIS OS part1.md` + `Mentis OS part2.md`）。

---

## 0. 一句话目标

把当前 **Chat + Dashboard** 的 Fortune AI，升级为 **Stream-Centric Agentic Personal OS**：  
**“Life is a Stream, not a Dashboard.”** —— 生活流成为输入，进化成为输出；Dashboard 退居背景，Agent 主动干预成为灵魂。

---

## 1. Mentis OS 的不可变设计原则（必须逐条落地）

### 1.1 三层交互模型（Three-Layer Interaction Model）

- **Layer 1：The Stream（核心交互区，90% 时间）**
  - Vibe Diary（碎碎念/情绪日记）是最高频入口
  - Action Cards（Agent 主动推送的任务卡）与 Chat 都“融入流中”
  - 每次输入必须产生**即时微反馈**：AI Tag / 能量变化 / Aura 变化
- **Layer 2：The HUD（Ambient HUD，环境感知层）**
  - Dashboard 不再是独立页面，而是**围绕 Stream 的背景环境层**
  - 常态隐形，以 Dynamic Aura、边缘微光、数字浮动/粒子等方式被动呈现
  - 仅在状态剧烈变化或用户呼出时显现
- **Layer 3：The Intervention（主动干预层）**
  - Agent 不等待提问，基于 Stream + 模块数据 + 时间节点主动插入 Action Cards
  - 触发条件：时间节点 / 情绪阈值 / 能量变化 / 行为模式 / 运势窗口

### 1.2 产品功能矩阵（STREAM / DECODE / REFRAME / EVOLVE / REFLECT）

- **STREAM**：Voice/Text/Photo 入口 + 结构化沉淀 + 即时反馈
- **DECODE**：BaZi / ZiWei / MBTI / Jung / Fortune（日运等）
- **REFRAME**：CBT / ACT / NLP 重构（识别→重述→练习→追踪）
- **EVOLVE**：习惯处方 / If-Then / Momentum / Streak / Auto Checkin
- **REFLECT**：Weekly Mirror / Insight / Pattern Detection

### 1.3 核心链路必须事件化（Event-Driven）

Mentis 的核心 API（`POST /stream`）以 **SSE** 形式返回一串确定事件序列（示例）：

1) `stream_created` → 2) `extraction_complete` → 3) `state_update` → 4) `behavior_match`（可选） → 5) `agent_response`（可选） → 6) `done`

这意味着：**前端不是等待“一个回答”，而是在消费“一个处理过程”**。

---

## 2. 现状盘点（fortune_ai 代码层面真实结构）

### 2.1 当前系统形态

- **Web（Next.js）**：`fortune_ai/web-app`
  - 现为 DualCoreLayout：ChatZone + DashboardZone（仍是 v2 范式）
  - 已接入 Vercel AI SDK 流式：`src/app/api/chat/route.ts`
  - 已具备“Magic Input/Omnibar”（含语音/图片入口 UI 雏形）
  - 视觉系统已成型：`src/app/globals.css`（Notion Zen / Ethereal Earth Tones / glassmorphism / capsule）
- **Backend（FastAPI）**：`fortune_ai/api` + `fortune_ai/services`
  - 提供 auth / dashboard / bazi / report / internal context 等
  - 内部接口用于 Next.js Agent Runtime：`/internal/context`、`/internal/chat/run/*`
- **数据层（PostgreSQL）**
  - 以 SQL 文件迁移为主：`fortune_ai/migrations/*.sql`
  - 核心表：`fortune_user`、`fortune_conversation_*`、`fortune_commitment`、`fortune_checkin`、`fortune_reflection` 等
- **遗留 Agent Service（Express）**：`fortune_ai/agent_service`
  - 与当前 Next.js Agent Runtime 能力重叠（应纳入淘汰计划）

### 2.2 “必须保留”的视觉元素（Freeze 清单）

以代码为准，冻结并在 Mentis UI 重构中复用：

- 设计 token：`fortune_ai/web-app/src/app/globals.css`
  - 背景纸感、前景炭色、卡片阴影、glassmorphism、圆角体系、字体组合等
- 关键组件气质
  - Landing 的 orb/portal（`src/components/landing/*`）
  - Input Capsule（`input-capsule` 样式与交互）
  - 卡片体系（Card + soft border + shadow-floating）
- 品牌资源：`fortune_ai/web-app/public/assets/*`（logo 等）

> 解释：Mentis OS 文档给的是交互结构与系统机制；视觉层可以在不改变这些机制的情况下，继续沿用当前的“Notion Zen / Ethereal Earth Tones”审美。

---

## 3. 目标架构（Mentis OS v3.0 落地到代码组织）

### 3.1 目标系统分层（对齐文档的系统架构图）

- **Client Layer**
  - Web（Next.js）先完成 v3.0；移动端（RN/Taro）后续按 v3.1+ 推进
- **API Gateway（Edge/Workers）**
  - Auth / Rate Limit / Routing / Logging / CORS
  - Web 先以 Next.js Middlewares + Edge Functions 近似实现；后续可迁 Cloudflare Workers
- **Agent Runtime Layer（Next.js API Routes + Vercel AI SDK）**
  - `POST /v3/stream`：Stream Processor + Agent Runtime 多步推理（`maxSteps: 5`）
  - 动态 tool registry：DECODE / REFRAME / EVOLVE / SYSTEM
- **Data Layer**
  - Postgres（Primary）/ Redis（State/Cache）/ Pinecone（Vector）/ R2/S3（Media）
- **Realtime**
  - WebSocket：Pusher Channels
  - Push：FCM；Email：Resend（按文档）

### 3.2 代码仓库重构建议（最终形态）

目标：把“领域模型/算法/协议”从“表现层/框架代码”中剥离，避免继续膨胀为不可维护的混合体。

推荐收敛为单一 Mentis OS 主干（保留现有可用资产，逐步淘汰旧实现）：

- `fortune_ai/web-app`（保留，升级为 Mentis Web）
  - `src/app/(mentis)/...`：Stream/HUD/Module 页面
  - `src/app/api/v3/...`：Mentis v3 API（Next.js Runtime）
  - `src/lib/mentis/*`：流处理、状态机、事件协议、tool registry
- `fortune_ai/services`（短期保留，作为“可迁移算法库”）
  - BaZi / ZiWei 等若已稳定，第一阶段通过内部调用复用；第二阶段再迁移到 TS/Drizzle 体系
- `fortune_ai/api`（逐步退役）
  - 仅保留过渡期的兼容 API 与内部算法服务入口
- `fortune_ai/agent_service`（淘汰）
  - 迁移其 agent 逻辑到 Next.js API Routes；完成后关闭

> 原则：**先把交互范式改成 Stream + HUD + Intervention，再逐步迁移语言/框架。** 否则会陷入“改技术栈但交互仍是 v2”的低价值重构。

### 3.3 技术栈对齐（按 Mentis OS part2）与过渡策略

Mentis v3.0 目标技术栈（文档定义）：

- **Frontend**
  - Next.js 14（App Router）+ TypeScript
  - Tailwind CSS + Framer Motion
  - Zustand + TanStack Query
  - React Hook Form + Zod
  - Radix UI + shadcn/ui
- **Backend**
  - Next.js API Routes + Vercel Functions（作为主 Runtime）
  - Vercel AI SDK（Agent Runtime，多步推理）
  - Drizzle ORM + Drizzle Migrations
  - NextAuth.js v5 + JWT（Bearer Token）
  - Upstash QStash（后台作业）
- **Data/Infra**
  - Neon PostgreSQL、Upstash Redis、Pinecone、Cloudflare R2（S3 compatible）
  - Monitoring：Sentry；Analytics：Vercel Analytics

过渡策略（避免“换栈优先”的陷阱）：

1) **v3.0 交互先行**：先让 Web 的主屏变为 Stream + HUD，并跑通 `POST /v3/stream` 的事件闭环  
2) **Runtime 渐进**：Next.js API 先“包住”现有 FastAPI/算法库（内部调用），保证功能连续  
3) **再迁移数据与 ORM**：逐步把新表/新链路收敛到 Drizzle schema（旧 SQL migrations 只读/归档）  
4) **最后退役 FastAPI/Express**：当 v3.0+ 的关键链路完全由 Next.js Runtime 承担后，再关闭遗留服务

---

## 4. 数据模型重构（Mentis ERD → 可迁移方案）

### 4.1 Mentis v3.0 核心实体（必须建立）

以文档 ERD/DDL 为准，核心表至少包含：

- `mentis_user`
- `user_profile`（birth_time、birth_location、bazi/ziwei 缓存、mbti/jung、preferences、notification_settings）
- `user_state`（energy_score、momentum、streak_days、current_mood、aura_state、last_active_at…）
- `stream_entry`（type、raw_content、emotion、context、tags、energy_delta、embedding_id、matched_behavior…）
- `action_task`（suggestion/习惯/任务；status；trigger_time/expires_at；momentum_reward…）
- `checkin_log`（行为打卡日志：behavior_type、source、momentum_delta…）
- `insight_record`（洞察沉淀：weekly mirror、pattern、fortune insight 等）

### 4.2 从现有 Fortune 表迁移映射（最低可行迁移）

建议“并行新表 + 渐进迁移”，避免一次性断腕：

- `fortune_user` → `mentis_user`
  - email/name/tier：新增 tier（按旧系统的订阅/权限映射或默认 free）
- `fortune_user_preferences` → `user_profile.preferences + notification_settings`
- `fortune_conversation_session/message` → `stream_entry(type='chat')`
  - 旧对话可批量转为 Stream 卡片（保留 created_at，写入 tags=[#Chat]）
- `fortune_commitment` → `action_task`
  - status 映射：suggested/active/done/skipped/canceled
- `fortune_checkin` → `checkin_log`
- `fortune_reflection` → `insight_record(type='reflection')`
- `fortune_bazi_snapshot` → `user_profile.bazi_data`（保留快照表用于追溯亦可）

### 4.3 迁移步骤（可回滚的 Cutover）

1) **建立 Mentis 新 schema**（不影响旧功能）
2) **Backfill**：把旧数据导入新表（一次性脚本 + 校验）
3) **双写阶段**：旧链路写旧表同时写新表（或由 CDC/触发器/应用层写入）
4) **新 UI 切流**：Stream UI 读取 `stream_entry` + `user_state`
5) **关闭旧写入**：旧表只读保留一段时间；最终归档/移除

---

## 5. API 重构（严格按 Mentis v3.0）

### 5.1 路由与版本化

- 新增 `/v3` 命名空间（文档要求）：`BASE URL: .../v3`
- 关键公共端点（摘自文档，必须齐全）
  - `/auth/register` `/auth/login` `/auth/refresh` `/landing/quick-insight`
  - `/stream`（POST SSE + GET 历史 + GET 单条 + DELETE）
  - `/decode/*` `/reframe/*` `/evolve/*`
  - `/user/state`
  - `/realtime`（WebSocket）

### 5.2 统一错误格式与错误码

所有 API 返回：

```ts
{ "error": { "code": string, "message": string, "details"?: any, "request_id": string } }
```

错误码集合按文档（auth/permission/resource/validation/rate-limit/server）。

### 5.3 `POST /stream` 的落地要求（SSE 事件契约）

后端必须按文档事件序列逐步推送（至少实现到 `state_update`，其余可灰度）：

- `stream_created`：写入 `stream_entry` 基础行
- `extraction_complete`：写入 emotion/context/tags/energy_delta
- `state_update`：更新 `user_state`（energy_score/momentum/aura_state）
- `behavior_match`（可选）：命中任务/行为库，触发 auto_checkin 与 `checkin_log`
- `agent_response`（可选）：生成 Action Card → 写入 `action_task` 并返回卡片
- `done`

### 5.4 认证 / 权限 / 版本 / 限流（必须对齐文档）

- **认证**：Bearer Token（JWT）
  - Web：NextAuth v5 负责登录与 JWT 签发（Cookie 仅作为 Web 会话载体；对外 API 仍以 Bearer 为准）
  - Mobile/第三方：直接走 Bearer Token
- **权限**：按 user tier（free/pro/premium）控制
  - tool registry 动态裁剪（未开通模块不加载对应 tools）
  - 高阶模块（如 ZiWei、Weekly Mirror、Photo Vision）按 tier/订阅解锁
- **版本化**：所有新能力走 `/v3/*`；旧 `/api/*` 过渡期保留为兼容层（最终收敛）
- **限流**：在 Edge/Gateway 层做 tier-based rate limit（并输出统一 `request_id` 便于追踪）

---

## 6. Stream Processor + Agent Runtime（Mentis 的“引擎室”）

### 6.1 Stream Processor 管线（按文档）

输入（Voice/Text/Photo）→ 预处理 → 结构化提取 → 校验评分 → 写库/推送：

- **Voice**：Whisper STT → 文本
- **Text**：直接进入 NLP Extract
- **Photo**：Vision API → 文字描述/实体 → 合并入结构化输出

结构化输出（文档 schema）：

- `emotion`: `{primary,intensity,secondary[]}`
- `context`: `{scene,trigger,target,time_of_day}`
- `tags`: `string[]`
- `energy_delta`: `int`

### 6.2 行为匹配（NLU → Auto Checkin）

按文档阈值：

- 先匹配 pending tasks（阈值 `0.80`，`>=0.85` 可自动确认）
- 再匹配 Pinecone `behavior_library`（`>=0.85` 自动；`0.60-0.85` 弹确认卡；`<0.60` 忽略）

副作用：

- 写入 `checkin_log`
- 更新 `user_state.momentum` / `streak_days`
- 推送 `state_update` 与（可选）`task_push`

### 6.3 Agent Runtime（Vercel AI SDK Multi-step）

必须实现：

- `selectModel(userTier)`：多模型路由（GPT/Claude/GLM）
- `buildContext(userId)`：L0 + L1 + Biography + Current State + 相关记忆（向量检索）
- 动态工具加载：
  - DECODE：bazi/ziwei/fortune/mbti…
  - REFRAME：cbt_identify/reword_negative/act_exercise…
  - EVOLVE：habit_suggest/checkin_auto/momentum_update/ifthen_create…
  - SYSTEM：user_state_update/notification_push/insight_generate…
- `maxSteps: 5`，并在每步回调里落库/发事件（可只做日志 → 再升级为事务）

> 交易一致性建议：参考当前 FastAPI `/internal/chat/run/start|finalize` 的思路，把“流式输出”与“副作用提交”解耦为可原子化的 finalize 阶段（避免半写入）。

---

## 7. Realtime 同步与通知（按文档）

### 7.1 WebSocket Channel 设计

`wss://.../v3/realtime?token={jwt}`

- 订阅 channel：`['stream','state','tasks','insights']`
- Server message types：`stream_new/state_update/aura_change/task_push/insight_ready`

### 7.2 触发点

- `state_update`：每次 `POST /stream` 处理完成必须广播（P95 < 100ms）
- `task_push`：Agent 主动干预或定时触发（morning/afternoon/evening + 运势窗口）
- `insight_ready`：Weekly Mirror 等后台作业完成推送

### 7.3 后台作业（QStash）

把超过 1-2s 的流程拆到后台：

- 周报/镜像报告生成
- 大规模向量回填、行为库训练/更新
- 多模态（图片/语音）耗时推理

### 7.4 性能指标与可观测性（按文档 SLO/SLI）

必须把 Mentis OS part2 的指标变成“可观测的工程约束”：

- **可用性**：Core API 99.95% uptime；WebSocket 99.5% uptime
- **延迟（P95）**：
  - Stream Input → First Response `< 500ms`
  - Stream Input → Complete Processing `< 3000ms`
  - Emotion Detection `< 300ms`；Behavior Match `< 200ms`；State Broadcast `< 100ms`
- **错误率**：5xx `< 0.1%`；AI service failures `< 0.5%`

落地手段：

- 所有请求生成并回传 `request_id`（SSE/WebSocket 事件也携带）
- 结构化日志 + 基础 trace（至少覆盖 `/v3/stream` 全链路）
- Sentry：后端函数异常、前端崩溃、关键性能指标（TTFB/First Response）

---

## 8. 前端重构（保持视觉元素，但交互严格 Mentis）

### 8.1 信息架构：从 DualCore → Stream + HUD

当前：`DualCoreLayout(ChatZone, DashboardZone)`  
目标：`StreamScreen(StreamFeed + MagicInput + AmbientHUD + ActionCards)`

关键改造：

- **Chat Message List** → **Stream Feed（卡片时间线）**
  - 用户卡：Vibe Diary / Chat
  - Agent 卡：行动卡/确认卡/洞察卡/里程碑卡
- **DashboardZone** → **HUD Overlay**
  - 平时隐形；状态变化/用户呼出时以轻量层呈现
  - 复用现有 Tabs 内容，但入口从“侧栏主战场”降级为“环境层”

### 8.2 Dynamic Aura System（视觉保持 + 机制照抄）

机制按文档（calm/alert/happy/anxious/flow + 2s transition），但颜色/质感要用现有 token 做映射：

- 以现有 `--element-*`、`--accent`、`--orb-*`、glass/blur/shadow 体系生成 Aura 渐变
- 不引入新“赛博霓虹”风格，保持纸感与柔和光晕

### 8.3 Magic Input（零摩擦输入）

复用现有 `Omnibar` 的 capsule 视觉与交互节奏，升级为：

- 长按录音 → Whisper → `POST /v3/stream`（type=vibe_diary, media=audio）
- 拍照/上传 → R2/S3 → `POST /v3/stream`（media=image）
- 文本输入 → `POST /v3/stream`
- SSE 消费事件：即时更新 Feed / 能量条 / Aura / 待办卡

### 8.4 Action Cards（交互契约）

至少实现文档 Type 1/2：

- Suggestion Card：长按完成 + 进度条 + 动量奖励
- Confirmation Card：是/不是/设置提醒（触发 checkin/task）

---

## 9. 里程碑（对齐文档 v3.x Roadmap）

> 以“可上线的 v3.0 MVP”为第一目标；后续按 v3.1/3.2/3.3 推进。

### 9.1 v3.0 MVP（Month 1-2）—— 必须完成

- Core Stream Architecture（`POST /v3/stream` SSE 事件完整闭环）
- Vibe Diary Input（Voice + Text）
- Basic Emotion Detection + `energy_delta`
- Dynamic Aura System（HUD 背景层）
- Simple Action Cards（Suggestion + Confirmation）
- BaZi Daily Fortune（DECODE 基础）
- Momentum Tracking（`user_state` + `checkin_log` + streak）

验收口径（按文档 SLO）：

- P95：Input→First Response `< 500ms`
- P95：Input→Complete Processing `< 3000ms`

### 9.2 v3.1 Enhancement（Month 3-4）

- NLU Auto Checkin（embedding + Pinecone 行为库）
- Proactive Agent Intervention（定时/阈值触发）
- ZiWei 集成
- Weekly Mirror Report
- Photo Input + Vision

### 9.3 v3.2 Intelligence（Month 5-6）

- CBT Module（Cognitive Reframe）
- MBTI 集成
- Advanced Behavior Matching
- Habit Prescription（个性化微习惯）
- 跨设备同步、通知优化

---

## 10. 风险与控制（工程视角）

- **一次性技术栈迁移风险**：先完成 Stream 范式改造，再迁移 FastAPI→Next.js/Drizzle；避免“换栈但不换交互”
- **数据迁移风险**：采用并行新表 + backfill + 双写 + 切流，确保可回滚
- **实时链路复杂度**：v3.0 先以 SSE + 轮询兜底；v3.1 再上 Pusher 全量
- **AI 依赖不稳定**：按文档做多模型路由与降级（GPT/Claude/GLM），并对 emotion/behavior 抽取做 deterministic 校验

---

## 11. 立即可执行的“第一周 TODO”（最小闭环）

1) 建立 Mentis v3 数据表（`mentis_user/user_profile/user_state/stream_entry/action_task/checkin_log/insight_record`）并确定迁移/回滚策略
2) 建立 `/v3/auth/*` 骨架（JWT 签发与校验）+ 统一 `request_id` 与错误格式
3) 新增 `POST /v3/stream`（先做：`stream_created`→`extraction_complete`→`state_update`→`done`）
4) 前端新增 StreamFeed 原型（复用现有 card/omnibar 视觉），消费 SSE 事件更新 UI
5) HUD：实现 Aura 背景层与状态机（只做 calm/alert 两态也可）
6) 打通最小动量：`checkin_log` 写入 + `user_state.momentum/streak` 更新

---

## 12. 附录：环境变量（按文档）

以 Mentis OS part2 的 env 列表为准，核心包括：

- `DATABASE_URL` / `DATABASE_URL_UNPOOLED`
- `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN`
- `PINECONE_API_KEY` / `PINECONE_ENVIRONMENT` / `PINECONE_INDEX`
- R2/S3、LLM、Whisper、Embedding、Pusher、FCM、Resend、Sentry 等

---

> 本文件是“重构路线图/架构落地清单”，不是实现代码。后续每个里程碑建议拆成一组 ADR（Architecture Decision Records）+ 可执行任务列表（按模块/表/接口/页面/事件契约拆分），并用 A/B 或 feature flag 做渐进切流。
