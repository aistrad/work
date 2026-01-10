# VibeLife - 资源配置

> 最后更新: 2026-01-10 | v3.0 Schema 已部署 | AI SDK 6 已集成 | 动态模型路由系统 | 数据目录重构 | Knowledge v2.0 目录结构 ✨

---

## 0. 部署架构

### 正式部署 (Production)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户浏览器                                      │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                      ┌───────────┴───────────┐
                      │     Cloudflare        │
                      │  (DNS + CDN + SSL)    │
                      │  vibelife.app 域名    │
                      └───────────┬───────────┘
                                  │
          ┌───────────────────────┴───────────────────────┐
          │                                               │
          ▼                                               ▼
┌─────────────────────────────┐           ┌─────────────────────────────────┐
│   Vercel / 阿里云香港        │           │      aiscend 服务器              │
│   (前端)                     │           │      (后端 + 数据库)             │
│                             │           │                                 │
│  vibelife.app        ───────┼───────────┼───► api.vibelife.app            │
│  bazi.vibelife.app          │   HTTPS   │     FastAPI + PostgreSQL        │
│  zodiac.vibelife.app        │   API     │     106.37.170.238              │
│  mbti.vibelife.app          │           │                                 │
└─────────────────────────────┘           └─────────────────────────────────┘
```

| 组件 | 提供商 | 说明 |
|------|--------|------|
| **域名** | Cloudflare | `vibelife.app` 注册和 DNS 管理 |
| **前端** | Vercel 或 阿里云香港 | Next.js SSR/SSG |
| **后端** | aiscend 服务器 | FastAPI + Docker |
| **数据库** | aiscend 服务器 | PostgreSQL 16 + pgvector |
| **CDN** | Cloudflare | 全球加速 + SSL |

### 域名规划

| 域名 | 用途 | 部署位置 |
|------|------|----------|
| `vibelife.app` | 主站 Landing | Vercel/阿里云 |
| `api.vibelife.app` | API 服务 | aiscend |
| `bazi.vibelife.app` | 八字站点 | Vercel/阿里云 |
| `zodiac.vibelife.app` | 星座站点 | Vercel/阿里云 |
| `mbti.vibelife.app` | MBTI 站点 (P1) | Vercel/阿里云 |
| `id.vibelife.app` | Vibe ID 认证中心 | Vercel/阿里云 |

---

## 0.1 临时测试部署

**服务器**: `106.37.170.238` (aiscend)

| 服务 | 端口 | 访问地址 |
|------|------|----------|
| **API 后端** | 8000 | `http://106.37.170.238:8000` |
| **主站 (vibelife)** | 8230 | `http://106.37.170.238:8230` |
| **八字站 (bazi)** | 8231 | `http://106.37.170.238:8231` |
| **星座站 (zodiac)** | 8232 | `http://106.37.170.238:8232` |

**测试启动命令**:
```bash
# 后端 API
cd /home/aiscend/work/vibelife/apps/api
export GLM_API_KEY="your-key"
export GLM_CHAT_MODEL="glm-4.7-flash"
export GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
export DEFAULT_LLM_PROVIDER="glm"
export VIBELIFE_DB_URL="postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife"
uvicorn main:app --port 8000 --host 0.0.0.0

# 主站前端
cd /home/aiscend/work/vibelife/apps/web
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=vibelife \
pnpm dev --port 8230

# 八字站前端
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=bazi \
pnpm dev --port 8231

# 星座站前端
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=zodiac \
pnpm dev --port 8232
```

---

## 1. 数据库

**PostgreSQL 16 (aiscend 服务器)** ✅ 已验证

| 配置项 | 值 |
|--------|-----|
| 主机 | `106.37.170.238` |
| 端口 | `8224` |
| 用户 | `postgres` |
| 密码 | `<REDACTED>` |
| 数据库 | `vibelife` |
| 连接字符串 | `postgresql://postgres:<REDACTED>@106.37.170.238:8224/vibelife` |

**v3.0 Schema 表 (核心)**:

