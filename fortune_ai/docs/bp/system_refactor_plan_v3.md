# Fortune AI 系统彻底重构方案（v4.0 Evolutionary Memory 落地）

**适用范围**：以 v4.0（Hot/Cold Path + Insight Agent + Postgres SSOT + A2UI + Commitment）为目标，基于以下最新文档对齐并输出可执行重构路线：
- `fortune_ai/docs/os/os_design_v3.md`
- `fortune_ai/docs/os/modul_core_v3.md`
- `fortune_ai/docs/frontend/frontend_final_v3.md`
- `fortune_ai/docs/architech/system_design_final_mvp_v3.md`
- `fortune_ai/docs/GLOSSARY.md`（术语/API/错误码/动作枚举 SSOT）

> **一句话目标**：把“文档里的 v4.0 架构”重构成**边界清晰、可插拔、可观测、可演进**的实现，并用分阶段迁移保证持续可用。

---

## 0. 重构准则（SSOT + 可验收）

### 0.1 SSOT 约束（硬规则）

- **Data SSOT**：业务数据只写 `fortune_ai` PostgreSQL；禁止写本地文件作为业务事实（包含外部任务 prompt/output 日志）。
- **Spec SSOT**：`fortune_ai/docs/GLOSSARY.md` 是术语/端点/错误码/动作枚举的唯一来源；其他文档只引用，不重复定义口径。
- **Loop SSOT**：每次交互必须落到 `Commitment`（suggested→active→done/skipped）；`WCG` 可 SQL 判定（见 `GLOSSARY.md#10`）。
- **双路径**：Hot Path <2s；Cold Path 异步写回 L0/L1；Cold Path 不得阻塞 Hot Path。
- **可插拔**：L2 Agents、模型选择、L1 模块以接口插拔；Context Manager 是唯一组装入口。
- **可观测**：`correlation_id`（`X-Request-ID`）贯穿 API → worker → LLM 调用 → DB 记录。

### 0.2 非目标（避免重构失控）

- 不改 DB/框架大栈：仍以 FastAPI + Next.js + PostgreSQL 为主。
- 不引入重型基础设施作为前置（Kafka/ES/复杂 MQ）；Cold Path 优先用“DB 队列 + worker”落地。

---

## 1. 现状问题（按根因归类）

> 注：问题清单与优先级以四份 v3 文档为准（各文档末尾 `P0/P1/P2`），此处只做“根因归并”。

### 1.1 闭环阻塞（P0）

- **前端写操作 CSRF 处理分散/重复**：同一项目内出现多套 CSRF 读取/注入方式，导致写操作不稳定、难排查。
- **action_buttons 的动作系统不统一**：组件直接 `fetch`、缺少统一错误反馈与状态联动，导致需要 `reload` 或出现“点了没反应”的体验。

### 1.2 SSOT 漏洞（P0/P1）

- `fortune_ai/services/task_service.py` 仍写 `fortune_ai/services/conversation_store.py` 本地 jsonl 作为外部任务 prompt/output 日志 → 与“PostgreSQL 业务数据 SSOT”冲突。
- 外部任务（report/poster）**审计口径不统一**：prompt/output/a2ui 产物散落，难回放、难追溯。

### 1.3 架构边界不清（P1）

- `services/` 承载了 L0/L1/L2/Context/Interaction 的混合逻辑，新增模块只能继续堆叠。
- A2UI 解析/渲染/动作执行分散在 store/blocks/dashboard 组件中，缺少“单一动作入口”。

### 1.4 Cold Path 缺失（P1/P2）

- Insight & Memory Agent 仍停留在文档层：缺 job 设计、状态机、重试、观测与灰度开关，无法兑现“越用越懂用户”。

### 1.5 治理与排障能力弱（P2）

- 缺 `X-Request-ID` / correlation_id 的统一注入与透传；跨 `api/worker/agent_service` 排查成本高。
- anti-dependency 缺新用户豁免，影响激活（与 `system_design_final_mvp_v3.md` 的产品原则冲突）。

---

## 2. 目标架构（落地视角）

### 2.1 运行时边界：Hot Path 与 Cold Path 的硬隔离

