Pinned
nader dabit

@dabit3
The Complete Guide to Building Agents with the Claude Agent SDK
If you've used Claude Code, you've seen what an AI agent can actually do: read files, run commands, edit code, figure out the steps to accomplish a task. 
And you know it doesn't just help you write code, it takes ownership of problems and works through them the way a thoughtful engineer would.
The Claude Agent SDK is the same engine, yours to point at whatever problem you want, so you can easily build agents of your own.
It's the infrastructure behind Claude Code, exposed as a library. You get the agent loop, the built-in tools, the context management, basically everything you'd otherwise have to build yourself.
This guide walks through building a code review agent from scratch. By the end, you'll have something that can analyze a codebase, find bugs and security issues, and return structured feedback.
More importantly, you'll understand how the SDK works so you can build whatever you actually need.
What we're building
Our code review agent will:
Analyze a codebase for bugs and security issues
Read files and search through code autonomously
Provide structured, actionable feedback
Track its progress as it works
The stack
• Runtime - Claude Code CLI
• SDK - @anthropic-ai/claude-agent-sdk
• Language - TypeScript 
• Model - Claude Opus 4.5
What the SDK gives you
If you've built agents with the raw API, you know the pattern: call the model, check if it wants to use a tool, execute the tool, feed the result back, repeat until done. This can get tedious when building anything non-trivial.
The SDK handles that loop:
typescript
// Without the SDK: You manage the loop
let response = await client.messages.create({...});
while (response.stop_reason === "tool_use") {
  const result = yourToolExecutor(response.tool_use);
  response = await client.messages.create({ tool_result: result, ... });
}

// With the SDK: Claude manages it
for await (const message of query({ prompt: "Fix the bug in auth.py" })) {
  console.log(message); // Claude reads files, finds bugs, edits code
}
You also get working tools out of the box:
• Read - read any file in the working directory
• Write - create new files
• Edit - make precise edits to existing files
• Bash - run terminal commands
• Glob - find files by pattern
• Grep - search file contents with regex
• WebSearch - search the web
• WebFetch - fetch and parse web pages
You don't have to implement any of this yourself.
Prerequisites
Node.js 18+ installed
An Anthropic API key (get one here)
Getting started
Step 1: Install Claude Code CLI
The Agent SDK uses Claude Code as its runtime:
bash
npm install -g @anthropic-ai/claude-code
After installing, run claude in your terminal and follow the prompts to authenticate.
Step 2: Create your project
bash
mkdir code-review-agent && cd code-review-agent
npm init -y
npm install @anthropic-ai/claude-agent-sdk
npm install -D typescript @types/node tsx
Step 3: Set your API key
bash
export ANTHROPIC_API_KEY=your-api-key
Your first agent
Create agent.ts:
typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function main() {
  for await (const message of query({
    prompt: "What files are in this directory?",
    options: {
      model: "opus",
      allowedTools: ["Glob", "Read"],
      maxTurns: 250
    }
  })) {
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log(block.text);
        }
      }
    }
    
    if (message.type === "result") {
      console.log("\nDone:", message.subtype);
    }
  }
}

main();
Run it:
bash
npx tsx agent.ts
Claude will use the Glob tool to list files and tell you what it found.
Understanding the message stream
The query() function returns an async generator that streams messages as Claude works. Here are the key message types:
typescript
for await (const message of query({ prompt: "..." })) {
  switch (message.type) {
    case "system":
      // Session initialization info
      if (message.subtype === "init") {
        console.log("Session ID:", message.session_id);
        console.log("Available tools:", message.tools);
      }
      break;
      
    case "assistant":
      // Claude's responses and tool calls
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log("Claude:", block.text);
        } else if ("name" in block) {
          console.log("Tool call:", block.name);
        }
      }
      break;
      
    case "result":
      // Final result
      console.log("Status:", message.subtype); // "success" or error type
      console.log("Cost:", message.total_cost_usd);
      break;
  }
}
Building a code review agent
Now let's build something useful. Create review-agent.ts:
typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function reviewCode(directory: string) {
  console.log(`\n🔍 Starting code review for: ${directory}\n`);
  
  for await (const message of query({
    prompt: `Review the code in ${directory} for:
1. Bugs and potential crashes
2. Security vulnerabilities  
3. Performance issues
4. Code quality improvements

Be specific about file names and line numbers.`,
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep"],
      permissionMode: "bypassPermissions", // Auto-approve read operations
      maxTurns: 250
    }
  })) {
    // Show Claude's analysis as it happens
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log(block.text);
        } else if ("name" in block) {
          console.log(`\n📁 Using ${block.name}...`);
        }
      }
    }
    
    // Show completion status
    if (message.type === "result") {
      if (message.subtype === "success") {
        console.log(`\n✅ Review complete! Cost: $${message.total_cost_usd.toFixed(4)}`);
      } else {
        console.log(`\n❌ Review failed: ${message.subtype}`);
      }
    }
  }
}

// Review the current directory
reviewCode(".");
Testing It Out
Create a file with some intentional issues. Create example.ts:
typescript
function processUsers(users: any) {
  for (let i = 0; i <= users.length; i++) { // Off-by-one error
    console.log(users[i].name.toUpperCase()); // No null check
  }
}

function connectToDb(password: string) {
  const connectionString = `postgres://admin:${password}@localhost/db`;
  console.log("Connecting with:", connectionString); // Logging sensitive data
}

async function fetchData(url) { // Missing type annotation
  const response = await fetch(url);
  return response.json(); // No error handling
}
Run the review:
bash
npx tsx review-agent.ts
Claude will identify the bugs, security issues, and suggest fixes.
Adding Structured Output
For programmatic use, you'll want structured data. The SDK supports JSON Schema output:
typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const reviewSchema = {
  type: "object",
  properties: {
    issues: {
      type: "array",
      items: {
        type: "object",
        properties: {
          severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
          category: { type: "string", enum: ["bug", "security", "performance", "style"] },
          file: { type: "string" },
          line: { type: "number" },
          description: { type: "string" },
          suggestion: { type: "string" }
        },
        required: ["severity", "category", "file", "description"]
      }
    },
    summary: { type: "string" },
    overallScore: { type: "number" }
  },
  required: ["issues", "summary", "overallScore"]
};

