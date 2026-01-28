---
name: vibe-manus
description: |
  大任务并行处理框架。
  使用 Planning with Files + Subagent 模式处理超出 context 窗口的任务。
  触发词：vibe-manus, 大任务, 并行处理, 断点续传, manus
---

# vibe-manus - 大任务并行处理框架

## 概述

vibe-manus 是一个通用的大任务处理框架，解决 Claude Code 在处理大文件或复杂任务时 context 窗口溢出的问题。

**核心原理**：
1. **Planning with Files**: 用文件作为"外部记忆"，持久化中间状态
2. **Subagent 并行**: 每个 chunk 由独立 subagent 处理，有独立 context
3. **断点续传**: 支持 /compact 后或新会话继续未完成任务

```
┌─────────────────────────────────────────────────────────────────┐
│  vibe-manus 架构                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  主 Agent (协调者)                                              │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Phase 1: 准备                                             │ │
│  │ • 分析任务，创建 work_state.json                          │ │
│  │ • 分割任务为多个 chunks                                   │ │
│  │ • 检查断点续传状态                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│       │                                                         │
│       │ Task tool (并行启动)                                    │
│       ▼                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │Subagent │  │Subagent │  │Subagent │  │Subagent │           │
│  │Chunk 1  │  │Chunk 2  │  │Chunk 3  │  │Chunk 4  │           │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘           │
│       │            │            │            │                  │
│       └────────────┴────────────┴────────────┘                  │
│                         │                                       │
│                         ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              work_state.json (外部记忆)                   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                         │                                       │
│                         ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Phase 3: 汇总                                             │ │
│  │ • 读取 partial_results，合并、去重、验证                  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 适用场景

| 场景 | 示例 | 触发条件 |
|------|------|---------|
| 知识抽取 | 大文件分段抽取 Cases/Scenarios | 文件 > 100KB |
| 代码重构 | 大规模代码修改 | 涉及 > 20 个文件 |
| 批量处理 | 多文件批量转换/分析 | > 10 个独立单元 |
| 长流程任务 | 需要多轮交互的复杂任务 | 预估 tokens > 30K |

---

## 使用方式

### 自动触发

当检测到以下情况时，Claude 会建议使用 vibe-manus：
- 文件大小 > 100KB
- 预估 tokens > 30K
- 任务需要处理 > 10 个独立单元

### 手动触发

```
/vibe-manus <task_description>
```

示例：
```
/vibe-manus 抽取《东方代码启示录》中的所有案例
/vibe-manus 重构 apps/api/services/ 下的所有服务类
/vibe-manus 批量转换 /data/docs/ 下的所有 PDF 文件
```

---

## 三阶段流程

### Phase 1: 准备 (主 Agent)

**目标**：分析任务，创建工作状态文件

```
1.1 分析任务
    • 确定任务类型 (extraction | refactor | batch | custom)
    • 识别源文件/目录
    • 计算 MD5 哈希

1.2 检查断点续传
    • 检查 work_state.json 是否存在
    • 如果存在且 MD5 匹配 → 继续未完成的 chunks
    • 如果不存在或 MD5 不匹配 → 创建新的 work_state

1.3 分割任务
    • 按章节/文件/逻辑单元分割
    • 每个 chunk 控制在 ~20K tokens 以内
    • 记录到 work_state.chunks

1.4 分配 chunks
    • 将 chunks 分成 N 批（默认 4 批）
    • 每批分配给一个 subagent
