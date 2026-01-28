# VibeProfile - 用户画像数据层

> Version: 3.0 | 三层架构：Identity + Skills + Vibe
> Updated: 2026-01-22

---

## 1. 概述

VibeProfile 是 VibeLife 用户数据的**画像层**，采用三层架构设计。

### 核心理念

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

### 设计原则

| 原则 | 说明 |
|------|------|
| **三层分离** | Identity / Skills / Vibe 职责清晰 |
| **Skills 是原始数据** | 每个 Skill 存自己的数据，互不干扰 |
| **Vibe 是共享洞察** | 跨 Skill 共享，所有 Skill 都可读取 |
| **Vibe 双来源** | 抽取（activities）+ 同步（skills） |
| **Single JSONB** | 画像数据一张表 (`unified_profiles.profile`) |

---

## 2. 数据结构

### 2.1 完整 Profile Schema

```json
{
  "identity": {
    "display_name": "用户名",
    "birth_info": {
      "date": "1990-01-01",
      "time": "12:00",
      "location": "北京",
      "timezone": "Asia/Shanghai",
      "gender": "male"
    }
  },

  "skills": {
    "bazi": {
      "chart": { "year": {...}, "month": {...}, "day": {...}, "hour": {...} },
      "dayun": { "current": {...}, "periods": [...] },
      "features": { "daymaster": "甲木", "strength": "strong", "pattern": "..." }
    },
    "zodiac": {
      "chart": { "sun": "Aries", "moon": "Leo", "ascendant": "Virgo", ... },
      "houses": [...],
      "aspects": [...]
    },
    "tarot": {
      "last_reading": { "spread": "celtic_cross", "cards": [...], "date": "..." }
    },
    "lifecoach": {
      "north_star": {
        "vision_scene": "3年后的理想场景",
        "anti_vision_scene": "不改变的后果",
        "pain_points": ["持续的不满1", "持续的不满2"],
        "vision_timeframe": "3年后"
      },
      "identity": {
        "current": "我是那种会拖延的人",
        "target": "我是那种说到做到的人"
      },
      "goals": [
        {
          "id": "goal_001",
          "title": "完成写作项目",
          "category": "career",
          "status": "in_progress",
          "progress": 0.6,
          "year": 2026,
          "created_at": "2026-01-10T08:00:00Z",
          "milestones": [
            { "id": "m1", "title": "完成大纲", "completed": true }
          ]
        }
      ],
      "current": {
        "week": {
          "week_start": "2026-01-20",
          "rocks": [{ "id": "...", "task": "周大石头", "status": "pending" }]
        },
        "daily": {
          "date": "2026-01-22",
          "levers": [{ "id": "...", "task": "每日杠杆", "status": "pending" }]
        },
        "month": {
          "id": "boss_001",
          "title": "月度Boss",
          "month": "2026-01",
          "progress": 0.7
        }
      },
      "progress": {
        "current_streak": 7,
        "longest_streak": 14,
        "total_checkins": 50,
        "last_checkin_date": "2026-01-21"
      }
    }
  },

  "vibe": {
    "insight": {
      "essence": {
        "archetype": {
          "primary": "creator",
          "secondary": "explorer",
          "shadow": "ruler"
        },
        "traits": [
          { "source": "bazi", "trait": "表达力强" },
          { "source": "zodiac", "trait": "好奇心旺" }
        ]
      },
      "dynamic": {
        "emotion": { "current": "calm", "intensity": 0.6 },
        "energy": { "level": 0.7, "focus": ["career"] },
        "active_archetype": "creator",
        "trend": {
          "archetype_shift": { "rising": "pioneer", "delta": 0.05 },
          "emotion_trend": "stable",
          "direction": "expansion"
        }
      },
      "pattern": {
        "behaviors": [
          { "pattern": "晚间活跃", "confidence": 0.8 },
          { "pattern": "周期性低落", "trigger": "周一" }
        ],
        "insights": [
          "你在压力下倾向于独处思考",
          "创意灵感常在深夜涌现"
        ]
      },
      "updated_at": "2026-01-22T03:00:00Z"
    },
    "target": {
      "north_star": {},
      "goals": [],
      "focus": {
        "primary": "career",
        "secondary": ["growth"],
        "active_goal": "goal_001",
        "heat_map": { "career": 0.8, "growth": 0.5, "health": 0.2 }
      },
      "milestones": {
        "achieved": [],
        "streak": { "current": 7, "best": 14 },
        "moments": []
      },
      "updated_at": "2026-01-22T03:00:00Z"
    },
    "relationship": {
      "relationships": [
        {
          "id": "rel_001",
          "name": "小明",
          "type": "romantic",
          "birth_info": {
            "date": "1992-03-15",
            "time": "08:30",
            "place": "上海",
            "timezone": "Asia/Shanghai"
          },
          "synastry": {
            "zodiac": {
              "overall_score": 78,
              "categories": [
                { "name": "沟通", "score": 82 },
                { "name": "情感", "score": 75 },
                { "name": "吸引力", "score": 80 },
                { "name": "价值观": 76 }
              ],
              "aspects": [
                {
                  "person1_planet": "太阳",
                  "person2_planet": "月亮",
                  "aspect_type": "trine",
                  "aspect_name": "三分相",
                  "influence": "positive"
                }
              ],
              "strengths": ["情感共鸣强", "沟通顺畅"],
              "challenges": ["需要更多独处空间"],
              "advice": "珍惜这份默契，用心经营关系",
              "calculated_at": "2026-01-22T10:00:00Z"
            }
          },
          "created_at": "2026-01-20T08:00:00Z",
          "last_synastry_at": "2026-01-22T10:00:00Z"
        }
      ],
      "updated_at": "2026-01-22T10:00:00Z"
    }
  },

  "preferences": {
    "voice_mode": "warm",
    "language": "zh-CN",
    "timezone": "Asia/Shanghai",
    "subscribed_skills": {
      "bazi": { "status": "subscribed", "push_enabled": true },
      "zodiac": { "status": "subscribed", "push_enabled": true }
    },
    "push_settings": {
      "default_push_hour": 8,
      "quiet_start_hour": 22,
      "quiet_end_hour": 7
    }
  }
}
```

