# AIS 域边界与规范一致性审计（问题与修复计划）

日期：2025-11-14  
范围：基于最新版 `.claude/specs/ais/spec.md / requirements.md / design.md` 的严格对照复核

## 背景与目标
- 原则：以“业务域边界先于实现”为最高约束（data / factor / strategy / execution / core），SSoT=DB；生产只允许通过 data 域 L2 访问源数据；各域仅写自身 schema；禁用 `ais_temp.*`。
- 目标：列出当前仓库不符合项，给出分批（P0→P1→P2）修复方案、验收口径与 CI 门禁，确保策略/因子/作业可审计、可回放、可治理。

---

## 发现的问题（按域与层次）

### 1) Data 域与执行路径
- 生产路径未强制通过 data 域 PG 后端（存在 CSV 适配器旁路）
  - 证据：`ais/domain/data/src/l2.py:29-39,42-52,55-61` 允许未设置 `DB_DSN/PG*` 时走 CSV。
  - 影响：生产可能绕过 DB 读数，违背 SSoT 与“唯一入口”原则。
- 回测脚本允许无 DB 环境运行生产区间
  - 证据：`scripts/run_sb2_report.py` 默认不强制 DB 环境。

### 2) 域名 schema 与映射
- Execution 契约仍指向 `ais_temp.*`
  - 证据：`ais/domain/execution/spec.md:19-21` 仍是 `ais_temp.order/execution_log`。
- 风险自由利率 datasets 与实现存在描述差异
  - 证据：`ais/domain/data/spec.md` 写 `t_bill_1m -> aiscend.public.tbill_1m`；实现默认使用 `SHV`（PG）或 `BIL`（CSV）。

### 3) 控制面/产物 SSoT（DB）未完全收敛
- 运行配置快照、审计、作业运行仍落文件
  - 证据：
    - `ais/domain/common/config.py:71-82` → `storage/run_config_snapshot.jsonl`
    - `ais/domain/common/audit.py:11` → `logs/audit.jsonl`
    - `tools/job_sync.py:25` → `storage/db/aiscend/core/job_schedule.jsonl`
    - `tools/obs_aggregate.py:31` → `storage/db/aiscend/core/job_run.jsonl`
- 因子/策略存在文件回退写入（生产不应允许）
  - 证据：`ais/domain/factor/src/sb2_bands.py:129-154`、`ais/domain/factor/src/rolling_vol.py:84-107`、`ais/domain/strategy/src/sb2.py:210-250`。

### 4) 策略口径（后备资产=Rf）
- SB2 组合收益未纳入 Rf（空仓资金）
  - 证据：`ais/domain/strategy/src/sb2.py:150-206` 仅计算 Σw·r − cost。

### 5) 契约/CI 硬门槛与一致性
- 契约校验未做 I/O Schema 的存在与字段一致性校验
  - 证据：`tools/contract_check.py` 仅校端点可导入。
- 未实现 L2 出口注册与变更审计
  - 规范：REQ‑011；当前缺少 `l2_registry` 报告。
- 生产未禁 CSV 适配器
  - 证据：`ais/domain/data/src/l2.py` 存在 fallback；CI 未拦截。

### 6) 可靠性与安全
- L2 未实现“≤3 次指数退避”（仅统一异常）
  - 证据：`ais/domain/common/l2.py:146-159`。
- HITL token 缺 TTL/作用域校验
  - 证据：`ais/domain/execution/src/hitl.py:33` 仅长度判定。

### 7) 文档与注释残留
- 旧版 `ais_temp` 文档仍在，注释仍提及 ais_temp
  - 证据：`.claude/specs/ais/ais requirement full temp.md:*`、`ais/domain/strategy/src/run.py:21` 注释、`storage/ci/contract_report.json` 历史产物。

