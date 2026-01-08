# VibeLife Freemium 功能边界设计文档

> **文档版本**: v1.0
> **设计日期**: 2026-01-07
> **商业模式**: Paywall（关键功能付费）+ Freemium（免费增值）
> **核心原则**: 30%免费用户感到满意，但渴望更多

---

## 1. 设计哲学

### 1.1 Freemium 黄金法则

| 法则 | 说明 | VibeLife 实现 |
|------|------|---------------|
| **30% 满意原则** | 免费用户中30%应感到「已经够用」 | 今日运势+命盘预览+轻度对话 |
| **渴望升级** | 满意的同时，明确知道付费会更好 | 差异化展示 + 自然引导 |
| **低摩擦付费** | 付费决策在主动请求时触发 | 用户想要更多时才展示付费墙 |
| **价值透明** | 付费前后价值预期清晰 | 明确列出功能对比表 |
| **公平感** | 免费用户不感到被限制，只是功能少 | 没有「已用完额度」的挫败感 |

### 1.2 转化漏斗设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        VibeLife 转化漏斗                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  100%  新用户                                                    │
│    │                                                            │
│    ▼                                                            │
│   85%   完成快速选择（看到命盘预览）                              │
│    │                                                            │
│    ▼                                                            │
│   70%   看到今日运势（Aha Moment）                               │
│    │                                                            │
│    ▼                                                            │
│   40%   开始深度访谈                                             │
│    │                                                            │
│    ▼                                                            │
│   30%   完成访谈 + 看到Lite报告                                  │
│    │                                                            │
│    ▼                                                            │
│   15%   看到付费墙 + 想要更多                                    │
│    │                                                            │
│    ▼                                                            │
│    5%   转化为付费用户 ✅                                        │
│                                                                  │
│  目标：Free-to-Paid Rate = 5%                                   │
│        (健康范围: 3-8%)                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 功能边界详细定义

### 2.1 免费版（体验版）

**目标**: 让用户体验到核心价值，建立信任，形成口碑传播

```python
FREE_TIER = {
    "name": "体验版",
    "price": "¥0",
    "positioning": "像朋友一样了解你",

    "onboarding": {
        "flow": "快速选择 → 命盘预览 → 今日运势",
        "time_to_aha": "< 30秒",
        "required_info": "仅选择关注点，无需个人信息"
    },

    "features": {
        # 核心免费价值
        "daily_fortune": {
            "name": "今日运势卡片",
            "value": "每日更新，基础运势指数",
            "detail": {
                "overall_score": "总运势指数（0-100）",
                "lucky_items": "今日幸运色/数字/方位",
                "short_insight": "一句话金句（50字内）",
                "frequency": "每日1次"
            },
            "upgrade_trigger": "想要查看下周/本月运势"
        },

        "chart_preview": {
            "name": "命盘可视化预览",
            "value": "专业命盘展示，建立信任感",
            "detail": {
                "chart_type": "四柱八字命盘（静态）",
                "highlight": "日主突出显示",
                "elements": "五行配色（木青/火红/土黄/金白/水黑）",
                "interaction": "无交互，仅展示"
            },
            "upgrade_trigger": "想要查看命盘深度解读"
        },

        "lite_report": {
            "name": "Lite 报告",
            "value": "基础性格和运势分析",
            "detail": {
                "length": "500-800字",
                "sections": [
                    "日主特性（100字）",
                    "今日运势（200字）",
                    "简短建议（150字）"
                ],
                "generation": "即时生成",
                "accessibility": "永久查看"
            },
            "upgrade_trigger": "想要完整深度报告（3000字+）"
        },

        "chat_quota": {
            "name": "AI对话额度",
            "value": "轻度对话，满足好奇",
            "detail": {
                "quota": "每周3条深度对话",
                "reset": "每周一0点重置",
                "overflow": "用完后下周恢复，不强制付费",
                "voice_mode": "支持语气切换"
            },
            "upgrade_trigger": "想要无限深度对话"
        }
    },

    "limitations": {
        "interview": "可选深度访谈（非强制）",
        "identity_prism": "不开放",
        "life_kline": "不开放",
        "relationship_analysis": "不开放",
        "ai_art_poster": "不开放",
        "report_export": "仅在线查看，不提供PDF下载",
        "support": "社区支持"
    },

    "sharing": {
        "enabled": True,
        "incentive": "分享命盘卡片到社交媒体，解锁1次额外对话",
        "tracking": "UTM参数追踪分享来源"
    }
}
```

