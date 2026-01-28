# Dashboard → Chat 整合实施指南

> **面向读者**: 开发者
> **难度**: 中级
> **预计时间**: 2-3 小时

---

## 📋 实施步骤

### Phase 1: 创建新组件（1-1.5 小时）

#### Step 1.1: 创建 AmbientStatusBar

**文件**: `apps/web/src/components/chat/AmbientStatusBar.tsx`

```typescript
"use client";

import { useState, useCallback } from "react";
import { cn } from "@/lib/utils";
import type { StatusData } from "@/types/dashboard";

interface AmbientStatusBarProps {
  status: StatusData;
  onCheckIn: () => Promise<unknown>;
  className?: string;
}

export function AmbientStatusBar({
  status,
  onCheckIn,
  className,
}: AmbientStatusBarProps) {
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

  const { streak, checkedIn, energy } = status;

  // 根据连续天数显示火焰数量
  const getFlameCount = (days: number) => {
    if (days >= 30) return 5;
    if (days >= 14) return 4;
    if (days >= 7) return 3;
    if (days >= 3) return 2;
    return 1;
  };

  const flames = "🔥".repeat(getFlameCount(streak));

  return (
    <div className={cn("flex items-center justify-between px-4 py-3 rounded-lg", className)}
      style={{ background: 'var(--bg-card)', border: '1px solid var(--border-subtle)' }}>

      {/* 左侧：状态指标 */}
      <div className="flex items-center gap-6">
        {/* Streak */}
        <div className="flex items-center gap-1.5">
          <span className="text-lg">{flames}</span>
          <span className="text-sm font-medium" style={{ color: 'var(--text-secondary)' }}>
            {streak}天连续
          </span>
        </div>

        {/* Energy */}
        {energy !== undefined && (
          <div className="flex items-center gap-1.5">
            <span className="text-lg">💪</span>
            <span className="text-sm font-medium" style={{ color: 'var(--text-secondary)' }}>
              能量 {energy}%
            </span>
          </div>
        )}

        {/* Checked In Status */}
        <div className="flex items-center gap-1.5">
          <span style={{ color: checkedIn ? 'var(--color-success)' : 'var(--text-disabled)' }}>
            {checkedIn ? "✓" : "□"}
          </span>
          <span className="text-sm font-medium"
            style={{ color: checkedIn ? 'var(--color-success)' : 'var(--text-tertiary)' }}>
            {checkedIn ? "已签到" : "未签到"}
          </span>
        </div>
      </div>

      {/* 右侧：签到按钮 */}
      {!checkedIn && (
        <button onClick={handleCheckIn} disabled={isCheckingIn}
          className="px-4 py-1.5 rounded-lg text-sm font-medium text-white disabled:opacity-50 disabled:cursor-not-allowed transition-all hover:scale-105"
          style={{
            background: 'linear-gradient(135deg, var(--accent-primary) 0%, var(--accent-secondary) 100%)',
            boxShadow: 'var(--shadow-soft)',
          }}>
          {isCheckingIn ? "签到中..." : "开始今天"}
        </button>
      )}
    </div>
  );
}
```

**关键点**:
- ✅ 使用 CSS 变量保持设计系统一致
- ✅ 火焰数量根据连续天数动态显示
- ✅ 签到按钮仅在未签到时显示
- ✅ 防抖处理避免重复点击

---

#### Step 1.2: 创建 LifecoachQuickView

**文件**: `apps/web/src/components/chat/LifecoachQuickView.tsx`

