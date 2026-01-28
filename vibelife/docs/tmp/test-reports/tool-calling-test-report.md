# CoreAgent 工具调用测试报告

> 生成时间: 2026-01-14 21:41:58

## 测试概览

| 指标 | 数值 |
|------|------|
| 总测试数 | 14 |
| 通过 | 7 |
| 失败 | 7 |
| 通过率 | 50.0% |

## 测试结果详情

### CORE Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| core_auto_bazi | Core Skill 自动识别八字关键词并调用 use_skill | `use_skill` | `(无)` | ❌ 失败 |
| core_auto_zodiac | Core Skill 自动识别星座关键词并调用 use_skill | `use_skill` | `use_skill, request_info` | ✅ 通过 |
| core_auto_tarot | Core Skill 自动识别塔罗关键词并调用 use_skill | `use_skill` | `use_skill, ask_user_question, draw_tarot_cards, show_skill_services, search_db` | ✅ 通过 |
| core_auto_career | Core Skill 自动识别职业关键词并调用 use_skill | `use_skill` | `(无)` | ❌ 失败 |

### BAZI Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| bazi_chart | Bazi Skill 调用 show_bazi_chart 展示命盘 | `show_bazi_chart` | `calculate_bazi, show_bazi_chart, show_insight` | ✅ 通过 |
| bazi_fortune | Bazi Skill 调用 show_bazi_fortune 展示运势 | `show_bazi_fortune` | `calculate_bazi, show_bazi_chart, show_bazi_fortune, show_insight` | ✅ 通过 |
| bazi_kline | Bazi Skill 调用 show_bazi_kline 展示 K 线图 | `show_bazi_kline` | `calculate_bazi, show_bazi_kline, show_bazi_fortune, show_insight` | ✅ 通过 |

### ZODIAC Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| zodiac_chart | Zodiac Skill 调用 show_zodiac_chart 展示星盘 | `show_zodiac_chart` | `show_zodiac_chart, search_db, search_db, show_insight` | ✅ 通过 |
| zodiac_transit | Zodiac Skill 调用 show_zodiac_transit 展示行运 | `show_zodiac_transit` | `show_zodiac_chart, show_zodiac_transit, search_db, search_db, show_insight` | ✅ 通过 |
| zodiac_synastry | Zodiac Skill 调用 show_zodiac_synastry 展示合盘 | `show_zodiac_synastry` | `(无)` | ❌ 失败 |

### CAREER Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| career_analysis | Career Skill 调用 show_career_analysis 展示职业分析 | `show_career_analysis` | `request_info, ask_user_question, search_db, search_db` | ❌ 失败 |
| career_personality | Career Skill 调用 show_personality_profile 展示人格画像 | `show_personality_profile` | `(无)` | ❌ 失败 |

### TAROT Skill

| 测试名称 | 描述 | 期望工具 | 实际工具 | 状态 |
|----------|------|----------|----------|------|
| tarot_single | Tarot Skill 调用 show_tarot_card 抽单牌 | `show_tarot_card` | `ask_user_question, draw_tarot_cards, draw_tarot_cards, show_tarot_spread` | ❌ 失败 |
| tarot_three | Tarot Skill 调用 show_tarot_card 抽三牌 | `show_tarot_card` | `(无)` | ❌ 失败 |

## 失败用例详细分析

### core_auto_bazi

**描述**: Core Skill 自动识别八字关键词并调用 use_skill

**Skill**: `core (auto)`

**用户消息**: 帮我测八字

**期望工具**: `use_skill`

**实际工具**: `(无)`

**LLM 回复**:
```
我来帮您进行八字测算。为了给您提供准确的八字命盘分析，我需要知道您的出生信息。

请提供以下信息：
1. **出生年月日时**（公历或农历都可以）
2. **出生地点**（省市县）
3. **性别**

例如：
- 公历：1990年5月15日 下午3点30分
- 农历：庚午年四月廿一 申时
- 出生地：北京市朝阳区
- 性别：男

有了这些信息，我就可以为您排八字、看命盘，分析您的性格、事业、财运、感情等方面的运势了。
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

### core_auto_career

**描述**: Core Skill 自动识别职业关键词并调用 use_skill

**Skill**: `core (auto)`

**用户消息**: 我想换工作，给点建议

**期望工具**: `use_skill`

**实际工具**: `(无)`

**LLM 回复**:
```
我理解你想换工作的想法。为了给你更有针对性的职业建议，我需要了解一些基本信息：

