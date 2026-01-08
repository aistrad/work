# VibeLife 矩阵战略架构方案

> **文档版本**: v1.0
> **更新日期**: 2026-01-07
> **战略阶段**: Phase 1 & 2 去中心化流量验证 → Phase 3 中心化生态聚合

---

## 1. 战略概述

### 1.1 矩阵战略核心

| 阶段 | 目标 | 架构特征 |
|------|------|----------|
| **Phase 1** | 去中心化获客 + 验证 | 独立子域名，快速试错 |
| **Phase 2** | 矩阵扩展 + 交叉销售 | 统一账户，独立收费 |
| **Phase 3** | 中心化生态 | 主 App 聚合，子域名变落地页 |

### 1.2 核心决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| **域名策略** | 子域名 (Subdomain) | 工程速度 + 风险隔离 + 独立品牌感 |
| **命名风格** | 直接命名 (bazi/zodiac) | SEO 友好 + 中文用户易记 |
| **路由策略** | 路由组物理隔离 | (bazi)/ (zodiac)/ 独立页面文件，深度定制 UI |
| **账户体系** | 共享注册登录 | Cookie 设在 .vibelife.app，跨子域名 SSO |
| **收费模式** | 各 Skill 独立收费 | 系统支持差异化定价，具体价格待定 |
| **数据策略** | 深度共享 | 「了解你越多越深」核心价值 |
| **视觉关联** | 强关联 - 统一顶栏 | 品牌矩阵感 |
| **主站定位** | 品牌索引页 (Phase 1) | www.vibelife.app 作为品牌入口 |
| **支付架构** | Stripe + Airwallex 双轨 | 海外主体，国内外用户各半 |
| **定价币种** | 双币种 (CNY/USD) | 根据用户地区自动切换 |
| **计费模型** | 订阅 + 单次 + 增值服务 | 灵活的商业模式 |

---

## 2. 域名架构

### 2.1 子域名规划

```
┌─────────────────────────────────────────────────────────────────┐
│                     vibelife.app 域名矩阵                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   www.vibelife.app          ← 品牌索引页（Phase 1）             │
│        │                                                        │
│        ├── bazi.vibelife.app    ← 八字命理（P1 上线）           │
│        │                                                        │
│        ├── zodiac.vibelife.app  ← 星座占星（P1 上线）           │
│        │                                                        │
│        ├── mbti.vibelife.app    ← MBTI 人格（P2 规划）          │
│        │                                                        │
│        ├── career.vibelife.app  ← 职业发展（P2 规划）           │
│        │                                                        │
│        └── app.vibelife.app     ← 主 App（Phase 3）             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 DNS 配置

```
# Vercel/Cloudflare DNS 配置
*.vibelife.app    CNAME    cname.vercel-dns.com
www.vibelife.app  CNAME    cname.vercel-dns.com
```

### 2.3 Vercel 配置 (vercel.json)

> **路由策略**：采用路由组物理隔离模式，每个子域名映射到对应的路由组目录，实现深度定制 UI。

```json
{
  "rewrites": [
    {
      "source": "/:path*",
      "has": [{ "type": "host", "value": "www.vibelife.app" }],
      "destination": "/www/:path*"
    },
    {
      "source": "/:path*",
      "has": [{ "type": "host", "value": "bazi.vibelife.app" }],
      "destination": "/bazi/:path*"
    },
    {
      "source": "/:path*",
      "has": [{ "type": "host", "value": "zodiac.vibelife.app" }],
      "destination": "/zodiac/:path*"
    }
  ]
}
```

---

## 3. 账户与认证架构

### 3.1 共享账户 + 独立订阅模型

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户账户层（全局共享）                     │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  User                                                   │   │
│   │  ├── id: UUID (全局唯一)                                │   │
│   │  ├── email / phone / oauth_provider                     │   │
│   │  ├── created_at                                         │   │
│   │  └── Cookie Domain: .vibelife.app (根域名)              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│              ┌───────────────┼───────────────┐                   │
│              ▼               ▼               ▼                   │
│   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│   │  Bazi Profile   │ │ Zodiac Profile  │ │  MBTI Profile   │   │
│   │                 │ │                 │ │                 │   │
│   │ • 命盘数据      │ │ • 星盘数据      │ │ • 类型数据      │   │
│   │ • 对话历史      │ │ • 对话历史      │ │ • 对话历史      │   │
│   │ • 报告记录      │ │ • 报告记录      │ │ • 报告记录      │   │
│   └────────┬────────┘ └────────┬────────┘ └────────┬────────┘   │
│            │                   │                   │             │
│   ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐   │
│   │ Bazi Subscribe  │ │Zodiac Subscribe │ │ MBTI Subscribe  │   │
│   │                 │ │                 │ │                 │   │
│   │ tier: pro       │ │ tier: free      │ │ tier: free      │   │
│   │ price: ¥19.9/mo │ │ price: ¥19.9/mo │ │ price: ¥19.9/mo │   │
│   └─────────────────┘ └─────────────────┘ └─────────────────┘   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                        共享数据层                                │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Shared Profile (深度共享)                              │   │
│   │  ├── basic: { birth_datetime, birth_location, gender }  │   │
│   │  ├── life_context: { career, relationship, events }     │   │
│   │  ├── ai_insights: { traits, patterns, growth_areas }    │   │
│   │  └── identity_prism: { core, inner, outer }             │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 SSO 技术实现

**Cookie 设置（根域名共享）**：
```typescript
// apps/api/services/identity/auth.py
def set_auth_cookie(response: Response, token: str):
    response.set_cookie(
        key="vibelife_token",
        value=token,
        domain=".vibelife.app",  # 关键：根域名
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=60 * 60 * 24 * 30  # 30 天
    )
