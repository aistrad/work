# VibeID 原型计算算法升级方案

> 版本：v2.0
> 更新日期：2026-01-16
> 状态：设计完成

---

## 1. 项目概述

### 1.1 背景

VibeID 是 VibeLife 的核心人格操作系统，将东方命理（八字）与西方占星（星座）融合，映射到荣格12原型体系。当前算法存在以下问题：

1. **八字格局判断过于简化**：仅基于月令十神，未考虑日主强弱、用神喜忌
2. **星座信息利用不足**：仅用太阳星座，浪费了已计算的丰富星盘数据
3. **融合算法缺乏理论支撑**：60%/40%权重是拍脑袋决定的
4. **可解释性不足**：用户不理解"为什么我是这个原型"

### 1.2 升级目标

| 目标 | 描述 | 优先级 |
|------|------|--------|
| 准确性 | 让计算结果更符合用户真实人格 | P0 |
| 可解释性 | 让用户理解原型归因的依据 | P0 |
| 成长导向 | 让系统能引导用户的个体化成长 | P1 |
| 差异化 | 让不同用户的结果有足够区分度 | P2 |

### 1.3 设计原则

1. **八字主导**：八字决定Core原型，星座补充表达细节
2. **中等深度**：加入日主强弱、用神喜忌，但不追求专业命理师级别
3. **五点星盘**：太阳、月亮、上升、金星、火星五点模型
4. **得分计算+简化呈现**：后台计算完整12原型得分，前台呈现主原型+副原型

---

## 2. 核心算法设计

### 2.1 八字原型计算（Primary Source）

#### 2.1.1 日主强弱判断

日主强弱是原型计算的基础参数，影响原型的表达方式。

```python
class DayMasterStrength(Enum):
    """日主强弱等级"""
    EXTREMELY_STRONG = "极旺"  # 得令得地得势，需要泄耗
    STRONG = "偏旺"            # 有根有气，喜泄耗
    BALANCED = "中和"          # 身旺弱平衡，喜顺势
    WEAK = "偏弱"              # 无根少气，喜生扶
    EXTREMELY_WEAK = "极弱"    # 从格条件，需特殊处理

def calculate_day_master_strength(bazi: BaziChart) -> tuple[DayMasterStrength, float]:
    """
    计算日主强弱

    Returns:
        (强弱等级, 强度分数 -1.0 到 1.0)
    """
    score = 0.0

    # 1. 得令判断 (月支对日主的影响)
    month_branch = bazi.month_branch
    day_master = bazi.day_master
    seasonal_factor = get_seasonal_strength(day_master, month_branch)
    score += seasonal_factor * 0.4  # 权重40%

    # 2. 得地判断 (四支对日主的根气)
    root_factor = calculate_root_strength(day_master, bazi.branches)
    score += root_factor * 0.3  # 权重30%

    # 3. 得势判断 (天干透出的帮扶)
    support_factor = calculate_stem_support(day_master, bazi.stems)
    score += support_factor * 0.2  # 权重20%

    # 4. 合冲修正 (干支合化、地支冲合)
    combination_factor = calculate_combination_effect(bazi)
    score += combination_factor * 0.1  # 权重10%

    # 转换为等级
    if score >= 0.6:
        return (DayMasterStrength.EXTREMELY_STRONG, score)
    elif score >= 0.2:
        return (DayMasterStrength.STRONG, score)
    elif score >= -0.2:
        return (DayMasterStrength.BALANCED, score)
    elif score >= -0.6:
        return (DayMasterStrength.WEAK, score)
    else:
        return (DayMasterStrength.EXTREMELY_WEAK, score)
```

#### 2.1.2 用神喜忌判断

用神决定了命局的需求方向，直接影响原型的核心驱动力。

```python
class UsefulGod(Enum):
    """用神类型"""
    WEALTH = "财"        # 追求资源、物质
    POWER = "官杀"       # 追求权力、地位
    RESOURCE = "印"      # 追求知识、支持
    OUTPUT = "食伤"      # 追求表达、创造
    PEER = "比劫"        # 追求合作、竞争

def determine_useful_god(bazi: BaziChart, strength: DayMasterStrength) -> UsefulGod:
    """
    根据日主强弱确定用神

    基本原则：
    - 身旺：喜财官食伤（泄耗之神）
    - 身弱：喜印比（生扶之神）
    - 特殊格局：顺势取用
    """
    if strength in [DayMasterStrength.STRONG, DayMasterStrength.EXTREMELY_STRONG]:
        # 身旺喜泄耗
        if has_strong_element(bazi, "food_god"):
            return UsefulGod.OUTPUT  # 食伤泄秀
        elif has_strong_element(bazi, "wealth"):
            return UsefulGod.WEALTH  # 财星耗身
        else:
            return UsefulGod.POWER  # 官杀制身
    elif strength in [DayMasterStrength.WEAK, DayMasterStrength.EXTREMELY_WEAK]:
        # 身弱喜生扶
        if has_strong_element(bazi, "resource"):
            return UsefulGod.RESOURCE  # 印星生身
        else:
            return UsefulGod.PEER  # 比劫帮身
    else:
        # 中和取平衡
        return determine_balanced_god(bazi)
```

#### 2.1.3 格局+用神→原型映射

升级后的映射考虑格局和用神的组合：