1. **你的出生信息**：出生年月日时（阳历或农历）和出生地点，这样我可以结合你的命理特点来分析

2. **当前工作情况**：你现在从事什么行业？工作多久了？

3. **换工作原因**：是什么让你想换工作？是薪资、发展空间、工作内容还是其他原因？

4. **兴趣方向**：有没有特别感兴趣的行业或岗位？

有了这些信息，我就能从命理角度分析你的职业特质、适合的发展方向，以及当前是否适合变动，给你更精准的建议。

你可以先告诉我出生信息吗？
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
我理解你想了解与某个人的关系匹配度。要分析两个人的星盘合盘，我需要先了解你们双方的出生信息。

目前我只知道你的出生信息（1990年5月15日14:30，北京），但还需要知道对方的出生信息才能进行合盘分析。

请告诉我对方的出生信息：
- 出生日期（年、月、日）
- 出生时间（尽可能精确）
- 出生地点（城市）

有了这些信息后，我就可以：
1. 计算对方的星盘
2. 分析你们两人的星盘合盘
3. 从相位、宫位、元素等角度评估关系潜力
4. 识别可能的挑战和成长机会

请提供对方的出生信息，我来为你进行详细的关系合盘分析。
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

### career_analysis

**描述**: Career Skill 调用 show_career_analysis 展示职业分析

**Skill**: `career`

**用户消息**: 我适合什么职业

**期望工具**: `show_career_analysis`

**实际工具**: `request_info, ask_user_question, search_db, search_db`

**错误**: {'error': 'Object of type UUID is not JSON serializable'}

**LLM 回复**:
```
我来帮您分析适合的职业方向。首先，我需要了解一些基本信息来为您提供更精准的分析。我看到您之前已经提供了出生信息（1990年5月15日14:30，北京），这很好。现在我需要了解您的职业背景信息：在等待您的回复时，让我先基于您的出生信息进行一些初步分析，并检索相关的职业发展知识。
```

**工具调用详情**:
```json
[
  {
    "id": "call_00_ETsffp8hqJ4mjGffywFUdvJB",
    "name": "request_info",
    "arguments": "{\"info_type\": \"context\", \"question\": \"为了更好地分析您的职业方向，请告诉我：\\n1. 您的教育背景和专业是什么？\\n2. 目前的工作经历或实习经历有哪些？\\n3. 您对哪些领域或工作内容特别感兴趣？\"}"
  },
  {
    "id": "call_00_65qiZhroXvghNin9Os6BdoDF",
    "name": "ask_user_question",
    "arguments": "{\"question\": \"为了更好地分析您的职业方向，请告诉我：\\n1. 您的教育背景和专业是什么？\\n2. 目前的工作经历或实习经历有哪些？\\n3. 您对哪些领域或工作内容特别感兴趣？\"}"
  },
  {
    "id": "call_00_X52o99O0t5roV3UvnsRKgXDE",
    "name": "search_db",
    "arguments": "{\"table\": \"knowledge_chunks\", \"query\": \"职业方向分析 性格类型 MBTI 九型人格\", \"top_k\": 5}"
  },
  {
    "id": "call_00_Z9dW9dYbtyEDo5RdlZpvkcFn",
    "name": "search_db",
    "arguments": "{\"table\": \"knowledge_chunks\", \"query\": \"career direction personality analysis\", \"top_k\": 5}"
  }
]
```

**问题分析**:
- LLM 调用了错误的工具: `request_info` 而非 `show_career_analysis`
- 可能原因：工具调用规则表中的用户意图描述不够准确
- 建议：更新 SKILL.md 中的工具调用规则表

---

### career_personality

**描述**: Career Skill 调用 show_personality_profile 展示人格画像

**Skill**: `career`

**用户消息**: 分析一下我的性格

**期望工具**: `show_personality_profile`

**实际工具**: `(无)`

