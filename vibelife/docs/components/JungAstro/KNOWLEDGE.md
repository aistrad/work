# JungAstro 知识库构建计划

## 概述

构建专门的荣格心理占星知识库，支持 JungAstro Skill 的深度分析能力。

## 核心资料来源

### 一级资料 (必须)

| 作者 | 著作 | 主题 | 优先级 |
|-----|------|------|-------|
| Liz Greene | Saturn: A New Look at an Old Devil | 土星心理学 | P0 |
| Liz Greene | The Astrology of Fate | 命运与心理 | P0 |
| Howard Sasportas | The Twelve Houses | 宫位心理学 | P0 |
| Howard Sasportas | The Gods of Change | 外行星心理 | P0 |
| Stephen Arroyo | Astrology, Karma & Transformation | 业力与转化 | P0 |

### 二级资料 (推荐)

| 作者 | 著作 | 主题 | 优先级 |
|-----|------|------|-------|
| Dane Rudhyar | The Astrology of Personality | 人格占星 | P1 |
| Liz Greene | The Luminaries | 太阳月亮心理 | P1 |
| Liz Greene | The Inner Planets | 内行星心理 | P1 |
| Robert Hand | Planets in Transit | 行运心理 | P1 |
| Sue Tompkins | Aspects in Astrology | 相位心理 | P1 |

### 三级资料 (补充)

| 作者 | 著作 | 主题 | 优先级 |
|-----|------|------|-------|
| Carl Jung | Synchronicity | 共时性理论 | P2 |
| Carl Jung | Psychological Types | 心理类型 | P2 |
| James Hillman | Re-Visioning Psychology | 原型心理学 | P2 |

---

## 知识库结构

```
/data/vibelife/knowledge/jungastro/
├── source/                         # 原始资料
│   ├── liz-greene/
│   │   ├── saturn-new-look.pdf
│   │   ├── astrology-of-fate.pdf
│   │   ├── luminaries.pdf
│   │   └── inner-planets.pdf
│   ├── howard-sasportas/
│   │   ├── twelve-houses.pdf
│   │   └── gods-of-change.pdf
│   ├── stephen-arroyo/
│   │   └── karma-transformation.pdf
│   ├── dane-rudhyar/
│   │   └── astrology-personality.pdf
│   └── jung/
│       ├── synchronicity.pdf
│       └── psychological-types.pdf
│
├── converted/                      # 转换后的 Markdown
│   ├── liz-greene/
│   │   ├── saturn-new-look.md
│   │   └── ...
│   └── ...
│
└── extracted/                      # 抽取结果
    ├── cases/                      # 案例库
    │   ├── saturn-square-sun.json
    │   ├── pluto-transit-moon.json
    │   └── ...
    └── scenarios/                  # 场景库
        ├── saturn-return.md
        ├── shadow-integration.md
        └── ...
```

---

## 知识提取重点

### 1. 行星心理解读

每个行星的深度心理学解读：

```yaml
planet_psychology:
  - planet: saturn
    topics:
      - 土星作为内在权威
      - 土星与父亲情结
      - 土星的恐惧与成熟
      - 土星回归的心理意义
      - 土星相位的心理动力
    sources:
      - "Saturn: A New Look at an Old Devil"
      - "The Twelve Houses" (土星在各宫)

  - planet: pluto
    topics:
      - 冥王星与阴影
      - 冥王星与转化
      - 冥王星与权力动力
      - 冥王星行运的心理过程
    sources:
      - "The Gods of Change"
      - "Astrology, Karma & Transformation"

  - planet: moon
    topics:
      - 月亮与情感需求
      - 月亮与母亲情结
      - 月亮与内在小孩
      - 月亮相位的情感模式
    sources:
      - "The Luminaries"
```

### 2. 相位心理动力

困难相位的成长意义：

```yaml
aspect_psychology:
  - aspect: square
    topics:
      - 刑相作为成长动力
      - 内在张力的整合
      - 具体行星组合的心理意义
    examples:
      - sun_square_saturn: "自我表达与内在权威的张力"
      - moon_square_pluto: "情感安全与深层转化的张力"
      - venus_square_mars: "爱与欲望的张力"

  - aspect: opposition
    topics:
      - 对冲作为极性整合
      - 投射与关系觉察
      - 具体行星组合的心理意义
    examples:
      - sun_opposition_moon: "意识与无意识的整合"
      - venus_opposition_saturn: "爱与责任的平衡"
```

### 3. 宫位生命主题

12宫位的心理发展任务：

```yaml
house_psychology:
  - house: 1
    topics:
      - 身份认同的形成
      - 人格面具的发展
      - 1宫行星的心理意义
    sources:
      - "The Twelve Houses" Chapter 1

  - house: 8
    topics:
      - 深层转化的领域
      - 亲密与权力动力
      - 死亡与重生的心理
      - 8宫行星的心理意义
    sources:
      - "The Twelve Houses" Chapter 8

  - house: 12
    topics:
      - 集体无意识的连接
      - 隐藏的自我
      - 灵性发展
      - 12宫行星的心理意义
    sources:
      - "The Twelve Houses" Chapter 12
```

### 4. 周期心理学

人生周期的心理意义：

