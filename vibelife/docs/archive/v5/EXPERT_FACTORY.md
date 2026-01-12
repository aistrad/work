# Expert Factory - 专家系统工厂

> **版本**: 1.0
> **日期**: 2026-01-11
> **目标**: 从知识库一键生成领域专家系统

---

## 1. 概述

Expert Factory 是一个自动化系统，能够从原始知识库（如八字古籍、占星书籍）自动生成完整的领域专家 Skill。

### 核心理念

```
普通专家：知道很多事实（Knowledge）
顶级专家：知道事实 + 方法论（Methodology）+ 判断力（Judgment）+ 流程（Workflow）
```

Expert Factory 自动完成这个"提炼"过程。

---

## 2. 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Expert Factory Pipeline                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  输入: /data/vibelife/knowledge/{skill}/converted/*.md                      │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Stage 1: Prompt Optimization                                        │   │
│  │  - 生成专家身份 (role, backstory)                                    │   │
│  │  - 生成核心方法论 (core_methodology)                                 │   │
│  │  - 生成领域示例 (domain_examples)                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌───────────────────────────────────────���─────────────────────────────┐   │
│  │  Stage 2: Pattern Extraction (逐文件)                                │   │
│  │  - Methods: 分析方法论（如何做某事的步骤）                           │   │
│  │  - Workflows: 流程片段（分析的先后顺序）                             │   │
│  │  - Rules: 判断规则（IF-THEN 形式的经验判断）                         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Stage 3: Merge & Assemble                                           │   │
│  │  - 合并多文件结果                                                    │   │
│  │  - 生成 Skill 目录结构                                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  输出: skills/{skill}/                                                      │
│        ├── SKILL.md                                                        │
│        ├── workflows/main_flow.yaml                                        │
│        ├── methods/*.yaml                                                  │
│        └── rules/rules.yaml                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 知识分类

Expert Factory 将知识分为四类：

| 类型 | 描述 | 存储位置 |
|------|------|---------|
| **Facts** | 客观数据、定义、实体信息 | knowledge_chunks 表（RAG） |
| **Methods** | 如何做某事的系统化方法 | skills/{skill}/methods/*.yaml |
| **Workflows** | 多步骤任务的执行顺序 | skills/{skill}/workflows/main_flow.yaml |
| **Heuristics** | 专家的直觉和判断规则 | skills/{skill}/rules/rules.yaml |

---

## 4. 输出目录结构

```
skills/bazi/
├── SKILL.md                    # 主 Skill（含 SOP 路由）
├── meta.json                   # 元信息
├── optimized_prompt.json       # Prompt 优化结果
├── EXTRACTION_PROMPT.md        # 提取 Prompt
│
├── workflows/                  # SOP 定义
│   └── main_flow.yaml          # 主分析流程
│
├── methods/                    # 方法论
│   ├── 日主分析.yaml
│   ├── 五行分析.yaml
│   └── ...
│
└── rules/                      # 判断规则
    └── rules.yaml
```

---

## 5. 使用方法

### CLI 命令

```bash
# 一键构建专家系统
python scripts/skill_creator.py build bazi

# 指定知识库目录
python scripts/skill_creator.py build bazi -k /data/vibelife/knowledge/bazi/converted

# 指定输出目录
python scripts/skill_creator.py build bazi -o /path/to/output

# 指定目标描述
python scripts/skill_creator.py build bazi -g "根据八字命盘进行性格分析"
```

### Python API

```python
from services.skill_distill.expert_factory import ExpertFactory
from pathlib import Path

factory = ExpertFactory()
result = await factory.build(
    skill_name="bazi",
    knowledge_dir=Path("/data/vibelife/knowledge/bazi/converted"),
    output_dir=Path("skills/bazi"),
    goal="根据八字命盘进行性格分析、运势预测和人生指导"
)

print(f"Methods: {result.methods_extracted}")
print(f"Workflow Steps: {result.workflow_steps}")
print(f"Rules: {result.rules_extracted}")
```

---

## 6. 核心模块

```
services/skill_distill/
├── expert_factory.py           # 工厂主入口
├── prompt_optimizer.py         # Prompt 优化器（生成 Meta）
├── pattern_extractor.py        # 模式提取器（提取 Methods/Workflows/Rules）
└── skill_assembler.py          # Skill 组装器（合并结果并生成文件）
```

### 6.1 PatternExtractor

逐文件提取专家模式：

```python
extractor = PatternExtractor()
result = await extractor.extract_from_file(
    file_path=Path("子平真诠.md"),
    meta={"role": "...", "backstory": "...", ...}
)
# result.methods, result.workflow_steps, result.rules
```

### 6.2 SkillAssembler

合并多文件结果并生成 Skill 文件：

```python
assembler = SkillAssembler()
merged = await assembler.merge_results(results, meta)
await assembler.generate_skill_files(skill_name, merged, meta, output_dir)
```

---

## 7. Prompt 设计

### 7.1 抽取 Prompt（通用模板）

```markdown
你是 {role}。

## 背景
{backstory}

## 核心方法论
{core_methodology}

## 任务：从文档中提取专家级深度 Knowhow

### 什么是深度 Knowhow
- ✅ 大模型不知道的专业经验
- ✅ 具体的判断标准和阈值
- ✅ 反直觉的洞察
- ✅ 实战中的"坑"和技巧
- ❌ 不是：概念定义、通用流程、教科书知识

### 提取三类内容
1. Methods（方法论）
2. Workflows（流程片段）
3. Rules（判断规则）

### 领域特定示例
{domain_examples}

## 文档内容
{document_content}

## 输出格式
{JSON 格式}
```

### 7.2 合并 Prompt（通用模板）

```markdown
你是 {role}。

## 任务：合并多个来源的专家知识

### 合并规则
- Methods: 相似方法合并，保留最完整版本
- Workflows: 合并成统一的主分析流程
- Rules: 去重，冲突规则标注不同来源

### 各来源抽取结果
{all_extraction_results}

## 输出格式
{JSON 格式}
```

---

## 8. 与 RAG 系统的关系

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         两个独立流程                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  知识库源文件 (*.md)                                                         │
│       │                                                                     │
│       ├──────────────────────────────────────────┐                         │
│       │                                          │                         │
│       ▼                                          ▼                         │
│  ┌─────────────────────────┐          ┌─────────────────────────┐         │
│  │  流程 A: RAG 入库        │          │  流程 B: Skill 抽取      │         │
│  │  (已有，独立运行)        │          │  (Expert Factory)       │         │
│  │                         │          │                         │         │
│  │  - BGE-M3 Embedding     │          │  - Opus 深度分析        │         │
│  │  - 分块 + 向量化        │          │  - Methods/Workflows/   │         │
│  │  - 存入 knowledge_chunks│          │    Rules 提取           │         │
│  └─────────────────────────┘          └─────────────────────────┘         │
│       │                                          │                         │
│       ▼                                          ▼                         │
│  knowledge_chunks 表                    skills/{skill}/ 目录               │
│  (Facts - 运行时检索)                   (Methods/Workflows/Rules)          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **RAG 入库**：已有流程，使用 BGE-M3 embedding，存储 Facts
- **Skill 抽取**：Expert Factory，使用 Opus 深度分析，提取 Methods/Workflows/Rules

---

## 9. 默认配置

| 配置项 | 默认值 |
|--------|--------|
| 知识库目录 | `/data/vibelife/knowledge/{skill}/converted/` |
| 输出目录 | `apps/api/skills/{skill}/` |
| 文件模式 | `*.md` |
| 最大内容字符数 | 500,000 (约 150K tokens) |

---

## 10. 示例输出

### main_flow.yaml

```yaml
name: 主分析流程
version: '1.0'
steps:
- order: 1
  name: 确定日主
  description: 根据八字排盘，确定日主，即日柱的天干
  depends_on: null
  source: 渊海子平.md
- order: 2
  name: 分析五行旺衰
  description: 分析八字中金、木、水、火、土五行的旺衰情况
  depends_on: 1
  source: 穷通宝鉴例释录.md
...
```

### rules.yaml

```yaml
rules:
- condition: 日主旺，用神为金或水
  conclusion: 喜金或水
  confidence: high
  sources:
  - 穷通宝鉴例释录.md
- condition: 伤官见官
  conclusion: 为祸百端
  confidence: high
  sources:
  - 渊海子平.md
...
```