**LLM 回复**:
```
我注意到您已经提供了出生信息（1990年5月15日14:30，北京），这让我可以为您进行详细的性格分析。

不过，为了给您提供更精准的性格分析，我需要先了解一下您希望从哪个角度来探索您的性格特质：

1. **八字命理角度** - 基于您的出生时间分析五行能量、十神配置等，了解您的先天性格特质
2. **现代心理学角度** - 结合MBTI、九型人格等理论，分析您的性格类型和优势
3. **综合角度** - 结合传统命理和现代心理学，给您一个全面的性格画像

您更倾向于哪种分析方式呢？
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

### tarot_single

**描述**: Tarot Skill 调用 show_tarot_card 抽单牌

**Skill**: `tarot`

**用户消息**: 帮我抽一张牌

**期望工具**: `show_tarot_card`

**实际工具**: `ask_user_question, draw_tarot_cards, draw_tarot_cards, show_tarot_spread`

**LLM 回复**:
```
我将为您抽取一张塔罗牌。在抽牌之前，我想了解一下，您是否有特定的问题或领域想要获得指引？比如关于工作、感情、个人成长，或者只是想获得一些日常的启发？现在为您抽取一张塔罗牌：让我重新为您抽牌：看起来抽牌功能暂时不可用。不过，我可以基于塔罗哲学为您提供一些指引。

根据塔罗的智慧，单牌抽取通常反映的是当下的能量状态或需要关注的焦点。既然您没有特定的问题，这张牌将为您揭示当前生活中最需要关注的方向。

让我为您展示牌阵：让我为您提供一些塔罗的日常指引：

**今日塔罗启示：**

在塔罗哲学中，每一张牌都是一面镜子，反映我们内心的状态。既然您选择单牌抽取，这通常意味着：

1. **当下的能量** - 这张牌会揭示您当前的能量状态
2. **需要关注的焦点** - 指出生活中最需要关注的方向
3. **潜意识的提醒** - 反映您内心深处的智慧

**核心指引：**
今天，请花一些时间静心观察自己的内在状态。塔罗不是预测未来，而是帮助您看清当下的自己。无论您面临什么情况，记住您拥有内在的智慧和力量去应对。

**建议行动：**
- 花5分钟静坐，感受自己的呼吸
- 思考今天最让您在意的一件事...
```

**工具调用详情**:
```json
[
  {
    "id": "call_00_FqmWeYtcBr57UQpNOylmB4Eu",
    "name": "ask_user_question",
    "arguments": "{\"question\": \"您是否有特定的问题或领域想要获得指引？比如关于工作、感情、个人成长，或者只是想获得一些日常的启发？\"}"
  },
  {
    "id": "call_00_1zGzrf3fxrIv4AvCBfUYbBLT",
    "name": "draw_tarot_cards",
    "arguments": "{\"spread_type\": \"single\"}"
  },
  {
    "id": "call_00_RoufplQXvBCpV7CbHf3rxKyn",
    "name": "draw_tarot_cards",
    "arguments": "{\"spread_type\": \"single\"}"
  },
  {
    "id": "call_00_IMnm1DPfiLRigvn36XwgmSMy",
    "name": "show_tarot_spread",
    "arguments": "{}"
  }
]
```

**问题分析**:
- LLM 调用了错误的工具: `ask_user_question` 而非 `show_tarot_card`
- 可能原因：工具调用规则表中的用户意图描述不够准确
- 建议：更新 SKILL.md 中的工具调用规则表

---

### tarot_three

**描述**: Tarot Skill 调用 show_tarot_card 抽三牌

**Skill**: `tarot`

**用户消息**: 来个三牌阵

**期望工具**: `show_tarot_card`

**实际工具**: `(无)`

**LLM 回复**:
```
我来为您抽取一个三牌阵。三牌阵通常用于探索过去、现在、未来的关系，或者原因、现状、结果的脉络。

请问您想针对什么具体问题或主题进行抽牌呢？比如：
- 某个特定情况的发展
- 某个决定的影响
- 某个关系的走向
- 或者您只是想看看当前的能量状态

请告诉我您的关注点，这样我可以更好地为您解读牌面的意义。
```

**问题分析**:
- LLM 没有调用任何工具，直接用文字回答
- 可能原因：SKILL.md 中的工具调用规则不够明确
- 建议：检查对应 skill 的 SKILL.md，确保有明确的工具调用规则表

---

## 优化建议

### 需要修复的问题

- **core**: 2 个测试失败
  - 检查 `apps/api/skills/core/SKILL.md` 的工具调用规则
- **zodiac**: 1 个测试失败
  - 检查 `apps/api/skills/zodiac/SKILL.md` 的工具调用规则
- **career**: 2 个测试失败
  - 检查 `apps/api/skills/career/SKILL.md` 的工具调用规则
- **tarot**: 2 个测试失败
  - 检查 `apps/api/skills/tarot/SKILL.md` 的工具调用规则

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
