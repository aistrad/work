# Fortune AI Main 页面 UI/UX 优化计划

## 概述

基于 `system_design_final_mvp.md` 的产品愿景和当前代码实现，本计划旨在优化 main 页面的前端设计，提升用户体验，增强品牌识别度，并融入新中式赛博/Y2K酸性设计元素。

## 用户确认的方向

- **优化范围**：全面优化（P0→P1→P2 依次实现）
- **游戏化**：暂不实现（能量值、成就徽章等后续再做）
- **移动端**：**高优先级**（优先优化 Bottom Sheet 体验）

## 核心设计原则

- **三点击原则**：任何核心价值 ≤3 次点击完成
- **每次交互必落到 Commitment**
- **反依赖机制**：防玄学依赖
- **成图率优先**：满足Z世代审美身份展示需求
- **移动优先**：每个功能同时考虑桌面和移动端实现

---

## 实现优先级（调整后）

### P0 - 立即执行（视觉基础优化）

#### 1. Header 毛玻璃效果增强
**文件**: [ui.css](fortune_ai/api/static/ui.css)

```css
.ui-header {
  background: rgba(251,248,243,.75);
  backdrop-filter: saturate(180%) blur(16px);
  border-bottom: 1px solid rgba(255,255,255,.3);
  box-shadow: 0 4px 30px rgba(15,23,42,.06);
}
```

#### 2. 输入框 Focus 状态优化
**文件**: [ui.css](fortune_ai/api/static/ui.css)

```css
.ui-input:focus-within {
  background: #fff;
  border: 2px solid var(--brand-solid);
  box-shadow:
    0 0 0 4px rgba(15,118,110,.1),
    0 18px 34px rgba(15,23,42,.15);
}
```

#### 3. 卡片 Hover 效果（镭射边框）
**文件**: [ui.css](fortune_ai/api/static/ui.css)

```css
.ui-card::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1px;
  background: linear-gradient(
    135deg,
    rgba(15,118,110,.3),
    rgba(45,212,191,.4),
    rgba(245,158,11,.3)
  );
  -webkit-mask:
    linear-gradient(#fff 0 0) content-box,
    linear-gradient(#fff 0 0);
  mask-composite: exclude;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.ui-card:hover::before { opacity: 1; }
.ui-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 40px rgba(15,23,42,.1);
}
```

#### 4. 消息发送动画优化
**文件**: [ui.css](fortune_ai/api/static/ui.css)

```css
.msg-user {
  animation: msgSend 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes msgSend {
  0% { opacity: 0; transform: translateX(20px) scale(0.95); }
  100% { opacity: 1; transform: translateX(0) scale(1); }
}
```

#### 5. 发送按钮加载态
**文件**: [ui.css](fortune_ai/api/static/ui.css) + [ui.js](fortune_ai/api/static/ui.js)

```css
.ui-send-btn.loading {
  pointer-events: none;
  color: transparent;
}

.ui-send-btn.loading::after {
  content: "";
  position: absolute;
  width: 16px; height: 16px;
  border: 2px solid rgba(255,255,255,.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
```

---

### P1 - 短期执行（交互增强）

#### 1. Bento 卡片折叠/展开
**文件**: [bazi2.html](fortune_ai/api/templates/bazi2.html) + [ui.css](fortune_ai/api/static/ui.css) + [ui.js](fortune_ai/api/static/ui.js)

- 添加 `.ui-card__toggle` 按钮
- 实现 `.collapsed` 状态切换
- 添加过渡动画

```css
.ui-card.collapsed .ui-card__bd {
  max-height: 0;
  padding: 0 14px;
  overflow: hidden;
  transition: max-height 0.3s ease;
}
```

#### 2. 功能分组重构（Bento Panel）
**文件**: [bazi2.html](fortune_ai/api/templates/bazi2.html)

将6张卡片分为三组：
- **每日必用**：今日指引、情绪打卡
- **任务与决策**：行动处方、决策模板、话术生成
- **成长追踪**：成长计划

```html
<div class="ui-bento">
  <section class="ui-bento-group" data-priority="high">
    <div class="ui-bento-group__title">每日必用</div>
    <div class="ui-bento-group__cards">
      <!-- 今日指引、情绪打卡 -->
    </div>
  </section>
  <!-- ... -->
</div>
```

#### 3. 工具执行进度条
**文件**: [ui.css](fortune_ai/api/static/ui.css) + [ui.js](fortune_ai/api/static/ui.js)

```css
.ui-progress {
  height: 4px;
  background: var(--line);
  border-radius: 2px;
  overflow: hidden;
}

.ui-progress__bar {
  height: 100%;
  background: var(--brand);
  transition: width 0.3s ease;
}
```

#### 4. 移动端 Bottom Sheet 优化（高优先级）
**文件**: [ui.css](fortune_ai/api/static/ui.css) + [ui.js](fortune_ai/api/static/ui.js)

