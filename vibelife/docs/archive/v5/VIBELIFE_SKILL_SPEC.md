# VibeLife Agent/Skill 规范 v5.0

## 概述

VibeLife Skill 系统是一个模块化的能力扩展框架，允许通过 Markdown 文件定义专业领域的对话能力。本规范定义了 Skill 的结构、加载机制和最佳实践。

## 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        CoreAgent                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SkillLoader                           │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │  Core   │  │  Bazi   │  │ Zodiac  │  │  ...    │    │   │
│  │  │ SKILL.md│  │ SKILL.md│  │ SKILL.md│  │ SKILL.md│    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   System Prompt                          │   │
│  │  Core Skill + Active Skill(s) + User Profile            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Tools                               │   │
│  │  Shared Tools + Skill-specific Tools                    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 目录结构

```
apps/api/skills/
├── README.md                 # 架构文档
├── core/                     # Core Skill（始终加载）
│   ├── SKILL.md             # 主指令
│   ├── DIALOGUE.md          # 对话技术库
│   └── CRISIS.md            # 危机处理指南
├── bazi/                     # 八字 Skill
│   ├── SKILL.md             # 主指令
│   ├── PATTERNS.md          # 格局解读（可选）
│   └── TERMS.md             # 术语表（可选）
├── zodiac/                   # 星座 Skill
│   ├── SKILL.md             # 主指令
│   └── ASPECTS.md           # 相位解读（可选）
└── {new-skill}/              # 新 Skill
    └── SKILL.md             # 主指令（必需）
```

## SKILL.md 文件格式

### 必需结构

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

### 原则 2
说明...

## 表达方式

- 语言风格指南
- 禁止事项

## 可用工具

- `tool_name_1` - 工具描述
- `tool_name_2` - 工具描述
```

### Frontmatter 字段

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `name` | ✅ | string | Skill 唯一标识符，小写字母+连字符，最多 32 字符 |
| `description` | ✅ | string | 技能描述，最多 512 字符，用于 LLM 选择 |
| `version` | ❌ | string | 版本号，如 "1.0.0" |
| `author` | ❌ | string | 作者 |
| `requires` | ❌ | array | 依赖的其他 Skill |
| `tools` | ❌ | array | 声明使用的工具列表 |

### 命名规范

- `name`: 小写字母、数字、连字符，如 `bazi`, `zodiac`, `tarot-reading`
- 不允许：空格、下划线、大写字母��特殊字符
- 保留名称：`core`, `system`, `admin`

## Skill 类型

### 1. Core Skill（核心技能）

始终加载，提供基础对话能力。

```yaml
---
name: core
description: |
  生命对话者。提供深度倾听、情绪感知、模式识别能力。
  始终激活，与专业 Skill 叠加使用。
---
```

特点：
- 位于 `skills/core/` 目录
- 自动加载，无需选择
- 定义 Vibe 的人格和对话原则
- 可包含辅助文件（DIALOGUE.md, CRISIS.md）

### 2. Professional Skill（专业技能）

按需加载，提供领域专业能力。

```yaml
---
name: bazi
description: |
  八字命理分析专家。提供命盘排盘、日主分析、十神解读。
  当用户询问八字、命盘、运势等话题时使用。
---
```

特点：
- 位于 `skills/{skill-name}/` 目录
- 通过 `use_skill` 工具激活
- 定义专业分析方法和工具
- 可与 Core Skill 叠加

## 加载机制

### 三层加载

| 层级 | 加载��机 | Token 消耗 | 内容 |
|------|---------|-----------|------|
| L1: Metadata | 启动时 | ~50 tokens/Skill | YAML frontmatter |
| L2: Instructions | 激活时 | < 3000 tokens | SKILL.md 主体 |
| L3: Resources | 按需 | 可变 | 辅助文件 |

### 加载流程

```python
# 1. 启动时加载所有 Skill 元数据
skills = get_available_skills()  # ["core", "bazi", "zodiac"]

# 2. 构建初始 System Prompt（仅 Core）
prompt = build_system_prompt([], include_core=True)

# 3. LLM 选择 Skill
use_skill(skills=["bazi"], topic="career")

# 4. 动态加载选中的 Skill
prompt = build_system_prompt(["bazi"], include_core=True)
```

## 工具系统

### 工具类型

| 类型 | 说明 | 示例 |
|------|------|------|
| Shared | 所有 Skill 可用 | `show_report`, `show_insight` |
| Skill-specific | 特定 Skill 专用 | `show_bazi_chart`, `show_zodiac_chart` |
| System | 系统内部使用 | `use_skill`, `search_knowledge` |

### 工具定义格式

```python
TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "show_bazi_chart",
        "description": "展示用户的八字命盘，包括四柱、日主、五行分布",
        "parameters": {
            "type": "object",
            "properties": {
                "user_id": {
                    "type": "string",
                    "description": "用户 ID"
                },
                "show_details": {
                    "type": "boolean",
                    "description": "是否显示详细信息",
                    "default": True
                }
            },
            "required": ["user_id"]
        }
    }
}
```

### 在 SKILL.md 中声明工具

```markdown
## 可用工具

