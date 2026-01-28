# vibelife-skill 优化计划 - 文件优先策略

## 核心策略

**原则**: 用文件操作替代内存操作，及时 compact/clear，避免 context 膨胀

---

## 1. 问题诊断

### 1.1 已解决 vs 待优化

| 问题点 | 原因 | 状态 |
|--------|------|------|
| Subagent 返回值膨胀 | 15-20KB JSON 返回到 Main context | ✓ 已解决 |
| work_state.json 膨胀 | partial_results 累积完整对象 | ✓ 已解决 |
| 汇总阶段全量加载 | Phase 4-6 同时持有所有数据 | ✓ 已解决 |
| **Subagent 内部 context** | **阅读长 chunk 后 context 累积** | **🔴 核心问题** |
| TaskOutput 输出膨胀 | 非阻塞读取返回大量数据 | 🟡 需优化 |

### 1.2 已完成优化效果

```
优化前:
  Main Agent context: 150KB+
  work_state.json: 21KB+ (持续增长)
  Subagent 返回值: 15-20KB JSON

优化后:
  Main Agent context: <20KB
  work_state.json: <5KB (固定)
  Subagent 返回值: ~50 字符状态
```

### 1.3 核心问题: Subagent 内部 context 膨胀

**根因分析**:
```
当前流程:
  Read(chunk, 0-5000行) → 存入 context (~20K tokens)
  识别 case1 → context 继续增长
  识别 case2 → context 继续增长
  ...
  识别 caseN → context 超限或卡住
```

**问题严重性**:
- 单个 chunk 可能有 10-50K tokens
- Subagent 没有 compact 能力
- 导致部分 subagent 卡住或超时

---

## 2. 解决方案: 文件优先策略

### 2.1 核心改进: Subagent 分段阅读 + 即时写入

**解决 Subagent 内部 context 膨胀的关键**: 分段阅读，即时写入，不累积

```
优化后流程:
  Read(chunk, 0-500行) → 识别 case1 → 立即写入文件 → 清空变量
  Read(chunk, 500-1000行) → 识别 case2 → 立即写入文件 → 清空变量
  ...
  返回简短摘要
```

**实现细节**:

1. **分段阅读** (每段 ~300-500行):
   ```
   Subagent 不一次性读取整个 chunk
   使用 Read(file, offset=N, limit=500) 分段读取
   ```

2. **即时写入** (识别一个，写入一个):
   ```
   识别到 case → 立即 Write(cases/chunkX_caseY.json)
   不在 context 中保留完整 case 对象
   ```

3. **增量状态更新**:
   ```
   每处理完一段，更新 work_state.json 的进度
   记录 current_offset，支持断点续传
   ```

### 2.2 监控优化: Bash 检查状态文件

```bash
# 轻量级状态检查，不污染 Main context
python3 -c "
import json
d = json.load(open('work_state.json'))
done = sum(1 for c in d['chunks'] if c['status']=='done')
print(f'Progress: {done}/{len(d[\"chunks\"])} chunks done')
"
```

### 2.3 清理策略: 移动到 archive/

```
Phase 6 完成后:
  mv extracted/cases/* archive/cases_{timestamp}/
  mv extracted/scenarios/* archive/scenarios_{timestamp}/
  保留 extraction_records.json 和 work_state.json
```

### 2.4 数据结构增强

**work_state.json 增加进度追踪**:
```json
{
  "chunks": [
    {
      "index": 0,
      "status": "in_progress",
      "current_offset": 500,    // 新增: 当前阅读位置
      "total_lines": 2000,      // 新增: chunk 总行数
      "processed_cases": 2,     // 新增: 已处理 case 数
      "processed_scenarios": 1  // 新增: 已处理 scenario 数
    }
  ],
  "result_refs": { "cases": [], "scenarios": [] }
}
```

**目录结构**:
```
extracted/
├── work_state.json
├── cases/
│   ├── chunk0_case001.json
│   └── ...
├── scenarios/
│   └── ...
├── archive/              # 新增: 归档目录
│   ├── cases_20260115/
│   └── scenarios_20260115/
└── extraction_records.json
```

---

## 3. SKILL.md 修改清单

| 文件位置 | 修改内容 | 优先级 |
|----------|----------|--------|
| `.claude/skills/vibelife-skill/SKILL.md` L296-344 | **Subagent Prompt: 增加分段阅读指令** | 🔴 P0 |
| `.claude/skills/vibelife-skill/SKILL.md` L380-400 | **监控循环: 改用 Bash 检查文件状态** | 🟡 P1 |
| `.claude/skills/vibelife-skill/SKILL.md` L237-270 | **work_state.json: 增加 current_offset 追踪** | 🟡 P1 |
| `.claude/skills/vibelife-skill/SKILL.md` L597-627 | **Phase 6: 增加归档逻辑** | 🟢 P2 |

### 关键修改 1: Subagent Prompt (P0)

```markdown
## 分段阅读策略 (新增)

⚠️ 内存管理规则:
1. 使用 Read(file, offset=N, limit=500) 分段读取
2. 每识别一个 case/scenario，立即写入文件
3. 写入后清空相关变量，不保留完整对象
4. 每处理 500 行，更新 work_state.json 的 current_offset

执行步骤:
1. offset=0, Read 500 行
2. 识别 cases/scenarios → 立即写入 → 清空
3. offset+=500, 继续读取
4. 重复直到 chunk 结束
5. 返回简短摘要: "chunk X done: N cases, M scenarios"
```

### 关键修改 2: Phase 6 归档 (P2)

```python
# 移动临时文件到归档目录
import shutil
from datetime import datetime

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
archive_dir = f"{extracted_dir}/archive/{timestamp}"
os.makedirs(archive_dir, exist_ok=True)
shutil.move(f"{extracted_dir}/cases", f"{archive_dir}/cases")
shutil.move(f"{extracted_dir}/scenarios", f"{archive_dir}/scenarios")
```

---

## 4. 验证方法

1. **修改 SKILL.md 后重新运行抽取**
2. **监控指标**:
   - Subagent 是否完成且无超时 ✓
   - work_state.json 大小保持 <5KB ✓
   - archive/ 目录是否正确生成 ✓
3. **成功标准**:
   - 所有 chunk 处理完成
   - 无 context 超限错误
   - 临时文件已归档
