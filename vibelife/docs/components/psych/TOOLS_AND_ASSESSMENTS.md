# Psych Skill 工具与评估设计

> **Version**: 1.0.0
> **Purpose**: 定义 Psych Skill 的工具系统和评估量表

---

## 一、工具系统概览

```yaml
# tools.yaml - Psych Skill 工具定义

skill_id: psych
version: 1.0.0

compute:
  - name: calculate_assessment_score
    description: 计算心理评估量表得分
    card_type: assessment_result
    parameters:
      - name: assessment_type
        type: string
        enum: [phq9, gad7, dass21, phq2, gad2]
        required: true
      - name: responses
        type: array
        description: 用户对各题目的回答 (0-3)
        required: true

  - name: analyze_lifestyle
    description: 分析阿德勒生活风格
    card_type: lifestyle_profile
    parameters:
      - name: family_constellation
        type: object
        description: 家庭星座信息
      - name: early_recollections
        type: array
        description: 早期记忆列表
      - name: life_tasks_scores
        type: object
        description: 三大人生任务满意度评分

  - name: identify_cognitive_distortions
    description: 识别认知扭曲类型
    card_type: distortion_analysis
    parameters:
      - name: thought
        type: string
        description: 用户的自动化思维
        required: true

collect:
  - name: collect_assessment_responses
    description: 收集心理评估量表回答
    card_type: assessment_form
    parameters:
      - name: assessment_type
        type: string
        enum: [phq9, gad7, dass21, phq2, gad2]
        required: true
      - name: question
        type: string
        description: 引导语

  - name: collect_early_recollection
    description: 收集早期记忆
    card_type: narrative_form
    parameters:
      - name: recollection_number
        type: integer
        description: 第几个早期记忆
      - name: prompts
        type: array
        description: 引导问题列表

  - name: collect_family_constellation
    description: 收集家庭星座信息
    card_type: structured_form
    parameters:
      - name: section
        type: string
        enum: [birth_order, siblings, parents, family_atmosphere]

  - name: collect_thought_record
    description: 收集认知记录
    card_type: thought_record_form
    parameters:
      - name: situation
        type: string
      - name: emotion
        type: string
      - name: automatic_thought
        type: string
      - name: evidence_for
        type: string
      - name: evidence_against
        type: string
      - name: balanced_thought
        type: string

display:
  - name: show_assessment_result
    description: 展示评估结果
    card_type: assessment_result
    parameters:
      - name: assessment_type
        type: string
      - name: total_score
        type: integer
      - name: severity_level
        type: string
      - name: interpretation
        type: string
      - name: recommendations
        type: array

  - name: show_archetype_profile
    description: 展示原型特征
    card_type: archetype_profile
    parameters:
      - name: primary_archetype
        type: string
      - name: secondary_archetypes
        type: array
      - name: shadow_archetype
        type: string
      - name: description
        type: string
      - name: growth_suggestions
        type: array

  - name: show_distortion_analysis
    description: 展示认知扭曲分析
    card_type: distortion_card
    parameters:
      - name: original_thought
        type: string
      - name: distortion_types
        type: array
      - name: challenge_questions
        type: array
      - name: reframed_thought
        type: string

  - name: show_lifestyle_profile
    description: 展示生活风格分析
    card_type: lifestyle_profile
    parameters:
      - name: lifestyle_type
        type: string
      - name: core_beliefs
        type: object
      - name: birth_order_influence
        type: string
      - name: early_memory_themes
        type: array
      - name: growth_areas
        type: array

  - name: show_exercise
    description: 展示练习卡片
    card_type: exercise_card
    parameters:
      - name: exercise_name
        type: string
      - name: duration
        type: string
      - name: instructions
        type: array
      - name: reflection_prompts
        type: array

  - name: show_crisis_resources
    description: 展示危机资源
    card_type: crisis_alert
    parameters:
      - name: message
        type: string
      - name: hotlines
        type: array
      - name: immediate_steps
        type: array

search:
  - name: search_psych_knowledge
    description: 搜索心理学知识库
    parameters:
      - name: query
        type: string
        description: 搜索关键词
        required: true
      - name: category
        type: string
        enum: [jungian, adlerian, cbt, assessments, exercises, psychoeducation]
      - name: max_results
        type: integer
        default: 3

action:
  - name: save_assessment_history
    description: 保存评估历史记录
    parameters:
      - name: assessment_type
        type: string
      - name: score
        type: integer
      - name: date
        type: string

  - name: schedule_checkin
    description: 设置心理健康检查提醒
    parameters:
      - name: frequency
        type: string
        enum: [daily, weekly, monthly]
      - name: reminder_type
        type: string
        enum: [mood_check, assessment, exercise]
```

