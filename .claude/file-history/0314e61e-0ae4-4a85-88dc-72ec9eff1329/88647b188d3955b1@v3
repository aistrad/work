# Mentis 前端 Review 与优化方案

## 项目位置
`/home/aiscend/work/mentis/apps/web`

---

## 现有实现 Review 总结

### ✅ 已实现 (架构良好)

| 组件 | 文件 | 状态 |
|------|------|------|
| Stream Store | `src/stores/stream-store.ts` (219行) | ✅ 完整的 Zustand 状态管理 |
| SSE 流处理 | `src/lib/stream.ts` (88行) | ✅ 事件流解析 |
| WebSocket | `src/lib/realtime.ts` (339行) | ✅ 实时推送 |
| Dynamic Aura | `src/components/hud/dynamic-aura.tsx` (63行) | ⚠️ 需要 CSS 变量 |
| Stream Card | `src/components/stream/stream-card.tsx` (40行) | ⚠️ 需要样式优化 |
| Action Card | `src/components/stream/action-card.tsx` (49行) | ⚠️ 需要动画 |
| Stream Feed | `src/components/stream/stream-feed.tsx` (39行) | ✅ 基础功能 |
| Stream Screen | `src/components/stream/stream-screen.tsx` (47行) | ⚠️ 缺少 Omnibar |
| Top Status Bar | `src/components/stream/top-status-bar.tsx` (39行) | ⚠️ 需要样式优化 |
| DB Schema | `src/lib/db/schema.ts` (306行) | ✅ Drizzle ORM |

### ❌ 关键缺失

| 缺失项 | 严重程度 | 说明 |
|--------|----------|------|
| `tailwind.config.ts` | **CRITICAL** | CSS 变量未定义，样式失效 |
| `globals.css` | **CRITICAL** | 无全局样式，设计系统缺失 |
| `src/app/layout.tsx` | **CRITICAL** | 无根布局 |
| `src/app/page.tsx` | **CRITICAL** | 无 Landing Page |
| `src/app/login/page.tsx` | HIGH | 无登录页 |
| `Omnibar` 组件 | HIGH | stream-screen.tsx 引用但不存在 |
| `framer-motion` 依赖 | HIGH | 无动画库 |
| 字体配置 | HIGH | Playfair Display + Inter 未加载 |

---

## 优化方案

### Phase 1: 基础设施修复 (CRITICAL)

#### 1.1 创建 Tailwind 配置
**文件**: `/home/aiscend/work/mentis/apps/web/tailwind.config.ts`

```typescript
import type { Config } from 'tailwindcss'

export default {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        // Fortune AI 暖纸色系
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        card: 'hsl(var(--card))',
        border: 'hsl(var(--border))',
        accent: 'hsl(var(--accent))',
        muted: { DEFAULT: 'hsl(var(--muted))', foreground: 'hsl(var(--muted-foreground))' },
        success: 'hsl(var(--success))',
        destructive: 'hsl(var(--destructive))',
        // 五行元素色
        'element-water': 'hsl(var(--element-water))',
        'element-fire': 'hsl(var(--element-fire))',
        'element-earth': 'hsl(var(--element-earth))',
        'element-wood': 'hsl(var(--element-wood))',
        'element-metal': 'hsl(var(--element-metal))',
      },
      fontFamily: {
        serif: ['Playfair Display', 'Noto Serif SC', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      backdropBlur: { glass: '20px' },
      animation: {
        float: 'float 8s ease-in-out infinite',
        breathe: 'breathe 4s ease-in-out infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-20px)' },
        },
        breathe: {
          '0%, 100%': { transform: 'scale(1)', opacity: '0.8' },
          '50%': { transform: 'scale(1.05)', opacity: '1' },
        },
        'pulse-glow': {
          '0%, 100%': { opacity: '0.6' },
          '50%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
} satisfies Config
```

