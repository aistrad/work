# useJourneyData Hook Documentation

React Hook for managing Journey page data with SWR-based state management and optimistic updates.

## Overview

`useJourneyData` 是 Journey 页面的核心数据管理 Hook，负责：

1. **数据获取**: 通过 SWR 从 `/api/journey` 获取 lifecoach skill_data
2. **状态管理**: 提供计算属性和状态判断
3. **乐观更新**: 支持本地先更新，后端失败时回滚
4. **自动刷新**: 支持手动刷新和重连时自动刷新

## Basic Usage

```typescript
import { useJourneyData } from "@/hooks/useJourneyData";

function JourneyPage() {
  const {
    data,
    isLoading,
    error,
    journeyState,
    toggleAction,
    toggleLever,
    refresh
  } = useJourneyData();

  if (isLoading) return <JourneySkeleton />;
  if (error) return <ErrorState error={error} />;

  return (
    <div>
      <h1>My Journey - {journeyState}</h1>
      {/* 使用 data 和 actions */}
    </div>
  );
}
```

## Return Values

### Data

| Property | Type | Description |
|----------|------|-------------|
| `data` | `LifecoachSkillData \| undefined` | 完整的 lifecoach skill_data |
| `isLoading` | `boolean` | 是否正在加载 |
| `error` | `Error \| undefined` | 错误信息 |

### Computed Values

| Property | Type | Description |
|----------|------|-------------|
| `journeyState` | `JourneyState` | 页面状态: `empty` \| `north_star_set` \| `planned` \| `executing` |
| `hasNorthStar` | `boolean` | 是否有北极星愿景 |
| `hasIdentity` | `boolean` | 是否有身份设定 |
| `hasRoadmap` | `boolean` | 是否有路线图/年度目标 |
| `hasWeeklyActions` | `boolean` | 是否有周大石头 |
| `hasMonthlyBoss` | `boolean` | 是否有月度 Boss |
| `hasDailyLevers` | `boolean` | 是否有每日杠杆 |

### Data Sections

| Property | Type | Description |
|----------|------|-------------|
| `northStar` | `NorthStar \| undefined` | 北极星愿景 |
| `identity` | `Identity \| undefined` | 身份转换 |
| `roadmap` | `Roadmap \| undefined` | 路线图 |
| `goals` | `YearlyGoal[]` | 年度目标列表（已规范化） |
| `weekly` | `Weekly \| undefined` | 本周大石头（已规范化） |
| `monthlyBoss` | `MonthlyBoss \| undefined` | 月度 Boss |
| `dailyLevers` | `DailyLevers \| undefined` | 每日杠杆 |
| `progress` | `Progress \| undefined` | 进度统计 |
| `systemState` | `LifecoachSystemState \| undefined` | 系统状态 |

### Actions

| Method | Signature | Description |
|--------|-----------|-------------|
| `toggleAction` | `(actionId: string) => Promise<void>` | 切换周大石头完成状态 |
| `toggleLever` | `(leverId: string) => Promise<void>` | 切换每日杠杆完成状态 |
| `toggleMilestone` | `(milestoneId: string) => Promise<void>` | 切换月度 Boss 里程碑完成状态 |
| `checkin` | `(energyLevel?: number, intention?: string) => Promise<{success: boolean, streak: number, message: string}>` | 每日签到 |
| `refresh` | `() => Promise<void>` | 手动刷新数据 |

## Usage Examples

### 1. 根据状态显示不同UI

```typescript
function JourneyPage() {
  const { journeyState, data } = useJourneyData();

  switch (journeyState) {
    case "empty":
      return <EmptyJourneyCard />;
    case "north_star_set":
      return <NorthStarSetCard northStar={data?.north_star} />;
    case "planned":
      return <PlannedStateCard roadmap={data?.roadmap} />;
    case "executing":
      return <JourneyContent data={data} />;
  }
}
```

### 2. 切换周大石头完成状态

```typescript
function WeeklyRocksCard() {
  const { weekly, toggleAction } = useJourneyData();

  const handleToggle = async (rockId: string) => {
    try {
      await toggleAction(rockId);
      toast.success("已更新");
    } catch (error) {
      toast.error("更新失败");
    }
  };

  return (
    <div>
      {weekly?.rocks?.map(rock => (
        <Checkbox
          key={rock.id}
          checked={rock.status === "completed"}
          onChange={() => handleToggle(rock.id!)}
        >
          {rock.task}
        </Checkbox>
      ))}
    </div>
  );
}
```

### 3. 切换每日杠杆

```typescript
function DailyLeversCard() {
  const { dailyLevers, toggleLever, progress } = useJourneyData();

  const handleToggle = async (leverId: string) => {
    try {
      await toggleLever(leverId);
    } catch (error) {
      console.error("Toggle lever failed:", error);
    }
  };

  return (
    <div>
      <h2>今日杠杆 🔥 {progress?.current_streak}天连续</h2>
      {dailyLevers?.levers?.map(lever => (
        <Checkbox
          key={lever.id}
          checked={lever.status === "completed"}
          onChange={() => handleToggle(lever.id)}
        >
          {lever.task}
        </Checkbox>
      ))}
    </div>
  );
}
```

