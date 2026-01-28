# Vibe ID API 设计

> Version: 7.0 | 2026-01-18

---

## 概述

Vibe ID API 提供完整的身份创建、查询、分享和配对功能。所有 API 遵循 RESTful 设计原则。

## API 端点总览

| 端点 | 方法 | 认证 | 说明 |
|------|------|------|------|
| `/api/v1/vibe-id/create` | POST | 可选 | 创建 Vibe ID |
| `/api/v1/vibe-id` | GET | 必须 | 获取当前用户 Vibe ID |
| `/api/v1/vibe-id/preview` | GET | 无 | 预览 Vibe ID (不保存) |
| `/api/v1/vibe-id/recalculate` | POST | 必须 | 重新计算 Vibe ID |
| `/api/v1/vibe-id/card/{share_code}.png` | GET | 无 | 获取分享卡片图片 |
| `/api/v1/vibe-id/card/generate` | POST | 必须 | 生成分享卡片 |
| `/api/v1/vibe-id/invite/{share_code}` | GET | 无 | 获取邀请信息 |
| `/api/v1/vibe-id/match` | POST | 必须 | 计算配对 |
| `/api/v1/vibe-id/archetypes` | GET | 无 | 获取12原型定义 |
| `/api/v1/vibe-id/archetypes/{id}` | GET | 无 | 获取单个原型详情 |
| `/api/v1/vibe-id/claim` | POST | 必须 | 认领临时 Vibe ID |

---

## 详细 API 定义

### 1. 创建 Vibe ID

**极简创建入口，支持无登录体验。**

```
POST /api/v1/vibe-id/create
```

**请求体:**
```json
{
  "birth_date": "1990-05-15",
  "birth_time": "08:30",
  "birth_place": "北京",
  "gender": "male",
  "invited_by": "VB7X9K"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| birth_date | string | 是 | 出生日期 YYYY-MM-DD |
| birth_time | string | 是 | 出生时间 HH:MM |
| birth_place | string | 否 | 出生地点，默认"北京" |
| gender | string | 否 | 性别 male/female/unknown |
| invited_by | string | 否 | 邀请人的 share_code |

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "vibe_id": { /* 完整 VibeID 数据结构 */ },
    "share_code": "VB7X9K",
    "card_url": "/api/v1/vibe-id/card/VB7X9K.png",
    "is_temporary": true
  }
}
```

| 字段 | 说明 |
|------|------|
| vibe_id | 完整的 Vibe ID 数据 |
| share_code | 6位分享码 |
| card_url | 分享卡片 URL |
| is_temporary | 是否为临时数据 (未登录时为 true) |

**错误响应:**
```json
{
  "status": "error",
  "error": "invalid_birth_date",
  "message": "出生日期格式错误，请使用 YYYY-MM-DD 格式"
}
```

---

### 2. 获取 Vibe ID

**获取当前登录用户的 Vibe ID。**

```
GET /api/v1/vibe-id
```

**请求头:**
```
Authorization: Bearer {token}
```

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "vibe_id": { /* 完整 VibeID 数据结构 */ },
    "share_code": "VB7X9K",
    "card_url": "/api/v1/vibe-id/card/VB7X9K.png"
  }
}
```

**错误响应 (404):**
```json
{
  "status": "error",
  "error": "not_found",
  "message": "Vibe ID 不存在，请先创建"
}
```

---

### 3. 预览 Vibe ID

**无需登录，预览 Vibe ID 结果，不保存。**

```
GET /api/v1/vibe-id/preview?birth_date=1990-05-15&birth_time=08:30
```

**查询参数:**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| birth_date | string | 是 | 出生日期 |
| birth_time | string | 是 | 出生时间 |
| birth_place | string | 否 | 出生地点 |
| gender | string | 否 | 性别 |

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "vibe_id": { /* 完整 VibeID 数据结构 */ },
    "is_preview": true
  }
}
```

---

### 4. 重新计算 Vibe ID

**强制重新计算当前用户的 Vibe ID。**

```
POST /api/v1/vibe-id/recalculate
```

**请求头:**
```
Authorization: Bearer {token}
```

**请求体 (可选):**
```json
{
  "birth_date": "1990-05-15",
  "birth_time": "08:30",
  "birth_place": "上海",
  "gender": "male"
}
```

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "vibe_id": { /* 完整 VibeID 数据结构 */ },
    "share_code": "VB7X9K",
    "card_url": "/api/v1/vibe-id/card/VB7X9K.png",
    "recalculated": true
  }
}
```

---

### 5. 获取分享卡片图片

**服务端渲染的分享卡片图片。**

```
GET /api/v1/vibe-id/card/{share_code}.png
```

**路径参数:**
| 参数 | 说明 |
|------|------|
| share_code | 6位分享码 |

**查询参数 (可选):**
| 参数 | 类型 | 说明 |
|------|------|------|
| style | string | 卡片样式: default/dark/gradient/minimal |
| size | string | 尺寸: small/medium/large |

**响应:**
- Content-Type: `image/png`
- 返回 PNG 图片二进制数据

**错误响应 (404):**
- 返回默认占位图片

---

### 6. 生成分享卡片

**生成或更新分享卡片。**

```
POST /api/v1/vibe-id/card/generate
```

**请求头:**
```
Authorization: Bearer {token}
```

**请求体:**
```json
{
  "style": "gradient",
  "include_qr": true,
  "custom_text": "来测测你的 Vibe"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| style | string | 否 | 卡片样式，默认 default |
| include_qr | boolean | 否 | 是否包含二维码，默认 true |
| custom_text | string | 否 | 自定义分享文案 |

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "card_url": "/api/v1/vibe-id/card/VB7X9K.png",
    "share_code": "VB7X9K",
    "share_text": "我是探索者 Vibe 🧭 来测测你的 Vibe",
    "generated_at": "2026-01-18T10:30:00Z"
  }
}
```

---

### 7. 获取邀请信息

**通过分享码获取邀请人信息。**

```
GET /api/v1/vibe-id/invite/{share_code}
```

**路径参数:**
| 参数 | 说明 |
|------|------|
| share_code | 邀请人的分享码 |

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "inviter": {
      "nickname": "小明",
      "archetype": "Explorer",
      "emoji": "🧭",
      "tagline": "探索者"
    },
    "invite_type": "general",
    "message": "小明邀请你测测你的 Vibe"
  }
}
```