---

## 二、评估量表详细设计

### 2.1 PHQ-9 (患者健康问卷-9)

```yaml
phq9:
  metadata:
    name: 患者健康问卷-9
    name_en: Patient Health Questionnaire-9
    purpose: 筛查和评估抑郁症状严重程度
    items: 9
    recall_period: 过去两周
    time_to_complete: 3-5 分钟
    scoring_range: 0-27
    source: Kroenke et al., 2001

  introduction: |
    接下来我会问你一些关于过去两周感受的问题。
    请根据你的实际感受选择最符合的选项。
    没有对错之分，请诚实回答。

  response_scale:
    0: 完全没有
    1: 有几天
    2: 一半以上时间
    3: 几乎每天

  items:
    - id: 1
      text: 做事时提不起劲或没有兴趣
      domain: anhedonia

    - id: 2
      text: 感到心情低落、沮丧或绝望
      domain: depressed_mood

    - id: 3
      text: 入睡困难、睡不安稳或睡眠过多
      domain: sleep

    - id: 4
      text: 感觉疲倦或没有精力
      domain: fatigue

    - id: 5
      text: 食欲不振或吃太多
      domain: appetite

    - id: 6
      text: 觉得自己很糟——或觉得自己很失败，或让自己或家人失望
      domain: self_worth

    - id: 7
      text: 难以集中注意力做事，例如阅读报纸或看电视
      domain: concentration

    - id: 8
      text: 动作或说话缓慢到别人可以察觉——或者相反，烦躁不安、走来走去比平常多
      domain: psychomotor

    - id: 9
      text: 有不如死掉或用某种方式伤害自己的念头
      domain: suicidal_ideation
      critical: true  # 关键安全题目

  # 额外功能损害题目（不计入总分）
  functional_item:
    text: |
      如果你勾选了上述任何一项问题，
      这些问题给你的工作、家务或与他人相处带来了多大困难？
    options:
      - 完全没有困难
      - 有些困难
      - 非常困难
      - 极度困难

  scoring:
    calculation: 将题目 1-9 的分数相加
    severity_levels:
      - range: [0, 4]
        level: 无抑郁或极轻微抑郁
        interpretation: |
          你目前没有明显的抑郁症状。
          继续保持健康的生活方式。
        recommendation: 无需特别干预

      - range: [5, 9]
        level: 轻度抑郁
        interpretation: |
          你可能正在经历一些轻微的抑郁症状。
          这在生活压力时期是常见的。
        recommendation: |
          - 自我监测，关注症状变化
          - 尝试运动、社交、规律作息
          - 如症状持续超过2周，考虑咨询专业人士

      - range: [10, 14]
        level: 中度抑郁
        interpretation: |
          你的抑郁症状已达到中度水平。
          这可能正在影响你的日常生活。
        recommendation: |
          - 建议寻求专业心理咨询
          - 考虑认知行为疗法
          - 与信任的人谈谈你的感受

      - range: [15, 19]
        level: 中重度抑郁
        interpretation: |
          你的抑郁症状比较严重。
          积极寻求专业帮助非常重要。
        recommendation: |
          - 强烈建议寻求专业治疗
          - 心理治疗结合必要的药物治疗
          - 告诉身边的人你需要支持

      - range: [20, 27]
        level: 重度抑郁
        interpretation: |
          你正在经历严重的抑郁症状。
          请尽快寻求专业帮助。
        recommendation: |
          - 请立即联系专业心理健康服务
          - 考虑精神科就诊
          - 确保有人陪伴和支持你

  safety_protocol:
    item_9_trigger:
      score_1:
        action: concerned_followup
        message: |
          我注意到你提到有时会有不想活或伤害自己的想法。
          我想确认一下你现在的安全。
          你现在有伤害自己的想法或计划吗？

      score_2_or_3:
        action: crisis_protocol
        message: |
          我非常担心你的安全。
          有这样的想法说明你正在承受很大的痛苦。

          请立即联系专业帮助：
          🆘 全国心理援助热线：400-161-9995（24小时）
          🆘 北京心理危机热线：010-82951332

          你现在安全吗？有人陪在你身边吗？
```

### 2.2 GAD-7 (广泛性焦虑障碍量表-7)

