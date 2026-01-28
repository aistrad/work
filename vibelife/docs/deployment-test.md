# VibeLife 测试环境部署指南

> 最后更新: 2026-01-19 | v7.0 已验证 | 测试环境 (aiscend)

---

## 部署架构

### 测试环境架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户浏览器                                      │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         aiscend 服务器                                       │
│                         106.37.170.238                                       │
│                                                                             │
│   ┌─────────────────────────┐     ┌─────────────────────────────────────┐   │
│   │  前端 (Next.js)         │     │  后端 (FastAPI)                     │   │
│   │  Port: 8232             │────►│  Port: 8100                         │   │
│   │  Production Mode        │     │                                     │   │
│   └─────────────────────────┘     └──────────────┬──────────────────────┘   │
│                                                  │                          │
│                                                  ▼                          │
│                                   ┌─────────────────────────────────────┐   │
│                                   │  PostgreSQL 16 + pgvector           │   │
│                                   │  Port: 8224                         │   │
│                                   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 服务分布

| 组件 | 位置 | 端口 | 运行模式 |
|------|------|------|----------|
| 前端 (Next.js) | aiscend 服务器 | 8232 | Production (`pnpm start`) |
| 后端 (FastAPI) | aiscend 服务器 | 8100 | uvicorn |
| 数据库 (PostgreSQL 16) | aiscend 服务器 | 8224 | - |

---

## 快速启动

### 1. 启动后端 API (端口 8100)

```bash
cd /home/aiscend/work/vibelife/apps/api

# 激活虚拟环境
source venv/bin/activate

# 使用测试环境配置
cp /home/aiscend/work/vibelife/.env.test .env

# 启动服务
uvicorn main:app --port 8100 --host 0.0.0.0 --reload

# 或后台运行
nohup uvicorn main:app --host 0.0.0.0 --port 8100 > /tmp/vibelife-api.log 2>&1 &
```

### 2. 启动前端 Web (端口 8232)

> **重要**: 必须使用生产模式运行，开发模式会导致静态资源 404 错误

```bash
cd /home/aiscend/work/vibelife/apps/web

# 步骤 1: 构建生产版本 (必需)
pnpm build

# 步骤 2: 启动生产服务器
pnpm start -H 0.0.0.0 -p 8232

# 后台运行
nohup pnpm start -H 0.0.0.0 -p 8232 > /tmp/vibelife-web-8232.log 2>&1 &
```

> 注意: 不要使用 `pnpm dev` 运行测试环境，会导致 `/_next/static/*` 资源 404

### 3. 一键启动脚本

创建 `~/start-test.sh`:

```bash
#!/bin/bash
# VibeLife 测试环境启动脚本 v2.0

set -e

cd /home/aiscend/work/vibelife

# 启动后端
echo "Starting API on port 8100..."
cd apps/api
source venv/bin/activate
nohup uvicorn main:app --host 0.0.0.0 --port 8100 > /tmp/vibelife-api.log 2>&1 &
API_PID=$!
echo "API PID: $API_PID"

# 等待 API 启动
sleep 3

# 启动前端 (生产模式)
echo "Starting Web on port 8232 (production mode)..."
cd ../web

# 检查是否需要重新构建
if [ ! -d ".next" ] || [ "$(find src -newer .next -type f | head -1)" ]; then
    echo "Building frontend..."
    pnpm build
fi

nohup pnpm start -H 0.0.0.0 -p 8232 > /tmp/vibelife-web-8232.log 2>&1 &
WEB_PID=$!
echo "Web PID: $WEB_PID"

# 等待服务启动
sleep 5

echo ""
echo "=== VibeLife Test Environment ==="
echo "API: http://106.37.170.238:8100"
echo "Web: http://106.37.170.238:8232"
echo ""
echo "Health Check:"
curl -s http://localhost:8100/health | head -1 || echo "API not ready"
curl -s -o /dev/null -w "Web: %{http_code}\n" http://localhost:8232 || echo "Web not ready"
echo ""
echo "Logs:"
echo "  API: tail -f /tmp/vibelife-api.log"
echo "  Web: tail -f /tmp/vibelife-web-8232.log"
```

```bash
chmod +x ~/start-test.sh
~/start-test.sh
```

---

## 停止服务

```bash
# 查找进程
ps aux | grep -E "(uvicorn|next-server)" | grep -v grep

# 停止后端
pkill -f "uvicorn main:app.*8100"

# 停止前端
pkill -f "next.*8232"

# 或一键停止
pkill -f "uvicorn main:app" && pkill -f "next-server"
```