当需要展示命盘或运势时，使用以下工具：

- `show_bazi_chart` - 展示八字命盘（四柱、日主、五行）
- `show_bazi_fortune` - 展示大运流年
- `show_bazi_kline` - 展示运势曲线
- `search_knowledge` - 检索八字知识库
```

## RAG 集成

### 知识库结构

每个 Skill 可以有独立的知识库：

```
knowledge/
├── bazi/
│   ├── patterns/      # 格局知识
│   ├── ten_gods/      # 十神知识
│   └── elements/      # 五行知识
└── zodiac/
    ├── planets/       # 行星知识
    ├── signs/         # 星座知识
    └── aspects/       # 相位知识
```

### 在 SKILL.md 中使用 RAG

```markdown
## 知识检索

当需要专业知识支撑时，调用 `search_knowledge` 工具：

```
search_knowledge(query="日主为甲木的��格特点", skill_id="bazi")
```

检索结果会以 `<knowledge>` 标签包装，供你参考。
```

## 计算服务集成

### Calculator 接口

每个需要计算的 Skill 应有对应的 Calculator：

```python
# services/bazi/bazi_calculator.py
class BaziCalculator:
    async def calculate(self, birth_date, birth_time, gender) -> BaziChart:
        """计算八字命盘"""
        pass

# services/zodiac/zodiac_calculator.py
class ZodiacCalculator:
    async def calculate(self, birth_date, birth_time, birth_place) -> ZodiacChart:
        """计算星盘"""
        pass
```

### 在 SKILL.md 中说明数据来源

```markdown
## 数据来源

用户的命盘数据已预先计算并存储在 Profile 中。
你可以直接引用以下数据：

- `profile.bazi_chart` - 八字命盘
- `profile.bazi_chart.day_master` - 日主
- `profile.bazi_chart.pattern` - 格局
```

## 前端集成

### Generative UI 工具

每个 UI 工具需要前端实现：

```typescript
// apps/web/src/skills/bazi/tools/show-bazi-chart.tsx
export const showBaziChartTool: ToolDefinition = {
  name: "show_bazi_chart",

  // 执行逻辑
  async execute(params, context) {
    return fetch(`/api/v1/users/${params.userId}/bazi-chart`);
  },

  // 渲染组件
  render(result) {
    return <BaziChartCard data={result} />;
  },

  // 返回给 LLM 的摘要
  toModelOutput(result) {
    return `已展示八字命盘。日主: ${result.dayMaster}`;
  }
};
```

### Skill 配置

```typescript
// apps/web/src/skills/bazi/config.ts
export const baziConfig: SkillConfig = {
  id: "bazi",
  name: "八字命理",
  icon: Compass,
  theme: { primary: "#B8860B" },

  inputForm: {
    fields: [
      { id: "birthDate", type: "date", required: true },
      { id: "birthTime", type: "time" },
      { id: "gender", type: "select" }
    ]
  },

  quickPrompts: [
    "帮我看看我的八字",
    "我最近运势怎么样"
  ]
};
```

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

### 示例：好的 SKILL.md

```markdown
---
name: bazi
description: |
  八字命理分析专家。提供命盘排盘、日主分析、十神解读。
  当用户询问八字、命盘、运势、大运、流年等话题时使用。
---

# Bazi Skill - 八字命理分析

## 能力范围

- 八字命盘排盘与解读
- 日主分析与五行平衡
- 十神关系解读
- 大运流年分析

## 分析原则

### 以日主为核心

日主是命盘的"我"，所有分析围绕日主展开。

### 五行平衡

分析五行分布，找出过旺或过弱的元素。

## 表达方式

- 用通俗易懂的语言解释命理概念
- 结合用户的实际生活情境
- 避免绝对化表述

## 禁止事项

- 不预测具体事件发生的精确时间
- 不做负面恐吓式预测
- 不评判命盘的"好坏"

## 可用工具

- `show_bazi_chart` - 展示八字命盘
- `show_bazi_fortune` - 展示大运流年
```

## API 参考

### SkillLoader API

```python
from services.agent import load_skill, build_system_prompt, get_available_skills

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
```

### CoreAgent API

```python
from services.agent import CoreAgent, AgentContext

agent = CoreAgent()

context = AgentContext(
    user_id="user-123",
    user_tier="pro",
    profile={"bazi_chart": {...}},
    skill_data={"current_fortune": {...}}
)

async for event in agent.run("帮我看看我的八字", context):
    if event.type == "content":
        print(event.data["content"])
    elif event.type == "tool_call":
        print(f"调用工具: {event.data['name']}")
```

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 5.0 | 2025-01 | 初始版本，SKILL.md 格式 |
