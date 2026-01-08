#!/bin/bash
# Show Status Script
# 显示当前配置状态

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示配置状态
show_status() {
    echo "================================"
    echo "  Claude Alias 当前配置状态"
    echo "================================"
    echo ""

    # 显示当前 alias
    echo -e "${BLUE}当前 Alias:${NC}"
    if [[ "$ANTHROPIC_BASE_URL" == *"z.ai"* ]]; then
        echo "  glm (Z.AI / ChatGLM-4)"
    elif [[ "$ANTHROPIC_BASE_URL" == *"anthropic.com"* ]]; then
        echo "  claude/cc (Anthropic 官方)"
    else
        echo "  未知或未配置"
    fi
    echo ""

    # 显示配置详情
    echo -e "${BLUE}配置详情:${NC}"
    echo "  API Endpoint: ${ANTHROPIC_BASE_URL:-未设置}"
    echo "  Opus Model: ${ANTHROPIC_DEFAULT_OPUS_MODEL:-未设置}"
    echo "  Sonnet Model: ${ANTHROPIC_DEFAULT_SONNET_MODEL:-未设置}"
    echo "  Haiku Model: ${ANTHROPIC_DEFAULT_HAIKU_MODEL:-未设置}"
    echo ""

    # 显示认证方式
    echo -e "${BLUE}认证方式:${NC}"
    if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
        echo "  自定义 Token (Z.AI)"
    else
        echo "  默认认证 (Anthropic 官方)"
    fi
    echo ""

    # 显示可用的 alias
    echo -e "${BLUE}可用的 Alias:${NC}"
    echo "  glm       - Z.AI GLM-4.7"
    echo "  claude    - Anthropic Claude (htdong@gmail.com)"
    echo "  cc        - Anthropic Claude (aiscendtech@gmail.com)"
    echo ""

    # 显示使用提示
    echo -e "${YELLOW}提示:${NC}"
    echo "  使用 'glm <command>' 切换到 GLM"
    echo "  使用 'claude <command>' 切换到 Claude 官方"
    echo "  使用 'cc <command>' 切换到 CC 配置"
    echo ""
}

# 主函数
main() {
    show_status
}

main
