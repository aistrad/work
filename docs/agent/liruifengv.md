使用 Claude Agent SDK 快速构建 Agent
发布于：2025年11月11日
·
2222 字
·
11 分钟
claude
agent
ai
最近在学习 AI Agent 开发，本文将使用 Claude Agent SDK 的 TypeScript 版本, 构建一个 AI Agent Demo。

全部代码在我的 GitHub 仓库 liruifengv/claude-agent-demo。

Claude Agent SDK 介绍
Claude Agent SDK 的前身是 Claude Code SDK，是 Claude Code 的底层框架，现在改为通用的 Agent SDK，其中具备了 Claude Code 所拥有的一些基础能力，包括上下文管理，内置丰富的工具，权限控制等，如果你也想构建一个 Agent，使用这个 SDK 能快速搭建起来。更多详情请看 Claude Agent SDK 的文档

环境配置
首先我们需要初始化一个 Node.js 的空项目。

其次是环境变量，需要配置 Claude 的模型的 BASE_URL 和 API_KEY

两种方式：

可以在系统的环境变量里配置：
.zshrc
ANTHROPIC_BASE_URL=ANTHROPIC_BASE_URL
ANTHROPIC_API_KEY=ANTHROPIC_API_KEY

或者在项目的 .env 文件中配置：
.env
ANTHROPIC_BASE_URL=ANTHROPIC_BASE_URL
ANTHROPIC_API_KEY=ANTHROPIC_API_KEY

你可以在以下平台获取 API Key，使用任何 Claude 兼容的 API 皆可。 建议使用国产开源模型的 Coding Plan 进行测试。

MiniMax Coding Plan。
GLM Coding Plan。
aihubmix 中转平台。
然后安装 @anthropic-ai/claude-agent-sdk 这个 npm 包：

npm install
npm install @anthropic-ai/claude-agent-sdk

基础用法
首先是 query 函数，他是跟 Agent 交互的主要函数，用于向 Agent 发送请求。

我们来看下用法：

src/core/basic-example.ts
import { query, Query } from "@anthropic-ai/claude-agent-sdk";

export async function basicExample() {
    // query 函数接受一个 prompt 参数
    const result: Query = query({prompt: "你好"})

    // 这里使用 for await of 循环 result
    for await (const message of result){
      // message.type 有几种：'assistant', 'user', 'system', 'result' 等
      // 根据不同的消息类型做业务逻辑
      switch (message.type){
        case 'assistant':
          // message.message.content 是一个数组，我们循环所有的 msg
          for (const msg of message.message.content) {
            // 打印 text 类型的输出
            if (msg.type === "text") {
              console.log(msg.text)
            }
          }
      }
    }
  }

在 index.ts 中调用 basicExample 函数：

src/index.ts
import { basicExample } from "./core/basic-example";

async function main() {
  console.log('Starting Claude Agent Demo...');
  await basicExample();
}

main();

执行 tsx src/index.ts

可以在终端看到

> claude-agent-demo@1.0.0 dev
> tsx src/index.ts

Starting Claude Agent Demo...
你好！很高兴见到你！我是 Claude，一个 AI 助手。我可以帮助你：

- 编写和调试代码
- 搜索和分析代码库
- 执行命令和运行脚本
- 管理文件和项目
- 回答技术问题

有什么我可以帮助你的吗？

Session 会话管理
Claude Agent SDK 自带了会话管理功能，当新建一个 query 时，它会返回一个 session ID，你可以使用这个 ID 来保存和恢复会话。例如，你可以将 session ID 存储在数据库中，以便在用户下次登录时恢复会话。

src/core/session-example.ts
import {query, Query} from "@anthropic-ai/claude-agent-sdk";

