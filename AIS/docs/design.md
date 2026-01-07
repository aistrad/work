# Skills-Orchestrated Lean Backtesting — Design

Version: 0.1 (Planning Only)
Status: Draft (No code changes applied)

1. Goals（目标）
- 将当前“策略强耦合、脚本硬编码”的回测流程重构为“文档驱动”的、可编排的、可审计的体系：
  - 流程级权威：`AIS/.claude/skills/strategy-lean-skills.md`（Process-level Skills）。
  - 策略级权威：`AIS/strategy/<slug>/strtegy.md`（Strategy Single Source of Truth）。
  - 新增两类 Skills：`alpha/` 与 `portfolio/`，并提供统一模板与目录规范。
- 以 AiScend 数据库为唯一数据来源；仅生成 QC 规范数据到 `data/`。
- 通过 `src/` 的通用编排程序（Orchestrator）驱动本地 Lean 引擎，不再在策略内堆叠脚本。
- 重要文档（流程/策略/Alpha/Portfolio 及报告）由数据库统一管理并驱动（Doc-as-Truth）。

2. Non-Goals（非目标）
- 此阶段不改动策略的核心 Alpha 计算与交易框架，只改“组织形式与编排方式”。
- 不引入除 Lean 本地引擎以外的新引擎。

3. Terminology（术语）
- Skill：一类可被 Orchestrator 消费的“能力文档”，分为 Strategy / Alpha / Portfolio。
- Recipe：由技能文档解析、融合得到的“可执行食谱”，Orchestrator 用其调用数据管线与 Lean。
- Orchestrator：位于 `src/` 的通用程序，解析技能文档→生成 Recipe→调 Lean→汇总产物→入库。

4. Architecture Overview（架构总览）
```mermaid
flowchart LR
  A[Process Skills\n.claude/skills/*.md] --> P[Spec Parser]
  B[Strategy/Alpha/Portfolio\n<slug>/strtegy.md] --> P
  P --> R[Run Recipe]
  R --> D[DataPipe\n(AiScend -> QC data/)]
  R --> L[LeanRunner\n(lean backtest)]
  L --> BT[qc/backtests/<ts>]
  L --> K[KPI Extractor]
  K --> RUNS[strategy/<slug>/runs/]
  RUNS --> REP[Report Builder]
  REP --> DB[(AiScend DB\nskill_docs/skill_runs/...)]
  D -->|registry| data[(data/)]
```

5. Skills Directory & Templates（目录与模板）
- 仅保留流程级权威目录：`AIS/.claude/skills/`
  - `templates/`：模板采用“keys in English, content in Chinese”的格式约定。
  - `manifest.yaml`：技能清单（machine-readable）。
- 三类技能的单体事实来源：
  - Strategy：`strategy/<slug>/strtegy.md`
  - Alpha：`alpha/<slug>/strtegy.md`
  - Portfolio：`portfolio/<slug>/strtegy.md`
- 文件命名：统一小写；`strtegy.md` 用于策略/Alpha/组合的“事实来源文档”。

6. Templates（模板，Keys in English, Content in Chinese）
6.1 Strategy Template（示例）
```yaml
---
kind: Strategy
slug: industry-momentum
version: 1.0.0
universe:
  tickers: [XLC, XLY, XLP, XLE, XLF, XLV, XLI, XLB, XLRE, XLK, XLU]
parameters:
  j1_lookback_days: 126
  j2_lookback_days: 63
  skip_days: 21
  rebalance_frequency_days: 90
  max_holdings: 3
switches:
  enable_vix_switch: false
  enable_abs_momentum_filter: false
  enable_asset_vol_filter: false
objectives:
  primary: SharpeRatio
  direction: maximize
  constraints:
    - { metric: Drawdown, op: '<=', value: 0.35 }
data:
  source: aiscend
  root: data/
  qc_contract:
    time_format: 'YYYYMMDD 00:00'
    map_factor_alignment: true
orchestration:
  engine: lean-local
  outputs:
    backtests_dir: strategy/<slug>/qc/backtests
    runs_dir: strategy/<slug>/runs
    optimize_dir: strategy/<slug>/optimize
    reports_dir: strategy/<slug>/reports
---
```

6.2 Alpha Template（示例：以 Alpha 取代 factor）
```yaml
---
kind: Alpha
slug: quality-trend
version: 1.0.0
description: >
  （中文）Alpha 本质为 AiScend 数据字典定义的基础字段与衍生逻辑的组合。
  例如：依据 ticker_price 与财务表联合，计算“质量趋势”评分。
source:
  aiscend:
    tables:
      - ticker_price
      - f_financial_trends
    dictionary_refs:
      - docs/aiscend_dict.md#ticker_price
      - docs/aiscend_dict.md#f_financial_trends
logic:
  window: 252
  steps:
    - name: align_calendar
      desc: 交易日对齐与缺失填充（前值填充）
    - name: compute_metrics
      desc: 指标计算（示例：ROE/ROA/毛利率稳定性）
    - name: zscore_winsor
      desc: 去极值+标准化
    - name: combine
      desc: 加权合成 Alpha 值（0-1）
storage:
  tables:
    - alpha_meta
    - alpha_value
    - alpha_run
orchestration:
  compute_mode: batch
  output_root: data/alpha/<slug>/
---
```

