# VibeLife v9 - 数据流设计文档

> Version: 9.0 | 2026-01-21
> 核心：Extracted → Me / Journey / Proactive

---

## 一、数据流全景

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 VibeLife v9 数据流全景                                   │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   ┌─────────────┐                                                                       │
│   │  用户对话   │                                                                       │
│   │  (Chat)     │                                                                       │
│   └──────┬──────┘                                                                       │
│          │                                                                              │
│          ▼                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                           EXTRACTION LAYER                                       │   │
│   ├─────────────────────────────────────────────────────────────────────────────────┤   │
│   │                                                                                 │   │
│   │   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐   ┌─────────────┐   │   │
│   │   │  情绪抽取     │   │  话题抽取     │   │  行为抽取     │   │  实体抽取   │   │   │
│   │   │  Emotion      │   │  Topic        │   │  Behavior     │   │  Entity     │   │   │
│   │   └───────┬───────┘   └───────┬───────┘   └───────┬───────┘   └──────┬──────┘   │   │
│   │           │                   │                   │                  │          │   │
│   └───────────┼───────────────────┼───────────────────┼──────────────────┼──────────┘   │
│               │                   │                   │                  │              │
│               ▼                   ▼                   ▼                  ▼              │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                           STORAGE LAYER                                          │   │
│   ├─────────────────────────────────────────────────────────────────────────────────┤   │
│   │                                                                                 │   │
│   │   ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│   │   │                        VibeProfile (Unified)                            │   │   │
│   │   ├─────────────────────────────────────────────────────────────────────────┤   │   │
│   │   │  • emotion_history: 情绪历史                                            │   │   │
│   │   │  • topic_weights: 话题权重                                              │   │   │
│   │   │  • behavior_patterns: 行为模式                                          │   │   │
│   │   │  • archetype_weights: 原型权重                                          │   │   │
│   │   │  • entity_graph: 实体关系图                                             │   │   │
│   │   └─────────────────────────────────────────────────────────────────────────┘   │   │
│   │                                                                                 │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│               │                   │                   │                                 │
│               │                   │                   │                                 │
│       ┌───────┴───────┐   ┌───────┴───────┐   ┌───────┴───────┐                        │
│       ▼               ▼   ▼               ▼   ▼               ▼                        │
│   ┌─────────┐     ┌─────────┐     ┌─────────────────┐                                   │
│   │ ME 页   │     │JOURNEY页│     │  PROACTIVE 推送 │                                   │
│   │         │     │         │     │                 │                                   │
│   │• 融合洞察│     │• 目标排序│     │• 情绪关怀       │                                   │
│   │• 原型演化│     │• 进度追踪│     │• 进度提醒       │                                   │
│   │• 情绪轨迹│     │• 热度展示│     │• 运势提示       │                                   │
│   └─────────┘     └─────────┘     └─────────────────┘                                   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## ��、抽取层详解

### 2.1 情绪抽取 (Emotion Extractor)

```yaml
输入: 单轮对话消息
输出:
  emotion_state:
    primary: "anxious" | "calm" | "excited" | "sad" | "angry" | "neutral"
    intensity: 0-1
    confidence: 0-1

处理流程:
  1. LLM 分析用户消息情绪
  2. 结合上下文判断情绪连续性
  3. 更新 emotion_history

触发条件:
  - 每轮对话实时执行

下游影响:
  - Me 页: 情绪轨迹卡片
  - Proactive: 情绪关怀推送触发
```

### 2.2 话题抽取 (Topic Extractor)

```yaml
输入: 完整对话会话
输出:
  topics:
    - name: string
      category: "career" | "relationship" | "health" | "growth" | "finance" | "spiritual"
      weight: 0-1
      keywords: string[]

处理流程:
  1. LLM 分析会话主题
  2. 分类到预定义类别
  3. 计算话题权重
  4. 更新 topic_weights

触发条件:
  - 对话结束时执行

下游影响:
  - Journey 页: 目标优先级排序
  - Proactive: 话题相关推送
```

### 2.3 行为抽取 (Behavior Extractor)

```yaml
输入: 对话历史 + 当前会话
输出:
  behavior_signals:
    - pattern: "seeking_validation" | "problem_solving" | "venting" | "exploring" | "planning"
      confidence: 0-1
      evidence: string[]

处理流程:
  1. LLM 分析用户对话模式
  2. 匹配预定义行为模式
  3. 计算置信度
  4. 更新 behavior_patterns

触发条件:
  - 对话结束时执行

下游影响:
  - Me 页: 原型演化（行为 → 原型映射）
  - Proactive: 个性化推送风格
```

### 2.4 实体抽取 (Entity Extractor)

