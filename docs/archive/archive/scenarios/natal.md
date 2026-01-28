---
id: natal
name: 本命解读
level: standard
billing: basic
description: 全面解读本命盘，揭示人格结构、生命主题与潜能
---

# 本命解读

## 触发条件

**主要触发词**: 本命盘, 完整分析, 详细看盘

**次要触发词**: 出生盘, 全面分析, 深度解读

## 前置要求

- 用户出生日期（必须）
- 用户出生时间（必须）
- 出生地点（必须）

## 可组合场景

本场景可引用以下MiniSkill的分析框架：
- basic_chart (基础星盘数据)
- sun_sign (太阳星座特质)

引用方式: 内联执行

## 输出配置

**使用工具**:
- show_zodiac_chart
- show_insight
- show_report

**交付物**: 本命盘完整解读报告

**预估轮次**: 4-6 轮

## 服务流程 (SOP)

### Phase 1: 信息收集

**类型**: required

收集完整出生信息：
- 出生日期
- 出生时间（精确到分钟）
- 出生地点

### Phase 2: 计算星盘

**类型**: required

计算完整本命盘：
- 行星位置（含凯龙星、北交点）
- 宫位系统（Placidus）
- 相位网络
- 元素/模式分布

### Phase 3: 快速扫描

**类型**: required

识别核心模式（30秒内完成）：
- 太��/月亮/上升三位一体
- 主导元素与模式
- 关键相位图形（大三角、T三角、大十字等）
- 空宫与强调宫位

### Phase 4: 主动追问

**类型**: optional

根据星盘特点追问：
- "你对自己的哪个方面最好奇？"
- "你是否经常感受到[基于星盘的特定张力]？"

### Phase 5: 深度分析

**类型**: required

**使用的思维架构**:
- Howard Sasportas 宫位哲学：宫位是生命领域的舞台
- Sue Tompkins 相位心理学：相位是内在对话
- Stephen Arroyo 元素理论：元素是能量表达方式

**分析框架**:
```yaml
analysis_framework:
  dimensions:
    - name: "核心身份"
      source_framework: "Sun-Moon-Ascendant Integration"
      factors: ["太阳星座/宫位", "月亮星座/宫位", "上升星座"]
      output_type: "人格结构描述"
    - name: "内在驱力"
      source_framework: "Planetary Psychology"
      factors: ["火星位置", "金星位置", "水星位置"]
      output_type: "动机与表达方式"
    - name: "成长主题"
      source_framework: "Outer Planet Analysis"
      factors: ["土星位置", "天王星位置", "海王星位置", "冥王星位置"]
      output_type: "生命课题"
    - name: "相位动力"
      source_framework: "Sue Tompkins Aspect Psychology"
      factors: ["主要相位", "相位图形"]
      output_type: "内在张力与整合"
  reasoning_approach: "从核心身份到成长主题，从个人行星到外行星"
```

**知识检索**:
| 检索项 | 类型 | 查询 |
|-------|------|------|
| 行星解读 | rag | {planet} in {sign} in {house} |
| 相位解读 | rag | {planet1} {aspect} {planet2} |
| 宫位主题 | keyword | {house} house meaning |

### Phase 6: 输出交付

**类型**: required

**工具调用顺序**:
1. `show_zodiac_chart` - 展示本命盘
2. `show_report` - 完整解读报告
3. `show_insight` - 核心洞察卡片

### Phase 7: 答疑讨论

**类型**: reactive

**常见问题处理**:
| 问题模式 | 处理方式 |
|---------|---------|
| "这个相位是好是坏？" | 解释相位是能量，无好坏之分 |
| "我的命盘好不好？" | 强调每个命盘都有独特价值 |
| "某行星落陷怎么办？" | 解释落陷是不同的表达方式 |

## 输出模板

```
## 本命盘解读

### 核心身份
- 太阳 [星座] [宫位]：[核心自我]
- 月亮 [星座] [宫位]：[情感需求]
- 上升 [星座]：[外在表现]

### 能量分布
- 元素：[火/土/风/水分布]
- 模式：[开创/固定/变动分布]

### 关键主题
[基于相位图形和行星配置的主题分析]

### 成长方向
[基于外行星和北交点的成长建议]
```
