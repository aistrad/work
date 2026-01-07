# VibeLife 前端工程指南 v3.0

> **文档定位**：Phase 1 前端落地的唯一真理来源 (Source of Truth)
> **目标状态**：世界级移动端优先体验 + PC 端沉浸式工作台
> **美学基准**：Apple Journal / Apple Books / Paper by WeTransfer
> **核心隐喻**：魔幻现实主义 —— 东方神秘学遇见现代物理
> **Last Updated**：2026-01-06

---

## 0. 执行摘要

### 0.1 本文要解决什么

把「愿景」落到「4 周可交付的 P0 体验」：

| 目标 | 定义 | 核心指标 |
|------|------|----------|
| **引流** | 有特色功能、可传播、别的 App 没有 | `share_complete_rate` |
| **激活** | 眼前一亮、极易用、立刻解决痛点 | `first_value_rate` |
| **第一口价值** | 高质量解读 + 高质量洞察（质量 > 速度） | `first_value_achieved` |

### 0.2 关键决策摘要

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 身份框架 | **三元 Identity Prism** (Inner/Core/Outer) | 更细腻表达人的多面性，符合东方命理层次观 |
| 洞察卡交互 | **响应式混合** (PC: Side Panel / Mobile: Bottom Sheet) | PC 不遮挡聊天，移动端原生感 |
| Relationship Simulator | **P0+ 含双用户模式** | 杀手级引流功能，隐私友好是核心差异化 |
| 端侧优先级 | **双端并重 (60/40)** | 移动端核心体验 + PC 工作台基础版 |
| 首次价值 | **混合策略** | 推演过场 (1.5-2s) 作为仪式感桥接，再给完整解读 |
| 趋势表达 | **只给主题 + 注意点** | 不预测具体事件，避免贩卖焦虑 |

---

## 1. 设计哲学与物理质感

### 1.1 光纸 (Luminous Paper)

**拒绝平坦色块**，在 `--vellum (#FBF7F1)` 之上创造材质深度：

```css
/* 噪点纹理叠加 */
.luminous-paper {
  background: var(--vellum);
  position: relative;
}
.luminous-paper::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url('/textures/paper-grain.png');
  opacity: 0.03;
  mix-blend-mode: multiply;
  pointer-events: none;
}
```

**光晕是背光**：柔和、漫射、温暖。禁用霓虹感、禁用过亮 glow。

**墨水物理**：流式文本 / 标题入场用「模糊显影」：

```css
@keyframes ink-reveal {
  from { filter: blur(4px); opacity: 0; }
  to   { filter: blur(0);   opacity: 1; }
}
.ink-text {
  animation: ink-reveal 0.6s var(--ease-out-expo) forwards;
}
```

### 1.2 禅意呼吸动效 (Zen Breath)

| 属性 | 规范 |
|------|------|
| 频率 | 极低：`0.05Hz - 0.1Hz` (10-20 秒一个周期) |
| 默认 | 静止。只在交互 / 推演时「苏醒」 |
| 缓动 | 统一 `framer-motion` **spring physics**，禁用 `linear` |
| 强度 | 最大位移 `4px`，最大缩放 `1.02` |

```typescript
// 统一呼吸动效配置
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

### 1.3 色彩系统

**语义色**（已在 `globals.css` 定义）：

| Token | Light | Dark | 用途 |
|-------|-------|------|------|
| `--background` | `#FBF7F1` | `#1C1A17` | 页面背景 |
| `--foreground` | `#1C1A17` | `#FBF7F1` | 主文本 |
| `--accent` | `#B88A44` | `#D4A55A` | 强调/CTA |
| `--muted` | `#F5F0E8` | `#2A2825` | 次级背景 |

**技能主题色**（通过 `data-skill` 属性切换）：

| Skill | Primary | Accent | 隐喻 |
|-------|---------|--------|------|
| `bazi` | 玄金 `#8B7355` | 朱砂 `#C45C48` | 铜钱/古卷 |
| `zodiac` | 星蓝 `#4A5568` | 金线 `#D4AF37` | 星空/黄道 |
| `mbti` | 棱镜 `#6B46C1` | 光谱 `#EC4899` | 折射/光谱 |

---

