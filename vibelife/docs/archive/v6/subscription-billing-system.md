# VibeLife 订阅与计费系统
> **版本**: v2.0 (已实现)
> **日期**: 2026-01-15
> **状态**: ✅ 迁移完成

---

## 一、系统概览

### 1.1 用户身份状态机

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         VibeLife 用户身份状态机                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│                              ┌──────────────┐                                   │
│                              │   访客流量    │                                   │
│                              └──────┬───────┘                                   │
│                                     │                                           │
│                                     ▼                                           │
│                    ┌────────────────────────────────────┐                       │
│                    │           GUEST (游客)              │                       │
│                    │  · session_id (cookie, 30天)       │                       │
│                    │  · 完整 onboarding                 │                       │
│                    │  · 简版报告                        │                       │
│                    └─────────────┬──────────────────────┘                       │
│                                  │                                              │
│              ┌───────────────────┼───────────────────┐                          │
│              ▼                   ▼                   ▼                          │
│     ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                  │
│     │ 邮箱+密码注册   │  │ 手机号+密码注册 │  │ OAuth 注册     │                  │
│     │  (海外用户)     │  │  (大陆用户)     │  │ Google/Apple  │                  │
│     └───────┬────────┘  └───────┬────────┘  └───────┬────────┘                  │
│             └───────────────────┼───────────────────┘                          │
│                                 │                                              │
│                                 ▼                                              │
│                    ┌────────────────────────────────────┐                       │
│                    │         FREE USER (免费用户)        │                       │
│                    │  · user_id + vibe_id               │                       │
│                    │  · 每日 3 条对话                    │                       │
│                    └─────────────┬──────────────────────┘                       │
│                                  │                                              │
│              ┌───────────────────┼───────────────────┐                          │
│              ▼                   ▼                   ▼                          │
│     ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                  │
│     │ USD 月付 $9.9  │  │ HKD 1月 $39   │  │ 单次报告 ¥19.9 │                  │
│     │  (自动续费)    │  │  (预付模式)    │  │  (一次性)       │                  │
│     └───────┬────────┘  └───────┬────────┘  └───────┬────────┘                  │
│             └───────────────────┼───────────────────┘                          │
│                                 │                                              │
│                                 ▼                                              │
│                    ┌────────────────────────────────────┐                       │
│                    │         PAID USER (付费用户)        │                       │
│                    │  · 每日 200 条对话                  │                       │
│                    │  · 完整报告 + AI海报                │                       │
│                    └─────────────┬──────────────────────┘                       │
│                                  │                                              │
│              ┌───────────────────┴───────────────────┐                          │
│              ▼                                       ▼                          │
│     ┌────────────────┐                      ┌────────────────┐                  │
│     │   续费成功     │                      │  到期/取消     │                  │
│     └────────────────┘                      └───────┬────────┘                  │
│                                                     │                          │
│                                                     ▼                          │
│                                        ┌────────────────────────┐              │
│                                        │  FREE USER (降级)      │              │
│                                        └────────────────────────┘              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 支付双轨制

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            支付流程 (Stripe 双轨制)                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  GET /payment/detect-region → IP 检测 → CN/HK → "CN" | 其他 → "GLOBAL"          │
│                                                                                 │
│                    ┌────────────────┴────────────────┐                          │
│                    │                                 │                          │
│                    ▼                                 ▼                          │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐             │
│  │      CN 轨道 (预付模式)       │  │    GLOBAL 轨道 (订阅模式)    │             │
│  │                              │  │                              │             │
│  │  产品:                       │  │  产品:                       │             │
│  │   · cn_1m  (HK$39/1月)      │  │   · global_monthly  ($9.9)  │             │
│  │   · cn_3m  (HK$99/3月)      │  │   · global_quarterly ($24.9)│             │
│  │   · cn_12m (HK$298/12月)    │  │   · global_yearly ($69.9)   │             │
│  │                              │  │                              │             │
│  │  支付方式:                   │  │  支付方式:                   │             │
│  │   · 支付宝 (Alipay)         │  │   · 信用卡 (Card)           │             │
│  │   · 微信支付 (WeChat Pay)   │  │   · Apple Pay               │             │
│  │                              │  │   · Google Pay              │             │
│  │                              │  │                              │             │
│  │  Stripe mode: "payment"     │  │  Stripe mode: "subscription"│             │
│  └──────────────────────────────┘  └──────────────────────────────┘             │
│                    │                                 │                          │
│                    └────────────────┬────────────────┘                          │
│                                     │                                           │
│                                     ▼                                           │
│                    ┌────────────────────────────────────┐                       │
│                    │   Webhook: checkout.session.completed                      │
│                    │   → SubscriptionService.activate() ✅                      │
│                    └────────────────────────────────────┘                       │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、系统架构 (已实现)

