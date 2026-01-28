# VibeLife V8 系统架构文档

> Version: 8.0 | 2026-01-19
> 核心理念：AI 原生的个人成长陪伴平台

---

## 1. 产品定位

VibeLife 是一个 AI 原生的个人成长陪伴平台，通过多个专业 Skill 提供深度理解和主动关怀。

### 1.1 三大差异化

| 差异化 | 说明 |
|--------|------|
| **Deep Understanding** | 理解你这个人，而非只是问题 |
| **Proactive Agency** | 主动关心，而非等你开口 |
| **Infinite Extensibility** | 通过 Skills 无限扩展能力 |

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| **Simplicity** | 保持简单，避免过度工程 |
| **Config-Driven** | Skill 层配置驱动，平台层代码驱动 |
| **Single Source of Truth** | 工具定义、模型配置等只有一个数据源 |
| **DDD** | 领域驱动设计，每个 Skill 独立管理自己的服务 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VibeLife V8 Architecture                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐      ┌──────────────┐      ┌──────────────┐          │
│   │   Browser    │─────▶│   Next.js    │─────▶│  Python API  │          │
│   │  (AI SDK 4)  │      │   (Proxy)    │      │  (FastAPI)   │          │
│   └──────────────┘      └──────────────┘      └──────────────┘          │
│                                                      │                   │
│                         ┌────────────────────────────┼────────────────┐  │
│                         │                            ▼                │  │
│                         │   ┌────────────────────────────────────┐    │  │
│                         │   │            CoreAgent               │    │  │
│                         │   │     (Agentic Loop + Tool Calling)  │    │  │
│                         │   └────────────────────────────────────┘    │  │
│                         │              │              │               │  │
│                         │    ┌─────────┴──────┐      │               │  │
│                         │    ▼                ▼      ▼               │  │
│                         │ ┌────────┐  ┌────────────┐ ┌────────────┐  │  │
│                         │ │  Tool  │  │   Skill    │ │  Knowledge │  │  │
│                         │ │Registry│  │  Loader    │ │  (Cases)   │  │  │
│                         │ └────────┘  └────────────┘ └────────────┘  │  │
│                         │                    │                       │  │
│                         │    ┌───────────────┼───────────────┐       │  │
│                         │    ▼               ▼               ▼       │  │
│                         │ ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐    │  │
│                         │ │ Bazi │  │Zodiac│  │Tarot │  │Career│    │  │
│                         │ │Skill │  │Skill │  │Skill │  │Skill │    │  │
│                         │ └──────┘  └──────┘  └──────┘  └──────┘    │  │
│                         └──────────────────┬─────────────────────────┘  │
│                                            ▼                            │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                      VibeProfile Layer                            │  │
│   │          UnifiedProfileRepository (统一数据访问)                  │  │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  │  │
│   │  │  Identity  │  │   State    │  │Life Context│  │Skill Data  │  │  │
│   │  │ (出生信息)  │  │ (情绪状态)  │  │(目标/提醒) │  │(命盘数据)  │  │  │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘  │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                            │                            │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                    UserDataSpace (数据层)                         │  │
│   │  ┌─────────────────────┐  ┌─────────────────────────────────┐    │  │
│   │  │ VibeProfile (WHO)   │  │   Operational (WHAT)            │    │  │
│   │  │ unified_profiles    │  │   conversations, messages       │    │  │
│   │  │ (JSONB)             │  │   notifications, payments       │    │  │
│   │  └─────────────────────┘  └─────────────────────────────────┘    │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 核心引擎

### 3.1 CoreAgent

基于 Anthropic Agent 设计原则的对话引擎，是系统的核心。

**核心流程**：
```
用户消息 → CoreAgent.run()
    │
    ├─ 1. Skill 路由（LLM 自动选择或前端指定）
    │
    ├─ 2. 构建 System Prompt
    │      ├─ Skill 专家身份
    │      ├─ SOP 规则（配置驱动）
    │      ├─ 相关 Cases（倒排索引匹配）
    │      └─ 用户上下文（Profile + Skill Data）
    │
    ├─ 3. LLM 调用（支持 Tool Calling）
    │
    ├─ 4. 工具执行（ToolRegistry）
    │
    └─ 5. 流式输出（AI SDK Data Stream Protocol）
```

**关键特性**：
- **LLM 自动路由**：通过 `use_skill` 工具让 LLM 决定使用哪个 Skill
- **SOP 配置驱动**：从 SKILL.md 读取 `requires_birth_info`、`requires_compute` 等配置
- **Case 匹配**：使用倒排索引匹配相似案例，注入 System Prompt

