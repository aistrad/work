# Scenario 与 Case 抽取流程优化计划

> 前置工作（已完成）：通用模板优化，新增 thinking_frameworks_used, reasoning_chain, guidance_patterns 三个字段

---

## 一、现状分析

### 1.1 当前抽取架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     当前架构（两次独立处理）                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  knowledge_chunks 表                                                    │
│        │                                                                │
│        ├───→ [Stage 4a] case_extractor.py ───→ cases 表                │
│        │         └─ LLM Call #1                                        │
│        │                                                                │
│        └───→ [Stage 4b] scenario_generator.py ───→ scenario_candidates │
│                  └─ LLM Call #2                                        │
│                                                                         │
│  问题：                                                                 │
│  • 同一 chunk 被处理两次，浪费 LLM 调用                                  │
│  • 无增量处理，每次全量跑                                                │
│  • Scenario 无法追溯来源 chunk                                          │
│  • 更新 Prompt 后无法选择性重新处理                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 关键文件清单

| 文件 | 职责 | 行数 |
|------|------|------|
| `apps/api/workers/case_extractor.py` | Case 提取 | 346 行 |
| `apps/api/workers/scenario_generator.py` | Scenario 生成 | 463 行 |
| `apps/api/scripts/build_knowledge.py` | 流水线编排 | 342 行 |
| `.claude/skills/vibelife-skill/templates/prompts/CASE_EXTRACTION_PROMPT.md` | Case Prompt 模板 | ~150 行 |

### 1.3 数据流分析

**Case 抽取 (case_extractor.py:316-329)**：
```python
# 数据源查询
SELECT id, chunk_text as content
FROM knowledge_chunks
WHERE skill_id = $1
AND chunk_type IN ('case', 'theory', 'rule')  # 过滤条件
LIMIT $2
```

**Scenario 生成 (scenario_generator.py:430-441)**：
```python
# 数据源查询
SELECT id, chunk_text as content, chunk_type
FROM knowledge_chunks
WHERE skill_id = $1
ORDER BY chunk_type DESC  # 优先 method
LIMIT $2
```

---

## 二、优化目标

### 2.1 数据源变更：从 MD 文件直接抽取

