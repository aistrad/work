# VibeLife 数据生成时序链路图

> **核心原则**: 零硬编码，所有数据由 Skill 模块主动生成（Proactive），Chat 组件只负责展示和交互

---

## 🔄 完整数据流架构图

```mermaid
sequenceDiagram
    participant Worker as Worker<br/>(定时任务)
    participant ProactiveEngine as Proactive<br/>Engine
    participant TriggerDetector as Trigger<br/>Detector
    participant BaziSkill as Bazi<br/>Skill
    participant LifecoachSkill as Lifecoach<br/>Skill
    participant ZodiacSkill as Zodiac<br/>Skill
    participant UnifiedProfile as Unified<br/>Profile<br/>(数据库)
    participant DashboardAPI as Dashboard<br/>API
    participant ChatComponent as Chat<br/>Component<br/>(前端)

    %% ═══════════════════════════════════════════════════════════════
    %% Phase 1: 定时触发 (每小时)
    %% ═══════════════════════════════════════════════════════════════

    Note over Worker: 每小时执行
    Worker->>ProactiveEngine: run_scheduled_scan()

    ProactiveEngine->>ProactiveEngine: _load_skill_configs()<br/>加载所有 reminders.yaml
    Note right of ProactiveEngine: skills/*/reminders.yaml<br/>- bazi/reminders.yaml<br/>- lifecoach/reminders.yaml<br/>- zodiac/reminders.yaml

    ProactiveEngine->>UnifiedProfile: 获取当前时段用户列表
    UnifiedProfile-->>ProactiveEngine: 返回用户 profiles

    %% ═══════════════════════════════════════════════════════════════
    %% Phase 2: 触发检测 (针对每个用户)
    %% ═══════════════════════════════════════════════════════════════

    loop 对每个用户
        ProactiveEngine->>TriggerDetector: should_trigger(trigger_config, profile)

        alt 时间触发 (time_based)
            Note over TriggerDetector: schedule: "0 8 * * *"<br/>检查当前是否匹配 cron
            TriggerDetector->>TriggerDetector: _check_time_based()
        else 事件触发 (event_based)
            Note over TriggerDetector: event: birthday<br/>event: dayun_change<br/>event: solar_term
            TriggerDetector->>UnifiedProfile: 读取用户事件数据
            UnifiedProfile-->>TriggerDetector: 返回事件信息
            TriggerDetector->>TriggerDetector: _detect_event()
        else 阈值触发 (threshold_based)
            Note over TriggerDetector: metric: daily_fortune_score<br/>condition: "<" threshold: 40
            TriggerDetector->>UnifiedProfile: 读取运势分数
            UnifiedProfile-->>TriggerDetector: 返回分数
            TriggerDetector->>TriggerDetector: _check_threshold()
        end

        TriggerDetector-->>ProactiveEngine: 返回触发结果

        %% ═══════════════════════════════════════════════════════════════
        %% Phase 3: 内容生成 (调用 Skill 模块)
        %% ═══════════════════════════════════════════════════════════════

        alt Bazi Skill 触发
            ProactiveEngine->>BaziSkill: generate_content()<br/>generator: rules/daily-fortune.md
            Note right of BaziSkill: 1. 调用 calculate_bazi()<br/>2. 分析今日干支<br/>3. 生成个性化运势<br/>4. 生成行动建议
            BaziSkill->>UnifiedProfile: 读取用户命盘<br/>profiles.bazi.bazi_chart
            UnifiedProfile-->>BaziSkill: 返回命盘数据
            BaziSkill->>BaziSkill: 计算今日运势<br/>(综合分数 + 宜忌)
            BaziSkill->>UnifiedProfile: 写入 Skill Data<br/>profiles.skills.bazi.daily_fortune
            BaziSkill-->>ProactiveEngine: 返回 ReminderContent<br/>{title, body, card_type, quick_actions}
        end

        alt Lifecoach Skill 触发
            ProactiveEngine->>LifecoachSkill: generate_content()<br/>generator: rules/companion/daily-checkin.md
            Note right of LifecoachSkill: 1. 读取用户愿景<br/>2. 读取连续天数<br/>3. 生成情感化文案<br/>4. 生成杠杆提醒
            LifecoachSkill->>UnifiedProfile: 读取 Lifecoach 状态<br/>profiles.skills.lifecoach
            UnifiedProfile-->>LifecoachSkill: 返回愿景、大石头、杠杆
            LifecoachSkill->>LifecoachSkill: 生成个性化签到文案<br/>(根据 streak 动态调整)
            LifecoachSkill-->>ProactiveEngine: 返回 ReminderContent
        end

        alt Zodiac Skill 触发
            ProactiveEngine->>ZodiacSkill: generate_content()<br/>generator: rules/daily-transit.md
            Note right of ZodiacSkill: 1. 计算今日行星位置<br/>2. 分析与本命盘相位<br/>3. 生成能量提示
            ZodiacSkill->>UnifiedProfile: 读取用户星盘<br/>profiles.zodiac.natal_chart
            UnifiedProfile-->>ZodiacSkill: 返回星盘数据
            ZodiacSkill->>ZodiacSkill: 计算行星行运
            ZodiacSkill->>UnifiedProfile: 写入 Skill Data<br/>profiles.skills.zodiac.daily_transit
            ZodiacSkill-->>ProactiveEngine: 返回 ReminderContent
        end

        %% ═══════════════════════════════════════════════════════════════
        %% Phase 4: 推送投递 (写入数据库)
        %% ═══════════════════════════════════════════════════════════════

        ProactiveEngine->>UnifiedProfile: 写入生成的数据<br/>unified_profiles.skills.*
        Note right of UnifiedProfile: profiles.skills.bazi.daily_fortune<br/>profiles.skills.lifecoach.today_levers<br/>profiles.skills.zodiac.daily_transit
    end

    %% ═══════════════════════════════════════════════════════════════
    %% Phase 5: 用户打开 Chat 页面
    %% ═══════════════════════════════════════════════════════════════

    Note over ChatComponent: 用户打开 /chat 页面
    ChatComponent->>DashboardAPI: GET /dashboard

    DashboardAPI->>UnifiedProfile: 聚合用户数据<br/>SELECT * FROM unified_profiles WHERE user_id = ?
    UnifiedProfile-->>DashboardAPI: 返回完整 profile

    DashboardAPI->>DashboardAPI: 构建 DashboardDTO<br/>(聚合各 Skill 数据)
    Note right of DashboardAPI: {<br/>  ambient: {...},<br/>  status: {...},<br/>  lifecoach: {...},<br/>  mySkills: [...]<br/>}

    DashboardAPI-->>ChatComponent: 返回 Dashboard 数据

    ChatComponent->>ChatComponent: useDashboardWelcomeData()<br/>(数据转换)

    ChatComponent->>ChatComponent: 渲染 ChatWelcomeMessage<br/>- EnhancedFortuneCard<br/>- ConversationalLifecoachCard<br/>- DynamicQuickActions

    Note over ChatComponent: 用户看到个性化欢迎消息<br/>（所有数据来自 Skill 模块）

    %% ═══════════════════════════════════════════════════════════════
    %% Phase 6: 用户交互 (触发新的数据生成)
    %% ═══════════════════════════════════════════════════════════════

    alt 用户点击"开始今天"(签到)
        ChatComponent->>DashboardAPI: POST /dashboard/checkin
        DashboardAPI->>UnifiedProfile: 更新 lifecoach.progress.checkins
        UnifiedProfile-->>DashboardAPI: 返回新的 streak
        DashboardAPI-->>ChatComponent: 返回签到成功
        ChatComponent->>ChatComponent: toast.success("连续 7 天 🔥")
    end

    alt 用户点击"写作1小时"(杠杆行动)
        ChatComponent->>ChatComponent: 发送 prompt: "帮我完成：写作1小时"
        Note over ChatComponent: 触发对话，引导用户执行
    end

    alt 用户点击"周复盘"
        ChatComponent->>ChatComponent: router.push("/chat?scenario=weekly-review")
        Note over ChatComponent: 跳转到 Lifecoach<br/>触发复盘协议
    end
```

