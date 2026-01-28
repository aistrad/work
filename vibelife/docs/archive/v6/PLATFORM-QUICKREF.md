# Platform Services 快速参考卡片

> 一页纸速查，详细内容请参考 [PLATFORM-SERVICES.md](./PLATFORM-SERVICES.md)

---

## 文件速查

```
routes/account.py      → 认证 + 用户 + 访客 + 身份棱镜
routes/commerce.py     → 支付 + 订阅 + 权益 + 付费墙
routes/notifications.py → 通知

services/identity/     → AuthService, JWTService, GuestSessionService, OAuthService
services/billing/      → SubscriptionService, StripeService, PaywallService
services/entitlement/  → EntitlementService (兼容层，委托到 SubscriptionService)

stores/unified_profile_repo.py → 统一 Profile 数据访问
```

---

## API 端点速查

### Account `/account/*`

| 端点 | 用途 |
|------|------|
| `POST /auth/register` | 注册 |
| `POST /auth/login` | 登录 |
| `POST /auth/refresh` | 刷新令牌 |
| `GET /auth/me` | 获取当前用户 |
| `POST /auth/oauth/google` | Google 登录 |
| `POST /auth/oauth/apple` | Apple 登录 |
| `GET /profile` | 获取资料 |
| `PUT /profile` | 更新资料 |
| `POST /guest/session` | 创建访客会话 |
| `GET /identity/prism` | 获取身份棱镜 |

### Commerce `/commerce/*`

| 端点 | 用途 |
|------|------|
| `GET /payment/config` | Stripe 配置 |
| `GET /payment/detect-region` | 检测地区 |
| `GET /payment/pricing` | 获取定价 |
| `POST /payment/create-checkout` | 创建支付 |
| `POST /payment/webhook` | Stripe 回调 |
| `GET /billing/subscription/me` | 我的订阅 |
| `GET /entitlement` | 获取权益 |
| `GET /entitlement/can-chat` | 检查对话权限 |
| `POST /paywall/check` | 检查付费墙 |

---

## 认证依赖

```python
from services.identity import get_current_user, get_optional_user, CurrentUser

# 必须认证
@router.get("/protected")
async def endpoint(user: CurrentUser = Depends(get_current_user)):
    pass

# 可选认证
@router.get("/public")
async def endpoint(user: Optional[CurrentUser] = Depends(get_optional_user)):
    pass
```

---

## 订阅服务

```python
from services.billing.subscription import SubscriptionService
from stores.db import get_db_pool

pool = await get_db_pool()
svc = SubscriptionService(pool)

# 获取订阅
sub = await svc.get_user_subscription(user_id)

# 检查对话权限
result = await svc.check_can_chat(user_id)
# {"can_chat": True, "remaining": 27, "tier": "paid"}

# 获取权益
ent = await svc.get_entitlements(user_id)
```

---

## Profile 数据

```python
from stores.unified_profile_repo import UnifiedProfileRepository

# 读取
profile = await UnifiedProfileRepository.get_profile(user_id)
birth = await UnifiedProfileRepository.get_birth_info(user_id)
skill = await UnifiedProfileRepository.get_skill_data(user_id, "bazi")

# 写入 (局部更新)
await UnifiedProfileRepository.update_birth_info(user_id, {...})
await UnifiedProfileRepository.update_skill_data(user_id, "bazi", {...})
```

---

## 双轨制定价

| 地区 | 模式 | 计划 | 价格 |
|------|------|------|------|
| CN | 预付 | 1m/3m/12m | 39/99/298 HKD |
| GLOBAL | 订阅 | monthly/quarterly/yearly | $9.90/$24.90/$69.90 USD |

---

## 层级限制

| 层级 | 每日对话 |
|------|----------|
| free | 3 次 |
| paid | 200 次 |

---

## 环境变量

```bash
# 必需
DATABASE_URL=postgresql://...
JWT_SECRET_KEY=xxx
STRIPE_SECRET_KEY=sk_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Stripe 价格 ID
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
```

---

## 数据库表

| 表 | 用途 |
|------|------|
| `vibe_users` | 用户基本信息 |
| `user_auths` | 认证信息 |
| `unified_profiles` | 统一 Profile (JSONB) |
| `subscriptions` | 订阅记录 |
| `usage_events` | 用量事件 |
| `onboarding_data` | Onboarding 数据 |

---

## Stripe Webhook 事件

- `checkout.session.completed` → 支付完成
- `customer.subscription.updated` → 订阅更新
- `customer.subscription.deleted` → 订阅取消

---

## 常用命令

```bash
# 运行 API
cd apps/api && ./start_api.sh

# 运行迁移
psql $DATABASE_URL -f migrations/015_unified_profiles.sql

# 测试支付
curl -X POST http://localhost:8000/commerce/payment/create-checkout \
  -H "Content-Type: application/json" \
  -d '{"user_id": "uuid", "product_id": "cn_1m"}'
```
