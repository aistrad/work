---
name: vibelife-test
description: |
  VibeLife Test - 测试环境管理工具。
  快速启动/停止/查看测试环境状态。
  测试环境：API 端口 8100，Web 端口 8232。
  触发词：vibelife-test, 测试环境, 启动测试, 停止测试
---

# VibeLife Test - 测试环境管理

## 命令

| 命令 | 说明 |
|------|------|
| `vibelife-test start` | 启动测试环境 |
| `vibelife-test stop` | 停止测试环境 |
| `vibelife-test status` | 查看测试环境状态 |
| `vibelife-test logs` | 查看测试环境日志 |

## 环境配置

| 项目 | 值 |
|------|------|
| API 端口 | 8100 |
| Web 端口 | 8232 |
| API 地址 | http://106.37.170.238:8100 |
| Web 地址 | http://106.37.170.238:8232 |
| 配置文件 | `/home/aiscend/work/vibelife/.env.test` |
| 日志目录 | `/data/vibelife/logs/test` |

## 执行流程

### start - 启动测试环境

```bash
# 执行启动脚本
/home/aiscend/work/vibelife/scripts/start-test.sh
```

**启动内容**：
1. 加载 `.env.test` 环境变量
2. 启动 API 服务（uvicorn，端口 8100）
3. 启动 Web 服务（pnpm dev，端口 8232）
4. 输出访问地址

### stop - 停止测试环境

```bash
# 执行停止脚本
/home/aiscend/work/vibelife/scripts/stop-test.sh
```

**停止内容**：
1. 停止 API 进程
2. 停止 Web 进程
3. 清理残留进程

### status - 查看状态

```bash
# 检查 API 端口
lsof -i :8100

# 检查 Web 端口
lsof -i :8232

# 检查健康状态
curl -s http://localhost:8100/health
```

### logs - 查看日志

```bash
# API 日志
tail -f /data/vibelife/logs/test/api.log

# Web 日志
tail -f /data/vibelife/logs/test/web.log
```

## 与生产环境的区别

| 项目 | 生产环境 | 测试环境 |
|------|---------|---------|
| 运行用户 | vibelife | aiscend |
| API 端口 | 8000 | 8100 |
| Web 端口 | 8230 | 8232 |
| 数据库 | vibelife（共用） | vibelife（共用） |
| 数据目录 | /data/vibelife（共用） | /data/vibelife（共用） |

## 注意事项

1. 测试环境与生产环境共用数据库，修改数据会影响生产
2. 启动前确保端口 8100 和 8232 未被占用
3. 日志文件位于 `/data/vibelife/logs/test/`
