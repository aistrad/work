# AIS（Agentic Investment System）开发规范（Dev‑Spec）

**— Codex 中枢、域优先组织、Skill 兼容、发布即治理**

> 本文件是 **Codex 下一步 dev‑spec 模式开发的唯一完整参照**。
> 目标：在**不关心 Codex 内部实现细节**的前提下，统一“域 → DB → 配置 → L2 API → Skills → 调度”的工程契约；研究/交互由 Codex（agentic）全权驱动，固定流程由 **crontab + DB** 承载；配置“文件 + 数据库管理”防止硬编码；Skills 的**安装路径与索引**严格遵循既有规范。 

---

## 0. 术语与约定

* **Codex**：唯一 agentic 中枢（黑盒）。仅通过 **Skills** 与之协作；Skills 只调用 L2 API。
* **域（Domain）**：六个功能域 `data / factor / strategy / portfolio / execution / risk`。
* **L1 / L2 / L3**：L1=引擎与基础设施；L2=稳定 API（`src/`）；L3=Skills（流程知识）。
* **SSoT**：Single Source of Truth；本规范要求**治理与运行元数据以 DB 为唯一真源**。
* **MUST/SHOULD/MAY**：分别表示强制/推荐/可选。

---

## 1. 顶层架构与边界（稳定三层）

```
User (PM/CIO/Quant) ── Chat/CLI/Portal
         │
         ▼
    Codex（黑盒，所有 agentic 能力）
         │  仅通过 Skills 协作
         ▼
   L3 Skills（流程/研究/交互）
         │  调用
         ▼
   L2 稳定 API（ais/domain/<d>/src/*）
         │  封装
         ▼
L1 引擎与基础设施（Lean/DB/FS/队列…）
```

**要求**

* Skills **MUST** 仅调用 L2；不得直连 DB/引擎。
* 研究/交互类流程 **MUST** 由 Codex 编排；固化后的流程 **MUST** 走 crontab+DB。

---

## 2. 仓库组织（域优先）与 `spec.md`（域唯一协作规范）

### 2.1 目录结构（每个域“一仓到底”）

```
ais/
└─ domain/
   ├─ data/
   │  ├─ spec.md            # ← 本域“唯一协作规范”，兼容 Skill 规范外形（见 2.2）
   │  ├─ src/               # ← L2 稳定 API（仅此对 Skills 暴露）
   │  ├─ configs/           # ← 人类可读配置；上线即导入 DB 管理
   │  ├─ schemas/           # ← JSON Schema（I/O、配置）
   │  ├─ sql/               # ← 本域 DDL/Migration/视图
   │  ├─ jobs/              # ← 本域作业模板（YAML/SQL）
   │  ├─ tests/             # ← 合约测试（API/Schema/数据质量）
   │  └─ skills/            # ← ★ 开发版技能源码（见 5.1）
   ├─ factor/ …（同构）
   └─ …（六域同构）
```

* `spec.md` 是**该域对“用户 ↔ Codex/系统”的唯一协作规范**；CI **MUST** 以其为源生成/校验 L2 存根、Schema、作业模板与配置清单。

### 2.2 `spec.md` 的外形与内容（**完全兼容 Skill 规范**）

* **Frontmatter**：仅含 `name`、`description` 两键（与 `SKILL.md` 一致）。
* **正文**：固定四个英文标题
  `Overview and Intent`、`Quick Start`、`Workflows / Function / Inputs / Outputs`、`Scripts / Reference / Best Practices / Integration Points`。
* **固定部分**：在正文中嵌入 **`Domain Contract`（YAML 代码块）**，即旧 `DOMAIN.yaml` 的等价体，供工具解析。

**`ais/domain/factor/spec.md` 示例骨架（节选）**

````markdown
---
name: domain-factor
description: 因子域：定义/计算/质检/发布的统一协作规范（对 Skills 与 L2 的契约）。
---