```

**前端 Cookie 读取**：
```typescript
// apps/web/src/lib/auth.ts
export function getAuthToken(): string | null {
  // Cookie 自动在所有 *.vibelife.app 子域名共享
  return Cookies.get('vibelife_token');
}
```

### 3.3 数据库 Schema 扩展

```sql
-- 用户表（已有）
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订阅表（按 Skill 独立）
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill TEXT NOT NULL,  -- 'bazi', 'zodiac', 'mbti', 'career'
    tier TEXT NOT NULL DEFAULT 'free',  -- 'free', 'pro', 'premium'
    price_cents INT,  -- 支持差异化定价
    status TEXT NOT NULL DEFAULT 'active',
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    stripe_subscription_id TEXT,
    UNIQUE(user_id, skill)
);

-- Phase 2: 全家桶套餐
CREATE TABLE bundle_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    bundle_type TEXT NOT NULL,  -- 'all_access'
    price_cents INT,
    status TEXT,
    starts_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

-- 共享 Profile（已有 user_profiles 表）
-- ai_insights, identity_prism 等数据全局共享

-- Skill 专属数据
CREATE TABLE skill_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill TEXT NOT NULL,
    data_type TEXT NOT NULL,  -- 'conversation', 'report', 'chart'
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 4. 前端架构

### 4.1 代码组织（Monorepo + 路由组）

