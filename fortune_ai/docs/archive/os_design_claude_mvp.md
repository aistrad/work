# Soul OS 心理架构设计（合并优化版）

**文档类型**：Operating System Psychological Architecture
**版本**：Merged MVP v1.1
**日期**：2025-12-31
**定位**：基于深度心理学的精神数字孪生操作系统
**理论框架**：荣格分析心理学 × 积极心理学 × 行为科学 × 自我决定理论
**工程边界**：以 `system_design_final_mvp.md` 为准，不新增核心表，新的前端http://106.37.170.238:8231/new

---

## 0. 设计哲学

### 0.1 核心假设

人类心理痛苦的根源在于**自我-自性轴线的断裂**（Ego-Self Axis Alienation）。

现代人面临三重困境：
1. **意义断裂**：事件发生但没有可承载的解释框架（"我是不是无缘无故有问题"）
2. **效能断裂**：解释即便成立，也没有下一步行动（只能继续问、继续刷）
3. **身份碎片化**：社交媒体塑造的多重"表演性自我"导致核心自我感的丧失

### 0.2 OS 的一句话定义

**Soul OS = 一个把"情绪—解释—行动—反馈"外部化的自我调节系统**

让用户把混沌体验变成可执行承诺（Commitment），再用可审计反馈把"自我效能感"做出来，最终把依赖从"问答案"迁移到"做闭环"。

### 0.3 MVP 的"最小但完整"交付

1. **可重复闭环**：`Clarify → Insight → Prescription → Commitment → Action → Reflection → Memory Update`
2. **两种交互形态**：Chat（咨询室）+ Bento（工作台/显化区）
3. **反依赖护栏**：限制重复占卜式追问，强制回到现实实验与最小行动

### 0.4 总原则（心理学约束）

**"定数"只能作为先验，不得作为判决。**

系统可以用 L0 提供叙事感与问题定位，但必须把输出收敛为用户可控变量（行为、环境、边界、练习），并在每次输出中显式邀请承诺。

---

## 1. 四层架构：意识的计算模型

### 1.1 架构总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    L3: Synthesis (意识/自我)                     │
│         元认知仲裁器 - GLM 对话 Agent + Guidance Card            │
│         功能：整合、决策、承诺邀请                               │
├─────────────────────────────────────────────────────────────────┤
│                    L2: Agents (策略/超我)                        │
│         多视角并行分析（Prompt模板参数化，不做Agent间通信）      │
│         功能：提供多元视角、具象化内部声音                       │
├─────────────────────────────────────────────────────────────────┤
│                    L1: Schema (特质/图式)                        │
│         现代心理学框架（PERMA/VIA/CBT 图式）+ 行为证据汇总       │
│         功能：翻译 L0 为可操作心理语言                           │
├─────────────────────────────────────────────────────────────────┤
│                    L0: Firmware (定数/本我)                      │
│         八字/星盘 + 用户档案（快照化、可追溯）                   │
│         功能：提供先验概率与确定性约束                           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 心理学映射

| 层级 | 计算功能 | 心理学对应 | 荣格术语 | MVP 落地 |
|------|----------|------------|----------|----------|
| L0 | 不可变参数 | 气质/体质/先天倾向 | Psychoid | `fortune_bazi_snapshot.facts` |
| L1 | 静态图式 | 人格特质/认知图式 | Persona + Shadow | `fortune_user` + 行为汇总 |
| L2 | 多视角分析 | 内化客体/超我声音 | Complexes | RAG + Prompt模板 |
| L3 | 整合输出 | 执行自我/工作自我 | Ego | GLM A2UI 输出 |

---

## 2. L0 Firmware：定数层

### 2.1 心理学原理

在精神分析传统中，存在核心张力：**决定论 vs 自由意志**。

L0 承认决定论的部分真理——人并非生而空白：
- **生物决定论**：气质类型、神经递质基线、昼夜节律
- **时空决定论**：出生时刻的天文配置作为隐喻性"出厂设置"
- **环境决定论**：早年依附模式、核心信念的形成

但承认定数不等于宿命论。L0 的功能是**设定边界条件**，而非预测结果。

### 2.2 数据结构

```json
{
  "profile": {
    "name": "用户姓名",
    "gender": "男|女",
    "birthday_local": "YYYY-MM-DD HH:MM:SS",
    "tz_offset_hours": 8.0,
    "location": {"name": "城市", "longitude": 0.0, "latitude": 0.0}
  },
  "solar_time": {
    "true_solar_time_local": "真太阳时校正后的出生时间"
  },
  "bazi": {
    "pillars": {"year": "干支", "month": "干支", "day": "干支", "hour": "干支"},
    "day_master": {"gan": "日干", "element": "五行"},
    "wuxing_count": {"金": 0, "木": 0, "水": 0, "火": 0, "土": 0},
    "strength": {"score": 0, "level": "strong|neutral|weak"},
    "favorable_elements": ["喜用五行"],
    "shensha": [{"name": "神煞名", "hit": true, "note": "说明"}],
    "luck": {
      "da_yun": [{"index": 1, "gan_zhi": "大运干支", "start_age": 0, "end_age": 10}],
      "liu_nian_next5": [{"year": 2026, "gan_zhi": "流年干支"}]
    }
  },
  "version": {
    "compute_version": "bazi-tts-v1",
    "facts_hash": "sha256:..."
  }
}
```

