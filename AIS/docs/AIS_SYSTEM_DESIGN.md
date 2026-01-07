# AIS 系统设计（v1）

## 目标与原则
- 单一真源：AIS 数据库为数据/因子/运行产物的唯一真源；文件系统为可复现工件缓存。
- 四层架构：Skills（流程规范）+ 配置（约定与状态）+ 代码（实现）+ 数据库（真源）。
- 解耦协作：各域（data/factor/strategy/portfolio/execution/risk）仅以公开契约交互；严禁跨越边界调用他方内部实现。
- 与 Lean 对齐：映射 Universe/Alpha/PortfolioConstruction/Execution/Risk 组件；Alpha 只产出预测（Insights），PCM 只做目标权重，Risk 只做调整，Execution 只负责下单。
- 幂等与审计：所有写入具备幂等键与事务；统一 run_manifest 与 artifacts 索引；全链路 JSON 行日志。

## 目录与命名规范（仓内）
```
AIS/
├─ docs/
│  └─ AIS_SYSTEM_DESIGN.md                 # 本文件
├─ Data/                                   # 数据域（配置与质量审计摘要）
│  ├─ DATA.md
│  ├─ configs/
│  │  ├─ lean_mapping.json                 # AIS→Lean 目录/复权/分辨率/日历
│  │  └─ policies.json                     # 缺失/对齐/时区策略
│  └─ universe/
│     └─ sector-etfs.json                  # 例：行业ETF宇宙
├─ Factor/                                 # 因子域（定义与登记配置）
│  └─ momentum-average-rank/
│     ├─ FACTOR.md
│     └─ meta.json
├─ Portfolio/                              # 组合域（多策略合成/约束）
│  └─ core-mmvo/
│     ├─ PORTFOLIO.md
│     └─ constraints.json
├─ Execution/                              # 执行域（撮合/成本模型）
│  └─ vwap/
│     ├─ EXECUTION.md
│     └─ policy.json
├─ Risk/                                   # 风险域（阈值/限额/触发器）
│  └─ basic/
│     ├─ RISK.md
│     ├─ limits.json
│     └─ triggers.json
├─ Strategy/
│  └─ industry-momentum/
│     ├─ STRATEGY.md                       # 规范化命名（原 strtegy.md）
│     ├─ configs/                          # parameters/optimization/scenarios
│     ├─ qc/                               # Lean 项目（main.py/config.json）
│     ├─ runs/ | optimize/ | reports/
│     └─ scripts/ | code/ | algo/
└─ src/                                    # 统一代码实现（可被 Lean 注入）
   ├─ data/        │ lean_export.py/validate.py
   ├─ factor/      │ compute.py/registry.py
   ├─ strategy/    │ run.py
   ├─ portfolio/   │ optimizer.py
   ├─ execution/   │ policy.py
   ├─ risk/        │ manager.py
   ├─ db/          │ client.py/mapping.py
   ├─ artifacts/   │ io.py
   └─ lean/        │ run.py
```

约定：
- 域目录首字母大写（Data/Factor/Portfolio/Execution/Risk/Strategy），功能性系统目录全小写（如 `src/`、`docs/`、`data/` 作为 Lean 数据根）。
- 统一使用大写权威规范文件名：策略域 `STRATEGY.md`、数据域 `DATA.md`、因子域 `FACTOR.md`、组合域 `PORTFOLIO.md`、执行域 `EXECUTION.md`、风险域 `RISK.md`。
- `src/` 作为注入路径：Lean 根的 `lean.json` 配置 `"python-additional-paths": ["./src"]`。

## 配置规范（各域）
- 数据域（Data）
  - `configs/lean_mapping.json`：目录映射、分辨率、Normalization、交易日历。
  - `configs/policies.json`：缺失率阈值、复权口径、时区与收盘时间、样本边界策略。
  - `universe/<name>.json`：资产集合、起止日期、别名、数据提供方。
- 因子域（factor）
  - `<factor>/FACTOR.md`：口径/频率/滞后/单位/依赖/质量控制。
  - `<factor>/meta.json`：入库所需元数据（不含值）。
- 策略域（Strategy）
  - `STRATEGY.md`：目标/宇宙/Alpha 组合/参数/Gates/KPI/敏感年份窗口。
  - `configs/parameters.*.json`、`optimization.*.json`、`scenarios.json`。
- 组合域（portfolio）
  - `<portfolio>/PORTFOLIO.md`：目标函数/约束/再平衡频率/二层分配策略。
  - `<portfolio>/constraints.json`：集中度/暴露/换手率等上限。
- 执行域（execution）
  - `<execution>/EXECUTION.md`：执行模型（Immediate/VWAP/Spread/StdDev/自定义）、成本与分片策略。
  - `<execution>/policy.json`：执行参数（如分片阈值、最大参与度等）。
- 风险域（risk）
  - `<risk>/RISK.md`：风控规则、触发流程、与 PCM/Execution 的接口。
  - `<risk>/limits.json`、`triggers.json`：阈值与规则集。