---

## 📊 数据来源映射表

### 欢迎消息中的每个字段 → Skill 来源

| 组件 | 字段 | 数据来源 | 生成触发 |
|-----|------|---------|---------|
| **开场问候** | `greeting` | `ambient.greeting` | 无（静态配置） |
| | `solarTerm` | `ambient.solarTerm` | 系统计算（基于日期） |
| | `streak` | `lifecoach.progress.streak` | Lifecoach Skill (签到时更新) |
| **今日能量盘** | `headline` | `skills.bazi.daily_fortune.headline` | Bazi Skill<br/>触发: daily_fortune<br/>时间: 04:00 每天 |
| | `insights[]` | `skills.bazi.daily_fortune.insights` | Bazi Skill<br/>(基于当日干支 + 用户命盘) |
| | `rating.overall` | `skills.bazi.daily_fortune.score` | Bazi Skill<br/>(综合评分算法) |
| | `rating.focused_area` | `skills.bazi.daily_fortune.area_scores` | Bazi Skill<br/>(根据 life_context.current_focus) |
| **本周进度** | `northStar` | `lifecoach.north_star.vision` | Lifecoach Skill<br/>触发: 用户完成 dankoe 协议 |
| | `monthlyProject` | `lifecoach.monthly.current_project` | Lifecoach Skill<br/>触发: 用户设定月度目标 |
| | `weekRocks[]` | `lifecoach.weekly.rocks` | Lifecoach Skill<br/>触发: weekly_planning<br/>时间: 周一 08:00 |
| | `todayLevers[]` | `lifecoach.daily.levers` | Lifecoach Skill<br/>触发: daily_checkin<br/>时间: 08:00 每天 |
| | `progressMessage` | 前端动态生成 | (基于完成度计算) |
| **快捷按钮** | 按钮列表 | 前端动态生成 | (基于用户状态 + 时间) |
| | `checkedIn` | `lifecoach.progress.checkedIn` | Lifecoach Skill |
| | `uncompletedLevers` | `lifecoach.daily.levers` | Lifecoach Skill |