```

**Phase 1 输出检查点**：
```
☐ 任务类型: [extraction|refactor|batch|custom]
☐ 源文件/目录: [path]
☐ MD5: [hash]
☐ 断点续传: [是/否]
☐ 总 chunks 数: [N]
☐ 分配方案: Subagent A: chunks 1-8, Subagent B: chunks 9-16, ...
☐ work_state.json 已创建: [是]
```

### Phase 2: 并行执行与监控 (Subagents) ★

**目标**：每个 subagent 独立处理分配的 chunks，使用 TaskOutput 监控状态

#### 2.1 启动 Subagents (后台模式)

```
for chunk in pending_chunks:
    result = Task(
        description=f"处理 chunk {chunk.index}",
        prompt=SUBAGENT_PROMPT,
        subagent_type="general-purpose",
        run_in_background=true,   // ✅ 后台运行
        max_turns=50              // ✅ 限制最大轮次
    )

    // ✅ 保存 task_id 到 work_state (关键!)
    chunk.task_id = result.task_id
    chunk.status = "in_progress"
    chunk.started_at = now()
    save_work_state()
```

#### 2.2 监控循环 (使用 TaskOutput) ★

```
while has_running_chunks:
    for chunk in chunks where status == "in_progress":

        // ✅ 使用 TaskOutput 非阻塞检查状态
        result = TaskOutput(
            task_id=chunk.task_id,
            block=false,           // 非阻塞
            timeout=5000           // 5秒超时
        )

        if result.status == "completed":
            chunk.status = "done"
            chunk.agent_id = result.agent_id  // ✅ 保存用于恢复
            chunk.completed_at = now()

        elif result.status == "failed":
            handle_failure(chunk)

        elif result.status == "running":
            // 检查是否超时
            if now() - chunk.started_at > config.timeout_seconds:
                chunk.status = "timeout"
                handle_timeout(chunk)

        chunk.last_checked = now()
        save_work_state()

    display_progress()
    sleep(config.check_interval)
```

#### 2.3 超时和失败处理

```
def handle_failure(chunk):
    if chunk.retry_count < config.max_retries and chunk.agent_id:
        // ✅ 使用 resume 恢复之前的 subagent
        result = Task(
            resume=chunk.agent_id,
            prompt="继续处理，上次可能因错误中断"
        )
        chunk.task_id = result.task_id
        chunk.status = "in_progress"
        chunk.retry_count += 1
    else:
        chunk.status = "failed"

def handle_timeout(chunk):
    if chunk.retry_count < config.max_retries:
        // 重新启动新的 subagent
        result = Task(...)
        chunk.task_id = result.task_id
        chunk.status = "in_progress"
        chunk.started_at = now()
        chunk.retry_count += 1
    else:
        chunk.status = "failed"
```

#### 2.4 Subagent 执行流程

```
for each chunk in assigned_chunks:
    a. 读取 chunk 内容 (Read tool)
    b. 执行处理逻辑 (根据 task_type)
    c. 将结果追加到 work_state.partial_results
    d. 更新 chunk.status = "done"
    e. 保存 work_state.json (原子写入)
```

**Subagent 关键原则**：
- 每处理完一个 chunk 立即写入文件
- 不在 context 中累积大量内容
- 独立运行，不依赖其他 subagent

### Phase 3: 汇总 (主 Agent)

**目标**：合并结果，执行后处理

```
3.1 等待所有 subagents 完成
    • 监控循环检测到所有 chunks 状态为 done/failed
    • 检查 work_state.stats

3.2 读取 partial_results
    • 从 work_state.json 读取所有 subagent 的结果

3.3 合并与去重
    • 按 task_type 执行相应的合并逻辑
    • 去除重复项
    • 验证数据完整性

3.4 后处理
    • 执行 task_type 特定的后处理
    • 如：Cases 评分、Scenarios 发布等

3.5 保存最终结果
    • 更新 work_state.final_result
    • 更新 work_state.status = "completed"
```

**Phase 3 输出检查点**：
```
☐ 所有 subagents 完成: [是]
☐ 成功 chunks: [N]
☐ 失败 chunks: [M]
☐ 超时 chunks: [K]
☐ 合并结果数: [X]
☐ 去重后结果数: [Y]
☐ 最终结果已保存: [是]
☐ work_state.status: completed
```

---

## 工作状态文件

### 位置

```
{task_dir}/work_state.json

