# Vibelife 支付体系实施与集成手册 (Ver 2.0)

> 📅 更新日期：2025年1月  
> 🎯 目标读者：CTO / 全栈工程师 / 产品经理  
> 📍 适用平台：Stripe Hong Kong 账户

---

## ⚠️ 关键更新说明 (v2.0 重大变更)

> **【必读】** 本手册基于 Stripe 2025 年最新政策进行了重大更新：
> 
> 1. **支付宝/微信支付不支持 Recurring 订阅** - 在 Stripe Checkout 中仅支持一次性支付 (One-time Payment)
> 2. **必须采用双轨制** - 海外用户走信用卡订阅，大陆用户走预付时长模式
> 3. **费率已更新** - 反映 Stripe HK 最新定价结构

---

## 1. Stripe 香港账户费率结构 (2025)

### 1.1 交易手续费

| 支付方式 | 费率 | 适用场景 |
|---------|------|---------|
| 信用卡/借记卡 (本地) | **3.4% + HK$2.35** | 香港发行的卡片 |
| 信用卡/借记卡 (国际) | **3.4% + HK$2.35 + 0.5%** | 非香港发行的卡片 |
| 支付宝 / 微信支付 | **2.2% + HK$2.00** | ⚠️ 仅支持一次性支付 |
| 货币转换费 | **+2%** | 需要货币转换时额外收取 |

### 1.2 其他费用

| 项目 | 费用 | 说明 |
|-----|------|-----|
| 争议/退款 (Dispute) | HK$85.00 | 每笔争议收取；胜诉可退还 |
| 3D Secure 验证 | 免费 | 标准定价用户免费 |
| USD 出款 | 1% (最低 $5) | 提款到 USD 银行账户 |
| Billing (订阅管理) | 0.7% | 按需付费模式 |

### 1.3 退款期限

| 支付方式 | 退款期限 |
|---------|---------|
| 支付宝 | 90 天内 |
| 微信支付 | 180 天内 |
| 信用卡 | 无限制 |

> 💡 **成本优化提示**：如果使用 HKD 收款并结算到 HKD 银行账户，可避免 2% 货币转换费。

---

## 2. 定价策略设计 (Pricing Strategy)

### 2.1 核心策略：双轨制

由于支付宝/微信**不支持 Stripe 的 Recurring 订阅**，我们采用「双轨制」：

| 用户群体 | 支付模式 | Stripe Mode | 货币 |
|---------|---------|-------------|-----|
| 海外用户 (Global) | 信用卡自动续费订阅 | `subscription` | USD |
| 大陆/香港用户 (CN/HK) | 预付时长（一次性购买） | `payment` | HKD |

### 2.2 价格配置表

#### 海外用户 - USD 信用卡订阅 (Recurring)

| 周期 | 价格 (USD) | 月均成本 | 节省幅度 | Stripe Mode |
|-----|-----------|---------|---------|------------|
| 月付 | **$9.90** | $9.90 | 基准价 | `subscription` |
| 季付 | **$24.90** | $8.30 | 省 16% | `subscription` |
| 年付 | **$69.90** | $5.83 | 省 41% | `subscription` |

#### 大陆/香港用户 - HKD 预付时长 (One-time)

| 周期 | 价格 (HKD) | 约合人民币 | 节省幅度 | Stripe Mode |
|-----|-----------|-----------|---------|------------|
| 1个月 | **HK$39** | ≈ ¥36 | 基准价 | `payment` |
| 3个月 | **HK$99** | ≈ ¥92 | 省 15% | `payment` |
| 12个月 | **HK$298** | ≈ ¥275 | 省 36% | `payment` |

> 💡 **汇率说明**：大陆用户支付 HKD 时，支付宝/微信会自动显示人民币金额（基于实时汇率）。前端需注明「以港币结算，支付宝自动换汇」。

---

## 3. Stripe 后台配置指南

### 3.1 激活支付方式

进入 `Settings` → `Payment methods`，确保激活：

- [x] **Cards** (Visa, Mastercard, Amex) - 默认开启
- [x] **Alipay (支付宝)** - ⚠️ 需手动激活
- [x] **WeChat Pay (微信支付)** - 需申请激活（审核周期约 1-2 周）
- [x] **Link** - 推荐开启，提升海外转化率

### 3.2 创建产品与价格 (Product & Prices)

进入 `Product catalog` → `Add product`

#### 产品结构设计

