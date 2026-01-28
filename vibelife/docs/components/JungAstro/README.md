# JungAstro Skill 设计文档

## 概述

基于《The Complete Beginner's Guide to Jungian Astrology》和 VibeLife Skill 规范，构建一个**独立的**荣格心理占星 Skill。

**核心定位**: 荣格心理占星分析师 - 将占星作为心理自我认知工具，而非命运预测。

## 设计决策

| 决策点 | 选择 |
|-------|------|
| 与 zodiac 关系 | **独立 Skill**，与 zodiac 并列 |
| 与 vibe_id 关系 | **保持独立**，不替代 vibe_id |
| 前端卡片 | **新建专属卡片** |
| 知识库 | **构建完整知识库** |

## 文档索引

| 文档 | 内容 |
|-----|------|
| [FRAMEWORK.md](./FRAMEWORK.md) | 四层心理模型框架 |
| [SKILL.md](./SKILL.md) | Skill 定义文件 |
| [TOOLS.md](./TOOLS.md) | 工具定义 |
| [RULES.md](./RULES.md) | 分析规则 |
| [CARDS.md](./CARDS.md) | 前端卡片设计 |
| [KNOWLEDGE.md](./KNOWLEDGE.md) | 知识库构建计划 |
| [IMPLEMENTATION.md](./IMPLEMENTATION.md) | 实施步骤 |

## 与其他 Skill 的协作

```
用户: "帮我分析一下"
     ↓
Core Skill 判断意图
     ↓
┌─────────────────────────────────────────┐
│  "看星盘" → zodiac (传统占星)            │
│  "心理分析" → jungastro (荣格心理占星)   │
│  "人格画像" → vibe_id (融合原型)         │
│  "算命" → bazi (八字命理)                │
└─────────────────────────────────────────┘
```

**触发词区分**:
- zodiac: 星座、星盘、运势、行运、水逆
- jungastro: 心理占星、荣格、阴影、个体化、心理功能
- vibe_id: 人格画像、VibeID、原型、四维人格

## 目录结构

```
apps/api/skills/jungastro/
├── SKILL.md                    # Skill 主定义
├── config/
│   ├── planets.yaml            # 行星心理功能定义
│   ├── signs.yaml              # 星座元素-模式定义
│   ├── houses.yaml             # 宫位生命领域定义
│   └── aspects.yaml            # 相位关系定义
├── rules/
│   ├── psychological-portrait.md   # 心理画像分析规则
│   ├── shadow-work.md              # 阴影整合分析规则
│   ├── individuation.md            # 个体化进程分析规则
│   └── relationship-dynamics.md    # 关系动力学规则
├── tools/
│   ├── tools.yaml              # 工具定义
│   └── handlers.py             # 工具执行器
└── services/
    ├── __init__.py
    ├── calculator.py           # 复用 zodiac 计算
    └── interpreter.py          # 荣格心理解读器

apps/web/src/skills/jungastro/
├── cards/
│   ├── PsychologicalPortrait.tsx   # 心理画像卡片
│   ├── ShadowAnalysis.tsx          # 阴影分析卡片
│   ├── IndividuationPath.tsx       # 个体化路径卡片
│   └── PsychologicalFunctions.tsx  # 心理功能分布卡片
├── tools/
│   └── index.ts                # 工具注册
└── panels/
    └── JungAstroPanel.tsx      # 主面板

/data/vibelife/knowledge/jungastro/
├── source/                     # 原始资料 (Liz Greene, Sasportas 等)
├── converted/                  # 转换后的 Markdown
└── extracted/                  # 抽取的案例和场景
```
