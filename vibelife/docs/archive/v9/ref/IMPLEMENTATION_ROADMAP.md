# VibeLife v9 - 实施路线图

> Version: 9.0 | 2026-01-21
> 优先级：Proactive 智能推送 → Me 活化 → Journey 活化

---

## 一、总体规划

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        V9 实施路线图 (8周)                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Week 1-2          Week 3-4          Week 5-6          Week 7-8            │
│   ┌─────────┐       ┌─────────┐       ┌─────────┐       ┌─────────┐         │
│   │ 数据抽取 │──────▶│ Proactive│──────▶│ Me 活化  │──────▶│Journey活化│       │
│   │  基础   │       │ 智能化  │       │         │       │          │         │
│   └─────────┘       └─────────┘       └─────────┘       └─────────┘         │
│                                                                             │
│   关键交付:          关键交付:          关键交付:          关键交付:          │
│   • Extractor       • 多源触发         • 融合洞察         • 智能排序         │
│   • 数据表          • 优先级排序       • 原型演化         • 自动进度         │
│   • 基础API         • 推送决策         • 情绪轨迹         • 热度展示         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 二、Phase 1: 数据抽取基础 (Week 1-2)

### 2.1 目标
建立从对话中抽取多维数据的能力

### 2.2 任务分解

| 任务 | 负责 | 预估 | 依赖 |
|------|------|------|------|
| 设计抽取数据结构 | Design | 0.5d | - |
| 创建 extracted_signals 表 | BE | 0.5d | 结构设计 |
| 创建 emotion_snapshots 表 | BE | 0.5d | 结构设计 |
| 创建 topic_heat_index 表 | BE | 0.5d | 结构设计 |
| 实现 EmotionExtractor | BE | 1d | 表创建 |
| 实现 TopicExtractor | BE | 1d | 表创建 |
| 实现 BehaviorExtractor | BE | 1d | 表创建 |
| 实现 EntityExtractor | BE | 1d | 表创建 |
| 集成到 CoreAgent 对话流程 | BE | 1d | Extractors |
| 编写单元测试 | BE | 1d | 全部 |

### 2.3 关键代码位置

```
apps/api/
├── services/
│   └── extraction/              # 新增
│       ├── __init__.py
│       ├── emotion_extractor.py
│       ├── topic_extractor.py
│       ├── behavior_extractor.py
│       └── entity_extractor.py
├── stores/
│   └── extracted_data_repo.py   # 新增
└── workers/
    └── profile_extractor.py     # 扩展
```

### 2.4 验收标准

- [ ] 每轮对话后自动抽取情绪
- [ ] 对话结束后抽取话题和行为
- [ ] 抽取数据正确存储到 DB
- [ ] 单元测试覆盖率 > 80%

---

## 三、Phase 2: Proactive 智能化 (Week 3-4)

### 3.1 目标
基于抽取数据实现智能推送决策

### 3.2 任务分解

| 任务 | 负责 | 预估 | 依赖 |
|------|------|------|------|
| 设计触发器接口 | Design | 0.5d | Phase 1 |
| 实现 EmotionTrigger | BE | 1d | 接口设计 |
| 实现 JourneyTrigger | BE | 1d | 接口设计 |
| 实现 FortuneTrigger | BE | 0.5d | 接口设计 |
| 实现 HabitTrigger | BE | 0.5d | 接口设计 |
| 实现优先级排序算法 | BE | 1d | 触发器 |
| 实现频率控制逻辑 | BE | 0.5d | 排序 |
| 扩展 Proactive Engine | BE | 1d | 全部 |
| 推送内容生成优化 | BE | 1d | Engine |
| 集成测试 | BE | 1d | 全部 |

### 3.3 关键代码位置

```
apps/api/services/proactive/
├── engine.py                    # 扩展
├── intelligent_trigger.py       # 新增
├── triggers/                    # 新增
│   ├── __init__.py
│   ├── emotion_trigger.py
│   ├── journey_trigger.py
│   ├── fortune_trigger.py
│   └── habit_trigger.py
├── priority_sorter.py           # 新增
└── frequency_controller.py      # 新增
```

### 3.4 验收标准

- [ ] 情绪低落时触发关怀推送
- [ ] Journey 目标停滞时触发提醒
- [ ] 推送优先级正确排序
- [ ] 每日推送不超过3条
- [ ] 推送内容个性化

---

## 四、Phase 3: Me 页活化 (Week 5-6)

