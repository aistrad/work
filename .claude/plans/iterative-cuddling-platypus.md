# 代码保密与协作部署方案

## 目标
- 保护后端 API 核心代码（Agent、Skills、Prompts）
- 同事只需部署产物，无需访问源码

## 推荐方案：私有仓库 + Docker 镜像部署

### 架构
```
[开发者] → [私有 GitHub Repo] → [GitHub Actions] → [Docker Registry]
                                                           ↓
                                           [运维同事] ← [拉取镜像部署]
```

---

## 实施步骤

### 1. 确保 GitHub 仓库为私有

```bash
# 检查当前状态（通过 GitHub API）
gh repo view aiscendtech/vibelife --json isPrivate

# 如果是 public，改为 private
gh repo edit aiscendtech/vibelife --visibility private
```

### 2. 创建 Dockerfile（如果没有）

**文件**: `apps/api/Dockerfile`
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8100
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8100"]
```

**文件**: `apps/web/Dockerfile`
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["node", "server.js"]
```

### 3. 设置 GitHub Actions 自动构建

**文件**: `.github/workflows/build-push.yml`
```yaml
name: Build and Push Docker Images

on:
  push:
    branches: [master, main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: aiscendtech/vibelife

jobs:
  build-api:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push API
        uses: docker/build-push-action@v5
        with:
          context: ./apps/api
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-api:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-api:${{ github.sha }}

  build-web:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Web
        uses: docker/build-push-action@v5
        with:
          context: ./apps/web
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-web:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-web:${{ github.sha }}
```

### 4. 为运维同事创建部署权限

**方案 A: GitHub 包读取权限（推荐）**
```bash
# 邀请同事到 Organization
gh org invite <colleague-username> --org aiscendtech

# 或者创建 Personal Access Token (PAT) 给同事
# 权限: read:packages
```

**方案 B: 共享 docker-compose.yml**

创建一个单独的部署仓库或文件给同事：

**文件**: `deploy/docker-compose.yml`
```yaml
version: '3.8'
services:
  api:
    image: ghcr.io/aiscendtech/vibelife-api:latest
    ports:
      - "8100:8100"
    env_file:
      - .env
    restart: unless-stopped

  web:
    image: ghcr.io/aiscendtech/vibelife-web:latest
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://api:8100
    depends_on:
      - api
    restart: unless-stopped
```

### 5. 运维同事的操作流程

```bash
# 1. 登录 GitHub Container Registry
echo $GITHUB_PAT | docker login ghcr.io -u USERNAME --password-stdin

# 2. 拉取最新镜像
docker pull ghcr.io/aiscendtech/vibelife-api:latest
docker pull ghcr.io/aiscendtech/vibelife-web:latest

# 3. 启动服务
docker-compose up -d

# 4. 更新时
docker-compose pull && docker-compose up -d
```

---

## 权限总结

| 角色 | GitHub Repo | Docker 镜像 | 源代码 |
|------|-------------|-------------|--------|
| 开发者 (你) | ✅ 完整访问 | ✅ 推送/拉取 | ✅ |
| 运维同事 | ❌ 无需访问 | ✅ 只读拉取 | ❌ |

---

## 替代方案

如果不想用 Docker：

### 方案 B: 分离仓库
- 私有仓库: `vibelife-core` (API 核心)
- 公开/共享仓库: `vibelife-deploy` (部署配置)

### 方案 C: Git Submodules
- 主仓库包含 web
- 私有 submodule 包含 api

---

## 验证步骤

1. [ ] 确认 GitHub 仓库为私有
2. [ ] 创建并测试 Dockerfile
3. [ ] 设置 GitHub Actions
4. [ ] 测试镜像构建和推送
5. [ ] 为同事创建访问令牌
6. [ ] 同事测试拉取镜像并部署
