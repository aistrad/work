---
scenario_id: bazi_calculation
name: 八字排盘计算
level: entry
billing: free
---

# 八字排盘计算

## 触发词
- 排八字
- 算八字
- 查八字
- 我的八字
- 出生时间
- 生辰八字
- 四柱

## SOP 流程

### Phase 1: 获取出生信息
- 类型: required
- 工具: collect_birth_info
- 说明: 获取精确到时分的出生时间和出生地点

### Phase 2: 查年柱
- 类型: required
- 工具: calculate_year_pillar
- 说明: 根据万年历查询年干支，注意立春分界

### Phase 3: 查月柱
- 类型: required
- 工具: calculate_month_pillar
- 说明: 根据节令和年干推算月柱干支

### Phase 4: 查日柱
- 类型: required
- 工具: calculate_day_pillar
- 说明: 根据万年历查询日干支

### Phase 5: 计算时柱
- 类型: required
- 工具: calculate_hour_pillar
- 说明: 根据日干和出生时辰推算时柱

### Phase 6: 输出完整八字
- 类型: required
- 工具: format_bazi_output
- 说明: 按格式输出四柱八字，标注性别

