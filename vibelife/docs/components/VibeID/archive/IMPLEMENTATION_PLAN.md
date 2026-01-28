# VibeID v5.0 实施计划

> **基于**: VibeID设计-v4.md (实际为 v5.0)
> **日期**: 2026-01-16
> **目标**: 完整实现 v5.0，后端优先，增量升级

---

## 一、现状分析

### 1.1 现有代码结构

| 模块 | 文件 | 现状 | 需要改动 |
|------|------|------|----------|
| 八字计算 | `skills/bazi/services/calculator.py` | 基础四柱排盘、十神计算 | 新增日主强弱、用神、格局 |
| 八字解读 | `skills/bazi/services/interpreter.py` | 简单解读 | 新增原型映射 |
| 八字运势 | `skills/bazi/services/computer.py` | 大运/流年/每日 | 保持不变 |
| 星盘计算 | `services/astrology/calculator.py` | 使用 kerykeion | 已支持五点 |
| 星座运势 | `skills/zodiac/services/computer.py` | 太阳/月亮/上升 | 新增金星/火星 |
| 用户画像 | `stores/unified_profile_repo.py` | JSONB 存储 | 新增 vibe_id 字段 |

### 1.2 Gap 分析

| 功能 | v5.0 要求 | 当前状态 | 实现难度 |
|------|----------|----------|----------|
| 日主强弱计算 | 得令/得地/得势 | 无 | 中 |
| 用神喜忌判断 | 5种用神类型 | 无 | 中 |
| 格局判断 | 10种正格 | 简单月令格局 | 中 |
| 格局+用神→原型映射 | 50种组合 | 无 | 低 |
| 五点星盘 | 太阳/月亮/上升/金星/火星 | 太阳/月亮/上升 | 低 |
| 12原型四维模型 | Core/Inner/Outer/Shadow | 无 | 中 |
| 八字主导融合 | 70%/30% + 一致性奖励 | 无 | 低 |
| 可解释性模块 | 八字/星座/融合洞察 | 无 | 低 |

---

## 二、文件结构设计

```
apps/api/
├── services/
│   └── vibe_id/                    # 新建目录
│       ├── __init__.py
│       ├── models.py               # 数据模型定义
│       ├── bazi_analyzer.py        # 八字中等深度分析
│       ├── zodiac_analyzer.py      # 五点星盘分析
│       ├── archetype_calculator.py # 原型计算
│       ├── fusion_engine.py        # 融合算法
│       ├── explainer.py            # 可解释性生成
│       └── service.py              # 统一服务入口
├── routes/
│   └── vibe_id.py                  # API 路由
└── stores/
    └── unified_profile_repo.py     # 更新 vibe_id 字段
```

---

## 三、数据结构设计

### 3.1 VibeID Profile 结构 (存储在 unified_profiles.profile.vibe_id)

```python
@dataclass
class VibeIDProfile:
    """VibeID 完整画像"""

    # 计算元数据
    version: str = "5.0"
    calculated_at: datetime = None

    # 八字分析结果
    bazi_analysis: BaziAnalysis = None

    # 星盘分析结果
    zodiac_analysis: ZodiacAnalysis = None

    # 四维原型
    archetypes: FourDimensionalArchetypes = None

    # 12原型得分
    archetype_scores: Dict[str, float] = None  # 0-100

    # 可解释性
    explanation: Explanation = None


@dataclass
class BaziAnalysis:
    """八字分析结果"""
    day_master: str                    # 日主天干
    day_master_element: str            # 日主五行
    day_master_strength: str           # 极旺/偏旺/中和/偏弱/极弱
    day_master_strength_score: float   # -1.0 ~ 1.0
    pattern: str                       # 格局名称
    useful_god: str                    # 用神类型
    archetype_driver: str              # 原型驱动描述
    primary_archetype: str             # 主原型
    secondary_archetype: str           # 副原型


@dataclass
class ZodiacAnalysis:
    """星盘分析结果"""
    sun_sign: str
    moon_sign: str
    rising_sign: str
    venus_sign: str                    # v5.0 新增
    mars_sign: str                     # v5.0 新增
    primary_archetype: str
    inner_archetype: str               # 月亮+金星
    outer_archetype: str               # 上升+火星


@dataclass
class FourDimensionalArchetypes:
    """四维原型"""
    core: ArchetypeResult              # 灵魂本质
    inner: ArchetypeResult             # 内在世界
    outer: ArchetypeResult             # 外在呈现
    shadow: ArchetypeResult            # 阴影倾向


@dataclass
class ArchetypeResult:
    """单个原型结果"""
    primary: str                       # 主原型
    secondary: str = None              # 副原型
    confidence: str = "medium"         # high/medium/low
    source: Dict[str, Any] = None      # 来源说明


@dataclass
class Explanation:
    """可解释性"""
    summary: str                       # 总结
    bazi_insight: str                  # 八字洞察
    zodiac_insight: str                # 星座洞察
    integration_insight: str           # 融合洞察
    growth_direction: str              # 成长方向
```

