# VibeLife Agent & Skill 系统完整文档

> 版本: v5.0 | 更新日期: 2025-01

---

## 目录

1. [概述](#概述)
2. [架构](#架构)
3. [Skill 系统](#skill-系统)
4. [Agent 系统](#agent-系统)
5. [知识提炼系统](#知识提炼系统)
6. [CLI 工具](#cli-工具)
7. [API 参考](#api-参考)
8. [最佳实践](#最佳实践)

---

## 概述

VibeLife Agent & Skill 系统是一个模块化的 AI 对话框架，支持：

- **Skill 系统**：通过 Markdown 文件定义专业领域能力
- **Agent 系统**：基于 Claude Agent SDK 设计的对话引擎
- **知识提炼**：从知识库自动提炼 Skill 的方法论和流程
- **热重载**：修改 Skill 后无需重启即可生效

---

## 架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           VibeLife Agent System                          │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                         CoreAgent                                │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │ SkillLoader │  │  LLM Client │  │ Tool System │             │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                         Skills                                   │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │   │
│  │  │  Core   │  │  Bazi   │  │ Zodiac  │  │  ...    │            │   │
│  │  │SKILL.md │  │SKILL.md │  │SKILL.md │  │SKILL.md │            │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Knowledge (RAG)                               │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │  Retrieval  │  │  Embedding  │  │  pgvecto.rs │             │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 数据流

```
用户消息 → CoreAgent → SkillLoader (加载 SKILL.md)
                ↓
         构建 System Prompt (Core + Active Skills + User Profile)
                ↓
         调用 LLM → 可能触发 Tool Call
                ↓
         RAG 检索 (按需) ← Knowledge 知识库
                ↓
         生成回复 → 前端渲染 (Generative UI)
```

---

## Skill 系统

### 目录结构

```
apps/api/skills/
├── README.md                 # 架构文档
├── core/                     # Core Skill（始终加载）
│   ├── SKILL.md             # 主指令
│   ├── DIALOGUE.md          # 对话技术库
│   └── CRISIS.md            # 危机处理指南
├── bazi/                     # 八字 Skill
│   └── SKILL.md             # 主指令
├── zodiac/                   # 星座 Skill
│   └── SKILL.md             # 主指令
└── {new-skill}/              # 新 Skill
    └── SKILL.md             # 主指令（必需）
```

### SKILL.md 文件格式

```markdown
---
name: skill-name
description: |
  技能描述。用于 LLM 选择技能时参考。
  应包含：1) 能做什么 2) 何时使用
---

# Skill 标题

## 能力范围

- 能力 1
- 能力 2

## 分析原则

### 原则 1
说明...

## 表达方式

- 语言风格指南

## 禁止事项

- 不能做的事

## 可用工具

- `tool_name` - 工具描述
```

### Frontmatter 字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | ✅ | Skill 唯一标识符，小写+连字符，最多 32 字符 |
| `description` | ✅ | 技能描述，最多 512 字符 |
| `version` | ❌ | 版本号 |
| `tools` | ❌ | 声明使用的工具列表 |

### Skill 类型

| 类型 | 说明 | 加载时机 |
|------|------|---------|
| **Core Skill** | 基础对话能力，定义 Vibe 人格 | 始终加载 |
| **Professional Skill** | 专业领域能力（bazi/zodiac） | 按需加载 |

### 三层加载机制

| 层级 | 加载时机 | Token 消耗 | 内容 |
|------|---------|-----------|------|
| L1: Metadata | 启动时 | ~50 tokens/Skill | YAML frontmatter |
| L2: Instructions | 激活时 | < 3000 tokens | SKILL.md 主体 |
| L3: Resources | 按需 | 可变 | 辅助文件 |

---

## Agent 系统

### CoreAgent

主 Agent，负责对话处理和 Skill 协调。

```python
from services.agent import CoreAgent, AgentContext

agent = CoreAgent(max_iterations=10)

context = AgentContext(
    user_id="user-123",
    user_tier="pro",
    profile={...},
    skill_data={...},
    history=[...]
)

async for event in agent.run(message, context):
    handle_event(event)
```

### AgentContext

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | str | 用户 ID |
| `user_tier` | str | 用户等级 (free/pro/vip) |
| `profile` | dict | 用户画像 |
| `skill_data` | dict | Skill 相关数据 |
| `history` | list | 对话历史 |

### AgentEvent

| 类型 | 说明 | 数据 |
|------|------|------|
| `thinking` | 思考中 | `{iteration: int}` |
| `content` | 文本内容 | `{content: str}` |
| `tool_call` | 工具调用 | `{id, name, arguments}` |
| `tool_result` | 工具结果 | `{id, name, result}` |
| `done` | 完成 | `{content: str}` |
| `error` | 错误 | `{error: str}` |

### Agent 循环

```
构建消息 → 调用 LLM → 检查响应
                         ↓
              有 Tool Call? ─Yes→ 执行工具 → 回到构建消息
                         │
                        No
                         ↓
                    返回结果
```

---

## 知识提炼系统

### 核心算法

从知识库自动提炼 Skill 的方法论和流程：

```
知识库 MD 文件 → 逐文件提取流程性问答对 → 汇总合并去重 → 生成 SKILL.md
```

### 问答对类别

| 类别 | 说明 | 示例 |
|------|------|------|
| `analysis_flow` | 分析流程 | "如何判断日主强弱？" |
| `judgment_rule` | 判断规则 | "什么情况下印星为用神？" |
| `dialogue_strategy` | 对话策略 | "用户问运势时如何回应？" |
| `expression_norm` | 表达规范 | "如何用通俗语言解释？" |

### 关键设计

- **只提取流程性知识**：分析步骤、判断规则、对话策略、表达规范
- **具体知识点留给 RAG**：不重复存储，运行时检索
- **LLM 驱动**：利用大模型理解和提炼能力

---

## CLI 工具

### skill_creator.py

统一的 Skill 管理工具。

```bash
cd /home/aiscend/work/vibelife/apps/api

# 创建新 Skill
python scripts/skill_creator.py create tarot
python scripts/skill_creator.py create tarot --display-name "塔罗牌"

# 验证 Skill
python scripts/skill_creator.py validate bazi

# 列出所有 Skills
python scripts/skill_creator.py list

# 从知识库提炼 Skill
python scripts/skill_creator.py distill bazi --knowledge-dir /path/to/knowledge
python scripts/skill_creator.py distill bazi --preview  # 预览模式

# 热重载 Skill
python scripts/skill_creator.py reload bazi    # 重载单个
python scripts/skill_creator.py reload         # 重载所有
```

### 命令详解

#### create - 创建新 Skill

```bash
python scripts/skill_creator.py create <name> [--display-name NAME] [--description DESC]
```

#### validate - 验证 Skill

```bash
python scripts/skill_creator.py validate <name>
```

检查项：
- SKILL.md 文件存在
- frontmatter 包含 name 和 description
- 内容不为空
- 建议章节存在

#### distill - 从知识库提炼

```bash
python scripts/skill_creator.py distill <name> \
  --knowledge-dir /path/to/knowledge \
  [--preview] \
  [--no-merge] \
  [--no-reload]
```

参数：
- `--knowledge-dir, -k`: 知识库目录
- `--preview`: 预览模式（不生成文件）
- `--no-merge`: 不合并去重问答对
- `--no-reload`: 不自动重载

#### reload - 热重载

```bash
python scripts/skill_creator.py reload [name]
```

- 指定 name：重载单个 Skill
- 不指定：重载所有 Skills

---

## API 参考

### SkillLoader

```python
from services.agent import (
    load_skill,
    build_system_prompt,
    get_available_skills,
    reload_skill,
    reload_all_skills
)

# 加载单个 Skill
skill = load_skill("bazi")
skill.name         # "bazi"
skill.description  # "八字命理分析专家..."
skill.content      # Markdown 内容

# 构建 System Prompt
prompt = build_system_prompt(
    active_skills=["bazi"],
    include_core=True
)

# 获取所有可用 Skill
skills = get_available_skills()  # ["core", "bazi", "zodiac"]

# 热重载
reload_skill("bazi")      # 重载单个
reload_all_skills()       # 重载所有
```

### SkillDistiller

```python
from services.skill_distill import SkillDistiller, DistillConfig

config = DistillConfig(
    skill_name="bazi",
    skill_description="八字命理分析专家",
    knowledge_dir=Path("/path/to/knowledge"),
    merge_qa=True
)

distiller = SkillDistiller()

# 完整提炼
result = await distiller.distill(config)
print(f"提取了 {result.total_qa_pairs} 个问答对")

# 预览模式
qa_pairs = await distiller.preview(config)
```

### 工具系统

```python
from services.vibe_engine.tools import get_tools_for_skill

# 获取 Skill 可用工具
tools = get_tools_for_skill("bazi")
# 返回: [show_bazi_chart, show_bazi_fortune, show_report, ...]
```

### API 端点

| 端点 | 说明 |
|------|------|
| `POST /chat/v5/stream` | V5 CoreAgent 对话（SSE） |
| `POST /chat/v5/guest/stream` | 访客对话 |

---

## 最佳实践

### SKILL.md 编写指南

1. **清晰的能力边界**
   - 明确说明能做什么、不能做什么
   - 列出禁止事项

2. **具体的分析原则**
   - 提供可操作的指导
   - 包含示例

3. **适当的表达方式**
   - 定义语言风格
   - 避免术语堆砌

4. **工具使用说明**
   - 说明何时使用哪个工具
   - 提供调用示例

### 知识提炼最佳实践

1. **知识库准备**
   - 确保 MD 文件格式规范
   - 内容应包含方法论和流程

2. **先预览后提炼**
   ```bash
   python scripts/skill_creator.py distill bazi --preview
   ```

3. **迭代优化**
   - 检查生成的 SKILL.md
   - 手动调整后重新验证

### 热重载使用场景

- 开发调试时快速测试修改
- 知识提炼后自动生效
- 灰度发布切换版本

---

## 文件清单

### 核心代码

| 文件 | 说明 |
|------|------|
| `services/agent/skill_loader.py` | Skill 加载器 |
| `services/agent/core.py` | CoreAgent 实现 |
| `services/skill_distill/` | 知识提炼系统 |
| `scripts/skill_creator.py` | CLI 工具 |

### Skill 文件

| 文件 | 说明 |
|------|------|
| `skills/core/SKILL.md` | Core Skill |
| `skills/bazi/SKILL.md` | 八字 Skill |
| `skills/zodiac/SKILL.md` | 星座 Skill |

### 文档

| 文件 | 说明 |
|------|------|
| `docs/archive/v5/VIBELIFE_AGENT_SKILL_SYSTEM.md` | 本文档 |

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 5.0 | 2025-01 | 初始版本：SKILL.md 格式、知识提炼、热重载 |
