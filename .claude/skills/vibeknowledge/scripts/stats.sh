#!/bin/bash
# VibeLife Knowledge Stats
# 显示知识库统计信息

set -e

VIBELIFE_ROOT="${VIBELIFE_ROOT:-/home/aiscend/work/vibelife}"

cd "$VIBELIFE_ROOT"

# 加载环境变量
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# 显示统计
python -m apps.api.scripts.sync_knowledge --stats
