下面给你一套“把市场当用户、把公司/板块当 item”的**上下文推荐系统**设计方案，满足你两个硬约束：

* **不自己训练模型**（不训练任何 ML/DL 预测器）
* **完全依赖大模型 API**（LLM + Embedding + RAG + 多次调用/投票），外加你自己做的**确定性特征计算/检索/回测**（这不算训练）

目标：给定“当前市场状态上下文”，输出未来 **1–3 个月**（短期）或 **6–12 个月**（中期）**涨幅 Top-K 的行业/板块**（rank + 置信度）。

---

## 1) 先把问题建模成“上下文推荐”

你说“市场是用户、公司是 item”。更准确的可落地抽象是：

* **User = Market State at time t**（把每个时点的市场状态当成一个“虚拟用户”）
* **Item = Sector/Industry（或公司）**（你最终要 Top-K 行业板块）
* **Context = 当前宏观/流动性/风险偏好/政策/事件/结构等状态**
* **Label = 未来 horizon 的相对收益**（比如行业相对基准的超额收益，或收益排名）

这其实是“Context-aware Recommender”：
[
\text{score}(sector, t, h) \rightarrow \text{rank topK}
]

关键点：你不是在预测一个绝对价格，而是在做**在当前上下文下的“偏好排序”**（哪个板块更可能被资金偏爱）。

---

## 2) 你会踩的 4 个坑（先直说）

1. **样本太少 + 非平稳**
   6–12 个月尺度可用样本非常有限（尤其如果是按月快照），且宏观机制会变。

2. **LLM 自己不会“凭空”有 alpha**
   如果没有结构化数据信号 + 历史类比，它很容易变成“讲得通但不赚钱”的叙事机。

3. **信息泄露（最致命）**
   你做回测时，如果把未来新闻摘要/财报数据“无意中”塞进 prompt，效果会假到离谱。

4. **输出不稳定**
   同一输入，多次调用 LLM 排名会漂。必须用**结构化输出 + ensemble/投票 + 校验器**。

所以系统必须是：**数据驱动 + LLM 做压缩/解释/类比/重排，而不是单纯让 LLM 猜。**

---

## 3) 总体架构：三层 = 数据层 / 表征层 / 决策层

### 3.1 数据层（你自己算，LLM 不算数值）

**Market Context（市场状态）**建议至少 6 组信号：

1. **风险偏好与波动**

   * 指数波动（如 VIX / HV / 波动率期限结构）
   * 风险溢价代理：信用利差、CDS、TED、融资利率（视市场而定）
   * 市场宽度：上涨家数、创 52 周新高新低、成交集中度

2. **利率与流动性**

   * 无风险利率水平与变化（10Y、2Y、曲线斜率）
   * 流动性代理：央行资产负债表、M2、回购利率、美元流动性指标（视市场而定）

3. **宏观增长/通胀预期**

   * PMI、工业产出、就业、通胀预期（breakeven）
   * surprise index（宏观数据超预期）

4. **风格因子表现（相当于市场“口味”显性化）**

   * value/growth、quality、low vol、momentum、size 等近 1–3 个月相对表现
   * “大盘 vs 小盘”“高股息 vs 成长”等

5. **资金流与仓位**

   * ETF/基金申赎、北向/两融/期权 OI、期货净持仓（取决于你覆盖市场）
   * 期权 gamma 环境、偏度（skew）

6. **事件日历与政策环境**

   * FOMC/央行会议、财报季、重大政策窗口
   * 监管/产业政策强度（可做文本量化）

**Item Features（板块/行业特征）**建议至少 5 组：

1. **动量与相对强弱**

   * 1m/3m/6m 相对基准动量、趋势强度、回撤
2. **估值与盈利**

   * PE/PB/EVEBITDA（行业聚合）
   * 盈利增速、ROE、利润率、资产负债表质量
3. **盈利预期修正**

   * 分析师盈利预测上修/下修、盈利惊喜
4. **敏感度/暴露（Beta to macro）**

   * 对利率、油价、汇率、通胀的历史敏感度（这里可用简单回归估计——不是训练 LLM）
5. **行业级新闻/舆情/政策主题**

   * 产业政策、供需、地缘、技术周期、监管风险（文本类信号）

> 重要：数值特征要**标准化**（z-score、分位数、同比变化），否则 LLM 读数值会很糟。

---

## 4) 表征层：把“市场状态”做成可检索、可比对的“用户卡片”

你需要两种表征同时存在：

### 4.1 结构化 Market State Card（强制 JSON）

这是给 LLM 的“输入真相”，要像 API 一样稳定：

```json
{
  "asof": "2025-12-28",
  "horizon": "1-3m",
  "market": "CN_A_or_US_or_global",
  "context_features": {
    "risk": {"vix": 18.2, "credit_spread_z": 0.7, "breadth_pct_z": -0.3},
    "rates": {"10y_change_3m_bp": -25, "curve_2s10s_bp": -40},
    "liquidity": {"liquidity_z": 0.4},
    "macro": {"pmi_trend_z": -0.2, "inflation_trend_z": -0.5},
    "style": {"growth_minus_value_1m": 1.2, "momentum_1m": 0.8},
    "flows": {"equity_etf_flow_z": 0.3, "put_call_z": -0.6}
  },
  "events": ["earnings_season_upcoming", "central_bank_meeting_in_2w"]
}
```

### 4.2 文本型 Market Narrative（给 embedding / 类比检索）

把上面的结构化特征压缩成**短文本**（200–400 字），用于向量化检索历史相似状态（“相似用户”）：

