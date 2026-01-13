---
name: vibe-agent
description: Agent 设计专家。帮助构建智能体系统，包括 Agentic Loop、Tool Use、Subagents、Hooks。触发词：agent, 智能体, 构建agent, tool use, subagent
---

# Vibe Agent - Agent 设计专家

帮助你快速构建高质量的 AI Agent 系统。

## 核心原则

### 1. Agentic Loop

```
用户消息 → LLM 思考 → 工具调用 → 环境反馈 → LLM 继续思考 → ...
                ↑                              │
                └──────────────────────────────┘
```

**关键点**：
- 每步从环境获取 "ground truth"（工具调用结果）
- LLM 根据反馈动态调整下一步行动
- **不要用代码硬编码决策逻辑，让 LLM 自己判断**

### 2. Tool Use 最佳实践 (ACI)

站在模型角度设计工具：

```python
# 好的工具定义
{
    "name": "search_codebase",
    "description": "Search for code patterns. Example: 'async function.*fetch' finds async fetch functions. Use when looking for specific code patterns or implementations.",
    "input_schema": {
        "type": "object",
        "properties": {
            "pattern": {
                "type": "string",
                "description": "Regex pattern. Example: 'class.*Error' finds error classes"
            },
            "file_type": {
                "type": "string",
                "description": "File extension filter. Example: 'ts', 'py'"
            }
        },
        "required": ["pattern"]
    }
}
```

**原则**：
- 包含示例用法和边界情况
- 参数命名清晰，像给初级开发者写 docstring
- 防错设计：强制绝对路径而非相对路径

### 工具调用规则设计（关键！）

**关键洞察**：工具定义 ≠ 工具调用。即使工具被正确加载，如果 system prompt 中没有明确指导，LLM 可能会选择直接用文字回答而不调用工具。

**解决方案**：在 SKILL.md 中添加明确的工具调用规则表：

```markdown
## 工具调用规则（必须遵守）

**重要：你必须通过调用工具来展示结果，而不是直接用文字描述。**

| 用户意图 | 必须调用的工具 |
|---------|--------------|
| 查看命盘 | `show_bazi_chart` |
| 问运势 | `show_bazi_fortune` |
| 缺少信息 | `request_info` |

**示例**：
- 用户问"2026年运势" → 必须调用 `show_bazi_fortune(year=2026)`
- 用户问"看看我的命盘" → 必须调用 `show_bazi_chart`
```

**为什么有效**：
1. 明确的映射表让 LLM 知道"什么时候必须调用工具"
2. 具体示例帮助 LLM 理解调用方式
3. "必须遵守"的强调语气提高遵从率

### 3. Subagents 设计

```typescript
const agents = {
  "code-reviewer": {
    description: "代码审查专家。分析代码质量、安全漏洞、性能问题。",
    tools: ["Read", "Glob", "Grep"],
    prompt: "你是代码审查专家，专注于...",
    model: "haiku"  // 简单任务用快速模型
  },
  "researcher": {
    description: "研究员。搜索网络收集资料，写入 files/research_notes/",
    tools: ["WebSearch", "Write"],
    prompt: "你是研究专家，必须使用 WebSearch...",
    model: "sonnet"
  }
}
```

**使用场景**：
- 任务可分解为独立子任务
- 需要不同专业能力
- 需要并行执行提高效率

### 4. Hooks 机制

```typescript
// PreToolUse: 工具执行前拦截
async function validateBashCommand(input, toolUseId, context) {
  if (input.command?.includes('rm -rf /')) {
    return {
      hookSpecificOutput: {
        permissionDecision: 'deny',
        permissionDecisionReason: '危险命令已阻止'
      }
    };
  }
  return {};
}

options: {
  hooks: {
    PreToolUse: [{ matcher: 'Bash', hooks: [validateBashCommand] }]
  }
}
```

**Hook 类型**：
- `PreToolUse`: 工具执行前
- `PostToolUse`: 工具执行后
- `UserPromptSubmit`: 用户提交时
- `Stop`: 停止执行时

## Claude Agent SDK 快速上手

