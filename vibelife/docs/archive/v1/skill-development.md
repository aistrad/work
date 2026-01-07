# VibeLife Skill 开发指南

本文档介绍如何为 VibeLife 开发新的 Skill。

## Skill 架构概述

每个 Skill 包含以下组件：

```
packages/skills/{skill_name}/
├── SKILL.md            # Skill 定义文档
├── site_config.yaml    # 站点配置
├── scripts/            # 专业计算脚本
├── references/         # 参考知识文档
└── assets/             # 资源文件
```

---

## SKILL.md 规范

`SKILL.md` 是 Skill 的核心定义文件：

```markdown
# Skill: {skill_name}

## Meta
- id: skill_name
- name: 技能显示名称
- description: 一句话描述
- version: 1.0.0
- author: your-name

## Persona
角色设定和语气指南...

## Intents
支持的意图列表...

## Tools
可用的工具函数...

## Knowledge
相关知识库...

## Workflows
工作流定义...

## Insight Rules
洞察触发规则...
```

### 完整示例

```markdown
# Skill: Bazi (八字命理)

## Meta
- id: bazi
- name: 八字命理
- description: 基于中国传统命理学的个人洞察工具
- version: 1.0.0
- tags: [命理, 运势, 中国传统文化]

## Persona

### 身份
你是一位温暖的命理顾问，拥有深厚的八字知识，但不会刻板地讲述理论，而是用生活化的语言帮助用户理解自己。

### 语气
- 温暖、亲切、有分寸
- 用"看见"替代"分析"
- 用"发现"替代"诊断"
- 用"也许"替代"一定"

### 禁忌
- 不做绝对性预测
- 不涉及寿命、健康等敏感话题
- 不强化宿命论

## Intents

### chart_reading
触发词: 排盘, 八字, 命盘, 看看我的八字
所需信息: birth_datetime, birth_location (可选), gender
响应: 生成并解读用户八字命盘

### transit_analysis
触发词: 今年运势, 明年, 大运, 流年
所需信息: target_period
响应: 分析指定时期的运势

### pattern_analysis
触发词: 格局, 十神, 五行
所需信息: 无额外信息
响应: 深度分析命盘格局

## Tools

### bazi.calculator.generate_chart
描述: 根据出生时间生成八字命盘
参数:
  - birth_datetime: datetime
  - birth_location: string (optional)
  - gender: enum[male, female]
返回: BaziChart object

### bazi.transit.calculate_dayun
描述: 计算大运
参数:
  - chart: BaziChart
返回: DayunList

### bazi.analysis.analyze_ten_gods
描述: 分析十神配置
参数:
  - chart: BaziChart
返回: TenGodsAnalysis

## Knowledge

### 核心知识
- theory/天干地支.md
- theory/五行生克.md
- theory/十神详解.md

### 格局知识
- patterns/正官格.md
- patterns/偏财格.md
- ...

### 案例库
- cases/事业案例.md
- cases/感情案例.md

## Insight Rules

### 格局发现 (discovery)
条件:
  - 用户首次排盘
  - 命盘有明显特征
触发: 生成 DISCOVERY 卡片
内容: "我看见你的命盘中..."

### 运势时机 (timing)
条件:
  - 当前时间接近重要节点
  - 用户有相关对话
触发: 生成 TIMING 卡片
内容: "现在是...的好时机"
```

---

## 工具函数开发

### 目录结构

```
apps/api/tools/{skill_name}/
├── __init__.py
├── calculator.py    # 核心计算
├── transit.py       # 行运计算
└── analysis.py      # 分析功能
```

### 函数规范