> “波动温和、利率下行、信用利差走阔但未失控，市场风格偏成长+动量，宽度略弱，资金净流入温和，财报季临近……”

这个 narrative 由 LLM 生成，但必须只基于结构化输入（避免夹带外部知识）。

---

## 5) 决策层：两条主线 + 一个融合器（推荐你这么做）

你要的是 Top-K 排名，最稳的做法是：

### 主线 A：**类协同过滤（User-based CF）= 历史相似状态 → 条件期望收益**

这条线几乎不需要 LLM 的“预测能力”，它只用 LLM/embedding 来做“相似用户检索”。

**做法：**

1. 建一个历史库：每个历史月/周一个 Market State Card + Narrative
2. 对每个历史时点，存未来 horizon 的**行业收益排名/超额收益**（这是 label，但不是训练）
3. 预测时：

   * 对当前 narrative 做 embedding
   * 召回最相似的 N 个历史 state（N=30/50）
   * 计算每个行业在这些相似 state 下的平均/中位数超额收益，得到 **CF Base Score**

优点：

* 没有训练
* 可解释（“类似 2019Q1/2020Q2 那种环境，赢家是什么”）
* 不容易被 LLM 幻觉带跑

缺点：

* 如果市场机制变了或历史库太短，会失灵

### 主线 B：**“偏好向量 × 行业暴露” = 可解释的上下文匹配打分**

这条线把“市场口味”显式化，最贴合你“市场是用户”的设定。

**核心：**

* Market Preference Vector（市场偏好向量）：比如对 “利率敏感/成长/防御/商品/高股息/动量”等维度的权重
* Sector Exposure Vector（行业暴露向量）：行业对这些维度的暴露（可静态 + 动态）

然后：
[
\text{score} = w^\top x + \text{adjustments}
]

**实现上不训练：**

* 行业暴露向量：可以用两种方式

  1. **LLM 生成静态行业画像**（科技=高久期/成长，银行=利率敏感…）+ 定期人工审核
  2. 或用简单历史回归得到 beta（这不是训练 LLM，是传统统计估计）
* 市场偏好向量：每次由 LLM 根据 context_features 输出（并输出置信度/主导驱动）

再加一些显性调整项（你自己算）：

* 相对动量加分（短期更重要）
* 估值与修正（中期更重要）
* 盈利预期上修（中期重要）
* 风险惩罚（高波动/高回撤行业惩罚）

优点：

* 强解释性
* 可以做短期/中期两套权重逻辑（下面我会给）

缺点：

* 行业暴露如果做得粗，会偏概念化

### 融合器：A/B 两条线 + LLM 作为 re-ranker（最后一公里）

最终得分建议是：
[
S = \alpha S_{CF} + (1-\alpha) S_{Pref}
]
然后把 Top 2K 候选扔给 LLM 做“再排序/剔除明显冲突”，输出最终 Top-K + 置信度。

> 为什么要 re-rank？
> 因为 A/B 都是“统计/结构化逻辑”，但真实市场会被事件/政策冲击扭曲，LLM 更擅长识别“叙事一致性”和“当下主线冲突”。

---

## 6) 短期 vs 中期：同一系统，两套 horizon 配置

### 6.1 短期（1–3 个月）更像“资金偏好”

建议偏重：

* **相对动量/趋势**
* **资金流/仓位变化**
* **风险偏好与波动环境**
* **事件驱动**（财报季、政策窗口、供给冲击）

偏好向量示例维度（可让 LLM 输出）：

* risk_on (0~1)
* duration_preference（利率下行→久期偏好）
* momentum_preference
* liquidity_sensitivity
* policy_theme_intensity（政策主题强度）
* dispersion（行业分化程度）

### 6.2 中期（6–12 个月）更像“盈利与估值均值回归 + 商业周期”

建议偏重：

* **盈利预期修正**（尤其是持续上修）
* **估值分位**（贵/便宜在中期更起作用）
* **宏观周期定位**（复苏/滞胀/衰退/再通胀）
* **结构性景气度**（产业周期）

中期偏好向量维度可以不同：

* growth_cycle（增长周期）
* inflation_cycle（通胀周期）
* real_rate_trend（真实利率）
* earnings_revision_weight
* valuation_mean_reversion_weight
* quality_preference（财务质量/护城河偏好）

---

## 7) LLM 在系统里具体干什么：5 个角色（建议多代理）

你要的不是一个“万能 prompt”，而是**分工明确的 LLM 模块**，每个模块输出结构化结果，便于回测与监控。

### 角色 1：State Encoder（市场状态编码器）

输入：Market State Card（结构化）
输出：

* Regime labels（比如 risk-on/off、inflation up/down、rates up/down）
* Preference Vector（权重 + 置信度）
* 关键驱动（Top 3 drivers）
* 不确定性（0~1）

**必须 JSON 输出**，并限制数值范围。

### 角色 2：Analog Retriever Helper（类比检索助手）

你可以不用 LLM 做检索（用 embedding 向量检索即可），但 LLM 可以做两件事：

* 用当前 state 生成更稳健的 narrative（用于 embedding）
* 对召回的历史类比做“相似性解释”和“剔除不合理类比”（比如结构不同）

### 角色 3：Sector Card Summarizer（行业卡片摘要器）

输入：行业的结构化特征 + 近期行业新闻摘要
输出：

* 行业当前状态摘要（动量/估值/修正/风险）
* 行业“催化剂/风险点”
* 行业暴露向量（如果你用 LLM 来生成）

### 角色 4：Ranker（打分与排序）

输入：

* Preference Vector
* 每个行业的结构化特征（最好是标准化后的）
* CF Base Score（来自主线 A）
  输出：
