---
name: vibeknowledge
description: VibeLife 知识库管理；用于同步和处理 bazi/zodiac/mbti 等 skill 的知识文档；支持文档扫描、向量化入库与统计查看；默认先同步再处理。
---

# Overview and Intent

## 0. 适用场景与核心目标

- **适用对象**：VibeLife 项目开发者，需要管理知识库内容
- **核心目标**：
  1) 扫描 `knowledge/` 目录，检测新增/变更文档
  2) 启动 Ingestion Worker 处理待处理文档
  3) 查看知识库处理统计

## 1. 知识库结构

```
/data/vibelife/knowledge/
├── bazi/       # 八字知识 → skill_id: "bazi"
├── zodiac/     # 星座知识 → skill_id: "zodiac"
└── mbti/       # MBTI知识 → skill_id: "mbti" (P1)
```

**支持格式**：`.md`, `.txt`, `.pdf`, `.epub`, `.docx`, `.html`

## 2. 处理流程

1. **Sync**: 扫描文件夹，注册文档到数据库（status: pending）
2. **Ingest**: Worker 处理 pending 文档
   - 格式转换 → Markdown
   - 智能分块（SmartChunker）
   - Jieba 中文分词
   - **BAAI/bge-m3 Embedding 向量化（1024维，本地推理）**
   - 存入 PostgreSQL + pgvector
3. **Retrieve**: 通过 RetrievalService 检索（Vector + FTS + RRF）

---

# Quick Start

1) 将知识文档放入 `/data/vibelife/knowledge/<skill_id>/` 目录
2) 执行 `/vibeknowledge` 完成扫描+处理（一键完成）

**分步执行：**
- `/vibeknowledge sync` - 只扫描，不处理
- `/vibeknowledge ingest` - 只处理 pending 文档
- `/vibeknowledge stats` - 查看统计

---

# Workflows

## Workflow 0：默认（sync + ingest）

**命令**：
```bash
/vibeknowledge                         # 扫描 + 处理（一键完成）
/vibeknowledge --skill bazi            # 只处理八字
```

## Workflow 1：同步知识文档 (sync)

**触发**：只想扫描不处理时

**命令**：
```bash
/vibeknowledge sync                    # 扫描所有 skill
/vibeknowledge sync --skill bazi       # 只扫描八字
/vibeknowledge sync --force            # 强制重新处理所有
/vibeknowledge sync --stats            # 仅查看统计
```

**步骤**：
1. 扫描 `/data/vibelife/knowledge/` 下所有 skill 文件夹
2. 计算文件 MD5 hash，检测变更
3. 新文件/变更文件标记为 `pending`
4. 删除的文件标记为 `archived`
5. 输出统计信息

**输出**：
- 新增/更新/归档/未变更的文件数量
- 各 skill 的文档状态

## Workflow 2：处理文档 (ingest)

**触发**：有 pending 文档需要处理

**命令**：
```bash
/vibeknowledge ingest                  # 启动 worker
```

**步骤**：
1. 从队列获取 pending 文档（SKIP LOCKED）
2. 转换为 Markdown
3. 智能分块
4. 生成 embedding（bge-m3, 1024维）
5. 存入数据库
6. 标记为 completed

**输出**：
- 处理进度日志
- 完成统计

## Workflow 3：查看统计 (stats)

**触发**：用户想查看知识库状态

**命令**：
```bash
/vibeknowledge stats
```

**输出**：
```
Knowledge Base Statistics:
----------------------------------------------------------------------
Skill        Pending    Processing   Completed    Failed   Chunks
----------------------------------------------------------------------
bazi         0          0            5            0        128
zodiac       3          0            0            0        0
mbti         0          0            2            0        45
```

---

# Reference Documentation

## A. 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `VIBELIFE_ROOT` | 项目根目录 | `/home/aiscend/work/vibelife` |
| `VIBELIFE_DATA_ROOT` | 数据根目录 | `/data/vibelife` |
| `VIBELIFE_KNOWLEDGE_ROOT` | 知识库目录 | `/data/vibelife/knowledge` |
| `VIBELIFE_DB_URL` | PostgreSQL 连接字符串 | 必需 |
| `EMBEDDING_MODEL_NAME` | Embedding 模型 | `BAAI/bge-m3` |
| `EMBEDDING_DIMENSION` | 向量维度 | `1024` |
| `EMBEDDING_DEVICE` | 推理设备 | `auto` (cuda/cpu) |
| `EMBEDDING_LOCAL_DIR` | 本地模型缓存目录 | 可选 |
| `EMBEDDING_BATCH_SIZE` | 批处理大小 | `16` |

## B. 数据库表 (v3.0 Schema)

