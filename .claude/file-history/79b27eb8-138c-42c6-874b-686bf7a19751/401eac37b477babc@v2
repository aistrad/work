# Me 页重构设计文档 v1.0

> 设计师：Claude Ultra Mode
> 日期：2026-01-21
> 基于：v9 架构 + VibeID 设计哲学 + Chat-First 理念

---

## 一、设计理念

### 核心定位

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   Me 页 = 一面「数字镜子」                                          │
│                                                                     │
│   你打开它，看到的不是数据，而是一个关于"你是谁"的艺术品。          │
│                                                                     │
│   一句话 → 告诉你本质                                                │
│   展开层 → 揭示维度                                                  │
│   跳转Chat → 深度对话                                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **聚合融合** | VibeID 是融合层，展示八字+星座的综合洞察 | 一个融合身份卡片，而非三个并列卡片 |
| **简化呈现** | 默认一句话 + 主原型，复杂度隐藏在展开层 | Layer 1简洁，Layer 2详细 |
| **轻交互** | 页面内可展开查看详情，深度分析跳 Chat | 展开动画 + CTA 跳转 |
| **艺术品感** | 借鉴 VibeID 的精美视觉（渐变、阴影、书卷感）| 羊皮纸质感 + 渐变文字 + 柔和阴影 |
| **部分成长** | 融入成长轨迹，但不是核心（80%静态 + 20%动态）| 成长时间线可展开，展示最近3个节点 |

---

## 二、信息架构

### 层级结构

```
Me 页
│
├─ Layer 0: 用户信息（顶部，简洁）
│   ├─ 头像 + 昵称
│   └─ Pro 标识（如果有）
│
├─ Layer 1: 融合身份卡片（默认展示，占据视觉焦点）★核心★
│   ├─ 主原型徽章：创造者 · 探索者
│   ├─ 一句话本质："创造者的灵魂，探索者的心"
│   ├─ 融合来源：融合自八字（甲木·食神格）× 星座（水瓶·天秤）
│   ├─ 今日状态：能量 85% 🔥 | 运势 ⭐⭐⭐⭐
│   └─ CTA: [探索更多维度 ↓]
│
├─ Layer 2: 维度详情（点击展开，平滑动画）
│   │
│   ├─ 🌙 八字维度
│   │   ├─ 标签：我的底层密码
│   │   ├─ 数据行：
│   │   │   ├─ 日主：甲木 - 生命能量的根基
│   │   │   ├─ 格局：食神格 - 创造与表达的天赋
│   │   │   └─ 当前大运：丙火 - 创造力爆发期（至2030）
│   │   ├─ 今日运势：⭐⭐⭐⭐ "甲子日，水气旺盛..."
│   │   └─ CTA: [深度分析 → Chat]
│   │
│   ├─ ⭐ 星座维度
│   │   ├─ 标签：我的宇宙坐标
│   │   ├─ 数据行：
│   │   │   ├─ 太阳：水瓶座 - 创新思维的源泉
│   │   │   ├─ 上升：天秤座 - 和谐表达的方式
│   │   │   └─ 月亮：巨蟹座 - 情感需求的核心
│   │   ├─ 今日能量：🌟 灵感爆发 "水星顺行，沟通顺畅"
│   │   └─ CTA: [深度分析 → Chat]
│   │
│   └─ 🌱 成长轨迹
│       ├─ 时间线节点（最近3个）：
│       │   ├─ 🌟 突破时刻（3天前）- "完成人生重置协议"
│       │   ├─ 💡 原型演化（1周前）- "创造者能量 +5"
│       │   └─ 🎯 目标达成（2周前）- "连续7天完成目标"
│       └─ CTA: [查看完整旅程 → Chat]
│
└─ Layer 3: 设置（折叠，降低视觉权重）
    ├─ 语气模式：🌞 温暖 | 😈 吐槽 | 🧙 睿智
    ├─ 通知设置
    └─ 账户管理
```

### 与当前架构对比

| 维度 | 当前 MePanel.tsx | 重构后 |
|------|-----------------|--------|
| **顶部** | 用户卡片（较大）| 用户卡片（简化）|
| **核心** | VibeID + 八字 + 星座 **并列3个卡片** | **融合身份卡片**（聚合三者）|
| **详情** | 每个 skill 独立卡片，始终可见 | 可展开的维度详情（默认折叠）|
| **成长** | 无 | 成长轨迹（可展开）|
| **设置** | 可折叠但默认展开 | 更低调（默认折叠）|
| **视觉** | 标准卡片 | 羊皮纸质感 + 艺术品风格 |