export async function sessionExample() {
    let sessionId: string | undefined

    const result: Query = query({
      prompt: "你好",
      options: {
        // options 的 resume 参数传入记录的 sessionId，就可以继续对话了
          resume: sessionId
      }
  })

  for await (const message of result) {
    switch (message.type) {
      // message.type === 'assistant' && message.subtype === 'init' 的时候
      // 会返回一个 session_id，需要把这个 session_id 存下来
      case 'system':
        if (message.subtype === 'init') {
          sessionId = message.session_id
          console.log(`Current Session ID: ${sessionId}`)
        }
        break
      case 'assistant':
        for (const msg of message.message.content) {
          if (msg.type === "text") {
            console.log(`Assistant: ${msg.text}`)
          }
        }
        break
    }
  }
}

实现连续对话
接下来我们会在终端使用 node 做一下简单的交互，使得用户可输入内容，然后使用 session ID 实现连续对话。

创建一个 tui-chat.ts:

src/core/tui-chat.ts
export async function tuiChat() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        prompt: 'User: '
    })

    rl.prompt()

    rl.on('line', async (input: string) => {
        const userInput = input.trim()
        console.log(`User: ${userInput}`)
        rl.prompt()
    })


    rl.on('close', () => {
        console.log("exit the chat")
        process.exit(0);
    });

}

以上代码就能实现用户在终端连续输入内容。 接着写 AI 对话的代码：

src/core/tui-chat.ts
// 这个函数接收两个参数，一个 prompt 用户输入，一个当前会话 id
export async function chatExample(prompt: string, sessionId: string | undefined) {

  // 函数内部定义会话 id
  let _sessionId: string | undefined

  const result: Query = query({
    prompt: prompt,
    options: {
      // options 的 resume 参数传入记录的 sessionId，就可以继续对话了
      resume: sessionId
    }
  })
  for await (const message of result) {
    switch (message.type) {
      case 'system':
        if (message.subtype === 'init') {
          // 系统初始化时记录会话ID
          _sessionId = message.session_id
        }
        break
      case 'assistant':
        for (const msg of message.message.content) {
          if (msg.type === "text") {
            console.log(`Assistant: ${msg.text}`)
          }
        }
        break
    }
  }

  // 把当前会话 id 返回给调用者
  return _sessionId
}

然后调用这个 chatExample 就行：

src/core/tui-chat.ts
export async function tuiChat() {
  // 记录 sessionId
  let sessionId: string | undefined

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    prompt: 'User: '
  })

  rl.prompt()

  rl.on('line', async (input: string) => {
    const userInput = input.trim()
    // 赋值返回的 sessionId
    sessionId = await chatExample(userInput, sessionId)

    rl.prompt()
  })


  rl.on('close', () => {
    console.log("exit the chat")
    process.exit(0);
  });
}

好的，现在我们来执行一下看看效果：

Starting Claude Agent Demo...
User: hello
Assistant: Hello! 👋 How can I help you today? I'm Claude, and I can assist you with a variety of tasks like:

- Writing, editing, or reviewing code
- Searching through codebases and files
- Running commands and tests
- Creating pull requests and managing git operations
- Answering questions about your project
- And much more!

What would you like to work on?
User: 你是谁
Assistant: 你好！我是 Claude，由 Anthropic 开发的 AI 助手。

在这个环境中，我是 Claude Code - 一个专门用于编程和开发任务的版本。我可以帮助你：

- 编写、编辑和审查代码
- 搜索和分析代码库
- 运行命令和测试
- 管理 Git 操作和创建 Pull Request
- 回答关于项目的问题
- 还有更多其他功能！

有什么我可以帮助你的吗？
User: 我跟你说的上一句话是什么
Assistant: 你上一句话是"你是谁"。

完美，我们可以在终端和 Agent 连续对话了，它能记住我们上一句话，说明当前会话是有效的。

工具调用
接下来我们会自定义一个用于数学计算的工具，和一个 MCP Server。

先安装 mathjs 和 zod

npm install mathjs
npm install zod@3.25.76

Claude Agent SDK 内部使用的 zod 还是 3.25 版本，而最新版已经是 4.1.12，会有兼容问题，所以我们安装了指定版本。

