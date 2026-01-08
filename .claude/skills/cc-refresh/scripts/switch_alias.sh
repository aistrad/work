#!/bin/bash
# Switch Alias Script
# 用于切换不同的 Claude/GLM alias

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load_apikey_config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

save_current_config() {
    cat > /tmp/claude_alias_prev.txt <<EOF
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-}
ANTHROPIC_DEFAULT_OPUS_MODEL=${ANTHROPIC_DEFAULT_OPUS_MODEL:-}
ANTHROPIC_DEFAULT_SONNET_MODEL=${ANTHROPIC_DEFAULT_SONNET_MODEL:-}
ANTHROPIC_DEFAULT_HAIKU_MODEL=${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}
EOF
}

switch_to_glm() {
    echo -e "${GREEN}切换到 GLM (Z.AI)${NC}"

    unset ANTHROPIC_API_KEY
    export ANTHROPIC_BASE_URL="$GLM_BASE_URL"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.7"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
    export ANTHROPIC_AUTH_TOKEN="$GLM_KEY"

    echo "  Endpoint: $GLM_BASE_URL"
    echo "  Opus: glm-4.7"
    echo "  Sonnet: glm-4.7"
    echo "  Haiku: glm-4.5-air"
}

switch_to_claude() {
    echo -e "${GREEN}切换到 Claude (htdong@gmail.com)${NC}"

    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    export ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929"

    echo "  Endpoint: $CLAUDE_BASE_URL"
    echo "  Opus: claude-opus-4-5-20251101"
    echo "  Sonnet: claude-sonnet-4-5-20250929"
    echo "  Haiku: claude-haiku-4-5-20250929"
}

switch_to_cc() {
    echo -e "${GREEN}切换到 CC (Neurax API)${NC}"

    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    export ANTHROPIC_BASE_URL="$CC_BASE_URL"
    export ANTHROPIC_API_KEY="$CC_API_KEY"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929"

    echo "  Endpoint: $CC_BASE_URL"
    echo "  Opus: claude-opus-4-5-20251101"
    echo "  Sonnet: claude-sonnet-4-5-20250929"
    echo "  Haiku: claude-haiku-4-5-20250929"
}

main() {
    local alias_name="$1"

    if [ -z "$alias_name" ]; then
        echo -e "${RED}错误：请指定要切换的 alias (glm/claude/cc)${NC}"
        echo "用法: $0 <glm|claude|cc>"
        exit 1
    fi

    save_current_config

    case "$alias_name" in
        glm)
            switch_to_glm
            ;;
        claude)
            switch_to_claude
            ;;
        cc)
            switch_to_cc
            ;;
        *)
            echo -e "${RED}错误：未知的 alias '$alias_name'${NC}"
            echo "支持的 alias: glm, claude, cc"
            exit 1
            ;;
    esac

    echo -e "${GREEN}✓ 切换完成${NC}"
}

main "$@"
