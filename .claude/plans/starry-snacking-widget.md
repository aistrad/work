# Claude Code Alias 配置诊断和修复计划

## 用户需求
1. `claude` alias - 使用 htdong@gmail.com 账户登录
2. `cc` alias - 使用 API Key 登录
3. `glm` alias - 使用 GLM 4.7 模型

## 当前状态分析

### Alias 定义 (~/.bashrc)
✓ **已正确配置**（lines 174, 177, 180）
```bash
# claude: 清除环境变量，使用账户登录
alias claude='env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL /home/aiscend/.local/bin/claude --dangerously-skip-permissions'

# glm: 使用 Z.AI GLM 4.7
alias glm='ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7 ANTHROPIC_DEFAULT_SONNET_MODEL=glm-4.7 ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.7 ANTHROPIC_AUTH_TOKEN=$ZAI_GLM_KEY /home/aiscend/.local/bin/claude --dangerously-skip-permissions'

# cc: 使用 API Key（Neurax API）
alias cc='env -u ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL_CC /home/aiscend/.local/bin/claude --dangerously-skip-permissions'
```

### 环境变量配置 (~/.claude/env)
✓ **已正确配置**
```bash
export ZAI_GLM_KEY='42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF'
export ANTHROPIC_API_KEY="sk-etcBrsMBRmBOybA9E1Ev9FMiQpdS9lx2yVqvMvamn9Q2T8WE"
export ANTHROPIC_BASE_URL_CC="https://200.xstx.info"
```

### 自动加载机制 (~/.bashrc line 170)
✓ **已配置**
```bash
[ -f "$HOME/.claude/env" ] && source "$HOME/.claude/env"
```

## 诊断结果

### ✓ 配置完全正确！

经过详细验证，所有配置都已正确设置：

1. **环境变量加载机制** (~/.bashrc:170)
   - ✓ 正确配置自动加载 ~/.claude/env
   - ✓ 只在 interactive shell 中生效（标准 bash 行为，lines 7-10）

2. **环境变量定义** (~/.claude/env)
   - ✓ ZAI_GLM_KEY 正确设置
   - ✓ ANTHROPIC_API_KEY 正确设置
   - ✓ ANTHROPIC_BASE_URL_CC 正确设置

3. **Alias 定义** (~/.bashrc:174,177,180)
   - ✓ `claude` - 清除环境变量，使用账户登录
   - ✓ `cc` - 使用 API Key 和自定义 base URL
   - ✓ `glm` - 使用 GLM 4.7 模型

### 测试验证

在 **interactive shell** 中（用户实际使用的终端）：
- ✓ 所有三个 alias 正确定义
- ✓ ANTHROPIC_API_KEY 长度 51（正确加载）
- ✓ ZAI_GLM_KEY 长度 49（正确加载）
- ✓ ANTHROPIC_BASE_URL_CC 正确设置

### 发现的小问题

**唯一的小问题**: ~/.bashrc line 140 中有一个被注释的旧 ANTHROPIC_API_KEY
- 不影响功能，但可能造成混淆
- 建议清理以保持配置清晰

## 操作建议

### 主要操作：重新加载配置

如果是在一个旧的 shell 会话中（在 ~/.claude/env 创建之前启动的），需要重新加载：

```bash
# 方式1: 重新加载 bashrc
source ~/.bashrc

# 方式2: 重启终端（更彻底）
# 关闭并重新打开终端
```

### 可选优化：清理配置

**清理 ~/.bashrc line 140** 的被注释 ANTHROPIC_API_KEY：
```bash
# 当前 (line 140):
# export ANTHROPIC_API_KEY="sk-ant-api03-rbOC..."

# 建议: 完全删除此行，统一使用 ~/.claude/env
```

好处：
- 避免配置混淆
- 单一可信源（~/.claude/env）
- 由 cc-refresh skill 统一管理

## 验证步骤

执行以下命令验证配置：

```bash
# 1. 重新加载配置
source ~/.bashrc

# 2. 验证环境变量
echo "ZAI_GLM_KEY length: ${#ZAI_GLM_KEY}"           # 应该是 49
echo "ANTHROPIC_API_KEY length: ${#ANTHROPIC_API_KEY}" # 应该是 51
echo "ANTHROPIC_BASE_URL_CC: $ANTHROPIC_BASE_URL_CC"   # 应该是 https://200.xstx.info

# 3. 验证 alias
type claude  # 应该显示 alias 定义
type cc      # 应该显示 alias 定义
type glm     # 应该显示 alias 定义

# 4. 测试 alias（可选）
claude --version  # 应该使用账户登录
cc --version      # 应该使用 API Key
glm --version     # 应该使用 GLM API
```

## 关键文件
- `/home/aiscend/.bashrc` (lines 140, 170, 174, 177, 180)
- `/home/aiscend/.claude/env`
- `/home/aiscend/work/docs/apikey.md` (参考文档)

## 结论

### ✅ 配置完全符合要求！

所有三个 alias 都已正确配置，完全符合用户需求：

| Alias | 认证方式 | 配置状态 | 说明 |
|-------|---------|---------|------|
| `claude` | htdong@gmail.com 账户 | ✓ 正确 | 清除所有环境变量，使用 subscription |
| `cc` | API Key | ✓ 正确 | 使用 Neurax API (200.xstx.info) |
| `glm` | GLM 4.7 | ✓ 正确 | 通过 Z.AI 调用 GLM 模型 |

### 下一步操作

1. **必要**: 重新加载配置
   ```bash
   source ~/.bashrc
   ```

2. **可选**: 清理 ~/.bashrc line 140 的旧配置注释

3. **验证**: 运行测试命令确认一切正常

配置已经完美设置，无需修改！

## 执行计划

如果用户确认后，将执行以下操作：

### 操作 1: 清理旧配置（可选）
**文件**: /home/aiscend/.bashrc
**行**: 140
**操作**: 删除被注释的旧 ANTHROPIC_API_KEY 行
```bash
# 删除这一行:
# export ANTHROPIC_API_KEY="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"
```

### 操作 2: 验证配置
在当前 shell 中重新加载并验证所有 alias 正常工作：
```bash
# 重新加载
source ~/.bashrc

# 验证环境变量
echo "ZAI_GLM_KEY length: ${#ZAI_GLM_KEY}"
echo "ANTHROPIC_API_KEY length: ${#ANTHROPIC_API_KEY}"
echo "ANTHROPIC_BASE_URL_CC: $ANTHROPIC_BASE_URL_CC"

# 验证 alias
type claude
type cc
type glm
```

### 预期结果
- ✓ 三个 alias 都正确定义
- ✓ 所有环境变量正确加载
- ✓ 配置文件清晰，无冗余注释
