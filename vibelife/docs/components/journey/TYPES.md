# Journey Types Documentation

Journey 数据结构基于 CoreAgent SKILL_DATA_ARCHITECTURE，对应后端 `skill_data.lifecoach`。

## 核心数据结构

### LifecoachSkillData

完整的 lifecoach skill_data 结构：

```typescript
interface LifecoachSkillData {
  north_star?: NorthStar;           // 北极星愿景
  identity?: Identity;               // 身份转换
  roadmap?: Roadmap;                 // 路线图 (年度目标)
  goals?: YearlyGoal[];              // 年度目标 (兼容旧格式)
  weekly?: Weekly;                   // 本周行动 (旧格式)
  weekly_rocks?: Weekly;             // 周大石头 (新格式)
  monthly_boss?: MonthlyBoss;        // 月度 Boss
  daily_levers?: DailyLevers;        // 每日杠杆
  progress?: Progress;               // 进度统计
  _state?: LifecoachSystemState;     // 系统状态
  _meta?: {                          // 元数据
    version: number;
    created_at?: string;
    updated_at?: string;
  };
}
```

## Dan Koe 协议核心输出

### NorthStar (北极星愿景)

Dan Koe 协议第一步输出，定义用户的愿景和反愿景。

```typescript
interface NorthStar {
  vision_scene?: string;        // 愿景场景 - 3年后的周二
  vision_timeframe?: string;    // 愿景时间框架
  anti_vision_scene?: string;   // 反愿景场景 - 5年后的周二
  pain_points?: string[];       // 持续的不满/痛点
}
```

**示例：**
```json
{
  "vision_scene": "3年后的周二早晨，我在海边的工作室写作，刚完成新书的一章...",
  "vision_timeframe": "3 years",
  "anti_vision_scene": "5年后依然困在无意义的工作中，与家人疏远，健康恶化...",
  "pain_points": ["时间不自由", "工作无意义", "与家人疏远"]
}
```

### Identity (身份转换)

Dan Koe 协议核心输出，帮助用户完成身份认知转变。

```typescript
interface Identity {
  current?: string;   // 旧身份 - "我是那种会..."
  target?: string;    // 新身份 - "我是那种..."
  roles?: string[];   // 角色列表
}
```

**示例：**
```json
{
  "current": "我是那种总是拖延、害怕失败的人",
  "target": "我是一个果断行动、从失败中学习的创作者",
  "roles": ["创作者", "父亲", "终身学习者"]
}
```

## 年度目标体系

### YearlyGoal (年度目标)

```typescript
interface YearlyGoal {
  id: string;
  title: string;
  description?: string;
  category?: "career" | "health" | "relationship" | "wealth" | "growth" | "other";
  progress: number;              // 0-100
  status: "pending" | "in_progress" | "completed" | "abandoned";
  year?: number;
  milestones?: Milestone[];
}
```

**示例：**
```json
{
  "id": "goal-2026-1",
  "title": "出版第一本书",
  "description": "完成并出版关于个人成长的书籍",
  "category": "career",
  "progress": 35,
  "status": "in_progress",
  "year": 2026,
  "milestones": [
    { "id": "m1", "title": "完成大纲", "completed": true },
    { "id": "m2", "title": "完成前6章", "completed": false }
  ]
}
```

### Roadmap (路线图)

```typescript
interface Roadmap {
  goals?: YearlyGoal[];
  created_at?: string;
  updated_at?: string;
}
```

## 执行体系

### MonthlyBoss (月度 Boss)

Dan Koe "人生游戏化" 概念，每月一个大任务。

```typescript
interface MonthlyBoss {
  id?: string;
  title: string;
  description?: string;
  month: string;                 // YYYY-MM
  progress: number;              // 0-100
  status: "pending" | "in_progress" | "completed" | "failed";
  goal_id?: string;              // 关联的年度目标 ID
  milestones?: Milestone[];
}
```

**示例：**
```json
{
  "id": "boss-2026-01",
  "title": "完成书籍第3章",
  "month": "2026-01",
  "progress": 40,
  "status": "in_progress",
  "goal_id": "goal-2026-1",
  "milestones": [
    { "id": "m1", "title": "3.1 节初稿", "completed": true },
    { "id": "m2", "title": "案例收集", "completed": true },
    { "id": "m3", "title": "3.2 节初稿", "completed": false }
  ]
}
```

### Weekly (本周大石头)

Dan Koe "Weekly Rocks" 概念，本周 3-5 件重要的事。

