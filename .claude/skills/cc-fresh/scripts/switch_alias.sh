#!/bin/bash
# Switch Alias Script
# 用于切换不同的 Claude/GLM alias

set -e

# 配置
GLM_KEY="42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF"
GLM_BASE_URL="https://api.z.ai/api/anthropic"
CLAUDE_BASE_URL="https://api.anthropic.com"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 记录当前配置
save_current_config() {
    cat > /tmp/claude_alias_prev.txt <<EOF
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-}
ANTHROPIC_DEFAULT_OPUS_MODEL=${ANTHROPIC_DEFAULT_OPUS_MODEL:-}
ANTHROPIC_DEFAULT_SONNET_MODEL=${ANTHROPIC_DEFAULT_SONNET_MODEL:-}
ANTHROPIC_DEFAULT_HAIKU_MODEL=${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}
EOF
}

# 切换到 GLM
switch_to_glm() {
    echo -e "${GREEN}切换到 GLM (Z.AI)${NC}"

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

# 切换到 Claude（htdong@gmail.com）
switch_to_claude() {
    echo -e "${GREEN}切换到 Claude (htdong@gmail.com)${NC}"

    export ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929"
    unset ANTHROPIC_AUTH_TOKEN

    echo "  Endpoint: $CLAUDE_BASE_URL"
    echo "  Opus: claude-opus-4-5-20251101"
    echo "  Sonnet: claude-sonnet-4-5-20250929"
    echo "  Haiku: claude-haiku-4-5-20250929"
}

# 切换到 CC（aiscendtech@gmail.com）
switch_to_cc() {
    echo -e "${GREEN}切换到 CC (aiscendtech@gmail.com)${NC}"

    export ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-5-20251101"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20250929"
    unset ANTHROPIC_AUTH_TOKEN

    echo "  Endpoint: $CLAUDE_BASE_URL"
    echo "  Opus: claude-opus-4-5-20251101"
    echo "  Sonnet: claude-sonnet-4-5-20250929"
    echo "  Haiku: claude-haiku-4-5-20250929"
}

# 主函数
main() {
    local alias_name="$1"

    if [ -z "$alias_name" ]; then
        echo -e "${RED}错误：请指定要切换的 alias (glm/claude/cc)${NC}"
        echo "用法: $0 <glm|claude|cc>"
        exit 1
    fi

    # 保存当前配置
    save_current_config

    # 切换到指定 alias
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