## 数据库契约（建议表）
- 数据层：
  - `data_manifest(id, universe, from, to, rows, hash, normalization, calendar, notes)`
  - `symbol(ref, exchange, asset_type, first_date, last_date, meta)`、`calendar(date, market, is_trading_day)`
- 因子层：
  - `factor_meta(name, frequency, lag, units, formula, deps, universe, owner, hash, created_at)`
  - `factor_value(name, symbol, date, value, quality_code, ver)`（唯一键 `(name,symbol,date,ver)`）
- 回测层：
  - `run(run_id, slug, engine_digest, params_hash, data_manifest_id, factor_manifest_id, start, end, status, created_at)`
  - `run_equity(run_id, date, nav, drawdown, exposure)`、`run_trade(run_id, order_id, symbol, side, qty, price, fees, slippage, ts)`
  - `run_metric(run_id, key, value)`、`run_artifact(run_id, key, ref, type, hash)`
- 组合层：
  - `portfolio_meta(name, objective, constraints, rebalance_days, notes)`
  - `portfolio_alloc(name, asof, target_type, target_id, weight)`（`target_type in ('strategy','alpha','asset')`）
- 执行/风控层：
  - `execution_policy(name, model, params_json)`、`execution_run(run_id, policy_name, stats_json)`
  - `risk_policy(name, rules_json)`、`risk_event(run_id, symbol, rule, severity, context_json, ts)`

幂等与事务：
- 幂等键建议：`(run_id, params_hash, engine_digest, data_manifest_id)`；写入前查重；全部写入走事务；失败回滚。

## Skills 体系（流程规范）
- 共 6 个技能：quant-data / quant-factor / quant-strategy / quant-portfolio / quant-execution / quant-risk。
- 统一准则：索引预加载（~/.codex/skills.json）→ 选择后加载正文 → 复述并制定计划（含范围/产物/回滚）→ 用户确认 → 执行。
- Gates：
  - quant-data：`data-quality-review`（缺失/对齐/复权/交易日）。
  - quant-factor：`factor-coverage-review`（覆盖率/滞后/质量码）。
  - quant-strategy：`spec-*` + `run-kpi-review`（Sharpe/MaxDD/交易数、敏感年份窗口）。
  - quant-portfolio：`portfolio-constraint-review`（约束与曝险）。
  - quant-execution：`execution-sanity-check`（盘口/流动性/成本参数）。
  - quant-risk：`risk-policy-review`（阈值/触发器影响范围）。

## src API 契约（占位签名）
- `src/data/lean_export.py`
  - `export_to_lean(universe, date_range, target_root) -> DataManifest`
  - `validate_lean_dataset(target_root) -> ValidationReport`
- `src/factor/compute.py`
  - `compute_and_write(name, universe, date_range, params) -> FactorManifest`
- `src/strategy/run.py`
  - `backtest(slug, params, data_manifest_id, factor_manifest_id) -> RunManifest`
  - `optimize(slug, objective, search_space, constraints) -> list[RunManifest]`
- `src/portfolio/optimizer.py`
  - `solve(weights_inputs, objective, constraints) -> dict[target, weight]`
- `src/execution/policy.py`
  - `select(model, **kwargs) -> ExecutionConfig`
- `src/risk/manager.py`
  - `apply(run_id, targets, policy_name) -> (adjusted_targets, events)`
- `src/db/client.py`
  - `with tx(): insert_* / upsert_*`（参数化 SQL + 事务）
- `src/lean/run.py`
  - `backtest(project_path, params) -> Path`（返回产物目录），并生成 `run_manifest`。

## 运行与审计
- 预告：写盘/导出/回测/入库前，输出 1–2 句包含“影响范围/产物位置/回滚策略”。
- 产物：采集 Lean `*-summary.json`、`statistics.json`、`orders.json`、`transactions.csv`、`log.txt`，清洗入库并保存文件引用。
- 日志：JSON 行，字段最小集：`ts, level, step, run_id, params_hash, ctx, elapsed_ms`。

## 迁移路线
- 1) 规范化命名：`Strategy/<slug>/STRATEGY.md`（本次已完成重命名）。
- 2) 搭建 Data/Factor/Portfolio/Execution/Risk 目录与配置占位；不迁移大数据。
- 3) 建立 src 包骨架与函数签名；后续将策略内通用代码抽取到 src。
- 4) 在 ~/.claude/skills/ 中创建 6 个 SKILL.md 骨架（仓内也保留副本以便审阅/版本化）。

---

## 附录A：AIS 数据库是否独立与合并至 aiscend 的讨论方案（Proposal）

本附录给出“是否单独保留 AIS 数据库”的决策建议与“并入 aiscend 数据库”的合并规划，仅为方案与思考。

### 决策结论
- 推荐合并：将 AIS 并入 aiscend，在同一物理实例内用独立 schema 做强隔离（或表名前缀），对象存储承载大体量工件。
  - 优点：单一真源、少副本；治理/审计集中；成本/运维收敛。