```
apps/web/src/
├── app/
│   │
│   ├── (www)/                    # 主站（品牌索引页）
│   │   ├── layout.tsx            # 主站布局
│   │   └── page.tsx              # 品牌索引页
│   │
│   ├── (bazi)/                   # Bazi 路由组
│   │   ├── layout.tsx            # Bazi 专属布局
│   │   ├── page.tsx              # Bazi 首页
│   │   ├── chat/page.tsx         # 聊天
│   │   ├── chart/page.tsx        # 命盘
│   │   ├── report/page.tsx       # 报告
│   │   └── relationship/page.tsx # 关系
│   │
│   ├── (zodiac)/                 # Zodiac 路由组
│   │   ├── layout.tsx            # Zodiac 专属布局
│   │   ├── page.tsx              # Zodiac 首页
│   │   ├── chat/page.tsx
│   │   ├── chart/page.tsx
│   │   ├── report/page.tsx
│   │   └── relationship/page.tsx
│   │
│   ├── (shared)/                 # 共享路由
│   │   ├── auth/
│   │   │   ├── login/page.tsx
│   │   │   ├── register/page.tsx
│   │   │   └── sso-callback/page.tsx
│   │   └── me/
│   │       ├── page.tsx          # 个人中心
│   │       └── subscriptions/page.tsx  # 订阅管理
│   │
│   └── middleware.ts             # 子域名路由中间件
│
├── components/
│   ├── core/                     # 共享核心组件
│   │   ├── LuminousPaper.tsx
│   │   ├── BreathAura.tsx
│   │   ├── InsightCard.tsx
│   │   └── GlobalNav.tsx         # 统一顶栏
│   │
│   ├── chat/                     # 共享聊天组件
│   │   ├── ChatContainer.tsx
│   │   ├── ChatMessage.tsx
│   │   └── ChatInput.tsx
│   │
│   ├── bazi/                     # Bazi 专属组件
│   │   ├── BaziChart.tsx
│   │   ├── WuxingDisplay.tsx
│   │   ├── DayunTimeline.tsx
│   │   └── BaziThemeProvider.tsx
│   │
│   └── zodiac/                   # Zodiac 专属组件
│       ├── NatalChart.tsx
│       ├── PlanetPositions.tsx
│       ├── TransitOverlay.tsx
│       └── ZodiacThemeProvider.tsx
│
└── styles/
    ├── globals.css               # 共享基础样式
    ├── themes/
    │   ├── bazi.css              # 玄金 #8B7355 + 朱砂 #C45C48
    │   └── zodiac.css            # 星蓝 #4A5568 + 金线 #D4AF37
    └── components/               # 组件样式
```

### 4.2 Middleware 子域名路由

```typescript
// apps/web/src/middleware.ts
import { NextRequest, NextResponse } from 'next/server';

const SKILL_DOMAINS: Record<string, string> = {
  'bazi': 'bazi',
  'zodiac': 'zodiac',
  'mbti': 'mbti',
  'career': 'career',
  'www': 'www',
};

export function middleware(request: NextRequest) {
  const hostname = request.headers.get('host') || '';
  const subdomain = hostname.split('.')[0];

  // 识别 skill
  const skill = SKILL_DOMAINS[subdomain] || 'bazi';

  // 设置 skill 到 Cookie 和 Header
  const response = NextResponse.next();
  response.cookies.set('vibelife_skill', skill, {
    domain: '.vibelife.app',
    path: '/',
  });
  response.headers.set('x-vibelife-skill', skill);

  return response;
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### 4.3 统一顶栏组件

```typescript
// apps/web/src/components/core/GlobalNav.tsx
'use client';

import { useSkill } from '@/providers/SkillProvider';
import Link from 'next/link';

const SKILL_LINKS = [
  { skill: 'bazi', label: '八字', href: 'https://bazi.vibelife.app' },
  { skill: 'zodiac', label: '星座', href: 'https://zodiac.vibelife.app' },
  { skill: 'mbti', label: 'MBTI', href: 'https://mbti.vibelife.app', disabled: true },
];

