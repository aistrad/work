# SkillIntroCard 数据结构

> Version: 1.0.0 | 2026-01-20

---

## 1. 数据来源

```
┌─────────────────────────────────────────────────────────────────┐
│                        数据流                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SKILL.md frontmatter                                           │
│         ↓                                                        │
│  skill_loader.py (SkillMetadata)                                │
│         ↓                                                        │
│  API: GET /api/v1/skills/{skill_id}/intro                       │
│         ↓                                                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ SkillIntroData                                              ││
│  │ ├─ skill: SkillMetadata (静态配置)                          ││
│  │ ├─ subscription: UserSubscription (用户状态)                ││
│  │ └─ settings: UserSkillSettings (用户配置)                   ││
│  └─────────────────────────────────────────────────────────────┘│
│         ↓                                                        │
│  SkillIntroCard 组件                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. SKILL.md Frontmatter 扩展

### 2.1 当前结构 (已有)

```yaml
---
name: lifecoach
description: |
  人生教练。支持多种教练方法论...
  触发词：迷茫、卡住、拖延...
category: professional
icon: "🧭"
color: "#10B981"
version: "3.0.0"

pricing:
  type: premium
  trial_messages: 5

features:
  - name: 多方法论支持
    description: Dan Koe、Covey、王阳明、了凡四训
    icon: "📚"
    tier: free
  - name: 完整教练流程
    description: 诊断→设计→执行→复盘
    icon: "🎯"
    tier: free
  - name: 持续陪伴
    description: 每日签到、周复盘、进度追踪
    icon: "🤝"
    tier: premium

showcase:
  tagline: 你的 AI 人生教练，多元智慧助你成长
  highlights:
    - 四大教练方法论任选
    - 完整的教练流程
    - 持续陪伴，长期成长
  demo_prompts:
    - "我感觉很迷茫，不知道该做什么"
    - "帮我用 Dan Koe 方法做一次人生重置"
    - "我想用了凡四训的方法改变命运"
---
```

### 2.2 扩展字段 (新增)

```yaml
# 在 features 中添加 action 字段
features:
  - name: 多方法论支持
    description: Dan Koe、Covey、王阳明、了凡四训
    icon: "📚"
    tier: free
    # 新增: 点击行为
    action:
      type: navigate          # send_prompt | navigate | expand
      target: rule            # rule | scenario | url
      id: dankoe              # 目标 ID
    # 新增: 功能专属示例
    demo_prompt: "帮我用 Dan Koe 方法分析一下"

# 新增: 可配置的设置项
settings:
  - key: push_enabled
    name: 每日提醒
    type: toggle
    default: true
    description: 接收每日签到和复盘提醒
  - key: voice_mode
    name: 语音模式
    type: select
    default: warm
    options:
      - value: warm
        label: 温暖支持
      - value: direct
        label: 直接挑战
      - value: playful
        label: 轻松幽默
  - key: reminder_hour
    name: 提醒时间
    type: time
    default: "08:00"
    description: 每日提醒的发送时间

# 新增: 介绍卡片配置
intro_card:
  # 默认显示的 sections
  default_sections: [header, features, quickstart, pricing]
  # 是否在首次使用时自动展示
  show_on_first_use: true
  # 自定义 CTA 文案
  cta_text: "开始你的成长之旅"
```

---

## 3. TypeScript 类型定义

### 3.1 核心类型

```typescript
// types.ts

/**
 * Feature 点击行为
 */
interface FeatureAction {
  type: 'send_prompt' | 'navigate' | 'expand';
  target?: 'rule' | 'scenario' | 'url';
  id?: string;
  url?: string;
}

/**
 * Skill 功能特性
 */
interface SkillFeature {
  name: string;
  description: string;
  icon: string;
  tier: 'free' | 'basic' | 'premium';
  action?: FeatureAction;
  demo_prompt?: string;
}

/**
 * 设置项定义
 */
interface SkillSetting {
  key: string;
  name: string;
  type: 'toggle' | 'select' | 'time' | 'number';
  default: any;
  description?: string;
  options?: Array<{ value: string; label: string }>;
  min?: number;
  max?: number;
}

/**
 * 定价信息
 */
interface SkillPricing {
  type: 'free' | 'premium' | 'credits';
  trial_messages: number;
  credits_per_use?: number;
}

/**
 * 展示配置
 */
interface SkillShowcase {
  tagline: string;
  highlights: string[];
  preview_image?: string;
  demo_prompts: string[];
}

/**
 * 介绍卡片配置
 */
interface IntroCardConfig {
  default_sections: SectionType[];
  show_on_first_use: boolean;
  cta_text?: string;
}

/**
 * Skill 元数据 (完整)
 */
interface SkillMetadata {
  id: string;
  name: string;
  description: string;
  version: string;
  category: 'core' | 'default' | 'professional';
  icon: string;
  color: string;
  triggers: string[];
  pricing: SkillPricing;
  features: SkillFeature[];
  showcase: SkillShowcase;
  settings?: SkillSetting[];
  intro_card?: IntroCardConfig;
}
```

### 3.2 用户状态类型

```typescript
/**
 * 用户订阅状态
 */
interface UserSubscription {
  skill_id: string;
  status: 'subscribed' | 'trial' | 'unsubscribed';
  push_enabled: boolean;
  subscribed_at?: string;
  trial_messages_used: number;
  trial_messages_remaining: number;
}

/**
 * 用户 Skill 设置
 */