```yaml
gad7:
  metadata:
    name: 广泛性焦虑障碍量表-7
    name_en: Generalized Anxiety Disorder 7-item scale
    purpose: 筛查和评估焦虑症状严重程度
    items: 7
    recall_period: 过去两周
    time_to_complete: 2-3 分钟
    scoring_range: 0-21
    source: Spitzer et al., 2006

  introduction: |
    接下来我会问你一些关于焦虑感受的问题。
    请根据过去两周的实际感受选择最符合的选项。

  response_scale:
    0: 完全没有
    1: 有几天
    2: 一半以上时间
    3: 几乎每天

  items:
    - id: 1
      text: 感到紧张、焦虑或急切
      domain: nervous

    - id: 2
      text: 不能停止或控制担忧
      domain: uncontrollable_worry

    - id: 3
      text: 对各种各样的事情担忧过多
      domain: excessive_worry

    - id: 4
      text: 很难放松下来
      domain: relaxation

    - id: 5
      text: 由于不安而无法静坐
      domain: restlessness

    - id: 6
      text: 变得容易烦恼或急躁
      domain: irritability

    - id: 7
      text: 感到好像将有可怕的事情发生
      domain: dread

  scoring:
    calculation: 将题目 1-7 的分数相加
    severity_levels:
      - range: [0, 4]
        level: 极轻微焦虑
        interpretation: |
          你目前没有明显的焦虑症状。
        recommendation: 继续保持，关注压力管理

      - range: [5, 9]
        level: 轻度焦虑
        interpretation: |
          你可能正在经历一些轻微的焦虑。
          这在压力时期是常见的反应。
        recommendation: |
          - 尝试放松技巧（深呼吸、渐进性肌肉放松）
          - 规律运动有助于缓解焦虑
          - 减少咖啡因摄入

      - range: [10, 14]
        level: 中度焦虑
        interpretation: |
          你的焦虑症状已达到中度水平。
          这可能正在影响你的日常功能。
        recommendation: |
          - 建议寻求专业心理咨询
          - 认知行为疗法对焦虑非常有效
          - 学习焦虑管理技巧

      - range: [15, 21]
        level: 重度焦虑
        interpretation: |
          你正在经历严重的焦虑症状。
          请尽快寻求专业帮助。
        recommendation: |
          - 请联系专业心理健康服务
          - 可能需要综合治疗方案
          - 与家人朋友分享你的感受
```

### 2.3 DASS-21 (抑郁焦虑压力量表-21)

```yaml
dass21:
  metadata:
    name: 抑郁焦虑压力量表-21
    name_en: Depression Anxiety Stress Scales-21
    purpose: 同时评估抑郁、焦虑和压力三个维度
    items: 21
    subscales: 3
    recall_period: 过去一周
    time_to_complete: 5-7 分钟
    scoring_range: 0-63 (每个分量表 0-21，乘以 2)
    source: Lovibond & Lovibond, 1995

  introduction: |
    请阅读以下每项陈述，并选择一个数字来表示
    过去一周内该陈述对你适用的程度。
    没有对错之分，不要花太多时间在任何一项上。

  response_scale:
    0: 根本不适用于我
    1: 有时候适用于我
    2: 常常适用于我
    3: 总是适用于我

  items:
    # 抑郁分量表 (D)
    - id: 3
      text: 我好像不能再有任何好的感觉
      subscale: depression

    - id: 5
      text: 我发觉很难主动去做事
      subscale: depression

    - id: 10
      text: 我觉得没有什么可以期待
      subscale: depression

    - id: 13
      text: 我感到闷闷不乐、情绪低落
      subscale: depression

    - id: 16
      text: 我对任何事都提不起热情
      subscale: depression

    - id: 17
      text: 我觉得自己不怎么值得做人
      subscale: depression

    - id: 21
      text: 我觉得生活毫无意义
      subscale: depression

    # 焦虑分量表 (A)
    - id: 2
      text: 我感到口干
      subscale: anxiety

    - id: 4
      text: 我感到呼吸困难（例如，呼吸急促，但不是因为运动）
      subscale: anxiety

    - id: 7
      text: 我发觉手在发抖
      subscale: anxiety

    - id: 9
      text: 我担心自己会惊慌失措、出丑
      subscale: anxiety

    - id: 15
      text: 我感觉快要惊慌了
      subscale: anxiety

    - id: 19
      text: 我意识到自己心跳加速却没有运动（例如，心跳加快或心跳不规律）
      subscale: anxiety

    - id: 20
      text: 我无缘无故感到害怕
      subscale: anxiety

    # 压力分量表 (S)
    - id: 1
      text: 我发觉自己为小事而烦恼
      subscale: stress

    - id: 6
      text: 我反应过度
      subscale: stress

    - id: 8
      text: 我觉得自己消耗了很多精力
      subscale: stress

    - id: 11
      text: 我发觉自己变得激动
      subscale: stress

    - id: 12
      text: 我发觉自己很难放松
      subscale: stress

    - id: 14
      text: 我无法忍受任何阻碍我正在做的事情的因素
      subscale: stress

    - id: 18
      text: 我觉得自己相当敏感
      subscale: stress

  scoring:
    calculation: |
      分别计算三个分量表的原始分数，然后乘以 2。
      抑郁: 题目 3, 5, 10, 13, 16, 17, 21
      焦虑: 题目 2, 4, 7, 9, 15, 19, 20
      压力: 题目 1, 6, 8, 11, 12, 14, 18

    severity_levels:
      depression:
        - range: [0, 9]
          level: 正常
        - range: [10, 13]
          level: 轻度
        - range: [14, 20]
          level: 中度
        - range: [21, 27]
          level: 重度
        - range: [28, 42]
          level: 极重度

      anxiety:
        - range: [0, 7]
          level: 正常
        - range: [8, 9]
          level: 轻度
        - range: [10, 14]
          level: 中度
        - range: [15, 19]
          level: 重度
        - range: [20, 42]
          level: 极重度

      stress:
        - range: [0, 14]
          level: 正常
        - range: [15, 18]
          level: 轻度
        - range: [19, 25]
          level: 中度
        - range: [26, 33]
          level: 重度
        - range: [34, 42]
          level: 极重度
```