mathjs 是一个数学计算的库，他有一个 evaluate 方法，可以执行字符串表达式，例如：

import math from 'mathjs';

math.evaluate('1.2 * (2 + 4.5)')

创建一个 tools/calc-tool.ts：

src/tools/calc-tool.ts
import { tool } from "@anthropic-ai/claude-agent-sdk";

import { z } from "zod"
import { calculator } from "../utils/calculator";

// 使用 tool 函数创建一个工具
// 前两个参数是工具名称和描述
export const calcTool = tool(
  "calculator",
  "Perform a calculation using an expression string. The strings used here are executed using mathjs evaluate function. eg  " + "1.2 * (2 + 4.5)",
  // 第三个参数是 inputSchema，使用 zod 来定义
  {
    expression: z.string().describe("The expression to be evaluated")
  },
  async (args) =>{
    // 回调函数里执行工具的具体业务逻辑
    const result = calculator(args.expression)

    // 返回这个结构即可
    return {
      content: [
        {
          type: "text",
          text: result
        }
      ]
    }
  }
)

创建一个 utils/calculator.ts：

src/utils/calculator.ts
import * as math from 'mathjs'

export function calculator(expression:string) : string{
  const result = math.evaluate(expression)
  return result.toString()
}

工具定义完毕，Claude Agent SDK 要求我们必须定义一个 MCP Server 来使用工具。

我们创建一个 mcps/mcp-example-server.ts 文件：

