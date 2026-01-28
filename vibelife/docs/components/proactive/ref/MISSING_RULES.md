# Proactive 模块缺失的 Rules 文件清单

> 生成时间: 2026-01-19
>
> 这些 rules 文件在 `reminders.yaml` 中被引用，但尚未创建。
> 各 Skill 负责人需要补齐这些文件以支持 Proactive 内容生成。

## 文件命名规范

```
apps/api/skills/{skill_id}/rules/{rule-id}.md
```

## 缺失文件列表

### 🔴 bazi (3个)

| 文件 | 用途 | 引用位置 | 优先级 |
|-----|------|---------|--------|
| `rules/daily-fortune.md` | 每日运势内容生成 | daily_fortune reminder | P0 |
| `rules/dayun-transition.md` | 大运交接提醒内容 | dayun_transition reminder | P1 |
| `rules/fortune-alert.md` | 运势预警内容生成 | fortune_alert reminder | P1 |

**注意**: 现有 `rules/fortune.md` 是通用运势分析规则，与 `daily-fortune.md` 不同。

---

### 🔴 core (8个)

| 文件 | 用途 | 引用位置 | 优先级 |
|-----|------|---------|--------|
| `rules/weekly-summary.md` | 每周运势总结 | weekly_summary reminder | P0 |
| `rules/monthly-report.md` | 每月深度报告 | monthly_report reminder | P0 |
| `rules/birthday.md` | 生日提醒内容 | birthday reminder | P1 |
| `rules/daily-plan.md` | 每日计划生成 | daily_plan reminder | P2 |
| `rules/daily-checkin.md` | 每日打卡复盘 | daily_checkin reminder | P2 |
| `rules/weekly-review.md` | 周复盘内容 | weekly_review reminder | P2 |
| `rules/milestone.md` | 里程碑提醒 | milestone_reminder | P2 |
| `rules/celebration.md` | 庆祝内容生成 | streak_celebration | P2 |

**注意**: Core Skill 目前没有 `rules/` 目录，需要先创建。

---

### 🟡 mindfulness (1个)

| 文件 | 用途 | 引用位置 | 优先级 |
|-----|------|---------|--------|
| `rules/celebration.md` | 里程碑庆祝内容 | streak_* reminders | P2 |

**现有 rules 文件** (可复用):
- ✅ `rules/morning.md` - 晨间正念
- ✅ `rules/sleep.md` - 睡前放松
- ✅ `rules/stop.md` - STOP 练习
- ✅ `rules/rain.md` - RAIN 练习
- ✅ `rules/integration.md` - 整合练习
- ✅ `rules/breathing.md` - 呼吸练习

---

### ✅ zodiac (全部已有)

所有引用的 rules 文件均已存在：
- ✅ `rules/transit.md`
- ✅ `rules/cycles.md`

---

## 统计

| Skill | 缺失数量 | 优先级分布 |
|-------|---------|-----------|
| bazi | 3 | P0:1, P1:2 |
| core | 8 | P0:2, P1:1, P2:5 |
| mindfulness | 1 | P2:1 |
| zodiac | 0 | - |
| **总计** | **12** | P0:3, P1:3, P2:6 |

---

## Rule 文件模板

每个 rule 文件应遵循以下格式：

```markdown
---
id: daily-fortune
name: 每日运势
impact: MEDIUM
impactDescription: 用于生成个性化的每日运势推送内容
tags: 运势, 每日, 推送
---

# 每日运势规则

## 分析要点

| 步骤 | 分析点 | 检索 Query | 优先级 |
|-----|-------|-----------|--------|
| 1 | xxx | "xxx" | 必须 |

## 输出要求

- 内容简短有力，不超过100字
- 包含具体可执行的建议
- 语气温暖但不矫情

## 常见问题

Q: xxx
A: xxx
```

---

## 行动项

### P0 - 立即创建 (3个)
1. [ ] `bazi/rules/daily-fortune.md`
2. [ ] `core/rules/weekly-summary.md`
3. [ ] `core/rules/monthly-report.md`

### P1 - 一周内 (3个)
4. [ ] `bazi/rules/dayun-transition.md`
5. [ ] `bazi/rules/fortune-alert.md`
6. [ ] `core/rules/birthday.md`

### P2 - 后续补齐 (6个)
7. [ ] `core/rules/daily-plan.md`
8. [ ] `core/rules/daily-checkin.md`
9. [ ] `core/rules/weekly-review.md`
10. [ ] `core/rules/milestone.md`
11. [ ] `core/rules/celebration.md`
12. [ ] `mindfulness/rules/celebration.md`
