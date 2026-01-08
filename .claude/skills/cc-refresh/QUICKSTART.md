# CC-Fresh 快速使用指南

## 1. 启用 Alias

将以下内容添加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
# CC-Fresh Alias Manager
source ~/.claude/skills/cc-fresh/scripts/alias_setup.sh
```

然后重新加载：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

## 2. 使用方式

### GLM（Z.AI / ChatGLM-4）
```bash
glm <your-command>
```
- 使用 GLM-4.7 模型
- API: `https://api.z.ai/api/anthropic`
- 适合：快速测试、成本优化

### Claude（htdong@gmail.com）
```bash
claude <your-command>
```
- 使用 Claude 官方模型
- API: `https://api.anthropic.com`
- 个人订阅账号

### CC（aiscendtech@gmail.com Org）
```bash
cc <your-command>
```
- 使用 Claude 官方模型
- API: `https://api.anthropic.com`
- 组织订阅账号

## 3. 验证配置

```bash
# 查看当前状态
claude-aliases

# 验证配置
~/.claude/skills/cc-fresh/scripts/verify_config.sh

# 显示详细信息
~/.claude/skills/cc-fresh/scripts/show_status.sh
```

## 4. 示例

```bash
# 使用 GLM 生成代码
glm "帮我写一个 Python 函数"

# 使用 Claude 官方模型进行代码审查
cc "审查这段代码的性能问题"

# 查看当前使用的模型
claude-aliases
```

## 5. 注意事项

- ⚠️ GLM API Key 已包含在 alias 中，无需额外配置
- ⚠️ Claude 和 cc 使用不同的账号，计费独立
- ⚠️ 如需临时切换，可直接使用环境变量：

```bash
# 临时使用 GLM
ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic \
ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7 \
claude <command>
```

## 6. 故障排查

### Alias 不生效
```bash
# 检查 alias 是否加载
alias glm

# 重新加载配置
source ~/.bashrc
```

### API 调用失败
```bash
# 检查网络连接
curl -I https://api.z.ai/api/anthropic

# 验证配置
~/.claude/skills/cc-fresh/scripts/verify_config.sh
```

## 相关资源

- 完整文档: `~/.claude/skills/cc-fresh/SKILL.md`
- API Key 管理: `/home/aiscend/work/docs/apikey.md`
- Z.AI 集成指南: https://docs.z.ai/scenario-example/develop-tools/claude