```python
# 格局-用神-原型映射表
# 每个格局根据用神不同，映射到不同的原型组合

BAZI_ARCHETYPE_MAPPING = {
    # 正官格（秩序、规范、责任）
    "正官格": {
        UsefulGod.WEALTH: {
            "primary": Archetype.RULER,      # 统治者：通过资源管理实现秩序
            "secondary": Archetype.CAREGIVER, # 照顾者：对他人负责
            "driver": "责任驱动型成就者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 智者：通过知识获得权威
            "secondary": Archetype.RULER,
            "driver": "知识驱动型领导者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：在规范中创新
            "secondary": Archetype.RULER,
            "driver": "创新驱动型改革者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.REGULAR,    # 凡人：平等合作的领导
            "secondary": Archetype.RULER,
            "driver": "群体驱动型领袖"
        },
        UsefulGod.POWER: {
            "primary": Archetype.RULER,      # 纯粹的统治者
            "secondary": Archetype.HERO,
            "driver": "权力驱动型领导者"
        }
    },

    # 七杀格（魄力、挑战、突破）
    "七杀格": {
        UsefulGod.RESOURCE: {
            "primary": Archetype.HERO,       # 英雄：以智取胜
            "secondary": Archetype.SAGE,
            "driver": "策略型战士"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.OUTLAW,     # 叛逆者：挑战权威
            "secondary": Archetype.CREATOR,
            "driver": "颠覆性创新者"
        },
        UsefulGod.WEALTH: {
            "primary": Archetype.HERO,       # 英雄：征服式获取
            "secondary": Archetype.EXPLORER,
            "driver": "开拓型冒险家"
        },
        UsefulGod.PEER: {
            "primary": Archetype.HERO,       # 英雄：团队作战
            "secondary": Archetype.REGULAR,
            "driver": "合作型战士"
        },
        UsefulGod.POWER: {
            "primary": Archetype.OUTLAW,     # 叛逆者：以暴制暴
            "secondary": Archetype.HERO,
            "driver": "革命型领袖"
        }
    },

    # 正印格（滋养、学习、传承）
    "正印格": {
        UsefulGod.POWER: {
            "primary": Archetype.SAGE,       # 智者：知识即权力
            "secondary": Archetype.RULER,
            "driver": "学术型权威"
        },
        UsefulGod.WEALTH: {
            "primary": Archetype.CAREGIVER,  # 照顾者：资源滋养他人
            "secondary": Archetype.SAGE,
            "driver": "资源型守护者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：传承中创新
            "secondary": Archetype.SAGE,
            "driver": "传承型创作者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.CAREGIVER,  # 照顾者：群体滋养
            "secondary": Archetype.REGULAR,
            "driver": "群体型教育者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 纯粹的智者
            "secondary": Archetype.INNOCENT,
            "driver": "纯粹求知者"
        }
    },

    # 偏印格（独立、非主流、直觉）
    "偏印格": {
        UsefulGod.POWER: {
            "primary": Archetype.MAGICIAN,   # 魔术师：神秘的权力
            "secondary": Archetype.SAGE,
            "driver": "幕后操控者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：非主流创作
            "secondary": Archetype.OUTLAW,
            "driver": "先锋艺术家"
        },
        UsefulGod.WEALTH: {
            "primary": Archetype.MAGICIAN,   # 魔术师：点石成金
            "secondary": Archetype.EXPLORER,
            "driver": "另类投资者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.OUTLAW,     # 叛逆者：群体边缘
            "secondary": Archetype.MAGICIAN,
            "driver": "反主流联盟者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 智者：深度研究
            "secondary": Archetype.MAGICIAN,
            "driver": "神秘学研究者"
        }
    },

    # 食神格（表达、享受、分享）
    "食神格": {
        UsefulGod.WEALTH: {
            "primary": Archetype.CREATOR,    # 创造者：创作变现
            "secondary": Archetype.LOVER,
            "driver": "商业化创作者"
        },
        UsefulGod.POWER: {
            "primary": Archetype.MAGICIAN,   # 魔术师：才华转化影响力
            "secondary": Archetype.CREATOR,
            "driver": "影响力创作者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 智者：输出型学者
            "secondary": Archetype.CREATOR,
            "driver": "知识传播者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.JESTER,     # 愚者：娱乐大众
            "secondary": Archetype.CREATOR,
            "driver": "群体娱乐者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 纯粹的创造者
            "secondary": Archetype.JESTER,
            "driver": "纯粹表达者"
        }
    },

    # 伤官格（叛逆、创新、挑战）
    "伤官格": {
        UsefulGod.WEALTH: {
            "primary": Archetype.CREATOR,    # 创造者：创新获利
            "secondary": Archetype.OUTLAW,
            "driver": "颠覆式创业者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.MAGICIAN,   # 魔术师：智慧型叛逆
            "secondary": Archetype.CREATOR,
            "driver": "思想叛逆者"
        },
        UsefulGod.POWER: {
            "primary": Archetype.OUTLAW,     # 叛逆者：挑战权威
            "secondary": Archetype.HERO,
            "driver": "体制挑战者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.OUTLAW,     # 叛逆者：群体叛逆
            "secondary": Archetype.EXPLORER,
            "driver": "反叛联盟者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：极致表达
            "secondary": Archetype.OUTLAW,
            "driver": "极端艺术家"
        }
    },

    # 正财格（稳健、积累、务实）
    "正财格": {
        UsefulGod.POWER: {
            "primary": Archetype.RULER,      # 统治者：资源型领导
            "secondary": Archetype.REGULAR,
            "driver": "资源管理者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：实用创作
            "secondary": Archetype.REGULAR,
            "driver": "实用型创作者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 智者：理财专家
            "secondary": Archetype.CAREGIVER,
            "driver": "财务顾问型"
        },
        UsefulGod.PEER: {
            "primary": Archetype.REGULAR,    # 凡人：共同致富
            "secondary": Archetype.CAREGIVER,
            "driver": "群体经济者"
        },
        UsefulGod.WEALTH: {
            "primary": Archetype.REGULAR,    # 纯粹的凡人
            "secondary": Archetype.LOVER,
            "driver": "务实生活者"
        }
    },

    # 偏财格（冒险、投机、慷慨）
    "偏财格": {
        UsefulGod.POWER: {
            "primary": Archetype.EXPLORER,   # 探险家：冒险获权
            "secondary": Archetype.RULER,
            "driver": "冒险型领袖"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.JESTER,     # 愚者：乐善好施
            "secondary": Archetype.CREATOR,
            "driver": "慷慨创作者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.MAGICIAN,   # 魔术师：投机智慧
            "secondary": Archetype.EXPLORER,
            "driver": "投资策略家"
        },
        UsefulGod.PEER: {
            "primary": Archetype.JESTER,     # 愚者：社交达人
            "secondary": Archetype.LOVER,
            "driver": "社交投资者"
        },
        UsefulGod.WEALTH: {
            "primary": Archetype.EXPLORER,   # 探险家：财富冒险
            "secondary": Archetype.JESTER,
            "driver": "财富探险家"
        }
    },

    # 比肩格（独立、竞争、自主）
    "比肩格": {
        UsefulGod.WEALTH: {
            "primary": Archetype.EXPLORER,   # 探险家：独立开拓
            "secondary": Archetype.HERO,
            "driver": "独立开拓者"
        },
        UsefulGod.POWER: {
            "primary": Archetype.HERO,       # 英雄：竞争获胜
            "secondary": Archetype.OUTLAW,
            "driver": "竞争型战士"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.CREATOR,    # 创造者：独立创作
            "secondary": Archetype.EXPLORER,
            "driver": "独立创作者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.SAGE,       # 智者：自学成才
            "secondary": Archetype.EXPLORER,
            "driver": "自学型专家"
        },
        UsefulGod.PEER: {
            "primary": Archetype.REGULAR,    # 凡人：群体认同
            "secondary": Archetype.HERO,
            "driver": "群体竞争者"
        }
    },

    # 劫财格（冲动、果敢、多变）
    "劫财格": {
        UsefulGod.WEALTH: {
            "primary": Archetype.OUTLAW,     # 叛逆者：不择手段
            "secondary": Archetype.EXPLORER,
            "driver": "激进获取者"
        },
        UsefulGod.POWER: {
            "primary": Archetype.HERO,       # 英雄：强势竞争
            "secondary": Archetype.OUTLAW,
            "driver": "强势竞争者"
        },
        UsefulGod.OUTPUT: {
            "primary": Archetype.JESTER,     # 愚者：冲动表达
            "secondary": Archetype.OUTLAW,
            "driver": "冲动型表达者"
        },
        UsefulGod.RESOURCE: {
            "primary": Archetype.MAGICIAN,   # 魔术师：快速学习
            "secondary": Archetype.OUTLAW,
            "driver": "速成型学习者"
        },
        UsefulGod.PEER: {
            "primary": Archetype.OUTLAW,     # 叛逆者：群体冲突
            "secondary": Archetype.HERO,
            "driver": "群体冲突者"
        }
    }
}
```