#### 1.2 创建全局样式
**文件**: `/home/aiscend/work/mentis/apps/web/src/app/globals.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* ========== Fortune AI Soul OS 设计系统 ========== */

@layer base {
  :root {
    /* 暖纸色系 (Light Mode) */
    --background: 40 20% 98%;        /* #FDFCFA */
    --background-subtle: 40 15% 96%;
    --foreground: 30 10% 22%;        /* #37352F */
    --foreground-muted: 30 5% 55%;
    --card: 0 0% 100%;
    --border: 40 10% 90%;
    --accent: 35 60% 52%;            /* #C9A05A 金麦色 */
    --muted: 40 10% 94%;
    --muted-foreground: 30 5% 55%;
    --success: 145 40% 45%;
    --destructive: 0 65% 55%;

    /* 五行元素色 */
    --element-water: 210 70% 45%;
    --element-water-dark: 210 70% 25%;
    --element-fire: 0 80% 55%;
    --element-fire-dark: 0 80% 35%;
    --element-earth: 40 70% 50%;
    --element-earth-dark: 40 70% 30%;
    --element-wood: 120 50% 40%;
    --element-wood-dark: 120 50% 25%;
    --element-metal: 30 5% 85%;
    --element-metal-dark: 30 5% 65%;

    /* Orb 渐变 */
    --orb-default-from: 25 60% 75%;  /* Soul Peach */
    --orb-default-to: 200 40% 80%;   /* Mist Blue */
    --orb-insight-from: 270 60% 55%; /* Mentis Purple */
    --orb-insight-to: 290 40% 75%;   /* Morning Haze */
  }

  .dark {
    --background: 220 10% 8%;
    --foreground: 40 10% 88%;
    --card: 220 10% 12%;
    --border: 220 8% 20%;
  }
}

/* ========== 字体 ========== */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Playfair+Display:ital,wght@0,400;0,500;0,600;1,400&family=Noto+Serif+SC:wght@400;500;600&display=swap');

body {
  font-family: 'Inter', system-ui, sans-serif;
  background: hsl(var(--background));
  color: hsl(var(--foreground));
}

/* ========== 玻璃态效果 ========== */
@layer utilities {
  .glass {
    background: hsl(var(--background) / 0.7);
    backdrop-filter: blur(20px);
    border: 1px solid hsl(var(--border) / 0.5);
  }

  .glass-card {
    background: hsl(var(--card) / 0.8);
    backdrop-filter: blur(16px);
    box-shadow:
      0 4px 24px hsl(var(--foreground) / 0.06),
      inset 0 1px 0 hsl(0 0% 100% / 0.1);
  }
}

/* ========== 动画 ========== */
@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-20px); }
}
```

#### 1.3 创建根布局
**文件**: `/home/aiscend/work/mentis/apps/web/src/app/layout.tsx`

```tsx
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Mentis - Decode. Reframe. Evolve.',
  description: '解码命运 · 重塑认知 · 进化人生',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  )
}
```

#### 1.4 安装缺失依赖
```bash
cd /home/aiscend/work/mentis/apps/web
pnpm add framer-motion
```

---

### Phase 2: Landing Page 创建

**文件**: `/home/aiscend/work/mentis/apps/web/src/app/page.tsx`

**设计要点**:
- 继承 Fortune AI Soul Orb 动画
- 生辰输入胶囊 (BirthInputCapsule)
- 即时命盘洞察
- 登录/注册入口

**组件拆分**:
```
src/components/landing/
├── mentis-soul-orb.tsx      # 五行渐变 Soul Orb
├── birth-input-capsule.tsx  # 生辰输入框
├── instant-insight-card.tsx # 快速洞察卡片
└── portal-modal.tsx         # 登录弹窗
```

---

### Phase 3: 登录页创建

**文件**: `/home/aiscend/work/mentis/apps/web/src/app/login/page.tsx`

**设计要点**:
- 两栏响应式布局
- 左侧: 登录/注册表单
- 右侧: 命盘预览 (八字/紫微)

**组件拆分**:
```
src/components/auth/
├── auth-form.tsx            # 认证表单
├── birth-info-panel.tsx     # 生辰信息
├── fortune-preview.tsx      # 命盘预览
└── social-auth-buttons.tsx  # 第三方登录
```

---

### Phase 4: 现有组件优化

#### 4.1 修复 Omnibar 缺失
**创建文件**: `/home/aiscend/work/mentis/apps/web/src/components/chat/omnibar.tsx`

