# CoreAgent 工具调用测试报告

> 生成时间: 2026-01-13 15:03:37

## 测试概览

| 指标 | 数值 |
|------|------|
| 总测试数 | 14 |
| 通过 | 11 |
| 失败 | 3 |
| 通过率 | 78.6% |

## 测试结果详情

### CORE Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| core_auto_bazi | Core Skill 自动识别八字关键词并调用 use_skill | `use_skill` | `use_skill, show_bazi_chart` | ✅ 通过 |
| core_auto_zodiac | Core Skill 自动识别星座关键词并调用 use_skill | `use_skill` | `use_skill, show_zodiac_chart` | ✅ 通过 |
| core_auto_tarot | Core Skill 自动识别塔罗关键词并调用 use_skill | `use_skill` | `use_skill, show_tarot_card, show_tarot_card, use_skill` | ✅ 通过 |
| core_auto_career | Core Skill 自动识别职业关键词并调用 use_skill | `use_skill` | `(无)` | ❌ 失败 |

### BAZI Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| bazi_chart | Bazi Skill 调用 show_bazi_chart 展示命盘 | `show_bazi_chart` | `show_bazi_chart` | ✅ 通过 |
| bazi_fortune | Bazi Skill 调用 show_bazi_fortune 展示运势 | `show_bazi_fortune` | `show_bazi_fortune, show_bazi_chart` | ✅ 通过 |
| bazi_kline | Bazi Skill 调用 show_bazi_kline 展示 K 线图 | `show_bazi_kline` | `show_bazi_kline, show_bazi_chart, show_bazi_fortune` | ✅ 通过 |

### ZODIAC Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| zodiac_chart | Zodiac Skill 调用 show_zodiac_chart 展示星盘 | `show_zodiac_chart` | `show_zodiac_chart` | ✅ 通过 |
| zodiac_transit | Zodiac Skill 调用 show_zodiac_transit 展示行运 | `show_zodiac_transit` | `show_zodiac_transit` | ✅ 通过 |
| zodiac_synastry | Zodiac Skill 调用 show_zodiac_synastry 展示合盘 | `show_zodiac_synastry` | `(无)` | ❌ 失败 |

### CAREER Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| career_analysis | Career Skill 调用 show_career_analysis 展示职业分析 | `show_career_analysis` | `show_career_analysis, show_report` | ✅ 通过 |
| career_personality | Career Skill 调用 show_personality_profile 展示人格画像 | `show_personality_profile` | `show_career_analysis, show_insight, show_report` | ❌ 失败 |

### TAROT Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| tarot_single | Tarot Skill 调用 show_tarot_card 抽单牌 | `show_tarot_card` | `show_tarot_card, show_tarot_card` | ✅ 通过 |
| tarot_three | Tarot Skill 调用 show_tarot_card 抽三牌 | `show_tarot_card` | `show_tarot_card, show_tarot_card` | ✅ 通过 |

## 失败用例详细分析

### core_auto_career

**描述**: Core Skill 自动识别职业关键词并调用 use_skill

**Skill**: `core (auto)`

**用户消息**: 我想换工作，给点建议

**期望工具**: `use_skill`

**实际工具**: `(无)`

**LLM 回复**:
```
我感受到你正在考虑职业变动，这是一个需要认真对待的决定。换工作不仅仅是换个地方上班，它涉及到你的职业发展、生活节奏，甚至自我认同。

不过，在给出建议之前，我想先了解一些背景，这样能更有针对性地帮你思考：

**你现在的状态是怎样的？**
- 是什么让你想离开现在的工作？是环境、发展空间，还是其他什么？
- 这个想法在你心里酝酿多久了？是突然的决定，还是积累了很久？

**你期待的变化是什么？**
- 你希望新工作能带来什么现在没有的东西？
- 有没有特别想尝试的方向或行业？

**你的顾虑有哪些？**
- 最让你犹豫不决的是什么？
- 有没有什么现实因素需要考虑（比如经济压力、家庭支持等）？

另外，如果你愿意，我可以帮你从职业发展的角度做一些分析。这需要了解你的出生信息，但如果你不想提供也没关系，我们可以继续聊你的想法。

你想从哪里开始聊起？
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

### zodiac_synastry

**描述**: Zodiac Skill 调用 show_zodiac_synastry 展示合盘

**Skill**: `zodiac`

**用户消息**: 我和他合适吗

**期望工具**: `show_zodiac_synastry`

**实际工具**: `(无)`

**LLM 回复**:
```
我看到你想了解关系的兼容性。为了给你提供准确的关系分析，我需要知道对方的出生信息。