### 2.2 Pro 版（深度版）

**目标**: 为愿意付费的用户提供完整价值，形成持续订阅

```python
PRO_TIER = {
    "name": "深度版",
    "pricing": {
        "monthly": {
            "cny": 1990,  # ¥19.9/月
            "usd": 299    # $2.99/月
        },
        "yearly": {
            "cny": 15900,  # ¥159/年（省20%）
            "usd": 2399    # $23.99/年
        }
    },
    "positioning": "像大师一样专业，深度了解你自己",

    "features": {
        # 核心付费价值
        "full_report": {
            "name": "完整深度报告",
            "value": "专业命理师级别的完整解读",
            "detail": {
                "length": "3000-5000字",
                "sections": [
                    "命盘结构分析（500字）",
                    "日主深度解读（800字）",
                    "五行能量平衡（600字）",
                    "十神关系分析（500字）",
                    "大运流年运势（800字）",
                    "人生关键节点（500字）",
                    "可执行建议（300字）"
                ],
                "generation": "3-5分钟生成",
                "formats": ["在线查看", "PDF下载", "分享卡片"]
            }
        },

        "unlimited_chat": {
            "name": "无限深度对话",
            "value": "随时随地，想聊就聊",
            "detail": {
                "quota": "无限对话",
                "response_time": "< 5秒",
                "context_memory": "完整对话历史",
                "voice_mode": "3种语气模式（温暖/专业/幽默）"
            }
        },

        "identity_prism": {
            "name": "Identity Prism 三元棱镜",
            "value": "从3个维度深度理解自己",
            "detail": {
                "dimensions": [
                    "Inner Self（内在自我）",
                    "Core Self（核心自我）",
                    "Outer Self（外在呈现）"
                ],
                "interaction": "可切换查看",
                "actionable_insights": "每个维度给出3个行动建议"
            }
        },

        "life_kline": {
            "name": "人生 K 线图",
            "value": "可视化人生运势起伏",
            "detail": {
                "chart_type": "ECharts交互式图表",
                "time_range": "过去10年 + 未来10年",
                "granularity": "年/月/日三级",
                "highlights": "自动标记关键转折点",
                "export": "支持导出高清图片"
            }
        },

        "relationship_analysis": {
            "name": "关系匹配分析",
            "value": "深度了解你与他人的关系",
            "detail": {
                "types": ["爱情", "友情", "事业合作"],
                "analysis_depth": "命盘合婚 + 性格匹配 + 沟通建议",
                "compatibility_score": "0-100分契合度",
                "actionable_advice": "相处之道 + 潜在冲突预警"
            }
        },

        "ai_art_poster": {
            "name": "AI 艺术生图报告",
            "value": "独特的视觉命盘艺术作品",
            "detail": {
                "style": "东方神秘美学",
                "customization": "基于命盘个性化生成",
                "formats": ["16:9海报", "9:16手机壁纸"],
                "sharing": "专为社交媒体优化"
            }
        },

        "priority_features": {
            "name": "优先权益",
            "value": "尊贵的VIP体验",
            "detail": [
                "新功能优先体验",
                "客服优先响应",
                "无广告体验",
                "API访问权限（未来开放）"
            ]
        }
    },

    "billing": {
        "renewal": "自动续费，可随时取消",
        "grace_period": "取消后有效期至订阅结束",
        "refund_policy": "7天内不满意全额退款",
        "payment_methods": ["微信支付", "支付宝", "信用卡", "Apple Pay"]
    }
}
```

### 2.3 增值服务（Add-ons）

**目标**: 为Pro用户提供额外价值，提升ARPU