### 3.2 API 响应结构

```python
@dataclass
class VibeIDResponse:
    """API 响应"""
    # 简化展示
    primary_archetype: str
    primary_emoji: str
    primary_tagline: str
    secondary_archetype: str

    # 四维原型
    core: ArchetypeDisplay
    inner: ArchetypeDisplay
    outer: ArchetypeDisplay
    shadow: ArchetypeDisplay

    # 归因简述
    bazi_brief: str                    # "正官格 · 用神为财"
    zodiac_brief: str                  # "太阳狮子 · 月亮巨蟹 · 上升天蝎"

    # 可解释性
    explanation: Explanation

    # 12原型雷达图数据
    archetype_scores: Dict[str, float]
```

---

## 四、核心算法设计

### 4.1 日主强弱计算

```python
def calculate_day_master_strength(bazi_chart: BaziChart) -> Tuple[str, float]:
    """
    计算日主强弱

    Returns:
        (强弱等级, 强度分数 -1.0 到 1.0)
    """
    score = 0.0
    day_master = bazi_chart.day_master.stem
    month_branch = bazi_chart.four_pillars["month"].branch

    # 1. 得令判断 (月支对日主的影响) - 权重40%
    seasonal_factor = get_seasonal_strength(day_master, month_branch)
    score += seasonal_factor * 0.4

    # 2. 得地判断 (四支对日主的根气) - 权重30%
    root_factor = calculate_root_strength(day_master, bazi_chart)
    score += root_factor * 0.3

    # 3. 得势判断 (天干透出的帮扶) - 权重20%
    support_factor = calculate_stem_support(day_master, bazi_chart)
    score += support_factor * 0.2

    # 4. 合冲修正 - 权重10%
    combination_factor = calculate_combination_effect(bazi_chart)
    score += combination_factor * 0.1

    # 转换为等级
    if score >= 0.6:
        return ("极旺", score)
    elif score >= 0.2:
        return ("偏旺", score)
    elif score >= -0.2:
        return ("中和", score)
    elif score >= -0.6:
        return ("偏弱", score)
    else:
        return ("极弱", score)
```

### 4.2 用神判断

```python
def determine_useful_god(bazi_chart: BaziChart, strength: str) -> str:
    """
    根据日主强弱确定用神

    Returns:
        用神类型: 财/官杀/印/食伤/比劫
    """
    if strength in ["偏旺", "极旺"]:
        # 身旺喜泄耗
        if has_strong_element(bazi_chart, "food_god"):
            return "食伤"  # 食伤泄秀
        elif has_strong_element(bazi_chart, "wealth"):
            return "财"    # 财星耗身
        else:
            return "官杀"  # 官杀制身
    elif strength in ["偏弱", "极弱"]:
        # 身弱喜生扶
        if has_strong_element(bazi_chart, "resource"):
            return "印"    # 印星生身
        else:
            return "比劫"  # 比劫帮身
    else:
        # 中和取平衡
        return determine_balanced_god(bazi_chart)
```

### 4.3 格局判断