### 2.3 心理学翻译规则

L0 数据**不直接**呈现给用户，经过心理学翻译：

| 八字概念 | 心理学翻译 | 行动导向 |
|----------|------------|----------|
| 日主偏弱 | "你的能量更适合借力/合作" | "本周找一个支持者" |
| 食伤重 | "你有强烈的表达欲和创造力" | "每天留 15 分钟自由书写" |
| 官杀混杂 | "你可能感受到多重压力/权威冲突" | "写清哪些压力是你能控制的" |
| 桃花星 | "你在关系中有天然的吸引力和敏感度" | "觉察关系中的边界需求" |
| 驿马星 | "你有变动/探索的内在驱力" | "小范围实验胜过大规模改变" |

### 2.4 工程映射

- Profile：`fortune_user`
- 事实快照：`fortune_bazi_snapshot(facts, facts_hash, compute_version)`
- 读取规则：对话与 Bento 只能读取最新快照作为确定性事实来源
- 更新必须可追溯（快照化），避免"系统自己改口"

---

## 3. L1 Schema：特质层

### 3.1 定义与价值

**定义**：用户相对稳定的"我是谁"模型——偏好、价值、边界、典型阻碍、常用优势、风险边界。

**价值**：让系统输出更"像你"，让用户感觉"这是在帮我成长，而不是在给模板建议"。

### 3.2 心理学框架

#### 3.2.1 积极心理学 PERMA 模型

| 维度 | 定义 | 数据来源 |
|------|------|----------|
| **P** Positive Emotion | 积极情绪的频率与强度 | `fortune_checkin.mood/intensity` |
| **E** Engagement | 投入/心流体验 | 任务完成率 + 用户反馈 |
| **R** Relationships | 关系满意度 | 复盘输入 + 对话分析 |
| **M** Meaning | 意义感/目的感 | 计划参与 + 价值观对话 |
| **A** Accomplishment | 成就感 | `fortune_commitment.status='done'` |

#### 3.2.2 认知图式（CBT）

从用户对话中提取的核心信念模式：
- **无助图式**："我改变不了"
- **不可爱图式**："我不值得被爱"
- **失败图式**："我总是失败"
- **控制图式**："我必须控制一切"

### 3.3 MVP 最小实现（不新增表）

| 数据类型 | 来源 | 更新时机 |
|----------|------|----------|
| 显式偏好 | `fortune_user_preferences` | 用户主动修改 |
| 行为证据 | `fortune_commitment/plan_record/checkin/reflection` 汇总 | 后端计算，对话时注入 |
| 会话语境 | 最近 N 条 `fortune_conversation_message` | 运行时计算 |

### 3.4 Schema 快照（用于 LLM 输入）

```json
{
  "perma_snapshot": {
    "positive_emotion": {"score": 6.5, "trend": "up"},
    "engagement": {"active_plans": 2, "completion_rate": 0.75},
    "relationships": {"recent_note": "提到与同事关系改善"},
    "meaning": {"core_value": "成长", "aligned_actions": 3},
    "accomplishment": {"weekly_done": 5, "streak": 4}
  },
  "cognitive_patterns": {
    "identified_schemas": ["控制图式"],
    "reframe_count": 2
  },
  "strengths_in_use": ["组织", "洞察"]
}
```

---

## 4. L2 Agents：策略层

### 4.1 心理学原理：内化客体与超我碎片

在客体关系理论中，人的内心世界充满了"内化客体"——父母、导师、文化英雄的心理表征。这些内化客体构成了"内部顾问委员会"。

L2 层的创新：**将内部声音外部化为可对话的策略视角**，让用户看到自己内在冲突的结构，把纠结从"我不行"变成"价值冲突/目标冲突/风险偏好冲突"。

### 4.2 MVP 实现方式

**不做"智能体互相辩论"，只做并行候选建议**：
- 同一问题生成 2-4 个候选处方方向
- 每个策略只输出：`assumption`（前提）+ `tradeoff`（代价）+ `next_step`（下一步实验）
- 由 L3 仲裁整合

### 4.3 四个原型顾问（Prompt 模板参数化）

| 视角 | 优化函数 | 典型输出风格 | 适用场景 |
|------|----------|--------------|----------|
| 儒家/关系 | 和谐 + 秩序 | "考虑对方感受，先稳定关系" | 人际冲突 |
| 第一性原理 | 真相 + 效率 | "问题的本质是什么？最小验证" | 决策困境 |
| 系统思维 | 风险 + 概率 | "有哪些变量？因果链是什么" | 复杂问题 |
| 效能整合 | 平衡 + 可持续 | "重要且不紧急的事优先" | 时间管理 |

