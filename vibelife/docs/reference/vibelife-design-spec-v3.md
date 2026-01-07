# VibeLife UI/UX Design Specification v3.0

> **设计方向**: LUMINOUS PAPER (光纸)
> **版本**: 3.0
> **日期**: 2026-01-06
> **定位**: 魔幻现实主义 —— 东方神秘学遇见现代物理
> **美学基准**: Apple Journal / Apple Books / Paper by WeTransfer

---

## 执行摘要

### 设计核心理念

**LUMINOUS PAPER（光纸）**—— 不是复古羊皮纸，而是「被内光照亮的纸」

| 维度 | 传统方案 (VELLUM OS) | 本方案 (LUMINOUS PAPER) |
|------|---------------------|------------------------|
| 纸质感 | 静态旧羊皮纸 | 会呼吸的光纸，有背光感 |
| 视觉锚点 | 模糊的 Vibe Glyph | 明确的 Breath Aura + 有机形 |
| 个人化 | 仅换色 | 光晕+印章+形态都随五行/技能变化 |
| 品牌记忆点 | 弱 | 「我的命格在发光」|
| 差异化 | 像高端模板 | 像独特产品 |

### 关键交互决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 身份框架 | **Identity Prism (三元棱镜)** | Inner/Core/Outer 三档，表达人的多面性 |
| 洞察卡交互 | **响应式混合** | PC: Side Panel / Mobile: Bottom Sheet |
| 首次价值 | **推演过场 + 完整解读** | 1.5-2s 仪式感桥接 |
| 端侧优先级 | **移动端优先 (60/40)** | 核心体验移动端，PC 工作台基础版 |

---

## Part 1: 设计哲学

### 1.1 光纸 (Luminous Paper)

**拒绝平坦色块**，在 `--vellum (#FBF7F1)` 之上创造材质深度。

#### 1.1.1 纸张纹理层

```css
.luminous-paper {
  background: var(--vellum);
  position: relative;
}

.luminous-paper::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url('/textures/paper-grain.png');
  /* 或使用 SVG noise */
  opacity: 0.025;
  mix-blend-mode: multiply;
  pointer-events: none;
}
```

#### 1.1.2 背光光晕 (Breath Aura)

光晕是「背光」—— 柔和、漫射、温暖。**禁用霓虹感、禁用过亮 glow。**

```css
.breath-aura {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.breath-aura::before {
  content: '';
  position: absolute;
  width: 140%;
  height: 140%;
  top: -20%;
  left: -20%;
  background: 
    radial-gradient(ellipse 60% 50% at 25% 20%, var(--element-glow) 0%, transparent 50%),
    radial-gradient(ellipse 50% 60% at 75% 70%, var(--element-glow) 0%, transparent 45%);
  animation: breathe 6s ease-in-out infinite;
}

@keyframes breathe {
  0%, 100% { 
    opacity: 0.4;
    transform: scale(1);
  }
  50% { 
    opacity: 0.7;
    transform: scale(1.05);
  }
}
```

#### 1.1.3 五行光晕变量

根据用户五行属性动态注入：

```css
:root {
  /* 五行光晕色 */
  --wood-glow: hsla(120, 35%, 35%, 0.12);
  --fire-glow: hsla(0, 65%, 50%, 0.10);
  --earth-glow: hsla(40, 55%, 45%, 0.12);
  --metal-glow: hsla(30, 5%, 70%, 0.15);
  --water-glow: hsla(210, 55%, 40%, 0.10);
  
  /* 当前用户的元素光晕 */
  --element-glow: var(--wood-glow);
}
```

### 1.2 墨水物理 (Ink Physics)

流式文本/标题入场使用「模糊显影」效果：

```css
@keyframes ink-reveal {
  from { 
    filter: blur(4px); 
    opacity: 0; 
  }
  to { 
    filter: blur(0); 
    opacity: 1; 
  }
}

.ink-text {
  animation: ink-reveal 0.6s var(--ease-out-expo) forwards;
}
```

### 1.3 禅意呼吸动效 (Zen Breath)

| 属性 | 规范 |
|------|------|
| 频率 | 极低：`0.05Hz - 0.1Hz` (10-20 秒一个周期) |
| 默认 | 静止。只在交互/推演时「苏醒」|
| 缓动 | 统一 spring physics，**禁用 linear** |
| 强度 | 最大位移 `4px`，最大缩放 `1.02` |