示例:
/data/vibelife/knowledge/bazi/extracted/work_state.json
/tmp/vibe-manus/refactor_20260114/work_state.json
```

### 结构 (增强版 - 支持 TaskOutput 监控)

```json
{
  "task_id": "extract_东方代码启示录_20260114_143052",
  "task_type": "extraction",
  "task_description": "抽取《东方代码启示录》中的所有案例",
  "created_at": "2026-01-14T14:30:52",
  "updated_at": "2026-01-14T14:35:00",
  "status": "in_progress",

  "source": {
    "type": "file",
    "path": "/data/vibelife/knowledge/bazi/converted/东方代码启示录.converted.md",
    "md5": "00cfad303f90ae12f59aed6344742497",
    "size_bytes": 552370
  },

  "config": {
    "max_chunks_per_agent": 8,
    "num_agents": 4,
    "chunk_strategy": "by_section",
    "max_turns": 50,            // ✅ 新增: subagent 最大轮次
    "check_interval": 30,       // ✅ 新增: 监控检查间隔(秒)
    "timeout_seconds": 300,     // ✅ 新增: 单个 chunk 超时(秒)
    "max_retries": 2            // ✅ 新增: 最大重试次数
  },

  "chunks": [
    {
      "index": 0,
      "name": "前言",
      "range": {"start_line": 1, "end_line": 299},
      "status": "done",         // pending | in_progress | done | timeout | failed
      "task_id": "abc123",      // ✅ 新增: Task tool 返回的 ID (用于 TaskOutput 监控)
      "agent_id": "af91d55",    // ✅ 更新: 用于 resume 恢复的 agent ID
      "started_at": "2026-01-14T14:31:00",
      "completed_at": "2026-01-14T14:31:30",
      "last_checked": "2026-01-14T14:31:25",  // ✅ 新增: 上次检查时间
      "retry_count": 0          // ✅ 新增: 重试次数
    },
    {
      "index": 1,
      "name": "第一章",
      "range": {"start_line": 300, "end_line": 529},
      "status": "in_progress",
      "task_id": "def456",
      "agent_id": null,
      "started_at": "2026-01-14T14:31:35",
      "retry_count": 0
    },
    {
      "index": 2,
      "name": "第二章",
      "range": {"start_line": 530, "end_line": 862},
      "status": "pending",
      "task_id": null,
      "agent_id": null,
      "retry_count": 0
    }
  ],

  "partial_results": {
    "cases": [
      {
        "location_id": "东方代码启示录.converted.md:第八章:0",
        "name": "伤官配印案例",
        "extracted_by": "subagent_A",
        "extracted_at": "2026-01-14T14:32:00",
        "data": {}
      }
    ],
    "scenarios": []
  },

  "final_result": null,

  "stats": {
    "total_chunks": 31,
    "completed_chunks": 2,
    "failed_chunks": 0,
    "pending_chunks": 29,
    "in_progress_chunks": 1,    // ✅ 新增
    "timeout_chunks": 0,        // ✅ 新增
    "total_cases_found": 1,
    "total_scenarios_found": 0
  },

  "errors": []
}
```

### 状态流转

```
pending → in_progress → done
              ↓
           timeout → in_progress (重试)
              ↓           ↓
           failed ←───────┘ (超过 max_retries)
```

---

## 断点续传

### 检测逻辑

```python
def check_resume(work_state_path, source_path):
    if not exists(work_state_path):
        return "new"  # 新任务

    work_state = load(work_state_path)
    current_md5 = calculate_md5(source_path)

    if work_state["source"]["md5"] != current_md5:
        return "new"  # 源文件变化，重新开始

    if work_state["status"] == "completed":
        return "completed"  # 已完成

    pending_chunks = [c for c in work_state["chunks"] if c["status"] != "done"]
    if pending_chunks:
        return "resume"  # 继续未完成的 chunks

    return "completed"