**关键差异**：
- 从 **"3个并列卡片"** → **"1个融合卡片 + 可展开详情"**
- 从 **"数据展示"** → **"艺术品呈现"**
- 从 **"全部可见"** → **"简洁默认 + 层次探索"**

---

## 三、视觉设计

### 3.1 融合身份卡片（核心）

借鉴 VibeID 的设计语言，创造"艺术品"质感。

#### 完整代码示例

```tsx
// components/me/FusedIdentityCard.tsx

import { useState } from 'react';
import { ArrowDown, ArrowUp } from 'lucide-react';
import { cn } from '@/lib/utils';
import { ArchetypeBadge } from './shared/ArchetypeBadge';

export interface FusedIdentityData {
  essence: string; // 一句话本质
  primaryArchetype: string; // 主原型
  secondaryArchetype?: string; // 次原型
  sources: {
    bazi: { dayMaster: string; pattern: string };
    zodiac: { sun: string; ascendant: string };
  };
  today: {
    energy: number; // 0-100
    fortuneLevel: 1 | 2 | 3 | 4 | 5;
    insight: string;
  };
}

export function FusedIdentityCard({
  data,
  expanded,
  onToggle
}: {
  data: FusedIdentityData;
  expanded: boolean;
  onToggle: () => void;
}) {
  const fortuneStars = '⭐'.repeat(data.today.fortuneLevel);
  const energyEmoji = data.today.energy >= 80 ? '🔥' :
                       data.today.energy >= 60 ? '✨' :
                       data.today.energy >= 40 ? '💫' : '💤';

  return (
    <div className={cn(
      // 羊皮纸背景
      "relative overflow-hidden",
      "bg-gradient-to-br from-vellum-50/80 via-white to-vellum-100/60",
      "border border-vellum-200/40",
      "shadow-[0_8px_30px_rgb(139,92,46,0.08)]",
      "rounded-2xl p-6",
      // 交互
      "transition-all duration-300",
      expanded && "shadow-[0_12px_40px_rgb(139,92,46,0.12)]"
    )}>

      {/* 装饰性边框 */}
      <div className="absolute inset-0 rounded-2xl border-2 border-vellum-200/20 pointer-events-none" />

      {/* 核心内容 */}
      <div className="relative z-10">

        {/* 主原型徽章 */}
        <div className="flex items-center gap-2 mb-4">
          <ArchetypeBadge archetype={data.primaryArchetype} />
          {data.secondaryArchetype && (
            <>
              <span className="text-vellum-400">·</span>
              <ArchetypeBadge
                archetype={data.secondaryArchetype}
                variant="secondary"
              />
            </>
          )}
        </div>

        {/* 一句话本质 */}
        <h2 className={cn(
          "font-serif text-2xl font-semibold",
          "text-transparent bg-clip-text",
          "bg-gradient-to-br from-ink-800 via-ink-600 to-ink-500",
          "leading-relaxed mb-3"
        )}>
          "{data.essence}"
        </h2>

        {/* 副标题：融合来源 */}
        <p className="text-sm text-ink-500/70 mb-4">
          融合自八字（{data.sources.bazi.dayMaster}·{data.sources.bazi.pattern}）
          × 星座（{data.sources.zodiac.sun}·{data.sources.zodiac.ascendant}）
        </p>

        {/* 今日能量状态 */}
        <div className="flex items-center gap-3 mb-5">
          {/* 能量 */}
          <div className="flex items-center gap-1.5">
            <span className="text-sm text-ink-600">今日能量</span>
            <div className="flex items-center gap-0.5">
              <span className="text-lg">{energyEmoji}</span>
              <span className="font-medium text-amber-600">
                {data.today.energy}%
              </span>
            </div>
          </div>

          {/* 分隔线 */}
          <div className="h-4 w-px bg-vellum-200" />

          {/* 运势 */}
          <div className="flex items-center gap-1.5">
            <span className="text-sm text-ink-600">运势</span>
            <span className="text-base">{fortuneStars}</span>
          </div>
        </div>

        {/* CTA：探索更多 */}
        <button
          onClick={onToggle}
          className={cn(
            "group w-full flex items-center justify-center gap-2",
            "px-4 py-3 rounded-xl",
            "bg-gradient-to-r from-vellum-100/50 to-amber-100/30",
            "hover:from-vellum-100 hover:to-amber-100/50",
            "border border-vellum-200/50",
            "transition-all duration-300"
          )}
        >
          <span className="text-sm font-medium text-ink-700">
            {expanded ? '收起' : '探索更多维度'}
          </span>
          {expanded ? (
            <ArrowUp className="w-4 h-4 text-ink-500 transition-transform group-hover:-translate-y-0.5" />
          ) : (
            <ArrowDown className="w-4 h-4 text-ink-500 transition-transform group-hover:translate-y-0.5" />
          )}
        </button>

      </div>
    </div>
  );
}
```

