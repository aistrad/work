# VibeLife Core Tools v3

> **设计原则**: Core Skill 提供完全通用的原子工具，零业务语义
> **业务语义**: 在 scenarios/ 和各 Skill 的 SKILL.md 中定义

---

## 1. 架构总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          工具分层架构 v3                                      │
└─────────────────────────────────────────────────────────────────────────────┘

Core Skill (基础层) - 零业务语义
├── 数据工具 (CRUD)
│   ├── read_user_data      # 读取任意路径数据
│   ├── write_user_data     # 写入任意路径数据
│   ├── query_user_data     # 查询数据
│   └── delete_user_data    # 删除数据
│
├── 触发器工具
│   ├── create_trigger      # 创建触发器
│   ├── list_triggers       # 列出触发器
│   └── cancel_trigger      # 取消触发器
│
└── 展示工具 (通用视图)
    └── show_card           # 通用卡片渲染

─────────────────────────────────────────────────────────────────────────────

业务层 - 在 scenarios/ 和 Skill SKILL.md 中定义
├── scenarios/goal_tracking.md    # 定义目标追踪的 SOP 和路径规范
├── scenarios/daily_routine.md    # 定义日常打卡的 SOP
├── skills/bazi/SKILL.md          # 定义八字相关路径和卡片
└── skills/zodiac/SKILL.md        # 定义星盘相关路径和卡片
```

---

## 2. Core 数据工具

### 2.1 read_user_data

```yaml
name: read_user_data
description: 读取用户存储的数据
parameters:
  path:
    type: string
    description: 数据路径 (由调用方自行定义路径规范)
    required: true
returns:
  status: success | not_found | error
  path: string
  data: object | null
  version: integer
```

### 2.2 write_user_data

```yaml
name: write_user_data
description: 写入用户数据 (创建或更新)
parameters:
  path:
    type: string
    description: 数据路径
    required: true
  content:
    type: object
    description: JSON 内容
    required: true
  expected_version:
    type: integer
    description: 乐观锁版本号 (可选，用于并发控制)
returns:
  status: success | conflict | error
  path: string
  version: integer
```

### 2.3 query_user_data

```yaml
name: query_user_data
description: 查询用户数据
parameters:
  path_prefix:
    type: string
    description: 路径前缀
  filters:
    type: object
    description: JSONB 过滤条件
  sort_by:
    type: string
    description: 排序字段
  limit:
    type: integer
    default: 20
returns:
  status: success | error
  count: integer
  results: array<{path, content, version, updated_at}>
```

### 2.4 delete_user_data

```yaml
name: delete_user_data
description: 删除用户数据
parameters:
  path:
    type: string
    required: true
returns:
  status: success | not_found | error
```

---

## 3. Core 触发器工具

### 3.1 create_trigger

```yaml
name: create_trigger
description: 创建触发器 (定时提醒 / 条件触发 / 定时任务)
parameters:
  trigger_type:
    type: string
    enum: [reminder, condition, schedule]
    required: true
  title:
    type: string
    required: true
  description:
    type: string

  # 定时类参数 (reminder / schedule)
  schedule:
    type: string
    description: 调度表达式 (HH:MM 或 cron)
  schedule_type:
    type: string
    enum: [once, daily, weekly, cron]

  # 条件类参数 (condition)
  condition:
    type: object
    description: |
      触发条件规则，支持:
      - type: "data_match" - 数据匹配触发
      - type: "count" - 计数达标触发
      - type: "deadline" - 截止日期触发
    properties:
      type: { type: string, enum: [data_match, count, deadline] }
      watch_path: { type: string }
      rule: { type: object }

  # 触发动作
  action:
    type: object
    required: true
    description: |
      触发后执行的动作:
      - type: "message" - 发送消息
      - type: "generate" - 生成内容
      - type: "update" - 更新数据
      - type: "notify" - 推送通知
    properties:
      type: { type: string, enum: [message, generate, update, notify] }
      params: { type: object }

  # 关联
  source_path:
    type: string
    description: 关联的数据路径

returns:
  status: success | error
  trigger_id: string
  next_trigger_at: string
