# VibeInsight (Me页/VibeProfile) 体验优化计划

## 产品目标
**北极星**: "让每一个人，都拥有一个真正懂自己的存在"
**核心体验**: 用户打开 Me 页，立刻感受到"这个 AI 真的懂我"

---

## 现状诊断

### 已实现 ✅
- **后端架构成熟**: VibeProfile v9.0 三层架构 (Identity + Skills + Vibe)
- **数据提取能力**: ProfileExtractor 从对话中抽取 vibe.insight + vibe.target
- **前端组件就绪**: MePanel, VibeIDCard, BaziSummaryCard, ZodiacSummaryCard
- **Skill 数据同步**: Bazi/Zodiac/Lifecoach 自动同步到 vibe.insight

### 核心断点 ❌
1. **数据断层**: 前端调用的 API 端点不存在 (`/skills/bazi/profile/{userId}/summary`)
2. **静态展示**: Me 页只是数据展示，没有"懂你"的动态体验
3. **无即时反馈**: Profile 仅每日批量更新，用户无法感知 AI 在"学习自己"

---

## 最优先改进的三件事

### 🥇 P0: 打通数据流 - 让 Me 页有数据可看
**问题**: 前端 `useProfileData.ts` 调用的 API 不存在，Me 页永远是空白
**目标**: 用户打开 Me 页，能看到自己的 VibeID + 八字 + 星座摘要

**实现方案**:
```
新增 API 端点 (routes/account.py 或 routes/skills.py):
GET /account/me/dashboard
返回: {
  vibeId: vibe.insight.essence.archetype → 转换为 VibeIDDisplay 格式,
  bazi: { dayMaster, pattern, todayFortune, fortuneLevel },
  zodiac: { sunSign, ascendant, todayEnergy, energyLevel }
}
```

**关键改动**:
- `apps/api/routes/account.py`: 新增 `/me/dashboard` 端点
- `apps/api/services/`: 新增 dashboard_service.py 聚合 vibe.insight + skills 数据
- `apps/web/src/hooks/useProfileData.ts`: 修改为调用新端点

**工作量**: 1-2 天

---

### 🥈 P1: 每日一语 - 让用户感受"被懂"
**问题**: Me 页是静态的，没有"这是专门为你说的"的感觉
**目标**: 用户每天打开 Me 页，看到一句基于自己 Profile 生成的专属 insight

**实现方案**:
```
1. 新增 daily_insight 字段到 vibe.insight.dynamic
2. ProactiveEngine 每日凌晨生成，基于:
   - vibe.insight (用户是谁)
   - vibe.target (用户想成为谁)
   - 当日天干地支 / 行星相位
3. 前端 Me 页顶部显示"今日给你的话"卡片
```

**关键改动**:
- `apps/api/services/proactive/content_generator.py`: 新增 daily_insight 生成
- `apps/api/skills/lifecoach/reminders.yaml`: 配置每日 insight 触发
- `apps/web/src/components/me/DailyInsightCard.tsx`: 新组件
- `MePanel.tsx`: 集成 DailyInsightCard

**工作量**: 2-3 天

---

### 🥉 P2: 实时学习反馈 - 让用户知道 AI 在"懂自己"
**问题**: 用户聊完天后，不知道 AI 有没有记住/理解自己
**目标**: 聊天后，Profile 有即时更新，用户能看到"我又了解你一点了"

**实现方案**:
```
1. 轻量级实时抽取:
   - 聊天结束后 (Stop hook)，快速检测是否有新 insight
   - 仅抽取关键字段: emotion, energy, challenges, goals

2. 前端反馈:
   - 聊天结束时，如果 Profile 有更新，显示微妙动画
   - Me 页显示"最近更新"标记

3. 增量而非全量:
   - 使用 ProfileExtractor 的 merge 逻辑
   - 只更新 dynamic 层，不动 essence 层
```

**关键改动**:
- `apps/api/services/agent/core.py`: AgentEvent 新增 `profile_updated` 类型
- `apps/api/services/agent/stream_adapter.py`: 聊天结束时触发轻量抽取
- `apps/web/src/components/chat/`: 添加 Profile 更新动画
- `apps/web/src/components/me/`: 添加"刚刚更新"标记

**工作量**: 3-4 天

---

## 实现优先级

| 优先级 | 任务 | 用户价值 | 工作量 | ROI |
|--------|------|----------|--------|-----|
| P0 | 打通数据流 | 从0到1，Me页可用 | 1-2天 | ⭐⭐⭐⭐⭐ |
| P1 | 每日一语 | "懂你"的直观感受 | 2-3天 | ⭐⭐⭐⭐ |
| P2 | 实时学习反馈 | 建立信任感 | 3-4天 | ⭐⭐⭐ |

---

## 关键文件

### 后端
- `apps/api/routes/account.py` - 新增 Me Dashboard 端点
- `apps/api/stores/unified_profile_repo.py` - Profile 数据访问
- `apps/api/services/proactive/content_generator.py` - 每日 Insight 生成
- `apps/api/workers/profile_extractor.py` - Profile 抽取逻辑

### 前端
- `apps/web/src/components/layout/panels/MePanel.tsx` - Me 页主组件
- `apps/web/src/hooks/useProfileData.ts` - 数据获取 Hook
- `apps/web/src/skills/vibe-id/components/VibeIDCard.tsx` - VibeID 展示

---

## 验证方式

### P0 验证
```bash
# 1. 启动测试环境
./scripts/start-test.sh

# 2. 调用新 API
curl http://localhost:8100/api/v1/account/me/dashboard \
  -H "Authorization: Bearer <test_token>"

# 3. 前端验证
# 打开 http://localhost:8232/chat，切换到 Me tab
# 应该看到 VibeID + 八字 + 星座卡片有数据
```

### P1 验证
```bash
# 1. 手动触发 daily insight 生成
python -c "from services.proactive.engine import get_proactive_engine; ..."

# 2. 前端验证
# Me 页顶部应显示"今日给你的话"卡片
```

### P2 验证
```bash
# 1. 发送聊天消息，提及新目标或情绪
# 2. 聊天结束后，检查 vibe.insight.dynamic 是否更新
# 3. 前端应显示更新动画
```

---

## 未解决问题

1. **今日运势数据来源**: 八字/星座的"今日运势"从哪里获取？需要每日计算还是预生成？
2. **VibeID 完整数据**: VibeIDCard 需要很多字段 (四维原型等)，当前 vibe.insight.essence 结构是否足够？
3. **性能考虑**: Me 页聚合多个数据源，是否需要缓存层？