export function GlobalNav() {
  const { skill: currentSkill } = useSkill();

  return (
    <nav className="h-12 border-b border-vellum-200 bg-vellum/80 backdrop-blur">
      <div className="flex items-center justify-between px-4 h-full">
        {/* Logo */}
        <Link href="https://www.vibelife.app" className="flex items-center gap-2">
          <span className="text-lg font-serif text-ink">VibeLife</span>
        </Link>

        {/* Skill 导航 */}
        <div className="flex items-center gap-4">
          {SKILL_LINKS.map(({ skill, label, href, disabled }) => (
            <a
              key={skill}
              href={disabled ? undefined : href}
              className={`
                text-sm transition-colors
                ${currentSkill === skill
                  ? 'text-ink font-medium'
                  : 'text-ink/60 hover:text-ink'}
                ${disabled ? 'opacity-40 cursor-not-allowed' : ''}
              `}
            >
              {label}
            </a>
          ))}
        </div>

        {/* 用户菜单 */}
        <UserMenu />
      </div>
    </nav>
  );
}
```

---

## 5. 后端服务架构

### 5.1 服务共享模型

```
┌─────────────────────────────────────────────────────────────────┐
│                        API Gateway                               │
│                   api.vibelife.app                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   所有子域名共享同一个后端 API                                    │
│                                                                 │
│   bazi.vibelife.app  ─┐                                        │
│                       │                                         │
│   zodiac.vibelife.app ├──▶  api.vibelife.app                   │
│                       │                                         │
│   mbti.vibelife.app  ─┘                                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   API 路由                                                      │
│   ─────────────────────────────────────────────────────────     │
│                                                                 │
│   POST /api/v1/chat/stream                                      │
│        Body: { skill: "bazi", message: "..." }                  │
│                                                                 │
│   POST /api/v1/report/generate                                  │
│        Body: { skill: "zodiac", level: "full" }                 │
│                                                                 │
│   GET /api/v1/user/subscriptions                                │
│        Response: [                                              │
│          { skill: "bazi", tier: "pro", expires_at: "..." },     │
│          { skill: "zodiac", tier: "free" }                      │
│        ]                                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 订阅验证中间件

```python
# apps/api/middleware/subscription.py
from functools import wraps
from fastapi import HTTPException, Request

def require_subscription(skill: str, min_tier: str = "pro"):
    """检查用户是否有指定 Skill 的订阅"""
    def decorator(func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            user_id = request.state.user_id

            # 检查订阅
            subscription = await get_user_subscription(user_id, skill)

            if not subscription or subscription.tier < min_tier:
                raise HTTPException(
                    status_code=402,
                    detail={
                        "error": "subscription_required",
                        "skill": skill,
                        "required_tier": min_tier,
                        "current_tier": subscription.tier if subscription else "free"
                    }
                )

            return await func(request, *args, **kwargs)
        return wrapper
    return decorator

# 使用示例
@router.post("/report/generate")
@require_subscription(skill_from_body=True, min_tier="pro")
async def generate_report(request: ReportRequest):
    ...
```

### 5.3 定价配置

> **定价策略**：Phase 1 定价待定，系统先支持差异化定价能力。以下为示例配置。

```python
# apps/api/config/pricing.py
from typing import Dict
from dataclasses import dataclass

@dataclass
class SkillPricing:
    skill: str
    tiers: Dict[str, int]  # tier -> price_cents

# Phase 1: 定价待定，系统支持差异化定价
# 以下为示例配置，上线前确认具体价格
SKILL_PRICING = {
    "bazi": SkillPricing(
        skill="bazi",
        tiers={
            "free": 0,
            "pro": 1990,      # ¥19.9/月（待定）
            "premium": 2990,  # ¥29.9/月（预留）
        }
    ),
    "zodiac": SkillPricing(
        skill="zodiac",
        tiers={
            "free": 0,
            "pro": 1990,      # ¥19.9/月（待定）
            "premium": 2990,
        }
    ),
}

# Phase 2: 全家桶套餐
BUNDLE_PRICING = {
    "all_access": {
        "monthly": 4990,   # ¥49.9/月
        "yearly": 39900,   # ¥399/年
    }
}
```

---

## 6. 支付与收费架构

### 6.1 支付服务商策略

> **核心决策**：网站部署海外，仅海外主体，采用 **Stripe 为主 + Airwallex 补充** 的双轨支付架构。

