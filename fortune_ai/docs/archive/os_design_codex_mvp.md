# Fortune AI「Soul OS」MVP 设计（自我-自性轴线 / 可落地）

**文档类型**：OS Design（MVP）  
**产品代号**：`Fortune AI`  
**版本**：Codex MVP v1.0  
**日期**：2025-12-31  
**范围**：仅定义 OS 层（心理学-产品-工程的统一模型），实现边界以 `fortune_ai/docs/architech/system_design_final_mvp.md` 为准  

**参考输入（本次综合）**
- `fortune_ai/docs/os/os idea.md`：自我-自性轴线的四层心理-计算映射（L0–L3）
- `fortune_ai/docs/architech/bp v1.md`：精神数字孪生 + 双模式交互（Chat / Function）+ 增长与玩法方向
- `fortune_ai/docs/architech/system_design_final_mvp.md`：Web 可落地闭环、A2UI、PostgreSQL SSOT、反依赖机制、Bento 工作台
- `fortune_ai/docs/architech/idea business model.md`：State Score / WOOP / 微课程 / 游戏化变现与裂变（订阅+内购+激励）

---

## 0. 一页结论（给产品 & 研发）

### 0.1 OS 的一句话定义

**Soul OS = 一个把“情绪—解释—行动—反馈”外部化的自我调节系统**：  
让用户把混沌体验变成可执行承诺（Commitment），再用可审计反馈（Check-in / Reflection / Plan Record）把“自我效能感”做出来，最终把依赖从“问答案”迁移到“做闭环”。

### 0.2 MVP 的“最小但完整”的 OS 交付

对齐 `system_design_final_mvp.md` 的闭环与约束，OS 在 MVP 只交付三件事：
1) **可重复闭环**：`Clarify → Insight → Prescription → Commitment → Action → Reflection → Memory Update`
2) **两种交互形态**：Chat（咨询室）+ Bento（工作台/显化区）
3) **反依赖护栏**：限制重复占卜式追问，强制回到现实实验与最小行动

### 0.3 一条总原则（心理学约束）

**“定数”只能作为先验，不得作为判决。**  
系统可以用 `L0` 提供叙事感与问题定位，但必须把输出收敛为用户可控变量（行为、环境、边界、练习），并在每次输出中显式邀请承诺（Commitment）。

---

## 1. 心理学底座：自我-自性轴线的产品化

### 1.1 核心问题：为什么用户会“越问越焦虑”

从分析心理学的视角，焦虑的燃料通常来自两种断裂：
- **意义断裂**：事件发生但没有可承载的解释框架（只剩“我是不是不行/我是不是倒霉”）
- **效能断裂**：解释即便成立，也没有下一步行动（只能继续问、继续刷）

因此 OS 的任务不是“给真相”，而是**修复轴线**：
- 让自我（Ego）能看见更完整的自性（Self）线索（被理解、被命名）
- 再把理解翻译为行动（能做、可做、现在就做）

### 1.2 外部化（Externalization）是 MVP 的技术路径

MVP 不追求“全量人格仿真”，而追求**外部化的可用最小集**：
- 把“内心的声音/冲突/价值”外部化为结构化卡片（Bento）
- 把“行动”外部化为可点击承诺（`fortune_commitment`）
- 把“反馈”外部化为可追溯记录（`fortune_checkin` / `fortune_reflection` / `fortune_plan_record`）

---

## 2. 运行时闭环（Runtime Loop）：从咨询到自我调节

对齐 `system_design_final_mvp.md`，OS 的一次运行必须走完 7 步；每一步对应清晰的心理学意图与工程落点。

| Step | 产物（给用户） | 心理学意图 | MVP 落点（SSOT） |
|---|---|---|---|
| Clarify | 问题结构化（选项/约束/时间窗） | 降低不确定性焦虑 | `fortune_conversation_message` / `POST /api/bento/decision-brief` |
| Insight | 可控/不可控拆分 + 解释 | 认知重评、归因修正 | A2UI `markdown_text` |
| Prescription | ≤3 条处方（微行动优先） | 行为激活、启动摩擦最小化 | A2UI + 写入 `fortune_commitment(status=suggested)` |
| Commitment | 用户选一个并确认 | 建立承诺、形成自我效能 | `fortune_commitment.accepted_at` |
| Action | 完成/跳过/延期 | 行为回路形成 | `fortune_commitment.status` |
| Reflection | 一句话复盘（得失/阻碍/下次） | 强化学习、复盘迁移 | `fortune_reflection` 或 `fortune_checkin` |
| Memory Update | 更新“自我模型”可见变化 | 形成成长叙事与可追溯证据 | 由后端汇总写入各表；供下次对话读取 |