```yaml
输入: 对话消息
输出:
  entities:
    - type: "person" | "goal" | "event" | "place" | "time"
      name: string
      attributes: object
      sentiment: -1 to 1

处理流程:
  1. NER 识别实体
  2. 情感分析关联
  3. 更新 entity_graph

触发条件:
  - 每轮对话实时执行

下游影响:
  - Me 页: 关系图谱
  - Journey 页: 目标关联人物
```

## 三、存储层设计

### 3.1 VibeProfile 扩展字段

```sql
-- unified_profiles 表扩展
ALTER TABLE unified_profiles ADD COLUMN IF NOT EXISTS
  extracted_data JSONB DEFAULT '{}';

-- extracted_data 结构
{
  "emotion_history": [
    {
      "timestamp": "2026-01-21T10:30:00Z",
      "state": "anxious",
      "intensity": 0.7,
      "conversation_id": "uuid"
    }
  ],
  "topic_weights": {
    "career": 0.4,
    "relationship": 0.3,
    "health": 0.1,
    "growth": 0.15,
    "finance": 0.05
  },
  "behavior_patterns": {
    "dominant": "problem_solving",
    "secondary": ["exploring", "planning"],
    "history": [...]
  },
  "archetype_weights": {
    "creator": 0.3,
    "healer": 0.25,
    "pioneer": 0.2,
    "sage": 0.15,
    "guardian": 0.1
  },
  "entity_graph": {
    "nodes": [...],
    "edges": [...]
  }
}
```

### 3.2 新增索引表

```sql
-- 情绪历史索引（便于查询趋势）
CREATE TABLE emotion_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    snapshot_date DATE,
    avg_intensity DECIMAL(3,2),
    dominant_emotion VARCHAR(20),
    emotion_counts JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emotion_snapshots_user_date
ON emotion_snapshots(user_id, snapshot_date DESC);

-- 话题热度索引（便于排序）
CREATE TABLE topic_heat_index (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    week_start DATE,
    topic_scores JSONB,  -- {"career": 0.8, "health": 0.2, ...}
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_topic_heat_user_week
ON topic_heat_index(user_id, week_start DESC);
```

## 四、消费层详解

### 4.1 Me 页数据消费

```python
class MePageDataService:
    """Me 页数据服务"""

    async def get_fusion_insight(self, user_id: str) -> FusionInsight:
        """
        融合洞察：八字 + 行为 + 话题
        """
        profile = await self.get_profile(user_id)
        bazi_traits = profile.bazi_analysis.key_traits
        behavior_pattern = profile.extracted_data.behavior_patterns.dominant
        hot_topic = self._get_hottest_topic(profile.extracted_data.topic_weights)

        # LLM 生成融合洞察
        insight = await self.llm.generate_fusion_insight(
            bazi_traits=bazi_traits,
            behavior=behavior_pattern,
            topic=hot_topic
        )
        return insight

    async def get_archetype_evolution(self, user_id: str) -> ArchetypeEvolution:
        """
        原型演化：展示权重变化
        """
        profile = await self.get_profile(user_id)
        current_weights = profile.extracted_data.archetype_weights
        history = await self.get_archetype_history(user_id, days=30)

        return ArchetypeEvolution(
            current=current_weights,
            trend=self._calculate_trend(history),
            evidence=self._get_evolution_evidence(history)
        )

    async def get_emotion_trajectory(self, user_id: str) -> EmotionTrajectory:
        """
        情绪轨迹：7天曲线
        """
        snapshots = await self.emotion_repo.get_recent(user_id, days=7)
        insights = self._analyze_emotion_pattern(snapshots)

        return EmotionTrajectory(
            data_points=snapshots,
            insights=insights
        )
```

### 4.2 Journey 页数据消费

```python
class JourneyPageDataService:
    """Journey 页数据服务"""

    async def get_sorted_goals(self, user_id: str) -> List[GoalWithHeat]:
        """
        智能排序目标：基于话题热度
        """
        goals = await self.goal_repo.get_user_goals(user_id)
        topic_heat = await self.topic_heat_repo.get_current_week(user_id)

        # 计算每个目标的相关性分数
        for goal in goals:
            goal.relevance_score = self._calculate_goal_relevance(
                goal=goal,
                topic_heat=topic_heat
            )
            goal.suggestion = await self._generate_suggestion(goal, topic_heat)

        # 按相关性排序
        return sorted(goals, key=lambda g: g.relevance_score, reverse=True)

    async def get_weekly_rocks_with_auto_progress(
        self,
        user_id: str
    ) -> List[RockWithProgress]:
        """
        本周大石头：基于对话自动识别进度
        """
        rocks = await self.rock_repo.get_current_week(user_id)
        recent_conversations = await self.conv_repo.get_recent(user_id, days=7)

        for rock in rocks:
            # 分析对话中是否提到完成相关事项
            progress = await self.llm.analyze_rock_progress(
                rock=rock,
                conversations=recent_conversations
            )
            rock.auto_progress = progress

        return rocks
```