### 9) 跨域协作与权限边界未完全固化
- 问题：非 data 域可能（或将来可能）直接访问 `aiscend.public.*` 或他域内部表；规范要求跨域仅通过“域契约”（L2/API 或对外产品化只读数据集）。
- 影响：破坏域边界与独立演进；增加破坏性变更风险；审计与权限复杂度增加。
- 证据：当前代码已基本通过 L2 访问，但 CI/权限未设置硬门槛，仍存在旁路可能（需增加检测与收口）。

### 8) Skills 机制未完整落地
- 现状：索引与校验已接入（`~/.codex/skills.json` 三键校验），但发布/注册/运行器缺失；未将技能注册治理落库（`aiscend.core.skill_registry`）。
- 影响：技能的治理与可审计性不足，生态流程不闭环。

---

## 修复计划（分批）

### P0（生产门禁与策略口径，立即项）
1. 生产必须经 data 域 PG 后端
   - 变更：
     - `scripts/run_sb2_report.py` 在生产参数（时窗≥1年或 `--prod`）下，检测 `DB_DSN|PG*`，缺失则 fail；打印原因。
     - `scripts/ci_check.py` 新增门禁：当检测到“生产跑数”却使用 CSV 适配器→fail。
   - 验收：生产回测时，未设 DB → 退出非零；设 DB → 通过并记录 DB 源。
2. SB2 纳入 Rf 收益（后备资产=SHV 近似）
   - 变更：`ais/domain/strategy/src/sb2.py` 组合收益改为 `Σ w_j*r_j + (1-Σw)*rf_t - cost`；报告新增 `uses_rf_in_return=true` 与 `avg_cash_weight`。
   - 验收：报告包含新字段；结果可复算；CI 断言字段存在。
3. Execution 契约映射修正
   - 变更：`ais/domain/execution/spec.md:19-21` 改为 `aiscend.execution.order/execution_log`。
   - 验收：`contract_check` 通过；`mapping_check` 无告警。
4. 跨域协作与权限边界（第一步）
   - 变更：在 CI 增加“跨域裸表访问”静态扫描：非 data 域出现 `SELECT aiscend.public.*` 或 `SELECT aiscend.<other_domain>.*` → fail；
   - 验收：CI 报告“跨域裸表=0”；策略/因子/执行所有 DB 访问均通过 data L2 或对外产品化只读数据集。
5. AIS 业务执行模式（Biz‑Exec）触发与边界（文档与门禁）
   - 变更：
     - 在 `~/.codex/AGENTS.md` 增加 `ais` 触发词说明与“仅技能执行”的强约束；
     - 在 `.claude/specs/ais/spec.md` 增加 5.4 “Biz‑Exec”小节（命名前缀 `ais-`、代码/数据/配置边界、预告与确认）；
   - 验收：会话命中 `ais` 时仅选择 `ais-` 前缀技能；若用户尝试绕过技能执行，系统输出拒绝与引导。

### P1（SSoT DB 化与契约一致性，短期）
1. 控制面与作业写 DB
   - 变更：新增 `aiscend.core.{run_config_snapshot,audit_log,events,job_schedule,job_run}`；
     - L2 装饰器：快照写 DB，产物审计写 `core.audit_log`；
     - `job_sync.py / obs_aggregate.py` 改为写 `core.job_*`。
   - 验收：文件落地改为可选 dev 模式；CI 断言生产禁止文件路径。
2. 因子/策略产物生产禁止文件回退
   - 变更：依据 `AIS_MODE=prod` 强制 DB；移除回退或在 prod 下禁用。
   - 验收：CI 在 prod 模式扫描代码路径，无文件写入分支。
3. 契约/Schema 强校验与 L2 出口注册
   - 变更：`contract_check.py` 校验 `input_schema/output_schema` 存在且字段一致；新增 `tools/l2_registry.py` 生成 `l2_registry.json` 并输出 diff/事件。
   - 验收：CI 输出字段 diff=0；变更报告包含 `added/removed`。