```python
ADD_ON_SERVICES = {
    "deep_consultation": {
        "name": "深度1对1咨询",
        "price": "¥199/次 (60分钟)",
        "description": "与专业命理师1对1视频咨询",
        "target": "遇到重要决策，需要专业指导"
    },

    "family_package": {
        "name": "家庭套餐",
        "price": "¥49.9/月（最多5人）",
        "description": "全家人的命盘管理",
        "features": [
            "独立命盘",
            "家庭关系分析",
            "合家运势",
            "家庭报告"
        ]
    },

    "extra_report": {
        "name": "额外报告生成",
        "price": "¥9.9/份",
        "description": "为不同出生时间生成新报告",
        "use_case": "想看不同时间点的分析"
    },

    "export_premium": {
        "name": "高级导出",
        "price": "¥4.9/次",
        "description": "导出多种格式的专业报告",
        "formats": ["PDF高清", "Word可编辑", "PPT演示文稿"]
    }
}
```

---

## 3. 功能对比矩阵

### 3.1 可视化对比表

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        VibeLife 功能对比表                                  │
├─────────────────┬───────────────────┬──────────────────┬────────────────────┤
│   功能模块      │    体验版 (Free)   │   深度版 (Pro)    │      说明          │
├─────────────────┼───────────────────┼──────────────────┼────────────────────┤
│                                                                          │
│ 🎯 Onboarding                                                            │
│ ├─ 快速命盘预览   │        ✅         │       ✅        │  免费用户先体验   │
│ ├─ 访谈流程      │        ⚠️         │       ✅        │  Free可选，Pro推荐│
│ └─ Aha Moment    │      <30秒        │      <30秒      │  所有用户同等速度 │
│                                                                          │
│ 🔮 命盘可视化                                                            │
│ ├─ 四柱八字命盘   │   静态预览        │    交互式       │  Pro可点击查看详情│
│ ├─ 五行配色      │        ✅         │       ✅        │  所有用户同等体验 │
│ ├─ 命盘深度解读   │        ❌         │       ✅        │  仅Pro开放        │
│ └─ 命盘导出      │        ❌         │       ✅        │  Pro可导出高清图  │
│                                                                          │
│ 📊 今日运势                                                              │
│ ├─ 每日运势卡片   │        ✅         │       ✅        │  所有用户每日更新 │
│ ├─ 运势指数      │    0-100基础      │  0-100详细      │  Pro有细分维度    │
│ ├─ 幸运指引      │    简单3项        │   详细5项       │  Pro更丰富        │
│ └─ 历史运势查看   │        ❌         │       ✅        │  Pro可查看历史    │
│                                                                          │
│ 📝 报告生成                                                              │
│ ├─ Lite报告      │   500-800字       │       ✅        │  Free永久查看     │
│ ├─ 完整深度报告   │   前500字预览     │  3000-5000字    │  Pro解锁全部内容  │
│ ├─ 报告更新      │      手动         │     自动        │  Pro订阅期内自动  │
│ └─ 报告导出      │        ❌         │    PDF/图片     │  Pro可导出        │
│                                                                          │
│ 💬 AI对话                                                                │
│ ├─ 对话额度      │   3条/周          │      无限       │  Pro畅聊无限制    │
│ ├─ 语气模式      │      1种          │     3种        │  Pro可切换语气    │
│ ├─ 对话历史      │   最近7天         │   永久保存      │  Pro完整历史      │
│ └─ 上下文记忆    │      基础         │     深度       │  Pro更懂你        │
│                                                                          │
│ 🔮 Identity Prism                                                       │
│ ├─ Inner Self     │        ❌         │       ✅        │  仅Pro开放        │
│ ├─ Core Self     │        ❌         │       ✅        │  仅Pro开放        │
│ └─ Outer Self     │        ❌         │       ✅        │  仅Pro开放        │
│                                                                          │
│ 📈 人生K线图                                                             │
│ ├─ 运势可视化    │        ❌         │       ✅        │  仅Pro开放        │
│ ├─ 关键节点标记   │        ❌         │       ✅        │  仅Pro开放        │
│ └─ 导出功能      │        ❌         │       ✅        │  仅Pro开放        │
│                                                                          │
│ ❤️ 关系分析                                                              │
│ ├─ 关系匹配度    │        ❌         │       ✅        │  仅Pro开放        │
│ ├─ 相处建议      │        ❌         │       ✅        │  仅Pro开放        │
│ └─ 多人对比      │        ❌         │       ✅        │  仅Pro开放        │
│                                                                          │
│ 🎨 AI生图海报                                                           │
│ ├─ 命盘艺术海报   │        ❌         │       ✅        │  仅Pro开放        │
│ ├─ 个性化定制    │        ❌         │       ✅        │  仅Pro开放        │
│ └─ 社交分享优化   │        ❌         │       ✅        │  仅Pro开放        │
│                                                                          │
│ 💎 优先权益                                                              │
│ ├─ 新功能体验    │        ❌         │       ✅        │  Pro优先          │
│ ├─ 客服响应      │    社区支持       │   优先客服      │  Pro专属通道      │
│ └─ 广告体验      │      无广告       │     无广告      │  所有用户无广告   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 功能边界代码实现

