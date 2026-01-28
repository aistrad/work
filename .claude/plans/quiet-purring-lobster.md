# V8 架构验证实现计划

> 目标：完成设计与实现对齐，达到 1 万付费用户验证状态
> 日期：2026-01-19

---

## 一、现状发现（与预期差异）

### 前端组件（比预期完整）

| 组件 | 预期状态 | 实际状态 | 位置 |
|------|---------|---------|------|
| Dashboard 卡片 | ❌ 缺失 | ✅ 已存在 | `components/dashboard/` |
| LifeCoach Provider | ❌ 缺失 | ✅ 完整 (450行) | `providers/LifeCoachProvider.tsx` |
| Skill 卡片 | ❌ 缺失 | ✅ 已存在 | `skills/lifecoach/cards/` |
| 类型定义 | ❌ 缺失 | ✅ 完整 | `types/lifecoach.ts` |
| API 封装 | ❌ 缺失 | ✅ 完整 | `lib/lifecoach-api.ts` |

**现有 Dashboard 卡片**：
- `MorningBriefingCard.tsx` - 晨间简报
- `TodayFocusCard.tsx` - 今日焦点
- `StreakCard.tsx` - 签到连续
- `NorthStarCard.tsx` - 北极星指南针
- `WeeklyRocksCard.tsx` - 周大石头
- `GoalsBalanceCard.tsx` - 目标平衡

### 后端规则（确实有缺失）

| 项目 | 状态 | 缺失内容 |
|------|------|---------|
| LifeCoach 陪伴规则 | ⚠️ 缺 1 个 | `monthly-review.md` |
| Bazi 规则 | ⚠️ 缺 3 个 | `daily-fortune.md`, `dayun-transition.md`, `fortune-alert.md` |
| Core 规则 | ❌ 缺 8 个 | 整个目录不存在 |

---

## 二、实际需要做的工作

### Phase 1: 验证前端集成 (P0)

**目标**：确认 Dashboard 是否正常工作，定位断层点

**检查项**：
1. [ ] 验证 `DashboardGrid.tsx` 是否正确调用 `useLifeCoach()`
2. [ ] 验证 `LifeCoachProvider` 是否在 auth 变化时自动加载数据
3. [ ] 验证后端 `/lifecoach/state/read` API 是否正常返回数据
4. [ ] 验证 `app/dashboard/page.tsx` 路由是否正确

**关键文件**：
- `/apps/web/src/components/dashboard/DashboardGrid.tsx`
- `/apps/web/src/providers/LifeCoachProvider.tsx`
- `/apps/web/src/app/dashboard/page.tsx`

### Phase 2: 补齐后端规则 (P0)

**目标**：补齐缺失的 Rule 文件

**2.1 LifeCoach 月度复盘** (1 文件)
```
创建: apps/api/skills/lifecoach/rules/companion/monthly-review.md
```

**2.2 Bazi 推送规则** (3 文件)
```
创建: apps/api/skills/bazi/rules/daily-fortune.md    # P0
创建: apps/api/skills/bazi/rules/dayun-transition.md # P1
创建: apps/api/skills/bazi/rules/fortune-alert.md    # P1
```

**2.3 Core 规则** (优先 3 个)
```
创建: apps/api/skills/core/rules/weekly-summary.md   # P0
创建: apps/api/skills/core/rules/monthly-report.md   # P0
创建: apps/api/skills/core/rules/birthday.md         # P1
```

### Phase 3: future_self 体验验证 (P1)

**目标**：确认"来自未来的你"体验是否完整

**检查项**：
1. [ ] 验证 `system.persona = "future_self"` 是否生效
2. [ ] 验证 `north_star.vision_scene` 是否用于生成对话
3. [ ] 验证前端是否有对应的 UI 呈现

**关键文件**：
- `/apps/api/skills/lifecoach/SKILL.md`
- `/apps/api/skills/lifecoach/rules/companion/daily-checkin.md`

### Phase 4: extracted 自动提取 (P1)

**目标**：实现每日例行提取

**架构**：
```
workers/extraction_worker.py (新建)
    │
    ├─ 每日凌晨 04:00 运行（与 Proactive Worker 同时）
    │
    ├─ 获取用户最近 24 小时的对话 (messages 表)
    │
    ├─ 调用 LLM 批量分析，提取：
    │   - facts: 新发现的客观事实
    │   - goals: 提到的目标
    │   - concerns: 关注的问题
    │
    └─ 写入 unified_profiles.profile.extracted
```

**关键文件**：
- 新建: `/apps/api/workers/extraction_worker.py`
- 修改: `/apps/api/stores/unified_profile_repo.py` (添加 update_extracted)

### Phase 5: Cold Layer 使用 (P2)

**目标**：将重要洞察写入 Cold Layer

**修改点**：
- 在 `extraction_worker.py` 中，重要洞察写入 `vibe_profile_insights` 表
- 时间线事件写入 `vibe_profile_timeline` 表

---

## 三、工作量估计

| Phase | 工作内容 | 估计 |
|-------|---------|------|
| Phase 1 | 验证前端集成 | 1-2 小时（调试为主）|
| Phase 2 | 补齐后端规则 | 3-4 小时（7 个文件）|
| Phase 3 | future_self 验证 | 1 小时（验证+修复）|
| Phase 4 | extracted Worker | 2-3 小时（新模块）|
| Phase 5 | Cold Layer | 1 小时（扩展现有）|
| **总计** | | **8-11 小时** |

---

## 四、执行顺序

```
Phase 1 (验证) ──▶ Phase 2 (规则) ──▶ Phase 3 (体验)
                                           │
                                           ▼
                        Phase 5 (Cold) ◀── Phase 4 (提取)
```

**推荐**：先做 Phase 1 验证，可能发现更多问题。

---

## 五、验证方法

### Phase 1 验证
```bash
# 1. 启动测试环境
~/start-test.sh

# 2. 访问 Dashboard
http://106.37.170.238:8232/dashboard

# 3. 检查 API 响应
curl http://127.0.0.1:8100/api/v1/lifecoach/state/read \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sections": ["north_star", "goals", "current", "progress"]}'
```

### Phase 2 验证
```bash
# 测试 Proactive 扫描
python workers/proactive_worker.py --dry-run
```

### Phase 4 验证
```bash
# 测试 Extraction Worker
python workers/extraction_worker.py --once --dry-run
```

---

## 六、风险点

1. **前端可能已工作** - Phase 1 验证可能发现问题不在前端
2. **API 端点可能不存在** - 需要验证 `/lifecoach/state/read` 是否实现
3. **Provider 数据加载时机** - 可能需要调整加载触发条件