### 3.2 Skill System

配置驱动的技能系统，支持自动发现。

**Skill 分类**：
```
┌─────────────────────────────────────────────────────────────┐
│  Core Layer (始终激活，不可取消)                              │
│  └─ core: 生命对话者 - AI 的灵魂                             │
├─────────────────────────────────────────────────────────────┤
│  Default Layer (默认激活，免费，可取消)                       │
│  ├─ mindfulness: 正念导师                                    │
│  └─ lifecoach: 人生教练                                      │
├─────────────────────────────────────────────────────────────┤
│  Professional Layer (需订阅，付费)                           │
│  ├─ bazi: 八字命理                                          │
│  ├─ zodiac: 西方占星                                        │
│  ├─ tarot: 塔罗占卜                                         │
│  ├─ jungastro: 荣格占星                                     │
│  └─ career: 职业规划                                        │
└─────────────────────────────────────────────────────────────┘
```

**Skill 目录结构**：
```
skills/{skill_id}/
├── SKILL.md              # Skill 定义（专家身份、触发词、配置）
├── rules/                # 规则文件（分析要点、输出要求）
│   ├── basic-reading.md
│   └── career.md
├── tools/                # 工具定义
│   ├── tools.yaml        # 工具 Schema
│   └── handlers.py       # 工具执行器
├── services/             # 领域服务
│   └── api.py            # API 服务（@skill_service 装饰器）
├── scenarios/            # 场景文件（旧架构兼容）
└── reminders.yaml        # 主动推送配置
```

### 3.3 Tool Registry

统一的工具注册表，支持自动发现。

**工具类型**：
| 类型 | 说明 | 示例 |
|------|------|------|
| collect | 收集用户信息 | request_info |
| calculate | 计算/排盘 | calculate_bazi |
| display | 展示结果 | show_bazi_chart |
| search | 知识检索 | search_db |
| action | 执行操作 | write_user_data |

**工具定义**（tools.yaml）：
```yaml
- name: show_bazi_chart
  description: 展示八字命盘
  tool_type: display
  card_type: BaziChart
  parameters:
    - name: chart
      type: object
      required: true
```

**工具执行器**（handlers.py）：
```python
@tool_handler("show_bazi_chart")
async def execute_show_bazi_chart(args: Dict, context: ToolContext) -> Dict:
    return {"cardType": "bazi_chart", **args}
```

---

## 4. 知识系统

### 4.1 Knowledge Base v2

基于 Case 倒排索引的知识检索系统，替代传统向量检索。

**核心概念**：
- **Cases**：从原文 LLM 抽取的结构化案例，存储在数据库中
- **倒排索引**：基于 tags 的内存索引，快速匹配相似案例
- **Rule 关联**：Cases 通过 `rule_ids` 关联到规则文件

**数据流**：
```
原文 (PDF/MD)
    │
    ▼ LLM 抽取
数据库: skill_cases 表
    │
    ▼ tags
Case 倒排索引（内存缓存）
    │
    ▼ 用户命盘特征匹配
System Prompt 注入
```

**Case 数据模型**：
| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 案例 ID |
| skill_id | string | 所属 Skill |
| name | string | 案例名称 |
| tags | string[] | 特征标签（用于匹配） |
| rule_ids | string[] | 关联的规则 ID |
| content | text | 案例正文（Markdown） |

---

## 5. 主动模块

### 5.1 Proactive Engine

主动触达用户，增强粘性和业务转化。通过 **VibeProfile** 统一管理用户订阅、推送偏好和提醒设置。

**架构**：
```
每日 04:00 凌晨扫描
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  ProactiveWorker.daily_scan()                                │
│                                                              │
│  1. 从 VibeProfile 获取所有 push_enabled 用户                │
│     WHERE profile->'preferences'->'push_settings'->          │
│           'push_enabled' = true                              │
│                                                              │
│  2. 为每个用户生成今日内容:                                  │
│     • 检查 subscribed_skills，生成运势推送                   │
│     • 检查 life_context.reminders，生成提醒推送              │
│     • 检查 life_context.goals，生成目标进度推送              │
│                                                              │
│  3. 存入 notifications 表，标记 deliver_hour                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
每小时投递 (00, 01, 02, ...)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  NotificationWorker.deliver()                                │
│                                                              │
│  SELECT * FROM notifications                                 │
│  WHERE deliver_hour = current_hour AND delivered = false     │
│                                                              │
│  投递到用户设备                                              │
└─────────────────────────────────────────────────────────────┘
```