```

### 触发场景

| 场景 | 行为 |
|------|------|
| /compact 后继续 | 检测到 work_state，继续未完成 chunks |
| 新会话继续 | 检测到 work_state 且 MD5 匹配，继续 |
| 源文件变化 | MD5 不匹配，创建新 work_state，全量重新处理 |
| 部分 chunk 失败 | 只重试 status="failed" 的 chunks |

### 断点续传命令

```
# 继续上次未完成的任务
/vibe-manus --resume

# 强制重新开始
/vibe-manus --force-restart
```

---

## 任务类型

### extraction (知识抽取)

```yaml
task_type: extraction
chunk_strategy: by_section  # 按章节分割
partial_results:
  cases: []      # 抽取的案例
  scenarios: []  # 抽取的场景
post_process:
  - deduplicate_by_location_id
  - calculate_quality_score
  - sync_to_database
```

### refactor (代码重构)

```yaml
task_type: refactor
chunk_strategy: by_file  # 按文件分割
partial_results:
  changes: []    # 代码变更
  errors: []     # 编译/类型错误
post_process:
  - apply_changes
  - run_tests
  - format_code
```

### batch (批量处理)

```yaml
task_type: batch
chunk_strategy: by_item  # 按项目分割
partial_results:
  processed: []  # 已处理项
  skipped: []    # 跳过项
post_process:
  - generate_report
  - cleanup_temp_files
```

---

## Subagent 配置

### 默认配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| num_agents | 4 | 并行 subagent 数量 |
| max_chunks_per_agent | 8 | 每个 agent 最多处理的 chunks |
| subagent_type | general-purpose | Task tool 的 subagent_type |
| run_in_background | false | 是否后台运行 |

### 自定义配置

```
/vibe-manus --agents 2 --chunks-per-agent 16 <task>
```

---

## 错误处理

### Chunk 级错误

```json
{
  "index": 5,
  "status": "failed",
  "error": {
    "type": "ReadError",
    "message": "File not found",
    "at": "2026-01-14T14:33:00"
  }
}
```

### 任务级错误

```json
{
  "status": "failed",
  "errors": [
    {
      "phase": "phase_2",
      "agent_id": "B",
      "type": "AgentTimeout",
      "message": "Subagent B timed out after 10 minutes"
    }
  ]
}
```

### 恢复策略

1. **自动重试**: 失败的 chunk 自动重试 1 次
2. **手动重试**: `/vibe-manus --retry-failed`
3. **跳过失败**: `/vibe-manus --skip-failed`

---

## 最佳实践

### 1. 合理分割 chunks

- 每个 chunk 控制在 ~20K tokens
- 按逻辑边界分割（章节、文件、函数）
- 避免跨 chunk 依赖

### 2. 及时写入文件

- 每处理完一个 chunk 立即写入
- 使用原子写入避免数据损坏
- 不在 context 中累积大量内容

### 3. 利用断点续传

- 大任务分多次执行
- 遇到问题时 /compact 后继续
- 保留 work_state.json 直到任务完成

### 4. 监控进度

```bash
# 查看任务进度
cat work_state.json | jq '.stats'

# 查看失败的 chunks
cat work_state.json | jq '.chunks[] | select(.status == "failed")'
```

---

## 与其他 Skills 集成

### vibelife-skill 集成

在 vibelife-skill 的 Stage 4 (统一抽取) 中，当检测到大文件时自动调用 vibe-manus：

```
if file_size > 100KB or estimated_tokens > 30K:
    use vibe-manus for extraction
else:
    use standard extraction
```

### vibe-review 集成

在 vibe-review 处理大规模代码审查时：

```
if files_count > 20:
    use vibe-manus for parallel review
```

---

## 模板文件

| 模板 | 位置 | 用途 |
|------|------|------|
| WORK_STATE.json | templates/WORK_STATE.json | 工作状态文件模板 |
| SUBAGENT_PROMPT.md | templates/SUBAGENT_PROMPT.md | Subagent prompt 模板 |