# Overview and Intent
- 本域提供因子定义与计算的标准化能力；Skills 通过 L2 API 调用，结果写回本域权威表。
- 默认“先计划/预览，后执行”；命中高风险标签需 HITL 审批。 

# Workflows / Function / Inputs / Outputs
## Domain Contract (YAML, 固定段落)
```yaml
domain: factor
owners: [alice.pm, bob.qpm]
contracts:
  apis:
    - name: compute
      entry: ais/domain/factor/src/compute.py:run
      input_schema: ais/domain/factor/schemas/compute.input.json
      output_schema: ais/domain/factor/schemas/compute.output.json
      idempotent: true
      side_effects: ["ais_factor.f_value_daily"]
  datasets:
    - name: ais_factor.f_value_daily
      keys: [asof, ticker]
      retention: "P5Y"
  skills_allowed:
    - name: factor-compute-value
      version_range: ">=1.1.0 <2.0.0"
  job_templates:
    - name: nightly_factor_value
      cron: "0 2 * * 1-5"
      calendar: XNYS
      using: skill:factor-compute-value
governance:
  risk_tags: []
  metrics_slo: { ic_mean_min: 0.02, coverage_min: 0.7 }
compat:
  min_skill_spec: "1.0.0"
  l2_api_stability: "semver"
````

```

---

## 3. 数据库（Domain‑Driven Schema + 控制面 SSoT）

### 3.1 Schema 划分（Postgres 示例）
- **控制面（SSoT）**：`ais_core`  
  - `skill_registry`, `agent_strategy_registry`, `config_store`, `job_schedule`, `job_run`, `run_config_snapshot`, …（治理/版本/运行/审计）。
- **数据面（领域模型）**：  
  - `ais_data`, `ais_factor`, `ais_strategy`, `ais_portfolio`, `ais_execution`, `ais_risk`（各域事实/派生表与视图）。

**表约定（数据面）**
- 事实行 **MUST** 带 `run_id`、`config_id`、`created_at`；  
- 大对象（报告/图表）**MAY** 存对象存储，表内存 `blob_uri` + `sha256`；  
- 对外可见的数据集 **MUST** 在 `Domain Contract.datasets` 登记。

**SSoT 原则**：治理/状态/版本/运行元数据 **MUST** 以 DB 为唯一真源；文件仅作可读稿与大对象。

---

## 4. L2 稳定 API（`ais/domain/<d>/src`）
- 每域暴露有限且稳定的入口（如 `compute.py:run`、`run.py:backtest`）。  
- 签名与 I/O **MUST** 由 `Domain Contract.apis` + `schemas/` 定义并在 CI 校验。  
- L2 **MUST**：  
  1) 只读 **配置快照**（`config_store → run_config_snapshot`），  
  2) 封装引擎差异（Lean 等），  
  3) 记录审计字段（`run_id/config_id/skill_version`）。

---

## 5. Skills：开发目录、发布路径、索引与命名

### 5.1 技能的**开发版**与**发布版**
- **开发版（源码托管）**：放在 **对应域下**，便于就近协作与测试：  
  `ais/domain/<domain>/skills/<skill-name>/`（含 `SKILL.md`、`scripts/`、`references/`、`assets/`）。  
- **发布版（运行安装）**：统一发布/同步至运行机：  
  `~/.claude/skills/<skill-name>/SKILL.md`（**唯一有效安装路径**）；并更新 `~/.codex/skills.json`（**仅三键**：`name/description/path`）。  
- **发布工具**：提供 `ais skills publish`（或 `sync`）将开发版**拷贝/链接**到安装路径，并自动重建索引。  
- **权威注册**：发布后在 `ais_core.skill_registry` 记录 `name/version/owner/tags/allowed_tools/dependencies/metrics`；索引文件仅做 Agent 发现，不是权威。