```
┌─────────────────────────────────────────────────────────────────┐
│                        支付架构总览                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   用户地区识别                                                   │
│        │                                                        │
│        ├─── 海外用户 ──────────────────────┐                    │
│        │                                   │                    │
│        │    ┌─────────────────────────┐    │                    │
│        │    │       Stripe            │    │                    │
│        │    │                         │    │                    │
│        │    │  • Credit Card          │    │                    │
│        │    │  • Apple Pay            │    │                    │
│        │    │  • Google Pay           │    │                    │
│        │    │  • PayPal (via Stripe)  │    │                    │
│        │    └─────────────────────────┘    │                    │
│        │                                   │                    │
│        └─── 国内用户 ──────────────────────┤                    │
│                                            │                    │
│             ┌─────────────────────────┐    │                    │
│             │      Airwallex          │    │                    │
│             │    (跨境收单)            │    │                    │
│             │                         │    │                    │
│             │  • 微信支付 (WeChat Pay) │    │                    │
│             │  • 支付宝 (Alipay)       │    │                    │
│             └─────────────────────────┘    │                    │
│                                            │                    │
│                                            ▼                    │
│                              ┌─────────────────────────┐        │
│                              │     海外银行账户         │        │
│                              │   (统一结算)            │        │
│                              └─────────────────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Stripe vs Airwallex 对比

| 维度 | Stripe | Airwallex |
|------|--------|-----------|
| **海外信用卡** | ✅ 最佳体验 | ✅ 支持 |
| **Apple Pay / Google Pay** | ✅ 原生支持 | ⚠️ 有限支持 |
| **微信支付 (跨境)** | ⚠️ 需中国实体 | ✅ 海外主体可用 |
| **支付宝 (跨境)** | ⚠️ 需中国实体 | ✅ 海外主体可用 |
| **订阅管理** | ✅ Stripe Billing 强大 | ⚠️ 需自建 |
| **费率 (海外)** | 2.9% + $0.30 | 2.5% + $0.30 |
| **费率 (国内)** | N/A | 3.5% + ¥0.50 |
| **适用场景** | 海外用户为主 | 国内用户跨境收款 |

### 6.3 双轨支付技术实现

```python
# apps/api/services/billing/payment_router.py
from enum import Enum
from typing import Optional

class PaymentProvider(Enum):
    STRIPE = "stripe"
    AIRWALLEX = "airwallex"

class PaymentRouter:
    """根据用户地区和支付方式路由到对应支付服务商"""

    def get_provider(
        self,
        user_region: str,
        payment_method: str
    ) -> PaymentProvider:
        # 国内用户 + 微信/支付宝 → Airwallex
        if user_region == "CN" and payment_method in ["wechat_pay", "alipay"]:
            return PaymentProvider.AIRWALLEX

        # 其他情况 → Stripe
        return PaymentProvider.STRIPE

    async def create_checkout_session(
        self,
        user_id: str,
        product_type: str,  # 'subscription' | 'one_time' | 'addon'
        product_id: str,
        currency: str,
        user_region: str,
        payment_method: Optional[str] = None
    ):
        provider = self.get_provider(user_region, payment_method)

        if provider == PaymentProvider.STRIPE:
            return await self.stripe_service.create_session(...)
        else:
            return await self.airwallex_service.create_session(...)
```

### 6.4 双币种定价策略

```python
# apps/api/config/pricing.py
from dataclasses import dataclass
from typing import Dict

@dataclass
class MultiCurrencyPrice:
    cny: int  # 人民币（分）
    usd: int  # 美元（美分）

# 订阅定价（双币种）
SUBSCRIPTION_PRICING = {
    "bazi": {
        "pro": {
            "monthly": MultiCurrencyPrice(cny=1990, usd=299),   # ¥19.9 / $2.99
            "yearly": MultiCurrencyPrice(cny=15900, usd=2399),  # ¥159 / $23.99
        }
    },
    "zodiac": {
        "pro": {
            "monthly": MultiCurrencyPrice(cny=1990, usd=299),
            "yearly": MultiCurrencyPrice(cny=15900, usd=2399),
        }
    },
}

# 单次购买定价
ONE_TIME_PRICING = {
    "full_report": MultiCurrencyPrice(cny=1990, usd=299),      # ¥19.9 / $2.99
    "ai_portrait": MultiCurrencyPrice(cny=990, usd=149),       # ¥9.9 / $1.49
    "relationship_report": MultiCurrencyPrice(cny=1990, usd=299),
}

