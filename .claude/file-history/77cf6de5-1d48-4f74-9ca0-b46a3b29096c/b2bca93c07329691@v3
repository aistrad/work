# 文档更新计划：knowledge-system-plan.md

## 目标文档
`/home/aiscend/work/vibelife/docs/knowledge-system-plan.md`

## 需要更新的内容

### 1. 设计决策表 - 向量维度修正
- **文档**: Gemini 3072维
- **代码**: 默认 1536 维（表定义 3072 向前兼容）
- **操作**: 更新为 1536 维

### 2. 文档表 Schema 更新
- **缺少字段**: `file_size_bytes`, `retry_count`, `locked_by`, `locked_at`
- **操作**: 补充完整字段

### 3. 知识块表 Schema 更新
- **缺少字段**: `char_count`
- **操作**: 补充字段

### 4. 混合搜索函数更新
- **缺少参数**: `vector_weight`, `text_weight`
- **操作**: 补充参数和默认值

### 5. 实现任务清单更新
- **状态**: 大部分已完成
- **操作**: 更新为已完成状态

### 6. 新增运维章节
- **内容**: 同步脚本使用说明、Worker 启动方式
- **操作**: 新增使用指南

---

# 知识系统流程分析：同步脚本 vs Ingestion Worker

## 概述

VibeLife 的知识处理系统分为两个阶段：
1. **同步脚本** (`sync_knowledge.py`) - 扫描文件系统，标记变更
2. **Ingestion Worker** (`ingestion.py`) - 后台处理 pending 文档

---

## 1. 同步脚本 (sync_knowledge.py) 详细流程

### 代码位置
`/home/aiscend/work/vibelife/apps/api/scripts/sync_knowledge.py`

### 命令行参数

| 参数 | 类型 | 作用 |
|------|------|------|
| `--skill SKILL_ID` | 可选 | 只同步指定技能文件夹（如 bazi） |
| `--force` | 标志 | 强制重新入队所有文档，无视哈希值 |
| `--stats` | 标志 | 仅显示统计，不执行同步 |

### 执行流程

```
main()
├── init_db()                          # 初始化 asyncpg 连接池
│
├── if --stats:
│   └── show_stats() → 退出           # 查询 knowledge_stats 视图
│
└── sync_all(target_skill, force)
    ├── 遍历 KNOWLEDGE_ROOT 下的一级目录（每个作为 skill_id）
    │
    └── for each skill_folder:
        ├── if --force:
        │   └── UPDATE status='pending' WHERE status NOT IN ('pending','processing')
        │
        └── scan_skill_folder(skill_id, folder_path)
            ├── glob 查找所有支持的文件 (*.md, *.pdf, *.epub, *.docx, *.html)
            │
            └── for each file:
                ├── 计算 MD5 哈希
                ├── 获取文件类型和大小
                │
                └── 数据库操作:
                    ├── 新文件 → INSERT status='pending'
                    ├── 哈希变化 → UPDATE status='pending' + DELETE 旧 chunks
                    └── archived 文件恢复 → UPDATE status='pending'
```

### 关键特性
- **增量检测**: 通过 MD5 哈希判断文件是否变化
- **状态管理**: 仅将需要处理的文档标记为 pending
- **自动存档**: 文件系统中不存在的文档标记为 archived

---

## 2. Ingestion Worker 详细流程

### 代码位置
`/home/aiscend/work/vibelife/apps/api/workers/ingestion.py`

### 启动方式
通过 FastAPI 应用生命周期自动启动（`main.py`）

### 执行流程

```
IngestionWorker.start()
    ↓
_run_loop() [异步循环, 每 5 秒轮询]
    ↓
_claim_document()
    └── SQL: claim_pending_document() 使用 SKIP LOCKED
    ↓
_process_document(doc)
    │
    ├── Step 1: 文档转换
    │   └── DocumentConverter.convert(file_path) → Markdown
    │       ├── PDFConverter (pymupdf4llm)
    │       ├── EPUBConverter (ebooklib + BeautifulSoup)
    │       ├── DOCXConverter (python-docx)
    │       └── HTMLConverter (html2text)
    │
    ├── Step 2: 智能分块
    │   └── SmartChunker.chunk(markdown_text)
    │       ├── 阶段1: _parse_structure() - 按 Markdown 标题解析
    │       ├── 阶段2: _merge_small_sections() - 合并过小的节
    │       └── 阶段3: _split_and_finalize() - 在句子边界分割
    │
    ├── Step 3: Jieba 中文分词
    │   └── SmartChunker.preprocess_for_search(content)
    │       └── jieba.cut_for_search() → 空格分隔的分词结果
    │
    ├── Step 4: Gemini Embedding 向量化
    │   └── _batch_embed(contents)
    │       └── EmbeddingService.embed_batch()
    │           └── HTTP POST gemini-embedding-001:embedContent
    │           └── taskType: "RETRIEVAL_DOCUMENT"
    │           └── 输出: 1536 维向量 + L2 归一化
    │
    └── Step 5: 存入 PostgreSQL + pgvector
        ├── DELETE FROM knowledge_chunks_v2 WHERE document_id=...
        └── INSERT INTO knowledge_chunks_v2 (
                content, embedding, search_text_preprocessed,
                section_path, section_title, ...
            )
    ↓
_complete_document() 或 _fail_document()
```

