# Proactive 模块设计规范 v2.0

> 更新日志:
> - v2.0 (2026-01-19): 统一配置格式，新增触发器类型，添加 global_config

## 概述

Proactive 模块负责主动触达用户，通过推送通知增强用户粘性和业务转化。本模块与 Skill Management 深度集成，实现订阅感知的精准推送。

## 核心原则

| 原则 | 说明 |
|-----|------|
| 订阅感知 | 根据 Skill 订阅状态决定是否推送 |
| 配置独立 | reminders.yaml 独立于 SKILL.md，便于运营调整 |
| Skill 级开关 | 用户通过 Skill 总开关控制推送，简化设置 |
| 对话引导 | 每条推送提供一键开始对话入口 |
| **配置驱动** | 所有内容生成通过 rules/*.md，避免代码硬编码 |

## 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                    Proactive 架构                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │  Scheduler  │───▶│   Engine    │───▶│  Delivery   │        │
│  │  (Cron)     │    │             │    │  (Push)     │        │
│  └─────────────┘    └──────┬──────┘    └─────────────┘        │
│                            │                                   │
│           ┌────────────────┼────────────────┐                  │
│           │                │                │                  │
│           ▼                ▼                ▼                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Trigger    │  │  Content    │  │ Subscription │            │
│  │  Detector   │  │  Generator  │  │   Checker    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│         │                │                │                    │
│         │                │                │                    │
│         ▼                ▼                ▼                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ reminders   │  │   rules/    │  │ user_skill  │            │
│  │   .yaml     │  │   *.md      │  │ subscriptions│           │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 配置规范 v2.0

### reminders.yaml 结构

reminders.yaml 独立存放于 `apps/api/skills/{skill_id}/reminders.yaml`，与 SKILL.md 通过 skill_id 关联。

```yaml
# v2.0 配置格式
skill_id: bazi
enabled: true

# 使用 reminders (不是 reminder_types)
reminders:
  - id: daily_fortune
    name: 每日运势
    trigger:
      type: time_based
      schedule: "0 4 * * *"
    content:
      generator: rules/daily-fortune.md  # 必须使用 rules/ 路径
      card_type: DailyFortuneCard
      # 对话引导配置 (必须)
      suggested_prompt: "想了解今天的运势详情？"
      quick_actions:
        - label: "今日宜忌"
          prompt: "今天适合做什么？有什么需要注意的？"
    priority: medium

# 全局配置
global_config:
  default_push_hour: 4      # 默认推送时间
  cooldown_hours: 24        # 同类型冷却时间
```

### 必须字段

| 字段 | 类型 | 说明 |
|-----|------|------|
| skill_id | string | Skill 标识符，与 SKILL.md 一致 |
| enabled | boolean | 是否启用推送 |
| reminders | array | 提醒配置列表 |
| reminders[].id | string | 提醒唯一标识 (snake_case) |
| reminders[].name | string | 提醒名称 (中文) |
| reminders[].trigger | object | 触发配置 |
| reminders[].content | object | 内容配置 |
| reminders[].content.generator | string | **必须** 使用 `rules/*.md` 路径 |
| reminders[].content.suggested_prompt | string | **必须** 对话引导提示语 |
| reminders[].content.quick_actions | array | **必须** 快捷操作按钮 |

---

## 触发器类型

### 1. time_based - 定时触发

```yaml
trigger:
  type: time_based
  schedule: "0 4 * * *"     # Cron 表达式
  time_window: "04:00-06:00" # 可选: 允许的时间窗口
  condition: has_active_goals # 可选: 前置条件
```

### 2. event_based - 事件触发

```yaml
trigger:
  type: event_based
  event: birthday           # 事件类型
  advance_days: [7, 0]      # 提前多少天触发
```

**支持的事件类型:**

| 事件 | 说明 | 来源 |
|-----|------|------|
| birthday | 阳历生日 | unified_profiles |
| lunar_birthday | 农历生日 | unified_profiles |
| dayun_change | 大运交接 | bazi.services |
| liunian_change | 流年交接 | bazi.services |
| solar_term | 节气 | global_events |
| lunar_phase | 月相 (新月/满月) | zodiac.services |
| mercury_retrograde | 水逆 | zodiac.services |
| significant_transit | 重要行运 | zodiac.services |
| checkin_streak | 连续打卡里程碑 | core |
| practice_milestone | 累计练习里程碑 | mindfulness |
| goal_deadline_approaching | 目标截止日期临近 | core |

### 3. threshold_based - 阈值触发

```yaml
trigger:
  type: threshold_based
  metric: daily_fortune_score
  condition: "<"
  threshold: 40
  cooldown_days: 7          # 冷却期，避免重复推送
```

**支持的指标:**

| 指标 | 说明 | 来源 |
|-----|------|------|
| daily_fortune_score | 每日运势分数 | bazi.services |
| health_score | 健康指数 | zodiac.services |
| streak_days | 连续打卡天数 | core |
| total_minutes | 累计练习时长 | mindfulness |

### 4. emotion_based - 情绪触发 (Mindfulness 专用)

```yaml
trigger:
  type: emotion_based
  emotion: anxiety
  keywords:
    - 焦虑
    - 着急
    - 担心
```

**支持的情绪类型:**

| 情绪 | 关键词示例 |
|-----|-----------|
| anxiety | 焦虑、着急、担心、紧张 |
| anger | 生气、愤怒、火大、气死 |
| sadness | 难过、悲伤、想哭、失落 |
| overwhelm | 崩溃、受不了、压力大 |

### 5. skill_completion - Skill 完成触发

```yaml
trigger:
  type: skill_completion
  preceding_skill: bazi
  condition:
    session_depth: ">= 3"
    topic_depth: deep
```

---

## Subscription 集成

### 推送决策逻辑

```python
async def _should_send_to_user(
    self,
    user_id: UUID,
    skill_id: str,
) -> bool:
    """
    检查是否应该发送推送
    - 粒度: Skill 级别总开关
    """
    # 1. 获取 Skill 元数据
    skill_meta = load_skill_metadata(skill_id)
    category = skill_meta.category if skill_meta else "professional"

    # 2. Core Skill 始终发送
    if category == "core":
        return True

    # 3. 获取用户订阅状态
    subscription = await SkillSubscriptionRepo.get(user_id, skill_id)

    # 4. Default Skill: 检查是否取消订阅或关闭推送
    if category == "default":
        if subscription and subscription.status == "unsubscribed":
            return False
        if subscription and not subscription.push_enabled:
            return False
        return True

    # 5. Professional Skill: 需要有效订阅且开启推送
    if not subscription or subscription.status != "subscribed":
        return False

    return subscription.push_enabled
```

### 订阅状态与推送关系

| Skill 类别 | 订阅状态 | push_enabled | 是否推送 |
|-----------|---------|--------------|---------|
| core | - | - | ✅ 始终推送 |
| default | 无/subscribed | true (默认) | ✅ 推送 |
| default | unsubscribed | - | ❌ 不推送 |
| default | subscribed | false | ❌ 不推送 |
| professional | subscribed | true | ✅ 推送 |
| professional | 无/unsubscribed | - | ❌ 不推送 |
| professional | subscribed | false | ❌ 不推送 |

---

## ContentGenerator 设计

### 配置驱动原则

**所有内容生成必须通过 rules/*.md 配置，禁止在代码中硬编码文案。**

```python
class ContentGenerator:
    """配置驱动的内容生成器"""

    async def generate(
        self,
        task: ReminderTask,
        profile: Dict[str, Any],
        config: Dict[str, Any],
    ) -> ReminderContent:
        """
        流程:
        1. 加载 content.generator 指定的 rule 文件
        2. 使用 rule 中的分析要点和检索 Query
        3. 调用 LLM 生成个性化内容
        4. 附加对话引导信息
        """
        generator_path = config.get("content", {}).get("generator", "")

        # 必须使用 rules/ 路径
        if not generator_path.startswith("rules/"):
            raise ValueError(f"generator must use rules/ path: {generator_path}")

        rule = load_rule(task.skill_id, generator_path)
        content = await self._generate_from_rule(task, profile, rule)

        # 附加对话引导
        content.suggested_prompt = config["content"]["suggested_prompt"]
        content.quick_actions = config["content"]["quick_actions"]

        return content
```

---

## 通知数据结构

### ProactiveNotification

```typescript
interface ProactiveNotification {
  id: string;
  skill_id: string;
  reminder_type: string;
  title: string;
  content: {
    body: string;
    fortune_hint?: string;
    action_tip?: string;
    // 对话引导 (必须)
    suggested_prompt: string;
    quick_actions: Array<{
      label: string;
      prompt: string;  // 点击后发送的消息
    }>;
  };
  card_type?: string;
  created_at: string;
  read_at?: string;
}
```

---

## 目录结构

```
apps/api/
├── skills/{skill_id}/
│   ├── SKILL.md
│   ├── reminders.yaml        # Proactive 配置 (v2.0 格式)
│   ├── rules/
│   │   ├── daily-fortune.md  # 推送内容生成规则
│   │   └── ...
│   └── tools/
│
├── services/
│   └── proactive/
│       ├── engine.py         # 集成 Subscription 检查
│       ├── trigger_detector.py  # 支持 5 种触发器
│       ├── content_generator.py  # 配置驱动生成
│       └── __init__.py
│
└── workers/
    └── proactive_worker.py

apps/web/
├── components/
│   └── layout/
│       └── NotificationBell.tsx  # 支持 quick_actions
│
└── app/
    └── chat/
        └── page.tsx              # 支持 skill/prompt 参数
```

---

## 迁移指南 (v1.0 → v2.0)

### 1. 配置格式迁移

```yaml
# v1.0 (旧)
reminder_types:
  - id: daily_fortune
    ...

# v2.0 (新)
reminders:
  - id: daily_fortune
    ...
```

### 2. 添加必须字段

每个 reminder 必须包含:
- `content.generator`: 使用 `rules/*.md` 路径
- `content.suggested_prompt`: 对话引导提示
- `content.quick_actions`: 至少 1 个快捷操作

### 3. 添加 global_config

```yaml
global_config:
  default_push_hour: 4
  cooldown_hours: 24
```

### 4. 创建缺失的 rules 文件

参考 [MISSING_RULES.md](./MISSING_RULES.md) 补齐缺失的规则文件。

---

## API 接口

### 获取推送通知列表

```
GET /api/notifications
```

Response:
```json
{
  "items": [
    {
      "id": "uuid",
      "skill_id": "bazi",
      "reminder_type": "daily_fortune",
      "title": "今日运势",
      "content": {
        "body": "甲木日主，今日戊土当令...",
        "suggested_prompt": "想了解今天的运势详情？",
        "quick_actions": [
          {"label": "今日宜忌", "prompt": "今天适合做什么？"},
          {"label": "开运建议", "prompt": "今天如何提升运势？"}
        ]
      },
      "created_at": "2026-01-19T04:00:00Z"
    }
  ],
  "unread_count": 1
}
```

### 更新 Skill 推送开关

```
PUT /api/skills/{skill_id}/subscription
```

Request:
```json
{
  "push_enabled": false
}
```

---

## 相关文档

- [MISSING_RULES.md](./MISSING_RULES.md) - 缺失的 rules 文件清单
- [reminders-schema.yaml](./reminders-schema.yaml) - 配置 JSON Schema
- [README.md](./README.md) - 模块概览
