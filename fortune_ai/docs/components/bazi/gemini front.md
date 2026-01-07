
它的核心特点是：**极度的“圆润” (Radius)**、**悬浮感 (Elevation)**、**以文字为尊的排版**，以及**微妙的渐变色 (Gemini Gradient)**。

以下为您撰写的《Gemini 风格前端设计规范文档（复刻版）》。

---

# Gemini 风格聊天界面设计规范 (Design Spec v1.0)

## 1. 设计理念 (Design Philosophy)

* **空间感 (Airy):** 抛弃传统的“聊天气泡密集堆叠”，强调内容呼吸感。
* **容器化 (Container-based):** 核心操作区（输入框）和独立内容块采用高圆角的容器。
* **材质 (Material):** 使用浅灰色调区分层级，而非硬边框。
* **星空感 (Sparkle):** 使用蓝紫色渐变作为品牌识别（Loading、高亮、Logo）。

---

## 2. 布局结构 (Layout & Grid)

### 2.1 整体框架

采用 **左侧边栏 + 右侧主舞台** 结构。

* **侧边栏 (Sidebar):**
* 宽度：`260px` - `300px` (桌面端)。
* 状态：可折叠 (Collapsible)。折叠后变为汉堡菜单图标。
* 背景色：`#F0F4F9` (浅灰) 或 `#1E1F20` (深色模式)。
* 内容：由“新建对话”大按钮、历史记录列表、设置组成。


* **主舞台 (Main Stage):**
* 宽度：自适应，但在大屏上限制内容最大宽度 (`max-width: 850px`) 并居中，保证阅读视线不发散。
* 背景色：`#FFFFFF` (白) 或 `#131314` (纯黑/深灰)。



### 2.2 移动端适配

* 侧边栏隐藏，通过左上角“汉堡菜单”触发滑出层（Drawer）。
* 输入框始终吸底。

---

## 3. 色彩系统 (Color System)

Gemini 的配色非常克制，主要依靠**中性色**来烘托内容，仅在关键交互使用渐变。

| 语义 | Light Mode (HEX) | Dark Mode (HEX) | 说明 |
| --- | --- | --- | --- |
| **Background** | `#FFFFFF` | `#131314` | 全局背景 |
| **Surface** | `#F0F4F9` | `#1E1F20` | 侧边栏、输入框背景、用户消息底色 |
| **Text Primary** | `#1F1F1F` | `#E3E3E3` | 正文、标题 |
| **Text Secondary** | `#444746` | `#C4C7C5` | 辅助说明、时间戳 |
| **Brand Gradient** | `linear-gradient(90deg, #4285F4, #9B72CB, #D96570)` | 同左 | 用于 Logo、Loading 条、高亮文字 |
| **Input Active** | `#E8F0FE` (极淡蓝) | `#282A2C` | 输入框激活/Hover |

---

## 4. 核心组件 (Components)

### 4.1 底部输入区 (The Prompt Box)

这是 Gemini 灵魂所在，不同于传统 IM 的输入条，它更像一个“悬浮的控制台”。

* **外观：**
* 高圆角矩形 (`border-radius: 24px` 或更多)。
* 背景色：`#F0F4F9` (Surface)。
* 无边框，激活时可能有一圈 `2px` 的高亮或更深的背景色。


* **布局：**
* 左侧：`+` 号 (上传文件/图片)，圆形 Hover 背景。
* 中间：多行文本输入 (`textarea`)，自适应高度，无滚动条。
* 右侧：发送按钮（纸飞机/星形图标）。**空状态时为灰色，有输入时变为实心（深色或渐变）。**


* **位置：** 页面底部居中，但**不贴底**，距离底部约 `24px`，产生悬浮感。

### 4.2 消息流 (Message Stream)

Gemini 的消息流设计严格区分“我”和“AI”。

* **用户消息 (User Prompt):**
* **样式：** 灰色胶囊/块状背景 (`#F0F4F9`)。
* **圆角：** 大圆角 (`border-radius: 12px` 或 `24px`)。
* **对齐：** 靠右对齐（或居中布局下的右侧），强调“这是我的指令”。
* **宽度：** 自适应内容，不超过容器宽度的 70%。


* **AI 回答 (Model Response):**
* **样式：** **无气泡背景**，直接融入页面背景。
* **图标：** 左上角必须带有 Gemini 星光图标 (Sparkle Icon)。
* **对齐：** 左对齐，铺满容器宽度。
* **排版：** * Markdown 渲染。
* 行高 (`line-height`) 设为 `1.6` 或 `1.7`，极佳的阅读舒适度。
* 段间距 (`margin-bottom`) 宽松。


* **工具栏：** 回答下方悬浮一排小图标（复制、点赞、重新生成、修改），通常默认隐藏，Hover 时显示。


---

## 5. 排版与字体 (Typography)

Gemini 给人的感觉是“现代杂志”。

* **字体栈 (Font Stack):**
* 英文：`Google Sans`, `Roboto`, `Inter`, `system-ui`.
* 中文：`Noto Sans SC` (思源黑体), 避免使用宋体（除非是你的 Bazi 报告特定区域）。
* 代码：`Roboto Mono`, `Fira Code`.


* **字重：**
* 标题：`Medium (500)`，不使用过粗的 Bold，保持优雅。
* 正文：`Regular (400)`.


* **字号 (参考):**
* 正文：`16px` (Desktop) / `15px` (Mobile).
* 标题 H2/H3：`20px` / `18px`.



---

## 6. 动效与交互 (Micro-interactions)

1. **流式输出 (Streaming):**
* AI 回答时，文字逐字出现。
* **光标效应：** 当前生成的最后一个字符处，可能保留一个淡淡的圆形光标或闪烁符。


2. **思考状态 (Thinking):**
* 在 AI 开始回答前，使用**流光渐变 (Shimmer Effect)** 扫过输入框或显示一个带有品牌渐变的 Loading 动画（如波浪线或旋转的星星）。


3. **过渡 (Transitions):**
* 所有 Hover 效果（背景色变化）都需要 `transition: all 0.2s ease`，避免生硬切换。



---

## 7. 针对您的“Bazi 模块”特化建议

虽然采用 Gemini 风格，但您的内容是命理，建议做以下微调：

* **Markdown 表格：** Gemini 的表格是简单的细线表。建议您的命盘表格（四柱八字）加重表头背景色（如淡金/淡紫），使其在无框的 AI 回答中突显出来。
* **引用样式：** 当 AI 引用古籍（如铁板神数条文）时，使用左侧带有**品牌渐变竖线**的 Blockquote 样式，增加庄重感。
* **Artifacts 模式：** 如果生成的 Bazi 报告很长，参考 Claude 或 Gemini 的 "Drafts" 概念，在右侧弹出一个独立的“文档阅读器”层，保持左侧对话流的清洁。

---

### 附录：Tailwind CSS 核心配置参考

如果您使用 Tailwind，可以预设这些 Theme：

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        surface: '#F0F4F9',
        'surface-dark': '#1E1F20',
        primary: '#1F1F1F', // 文字主色
        brand: {
          start: '#4285F4',
          middle: '#9B72CB',
          end: '#D96570',
        }
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '24px', // Gemini 输入框标准
        '3xl': '32px',
      }
    }
  }
}

```
