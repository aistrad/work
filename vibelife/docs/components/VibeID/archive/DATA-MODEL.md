# Vibe ID 数据模型

> Version: 7.0 | 2026-01-18

---

## 概述

Vibe ID v7.0 采用全新的数据结构，从"人格分析结果"升级为"用户身份系统"。数据存储在 `unified_profiles.skill_data.vibe_id` 中。

## 完整数据结构

```yaml
# unified_profiles.skill_data.vibe_id (v7.0)

vibe_id:
  # ═══════════════════════════════════════════════════════════════════════════
  # 元数据 (Metadata)
  # ═══════════════════════════════════════════════════════════════════════════
  version: "7.0"
  created_at: "2026-01-18T10:30:00Z"
  updated_at: "2026-01-18T10:30:00Z"

  # ═══════════════════════════════════════════════════════════════════════════
  # 核心身份 (Core Identity)
  # 用户的"数字身份证"，最核心的身份标识
  # ═══════════════════════════════════════════════════════════════════════════
  identity:
    # 主原型 - 最核心的身份标识
    primary_archetype: "Explorer"        # 12原型之一 (必填)
    primary_emoji: "🧭"                  # 原型 Emoji
    primary_tagline: "探索者"            # 原型中文名
    primary_nickname: "好奇宝宝"         # 原型昵称
    primary_slogan: "好奇心驱动，追求意义，享受探索未知的旅程"

    # 副原型 (可选)
    secondary_archetype: "Sage"          # 12原型之一 (可选)
    secondary_emoji: "📚"
    secondary_tagline: "智者"

    # 置信度
    confidence: "high"                   # high | medium | low
    confidence_score: 0.92               # 0-1 数值

    # 东西方一致性
    consistency_type: "perfect_match"    # perfect_match | similar | neutral | conflict
    consistency_description: "八字与星盘指向同一原型"

  # ═══════════════════════════════════════════════════════════════════════════
  # 四维画像 (Four Dimensions)
  # 深度人格分析，展示人格的不同层面
  # ═══════════════════════════════════════════════════════════════════════════
  dimensions:
    # Core - 灵魂本质 (基于八字格局 + 太阳星座)
    core:
      archetype: "Explorer"
      emoji: "🧭"
      tagline: "探索者"
      summary: "追求自由与发现的灵魂"
      description: "你的内核是一个永不停歇的探索者，对未知充满好奇，渴望在旅途中发现生命的意义。"
      confidence: "high"
      source:
        bazi_contribution: "食神格"
        bazi_pattern: "食神格"
        bazi_useful_god: "水"
        zodiac_contribution: "射手座"
        consistency_type: "perfect_match"

    # Inner - 内在世界 (基于月亮星座 + 金星星座)
    inner:
      archetype: "Sage"
      emoji: "📚"
      tagline: "智者"
      summary: "内心渴望理解与智慧"
      description: "在内心深处，你渴望理解事���的本质，追求智慧和真理。"
      confidence: "high"
      source:
        moon_sign: "处女座"
        venus_sign: "天蝎座"

    # Outer - 外在呈现 (基于上升星座 + 火星星座)
    outer:
      archetype: "Hero"
      emoji: "⚔️"
      tagline: "英雄"
      summary: "展现勇敢与行动力"
      description: "在他人眼中，你是一个勇敢、有行动力的人，敢于迎接挑战。"
      confidence: "medium"
      source:
        rising_sign: "白羊座"
        mars_sign: "狮子座"

    # Shadow - 阴影倾向 (Core 的对立面)
    shadow:
      archetype: "Regular"
      emoji: "🏠"
      tagline: "凡人"
      summary: "害怕平庸与被束缚"
      description: "你内心深处害怕变得平庸，害怕被日常琐事束缚，失去探索的自由。"
      tension: "自由 vs 归属"
      tension_description: "在追求自由的同时，也渴望归属感，这是你需要整合的核心张力。"
      user_confirmed: false              # 用户是否确认
      source:
        derived_from: "Explorer"
        method: "opposing_archetype"

  # ═══════════════════════════════════════════════════════════════════════════
  # 能量雷达 (Energy Radar)
  # 12原型得分，用于雷达图展示
  # ═══════════════════════════════════════════════════════════════════════════
  scores:
    Explorer: 92.5
    Sage: 78.3
    Hero: 65.0
    Creator: 58.2
    Magician: 52.1
    Outlaw: 45.8
    Lover: 42.3
    Jester: 38.7
    Caregiver: 35.2
    Innocent: 28.9
    Ruler: 22.4
    Regular: 15.6

  # ═══════════════════════════════════════════════════════════════════════════
  # 性格标签 (Personality Tags)
  # 易传播的标签，用于分享卡片和社交
  # ═══════════════════════════════════════════════════════════════════════════
  tags:
    - id: "curious"
      label: "好奇宝宝"
      emoji: "🔍"
      score: 95
      category: "trait"                  # trait | strength | style

    - id: "independent"
      label: "独立自主"
      emoji: "🦅"
      score: 88
      category: "trait"

    - id: "analytical"
      label: "理性分析"
      emoji: "🧠"
      score: 82
      category: "strength"

    - id: "adventurous"
      label: "爱冒险"
      emoji: "🎢"
      score: 79
      category: "style"

    - id: "deep_thinker"
      label: "深度思考"
      emoji: "💭"
      score: 75
      category: "strength"

  # ═══════════════════════════════════════════════════════════════════════════
  # 关系倾向 (Relationship Tendency)
  # 用于配对和关系分析
  # ═══════════════════════════════════════════════════════════════════════════
  relationship:
    # 爱的语言
    love_language: "quality_time"        # quality_time | words | acts | gifts | touch
    love_language_label: "精心时刻"
    love_language_description: "你最看重的是与伴侣共度的高质量时光"

    # 依恋类型
    attachment_style: "secure"           # secure | anxious | avoidant | fearful
    attachment_label: "安全型"
    attachment_description: "你在关系中通常感到安全，能够建立健康的亲密关系"

    # 匹配原型
    best_match:                          # 最佳匹配原型
      - archetype: "Sage"
        reason: "智慧与探索的完美结合"
        compatibility: 95
      - archetype: "Creator"
        reason: "共同的创新精神"
        compatibility: 88

    growth_match:                        # 成长型匹配
      - archetype: "Caregiver"
        reason: "帮助你学会关怀与稳定"
        compatibility: 72

    challenge_match:                     # 挑战型匹配
      - archetype: "Ruler"
        reason: "控制与自由的张力"
        compatibility: 45

  # ═══════════════════════════════════════════════════════════════════════════
  # 成长方向 (Growth Direction)
  # 个人成长建议
  # ═══════════════════════════════════════════════════════════════════════════
  growth:
    direction: "从探索到智慧的整合"
    direction_description: "你的成长方向是将探索的经历转化为深刻的智慧"

    current_phase: "expansion"           # foundation | expansion | integration | mastery
    phase_label: "扩展期"
    phase_description: "当前你处于人生的扩展期，适合大胆尝试和探索"

    key_lesson: "学会在自由中建立深度连接"
    key_lesson_description: "你需要学习的核心课题是如何在保持自由的同时，建立深度的人际连接"

    superpowers:                         # 超能力
      - id: "insight"
        label: "洞察力"
        description: "能够快速看透事物本质"
      - id: "adaptability"
        label: "适应力"
        description: "在变化中游刃有余"
      - id: "innovation"
        label: "创新思维"
        description: "总能找到新的解决方案"

    growth_points:                       # 成长点
      - id: "patience"
        label: "耐心"
        description: "学会等待和坚持"
      - id: "commitment"
        label: "承诺"
        description: "在自由中学会承诺"
      - id: "depth"
        label: "深度关系"
        description: "建立更深层的人际连接"

  # ═══════════════════════════════════════════════════════════════════════════
  # 底层密码 (Underlying Code)
  # 归因数据，展示分析依据
  # ═══════════════════════════════════════════════════════════════════════════
  underlying:
    # 八字数据
    bazi:
      brief: "食神格 · 用神为水 · 身偏旺"
      pattern: "食神格"
      pattern_description: "食神格主聪明才智，追求自由表达"
      useful_god: "水"
      useful_god_description: "水为用神，利于流动、变化、智慧"
      day_master: "甲木"
      day_master_element: "木"
      day_master_strength: "偏旺"
      day_master_strength_score: 0.3     # -1 到 1

    # 星盘数据
    zodiac:
      brief: "太阳射手 · 月亮处女 · 上升白羊"
      sun_sign: "射手座"
      sun_sign_element: "火"
      moon_sign: "处女座"
      moon_sign_element: "土"
      rising_sign: "白羊座"
      rising_sign_element: "火"
      venus_sign: "天蝎座"
      mars_sign: "狮子座"

  # ═══════════════════════════════════════════════════════════════════════════
  # 解释文本 (Explanation)
  # 可读性文本，用于展示
  # ═══════════════════════════════════════════════════════════════════════════
  explanation:
    summary: "你是一个天生的探索者，内心充满好奇，渴望在旅途中发现生命的意义。你的八字食神格赋予你聪明才智和自由精神，而射手座的太阳更强化了这种探索欲望。"

    bazi_insight: "食神格的你，天生聪慧，追求自由表达。用神为水，意味着你需要流动和变化来激发潜能。"

    zodiac_insight: "太阳射手让你热爱冒险，月亮处女给你分析能力，上升白羊让你展现勇敢。"

    integration_insight: "东方命理与西方占星在你身上达成了完美一致，都指向探索者原型，这是非常罕见的。"

    growth_direction: "你的成长方向是学会在自由中建立深度连接，将探索的经历转化为智慧。"

  # ═══════════════════════════════════════════════════════════════════════════
  # 分享配置 (Share Config)
  # 分享卡片相关
  # ═══════════════════════════════════════════════════════════════════════════
  share:
    share_code: "VB7X9K"                 # 6位分享码
    card_style: "default"                # default | dark | gradient | minimal
    card_generated_at: "2026-01-18T10:30:00Z"
    card_url: "/api/v1/vibe-id/card/VB7X9K.png"

    # 邀请统计
    invite_count: 0                      # 通过此码邀请的人数
    invited_by: null                     # 邀请人的 share_code (如果有)

    # 分享文案
    share_text: "我是探索者 Vibe 🧭 好奇心驱动，追求意义，享受探索未知的旅程。来测测你的 Vibe 是什么？"

  # ═══════════════════════════════════════════════════════════════════════════
  # 计算元数据 (Calculation Metadata)
  # 记录计算过程，用于调试和版本追踪
  # ═══════════════════════════════════════════════════════════════════════════
  calculation:
    algorithm_version: "7.0"
    fusion_weights:
      bazi: 0.7
      zodiac: 0.3
    consistency_bonus: 0.15
    source_versions:
      bazi: "2026-01-18T10:29:00Z"
      zodiac: "2026-01-18T10:29:30Z"
```

