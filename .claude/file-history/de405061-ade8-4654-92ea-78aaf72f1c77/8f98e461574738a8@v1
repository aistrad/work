# Journey Components Overview

Journey 页面组件架构，基于 Dan Koe 一日重置流程和4状态渐进系统。

## Component Architecture

```
apps/web/src/components/journey/
├── JourneyContent.tsx          # 主容器 - State 3 (executing)
├── JourneySkeleton.tsx         # 加载骨架屏
│
├── EmptyJourneyCard.tsx        # State 0 - 空白状态
├── NorthStarSetCard.tsx        # State 1 - 北极星已设
├── PlannedStateCard.tsx        # State 2 - 规划完成
│
├── NorthStarCard.tsx           # 北极星愿景卡片
├── YearlyGoalsCard.tsx         # 年度目标卡片
├── MonthlyBossCard.tsx         # 月度 Boss 卡片
├── WeeklyActionsCard.tsx       # 周大石头卡片
└── JourneyDailyLeversCard.tsx  # 每日杠杆卡片
```

## State-Driven Components

### State 0: EmptyJourneyCard

**用途**: 引导新用户开始设定人生愿景

**Props**: None

**功能**:
- 展示引导文案："还没有设定方向？"
- CTA 按钮："开始设计我的人生"
- 点击后跳转 Chat，触发 Dan Koe 反愿景协议

**示例**:
```typescript
import EmptyJourneyCard from '@/components/journey/EmptyJourneyCard';

<EmptyJourneyCard />
```

---

### State 1: NorthStarSetCard

**用途**: 用户已设定北极星，引导制定年度目标

**Props**:
```typescript
interface NorthStarSetCardProps {
  northStar?: NorthStar;
}
```

**功能**:
- 展示北极星愿景
- 引导制定路线图
- CTA: "继续设定目标 →"

**示例**:
```typescript
import NorthStarSetCard from '@/components/journey/NorthStarSetCard';

<NorthStarSetCard northStar={data?.north_star} />
```

---

### State 2: PlannedStateCard

**用途**: 用户已设定路线图，引导设定本周大石头

**Props**:
```typescript
interface PlannedStateCardProps {
  roadmap?: Roadmap;
}
```

**功能**:
- 展示北极星 + 年度目标
- 引导设定本周大石头
- CTA: "设定本周计划 →"

**示例**:
```typescript
import PlannedStateCard from '@/components/journey/PlannedStateCard';

<PlannedStateCard roadmap={data?.roadmap} />
```

---

### State 3: JourneyContent

**用途**: 完整执行仪表盘，用户进入日常使用状态

**Props**:
```typescript
interface JourneyContentProps {
  data: LifecoachSkillData;
}
```

**功能**:
- 展示完整的执行仪表盘
- 包含所有执行卡片（北极星、年度目标、月 Boss、周大石头、每日杠杆）
- 支持勾选完成、查看进度

**示例**:
```typescript
import JourneyContent from '@/components/journey/JourneyContent';

<JourneyContent data={data} />
```

## Functional Components

### NorthStarCard

**用途**: 展示北极星愿景和反愿景

**Props**:
```typescript
interface NorthStarCardProps {
  northStar: NorthStar;
  onEdit?: () => void;
}
```

**功能**:
- 展示愿景场景
- 可折叠展示反愿景
- 编辑按钮（可选）

**设计要点**:
- ⭐ 图标标识
- 愿景文字突出显示
- 反愿景折叠在底部（🔥 图标）

---

### YearlyGoalsCard

**用途**: 展示年度目标列表和进度

**Props**:
```typescript
interface YearlyGoalsCardProps {
  goals: YearlyGoal[];
  onEdit?: () => void;
}
```

**功能**:
- 展示 1-3 个年度目标
- 每个目标显示进度条
- 显示 Q1 聚焦项

**设计要点**:
- 🎯 图标标识
- 目标分类标签（career, health, relationship 等）
- 进度条可视化

---

### MonthlyBossCard

**用途**: 展示本月 Boss 战进度

**Props**:
```typescript
interface MonthlyBossCardProps {
  monthlyBoss: MonthlyBoss;
  onToggleMilestone?: (milestoneId: string) => void;
}
```

**功能**:
- 展示 Boss 名称和进度
- 里程碑列表（可勾选）
- 剩余天数倒计时

**设计要点**:
- 📊 图标标识
- 进度条 + 百分比
- 里程碑勾选框
- "X天剩余" 显示紧迫感

---

### WeeklyActionsCard

**用途**: 展示本周大石头（3-5件重要的事）

**Props**:
```typescript
interface WeeklyActionsCardProps {
  weekly: Weekly;
  onToggleAction?: (actionId: string) => void;
  onAddAction?: () => void;
}
```

**功能**:
- 展示本周大石头列表
- 勾选完成
- 显示完成进度（2/4）
- "+ 添加大石头" 按钮

**设计要点**:
- 🪨 图标标识
- 完成/未完成视觉区分
- 关联目标标签（右侧显示）

---

### JourneyDailyLeversCard

**用途**: 展示今日杠杆（1-3个高杠杆行动）

**Props**:
```typescript
interface JourneyDailyLeversCardProps {
  dailyLevers: DailyLevers;
  progress?: Progress;
  onToggleLever?: (leverId: string) => void;
  onCheckin?: () => void;
}
```

**功能**:
- 展示今日杠杆列表
- 勾选完成
- 显示连续天数（🔥 X天连续）
- "完成签到 ✓" 按钮

**设计要点**:
- ☀️ 图标标识
- 高亮未完成项
- 完成后显示打勾动画
- 全部完成时弹出庆祝卡

