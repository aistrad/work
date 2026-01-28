# VibeLife 复杂组合指令工具设计方案

> 目标：让用户能完成 "年目标拆解 + 每日计划 + 持续监督" 等复杂指令

---

## 核心设计思路

**两层架构**：Core Skill 提供原子工具，子技能组合使用

```
Core Skill (基础层)
├── 原子化工具
│   ├── read_user_data    # 读取用户数据
│   ├── write_user_data   # 写入用户数据
│   ├── query_user_data   # 查询用户数据
│   ├── schedule_reminder # 设置提醒
│   └── cancel_reminder   # 取消提醒
│
└── 子技能 (组合层) - 在 scenarios/ 中定义
    ├── goal_tracking     # 目标追踪 - 组合 read/write/schedule
    ├── relationship_calc # 关系计算 - 组合 read/query + bazi/zodiac
    └── time_window       # 时间窗口推荐 - 组合 query + bazi/zodiac
```

**执行流程**:
```
用户说 "这是我的年目标，帮我拆解"
    ↓
1. Core Skill 路由到 goal_tracking 子技能
2. LLM 调用 write_user_data 存储目标
3. LLM 调用 decompose 逻辑分解目标
4. LLM 调用 schedule_reminder 设置每日提醒
5. 用户可通过 read_user_data / write_user_data 编辑计划
```

---

## 实现方案

### 1. 数据模型

**设计原则**：用户个性化数据存 JSON 文件 + 数据库双向同步

**新增 1 张表** (简化设计):

| 表名 | 用途 |
|------|------|
| `user_data_store` | 用户 JSON 数据存储 (goals, tasks, files 全部用 JSON) |

```sql
CREATE TABLE user_data_store (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES vibe_users(id),
    data_type   VARCHAR(50) NOT NULL,  -- goals, tasks, checkins, files
    data_path   VARCHAR(500) NOT NULL, -- 虚拟路径: goals/2026/year.json
    content     JSONB NOT NULL,        -- JSON 数据
    version     INTEGER DEFAULT 1,
    updated_at  TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, data_path)
);
```

**与文件目录同步**:
```
数据库 user_data_store ←→ 虚拟文件系统 /users/{user_id}/
```
- 用户编辑文件 → 自动同步到数据库
- 数据库更新 → 自动写入文件
- 支持未来复杂场景扩展

**Profile 扩展**:
```json
{
  "goal_tracking": {
    "last_checkin": "2026-01-17",
    "streak_days": 5,
    "reminder_time": "08:00",
    "enable_fortune_insights": true  // 命理整合开关
  }
}
```

### 2. 扩展 Core Skill

**不新建独立 Skill**，而是扩展 `skills/core/`:

```
skills/core/
├── SKILL.md              # 更新：添加子技能描述
├── tools/
│   ├── tools.yaml        # 新增原子工具
│   └── handlers.py       # 新增处理器
├── services/
│   ├── user_data.py      # 新增：用户数据读写服务
│   ├── reminder.py       # 新增：提醒调度服务
│   └── decomposer.py     # 新增：LLM 分解服务
├── scenarios/
│   ├── goal_tracking.md  # 新增：目标追踪子技能
│   ├── relationship.md   # 新增：关系计算子技能
│   └── time_window.md    # 新增：时间窗口子技能
└── reminders.yaml        # 新增：定时提醒配置
```

**子技能定义示例** (`scenarios/goal_tracking.md`):
```markdown
---
id: goal_tracking
name: 目标追踪
triggers: [目标, 计划, 任务, 监督我, 打卡]
required_tools: [read_user_data, write_user_data, schedule_reminder]
optional_tools: [calculate_bazi, show_zodiac_transit]  # 命理整合
---

你是用户的目标管理教练。帮助用户：
1. 设定 SMART 目标
2. 分解为可执行任务
3. 每日监督和激励

## 工具使用规则
| 用户意图 | 调用工具 |
|---------|---------|
| 设定目标 | write_user_data(path="goals/...") |
| 查看进度 | read_user_data + 计算完成率 |
| 设置提醒 | schedule_reminder |
```

### 3. 核心原子工具设计 (Core Skill)

**通用数据工具** (所有子技能复用):

| 工具 | 类型 | 用途 |
|------|------|------|
| `read_user_data` | action | 读取用户 JSON 数据 |
| `write_user_data` | action | 写入用户 JSON 数据 |
| `query_user_data` | action | 查询用户数据 (支持过滤) |
| `delete_user_data` | action | 删除用户数据 |

**提醒工具**:

| 工具 | 类型 | 用途 |
|------|------|------|
| `schedule_reminder` | action | 设置定时提醒 |
| `list_reminders` | action | 列出用户的提醒 |
| `cancel_reminder` | action | 取消提醒 |