```typescript
// 统一呼吸动效配置 (framer-motion)
export const breathVariants = {
  idle: { scale: 1 },
  breathing: {
    scale: [1, 1.015, 1],
    transition: {
      duration: 16,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};
```

---

## Part 2: 色彩系统

### 2.1 品牌主色

```
┌──────────────────────────────────────────────────────────────┐
│  Token          Light           Dark            用途         │
├──────────────────────────────────────────────────────────────┤
│  --background   #FBF7F1         #1C1A17         页面背景     │
│  --foreground   #1C1A17         #FBF7F1         主文本       │
│  --accent       #B88A44         #D4A55A         强调/CTA     │
│  --muted        #F5F0E8         #2A2825         次级背景     │
│  --border       #E8E0D6         #2A2822         边框         │
│  --card         #FFFFFF         #1E1D1A         卡片背景     │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 技能主题色

通过 `data-skill` 属性切换：

```
┌──────────────────────────────────────────────────────────────────┐
│  Skill      Primary         Accent          隐喻               │
├──────────────────────────────────────────────────────────────────┤
│  bazi       玄金 #8B7355    朱砂 #C45C48    铜钱/古卷           │
│  zodiac     星蓝 #4A5568    金线 #D4AF37    星空/黄道           │
│  mbti       棱镜 #6B46C1    光谱 #EC4899    折射/光谱           │
│  attach     珊瑚 #B13C41    桃粉 #F3A6A9    依恋/连接           │
│  career     青铜 #0E7490    翠光 #67E8F9    职业/成长           │
└──────────────────────────────────────────────────────────────────┘
```

### 2.3 五行状态色

```
┌──────────────────────────────────────────────────────────────┐
│  五行    色相              应用场景                          │
├──────────────────────────────────────────────────────────────┤
│  木      hsl(120 35% 35%)  成长、发展、学习                   │
│  火      hsl(0 65% 50%)    热情、警觉、紧急                   │
│  土      hsl(40 55% 45%)   稳定、喜悦、积极                   │
│  金      hsl(30 5% 70%)    收敛、中性、常规                   │
│  水      hsl(210 55% 40%)  平静、智慧、冥想                   │
└──────────────────────────────────────────────────────────────┘
```

---

## Part 3: 字体系统

### 3.1 字体家族

```css
:root {
  /* Display Serif - 情感标题/英文大标题 */
  --font-serif: 'Fraunces', 'Noto Serif SC', 'Source Han Serif SC', Georgia, serif;
  
  /* UI Sans - 正文/界面 */
  --font-sans: 'Bricolage Grotesque', 'Noto Sans SC', system-ui, sans-serif;
}
```

**选型理由**：
- **Fraunces**: 有「编辑部」气质，比传统衬线更现代，italic 变体带戏剧感
- **Bricolage Grotesque**: 有人味的 grotesque，避免 Inter 的「默认感」
- **Noto SC**: 中文回退，覆盖简繁体

### 3.2 字体层级

```
┌──────────────────────────────────────────────────────────────────┐
│  层级           尺寸                    样式                     │
├──────────────────────────────────────────────────────────────────┤
│  Hero Title     clamp(2rem, 5vw, 3.5rem)  font-serif italic -0.025em │
│  Section Title  1.75rem (28px)            font-serif 500 -0.02em    │
│  Card Title     1.125rem (18px)           font-sans 600 -0.01em     │
│  Body           1rem (16px)               font-sans 400 1.6 lh      │
│  Small          0.875rem (14px)           font-sans 400 muted       │
│  XS             0.75rem (12px)            font-sans 500 标签/时间戳  │
│  Tag            0.6875rem (11px)          font-sans 600 uppercase   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Part 4: 间距与圆角

### 4.1 圆角系统

```
xs:    0.375rem (6px)   - 小标签、badge
sm:    0.5rem (8px)     - 按钮内元素
md:    0.75rem (12px)   - 标准卡片、输入框
lg:    1rem (16px)      - 大卡片、模态框
xl:    1.5rem (24px)    - Hero 区域、特大容器
full:  9999px           - 圆形按钮、Omnibar、Tag
```

### 4.2 间距系统 (4px 基线)

```
1:   4px    - 内部微调
2:   8px    - 组件内间距
3:   12px   - 小组件间距
4:   16px   - 标准间距
5:   20px   - 区块内间距
6:   24px   - 区块间距
8:   32px   - 大区块间距
10:  40px   - Section 间距
12:  48px   - 页面级间距
```

---

## Part 5: 玻璃态与阴影

### 5.1 Frosted Glass 层级

