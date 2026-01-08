# CC-Fresh Skill - Claude Alias Manager

快速切换不同的 Claude/G LM 配置（glm/claude/cc）

## 快速开始

### 1. 加载 Alias

在你的 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
source ~/.claude/skills/cc-fresh/scripts/alias_setup.sh
```

然后重新加载配置：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

### 2. 使用 Alias

```bash
# 使用 GLM 模型
glm --help

# 使用 Claude 官方模型（htdong@gmail.com）
claude --help

# 使用 Claude 官方模型（aiscendtech@gmail.com Org）
cc --help
```

### 3. 查看状态

```bash
# 验证配置
~/.claude/skills/cc-fresh/scripts/verify_config.sh

# 显示状态
~/.claude/skills/cc-fresh/scripts/show_status.sh
```

## 功能特性

- ✅ 支持三种 alias：glm（Z.AI）、claude（官方）、cc（Org）
- ✅ 快速切换不同的 API endpoint 和模型
- ✅ 环境变量自动配置
- ✅ 配置验证和状态显示

## 配置说明

### GLM（Z.AI / ChatGLM-4）
- API: `https://api.z.ai/api/anthropic`
- Models: `glm-4.7`, `glm-4.5-air`

### Claude（官方）
- API: `https://api.anthropic.com`
- Models: `claude-opus-4-5-20251101`, `claude-sonnet-4-5-20250929`

### CC（Org Subscription）
- API: `https://api.anthropic.com`
- Models: 同上，不同的账号和计费

## 故障排查

### Alias 不生效
确认 alias 已加载：
```bash
alias glm
```

如果未找到，检查是否已 source 配置文件。

### API 调用失败
1. 检查网络连接
2. 验证 API Key 是否正确
3. 查看当前配置：`~/.claude/skills/cc-fresh/scripts/show_status.sh`

## 相关文档

- [Z.AI GLM 集成文档](https://docs.z.ai/scenario-example/develop-tools/claude)
- [API Key 管理](/home/aiscend/work/docs/apikey.md)
- [完整文档](SKILL.md)
