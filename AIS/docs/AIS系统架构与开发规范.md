# AIS架构与开发规范

**— 唯一完整参照文件（.md）**

> 本规范定义 AIS 在 **Codex 为唯一 agentic 中枢** 前提下的整体工程与治理约束：域（Data/Factor/Strategy/Portfolio/Execution/Risk）按 **domain‑first** 组织；L2 稳定 API；“配置文件 + 数据库（管理配置）”；Skills 作为唯一对外能力接口；固定流程由 **crontab + 数据库** 执行。Skill 的格式、命名、索引与路径严格兼容《Codex Skills Specification & Template》。 

---

## 0. 目标、范围与原则

**目标**

* 以 *domain‑first* 与 *stable‑stack*（L1 引擎 / L2 稳定 API / L3 Skills）实现“研究与交互由 Codex 驱动，固定任务由 crontab + DB 执行”；全链路可复现、可审计、可演进。
* 以 **单一契约文件 `spec.md`** 约束每个功能域对用户与 Codex 的协作；`spec.md` **完全兼容 Skill 规范的文档结构**，并在其中固化 `DOMAIN.yaml` 片段作为域契约的**固定部分**。

**范围**

* 仓库结构、命名规范、域契约（`spec.md`）、L2 API 约定、配置合成与快照、数据库（域驱动 Schema + 治理中枢）、Skills 放置与发布、调度/作业、HITL 风险治理、CI/Lint/生成器。

**核心原则（MUST）**

1. **Codex 唯一 agentic 中枢**：研究/交互/编排全部经由 Codex 调用 Skills；我们不关心 Codex 内部实现。
2. **Skills 仅调用 L2 API**：严禁 Skills 直连引擎或数据库；一切易变集成封装在 L2。
3. **配置文件 + 数据库（管理配置）**：任何路径/阈值/权重不得硬编码；运行前合成“Resolved Config”并固化快照。
4. **DB 为治理与运行态的唯一真源（SSOT）**：注册中心、配置激活、作业、运行与审计写入 DB；大对象存储用文件/对象存储，仅在 DB 存引用与校验。
5. **固定流程自动化**：通过 crontab 唤起 Job‑Runner，读取 DB 计划并执行（Skill 或 L2）；高风险步骤强制 HITL。
6. **Skill 规范兼容**：命名、`SKILL.md` 结构、索引文件 `~/.codex/skills.json` 与安装路径 `~/.claude/skills/<name>/SKILL.md` 完全遵循规范。

---

## 1. 仓库与命名（Domain‑First）

```
ais/
  domain/
    data/
      spec.md            # ★ 域规范（兼容 Skill 文档结构，内含 DOMAIN.yaml 固定片段）
      src/               # 该域 L2 稳定 API（唯一可被 Skills 调用）
      configs/           # 该域默认与环境化配置（YAML/JSON）
      db/                # 该域 DDL/迁移/视图（对应 ais_data）
      jobs/              # 该域作业模板（渲染至 cron_jobs）
      schemas/           # I/O schema（JSON Schema）
      tests/             # 合约/数据/流程测试
      docs/              # 该域人读文档
    factor/ ...（同上）
    strategy/ ...
    portfolio/ ...
    execution/ ...
    risk/ ...
  gov/
    db/                  # ais_gov（skill_registry / agent_strategy_registry / config_registry / cron_* / trading_calendar）
    docs/
  scheduler/
    job_runner.py        # 读取 ais_gov.cron_job 并执行（skill 或 l2）
  skills/                # 源码形态的技能（发布到 ~/.claude/skills）
    factor-value/
      SKILL.md
      scripts/
      references/
      assets/
  artifacts/             # 产物归档（分域）
```

**命名（MUST）**

* **域目录名**：`data/factor/strategy/portfolio/execution/risk`。
* **L2 API 导入前缀**：`ais.domain.<domain>.src.<module>`。
* **技能名**：`<domain>-<capability>[-<mode>][-<scope>]`，kebab‑case，≤64，遵循 Skill 规范保留字与正则限制。

---

## 2. `spec.md`（域规范，兼容 Skill 文档结构）

