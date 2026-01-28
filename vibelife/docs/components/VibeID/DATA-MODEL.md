# VibeID 数据模型 v7.0

> Version: 7.0 | 2026-01-19

## 1. 概述

VibeID v7 将数据从 `skill_data.vibe_id` 提升到 `unified_profiles.vibe_id`，成为用户身份的核心字段。

## 2. 数据结构

### 2.1 unified_profiles.vibe_id

```json
{
  "vibe_id": {
    "version": "7.0",
    "calculated_at": "2026-01-19T00:00:00Z",
    "updated_at": "2026-01-19T14:30:00Z",

    // ═══════════════════════════════════════════════════════════
    // 简化呈现（默认展示）
    // ═══════════════════════════════════════════════════════════
    "primary_archetype": "Explorer",
    "archetype_signature": "追求自由的智者，内心渴望连接",

    // ═══════════════════════════════════════════════════════════
    // 四维原型（深度探索）
    // ═══════════════════════════════════════════════════════════
    "dimensions": {
      "core": {
        "archetype": "Explorer",
        "secondary": "Sage",
        "confidence": "high",
        "source": {
          "bazi_contribution": "Explorer",
          "bazi_pattern": "食神格",
          "bazi_useful_god": "食神",
          "zodiac_contribution": "Sage",
          "consistency_type": "similar"
        }
      },
      "inner": {
        "archetype": "Lover",
        "confidence": "high",
        "source": {
          "moon_sign": "Cancer",
          "venus_sign": "Pisces"
        }
      },
      "outer": {
        "archetype": "Sage",
        "confidence": "medium",
        "source": {
          "rising_sign": "Virgo",
          "mars_sign": "Gemini"
        }
      },
      "shadow": {
        "archetype": "Caregiver",
        "confidence": "low",
        "source": {
          "derived_from": "Explorer",
          "method": "opposing_archetype",
          "tension": "扎根 vs 流动",
          "user_confirmed": false
        }
      }
    },

    // ═══════════════════════════════════════════════════════════
    // 12原型能量分布
    // ═══════════════════════════════════════════════════════════
    "scores": {
      "Explorer": 85.0,
      "Sage": 72.0,
      "Lover": 68.0,
      "Creator": 55.0,
      "Hero": 48.0,
      "Magician": 45.0,
      "Jester": 42.0,
      "Outlaw": 38.0,
      "Innocent": 35.0,
      "Regular": 32.0,
      "Ruler": 28.0,
      "Caregiver": 25.0
    },

    // ═══════════════════════════════════════════════════════════
    // 演化历史（动态演化）
    // ═══════════════════════════════════════════════════════════
    "evolution": [
      {
        "id": "evo_001",
        "timestamp": "2026-01-19T00:00:00Z",
        "trigger": "initial_calculation",
        "snapshot": {
          "primary_archetype": "Explorer",
          "scores": {"Explorer": 85.0, "Sage": 72.0}
        },
        "delta": null,
        "insight": "首次计算，Explorer 能量显著，追求自由是你的核心驱动"
      },
      {
        "id": "evo_002",
        "timestamp": "2026-03-15T14:30:00Z",
        "trigger": "conversation",
        "snapshot": null,
        "delta": {"Hero": 2.0, "Explorer": -1.0},
        "insight": "最近的对话中，你展现了更多勇于挑战的特质"
      },
      {
        "id": "evo_003",
        "timestamp": "2026-06-19T00:00:00Z",
        "trigger": "dayun_change",
        "snapshot": {
          "primary_archetype": "Explorer",
          "scores": {"Explorer": 82.0, "Hero": 75.0}
        },
        "delta": {"Hero": 8.0, "Explorer": -3.0},
        "insight": "大运交接，Hero 能量上升，这是你展现领导力的时期"
      }
    ],

    // ═══════════════════════════════════════════════════════════
    // 来源追溯
    // ═══════════════════════════════════════════════════════════
    "sources": {
      "bazi": {
        "chart_version": "2026-01-19T00:00:00Z",
        "contribution": 0.7
      },
      "zodiac": {
        "chart_version": "2026-01-19T00:00:00Z",
        "contribution": 0.3
      }
    },

    // ═══════════════════════════════════════════════════════════
    // 沟通偏好（从原型推导）
    // ═══════════════════════════════════════════════════════════
    "communication_preferences": {
      "style": "open_exploration",
      "likes": ["开放式探索", "多种可能性", "深度分析"],
      "dislikes": ["过于结构化", "限制性建议", "说教"],
      "tone": "curious_warm"
    }
  }
}
```

### 2.2 字段说明

#### 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| version | string | 是 | 数据版本 |
| calculated_at | string | 是 | 首次计算时间 (ISO 8601) |
| updated_at | string | 是 | 最后更新时间 (ISO 8601) |
| primary_archetype | string | 是 | 主原型 ID |
| archetype_signature | string | 是 | 人格金句 |
| dimensions | object | 是 | 四维原型详情 |
| scores | object | 是 | 12原型能量分布 |
| evolution | array | 是 | 演化历史 |
| sources | object | 是 | 来源追溯 |
| communication_preferences | object | 否 | 沟通偏好 |

#### dimensions 字段

每个维度包含：

| 字段 | 类型 | 说明 |
|-----|------|------|
| archetype | string | 原型 ID |
| secondary | string | 副原型 ID (仅 core 有) |
| confidence | string | 置信度: high/medium/low |
| source | object | 来源信息 |

#### evolution 字段

每条演化记录包含：

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | string | 记录 ID |
| timestamp | string | 时间戳 (ISO 8601) |
| trigger | string | 触发类型: initial_calculation/conversation/dayun_change/birthday/user_request |
| snapshot | object | 快照 (周期驱动时保存) |
| delta | object | 变化量 (对话驱动时保存) |
| insight | string | 洞察文本 |

