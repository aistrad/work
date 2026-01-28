# Lifecoach V2 实现任务清单

> Version: 2.0 | Date: 2026-01-19
> 状态：✅ Phase 1-3 完成 | Phase 4-5 待做

---

## Phase 1: 数据基础 (P0) ✅

### 1.1 工具实现

- [x] **tools/tools.yaml** - 添加新工具定义 ✅
  - read_lifecoach_state (sections: system, north_star, goals, roadmap, current, identity, progress, journal)
  - write_lifecoach_state (深度合并支持)
  - add_journal_entry (数组结构)
  - update_progress (streak 逻辑)

- [x] **tools/handlers.py** - 实现工具处理器 ✅
  - 与 DATA-STRUCTURE.md 对齐
  - 支持嵌套结构 (current.week.rocks, current.daily.levers)
  - deep_merge 函数实现

### 1.2 数据迁移

- [x] 确认现有用户数据不受影响 ✅
- [x] 新用户自动使用 V2 结构 ✅
- [x] 旧用户首次触发 lifecoach 时初始化 V2 结构 ✅

---

## Phase 2: Rules 更新 (P0) ✅

### 2.1 更新现有 Rules

每个 Rule 已添加：
1. 启动前读取 Profile (read_lifecoach_state)
2. 完成后写入 Profile (write_lifecoach_state)
3. 更新 progress

- [x] **rules/pattern-decode.md** ✅
  - 读取: north_star, journal

- [x] **rules/anti-vision.md** ✅
  - 读取: north_star
  - 写入: north_star.anti_vision

- [x] **rules/vision-design.md** ✅
  - 读取: north_star
  - 写入: north_star.vision_scene

- [x] **rules/identity-shift.md** ✅
  - 读取: north_star, goals, identity
  - 写入: identity.*

- [x] **rules/life-game.md** ✅
  - 读取: north_star, goals, current, progress
  - 写入: current.daily

- [x] **rules/stuck-breakthrough.md** ✅
  - 读取: north_star, goals, current, journal
  - 写入: journal (insight)

### 2.2 更新 SKILL.md

- [x] 更新能力索引表格 ✅
- [x] 添加 Profile 集成说明 ✅
- [x] 添加陪伴系统说明 ✅
- [x] 更新触发词 ✅

### 2.3 更新 _index.md

- [ ] 添加新的能力分类
- [ ] 更新流程组合建议

---

## Phase 3: 陪伴系统 (P1) ✅

### 3.1 陪伴 Rules

- [x] **rules/companion/daily-checkin.md** ✅
  - 触发: 每日 8:00
  - 读取: north_star, goals, current, progress
  - 输出: 个性化提醒 + daily_levers 卡片
  - 写入: progress, current.daily

- [x] **rules/companion/weekly-review.md** ✅
  - 触发: 周日 20:00
  - 读取: north_star, goals, current, progress, journal
  - 输出: 周复盘引导 + role_balance 卡片
  - 写入: journal (weekly), goals

- [x] **rules/companion/weekly-planning.md** ✅
  - 触发: 周一 8:00 / 用户主动
  - 读取: north_star, goals, current, progress, journal
  - 输出: 大石头规划引导 + weekly_rocks 卡片
  - 写入: current.week, current.daily

- [ ] **rules/companion/monthly-review.md**
  - 触发: 每月 1 日
  - 读取: current.month, roadmap.quarter
  - 输出: 月度复盘引导
  - 写入: journal (monthly), current.month (下月)

### 3.2 主动推送集成

