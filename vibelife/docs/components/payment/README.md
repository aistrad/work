# VibeLife 支付系统文档

## 📚 文档导航

### 🔧 运营配置
- **[运营配置手册](./运营配置手册.md)** - Stripe + PayPal 配置完整指南
- **[第三方服务密钥清单](./第三方服务密钥清单.md)** - 快速查找配置项和密钥状态

### 🏗️ 技术实现
- **[Stripe 集成文档](./STRIPE_INTEGRATION.md)** - Stripe API 和前端集成详情
- **[PayPal 集成文档](./PAYPAL_INTEGRATION.md)** - PayPal 收单集成详情
- **[双轨制设计](./双轨制设计.md)** - 海外订阅 vs 大陆预付方案
- 后端服务：`apps/api/services/billing/`
- 前端页面：`apps/web/src/app/payment/`
- API 路由：`apps/web/src/app/api/payment/`

---

## 🎯 快速开始

### 场景 1️⃣：配置 Stripe（订阅 + 支付宝/微信）
1. 注册 [Stripe 账号](https://dashboard.stripe.com/register)
2. 获取 API 密钥（测试 / 生产）
3. 创建产品和价格
4. 配置 Webhook
5. 配置环境变量

### 场景 2️⃣：配置 PayPal（全球收款补充）
1. 注册 [PayPal Business 账号](https://www.paypal.com/bizsignup)
2. 创建 REST API 应用获取 Client ID/Secret
3. 配置环境变量
4. 测试沙盒环境

---

## ⚡ 当前配置状态

| 服务 | 状态 | 功能影响 |
|------|------|---------|
| Stripe API | ⚠️ 待配置 | 信用卡/支付宝/微信支付不可用 |
| Stripe Webhook | ⚠️ 待配置 | 无法接收 Stripe 支付回调 |
| Stripe 产品/价格 | ⚠️ 待配置 | 无订阅计划 |
| PayPal API | ⚠️ 待配置 | PayPal 支付不可用 |
| PayPal Webhook | ⚠️ 待配置 | 无法接收 PayPal 支付回调 |

**结论：** 支付系统代码已就绪，需要配置 Stripe 和 PayPal 账号。

---

## 💳 支付方式支持

### Stripe 渠道
| 支付方式 | 状态 | 适用地区 |
|---------|------|---------|
| 信用卡/借记卡 | ✅ 支持 | 全球 |
| Alipay | ✅ 支持 | 中国大陆 |
| WeChat Pay | ✅ 支持 | 中国大陆 |
| Apple Pay | 🔧 可启用 | 海外 |
| Google Pay | 🔧 可启用 | 海外 |

### PayPal 渠道
| 支付方式 | 状态 | 适用地区 |
|---------|------|---------|
| PayPal 余额 | ✅ 支持 | 全球（200+ 国家） |
| 信用卡（Guest） | ✅ 支持 | 全球 |
| 借记卡 | ✅ 支持 | 全球 |
| Pay Later | 🔧 可启用 | 美国/英国/德国等 |

---

## 🔐 支付流程概览

### Stripe 订阅流程（海外用户）
```
用户选择订阅计划 → 创建 Checkout Session → 跳转 Stripe 托管页面 → 支付成功 → Webhook 通知 → 更新用户权益
```

### Stripe 预付流程（大陆用户）
```
用户选择预付套餐 → 创建 PaymentIntent → 前端确认支付 → 支付成功 → Webhook 通知 → 增加用户时长
```

### PayPal 支付流程
```
用户选择 PayPal → 创建 Order → 跳转 PayPal 授权 → 用户确认 → Capture 扣款 → Webhook 通知 → 增加用户时长
```

### 管理订阅
```
用户访问账户页面 → 创建 Billing Portal Session → 跳转 Stripe 门户 → 管理/取消订阅
```

---

## 🛡️ 安全特性

- ✅ **服务端金额计算**：防止客户端篡改价格
- ✅ **Webhook 签名验证**：防止伪造回调
- ✅ **幂等处理**：防止重复扣款
- ✅ **PCI DSS 合规**：敏感数据不经过自有服务器

---

## 📞 技术支持

### 配置问题排查
1. 检查 Stripe Dashboard 的事件日志
2. 查看后端日志：`apps/api/logs/`
3. 验证 Webhook 签名配置

### 常见错误
- `No such price`: Price ID 配置错误
- `Invalid signature`: Webhook Secret 不匹配
- `Card declined`: 用户卡片问题

### 文档更新日志
- 2026-01-25: 添加 PayPal 支付支持
- 2026-01-25: 初始版本创建
