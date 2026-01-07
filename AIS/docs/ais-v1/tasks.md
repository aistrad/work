# AIS v1 实施任务清单（Spec v2，中文）

说明：本任务清单围绕“插件化/执行后端/组合与风控”的重构落地，保持策略插件零改动；仅规划与规格，不含实际代码改动。

## 0. 总体

- [ ] 明确阶段边界与灰度：回测路径保持；新增模块先影子运行后切换；所有变更先写 specs 与测试再实现。

### 0.1 文档与契约落位（本次）
- [ ] 将 design.md 中新增的“策略 IR/DSL / 回测 I/O / 结果 IR / 策略包 / 黄金路径”五节统一为中文，并与 requirements.md 的 EARS 条目一致（已完成文档修改，需回看）。
- [ ] 在 requirements.md 增补“策略 IR/DSL 契约”“回测 I/O 契约”“结果 IR 契约”三节及 EARS 验收（已完成文档修改，需回看）。
- [ ] 在 docs/aiscend_database_dictionary.md 中扩展 GEDD：fundamentals.ttm、valuation.percentile、forecast.earnings（状态 `proposed`，强调 PIT/as‑of/lag，verified 仅人工）（已完成文档修改，需回看）。
- [ ] Manifest 字段对齐：补充 `ir_version/ir_sha256` 与 `gedd.commit/datasets_used/factors_used`（规格层面声明，落地由实现阶段完成）。

## 1. 插件装载与注册（Strategy Loader）

- [ ] Entry points 发现：组 `ais.strategies`；加载 `load(params)->Strategy`；校验 `api_version`。
- [ ] `strategy_meta` 读写：按行版本化（UNIQUE(strategy_name,version)）；落盘参数快照与 factors_used；
- [ ] Manifest 写入：`strategy_slug/plugin_package/plugin_version/entrypoint` 等新字段；与 DB `backtest_run.report_paths` 对齐。

## 2. 执行后端抽象（ExecutionBackend）

- [ ] 接口定义：`sync_positions/target_to_orders/submit/poll_fills/reconcile/cancel_all/heartbeat`。
- [ ] 回测实现对齐：BacktestSimBackend 适配现有 Backtrader/Pandas 路径。
- [ ] IB 实盘草案：合约映射、目标→差额订单、节流/重试、部分成交处理与状态幂等；先 Paper。

## 3. 组合器（PortfolioCombiner）

- [ ] 输入多策略 `StrategyOutput`，输出账户级目标权重；
- [ ] 资金分配策略（固定/波动率预算/风险平价）与冲突调解（加总/裁剪/优先级）。

## 4. 风控引擎（RiskEngine）

- [ ] 配置模型与层级合并：global→portfolio→strategy-default→strategy-override→ticker-overrides；优先级规则实现；
- [ ] 规则最小集：`cap_weight/sl/tp/trailing_sl/vol/event/turnover_cap/notional_cap/order_rate_cap`；
- [ ] 输入合并：策略 `risk_signals/weights_after_risk` 与集中配置；
- [ ] 审计落地：写 `strategy_risk_signal/risk_breach`、统计摘要与 Manifest 字段。

## 5. 数据与对齐统一

- [ ] `data.price_field` 与 `data.alignment` 贯通 Providers/执行后端/指标；
- [ ] Benchmark 对齐与超额/IR/TE 指标扩展。

## 5.1 新增：全局可执行数据字典（GEDD）MVP 接入

- [ ] 添加 `src/utils/dictionary_loader.py`：从 `docs/aiscend_database_dictionary.md` 解析 fenced YAML 区块，生成 `registry`（datasets/factors）。
- [ ] 添加 `src/utils/dictionary_health.py`：基于 information_schema 校验 `dataset.source.table` 与 `fields` 存在性；返回健康报告。
- [ ] Orchestrator 启动阶段插入 `DictionaryHealth`：输出 `dictionary.loaded`/`dictionary.health` 日志；失败时退出。
- [ ] Manifest 增补字段：`dictionary_commit`, `datasets_used[]`, `factors_used[]`。
- [ ] 与 Providers 的对接（MVP）：不改变查询路径，仅将 `registry` 用于健康检查与日志对齐；后续再切换到合约驱动 SQL 生成。

## 6. 产物命名与清单

- [ ] 采用目录/文件命名规范；
- [ ] Manifest 扩展字段与 DB `backtest_run.report_paths` 写入；
- [ ] 清理脚本（按 `output.keep_days`）。

## 6.2 结果 IR 与审计（契约校验）
- [ ] 结果 IR 的最小键：`run/exec/equity/trades/perf/audit/diagnostics/logs`；断言字段存在与类型正确。
- [ ] 审计包含：约束命中计数、费用 bps 分布、流动性（ADV 占比）与稳定性（profiles 箱线图概览）统计位点（规格层声明）。

## 6.1 文档目录合并