你可以告诉我：
- 对方的出生日期（年月日）
- 出生时间（如果知道的话）
- 出生地点

这样我就能为你展示详细的合盘分析，看看你们之间的能量互动和成长潜力。
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

### career_personality

**描述**: Career Skill 调用 show_personality_profile 展示人格画像

**Skill**: `career`

**用户消息**: 分析一下我的性格

**期望工具**: `show_personality_profile`

**实际工具**: `show_career_analysis, show_insight, show_report`

**LLM 回复**:
```
我来帮你分析一下性格特点。根据你的出生信息，我可以为你生成一份人格画像。让我用正确的方式为你展示性格分析。看起来我需要为你生成更完整的性格分析报告。让我为你展示详细的性格分析。我看到这是一个演示版的报告。让我为你提供一些关于性格分析的思路：

从你的出生信息来看，1990年5月15日出生的人通常具有一些共同的特点，但每个人的性格都是独特的。我想了解：

1. **你觉得自己最明显的性格特点是什么？**
   - 比如：外向还是内向？喜欢计划还是随性？

2. **在什么情况下你感觉最有活力？**
   - 是与人交流时，还是独处思考时？

3. **你做决定时更倾向于什么方式？**
   - 逻辑分析，还是跟着感觉走？

4. **最近有没有什么让你特别困扰的性格特点？**

这样我可以更好地理解你的性格模式，而不是仅仅基于出生日期给你一个标签化的分析。

你觉得从哪个问题开始聊比较好？
```

**工具调用详情**:
```json
[
  {
    "id": "call_00_hUh0GJv8PnmLCCHPNAJ4bhRY",
    "name": "show_career_analysis",
    "arguments": "{\"analysisType\": \"direction\"}"
  },
  {
    "id": "call_00_uyKBtKrCN9pQsMSw8CTKmQSu",
    "name": "show_insight",
    "arguments": "{\"category\": \"personality\"}"
  },
  {
    "id": "call_00_iBEsBEo39NUkAf7PoyEa7AbS",
    "name": "show_report",
    "arguments": "{\"reportType\": \"full\"}"
  }
]
```

**问题分析**:
- LLM 调用了错误的工具: `show_career_analysis` 而非 `show_personality_profile`
- 可能原因：工具调用规则表中的用户意图描述不够准确
- 建议：更新 SKILL.md 中的工具调用规则表

---

## 优化建议

### 需要修复的问题

- **core**: 1 个测试失败
  - 检查 `apps/api/skills/core/SKILL.md` 的工具调用规则
- **zodiac**: 1 个测试失败
  - 检查 `apps/api/skills/zodiac/SKILL.md` 的工具调用规则
- **career**: 1 个测试失败
  - 检查 `apps/api/skills/career/SKILL.md` 的工具调用规则

### 通用优化建议

1. **确保每个 SKILL.md 包含工具调用规则表**
   ```markdown
   ## 工具调用规则（必须遵守）

   | 用户意图 | 必须调用的工具 |
   |---------|--------------|
   | ... | ... |
   ```

2. **为每个工具提供调用示例**
   ```markdown
   **示例**：
   - 用户问"XXX" → 必须调用 `tool_a(param=value)`
   ```

3. **使用强制性语气**
   - 使用"必须"而非"可以"
   - 使用"你必须通过调用工具来展示结果"

4. **定期运行此测试脚本验证工具调用**
   ```bash
   python scripts/test_tool_calling.py
   ```
