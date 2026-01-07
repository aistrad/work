#!/bin/bash
set -e

SYNC_DIR="${SYNC_DIR:-$HOME/.work-sync}"

echo "=== sync-work: Pushing to GitHub ==="

if [ ! -d "$SYNC_DIR/.git" ]; then
    echo "Error: Sync directory not initialized. Run '/sync-work sync' first."
    exit 1
fi

cd "$SYNC_DIR"

# 添加所有变更
git add -A

# 检查是否有变更
if git diff --cached --quiet; then
    echo "No changes to commit."
    exit 0
fi

# 显示将要提交的变更
echo "Changes to commit:"
git diff --cached --stat
echo ""

# 提交
COMMIT_MSG="${1:-sync: $(date '+%Y-%m-%d %H:%M')}"
echo "Committing with message: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

# 推送
echo ""
echo "Pushing to origin/main..."
git push -u origin main

echo ""
echo "Successfully pushed to GitHub!"
echo "View at: https://github.com/aistrad/work"