```
Vibelife Premium (产品)
├── 订阅类 Prices (Recurring) - 海外用户
│   ├── price_sub_monthly_usd    ($9.90/月)
│   ├── price_sub_quarterly_usd  ($24.90/3月)
│   └── price_sub_yearly_usd     ($69.90/年)
│
└── 一次性 Prices (One-time) - 大陆/香港用户
    ├── price_prepaid_1m_hkd     (HK$39)
    ├── price_prepaid_3m_hkd     (HK$99)
    └── price_prepaid_12m_hkd    (HK$298)
```

#### 创建步骤

**A. 订阅类 (Recurring) - 海外用户：**

1. Add product → Name: `Vibelife Premium`
2. Add price:
   - Pricing model: `Standard pricing`
   - Amount: `9.90` → Currency: `USD`
   - Billing period: `Monthly` → ✅ **Recurring**
3. 重复创建季付、年付价格

**B. 一次性 (One-time) - 大陆/香港用户：**

1. 在同一产品下 Add price
2. Amount: `39` → Currency: `HKD`
3. ⚠️ 选择 **One time** (非 Recurring)
4. 重复创建 3个月、12个月价格

> ⚠️ **重要**：Recurring 类型的 Price 无法使用支付宝/微信支付。One-time 类型可以使用所有支付方式。

### 3.3 记录 Price ID

配置完成后，记录以下 6 个核心 Price ID：

```javascript
const PRICE_IDS = {
  // 海外订阅 (Recurring)
  SUB_MONTHLY_USD: 'price_1Ox...xxx',
  SUB_QUARTERLY_USD: 'price_1Oy...xxx',
  SUB_YEARLY_USD: 'price_1Oz...xxx',
  
  // 大陆预付 (One-time)
  PREPAID_1M_HKD: 'price_1Pa...xxx',
  PREPAID_3M_HKD: 'price_1Pb...xxx',
  PREPAID_12M_HKD: 'price_1Pc...xxx',
};
```

---

## 4. 编程集成逻辑

### 4.1 前端：智能路由与价格展示

#### 地区检测逻辑

```javascript
// IP 地区判断
async function detectUserRegion() {
  const response = await fetch('https://api.ip.sb/geoip');
  const { country_code } = await response.json();
  
  // CN/HK 用户走预付模式，其他走订阅模式
  return ['CN', 'HK'].includes(country_code) ? 'CN' : 'GLOBAL';
}
```

#### UI 渲染差异

| 元素 | CN 模式 | Global 模式 |
|-----|--------|------------|
| 价格显示 | HK$39 / HK$99 / HK$298 | $9.90/mo / $24.90/3mo / $69.90/yr |
| 支付图标 | 支付宝、微信、Visa | Visa、MasterCard、Apple Pay |
| 按钮文案 | 「立即购买」 | 「Subscribe Now」 |
| 说明文字 | 一次性购买，支持支付宝 | 自动续费，可随时取消 |
| 续费提示 | 显示到期时间 | 显示下次扣款日期 |

### 4.2 后端：创建 Checkout Session

#### Price ID 映射配置

```python
PRICE_MAP = {
    'CN': {
        '1m': 'price_prepaid_1m_hkd_xxx',
        '3m': 'price_prepaid_3m_hkd_xxx',
        '12m': 'price_prepaid_12m_hkd_xxx',
    },
    'GLOBAL': {
        'monthly': 'price_sub_monthly_usd_xxx',
        'quarterly': 'price_sub_quarterly_usd_xxx',
        'yearly': 'price_sub_yearly_usd_xxx',
    }
}

# 预付时长映射 (天数)
SERVICE_DAYS = {
    '1m': 30,
    '3m': 90,
    '12m': 365,
}
```

#### 创建 Session - Python 完整示例

```python
import stripe
from datetime import datetime, timedelta

stripe.api_key = 'sk_live_xxx'

def create_checkout_session(user_id: str, plan: str, region: str, user_email: str):
    """
    创建 Stripe Checkout Session
    
    Args:
        user_id: 用户ID
        plan: 套餐类型 ('1m', '3m', '12m' for CN; 'monthly', 'quarterly', 'yearly' for GLOBAL)
        region: 地区 ('CN' or 'GLOBAL')
        user_email: 用户邮箱
    """
    price_id = PRICE_MAP[region][plan]
    
    # 🔑 关键区别：CN 用 payment 模式，Global 用 subscription 模式
    mode = 'payment' if region == 'CN' else 'subscription'
    
    # 构建 metadata
    metadata = {
        'user_id': user_id,
        'plan_type': plan,
        'region': region,
    }
    
    # 预付模式需要记录服务时长
    if region == 'CN':
        metadata['service_days'] = str(SERVICE_DAYS.get(plan, 30))
    
    session = stripe.checkout.Session.create(
        customer_email=user_email,
        line_items=[{
            'price': price_id,
            'quantity': 1,
        }],
        mode=mode,
        
        # 自动匹配支付方式
        automatic_payment_methods={'enabled': True},
        
        # 回调 URL
        success_url='https://vibelife.com/success?session_id={CHECKOUT_SESSION_ID}',
        cancel_url='https://vibelife.com/pricing',
        
        metadata=metadata,
        
        # 订阅模式额外配置
        **(
            {'subscription_data': {'metadata': metadata}}
            if mode == 'subscription' else {}
        ),
    )
    
    return session.url
```