**触发器类型**：
| 类型 | 说明 | 数据来源 | 示例 |
|------|------|---------|------|
| time_based | 定时触发 | reminders.yaml | 每日运势 |
| event_based | 事件触发 | VibeProfile.identity | 生日、节气 |
| threshold_based | 阈值触发 | VibeProfile.state | 运势低于 40 分 |
| emotion_based | 情绪触发 | VibeProfile.state | 检测到焦虑 |
| skill_completion | 完成触发 | conversations | 深度对话后推荐 |
| reminder_based | 用户提醒 | VibeProfile.life_context.reminders | 目标打卡、喝水 |

**配置示例**（reminders.yaml）：
```yaml
skill_id: bazi
enabled: true

reminders:
  - id: daily_fortune
    name: 每日运势
    trigger:
      type: time_based
      schedule: "0 4 * * *"
    content:
      generator: rules/daily-fortune.md
      suggested_prompt: "想了解今天的运势详情？"
      quick_actions:
        - label: "今日宜忌"
          prompt: "今天适合做什么？"
```

**用户提醒流程**（基于 VibeProfile）：
```python
# 每日扫描时检查用户的 reminders
profile = await VibeProfileRepository.get_profile(user_id)
reminders = profile.get("life_context", {}).get("reminders", [])

for reminder in reminders:
    if reminder["status"] != "active":
        continue

    # 检查今天是否应该触发
    if should_trigger_today(reminder):
        # 生成通知，在 trigger_hour 投递
        await create_notification(
            user_id=user_id,
            type="reminder",
            content=reminder["title"],
            deliver_hour=reminder["trigger_hour"]
        )
```

### 5.2 Skill Management

让用户发现、订阅、管理 Skill。订阅信息存储在 **VibeProfile.preferences.subscribed_skills**。

**订阅状态与推送**：
| Skill 类别 | 订阅要求 | 推送条件 | 存储位置 |
|-----------|---------|---------|---------|
| core | 始终激活 | 始终推送 | - |
| default | 默认激活，可取消 | status=subscribed && push_enabled=true | VibeProfile |
| professional | 需订阅 | status=subscribed && push_enabled=true | VibeProfile |

**数据结构**：
```yaml
preferences:
  subscribed_skills:
    bazi:
      status: "subscribed"           # subscribed | unsubscribed
      push_enabled: true
      subscribed_at: "2026-01-01T00:00:00Z"
      trial_messages_used: 0
```

---

## 6. 用户体验

### 6.1 对话体验

**Core Skill 人格**：
- 温暖但不粘腻
- 智慧但不说教
- 好奇但不窥探
- 诚实但不伤害

**能力层次**：
1. **倾听与共情**：深度倾听、情绪感知、不评判
2. **记忆与累积**：跨对话记忆、模式识别、变化觉察
3. **引导探索**：苏格拉底式提问、重框架、联结
4. **适度引导**：知道边界、轻推、播种、庆祝

### 6.2 新用户流程

```
Landing → Loading → Aha Moment → Conversion
   │          │          │           │
   │          │          │           └─ 付费转化
   │          │          └─ 日主洞察 + 今日运势
   │          └─ 命盘渐进绘制 + 计算步骤展示
   └─ 零摩擦入口（键盘直接输入生辰）
```

### 6.3 ShowCard Fallback 机制

"专用优先，通用兜底"的卡片渲染策略：
1. 优先使用注册的专用组件
2. 不存在时根据 `fallbackType` 降级到通用视图
3. 智能推断：根据 data/items/nodes 等属性自动选择

**通用视图类型**：list, tree, table, timeline, form, select, chart, progress, counter, modal, toast, custom

---

## 7. 技术栈

### 7.1 后端

| 组件 | 技术 |
|------|------|
| 框架 | FastAPI (Python 3.11+) |
| 数据库 | PostgreSQL 16 + pgvector |
| LLM | DeepSeek / GLM / Claude (Anthropic 兼容 API) |
| 向量嵌入 | BAAI/bge-m3 (1024维，本地 CUDA) |

### 7.2 前端

| 组件 | 技术 |
|------|------|
| 框架 | Next.js 14 (App Router) |
| 语言 | TypeScript 5.3+ |
| 样式 | Tailwind CSS 3.4 |
| 动画 | Framer Motion |
| AI SDK | Vercel AI SDK 4.x |

