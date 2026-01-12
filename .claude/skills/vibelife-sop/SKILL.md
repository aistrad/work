---
name: vibelife-sop
description: VibeLife SOP - Expert Factory 专家系统构建工具。从知识库自动提取 Methods/Workflows/Rules，生成领域专家 Skill。
---

# VibeLife SOP - Expert Factory

## 0. 概述

从知识库一键生成领域专家系统。采用迭代式提取：初步提取 → 自我评估 → 改进提取。

**核心目标**：提取大模型不知道的深度 Knowhow（Methods/Workflows/Rules）

## 1. 目录规范

```
知识库: /data/vibelife/knowledge/{skill}/converted/
输出:   /home/aiscend/work/vibelife/apps/api/skills/{skill}/
```

---

# Workflows

## Workflow 0：完整构建（默认）

**命令**：
```bash
/vibelife-sop build bazi
/vibelife-sop build zodiac
```

**步骤**：
1. 生成专家 Meta（role, backstory, core_methodology）
2. 逐文件提取 Methods/Workflows/Rules（2轮迭代）
3. 合并结果并生成 Skill 文件

**执行**：
```bash
cd /home/aiscend/work/vibelife/apps/api
python scripts/skill_creator.py build {skill} -k /data/vibelife/knowledge/{skill}/converted
```

## Workflow 1：单文件测试

**命令**：
```bash
/vibelife-sop test zodiac "Trust_Your_Timing"
```

**执行**：
```python
import asyncio
from pathlib import Path
from services.skill_distill.pattern_extractor import PatternExtractor
from services.skill_distill.prompt_optimizer import PromptOptimizer

async def test_single_file(skill_name, file_pattern):
    optimizer = PromptOptimizer()
    knowledge_dir = Path(f'/data/vibelife/knowledge/{skill_name}/converted')

    optimized = await optimizer.optimize(
        skill_name=skill_name,
        knowledge_dir=knowledge_dir,
        goal='根据命盘进行性格分析、运势预测和人生指导'
    )
    meta = {
        'role': optimized.meta.role,
        'backstory': optimized.meta.backstory,
        'core_methodology': optimized.meta.core_methodology,
        'domain_examples': '',
        'domain': skill_name
    }

    extractor = PatternExtractor()
    files = list(knowledge_dir.glob(f'*{file_pattern}*'))
    if files:
        result = await extractor.extract_from_file(files[0], meta, iterations=2)
        print(f'Methods: {len(result.methods)}')
        print(f'Workflow Steps: {len(result.workflow_steps)}')
        print(f'Rules: {len(result.rules)}')
        for r in result.rules[:5]:
            print(f'  - IF {r.condition} THEN {r.conclusion}')

asyncio.run(test_single_file('{skill_name}', '{file_pattern}'))
```

## Workflow 2：查看已有 Skill

**命令**：
```bash
/vibelife-sop list
```

**执行**：
```bash
ls -la /home/aiscend/work/vibelife/apps/api/skills/
```

## Workflow 3：查看提取结果

**命令**：
```bash
/vibelife-sop show bazi rules
/vibelife-sop show bazi methods
```

**执行**：
```bash
cat /home/aiscend/work/vibelife/apps/api/skills/{skill}/rules/rules.yaml
cat /home/aiscend/work/vibelife/apps/api/skills/{skill}/methods/*.yaml
```

---

# 迭代式提取流程

```
┌─────────────────────────────────────────────────────────────┐
│                    Iterative Extraction                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Round 1: 初步提取（通用 Prompt）                            │
│       │                                                     │
│       ▼                                                     │
│  Round 2: 自我评估                                          │
│       │  - 哪些是深度 knowhow？                             │
│       │  - 哪些是常识？（应删除）                           │
│       │  - 哪些有错误？                                     │
│       ▼                                                     │
│  Round 3: 改进提取                                          │
│       │  - 删除常识                                         │
│       │  - 修正错误                                         │
│       │  - 补充遗漏                                         │
│       ▼                                                     │
│  (重复迭代 2 轮)                                            │
│       │                                                     │
│       ▼                                                     │
│  最终结果                                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# 输出结构

```
skills/{skill}/
├── SKILL.md              # 主 Skill 文件
├── meta.json             # 元信息
├── optimized_prompt.json # Prompt 优化结果
├── methods/              # 方法论
│   └── *.yaml
├── workflows/            # SOP 流程
│   └── main_flow.yaml
└── rules/                # 判断规则
    └── rules.yaml
```

---

# 深度 Knowhow 标准

**要提取的**：
- 大模型不知道的专业经验
- 具体的判断标准和阈值
- 反直觉的洞察
- 实战中的"坑"和技巧

**不要提取的**：
- 概念定义、通用流程
- 教科书知识
- 大模型已知的常识（如五行生克）

---

# Changelog

## 2026-01-12
- 创建 vibelife-sop skill
- 支持迭代式提取（2轮）
- 支持 bazi、zodiac、mbti 等领域