---

## 🔧 Skill 数据生成机制详解

### Bazi Skill - 今日运势生成

```yaml
# skills/bazi/reminders.yaml

- id: daily_fortune
  trigger:
    type: time_based
    schedule: "0 4 * * *"  # 每天 04:00 (用户本地时间)
  content:
    generator: rules/daily-fortune.md  # ← Rule 文件定义生成逻辑
```

**生成流程**:
1. **触发**: Proactive Engine 在 04:00 触发
2. **读取数据**: 从 `unified_profiles.bazi.bazi_chart` 读取用户命盘
3. **计算**: 调用 `BaziComputer.calculate_daily_fortune()`
   - 计算今日干支
   - 分析与日主关系
   - 生成宜忌建议
4. **个性化**: 读取 `life_context.current_focus` (事业/感情/健康)
5. **写入**: 保存到 `unified_profiles.skills.bazi.daily_fortune`

**生成的数据结构**:
```json
{
  "skill_id": "bazi",
  "data_type": "daily_fortune",
  "generated_at": "2026-01-21T04:00:00Z",
  "content": {
    "headline": "今天适合推进你的创作项目",
    "insights": [
      "上午 9-11 点能量最佳，安排重要会议",
      "人际关系顺畅，适合团队协作",
      "保持专注，一步一步来"
    ],
    "rating": {
      "overall": 4,
      "focused_area": {
        "name": "事业",
        "score": 5,
        "emoji": "💼",
        "tip": "今天适合推进你的创作项目"
      }
    }
  }
}
```

---

### Lifecoach Skill - 进度数据生成

```yaml
# skills/lifecoach/reminders.yaml

- id: daily_checkin
  trigger:
    type: time_based
    schedule: "0 8 * * *"  # 每天 08:00
  conditions:
    - type: has_data
      path: "lifecoach.north_star.vision"
    - type: not_checked_in_today
```

**生成流程**:
1. **触发**: Proactive Engine 在 08:00 触发
2. **条件检查**:
   - 用户已设定北极星愿景
   - 今天还没签到
3. **读取数据**: 从 `unified_profiles.skills.lifecoach` 读取
   - `north_star.vision`
   - `progress.streak`
   - `daily.levers`
4. **生成文案**: 根据 `streak` 动态选择模板
   - streak >= 30 → "一个月了！"
   - streak >= 7 → "一周连续签到！"
   - streak >= 3 → "连续第{streak}天！"
   - default → "早上好！准备开始新的一天了吗？"
5. **推送**: 发送通知 + 更新 UI 状态