#### 配色方案

```typescript
// styles/colors/me-page.ts

export const MePageColors = {
  // 羊皮纸背景（延续 VibeID）
  vellum: {
    50: '#FDFBF7',   // 最浅的米白色
    100: '#F9F5ED',  // 浅米色
    200: '#F0E9D9',  // 羊皮纸边缘
    300: '#E4D9C1',  // 较深的纸质感
    400: '#D4C5A6',  // 阴影色
  },

  // 墨水文字（温暖的黑色系）
  ink: {
    500: '#5C4A3A',  // 中等深度
    600: '#4A3A2A',  // 标题深度
    700: '#3A2A1A',  // 深度文字
    800: '#2A1A0A',  // 最深文字（渐变起点）
  },

  // 强调色（琥珀金）
  accent: {
    100: '#FFF4E6',  // 浅琥珀背景
    500: '#FFB84D',  // 中等琥珀
    600: '#FF9500',  // 深琥珀（CTA hover）
  },
}
```

### 3.2 原型徽章组件

```tsx
// components/me/shared/ArchetypeBadge.tsx

export function ArchetypeBadge({
  archetype,
  variant = 'primary'
}: {
  archetype: string;
  variant?: 'primary' | 'secondary';
}) {
  const isPrimary = variant === 'primary';

  return (
    <div className={cn(
      "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full",
      "text-sm font-medium",
      isPrimary ? [
        "bg-gradient-to-r from-amber-100/80 to-orange-100/60",
        "text-amber-800",
        "border border-amber-200/50"
      ] : [
        "bg-gradient-to-r from-blue-50/80 to-purple-50/60",
        "text-blue-700",
        "border border-blue-200/40"
      ]
    )}>
      <span className={isPrimary ? "text-amber-600" : "text-blue-500"}>
        {getArchetypeEmoji(archetype)}
      </span>
      <span>{archetype}</span>
    </div>
  );
}

function getArchetypeEmoji(archetype: string): string {
  const emojiMap: Record<string, string> = {
    '创造者': '🎨',
    '探索者': '🧭',
    '智者': '📚',
    '英雄': '⚔️',
    '统治者': '👑',
    // ... 更多映射
  };
  return emojiMap[archetype] || '✨';
}
```

### 3.3 维度详情卡片

```tsx
// components/me/DimensionCard.tsx

export function DimensionCard({
  icon,
  title,
  subtitle,
  dataRows,
  todayCard,
  onAnalyze,
  theme = 'amber' // 'amber' for bazi, 'purple' for zodiac, 'blue' for growth
}: DimensionCardProps) {
  const themeColors = {
    amber: {
      gradient: 'from-amber-50/50 to-orange-50/50',
      border: 'border-amber-200/30',
      accent: 'text-amber-700',
      bg: 'bg-amber-50/50',
    },
    purple: {
      gradient: 'from-purple-50/50 to-blue-50/50',
      border: 'border-purple-200/30',
      accent: 'text-purple-700',
      bg: 'bg-purple-50/50',
    },
    blue: {
      gradient: 'from-blue-50/50 to-cyan-50/50',
      border: 'border-blue-200/30',
      accent: 'text-blue-700',
      bg: 'bg-blue-50/50',
    },
  }[theme];

  return (
    <div className={cn(
      "p-5 rounded-xl",
      `bg-gradient-to-br ${themeColors.gradient}`,
      `border ${themeColors.border}`,
      "shadow-card"
    )}>

      {/* 标题 */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <span className="text-2xl">{icon}</span>
          <h3 className="font-serif text-lg font-semibold text-foreground">
            {title}
          </h3>
        </div>
        <span className="text-xs text-muted-foreground px-2 py-1 bg-white/50 rounded-full">
          {subtitle}
        </span>
      </div>

      {/* 数据行 */}
      <dl className="space-y-2 mb-4">
        {dataRows.map((row, i) => (
          <DataRow key={i} {...row} />
        ))}
      </dl>

      {/* 今日卡片 */}
      {todayCard && (
        <div className={cn(
          "p-3 rounded-lg border",
          `${themeColors.bg} ${themeColors.border}`,
          "mb-3"
        )}>
          <div className="flex items-center justify-between mb-1.5">
            <span className={cn("text-xs font-medium", themeColors.accent)}>
              {todayCard.label}
            </span>
            <span className="text-sm">{todayCard.indicator}</span>
          </div>
          <p className="text-sm text-ink-700 leading-relaxed">
            {todayCard.text}
          </p>
        </div>
      )}

      {/* CTA */}
      <button
        onClick={onAnalyze}
        className={cn(
          "w-full flex items-center justify-center gap-1",
          "py-2 text-sm font-medium transition-colors group",
          themeColors.accent,
          `hover:${themeColors.accent.replace('700', '800')}`
        )}
      >
        <span>深度分析</span>
        <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
      </button>
    </div>
  );
}
```