---

## 三、探索性工具设计

### 3.1 原型探索问卷

```yaml
archetype_inventory:
  metadata:
    name: 原型探索问卷
    purpose: 识别活跃的荣格原型
    items: 36 (每个原型 3 题)
    archetypes: 12
    time_to_complete: 10-15 分钟

  introduction: |
    这份问卷将帮助你发现哪些原型能量在你的生活中最活跃。
    请根据直觉选择，不要过度思考。

  response_scale:
    1: 完全不像我
    2: 不太像我
    3: 有点像我
    4: 比较像我
    5: 非常像我

  items:
    innocent:
      - text: 我相信事情最终会好起来
      - text: 我喜欢简单、纯粹的生活
      - text: 我对人通常持信任态度

    explorer:
      - text: 我渴望新的体验和冒险
      - text: 我不喜欢被规则和惯例束缚
      - text: 我经常想要探索未知的领域

    sage:
      - text: 我喜欢深入思考复杂的问题
      - text: 学习新知识让我感到满足
      - text: 我相信智慧能解决大多数问题

    hero:
      - text: 面对挑战时我会迎难而上
      - text: 我愿意为保护他人而战
      - text: 我相信勇气和毅力能克服困难

    outlaw:
      - text: 我质疑传统规则和权威
      - text: 我有时想要打破现状
      - text: 我讨厌不公正的制度

    magician:
      - text: 我相信转化和改变是可能的
      - text: 我对神秘和灵性感兴趣
      - text: 我喜欢帮助他人实现梦想

    regular_guy:
      - text: 我珍视归属感和被接纳
      - text: 我喜欢和普通人在一起
      - text: 我相信每个人都是平等的

    lover:
      - text: 我重视亲密关系和连接
      - text: 我对美和感官体验敏感
      - text: 我愿意为所爱的人付出一切

    jester:
      - text: 我喜欢用幽默让人开心
      - text: 我相信生活应该是有趣的
      - text: 我不太把事情当回事

    caregiver:
      - text: 照顾他人让我感到满足
      - text: 我经常把别人的需求放在自己之前
      - text: 我想让世界变得更温暖

    ruler:
      - text: 我喜欢掌控局面
      - text: 我有领导他人的倾向
      - text: 我相信有序和稳定很重要

    creator:
      - text: 我喜欢创造新事物
      - text: 表达想法和愿景对我很重要
      - text: 我有时会沉浸在创作中忘记时间

  scoring:
    calculation: 每个原型取三道题目的平均分
    output:
      primary: 得分最高的原型
      secondary: 得分第二和第三高的原型
      shadow: 得分最低的原型（可能代表阴影）

  interpretation_template: |
    **你的主要原型：{primary_archetype}**

    {archetype_description}

    **这意味着你可能：**
    {strengths}

    **需要注意的阴影面：**
    {shadow_aspects}

    **你的次要原型（{secondary_1}, {secondary_2}）**
    这些原型也在你的生活中发挥作用...

    **潜在的成长方向：**
    你的阴影原型 {shadow_archetype} 可能包含
    你尚未开发的资源...
```

