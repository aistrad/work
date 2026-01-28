# Lifecoach Skill 设计文档

版本: 1.0 | 日期: 2026-01-19
基于: Dan Koe《How to Fix Your Entire Life in 1 Day》

---

## 1. 知识摄入分析

### 1.1 知识类型分类

| 类型 | 内容 | 放置位置 |
|-----|------|---------|
| **程序性知识** | 一日重置协议、身份转变流程 | rules/ |
| **声明性知识** | 7大理论洞见、9阶段心智模型 | reference/ |
| **启发式知识** | 行为目标论、身份优先原则 | SKILL.md 核心理念 |

### 1.2 触发条件

**主要触发词**:
- 迷茫、不知道想要什么、没方向
- 卡住、做不到、拖延、没动力
- 想改变、想成为、新的我
- 目标、愿景、人生规划

**用户典型表达**:
- "我不知道自己想要什么"
- "我总是拖延重要的事"
- "我想改变但做不到"
- "我感觉卡住了"

### 1.3 核心工作流

```
心理考古 → 反愿景构建 → 愿景MVP → 身份设计 → 目标层级 → 游戏化整合
```

### 1.4 决策点

1. **阶段判断**: 用户处于迷茫期/卡点期/转型期?
2. **卡点类型**: 认知卡点 vs 情绪卡点 vs 身份卡点?
3. **深度选择**: 轻量引导 vs 深度协议?

---

## 2. 核心理论框架

### 2.1 七大核心洞见 (Dan Koe)

| # | 洞见 | 核心观点 |
|---|-----|---------|
| 1 | **身份优先** | 改变行为前先改变你是谁 |
| 2 | **行为即目标** | 所有行为都在追求某个目标(包括自我破坏) |
| 3 | **反愿景力量** | 负能量是最强动力，如果知道如何使用 |
| 4 | **心智阶段** | 心智通过可预测阶段进化 |
| 5 | **控制论智能** | 智能 = 目标→行动→反馈→调整的迭代能力 |
| 6 | **一日协议** | 通过深度自省实现快速转变 |
| 7 | **游戏化框架** | 把人生设计成你想玩的游戏 |

### 2.2 思维架构体系

| 架构 | 维度 | 应用场景 |
|-----|------|---------|
| 身份-行为架构 | Identity → Behavior → Result | 习惯改变、目标达成 |
| 目标解码架构 | Surface → Hidden → True Need | 卡点分析、拖延 |
| 反愿景架构 | Anti-Vision → Vision → Gap | 迷茫、缺乏动力 |
| 控制论架构 | Goal → Action → Feedback → Adjust | 持续改进 |
| 游戏化架构 | Win → Lose → Mission → Quest → Rules | 人生设计 |

### 2.3 一日重置协议 (轻量版)

```
┌─────────────────────────────────────────────────────────────┐
│                    一日重置协议                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  早晨: 心理考古                                              │
│  ├── 挖掘隐藏不满                                           │
│  ├── 识别行为-目标关系                                       │
│  └── 构建反愿景                                             │
│                                                             │
│  白天: 觉察中断                                              │
│  ├── 定时提问打断自动驾驶                                    │
│  └── 觉察行为背后的真实目标                                  │
│                                                             │
│  晚上: 整合输出                                              │
│  ├── 构建愿景 MVP                                           │
│  ├── 设计新身份                                             │
│  └── 设定目标层级 (年→月→日)                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Skill 架构设计

### 3.1 采用 Agentic + 渐进式加载架构

```
lifecoach/
├── SKILL.md                    # 核心定义 (< 200 行)
├── rules/                      # 分析规则 (按需加载)
│   ├── _index.md              # 规则索引
│   ├── pattern-decode.md      # 模式解码能力
│   ├── anti-vision.md         # 反愿景构建能力
│   ├── vision-design.md       # 愿景设计能力
│   ├── identity-shift.md      # 身份转换能力
│   ├── stuck-breakthrough.md  # 卡点突破能力
│   └── life-game.md           # 人生游戏化能力
├── tools/
│   ├── tools.yaml             # 工具定义
│   └── handlers.py            # 工具执行器
└── reference/
    └── dan-koe-framework.md   # Dan Koe 完整框架参考