### 2.2 Layer 说明

#### Layer 1: Identity（基础信息）

| 字段 | 说明 | 来源 |
|------|------|------|
| `display_name` | 显示名称 | 用户填写 |
| `birth_info` | 出生信息 | 用户填写 |

#### Layer 2: Skills（Skill 原始数据）

| Skill | 存储内容 | 写入时机 |
|-------|---------|---------|
| `bazi` | chart, dayun, features | 排盘时 |
| `zodiac` | chart, houses, aspects | 排盘时 |
| `tarot` | last_reading | 每次占卜后 |
| `lifecoach` | north_star, goals, current, progress | 协议完成后 |
| `mindfulness` | sessions, streaks | 冥想后 |

#### Layer 3: Vibe（共享深度信息）

| 字段 | 说明 | 来源 |
|------|------|------|
| `vibe.insight` | 我是谁（本质+动态+规律） | ProfileExtractor 融合生成 |
| `vibe.target` | 我要成为谁（目标+聚焦+里程碑） | 抽取 + 同步自 skills |
| `vibe.relationship` | 我与他人（关系对象+合盘洞察） | Synastry Skill 写入 |

---

## 3. 数据流

### 3.1 写入流

```
用户交互
    │
    ├─► Bazi Skill ─────────► skills.bazi
    │   （排盘计算）
    │
    ├─► Zodiac Skill ───────► skills.zodiac
    │   （排盘计算）
    │
    ├─► Lifecoach Skill ────► skills.lifecoach
    │   （协议对话）              ├─ north_star
    │                            ├─ goals
    │                            ├─ current
    │                            └─ progress
    │
    ▼
Activities (conversations/messages)
    │
    ▼ (每日凌晨 3 点)
    │
┌────────────────────────────────────────────────────────────────┐
│  ProfileExtractor                                               │
│  ───────────────────────────────────────────────────────────── │
│                                                                 │
│  输入：                                                         │
│  • activities (对话记录)                                        │
│  • skills.bazi.chart (命盘)                                    │
│  • skills.zodiac.chart (星盘)                                  │
│  • skills.lifecoach.goals (目标)                               │
│                                                                 │
│  处理：                                                         │
│  • 融合生成 vibe.insight（本质+动态+规律）                      │
│  • 同步+抽取 vibe.target（目标+聚焦+里程碑）                    │
│                                                                 │
│  输出：                                                         │
│  • vibe.insight                                                │
│  • vibe.target                                                 │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 读取流

```
Chat（对话）
    │
    ├─ 读取 identity.birth_info（所有 Skill 共享）
    ├─ 读取 skills.{skill_id}（当前 Skill 专属）
    ├─ 读取 vibe.insight（共享洞察）
    └─ 读取 vibe.target（共享目标）