### 7.3 LLM 模型配置

**唯一配置源**：`config/models.yaml`

```yaml
providers:
  deepseek:
    base_url: https://api.deepseek.com/anthropic
    is_anthropic_compatible: true
  glm:
    base_url: https://open.bigmodel.cn/api/anthropic/v1
    is_anthropic_compatible: true

routing:
  chat:
    free: deepseek-chat
    paid: deepseek-chat
    fallback: [glm-4.7]
```

---

## 8. API 架构

### 8.1 路由结构

```
routes/ (7 个核心路由文件)
├── health.py           # 健康检查
├── chat_v5.py          # CoreAgent 对话入口
├── tools.py            # 工具 Schema API
├── skills.py           # Skill Gateway（配置驱动）
├── account.py          # 用户域（认证、用户、访客、身份）
├── commerce.py         # 支付域（支付、订阅、权益）
└── notifications.py    # 通知域
```

### 8.2 核心端点

| 域 | 端点前缀 | 说明 |
|----|----------|------|
| Chat | `/api/v1/chat/v5/*` | CoreAgent 对话 |
| Skills | `/api/v1/skills/{skill}/{action}` | 统一 Skill Gateway |
| Account | `/api/v1/account/*` | 认证、用户、访客、身份 |
| Commerce | `/api/v1/commerce/*` | 支付、订阅、权益 |
| Tools | `/api/v1/tools/*` | 工具 Schema |
| Notifications | `/api/v1/notifications/*` | 通知管理 |

---

## 9. 数据模型

### 9.1 UserDataSpace - 数据空间划分

VibeLife 采用 UserDataSpace 统一管理用户数据，区分 **WHO**（画像）和 **WHAT**（操作）：

```
┌─────────────────────────────────────────────────────────────────┐
│                        UserDataSpace                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   VibeProfile (WHO)              Operational (WHAT)              │
│   ─────────────────              ──────────────────              │
│   用户是谁                       用户做了什么                    │
│   • unified_profiles             • conversations                 │
│                                  • messages                      │
│                                  • reports                       │
│                                  • notifications                 │
│                                  • subscriptions                 │
│                                  • payments                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 核心表

| 表 | 说明 | 数据类型 |
|----|------|----------|
| **VibeProfile (WHO)** | | |
| unified_profiles | 用户画像（JSONB） | WHO |
| vibe_profile_insights | AI 洞察（Cold Layer） | WHO |
| vibe_profile_timeline | 重要事件时间线 | WHO |
| **Operational (WHAT)** | | |
| vibe_users | 用户基本信息 | WHAT |
| conversations | 对话会话 | WHAT |
| messages | 对话消息 | WHAT |
| notifications | 通知记录 | WHAT |
| skill_cases | 知识案例（Case 系统） | WHAT |
| **Billing (WHAT)** | | |
| subscriptions | 付费订阅记录 | WHAT |
| payments | 支付记录 | WHAT |

### 9.3 VibeProfile 数据结构

**统一画像存储**（unified_profiles.profile JSONB）：

```yaml
profile:
  account: { vibe_id, display_name, tier, status }  # 从 vibe_users 同步
  identity:
    birth_info: { date, time, place, timezone, gender }
  state:
    emotion: "neutral"              # anxious | sad | neutral | content | excited
    focus: ["career"]
    life_stage: "career_growth"
  preferences:
    voice_mode: "warm"
    language: "zh-CN"
    subscribed_skills:              # 整合 user_skill_subscriptions
      bazi: { status, push_enabled, subscribed_at, trial_messages_used }
    push_settings:                  # 整合 user_push_preferences
      { default_push_hour, max_daily_pushes, quiet_start_hour, quiet_end_hour }
    data_retention:
      conversations: "1y"           # "1y" | "3y" | "forever"
    blocked_skills: []
  skill_data:
    bazi: { chart, features, current_dayun, current_liunian }
    zodiac: { chart, current_transits }
    tarot: { last_reading }
    career: { assessment }
  extracted:                        # 从对话抽取
    facts: []
    goals: []
    concerns: []
    pain_points: []
  life_context:                     # 整合 user_data_store
    occupation: { title, industry }
    focus_areas: ["career", "health"]
    goals: [{ id, title, category, status, progress, deadline }]
    tasks: [{ id, title, status, due_date, goal_id }]
    checkins: { "2026-01-19": { mood, energy, notes } }  # 只保留 30 天
    reminders: [{ id, type, title, schedule_type, trigger_hour, status }]
    tracking: { last_checkin, streak_days }