每个域根目录下 **必须存在** `spec.md`，其文档结构与章节标题 **完全复用 Skill 规范**，以便将来纳入 Skill 体系或被 Codex 统一加载：`Overview and Intent`、`Quick Start`、`Workflows / Function / Inputs / Outputs`、`Scripts / Reference / Best Practices / Integration Points`。文首 Frontmatter 仅包含 `name` 与 `description` 两键（与 SKILL.md 相同语义），例如：

```markdown
---
name: domain-factor
description: 因子域：定义 L2 能力、数据契约、配置与作业模板的唯一协作规范；对外暴露 compute 等稳定 API。
---
```

> **说明**：`name` 与 `description` 的校验、文档章节标题等要求与 Skill 规范一致，从而实现**完全兼容**；域规范不会出现在 `~/.codex/skills.json`（仅技能出现），但其格式与校验规则可复用同一套 Lint。

### 2.1 固定部分：`DOMAIN.yaml`（内嵌于 `spec.md`）

在 `spec.md` 的 **“Scripts / Reference / …”** 章节最后，**必须**内嵌一个 `DOMAIN.yaml` 代码块作为**固定部分**，是 Codex/Runner/CI 的机器可读契约源。示例（节选）：

```yaml
# DOMAIN.yaml（固定部分）
domain: factor
version: 1.2.0
owners: [ "alice.pm", "bob.qpm" ]

db:
  schema: ais_factor
  tables:
    - name: f_value_daily
      pk: [asof, ticker]
      retention: "P5Y"
    - name: f_momentum_daily
      pk: [asof, ticker]
      retention: "P5Y"

api:
  modules:
    - name: factor.compute
      import: ais.domain.factor.src.compute
      inputs_schema: schemas/compute.in.json
      outputs_schema: schemas/compute.out.json
      side_effects: [ "ais_factor.f_value_daily" ]

configs:
  defaults: configs/defaults.yml
  env_overlays:
    prod:  configs/env/prod.yml
    stage: configs/env/stage.yml

skills_allowed:
  version_range: ">=1.0.0 <3.0.0"
  families:
    - "factor-compute-*"
    - "factor-quality-*"
  default_tags: [ "domain:factor", "no-execution" ]

scheduler:
  templates:
    - jobs/nightly_factor.yml

governance:
  hitl_tags: []
  metrics_slo:
    latency_p95_ms: 30000
    error_rate: "<1%"

compatibility:
  change_policy: "semver-major requires deprecation window"
```

**CI 要求（MUST）**

* `api.modules[*].import` 能在仓库解析到实际 L2 模块；
* `db.tables[*].name` 在该域 `db/` 的迁移中存在；
* `skills_allowed.families` 能被本地技能索引匹配（见 §5）；
* `scheduler.templates[*]` 渲染后通过 cron 语法校验并可写入 `ais_gov.cron_job`。

> 该约束将 **域规范 → 代码/表/配置/作业** 绑定为一个可审计的契约闭环。

---

## 3. L2 稳定 API（对 Skills 的唯一入口）

**规则（MUST）**

* L2 API 仅暴露在 `ais/domain/<domain>/src`；函数与 I/O **由 `spec.md` 的 `DOMAIN.yaml.api.modules` 声明**；
* Skills **只能**调用 L2 API；严禁绕过 L2 直触引擎或数据库；
* I/O Schema 放在 `schemas/*.json`，以 JSON Schema 校验；
* L2 记录 `run_id / config_id / skill_version / codex_trace_id` 等最小审计字段。

**命名示例**

* `ais.domain.data.src.ingest`、`ais.domain.factor.src.compute`、`ais.domain.strategy.src.run`、`ais.domain.portfolio.src.optimizer`、`ais.domain.execution.src.policy`、`ais.domain.risk.src.manager`。

---

## 4. 配置体系（文件 + DB 管理 + 快照）

**合成顺序（MUST）**：`defaults → env（prod/stage/dev） → DOMAIN.yaml 指示的激活配置（DB） → 运行覆写` ⇒ **Resolved Config**。
**快照（MUST）**：每次运行固化 `Resolved Config` 至 `ais_gov.run_config_snapshot`，并将 `config_id` 写入产物表与日志，确保可复现。

