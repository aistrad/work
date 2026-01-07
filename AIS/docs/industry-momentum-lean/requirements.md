标题：QuantConnect Lean 行业动量 ETF 策略 — 需求规格（Requirements）

简介
- 对齐声明：本策略的权威配置与选项定义以 `strategy/industry-momentum-lean/skills.md` 为准；如与本文件存在冲突，以 `skills.md` 为准，并在变更日志中记录。
- 目标：在 QuantConnect LEAN 上实现一套完整的行业动量 ETF 策略（研究/回测用），覆盖信号计算、持仓生成、执行与成本建模、可选风险过滤（VIX/波动率）、参数优化、数据质量控制与审计级日志/产物输出。策略采用 Select Sector SPDR ETFs 宇宙，使用“跳过最近1个月”的 6–1 与 3–1 动量，通过“平均名次”融合，长仅做多、等权、季度调仓。
- 范围：仅限研究与回测（不含实盘接入与经纪商对接）。包含 Alpha 生成、组合构建、执行、（可选）风控、优化器配置、数据/偏差防护。不包含部署与生产运维。
- 上下文复用：参考 AIS‑v1 中“平均名次/并集优先”的排序思路、稳健调仓日构造、结构化日志与 JSON 产物沉淀，将其映射到 LEAN 的 Universe/Alpha/PCM/Risk/Execution 职责模型与 API 约定。

1. 用户故事与核心功能需求
1.1 宇宙与调度（LEAN 规范）
- 用户故事：作为量化研究员，我希望使用固定的 Select Sector SPDR ETFs 宇宙并按季度调仓，以便稳定评估行业动量。
- 验收（EARS）：
  - 当算法 Initialize 时，系统应通过 ManualUniverseSelectionModel 订阅 11 只行业 ETF：XLC,XLY,XLP,XLE,XLF,XLV,XLI,XLB,XLRE,XLK,XLU；若个别不可用，应带 WARN 记录并剔除。
  - 当交易日推进时，系统应使用 Scheduler 在设定时间（如开盘后10分钟）触发季度调仓（可配置天数），若处于预热 IsWarmingUp 则跳过。
  - 当某 ETF 在当前调仓点缺乏足够历史数据时，系统应将其排除出当次排名，并以 WARN 记录“数据不足”。

1.2 跳过月动量与“平均名次”融合（LEAN 历史数据）
- 用户故事：作为研究员，我希望精确计算 6–1 与 3–1 跳过月动量，避免短期反转污染。
- 验收（EARS）：
  - 当生成信号时，系统应以日频 History 数据计算“跳过区间收益”，其所有窗口参数以“日”为单位可配置：
    - j1_lookback_days（默认 126，相当于 6 个月）、j2_lookback_days（默认 63，相当于 3 个月）、skip_days（默认 21，相当于 1 个月）。
    - 计算区间：J1 使用 [t−skip_days−j1_lookback_days, t−skip_days]，J2 使用 [t−skip_days−j2_lookback_days, t−skip_days]。
    - 允许通过 GetParameter 动态覆盖上述参数，以便在优化中按“日”为粒度搜索。
  - 当两种动量可用时，系统应分别做 ETF 间降序名次，最终名次 = (rank_6_1 + rank_3_1)/2，并以该名次进行最终排序。
  - 当任一信号缺失（样本不足）时，系统应剔除该 ETF 参与本次排名，并以 WARN 记录缺失区间。

1.3 仅做多、持仓上限与等权权重（LEAN PCM）
- 用户故事：作为组合工程师，我希望长仅做多、等权持有 Top‑N，以保持简单稳健。
- 验收（EARS）：
  - 当得到名次后，系统应选出 Top‑N（参数化：max_holdings，默认 3），对赢家发出 Insight.Price(..., Up)，对其余发出 Flat。
  - 当 PCM 接收 Insight 时，应对赢家分配 1/N 等权、其他为 0，实现组合层面的仅做多。
  - 当赢家集合变化时，系统应将离开集合的标的目标权重设为 0，由执行模型在下一周期完成调仓。

1.4 执行与成本（LEAN Execution/Fees/Slippage）
- 用户故事：作为回测用户，我需要合理的执行假设，避免业绩乐观偏差。
- 验收（EARS）：
  - 当生成目标时，系统应使用 ImmediateExecutionModel（或同级简化模型）匹配低频调仓。
  - 当回测运行时，系统应应用可配置的佣金与滑点，并在运行元数据与日志中记录。

1.5 风险控制（可选）— VIX/组合波动阈值（LEAN Risk）
- 用户故事：作为风控人员，我希望可选的 VIX 或已实现波动率阈值以降低动量崩溃暴露。
- 验收（EARS）：
  - 当配置 VIX 阈值且数据可用时（参数：enable_vix_switch=true/false，vix_threshold 可调），系统应在 VIX 超阈时暂停发出新的 Long 信号，并以 INFO 记录 risk_switch:off（含阈值与当前值）。
  - 当配置组合波动阈值时（参数：enable_portfolio_vol_switch=true/false，portfolio_vol_threshold 可调），系统应在自定义 RiskManagementModel 中监控已实现波动，超阈则清空目标并以 WARN 记录触发细节。
  - 当上述过滤关闭时，Initialize 应以 DEBUG 明示“已禁用”。

