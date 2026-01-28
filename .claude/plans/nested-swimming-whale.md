# VibeLife 上线前 5 个最重要改进

## 原则：简洁，不过度工程化

---

## 改进 1: 修复支付系统 Bug（阻断上线）

### 问题
`paywall.py:112` 引用 `VIBELIFE_ALL`，但枚举只有 `FREE`/`PAID`，会报错

### 修复
```python
# apps/api/services/billing/subscription.py
class SubscriptionTier(str, Enum):
    FREE = "free"
    PAID = "paid"
    VIBELIFE_ALL = "vibelife_all"  # 添加这行
```

### 工作量: 30 分钟

---

## 改进 2: 创建定价页

### 问题
前端没有 `/pricing` 页面，用户看不到价格

### 修复
创建 `apps/web/src/app/pricing/page.tsx`，展示双轨定价：
- CN 用户：HKD 39/99/298
- 海外用户：USD 9.90/24.90/69.90

### 工作量: 1 天

---

## 改进 3: 配置 Stripe Prices

### 步骤
1. Stripe Dashboard 创建 6 个 Price
2. 填入 `.env`:
```
STRIPE_PRICE_PREPAID_1M_HKD=price_xxx
STRIPE_PRICE_PREPAID_3M_HKD=price_xxx
STRIPE_PRICE_PREPAID_12M_HKD=price_xxx
STRIPE_PRICE_SUB_MONTHLY_USD=price_xxx
STRIPE_PRICE_SUB_QUARTERLY_USD=price_xxx
STRIPE_PRICE_SUB_YEARLY_USD=price_xxx
```

### 工作量: 1 小时

---

## 改进 4: 添加 Rate Limiting

### 方案
使用 slowapi，最简配置：

```python
# apps/api/main.py
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

# 在 chat 路由添加
@router.post("/chat/v5/stream")
@limiter.limit("30/minute")  # 每分钟最多 30 次
async def chat_stream(...):
```

### 工作量: 2 小时

---

## 改进 5: 轮换泄露的 API Key

### 问题
`.env.test` 里有真实的 CLAUDE_API_KEY

### 修复
1. 去 Claude 控制台撤销旧 key
2. 生成新 key
3. 更新生产环境配置
4. 清理 `.env.test` 里的敏感数据

### 工作量: 15 分钟

---

## 执行顺序

1. **立即** - 改进 5（轮换 Key）
2. **Day 1** - 改进 1（修复 Bug）+ 改进 4（Rate Limit）
3. **Day 2-3** - 改进 2（定价页）+ 改进 3（Stripe 配置）
4. **Day 4** - 端到端测试支付流程

---

## 验证

```bash
# 支付流程
1. 访问 /pricing 看到价格
2. 点击购买，跳转 Stripe Checkout
3. 完成支付，订阅状态变 active

# Rate Limiting
curl 快速请求 30+ 次，第 31 次返回 429
```

---

## 文件清单

### 修改
- `apps/api/services/billing/subscription.py` (1 行)
- `apps/api/main.py` (添加 limiter)
- `.env` (填 Stripe IDs)

### 新建
- `apps/web/src/app/pricing/page.tsx`