- [x] **services/proactive/engine.py** ✅
  - 自动加载 skills/*/reminders.yaml
  - 支持 conditions 参数传递

- [x] **services/proactive/trigger_detector.py** ✅
  - 添加 lifecoach 条件检查器:
    - has_data, not_checked_in_today, checked_in_today
    - has_weekly_data, not_reviewed_this_week, not_planned_this_week
    - has_pending_levers, had_streak
  - 添加 streak_broken 事件检测

- [x] **reminders.yaml** ✅
  - daily_checkin: 每日 8:00
  - weekly_review: 周日 20:00
  - weekly_planning: 周一 8:00
  - lever_reminder: 每日 14:00
  - streak_recovery: 断签后 24 小时

---

## Phase 4: Covey 方法论 (P2)

### 4.1 核心 Rules

- [ ] **rules/covey-habit2-begin-end.md** - 以终为始
  ```markdown
  核心: 葬礼想象 + 使命宣言
  读取: north_star
  写入: north_star.mission, roles
  ```

- [ ] **rules/covey-habit3-first-things.md** - 要事第一
  ```markdown
  核心: 时间矩阵 + 大石头
  读取: roles, current
  写入: current.week.rocks
  ```

- [ ] **rules/covey-roles.md** - 角色系统
  ```markdown
  核心: 角色识别 + 年度目标
  读取: north_star, roles
  写入: roles[]
  ```

### 4.2 辅助 Rules (可选)

- [ ] **rules/covey-habit1-proactive.md** - 积极主动
- [ ] **rules/covey-habit4-win-win.md** - 双赢思维
- [ ] **rules/covey-habit5-understand.md** - 知彼解己
- [ ] **rules/covey-habit6-synergize.md** - 统合综效
- [ ] **rules/covey-habit7-sharpen.md** - 不断更新

---

## Phase 5: 展示工具 (P2)

### 5.1 新增卡片类型

- [ ] **show_life_roadmap** - 展示人生路线图
  ```json
  {
    "cardType": "life_roadmap",
    "north_star": "...",
    "year_milestones": [...],
    "current_quarter": "...",
    "current_month": "..."
  }
  ```

- [ ] **show_role_balance** - 展示角色平衡
  ```json
  {
    "cardType": "role_balance",
    "roles": [
      {"name": "创作者", "planned": 3, "done": 2},
      ...
    ]
  }
  ```

- [ ] **show_weekly_rocks** - 展示周大石头
  ```json
  {
    "cardType": "weekly_rocks",
    "week": "2026-01-20",
    "rocks": [
      {"rock": "...", "role": "...", "done": false},
      ...
    ]
  }
  ```

### 5.2 前端组件

- [ ] `apps/web/src/skills/lifecoach/cards/LifeRoadmap.tsx`
- [ ] `apps/web/src/skills/lifecoach/cards/RoleBalance.tsx`
- [ ] `apps/web/src/skills/lifecoach/cards/WeeklyRocks.tsx`

---

## 验收标准

### Phase 1 验收 ✅
- [x] 可以读取/写入 lifecoach 数据 ✅ (测试通过 8/8)
- [x] 数据结构符合 DATA-STRUCTURE.md 定义 ✅
- [x] 现有用户数据不受影响 ✅

### Phase 2 验收 ✅
- [x] 所有现有 Rules 都能读写 Profile ✅
- [x] 用户的愿景/身份等数据能持久化 ✅
- [x] 下次对话能读取到之前的数据 ✅

### Phase 3 验收 ✅
- [x] 每日签到正常推送 ✅ (reminders.yaml + proactive_engine)
- [x] 周复盘正常触发 ✅
- [x] streak 计数正确 ✅
- [x] journal 正常记录 ✅ (数组结构)

### Phase 4 验收
- [ ] Covey 使命宣言流程完整
- [ ] 角色系统可用
- [ ] 大石头规划可用

---

## 风险与依赖

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| Profile 数据量过大 | 读取性能下降 | journal 定期归档 |
| 主动推送打扰用户 | 用户关闭功能 | 提供细粒度控制 |
| 方法论冲突 | 用户困惑 | 清晰的方法论选择引导 |

| 依赖 | 状态 | 说明 |
|-----|------|------|
| life_context._paths | ✅ 已有 | UnifiedProfileRepository 支持 |
| proactive_worker | ✅ 已有 | 需要添加 lifecoach 触发器 |
| 前端卡片系统 | ✅ 已有 | 需要添加新卡片类型 |
