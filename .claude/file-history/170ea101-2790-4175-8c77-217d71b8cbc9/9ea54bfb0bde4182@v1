# 新增组件详解

> **组件版本**: V9.0
> **创建日期**: 2026-01-21

---

## 📦 组件列表

本次 Dashboard → Chat 整合新增了 3 个核心组件：

1. **AmbientStatusBar** - 简化版状态条
2. **LifecoachQuickView** - 可展开 Lifecoach 卡片
3. **ChatEmptyStateWithDashboard** - 整合容器

---

## 1. AmbientStatusBar

### 📝 组件说明

**文件路径**: `apps/web/src/components/chat/AmbientStatusBar.tsx`

**功能**: 横向展示用户状态指标（连续天数、能量、签到状态），提供快速签到入口

**设计理念**:
- 简化 Dashboard 的 Ambient 层，移除重复的问候和名言
- 聚焦核心指标，紧凑展示
- 一键签到，即时反馈

---

### 🎨 视觉效果

```
┌───────────────────────────────────────────────────────┐
│  🔥🔥 2天连续 | 💪 能量 75% | □ 未签到  [开始今天]  │
└───────────────────────────────────────────────────────┘
```

**已签到状态**:
```
┌───────────────────────────────────────────────────────┐
│  🔥🔥🔥 7天连续 | 💪 能量 82% | ✓ 已签到              │
└───────────────────────────────────────────────────────┘
```

---

### 🔧 Props 定义

```typescript
interface AmbientStatusBarProps {
  /** 状态数据 */
  status: StatusData;

  /** 签到回调 */
  onCheckIn: () => Promise<unknown>;

  /** 自定义样式 */
  className?: string;
}

interface StatusData {
  /** 连续签到天数 */
  streak: number;

  /** 今日是否已签到 */
  checkedIn: boolean;

  /** 能量值（可选，0-100） */
  energy?: number;
}
```

---

### ⚙️ 使用示例

```typescript
import { AmbientStatusBar } from "@/components/chat/AmbientStatusBar";

function MyComponent() {
  const handleCheckIn = async () => {
    await apiClient.post("/dashboard/checkin");
    toast.success("签到成功！");
  };

  return (
    <AmbientStatusBar
      status={{
        streak: 7,
        checkedIn: false,
        energy: 75,
      }}
      onCheckIn={handleCheckIn}
      className="w-full"
    />
  );
}
```

---

### 🎯 核心特性

#### 1. 火焰数量动态显示
根据连续天数显示不同数量的火焰：

| 连续天数 | 火焰数量 | 示例 |
|---------|---------|------|
| < 3 天 | 1 个 | 🔥 |
| 3-6 天 | 2 个 | 🔥🔥 |
| 7-13 天 | 3 个 | 🔥🔥🔥 |
| 14-29 天 | 4 个 | 🔥🔥🔥🔥 |
| ≥ 30 天 | 5 个 | 🔥🔥🔥🔥🔥 |

**实现代码**:
```typescript
const getFlameCount = (days: number) => {
  if (days >= 30) return 5;
  if (days >= 14) return 4;
  if (days >= 7) return 3;
  if (days >= 3) return 2;
  return 1;
};

const flames = "🔥".repeat(getFlameCount(streak));
```

---

#### 2. 签到按钮状态管理
**未签到时**: 显示"开始今天"按钮
**签到中**: 显示"签到中..."，按钮禁用
**已签到**: 按钮隐藏，显示"✓ 已签到"

**实现代码**:
```typescript
const [isCheckingIn, setIsCheckingIn] = useState(false);

const handleCheckIn = useCallback(async () => {
  if (status.checkedIn || isCheckingIn) return;

  setIsCheckingIn(true);
  try {
    await onCheckIn();
  } finally {
    setIsCheckingIn(false);
  }
}, [onCheckIn, status.checkedIn, isCheckingIn]);
```

---

#### 3. 能量值可选显示
如果 `energy` 为 `undefined`，则不显示能量指标