#### 2.1.4 日主强弱对原型表达的修正

```python
def apply_strength_modifier(
    archetype_scores: dict[Archetype, float],
    strength: DayMasterStrength,
    strength_score: float
) -> dict[Archetype, float]:
    """
    日主强弱修正原型表达

    身旺：增强外向型原型（Hero, Ruler, Outlaw, Explorer, Creator）
    身弱：增强内向型原型（Sage, Caregiver, Innocent, Lover, Regular）
    """
    EXTROVERT_ARCHETYPES = {
        Archetype.HERO, Archetype.RULER, Archetype.OUTLAW,
        Archetype.EXPLORER, Archetype.CREATOR, Archetype.JESTER
    }
    INTROVERT_ARCHETYPES = {
        Archetype.SAGE, Archetype.CAREGIVER, Archetype.INNOCENT,
        Archetype.LOVER, Archetype.REGULAR, Archetype.MAGICIAN
    }

    modified_scores = archetype_scores.copy()

    if strength_score > 0:  # 身旺
        modifier = 1 + strength_score * 0.2  # 最多+20%
        for archetype in EXTROVERT_ARCHETYPES:
            if archetype in modified_scores:
                modified_scores[archetype] *= modifier
    else:  # 身弱
        modifier = 1 + abs(strength_score) * 0.2
        for archetype in INTROVERT_ARCHETYPES:
            if archetype in modified_scores:
                modified_scores[archetype] *= modifier

    return modified_scores
```

### 2.2 星座原型计算（五点模型）

#### 2.2.1 五点模型设计

```python
class ZodiacFivePoints:
    """五点星盘模型"""

    POINT_WEIGHTS = {
        "sun": 0.35,      # 核心自我
        "moon": 0.25,     # 情感需求
        "ascendant": 0.20, # 社会面具
        "venus": 0.10,    # 爱情风格
        "mars": 0.10      # 行动风格
    }

    POINT_ARCHETYPE_LAYER = {
        "sun": "core",       # 影响Core原型
        "moon": "inner",     # 影响Inner表达
        "ascendant": "outer", # 影响Outer表达
        "venus": "relation",  # 影响关系模式
        "mars": "action"      # 影响行动模式
    }
```

#### 2.2.2 星座→原型映射（五点完整版）

