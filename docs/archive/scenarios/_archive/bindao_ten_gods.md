---
scenario_id: bindao_ten_gods
name: 十神配套分析
level: entry
billing: free
---

# 十神配套分析

## 触发词
- 配十神
- 十神是什么
- 分析十神
- 看十神
- 十神定位

## SOP 流程

### Phase 1: 确定日干
- 类型: required
- 工具: identify_daymaster
- 说明: 识别日柱天干作为命主代表

### Phase 2: 天干配十神
- 类型: required
- 工具: bindao_tiangan_ten_gods
- 说明: 根据天干与日干的生克关系配十神

### Phase 3: 地支配十神
- 类型: required
- 工具: bindao_dizhi_ten_gods
- 说明: 根据地支与日干的生克关系配十神

### Phase 4: 输出十神格式
- 类型: required
- 工具: format_ten_gods_output
- 说明: 按标准格式输出带十神的八字