```python
"""
工具函数模块
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class ChartResult(BaseModel):
    """返回结果模型"""
    year: dict
    month: dict
    day: dict
    hour: dict
    day_master: str


def generate_chart(
    birth_datetime: datetime,
    birth_location: Optional[str] = None,
    gender: str = "male"
) -> ChartResult:
    """
    生成八字命盘

    Args:
        birth_datetime: 出生时间 (含时区)
        birth_location: 出生地点 (用于时区校正)
        gender: 性别 (影响大运方向)

    Returns:
        ChartResult: 命盘数据

    Raises:
        ValueError: 参数无效
    """
    # 实现逻辑...
    pass
```

### 注册工具

在 `tools/__init__.py` 中注册：

```python
from .bazi import calculator, transit, analysis

SKILL_TOOLS = {
    "bazi": {
        "calculator": calculator,
        "transit": transit,
        "analysis": analysis,
    }
}
```

---

## 知识库构建

### 文档格式

使用 Markdown 格式，支持：

```markdown
---
skill: bazi
category: theory
title: 天干地支详解
tags: [基础, 天干, 地支]
---

# 天干地支

## 概述
天干地支是中国古代的计时系统...

## 十天干
甲、乙、丙、丁、戊、己、庚、辛、壬、癸

### 甲木
- 五行: 木
- 阴阳: 阳
- 特性: 参天大树，正直向上
- 代表: 领导力、开创性

## QA
Q: 天干和地支有什么区别？
A: 天干代表天的能量，地支代表地的能量...
```

### 向量化流程

1. 文档预处理
2. 语义分块 (Semantic Chunking)
3. 生成 Embedding (Gemini)
4. 存储到 pgvector / Pinecone

```python
# 知识处理示例
from services.knowledge.embedding import EmbeddingService

service = EmbeddingService()

# 处理单个文档
await service.process_document(
    skill_id="bazi",
    file_path="knowledge/bazi/theory/天干地支.md"
)

# 批量处理
await service.process_directory(
    skill_id="bazi",
    directory="knowledge/bazi/"
)
```

---

## 站点配置

`site_config.yaml` 定义站点外观和行为：

```yaml
site:
  id: bazi
  name: 八字命理
  domain: bazi.vibelife.app
  tagline: "看见命运的纹理"

theme:
  primary_color: "#8B4513"    # 棕色
  secondary_color: "#DAA520"  # 金色
  background: "linear-gradient(135deg, #2D1B0E 0%, #4A3728 100%)"
  font_style: "traditional"

landing:
  hero:
    title: "你的命运密码"
    subtitle: "八字命理，看见生命的纹理"
    cta: "免费查看命盘"

  input_form:
    fields:
      - type: date
        name: birth_date
        label: 出生日期
        required: true
      - type: time
        name: birth_time
        label: 出生时辰
        required: true
      - type: select
        name: gender
        label: 性别
        options: [男, 女]

monetization:
  free_tier:
    features:
      - 1次完整命盘解读
      - 每天3次提问
      - 基础运势
    paywall_triggers:
      - deep_pattern_analysis
      - detailed_transit

  premium_tier:
    price_monthly: 29
    price_yearly: 199
    features:
      - 无限对话
      - 深度十神分析
      - 月运推送

seo:
  title: "八字命理 - VibeLife"
  description: "AI 八字命理分析，看见你的命运纹理"
  keywords: [八字, 命理, 运势, 算命]
```

---

## 最佳实践

### 1. Persona 设计
- 保持一致的人格特征
- 语气温暖但专业
- 避免绝对化表述

### 2. 工具函数
- 单一职责原则
- 完善的类型注解
- 详细的文档字符串
- 充分的错误处理

### 3. 知识库
- 结构化组织内容
- 提供丰富的 QA 对
- 定期更新和校验

### 4. 洞察规则
- 设置合理的触发阈值
- 避免过度推送
- 确保高质量内容

---

## 测试

```bash
# 运行 Skill 测试
cd apps/api
pytest tests/test_{skill_name}*.py -v

# 测试工具函数
pytest tests/test_{skill_name}_tools.py

# 测试知识检索
pytest tests/test_{skill_name}_knowledge.py
```