```

### 3.2 list_triggers

```yaml
name: list_triggers
description: 列出用户触发器
parameters:
  trigger_type:
    type: string
    description: 类型过滤 (可选)
  status:
    type: string
    default: active
    enum: [active, paused, completed, all]
returns:
  status: success | error
  count: integer
  triggers: array
```

### 3.3 cancel_trigger

```yaml
name: cancel_trigger
description: 取消触发器
parameters:
  trigger_id:
    type: string
    required: true
returns:
  status: success | not_found
```

---

## 4. Core 展示工具: show_card

**核心原则**: 卡片类型是通用视图类型，不包含业务语义。

```yaml
name: show_card
description: 在聊天中渲染可视化卡片

parameters:
  card_type:
    type: string
    description: 通用视图类型
    enum:
      # 基础视图
      - list              # 列表视图
      - tree              # 树状视图
      - table             # 表格视图
      - timeline          # 时间线视图

      # 交互视图
      - form              # 表单视图 (可交互)
      - select            # 选择视图 (单选/多选)

      # 数据可视化
      - chart             # 图表 (由 chart_type 细分)
      - progress          # 进度展示
      - counter           # 计数器

      # 反馈视图
      - modal             # 模态框
      - toast             # 轻提示

      # 自定义 (Skill 注册)
      - custom            # 自定义组件 (需指定 component_id)

    required: true

  data_source:
    type: object
    description: 数据来源
    properties:
      type:
        enum: [path, inline, api]
        description: |
          - path: 从 user_data_store 读取
          - inline: 直接传入数据
          - api: 调用后端 API
      path:
        type: string
        description: 数据路径 (当 type=path)
      data:
        type: object
        description: 内联数据 (当 type=inline)
      endpoint:
        type: string
        description: API 端点 (当 type=api)
    required: true

  options:
    type: object
    description: 渲染选项
    properties:
      title: { type: string }
      subtitle: { type: string }
      interactive: { type: boolean, default: false }
      # 视图特定选项
      chart_type: { type: string, enum: [bar, line, pie, radar] }
      component_id: { type: string, description: "自定义组件 ID" }
      columns: { type: array, description: "table 视图的列定义" }
      fields: { type: array, description: "form 视图的字段定义" }

returns:
  status: success | error
  card_type: string
  data: object
  model_output: string
```

---

## 5. 工具返回规范

所有 Core 工具返回统一格式：

```typescript
interface ToolResult {
  // 必须
  status: 'success' | 'error' | 'not_found' | 'conflict' | 'pending';

  // 数据工具返回
  path?: string;
  data?: any;
  version?: number;

  // 展示工具返回
  card_type?: string;

  // 模型输出 (可选，减少 token)
  model_output?: string;

  // 错误信息
  error?: string;
}
```

---

## 6. 数据流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              数据流程                                         │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────────┐
                              │      Tool Call      │
                              │  (from LLM Agent)   │
                              └──────────┬──────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
        ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
        │  read_user_data   │ │  write_user_data  │ │    show_card      │
        └─────────┬─────────┘ └─────────┬─────────┘ └─────────┬─────────┘
                  │                     │                     │
                  ▼                     ▼                     ▼
        ┌─────────────────────────────────────────────────────────────────┐
        │                       Services Layer                             │
        │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
        │  │ UserDataService │ │ UserDataService │ │   CardService   │   │
        │  │     .read()     │ │    .write()     │ │   .render()     │   │
        │  └────────┬────────┘ └────────┬────────┘ └────────┬────────┘   │
        └───────────┼───────────────────┼───────────────────┼────────────┘
                    │                   │                   │
                    └───────────────────┼───────────────────┘
                                        │
                                        ▼
        ┌─────────────────────────────────────────────────────────────────┐
        │                        PostgreSQL                                │
        │   ┌─────────────────────────────────────────────────────────┐   │
        │   │              user_data_store                             │   │
        │   │  user_id | data_path | content | version | updated_at   │   │
        │   └─────────────────────────────────────────────────────────┘   │
        │   ┌─────────────────────────────────────────────────────────┐   │
        │   │              user_triggers                               │   │
        │   │  user_id | type | schedule | condition | action         │   │
        │   └─────────────────────────────────────────────────────────┘   │
        └─────────────────────────────────────────────────────────────────┘
```

---