- 需保留独库的场景（备选）：合规隔离、OLTP/分析异构、极端写入/锁风险难以分区化时。此时可用“独立 AIS 库 + 只读外部表/FDW”隔离。

### 总体规划（并入 aiscend 数据库）
- Schema 分层（示例）：
  - `ais_meta`：技能/资源/配置与版本（skills、resources、configs、plans、gates）。
  - `ais_data`：数据清单与导出契约（`data_manifest`、`universe`、`calendar_ref`）。
  - `ais_factor`：因子定义与数值（`factor_meta`、`factor_value`、`factor_eval`）。
  - `ais_strategy`：运行与产物（`run`、`run_metric`、`run_equity`、`run_trade`、`run_artifact`、`signals`）。
  - `ais_portfolio`：组合（`portfolio_meta`、`portfolio_alloc`、`attribution`）。
  - `ais_execution`：执行（`execution_policy`、`execution_run`）。
  - `ais_risk`：风控（`risk_policy`、`risk_event`）。
  - `ais_lineage`：血缘/输入指纹/任务 DAG（`lineage_edge`、`inputs_fingerprint`）。
  - `ais_audit`：审计日志（plan、tool_call、gate、状态迁移）。
- 命名规范：主键 `id`（`uuid_v7`/snowflake）；时间 `created_at/updated_at`（UTC）；可选 `deleted_at`；幂等键：
  - `run`：（`run_id`, `params_hash`, `engine_digest`, `data_manifest_id`）。
  - `factor_value`：（`name`, `symbol`, `date`, `ver`）。
  - `signals`：（`as_of`, `symbol`, `book`）。
- 指纹与版本：`config_hashes`（Data/Factor/Strategy/Portfolio/Execution/Risk 六域）、`skill_versions`、`dag`（步骤图）。
- 分区与时序：
  - `factor_value`：按 `name` 哈希分区 + 日期二级分区（或 Timescale hypertable）。
  - `run_trade/run_equity`：按 `run_id` 分区；`signals` 按 `as_of` 分区并建 `(as_of, symbol)` 复合索引。
- 大对象：`run_artifact.ref` 指向对象存储（如 `s3://.../runs/<ts-hash>/statistics.json`），数据库仅存元数据与哈希。
- 访问控制：schema 级授权（`ais_admin`/`ais_writer`/`ais_reader`）；必要时启用 RLS 做项目级隔离。
- 环境隔离：`*_dev/stg/prod` 平行 schema；产线使用专属对象存储 bucket。
- 数据字典：集中字段定义/单位/滞后/质量码，绑定 `ais_meta.*` 与版本。

### 数据模型映射（从本设计到合并后）
- Data：`data_manifest`→`ais_data.data_manifest`；`universe`→`ais_data.universe`。
- Factor：`factor_meta`/`factor_value`/`factor_eval`→`ais_factor.*`。
- Strategy：`run`/`run_metric`/`run_equity`/`run_trade`/`run_artifact`/`signals`→`ais_strategy.*`。
- Portfolio/Execution/Risk：映射至 `ais_portfolio.*` / `ais_execution.*` / `ais_risk.*`。
- Lineage/Audit：`inputs_fingerprint/lineage_edge`→`ais_lineage.*`；审计→`ais_audit.logs`。

### 性能与隔离风险的缓解
- 写入洪峰：作业队列 + 按 `run_id`/`factor_name` 分片；短事务批量写；延迟/异步索引。
- 查询隔离：常用聚合做物化视图；报表走只读副本；按窗口裁剪与分区归档。

### 合并落地路线
1) 盘点：列出现有表/数据量/读写模式/SLA，产出 `ais_*` DDL 草案。
2) 影子环境：建立 `ais_*_stg`，以 Industry Momentum 试点贯通读写。
3) 双写与切换：应用主写 aiscend，稳定后停旧库写；回灌历史数据并做一致性校验。
4) 下线与清理：冻结旧 AIS，完成备份归档并停机；更新密钥、监控与运维手册。
5) 验收：新增告警（写入失败、幂等冲突、分区膨胀、慢查询）。

### 代码与配置改造要点（仓内影响，规划）
- `src/db/mapping.py` 支持 schema 前缀（如 `ais_strategy.run`），环境变量覆盖 schema 组（dev/stg/prod）。
- 统一 `tx()` 事务与 `ON CONFLICT` 幂等策略；`src/artifacts/io.py` 负责对象存储外链与哈希。
- 各域配置（JSON/YAML）同步登记 `ais_meta.configs`，其哈希写入 `run.config_hashes`。

### 备选：不合并的隔离方案
- 保持独库 + FDW/外部表只读引用 aiscend 原始数据；写入仍落 AIS；用 CDC/作业同步 KPI 摘要回 aiscend。

### 总结
- 合并更利于单一真源、统一治理与最小权限；通过 schema 隔离、分区/压缩、对象存储、只读副本和作业队列，化解写读混部与体量压力。
- 建议以 Industry Momentum 为试点完成 `ais_*_stg` 贯通后，再迁移全量量化域数据。