**数据规模分析**（以 bazi 为例）：
| 指标 | MD 源文件 | DB chunks |
|------|----------|-----------|
| 数量 | 45 文件 | ~3478 chunks |
| 总行数 | 164,110 行 | - |
| 最大单文件 | 9059 行 (~100K tokens) | 每 chunk ~500 tokens |
| 上下文 | 完整文档结构 | 碎片化 |

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     新架构：MD 文件 → 统一抽取                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  /data/vibelife/knowledge/{skill}/converted/*.md  ← 数据源（人工编写）  │
│        │                                                                │
│        ▼                                                                │
│  [Stage 4] unified_extractor.py                                        │
│        │   ├─ 按章节分割（控制 < 30K tokens/次）                        │
│        │   ├─ 单次 LLM 调用同时提取 Case + Scenario                     │
│        │   ├─ 增量处理：跟踪已处理的文件+章节                           │
│        │   └─ 记录 source_file + source_section                        │
│        │                                                                │
│        ├───→ Scenario → 文件 (skills/{skill}/scenarios/*.md)           │
│        │                  └─ 人工审核后发布                             │
│        │                                                                │
│        └───→ Case → 数据库 (cases 表)                                  │
│                      └─ 质量评分后入库                                  │
│                                                                         │
│  优势：                                                                 │
│  • 完整上下文：LLM 看到完整章节，理解更准确                             │
│  • 可追溯：每个 Case/Scenario 都能追溯到源文件+章节                     │
│  • 易调试：直接查看 MD 文件，不需要查询数据库                           │
│  • 版本控制：MD 文件可 git 管理                                         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 存储原则：文件 vs 数据库（核心决策）

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         存储原则（核心决策）                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📁 Scenario（场景）→ 文件优先                                          │
│  ├─ 性质：服务定义（SOP、触发词、输出模板）                             │
│  ├─ 理由：需要版本控制、人工编辑、Git 追踪                              │
│  ├─ 主存储：skills/{skill}/scenarios/*.md                              │
│  ├─ DB 辅助：scenario_index（仅存触发词索引用于路由）                   │
│  └─ 审核流：                                                            │
│       LLM 生成 → extracted/scenarios/ 目录（候选）                      │
│              → 人工审核编辑                                             │
│              → 移动到 skills/{skill}/scenarios/（发布）                 │
│              → 同步更新 scenario_index 表                               │
│                                                                         │
│  🗄️ Case（案例）→ 数据库优先                                            │
│  ├─ 性质：检索数据（特征、推理链、指导模式）                            │
│  ├─ 理由：需要向量搜索、相似匹配、动态查询                              │
│  ├─ 主存储：cases 表（PostgreSQL + pgvector）                          │
│  ├─ 辅助：可选导出为 .yaml 用于批量审核                                │
│  └─ 审核流：                                                            │
│       LLM 生成 → cases 表 (status='pending')                           │
│              → 质量评分 (quality_score)                                │
│              → 高分自动审核 / 低分人工审核                              │
│              → 更新 status='approved'                                  │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  判断标准（选文件 or 数据库）：                                          │
│  ┌─────────────────────┬────────────────┬────────────────┐             │
│  │ 问题                 │ 答案=是 → 文件 │ 答案=是 → DB   │             │
│  ├─────────────────────┼────────────────┼────────────────┤             │
│  │ 需要人工编辑内容？    │ ✓             │                │             │
│  │ 需要 Git 版本控制？   │ ✓             │                │             │
│  │ 定义系统行为？        │ ✓             │                │             │
│  │ 需要向量相似搜索？    │                │ ✓              │             │
│  │ 需要动态条件查询？    │                │ ✓              │             │
│  │ 是运行时检索数据？    │                │ ✓              │             │
│  └─────────────────────┴────────────────┴────────────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 完整目录结构

```
/data/vibelife/knowledge/{skill}/
├── source/                    # 原始文件（PDF, Word）
│   └── *.pdf, *.docx
│
├── converted/                 # 转换后 MD（抽取数据源 ✓）
│   ├── manual/               # 人工编写
│   │   └── 第*章_*.md
│   └── *.converted.md        # 自动转换
│
└── extracted/                 # 新增：抽取中间结果
    ├── cases/                # Case 候选（审核前）
    │   └── {file_stem}.cases.yaml
    ├── scenarios/            # Scenario 候选（审核前）
    │   └── {file_stem}.scenarios.md
    └── extraction_log.json   # 处理日志（增量用）

/apps/api/skills/{skill}/
├── SKILL.md                  # Skill 定义
├── scenarios/                # 已发布 Scenario（文件 ✓）
│   └── *.md
└── tools/                    # 工具定义
    └── *.py

PostgreSQL
├── knowledge_chunks          # 分块知识（运行时向量检索）
├── cases                     # Case 数据（运行时检索 ✓）
│   └── status: pending/approved/rejected
└── scenario_index            # 触发词索引（运行时路由）
```

---

## 三、实施方案

### 3.1 增量处理机制：extraction_log.json

**不再依赖数据库追踪**，改用文件系统日志：

```json
// /data/vibelife/knowledge/{skill}/extracted/extraction_log.json
{
  "skill_id": "bazi",
  "prompt_version": 2,
  "last_run": "2026-01-14T10:30:00Z",
  "files": {
    "manual/第六章_十神的深层心理与事件对应.md": {
      "status": "extracted",
      "md5": "abc123...",
      "extracted_at": "2026-01-14T10:30:00Z",
      "cases_count": 5,
      "scenarios_count": 2
    },
    "《东方代码启示录》概念篇+八字教学基础版本.converted.md": {
      "status": "pending",
      "md5": "def456...",
      "sections": [
        {"name": "第一章", "status": "extracted"},
        {"name": "第二章", "status": "pending"}
      ]
    }
  }
}
```

**增量逻辑**：
1. 检查文件 MD5 是否变化 → 变化则需重新抽取
2. 检查 prompt_version 是否更新 → 更新则全部重新抽取
3. 只处理 status = "pending" 的文件/章节

### 3.2 数据库 Schema 变更

**cases 表新增字段**（追溯来源）：

```sql
-- 来源追溯（从 MD 文件）
ALTER TABLE cases ADD COLUMN IF NOT EXISTS
    source_file VARCHAR(255);      -- 源文件路径
ALTER TABLE cases ADD COLUMN IF NOT EXISTS
    source_section VARCHAR(255);   -- 源章节名称
ALTER TABLE cases ADD COLUMN IF NOT EXISTS
    quality_score FLOAT DEFAULT 0; -- 质量评分 0-1

-- 索引
CREATE INDEX IF NOT EXISTS idx_cases_source_file
    ON cases(skill_id, source_file);
CREATE INDEX IF NOT EXISTS idx_cases_status
    ON cases(skill_id, status);
```

**scenario_index 表更新**（不再需要 scenario_candidates 表）：

```sql
-- Scenario 直接从文件加载，scenario_index 只存索引
-- 无需数据库修改，但需要更新加载逻辑
```

### 3.3 统一抽取 Prompt 设计

**新建文件**: `.claude/skills/vibelife-skill/templates/prompts/UNIFIED_EXTRACTION_PROMPT.md`

```markdown
你是一个专业的知识抽取专家。请从以下文本中同时识别：
1. **案例 (Case)**：具体的分析实例，包含完整的推理过程
2. **场景 (Scenario)**：可服务用户的服务流程定义

## Skill类型: {skill_id}

## 思维架构体系
{thinking_frameworks}

## 源文件信息
- 文件: {source_file}
- 章节: {source_section}

## 待分析文本
{text}

## 输出格式

```json
{
  "cases": [
    {
      "name": "案例名称",
      "core_data": {...},
      "features": {...},
      "thinking_frameworks_used": ["架构1", "架构2"],
      "reasoning_chain": [
        {"step": 1, "framework": "...", "observation": "...", "analysis": "...", "conclusion": "..."}
      ],
      "guidance_patterns": [
        {"pattern_name": "...", "condition": "...", "advice": "...", "source": "..."}
      ],
      "tags": [...],
      "scenario_ids": [...]
    }
  ],
  "scenarios": [
    {
      "scenario_id": "英文ID",
      "name": "中文名称",
      "level": "entry|standard|professional",
      "primary_triggers": ["触发词1", "触发词2"],
      "secondary_triggers": ["次要触发词"],
      "sop_phases": [
        {"phase": 1, "name": "信息收集", "description": "...", "tools": [...]}
      ]
    }
  ],
  "extraction_notes": "抽取备注（可选）"
}
```

如果文本不包含案例或场景，对应数组返回空 `[]`。
```

### 3.4 新建统一抽取器

**新建文件**: `apps/api/workers/unified_extractor.py`

核心逻辑（基于 MD 文件）：

```python
class UnifiedExtractor:
    """
    Stage 4: Unified Case & Scenario Extraction from MD Files

    Features:
    - Reads directly from MD source files (not DB chunks)
    - Single LLM call extracts both Case and Scenario
    - Incremental processing via extraction_log.json
    - Large files split by sections (< 30K tokens per call)
    - Output: Cases → DB, Scenarios → files
    """

    def __init__(self, skill_id: str):
        self.skill_id = skill_id
        self.converted_dir = DATA_DIR / "knowledge" / skill_id / "converted"
        self.extracted_dir = DATA_DIR / "knowledge" / skill_id / "extracted"
        self.log_path = self.extracted_dir / "extraction_log.json"

    def _load_extraction_log(self) -> dict:
        """Load or initialize extraction log"""
        ...

    def _split_by_sections(self, content: str, max_tokens: int = 30000) -> list[dict]:
        """Split large MD file by sections (headers)"""
        ...

    async def extract_from_file(self, file_path: Path) -> dict:
        """
        Extract Cases and Scenarios from a single MD file.
        For large files, split by sections.
        """
        content = file_path.read_text()

        if self._estimate_tokens(content) > 30000:
            sections = self._split_by_sections(content)
            results = {"cases": [], "scenarios": []}
            for section in sections:
                section_result = await self._call_llm(section["content"], section["name"])
                results["cases"].extend(section_result["cases"])
                results["scenarios"].extend(section_result["scenarios"])
            return results
        else:
            return await self._call_llm(content, file_path.stem)

    async def process_pending_files(self, force_reextract: bool = False) -> dict:
        """
        Incremental processing:
        - Check MD5 hash for file changes
        - Only process changed/new files
        - Update extraction_log.json
        """
        log = self._load_extraction_log()
        md_files = list(self.converted_dir.rglob("*.md"))

        results = {"cases_count": 0, "scenarios_count": 0, "files_processed": 0}

        for md_file in md_files:
            rel_path = str(md_file.relative_to(self.converted_dir))
            current_md5 = self._compute_md5(md_file)

            # Skip if already processed and unchanged
            if not force_reextract and rel_path in log["files"]:
                if log["files"][rel_path]["md5"] == current_md5:
                    continue

            # Extract
            extraction = await self.extract_from_file(md_file)

            # Save Cases to DB
            saved_cases = await self._save_cases_to_db(
                extraction["cases"],
                source_file=rel_path
            )

            # Save Scenarios to files
            saved_scenarios = await self._save_scenarios_to_files(
                extraction["scenarios"],
                source_file=rel_path
            )

            # Update log
            log["files"][rel_path] = {
                "status": "extracted",
                "md5": current_md5,
                "extracted_at": datetime.now().isoformat(),
                "cases_count": len(extraction["cases"]),
                "scenarios_count": len(extraction["scenarios"])
            }

            results["cases_count"] += saved_cases
            results["scenarios_count"] += saved_scenarios
            results["files_processed"] += 1

        self._save_extraction_log(log)
        return results

    async def _save_cases_to_db(self, cases: list, source_file: str) -> int:
        """Insert cases to PostgreSQL with status='pending'"""
        ...

    async def _save_scenarios_to_files(self, scenarios: list, source_file: str) -> int:
        """
        Save scenarios to extracted/scenarios/ directory as .md files.
        These are candidates for human review.
        """
        for scenario in scenarios:
            output_path = self.extracted_dir / "scenarios" / f"{scenario['scenario_id']}.md"
            md_content = self._render_scenario_md(scenario)
            output_path.write_text(md_content)
        return len(scenarios)
```

### 3.5 流水线整合

**修改**: `apps/api/scripts/build_knowledge.py`

```python
# 原来（两个独立步骤）
async def run_stage_4a(self, limit: int = 100):
    """Stage 4a: Extract cases from DB chunks"""
    ...

async def run_stage_4b(self, limit: int = 50):
    """Stage 4b: Generate scenarios from DB chunks"""
    ...

# 新增（统一抽取，直接从 MD 文件）
async def run_stage_4(self, force_reextract: bool = False):
    """
    Stage 4: Unified Extraction from MD Files

    读取 /data/vibelife/knowledge/{skill}/converted/*.md
    输出:
    - Cases → cases 表 (status='pending')
    - Scenarios → extracted/scenarios/*.md (候选)
    """
    from workers.unified_extractor import UnifiedExtractor

    extractor = UnifiedExtractor(self.skill_id)
    results = await extractor.process_pending_files(force_reextract=force_reextract)

    logger.info(f"Stage 4 complete: {results['cases_count']} cases, {results['scenarios_count']} scenarios from {results['files_processed']} files")
    return results
```

### 3.6 CLI 参数扩展

```bash
# 增量处理（默认行为，只处理新增/修改的 MD 文件）
python build_knowledge.py --skill bazi --stages 4

# 强制重新抽取所有文件
python build_knowledge.py --skill bazi --stages 4 --force-reextract

# 只处理特定文件
python build_knowledge.py --skill bazi --stages 4 --files "manual/*.md"

# 查看抽取状态（不执行）
python build_knowledge.py --skill bazi --stages 4 --dry-run
```

---

## 四、增量逻辑详解

### 4.1 基于文件的状态追踪

**核心原理**：使用 MD5 哈希检测文件变化，而非数据库状态

```
extraction_log.json
{
  "files": {
    "file.md": {
      "md5": "abc123",        ← 文件内容哈希
      "status": "extracted",
      "extracted_at": "..."
    }
  },
  "prompt_version": 2         ← Prompt 版本号
}

状态判断：
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   文件不在 log 中？             → 新文件，需要处理                        │
│   文件 MD5 变化？               → 内容更新，需要重新处理                  │
│   prompt_version 变化？         → Prompt 更新，全部重新处理               │
│   其他情况                      → 跳过（已处理且未变化）                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 融合策略（基于文件）

**场景 A：新增 MD 文件**
```
1. 用户添加新 MD 文件到 converted/ 目录
2. Stage 4 运行 → 检测到新文件（不在 log 中）
3. 抽取 Cases + Scenarios
4. Cases → 写入 DB (status='pending')
   Scenarios → 写入 extracted/scenarios/*.md
5. 更新 extraction_log.json
```

**场景 B：修改已有 MD 文件**
```
1. 用户编辑 converted/ 目录中的 MD 文件
2. Stage 4 运行 → 检测到 MD5 变化
3. 重新抽取该文件
4. Cases → UPSERT（基于 source_file 匹配）
   Scenarios → 覆盖写入 extracted/scenarios/
5. 更新 extraction_log.json
```

**场景 C：更新 Prompt 模板**
```
1. 编辑 UNIFIED_EXTRACTION_PROMPT.md
2. 递增 extraction_log.json 中的 prompt_version
3. 运行: python build_knowledge.py --skill bazi --stages 4 --force-reextract
4. 所有文件重新处理
5. 旧结果被新结果覆盖/更新
```

**场景 D：删除 MD 源文件**
```
1. 用户从 converted/ 删除 MD 文件
2. 运行清理命令: python build_knowledge.py --skill bazi --cleanup
3. 查找 cases 表中 source_file 指向已删除文件的记录
4. 标记或删除这些 Cases
5. 从 extracted/scenarios/ 删除相关 Scenario 候选
```

### 4.3 来源追溯查询

```sql
-- 查看某个 Case 来源于哪个 MD 文件
SELECT
    c.id,
    c.name,
    c.source_file,        -- 例: "manual/第六章_十神的深层心理与事件对应.md"
    c.source_section,     -- 例: "第六节：正偏转换"
    c.status,
    c.quality_score
FROM cases c
WHERE c.id = 'CASE_bazi_xxxx';

-- 查看某个 MD 文件产出了哪些 Cases
SELECT
    source_file,
    COUNT(*) as cases_count,
    AVG(quality_score) as avg_quality,
    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_count
FROM cases
WHERE skill_id = 'bazi'
GROUP BY source_file
ORDER BY cases_count DESC;

-- 查找质量评分低的 Cases（需人工审核）
SELECT id, name, source_file, quality_score
FROM cases
WHERE skill_id = 'bazi'
  AND status = 'pending'
  AND quality_score < 0.6
ORDER BY quality_score ASC;
```

---

## 五、关键文件修改清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `apps/api/workers/unified_extractor.py` | 新建 | 统一抽取器（从 MD 文件抽取） |
| `.claude/skills/vibelife-skill/templates/prompts/UNIFIED_EXTRACTION_PROMPT.md` | 新建 | 统一抽取 Prompt 模板 |
| `apps/api/stores/migrations/002_cases_source_tracking.sql` | 新建 | cases 表新增 source_file, source_section, quality_score |
| `apps/api/scripts/build_knowledge.py` | 修改 | 新增 run_stage_4() 统一抽取方法 |
| `apps/api/routes/knowledge_builder.py` | 修改 | 新增抽取状态查询 API |

**新增目录结构**：
```
/data/vibelife/knowledge/{skill}/extracted/
├── cases/                # Case 候选（YAML 格式，便于批量审核）
├── scenarios/            # Scenario 候选（MD 格式，便于人工编辑）
└── extraction_log.json   # 增量处理日志
```

**保留兼容**（不删除）：
- `apps/api/workers/case_extractor.py` - 保留用于单独调试/对比
- `apps/api/workers/scenario_generator.py` - 保留用于单独调试/对比
- Stage 4a/4b CLI 参数继续可用（内部调用新的统一抽取器）

---

## 六、验证方案

### 6.1 单元测试

```python
# test_unified_extractor.py

async def test_extract_from_file_returns_both():
    """验证单次文件处理能同时返回 Case 和 Scenario"""
    extractor = UnifiedExtractor("bazi")
    result = await extractor.extract_from_file(Path("test.md"))
    assert "cases" in result
    assert "scenarios" in result

async def test_incremental_skips_unchanged_files():
    """验证增量逻辑会跳过未修改的文件"""
    # 首次运行
    results1 = await extractor.process_pending_files()
    # 再次运行（文件未变）
    results2 = await extractor.process_pending_files()
    assert results2["files_processed"] == 0

async def test_md5_change_triggers_reextract():
    """验证文件内容变化会触发重新抽取"""
    # 首次运行
    await extractor.process_pending_files()
    # 修改文件内容
    test_file.write_text(test_file.read_text() + "\n新内容")
    # 再次运行
    results = await extractor.process_pending_files()
    assert results["files_processed"] == 1

async def test_cases_saved_to_db_scenarios_to_files():
    """验证 Cases 写入 DB，Scenarios 写入文件"""
    results = await extractor.process_pending_files()
    # 检查 DB
    cases = await db.fetch("SELECT * FROM cases WHERE skill_id = 'bazi'")
    assert len(cases) > 0
    # 检查文件
    scenario_files = list((extracted_dir / "scenarios").glob("*.md"))
    assert len(scenario_files) > 0
```

### 6.2 端到端测试

```bash
# 1. 准备测试 MD 文件
echo "# 测试章节\n\n乾隆案例分析..." > /data/vibelife/knowledge/bazi/converted/test.md

# 2. 首次运行
python build_knowledge.py --skill bazi --stages 4
# 日志应显示 "1 file processed, X cases, Y scenarios"

# 3. 验证结果
# 检查 DB
psql -c "SELECT COUNT(*), source_file FROM cases WHERE skill_id = 'bazi' GROUP BY source_file;"
# 检查文件
ls /data/vibelife/knowledge/bazi/extracted/scenarios/
cat /data/vibelife/knowledge/bazi/extracted/extraction_log.json

# 4. 再次运行（应该跳过已处理的）
python build_knowledge.py --skill bazi --stages 4
# 日志应显示 "0 files to process (all up to date)"

# 5. 修改源文件触发重新抽取
echo "\n新增内容" >> /data/vibelife/knowledge/bazi/converted/test.md
python build_knowledge.py --skill bazi --stages 4
# 日志应显示 "1 file processed (content changed)"

# 6. 强制全部重新抽取
python build_knowledge.py --skill bazi --stages 4 --force-reextract
# 日志应显示所有文件都被处理
```

---

## 七、后续可选优化

1. **批量 LLM 调用**：将多个 chunks 合并到一个 Prompt 中处理
2. **异步队列**：使用 Celery/Redis 实现后台异步抽取
3. **质量评分**：为每个 Case/Scenario 生成质量评分
4. **去重检测**：检测相似的 Case/Scenario 避免重复

---

# 附录：原通用模板优化计划（已完成）

## 从《东方代码启示录》案例中抽象的核心洞察

### 洞察 1：专家存储的是"推理链条"而非"结论"

**学习案例**（乾隆皇帝八字分析）：
```
结论型记录（当前）：                    推理型记录（专家）：
─────────────────────────              ─────────────────────────
{                                      {
  "pattern": "正官格",                   "reasoning_chain": [
  "key_gods": ["正官"]                     {
}                                           "step": 1,
                                            "observation": "劫财辛金透出",
↓ 用户只能看到结论                           "analysis": "被正官丁火克弱",
                                            "conclusion": "释放反向信号→人脉扶助"
                                          }
                                        ]
                                      }

                                      ↓ 用户能看到专家的思维过程
```

**泛化到所有 Skill**：
- 占星：不只记录"金星落天蝎"，要记录如何从相位推导出"情感深刻"
- 塔罗：不只记录"愚者正位"，要记录如何从牌面推导出"新开始的勇气"
- 职业：不只记录"适合管理"，要记录如何从经历推导出"领导力潜质"

---

### 洞察 2：每个领域都有自己的"思维架构"体系

**学习案例**（八字25种思维架构）：
```
主体思维架构 → 身强/身弱判定
客体思维架构 → 十神分析
时运思维架构 → 大运流年
正偏思维架构 → 正偏转换关系
...
```

**泛化到所有 Skill**：

| Skill | 核心思维架构（示例） |
|-------|---------------------|
| Zodiac | 元素架构、模式架构、相位架构、宫位架构、行运架构 |
| Tarot | 大小牌架构、花色架构、数字架构、叙事架构、元素尊严架构 |
| Career | 职业锚架构、霍兰德架构、MBTI架构、技能矩阵架构 |

**核心观点**：每个专业领域都有一套"看问题的方式"，这就是思维架构。

---

### 洞察 3：专家系统的核心价值是"指导"而非"预测"

**学习案例**（《东方代码启示录》原话）：
> "八字学的实用性，不在于预见人生，而在于指导更理想的人生。"
> "可以主动选择较轻微的表现方式来宣泄能量"

**泛化到所有 Skill**：
- 所有专家系统都应该输出"可操作的指导"
- 指导模式是专家系统的核心资产
- 这才是用户真正需要的价值

---

## 通用模板优化方案

### 1. SKILL_TEMPLATE.md 新增「思维架构」章节

```markdown
## 思维架构体系

本 Skill 的分析基于以下思维架构：

### 核心架构 (必须掌握)

| 架构名称 | 分析维度 | 应用场景 |
|---------|---------|---------|
| {架构1} | {描述} | {场景} |
| {架构2} | {描述} | {场景} |

### 进阶架构 (专业级使用)

| 架构名称 | 分析维度 | 应用场景 |
|---------|---------|---------|
| {架构3} | {描述} | {场景} |

### 架构组合规则

| 场景类型 | 使用架构组合 |
|---------|-------------|
| {场景} | {架构1} + {架构2} |
```

**好处**：
- 新手构建 Skill 时知道要思考"这个领域的分析维度有哪些"
- Scenario 可以引用架构组合
- Case 可以标注使用了哪些架构

---

### 2. SCENARIO_TEMPLATE.md 新增「分析框架」配置

在 Phase 5 (深度分析) 中新增：

```markdown
### Phase 5: 深度分析

**使用的思维架构**:
- {架构1}: {在此场景的应用方式}
- {架构2}: {在此场景的应用方式}

**分析框架**:
```yaml
analysis_framework:
  dimensions:
    - name: "{分析维度1}"
      source_framework: "{架构名称}"
      factors: ["{因素1}", "{因素2}"]
      output: "{输出类型}"
    - name: "{分析维度2}"
      source_framework: "{架构名称}"
      factors: [...]
      output: "..."
```

**好处**：
- SOP 不再是"黑盒"，而是清晰标注使用了哪些架构
- LLM 执行时有明确的分析框架指导
- 案例匹配可以基于架构匹配

---

### 3. CASE_EXTRACTION_PROMPT.md 重构为「推理链条提取」

**当前结构**：
```
core_data + features + tags + analysis + conclusion
```

**新结构**：
```
core_data + features + thinking_frameworks_used + reasoning_chain + guidance_patterns
```

**新增字段定义**：

```markdown
## 推理链条 (reasoning_chain)

从专业文本中提取专家的推理过程，每个步骤包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| step | int | 步骤序号 |
| framework | string | 使用的思维架构 |
| observation | string | 观察到的特征 |
| analysis | string | 分析推理过程 |
| conclusion | string | 该步骤的结论 |

## 指导模式 (guidance_patterns)

从专业文本中提取可复用的指导建议：

| 字段 | 类型 | 说明 |
|------|------|------|
| pattern_name | string | 模式名称 |
| condition | string | 适用条件 |
| advice | string | 具体建议 |
| source | string | 来源依据 |

## 使用的思维架构 (thinking_frameworks_used)

标注该案例使用了哪些思维架构：
- 用于 Scenario-Case 匹配
- 用于推理链条归类
```

---

### 4. SKILL_SCHEMAS.md 新增通用字段

**所有 Skill 共享的新字段**：

```python
# 通用案例结构（所有 Skill 共享）
COMMON_CASE_FIELDS = {
    "reasoning_chain": {
        "type": "array",
        "description": "专家推理链条",
        "items": {
            "step": "int",
            "framework": "string",
            "observation": "string",
            "analysis": "string",
            "conclusion": "string"
        }
    },
    "guidance_patterns": {
        "type": "array",
        "description": "指导模式",
        "items": {
            "pattern_name": "string",
            "condition": "string",
            "advice": "string",
            "source": "string"
        }
    },
    "thinking_frameworks_used": {
        "type": "array",
        "description": "使用的思维架构列表",
        "items": "string"
    }
}
```

---

### 5. VibeLife-Expert-System-v6.md 新增「思维架构层」

在架构全景图中新增：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      VibeLife Expert System                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ══════════════════════ 思维架构层 (Thinking Framework Layer) ═══════════   │
│                                                                             │
│   每个 Skill 定义自己的思维架构体系：                                        │
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │   Bazi      │  │   Zodiac    │  │   Tarot     │  │   Career    │       │
│   ├─────────────┤  ├─────────────┤  ├─────────────┤  ├─────────────┤       │
│   │ 主体架构    │  │ 元素架构    │  │ 大小牌架构  │  │ 职业锚架构  │       │
│   │ 客体架构    │  │ 模式架构    │  │ 花色架构    │  │ 霍兰德架构  │       │
│   │ 时运架构    │  │ 相位架构    │  │ 数字架构    │  │ MBTI架构    │       │
│   │ 正偏架构    │  │ 宫位架构    │  │ 叙事架构    │  │ 技能架构    │       │
│   │ ...         │  │ ...         │  │ ...         │  │ ...         │       │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                                             │
│   Scenario = 思维架构的组合                                                  │
│   Case = 思维架构下的推理示范 + 指导模式                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 关键文件修改清单

| 文件 | 修改类型 | 具体内容 |
|------|---------|---------|
| `templates/SKILL_TEMPLATE.md` | 新增章节 | 「思维架构体系」 |
| `templates/SCENARIO_TEMPLATE.md` | 新增 Phase 5 配置 | 分析框架 YAML |
| `templates/prompts/CASE_EXTRACTION_PROMPT.md` | 重构 | 推理链条+指导模式提取 |
| `templates/schemas/SKILL_SCHEMAS.md` | 新增字段 | 3个通用字段 |
| `docs/archive/v6/VibeLife-Expert-System-v6.md` | 新增章节 | 思维架构层说明 |

---

## 验证方案

1. **用新 SKILL_TEMPLATE 重新审视 Zodiac Skill**
   - 识别占星的思维架构体系
   - 验证模板是否足够通用

2. **用新 CASE_EXTRACTION_PROMPT 提取乾隆案例**
   - 验证推理链条提取是否可行
   - 验证指导模式提取是否可行

3. **用新 SCENARIO_TEMPLATE 检查 career.md**
   - 验证分析框架配置是否清晰
   - 验证思维架构引用是否合理

---

## 核心价值总结

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   从「结论导向」→「推理导向」                                                │
│                                                                             │
│   当前：专家系统 = 知识库 + 案例库 + SOP                                    │
│                                                                             │
│   优化：专家系统 = 思维架构 + 推理链条 + 指导模式                            │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                                                                     │   │
│   │   思维架构：专家"怎么看"问题                                        │   │
│   │   推理链条：专家"怎么想"问题                                        │   │
│   │   指导模式：专家"怎么建议"用户                                      │   │
│   │                                                                     │   │
│   │   这三者才是专家系统的核心资产                                       │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```