```tsx
"use client"
import { useState } from "react"
import { Mic, Camera, Send } from "lucide-react"

export function Omnibar({ onSubmit }: { onSubmit: (content: string) => void }) {
  const [value, setValue] = useState("")

  return (
    <div className="glass-card rounded-full flex items-center px-4 py-3 gap-3">
      <button className="p-2 hover:bg-accent/10 rounded-full">
        <Mic className="w-5 h-5" />
      </button>
      <button className="p-2 hover:bg-accent/10 rounded-full">
        <Camera className="w-5 h-5" />
      </button>
      <input
        className="flex-1 bg-transparent outline-none placeholder:text-muted-foreground"
        placeholder="有什么想告诉我的..."
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onKeyDown={(e) => e.key === "Enter" && value && (onSubmit(value), setValue(""))}
      />
      <button
        className="p-2 bg-foreground text-background rounded-full hover:opacity-90"
        onClick={() => value && (onSubmit(value), setValue(""))}
      >
        <Send className="w-4 h-4" />
      </button>
    </div>
  )
}
```

#### 4.2 升级 StreamCard 样式
**修改**: `src/components/stream/stream-card.tsx`
- 添加玻璃态效果
- 使用 Fortune AI 配色
- 添加入场动画

#### 4.3 升级 DynamicAura
**修改**: `src/components/hud/dynamic-aura.tsx`
- 添加 Framer Motion 动画
- 状态切换平滑过渡
- 粒子效果增强

#### 4.4 升级 TopStatusBar
**修改**: `src/components/stream/top-status-bar.tsx`
- 玻璃态背景
- 金麦色能量/动量高亮
- 添加运势徽章

---

## 文件修改清单

### 新建文件 (9个)

| 优先级 | 文件路径 |
|--------|----------|
| P0 | `tailwind.config.ts` |
| P0 | `src/app/globals.css` |
| P0 | `src/app/layout.tsx` |
| P0 | `src/app/page.tsx` (Landing) |
| P1 | `src/app/login/page.tsx` |
| P1 | `src/components/chat/omnibar.tsx` |
| P1 | `src/components/landing/mentis-soul-orb.tsx` |
| P1 | `src/components/landing/birth-input-capsule.tsx` |
| P2 | `src/components/auth/auth-form.tsx` |

### 修改文件 (5个)

| 文件 | 修改内容 |
|------|----------|
| `package.json` | 添加 framer-motion 依赖 |
| `src/components/stream/stream-card.tsx` | 玻璃态 + 动画 |
| `src/components/hud/dynamic-aura.tsx` | Framer Motion 升级 |
| `src/components/stream/top-status-bar.tsx` | 玻璃态 + 样式优化 |
| `src/components/stream/action-card.tsx` | 长按动画效果 |

---

## 设计系统对齐检查表

| 特性 | Fortune AI | Mentis 现状 | 需要修复 |
|------|------------|-------------|----------|
| 暖纸底色 #FDFCFA | ✅ | ❌ | ✅ globals.css |
| 金麦强调色 #C9A05A | ✅ | ❌ | ✅ globals.css |
| Playfair Display 字体 | ✅ | ❌ | ✅ globals.css |
| Inter 正文字体 | ✅ | ❌ | ✅ globals.css |
| Soul Orb 动画 | ✅ | ⚠️ 简化版 | ✅ 需 Framer Motion |
| 玻璃态效果 | ✅ | ❌ | ✅ utilities |
| 弹簧动画 | ✅ | ❌ | ✅ 需 Framer Motion |
| 五行元素色 | ✅ | ⚠️ 变量未定义 | ✅ globals.css |

---

## 执行顺序

```
1. [P0] 创建 tailwind.config.ts
2. [P0] 创建 globals.css (完整设计系统)
3. [P0] 创建 layout.tsx
4. [P0] 安装 framer-motion
5. [P0] 创建 omnibar.tsx (修复 stream-screen 依赖)
6. [P1] 创建 Landing Page (page.tsx + 组件)
7. [P1] 创建 Login Page
8. [P2] 优化现有组件样式
9. [P2] 添加动画效果
```