```

### 3.2 核心能力索引

| 能力 | 优先级 | 规则文件 | 触发场景 |
|-----|-------|---------|---------|
| 模式解码 | CRITICAL | `rules/pattern-decode.md` | 发现重复模式、理解行为背后目标 |
| 卡点突破 | HIGH | `rules/stuck-breakthrough.md` | 卡住、做不到、拖延 |
| 反愿景构建 | HIGH | `rules/anti-vision.md` | 不想成为、害怕、讨厌现状 |
| 愿景设计 | HIGH | `rules/vision-design.md` | 想要什么、目标、方向 |
| 身份转换 | MEDIUM | `rules/identity-shift.md` | 想成为、改变自己 |
| 人生游戏化 | MEDIUM | `rules/life-game.md` | 人生规划、设计人生 |

### 3.3 工具设计

| 工具 | 类型 | 用途 |
|-----|------|------|
| `show_pattern_insight` | display | 展示行为模式洞察 |
| `show_vision_map` | display | 展示愿景/反愿景地图 |
| `show_identity_design` | display | 展示身份设计卡片 |
| `show_life_game` | display | 展示人生游戏设计 |
| `show_action_plan` | display | 展示行动计划 |

---

## 4. 与其他 Skill 联动

| 联动方式 | 触发条件 | 组合 |
|---------|---------|------|
| 命理→行动 | 完成命理分析后问"然后呢" | bazi/zodiac + lifecoach |
| 职业→突破 | 职业规划遇到心理卡点 | career + lifecoach |
| 目标→追踪 | 设定目标后需要监督 | lifecoach + core(目标追踪) |

---

## 5. 核心问题库

### 5.1 心理考古问题

```
- 你学会忍受的、持续的不满是什么？
- 过去一年你抱怨最多但从未真正改变的三件事是什么？
- 如果有人只看你的行为(而非你的话)，他们会认为你真正想要的是什么？
- 有什么关于你现在生活的真相，是你无法承受对你尊敬的人说出口的？
```

### 5.2 反愿景问题

```
- 如果未来5年什么都不改变，描述一个普通的周二。
- 10年后：你错过了什么？什么机会关闭了？
- 你生命的尽头，你过了安全的版本。代价是什么？
- 谁正在过着你描述的那个未来？你想到成为他们时感觉如何？
```

### 5.3 身份问题

```
- 要真正改变，你必须放弃什么身份？("我是那种会..."的人)
- 你没有改变的最令人尴尬的原因是什么？
- 如果你的当前行为是一种自我保护，你到底在保护什么？
```

### 5.4 愿景问题

```
- 忘记可行性。3年后你真正想要的生活是什么样？
- 你必须相信自己什么，才能让那种生活感觉自然？
- 如果你已经是那个人，这周你会做什么？
```

---

## 6. 实现检查清单

### 6.1 SKILL.md 检查

- [ ] 行数 < 200 行
- [ ] Frontmatter 包含 name 和 description
- [ ] description 包含触发词
- [ ] 核心能力索引表格完整
- [ ] 每个能力都有优先级标注
- [ ] 工具快速参考表格完整
- [ ] 服务原则 5 条
- [ ] 伦理边界完整

### 6.2 Rule 检查

- [ ] 每个能力都有对应 rule 文件
- [ ] Frontmatter 包含 id, name, impact, tags
- [ ] 分析要点表格完整
- [ ] 每个要点都有检索 Query
- [ ] 输出要求明确

### 6.3 工具检查

- [ ] tools.yaml 定义完整
- [ ] handlers.py 实现完整
- [ ] 卡片类型定义清晰

---

## 7. 方法论来源

**主要来源**: Dan Koe《How to Fix Your Entire Life in 1 Day》

**核心引用**:

> "If you want a specific outcome in life, you must have the lifestyle that creates that outcome long before you reach it."

> "All behavior is goal-oriented... if you can't stop procrastinating your work, you are attempting to achieve a goal. In this case, that goal could be to protect yourself from the judgment."

> "The best periods of my life always came after a period of getting absolutely fed up with the lack of progress I was making."

> "Your vision is how you win. Your anti-vision is what's at stake. Your 1 year goal is the mission. Your 1 month project is the boss fight. Your daily levers are the quests."
