# VibeLife 用户数据体系 v3

> **设计原则**: 4 表核心架构，职责清晰，零业务语义
> **业务语义**: 在 scenarios/ 和各 Skill 的 SKILL.md 中定义路径规范

---

## 1. 架构总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           用户数据体系 v3                                    │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────┐
  │     vibe_users       │  ← 身份层 (Identity)
  │  账号 + 认证 + 计费   │
  └──────────┬───────────┘
             │ 1:1
             ▼
  ┌──────────────────────┐
  │   unified_profiles   │  ← 画像层 (Profile)
  │  基础信息 + 偏好      │
  │  + Skill 计算数据     │
  └──────────┬───────────┘
             │ 1:N
             ▼
  ┌──────────────────────┐
  │   user_data_store    │  ← 内容层 (Content)
  │  任意路径的用户数据   │
  │  虚拟文件系统         │
  └──────────────────────┘

  ┌──────────────────────┐
  │    user_triggers     │  ← 主动服务层 (Proactive)
  │  定时 + 条件触发      │
  └──────────────────────┘
```

---

## 2. 数据分层职责

| 层级 | 表名 | 职责 | 数据特性 |
|------|------|------|----------|
| **身份层** | vibe_users | 账号、认证、订阅、配额、计费汇总 | 高频读取，低频写入 |
| **画像层** | unified_profiles | 基础信息、偏好、Skill 计算数据 | 用户画像，Skill 共享 |
| **内容层** | user_data_store | 任意路径的用户内容数据 | 路径由调用方定义 |
| **主动层** | user_triggers | 定时提醒、条件触发、定时任务 | 主动服务调度 |

---

## 3. 表结构设计

### 3.1 vibe_users (身份层 + 计费)

```sql
CREATE TABLE vibe_users (
    -- 身份标识
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vibe_id         VARCHAR(20) UNIQUE NOT NULL,  -- VB-A1B2C3D4
    display_name    VARCHAR(100),
    avatar_url      VARCHAR(500),

    -- 订阅状态 (缓存，权威数据在 user_subscriptions)
    tier            VARCHAR(20) DEFAULT 'free',   -- free | paid | premium
    tier_expires_at TIMESTAMPTZ,

    -- 用量配额 (每日/每月限制)
    daily_quota     JSONB DEFAULT '{
        "conversations": 10,
        "llm_calls": 50
    }',

    -- 计费汇总 (由 Worker 从 usage_events 定期聚合)
    billing_summary JSONB DEFAULT '{
        "current_month": {
            "llm_calls": 0,
            "tokens": 0,
            "cost_usd": 0.0
        },
        "lifetime": {
            "total_conversations": 0,
            "total_tokens": 0,
            "total_cost_usd": 0.0
        }
    }',

    -- 时间戳
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 认证表
CREATE TABLE vibe_user_auth (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    auth_type       VARCHAR(20) NOT NULL,  -- email | phone | wechat | apple
    auth_identifier VARCHAR(255) NOT NULL,
    auth_credential VARCHAR(255),          -- hashed password or token
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (auth_type, auth_identifier)
);