### 3.4 数据行组件

```tsx
// components/me/shared/DataRow.tsx

export function DataRow({
  label,
  value,
  insight
}: {
  label: string;
  value: string;
  insight?: string;
}) {
  return (
    <div className="flex items-start gap-2">
      <dt className="text-xs text-muted-foreground w-20 flex-shrink-0 pt-0.5">
        {label}
      </dt>
      <dd className="flex-1">
        <div className="text-sm font-medium text-foreground mb-0.5">
          {value}
        </div>
        {insight && (
          <div className="text-xs text-ink-600/70 leading-relaxed">
            {insight}
          </div>
        )}
      </dd>
    </div>
  );
}
```

---

## 四、交互流程

### 4.1 默认状态（折叠）

```
┌─────────────────────────────────────────┐
│  [用户卡片：林小薇 · Pro]                │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  融合身份卡片                    │   │
│  │                                  │   │
│  │  [徽章] 创造者 · 探索者           │   │
│  │                                  │   │
│  │  "创造者的灵魂，探索者的心"      │   │
│  │                                  │   │
│  │  融合自八字（甲木·食神格）       │   │
│  │  × 星座（水瓶·天秤）             │   │
│  │                                  │   │
│  │  今日能量 🔥 85%  |  运势 ⭐⭐⭐⭐│   │
│  │                                  │   │
│  │  [探索更多维度 ↓]                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [设置 ▼]（折叠）                       │
│                                         │
└─────────────────────────────────────────┘

视觉焦点：融合身份卡片
用户第一眼看到："创造者的灵魂，探索者的心"
```

### 4.2 展开状态

用户点击"探索更多维度"后，卡片向下展开：

```
┌─────────────────────────────────────────┐
│  [用户卡片：林小薇 · Pro]                │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  融合身份卡片                    │   │
│  │  ...（同上）                     │   │
│  │  [收起 ↑]                        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │ ← 平滑展开
│  │  🌙 八字维度                     │   │
│  │  我的底层密码                    │   │
│  │                                  │   │
│  │  日主：甲木                      │   │
│  │    - 生命能量的根基              │   │
│  │  格局：食神格                    │   │
│  │    - 创造与表达的天赋            │   │
│  │  大运：丙火                      │   │
│  │    - 创造力爆发期（至2030）      │   │
│  │                                  │   │
│  │  [今日运势 ⭐⭐⭐⭐]              │   │
│  │  甲子日，水气旺盛...             │   │
│  │                                  │   │
│  │  [深度分析 →]                    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  ⭐ 星座维度                     │   │
│  │  我的宇宙坐标                    │   │
│  │  ...                             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  🌱 成长轨迹                     │   │
│  │  [时间线节点...]                 │   │
│  │  [查看完整旅程 →]                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [设置 ▼]（折叠）                       │
│                                         │
└─────────────────────────────────────────┘
```

**动画细节**：
- 展开动画：`duration-400ms, ease-[cubic-bezier(0.4, 0, 0.2, 1)]`
- 融合卡片阴影加深：`shadow-lg` → `shadow-xl`
- 维度卡片淡入：`opacity-0` → `opacity-1`

### 4.3 跳转 Chat 流程

用户点击维度详情中的"深度分析"：

```
Me 页
  ↓ 点击 [深度分析]
/chat?skill=bazi&prompt=详细分析我的八字
  ↓
Chat 页加载
  ↓
VibeLife: "好的，让我详细分析你的八字命盘..."
  ↓
（开始深度对话，展示四柱、大运、流年等详细信息）
```

**实现代码**：

