Title: Industry Momentum (Lean) — Implementation Tasks

说明：以下任务清单遵循两级编号，全部为可执行的编码与测试活动；每项都标注目录放置、关联需求条款与设计执行流（EF）步骤/检查点（C1–C6）。完成每步需输出结构化日志与必要的产物。

1. [ ] 建立算法工程骨架与参数读取
   - 目录：`strategy/industry-momentum-lean/code/IndustryMomentumAlgorithm.py`
   - 动作：创建 `QCAlgorithm` 派生类，接入 `GetParameter` 读取：`j1_lookback_days/j2_lookback_days/skip_days/max_holdings/rebalance_frequency_days/buffer_days` 及风控/过滤开关与阈值；设置基准 SPY/现金/回测区间；`SetWarmUp(max(j1,j2)+skip+buffer_days)`。
   - 需求映射：1.1、1.6/1.7、1.8；日志要求第3节。
   - 设计映射：EF-1.1/1.2/1.3/1.5；检查点：C1。
   - 日志：事件 `init`（包含参数哈希/Universe/预热天数）。

2. [ ] 宇宙订阅（ManualUniverseSelectionModel）
   - 目录：`strategy/industry-momentum-lean/code/universe.py`
   - 动作：实现固定 11 ETF 订阅；在不可用时记录 `WARN` 并剔除；`OnSecuritiesChanged` 维护活跃 symbols。
   - 需求映射：1.1；日志第3节。
   - 设计映射：EF-1.4，Alpha-`OnSecuritiesChanged`；C1。
   - 日志：事件 `universe_ready`（可用/剔除列表）。

3. [ ] 调度与节流
   - 目录：`strategy/industry-momentum-lean/code/schedule.py`（或置于主算法中）
   - 动作：`Schedule.On(DateRules.EveryDay, TimeRules.AfterMarketOpen("SPY",10), RunAlphaGeneration)`；仅在 `now >= next_rebalance_time` 且非 `IsWarmingUp` 执行，并更新下一次时间（+rebalance_frequency_days）。
   - 需求映射：1.1、2.2；设计：EF-2；检查点：C1。
   - 日志：`schedule_tick`、`skip_non_rebalance`。

4. [ ] 历史数据拉取与当日剔除
   - 目录：`strategy/industry-momentum-lean/code/history.py`
   - 动作：封装 `get_history(symbols, needed_days)`，计算 `needed_days = skip_days + max(j1,j2) + 5`；剔除当日未收盘记录。
   - 需求映射：1.7（1.8）、3；设计：EF-3.2；检查点：C2。
   - 日志：`history_fetch`（bars/剔除当日/耗时）。

5. [ ] 跳过月收益与平均名次融合
   - 目录：`strategy/industry-momentum-lean/code/alpha/industry_momentum_alpha.py`
   - 动作：实现 `IndustryMomentumAlphaModel.GenerateInsights()`：
     - 对每 symbol 计算 J1/J2：`p_end = close[-skip]`，`p_start_j1 = close[-(skip+j1)]`，`p_start_j2 = close[-(skip+j2)]`；收益为 `(p_end/p_start)-1`；不足样本剔除（限频 WARN）。
     - 计算 `rank_j1/rank_j2`（降序），`final_rank = (rank_j1 + rank_j2)/2`；按升序取前 `max_holdings` 生成 `Up`，其余 `Flat`（duration=`rebalance_frequency_days`）。
   - 需求映射：1.2、1.3；设计：EF-3.3/3.4/3.5/3.6；检查点：C3/C4。
   - 日志：`calc_returns`、`rank_table`、`select_winners`、`emit_insights`。

6. [ ] 可选过滤与风控（前置）
   - 目录：`strategy/industry-momentum-lean/code/risk_filters.py`
   - 动作：
     - VIX 开关：订阅 `CBOE:VIX` 自定义数据（若运行环境可用）；若启用且 `vix > threshold`，直接返回空 insights（INFO）。
     - 绝对动量过滤：`abs_lookback_days` 计算收益 ≤0 的剔除（INFO）。
     - 资产波动过滤：滚动年化波动 `asset_vol_lookback_days`，大于 `asset_vol_threshold` 剔除（WARN）。
   - 需求映射：1.5、1.6（新增可选）；设计：EF-3.1；检查点：C5.1。
   - 日志：`risk_switch`（vix）、`filter_abs_mom`、`filter_asset_vol`。

7. [ ] PortfolioConstruction 与 Execution
   - 目录：主算法 Initialize 内设置
   - 动作：`SetPortfolioConstruction(EqualWeightingPortfolioConstructionModel())`；`SetExecution(ImmediateExecutionModel())`；保持 Up=1/N、Flat=0 的目标；（可选）实现 PortfolioVolatilitySwitch 风控模型覆盖为清仓目标（WARN）。
   - 需求映射：1.3、1.4、1.5；设计：EF-4；检查点：C4/C5。
   - 日志：`targets_built`、`risk_clear`（若触发）。

8. [ ] 产物写入（ObjectStore/本地）与 KPI 计算
   - 目录：`strategy/industry-momentum-lean/code/artifacts.py`
   - 动作：
     - 生成 run manifest（参数、spec/skills 哈希、git 提交、回测区间）。
     - 在 `OnEndOfAlgorithm` 写出 KPI（CAGR/Vol/Sharpe/MaxDD/WinRate/Days）与每次调仓快照（可用/剔除/名次/赢家）。
     - JSON 输出键名对齐 ais 回测表结构（供后续入库）。
   - 需求映射：1.9、2.3；设计：EF-5；检查点：C6。
   - 日志：`metrics_done`、`artifacts_saved`（包含文件名与字节数）。