-- 索引
CREATE INDEX idx_users_tier ON vibe_users (tier);
CREATE INDEX idx_users_vibe_id ON vibe_users (vibe_id);
```

---

### 3.2 unified_profiles (画像层)

```sql
CREATE TABLE unified_profiles (
    user_id     UUID PRIMARY KEY REFERENCES vibe_users(id) ON DELETE CASCADE,
    profile     JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 历史归档表
CREATE TABLE unified_profiles_history (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL,
    profile     JSONB NOT NULL,
    archived_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_profiles_birth ON unified_profiles USING GIN ((profile -> 'birth_info'));
CREATE INDEX idx_profiles_history ON unified_profiles_history (user_id, archived_at DESC);
```

**profile JSONB 结构**:

```json
{
  "birth_info": {
    "date": "1990-05-15",
    "time": "10:30",
    "place": "北京",
    "gender": "male",
    "timezone": "Asia/Shanghai"
  },

  "skill_data": {
    // Skill 计算的数据，结构由各 Skill 定义
    // 例如 bazi skill 定义 pillars, day_master 等
    // 例如 zodiac skill 定义 sun_sign, moon_sign 等
  },

  "preferences": {
    "voice_mode": "warm",
    "language": "zh-CN",
    "timezone": "Asia/Shanghai",
    "notification_time": "08:00",
    "enable_proactive": true
  },

  "context": {
    // 用户生活上下文，由对话提取
    // 结构自由，不预设字段
  },

  "extracted": {
    // AI 提取的用户信息
    "facts": [],
    "concerns": [],
    "patterns": [],
    "extracted_at": "2026-01-18T10:00:00Z"
  }
}
```

---

### 3.3 user_data_store (内容层)

**核心原则**: 路径完全自由，不预设业务语义。

```sql
CREATE TABLE user_data_store (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,
    data_path   VARCHAR(255) NOT NULL,  -- 任意路径，由调用方定义
    content     JSONB NOT NULL,
    version     INTEGER DEFAULT 1,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (user_id, data_path)
);

-- 索引
CREATE INDEX idx_data_user_path ON user_data_store (user_id, data_path);
CREATE INDEX idx_data_path_prefix ON user_data_store (user_id, data_path varchar_pattern_ops);
CREATE INDEX idx_data_content ON user_data_store USING GIN (content);
CREATE INDEX idx_data_updated ON user_data_store (user_id, updated_at DESC);
```

**路径规范**:

- 路径由 scenarios/ 和 Skill SKILL.md 定义，Core 不预设
- 路径格式: `segment/segment/segment` (无前导斜杠)
- 支持通配符查询: `prefix/*`

**示例** (由 scenarios/goal_tracking.md 定义):

```
goals/2026/year
goals/2026/q1
plans/daily/2026-01-18
checkins/2026-01-18
```

**示例** (由 skills/bazi/SKILL.md 定义):

```
bazi/chart
bazi/fortune/2026-01-18
bazi/relationships/partner_001
```

---

### 3.4 user_triggers (主动服务层)

```sql
CREATE TABLE user_triggers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,

    -- 触发类型
    trigger_type    VARCHAR(50) NOT NULL,  -- reminder | condition | schedule

    -- 触发内容
    title           VARCHAR(255) NOT NULL,
    description     TEXT,

    -- 触发动作 (通用)
    action          JSONB NOT NULL DEFAULT '{}',

    -- 调度配置 (for reminder/schedule)
    schedule        VARCHAR(100),           -- cron 表达式 或 HH:MM
    schedule_type   VARCHAR(20),            -- once | daily | weekly | cron
    next_trigger_at TIMESTAMPTZ,
    last_triggered  TIMESTAMPTZ,

    -- 条件配置 (for condition trigger)
    condition       JSONB,

    -- 关联
    source_path     VARCHAR(255),           -- 关联的 user_data_store path

    -- 状态
    status          VARCHAR(20) DEFAULT 'active',  -- active | paused | completed | cancelled
    trigger_count   INTEGER DEFAULT 0,
    metadata        JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_trigger_user_status ON user_triggers (user_id, status);
CREATE INDEX idx_trigger_next ON user_triggers (next_trigger_at) WHERE status = 'active';
CREATE INDEX idx_trigger_type ON user_triggers (trigger_type, status);
```

**trigger_type 说明**:

| 类型 | 说明 | 示例 |
|------|------|------|
| reminder | 定时提醒 | 每天早8点发送消息 |
| condition | 条件触发 | 某路径数据满足条件时触发 |
| schedule | 定时任务 | 每周日执行生成任务 |

**action JSONB 结构** (通用):

```json
{
  "type": "message | generate | update | notify",
  "params": {
    // type=message: 发送消息
    "content": "提醒内容",

    // type=generate: 生成内容
    "prompt": "生成 prompt",
    "output_path": "输出路径",

    // type=update: 更新数据
    "target_path": "目标路径",
    "operation": "set | merge | delete",

    // type=notify: 推送通知
    "title": "通知标题",
    "body": "通知内容"
  }
}
```

**condition JSONB 结构** (通用):

```json
{
  "type": "data_match | count | deadline",
  "watch_path": "监控的数据路径",
  "rule": {
    // data_match: JSONB 匹配规则
    // count: {"$gte": 7}
    // deadline: {"days_until": {"$lte": 7}}
  }
}
```

---

## 4. 辅助表

### 4.1 usage_events (用量事件流)

```sql
CREATE TABLE usage_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    event_type      VARCHAR(50) NOT NULL,  -- llm_call | skill_use | tool_call | conversation
    model           VARCHAR(100),
    input_tokens    INTEGER DEFAULT 0,
    output_tokens   INTEGER DEFAULT 0,
    estimated_cost  DECIMAL(10, 6) DEFAULT 0,
    skill_id        VARCHAR(50),
    tool_name       VARCHAR(100),
    conversation_id UUID,
    metadata        JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_usage_user_date ON usage_events (user_id, created_at);
CREATE INDEX idx_usage_skill ON usage_events (skill_id, created_at);
```

### 4.2 user_subscriptions (订阅管理)

```sql
CREATE TABLE user_subscriptions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES vibe_users(id),
    plan_id                 VARCHAR(50) NOT NULL,
    status                  VARCHAR(20) DEFAULT 'active',
    payment_provider        VARCHAR(50),
    payment_subscription_id VARCHAR(255),
    started_at              TIMESTAMPTZ DEFAULT NOW(),
    current_period_end      TIMESTAMPTZ,
    cancelled_at            TIMESTAMPTZ
);
```

---

## 5. 数据流向图

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              数据流向                                       │
└────────────────────────────────────────────────────────────────────────────┘

  用户请求
     │
     ▼
┌────────────┐    配额检查     ┌────────────────┐
│  API 层    │───────────────►│   vibe_users   │
└────────────┘                 │ tier + quota   │
     │                         └────────────────┘
     │ 获取 Profile                    │
     ▼                                 │ 用量累计
┌────────────────┐            ┌────────┴───────┐
│ Profile Cache  │◄───────────│unified_profiles│
│  (Redis/内存)   │            │  (画像数据)     │
└────────────────┘            └────────────────┘
     │
     │ Agent 执行
     ▼
┌────────────┐   读写用户数据   ┌────────────────┐
│ CoreAgent  │◄──────────────►│ user_data_store│
│            │                 │  (内容数据)     │
└────────────┘                 └────────────────┘
     │
     │ 创建触发器
     ▼
┌────────────────┐
│ user_triggers  │◄───────────  ProactiveEngine 扫描
│  (主动服务)     │
└────────────────┘
     │
     │ 触发时
     ▼
┌────────────────┐
│ Notification   │───────────►  推送到用户
│   Service      │
└────────────────┘
     │
     ▼
┌────────────────┐
│ usage_events   │◄───────────  记录所有用量
│  (计费事件流)   │
└────────────────┘
     │
     ▼ (每日聚合 Worker)
┌────────────────┐
│ vibe_users     │
│.billing_summary│
└────────────────┘
```

---

## 6. 主动服务流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         主动服务架构 (Proactive Service)                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   ┌─────────────┐     ┌─────────────────┐     ┌─────────────────────────┐   │
│   │   Cron Job  │────►│ ProactiveEngine │────►│    TriggerDetector      │   │
│   │ (每分钟跑)  │     │   (engine.py)   │     │  (trigger_detector.py)  │   │
│   └─────────────┘     └────────┬────────┘     └──────────────┬──────────┘   │
│                                │                              │              │
│                                │                              │ 检查触发条件 │
│                                │                              ▼              │
│                    ┌───────────┴───────────┐  ┌─────────────────────────┐   │
│                    │                       │  │     user_triggers       │   │
│                    │                       │  │ • reminder (定时)       │   │
│                    │                       │  │ • condition (条件)      │   │
│                    │                       │  │ • schedule (任务)       │   │
│                    │                       │  └─────────────────────────┘   │
│                    │                       │              │                  │
│                    ▼                       ▼              ▼                  │
│        ┌─────────────────────────────────────────────────────────────────┐  │
│        │                      ActionExecutor                              │  │
│        │  • message → 发送消息                                            │  │
│        │  • generate → 生成内容                                           │  │
│        │  • update → 更新数据                                             │  │
│        │  • notify → 推送通知                                             │  │
│        └─────────────────────────────────────────────────────────────────┘  │
│                                      │                                       │
│                                      ▼                                       │
│        ┌─────────────────────────────────────────────────────────────────┐  │
│        │                    NotificationService                           │  │
│        └─────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Core 工具设计原则

### 7.1 零业务语义

Core 工具不包含任何业务特定的概念：

| 方面 | Core 层 | 业务层 (scenarios/) |
|------|---------|---------------------|
| 数据路径 | 任意字符串 | `goals/2026/year` |
| 卡片类型 | `list`, `tree`, `form` | `goal_tree`, `checkin_form` |
| 触发动作 | `message`, `notify` | `daily_plan_reminder` |

### 7.2 通用展示工具

```yaml
show_card:
  card_type:
    # 通用视图类型
    - list          # 列表
    - tree          # 树状
    - table         # 表格
    - timeline      # 时间线
    - form          # 表单 (可交互)
    - chart         # 图表
    - progress      # 进度
    - modal         # 模态框
    - custom        # 自定义组件
```

### 7.3 Skill 自定义卡片

Skill 通过 `custom` + `component_id` 注册自定义卡片：

```yaml
# 在 Skill 中使用
show_card:
  card_type: custom
  options:
    component_id: bazi_chart  # Skill 注册的组件
  data_source:
    type: api
    endpoint: /bazi/chart
```

---

## 8. 删除的表

| 表名 | 状态 | 原因 |
|------|------|------|
| `skill_profiles` | **删除** | 合并到 unified_profiles.skill_data |
| `user_reminders` | **升级** | 升级为 user_triggers |

---

## 9. 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| **Core 零业务语义** | 路径/卡片类型都是通用的 | 避免耦合，易于扩展 |
| 计费数据位置 | vibe_users.billing_summary | 配额检查高频读取 |
| skill_data 位置 | unified_profiles | Skill 间共享计算数据 |
| 用户数据存储 | 虚拟文件路径 | 支持任意层级结构 |
| 版本控制 | 乐观锁 (version) | 防止并发写入冲突 |
| **展示工具** | **通用 show_card** | card_type 是视图类型 |
| **Skill 扩展** | **custom + component_id** | Skill 注册自定义组件 |

---

## 10. 迁移检查清单

- [ ] 添加 vibe_users.tier, daily_quota, billing_summary 字段
- [ ] 创建 user_triggers 表
- [ ] 迁移 user_reminders 数据到 user_triggers
- [ ] 将 skill_profiles.profile_data 合并到 unified_profiles.skill_data
- [ ] 删除 skill_profiles 表
- [ ] 更新 UnifiedProfileRepository
- [ ] 创建 TriggerService
- [ ] 创建计费汇总 Worker
- [ ] 实现通用 CardRegistry (list/tree/form/table)
- [ ] 迁移现有 Skill 卡片为 custom 组件
