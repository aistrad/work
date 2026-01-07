# LLM CLI 调度系统设计文档（整合版）

## 设计理念

**核心原则**：以 Claude 代码骨架为实现底座，整合 Codex 设计的关键特性。

- 生产者指定 `tool`（claude, codex, gemini），`model` 用于记录
- Worker 按 `(tool, account)` 分组，支持**多账号**
- 只限制并发数，速率限制依赖 API 429 返回
- **产物独立存储**（`task_files` 表）
- **审计追踪**（`task_runs` 表）
- **安全默认**（禁用危险旗标）
- HTTP API **可选**（默认关闭）

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    任务生产者                                   │
│  schedulerctl (必须)  │  HTTP API (可选, 默认关闭)           │
└────────────────────────────┬────────────────────────────────────┘
                             │ 写入任务
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ tasks       │ task_runs      │ task_files            │   │
│  │             │ (审计追踪)      │ (产物存储)            │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ worker_groups: (tool, account) → Worker 组               │   │
│  │   (claude, main)      → group: claude-main              │   │
│  │   (claude, team-a)    → group: claude-team-a            │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │ 按 tool 分配
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Worker Group A (tool=claude, account=main)         │
│  Worker-1  Worker-2  Worker-3                                   │
│  API Key: sk-main                                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Worker Group B (tool=claude, account=team-a)        │
│  Worker-4                                                       │
│  API Key: sk-team-a                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 数据模型（整合版）

```sql
-- ============================================================
-- 任务表
-- ============================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 生产者指定
    tool TEXT NOT NULL CHECK (tool IN ('codex', 'claude', 'gemini')),
    model TEXT,                           -- 可选，仅记录，不影响路由
    prompt TEXT NOT NULL,
    input_files JSONB NOT NULL DEFAULT '[]',
    output_files JSONB NOT NULL DEFAULT '[]',

    -- 调度字段
    tenant_id TEXT NOT NULL DEFAULT 'default',
    queue TEXT NOT NULL DEFAULT 'default',
    priority INT NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 9),
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'leased', 'running', 'succeeded', 'failed', 'canceled')),
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 租约字段
    lease_expires_at TIMESTAMPTZ,
    attempt INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    next_attempt_at TIMESTAMPTZ,

    -- 幂等性
    idempotency_key TEXT UNIQUE NULLS NOT DISTINCT,

    -- 执行结果（摘要）
    result JSONB,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Worker 分组：按 (tool, account) 分组
-- 同一个 tool 可以有多个组（不同账号）
-- ============================================================
CREATE TABLE worker_groups (
    group_name TEXT PRIMARY KEY,         -- "claude-main", "claude-team-a"
    tool TEXT NOT NULL,                  -- "claude", "codex", "gemini"
    account_name TEXT NOT NULL,          -- "main", "team-a", "experiment"

    -- 配置
    max_concurrent INT NOT NULL,
    current_concurrent INT NOT NULL DEFAULT 0,

    -- 环境变量（账号凭证）
    env_vars JSONB NOT NULL DEFAULT '{}',  -- {"API_KEY": "sk-..."}

    UNIQUE(tool, account_name)
);

-- ============================================================
-- 任务执行记录：审计追踪（Codex 命名）
-- ============================================================
CREATE TABLE task_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    attempt INT NOT NULL,

    -- 执行信息
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    status TEXT NOT NULL,
    exit_code INT,

    -- 输出（截断）
    stdout_trunc TEXT,
    stderr TEXT,

    -- 产物摘要
    output_files JSONB,                 -- 产物清单
    tokens_used INT,
    latency_ms INT
);

-- ============================================================
-- 产物文件存储（Codex 设计）
-- ============================================================
CREATE TABLE task_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    path TEXT NOT NULL,
    is_input BOOLEAN NOT NULL,

    -- 内容（小文件直接存）
    content BYTEA,
    size_bytes BIGINT,

    -- 大文件可选（预留）
    storage_url TEXT
);

-- ============================================================
-- 并发限制（简化版：只限制并发）
-- ============================================================
CREATE TABLE concurrency_limits (
    scope TEXT PRIMARY KEY,  -- 'tool:claude', 'model:gpt-4'
    max_concurrent INT NOT NULL,
    current_concurrent INT NOT NULL DEFAULT 0
);

INSERT INTO concurrency_limits (scope, max_concurrent) VALUES
    ('tool:claude', 3),
    ('tool:codex', 5),
    ('tool:gemini', 5);

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX idx_tasks_fetch ON tasks (status, priority DESC, scheduled_at ASC)
WHERE status IN ('queued', 'leased');
CREATE INDEX idx_tasks_lease ON tasks (lease_expires_at)
WHERE status = 'leased';
CREATE INDEX idx_tasks_tenant ON tasks (tenant_id, status);

CREATE INDEX idx_task_runs_task ON task_runs(task_id, attempt);
CREATE INDEX idx_task_files_task ON task_files(task_id, is_input);
```