9. [ ] 纯逻辑单元测试（本仓可运行）
   - 目录：`tests/unit/industry_momentum/`
   - 动作：为“窗口切片与收益计算、平均名次与 Top‑N 选择、过滤器计算”编写可离线跑的函数与测试；数据以假序列/小样本 Pandas 构造。
   - 需求映射：测试与日志章节；设计：C2/C3 函数级验证。
   - 日志：pytest 输出；确保边界条件（样本不足/并列名次）。

10. [ ] 日志格式与事件校验测试
   - 目录：`tests/unit/industry_momentum/test_logging_schema.py`
   - 动作：对日志格式化工具进行单测，确保事件键、级别、run_id、params_hash、耗时字段必备；模拟一轮调仓事件链路。
   - 需求映射：3 强制日志；设计：日志架构小节。

11. [ ] 性能与内存安全基线
   - 目录：`strategy/industry-momentum-lean/code/utils/perf.py` + `tests/unit/industry_momentum/test_perf.py`
   - 动作：封装计算过程的计时与峰值内存采样（如可用）；生成性能日志；为 11 只 ETF 的 5 年数据做基线验证，避免不必要拷贝。
   - 需求映射：性能监控、内存安全；设计：性能监控与 C3。

12. [ ] Lean 集成与回测脚本占位
   - 目录：`strategy/industry-momentum-lean/scripts/run_backtest_cli.md`
   - 动作：提供 Lean CLI/Cloud 的运行命令模板与参数映射（把 `configs/parameters.default.json` 拷入项目 `config.json` 的 `parameters` 段）。
   - 需求映射：运行指引；设计：目录与产物章节。

13. [ ] 参数优化作业模板与产物归档
   - 目录：`strategy/industry-momentum-lean/configs/optimization.{grid,euler,walkforward}.json`（已就绪）
   - 动作：补充最小脚本/说明把最优前 k 输出到 `runs/`；对 WFO 生成拼接 OOS 曲线 JSON。
   - 需求映射：优化章节；设计：5.2.1。

14. [ ] DB 对接 JSON 映射函数（可选）
   - 目录：`strategy/industry-momentum-lean/code/db_mapping.py`
   - 动作：提供 `to_backtest_run/equity/trade/factor_value` 的 JSON 结构生成器；不直接写库，仅产物。
   - 需求映射：第9节；设计：数据模型与 DB 契约。

15. [ ] 设计一致性终检（Design→Code）
   - 目录：代码审阅记录与自检脚本（可放 `strategy/industry-momentum-lean/reports/validation.md`）
   - 动作：
     - 对照 EF 步骤与 C1–C6 检查点逐项核对；
     - 验证所有日志事件都至少出现一次；
     - 验证参数在 Manifest 与运行日志中一致；
     - 若设计/实现有偏差，更新 `design.md` 并记录 `docs/CHANGELOG_EXEC_FLOW.md`。
   - 需求映射：最终验证任务集合；设计：全部章节。

16. [ ] 回gress：关键区间打标与分析导出
   - 目录：`strategy/industry-momentum-lean/code/analytics.py`
   - 动作：对 2008–2009、2020、2022 的子区间 KPI 打标签输出到 JSON，辅助“动量崩溃”与反转年的评估。
   - 需求映射：1.9（关键年份标注）；设计：概览与成果。

17. [ ] 最终报告与交付包（可选）
   - 目录：`strategy/industry-momentum-lean/reports/`
   - 动作：汇总 KPI、赢家变更、风险开关触发统计、优化最优前 k、WFO OOS 总结，生成 markdown 报告。
   - 需求映射：产物与治理章节。

18. [ ] 变更同步与版本固化
   - 目录：`docs/CHANGELOG_EXEC_FLOW.md`
   - 动作：若执行流/默认参数变动，更新 requirements/design 与本变更记录；在 Manifest 中更新 spec/skills 内容哈希。

— Final Validation Tasks —

19. [ ] 设计到代码一致性全面复核（Design-to-Code Consistency Review）
   - 对照 `.claude/specs/industry-momentum-lean/design.md` 的 EF 步骤与决策点，逐函数比对实现；记录对齐结论与差异整改。

20. [ ] 功能完整性审计（Feature Completeness Audit）
   - 核对用户故事与 EARS 验收项（宇宙/信号/调度/Up&Flat/等权/风控/过滤/优化/产物/日志）。

21. [ ] 执行流验证（Execution Flow Validation）
   - 回放一次完整调仓周期的日志，确认事件顺序与条件分支与设计一致；核对 `skip_days` 与窗口索引。

22. [ ] 架构符合性检查（Architecture Compliance Check）
   - 确认 Universe/Alpha/PCM/Execution/Risk 分层与职责边界清晰；Alpha 使用 `GenerateInsights` 而非高频 `Update`。

23. [ ] 接口实现验证（Interface Implementation Verification）
   - 参数读取、日志格式、产物 JSON Schema、可选开关与阈值生效路径逐项验证。

24. [ ] 错误处理完整性（Error Handling Completeness）
   - 历史不足、VIX 数据缺失、JSON 写入失败的容错路径执行一次并记录。

25. [ ] 性能与内存（Performance Requirements Validation）
   - 采样 5 年窗口（11 ETF）完成一次基准运行，记录耗时与内存；确认无不必要拷贝与 O(n×m) 级别陷阱。

26. [ ] 日志与监控（Logging Verification）
   - 抽样 3 次调仓日，验证每个关键事件的 JSON 字段与级别、耗时是否齐全；确认轮转/留存策略说明已落地。

27. [ ] 文档同步完成（Documentation Synchronization）
   - 确认 `requirements.md/design.md/skills.md` 与实现一致；必要时更新并留痕。

