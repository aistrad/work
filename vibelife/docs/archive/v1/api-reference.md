# VibeLife API Reference

> 完整的 API 文档可通过 `/docs` (Swagger UI) 或 `/redoc` 访问

## 基础信息

| 项目 | 测试环境 | 正式环境 |
|------|----------|----------|
| Base URL | `http://106.37.170.238:8000/api/v1` | `https://api.vibelife.app/api/v1` |
| API 文档 | `http://106.37.170.238:8000/docs` | `https://api.vibelife.app/docs` |
| 认证方式 | Bearer Token (JWT) | Bearer Token (JWT) |
| 响应格式 | JSON | JSON |

## 认证 (Authentication)

### POST /auth/register
注册新用户

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "secure_password",
  "display_name": "用户昵称"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "vibe_id": "VB20260105001",
    "email": "user@example.com",
    "display_name": "用户昵称"
  },
  "tokens": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer"
  }
}
```

### POST /auth/login
用户登录

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

### POST /auth/refresh
刷新访问令牌

**Headers:**
```
Authorization: Bearer <refresh_token>
```

### POST /auth/logout
用户登出

---

## 用户 (Users)

### GET /users/me
获取当前用户信息

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "vibe_id": "VB20260105001",
    "display_name": "用户昵称",
    "birth_datetime": "1990-05-15T10:30:00Z",
    "birth_location": "北京",
    "timezone": "Asia/Shanghai"
  }
}
```

### PUT /users/me
更新用户信息

### GET /users/me/profiles
获取用户所有 Skill 档案

---

## 对话 (Chat)

### POST /chat/{skill_id}/message
发送消息

**Request Body:**
```json
{
  "content": "你好，帮我看看今年运势",
  "conversation_id": "uuid (可选)"
}
```

**Response (SSE Stream):**
```
data: {"type": "start", "conversation_id": "uuid"}
data: {"type": "content", "text": "你好！"}
data: {"type": "content", "text": "让我看看..."}
data: {"type": "insight", "insight": {...}}
data: {"type": "done"}
```

### GET /chat/{skill_id}/history
获取对话历史

### GET /chat/conversations
获取所有对话列表

---

## 提醒 (Reminders)

### GET /reminders/events/upcoming
获取即将到来的运势事件

**Query Parameters:**
- `days_ahead` (int): 查询天数，默认 7
- `event_type` (string): 事件类型筛选

**Response:**
```json
{
  "events": [
    {
      "id": "uuid",
      "event_type": "solar_term",
      "name": "节气·立春",
      "start_date": "2026-02-04",
      "event_data": {"solar_term": "立春"}
    }
  ]
}
```

### GET /reminders/events/mercury-retrograde
检查水逆状态

### GET /reminders/settings/{user_id}
获取用户提醒设置

### PUT /reminders/settings/{user_id}
更新用户提醒设置

### GET /reminders/notifications/{user_id}
获取用户通知列表

### POST /reminders/notifications/{notification_id}/read
标记通知已读

---

## 周期回顾 (Mirror)

### GET /mirror/monthly/{user_id}
获取月运回顾

**Response:**
```json
{
  "review": {
    "month": "2026-01",
    "month_name": "丙寅月",
    "current_month_summary": "本月能量平稳...",
    "current_month_highlights": ["工作效率提升", "人际关系和谐"],
    "next_month_outlook": "下月带来新能量...",
    "key_advice": "顺应能量流动"
  }
}
```

### GET /mirror/weekly/{user_id}
获取周运回顾

### GET /mirror/weekly/sign/{sun_sign}
获取特定星座周运

### POST /mirror/cards/monthly/{user_id}
生成月运分享卡片

### POST /mirror/cards/weekly/{user_id}
生成周运分享卡片

---

## 订阅 (Billing)

### GET /billing/plans
获取所有订阅计划

**Response:**
```json
{
  "plans": [
    {
      "id": "bazi_premium",
      "name": "八字会员",
      "plan_type": "skill_single",
      "skill_ids": ["bazi"],
      "price_monthly": 2900,
      "price_yearly": 19900,
      "currency": "CNY",
      "features": ["无限对话", "深度十神分析", ...]
    }
  ]
}
```

### GET /billing/subscription/{user_id}
获取用户订阅状态

### POST /billing/checkout/create
创建支付会话

**Request Body:**
```json
{
  "user_id": "uuid",
  "plan_id": "bazi_premium",
  "billing_cycle": "monthly",
  "success_url": "https://...",
  "cancel_url": "https://..."
}
```

### POST /billing/paywall/check
检查付费墙

**Request Body:**
```json
{
  "user_id": "uuid",
  "trigger": "deep_pattern_analysis",
  "skill_id": "bazi"
}
```

---

## 错误响应

所有错误响应格式：

```json
{
  "detail": "错误描述"
}
```

常见 HTTP 状态码：
- `400` - 请求参数错误
- `401` - 未认证
- `403` - 无权限
- `404` - 资源不存在
- `429` - 请求过于频繁
- `500` - 服务器内部错误

---

## Rate Limiting

| 用户类型 | 限制 |
|----------|------|
| 免费用户 | 3 次/天 (对话) |
| 订阅用户 | 无限制 |
| API 调用 | 100 次/分钟 |

---

## Webhook Events

Stripe Webhook 端点: `POST /billing/webhook/stripe`

支持的事件类型：
- `checkout.session.completed` - 支付成功
- `customer.subscription.updated` - 订阅更新
- `customer.subscription.deleted` - 订阅取消
- `invoice.payment_failed` - 支付失败