* 每个行业 score_short / score_mid
* Top-K
* 每个行业的 “why”（短解释，不要长篇推理）
* “如果错，会怎么错”（反事实风险）

### 角色 5：Critic/Verifier（审计与稳定器）

输入：Ranker 输出 + 原始特征
检查：

* 是否引用了不存在的数据（幻觉）
* 是否出现逻辑冲突（比如风险厌恶却推荐高 beta）
* 是否置信度与信号强度一致
* 是否出现 prompt injection（新闻里夹带指令）

输出：通过/不通过 + 修正建议 + 置信度折扣

> 这一步能显著提升线上稳定性，尤其当你接入新闻文本时。

---

## 8) “完全不用训练”情况下，怎么做历史记忆与类比检索

这是你系统的“灵魂”，也最像推荐系统的“协同过滤”。

### 8.1 历史库怎么存（关键）

每个时间点 t（建议周频或月频）存：

* `state_card_t`（结构化特征）
* `state_narrative_t`（LLM 生成的、只基于 state_card 的摘要）
* `future_returns_{sector, h}`（未来 1–3m 与 6–12m 的行业超额收益/排名）
* `notes`（重大事件标签，可人工或 LLM 打标签）

### 8.2 检索策略（别只用向量相似度）

建议两阶段：

1. **向量召回**（embedding 相似）取 top 200
2. **数值过滤**（结构化特征距离）筛到 top 30–50
   例如：要求利率趋势/波动水平/风险偏好标签一致，避免“叙事相似但关键变量相反”。

### 8.3 CF Base Score（无需任何训练）

对每个行业 i：

* 取相似历史状态集合 ( \mathcal{N}(t) )
* 计算行业未来超额收益的平均/中位数，或胜率：

  * `mean_excess_return(i)`
  * `P(i in topK | similar states)`

这直接就是“相似用户喜欢什么 item”。

---

## 9) 让系统“可回测、可迭代、可上线”的关键工程细节

### 9.1 强制结构化输入输出（Schema First）

* 输入给 LLM 的只允许：

  * JSON（数值特征）
  * 你自己生成的新闻摘要（而不是原始新闻全文）
* 输出必须可解析 JSON，字段固定，便于版本对比。

### 9.2 版本控制

你要对这三样做版本化：

* 特征版本（feature_v）
* prompt 版本（prompt_v）
* 检索版本（retrieval_v）

否则你永远找不到“为什么今天开始变差”。

### 9.3 稳定性：投票/自洽

* 同一次输入，调用 LLM 3–5 次（不同 seed），取 **Borda count** 或平均 rank
* 或用两种模型（一个强推理、一个便宜）做 ensemble

### 9.4 成本控制（很现实）

* 行业卡片/行业暴露向量：**低频更新**（周或月）
* 市场状态编码：可以日频，但要压缩 token
* 新闻：先用便宜模型做摘要，再给强模型做排序

---

## 10) 一个可直接落地的“端到端流程”（周频为例）

1. **Feature Builder（Python）**

   * 拉取市场/宏观/行业数据
   * 计算并标准化特征，写入 Feature Store

2. **State Narrative（LLM#1）**

   * 输入 state_card，输出 narrative + regime 标签（JSON）

3. **Retrieve Analogues（Embedding + Filter）**

   * 用 narrative embedding 召回历史相似状态
   * 数值过滤
   * 计算 CF Base Score（行业条件期望收益/胜率）

4. **Sector Cards（可缓存）**

   * 汇总每个行业特征 + 近期行业新闻摘要
   * LLM#2 输出 sector summary + exposure vector（或你自己维护 exposure）

5. **Ranker（LLM#3）**

   * 输入：state preference vector + CF score + 行业特征
   * 输出：短期 Top-K、中期 Top-K、置信度、风险提示（JSON）

6. **Critic/Verifier（LLM#4）**

   * 校验一致性与注入风险
   * 产出最终结果 + 置信度折扣

7. **Logging & Backtest Harness**

   * 把输入/输出/召回类比/最终排名写入日志
   * 每周滚动做 walk-forward 评估

---

## 11) 评估体系：别只看收益，要看“排序质量 + 稳定性”

至少要有这些指标（按 horizon 分开算）：

* **Top-K 命中率**：预测 Top-K 中有多少真的进入未来 Top-K
* **平均超额收益**：预测 Top-K 等权组合超额收益
* **Rank IC（Spearman）**：预测 rank 与真实收益 rank 的相关
* **稳定性**：相邻两期 Top-K 的 Jaccard 相似度（太跳=不可用）
* **置信度校准**：当模型说 0.8 置信时，真实胜率是否更高（否则置信度是装饰品）
* **回撤与极端期表现**：风险 off 时是不是系统性踩雷

---

## 12) 你可以直接用的 Prompt 设计模板（示意）

### State Encoder Prompt（输出偏好向量）

**System：**

* 只能基于输入 JSON 推断
* 不得引用外部事实
* 输出严格 JSON

**User：**

* state_card JSON（如上）
* horizon=1-3m 或 6-12m

**Output JSON：**

```json
{
  "regime": {
    "risk_on": 0.0,
    "rates_trend": "down",
    "inflation_trend": "down",
    "liquidity": "neutral",
    "dispersion": "high"
  },
  "preference_vector": {
    "momentum": 0.75,
    "duration": 0.60,
    "value": -0.20,
    "quality": 0.30,
    "commodity": -0.10,
    "defensive": 0.15
  },
  "top_drivers": ["rates_falling", "momentum_strong", "breadth_weak"],
  "uncertainty": 0.35
}
```