# 增值服务定价
ADDON_PRICING = {
    "ai_art_report": MultiCurrencyPrice(cny=990, usd=149),     # AI 生图报告
    "deep_analysis": MultiCurrencyPrice(cny=1990, usd=299),    # 深度分析
    "extra_chat_quota": MultiCurrencyPrice(cny=590, usd=99),   # 额外对话额度
}

# Phase 2: 全家桶套餐
BUNDLE_PRICING = {
    "all_access": {
        "monthly": MultiCurrencyPrice(cny=4990, usd=699),      # ¥49.9 / $6.99
        "yearly": MultiCurrencyPrice(cny=39900, usd=5999),     # ¥399 / $59.99
    }
}

def get_price(price: MultiCurrencyPrice, region: str) -> tuple[int, str]:
    """根据用户地区返回对应币种价格"""
    if region == "CN":
        return price.cny, "CNY"
    return price.usd, "USD"
```

### 6.5 产品类型与计费模型

```
┌─────────────────────────────────────────────────────────────────┐
│                        计费模型总览                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. 订阅 (Subscription)                                        │
│   ─────────────────────────────────────────────────────────     │
│   • 按 Skill 独立订阅（bazi_pro, zodiac_pro）                   │
│   • 支持月付 / 年付（年付享折扣）                                │
│   • Stripe Billing 管理订阅生命周期                             │
│   • 自动续费 + 到期提醒                                         │
│                                                                 │
│   2. 单次购买 (One-time)                                        │
│   ─────────────────────────────────────────────────────────     │
│   • 完整报告套餐                                                │
│   • AI 生图报告                                                 │
│   • 关系分析报告                                                │
│   • 购买后永久有效                                              │
│                                                                 │
│   3. 增值服务 (Add-on)                                          │
│   ─────────────────────────────────────────────────────────     │
│   • 订阅用户可额外购买                                          │
│   • AI 艺术报告（高清海报）                                     │
│   • 深度咨询时长                                                │
│   • 额外对话额度                                                │
│                                                                 │
│   4. 全家桶套餐 (Bundle) - Phase 2                              │
│   ─────────────────────────────────────────────────────────     │
│   • All Access：解锁所有 Skill                                  │
│   • 月付 / 年付                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.6 数据库 Schema（支付相关）

```sql
-- 订阅表（按 Skill 独立）
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill TEXT NOT NULL,  -- 'bazi', 'zodiac', 'mbti', 'career'
    tier TEXT NOT NULL DEFAULT 'free',
    billing_cycle TEXT,  -- 'monthly', 'yearly'
    currency TEXT NOT NULL,  -- 'CNY', 'USD'
    price_cents INT,
    status TEXT NOT NULL DEFAULT 'active',
    payment_provider TEXT,  -- 'stripe', 'airwallex'
    provider_subscription_id TEXT,  -- Stripe/Airwallex 订阅 ID
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, skill)
);

-- 单次购买记录
CREATE TABLE purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_type TEXT NOT NULL,  -- 'report', 'ai_portrait', 'relationship'
    product_id TEXT,  -- 关联的报告/产品 ID
    skill TEXT,
    currency TEXT NOT NULL,
    amount_cents INT NOT NULL,
    payment_provider TEXT,
    provider_payment_id TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 增值服务购买记录
CREATE TABLE addon_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    addon_type TEXT NOT NULL,  -- 'ai_art_report', 'deep_analysis', 'extra_chat_quota'
    skill TEXT,
    currency TEXT NOT NULL,
    amount_cents INT NOT NULL,
    quantity INT DEFAULT 1,
    payment_provider TEXT,
    provider_payment_id TEXT,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ  -- 部分增值服务有有效期
);

-- 支付事件日志（对账用）
CREATE TABLE payment_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    event_type TEXT NOT NULL,  -- 'checkout.completed', 'subscription.renewed', etc.
    payment_provider TEXT NOT NULL,
    provider_event_id TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_provider ON subscriptions(payment_provider, provider_subscription_id);
CREATE INDEX idx_purchases_user ON purchases(user_id);
CREATE INDEX idx_payment_events_provider ON payment_events(payment_provider, provider_event_id);
```