```python
# apps/api/services/subscription/tier_service.py
from enum import Enum
from typing import Dict, List
from pydantic import BaseModel

class Tier(str, Enum):
    FREE = "free"
    PRO = "pro"
    PREMIUM = "premium"  # 预留

class Feature(str, Enum):
    # 免费功能
    DAILY_FORTUNE = "daily_fortune"
    CHART_PREVIEW = "chart_preview"
    LITE_REPORT = "lite_report"
    CHAT_QUOTA = "chat_quota"

    # 付费功能
    FULL_REPORT = "full_report"
    UNLIMITED_CHAT = "unlimited_chat"
    IDENTITY_PRISM = "identity_prism"
    LIFE_KLINE = "life_kline"
    RELATIONSHIP_ANALYSIS = "relationship_analysis"
    AI_ART_POSTER = "ai_art_poster"
    REPORT_EXPORT = "report_export"

class TierConfig(BaseModel):
    tier: Tier
    features: List[Feature]
    limits: Dict[str, any]
    upgrade_prompts: Dict[str, str]

TIER_CONFIGS = {
    Tier.FREE: TierConfig(
        tier=Tier.FREE,
        features=[
            Feature.DAILY_FORTUNE,
            Feature.CHART_PREVIEW,
            Feature.LITE_REPORT,
            Feature.CHAT_QUOTA
        ],
        limits={
            "daily_fortune_frequency": "1/day",
            "chat_quota": 3,
            "chat_reset": "weekly",
            "lite_report_length": 800,
            "report_access": "online_only"
        },
        upgrade_prompts={
            "daily_fortune": "解锁下周运势预测",
            "chat_quota": "升级Pro，无限畅聊",
            "lite_report": "查看完整3000字深度报告",
            "chart_preview": "解锁命盘深度解读"
        }
    ),

    Tier.PRO: TierConfig(
        tier=Tier.PRO,
        features=[
            # 继承所有免费功能
            Feature.DAILY_FORTUNE,
            Feature.CHART_PREVIEW,
            Feature.LITE_REPORT,
            # 额外付费功能
            Feature.FULL_REPORT,
            Feature.UNLIMITED_CHAT,
            Feature.IDENTITY_PRISM,
            Feature.LIFE_KLINE,
            Feature.RELATIONSHIP_ANALYSIS,
            Feature.AI_ART_POSTER,
            Feature.REPORT_EXPORT
        ],
        limits={
            "daily_fortune_frequency": "unlimited",
            "chat_quota": "unlimited",
            "report_length": "unlimited",
            "report_access": "online_offline",
            "export_formats": ["pdf", "image", "share_card"]
        },
        upgrade_prompts={}
    )
}

def check_feature_access(user_id: str, feature: Feature) -> tuple[bool, TierConfig]:
    """
    检查用户是否有权限访问某功能
    返回: (has_access, tier_config)
    """
    # 获取用户订阅状态
    subscription = get_user_subscription(user_id)
    tier = subscription.tier if subscription else Tier.FREE
    config = TIER_CONFIGS[tier]

    has_access = feature in config.features
    return has_access, config

def get_upgrade_prompt(feature: Feature, tier: Tier) -> str:
    """
    获取功能升级提示文案
    """
    if tier == Tier.FREE:
        return TIER_CONFIGS[Tier.FREE].upgrade_prompts.get(
            feature.value,
            "升级Pro解锁此功能"
        )
    return ""
```

---

## 4. 付费触发点设计

### 4.1 自然付费触发时机

