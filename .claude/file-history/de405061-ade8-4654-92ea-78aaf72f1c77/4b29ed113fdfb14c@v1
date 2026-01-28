# Journey 页面文档

Journey 页面是 VibeLife 的核心功能之一，基于 Dan Koe 的一日重置流程，帮助用户设定人生愿景、拆解目标、并持续执行。

## 目录

- [概述](#概述)
- [核心概念](#核心概念)
- [快速开始](#快速开始)
- [架构设计](#架构设计)
- [文档索引](#文档索引)
- [开发指南](#开发指南)

---

## 概述

### Journey 页面的本质

```
Journey 页面不是「展示目标」的静态页面
而是「人生游戏」的控制中心

用户心智模型：
"我来这里，是为了：
 1. 看到我在哪（当前进度）
 2. 知道下一步做什么（行动指引）
 3. 能快速调整方向（进入教练对话）"
```

### 核心价值

1. **愿景驱动**: 从 3 年愿景反推今日行动
2. **渐进引导**: 4 状态渐进系统，降低认知负担
3. **执行优先**: 今日杠杆始终可见，降低执行摩擦
4. **Chat-First**: 所有深度交互回到对话，保持 UI 简洁

---

## 核心概念

### Dan Koe 流程映射

```
┌─────────────────────────────────────────────────────────────┐
│                Dan Koe 一日重置 → Journey 页面               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Phase 1: 诊断 (Diagnose)                                  │
│   • 心理考古：识别行为模式                                   │
│   • 卡点突破：找到阻碍                                       │
│   → 在 Chat 中完成，结果存入 identity.patterns              │
│                                                             │
│   Phase 2: 设计 (Design)                                    │
│   • 反愿景：你最恐惧的未来                                   │
│   • 愿景：你真正想要的未来                                   │
│   • 身份：你需要成为谁                                       │
│   → 在 Chat 中完成，结果展示在 Journey 顶部「北极星」        │
│                                                             │
│   Phase 3: 执行 (Execute)                                   │
│   • 年度目标 → 季度聚焦 → 月度Boss战 → 周大石头 → 每日杠杆   │
│   → Journey 页面主体：展示层级 + 勾选执行                    │
│                                                             │
│   Phase 4: 复盘 (Review)                                    │
│   • 每日复盘 / 周复盘 / 月复盘                               │
│   → 在 Chat 中完成，进度在 Journey 页面可视化                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4 状态渐进系统

| State | 条件 | 展示内容 | CTA |
|-------|------|----------|-----|
| **empty** | 没有北极星愿景 | 引导开始旅程 | "开始设计我的人生" |
| **north_star_set** | 有北极星，无路线图 | 北极星 + 引导制定路线图 | "继续设定目标 →" |
| **planned** | 有路线图，无周大石头 | 北极星 + 路线图 + 引导设定本周 | "设定本周计划 →" |
| **executing** | 有周大石头 | 完整执行仪表盘 | 勾选完成 + 快捷入口 |

### 数据层级

```
⭐ 北极星愿景 (North Star)
 ├─ 愿景场景 (Vision Scene)
 └─ 反愿景场景 (Anti-Vision Scene)

🎯 年度目标 (Yearly Goals) [1-3个]
 ├─ 目标1: 创作自由
 ├─ 目标2: 家庭幸福
 └─ 目标3: 身心健康

📊 月度 Boss (Monthly Boss) [每月1个]
 ├─ Boss 名称: 完成书籍第3章
 ├─ 进度: 40%
 └─ 里程碑: [3.1节 ✓, 3.2节 ○, 3.3节 ○]

🪨 周大石头 (Weekly Rocks) [每周3-5个]
 ├─ 完成3.2节初稿 ✓
 ├─ 回复合作邮件 ✓
 ├─ 周三带孩子活动 ○
 └─ 周六户外跑步 ○

☀️ 每日杠杆 (Daily Levers) [每日1-3个]
 ├─ 1小时深度写作 ✓
 ├─ 30分钟阅读 ○
 └─ 回复重要邮件 ○
```

---

## 快速开始

### 1. 读取 Journey 数据

```typescript
import { useJourneyData } from "@/hooks/useJourneyData";

function MyComponent() {
  const { data, isLoading, journeyState } = useJourneyData();

  if (isLoading) return <div>Loading...</div>;

  console.log(journeyState); // "empty" | "north_star_set" | "planned" | "executing"
  console.log(data.north_star);
  console.log(data.weekly);
  console.log(data.daily_levers);
}
```

### 2. 根据状态展示 UI

```typescript
import EmptyJourneyCard from "@/components/journey/EmptyJourneyCard";
import NorthStarSetCard from "@/components/journey/NorthStarSetCard";
import PlannedStateCard from "@/components/journey/PlannedStateCard";
import JourneyContent from "@/components/journey/JourneyContent";

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
      return <JourneyContent data={data!} />;
  }
}
```

### 3. 切换任务完成状态

```typescript
function WeeklyRocks() {
  const { weekly, toggleAction } = useJourneyData();

  return (
    <div>
      {weekly?.rocks?.map(rock => (
        <Checkbox
          key={rock.id}
          checked={rock.status === "completed"}
          onChange={() => toggleAction(rock.id!)}
        >
          {rock.task}
        </Checkbox>
      ))}
    </div>
  );
}
```

---

## 架构设计

### 技术栈

- **Frontend Framework**: Next.js 14 (App Router)
- **State Management**: SWR (React Hooks for Data Fetching)
- **UI Components**: React + Tailwind CSS
- **Backend**: Python FastAPI + SQLite (skill_data.lifecoach)
- **Data Flow**: Client → Next.js API Route → Backend Skill API

### 数据流

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│             │      │              │      │                 │
│  Component  │ ───→ │ useJourneyData │ ───→ │  /api/journey   │
│             │      │  (SWR Hook)  │      │  (Next.js API)  │
└─────────────┘      └──────────────┘      └─────────────────┘
                            ↑                       │
                            │                       ↓
                            │              ┌─────────────────┐
                            │              │                 │
                            └────────────  │  Backend API    │
                              (Optimistic  │  /skills/       │
                               Updates)    │  lifecoach/     │
                                           │  state_read     │
                                           │  state_write    │
                                           └─────────────────┘
```

### 文件结构

```
vibelife/
├── apps/
│   ├── api/
│   │   ├── routes/skills.py              # Backend skill APIs
│   │   ├── skills/lifecoach/             # Lifecoach skill logic
│   │   └── stores/skill_catalog_repo.py  # Skill data storage
│   │
│   └── web/
│       ├── src/
│       │   ├── app/
│       │   │   └── api/journey/route.ts  # Journey API proxy
│       │   ├── components/journey/       # Journey UI components
│       │   │   ├── EmptyJourneyCard.tsx
│       │   │   ├── NorthStarSetCard.tsx
│       │   │   ├── PlannedStateCard.tsx
│       │   │   ├── JourneyContent.tsx
│       │   │   ├── NorthStarCard.tsx
│       │   │   ├── YearlyGoalsCard.tsx
│       │   │   ├── MonthlyBossCard.tsx
│       │   │   ├── WeeklyActionsCard.tsx
│       │   │   └── JourneyDailyLeversCard.tsx
│       │   ├── hooks/
│       │   │   └── useJourneyData.ts     # Journey data hook
│       │   └── types/
│       │       └── journey.ts            # TypeScript types
│       │
└── docs/
    └── components/journey/               # 本目录
        ├── README.md                     # 本文件
        ├── journey-design.md             # UI/UX 设计文档
        ├── API.md                        # API 文档
        ├── TYPES.md                      # 类型文档
        ├── HOOK.md                       # Hook 文档
        └── COMPONENTS.md                 # 组件文档
```

---

## 文档索引

### 设计文档

- **[journey-design.md](./journey-design.md)** - UI/UX 设计完整方案
  - 用户心智模型
  - 页面状态设计
  - 交互设计
  - 首次流程设计
  - Mobile 适配

### 技术文档

- **[API.md](./API.md)** - Journey API 文档
  - GET/POST /api/journey
  - 请求/响应格式
  - 错误处理
  - 使用示例

- **[TYPES.md](./TYPES.md)** - 数据类型文档
  - LifecoachSkillData
  - NorthStar, Identity, Roadmap
  - MonthlyBoss, Weekly, DailyLevers
  - JourneyState 状态机

- **[HOOK.md](./HOOK.md)** - useJourneyData Hook 文档
  - Hook API 说明
  - 使用示例
  - 乐观更新机制
  - 性能优化

- **[COMPONENTS.md](./COMPONENTS.md)** - 组件文档
  - 组件架构
  - 各组件 Props 和功能
  - 设计模式
  - Mobile 适配

### 相关文档

- **[@vibelife/docs/components/coreagent/SKILL_DATA_ARCHITECTURE.md](../coreagent/SKILL_DATA_ARCHITECTURE.md)** - Skill Data 架构
- **[@vibelife/docs/components/lifecoach/](../lifecoach/)** - Lifecoach Skill 文档

---

## 开发指南

### 添加新的 Journey 卡片

1. 在 `/apps/web/src/components/journey/` 创建新组件
2. 定义 Props 类型（使用 `/apps/web/src/types/journey.ts` 中的类型）
3. 使用 `useJourneyData` Hook 获取数据
4. 在 `JourneyContent.tsx` 中引入并使用

```typescript
// 1. 创建新组件
// /apps/web/src/components/journey/QuarterlyFocusCard.tsx
import { useJourneyData } from "@/hooks/useJourneyData";

interface QuarterlyFocusCardProps {
  focus?: string;
}

export default function QuarterlyFocusCard({ focus }: QuarterlyFocusCardProps) {
  return (
    <div className="card">
      <h2>Q1 聚焦</h2>
      <p>{focus}</p>
    </div>
  );
}

// 2. 在 JourneyContent.tsx 中使用
import QuarterlyFocusCard from "./QuarterlyFocusCard";

export default function JourneyContent({ data }: JourneyContentProps) {
  return (
    <div>
      <NorthStarCard northStar={data.north_star} />
      <QuarterlyFocusCard focus={data.quarterly_focus} />
      {/* ... other cards */}
    </div>
  );
}
```

### 添加新的数据字段

1. 在后端 lifecoach skill 中添加字段逻辑
2. 在 `/apps/web/src/types/journey.ts` 中更新类型定义
3. 在 `useJourneyData.ts` 中添加计算属性（如需要）
4. 在组件中使用新字段

```typescript
// 1. 更新类型
// /apps/web/src/types/journey.ts
export interface LifecoachSkillData {
  // ... existing fields
  quarterly_focus?: string;  // 新增字段
}

// 2. 在 Hook 中使用
// /apps/web/src/hooks/useJourneyData.ts
export function useJourneyData() {
  // ...
  return {
    // ...
    quarterlyFocus: data?.quarterly_focus,
  };
}
```

### 调试

#### 查看 Journey 数据

```typescript
import { useJourneyData } from "@/hooks/useJourneyData";

function DebugPanel() {
  const { data, journeyState } = useJourneyData();

  return (
    <pre>
      State: {journeyState}
      {JSON.stringify(data, null, 2)}
    </pre>
  );
}
```

#### 手动刷新数据

```typescript
const { refresh } = useJourneyData();

<button onClick={refresh}>刷新数据</button>
```

#### 测试乐观更新失败回滚

```typescript
const { toggleAction } = useJourneyData();

const handleToggle = async (id: string) => {
  try {
    await toggleAction(id);
  } catch (error) {
    console.log("回滚成功:", error);
  }
};
```

### 性能优化

1. **使用 React.memo**: 避免不必要的重渲染

```typescript
export default React.memo(MonthlyBossCard);
```

2. **SWR Deduplication**: 1分钟内重复请求会被去重

3. **Optimistic Updates**: 立即更新 UI，减少等待时间

4. **Lazy Loading**: 懒加载非关键卡片

```typescript
const QuarterlyFocusCard = lazy(() => import("./QuarterlyFocusCard"));
```

### 测试

#### 单元测试

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useJourneyData } from '@/hooks/useJourneyData';

test('should load journey data', async () => {
  const { result } = renderHook(() => useJourneyData());

  await waitFor(() => {
    expect(result.current.isLoading).toBe(false);
  });

  expect(result.current.data).toBeDefined();
});
```

#### 集成测试

```typescript
import { render, screen } from '@testing-library/react';
import JourneyPage from '@/app/journey/page';

test('renders empty state for new user', () => {
  render(<JourneyPage />);
  expect(screen.getByText('还没有设定方向？')).toBeInTheDocument();
});
```

---

## FAQ

### Q: Journey 数据存储在哪里？

A: 数据存储在后端 SQLite 数据库的 `skill_data` 表中，字段为 `lifecoach`。

### Q: 如何触发 Dan Koe 设置流程？

A: 在 Chat 中发送消息触发 lifecoach skill，或点击 Journey 页面的 CTA 按钮跳转到 Chat。

### Q: 为什么使用 SWR 而不是 Redux？

A: SWR 提供了自动缓存、去重、重连刷新等特性，更适合服务端状态管理。Journey 数据属于服务端状态，不需要复杂的客户端状态管理。

### Q: 如何处理多设备同步？

A: SWR 在重连时会自动刷新数据（`revalidateOnReconnect: true`），确保数据最新。如需实时同步，可以考虑添加 WebSocket 或轮询。

### Q: 乐观更新失败后如何回滚？

A: `useJourneyData` 内部已实现自动回滚。如果后端 API 调用失败，会自动恢复到更新前的数据。

---

## 更新日志

### 2026-01-21
- ✅ 创建完整的 Journey 文档体系
- ✅ 整理所有 journey 相关文档到 `/docs/components/journey/`
- ✅ 添加 API, TYPES, HOOK, COMPONENTS 文档

---

## 贡献指南

如需更新 Journey 功能：

1. 阅读本文档和相关设计文档
2. 遵循现有的架构模式（Chat-First, 乐观更新等）
3. 更新相关类型定义
4. 添加单元测试
5. 更新文档

---

## 联系方式

如有问题，请参考：
- 设计问题 → [@vibelife/docs/components/journey/journey-design.md](./journey-design.md)
- 技术问题 → [@vibelife/docs/components/journey/API.md](./API.md) | [HOOK.md](./HOOK.md)
- 后端问题 → [@vibelife/docs/components/coreagent/](../coreagent/)
