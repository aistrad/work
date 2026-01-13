# CoreAgent 全面深度测试报告

> 生成时间: 2026-01-13 16:00:34
> 测试基于: user-flow-design-v2.1.md, user case.md

## 测试概览

| 指标 | 数值 |
|------|------|
| 总测试数 | 21 |
| 通过 | 19 |
| 失败 | 2 |
| 通过率 | 90.5% |

## 按类别统计

| 类别 | 通过/总数 | 通过率 |
|------|----------|--------|
| 认识自我 | 3/3 | 100% |
| 理解当下 | 2/3 | 67% |
| 如何改变 | 2/2 | 100% |
| 咨询问事 | 2/2 | 100% |
| 合盘 | 2/2 | 100% |
| 自动路由 | 4/4 | 100% |
| 人格模式 | 2/2 | 100% |
| 边界情况 | 1/2 | 50% |
| 可视化 | 1/1 | 100% |

## 测试结果详情


### 认识自我

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| self_bazi_deep | BaZi 深度自我认知 | `show_bazi_chart` | `show_bazi_chart, show_report` | ✅ |
| self_zodiac_emotion | Zodiac 情绪模式识别 | `show_zodiac_chart` | `show_zodiac_chart, show_zodiac_transit` | ✅ |
| self_career_mbti | Career/MBTI 认知盲点 | `show_personality_profile` | `show_personality_profile, show_report` | ✅ |

### 理解当下

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| now_bazi_fortune | BaZi 运势归因 | `show_bazi_fortune` | `(对话)` | ❌ |
| now_zodiac_transit | Zodiac 环境主动提醒 | `show_zodiac_transit` | `show_zodiac_transit` | ✅ |
| now_bazi_year | BaZi 流年运势 | `show_bazi_fortune` | `show_bazi_fortune, show_bazi_chart` | ✅ |

### 如何改变

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| change_bazi_daily | BaZi 每日微行动 | `show_bazi_fortune` | `show_bazi_chart, show_bazi_fortune, show_insight` | ✅ |
| change_career_plan | Career 长程转型计划 | `show_career_analysis` | `show_career_analysis, show_report` | ✅ |

### 咨询问事

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| consult_bazi_career | BaZi 职业决策 | `show_bazi_chart, show_bazi_fortune` | `show_bazi_chart, show_bazi_fortune, show_bazi_kline` | ✅ |
| consult_tarot_decision | Tarot 决策咨询 | `show_tarot_card` | `show_tarot_card` | ✅ |

### 合盘

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| relation_zodiac_synastry | Zodiac 合盘分析（有对方信息） | `show_zodiac_synastry` | `show_zodiac_synastry` | ✅ |
| relation_zodiac_no_partner | Zodiac 合盘分析（无对方信息） | `(对话)` | `(对话)` | ✅ |

### 自动路由

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| auto_bazi | Core 自动识别八字 | `use_skill` | `use_skill, show_bazi_chart` | ✅ |
| auto_zodiac | Core 自动识别星座 | `use_skill` | `use_skill, show_zodiac_chart` | ✅ |
| auto_tarot | Core 自动识别塔罗 | `use_skill` | `use_skill, show_tarot_card, show_tarot_card` | ✅ |
| auto_career | Core 自动识别职业 | `use_skill` | `use_skill, show_bazi_chart, show_bazi_fortune, show_bazi_kline` | ✅ |

### 人格模式

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| voice_warm | 暖心闺蜜模式 | `show_bazi_fortune` | `show_bazi_fortune, show_bazi_chart` | ✅ |
| voice_sarcastic | 毒舌损友模式 | `show_bazi_fortune` | `show_bazi_chart, show_bazi_fortune` | ✅ |

### 边界情况

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| edge_no_birth | 无出生信息时的处理 | `(对话)` | `show_bazi_chart` | ❌ |
| edge_vague_request | 模糊请求的处理 | `(对话)` | `(对话)` | ✅ |

### 可视化

| ID | 描述 | 期望工具 | 实际工具 | 状态 |
|-----|------|----------|----------|------|
| kline_trend | BaZi K线图 | `show_bazi_kline` | `show_bazi_kline, show_bazi_chart, show_bazi_fortune, show_report` | ✅ |

## 失败用例详细分析

### now_bazi_fortune

**描述**: BaZi 运势归因

**类别**: 理解当下

**Skill**: `bazi`

**用户消息**: 最近诸事不顺，很累，是不是我能力有问题？

**期望行为**: 展示运势，提供客观归因，减轻心理负担

**期望工具**: `show_bazi_fortune`

**实际工具**: `(对话)`

**LLM 回复**:
```
听到你这么说，我能感受到那种疲惫和挫败感。当一连串事情都不顺利的时候，确实很容易开始怀疑自己。

不过，我想先问问你：这个"诸事不顺"，具体是指哪些方面呢？是工作上的挑战，还是人际关系，或者是其他什么？

另外，这种"累"的感觉，是身体上的疲惫，还是心里那种"提不起劲"的状态？它持续多久了？

有时候，我们遇到不顺的时候，会习惯性地把原因归结到自己身上，觉得是不是自己不够好、能力不足。但很多时候，事情不顺可能和时机、环境、甚至只是暂时的能量低谷有关。

你想聊聊具体发生了什么吗？
```

---

### edge_no_birth

**描述**: 无出生信息时的处理

**类别**: 边界情况

**Skill**: `bazi`

**用户消息**: 看看我的命盘

**期望行为**: 询问出生信息

**期望工具**: `(对话)`

**实际工具**: `show_bazi_chart`

**LLM 回复**:
```
我来帮你查看八字命盘。看到了你的八字命盘。你是**甲木日主**，生于庚午年、戊子月、甲辰日、甲寅时。

让我先给你一个直观的感受：

**甲木**，就像森林里最高大的那棵树，正直、坚韧、有担当。你的命盘里木元素最旺（3个），说明你天生有种"向上生长"的力量——不甘平庸，想要成就一番事业。

**正印格**很有意思。印星代表学习、积累、内在的滋养。这格局的人通常：
- 喜欢思考，有深度
- 学习能力强，知识吸收快  
- 内心世界丰富，但有时想得太多
- 需要时间来沉淀和积累

你的命盘中**火元素**也相当明显（2个），这给了甲木温暖和展现的机会。火是木的食伤，代表才华、表达、创造力。所以你不...
```

---

## 测试结论与建议

### 通过的场景
- ✅ **认识自我**: 全部通过
- ✅ **如何改变**: 全部通过
- ✅ **咨询问事**: 全部通过
- ✅ **合盘**: 全部通过
- ✅ **自动路由**: 全部通过
- ✅ **人格模式**: 全部通过
- ✅ **可视化**: 全部通过

### 需要关注的场景
- ⚠️ **理解当下**: 2/3 通过
- ⚠️ **边界情况**: 1/2 通过

### 测试覆盖说明

本测试集基于以下文档设计：
1. **user case.md** - 用户场景（认识自我、理解当下、如何改变、咨询问事、合盘）
2. **user-flow-design-v2.1.md** - 用户流程（人格选择、深度访谈、转化）

测试维度：
- 用户场景覆盖
- Skill 覆盖（bazi、zodiac、career、tarot）
- 人格模式覆盖（warm、sarcastic）
- 工具调用正确性
- 边界情况处理