### 2.1 架构图

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              API Routes                                       │
├──────────────────────────────────────────────────────────────────────────────┤
│  payment.py ──────→ SubscriptionService (订阅激活)                            │
│  chat.py    ──────→ UsageService (用量记录 + 计费)                            │
│  entitlement.py ──→ EntitlementService (兼容层)                               │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Services                                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────┐      ┌─────────────────────────┐                │
│  │   SubscriptionService   │◄─────│   EntitlementService    │                │
│  │   (订阅 + 权益管理)     │      │   (兼容层，委托调用)     │                │
│  │                         │      │                         │                │
│  │   · create_prepaid()   │      │   · check_can_chat()   │                │
│  │   · create_stripe()    │      │   · get_entitlements()  │                │
│  │   · check_can_chat()   │      │   · upgrade_to_paid()   │                │
│  │   · get_entitlements() │      └─────────────────────────┘                │
│  │   · expire_overdue()   │                                                  │
│  └─────────────────────────┘                                                  │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         UsageService (统一用量)                          │ │
│  │                                                                          │ │
│  │   记录方法:                           查询方法:                          │ │
│  │   · record_llm_call(tokens, cost)    · get_billing_summary()            │ │
│  │   · record_skill_use(skill_id)       · get_usage_by_skill()             │ │
│  │   · record_tool_call(tool_name)      · get_usage_by_model()             │ │
│  │   · record_conversation()            · get_daily/monthly_usage()        │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Database                                         │
├──────────────────────────────────────────────────────────────────────────────┤
│  subscriptions     - 订阅记录 (prepaid/stripe)                                │
│  usage_events      - 用量事件 (llm_call/skill_use/tool_call)                 │
│  vibe_users        - 用户基础信息                                             │
│  payments          - 支付记录                                                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 层级配置

```python
TIER_CONFIG = {
    "free": {"daily_limit": 3},
    "paid": {"daily_limit": 200},
}
```

### 2.3 模型定价表

```python
MODEL_PRICING = {  # 每 1M tokens (USD)
    "glm-4-flash": {"input": 0.1, "output": 0.1},
    "deepseek-chat": {"input": 0.14, "output": 0.28},
    "deepseek-reasoner": {"input": 0.55, "output": 2.19},
    "gemini-2.0-flash": {"input": 0.075, "output": 0.3},
    "claude-sonnet": {"input": 3.0, "output": 15.0},
    "gpt-4o": {"input": 2.5, "output": 10.0},
}
```

---

## 三、核心数据表

### 3.1 usage_events (新表)

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

-- 索引
CREATE INDEX idx_usage_events_user_date ON usage_events(user_id, created_at);
CREATE INDEX idx_usage_events_billing ON usage_events(user_id, event_type, created_at);
CREATE INDEX idx_usage_events_skill ON usage_events(skill_id, created_at);
```

### 3.2 subscriptions (现有表)

```sql
-- 已存在，核心字段:
id, user_id, plan_code, status, vip_type, region,
started_at, expires_at, stripe_subscription_id, stripe_customer_id,
payment_failed_count, source, created_at, updated_at
```

---

## 四、计费 API

### 4.1 获取月度账单

```http
GET /billing/usage/summary?month=2026-01