```yaml
cycle_psychology:
  - cycle: saturn_return
    topics:
      - 第一次土星回归 (~29岁)
      - 第二次土星回归 (~58岁)
      - 土星回归的心理任务
      - 如何健康度过土星回归
    sources:
      - "Saturn: A New Look at an Old Devil"

  - cycle: uranus_opposition
    topics:
      - 中年觉醒 (~42岁)
      - 重新评估人生
      - 打破旧模式
    sources:
      - "The Gods of Change"

  - cycle: chiron_return
    topics:
      - 疗愈者的觉醒 (~50岁)
      - 接受伤痛
      - 成为疗愈者
    sources:
      - "The Gods of Change"
```

### 5. 阴影整合方法

如何与困难配置工作：

```yaml
shadow_integration:
  topics:
    - 识别阴影的方法
    - 投射的觉察与收回
    - 困难相位的整合策略
    - 冥王星能量的转化
    - 土星恐惧的面对
  sources:
    - "Saturn: A New Look at an Old Devil"
    - "The Gods of Change"
    - "Astrology, Karma & Transformation"
```

---

## 知识提取流程

### Stage 0: 格式转换

```bash
# PDF → Markdown
python scripts/build_knowledge.py --skill jungastro --stages 0
```

### Stage 1-3: 切块入库

```bash
# 切块 → 向量化 → 入库
python scripts/build_knowledge.py --skill jungastro --stages 1-3
```

### Stage 4C: Case 抽取

从知识库中抽取具体案例：

```bash
cd /home/aiscend/work/vibelife/apps/api
python workers/case_extractor.py jungastro
```

**Case 数据结构**:

```json
{
  "id": "saturn_square_sun_case_001",
  "skill_id": "jungastro",
  "scenario_ids": ["shadow-work", "psychological-portrait"],
  "name": "太阳刑土星的心理整合",
  "core_data": {
    "aspect": "sun_square_saturn",
    "sun_sign": "leo",
    "saturn_sign": "scorpio"
  },
  "features": {
    "tension_type": "self_expression_vs_authority",
    "shadow_manifestation": ["self_doubt", "perfectionism"],
    "integration_path": "building_inner_authority"
  },
  "analysis": {
    "psychological_dynamics": "...",
    "shadow_patterns": "...",
    "growth_opportunities": "..."
  },
  "conclusion": {
    "integration_suggestions": ["..."],
    "affirmation": "..."
  },
  "authority": "high",
  "source": "Saturn: A New Look at an Old Devil, Chapter 5"
}
```

### Stage 4S: Scenario 抽取

从知识库中抽取场景模板：

```bash
python workers/scenario_extractor.py jungastro
```

**Scenario 示例**:

```markdown
---
id: saturn-return
name: 土星回归分析
level: standard
billing: basic
description: 分析土星回归的心理意义和成长任务
---

# 土星回归分析

## 触发条件

**主要触发词**: 土星回归, 29岁, 58岁, 人生转折

**次要触发词**: 成年, 成熟, 责任

## 服务流程 (SOP)

### Phase 1: 信息收集
确认用户年龄和出生信息
**工具**: collect_birth_info

### Phase 2: 本命土星分析
分析本命土星的星座和宫位
**工具**: search_db (query: "土星 {sign} {house}宫")

### Phase 3: 展示分析
展示土星回归分析
**工具**: show_individuation_path (cycle: "saturn_return")
```

### Stage 6: 质量检查

```bash
python scripts/build_knowledge.py --skill jungastro --stages 6
```

**质量指标**:

| 指标 | 目标 |
|------|------|
| 知识覆盖率 | ≥300 chunks |
| 案例分布 | ≥50 cases |
| 场景覆盖 | ≥10 scenarios |
| 检索质量 | ≥70% |

---

## 知识检索策略

### Query 模式

| 检索类型 | Query 模式 | 示例 |
|---------|-----------|------|
| 行星心理 | "{planet} 心理功能 荣格" | "土星 心理功能 荣格" |
| 相位解读 | "{planet1} {aspect} {planet2} 心理" | "太阳 刑 土星 心理" |
| 宫位心理 | "{house}宫 心理意义" | "第八宫 心理意义" |
| 阴影工作 | "阴影 {planet/sign} 整合" | "阴影 冥王星 整合" |
| 周期分析 | "{cycle} 心理任务" | "土星回归 心理任务" |

### 检索优先级

1. **精确匹配**: 优先返回与查询完全匹配的内容
2. **权威来源**: 优先返回一级资料的内容
3. **案例支撑**: 优先返回有具体案例的内容
4. **整合建议**: 优先返回包含整合建议的内容

---

## 实施时间线

### Week 1: 资料收集与转换
- [ ] 收集一级资料 (5本)
- [ ] PDF → Markdown 转换
- [ ] 初步质量检查

### Week 2: 切块入库
- [ ] 切块处理
- [ ] 向量化
- [ ] 入库
- [ ] 检索测试

### Week 3: Case/Scenario 抽取
- [ ] Case 抽取 (目标: 50+)
- [ ] Scenario 抽取 (目标: 10+)
- [ ] 质量审核

### Week 4: 优化与测试
- [ ] 检索质量优化
- [ ] 端到端测试
- [ ] 文档完善

---

## 版权注意事项

1. **仅供内部使用**: 知识库内容仅用于 AI 分析，不直接展示给用户
2. **引用标注**: 所有提取的知识标注来源
3. **合理使用**: 遵循学术引用的合理使用原则
4. **原创输出**: AI 生成的分析是原创内容，不是直接复制
