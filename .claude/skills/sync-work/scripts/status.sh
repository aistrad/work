#!/bin/bash

SYNC_DIR="${SYNC_DIR:-$HOME/.work-sync}"

echo "=== sync-work: Status ==="
echo ""

if [ ! -d "$SYNC_DIR/.git" ]; then
    echo "Sync directory not initialized."
    echo "Run '/sync-work sync' to initialize."
    exit 0
fi

cd "$SYNC_DIR"

echo "Sync directory: $SYNC_DIR"
echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'not set')"
echo "Branch: $(git branch --show-current)"
echo ""

# 显示最近的提交
echo "=== Recent Commits ==="
git log --oneline -5 2>/dev/null || echo "(no commits yet)"
echo ""

# 显示当前状态
echo "=== Pending Changes ==="
git status --short

# 统计
echo ""
echo "=== Statistics ==="
if [ -d ".claude" ]; then
    echo ".claude/: $(find .claude -type f | wc -l) files"
fi
if [ -d "docs" ]; then
    echo "docs/: $(find docs -type f | wc -l) files"
fi
for proj in AIS fortune_ai vibelife cli_worker mentis; do
    if [ -d "$proj/docs" ]; then
        echo "$proj/docs/: $(find $proj/docs -type f | wc -l) files"
    fi
done