---

### JourneySkeleton

**用途**: 数据加载时的骨架屏

**Props**: None

**功能**:
- 展示加载状态
- 模拟真实布局

---

## Usage Example

### 完整的 Journey 页面

```typescript
"use client";

import { useJourneyData } from "@/hooks/useJourneyData";
import EmptyJourneyCard from "@/components/journey/EmptyJourneyCard";
import NorthStarSetCard from "@/components/journey/NorthStarSetCard";
import PlannedStateCard from "@/components/journey/PlannedStateCard";
import JourneyContent from "@/components/journey/JourneyContent";
import JourneySkeleton from "@/components/journey/JourneySkeleton";

export default function JourneyPage() {
  const { data, isLoading, journeyState } = useJourneyData();

  if (isLoading) {
    return <JourneySkeleton />;
  }

  switch (journeyState) {
    case "empty":
      return <EmptyJourneyCard />;

    case "north_star_set":
      return <NorthStarSetCard northStar={data?.north_star} />;

    case "planned":
      return <PlannedStateCard roadmap={data?.roadmap} />;

    case "executing":
      return <JourneyContent data={data!} />;

    default:
      return <EmptyJourneyCard />;
  }
}
```

### 单独使用某个卡片

```typescript
import MonthlyBossCard from "@/components/journey/MonthlyBossCard";
import { useJourneyData } from "@/hooks/useJourneyData";

function DashboardOverview() {
  const { monthlyBoss, toggleMilestone } = useJourneyData();

  if (!monthlyBoss) return null;

  return (
    <MonthlyBossCard
      monthlyBoss={monthlyBoss}
      onToggleMilestone={toggleMilestone}
    />
  );
}
```

## Component Design Patterns

### 1. Chat-First Pattern

所有深度交互（编辑、设定）都引导回 Chat：

```typescript
// EmptyJourneyCard.tsx
const handleStart = () => {
  router.push('/chat?action=start-journey');
};

// NorthStarCard.tsx
const handleEdit = () => {
  router.push('/chat?action=edit-vision');
};
```

### 2. Optimistic Updates

所有勾选操作都使用乐观更新：

```typescript
const handleToggle = async (id: string) => {
  try {
    await onToggleLever?.(id);  // 内部实现乐观更新
    // UI 立即响应
  } catch (error) {
    toast.error("操作失败");
    // Hook 内部会回滚
  }
};
```

### 3. Progressive Disclosure

渐进式展示，避免信息过载：

```typescript
// 默认收起反愿景
const [showAntiVision, setShowAntiVision] = useState(false);

<div onClick={() => setShowAntiVision(!showAntiVision)}>
  🔥 反愿景 {showAntiVision ? '▲' : '▼'}
</div>
{showAntiVision && <div>{northStar.anti_vision_scene}</div>}
```

### 4. Celebration Moments

完成任务时的微动效：

```typescript
const handleComplete = async (id: string) => {
  await onToggleLever?.(id);

  // 触发庆祝动效
  confetti({
    particleCount: 100,
    spread: 70,
    origin: { y: 0.6 }
  });

  // 检查是否全部完成
  if (isAllCompleted) {
    showCelebrationModal();
  }
};
```

## Mobile Adaptations

### 优先级排序

Mobile 上优先展示高频操作：

```typescript
// Mobile Layout
<div className="space-y-4">
  <JourneyDailyLeversCard />  {/* 1. 今日杠杆（最高频） */}
  <WeeklyActionsCard />       {/* 2. 本周大石头 */}
  <MonthlyBossCard />         {/* 3. 月度 Boss */}
  <YearlyGoalsCard />         {/* 4. 年度目标 */}
  <NorthStarCard />           {/* 5. 北极星（最低频） */}
</div>
```

### 区块收起

默认只展开今日杠杆：

```typescript
const [expandedCards, setExpandedCards] = useState(["daily"]);

<WeeklyActionsCard
  isExpanded={expandedCards.includes("weekly")}
  onToggleExpand={() => toggleCard("weekly")}
/>
```

## Styling Guidelines

### 视觉层级

```
1. 北极星：最醒目，使用大字体 + ⭐ 图标
2. 今日杠杆：次醒目，高亮未完成项
3. 周大石头：标准卡片
4. 月度/年度：折叠或灰度显示
```

### 图标系统

```
⭐ - 北极星
🔥 - 反愿景 / 连续天数
🎯 - 年度目标
📊 - 月度 Boss
🪨 - 周大石头
☀️ - 每日杠杆
✓ - 完成
○ - 未完成
```

### 进度条样式

```typescript
// 不同状态不同颜色
const progressColor = progress >= 80 ? 'green' : progress >= 50 ? 'yellow' : 'red';

<ProgressBar value={progress} color={progressColor} />
```

## Accessibility

1. **Keyboard Navigation**: 所有勾选框支持键盘操作
2. **Screen Reader**: 使用语义化 HTML 和 ARIA 标签
3. **Focus Management**: 编辑后焦点返回原位置
4. **High Contrast**: 支持高对比度模式

## Performance

1. **Lazy Loading**: 大卡片内容懒加载
2. **Memo**: 使用 `React.memo` 避免不必要的重渲染
3. **Virtual Lists**: 如果目标/任务过多，使用虚拟列表
4. **Optimistic Updates**: 减少等待时间

## Related Files

- **Components**: `/apps/web/src/components/journey/`
- **Hook**: `/apps/web/src/hooks/useJourneyData.ts`
- **Types**: `/apps/web/src/types/journey.ts`
- **Design Spec**: `@vibelife/docs/components/journey/journey-design.md`