```python
# 太阳星座映射（核心自我）
SUN_SIGN_ARCHETYPE_MAPPING = {
    "白羊座": {"primary": Archetype.HERO, "secondary": Archetype.EXPLORER},
    "金牛座": {"primary": Archetype.LOVER, "secondary": Archetype.REGULAR},
    "双子座": {"primary": Archetype.JESTER, "secondary": Archetype.MAGICIAN},
    "巨蟹座": {"primary": Archetype.CAREGIVER, "secondary": Archetype.INNOCENT},
    "狮子座": {"primary": Archetype.RULER, "secondary": Archetype.CREATOR},
    "处女座": {"primary": Archetype.SAGE, "secondary": Archetype.CAREGIVER},
    "天秤座": {"primary": Archetype.LOVER, "secondary": Archetype.RULER},
    "天蝎座": {"primary": Archetype.MAGICIAN, "secondary": Archetype.OUTLAW},
    "射手座": {"primary": Archetype.EXPLORER, "secondary": Archetype.SAGE},
    "摩羯座": {"primary": Archetype.RULER, "secondary": Archetype.HERO},
    "水瓶座": {"primary": Archetype.OUTLAW, "secondary": Archetype.SAGE},
    "双鱼座": {"primary": Archetype.INNOCENT, "secondary": Archetype.MAGICIAN}
}

# 月亮星座映射（情感需求/内在表达）
MOON_SIGN_ARCHETYPE_MAPPING = {
    "白羊座": {"primary": Archetype.HERO, "style": "直接、冲动的情感表达"},
    "金牛座": {"primary": Archetype.LOVER, "style": "稳定、感官的情感需求"},
    "双子座": {"primary": Archetype.JESTER, "style": "多变、交流的情感模式"},
    "巨蟹座": {"primary": Archetype.CAREGIVER, "style": "滋养、保护的情感本能"},
    "狮子座": {"primary": Archetype.CREATOR, "style": "热情、戏剧化的情感"},
    "处女座": {"primary": Archetype.CAREGIVER, "style": "细致、服务的情感表达"},
    "天秤座": {"primary": Archetype.LOVER, "style": "和谐、审美的情感需求"},
    "天蝎座": {"primary": Archetype.MAGICIAN, "style": "深沉、转化的情感体验"},
    "射手座": {"primary": Archetype.EXPLORER, "style": "自由、乐观的情感态度"},
    "摩羯座": {"primary": Archetype.RULER, "style": "克制、务实的情感处理"},
    "水瓶座": {"primary": Archetype.OUTLAW, "style": "超脱、人道的情感观"},
    "双鱼座": {"primary": Archetype.INNOCENT, "style": "共情、梦幻的情感世界"}
}

# 上升星座映射（社会面具/外在表达）
ASCENDANT_ARCHETYPE_MAPPING = {
    "白羊座": {"primary": Archetype.HERO, "impression": "充满活力、竞争性强"},
    "金牛座": {"primary": Archetype.REGULAR, "impression": "稳重可靠、享受生活"},
    "双子座": {"primary": Archetype.JESTER, "impression": "机智灵活、善于沟通"},
    "巨蟹座": {"primary": Archetype.CAREGIVER, "impression": "温暖亲切、富有同理心"},
    "狮子座": {"primary": Archetype.RULER, "impression": "自信大方、引人注目"},
    "处女座": {"primary": Archetype.SAGE, "impression": "谨慎细致、追求完美"},
    "天秤座": {"primary": Archetype.LOVER, "impression": "优雅得体、追求和谐"},
    "天蝎座": {"primary": Archetype.MAGICIAN, "impression": "神秘深沉、洞察力强"},
    "射手座": {"primary": Archetype.EXPLORER, "impression": "开放乐观、追求自由"},
    "摩羯座": {"primary": Archetype.RULER, "impression": "严肃可靠、目标导向"},
    "水瓶座": {"primary": Archetype.OUTLAW, "impression": "独特前卫、特立独行"},
    "双鱼座": {"primary": Archetype.INNOCENT, "impression": "温柔梦幻、富有艺术感"}
}

# 金星星座映射（爱情风格）
VENUS_SIGN_ARCHETYPE_MAPPING = {
    "白羊座": {"primary": Archetype.HERO, "love_style": "主动追求、热情直接"},
    "金牛座": {"primary": Archetype.LOVER, "love_style": "忠诚专一、感官享受"},
    "双子座": {"primary": Archetype.JESTER, "love_style": "多变有趣、智性交流"},
    "巨蟹座": {"primary": Archetype.CAREGIVER, "love_style": "温柔呵护、家庭导向"},
    "狮子座": {"primary": Archetype.CREATOR, "love_style": "浪漫奢华、戏剧化表达"},
    "处女座": {"primary": Archetype.CAREGIVER, "love_style": "细心体贴、实际付出"},
    "天秤座": {"primary": Archetype.LOVER, "love_style": "优雅浪漫、追求美感"},
    "天蝎座": {"primary": Archetype.MAGICIAN, "love_style": "深情专一、占有欲强"},
    "射手座": {"primary": Archetype.EXPLORER, "love_style": "自由开放、冒险精神"},
    "摩羯座": {"primary": Archetype.RULER, "love_style": "务实稳重、长期承诺"},
    "水瓶座": {"primary": Archetype.OUTLAW, "love_style": "独立自由、打破常规"},
    "双鱼座": {"primary": Archetype.INNOCENT, "love_style": "浪漫梦幻、无条件付出"}
}

# 火星星座映射（行动风格）
MARS_SIGN_ARCHETYPE_MAPPING = {
    "白羊座": {"primary": Archetype.HERO, "action_style": "果断冲动、竞争好胜"},
    "金牛座": {"primary": Archetype.REGULAR, "action_style": "稳健持久、务实坚定"},
    "双子座": {"primary": Archetype.MAGICIAN, "action_style": "灵活多变、策略性强"},
    "巨蟹座": {"primary": Archetype.CAREGIVER, "action_style": "情绪驱动、保护本能"},
    "狮子座": {"primary": Archetype.RULER, "action_style": "自信领导、追求卓越"},
    "处女座": {"primary": Archetype.SAGE, "action_style": "精确分析、完美主义"},
    "天秤座": {"primary": Archetype.LOVER, "action_style": "协调平衡、避免冲突"},
    "天蝎座": {"primary": Archetype.MAGICIAN, "action_style": "坚定执着、隐秘策略"},
    "射手座": {"primary": Archetype.EXPLORER, "action_style": "冒险乐观、自由奔放"},
    "摩羯座": {"primary": Archetype.HERO, "action_style": "坚韧不拔、目标导向"},
    "水瓶座": {"primary": Archetype.OUTLAW, "action_style": "独特创新、打破规则"},
    "双鱼座": {"primary": Archetype.INNOCENT, "action_style": "直觉引导、随流而动"}
}
```