---

## 代码结构

```
scheduler/
├── README.md
├── Makefile
├── config.yaml
├── pyproject.toml
│
├── scheduler/
│   ├── __init__.py
│   ├── __main__.py
│   │
│   ├── config.py                # 配置加载
│   ├── database.py              # 数据库连接
│   │
│   ├── worker.py                # Worker 主逻辑
│   ├── executor.py              # CLI 执行器（安全默认）
│   │
│   ├── api.py                   # HTTP API（可选，默认关闭）
│   └── cli.py                   # schedulerctl
│
├── agents/                      # Subprocess Wrapper
│   ├── __init__.py
│   ├── base.py
│   ├── codex.py
│   ├── claude.py
│   └── gemini.py
│
├── sql/
│   └── init.sql
│
└── tests/
    └── test_worker.py
```

---

## 配置文件 `config.yaml`

```yaml
# 数据库
database:
  # 与 fortune_ai 数据库使用相同的账号/密码/主机，仅数据库名改为 cli_worker
  # 示例：postgresql://<fortune_ai_user>:<fortune_ai_password>@<fortune_ai_host>/cli_worker
  url: "postgresql://<fortune_ai_user>:<fortune_ai_password>@<fortune_ai_host>/cli_worker"
  pool_size: 10

# Worker 配置
worker:
  group_name: "claude-main"      # 当前 Worker 属于哪个组 (tool-account)
  concurrency: 4                 # 单进程内并发
  heartbeat_interval: 30
  lease_interval: 60
  poll_interval: 1

# 执行配置
execution:
  timeout: 600
  work_dir: "/tmp/scheduler"
  cleanup: true

# 安全配置（重要！）
security:
  allow_dangerous_flags: false   # 默认禁用危险旗标
  enforce_path_whitelist: true    # 强制路径白名单

# API 配置（可选，默认关闭）
api:
  enabled: false                  # 默认关闭
  host: "0.0.0.0"
  port: 8000

# 日志
logging:
  level: "INFO"
  format: "json"
```

---

## Worker 核心逻辑 `scheduler/worker.py`

