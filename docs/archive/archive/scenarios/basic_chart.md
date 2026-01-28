---
id: basic_chart
name: 基础星盘
level: entry
billing: free
description: 快速解读星盘核心特征
---

# 基础星盘

## 触发条件

**主要触发词**: 看星盘, 我的星座, 星盘分析

**次要触发词**: 星座, 占星

## 前置要求

- 用户出生日期（必须）
- 用户出生时间（必须）
- 出生地点（必须）

## 输出配置

**使用工具**:
- show_zodiac_chart
- show_insight

**预估轮次**: 1-3 轮

## 服务流程 (SOP)

### Phase 1: 信息收集

**类型**: required

检查用户是否有 birth_info，无则收集。

### Phase 2: 计算星盘

**类型**: required

计算本命盘数据。

### Phase 3: 快速扫描

**类型**: required

识别核心特征：
- 太阳、月亮、上升星座
- 主要相位
- 元素分布

### Phase 4: 主动追问

**类型**: optional

根据星盘特点自然追问。

### Phase 5: 深度分析

**类型**: required

分析核心人格特质。

### Phase 6: 输出交付

**类型**: required

1. `show_zodiac_chart` - 展示星盘
2. `show_insight` - 核心洞察

### Phase 7: 答疑讨论

**类型**: reactive

回答用户追问。