```tsx
const handleBaziAnalyze = () => {
  router.push('/chat?skill=bazi&prompt=详细分析我的八字命盘');
};

const handleZodiacAnalyze = () => {
  router.push('/chat?skill=zodiac&prompt=分析我的星盘配置');
};

const handleGrowthReview = () => {
  router.push('/chat?skill=lifecoach&prompt=回顾我的成长轨迹');
};
```

---

## 五、数据模型

### 5.1 融合身份数据结构

```typescript
// types/me-page.ts

export interface FusedIdentity {
  // 核心本质（一句话）
  essence: string; // "创造者的灵魂，探索者的心"

  // 主原型（融合后）
  primaryArchetype: string; // "创造者"
  secondaryArchetype?: string; // "探索者"

  // 来源标注
  sources: {
    bazi: {
      dayMaster: string; // "甲木"
      pattern: string; // "食神格"
    };
    zodiac: {
      sun: string; // "水瓶座"
      ascendant: string; // "天秤座"
    };
  };

  // 今日状态
  today: {
    energy: number; // 0-100
    fortuneLevel: 1 | 2 | 3 | 4 | 5;
    insight: string; // "甲子日，水气旺盛，适合沟通学习"
  };

  // 元数据
  meta: {
    calculatedAt: string; // ISO timestamp
    version: string; // "v7.0"
  };
}
```

### 5.2 维度详情数据

```typescript
export interface DimensionDetails {
  bazi: {
    dayMaster: {
      value: string; // "甲木"
      insight: string; // "生命能量的根基"
    };
    pattern: {
      value: string; // "食神格"
      insight: string; // "创造与表达的天赋"
    };
    currentDayun: {
      value: string; // "丙火"
      insight: string; // "创造力爆发期"
      endYear: number; // 2030
    };
    todayFortune: {
      level: 1 | 2 | 3 | 4 | 5;
      text: string; // "甲子日，水气旺盛..."
    };
  };

  zodiac: {
    sun: {
      value: string; // "水瓶座"
      insight: string; // "创新思维的源泉"
    };
    ascendant: {
      value: string; // "天秤座"
      insight: string; // "和谐表达的方式"
    };
    moon?: {
      value: string; // "巨蟹座"
      insight: string; // "情感需求的核心"
    };
    todayEnergy: {
      level: 1 | 2 | 3 | 4 | 5;
      text: string; // "水星顺行，沟通顺畅"
    };
  };

  growth: {
    timeline: Array<{
      id: string;
      type: 'breakthrough' | 'evolution' | 'achievement';
      title: string;
      description: string;
      date: string; // ISO timestamp
      icon: string; // emoji
    }>;
  };
}
```

### 5.3 API 接口设计

```typescript
// API: GET /api/v1/me/fused-identity
// 返回融合身份数据

export async function getFusedIdentity(userId: string): Promise<FusedIdentity> {
  // 1. 读取 VibeID
  const vibeId = await VibeIDService.get_full(userId);

  // 2. 读取八字
  const bazi = await BaziService.get_summary(userId);

  // 3. 读取星座
  const zodiac = await ZodiacService.get_summary(userId);

  // 4. 融合生成 essence（核心算法）
  const essence = await generateEssence(vibeId, bazi, zodiac);

  // 5. 计算今日状态
  const today = await calculateTodayStatus(bazi, zodiac);

  return {
    essence,
    primaryArchetype: vibeId.primary_archetype,
    secondaryArchetype: vibeId.dimensions.inner?.archetype,
    sources: {
      bazi: {
        dayMaster: bazi.dayMaster,
        pattern: bazi.pattern,
      },
      zodiac: {
        sun: zodiac.sunSign,
        ascendant: zodiac.ascendant,
      },
    },
    today,
    meta: {
      calculatedAt: new Date().toISOString(),
      version: 'v7.0',
    },
  };
}
```

#### 核心算法：generateEssence

```typescript
async function generateEssence(
  vibeId: VibeIDFull,
  bazi: BaziSummary,
  zodiac: ZodiacSummary
): Promise<string> {
  // 融合逻辑：
  // 1. VibeID 提供主原型（如"创造者"）
  // 2. 八字提供底层特质（如"甲木日主 → 生长力强"）
  // 3. 星座提供表达方式（如"水瓶座 → 创新思维"）

  const template = `${vibeId.primary_archetype}的${bazi.coreQuality}，${zodiac.expressionStyle}`;

  // 示例输出：
  // "创造者的灵魂，探索者的心"
  // "智者的深度，英雄的勇气"
  // "探索者的好奇，照顾者的温暖"

  return template;
}
```

---

## 六、组件结构

