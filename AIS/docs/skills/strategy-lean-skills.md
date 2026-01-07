# Claude Skill — 策略（QuantConnect Lean）全流程规范

## Skill 元信息
- 名称：strategy-lean-workflow
- 版本：v1.0.0
- 适用范围：在 QuantConnect LEAN 上进行策略研究的完整工作流（需求→设计→任务→实现→回测→参数优化→产物→治理）。
- 权威性：本技能文档定义流程与工件清单；具体到某一策略的权威配置以 `strategy/<slug>/strtegy.md` 为准。本仓当前策略为 `industry-momentum`。

## 对齐关系
- 策略级：`strategy/industry-momentum/strtegy.md`（权威参数/选项说明）。
- 规格级：`.claude/specs/industry-momentum-lean/{requirements.md,design.md}`。
- 流程级（本文）：贯穿会话的统一方法论、评审关卡与产物要求。

## 前置依赖与环境
- 代码与结构：遵循根 `AGENTS.md`；统一规范为：
  - 单一数据根：仅小写 `data/`，`lean.json` 的 `"data-folder"` 指向绝对路径（如 `/home/aiscend/work/AIS/data`）。
  - 策略目录：`strategy/<slug>/`（kebab-case），其中 Lean 项目固定放在子目录 `qc/`（例如：`strategy/industry-momentum/qc/`）。
  - 共享库：跨策略复用代码集中在 `src/`，并在根 `lean.json` 配置 `python-additional-paths: ["./src"]` 注入。
  - 产物归档：Lean 原生日志/回测在 `strategy/<slug>/qc/backtests/`；策略级精简产物在 `strategy/<slug>/runs/`、`strategy/<slug>/optimize/`、`strategy/<slug>/reports/`。
- 运行环境：Python 3.11+；Lean CLI；日志为结构化 JSON 行；DB 连接通过环境变量（不提交密钥）。
- 数据时间窗：覆盖 2008–2009、2020、2022 等关键年份以检验动量脆弱点。

## 工作流（Workflow）
1) 项目发现（Discovery）
- 遍历 `~/work/AIS-v1` 与相关目录；清点可复用组件与模式（平均名次融合、稳健调仓日、结构化日志、JSON 产物）。
- 输出：背景摘要与复用清单（对齐 specs 的“上下文复用”条款）。

2) 需求规格（Requirements — EARS）
- 核心：
  - 宇宙：ManualUniverseSelectionModel 固定 11 行业 ETF。
  - 信号：6–1 与 3–1 跳过月动量（日粒度，History 精确切片，剔除当日样本），平均名次融合。
  - 组合：仅多 Top‑N + 等权；非赢家 Flat。
  - 调度：`rebalance_frequency_days`（默认 90）。
  - 风控/过滤（可选）：VIX 开关、组合波动阈值、绝对动量、资产波动过滤。
  - 优化：Grid/Euler + WFO；目标/约束明确。
- 日志与产物：JSON 行（事件/耗时），KPI 与调仓快照 JSON，DB 对接 JSON。
- 工件：`.claude/specs/<feature>/requirements.md`（本仓为 `industry-momentum-lean`）。
- 评审关卡：`spec-requirements-review`。

3) 设计文档（Design）
- LEAN 架构映射：Universe/Alpha(Update/GenerateInsights)/PCM(EqualWeighting)/Execution(Immediate)/Risk（可选）。
- 详细执行流：按日节流→历史切片→收益计算→平均名次→Top‑N→Up/Flat→等权→（可选）风控覆盖。
- 日志架构：事件键、级别、耗时字段；当日数据剔除、防前瞻；WarmUp 公式。
- 目录结构（策略级）：
  - `strategy/<slug>/qc/`：Lean 项目根（main.py、config.json、algo/、backtests/）。
  - `strategy/<slug>/configs/`：parameters.*.json、optimization.*.json、scenarios.json。
  - `strategy/<slug>/scripts/`：该策略专属脚本（批量回测、汇总、报告生成）。
  - `strategy/<slug>/runs/`、`strategy/<slug>/optimize/`、`strategy/<slug>/reports/`。
- DB 契约：backtest_run/equity/trade/factor_meta/value 字段映射。
- 工件：`.claude/specs/<feature>/design.md`。
- 评审关卡：`spec-design-review`。

4) 实施任务清单（Implementation Plan）
- 内容：将设计拆解为可执行编码步骤（Universe/Alpha/Risk/日志/产物/优化脚本/测试），每步映射到“详细执行流”编号，含验证标准与日志校验点。
- 工件：`.claude/specs/<feature>/tasks.md`。
- 评审关卡：`spec-tasks-review`。

5) 编程实现（Coding — 受控阶段）
- 原则：先最小可用链路（Universe→Alpha→PCM→Execution），再可选风控与过滤；严格 JSON 日志与产物；剔除当前日数据。
- 代码位置：`strategy/<slug>/qc/algo/`（按设计定义的模块名与类名）。
- 共享代码：放入 `src/` 并通过 `python-additional-paths` 注入。
- 校验：按“实现检查点（C1–C6）”逐步自检并记录日志与产物。