## 2. 信息架构 (IA)

### 2.1 四大诉求主叙事

Phase 1 的产品骨架围绕用户最大诉求展开：

```
1. 身份：我是谁 (Identity Prism)     → 第一次击中 (Activation)
2. 关系：我们是什么 (Relationship)   → 可分享、可传播 (Acquisition)
3. 趋势：我正处在什么阶段 (Now/Next) → 复访动机 (Retention seed)
4. 改变：我下一步怎么做 (Coach)      → 长期价值 (Monetization seed)
```

### 2.2 导航结构

#### 移动端 BottomNav (固定四 Tab)

```
┌────────┬────────┬────────┬────────┐
│  Chat  │  Chart │ Journey│   Me   │
│   💬   │   📊   │   🛤   │   👤   │
└────────┴────────┴────────┴────────┘
```

| Tab | 职责 | P0 内容 |
|-----|------|---------|
| **Chat** | 对话主线，洞察卡嵌入 | 流式对话 + 洞察卡 + Daily Greeting |
| **Chart** | 结构化解读（命盘/星盘/类型） | Identity Prism + 出盘结果 + 证据 |
| **Journey** | 洞察库 + 周期回顾 + 轻量行动 | 洞察收藏列表 + 7天微行动 |
| **Me** | 身份开关 + 偏好 + 订阅 | Identity Prism (常驻) + 设置 |

#### PC 端三栏布局

```
┌──────────┬────────────────────────┬──────────────────────┐
│  导航栏  │       聊天主区域        │    Insight Panel     │
│  (240px) │     (max-w-3xl)        │      (360px)         │
│          │                        │                      │
│  · Chat  │   [对话流 + 输入框]    │  · Identity Prism    │
│  · Chart │                        │  · 当前洞察详情      │
│  · Journey                        │  · Now/Next 趋势     │
│  · Me    │                        │  · 快捷操作          │
│          │                        │                      │
│  ─────── │                        │                      │
│  历史    │                        │                      │
└──────────┴────────────────────────┴──────────────────────┘
```

### 2.3 路由规范 (Next.js App Router)

```
/                       # 首页 Landing
/{skill}                # 技能入口 (bazi/zodiac/mbti)
/{skill}/chat           # 对话页
/{skill}/chart          # 图表/报告页
/{skill}/journey        # 回顾/时间线
/me                     # 全局个人中心
/auth/login             # 登录
/auth/register          # 注册
/relationship           # 关系模拟器入口
/relationship/[id]      # 关系详情页
```

---

## 3. 核心组件规格

### 3.1 仪式感输入胶囊 (Birth Input Capsule) — P0

**交互规范**：

| 状态 | 视觉表现 |
|------|----------|
| 默认 | 圆角胶囊，1px 边框，微弱内阴影 |
| 聚焦 | `scale(1.02)` + 边框变 accent + 外发光 |
| 完成 | 短暂 pulse + 收缩回原尺寸 |

**字段策略**：

```
必填：生日（年/月/日）
选填（收纳为「高级选项」）：
  - 时辰：可跳过 (unknown)，提示「时辰可提升精度」
  - 性别：包容性选项（女性/男性/非二元/不便透露）
  - 地点：默认北京，可修改
```

**包容性要求**：
- 文案避免默认异性恋叙事
- 关系建议使用中性措辞
- 性别字段不做二元假设

### 3.2 推演过场 (Deduction Bridge) — P0

**目标**：1.5-2s 的仪式感过渡，连接「凡人输入」与「天机洞察」

| Skill | 视觉隐喻 | 技术实现 |
|-------|----------|----------|
| `bazi` | 同心环转动（玉石质感） | SVG + framer-motion rotate |
| `zodiac` | 星点连线（深蓝底金线） | Canvas particles + line drawing |
| `mbti` | 光谱折射（棱镜分光） | CSS gradient animation |

**工程规范**：
- 统一组件：`<TransitionOverlay variant="bazi|zodiac|mbti" />`
- 必须提供「跳过」按钮（无障碍 + 尊重用户时间）
- 过场期间预加载后续数据