```css
/* 标准玻璃 - 导航栏、Omnibar */
.glass {
  background: rgba(251, 247, 241, 0.9);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(232, 224, 214, 0.5);
}

/* 卡片玻璃 - Insight Card、Birth Capsule */
.glass-card {
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(232, 224, 214, 0.6);
  box-shadow:
    0 4px 24px rgba(28, 26, 23, 0.06),
    0 1px 3px rgba(28, 26, 23, 0.04),
    inset 0 1px 0 rgba(255, 255, 255, 0.5);
}

/* 轻量玻璃 - 次要区域 */
.glass-subtle {
  background: rgba(251, 247, 241, 0.7);
  backdrop-filter: blur(12px);
}
```

### 5.2 阴影层级

```css
--shadow-sm: 0 1px 3px rgba(28, 26, 23, 0.04);
--shadow-md: 0 4px 12px rgba(28, 26, 23, 0.06);
--shadow-lg: 0 8px 24px rgba(28, 26, 23, 0.08);
--shadow-xl: 0 16px 40px rgba(28, 26, 23, 0.12);

/* 聚焦状态阴影 */
--shadow-focus: 0 0 0 3px rgba(184, 138, 68, 0.15);
```

---

## Part 6: 动画系统

### 6.1 缓动函数

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);    /* 高端流畅感 */
--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);  /* 弹性活泼 */
--ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);       /* 标准平滑 */
```

### 6.2 入场动画

```css
/* 消息/卡片入场 */
@keyframes fade-in-up {
  from { 
    opacity: 0; 
    transform: translateY(10px); 
  }
  to { 
    opacity: 1; 
    transform: translateY(0); 
  }
}

/* 墨水显影 - 用于标题 */
@keyframes ink-reveal {
  from { 
    filter: blur(4px); 
    opacity: 0; 
  }
  to { 
    filter: blur(0); 
    opacity: 1; 
  }
}

/* 缩放入场 */
@keyframes scale-in {
  from { 
    opacity: 0; 
    transform: scale(0.95); 
  }
  to { 
    opacity: 1; 
    transform: scale(1); 
  }
}
```

### 6.3 微交互

```css
/* Hover */
.interactive:hover {
  transform: translateY(-2px);
  transition: transform 0.2s var(--ease-out-expo);
}

/* Active */
.interactive:active {
  transform: scale(0.98);
  transition: transform 0.1s;
}

/* Focus */
.interactive:focus-visible {
  outline: none;
  box-shadow: var(--shadow-focus);
}
```

---

## Part 7: 核心组件规格

### 7.1 Birth Input Capsule (仪式感输入胶囊)

**视觉规格**：

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                 输入你的出生日期，开始探索                    │
│                                                             │
│     ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│     │   年 ▾   │  │   月 ▾   │  │   日 ▾   │              │
│     └──────────┘  └──────────┘  └──────────┘              │
│                                                             │
│     ☐ 高级选项（时辰、地点）                                │
│                                                             │
│     ╭─────────────────────────────────────────╮            │
│     │           开始了解自己  →               │            │
│     ╰─────────────────────────────────────────╯            │
│                                                             │
│     glass-card | rounded-xl (1.5rem) | max-w-md            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**交互状态**：

| 状态 | 视觉表现 |
|------|----------|
| 默认 | 圆角胶囊，1px 边框，微弱内阴影 |
| 聚焦 | `scale(1.02)` + 边框变 accent + 外发光 |
| 完成 | 短暂 pulse + 收缩回原尺寸 |

**字段策略**：
- **必填**：生日（年/月/日）
- **选填**（收纳为「高级选项」）：
  - 时辰：可跳过，提示「时辰可提升精度」
  - 性别：包容性选项（女性/男性/非二元/不便透露）
  - 地点：默认北京，可修改

### 7.2 Identity Prism (三元身份棱镜)

**核心理念**：
> 用一个**极简交互**解决用户核心困惑：
> 「我内心是这样的，但别人觉得我是那样的」→ **人是多面的** → 我被理解/被允许

**视觉规格**：

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    IDENTITY PRISM                           │
│                                                             │
│     ○ Inner        ◉ Core        ○ Outer                   │
│     ════════════════●════════════════════                  │
│                                                             │
│              你真正稳定的驱动力是                            │
│                                                             │
│           ╭───────────────────────────╮                    │
│           │                           │                    │
│           │    「追求深度理解」         │                    │
│           │                           │                    │
│           ╰───────────────────────────╯                    │
│                                                             │
│     你天生对表象不满足，总想探究事物                         │
│     背后的本质。这让你在研究、分析、                         │
│     策略制定方面有独特优势。                                │
│                                                             │
│              来源：日主甲木 · 偏印格                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**三档含义**：

| 视角 | 含义 | 语气 |
|------|------|------|
| **Inner (阴)** | 内心最在意的 | 「在你心里，其实最在意的是…」 |
| **Core (本)** | 真正稳定的驱动力 | 「你真正稳定的驱动力是…」 |
| **Outer (阳)** | 给人的感觉 | 「你给人的感觉是…」 |

**TriToggle 组件**：

```typescript
interface TriToggleProps {
  value: 'inner' | 'core' | 'outer';
  onChange: (value: 'inner' | 'core' | 'outer') => void;
  disabled?: boolean;
}