#### 2.2.3 五点综合计算

```python
def calculate_zodiac_archetype_scores(chart: ZodiacChart) -> dict[Archetype, float]:
    """
    基于五点模型计算星座原型得分
    """
    archetype_scores = {archetype: 0.0 for archetype in Archetype}
    explanation_parts = []

    # 太阳星座（35%权重）
    sun_mapping = SUN_SIGN_ARCHETYPE_MAPPING[chart.sun_sign]
    archetype_scores[sun_mapping["primary"]] += 0.35 * 1.0
    archetype_scores[sun_mapping["secondary"]] += 0.35 * 0.5
    explanation_parts.append(f"太阳{chart.sun_sign}赋予你{sun_mapping['primary'].value}的核心特质")

    # 月亮星座（25%权重）
    moon_mapping = MOON_SIGN_ARCHETYPE_MAPPING[chart.moon_sign]
    archetype_scores[moon_mapping["primary"]] += 0.25 * 1.0
    explanation_parts.append(f"月亮{chart.moon_sign}让你的情感表达呈现{moon_mapping['style']}")

    # 上升星座（20%权重）
    asc_mapping = ASCENDANT_ARCHETYPE_MAPPING[chart.ascendant]
    archetype_scores[asc_mapping["primary"]] += 0.20 * 1.0
    explanation_parts.append(f"上升{chart.ascendant}让你给人{asc_mapping['impression']}的印象")

    # 金星星座（10%权重）
    venus_mapping = VENUS_SIGN_ARCHETYPE_MAPPING[chart.venus_sign]
    archetype_scores[venus_mapping["primary"]] += 0.10 * 1.0
    explanation_parts.append(f"金星{chart.venus_sign}让你的爱情风格是{venus_mapping['love_style']}")

    # 火星星座（10%权重）
    mars_mapping = MARS_SIGN_ARCHETYPE_MAPPING[chart.mars_sign]
    archetype_scores[mars_mapping["primary"]] += 0.10 * 1.0
    explanation_parts.append(f"火星{chart.mars_sign}让你的行动风格是{mars_mapping['action_style']}")

    return archetype_scores, explanation_parts
```

### 2.3 东西方融合算法

#### 2.3.1 八字主导的融合设计

```python
class FusionStrategy:
    """八字主导的东西方融合策略"""

    # 基础权重：八字70%，星座30%
    BASE_BAZI_WEIGHT = 0.70
    BASE_ZODIAC_WEIGHT = 0.30

    # 一致性奖励：当两套系统指向同一原型时
    CONSISTENCY_BONUS = 0.15

    # 冲突处理：当两套系统指向对立原型时
    CONFLICT_PENALTY = 0.10

def calculate_fused_archetype(
    bazi_scores: dict[Archetype, float],
    zodiac_scores: dict[Archetype, float],
    bazi_explanation: list[str],
    zodiac_explanation: list[str]
) -> VibeIDResult:
    """
    融合计算最终原型

    策略：
    1. 八字决定Core原型（主原型）
    2. 星座调整表达层次（Inner/Outer）
    3. 一致性增强置信度
    4. 冲突时八字优先
    """

    # Step 1: 获取八字主原型
    bazi_primary = max(bazi_scores, key=bazi_scores.get)
    bazi_primary_score = bazi_scores[bazi_primary]

    # Step 2: 获取星座主原型
    zodiac_primary = max(zodiac_scores, key=zodiac_scores.get)
    zodiac_primary_score = zodiac_scores[zodiac_primary]

    # Step 3: 一致性检查
    consistency_type = check_consistency(bazi_primary, zodiac_primary)

    # Step 4: 融合计算
    fused_scores = {}
    for archetype in Archetype:
        base_score = (
            bazi_scores.get(archetype, 0) * FusionStrategy.BASE_BAZI_WEIGHT +
            zodiac_scores.get(archetype, 0) * FusionStrategy.BASE_ZODIAC_WEIGHT
        )

        # 一致性奖励
        if archetype == bazi_primary and archetype == zodiac_primary:
            base_score += FusionStrategy.CONSISTENCY_BONUS

        fused_scores[archetype] = base_score

    # Step 5: 确定最终原型
    primary_archetype = max(fused_scores, key=fused_scores.get)

    # Step 6: 确定副原型（排除主原型后的最高分）
    secondary_scores = {k: v for k, v in fused_scores.items() if k != primary_archetype}
    secondary_archetype = max(secondary_scores, key=secondary_scores.get)

    # Step 7: 生成解释
    explanation = generate_explanation(
        primary_archetype, secondary_archetype,
        bazi_primary, zodiac_primary,
        consistency_type,
        bazi_explanation, zodiac_explanation
    )

    # Step 8: 计算置信度
    confidence = calculate_confidence(
        fused_scores[primary_archetype],
        fused_scores[secondary_archetype],
        consistency_type
    )

    return VibeIDResult(
        primary_archetype=primary_archetype,
        secondary_archetype=secondary_archetype,
        all_scores=fused_scores,
        confidence=confidence,
        explanation=explanation,
        bazi_contribution=bazi_explanation,
        zodiac_contribution=zodiac_explanation
    )

def check_consistency(bazi_archetype: Archetype, zodiac_archetype: Archetype) -> str:
    """
    检查八字和星座原型的一致性
    """
    if bazi_archetype == zodiac_archetype:
        return "perfect_match"  # 完美一致

    # 定义原型对立关系
    OPPOSING_PAIRS = [
        (Archetype.RULER, Archetype.OUTLAW),
        (Archetype.HERO, Archetype.INNOCENT),
        (Archetype.SAGE, Archetype.JESTER),
        (Archetype.CAREGIVER, Archetype.EXPLORER),
    ]

    for pair in OPPOSING_PAIRS:
        if {bazi_archetype, zodiac_archetype} == set(pair):
            return "conflict"  # 对立冲突

    # 定义原型相近关系
    SIMILAR_GROUPS = [
        {Archetype.RULER, Archetype.HERO, Archetype.MAGICIAN},
        {Archetype.SAGE, Archetype.CAREGIVER, Archetype.REGULAR},
        {Archetype.CREATOR, Archetype.EXPLORER, Archetype.OUTLAW},
        {Archetype.LOVER, Archetype.INNOCENT, Archetype.JESTER},
    ]

    for group in SIMILAR_GROUPS:
        if bazi_archetype in group and zodiac_archetype in group:
            return "similar"  # 相近

    return "neutral"  # 中性
```