```typescript
interface TransitionOverlayProps {
  variant: 'bazi' | 'zodiac' | 'mbti';
  duration?: number; // 默认 2000ms
  onComplete: () => void;
  onSkip?: () => void;
}
```

### 3.3 洞察卡片 (Insight Card) — P0

**流中形态 (Gems in the Stream)**：

```
┌─────────────────────────────────┐
│ ✨ 洞察                         │
│ ┌───────────────────────────┐   │
│ │  你的核心驱动力是          │   │
│ │  「追求深度理解」          │   │
│ │                           │   │
│ │  [展开详情 →]              │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

**展开交互（响应式混合）**：

| 端侧 | 交互形式 | 实现库 |
|------|----------|--------|
| Mobile (<1024px) | Bottom Sheet | `vaul` |
| PC (≥1024px) | Side Panel (右栏内切换) | 自定义 + framer-motion |

**展开后必备功能**：

| 功能 | 交互 | 优先级 |
|------|------|--------|
| 喜欢 | 点击心形，只做正向反馈 | P0 |
| 分享 | 复制文本 / 生成海报 (二选一先做复制) | P0 |
| 深入解读 | 生成 follow-up prompt，回到对话 | P0 |
| 收藏/保存 | 点击触发渐进注册，登录后进入 Journey | P0 |

**数据结构**：

```typescript
interface InsightCard {
  id: string;
  skill: 'bazi' | 'zodiac' | 'mbti';
  type: 'identity' | 'relationship' | 'trend' | 'action';
  title: string;           // 一句话标题
  summary: string;         // 2-3 句核心洞察
  detail?: string;         // 展开后详细内容
  evidence?: {             // 证据（不暴露完整 portrait）
    type: 'chart' | 'conversation';
    snippet: string;       // 如 "日主=甲木" 或用户原话
  }[];
  actions: ('like' | 'share' | 'dive' | 'save')[];
  createdAt: string;
}
```

### 3.4 Identity Prism (三元身份视角) — P0 核心

> 用一个**极简交互**，一次性解决用户核心困惑：
> 「我内心是这样的，但别人觉得我是那样的」→ **人是多面的** → 我被理解/被允许/被赋能

#### 3.4.1 三段式文案结构

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   ○ Inner    ◉ Core    ○ Outer                 │
│   ═════════════●═══════════════                │
│                                                 │
│   你真正稳定的驱动力是                           │
│   ╭─────────────────────────────╮               │
│   │                             │               │
│   │     「追求深度理解」          │               │
│   │                             │               │
│   ╰─────────────────────────────╯               │
│                                                 │
│   你天生对表象不满足，总想探究事物               │
│   背后的本质。这让你在研究、分析、               │
│   策略制定方面有独特优势。                       │
│                                                 │
│   来源：日主甲木 · 偏印格                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

| 视角 | 含义 | 语气 |
|------|------|------|
| **Inner (阴)** | 内心最在意的 | 「在你心里，其实最在意的是…」 |
| **Core (本)** | 真正稳定的驱动力 | 「你真正稳定的驱动力是…」 |
| **Outer (阳)** | 给人的感觉 | 「你给人的感觉是…」 |

#### 3.4.2 放置策略（半常驻）

| 端侧 | 位置 | 形态 |
|------|------|------|
| PC | Insight Panel 顶部（第一屏可见） | 完整三档开关 |
| Mobile - Me Tab | 顶部常驻 | 完整三档开关 |
| Mobile - Chat | 空状态时展示预览卡，点击跳转 Me | 简化预览 |
| Chart/报告页 | 作为报告第一页 | 完整展示 |

#### 3.4.3 交互组件：TriToggle

三档物理开关，带「机械阻尼感」的 spring 动画：

```typescript
interface TriToggleProps {
  value: 'inner' | 'core' | 'outer';
  onChange: (value: 'inner' | 'core' | 'outer') => void;
  disabled?: boolean;
}

// 动效配置
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

#### 3.4.4 三 Skill 映射

**八字 (Bazi)**：
- `Inner`：日主（本我核心气质）→「你最自然的反应方式」
- `Core`：用神/喜忌 →「长期利益的方向盘」（现代语义，不堆术语）
- `Outer`：十神结构 →「社会角色策略」