#### Node.js 版本

```javascript
const stripe = require('stripe')('sk_live_xxx');

async function createCheckoutSession({ userId, plan, region, userEmail }) {
  const priceId = PRICE_MAP[region][plan];
  const mode = region === 'CN' ? 'payment' : 'subscription';
  
  const metadata = {
    user_id: userId,
    plan_type: plan,
    region: region,
  };
  
  if (region === 'CN') {
    metadata.service_days = String(SERVICE_DAYS[plan] || 30);
  }
  
  const session = await stripe.checkout.sessions.create({
    customer_email: userEmail,
    line_items: [{ price: priceId, quantity: 1 }],
    mode: mode,
    automatic_payment_methods: { enabled: true },
    success_url: 'https://vibelife.com/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: 'https://vibelife.com/pricing',
    metadata: metadata,
    ...(mode === 'subscription' && {
      subscription_data: { metadata: metadata }
    }),
  });
  
  return session.url;
}
```

---

## 5. Webhook 处理与权益发放

### 5.1 需要监听的事件

| 事件类型 | 触发时机 | 处理逻辑 |
|---------|---------|---------|
| `checkout.session.completed` | 支付成功 | 开通会员权益 |
| `customer.subscription.updated` | 订阅变更 | 更新订阅状态 |
| `customer.subscription.deleted` | 订阅取消 | 到期后关闭权益 |
| `invoice.payment_failed` | 续费失败 | 发送提醒/暂停权益 |
| `invoice.paid` | 续费成功 | 延长到期时间 |

### 5.2 Webhook 处理 - Python 示例

```python
import stripe
from flask import Flask, request, jsonify
from datetime import datetime, timedelta

app = Flask(__name__)
endpoint_secret = 'whsec_xxx'

@app.route('/webhook/stripe', methods=['POST'])
def stripe_webhook():
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')
    
    try:
        event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
    except ValueError:
        return 'Invalid payload', 400
    except stripe.error.SignatureVerificationError:
        return 'Invalid signature', 400
    
    # 路由到具体处理函数
    handlers = {
        'checkout.session.completed': handle_checkout_completed,
        'customer.subscription.updated': handle_subscription_updated,
        'customer.subscription.deleted': handle_subscription_deleted,
        'invoice.payment_failed': handle_payment_failed,
    }
    
    handler = handlers.get(event['type'])
    if handler:
        handler(event['data']['object'])
    
    return jsonify({'status': 'success'})


def handle_checkout_completed(session):
    """处理支付成功"""
    metadata = session.get('metadata', {})
    user_id = metadata.get('user_id')
    region = metadata.get('region')
    plan = metadata.get('plan_type')
    
    if not user_id:
        return
    
    if region == 'CN':
        # 预付模式：计算到期时间
        service_days = int(metadata.get('service_days', 30))
        expire_at = datetime.now() + timedelta(days=service_days)
        
        User.objects.filter(id=user_id).update(
            vip_status='active',
            vip_type='prepaid',
            expire_at=expire_at,
            stripe_payment_id=session['id'],
        )
    else:
        # 订阅模式：关联 Stripe Subscription
        subscription_id = session.get('subscription')
        
        User.objects.filter(id=user_id).update(
            vip_status='active',
            vip_type='subscription',
            stripe_subscription_id=subscription_id,
            stripe_customer_id=session.get('customer'),
        )


def handle_subscription_updated(subscription):
    """处理订阅变更（升级/降级）"""
    user = User.objects.filter(
        stripe_subscription_id=subscription['id']
    ).first()
    
    if user:
        # 更新套餐信息
        user.current_plan = subscription['items']['data'][0]['price']['id']
        user.save()


def handle_subscription_deleted(subscription):
    """处理订阅取消"""
    User.objects.filter(
        stripe_subscription_id=subscription['id']
    ).update(
        vip_status='cancelled',
        expire_at=datetime.fromtimestamp(subscription['current_period_end']),
    )


def handle_payment_failed(invoice):
    """处理续费失败"""
    subscription_id = invoice.get('subscription')
    user = User.objects.filter(stripe_subscription_id=subscription_id).first()
    
    if user:
        # 发送续费失败通知
        send_payment_failed_notification(user)
        
        # 如果连续失败多次，暂停权益
        user.payment_failed_count += 1
        if user.payment_failed_count >= 3:
            user.vip_status = 'suspended'
        user.save()
```

