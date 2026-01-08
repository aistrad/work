---
name: cc-refresh
description: Claude Code Alias 管理；用于在不同 Claude/G LM 配置之间快速切换（glm/claude/cc）；支持环境变量配置、模型选择与凭据管理；默认交互式确认后应用配置。
---

# Overview and Intent

## 0. 适用场景与核心目标

- **适用对象**：需要在多个 Claude/G LM 配置之间切换的开发者。
- **核心目标**：
  1) 提供统一的 alias 管理接口（glm/claude/cc）
  2) 支持快速切换不同的 API endpoint 和模型
  3) 管理不同的认证凭据（API keys）
  4) 简化配置流程，避免手动设置环境变量

## 1. 支持的 Alias 配置

### 1.1 glm（Z.AI / ChatGLM-4）
- **API Endpoint**: `https://api.z.ai/api/anthropic`
- **Models**:
  - Opus: `glm-4.7`
  - Sonnet: `glm-4.7`
  - Haiku: `glm-4.5-air`
- **Auth**: 使用 Z.AI API Key

### 1.2 claude（htdong@gmail.com Subscription）
- **API Endpoint**: `https://api.anthropic.com`
- **Models**:
  - Opus: `claude-opus-4-5-20251101`
  - Sonnet: `claude-sonnet-4-5-20250929`
  - Haiku: `claude-haiku-4-5-20250929`
- **Auth**: 使用 Anthropic 官方认证

### 1.3 cc（Neurax API Key 认证）
- **API Endpoint**: `http://47.122.42.83:8080`
- **Models**:
  - Opus: `claude-opus-4-5-20251101`
  - Sonnet: `claude-sonnet-4-5-20250929`
  - Haiku: `claude-haiku-4-5-20250929`
- **Auth**: 使用 Neurax API Key 认证（API Key: sk-neurax-ab0244236571241006e93bf950496d09）
- **配置方式**: 在 ~/.bashrc 中定义为函数，使用 export 设置环境变量

## 2. 使用方式

### 2.1 通过 Shell Alias/Function
```bash
# 使用 GLM 模型
glm <your-command>

# 使用 Claude 官方模型（htdong@gmail.com，付费）
claude <your-command>

# 使用 API Key 认证（cc 函数）
cc <your-command>
```

### 2.2 通过环境变量
```bash
# GLM 配置
export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
export ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7
export ANTHROPIC_AUTH_TOKEN=<your-zai-key>

# Claude 官方配置（htdong@gmail.com）
# 不设置环境变量，使用默认认证

# CC 配置（Neurax API Key）
export ANTHROPIC_BASE_URL=https://200.xstx.info
export ANTHROPIC_API_KEY=sk-etcBrsMBRmBOybA9E1Ev9FMiQpdS9lx2yVqvMvamn9Q2T8WE
```

### 2.3 通过 settings.json
在 `~/.claude/settings.json` 中添加：
```json
{
  "env": {
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic"
  }
}
```

## 3. 核心原则

1. **安全性优先**：API Key 不应硬编码在脚本中，优先使用环境变量
2. **配置隔离**：不同 alias 的配置互不干扰
3. **用户确认**：修改配置前需要用户确认
4. **可追溯性**：记录配置变更历史

---

# Quick Start

1) 选择需要的 alias（glm/claude/cc）
2) 执行对应的 alias 命令
3) 确认配置已应用
4) 开始使用对应的模型

---

# Workflows

## Workflow 1：初始化 Alias 配置

**触发**：用户首次使用 cc-refresh skill

**步骤**：
1. 检查当前 shell 配置（~/.bashrc 或 ~/.zshrc）
2. 询问用户需要配置哪些 alias
3. 生成 alias 配置脚本
4. 添加到 shell 配置文件
5. 提示用户重新加载 shell 配置

**输出**：
- Alias 配置已添加到 shell 配置文件
- 使用说明

## Workflow 2：切换 Alias

**触发**：用户执行 glm/claude/cc 命令

