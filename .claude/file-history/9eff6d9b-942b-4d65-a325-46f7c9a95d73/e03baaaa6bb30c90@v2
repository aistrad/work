# Bashrc 简化和优化计划

## 问题分析

### 当前发现的主要问题：

#### 1. 重复的 PATH 配置 🔴
- `$HOME/.local/bin` 被添加了 **2次**（第160行和第185行）
- `$HOME/.dotnet` 被添加了 **2次**（第161行和第162行）
- PATH 配置分散在多个位置（第160-165行、185行、193行、196行）

#### 2. 配置结构混乱 🔴
- 环境变量散布在文件各处
- 缺少清晰的分段注释
- 没有逻辑分组

#### 3. 敏感信息暴露 🔴
- API Keys（OpenAI, DeepSeek等）直接写在 bashrc 中
- 不利于版本控制和备份时的敏感信息保护

#### 4. 代理配置冗余 🟡
- 小写和大写版本同时存在（兼容性需要，但缺少说明）

## 用户决策（已确认）

✅ **API Keys**: 移到单独的 `~/.env` 文件中
✅ **Aliases**: 保持在 bashrc 中
✅ **历史记录**: 增加到 10000（从当前的 1000）
✅ **Conda**: 保留自动激活 'ai' 环境

## 优化方案

### 阶段 1：创建 ~/.env 文件

**目标**: 将敏感的 API Keys 隔离到单独文件

**创建新文件** `~/.env`:
```bash
# API Keys - 敏感信息，请勿提交到版本控制
# 由 ~/.bashrc 自动加载

# Python & General
export PYTHONIOENCODING=utf-8

# Financial & Market Data
export FMP_API_KEY="5jt7ii79BCvV7s2LOyEfzyURxpqNQKYf"

# AI / LLM APIs
export OPENAI_API_KEY="sk-proj-W2xeAJwR8uEoz92NpeP3T3BlbkFJxRO8Z7XdHGUAQqq7z9bk"
export VOYAGE_API_KEY="pa-YdlR1bSJuOVkWCdciJZkoVI54j91enix7iqWRxBP1-U"
export DEEPSEEK_API_KEY="sk-56f469838d6f486f823d620034bb61fe"
export DEEPSEEK_HUOSHAN_API_KEY="7dd54fe0-9cfc-40ce-9a7d-a3fc63dc82ec"
export GOOGLE_SEARCH_API_KEY="AIzaSyAY7QXUs4esnBe8rMZnmZWfnMjaGO3hgb0"
```

**权限设置**: `chmod 600 ~/.env` (只有所有者可读写)

### 阶段 2：重构 ~/.bashrc

**目标**: 清晰的结构、去除重复、添加注释

**新的 bashrc 结构**:

```bash
# ============================================================================
# SECTION 1: 系统默认配置（Ubuntu 标准，保持不变）
# ============================================================================
[行1-118：保持原样]

# ============================================================================
# SECTION 2: 包管理器初始化
# ============================================================================

# >>> conda initialize >>>
[行120-134：保持原样，包括 conda activate ai]

# >>> nvm initialize >>>
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============================================================================
# SECTION 3: 环境变量配置
# ============================================================================

# === 3.1 加载敏感信息（API Keys等） ===
[ -f "$HOME/.env" ] && source "$HOME/.env"

# === 3.2 历史记录配置（优化） ===
# 注意：这部分移到这里是为了覆盖系统默认值
export HISTSIZE=10000
export HISTFILESIZE=20000

# === 3.3 网络代理配置 ===
# 注：同时设置大小写版本以确保兼容性
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export all_proxy=socks5://127.0.0.1:10808
export HTTP_PROXY=http://127.0.0.1:10808
export HTTPS_PROXY=http://127.0.0.1:10808
export ALL_PROXY=socks5://127.0.0.1:10808
export NO_PROXY=.slopus.com,api.cluster-fluster.com,happy-api.slopus.com,localhost,127.0.0.1,.local

# === 3.4 应用特定配置 ===
export HAPPY_SERVER_URL=https://api.cluster-fluster.com
export DOTNET_ROOT="$HOME/.dotnet"
export DOTNET_MULTILEVEL_LOOKUP=0
export BUN_INSTALL="$HOME/.bun"

# ============================================================================
# SECTION 4: PATH 配置（集中管理，去除重复）
# ============================================================================
export PATH="$HOME/.local/bin:$PATH"                      # 用户本地程序
export PATH="$HOME/.dotnet:$DOTNET_ROOT/tools:$PATH"     # .NET SDK
export PATH="$BUN_INSTALL/bin:$PATH"                      # Bun runtime
export PATH="$HOME/.opencode/bin:$PATH"                   # OpenCode

# ============================================================================
# SECTION 5: Aliases 配置
# ============================================================================

# === 5.1 Claude CLI Aliases ===
# 加载 Claude 相关环境变量
[ -f "$HOME/.claude/env" ] && source "$HOME/.claude/env"

# claude: 使用 htdong@gmail.com 官方账号（付费订阅）
alias claude='env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL \
  /home/aiscend/.local/bin/claude --dangerously-skip-permissions'

# cc: 使用 Neurax API Key（主力使用）
alias cc='CLAUDE_CONFIG_DIR=$CC_CONFIG_DIR \
  XDG_STATE_HOME=$CC_STATE_HOME \
  ANTHROPIC_API_KEY=$CC_API_KEY \
  ANTHROPIC_BASE_URL=$CC_BASE_URL \
  ANTHROPIC_DEFAULT_OPUS_MODEL=$CC_OPUS_MODEL \
  ANTHROPIC_DEFAULT_SONNET_MODEL=$CC_SONNET_MODEL \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=$CC_HAIKU_MODEL \
  /home/aiscend/.local/bin/claude --model opus --dangerously-skip-permissions'

# glm: 使用 Z.AI GLM 4.7 模型
alias glm='ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic \
  ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7 \
  ANTHROPIC_DEFAULT_SONNET_MODEL=glm-4.7 \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.7 \
  ANTHROPIC_AUTH_TOKEN=$ZAI_GLM_KEY \
  /home/aiscend/.local/bin/claude --dangerously-skip-permissions'

# === 5.2 其他工具 Aliases ===
# Codex CLI
alias codex='codex -m gpt-5 -c model_reasoning_effort="high" \
  --search --dangerously-bypass-approvals-and-sandbox'

# Gemini CLI
alias gemini='gemini -yolo'

# ============================================================================
# END OF CONFIGURATION
# ============================================================================
```

### 阶段 3：具体的改动列表

**删除的行**:
- 第136-143行：API Keys（移到 ~/.env）
- 第160行：重复的 `$HOME/.local/bin`
- 第162行：重复的 `$HOME/.dotnet`
- 第185行：重复的 `$HOME/.local/bin`

**新增内容**:
- 在 SECTION 3 开头添加：`[ -f "$HOME/.env" ] && source "$HOME/.env"`
- 更新历史记录设置：`HISTSIZE=10000`, `HISTFILESIZE=20000`
- 添加清晰的分段注释

**保持不变**:
- Ubuntu 系统默认配置（行1-118）
- Conda 初始化和自动激活
- NVM 配置
- 所有 aliases（格式化后保持在 bashrc 中）
- 代理配置（保留大小写版本以确保兼容性）

## 关键文件清单

**需要修改的文件**:
1. `~/.bashrc` - 主配置文件（重构）

**需要创建的文件**:
1. `~/.env` - API Keys（新建，权限 600）

**需要保持的文件**:
1. `~/.claude/env` - Claude 相关配置（不变）

## 验证计划

**修改后验证步骤**:

1. **语法检查**:
   ```bash
   bash -n ~/.bashrc  # 检查语法错误
   ```

2. **加载测试**:
   ```bash
   source ~/.bashrc  # 重新加载配置
   ```

3. **环境变量验证**:
   ```bash
   echo $OPENAI_API_KEY  # 验证 API Keys 已加载
   echo $CC_API_KEY      # 验证 Claude 配置
   echo $PATH | tr ':' '\n'  # 验证 PATH 无重复
   ```

4. **Aliases 测试**:
   ```bash
   alias | grep -E "claude|cc|glm|codex|gemini"  # 验证所有 aliases
   ```

5. **历史记录验证**:
   ```bash
   echo $HISTSIZE  # 应该显示 10000
   ```

6. **Conda 环境**:
   ```bash
   conda env list  # 验证 ai 环境已激活
   ```

## 优化效果

**预期改进**:
- ✅ 消除所有 PATH 重复
- ✅ 敏感信息隔离（~/.env 文件权限 600）
- ✅ 清晰的结构和注释（5个主要 section）
- ✅ 历史记录容量增加 10 倍
- ✅ 保持所有现有功能不变
- ✅ 更易于维护和备份

**行数变化**:
- 原文件：197 行
- 优化后：约 180 行（减少 ~9%）
- 新增 ~/.env：15 行

**代码质量**:
- 消除重复：4 处
- 增加注释：5 个主要 section
- 逻辑分组：清晰的功能分区
