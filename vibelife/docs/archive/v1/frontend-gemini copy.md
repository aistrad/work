# 前端工程指南：VibeLife "Luminous Paper" (光纸设计)
> **目标状态**: 世界级 (World Class) 移动端优先体验
> **美学基准**: Apple Journal / Apple Books / Paper by WeTransfer
> **核心隐喻**: 魔幻现实主义 (东方神秘学遇见现代物理)

## 1. 设计哲学与物理质感 (Design Philosophy & Physics)

### 1.1 "光纸" (Luminous Paper) 的质感
我们构建的不是一个平面的 Web App，而是一张**有生命力的“数字纸张”**。

*   **肌理与表面 (Grain & Surface)**: 拒绝平坦的 `#FBF7F1` 色块。使用 CSS 噪点纹理 (Noise Texture) 叠加 `mix-blend-mode: multiply/overlay` 来创造深度。背景不应看起来像代码里的颜色值，而应看起来像**材质**。
*   **光照 (Lighting)**: “光晕”不是霓虹灯，而是**透纸而出的背光**。它是漫射的、柔和的、温暖的。
*   **墨水物理 (Ink Physics)**: 文字渲染采用微妙的 **模糊显影 (Blur-in)** 效果 (`blur(4px) -> blur(0)`) 结合透明度变化，模拟墨水渗入纸纤维并在纸面上干透的过程。

### 1.2 "禅意呼吸" 动效系统 (Zen Breath Motion)
*   **频率**: 极低 (0.05Hz - 0.1Hz)。
*   **触发**: 界面默认是静止的。只有在交互或“推演”阶段才会“苏醒”。
*   **实现**: 必须使用 `framer-motion` 的**弹簧物理 (Spring Physics)**。拒绝线性缓动 (Linear Easing)。所有的运动都必须带有动量和阻尼感 (Damping)。

---

## 2. 组件架构 (Mobile First)

### 2.1 "仪式感" 输入胶囊 (The Ritual Input)
**目标**: “书写契约” (流畅、安静、流体感)。

*   **交互细节**:
    *   **点击聚焦**: 胶囊轻微膨胀 (scale 1.02)，伴随“呼吸”般的缓动。
    *   **输入中**: 光标不是闪烁的竖线，而是一个柔和发光的游标或有节奏的脉冲。
    *   **触觉反馈**: 如果环境允许 (PWA/Web APIs)，在关键输入节点提供极轻微的震动反馈 (Haptics)。

### 2.2 "推演" 过场 (The Deduction Bridge)
**目标**: 连接“凡人输入”与“天机洞察”的 1.5秒 - 2秒 过场。一种“魔法机械装置”启动的感觉。

*   **架构**: 一个 `TransitionOverlay` 组件，根据 `NEXT_PUBLIC_SITE_ID` 接受不同的 `variant` 参数。
*   **变体 (Variants)**:
    *   `bazi` (八字): **同心环 (Concentric Rings)**。三圈石质/玉质圆环向不同方向转动（年/月/日柱归位）。视觉上要有“重物滑动”的物理分量感。
    *   `zodiac` (星座): **星连 (Star Connection)**。深蓝底色，星点逐个亮起，细金线快速勾勒出星座几何结构。
    *   `mbti`: **光谱折射 (Spectrum Shift)**。棱镜效果，光线分裂成四条独特的色带，最后汇聚成用户的类型。
    *   `tarot`: **洗牌 (Card Shuffle)**。视觉上的洗牌动画，最终定格为一张牌面朝下放置。

### 2.3 洞察卡片: "流中宝石" (Gems in the Stream)
**目标**: 沉浸感。绝对不打断对话流。

*   **视觉表现**:
    *   它们跟随聊天流一同流动。
    *   **区分度**: 拥有独特的 **微光流转 (Sheen)** 效果（卡片加载时一道斜光扫过）。
    *   **层级**: 极微妙的 `box-shadow`，暗示它们比普通消息气泡纸质“更厚”一点。
