# VibeLife 部署指南

> 最后更新: 2026-01-09 | v3.0 已验证 | 数据目录重构

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
│                             │           │  PostgreSQL 16 (port 8224)      │
└─────────────────────────────┘           └─────────────────────────────────┘
```

### 服务分布

| 组件 | 位置 | 域名/端口 |
|------|------|-----------|
| 域名管理 | Cloudflare | `vibelife.app` |
| 前端 (Next.js) | Vercel / 阿里云香港 | `vibelife.app`, `bazi.vibelife.app` 等 |
| 后端 (FastAPI) | aiscend 服务器 | `api.vibelife.app` / `106.37.170.238:8000` |
| 数据库 (PostgreSQL 16) | aiscend 服务器 | `106.37.170.238:8224` |

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

# 设置环境变量
export GLM_API_KEY="your-glm-api-key"
export GLM_CHAT_MODEL="glm-4.7"
export GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
export DEFAULT_LLM_PROVIDER="glm"
export VIBELIFE_DB_URL="postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife"

# 若使用 Claude 作为默认模型 (仍建议保留 GLM 作为 fallback):
# export CLAUDE_API_KEY="your-claude-api-key"  # 兼容 ANTHROPIC_API_KEY
# export DEFAULT_LLM_PROVIDER="claude"

# 启动服务
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
# 期望输出: {"status":"ok","service":"vibelife-api","version":"1.0.0","database":"ok"}

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
- PostgreSQL 16+ (with pgvector extension)
- CUDA (可选，用于 GPU 加速 embedding)

### 云服务
- Cloudflare (域名 + CDN)
- Stripe 账户 (支付)
- 智谱 API (LLM)
- Pinecone (向量存储，可选)

---

## 环境变量配置

### 后端环境变量 (.env)

```bash
# ─────────────────────────────────────────────────────────────────
# 数据库
# ─────────────────────────────────────────────────────────────────
VIBELIFE_DB_URL=postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife
VIBELIFE_DB_HOST=106.37.170.238
VIBELIFE_DB_PORT=8224
VIBELIFE_DB_NAME=vibelife
VIBELIFE_DB_USER=postgres
VIBELIFE_DB_PASSWORD=<PASSWORD>

# ─────────────────────────────────────────────────────────────────
# JWT 认证
# ─────────────────────────────────────────────────────────────────
VIBELIFE_JWT_SECRET=your-jwt-secret-key
VIBELIFE_ACCESS_TOKEN_EXPIRE_MINUTES=60
VIBELIFE_REFRESH_TOKEN_EXPIRE_DAYS=30

# ─────────────────────────────────────────────────────────────────
# API 配置
# ─────────────────────────────────────────────────────────────────
VIBELIFE_API_HOST=0.0.0.0
VIBELIFE_API_PORT=8000
VIBELIFE_DEV=1

# ─────────────────────────────────────────────────────────────────
# CORS (根据部署环境调整)
# ─────────────────────────────────────────────────────────────────
# 测试环境
VIBELIFE_CORS_ORIGINS=http://106.37.170.238:8230,http://106.37.170.238:8231,http://106.37.170.238:8232,http://localhost:3000

# 正式环境
# VIBELIFE_CORS_ORIGINS=https://vibelife.app,https://bazi.vibelife.app,https://zodiac.vibelife.app

# ─────────────────────────────────────────────────────────────────
# LLM 服务 - 智谱 GLM (支持 GLM_* 或 ZHIPU_* 前缀)
# ─────────────────────────────────────────────────────────────────
GLM_API_KEY=your-glm-api-key
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.6v
GLM_BASE_URL=https://open.bigmodel.cn/api/paas/v4

# ─────────────────────────────────────────────────────────────────
# Claude (备选)
# ─────────────────────────────────────────────────────────────────
CLAUDE_API_KEY=your-claude-api-key
# 兼容变量名 (与部分文档/部署系统一致)
ANTHROPIC_API_KEY=your-anthropic-api-key

# ─────────────────────────────────────────────────────────────────
# 数据目录 (独立数据盘)
# ─────────────────────────────────────────────────────────────────
VIBELIFE_DATA_ROOT=/data/vibelife
VIBELIFE_KNOWLEDGE_ROOT=/data/vibelife/knowledge
VIBELIFE_UPLOADS_ROOT=/data/vibelife/uploads
VIBELIFE_CACHE_ROOT=/data/vibelife/cache
VIBELIFE_LOGS_ROOT=/data/vibelife/logs

# ─────────────────────────────────────────────────────────────────
# Embedding - BAAI/bge-m3 (本地)
# ─────────────────────────────────────────────────────────────────
EMBEDDING_MODEL_NAME=BAAI/bge-m3
EMBEDDING_DIMENSION=1024
EMBEDDING_DEVICE=cuda

