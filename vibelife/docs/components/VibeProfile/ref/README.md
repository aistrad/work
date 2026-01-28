# VibeProfile

用户画像数据层，三层架构：Identity + Skills + Vibe。

## 核心架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      VibeProfile 三层架构                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Identity（基础信息）                                   │
│  ────────────────────────────────────────────────────────────   │
│  来源：用户填写                                                  │
│  内容：birth_info, display_name, preferences                    │
│                                                                  │
│  Layer 2: Skills（Skill 原始数据）                              │
│  ────────────────────────────────────────────────────────────   │
│  来源：各 Skill 实时写入                                        │
│  内容：bazi.chart, zodiac.chart, lifecoach.{...}, tarot.{...}  │
│                                                                  │
│  Layer 3: Vibe（共享深度信息）← 核心创新                        │
│  ────────────────────────────────────────────────────────────   │
│  来源：抽取（activities）+ 同步（skills）                        │
│  内容：vibe.insight + vibe.target                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 快速开始

```python
from stores.unified_profile_repo import UnifiedProfileRepository

# 读取
profile = await UnifiedProfileRepository.get_profile(user_id)

# Layer 1: Identity
birth_info = profile["identity"]["birth_info"]

# Layer 2: Skills
bazi_chart = profile["skills"]["bazi"]["chart"]
lifecoach_goals = profile["skills"]["lifecoach"]["goals"]

# Layer 3: Vibe（共享深度信息）
insight = profile["vibe"]["insight"]  # 我是谁
target = profile["vibe"]["target"]    # 我要成为谁
```

## 数据结构

```yaml
profile:
  # Layer 1: Identity
  identity:
    display_name: "用户名"
    birth_info: { date, time, location }

  # Layer 2: Skills（各 Skill 原始数据）
  skills:
    bazi: { chart, dayun }
    zodiac: { chart }
    tarot: { last_reading }
    lifecoach:
      north_star: { vision_scene, anti_vision_scene, pain_points }
      goals: []
      current: { week, daily, month }
      progress: { current_streak, longest_streak }

  # Layer 3: Vibe（共享深度信息）
  vibe:
    insight:  # 我是谁（ProfileExtractor 融合生成）
      essence: { archetype, traits }
      dynamic: { emotion, energy, trend }
      pattern: { behaviors, insights }
    target:   # 我要成为谁（抽取 + 同步）
      north_star: {}     # 同步自 skills.lifecoach.north_star
      goals: []          # 同步自 skills.lifecoach.goals + 抽取
      focus: {}          # 计算得出
      milestones: {}     # 同步自 skills.lifecoach.progress

  # 用户偏好
  preferences:
    timezone: "Asia/Shanghai"
    voice_mode: "warm"
    subscribed_skills: {}
```

## 数据流

```
用户交互
    │
    ├─► Bazi Skill ─────► skills.bazi.chart
    ├─► Zodiac Skill ───► skills.zodiac.chart
    ├─► Lifecoach ──────► skills.lifecoach.{north_star,goals}
    │
    ▼
Activities (conversations/messages)
    │
    ▼ (每日凌晨，ProfileExtractor)
    │
┌───────────────────────────────────────────┐
│  ProfileExtractor                          │
│  ──────────────────────────────────────── │
│  输入：activities + skills.*               │
│  输出：vibe.insight + vibe.target         │
└───────────────────────────────────────────┘
```

## 文档

- [SPEC.md](./SPEC.md) - 完整设计
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 架构图