```python
"""
Scheduler Worker - 整合版
- Worker 按 (tool, account) 分组
- 只拉取本组 tool 的任务
- 同一个 tool 的多个账号 Worker 竞争任务
"""

import asyncio
import asyncpg
import json
import os
import shutil
import signal
import tempfile
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass
import uuid

from .config import Config
from .executor import Executor

log = logging.getLogger(__name__)


@dataclass
class WorkerGroup:
    """Worker 组配置"""
    group_name: str
    tool: str
    account_name: str
    max_concurrent: int
    env_vars: Dict[str, str]


@dataclass
class Task:
    """任务数据类"""
    id: uuid.UUID
    tool: str
    model: Optional[str]
    prompt: str
    input_files: List[Dict[str, str]]
    output_files: List[str]
    attempt: int
    max_attempts: int
    priority: int
    tenant_id: str


class Worker:
    """Worker 进程"""

    def __init__(self, config: Config):
        self.config = config
        self.db_pool = None
        self.executor = None
        self.running = False
        self.worker_id = uuid.uuid4()
        self.group: Optional[WorkerGroup] = None

    async def start(self):
        """启动 Worker"""
        log.info("Starting worker %s (group: %s)",
                self.worker_id, self.config.worker.group_name)

        # 1. 连接数据库
        self.db_pool = await asyncpg.create_pool(self.config.database.url)

        # 2. 注册 Worker
        await self._register_worker()

        # 3. 加载组配置
        self.group = await self._load_group_config()
        log.info("Worker group: %s, tool: %s, account: %s",
                self.group.group_name, self.group.tool, self.group.account_name)

        # 4. 设置环境变量（账号凭证）
        for key, value in self.group.env_vars.items():
            os.environ[key] = value
            log.debug("Set env: %s=***", key)

        # 5. 初始化执行器
        self.executor = Executor(self.config)

        self.running = True

        # 启动工作协程
        workers = [
            asyncio.create_task(self._worker_loop(i))
            for i in range(self.config.worker.concurrency)
        ]

        heartbeat = asyncio.create_task(self._heartbeat_loop())

        # 信号处理
        for sig in (signal.SIGTERM, signal.SIGINT):
            signal.signal(sig, self._signal_handler)

        await asyncio.gather(*workers, heartbeat, return_exceptions=True)

    async def _register_worker(self):
        """注册 Worker 到数据库"""
        async with self.db_pool.acquire() as conn:
            # 检查组是否存在
            group = await conn.fetchrow(
                "SELECT * FROM worker_groups WHERE group_name = $1",
                self.config.worker.group_name
            )

            if not group:
                raise ValueError(f"Worker group not found: {self.config.worker.group_name}")

            # 注册自己
            await conn.execute("""
                INSERT INTO worker_registry (worker_id, group_name, hostname, pid)
                VALUES ($1, $2, $3, $4)
            """, self.worker_id, self.config.worker.group_name,
                os.uname().nodename, os.getpid())

            log.info("Registered worker %s to group %s",
                    self.worker_id, self.config.worker.group_name)

    async def _load_group_config(self) -> WorkerGroup:
        """加载组配置"""
        async with self.db_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT group_name, tool, account_name,
                       max_concurrent, env_vars
                FROM worker_groups
                WHERE group_name = $1
            """, self.config.worker.group_name)

            return WorkerGroup(
                group_name=row['group_name'],
                tool=row['tool'],
                account_name=row['account_name'],
                max_concurrent=row['max_concurrent'],
                env_vars=row['env_vars']
            )

    def _signal_handler(self, sig, frame):
        """信号处理"""
        log.info("Received signal %s, shutting down...", sig)
        self.running = False

    async def _worker_loop(self, worker_idx: int):
        """单个 Worker 协程"""
        log.info("Worker loop %d started", worker_idx)

        while self.running:
            try:
                # 1. 租约抢取 - 只抢取本组 tool 的任务
                task = await self._lease_task()

                if task is None:
                    await asyncio.sleep(self.config.worker.poll_interval)
                    continue

                log.info("Worker %d leased task %s (tool: %s, model: %s, attempt: %d)",
                        worker_idx, task.id, task.tool, task.model, task.attempt)

                # 2. 并发控制（按组）
                permitted = await self._acquire_concurrency()
                if not permitted:
                    await self._release_lease(task.id)
                    await asyncio.sleep(5)
                    continue

                # 3. 执行任务
                await self._execute_task(task)

            except Exception as e:
                log.exception("Worker loop %d error: %s", worker_idx, e)
                await asyncio.sleep(5)

        log.info("Worker loop %d stopped", worker_idx)

    async def _lease_task(self) -> Optional[Task]:
        """租约抢取 - 只抢取本组 tool 的任务"""
        async with self.db_pool.acquire() as conn:
            async with conn.transaction():
                # 关键：只查询本组 tool 的任务
                row = await conn.fetchrow("""
                    SELECT id, tool, model, prompt, input_files, output_files,
                           attempt, max_attempts, priority, tenant_id
                    FROM tasks
                    WHERE ((status = 'queued' AND scheduled_at <= NOW())
                           OR (status = 'leased' AND lease_expires_at < NOW()))
                      AND tool = $1
                      AND (next_attempt_at IS NULL OR next_attempt_at <= NOW())
                    ORDER BY priority DESC, scheduled_at ASC
                    FOR UPDATE SKIP LOCKED
                    LIMIT 1
                """, self.group.tool)

                if row is None:
                    return None

                # 更新租约
                await conn.execute("""
                    UPDATE tasks
                    SET status = 'leased',
                        attempt = attempt + 1,
                        lease_expires_at = NOW() + interval '60 seconds',
                        updated_at = NOW()
                    WHERE id = $1
                """, row['id'])

                return Task(**dict(row))

    async def _acquire_concurrency(self) -> bool:
        """并发控制 - 按组"""
        async with self.db_pool.acquire() as conn:
            async with conn.transaction():
                result = await conn.fetchrow("""
                    UPDATE worker_groups
                    SET current_concurrent = current_concurrent + 1
                    WHERE group_name = $1
                      AND current_concurrent < max_concurrent
                    RETURNING current_concurrent
                """, self.group.group_name)

                return result is not None

    async def _release_concurrency(self):
        """释放并发"""
        async with self.db_pool.acquire() as conn:
            await conn.execute("""
                UPDATE worker_groups
                SET current_concurrent = current_concurrent - 1
                WHERE group_name = $1
            """, self.group.group_name)

    async def _release_lease(self, task_id: uuid.UUID):
        """释放租约"""
        async with self.db_pool.acquire() as conn:
            await conn.execute("""
                UPDATE tasks
                SET status = 'queued',
                    lease_expires_at = NULL
                WHERE id = $1
            """, task_id)

    async def _execute_task(self, task: Task):
        """执行任务"""
        task_id = task.id
        run_id = uuid.uuid4()
        start_time = datetime.now()
        work_dir = None

        try:
            # 1. 创建运行记录（Codex 命名：task_runs）
            async with self.db_pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO task_runs
                    (id, task_id, attempt, started_at, status)
                    VALUES ($1, $2, $3, NOW(), 'running')
                """, run_id, task_id, task.attempt)

            # 2. 更新任务状态
            async with self.db_pool.acquire() as conn:
                await conn.execute("""
                    UPDATE tasks
                    SET status = 'running',
                        started_at = NOW(),
                        lease_expires_at = NOW() + interval '60 seconds'
                    WHERE id = $1
                """, task_id)

            # 3. 准备工作目录
            work_dir = Path(tempfile.mkdtemp(prefix=f"task_{task_id}_"))

            for file_spec in task.input_files:
                file_path = work_dir / file_spec['name']
                file_path.write_text(file_spec['content'])

            # 4. 执行 CLI（安全默认）
            result = await self.executor.run(
                tool=self.group.tool,
                model=task.model,
                prompt=task.prompt,
                work_dir=str(work_dir)
            )

            # 5. 收集输出文件（存入 task_files）
            output_files = []
            for output_name in task.output_files:
                output_path = work_dir / output_name
                if output_path.exists():
                    content = output_path.read_text()
                    output_files.append(output_name)
                    # 存入 task_files 表
                    await self._save_output_file(task_id, output_name, content)

            # 6. 计算耗时
            latency_ms = int((datetime.now() - start_time).total_seconds() * 1000)

            # 7. 更新为成功
            async with self.db_pool.acquire() as conn:
                await conn.execute("""
                    UPDATE tasks
                    SET status = 'succeeded',
                        result = $2,
                        finished_at = NOW()
                    WHERE id = $1
                """, task_id, json.dumps({
                    'files': output_files,
                    'exit_code': result['exit_code']
                }))

                # 更新 task_runs（Codex 命名）
                await conn.execute("""
                    UPDATE task_runs
                    SET finished_at = NOW(),
                        status = 'succeeded',
                        exit_code = $2,
                        stdout_trunc = $3,
                        output_files = $4,
                        latency_ms = $5
                    WHERE id = $1
                """, run_id, result['exit_code'],
                    result.get('stdout', '')[:10000],
                    json.dumps(output_files),
                    latency_ms)

            log.info("Task %s completed successfully", task_id)

        except Exception as e:
            await self._handle_failure(task_id, run_id, str(e))

        finally:
            await self._release_concurrency()

            # 清理工作目录
            if work_dir and self.config.execution.cleanup:
                try:
                    shutil.rmtree(work_dir)
                except:
                    pass

    async def _save_output_file(self, task_id: uuid.UUID, path: str, content: str):
        """保存输出文件到 task_files 表"""
        async with self.db_pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO task_files (task_id, path, is_input, content, size_bytes)
                VALUES ($1, $2, false, $3, $4)
            """, task_id, path, content.encode('utf-8'), len(content))

    async def _handle_failure(self, task_id: uuid.UUID, run_id: uuid.UUID, error_message: str):
        """处理失败"""
        async with self.db_pool.acquire() as conn:
            task = await conn.fetchrow(
                "SELECT attempt, max_attempts FROM tasks WHERE id = $1", task_id)

            retryable = task['attempt'] < task['max_attempts']

            # 检查是否是速率限制
            if '429' in error_message or 'rate' in error_message.lower():
                retryable = True

            if retryable:
                backoff = min(300, 30 * (2 ** task['attempt']))
                await conn.execute("""
                    UPDATE tasks
                    SET status = 'queued',
                        error_message = $2,
                        next_attempt_at = NOW() + interval '%s seconds',
                        updated_at = NOW()
                    WHERE id = $1
                """ % backoff, task_id, error_message)

                await conn.execute("""
                    UPDATE task_runs
                    SET finished_at = NOW(), status = 'failed', stderr = $2
                    WHERE id = $1
                """, run_id, error_message)

                log.warning("Task %s failed (retryable), next attempt in %ds",
                           task_id, backoff)
            else:
                await conn.execute("""
                    UPDATE tasks
                    SET status = 'failed', error_message = $2, finished_at = NOW()
                    WHERE id = $1
                """, task_id, error_message)

                await conn.execute("""
                    UPDATE task_runs
                    SET finished_at = NOW(), status = 'failed', stderr = $2
                    WHERE id = $1
                """, run_id, error_message)

                log.error("Task %s failed permanently: %s", task_id, error_message)

    async def _heartbeat_loop(self):
        """心跳"""
        while self.running:
            try:
                async with self.db_pool.acquire() as conn:
                    # 更新 Worker 心跳
                    await conn.execute("""
                        UPDATE worker_registry
                        SET last_heartbeat = NOW()
                        WHERE worker_id = $1
                    """, self.worker_id)

                    # 续租 running 任务
                    await conn.execute("""
                        UPDATE tasks
                        SET lease_expires_at = NOW() + interval '60 seconds'
                        WHERE status = 'running'
                          AND lease_expires_at < NOW() + interval '30 seconds'
                    """)

                    # 清理过期租约
                    await conn.execute("""
                        UPDATE tasks
                        SET status = 'queued', lease_expires_at = NULL
                        WHERE status = 'leased' AND lease_expires_at < NOW()
                    """)

            except Exception as e:
                log.exception("Heartbeat error: %s", e)

            await asyncio.sleep(self.config.worker.heartbeat_interval)

    async def stop(self):
        """停止 Worker"""
        self.running = False

        if self.db_pool:
            async with self.db_pool.acquire() as conn:
                await conn.execute(
                    "DELETE FROM worker_registry WHERE worker_id = $1",
                    self.worker_id
                )

            await self.db_pool.close()


async def main():
    config = Config.load()
    logging.basicConfig(
        level=getattr(logging, config.logging.level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    worker = Worker(config)
    try:
        await worker.start()
    except KeyboardInterrupt:
        await worker.stop()


if __name__ == '__main__':
    asyncio.run(main())
```

