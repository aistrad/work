# Stripe 支付集成最佳实践手册

> **版本**: v1.0
> **更新日期**: 2026-01-11
> **参考**: https://docs.stripe.com/payments/quickstart

## 目录

1. [概述](#概述)
2. [Stripe Dashboard 配置](#stripe-dashboard-配置)
3. [Products 和 Prices 创建](#products-和-prices-创建)
4. [Webhook 配置](#webhook-配置)
5. [前端集成](#前端集成)
6. [安全最佳实践](#安全最佳实践)
7. [测试与调试](#测试与调试)

---

## 概述

VibeLife 使用 Stripe 实现双轨制支付：
- **海外用户 (GLOBAL)**: USD 订阅模式 (Recurring)
- **大陆/香港用户 (CN)**: HKD 预付模式 (One-time)

### 核心原则

1. **金额服务端计算** - 防止客户端篡改
2. **Webhook 确认支付** - 不依赖客户端回调
3. **签名验证** - 确保请求来自 Stripe
4. **PCI 合规** - 使用 Stripe.js，支付信息不经过服务器

---

## Stripe Dashboard 配置

### 1. 登录 Stripe Dashboard

- 测试环境: https://dashboard.stripe.com/test
- 生产环境: https://dashboard.stripe.com

### 2. 获取 API 密钥

路径: **Developers** → **API keys**

| 密钥类型 | 格式 | 用途 |
|---------|------|------|
| Publishable key | `pk_test_xxx` / `pk_live_xxx` | 前端初始化 Stripe.js |
| Secret key | `sk_test_xxx` / `sk_live_xxx` | 后端 API 调用 |

**配置到 .env**:
```bash
# 后端
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx

# 前端 (apps/web/.env.local)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

---

## Products 和 Prices 创建

### 什么是 Product 和 Price？

```
Product (产品)          Price (价格)
    ↓                      ↓
"VibeLife Premium"    "月付 $9.90" (price_xxx)
                      "年付 $69.90" (price_yyy)
```

- **Product**: 你销售的服务/商品
- **Price**: 该产品的定价方案（可以有多个）

### 创建步骤

#### 1. 创建 Product

路径: **Products** → **Add product**

填写:
- **Name**: VibeLife Premium
- **Description**: VibeLife 付费会员服务

#### 2. 添加 Prices

对于每个 Product，添加以下价格：

**海外订阅 (USD, Recurring)**:

| Price 名称 | 类型 | 金额 | 周期 | 环境变量 |
|-----------|------|------|------|----------|
| Global Monthly | Recurring | $9.90 | Monthly | `STRIPE_PRICE_SUB_MONTHLY_USD` |
| Global Quarterly | Recurring | $24.90 | Every 3 months | `STRIPE_PRICE_SUB_QUARTERLY_USD` |
| Global Yearly | Recurring | $69.90 | Yearly | `STRIPE_PRICE_SUB_YEARLY_USD` |

**大陆/香港预付 (HKD, One-time)**:

| Price 名称 | 类型 | 金额 | 环境变量 |
|-----------|------|------|----------|
| CN 1-Month | One-time | HKD 39 | `STRIPE_PRICE_PREPAID_1M_HKD` |
| CN 3-Month | One-time | HKD 99 | `STRIPE_PRICE_PREPAID_3M_HKD` |
| CN 12-Month | One-time | HKD 298 | `STRIPE_PRICE_PREPAID_12M_HKD` |

#### 3. 获取 Price ID

创建后，点击价格行，复制 **Price ID**（格式: `price_1ABC123...`）

#### 4. 配置到 .env

```bash
# 海外订阅 Price IDs (USD, Recurring)
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
STRIPE_PRICE_SUB_QUARTERLY_USD=price_xxx
STRIPE_PRICE_SUB_YEARLY_USD=price_xxx

# 大陆/香港预付 Price IDs (HKD, One-time)
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_PREPAID_3M_HKD=price_xxx
STRIPE_PRICE_PREPAID_12M_HKD=price_xxx
```

---

## Webhook 配置

### 什么是 Webhook？

Webhook 是 Stripe 主动通知服务器的机制。当支付成功、订阅取消等事件发生时，Stripe 向你的服务器发送 HTTP POST 请求。

### 为什么需要 Webhook？

- 用户可能关闭浏览器，客户端回调不可靠
- 防止恶意客户端伪造支付成功
- Stripe 官方推荐的最佳实践

### 配置步骤

#### 1. 创建 Webhook Endpoint

路径: **Developers** → **Webhooks** → **Add endpoint**

填写:
- **Endpoint URL**: `https://你的域名/api/v1/payment/webhook`
- **Description**: VibeLife Payment Webhook

#### 2. 选择事件

勾选以下事件:

| 事件 | 说明 |
|------|------|
| `checkout.session.completed` | Checkout 完成 |
| `payment_intent.succeeded` | 支付成功 |
| `payment_intent.payment_failed` | 支付失败 |
| `customer.subscription.created` | 订阅创建 |
| `customer.subscription.updated` | 订阅更新 |
| `customer.subscription.deleted` | 订阅取消 |
| `invoice.paid` | 发票支付成功 |
| `invoice.payment_failed` | 发票支付失败 |

#### 3. 获取 Signing Secret

创建后，点击 **Reveal** 查看 **Signing secret**（格式: `whsec_xxx`）

#### 4. 配置到 .env

```bash
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

### 本地测试 Webhook

使用 Stripe CLI 转发 webhook 到本地:

```bash
# 安装 Stripe CLI
# macOS: brew install stripe/stripe-cli/stripe
# Linux: 参考 https://stripe.com/docs/stripe-cli

# 登录
stripe login

# 转发 webhook 到本地
stripe listen --forward-to localhost:8000/api/v1/payment/webhook

# 输出示例:
# > Ready! Your webhook signing secret is whsec_xxx (使用此临时 secret)
```

触发测试事件:
```bash
stripe trigger payment_intent.succeeded
stripe trigger checkout.session.completed
```

---

## 前端集成

### 1. 安装 Stripe.js

```bash
pnpm add @stripe/stripe-js @stripe/react-stripe-js
```

### 2. 初始化 Stripe

```typescript
// lib/stripe.ts
import { loadStripe } from '@stripe/stripe-js';

const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
);

export default stripePromise;
```

### 3. 使用 Checkout Session (推荐)

```typescript
// 创建 Checkout Session
const response = await fetch('/api/v1/payment/create-checkout', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: userId,
    product_id: 'global_monthly', // 或 'cn_1m'
  }),
});

const { checkout_url } = await response.json();

// 跳转到 Stripe Checkout 页面
window.location.href = checkout_url;
```

### 4. 使用 PaymentIntent (自定义 UI)

```typescript
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js';

// 1. 获取 client_secret
const response = await fetch('/api/v1/payment/create-payment-intent', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_id: userId,
    amount: 990, // $9.90 = 990 cents
    currency: 'usd',
  }),
});
const { client_secret } = await response.json();

