---
id: transit
name: 行运分析
level: standard
billing: basic
description: 分析当前行星行运对本命盘的影响，揭示生命周期中的成长机会
---

# 行运分析

## 触发条件

**主要触发词**: 运势, 行运, 最近运势, 现在的运势

**次要触发词**: 流年, 行星影响, 当前能量, 这段时间

## 前置要求

- 用户出生日期（必须）
- 用户出生时间（必须）
- 出生地点（必须）

## 可组合场景

本场景可引用以下MiniSkill的分析框架：
- basic_chart (基础星盘数据)
- saturn_cycle (土星周期分析)

引用方式: 内联执行

## 输出配置

**使用工具**:
- show_zodiac_chart
- show_zodiac_transit
- show_insight

**交付物**: 行运分析报告

**预估轮次**: 3-5 轮

## 服务流程 (SOP)

### Phase 1: 信息收集

**类型**: required

收集用户出生信息，确认分析时间范围。

### Phase 2: 计算星盘

**类型**: required

计算本命盘和当前行运盘：
- 本命行星位置
- 当前行星位置
- 行运相位计算

### Phase 3: 快速扫描

**类型**: required

识别关键行运（30秒内完成）：
- 外行星（土星、天王星、海王星、冥王星）行运
- 木星行运
- 重要相位（合、刑、冲、三合、六合）
- 行运行星所在宫位

### Phase 4: 主动追问

**类型**: optional

根据行运特点追问：
- "你最近是否感受到某方面的压力或变化？"
- "你更想了解哪个领域：事业/感情/健康/财务？"

### Phase 5: 深度分析

**类型**: required

**使用的思维架构**:
- Robert Hand 行运方法论：行运是内在意图的外在显化
- 周期性思维：理解行星周期与人生阶段的对应

**分析框架**:
```yaml
analysis_framework:
  dimensions:
    - name: "外行星行运"
      source_framework: "Robert Hand Transit Method"
      factors: ["土星行运", "天王星行运", "海王星行运", "冥王星行运"]
      output_type: "周期性主题"
    - name: "木星行运"
      source_framework: "Expansion Cycle"
      factors: ["木星所在宫位", "木星相位"]
      output_type: "机遇领域"
    - name: "内行星行运"
      source_framework: "Daily Timing"
      factors: ["火星", "金星", "水星"]
      output_type: "近期能量"
  reasoning_approach: "从外行星到内行星，从长期主题到近期能量"
```

**知识检索**:
| 检索项 | 类型 | 查询 |
|-------|------|------|
| 行运解读 | rag | {planet} transit {aspect} {natal_planet} |
| 宫位影响 | keyword | transit through {house} house |

### Phase 6: 输出交付

**类型**: required

**工具调用顺序**:
1. `show_zodiac_chart` - 展示本命盘与行运盘
2. `show_zodiac_transit` - 展示行运分析
3. `show_insight` - 核心洞察与建议

### Phase 7: 答疑讨论

**类型**: reactive

**常见问题处理**:
| 问题模式 | 处理方式 |
|---------|---------|
| "这个行运会持续多久？" | 解释行运周期和容许度 |
| "我该怎么应对？" | 提供成长导向的建议 |
| "会发生什么事？" | 强调行运是内在意图的显化，不预测具体事件 |

## 输出模板

```
## 当前行运概览

### 主要行运
- [行星] [相位] [本命行星]：[主题解读]

### 周期性主题
[基于外行星行运的长期主题分析]

### 近期能量
[基于内行星行运的近期能量分析]

### 成长建议
[基于行运特点的成长导向建议]
```