1.6（可选）绝对动量与资产波动过滤
- 用户故事：作为研究员，我希望在相对动量基础上增加绝对动量阈值（<0 不持有）与资产波动过滤（剔除过度波动资产）。
- 验收（EARS）：
  - 当 enable_abs_momentum_filter=true 时，系统应在 Alpha 生成前以 abs_lookback_days 计算绝对收益，收益≤0 的 ETF 不纳入 winners 候选，并记录 INFO 统计。
  - 当 enable_asset_vol_filter=true 时，系统应在 Alpha 生成前以 asset_vol_lookback_days 估算年化波动，若超过 asset_vol_threshold 则剔除，并 WARN 记录阈值与候选减少数量。

1.7 参数化与优化器集成（LEAN Optimizer）
- 用户故事：作为研究员，我希望用 LEAN 优化器搜索回看期、跳过月、持仓上限与调仓频率等稳健参数区域。
- 验收（EARS）：
  - 当 Initialize 执行时，系统应通过 GetParameter 读取日粒度参数：j1_lookback_days、j2_lookback_days、skip_days、max_holdings、rebalance_frequency_days（调仓频率/持有期；默认 90 天）等，具备默认值。
  - 当启动优化任务时，系统应接受优化器提供的范围（Grid/Euler），并在回测统计中产出目标指标（如 Sharpe、Max Drawdown）。
  - 当优化完成时，系统应持久化前 k 组最优参数与目标值到 JSON 产物，并以 INFO 输出摘要。

1.8 数据质量、预热与回看处理（避免前瞻）
- 用户故事：作为工程师，我需要确定性的预热与数据质量检查，以确保排名稳定且无前瞻偏差。
- 验收（EARS）：
  - 当设置预热时，系统应按 (max(j1_lookback_days, j2_lookback_days) + skip_days) + buffer_days 进行 WarmUp（单位：日，默认 buffer_days=30），未完成前不发出 Insight。
  - 当请求历史数据时，系统应剔除“当日未收盘”数据以避免前瞻，并以 DEBUG 记录。
  - 当某 ETF 不满足窗口样本数时，系统应跳过该标的并继续（每次调仓对同一标的限频 WARN 记录）。

1.9 指标、基准与产物（Metrics & Artifacts）
- 用户故事：作为研究员，我希望标准业绩指标与基准对照，便于评估 Alpha 与风险。
- 验收（EARS）：
  - 当回测运行时，系统应将 SPY 设为基准并记录 CAGR、年化波动、Sharpe、最大回撤等 KPI。
  - 当回测结束时，系统应导出 JSON 产物：参数、日期、KPI、（可选）换手率、每次调仓选股摘要等。
  - 当窗口覆盖关键年份（如 2008–2009、2020、2022）时，系统应在产物中对这些区间的 KPI 进行标记（若落入回测区间）。

1.10 错误处理与边界情形
- 用户故事：作为运行维护者，我希望在数据缺失/代码异常时优雅降级且信息透明。
- 验收（EARS）：
  - 当单个标的数据不足时，系统应剔除并继续，生成“missing_data”小结（JSON）并 WARN 一次。
  - 当可用候选少于 N 时，系统应对可用赢家等权持有，并以 INFO 记录当前持仓数减少。
  - 当宇宙内成分因上市/存续差异变化时，系统应自动适配可用集合完成排名。

2. 非功能需求
2.1 简洁与可维护（LEAN 职责分离）
- 验收（EARS）：实现以单个 QCAlgorithm 为宿主，配合 ManualUniverseSelectionModel、定制 AlphaModel（Scheduled 触发）、EqualWeightingPortfolioConstructionModel 与 ImmediateExecutionModel；若启用风控再挂接 RiskManagementModel。遵循 LEAN API 约定、命名与生命周期回调（Initialize/OnSecuritiesChanged/Update）。

2.2 性能
- 验收（EARS）：非调仓日严禁重复重算或发起重型 History 请求；以 DEBUG 记录“skip_non_rebalance”。

2.3 可复现
- 验收（EARS）：回测结束输出运行清单（参数哈希、版本/提交号、时间窗、随机种子如有）至 JSON；同清单在相同数据前提下应产生一致的选股与权重。

3. 强制日志（Logging）要求（LEAN 规范化输出）
- 必须记录的事件：
  - 初始化：参数与默认值、WarmUp 天数、宇宙清单、Scheduler 配置。
  - 每次调仓：可用与剔除标的列表（含原因）、J1/J2 窗口、名次表、Top‑N、生成的目标权重。
  - 风控：VIX/组合波动的当前值与阈值、开关决策、目标覆盖/清仓动作。
  - 数据问题：历史缺失、NaN、映射/起始日期差异等。
  - 优化：目标函数、前 k 组参数、最优值与稳定性提示。