// 2. 渲染支付表单
function CheckoutForm() {
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (e) => {
    e.preventDefault();

    const { error } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: 'https://vibelife.app/payment/success',
      },
    });

    if (error) {
      // 显示错误
      console.error(error.message);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />
      <button type="submit">Pay</button>
    </form>
  );
}

// 3. 包装组件
<Elements stripe={stripePromise} options={{ clientSecret: client_secret }}>
  <CheckoutForm />
</Elements>
```

---

## 安全最佳实践

### 1. 金额服务端计算

```python
# 正确: ��务端计算金额
@router.post("/create-payment-intent")
async def create_payment_intent(request: Request):
    # 从数据库获取价格，不信任客户端传入的金额
    price = get_price_from_db(request.product_id)
    intent = stripe.PaymentIntent.create(
        amount=price.amount_cents,
        currency=price.currency,
    )
```

### 2. Webhook 签名验证

```python
# 正确: 验证签名
event = stripe.Webhook.construct_event(
    payload, sig_header, webhook_secret
)

# 错误: 跳过验证
event = json.loads(payload)  # 不安全!
```

### 3. 使用 Stripe.js

- 始终从 `js.stripe.com` 加载 Stripe.js
- 不要自己托管或打包 Stripe.js
- 支付信息直接发送到 Stripe，不经过你的服务器

### 4. 密钥管理

- Secret key 只在服务端使用
- Publishable key 可以暴露给前端
- 生产环境使用 `sk_live_` / `pk_live_`
- 测试环境使用 `sk_test_` / `pk_test_`

---

## 测试与调试

### 测试卡号

| 卡号 | 场景 |
|------|------|
| 4242 4242 4242 4242 | 成功支付 |
| 4000 0000 0000 3220 | 需要 3D Secure |
| 4000 0000 0000 9995 | 支付失败 |
| 4000 0000 0000 0341 | 卡片被拒 |

CVV: 任意 3 位数字
有效期: 任意未来日期

### 查看日志

Stripe Dashboard → **Developers** → **Logs**

### 常见问题

#### Q: Webhook 返回 400 错误
A: 检查签名验证，确保 `STRIPE_WEBHOOK_SECRET` 正确

#### Q: 支付成功但数据库未更新
A: 检查 Webhook 是否正确配置，查看 Stripe Dashboard 的 Webhook 日志

#### Q: 测试环境正常，生产环境失败
A: 确保使用了正确的 API 密钥（`sk_live_` 而非 `sk_test_`）

---

## API 端点参考

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/payment/config` | GET | 获取 Stripe 公钥 |
| `/api/v1/payment/pricing` | GET | 获取定价信息 |
| `/api/v1/payment/create-checkout` | POST | 创建 Checkout Session |
| `/api/v1/payment/create-payment-intent` | POST | 创建 PaymentIntent |
| `/api/v1/payment/verify` | POST | 验证支付状态 |
| `/api/v1/payment/webhook` | POST | Stripe Webhook 回调 |

---

## 环境变量清单

```bash
# ═══════════════════════════════════════════════════════════════
# Stripe 支付配置
# ═══════════════════════════════════════════════════════════════

# 基础配置
STRIPE_SECRET_KEY=sk_test_xxx          # 后端 API 密钥
STRIPE_PUBLISHABLE_KEY=pk_test_xxx     # 前端公钥
STRIPE_WEBHOOK_SECRET=whsec_xxx        # Webhook 签名密钥

# 海外订阅 Price IDs (USD, Recurring)
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
STRIPE_PRICE_SUB_QUARTERLY_USD=price_xxx
STRIPE_PRICE_SUB_YEARLY_USD=price_xxx

# 大陆/香港预付 Price IDs (HKD, One-time)
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_PREPAID_3M_HKD=price_xxx
STRIPE_PRICE_PREPAID_12M_HKD=price_xxx

# 前端 (apps/web/.env.local)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

---

## 下一步

1. 在 Stripe Dashboard 创建 Products 和 Prices
2. 配置 Webhook endpoint
3. 将获取的 Price IDs 和 Webhook Secret 配置到 .env
4. 前端集成 Stripe.js
5. 测试完整支付流程
