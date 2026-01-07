# VibeLife Knowledge System Optimization Plan

> 版本: v2.0
> 日期: 2026-01-06
> 状态: 已实现

## 目标

基于 PostgreSQL + pgvector，设计**极简高效**的知识库系统：
- 支持多格式文档：PDF, MD, TXT, EPUB, DOCX, HTML
- 每个 skill module 指定知识源文件夹，每日凌晨 4:00 自动同步
- 中英文混合查询优化 (70% 中文 / 30% 英文)
- 极简架构：无 Redis、Celery、ES，纯 PostgreSQL Native

---

## 设计决策

| 决策项 | 选择 |
|--------|------|
| 向量维度 | **1024维**（默认 bge-m3 原生维度） |
| 文件删除策略 | **软删除/归档** (标记 archived, 保留数据) |
| QA生成 | **不需要** (当前阶段不自动生成 QA 对) |
| 扫描频率 | **每日凌晨 4:00** |
| 任务队列 | **PostgreSQL SKIP LOCKED** (替代 Celery) |
| 重试机制 | **最多 3 次重试** |
| 锁超时 | **30 分钟** (防止僵尸任务) |
| 混合搜索权重 | **向量 0.7 / 关键词 0.3** |

---

## 知识源目录结构

```
/home/aiscend/work/vibelife/knowledge/
├── bazi/           # 八字技能知识库
│   ├── 天干地支.md
│   ├── 十神详解.pdf
│   ├── 八字入门.epub
│   └── 案例分析.docx
├── zodiac/         # 星座技能知识库
└── mbti/           # MBTI技能知识库
```

---

## 多格式支持

| 格式 | 转换工具 | 说明 |
|------|---------|------|
| PDF | pymupdf4llm | 保留表格结构 |
| EPUB | ebooklib + BeautifulSoup | 电子书 |
| DOCX | python-docx | Word 文档 |
| HTML | html2text | 网页/抓取内容 |
| MD/TXT | 直接读取 | 原生支持 |

---

## 分块策略

### 设计原则

```
八字/星座/MBTI 知识特点:
├── 层次分明: 天干 → 十神 → 格局 → 运势
├── 表格密集: 五行对照表、天干地支表
├── 术语关联: "比肩" 需要联系 "日主"、"五行"
└── 结构固定: 12星座 × N维度, 16类型 × M特征

分块原则:
1. 语义完整性 > 长度均匀性
2. 表格/列表作为完整单元，不拆分
3. 保留层级路径信息 (如 "十神 > 比肩 > 特点")
```

### 分块参数

```python
CHUNK_SIZE = 600          # 目标块大小 (中文字符)
CHUNK_OVERLAP = 80        # 重叠区域 (保持上下文)
MIN_CHUNK_SIZE = 100      # 最小块 (过小则向上合并)
MAX_CHUNK_SIZE = 1200     # 最大块 (允许表格超长)
```

### 三阶段分块流程

```
阶段 1: 结构解析 (按 Markdown 标题)
─────────────────────────────────────
# 十神详解
## 比肩
### 比肩的特点
...

→ 解析为层级结构，保留 section_path

阶段 2: 智能合并 (过小块向上合并)
─────────────────────────────────────
### 比肩的特点 (50字)  ──┐
### 比肩过旺 (80字)    ──┼→ 合并为 "比肩" 块
### 比肩过弱 (60字)    ──┘

阶段 3: 安全拆分 (过长块在句子边界拆分)
─────────────────────────────────────
## 格局分析 (2000字)
→ 拆分为 3 个块，保留 80 字重叠
```

### 特殊内容处理

```
表格: 永不拆分，即使超过 MAX_CHUNK_SIZE
列表: < 800字保持完整，否则按顶级项拆分
代码块: 保持完整
```

---

## 中英文混合搜索

应用层 Jieba 分词 + PostgreSQL `simple` 配置：

```
输入: "比肩代表独立能力strong independence"
分词: "比肩 代表 独立 能力 strong independence"
存储: search_text_preprocessed 列
索引: to_tsvector('simple', ...) 自动生成
```

**优势**：
- 无需安装 pg_jieba 等运维复杂插件
- 任何 PostgreSQL 实例都能直接运行
- 对中英文都有良好支持

---

## 数据库 Schema

### 文档表 (兼作任务队列)

```sql
CREATE TABLE IF NOT EXISTS knowledge_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_hash TEXT NOT NULL,         -- MD5 用于检测变更
    file_type TEXT NOT NULL,         -- pdf, md, txt, epub, docx, html
    file_size_bytes BIGINT DEFAULT 0,
    content_md TEXT,                 -- 转换后的 Markdown (归档)
    status TEXT DEFAULT 'pending',   -- pending/processing/completed/failed/archived
    error_message TEXT,
    chunk_count INT DEFAULT 0,
    retry_count INT DEFAULT 0,       -- 重试次数 (最多 3 次)
    locked_by TEXT,                  -- Worker ID (用于 SKIP LOCKED)
    locked_at TIMESTAMPTZ,           -- 锁定时间 (超时检测)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(skill_id, filename)
);
```