**步骤**：
1. 检查当前环境变量
2. 设置对应的环境变量
3. 执行 claude 命令
4. 清理临时环境变量（如果需要）

**输出**：
- 执行结果
- 当前使用的模型信息

## Workflow 3：验证配置

**触发**：用户想要确认当前配置

**步骤**：
1. 读取当前环境变量
2. 显示当前 API endpoint
3. 显示当前模型配置
4. 测试 API 连接（可选）

**输出**：
- 当前配置摘要
- 连接状态

---

# Reference Documentation

## A. 环境变量参考

| 变量名 | 说明 | GLM 示例 | Claude 示例 | CC 示例 |
|--------|------|----------|-------------|---------|
| `ANTHROPIC_BASE_URL` | API Endpoint | `https://api.z.ai/api/anthropic` | `https://api.anthropic.com` | `http://47.122.42.83:8080` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Opus 模型 | `glm-4.7` | `claude-opus-4-5-20251101` | `claude-opus-4-5-20251101` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Sonnet 模型 | `glm-4.7` | `claude-sonnet-4-5-20250929` | `claude-sonnet-4-5-20250929` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Haiku 模型 | `glm-4.5-air` | `claude-haiku-4-5-20250929` | `claude-haiku-4-5-20250929` |
| `ANTHROPIC_AUTH_TOKEN` | API Token (GLM) | Z.AI API Key | - | - |
| `ANTHROPIC_API_KEY` | API Key | - | - | Neurax API Key |

## B. 故障排查

### B.1 Alias 不生效
**症状**：执行 glm/claude/cc 命令提示找不到命令

**解决方案**：
1. 确认 alias 已添加到 shell 配置文件
2. 执行 `source ~/.bashrc` 或 `source ~/.zshrc`
3. 检查 alias 是否正确注册：`alias glm`

### B.2 API 调用失败
**症状**：提示认证失败或网络错误

**解决方案**：
1. 确认 API Key 正确
2. 确认网络连接正常
3. 检查 API endpoint 是否正确
4. 查看 API 状态页面

### B.3 模型不匹配
**症状**：使用了错误的模型

**解决方案**：
1. 检查环境变量是否正确设置
2. 使用 `/status` 命令查看当前模型
3. 手动指定模型：`claude --model glm-4.7`

## C. 配置文件位置

- Shell 配置：`~/.bashrc` 或 `~/.zshrc`
- Claude Code 配置：`~/.claude/settings.json`
- Skill 脚本：`~/.claude/skills/cc-refresh/scripts/`

## D. 相关资源

- [Z.AI GLM 集成文档](https://docs.z.ai/scenario-example/develop-tools/claude)
- [Claude Code 官方文档](https://docs.anthropic.com/en/docs/claude-code/overview)
- [API Key 管理](/home/aiscend/work/docs/apikey.md)

---

# Examples

## Example 1：首次设置 GLM Alias

```bash
# 1. 加载 cc-refresh skill
# 2. 执行初始化
cc-refresh init --alias glm

# 3. 添加到 shell 配置
echo "source ~/.claude/skills/cc-refresh/scripts/alias_setup.sh" >> ~/.bashrc
source ~/.bashrc

# 4. 测试
glm --version
```

## Example 2：临时切换到 Claude 官方模型

```bash
# 不修改配置，临时使用
ANTHROPIC_BASE_URL=https://api.anthropic.com \
ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-5-20251101 \
claude --help
```



---

# Troubleshooting Guide

## 常见问题

**Q: 如何确认当前使用的是哪个模型？**
A: 在 Claude Code 中执行 `/status` 命令

**Q: 可否同时使用多个配置？**
A: 可以，但需要通过不同的 shell 会话或临时环境变量

**Q: 如何回滚到默认配置？**
A: 删除 `~/.claude/settings.json` 中的 `env` 配置，或重新登录

**Q: GLM 模型支持哪些功能？**
A: 大部分 Anthropic API 功能都支持，但可能有细微差异

---

# Changelog

