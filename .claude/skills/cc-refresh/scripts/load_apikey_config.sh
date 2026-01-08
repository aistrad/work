#!/bin/bash
# 从 apikey.md 读取最新的配置信息

GLM_BASE_URL="${GLM_BASE_URL:-https://api.z.ai/api/anthropic}"
CLAUDE_BASE_URL="${CLAUDE_BASE_URL:-https://api.anthropic.com}"
APIKEY_FILE="${APIKEY_FILE:-$HOME/work/docs/apikey.md}"

if [ ! -f "$APIKEY_FILE" ]; then
    echo "警告：找不到 apikey.md 文件 ($APIKEY_FILE)" >&2
    echo "使用默认配置或环境变量" >&2
fi

load_config_from_apikey() {
    [ ! -f "$APIKEY_FILE" ] && return 0

    local glm_key=$(grep -E "^export ZAI_GLM_KEY=" "$APIKEY_FILE" | sed -E "s/^export ZAI_GLM_KEY='(.*)'$/\1/" || true)
    [ -n "$glm_key" ] && GLM_KEY="$glm_key"

    local cc_api_key=$(grep -E "^export ANTHROPIC_API_KEY=" "$APIKEY_FILE" | sed -E 's/^export ANTHROPIC_API_KEY="(.*)"$/\1/' || true)
    [ -n "$cc_api_key" ] && CC_API_KEY="$cc_api_key"

    local cc_base_url=$(grep -E "^export ANTHROPIC_BASE_URL=" "$APIKEY_FILE" | sed -E 's/^export ANTHROPIC_BASE_URL="(.*)"$/\1/' || true)
    [ -n "$cc_base_url" ] && CC_BASE_URL="$cc_base_url"
}

load_config_from_apikey

export GLM_KEY="${GLM_KEY:-}"
export GLM_BASE_URL="$GLM_BASE_URL"
export CLAUDE_BASE_URL="$CLAUDE_BASE_URL"
export CC_API_KEY="${CC_API_KEY:-}"
export CC_BASE_URL="${CC_BASE_URL:-http://47.122.42.83:8080}"

if [ "$DEBUG_CC_REFRESH" = "1" ]; then
    echo "已加载配置："
    echo "  GLM_KEY: ${GLM_KEY:0:8}..."
    echo "  GLM_BASE_URL: $GLM_BASE_URL"
    echo "  CC_API_KEY: ${CC_API_KEY:0:8}..."
    echo "  CC_BASE_URL: $CC_BASE_URL"
fi