### Ranker Prompt（融合 CF + 偏好匹配）

输入包含：

* preference_vector
* CF base scores（每行业一个）
* 行业特征表（最好也是 JSON 数组）

输出：

* 每行业 score、解释、风险点
* Top-K 短期/中期

---

## 13) 最推荐的 MVP 路线（别一上来就“全自动”）

**第 1 阶段（2–4 周）**：先做主线 A（类协同过滤）

* 建历史 state 库 + embedding 检索 + CF base score
* 输出 Top-K + 解释（解释可以后加）
* 先验证：是否在多个年份能稳定有正的排序 IC

**第 2 阶段（再 2–4 周）**：加主线 B（偏好向量 × 行业暴露）

* 行业暴露先做静态（LLM 生成 + 你人工审核）
* preference_vector 日/周更新
* 做 A+B 融合

**第 3 阶段（再 2–4 周）**：加新闻/政策文本信号 + Critic

* 先摘要再入模，防注入
* 加 verifier 做一致性与风险过滤

---

## 14) 现实提醒（但也是机会）

你这个方向如果做得好，优势不是“LLM 神奇预测”，而是：

* 用 LLM 把**杂乱市场状态压缩成可检索、可对比的表示**
* 用历史类比把“市场偏好”变成一个**可解释的条件分布**
* 用 LLM 做最后的“叙事一致性 re-rank”和风险审计
* 全流程可回测、可监控、可迭代（这才是能长期跑的系统）

---

如果你愿意，我可以在你不补充任何额外信息的前提下，直接给你一份更“工程化”的设计稿，包括：

* 具体行业层级（GICS/申万/中信）怎么映射
* 每组 context/item 特征的最小集合（MVP 20–40 个特征）
* 历史库的表结构（state_table / sector_table / label_table）
* 检索与融合的伪代码（含投票与置信度校准）
* 防数据泄露 checklist（回测必备）

你只要告诉我：你主要做 **A 股 / 美股 / 港股 / 全球** 哪个市场（一个就行），我就按那个市场的可获得数据来落细。


下面我按你这两条要求，把系统升级成一个“真正交易台能用”的完整版：**市场状态 = 专业交易员的 regime + 资金行为 + 前瞻定价**；**item = GICS 子行业 + 主题（Theme）**，并且 item 的状态以**产业链/供需/定价/库存/资本开支周期/盈利预期**为主，而不是泛泛的风格因子。

我会把它设计成：**不训练任何模型**，只用 **LLM API + Embedding/RAG + 规则/统计计算**（你自己算数值不算训练），最后输出**短期(1–3m)/中期(6–12m) Top-K 子行业与主题**，并给出“可证伪”的交易员式解释。

---

## 0) 你要的不是“预测涨跌”，而是“预测下一段时间资金会偏爱什么”

顶级 trader/analyst 做的事情，本质是两步：

1. **判断市场现在处于什么交易环境（regime）**：是 risk-on 追涨、还是 risk-off 防御、是通胀/利率驱动、还是增长/政策驱动？市场在定价什么、最怕什么？
2. **在这个环境下，找“被低估的盈利路径 + 正在改善的预期 + 有催化剂 + 资金容易去”的篮子**
   这其实就是“市场这个用户”在当下的偏好排序。

所以系统要把“市场状态”做成：**谁在开车（driver）+ 资金怎么走（flow/positioning）+ 市场前瞻定价（implied expectations）**。

---

## 1) 总体架构：三张卡 + 两条主线 + 一个交易台式风控覆盖

### 三张卡（必须结构化）

* **Market Regime Card（市场状态卡）**：专业指标 + 前瞻定价 + 事件风险
* **Item Fundamental Card（子行业/主题基本面卡）**：产业链/供需/定价/库存/资本周期/预期修正
* **Catalyst & Risk Card（催化剂与风险卡）**：未来 1–3m / 6–12m 的“会改变预期的东西”

### 两条主线（不训练）

* **主线 A：历史相似环境检索（Analog/“协同过滤”）**
  现在的市场状态像历史哪些阶段？当时 1–3m/6–12m 领先的是哪些子行业/主题？
* **主线 B：交易逻辑匹配（Context → Preference → Fundamental Fit）**
  当前 driver 决定市场更看重哪些基本面维度（定价权？库存周期？capex？盈利修正？），让 item 自己的“基本面状态向量”去匹配。

### 风控覆盖（交易员必备）

* **拥挤度/定价偏离/尾部风险**：避免“对但死在路上”
* **情景分析（Scenario）**：如果利率/油价/美元/信用利差反向动，会不会全盘崩？

---

## 2) 市场状态（Market Regime）：用“交易员的面板”重构，且加入前瞻数据

下面这部分是核心。我按真实交易台把 Market Regime 分成 10 个模块。你不需要每个都全做，**但至少要覆盖：风险/利率/信用/波动/仓位/前瞻定价/事件**，否则系统会很“研究员”而不“交易员”。

### 2.1 Price Action & Breadth（价格行为与宽度：市场是否健康）

> Trader 看这个判断“上涨是健康扩散还是少数权重股硬拉”

* 指数层面：趋势强度（20/60/200 日均线斜率、突破/失败次数）
* 宽度：上涨家数占比、创新高/新低比、等权 vs 市值加权表现差、行业扩散度
* 领涨结构：Top N 权重贡献度（集中度越高，越脆）
* 反转信号：急跌后修复速度、gap 回补、弱转强/强转弱频率

**前瞻性**：宽度和集中度是“领先风险”的信号——指数还在涨，但宽度先崩，后面容易出事。

---