---

## 5. Skills 放置与发布（兼容 Codex / Claude Code）

**运行时放置（MUST）**

* 技能安装路径：`~/.claude/skills/<name>/SKILL.md`；
* 索引文件：`~/.codex/skills.json`，仅含 `name/description/path` 三键，`path` 指向上述安装路径。

**仓库与发布**

* 源码形态：`ais/skills/<name>/SKILL.md`（受 Git 管理）；
* 发布动作：`ais skills sync` 将技能同步/链接到 `~/.claude/skills` 并更新 `~/.codex/skills.json`；
* 权威注册：安装后在 `ais_gov.skill_registry` 记录 `name/version/owner/tags/allowed_tools/dependencies/metrics`。 

**命名（MUST）**

* `name`：kebab‑case，≤64，仅小写字母/数字/连字符；禁止保留字 `anthropic`、`claude`。
* 组织语法：`<domain>-<capability>[-<mode>][-<scope>]`（如 `factor-compute-value`、`strategy-run-backtest`）。

---

## 6. 数据库规范（Domain‑Driven Schema + 治理中枢）

**命名空间（MUST）**

* 域：`ais_data / ais_factor / ais_strategy / ais_portfolio / ais_execution / ais_risk`；
* 治理中枢：`ais_gov`（注册/配置/作业/运行/交易日历）。

**键与幂等（MUST）**

* 事实表统一键：`asof`、`ticker`（或 `strategy_id` 等域键）+ `run_id / config_id`；
* 大对象：仅存外部 `blob_uri` 与 `sha256` 校验。

**示例 DDL（节选）**

```sql
-- 因子域
create schema if not exists ais_factor;
create table if not exists ais_factor.f_value_daily (
  asof date not null,
  ticker text not null,
  value_score double precision not null,
  run_id uuid not null,
  config_id uuid not null,
  primary key (asof, ticker)
);

-- 策略运行
create schema if not exists ais_strategy;
create table if not exists ais_strategy.run_equity (
  run_id uuid primary key,
  strategy_id uuid not null,
  start_date date not null,
  end_date date not null,
  equity_curve jsonb not null,
  config_id uuid not null
);

-- 治理中枢
create schema if not exists ais_gov;

create table if not exists ais_gov.skill_registry (
  skill_id uuid primary key,
  name varchar(64) unique not null,
  description text not null,
  version varchar(20) not null,
  owner_user_id uuid not null,
  status text not null check (status in ('beta','production','deprecated','archived')),
  dependencies jsonb not null default '[]',
  tags jsonb not null default '[]',
  allowed_tools jsonb not null default '[]',
  metadata_metrics jsonb not null default '{}'
);

create table if not exists ais_gov.agent_strategy_registry (
  strategy_id uuid primary key,
  strategy_name text not null,
  owner_pm_id uuid not null,
  graph_definition jsonb not null,
  linked_skill_versions jsonb not null,
  status text not null check (status in ('running','paused_hitl','error','stopped')),
  current_pnl numeric,
  current_drawdown numeric
);

create table if not exists ais_gov.config_registry (
  config_id uuid primary key,
  scope text not null check (scope in ('global','domain','skill','strategy')),
  scope_ref text not null,
  version integer not null,
  payload jsonb not null,
  status text not null check (status in ('draft','approved','active')),
  changelog text
);

create table if not exists ais_gov.run_config_snapshot (
  snapshot_id uuid primary key,
  config_id uuid not null,
  resolved_payload jsonb not null,
  created_at timestamptz default now()
);

create table if not exists ais_gov.cron_job (
  job_id uuid primary key,
  name text unique not null,
  schedule_spec text not null,
  tz text not null,
  trading_calendar text,
  executor text not null check (executor in ('skill','l2')),
  target_ref text not null,
  payload jsonb not null default '{}',
  constraints_json jsonb not null default '{}',
  enabled boolean not null default true
);

create table if not exists ais_gov.cron_run (
  run_id uuid primary key,
  job_id uuid not null,
  scheduled_at timestamptz not null,
  started_at timestamptz,
  ended_at timestamptz,
  status text not null check (status in ('queued','running','success','failed','paused_hitl')),
  error text,
  logs_uri text,
  config_snapshot_id uuid,
  artifact_refs jsonb not null default '[]',
  codex_trace_id text,
  cost_metrics jsonb not null default '{}'
);
```

