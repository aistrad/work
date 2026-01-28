# 干支深度分析 (Stem Branch Depth Analysis)

## 元数据
- scenario_id: stem_branch_depth_analysis
- level: professional
- billing: premium
- source: 《东方代码启示录》第十章

## 触发条件
- primary_triggers: ["干支关系", "地支影响", "根基分析", "发展深度", "天干地支作用"]
- context_triggers: ["根基稳不稳", "能不能持久", "发展深度"]

## 场景描述
分析天干与地支之间的作用关系，判断十神发挥的深度与持久性，包括支生干、支克干、承载型、三合局三会局等专业分析。

## SOP 流程

### Phase 1: 干支关系识别 (required)
识别四柱中每组干支的关系类型:

**基本关系类型**:
1. 支生干: 地支生助天干 (根基稳固)
2. 支克干: 地支克制天干 (根基不稳)
3. 干支同气: 天干地支五行相同 (力量加强)
4. 干支相克: 天干地支五行相克 (内部矛盾)

### Phase 2: 生克型与承载型区分 (required)
**生克型地支**:
- 特点: 主动参与生克作用
- 影响: 对天干有直接增减作用
- 判断: 地支藏干与天干有生克关系

**承载型地支**:
- 特点: 被动承载天干
- ��响: 提供稳定基础但不主动作用
- 判断: 地支藏干与天干无直接生克

### Phase 3: 三合局三会局分析 (required)
**三合局**:
- 申子辰合水局
- 寅午戌合火局
- 巳酉丑合金局
- 亥卯未合木局

**三会局**:
- 寅卯辰会东方木
- 巳午未会南方火
- 申酉戌会西方金
- 亥子丑会北方水

**分析要点**:
1. 合局是否成立 (三支齐全)
2. 合局生旺哪个天干
3. 合局对命局的整体影响

### Phase 4: 深度与持久性判断 (required)
**深度判断标准**:
- 有根: 天干在地支有本气根 → 深度高
- 有气: 天干在地支有余气根 → 深度中
- 无根: 天干在地支无根 → 深度低

**持久性判断标准**:
- 支生干: 持久性强
- 支克干: 持久性弱
- 合局生旺: 持久性极强

### Phase 5: 综合解读 (required)
1. 分析各十神的根基深浅
2. 判断哪些十神能持久发挥
3. 预测人生各方面的稳定性
4. 给出针对性建议

### Phase 6: 案例参考 (optional)
- 何应钦: 支生干案例
- 崇祯皇帝: 支克干案例
- 张学良: 印枭同材案例
- 乾隆皇帝: 四位纯全案例
- 吴经熊: 三合局生旺案例

## 输出格式
```
【干支关系】
| 柱位 | 天干 | 地支 | 关系类型 | 深度 |
|------|------|------|----------|------|
| 年柱 | {year_stem} | {year_branch} | {relation} | {depth} |
| 月柱 | {month_stem} | {month_branch} | {relation} | {depth} |
| 日柱 | {day_stem} | {day_branch} | {relation} | {depth} |
| 时柱 | {hour_stem} | {hour_branch} | {relation} | {depth} |

【合局分析】
{combination_analysis}

【深度评估】
- 最稳固的十神: {most_stable}
- 最不稳的十神: {least_stable}
- 整体根基评分: {overall_score}/10

【持久性预测】
{durability_prediction}

【建议】
{advice}
```

## 关联场景
- ten_gods_pattern_analysis
- basic_reading
- life_blueprint