### 6.7 Webhook 处理

```python
# apps/api/routes/webhooks.py
from fastapi import APIRouter, Request, HTTPException
import stripe
from services.billing import SubscriptionService, PurchaseService

router = APIRouter()

# Stripe Webhook
@router.post("/webhooks/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # 处理事件
    if event["type"] == "checkout.session.completed":
        await handle_checkout_completed(event["data"]["object"])
    elif event["type"] == "customer.subscription.updated":
        await handle_subscription_updated(event["data"]["object"])
    elif event["type"] == "customer.subscription.deleted":
        await handle_subscription_canceled(event["data"]["object"])
    elif event["type"] == "invoice.payment_failed":
        await handle_payment_failed(event["data"]["object"])

    return {"status": "ok"}

# Airwallex Webhook
@router.post("/webhooks/airwallex")
async def airwallex_webhook(request: Request):
    payload = await request.json()
    signature = request.headers.get("x-signature")

    # 验证签名
    if not verify_airwallex_signature(payload, signature):
        raise HTTPException(status_code=400, detail="Invalid signature")

    event_type = payload.get("name")

    if event_type == "payment_intent.succeeded":
        await handle_airwallex_payment_success(payload["data"]["object"])
    elif event_type == "payment_intent.payment_failed":
        await handle_airwallex_payment_failed(payload["data"]["object"])

    return {"status": "ok"}
```

### 6.8 前端支付流程

```typescript
// apps/web/src/lib/checkout.ts
import { loadStripe } from '@stripe/stripe-js';

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_KEY!);

interface CheckoutParams {
  productType: 'subscription' | 'one_time' | 'addon';
  productId: string;
  skill?: string;
}

export async function initiateCheckout(params: CheckoutParams) {
  // 1. 获取用户地区
  const region = await detectUserRegion();

  // 2. 调用后端创建 checkout session
  const response = await fetch('/api/v1/billing/checkout', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ...params,
      region,
    }),
  });

  const { provider, sessionId, redirectUrl } = await response.json();

  // 3. 根据支付服务商跳转
  if (provider === 'stripe') {
    const stripe = await stripePromise;
    await stripe?.redirectToCheckout({ sessionId });
  } else if (provider === 'airwallex') {
    // Airwallex 跳转到支付页面
    window.location.href = redirectUrl;
  }
}

// 用户地区检测
async function detectUserRegion(): Promise<string> {
  // 优先使用用户设置
  const savedRegion = localStorage.getItem('user_region');
  if (savedRegion) return savedRegion;

  // 其次使用 IP 地理位置
  try {
    const response = await fetch('https://ipapi.co/json/');
    const data = await response.json();
    return data.country_code;
  } catch {
    return 'US'; // 默认海外
  }
}
```

---

## 7. 数据共享策略

### 7.1 共享数据范围

| 数据类型 | 共享级别 | 说明 |
|----------|----------|------|
| **基础信息** | ✅ 全局共享 | birth_datetime, birth_location, gender, name |
| **生活上下文** | ✅ 全局共享 | career, relationship, life_stage, recent_events |
| **AI 洞察** | ✅ 全局共享 | personality_traits, communication_style, emotional_patterns |
| **Identity Prism** | ✅ 全局共享 | core, inner, outer 三元身份 |
| **对话历史** | ❌ Skill 独立 | 各 Skill 对话分开存储 |
| **报告记录** | ❌ Skill 独立 | 各 Skill 报告分开存储 |
| **订阅状态** | ❌ Skill 独立 | 各 Skill 独立收费 |

### 7.2 跨 Skill 数据利用

```python
# 用户在 bazi 积累的画像可在 zodiac 使用
async def build_context(user_id: str, skill: str):
    # 1. 加载共享 Profile（所有 Skill 贡献的数据）
    shared_profile = await get_shared_profile(user_id)

    # 2. 加载 Skill 专属数据
    skill_data = await get_skill_data(user_id, skill)

    # 3. 构建上下文
    context = {
        "shared": {
            "basic": shared_profile.basic,
            "life_context": shared_profile.life_context,
            "ai_insights": shared_profile.ai_insights,
            "identity_prism": shared_profile.identity_prism,
        },
        "skill_specific": skill_data,
    }

    return context
```

