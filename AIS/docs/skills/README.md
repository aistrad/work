# Skills System (Process-Level Authority)

This folder defines the organization-wide skills system for Lean-based research and trading. It provides process-level conventions and machine-readable templates that orchestrators can parse.

说明（中文）：本目录为“流程级权威”规范与模板。每个具体策略/Alpha/Portfolio 的“单体事实来源”文档放在 `strategy/<slug>/strtegy.md`、`alpha/<slug>/strtegy.md`、`portfolio/<slug>/strtegy.md`。Orchestrator 从这些文档提取元数据（YAML Front-Matter）生成可执行的 Run Recipe。

Key goals
- Single data root: `data/` only, QC-compatible.
- Single data source: AiScend DB via AISCEND_DB_URL.
- Declarative skills: documents own the truth; code reads specs.
- Reusable orchestrator in `src/aisc/*` applies to all skills.

Folders
- `templates/` English-format templates for Strategy, Alpha, Portfolio (content in Chinese).
- `db/` Proposed SQL schemas for skills tables in AiScend DB.
- `manifest.yaml` Machine list of available skills and locations.

