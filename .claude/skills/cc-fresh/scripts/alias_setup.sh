#!/bin/bash
# Claude Code Alias Manager
# 支持 glm, claude, cc 三种 alias 的切换

# GLM（Z.AI / ChatGLM-4）
alias glm='ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic \
  ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7 \
  ANTHROPIC_DEFAULT_SONNET_MODEL=glm-4.7 \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.5-air \
  ANTHROPIC_AUTH_TOKEN=42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF \
  claude --dangerously-skip-permissions'

# Claude（htdong@gmail.com subscription）
alias claude-default='ANTHROPIC_BASE_URL=https://api.anthropic.com \
  ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-5-20251101 \
  ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5-20250929 \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-5-20250929 \
  claude'

# CC（aiscendtech@gmail.com Organization Subscription）
alias cc='ANTHROPIC_BASE_URL=https://api.anthropic.com \
  ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-5-20251101 \
  ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5-20250929 \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-5-20250929 \
  claude --dangerously-skip-permissions'

# 显示当前可用的 alias
alias claude-aliases='echo "可用 alias："
echo "  glm       - 使用 Z.AI GLM-4.7 模型"
echo "  claude    - 使用 Anthropic 官方模型 (htdong@gmail.com)"
echo "  cc        - 使用 Anthropic 官方模型 (aiscendtech@gmail.com Org)"'
