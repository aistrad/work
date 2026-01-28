# VibeLife Platform Services 移交文档

> **版本**: v6.0
> **更新日期**: 2026-01-16
> **负责人**: Platform Team

---

## 目录

1. [概述](#1-概述)
2. [架构设计](#2-架构设计)
3. [API 端点](#3-api-端点)
4. [服务层](#4-服务层)
5. [数据层](#5-数据层)
6. [数据库结构](#6-数据库结构)
7. [环境配置](#7-环境配置)
8. [部署与运维](#8-部署与运维)
9. [常见问题](#9-常见问题)

---

## 1. 概述

### 1.1 Platform Services 定义

Platform Services 是 VibeLife 的基础设施层，提供以下核心能力：

| 服务 | 职责 | 路由文件 |
|------|------|----------|
| **Identity** | 用户认证、授权、访客会话 | `account.py` |
| **Billing** | 订阅管理、双轨制支付 | `commerce.py` |
| **Entitlement** | 权益检查、用量控制 | `commerce.py` |
| **Notification** | 通知推送、每日运势 | `notifications.py` |

### 1.2 设计原则

1. **路由合并**: 按业务域合并路由，减少文件数量
2. **服务委托**: EntitlementService 作为兼容层，委托到 SubscriptionService
3. **数据统一**: 使用 `unified_profiles` 表统一存储用户 Profile 数据
4. **双轨制支付**: 支持 CN（预付）和 GLOBAL（订阅）两种模式

### 1.3 文件结构

```
apps/api/
├── routes/
│   ├── account.py          # 账户统一入口
│   ├── commerce.py         # 商业统一入口
│   └── notifications.py    # 通知路由
├── services/
│   ├── identity/           # 身份认证服务
│   │   ├── __init__.py
│   │   ├── auth.py         # 认证服务 + CurrentUser
│   │   ├── jwt.py          # JWT 令牌
│   │   ├── sso.py          # SSO 单点登录
│   │   ├── oauth.py        # Google/Apple OAuth
│   │   ├── guest_session.py # 访客会话
│   │   ├── password_reset.py # 密码重置
│   │   └── prism_generator.py # 身份棱镜
│   ├── billing/            # 计费服务
│   │   ├── __init__.py
│   │   ├── stripe_service.py # Stripe API
│   │   ├── subscription.py   # 订阅管理
│   │   └── paywall.py        # 付费墙
│   └── entitlement/        # 权益服务（兼容层）
│       └── __init__.py
├── stores/
│   ├── unified_profile_repo.py  # 统一 Profile 仓库
│   └── onboarding_data_repo.py  # Onboarding 数据仓库
└── migrations/
    ├── 015_unified_profiles.sql
    ├── 016_deprecate_old_profile_tables.sql
    ├── 017_drop_old_profile_tables.sql
    └── 018_usage_events.sql
```

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (Web/App)                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         API Gateway                              │
│                    (FastAPI + Uvicorn)                          │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   /account/*  │       │  /commerce/*  │       │/notifications │
│   account.py  │       │  commerce.py  │       │notifications.py│
└───────────────┘       └───────────────┘       └───────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   Identity    │       │   Billing     │       │  Reminder     │
│   Services    │       │   Services    │       │   Service     │
└───────────────┘       └───────────────┘       └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PostgreSQL                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ vibe_users  │  │subscriptions│  │unified_     │              │
│  │ user_auths  │  │ payments    │  │ profiles    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 认证流程

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│  Login   │────▶│  JWT     │────▶│  Access  │
│          │     │  API     │     │  Service │     │  Token   │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                                                         │
                                                         ▼
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│Protected │◀────│  Auth    │◀────│  Verify  │◀────│  Bearer  │
│  API     │     │Dependency│     │  Token   │     │  Header  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
```

### 2.3 双轨制支付流程

```
                    ┌─────────────────┐
                    │   用户发起支付   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   检测用户地区   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │   CN (大陆/香港)  │           │   GLOBAL (海外)  │
     └────────┬────────┘           └────────┬────────┘
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │   预付模式       │           │   订阅模式       │
     │   (一次性支付)   │           │   (自动续费)     │
     └────────┬────────┘           └────────┬────────┘
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │ Stripe Payment  │           │ Stripe          │
     │ (mode=payment)  │           │ Subscription    │
     └────────┬────────┘           └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                    ┌────────▼────────┐
                    │   Webhook 回调   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   创建/更新订阅  │
                    └─────────────────┘
```

---

## 3. API 端点

### 3.1 Account API (`/account/*`)

#### 认证端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| POST | `/account/auth/register` | 用户注册 | 否 |
| POST | `/account/auth/login` | 用户登录 | 否 |
| POST | `/account/auth/refresh` | 刷新令牌 | 否 |
| POST | `/account/auth/logout` | 用户登出 | 是 |
| GET | `/account/auth/me` | 获取当前用户 | 是 |
| POST | `/account/auth/oauth/google` | Google OAuth | 否 |
| POST | `/account/auth/oauth/apple` | Apple OAuth | 否 |
| POST | `/account/auth/password/reset-request` | 请求密码重置 | 否 |
| POST | `/account/auth/password/reset` | 重置密码 | 否 |

#### 用户资料端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/account/profile` | 获取用户资料 | 是 |
| PUT | `/account/profile` | 更新用户资料 | 是 |
| GET | `/account/profile/export` | 导出用户数据 (GDPR) | 是 |

#### 访客会话端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| POST | `/account/guest/session` | 创建访客会话 | 否 |
| GET | `/account/guest/session` | 获取访客会话 | Cookie |
| PUT | `/account/guest/session/onboarding` | 保存 Onboarding 数据 | Cookie |
| DELETE | `/account/guest/session` | 删除访客会话 | Cookie |

#### 身份棱镜端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/account/identity/prism` | 获取身份棱镜数据 | 可选 |

### 3.2 Commerce API (`/commerce/*`)

#### 支付端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/commerce/payment/config` | 获取 Stripe 配置 | 否 |
| GET | `/commerce/payment/detect-region` | 检测用户地区 | 否 |
| GET | `/commerce/payment/pricing` | 获取定价信息 | 否 |
| POST | `/commerce/payment/create-checkout` | 创建 Checkout Session | 否 |
| POST | `/commerce/payment/verify` | 验证支付状态 | 否 |
| POST | `/commerce/payment/webhook` | Stripe Webhook | 否 |

#### 订阅端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/commerce/billing/plans` | 获取订阅计划 | 否 |
| GET | `/commerce/billing/subscription/me` | 获取我的订阅 | 是 |
| POST | `/commerce/billing/subscription/cancel` | 取消订阅 | 是 |

#### 权益端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/commerce/entitlement` | 获取用户权益 | 是 |
| GET | `/commerce/entitlement/can-chat` | 检查对话权限 | 是 |
| POST | `/commerce/entitlement/upgrade` | 升级到付费 (测试) | 是 |
| POST | `/commerce/entitlement/downgrade` | 降级到免费 (测试) | 是 |

#### 付费墙端点

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| POST | `/commerce/paywall/check` | 检查付费墙访问 | 否 |

### 3.3 Notifications API (`/notifications/*`)

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/notifications` | 获取通知列表 | 可选 |
| GET | `/notifications/unread` | 获取未读通知 | 可选 |
| POST | `/notifications/{id}/read` | 标记已读 | 否 |
| GET | `/notifications/daily` | 获取今日运势 | 可选 |

---

## 4. 服务层

### 4.1 Identity Services

#### AuthService

```python
from services.identity import AuthService

# 注册
result = await AuthService.register(
    email="user@example.com",
    password="password123",
    display_name="User",
    birth_datetime=datetime(1990, 1, 1, 12, 0),
    birth_location="Beijing",
    gender="male",
    skill="bazi"
)

# 登录
result = await AuthService.login(
    email="user@example.com",
    password="password123"
)

# 刷新令牌
result = await AuthService.refresh_token(refresh_token)
```

#### CurrentUser 依赖

```python
from services.identity import get_current_user, get_optional_user, CurrentUser

# 必须认证
@router.get("/protected")
async def protected_endpoint(current_user: CurrentUser = Depends(get_current_user)):
    return {"user_id": str(current_user.user_id)}

# 可选认证
@router.get("/public")
async def public_endpoint(current_user: Optional[CurrentUser] = Depends(get_optional_user)):
    if current_user:
        return {"user_id": str(current_user.user_id)}
    return {"user_id": None}
```

#### GuestSessionService

```python
from services.identity import GuestSessionService

# 创建访客会话
session = await GuestSessionService.create_session()

# 保存 Onboarding 数据
session = await GuestSessionService.save_onboarding_data(
    session_id=session_id,
    birth_datetime=datetime(1990, 1, 1, 12, 0),
    birth_location="Beijing",
    gender="male",
    skill="bazi",
    interview_responses={"q1": "answer1"},
    focus_areas=["career", "relationship"]
)

# 关联到用户
await GuestSessionService.link_to_user(session_id, user_id)
```

### 4.2 Billing Services

#### SubscriptionService

```python
from services.billing.subscription import SubscriptionService, SubscriptionStatus
from stores.db import get_db_pool

pool = await get_db_pool()
service = SubscriptionService(pool)

# 获取用户订阅
subscription = await service.get_user_subscription(user_id)

# 创建预付订阅 (CN)
sub_id = await service.create_prepaid_subscription(
    user_id=user_id,
    plan_code="3m",
    service_days=90,
    payment_session_id=session_id,
    region="CN"
)

# 创建 Stripe 订阅 (GLOBAL)
sub_id = await service.create_stripe_subscription(
    user_id=user_id,
    plan_code="monthly",
    stripe_subscription_id=stripe_sub_id,
    stripe_customer_id=customer_id,
    current_period_end=period_end
)

# 检查对话权限
result = await service.check_can_chat(user_id)
# {"can_chat": True, "remaining": 27, "tier": "paid"}

# 获取用户权益
entitlements = await service.get_entitlements(user_id)
```

#### EntitlementService (兼容层)

```python
from services.entitlement import EntitlementService

# 检查对话权限
result = await EntitlementService.check_can_chat(user_id)

# 获取权益
entitlements = await EntitlementService.get_entitlements(user_id)

# 升级/降级 (测试用)
await EntitlementService.upgrade_to_paid(user_id, expires_at)
await EntitlementService.downgrade_to_free(user_id)
```

### 4.3 层级配置

```python
# 免费用户
TIER_CONFIG = {
    "free": {"daily_limit": 3},    # 每天 3 次对话
    "paid": {"daily_limit": 200},  # 每天 200 次对话
}
```

---

## 5. 数据层

### 5.1 UnifiedProfileRepository

统一 Profile 数据访问层，使用 JSONB 存储用户数据。

```python
from stores.unified_profile_repo import UnifiedProfileRepository

# 获取完整 Profile
profile = await UnifiedProfileRepository.get_profile(user_id)

# 获取出生信息
birth_info = await UnifiedProfileRepository.get_birth_info(user_id)

# 获取 Skill 数据
skill_data = await UnifiedProfileRepository.get_skill_data(user_id, "bazi")

# 更新出生信息 (局部更新)
await UnifiedProfileRepository.update_birth_info(user_id, {
    "date": "1990-01-01",
    "time": "12:00",
    "place": "Beijing",
    "gender": "male",
    "timezone": "Asia/Shanghai"
})

# 更新 Skill 数据 (局部更新)
await UnifiedProfileRepository.update_skill_data(user_id, "bazi", {
    "chart": {...},
    "analysis": {...}
})

# 更新用户偏好
await UnifiedProfileRepository.update_preferences(user_id, {
    "voice_mode": "professional",
    "language": "en-US"
})
```

### 5.2 Profile JSONB 结构

```json
{
  "birth_info": {
    "date": "1990-01-01",
    "time": "12:00",
    "place": "Beijing",
    "gender": "male",
    "timezone": "Asia/Shanghai"
  },
  "life_context": {
    "occupation": "Engineer",
    "relationship_status": "married",
    "concerns": ["career", "health"]
  },
  "identity_prism": {
    "core": {...},
    "inner": {...},
    "outer": {...}
  },
  "preferences": {
    "voice_mode": "warm",
    "language": "zh-CN"
  },
  "skill_data": {
    "bazi": {
      "chart": {...},
      "analysis": {...}
    },
    "zodiac": {
      "natal_chart": {...}
    }
  },
  "extracted": {
    "facts": [...],
    "concerns": [...],
    "goals": [...]
  }
}
```

---

## 6. 数据库结构

### 6.1 核心表

#### vibe_users (用户表)

```sql
CREATE TABLE vibe_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vibe_id VARCHAR(20) UNIQUE NOT NULL,  -- 用户唯一标识 (如 VIBE-XXXX)
    display_name VARCHAR(100),
    avatar_url TEXT,
    birth_datetime TIMESTAMPTZ,
    birth_location VARCHAR(200),
    gender VARCHAR(10),
    timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
    language VARCHAR(10) DEFAULT 'zh-CN',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### user_auths (认证表)

```sql
CREATE TABLE user_auths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    auth_type VARCHAR(20) NOT NULL,  -- email, phone, google, apple
    auth_identifier VARCHAR(255) NOT NULL,
    auth_credential TEXT,  -- 密码哈希或 OAuth token
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(auth_type, auth_identifier)
);
```

#### unified_profiles (统一 Profile 表)

```sql
CREATE TABLE unified_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES vibe_users(id),
    profile JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### subscriptions (订阅表)

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    plan_code VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,  -- active, canceled, expired, suspended
    vip_type VARCHAR(20) DEFAULT 'subscription',  -- prepaid, subscription
    region VARCHAR(10) DEFAULT 'GLOBAL',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    stripe_subscription_id VARCHAR(100),
    stripe_customer_id VARCHAR(100),
    payment_failed_count INT DEFAULT 0,
    source VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### usage_events (用量事件表)

```sql
CREATE TABLE usage_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    event_type VARCHAR(20) NOT NULL,  -- llm_call, skill_use, tool_call, conversation
    model VARCHAR(50),
    input_tokens INT DEFAULT 0,
    output_tokens INT DEFAULT 0,
    estimated_cost DECIMAL(10,6) DEFAULT 0,
    skill_id VARCHAR(30),
    tool_name VARCHAR(50),
    conversation_id UUID,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 6.2 迁移文件

| 文件 | 描述 |
|------|------|
| `015_unified_profiles.sql` | 创建 unified_profiles 和 onboarding_data 表 |
| `016_deprecate_old_profile_tables.sql` | 标记旧表为 deprecated |
| `017_drop_old_profile_tables.sql` | 删除旧的 Profile 表 |
| `018_usage_events.sql` | 创建统一用量表 |

---

## 7. 环境配置

### 7.1 必需环境变量

```bash
# 数据库
DATABASE_URL=postgresql://user:pass@localhost:5432/vibelife

# JWT
JWT_SECRET_KEY=your-secret-key
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# Stripe
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Stripe 价格 ID (CN 预付)
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_PREPAID_3M_HKD=price_xxx
STRIPE_PRICE_PREPAID_12M_HKD=price_xxx

# Stripe 价格 ID (GLOBAL 订阅)
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
STRIPE_PRICE_SUB_QUARTERLY_USD=price_xxx
STRIPE_PRICE_SUB_YEARLY_USD=price_xxx

# OAuth
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
APPLE_CLIENT_ID=com.vibelife.app

# 应用
APP_BASE_URL=https://app.vibelife.com
```

### 7.2 定价配置

#### CN 地区 (预付)

| 计划 | 价格 | 天数 | 折扣 |
|------|------|------|------|
| 1m | 39 HKD | 30 | - |
| 3m | 99 HKD | 90 | 15% |
| 12m | 298 HKD | 365 | 36% |

#### GLOBAL 地区 (订阅)

| 计划 | 价格 | 周期 | 折扣 |
|------|------|------|------|
| monthly | $9.90 USD | 月 | - |
| quarterly | $24.90 USD | 季 | 16% |
| yearly | $69.90 USD | 年 | 41% |

---

## 8. 部署与运维

### 8.1 定时任务

```bash
# 检查即将到期的预付订阅 (每天 9:00)
0 9 * * * python -c "from services.billing.subscription import SubscriptionService; ..."

# 过期订阅处理 (每小时)
0 * * * * python -c "from services.billing.subscription import SubscriptionService; ..."
```

### 8.2 Stripe Webhook 配置

在 Stripe Dashboard 配置以下事件：

- `checkout.session.completed` - 支付完成
- `customer.subscription.updated` - 订阅更新
- `customer.subscription.deleted` - 订阅取消
- `invoice.payment_failed` - 支付失败

Webhook URL: `https://api.vibelife.com/commerce/payment/webhook`

### 8.3 监控指标

| 指标 | 描述 | 告警阈值 |
|------|------|----------|
| `auth_login_success_rate` | 登录成功率 | < 95% |
| `payment_success_rate` | 支付成功率 | < 90% |
| `subscription_churn_rate` | 订阅流失率 | > 10% |
| `api_latency_p99` | API P99 延迟 | > 500ms |

### 8.4 日志

```python
import logging
logger = logging.getLogger(__name__)

# 关键日志
logger.info(f"User registered: {user_id}")
logger.info(f"Payment completed: session={session_id}, user={user_id}")
logger.warning(f"Payment failed: session={session_id}, count={failed_count}")
logger.error(f"Webhook processing failed: {error}")
```

---

## 9. 常见问题

### 9.1 认证问题

**Q: Token 过期后如何处理？**

A: 使用 refresh_token 调用 `/account/auth/refresh` 获取新的 access_token。

**Q: 如何处理 OAuth 登录？**

A: 前端获取 Google/Apple 的 id_token，调用 `/account/auth/oauth/google` 或 `/account/auth/oauth/apple`。

### 9.2 支付问题

**Q: 如何判断用户地区？**

A: 调用 `/commerce/payment/detect-region`，根据 IP 地址判断。CN/HK 用户使用预付模式，其他地区使用订阅模式。

**Q: Webhook 签名验证失败？**

A: 检查 `STRIPE_WEBHOOK_SECRET` 是否正确配置。

**Q: 预付订阅如何续费？**

A: 用户再次购买时，系统会自动延长现有订阅的到期时间。

### 9.3 权益问题

**Q: 免费用户每天可以对话几次？**

A: 3 次。

**Q: 付费用户每天可以对话几次？**

A: 200 次。

**Q: 如何检查用户是否可以对话？**

A: 调用 `/commerce/entitlement/can-chat`，返回 `{"can_chat": true/false, "remaining": N, "tier": "free/paid"}`。

---

## 附录

### A. API 请求示例

#### 注册

```bash
curl -X POST https://api.vibelife.com/account/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "display_name": "User",
    "onboarding": {
      "birth_datetime": "1990-01-01T12:00:00",
      "birth_location": "Beijing",
      "gender": "male",
      "skill": "bazi"
    }
  }'
```

#### 创建 Checkout

```bash
curl -X POST https://api.vibelife.com/commerce/payment/create-checkout \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid",
    "product_id": "cn_3m",
    "success_url": "https://app.vibelife.com/payment/success",
    "cancel_url": "https://app.vibelife.com/pricing"
  }'
```

### B. 联系方式

- **技术负责人**: Platform Team
- **文档更新**: 2026-01-16
- **代码仓库**: github.com/aiscendtech/vibelife