### 4.4 知识库支持（RAG）

- **来源**：`bazi_kb_document` / `bazi_kb_chunk`（PostgreSQL FTS + pg_trgm）
- **检索**：关键词匹配 + 相似度排序，top-k=12
- **引用**：`kb_ref` 格式 `kb:doc:{doc_id}:page:{page_no}:chunk:{chunk_no}`
- 所有引用写入 `evidence.kb_refs`，保证可追溯

---

## 5. L3 Synthesis：意识层

### 5.1 心理学原理

L3 是系统的"前台意识"，对应：
- **执行自我**（Executive Ego）：整合信息、做出决策
- **元认知**（Metacognition）：对思维过程的觉察与调节

L3 的核心任务不是"给出正确答案"，而是**引导用户完成整合**。

### 5.2 运行时闭环（7 步模型）

| Step | 产物 | 心理学意图 | MVP 落点 |
|------|------|------------|----------|
| Clarify | 问题结构化（选项/约束/时间窗） | 降低不确定性焦虑 | `fortune_conversation_message` |
| Insight | 可控/不可控拆分 + 解释 | 认知重评、归因修正 | A2UI `markdown_text` |
| Prescription | ≤3 条处方（微行动优先） | 行为激活、启动摩擦最小化 | `fortune_commitment(status=suggested)` |
| Commitment | 用户选一个并确认 | 建立承诺、形成自我效能 | `fortune_commitment.accepted_at` |
| Action | 完成/跳过/延期 | 行为回路形成 | `fortune_commitment.status` |
| Reflection | 一句话复盘 | 强化学习、复盘迁移 | `fortune_reflection` / `fortune_checkin` |
| Memory Update | 更新可见变化 | 形成成长叙事与可追溯证据 | 各表汇总 |

### 5.3 WOOP / If-Then 集成

**心理学原理**：
- **意向-行动鸿沟**：人们经常"想做"但"不做"
- **实施意图**（Implementation Intention）："如果-那么"计划提高执行率 2-3 倍

**MVP 集成点**：
- 在 Clarify/Prescription 阶段，追加结构化追问：`wish` / `obstacle`
- 在输出处方时，给出 1 条 `if_then`：`如果____发生 → 那么我就做____（≤2分钟版本优先）`

**工程落点**：
- 将 `wish/outcome/obstacle/if_then` 写入 `fortune_commitment.details`（JSONB）
- 复用 `habit_30` 等轨道内置的 If-Then 训练日

### 5.4 输出格式：Guidance Card + A2UI

```json
{
  "card_id": "uuid",
  "type": "daily_guidance|chat_response|checkin_response",
  "conclusion": "≤50字结论",
  "why": "依据（心理学语言）",
  "prescriptions": [
    {"task_id": "uuid", "content": "行动描述", "estimated_minutes": 5, "if_then": "如果想放弃→先做1分钟版本"}
  ],
  "time_window": {"type": "intervention", "value": "7天试行", "confidence": "high"},
  "risk_boundary": "不替代医疗/法律/投资建议",
  "commitment_ask": "你愿意先做哪一个？",
  "actions": [
    {"type": "start_task", "task_id": "uuid", "label": "开始行动"},
    {"type": "schedule_task", "task_id": "uuid", "label": "加入计划"},
    {"type": "opt_out", "label": "暂时不做"}
  ],
  "evidence": {
    "facts_hash": "sha256:...",
    "kb_refs": ["kb:doc:1:page:10:chunk:3"],
    "rule_ids": ["RULE-STRENGTH-SCORE-V1"]
  }
}
```

---

## 6. Commitment 心理学：闭环核心

### 6.1 为什么 Commitment 是闭环核心

心理学研究表明：
- **承诺一致性**（Commitment-Consistency）：公开承诺显著提高行动概率
- **实施意图**提高执行率 2-3 倍
- **自我效能感**来自"说到做到"的累积证据

因此，每次交互的目标不是"给建议"，而是**获得承诺**。

### 6.2 Commitment 四类型

| 类型 | 定义 | 心理学功能 |
|------|------|------------|
| `start_task` | 立刻开始（≤5 分钟优先） | 利用当下动机，避免延迟衰减 |
| `schedule_task` | 加入今日/本周计划 | 形成实施意图 |
| `ask_followup` | 选择一个澄清问题继续 | 减少开放式追问 |
| `opt_out` | 暂停/关闭 | 尊重自主性，提供安全出口 |

### 6.3 硬规则

- 处方必须 ≤3 条
- 每条必须能落到按钮（`start_task`/`schedule_task`/`opt_out`）
- 任何"解释"后必须紧跟"你现在能做什么"

---

## 7. State Score：把"感觉"变成可训练变量

