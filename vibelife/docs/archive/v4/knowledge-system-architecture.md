# Knowledge 库构建系统架构

> **版本**: v2.0
> **日期**: 2026-01-10
> **状态**: 已实现

---

## 概述

VibeLife Knowledge 库采用两阶段处理流程：源文件转换 + 向量化入库。支持保留转换后的 Markdown 文件，便于人工审核、版本管理和二次利用。

## 目录结构

```
knowledge/
├── {skill_id}/
│   ├── source/                    # 源文件目录
│   │   ├── book1.pdf
│   │   ├── book2.epub
│   │   └── notes.docx
│   └── converted/                 # 转换后的 MD 目录
│       ├── book1.converted.md
│       ├── book2.converted.md
│       └── notes.converted.md
└── {another_skill}/
    ├── source/
    └── converted/
```

## 处理流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Knowledge 入库流程                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. 文件同步 (sync_knowledge.py)                                        │
│     ├─ 扫描 source/ 目录                                                │
│     ├─ 检测文件变更 (MD5)                                               │
│     ├─ 检测 .converted.md 变更                                          │
│     ├─ 自动迁移旧目录结构                                               │
│     └─ 入队 (knowledge_documents 表)                                    │
│                                                                         │
│  2. 文档处理 (ingestion.py)                                             │
│     ├─ 转换为 Markdown (或使用已有 .converted.md)                       │
│     ├─ 保存 .converted.md 文件                                          │
│     ├─ 智能分块 (chunker.py)                                            │
│     ├─ 生成向量 (embedding.py)                                          │
│     ├─ 提取术语 (term_service.py)                                       │
│     └─ 存储到数据库                                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 变更检测逻辑

| 场景 | 检测方式 | 处理方式 |
|------|----------|----------|
| 源文件新增 | 文件不在数据库中 | 转换 → 保存 .converted.md → 入库 |
| 源文件修改 | file_hash 变化 | 重新转换 → 覆盖 .converted.md → 重新入库 |
| .converted.md 手动修改 | converted_hash 变化 + mtime 比源文件新 | 跳过转换 → 直接使用 .converted.md → 重新入库 |
| 文件删除 | 文件不存在 | 标记为 archived |

## 命名规则

- 源文件：`{name}.{ext}` (如 `book.pdf`)
- 转换后：`{name}.converted.md` (如 `book.converted.md`)

## 支持的文件格式

| 格式 | 扩展名 | 转换器 |
|------|--------|--------|
| Markdown | .md, .markdown | 直接读取 |
| 纯文本 | .txt | 直接读取 |
| PDF | .pdf | pymupdf4llm |
| EPUB | .epub | ebooklib + html2text |
| Word | .docx, .doc | python-docx |
| HTML | .html, .htm | BeautifulSoup + html2text |

## 数据库 Schema

### knowledge_documents 表

```sql
CREATE TABLE knowledge_documents (
    id UUID PRIMARY KEY,
    skill_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_hash TEXT NOT NULL,           -- 源文件 MD5
    file_type TEXT NOT NULL,
    file_size_bytes INT,
    content_md TEXT,                   -- 转换后的 Markdown (数据库备份)
    converted_path TEXT,               -- .converted.md 文件路径
    converted_hash TEXT,               -- .converted.md 文件 MD5
    use_converted BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'pending',
    chunk_count INT DEFAULT 0,
    ...
);
```

### knowledge_chunks 表

```sql
CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY,
    document_id UUID REFERENCES knowledge_documents(id),
    skill_id TEXT NOT NULL,
    chunk_index INT NOT NULL,
    content TEXT NOT NULL,
    section_path TEXT[],               -- 层级路径
    section_title TEXT,
    search_text_preprocessed TEXT,     -- Jieba 预分词
    search_vector TSVECTOR,            -- FTS 向量
    embedding vector(1024),            -- BGE-M3 向量
    ...
);
```

## 使用方法

### 同步知识库

```bash
# 同步所有技能
python -m apps.api.scripts.sync_knowledge

# 同步指定技能
python -m apps.api.scripts.sync_knowledge --skill bazi

# 强制重新处理所有文件
python -m apps.api.scripts.sync_knowledge --force

# 跳过自动迁移
python -m apps.api.scripts.sync_knowledge --no-migrate

# 仅查看统计
python -m apps.api.scripts.sync_knowledge --stats
```

### 运行入库 Worker

```bash
python -m apps.api.scripts.run_ingestion
```

### 手动审核/校对流程

1. 运行同步，生成 `.converted.md` 文件
2. 打开 `knowledge/{skill}/converted/` 目录
3. 用编辑器修改 `.converted.md` 文件
4. 再次运行同步，系统自动检测变更并重新入库

## 关键文件

| 文件 | 说明 |
|------|------|
| `apps/api/scripts/sync_knowledge.py` | 文件同步脚本 |
| `apps/api/scripts/run_ingestion.py` | 入库 Worker 启动脚本 |
| `apps/api/workers/ingestion.py` | 入库 Worker 核心逻辑 |
| `apps/api/workers/converters.py` | 多格式转换器 |
| `apps/api/workers/chunker.py` | 智能分块器 |
| `apps/api/services/knowledge/embedding.py` | 向量生成服务 |
| `apps/api/services/knowledge/retrieval.py` | 混合检索服务 |
| `apps/api/services/knowledge/term_service.py` | 术语提取服务 |
| `migrations/008_knowledge_converted_path.sql` | 数据库迁移 |

## 更新历史

- **2026-01-10 v2.0**: 新增 source/converted 目录结构，支持保留 .converted.md 文件
- **2026-01-05 v1.0**: 初始版本