**展示工具** (子技能特定):

| 工具 | 类型 | 用途 | 子技能 |
|------|------|------|-------|
| `show_goal_tree` | display | 展示目标树 | goal_tracking |
| `show_daily_plan` | display | 展示今日计划 | goal_tracking |
| `show_checkin_form` | display | 打卡复盘表单 | goal_tracking |
| `show_compatibility` | display | 关系匹配结果 | relationship |
| `show_time_windows` | display | 最佳时间窗口 | time_window |

### 4. 用户文件系统

**虚拟路径结构**:
```
/users/{user_id}/
├── goals/2026/
│   ├── year_goal.md       # 年度目标文档
│   └── months/01.md       # 月度分解
├── plans/daily/
│   └── 2026-01-18.md      # 每日计划
└── reflections/
    └── week_01.md         # 周复盘
```

**文件格式** (Markdown + YAML Frontmatter):
```markdown
---
id: goal_2026_001
title: 2026年职业突破
level: year
status: active
progress: 15
---

# 2026年职业突破

## 关键成果
1. [ ] Q1: 完成认证
2. [ ] Q2: 主导项目

## 我的笔记
...可自由编辑...
```

### 5. 定时提醒配置

**`skills/goals/reminders.yaml`**:

| 提醒 | 触发 | 内容 |
|------|------|------|
| 每日计划 | 早8点 | 今日任务预览 + 命理提示 |
| 每日复盘 | 晚9点 | 打卡提醒 |
| 周复盘 | 周日晚8点 | 本周总结 |
| 里程碑 | 截止前 7/3/1 天 | 目标到期提醒 |
| 连续打卡 | 7/14/21/30 天 | 庆祝激励 |

### 6. 前端卡片

| 卡片 | 功能 |
|------|------|
| `GoalTreeCard` | 可折叠目标树，进度条，快捷操作 |
| `DailyPlanCard` | 时间轴布局，任务勾选，拖拽排序 |
| `CheckinFormCard` | 任务完成勾选，精力评分，反思 |
| `GoalFileEditor` | Markdown 编辑器，实时预览 |

---

## 关键文件清单

**需修改**:
- `apps/api/stores/migrations/` - 新增 `user_data_store` 迁移
- `apps/api/skills/core/SKILL.md` - 添加子技能描述
- `apps/api/skills/core/tools/tools.yaml` - 新增原子工具
- `apps/api/skills/core/tools/handlers.py` - 新增处理器
- `apps/api/services/proactive/trigger_detector.py` - 添加目标截止检测

**需新建**:
- `apps/api/skills/core/services/user_data.py` - 用户数据服务
- `apps/api/skills/core/services/reminder.py` - 提醒服务
- `apps/api/skills/core/scenarios/goal_tracking.md` - 目标追踪子技能
- `apps/api/skills/core/scenarios/relationship.md` - 关系计算子技能
- `apps/api/skills/core/scenarios/time_window.md` - 时间窗口子技能
- `apps/web/src/skills/core/cards/` - 新卡片组件

**参考文件**:
- `apps/api/skills/bazi/tools/tools.yaml` - 工具定义模板
- `apps/api/services/agent/tool_registry.py` - 工具注册机制
- `apps/api/services/proactive/engine.py` - 提醒引擎

---

## 实现阶段

| 阶段 | 内容 | 产出 |
|------|------|------|
| P1 | 数据模型 + 原子工具 | user_data_store 表 + read/write/query 工具 |
| P2 | goal_tracking 子技能 | 目标分解、每日计划生成 |
| P3 | 提醒工具 + Worker | schedule_reminder + 每日推送 |
| P4 | 前端卡片 | goal_tree, daily_plan, checkin 卡片 |
| P5 | 扩展子技能 | relationship, time_window |

---

## 设计决策 (已确认)

| 问题 | 决策 |
|------|------|
| 数据存储 | JSON 文件 + 数据库双向同步，支持复杂场景扩展 |
| LLM 模型 | DeepSeek (成本低、速度快) |
| 命理整合 | 用户可选开关 (`enable_fortune_insights`) |

---

## 下一步行动

0. **输出设计文档到 `/home/aiscend/work/vibelife/docs/archive/v7/COMPOSITE-TOOLS.md`**
1. 创建 `user_data_store` 数据库迁移
2. 在 `skills/core/tools/` 新增原子工具: `read_user_data`, `write_user_data`, `schedule_reminder`
3. 在 `skills/core/scenarios/` 创建子技能: `goal_tracking.md`
4. 实现 `services/user_data.py` 数据读写服务
5. 接入定时提醒系统