| 表名 | 说明 |
|------|------|
| `users` | 用户核心表 (vibe_id) |
| `user_auth` | 认证方式表 (email, phone, google, apple) |
| `user_profiles` | 用户画像 (JSONB, 版本化) |
| `conversations` | 对话会话 |
| `messages` | 消息记录 |
| `reports` | 生成的报告 |
| `relationships` | 关系分析 |
| `insights` | LLM 生成的洞察 |
| `knowledge_chunks` | 知识库 (pgvector 1024维) |
| `subscription_plans` | 订阅计划 |
| `subscriptions` | 用户订阅 |
| `payments` | 支付记录 |
| `daily_greetings` | 每日问候缓存 |
| `user_events` | 用户事件 |

**Migration 文件**:
- `migrations/001_v3_schema.sql` - v3.0 数据库 Schema
- `migrations/002_interview_sessions.sql` - 访谈会话表
- `migrations/003_model_router.sql` - 模型路由系统
- `migrations/004_update_model_routes.sql` - 路由规则更新 (VIP/Pro→Gemini, 默认→GLM-4.7)
- `migrations/005_user_gender_voice_mode.sql` - 用户性别和人格字段

## 2. 智谱 GLM (对话)

**API 控制台**: https://bigmodel.cn/usercenter/equity-mgmt/user-rights

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` (环境变量: `GLM_API_KEY`) |
| 对话模型 | `glm-4.7` ✅ (全局默认) |
| Base URL | `https://open.bigmodel.cn/api/paas/v4` |

**API 文档**: https://docs.bigmodel.cn/cn/guide/models/text/glm-4.7

**代码支持**: LLM 配置同时支持 `GLM_*` 和 `ZHIPU_*` 环境变量前缀

## 3. Claude (备选)

| 配置项 | 值 |
|--------|-----|
| API Key | 需配置 `CLAUDE_API_KEY` |
| 模型 | `claude-opus-4-5-20251101` |

## 3.1 Google Gemini (对话 + 图像生成默认)

**API 端点**: OpenAI 兼容格式 (中转)

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` (环境变量: `GEMINI_API_KEY`) |
| Base URL | `https://api2.qiandao.mom/v1` |
| 对话模型 | `gemini-3-pro-preview` |
| 图像生成模型 | `gemini-3-pro-image-preview` ✅ 默认 |

**功能**:
- OpenAI 兼容 API 格式
- 支持 Chat Completions (`/chat/completions`)
- 支持 Image Generation (`/images/generations`)
- 流式响应 (SSE)

## 4. Embedding (默认 BAAI/bge-m3)

| 配置项 | 值 |
|--------|-----|
| 默认模型 | `BAAI/bge-m3` |
| 推理 | 本地 SentenceTransformers |
| **维度** | **1024** (pgvector vector) |
| 设备 | `cuda` (GPU 加速) |

## 5. Pinecone (向量存储 - 可选)

**控制台**: https://app.pinecone.io/

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` |
| 索引 | `vibelife-knowledge` |
| Host | `mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io` |
| 维度 | 1024 |
| Metric | `cosine` |

## 6. Stripe (支付)

| 配置项 | 值 |
|--------|-----|
| Secret Key | 需配置 `STRIPE_SECRET_KEY` |
| Publishable Key | 需配置 `STRIPE_PUBLISHABLE_KEY` |
| Webhook Secret | 需配置 `STRIPE_WEBHOOK_SECRET` |
| 控制台 | https://dashboard.stripe.com |

## 7. 服务分工总览

| 服务 | 提供商 | 模型/规格 | 状态 |
|------|--------|----------|------|
| **对话 (全局默认)** | **GLM** | **glm-4.7** | ✅ 默认 |
| 对话 (VIP/Pro) | Gemini | gemini-3-pro-preview | ✅ 动态路由 |
| **图像生成** | **Gemini** | **gemini-3-pro-image-preview** | ✅ **默认** |
| 向量嵌入 | BGE | BAAI/bge-m3 (1024维) | ✅ 已验证 |
| 向量存储 | PostgreSQL pgvector | 1024维 | ✅ 已验证 |
| 星盘计算 | swisseph | Swiss Ephemeris | ✅ 已配置 |
| 支付 | Stripe | Checkout + Subscription | ⏳ 待配置 |

## 7.1 模型路由系统 ✨

动态模型选择系统，支持按用户等级、任务类型、技能自动路由到最佳模型。

### 配置文件 (完全配置化) 🆕

所有模型配置现在统一在 `apps/api/config/models.yaml` 中管理，代码中无硬编码。

**配置优先级**：
1. 环境变量（最高）
2. `config/models.yaml` 配置文件
3. 数据库动态规则（用户层级、A/B测试）
4. 代码默认值（仅作为最终兜底）

**配置文件位置**: `apps/api/config/models.yaml`

```yaml
# 提供商配置
providers:
  glm:
    base_url: "${GLM_BASE_URL:https://open.bigmodel.cn/api/paas/v4}"
    api_key_env: "GLM_API_KEY"
  gemini:
    base_url: "${GEMINI_BASE_URL:https://new.12ai.org/v1}"
    api_key_env: "GEMINI_API_KEY"
    backup_urls: ["https://hk.12ai.org/v1", "https://api2.qiandao.mom/v1"]
  claude:
    base_url: "${CLAUDE_BASE_URL:https://www.zz166.cn/api}"
    api_key_env: "CLAUDE_API_KEY"