---

## 执行器 `scheduler/executor.py`（安全默认）

```python
"""
CLI 执行器 - 安全默认
- 默认禁用危险旗标
- 只在配置允许时启用
"""

import asyncio
from pathlib import Path
from typing import Dict, Any
import logging

from .config import Config

log = logging.getLogger(__name__)


class Executor:
    """CLI 执行器"""

    def __init__(self, config: Config):
        self.config = config

    async def run(self, tool: str, model: Optional[str], prompt: str, work_dir: str) -> Dict[str, Any]:
        """执行 CLI 工具"""
        log.info("Executing %s with model=%s", tool, model)

        if tool == 'codex':
            return await self._run_codex(model, prompt, work_dir)
        elif tool == 'claude':
            return await self._run_claude(model, prompt, work_dir)
        elif tool == 'gemini':
            return await self._run_gemini(model, prompt, work_dir)
        else:
            raise ValueError(f"Unknown tool: {tool}")

    async def _run_codex(self, model: Optional[str], prompt: str, work_dir: str) -> Dict:
        """执行 Codex CLI"""
        cmd = [
            "codex", "exec",
            "-a", "never",
            "--sandbox", "workspace-write",
        ]

        if model:
            cmd.extend(["-m", model])

        cmd.append(prompt)

        return await self._execute_subprocess(cmd, work_dir)

    async def _run_claude(self, model: Optional[str], prompt: str, work_dir: str) -> Dict:
        """执行 Claude CLI - 安全默认"""
        cmd = ["claude", "-p"]

        # 默认不使用危险旗标
        if model:
            cmd.extend(["--model", model])

        cmd.append(prompt)

        return await self._execute_subprocess(cmd, work_dir)

    async def _run_gemini(self, model: Optional[str], prompt: str, work_dir: str) -> Dict:
        """执行 Gemini CLI"""
        cmd = ["gemini", prompt, "-y", "--sandbox"]

        return await self._execute_subprocess(cmd, work_dir)

    async def _execute_subprocess(self, cmd: list, work_dir: str) -> Dict:
        """执行子进程"""
        log.debug("Executing: %s in %s", ' '.join(cmd), work_dir)

        import os
        process = await asyncio.create_subprocess_exec(
            *cmd,
            cwd=work_dir,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=os.environ.copy()
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=self.config.execution.timeout
        )

        return {
            'exit_code': process.returncode,
            'stdout': stdout.decode('utf-8', errors='replace'),
            'stderr': stderr.decode('utf-8', errors='replace'),
        }
```

