# Soul OS 心理架构设计 v1.1（基于实测优化版）

**文档类型**：Operating System Psychological Architecture
**版本**：v1.1 (Post-Testing Optimization)
**日期**：2026-01-01
**定位**：基于深度心理学的精神数字孪生操作系统
**理论框架**：荣格分析心理学 × 积极心理学 × 行为科学 × 自我决定理论
**工程边界**：以 `system_design_final_mvp.md` 为准，新的前端 http://106.37.170.238:8231/new

---

## 0. 实测发现与本版优化重点

### 0.1 case_test_codex.md 识别的关键缺口

| 缺口类型 | 问题描述 | 影响 | 本版解决方案 |
|---------|---------|------|-------------|
| **Chat 主流程阻塞** | anti-dependency 对新用户默认强触发 daily_limit | 无法获得目标设定与行动处方 | 优化触发策略，增加门槛条件 |
| **A2UI 未渲染** | 前端未实现 action_buttons 渲染 | OS 停留在文字建议层 | 强制 A2UI 协议，前端必须实现 |
| **目标设定缺失** | 无 Goal/OKR/检查点实体与 UI | 无法支撑 benran case 目标-规划-监督闭环 | 新增 Goal 实体与向导流程 |
| **计划未接入** | 后端 `/api/plan/*` 存在但前端未对接 | 成长计划功能不可用 | 前端必须实现计划 UI |
| **复盘缺失** | fortune_reflection 未实现 | 无法形成完整 PDCA 闭环 | 新增复盘 API 与 UI |
| **Check-in 入口缺失** | 情绪打卡只能通过 API 触发 | 用户无法主动打卡 | 前端新增 Check-in UI |

### 0.2 本版核心升级

1. **目标设定模块**：新增 Goal 实体，支撑年/季/月/周目标拆解
2. **复盘模块**：新增 daily/weekly 复盘 API 与 UI
3. **anti-dependency 策略优化**：更精细的触发条件
4. **A2UI 强制渲染**：前端必须实现 action_buttons
5. **Check-in UI**：前端可见入口

---

## 1. 设计哲学（不变）

### 1.1 核心假设

人类心理痛苦的根源在于**自我-自性轴线的断裂**（Ego-Self Axis Alienation）。

现代人面临三重困境：
1. **意义断裂**：事件发生但没有可承载的解释框架
2. **效能断裂**：解释即便成立，也没有下一步行动
3. **身份碎片化**：社交媒体塑造的多重"表演性自我"导致核心自我感的丧失

### 1.2 OS 的一句话定义

**Soul OS = 一个把"情绪—解释—行动—反馈"外部化的自我调节系统**

### 1.3 北极星指标（WCG）

**Weekly Closed-loop Guidance**：用户在一周内完成 ≥1 次"触发 → 指引 → 行动 → 反馈"闭环。

```
完整闭环 = Checkin/Chat → Insight/Prescription → Commitment → Action → Reflection → Memory Update
```

---

## 2. 四层架构（不变）