```typescript
{energy !== undefined && (
  <div className="flex items-center gap-1.5">
    <span className="text-lg">💪</span>
    <span className="text-sm font-medium">能量 {energy}%</span>
  </div>
)}
```

---

### 🎨 样式系统

使用 CSS 变量保持设计系统一致：

```typescript
style={{
  background: 'var(--bg-card)',
  border: '1px solid var(--border-subtle)',
}}
```

**颜色映射**:
- 文本: `var(--text-secondary)` / `var(--text-tertiary)`
- 成功色: `var(--color-success)`（已签到）
- 禁用色: `var(--text-disabled)`（未签到）
- 按钮渐变: `var(--accent-primary)` → `var(--accent-secondary)`

---

### 📱 响应式设计

**PC 端**:
- 左右布局，签到按钮右对齐
- 指标项间距 `gap-6`

**移动端**:
- 可能需要调整间距为 `gap-3`
- 签到按钮适配小屏幕

---

### ♿ 无障碍支持

- ✅ 按钮有明确 `disabled` 状态
- ✅ 颜色对比度符合 WCAG AA 标准
- ✅ 图标 + 文字双重提示

---

### 🐛 常见问题

**Q1: 签到后连续天数未更新？**
A: 确保 `onCheckIn` 成功后重新获取 Dashboard 数据：
```typescript
const handleCheckIn = async () => {
  await checkInApi();
  await refetchDashboard();  // ← 重新获取数据
};
```

**Q2: 火焰数量显示错误？**
A: 检查 `streak` 值是否正确传递，确保是数字类型

---

## 2. LifecoachQuickView

### 📝 组件说明

**文件路径**: `apps/web/src/components/chat/LifecoachQuickView.tsx`

**功能**: 可展开/收起的 Lifecoach 卡片，折叠时显示摘要，展开时显示完整内容

**设计理念**:
- 折叠状态：快速浏览关键指标
- 展开状态：深度查看和操作
- 原地切换：保持上下文连贯

---

### 🎨 视觉效果

**折叠状态**:
```
┌───────────────────────────────────────────────────────┐
│  🧭 LIFECOACH                                      ▼  │
│  ⭐ 成为更好的自己 | 📊 月度 60% | ☀️ 杠杆 2/3 | ... │
└───────────────────────────────────────────────────────┘
```

**展开状态**:
```
┌───────────────────────────────────────────────────────┐
│  🧭 LIFECOACH                                      ▲  │
│                                                        │
│  ⭐ 北极星：成为更好的自己                             │
│                                                        │
│  📊 月度项目：健康计划                                 │
│  ━━━━━━━━━━━━━━━━ 60%                                 │
│  剩余 10 天                                            │
│                                                        │
│  ☀️ 今日杠杆                                           │
│  □ 晨间冥想                                            │
│  ✓ 阅读30分钟                                          │
│  □ 运动1小时                                           │
│                                                        │
│  📅 本周大石头                                         │
│  ✓ 完成项目提案 (work)                                 │
│  □ 学习新技能 (growth)                                 │
└───────────────────────────────────────────────────────┘
```

---

### 🔧 Props 定义

```typescript
interface LifecoachQuickViewProps {
  /** Lifecoach 数据 */
  data: LifecoachData;

  /** 杠杆打勾回调 */
  onToggleLever: (leverId: string) => Promise<void>;

  /** 大石头打勾回调 */
  onToggleRock: (rockId: string) => Promise<void>;

  /** 北极星点击回调（可选） */
  onClickNorthStar?: () => void;

  /** 自定义样式 */
  className?: string;
}

interface LifecoachData {
  /** 北极星愿景 */
  northStar?: string;

  /** 月度项目 */
  monthlyProject?: {
    name: string;
    progress: number;      // 0-100
    daysRemaining: number;
  };

  /** 今日杠杆 */
  todayLevers: LeverItem[];

  /** 本周大石头 */
  weekRocks: RockItem[];
}

interface LeverItem {
  id: string;
  text: string;
  completed: boolean;
}

interface RockItem {
  id: string;
  text: string;
  role: string;  // work, growth, health, etc.
  completed: boolean;
}
```

---