### 3.2 生活风格评估表

```yaml
lifestyle_assessment:
  metadata:
    name: 生活风格评估
    purpose: 探索阿德勒生活风格
    sections: 4
    time_to_complete: 20-30 分钟

  sections:

    family_constellation:
      name: 家庭星座
      questions:
        birth_order:
          - 你在家中排行第几？
          - 你和最近的兄弟姐妹年龄差多少？
          - 如果是独生子女，你对此有什么感受？

        siblings:
          prompt: |
            请描述你的每个兄弟姐妹（包括年龄、性格、与你的关系）。
            如果是独生子女，描述你童年时最亲近的同龄人。
          follow_up:
            - 你和谁最亲近？为什么？
            - 你和谁竞争最多？
            - 谁是父母的"最爱"？

        parents:
          prompt: |
            用几个词描述你的父亲/母亲（或主要抚养者）。
          follow_up:
            - 你更像谁？
            - 你希望像谁？不希望像谁？
            - 他们对你的期望是什么？

        family_atmosphere:
          - 你会用什么词描述你家的氛围？
          - 家里谁做决定？
          - 冲突通常如何解决？

    early_recollections:
      name: 早期记忆
      instructions: |
        请回忆 8 岁之前的三个清晰记忆。
        它们不需要是重大事件，任何你记得的都可以。
      for_each_memory:
        - 尽可能详细地描述发生了什么，像讲故事一样
        - 记忆中最生动、最清晰的一刻是什么？
        - 那一刻你的感受是什么？
        - 记忆中的其他人在做什么？

      analysis_framework:
        themes:
          - 你在这些记忆中是主动的还是被动的？
          - 其他人是支持的、威胁的、还是无关的？
          - 你的情绪体验主要是什么？
          - 这些记忆中有什么共同主题？

    life_tasks:
      name: 人生任务
      tasks:
        work:
          satisfaction: 对工作/学业的满意度 (1-10)
          challenges: 工作中最大的挑战是什么？
          meaning: 你觉得自己在做有意义的贡献吗？

        social:
          satisfaction: 对社交生活的满意度 (1-10)
          friends: 你有多少亲密朋友？
          belonging: 你觉得自己属于某个群体吗？

        love:
          satisfaction: 对亲密关系的满意度 (1-10)
          patterns: 在关系中你通常有什么模式？
          concerns: 关系中最常担心什么？

    core_beliefs:
      name: 核心信念探索
      prompts:
        self_view:
          prompt: "我是一个______的人"
          follow_up: 这个信念来自哪里？

        world_view:
          prompt: "这个世界是______的"
          follow_up: 什么经历让你形成这个看法？

        others_view:
          prompt: "其他人通常是______的"
          follow_up: 这影响你如何与人互动？

        life_motto:
          prompt: 如果用一句话总结你的人生哲学，会是什么？
```

### 3.3 阴影工作评估

```yaml
shadow_assessment:
  metadata:
    name: 阴影探索问卷
    purpose: 识别阴影内容
    sections: 4
    time_to_complete: 15-20 分钟

  sections:

    projection_identification:
      name: 投射识别
      instructions: |
        想三个你强烈反感的人或公众人物。
        对于每个人：
      questions:
        - 你最讨厌他们什么特质？
        - 当他们表现出这个特质时，你有什么情绪反应？
        - 这个特质是否可能以任何形式存在于你自己身上？

    trigger_mapping:
      name: 触发点地图
      instructions: |
        回想最近让你情绪强烈反应的情境。
      questions:
        - 发生了什么？
        - 你的情绪反应是什么？强度如何（1-10）？
        - 这种反应是否与情境的严重程度相称？
        - 这种反应让你想起过去的什么？

    repressed_desires:
      name: 压抑的渴望
      instructions: |
        诚实回答以下问题（无人会看到你的答案）：
      questions:
        - 你有时希望自己可以做但觉得"不应该"做的事是什么？
        - 如果没人会知道或评判，你会做什么不同的事？
        - 你小时候被告知"不能"或"不应该"做的事是什么？

    golden_shadow:
      name: 金色阴影
      instructions: |
        想三个你非常崇拜的人。
      questions:
        - 你最欣赏他们什么特质？
        - 你是否相信自己也可以拥有这些特质？
        - 是什么阻止你表达这些特质？
```

---

## 四、工具执行器设计

### 4.1 评估计算执行器