### 4. 切换月度 Boss 里程碑

```typescript
function MonthlyBossCard() {
  const { monthlyBoss, toggleMilestone } = useJourneyData();

  const handleToggle = async (milestoneId: string) => {
    try {
      await toggleMilestone(milestoneId);
    } catch (error) {
      console.error("Toggle milestone failed:", error);
    }
  };

  return (
    <div>
      <h2>{monthlyBoss?.title}</h2>
      <ProgressBar value={monthlyBoss?.progress || 0} />
      {monthlyBoss?.milestones?.map(milestone => (
        <Checkbox
          key={milestone.id}
          checked={milestone.completed}
          onChange={() => handleToggle(milestone.id)}
        >
          {milestone.title}
        </Checkbox>
      ))}
    </div>
  );
}
```

### 5. 每日签到

```typescript
function CheckinButton() {
  const { checkin, progress } = useJourneyData();
  const [isChecking, setIsChecking] = useState(false);

  const handleCheckin = async () => {
    setIsChecking(true);
    try {
      const result = await checkin(8, "专注深度工作");
      toast.success(`签到成功！🔥 ${result.streak} 天连续`);
    } catch (error) {
      toast.error("签到失败");
    } finally {
      setIsChecking(false);
    }
  };

  if (progress?.today_checked_in) {
    return <div>✅ 今日已签到</div>;
  }

  return (
    <Button onClick={handleCheckin} disabled={isChecking}>
      完成签到 ✓
    </Button>
  );
}
```

### 6. 手动刷新数据

```typescript
function RefreshButton() {
  const { refresh } = useJourneyData();
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refresh();
      toast.success("数据已刷新");
    } catch (error) {
      toast.error("刷新失败");
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <Button onClick={handleRefresh} disabled={isRefreshing}>
      刷新
    </Button>
  );
}
```

## Implementation Details

### SWR Configuration

```typescript
const { data, error, isLoading, mutate } = useSWR<LifecoachSkillData>(
  JOURNEY_KEY,
  fetcher,
  {
    revalidateOnFocus: false,      // 不在 focus 时自动刷新
    revalidateOnReconnect: true,   // 重连时自动刷新
    dedupingInterval: 60000,       // 1分钟去重
    errorRetryCount: 3,            // 错误重试3次
  }
);
```

### Optimistic Update Pattern

所有状态切换（toggleAction, toggleLever, toggleMilestone）都遵循乐观更新模式：

```typescript
1. 计算新状态
2. 立即更新本地数据 (mutate(optimisticData, false))
3. 调用后端 API
4. 如果失败，回滚到原始数据 (mutate(data, false))
```

**优点：**
- 即时 UI 反馈
- 更好的用户体验
- 网络延迟不影响交互

**注意：**
- 后端失败时会回滚
- 需要处理异常情况

### Data Normalization

Hook 内部处理了数据格式的兼容性：

```typescript
// 支持 weekly 和 weekly_rocks 两种格式
const weekly = data?.weekly_rocks || data?.weekly;

// 支持 roadmap.goals 和 goals 两种格式
const goals = data?.roadmap?.goals || data?.goals || [];
```

## Performance Considerations

1. **Deduplication**: 1分钟内重复请求会被去重
2. **Optimistic Updates**: 减少等待时间，提升交互性能
3. **Selective Revalidation**: 仅在重连时自动刷新，避免不必要的请求
4. **SWR Cache**: 全局共享缓存，多个组件使用同一数据不会重复请求

## Error Handling

```typescript
function JourneyPage() {
  const { data, isLoading, error } = useJourneyData();

  if (error) {
    return (
      <ErrorState
        title="加载失败"
        message={error.message}
        retry={() => window.location.reload()}
      />
    );
  }

  // ... rest of component
}
```

## Testing

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useJourneyData } from '@/hooks/useJourneyData';

describe('useJourneyData', () => {
  it('should load journey data', async () => {
    const { result } = renderHook(() => useJourneyData());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.data).toBeDefined();
  });

  it('should toggle action optimistically', async () => {
    const { result } = renderHook(() => useJourneyData());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    const actionId = result.current.weekly?.rocks?.[0]?.id;
    if (actionId) {
      await act(() => result.current.toggleAction(actionId));
      // 验证状态已改变
    }
  });
});
```

## Related Files

- **Hook Implementation**: `/apps/web/src/hooks/useJourneyData.ts`
- **Types**: `/apps/web/src/types/journey.ts`
- **API Route**: `/apps/web/src/app/api/journey/route.ts`
- **SWR Documentation**: https://swr.vercel.app/

## Best Practices

1. **Always Handle Errors**: 用户操作可能失败，需要提供错误反馈
2. **Show Loading States**: 使用 `isLoading` 提供加载反馈
3. **Optimistic Updates**: 利用乐观更新提升体验，但做好失败处理
4. **Avoid Unnecessary Refreshes**: 依赖 SWR 的自动刷新机制，不要频繁手动刷新
5. **Use Computed Values**: 使用提供的计算属性（如 `journeyState`）而不是自己计算