### ⚙️ 使用示例

```typescript
import { LifecoachQuickView } from "@/components/chat/LifecoachQuickView";

function MyComponent() {
  const handleToggleLever = async (leverId: string) => {
    await apiClient.patch(`/dashboard/lever/${leverId}`);
    await refetchDashboard();
  };

  const handleToggleRock = async (rockId: string) => {
    await apiClient.patch(`/dashboard/rock/${rockId}`);
    await refetchDashboard();
  };

  const handleNorthStarClick = () => {
    console.log("查看北极星详情");
  };

  return (
    <LifecoachQuickView
      data={{
        northStar: "成为更好的自己",
        monthlyProject: {
          name: "健康计划",
          progress: 60,
          daysRemaining: 10,
        },
        todayLevers: [
          { id: "1", text: "晨间冥想", completed: false },
          { id: "2", text: "阅读30分钟", completed: true },
        ],
        weekRocks: [
          { id: "1", text: "完成项目提案", role: "work", completed: true },
        ],
      }}
      onToggleLever={handleToggleLever}
      onToggleRock={handleToggleRock}
      onClickNorthStar={handleNorthStarClick}
      className="w-full"
    />
  );
}
```

---

### 🎯 核心特性

#### 1. 状态切换
使用 `useState` 管理展开/收起状态：

```typescript
const [isExpanded, setIsExpanded] = useState(false);
```

**折叠 → 展开**: 点击整个卡片
**展开 → 折叠**: 点击右上角 `▲` 按钮

---

#### 2. 完整卡片复用
展开状态复用 `LifecoachCard` 组件：

```typescript
if (isExpanded) {
  return (
    <div className="relative">
      <button onClick={() => setIsExpanded(false)} className="absolute top-4 right-4 z-10">
        <ChevronUp />
      </button>
      <LifecoachCard
        data={data}
        onToggleLever={onToggleLever}
        onToggleRock={onToggleRock}
        onClickNorthStar={onClickNorthStar}
      />
    </div>
  );
}
```

---

#### 3. 摘要计算
折叠状态动态计算完成进度：

```typescript
const completedLevers = data.todayLevers.filter((l) => l.completed).length;
const completedRocks = data.weekRocks.filter((r) => r.completed).length;
const monthlyProgress = data.monthlyProject?.progress || 0;
```

---

#### 4. 响应式摘要
摘要文字过长时自动截断：

```typescript
<span className="truncate max-w-[200px]">
  {data.northStar}
</span>
```

---

### 🎨 样式系统

**折叠状态**:
- 背景: `var(--bg-card)`
- 边框: `var(--border-subtle)`
- Hover: `hover:shadow-md`（提示可点击）

**展开状态**:
- 相对定位: `position: relative`
- 收起按钮: `absolute top-4 right-4`
- Z-index: `z-10`（确保按钮在最上层）

---

### 📱 响应式设计

**PC 端**:
- 摘要横向排列: `flex flex-wrap gap-x-4`
- 最大宽度无限制

**移动端**:
- 摘要自动换行
- 指标项间距调整为 `gap-x-2`
- 北极星文字截断宽度调整

---

### ♿ 无障碍支持

- ✅ 按钮有明确 `aria-label`
- ✅ 展开/收起有视觉反馈（图标 ▼/▲）
- ✅ 可键盘操作（Enter/Space）

---

### 🐛 常见问题

**Q1: 展开后点击卡片内容会收起？**
A: 确保收起按钮使用绝对定位，不与卡片内容重叠

**Q2: 摘要文字被截断看不全？**
A: 调整 `max-w-[200px]` 或使用 tooltip 显示完整文字

**Q3: 打勾后状态未更新？**
A: 确保 `onToggleLever` 成功后重新获取数据

---

## 3. ChatEmptyStateWithDashboard

### 📝 组件说明

**文件路径**: `apps/web/src/components/chat/ChatEmptyStateWithDashboard.tsx`

**功能**: Chat 空状态容器，整合所有 Dashboard 组件