- [ ] 统一文档目录为 `docs/`；将 `doc/` 下所有文档合并迁移到 `docs/`；
- [ ] 更新所有规范与脚本中的路径引用（`doc/...` → `docs/...`）；
- [ ] 在 `doc/` 放置 `README.MOVED.md` 指向新位置（过渡期），后续版本删除该目录；

## 7. 策略插件示例对齐（indmoment oversea — 季度）

- [ ] 将现有仓内策略迁移为外部插件包（影子运行对齐净值/交易/费用/审计）；
- [ ] 在 `strategy_meta` 登记策略版本与 factors_used；
- [ ] 为该插件编写参数 Schema、示例配置与最小审计断言。

## 8. 测试与门禁

- [ ] 单元：Loader/Backend/Combiner/RiskEngine/Providers 的参数与边界覆盖；
- [ ] 集成：端到端（回测）+ Paper（模拟）；
- [ ] 集成：`DictionaryHealth` 成功解析与最小校验（`price.daily_usd@v1` 表/列存在性）
- [ ] 审计：日志/清单/DB 记录一致性断言；风控冲突优先级与结果“更保守”原则验证。

## 审计与调仓规则增强

- [ ] 暖启动：为 `pricing_service.load_prices` 增加 `lookback_days` 参数；编排器读取 `data.lookback` 并默认启用（90 天），仅用于因子/信号计算，主回测区间不变。
- [ ] 调仓日契约：实现“权重与调仓日程构建器”返回 `(weights, rebalance_dates)`；编排器优先使用 `schedule`，引擎仅在显式调仓日下单；为事件驱动扩展预留 `events` 接口。
- [ ] Universe（HK 交易所）：`universe.exchange` 显式使用 `exchange_short_name`（如 HKSE），`region=hk` 时优先按交易所过滤；可选 `ticker_suffix: '.HK'` 进一步约束。
- [ ] 审计报告：新增 `audit_report` 服务，生成 `runs/<run_id>/audit_report.json`，包含月度/季度调仓日、当期可用标的数、持仓数量与覆盖率（按策略定义）、换手率、费用 bps 分布、异常提示。
- [ ] 测试更新：将所有“日历月末”断言统一更新为“最后交易日”规则；新增佣金/滑点 bps 对账测试、显式调仓日触发测试、适配器 OHLC 复制与索引对齐测试。

## 行业先行选股（indmoment oversea — 季度）

- [ ] 行业预筛与并集逻辑（对应需求 1.4-2）：
  - 以 `adv3m_usd=AVG(amount_usd)`（近 100 自然日）与 `mkt_cap_usd` 为阈值统计每行业合格个股数（≥3）。
  - 行业过滤 `R_1m<10%`；`R_3_1` 和 `R_6_1` 各取 Top5 并集；若>10，按 `rank_sum→R_6_1→cap_sum` 截至 10。
  - 代码：`src/services/selector/indmoment_oversea_quarterly.py`（`industry_rank_union_ranksum`）。
- [ ] 个股筛选与排序（对应需求 1.4-2）：
  - 行业内过滤 `r_1m<15% & mkt_cap_usd>2B & adv3m_usd>10M`；
  - 在入选行业内按评分规则与参数选取若干标的，并按 `rank_sum→r_6_1→mcap` 规则排序；允许不足；
  - 代码：`select_stocks_per_industry`（已替换 z-score 口径）。
- [ ] mkt_cap_usd as‑of 来源（对应需求 1.4-6）：
  - 优先 `f_valuation_multiple.market_cap_usd` 最近记录（使用 `calculation_date` 距离最小）；
  - 回退 `ticker_price.mkt_cap_usd` 当日值；
  - 代码：`build_weights` 中 as‑of 查询。
- [ ] 执行价/成交规则（对应需求 1.4-4）：
  - `pricing_service.load_avg_open` 已落地；在 orchestrator/engine 侧接入 open 覆盖，使用 cheat‑on‑open；
  - 产出 `audit_report.json` 费用 bps 分布校验。
- [ ] 文档同步与数据字典（对应 specs 数据口径补充）：
  - 更新 `docs/aiscend_database_dictionary.md` 与 `.claude/specs/ais-v1/data_dictionary_aiscend.md` 的 ADV3m 与 mktcap 口径说明。

## 测试（新增）

- [ ] `tests/integration/test_backtrader_engine.py`：显式调仓日仅产生一次订单；open 覆盖价生效；bps 对账。
- [ ] `tests/unit/test_universe_service.py`：region=hk 使用 `exchange_short_name` 过滤；oversea 正确排除 CN/HK 别名。
- [ ] `tests/integration/test_factor_value_upsert.py`：`ensure_indmoment3_1` 幂等；二次运行无重复行。
- [ ] `tests/integration/test_large_universe_smoke.py`（可标记 `-m smoke` 跳过 CI）：全量 oversea（短窗口）流水线跑通，日志包含阶段耗时与覆盖率。