async function reviewCodeStructured(directory: string) {
  for await (const message of query({
    prompt: `Review the code in ${directory}. Identify all issues.`,
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep"],
      permissionMode: "bypassPermissions",
      maxTurns: 250,
      outputFormat: {
        type: "json_schema",
        schema: reviewSchema
      }
    }
  })) {
    if (message.type === "result" && message.subtype === "success") {
      const review = message.structured_output as {
        issues: Array<{
          severity: string;
          category: string;
          file: string;
          line?: number;
          description: string;
          suggestion?: string;
        }>;
        summary: string;
        overallScore: number;
      };
      
      console.log(`\n📊 Code Review Results\n`);
      console.log(`Score: ${review.overallScore}/100`);
      console.log(`Summary: ${review.summary}\n`);
      
      for (const issue of review.issues) {
        const icon = issue.severity === "critical" ? "🔴" :
                     issue.severity === "high" ? "🟠" :
                     issue.severity === "medium" ? "🟡" : "🟢";
        console.log(`${icon} [${issue.category.toUpperCase()}] ${issue.file}${issue.line ? `:${issue.line}` : ""}`);
        console.log(`   ${issue.description}`);
        if (issue.suggestion) {
          console.log(`   💡 ${issue.suggestion}`);
        }
        console.log();
      }
    }
  }
}

reviewCodeStructured(".");
Handling permissions
By default, the SDK asks for approval before executing tools. You can customize this:
Permission modes
typescript
options: {
  // Standard mode - prompts for approval
  permissionMode: "default",
  
  // Auto-approve file edits
  permissionMode: "acceptEdits",
  
  // No prompts (use with caution)
  permissionMode: "bypassPermissions"
}
Custom permission handler
For fine-grained control, use canUseTool:
typescript
options: {
  canUseTool: async (toolName, input) => {
    // Allow all read operations
    if (["Read", "Glob", "Grep"].includes(toolName)) {
      return { behavior: "allow", updatedInput: input };
    }
    
    // Block writes to certain files
    if (toolName === "Write" && input.file_path?.includes(".env")) {
      return { behavior: "deny", message: "Cannot modify .env files" };
    }
    
    // Allow everything else
    return { behavior: "allow", updatedInput: input };
  }
}
Creating subagents
For complex tasks, you can create specialized subagents:
typescript
import { query, AgentDefinition } from "@anthropic-ai/claude-agent-sdk";

async function comprehensiveReview(directory: string) {
  for await (const message of query({
    prompt: `Perform a comprehensive code review of ${directory}. 
Use the security-reviewer for security issues and test-analyzer for test coverage.`,
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep", "Task"], // Task enables subagents
      permissionMode: "bypassPermissions",
      maxTurns: 250,
      agents: {
        "security-reviewer": {
          description: "Security specialist for vulnerability detection",
          prompt: `You are a security expert. Focus on:
- SQL injection, XSS, CSRF vulnerabilities
- Exposed credentials and secrets
- Insecure data handling
- Authentication/authorization issues`,
          tools: ["Read", "Grep", "Glob"],
          model: "sonnet"
        } as AgentDefinition,
        
        "test-analyzer": {
          description: "Test coverage and quality analyzer",
          prompt: `You are a testing expert. Analyze:
- Test coverage gaps
- Missing edge cases
- Test quality and reliability
- Suggestions for additional tests`,
          tools: ["Read", "Grep", "Glob"],
          model: "haiku" // Use faster model for simpler analysis
        } as AgentDefinition
      }
    }
  })) {
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log(block.text);
        } else if ("name" in block && block.name === "Task") {
          console.log(`\n🤖 Delegating to: ${(block.input as any).subagent_type}`);
        }
      }
    }
  }
}

comprehensiveReview(".");
Session management
For multi-turn conversations, capture and resume sessions:
typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

async function interactiveReview() {
  let sessionId: string | undefined;
  
  // Initial review
  for await (const message of query({
    prompt: "Review this codebase and identify the top 3 issues",
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep"],
      permissionMode: "bypassPermissions",
      maxTurns: 250
    }
  })) {
    if (message.type === "system" && message.subtype === "init") {
      sessionId = message.session_id;
    }
    // ... handle messages
  }
  
  // Follow-up question using same session
  if (sessionId) {
    for await (const message of query({
      prompt: "Now show me how to fix the most critical issue",
      options: {
        resume: sessionId, // Continue the conversation
        allowedTools: ["Read", "Glob", "Grep"],
        maxTurns: 250
      }
    })) {
      // Claude remembers the previous context
    }
  }
}
Using hooks
Hooks let you intercept and customize agent behavior:
typescript
import { query, HookCallback, PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";

// Hook callbacks receive three arguments:
// 1. input - details about the event (tool name, arguments, etc.)
// 2. toolUseId - correlates PreToolUse and PostToolUse events for the same call
// 3. context - contains AbortSignal for cancellation
const auditLogger: HookCallback = async (input, toolUseId, { signal }) => {
  if (input.hook_event_name === "PreToolUse") {
    const preInput = input as PreToolUseHookInput;
    console.log(`[AUDIT] ${new Date().toISOString()} - ${preInput.tool_name}`);
  }
  return {}; // Return empty object to allow the operation
};

const blockDangerousCommands: HookCallback = async (input, toolUseId, { signal }) => {
  if (input.hook_event_name === "PreToolUse") {
    const preInput = input as PreToolUseHookInput;
    if (preInput.tool_name === "Bash") {
      const command = (preInput.tool_input as any).command || "";
      if (command.includes("rm -rf") || command.includes("sudo")) {
        return {
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",  // Block the tool from executing
            permissionDecisionReason: "Dangerous command blocked"
          }
        };
      }
    }
  }
  return {};
};