---

## 环境要求

### 系统要求
- Node.js 18+
- Python 3.11+
- PostgreSQL 16+ (with pgvector extension)
- CUDA (可选，用于 GPU 加速 embedding)

### 云服务
- Stripe 账户 (支付)
- 智谱 API (LLM)
- DeepSeek API (LLM)

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
# API 配置 (测试环境端口)
# ─────────────────────────────────────────────────────────────────
VIBELIFE_API_HOST=0.0.0.0
VIBELIFE_API_PORT=8100
VIBELIFE_DEV=1

# ─────────────────────────────────────────────────────────────────
# CORS (测试环境)
# ─────────────────────────────────────────────────────────────────
VIBELIFE_CORS_ORIGINS=http://106.37.170.238:8232,http://localhost:8232,http://localhost:3000

# ─────────────────────────────────────────────────────────────────
# LLM 服务 - DeepSeek (主力)
# ─────────────────────────────────────────────────────────────────
DEEPSEEK_API_KEY=your-deepseek-api-key

# ─────────────────────────────────────────────────────────────────
# LLM 服务 - 智谱 GLM (备选)
# ─────────────────────────────────────────────────────────────────
GLM_API_KEY=your-glm-api-key
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.6v
GLM_BASE_URL=https://open.bigmodel.cn/api/paas/v4

# ─────────────────────────────────────────────────────────────────
# Claude (备选)
# ─────────────────────────────────────────────────────────────────
CLAUDE_API_KEY=your-claude-api-key

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
# Stripe 支付
# ─────────────────────────────────────────────────────────────────
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

### 前端环境变量

```bash
# 测试环境 (apps/web/.env.local)
NEXT_PUBLIC_API_URL=http://106.37.170.238:8100
NEXT_PUBLIC_API_BASE=http://106.37.170.238:8100/api/v1
NEXT_PUBLIC_WS_URL=ws://106.37.170.238:8100/ws

# 内部 API (SSR) - 关键配置！
# Next.js rewrites 使用此地址转发 /api/v1/* 请求到后端
# 必须指向本地 API，不要使用外部 IP
VIBELIFE_API_INTERNAL=http://127.0.0.1:8100
```

> **重要**: `VIBELIFE_API_INTERNAL` 是 API 路由的关键配置。前端通过 Next.js rewrites 将 `/api/v1/*` 请求转发到此地址。使用 `127.0.0.1:8100` 而非外部 IP，因为外部 IP 可能不可达或返回 503。

---

## 数据库初始化

### 运行 Schema 迁移

```bash
# 连接数据库
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife

# 运行迁移
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife \
  -f /home/aiscend/work/vibelife/apps/api/stores/migrations/001_init.sql
```

### 验证表创建

```bash
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
```

---

## 健康检查

```bash
# API 健康检查
curl http://106.37.170.238:8100/health
# 期望输出: {"status":"ok","service":"vibelife-api","version":"6.9.0","database":"ok"}

# 前端检查
curl -I http://106.37.170.238:8232
# 期望: HTTP/1.1 200 OK

# 数据库检查
psql postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife -c "SELECT 1"
```

---

## API 端点验证

部署完成后，验证以下核心端点:

```bash
# 1. 健康检查
curl http://106.37.170.238:8100/health

# 2. 对话 API (SSE)
curl -X POST http://106.37.170.238:8100/api/v1/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "你好", "skill": "bazi"}'

# 3. 工具 Schema
curl http://106.37.170.238:8100/api/v1/tools/schema

# 4. Skill 列表
curl http://106.37.170.238:8100/api/v1/skills

# 5. Dev Login (测试登录)
curl -X POST http://127.0.0.1:8100/api/v1/account/auth/dev-login \
  -H "Content-Type: application/json" \
  -d '{"email":"iaaichina@163.com"}'
```

---

## Dev Login (开发环境快速登录)

**用途**: 开发/测试环境快速登录，无需 OAuth 认证流程

**访问地址**: http://106.37.170.238:8232/auth/dev-login

**默认测试用户**:
| 字段 | 值 |
|------|-----|
| Email | `iaaichina@163.com` |
| Vibe ID | `VB-YRZ5YYVR` |

**使用方式**:
1. 浏览器访问 `http://106.37.170.238:8232/auth/dev-login`
2. 默认已填入测试用户 Email，直接点击 Login
3. 登录成功后自动跳转首页

