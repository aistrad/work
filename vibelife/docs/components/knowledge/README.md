# Knowledge Base v2

> 从原文抽取 Cases，存入数据库，倒排索引 + Context Build

## 核心概念

**Cases**：从原文 LLM 抽取的结构化案例，存储在数据库中，用于相似案例参考

## 数据模型

### Case（数据库表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 案例 ID，如 `case_bazi_001` |
| skill_id | string | 所属 Skill |
| name | string | 案例名称 |
| tags | string[] | 特征标签（用于匹配） |
| rule_ids | string[] | 关联的规则 ID |
| content | text | 案例正文（Markdown） |

## 目录结构

```
skills/{skill}/
├── SKILL.md
└── rules/          # 人工定义（已有）
```

> Cases 不存文件，只存数据库

## 工作流程

```
用户命盘 {daymaster: "戊土", strength: "身强"}
    │
    ▼
Case 倒排索引: "戊土" + "身强" → [case_001]
    │
    ▼
从数据库加载 case_001 → 注入 System Prompt
```

## 构建命令

```bash
# Stage 0: 格式转换
python scripts/build_knowledge.py --skill bazi --stages 0

# Stage 1: 抽取 Cases → 存入数据库
python scripts/build_knowledge.py --skill bazi --stages 1
```

## 文档

- [DESIGN.md](./DESIGN.md) - 详细设计