for await (const message of query({
  prompt: "Clean up temporary files",
  options: {
    model: "opus",
    allowedTools: ["Bash", "Glob"],
    maxTurns: 50,
    hooks: {
      // PreToolUse fires before each tool executes
      // Other hooks: PostToolUse, Stop, SessionStart, SessionEnd, etc.
      PreToolUse: [
        // Each entry has an optional matcher (regex) and an array of callbacks
        // No matcher = runs for ALL tool calls
        { hooks: [auditLogger] },
        
        // matcher: 'Bash' = only runs when tool_name matches 'Bash'
        // Use regex for multiple tools: 'Bash|Write|Edit'
        { matcher: "Bash", hooks: [blockDangerousCommands] }
      ]
    }
  }
})) {
  if (message.type === "assistant") {
    for (const block of message.message.content) {
      if ("text" in block) {
        console.log(block.text);
      }
    }
  }
}
Custom tool calling
Tools are how agents interact with the world - reading files, calling APIs, querying databases, running code. The SDK includes built-in tools for common operations (filesystem, shell, web), but most agents will need custom tools to access your own systems.
The raw API pattern
Without the SDK, you manage the tool loop yourself:
typescript
// 1. Define tools with their schemas
const tools = [{
  name: "get_weather",
  description: "Get current weather for a city",
  input_schema: {
    type: "object",
    properties: {
      city: { type: "string", description: "City name" }
    },
    required: ["city"]
  }
}];

// 2. Write an executor for each tool
function executeTool(name: string, input: any): string {
  if (name === "get_weather") {
    return fetchWeatherAPI(input.city);
  }
  throw new Error(`Unknown tool: ${name}`);
}

// 3. Run the agent loop
const messages = [{ role: "user", content: "What's the weather in Tokyo?" }];

let response = await client.messages.create({
  model: "claude-opus-4-5-20251101",
  tools,
  messages
});

while (response.stop_reason === "tool_use") {
  messages.push({ role: "assistant", content: response.content });
  
  const toolResults = response.content
    .filter(block => block.type === "tool_use")
    .map(toolUse => ({
      type: "tool_result",
      tool_use_id: toolUse.id,
      content: executeTool(toolUse.name, toolUse.input)
    }));
  
  messages.push({ role: "user", content: toolResults });
  response = await client.messages.create({ model, tools, messages });
}

const textBlock = response.content.find(block => block.type === "text");
if (textBlock && textBlock.type === "text") {
  console.log("Final response:", textBlock.text);
}
Key points:
Claude decides when to use tools based on the user's request and tool descriptions
You execute the tools and return results
The loop continues until Claude has enough information (`stop_reason: "end_turn"`)
Message history grows with each iteration - the API is stateless, so every request needs the full conversation
What the SDK handles
When you use built-in tools like `allowedTools: ["Read", "Glob"]`, the SDK manages all of this automatically - definitions, execution, and the loop.
For custom tools, you need a way to define them so the SDK can do the same. That's what MCP provides.
Adding custom tools with MCP
Extend Claude with custom tools using Model Context Protocol:
typescript
import { query, tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";

const customServer = createSdkMcpServer({
  name: "code-metrics",
  version: "1.0.0",
  tools: [
    tool(
      "analyze_complexity",
      "Calculate cyclomatic complexity for a file",
      {
        filePath: z.string().describe("Path to the file to analyze")
      },
      async (args) => {
        const complexity = Math.floor(Math.random() * 20) + 1;
        return {
          content: [{
            type: "text",
            text: `Cyclomatic complexity for ${args.filePath}: ${complexity}`
          }]
        };
      }
    )
  ]
});

async function analyzeCode(filePath: string) {
  for await (const message of query({
    prompt: `Analyze the complexity of ${filePath}`,
    options: {
      model: "opus",
      mcpServers: {
        "code-metrics": customServer
      },
      allowedTools: ["Read", "mcp__code-metrics__analyze_complexity"],
      maxTurns: 50
    }
  })) {
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log(block.text);
        }
      }
    }
    
    if (message.type === "result") {
      console.log("Done:", message.subtype);
    }
  }
}

analyzeCode("main.ts");
Cost tracking
Track API costs for billing:
typescript
for await (const message of query({ prompt: "..." })) {
  if (message.type === "result" && message.subtype === "success") {
    console.log("Total cost:", message.total_cost_usd);
    console.log("Token usage:", message.usage);
    
    // Per-model breakdown (useful with subagents)
    for (const [model, usage] of Object.entries(message.modelUsage)) {
      console.log(`${model}: $${usage.costUSD.toFixed(4)}`);
    }
  }
}
Production code review agent
Here's a production-ready agent that ties everything together:
typescript
import { query, AgentDefinition } from "@anthropic-ai/claude-agent-sdk";

interface ReviewResult {
  issues: Array<{
    severity: "low" | "medium" | "high" | "critical";
    category: "bug" | "security" | "performance" | "style";
    file: string;
    line?: number;
    description: string;
    suggestion?: string;
  }>;
  summary: string;
  overallScore: number;
}

const reviewSchema = {
  type: "object",
  properties: {
    issues: {
      type: "array",
      items: {
        type: "object",
        properties: {
          severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
          category: { type: "string", enum: ["bug", "security", "performance", "style"] },
          file: { type: "string" },
          line: { type: "number" },
          description: { type: "string" },
          suggestion: { type: "string" }
        },
        required: ["severity", "category", "file", "description"]
      }
    },
    summary: { type: "string" },
    overallScore: { type: "number" }
  },
  required: ["issues", "summary", "overallScore"]
};