src/mcps/mcp-example-server.ts
import { createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { calcTool } from "../tools/calc-tool";

// createSdkMcpServer 是定义 MCP Server 的函数
export const utilitiesServer = createSdkMcpServer({
  name: "utilities",
  version: "1.0.0",
  tools: [calcTool],
})

好的，MCP Server 创建完毕。

接我们回到 chatExample 函数：

src/core/tui-chat-with-tools.ts
import { utilitiesServer } from "../mcps/mcp-example-server";

export async function chatExample(prompt: string, sessionId: string | undefined) {
  let _sessionId: string | undefined

  const result: Query = query({
    prompt: prompt,
    options: {
      resume: sessionId,
      // systemPrompt 可以自定义系统提示词
      systemPrompt: "You are a helpful assistant that can use tools to get information. You can use the following tools: calculator",
      // mcpServers 是一个对象参数，传入自定义的 MCP utilitiesServer
      mcpServers: {
        utilities: utilitiesServer
      },
      // 必须在 allowedTools 里指定的工具才能使用
      // 工具的命名格式是固定的：mcp__{server_name}__{tool_name}
      // 这里就是 mcp__utilities__calculator
      allowedTools: [
        "mcp__utilities__calculator",
      ]
    }
  })
  for await (const message of result) {
    switch (message.type) {
      case 'system':
        if (message.subtype === 'init') {
          _sessionId = message.session_id
        }
        break
      case 'assistant':
        for (const msg of message.message.content) {
          if (msg.type === "text") {
            console.log(`Assistant: ${msg.text}`)
          }
          // 打印 tool_use 类型的的消息
          else if (msg.type === "tool_use") {
            process.stdout.write(`Using tool:  ${msg.name} `)
            if (msg.input) {
                // tool 得到的表达式
                process.stdout.write(` - Input: ${msg.input.expression} `)
            }

            process.stdout.write('\n')
          }
        }
        break
      case 'user':
        for (const msg of message.message.content) {
          // 打印 tool_result 类型的消息
          if (msg.type === "tool_result") {
            process.stdout.write("Tool Results: ")
            for (const result of msg.content) {
              if (result.type === "text") {
                process.stdout.write(result.text)
                process.stdout.write(" - ")
              }
            }
            process.stdout.write('\n')
          }
        }
        break
    }
  }

  return _sessionId
}

我们运行看看效果：

Starting Claude Agent Demo...
User: 你好
Assistant: 你好！很高兴见到你。我是 Claude，一个 AI 助手。我可以帮你进行计算、回答问题、解决问题等。有什么我可以帮助你的吗？
User: 2454+23546，再平方，再除以 32，等于多少？
Assistant: 我来帮你计算这个问题。
Using tool:  mcp__utilities__calculator  - Input: (2454 + 23546)^2 / 32
Tool Results: 21125000 -
Assistant: 计算结果是：**21,125,000**

让我展示一下计算步骤：
1. 首先：2454 + 23546 = 26000
2. 然后平方：26000² = 676,000,000
3. 最后除以 32：676,000,000 ÷ 32 = 21,125,000

我们提问了一个数学问题，它把他解析为工具需要的表达式，然后使用了工具，得到了正确结果，完美！

结尾
使用 Claude Agent SDK，我们用很少的代码就写了一个简单的 Agent，这个 SDK 应该是学习 Agent 开发起手比较简单的工具了，当然还有很多优秀的 Agent 框架，比如 Vercel AI SDK, Mastra, 等等，后续也会学习使用。

Claude Agent SDK 最简玩法：几行代码配合 Markdown 轻松搭建 Agent
发布于：2026年1月6日
·
1042 字
·
5 分钟
claude
agent
ai
本文将带大家了解 Claude Agent SDK 的最简玩法，只需要几行代码，加上几个 Markdown 文件，就能迅速搭建出一个 Agent。

全部代码在我的 GitHub 仓库 liruifengv/claude-agent-demo。

上节回顾
在上一篇文章中，我们 使用 Claude Agent SDK 实现了一个 DeepResearch Agent，它实现了一个多 Agent 协作系统，分为

负责分解研究任务，调度其他 Agent 的 Lead Agent
负责搜索网络、收集资料的 Researcher
负责将研究结果整理成报告 Report Writer
之前是基于代码实现的 SubAgents，现在我们使用 Markdown 文件来实现 Subagents。

Markdown 实现
首先在项目的根目录创建 .claude 文件夹。

创建 CLAUDE.md 文件，这个文件就是主 Agent 的系统提示词，和 Claude Code 的用法一样。

.claude/CLAUDE.md
You are a lead research coordinator who orchestrates comprehensive multi-agent research projects.

**CRITICAL RULES:**
1. You MUST delegate ALL research and report writing to specialized subagents. You NEVER research or write reports yourself.
2. Keep ALL responses SHORT - maximum 2-3 sentences. NO greetings, NO emojis, NO explanations unless asked.
3. Get straight to work immediately - analyze and spawn subagents right away.

<role_definition>
- Break user research requests into 2-4 distinct research subtopics
- Spawn multiple researcher subagents in parallel to investigate each subtopic
- Coordinate the research process and ensure comprehensive coverage
- After ALL research is complete, spawn a report-writer subagent to synthesize findings
- Your ONLY tool is Task - you delegate everything to subagents
</role_definition>

// 更多请查看代码仓库...

然后创建 agents 文件夹，这个文件夹是放 SubAgents 的提示词的。

创建一个 researcher.md 文件，这个文件就是 Researcher 的系统提示词。

.claude/agents/researcher.md
---
name: researcher
description: Use this agent when you need to gather research information on any topic. The researcher uses web search to find relevant information, articles, and sources from across the internet. Writes research findings to files/research_notes/ for later use by report writers. Ideal for complex research tasks that require deep searching and cross-referencing.
tools: WebSearch, Write
---
You are a research specialist focused on information gathering. You always follow this system prompt COMPLETELY. This is critically important.

**CRITICAL: You MUST use WebSearch for ALL research. You MUST save CONCISE research summaries to files/research_notes/ folder.**

// 更多请查看代码仓库...

注意这个文件上方有三个横杠围起来的内容，叫做 frontmatter，里面是一些字段：

name: SubAgent 的名称
description: SubAgent 的描述，告诉 Lead Agent 什么时候应该调用这个 subagent
tools: SubAgent 可以使用的工具。
model: SubAgent 使用的模型。
Claude Agent SDK 在启动时会去读取 .claude 文件夹，加载系统提示词和 SubAgents。

同理，我们再创建一个 report-writer.md 文件，这个文件就是 Report Writer 的系统提示词。

.claude/agents/report-writer.md
---
name: report-writer
description: Use this agent when you need to create a formal research report document. The report-writer reads research findings from files/research_notes/ and synthesizes them into clear, concise, professionally formatted reports in files/reports/. Ideal for creating structured documents with proper citations and organization. Does NOT conduct web searches - only reads existing research notes and creates reports.
tools: Read, Write, Glob, Skill
---
You are a professional report writer who creates clear, concise research summaries on any topic.

**CRITICAL: You MUST read research notes from files/research_notes/ folder.**

// 更多请查看代码仓库...

OK，有了这个三个 Markdown 文件，我们的 Agent 的核心就已经建立起来了。

接下来写一点代码：

agent.ts
import { query, type Query } from "@anthropic-ai/claude-agent-sdk";

const result: Query = query({
  prompt: userInput,
  options: {
    resume: sessionId,
    settingSources: ["project"],
    permissionMode: "bypassPermissions",
    allowedTools: ["Task"],
    hooks: customHooks,
  },
});

这里使用了 query 函数来调用 Agent，一些参数我们在之前的文章中讲过了。我们把 settingSources 设置为 ["project"]，这样 Agent 就会从项目配置中读取设置。 allowedTools 我们只给主 Agent 一个 Task 工具安排任务。

这就是核心代码了!

其余的可以在根据需求，增加用户交互、自定义钩子函数、日志输出等。

总结
就这么简单，三个 Markdown 文件，配合几行代码，就能实现一个非常强的 DeepResearch Agent。这就是 Claude Agent SDK 的强大。 你不需要关心细节，什么 Agent Loop、工具调用、权限管理、SubAgents，这些都由 SDK 内部处理好了。

使用 Claude Agent SDK 写一个 DeepResearch Agent
发布于：2025年12月11日
·
1622 字
·
8 分钟
claude
agent
ai
本文将使用 Claude Agent TS SDK 写一个 DeepResearch Agent，这是来自于 Claude 官方示例仓库（Python 版） 的 TS 版本实现。

完整代码在我的 GitHub 仓库 liruifengv/claude-agent-demo。

什么是 DeepResearch Agent？
DeepResearch Agent 是一个 多 Agent 协作系统，它能够像真正的研究团队一样工作：

Lead Agent（协调者）：负责分解研究任务，调度其他 Agent
Researcher（研究员）：负责搜索网络、收集资料
Report Writer（报告编写）：负责将研究结果整理成报告
使用 Subagents 的好处
子代理与主代理保持独立的上下文，防止信息过载并保持交互的专注。这种隔离确保了专门的任务不会将无关的细节污染到主对话上下文中。
多个子代理可以同时运行，显著加快复杂工作流程。
每个子代理都可以拥有定制化的系统提示词，包括特定领域的专业知识、最佳实践和限制。
子代理可以被限制在特定的工具上，以降低意外行为的风险。
使用 Claude Agent TS SDK，实现 Subagents 特别简单。

架构图
┌─────────────────────────────────────────────────────────────┐
│                      Lead Agent (协调者)                      │
│                   只有 Task 工具，负责调度                      │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
          ┌───────────▼───────┐   ┌───────▼───────────┐
          │   Researcher ×N   │   │   Report-Writer   │
          │  WebSearch, Write │   │ Glob, Read, Write │
          └───────────────────┘   └───────────────────┘

核心实现
1. 定义 Subagent
在 agent.ts 中，我们定义了两个专业化的 subagent：

// 定义专业化的 subagent
const agents = {
  researcher: {
    description:
      "Use this agent when you need to gather research information on any topic. " +
      "The researcher uses web search to find relevant information, articles, and sources " +
      "from across the internet. Writes research findings to files/research_notes/ " +
      "for later use by report writers.",
    tools: ["WebSearch", "Write"],  // 可以搜索网络和写入文件
    prompt: researcherPrompt,        // 研究员的系统提示词
    model: "haiku" as const,
  },
  "report-writer": {
    description:
      "Use this agent when you need to create a formal research report document. " +
      "The report-writer reads research findings from files/research_notes/ and synthesizes " +
      "them into clear, concise, professionally formatted reports in files/reports/.",
    tools: ["Skill", "Write", "Glob", "Read"], // 可以查找、读取和写入文件
    prompt: reportWriterPrompt,     // 报告撰写系统提示词
    model: "haiku" as const,
  },
};

关键点解释：

description：告诉 Lead Agent 什么时候应该调用这个 subagent
tools：该 subagent 可以使用的工具
prompt：该 subagent 的系统提示词，定义它的行为
model：使用的模型
2. Lead Agent 的提示词
prompts/lead-agent.ts 中定义了协调者的行为：

export const leadAgentPrompt = `You are a lead research coordinator who orchestrates comprehensive multi-agent research projects.

**CRITICAL RULES:**
1. You MUST delegate ALL research and report writing to specialized subagents. You NEVER research or write reports yourself.
2. Keep ALL responses SHORT - maximum 2-3 sentences.
3. Get straight to work immediately - analyze and spawn subagents right away.

<workflow>
**STEP 1: ANALYZE USER REQUEST**
- Understand the research topic and scope
- Identify 2-4 distinct subtopics or angles to investigate

**STEP 2: SPAWN RESEARCHER SUBAGENTS (IN PARALLEL)**
- Use Task tool to spawn 2-4 researcher subagents simultaneously
- Give EACH researcher a specific, focused subtopic to investigate

**STEP 3: WAIT FOR RESEARCH COMPLETION**
- All researchers will complete their work and save findings
- Do NOT proceed until all researchers have finished

**STEP 4: SPAWN REPORT-WRITER SUBAGENT**
- Use Task tool to spawn ONE report-writer subagent
- Instruct it to read ALL research notes and create a synthesis report
</workflow>

<task_tool_usage>
For researchers:
- subagent_type: "researcher"
- description: Brief description of the subtopic
- prompt: Detailed instructions on what to research

For report-writer:
- subagent_type: "report-writer"
- description: "Synthesize research into final report"
- prompt: "Read all research notes from files/research_notes/ and create a report in files/reports/"
</task_tool_usage>

// 更多请查看代码仓库...
`;

3. 研究员的提示词
prompts/researcher.ts 定义了研究员如何工作：

export const researcherPrompt = `You are a research specialist focused on information gathering.

**CRITICAL: You MUST use WebSearch for ALL research. You MUST save research summaries to files/research_notes/ folder.**

<workflow>
1. IMMEDIATELY use WebSearch with well-crafted queries
2. Use WebSearch multiple times (3-7 searches) with different angles
3. Extract key findings from WebSearch results
4. SAVE findings to files/research_notes/{topic_name}.md using Write tool
5. Return brief confirmation that research was saved

CRITICAL: NEVER rely on your own knowledge - ONLY use WebSearch results.
</workflow>
// 更多请查看代码仓库...
`;

4. 报告编写的提示词
prompts/report-writer.ts：

export const reportWriterPrompt = `You are a professional report writer who creates clear, concise research summaries.

**CRITICAL: You MUST read research notes from files/research_notes/ folder.**

<workflow>
1. Use Glob to find all research notes in files/research_notes/
2. Use Read to load each research note file
3. Synthesize all research notes into a cohesive report
4. Save to files/reports/ folder as .txt file
</workflow>

<requirements>
- One-page length (500-800 words)
- Every claim must have a citation
- Clear, professional language
</requirements>
// 更多请查看代码仓库...
`;

5. 启动 Agent
在 agent.ts 的 chat() 函数中，把所有部分组合起来：

import { query, type Query, type SDKAssistantMessage } from "@anthropic-ai/claude-agent-sdk";

export async function chat(): Promise<void> {
  // ... 省略初始化代码

  // 用于会话连续性的 Session ID
  let sessionId: string | undefined;

  while (true) {
    const userInput = await askQuestion();
    if (!userInput) break;

    // 发送给 agent
    const result: Query = query({
      prompt: userInput,
      options: {
        resume: sessionId,                    // 恢复会话
        permissionMode: "bypassPermissions",  // 跳过权限确认
        systemPrompt: leadAgentPrompt,        // Lead Agent 的提示词
        allowedTools: ["Task"],               // Lead Agent 只能用 Task 调度 subagent
        agents,                               // 注册的 subagent 定义
        model: "haiku",
      },
    });

    // 流式处理响应
    for await (const msg of result) {
      switch (msg.type) {
        case "system":
          if (msg.subtype === "init") {
            sessionId = msg.session_id;  // 保存 session ID
          }
          break;
        case "assistant":
          processAssistantMessage(msg, tracker, transcript);
          break;
      }
    }
  }
}

6. 处理 Assistant 消息
function processAssistantMessage(
  msg: SDKAssistantMessage,
  tracker: SubagentTracker,
  transcript: TranscriptWriter
): void {
  // 使用消息中的 parent_tool_use_id 更新 tracker 上下文
  const parentId = msg.parent_tool_use_id;
  tracker.setCurrentContext(parentId ?? undefined);

  for (const block of msg.message.content) {
    if (block.type === "text" && block.text) {
      // 输出文本内容
      transcript.write(block.text, "");
    } else if (block.type === "tool_use" && block.name === "Task") {
      // 检测到生成 subagent
      const input = block.input || {};
      const subagentType = String(input.subagent_type || "unknown");
      const description = String(input.description || "no description");
      const prompt = String(input.prompt || "");

      // 注册 subagent
      const subagentId = tracker.registerSubagentSpawn(
        block.id || "",
        subagentType,
        description,
        prompt
      );

      // 面向用户的输出
      transcript.write(`\n\n[🚀 Spawning ${subagentId}: ${description}]\n`, "");
    }
  }
}

运行效果
当你输入”Research quantum computing developments”时，系统会：

Agent: Breaking this into 4 research areas: hardware/qubits, algorithms/applications,
industry players/investments, and challenges/timeline. Spawning researchers.

============================================================
🚀 SUBAGENT SPAWNED: RESEARCHER-1
============================================================
Task: Quantum hardware and qubit technology
============================================================

[🚀 Spawning RESEARCHER-1: Quantum hardware and qubit technology]

============================================================
🚀 SUBAGENT SPAWNED: RESEARCHER-2
============================================================
Task: Quantum algorithms and applications
============================================================

[RESEARCHER-1] → WebSearch
[RESEARCHER-2] → WebSearch
[RESEARCHER-1] → Write
[RESEARCHER-2] → Write

============================================================
🚀 SUBAGENT SPAWNED: REPORT-WRITER-1
============================================================
Task: Synthesize research into final report
============================================================

[REPORT-WRITER-1] → Glob
[REPORT-WRITER-1] → Read
[REPORT-WRITER-1] → Write

Agent: Research complete. Report saved to files/reports/quantum_computing_summary.txt

关键概念总结
概念	说明
agents	定义可用的 subagent，包括 description、tools、prompt、model
allowedTools: ["Task"]	Lead Agent 只能用 Task 工具来调度 subagent
Task 工具	SDK 内置工具，用于生成 subagent
parent_tool_use_id	用于追踪哪个 subagent 在执行
resume: sessionId	保持会话连续性，支持多轮对话
运行项目
# 设置 API Key
export ANTHROPIC_API_KEY=your_key

# 运行
npx tsx src/research-agent/agent.ts

这就是使用 Claude Agent SDK 构建 DeepResearch Agent 的核心实现——通过定义专业化的 subagent，让 AI 像一个研究团队一样协作完成复杂的研究任务。