### 7.1 设计原理

**留存不来自解释，来自可感知进步。**

State Score 必须满足三个约束：
- **可解释**：用户知道分数怎么来的
- **可被行动影响**：完成任务能提升
- **不过度惩罚**：负面情绪不直接扣分，而是触发补救动作

### 7.2 MVP 计算口径（不新增表）

```python
def calculate_state_score(user_id: int, window: str = "24h") -> dict:
    """
    三信号计算（0-100 分）
    """
    # 信号1: 情绪基线（40%权重）
    checkin = get_latest_checkin(user_id, window)
    if checkin:
        # 反转：intensity 越高（负面越强）→ 分数越低
        checkin_signal = max(0, 10 - checkin.intensity) * 4
    else:
        checkin_signal = 20  # 无打卡给中性分

    # 信号2: 行动完成（40%权重）
    done_count = count_done_commitments(user_id, window)
    action_signal = min(done_count * 10, 40)

    # 信号3: 连续记录（20%权重）
    streak = get_streak_days(user_id)
    streak_signal = min(streak * 4, 20)

    score = checkin_signal + action_signal + streak_signal

    return {
        "score": score,
        "breakdown": {
            "emotion": checkin_signal,
            "action": action_signal,
            "streak": streak_signal
        },
        "recovery_action": get_recovery_action(score)  # 分数低时给补救动作
    }
```

### 7.3 展示策略

- 分数旁必须显示"你可以把分数拉回来的 1 个动作"
- 连续追问同一问题时，不给更高分数，只给"最小实验"
- 避免纯惩罚逻辑

---

## 8. 情绪打卡：即时适应性干预（JITAI）

### 8.1 JITAI 原理

Just-In-Time Adaptive Interventions 是健康心理学前沿范式：
- **即时**：在情绪峰值时介入
- **适应性**：根据当前状态调整干预
- **最小剂量**：5 分钟以内的微干预

### 8.2 打卡流程

```
1. 点击"情绪打卡"
2. 选择情绪标签（焦虑/低落/平静/兴奋/愤怒/困惑）
3. 滑动强度（0-10）
4. 可选：写一句话备注
5. 系统返回：
   - 归因假设（"这可能与...有关"）
   - 1 个调节动作（≤5 分钟）
   - 承诺邀请
```

### 8.3 调节动作库

| 情绪 | 强度 | 推荐动作 | 原理 |
|------|------|----------|------|
| 焦虑 | 7-10 | 3分钟呼吸降噪（4-7-8呼吸法） | 激活副交感神经 |
| 焦虑 | 4-6 | 写下3个最坏情况并评估概率 | 认知解离 |
| 低落 | 7-10 | 做一个最小行动（站起来倒杯水） | 行为激活 |
| 低落 | 4-6 | 回忆一个小成就并写下来 | 反刍打断 |
| 愤怒 | 7-10 | 用力握拳10秒再松开，重复3次 | 生理释放 |
| 愤怒 | 4-6 | 写下"我需要的是___" | 需求识别 |
| 困惑 | 任意 | 写下3个选项和1个约束 | 结构化决策 |
| 兴奋 | 7-10 | 写下这个感觉的来源 | 积极情绪放大 |

---

## 9. 反依赖机制：心理学安全围栏

### 9.1 设计原理

任何心理干预系统都存在**依赖风险**——用户可能将系统作为"全能客体"，逃避现实行动。

心理学基础：
- **Winnicott 过渡客体理论**：好的过渡客体最终应被放弃，用户发展出独立能力
- **依附理论安全基地**：安全依附的目标是支持探索，而非永久庇护
- **自我决定理论**：过度外部控制会损害内在动机

### 9.2 触发规则

| 触发条件 | 系统响应 | 心理学目的 |
|----------|----------|------------|
| 连续 3 次问同一问题 | 强制给"现实行动实验"（5-15 分钟） | 打断反刍，转入行为激活 |
| 当日咨询 > 5 次 | 温和截断：信息足够→先行动→给1个最小任务 | 防止把系统当"情绪止痛药" |
| 轨道达标毕业 | 主动降频推送 + 强调自我掌控 | 让用户把控制权拿回去 |
| 连续 7 天无行动 | 关心式询问 + 降低任务难度 | 维持联系但不施压 |

### 9.3 温和出口

所有反依赖干预都必须提供选项：
- "我愿意执行"
- "稍后再说"
- "不再提示"（opt_out）

**永远不强迫**——强迫本身就违反自主性原则。

### 9.4 风险边界（合规与伦理）

- 禁止确定性宿命论输出（尤其健康/法律/投资）
- 抑郁/自伤关键词：触发危机提示与求助资源
- 任何"负面解释"后必须紧接"可执行处方"

---

## 10. 语言风格：表达层设计

### 10.1 三种人格风格