async function runCodeReview(directory: string): Promise<ReviewResult | null> {
  console.log(`\n${"=".repeat(50)}`);
  console.log(`🔍 Code Review Agent`);
  console.log(`📁 Directory: ${directory}`);
  console.log(`${"=".repeat(50)}\n`);

  let result: ReviewResult | null = null;

  for await (const message of query({
    prompt: `Perform a thorough code review of ${directory}.

Analyze all source files for:
1. Bugs and potential runtime errors
2. Security vulnerabilities
3. Performance issues
4. Code quality and maintainability

Be specific with file paths and line numbers where possible.`,
    options: {
      model: "opus",
      allowedTools: ["Read", "Glob", "Grep", "Task"],
      permissionMode: "bypassPermissions",
      maxTurns: 250,
      outputFormat: {
        type: "json_schema",
        schema: reviewSchema
      },
      agents: {
        "security-scanner": {
          description: "Deep security analysis for vulnerabilities",
          prompt: `You are a security expert. Scan for:
- Injection vulnerabilities (SQL, XSS, command injection)
- Authentication and authorization flaws
- Sensitive data exposure
- Insecure dependencies`,
          tools: ["Read", "Grep", "Glob"],
          model: "sonnet"
        } as AgentDefinition
      }
    }
  })) {
    // Progress updates
    if (message.type === "assistant") {
      for (const block of message.message.content) {
        if ("name" in block) {
          if (block.name === "Task") {
            console.log(`🤖 Delegating to: ${(block.input as any).subagent_type}`);
          } else {
            console.log(`📂 ${block.name}: ${getToolSummary(block)}`);
          }
        }
      }
    }

    // Final result
    if (message.type === "result") {
      if (message.subtype === "success" && message.structured_output) {
        result = message.structured_output as ReviewResult;
        console.log(`\n✅ Review complete! Cost: $${message.total_cost_usd.toFixed(4)}`);
      } else {
        console.log(`\n❌ Review failed: ${message.subtype}`);
      }
    }
  }

  return result;
}

function getToolSummary(block: any): string {
  const input = block.input || {};
  switch (block.name) {
    case "Read": return input.file_path || "file";
    case "Glob": return input.pattern || "pattern";
    case "Grep": return `"${input.pattern}" in ${input.path || "."}`;
    default: return "";
  }
}

function printResults(result: ReviewResult) {
  console.log(`\n${"=".repeat(50)}`);
  console.log(`📊 REVIEW RESULTS`);
  console.log(`${"=".repeat(50)}\n`);
  
  console.log(`Score: ${result.overallScore}/100`);
  console.log(`Issues Found: ${result.issues.length}\n`);
  console.log(`Summary: ${result.summary}\n`);
  
  const byCategory = {
    critical: result.issues.filter(i => i.severity === "critical"),
    high: result.issues.filter(i => i.severity === "high"),
    medium: result.issues.filter(i => i.severity === "medium"),
    low: result.issues.filter(i => i.severity === "low")
  };
  
  for (const [severity, issues] of Object.entries(byCategory)) {
    if (issues.length === 0) continue;
    
    const icon = severity === "critical" ? "🔴" :
                 severity === "high" ? "🟠" :
                 severity === "medium" ? "🟡" : "🟢";
    
    console.log(`\n${icon} ${severity.toUpperCase()} (${issues.length})`);
    console.log("-".repeat(30));
    
    for (const issue of issues) {
      const location = issue.line ? `${issue.file}:${issue.line}` : issue.file;
      console.log(`\n[${issue.category}] ${location}`);
      console.log(`  ${issue.description}`);
      if (issue.suggestion) {
        console.log(`  💡 ${issue.suggestion}`);
      }
    }
  }
}

// Run the review
async function main() {
  const directory = process.argv[2] || ".";
  const result = await runCodeReview(directory);
  
  if (result) {
    printResults(result);
  }
}

main().catch(console.error);
Run it:
bash
npx tsx review-agent.ts ./src
What's next
The code review agent covers the essentials: query(), allowedTools, structured output, subagents, and permissions. 
If you want to go deeper:
More capabilities
File checkpointing - track and revert file changes
Skills - package reusable capabilities
Production deployment
Hosting - deploy in containers and CI/CD
Secure deployment - sandboxing and credential management
Full reference
TypeScript SDK reference 
Python SDK reference 
This guide covers V1 of the SDK. V2 is currently in development. I will update this guide with V2 once it's released and stable.

If you're interested in building verifiable agents, check out the work we're doing at @eigencloud here.


nader dabit

@dabit3
You Could've Invented Claude Code 
What makes Claude Code powerful is surprisingly simple: it's a loop that lets an AI read files, run commands, and iterate until a task is done. 
The complexity comes from handling edge cases, building a good UX, and integrating with real development workflows.
In this post, I'll start from scratch and build up to Claude Code's architecture step by step, showing how you could have invented it yourself from first principles, using nothing but a terminal, an LLM API, and the desire to make AI actually useful.
End goal: learn how powerful agents work, so you can build your own
First, let's establish the problem we're trying to solve.
When you use ChatGPT or Claude in a browser, you're doing a lot of manual labor:
Copy-paste code from the chat into files
Run commands yourself, then copy errors back
Provide context by uploading files or pasting content
Manually iterate through the fix-test-debug cycle
You're essentially acting as the AI's hands. The AI thinks; you execute.
What if the AI could execute too?
Imagine telling an AI: "Fix the bug in auth.py" and walking away. When you come back, the bug is fixed. The AI read the file, understood it, tried a fix, ran the tests, saw them fail, tried another approach, and eventually succeeded.
This is what an agent does. It's an AI that can:
Take actions in the real world (read files, run commands)
Observe the results
Decide what to do next
Repeat until the task is complete
Let's build one from scratch.
The Simplest Possible Agent
Let's start with the absolute minimum: an AI that can run a single bash command.
bash
#!/bin/bash
# agent-v0.sh - The simplest possible agent

PROMPT="$1"

# Ask Claude what command to run
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-5-20251101",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "'"$PROMPT"'\n\nRespond with ONLY a bash command. No markdown, no explanation, no code blocks."}]
  }')

# Extract the command from response
COMMAND=$(echo "$RESPONSE" | jq -r '.content[0].text')

