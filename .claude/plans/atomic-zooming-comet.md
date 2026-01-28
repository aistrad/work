# VibeLife Knowledge System Optimization Plan

## 目标
基于 PostgreSQL + pgvector，设计**极简高效**的知识库系统：
- 支持多格式文档：PDF, MD, TXT, EPUB, DOCX, HTML
- 每个 skill module 指定知识源文件夹，每日凌晨 4:00 自动同步
- 中英文混合查询优化 (70% 中文 / 30% 英文)
- 极简架构：无 Redis、Celery、ES，纯 PostgreSQL Native

---

## 用户确认的设计决策

| 决策项 | 选择 |
|--------|------|
| 向量维度 | **保持 Gemini 3072维** |
| 文件删除策略 | **软删除/归档** (标记 archived, 保留数据) |
| QA生成 | **不需要** (当前阶段不自动生成 QA 对) |
| 扫描频率 | **每日凌晨 4:00** |
| User Insight | **不在本计划范围** (独立模块) |
| Source-Insight | **不引入** (保持极简) |

---

## 设计决策详解

### 1. 文件目录简化
每个 skill 一个知识源文件夹：

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

### 2. 多格式支持

| 格式 | 转换工具 | 说明 |
|------|---------|------|
| PDF | pymupdf4llm | 保留表格结构 |
| EPUB | ebooklib + BeautifulSoup | 电子书 |
| DOCX | python-docx | Word 文档 |
| HTML | html2text | 网页/抓取内容 |
| MD/TXT | 直接读取 | 原生支持 |

### 3. 中英文混合搜索
应用层 Jieba 分词 + PG `simple` 配置：
```
输入: "比肩代表独立能力strong independence"
分词: "比肩 代表 独立 能力 strong independence"
存储: search_text_preprocessed 列
索引: to_tsvector('simple', ...) 自动生成
```

### 4. 软删除策略
文件被删除时：
- `status = 'archived'`
- 保留数据用于审计/回滚
- 不参与检索

---

## 分块策略 (核心设计)

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

## 数据库 Schema 设计

```sql
-- ===============================================
-- 文件: migrations/002_knowledge_v2.sql
-- ===============================================

-- 文档表 (兼作任务队列)
CREATE TABLE IF NOT EXISTS knowledge_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,         -- 完整文件路径
    file_hash TEXT NOT NULL,         -- MD5 用于检测变更
    file_type TEXT NOT NULL,         -- pdf, md, txt, epub, docx, html
    content_md TEXT,                 -- 转换后的 Markdown (归档)
    status TEXT DEFAULT 'pending',   -- pending/processing/completed/failed/archived
    error_message TEXT,
    chunk_count INT DEFAULT 0,       -- 生成的知识块数量
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(skill_id, filename)
);

-- 新版知识块表
CREATE TABLE IF NOT EXISTS knowledge_chunks_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES knowledge_documents(id) ON DELETE SET NULL,
    skill_id TEXT NOT NULL,
    chunk_index INT NOT NULL DEFAULT 0,
    content TEXT NOT NULL,
    content_type TEXT DEFAULT 'knowledge',  -- knowledge, theory, pattern, case, example

    -- 层级路径信息 (如 "十神详解 > 比肩 > 特点")
    section_path TEXT[],             -- ARRAY['十神详解', '比肩', '特点']
    section_title TEXT,              -- 当前节标题

    -- 元数据
    metadata JSONB DEFAULT '{}',
    has_table BOOLEAN DEFAULT FALSE,
    has_list BOOLEAN DEFAULT FALSE,

    -- Jieba 分词后存入 (中英文混合)
    search_text_preprocessed TEXT,

    -- 自动生成全文索引 (GENERATED ALWAYS)
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', COALESCE(search_text_preprocessed, ''))
    ) STORED,

    -- Gemini 3072维向量
    embedding vector(3072),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_docs_status ON knowledge_documents(status);
CREATE INDEX IF NOT EXISTS idx_docs_skill ON knowledge_documents(skill_id);
CREATE INDEX IF NOT EXISTS idx_chunks_v2_skill ON knowledge_chunks_v2(skill_id);
CREATE INDEX IF NOT EXISTS idx_chunks_v2_doc ON knowledge_chunks_v2(document_id);
CREATE INDEX IF NOT EXISTS idx_chunks_v2_type ON knowledge_chunks_v2(content_type);
CREATE INDEX IF NOT EXISTS idx_chunks_v2_fts ON knowledge_chunks_v2 USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_chunks_v2_vec ON knowledge_chunks_v2 USING hnsw(embedding vector_cosine_ops);

-- 迁移旧 knowledge_chunks 数据 (保留现有数据)
INSERT INTO knowledge_chunks_v2 (skill_id, content, content_type, section_title, metadata, embedding, created_at)
SELECT
    skill_id,
    content,
    COALESCE(content_type, 'knowledge'),
    source_section,
    metadata,
    embedding,
    created_at
FROM knowledge_chunks
WHERE embedding IS NOT NULL
ON CONFLICT DO NOTHING;
```