```typescript
"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import type { LifecoachData } from "@/types/dashboard";
import { LifecoachCard } from "@/components/dashboard/lifecoach/LifecoachCard";
import { ChevronDown, ChevronUp } from "lucide-react";

interface LifecoachQuickViewProps {
  data: LifecoachData;
  onToggleLever: (leverId: string) => Promise<void>;
  onToggleRock: (rockId: string) => Promise<void>;
  onClickNorthStar?: () => void;
  className?: string;
}

export function LifecoachQuickView({
  data,
  onToggleLever,
  onToggleRock,
  onClickNorthStar,
  className,
}: LifecoachQuickViewProps) {
  const [isExpanded, setIsExpanded] = useState(false);

  const completedLevers = data.todayLevers.filter((l) => l.completed).length;
  const completedRocks = data.weekRocks.filter((r) => r.completed).length;
  const monthlyProgress = data.monthlyProject?.progress || 0;

  // 展开状态：显示完整卡片
  if (isExpanded) {
    return (
      <div className={cn("relative", className)}>
        <button onClick={() => setIsExpanded(false)}
          className="absolute top-4 right-4 z-10 p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
          aria-label="收起">
          <ChevronUp className="w-5 h-5" style={{ color: 'var(--text-tertiary)' }} />
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

  // 折叠状态：显示摘要
  return (
    <button onClick={() => setIsExpanded(true)}
      className={cn("w-full text-left p-4 rounded-lg transition-all hover:shadow-md", className)}
      style={{ background: 'var(--bg-card)', border: '1px solid var(--border-subtle)' }}>

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-xl">🧭</span>
          <span className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
            LIFECOACH
          </span>
        </div>
        <ChevronDown className="w-5 h-5" style={{ color: 'var(--text-tertiary)' }} />
      </div>

      {/* 关键指标摘要 */}
      <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
        {/* 北极星 */}
        {data.northStar && (
          <div className="flex items-center gap-1.5">
            <span>⭐</span>
            <span style={{ color: 'var(--text-secondary)' }} className="truncate max-w-[200px]">
              {data.northStar}
            </span>
          </div>
        )}

        {/* 月度进度 */}
        {data.monthlyProject && (
          <div className="flex items-center gap-1.5">
            <span>📊</span>
            <span style={{ color: 'var(--text-secondary)' }}>月度 {monthlyProgress}%</span>
          </div>
        )}

        {/* 今日杠杆 */}
        <div className="flex items-center gap-1.5">
          <span>☀️</span>
          <span style={{ color: 'var(--text-secondary)' }}>
            杠杆 {completedLevers}/{data.todayLevers.length}
          </span>
        </div>

        {/* 本周大石头 */}
        <div className="flex items-center gap-1.5">
          <span>📅</span>
          <span style={{ color: 'var(--text-secondary)' }}>
            大石头 {completedRocks}/{data.weekRocks.length}
          </span>
        </div>
      </div>
    </button>
  );
}
```

**关键点**:
- ✅ 两种状态：折叠（摘要）和展开（完整）
- ✅ 点击原地切换，保持上下文
- ✅ 复用 `LifecoachCard` 组件
- ✅ 摘要展示关键指标（北极星、月度、杠杆、大石头）

---

#### Step 1.3: 创建 ChatEmptyStateWithDashboard

**文件**: `apps/web/src/components/chat/ChatEmptyStateWithDashboard.tsx`

