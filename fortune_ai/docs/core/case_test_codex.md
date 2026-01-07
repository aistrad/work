# Fortune AI /new（目标设定·规划·监督执行）实测与优化建议（Codex）

> 目标：评估 `http://106.37.170.238:8231/new` 是否能支撑 `fortune_ai/docs/os/benran case.md` 中的「制定目标→规划→监督执行→复盘」闭环，并给出前端/后端/架构需要的优化。
>
> 约束：只测试与分析，不改任何业务代码；本文为测试结论与建议。

---

## 1. 结论摘要（P0 先说）

1) **目前 /new 只能稳定跑通“登录 → Dashboard 浏览 →（通过 API 触发）任务创建 → 任务接受/完成 → 分数反馈”**；但 **“目标设定/规划/监督执行”在用户侧的主入口（Chat/A2UI/计划/复盘）尚未形成可用闭环**。  
2) **Chat 侧存在硬阻塞**：对测试账号触发了 `anti_dependency (daily_limit)`，返回“先行动/打开任务”的干预消息，**导致无法得到目标设定与行动处方**。同时，前端 **未渲染 A2UI 的 action_buttons**，即使后端返回按钮，用户也点不到。  
3) **“成长计划 / 计划打卡 / 复盘（daily/weekly）”缺口较大**：后端已有 `plan` 表与 `/api/plan/*`，但 /new 前端未接入；`fortune_reflection`（设计稿里有）在当前代码未实现对应 API/服务与 UI。  
4) 任务闭环本身（`accept → done → state_score + rewards`）在 `/api/dashboard/*` 路径下是可用的，但 **需要补齐“从目标/规划自动生成任务、以及监督/复盘输入”** 才能接近 `benran case` 的 OS 能力。

---

## 2. Playwright 实测记录（仅 /new）

### 2.1 环境与方式

- 测试目标：`http://106.37.170.238:8231/new`
- 浏览器：Chromium（Playwright）
- 运行方式：由于运行环境缺少 XServer，**使用 `headless: true`**（曾尝试 `headless:false`，会报 “Missing X server or $DISPLAY”）。
- 测试账号：使用既有测试账号 `playwright_test@example.com`（密码不在文档中记录）。

### 2.2 登录与基础可达性

- `/new/login`：邮箱/密码登录成功，后端返回 `POST /api/auth/login 200` 并设置 Cookie：`fortune_session`、`fortune_csrf`。
- **发现一个 P0 前端问题**：登录页「注册」链接的 `href` 为 `/register`（缺少 `basePath=/new`），容易导致跳转到错误路径（应当是 `/new/register` 或使用 Next 的 `Link`/router basePath-aware 路由）。

证据（第一次登录+聊天+任务尝试）：
- 运行结果：`/tmp/1767203347724-results.json`
- 截图：`/tmp/1767203347724-01-login.png`、`/tmp/1767203347724-10-app-ready.png`

### 2.3 Chat 尝试“目标设定→行动处方→监督检查点”

向 Chat 输入「本周目标：提升工作专注与执行力」并强制要求包含 `### 行动处方`：

- 后端返回：`/api/chat/send 200`，但 `backend=anti_dependency`，`intervention_type=daily_limit`，`suggested_tasks=[]`。
- UI 表现：助手返回“信息足够→先行动”的文本；**没有出现任何可点击按钮**（action_buttons 未渲染）。
- 结果：**无法通过 Chat 完成“制定目标/规划/监督检查点”的输出，更无法一键转任务**。

证据：
- `jq '.api.chat_send[0].response.body_json.data.backend' /tmp/1767203347724-results.json` 为 `anti_dependency`
- 截图（Chat 与任务 Tab）：`/tmp/1767203347724-chat-goal.png`、`/tmp/1767203347724-05-tasks.png`

### 2.4 监督执行（任务闭环）可用性验证

由于 Chat 被 anti-dependency 截断，改用 **Dashboard 的 check-in API 触发任务**，再用 **任务 Tab 的 UI 完成“接受→完成”**，验证闭环是否通：

1) 在已登录态，通过浏览器上下文调用 `POST /api/dashboard/checkin`（携带 `X-CSRF-Token`）。  
2) 返回 `task_id` + `recommended_action` + `state_score`（A2UI 结构也返回）。  
3) 切到「任务」Tab：出现该 `recommended_action` 对应的建议任务。  
4) 点击「立即开始」→ `POST /api/dashboard/task/accept 200`，任务变为 active。  
5) 点击「完成」→ `POST /api/dashboard/task/done 200`，返回新的 `state_score` 与 `rewards`（`aura_earned`、`new_streak`）。

证据：
- 运行结果：`/tmp/1767204014379-checkin-taskflow.json`
- 截图：`/tmp/1767204014379-02-tasks.png`、`/tmp/1767204014379-03-after-accept.png`、`/tmp/1767204014379-04-after-done.png`

结论：**“监督执行”的任务执行闭环（accept/done + 反馈）是可用的**；但其入口目前依赖 API/隐藏能力，而非面向用户的可见交互（缺少 check-in UI、缺少从目标/规划生成任务）。

---

## 3. 与 `benran case`（OS 能力）对照：缺口清单

`fortune_ai/docs/os/benran case.md` 的核心能力可以抽象成：

- 目标设定：年/季/月/周目标；Outcome/Lead measure/假设前提；节奏与检查点
- 规划：晨间规划（认知/时间/资本三维）+ 二号门微实验
- 监督执行：承诺（Commitment）→ 行动 → 反馈（check-in/数据）→ 调整
- 复盘升级：日/周/月复盘，沉淀系统升级日志

对照当前 Fortune AI（/new + 现有 API/数据）：

