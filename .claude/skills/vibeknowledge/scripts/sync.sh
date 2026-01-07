#!/bin/bash
# VibeLife Knowledge Sync Script
# 只扫描文档，不处理

set -e

VIBELIFE_ROOT="${VIBELIFE_ROOT:-/home/aiscend/work/vibelife}"

cd "$VIBELIFE_ROOT"

# 加载环境变量
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# 执行同步脚本
python -m apps.api.scripts.sync_knowledge "$@"