**硬规则（MVP）**
- 处方（Prescription）必须 ≤3 条；每条必须能落到按钮（`accept_task`/`open_panel`/`opt_out`）
- 任何“解释”后必须紧跟“你现在能做什么”（行动处方）

### 2.1 WOOP / If-Then（把愿望变成可执行计划）

来自 `idea business model.md` 的关键建议是把 **WOOP（Wish/Outcome/Obstacle/Plan）** 植入对话，让“想要改变”不再停留在口号。

**MVP 推荐集成点**
- 在 `Clarify` 或 `Prescription` 阶段，当用户表达目标/习惯时，追加 1–2 句结构化追问：`wish` / `obstacle`
- 在输出处方时，至少给出 1 条 `if_then`（Implementation Intention）：`如果____发生 → 那么我就做____（≤2分钟版本优先）`

**工程落点（不新增表的前提）**
- 将 `wish/outcome/obstacle/if_then` 写入 `fortune_commitment.details`（JSONB），用于后续复盘与提示一致性
- 若用户加入 `habit_30` 等轨道，可复用轨道内置的 If-Then 训练日（对齐 `system_design_final_mvp.md` 的预设任务）

---

## 3. 四层 OS 架构（L0–L3）：心理映射 → 工程映射

> 说明：L0–L3 是**认知架构**，不是必须的多进程“多智能体系统”。MVP 实现可以是“单 LLM + 多个结构化输入 + 规则约束”。

### 3.1 L0 Firmware（定数 / 先验）

**定义**：不可随意更改的先验信息（出生信息、地点、时区；由此计算的命理/占星事实快照）。  
**价值**：提供叙事锚点（Validation）与提问方向（更精准的澄清问题），降低“我是不是无缘无故有问题”的羞耻感。

**MVP 约束**
- L0 只输出 `facts`，不得输出“必然结论”；任何预测必须降级为条件句 + 低置信度
- L0 的更新必须可追溯（快照化），避免“系统自己改口”

**工程映射（已在 Final MVP 定义）**
- Profile：`fortune_user`
- 事实快照：`fortune_bazi_snapshot(facts, facts_hash, compute_version)`
- 读取规则：对话与 Bento 只能读取最新快照作为确定性事实来源

### 3.2 L1 Schema（图式 / 相对稳定的自我模型）

**定义**：用户相对稳定的“我是谁”模型：偏好、价值、边界、典型阻碍、常用优势、风险边界。  
**价值**：让系统输出更“像你”，同时让用户感觉“这是在帮我成长，而不是在给模板建议”。

**MVP 最小实现（不引入新 DB 的前提）**
- 显式偏好：`fortune_user_preferences(persona_style, push_*)`
- 行为证据：从 `fortune_commitment / fortune_plan_record / fortune_checkin / fortune_reflection` 汇总出“常见模式”（后端计算、对话时注入）
- 会话语境：从最近 N 条 `fortune_conversation_message` 提炼“本周主题”（运行时计算）

> 备注：若后续需要把 L1 固化为可编辑“角色面板”，再新增 `fortune_user_schema`（JSONB）即可；MVP 先不要求。

### 3.3 L2 Agents（策略声音 / 部分人格）

**定义**：把“应该怎么做”的冲突来源外部化为若干策略视角，让用户看到自己内在冲突的结构。  
**价值**：把纠结从“我不行”变成“价值冲突/目标冲突/风险偏好冲突”，降低自责，提升选择质量。

**MVP 实现方式（推荐）**
- 不做“智能体互相辩论”，只做**并行候选建议**：同一问题生成 2–4 个候选处方方向，然后由 L3 仲裁
- 每个策略只输出三件事：`assumption`（前提）、`tradeoff`（代价）、`next_step`（下一步实验）