- `knowledge_documents`: 文档元数据（id, skill_id, filename, status, hash...）
- `knowledge_chunks`: 文档分块（content, embedding vector(1024), metadata...）

**Schema 位置**: `migrations/001_v3_schema.sql`

## C. 相关文件

| 文件 | 说明 |
|------|------|
| `apps/api/scripts/sync_knowledge.py` | 同步脚本 |
| `apps/api/workers/ingestion.py` | Ingestion Worker |
| `apps/api/workers/chunker.py` | 智能分块器 |
| `apps/api/workers/converters.py` | 格式转换器 |
| `apps/api/services/knowledge/retrieval.py` | 检索服务 |
| `apps/api/services/knowledge/embedding.py` | Embedding 服务 |

## D. Embedding 配置详情

```python
# apps/api/services/knowledge/embedding.py
class EmbeddingService:
    MODEL_NAME = os.getenv("EMBEDDING_MODEL_NAME", "BAAI/bge-m3")
    TARGET_DIMENSION = int(os.getenv("EMBEDDING_DIMENSION", "1024"))
    DEVICE = os.getenv("EMBEDDING_DEVICE", "auto")  # auto | cuda | cpu
    BATCH_SIZE = int(os.getenv("EMBEDDING_BATCH_SIZE", "16"))
    LOCAL_DIR = os.getenv("EMBEDDING_LOCAL_DIR")  # 可选，本地缓存
```

**特性**：
- 本地推理，无需外部 API
- 支持 GPU 加速（CUDA）
- 自动维度适配（截断/填充到 1024）

---

# Examples

## Example 1：添加八字知识

```bash
# 1. 准备文档
cp 天干地支.md /data/vibelife/knowledge/bazi/

# 2. 同步
/vibeknowledge sync --skill bazi
# Output: + NEW: 天干地支.md

# 3. 处理
/vibeknowledge ingest

# 4. 验证
/vibeknowledge stats
```

## Example 2：批量添加星座知识

```bash
# 1. 复制多个文档
cp zodiac_docs/*.pdf /data/vibelife/knowledge/zodiac/

# 2. 同步所有
/vibeknowledge sync
# Output:
#   Skill: zodiac
#   Found 12 files
#   + NEW: astrology_guide.pdf
#   + NEW: planets_in_transit.pdf
#   ...

# 3. 启动处理
/vibeknowledge ingest
```

## Example 3：强制重新处理

```bash
# 文档内容更新后，强制重新生成 embedding
/vibeknowledge sync --skill bazi --force
/vibeknowledge ingest
```

## Example 4：查看当前知识库状态

```bash
# 查看所有 skill 的统计
/vibeknowledge stats

# 当前知识文件：
# - /data/vibelife/knowledge/bazi/: 2 个 PDF（八字教材）
# - /data/vibelife/knowledge/zodiac/: 12 个 PDF（星座书籍）
```

---

# Troubleshooting Guide

## 常见问题

**Q: 文档未被检测到？**
A: 检查文件扩展名是否在支持列表（.md/.txt/.pdf/.epub/.docx/.html）

**Q: Embedding 生成失败？**
A: 检查：
1. `sentence-transformers` 是否安装
2. CUDA 是否可用（如使用 GPU）
3. 模型是否已下载到本地

**Q: 处理卡住？**
A:
1. 查看 worker 日志
2. 检查数据库连接
3. 确认 `VIBELIFE_DB_URL` 环境变量正确

**Q: 如何重新处理单个文件？**
A: 修改文件内容（触发 hash 变更）或使用 `--force`

**Q: 如何检查 embedding 配置？**
A:
```bash
cd /home/aiscend/work/vibelife/apps/api
python -c "
from services.knowledge.embedding import EmbeddingService
print(f'Model: {EmbeddingService.MODEL_NAME}')
print(f'Dimension: {EmbeddingService.TARGET_DIMENSION}')
print(f'Device: {EmbeddingService.DEVICE}')
"
```

---

# Changelog

## 2026-01-09
- 重构知识库目录：`vibelife/knowledge/` → `/data/vibelife/knowledge/`
- 新增环境变量：`VIBELIFE_DATA_ROOT`, `VIBELIFE_KNOWLEDGE_ROOT`
- 更新所有路径引用和示例

## 2026-01-07
- 更新 Embedding 配置：Gemini → BAAI/bge-m3 (本地推理)
- 更新向量维度：1536 → 1024
- 更新数据库表名：knowledge_chunks_v2 → knowledge_chunks (v3 schema)
- 更新环境变量文档
- 添加 Embedding 配置详情和故障排查

## 2026-01-06
- 初始版本
- 支持 sync/ingest/stats 三个 workflow
- 支持 bazi/zodiac/mbti 三个 skill