#### 2.3.2 可解释性模块

```python
def generate_explanation(
    primary: Archetype,
    secondary: Archetype,
    bazi_primary: Archetype,
    zodiac_primary: Archetype,
    consistency: str,
    bazi_explanation: list[str],
    zodiac_explanation: list[str]
) -> dict:
    """
    生成用户可理解的原型解释
    """

    explanation = {
        "summary": "",
        "bazi_insight": "",
        "zodiac_insight": "",
        "integration_insight": "",
        "growth_direction": ""
    }

    # 主原型总结
    explanation["summary"] = f"你的核心原型是【{primary.chinese_name}】，副原型是【{secondary.chinese_name}】"

    # 八字洞察
    explanation["bazi_insight"] = (
        f"从八字角度看，{bazi_explanation[0]}。"
        f"这决定了你的人生底色是{bazi_primary.chinese_name}型的。"
    )

    # 星座洞察
    explanation["zodiac_insight"] = (
        f"从星盘角度看，{'; '.join(zodiac_explanation[:3])}。"
        f"这影响了你的表达方式偏向{zodiac_primary.chinese_name}。"
    )

    # 融合洞察
    if consistency == "perfect_match":
        explanation["integration_insight"] = (
            f"东方命理与西方占星高度一致地指向{primary.chinese_name}原型，"
            f"说明这是你非常稳定的核心特质。"
        )
    elif consistency == "conflict":
        explanation["integration_insight"] = (
            f"有趣的是，八字指向{bazi_primary.chinese_name}，"
            f"而星盘指向{zodiac_primary.chinese_name}，"
            f"这种张力可能让你内心有时感到矛盾。"
            f"最终我们以八字为主，确定你的主原型是{primary.chinese_name}。"
        )
    else:
        explanation["integration_insight"] = (
            f"八字的{bazi_primary.chinese_name}特质与星盘的{zodiac_primary.chinese_name}特质"
            f"相互补充，让你的人格更加丰富多元。"
        )

    # 成长方向
    explanation["growth_direction"] = generate_growth_direction(primary, secondary)

    return explanation

def generate_growth_direction(primary: Archetype, secondary: Archetype) -> str:
    """
    生成成长方向建议
    """
    GROWTH_DIRECTIONS = {
        Archetype.HERO: "你的成长方向是学会接纳脆弱，在保持勇气的同时培养同理心。",
        Archetype.SAGE: "你的成长方向是将智慧转化为行动，不仅追求理解，更要实践和分享。",
        Archetype.CAREGIVER: "你的成长方向是学会照顾自己，建立健康的边界，避免过度付出。",
        Archetype.CREATOR: "你的成长方向是完成作品而非追求完美，让创意真正落地。",
        Archetype.RULER: "你的成长方向是学会授权和信任，在掌控中保持灵活。",
        Archetype.OUTLAW: "你的成长方向是将叛逆转化为建设性的变革，找到值得为之战斗的事业。",
        Archetype.MAGICIAN: "你的成长方向是将洞察用于帮助他人，而非仅仅掌控局势。",
        Archetype.LOVER: "你的成长方向是在关系中保持独立性，避免失去自我。",
        Archetype.JESTER: "你的成长方向是在欢乐中找到深度，让幽默服务于真正重要的事。",
        Archetype.REGULAR: "你的成长方向是在归属中保持独特性，勇敢表达自己的观点。",
        Archetype.INNOCENT: "你的成长方向是在保持纯真的同时发展智慧，学会辨别而非盲目信任。",
        Archetype.EXPLORER: "你的成长方向是学会深耕，在自由探索中也能建立持久的连接。"
    }

    base_direction = GROWTH_DIRECTIONS[primary]

    # 根据副原型补充
    if secondary:
        supplement = f"同时，你的{secondary.chinese_name}副原型可以成为这个成长过程中的资源。"
        return base_direction + supplement

    return base_direction
```