### 4.3 Proactive 数据消费

```python
class ProactiveIntelligentEngine:
    """Proactive 智能引擎"""

    async def evaluate_all_triggers(self, user_id: str) -> List[TriggerCandidate]:
        """
        评估所有触发条件
        """
        profile = await self.get_profile(user_id)
        candidates = []

        # 1. 情绪触发
        emotion_trigger = await self._evaluate_emotion_trigger(profile)
        if emotion_trigger:
            candidates.append(emotion_trigger)

        # 2. 进度触发
        journey_trigger = await self._evaluate_journey_trigger(profile)
        if journey_trigger:
            candidates.append(journey_trigger)

        # 3. 运势触发
        fortune_trigger = await self._evaluate_fortune_trigger(profile)
        if fortune_trigger:
            candidates.append(fortune_trigger)

        # 4. 习惯触发
        habit_trigger = await self._evaluate_habit_trigger(profile)
        if habit_trigger:
            candidates.append(habit_trigger)

        return candidates

    async def _evaluate_emotion_trigger(self, profile) -> Optional[TriggerCandidate]:
        """
        情绪触发：连续N天低落
        """
        emotion_history = profile.extracted_data.emotion_history[-7:]
        low_count = sum(1 for e in emotion_history if e.intensity < 0.3)

        if low_count >= 3:
            return TriggerCandidate(
                type="emotion_care",
                priority=0,  # 最高优先级
                content=await self._generate_care_message(profile),
                personalization_score=0.9
            )
        return None

    async def _evaluate_journey_trigger(self, profile) -> Optional[TriggerCandidate]:
        """
        进度触发：目标停滞
        """
        goals = await self.goal_repo.get_stale_goals(profile.user_id, days=7)

        if goals:
            return TriggerCandidate(
                type="journey_reminder",
                priority=1,
                content=await self._generate_journey_reminder(goals[0]),
                personalization_score=0.8
            )
        return None
```

## 五、API 接口设计

### 5.1 Me 页 API

```yaml
GET /api/v1/me/insights
Response:
  fusion_insight:
    content: string
    sources: ["bazi", "behavior", "topic"]
    generated_at: timestamp
  archetype_evolution:
    current_weights: object
    trend: object
    evidence: string[]
  emotion_trajectory:
    data_points: array
    insights: string[]

GET /api/v1/me/insights/refresh
Description: 强制刷新洞察
Response:
  success: boolean
  new_insight: object
```

### 5.2 Journey 页 API

```yaml
GET /api/v1/journey/goals?sort=intelligent
Response:
  goals:
    - id: string
      title: string
      relevance_score: number
      heat_indicator: "hot" | "warm" | "cold"
      suggestion: string

GET /api/v1/journey/rocks/auto-progress
Response:
  rocks:
    - id: string
      title: string
      manual_status: "pending" | "completed"
      auto_detected_progress: string
      confidence: number
```

### 5.3 Proactive API

```yaml
POST /api/v1/proactive/evaluate
Description: 手动触发推送评估（用于测试）
Response:
  candidates:
    - type: string
      priority: number
      content: string
      will_send: boolean
      reason: string

GET /api/v1/proactive/history
Response:
  pushes:
    - id: string
      type: string
      content: string
      sent_at: timestamp
      opened: boolean
      converted: boolean
```

## 六、数据一致性保障

### 6.1 抽取失败处理

```python
class ExtractionFailureHandler:
    """抽取失败处理"""

    async def handle_failure(self, conversation_id: str, error: Exception):
        # 1. 记录失败
        await self.failure_log.record(conversation_id, error)

        # 2. 加入重试队列
        await self.retry_queue.enqueue(
            conversation_id=conversation_id,
            retry_count=0,
            max_retries=3
        )

        # 3. 不影响用户体验
        # 使用上次抽取结果 fallback
```

### 6.2 数据版本控制

```python
class ProfileVersionControl:
    """Profile 版本控制"""

    async def update_with_version(self, user_id: str, extracted_data: dict):
        # 乐观锁更新
        current_version = await self.get_version(user_id)

        success = await self.profile_repo.update(
            user_id=user_id,
            extracted_data=extracted_data,
            expected_version=current_version
        )

        if not success:
            # 版本冲突，重新读取后合并
            await self.merge_and_retry(user_id, extracted_data)
```

---

## 附录：数据量估算

| 数据类型 | 单用户每日 | 存储周期 | 预估存储 |
|----------|------------|----------|----------|
| emotion_history | ~10条 | 90天 | ~900条/用户 |
| topic_weights | 1次更新 | 永久 | 1条/用户 |
| behavior_patterns | ~3条 | 90天 | ~270条/用户 |
| entity_graph | ~20节点 | 永久 | ~500节点/用户 |
