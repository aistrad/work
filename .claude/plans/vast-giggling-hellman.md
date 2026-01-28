# Plan: sync-work Skill 设计与实现

## 目标
创建 `sync-work` skill，将 ~/work 目录下的文档和配置同步到 GitHub 仓库 https://github.com/aistrad/work

## 同步范围

### 根目录
- `.claude/` - Claude 配置和 skills
- `docs/` - 工作区级文档

### 主项目 docs
- `AIS/docs/`
- `fortune_ai/docs/`
- `vibelife/docs/`
- `cli_worker/docs/`
- `mentis/docs/`

## 目录结构（保持原有层级）

同步后 GitHub 仓库结构：
```
aistrad/work/
├── .claude/
│   ├── settings.local.json
│   └── skills/
│       ├── vibe/
│       ├── dev-spec/
│       ├── quant-strategy/
│       ├── cc-fresh/
│       ├── vibeknowledge/
│       └── sync-work/        # 新增
├── docs/
│   ├── cc-fresh-setup-summary.md
│   ├── apikey.md
│   └── vibelife/
├── AIS/
│   └── docs/
├── fortune_ai/
│   └── docs/
├── vibelife/
│   └── docs/
├── cli_worker/
│   └── docs/
└── mentis/
    └── docs/
```

## Skill 设计

### 文件结构
```
~/.claude/skills/sync-work/
├── SKILL.md              # 主文档
└── scripts/
    ├── default.sh        # 完整流程：sync + push
    ├── sync.sh           # 仅同步文件到暂存区
    ├── push.sh           # 仅推送到 GitHub
    └── status.sh         # 查看同步状态
```

### 工作流设计

**Workflow 0 (default): sync + push**
1. 创建/更新同步目录 `~/.work-sync/`
2. 使用 rsync 同步指定目录（保持结构）
3. git add + commit + push

**Workflow 1: sync（仅同步）**
- 同步文件到本地暂存目录
- 显示变更文件列表

**Workflow 2: push（仅推送）**
- 提交并推送到 GitHub

**Workflow 3: status**
- 显示当前同步状态
- 显示未提交的变更

### 核心脚本逻辑

#### sync.sh
```bash
#!/bin/bash
set -e

WORK_DIR="${WORK_DIR:-/home/aiscend/work}"
SYNC_DIR="${SYNC_DIR:-$HOME/.work-sync}"
REPO_URL="https://github.com/aistrad/work.git"

# 确保同步目录存在且已初始化
if [ ! -d "$SYNC_DIR/.git" ]; then
    git clone "$REPO_URL" "$SYNC_DIR" || {
        mkdir -p "$SYNC_DIR"
        cd "$SYNC_DIR"
        git init
        git remote add origin "$REPO_URL"
    }
fi

# 同步 .claude 目录
rsync -av --delete \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    "$WORK_DIR/.claude/" "$SYNC_DIR/.claude/"

# 同步根 docs
rsync -av --delete "$WORK_DIR/docs/" "$SYNC_DIR/docs/"

# 同步主项目 docs
for proj in AIS fortune_ai vibelife cli_worker mentis; do
    if [ -d "$WORK_DIR/$proj/docs" ]; then
        mkdir -p "$SYNC_DIR/$proj"
        rsync -av --delete "$WORK_DIR/$proj/docs/" "$SYNC_DIR/$proj/docs/"
    fi
done

# 显示变更
cd "$SYNC_DIR"
git status --short
```

#### push.sh
```bash
#!/bin/bash
set -e

SYNC_DIR="${SYNC_DIR:-$HOME/.work-sync}"
cd "$SYNC_DIR"

# 添加所有变更
git add -A

# 检查是否有变更
if git diff --cached --quiet; then
    echo "No changes to commit"
    exit 0
fi

# 提交
COMMIT_MSG="${1:-sync: $(date '+%Y-%m-%d %H:%M')}"
git commit -m "$COMMIT_MSG"

# 推送
git push origin main
echo "Pushed to GitHub successfully"
```

## 实现步骤

1. **创建 skill 目录结构**
   - `~/.claude/skills/sync-work/`
   - `~/.claude/skills/sync-work/scripts/`

2. **编写 SKILL.md**
   - 描述、使用方式、工作流

3. **编写脚本**
   - `sync.sh` - 文件同步
   - `push.sh` - Git 推送
   - `default.sh` - 完整流程
   - `status.sh` - 状态查看

4. **初始化同步仓库**
   - 创建 `~/.work-sync/` 目录
   - 克隆或初始化 git 仓库
   - 配置 remote

5. **测试**
   - 运行 `/sync-work sync` 测试同步
   - 运行 `/sync-work status` 查看状态
   - 运行 `/sync-work` 完整流程测试

## 确认事项

- [x] GitHub 仓库 aistrad/work 已存在
- [x] settings.local.json 照常同步（用户确认无敏感信息）

## 注意事项

- `.gitignore` 配置：排除 `*.pyc`, `__pycache__`, `.env` 等
- 确保有 GitHub 仓库写权限

## 关键文件

| 文件 | 作用 |
|------|------|
| `~/.claude/skills/sync-work/SKILL.md` | Skill 文档 |
| `~/.claude/skills/sync-work/scripts/sync.sh` | 同步脚本 |
| `~/.claude/skills/sync-work/scripts/push.sh` | 推送脚本 |
| `~/.work-sync/` | 同步暂存目录 |
