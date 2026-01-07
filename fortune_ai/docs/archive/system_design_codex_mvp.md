# Fortune AI Web MVP 系统设计（Codex MVP）

**文档类型**：MVP System Design（Web 可落地）  
**产品代号**：`Fortune AI`  
**版本**：MVP v0.1  
**日期**：2025-12-29  
**核心定位（v4）**：**人生导航 / 陪伴 / 提升**（有效而极简）  
**MVP 入口**：`/main`（两栏：对话 + 功能区 / Workbench）  

---

## 0. 一页结论（MVP 要交付什么）

MVP 只做一件事：在 Web 上跑通一个可复用的“陪跑闭环”：

`Clarify → Insight → Prescription → Commitment → Action → Reflection → Memory Update`

- **对话区（Chat）**：一个“积极心理学 / Performance Coach”对话 Agent，负责把后端的专业分析（命理计算 + 知识库 + 规则）翻译成可执行行动处方；同时承担**销售 / 客服 / 助教**（但优先级固定：教练 > 助教 > 客服 > 销售）。
- **功能区（Bento/Workbench）**：所有“非语言交互”放在这里，用卡片化把行动做成 1 tap：情绪打卡、今日任务、决策模板、话术生成、报告生成、复盘等。
- **后端（完整版八字 + 知识库）**：用“数学脑/知识脑/语言脑”分层，输出结构化事实与可追溯证据；LLM 只负责表达与教练式引导，不负责计算与玄学断言。

**北极星指标**：`WCG`（Weekly Closed-loop Guidance）  
定义：用户一周内完成 ≥1 次「触发→指引→行动→反馈」闭环。

---

## 1. MVP 范围声明（In / Out）

### 1.1 In Scope（必须做）

**前端（Web）**
- 统一入口：`/main`（现有两栏原型作为基底）。
- Chat：支持 `标准/温暖/毒舌` 三种语言风格；Agent 以积极心理学/教练表达为主。
- 功能区（Bento/Workbench）：至少包含：
  - `今日指引`（结论 + 1 个行动）
  - `行动处方`（≤3 条，可勾选/完成）
  - `情绪打卡`（1 tap + 简短归因 + 1 个调节动作）
  - `30 天计划`（用户订阅，日提醒）
  - `八字报告/工具入口`（沿用现有“生成八字报告 / 校准出生时间 / 铁板神算”等表单能力，可折叠为“工具”）

**后端**
- 完整版八字计算（至少做到：四柱、五行、十神、藏干、旺衰、格局/喜用的“可解释版本”、大运、流年关键提示）。
- 八字知识库接入：`/home/aiscend/work/fortune_ai/knowledge/bazi`（PDF）→ 抽取/切分/索引 → 检索 → 作为解读证据（`kb_ref`）。
- 交付契约：统一输出 `Guidance Card`（结构化字段 + evidence）。

**主动服务（Push）**
- 只推**用户订阅的计划提醒** + **关键事件触发**（不做随机推送）。
- 每条推送必须包含：`Why me, why now` + `One action` + `Opt-out`。

### 1.2 Out of Scope（MVP 明确不做）

- 社区 / Feed / 公域 UGC。
- “强预测强断言”的宿命论表达；恐吓式营销。
- 大而全的命理体系扩展（紫微/占星/奇门等可留作后续插件，不进 MVP 必做）。

---

## 2. 产品原则（有效而极简）

### 2.1 三点击原则（必须可验收）

任何核心价值都要能在 ≤3 次点击完成：

- 打开 → 看到结论卡 → 选择下一步（Commitment）
- 点击“情绪” → 选择状态 → 获得归因 + 1 个动作
- 点击“今日任务” → 开始 → 完成/复盘

### 2.2 每次交互都要落到 Commitment

定义：每次输出都必须引导用户做一个明确选择（承诺），否则只是内容消费。

MVP 的承诺类型（`commitment_type`）只保留 4 类：
- `start_task`：开始一个最小任务（≤5 分钟优先）
- `schedule_task`：把任务放进“今天/本周”并设提醒
- `ask_followup`：选择一个澄清问题以继续（避免开放式追问过多）
- `opt_out`：关闭/暂停（反依赖与推送边界的一部分）

### 2.3 反依赖机制（MVP 必做的护栏）