```python
PATTERN_TYPES = [
    "正官格", "七杀格", "正印格", "偏印格",
    "食神格", "伤官格", "正财格", "偏财格",
    "比肩格", "劫财格"
]

def determine_pattern(bazi_chart: BaziChart) -> str:
    """
    判断八字格局

    基于月令透干取格
    """
    month_branch = bazi_chart.four_pillars["month"].branch
    month_hidden = BRANCH_HIDDEN_STEMS.get(month_branch, [])

    # 检查月令藏干是否透出
    for stem in [p.stem for p in bazi_chart.four_pillars.values()]:
        if stem in month_hidden and stem != bazi_chart.day_master.stem:
            ten_god = get_ten_god(bazi_chart.day_master.stem, stem)
            return f"{ten_god}格"

    # 默认取月令本气
    if month_hidden:
        main_stem = month_hidden[0]
        ten_god = get_ten_god(bazi_chart.day_master.stem, main_stem)
        return f"{ten_god}格"

    return "普通格局"
```

### 4.4 格局+用神→原型映射

```python
BAZI_ARCHETYPE_MAPPING = {
    "正官格": {
        "财": {"primary": "Ruler", "secondary": "Caregiver", "driver": "责任驱动型成就者"},
        "官杀": {"primary": "Ruler", "secondary": "Hero", "driver": "权威导向型领导者"},
        "印": {"primary": "Sage", "secondary": "Ruler", "driver": "知识驱动型领导者"},
        "食伤": {"primary": "Creator", "secondary": "Ruler", "driver": "创意表达型管理者"},
        "比劫": {"primary": "Regular", "secondary": "Ruler", "driver": "团队协作型领导者"},
    },
    "七杀格": {
        "财": {"primary": "Hero", "secondary": "Explorer", "driver": "冒险进取型开拓者"},
        "官杀": {"primary": "Outlaw", "secondary": "Hero", "driver": "突破规则型变革者"},
        "印": {"primary": "Hero", "secondary": "Sage", "driver": "智勇双全型战士"},
        "食伤": {"primary": "Outlaw", "secondary": "Creator", "driver": "创新颠覆型先锋"},
        "比劫": {"primary": "Hero", "secondary": "Regular", "driver": "团队战斗型英雄"},
    },
    # ... 其他8种格局
}
```

### 4.5 融合算法

```python
def calculate_fused_archetype(
    bazi_result: BaziAnalysis,
    zodiac_result: ZodiacAnalysis
) -> FourDimensionalArchetypes:
    """
    八字主导融合算法

    权重: 八字 70%, 星座 30%
    一致性奖励: +15%
    """
    # Core 原型: 八字格局+用神 70% + 太阳星座 30%
    core = calculate_core_archetype(bazi_result, zodiac_result)

    # Inner 原型: 月亮星座 75% + 金星星座 25%
    inner = calculate_inner_archetype(zodiac_result)

    # Outer 原型: 上升星座 70% + 火星星座 30%
    outer = calculate_outer_archetype(zodiac_result)

    # Shadow 原型: 基于 Core 的对立面
    shadow = calculate_shadow_archetype(core.primary)

    return FourDimensionalArchetypes(
        core=core,
        inner=inner,
        outer=outer,
        shadow=shadow
    )
```

---

## 五、实施步骤

### Phase 1: 基础设施 (Day 1)

1. 创建 `services/vibe_id/` 目录结构
2. 定义数据模型 (`models.py`)
3. 创建数据库迁移脚本

### Phase 2: 八字算法升级 (Day 1-2)

1. 实现日主强弱计算 (`bazi_analyzer.py`)
2. 实现用神判断
3. 实现格局判断
4. 实现格局+用神→原型映射

### Phase 3: 星盘扩展 (Day 2)

1. 扩展 ZodiacComputer 支持金星/火星
2. 实现五点星盘→原型映射 (`zodiac_analyzer.py`)

### Phase 4: 原型系统 (Day 2-3)

1. 实现12原型定义和映射表
2. 实现四维原型计算 (`archetype_calculator.py`)
3. 实现融合算法 (`fusion_engine.py`)