---

## 3. 数据结构设计

### 3.1 VibeID 结果结构

```python
@dataclass
class VibeIDResult:
    """VibeID 计算结果"""

    # 核心原型
    primary_archetype: Archetype
    secondary_archetype: Archetype

    # 完整得分（后台保存，用于高级功能）
    all_scores: dict[Archetype, float]

    # 置信度（0-1）
    confidence: float

    # 可解释性模块
    explanation: dict[str, str]
    bazi_contribution: list[str]
    zodiac_contribution: list[str]

    # 元数据
    calculation_version: str = "v2.0"
    calculated_at: datetime = field(default_factory=datetime.now)

    # 八字详情
    bazi_pattern: str = ""
    useful_god: str = ""
    day_master_strength: str = ""

    # 星座详情
    sun_sign: str = ""
    moon_sign: str = ""
    ascendant: str = ""
    venus_sign: str = ""
    mars_sign: str = ""

@dataclass
class VibeIDDisplay:
    """VibeID 简化展示（前端使用）"""

    primary_archetype: str  # 主原型名称
    primary_emoji: str      # 主原型emoji
    primary_tagline: str    # 一句话描述

    secondary_archetype: str

    summary: str            # 综合描述
    growth_tip: str         # 成长提示

    # 归因简述（用户可展开查看）
    bazi_brief: str         # "正官格+用神为财"
    zodiac_brief: str       # "太阳狮子+月亮巨蟹"
```

### 3.2 原型定义

```python
class Archetype(Enum):
    """荣格12原型"""

    INNOCENT = "innocent"
    SAGE = "sage"
    EXPLORER = "explorer"
    OUTLAW = "outlaw"
    MAGICIAN = "magician"
    HERO = "hero"
    LOVER = "lover"
    JESTER = "jester"
    REGULAR = "regular"
    CAREGIVER = "caregiver"
    RULER = "ruler"
    CREATOR = "creator"

    @property
    def chinese_name(self) -> str:
        return {
            "innocent": "天真者",
            "sage": "智者",
            "explorer": "探险家",
            "outlaw": "叛逆者",
            "magician": "魔术师",
            "hero": "英雄",
            "lover": "爱人",
            "jester": "愚者",
            "regular": "凡人",
            "caregiver": "照顾者",
            "ruler": "统治者",
            "creator": "创造者"
        }[self.value]

    @property
    def emoji(self) -> str:
        return {
            "innocent": "🌸",
            "sage": "📚",
            "explorer": "🧭",
            "outlaw": "⚡",
            "magician": "🔮",
            "hero": "⚔️",
            "lover": "💕",
            "jester": "🎭",
            "regular": "🏠",
            "caregiver": "🤗",
            "ruler": "👑",
            "creator": "🎨"
        }[self.value]

    @property
    def tagline(self) -> str:
        return {
            "innocent": "相信美好，保持纯真",
            "sage": "追求真理，启迪智慧",
            "explorer": "追寻自由，探索未知",
            "outlaw": "打破常规，推动变革",
            "magician": "洞察本质，转化现实",
            "hero": "克服困难，证明价值",
            "lover": "追求连接，创造亲密",
            "jester": "活在当下，带来欢乐",
            "regular": "脚踏实地，归属群体",
            "caregiver": "照顾他人，无私奉献",
            "ruler": "掌控局面，承担责任",
            "creator": "表达自我，创造不朽"
        }[self.value]
```

---

## 4. API 设计

### 4.1 计算接口

```python
# POST /api/v1/vibeid/calculate
{
    "user_id": "string",
    "birth_info": {
        "year": 1990,
        "month": 8,
        "day": 15,
        "hour": 14,
        "minute": 30,
        "longitude": 116.4,
        "latitude": 39.9,
        "timezone": "Asia/Shanghai"
    },
    "options": {
        "include_full_scores": false,  # 是否返回完整12原型得分
        "include_explanation": true,   # 是否返回解释模块
        "force_recalculate": false     # 是否强制重新计算
    }
}

# Response
{
    "success": true,
    "data": {
        "display": {
            "primary_archetype": "创造者",
            "primary_emoji": "🎨",
            "primary_tagline": "表达自我，创造不朽",
            "secondary_archetype": "叛逆者",
            "summary": "你的核心原型是创造者...",
            "growth_tip": "你的成长方向是完成作品...",
            "bazi_brief": "伤官格 · 用神为财",
            "zodiac_brief": "太阳狮子 · 月亮双鱼 · 上升天蝎"
        },
        "explanation": {
            "summary": "...",
            "bazi_insight": "...",
            "zodiac_insight": "...",
            "integration_insight": "...",
            "growth_direction": "..."
        },
        "confidence": 0.85,
        "version": "v2.0"
    }
}
```

### 4.2 获取详情接口