---

## HTTP API `scheduler/api.py`（可选，默认关闭）

```python
"""
HTTP API - 可选组件
- 默认关闭
- 通过配置 api.enabled 启用
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
import asyncpg
from datetime import datetime
import uuid
import logging

from .config import Config

log = logging.getLogger(__name__)

# 全局开关
_api_enabled = False
app = FastAPI(title="Scheduler API")


class TaskRequest(BaseModel):
    """统一 TaskSpec"""
    tool: str = Field(..., description="工具: claude, codex, gemini")
    model: Optional[str] = Field(None, description="模型名称（可选）")
    prompt: str = Field(..., description="任务提示词")
    input_files: List[Dict[str, str]] = Field(default_factory=list)
    output_files: List[str] = Field(default_factory=list)
    tenant_id: str = Field(default="default")
    priority: int = Field(default=5, ge=1, le=9)
    idempotency_key: Optional[str] = None


class TaskResponse(BaseModel):
    task_id: uuid.UUID
    status: str


@app.post("/tasks", response_model=TaskResponse)
async def create_task(req: TaskRequest):
    """创建任务"""
    if not _api_enabled:
        raise HTTPException(status_code=503, detail="API is disabled")

    conn = await app.state.db_pool.acquire()

    try:
        async with conn.transaction():
            # 检查幂等性
            if req.idempotency_key:
                existing = await conn.fetchrow(
                    "SELECT id, status FROM tasks WHERE idempotency_key = $1",
                    req.idempotency_key
                )
                if existing:
                    return TaskResponse(task_id=existing['id'], status=existing['status'])

            # 插入任务
            task_id = uuid.uuid4()
            await conn.execute("""
                INSERT INTO tasks (id, tool, model, prompt, input_files, output_files,
                                   tenant_id, priority, idempotency_key)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            """, task_id, req.tool, req.model, req.prompt, req.input_files,
                req.output_files, req.tenant_id, req.priority, req.idempotency_key)

            return TaskResponse(task_id=task_id, status="queued")

    finally:
        app.state.db_pool.release(conn)


@app.get("/health")
async def health():
    """健康检查"""
    return {"status": "ok", "api_enabled": _api_enabled}


@app.on_event("startup")
async def startup():
    global _api_enabled
    config = Config.load()
    _api_enabled = getattr(config.api, 'enabled', False)

    if _api_enabled:
        app.state.db_pool = await asyncpg.create_pool(config.database.url)


@app.on_event("shutdown")
async def shutdown():
    await app.state.db_pool.close()


if __name__ == "__main__":
    import uvicorn
    config = Config.load()
    if getattr(config.api, 'enabled', False):
        uvicorn.run(app, host=config.api.host, port=config.api.port)
    else:
        log.warning("API is disabled")
```