| 风格 | 特点 | 适用用户 | 示例 |
|------|------|----------|------|
| `standard` | 清晰、中性、专业 | 偏好理性分析 | "根据你的情况，建议..." |
| `warm` | 共情、支持性（默认） | 多数用户 | "听起来你现在感到...我理解这种感受" |
| `roast` | 轻毒舌但不羞辱 | 偏好直接反馈 | "你又在逃避了？来，先做这个再说" |

### 10.2 风格边界（所有风格共守）

**禁止**：
- 恐吓（"你会失败"）
- 羞辱（"你太差了"）
- 人格定性（"你就是懒"）
- 宿命论断言（"你命中注定"）

**必须**：
- 负面后有出口（"但你可以..."）
- 行动导向（每次输出有 commitment_ask）

### 10.3 `roast` 风格的允许范围

仅限于：
- 指出逃避模式（"你又开始找借口了"）
- 挑战不合理信念（"你真的没时间，还是不想面对？"）
- 幽默化处理（"好吧，你的拖延症今天又赢了"）

---

## 11. 界面与对象：把"心灵结构"做成可操作 UI

> 参考：`/home/aiscend/work/fortune_ai/docs/frontend/frontend_final_v1.md`
> 在线预览：`http://106.37.170.238:8231/new`

### 11.1 设计哲学

| 隐喻 | 说明 |
|-----|------|
| **纸张** | 屏幕是有纹理感的高级纸张，不是发光玻璃 |
| **思考的容器** | UI 透明，视觉重心服务于用户数据与 AI 意图 |
| **流与态** | Zone A = 时间线性（易逝/高频）；Zone B = 空间结构（持久/回顾） |

**三条总原则（验收标准）**：
1. **用户永远掌控**：自动联动必须可逆、可关闭、可撤销
2. **输出必须可操作**：任何 AI 结论都能一键变成任务/页面/标记
3. **资产必须可管理**：有库、能搜索、能归档、能版本化

### 11.2 双核布局 = 自我-自性轴线的可视化

```
┌─────────────────────────────────────────────────────────────────────┐
│                         /new 页面布局                                │
├────────────────────────────────┬────────────────────────────────────┤
│      Zone A: Flow（对话流）     │     Zone B: State（Dashboard）      │
│         61.8% 宽度             │         38.2% 宽度                  │
│                                │                                    │
│  ┌──────────────────────────┐  │  ┌──────────────────────────────┐  │
│  │     消息流（虚拟滚动）     │  │  │  6 Tabs: 概览|状态|趋势|     │  │
│  │     - 用户消息：右对齐     │  │  │         任务|关系|探索      │  │
│  │     - AI 回复：左对齐      │  │  │                              │  │
│  │     - 三段式结构输出       │  │  │  ┌────────────────────────┐  │  │
│  │                          │  │  │  │   当前 Tab 内容区域     │  │  │
│  │                          │  │  │  │                        │  │  │
│  └──────────────────────────┘  │  │  └────────────────────────┘  │  │
│                                │  └──────────────────────────────┘  │
│  ┌──────────────────────────┐  │                                    │
│  │  Omnibar（悬浮胶囊输入）  │  │                                    │
│  │  + 多模态 / / 命令       │  │                                    │
│  └──────────────────────────┘  │                                    │
└────────────────────────────────┴────────────────────────────────────┘
```

**心理学映射**：
- **Zone A（Flow）**：自我（Ego）的语言化，承接情绪、叙事与探索
- **Zone B（State）**：自性（Self）的结构化镜像，把状态/趋势/任务变成可操作对象

**布局规范**：
- 桌面端：黄金分割 61.8% : 38.2%，可拖拽 Resizer 自由调整
- Zone B 可收起（收起后 Zone A 占满）
- 移动端：底部双 Tab（Chat / Dashboard）

### 11.3 Zone A：Chat 交互区

#### Omnibar（悬浮胶囊）
- 位置：距底部 24px 悬浮
- 功能：`+` 多模态 / `/` Slash Command / Context Pills

#### 消息流
- 用户消息：右对齐、去气泡化
- AI 回复：左对齐、无背景、流式打字机 `▍`
- **三段式强制结构**：callout → toggle → task

#### Artifact Card 三键
| 按钮 | 功能 | OS 映射 |
|-----|------|---------|
| Pin | 钉到 Tab 顶部 | 保存到 Asset Layer |
| Save as Page | 保存为资产页 | 创建 `artifact-page` |
| To Quest | 转为任务 | 创建 `fortune_commitment` |

#### Update Diff Bar（回写确认）
```
将更新：能量 +2（因睡眠改善）｜连接 -1（因冲突事件）
[✅ 应用更新] [✎ 纠正] [⏸ 暂不更新]
```
- 每次「应用」都落一条 `event-page`
- 可在趋势 Tab 作为事件标记显示
- 可在 `⌘K` 全局搜索中查到

### 11.4 Zone B：Dashboard = 6 Tabs