**Hot Path（同步，<2s）只做：**
1. 认证/CSRF 校验
2. 写入 `fortune_conversation_message`（用户输入）
3. Context Manager 组装 context（L0 + Relevant L1 + History）
4. 调用 Interaction Layer（模型选择/流式）
5. 写入 assistant message（含 `a2ui`）
6. 若产生 commitments：写入 `fortune_commitment(status='suggested')`
7. 返回 A2UI 给前端渲染

**Cold Path（异步，后台）只做：**
1. 读取对话片段（`session_id` + message range）
2. Insight Agent 结构化提取（tags/status/summary + L1 updates）
3. 写回 L0/L1（带审计/幂等）
4. 可选：刷新 `fortune_daily_guidance`、K线日线等派生数据

### 2.2 “层级 → 代码模块”映射（建议的工程分层）

保持单体仓库，但把逻辑按边界收拢（**先引入新目录，再逐步搬迁**，避免一次性大迁移）：

**Backend（Python）**
- `fortune_ai/api/`：只保留路由与 request/response schema；不放业务规则。
- `fortune_ai/services/interaction/`：LLM client、模型选择、流式协议（SSE）。
- `fortune_ai/services/context/`：Context Manager v4.0（读取 L0/L1/history，组装 prompt）。
- `fortune_ai/services/agents/`
  - `expert/`：八字/PERMA/CBT… 专家提示词与工具调用
  - `style/`：standard/warm/roast 等风格转换
- `fortune_ai/services/modules/`：L1 Module Data（bazi/perma/kline/...）的“读上下文 + 写回接口”。
- `fortune_ai/services/insight/`：Insight & Memory Pipeline（job、prompt、mapper、写回）。
- `fortune_ai/stores/`：Postgres repository/transaction；每个领域一组 store（chat_store、commitment_store、external_job_store…）。

**Frontend（Next.js）**
- `fortune_ai/web-app/src/lib/`：单一 `apiClient` + CSRF helper + 统一错误处理（401/403 跳转、toast）。
- `fortune_ai/web-app/src/stores/`：按域拆分（chat/tasks/status/ui），由现有 `app-store.ts` 逐步拆出。
- `fortune_ai/web-app/src/components/chat/blocks/`：只渲染，不直接 `fetch`；动作统一走 store handler。
- `fortune_ai/web-app/src/components/dashboard/`：只消费 store 数据，不做写操作细节。

### 2.3 契约 SSOT：A2UI 与 Action 统一入口

- A2UI schema 以 `fortune_ai/docs/GLOSSARY.md#4-a2ui-组件类型` 与 `#87` 为唯一口径。
- 前端动作处理只有一个入口：`handleA2UIAction(action)`，内部映射到 API 或 UI 事件。
- 后端 commitments 生成也只有一个入口：`suggest_commitments(...)`，保证状态机与埋点一致。

---

## 3. SSOT 治理与数据结构重构

### 3.1 消灭本地文件落盘（硬目标）

将 `fortune_ai/services/conversation_store.py` 的外部任务 prompt/output 日志迁移至 Postgres：

- **方案 A（最小改动，推荐优先）**：扩展 `fortune_external_job`，新增：
  - `prompt` / `output_text` / `raw_output` / `correlation_id`
- **方案 B（审计更完整）**：新增 `fortune_external_job_log`（1:N）用于多次轮询与中间产物记录。

完成后：
- 过渡期：`conversation_store.py` 仅保留“兼容读取”（如确有需要）
- 最终：删除所有写入路径与对 `conversation_store` 的引用

### 3.2 Cold Path Job 表（Insight Agent MVP）

新增（或复用）一个“数据库队列”表（避免引入 MQ）：

- `fortune_insight_job`
  - `job_id`, `user_id`, `session_id`, `from_message_id`, `to_message_id`
  - `status`（queued/processing/done/error）, `attempts`, `next_run_at`
  - `output_json`（l0_updates/l1_updates）, `error`, `correlation_id`, timestamps

写回采取“幂等 + 审计”：
- 每次 job 输出落库一份 `output_json`，并记录 `applied_at`
- L0/L1 只更新“有变化字段”；冲突时以 `updated_at`/版本号解决

---

## 4. 前端重构：从“组件直接 fetch”到“动作系统”

### 4.1 CSRF 与 API Client 单一化

