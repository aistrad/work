# VibeLife v9 - Me/Journey 页面活化设计

> Version: 9.0 | 2026-01-21
> 核心理念：从静态展示到动态学习

---

## 一、设计哲学

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   v8: 页面是「镜子」—— 静态反映你的数据                                      │
│   v9: 页面是「生命体」—— 从每次对话中学习、进化、主动关心你                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.1 活化三要素

| 要素 | 说明 | 实现方式 |
|------|------|----------|
| **学习** | 从用户对话中提取信息 | Extractor 多维度抽取 |
| **进化** | 动态更新展示内容 | 融合洞察 + 原型演化 |
| **主动** | 基于学习触发关怀 | Proactive 智能推送 |

---

## 二、Me 页活化设计

### 2.1 核心变化

```
v8 Me 页                          v9 Me 页
┌─────────────────┐              ┌─────────────────┐
│ VibeID 静态展示  │              │ 融合洞察卡片     │ ← 八字+行为+话题融合
├─────────────────┤              ├─────────────────┤
│ 八字分析结果    │    ──────▶   │ 原型演化卡片     │ ← 动态变化，有证据
├─────────────────┤              ├─────────────────┤
│ 星座分析结果    │              │ 情绪轨迹卡片     │ ← 7天曲线+洞察
├─────────────────┤              ├─────────────────┤
│ 人格测试结果    │              │ 关系图谱卡片     │ ← 从对话中学习
└─────────────────┘              └─────────────────┘
```

### 2.2 融合洞察卡片

#### 设计理念
不再分开展示八字、星座、行为数据，而是**融合生成一句话洞察**。

#### 数据融合逻辑

```python
def generate_fusion_insight(user_id: str) -> str:
    """
    融合三源数据生成洞察
    """
    # 1. 获取八字特质
    bazi_traits = get_bazi_traits(user_id)
    # 例：["食神旺，表达力强", "木火相生，创造力旺"]

    # 2. 获取行为模式
    behavior = get_dominant_behavior(user_id)
    # 例："problem_solving"

    # 3. 获取话题热度
    hot_topic = get_hottest_topic(user_id)
    # 例："career" (80%)

    # 4. LLM 融合生成
    prompt = f"""
    用户八字特质：{bazi_traits}
    用户近期行为模式：{behavior}
    用户近期关注话题：{hot_topic}

    请用一段话（50字以内）融合这三个维度，
    生成一个关于「用户当前状态」的洞察。
    不要分开说三个维度，要自然融合。
    """

    return llm.generate(prompt)
```

#### 示例输出

```
"你的命盘显示表达创作是天赋，而你最近频繁探讨写作话题，
正是天赋与行动的合一。继续这个方向。"
```

#### 前端设计

```tsx
// components/me/FusionInsightCard.tsx

interface FusionInsightCardProps {
  insight: {
    content: string;
    sources: ('bazi' | 'behavior' | 'topic')[];
    generatedAt: string;
  };
}

export function FusionInsightCard({ insight }: FusionInsightCardProps) {
  return (
    <Card className="bg-gradient-to-br from-indigo-50 to-purple-50">
      <CardHeader>
        <div className="flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-indigo-500" />
          <span className="text-sm font-medium">今日洞察</span>
        </div>
      </CardHeader>
      <CardContent>
        <p className="text-lg leading-relaxed">{insight.content}</p>
        <div className="mt-4 flex gap-2">
          {insight.sources.map(source => (
            <Badge key={source} variant="secondary">
              {sourceLabels[source]}
            </Badge>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
```

### 2.3 原型演化卡片

#### 设计理念
展示 VibeID 原型的**动态变化**，而非静态标签。

#### 数据结构

```typescript
interface ArchetypeEvolution {
  current: {
    primary: { name: string; weight: number };
    secondary: { name: string; weight: number }[];
  };
  trend: {
    rising: { name: string; delta: number }[];
    falling: { name: string; delta: number }[];
  };
  evidence: string[];  // 来自对话的证据
}
```

