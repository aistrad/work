# Codex 调度层设计（最终版｜简化整合）

本版本基于现有 Codex/Claude 两份设计的差异对比与整合意见，采纳“Claude 代码骨架 + Codex 的关键治理点（产物与审计、账号并发）”的思路，并按最新评审进一步简化：默认只做并发控制，不实现速率窗；保留 tenant_id 字段但不实现租户轮询；HTTP API 可选且默认关闭；Prometheus 指标延后，先以结构化日志满足可观测性。

---

## 1. 设计结论（TL;DR）
- 入口：仅 `schedulerctl`（直连 DB）；HTTP API 提供可选开关，默认关闭以降低攻击面与依赖。
- 调度：PostgreSQL 队列 + Worker；只做“并发控制”，速率限制依赖供应商 429 并做退避重试。
- 多租户：`tenant_id` 字段保留用于筛选，不实现配额与加权轮询（按需再加）。
- 账号：引入 `accounts` 与并发计数按账号维度，支持同一 tool 多账号并行；账号由 Worker 分组或自动发现。
- 产物与审计：采纳 `task_runs`（含产物摘要）+ `task_files`（小文件存储）；stdout/stderr 截断入库。
- 安全：危险旗标默认禁用（尤其 Claude），强制临时工作区 + 临时 HOME + 路径白名单 + rlimits；后续可加 cgroups。

---

## 2. 采用/不采用一览
- 采用
  - Claude 的 Worker/Executor/CLI 骨架与错误分类（timeout/429/auth/unknown）。
  - Codex 的 `task_runs`/`task_files` 数据面与“按账号并发”治理（concurrency_limits）。
  - 统一 TaskSpec（tool, model, prompt, input_files, output_spec, idempotency_key）。
- 不采用（首版暂缓）
  - 速率窗/令牌桶（以 429 退避代替）。
  - 多租户加权轮询与配额。
  - 强制暴露 HTTP/API 与 Prometheus 指标（保留开关与占位）。

---

## 3. 数据模型（最简可用｜修订）

```sql
-- 任务表（保留核心字段）
CREATE TABLE tasks (
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    tenant_id TEXT DEFAULT 'default',
    tool TEXT NOT NULL CHECK (tool IN ('codex','claude','gemini')),
    model TEXT,                                         -- 预留字段（生产者可填，当前执行层可忽略）
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','leased','running','succeeded','failed','canceled','deadletter')),
    priority INT DEFAULT 5 CHECK (priority BETWEEN 1 AND 9),
    prompt TEXT,
    input_files JSONB DEFAULT '[]',                     -- 小文件入库（< 1MiB）
    output_spec JSONB DEFAULT '[]',                     -- 产物收集配置（文件相对路径列表）
    idempotency_key TEXT UNIQUE NULLS NOT DISTINCT,
    attempt INT NOT NULL DEFAULT 0,                     -- 重试计数（用于退避与死信判断）
    leased_by TEXT REFERENCES accounts(id),             -- 当前租约归属账号（便于审计与并发释放）
    lease_expires_at TIMESTAMPTZ,                       -- 租约到期时间（心跳续租）
    next_attempt_at TIMESTAMPTZ,                        -- 下一次尝试时间（指数退避后设置）
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 运行记录（合并产物摘要，减少 JOIN）
CREATE TABLE task_runs (
    id UUID PRIMARY KEY,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    attempt INT,
    status TEXT,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    exit_code INT,
    stdout TEXT,
    stderr TEXT,
    output_files JSONB,     -- 产物摘要清单（文件名数组或路径→元数据）
    tokens_used INT,
    latency_ms INT
);

-- 文件存储（小文件直接存；大文件后续接入外部存储）
CREATE TABLE task_files (
    id UUID PRIMARY KEY,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    path TEXT,
    is_input BOOLEAN,
    content BYTEA,
    size_bytes BIGINT
);

-- 合并 accounts 与 worker_groups：按账号维度管理并发，并携带运行所需环境
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,                              -- 账号/组唯一标识，推荐与 group_name 同名
    group_name TEXT UNIQUE NOT NULL,                  -- Worker 启动时使用的组名（兼容 Claude 的 GROUP_NAME）
    tool TEXT NOT NULL CHECK (tool IN ('codex','claude','gemini')),
    name TEXT,
    env_vars JSONB NOT NULL DEFAULT '{}',             -- 运行所需环境（如 XDG_CONFIG_HOME、API KEY 引用等）
    cred_ref TEXT,                                    -- 可选：凭证引用/路径（若不走 env_vars）
    enabled BOOLEAN DEFAULT TRUE,
    max_concurrency INT NOT NULL,
    dangerous BOOLEAN DEFAULT FALSE                   -- 是否允许危险旗标（仅受控环境）
);

CREATE TABLE concurrency_limits (
    scope TEXT PRIMARY KEY,           -- 统一为 'account:<id>'（不再使用 tool:*）
    max_concurrent INT NOT NULL,
    current_concurrent INT NOT NULL DEFAULT 0
);
```