interface UserSkillSettings {
  skill_id: string;
  voice_mode?: 'warm' | 'direct' | 'playful';
  reminder_hour?: number;
  custom_settings?: Record<string, any>;
}
```

### 3.3 组件 Props 类型

```typescript
/**
 * Section 类型
 */
type SectionType = 'header' | 'features' | 'quickstart' | 'pricing' | 'settings';

/**
 * 变体类型
 */
type IntroCardVariant = 'full' | 'compact' | 'mini';

/**
 * Action 回调类型
 */
type IntroCardAction =
  | { type: 'send_prompt'; prompt: string }
  | { type: 'navigate'; target: 'rule' | 'scenario'; id: string }
  | { type: 'subscribe'; skillId: string }
  | { type: 'unsubscribe'; skillId: string }
  | { type: 'toggle_setting'; key: string; value: any }
  | { type: 'expand_feature'; featureId: string }
  | { type: 'dismiss' };

/**
 * SkillIntroCard Props
 */
interface SkillIntroCardProps {
  /** Skill ID */
  skillId: string;

  /** 变体: full | compact | mini */
  variant?: IntroCardVariant;

  /** 要显示的 sections (覆盖默认配置) */
  sections?: SectionType[];

  /** 是否可关闭 */
  dismissible?: boolean;

  /** Action 回调 */
  onAction?: (action: IntroCardAction) => void;

  /** 自定义样式 */
  className?: string;

  /** 预加载的数据 (避免重复请求) */
  initialData?: SkillIntroData;
}

/**
 * 完整的介绍卡片数据
 */
interface SkillIntroData {
  skill: SkillMetadata;
  subscription: UserSubscription | null;
  settings: UserSkillSettings | null;
}
```

---

## 4. API 响应结构

### 4.1 GET /api/v1/skills/{skill_id}/intro

```json
{
  "skill": {
    "id": "lifecoach",
    "name": "Lifecoach",
    "description": "人生教练。支持多种教练方法论...",
    "version": "3.0.0",
    "category": "professional",
    "icon": "🧭",
    "color": "#10B981",
    "triggers": ["迷茫", "卡住", "拖延", "想改变"],
    "pricing": {
      "type": "premium",
      "trial_messages": 5,
      "credits_per_use": null
    },
    "features": [
      {
        "name": "多方法论支持",
        "description": "Dan Koe、Covey、王阳明、了凡四训",
        "icon": "📚",
        "tier": "free",
        "action": {
          "type": "navigate",
          "target": "rule",
          "id": "dankoe"
        },
        "demo_prompt": "帮我用 Dan Koe 方法分析一下"
      }
    ],
    "showcase": {
      "tagline": "你的 AI 人生教练，多元智慧助你成长",
      "highlights": [
        "四大教练方法论任选",
        "完整的教练流程",
        "持续陪伴，长期成长"
      ],
      "demo_prompts": [
        "我感觉很迷茫，不知道该做什么",
        "帮我用 Dan Koe 方法做一次人生重置"
      ]
    },
    "settings": [
      {
        "key": "push_enabled",
        "name": "每日提醒",
        "type": "toggle",
        "default": true
      },
      {
        "key": "voice_mode",
        "name": "语音模式",
        "type": "select",
        "default": "warm",
        "options": [
          { "value": "warm", "label": "温暖支持" },
          { "value": "direct", "label": "直接挑战" }
        ]
      }
    ],
    "intro_card": {
      "default_sections": ["header", "features", "quickstart", "pricing"],
      "show_on_first_use": true,
      "cta_text": "开始你的成长之旅"
    }
  },
  "subscription": {
    "skill_id": "lifecoach",
    "status": "trial",
    "push_enabled": true,
    "subscribed_at": null,
    "trial_messages_used": 2,
    "trial_messages_remaining": 3
  },
  "settings": {
    "skill_id": "lifecoach",
    "voice_mode": "warm",
    "reminder_hour": 8,
    "custom_settings": {}
  }
}
```

---

## 5. 工具调用数据

### 5.1 show_skill_intro 工具参数

```yaml
# tools.yaml
- name: show_skill_intro
  description: 展示 Skill 介绍导航卡片
  tool_type: display
  card_type: skill_intro
  parameters:
    - name: skill_id
      type: string
      required: true
      description: Skill ID
    - name: variant
      type: string
      enum: [full, compact, mini]
      default: compact
      description: 卡片变体
    - name: sections
      type: array
      items: string
      description: 要显示的 sections，不传则使用默认配置
    - name: reason
      type: string
      description: 展示原因（用于首次使用场景）
```

### 5.2 工具返回数据

```json
{
  "cardType": "skill_intro",
  "data": {
    "skill_id": "lifecoach",
    "variant": "compact",
    "sections": ["header", "features", "quickstart"],
    "reason": "这是你第一次使用人生教练，让我介绍一下它能帮你做什么"
  }
}
```

---

## 6. 数据缓存策略

| 数据类型 | 缓存位置 | TTL | 失效条件 |
|---------|---------|-----|---------|
| SkillMetadata | 内存 + localStorage | 1 小时 | 版本变更 |
| UserSubscription | React Query | 5 分钟 | 订阅操作 |
| UserSkillSettings | React Query | 5 分钟 | 设置变更 |

```typescript
// useSkillIntro.ts
const useSkillIntro = (skillId: string) => {
  return useQuery({
    queryKey: ['skill-intro', skillId],
    queryFn: () => fetchSkillIntro(skillId),
    staleTime: 5 * 60 * 1000, // 5 分钟
    cacheTime: 30 * 60 * 1000, // 30 分钟
  });
};
```