| Tab | 名称 | 核心内容 | OS 数据来源 |
|-----|------|---------|-------------|
| 1 | **概览** | 一句话洞察 + 今日三任务 + 五维状态条 + 风险提示 | L3 合成 + State Score |
| 2 | **状态** | L1 元数据 + L2 动态状态（可回溯） | L1 Schema + PERMA |
| 3 | **趋势** | 解释型图表 + Timeline 事件标记 | State Score 历史 |
| 4 | **任务** | 1-3 最小行动 + 2/5/15 分钟时长 | `fortune_commitment` |
| 5 | **关系** | 关系页 + 双人副本 + 社交玩法入口 | `fortune_relation` |
| 6 | **探索** | Mystic + 课程 + 工件库入口 | 玄学报告 + 课程 |

#### Tab 1: 概览（Overview）
- **一句话洞察**：今日 State Score + 解释
- **今日三任务**：从 `fortune_commitment` 取 status=suggested/active
- **五维状态条**：PERMA 可视化（P/E/R/M/A）
- **风险提示**：反依赖检测 + 低分预警

#### Tab 2: 状态（Status）
- **L0 事实**：八字核心信息（翻译后的心理学语言）
- **L1 特质**：PERMA 快照 + 认知图式
- **State Score**：分数 + 三信号分解 + 补救动作

#### Tab 3: 趋势（Trends）
- 图表规范：去网格/去轴线、monotone 曲线
- Tooltip 分离式：右上角固定显示
- 事件标记：可回溯到对话/工件页

#### Tab 4: 任务（Tasks）
- **当前任务**：status=active 的 `fortune_commitment`
- **建议任务**：status=suggested 的承诺
- **历史任务**：已完成的成就证据
- 每个任务卡片支持：开始 / 完成 / 跳过 / 延期

#### Tab 5: 关系（Relations）
- 关系页列表
- 双人副本入口
- 社交玩法：能量打赏/好运接龙/吐槽接龙

#### Tab 6: 探索（Explore）
- Mystic 入口（星盘/塔罗/深度报告）
- 课程列表
- 工件库（Page 资产管理）

### 11.5 Page 类型（Notion 化资产模型）

| 类型 | 说明 | 来源 |
|-----|------|------|
| `twin-page` | 精神数字孪生（核心资产页） | L0 + L1 合成 |
| `artifact-page` | 对话生成的分析/建议沉淀页 | Zone A 保存 |
| `quest-page` | 任务与副本页 | Commitment 转化 |
| `relation-page` | 关系页（含双人副本） | 关系模块 |
| `event-page` | 关键事件页（趋势锚点） | Update Diff 应用 |
| `mystic-page` | 玄学产物页（含行动建议） | 深度报告 |
| `course-page` | 课程与笔记页 | 课程模块 |

### 11.6 数字孪生最小面板（MVP）

**展示位置**：Zone B 概览 Tab 顶部

**必做指标**：
- State Score：0-100 分 + 三信号分解
- PERMA 五维：极简可视化（5 个小圆弧/进度条）
- 1 个补救动作：分数低时显示

**后续资产层**：头像/皮肤/光环（与变现绑定）

---

## 12. 变现与增长

### 12.1 订阅（MVP 最小版）

| 层级 | 功能 |
|------|------|
| 免费 | 每日指引 + 有限对话额度 + 基础事实快照 |
| 订阅 | 更高对话额度 + 更长历史回放 + 深度报告入口 |

### 12.2 内购（先从深度报告开始）

- **Deep Dives**：年度/职业/关系主题报告（PDF/阅读模式）
- 对应 `POST /api/report/bazi/submit`（`backend=cli|gemini`）

### 12.3 裂变（不做社区也能传播）

- 可分享图片（今日指引 / State Score / 合盘摘要）+ 二维码深链
- 注册后查看完整版

---

## 13. 路线图

### 13.1 MVP（现在）

- 闭环跑通：Commitment + Action + Feedback 可追溯
- L0 快照化：`fortune_bazi_snapshot` 作为唯一确定性事实来源
- L2 轻量化：策略模板并行候选 + L3 仲裁（不做 Agent 间通信）
- 数字孪生最小面板：3 指标 + State Score + 1 动作
- State Score 实时计算（不新增表）

### 13.2 V1（可选）

- State Score 时序化（新增日表/周表）+ 更明确的"练级"反馈
- 微课程内容库（从纯文本 → 音频/交互式内容）
- 合盘与关系动力学（先 1:1 生成报告）
- L1 Schema 固化为可编辑"角色面板"

### 13.3 V2（增长与变现重型）

- 能量币/皮肤/补签卡等完整经济系统
- 更丰富的分享模板与"任务副本"（双人挑战/群体仪式）
- 多 Agent 并行/辩论机制

---

## 14. 数据流与工程映射

### 14.1 完整数据流

