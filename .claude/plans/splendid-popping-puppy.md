# VibeTarget & Journey 页面设计方案

> 日期: 2026-01-22
> 模式: Ultra Deep Analysis → 设计方案

---

## 〇、设计背景

### 0.1 用户决策摘要

| 决策项 | 用户选择 |
|--------|----------|
| 智能排序 | ❌ 不需要（保持现有层级结构） |
| 命理融合 | ❌ 完全分离（Journey 不含命理） |
| 自动进度识别 | ✅ 是，提示用户确认 |
| 优先级 | 1️⃣ 先完善现有流程体验 |
| 核心场景 | 每日打卡 + 周回顾 + 卡住找方向 + 成就感 |
| 默认视图 | 全景视图（北极星→年度→周→今日） |
| 打卡机制 | 保持现状简单化 |

### 0.2 VibeProfile 架构关键点

Journey 页的数据来自 **VibeProfile** 的 `vibe.target` 层。根据最新架构：

```yaml
# VibeProfile 数据结构
profile:
  identity: { birth_info, display_name }

  skills:  # 各 Skill 原始数据（Skills 负责写入）
    lifecoach:
      north_star: { vision_scene, anti_vision_scene, pain_points }
      identity: { current, target }
      goals: [...]
      current: { week, daily, month }
      progress: { current_streak, longest_streak, total_checkins }

  vibe:  # 跨 Skill 共享层（Vibe 负责同步）
    insight: { essence, dynamic, pattern }  # 我是谁
    target: { north_star, goals, focus }    # 我要成为谁 ← Journey 页数据源

  preferences:
    subscribed_skills: [bazi, lifecoach, ...]
```

**关键设计决策**：
1. **Skills 是原始数据**：`skills.lifecoach` 由 lifecoach Skill 写入
2. **Vibe 是共享层**：`vibe.target` 通过 `vibe_sync.yaml` 配置从 `skills.lifecoach` 同步
3. **Journey 页读取 `vibe.target`**：不直接读 `skills.lifecoach`

### 0.3 配置驱动的 Vibe 同步

```yaml
# config/vibe_sync.yaml (已设计)

target:
  north_star:
    source: skills.lifecoach.north_star
  goals:
    source: skills.lifecoach.goals
  focus:
    source: skills.lifecoach.current.month.goal_id
```

### 0.4 Phase 1 路由与 Journey 的联动

Phase 1 Prompt 根据用户画像个性化路由：

```
{personalization_hint} 动态生成：

如果用户有 north_star：
  "用户正在追踪目标：{north_star}，优先考虑 lifecoach"

如果用户关注 career：
  "用户关注职业发展，优先考虑 career/lifecoach"
```

**这意味着**：Journey 页的 `north_star` / `goals` / `focus` 数据会影响 Chat 路由

---

## 一、项目理解

### 1.1 核心定位

VibeLife 的四大支柱中，VibeTarget/Journey 解决的是「**我要成为谁**」的问题：

```
用户问题                     解决方案
───────────────────────────────────────────
"我想找专家咨询"       →  CoreAgent + Skills
"我的信息太分散"       →  VibeProfile
"我是谁？"            →  Me + VibeInsight
"我要成为谁？"        →  VibeTarget (Journey 页)  ← 本次设计焦点
```

### 1.2 VibeTarget 三维模型（来自 v9 顶层架构）

| 维度 | 含义 | 数据来源 |
|------|------|----------|
| Goals（目标）| 我想要什么 | 对话抽取 + 协议流程（Dan Koe/Covey） |
| Focus（聚焦）| 我现在关注什么 | 话题热度 + 目标活跃度 |
| Milestones（里程碑）| 我走过了什么 | 完成记录 + 重要时刻 |

---

## 二、现状评估

### 2.1 已实现（✅）

当前 Journey 页面已实现 **4 状态渐进系统**：

```
State 0 (empty)           → EmptyJourneyCard（引导开始）
State 1 (north_star_set)  → NorthStarCard（愿景 + 反愿景）
State 2 (planned)         → 年度目标 + 月度 Boss
State 3 (executing)       → 完整仪表盘（周大石头 + 每日杠杆）
```

组件结构完整：
- NorthStarCard（北极星愿景）
- YearlyGoalsCard（年度目标）
- MonthlyBossCard（月度 Boss）
- WeeklyActionsCard（周行动）
- JourneyDailyLeversCard（每日杠杆）
- Progress Stats（进度统计）

### 2.2 存在的问题

#### 问题 1：「静态展示」vs「活的生命体」

