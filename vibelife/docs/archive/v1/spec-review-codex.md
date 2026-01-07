# VibeLife Spec v2.0 / v2.1 Review & Test Report

基于 `mentis/docs/archive/vibelife spec v2.0.md` 与 `mentis/docs/archive/vibelife spec v2.1.md` 对 `vibelife/` 做的对照审查与可运行性测试记录（偏工程验收视角）。

## 已验证（可运行）

### Backend (FastAPI)
- 健康检查：`GET /health`、`GET /` 正常返回
- 认证：`/api/v1/auth/*`（register/login/refresh/me/logout）接口结构齐全
- Chat：`/api/v1/chat/*`（含 `guest` 与 `stream`）可用（`guest` 已处理 GLM reasoning 导致 content 为空的问题）
- Reminders：`/api/v1/reminders/*` 路由可加载（事件/设置/通知）
- Mirror：`/api/v1/mirror/*`（weekly sign 等）可返回默认内容
- Billing：`/api/v1/billing/*` 可返回预置 plans/paywall 结构

### Frontend (Next.js)
- 主站与 3 个 Skill Landing：`/`、`/bazi`、`/zodiac`、`/mbti`
- Chat：`/bazi/chat`、`/zodiac/chat`、`/mbti/chat`（未登录时自动走 guest 模式）
- Auth：`/auth/login`、`/auth/register`
- About：`/about`

## 自动化测试结果

### API 单测
- `vibelife/apps/api`：`pytest` 34/34 通过

### Web 构建检查
- `vibelife/apps/web`：`pnpm typecheck` 通过
- `vibelife/apps/web`：`pnpm build` 通过

### E2E 冒烟（无 GUI 环境）
- Playwright 必须 headless（容器无 X Server）
- 脚本走 UI 路由与 chat UI（guest chat 采用 mock，避免外部 LLM 不确定性）
- 截图输出：
  - `/tmp/vibelife-bazi-chat.png`
  - `/tmp/vibelife-zodiac.png`
  - `/tmp/vibelife-mbti.png`

## 关键问题（已修复）

### Backend 运行/导入问题
- `stores.db` 增加 `get_db_pool()` 兼容别名，修复 reminders/mirror/billing 路由引用
- `services.identity` 导出 `CurrentUser`，修复 chat/auth 等依赖注入导入
- `services.vibe_engine` 导出 `LLMMessage`，修复 guest chat 构造消息
- 修复 `services/agent/persona.py` 的字符串字面量语法错误
- 补齐 bazi 工具与测试/服务期望的接口适配：
  - `BaziCalculator.generate_chart()`
  - `BaziTransitCalculator`
  - `BaziAnalyzer`
- `apps/api/main.py` 启动时自动加载 `vibelife/.env`（若存在），避免环境变量缺失导致服务行为异常
- `chat/guest` 增大 token budget 并加入兜底，避免 GLM 先输出 reasoning 导致 `content` 为空

### Frontend 路由/构建问题
- 修复首页 CTA 路由：`/login` → `/auth/login`
- 增补缺失页面：`/about`、`/zodiac`、`/mbti`、以及 3 个 skill chat 页面
- 修复动态 Tailwind class（`bg-${color}-600`）导致 production build 不稳定的问题
- 未登录聊天自动降级为 guest chat（符合 “价值前置 / 渐进注册” 的体验要求）
- 移除首页与八字页的 framer-motion 首屏隐藏（避免无交互环境下页面不可见）
- 增加 `apps/web/.eslintrc.json`，让 `next lint` 非交互可运行

### 文档与安全
- `vibelife/.env.example` 与 `vibelife/docs/config.md` 已去除明文密钥/密码（保留在本机 `.env` 中即可）

## 与 v2.0 / v2.1 的差距（重点）

以下为“规格中明确提到、但当前实现仍明显缺失/未闭环”的项目（优先级从高到低）：

1. **工具调用闭环（Skill Tools in Agent Pipeline）**
   - `AgentRuntime._invoke_tool()` 仍是空实现；八字/星座/MBTI 工具虽存在，但未接入对话流程
2. **Vibe ID 站点与跨站 SSO 闭环**
   - `apps/id` 为空；前端也缺少 `sso-callback` 等页面/跳转链路验证
3. **Insight Cards 全链路**
   - 后端有 `InsightGenerator` 与基础数据表，但前端未集成展示/保存/分享；触发规则与 UI 仍未联动
4. **Proactive Reminder System 生产化**
   - 有事件表/设置/通知服务与 API，但缺少定时调度（cron/队列）、push/wechat 等投递实现与权限收敛
5. **Knowledge Layer 生产可用性**
   - embedding/retrieval 依赖外部服务；向量写入/检索在 Postgres 的 `vector` 适配与索引/数据管道需要进一步验证
6. **共享 UI 包与多站点生成**
   - `packages/ui` 目录目前为空，尚未形成 “统一体验标准层” 的可复用组件库与站点模板引擎

## 建议下一步（Phase 1 最小闭环）

1. 在 `AgentRuntime._invoke_tool()` 里把 **bazi 排盘 + 基础分析** 接起来，形成 “输入出生信息 → 工具计算 → LLM 解读” 的闭环
2. 把 guest landing 的出生信息输入改为 **真正调用后端工具**（即使不登录也能体验）
3. 补齐 `apps/id`（或先用 `apps/web` 承担 SSO callback）做一次跨站 token 兑换端到端验证
4. 将 reminder 初始化与每日扫描任务做成可部署的 cron（先落库 in-app 通知即可）