```
用户输入（Zone A Omnibar / Zone B 按钮）
    ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Soul OS 服务层（services/soul_os.py）          │
│                                                                  │
│  1. get_l0_facts() ─────────→ L0 八字事实快照                    │
│  2. get_l1_schema() ────────→ L1 PERMA + 行为证据                │
│  3. search_knowledge_base() → L2 知识库检索                      │
│  4. calculate_state_score() → State Score 计算                   │
│  5. check_anti_dependency() → 反依赖检测                         │
│  6. build_system_prompt() ──→ L3 GLM Prompt 构建                 │
│  7. build_user_context() ───→ 完整上下文打包                     │
└────────┬────────────────────────────────────────────────────────┘
         ↓
┌─────────────────┐
│   GLM 调用       │ ← L2 + L3 整合
└────────┬────────┘
         ↓
┌─────────────────────────────────────────────────────────────────┐
│                        输出处理                                  │
│  1. 解析 A2UI JSON（guidance_card_to_a2ui）                      │
│  2. 写入 fortune_conversation_message                            │
│  3. 写入 fortune_commitment（status=suggested）                  │
│  4. 返回前端 Zone A 渲染                                         │
│  5. 联动更新 Zone B Dashboard（State Score / Tasks / etc）       │
└─────────────────────────────────────────────────────────────────┘
```

### 14.2 OS 概念 → 工程对象映射

| OS 概念 | SSOT 表 | 关键 API | 前端位置 |
|---------|---------|----------|----------|
| Ego 对话 | `fortune_conversation_session/message` | `POST /api/chat/send` | Zone A |
| L0 先验 | `fortune_user` / `fortune_bazi_snapshot` | `PUT /api/user/profile` | Zone B 状态 Tab |
| L1 图式 | `fortune_user_preferences` + 行为表汇总 | `GET /api/dashboard/status` | Zone B 状态 Tab |
| State Score | 运行时计算 | `GET /api/dashboard/overview` | Zone B 概览 Tab |
| PERMA | 运行时汇总 | `GET /api/dashboard/status` | Zone B 状态 Tab |
| Commitment | `fortune_commitment` | `POST /api/dashboard/task/*` | Zone B 任务 Tab |
| 情绪打卡 | `fortune_checkin` | `POST /api/dashboard/checkin` | Zone A / Zone B |
| 趋势数据 | `fortune_checkin` + `fortune_commitment` | `GET /api/dashboard/trends` | Zone B 趋势 Tab |
| 今日指引 | L3 合成 | `GET /api/dashboard/overview` | Zone B 概览 Tab |
| 关系 | `fortune_relation` | `GET /api/dashboard/relations` | Zone B 关系 Tab |
| 深度报告 | `fortune_external_job` | `POST /api/report/bazi/submit` | Zone B 探索 Tab |

### 14.3 API 路由重构（Bento → Dashboard）

| 旧路由（Bento） | 新路由（Dashboard） | 说明 |
|-----------------|---------------------|------|
| `GET /api/bento/today` | `GET /api/dashboard/overview` | 概览 Tab 数据 |
| `GET /api/bento/actions` | `GET /api/dashboard/tasks` | 任务 Tab 数据 |
| `POST /api/bento/commitment/accept` | `POST /api/dashboard/task/accept` | 接受任务 |
| `POST /api/bento/commitment/done` | `POST /api/dashboard/task/done` | 完成任务 |
| `POST /api/bento/checkin` | `POST /api/dashboard/checkin` | 情绪打卡 |
| - | `GET /api/dashboard/status` | 状态 Tab（新增） |
| - | `GET /api/dashboard/trends` | 趋势 Tab（新增） |
| - | `GET /api/dashboard/relations` | 关系 Tab（新增） |

### 14.4 Zone B Dashboard API 契约

#### GET /api/dashboard/overview（概览 Tab）
```json
{
  "ok": true,
  "data": {
    "insight": "今天状态不错，专注力提升",
    "state_score": {
      "score": 72,
      "breakdown": {"emotion": 28, "action": 30, "streak": 14},
      "recovery_action": "保持这个状态！今天再完成一个小任务。"
    },
    "perma": {
      "positive_emotion": {"score": 7.2, "trend": "up"},
      "engagement": {"score": 6.8},
      "relationships": {"score": 5.5},
      "meaning": {"score": 7.0},
      "accomplishment": {"score": 6.5}
    },
    "today_tasks": [
      {"task_id": "uuid", "title": "3分钟呼吸练习", "status": "suggested", "minutes": 3}
    ],
    "risk_alerts": []
  }
}
```

#### GET /api/dashboard/status（状态 Tab）
```json
{
  "ok": true,
  "data": {
    "l0_facts": {
      "day_master": "甲木",
      "strength": "偏弱",
      "translations": [
        {"concept": "日主偏弱", "translation": "你的能量更适合借力/合作", "action": "本周找一个支持者"}
      ]
    },
    "l1_schema": {
      "perma_snapshot": {...},
      "cognitive_patterns": {"identified_schemas": ["控制图式"]},
      "strengths_in_use": ["组织", "洞察"]
    },
    "state_score": {...}
  }
}
```