```python
# handlers.py 示例结构

from services.agent.tool_registry import tool_handler
from typing import Dict
from .services.calculator import (
    calculate_phq9_score,
    calculate_gad7_score,
    calculate_dass21_score,
    interpret_severity
)

@tool_handler("calculate_assessment_score")
async def execute_calculate_assessment(args: Dict, context: ToolContext) -> Dict:
    """
    计算心理评估量表得分

    返回：
    - total_score: 总分
    - severity_level: 严重程度
    - subscales: 分量表得分（如 DASS-21）
    - interpretation: 解读
    - recommendations: 建议
    - safety_flag: 安全标记（如 PHQ-9 第 9 题）
    """
    assessment_type = args.get("assessment_type")
    responses = args.get("responses")

    if assessment_type == "phq9":
        result = calculate_phq9_score(responses)
        # 检查第 9 题（自杀意念）
        if responses[8] >= 1:
            result["safety_flag"] = "suicidal_ideation"
            result["safety_score"] = responses[8]

    elif assessment_type == "gad7":
        result = calculate_gad7_score(responses)

    elif assessment_type == "dass21":
        result = calculate_dass21_score(responses)

    # 添加解读和建议
    result["interpretation"] = interpret_severity(
        assessment_type,
        result["severity_level"]
    )

    return {
        "status": "success",
        "card_type": "assessment_result",
        "data": result
    }


@tool_handler("identify_cognitive_distortions")
async def execute_identify_distortions(args: Dict, context: ToolContext) -> Dict:
    """
    识别认知扭曲类型

    使用 LLM 能力分析用户的自动化思维，
    识别可能存在的认知扭曲。
    """
    thought = args.get("thought")

    # 这里依赖 LLM 的分析能力
    # 返回结构化的分析结果供 LLM 进一步处理

    return {
        "status": "success",
        "card_type": "distortion_analysis",
        "data": {
            "original_thought": thought,
            "analysis_prompt": f"""
请分析这个想法中可能存在的认知扭曲：
"{thought}"

可能的认知扭曲类型：
- 全或无思维
- 灾难化
- 读心术
- 算命
- "应该"陈述
- 贴标签
- 情绪推理
- 心理过滤
- 否定积极
- 个人化
- 责备

对于每个识别出的扭曲：
1. 指出是哪种类型
2. 解释为什么这是扭曲
3. 提供挑战问题
4. 给出可能的重构想法
"""
        }
    }


@tool_handler("show_crisis_resources")
async def execute_show_crisis(args: Dict, context: ToolContext) -> Dict:
    """
    展示危机资源

    当检测到危机信号时调用
    """
    return {
        "status": "success",
        "card_type": "crisis_alert",
        "data": {
            "message": args.get("message", "我很担心你的安全。请联系专业帮助。"),
            "hotlines": [
                {
                    "name": "全国心理援助热线",
                    "number": "400-161-9995",
                    "hours": "24小时"
                },
                {
                    "name": "北京心理危机研究与干预中心",
                    "number": "010-82951332",
                    "hours": "24小时"
                },
                {
                    "name": "生命热线",
                    "number": "400-821-1215",
                    "hours": "24小时"
                }
            ],
            "immediate_steps": [
                "如果你有伤害自己的工具，请先把它们放到安全的地方",
                "联系你信任的人，告诉他们你的感受",
                "拨打上面的热线，专业人员可以帮助你"
            ]
        },
        "priority": "high"
    }
```

---

## 五、卡片组件设计

### 5.1 评估结果卡片

```typescript
// AssessmentResultCard.tsx

interface AssessmentResultCardProps {
  data: {
    assessment_type: 'phq9' | 'gad7' | 'dass21';
    total_score: number;
    severity_level: string;
    subscales?: {
      depression?: number;
      anxiety?: number;
      stress?: number;
    };
    interpretation: string;
    recommendations: string[];
    safety_flag?: string;
  };
}

export function AssessmentResultCard({ data }: AssessmentResultCardProps) {
  const getSeverityColor = (level: string) => {
    switch (level) {
      case '正常': case '极轻微': return 'green';
      case '轻度': return 'yellow';
      case '中度': return 'orange';
      case '重度': case '中重度': return 'red';
      case '极重度': return 'darkred';
      default: return 'gray';
    }
  };

  return (
    <Card className="assessment-result">
      <CardHeader>
        <h3>{getAssessmentName(data.assessment_type)} 结果</h3>
      </CardHeader>

      <CardBody>
        {/* 分数显示 */}
        <ScoreDisplay
          score={data.total_score}
          maxScore={getMaxScore(data.assessment_type)}
          color={getSeverityColor(data.severity_level)}
        />

        {/* 严重程度标签 */}
        <SeverityBadge
          level={data.severity_level}
          color={getSeverityColor(data.severity_level)}
        />

        {/* DASS-21 分量表 */}
        {data.subscales && (
          <SubscalesChart
            depression={data.subscales.depression}
            anxiety={data.subscales.anxiety}
            stress={data.subscales.stress}
          />
        )}

        {/* 解读 */}
        <Interpretation text={data.interpretation} />

        {/* 建议 */}
        <Recommendations items={data.recommendations} />

        {/* 安全提醒（如果有） */}
        {data.safety_flag && (
          <SafetyAlert flag={data.safety_flag} />
        )}
      </CardBody>
    </Card>
  );
}
```

