---
id: synastry
name: 合盘分析
level: professional
billing: premium
description: 分析两人星盘的互动关系，揭示关系动力与成长机会
---

# 合盘分析

## 触发条件

**主要触发词**: 合盘, 配对, 兼容性, 关系分析

**次要触发词**: 我们合适吗, 感情分析, 两个人的星盘

## 前置要求

- 用户出生日期（必须）
- 用户出生时间（必须）
- 用户出生地点（必须）
- 对方出生日期（必须）
- 对方出生时间（推荐）
- 对方出生地点（推荐）

## 可组合场景

本场景可引用以下MiniSkill的分析框架：
- natal (本命盘解读)
- basic_chart (基础星盘数据)

引用方式: 内联执行

## 输出配置

**使用工具**:
- show_zodiac_chart
- show_zodiac_synastry
- show_insight
- show_report

**交付物**: 合盘分析报告

**预估轮次**: 5-7 轮

## 服务流程 (SOP)

### Phase 1: 信息收集

**类型**: required

收集双方出生信息：
- 用户完整出生信息
- 对方出生信息（尽可能完整）

### Phase 2: 计算双盘

**类型**: required

计算两人星盘：
- 用户本命盘
- 对方本命盘
- 合盘相位（Cross-aspects）
- 组合盘（Composite，可选）

### Phase 3: 快速扫描

**类型**: required

识别关键互动（30秒内完成）：
- 太阳/月亮互动
- 金星/火星互动
- 土星相位（业力连接）
- 外行星相位（深层转化）
- 宫位重叠

### Phase 4: 主动追问

**类型**: optional

根据合盘特点追问：
- "你们是什么类型的关系？（恋人/朋友/家人/同事）"
- "你们相处中最大的挑战是什么？"
- "你最想了解关系的哪个方面？"

### Phase 5: 深度分析

**类型**: required

**使用的思维架构**:
- Sue Tompkins 关系相位学：相位是两人能量的对话
- 投射分析：识别关系中的投射模式
- 成长导向：关系是相互成长的机会

**分析框架**:
```yaml
analysis_framework:
  dimensions:
    - name: "核心吸引力"
      source_framework: "Venus-Mars Dynamics"
      factors: ["金星互动", "火星互动", "太阳月亮互动"]
      output_type: "吸引力描述"
    - name: "情感连接"
      source_framework: "Moon Aspects"
      factors: ["月亮相位", "水星相位"]
      output_type: "情感沟通模式"
    - name: "挑战与成长"
      source_framework: "Saturn & Outer Planet Aspects"
      factors: ["土星相位", "天王星相位", "冥王星相位"]
      output_type: "成长课题"
    - name: "长期潜力"
      source_framework: "Composite Analysis"
      factors: ["组合盘太阳", "组合盘月亮", "组合盘土星"]
      output_type: "关系发展方向"
  reasoning_approach: "从吸引力到挑战，从当下到长期"
```

**知识检索**:
| 检索项 | 类型 | 查询 |
|-------|------|------|
| 合盘相位 | rag | synastry {planet1} {aspect} {planet2} |
| 关系动力 | rag | relationship {planet} aspects |
| 投射模式 | keyword | projection in relationships |

### Phase 6: 输出交付

**类型**: required

**工具调用顺序**:
1. `show_zodiac_chart` - 展示双方星盘
2. `show_zodiac_synastry` - 展示合盘分析
3. `show_report` - 完整合盘报告
4. `show_insight` - 关系洞察卡片

### Phase 7: 答疑讨论

**类型**: reactive

**常见问题处理**:
| 问题模式 | 处理方式 |
|---------|---------|
| "我们合适吗？" | 解释合盘显示互动模式，不决定结果 |
| "这个相位是不是很糟糕？" | 解释挑战相位是成长机会 |
| "我们能长久吗？" | 强调关系需要双方共同经营 |

## 输出模板

```
## 合盘分析

### 核心吸引力
- [吸引力来源分析]

### 情感连接
- 沟通模式：[基于水星互动]
- 情感需求：[基于月亮互动]

### 挑战与成长
- 主要挑战：[基于土星/外行星相位]
- 成长机会：[如何通过关系成长]

### 关系建议
[基于合盘特点的关系经营建议]
```