### 6.1 目录结构

```
apps/web/src/components/me/
├── MePage.tsx                    # 主页面组件
├── FusedIdentityCard.tsx         # 融合身份卡片（核心）★
├── DimensionDetails.tsx          # 维度详情容器
│   ├── BaziDimension.tsx         # 八字维度卡片
│   ├── ZodiacDimension.tsx       # 星座维度卡片
│   └── GrowthTimeline.tsx        # 成长轨迹
├── UserInfoCard.tsx              # 用户信息卡片（简化版）
├── SettingsSection.tsx           # 设置区域（折叠）
└── shared/
    ├── ArchetypeBadge.tsx        # 原型徽章
    ├── DataRow.tsx               # 数据行组件
    ├── TimelineNode.tsx          # 时间线节点
    └── DimensionCard.tsx         # 维度卡片通用组件
```

### 6.2 主页面组件

```tsx
// components/me/MePage.tsx

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useMePageData } from '@/hooks/useMePageData';
import { FusedIdentityCard } from './FusedIdentityCard';
import { DimensionDetails } from './DimensionDetails';
import { UserInfoCard } from './UserInfoCard';
import { SettingsSection } from './SettingsSection';
import { MePageSkeleton } from './MePageSkeleton';

export function MePage() {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const { fusedIdentity, dimensions, user, loading } = useMePageData();

  if (loading) return <MePageSkeleton />;

  return (
    <div className="me-page h-full overflow-y-auto p-5 space-y-5">

      {/* Layer 0: 用户信息 */}
      <UserInfoCard user={user} />

      {/* Layer 1: 融合身份卡片 */}
      <FusedIdentityCard
        data={fusedIdentity}
        expanded={expanded}
        onToggle={() => setExpanded(!expanded)}
      />

      {/* Layer 2: 维度详情（展开层）*/}
      <DimensionDetails
        expanded={expanded}
        data={dimensions}
        onBaziAnalyze={() => router.push('/chat?skill=bazi&prompt=详细分析我的八字')}
        onZodiacAnalyze={() => router.push('/chat?skill=zodiac&prompt=分析我的星盘')}
        onGrowthReview={() => router.push('/chat?skill=lifecoach&prompt=回顾成长')}
      />

      {/* Layer 3: 设置（折叠）*/}
      <SettingsSection />

    </div>
  );
}
```

### 6.3 维度详情容器