- 日志级别：
  - DEBUG：参数默认、WarmUp 细节、非调仓日跳过、窗口索引定位、计时数据。
  - INFO：调仓结果、赢家集合、目标、风控决策、优化摘要。
  - WARN：数据不足/剔除、候选不足、产物写入重试。
  - ERROR：History 失败、产物持久化失败、未捕获异常。
  - FATAL：不可恢复的初始化错误（如宇宙为空）。
- 日志格式：
  - 推荐 JSON 行（time, level, component, event, run_id, params_hash, details），通过 self.Log/self.Debug/self.Error 输出 JSON 字符串；关键步骤附耗时（毫秒）。
- 留存与轮转：
  - 本地：保留近 30 个 run 目录，超出轮转。云端：遵循 QC 保留策略；若可用，采用 ObjectStore 导出产物。
- 性能监控：
  - 为 History、排名、EmitInsights 等关键步骤记录耗时（DEBUG）与汇总（INFO）。

4. 配置与参数
- 关键参数（默认，全部“日”）：
  - max_holdings=3，rebalance_frequency_days=90，j1_lookback_days=126，j2_lookback_days=63，skip_days=21。
  - buffer_days=30（预热缓冲）。
  - 可选风控参数：vix_threshold（禁用则为空）、portfolio_vol_threshold（禁用则为空）。
  - 风控开关：enable_vix_switch=false，enable_portfolio_vol_switch=false。
  - 优化：objective（Sharpe/Drawdown）、direction（max/min）。

8. 策略工程化目录（strategy/）与生命周期管理
- 目录结构（位于 AIS‑v1/strategy/industry-momentum-lean/）：
  - papers/：原始论文与参考资料（如 SSRN-1919226 摘要、Moskowitz & Grinblatt 1999、Grundy & Martin 2001）。
  - configs/：LEAN 参数模板与优化空间样例（config.json、optimizer.json）。
  - code/：LEAN 算法代码（AlphaModel、Universe、PCM/Risk 扩展、工具函数）。
  - runs/：本地或云端回测产物（参数清单、日志 JSONL、KPIs、每次调仓快照）。
  - optimize/：优化作业记录（目标、最优前 k、热图/表格）。
  - reports/：自动汇总的回测与优化报告（可选）。
- 流程：需求→设计→实现→回测→优化→报告→归档；每次关键变更同步更新 .claude/specs/* 并记录到 CHANGELOG_EXEC_FLOW。

9. 与 ais 数据库对接（结果/因子/治理映射）
- 对照表（来源 db/ddl/ais_v1_core.sql）：
  - 策略注册：strategy_meta(name, category, description, owner)；版本登记：strategy_version(template, params, changelog)。
  - 回测结果：backtest_run(run_id, experiment_name, start_date, end_date, benchmark, config_hash, strategy_template, params, perf)，与明细表 backtest_equity、backtest_trade。
  - 因子沉淀（可选）：factor_meta/factor_value 存储“行业动量分数/名次”等研究信号以便复用。
- 要求（EARS）：
  - 当一次回测完成时，系统应生成与 backtest_run/backtest_equity/backtest_trade 结构一致的 JSON 产物（键名对齐），供后续批量导入。
  - 当策略参数或版本变更时，系统应生成 strategy_version 记录所需的 params/changelog 字段。
  - 如开启信号落库，需输出 factor_meta（factor_name=industry_momentum_rank, version）、factor_value（date/asset_id/value）。

10. 优化扩展：步行优化（Walk-Forward Optimization, WFO）
- 验收（EARS）：
  - 当提供 `configs/optimization.walkforward.json` 时，系统应按给定训练/测试窗口进行多次优化与样本外评估，并在最终产物中拼接 OOS 曲线与 KPI 概要。
  - 每个窗口的最优参数集与目标指标应写入 JSON 产物并以 INFO 汇总。

5. 依赖与上下文使用说明（复用自 AIS‑v1）
- 复用点：
  - 动量窗口“平均名次”融合与“并集→再排序”的思想；稳健调仓日与诊断产物（JSON）；结构化日志规范。
- 集成方式：
  - 在 LEAN AlphaModel 中以 History 精确切片实现跳过月；用 ManualUniverseSelectionModel 固定行业 ETF 宇宙；以 EqualWeightingPortfolioConstructionModel 做等权配仓；Scheduler 触发低频计算；严格剔除当日未收盘数据以避免前瞻。

6. 成功标准（Success Criteria）
- 2007‑01‑01 至近期截止日期的完整回测可稳定运行并产出 KPI 与产物。
- 至少对 lookback_months_j1、lookback_months_j2 两个参数完成一次优化作业，返回最优配置与前 k 摘要。
- 日志与产物满足审计需求，可据此复现实验并定位问题。

7. 待确认事项（为后续澄清准备）
- 是否需要支持月度/半年度等其他调仓频率作为对照？
- 成本模型采用统一基点/最小费用，还是 ETF 级别差异化设置？
- 产物是否需要写入 ObjectStore 并在云端导出（若使用 QC Cloud）？