### 2.2 Volatility Surface（波动率曲面：市场在给“尾部风险”标什么价）

> 真正专业的“市场情绪”不看新闻，看期权定价

* **隐含波动率期限结构**（term structure）：短端抬升 = 近期事件风险/恐慌；长端抬升 = 结构性不确定性
* **偏度/微笑（skew/smile）**：put skew 变陡 = 下行保护需求高，risk-off
* **隐含相关性/分散度**：指数 IV 与成分股 IV 的关系（dispersion trade）
  分散上升通常对应“个股/行业分化机会”
* **隐含分布**（从期权提取的概率）：尾部概率、负偏度强弱（不是精确预测，但很有信息量）

**前瞻性**：期权是在“用真钱投票”未来波动与尾部风险。

---

### 2.3 Rates & Curve & Implied Path（利率与曲线：谁在主导估值）

> 很多板块轮动，本质是“久期交易”

* 2Y/10Y 水平与变动（1w/1m/3m）
* 曲线形态（2s10s、5s30s）、实际利率 vs 名义利率
* **breakeven（通胀预期）**：名义-实际
* **前瞻路径**：OIS/利率期货隐含未来加息/降息概率、政策路径的“市场共识”
* 利率波动（rates vol）：利率波动上来，权益久期股更不稳

**前瞻性**：期货/掉期隐含路径是“未来 6–12m 资金贴现率假设”的核心输入。

---

### 2.4 Credit & Funding（信用与融资：风险的真正阀门）

> 只看股票会晚一步，信用先出问题

* 投资级/高收益利差（spread）与变化速度
* CDS 指数（如果可得）
* 融资利率、回购利率、美元流动性（跨境市场很关键）
* 企业债发行窗口是否打开（发行量、利差定价）

**前瞻性**：信用利差抬升常常领先 equity risk-off；融资收紧会杀高杠杆行业。

---

### 2.5 Liquidity & Policy（流动性与政策：有没有“水”和“方向”）

> 流动性不是宏大叙事，是交易结果的约束

* 央行资产负债表变化、财政投放节奏（因市场而异）
* 金融条件指数（FCI）或你自建的综合流动性指标
* 监管与产业政策强度（文本量化：政策密度、措辞强硬度）

**前瞻性**：政策是典型的“信息不对称”来源，LLM 在政策文本解析上非常有用。

---

### 2.6 Positioning & Flows（仓位与资金流：短期涨跌最敏感）

> “谁的仓位太满/太空”决定短期非线性

* ETF/共同基金申赎
* 期货净持仓（COT 或当地等价数据）
* 两融/保证金、融券、借贷成本（borrow）
* 机构仓位 proxy（CTA 趋势资金、风险平价敞口 proxy）
* 期权 OI 与 put/call、dealer gamma（如果能估）

**前瞻性**：仓位是“未来被迫买/卖”的来源，尤其对 1–3m。

---

### 2.7 Cross-Asset Dashboard（跨资产：谁在讲真话）

> 顶级宏观交易员一定盯跨资产一致性

* 美元指数/汇率、商品（油/铜/农产品）、运费（如 BDI）、黄金
* 商品期限结构（contango/backwardation）反映供需紧张与库存
* 股票 vs 信用 vs 利率的“风险信号是否一致”
* 全球相对强弱：美股/欧股/新兴、不同市场风险偏好差

**前瞻性**：商品期限结构、信用、汇率往往领先“宏观叙事”。

---

### 2.8 Earnings & Expectation Machine（盈利与预期机器：中期的核心）

> 中期(6–12m)本质是“预期修正 + 盈利兑现”

* 分析师一致预期：EPS/营收增速变化（上修/下修幅度与广度）
* 指引（guidance）情绪：电话会措辞、订单能见度关键词
* 财报“预期差”：超预期幅度、市场反应（beat but down 说明预期过高）
* **隐含财报波动**：财报前后 IV，市场在为“惊喜”付多少钱

**前瞻性**：盈利预期上修广度，是最强的中期横截面信号之一。

---

### 2.9 Event Risk Calendar（事件风险：短期最容易翻车）

> Trader 必须知道未来 30–90 天“会让预期重定价”的点

* 央行会议、通胀/就业、财报季、重要政策窗口
* 行业特定：重要产品发布/招标/行业会议/监管节点
* 地缘与供给事件（能源、航运、关键矿）

**前瞻性**：事件让“均值回归”失效；短期必须把事件当成一等公民。

---

### 2.10 Market “Pricing of Narratives”（市场正在定价什么叙事）

> 这是 LLM 的强项：把“叙事”变成结构化变量

* 主题热度：新闻/研报/电话会提及频次与情绪
* 叙事集中度：是不是所有人都在讲同一个故事（拥挤风险）
* 叙事—价格一致性：故事越来越热但价格不涨 = 可能被证伪/资金不买单

---

## 3) Item 细化：GICS 子行业 + Theme（主题）作为统一 item 接口

你要做到“子行业 + 主题”，关键是：**把主题当成一种虚拟子行业**，它也有成分股、也能算聚合基本面、也能算产业链指标。统一接口后系统才可扩展。

### 3.1 Item Universe 设计（统一接口）

* `item_type`: `"gics_subindustry"` 或 `"theme"`
* `constituents`: 股票列表 + 权重（市值权重/等权/流动性权重）
* `coverage`: 覆盖率（成分股财务可得比例、主题纯度）
* `versioning`: 主题定义版本号（防止主题漂移导致回测失真）

### 3.2 Theme（主题）怎么定义才不“玄学”

主题的定义必须满足三条，不然就是自欺欺人：