---

## 8. 部署架构

### 8.1 Vercel 多域名部署

```
┌─────────────────────────────────────────────────────────────────┐
│                        Vercel Project                            │
│                      vibelife-web                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Domains:                                                      │
│   ├── www.vibelife.app      (Primary)                          │
│   ├── bazi.vibelife.app     (Alias)                            │
│   ├── zodiac.vibelife.app   (Alias)                            │
│   └── *.vibelife.app        (Wildcard)                         │
│                                                                 │
│   Environment Variables:                                        │
│   ├── NEXT_PUBLIC_API_URL=https://api.vibelife.app             │
│   ├── NEXT_PUBLIC_COOKIE_DOMAIN=.vibelife.app                  │
│   └── NEXT_PUBLIC_DEFAULT_SKILL=bazi                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 本地开发配置

```bash
# /etc/hosts (本地开发)
127.0.0.1 www.vibelife.local
127.0.0.1 bazi.vibelife.local
127.0.0.1 zodiac.vibelife.local
```

```env
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_COOKIE_DOMAIN=.vibelife.local
```

---

## 9. 实施路线图

### Phase 1 (当前)

- [x] 子域名架构设计
- [x] 支付架构设计（Stripe + Airwallex 双轨）
- [ ] middleware.ts 子域名路由完善
- [ ] (www)/ (bazi)/ (zodiac)/ 路由组创建
- [ ] 统一顶栏 GlobalNav 实现
- [ ] SSO Cookie 跨域配置
- [ ] 订阅表 Schema 扩展（支持多币种、多支付商）
- [ ] Stripe 集成（海外信用卡、订阅管理）
- [ ] Airwallex 集成（国内微信/支付宝跨境收单）
- [ ] 双币种定价系统
- [ ] Webhook 处理（Stripe + Airwallex）

### Phase 2

- [ ] 全家桶套餐（All Access）
- [ ] MBTI Skill 上线
- [ ] 增值服务商店
- [ ] 跨 Skill 数据分析
- [ ] 订阅用户留存优化

### Phase 3

- [ ] 主 App (app.vibelife.app) 开发
- [ ] 子域名转为落地页
- [ ] 原生 App 开发

---

## 10. 关键文件清单

### 前端

| 文件 | 作用 |
|------|------|
| `apps/web/src/middleware.ts` | 子域名路由 |
| `apps/web/src/providers/SkillProvider.tsx` | Skill 上下文 |
| `apps/web/src/components/core/GlobalNav.tsx` | 统一顶栏 |
| `apps/web/src/app/(www)/layout.tsx` | 主站布局 |
| `apps/web/src/app/(bazi)/layout.tsx` | Bazi 专属布局 |
| `apps/web/src/app/(zodiac)/layout.tsx` | Zodiac 专属布局 |
| `apps/web/src/lib/checkout.ts` | 支付流程 |
| `vercel.json` | 部署配置 |

### 后端

| 文件 | 作用 |
|------|------|
| `apps/api/services/billing/payment_router.py` | 支付路由（Stripe/Airwallex） |
| `apps/api/services/billing/stripe_service.py` | Stripe 服务 |
| `apps/api/services/billing/airwallex_service.py` | Airwallex 服务 |
| `apps/api/config/pricing.py` | 定价配置（双币种） |
| `apps/api/middleware/subscription.py` | 订阅验证 |
| `apps/api/routes/webhooks.py` | Webhook 处理 |
| `apps/api/routes/billing.py` | 计费 API |

### 数据库

| 文件 | 作用 |
|------|------|
| `migrations/002_subscriptions.sql` | 订阅表 Schema |
| `migrations/003_purchases.sql` | 单次购买表 |
| `migrations/004_addon_purchases.sql` | 增值服务表 |
| `migrations/005_payment_events.sql` | 支付事件日志 |