---

## 3. 文档 vs 代码 对比分析

### 文档描述
> - 文档格式转换 → Markdown
> - 智能分块（SmartChunker）
> - Jieba 中文分词
> - Gemini Embedding 向量化（1536维）
> - 存入 PostgreSQL + pgvector

### 对比结果

| 步骤 | 文档描述 | 代码实现 | 差异 |
|------|----------|----------|------|
| **格式转换** | "文档格式转换 → Markdown" | ✅ 支持 PDF/EPUB/DOCX/HTML/MD/TXT | **一致**，但文档未列出具体格式 |
| **智能分块** | "SmartChunker" | ✅ 三阶段分块：结构解析→合并→分割 | **一致**，但文档未说明三阶段设计 |
| **中文分词** | "Jieba 中文分词" | ✅ `jieba.cut_for_search()` 搜索模式 | **一致** |
| **向量化** | "Gemini Embedding（1536维）" | ⚠️ 代码配置 1536，但表定义 3072 | **潜在差异**，见下方分析 |
| **存储** | "PostgreSQL + pgvector" | ✅ HNSW 索引 + GIN 全文索引 | **一致** |

### 重要发现

#### 1. 向量维度不一致
- **代码配置**: `DEFAULT_DIMENSION = 1536`（embedding.py:26）
- **表定义**: `embedding vector(3072)`（002_knowledge_v2.sql:68）
- **分析**: 这是向前兼容设计。pgvector 的 `vector(3072)` 定义可以存储任意 ≤3072 维的向量，当前使用 1536 维是性能优化选择。

#### 2. 文档未提及的关键特性

| 特性 | 说明 |
|------|------|
| **SKIP LOCKED** | 分布式任务队列，支持多 Worker 并发 |
| **三阶段分块** | 结构解析 → 智能合并 → 句子边界分割 |
| **表格保护** | 包含表格的块永不分割 |
| **层级路径** | section_path 保留完整层级（如 `['十神', '比肩', '特性']`） |
| **RRF 混合搜索** | 向量 + 关键词结果融合（权重 0.7:0.3） |
| **重试机制** | 失败文档最多重试 3 次 |
| **锁超时** | 30 分钟锁超时，防止僵尸任务 |

#### 3. 同步脚本 vs Ingestion Worker 职责划分

```
同步脚本 (sync_knowledge.py)           Ingestion Worker (ingestion.py)
────────────────────────────          ─────────────────────────────────
• 扫描文件系统                         • 处理 pending 文档
• 计算文件哈希                         • 格式转换 → Markdown
• 检测变更                             • 智能分块
• 标记 pending 状态                    • Jieba 分词
• 存档缺失文件                         • Gemini 向量化
                                       • 存储 chunks 到数据库
```

---

## 4. SmartChunker 详细配置

```python
# chunker.py
CHUNK_SIZE = 600          # 目标块大小（汉字）
CHUNK_OVERLAP = 80        # 上下文重叠
MIN_CHUNK_SIZE = 100      # 最小块（小于则合并）
MAX_CHUNK_SIZE = 1200     # 最大块（超过则分割）
```

### 分块规则
1. **表格/代码块**: 永不分割，保持完整
2. **普通文本**: 在句子边界分割（。！？；）
3. **重叠设计**: 连续块之间保留 80 字重叠，确保上下文连贯

---

## 5. 数据流总结

```
[文件系统]
    │
    ↓ sync_knowledge.py (每天 4:00 AM cron)
    │
[knowledge_documents] status='pending'
    │
    ↓ IngestionWorker (持续轮询)
    │
    ├─→ DocumentConverter → Markdown
    ├─→ SmartChunker → Chunks
    ├─→ Jieba → 分词文本
    ├─→ Gemini → 1536维向量
    │
    ↓
[knowledge_chunks_v2]
    │
    ↓ hybrid_search_v2() (RRF 融合)
    │
[搜索结果]
```

---

## 6. 关键文件路径

| 文件 | 路径 | 职责 |
|------|------|------|
| 同步脚本 | `apps/api/scripts/sync_knowledge.py` | 文件系统扫描 |
| Worker | `apps/api/workers/ingestion.py` | 后台处理 |
| 分块器 | `apps/api/workers/chunker.py` | 智能分块 |
| 转换器 | `apps/api/workers/converters.py` | 格式转换 |
| Embedding | `apps/api/services/knowledge/embedding.py` | Gemini 向量化 |
| 数据库 | `migrations/002_knowledge_v2.sql` | Schema + 函数 |