**设计理念**:
- 垂直布局，居中显示
- 组件顺序：DailyGreeting → VibeGlyph → AmbientStatusBar → LifecoachQuickView → MySkillsCarousel
- 响应式适配，移动端友好

---

### 🎨 视觉效果

```
┌─────────────────────────────────────────┐
│            [DailyGreeting]               │
│  问候、日期、节气、运势、今日一步       │
│                                          │
│            [VibeGlyph]                   │
│  呼吸光晕 + 脉冲环                       │
│                                          │
│          [AmbientStatusBar]              │
│  连续天数 | 能量 | 签到                  │
│                                          │
│         [LifecoachQuickView]             │
│  北极星 | 月度 | 杠杆 | 大石头           │
│                                          │
│          [MySkillsCarousel]              │
│  Skills 横滑卡片                         │
└─────────────────────────────────────────┘
```

---

### 🔧 Props 定义

```typescript
interface ChatEmptyStateWithDashboardProps {
  /** 当前 Skill */
  skill: SkillType;

  /** Dashboard 数据 */
  dashboardData?: DashboardDTO | null;

  /** 加载状态 */
  isDashboardLoading?: boolean;

  /** 快速 Prompt 回调 */
  onQuickPrompt?: (prompt: string) => void;

  /** 签到回调 */
  onCheckIn: () => Promise<void>;

  /** 杠杆打勾回调 */
  onToggleLever: (leverId: string) => Promise<void>;

  /** 大石头打勾回调 */
  onToggleRock: (rockId: string) => Promise<void>;

  /** DailyGreeting 数据 */
  dailyGreeting: DailyGreetingData;

  /** 自定义样式 */
  className?: string;
}
```

---

### ⚙️ 使用示例

```typescript
import { ChatEmptyStateWithDashboard } from "@/components/chat/ChatEmptyStateWithDashboard";

function ChatContainer() {
  const { dashboard, isLoading, checkIn, toggleLever, toggleRock } = useDashboard();
  const dailyData = useDailyGreeting(skill);

  const handleQuickPrompt = (prompt: string) => {
    sendMessage(prompt);
  };

  return (
    <div className="h-full">
      {messages.length === 0 ? (
        <ChatEmptyStateWithDashboard
          skill="bazi"
          dashboardData={dashboard}
          isDashboardLoading={isLoading}
          onQuickPrompt={handleQuickPrompt}
          onCheckIn={checkIn}
          onToggleLever={toggleLever}
          onToggleRock={toggleRock}
          dailyGreeting={{
            greeting: dailyData.greeting,
            solarTerm: dailyData.solarTerm,
            // ... 其他字段
          }}
        />
      ) : (
        <MessageList messages={messages} />
      )}
    </div>
  );
}
```

---

### 🎯 核心特性

#### 1. Skills 卡片点击映射
点击 Skills 卡片自动发送预设 prompt：

```typescript
const handleSkillCardClick = useCallback(
  (skillId: string) => {
    const promptMap: Record<string, string> = {
      bazi: "帮我看看今日运势",
      zodiac: "查看我的星盘运势",
      tarot: "帮我抽一张塔罗牌",
      career: "分析我的职业发展",
      lifecoach: "查看我的人生仪表盘",
    };
    const prompt = promptMap[skillId] || `切换到 ${skillId}`;
    onQuickPrompt?.(prompt);
  },
  [onQuickPrompt]
);
```

---

#### 2. 加载状态处理
Dashboard 数据加载时显示骨架屏：

```typescript
{isDashboardLoading ? (
  <DashboardLoadingSkeleton />
) : dashboardData ? (
  <DashboardComponents />
) : null}
```

**骨架屏组件**:
```typescript
function DashboardLoadingSkeleton() {
  return (
    <div className="w-full space-y-4">
      <Skeleton className="h-16 w-full rounded-lg" />
      <Skeleton className="h-24 w-full rounded-lg" />
      <Skeleton className="h-32 w-full rounded-lg" />
    </div>
  );
}
```

---

#### 3. VibeGlyph 动效
居中显示 VibeGlyph，带脉冲环和呼吸光晕：