```python
PAYWALL_TRIGGERS = {
    "trigger_1": {
        "name": "第二次深度对话请求",
        "condition": "用户本周已使用3条免费对话，尝试发送第4条",
        "timing": "用户已体验到对话价值，建立信任",
        "message": "本周免费对话已用完。升级Pro，无限畅聊。",
        "conversion_rate_expected": "15-20%"
    },

    "trigger_2": {
        "name": "完整报告查看请求",
        "condition": "用户阅读完Lite报告，点击「查看完整报告」",
        "timing": "用户已了解基础价值，想要更深度分析",
        "message": "解锁3000字完整深度解读，了解真正的自己。",
        "conversion_rate_expected": "10-15%"
    },

    "trigger_3": {
        "name": "关系分析功能点击",
        "condition": "用户尝试使用关系匹配功能",
        "timing": "用户想要扩展使用场景",
        "message": "解锁关系分析，深度了解你与他人的契合度。",
        "conversion_rate_expected": "8-12%"
    },

    "trigger_4": {
        "name": "历史运势查看",
        "condition": "用户想要查看历史运势记录",
        "timing": "用户产生留存需求",
        "message": "升级Pro，查看完整运势历史趋势。",
        "conversion_rate_expected": "5-10%"
    },

    "trigger_5": {
        "name": "报告导出请求",
        "condition": "用户尝试下载/导出报告",
        "timing": "用户想要保存或分享",
        "message": "解锁PDF导出，随时随地查看你的报告。",
        "conversion_rate_expected": "6-10%"
    }
}
```

### 4.2 付费墙 UI/UX 设计

```typescript
// apps/web/src/components/subscription/PaywallCard.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface PaywallCardProps {
  trigger: string;
  feature: string;
  message: string;
  onUpgrade: () => void;
  onDismiss: () => void;
}

export function PaywallCard({ trigger, feature, message, onUpgrade, onDismiss }: PaywallCardProps) {
  const [showPricing, setShowPricing] = useState(false);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full overflow-hidden">
        {/* 头部：功能价值 */}
        <div className="bg-gradient-to-br from-amber-500 to-orange-500 p-6 text-white text-center">
          <div className="text-5xl mb-4">🔓</div>
          <h2 className="text-2xl font-serif mb-2">
            解锁{feature}
          </h2>
          <p className="text-white/90">
            {message}
          </p>
        </div>

        {/* Pro功能清单 */}
        <div className="p-6">
          <h3 className="font-medium text-ink mb-4">
            Pro用户还可以享受：
          </h3>

          <ul className="space-y-3 mb-6">
            {[
              { icon: '📊', text: '完整3000字深度报告' },
              { icon: '💬', text: '无限AI对话，随时随地' },
              { icon: '🔮', text: 'Identity Prism 三元棱镜' },
              { icon: '📈', text: '人生K线图，运势可视化' },
              { icon: '❤️', text: '关系匹配分析' },
              { icon: '🎨', text: 'AI艺术生图海报' }
            ].map((item, idx) => (
              <li key={idx} className="flex items-center gap-3">
                <span className="text-2xl">{item.icon}</span>
                <span className="text-ink">{item.text}</span>
              </li>
            ))}
          </ul>

          {/* 定价卡片 */}
          {!showPricing ? (
            <button
              onClick={() => setShowPricing(true)}
              className="w-full bg-gradient-to-r from-amber-500 to-orange-500 text-white py-4 rounded-xl font-medium hover:shadow-lg transition-all"
            >
              查看Pro定价 →
            </button>
          ) : (
            <PricingOptions onSelect={onUpgrade} />
          )}

          {/* 跳过按钮 */}
          <button
            onClick={onDismiss}
            className="w-full mt-3 text-ink/60 hover:text-ink transition-colors"
          >
            暂时不需要
          </button>
        </div>

        {/* 信任标识 */}
        <div className="px-6 pb-6 text-center text-sm text-ink/50">
          7天内不满意全额退款 · 随时取消
        </div>
      </div>
    </div>
  );
}

// 定价选项组件
function PricingOptions({ onSelect }: { onSelect: () => void }) {
  return (
    <div className="space-y-3">
      {/* 年付推荐 */}
      <button
        onClick={onSelect}
        className="w-full p-4 border-2 border-amber-500 rounded-xl relative"
      >
        <div className="absolute top-2 right-2 bg-amber-500 text-white text-xs px-2 py-1 rounded-full">
          省20%
        </div>
        <div className="flex justify-between items-center">
          <div className="text-left">
            <div className="font-medium text-ink">年付 Pro</div>
            <div className="text-sm text-ink/60">平均 ¥13.25/月</div>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-ink">¥159</div>
            <div className="text-sm text-ink/60">/年</div>
          </div>
        </div>
      </button>

      {/* 月付 */}
      <button
        onClick={onSelect}
        className="w-full p-4 border border-vellum-300 rounded-xl hover:border-amber-300 transition-colors"
      >
        <div className="flex justify-between items-center">
          <div className="text-left">
            <div className="font-medium text-ink">月付 Pro</div>
            <div className="text-sm text-ink/60">灵活订阅</div>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-ink">¥19.9</div>
            <div className="text-sm text-ink/60">/月</div>
          </div>
        </div>
      </button>
    </div>
  );
}
```