---

## 7. 调度与自动化（crontab + DB + Runner）

**机制（MUST）**

* crontab 仅唤起 `job_runner.py`；Runner 读取 `ais_gov.cron_job` 并根据 `executor` 调用 **Skill（非交互）** 或 **L2 API**；
* 交易日历与时区：字段 `tz/trading_calendar` 控制非交易日偏移；
* 并发与重试：`constraints_json` 支持 `max_running=1`、重试退避、依赖；
* **HITL**：若目标技能在 `skill_registry.tags` 含 `high-risk-execution`，Runner 在关键步骤前强制进入 `paused_hitl`，并联动 `agent_strategy_registry.status`。

**作业模板（域内 `jobs/` → 渲染至 DB）**

```yaml
# ais/domain/factor/jobs/nightly_factor.yml
name: nightly_factor_value
executor: skill
skill: factor-compute-value@1.4.2
schedule_spec: "0 2 * * 1-5"
tz: "America/New_York"
trading_calendar: "XNYS"
payload:
  universe: "us_largecap"
  asof: "{{trade_date}}"
config_ref: "factor.value.us@13"
constraints_json:
  max_running: 1
  retry:
    max_attempts: 3
    backoff_seconds: 120
```

**典型作业（建议）**

* **F‑DAILY**：因子日更（Skill 执行）；
* **S‑WEEKLY**：策略周度回测/纸上仿真（Skill 或 L2）；
* **P‑MONTHLY**：组合月度再平衡（Skill，`high-risk-execution` ⇒ HITL）。

---

## 8. 风险与治理（HITL / 标签 / 追溯）

**标签治理（MUST）**

* 在 `ais_gov.skill_registry.tags` 标注风险标签（如 `high-risk-execution`）；Runner 据此强制 HITL 中断；
* 所有运行写 `codex_trace_id / run_id / config_id / skill_version` 到运行表；
* CIO 仪表板可基于 `cron_run` 与策略注册表实时查看队列与风险事件（实现依赖 UI，不属本规范）。

---

## 9. CI、Lint 与生成器

**Lint（MUST）**

* **spec‑lint**：校验 `spec.md` 结构与 Frontmatter（沿用 Skill 规范的检查器）。
* **domain‑contract‑lint**：解析 `DOMAIN.yaml` 与 `db/`、`src/`、`jobs/` 一致性；
* **skill‑lint**：`SKILL.md` frontmatter 与路径、命名、正文四段标题；`~/.codex/skills.json` 三键校验与路径正则。
* **config‑lint**：配置合成顺序、必填键、禁止硬编码路径/阈值（规则库）；
* **sql‑lint**：域前缀/Schema 与主键/索引规范。

**生成器（SHOULD）**

* `ais domain init <domain>`：生成域骨架与 `spec.md` 模板；
* `ais jobs render <domain>`：将 `jobs/*.yml` 渲染入 `ais_gov.cron_job`；
* `ais skills sync`：同步技能至 `~/.claude/skills` 并更新 `~/.codex/skills.json`。

---

## 10. 参考样例

### 10.1 `ais/domain/factor/spec.md`（简化示例）

````markdown
---
name: domain-factor
description: 因子域：对外暴露 compute 等稳定 API，统一数据与作业契约；仅通过 L2 与底层引擎/DB 交互。
---

# Overview and Intent
- 为 B/T/V/M 等因子的计算、质检与落库提供稳定能力边界与审计闭环（API/表/配置/作业）。
- Skills 仅通过本域 L2 API（如 `factor.compute`）访问因子能力，不可直连 DB/引擎。:contentReference[oaicite:27]{index=27}

# Quick Start
- 使用方式（Codex）：让 Codex 选择 `factor-compute-*` 技能，技能再调用 `ais.domain.factor.src.compute`。
- 本域配置：读取 `configs/` 与 `ais_gov.config_registry` 合成 Resolved Config，运行时固化快照。:contentReference[oaicite:28]{index=28}