### 基础用法

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Review the code in ./src",
  options: {
    model: "opus",
    allowedTools: ["Read", "Glob", "Grep"],
    permissionMode: "bypassPermissions",
    maxTurns: 250
  }
})) {
  if (message.type === "assistant") {
    for (const block of message.message.content) {
      if ("text" in block) console.log(block.text);
    }
  }
}
```

### 结构化输出

```typescript
const reviewSchema = {
  type: "object",
  properties: {
    issues: {
      type: "array",
      items: {
        type: "object",
        properties: {
          severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
          file: { type: "string" },
          description: { type: "string" }
        }
      }
    },
    summary: { type: "string" }
  }
};

query({
  prompt: "Review code",
  options: {
    outputFormat: { type: "json_schema", schema: reviewSchema }
  }
})
```

### 自定义工具

```typescript
import { tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";

const calcTool = tool(
  "calculator",
  "数学计算。示例: '1.2 * (2 + 4.5)'",
  { expression: z.string().describe("数学表达式") },
  async (args) => ({
    content: [{ type: "text", text: evaluate(args.expression) }]
  })
);

const server = createSdkMcpServer({
  name: "utilities",
  tools: [calcTool]
});

// 使用: allowedTools: ["mcp__utilities__calculator"]
```

### Markdown 方式定义 Subagent

```
.claude/
├── CLAUDE.md              # 主 Agent 系统提示词
└── agents/
    ├── researcher.md      # Subagent 定义
    └── report-writer.md
```

```markdown
<!-- .claude/agents/researcher.md -->
---
name: researcher
description: 研究员，使用 WebSearch 收集资料
tools: WebSearch, Write
model: haiku
---
你是研究专家。必须使用 WebSearch 搜索，结果保存到 files/research_notes/
```

## 实战案例

### 案例 1: DeepResearch Agent (多 Agent 协作)

**架构**：
```
┌─────────────────────────────────────────────────────────────┐
│                   Lead Agent (协调者)                        │
│                只有 Task 工具，负责调度                       │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
          ┌───────────▼───────┐   ┌───────▼───────────┐
          │   Researcher ×N   │   │   Report-Writer   │
          │  WebSearch, Write │   │ Glob, Read, Write │
          └───────────────────┘   └───────────────────┘
```

**Lead Agent 提示词**：
```markdown
You are a lead research coordinator.

**CRITICAL RULES:**
1. MUST delegate ALL research to subagents. NEVER research yourself.
2. Keep responses SHORT - max 2-3 sentences.

<workflow>
1. Analyze request → identify 2-4 subtopics
2. Spawn researcher subagents IN PARALLEL
3. Wait for all researchers to complete
4. Spawn ONE report-writer to synthesize
</workflow>
```

**Researcher 提示词**：
```markdown
---
name: researcher
description: 研究员，搜索网络收集资料
tools: WebSearch, Write
---
You are a research specialist.

**CRITICAL: MUST use WebSearch. Save to files/research_notes/**

<workflow>
1. Use WebSearch 3-7 times with different angles
2. Extract key findings
3. Save to files/research_notes/{topic}.md
</workflow>
```

**代码实现**：
```typescript
const result = query({
  prompt: userInput,
  options: {
    systemPrompt: leadAgentPrompt,
    allowedTools: ["Task"],  // Lead 只能调度
    agents: {
      researcher: {
        description: "研究员，搜索网络收集资料",
        tools: ["WebSearch", "Write"],
        prompt: researcherPrompt,
        model: "haiku"
      },
      "report-writer": {
        description: "报告撰写，整理研究结果",
        tools: ["Glob", "Read", "Write"],
        prompt: reportWriterPrompt,
        model: "haiku"
      }
    }
  }
});
```

### 案例 2: Code Review Agent

**功能**：分析代码库，找出 bug、安全漏洞、性能问题

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function reviewCode(directory: string) {
  for await (const message of query({
    prompt: `Review code in ${directory} for:
1. Bugs and potential crashes
2. Security vulnerabilities
3. Performance issues
4. Code quality improvements

Be specific about file names and line numbers.`,
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep"],
      permissionMode: "bypassPermissions",
      maxTurns: 250
    }
  })) {
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("text" in block) console.log(block.text);
        if ("name" in block) console.log(`📁 Using ${block.name}...`);
      }
    }
  }
}
```

**结构化输出版本**：
```typescript
const reviewSchema = {
  type: "object",
  properties: {
    issues: {
      type: "array",
      items: {
        type: "object",
        properties: {
          severity: { enum: ["low", "medium", "high", "critical"] },
          category: { enum: ["bug", "security", "performance", "style"] },
          file: { type: "string" },
          line: { type: "number" },
          description: { type: "string" },
          suggestion: { type: "string" }
        }
      }
    },
    summary: { type: "string" },
    overallScore: { type: "number" }
  }
};

query({
  prompt: `Review code in ${directory}`,
  options: {
    outputFormat: { type: "json_schema", schema: reviewSchema }
  }
});
```

### 案例 3: Email Agent

**功能**：IMAP 邮件助手，显示收件箱、搜索邮件

```typescript
// 自定义 IMAP 工具
const imapTools = {
  list_inbox: tool(
    "list_inbox",
    "列出收件箱邮件。参数: limit (默认10)",
    { limit: z.number().optional() },
    async ({ limit = 10 }) => {
      const emails = await imap.listInbox(limit);
      return { content: [{ type: "text", text: JSON.stringify(emails) }] };
    }
  ),
  search_emails: tool(
    "search_emails",
    "搜索邮件。示例: 'from:boss subject:urgent'",
    { query: z.string() },
    async ({ query }) => {
      const results = await imap.search(query);
      return { content: [{ type: "text", text: JSON.stringify(results) }] };
    }
  )
};

const emailServer = createSdkMcpServer({
  name: "email",
  tools: Object.values(imapTools)
});

query({
  prompt: "Show my unread emails from today",
  options: {
    mcpServers: { email: emailServer },
    allowedTools: ["mcp__email__list_inbox", "mcp__email__search_emails"]
  }
});
```

### 案例 4: 带 Hooks 的安全 Agent

**功能**：执行任务时自动拦截危险操作

```typescript
const securityHooks = {
  PreToolUse: [
    {
      matcher: "Bash",
      hooks: [async (input) => {
        const dangerous = ["rm -rf", "sudo", "> /dev/", "mkfs"];
        const cmd = input.command || "";
        for (const d of dangerous) {
          if (cmd.includes(d)) {
            return {
              hookSpecificOutput: {
                permissionDecision: "deny",
                permissionDecisionReason: `危险命令: ${d}`
              }
            };
          }
        }
        return {};
      }]
    },
    {
      matcher: "Write",
      hooks: [async (input) => {
        const protected = [".env", "credentials", "secrets"];
        const path = input.file_path || "";
        for (const p of protected) {
          if (path.includes(p)) {
            return {
              hookSpecificOutput: {
                permissionDecision: "deny",
                permissionDecisionReason: `受保护文件: ${p}`
              }
            };
          }
        }
        return {};
      }]
    }
  ]
};

query({
  prompt: "Clean up the project",
  options: {
    hooks: securityHooks,
    allowedTools: ["Bash", "Write", "Read", "Glob"]
  }
});
```

## 参考资源

- [Claude Agent SDK Demos](https://github.com/anthropics/claude-agent-sdk-demos) - 官方示例
- [liruifengv/claude-agent-demo](https://github.com/liruifengv/claude-agent-demo) - 中文教程
- [Anthropic Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Claude Agent SDK Docs](https://platform.claude.com/docs/en/agent-sdk/overview)

## 设计检查清单

- [ ] 是否让 LLM 自己决策，而非硬编码逻辑？
- [ ] 工具定义是否包含示例和边界情况？
- [ ] **是否在 SKILL.md 中添加了明确的工具调用规则表？**
- [ ] **是否为每个工具提供了调用示例？**
- [ ] 是否需要 Subagents 分解任务？
- [ ] 是否需要 Hooks 做权限控制？
- [ ] 是否选择了合适的模型（haiku/sonnet/opus）？
- [ ] 是否需要结构化输出（JSON Schema）？
- [ ] 是否需要 Session 管理实现多轮对话？