# 模型定义
models:
  glm-4-flash:
    provider: glm
    model_name: "${GLM_CHAT_MODEL:glm-4-flash}"
    capabilities: [chat]
  gemini-flash:
    provider: gemini
    model_name: "${GEMINI_CHAT_MODEL:gemini-2.5-flash}"
    capabilities: [chat, analysis]
  claude-opus:
    provider: claude
    model_name: "${CLAUDE_MODEL:claude-opus-4-5-20251101}"
    capabilities: [chat, analysis, vision]

# 默认路由（带 fallback 链）
defaults:
  chat:
    primary: gemini-flash
    fallback: [glm-4-flash, claude-opus]
  image_gen:
    primary: gemini-image
    fallback: []

# 全局兜底
global_fallback: glm-4-flash
```

### 便捷更新配置

```bash
# 列出当前配置
python apps/api/scripts/update_model_config.py --list

# 从 docs/apikey.md 同步
python apps/api/scripts/update_model_config.py --sync-from-docs

# 设置主力模型
python apps/api/scripts/update_model_config.py --set-primary chat claude-opus

# 验证配置
python apps/api/scripts/update_model_config.py --validate
```

### Fallback 触发条件

- **API 调用失败**：网络错误、超时、API 返回错误码（4xx/5xx）
- **配额超限**：当前模型配额用完时自动切换到下一个模型

### 路由规则（数据库动态配置）

| 优先级 | 规则名称 | 匹配条件 | 目标模型 | 降级链 |
|--------|----------|----------|----------|--------|
| 20 | 图像生成默认 | task=image_gen | gemini:gemini-image | - |
| 30 | VIP用户 | tier=vip | claude:claude-opus | gemini-flash → glm-4-flash |
| 35 | Pro用户 | tier=pro | gemini:gemini-flash | glm-4-flash |
| 100 | 全局默认 | - | gemini:gemini-flash | glm-4-flash |

### 配额规则

| 规则 | 范围 | 限制 | 超额处理 |
|------|------|------|----------|
| Gemini 全局日限 | provider=gemini | 5000次/天 | 降级到 glm-4-flash |
| Claude 全局日限 | provider=claude | 1000次/天 | 降级到 gemini-flash |
| 免费用户日限 | tier=free | 50次/天 | 拒绝 |
| 图像生成全局日限 | task=image_gen | 500张/天 | 拒绝 |

### 模型清单

| ID | 提供商 | 模型名 | 能力 |
|----|--------|--------|------|
| glm-4-flash | GLM | glm-4-flash | chat |
| glm-4.7 | GLM | glm-4.7 | chat, analysis |
| gemini-flash | Gemini | gemini-2.5-flash | chat, analysis |
| gemini-image | Gemini | gemini-2.5-flash-image | image_gen |
| claude-opus | Claude | claude-opus-4-5-20251101 | chat, analysis, vision |

### 代码位置

- **配置文件**: `apps/api/config/models.yaml`
- **配置加载器**: `apps/api/services/model_router/config.py`
- **统一客户端**: `apps/api/services/model_router/client.py`
- **路由器**: `apps/api/services/model_router/router.py`
- **更新脚本**: `apps/api/scripts/update_model_config.py`
- **Migration**: `migrations/003_model_router.sql`, `migrations/004_update_model_routes.sql`

## 8. 数据目录配置

数据目录位于独立数据盘 `/data/vibelife/`，便于生产环境管理。

| 目录 | 用途 | 环境变量 |
|------|------|----------|
| `/data/vibelife/` | 数据根目录 | `VIBELIFE_DATA_ROOT` |
| `/data/vibelife/knowledge/` | 知识库源文件 | `VIBELIFE_KNOWLEDGE_ROOT` |
| `/data/vibelife/uploads/` | 用户上传文件 | `VIBELIFE_UPLOADS_ROOT` |
| `/data/vibelife/cache/` | 缓存数据 | `VIBELIFE_CACHE_ROOT` |
| `/data/vibelife/logs/` | 日志文件 | `VIBELIFE_LOGS_ROOT` |

**知识库结构** (v2.0 新目录结构):
```
/data/vibelife/knowledge/
├── bazi/                      # 八字知识 → skill_id: "bazi"
│   ├── source/                # 源文件 (PDF, EPUB, DOCX 等)
│   │   ├── book1.pdf
│   │   └── notes.docx
│   └── converted/             # 转换后的 Markdown
│       ├── book1.converted.md
│       └── notes.converted.md
├── zodiac/                    # 星座知识 → skill_id: "zodiac"
│   ├── source/
│   └── converted/
└── mbti/                      # MBTI知识 → skill_id: "mbti"
    ├── source/
    └── converted/