当前页面是**数据展示**，不是**智能陪伴**：

| 现状 | v9 愿景 |
|------|---------|
| 目标按创建时间排序 | 按对话热度智能排序 |
| 进度需手动更新 | 从对话自动识别进度 |
| 无情绪/上下文感知 | 基于用户状态动态推荐 |

#### 问题 2：「命理」与「目标」的关系不明确

- 当前 Journey 页 **完全不含命理元素**（这是设计决策）
- 但 v10 提出 **Fortune Alignment** 概念：
  ```
  priority_score =
      topic_heat * 0.4 +           // 近期关注度
      fortune_alignment * 0.3 +    // 命理契合度
      archetype_match * 0.3        // 原型匹配度
  ```
- 问题：如何「默认不加入命理，用户主动询问时才提供」？

#### 问题 3：与 Me 页（VibeInsight）的协同

- Me 页：「我是谁」→ 本质 + 动态 + 规律
- Journey 页：「我要成为谁」→ 目标 + 聚焦 + 里程碑
- 两者如何联动？例如：
  - 「你的创造者原型正在显化」→ 推荐创作类目标
  - 「情绪低落 3 天」→ 暂缓目标推进，先关怀

#### 问题 4：数据来源多元化的复杂性

| 数据来源 | 优先级 | 说明 |
|----------|--------|------|
| 协议流程（Dan Koe/Covey）| 最高 | 结构化北极星 + 目标 |
| 对话抽取（ProfileExtractor）| 中 | 自动识别愿望/计划 |
| 用户手动添加 | 低 | Journey 页直接编辑 |

---

## 三、设计决策待定

### D1: 智能排序的实现方式

**选项 A: 纯行为热度**
```
priority = topic_heat * 1.0
```
优点：简单、直观、无命理依赖
缺点：错过「天时」机会

**选项 B: 行为 + 命理融合**
```
priority = topic_heat * 0.5 + fortune_alignment * 0.3 + archetype * 0.2
```
优点：更「懂你」
缺点：增加复杂度、可能让非命理用户困惑

**选项 C: 渐进式**
- 默认使用行为热度
- 用户订阅命理 Skill 后，融入命理元素
- 显式标注「今日运势推荐」vs「高关注度」

### D2: 自动进度识别的交互

用户对话中提到「我完成了写作大纲」→ 如何处理？

**选项 A: 自动标记完成**
- 用户可能不知道发生了什么

**选项 B: 提示确认**
```
检测到你可能已完成「写作大纲」
[确认完成] [忽略]
```
- 增加交互摩擦，但用户可控

**选项 C: 仅显示进展提示**
- 不主动标记，只在 Journey 页显示「检测到进展」
- 用户手动操作

### D3: 命理元素的呈现方式

如果要加入命理：

**选项 A: 完全分离**
- Journey 页无命理，需要时去 Chat 问

**选项 B: 折叠式**
- 默认隐藏，有一个「查看命理视角」按钮

**选项 C: 融合式**
- 直接在目标卡片上显示「今日运势：利推进此目标」

---

## 四、未解决问题

1. **容错策略**：skill_data 缺失（无命盘）时，Journey 页如何呈现？
   - 纯粹基于对话抽取？
   - 引导用户使用命理 Skill？

2. **刷新频率**：
   - 智能排序是实时还是每日？
   - 自动进度检测在对话结束时还是周期性？

3. **移动端适配**：
   - 当前 Journey 页在移动端体验如何？
   - 卡片层级过多是否需要简化？

4. **与 Proactive 的联动**：
   - 推送「你的写作目标 3 天没更新」需要哪些数据？
   - 推送频率控制逻辑？

---

## 五、设计方案

### 5.1 设计原则

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Journey 页设计原则                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. 全景 + 聚焦                                                              │
│     默认全景视图（北极星→年度→月度→周→今日）                                  │
│     每日签到入口明显                                                          │
│                                                                             │
│  2. 智能但不神秘                                                              │
│     智能排序基于对话热度（可解释）                                            │
│     自动进度需用户确认                                                        │
│                                                                             │
│  3. 纯粹目标管理                                                              │
│     不含命理元素（命理去 Chat 问）                                            │
│     重点是陪伴和鼓励，不是预测                                                │
│                                                                             │
│  4. 成就感驱动                                                                │
│     完成任务有视觉反馈                                                        │
│     进度统计清晰                                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Phase 1: 完善现有流程体验

**目标**：优化 4 状态渐进系统的体验，遵循 Journey 设计原则

