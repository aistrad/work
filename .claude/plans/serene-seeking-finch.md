# Plan: 更新 Embedding 模型为 GTE-Qwen2

## 目标
将 embedding 服务从 Google Gemini 切换到 Alibaba-NLP/gte-Qwen2-7B-instruct

## 已完成
- [x] 更新 `/home/aiscend/work/vibelife/apps/api/services/knowledge/embedding.py`（用户已修改）

## 待执行

### 1. 数据库更新
- 更新 vector 维度为 3584
- 更新 hybrid_search_v2 和 vector_search_v2 函数
- 重置所有文档状态

### 2. 文档更新（排除 archive/）
需要更新以下文档中的 Gemini embedding 相关内容：

| 文件 | 更新内容 |
|------|----------|
| `docs/config.md` | 环境变量配置 |
| `docs/deployment.md` | 部署说明 |
| `docs/knowledge-system-plan.md` | 知识系统架构 |
| `docs/skill-development.md` | Skill 开发指南 |
| `docs/architecture-gap-analysis.md` | 架构分析 |
| `docs/vibelife spec v2.0.md` | 规格文档 |
| `docs/vibelife spec v2.1.md` | 规格文档 |

### 3. 环境变量更新
新环境变量：
```
EMBEDDING_MODEL_NAME=Alibaba-NLP/gte-Qwen2-7B-instruct
EMBEDDING_DIMENSION=3584
EMBEDDING_DEVICE=auto
EMBEDDING_BATCH_SIZE=16
```

移除旧环境变量：
```
GEMINI_API_KEY (embedding 用)
GEMINI_EMBEDDING_MODEL
GEMINI_EMBEDDING_DIMENSION
```
