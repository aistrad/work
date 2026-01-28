# VibeLife - 资源配置

> 最后更新: 2026-01-05 | Phase 14 完成

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
| **数据库** | aiscend 服务器 | PostgreSQL + pgvector |
| **CDN** | Cloudflare | 全球加速 + SSL |

### 域名规划

| 域名 | 用途 | 部署位置 |
|------|------|----------|
| `vibelife.app` | 主站 Landing | Vercel/阿里云 |
| `api.vibelife.app` | API 服务 | aiscend |
| `bazi.vibelife.app` | 八字站点 | Vercel/阿里云 |
| `zodiac.vibelife.app` | 星座站点 | Vercel/阿里云 |
| `mbti.vibelife.app` | MBTI 站点 | Vercel/阿里云 |
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

**PostgreSQL (aiscend 服务器)** ✅ 已验证

| 配置项 | 值 |
|--------|-----|
| 主机 | `106.37.170.238` |
| 端口 | `8224` |
| 用户 | `postgres` |
| 密码 | `<REDACTED>` |
| 数据库 | `vibelife` |
| 连接字符串 | `postgresql://postgres:<REDACTED>@106.37.170.238:8224/vibelife` |

**已创建表 (14个)**:
- `vibe_users` - 用户核心表
- `vibe_user_auth` - 认证方式表
- `vibe_data_consents` - 数据共享授权表
- `skill_profiles` - Skill Profile
- `skill_conversations` - 对话记录
- `skill_messages` - 消息记录
- `skill_insights` - 洞察记录
- `subscription_plans` - 订阅计划
- `user_subscriptions` - 用户订阅状态
- `knowledge_chunks` - 知识块 (含 pgvector 3072维)
- `knowledge_qa_pairs` - QA 对
- `fortune_events` - 运势事件日历
- `reminder_settings` - 提醒设置
- `user_notifications` - 用户通知记录

## 2. 智谱 GLM (对话/图片)

**API 控制台**: https://bigmodel.cn/usercenter/equity-mgmt/user-rights

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` |
| 对话模型 | `glm-4.7` ✅ (最新旗舰) |
| 图片理解 | `glm-4.6v` ✅ (最新视觉) |
| Base URL | `https://open.bigmodel.cn/api/paas/v4` |

**API 文档**: https://docs.bigmodel.cn/cn/guide/models/text/glm-4.7

## 3. Claude (备选)

| 配置项 | 值 |
|--------|-----|
| API Key | 需配置 `CLAUDE_API_KEY` |
| 模型 | `claude-3-5-sonnet-20241022` |

## 4. Google Gemini (Embedding)

**申请地址**: https://aistudio.google.com/app/apikey

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` |
| 模型 | `gemini-embedding-001` |
| **维度** | **3072** |

## 5. Pinecone (向量存储)

**控制台**: https://app.pinecone.io/

| 配置项 | 值 |
|--------|-----|
| API Key | `<REDACTED>` |
| 索引 | `mentis-streams` (可复用) / `vibelife-knowledge` (新建) |
| Host | `mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io` |
| **维度** | **3072** (与 Gemini 匹配) |
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
| 对话生成 | GLM | glm-4.7 | ✅ 已验证 |
| 图片理解 | GLM | glm-4.6v | ✅ 已配置 |
| 向量嵌入 | Gemini | gemini-embedding-001 (3072维) | ✅ 已验证 |
| 向量存储 | Pinecone | mentis-streams (3072维) | ✅ 已验证 |
| 星盘计算 | swisseph | Swiss Ephemeris | ✅ 已配置 |
| 支付 | Stripe | Checkout + Subscription | ⏳ 待配置 |

## 8. 环境变量

完整环境变量已配置在 `/home/aiscend/work/vibelife/.env`

```bash
# ─────────────────────────────────────────────────────────────────
# VIBELIFE 环境变量
# ─────────────────────────────────────────────────────────────────

# 数据库
VIBELIFE_DB_URL=postgresql://postgres:<REDACTED>@106.37.170.238:8224/vibelife

# JWT
VIBELIFE_JWT_SECRET=<REDACTED>

# CORS (测试环境)
VIBELIFE_CORS_ORIGINS=http://106.37.170.238:8230,http://106.37.170.238:8231,http://106.37.170.238:8232,http://localhost:3000

# 智谱 GLM (对话/图片)
GLM_API_KEY=<REDACTED>
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.6v

# Claude (备选)
CLAUDE_API_KEY=your-claude-api-key

# Google Gemini (Embedding)
GEMINI_API_KEY=<REDACTED>
GEMINI_EMBEDDING_MODEL=gemini-embedding-001

# Pinecone
PINECONE_API_KEY=<REDACTED>
PINECONE_HOST=mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# 默认 LLM 提供商
DEFAULT_LLM_PROVIDER=glm
```

## 9. 启动命令

### 测试环境 (单机多端口)

```bash
# 1. 启动后端 API (端口 8000)
cd /home/aiscend/work/vibelife/apps/api
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

## 10. 项目结构

```
/home/aiscend/work/vibelife/
├── apps/
│   ├── api/                     # FastAPI 后端
│   │   ├── main.py              # 应用入口
│   │   ├── requirements.txt     # Python 依赖
│   │   ├── Dockerfile
│   │   ├── routes/              # API 路由
│   │   ├── services/            # 业务服务
│   │   ├── tools/               # 专业工具
│   │   └── tests/               # 测试
│   │
│   └── web/                     # Next.js 14 前端
│       ├── package.json
│       ├── tailwind.config.ts
│       ├── Dockerfile
│       └── src/
│           ├── app/             # 页面
│           ├── components/      # 组件
│           └── lib/             # 工具库
│
├── deploy/
│   ├── aiscend/                 # 后端部署配置
│   │   ├── docker-compose.yml
│   │   ├── nginx/
│   │   └── scripts/
│   └── aliyun/                  # 前端部署配置
│       ├── README.md
│       └── vercel.json
│
├── k8s/                         # Kubernetes 配置 (备用)
├── docs/                        # 文档
├── migrations/                  # 数据库迁移
├── .github/workflows/           # CI/CD
├── .env                         # 环境变量
└── docker-compose.yml           # 本地开发
```

## 11. 进度状态

- [x] Phase 0: 项目初始化 ✅ 2026-01-05
- [x] Phase 1: 数据层完善 ✅
- [x] Phase 2: Vibe ID 统一身份系统 ✅
- [x] Phase 3: 核心引擎层 (Vibe Engine) ✅
- [x] Phase 4: 知识引擎层 ✅
- [x] Phase 5: Skill Agent 层 ✅
- [x] Phase 6: Skill 工具函数系统 ✅
- [x] Phase 7: 体验层 ✅
- [x] Phase 8: 独立站点层 (部分) ✅
- [x] Phase 9: 主动智能系统 ✅
- [x] Phase 10: Skill Mirror 系统 ✅
- [x] Phase 11: 商业化系统 ✅
- [x] Phase 12: 测试框架 ✅
- [x] Phase 13: 文档 ✅
- [x] Phase 14: 部署配置 ✅

## 12. 下一步

1. **测试部署**: 在 aiscend 服务器上启动测试环境
2. **域名配置**: Cloudflare 配置 vibelife.app DNS
3. **SSL 证书**: Let's Encrypt 申请证书
4. **正式部署**: 前端部署到 Vercel/阿里云
