# Lifecoach V2 数据结构设计

> Version: 2.1 | Date: 2026-01-19
> 基于 Dan Koe + Stephen Covey 方法论融合
> 支持"来自未来的你"角色扮演

---

## 1. 设计原则

### 1.1 核心原则

| 原则 | 说明 |
|-----|------|
| **方法论无关** | 数据结构不绑定具体方法论，Dan Koe、Covey、Ikigai 都用同一套结构 |
| **多目标聚焦** | 北极星支持最多 3 个目标，与角色系统融合 |
| **层级清晰** | 从北极星到每日行动，层层分解，路径明确 |
| **角色平衡** | 支持 Covey 的多角色系统，追踪生活各领域平衡 |
| **持续演进** | 支持渐进式填充，用户可以只做一部分 |
| **自动拆解** | 用户设定愿景后，系统自动拆解路径，用户确认 |

### 1.2 语气与角色分层

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         语气与角色分层设计                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Layer 1: 全局语气 (preferences.voice_mode)                             │
│  ══════════════════════════════════════════                             │
│  存储位置: unified_profiles.profile.preferences.voice_mode              │
│                                                                         │
│  warm          温暖、鼓励、有同理心                                      │
│  playful       活泼、轻松、有趣                                          │
│  roast         毒舌、犀利、激将法                                        │
│  professional  专业、结构化、高效                                        │
│                                                                         │
│  → 全局生效，所有 Skill 共享                                            │
│                                                                         │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  Layer 2: Lifecoach 角色 (lifecoach.system.persona)                     │
│  ══════════════════════════════════════════════════                     │
│  存储位置: life_context._paths["lifecoach"].system.persona              │
│                                                                         │
│  future_self   来自未来的你（基于用户的愿景场景）                        │
│  coach         专业教练                                                  │
│                                                                         │
│  → 只在 lifecoach 场景下生效                                            │
│                                                                         │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  组合矩阵 (2 × 4 = 8 种)：                                               │
│                                                                         │
│              │  warm      │  playful   │  roast     │ professional │   │
│  ────────────┼────────────┼────────────┼────────────┼──────────────│   │
│  future_self │ 温暖的     │ 活泼的     │ 毒舌的     │ 专业的       │   │
│              │ 未来的你   │ 未来的你   │ 未来的你   │ 未来的你     │   │
│  ────────────┼────────────┼────────────┼────────────┼──────────────│   │
│  coach       │ 温暖的     │ 活泼的     │ 毒舌的     │ 专业的       │   │
│              │ 教练       │ 教练       │ 教练       │ 教练         │   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 目标层级模型