---

## 6. 订阅管理 - Customer Portal

Stripe 提供内置的 Customer Portal，让**订阅用户**自助管理账单。

### 6.1 Portal 功能

- ✅ 更新支付方式（信用卡）
- ✅ 查看账单历史
- ✅ 升级/降级订阅计划
- ✅ 取消订阅
- ✅ 下载发票 PDF

### 6.2 后端创建 Portal Session

```python
def create_portal_session(user):
    """
    创建 Customer Portal Session
    仅对订阅用户有效（预付用户无需此功能）
    """
    if user.vip_type != 'subscription' or not user.stripe_customer_id:
        return None
    
    session = stripe.billing_portal.Session.create(
        customer=user.stripe_customer_id,
        return_url='https://vibelife.com/account',
    )
    
    return session.url
```

### 6.3 前端集成

```javascript
// 账户页面
async function openBillingPortal() {
  const response = await fetch('/api/billing/portal', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });
  
  const { url } = await response.json();
  
  if (url) {
    window.location.href = url;
  } else {
    // 预付用户显示不同的管理界面
    showPrepaidManagement();
  }
}
```

### 6.4 Dashboard 配置

进入 `Settings` → `Billing` → `Customer portal`：

1. ✅ 允许更新支付方式
2. ✅ 显示账单历史
3. ✅ 配置可切换的产品目录（最多10个）
4. ✅ 设置取消订阅时的挽留优惠券

---

## 7. 大陆用户续费策略

由于预付模式无法自动续费，需要设计完善的到期提醒和续费引导流程。

### 7.1 到期提醒时间线

| 时间节点 | 触发动作 | 渠道 |
|---------|---------|-----|
| 到期前 7 天 | 发送续费提醒 | App 推送 + 邮件 |
| 到期前 3 天 | 发送紧急提醒 + 优惠 | App 推送 + 微信服务号 |
| 到期前 1 天 | 最后提醒 | App 弹窗 |
| 到期当天 | 权益暂停，保留数据 30 天 | 状态变更 |
| 到期后 30 天 | 数据归档提醒 | 邮件 |

### 7.2 续费激励设计

| 场景 | 激励措施 |
|-----|---------|
| 到期前续费年付 | 额外赠送 1 个月 |
| 连续续费 2 年以上 | 享受 9 折永久优惠 |
| 推荐好友购买 | 双方各得 1 个月会员 |
| 流失用户召回 | 首月 5 折优惠 |

### 7.3 续费提醒实现

```python
from celery import shared_task
from datetime import datetime, timedelta

@shared_task
def check_expiring_users():
    """每日定时任务：检查即将到期的预付用户"""
    
    now = datetime.now()
    
    # 7天内到期的用户
    users_7d = User.objects.filter(
        vip_type='prepaid',
        vip_status='active',
        expire_at__lte=now + timedelta(days=7),
        expire_at__gt=now + timedelta(days=3),
    )
    
    for user in users_7d:
        send_renewal_reminder(user, days_left=7)
    
    # 3天内到期的用户（附带优惠）
    users_3d = User.objects.filter(
        vip_type='prepaid',
        vip_status='active',
        expire_at__lte=now + timedelta(days=3),
        expire_at__gt=now + timedelta(days=1),
    )
    
    for user in users_3d:
        send_renewal_reminder(user, days_left=3, include_discount=True)
    
    # 已到期的用户
    expired_users = User.objects.filter(
        vip_type='prepaid',
        vip_status='active',
        expire_at__lte=now,
    )
    
    for user in expired_users:
        user.vip_status = 'expired'
        user.save()
        send_expiration_notice(user)
```

---

## 8. 测试指南

### 8.1 测试模式

使用 Stripe Test Mode 验证所有流程：

- Dashboard 左下角切换 Test/Live 模式
- 测试环境的 API Key 以 `sk_test_` 开头
- 所有测试交易不会产生真实费用

### 8.2 测试卡号