**错误响应 (404):**
```json
{
  "status": "error",
  "error": "invalid_share_code",
  "message": "邀请码无效或已过期"
}
```

---

### 8. 计算配对

**计算两个用户的 Vibe 配对。**

```
POST /api/v1/vibe-id/match
```

**请求头:**
```
Authorization: Bearer {token}
```

**请求体 (方式一 - 通过用户ID):**
```json
{
  "target_user_id": "uuid-xxx"
}
```

**请求体 (方式二 - 通过分享码):**
```json
{
  "target_share_code": "VB7X9K"
}
```

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "match_score": 85,
    "compatibility_level": "excellent",
    "compatibility_label": "灵魂伴侣",

    "user_archetype": {
      "primary": "Explorer",
      "emoji": "🧭",
      "tagline": "探索者"
    },
    "target_archetype": {
      "primary": "Sage",
      "emoji": "📚",
      "tagline": "智者"
    },

    "insights": {
      "summary": "探索者与智者的组合是绝佳搭配，你们能在探索中共同成长。",
      "strengths": [
        "共同的求知欲",
        "互补的行动与思考",
        "尊重彼此的独立空间"
      ],
      "challenges": [
        "可能都不擅长处理情感细节",
        "需要学习表达关心"
      ],
      "advice": "多分享你们的发现和思考，这是你们连接的最佳方式。"
    },

    "dimensions_match": {
      "core": { "score": 92, "description": "核心价值观高度一致" },
      "inner": { "score": 78, "description": "内心世界相互理解" },
      "outer": { "score": 85, "description": "外在表现互补" },
      "shadow": { "score": 65, "description": "阴影面需要相互包容" }
    }
  }
}
```

---

### 9. 获取12原型定义

**获取所有原型的完整定义。**

```
GET /api/v1/vibe-id/archetypes
```

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "archetypes": {
      "Explorer": {
        "id": "Explorer",
        "name_en": "Explorer",
        "name_cn": "探索者",
        "nickname": "好奇宝宝",
        "emoji": "🧭",
        "slogan": "好奇心驱动，追求意义，享受探索未知的旅程",
        "core_drive": "追求自由与发现",
        "core_fear": "被困住、空虚、随波逐流",
        "description": "探索者是永不停歇的旅人...",
        "superpowers": ["洞察力", "适应力", "创新思维"],
        "growth_points": ["耐心", "承诺", "深度关系"],
        "growth_direction": "从探索到智慧的整合",
        "best_match": ["Sage", "Creator"],
        "challenge_match": ["Ruler", "Regular"],
        "rarity": 0.08,
        "light_side": ["好奇", "独立", "勇敢"],
        "dark_side": ["逃避", "承诺恐惧", "不安定"]
      },
      // ... 其他11个原型
    }
  }
}
```

---

### 10. 获取单个原型详情

```
GET /api/v1/vibe-id/archetypes/{archetype_id}
```

**路径参数:**
| 参数 | 说明 |
|------|------|
| archetype_id | 原型ID，如 Explorer |

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "id": "Explorer",
    "name_en": "Explorer",
    "name_cn": "探索者",
    // ... 完整原型信息
  }
}
```

---

### 11. 认领临时 Vibe ID

**用户注册后，将 localStorage 中的临时 Vibe ID 认领到账号。**

```
POST /api/v1/vibe-id/claim
```

**请求头:**
```
Authorization: Bearer {token}
```

**请求体:**
```json
{
  "temporary_share_code": "VB7X9K",
  "vibe_id_data": { /* 完整 VibeID 数据 */ }
}
```

**响应 (200):**
```json
{
  "status": "success",
  "data": {
    "claimed": true,
    "share_code": "VB7X9K",
    "message": "Vibe ID 已成功绑定到你的账号"
  }
}
```

---

## 错误码定义

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| invalid_birth_date | 400 | 出生日期格式错误 |
| invalid_birth_time | 400 | 出生时间格式错误 |
| invalid_share_code | 404 | 分享码无效 |
| not_found | 404 | Vibe ID 不存在 |
| unauthorized | 401 | 未登录 |
| calculation_failed | 500 | 计算失败 |
| card_generation_failed | 500 | 卡片生成失败 |

---

## 速率限制

| 端点 | 限制 |
|------|------|
| /create | 10次/分钟/IP |
| /preview | 30次/分钟/IP |
| /card/*.png | 100次/分钟/IP |
| /match | 20次/分钟/用户 |

---

## 缓存策略

| 端点 | 缓存时间 | 说明 |
|------|----------|------|
| /card/*.png | 1小时 | CDN 缓存 |
| /archetypes | 24小时 | 静态数据 |
| /invite/* | 5分钟 | 短期缓存 |