```
                        ┌─────────────────┐
                        │   North Star    │  ← 终极愿景
                        │    (愿景)       │
                        └────────┬────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
        ┌──────────┐      ┌──────────┐      ┌──────────┐
        │  Goal 1  │      │  Goal 2  │      │  Goal 3  │  ← 核心目标 (最多3个)
        │ 创作自由 │      │ 家庭幸福 │      │ 身心健康 │     用户自由设定
        └────┬─────┘      └────┬─────���      └────┬─────┘
             │                 │                 │
             └─────────────────┼─────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Quarterly Focus   │  ← 季度聚焦
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Monthly Project   │  ← 月度项目 (Boss战)
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Weekly Rocks     │  ← 周大石头
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Daily Actions    │  ← 每日杠杆
                    └─────────────────────┘

  横向支撑：
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  Anti-Vision │  │   Identity   │  │  Principles  │
  │   (反愿景)   │  │  (身份设计)  │  │   (原则)     │
  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 2. 数据结构定义

### 2.1 存储位置

```
unified_profiles.profile.life_context._paths["lifecoach"]
```

### 2.2 完整结构

```json
{
  "lifecoach": {
    "content": {
      "system": { ... },
      "north_star": { ... },
      "goals": [ ... ],
      "roadmap": { ... },
      "current": { ... },
      "identity": { ... },
      "progress": { ... },
      "journal": [ ... ]
    },
    "version": 1,
    "updated_at": "2026-01-19T10:30:00Z"
  }
}
```

### 2.3 各部分详细定义

#### 2.3.0 System (系统配置)

Lifecoach 的系统级配置，包括方法论选择、角色设定、自动化选项。

```json
{
  "system": {
    "active_framework": "dankoe",
    "persona": "future_self",
    "auto_breakdown": true,
    "daily_checkin": true,
    "weekly_review": true,
    "initialized_at": "2026-01-15T10:00:00Z"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| active_framework | string | 是 | 当前使用的方法论 (dankoe/covey/okr)，用户同时只能选一套 |
| persona | string | 是 | 系统角色 (future_self/coach)，见 1.2 语气与角色分层 |
| auto_breakdown | boolean | 否 | 是否启用自动拆解（用户设定愿景后系统自动生成路径） |
| daily_checkin | boolean | 否 | 是否启用每日签到提醒 |
| weekly_review | boolean | 否 | 是否启用周复盘提醒 |
| initialized_at | string | 否 | 首次初始化时间 |

**方法论说明：**

| 方法论 | 核心特点 | 适合人群 |
|-------|---------|---------|
| dankoe | 愿景/反愿景驱动，身份转换，每日杠杆 | 创作者、自由职业者 |
| covey | 使命宣言，角色平衡，大石头 | 多角色平衡者、管理者 |
| okr | 目标与关键结果，季度迭代 | 目标导向者、团队协作 |

**自动拆解流程：**

```
用户设定愿景 → 系统自动生成路径 → 用户确认/调整 → 保存
     │                │                  │
     ▼                ▼                  ▼
  north_star    roadmap (草稿)      roadmap (确认)
```

#### 2.3.1 North Star (北极星)

终极方向，包含愿景、反愿景、使命、原则。当 `system.persona = future_self` 时，`vision_scene` 用于构建"来自未来的你"的口吻。

```json
{
  "north_star": {
    "vision": "一个通过创作影响百万人、时间自由、家庭幸福的人",
    "vision_scene": "我现在坐在海边的工作室里，刚完成今天的写作。窗外是蓝色的大海，下午三点，我准备去接孩子放学...",
    "vision_timeframe": "3年后",
    "anti_vision": "一个为了安全感困在无意义工作中、与家人疏远的人",
    "mission": "通过清晰的思考和写作，帮助人们设计自己的人生",
    "principles": [
      "健康第一",
      "家庭优先于事业",
      "诚实透明"
    ],
    "details": {
      "anti_scene": "早上被闹钟惊醒，挤地铁上班，晚上加班到深夜..."
    },
    "source": "dankoe",
    "created_at": "2026-01-15",
    "updated_at": "2026-01-15"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| vision | string | 是 | 一句话愿景 |
| vision_scene | string | 否 | 愿景场景描述（用于 future_self 角色口吻） |
| vision_timeframe | string | 否 | 愿景时间框架 (1年后/3年后/5年后) |
| anti_vision | string | 否 | 一句话反愿景 |
| mission | string | 否 | Covey 使命宣言 |
| principles | string[] | 否 | 不可妥协的原则 |
| details | object | 否 | 详细描述（方法论特有字段） |
| source | string | 否 | 来源方法论 (dankoe/covey/okr) |

**Future Self 角色说明：**

当 `persona = future_self` 时，系统会基于 `vision_scene` 以"来自未来的你"的口吻与用户对话：

```
示例对话（warm + future_self）：
"嘿，我是3年后的你。现在我正坐在海边工作室里，刚完成今天的写作。
 你现在做的每一个选择，都在把我们带向这里。今天的写作完成了吗？"

示例对话（roast + future_self）：
"我是3年后的你，正在海边喝咖啡。你呢？还在刷手机？
 醒醒，那个愿景不会自己实现。今天的杠杆行动，做了几个？"
```

#### 2.3.2 Goals (核心目标)

用户自由设定的核心目标，最多 3 个。融合了角色与目标的概念。

```json
{
  "goals": [
    {
      "id": "creative_freedom",
      "name": "创作自由",
      "description": "通过写作和创作实现时间与财务自由",
      "year_target": "出版第一本书，建立1万订阅者",
      "why": "这是我实现愿景的核心路径",
      "priority": 1
    },
    {
      "id": "family_happiness",
      "name": "家庭幸福",
      "description": "与家人建立深度连接",
      "year_target": "每周3次高质量陪伴，每月1次家庭活动",
      "why": "家人是我最重要的支持系统",
      "priority": 2
    },
    {
      "id": "health",
      "name": "身心健康",
      "description": "保持身体和心理的健康状态",
      "year_target": "每周运动3次，保持冥想习惯",
      "why": "健康是一切的基础",
      "priority": 3
    }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| id | string | 是 | 目标唯一标识 |
| name | string | 是 | 目标名称（用户自由命名） |
| description | string | 否 | 目标描述 |
| year_target | string | 是 | 年度目标 |
| why | string | 否 | 为什么这个目标重要 |
| priority | number | 否 | 优先级 (1最高) |

**约束：最多 3 个目标**，帮助用户聚焦。

#### 2.3.3 Roadmap (路线图)

从年度到季度的路径规划。

```json
{
  "roadmap": {
    "year": {
      "year": 2026,
      "theme": "创作元年",
      "end_state": "书稿完成，订阅者破万",
      "milestones": [
        {"q": 1, "milestone": "完成书稿前6章"},
        {"q": 2, "milestone": "完成全部书稿初稿"},
        {"q": 3, "milestone": "完成修订，开始出版流程"},
        {"q": 4, "milestone": "书籍出版，订阅者破万"}
      ]
    },
    "quarter": {
      "year": 2026,
      "q": 1,
      "focus": "完成书稿前6章",
      "key_results": [
        "每周完成1节内容",
        "建立每日写作习惯",
        "订阅者达到3000"
      ],
      "started_at": "2026-01-01"
    }
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| year.theme | string | 否 | 年度主题 |
| year.end_state | string | 是 | 年底期望状态 |
| year.milestones | array | 否 | 季度里程碑 |
| quarter.focus | string | 是 | 季度聚焦目标 |
| quarter.key_results | string[] | 否 | 关键结果 (OKR风格) |

#### 2.3.4 Current (当前焦点)

月/周/日的具体行动。

```json
{
  "current": {
    "month": {
      "project": "完成第3章",
      "goal_id": "creative_freedom",
      "deadline": "2026-01-31",
      "why": "这是书的核心章节，决定整体质量",
      "tasks": [
        {"task": "3.1 核心概念", "status": "done"},
        {"task": "3.2 案例分析", "status": "in_progress"},
        {"task": "3.3 实践指南", "status": "pending"}
      ],
      "started_at": "2026-01-01"
    },
    "week": {
      "start": "2026-01-20",
      "end": "2026-01-26",
      "rocks": [
        {"rock": "完成3.2节初稿", "goal_id": "creative_freedom", "done": false},
        {"rock": "周三带孩子去公园", "goal_id": "family_happiness", "done": false},
        {"rock": "跑步3次", "goal_id": "health", "done": false}
      ]
    },
    "daily": {
      "date": "2026-01-19",
      "levers": [
        "写作1小时 (6-7am)",
        "发1条推文",
        "读30分钟"
      ],
      "today_focus": "完成3.2节的第一个案例",
      "time_blocks": [
        {"time": "06:00-07:00", "task": "写作", "goal_id": "creative_freedom"},
        {"time": "18:00-19:00", "task": "陪孩子", "goal_id": "family_happiness"}
      ]
    }
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| month.project | string | 是 | 月度项目 (Boss战) |
| month.goal_id | string | 否 | 关联目标 |
| month.tasks | array | 否 | 项目拆解任务 |
| week.rocks | array | 是 | 本周大石头 |
| week.rocks[].goal_id | string | 否 | 关联目标 |
| daily.levers | string[] | 是 | 每日杠杆行动 |
| daily.time_blocks | array | 否 | 时间块规划 |

#### 2.3.5 Identity (身份)

身份转换追踪。

```json
{
  "identity": {
    "current": "我是那种会拖延重要事情的人",
    "becoming": "我正在���为那种面对恐惧行动的人",
    "target": "我是那种把创造放在第一位的人",
    "anchors": [
      "每天早起写作1小时",
      "周日复盘"
    ],
    "patterns": [
      {
        "behavior": "重要项目拖延",
        "hidden_goal": "保护自己免受失败评判",
        "cost": "错过机会，自我否定加深",
        "identified_at": "2026-01-10"
      }
    ],
    "updated_at": "2026-01-15"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| current | string | 否 | 当前身份认知 |
| becoming | string | 否 | 过渡身份 |
| target | string | 是 | 目标身份 |
| anchors | string[] | 否 | 锚定行为 |
| patterns | array | 否 | 已识别的行为模式 |

#### 2.3.6 Progress (进度)

整体进度追踪。

```json
{
  "progress": {
    "stage": "executing",
    "streak": 4,
    "last_checkin": "2026-01-19",
    "total_checkins": 15,
    "completions": {
      "north_star": true,
      "goals": true,
      "roadmap": true,
      "current_month": false,
      "current_week": true
    },
    "stats": {
      "weeks_tracked": 3,
      "avg_rocks_completion": 0.75,
      "best_streak": 7
    }
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| stage | string | 是 | 当前阶段 (planning/executing/reviewing) |
| streak | number | 否 | 连续签到天数 |
| last_checkin | string | 否 | 最后签到日期 |
| completions | object | 否 | 各部分完成状态 |
| stats | object | 否 | 统计数据 |

#### 2.3.7 Journal (日志)

复盘记录，不限制条数。

```json
{
  "journal": [
    {
      "date": "2026-01-19",
      "type": "daily",
      "mood": 7,
      "energy": 8,
      "rocks_completed": 2,
      "rocks_total": 3,
      "wins": ["完成早起写作", "发了一条高互动推文"],
      "struggles": ["下午刷手机1小时"],
      "insight": "刷手机是在逃避困难部分",
      "gratitude": "感谢妻子的支持",
      "tomorrow": "直接从最难的部分开始"
    },
    {
      "date": "2026-01-12",
      "type": "weekly",
      "week_start": "2026-01-06",
      "rocks_completed": 5,
      "rocks_total": 7,
      "goal_balance": {
        "creative_freedom": {"planned": 3, "done": 3},
        "family_happiness": {"planned": 2, "done": 1},
        "health": {"planned": 2, "done": 1}
      },
      "wins": ["连续5天早起", "完成了3.1节"],
      "struggles": ["周三完全没写", "运动计划没执行"],
      "insight": "周三会议太多，需要调整",
      "next_week_focus": "保护周三上午的写作时间",
      "adjustments": ["把运动改到早上写作后"]
    },
    {
      "date": "2026-01-01",
      "type": "monthly",
      "month": "2025-12",
      "project_completed": true,
      "key_achievements": ["完成第2章", "订阅者突破2000"],
      "lessons": ["低估了案例收集的时间"],
      "next_month_focus": "第3章是核心，要预留更多时间"
    }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| date | string | 是 | 日期 |
| type | string | 是 | 类型 (daily/weekly/monthly/quarterly) |
| mood | number | 否 | 心情 (1-10) |
| rocks_completed | number | 否 | 完成的大石头数 |
| goal_balance | object | 否 | 目标平衡统计 (周复盘) |
| insight | string | 否 | 洞察 |

---

## 3. 方法论映射

### 3.1 Dan Koe 映射

| Dan Koe 概念 | 数据位置 |
|-------------|---------|
| Vision (愿景) | north_star.vision |
| Anti-Vision (反愿景) | north_star.anti_vision |
| 1 Year Goal (年度目标) | roadmap.year.end_state |
| 1 Month Project (月度项目) | current.month.project |
| Daily Levers (每日杠杆) | current.daily.levers |
| Constraints (约束) | north_star.principles |
| Identity (身份) | identity.* |
| Patterns (模式) | identity.patterns |

### 3.2 Covey 7 Habits 映射

| Covey 概念 | 数据位置 |
|-----------|---------|
| Mission Statement (使命宣言) | north_star.mission |
| Goals (目标) | goals[] |
| Year Target (年度目标) | goals[].year_target |
| Big Rocks (大石头) | current.week.rocks |
| Weekly Planning (周计划) | current.week |
| Quadrant II (重要不紧急) | current.month.project |
| Principles (原则) | north_star.principles |

### 3.3 其他方法论扩展点

| 方法论 | 可存储位置 |
|-------|-----------|
| Ikigai | north_star.details.ikigai |
| OKR | roadmap.quarter.key_results |
| GTD | current.daily.time_blocks |
| Atomic Habits | identity.anchors |

---

## 4. 工具设计

### 4.1 读取工具

```yaml
- name: read_lifecoach_state
  description: 读取用户的 lifecoach 状态
  parameters:
    type: object
    properties:
      sections:
        type: array
        items:
          type: string
          enum: [north_star, goals, roadmap, current, identity, progress, journal]
        description: 要读取的部分，不传则读取全部
      journal_limit:
        type: integer
        default: 10
        description: journal 返回条数限制
```

### 4.2 写入工具

```yaml
- name: write_lifecoach_state
  description: 写入用户的 lifecoach 状态
  parameters:
    type: object
    required: [section, data]
    properties:
      section:
        type: string
        enum: [north_star, goals, roadmap, current, identity, progress]
        description: 要写入的部分
      data:
        type: object
        description: 要写入的数据
      merge:
        type: boolean
        default: true
        description: 是否合并（true）还是覆盖（false）
```

### 4.3 日志工具

```yaml
- name: add_journal_entry
  description: 添加一条复盘日志
  parameters:
    type: object
    required: [type]
    properties:
      type:
        type: string
        enum: [daily, weekly, monthly, quarterly, insight]
      date:
        type: string
        description: 日期，默认今天
      mood:
        type: integer
        minimum: 1
        maximum: 10
      energy:
        type: integer
        minimum: 1
        maximum: 10
      rocks_completed:
        type: integer
      rocks_total:
        type: integer
      goal_balance:
        type: object
        description: 目标平衡统计
      wins:
        type: array
        items:
          type: string
      struggles:
        type: array
        items:
          type: string
      insight:
        type: string
      tomorrow:
        type: string
      next_week_focus:
        type: string
```

### 4.4 进度更新工具

```yaml
- name: update_progress
  description: 更新进度状态
  parameters:
    type: object
    properties:
      checkin:
        type: boolean
        description: 是否记录签到
      complete_rock:
        type: string
        description: 完成的大石头描述
      complete_task:
        type: string
        description: 完成的月度任务
```

---

## 5. 使用流程

### 5.1 首次使用流程

```
1. 北极星设定 (Phase 1)
   ├── 选择方法论: Dan Koe / Covey / OKR
   ├── 执行协议: 反愿景 → 愿景 → 原则
   └── 写入: north_star

2. 核心目标设定 (Phase 2)
   ├── 设定核心目标 (最多3个)
   ├── 每个目标设定年度目标
   └── 写入: goals, roadmap.year

3. 季度规划 (Phase 3)
   ├── 确定季度聚焦
   ├── 设定关键结果
   └── 写入: roadmap.quarter

4. 月度项目 (Phase 4)
   ├── 确定本月 Boss
   ├── 拆解任务
   └── 写入: current.month

5. 周计划 (Phase 5)
   ├── 选择大石头 (按目标平衡)
   └── 写入: current.week

6. 每日执行 (Phase 6)
   ├── 确认今日杠杆
   └── 写入: current.daily
```

### 5.2 日常陪伴流程

```
每日早晨 (默认开启):
├── 读取: current.daily, progress
├── 推送: 今日杠杆提醒
├── 用户响应后: 更新 progress.streak
└── 晚间可选: 添加 journal (daily)

每周日晚:
├── 读取: current.week, goals
├── 引导: 周复盘
├── 添加: journal (weekly)
└── 规划: 下周 rocks

每月初:
├── 读取: current.month, roadmap.quarter
├── 引导: 月度复盘
├── 添加: journal (monthly)
└── 规划: 下月 project

每季度初:
├── 读取: roadmap, goals
├── 引导: 季度复盘
├── 添加: journal (quarterly)
└── 更新: roadmap.quarter
```

---

## 6. 版本历史

| 版本 | 日期 | 变更 |
|-----|------|------|
| 2.2 | 2026-01-19 | 简化：roles → goals，最多3个目标，角色与目标融合 |
| 2.1 | 2026-01-19 | 新增：system 配置、语气与角色分层、自动拆解流程、vision_scene |
| 2.0 | 2026-01-19 | 重构：新增 roles, roadmap, 层级化 current |
| 1.0 | 2026-01-15 | 初版：基于 Dan Koe 的扁平结构 |