**星座 (Zodiac)**：
- `Inner`：月亮星座
- `Core`：太阳星座
- `Outer`：上升星座（缺失时退化为双层，轻提示补充时辰可解锁）

**MBTI**：
- `Inner`：内在能量补给方式
- `Core`：主导功能/决策偏好
- `Outer`：对外互动策略

#### 3.4.5 禁用话术

**必须禁用**：
- 「你注定… / 你一定会… / 你逃不掉… / 这是命」
- 以恐惧驱动的句式：「不这样就会很惨/会出事/会破财」
- 情感操控式推销：「不买你就错过窗口期」

**改用**：
- 「更可能 / 更容易 / 在…情况下常见 / 可以尝试」

### 3.5 Relationship Simulator (关系模拟器) — P0+

> 杀手级引流功能：隐私友好 + 可分享 + 可行动

#### 3.5.1 主场景

**亲密关系**为主打（传播性最强、复访动机最强）

#### 3.5.2 双模式设计

**模式 1：传统输入（单人发起）**

```
┌─────────────────────────────────────┐
│  关系模拟器                      ✕  │
├─────────────────────────────────────┤
│                                     │
│  选择对方信息来源                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  📅 我知道 TA 的生日         │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │  ♈ 我只知道 TA 的星座        │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │  🧠 我知道 TA 的 MBTI        │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**模式 2：双用户隐私模式 (Vibe Link)**

```
发起者                              接收者
─────────                           ─────────
1. 选择披露级别
   ○ 最隐私（默认）
   ○ 展示基本标签
   ○ 完整披露

2. 生成邀请链接 ──────────────────→ 3. 点击链接

                                    4. 选择披露级别

                                    5. 确认参与

          ←────────────────────────

6. 双方各自看到「我该如何对待 TA」
   （底层信息不互相暴露）
```

**隐私边界**（默认最隐私）：
- 对方看不到：生日/时辰/地点/性别
- 也不展示：日主/上升/MBTI 类型等底层标签
- 只展示：合盘结果 + 行动建议

#### 3.5.3 输出形态：行动处方

```
┌─────────────────────────────────────┐
│  你们的关系诊断                      │
├─────────────────────────────────────┤
│                                     │
│  「你们是彼此的镜子，                │
│    但镜中的自己让你有点不安」        │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💬 下次可以这样说                   │
│  ┌─────────────────────────────┐    │
│  │ "我需要一点时间想清楚"       │ 📋 │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ "你说的我听到了，但..."      │ 📋 │
│  └─────────────────────────────┘    │
│                                     │
│  ⚠️ 注意点                          │
│  避免在 TA 情绪激动时讲道理          │
│                                     │
│  ┌──────────────────────────────┐   │
│  │       ↗ 分享关系卡           │   │
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

#### 3.5.4 可分享关系卡（引流核心）

**只包含**：
- 一句关系结论
- 「你们最适合的沟通方式」一句
- 一个「下次就用这句开场」模板

**明确不包含**：
- 生日、星座/类型、命盘字段等敏感信息

### 3.6 趋势系统 (Now/Next) — P0

#### 3.6.1 表达边界

**只给**：
- 阶段主题
- 风险/注意点
- 可做的事

**不做**：
- 不预测具体事件
- 不说「会发生什么」

#### 3.6.2 组件设计

**NowNextCard**：

```
┌─────────────────────────────────────┐
│  📍 当前阶段                        │
├─────────────────────────────────────┤
│  主题：沉淀与积累                    │
│                                     │
│  ⚠️ 注意：容易陷入细节，忘记大局     │
│                                     │
│  ✓ 可做：每周留出 2 小时做规划       │
├─────────────────────────────────────┤
│  ➡️ 下一阶段（3 月起）               │
│  主题：向外拓展                      │
└─────────────────────────────────────┘
```

**TodayOneStep**（嵌入 Daily Greeting）：

```
┌─────────────────────────────────────┐
│  🌅 早安                            │
│  今天立春，木气上升                  │
│                                     │
│  今日一步                           │
│  ┌─────────────────────────────┐    │
│  │ ☐ 拒绝一个不合理的请求       │    │
│  └─────────────────────────────┘    │
│                                     │
│  [加入 7 天计划]                    │
└─────────────────────────────────────┘
```