**API 调用**:
```bash
# 通过 Email 登录
curl -X POST http://127.0.0.1:8100/api/v1/account/auth/dev-login \
  -H "Content-Type: application/json" \
  -d '{"email":"iaaichina@163.com"}'

# 通过 Vibe ID 登录
curl -X POST http://127.0.0.1:8100/api/v1/account/auth/dev-login \
  -H "Content-Type: application/json" \
  -d '{"vibe_id":"VB-YRZ5YYVR"}'
```

**返回示例**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "user_id": "a58d5189-3c7e-42a4-91d5-9a2c3e091724",
    "vibe_id": "VB-YRZ5YYVR",
    "display_name": "hd"
  }
}
```

**安全限制**: 仅在 `VIBELIFE_ENV != production` 时可用

---

## 查看日志

```bash
# API 日志
tail -f /tmp/vibelife-api.log

# Web 日志
tail -f /tmp/vibelife-web-8232.log

# API 请求日志
tail -f /data/vibelife/logs/api_requests.log
```

---

## 端口检查

```bash
# 检查端口占用
lsof -i :8100  # API
lsof -i :8232  # Web
lsof -i :8224  # PostgreSQL

# 检查所有 vibelife 相关端口
netstat -tuln | grep -E "(8100|8232|8224)"
```

---

## 故障排查

### 1. API 无法访问

```bash
# 检查进程
ps aux | grep uvicorn

# 检查端口
netstat -tlnp | grep 8100

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
echo $DEEPSEEK_API_KEY
echo $GLM_API_KEY

# 查看 config/models.yaml 配置
cat /home/aiscend/work/vibelife/apps/api/config/models.yaml
```

### 4. 前端无法调用 API / Chat 发送失败

**常见原因**:
1. `VIBELIFE_API_INTERNAL` 配置错误或未设置
2. API 服务未运行在 localhost:8100
3. 外部 IP (106.37.170.238:8100) 返回 503

**排查步骤**:
```bash
# 1. 检查本地 API 是否运行
curl http://127.0.0.1:8100/health

# 2. 测试 chat 端点
curl -X POST http://127.0.0.1:8100/api/v1/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "hi"}'

# 3. 通过 Web rewrite 测试 (确保 Web 在运行)
curl http://localhost:8232/api/v1/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "hi"}'
```

**解决方案**:
- 确保 `VIBELIFE_API_INTERNAL=http://127.0.0.1:8100` 在启动 Web 时设置
- 如果直接启动: `VIBELIFE_API_INTERNAL=http://127.0.0.1:8100 pnpm dev -p 8232`
- 检查 CORS 配置是否包含前端域名
- 查看浏览器 Network 面板的错误信息

### 5. 静态资源 404 错误

如果浏览器控制台出现 `/_next/static/*` 404 错误：

```bash
# 原因: 使用了开发模式运行，或构建产物过期

# 解决方案:
cd /home/aiscend/work/vibelife/apps/web

# 1. 停止旧进程
pkill -f "next.*8232"

# 2. 重新构建
pnpm build

# 3. 以生产模式启动
nohup pnpm start -H 0.0.0.0 -p 8232 > /tmp/vibelife-web-8232.log 2>&1 &

# 4. 验证
curl -I http://106.37.170.238:8232/_next/static/css/*.css
# 应返回 200 OK
```

### 6. TypeScript 构建错误

```bash
# 清理缓存
cd /home/aiscend/work/vibelife/apps/web
rm -rf .next
pnpm build
```

---

## 与生产环境对比

| 项目 | 测试环境 | 生产环境 |
|------|----------|----------|
| 用户 | aiscend | vibelife |
| API 端口 | 8100 | 8000 |
| Web 端口 | 8232 | 8230 |
| 工作目录 | /home/aiscend/work/vibelife | /home/vibelife/vibelife |
| 启动方式 | 手动/脚本 | Systemd |
| 前端模式 | Production (`pnpm start`) | Production |
| 域名 | IP:Port | vibelife.app |

---

## 安全建议

1. **API 密钥**: 使用环境变量，不要提交到代码库
2. **CORS**: 限制允许的来源域名
3. **防火墙**: 只开放必要端口 (8100, 8224, 8232)
4. **日志脱敏**: 不要记录敏感信息
5. **定期更新**: 保持依赖包更新
6. **数据库**: 使用强密码，限制访问 IP

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v7.0 | 2026-01-19 | 添加 Chat 发送失败故障排查，强调 VIBELIFE_API_INTERNAL 配置重要性 |
| v6.9 | 2026-01-19 | 修复静态资源404问题，强制使用生产模式运行前端 |
| v6.8 | 2026-01-17 | 初始版本，基于 deployment.md 适配测试端口 |
