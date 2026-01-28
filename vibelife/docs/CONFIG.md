# VibeLife 配置参考

> **版本**: v6.8 | **更新**: 2026-01-17

## 服务架构

| 组件 | 技术栈 | 端口 |
|------|--------|------|
| 后端 API | FastAPI + Python 3.13 | 8000 |
| 前端 Web | Next.js 14 + React 18 | 3000/8230 |
| 数据库 | PostgreSQL 16 + pgvector | 8224 |

## 数据库

| 配置项 | 值 |
|--------|-----|
| 主机 | `106.37.170.238` |
| 端口 | `8224` |
| 数据库 | `vibelife` |
| 连接串 | `postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife` |

**核心表**:
- `vibe_users` - 用户
- `unified_profiles` - 用户画像 (JSONB)
- `conversations` / `messages` - 对话
- `knowledge_chunks` - 知识库 (pgvector 1024维)
- `cases` / `scenarios` - 专家系统

## LLM 配置

**配置文件**: `apps/api/config/models.yaml` (唯一配置源)

**默认路由顺序**: deepseek → glm → claude

| 提供商 | 模型 | 用途 | 环境变量 |
|--------|------|------|----------|
| DeepSeek | deepseek-chat | 主力对话 | `DEEPSEEK_API_KEY` |
| GLM | glm-4.7 | 备选对话 | `GLM_API_KEY` |
| Claude | claude-opus-4-5 | 备选对话 | `CLAUDE_API_KEY` |
| Gemini | gemini-image | 图像生成 | `GEMINI_API_KEY` |

```yaml
# config/models.yaml 核心配置
defaults:
  chat:
    primary: deepseek-v3
    fallback: [glm-4.7, claude-opus]
  image_gen:
    primary: gemini-image
global_fallback: glm-4.7
```

## 向量嵌入

| 配置项 | 值 |
|--------|-----|
| 模型 | `BAAI/bge-m3` |
| 维度 | `1024` |
| 推理 | 本地 SentenceTransformers (CUDA) |
| 存储 | PostgreSQL pgvector |

```bash
EMBEDDING_MODEL_NAME=BAAI/bge-m3
EMBEDDING_DIMENSION=1024
EMBEDDING_DEVICE=cuda
EMBEDDING_LOCAL_DIR=/home/aiscend/.cache/vibelife/models/bge-m3
```

## 数据目录

```
/data/vibelife/
├── knowledge/     # 知识库源文件
│   ├── bazi/
│   ├── zodiac/
│   └── career/
├── uploads/       # 用户上传
├── cache/         # 缓存
└── logs/          # 日志
```

## API 路由 (v6.8)

| 路由 | 说明 |
|------|------|
| `/health` | 健康检查 |
| `/api/v1/chat/*` | 对话 (SSE) |
| `/api/v1/tools/*` | 工具调用 |
| `/api/v1/skills/*` | Skill Gateway |
| `/api/v1/account/*` | 用户账户 |
| `/api/v1/commerce/*` | 支付订阅 |
| `/api/v1/vibe-id/*` | VibeID |

## 项目结构 (v6.8)

```
apps/api/
├── main.py                    # 入口 (7 路由)
├── config/models.yaml         # LLM 配置 (唯一源)
├── routes/                    # API 路由
│   ├── chat_v5.py            # 对话 (CoreAgent)
│   ├── skills.py             # Skill Gateway
│   ├── account.py            # 账户
│   └── commerce.py           # 支付
├── services/
│   ├── agent/                # CoreAgent + ToolRegistry
│   ├── llm/                  # LLM 客户端
│   ├── knowledge/            # RAG 检索
│   └── proactive/            # 主动推送
├── skills/                   # Skill 定义 (DDD)
│   ├── bazi/
│   │   ├── SKILL.md
│   │   ├── services/         # 领域服务
│   │   ├── tools/            # 工具定义
│   │   └── scenarios/        # 场景
│   ├── zodiac/
│   ├── tarot/
│   └── career/
└── stores/                   # 数据访问层

apps/web/src/
├── app/                      # Next.js App Router
├── components/               # React 组件
├── hooks/useVibeChat.ts      # AI SDK 6 集成
└── skills/                   # 前端 Skill 卡片
```

## 环境变量

完整配置见 `.env.example`，核心变量：

```bash
# 数据库
VIBELIFE_DB_URL=postgresql://postgres:<PASSWORD>@<HOST>:8224/vibelife

# LLM
DEEPSEEK_API_KEY=<KEY>
GLM_API_KEY=<KEY>
CLAUDE_API_KEY=<KEY>
GEMINI_API_KEY=<KEY>

# 向量嵌入
EMBEDDING_MODEL_NAME=BAAI/bge-m3
EMBEDDING_DIMENSION=1024

# JWT
VIBELIFE_JWT_SECRET=<SECRET>

# CORS
VIBELIFE_CORS_ORIGINS=http://localhost:3000,https://vibelife.app

# 数据目录
VIBELIFE_DATA_ROOT=/data/vibelife
```

## 健康检查

```bash
# API
curl http://localhost:8000/health

# 数据库
psql $VIBELIFE_DB_URL -c "SELECT 1"

# pgvector
psql $VIBELIFE_DB_URL -c "SELECT vector_dims('[1,2,3]'::vector)"
```

## 支付 (Stripe)

| 配置项 | 环境变量 |
|--------|----------|
| Secret Key | `STRIPE_SECRET_KEY` |
| Publishable Key | `STRIPE_PUBLISHABLE_KEY` |
| Webhook Secret | `STRIPE_WEBHOOK_SECRET` |

详见 `docs/archive/v5/stripe-best-practices.md`