### 5.2 兼容要求（与 Skill 规范一致）
- `SKILL.md` frontmatter **ONLY** `name/description`；目录与 `name` 必须 **kebab‑case ≤ 64**；`name` 不得含保留字 `anthropic`、`claude`。  
- `~/.codex/skills.json` 的 `path` **MUST** 指向 `~/.claude/skills/<name>/SKILL.md`。

### 5.3 命名建议
- 形如：`<domain>-<verb>-<object>[-qualifier]`（例：`factor-compute-value`、`strategy-run-backtest`）；版本采用 semver，**MUST NOT** 编入 `name` 或路径。

---

## 6. 配置治理（文件 + DB 管理 + 快照）
- 合成顺序：`defaults → env(prod/stage/dev) → DB 激活版本 → runtime overrides` → **Resolved Config**；  
- 每次执行 **MUST** 固化快照入 `run_config_snapshot` 并在产物中携带 `config_id`；  
- 代码/Skills **MUST NOT** 硬编码路径、阈值或凭据。

---

## 7. 调度与固化（crontab + DB + Runner）
- **运行时序**：`crontab → job-runner → ais_core.job_schedule → 执行（Skill 或 L2）→ ais_core.job_run`。  
- **字段要点**：  
  `job_schedule(job_id, name, cron_spec, tz, trading_calendar, target_type[skill|l2], target_ref, config_id, enabled, concurrency, retry, owner)`；  
  `job_run(run_id, job_id, scheduled_at, started_at, ended_at, status, error, logs_uri, config_snapshot_id, artifact_refs, codex_trace_id, cost_metrics)`；  
  可选 `job_dependency`（有序 DAG）。  
- **模板**：各域 `jobs/*.yml` 渲染入 `job_schedule`（如夜间因子、周度回测、月度再平衡）。

---

## 8. 安全与治理（HITL / 标签 / 审计）
- 在 `skill_registry.tags` 标注 `high-risk-execution` 的技能，在“下单/调整仓位”等关键步骤前 **MUST** 触发 HITL：  
  进入 `paused_hitl`，待审批后恢复；全程审计，状态同步 `agent_strategy_registry.status`。  
- 所有产物 **MUST** 关联 `run_id/config_id/skill_version` 用于追溯与回放。

---

## 9. **简化** Lint 机制（最小可用集）
> 遵循“**足够而简**”原则，先保合规与一致性，后续再扩展。

- **spec‑lint（必选）**  
  - 校验 `spec.md` frontmatter 仅含 `name/description`；  
  - 检查四个固定标题是否存在；  
  - 检出唯一 `Domain Contract`（YAML 块）并做**字段存在性**校验（`domain/contracts/apis/datasets/…`）。
- **skill‑lint（必选）**  
  - 校验 `SKILL.md` frontmatter（two‑fields 规则、kebab‑case ≤64、保留字）；  
  - 校验 `~/.codex/skills.json` 仅三键，`path` 指向有效安装路径。
- **index‑lint（必选）**  
  - 本地已安装技能与 `ais_core.skill_registry` 进行“影子比对”（发现幽灵技能/缺失技能仅**告警**，不阻断）。
- **可选**（关闭默认）  
  - `sql‑lint`（前缀/主键/视图一致性）；  
  - `api‑stub‑lint`（L2 签名与 schema 的深度校验）。  
> 以上三项为**默认唯一启用**的校验；其余均可在需要时临时开启。

---

## 10. 最小落地清单（可立即执行）
1. 为六个域创建 `ais/domain/<d>/spec.md` 与 `Domain Contract` 雏形；  
2. 建立 `ais_core` 与六个数据面 Schema；创建控制面核心表；  
3. 落 `src/<d>/*` 的最小接口存根与 JSON Schema；  
4. 配置解析器接入 `config_store` 并产生快照；  
5. 上线两类作业模板（夜间因子/周度回测）与 Runner；  
6. 搭建“开发版技能→发布版技能”的发布链路（`ais skills publish` → `~/.claude/skills`；重建 `~/.codex/skills.json`；写入 `skill_registry`）。 

