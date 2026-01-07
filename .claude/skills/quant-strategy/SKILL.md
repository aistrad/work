---
name: quant-strategy
description: 适用【quant】；当开展投资研究与量化策略落地时触发；用于从问题→假设→数据→回测→风控→归档复盘的精益流程；输入包含目标、标的/因子、样本区间与频率、约束与评价指标；输出实验日志、KPI 报表、回测快照与复盘结论；默认先计划，确认后执行。
---

# Overview and Intent
- 以“小步快跑、证据优先”为原则，最短路径验证投资假设并沉淀可复现产物；强调风控、可审计与回滚能力。以下内容基于现有 AIS Strategy 文档重组，保留原有语义，仅进行结构化编排与版式统一。

# Quick Start
- 触发：`skill quant-strategy` 或 `skill plan quant-strategy <brief-goal>`。
- 触发意图示例：投资/分析/研究/量化/回测/组合/仓位管理/风控。
- 默认最小权限：禁网、禁安装新包、不写系统目录；联网/下载数据/写盘前需预告范围/影响/回滚策略，得到确认后执行。
- 幂等策略：时间戳分区或内容哈希比对；所有写入均记录审计日志；必要时可回滚到上次有效产物。
- 合规：MUST NOT 修改任意路径下 `AGENTS.md`。

# Workflows / Function / Inputs / Outputs
- Function（能力范围）
  - 定义问题与目标 → 提出可证伪假设 → 准备与描述数据 → 快速回测（先闭环）→ 风控校验 → 归档与复盘。
- Inputs（最小输入）
  - `目标`（KPI 与评价口径）、`标的/因子集合`、`样本区间`（训练/验证/滚动）、`频率`（D/W/M/min）、`约束`（持仓/波动/回撤）、`成本假设`、`基准/比较组`。
- Outputs（主要产物）
  - 日志：`logs/<date>/backtest.jsonl`（事件/参数/KPI/副作用）
  - 报表：`reports/<date>/kpi.md`、图表与表格
  - 快照：`snapshots/<date>/positions.parquet`、`orders.csv`
  - 复盘：`reviews/<date>/conclusions.md` 与下一步计划

- Core Workflows（保留原始条款为指令块）

```text
# Scope（原文节选）
从研究问题提出到策略上线前的全流程：定义问题→提出可检验假设→准备与描述数据→快速回测→风控校验→结果归档→复盘审计。

# Workflow（原文重排为 6 步）
1) Frame the Question
- 明确定义可度量的目标与评价口径（如年化、回撤、交易次数与胜率）。

2) Form Hypotheses
- 写出可证伪的假设及其数据证据；列出主要风险渠道与预期失效情景。

3) Prepare Data
- 标注数据时间窗、频率、存储位置与去未来函数处理；记录数据质量问题及修复方案。

4) Backtest Quickly
- 优先构建最小闭环，先跑通核心链路；记录关键事件为 JSON 行日志，产出 KPI 与调仓快照。

5) Risk Controls
- 设定持仓/波动/回撤等约束；验证敏感区间表现（如 2008-2009、2020、2022）。

6) Archive & Review
- 将结果、参数、代码与日志以可追溯方式归档；撰写简明结论与下一步计划。

# Checklists（原文节选）
- Entry: 目标、数据来源、评价指标已明确；无前瞻与数据泄漏。
- Exit: 产物齐全（日志/KPI/快照/参数清单）、关键结论可复现、风险点已评估。

# Safety（原文节选）
- 所有计算与结论必须附证据（日志/图表/表格）；对异常区间必须解释或记录为后续工作。
```

# Scripts / Reference / Best Practices / Integration Points
- Scripts（可选映射）
  - `scripts/prepare_data.py`、`scripts/run_backtest.py`、`scripts/report_kpi.py`；与 `workflow.yaml` 的 `steps[].script` 对应。
- Reference（参考）
  - `references/backtest-metrics.md`、`references/risk-controls.md`、`schemas/*.json`（输入/输出/日志行校验）。
- Best Practices（要点）
  - 先闭环后优化；记录“输入哈希→输出引用”。
  - 日志字段最小集：`timestamp`、`step`、`input_hash`、`output_ref`、`side_effects`、`status`。
  - 幂等/回滚：时间戳分区或内容哈希比对；写入前 1-2 句预告。
  - 安全：MUST NOT 修改任意路径下 `AGENTS.md`；默认最小权限（禁网、禁装包、不写系统目录）。
- Integration Points（集成）
  - 与数据层（本地/对象存储/数据源 API）解耦；与风控/审计系统对接；如需联网/安装包，先预告并经确认。

