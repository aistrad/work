# VibeLife 部署指南

> 最后更新: 2026-01-05

---

## 部署架构

### 正式部署架构 (Production)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户浏览器                                      │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                      ┌───────────┴───────────┐
                      │     Cloudflare        │
                      │  vibelife.app 域名    │
                      │  DNS + CDN + SSL      │
                      └───────────┬───────────┘
                                  │
          ┌───────────────────────┴───────────────────────┐
          │                                               │
          ▼                                               ▼
┌─────────────────────────────┐           ┌─────────────────────────────────┐
│   Vercel / 阿里云香港        │           │      aiscend 服务器              │
│   (前端 - Next.js)          │           │      106.37.170.238             │
│                             │           │                                 │
│  vibelife.app               │   HTTPS   │  api.vibelife.app               │
│  bazi.vibelife.app     ─────┼───────────┼──► FastAPI (port 8000)          │
│  zodiac.vibelife.app        │   API     │     │                           │
│  mbti.vibelife.app          │           │     ▼                           │
│                             │           │  PostgreSQL (port 8224)         │
└─────────────────────────────┘           └─────────────────────────────────┘
```

### 服务分布

| 组件 | 位置 | 域名/端口 |
|------|------|-----------|
| 域名管理 | Cloudflare | `vibelife.app` |
| 前端 (Next.js) | Vercel / 阿里云香港 | `vibelife.app`, `bazi.vibelife.app` 等 |
| 后端 (FastAPI) | aiscend 服务器 | `api.vibelife.app` / `106.37.170.238:8000` |
| 数据库 (PostgreSQL) | aiscend 服务器 | `106.37.170.238:8224` |

---

## 临时测试部署

在正式域名配置完成前，可使用 IP + 端口方式进行测试。

### 测试环境配置

| 服务 | 端口 | 访问地址 |
|------|------|----------|
| **API 后端** | 8000 | `http://106.37.170.238:8000` |
| **主站 (vibelife)** | 8230 | `http://106.37.170.238:8230` |
| **八字站 (bazi)** | 8231 | `http://106.37.170.238:8231` |
| **星座站 (zodiac)** | 8232 | `http://106.37.170.238:8232` |

### 测试启动命令

**终端 1 - 后端 API:**
```bash
cd /home/aiscend/work/vibelife/apps/api
uvicorn main:app --port 8000 --host 0.0.0.0 --reload
```

**终端 2 - 主站前端:**
```bash
cd /home/aiscend/work/vibelife/apps/web
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=vibelife \
pnpm dev --port 8230 --hostname 0.0.0.0
```

**终端 3 - 八字站:**
```bash
cd /home/aiscend/work/vibelife/apps/web
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=bazi \
pnpm dev --port 8231 --hostname 0.0.0.0
```

**终端 4 - 星座站:**
```bash
cd /home/aiscend/work/vibelife/apps/web
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000 \
NEXT_PUBLIC_SITE_ID=zodiac \
pnpm dev --port 8232 --hostname 0.0.0.0
```

### 健康检查

```bash
# API 健康检查
curl http://106.37.170.238:8000/health

# API 文档
open http://106.37.170.238:8000/docs

# 前端站点
curl http://106.37.170.238:8230
curl http://106.37.170.238:8231
curl http://106.37.170.238:8232
```

---

## 环境要求

### 系统要求
- Node.js 18+
- Python 3.11+
- PostgreSQL 15+ (with pgvector extension)
- Redis (可选，用于缓存)

### 云服务
- Cloudflare (域名 + CDN)
- Stripe 账户 (支付)
- 智谱 API (LLM)
- Google Cloud (Gemini Embedding)
- Pinecone (向量存储，可选)

---

## 环境变量配置

### 后端环境变量 (.env)

```bash
# ─────────────────────────────────────────────────────────────────
# 数据库
# ─────────────────────────────────────────────────────────────────
VIBELIFE_DB_URL=postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/vibelife

# ─────────────────────────────────────────────────────────────────
# JWT 认证
# ─────────────────────────────────────────────────────────────────
VIBELIFE_JWT_SECRET=vibelife-jwt-secret-key-2026-aiscend
VIBELIFE_JWT_EXPIRE_MINUTES=60
VIBELIFE_REFRESH_TOKEN_EXPIRE_DAYS=30

# ─────────────────────────────────────────────────────────────────
# CORS (根据部署环境调整)
# ─────────────────────────────────────────────────────────────────
# 测试环境
VIBELIFE_CORS_ORIGINS=http://106.37.170.238:8230,http://106.37.170.238:8231,http://106.37.170.238:8232,http://localhost:3000

# 正式环境
# VIBELIFE_CORS_ORIGINS=https://vibelife.app,https://bazi.vibelife.app,https://zodiac.vibelife.app

# ─────────────────────────────────────────────────────────────────
# LLM 服务 - 智谱 GLM
# ─────────────────────────────────────────────────────────────────
GLM_API_KEY=your-glm-api-key
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.6v

# ─────────────────────────────────────────────────────────────────
# Claude (备选)
# ─────────────────────────────────────────────────────────────────
CLAUDE_API_KEY=your-claude-api-key

# ─────────────────────────────────────────────────────────────────
# Embedding - Alibaba GTE-Qwen2 (local)
# ─────────────────────────────────────────────────────────────────
GEMINI_API_KEY=your-gemini-api-key
GEMINI_EMBEDDING_MODEL=gemini-embedding-001

# ─────────────────────────────────────────────────────────────────
# Pinecone (向量存储)
# ─────────────────────────────────────────────────────────────────
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_HOST=your-index.pinecone.io

# ─────────────────────────────────────────────────────────────────
# Stripe 支付
# ─────────────────────────────────────────────────────────────────
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# ─────────────────────────────────────────────────────────────────
# 应用配置
# ─────────────────────────────────────────────────────────────────
VIBELIFE_API_HOST=0.0.0.0
VIBELIFE_API_PORT=8000
VIBELIFE_ENV=production
DEFAULT_LLM_PROVIDER=glm
```