**可配置的 4 个原型顾问（来自 `os idea.md`）**
- Confucius：关系/秩序/责任（边界与义务清晰化）
- Elon Musk：突破/实验/高杠杆（最小验证与快速迭代）
- Ray Dalio：系统/原则/复盘（因果链与规则化）
- Stephen Covey：效能/习惯/角色（要事优先与可持续节奏）

> MVP 可以先把它们实现为“提示模板（prompt template）/规则模块”，并不要求 4 个独立 Agent 进程。

### 3.4 L3 Synthesis（意识 / 仲裁器）

**定义**：在 L0 先验、L1 图式、L2 候选建议之间做一致性仲裁，输出可执行的统一行动。  
**价值**：这一步是“从理解到改变”的唯一出口；没有 L3，就会停留在内容消费与反刍。

**MVP 产物（对齐 Final MVP）**
- 输出必须为 A2UI JSON（首组件 `markdown_text`，第二组件 `action_buttons`）
- 必须包含：`conclusion` + `why` + `prescriptions(≤3)` + `risk_boundary` + `commitment_ask`
- 必须把处方写入 `fortune_commitment(status=suggested)`，形成可追溯闭环入口

---

## 4. OS 的界面与对象：把“心灵结构”做成可操作 UI

### 4.1 `/main` 两栏 = 轴线的可视化

- 左栏（Chat Thread）：**自我（Ego）的语言化**，承接情绪与叙事
- 右栏（Workbench/Bento）：**自性的结构化镜像**，把冲突/任务/计划变成可点击对象

### 4.2 Bento 的 MVP 组件（建议与 Final MVP 对齐）

| Tab/Panel | 用户动作 | OS 作用 |
|---|---|---|
| Today | 看“今日指引卡”→点一个行动 | 把系统价值压缩成 1 张卡，降低启动成本 |
| Check-in | 选情绪/强度→得到 1 个调节动作 | 情绪调节先行，避免在高唤醒状态做重大决策 |
| Commitment | 接受/完成/跳过任务 | 把“建议”变成“承诺”，把承诺变成“证据” |
| Decision Brief | 填选项/约束→生成最小实验 | 专门承接高频的“我要不要/该不该” |
| Script | 生成短脚本（沟通/自我对话） | 提供可直接照读的行为脚本，降低社交与执行摩擦 |
| Plan | 加入 30 天/14 天轨道→每日记录 | 长程成长的节奏器（把成长做成进度） |

### 4.3 “精神数字孪生 / 角色面板”在 MVP 的最小形态

为避免 MVP 被“面板工程”拖垮，建议把数字孪生拆成两层：
- **展示层（MVP 必做）**：在 Workbench 顶部 Viewer 显示 3 个指标 + 1 句解释 + 1 个建议动作  
  示例指标：`energy`（精力）、`clarity`（清晰度）、`connection`（连接感）
- **资产层（后续可做）**：头像/皮肤/光环/装备（与变现深度绑定）

> 关键：MVP 的面板必须服务闭环（引向行动），而不是成为“更好看的静态标签”。

### 4.4 State Score（状态分数）：把“感觉”变成可训练变量

来自 `idea business model.md` 的核心洞察是对的：**留存不来自解释，来自可感知进步**。  
但在 MVP 里，State Score 必须满足三个约束：可解释、可被行动影响、不过度惩罚。

**MVP 建议（不新增表也能落地）**
- 计算口径：由后端按“最近 24h/7d”汇总（不要求精确心理测量）
  - `checkin_signal`：最近一次 `fortune_checkin(intensity)`（高强度负面→分数下降，但会触发补救动作）
  - `action_signal`：24h 内 `fortune_commitment.status='done'` 是否发生（完成→上升）
  - `streak_signal`：连续记录/连续完成（用 `fortune_plan_record` 或 check-in 计算）
- 展示策略：分数旁必须显示“你可以把分数拉回来的 1 个动作”（避免纯惩罚）
- 反依赖：当用户连续追问同一问题时，不给更高分数，只给“最小实验”

---

## 5. 反依赖与安全：把“玄学依赖”导向“自我掌控”

### 5.1 反依赖机制（对齐 Final MVP，可验收）