```typescript
"use client";

import { useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import type { SkillType } from "@/components/core";
import type { DashboardDTO } from "@/types/dashboard";
import { DailyGreeting } from "@/components/greeting/DailyGreeting";
import { VibeGlyph, BreathAura } from "@/components/core";
import { AmbientStatusBar } from "./AmbientStatusBar";
import { LifecoachQuickView } from "./LifecoachQuickView";
import { SkillCarousel } from "@/components/dashboard/skills/SkillCarousel";
import { Skeleton } from "@/components/ui/Skeleton";

interface ChatEmptyStateWithDashboardProps {
  skill: SkillType;
  dashboardData?: DashboardDTO | null;
  isDashboardLoading?: boolean;
  onQuickPrompt?: (prompt: string) => void;
  onCheckIn: () => Promise<void>;
  onToggleLever: (leverId: string) => Promise<void>;
  onToggleRock: (rockId: string) => Promise<void>;
  dailyGreeting: {
    greeting: string;
    solarTerm?: string | null;
    timeOfDay: string;
    date: string;
    todayTip: string;
    baziHint?: string;
    fortuneScore: number;
    fortuneHint: string;
    actionText: string;
    actionCompleted: boolean;
    onActionToggle: () => void;
    shareText: string;
  };
  className?: string;
}

export function ChatEmptyStateWithDashboard({
  skill,
  dashboardData,
  isDashboardLoading,
  onQuickPrompt,
  onCheckIn,
  onToggleLever,
  onToggleRock,
  dailyGreeting,
  className,
}: ChatEmptyStateWithDashboardProps) {
  const router = useRouter();

  // Skill 卡片点击：发送预设 prompt
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

  const handleNorthStarClick = useCallback(() => {
    onQuickPrompt?.("查看我的北极星愿景");
  }, [onQuickPrompt]);

  return (
    <div className={cn("flex flex-col items-center w-full md:max-w-xl mx-auto px-4 py-6 space-y-6", className)}>
      {/* 1. DailyGreeting */}
      <DailyGreeting
        greeting={dailyGreeting.greeting}
        solarTerm={dailyGreeting.solarTerm}
        timeOfDay={dailyGreeting.timeOfDay}
        date={dailyGreeting.date}
        todayTip={dailyGreeting.todayTip}
        baziHint={dailyGreeting.baziHint}
        fortuneScore={dailyGreeting.fortuneScore}
        fortuneHint={dailyGreeting.fortuneHint}
        actionItem={{ text: dailyGreeting.actionText, completed: dailyGreeting.actionCompleted }}
        onActionToggle={dailyGreeting.onActionToggle}
        shareText={dailyGreeting.shareText}
        className="w-full"
      />

      {/* 2. VibeGlyph */}
      <div className="relative flex items-center justify-center">
        <div className="absolute w-16 h-16 rounded-full border border-skill-primary/20 animate-pulse-slow" />
        <div className="absolute w-24 h-24 rounded-full border border-skill-primary/10 animate-pulse-slower" />
        <BreathAura skill={skill} size="sm" position="center" intensity="medium" className="opacity-40" />
        <VibeGlyph size="sm" skill={skill} showAura={true} animate={true} className="relative z-10" />
      </div>

      {/* Dashboard 数据加载状态 */}
      {isDashboardLoading ? (
        <DashboardLoadingSkeleton />
      ) : dashboardData ? (
        <>
          {/* 3. AmbientStatusBar */}
          <AmbientStatusBar status={dashboardData.status} onCheckIn={onCheckIn} className="w-full" />

          {/* 4. LifecoachQuickView */}
          <LifecoachQuickView
            data={dashboardData.lifecoach}
            onToggleLever={onToggleLever}
            onToggleRock={onToggleRock}
            onClickNorthStar={handleNorthStarClick}
            className="w-full"
          />

          {/* 5. MySkillsCarousel */}
          {dashboardData.mySkills && dashboardData.mySkills.length > 0 && (
            <div className="w-full">
              <h3 className="text-sm font-semibold mb-3 px-1" style={{ color: 'var(--text-tertiary)' }}>
                我的 Skills
              </h3>
              <SkillCarousel skills={dashboardData.mySkills} onCardClick={handleSkillCardClick} />
            </div>
          )}
        </>
      ) : null}
    </div>
  );
}

// Loading skeleton
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

**关键点**:
- ✅ 整合所有子组件（DailyGreeting, AmbientStatusBar, LifecoachQuickView, MySkillsCarousel）
- ✅ 处理 Dashboard 数据加载状态（骨架屏）
- ✅ Skills 卡片点击映射到预设 prompt
- ✅ 响应式布局（居中，最大宽度限制）

---

### Phase 2: 修改现有组件（30-45 分钟）

#### Step 2.1: 修改 ChatContainer

**文件**: `apps/web/src/components/chat/ChatContainer.tsx`

**步骤**:

1. 添加导入：
```typescript
import { ChatEmptyStateWithDashboard } from "./ChatEmptyStateWithDashboard";
import type { DashboardDTO } from "@/types/dashboard";
```

2. 扩展 Props：
```typescript
export interface ChatContainerProps {
  // ... 原有 props
  dashboardData?: DashboardDTO | null;
  isDashboardLoading?: boolean;
  onCheckIn?: () => Promise<void>;
  onToggleLever?: (leverId: string) => Promise<void>;
  onToggleRock?: (rockId: string) => Promise<void>;
}
```

3. 添加函数参数：
```typescript
export function ChatContainer({
  // ... 原有参数
  dashboardData,
  isDashboardLoading,
  onCheckIn,
  onToggleLever,
  onToggleRock,
}: ChatContainerProps) {
  // ...
}
```

4. 准备 DailyGreeting 数据：
```typescript
const dailyData = useDailyGreeting(displaySkill);
const actionKey = useMemo(
  () => `vibelife-daily-action:${displaySkill}:${dailyData.isoDate}`,
  [displaySkill, dailyData.isoDate]
);
const [actionCompleted, setActionCompleted] = useState(false);

