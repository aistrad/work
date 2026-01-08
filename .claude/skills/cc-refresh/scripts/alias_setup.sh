#!/bin/bash
# Claude Code Alias Manager (cc-refresh skill)
# 支持 glm, claude, cc 三种 function 的切换

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GLM_BASE_URL="https://api.z.ai/api/anthropic"
CLAUDE_BASE_URL="https://api.anthropic.com"
CC_BASE_URL="http://47.122.42.83:8080"

GLM() {
    source "$SCRIPT_DIR/load_apikey_config.sh"

    unset ANTHROPIC_API_KEY
    ANTHROPIC_BASE_URL="$GLM_BASE_URL" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.7" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
        ANTHROPIC_AUTH_TOKEN="$GLM_KEY" \
        claude --dangerously-skip-permissions "$@"
}

claude-default() {
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929" \
        claude "$@"
}

cc() {
    source "$SCRIPT_DIR/load_apikey_config.sh"

    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    ANTHROPIC_API_KEY="$CC_API_KEY" \
        ANTHROPIC_BASE_URL="$CC_BASE_URL" \
        ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101" \
        ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929" \
        ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929" \
        claude "$@"
}

claude-aliases() {
    source "$SCRIPT_DIR/load_apikey_config.sh"

    echo "可用 function："
    echo "  GLM       - 使用 Z.AI GLM-4.7 模型 (从 apikey.md 读取)"
    echo "  claude-default - 使用 Anthropic 官方模型 (htdong@gmail.com, 付费)"
    echo "  cc        - 使用 Neurax API Key (从 apikey.md 读取)"
    echo ""
    echo "当前配置 (从 apikey.md)："
    echo "  CC Base URL: $CC_BASE_URL"
    echo "  GLM Key: ${GLM_KEY:0:8}..."
    echo "  CC Key: ${CC_API_KEY:0:8}..."
}
