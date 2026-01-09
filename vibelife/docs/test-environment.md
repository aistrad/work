# VibeLife 测试环境部署文档

## 概述

本文档描述 VibeLife 测试环境的配置和使用方法。测试环境与生产环境共用数据库和数据目录，仅端口不同。

## 环境配置

| 项目 | 生产环境 (vibelife) | 测试环境 (aiscend) |
|------|---------------------|-------------------|
| 运行用户 | vibelife | aiscend |
| API 端口 | 8000 | 8100 |
| Web 端口 | 8230 | 8232 |
| API 地址 | http://106.37.170.238:8000 | http://106.37.170.238:8100 |
| Web 地址 | http://106.37.170.238:8230 | http://106.37.170.238:8232 |
| 数据库 | vibelife（共用） | vibelife（共用） |
| 数据目录 | /data/vibelife（共用） | /data/vibelife（共用） |
| 配置文件 | .env | .env.test |

## 快速开始

### 使用 Skill 命令

```bash
# 启动测试环境
/vibelife-test start

# 停止测试环境
/vibelife-test stop

# 查看状态
/vibelife-test status
```

### 使用脚本

```bash
# 启动测试环境
./scripts/start-test.sh

# 停止测试环境
./scripts/stop-test.sh
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `.env.test` | 测试环境变量配置 |
| `scripts/start-test.sh` | 启动脚本 |
| `scripts/stop-test.sh` | 停止脚本 |
| `.claude/skills/vibelife-test/SKILL.md` | Claude Code skill 定义 |

## 启动流程

1. 加载 `.env.test` 环境变量
2. 启动 API 服务（uvicorn，端口 8100）
3. 启动 Web 服务（pnpm dev，端口 8232）
4. 创建 `.env.local` 配置前端 API 地址

## 日志

日志文件位于 `/data/vibelife/logs/test/`：

```bash
# 查看 API 日志
tail -f /data/vibelife/logs/test/api.log

# 查看 Web 日志
tail -f /data/vibelife/logs/test/web.log
```

## 健康检查

```bash
# 检查 API
curl http://localhost:8100/health

# 检查端口占用
lsof -i :8100
lsof -i :8232
```

## 注意事项

1. **数据共用**：测试环境与生产环境共用同一个数据库，修改数据会影响生产环境
2. **端口冲突**：启动前确保端口 8100 和 8232 未被占用
3. **权限**：确保 aiscend 用户有权限访��� `/data/vibelife` 目录

## 故障排除

### 端口被占用

```bash
# 查看占用端口的进程
lsof -i :8100
lsof -i :8232

# 强制停止
./scripts/stop-test.sh
```

### API 启动失败

```bash
# 检查日志
cat /data/vibelife/logs/test/api.log

# 手动启动调试
cd apps/api
source ../../.venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8100 --reload
```

### Web 启动失败

```bash
# 检查日志
cat /data/vibelife/logs/test/web.log

# 手动启动调试
cd apps/web
pnpm dev --port 8232
```