1. **可操作**：能映射到可交易的成分股（且流动性够）
2. **可度量**：至少有 3–5 个主题 KPI 能按周/月更新
3. **可进化**：随着产业链变化，成分股会变化（但要版本化）

举例：`AI` 不是一个点，它是链条：

* 算力：GPU/加速卡、HBM、先进封装、光模块/交换机、服务器电源/散热
* 云与平台：云厂商 capex、AI 平台软件
* 应用：企业软件、广告、搜索、内容生产
* 约束：电力、数据中心供给、出口管制/监管

主题 item 要拆成子段（segments），否则太宽泛。

---

## 4) Item 状态：必须以“产业链 + 预期修正”做主干（不是风格因子）

下面是我建议的 **Item Fundamental Card** 结构。你会发现它更像 sell-side/ buyside 行业研究框架，而不是量化因子列表。

### 4.1 Fundamental 6 维主框架（每个子行业/主题都要能填）

1. **Demand（需求）**

   * 订单/招标、出货量、终端销量、活跃用户/ARPU（主题应用类）
   * 领先指标：新订单指数、渠道反馈、搜索/招聘/流量等另类数据（可选）
2. **Supply/Capacity（供给/产能）**

   * 产能利用率、产能扩张计划、供给瓶颈（设备交期、关键材料）
3. **Pricing（定价/ASP/议价权）**

   * ASP 趋势、价格传导能力、折扣/促销强度
4. **Inventory（库存）**

   * 渠道库存/天数、去库存/补库存阶段（库存周期是行业轮动的大驱动）
5. **Cost/Input（成本与投入品）**

   * 关键原材料/能源/运费/工资，成本压力与对冲
6. **Capital Cycle（资本周期/Capex）**

   * Capex 强度、订单能见度、ROIC/边际回报变化
   * 资本开支周期常常决定 6–12m 的供需格局

> 这 6 维就是你说的“产业链”，而且能跨行业复用。

### 4.2 Expectations & Revisions（预期与修正：决定中期胜负）

* 一致预期 EPS/营收的**上修/下修幅度 + 广度**
* 电话会指引情绪与关键词（“需求能见度”“客户延迟”“库存正常化”等）
* “预期差”刻画：beat/miss + 股价反应（市场真实预期）

### 4.3 Valuation vs Quality（估值与质量：不是风格，是约束）

你不想做“风格因子”，但估值/质量是不可忽略的约束层：

* 估值分位（相对自身历史/相对市场/相对同行）
* 现金流质量、杠杆、利息覆盖（利率环境变时非常关键）
* 资本回报（ROIC）趋势

### 4.4 Crowding & Reflexivity（拥挤与反身性：交易员视角）

同一个基本面状态，在不同拥挤度下结局不同：

* 主题热度过高 + 估值极端 + 期权偏度极端 = 容易“利好出尽”
* 空头拥挤 + 基本面改善 = squeeze 风险（短期机会）

---

## 5) 关键工程：建立“产业链/主题知识图谱”，让 LLM 不再泛泛而谈

你要的“从产业链角度定义 item”，最硬核的做法是建一个 **Industry/Theme Graph**：

### 5.1 图谱节点

* Company（公司）
* Subindustry（GICS 子行业）
* Theme（主题）
* Product/Component（产品/零部件）
* Input（投入品：铜、DRAM、电力、运费…）
* Customer Segment（下游客户/行业）
* KPI（可度量指标：出货、价格、库存天数、capex、订单…）
* Event（政策、监管、会议、产品发布、招标）

### 5.2 图谱边（关系）

* “A 供应给 B”“A 依赖 X”“A 的 KPI 受 Y 驱动”“政策 P 影响子行业 S”
* 这些关系从：财报电话会、10-K/年报、研报摘要、政策文件中抽取

### 5.3 LLM 在图谱中的工作（无训练）

* **抽取**：实体识别 + 关系抽取（结构化 JSON）
* **归一化**：同义词合并（HBM/高带宽内存）
* **更新**：每周扫描新增文本，更新关系置信度
* **查询**：当你要解释“为什么某主题会赢”，系统可以沿图谱给出链路：
  “云 capex 上调 → 光模块订单/交期改善 → 子行业盈利预期上修 → 资金流入”

这会让解释从“风格叙事”升级成“产业链推导”。

---

## 6) 不训练的预测/排序引擎：我建议用“交易台三段式”

### 6.1 第一步：候选召回（Candidate Generation）

不要一上来让 LLM 对全 universe 排序，太慢且不稳。先用三种召回拼出候选池（例如 30–60 个 item）：

1. **Analog Recall（历史相似环境召回）**

   * Market Regime narrative 做 embedding
   * 召回历史 N 个相似 regime（周/月快照）
   * 统计当时 1–3m/6–12m 领先的子行业/主题 → 候选
2. **Fundamental Improvement Recall（基本面改善召回）**

   * 预期上修广度 Top、库存拐点、价格拐点、capex 上行等 → 候选
3. **Catalyst Calendar Recall（催化剂召回）**

   * 未来 30–90 天有明确事件驱动的主题/子行业 → 候选

> 这一步完全不需要训练，只靠检索 + 规则筛选。

---

### 6.2 第二步：打分（Scoring），核心是“市场偏好 × 基本面状态”

这里你要避免“浅薄风格因子”，我给你一个更交易员的分数分解：

对每个 item 生成 5 个分数（都可由你计算/或 LLM 输出结构化评分）：

1. **Fundamental Cycle Score（产业周期得分）**

   * 需求/供给/定价/库存/成本/capex 的综合“改善程度 + 领先性”