## 7. 前端卡片注册表

```typescript
// CardRegistry.ts - 通用视图组件

const CORE_CARD_TYPES = {
  // 基础视图
  LIST: 'list',
  TREE: 'tree',
  TABLE: 'table',
  TIMELINE: 'timeline',

  // 交互视图
  FORM: 'form',
  SELECT: 'select',

  // 数据可视化
  CHART: 'chart',
  PROGRESS: 'progress',
  COUNTER: 'counter',

  // 反馈视图
  MODAL: 'modal',
  TOAST: 'toast',

  // 自定义
  CUSTOM: 'custom',
} as const;

// Skill 可以注册自定义组件
CardRegistry.registerCustom('bazi_chart', BaziChartCard);
CardRegistry.registerCustom('zodiac_chart', ZodiacChartCard);
CardRegistry.registerCustom('tarot_spread', TarotSpreadCard);

// 渲染流程
function renderToolResult(result: ToolResult) {
  const { card_type, data, options } = result;

  if (card_type === 'custom' && options?.component_id) {
    // 自定义组件
    return CardRegistry.renderCustom(options.component_id, data);
  }

  if (CardRegistry.has(card_type)) {
    // 通用组件
    return CardRegistry.render(card_type, data, options);
  }

  return null;
}
```

---

## 8. 业务场景示例 (scenarios/)

业务语义在 scenarios/ 中定义，不在 Core Tools。

### 示例: scenarios/goal_tracking.md

```markdown
---
id: goal_tracking
triggers: [目标, 计划, 任务, 监督, 打卡]
path_convention:
  year_goal: "goals/{year}/year"
  quarter_goal: "goals/{year}/q{quarter}"
  daily_plan: "plans/daily/{date}"
  checkin: "checkins/{date}"
card_mapping:
  tree: goals/*
  list: plans/*
  form: checkins (interactive)
---

# 目标追踪场景

## 路径规范
- `goals/{year}/year` - 年度目标
- `goals/{year}/q{quarter}` - 季度目标
- `plans/daily/{date}` - 每日计划
- `checkins/{date}` - 打卡记录

## 工具组合示例

用户: "帮我设定2026年目标"

1. write_user_data(path="goals/2026/year", content={...})
2. show_card(card_type="tree", data_source={type:"path", path:"goals/2026"})

用户: "今天打卡"

1. read_user_data(path="plans/daily/2026-01-18")
2. show_card(
     card_type="form",
     data_source={type:"inline", data:{tasks:[], date:"2026-01-18"}},
     options={interactive: true, fields: [...]}
   )
3. [用户交互后] write_user_data(path="checkins/2026-01-18", content={...})
```

### 示例: skills/bazi/SKILL.md

```markdown
---
id: bazi
custom_cards:
  - bazi_chart
  - bazi_fortune
path_convention:
  chart_data: "bazi/chart"
  fortune_data: "bazi/fortune/{date}"
---

# 八字技能

## 自定义卡片
注册到 CardRegistry:
- bazi_chart: 八字命盘展示
- bazi_fortune: 运势展示

## 工具组合

用户: "展示我的八字"

1. show_card(
     card_type="custom",
     data_source={type:"api", endpoint:"/bazi/chart"},
     options={component_id: "bazi_chart"}
   )
```

---

## 9. 实现阶段

| 阶段 | 内容 | 产出 |
|------|------|------|
| **P1** | Core 数据工具 | UserDataService CRUD |
| **P2** | Core 触发器工具 | TriggerService |
| **P3** | Core 展示工具 | CardService + 通用组件 |
| **P4** | 前端 CardRegistry | list/tree/form/table 组件 |
| **P5** | Skill 自定义卡片 | bazi_chart, zodiac_chart 等 |
| **P6** | 业务场景 | scenarios/*.md |

---

## 10. 注意事项

1. **Core 零业务语义**: Core Tools 不包含任何业务特定的概念
2. **路径自由**: data_path 完全由调用方定义，Core 不做校验
3. **卡片类型通用**: card_type 是视图类型，不是业务类型
4. **Skill 扩展**: Skill 通过 custom + component_id 注册自定义卡片
5. **场景定义**: 业务路径规范、卡片映射在 scenarios/ 中定义