// 动效配置 - 机械阻尼感
const toggleSpring = {
  type: 'spring',
  stiffness: 500,
  damping: 30,
};
```

**光晕变化规则**：

| 状态 | 光晕半径 | 亮度 | 呼吸频率 |
|------|----------|------|----------|
| Inner | 小 (0.8x) | 低 | 慢 (20s) |
| Core | 中 (1x) | 中 | 几乎静止 |
| Outer | 大 (1.2x) | 高 | 稳 (16s) |

### 7.3 Insight Card (洞察卡片)

**流中形态 (In-Stream)**：

```
┌─────────────────────────────────────────────────────────────┐
│  ✨ 发现                                                    │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  木旺而水弱，善于开始需学扎根                                │
│                                                             │
│  过去一个月你提到了 3 次"差一点点"，                         │
│  这可能和木的特质有关。                                     │
│                                                             │
│  展开详情 →                                                 │
│                                                             │
│  glass-card | border-left-4 accent | rounded-xl             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**展开交互（响应式）**：

| 端侧 | 交互形式 | 实现库 |
|------|----------|--------|
| Mobile (<1024px) | Bottom Sheet | `vaul` |
| PC (≥1024px) | Side Panel | framer-motion |

**展开后结构**：

```
┌─────────────────────────────────────────────────────────────┐
│  ────────────────── (Handle)                                │
│                                                             │
│  ✨ 发现                                        [✕]         │
│                                                             │
│  木旺而水弱，善于开始需学扎根                                │
│  ───────────────────────────────────────────────────────    │
│                                                             │
│  你的命盘显示：木旺而水弱。                                  │
│                                                             │
│  这意味着你天生善于开始新事物，充满创意与冲劲。              │
│  但也需要学习"扎根"——给自己更多的沉淀时间，                  │
│  让想法真正落地。                                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  证据                                               │   │
│  │  日主=甲木 · 月令=寅木 · 偏印透出                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐             │
│  │  ❤️   │ │  📤   │ │  🔍   │ │  💾   │             │
│  │  喜欢  │ │  分享  │ │  深入  │ │  保存  │             │
│  └────────┘ └────────┘ └────────┘ └────────┘             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**数据结构**：

```typescript
interface InsightCard {
  id: string;
  skill: 'bazi' | 'zodiac' | 'mbti';
  type: 'identity' | 'relationship' | 'trend' | 'action';
  title: string;
  summary: string;
  detail?: string;
  evidence?: {
    type: 'chart' | 'conversation';
    snippet: string;
  }[];
  actions: ('like' | 'share' | 'dive' | 'save')[];
  createdAt: string;
}
```

### 7.4 Now/Next Card (趋势卡片)

**视觉规格**：

```
┌─────────────────────────────────────────────────────────────┐
│  📍 当前阶段                                                │
│  ─────────────────────────────────────────────────────────  │
│  主题：沉淀与积累                                           │
│                                                             │
│  ⚠️ 注意：容易陷入细节，忘记大局                            │
│                                                             │
│  ✓ 可做：每周留出 2 小时做规划                              │
├─────────────────────────────────────────────────────────────┤
│  ➡️ 下一阶段（3 月起）                                       │
│  主题：向外拓展                                             │
└─────────────────────────────────────────────────────────────┘
```

**表达边界**：
- ✅ **只给**：阶段主题、风险/注意点、可做的事
- ❌ **不做**：不预测具体事件、不说「会发生什么」

### 7.5 Daily Greeting (每日问候)

**视觉规格**：

```
┌─────────────────────────────────────────────────────────────┐
│  🎋 小寒 · 寒气渐盛                                         │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  寒气渐盛，宜收敛精气。                                     │
│  今天适合处理需要耐心的事。                                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  今日一步                                           │   │
│  │  ☐ 拒绝一个不合理的请求                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  border-left-4 accent | rounded-xl                          │
└─────────────────────────────────────────────────────────────┘
```

### 7.6 Transition Overlay (推演过场)

**目标**：1.5-2s 的仪式感过渡

**视觉差异**：

| Skill | 视觉隐喻 | 实现 |
|-------|----------|------|
| bazi | 同心环转动（玉石质感）| SVG + framer-motion rotate |
| zodiac | 星点连线（深蓝底金线）| Canvas particles |
| mbti | 光谱折射（棱镜分光）| CSS gradient animation |

**必须提供**「跳过」按钮（无障碍 + 尊重用户时间）

### 7.7 Omnibar (输入栏)

**视觉规格**：

```
╭─────────────────────────────────────────────────────────────╮
│                                                             │
│  [🎤] [📷] │  有什么想问的...                    [→]       │
│                                                             │
╰─────────────────────────────────────────────────────────────╯