*   **交互**:
    *   **点击**: 展开为 **底部抽屉 (Bottom Sheet)** (使用 `vaul` 库)，**绝对不要**使用居中模态框 (Modal)。这能让拇指始终停留在舒适区。

---

## 3. 技术实现栈 (Technical Stack)

### 3.1 核心库
*   **框架**: Next.js 14 (App Router)
*   **动画**: `framer-motion` (复杂编排的标准)。
*   **样式**: Tailwind CSS + CSS Modules (处理复杂纹理)。
*   **图标**: `lucide-react` (调整笔触粗细以匹配字体字重)。
*   **移动手势**: `react-use-gesture` (用于拖拽关闭、滑动操作)。
*   **移动端 UI 原语**: `vaul` (用于高性能、原生手感的 Bottom Sheets)。

### 3.2 字体系统 ("墨")
*   **标题**: `Fraunces` (Google Fonts)。如果可能，利用 `font-variation-settings` 调整 SOFT (柔和度) 轴；或者精心调整字间距。
*   **正文**: `Bricolage Grotesque` 或 `Noto Sans SC`。高易读性，人文主义感。
*   **渲染**: 强制 `antialiased`，必要时开启 `text-rendering: optimizeLegibility`。

### 3.3 关键 CSS 变量 ("色")
定义语义化 Token，允许不同 Skill 切换“主题”但保持“Vibe”结构。

```css
:root {
  /* 物理参数 */
  --ink-blur-duration: 0.6s;
  --paper-grain-opacity: 0.03;

  /* 颜色 - 默认 (八字/土) */
  --paper-bg: #FBF7F1;
  --ink-primary: #1C1A17;
  --gold-accent: #B88A44;
  --breath-glow: rgba(184, 138, 68, 0.08);
}

[data-skill="zodiac"] {
  --gold-accent: #A7A6F4; /* 星空靛蓝 */
  --breath-glow: rgba(60, 58, 122, 0.08);
}
/* ... 其他 Skill 依次类推 */
```

---

## 4. 工程路线图 (优先级排序)

### Phase 1: "手感" (The Feel) - 基础建设
1.  **全局纹理布局**: 实现 `LuminousPaper` 布局容器，包含噪点纹理和高性能背景渐变。
2.  **字体与 Tailwind 配置**: 设置字体族和语义化颜色工具类。
3.  **聊天 UI 打磨**: 构建具有特定 "玻璃+纸" 美学的 `MessageBubble` 和 `Omnibar`。

### Phase 2: "仪式" (The Ritual) - 交互实现
4.  **输入胶囊**: 构建 `BirthInput` 组件，专注于聚焦状态和微动效。
5.  **推演引擎**: 创建 `DeductionOverlay` 系统，并优先实现 `Bazi` (圆环) 动画。

### Phase 3: "洞察" (The Insight) - 价值交付
6.  **洞察卡片与抽屉**: 实现可折叠卡片和移动端底部抽屉 (使用 `vaul`)。
7.  **Markdown/流式渲染**: 确保 AI 文字流式输出时具有 "墨水显影" (Ink Blur) 的逐字/逐词动画效果。

---

## 5. "World Class" 打磨清单

*   [ ] **滚动链 (Scroll Chaining)**: 聊天滚动是否有原生的回弹效果 (iOS rubber banding)？
*   [ ] **虚拟键盘**: `Omnibar` 唤起时是否完美贴合键盘，没有跳动 (Visual Viewport vs Layout Viewport)？
*   [ ] **触摸延迟**: 按钮是否在 `touch start` 瞬间响应 (Active 态)，而不是 `touch end`？
*   [ ] **加载状态**: 骨架屏 (Skeletons) 是否使用同样的纹理在“呼吸”，而不是通用的灰色闪烁？
*   [ ] **PWA**: 是否配置了 `manifest.json`，正确的 apple-touch-icons，以及 `viewport-fit=cover`？

本文档将作为前端工程实现的唯一真理来源 (Source of Truth)。