### 知识块表

```sql
CREATE TABLE IF NOT EXISTS knowledge_chunks_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES knowledge_documents(id) ON DELETE SET NULL,
    skill_id TEXT NOT NULL,
    chunk_index INT NOT NULL DEFAULT 0,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'knowledge',

    -- 层级路径信息
    section_path TEXT[],             -- ARRAY['十神详解', '比肩', '特点']
    section_title TEXT,

    -- 元数据
    metadata JSONB DEFAULT '{}',
    has_table BOOLEAN DEFAULT FALSE,
    has_list BOOLEAN DEFAULT FALSE,
    char_count INT DEFAULT 0,        -- 字符数

    -- Jieba 分词后存入
    search_text_preprocessed TEXT,

    -- 自动生成全文索引
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', COALESCE(search_text_preprocessed, ''))
    ) STORED,

    -- 向量 (1024维)
    embedding vector(1024),

    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 索引

```sql
CREATE INDEX idx_docs_status ON knowledge_documents(status);
CREATE INDEX idx_docs_skill ON knowledge_documents(skill_id);
CREATE INDEX idx_chunks_v2_skill ON knowledge_chunks_v2(skill_id);
CREATE INDEX idx_chunks_v2_doc ON knowledge_chunks_v2(document_id);
CREATE INDEX idx_chunks_v2_type ON knowledge_chunks_v2(content_type);
CREATE INDEX idx_chunks_v2_fts ON knowledge_chunks_v2 USING gin(search_vector);
CREATE INDEX idx_chunks_v2_vec ON knowledge_chunks_v2 USING hnsw(embedding vector_cosine_ops);
```

---

## 混合搜索 SQL 函数 (RRF)

```sql
CREATE OR REPLACE FUNCTION hybrid_search_v2(
    query_text_processed TEXT,
    query_embedding vector(3584),
    match_skill_id TEXT,
    top_k INT DEFAULT 5,
    rrf_k INT DEFAULT 60,
    vector_weight FLOAT DEFAULT 0.7,   -- 向量搜索权重
    text_weight FLOAT DEFAULT 0.3      -- 关键词搜索权重
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    content_type TEXT,
    source_section TEXT,
    score FLOAT,
    match_type TEXT
) LANGUAGE sql STABLE AS $$
WITH semantic AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> query_embedding) as rank
    FROM knowledge_chunks_v2
    WHERE skill_id = match_skill_id AND embedding IS NOT NULL
    ORDER BY embedding <=> query_embedding
    LIMIT top_k * 2
),
keyword AS (
    SELECT id, ROW_NUMBER() OVER (
        ORDER BY ts_rank(search_vector, plainto_tsquery('simple', query_text_processed)) DESC
    ) as rank
    FROM knowledge_chunks_v2
    WHERE skill_id = match_skill_id
      AND search_vector @@ plainto_tsquery('simple', query_text_processed)
    LIMIT top_k * 2
)
SELECT
    COALESCE(s.id, k.id) as id,
    c.content,
    c.content_type,
    c.section_title,
    (COALESCE(1.0/(rrf_k + s.rank), 0.0) * vector_weight +
     COALESCE(1.0/(rrf_k + k.rank), 0.0) * text_weight)::FLOAT as score,
    CASE
        WHEN s.id IS NOT NULL AND k.id IS NOT NULL THEN 'hybrid'
        WHEN s.id IS NOT NULL THEN 'vector'
        ELSE 'keyword'
    END as match_type