---

## Makefile

```makefile
.PHONY: help migrate run-worker run-api test lint clean

help:
	@echo "Available commands:"
	@echo "  make migrate       - 初始化数据库"
	@echo "  make run-worker    - 启动 Worker (指定 GROUP_NAME)"
	@echo "  make run-api       - 启动 HTTP API (需配置开启)"
	@echo "  make test          - 运行测试"
	@echo "  make lint          - 代码检查"

migrate:
	psql -h localhost -U postgres -d scheduler -f sql/init.sql

run-worker:
	@if [ -z "$(GROUP_NAME)" ]; then \
		echo "Error: GROUP_NAME not set"; \
		echo "Usage: make run-worker GROUP_NAME=claude-main"; \
		exit 1; \
	fi
	GROUP_NAME=$(GROUP_NAME) python -m scheduler.worker

run-api:
	python -m scheduler.api

test:
	pytest tests/

lint:
	ruff check scheduler/ agents/
	black --check scheduler/ agents/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
```

---

## 使用示例

```bash
# 1. 初始化数据库
make migrate

# 2. 启动 Worker（不同账号）
make run-worker GROUP_NAME=claude-main
make run-worker GROUP_NAME=claude-team-a

# 3. 创建任务（使用 CLI）
schedulerctl enqueue claude "Refactor this code" --model claude-3-5
schedulerctl enqueue codex "Write tests"

# 4. 查看状态
schedulerctl list
schedulerctl get <task-id>

# 5. HTTP API（需要先在 config.yaml 中开启）
# 然后执行:
# make run-api
```

---

## 整合方案要点

| 特性 | 说明 |
|------|------|
| **数据模型** | `task_runs`（审计）、`task_files`（产物） |
| **多账号** | Worker 按 `(tool, account)` 分组 |
| **安全默认** | 默认禁用危险旗标 |
| **并发控制** | 只限制并发，速率依赖 429 |
| **HTTP API** | 可选，默认关闭 |
| **CLI** | 必选，永远可用 |

---

## 待实现模块

- `scheduler/config.py` - 配置加载
- `scheduler/database.py` - 数据库连接
- `pyproject.toml` - 依赖定义
