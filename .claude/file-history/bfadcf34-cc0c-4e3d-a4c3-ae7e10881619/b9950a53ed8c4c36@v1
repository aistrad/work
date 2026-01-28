#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== sync-work: Full Sync & Push ==="
echo ""

# Step 1: Sync files
"$SCRIPT_DIR/sync.sh"

echo ""
echo "=========================================="
echo ""

# Step 2: Push to GitHub
"$SCRIPT_DIR/push.sh" "$@"