6.3 Portfolio Template（示例）
```yaml
---
kind: Portfolio
slug: risk-parity-lite
version: 1.0.0
objective:
  target: volatility
  direction: minimize
constraints:
  - { metric: gross_exposure, op: '<=', value: 1.0 }
  - { metric: weight, scope: per-asset, op: '<=', value: 0.3 }
inputs:
  strategy_ref: strategy/industry-momentum/strtegy.md
  alpha_refs:
    - alpha/quality-trend/strtegy.md
optimizer:
  method: coordinate_descent
  iterations: 200
orchestration:
  engine: lean-local
  outputs:
    portfolios_dir: portfolio/<slug>/runs
---
```

7. Orchestrator ↔ src Mapping（技能到代码的映射）
- src/aisc/spec/
  - parser.py：解析 .claude/skills 与 strategy/alpha/portfolio 的 YAML Front-Matter，生成 Recipe。
  - schema.py：定义 Recipe / Universe / Parameters / Objectives / Artifacts 的数据结构。
- src/aisc/data/
  - aiscend_client.py：封装 AISCEND_DB_URL，仅连接 aiscend，提供统一查询。
  - pipeline.py（DataPipe）：将 DB 导出转换为 QC 规范（equity/index），对齐 map/factor，维护 registry.txt。
  - validate.py：QC 文件校验（时间格式/列数/首日对齐）。
- src/aisc/engine/
  - lean_runner.py：注入 parameters/universe 到 Lean 项目 config.json，调用本地 `lean backtest`。
  - extract.py：从 backtests/<ts> 提取 summary、曲线与交易，写入 runs/。
- src/aisc/opt/
  - grid.py/euler.py/wfo.py：根据技能文档的参数空间批量生成 Recipe 并编排运行。
- src/aisc/report/
  - builder.py：生成策略/组合报告（中文正文，英文字段名），危机年份切片与基准对比。
- src/aisc/docs/
  - sync.py：将策略/流程文档与报告推入 DB（skill_docs/skill_runs），并支持 pull。

8. Database Schema（核心表，草案）
- skill_docs(id, kind, slug, content_md, content_hash, version, created_at, updated_at)
- skill_runs(id, kind, slug, run_id, params_hash, git_sha, kpi_json, manifest_json, start, end, created_at)
- alpha_meta(alpha_slug, field, description, dictionary_ref, version, created_at)
- alpha_value(alpha_slug, ticker, date, value, quality_flag)
- alpha_run(id, alpha_slug, recipe_hash, git_sha, start, end, rowcount, created_at)
说明：Alpha 以“字典引用 + 逻辑步骤”为核心，与数据字典（docs/aiscend_dict.md）建立明确引用关系；所有技能文档与运行产物入库，形成“文档-运行-报告”可追溯链。

9. Data Contract（数据契约）
- 唯一数据源：AiScend（AISCEND_DB_URL）。
- 写盘：仅写入 `data/` 为 QC 规范；equity/usa/daily/*.zip 与 index/usa/daily/vix.zip；map_files、factor_files 首日对齐。
- 时间格式：`YYYYMMDD 00:00`。
- VIX：DB 符号 VIXX → QC 符号 VIX 由 DataPipe 映射统一处理。

10. CLI（初期）
- `ais run backtest --strategy <slug> --start 2007-01-01 --end 2023-12-31`
- `ais data sync --strategy <slug>`
- `ais optimize grid --strategy <slug> --space default`
- `ais report build --strategy <slug> --run <id>`
- `ais docs push|pull --scope process|strategy|alpha|portfolio --slug <slug>`

11. Governance & Logging（治理与日志）
- Orchestrator 日志：JSON 行（event, level, run_id, params_hash, git_sha, recipe_hash, duration_ms）。
- Manifest：记录 spec_hash、recipe_hash、lean_version、engine_image_digest、data_registry_hash、universe_hash。
- 审计：skill_docs 与 skill_runs 双向关联，保证“规范→运行→报告”闭环可追溯。

12. Migration Plan（迁移计划，仅规划）
- Phase A（两周）：落地 parser / datapipeline / lean_runner / minimal CLI；以 industry-momentum 为试点。
- Phase B（两周）：接入 grid/euler/wfo 与 report；docs push/pull；将 Alpha 替代 legacy factor 管线。
- Phase C（持续）：推广到多策略；完善数据质量守护与自动修复；建立稳健性测试集。

13. Risks & Mitigations（风险与对策）
- 规范可执行性：通过 pydantic 校验 YAML Front-Matter，文档不合规即阻断运行并给出路径/行号提示。
- 数据质量：DataPipe 强校验（时间格式/缺失/错列）；报告展示数据质量摘要；必要时自动重写 map/factor。
- 引擎差异：锁定 Lean 镜像 digest；所有 CLI 调用集中在 lean_runner 封装。

14. Open Questions（开放问题）
- Portfolio 对接 Alpha 与 Strategy 的最佳落点：在 Recipe 级做绑定，还是在 Report 阶段生成合成序列？
- Alpha 的质量标识（quality_flag）与字典条款的联动程度（是否要求每个字典字段都具备“可信度评分”？）。

（本设计为规划文档，不伴随任何代码/目录改动；实施需另行评审与安排。）