6) 回测（Backtest）
- 参数：复制 `strategy/<slug>/configs/parameters.default.json` 到 Lean 项目 `qc/config.json` 的 `parameters`。
- 运行（本地 Lean CLI）：`lean backtest "strategy/<slug>/qc"`；产物包含 KPI、调仓快照与 run manifest。
- 关键区间：验证 2008–2009、2020、2022 的表现差异与风险点。

7) 参数优化（Optimization）
- Grid/Euler：参考 `strategy/industry-momentum-lean/configs/optimization.{grid,euler}.json`；设置目标（Sharpe/Drawdown）与约束（TotalTrades/Drawdown）。
- WFO：按 `optimization.walkforward.json` 窗口训练/测试，输出 OOS 汇总曲线与每窗最优参数集。
- 选择：优先“高原”参数区，避免过度拟合尖峰；记录最优前 k 与稳定性评述。

8) 结果治理与发布（Governance & Release）
- 规格同步：requirements/design 若有变更，更新并记录 `docs/CHANGELOG_EXEC_FLOW.md`。
- DB 对接：导出对齐 JSON（run/equity/trade、factor_value）；可由批处理入库。
- 版本化：run manifest 记录 git 提交、spec 哈希与参数哈希，确保可复现。

9) 执行与自动化（Execution & Automation）
– 本地执行根目录要求：`<repo-root>`（Lean 项目根）。所有回测/优化均在该目录执行。
  - 准备（一次性）：
    - 在 `<repo-root>` 中创建/选择一个 Python 策略项目（可用 Lean CLI 创建模板）。
    - 将 `strategy/industry-momentum/algo/` 下的文件复制到该 Lean 项目（保持包结构），并确保 `strategy/industry-momentum/qc` 可被 Lean 识别（文件名与类名一致）。
    - 将 `strategy/industry-momentum/configs/parameters.default.json` 的 `parameters` 段合并进 Lean 项目 `config.json`。
    - 数据准备（默认方式A，推荐）：从 aiscend 数据库 `ticker_price` 导出至 `data/` 目录：
      - 命令：`python strategy/industry-momentum/scripts/export_db_prices_to_lean.py $AISCEND_DB_URL 2007-01-01 2025-10-01 XLC XLY XLP XLE XLF XLV XLI XLB XLRE XLK XLU`
      - 结果：写入 `<repo-root>/data/equity/usa/daily/<ticker>.zip`（Lean 日线格式）。
      - 说明：该方式为未来默认数据获取路径；Lean CLI 下载方式为备选。
  - 运行回测：
    - 切换目录：`cd <repo-root>`
    - 启动方式一（Launcher，本机 .NET）：
      - 先满足 Python 运行时要求：PythonNET 2.0.50 对应 Python 3.10/3.11；请安装对应版本并设置：
        - `export PYTHONNET_PYDLL=/path/to/libpython3.10.so.1.0`（或 3.11）
      - 运行：`dotnet run --project Launcher -c Release`
      - 说明：若本机仅有 Python 3.12+/3.13，将出现 `BadPythonDllException`，请改用 Lean CLI（方式二）或安装 3.10/3.11。
    - 启动方式二（推荐，Lean CLI + Docker；仅离线/本地数据）：
- 执行回测（本地 Lean CLI）：`lean backtest "strategy/<slug>/qc"`

### 按需补齐 + 日更（本地优先）
- 原则：
  - 回测前先检查本地 `data/` 是否覆盖本次 Universe；若缺口则即时从 AiScend 拉取“全历史”并转换为 QC 规范（daily/map/factor）。
  - 回测后把本次用到的 Ticker 写入注册清单 `data/registry.txt`，交由 aiscend 用户级 crontab 的日更任务自动增量维护。
- 脚本：
  - `scripts/prefetch_on_demand.sh [ProjectName] [TICKERS_CSV] [START] [END]`
    - 示例：`bash scripts/prefetch_on_demand.sh strategy/industry-momentum/qc "XLC,XLY,SPY" 2007-01-01 2023-12-31`
  - `scripts/check_and_prefetch.py`：
    - 检查 `data/equity/usa/daily/{ticker}.zip` 覆盖；缺口→调用 `export_db_prices_delta.py` 导出到 `data-staging/raw_equity/`，再由 `scripts/toolbox_import.sh` 转为 QC 规范落盘到 `data/`。
    - 追加使用的 Ticker 至 `data/registry.txt`。
  - `scripts/daily_sync.sh`（crontab 调用）：
    - 每日增量：优先读取 `data/registry.txt`，若不存在回退 `scripts/tickers.txt`；导出 DB 增量并 ToolBox 转换。