| 触发条件 | 系统响应（MVP） | 心理学目的 |
|---|---|---|
| 连续 3 次问同一问题 | 必须先选一个 5–15 分钟现实实验 | 打断反刍，转入行为激活 |
| 当日咨询 > 5 次 | 温和截断：信息足够→先行动 | 防止把系统当“情绪止痛药” |
| 轨道达标毕业 | 主动降频推送，强调自主 | 让用户把控制权拿回去 |

### 5.2 风险边界（合规与伦理）

- 禁止确定性宿命论输出（尤其是健康/法律/投资）
- 抑郁/自伤相关关键词：触发危机提示与求助资源（MVP 可以先做硬规则检测）
- 任何“负面解释”后必须紧接“可执行处方”（降低恐惧与无助感）

---

## 6. 变现与增长：把商业模型“嵌入 OS”，但不绑架 OS

### 6.1 订阅（Subscription）：`Cosmic Pass` 的 MVP 版本

对齐 `idea business model.md`，订阅的心理机制应是“损失厌恶 + 成长连续性”，但在 MVP 里先做最小闭环：
- 免费层：每日指引 + 有限对话额度 + 基础盘面/事实快照可见
- 订阅层：更高的对话额度/更长的历史回放/更完整的深度报告入口（`/api/report/bazi/submit`）

### 6.2 内购（IAP）：先从“深度报告”开始

最先可落地的单次付费，应是**有交付形态的内容产物**：
- `Deep Dives`：年度/职业/关系主题报告（PDF/阅读模式），对应现有深度报告链路（`backend=cli|gemini`）

头像皮肤/能量币等“游戏资产”更适合 V1+，避免 MVP 因经济系统复杂度失焦。

### 6.3 裂变（Referral）：不做社区也能做传播

在“不做社区”的约束下，MVP 的传播载体建议是：
- 可分享图片（今日指引 / 状态分数 / 合盘摘要）+ 二维码深链（注册后查看完整版）
- 逻辑上属于“分享”，不属于“社区内容生产”

---

## 7. 路线图：MVP 先交付“闭环”，再扩展“玩法”

### 7.1 MVP（现在）
- 闭环跑通：Commitment + Action + Feedback 可追溯
- L0 快照化：`fortune_bazi_snapshot` 作为唯一确定性事实来源
- L2 轻量化：策略模板并行候选 + L3 仲裁（不做 Agent 间通信）
- 数字孪生最小面板：3 指标 + 1 动作，服务闭环而非炫技

### 7.2 V1（可选）
- State Score 时序化（新增日表/周表）+ 更明确的“练级”反馈
- 微课程内容库（从 `script` 纯文本 → 音频/交互式内容）
- 合盘与关系动力学（先 1:1 生成报告，不做社区）

### 7.3 V2（增长与变现重型）
- 能量币/皮肤/补签卡等完整经济系统
- 更丰富的分享模板与“任务副本”（双人挑战/群体仪式）

---

## 8. 附录：OS 概念 → Final MVP 工程对象映射

| OS 概念 | SSOT 表/对象 | 关键 API（Final MVP） |
|---|---|---|
| Ego 对话 | `fortune_conversation_session` / `fortune_conversation_message` | `POST /api/chat/send` |
| L0 先验 | `fortune_user` / `fortune_bazi_snapshot` | `PUT /api/user/profile`（触发重算） |
| Commitment（承诺） | `fortune_commitment` | `POST /api/bento/commitment/accept` / `POST /api/bento/commitment/done` |
| 情绪反馈 | `fortune_checkin` | `POST /api/bento/checkin` |
| 复盘反馈 | `fortune_reflection` | `POST /api/bento/reflect` |
| 成长轨道 | `fortune_plan*` | `POST /api/plan/join` / `POST /api/plan/record` |
| 今日指引卡 | `fortune_daily_guidance(card JSONB)` | `GET /api/bento/today` |
| 推送节奏（JITAI 的最小版） | `fortune_push_event` / `fortune_user_preferences` | `PUT /api/user/preferences` / `POST /api/push/pause` |
| 深度报告产物（付费优先） | `fortune_external_job` | `POST /api/report/bazi/submit` |