```

**知识库管理命令**:
```bash
# 同步知识库（自动迁移旧文件到 source/ 目录）
python -m apps.api.scripts.sync_knowledge

# 同步指定技能
python -m apps.api.scripts.sync_knowledge --skill bazi

# 强制重新处理所有文件
python -m apps.api.scripts.sync_knowledge --force

# 运行入库 Worker
python -m apps.api.scripts.run_ingestion

# 查看统计
python -m apps.api.scripts.sync_knowledge --stats
```

**手动审核/校对流程**:
1. 运行同步，生成 `.converted.md` 文件
2. 打开 `knowledge/{skill}/converted/` 目录
3. 用编辑器修改 `.converted.md` 文件
4. 再次运行同步，系统自动检测变更并重新入库

## 9. 环境变量

完整环境变量已配置在 `/home/aiscend/work/vibelife/.env`

```bash
# ─────────────────────────────────────────────────────────────────
# VIBELIFE 环境变量 (v3.0)
# ─────────────────────────────────────────────────────────────────

# 数据库
VIBELIFE_DB_URL=postgresql://postgres:<REDACTED>@106.37.170.238:8224/vibelife

# JWT
VIBELIFE_JWT_SECRET=<REDACTED>
VIBELIFE_ACCESS_TOKEN_EXPIRE_MINUTES=60
VIBELIFE_REFRESH_TOKEN_EXPIRE_DAYS=30

# API 配置
VIBELIFE_API_PORT=8000
VIBELIFE_API_HOST=0.0.0.0
VIBELIFE_DEV=1

# CORS (测试环境)
VIBELIFE_CORS_ORIGINS=http://106.37.170.238:8230,http://106.37.170.238:8231,http://106.37.170.238:8232,http://localhost:3000

# 数据目录
VIBELIFE_DATA_ROOT=/data/vibelife
VIBELIFE_KNOWLEDGE_ROOT=/data/vibelife/knowledge
VIBELIFE_UPLOADS_ROOT=/data/vibelife/uploads
VIBELIFE_CACHE_ROOT=/data/vibelife/cache
VIBELIFE_LOGS_ROOT=/data/vibelife/logs

# 智谱 GLM (对话) - 支持 GLM_* 或 ZHIPU_* 前缀
GLM_API_KEY=<REDACTED>
GLM_CHAT_MODEL=glm-4.7
GLM_BASE_URL=https://open.bigmodel.cn/api/paas/v4

# Claude (备选)
CLAUDE_API_KEY=your-claude-api-key

# Google Gemini (图像生成默认)
GEMINI_API_KEY=<REDACTED>
GEMINI_BASE_URL=https://api2.qiandao.mom/v1
GEMINI_CHAT_MODEL=gemini-3-pro-preview
GEMINI_IMAGE_MODEL=gemini-3-pro-image-preview

# Embedding (默认 bge-m3)
EMBEDDING_MODEL_NAME=BAAI/bge-m3
EMBEDDING_DIMENSION=1024
EMBEDDING_DEVICE=cuda
EMBEDDING_LOCAL_DIR=/home/aiscend/.cache/vibelife/models/bge-m3

