#!/bin/bash
set -e

WORK_DIR="${WORK_DIR:-/home/aiscend/work}"
SYNC_DIR="${SYNC_DIR:-$HOME/.work-sync}"
REPO_URL="https://github.com/aistrad/work.git"

echo "=== sync-work: Syncing files ==="
echo "Source: $WORK_DIR"
echo "Target: $SYNC_DIR"
echo ""

# 确保同步目录存在且已初始化
if [ ! -d "$SYNC_DIR/.git" ]; then
    echo "Initializing sync directory..."
    if git clone "$REPO_URL" "$SYNC_DIR" 2>/dev/null; then
        echo "Cloned from $REPO_URL"
    else
        echo "Creating new repository..."
        mkdir -p "$SYNC_DIR"
        cd "$SYNC_DIR"
        git init
        git remote add origin "$REPO_URL"
        git checkout -b main 2>/dev/null || true
    fi
fi

cd "$SYNC_DIR"

# 拉取最新更改
echo "Pulling latest changes..."
git pull origin main 2>/dev/null || echo "(No remote history yet)"

# 同步 .claude 目录（从 ~/work/.claude/）
echo ""
echo "Syncing .claude/ (from work dir)..."
mkdir -p "$SYNC_DIR/.claude"
rsync -av \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    "$WORK_DIR/.claude/" "$SYNC_DIR/.claude/"

# 同步 ~/.claude/skills/ 目录
echo ""
echo "Syncing .claude/skills/ (from home dir)..."
rsync -av --delete \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    "$HOME/.claude/skills/" "$SYNC_DIR/.claude/skills/"

# 通用排除选项
EXCLUDE_OPTS=(
    --exclude='*.pyc'
    --exclude='__pycache__'
    --exclude='.DS_Store'
    --exclude='*.pdf'           # 排除大 PDF 文件
    --exclude='apikey.md'       # 排除敏感文件
    --exclude='*.key'
    --exclude='*.pem'
    --exclude='.env*'
)

# 同步根 docs
echo ""
echo "Syncing docs/..."
rsync -av --delete "${EXCLUDE_OPTS[@]}" \
    "$WORK_DIR/docs/" "$SYNC_DIR/docs/"

# 同步主项目 docs
for proj in AIS fortune_ai vibelife cli_worker mentis; do
    if [ -d "$WORK_DIR/$proj/docs" ]; then
        echo ""
        echo "Syncing $proj/docs/..."
        mkdir -p "$SYNC_DIR/$proj"
        rsync -av --delete "${EXCLUDE_OPTS[@]}" \
            "$WORK_DIR/$proj/docs/" "$SYNC_DIR/$proj/docs/"
    else
        echo ""
        echo "Skipping $proj/docs/ (not found)"
    fi
done

# 同步主项目 .claude/
for proj in vibelife; do
    if [ -d "$WORK_DIR/$proj/.claude" ]; then
        echo ""
        echo "Syncing $proj/.claude/..."
        mkdir -p "$SYNC_DIR/$proj/.claude"
        rsync -av --delete "${EXCLUDE_OPTS[@]}" \
            "$WORK_DIR/$proj/.claude/" "$SYNC_DIR/$proj/.claude/"
    fi
done

# 创建 .gitignore
if [ ! -f "$SYNC_DIR/.gitignore" ]; then
    echo ""
    echo "Creating .gitignore..."
    cat > "$SYNC_DIR/.gitignore" << 'EOF'
*.pyc
__pycache__/
.DS_Store
*.log
.env
.venv/
node_modules/
EOF
fi

# 显示变更
echo ""
echo "=== Changes ==="
git status --short

echo ""
echo "Sync completed. Run '/sync-work push' to push changes."