---

## 附录 A：Skills 规范要点（与本规范的兼容性）
- **目录命名**：`<role>-<skill>`，kebab‑case ≤64；目录名 MUST 与 frontmatter 的 `name` 一致；主文档 MUST 为大写 `SKILL.md`；UTF‑8。  
- **Frontmatter**：**仅** `name` 与 `description`；  
- **正文结构**：固定四个英文标题（正文可中文书写）；  
- **索引文件**：`~/.codex/skills.json` **仅** `name/description/path`；`path` **必须**为 `~/.claude/skills/<name>/SKILL.md`；  
- **保留字**：`name` **不得**包含 `anthropic`、`claude`。  
> 上述要求来源于既有 Skills 规范；本 Dev‑Spec 的 `spec.md` 外形已与之完全兼容（frontmatter 两键 + 固定四标题 + 固定 YAML 块）。

---

## 附录 B：系统愿景 / 哲学 / 架构原则 / 技术规约 / 演进蓝图

### B.1 愿景（Vision）
- **智能 × 工程解耦**：智能由 Codex（Skills）承载，工程由 L2 稳定 API 持有；相互独立、共同演进。  
- **可复现、可审计、可治理**：任何结果都能追溯到 `skill_version / config_id / run_id`。  
- **域优先**：以 `data/factor/strategy/portfolio/execution/risk` 为一等命名空间统一组织资产。

### B.2 哲学（First Principles）
1) **Black‑box Codex**：不绑定某一实现；以工具/技能清单为唯一协作面。  
2) **No Hardcoding**：配置“文件 + DB 管理 + 快照”；代码与数据分离。  
3) **Publish = Governed**：一切上线动作都在 `ais_core` 留痕并可回滚。  
4) **Prefer Simplicity**：先保合规与稳定，再逐步扩展复杂度（lint/编排/管控）。

### B.3 架构原则
- **稳定三层**（L1/L2/L3）、**域驱动 Schema**、**控制面 SSoT**；  
- **最小可用接口**：L2 只暴露稳定入口；  
- **安全分域**：高风险技能一律 HITL 审批；  
- **幂等与可重放**：每步操作均可基于 `run_id` 重放。

### B.4 技术规约（选摘）
- **命名**  
  - 表：`ais_<domain>.<prefix_object>`；主键含 `asof/ticker` 或域键；  
  - 技能：`<domain>-<verb>-<object>[-qualifier]`；  
  - 配置键：`<domain>.<object>.<attr>`。  
- **日志与审计**：最小字段 `timestamp/step/run_id/config_id/skill_name/skill_version/input_hash/output_ref/status`。  
- **错误约定**：L2 统一返回 `code/message/retryable`；Runner 记录 `error` 与 `logs_uri`。  
- **测试分层**：Schema 测试（字段/约束）、API 合约测试、作业烟测（dry‑run）。

### B.5 演进蓝图（12–18 个月）
1) **事件驱动调度**：在 cron 之外引入事件总线（行情/数据新鲜度）触发作业（Runner 保持兼容）。  
2) **资源弹性**：作业容器化；并发与配额治理；成本可视化到技能与策略。  
3) **配置治理升级**：灰度发布、金丝雀配置、审批流；配置差异的自动对账报告。  
4) **跨域数据契约**：以 `spec.md` 为源自动生成跨域视图与血缘图。  
5) **质量门体系**：因子/策略发布前的自动化质检（如 Alphalens 报告解读技能）接入 CI。  
6) **统一可观测性**：引入 Trace 聚合与成本/失败率仪表，策略与技能双维度剖析。  
7) **生态统一**：在保持 `.claude/skills` 兼容的同时，开放“域规范 → 技能”的自动映射与注册。

---

**（完）**
```