### Phase 5: 可解释性 (Day 3)

1. 实现解释生成器 (`explainer.py`)
2. 实现成长方向建议

### Phase 6: API 集成 (Day 3)

1. 创建 VibeID 服务入口 (`service.py`)
2. 创建 API 路由 (`routes/vibe_id.py`)
3. 更新 unified_profile_repo

### Phase 7: 测试验证 (Day 4)

1. 单元测试
2. 集成测试
3. 端到端测试

---

## 六、API 设计

### 6.1 计算 VibeID

```
POST /api/v1/vibe-id/calculate
```

**Request:**
```json
{
  "birth_date": "1990-05-15",
  "birth_time": "08:30",
  "birth_place": "北京",
  "gender": "male"
}
```

**Response:**
```json
{
  "primary_archetype": "Creator",
  "primary_emoji": "🎨",
  "primary_tagline": "表达是我的呼吸",
  "secondary_archetype": "Outlaw",

  "core": {
    "primary": "Creator",
    "secondary": "Outlaw",
    "confidence": "high"
  },
  "inner": {
    "primary": "Magician",
    "confidence": "medium"
  },
  "outer": {
    "primary": "Caregiver",
    "confidence": "medium"
  },
  "shadow": {
    "primary": "Regular",
    "confidence": "low"
  },

  "bazi_brief": "伤官格 · 用神为财 · 身偏旺",
  "zodiac_brief": "太阳狮子 · 月亮双鱼 · 上升天蝎",

  "explanation": {
    "summary": "你的核心原型是【创造者】，副原型是【叛逆者】",
    "bazi_insight": "你的八字是伤官格，用神为财，这决定了你的人生底色是创造者型的才华变现者。",
    "zodiac_insight": "太阳狮子赋予你Creator的核心特质；月亮双鱼让你的情感表达呈现梦幻共情风格。",
    "integration_insight": "八字的Creator特质与星盘的Creator特质高度一致，说明这是你非常稳定的核心特质。",
    "growth_direction": "你的成长方向是完成作品而非追求完美，让创意真正落地。"
  },

  "archetype_scores": {
    "Innocent": 35,
    "Explorer": 55,
    "Sage": 60,
    "Hero": 45,
    "Outlaw": 75,
    "Magician": 70,
    "Regular": 30,
    "Lover": 50,
    "Jester": 45,
    "Caregiver": 55,
    "Creator": 85,
    "Ruler": 40
  }
}
```

### 6.2 获取 VibeID

```
GET /api/v1/vibe-id
```

返回已计算的 VibeID，如果不存在则返回 404。

### 6.3 重新计算 VibeID

```
POST /api/v1/vibe-id/recalculate
```

强制重新计算（用于出生信息更新后）。

---

## 七、测试计划

### 7.1 单元测试

- 日主强弱计算准确性
- 用神判断逻辑
- 格局判断逻辑
- 原型映射正确性
- 融合算法权重

### 7.2 集成测试

- 完整计算流程
- 数据存储和读取
- 缓存失效

### 7.3 测试用例

```python
TEST_CASES = [
    {
        "name": "身旺正官格",
        "birth": {"date": "1990-01-15", "time": "08:00", "gender": "male"},
        "expected": {
            "strength": "偏旺",
            "pattern": "正官格",
            "useful_god": "财",
            "primary_archetype": "Ruler"
        }
    },
    # ... 更多测试用例
]
```

---

## 八、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 八字算法复杂度 | 计算不准确 | 参考经典文献，逐步验证 |
| 星盘计算依赖 | kerykeion 库问题 | 已验证可用 |
| 数据迁移 | 老用户数据丢失 | 增量升级，保留旧数据 |
| 性能问题 | 计算耗时 | 结果缓存，异步计算 |

---

## 九、后续迭代

1. **前端展示**: VibeID 卡片组件
2. **问答确认**: 用户确认阴影原型
3. **成长追踪**: 深度日、勇气邀请
4. **社交分享**: 生成分享图片