#### 前端设计

```tsx
// components/me/ArchetypeEvolutionCard.tsx

export function ArchetypeEvolutionCard({ evolution }: Props) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <span className="font-medium">原型演化</span>
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger>
                <Info className="h-4 w-4 text-muted-foreground" />
              </TooltipTrigger>
              <TooltipContent>
                基于你的对话行为动态计算
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        </div>
      </CardHeader>
      <CardContent>
        {/* 主原型 */}
        <div className="mb-4">
          <div className="flex items-center gap-2">
            <span className="text-2xl">{archetypeEmoji[evolution.current.primary.name]}</span>
            <span className="text-xl font-bold">{evolution.current.primary.name}</span>
            <span className="text-muted-foreground">
              {Math.round(evolution.current.primary.weight * 100)}%
            </span>
          </div>
        </div>

        {/* 权重条 */}
        <div className="space-y-2">
          {Object.entries(evolution.current).map(([name, weight]) => (
            <div key={name} className="flex items-center gap-2">
              <span className="w-20 text-sm">{name}</span>
              <Progress value={weight * 100} className="flex-1" />
              <span className="w-12 text-sm text-right">{Math.round(weight * 100)}%</span>
            </div>
          ))}
        </div>

        {/* 变化趋势 */}
        {evolution.trend.rising.length > 0 && (
          <div className="mt-4 p-3 bg-green-50 rounded-lg">
            <div className="flex items-center gap-1 text-green-600">
              <TrendingUp className="h-4 w-4" />
              <span className="text-sm">
                {evolution.trend.rising[0].name} +{evolution.trend.rising[0].delta}%
              </span>
            </div>
            <p className="text-xs text-green-700 mt-1">
              {evolution.evidence[0]}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

### 2.4 情绪轨迹卡片

#### 设计理念
可视化用户情绪变化，并提供**模式洞察**。

#### 数据结构

```typescript
interface EmotionTrajectory {
  dataPoints: {
    date: string;
    avgIntensity: number;  // 0-1, 越高越正向
    dominantEmotion: string;
  }[];
  insights: string[];  // 例：["周三情绪最低，通常与工作压力相关"]
}
```

#### 前端设计

```tsx
// components/me/EmotionTrajectoryCard.tsx

