---
name: sync-work
description: 将 ~/work 目录下的 .claude、docs 及主项目 docs 同步到 GitHub 仓库 aistrad/work；支持 sync（仅同步）、push（仅推送）、status（查看状态）等子命令；通过 /sync-work 显式调用。
---

# sync-work

将工作目录中的文档和配置同步到 GitHub。

## Quick Start

```bash
/sync-work           # 同步并推送
/sync-work sync      # 仅同步到本地
/sync-work status    # 查看状态
```

## 同步范围

### Claude Code 配置（完整复制）
- `~/.claude/` - 用户配置（排除 plugins/、statsig/、todo/、projects/）
- `~/.claude/repos/everything-claude-code/` - agents、commands、rules、skills 源仓库
- `~/work/.claude/` - 工作目录配置

### 文档
- `docs/` - 根目录文档
- 主项目 docs：
  - `AIS/docs/`
  - `fortune_ai/docs/`
  - `vibelife/docs/`
  - `cli_worker/docs/`
  - `mentis/docs/`

## Workflows

### Workflow 0: default (sync + push)

完整同步流程。

**触发**: `/sync-work` 或 `/sync-work default`

**步骤**:
1. 同步文件到 `~/.work-sync/`
2. Git add + commit + push

**脚本**: `scripts/default.sh`

### Workflow 1: sync

仅同步文件到本地暂存目录。

**触发**: `/sync-work sync`

**步骤**:
1. 确保 `~/.work-sync/` 存在且已初始化
2. rsync 同步指定目录
3. 显示变更列表

**脚本**: `scripts/sync.sh`

### Workflow 2: push

仅提交并推送到 GitHub。

**触发**: `/sync-work push [commit-message]`

**步骤**:
1. git add -A
2. git commit
3. git push

**脚本**: `scripts/push.sh`

### Workflow 3: status

查看当前同步状态。

**触发**: `/sync-work status`

**脚本**: `scripts/status.sh`

## 配置

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `WORK_DIR` | `/home/aiscend/work` | 源工作目录 |
| `SYNC_DIR` | `~/.work-sync` | 同步暂存目录 |

## GitHub 仓库

- URL: https://github.com/aistrad/work
- 分支: main

## 目录结构

同步后仓库结构：
```
aistrad/work/
├── .claude/
│   ├── settings.local.json
│   └── skills/
├── docs/
├── AIS/docs/
├── fortune_ai/docs/
├── vibelife/docs/
├── cli_worker/docs/
└── mentis/docs/
```

## Changelog

- 2025-01-07: 初始版本