---

## 5. 转化优化策略

### 5.1 定价心理学

```python
PRICING_PSYCHOLOGY = {
    "anchoring_effect": {
        "strategy": "锚定效应",
        "implementation": "同时展示月付和年付，年付看起来更划算",
        "example": "月付¥19.9 vs 年付¥159（平均¥13.25/月）"
    },

    "decoy_effect": {
        "strategy": "诱饵效应",
        "implementation": "三个选项：Free / Pro / Premium",
        "example": "Free ¥0, Pro ¥19.9, Premium ¥29.9 (让Pro看起来最优)"
    },

    "loss_aversion": {
        "strategy": "损失厌恶",
        "implementation": "限时优惠，倒计时",
        "example": "首月半价，仅限24小时"
    },

    "social_proof": {
        "strategy": "社会证明",
        "implementation": "用户数量、评分、评价",
        "example": "已有10,000+用户升级，4.9星好评"
    },

    "reciprocity": {
        "strategy": "互惠原理",
        "implementation": "先给价值，再要求付费",
        "example": "先免费今日运势，再引导解锁完整报告"
    }
}
```

### 5.2 转化率优化实验

```python
CONVERSION_OPTIMIZATION_EXPERIMENTS = {
    "experiment_1": {
        "name": "定价展示顺序",
        "variants": [
            "年付优先（推荐）",
            "月付优先",
            "仅月付"
        ],
        "metric": "conversion_rate",
        "hypothesis": "年付优先会提升ARPU"
    },

    "experiment_2": {
        "name": "付费墙文案",
        "variants": [
            "功能导向（解锁XX功能）",
            "价值导向（深度了解自己）",
            "稀缺导向（限时优惠）"
        ],
        "metric": "click_to_upgrade",
        "hypothesis": "价值导向转化率最高"
    },

    "experiment_3": {
        "name": "免费额度",
        "variants": [
            "3条对话/周",
            "5条对话/周",
            "7条对话/周"
        ],
        "metric": "free_user_satisfaction & conversion_rate",
        "hypothesis": "5条是最佳平衡点"
    },

    "experiment_4": {
        "name": "试用期",
        "variants": [
            "无试用期（直接付费墙）",
            "7天免费试用Pro",
            "3天免费试用Pro"
        ],
        "metric": "trial_to_paid_rate & churn",
        "hypothesis": "7天试用期提升转化但可能降低即时付费"
    }
}
```

---

## 6. 留存与召回

### 6.1 免费用户留存策略

```python
FREE_USER_RETENTION = {
    "notification_triggers": {
        "daily_fortune_ready": {
            "channel": "push + email",
            "message": "你的今日运势已更新，点击查看",
            "timing": "每天早上8点",
            "goal": "维持日活"
        },
        "weekly_quota_reset": {
            "channel": "push",
            "message": "本周对话额度已刷新，快来聊聊吧",
            "timing": "每周一早上9点",
            "goal": "维持周活"
        },
        "weekly_insight": {
            "channel": "email",
            "message": "本周运势摘要 + 1条个性化洞察",
            "timing": "每周日晚上8点",
            "goal": "内容留存"
        }
    },

    "engagement_loops": {
        "daily_check_in": {
            "action": "每日签到查看运势",
            "reward": "累计签到7天解锁1次额外对话",
            "frequency": "每日",
            "target": "建立习惯"
        },
        "share_to_unlock": {
            "action": "分享命盘到社交媒体",
            "reward": "解锁1次Pro功能体验",
            "frequency": "每周",
            "target": "病毒传播"
        }
    }
}
```

