# Dashboard 升级实施计划

> 目标：将 Chat 空状态的 BentoDashboard 升级为更丰富的体验

## 关键发现（大幅降低工作量）

| 功能 | 后端状态 | 前端状态 |
|------|---------|---------|
| 多维度能量 (area_scores) | ✅ 已计算，未暴露 | ✅ 类型已定义 |
| 宜/忌建议 (highlights/cautions) | ✅ 已生成，未映射 | ✅ 类型已定义 |
| 主题 (theme) | ✅ 已生成，未映射 | 需要显示 |
| 名言 (quote) | ❌ 返回 null | ✅ quotes.ts 已有名言库 |

**结论**：主要工作是数据映射 + 前端组件调整，无需复杂计算逻辑开发。

---

## 实施计划

### Phase 1: 后端数据暴露（1-2小时）

**文件**: `/home/aiscend/work/vibelife/apps/api/routes/dashboard.py`

修改 `get_dashboard()` 函数，将已有数据映射到 API 响应：

```python
# Line 203-233 修改 mySkills 构建逻辑
content: {
    "headline": daily_fortune.get("theme") or "查看今日运势",  # theme → headline
    "insights": daily_fortune.get("insights", [])[:3],
    "rating": {
        "overall": daily_fortune.get("score", 60),
        "label": "吉" if score >= 70 else ("中" if score >= 50 else "需留意"),
        "details": daily_fortune.get("area_scores", {})  # 新增
    },
    "suggestions": {  # 新增
        "do": daily_fortune.get("highlights", []),
        "avoid": daily_fortune.get("cautions", [])
    }
}
```

**文件**: `/home/aiscend/work/vibelife/apps/api/services/quote.py` (新建)

从前端 `apps/web/src/lib/dashboard/quotes.ts` 移植名言逻辑到后端：
- 100+ 条名言库
- 基于日期的稳定选择（同一天同一用户看到相同名言）

### Phase 2: 前端数据转换（30分钟）

**文件**: `/home/aiscend/work/vibelife/apps/web/src/hooks/useBentoDashboardData.ts`

新增字段映射：
```typescript
return {
  // 现有字段...

  // 新增
  fortuneData: baziCard ? {
    score: baziCard.content.rating?.overall ?? 60,
    areaScores: baziCard.content.rating?.details ?? {},
    suggestions: baziCard.content.suggestions ?? { do: [], avoid: [] },
    theme: baziCard.content.headline,
  } : undefined,

  quote: dashboard.ambient.quote,
  streak: dashboard.status.streak,
  checkedIn: dashboard.status.checkedIn,
}
```

### Phase 3: 前端组件升级（2-3小时）

**文件**: `/home/aiscend/work/vibelife/apps/web/src/components/chat/BentoDashboard.tsx`

重构为新布局：

```
┌─────────────────────────────────────┐
│ GreetingCard                        │
│ ☀️ 早安，小薇                        │
│ 大寒 · 阳气回升                     │
│ "向内求，是所有成就的起点。"—荣格    │
├─────────────────────────────────────┤
│ FortuneCard (新组件)                │
│ 🌟 今日运势                          │
│ 整体 ████████████░░ 78              │
│ ☀️ 宜：创意工作、表达                │
│ ⚠️ 慎：重大财务决定                  │
│ 💡 木火相生，想法易落地              │
├─────────────────────────────────────┤
│ TodayPriorityCard (新组件)          │
│ 🎯 今天最重要                        │
│ ⭐ 完成 3.2 节初稿                   │
│    💡 创意能量旺，正是时候           │
│    [ 🚀 开始专注 ]                  │
├─────────────────────────────────────┤
│ ┌─────────────┬──────────────┐      │
│ │NorthStarCard│WeekProgress  │      │
│ │⭐ 北极星    │📊 本周 2/4   │      │
│ └─────────────┴──────────────┘      │
├─────────────────────────────────────┤
│ StreakBar (新组件)                  │
│ 🔥 连续 7 天         [ ✓ 签到 ]    │
└─────────────────────────────────────┘
```

**新建组件**:
1. `FortuneCard.tsx` - 运势卡片（分数条 + 宜忌 + 洞察）
2. `TodayPriorityCard.tsx` - 今日重点（杠杆 + 运势融合提示）
3. `StreakBar.tsx` - 底部签到条

### Phase 4: 文档更新

**文件**: `/home/aiscend/work/vibelife/docs/components/chat/BENTO_DASHBOARD_V2.md` (新建)

记录新设计规范、组件 API、数据流。

---

## 关键文件清单

### 后端修改
| 文件 | 操作 | 说明 |
|------|------|------|
| `apps/api/routes/dashboard.py` | 修改 | 暴露 area_scores, suggestions |
| `apps/api/services/quote.py` | 新建 | 名言选择服务 |

### 前端修改
| 文件 | 操作 | 说明 |
|------|------|------|
| `apps/web/src/hooks/useBentoDashboardData.ts` | 修改 | 新增字段映射 |
| `apps/web/src/components/chat/BentoDashboard.tsx` | 重构 | 新布局 |
| `apps/web/src/components/chat/dashboard/FortuneCard.tsx` | 新建 | 运势卡片 |
| `apps/web/src/components/chat/dashboard/TodayPriorityCard.tsx` | 新建 | 今日重点 |
| `apps/web/src/components/chat/dashboard/StreakBar.tsx` | 新建 | 签到条 |

### 文档
| 文件 | 操作 |
|------|------|
| `docs/components/chat/BENTO_DASHBOARD_V2.md` | 新建 |

---

## 验证方案

1. **API 测试**: `curl /api/dashboard` 验证返回 rating.details 和 suggestions
2. **Playwright 截图**: 对比目标设计
3. **签到功能**: 验证 streak 更新和 UI 反馈

---

## 预计时间

| Phase | 时间 |
|-------|------|
| Phase 1: 后端 | 1-2 小时 |
| Phase 2: 前端数据 | 30 分钟 |
| Phase 3: 前端组件 | 2-3 小时 |
| Phase 4: 文档 | 30 分钟 |
| **总计** | **4-6 小时** |