# Workflows / Function / Inputs / Outputs
- Function：计算并写入 `ais_factor.f_value_daily`、`f_momentum_daily` 等表；导出指标与产物引用。
- Inputs：`universe`、`asof` 等（详见 `schemas/compute.in.json`）。
- Outputs：`factor_frame_ref`、落库记录（`asof/ticker/run_id/config_id`）。  
- 关键校验：对齐交易日历，避免缺失行；幂等以 `asof/ticker` + `run_id` 保证。

# Scripts / Reference / Best Practices / Integration Points
- Integration：禁止在 Skills 内访问 DB；白名单工具仅限 `l2.factor.compute` 与 `l2.data.fetch`。
- Best Practices：日志字段最小集 `timestamp/step/input_hash/output_ref/side_effects/status`。:contentReference[oaicite:29]{index=29}

```yaml
# DOMAIN.yaml（固定部分）
domain: factor
version: 1.2.0
owners: [ "alice.pm", "bob.qpm" ]

db:
  schema: ais_factor
  tables:
    - name: f_value_daily
      pk: [asof, ticker]
      retention: "P5Y"

api:
  modules:
    - name: factor.compute
      import: ais.domain.factor.src.compute
      inputs_schema: schemas/compute.in.json
      outputs_schema: schemas/compute.out.json
      side_effects: [ "ais_factor.f_value_daily" ]

configs:
  defaults: configs/defaults.yml
  env_overlays:
    prod:  configs/env/prod.yml
    stage: configs/env/stage.yml

skills_allowed:
  version_range: ">=1.0.0 <3.0.0"
  families: [ "factor-compute-*" ]
  default_tags: [ "domain:factor", "no-execution" ]

scheduler:
  templates:
    - jobs/nightly_factor.yml

governance:
  hitl_tags: []
  metrics_slo:
    latency_p95_ms: 30000
    error_rate: "<1%"
````

```

---

## 11. 运行职责边界总结

- **Codex**：唯一 agentic 中枢，负责意图识别、计划、选择与调用 Skills、长流程协作与 HITL。  
- **Skills（L3）**：只做“做什么”，以 `SKILL.md` 驱动；调用 L2，不关心“怎么做”；与 `~/.codex/skills.json` 索引及安装路径约定兼容。:contentReference[oaicite:30]{index=30}  
- **L2（域内 `src/`）**：封装引擎/DB/外部系统，提供稳定协定；记录审计字段。  
- **DB**：域事实（`ais_<domain>`）与治理（`ais_gov`）的唯一真源；配置/作业/运行/注册中心均在此落地。:contentReference[oaicite:31]{index=31}  
- **调度（Runner）**：crontab 触发、DB 取计划、执行 Skill/L2、强制 HITL、写运行与产物。:contentReference[oaicite:32]{index=32}

---

## 12. 附：命名/正则与路径约束（与 Skill 规范一致）

- **技能名/索引**：  
  - `name`：`^(?!.*anthropic)(?!.*claude)[a-z0-9-]{1,64}$`  
  - `~/.codex/skills.json` 仅含三键，`path` 必为 `~/.claude/skills/<name>/SKILL.md`。:contentReference[oaicite:33]{index=33}
- **域规范 `spec.md`**：Frontmatter 仅 `name/description`；四个英文标题固定；`DOMAIN.yaml` 作为固定代码块出现。  

---

### 结语

本规范把“域 → 契约（`spec.md` + `DOMAIN.yaml`）→ L2 API → 配置 → DB → Skills → 调度/治理”的全链路统一为**一套可审计、可复现、可演进**的工程与协作规则；既满足 Codex 作为唯一 agentic 中枢的要求，又与 Skill 规范完全兼容，支持未来将域规范纳入统一的技能生态。:contentReference[oaicite:34]{index=34} :contentReference[oaicite:35]{index=35}

> **实现建议**：按此文直接创建六个域的 `spec.md` 骨架与 `DOMAIN.yaml` 固定部分；落库 `ais_gov`；实现 `ais skills sync` 与作业渲染；接入 CI 的四类 Lint 后，即可在 **dev‑spec** 模式下并行推进功能域开发与治理。
```