索引建议（与 Claude 版保持一致 + 保留 deadletter｜对齐新增字段）：
- `CREATE INDEX idx_tasks_fetch ON tasks (status, priority DESC, created_at ASC) WHERE status IN ('queued','leased');`
- `CREATE INDEX idx_tasks_lease ON tasks (lease_expires_at) WHERE status='leased';`
- `CREATE INDEX idx_tasks_tenant ON tasks (tenant_id, status);`

---

## 4. Worker 策略（简化）
- 抢占：`SELECT ... FOR UPDATE SKIP LOCKED` 取 `queued`/过期 `leased`；置 `leased`、`leased_by=<account>`、`lease_expires_at=now()+ttl` 与 `attempt+=1`。
- 账号与并发：
  - Worker 以 (tool, account) 分组启动，或启动时“自动发现启用的 accounts”作为候选；
  - 申请并发许可：`UPDATE concurrency_limits SET current_concurrent=current_concurrent+1 WHERE scope='account:<id>' AND current_concurrent < max_concurrent RETURNING 1;` 未取到则让出任务（回退 `queued` 并短睡/抖动）。
- 执行：
  - 临时工作区 + 临时 HOME；只读挂载 `cred_path` 或注入环境变量；
  - Codex：`codex exec -a never --sandbox workspace-write [-m <model>]`；
  - Claude：默认 `claude -p`（不加危险旗标）；若 `account.dangerous=true` 且受控容器，再加 `--dangerously-skip-permissions --no-session-persistence`；
  - 心跳：30–45s 续租；超时 TERM→KILL；
  - 输出：按 `output_spec` 收集文件，写 `task_runs.output_files` 摘要与必要小文件到 `task_files`。
- 失败分类与退避：
  - 429/网络/5xx → retryable，指数退避 `min(300, 30 * 2^attempt)`；
  - 4xx/鉴权/权限 → fatal，直接 `failed`；
  - 超过 `max_attempts` → `deadletter`。
- 释放：完成或失败后将 `current_concurrent` 减 1，清理临时工作区。

---

## 5. 安全默认（必须）
- 命令白名单：仅允许固定子命令与旗标；拒绝任意命令直传。
- 路径白名单与相对路径校验：拒绝绝对路径与 `..`；
- 资源限额：每任务软/硬超时 + `RLIMIT_CPU/AS/NOFILE`；`nice` 降优先级；
- Claude 危险旗标默认禁用；仅 `accounts.dangerous=true` 且“受控容器+只读凭证目录”双条件满足时开启；执行前记录一条“预告日志”（影响范围+幂等策略）。

---

## 6. 统一 TaskSpec（接口统一）
- 字段：`tool`、`model`、`prompt`、`input_files`（[{name,content}]）、`output_spec`（[path]）、`idempotency_key`、`priority`、`tenant_id`（可选）。
- 说明：`model` 为保留字段，当前执行器不基于该字段做路由或速率控制；未来可按需启用。
- 入队途径：默认 CLI（schedulerctl enqueue）；HTTP API 作为可选模块（编译/启动开关）。

---

## 7. 评审建议采纳情况（与 Claude 版差异对齐）