## 数据结构对比 (v6 vs v7)

| 字段 | v6.0 | v7.0 | 变化 |
|------|------|------|------|
| identity | 无 | 新增 | 核心身份标识 |
| dimensions | archetypes | dimensions | 重命名，结构扩展 |
| scores | scores | scores | 保持 |
| tags | 无 | 新增 | 性格标签 |
| relationship | 无 | 新增 | 关系倾向 |
| growth | explanation.growth_direction | growth | 扩展为完整模块 |
| underlying | source | underlying | 重命名，结构扩展 |
| explanation | explanation | explanation | 保持 |
| share | 无 | 新增 | 分享配置 |
| calculation | source_versions | calculation | 扩展 |

## TypeScript 类型定义

```typescript
// types/vibe-id.ts

export type ArchetypeType =
  | 'Innocent' | 'Explorer' | 'Sage' | 'Hero'
  | 'Outlaw' | 'Magician' | 'Regular' | 'Lover'
  | 'Jester' | 'Caregiver' | 'Creator' | 'Ruler';

export type ConfidenceLevel = 'high' | 'medium' | 'low';

export type ConsistencyType = 'perfect_match' | 'similar' | 'neutral' | 'conflict';

export type LoveLanguage = 'quality_time' | 'words' | 'acts' | 'gifts' | 'touch';

export type AttachmentStyle = 'secure' | 'anxious' | 'avoidant' | 'fearful';

export type GrowthPhase = 'foundation' | 'expansion' | 'integration' | 'mastery';

export type TagCategory = 'trait' | 'strength' | 'style';

export type CardStyle = 'default' | 'dark' | 'gradient' | 'minimal';

export interface VibeIDIdentity {
  primary_archetype: ArchetypeType;
  primary_emoji: string;
  primary_tagline: string;
  primary_nickname: string;
  primary_slogan: string;
  secondary_archetype?: ArchetypeType;
  secondary_emoji?: string;
  secondary_tagline?: string;
  confidence: ConfidenceLevel;
  confidence_score: number;
  consistency_type: ConsistencyType;
  consistency_description: string;
}

export interface VibeIDDimension {
  archetype: ArchetypeType;
  emoji: string;
  tagline: string;
  summary: string;
  description: string;
  confidence: ConfidenceLevel;
  source: Record<string, string>;
}

export interface VibeIDShadow extends VibeIDDimension {
  tension: string;
  tension_description: string;
  user_confirmed: boolean;
}

export interface VibeIDDimensions {
  core: VibeIDDimension;
  inner: VibeIDDimension;
  outer: VibeIDDimension;
  shadow: VibeIDShadow;
}

export interface VibeIDTag {
  id: string;
  label: string;
  emoji: string;
  score: number;
  category: TagCategory;
}

export interface ArchetypeMatch {
  archetype: ArchetypeType;
  reason: string;
  compatibility: number;
}

export interface VibeIDRelationship {
  love_language: LoveLanguage;
  love_language_label: string;
  love_language_description: string;
  attachment_style: AttachmentStyle;
  attachment_label: string;
  attachment_description: string;
  best_match: ArchetypeMatch[];
  growth_match: ArchetypeMatch[];
  challenge_match: ArchetypeMatch[];
}

export interface GrowthItem {
  id: string;
  label: string;
  description: string;
}

export interface VibeIDGrowth {
  direction: string;
  direction_description: string;
  current_phase: GrowthPhase;
  phase_label: string;
  phase_description: string;
  key_lesson: string;
  key_lesson_description: string;
  superpowers: GrowthItem[];
  growth_points: GrowthItem[];
}

export interface VibeIDBazi {
  brief: string;
  pattern: string;
  pattern_description: string;
  useful_god: string;
  useful_god_description: string;
  day_master: string;
  day_master_element: string;
  day_master_strength: string;
  day_master_strength_score: number;
}

export interface VibeIDZodiac {
  brief: string;
  sun_sign: string;
  sun_sign_element: string;
  moon_sign: string;
  moon_sign_element: string;
  rising_sign: string;
  rising_sign_element: string;
  venus_sign?: string;
  mars_sign?: string;
}

export interface VibeIDUnderlying {
  bazi: VibeIDBazi;
  zodiac: VibeIDZodiac;
}

export interface VibeIDExplanation {
  summary: string;
  bazi_insight: string;
  zodiac_insight: string;
  integration_insight: string;
  growth_direction: string;
}

export interface VibeIDShare {
  share_code: string;
  card_style: CardStyle;
  card_generated_at: string;
  card_url: string;
  invite_count: number;
  invited_by?: string;
  share_text: string;
}

export interface VibeIDCalculation {
  algorithm_version: string;
  fusion_weights: {
    bazi: number;
    zodiac: number;
  };
  consistency_bonus: number;
  source_versions: {
    bazi?: string;
    zodiac?: string;
  };
}

export interface VibeID {
  version: string;
  created_at: string;
  updated_at: string;
  identity: VibeIDIdentity;
  dimensions: VibeIDDimensions;
  scores: Record<ArchetypeType, number>;
  tags: VibeIDTag[];
  relationship: VibeIDRelationship;
  growth: VibeIDGrowth;
  underlying: VibeIDUnderlying;
  explanation: VibeIDExplanation;
  share: VibeIDShare;
  calculation: VibeIDCalculation;
}
```