**生成的提醒数据**:
```json
{
  "reminder_id": "daily_checkin",
  "title": "连续第 7 天！",
  "body": "习惯的种子已经种下，今天继续浇灌。",
  "quick_actions": [
    {"label": "开始", "prompt": "我准备好了，开始今天的杠杆行动"},
    {"label": "低能量", "prompt": "今天能量比较低，帮我调整一下计划"}
  ],
  "data": {
    "streak": 7,
    "todayLevers": [
      {"id": "lever-1", "text": "写作1小时", "completed": false},
      {"id": "lever-2", "text": "阅读30分钟", "completed": false}
    ]
  }
}
```

---

## 🎯 关键设计原则

### 1. 零硬编码 (Zero Hardcoding)

❌ **错误做法** (硬编码):
```typescript
// Chat 组件中硬编码数据
function ChatWelcomeMessage() {
  const fortuneData = {
    headline: "今日运势良好",  // ← 硬编码
    insights: ["适合工作"],    // ← 硬编码
    rating: { overall: 4 }
  };
}
```

✅ **正确做法** (Skill 驱动):
```typescript
// 1. Skill 定义数据生成逻辑
// skills/bazi/reminders.yaml
- id: daily_fortune
  content:
    generator: rules/daily-fortune.md

// 2. Chat 组件只负责展示
function ChatWelcomeMessage({ data }) {
  return <EnhancedFortuneCard data={data.fortuneData} />;
}
```

---

### 2. Proactive 驱动 (Proactive-Driven)

**数据流向**: Skill → Proactive Engine → Database → Dashboard API → Chat Component

```
┌─────────────────────────────────────────────────────────────┐
│                    数据生成 (主动)                           │
│                                                             │
│  Skill Module (reminders.yaml + rules/*.md)                 │
│         ↓                                                    │
│  Proactive Engine (触发 + 生成)                              │
│         ↓                                                    │
│  Unified Profile Database (存储)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                    数据展示 (被动)                           │
│                                                             │
│  Dashboard API (聚合)                                        │
│         ↓                                                    │
│  Chat Component (展示)                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 3. Skill 自治 (Skill Autonomy)

每个 Skill 完全控制自己的数据生成：

| Skill | 数据类型 | 触发方式 | 生成器 |
|-------|---------|---------|-------|
| **Bazi** | 今日运势 | time_based<br/>04:00 每天 | `rules/daily-fortune.md` |
| | 大运交接 | event_based<br/>dayun_change | `rules/dayun-transition.md` |
| | 运势预警 | threshold_based<br/>score < 40 | `rules/fortune-alert.md` |
| **Lifecoach** | 每日签到 | time_based<br/>08:00 每天 | `rules/companion/daily-checkin.md` |
| | 周复盘 | time_based<br/>周日 20:00 | `rules/companion/weekly-review.md` |
| | 周规划 | time_based<br/>周一 08:00 | `rules/companion/weekly-planning.md` |
| | 断签提醒 | event_based<br/>streak_broken | (动态文案) |
| **Zodiac** | 今日行运 | time_based<br/>04:00 每天 | `rules/daily-transit.md` |
| | 水逆预警 | event_based<br/>mercury_retrograde | `rules/mercury-retrograde.md` |

---

## 📝 总结

### 当前架构的优势

| 维度 | 优势 | 实现方式 |
|-----|------|---------|
| **可扩展** | 新增 Skill 无需修改 Chat 组件 | Skill 只需添加 `reminders.yaml` |
| **可配置** | 触发时间、内容模板可配置 | 通过 YAML 配置，无需改代码 |
| **智能化** | 支持事件触发 + 阈值触发 | TriggerDetector 自动检测 |
| **个性化** | 基于用户数据生成内容 | 读取 `life_context` + `profile` |
| **解耦** | Chat 组件只负责展示 | 数据由 Proactive Engine 推送 |

### Chat 组件的职责

✅ **只负责**:
1. 从 Dashboard API 获取数据
2. 数据转换 (useDashboardWelcomeData)
3. UI 展示 (EnhancedFortuneCard, ConversationalLifecoachCard)
4. 交互处理 (签到、快捷按钮点击)

❌ **不负责**:
1. ~~数据生成~~
2. ~~业务逻辑~~
3. ~~触发条件判断~~
4. ~~内容个性化~~

---

**这就是 VibeLife 的数据生成时序链路！** 🎉

所有数据都是 Skill 模块通过 Proactive 机制主动生成，Chat 组件只负责展示和交互，完全符合你的要求。