---

## 混合搜索 SQL 函数 (RRF 下沉到数据库)

```sql
-- ===============================================
-- 文件: migrations/002_knowledge_v2.sql (续)
-- ===============================================

CREATE OR REPLACE FUNCTION hybrid_search_v2(
    query_text_processed TEXT,    -- Jieba 分词后的查询
    query_embedding vector(3072),
    match_skill_id TEXT,
    top_k INT DEFAULT 5,
    rrf_k INT DEFAULT 60
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
    c.source_section,
    (COALESCE(1.0/(rrf_k + s.rank), 0.0) * 0.7 +
     COALESCE(1.0/(rrf_k + k.rank), 0.0) * 0.3)::FLOAT as score,
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

## 核心文件实现

### 1. 多格式转换器

**文件**: `apps/api/workers/converters.py`

```python
"""
多格式文档 → Markdown 转换器
支持: PDF, EPUB, DOCX, HTML, MD, TXT
"""
import pymupdf4llm
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
from docx import Document
import html2text

class DocumentConverter:
    """统一文档转换接口"""

    @staticmethod
    async def to_markdown(file_path: str, file_type: str) -> str:
        """将任意格式转换为 Markdown"""

        if file_type == 'pdf':
            # PDF: 保留表格结构
            return pymupdf4llm.to_markdown(file_path, write_images=False)

        elif file_type == 'epub':
            # EPUB: 提取章节文本
            book = epub.read_epub(file_path)
            chapters = []
            for item in book.get_items():
                if item.get_type() == ebooklib.ITEM_DOCUMENT:
                    soup = BeautifulSoup(item.get_content(), 'html.parser')
                    chapters.append(soup.get_text())
            return "\n\n".join(chapters)

        elif file_type == 'docx':
            # DOCX: 提取段落
            doc = Document(file_path)
            paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
            return "\n\n".join(paragraphs)

        elif file_type == 'html':
            # HTML: 转为 Markdown
            with open(file_path, 'r', encoding='utf-8') as f:
                h = html2text.HTML2Text()
                h.ignore_links = False
                return h.handle(f.read())

        else:  # md, txt
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
```

### 2. 智能分块器

**文件**: `apps/api/workers/chunker.py`

```python
"""
VibeLife 专用分块器
特点: 保持语义完整性，表格不拆分，保留层级路径
"""
import re
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class Chunk:
    content: str
    section_path: List[str]
    section_title: str
    chunk_index: int
    has_table: bool
    has_list: bool