#### 5.2.1 Journey 设计原则（来自文档）

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       Journey 页面设计原则                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   1. Chat-First                                                         │
│      所有深度交互都回到 Chat，Journey 只负责「展示」和「勾选」            │
│                                                                         │
│   2. 状态驱动                                                            │
│      根据用户完成进度，展示不同的页面状态，引导下一步                     │
│                                                                         │
│   3. 层级清晰                                                            │
│      愿景 → 年 → 季 → 月 → 周 → 日，自上而下，一目了然                   │
│                                                                         │
│   4. 行动优先                                                            │
│      今日杠杆始终可见，降低执行摩擦                                       │
│                                                                         │
│   5. 快捷入口                                                            │
│      常用操作（调整、复盘、卡点）一键进入 Chat                           │
│                                                                         │
│   6. 渐进解锁                                                            │
│      未完成的区块置灰，引导用户按顺序完成设置                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 5.2.2 4 状态渐进系统

| State | 条件 | 展示内容 | CTA |
|-------|------|----------|-----|
| `empty` | 没有北极星愿景 | 引导开始旅程 | "开始设计我的人生" |
| `north_star_set` | 有北极星，无路线图 | 北极星 + 引导制定路线图 | "继续设定目标 →" |
| `planned` | 有路线图，无周大石头 | 北极星 + 路线图 + 引导设定本周 | "设定本周计划 →" |
| `executing` | 有周大石头 | 完整执行仪表盘 | 勾选完成 + 快捷入口 |

#### 5.2.3 优化重点

| 状态 | 当前问题 | 优化方案 |
|------|----------|----------|
| empty | 引导不够吸引 | 加强 value proposition |
| north_star_set | CTA 不够明确 | 突出「制定路线图」按钮 |
| planned | 引导流程不完整 | 强化设定周大石头入口 |
| executing | Mobile 端区块展开/收起 | 记住用户展开偏好 |

#### 5.2.4 Mobile 适配（优先级排序）

```
Mobile 上优先展示高频操作：
1. ☀️ 今日杠杆（最高频）
2. 🪨 本周大石头
3. 📊 月度 Boss
4. 🎯 年度目标
5. ⭐ 北极星（最低频）
```

### 5.3 Phase 2: 自动进度识别

**目标**：从对话中识别任务完成状态，提示用户确认

#### 5.4.1 检测逻辑

```python
async def detect_progress(conversation: Conversation, goals: List[Goal]) -> List[ProgressDetection]:
    """
    每轮对话结束后调用
    """
    prompt = f"""
    用户的目标：
    {[g.title for g in goals]}

    对话内容：
    {conversation.summary}

    判断用户是否提到完成了任何目标？
    输出 JSON: [{{"goal_title": "...", "completed": bool, "evidence": "..."}}]
    """
    return await llm.generate_json(prompt)
```

#### 5.4.2 确认交互

```
┌────────────────────────────────────────────────────────────────┐
│  💡 检测到进展                                                  │
│  ─────────────────────────────────────────────────────────────  │
│  你可能已完成「晨间写作 1 小时」                                  │
│  依据："今天终于完成了早起写作的挑战"                             │
│                                                                 │
│                                     [忽略]  [确认完成 ✓]        │
└────────────────────────────────────────────────────────────────┘
```

### 5.4 数据流设计

```
                         数据写入                         数据读取
                         ────────                        ────────

用户对话 (Chat)
    │
    ├─ lifecoach Skill ──────▶ skills.lifecoach.north_star
    │                          skills.lifecoach.goals
    │                          skills.lifecoach.current
    │                          skills.lifecoach.progress
    │
    ▼
vibe_sync.yaml (P0)
    │
    └─ 配置驱动同步 ──────────▶ vibe.target.north_star
                               vibe.target.goals
                               vibe.target.focus
                                    │
                                    │
              ┌────────────────────┴────────────────────┐
              │                                         │
              ▼                                         ▼
       Journey 页 (前端)                          Phase 1 Prompt
       读取: skills.lifecoach                    读取: vibe.target
       (via state_read API)                      {personalization_hint}
```

### 5.5 API 设计

Journey 页读取 `skills.lifecoach`（通过 state_read API）：

```yaml
# GET /api/journey (前端 API 代理)
# → 调用后端: POST /api/v1/skills/lifecoach/state_read

Request:
  sections: ["north_star", "identity", "roadmap", "current", "progress"]

Response:
  north_star: { vision_scene, anti_vision_scene, pain_points }
  identity: { current, target }
  roadmap: { goals: [...] }
  current:
    week: { rocks: [...] }
    daily: { levers: [...] }
    month: { boss: {...} }
  progress: { current_streak, longest_streak, total_checkins }
```

