# Skill 目录结构设计 v6

> 基于 VibeLife-Expert-System-v2.md 设计文档

## 目录结构

```
skills/{skill}/
├── SKILL.md              # 核心定义（人格+核心SOP+工具规则）- 始终加载
├── extended.json         # 扩展知识（扩展SOP+规则+模式）- 按需匹配
├── cases.json            # 案例库 - 按需匹配
├── tools/
│   └── tools.yaml        # 本技能的专属工具定义
└── meta.json             # 元数据
```

## 文件职责

| 文件 | 加载时机 | 内容特点 |
|-----|---------|---------|
| SKILL.md | 始终加载到 System Prompt | 精华、核心、必须掌握 |
| extended.json | 运行时按关键词匹配 | 完整、详细、按需检索 |
| cases.json | 运行时按关键词匹配 | 具体案例、模式匹配 |
| tools/tools.yaml | Skill 激活时加载 | 工具定义、前端卡片映射 |
| meta.json | 系统启动时加载 | 统计信息、版本、配置 |

## SKILL.md 结构

```markdown
---
name: string              # 技能ID
display_name: string      # 显示名称
description: string       # 一句话描述
triggers: string[]        # 触发关键词
requires_birth_info: bool # 是否需要出生信息
auto_collect: bool        # 激活后是否自动收集信息
---

# {SKILL_NAME} Skill

## 专家身份
{一段话定义专家人格}

## 核心SOP

### 分析流程
1. ...
2. ...

### 核心模式（5-10个）
| 模式 | 特征 | 初步判断 |
|-----|------|---------|

### 核心规则（10-20条）
| 条件 | 结论 | 置信度 |
|-----|------|-------|

## 工具调用规则
| 用户意图 | 必须调用的工具 |
|---------|--------------|

## 禁止行为
- ...
```

## extended.json 结构

```json
{
  "version": "1.0",
  "last_updated": "2026-01-13",

  "extended_sop": {
    "phases": [
      {
        "id": "P1",
        "name": "信息收集",
        "steps": [],
        "decision_points": []
      }
    ]
  },

  "patterns": {
    "quick_patterns": [
      {
        "id": "QP_001",
        "name": "模式名称",
        "signature": "识别特征",
        "indication": "初步判断",
        "confidence": "high|medium|low",
        "keywords": ["关键词1", "关键词2"]
      }
    ],
    "red_flags": [
      {
        "id": "RF_001",
        "signal": "信号描述",
        "severity": "critical|warning|notice",
        "action": "应采取的行动",
        "keywords": ["关键词"]
      }
    ]
  },

  "rules": {
    "tier1_must_know": [
      {
        "id": "T1_001",
        "condition": "条件",
        "action": "行动",
        "priority": "critical",
        "source": "来源",
        "keywords": ["关键词"]
      }
    ],
    "tier2_core": [],
    "tier3_edge": []
  }
}
```

## cases.json 结构

```json
{
  "version": "1.0",
  "last_updated": "2026-01-13",

  "archetypes": [
    {
      "id": "CASE_001",
      "name": "案例名称",
      "category": "分类",
      "key_features": ["特征1", "特征2"],
      "keywords": ["关键词"],
      "input": {},
      "analysis": {
        "observations": [],
        "applied_rules": [],
        "reasoning": "推理过程"
      },
      "conclusion": {
        "main_point": "主要结论",
        "confidence": "high|medium|low"
      },
      "source": "来源"
    }
  ],

  "edge_cases": []
}
```

## tools/tools.yaml 结构

```yaml
version: "1.0"

# 收集型工具
collect:
  - name: collect_{skill}_info
    description: 收集用户信息
    card_type: "{skill}_form"
    card_props:
      form_fields:
        - name: field_name
          type: date|time|location|text|select
          required: true
          label: 显示标签
      allow_text_input: true
    parameters:
      - name: param_name
        type: string
        required: false
        description: 参数描述

# 计算型工具
compute:
  - name: calculate_{skill}
    description: 计算...
    implementation: "{module}.{function}"
    parameters: []
    returns:
      type: object
      description: 返回值描述

# 展示型工具
display:
  - name: show_{skill}_chart
    description: 展示图表
    card_type: "{skill}_chart"
    when_to_call: "用户想看图表时"
    parameters: []

  - name: show_{skill}_report
    description: 展示报告
    card_type: "{skill}_report"
    when_to_call: "分析完成时"

  - name: show_{skill}_insight
    description: 展示洞察卡片
    card_type: "{skill}_insight"
    when_to_call: "需要突出关键洞察时"

# 检索型工具（CoreAgent 级，所有 Skill 共享）
# search_knowledge 定义在 core/tools/tools.yaml
```

## meta.json 结构

```json
{
  "skill_id": "bazi",
  "version": "1.0.0",
  "created_at": "2026-01-13",
  "last_updated": "2026-01-13",

  "stats": {
    "core_rules_count": 15,
    "extended_rules_count": 80,
    "patterns_count": 20,
    "cases_count": 30
  },

  "rag": {
    "enabled": true,
    "namespace": "bazi",
    "document_count": 10,
    "chunk_count": 500
  },

  "sop": {
    "phases": ["collect", "compute", "scan", "analyze", "output", "discuss"],
    "forced_phases": ["collect", "compute"]
  }
}
```

## 迁移映射

| 旧文件 | 新位置 |
|-------|-------|
| methods/*.yaml | extended.json → extended_sop.phases |
| rules/rules.yaml | extended.json → rules.tier1/tier2/tier3 |
| workflows/main_flow.yaml | SKILL.md → 核心SOP |
| meta.json | meta.json (保留) |
| SKILL.md | SKILL.md (精简) |

## 关键词匹配算法

```python
def match_knowledge(query: str, skill_id: str) -> dict:
    """
    从 extended.json 和 cases.json 中匹配相关知识

    算法：
    1. 分词：jieba 分词提取关键词
    2. 匹配：遍历 rules/patterns/cases 的 keywords 字段
    3. 排序：按匹配数量排序
    4. 返回：Top N 条规则 + Top M 个案例
    """
    pass
```