2. **Expectation Revision Score（预期修正得分）**

   * EPS/营收上修速度、广度、持续性
3. **Catalyst Score（催化剂得分）**

   * 未来 1–3m 是否存在“会改变预期”的事件，且概率/影响大
4. **Crowding & Valuation Penalty（拥挤与估值惩罚）**

   * 太拥挤/估值极端 → 扣分（尤其短期）
5. **Context Fit Score（环境匹配得分）**（最关键）

   * 由 Market Regime 的 driver 决定：现在市场更奖赏哪种基本面？

#### 环境匹配怎么做（不训练）

* 让 LLM 把 Market Regime Card 输出成一个 **Preference Vector**，但维度不是风格，而是**基本面维度权重**：

示例（短期 1–3m）：

* `pref_pricing_power`（定价权偏好）
* `pref_inventory_turn`（库存拐点偏好）
* `pref_capex_upcycle`（资本开支上行偏好）
* `pref_earnings_revision`（上修偏好）
* `pref_balance_sheet`（资产负债表偏好）
* `pref_duration_sensitivity`（久期敏感偏好，利率驱动时很重要）
* `pref_policy_beta`（政策 beta 偏好）

再让每个 item 的 Fundamental Card 输出对应的 **State Vector**（0–1 或 z-score），两者点乘就是 Context Fit。

这样你就不是“成长/价值因子”，而是“市场现在更喜欢：库存去化完成 + ASP 回升 + 上修开始”的行业。

---

### 6.3 第三步：LLM Re-rank（最后一公里），加“交易员式审计”

把候选池（30–60）和上述结构化分数喂给 LLM 让它做两件事：

1. **Re-rank**：结合产业链逻辑与 driver 一致性做排序微调
2. **Critic/Verifier**：检查逻辑冲突与“编故事”

   * risk-off 却推高 beta 高杠杆 → 直接打回
   * 没有任何 KPI/预期修正支撑 → 置信度降级
   * 主题解释无法沿图谱串联 → 视为“空洞叙事”

输出必须结构化：Top-K + 每个 item 的 3 条证据 + 1 条反证（如何证伪）+ 置信度。

---

## 7) 关键：前瞻性数据怎么接入（你要求的“加入前瞻数据”）

你不训练模型，但你可以接入“市场已经在前瞻定价”的数据，以及“企业/产业链领先指标”。我按成本从低到高给你路径：

### 7.1 低成本但高价值（强烈建议优先）

* 利率期货/OIS 隐含路径
* 期权 IV term structure、skew、隐含财报波动
* 分析师一致预期上修/下修（很多数据源可得）
* 大宗商品期货曲线（库存/供需紧张的前瞻）
* 企业财报电话会文本（LLM 抽取指引变化、订单能见度）

### 7.2 中成本（看你数据源）

* ETF/基金资金流与持仓变化
* 期货净持仓、gamma/仓位 proxy
* 行业价格指数、交期、库存（部分需要行业数据）

### 7.3 高成本另类数据（有了会很强，但不必一开始就上）

* 信用卡消费、web 流量、app 下载、招聘数据
* 卫星/物流/供给链数据
* 企业订单/交付实时指标

系统设计上，你只要保证这些数据进入 Item Fundamental Card 的“Demand/Supply/Pricing/Inventory”维度即可，不需要训练任何模型。

---

## 8) 数据结构（给你一套能直接落库的 schema）

### 8.1 Market Regime Card（建议 JSON）

```json
{
  "asof": "YYYY-MM-DD",
  "horizon": "1-3m",
  "modules": {
    "breadth": {"eqw_minus_mcap_z": -0.4, "new_high_low_z": -0.6, "concentration_z": 1.2},
    "vol_surface": {"iv_term_slope_z": 0.8, "skew_z": 1.1, "dispersion_z": 0.6},
    "rates": {"real_rate_trend_z": -0.7, "implied_cut_prob": 0.65, "curve_z": -0.5},
    "credit_funding": {"hy_spread_z": 0.4, "funding_stress_z": 0.2},
    "flows_positioning": {"equity_flow_z": 0.3, "cta_exposure_z": 0.9, "dealer_gamma": "positive"},
    "cross_asset": {"usd_z": -0.2, "oil_curve_tightness_z": 0.5},
    "earnings_expectations": {"revision_breadth_z": 0.1, "earnings_implied_move_z": 0.7},
    "event_risk": {"next_30d_risk": ["cb_meeting", "earnings_peak_week"]}
  }
}
```

### 8.2 Item Fundamental Card（子行业/主题通用）

```json
{
  "item_id": "theme_AI_infra",
  "item_type": "theme",
  "constituents_quality": {"purity": 0.72, "coverage": 0.88},
  "fundamental_6d": {
    "demand": {"signal": 0.7, "evidence": ["orders_up", "capex_guidance_up"]},
    "supply_capacity": {"signal": 0.4, "evidence": ["lead_time_normalizing"]},
    "pricing": {"signal": 0.6, "evidence": ["asp_stable_to_up"]},
    "inventory": {"signal": 0.5, "evidence": ["channel_inventory_down"]},
    "cost_inputs": {"signal": 0.3, "evidence": ["power_cost_rising"]},
    "capital_cycle": {"signal": 0.8, "evidence": ["hyperscaler_capex_up"] }
  },
  "expectations": {
    "revision_score": 0.65,
    "guidance_tone": "improving",
    "implied_earnings_move": 0.75
  },
  "valuation_quality": {"valuation_percentile": 0.85, "balance_sheet": 0.6},
  "crowding": {"flow_score": 0.7, "options_skew": 0.8},
  "catalysts": [
    {"name": "industry_conf", "window": "next_45d", "impact": "medium", "prob": 0.6}
  ],
  "graph_links": [
    {"from": "AI_infra", "edge": "depends_on", "to": "power_capacity"}
  ]
}
```

