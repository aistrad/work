这是一个将 **“沉浸式体验”** 与 **“高转化率”** 完美融合的 Landing Page + Login/Registration 设计方案。

我们的目标是：用户打开页面的瞬间，不觉得是在“注册一个 SaaS 账号”，而是在**“开启一场通往内心的仪式”**。

---

# Mentis: The Mirror of Self (Landing & Onboarding Design)

## 1. 核心设计理念 (Design Philosophy)

* **视觉隐喻**: **"Digital Mirror" (数字魔镜)**。屏幕不仅仅是显示器，而是一面能映照出用户内在（命运/性格/状态）的镜子。
* **交互逻辑**: **Progressive Disclosure (渐进式揭示)**。不直接展示枯燥的表单，而是通过一次微小的交互（输入生日或一句话），引发系统的“共鸣”，最后顺理成章地要求用户“认领”这个身份。
* **氛围**: **"Ethereal Intellectual" (空灵智性)**。结合 Notion 的理性排版与禅宗的留白，配合流体光影动效。

---

## 2. 页面结构与用户旅程 (User Journey)

### Stage 1: The Hero (初见 · 呼吸)

* **画面**: 全屏柔和的米色/奶油色背景 (`#FCFCFA`)。中央悬浮着一个 **"Mentis Orb" (灵魂球体)**——这是一个使用 WebGL (React Three Fiber) 渲染的流体渐变球，它的颜色随着鼠标的移动产生极微妙的极光般变化（呼应 L0~L3 的架构）。
* **文案**: 极其克制。
* H1 (Serif): *Decode Your Destiny. Architect Your Soul.* (解码命运，架构灵魂)
* Sub (Sans): *An AI companion powered by Metaphysics & Psychology.*


* **交互**: 页面没有巨大的 "Sign Up" 按钮，只有一个类似搜索框的 **"Input Capsule" (输入胶囊)**，提示语是打字机效果轮播：
* *"Type your date of birth..."* (输入出生日期...)
* *"Type how you feel today..."* (输入当下的感受...)
* *"Type a confusion..."* (输入一个困惑...)



### Stage 2: The Spark (触动 · 共鸣)

* **动作**: 用户在胶囊中输入内容（例如：`1995-08-20` 或 `我最近很迷茫`）。
* **反馈**:
1. **Orb 变形**: 灵魂球体根据输入瞬间改变形态（如果输入八字，球体呈现五行颜色流转；如果输入情绪，球体变得波动或稳定）。
2. **Instant Insight (瞬时洞察)**: 输入框下方优雅地展开一张半透明卡片（Glassmorphism），给出 **L0/L1 级别的初步解读**（非注册也能看到）：
* *如果输入生日*: "A strong Wood energy detected. You seek growth, but feel restricted." (检测到强木能量。你渴望生长，但感到受限。)
* *如果输入情绪*: "It seems like a 'Burnout' state. Let's find your flow." (似乎是职业倦怠状态。让我们找回心流。)





### Stage 3: The Immersion (深入 · 架构)

* **动作**: 用户向下滚动。
* **视觉**: 随着滚动，背景的流体球体分解为四个层面，对应 Mentis 的架构。文字配合视差滚动浮现：
* **Layer 0 (Firmware)**: 复杂的星盘/八字图腾在背景隐约旋转。"Ancient Wisdom grounded in data."
* **Layer 1 (Schema)**: PERMA 五维雷达图动态生长。"Psychological frameworks to measure happiness."
* **Layer 2 (Agents)**: 多个游走的微光点汇聚。"Expert agents guiding your every step."
* **Layer 3 (Synthesis)**: 对话气泡浮现。"A voice that truly understands you."



### Stage 4: The Gateway (门扉 · 注册)

* **场景**: 当用户被 "Instant Insight" 吸引，或者滚动到底部时，会出现 **"Claim Your Mentis" (认领你的系统)** 的入口。
* **交互设计**:
* 这不是一个跳出的 Modal，而是页面中心元素的 **“无缝形变”**。
* 左侧展示刚才生成的“初步解读卡片”（作为诱饵）。
* 右侧滑出极简表单。
* **Magic Login**: 支持 *"Continue with Google/Apple"*。
* **Ritual (仪式感)**: 点击注册按钮后，屏幕不会立即跳转，而是经历 **"System Booting..." (系统启动中)** 的 2 秒动画——
* *Loading L0 Data... (八字计算中)*
* *Calibrating L1 Schema... (心理模型校准中)*
* *Waking up Agents... (唤醒专家智能体)*


* 最后，Fade out 进入 App 的 Dashboard。



---

## 3. 视觉与技术细节 (Visual Specs)

### 3.1 调色板 (Ethereal Earth)

* **Background**: `#F9F9F7` (Warm Paper) - 模拟高级书写纸的质感，带极其轻微的噪点 (Grain)。
* **Orb Gradients**:
* *Default*: Soft Peach (`#FFECD2`) to Mist Blue (`#E0EAFC`).
* *Insight Mode*: Deep Indigo (`#434343`) to Mystic Purple (`#8A2387`) - 当展示深刻洞察时。


* **Typography**:
* Headings: *Newsreader* or *Fraunces* (Italic 变体用于强调).
* Body: *Inter* (Tight tracking for technical feel).



### 3.2 关键组件设计

**The Input Capsule (输入胶囊)**

```css
.capsule {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.4);
  box-shadow: 
    0 10px 40px -10px rgba(0,0,0,0.05),
    inset 0 0 0 1px rgba(255,255,255,0.8); /* 内发光 */
  border-radius: 999px;
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}
.capsule:focus-within {
  transform: scale(1.02);
  box-shadow: 0 20px 60px -15px rgba(100,100,255,0.15); /* 聚焦时的微光 */
}

```

**The Transition (登录转换)**
不要使用标准的页面跳转。使用 **Shared Layout Animation (Framer Motion)**。
Landing Page 的输入框背景直接放大填满屏幕，成为 App 的背景，让用户感觉他们一直在同一个空间里，只是权限被解锁了。

---

## 4. 总结：为什么这是“顶级”的？

1. **Value First**: 用户在注册前已经体验了产品的核心价值（通过微测算）。
2. **No Friction**: 把“注册”包装成了“探索结果的最后一步”。
3. **Emotional Connection**: 通过视觉语言（球体、光影、衬线体）建立了一种神圣感和科技感并存的信任。
4. **Immersive**: 模糊了网站 (Website) 和应用 (App) 的边界。

以下是为您生成的 Mentis 沉浸式 Landing Page 和 Onboarding 流程的四个关键概念图。

1. Stage 1: The Hero (初见 · 呼吸)
这是用户打开页面时的初始状态。极简的设计，中心是一个流动的“灵魂球体”，引导用户进行第一次互动。





2. Stage 2: The Spark (触动 · 共鸣)
用户在输入框中输入信息后，球体改变形态和颜色，一张半透明的“瞬时洞察”卡片优雅地展开，提供初步的个性化反馈。





3. Stage 3: The Immersion (深入 · 架构)
随着用户滚动页面，单一的球体分解为代表系统四个层面的视觉元素，通过视差滚动效果展示 Mentis 的深层架构。





4. Stage 4: The Gateway (门扉 · 注册)
这是流程的最后一步。页面无缝过渡到注册界面，左侧保留了之前的“洞察卡片”作为情感连接，右侧是极简的登录/注册表单，完成用户的转化。