| 建议 | 结论 | 说明 |
|------|------|------|
| 接入方式默认关闭 HTTP | 采纳 | CLI 足够，API 作为可选开关 |
| 限速仅并发控制 | 采纳 | 统一仅并发；scope 统一为 `account:<id>` |
| 多租户轮询暂缓 | 采纳 | 保留字段，后续再加配额/轮询 |
| task_files/task_runs | 采纳 | 必须，有审计与产物结构 |
| Claude 骨架 | 采纳 | 作为实现底座，补充安全与产物 |
| 安全默认（禁危险旗标） | 采纳 | 仅白名单账号 + 受控容器启用 |
| 统一 TaskSpec | 采纳 | 统一字段：`output_files` 用于结果摘要；保留 `output_spec` 作为收集配置 |
| 指标落地可暂缓 | 采纳 | 先日志，指标按需加 |
| API 编译/启动开关 | 采纳 | 默认关闭 |

---

## 8. MVP 实施清单（1–2 周）
- D1：建表（tasks/task_runs/task_files/accounts/concurrency_limits）与索引；落地 schedulerctl enqueue/get/ls/cancel/requeue。
- D2：Worker/Executor（基于 Claude 骨架）+ 并发许可 + 退避重试；临时工作区与安全默认；小文件产物回填。
- D3：accounts 命令（add/ls/enable/disable/set-limits）；stdout/stderr 截断；结构化日志。
- D4：混沌测试（429/超时/网络异常）；文档与示例；可选开启 HTTP API（默认关）。

---

## 9. 关键 SQL 片段（并发控制与退避；并发按账号 scope 统一）

```sql
-- 抢占任务
SELECT * FROM tasks
WHERE (
  (status='queued' AND (now() >= created_at) AND (next_attempt_at IS NULL OR next_attempt_at <= now()))
  OR (status='leased' AND lease_expires_at < now())
) AND tool = $1
ORDER BY priority DESC, created_at ASC
FOR UPDATE SKIP LOCKED
LIMIT 1;

-- 获取并发许可（按账号 'account:<id>'）
UPDATE concurrency_limits
SET current_concurrent = current_concurrent + 1
WHERE scope = $1 AND current_concurrent < max_concurrent
RETURNING 1;

-- 释放并发许可
UPDATE concurrency_limits
SET current_concurrent = current_concurrent - 1
WHERE scope = $1;

-- 429/限流退避（应用层计算秒数 backoff）
UPDATE tasks
SET status='queued', next_attempt_at = now() + ($1 || ' seconds')::interval
WHERE id = $2;
```

---

## 10. 运行与配置（对齐两版差异）
- `schedulerctl worker start --tools codex,claude --processes 4`（或 `--accounts auto` 从 DB 发现启用账号；也可使用 `group_name` 直接指定）。
- 配置：`db.url`、`lease.ttl=90s`、`heartbeat=30s`、`max_attempts=3`、`backoff_base=30s`、`work_dir=/tmp/scheduler-work/`、`inline_threshold=1MiB`。
- 数据库：名称固定为 `cli_worker`；账号/密码/主机与 `fortune_ai` 数据库保持一致（仅库名不同）。
- 安全：默认不启用任何危险旗标；Claude 账号需显式 `dangerous=true` 才可开启，并校验运行环境是受控容器。
- 并发 scope：统一为 `account:<id>`；不再使用 `tool:*` 计数，便于同一 tool 多账号并行。


### 10.1 Worker 与管理命令（CLI-only）
- `schedulerctl accounts add --id codex-main --tool codex --group-name codex-main --max 4 --env XDG_CONFIG_HOME=/secrets/codex`
- `schedulerctl accounts enable/disable <id>`、`schedulerctl accounts set-limits <id> --max N`
- `schedulerctl enqueue --tool codex --prompt @prompt.txt --output-spec results.txt`
- `schedulerctl tasks ls/get <id> [--with-files]`、`schedulerctl tasks requeue/cancel <id>`
- `schedulerctl worker start --accounts auto --processes 4`（或 `--accounts codex-main,claude-a,claude-b`）
- `schedulerctl worker status` 查看活跃进程与并发占用；`schedulerctl worker stop` 优雅停止。


### 10.2 本地开发与测试（SQLite 兼容层）
- 本仓库默认提供 SQLite 适配器以便在无 PostgreSQL 的环境下运行单元测试：
  - JSONB 字段以 TEXT 存储（存/取时做 JSON 序列化）。
  - `FOR UPDATE SKIP LOCKED` 用“尝试更新标记 + 随机退避”近似模拟。
  - 正式部署务必使用 PostgreSQL，并启用上述索引。