Me 页面
    │
    └─ 读取 vibe.insight（展示三维画像）

Journey 页面
    │
    ├─ 读取 skills.lifecoach（原始数据）
    └─ 读取 vibe.target（聚焦+里程碑）

Proactive（主动推送）
    │
    ├─ 读取 vibe.insight.dynamic（情绪/能量）
    └─ 读取 vibe.target.focus（当前聚焦）
```

---

## 4. VibeInsight 三维模型

### 4.1 维度 1: 本质 (Essence) — 我是什么

**静态层：先天倾向**

来源：`skills.bazi` + `skills.zodiac`

```json
{
  "archetype": {
    "primary": "creator",
    "secondary": "explorer",
    "shadow": "ruler"
  },
  "traits": [
    { "source": "bazi", "trait": "表达力强" },
    { "source": "zodiac", "trait": "好奇心旺" }
  ]
}
```

### 4.2 维度 2: 动态 (Dynamic) — 我现在怎么样

**动态层：当前状态 + 变化趋势**

来源：对话抽取（ProfileExtractor）

```json
{
  "emotion": { "current": "calm", "intensity": 0.6 },
  "energy": { "level": 0.7, "focus": ["career"] },
  "active_archetype": "creator",
  "trend": {
    "archetype_shift": { "rising": "pioneer", "delta": 0.05 },
    "emotion_trend": "stable",
    "direction": "expansion"
  }
}
```

### 4.3 维度 3: 规律 (Pattern) — 我的行为模式

**洞察层：长期规律**

来源：历史行为分析

```json
{
  "behaviors": [
    { "pattern": "晚间活跃", "confidence": 0.8 },
    { "pattern": "周期性低落", "trigger": "周一" }
  ],
  "insights": [
    "你在压力下倾向于独处思考",
    "创意灵感常在深夜涌现"
  ]
}
```

---

## 5. VibeTarget 三维模型

### 5.1 维度 1: 目标 (Goals) — 我想要什么

来源：同步自 `skills.lifecoach.goals` + 对话抽取

```json
{
  "goals": [
    {
      "id": "goal_001",
      "title": "完成写作项目",
      "source": "lifecoach",
      "status": "in_progress",
      "progress": 0.6
    }
  ]
}
```

### 5.2 维度 2: 聚焦 (Focus) — 我现在关注什么

来源：话题热度 + 目标活跃度

```json
{
  "primary": "career",
  "secondary": ["growth"],
  "active_goal": "goal_001",
  "heat_map": {
    "career": 0.8,
    "growth": 0.5,
    "health": 0.2
  }
}
```

### 5.3 维度 3: 里程碑 (Milestones) — 我走过了什么

来源：同步自 `skills.lifecoach.progress`

```json
{
  "achieved": [
    { "goal_id": "...", "title": "...", "achieved_at": "..." }
  ],
  "streak": { "current": 7, "best": 14 },
  "moments": [
    { "date": "...", "event": "首次公开分享写作" }
  ]
}
```

---

## 6. VibeRelationship — 我与他人

**第三维度**：记录用户与重要他人的关系洞察。

### 6.1 设计理念

| 问题 | vibeRelationship 如何解决 |
|------|-------------------------|
| 合盘结果看完就没了 | 持久存储，随时回顾 |
| 想看和某人的相处建议 | 直接读取，无需重新计算 |
| AI 不知道我的关系背景 | 对话时可引用关系洞察 |
| 多次合盘结果分散 | 统一存储，形成关系档案 |

### 6.2 数据结构

```json
{
  "relationships": [
    {
      "id": "rel_001",
      "name": "小明",
      "type": "romantic",
      "birth_info": {
        "date": "1992-03-15",
        "time": "08:30",
        "place": "上海",
        "timezone": "Asia/Shanghai"
      },
      "synastry": {
        "zodiac": {
          "overall_score": 78,
          "categories": [
            { "name": "沟通", "score": 82, "description": "沟通顺畅，容易理解彼此" },
            { "name": "情感", "score": 75, "description": "情感表达方式不同，需要学习理解" },
            { "name": "吸引力", "score": 80, "description": "相互吸引，有化学反应" },
            { "name": "价值观", "score": 76, "description": "价值观相近，目标一致" }
          ],
          "aspects": [
            {
              "person1_planet": "太阳",
              "person2_planet": "月亮",
              "aspect_type": "trine",
              "aspect_name": "三分相",
              "orb": 2.5,
              "influence": "positive",
              "description": "你的太阳三分相对方的月亮"
            }
          ],
          "strengths": ["情感共鸣强", "沟通顺畅"],
          "challenges": ["需要更多独处空间"],
          "advice": "珍惜这份默契，用心经营关系",
          "calculated_at": "2026-01-22T10:00:00Z"
        }
      },
      "created_at": "2026-01-20T08:00:00Z",
      "last_synastry_at": "2026-01-22T10:00:00Z"
    }
  ],
  "updated_at": "2026-01-22T10:00:00Z"
}
```

### 6.3 关系类型

| 类型 | 说明 | 分析侧重 |
|------|------|---------|
| `romantic` | 恋人/约会对象 | 激情、情感、沟通 |
| `spouse` | 配偶/伴侣 | 稳定性、成长、默契 |
| `parent_child` | 亲子 | 理解、沟通、教育 |
| `sibling` | 兄弟姐妹 | 互补、竞争、支持 |
| `business` | 合伙人/同事 | 互补、信任、决策 |
| `friend` | 朋友 | 相容性、趣味、支持 |

### 6.4 合盘维度（可扩展）

| 维度 | 来源 Skill | 分析内容 |
|------|-----------|---------|
| `zodiac` | zodiac | 星座相位、元素兼容、行星互动 |
| `bazi` | bazi | 八字合婚、日主生克、五行互补（Phase 2） |
| `jungastro` | jungastro | 依附风格、心理投射、成长机会（Phase 3） |

### 6.5 用户价值场景

**场景 1：日常对话中引用**

> 用户：最近和小明又吵架了
> AI：（读取 vibeRelationship）我记得你们的沟通方式有时会不同步。上次合盘分析建议你们在重大决策前给彼此冷静时间。这次是类似的情况吗？

**场景 2：快速回顾**

> 用户：我和小明的合盘结果是什么来着？
> AI：你们综合契合度 78%，属于「默契组合」级别。最大的亮点是情感共鸣强，需要注意的是都比较敏感，要给彼此空间。

**场景 3：关系成长追踪**（后期功能）

> 用户：我觉得最近和小明相处好多了
> AI：太好了！你们上次合盘是3个月前，要不要重新分析一下，看看关系有什么变化？

---

## 7. 数据访问

### 6.1 Repository API

```python
class UnifiedProfileRepository:
    """唯一数据访问层"""

    # ─────────────────────────────────────────────────────────────
    # 读取
    # ─────────────────────────────────────────────────────────────
    async def get_profile(user_id: UUID) -> Dict
    async def get_identity(user_id: UUID) -> Dict
    async def get_skill_data(user_id: UUID, skill_id: str) -> Dict
    async def get_vibe_insight(user_id: UUID) -> Dict
    async def get_vibe_target(user_id: UUID) -> Dict
    async def get_preferences(user_id: UUID) -> Dict

    # ─────────────────────────────────────────────────────────────
    # 写入（Layer 1: Identity）
    # ─────────────────────────────────────────────────────────────
    async def update_identity(user_id: UUID, identity: Dict)
    async def update_birth_info(user_id: UUID, birth_info: Dict)

    # ─────────────────────────────────────────────────────────────
    # 写入（Layer 2: Skills）
    # ─────────────────────────────────────────────────────────────
    async def update_skill_data(user_id: UUID, skill_id: str, data: Dict)
    async def merge_skill_data(user_id: UUID, skill_id: str, data: Dict)

    # ─────────────────────────────────────────────────────────────
    # 写入（Layer 3: Vibe）- 仅 ProfileExtractor 使用
    # ─────────────────────────────────────────────────────────────
    async def update_vibe_insight(user_id: UUID, insight: Dict)
    async def update_vibe_target(user_id: UUID, target: Dict)

    # ─────────────────────────────────────────────────────────────
    # VibeRelationship（关系管理）
    # ─────────────────────────────────────────────────────────────
    async def get_vibe_relationships(user_id: UUID) -> List[Dict]
    async def get_vibe_relationship(user_id: UUID, rel_id: str) -> Dict
    async def add_vibe_relationship(user_id: UUID, relationship: Dict) -> str
    async def update_vibe_relationship(user_id: UUID, rel_id: str, data: Dict)
    async def delete_vibe_relationship(user_id: UUID, rel_id: str)
    async def save_synastry_insight(user_id: UUID, rel_id: str, skill_id: str, insight: Dict)

    # ─────────────────────────────────────────────────────────────
    # 写入（Preferences）
    # ─────────────────────────────────────────────────────────────
    async def update_preferences(user_id: UUID, preferences: Dict)