glass | rounded-full | shadow-lg
```

**状态**：

| 状态 | 视觉表现 |
|------|----------|
| 默认 | Icons muted, placeholder visible |
| 录音中 | Mic icon red, pulse animation |
| 输入中 | Send button activated |
| 发送中 | Send → Spinner |

---

## Part 8: 布局规格

### 8.1 移动端导航

**Bottom Nav (固定四 Tab)**：

```
┌────────┬────────┬────────┬────────┐
│  Chat  │  Chart │ Journey│   Me   │
│   💬   │   📊   │   🛤   │   👤   │
└────────┴────────┴────────┴────────┘

height: calc(80px + safe-area-bottom)
```

### 8.2 PC 端三栏布局

```
┌──────────────┬────────────────────────────┬──────────────────┐
│   Side Nav   │       Main Content         │  Insight Panel   │
│    240px     │       flex-1               │      360px       │
│              │      max-w-3xl             │                  │
│  · Chat      │                            │  · Identity      │
│  · Chart     │    [对话/图表/历程]         │    Prism         │
│  · Journey   │                            │  · Now/Next      │
│  · Me        │                            │  · Actions       │
│              │                            │                  │
│  ─────────   │                            │                  │
│  历史对话     │                            │                  │
└──────────────┴────────────────────────────┴──────────────────┘
```

### 8.3 响应式断点

```css
/* Tailwind 配置 */
screens: {
  'sm': '640px',   /* 手机横屏 */
  'md': '768px',   /* 平板 */
  'lg': '1024px',  /* PC（洞察卡交互切换点）*/
  'xl': '1280px',  /* 大屏 PC */
}
```

---

## Part 9: 技能形态语言

**核心理念**：不只是换颜色，而是**形态语言差异化**

| Skill | 形态语言 | 布局隐喻 | 图形元素 |
|-------|----------|----------|----------|
| 八字 | 方形模块 + 竖排 | 天干地支柱状结构 | 四柱卡片、同心环 |
| 星座 | 圆形 + 连线 | 星盘/星座连线 | 圆盘、星点、弧线 |
| MBTI | 四象限 + 轴线 | 认知功能坐标系 | 2×2 矩阵、滑块 |
| 依恋 | 同心圆 + 波纹 | 安全基地/依恋半径 | 扩散圆、距离指示 |

---

## Part 10: Insight Seal (个人化印章)

**核心理念**：每张 Insight Card 带一个「个人化印章」

```
  ┌─────────┐
  │   木    │  ← 五行汉字
  │         │
  │  ○ ○ ○  │  ← 基于生辰哈希的微变化
  │   ○ ○   │
  │  ○ ○ ○  │
  └─────────┘