echo "AI suggests: $COMMAND"
read -r -p "Run this command? (y/n) " CONFIRM

if [ "$CONFIRM" = "y" ]; then
  eval "$COMMAND"
fi
Usage
bash
bash agent-v0.sh "list all Python files in this directory"
# AI suggests: ls *.py
# Run this command? (y/n)
This is... not very useful. The AI can suggest one command, then you're back to doing everything manually.
But here's the key insight: what if we put this in a loop?
Goal: Creating the agent loop
The fundamental insight behind all AI agents is the agent loop:
plaintext
while (task not complete):
    1. AI decides what to do next
    2. Execute that action
    3. Show AI the result
    4. Go back to step 1
Let's implement exactly this. The AI needs to tell us:
What action to take
Whether it's done
We'll use a simple JSON format:
bash
#!/bin/bash
# agent-v1.sh - Agent with a loop

SYSTEM_PROMPT='You are a helpful assistant that can run bash commands.

When the user gives you a task, respond with JSON in this exact format:
{"action": "bash", "command": "your command here"}

When the task is complete, respond with:
{"action": "done", "message": "explanation of what was accomplished"}

Only respond with JSON. No other text.'

# We'll build messages as a JSON array (using jq for proper escaping)
MESSAGES="[]"

run_agent() {
    local USER_MSG="$1"
    
    # Add initial user message using jq to handle escaping
    MESSAGES=$(echo "$MESSAGES" | jq --arg msg "$USER_MSG" '. + [{"role": "user", "content": $msg}]')
    
    while true; do
        # Build the request body properly with jq
        REQUEST_BODY=$(jq -n \
            --arg model "claude-opus-4-5-20251101" \
            --arg system "$SYSTEM_PROMPT" \
            --argjson messages "$MESSAGES" \
            '{model: $model, max_tokens: 1024, system: $system, messages: $messages}')
        
        # Call the API
        RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
          -H "x-api-key: $ANTHROPIC_API_KEY" \
          -H "content-type: application/json" \
          -H "anthropic-version: 2023-06-01" \
          -d "$REQUEST_BODY")
        # Echo the response for debugging
        AI_TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text')
        
        # Add assistant message to history
        MESSAGES=$(echo "$MESSAGES" | jq --arg msg "$AI_TEXT" '. + [{"role": "assistant", "content": $msg}]')
        
        # Parse the action from the JSON response
        ACTION=$(echo "$AI_TEXT" | jq -r '.action // empty')
        
        if [ -z "$ACTION" ]; then
            echo "❌ Could not parse response: $AI_TEXT"
            break
        elif [ "$ACTION" = "done" ]; then
            echo "✅ $(echo "$AI_TEXT" | jq -r '.message')"
            break
        elif [ "$ACTION" = "bash" ]; then
            COMMAND=$(echo "$AI_TEXT" | jq -r '.command')
            echo "🔧 Running: $COMMAND"
            
            # Execute and capture output
            OUTPUT=$(eval "$COMMAND" 2>&1)
            echo "$OUTPUT"
            
            # Feed result back to AI
            MESSAGES=$(echo "$MESSAGES" | jq --arg msg "Command output: $OUTPUT" '. + [{"role": "user", "content": $msg}]')
        else
            echo "❌ Unknown action: $ACTION"
            break
        fi
    done
}

run_agent "$1"
Now we have something that can actually iterate:
bash
bash agent-v1.sh "Create a file called hello.py that prints hello world, then run it"

# 🔧 Running: echo 'print("hello world")' > hello.py
# 🔧 Running: python hello.py
# hello world
# ✅ Created hello.py and executed it successfully. It prints "hello world".
The AI ran two commands and then told us it was done. We've created an agent loop!
But wait! We're executing arbitrary commands with no safety checks. The AI could rm -rf / and we'd blindly execute it.
Goal: Adding permission controls
Let's add a human-in-the-loop for dangerous operations. First, we define a function that wraps command execution with a safety check:
bash
# Add this function BEFORE run_agent() in your script
execute_with_permission() {
    local COMMAND="$1"
    
    # Check if command seems dangerous
    if echo "$COMMAND" | grep -qE 'rm |sudo |chmod |curl.*\|.*sh'; then
        # Use >&2 to print to stderr, so prompts display immediately
        # (stdout gets captured by the $(...) in the agent loop)
        echo "⚠️  Potentially dangerous command: $COMMAND" >&2
        echo "Allow? (y/n)" >&2
        read CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            echo "DENIED BY USER"
            return 1
        fi
    fi
    
    eval "$COMMAND" 2>&1
}
Then, inside the agent loop, we replace the direct eval call with our new function:
bash
        # BEFORE:
        OUTPUT=$(eval "$COMMAND" 2>&1)
        
        # AFTER (with permission check):
        OUTPUT=$(execute_with_permission "$COMMAND")
That's it! The function sits between the AI's request and actual execution, giving you a chance to block dangerous commands. When denied, you can feed that back to the AI so it can try a different approach.
Try it out:
bash
# Create a test file
echo 'print("hello world")' > hello.py

# Ask the agent to delete it
bash agent-v1.sh "delete the file hello.py"

# 🔧 Running: rm hello.py
# ⚠️  Potentially dangerous command: rm hello.py
# Allow? (y/n)
Type y to allow the deletion, or n to block it.
This is the beginning of a permission system. Claude Code takes this much further with:
Tool-specific permissions (file edits vs. bash commands)
Pattern-based allowlists (Bash(npm test:*) allows any npm test command)
Session-level "accept all" modes for when you trust the AI
The key insight: the human should be able to control what the AI can do, but with enough granularity that it's not annoying.
Goal: Beyond bash - Adding tools
Running bash commands is powerful, but it's also:
Dangerous: unlimited access to the system
Inefficient: reading a file shouldn't spawn a subprocess
Imprecise: output parsing is fragile
What if we gave the AI structured tools instead?
We'll switch to Python here since it handles JSON and API calls more cleanly:
python
# agent-v2.py - Agent with structured tools
import anthropic
import json
import os