```typescript
interface Weekly {
  week_start?: string;           // YYYY-MM-DD
  rocks?: WeeklyAction[];
  theme?: string;                // 本周主题
  energy_budget?: number;        // 能量预算
  stats?: {
    total: number;
    completed: number;
    in_progress: number;
    completion_rate: number;
  };
}

interface WeeklyAction {
  id?: string;
  task: string;
  status: "pending" | "in_progress" | "completed";
  progress?: number;             // 0-100
  completed_at?: string;
}
```

**示例：**
```json
{
  "week_start": "2026-01-20",
  "theme": "深度创作周",
  "rocks": [
    {
      "id": "w1",
      "task": "完成3.2节初稿",
      "status": "completed",
      "completed_at": "2026-01-21T10:30:00Z"
    },
    {
      "id": "w2",
      "task": "周三带孩子参加学校活动",
      "status": "pending"
    }
  ],
  "stats": {
    "total": 4,
    "completed": 1,
    "in_progress": 1,
    "completion_rate": 25
  }
}
```

### DailyLevers (每日杠杆)

Dan Koe "Daily Levers" 概念，每日 1-3 个高杠杆行动。

```typescript
interface DailyLevers {
  date: string;                  // YYYY-MM-DD
  levers: DailyLever[];
  energy_level?: number;         // 1-10
  intention?: string;            // 今日意图
  stats?: {
    total: number;
    completed: number;
    completion_rate: number;
  };
}

interface DailyLever {
  id: string;
  task: string;
  status: "pending" | "completed" | "skipped";
  completed_at?: string;
  skip_reason?: string;
  rock_id?: string;              // 关联的周大石头 ID
}
```

**示例：**
```json
{
  "date": "2026-01-21",
  "energy_level": 8,
  "intention": "专注深度工作",
  "levers": [
    {
      "id": "d1",
      "task": "1小时深度写作",
      "status": "completed",
      "completed_at": "2026-01-21T09:30:00Z",
      "rock_id": "w1"
    },
    {
      "id": "d2",
      "task": "30分钟阅读",
      "status": "pending"
    }
  ],
  "stats": {
    "total": 3,
    "completed": 1,
    "completion_rate": 33
  }
}
```

## 进度与状态

### Progress (进度统计)

```typescript
interface Progress {
  current_streak: number;        // 当前连续天数
  longest_streak: number;        // 最长连续天数
  total_checkins: number;        // 总签到次数
  last_checkin_date?: string;
  tasks_completed?: number;
  weekly_completion_rate?: number;
  today_checked_in?: boolean;
  achievements?: string[];
}
```

### LifecoachSystemState (系统状态)

```typescript
interface LifecoachSystemState {
  active_framework?: "dankoe" | "covey" | "yangming" | "liaofan" | null;
  initialized_at?: string;
  last_interaction?: string;
}
```

## Journey Page State Machine

### JourneyState

Journey 页面4状态渐进系统：

```typescript
type JourneyState = "empty" | "north_star_set" | "planned" | "executing";
```

**状态说明：**

| State | 条件 | 展示内容 |
|-------|------|----------|
| `empty` | 没有北极星愿景 | 引导开始旅程 |
| `north_star_set` | 有北极星，无路线图 | 北极星 + 引导制定路线图 |
| `planned` | 有路线图，无周大石头 | 北极星 + 路线图 + 引导设定本周 |
| `executing` | 有周大石头 | 完整执行仪表盘 |

**状态判断函数：**

```typescript
function getJourneyState(data: LifecoachSkillData | null | undefined): JourneyState {
  if (!data?.north_star?.vision_scene) return "empty";

  const hasRoadmap = (data.roadmap?.goals?.length ?? 0) > 0 || (data.goals?.length ?? 0) > 0;
  if (!hasRoadmap) return "north_star_set";

  const hasWeeklyRocks = (data.weekly?.rocks?.length ?? 0) > 0 || (data.weekly_rocks?.rocks?.length ?? 0) > 0;
  if (!hasWeeklyRocks) return "planned";

  return "executing";
}
```

## API Response Types

### ReadLifecoachStateResponse

```typescript
interface ReadLifecoachStateResponse {
  status: "success" | "empty" | "error";
  message?: string;
  data: LifecoachSkillData;
  version?: number;
  updated_at?: string;
}
```

## Related Files

- **Type Definitions**: `/apps/web/src/types/journey.ts`
- **Backend Schema**: `@vibelife/docs/components/coreagent/SKILL_DATA_ARCHITECTURE.md`
- **Lifecoach Skill**: `/apps/api/skills/lifecoach/`