```

**生成规则**：
- 基础图案：用户五行属性的抽象符号
- 边缘变化：基于生辰八字哈希的生成式微变化
- 效果：每个用户的印章都微妙不同
- 社交价值：「这是我的专属命格印记」

---

## Part 11: 分享卡片规格

### 11.1 尺寸规格

| 用途 | 尺寸 | 比例 |
|------|------|------|
| Instagram Story | 1080 × 1920 | 9:16 |
| 微信朋友圈 | 1080 × 1080 | 1:1 |
| 链接预览 | 1200 × 630 | 约 1.9:1 |

### 11.2 关系卡片内容

**只包含**：
- 一句关系结论
- 「你们最适合的沟通方式」一句
- 一个「下次就用这句开场」模板

**明确不包含**：
- 生日、星座/类型、命盘字段等敏感信息

---

## Part 12: 禁用话术

### 12.1 必须禁用

- ❌ 「你注定… / 你一定会… / 你逃不掉… / 这是命」
- ❌ 以恐惧驱动的句式：「不这样就会很惨/会出事/会破财」
- ❌ 情感操控式推销：「不买你就错过窗口期」

### 12.2 改用

- ✅ 「更可能 / 更容易 / 在…情况下常见 / 可以尝试」
- ✅ 客观描述 + 行动建议，而非宿命论断

---

## Part 13: 性能预算

| 指标 | 目标 |
|------|------|
| FCP | < 1.5s |
| LCP | < 2.5s |
| TTI | < 3.5s |
| Bundle Size (首屏) | < 150KB gzipped |

---

## Part 14: 组件清单

| 组件 | 文件位置 | 状态 |
|------|----------|------|
| LuminousPaper | `components/core/LuminousPaper.tsx` | ✅ |
| BreathAura | `components/core/BreathAura.tsx` | ✅ |
| InsightCard | `components/insight/InsightCard.tsx` | ✅ |
| InsightPanel | `components/insight/InsightPanel.tsx` | ✅ |
| TriToggle | `components/ui/TriToggle.tsx` | 🔨 |
| IdentityPrism | `components/identity/IdentityPrism.tsx` | 🔨 |
| TransitionOverlay | `components/core/TransitionOverlay.tsx` | 🔨 |
| NowNextCard | `components/trend/NowNextCard.tsx` | 🔨 |
| DailyGreeting | `components/greeting/DailyGreeting.tsx` | 🔨 |
| BirthCapsule | `components/input/BirthCapsule.tsx` | 🔨 |
| Omnibar | `components/chat/Omnibar.tsx` | 🔨 |
| BottomSheet | `components/ui/BottomSheet.tsx` | 🔨 |
| SidePanel | `components/ui/SidePanel.tsx` | 🔨 |
| InsightSeal | `components/insight/InsightSeal.tsx` | 🔨 |

---

## 附录 A: CSS 变量完整清单

```css
:root {
  /* Colors */
  --background: #FBF7F1;
  --foreground: #1C1A17;
  --accent: #B88A44;
  --accent-light: #D4A55A;
  --muted: #F5F0E8;
  --muted-foreground: #6D655B;
  --border: #E8E0D6;
  --card: #FFFFFF;
  
  /* Skill Colors */
  --bazi-primary: #8B7355;
  --bazi-accent: #C45C48;
  --zodiac-primary: #4A5568;
  --zodiac-accent: #D4AF37;
  --mbti-primary: #6B46C1;
  --mbti-accent: #EC4899;
  
  /* Element Glows */
  --wood-glow: hsla(120, 35%, 35%, 0.12);
  --fire-glow: hsla(0, 65%, 50%, 0.10);
  --earth-glow: hsla(40, 55%, 45%, 0.12);
  --metal-glow: hsla(30, 5%, 70%, 0.15);
  --water-glow: hsla(210, 55%, 40%, 0.10);
  --element-glow: var(--wood-glow);
  
  /* Typography */
  --font-serif: 'Fraunces', 'Noto Serif SC', Georgia, serif;
  --font-sans: 'Bricolage Grotesque', 'Noto Sans SC', system-ui, sans-serif;
  
  /* Easing */
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
  --ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);
  
  /* Shadows */
  --shadow-sm: 0 1px 3px rgba(28, 26, 23, 0.04);
  --shadow-md: 0 4px 12px rgba(28, 26, 23, 0.06);
  --shadow-lg: 0 8px 24px rgba(28, 26, 23, 0.08);
  --shadow-xl: 0 16px 40px rgba(28, 26, 23, 0.12);
  --shadow-focus: 0 0 0 3px rgba(184, 138, 68, 0.15);
  
  /* Safe Areas */
  --safe-area-bottom: env(safe-area-inset-bottom, 0px);
}
```

---

## 附录 B: 技术栈

| 类别 | 库 | 版本 |
|------|-----|------|
| 框架 | Next.js (App Router) | 14.x |
| 状态管理 | Zustand | 4.x |
| 动效 | framer-motion | 10.x |
| Bottom Sheet | vaul | 0.9.x |
| 样式 | Tailwind CSS | 3.x |
| 图标 | lucide-react | 0.x |
| 流式响应 | Vercel AI SDK | 3.x |

---

*Document Version: 3.0*
*Last Updated: 2026-01-06*