| 卡号 | 场景 |
|-----|-----|
| `4242 4242 4242 4242` | 成功支付 |
| `4000 0000 0000 9995` | 支付失败（余额不足） |
| `4000 0025 0000 3155` | 需要 3D Secure 验证 |
| `4000 0000 0000 0341` | 附加卡时失败 |

### 8.3 测试支付宝/微信

- Stripe 测试模式提供模拟跳转页面
- 点击 `Authorize test payment` 模拟支付成功
- 点击 `Fail test payment` 模拟支付失败

### 8.4 测试 Webhook

```bash
# 使用 Stripe CLI 转发 webhook 到本地
stripe listen --forward-to localhost:8000/webhook/stripe

# 触发测试事件
stripe trigger checkout.session.completed
stripe trigger customer.subscription.deleted
```

---

## 9. 上线检查清单

### 9.1 Stripe 配置

- [ ] 切换到 Live 模式
- [ ] 更新 API Keys (sk_live_xxx)
- [ ] 更新 Webhook Secret (whsec_xxx)
- [ ] 确认所有 Price ID 使用 Live 版本
- [ ] 激活 Alipay / WeChat Pay
- [ ] 配置 Customer Portal

### 9.2 代码配置

- [ ] 环境变量已更新为生产配置
- [ ] Webhook URL 已更新为生产域名
- [ ] Success/Cancel URL 已更新
- [ ] 错误处理和日志完善

### 9.3 业务流程

- [ ] 支付成功邮件模板准备
- [ ] 续费提醒邮件模板准备
- [ ] 客服话术准备（退款、争议处理）
- [ ] 财务对账流程确认

---

## 10. 常见问题 FAQ

### Q1: 为什么大陆用户不能用信用卡订阅？

A: 可以，但需要注意：
1. 大陆发行的 Visa/MasterCard 属于「国际卡」，会额外收取 0.5% 费用
2. 部分大陆银行卡可能因跨境限制导致扣款失败
3. 支付宝/微信更符合国内用户习惯，转化率更高

### Q2: 预付用户如何处理退款？

A: 
1. 支付宝退款期限为 90 天，微信为 180 天
2. 退款需按剩余天数比例计算
3. 建议通过 Stripe Dashboard 手动处理退款

### Q3: 用户切换地区怎么办？

A: 
1. 预付用户可以继续使用直到到期
2. 订阅用户可以取消后重新购买
3. 建议提供「套餐迁移」功能，折算剩余价值

### Q4: 如何处理汇率波动？

A: 
1. HKD 价格固定，汇率风险由用户承担
2. 前端显示「以港币结算，支付宝自动换汇」
3. 可考虑每季度根据汇率调整 HKD 定价

---

## 附录 A: 数据库 Schema 建议

```sql
-- 用户表扩展字段
ALTER TABLE users ADD COLUMN vip_status VARCHAR(20) DEFAULT 'inactive';
-- inactive | active | expired | cancelled | suspended

ALTER TABLE users ADD COLUMN vip_type VARCHAR(20);
-- prepaid | subscription

ALTER TABLE users ADD COLUMN expire_at TIMESTAMP;
ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(100);
ALTER TABLE users ADD COLUMN stripe_subscription_id VARCHAR(100);
ALTER TABLE users ADD COLUMN current_plan VARCHAR(50);
ALTER TABLE users ADD COLUMN payment_failed_count INT DEFAULT 0;

-- 支付记录表
CREATE TABLE payment_records (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    stripe_session_id VARCHAR(100),
    stripe_payment_intent_id VARCHAR(100),
    amount DECIMAL(10,2),
    currency VARCHAR(10),
    plan_type VARCHAR(20),
    region VARCHAR(10),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 附录 B: 环境变量配置

```bash
# .env.production

# Stripe Live Keys
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Price IDs (Live)
PRICE_SUB_MONTHLY_USD=price_xxx
PRICE_SUB_QUARTERLY_USD=price_xxx
PRICE_SUB_YEARLY_USD=price_xxx
PRICE_PREPAID_1M_HKD=price_xxx
PRICE_PREPAID_3M_HKD=price_xxx
PRICE_PREPAID_12M_HKD=price_xxx

# URLs
SUCCESS_URL=https://vibelife.com/payment/success
CANCEL_URL=https://vibelife.com/pricing
PORTAL_RETURN_URL=https://vibelife.com/account
```

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|-----|------|---------|
| 1.0 | 2024-12 | 初始版本 |
| 2.0 | 2025-01 | 重大更新：支付宝/微信改为预付模式；更新费率；添加 Customer Portal 集成 |

---

> 📧 如有问题，请联系技术团队