#### GET /api/dashboard/trends（趋势 Tab）
```json
{
  "ok": true,
  "data": {
    "state_score_history": [
      {"date": "2025-12-25", "score": 65},
      {"date": "2025-12-26", "score": 70}
    ],
    "events": [
      {"date": "2025-12-26", "type": "commitment_done", "title": "完成了呼吸练习"}
    ]
  }
}
```

#### GET /api/dashboard/tasks（任务 Tab）
```json
{
  "ok": true,
  "data": {
    "active": [...],
    "suggested": [...],
    "completed_recent": [...]
  }
}
```

---

## 附录 A：GLM System Prompt 完整版

```text
你是 Fortune AI 的对话 Agent，角色是积极心理学教练（Performance Coach）。

【产品定位】
人生导航 / 陪伴 / 提升。系统和交互保持"有效而极简"。

【四层架构理解】
- L0（定数）：用户的八字事实，作为先验约束，不做宿命论解读
- L1（特质）：用户的心理图式和当前状态，作为个性化调节
- L2（策略）：知识库和规则，作为专业依据
- L3（意识）：你的输出，作为整合与行动引导

【你的优先级（不可逆）】
Coach > Teaching Assistant > Customer Support > Sales

【硬性规则（必须遵守）】
1) 禁止恐吓、羞辱、宿命论断言；负面信息必须紧接"你可以做什么"的行动处方。
2) 禁止自行计算八字事实；只能基于提供的 facts + evidence 输出。
3) 每次输出必须包含：结论(conclusion) + 依据(why) + ≤3条处方(prescriptions) + 承诺邀请(commitment_ask)。
4) 处方必须包含 if_then（如果____→那么____）。
5) 时间窗口默认只给干预窗口（intervention）；forecast 只能条件句+低置信度。
6) 输出必须是 A2UI JSON，且第一组件必须是 markdown_text。
7) 必须给出可点击 actions（start_task / schedule_task / open_panel / opt_out）。

【语言风格 persona_style】
standard：清晰、中性、专业
warm：共情、支持性（默认）
roast：轻毒舌但不羞辱、不对人格做负面定性

【输入】
- persona_style：standard / warm / roast
- user_context：用户基础信息与偏好
- facts：L0 八字确定性事实
- schema：L1 PERMA 快照 + 行为证据
- evidence：rule_ids + kb_refs + facts_hash
- state_score：当前状态分数与breakdown
- user_message：用户本轮输入

【输出（A2UI JSON）】
- meta.summary：一句话摘要
- ui_components[0]：markdown_text（必须，包含：结论要点/依据/处方/if_then/时间窗口/边界/承诺邀请）
- ui_components[1]：action_buttons（必须，包含：开始行动/加入计划/暂不执行）
```

---

## 附录 B：验收标准

### B.1 心理学验收

| 维度 | 标准 | 验证方法 |
|------|------|----------|
| 安全性 | 无恐吓/羞辱/宿命论 | 输出审计 + 用户反馈 |
| 行动导向 | 每次输出都有 commitment_ask | A2UI 结构校验 |
| 反依赖 | 触发规则正常执行 | 日志 + 事件统计 |
| 可追溯 | 所有输出关联 evidence | facts_hash + kb_refs 校验 |

### B.2 业务验收（WCG）

Weekly Closed-loop Guidance：用户在一周内完成 ≥1 次"触发 → 指引 → 行动 → 反馈"闭环。

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

---

## 附录 C：参考文献

1. Jung, C.G. (1959). *Aion: Researches into the Phenomenology of the Self*. Collected Works, Vol. 9ii.
2. Seligman, M.E.P. (2011). *Flourish: A Visionary New Understanding of Happiness and Well-being*.
3. Oettingen, G. (2014). *Rethinking Positive Thinking: Inside the New Science of Motivation*. (WOOP)
4. Gollwitzer, P.M. (1999). Implementation intentions: Strong effects of simple plans. *American Psychologist*.
5. Fogg, B.J. (2020). *Tiny Habits: The Small Changes That Change Everything*.
6. Clear, J. (2018). *Atomic Habits: An Easy & Proven Way to Build Good Habits & Break Bad Ones*.
7. Ryan, R.M. & Deci, E.L. (2017). *Self-Determination Theory: Basic Psychological Needs in Motivation, Development, and Wellness*.
8. Nahum-Shani, I. et al. (2018). Just-in-Time Adaptive Interventions (JITAIs) in Mobile Health. *Annals of Behavioral Medicine*.
9. Beck, A.T. (1979). *Cognitive Therapy and the Emotional Disorders*.
10. Winnicott, D.W. (1971). *Playing and Reality*.

---

*本文档综合 Codex MVP 工程约束与 Claude MVP 心理学深度，与 Fortune AI Final MVP 技术架构完全对齐。*