### 前端环境变量

```bash
# 测试环境
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000

# 正式环境
# NEXT_PUBLIC_API_URL=https://api.vibelife.app

# 站点标识 (用于多站点路由)
NEXT_PUBLIC_SITE_ID=vibelife  # 或 bazi, zodiac, mbti

# Stripe 公钥
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xxx
```

---

## 后端部署 (aiscend 服务器)

### 方式一: 直接运行

```bash
cd /home/aiscend/work/vibelife/apps/api

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn main:app --port 8000 --host 0.0.0.0
```

### 方式二: Docker 部署

```bash
cd /home/aiscend/work/vibelife/deploy/aiscend

# 配置环境变量
cp .env.example .env
vim .env

# 启动
docker-compose up -d

# 查看日志
docker-compose logs -f api
```

### 方式三: Systemd 服务

创建 `/etc/systemd/system/vibelife-api.service`:

```ini
[Unit]
Description=VibeLife API
After=network.target

[Service]
Type=simple
User=aiscend
WorkingDirectory=/home/aiscend/work/vibelife/apps/api
EnvironmentFile=/home/aiscend/work/vibelife/.env
ExecStart=/usr/bin/python3 -m uvicorn main:app --port 8000 --host 0.0.0.0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable vibelife-api
sudo systemctl start vibelife-api
sudo systemctl status vibelife-api
```

---

## 前端部署

### 方式一: Vercel (推荐)

1. 连接 GitHub 仓库到 Vercel
2. 配置项目:
   - Root Directory: `apps/web`
   - Framework: Next.js
   - Build Command: `pnpm build`

3. 配置环境变量:
   ```
   NEXT_PUBLIC_API_URL=https://api.vibelife.app
   ```

4. 配置域名:
   - `vibelife.app` → 主站
   - `bazi.vibelife.app` → 八字站
   - `zodiac.vibelife.app` → 星座站

### 方式二: 阿里云香港 ECS

```bash
# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 pnpm
npm install -g pnpm

# 部署
cd /home/aiscend/work/vibelife/apps/web
pnpm install
pnpm build
pnpm start --port 3000
```

---

## DNS 配置 (Cloudflare)

| 记录类型 | 名称 | 内容 | 代理状态 |
|----------|------|------|----------|
| A | api | 106.37.170.238 | DNS only |
| CNAME | @ | cname.vercel-dns.com | Proxied |
| CNAME | bazi | cname.vercel-dns.com | Proxied |
| CNAME | zodiac | cname.vercel-dns.com | Proxied |
| CNAME | mbti | cname.vercel-dns.com | Proxied |

---

## 数据库

数据库已部署在 aiscend 服务器:

```
Host: 106.37.170.238
Port: 8224
Database: vibelife
User: postgres
```

### 连接测试

```bash
psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife
```

### 运行迁移

```bash
psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife -f migrations/001_init.sql
```

---

## 监控与日志

### 健康检查

```bash
# API
curl http://106.37.170.238:8000/health
# 或正式环境
curl https://api.vibelife.app/health
```

### 日志查看

```bash
# Docker 日志
docker logs -f vibelife-api

# Systemd 日志
journalctl -u vibelife-api -f
```

---

## 故障排查

### 1. API 无法访问

```bash
# 检查进程
ps aux | grep uvicorn

# 检查端口
netstat -tlnp | grep 8000

# 检查防火墙
sudo ufw status
```

### 2. 数据库连接失败

```bash
# 测试连接
psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife -c "SELECT 1"

# 检查 PostgreSQL 状态
systemctl status postgresql
```

### 3. 前端无法调用 API

- 检查 CORS 配置是否包含前端域名
- 检查 `NEXT_PUBLIC_API_URL` 是否正确
- 查看浏览器 Network 面板的错误信息

---

## 安全建议

1. **API 密钥**: 使用环境变量，不要提交到代码库
2. **HTTPS**: 正式环境必须使用 HTTPS (Cloudflare 提供)
3. **CORS**: 限制允许的来源域名
4. **防火墙**: 只开放必要端口 (8000, 8224)
5. **日志脱敏**: 不要记录敏感信息
6. **定期更新**: 保持依赖包更新