class VibeLifeChunker:
    CHUNK_SIZE = 600
    CHUNK_OVERLAP = 80
    MIN_CHUNK_SIZE = 100
    MAX_CHUNK_SIZE = 1200

    def chunk(self, markdown: str) -> List[Chunk]:
        """三阶段分块"""
        # 阶段1: 解析结构
        sections = self._parse_structure(markdown)

        # 阶段2: 智能合并过小块
        merged = self._merge_small_sections(sections)

        # 阶段3: 拆分过长块
        chunks = self._split_large_sections(merged)

        return chunks

    def _parse_structure(self, markdown: str) -> List[dict]:
        """按 Markdown 标题解析层级结构"""
        sections = []
        current_path = []
        current_content = []
        current_level = 0

        for line in markdown.split('\n'):
            header_match = re.match(r'^(#{1,4})\s+(.+)$', line)

            if header_match:
                # 保存之前的内容
                if current_content:
                    sections.append({
                        'path': current_path.copy(),
                        'title': current_path[-1] if current_path else '',
                        'content': '\n'.join(current_content),
                        'level': current_level
                    })
                    current_content = []

                # 更新路径
                level = len(header_match.group(1))
                title = header_match.group(2).strip()

                if level > current_level:
                    current_path.append(title)
                elif level == current_level:
                    if current_path:
                        current_path[-1] = title
                    else:
                        current_path.append(title)
                else:
                    current_path = current_path[:level-1] + [title]

                current_level = level
            else:
                current_content.append(line)

        # 保存最后一块
        if current_content:
            sections.append({
                'path': current_path.copy(),
                'title': current_path[-1] if current_path else '',
                'content': '\n'.join(current_content),
                'level': current_level
            })

        return sections

    def _merge_small_sections(self, sections: List[dict]) -> List[dict]:
        """合并过小的块到父级"""
        merged = []
        buffer = None

        for section in sections:
            content_len = len(section['content'])

            if content_len < self.MIN_CHUNK_SIZE:
                if buffer:
                    buffer['content'] += '\n\n' + section['content']
                else:
                    buffer = section.copy()
            else:
                if buffer:
                    merged.append(buffer)
                    buffer = None
                merged.append(section)

        if buffer:
            merged.append(buffer)

        return merged

    def _split_large_sections(self, sections: List[dict]) -> List[Chunk]:
        """拆分过长的块"""
        chunks = []
        chunk_index = 0

        for section in sections:
            content = section['content']
            has_table = '|' in content and '---' in content
            has_list = bool(re.search(r'^[\-\*\d]\s', content, re.MULTILINE))

            # 表格不拆分
            if has_table or len(content) <= self.MAX_CHUNK_SIZE:
                chunks.append(Chunk(
                    content=content.strip(),
                    section_path=section['path'],
                    section_title=section['title'],
                    chunk_index=chunk_index,
                    has_table=has_table,
                    has_list=has_list
                ))
                chunk_index += 1
            else:
                # 在句子边界拆分
                sub_chunks = self._split_at_sentences(content)
                for sub in sub_chunks:
                    chunks.append(Chunk(
                        content=sub.strip(),
                        section_path=section['path'],
                        section_title=section['title'],
                        chunk_index=chunk_index,
                        has_table=False,
                        has_list=has_list
                    ))
                    chunk_index += 1

        return chunks

    def _split_at_sentences(self, text: str) -> List[str]:
        """在句子边界拆分长文本"""
        sentences = re.split(r'(?<=[。！？.!?])\s*', text)
        chunks = []
        current = ""

        for sentence in sentences:
            if len(current) + len(sentence) > self.CHUNK_SIZE:
                if current:
                    chunks.append(current)
                current = sentence
            else:
                current += sentence

        if current:
            chunks.append(current)

        return chunks
```

### 3. 后台 Worker (替代 Celery)

**文件**: `apps/api/workers/ingestion.py`

```python
"""
Knowledge Ingestion Worker - 基于 PG SKIP LOCKED 的任务队列
"""
import asyncio
import jieba
from .converters import DocumentConverter
from .chunker import VibeLifeChunker