**注意**：Journey 页直接读 `skills.lifecoach`，不需要经过 `vibe.target`。
`vibe.target` 的同步是为了 Phase 1 Prompt 路由决策使用。

---

## 六、实施计划

### 依赖关系

```
P0: Vibe 同步配置  ← 前置依赖（与 Journey 设计并行）
        │
        ▼
Phase 1: 完善现有流程（无依赖，可先做）
        │
        ▼
Phase 2: 自动进度识别（可选）
```

### P0: Vibe 同步配置（2-3 天）（已有设计，单独实施）

| Day | 任务 | 产出 |
|-----|------|------|
| 1 | 创建 vibe_sync.yaml | target 同步配置 |
| 2 | 实现 sync.py | 配置驱动的同步器 |
| 3 | 集成到 unified_profile_repo | 替代硬编码 |

### Phase 1: 完善现有流程（3-5 天）

| Day | 任务 | 产出 |
|-----|------|------|
| 1 | Empty 状态优化 | EmptyJourneyCard 改版 |
| 2 | Executing 状态优化 | 首屏聚焦 + 折叠设计 |
| 3 | 移动端适配检查 | 响应式优化 |
| 4 | 交互细节打磨 | 动画、反馈、加载状态 |
| 5 | 缓冲 / 用户测试 | Bug 修复 |

### Phase 2: 自动进度识别（可选，3-5 天）

| Day | 任务 | 产出 |
|-----|------|------|
| 1-2 | Progress Detector 开发 | 后端检测逻辑 |
| 3-4 | 确认交互 UI | ProgressConfirmation 组件 |
| 5 | 集成测试 | 验收 |

---

## 七、验收标准

### 功能验收（Phase 1）

- [ ] 4 状态渐进正常工作
- [ ] Executing 状态展示全景视图
- [ ] 折叠状态持久化（记住用户偏好）
- [ ] Mobile 端布局正确
- [ ] Chat-First 交互正确（点击编辑跳转 Chat）

### 功能验收（Phase 2，可选）

- [ ] 自动进度检测准确率 > 70%
- [ ] 确认交互可用

### 体验验收

- [ ] 首屏加载 < 1s
- [ ] 移动端体验流畅
- [ ] 签到入口明显
- [ ] 完成任务有视觉反馈

---

## 八、已确认细节

| 问题 | 决策 |
|------|------|
| 折叠状态记忆 | ✅ 记住用户偏好 |
| 智能排序 | ❌ 不需要，保持层级结构 |
| 命理元素 | ❌ 完全分离，Journey 纯目标管理 |

---

## 九、关键文件清单

### P0: Vibe 同步配置（前置依赖，单独任务）

| 文件 | 修改内容 |
|------|----------|
| 新建: `apps/api/config/vibe_sync.yaml` | Vibe 数据同步配置 |
| 新建: `apps/api/services/vibe/sync.py` | 配置驱动的同步执行器 |
| `apps/api/stores/unified_profile_repo.py` | 调用 sync.py 替代硬编码 |

### Phase 1: 前端优化

| 文件 | 修改内容 |
|------|----------|
| `apps/web/src/components/journey/JourneyContent.tsx` | 折叠设计、首屏聚焦 |
| `apps/web/src/components/journey/EmptyJourneyCard.tsx` | 引导文案优化 |
| `apps/web/src/components/journey/NorthStarCard.tsx` | 展开/折叠逻辑改进 |
| `apps/web/src/hooks/useJourneyData.ts` | 折叠状态持久化 |
| `apps/web/src/utils/storage.ts` | LocalStorage 工具（如需）|

### Phase 2: 自动进度识别（可选）

| 文件 | 修改内容 |
|------|----------|
| 新建: `apps/api/services/journey/progress_detector.py` | 进度检测逻辑 |
| 新建: `apps/web/src/components/journey/ProgressConfirmation.tsx` | 进度确认弹窗 |

---

## 十、验证方案

### Phase 1 验证

1. 启动测试环境 `pnpm dev`
2. 访问 `/journey`
3. 验证：
   - Empty 状态显示优化后的引导
   - Executing 状态首屏聚焦今日任务
   - 折叠的卡片展开后刷新页面仍保持展开
   - 移动端布局正常
   - 4 状态渐进切换正确

### Phase 2 验证（可选）

1. 在 Chat 中表述「我完成了写作任务」
2. 验证 Journey 页显示进度确认提示
3. 点击「确认完成」验证状态更新