### 5.2 原型特征卡片

```typescript
// ArchetypeProfileCard.tsx

interface ArchetypeProfileCardProps {
  data: {
    primary_archetype: string;
    secondary_archetypes: string[];
    shadow_archetype: string;
    description: string;
    strengths: string[];
    shadow_aspects: string[];
    growth_suggestions: string[];
  };
}

export function ArchetypeProfileCard({ data }: ArchetypeProfileCardProps) {
  const archetypeIcons = {
    innocent: '🕊️',
    explorer: '🧭',
    sage: '📚',
    hero: '⚔️',
    outlaw: '🔥',
    magician: '✨',
    regular_guy: '🤝',
    lover: '❤️',
    jester: '🎭',
    caregiver: '🌸',
    ruler: '👑',
    creator: '🎨'
  };

  return (
    <Card className="archetype-profile">
      <CardHeader>
        <span className="archetype-icon">
          {archetypeIcons[data.primary_archetype]}
        </span>
        <h3>你的主要原型：{data.primary_archetype}</h3>
      </CardHeader>

      <CardBody>
        <Description text={data.description} />

        <Section title="你的优势">
          <List items={data.strengths} />
        </Section>

        <Section title="需要注意的阴影面">
          <List items={data.shadow_aspects} />
        </Section>

        <Section title="次要原型">
          <ArchetypeChips archetypes={data.secondary_archetypes} />
        </Section>

        <Section title="成长方向">
          <GrowthSuggestions
            shadow={data.shadow_archetype}
            suggestions={data.growth_suggestions}
          />
        </Section>
      </CardBody>
    </Card>
  );
}
```

### 5.3 认知扭曲分析卡片

```typescript
// DistortionAnalysisCard.tsx

interface DistortionAnalysisCardProps {
  data: {
    original_thought: string;
    distortion_types: Array<{
      type: string;
      explanation: string;
    }>;
    challenge_questions: string[];
    reframed_thought: string;
  };
}

export function DistortionAnalysisCard({ data }: DistortionAnalysisCardProps) {
  return (
    <Card className="distortion-analysis">
      <CardHeader>
        <h3>认知分析</h3>
      </CardHeader>

      <CardBody>
        {/* 原始想法 */}
        <Section title="原始想法">
          <Quote text={data.original_thought} />
        </Section>

        {/* 识别的扭曲 */}
        <Section title="可能的认知扭曲">
          {data.distortion_types.map((distortion, idx) => (
            <DistortionBadge
              key={idx}
              type={distortion.type}
              explanation={distortion.explanation}
            />
          ))}
        </Section>

        {/* 挑战问题 */}
        <Section title="思考这些问题">
          <QuestionList questions={data.challenge_questions} />
        </Section>

        {/* 重构想法 */}
        <Section title="可能的平衡想法">
          <HighlightedText text={data.reframed_thought} />
        </Section>
      </CardBody>
    </Card>
  );
}
```

---

## 六、数据存储设计

### 6.1 skill_data 结构

```yaml
# 存储在 unified_profiles.profile.skill_data.psych

psych:
  assessments:
    history:
      - date: "2026-01-15"
        type: phq9
        score: 8
        severity: 轻度抑郁

      - date: "2026-01-15"
        type: gad7
        score: 6
        severity: 轻度焦虑

    latest:
      phq9:
        date: "2026-01-15"
        score: 8
        severity: 轻度抑郁

      gad7:
        date: "2026-01-15"
        score: 6
        severity: 轻度焦虑

  exploration:
    archetypes:
      primary: hero
      secondary: [sage, creator]
      shadow: lover
      assessed_date: "2026-01-10"

    lifestyle:
      birth_order: firstborn
      lifestyle_type: socially_useful
      core_beliefs:
        self: "我需要证明自己的价值"
        world: "世界是竞争的"
        others: "他人是潜在的评判者"

    shadow_work:
      identified_projections:
        - "懒惰 - 投射到同事身上"
        - "依赖 - 投射到伴侣身上"
      integration_progress: []

  practices:
    completed_exercises:
      - name: 投射日记
        completed_date: "2026-01-12"
        reflections: "..."

    active_reminders:
      - type: mood_check
        frequency: daily
        time: "21:00"

    tracking:
      mood_logs:
        - date: "2026-01-15"
          mood: 6
          notes: "工作压力大但有进展"
```