class IngestionWorker:
    def __init__(self, pool, embedding_service):
        self.pool = pool
        self.embedding_service = embedding_service
        self.converter = DocumentConverter()
        self.chunker = VibeLifeChunker()

    async def run_loop(self):
        """后台循环：轮询 DB 队列，原子抢占任务"""
        print("🚀 Knowledge Ingestion Worker Started...")
        while True:
            try:
                async with self.pool.acquire() as conn:
                    task = await conn.fetchrow("""
                        UPDATE knowledge_documents
                        SET status = 'processing', updated_at = NOW()
                        WHERE id = (
                            SELECT id FROM knowledge_documents
                            WHERE status = 'pending'
                            ORDER BY created_at ASC
                            LIMIT 1
                            FOR UPDATE SKIP LOCKED
                        )
                        RETURNING id, file_path, file_type, skill_id
                    """)

                if not task:
                    await asyncio.sleep(2)
                    continue

                await self.process_document(task)

            except Exception as e:
                print(f"Worker Error: {e}")
                await asyncio.sleep(5)

    async def process_document(self, task):
        """核心处理流程"""
        try:
            # A. 多格式转 Markdown
            md_content = await self.converter.to_markdown(
                task['file_path'], task['file_type']
            )

            # B. 智能分块
            chunks = self.chunker.chunk(md_content)

            # C. 批量向量化
            chunk_texts = [c.content for c in chunks]
            embeddings = await self.embedding_service.embed_batch(chunk_texts)

            # D. Jieba 分词 + 入库
            insert_data = []
            for chunk, vec in zip(chunks, embeddings):
                seg_text = " ".join(jieba.cut_for_search(chunk.content))
                insert_data.append((
                    task['id'],
                    task['skill_id'],
                    chunk.chunk_index,
                    chunk.content,
                    chunk.section_path,
                    chunk.section_title,
                    chunk.has_table,
                    chunk.has_list,
                    seg_text,
                    str(vec)
                ))

            async with self.pool.acquire() as conn:
                async with conn.transaction():
                    await conn.executemany("""
                        INSERT INTO knowledge_chunks_v2
                        (document_id, skill_id, chunk_index, content,
                         section_path, section_title, has_table, has_list,
                         search_text_preprocessed, embedding)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                    """, insert_data)

                    await conn.execute("""
                        UPDATE knowledge_documents
                        SET status = 'completed', content_md = $1,
                            chunk_count = $2, updated_at = NOW()
                        WHERE id = $3
                    """, md_content, len(chunks), task['id'])

            print(f"✅ Processed: {task['file_path']} → {len(chunks)} chunks")

        except Exception as e:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    UPDATE knowledge_documents
                    SET status = 'failed', error_message = $1, updated_at = NOW()
                    WHERE id = $2
                """, str(e), task['id'])
            print(f"❌ Failed: {task['file_path']} - {e}")
```

### 4. 文件夹同步脚本

**文件**: `apps/api/scripts/sync_knowledge.py`

```python
"""
Knowledge Folder Sync - 每日凌晨 4:00 cron 触发
Usage: python scripts/sync_knowledge.py
"""
import asyncio
import hashlib
from pathlib import Path

SKILL_KNOWLEDGE_PATHS = {
    "bazi": "/home/aiscend/work/vibelife/knowledge/bazi",
    "zodiac": "/home/aiscend/work/vibelife/knowledge/zodiac",
    "mbti": "/home/aiscend/work/vibelife/knowledge/mbti"
}

# 支持的文件格式
SUPPORTED_EXTENSIONS = {'.pdf', '.md', '.txt', '.epub', '.docx', '.html'}

def compute_file_hash(filepath: str) -> str:
    with open(filepath, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()

async def sync_skill_folder(skill_id: str, folder_path: str, conn):
    """同步单个技能的知识文件夹"""
    path = Path(folder_path)
    if not path.exists():
        print(f"⚠️  Folder not found: {folder_path}")
        return

    # 1. 扫描文件系统
    current_files = {}
    for f in path.iterdir():
        if f.suffix.lower() in SUPPORTED_EXTENSIONS:
            current_files[f.name] = {
                'path': str(f),
                'hash': compute_file_hash(str(f)),
                'type': f.suffix[1:].lower()
            }

    # 2. 查询数据库现有记录
    db_records = await conn.fetch("""
        SELECT filename, file_hash, status FROM knowledge_documents
        WHERE skill_id = $1 AND status != 'archived'
    """, skill_id)
    db_files = {r['filename']: r for r in db_records}

    # 3. 新增文件
    for filename, info in current_files.items():
        if filename not in db_files:
            await conn.execute("""
                INSERT INTO knowledge_documents
                (skill_id, filename, file_path, file_hash, file_type, status)
                VALUES ($1, $2, $3, $4, $5, 'pending')
            """, skill_id, filename, info['path'], info['hash'], info['type'])
            print(f"✅ New: {filename}")

    # 4. 修改文件 (hash 变化)
    for filename, info in current_files.items():
        if filename in db_files and db_files[filename]['file_hash'] != info['hash']:
            await conn.execute("""
                DELETE FROM knowledge_chunks_v2
                WHERE document_id = (SELECT id FROM knowledge_documents WHERE skill_id = $1 AND filename = $2)
            """, skill_id, filename)
            await conn.execute("""
                UPDATE knowledge_documents
                SET file_hash = $3, status = 'pending', updated_at = NOW()
                WHERE skill_id = $1 AND filename = $2
            """, skill_id, filename, info['hash'])
            print(f"🔄 Modified: {filename}")

    # 5. 删除文件 → 软删除/归档
    for filename, record in db_files.items():
        if filename not in current_files and record['status'] != 'archived':
            await conn.execute("""
                UPDATE knowledge_documents
                SET status = 'archived', updated_at = NOW()
                WHERE skill_id = $1 AND filename = $2
            """, skill_id, filename)
            print(f"📦 Archived: {filename}")

async def main():
    from stores.db import get_db_pool, close_db_pool
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        for skill_id, folder in SKILL_KNOWLEDGE_PATHS.items():
            print(f"\n📂 Syncing {skill_id}: {folder}")
            await sync_skill_folder(skill_id, folder, conn)
    await close_db_pool()
    print("\n✅ Sync complete!")

if __name__ == "__main__":
    asyncio.run(main())
```

### 3. 更新 RetrievalService

**文件**: `apps/api/services/knowledge/retrieval.py` (修改)

```python
# 移除 Python 层 RRF，改用 SQL 函数
class RetrievalService:
    @classmethod
    async def search(cls, query: str, skill_id: str, top_k: int = 5) -> List[Dict]:
        # 1. Jieba 分词
        query_seg = " ".join(jieba.cut(query))

        # 2. 生成 query embedding
        query_embedding = await EmbeddingService.embed_query(query)

        # 3. 调用 SQL 函数 (RRF 在数据库完成)
        async with get_connection() as conn:
            results = await conn.fetch("""
                SELECT * FROM hybrid_search_v2($1, $2, $3, $4)
            """, query_seg, str(query_embedding), skill_id, top_k)

        return [dict(r) for r in results]
```

---

## Crontab 配置

```cron
# 文件: apps/api/scripts/crontab.example (追加)

# 知识库文件夹同步 - 每日凌晨 4:00
0 4 * * * cd /home/aiscend/work/vibelife/apps/api && python3 scripts/sync_knowledge.py >> /var/log/vibelife/knowledge_sync.log 2>&1
```

---

## 新增依赖

**文件**: `apps/api/requirements.txt` (追加)

```
# 中文分词
jieba>=0.42.1

# 多格式转换
pymupdf4llm>=0.0.17        # PDF → Markdown (保留表格)
ebooklib>=0.18             # EPUB 电子书
python-docx>=1.1.0         # DOCX Word 文档
html2text>=2024.2.26       # HTML → Markdown
beautifulsoup4>=4.12.0     # HTML 解析
```

---

## 实现任务清单 (按顺序)

### Phase 1: 数据库迁移
- [ ] 创建 `migrations/002_knowledge_v2.sql`
- [ ] 执行迁移：创建 `knowledge_documents` 表
- [ ] 执行迁移：创建 `knowledge_chunks_v2` 表
- [ ] 执行迁移：迁移旧 chunks 数据
- [ ] 执行迁移：创建 `hybrid_search_v2` SQL 函数
- [ ] 验证 HNSW 向量索引生效

### Phase 2: Worker 模块
- [ ] 安装依赖：`jieba`, `pymupdf4llm`, `ebooklib`, `python-docx`, `html2text`
- [ ] 创建 `apps/api/workers/__init__.py`
- [ ] 创建 `apps/api/workers/converters.py` (多格式转换器)
- [ ] 创建 `apps/api/workers/chunker.py` (智能分块器)
- [ ] 创建 `apps/api/workers/ingestion.py` (后台 Worker)
- [ ] 在 `main.py` lifespan 中启动 worker

### Phase 3: 文件夹同步
- [ ] 创建 `knowledge/bazi/`, `knowledge/zodiac/`, `knowledge/mbti/` 目录
- [ ] 创建 `scripts/sync_knowledge.py`
- [ ] 添加到 crontab (每日 4:00)

### Phase 4: 服务集成
- [ ] 修改 `services/knowledge/retrieval.py` 使用 SQL 函数
- [ ] 添加 jieba 分词到查询流程
- [ ] 移除 Python 层 RRF 逻辑
- [ ] 更新 `knowledge_repo.py` 适配新表

### Phase 5: 测试验证
- [ ] 上传测试文档 (PDF, EPUB, DOCX)
- [ ] 验证分块质量
- [ ] 验证检索效果

---

## 待修改文件清单

| 文件 | 操作 |
|------|------|
| `migrations/002_knowledge_v2.sql` | **新建** |
| `apps/api/workers/__init__.py` | **新建** |
| `apps/api/workers/converters.py` | **新建** |
| `apps/api/workers/chunker.py` | **新建** |
| `apps/api/workers/ingestion.py` | **新建** |
| `apps/api/scripts/sync_knowledge.py` | **新建** |
| `apps/api/requirements.txt` | 修改 (追加依赖) |
| `apps/api/main.py` | 修改 (启动 worker) |
| `apps/api/services/knowledge/retrieval.py` | 修改 (使用 SQL 函数) |
| `apps/api/stores/knowledge_repo.py` | 修改 (适配新表) |
| `apps/api/scripts/crontab.example` | 修改 (追加 cron)