#### 3.6.3 三 Skill 差异化

| Skill | 周期表达 | 示例 |
|-------|----------|------|
| 八字 | 流月/节气/阶段主题 | 「本月官星透出，适合争取曝光」 |
| 星座 | 天象/周期 | 「水逆期向内梳理，不急于决策」 |
| MBTI | 成长焦点 | 「本周适合练习设定边界」 |

### 3.7 主动关怀：Daily Greeting — P0

**策略**：No Push，打开页面立即看到最新的

**触发频率**：
- 每日（基于当日节律）
- 节气/特殊天象
- 用户事件（生日等）

**展示位置**：
- 首页或 Chat 顶部
- 只呈现「最新一期」，历史不做强依赖

```
┌─────────────────────────────────────┐
│  🎋 小寒                            │
│  ───────────────────────────────    │
│  寒气渐盛，宜收敛精气。              │
│  今天适合处理需要耐心的事。          │
│                        [了解更多 →] │
└─────────────────────────────────────┘
```

---

## 4. PC 工作台：A2UI (Agent-Driven UI)

### 4.1 设计理念

Agent 控制 UI 状态，不只是文本生成。

### 4.2 协议设计 (Phase 1 粗粒度)

后端通过 SSE Data Stream 发送 `ui_directive`：

```typescript
interface UIDirective {
  view: 'default' | 'transit' | 'pattern' | 'relationship';
  focus?: string;  // 如 '2026' 或 'partner_1'
  highlight?: string[];  // 需要高亮的元素 ID
}

// 示例
{ "view": "transit", "focus": "2026-Q1" }
```

### 4.3 Insight Panel 视图

Phase 1 支持 3 个视图：

| 视图 | 内容 | 触发条件 |
|------|------|----------|
| `default` | Identity Prism + 当前运势 + 快捷操作 | 默认/空闲 |
| `transit` | 运势时间线 + 阶段详情 | 用户问趋势/Agent 主动 |
| `pattern` | 命盘/星盘结构图 + 解释 | 用户问「为什么」/证据 |

### 4.4 技术实现

```typescript
// Zustand store
interface InsightPanelStore {
  currentView: 'default' | 'transit' | 'pattern';
  viewData: Record<string, unknown>;
  setView: (view: string, data?: Record<string, unknown>) => void;
}

// SSE handler (Vercel AI SDK)
const { data } = useChat({
  onDataMessage: (directive: UIDirective) => {
    insightPanelStore.setView(directive.view, { focus: directive.focus });
  },
});
```

---

## 5. 渐进注册 (Progressive Disclosure)

### 5.1 原则

**不阻断首次价值**，只在「用户明确要拥有」时注册。

### 5.2 触发点

| 动作 | 是否触发注册 |
|------|--------------|
| 单纯聊天 | ❌ |
| 单次体验 (Guest) | ❌ |
| 保存洞察 | ✅ |
| 查看完整报告/命盘 | ✅ |
| 生成关系邀请链接 | ✅ |

### 5.3 登录方式优先级

| 阶段 | 方式 |
|------|------|
| P0 | 邮箱 + 手机 |
| P1 | 微信 |
| P2 | Google / Apple |

---

## 6. 技术规范

### 6.1 必选库

| 类别 | 库 | 理由 |
|------|-----|------|
| 框架 | Next.js 14 (App Router) | 已采用 |
| 状态管理 | Zustand | 轻量、与 React 18 兼容好 |
| 动效 | framer-motion | Spring physics、layoutId |
| Bottom Sheet | vaul | 移动端原生感、snap points |
| 样式 | Tailwind CSS | 已采用 |
| 图标 | lucide-react | 已采用 |

### 6.2 SSE 流式响应

所有 AI 响应使用 SSE 流式输出：

```typescript
// 前端
const { messages, isLoading } = useChat({
  api: '/api/v1/chat/stream',
  streamMode: 'stream-data',
});

// 后端
@app.post("/api/v1/chat/stream")
async def chat_stream(request: ChatRequest):
    async def generate():
        async for chunk in agent.stream(request.message):
            yield f"data: {json.dumps(chunk)}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")
```

### 6.3 响应式断点