```python
# GET /api/v1/vibeid/{user_id}/detail
# 获取完整的 VibeID 信息，包括12原型完整得分

{
    "success": true,
    "data": {
        "primary": { ... },
        "all_scores": {
            "creator": 0.42,
            "outlaw": 0.28,
            "magician": 0.15,
            ...
        },
        "bazi_detail": {
            "pattern": "伤官格",
            "useful_god": "财",
            "day_master_strength": "偏旺",
            "day_master": "丙火",
            "explanation": ["丙火生于巳月...", ...]
        },
        "zodiac_detail": {
            "sun": {"sign": "狮子座", "archetype": "ruler"},
            "moon": {"sign": "双鱼座", "archetype": "innocent"},
            "ascendant": {"sign": "天蝎座", "archetype": "magician"},
            "venus": {"sign": "处女座", "archetype": "caregiver"},
            "mars": {"sign": "白羊座", "archetype": "hero"}
        }
    }
}
```

---

## 5. 实现路线图

### Phase 1: 基础升级（Week 1-2）

- [ ] 实现日主强弱计算模块
- [ ] 实现用神喜忌判断模块
- [ ] 升级八字原型映射表（格局+用神组合）
- [ ] 单元测试覆盖

### Phase 2: 五点模型（Week 3）

- [ ] 扩展星座原型映射（月亮/上升/金星/火星）
- [ ] 实现五点综合计算
- [ ] 与现有 ZodiacCalculator 集成

### Phase 3: 融合算法（Week 4）

- [ ] 实现八字主导的融合策略
- [ ] 实现一致性检查和奖励/惩罚机制
- [ ] 实现置信度计算

### Phase 4: 可解释性（Week 5）

- [ ] 实现解释生成模块
- [ ] 实现成长方向建议
- [ ] 前端展示适配

### Phase 5: 测试与优化（Week 6）

- [ ] 端到端测试
- [ ] 用户反馈收集
- [ ] 算法参数微调

---

## 6. 附录

### 6.1 八字格局完整映射表

| 格局 | 用神为财 | 用神为官杀 | 用神为印 | 用神为食伤 | 用神为比劫 |
|------|----------|------------|----------|------------|------------|
| 正官格 | Ruler+Caregiver | Ruler+Hero | Sage+Ruler | Creator+Ruler | Regular+Ruler |
| 七杀格 | Hero+Explorer | Outlaw+Hero | Hero+Sage | Outlaw+Creator | Hero+Regular |
| 正印格 | Caregiver+Sage | Sage+Ruler | Sage+Innocent | Creator+Sage | Caregiver+Regular |
| 偏印格 | Magician+Explorer | Magician+Sage | Sage+Magician | Creator+Outlaw | Outlaw+Magician |
| 食神格 | Creator+Lover | Magician+Creator | Sage+Creator | Creator+Jester | Jester+Creator |
| 伤官格 | Creator+Outlaw | Outlaw+Hero | Magician+Creator | Creator+Outlaw | Outlaw+Explorer |
| 正财格 | Regular+Lover | Ruler+Regular | Sage+Caregiver | Creator+Regular | Regular+Caregiver |
| 偏财格 | Explorer+Jester | Explorer+Ruler | Magician+Explorer | Jester+Creator | Jester+Lover |
| 比肩格 | Explorer+Hero | Hero+Outlaw | Sage+Explorer | Creator+Explorer | Regular+Hero |
| 劫财格 | Outlaw+Explorer | Hero+Outlaw | Magician+Outlaw | Jester+Outlaw | Outlaw+Hero |

### 6.2 星座五点映射完整表

| 星座 | 太阳(Core) | 月亮(Inner) | 上升(Outer) | 金星(Love) | 火星(Action) |
|------|------------|-------------|-------------|------------|--------------|
| 白羊 | Hero | Hero | Hero | Hero | Hero |
| 金牛 | Lover | Lover | Regular | Lover | Regular |
| 双子 | Jester | Jester | Jester | Jester | Magician |
| 巨蟹 | Caregiver | Caregiver | Caregiver | Caregiver | Caregiver |
| 狮子 | Ruler | Creator | Ruler | Creator | Ruler |
| 处女 | Sage | Caregiver | Sage | Caregiver | Sage |
| 天秤 | Lover | Lover | Lover | Lover | Lover |
| 天蝎 | Magician | Magician | Magician | Magician | Magician |
| 射手 | Explorer | Explorer | Explorer | Explorer | Explorer |
| 摩羯 | Ruler | Ruler | Ruler | Ruler | Hero |
| 水瓶 | Outlaw | Outlaw | Outlaw | Outlaw | Outlaw |
| 双鱼 | Innocent | Innocent | Innocent | Innocent | Innocent |

### 6.3 原型一致性矩阵

```
           Hero  Ruler  Sage  Care  Creat Outl  Magi  Lover Jest  Regu  Inno  Expl
Hero        -     +      0     0     0     +     +     0     0     0     -     +
Ruler       +     -      +     +     0     -     +     0     0     +     0     0
Sage        0     +      -     +     +     0     +     0     -     +     0     0
Caregiver   0     +      +     -     0     0     0     +     0     +     +     -
Creator     0     0      +     0     -     +     +     +     +     0     0     +
Outlaw      +     -      0     0     +     -     +     0     +     -     0     +
Magician    +     +      +     0     +     +     -     0     0     0     0     0
Lover       0     0      0     +     +     0     0     -     +     +     +     0
Jester      0     0      -     0     +     +     0     +     -     +     +     +
Regular     0     +      +     +     0     -     0     +     +     -     +     0
Innocent    -     0      0     +     0     0     0     +     +     +     -     0
Explorer    +     0      0     -     +     +     0     0     +     0     0     -

+ = 相近 (similar)
- = 对立 (conflict)
0 = 中性 (neutral)
```

---

## 7. 变更历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-01-10 | 初始版本，基础映射设计 |
| v2.0 | 2026-01-16 | 深度优化：中等深度八字计算、五点星盘模型、八字主导融合、可解释性模块 |