useEffect(() => {
  if (typeof window === "undefined") return;
  setActionCompleted(getLocalStorage(actionKey) === "1");
}, [actionKey]);

const toggleAction = useCallback(() => {
  setActionCompleted((prev) => {
    const next = !prev;
    setLocalStorage(actionKey, next ? "1" : "0");
    return next;
  });
}, [actionKey]);

const shareText = useMemo(() => {
  const term = dailyData.solarTerm ? ` · ${dailyData.solarTerm}` : "";
  return [
    `VibeLife${term} · ${dailyData.date}`,
    dailyData.greeting,
    `运势指数：${dailyData.fortuneScore}/100`,
    `今日一步：${dailyData.actionText}`,
    "#VibeLife",
  ].join("\n");
}, [dailyData]);

// 默认回调
const handleCheckIn = useCallback(async () => {
  if (onCheckIn) {
    await onCheckIn();
  } else {
    toast.success("签到成功！");
  }
}, [onCheckIn]);

const handleToggleLever = useCallback(async (leverId: string) => {
  if (onToggleLever) {
    await onToggleLever(leverId);
  }
}, [onToggleLever]);

const handleToggleRock = useCallback(async (rockId: string) => {
  if (onToggleRock) {
    await onToggleRock(rockId);
  }
}, [onToggleRock]);
```

5. 替换空状态渲染：
```typescript
{!hasMessages ? (
  /* Empty state with Dashboard */
  <div className="flex flex-col items-center justify-end h-full pb-4">
    <ChatEmptyStateWithDashboard
      skill={displaySkill}
      dashboardData={dashboardData}
      isDashboardLoading={isDashboardLoading}
      onQuickPrompt={handleQuickPrompt}
      onCheckIn={handleCheckIn}
      onToggleLever={handleToggleLever}
      onToggleRock={handleToggleRock}
      dailyGreeting={{
        greeting: dailyData.greeting,
        solarTerm: dailyData.solarTerm,
        timeOfDay: dailyData.timeOfDay,
        date: dailyData.date,
        todayTip: dailyData.todayTip,
        baziHint: dailyData.baziHint,
        fortuneScore: dailyData.fortuneScore,
        fortuneHint: dailyData.fortuneHint,
        actionText: dailyData.actionText,
        actionCompleted,
        onActionToggle: toggleAction,
        shareText,
      }}
    />
  </div>
) : (
  /* Messages list */
  // ...
)}
```

---

#### Step 2.2: 修改 chat/page.tsx

**文件**: `apps/web/src/app/chat/page.tsx`

**步骤**:

1. 添加导入：
```typescript
import { useDashboard } from "@/hooks/useDashboard";
```

2. 在 `ChatContent` 中集成 useDashboard：
```typescript
const ChatContent = memo(function ChatContent() {
  const { skill, setSkill } = useSkill();

  // Dashboard 数据（用于空状态）
  const {
    dashboard,
    isLoading: isDashboardLoading,
    checkIn,
    toggleLever,
    toggleRock,
  } = useDashboard();

  // ... 其他逻辑

  return (
    <LuminousPaper skill={skill} variant="default" className="h-full relative">
      <BreathAura skill={skill} size="xl" position="top" intensity="low" className="opacity-20" />
      <ChatContainer
        skill={skill}
        scenario={scenario || undefined}
        voiceMode={voiceMode}
        initialPrompt={initialPrompt}
        onInitialPromptSent={() => setInitialPrompt(null)}
        dashboardData={dashboard}
        isDashboardLoading={isDashboardLoading}
        onCheckIn={checkIn}
        onToggleLever={toggleLever}
        onToggleRock={toggleRock}
      />
    </LuminousPaper>
  );
});
```

---

### Phase 3: 清理冗余代码（15-30 分钟）

#### Step 3.1: 修改 /dashboard 路由

**文件**: `apps/web/src/app/dashboard/page.tsx`

```typescript
"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function DashboardPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/chat");
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-bg-primary">
      <div className="text-center">
        <div className="w-12 h-12 rounded-full bg-accent-primary/10 animate-pulse flex items-center justify-center mx-auto mb-3">
          <span className="text-2xl">💬</span>
        </div>
        <p className="text-text-secondary text-sm">重定向到对话...</p>
      </div>
    </div>
  );
}
```

#### Step 3.2: 删除 loading.tsx

```bash
rm -f apps/web/src/app/dashboard/loading.tsx
```

#### Step 3.3: 更新 app/page.tsx

**修改重定向逻辑**:
```typescript
// V9: Redirect authenticated users to Chat (Dashboard integrated)
useEffect(() => {
  if (isLoaded && isSignedIn) {
    router.replace('/chat')
  }
}, [isSignedIn, isLoaded, router])
```

#### Step 3.4: 清理图标导入

**NavBar.tsx 和 MobileTabBar.tsx**:
```typescript
// 移除
import { LayoutDashboard } from "lucide-react";
```

---

### Phase 4: 测试与验证（30 分钟）

#### Step 4.1: 本地构建测试

```bash
cd apps/web
npm run build
```

**检查构建错误**:
- 确保无 TypeScript 类型错误
- 确保无 ESLint 警告（Critical）

#### Step 4.2: 启动开发服务器

```bash
npm run dev
```

访问 `http://localhost:3000/chat` 检查：
1. ✅ 空状态显示所有 Dashboard 组件
2. ✅ Dashboard 数据正常加载
3. ✅ 交互功能正常（签到、展开、Skills 点击）
4. ✅ 发送消息后 Dashboard 隐藏