```css
/* Tailwind 配置 */
screens: {
  'sm': '640px',   // 手机横屏
  'md': '768px',   // 平板
  'lg': '1024px',  // PC（洞察卡交互切换点）
  'xl': '1280px',  // 大屏 PC
}
```

### 6.4 性能预算

| 指标 | 目标 |
|------|------|
| FCP | < 1.5s |
| LCP | < 2.5s |
| TTI | < 3.5s |
| Bundle Size (首屏) | < 150KB gzipped |

---

## 7. 工程路线图 (4 周)

### Week 1：模板强一致 + 移动端框架

| 任务 | 交付物 |
|------|--------|
| 全站统一 Luminous Paper | 所有页面应用纸张纹理 + 色彩系统 |
| BottomNav 骨架 | Chat/Chart/Journey/Me 四 Tab 可切换 |
| Birth Input 胶囊打磨 | 可跳过字段 + 默认地点 + 包容性选项 |
| 推演过场 (bazi) | TransitionOverlay 组件 + 跳过按钮 |

### Week 2：洞察卡闭环 + Identity Prism

| 任务 | 交付物 |
|------|--------|
| 洞察卡 Bottom Sheet | vaul 集成 + 响应式 (PC: Side Panel) |
| 分享功能 | 复制文本（海报 Phase 2） |
| Like + 深入解读 | 正向反馈 + follow-up prompt 生成 |
| Identity Prism | TriToggle 组件 + 三 Skill 映射 + 半常驻放置 |

### Week 3：Chart/档案 + 趋势视图 + 续聊

| 任务 | 交付物 |
|------|--------|
| `/{skill}/chart` 页面 | 最小可用报告页 |
| Insight Panel 真实数据 | 接入后端摘要 API |
| 继续上次对话 | localStorage (Guest) + conversation_id (登录) |
| NowNextCard + TodayOneStep | 趋势组件 + 嵌入 Daily Greeting |

### Week 4：Relationship Simulator + 付费墙预留

| 任务 | 交付物 |
|------|--------|
| Daily Greeting 卡片 | 展示最新一期 + 节气/天象 |
| Relationship Simulator P0+ | 传统输入 + 双用户模式 + 可分享关系卡 |
| 订阅权益/付费墙 UI | UI 就绪，支付可 stub |
| A2UI 粗粒度切换 | 3 个视图切换 + ui_directive handler |

---

## 8. 埋点清单 (最少集)

### 8.1 引流相关

```
landing_view(skill)
insight_share_click(type)
insight_share_complete(type, method)
relationship_simulator_opened(skill, mode)
relationship_share_click
relationship_share_complete
```

### 8.2 激活相关

```
birth_submit(skill, has_hour, has_gender, has_location)
deduction_shown(skill, duration_ms)
deduction_skipped(skill, at_ms)
chart_generated(skill, success)
chat_first_message_sent(skill)
insight_shown(type)
insight_opened(type)
insight_like(type)
first_value_achieved(skill, path)
```

### 8.3 留存相关

```
identity_prism_viewed(skill, state)
identity_prism_toggled(skill, from, to)
resume_conversation(skill)
daily_greeting_viewed
today_one_step_completed
```

### 8.4 转化相关

```
register_prompt_shown(trigger)
register_complete(method)
paywall_shown(feature)
subscription_started(plan)
```

---

## 9. 非目标 (4 周内刻意不做)

- 系统级 Push 通知
- 完整跨技能洞察整合
- 完整历史体系（先做「继续上次对话」）
- 30 天长期计划（先做 7 天微行动）
- 海报生成（先做复制文本）
- 完整支付接入（先做 Stripe，微信/支付宝 Phase 2）

---

## 10. 后端协同要点

### 10.1 新增 API 需求

| API | 用途 | 优先级 |
|-----|------|--------|
| `GET /api/v1/identity-prism/{skill}` | 获取三元身份数据 | P0 |
| `POST /api/v1/relationship/create` | 创建关系模拟 | P0 |
| `GET /api/v1/relationship/{id}` | 获取关系结果 | P0 |
| `POST /api/v1/relationship/invite` | 生成邀请链接 | P0 |
| `POST /api/v1/relationship/accept` | 接受邀请 | P0 |
| `GET /api/v1/trend/now-next/{skill}` | 获取趋势数据 | P0 |
| `GET /api/v1/greeting/today` | 获取每日问候 | P0 |

