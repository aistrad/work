# Fortune AI 前端统一与优化方案

> **角色定位**：作为 Notion UI/UX 总监，从系统设计层面统一 react_concept_design.md 的设计语言与现有 web-app 代码库

---

## 📊 现状分析

### 设计概念 (react_concept_design.md)
- ✅ Morandi/Notion Zen 美学方向正确
- ❌ 硬编码色值 (#F9F9F7, #37352F 等)
- ❌ 纯文本消息渲染，无 Block 结构
- ❌ Zone B 仅 lg 屏幕显示，移动端无替代入口
- ❌ 按钮无 focus ring、aria-label

### 实际代码库 (web-app)
- ✅ 已有 CSS 变量系统 (HSL 格式)
- ✅ Block-based 消息渲染架构
- ✅ 移动端底部 Tab 导航
- ⚠️ 部分组件仍有硬编码值
- ⚠️ A2UI → Commitment 闭环未完整
- ⚠️ 品牌视觉锚点不够突出

---

## 🔴 P0 - 体验断裂修复

### 1. 统一 Design Token 体系

**问题**：设计稿硬编码 `#F9F9F7/#37352F`，一旦接入多主题/Admin 端将分裂

**方案**：

```css
/* 语义化 Token 层 (globals.css 已有基础) */
:root {
  /* Surface 层级 */
  --surface-base: hsl(var(--background));
  --surface-subtle: hsl(var(--background-subtle));
  --surface-muted: hsl(var(--background-muted));
  --surface-elevated: hsl(var(--card));

  /* Text 层级 */
  --text-primary: hsl(var(--foreground));
  --text-secondary: hsl(var(--foreground-muted));
  --text-tertiary: hsl(var(--foreground-subtle));

  /* Interactive */
  --interactive-accent: hsl(var(--accent));
  --interactive-hover: hsl(var(--hover));
  --interactive-active: hsl(var(--active));
}
```

**组件改造示例**：
```tsx
// 🚫 Before (react_concept_design.md)
<button className="bg-[#37352F] text-[#F9F9F7]">

// ✅ After
<button className="bg-primary text-primary-foreground">
```

**文件改动**：
- [globals.css](web-app/src/app/globals.css) - 扩展语义 Token
- [tailwind.config.ts] - 确保 Token 映射
- 所有组件逐步迁移到语义 Token

---

### 2. CTA/可访问性语义强化

**问题**：SoulButton 无 focus ring，图标按钮无 aria-label

**方案**：

```tsx
// 创建 AccessibleButton 基础组件
const AccessibleButton = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ children, icon: Icon, ariaLabel, ...props }, ref) => (
    <button
      ref={ref}
      type="button"
      aria-label={ariaLabel}
      className={cn(
        "focus-visible:outline-none focus-visible:ring-2",
        "focus-visible:ring-accent focus-visible:ring-offset-2",
        "focus-visible:ring-offset-background",
        // ... 其他样式
      )}
      {...props}
    >
      {Icon && <Icon size={16} aria-hidden="true" />}
      {children}
    </button>
  )
);
```

**关键改动清单**：
- [ ] SoulButton 添加 `focus-visible:ring-*`
- [ ] 所有图标按钮添加 `aria-label`
- [ ] Omnibar 发送键添加 `type="submit"` 或 `type="button"`
- [ ] PromptCard 添加 `role="button"` + `tabIndex={0}` + `onKeyDown`

---

### 3. A2UI/工具结果承载架构

**问题**：消息只渲染纯文本，无法呈现"处方/证据/行动按钮/任务卡"

**方案**：利用现有 Block 系统扩展

```typescript
// 扩展 Block 类型定义
interface CommitmentBlock extends BaseBlock {
  type: 'commitment'
  action: 'start' | 'schedule' | 'opt_out'
  taskId: string
  taskTitle: string
  estimatedDuration?: string
  evidence?: string[]
}

interface PrescriptionBlock extends BaseBlock {
  type: 'prescription'
  title: string
  items: PrescriptionItem[]
  source: string // 证据来源
}
```

**新增组件**：
```
components/chat/blocks/
├── commitment-block.tsx   # 行动承诺卡片
├── prescription-block.tsx # 处方/建议卡片
├── evidence-block.tsx     # 证据引用块
└── task-action-block.tsx  # 任务操作按钮组
```

**联动机制**：
```typescript
// Commitment 完成后刷新 Zone B
const handleCommit = async (action: CommitmentAction) => {
  await api.commitTask(taskId, action);
  // 触发 Zone B 刷新
  window.dispatchEvent(new CustomEvent('refreshDashboard'));
  // 或通过 Zustand store 更新
  useAppStore.getState().refreshTasks();
}
```

---

### 4. 移动端策略补全

**问题**：Zone B 在 lg 才显示，移动端关键路径断裂

**方案**：移动端采用 Bottom Sheet + Tab 切换

```tsx
// 移动端 Zone B 入口策略

// A. 底部 Tab 已存在，强化内容
<MobileTabBar>
  <Tab icon={MessageSquare} label="对话" />
  <Tab icon={BarChart3} label="状态" badge={3} /> {/* 待办数 */}
  <Tab icon={Target} label="任务" />
  <Tab icon={Settings} label="设置" />
</MobileTabBar>

// B. 关键任务可从对话区直接访问
<FloatingActionButton
  icon={<CheckSquare />}
  onClick={() => openBottomSheet('tasks')}
  badge={pendingTasks.length}
/>

// C. AI 消息内的 Commitment 块直接可操作
<CommitmentBlock
  inlineAction={true} // 移动端内联显示操作按钮
/>
```

**实现要点**：
- 使用 Radix Dialog 作为 Bottom Sheet
- 手势支持：下滑关闭
- 状态同步：Sheet 内操作实时反映到 Tab 视图

---

## 🟡 P1 - 从"好看"到"好用"

### 5. 文案与语言一致性

**策略**：**默认中文 + 关键英文点缀**

| 场景 | 语言 | 示例 |
|------|------|------|
| 系统标题 | 英文 | Fortune AI, Soul OS |
| 功能入口 | 中文 | 每日塔罗, 成长日记 |
| AI 对话 | 中文 | 我理解你的感受... |
| 按钮标签 | 中文 | 发送, 开始, 查看详情 |
| 状态标签 | 英文缩写 | PERMA, Flow, Mind |

**改造示例**：
```tsx
// 🚫 Before
<h2>Good morning, Traveler. How is your soul aligned today?</h2>

// ✅ After
<h2>
  早安，旅行者
  <span className="text-muted">你的内心今天如何？</span>
</h2>
```

---

### 6. 字体分工规范

**策略**：Serif 仅用于标题/引言，正文用 Sans

```css
/* 字体使用规范 */
.heading-soul {
  font-family: var(--font-serif); /* Fraunces */
  font-weight: 600;
}

.body-text {
  font-family: var(--font-sans); /* Inter */
  font-weight: 400;
  line-height: 1.7;
}

.ai-message {
  font-family: var(--font-sans);
  /* Serif 仅用于引言块 */
}

.ai-message blockquote {
  font-family: var(--font-serif);
  font-style: italic;
}
```

**AI 消息排版规则**：
- 正文：Sans, 16px, 1.7 行高
- 标题：Serif, 加粗
- 引言块：Serif, 斜体, 左边框
- 列表：Sans, 圆点/数字
- 代码块：Mono, 背景色区分

---

### 7. Dashboard 从展示到闭环

**问题**：Radar 好看但缺"下一步"；任务状态不明确

**方案**：

```tsx
// A. PERMA 雷达图增强
<RadarChart data={permaData}>
  <TrendIndicator dimension="P" change={+0.5} />
  <ThresholdAlert dimension="A" message="成就感偏低，建议设置小目标" />
  <NextAction dimension="A" action="开始一个 15 分钟专注任务" />
</RadarChart>

// B. 任务状态机可视化
type TaskStatus = 'suggested' | 'active' | 'done' | 'skipped'

<TaskItem
  status={task.status}
  action={
    task.status === 'suggested' ? '接受' :
    task.status === 'active' ? '完成' : null
  }
/>

// C. 状态徽章
<StatusBadge status="suggested" /> // 待决定
<StatusBadge status="active" />    // 进行中
<StatusBadge status="done" />      // 已完成
<StatusBadge status="skipped" />   // 已跳过
```

---

## 🟢 P2 - 品牌记忆点

### 8. Orb/呼吸感作为跨页面母题

**策略**：将 Soul Orb 作为统一视觉锚点，贯穿所有页面

```tsx
// A. Header Mini Orb (状态指示器)
<HeaderOrb
  size="sm"
  status={currentEnergyLevel} // 'balanced' | 'low' | 'high'
  element={dominantElement}   // 'wood' | 'fire' | 'earth' | 'metal' | 'water'
/>

// B. Zone B 状态色联动
<DashboardZone
  accentColor={elementColors[dominantElement]}
  pulseIntensity={energyLevel}
/>

// C. 空态动效
<EmptyState>
  <OrbAnimation type="breathing" />
  <p>开始一段对话，探索内心宇宙</p>
</EmptyState>

// D. 加载态
<LoadingOrb pulsing={true} />
```

**五行色与状态绑定**：
| 元素 | 色值 | 状态含义 |
|------|------|----------|
| 木 | --wuxing-wood | 成长期 |
| 火 | --wuxing-fire | 活跃期 |
| 土 | --wuxing-earth | 稳定期 |
| 金 | --wuxing-metal | 收敛期 |
| 水 | --wuxing-water | 蓄势期 |

---

## 📁 关键文件清单

### 需修改
- [globals.css](web-app/src/app/globals.css) - Token 扩展
- [message-item.tsx](web-app/src/components/chat/message-item.tsx) - Block 渲染增强
- [blocks/index.tsx](web-app/src/components/chat/blocks/index.tsx) - 新增 Block 类型
- [dual-core-layout.tsx](web-app/src/components/layout/dual-core-layout.tsx) - 移动端策略
- [dashboard-zone.tsx](web-app/src/components/dashboard/dashboard-zone.tsx) - 闭环交互

### 需新增
- `components/ui/accessible-button.tsx` - 可访问按钮基础组件
- `components/chat/blocks/commitment-block.tsx` - 承诺行动块
- `components/chat/blocks/prescription-block.tsx` - 处方建议块
- `components/mobile/bottom-sheet.tsx` - 移动端抽屉
- `components/brand/orb-indicator.tsx` - 迷你 Orb 组件

---

## ⏱️ 优先级执行建议

```
Phase 1 (P0 - 基础体验)
├── Token 统一 → 解决分裂风险
├── 可访问性修复 → 键盘/读屏可用
├── 移动端 Zone B 入口 → 关键路径通畅
└── A2UI Block 基础架构

Phase 2 (P1 - 体验打磨)
├── 文案语言规范化
├── 字体分工实施
└── Dashboard 闭环交互

Phase 3 (P2 - 品牌强化)
└── Orb 母题系统化
```

---

## 🎯 设计原则总结

1. **Token First** - 所有颜色/间距/圆角使用语义化 Token，杜绝硬编码
2. **Accessibility by Default** - 每个交互元素都可键盘/读屏访问
3. **Mobile Complete** - 移动端不是桌面端的阉割版，而是完整体验的另一种形态
4. **Closed Loop** - 从对话 → 建议 → 承诺 → 执行 → 反馈的完整闭环
5. **Brand Anchor** - 用 Orb 作为品牌符号，而非"像 Notion"

---

## ✅ 决策确认

| 决策点 | 选择 | 影响 |
|--------|------|------|
| A2UI 后端 | **尚未定义** | 前端先设计理想 Block 结构，后端后续配合 |
| 移动端策略 | **底部 Tab 切换** | 沿用现有架构，强化 Tab 内容而非新增 Bottom Sheet |
| Admin 共用 | **暂不考虑** | Token 可独立演进，无需抽离公共包 |

---

## 🚀 实施 Checklist

### Phase 1: P0 基础修复
- [ ] 在 globals.css 新增语义化 Token 层 (surface-*, text-*, interactive-*)
- [ ] 迁移 react_concept_design.md 中的硬编码色值到 Token
- [ ] 为 SoulButton、PromptCard、Omnibar 添加 focus-visible 和 aria-label
- [ ] 在现有 blocks/index.tsx 新增 CommitmentBlock 和 PrescriptionBlock 类型
- [ ] 强化移动端底部 Tab 的状态/任务 Tab 内容

### Phase 2: P1 体验打磨
- [ ] 统一中英文案规范
- [ ] 实施字体分工 (Serif 标题 / Sans 正文)
- [ ] Dashboard 增加下一步建议、趋势指示、阈值提醒
- [ ] TaskItem 接入 Commitment 状态机

### Phase 3: P2 品牌强化
- [ ] 创建 OrbIndicator 组件
- [ ] Header 集成 Mini Orb 状态指示
- [ ] 空态/加载态使用 Orb 动效

---

*方案已确认，准备进入实施阶段。*