**重点优化项**：

1. **拖拽指示器**：
```css
.ui-workbench::before {
  content: "";
  position: absolute;
  top: 8px;
  left: 50%;
  transform: translateX(-50%);
  width: 40px; height: 4px;
  background: rgba(15,23,42,.2);
  border-radius: 2px;
}
```

2. **支持半展开态**（peek mode）：
```css
body.show-bento-peek .ui-workbench {
  transform: translateY(calc(100% - 200px));
}
```

3. **优化过渡动画**（使用 spring-like easing）：
```css
.ui-workbench {
  transition: transform 0.35s cubic-bezier(0.32, 0.72, 0, 1);
}
```

4. **手势支持**（JS实现）：
```javascript
// 触摸拖拽控制展开程度
// 快速滑动判定（velocity-based）
// 点击遮罩层关闭
```

5. **Viewport 高度优化**：
```css
.ui-workbench {
  height: 85vh;
  max-height: calc(100vh - 60px);
  max-height: calc(100dvh - 60px); /* 动态视口高度 */
}
```

6. **Viewer 区域移动端适配**：
```css
@media (max-width:1080px) {
  .ui-viewer {
    max-height: 28vh;
    min-height: 120px;
  }
}
```

#### 5. CSS 变量体系扩展
**文件**: [ui.css](fortune_ai/api/static/ui.css)

```css
:root {
  /* 新中式色彩 */
  --cinnabar: #e54d42;
  --ink-black: #1a1a1a;
  --rice-paper: #faf8f5;

  /* 光影层级 */
  --shadow-sm: 0 2px 8px rgba(15,23,42,.06);
  --shadow-md: 0 8px 24px rgba(15,23,42,.08);
  --shadow-lg: 0 16px 48px rgba(15,23,42,.12);
  --shadow-glow: 0 0 40px rgba(15,118,110,.15);

  /* 毛玻璃 */
  --glass-bg: rgba(255,255,255,.7);
  --glass-blur: blur(16px);
}
```

---

### P2 - 后续迭代（暂缓）

> 游戏化元素暂不实现，后续根据需求再做

- ~~Header 用户状态仪表盘~~
- ~~任务完成庆祝动画~~
- ~~成就徽章系统~~
- 统一图标系统（SVG Sprite）- 可在P1期间逐步引入

---

## 关键文件清单

| 文件 | 优化内容 | 优先级 |
|------|----------|--------|
| [ui.css](fortune_ai/api/static/ui.css) | 所有视觉样式、动画、响应式 | P0-P1 |
| [bazi2.html](fortune_ai/api/templates/bazi2.html) | HTML结构重构、Header优化 | P1 |
| [ui.js](fortune_ai/api/static/ui.js) | 交互逻辑、手势支持、动画控制 | P0-P1 |
| [tieban.css](fortune_ai/api/static/tieban.css) | 新中式设计参考 | 参考 |

---

## 实现步骤（建议顺序）

### 第一阶段：视觉基础 + 移动端（P0）

1. **扩展 CSS 变量体系** - `ui.css`
2. **Header 毛玻璃效果** - `ui.css`
3. **卡片 Hover 镭射边框** - `ui.css`
4. **输入框 Focus 状态** - `ui.css`
5. **消息动画优化** - `ui.css`
6. **发送按钮加载态** - `ui.css` + `ui.js`
7. **移动端 Bottom Sheet 拖拽指示器** - `ui.css`
8. **移动端过渡动画优化** - `ui.css`

### 第二阶段：交互增强（P1）

1. **Bento 卡片折叠/展开** - `bazi2.html` + `ui.css` + `ui.js`
2. **功能分组重构** - `bazi2.html` + `ui.css`
3. **工具执行进度条** - `ui.css` + `ui.js`
4. **移动端手势支持** - `ui.js`
5. **移动端半展开态** - `ui.css` + `ui.js`

---

## 技术注意事项

1. **保持原生JS兼容性**：所有交互均使用原生JS实现
2. **CSS变量命名规范**：
   - 颜色: `--{category}-{shade}`
   - 尺寸: `--{property}-{size}`
   - 效果: `--{effect}-{variant}`
3. **性能优化**：
   - 使用 `will-change` 优化频繁动画元素
   - 毛玻璃效果注意GPU占用（移动端尤其注意）
   - 手势事件使用 `passive: true`
4. **移动端特殊处理**：
   - 使用 `dvh` 单位处理Safari地址栏
   - 触摸事件防抖
   - 避免300ms点击延迟

---

## 预期效果

1. **品牌感提升**：通过Header优化、镭射边框、新中式元素增强识别度
2. **交互流畅度**：输入、发送、加载等关键路径的动画优化
3. **信息层次清晰**：Bento卡片分组、视觉优先级调整
4. **移动端体验**：优化的Bottom Sheet交互、手势支持、流畅过渡