```

**详细文档**：参见 `/docs/components/VibeProfile/SPEC.md`

### 9.4 数据访问层

**UnifiedProfileRepository** 提供统一的 Profile 访问接口（使用 jsonb_set 局部更新）：

```python
class UnifiedProfileRepository:
    # 读取：get_profile, get_birth_info, get_skill_data, get_preferences,
    #       get_life_context, get_extracted
    # 写入：update_birth_info, update_skill_data, update_preferences,
    #       update_life_context, update_extracted
    # 生活管理：add_goal, update_goal, add_task, add_checkin, add_reminder
    # Skill 订阅：subscribe, unsubscribe, is_subscribed, can_use_skill
    # 推送管理：get_push_settings, is_push_enabled, get_users_with_push_enabled
    # 缓存：_invalidate_cache (内存缓存，5分钟 TTL)
```

**实现位置**：`apps/api/stores/unified_profile_repo.py`

### 9.5 Skill 访问规则

| Skill | 可读 | 可写 |
|-------|------|------|
| **Core Layer** | | |
| core | 全部 | state, extracted |
| lifecoach | 全部 | state, extracted, life_context |
| mindfulness | 全部 | state |
| **Professional Layer** | | |
| bazi | identity, state | skill_data.bazi |
| zodiac | identity, state | skill_data.zodiac |
| tarot | identity, state | skill_data.tarot |
| career | identity, state, life_context | skill_data.career |

### 9.6 数据生命周期

| 领域 | 默认保留 | 用户可选 | 清理规则 |
|------|---------|---------|---------|
| **VibeProfile** | 永久 | - | checkins 保留 30 天 |
| **Conversations** | 1 年 | 1年 / 3年 / 永久 | 按 data_retention 设置清理 |
| **Content** | 永久 | 可手动删除 | - |
| **Billing** | 7 年 | 不可更改 | 法规要求 |
| **Logs** | 90 天 | - | 滚动清理 |
| **Notifications** | 30 天 | - | 已读 30 天后清理 |

### 9.7 已整合的废弃表

以下表的数据已迁移到 VibeProfile，可以删除：
- `user_skill_subscriptions` → `profile.preferences.subscribed_skills`
- `user_push_preferences` → `profile.preferences.push_settings`
- `user_data_store` → `profile.life_context`
- `skill_recommendation_blocks` → `profile.preferences.blocked_skills`

---

## 10. 部署架构

### 10.1 环境配置

| 环境 | API 端口 | Web 端口 | 说明 |
|------|----------|----------|------|
| 开发 | 8000 | 3000 | 本地开发 |
| 测试 | 8100 | 8232 | aiscend 服务器 |
| 生产 | 8231 | 8230 | 分布式部署 |

### 10.2 生产部署

```
用户 (全球)
    │
    ▼
Cloudflare (边缘节点 + DDoS 防护)
    │
    ▼ HTTPS 加密隧道
火山引擎香港 (Nginx + Next.js)
    │
    ▼
北京服务器 (FastAPI + PostgreSQL)
```

---

## 附录

### A. AI SDK Data Stream Protocol

```
0:"text chunk"           # 文本块
9:{"toolCallId":"..."}   # 工具调用开始
a:{"toolCallId":"..."}   # 工具调用结果
e:{"finishReason":"..."}  # 完成
d:{"finishReason":"..."}  # 结束
```

### B. 添加新 Skill 流程

1. 创建目录：`skills/newskill/{SKILL.md, rules/, tools/, services/}`
2. 定义 SKILL.md：专家身份、触发词、配置
3. 创建工具：tools.yaml + handlers.py
4. 创建 API 服务：services/api.py（@skill_service 装饰器）
5. 配置推送：reminders.yaml
6. 重启服务 - 自动发现新 Skill

### C. 版本历史

- **V8.0** (2026-01-19):
  - VibeProfile 整合：WHO/WHAT 数据分离，统一 JSONB 存储
  - 整合 user_skill_subscriptions, user_push_preferences, user_data_store
  - UnifiedProfileRepository 统一数据访问层
  - Knowledge v2（Case 倒排索引）、Proactive 模块
- **V7.1** (2026-01-18): LLM 自动路由、ShowCard Fallback 机制
- **V7.0** (2026-01-15): SkillServiceRegistry、统一 Skill Gateway、路由精简