# Pinecone (可选)
PINECONE_API_KEY=<REDACTED>
PINECONE_HOST=mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io

# 默认提供商配置
DEFAULT_LLM_PROVIDER=glm    # 对话 (支持 'glm', 'zhipu', 'gemini', 'claude')
DEFAULT_IMAGE_PROVIDER=gemini  # 图像生成 (默认 gemini)

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# OAuth (Google/Apple)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key

# 前端配置
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000
NEXT_PUBLIC_API_BASE=http://106.37.170.238:8000/api/v1
```

## 9. API 端点测试结果

| 端点 | 方法 | 状态 |
|------|------|------|
| `/health` | GET | ✅ 通过 |
| `/api/v1/chat/guest` | POST | ✅ 通过 (LLM 响应) |
| `/api/v1/chat/interview/start` | POST | ✅ 通过 |
| `/api/v1/chat/interview/answer` | POST | ✅ 通过 |
| `/api/v1/fortune/cycles` | GET | ✅ 通过 |
| `/api/v1/fortune/greeting` | POST | ✅ 通过 |
| `/api/v1/fortune/kline` | POST | ✅ 通过 |
| `/api/v1/relationship/analyze` | POST | ✅ 通过 |
| `/api/v1/report/preview` | POST | ✅ 通过 |

## 10. 启动命令

### 测试环境 (单机多端口)

```bash
# 1. 启动后端 API (端口 8000)
cd /home/aiscend/work/vibelife/apps/api
source /home/aiscend/work/vibelife/.env
uvicorn main:app --port 8000 --host 0.0.0.0 --reload

# 2. 启动主站前端 (端口 8230)
cd /home/aiscend/work/vibelife/apps/web
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 pnpm dev --port 8230

# 3. 启动八字站 (端口 8231) - 新终端
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=bazi pnpm dev --port 8231

# 4. 启动星座站 (端口 8232) - 新终端
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=zodiac pnpm dev --port 8232
```

### 健康检查

```bash
# API
curl http://106.37.170.238:8000/health

# 主站
curl http://106.37.170.238:8230

# 八字站
curl http://106.37.170.238:8231

