# Everything Claude Code 完全指南

> 来自 Anthropic 黑客马拉松获胜者的 Claude Code 配置集合。经过 10+ 个月的实际生产环境打磨，包含代理、技能、钩子、命令、规则和 MCP 配置。

---

## 目录

1. [概述](#概述)
2. [安装方法](#安装方法)
3. [核心概念](#核心概念)
4. [代理 (Agents)](#代理-agents)
5. [技能 (Skills)](#技能-skills)
6. [命令 (Commands)](#命令-commands)
7. [规则 (Rules)](#规则-rules)
8. [钩子 (Hooks)](#钩子-hooks)
9. [MCP 配置](#mcp-配置)
10. [上下文管理](#上下文管理)
11. [最佳实践](#最佳实践)
12. [配置示例](#配置示例)

---

## 概述

Everything Claude Code 是一个完整的 Claude Code 配置集合，旨在提高开发效率和代码质量。它包含：

| 组件 | 数量 | 说明 |
|------|------|------|
| 代理 (Agents) | 9 | 专业化子代理，处理特定任务 |
| 技能 (Skills) | 23+ | 工作流定义和领域知识 |
| 命令 (Commands) | 15 | 快速执行的斜杠命令 |
| 规则 (Rules) | 8 | 始终遵循的开发准则 |
| 钩子 (Hooks) | 6+ | 基于事件的自动化触发器 |
| MCP 配置 | 14+ | 外部服务集成 |

### 核心哲学

1. **代理优先** - 将复杂任务委托给专业代理
2. **并行执行** - 独立任务并行处理，提高效率
3. **先规划后执行** - 复杂操作使用 Plan Mode
4. **测试驱动** - 先写测试，再写实现
5. **安全第一** - 永不妥协安全性

---

## 安装方法

### 方式一：作为插件安装（推荐）

```bash
# 添加市场
/plugin marketplace add affaan-m/everything-claude-code

# 安装插件
/plugin install everything-claude-code@everything-claude-code
```

或直接编辑 `~/.claude/settings.json`：

```json
{
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": {
        "source": "github",
        "repo": "affaan-m/everything-claude-code"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

### 方式二：手动安装

```bash
# 克隆仓库
git clone https://github.com/affaan-m/everything-claude-code.git

# 复制组件到 Claude 配置目录
cp everything-claude-code/agents/*.md ~/.claude/agents/
cp everything-claude-code/rules/*.md ~/.claude/rules/
cp everything-claude-code/commands/*.md ~/.claude/commands/
cp -r everything-claude-code/skills/* ~/.claude/skills/
```

然后将 `hooks/hooks.json` 中的钩子配置合并到 `~/.claude/settings.json`。

---

## 核心概念

### 配置文件结构

```
~/.claude/
├── CLAUDE.md           # 用户级配置（全局生效）
├── settings.json       # 主设置文件
├── agents/             # 专业代理定义
├── rules/              # 始终遵循的规则
├── commands/           # 斜杠命令
├── skills/             # 技能和工作流
└── .claude.json        # MCP 服务器配置
```

### 项目级配置

在项目根目录创建 `CLAUDE.md`：

```markdown
# 项目概述
[项目描述、技术栈]

## 关键规则
- 代码组织规范
- 代码风格要求
- 测试要求
- 安全要求

## 文件结构
[项目目录结构说明]

## 可用命令
[项目特定命令]
```

---

## 代理 (Agents)

代理是具有有限范围和特定工具的专业化子代理。它们位于 `~/.claude/agents/` 目录。

### 可用代理列表

| 代理名称 | 用途 | 使用场景 |
|----------|------|----------|
| **planner** | 实现规划专家 | 复杂功能、重构 |
| **architect** | 系统设计 | 架构决策 |
| **tdd-guide** | 测试驱动开发 | 新功能、Bug 修复 |
| **code-reviewer** | 代码审查 | 代码完成后 |
| **security-reviewer** | 安全分析 | 提交前检查 |
| **build-error-resolver** | 构建错误修复 | 构建失败时 |
| **e2e-runner** | E2E 测试 | 关键用户流程 |
| **refactor-cleaner** | 死代码清理 | 代码维护 |
| **doc-updater** | 文档更新 | 文档同步 |

### 代理定义格式

```markdown
---
name: planner
description: 复杂功能实现规划专家
tools: Read, Grep, Glob
model: opus
---

你是一个专业的规划专家...

## 你的角色
- 分析需求，创建详细实现计划
- 将复杂功能分解为可管理的步骤
- 识别依赖关系和潜在风险
...
```

### 立即使用代理的场景

无需用户提示，直接使用：

1. **复杂功能请求** → 使用 `planner` 代理
2. **代码编写/修改后** → 使用 `code-reviewer` 代理
3. **Bug 修复或新功能** → 使用 `tdd-guide` 代理
4. **架构决策** → 使用 `architect` 代理

### 并行任务执行

对于独立操作，始终使用并行 Task 执行：

```markdown
# 正确：并行执行
同时启动 3 个代理：
1. 代理 1: auth.ts 安全分析
2. 代理 2: 缓存系统性能审查
3. 代理 3: utils.ts 类型检查

# 错误：不必要的顺序执行
先代理 1，然后代理 2，然后代理 3
```

---

## 技能 (Skills)

技能是工作流定义和领域知识，由命令或代理调用。位于 `~/.claude/skills/` 目录。

### 主要技能类别

#### 开发模式技能

| 技能 | 说明 |
|------|------|
| **coding-standards** | 语言最佳实践 |
| **backend-patterns** | API、数据库、缓存模式 |
| **frontend-patterns** | React、Next.js 模式 |
| **tdd-workflow** | TDD 方法论 |
| **security-review** | 安全检查清单 |

#### 高级技能（Longform Guide）

| 技能 | 说明 |
|------|------|
| **continuous-learning** | 自动从会话中提取模式 |
| **strategic-compact** | 手动压缩建议 |
| **eval-harness** | 验证循环评估 |
| **verification-loop** | 持续验证 |

### 持续学习技能 (continuous-learning)

自动评估 Claude Code 会话，提取可重用模式并保存为技能。

**工作原理：**
1. **会话评估** - 检查会话消息数量（默认 10+）
2. **模式检测** - 识别可提取的模式
3. **技能提取** - 保存到 `~/.claude/skills/learned/`

**可检测的模式类型：**

| 模式 | 说明 |
|------|------|
| `error_resolution` | 特定错误的解决方式 |
| `user_corrections` | 用户纠正的模式 |
| `workarounds` | 框架/库问题的解决方案 |
| `debugging_techniques` | 有效的调试方法 |
| `project_specific` | 项目特定约定 |

### 策略压缩技能 (strategic-compact)

在逻辑间隔点建议手动 `/compact`，而不是依赖任意的自动压缩。

**为什么需要策略压缩？**

自动压缩的问题：
- 经常在任务中间触发，丢失重要上下文
- 不了解逻辑任务边界
- 可能中断复杂的多步骤操作

策略压缩的优势：
- **探索后、执行前** - 压缩研究上下文，保留实现计划
- **完成里程碑后** - 为下一阶段重新开始
- **重大上下文切换前** - 在不同任务前清除探索上下文

---

## 命令 (Commands)

命令是快速执行的斜杠命令，位于 `~/.claude/commands/` 目录。

### 可用命令列表

| 命令 | 说明 |
|------|------|
| `/tdd` | 测试驱动开发工作流 |
| `/plan` | 创建实现计划 |
| `/code-review` | 代码质量审查 |
| `/e2e` | E2E 测试生成 |
| `/build-fix` | 修复构建错误 |
| `/refactor-clean` | 死代码清理 |
| `/learn` | 会话中提取模式 |
| `/checkpoint` | 保存验证状态 |
| `/verify` | 运行验证循环 |
| `/setup-pm` | 配置包管理器 |
| `/test-coverage` | 验证测试覆盖率 |
| `/update-docs` | 更新文档 |
| `/update-codemaps` | 更新代码地图 |
| `/orchestrate` | 编排命令 |
| `/eval` | 评估命令 |

### /tdd 命令详解

强制执行测试驱动开发工作流。

**执行步骤：**
1. **脚手架接口** - 先定义类型/接口
2. **生成测试** - 编写失败的测试（RED）
3. **实现代码** - 编写最少代码通过测试（GREEN）
4. **重构** - 改进代码保持测试通过（REFACTOR）
5. **验证覆盖率** - 确保 80%+ 测试覆盖率

**TDD 循环：**

```
RED → GREEN → REFACTOR → REPEAT

RED:      编写失败的测试
GREEN:    编写最少代码通过
REFACTOR: 改进代码，保持测试通过
REPEAT:   下一个功能/场景
```

**最佳实践：**

| 应该做 | 不应该做 |
|--------|----------|
| 先写测试，再写实现 | 先写实现再写测试 |
| 每次修改后运行测试 | 跳过测试运行 |
| 编写最少代码通过测试 | 一次写太多代码 |
| 测试行为，不测实现细节 | 模拟所有东西 |

### /plan 命令详解

创建全面的实现计划，在编写任何代码之前。

**执行步骤：**
1. **重述需求** - 明确需要构建的内容
2. **识别风险** - 发现潜在问题和阻碍
3. **创建步骤计划** - 将实现分解为阶段
4. **等待确认** - 必须收到用户批准才能继续

**输出格式：**

```markdown
# 实现计划：[功能名称]

## 需求重述
- [需求 1]
- [需求 2]

## 实现阶段

### 阶段 1：[阶段名称]
- 具体步骤和文件路径
- 依赖关系
- 风险评估

### 阶段 2：[阶段名称]
...

## 依赖项
- [依赖 1]
- [依赖 2]

## 风险
- 高：[描述]
- 中：[描述]
- 低：[描述]

## 预估复杂度：中等

**等待确认**：继续执行此计划？(yes/no/modify)
```

---

## 规则 (Rules)

规则是始终遵循的准则，位于 `~/.claude/rules/` 目录。

### 规则文件列表

| 文件 | 内容 |
|------|------|
| **security.md** | 安全检查、密钥管理 |
| **coding-style.md** | 不可变性、文件组织、错误处理 |
| **testing.md** | TDD 工作流、80% 覆盖率要求 |
| **git-workflow.md** | 提交格式、PR 工作流 |
| **agents.md** | 代理编排、何时使用哪个代理 |
| **patterns.md** | API 响应、仓库模式 |
| **performance.md** | 模型选择、上下文管理 |
| **hooks.md** | 钩子配置说明 |

### 安全准则 (security.md)

**提交前必须检查：**
- [ ] 无硬编码密钥（API 密钥、密码、令牌）
- [ ] 所有用户输入已验证
- [ ] SQL 注入防护（参数化查询）
- [ ] XSS 防护（清理 HTML）
- [ ] CSRF 保护已启用
- [ ] 认证/授权已验证
- [ ] 所有端点已限流
- [ ] 错误消息不泄露敏感数据

**密钥管理：**

```typescript
// 错误：硬编码密钥
const apiKey = "sk-proj-xxxxx"

// 正确：环境变量
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

**安全响应协议：**

发现安全问题时：
1. 立即停止
2. 使用 **security-reviewer** 代理
3. 先修复关键问题再继续
4. 轮换任何暴露的密钥
5. 审查整个代码库的类似问题

### 测试要求 (testing.md)

**最低测试覆盖率：80%**

测试类型（全部必需）：
1. **单元测试** - 单独的函数、工具、组件
2. **集成测试** - API 端点、数据库操作
3. **E2E 测试** - 关键用户流程（Playwright）

**TDD 强制工作流：**
1. 先写测试（RED）
2. 运行测试 - 应该失败
3. 写最少实现（GREEN）
4. 运行测试 - 应该通过
5. 重构（IMPROVE）
6. 验证覆盖率（80%+）

### 性能优化 (performance.md)

**模型选择策略：**

| 模型 | 能力 | 使用场景 |
|------|------|----------|
| **Haiku 4.5** | Sonnet 90% 能力，3x 成本节省 | 轻量代理、频繁调用、配对编程 |
| **Sonnet 4.5** | 最佳编码模型 | 主要开发工作、编排多代理工作流 |
| **Opus 4.5** | 最深推理 | 复杂架构决策、最大推理需求、研究分析 |

**上下文窗口管理：**

避免在上下文窗口最后 20% 进行：
- 大规模重构
- 跨多文件的功能实现
- 复杂交互调试

低上下文敏感度任务：
- 单文件编辑
- 独立工具创建
- 文档更新
- 简单 Bug 修复

---

## 钩子 (Hooks)

钩子在工具事件上触发，位于 `hooks/hooks.json` 或直接在 `settings.json` 中配置。

### 钩子类型

| 类型 | 触发时机 |
|------|----------|
| **PreToolUse** | 工具执行前 |
| **PostToolUse** | 工具执行后 |
| **PreCompact** | 上下文压缩前 |
| **SessionStart** | 会话开始时 |
| **SessionEnd** | 会话结束时 |
| **Stop** | 每次响应后 |

### 预配置钩子

#### 1. 开发服务器 tmux 提醒
```json
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"(npm run dev|pnpm( run)? dev|yarn dev|bun run dev)\"",
  "hooks": [{
    "type": "command",
    "command": "node -e \"console.error('[Hook] BLOCKED: Dev server must run in tmux for log access');process.exit(1)\""
  }],
  "description": "阻止在 tmux 外运行开发服务器"
}
```

#### 2. 长时间命令 tmux 提醒
```json
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"(npm (install|test)|pnpm (install|test)|yarn|cargo build|make|docker|pytest|vitest|playwright)\"",
  "hooks": [{
    "type": "command",
    "command": "node -e \"if(!process.env.TMUX){console.error('[Hook] Consider running in tmux for session persistence')}\""
  }],
  "description": "提醒使用 tmux 运行长时间命令"
}
```

#### 3. Git Push 提醒
```json
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"git push\"",
  "hooks": [{
    "type": "command",
    "command": "node -e \"console.error('[Hook] Review changes before push...')\""
  }],
  "description": "推送前提醒审查更改"
}
```

#### 4. PR 创建通知
```json
{
  "matcher": "tool == \"Bash\"",
  "hooks": [{
    "type": "command",
    "command": "node -e \"...检测 gh pr create 并输出 PR URL...\""
  }],
  "description": "PR 创建后记录 URL 并提供审查命令"
}
```

#### 5. console.log 警告
```json
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
  "hooks": [{
    "type": "command",
    "command": "node -e \"...检测 console.log 并警告...\""
  }],
  "description": "编辑后警告 console.log 语句"
}
```

#### 6. 策略压缩建议
```json
{
  "matcher": "tool == \"Edit\" || tool == \"Write\"",
  "hooks": [{
    "type": "command",
    "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/suggest-compact.js\""
  }],
  "description": "在逻辑间隔建议手动压缩"
}
```

---

## MCP 配置

MCP（Model Context Protocol）服务器配置位于 `mcp-configs/mcp-servers.json`。

### 可用 MCP 服务器

| 服务器 | 说明 |
|--------|------|
| **github** | GitHub 操作 - PR、Issues、Repos |
| **firecrawl** | 网页抓取和爬取 |
| **supabase** | Supabase 数据库操作 |
| **memory** | 跨会话持久记忆 |
| **sequential-thinking** | 链式思维推理 |
| **vercel** | Vercel 部署和项目 |
| **railway** | Railway 部署 |
| **cloudflare-docs** | Cloudflare 文档搜索 |
| **cloudflare-workers-builds** | Cloudflare Workers 构建 |
| **cloudflare-workers-bindings** | Cloudflare Workers 绑定 |
| **cloudflare-observability** | Cloudflare 可观测性/日志 |
| **clickhouse** | ClickHouse 分析查询 |
| **context7** | 实时文档查找 |
| **magic** | Magic UI 组件 |
| **filesystem** | 文件系统操作 |

### 配置示例

将所需服务器复制到 `~/.claude.json`：

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE"
      }
    },
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest", "--project-ref=YOUR_PROJECT_REF"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

### 重要警告

**上下文窗口管理：**
- 不要同时启用所有 MCP
- 200k 上下文窗口可能因工具过多而缩小到 70k
- 经验法则：
  - 配置 20-30 个 MCP
  - 每个项目启用少于 10 个
  - 活跃工具少于 80 个

使用项目配置中的 `disabledMcpServers` 禁用未使用的服务器。

---

## 上下文管理

### 动态上下文注入

上下文文件位于 `contexts/` 目录，用于根据模式注入不同的系统提示。

#### 开发上下文 (dev.md)
```markdown
模式: 主动开发
焦点: 实现、编码、构建功能

## 行为
- 先写代码，后解释
- 偏好可工作的解决方案而非完美解决方案
- 修改后运行测试
- 保持提交原子化

## 优先级
1. 让它工作
2. 让它正确
3. 让它干净
```

#### 审查上下文 (review.md)
```markdown
模式: 代码审查
焦点: 质量、安全、可维护性
```

#### 研究上下文 (research.md)
```markdown
模式: 研究/探索
焦点: 学习、理解、调查
```

### 记忆持久化

会话生命周期钩子自动保存/加载上下文：

1. **SessionStart** - 加载先前上下文和检测包管理器
2. **PreCompact** - 压缩前保存状态
3. **SessionEnd** - 持久化会话状态

---

## 最佳实践

### 代码组织

- 多个小文件优于少量大文件
- 高内聚、低耦合
- 典型 200-400 行，最大 800 行/文件
- 按功能/领域组织，而非按类型

### 代码风格

- 代码、注释或文档中不使用 emoji
- 始终不可变 - 从不改变对象或数组
- 生产代码中无 console.log
- 使用 try/catch 正确处理错误
- 使用 Zod 或类似工具验证输入

### Git 工作流

- 约定式提交：`feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- 从不直接提交到 main
- PR 需要审查
- 合并前所有测试必须通过

### 测试策略

- TDD：先写测试
- 最低 80% 覆盖率
- 工具函数写单元测试
- API 写集成测试
- 关键流程写 E2E 测试

### 工作流集成

1. 使用 `/plan` 理解需要构建什么
2. 使用 `/tdd` 测试驱动实现
3. 构建错误时使用 `/build-fix`
4. 使用 `/code-review` 审查实现
5. 使用 `/test-coverage` 验证覆盖率

---

## 配置示例

### 项目级 CLAUDE.md 示例

```markdown
# 项目概述

[项目简要描述 - 做什么、技术栈]

## 关键规则

### 1. 代码组织
- 多个小文件优于少量大文件
- 高内聚、低耦合
- 典型 200-400 行，最大 800 行/文件
- 按功能/领域组织

### 2. 代码风格
- 代码、注释或文档中不使用 emoji
- 始终不可变 - 从不改变对象或数组
- 生产代码中无 console.log
- 使用 try/catch 正确处理错误
- 使用 Zod 验证输入

### 3. 测试
- TDD：先写测试
- 最低 80% 覆盖率
- 工具函数写单元测试
- API 写集成测试
- 关键流程写 E2E 测试

### 4. 安全
- 无硬编码密钥
- 敏感数据使用环境变量
- 验证所有用户输入
- 仅使用参数化查询
- 启用 CSRF 保护

## 文件结构

src/
├── app/              # Next.js app router
├── components/       # 可复用 UI 组件
├── hooks/            # 自定义 React hooks
├── lib/              # 工具库
└── types/            # TypeScript 定义

## 关键模式

### API 响应格式

interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
}

## 可用命令

- /tdd - 测试驱动开发工作流
- /plan - 创建实现计划
- /code-review - 代码质量审查
- /build-fix - 修复构建错误

## Git 工作流

- 约定式提交：feat:, fix:, refactor:, docs:, test:
- 从不直接提交到 main
- PR 需要审查
- 合并前所有测试必须通过
```

### 用户级 CLAUDE.md 示例

```markdown
# 用户级 CLAUDE.md

## 核心哲学

你是 Claude Code。我使用专业代理和技能处理复杂任务。

**关键原则：**
1. **代理优先** - 将复杂工作委托给专业代理
2. **并行执行** - 尽可能使用多代理 Task 工具
3. **先规划后执行** - 复杂操作使用 Plan Mode
4. **测试驱动** - 先写测试再实现
5. **安全第一** - 永不妥协安全性

## 模块化规则

详细准则在 ~/.claude/rules/：

| 规则文件 | 内容 |
|----------|------|
| security.md | 安全检查、密钥管理 |
| coding-style.md | 不可变性、文件组织、错误处理 |
| testing.md | TDD 工作流、80% 覆盖率要求 |
| git-workflow.md | 提交格式、PR 工作流 |
| agents.md | 代理编排、何时使用哪个代理 |

## 可用代理

| 代理 | 用途 |
|------|------|
| planner | 功能实现规划 |
| architect | 系统设计和架构 |
| tdd-guide | 测试驱动开发 |
| code-reviewer | 质量/安全代码审查 |
| security-reviewer | 安全漏洞分析 |

## 个人偏好

### 代码风格
- 代码、注释或文档中不使用 emoji
- 偏好不可变性
- 多个小文件优于少量大文件

### Git
- 约定式提交
- 提交前本地测试
- 小型、聚焦的提交

### 测试
- TDD：先写测试
- 最低 80% 覆盖率
- 关键流程需要单元 + 集成 + E2E

## 成功指标

成功标准：
- 所有测试通过（80%+ 覆盖率）
- 无安全漏洞
- 代码可读且可维护
- 满足用户需求
```

---

## 跨平台支持

此插件完全支持 **Windows、macOS 和 Linux**。所有钩子和脚本已用 Node.js 重写以获得最大兼容性。

### 包管理器检测

插件自动检测首选包管理器（npm、pnpm、yarn 或 bun），优先级：

1. **环境变量**：`CLAUDE_PACKAGE_MANAGER`
2. **项目配置**：`.claude/package-manager.json`
3. **package.json**：`packageManager` 字段
4. **锁文件**：检测 package-lock.json、yarn.lock、pnpm-lock.yaml 或 bun.lockb
5. **全局配置**：`~/.claude/package-manager.json`
6. **回退**：第一个可用的包管理器

设置首选包管理器：

```bash
# 通过环境变量
export CLAUDE_PACKAGE_MANAGER=pnpm

# 通过全局配置
node scripts/setup-package-manager.js --global pnpm

# 通过项目配置
node scripts/setup-package-manager.js --project bun

# 检测当前设置
node scripts/setup-package-manager.js --detect
```

或在 Claude Code 中使用 `/setup-pm` 命令。

---

## 运行测试

插件包含完整的测试套件：

```bash
# 运行所有测试
node tests/run-all.js

# 运行单个测试文件
node tests/lib/utils.test.js
node tests/lib/package-manager.test.js
node tests/hooks/hooks.test.js
```

---

## 相关资源

- **简短指南（入门）**：[The Shorthand Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2012378465664745795)
- **详细指南（进阶）**：[The Longform Guide to Everything Claude Code](https://x.com/affaanmustafa/status/2014040193557471352)
- **GitHub 仓库**：[affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **作者 Twitter**：[@affaanmustafa](https://x.com/affaanmustafa)

---

## 许可证

MIT - 自由使用、按需修改、有能力时贡献回馈。

---

*如果这对你有帮助，请给仓库点星。阅读两份指南。构建伟大的东西。*