export function EmotionTrajectoryCard({ trajectory }: Props) {
  return (
    <Card>
      <CardHeader>
        <span className="font-medium">情绪轨迹</span>
      </CardHeader>
      <CardContent>
        {/* 折线图 */}
        <ResponsiveContainer width="100%" height={120}>
          <LineChart data={trajectory.dataPoints}>
            <XAxis dataKey="date" tickFormatter={formatDate} />
            <YAxis domain={[0, 1]} hide />
            <Line
              type="monotone"
              dataKey="avgIntensity"
              stroke="#8b5cf6"
              strokeWidth={2}
              dot={{ fill: '#8b5cf6' }}
            />
          </LineChart>
        </ResponsiveContainer>

        {/* 洞察 */}
        {trajectory.insights.length > 0 && (
          <div className="mt-4 p-3 bg-amber-50 rounded-lg">
            <p className="text-sm text-amber-800">
              {trajectory.insights[0]}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

---

## 三、Journey 页活化设计

### 3.1 核心变化

```
v8 Journey 页                     v9 Journey 页
┌─────────────────┐              ┌─────────────────┐
│ 目标列表（手动）│              │ 智能排序目标     │ ← 基于对话热度
├─────────────────┤              ├─────────────────┤
│ 进度条（手动）  │    ──────▶   │ 自动进度识别     │ ← 从对话中学习
├─────────────────┤              ├─────────────────┤
│ 静态提醒       │              │ 智能建议卡片     │ ← 个性化推荐
└─────────────────┘              └─────────────────┘
```

### 3.2 智能排序目标

#### 设计理念
目标列表不再按创建时间排序，而是按**用户当前关注度**排序。

#### 排序算法

```python
def calculate_goal_relevance(goal: Goal, topic_heat: dict) -> float:
    """
    计算目标与当前用户关注的相关性

    topic_heat: {"career": 0.8, "health": 0.1, "relationship": 0.1}
    """
    # 1. 目标关键词匹配话题
    goal_topics = extract_topics_from_goal(goal.title, goal.description)

    # 2. 计算加权相关性
    relevance = 0.0
    for topic in goal_topics:
        relevance += topic_heat.get(topic, 0.0)

    # 3. 考虑最近讨论次数
    recent_mentions = count_goal_mentions_in_conversations(goal.id, days=7)
    mention_bonus = min(recent_mentions * 0.1, 0.3)

    return min(relevance + mention_bonus, 1.0)
```

#### 前端设计

```tsx
// components/journey/SmartGoalList.tsx

interface GoalWithRelevance {
  id: string;
  title: string;
  relevanceScore: number;
  heatIndicator: 'hot' | 'warm' | 'cold';
  suggestion: string;
}

export function SmartGoalList({ goals }: { goals: GoalWithRelevance[] }) {
  return (
    <div className="space-y-3">
      {goals.map(goal => (
        <Card key={goal.id} className="p-4">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2">
                <HeatIndicator level={goal.heatIndicator} />
                <span className="font-medium">{goal.title}</span>
              </div>
              {goal.suggestion && (
                <p className="mt-2 text-sm text-muted-foreground">
                  💡 {goal.suggestion}
                </p>
              )}
            </div>
            <ChevronRight className="h-5 w-5 text-muted-foreground" />
          </div>
        </Card>
      ))}
    </div>
  );
}

function HeatIndicator({ level }: { level: 'hot' | 'warm' | 'cold' }) {
  const config = {
    hot: { icon: '🔥', color: 'text-orange-500', label: '最近频繁讨论' },
    warm: { icon: '☀️', color: 'text-yellow-500', label: '近期有提及' },
    cold: { icon: '❄️', color: 'text-blue-400', label: '已有一段时间未讨论' },
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger>
          <span className={config[level].color}>{config[level].icon}</span>
        </TooltipTrigger>
        <TooltipContent>{config[level].label}</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
```

### 3.3 自动进度识别

#### 设计理念
从用户对话中自动识别目标进度，减少手动更新负担。

#### 识别逻辑

```python
async def detect_rock_progress(
    rock: Rock,
    recent_conversations: List[Conversation]
) -> Optional[ProgressDetection]:
    """
    从对话中识别大石头进度
    """
    prompt = f"""
    用户的目标：{rock.title}
    目标描述：{rock.description}

    以下是用户最近7天的对话摘要：
    {summarize_conversations(recent_conversations)}

    请判断：
    1. 用户是否提到完成了这个目标？(yes/no)
    2. 如果有进展但未完成，进展是什么？
    3. 置信度 (0-1)

    输出 JSON：
    {{"completed": bool, "progress_note": string, "confidence": float}}
    """

    result = await llm.generate_json(prompt)

    if result["confidence"] > 0.7:
        return ProgressDetection(
            rock_id=rock.id,
            completed=result["completed"],
            progress_note=result["progress_note"],
            confidence=result["confidence"]
        )
    return None
```

#### 前端设计

```tsx
// components/journey/AutoProgressBadge.tsx

interface AutoProgressBadgeProps {
  detection: {
    completed: boolean;
    progressNote: string;
    confidence: number;
  };
  onConfirm: () => void;
  onDismiss: () => void;
}

export function AutoProgressBadge({ detection, onConfirm, onDismiss }: AutoProgressBadgeProps) {
  if (detection.completed) {
    return (
      <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5 text-green-500" />
            <span className="text-sm text-green-700">
              检测到你可能已完成这个任务
            </span>
          </div>
          <div className="flex gap-2">
            <Button size="sm" variant="ghost" onClick={onDismiss}>
              忽略
            </Button>
            <Button size="sm" onClick={onConfirm}>
              确认完成
            </Button>
          </div>
        </div>
        <p className="mt-2 text-xs text-green-600">
          {detection.progressNote}
        </p>
      </div>
    );
  }

  return (
    <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
      <div className="flex items-center gap-2">
        <Lightbulb className="h-5 w-5 text-blue-500" />
        <span className="text-sm text-blue-700">
          检测到进展：{detection.progressNote}
        </span>
      </div>
    </div>
  );
}
```

---

## 四、API 设计

### 4.1 Me 页 API

```yaml
# GET /api/v1/me/dashboard
# 获取 Me 页完整数据

Response:
  fusion_insight:
    content: string
    sources: string[]
    generated_at: string

  archetype_evolution:
    current:
      primary: { name: string, weight: number }
      secondary: { name: string, weight: number }[]
    trend:
      rising: { name: string, delta: number }[]
      falling: { name: string, delta: number }[]
    evidence: string[]

  emotion_trajectory:
    data_points:
      - date: string
        avg_intensity: number
        dominant_emotion: string
    insights: string[]

  relationship_graph:
    nodes: { id: string, name: string, type: string }[]
    edges: { source: string, target: string, sentiment: number }[]

---

# POST /api/v1/me/refresh
# 强制刷新 Me 页数据

Response:
  success: boolean
  refreshed_at: string
```

### 4.2 Journey 页 API

```yaml
# GET /api/v1/journey/goals?sort=intelligent
# 获取智能排序的目标列表

Response:
  goals:
    - id: string
      title: string
      description: string
      relevance_score: number
      heat_indicator: "hot" | "warm" | "cold"
      suggestion: string
      auto_progress:
        detected: boolean
        progress_note: string
        confidence: number

---

# GET /api/v1/journey/rocks/current-week
# 获取本周大石头（含自动进度）

Response:
  rocks:
    - id: string
      title: string
      manual_status: "pending" | "completed"
      auto_detection:
        completed: boolean
        progress_note: string
        confidence: number

---

# POST /api/v1/journey/rocks/{rock_id}/confirm-completion
# 确认自动检测的完成状态

Request:
  source: "auto_detection" | "manual"

Response:
  success: boolean
```

---

## 五、数据刷新策略

| 数据类型 | 刷新时机 | 缓存策略 |
|----------|----------|----------|
| 融合洞察 | 每日凌晨 + 手动刷新 | 24小时缓存 |
| 原型演化 | 每日凌晨 | 24小时缓存 |
| 情绪轨迹 | 每轮对话后 | 1小时缓存 |
| 目标排序 | 对话结束时 | 15分钟缓存 |
| 自动进度 | 对话结束时 | 不缓存 |

---

## 六、与 Proactive 联动

### 6.1 Me 页触发 Proactive

```python
# 情绪低落时触发
if emotion_trajectory.recent_avg < 0.3:
    trigger_proactive("emotion_care", user_id)

# 原型剧变时触发
if archetype_evolution.trend.rising[0].delta > 0.15:
    trigger_proactive("archetype_shift_notice", user_id)
```

### 6.2 Journey 页触发 Proactive

```python
# 目标停滞时触发
if goal.days_since_last_mention > 7:
    trigger_proactive("goal_reminder", user_id, goal_id)

# 大石头即将到期时触发
if rock.due_date - today <= 2 and rock.status == "pending":
    trigger_proactive("rock_deadline", user_id, rock_id)
```

---

## 附录：设计验收清单

### Me 页
- [ ] 融合洞察卡片每日更新
- [ ] 原型权重变化有证据支撑
- [ ] 情绪曲线正确渲染
- [ ] 数据来源标签清晰

### Journey 页
- [ ] 目标按热度正确排序
- [ ] 热度指示器显示正确
- [ ] 自动进度检测准确率 > 70%
- [ ] 确认/忽略按钮功能正常