4. Data 域 Rf 逻辑澄清
   - 变更：在 `ais/domain/data/spec.md` 将 `t_bill_1m` 逻辑集说明为“默认用 SHV ETF 近似”，或新增 `risk_free_1m` 逻辑名，明确候选与披露字段。
5. 跨域协作与权限边界（第二步）
   - 变更：
     - 在 `aiscend.data.*` 发布 `price_daily_curated/risk_free_1m` 对外只读视图（或物化视图），并在 data 契约 datasets 声明；
     - DB 权限收口：仅 data 服务账号可 SELECT `public.*`；其他域仅可 SELECT `aiscend.data.*` 的对外产品化视图；
   - 验收：运行用户权限检查通过；跨域 SQL 静态扫描=0；契约与 `sql/mapping.sql` 双向一致。
6. AIS 技能命名规范门禁
   - 变更：在技能索引与发布流程中检查 AIS 技能 `name` 前缀为 `ais-`；
   - 验收：`skills.index.validate` 报告中所有 `ais` 场景技能命名符合规范；不合规索引被拒绝。

### P2（可靠性/安全与文档收敛，中期）
1. L2 指数退避重试（≤3 次，带幂等键 `run_id`）
   - 变更：`ais/domain/common/l2.py` 捕获 `retryable=True` 的异常，指数退避 3 次；保留缓存命中。
2. HITL token TTL/作用域
   - 变更：`ais/domain/execution/src/hitl.py` 增加 `issued_at/ttl/scopes`；`policy.py` 校验过期与作用域。
3. 统一持久层
   - 变更：为各域增加 Repository（或统一 Core 层），集中 DB 写入策略/审计/幂等；各域仅调用自身 Repository。
4. 文档与历史产物收敛
   - 变更：将 `*.temp.*` 文档迁移 `_archive/` 并在 `spec.md` 顶部声明“以新版为准”；清理旧注释与历史 JSON。
5. Skills 发布与注册
   - 变更：实现 `ais skills publish`（或等效）将开发版同步到运行路径并重建索引；将技能元数据落库 `aiscend.core.skill_registry` 并联动 CI 校验；提供最小 Runner/Invoker。

---

## 验收口径（CI Gates）
- Gate‑1 生产路径门禁：未设 DB → fail；检测到 CSV 适配器 → fail。
- Gate‑2 Rf 口径：报告 `uses_rf_in_return=true` 且 `risk_free.source='SHV'`。
- Gate‑3 映射一致：`sql/mapping.sql` 无 `ais_temp.*` 且 execution 契约改为域名 schema。
- Gate‑4 SSoT：`core.*` 表存在且装饰器/作业写 DB；生产模式无文件写入。
- Gate‑5 契约/Schema：端点可导入、Schema 文件存在且字段一致；`l2_registry` 变更报告生成。
- Gate‑6 可靠性/安全：L2 退避重试覆盖率≥X%；HITL token 验证通过（时间窗与作用域）。

---

## 附：证据定位（便于复核）
- Data L2 双通道：`ais/domain/data/src/l2.py:29-39,42-52,55-61`
- SB2 未纳入 Rf：`ais/domain/strategy/src/sb2.py:150-206`
- 因子/策略文件回退：`ais/domain/factor/src/sb2_bands.py:129-154`、`ais/domain/factor/src/rolling_vol.py:84-107`、`ais/domain/strategy/src/sb2.py:210-250`
- Execution 契约旧映射：`ais/domain/execution/spec.md:19-21`
- 快照/审计/作业写文件：`ais/domain/common/config.py:71-82`、`ais/domain/common/audit.py:11`、`tools/job_sync.py:25`、`tools/obs_aggregate.py:31`
- 旧文档：`.claude/specs/ais/ais requirement full temp.md:1-86`

> 注：上述修复全部在“域边界清晰、SSoT=DB”的前提下实施；生产环境严格禁用文件适配器与 `ais_temp.*`，并通过 CI 门禁保证不可回退到不合规路径。
