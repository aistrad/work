---
name: vibe-review
description: |
  Vibe Review - Codex CLI 驱动的自动代码审查、测试与修复工具。
  先在主对话中收集上下文，再启动后台 Agent 执行审查/测试/修复，不阻塞用户。
  触发词：vibe-review, 代码审查, review, codex review
---

# Vibe Review - Codex CLI 自动代码审查与修复

## ⚠️ 执行指令（Claude Code 必须严格遵循）

**收到 `/vibe-review` 后，按以下步骤执行：**

### Step 1: 在主对话中收集上下文

从本次对话中收集（后台 Agent 无法访问对话历史，必须在此步骤完成）：
- 所有 Read 过的代码文件路径
- 所有 Edit/Write 过的代码文件路径
- 用户指定的额外文件
- 用户提供的说明/需求

### Step 2: 启动后台 Agent

使用 Task 工具启动后台 Agent，把 Step 1 收集的信息写入 prompt：

```
Task 工具参数：
- subagent_type: "general-purpose"
- run_in_background: true
- description: "Vibe Review"
- prompt: 见下方模板，填入文件列表和用户说明
```

### Step 3: 立即返回

告诉用户：
- Agent 已在后台启动
- Agent ID
- 检查进度：`/tasks`

**不要等待，立即返回控制权**

---

## Agent Prompt 模板

```
你是 Vibe Review Agent。执行代码审查、测试、修复流程。

## 待审查的文件
{在此填入 Step 1 收集的文件列表}

## 用户说明
{在此填入用户提供的说明，如无则写"无"}

## 执行流程

循环执行以下步骤（最多 3 轮）：

1. 读取文件并分析代码逻辑，生成 Mermaid 时序图（sequenceDiagram），展示函数调用流程、模块交互、数据流向
2. 检查 bug、安全漏洞、逻辑错误
3. **端到端真实数据真实测试**（必须执行，记录所有输入输出）：
   - **Web 页面**：使用 Playwright 进行浏览器测试
   - **API 端点**：发送 HTTP 请求测试
   - **后端服务/函数**：调用函数测试
   - **CLI 工具**：执行命令测试
   - 必须记录：测试输入（请求/参数/操作）和测试输出（响应/返回值/结果）
   - 截图保存关键步骤（如适用）
4. 修复所有发现的问题，记录修改点
5. 如果还有错误，继续下一轮；否则退出

注意：避免在 Agent 内再次调用 Codex CLI 或启动新的 Agent，防止递归执行。

## 最终输出

# Vibe Review 报告

## 时序图
{展示步骤 1 生成的 Mermaid 时序图}

## 发现的问题
| 文件 | 行号 | 类型 | 描述 | 状态 |
|------|------|------|------|------|

## 端到端测试结果
| 测试步骤 | 输入 | 输出 | 状态 |
|----------|------|------|------|
| {步骤描述} | {发送的请求/参数/操作} | {收到的响应/返回值/结果} | ✅/❌ |

## 修复摘要
1. [文件:行号] 修复内容

## 最终状态
✅/❌ 完成
```

---

## 使用示例

```bash
/vibe-review                                    # 审查对话中涉及的代码
/vibe-review apps/api/services/identity/auth.py # 指定文件
/vibe-review "检查安全性"                        # 指定重点
```

## 注意事项

1. **Step 1 必须在主对话完成**：后台 Agent 无法访问对话历史
2. **立即返回**：启动 Agent 后不等待
3. **检查进度**：`/tasks`