client = anthropic.Anthropic()

TOOLS = [
    {
        "name": "read_file",
        "description": "Read the contents of a file",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Path to the file"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "write_file",
        "description": "Write content to a file",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Path to the file"},
                "content": {"type": "string", "description": "Content to write"}
            },
            "required": ["path", "content"]
        }
    },
    {
        "name": "run_bash",
        "description": "Run a bash command",
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {"type": "string", "description": "The command to run"}
            },
            "required": ["command"]
        }
    }
]

def execute_tool(name, input):
    """Execute a tool and return the result."""
    if name == "read_file":
        try:
            with open(input["path"], "r") as f:
                return f.read()
        except Exception as e:
            return f"Error: {e}"
    
    elif name == "write_file":
        try:
            with open(input["path"], "w") as f:
                f.write(input["content"])
            return f"Successfully wrote to {input['path']}"
        except Exception as e:
            return f"Error: {e}"
    
    elif name == "run_bash":
        import subprocess
        result = subprocess.run(
            input["command"], 
            shell=True, 
            capture_output=True, 
            text=True
        )
        return result.stdout + result.stderr

def run_agent(task):
    """Main agent loop."""
    messages = [{"role": "user", "content": task}]
    
    while True:
        response = client.messages.create(
            model="claude-opus-4-5-20251101",
            max_tokens=4096,
            tools=TOOLS,
            messages=messages
        )
        
        # Check if we're done
        if response.stop_reason == "end_turn":
            # Extract final text response
            for block in response.content:
                if hasattr(block, "text"):
                    print(f"✅ {block.text}")
            break
        
        # Process tool uses
        if response.stop_reason == "tool_use":
            # Add assistant's response to history
            messages.append({"role": "assistant", "content": response.content})
            
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    print(f"🔧 {block.name}: {json.dumps(block.input)}")
                    result = execute_tool(block.name, block.input)
                    print(f"   → {result[:200]}...")  # Truncate for display
                    
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result
                    })
            
            # Add results to conversation
            messages.append({"role": "user", "content": tool_results})

if __name__ == "__main__":
    import sys
    run_agent(sys.argv[1])
Now we're using Anthropic's native tool use API. This is much better because:
Type safety: the AI knows exactly what parameters each tool accepts
Explicit actions: reading a file is a read_file call, not cat
Controlled surface area: we decide what tools exist
Try it out:
bash
# Create a test file for the agent to work with
cat > main.py << 'EOF'
def calculate(x, y):
    return x + y

def greet(name):
    print(f"Hello, {name}!")
EOF

# Run the agent
uv run --with anthropic python agent-v2.py "Read main.py and add a docstring to the first function"

# 🔧 read_file: {"path": "main.py"}
#    → def calculate(x, y):...
# 🔧 write_file: {"path": "main.py", "content": "def calculate(x, y):\n    \"\"\"Calculate..."}
#    → Successfully wrote to main.py
# ✅ I've added a docstring to the calculate function explaining its purpose.
Goal: Making edits precise
Our write_file tool has a problem: it replaces the entire file. If the AI makes a small change to a 1000-line file, it has to output all 1000 lines. This is:
Expensive: more output tokens = more cost
Error-prone: the AI might accidentally drop lines
Slow: generating that much text takes time
What if we had a tool for surgical edits?
python
{
    "name": "edit_file",
    "description": "Make a precise edit to a file by replacing a unique string",
    "input_schema": {
        "type": "object",
        "properties": {
            "path": {"type": "string"},
            "old_str": {"type": "string", "description": "Exact string to find (must be unique in file)"},
            "new_str": {"type": "string", "description": "String to replace it with"}
        },
        "required": ["path", "old_str", "new_str"]
    }
}
Implementation:
python
def edit_file(path, old_str, new_str):
    with open(path, "r") as f:
        content = f.read()
    
    # Ensure the string is unique
    count = content.count(old_str)
    if count == 0:
        return f"Error: '{old_str}' not found in file"
    if count > 1:
        return f"Error: '{old_str}' found {count} times. Must be unique."
    
    new_content = content.replace(old_str, new_str)
    with open(path, "w") as f:
        f.write(new_content)
    
    return f"Successfully replaced text in {path}"
This is exactly how Claude Code's str_replace tool works. The requirement for uniqueness might seem annoying, but it's actually a feature:
Forces the AI to include enough context to be unambiguous
Creates a natural diff that's easy for humans to review
Prevents accidental mass replacements
Goal: Searching the Codebase
So far our agent can read files it knows about. But what about a task like "find where the authentication bug is"?
The AI needs to search the codebase. Let's add tools for that.
python
SEARCH_TOOLS = [
    {
        "name": "glob",
        "description": "Find files matching a pattern",
        "input_schema": {
            "type": "object",
            "properties": {
                "pattern": {"type": "string", "description": "Glob pattern (e.g., '**/*.py')"}
            },
            "required": ["pattern"]
        }
    },
    {
        "name": "grep",
        "description": "Search for a pattern in files",
        "input_schema": {
            "type": "object",
            "properties": {
                "pattern": {"type": "string", "description": "Regex pattern to search for"},
                "path": {"type": "string", "description": "Directory or file to search in"}
            },
            "required": ["pattern"]
        }
    }
]
Now the AI can:
glob("**/*.py") → Find all Python files
grep("def authenticate", "src/") → Find authentication code
read_file("src/auth.py") → Read the relevant file
edit_file(...) → Fix the bug
This is the pattern: give the AI tools to explore, and it can navigate codebases it's never seen before.
Goal: Context management
Here's a problem you'll hit quickly: context windows are finite.
If you're working on a large codebase, the conversation might look like:
User: "Fix the bug in authentication"
AI: reads 10 files, runs 20 commands, tries 3 approaches
...conversation is now 100,000 tokens
AI: runs out of context and starts forgetting earlier information
How do we handle this?
Option 1: summarization (compaction)
When context gets too long, summarize what happened:
python
def compact_conversation(messages):
    """Summarize the conversation to free up context."""
    summary_prompt = """Summarize this conversation concisely, preserving:
    - The original task
    - Key findings and decisions
    - Current state of the work
    - What still needs to be done"""
    
    summary = client.messages.create(
        model="claude-opus-4-5-20251101",
        max_tokens=2000,
        messages=[
            {"role": "user", "content": f"{messages}\n\n{summary_prompt}"}
        ]
    )
    
    return [{"role": "user", "content": f"Previous work summary:\n{summary}"}]