### 6.2 付费用户留存策略

```python
PAID_USER_RETENTION = {
    "value_deliverables": {
        "monthly_report": {
            "content": "每月深度运势报告",
            "timing": "每月1号",
            "perceived_value": "¥19.9"
        },
        "exclusive_content": {
            "content": "Pro专属深度文章",
            "frequency": "每周1篇",
            "perceived_value": "持续学习"
        },
        "early_access": {
            "content": "新功能优先体验",
            "timing": "新功能发布时",
            "perceived_value": "尊贵感"
        }
    },

    "churn_prevention": {
        "cancel_intent_survey": {
            "timing": "用户点击取消时",
            "questions": [
                "为什么决定取消？",
                "我们如何改进？"
            ],
            "retention_offer": {
                "offer": "暂停订阅而非取消（保留数据，暂停付费）",
                "success_rate_target": ">20%"
            }
        },
        "expiring_soon_reminder": {
            "timing": "订阅到期前7天",
            "message": "你的Pro订阅即将到期，续费可享受...",
            "offer": "续费享8折优惠",
            "success_rate_target": ">30%"
        }
    }
}
```

---

## 7. 实施路线图

### Week 1-2: 边界定义

```
后端
├── [ ] TierConfig 数据模型
├── [ ] 功能权限检查中间件
├── [ ] Lite vs Full 报告生成逻辑
└── [ ] 对话额度管理系统

前端
├── [ ] Free vs Pro 功能门控
├── [ ] PaywallCard 组件
├── [ ] 功能对比展示页面
└── [ ] 定价选项组件

数据
├── [ ] 免费用户行为追踪
├── [ ] 付费触发点埋点
└── [ ] 转化漏斗分析
```

### Week 3-4: 转化优化

```
实验
├── [ ] A/B测试框架搭建
├── [ ] 定价展示实验
├── [ ] 付费墙文案实验
└── [ ] 免费额度实验

留存
├── [ ] Push通知系统
├── [ ] 邮件自动化
├── [ ] 签到奖励系统
└── [ ] 分享解锁机制
```

### Week 5-6: 数据驱动迭代

```
分析
├── [ ] Week 1-4 数据回顾
├── [ ] 转化漏斗分析
├── [ ] 用户反馈收集
└── [ ] 留存率分析

优化
├── [ ] 基于数据调整边界
├── [ ] 优化付费触发时机
├── [ ] 调整定价策略
└── [ ] 改进留存策略
```

---

## 8. 成功指标

### 8.1 核心KPI

```python
FREEMIUM_KPIS = {
    "acquisition": {
        "free_signups": "周免费注册用户数",
        "acquisition_channels": "渠道分布"
    },

    "activation": {
        "time_to_aha": "< 30秒",
        "aha_rate": "> 70%"
    },

    "retention": {
        "d1_retention": "> 40%",
        "w1_retention": "> 20%",
        "w4_retention": "> 10%"
    },

    "revenue": {
        "free_to_paid_rate": "5% (目标范围: 3-8%)",
        "arpu": "每用户平均收入",
        "ltv": "用户生命周期价值",
        "ltv_cac_ratio": "> 3"
    },

    "referral": {
        "k_factor": "> 1.2",
        "share_rate": "> 15%"
    }
}
```

### 8.2 健康度检查

```python
FREEMIUM_HEALTH_CHECK = {
    "healthy_signs": [
        "免费用户满意度 > 60%",
        "付费转化率稳定在 3-8%",
        "付费用户留存率 > 免费用户",
        "LTV/CAC > 3",
        "推荐系数 K-factor > 1"
    ],

    "warning_signs": [
        "免费用户满意度 < 40%",
        "付费转化率 < 2%",
        "付费用户流失率 > 15%/月",
        "LTV/CAC < 2",
        "口碑变差"
    ],

    "actions": {
        "free_satisfaction_low": "增加免费价值，减少限制感",
        "conversion_low": "优化付费触发时机和文案",
        "churn_high": "改进产品价值，增加留存功能",
        "ltv_cac_low": "优化获客渠道或提升定价"
    }
}
```