FROM semantic s
FULL OUTER JOIN keyword k ON s.id = k.id
JOIN knowledge_chunks_v2 c ON c.id = COALESCE(s.id, k.id)
ORDER BY score DESC
LIMIT top_k;
$$;
```

---

## 核心模块

### 1. 多格式转换器 (`workers/converters.py`)

将 PDF/EPUB/DOCX/HTML 统一转换为 Markdown 格式。

### 2. 智能分块器 (`workers/chunker.py`)

三阶段分块：结构解析 → 智能合并 → 安全拆分。

### 3. 后台 Worker (`workers/ingestion.py`)

基于 PostgreSQL `SKIP LOCKED` 的任务队列，替代 Celery。

### 4. 文件夹同步 (`scripts/sync_knowledge.py`)

每日凌晨 4:00 扫描知识源文件夹，检测新增/修改/删除。

---

## 新增依赖

```
jieba>=0.42.1              # 中文分词
pymupdf4llm>=0.0.17        # PDF → Markdown
ebooklib>=0.18             # EPUB 电子书
python-docx>=1.1.0         # DOCX Word 文档
html2text>=2024.2.26       # HTML → Markdown
beautifulsoup4>=4.12.0     # HTML 解析
```

---

## 实现任务清单

### Phase 1: 数据库迁移
- [x] 创建 `migrations/002_knowledge_v2.sql`
- [x] 执行迁移：创建表和索引
- [x] 创建 `hybrid_search_v2` SQL 函数

### Phase 2: Worker 模块
- [x] 安装依赖
- [x] 创建 `apps/api/workers/converters.py`
- [x] 创建 `apps/api/workers/chunker.py`
- [x] 创建 `apps/api/workers/ingestion.py`
- [x] 在 `main.py` lifespan 中启动 worker

### Phase 3: 文件夹同步
- [x] 创建 `knowledge/` 目录结构
- [x] 创建 `scripts/sync_knowledge.py`
- [ ] 添加到 crontab (每日 4:00)

### Phase 4: 服务集成
- [x] 修改 `services/knowledge/retrieval.py` 使用 SQL 函数
- [x] 添加 jieba 分词到查询流程

### Phase 5: 测试验证
- [ ] 上传测试文档 (PDF, EPUB, DOCX)
- [ ] 验证分块质量
- [ ] 验证检索效果

---

## 已实现文件

| 文件 | 状态 | 说明 |
|------|------|------|
| `migrations/002_knowledge_v2.sql` | ✅ 已创建 | 数据库 Schema + SQL 函数 |
| `apps/api/workers/__init__.py` | ✅ 已创建 | 导出 IngestionWorker |
| `apps/api/workers/converters.py` | ✅ 已创建 | 多格式文档转换器 |
| `apps/api/workers/chunker.py` | ✅ 已创建 | 三阶段智能分块器 |
| `apps/api/workers/ingestion.py` | ✅ 已创建 | 后台 Worker |
| `apps/api/scripts/sync_knowledge.py` | ✅ 已创建 | 文件夹同步脚本 |
| `apps/api/services/knowledge/embedding.py` | ✅ 已创建 | bge-m3 默认 + GTE-Qwen2 可选(截断到1024) |
| `apps/api/services/knowledge/retrieval.py` | ✅ 已创建 | 混合检索服务 |
| `apps/api/main.py` | ✅ 已修改 | Worker 生命周期管理 |
| `apps/api/stores/knowledge_repo.py` | ✅ 已修改 | 数据访问层 |

---

## 运维指南

### 1. 手动执行同步脚本

```bash
cd /home/aiscend/work/vibelife
python -m apps.api.scripts.sync_knowledge
```

**参数选项**：
- `--skill bazi` - 只同步指定 skill
- `--force` - 强制重新处理所有文档
- `--stats` - 仅查看统计

**示例**：
```bash
# 同步所有
python -m apps.api.scripts.sync_knowledge

# 同步特定技能
python -m apps.api.scripts.sync_knowledge --skill bazi

# 强制重新处理
python -m apps.api.scripts.sync_knowledge --skill bazi --force

# 查看统计
python -m apps.api.scripts.sync_knowledge --stats
```

### 2. Ingestion Worker

Worker 随 FastAPI 应用自动启动，处理 pending 文档：

**处理流程**：
1. 文档格式转换 → Markdown
2. 智能分块（SmartChunker 三阶段）
3. Jieba 中文分词
4. Embedding 向量化（默认 bge-m3，1024维）
5. 存入 PostgreSQL + pgvector

**环境变量**：
```bash
VIBELIFE_WORKER_ENABLED=1          # 启用 Worker (默认)
VIBELIFE_WORKER_POLL_INTERVAL=5    # 轮询间隔 (秒)
# 本地嵌入（无需 API Key）
EMBEDDING_MODEL_NAME=Alibaba-NLP/gte-Qwen2-7B-instruct
EMBEDDING_DIMENSION=3584
EMBEDDING_DIMENSION=1024           # 目标向量维度
```

### 3. 定时任务配置

```bash
# 每日凌晨 4:00 同步
0 4 * * * cd /path/to/vibelife && python -m apps.api.scripts.sync_knowledge >> /var/log/vibelife/sync.log 2>&1
```

### 4. 监控和调试

**查看文档状态**：
```sql
SELECT status, COUNT(*) FROM knowledge_documents GROUP BY status;
```

**查看处理失败的文档**：
```sql
SELECT filename, error_message, retry_count
FROM knowledge_documents
WHERE status = 'failed';
```

**重新处理失败文档**：
```sql
UPDATE knowledge_documents
SET status = 'pending', retry_count = 0
WHERE status = 'failed';
```
