---
id: solar_return
name: 太阳返照
level: professional
billing: premium
description: 解读太阳返照盘，揭示新一年的主题与机遇
---

# 太阳返照

## 触发条件

**主要触发词**: 生日盘, 年度运势, 太阳返照

**次要触发词**: 新的一年, 生日运势, 年度主题

## 前置要求

- 用户出生日期（必须）
- 用户出生时间（必须）
- 出生地点（必须）
- 当前所在地点（推荐，用于计算返照盘）

## 可组合场景

本场景可引用以下MiniSkill的分析框架：
- natal (本命盘解读)
- transit (行运分析)

引用方式: 内联执行

## 输出配置

**使用工具**:
- show_zodiac_chart
- show_insight
- show_report

**交付物**: 太阳返照年度报告

**预估轮次**: 4-6 轮

## 服务流程 (SOP)

### Phase 1: 信息收集

**类型**: required

收集信息：
- 完整出生信息
- 当前所在地点（影响返照盘宫位）
- 想了解的年度（当年或下一年）

### Phase 2: 计算返照盘

**类型**: required

计算太阳返照盘：
- 太阳精确返回本命位置的时刻
- 返照盘行星位置
- 返照盘宫位（基于当前所在地）
- 返照盘与本命盘的互动

### Phase 3: 快速扫描

**类型**: required

识别年度主题（30秒内完成）：
- 返照上升星座
- 返照太阳所在宫位
- 返照月亮位置
- 关键行星配置
- 与本命盘的重要相位

### Phase 4: 主动追问

**类型**: optional

根据返照盘特点追问：
- "新的一年你最关注哪个领域？"
- "你对即将到来的一年有什么期待或担忧？"

### Phase 5: 深度分析

**类型**: required

**使用的思维架构**:
- Mary Fortier Shea 太阳返照方法论：返照盘是年度蓝图
- 宫位焦点分析：返照太阳宫位决定年度焦点
- 周期整合：返照盘与行运的结合

**分析框架**:
```yaml
analysis_framework:
  dimensions:
    - name: "年度焦点"
      source_framework: "Solar Return Sun House"
      factors: ["返照太阳宫位", "返照上升"]
      output_type: "年度主题"
    - name: "情感基调"
      source_framework: "Solar Return Moon"
      factors: ["返照月亮星座", "返照月亮宫位", "月亮相位"]
      output_type: "情感需求"
    - name: "机遇与挑战"
      source_framework: "Planetary Configurations"
      factors: ["木星位置", "土星位置", "关键相位"]
      output_type: "机遇/挑战领域"
    - name: "与本命的互动"
      source_framework: "SR-Natal Aspects"
      factors: ["返照行星与本命行星相位"]
      output_type: "激活的本命主题"
  reasoning_approach: "从年度焦点到具体领域，从机遇到挑战"
```

**知识检索**:
| 检索项 | 类型 | 查询 |
|-------|------|------|
| 返照解读 | rag | solar return {planet} in {house} |
| 年度主题 | rag | solar return ascendant {sign} |
| 返照技法 | keyword | solar return interpretation |

### Phase 6: 输出交付

**类型**: required

**工具调用顺序**:
1. `show_zodiac_chart` - 展示太阳返照盘
2. `show_report` - 年度主题报告
3. `show_insight` - 年度洞察卡片

### Phase 7: 答疑讨论

**类型**: reactive

**常见问题处理**:
| 问题模式 | 处理方式 |
|---------|---------|
| "这一年会好吗？" | 解释返照盘显示主题，不预测好坏 |
| "我应该在哪里过生日？" | 解释地点影响宫位，但不改变核心主题 |
| "返照盘准吗？" | 解释返照盘是年度能量蓝图 |

## 输出模板

```
## 太阳返照年度分析

### 年度焦点
- 返照太阳 [宫位]：[年度主要领域]
- 返照上升 [星座]：[年度外在表现]

### 情感基调
- 返照月亮 [星座] [宫位]：[情感需求与表达]

### 机遇领域
- [基于木星和有利相位的机遇分析]

### 挑战领域
- [基于土星和张力相位的挑战分析]

### 年度建议
[基于返照盘特点的年度导向建议]
```