```tsx
// components/me/DimensionDetails.tsx

import { AnimatePresence, motion } from 'framer-motion';
import { BaziDimension } from './BaziDimension';
import { ZodiacDimension } from './ZodiacDimension';
import { GrowthTimeline } from './GrowthTimeline';

export function DimensionDetails({
  expanded,
  data,
  onBaziAnalyze,
  onZodiacAnalyze,
  onGrowthReview
}: DimensionDetailsProps) {

  return (
    <AnimatePresence>
      {expanded && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: 'auto', opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          transition={{
            duration: 0.4,
            ease: [0.4, 0, 0.2, 1] // Custom easing
          }}
          className="overflow-hidden space-y-4"
        >

          {/* 八字维度 */}
          <BaziDimension
            data={data.bazi}
            onAnalyze={onBaziAnalyze}
          />

          {/* 星座维度 */}
          <ZodiacDimension
            data={data.zodiac}
            onAnalyze={onZodiacAnalyze}
          />

          {/* 成长轨迹 */}
          <GrowthTimeline
            data={data.growth}
            onReview={onGrowthReview}
          />

        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

---

## 七、实施计划

### Phase 1: 数据层（2天）

**任务**：
- [ ] 创建 `FusedIdentity` 数据模型（TypeScript types）
- [ ] 实现后端 `generateEssence()` 融合算法
- [ ] API: `GET /api/v1/me/fused-identity`
- [ ] API: `GET /api/v1/me/dimension-details`
- [ ] 单元测试：验证融合算法正确性

**产出文件**：
- `apps/api/services/me/fused_identity.py`
- `apps/api/routes/me.py`
- `apps/web/src/types/me-page.ts`

**验收标准**：
- API 返回正确的融合数据
- 融合算法能生成有意义的 essence（非模板化）
- 性能：响应时间 < 500ms

---

### Phase 2: 核心视觉组件（3天）

**Day 1-2**: 融合身份卡片
- [ ] `FusedIdentityCard.tsx`（完整实现）
- [ ] `ArchetypeBadge.tsx`
- [ ] 配色方案应用（Tailwind 配置）
- [ ] 展开/折叠动画调试

**Day 3**: 共享组件
- [ ] `DataRow.tsx`
- [ ] `DimensionCard.tsx`（通用模板）
- [ ] `TimelineNode.tsx`

**产出文件**：
- `apps/web/src/components/me/FusedIdentityCard.tsx`
- `apps/web/src/components/me/shared/`（所有共享组件）

**验收标准**：
- 视觉100%还原设计稿
- 动画流畅（60fps）
- 移动端适配完成

---

### Phase 3: 维度详情组件（2天）

**Day 1**: 八字 + 星座维度
- [ ] `BaziDimension.tsx`
- [ ] `ZodiacDimension.tsx`
- [ ] 今日运势/能量卡片样式

**Day 2**: 成长轨迹
- [ ] `GrowthTimeline.tsx`
- [ ] 时间线节点动画
- [ ] "查看完整旅程"跳转逻辑

**产出文件**：
- `apps/web/src/components/me/BaziDimension.tsx`
- `apps/web/src/components/me/ZodiacDimension.tsx`
- `apps/web/src/components/me/GrowthTimeline.tsx`

**验收标准**：
- 三个维度卡片视觉统一
- 跳转 Chat 流程测试通过
- 展开动画顺滑

---

### Phase 4: 页面整合（1天）

**任务**：
- [ ] 重构 `MePage.tsx`
- [ ] `DimensionDetails.tsx` 容器组件
- [ ] `useMePageData` hook（数据获取）
- [ ] Loading/Empty/Error 状态

**产出文件**：
- `apps/web/src/components/me/MePage.tsx`
- `apps/web/src/hooks/useMePageData.ts`
- `apps/web/src/components/me/MePageSkeleton.tsx`

**验收标准**：
- 完整页面可交互
- 数据加载流畅
- 错误处理完善

---

### Phase 5: 打磨优化（1天）

**任务**：
- [ ] 视觉细节调整（间距、圆角、阴影）
- [ ] 动画流畅度优化（Spring 动画调参）
- [ ] 移动端触摸手势优化
- [ ] 性能优化（React.memo, useMemo）
- [ ] 可访问性（键盘导航、ARIA 标签）

**验收标准**：
- Lighthouse 性能评分 > 90
- 无可访问性警告
- 动画帧率稳定 60fps

---

**总工作量**：约 **9 天**

---

## 八、关键决策记录

### 8.1 为什么融合 VibeID + 八字 + 星座？

**问题**：当前 MePanel.tsx 展示三个并列卡片（VibeID、八字、星座），用户反馈信息过载。

**决策**：融合为一个"身份卡片"，展示聚合后的洞察。

**理由**：
1. **用户期望**：访谈结果显示，用户希望看到"聚合融合"（选项C）
2. **避免重复**：三个并列卡片信息过载，核心洞察重复
3. **提升价值**：融合后的洞察 > 单一维度（如"创造者的灵魂" > 只看原型）
4. **艺术品感**：一个精美的"你是谁"比三个数据卡更有冲击力

**实现方式**：
- VibeID 提供主原型（"创造者"）
- 八字提供底层特质（"甲木 → 生长力"）
- 星座提供表达方式（"水瓶 → 创新"）
- 融合生成一句话本质：**"创造者的灵魂，探索者的心"**

**风险**：
- 融合算法可能生成"模板化"文案
- **缓解**：使用 LLM 生成个性化 essence，而非硬编码模板

---

### 8.2 为什么"部分动态成长"而非核心？

**问题**：是否将成长系统作为 Me 页核心？

**决策**：成长是"部分"，不是核心（80%静态展示 + 20%动态成长）

**理由**：
1. **用户定位**：访谈结果显示，Me 页本质是"A为主（静态展示），B一部分（动态成长）"
2. **避免复杂**：完整的成长系统会让 Me 页过于沉重，偏离"艺术品"定位
3. **轻交互原则**：成长详情应该在 Chat 或 Journey 页深度展开

**实现方式**：
- Me 页只展示最近 **3 个关键节点**（时间线）
- 点击"查看完整旅程"跳转 Chat，进行深度回顾

---

### 8.3 为什么不移除设置？

**问题**：设置区域（语气模式、通知）是否应该移除？

**决策**：保留，但通过折叠降低视觉权重。

**理由**：
1. **用户需要**：快速访问语气模式、通知设置是高频需求
2. **但不喧宾夺主**：通过默认折叠，不影响核心"身份卡片"
3. **符合轻交互**：用户需要时展开，不需要时隐藏

**实现方式**：
- 设置区域默认折叠
- 点击标题展开（类似手风琴）
- 视觉上使用低调的灰色背景

---

### 8.4 为什么使用 framer-motion？

**问题**：v9 架构强调性能优化，framer-motion 会增加 bundle size。

**决策**：在 Me 页使用 framer-motion，因为动画是核心体验。

**理由**：
1. **艺术品感**：平滑的展开/折叠动画是"艺术品"体验的关键
2. **性能可控**：framer-motion 按需加载，仅在 Me 页使用
3. **开发效率**：framer-motion 比 CSS 动画更容易控制复杂动画

**权衡**：
- Bundle size +35KB（gzipped）
- 但换来显著提升的视觉体验

---

## 九、成功指标

### 定量指标

| 指标 | 当前（估计）| 目标 |
|-----|----------|------|
| 首次"哇"时刻 | ? | **< 2秒**（打开即被融合身份卡片吸引）|
| 展开率 | ? | **> 60%**（用户主动点击"探索更多"）|
| 跳转 Chat 率 | ? | **> 30%**（从维度详情点击"深度分析"）|
| 页面停留时长 | ? | **> 45秒**（仔细阅读融合洞察）|
| 回访率（7天）| ? | **> 40%**（用户愿意重复查看）|

### 定性指标

**用户反馈期望**：
- "Me 页像一件艺术品" ✨
- "一句话就说清了我是谁"
- "展开后的细节很惊艳"
- "每次看都能发现新东西"

**设计师自检清单**：
- [ ] 视觉上有"书卷气"（羊皮纸质感）
- [ ] 一句话本质非模板化（个性化融合）
- [ ] 展开动画流畅（Spring easing）
- [ ] 移动端体验完整（触摸手势）
- [ ] 空状态/加载态优雅

---

## 十、附录

### A. 融合算法伪代码

```python
# apps/api/services/me/fused_identity.py