目标：减少“玄学依赖”，把用户从“求答案”引导到“做行动实验”，符合“提升”定位。

| 触发条件 | Chat / Bento 响应（默认温和） |
|---|---|
| 连续 3 次问同一问题 | 先要求执行一个现实动作（5–15 分钟）再继续；提供“我愿意执行/稍后再说/关闭此提示” |
| 当日咨询 > 5 次 | 提示“信息足够，先行动”；推荐一个最小任务并结束对话回合 |
| 轨道毕业（30 天达标） | 主动减少推送频次，强调自我掌控；引导用户选择下一条轨道或进入“维护期” |

---

## 3. 前端交互：对话 + 功能区（Bento/Workbench）

### 3.1 MVP 主界面（基于现有 `/main`）

现有 `/main` 已具备“两栏原型”（左对话、右工作台）。MVP 的改造目标是：把右侧“工具表单”升级为 **Bento 卡片**，同时保留工具能力作为二级入口。

```
┌─────────────────────────────────────────────────────────────────┐
│ Fortune AI · Web MVP                                             │
├─────────────────────────────────────────────────────────────────┤
│ 左：对话（主交互）                  右：功能区（Bento/Workbench） │
│ - Coach Agent                        - Bento（默认）              │
│ - Guidance Card（结构化交付）        - 工具（报告/校准/铁板…）      │
│ - 承诺与行动追踪（commitment）       - 设置（persona/推送/隐私）     │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Bento 卡片（非语言交互全部放右侧）

> 每张卡都必须是“1 tap 可启动”，并最终产出/更新一个 `commitment` 或 `feedback`。

必备卡（MVP）：
- `今日指引`：今日结论（≤50 字）+ 1 个动作按钮（`start_task`）
- `行动处方`：最多 3 条进行中任务；支持完成/跳过/复盘（写 `action_done`/`feedback`）
- `情绪打卡`：情绪 + 强度（0–10）→ 归因 + 1 个调节动作
- `30 天计划`：主轨/副轨、今日任务、完成度、提醒时间（订阅式）
- `决策模板`：生成 `Decision Brief`（Options/Constraints/Risks/Next Experiment）
- `话术生成`：输入场景（关系/职场/边界）→ 输出可复制模板（短、可用）

工具卡（复用现有能力，放二级入口）：
- `生成八字报告`：复用 `/api/v2/submit` + `/api/v2/report/{job_id}`
- `校准出生时间`：复用 `/api/rectify/v3/stream`
- `铁板神算`：复用 `/api/tieban/*`

### 3.3 三点击路径（可验收）

| 场景 | 点击 1 | 点击 2 | 点击 3 |
|---|---|---|---|
| 今日指引 | 打开 `/main` | 点 `今日指引` | 点 `开始今日任务` |
| 情绪打卡 | 点 `情绪打卡` | 选择情绪/强度 | 点 `做一次 3 分钟降噪` |
| 决策支持 | 点 `决策模板` | 选择问题类型 | 点 `生成我的下一步实验` |
| 生成话术 | 点 `话术生成` | 填 1 句场景 | 点 `复制并发送` |

---

## 4. Chat Agent 设计（积极心理学 / Performance Coach）

### 4.1 角色定位与优先级（硬规则）

**核心身份**：Performance Coach（积极心理学教练）  
**兼任职责**：助教（教用法/带计划）、客服（解决问题）、销售（引导付费）

优先级固定为：

`Coach > Teaching Assistant > Customer Support > Sales`

说明：
- 销售必须“后置”：先交付价值，再给升级路径；不做恐吓式转化。
- 客服必须“解决问题优先”：出现故障/退款/投诉时，先处理再回到教练节奏。

### 4.2 语言风格（表达层，可切换）

`persona_style`：
- `standard`：简洁、专业、直接
- `warm`：更多共情与支持（默认推荐）
- `roast`：轻毒舌但**不羞辱**，不对人格做负面定性；用于轻娱乐场景

### 4.3 “后端专业分析”的翻译规则（关键）

后端输出分两层：

- `facts`：确定性计算结果（八字事实、计划状态、历史反馈）  
- `evidence`：规则与知识库引用（`rule_id` / `kb_ref` / `facts_hash`）

Chat 负责把 `facts + evidence` 翻译为用户可用语言，遵守：
- **先共情，再分析，最后给行动**（积极心理学/教练表达）
- **少玄学黑话，多可操作**：可以保留术语，但必须立即翻译成“对行动的含义”
- 默认只给 `Intervention Window`（行动有效期）；预测窗口只能概率/条件句表达

### 4.4 对话模板（MVP 统一）

```
1) 情绪确认：一句话复述用户状态（不评判）
2) 结构解释：把问题拆成“可控 / 不可控 / 需要澄清”
3) 行动处方：≤3 条（按成功概率×影响 − 摩擦 − 风险 + 能力增益排序）
4) 时间窗口：给“行动有效期”（例如 7 天试行）
5) 边界声明：不替代医疗/法律/投资建议
6) 承诺邀请：让用户选一个（Commitment）
```

---

## 5. 交付契约（Guidance Card + A2UI）

### 5.1 Guidance Card（服务端 SSOT）

```json
{
  "conclusion": "结论（≤50字，直接有用）",
  "why": "依据（用心理学/教练语言重构，不堆玄学黑话）",
  "prescription": ["处方1", "处方2", "处方3"],
  "time_window": {
    "type": "intervention|forecast",
    "value": "7天试行期",
    "confidence": "high|medium|low",
    "checkpoint": "下周一复核"
  },
  "risk_boundary": "不替代医疗/法律/投资建议",
  "commitment_ask": "你愿意先试试哪一个？",
  "evidence": {
    "plugin": "bazi",
    "rule_id": "R-021",
    "kb_ref": ["bazi:dfsv:page12:p3", "bazi:qianliminggao:page45:p2"],
    "facts_hash": "sha256:..."
  },
  "actions": [
    {"type": "start_task", "label": "开始今日任务", "task_id": "task_xxx"},
    {"type": "open_panel", "label": "打开决策模板", "panel": "decision_brief"}
  ],
  "meta": {
    "card_id": "guid-xxx",
    "policy_version": "mvp-0.1",
    "generated_at": "2025-12-29T10:00:00Z"
  }
}
```

### 5.2 A2UI（前端渲染协议）

现有 `/main` 已可渲染 `markdown_text` 组件（`/api/v2/report/{job_id}` 返回 A2UI 时，前端会提取首个组件的 `data` 文本）。MVP 建议：

- **第一组件必须是 `markdown_text`**：保证现有 UI 可展示。
- 可选增加：`action_buttons` / `checklist` 等组件（后续增强右侧 Bento 的可交互性）。

---

## 6. 主动服务（Push）：不被讨厌的边界

参考 `fortune_ai/docs/architech/qa1.md`：

> 为了形成习惯：每日（用户可定制时间）推送精心设计的信息；引导用户加入主动心理学计划。

并落实为 v4 四条硬规则：

1) **用户订阅 > 平台硬塞**：默认不随机推送，只推订阅计划提醒 + 关键节点。  
2) **Why me, why now**：解释触发原因（订阅/阶段/完成度）。  
3) **One action**：只给一个动作（≤5 分钟优先）。  
4) **Opt-out**：一键暂停/改时间/降频，不藏开关。  

### 6.1 触发类型与频控（MVP）

| 类型 | 触发条件 | 频率上限 | 默认开启 |
|---|---|---:|---|
| 计划提醒 | 用户订阅 30 天能力计划 | 每日 1 次（用户设定时间） | ✅ |
| 周复盘 | 每周固定一天（用户可选） | 每周 1 次 | ✅ |
| 成就庆祝 | streak/毕业/关键里程碑 | 达成即推 | ✅ |
| 额外提醒 | 未完成今日任务 | 每日最多 1 次（可关闭） | ❌ |

### 6.2 推送模板（MVP）

```
[Why] 你订阅的「决策清晰度」训练（第 7/30 天）
[What] 今日任务：用决策模板整理一个小问题（5分钟）
[Action] 👉 开始今日任务
[Opt-out] 暂停提醒 | 调整时间
```

### 6.3 MVP 渠道建议（从易到难）

- 站内消息（登录后展示）+ 对话区置顶卡（无权限成本，优先）
- Telegram/企微/微信模板消息（按渠道接入）
- Web Push（最后做，需要浏览器授权与 Service Worker）

---

## 7. 后端总体架构（MVP 可实施版）

### 7.1 分层（数学脑 / 知识脑 / 语言脑）

```
User Query / Bento Action
  → [数学脑] 八字确定性计算（facts JSON + facts_hash）
  → [知识脑] 知识库检索（kb_snippets + kb_ref）
  → [语言脑] 教练式表达合成（Guidance Card / A2UI）
  → [Commitment] 写入行动与反馈（闭环 SSOT）
```

### 7.2 服务与模块（建议）

**API（FastAPI）**
- `POST /api/chat/ask`：对话入口（异步 job）
- `POST /api/bento/*`：今日卡/打卡/计划/复盘（建议新增）

**Services**
- `services/bazi_engine.py`：确定性八字计算（需扩展为完整版）
- `services/kb_bazi.py`：知识库索引与检索（snapshot + evidence）
- `services/coach_engine.py`：处方选择、轨道、反依赖
- `services/orchestrator.py`：意图识别与路由（教练/命理/客服/销售）
- `services/commitment_store.py`：行动与反馈 SSOT

**Worker**
- `worker/push_scheduler.py`：每日提醒、周复盘（可用 cron/队列）

---

## 8. 后端：完整版八字（Deterministic Compute）设计

目标：同输入 + 同版本 → 输出结构化事实严格一致；不让 LLM “算八字”。

### 8.1 `facts` 最小字段集（MVP）

```json
{
  "profile": {
    "name": "张三",
    "gender": "男",
    "birth_local": "1990-01-01 12:34:00",
    "tz_offset_hours": 8,
    "location": {"name": "北京", "longitude": 116.4074, "latitude": 39.9042}
  },
  "pillars": {
    "year": {"gan": "庚", "zhi": "午", "pillar": "庚午"},
    "month": {"gan": "己", "zhi": "丑", "pillar": "己丑"},
    "day": {"gan": "甲", "zhi": "子", "pillar": "甲子"},
    "hour": {"gan": "丙", "zhi": "寅", "pillar": "丙寅"}
  },
  "day_master": {"gan": "甲", "element": "木"},
  "wuxing": {"金": 1, "木": 2, "水": 2, "火": 2, "土": 1},
  "ten_gods": {"year_gan": "七杀", "month_gan": "正财", "hour_gan": "食神"},
  "hidden_stems": {
    "year_zhi": [{"gan": "丁", "percent": 70}, {"gan": "己", "percent": 30}],
    "month_zhi": [{"gan": "己", "percent": 60}, {"gan": "癸", "percent": 40}]
  },
  "strength": {"day_master_strength": "strong|weak|neutral", "notes": ["...可解释依据..."]},
  "pattern": {"name": "格局名（可空）", "confidence": "high|medium|low"},
  "useful_god": {"favorable": ["水", "木"], "unfavorable": ["土"], "confidence": "medium"},
  "luck": {
    "da_yun": [{"start_age": 8, "pillar": "庚寅", "start_year": 1997}],
    "liu_nian": [{"year": 2026, "gan_zhi": "丙午", "signals": ["..."]}]
  },
  "version": {"compute_version": "bazi-mvp-0.1", "facts_hash": "sha256:..."}
}
```

### 8.2 “格局/喜用”在 MVP 的表达策略（避免伪精确）

- 输出允许给候选，但必须给 `confidence`，并明确其用途是“指导行动处方”，不是“命运宣判”。
- 默认只给 `Intervention Window`（行动有效期）；`Forecast Window` 只能用概率/条件句表达（与 v4 一致）。

---

## 9. 八字知识库（`fortune_ai/knowledge/bazi`）接入设计

### 9.1 目标

- 将 PDF 内容变成“可检索证据”，用于回答“为什么这么判断”，并降低幻觉。
- 关键结论必须带 `kb_ref`（文档 + 页码/段落）。

### 9.2 索引流程（建议离线构建）

**输入**：`fortune_ai/knowledge/bazi/*.pdf`  
**输出**：一个可版本化的 snapshot（如 `bazi_kb_snapshot_2025-12-29`）

流程：
1) PDF → 文本抽取（保留：文件名、页码、标题层级）
2) 切分 chunk（建议 300–800 中文字；chunk 之间允许 50–100 字重叠）
3) 建索引（MVP 推荐优先）  
   - `sqlite FTS5`（BM25，易落地，无需 embedding）
4) 检索：输入 query + facts → 返回 top-k chunks（含 `kb_ref`）

### 9.3 检索策略（Structured RAG）

- 先基于 `facts` 生成检索 query（例：`甲木 日主 身强 喜用 水 木`）。
- 再基于用户问题生成补充 query（例：`跳槽 焦虑 决策`）。
- 合并去重后取 top-k（建议 k=5..12）。

---

## 10. 对外 API 与数据契约（MVP）

### 10.1 复用现有 API（现状）

- `POST /api/chat/ask`：提交对话任务（异步 job）
- `GET /api/v2/report/{job_id}`：轮询获取 A2UI/Markdown 输出
- `POST /api/v2/submit`：生成八字报告任务（异步 job）
- `POST /api/rectify/v3/stream`：出生时间校准（SSE）

### 10.2 MVP 新增 API（建议）

> 目标：把“非语言交互”拆成可验收接口，避免所有功能都挤在 Chat prompt 里。

**Bento**
- `POST /api/bento/today`
- `POST /api/bento/checkin`
- `POST /api/bento/plan/subscribe`
- `POST /api/bento/plan/complete`
- `POST /api/bento/reflect`

**Push**
- `POST /api/push/pause`
- `POST /api/push/set-time`

统一字段：
- `persona_style`: `"standard" | "warm" | "roast"`
- `track`: `"decision_clarity" | "emotional_regulation" | "communication_power"`

---

## 11. 数据与存储（MVP 最小可行）

### 11.1 SSOT 建议

- `fortune_user`（已存在）：用户基础资料（含出生信息、地点、性别）
- `conversation_log`（现状为本地 `user/<id>/conversations/*.jsonl`；MVP 可先沿用）
- 新增（用于闭环与推送）：
  - `user_plan`：计划订阅与轨道配置
  - `user_commitment`：承诺的行动（task）
  - `user_checkin`：情绪打卡与反馈
  - `push_subscription`：提醒时间、渠道、暂停状态

### 11.2 隐私边界（MVP）

- 出生信息、地点属于高敏：需要明确用户同意；支持删除与更新。
- 输出侧避免“对第三方道德定性”；不做恐吓式表述。

---

## 12. 埋点与验收（MVP 可验收口径）

### 12.1 WCG 事件口径（最小集合）

- `trigger`: 打开今日卡 / 点击 push / 发起对话
- `guidance_shown`: 展示 Guidance Card（有 `card_id`）
- `commitment_made`: 用户确认一个行动（记录 `task_id`）
- `action_done`: 行动完成
- `feedback`: 复盘/情绪变化（0–10 或文本）

### 12.2 MVP 验收标准（建议）

**体验**
- 所有核心路径满足“三点击原则”。
- Chat 回复遵循“共情→分析→处方→承诺”模板，处方 ≤3。
- `standard/warm/roast` 可切换（风格只影响表达，不影响事实）。

**后端**
- 八字 facts 可重复（同输入同版本 `facts_hash` 一致）。
- 关键结论可追溯（至少 1 个 `kb_ref` 或 `rule_id`）。

**主动服务**
- 默认仅订阅用户生效；一键暂停/改时间可用；无随机推送。

---

## 13. MVP 交付里程碑（建议 2–4 周）

1) Week 1：Bento 卡片与新 API（今日卡/打卡/计划订阅/行动完成）；persona 切换；WCG 埋点。  
2) Week 2：完整版八字 facts 输出（含大运/流年）；facts_hash；基础解释模板（不靠 LLM 乱算）。  
3) Week 3：知识库离线索引 + 检索接入；evidence 引用；反依赖机制。  
4) Week 4（可选）：push scheduler + 渠道接入（站内 + 1 外部渠道），周复盘闭环。  

---

## 14. 开放问题（写在 MVP 里便于决策）

1) 付费触发点优先级：深度报告 vs 30 天计划订阅（建议先做计划订阅，更贴“提升”）。  
2) `格局/喜用` 的透明度（0–10）：MVP 默认建议 6（给依据 + 置信度，不堆黑话）。  
3) Push 渠道优先：站内 + Telegram/企微/微信模板消息哪个先做？（按增长渠道决定）。  