- 抽出 `web-app/src/lib/csrf.ts`：唯一读取 `fortune_csrf`
- 抽出 `web-app/src/lib/api-client.ts`：统一 `fetch`、`X-CSRF-Token`、错误码处理、401/403 跳转
- 全项目禁止出现“组件内手写 CSRF header”的重复实现

### 4.2 action_buttons 统一处理（不 reload）

- `ActionButtonsBlockComponent` 只派发 `action`，不直接 `fetch`
- `taskStore` 提供：
  - `acceptTask(task_id, commitment_type)`
  - `doneTask(task_id)`
  - `skipTask(task_id)`
  - `refresh()`（GET `/api/dashboard/tasks`）
- 成功后：Zone B 自动联动（store 更新）；失败 toast；按钮 loading/disabled

### 4.3 长对话性能与体验（P1/P2）

- `message-list` 引入虚拟滚动（`@tanstack/react-virtual`）
- A2UI 渲染做到“流式增量 + 最小重渲染”（按 message_id key）
- skeleton/empty/error 状态补齐

---

## 5. 后端重构：把“概念层”变成“可插拔接口”

### 5.1 Context Manager v4.0 成为唯一入口

建议接口：
- `build_context(user_id, session_id, user_input) -> ContextBundle`
  - `l0`, `l1`, `history`, `routing`, `prompts`, `limits`

### 5.2 L1 Module Data 统一接口

每个模块实现：
- `load(user_id) -> ModuleSnapshot`
- `to_context(snapshot) -> str|json`
- `apply_updates(user_id, updates)`

### 5.3 Insight Agent Pipeline（MVP）

- `enqueue_insight_job(session_id, message_range, correlation_id)`
- worker 侧：
  - `run_insight(job)` → `output_json`
  - `apply_updates(output_json)` → 更新 L0/L1 + 可选 summary/派生数据

---

## 6. 分阶段迁移路线图（Strangler + Feature Flags）

### Phase 0：闭环解阻（P0，1-2 天）

- 统一 CSRF helper 与 API client
- action_buttons 全量走 store handler，替换 `reload`
- 加 1 条 e2e：登录→发起 chat→点 `start_task`→任务列表刷新

### Phase 1：SSOT 治理（P1，2-5 天）

- 外部任务日志迁移到 `fortune_external_job`（或 log 表），移除 `conversation_store` 写入
- 补齐 `/api/auth/validation-points`（文档已有但实现缺失）
- anti-dependency 新用户 7 天豁免 + `opt_out` 出口
- 后端 CSRF helper 去重（统一到 deps 或独立模块）

### Phase 2：层级抽离（P1/P2，5-10 天）

- 将 `services/soul_os.py` 中 context/agent 路由拆出到 `services/context/*`、`services/agents/*`
- 定义 A2UI 与 Insight 输出的 Pydantic schema（用于校验与演进）
- 引入 `X-Request-ID`：middleware 生成/透传；落日志；外部 job 表记录

### Phase 3：Cold Path 落地（P2，5-10 天）

- 增加 `fortune_insight_job` + worker 轮询执行
- 先支持最小写回：L0 tags/status/summary + L1 perma_snapshot（或 checkin 派生）
- 灰度开关：`INSIGHT_AGENT_ENABLED=0/1`；失败不影响 Hot Path

### Phase 4：功能补全与体验（持续）

- K线：`/api/dashboard/kline` 数据校验 + 前端蜡烛图组件
- 海报：生成入口 + 预览组件 + 失败重试
- Settings：UI 完整 + 与 `fortune_user_preferences` 对齐
- 多模型切换：Interaction Layer 配置 UI + 偏好落库

---

## 7. 验收清单（必须可度量）

- **WCG**：按 `fortune_ai/docs/GLOSSARY.md#10` 的 SQL 能统计本周闭环用户数
- **Hot Path**：平均响应 <2s（不含 SSE 全量输出）
- **Cold Path**：insight job 成功率/平均处理时长/写回字段覆盖率可统计
- **SSOT**：仓库内无业务 jsonl 落盘；外部 job prompt/output 可在 DB 查到
- **可观测**：任一异常可用 correlation_id 贯穿 API→worker→DB 记录定位