- crontab（aiscend 用户）：
  - `crontab -e -u aiscend`
  - `10 2 * * * flock -n /home/aiscend/work/AIS/.locks/daily_sync.lock bash -lc '/home/aiscend/work/AIS/scripts/daily_sync.sh' >>/home/aiscend/work/AIS/logs/daily_sync.log 2>&1`
    - 产物：回测结束后，将产出复制或写入至 `strategy/industry-momentum/runs/` 为 `*_manifest.json / *_kpis.json / *_snapshots.json`（可在算法内或通过脚本搬运）。
  - 批量场景：
    - `strategy/industry-momentum/configs/scenarios.json` 定义常见实验组合；在 `<repo-root>` 逐个注入 `parameters` 并执行 backtest。
  - 报告：
    - `python strategy/industry-momentum/scripts/generate_report.py` 生成 `strategy/industry-momentum/reports/SUMMARY.md`。
  - 入库：
    - 导出 `AISCEND_DB_URL` 后执行 `python strategy/industry-momentum/scripts/ingest_to_ais.py <manifest> <kpis> <snapshots>`；遵循事务/参数化 SQL。

10) 合规与可审计（Compliance & Audit）
- 运行日志必须为 JSON 行，包含 `run_id/params_hash` 与耗时；产物需保存在 `runs/` 下，并可被 DB 入库脚本消费。
- 关键年份（2008–2009、2020、2022）需在报告中明确标记各自 KPI（如窗口覆盖）。

11) 角色分工与权威来源
- 流程级权威：本文件（strategy-lean-skills.md）。
- 策略级权威：`strategy/industry-momentum/strtegy.md`（参数/选项/执行细节）。如两者冲突，以策略级为准；流程新增步骤需在此文件维护。

12) 本地路径规范与一致性（统一版）
- 统一约定：仅小写 `data/` 为唯一数据根；每个策略 Lean 项目置于 `strategy/<slug>/qc`。
- 共享代码放在 `src/` 并通过 `python-additional-paths` 注入；参数通过 `strategy/<slug>/configs/parameters.*.json` 注入 `strategy/<slug>/qc/config.json`。
- Lean 原生产物保存在 `strategy/<slug>/qc/backtests/`；策略级摘要与优化结果落在 `strategy/<slug>/runs/` 与 `strategy/<slug>/optimize/`；manifest 记录 git 提交与参数哈希。

## 输入与输出（Inputs/Outputs）
- 输入：
  - 策略想法/参考文档路径（本会话：`docs/industry moment QuantConnect Lea.md`）。
  - 运行时间窗、目标指标、约束、风险偏好（VIX/波动阈值）。
- 输出：
  - 规格：requirements.md、design.md、tasks.md。
  - 策略目录：`strategy/industry-momentum/strtegy.md` + `configs/*.json`。
  - 回测与优化：KPI 与快照 JSON、最优参数与 WFO 汇总。
  - 治理：DB 对接 JSON、变更日志与版本清单。

## 日志与产物（Logging & Artifacts）
- 事件：`init`、`schedule_tick`、`history_fetch`、`calc_returns`、`rank_table`、`select_winners`、`emit_insights`、`risk_switch`、`metrics_done`、`artifacts_saved`、`data_insufficient`。
- 级别：DEBUG/INFO/WARN/ERROR/FATAL；必须包含耗时（毫秒）与上下文（run_id、params_hash）。
- 留存：本地保留近 30 个 run 目录；云端依平台策略；尽可能使用 ObjectStore。

## 安全与合规
- 禁止提交密钥；DB 读取通过环境变量（如 `AISCEND_DB_URL`）；所有数据库写入需使用事务与参数化 SQL。
- 防前瞻：剔除当日样本；预热遵循 `(max(j1,j2)+skip)+buffer_days`；不足样本限频 WARN。

## 评审关卡（Gates）
- 需求确认：`spec-requirements-review` 通过后进入设计。
- 设计确认：`spec-design-review` 通过后生成任务清单。
- 任务确认：`spec-tasks-review` 通过后进入编码与回测。

## 可选扩展
- 双动量（绝对+相对）、MVO/Risk Parity、行业/资产分层日志、风险预算型 PCM。

## 清单（Checklist）
- [ ] requirements.md 完成并通过评审
- [ ] design.md 完成并通过评审
- [ ] tasks.md 完成并通过评审
- [ ] strtegy.md（策略级）与 configs/*.json 就绪
- [ ] 代码最小链路跑通（C1–C6 检查点）
- [ ] 回测覆盖关键年份并生成产物
- [ ] Grid/Euler 完成并输出最优前 k
- [ ] WFO 完成并输出 OOS 曲线
- [ ] DB 对接 JSON 验证通过
- [ ] 变更日志与版本清单更新


**Engine Image**: Pinned Lean engine image: quantconnect/lean@sha256:cfb27fae17ba0fc627e6c40a1c7d29e1a726466c6a7fe1e8b0f5030bcab70864