Option 2: sub-agents (delegation)
For complex tasks, spawn a sub-agent with its own context:
python
def delegate_to_subagent(task, tools_allowed):
    """Spawn a sub-agent for a focused task."""
    result = run_agent(
        task=task,
        tools=tools_allowed,
        max_turns=10  # Prevent infinite loops
    )
    # Only return the result, not the full conversation
    return result.final_answer
This is why Claude Code has the concept of subagents: specialized agents that handle focused tasks in their own context, returning just the results.
Goal: the system prompt
We've been glossing over something important: how does the AI know how to behave?
The system prompt is where you encode:
The AI's identity and capabilities
Guidelines for tool usage
Project-specific context
Behavioral rules
Here's a simplified version of what makes Claude Code effective:
python
SYSTEM_PROMPT = """You are an AI assistant that helps with software development tasks.
You have access to the following tools:
- read_file: Read file contents
- write_file: Create or overwrite files
- edit_file: Make precise edits to existing files
- glob: Find files by pattern
- grep: Search for patterns in files
- bash: Run shell commands

## Guidelines

### Before making changes:
1. Understand the task fully before acting
2. Read relevant files to understand context
3. Plan your approach

### When editing code:
1. Use edit_file for small changes (preferred)
2. Use write_file only for new files or complete rewrites
3. Run tests after changes when possible
4. If tests fail, analyze the error and iterate

### General principles:
- Be concise but thorough
- Explain your reasoning briefly
- Ask for clarification if the task is ambiguous
- If you're stuck, say so instead of guessing

## Current Directory
You are working in: {current_directory}
"""
But here's the problem: what if the project has specific conventions? What if the team uses a particular testing framework, or has a non-standard directory structure?
Goal: Project-Specific Context (CLAUDE.md)
Claude Code solves this with CLAUDE.md - a file at the project root that gets automatically included in context:
markdown
# CLAUDE.md

## Project Overview
This is a FastAPI application for user authentication.

## Key Commands
- `make test`: Run all tests
- `make lint`: Run linting
- `make dev`: Start development server

## Architecture
- `src/api/`: API routes
- `src/models/`: Database models
- `src/services/`: Business logic
- `tests/`: Test files (mirror src/ structure)

## Conventions
- All functions must have type hints
- Use pydantic for request/response models
- Write tests before implementing features (TDD)

## Known Issues
- The /auth/refresh endpoint has a race condition (see issue #142)
Now the AI knows:
How to run tests for this project
Where to find things
What conventions to follow
Known gotchas to watch out for
This is one of Claude Code's most powerful features: project knowledge that travels with the code.
Putting it all together
Let's see what we've built. The core of an AI coding agent is this loop:
1. Setup (runs once)
Load the system prompt with tool descriptions, behavioral guidelines, and project context (CLAUDE.md)
Initialize an empty conversation history
2. Agent Loop (repeats until done)
Send conversation history to the LLM
LLM decides: use a tool or respond to user
If tool use:
plaintext
1. Check permissions (prompt user if dangerous)
2.Execute the tool (read_file, edit_file, bash, glob, grep, etc.)
3. Add the result to conversation history
4. Loop back to step 2
If final answer:
plaintext
1. Display response to user
2. Done
That's it. Every AI coding agent, from our 50-line bash script to Claude Code, follows this pattern.
Now let's build a complete, working mini-Claude Code that you can actually use. It combines everything we've learned: the agent loop, structured tools, permission checks, and an interactive REPL:
bash
#!/usr/bin/env python3
# mini-claude-code.py - A minimal Claude Code clone

import anthropic
import subprocess
import os
import json

client = anthropic.Anthropic()

TOOLS = [
    {
        "name": "read_file",
        "description": "Read the contents of a file",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Path to the file"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "write_file",
        "description": "Write content to a file (creates or overwrites)",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Path to the file"},
                "content": {"type": "string", "description": "Content to write"}
            },
            "required": ["path", "content"]
        }
    },
    {
        "name": "list_files",
        "description": "List files in a directory",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Directory path (default: current directory)"}
            }
        }
    },
    {
        "name": "run_command",
        "description": "Run a shell command",
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {"type": "string", "description": "The command to run"}
            },
            "required": ["command"]
        }
    }
]

DANGEROUS_PATTERNS = ["rm ", "sudo ", "chmod ", "mv ", "cp ", "> ", ">>"]

def check_permission(tool_name, tool_input):
    """Check if an action requires user permission."""
    if tool_name == "run_command":
        cmd = tool_input.get("command", "")
        if any(p in cmd for p in DANGEROUS_PATTERNS):
            print(f"\n⚠️  Potentially dangerous command: {cmd}")
            response = input("Allow? (y/n): ").strip().lower()
            return response == "y"
    elif tool_name == "write_file":
        path = tool_input.get("path", "")
        print(f"\n📝 Will write to: {path}")
        response = input("Allow? (y/n): ").strip().lower()
        return response == "y"
    return True