### 4.1 目标
Me 页展示动态生成的洞察内容

### 4.2 任务分解

| 任务 | 负责 | 预估 | 依赖 |
|------|------|------|------|
| 设计 Me 页 API | Design | 0.5d | Phase 1 |
| 实现融合洞察生成 | BE | 1.5d | API 设计 |
| 实现原型演化追踪 | BE | 1d | API 设计 |
| 实现情绪轨迹计算 | BE | 1d | API 设计 |
| Me 页 API 开发 | BE | 1d | 后端逻辑 |
| 融合洞察卡片 UI | FE | 1d | API |
| 原型演化卡片 UI | FE | 1d | API |
| 情绪轨迹卡片 UI | FE | 1d | API |
| 前后端联调 | Full | 1d | 全部 |

### 4.3 关键代码位置

```
apps/api/
├── routes/
│   └── me.py                    # 新增
└── services/
    └── me/                      # 新增
        ├── __init__.py
        ├── insight_generator.py
        ├── archetype_tracker.py
        └── emotion_analyzer.py

apps/web/src/
├── app/me/                      # 扩展
└── components/me/               # 扩展
    ├── FusionInsightCard.tsx
    ├── ArchetypeEvolutionCard.tsx
    └── EmotionTrajectoryCard.tsx
```

### 4.4 验收标准

- [ ] Me 页显示融合洞察卡片
- [ ] 原型权重变化可视化
- [ ] 7天情绪曲线正确渲染
- [ ] 洞察内容每日更新

---

## 五、Phase 4: Journey 页活化 (Week 7-8)

### 5.1 目标
Journey 页根据对话热度智能排序目标

### 5.2 任务分解

| 任务 | 负责 | 预估 | 依赖 |
|------|------|------|------|
| 设计 Journey 页 API | Design | 0.5d | Phase 1 |
| 实现话题热度统计 | BE | 1d | API 设计 |
| 实现目标相关性计算 | BE | 1d | 热度统计 |
| 实现自动进度识别 | BE | 1.5d | API 设计 |
| Journey 页 API 开发 | BE | 1d | 后端逻辑 |
| 智能排序列表 UI | FE | 1d | API |
| 热度指示器 UI | FE | 0.5d | API |
| 自动进度提示 UI | FE | 0.5d | API |
| 前后端联调 | Full | 1d | 全部 |
| E2E 测试 | QA | 1d | 全部 |

### 5.3 关键代码位置

```
apps/api/
├── routes/
│   └── journey.py               # 扩展
└── services/
    └── journey/                 # 扩展
        ├── goal_ranker.py       # 新增
        ├── heat_calculator.py   # 新增
        └── progress_detector.py # 新增

apps/web/src/
├── app/journey/                 # 扩展
└── components/journey/          # 扩展
    ├── SmartGoalList.tsx
    ├── HeatIndicator.tsx
    └── AutoProgressBadge.tsx
```

### 5.4 验收标准

- [ ] 目标按话题热度排序
- [ ] 热度指示器正确显示
- [ ] 自动识别进度准确率 > 70%
- [ ] 页面加载 < 2s

---

## 六、风险与缓解

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|----------|
| 抽取准确率不足 | 中 | 高 | 人工标注 + 模型微调 |
| 推送过于频繁打扰用户 | 中 | 高 | 严格频率控制 + A/B 测试 |
| 融合洞察质量不稳定 | 高 | 中 | Prompt 迭代 + 人工审核 |
| 性能问题 | 低 | 中 | 异步处理 + 缓存 |

---

## 七、成功指标

### 7.1 技术指标

| 指标 | 目标值 |
|------|--------|
| 抽取延迟 | < 500ms |
| API 响应时间 | < 200ms |
| 推送送达率 | > 95% |
| 系统可用性 | > 99.5% |

### 7.2 业务指标

| 指标 | 目标值 |
|------|--------|
| Me 页访问量 | +30% |
| Journey 页互动率 | +20% |
| 推送点击率 | > 15% |
| 用户 7日留存 | +10% |

---

## 八、里程碑

| 日期 | 里程碑 | 交付物 |
|------|--------|--------|
| Week 2 末 | 抽取基础完成 | Extractor + DB |
| Week 4 末 | Proactive 上线 | 智能推送 |
| Week 6 末 | Me 页上线 | 动态洞察 |
| Week 8 末 | Journey 页上线 | 智能排序 |
