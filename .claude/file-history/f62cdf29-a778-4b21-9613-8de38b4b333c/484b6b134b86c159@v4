#!/bin/bash
# VibeLife Knowledge: sync + ingest
# 默认入口：扫描文档并处理

set -e

export VIBELIFE_ROOT="${VIBELIFE_ROOT:-/home/aiscend/work/vibelife}"

cd "$VIBELIFE_ROOT"

# 加载环境变量
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Step 1: 同步文档
echo "=== Step 1: Syncing knowledge documents ==="
python -m apps.api.scripts.sync_knowledge "$@"

# Step 2: 处理文档
echo ""
echo "=== Step 2: Processing pending documents ==="
python -c "
import asyncio
import sys
import os
sys.path.insert(0, 'apps/api')

# Load environment from .env file
from dotenv import load_dotenv
import pathlib
env_path = pathlib.Path(os.environ.get('VIBELIFE_ROOT', '/home/aiscend/work/vibelife')) / '.env'
load_dotenv(str(env_path), override=True)

from stores.db import init_db, close_db
from workers.ingestion import IngestionWorker

async def process_all():
    await init_db()
    worker = IngestionWorker()
    count = 0

    while True:
        doc = await worker._claim_document()
        if not doc:
            break
        await worker._process_document(doc)
        count += 1

    await close_db()
    if count > 0:
        print(f'Processed {count} document(s).')
    else:
        print('No pending documents.')

asyncio.run(process_all())
"

# Step 3: 显示统计
echo ""
echo "=== Done ==="
python -m apps.api.scripts.sync_knowledge --stats