---

## 9) 输出形态：交易员能用的 Top-K（不是长篇论文）

输出必须像交易台晨会那样：**结论 + 证据 + 反证 + 风险**。

示例：

```json
{
  "asof": "YYYY-MM-DD",
  "horizon": "1-3m",
  "topk": [
    {
      "item_id": "gics_subindustry_semiconductor_equipment",
      "rank": 1,
      "confidence": 0.72,
      "why_3": [
        "inventory_cycle_turning (channel days down)",
        "orders/backlog improving (book-to-bill up)",
        "earnings revisions breadth improving"
      ],
      "catalyst": "earnings + industry event within 60d",
      "what_would_break": "orders roll over OR rates vol spike + risk-off"
    }
  ],
  "regime_summary": {
    "main_driver": "rates + earnings revisions",
    "risk": "crowding elevated in top themes"
  }
}
```

---

## 10) 你要求的“更像顶级 trader/analyst”的两点增强（我强烈建议加）

### 10.1 “预期 vs 现实”差分：把市场共识变成可量化的对手盘

顶级交易不是找“好行业”，而是找“市场低估了它的改善/高估了风险”。

你要做的不是 item 状态本身，而是：

* **Fundamental Improvement**（现实改善）
* **Expectation Embedded**（预期已经在价格/期权/卖方预期里了）
* 两者的差就是 alpha 来源：
  [
  \Delta = Improvement - EmbeddedExpectation
  ]

EmbeddedExpectation 的 proxy：

* 估值分位 + 预期上修程度 + 期权隐含波动/偏度 + 拥挤度

### 10.2 强制“反事实情景”输出（防止叙事自嗨）

每次 Top-K 都要给：

* 如果 10Y 上行 50bp / 信用利差走阔 / 油价大涨 / 美元大涨，会怎样？
* 哪些 Top-K 会被集体击穿？
  这能显著降低“看对方向但组合死在相关性上”的概率。

---

## 11) MVP 路线（你想快跑出效果，就按这个顺序）

1. **先把 Market Regime Card 做对**（至少：vol surface / rates implied / credit / flows / earnings revisions）
2. **先做 GICS 子行业**（主题先少量做 5–10 个，质量比数量重要）
3. **Item Fundamental Card 先只填 6 维 + revisions**（别先追求 100 个指标）
4. **先用 Analog + Revision + Catalyst 三召回**出候选池
5. **再加图谱与主题扩展**，逐步增强“产业链解释力”

---

## 12) 你马上能用的一句话总结（方便你对外讲系统）

> “我们把市场视为一个具有状态（regime、定价、仓位、事件）的‘用户’，把 GICS 子行业与投资主题视为 item。系统用前瞻定价（期权/利率期货/预期修正）+ 产业链 6 维基本面状态向量，结合历史相似环境检索，在不训练模型的前提下输出未来 1–3m/6–12m 的 Top-K 领先板块，并给出可证伪的交易证据链。”

---

如果你愿意，我可以在不问你更多问题的情况下，直接把 **“市场状态指标清单”**和 **“每个子行业/主题的 KPI 模板库（按产业链）”**给你一份更细的：

* 例如半导体设备、HBM、光模块、电力设备、银行、医药、软件、消费等各自应该看哪些**订单/库存/ASP/capex**代理指标；
* 以及 AI 这种主题如何拆成 4–6 个 segment、每段的 KPI 是什么、如何映射成分股与版本化。



架构方案三：基于“生成式模拟（Generative Simulation）”的下一状态预测这个方案借鉴了推荐系统中的**序列推荐（Sequential Recommendation）和强化学习（RL）**思路。传统推荐是预测$P(Item|User)$，而此方案侧重于预测$User_{t+1}$（市场下一步的状态）。如果我们将市场看作一个正在玩游戏的Agent，我们不预测它现在想买什么，而是预测它3个月后会变成什么样的人，然后提前把那个时候它需要的东西卖给它。1. 系统核心设计利用LLM的生成式模拟能力（World Modeling），推演未来的宏观叙事演变，然后进行“逆向匹配”。2. 核心流程Step 1: 蒙特卡洛叙事树搜索（Narrative Monte Carlo Search）给定当前起点，让LLM生成10条可能的未来3个月的演化路径（Scenarios）。Prompt：“基于当前美联储态度和国内财政政策，生成3种中期市场剧本：1. 强复苏+通胀起；2. 弱复苏+流动性陷阱；3. 滞胀。每种剧本的概率是多少？”Step 2: 虚拟回测（Synthetic Backtesting）针对每一个生成的“未来剧本”，询问LLM：“在这个剧本下，哪个行业是绝对赢家？”例如：在“剧本2（弱复苏+流动性陷阱）”中，LLM推理出赢家是“AI应用（讲故事）”和“甚至医药（超跌反弹）”。Step 3: 期望最大化排序（Expectation Maximization）汇总所有剧本下的赢家板块，结合剧本发生的概率，计算加权期望得分。如果某个板块在80%的剧本里表现都不错（具有鲁棒性），或者在大概率剧本里表现极佳（具有爆发性），则入选TopK。3. 这里的User和Item定义User (Current) -> User (Future Simulated)：系统预测的是市场的偏好漂移（Preference Drift）。Item：不是静态的公司，而是期权（Option）。我们将板块看作是对未来某种宏观状态的看涨期权。