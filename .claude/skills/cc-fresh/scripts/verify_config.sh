#!/bin/bash
# Verify Config Script
# 验证当前配置是否正确

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 验证配置
verify_config() {
    local has_error=0

    echo "验证当前配置..."

    # 检查 ANTHROPIC_BASE_URL
    if [ -z "$ANTHROPIC_BASE_URL" ]; then
        echo -e "${RED}✗ ANTHROPIC_BASE_URL 未设置${NC}"
        has_error=1
    else
        echo -e "${GREEN}✓${NC} ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
    fi

    # 检查模型配置
    if [ -z "$ANTHROPIC_DEFAULT_OPUS_MODEL" ]; then
        echo -e "${YELLOW}⚠${NC} ANTHROPIC_DEFAULT_OPUS_MODEL 未设置"
    else
        echo -e "${GREEN}✓${NC} ANTHROPIC_DEFAULT_OPUS_MODEL: $ANTHROPIC_DEFAULT_OPUS_MODEL"
    fi

    if [ -z "$ANTHROPIC_DEFAULT_SONNET_MODEL" ]; then
        echo -e "${YELLOW}⚠${NC} ANTHROPIC_DEFAULT_SONNET_MODEL 未设置"
    else
        echo -e "${GREEN}✓${NC} ANTHROPIC_DEFAULT_SONNET_MODEL: $ANTHROPIC_DEFAULT_SONNET_MODEL"
    fi

    if [ -z "$ANTHROPIC_DEFAULT_HAIKU_MODEL" ]; then
        echo -e "${YELLOW}⚠${NC} ANTHROPIC_DEFAULT_HAIKU_MODEL 未设置"
    else
        echo -e "${GREEN}✓${NC} ANTHROPIC_DEFAULT_HAIKU_MODEL: $ANTHROPIC_DEFAULT_HAIKU_MODEL"
    fi

    # 检查认证
    if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
        echo -e "${GREEN}✓${NC} ANTHROPIC_AUTH_TOKEN: 已设置（使用自定义认证）"
    else
        echo -e "${GREEN}✓${NC} ANTHROPIC_AUTH_TOKEN: 未设置（使用默认认证）"
    fi

    # 推断当前 alias
    echo ""
    echo "当前使用的 alias："
    if [[ "$ANTHROPIC_BASE_URL" == *"z.ai"* ]]; then
        echo -e "${GREEN}glm${NC} (Z.AI / ChatGLM-4)"
    elif [[ "$ANTHROPIC_BASE_URL" == *"anthropic.com"* ]]; then
        echo -e "${GREEN}claude/cc${NC} (Anthropic 官方)"
    else
        echo -e "${YELLOW}未知${NC}"
    fi

    return $has_error
}

# 主函数
main() {
    verify_config

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}配置验证通过${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}配置存在问题${NC}"
        exit 1
    fi
}

main