### 10.2 数据结构新增

```python
# Identity Prism 响应
class IdentityPrismResponse(BaseModel):
    skill: str
    inner: PrismLayer
    core: PrismLayer
    outer: PrismLayer

class PrismLayer(BaseModel):
    keyword: str           # 关键词
    description: str       # 2-3 句描述
    evidence: list[Evidence]  # 证据列表

# Relationship 响应
class RelationshipResult(BaseModel):
    id: str
    diagnosis: str         # 一句话诊断
    communication_style: str
    action_scripts: list[str]  # 可复制的话术
    warning: str           # 注意点
    shareable_card: ShareableCard
```

---

## 附录 A：备选方案存档

### A.1 身份框架备选

#### 方案 B：二元 Mirror Toggle

Jungian 心理学的 Persona/Self 框架：

```
┌─────────────────────────────────────┐
│                                     │
│   ◉ Outer (面具)    ○ Inner (本我)  │
│   ═══●═════════════════════════════ │
│                                     │
│   你展现给世界的是                   │
│   「冷静可靠的执行者」               │
│                                     │
└─────────────────────────────────────┘
```

**未采用理由**：二元过于简化，难以表达东方命理的层次感。

### A.2 洞察卡交互备选

#### 方案 C：原地扩展

卡片在原位置 layout animation 放大到全屏。

```
初始态                    展开态
┌───────┐                ┌─────────────┐
│ 洞察  │  ───────────→  │             │
│ [展开]│                │   洞察详情   │
└───────┘                │             │
                         └─────────────┘
```

**未采用理由**：
- 实现复杂度较高
- 与 A2UI 右栏模式冲突
- 移动端全屏跳转体验不如 Bottom Sheet 自然

### A.3 趋势表达备选

#### 方案 B：允许轻度预测

可以说「本周合作机会较多」「水逆期向内梳理」。

**未采用理由**：边界难以把控，易滑向「贩卖焦虑」，Phase 1 保守起见不做。

### A.4 Relationship Simulator 备选

#### 轻量验证方案

只做关系入口 UI，后端逻辑放 Phase 2。

**未采用理由**：用户明确希望 4 周内上线含双用户模式的完整版。

---

## 附录 B：组件速查表

| 组件 | 文件位置 | 状态 |
|------|----------|------|
| LuminousPaper | `components/core/LuminousPaper.tsx` | ✅ 已有 |
| VibeGlyph | `components/core/VibeGlyph.tsx` | ✅ 已有 |
| BreathAura | `components/core/BreathAura.tsx` | ✅ 已有 |
| InsightCard | `components/insight/InsightCard.tsx` | ✅ 已有，需扩展 |
| InsightPanel | `components/insight/InsightPanel.tsx` | ✅ 已有，需扩展 |
| TransitionOverlay | `components/core/TransitionOverlay.tsx` | ❌ 待创建 |
| TriToggle | `components/ui/TriToggle.tsx` | ❌ 待创建 |
| IdentityPrism | `components/identity/IdentityPrism.tsx` | ❌ 待创建 |
| NowNextCard | `components/trend/NowNextCard.tsx` | ❌ 待创建 |
| TodayOneStep | `components/trend/TodayOneStep.tsx` | ❌ 待创建 |
| DailyGreeting | `components/greeting/DailyGreeting.tsx` | ❌ 待创建 |
| RelationshipSimulator | `components/relationship/Simulator.tsx` | ❌ 待创建 |
| RelationshipCard | `components/relationship/Card.tsx` | ❌ 待创建 |
| BottomSheet | `components/ui/BottomSheet.tsx` | ❌ 待创建 (vaul 封装) |
| SidePanel | `components/ui/SidePanel.tsx` | ❌ 待创建 |

---

## 附录 C：ASCII 交互参考

详见 `/docs/frontend-identity-demo.md`

---

> 本文档是 Phase 1 前端落地的唯一真理来源 (Source of Truth)。
> 如需修改优先级，请先改本文档，再改代码。