```
┌─────────────────────────────────────────────────────────────────┐
│                    L3: Synthesis (意识/自我)                     │
│         元认知仲裁器 - GLM 对话 Agent + Guidance Card            │
├─────────────────────────────────────────────────────────────────┤
│                    L2: Agents (策略/超我)                        │
│         多视角并行分析（Prompt模板参数化）                       │
├─────────────────────────────────────────────────────────────────┤
│                    L1: Schema (特质/图式)                        │
│         现代心理学框架（PERMA/VIA/CBT 图式）+ 行为证据汇总       │
├─────────────────────────────────────────────────────────────────┤
│                    L0: Firmware (定数/本我)                      │
│         八字/星盘 + 用户档案（快照化、可追溯）                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 新增：目标设定模块（Goal Setting）

### 3.1 心理学原理

基于 benran case 的"认知/时间/资本三重主权"框架，目标设定需要：
- **长期价值优先**：10年维度思考
- **能力圈 + 第一性原理**：拆解到基础事实
- **区分可逆/不可逆决策**：一号门慎重，二号门快速实验

### 3.2 Goal 实体设计

```json
{
  "goal_id": "uuid",
  "user_id": 123,
  "type": "annual|quarterly|monthly|weekly",
  "title": "目标标题",
  "outcome_measure": "结果指标（如何衡量达成）",
  "lead_measures": ["行为指标1", "行为指标2"],
  "assumptions": ["假设前提1", "假设前提2"],
  "dimension": "cognition|time|capital|mixed",
  "checkpoints": [
    {"date": "2026-01-15", "description": "第一个检查点"}
  ],
  "related_commitments": ["task_id_1", "task_id_2"],
  "status": "active|achieved|abandoned|revised",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### 3.3 数据库表（建议新增）

```sql
CREATE TABLE IF NOT EXISTS fortune_goal (
    goal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES fortune_user(user_id),
    parent_goal_id UUID REFERENCES fortune_goal(goal_id),
    type TEXT NOT NULL CHECK (type IN ('annual','quarterly','monthly','weekly')),
    title TEXT NOT NULL,
    outcome_measure TEXT,
    lead_measures JSONB DEFAULT '[]',
    assumptions JSONB DEFAULT '[]',
    dimension TEXT DEFAULT 'mixed' CHECK (dimension IN ('cognition','time','capital','mixed')),
    checkpoints JSONB DEFAULT '[]',
    status TEXT DEFAULT 'active' CHECK (status IN ('active','achieved','abandoned','revised')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_goal_user_status ON fortune_goal(user_id, status);
```

### 3.4 目标设定流程（7 步模型扩展）

```
原有：Clarify → Insight → Prescription → Commitment → Action → Reflection → Memory Update

扩展：
GoalSet → Clarify → Insight → Prescription → Commitment → Action → Reflection → GoalReview → Memory Update

新增步骤：
- GoalSet：设定目标，拆解为可追踪的 Outcome/Lead/Checkpoint
- GoalReview：周期性复盘目标进展，调整或关闭
```

### 3.5 API 设计

```
POST /api/goal/create          创建目标
GET  /api/goal/list            获取用户目标列表
GET  /api/goal/{goal_id}       获取单个目标详情
PUT  /api/goal/{goal_id}       更新目标
POST /api/goal/{goal_id}/link  关联任务到目标
POST /api/goal/{goal_id}/checkpoint  记录检查点进展
```

### 3.6 前端 UI 要求

- 目标设定向导：引导用户完成 Outcome/Lead/Checkpoint 填写
- 目标卡片：在 Dashboard 概览 Tab 显示当前活跃目标
- 目标关联：任务完成时可关联到目标
- 检查点提醒：到期检查点推送

---

## 4. 新增：复盘模块（Reflection）

### 4.1 心理学原理

复盘是"强化学习"的核心机制：
- **事实层**：发生了什么
- **决策质量层**：决策是否合理（区分运气与判断）
- **四问心法**：人心/道心/精一/中道
- **原则升级**：沉淀经验为可复用规则

### 4.2 Reflection 实体设计

```json
{
  "reflection_id": "uuid",
  "user_id": 123,
  "type": "daily|weekly|monthly|checkpoint",
  "period_start": "2026-01-01",
  "period_end": "2026-01-07",
  "related_goal_id": "uuid|null",
  "facts": {
    "key_events": ["事件1", "事件2"],
    "goals_vs_actual": "目标与实际对比"
  },
  "decision_review": {
    "sample_decisions": [
      {"decision": "决策描述", "info_quality": "high|medium|low", "luck_vs_judgment": "运气30%/判断70%"}
    ]
  },
  "four_questions": {
    "human_heart": "人心驱动分析",
    "dao_heart": "道心对齐分析",
    "essence_one": "精一聚焦分析",
    "middle_way": "中道平衡分析"
  },
  "upgrades": {
    "reinforce": ["要强化的行为"],
    "abandon": ["要废弃的习惯"],
    "system_log": "本期系统升级日志"
  },
  "next_focus": "下一周期关键焦点",
  "created_at": "timestamp"
}
```

### 4.3 数据库表（建议新增）

```sql
CREATE TABLE IF NOT EXISTS fortune_reflection (
    reflection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES fortune_user(user_id),
    type TEXT NOT NULL CHECK (type IN ('daily','weekly','monthly','checkpoint')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    related_goal_id UUID REFERENCES fortune_goal(goal_id),
    facts JSONB DEFAULT '{}',
    decision_review JSONB DEFAULT '{}',
    four_questions JSONB DEFAULT '{}',
    upgrades JSONB DEFAULT '{}',
    next_focus TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reflection_user_type ON fortune_reflection(user_id, type, period_start DESC);
```

### 4.4 复盘触发机制

| 类型 | 触发条件 | 推送方式 |
|-----|---------|---------|
| daily | 每日 21:00-22:00 | 推送 + Chat 提示 |
| weekly | 每周日 | 推送 + Dashboard 提示 |
| monthly | 每月最后一天 | 推送 + Dashboard 提示 |
| checkpoint | Goal 检查点到期 | 推送 + Dashboard 提示 |

### 4.5 API 设计

```
POST /api/reflection/create    创建复盘
GET  /api/reflection/list      获取复盘列表
GET  /api/reflection/latest    获取最新复盘（按类型）
GET  /api/reflection/prompt    获取复盘引导问题（根据类型）
```

### 4.6 前端 UI 要求

- 复盘入口：Dashboard 概览 Tab 显示复盘提示
- 复盘向导：引导式问答完成复盘
- 复盘历史：可回溯历史复盘记录
- 复盘关联：复盘可关联到目标和趋势事件

---

## 5. 优化：anti-dependency 策略

### 5.1 问题分析

当前 `daily_limit` 触发过于激进，导致：
- 新用户首次对话即被截断
- 无法获得目标设定与行动处方
- 用户体验断裂

### 5.2 优化后的触发规则

```python
def check_anti_dependency(user_id: int, session_id: str) -> Optional[Dict]:
    """
    优化后的 anti-dependency 检测
    """
    # 获取用户上下文
    user = get_user(user_id)
    today_sessions = count_today_sessions(user_id)
    today_messages = count_today_messages(user_id)
    has_active_commitment = has_pending_commitment(user_id)
    days_since_register = (datetime.now() - user.created_at).days
    has_completed_onboarding = user.onboarding_completed

    # 新用户豁免期（注册7天内）
    if days_since_register < 7 and not has_completed_onboarding:
        return None  # 不触发 anti-dependency

    # 当日对话轮数阈值（从5提升到8）
    DAILY_MESSAGE_LIMIT = 8

    # 有未完成任务时，降低阈值
    if has_active_commitment:
        DAILY_MESSAGE_LIMIT = 5

    # 触发条件
    if today_messages >= DAILY_MESSAGE_LIMIT:
        # 即使触发，也必须返回至少1个可执行任务
        suggested_task = get_or_create_minimal_task(user_id)
        return {
            "triggered": True,
            "intervention_type": "daily_limit",
            "message": _build_intervention_message(suggested_task),
            "suggested_tasks": [suggested_task]  # 必须有任务
        }

    return None

def _build_intervention_message(task: Dict) -> str:
    """
    构建干预消息，必须包含可执行任务
    """
    return f"""今天我们聊了很多，信息已经足够了。

现在最重要的是**先行动**：
> {task['title']}（约{task.get('minutes', 5)}分钟）

完成后我们再继续。"""
```

### 5.3 触发条件对比

| 条件 | 优化前 | 优化后 |
|-----|-------|-------|
| 日消息阈值 | 5 | 8（有任务时5） |
| 新用户豁免 | 无 | 注册7天内豁免 |
| 返回任务 | 可选 | **必须返回至少1个任务** |
| 首次会话 | 可能触发 | 豁免 |

---

## 6. 优化：A2UI 强制渲染

### 6.1 问题分析

后端返回 A2UI 的 `action_buttons`，但前端未渲染，导致：
- 用户无法点击"开始行动"等按钮
- OS 停留在文字建议层

### 6.2 A2UI 渲染规范（前端必须实现）

```typescript
interface A2UIComponent {
  type: 'markdown_text' | 'action_buttons' | 'chart' | 'form' | 'card';
  title?: string;
  data: any;
}

interface ActionButton {
  label: string;
  action: {
    type: 'start_task' | 'schedule_task' | 'open_panel' | 'opt_out' | 'checkin';
    task_id?: string;
    panel?: string;
  };
}

// 前端必须实现的 action 处理映射
const actionHandlers = {
  'start_task': async (action) => {
    await api.post('/api/dashboard/task/accept', {
      task_id: action.task_id,
      commitment_type: 'start_task'
    });
    refreshTasks();
  },
  'schedule_task': async (action) => {
    await api.post('/api/dashboard/task/accept', {
      task_id: action.task_id,
      commitment_type: 'schedule_task'
    });
    refreshTasks();
  },
  'open_panel': (action) => {
    const panelMap = {
      'quests': 'tasks',  // 统一命名
      'tasks': 'tasks',
      'status': 'status',
      'trends': 'trends'
    };
    setActiveTab(panelMap[action.panel] || action.panel);
  },
  'opt_out': async () => {
    // 记录用户选择暂不执行
    toast('好的，有需要随时告诉我');
  },
  'checkin': () => {
    openCheckinModal();
  }
};
```

### 6.3 后端 panel 命名统一

| 后端返回 | 前端 Tab ID | 说明 |
|---------|------------|------|
| `quests` | `tasks` | 任务 Tab |
| `tasks` | `tasks` | 任务 Tab |
| `status` | `status` | 状态 Tab |
| `trends` | `trends` | 趋势 Tab |
| `overview` | `overview` | 概览 Tab |
| `relations` | `relations` | 关系 Tab |
| `explore` | `explore` | 探索 Tab |

---

## 7. 优化：Check-in UI 入口

### 7.1 前端 UI 要求

1. **概览 Tab 入口**：在 PERMA 状态卡片旁显示"情绪打卡"快捷入口
2. **Omnibar 快捷命令**：输入 `/checkin` 打开打卡面板
3. **Chat 区快捷入口**：聊天区顶部显示常用快捷按钮（查询状态/情绪打卡等）

### 7.2 Check-in Modal 组件

```typescript
interface CheckinModalProps {
  onSubmit: (data: CheckinData) => void;
  onClose: () => void;
}

interface CheckinData {
  mood: '平静' | '焦虑' | '愤怒' | '沮丧' | '悲伤' | '恐惧' | '兴奋' | '开心' | '满足' | '感恩';
  intensity: number;  // 1-10
  note?: string;
}

// UI 结构
<CheckinModal>
  <MoodSelector moods={MOOD_OPTIONS} />
  <IntensitySlider min={1} max={10} />
  <NoteInput placeholder="（可选）写一句话描述" />
  <SubmitButton />
</CheckinModal>
```

### 7.3 情绪分类与调节动作

| 情绪类型 | 强度 | 对 State Score 影响 | 推荐动作 |
|---------|------|-------------------|---------|
| 正向（平静/开心/满足/感恩） | 高(7-10) | +分 | 放大积极体验 |
| 正向 | 中(4-6) | +分（较少） | 维持当前状态 |
| 负向（焦虑/愤怒/沮丧/悲伤/恐惧） | 高(7-10) | 触发任务 | 即时调节动作 |
| 负向 | 中(4-6) | 触发任务 | 认知重评动作 |

---

## 8. 优化：成长计划 UI 接入

### 8.1 前端 UI 要求

1. **探索 Tab 入口**：在"修习课程"区域显示计划列表
2. **计划详情页**：显示计划进度、当日任务、历史打卡
3. **计划打卡**：每日指令完成后可记录

### 8.2 计划状态流转

```
available → enrolled → active → (paused) → completed
                              ↑           ↓
                              └───────────┘
```

### 8.3 API 使用

```
GET  /api/plan/list     获取可用计划列表
POST /api/plan/join     加入计划
GET  /api/plan/active   获取当前活跃计划（含当日指令）
POST /api/plan/record   记录每日完成
```

---

## 9. 数据流与工程映射（更新）

### 9.1 完整数据流（含新增模块）

```
用户输入（Zone A Omnibar / Zone B 按钮 / Check-in / Goal 设定）
    ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Soul OS 服务层（services/soul_os.py）          │
│                                                                  │
│  1. get_l0_facts() ─────────→ L0 八字事实快照                    │
│  2. get_l1_schema() ────────→ L1 PERMA + 行为证据                │
│  3. get_active_goals() ─────→ 当前活跃目标（新增）               │
│  4. search_knowledge_base() → L2 知识库检索                      │
│  5. calculate_state_score() → State Score 计算                   │
│  6. check_anti_dependency() → 反依赖检测（优化）                 │
│  7. build_system_prompt() ──→ L3 GLM Prompt 构建                 │
│  8. build_user_context() ───→ 完整上下文打包                     │
└────────┬────────────────────────────────────────────────────────┘
         ↓
┌─────────────────┐
│   GLM 调用       │ ← L2 + L3 整合
└────────┬────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│                        输出处理                                  │
│  1. 解析 A2UI JSON                                               │
│  2. 写入 fortune_conversation_message                            │
│  3. 写入 fortune_commitment（status=suggested）                  │
│  4. 关联到 fortune_goal（如有）                                  │
│  5. 返回前端 Zone A 渲染（含 action_buttons）                    │
│  6. 联动更新 Zone B Dashboard                                    │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 OS 概念 → 工程对象映射（更新）

| OS 概念 | SSOT 表 | 关键 API | 前端位置 |
|---------|---------|----------|----------|
| Ego 对话 | `fortune_conversation_*` | `POST /api/chat/send` | Zone A |
| L0 先验 | `fortune_user` / `fortune_bazi_snapshot` | `PUT /api/user/profile` | Zone B 状态 |
| L1 图式 | `fortune_user_preferences` + 行为表汇总 | `GET /api/dashboard/status` | Zone B 状态 |
| State Score | 运行时计算 | `GET /api/dashboard/overview` | Zone B 概览 |
| PERMA | 运行时汇总 | `GET /api/dashboard/status` | Zone B 状态 |
| Commitment | `fortune_commitment` | `POST /api/dashboard/task/*` | Zone B 任务 |
| 情绪打卡 | `fortune_checkin` | `POST /api/dashboard/checkin` | Zone A / B |
| **目标** | `fortune_goal`（新增） | `/api/goal/*` | Zone B 概览/任务 |
| **复盘** | `fortune_reflection`（新增） | `/api/reflection/*` | Zone B 概览/趋势 |
| 成长计划 | `fortune_plan_*` | `/api/plan/*` | Zone B 探索 |
| 趋势数据 | `fortune_checkin` + `fortune_commitment` | `GET /api/dashboard/trends` | Zone B 趋势 |
| 关系 | `fortune_relation` | `GET /api/dashboard/relations` | Zone B 关系 |

---

## 10. 前端实现优先级（P0→P2）

### P0：让用户能跑通闭环（必须）

1. **修复 basePath 路由一致性**：所有内部链接使用 Next.js Link 组件
2. **渲染 A2UI action_buttons**：实现完整的 action 处理映射
3. **Check-in UI 入口**：在概览 Tab 和 Omnibar 提供可见入口
4. **Plan UI 接入**：在探索 Tab 接入 `/api/plan/*`

### P1：目标设定与复盘产品化

1. **目标设定向导**：引导用户完成 Goal 创建
2. **目标卡片**：在概览 Tab 显示当前活跃目标
3. **复盘入口与向导**：daily/weekly 复盘引导式问答
4. **任务-目标关联**：完成任务时可关联到目标

### P2：体验与规模化

1. **任务状态刷新策略**：Tab 切换/操作后自动 refetch
2. **Asset Layer**：Pin/Save as Page/To Quest 持久化
3. **Push 通知**：复盘提醒、检查点到期提醒
4. **分享模板**：State Score / 目标进度 分享图

---

## 11. 后端实现优先级（P0→P2）

### P0：保证 Chat 主流程可用且"可行动"

1. **优化 anti-dependency 策略**：新用户豁免 + 必须返回任务
2. **统一 panel 命名**：与前端 Tab ID 对齐
3. **GLM 降级**：不可用时返回规则模板 A2UI

### P1：补齐目标/复盘数据闭环

1. **实现 Goal API**：`/api/goal/*`
2. **实现 Reflection API**：`/api/reflection/*`
3. **复盘触发器**：定时任务触发复盘提醒
4. **目标-任务关联**：任务完成时更新目标进度

### P2：治理与可观测

1. **全链路 correlation_id**
2. **结构化审计日志**
3. **LLM 失败可回放**

---

## 12. 验收标准（WCG + 新增）

### 12.1 原有 WCG 验收

```sql
WITH weekly_loop AS (
  SELECT
    user_id,
    DATE_TRUNC('week', created_at) AS week,
    BOOL_OR(accepted_at IS NOT NULL) AS has_commitment,
    BOOL_OR(status = 'done') AS has_action
  FROM fortune_commitment
  GROUP BY user_id, DATE_TRUNC('week', created_at)
)
SELECT
  user_id,
  week,
  (has_commitment AND has_action) AS wcg_achieved
FROM weekly_loop;
```

### 12.2 新增验收指标

| 指标 | 定义 | 目标 |
|-----|------|------|
| **目标设定率** | 注册7天内设定至少1个目标的用户比例 | ≥30% |
| **复盘完成率** | 每周完成至少1次复盘的用户比例 | ≥20% |
| **Check-in 使用率** | 每周至少1次情绪打卡的用户比例 | ≥40% |
| **A2UI 点击率** | action_buttons 被点击的比例 | ≥50% |
| **计划参与率** | 加入至少1个成长计划的用户比例 | ≥25% |

---

## 13. 实施路线图

### Phase 1（2周）：P0 必须项

- [ ] 前端：修复 basePath 路由
- [ ] 前端：实现 A2UI action_buttons 渲染
- [ ] 前端：添加 Check-in UI 入口
- [ ] 前端：接入 Plan UI
- [ ] 后端：优化 anti-dependency 策略
- [ ] 后端：统一 panel 命名

### Phase 2（2周）：P1 目标与复盘

- [ ] 后端：实现 Goal API
- [ ] 后端：实现 Reflection API
- [ ] 前端：目标设定向导
- [ ] 前端：复盘引导式问答
- [ ] 前端：任务-目标关联

### Phase 3（2周）：P2 体验优化

- [ ] 前端：刷新策略优化
- [ ] 前端：Asset Layer
- [ ] 后端：Push 通知
- [ ] 后端：审计日志

---

## 附录 A：GLM System Prompt（更新）

新增目标与复盘相关指令：

```text
【输入新增】
- active_goals：用户当前活跃的目标列表
- recent_reflections：最近的复盘记录
- plan_enrollment：当前参与的成长计划

【输出新增】
- 当用户提及目标设定时，引导使用 Goal 实体
- 当用户完成任务时，询问是否关联到目标
- 当检测到需要复盘时，提供复盘引导
- 当用户处于计划中时，优先推荐计划内任务

【四问心法集成】
在重要决策建议中，可选择性展示：
- 人心问：当前动机中的风险点
- 道心问：是否符合长期价值
- 精一问：理解深度与聚焦程度
- 中道问：各张力维度的平衡点
```

---

## 附录 B：参考文献（新增）

11. Kaplan, R.S. & Norton, D.P. (1996). *The Balanced Scorecard*. (OKR/目标管理)
12. Kolb, D.A. (1984). *Experiential Learning*. (复盘/经验学习)
13. Argyris, C. (1991). Teaching Smart People How to Learn. *Harvard Business Review*. (双环学习)

---

*本文档基于 case_test_codex.md 实测反馈优化，与 Fortune AI Final MVP 技术架构对齐，新增目标设定与复盘模块设计。*