Response:
{
    "llm_calls": 150,
    "total_input_tokens": 300000,
    "total_output_tokens": 200000,
    "total_tokens": 500000,
    "total_cost": 0.15,
    "skill_uses": 45,
    "tool_calls": 80,
    "conversations": 120
}
```

### 4.2 按 Skill 统计

```http
GET /billing/usage/by-skill?month=2026-01

Response:
[
    {"skill_id": "bazi", "llm_calls": 80, "tokens": 300000, "cost": 0.09},
    {"skill_id": "zodiac", "llm_calls": 70, "tokens": 200000, "cost": 0.06}
]
```

### 4.3 按模型统计

```http
GET /billing/usage/by-model?month=2026-01

Response:
[
    {"model": "glm-4-flash", "calls": 120, "input_tokens": 200000, "output_tokens": 100000, "cost": 0.05},
    {"model": "deepseek-chat", "calls": 30, "input_tokens": 100000, "output_tokens": 100000, "cost": 0.10}
]
```

---

## 五、关键文件索引

### 5.1 服务层

| 文件 | 描述 |
|------|------|
| `services/billing/subscription.py` | 订阅服务 (含 entitlement 方法) |
| `services/usage/service.py` | 统一用量服务 (支持计费) |
| `services/entitlement/__init__.py` | 兼容层 (委托到 SubscriptionService) |
| `services/agent/__init__.py` | QuotaTracker (简化版配额检查) |
| `services/agent/usage_tracker.py` | 内存用量追踪 (单次请求) |

### 5.2 路由层

| 文件 | 描述 |
|------|------|
| `routes/payment.py` | 支付路由 (Webhook 已修复) |
| `routes/chat.py` | 对话路由 (用量记录已接入) |
| `routes/entitlement.py` | 权益路由 |
| `routes/auth.py` | 认证路由 |

### 5.3 数据库

| 文件 | 描述 |
|------|------|
| `migrations/018_usage_events.sql` | 用量表迁移 |
| `stores/subscription_repo.py` | 订阅数据访问 |

---

## 六、已解决问题

| 问题 | 原状态 | 解决方案 |
|------|--------|----------|
| Webhook 订阅未持久化 | TODO 注释 | 调用 SubscriptionService |
| 用量无法计费 | 不持久化 | 新建 usage_events 表 |
| 服务重叠 | 4个重叠服务 | 合并为 2 个 |
| Token/Cost 丢失 | 只在内存 | UsageService 持久化 |

---

## 七、待办事项

| 优先级 | 任务 | 状态 |
|--------|------|------|
| P1 | 配置 Stripe Price ID | 待配置 |
| P1 | 预付续费提醒 | 待实现 |
| P2 | 邮件发送服务 | 待集成 |
| P2 | Customer Portal 端点 | 待暴露 |
| P3 | 微信登录 | 待规划 |

---

## 八、运维指南

### 8.1 数据库迁移

```bash
psql $DATABASE_URL -f migrations/018_usage_events.sql
```

### 8.2 定时任务

```bash
# crontab
# 每日凌晨2点执行过期检查
0 2 * * * cd /path/to/api && python -c "
from services.billing.subscription import SubscriptionService
from stores.db import get_db_pool
import asyncio

async def run():
    pool = await get_db_pool()
    svc = SubscriptionService(pool)
    count = await svc.expire_overdue_subscriptions()
    print(f'Expired {count} subscriptions')

asyncio.run(run())
"
```

### 8.3 回滚方案

```bash
# 恢复旧表
ALTER TABLE user_usage_deprecated RENAME TO user_usage;
ALTER TABLE usage_records_deprecated RENAME TO usage_records;

# 恢复旧文件
git checkout HEAD~1 -- apps/api/services/entitlement/service.py
git checkout HEAD~1 -- apps/api/services/identity/usage_limits.py
```

---

## 九、验证检查

```bash
# 核心模块导入测试
python -c "
from services.usage import UsageService
from services.entitlement import EntitlementService
from services.billing.subscription import SubscriptionService
from services.agent import QuotaTracker
print('✅ All imports successful')
"

# Webhook 测试
curl -X POST http://localhost:8000/payment/webhook \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: test"
```