---

## 3. 与其他字段的关系

### 3.1 unified_profiles 完整结构

```json
{
  "user_id": "uuid",

  // VibeID - 用户身份核心 (v7 新增顶层字段)
  "vibe_id": { ... },

  // Profile - Hot Memory (原有)
  "profile": {
    "facts": {
      "birth_info": {
        "date": "1990-01-15",
        "time": "14:30",
        "location": "北京"
      }
    },
    "state": {
      "current_emotion": "curious",
      "current_focus": "career"
    },
    "preferences": {
      "timezone": "Asia/Shanghai",
      "language": "zh-CN"
    }
  },

  // Skill Data - 各 Skill 专属数据 (原有)
  "skill_data": {
    "bazi": {
      "chart": { ... },
      "calculated_at": "..."
    },
    "zodiac": {
      "chart": { ... },
      "calculated_at": "..."
    }
    // 注意: vibe_id 不再放在这里
  },

  // Insights - Cold Memory (原有)
  "insights": {
    "discovery": [ ... ],
    "pattern": [ ... ],
    "growth": [ ... ]  // 与 vibe_id.evolution 联动
  }
}
```

### 3.2 数据依赖关系

```
profile.facts.birth_info
        │
        ▼
┌───────────────────────────────────────┐
│           计算依赖                     │
│  skill_data.bazi.chart ──┐            │
│                          ├──> vibe_id │
│  skill_data.zodiac.chart ┘            │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│           联动关系                     │
│  vibe_id.evolution ←→ insights.growth │
│  vibe_id.communication_preferences    │
│       ←→ profile.preferences          │
└───────────────────────────────────────┘
```

---

## 4. 索引设计

### 4.1 PostgreSQL 索引

```sql
-- 主原型索引（用于统计分析）
CREATE INDEX idx_unified_profiles_primary_archetype
ON unified_profiles ((vibe_id->>'primary_archetype'));

-- 演化时间索引（用于查询演化历史）
CREATE INDEX idx_unified_profiles_vibe_id_updated
ON unified_profiles ((vibe_id->>'updated_at'));
```

### 4.2 查询示例

```sql
-- 查询所有 Explorer 原型用户
SELECT user_id, vibe_id->>'archetype_signature' as signature
FROM unified_profiles
WHERE vibe_id->>'primary_archetype' = 'Explorer';

-- 查询最近有演化的用户
SELECT user_id, vibe_id->>'updated_at' as last_evolution
FROM unified_profiles
WHERE (vibe_id->>'updated_at')::timestamp > NOW() - INTERVAL '7 days';

-- 统计原型分布
SELECT
  vibe_id->>'primary_archetype' as archetype,
  COUNT(*) as count
FROM unified_profiles
WHERE vibe_id IS NOT NULL
GROUP BY vibe_id->>'primary_archetype'
ORDER BY count DESC;
```

---

## 5. 数据验证

### 5.1 JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "calculated_at", "updated_at", "primary_archetype", "archetype_signature", "dimensions", "scores", "evolution", "sources"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$"
    },
    "calculated_at": {
      "type": "string",
      "format": "date-time"
    },
    "updated_at": {
      "type": "string",
      "format": "date-time"
    },
    "primary_archetype": {
      "type": "string",
      "enum": ["Innocent", "Explorer", "Sage", "Hero", "Outlaw", "Magician", "Regular", "Lover", "Jester", "Caregiver", "Creator", "Ruler"]
    },
    "archetype_signature": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "dimensions": {
      "type": "object",
      "required": ["core", "inner", "outer", "shadow"],
      "properties": {
        "core": { "$ref": "#/definitions/dimension" },
        "inner": { "$ref": "#/definitions/dimension" },
        "outer": { "$ref": "#/definitions/dimension" },
        "shadow": { "$ref": "#/definitions/dimension" }
      }
    },
    "scores": {
      "type": "object",
      "additionalProperties": {
        "type": "number",
        "minimum": 0,
        "maximum": 100
      }
    },
    "evolution": {
      "type": "array",
      "items": { "$ref": "#/definitions/evolution_record" }
    },
    "sources": {
      "type": "object",
      "properties": {
        "bazi": { "$ref": "#/definitions/source_info" },
        "zodiac": { "$ref": "#/definitions/source_info" }
      }
    }
  },
  "definitions": {
    "dimension": {
      "type": "object",
      "required": ["archetype", "confidence", "source"],
      "properties": {
        "archetype": { "type": "string" },
        "secondary": { "type": "string" },
        "confidence": { "type": "string", "enum": ["high", "medium", "low"] },
        "source": { "type": "object" }
      }
    },
    "evolution_record": {
      "type": "object",
      "required": ["id", "timestamp", "trigger", "insight"],
      "properties": {
        "id": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" },
        "trigger": { "type": "string", "enum": ["initial_calculation", "conversation", "dayun_change", "birthday", "user_request"] },
        "snapshot": { "type": ["object", "null"] },
        "delta": { "type": ["object", "null"] },
        "insight": { "type": "string" }
      }
    },
    "source_info": {
      "type": "object",
      "properties": {
        "chart_version": { "type": "string" },
        "contribution": { "type": "number", "minimum": 0, "maximum": 1 }
      }
    }
  }
}
```

---

## 6. 版本历史

| 版本 | 日期 | 变更 |
|-----|------|------|
| 7.0 | 2026-01-19 | 提升到顶层字段，新增 evolution、communication_preferences |
| 6.0 | 2026-01-15 | 简化数据模型，返回 Dict |
| 5.0 | 2026-01-10 | 配置驱动的融合算法 |