```

### 6.2 Prompt Builder 读取逻辑

```python
def _build_profile_context(self, profile: Dict, skill_id: str) -> str:
    """构建 Profile 上下文注入到 System Prompt"""
    parts = []

    # Layer 1: Identity（所有 Skill 共享）
    identity = profile.get("identity", {})
    if identity.get("birth_info"):
        parts.append(format_birth_info(identity["birth_info"]))

    # Layer 2: Skill 专属数据
    skill_data = profile.get("skills", {}).get(skill_id, {})
    if skill_data:
        parts.append(f"## {skill_id} 数据\n{json.dumps(skill_data)}")

    # Layer 3: Vibe 共享深度信息（所有 Skill 可读）
    vibe = profile.get("vibe", {})
    if vibe.get("insight"):
        parts.append(f"## 用户画像\n{format_insight(vibe['insight'])}")
    if vibe.get("target"):
        parts.append(f"## 用户目标\n{format_target(vibe['target'])}")

    return "\n".join(parts)
```

---

## 7. 迁移

### 7.1 字段映射

| 旧字段 | 新字段 | 说明 |
|--------|--------|------|
| `skill_data.bazi` | `skills.bazi` | 重命名 |
| `skill_data.zodiac` | `skills.zodiac` | 重命名 |
| `life_context._paths.lifecoach.content` | `skills.lifecoach` | 移动 |
| `extracted.goals` | `vibe.target.goals` | 移动 |
| `state.focus` | `vibe.target.focus` | 移动 |
| `extracted.facts` | `vibe.insight.pattern.facts` | 移动 |
| `extracted.concerns` | `vibe.insight.pattern.concerns` | 移动 |

### 7.2 废弃的字段

- `life_context._paths` - 整个结构废弃
- `extracted.goals` - 移到 vibe.target
- `state.focus` - 移到 vibe.target.focus
- `state.emotion` - 移到 vibe.insight.dynamic

---

## 8. 与北极星对齐

| 北极星 | 实现 |
|--------|------|
| **深度理解** | VibeInsight 三维模型（本质 + 动态 + 规律） |
| **主动关心** | Proactive 读取 vibe.insight.dynamic + vibe.target.focus |
| **无限扩展** | Skills 按领域划分，数据隔离 |
| **温暖不粘腻** | VibeTarget 默认不加命理判断 |

---

## 附录：版本历史

- **v3.1** (2026-01-22): 新增 VibeRelationship
  - 新增 vibe.relationship 维度（与 insight/target 并列）
  - 支持关系对象管理和合盘洞察存储
  - 新增 Repository API: get_vibe_relationships, add_vibe_relationship, save_synastry_insight 等

- **v3.0** (2026-01-22): 三层架构重构
  - Identity + Skills + Vibe 三层分离
  - 废弃 life_context._paths 结构
  - 废弃 extracted.goals，移到 vibe.target
  - 新增 vibe.insight 和 vibe.target 共享深度信息

- **v2.3** (2026-01-19): UserDataSpace 统一管理
- **v2.0** (2026-01-15): WHO/WHAT 分离
- **v1.0** (2026-01-01): 初始版本