### 6.2 评估历史追踪

```python
# 评估历史存储和趋势分析

async def save_assessment_result(
    user_id: UUID,
    assessment_type: str,
    score: int,
    severity: str,
    responses: List[int]
) -> None:
    """保存评估结果到历史记录"""

    await UnifiedProfileRepository.update_skill_data(
        user_id,
        "psych",
        {
            f"assessments.latest.{assessment_type}": {
                "date": datetime.now().isoformat(),
                "score": score,
                "severity": severity
            },
            # 追加到历史
            "assessments.history": {
                "$push": {
                    "date": datetime.now().isoformat(),
                    "type": assessment_type,
                    "score": score,
                    "severity": severity
                }
            }
        }
    )


async def get_assessment_trend(
    user_id: UUID,
    assessment_type: str,
    period_days: int = 30
) -> List[Dict]:
    """获取评估分数趋势"""

    psych_data = await UnifiedProfileRepository.get_skill_data(user_id, "psych")
    history = psych_data.get("assessments", {}).get("history", [])

    # 过滤指定类型和时间范围的记录
    cutoff_date = datetime.now() - timedelta(days=period_days)
    filtered = [
        record for record in history
        if record["type"] == assessment_type
        and datetime.fromisoformat(record["date"]) > cutoff_date
    ]

    return sorted(filtered, key=lambda x: x["date"])
```

---

## 七、推送与提醒设计

### 7.1 reminders.yaml

```yaml
# reminders.yaml - Psych Skill 的主动推送配置

reminders:

  # 每日情绪检查
  - id: daily_mood_check
    trigger:
      type: time_based
      schedule: "0 21 * * *"  # 每天晚上 9 点
    content:
      generator: |
        今天过得怎么样？
        花一分钟时间，给今天的心情打个分（1-10）。
      card_type: mood_check_form
    user_preference:
      setting_path: preferences.psych.daily_mood_check
      default: false

  # 每周心理健康简报
  - id: weekly_mental_health_summary
    trigger:
      type: time_based
      schedule: "0 10 * * 0"  # 每周日上午 10 点
    content:
      generator: rules/weekly-summary.md
      card_type: weekly_summary
    user_preference:
      setting_path: preferences.psych.weekly_summary
      default: true

  # 评估提醒（上次评估后 30 天）
  - id: assessment_reminder
    trigger:
      type: time_based
      condition: |
        last_assessment_date + 30 days < today
    content:
      message: |
        距离上次心理健康评估已经过去一个月了。
        想做个快速检查吗？只需要 3 分钟。
      action: start_phq2_gad2
    user_preference:
      setting_path: preferences.psych.assessment_reminder
      default: true

  # 基于情绪的关怀推送
  - id: low_mood_followup
    trigger:
      type: emotion_based
      condition: |
        mood_log[-1].score <= 3 OR
        mood_log[-3:].average <= 4
    content:
      generator: rules/low-mood-support.md
      card_type: support_message
    cooldown: 24h

  # 评估高分后的跟进
  - id: high_score_followup
    trigger:
      type: event_based
      event: assessment_completed
      condition: |
        (assessment_type == 'phq9' AND score >= 10) OR
        (assessment_type == 'gad7' AND score >= 10)
    content:
      message: |
        我想跟你聊聊上次评估的结果。
        你最近还好吗？有什么我可以帮助的吗？
    delay: 48h  # 评估后 48 小时跟进
```

---

这份工具与评估设计文档定义了 Psych Skill 的：

1. **完整工具系统** - 计算、收集、展示、搜索、操作五类工具
2. **三大临床量表** - PHQ-9、GAD-7、DASS-21 的完整设计
3. **探索性问卷** - 原型、生活风格、阴影工作评估
4. **执行器实现** - Python 代码结构示例
5. **前端卡片** - TypeScript 组件设计
6. **数据存储** - skill_data 结构设计
7. **推送系统** - 主动关怀和提醒机制