def generate_essence(vibe_id, bazi, zodiac):
    """
    融合算法：生成个性化的一句话本质

    输入：
    - vibe_id: VibeID 完整数据
    - bazi: 八字摘要数据
    - zodiac: 星座摘要数据

    输出：
    - essence: 一句话本质（如"创造者的灵魂，探索者的心"）
    """

    # 1. 提取关键特质
    primary_archetype = vibe_id.primary_archetype  # "创造者"
    inner_archetype = vibe_id.dimensions.inner.archetype  # "探索者"

    bazi_quality = extract_bazi_quality(bazi)  # "生长力强" (from 甲木)
    zodiac_expression = extract_zodiac_expression(zodiac)  # "创新思维" (from 水瓶)

    # 2. 构建模板
    template = f"{primary_archetype}的{bazi_quality_to_noun(bazi_quality)}，{inner_archetype}的{zodiac_expression_to_noun(zodiac_expression)}"

    # 示例输出：
    # "创造者的灵魂，探索者的心"
    # "智者的深度，英雄的勇气"
    # "照顾者的温暖，统治者的力量"

    return template

def extract_bazi_quality(bazi):
    """从八字提取核心特质"""
    day_master_map = {
        "甲木": "生长力强",
        "乙木": "柔韧坚韧",
        "丙火": "热情奔放",
        "丁火": "细腻温暖",
        # ... 更多映射
    }
    return day_master_map.get(bazi.day_master, "独特能量")

def bazi_quality_to_noun(quality):
    """将特质转换为名词形式"""
    noun_map = {
        "生长力强": "灵魂",
        "柔韧坚韧": "韧性",
        "热情奔放": "火焰",
        "细腻温暖": "光芒",
    }
    return noun_map.get(quality, "本质")
```

### B. 配色参考

```css
/* Tailwind Config Extension */

module.exports = {
  theme: {
    extend: {
      colors: {
        vellum: {
          50: '#FDFBF7',
          100: '#F9F5ED',
          200: '#F0E9D9',
          300: '#E4D9C1',
          400: '#D4C5A6',
        },
        ink: {
          500: '#5C4A3A',
          600: '#4A3A2A',
          700: '#3A2A1A',
          800: '#2A1A0A',
        },
      },
      boxShadow: {
        'card': '0 8px 30px rgba(139, 92, 46, 0.08)',
        'card-hover': '0 12px 40px rgba(139, 92, 46, 0.12)',
      },
    },
  },
}
```

---

**文档版本**: v1.0
**最后更新**: 2026-01-21
**设计师**: Claude Ultra Mode
**状态**: ✅ Ready for Implementation