## Python 数据模型

```python
# skills/vibe_id/models.py (v7.0)

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from enum import Enum
from datetime import datetime


class Archetype(str, Enum):
    """12 原型枚举"""
    INNOCENT = "Innocent"
    EXPLORER = "Explorer"
    SAGE = "Sage"
    HERO = "Hero"
    OUTLAW = "Outlaw"
    MAGICIAN = "Magician"
    REGULAR = "Regular"
    LOVER = "Lover"
    JESTER = "Jester"
    CAREGIVER = "Caregiver"
    CREATOR = "Creator"
    RULER = "Ruler"


class ConfidenceLevel(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ConsistencyType(str, Enum):
    PERFECT_MATCH = "perfect_match"
    SIMILAR = "similar"
    NEUTRAL = "neutral"
    CONFLICT = "conflict"


class LoveLanguage(str, Enum):
    QUALITY_TIME = "quality_time"
    WORDS = "words"
    ACTS = "acts"
    GIFTS = "gifts"
    TOUCH = "touch"


class AttachmentStyle(str, Enum):
    SECURE = "secure"
    ANXIOUS = "anxious"
    AVOIDANT = "avoidant"
    FEARFUL = "fearful"


class GrowthPhase(str, Enum):
    FOUNDATION = "foundation"
    EXPANSION = "expansion"
    INTEGRATION = "integration"
    MASTERY = "mastery"


class TagCategory(str, Enum):
    TRAIT = "trait"
    STRENGTH = "strength"
    STYLE = "style"


class CardStyle(str, Enum):
    DEFAULT = "default"
    DARK = "dark"
    GRADIENT = "gradient"
    MINIMAL = "minimal"
```

## 数据迁移

由于选择"全新开始"，不需要数据迁移脚本。现有用户的 `skill_data.vibe_id` 将被新数据覆盖。

## 索引建议

```sql
-- 分享码索引 (用于快速查找)
CREATE INDEX idx_vibe_id_share_code ON unified_profiles
USING btree ((profile->'skill_data'->'vibe_id'->'share'->'share_code'));

-- 主原型索引 (用于统计和匹配)
CREATE INDEX idx_vibe_id_primary_archetype ON unified_profiles
USING btree ((profile->'skill_data'->'vibe_id'->'identity'->'primary_archetype'));
```