```typescript
<div className="relative flex items-center justify-center">
  {/* 脉冲环 */}
  <div className="absolute w-16 h-16 rounded-full border border-skill-primary/20 animate-pulse-slow" />
  <div className="absolute w-24 h-24 rounded-full border border-skill-primary/10 animate-pulse-slower" />

  {/* 呼吸光晕 */}
  <BreathAura skill={skill} size="sm" position="center" intensity="medium" className="opacity-40" />

  {/* 中心图标 */}
  <VibeGlyph size="sm" skill={skill} showAura={true} animate={true} className="relative z-10" />
</div>
```

---

#### 4. 条件渲染
仅当有 Skills 数据时显示横滑卡片：

```typescript
{dashboardData.mySkills && dashboardData.mySkills.length > 0 && (
  <div className="w-full">
    <h3 className="text-sm font-semibold mb-3">我的 Skills</h3>
    <SkillCarousel skills={dashboardData.mySkills} onCardClick={handleSkillCardClick} />
  </div>
)}
```

---

### 🎨 样式系统

**容器布局**:
```typescript
className="flex flex-col items-center w-full md:max-w-xl mx-auto px-4 py-6 space-y-6"
```

- `flex flex-col`: 垂直布局
- `items-center`: 水平居中
- `md:max-w-xl`: PC 端最大宽度 672px
- `mx-auto`: 左右居中
- `space-y-6`: 组件间距 24px

---

### 📱 响应式设计

**PC 端** (≥768px):
- 最大宽度: `672px`
- 组件间距: `24px`
- 水平内边距: `16px`

**移动端** (<768px):
- 全宽显示
- 组件间距: `24px`（保持不变）
- 水平内边距: `16px`

---

### ♿ 无障碍支持

- ✅ 语义化 HTML 结构
- ✅ 标题层级正确（h3）
- ✅ 颜色对比度符合标准
- ✅ 可键盘导航

---

### 🐛 常见问题

**Q1: Dashboard 数据未显示？**
A: 检查 `dashboardData` 是否正确传递，确保不是 `null` 或 `undefined`

**Q2: Skills 卡片点击无反应？**
A: 确保 `onQuickPrompt` 回调已正确传递

**Q3: 组件间距过大？**
A: 调整 `space-y-6` 为更小的值（如 `space-y-4`）

---

## 📊 组件对比

| 特性 | AmbientStatusBar | LifecoachQuickView | ChatEmptyStateWithDashboard |
|------|-----------------|--------------------|-----------------------------|
| **用途** | 状态展示 + 签到 | Lifecoach 摘要 + 详情 | 整合容器 |
| **交互** | 签到按钮 | 展开/收起 + 打勾 | Skills 点击 |
| **状态** | 简单 | 双状态切换 | 复杂（子组件聚合） |
| **数据依赖** | StatusData | LifecoachData | DashboardDTO + DailyGreeting |
| **复杂度** | 低 | 中 | 高 |

---

## 🔗 组件关系图

```
ChatEmptyStateWithDashboard (容器)
├─ DailyGreeting (保留原组件)
├─ VibeGlyph (保留原组件)
├─ AmbientStatusBar (新组件)
│  └─ 使用 StatusData
├─ LifecoachQuickView (新组件)
│  ├─ 折叠状态: 自定义摘要
│  └─ 展开状态: 复用 LifecoachCard
└─ MySkillsCarousel (复用 Dashboard 组件)
   └─ 点击发送预设 prompt
```

---

## 🛠️ 维护建议

### 添加新组件
1. 在 `ChatEmptyStateWithDashboard` 中添加渲染逻辑
2. 更新 `DashboardDTO` 类型定义
3. 传递必要的 props 和回调

### 修改交互
1. 在对应组件中修改回调逻辑
2. 更新父组件的 prop 传递
3. 更新文档和测试用例

### 性能优化
1. 使用 `memo` 包裹组件
2. 使用 `useCallback` 缓存回调
3. 使用 `useMemo` 缓存计算值

---

**组件文档完成**

维护者: Claude Sonnet 4.5
创建日期: 2026-01-21