def execute_tool(name, tool_input):
    """Execute a tool and return the result."""
    if name == "read_file":
        path = tool_input["path"]
        try:
            with open(path, "r") as f:
                content = f.read()
            return f"Contents of {path}:\n{content}"
        except Exception as e:
            return f"Error reading file: {e}"

    elif name == "write_file":
        path = tool_input["path"]
        content = tool_input["content"]
        try:
            with open(path, "w") as f:
                f.write(content)
            return f"✅ Successfully wrote to {path}"
        except Exception as e:
            return f"Error writing file: {e}"

    elif name == "list_files":
        path = tool_input.get("path", ".")
        try:
            files = os.listdir(path)
            return f"Files in {path}:\n" + "\n".join(f"  {f}" for f in sorted(files))
        except Exception as e:
            return f"Error listing files: {e}"

    elif name == "run_command":
        cmd = tool_input["command"]
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            return f"$ {cmd}\n{output}" if output else f"$ {cmd}\n(no output)"
        except subprocess.TimeoutExpired:
            return f"Command timed out after 30 seconds"
        except Exception as e:
            return f"Error running command: {e}"

    return f"Unknown tool: {name}"

def agent_loop(user_message, conversation_history):
    """Run the agent loop until the task is complete."""
    conversation_history.append({"role": "user", "content": user_message})

    while True:
        # Call Claude
        response = client.messages.create(
            model="claude-opus-4-5-20251101",
            max_tokens=4096,
            system=f"You are a helpful coding assistant. Working directory: {os.getcwd()}",
            tools=TOOLS,
            messages=conversation_history
        )

        # Add assistant response to history
        conversation_history.append({"role": "assistant", "content": response.content})

        # Check if we're done (no tool use)
        if response.stop_reason == "end_turn":
            # Print the final text response
            for block in response.content:
                if hasattr(block, "text"):
                    print(f"\n🤖 {block.text}")
            break

        # Process tool calls
        tool_results = []
        for block in response.content:
            if block.type == "tool_use":
                tool_name = block.name
                tool_input = block.input

                print(f"\n🔧 {tool_name}: {json.dumps(tool_input)}")

                # Check permissions
                if not check_permission(tool_name, tool_input):
                    result = "Permission denied by user"
                    print(f"   🚫 {result}")
                else:
                    result = execute_tool(tool_name, tool_input)
                    # Truncate long output for display
                    display = result[:200] + "..." if len(result) > 200 else result
                    print(f"   → {display}")

                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": result
                })

        # Add tool results to conversation
        conversation_history.append({"role": "user", "content": tool_results})

    return conversation_history

def main():
    print("Mini Claude Code")
    print(" Type your requests, or 'quit' to exit.\n")

    conversation_history = []

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if not user_input:
            continue
        if user_input.lower() in ["quit", "exit", "q"]:
            print("Goodbye!")
            break

        conversation_history = agent_loop(user_input, conversation_history)

if __name__ == "__main__":
    main()
Save this as mini-claude-code.py and run it:
bash
uv run --with anthropic python mini-claude-code.py
Here's what a session looks like:
bash
Mini Claude Code
 Type your requests, or 'quit' to exit.

You: create a python file that prints the fibonacci sequence up to n

🔧 write_file: {"path": "fibonacci.py", "content": "def fibonacci(n):\n    ..."}

📝 Will write to: fibonacci.py
Allow? (y/n): y
   → ✅ Successfully wrote to fibonacci.py

🤖 I've created fibonacci.py with a function that prints the Fibonacci sequence.
   Would you like me to run it to test it?

You: yes, run it with n=10

🔧 run_command: {"command": "python fibonacci.py 10"}
   → $ python fibonacci.py 10
     0 1 1 2 3 5 8 13 21 34

🤖 The script works correctly! It printed the first 10 Fibonacci numbers.

You: quit
Goodbye!
That's a working mini Claude Code clone in ~150 lines. It has:
Interactive REPL: keeps conversation context between prompts
Multiple tools: read, write, list files, run commands
Permission checks: asks before writing files or running dangerous commands
Conversation memory: each follow-up builds on previous context
This is essentially what Claude Code does, plus:
A polished terminal UI
Sophisticated permission system
Context compaction when conversations get long
Subagent delegation for complex tasks
Hooks for custom automation
Integration with git and other dev tools
The Claude Agent SDK
If you want to build on this foundation without reinventing the wheel, Anthropic offers the Claude Agent SDK. It's the same engine that powers Claude Code, exposed as a library.
Here's what our simple agent looks like using the SDK:
typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Fix the bug in auth.py",
  options: {
    model: "claude-opus-4-5-20251101",
    allowedTools: ["Read", "Edit", "Bash", "Glob", "Grep"],
    maxTurns: 50
  }
})) {
  if (message.type === "assistant") {
    for (const block of message.message.content) {
      if ("text" in block) {
        console.log(block.text);
      } else if ("name" in block) {
        console.log(`Using tool: ${block.name}`);
      }
    }
  }
}
The SDK handles:
The agent loop (so you don't have to)
All the built-in tools (Read, Write, Edit, Bash, Glob, Grep, etc.)
Permission management
Context tracking
Sub-agent coordination
What We've Learned
Starting from a simple bash script, we discovered:
The agent loop: AI decides → execute → observe → repeat
Structured tools: better than raw bash for safety and precision
Surgical edits: str_replace beats full file rewrites
Search tools: let the AI explore codebases
Context management: compaction and delegation handle long tasks
Project knowledge: CLAUDE.md gives project-specific context
Each of these emerged from a practical problem:
"How do I make the AI do more than one thing?" → agent loop
"How do I prevent it from destroying my system?" → permission system
"How do I make edits efficient?" → str_replace tool
"How does it find code it doesn't know about?" → search tools
"What happens when context runs out?" → compaction
"How does it know my project's conventions?" → CLAUDE.md
This is how you could have invented Claude Code. The core ideas are simple.
Again - the complexity comes from handling edge cases, building a good UX, and integrating with real development workflows.
Next Steps
If you want to build your own agents:
Start simple: a basic agent loop with 2-3 tools
Add tools incrementally: each new capability should solve a real problem
Handle errors gracefully: tools fail; your agent should recover
Test on real tasks: the edge cases will teach you what's missing
Consider using the Claude Agent SDK: why reinvent the wheel?
The future of software development is agents that can actually do things. Now we know how they work!
Resources:
Claude Agent SDK Documentation
Claude Code Documentation
Anthropic API Reference