#### Step 4.3: 响应式测试

使用浏览器开发工具模拟不同设备：
- Desktop (≥1024px)
- Tablet (768px - 1023px)
- Mobile (<768px)

检查所有组件在不同屏幕尺寸下的显示效果。

---

## 🐛 常见问题与解决

### 问题 1: Dashboard 数据未加载

**症状**: 空状态显示骨架屏，但数据始终不加载

**原因**:
- 后端 API `/api/dashboard` 返回错误
- 用户未登录

**解决**:
1. 检查浏览器 Network 面板，查看 API 请求状态
2. 确认用户已登录
3. 检查后端日志

### 问题 2: 签到按钮点击无反应

**症状**: 点击"开始今天"按钮无任何反应

**原因**:
- `onCheckIn` 回调未正确传递
- 后端 API `/api/dashboard/checkin` 错误

**解决**:
```typescript
// 确保 onCheckIn 已传递
<ChatContainer
  // ...
  onCheckIn={checkIn}  // ← 确保这里传递了
/>
```

### 问题 3: Skills 卡片点击后未发送消息

**症状**: 点击 Skills 卡片无反应

**原因**:
- `onQuickPrompt` 回调未正确传递
- Prompt 映射错误

**解决**:
```typescript
// 检查 handleSkillCardClick 映射
const promptMap: Record<string, string> = {
  bazi: "帮我看看今日运势",
  zodiac: "查看我的星盘运势",
  // ... 确保 skillId 在映射中
};
```

### 问题 4: Lifecoach 无法展开

**症状**: 点击 Lifecoach 卡片无反应

**原因**:
- `isExpanded` 状态未正确管理
- 点击事件被阻止

**解决**:
```typescript
// 确保 onClick 绑定正确
<button onClick={() => setIsExpanded(true)}>
  {/* ... */}
</button>
```

---

## ✅ 完成检查清单

### 代码完整性
- [ ] 所有新组件已创建
- [ ] 所有修改文件已更新
- [ ] 所有导入已添加
- [ ] Props 类型定义正确

### 功能测试
- [ ] Dashboard 数据正常加载
- [ ] 签到功能正常
- [ ] Lifecoach 展开/收起正常
- [ ] Skills 卡片点击发送 prompt
- [ ] 对话开始后 Dashboard 隐藏

### 性能测试
- [ ] Dashboard 加载时间 < 500ms
- [ ] 无明显卡顿
- [ ] 内存占用正常

### 兼容性测试
- [ ] Chrome/Edge 正常
- [ ] Firefox 正常
- [ ] Safari 正常
- [ ] 移动端正常

---

**实施完成！** 🎉

如有问题，请参考：
- [Ultra Analysis Report](./ULTRA_ANALYSIS_REPORT.md)
- [Dashboard Chat Integration](./DASHBOARD_CHAT_INTEGRATION.md)
- [Test Report](./TEST_REPORT.md)