# ─────────────────────────────────────────────────────────────────
# Pinecone (向量存储 - 可选)
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
# 默认 LLM 提供商 (支持 'glm'/'zhipu' 或 'claude')
# ─────────────────────────────────────────────────────────────────
DEFAULT_LLM_PROVIDER=glm
```

### 前端环境变量

```bash
# 测试环境
NEXT_PUBLIC_API_URL=http://106.37.170.238:8000
NEXT_PUBLIC_API_BASE=http://106.37.170.238:8000/api/v1

# 正式环境
# NEXT_PUBLIC_API_URL=https://api.vibelife.app
# NEXT_PUBLIC_API_BASE=https://api.vibelife.app/api/v1

# 站点标识 (用于多站点路由)
NEXT_PUBLIC_SITE_ID=vibelife  # 或 bazi, zodiac, mbti

# Stripe 公钥
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xxx
```

---

## 数据库初始化

### 运行 v3.0 Schema 迁移

```bash
# 连接数据库
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife

# 运行迁移
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife \
  -f /home/aiscend/work/vibelife/migrations/001_v3_schema.sql
```

### 验证表创建

```bash
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
```

期望输出 (核心表):
- `users`, `user_auth`, `user_profiles`
- `conversations`, `messages`
- `reports`, `relationships`, `insights`
- `knowledge_chunks`
- `subscription_plans`, `subscriptions`, `payments`
- `daily_greetings`, `user_events`

---

## 后端部署 (aiscend 服务器)

### 方式一: 直接运行

```bash
cd /home/aiscend/work/vibelife/apps/api

# 安装依赖
pip install -r requirements.txt

# 设置环境变量
export GLM_API_KEY="your-key"
export GLM_CHAT_MODEL="glm-4.7"
export GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
export DEFAULT_LLM_PROVIDER="glm"
export VIBELIFE_DB_URL="postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife"

# 若使用 Claude 作为默认模型 (仍建议保留 GLM 作为 fallback):
# export CLAUDE_API_KEY="your-claude-api-key"  # 兼容 ANTHROPIC_API_KEY
# export DEFAULT_LLM_PROVIDER="claude"

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

### 前端构建

```bash
cd /home/aiscend/work/vibelife/apps/web

# 安装依赖
pnpm install

# 构建
pnpm build

# 期望输出:
# ✓ Generating static pages (14/14)
# ✓ 编译成功
```

### 方式一: Vercel (推荐)

1. 连接 GitHub 仓库到 Vercel
2. 配置项目:
   - Root Directory: `apps/web`
   - Framework: Next.js
   - Build Command: `pnpm build`

3. 配置环境变量:
   ```
   NEXT_PUBLIC_API_URL=https://api.vibelife.app
   NEXT_PUBLIC_API_BASE=https://api.vibelife.app/api/v1
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

## API 端点验证

部署完成后，验证以下核心端点:

```bash
# 1. 健康检查
curl http://localhost:8000/health

# 2. Guest Chat
curl -X POST http://localhost:8000/api/v1/chat/guest \
  -H "Content-Type: application/json" \
  -d '{"message": "你好", "skill": "bazi"}'

# 3. Interview
curl -X POST http://localhost:8000/api/v1/chat/interview/start \
  -H "Content-Type: application/json" \
  -d '{"skill": "bazi"}'

# 4. Fortune Cycles
curl "http://localhost:8000/api/v1/fortune/cycles?birth_year=1990&day_master_element=wood&gender=male"

# 5. Daily Greeting
curl -X POST http://localhost:8000/api/v1/fortune/greeting \
  -H "Content-Type: application/json" \
  -d '{"profile": {"basic": {}}, "voice_mode": "warm"}'
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

# 直接运行时
# 日志输出在终端
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
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife -c "SELECT 1"

# 检查 PostgreSQL 状态
systemctl status postgresql
```

### 3. LLM 调用失败

```bash
# 检查环境变量
echo $GLM_API_KEY
echo $GLM_CHAT_MODEL

# 测试 API Key
curl -X POST https://open.bigmodel.cn/api/paas/v4/chat/completions \
  -H "Authorization: Bearer $GLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "glm-4.7", "messages": [{"role": "user", "content": "hello"}]}'
```

### 4. 前端无法调用 API

- 检查 CORS 配置是否包含前端域名
- 检查 `NEXT_PUBLIC_API_URL` 是否正确
- 查看浏览器 Network 面板的错误信息
- 确保 API 服务器在运行

### 5. TypeScript 构建错误

```bash
# 清理缓存
cd /home/aiscend/work/vibelife/apps/web
rm -rf .next
pnpm build
```

---

## 安全建议

1. **API 密钥**: 使用环境变量，不要提交到代码库
2. **HTTPS**: 正式环境必须使用 HTTPS (Cloudflare 提供)
3. **CORS**: 限制允许的来源域名
4. **防火墙**: 只开放必要端口 (8000, 8224)
5. **日志脱敏**: 不要记录敏感信息
6. **定期更新**: 保持依赖包更新
7. **数据库**: 使用强密码，限制访问 IP

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v3.0 | 2026-01-07 | Schema v3.0, LLM 配置优化, 前端 Suspense 修复 |
| v2.0 | 2026-01-05 | 初始部署配置 |