---

## 9. 常见问题解答

### Q1: 为什么免费用户只能每周3条对话？

**A**: 基于3个考量：
1. **成本控制**: 每条对话消耗API成本
2. **价值感知**: 有限额度让用户意识到对话的价值
3. **转化触发**: 第4条对话是自然的付费触发点

### Q2: 为什么不采用7天免费试用模式？

**A**: 对我们的产品不适合：
1. **低频产品**: 用户可能7天都不回来
2. **价值感知**: 先给永久免费价值，再付费转化更符合用户心理
3. **数据验证**: 我们的A/B测试显示直接Freemium转化率更高

### Q3: 如何防止免费用户滥用分享解锁？

**A**: 技术限制：
1. **设备限制**: 每设备每周最多1次分享奖励
2. **好友验证**: 好友必须完成注册才能算分享成功
3. **反作弊**: 监控异常分享行为，自动封禁

### Q4: 定价是否会调整？

**A**: 会，基于数据：
1. **Phase 1**: 测试¥19.9定价
2. **数据验证**: 观察转化率和ARPU
3. **迭代优化**: 可能测试¥9.9/¥29.9等不同价位
4. **动态定价**: 未来可能根据用户地区/行为差异化定价

---

## 10. 附录

### 10.1 数据库Schema扩展

```sql
-- 订阅表
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill TEXT NOT NULL,  -- 'bazi', 'zodiac'
    tier TEXT NOT NULL DEFAULT 'free',  -- 'free', 'pro', 'premium'
    billing_cycle TEXT,  -- 'monthly', 'yearly'
    currency TEXT NOT NULL,
    price_cents INT,
    status TEXT NOT NULL DEFAULT 'active',
    payment_provider TEXT,
    provider_subscription_id TEXT,
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, skill)
);

-- 用户配额表
CREATE TABLE user_quotas (
    user_id UUID REFERENCES users(id) PRIMARY KEY,
    weekly_chat_quota INT DEFAULT 3,
    weekly_chat_used INT DEFAULT 0,
    weekly_reset_at TIMESTAMPTZ,
    share_unlocks INT DEFAULT 0,
    last_share_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 功能访问日志
CREATE TABLE feature_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    feature TEXT NOT NULL,
    access_granted BOOLEAN,
    tier_at_access TEXT,
    triggered_paywall BOOLEAN,
    converted_to_paid BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_feature_access_user ON feature_access_logs(user_id);
CREATE INDEX idx_feature_access_feature ON feature_access_logs(feature, created_at);
```

### 10.2 API端点设计

```python
# apps/api/routes/subscription.py

@router.get("/me")
async def get_my_subscription(request: Request):
    """获取当前用户订阅状态"""
    user_id = request.state.user_id
    subscription = await get_user_subscription(user_id)
    return subscription

@router.post("/checkout")
async def create_checkout_session(request: Request, checkout_data: CheckoutRequest):
    """创建支付会话"""
    user_id = request.state.user_id
    session = await create_payment_session(user_id, checkout_data)
    return {"checkout_url": session.url}

@router.post("/cancel")
async def cancel_subscription(request: Request):
    """取消订阅"""
    user_id = request.state.user_id
    await cancel_user_subscription(user_id)
    return {"status": "canceled"}

@router.get("/features")
async def get_available_features(request: Request):
    """获取用户可访问的功能列表"""
    user_id = request.state.user_id
    features = await get_user_features(user_id)
    return {"features": features}

@router.post("/quota/check")
async def check_quota(request: Request, feature: str):
    """检查用户配额"""
    user_id = request.state.user_id
    has_quota, remaining = await check_user_quota(user_id, feature)
    return {"has_quota": has_quota, "remaining": remaining}
```

---

## 参考资源

- **Freemium Economics**: 《Freemium:离线产品如何通过免费增值盈利》
- **Conversion Optimization**: 《转化率优化实战指南》
- **Pricing Psychology**: 《定价心理学》
- **Case Studies**:
  - Spotify Freemium Model
  - Duolingo Free vs Super
  - Notion Personal vs Pro