1) **目标设定（缺口：产品化与数据化）**
   - 当前：没有“Goal/OKR/检查点”实体与 UI；只能靠 Chat 文字（但 Chat 当前被 anti-dependency 频繁截断）。
   - 需要：目标表（目标/指标/周期/状态/关联任务），以及“拆解为 1–3 个最小行动”的落地逻辑。

2) **规划（缺口：计划卡/计划轨道未在 /new 落地）**
   - 当前：后端已有 `/api/plan/list|active|join|record` 与 `fortune_plan_*` 表，但 /new 前端未接；Dashboard 也没有“计划”Tab/卡片。
   - 需要：成长计划 UI（选计划→加入→每日指令→记录完成→自动进入复盘日）。

3) **监督执行（部分具备，但入口与联动缺失）**
   - 当前：`fortune_commitment` + `task accept/done` + `state_score` 反馈可用；但缺少从 Chat/A2UI 一键落任务；缺少“监督检查点/提醒/待处理”机制。
   - 需要：把“行动处方”变成任务（按钮/拖拽/快捷键），并提供提醒与复盘入口。

4) **复盘（缺口：API/数据/UI 三缺）**
   - 当前：设计文档里有 `fortune_reflection`，但代码中未见对应服务与 API；/new UI 也无复盘入口。
   - 需要：daily/weekly 复盘数据结构、表单、自动触发（计划第7/14/…天）、与趋势/事件联动。

---

## 4. 优化建议（按前端 / 后端 / 架构拆分，含优先级）

### 4.1 前端（/new，P0→P2）

**P0：让用户能跑通闭环**
- 修复 `basePath=/new` 路由一致性：`/new/login` 的注册链接、登录成功后的跳转、所有内部链接统一 basePath-aware（避免 `/register` 这种断链）。
- 渲染 A2UI：至少支持 `markdown_text + action_buttons`；把按钮 action 映射为真实 UI 行为：
  - `start_task` / `schedule_task`：调用 `/api/dashboard/task/accept`
  - `open_panel`：映射到 Dashboard tab（例如 `quests`），并可带参数定位到任务
  - `opt_out`：关闭/降频/不再提示
- 给出“情绪打卡 / Check-in”可见入口（UI 表单）并联动任务 Tab（这是监督执行最稳定的入口之一）。

**P1：把“规划/目标设定”产品化**
- 增加「成长计划」UI：接入 `/api/plan/*`（list/join/active/record），在 Dashboard 增加 Plan 卡或 Tab，并在“复盘日”提供结构化问答表单。
- 增加「目标设定」向导：把用户输入转成可追踪目标（周期、衡量标准、检查点），并一键生成 1–3 个 commitment。

**P2：体验与规模化**
- 任务状态刷新策略：Tab 切换/操作后自动 refetch；失败显示 toast；支持乐观 UI + 回滚。
- Asset Layer：把 Pin/Save as Page/To Quest 做到可持久化（后端资产表 + 搜索）。

### 4.2 后端（P0→P2）

**P0：保证 Chat 主流程可用且“可行动”**
- anti-dependency 策略需要更“可控/不截断核心价值”：
  - `no_action` 不应对新用户默认强触发（可加“注册天数/首次会话/是否已有计划”等门槛）。
  - `daily_limit` 触发时，也应返回**至少 1 个可执行任务**（带 `task_id`），而不是只说“打开任务”。
- 对齐 `open_panel` 的 panel 命名与前端 Tab（如 `quests`），避免返回 `panel: tasks` 但前端无对应。
- GLM 不可用时（或报错时）提供降级：用规则模板（来自 OS 规划/复盘模板）生成最小可用 A2UI，而不是 500。

**P1：补齐“目标/复盘/计划监督”数据闭环**
- 实现 `fortune_reflection` 相关 API（daily/weekly），并把复盘结果写入趋势事件（可回溯）。
- 增加 Goal/Objective 实体（或在现有 plan/commitment 上扩展），支持目标→任务→检查点的可追踪链路。

**P2：治理与可观测**
- 全链路 `correlation_id`、结构化审计字段、失败可回放（尤其是 LLM 失败与 A2UI 校验失败）。

### 4.3 架构（P0→P2）

**P0：统一“闭环 SSOT + 可回溯”**
- 明确 SSOT：目标/计划/任务/打卡/复盘全部落 `fortune_ai`（已在设计里），并把“按钮动作/状态变化”写入事件表（趋势可解释）。
- 前后端协议统一：A2UI 是“动作的唯一协议”，前端必须能解释并执行（否则 OS 只停留在 prompt）。

**P1：监督执行的系统化**
- Push/提醒：把 `fortune_push_event` 与计划/任务状态联动（到点提醒、未完成降级任务、复盘日触发）。
- 权限与安全：Cookie `secure`、CSRF 策略、跨域/代理策略统一到部署层，避免环境差导致线上行为不一致。

---

## 5. 下一步建议（最小闭环落地顺序）

1) **先把 A2UI(action_buttons) 在 /new 渲染出来**（这是把 OS 从“文字建议”变成“可执行闭环”的最短路径）。  
2) **把 check-in 做成 UI 入口**，并保证 1 次 check-in → 生成 1 个任务 → 任务完成 → 分数反馈的闭环稳定。  
3) **再把“成长计划 / 复盘 / 目标设定”接进来**（/api/plan + 复盘表 + 目标表），形成周尺度的监督机制。

---

## 附录：测试产物路径

- Chat/任务尝试（含 anti_dependency 响应）：`/tmp/1767203347724-results.json`
- Check-in → 任务接受/完成闭环：`/tmp/1767204014379-checkin-taskflow.json`