# 星座站
curl http://106.37.170.238:8232
```

## 11. 项目结构

```
/home/aiscend/work/vibelife/
├── apps/
│   ├── api/                     # FastAPI 后端
│   │   ├── main.py              # 应用入口 (74 路由)
│   │   ├── requirements.txt     # Python 依赖
│   │   ├── routes/              # API 路由
│   │   │   ├── auth.py          # 认证
│   │   │   ├── chat.py          # 对话 (核心)
│   │   │   ├── report.py        # 报告生成
│   │   │   ├── fortune.py       # 运势/K-Line
│   │   │   ├── relationship.py  # 关系分析
│   │   │   └── ...
│   │   ├── services/            # 业务服务
│   │   │   ├── vibe_engine/     # 核心 AI 引擎
│   │   │   │   ├── llm.py       # LLM 服务
│   │   │   │   ├── context.py   # 上下文构建
│   │   │   │   └── portrait.py  # 用户画像
│   │   │   ├── model_router/    # 动态模型路由 ✨
│   │   │   │   ├── router.py    # 路由核心逻辑
│   │   │   │   ├── quota.py     # 配额管理
│   │   │   │   ├── cache.py     # 内存缓存
│   │   │   │   ├── repository.py # 数据库操作
│   │   │   │   └── models.py    # 数据模型
│   │   │   ├── interview/       # 访谈系统
│   │   │   ├── report/          # 报告生成
│   │   │   ├── fortune/         # 运势计算
│   │   │   ├── greeting/        # 每日问候
│   │   │   └── relationship/    # 关系分析
│   │   ├── stores/              # 数据存储
│   │   │   ├── db.py            # 数据库连接
│   │   │   ├── conversation_repo.py
│   │   │   ├── message_repo.py
│   │   │   └── profile_repo.py
│   │   └── tools/               # 专业工具
│   │       ├── bazi/            # 八字计算
│   │       └── zodiac/          # 星盘计算
│   │
│   └── web/                     # Next.js 14 前端
│       ├── package.json         # ai@6.0.20, @ai-sdk/react@3.0.20
│       ├── tailwind.config.ts
│       └── src/
│           ├── app/
│           │   ├── page.tsx             # 品牌首页 (Skill 选择器)
│           │   ├── api/chat/route.ts    # AI SDK 6 Data Stream Protocol ✨
│           │   ├── bazi/                # 八字路由组 ✨
│           │   │   ├── page.tsx         # Bazi Landing
│           │   │   ├── chat/page.tsx    # Bazi Chat
│           │   │   ├── relationship/    # Bazi 关系
│           │   │   └── report/          # Bazi 报告
│           │   ├── zodiac/              # 星座路由组 ✨
│           │   │   ├── page.tsx         # Zodiac Landing
│           │   │   ├── chat/page.tsx    # Zodiac Chat
│           │   │   ├── relationship/    # Zodiac 关系
│           │   │   └── report/          # Zodiac 报告
│           │   ├── chat/page.tsx        # 旧链接重定向
│           │   └── ...
│           ├── hooks/
│           │   └── useVibeChat.ts       # AI SDK 6 useChat 封装 ✨
│           ├── components/
│           │   ├── core/        # LUMINOUS PAPER 设计系统
│           │   ├── chat/        # 对话组件 (AI SDK 6 集成)
│           │   ├── layout/
│           │   │   ├── AppShell.tsx      # 主布局
│           │   │   └── ResizablePanel.tsx # 可调节边栏 ✨
│           │   ├── ui/          # UI 基础组件
│           │   └── insight/     # 洞察面板
│           └── lib/             # API 客户端
│
├── migrations/
│   ├── 001_v3_schema.sql        # v3.0 数据库 Schema
│   ├── 002_interview_sessions.sql # 访谈会话
│   ├── 003_model_router.sql     # 模型路由系统 ✨
│   └── 004_update_model_routes.sql # 路由规则更新 ✨
│
├── deploy/
│   ├── aiscend/                 # 后端部署配置
│   └── aliyun/                  # 前端部署配置
│
├── docs/                        # 文档
│   ├── vibelife spec v3.0.md   # 产品规格
│   ├── config.md               # 本文件
│   └── deployment.md           # 部署指南
│
├── .env                         # 环境变量
└── docker-compose.yml           # 本地开发

# 数据目录 (独立数据盘)
/data/vibelife/
├── knowledge/                   # 知识库源文件
│   ├── bazi/                   # 八字知识
│   ├── zodiac/                 # 星座知识
│   └── mbti/                   # MBTI知识
├── uploads/                     # 用户上传文件
├── cache/                       # 缓存数据
└── logs/                        # 日志文件
```

> ✨ = 2026-01-08 新增/更新

## 12. 功能状态

### P0 (核心功能) - ✅ 已完成

- [x] 多技能对话系统 (Bazi/Zodiac)
- [x] SSE 流式响应
- [x] 语音模式切换 (暖心闺蜜/毒舌损友/人生导师)
- [x] 智能访谈系统
- [x] 报告生��� (Lite/Full Preview)
- [x] 人生 K-Line 可视化
- [x] 大运周期计算
- [x] 每日问候
- [x] 关系分析 & Vibe Link
- [x] 文件上传提取
- [x] 用户注册 (邮箱+密码 / 手机号+密码)
- [x] OAuth 登录 (Google / Apple)

### UX 优化 (2026-01-08) - ✅ 已完成

- [x] **Phase 1**: 前端架构重构 - bazi/zodiac 路由组
- [x] **Phase 2**: 聊天页布局优化 - ResizablePanel (320-600px)
- [x] **Phase 3**: AI SDK 6 升级 - useChat + Data Stream Protocol
- [x] **Phase 4**: 冗余代码清理 - 删除重复组件

### P1 (待开发)

- [ ] 主动推送 (Daily Push)
- [ ] Mirror 周/月回顾
- [ ] MBTI 技能
- [ ] 语音交互
- [ ] Clerk 认证迁移
- [ ] Stripe/Airwallex 支付完善

## 13. 下一步

1. **测试部署**: 在 aiscend 服务器上启动测试环境
2. **域名配置**: Cloudflare 配置 vibelife.app DNS
3. **SSL 证书**: Let's Encrypt 申请证书
4. **正式部署**: 前端部署到 Vercel/阿里云
