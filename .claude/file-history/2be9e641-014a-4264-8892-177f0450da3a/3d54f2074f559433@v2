# Psych Skill 知识库架构

> **Version**: 1.0.0
> **Purpose**: 定义心理学知识库的结构、内容和检索策略

---

## 一、知识库总体架构

```
psych_knowledge_base/
│
├── theories/                      # 理论基础
│   ├── jungian/                   # 荣格分析心理学
│   │   ├── archetypes.md          # 原型理论
│   │   ├── shadow.md              # 阴影概念
│   │   ├── individuation.md       # 个体化进程
│   │   ├── persona.md             # 人格面具
│   │   ├── anima_animus.md        # 内在异性
│   │   ├── collective_unconscious.md  # 集体无意识
│   │   └── dream_analysis.md      # 梦境分析
│   │
│   ├── adlerian/                  # 阿德勒个体心理学
│   │   ├── lifestyle.md           # 生活风格
│   │   ├── birth_order.md         # 出生顺序
│   │   ├── social_interest.md     # 社会兴趣
│   │   ├── inferiority.md         # 自卑与补偿
│   │   ├── striving_superiority.md # 优越追求
│   │   ├── early_recollections.md # 早期记忆
│   │   ├── family_constellation.md # 家庭星座
│   │   └── life_tasks.md          # 人生任务
│   │
│   └── cbt/                       # 认知行为疗法
│       ├── cognitive_model.md     # 认知模型
│       ├── distortions.md         # 认知扭曲
│       ├── restructuring.md       # 认知重构
│       ├── behavioral_activation.md # 行为激活
│       └── exposure.md            # 暴露疗法
│
├── assessments/                   # 评估工具
│   ├── clinical/                  # 临床量表
│   │   ├── phq9.md                # 患者健康问卷-9
│   │   ├── gad7.md                # 广泛性焦虑障碍-7
│   │   ├── dass21.md              # 抑郁焦虑压力量表-21
│   │   └── pcl5.md                # PTSD 检查表-5
│   │
│   ├── personality/               # 人格评估
│   │   ├── big_five.md            # 大五人格
│   │   ├── jungian_types.md       # 荣格类型
│   │   └── personality_priorities.md # 阿德勒人格优先级
│   │
│   └── exploration/               # 探索性问卷
│       ├── shadow_work.md         # 阴影工作问卷
│       ├── lifestyle_assessment.md # 生活风格评估
│       └── archetype_inventory.md # 原型清单
│
├── exercises/                     # 练习库
│   ├── shadow_work/               # 阴影工作
│   ├── cognitive_restructuring/   # 认知重构
│   ├── journaling/                # 日记提示
│   ├── meditation/                # 冥想脚本
│   └── behavioral/                # 行为练习
│
├── psychoeducation/               # 心理教育
│   ├── emotions/                  # 情绪教育
│   ├── stress/                    # 压力管理
│   ├── relationships/             # 关系心理学
│   ├── trauma/                    # 创伤知识
│   └── self_care/                 # 自我关怀
│
└── crisis/                        # 危机资源
    ├── safety_plans.md            # 安全计划模板
    ├── hotlines.md                # 危机热线
    └── referral_guides.md         # 转介指南
```

---

## 二、荣格分析心理学知识库

### 2.1 原型理论 (`theories/jungian/archetypes.md`)

```yaml
archetype_knowledge:

  concept_definition:
    name: 原型 (Archetype)
    origin: 荣格 (Carl Jung)
    definition: |
      原型是存在于集体无意识中的普遍心理模式，
      是人类共同经验的心理沉淀。
      它们通过神话、宗教、梦境和艺术表现出来。

  primary_archetypes:

    self:
      name: 自性 (The Self)
      description: |
        自性是人格整合的中心和完整性的原型。
        它代表有意识和无意识的统一，
        是个体化进程的最终目标。
      symbols:
        - 曼陀罗 (Mandala)
        - 神圣婚姻 (Sacred Marriage)
        - 完美圆圈
        - 宝石或珍珠
      manifestations:
        positive: 整合、智慧、内在和平
        negative: 膨胀、自恋、脱离现实
      reflection_questions:
        - 你生命中什么时候感到最完整？
        - 你内心深处真正渴望成为什么样的人？
        - 什么能让你感到与更大的意义相连？

    shadow:
      name: 阴影 (The Shadow)
      description: |
        阴影包含我们压抑的、不接受的人格面向。
        这些特质不一定是负面的，
        只是我们选择不认同或隐藏的部分。
      symbols:
        - 黑暗
        - 怪物
        - 敌人
        - 镜中阴暗面
      manifestations:
        unintegrated:
          - 投射到他人身上
          - 对某些人或特质强烈反感
          - 自我破坏行为
          - 羞耻和内疚
        integrated:
          - 自我接纳增加
          - 创造力释放
          - 真实性增强
          - 对他人更宽容
      reflection_questions:
        - 你最不愿意让别人看到的自己是什么样子？
        - 你在别人身上最讨厌的特质是什么？
        - 你曾经做过什么让自己感到羞耻的事？

    persona:
      name: 人格面具 (The Persona)
      description: |
        人格面具是我们呈现给社会的外在形象，
        是适应社会期望而形成的"面具"。
        它是必要的，但过度认同会失去真实自我。
      symbols:
        - 面具
        - 服装
        - 角色
        - 舞台表演
      healthy_function: |
        - 保护内心的脆弱
        - 社会适应
        - 职业角色履行
      pathological_function: |
        - 过度认同角色
        - 失去真实自我
        - 内外不一致的痛苦
      reflection_questions:
        - 你在不同场合会呈现不同的"自己"吗？
        - 哪个"你"最接近真实的你？
        - 如果摘下所有面具，别人会看到什么？

    anima:
      name: 阿尼玛 (The Anima)
      description: |
        男性心理中的女性原型，
        代表与情感、创造力、灵魂的连接。
        它是男性无意识中的女性形象。
      developmental_stages:
        - name: 夏娃 (Eve)
          description: 本能、生物层面的女性
        - name: 海伦 (Helen)
          description: 浪漫、美学的女性
        - name: 玛利亚 (Mary)
          description: 精神、养育的女性
        - name: 索菲亚 (Sophia)
          description: 智慧、超越的女性
      reflection_questions:
        - 你对"女性气质"有什么看法？
        - 你与情感和直觉的关系如何？
        - 梦中出现的女性形象通常是怎样的？

    animus:
      name: 阿尼姆斯 (The Animus)
      description: |
        女性心理中的男性原型，
        代表逻辑、行动力、意志。
        它是女性无意识中的男性形象。
      developmental_stages:
        - name: 力量男 (Man of Mere Physical Power)
          description: 运动员、泰山
        - name: 浪漫男 (Man of Action/Romance)
          description: 战士、诗人
        - name: 知识男 (Man of the Word)
          description: 教授、演说家
        - name: 智慧男 (Man of Meaning)
          description: 灵性导师、哲人
      reflection_questions:
        - 你对"男性气质"有什么看法？
        - 你与逻辑和行动力的关系如何？
        - 梦中出现的男性形象通常是怎样的？

  character_archetypes:
    # 基于 Carol Pearson 的十二原型模型

    innocent:
      name: 天真者 (The Innocent)
      core_desire: 体验天堂
      goal: 快乐
      fear: 受罚、做错事
      strategy: 做正确的事
      gift: 信仰和乐观
      shadow: 否认、压抑

    explorer:
      name: 探险家 (The Explorer)
      core_desire: 发现真实自我的自由
      goal: 体验更好、更真实、更充实的生活
      fear: 被困住、空虚、不真实
      strategy: 旅行、寻求、逃离无聊
      gift: 自主、抱负、忠于灵魂
      shadow: 漫无目的、不适应

    sage:
      name: 智者 (The Sage)
      core_desire: 发现真理
      goal: 使用智慧理解世界
      fear: 被欺骗、无知
      strategy: 寻求信息和知识
      gift: 智慧、洞察
      shadow: 批判、脱离实际

    hero:
      name: 英雄 (The Hero)
      core_desire: 通过勇敢行动证明价值
      goal: 专业精通，改善世界
      fear: 软弱、脆弱、成为懦夫
      strategy: 尽可能强大和有能力
      gift: 勇气、能力
      shadow: 傲慢、永远需要敌人

    outlaw:
      name: 反叛者 (The Outlaw)
      core_desire: 复仇或革命
      goal: 摧毁不起作用的东西
      fear: 无力、无足轻重
      strategy: 破坏、颠覆、冲击
      gift: 激进的自由
      shadow: 越界、犯罪

    magician:
      name: 魔术师 (The Magician)
      core_desire: 了解宇宙的基本法则
      goal: 让梦想成真
      fear: 意外的负面后果
      strategy: 开发愿景并实现
      gift: 找到双赢解决方案
      shadow: 操纵

    regular_guy:
      name: 普通人 (The Regular Guy/Gal)
      core_desire: 与他人建立联系
      goal: 归属感
      fear: 被排斥、独自突出
      strategy: 发展普通的美德、融入
      gift: 现实主义、同理心、缺乏虚伪
      shadow: 失去自我、愤世嫉俗

    lover:
      name: 情人 (The Lover)
      core_desire: 亲密和体验
      goal: 与人、工作、环境建立关系
      fear: 孤独、不被爱、不受欢迎
      strategy: 在身体和情感上变得有吸引力
      gift: 激情、感激、欣赏
      shadow: 为取悦他人失去身份

    jester:
      name: 小丑 (The Jester)
      core_desire: 活在当下，充满乐趣
      goal: 玩乐、让世界更明亮
      fear: 无聊或无趣
      strategy: 玩耍、开玩笑、搞笑
      gift: 快乐
      shadow: 浪费生命、残忍

    caregiver:
      name: 照顾者 (The Caregiver)
      core_desire: 保护和照顾他人
      goal: 帮助他人
      fear: 自私和忘恩负义
      strategy: 为他人做事
      gift: 慷慨、同情心
      shadow: 殉道、操控

    ruler:
      name: 统治者 (The Ruler)
      core_desire: 控制
      goal: 创建繁荣、成功的家庭或社区
      fear: 混乱、被推翻
      strategy: 行使权力
      gift: 责任、领导力
      shadow: 独裁、无法授权

    creator:
      name: 创造者 (The Creator)
      core_desire: 创造持久价值
      goal: 实现愿景
      fear: 平庸、缺乏想象力
      strategy: 发展艺术控制和技能
      gift: 创造力、想象力
      shadow: 完美主义、创造力阻塞

  archetype_discovery_process:
    step_1:
      name: 认知学习
      action: 阅读各原型描述，初步自我识别

    step_2:
      name: 故事共鸣
      action: |
        回忆你最喜欢的神话/电影/小说人物
        识别哪些角色让你深度共鸣

    step_3:
      name: 阴影识别
      action: |
        识别你强烈反感的角色类型
        探索其可能代表你压抑的什么面向

    step_4:
      name: 梦境分析
      action: |
        记录梦中反复出现的角色
        分析其原型特征

    step_5:
      name: 整合实践
      action: |
        有意识地与不同原型能量工作
        在日常生活中练习原型表达
```

### 2.2 阴影工作 (`theories/jungian/shadow.md`)

```yaml
shadow_work_knowledge:

  definition:
    concept: |
      阴影是人格中我们不想成为的那个部分。
      它包含所有被压抑的特质——
      既有破坏性的，也有创造性的。

    jung_quote: |
      "除非你让无意识变得有意识，
       否则它会指导你的生活，
       而你会称之为命运。"

  shadow_formation:
    childhood:
      description: |
        阴影主要在童年形成。
        当某些特质被父母/社会否定时，
        我们学会压抑它们以维持爱和归属。
      example: |
        - 被告知"男孩不能哭"→ 压抑脆弱性
        - 被告知"好女孩要温顺"→ 压抑攻击性
        - 因愤怒被惩罚 → 压抑愤怒

    cultural:
      description: |
        文化和社会规范也塑造集体阴影。
        某些特质在特定文化中被集体压抑。

  shadow_manifestations:

    projection:
      name: 投射
      description: |
        当我们对某人有强烈的负面反应时，
        往往是因为他们展现了我们压抑的特质。
      example: |
        对懒惰的人极度愤怒 →
        可能自己内心也有懒惰的渴望但压抑了
      exercise: |
        列出三个你极度讨厌的人的特质。
        问自己：这些特质是否也存在于我身上，
        只是以不同方式表现？

    self_sabotage:
      name: 自我破坏
      description: |
        阴影会通过破坏我们的目标来表达自己，
        尤其当我们过度压抑某些需求时。
      example: |
        工作狂每到关键时刻就生病 →
        被压抑的休息需求在表达

    dreams:
      name: 梦境
      description: |
        阴影经常通过梦中的威胁形象出现。
        追逐者、怪物、敌人都可能是阴影投射。
      interpretation: |
        梦中的威胁形象是什么？
        如果它能说话，会说什么？
        它代表你的什么面向？

    slips:
      name: 口误和行为失误
      description: |
        弗洛伊德式口误往往泄露阴影内容。
      example: |
        "我很高兴...我是说很遗憾你离开"

  shadow_integration_process:

    stage_1_awareness:
      name: 觉察
      description: 首先需要意识到阴影的存在
      techniques:
        - 投射觉察练习
        - 触发点日记
        - 梦境记录
      questions:
        - 什么人或特质最能激起你的负面反应？
        - 你最害怕别人发现你什么？
        - 你梦中的敌人或追逐者是什么样子？

    stage_2_confrontation:
      name: 面对
      description: 直面阴影，而不是逃避或否认
      techniques:
        - 主动想象对话
        - 艺术表达
        - 治疗性写作
      questions:
        - 如果你的阴影有声音，它会说什么？
        - 它想要什么？需要什么？
        - 它在保护你什么？

    stage_3_acceptance:
      name: 接纳
      description: 认识到阴影是自己的一部分
      key_insight: |
        阴影不是敌人，而是被流放的盟友。
        它包含的能量可以被积极利用。
      questions:
        - 你能对这个面向的自己说"我接纳你"吗？
        - 这个"暗面"曾经如何保护过你？
        - 如果整合了这个特质，你会获得什么？

    stage_4_integration:
      name: 整合
      description: 将阴影能量转化为有意识的资源
      techniques:
        - 创造性表达
        - 建设性使用"负面"特质
        - 行为实验
      example: |
        压抑的攻击性 → 转化为边界设定能力
        压抑的自私 → 转化为健康的自我关怀
        压抑的脆弱 → 转化为深度连接能力

  shadow_work_exercises:

    exercise_1_projection_journal:
      name: 投射日记
      duration: 持续练习
      instructions: |
        1. 每天记录让你强烈反感的人或情境
        2. 描述具体触发你的特质或行为
        3. 问自己：这个特质如何存在于我身上？
        4. 写下你的发现，无需评判

    exercise_2_dialog_with_shadow:
      name: 与阴影对话
      duration: 20-30 分钟
      instructions: |
        1. 找一个安静的地方，放松身体
        2. 想象你的阴影以某种形象出现
           （可以是人、动物或抽象形象）
        3. 开始对话：
           - 你：你是谁？
           - 阴影：...
           - 你：你想要什么？
           - 阴影：...
           - 你：你在保护我什么？
           - 阴影：...
        4. 写下对话内容
        5. 反思对话中的洞察

    exercise_3_shadow_art:
      name: 阴影艺术
      duration: 30-60 分钟
      instructions: |
        1. 准备绘画材料（无需艺术技能）
        2. 闭眼感受你的阴影
        3. 用颜色、线条、形状表达它
        4. 不要思考，让手自然移动
        5. 完成后观察并写下感受

    exercise_4_golden_shadow:
      name: 金色阴影探索
      duration: 15 分钟
      description: |
        金色阴影是我们压抑的正面特质——
        那些我们崇拜他人拥有，
        却不相信自己也有的特质。
      instructions: |
        1. 列出三个你极度崇拜的人
        2. 写下你崇拜他们什么特质
        3. 问自己：这些特质是否也在我身上，
           只是被我压抑或低估了？
        4. 设计一个小实验来表达这些特质
```

---

## 三、阿德勒个体心理学知识库

### 3.1 生活风格 (`theories/adlerian/lifestyle.md`)

```yaml
lifestyle_knowledge:

  definition:
    concept: |
      生活风格（Lifestyle）是个体独特的生活方式，
      包括对自我、他人和世界的基本信念，
      以及由此产生的行为模式。

    adler_quote: |
      "重要的不是一个人生来如何，
       而是他如何使用自己所拥有的。"

  core_beliefs:
    self_concept:
      name: 自我概念
      question: "我是怎样的人？"
      examples:
        positive: "我是有能力的" / "我值得被爱"
        negative: "我不够好" / "我是个失败者"

    world_view:
      name: 世界观
      question: "这个世界是怎样的？"
      examples:
        positive: "世界是安全的" / "人们通常是善意的"
        negative: "世界是危险的" / "不能相信任何人"

    ethical_convictions:
      name: 伦理信念
      question: "我应该如何行动？"
      examples:
        healthy: "我应该贡献社会" / "合作比竞争更重要"
        unhealthy: "只有赢了才有价值" / "照顾自己最重要"

  lifestyle_assessment:

    family_constellation:
      name: 家庭星座
      description: |
        家庭星座描述一个人在原生家庭中的位置，
        包括出生顺序、兄弟姐妹关系、
        与父母的关系等。
      questions:
        - 你在家中排行第几？
        - 描述你的每个兄弟姐妹的性格
        - 谁是父母的最爱？为什么？
        - 你在家庭中扮演什么角色？
        - 你和哪个家庭成员最亲近？
        - 家庭氛围是怎样的？

    early_recollections:
      name: 早期记忆
      description: |
        阿德勒认为我们选择记住的早期记忆
        反映了我们的生活风格。
        这些记忆是我们如何看待自己和世界的隐喻。
      collection:
        instructions: |
          请回忆 8 岁之前的三个清晰记忆。
          对于每个记忆：
          1. 描述具体发生了什么（像看电影一样）
          2. 记忆中最生动的一刻是什么？
          3. 那一刻你有什么感受？
          4. 其他人在做什么？
      analysis:
        questions:
          - 这些记忆中反复出现的主题是什么？
          - 你在这些记忆中是主动的还是被动的？
          - 其他人是支持的、威胁的还是无关的？
          - 世界看起来是安全的还是危险的？
        interpretation: |
          早期记忆不需要是"真实"发生的，
          重要的是它们揭示的心理模式。
          我们倾向于记住那些确认我们生活风格的经历。

    life_tasks_evaluation:
      name: 人生任务评估
      tasks:
        work:
          name: 工作/职业
          questions:
            - 你对目前的工作/学业满意吗？（1-10）
            - 工作中最大的挑战是什么？
            - 你觉得自己在做有意义的贡献吗？
            - 你对成功的定义是什么？
        social:
          name: 社会关系/友谊
          questions:
            - 你对社交生活的满意度是多少？（1-10）
            - 你有多少亲密朋友？
            - 你在社交中通常扮演什么角色？
            - 你觉得被社区接纳吗？
        love:
          name: 爱情/亲密关系
          questions:
            - 你对亲密关系的满意度是多少？（1-10）
            - 在关系中你最常担心什么？
            - 你觉得自己值得被爱吗？
            - 你对伴侣关系的期望是什么？

  lifestyle_patterns:

    ruling_type:
      name: 支配型
      description: |
        追求控制和权力，
        倾向于支配他人。
      characteristics:
        - 高活动性
        - 低社会兴趣
        - 竞争导向
        - 可能欺凌他人
      healthy_expression: 领导力、果断
      unhealthy_expression: 控制、攻击

    getting_type:
      name: 索取型
      description: |
        倾向于依赖他人满足需求，
        被动等待他人帮助。
      characteristics:
        - 低活动性
        - 低社会兴趣
        - 依赖他人
        - 期望被照顾
      healthy_expression: 善于接受帮助、谦逊
      unhealthy_expression: 寄生、操控

    avoiding_type:
      name: 回避型
      description: |
        通过逃避挑战来保护自己免受失败。
      characteristics:
        - 低活动性
        - 低社会兴趣
        - 害怕失败
        - 社交退缩
      healthy_expression: 谨慎、深思熟虑
      unhealthy_expression: 孤立、停滞

    socially_useful:
      name: 社会有用型
      description: |
        这是阿德勒认为最健康的类型，
        既有活动性又有社会兴趣。
      characteristics:
        - 高活动性
        - 高社会兴趣
        - 合作导向
        - 为共同利益贡献
      expression: 健康的成就、帮助他人、社区参与
```

### 3.2 出生顺序 (`theories/adlerian/birth_order.md`)

```yaml
birth_order_knowledge:

  overview:
    description: |
      阿德勒观察到出生顺序对人格发展有显著影响。
      这不是决定论，而是一种倾向。
      重要的不是实际出生顺序，
      而是个人对自己在家庭中位置的主观感知。

    adler_quote: |
      "不是家庭中的位置决定性格，
       而是个人对这个位置的解读。"

  birth_positions:

    only_child:
      name: 独生子女
      psychological_position: 家庭关注的唯一焦点
      typical_characteristics:
        positive:
          - 成熟、独立
          - 语言能力强
          - 创造力高
          - 自我激励
        challenging:
          - 完美主义
          - 难以分享
          - 可能以自我为中心
          - 独处时更舒适
      common_patterns:
        - 习惯成人陪伴
        - 可能对同龄人互动不熟练
        - 高自我期望
      guiding_questions:
        - 你小时候最常和谁玩？
        - 你觉得独处是放松还是孤独？
        - 你对"分享"有什么感受？

    firstborn:
      name: 长子/长女
      psychological_position: |
        最初独享父母关注，
        后被"废黜"当弟妹出生。
      typical_characteristics:
        positive:
          - 责任感强
          - 领导能力
          - 成就导向
          - 可靠
        challenging:
          - 过度控制
          - 完美主义
          - 焦虑
          - 难以放松
      common_patterns:
        - 经常被要求"做榜样"
        - 可能对弟妹有矛盾情感
        - 倾向于传统和规则
        - 对失去地位敏感
      dethronment_experience:
        description: |
          "废黜"是长子/长女独特的经历——
          从独享父母关注到必须分享。
          这可能导致对失去的恐惧和控制需求。
      guiding_questions:
        - 弟弟/妹妹出生时你几岁？你还记得那时的感受吗？
        - 你是否经常被期望"照顾"弟妹？
        - 你对"第一"和"最好"有什么感受？

    middle_child:
      name: 中间子女
      psychological_position: |
        夹在长子/长女和幼子/幼女之间，
        没有"第一"或"最小"的特殊地位。
      typical_characteristics:
        positive:
          - 善于调解
          - 灵活适应
          - 社交能力强
          - 独立
        challenging:
          - 可能感到被忽视
          - 身份认同困惑
          - 竞争心强
          - 可能叛逆
      common_patterns:
        - 寻求独特身份
        - 善于谈判和妥协
        - 可能发展长子/长女不同的才能
        - 对公平高度敏感
      guiding_questions:
        - 你觉得自己在家庭中被"看见"吗？
        - 你如何在兄弟姐妹中找到自己的位置？
        - "公平"对你来说有多重要？

    youngest:
      name: 幼子/幼女
      psychological_position: |
        家庭中的"婴儿"，
        往往得到更多宽容和帮助。
      typical_characteristics:
        positive:
          - 魅力
          - 创造力
          - 善于激励他人
          - 冒险精神
        challenging:
          - 可能不够成熟
          - 依赖他人
          - 可能被轻视
          - 需要关注
      common_patterns:
        - 被保护和宠爱
        - 可能与年长孩子竞争
        - 可能发展出超越哥哥姐姐的雄心
        - 善于获得帮助
      guiding_questions:
        - 你小时候觉得被"宠坏"了吗？
        - 你是否觉得需要证明自己？
        - 你如何看待"依赖他人"？

  functional_vs_ordinal:
    description: |
      功能性出生顺序可能与实际出生顺序不同。
      例如：
      - 如果长子有残疾，次子可能功能上是"长子"
      - 年龄差距大（5年以上）可能创造"两个独生子女"
      - 性别分组可能创造子群体中的出生顺序
    factors:
      - 年龄差距
      - 性别分组
      - 身体/智力差异
      - 家庭动态变化（离婚、再婚）
      - 收养或寄养
```

---

## 四、循证实践知识库

### 4.1 认知扭曲 (`theories/cbt/distortions.md`)

```yaml
cognitive_distortions:

  overview:
    description: |
      认知扭曲是系统性的思维错误，
      导致对现实的非理性解读，
      进而引发负面情绪。
    author: Aaron Beck / David Burns
    purpose: 识别并挑战不健康的思维模式

  distortion_types:

    all_or_nothing:
      name: 全或无思维 / 非黑即白
      alias: [极端思维, 二分法思维]
      description: 以绝对的方式看待事物，没有中间地带
      examples:
        - "如果我没有得到 A，我就是失败者"
        - "她没回我消息，说明她讨厌我"
        - "这次面试不完美，我永远找不到工作了"
      challenge_questions:
        - 真的只有两个极端吗？
        - 有没有中间地带？
        - 如果给结果打分，会是多少分？
      reframe_template: |
        虽然{situation}不是完美的，
        但它也不是完全的失败。
        实际上，它大约是{percentage}%成功的。

    catastrophizing:
      name: 灾难化
      alias: [放大, 小题大做]
      description: 将小问题放大成灾难
      examples:
        - "我犯了这个错误，职业生涯完了"
        - "这次吵架后，我们的关系肯定结束了"
        - "我心跳加速，肯定是心脏病发作"
      challenge_questions:
        - 最坏的情况真的会发生吗？
        - 如果发生了，我真的无法应对吗？
        - 一年后回看这件事，会有多重要？
      reframe_template: |
        虽然{situation}让我担忧，
        但最可能的结果是{likely_outcome}，
        即使最坏的情况发生，我也可以{coping_strategy}。

    mind_reading:
      name: 读心术
      alias: [猜测他人想法]
      description: 假设知道别人在想什么（通常是负面的）
      examples:
        - "她一定觉得我很蠢"
        - "他没说话是因为生我的气"
        - "他们肯定在背后议论我"
      challenge_questions:
        - 我有什么证据支持这个想法？
        - 还有其他可能的解释吗？
        - 我是否直接问过对方？
      reframe_template: |
        我不确定{person}在想什么。
        可能的解释包括：{alternatives}。
        如果我想知道，我可以直接询问。

    fortune_telling:
      name: 算命
      alias: [预测未来]
      description: 预测负面结果会发生
      examples:
        - "这次尝试肯定会失败"
        - "我永远不会找到真爱"
        - "明天的演讲肯定会搞砸"
      challenge_questions:
        - 我真的能预测未来吗？
        - 过去类似的预测有多准确？
        - 有什么证据支持这个预测？
      reframe_template: |
        虽然我担心{prediction}，
        但我实际上不知道会发生什么。
        过去我也有过类似的担心，结果往往比预期的好。

    should_statements:
      name: "应该"陈述
      alias: [命令式思维]
      description: 用"应该"、"必须"对自己或他人提出僵化要求
      examples:
        - "我应该能处理所有事情"
        - "他应该理解我"
        - "生活不应该这么难"
      challenge_questions:
        - 这个"应该"来自哪里？
        - 如果没有做到，真的是不可接受的吗？
        - 我能用"希望"或"偏好"代替"应该"吗？
      reframe_template: |
        我更希望{preference}，
        但如果没有实现，
        我可以接受现实并继续前进。

    labeling:
      name: 贴标签
      alias: [过度概括化]
      description: 用单一负面标签定义自己或他人
      examples:
        - "我是个失败者"
        - "我太蠢了"
        - "他是个混蛋"
      challenge_questions:
        - 一个行为能定义一个人吗？
        - 这个标签公平吗？完整吗？
        - 我会这样评价我的朋友吗？
      reframe_template: |
        虽然我在{situation}中{behavior}，
        但这不能定义我这个人。
        我是一个复杂的人，有很多面向。

    emotional_reasoning:
      name: 情绪推理
      description: 把感受当作事实的证据
      examples:
        - "我感到焦虑，所以肯定有危险"
        - "我感到内疚，所以我一定做错了什么"
        - "我感到无望，所以情况真的很糟糕"
      challenge_questions:
        - 感受是事实吗？
        - 有什么客观证据？
        - 感受可能来自其他原因吗？
      reframe_template: |
        虽然我感到{emotion}，
        但感受不等于事实。
        客观来看，实际情况是{reality}。

    mental_filter:
      name: 心理过滤
      alias: [选择性注意, 负面过滤]
      description: 只关注负面细节，忽视正面信息
      examples:
        - 演讲收到 20 个好评，1 个差评，只记得差评
        - 工作得到表扬，但只关注小错误
        - 约会愉快，但只记得尴尬时刻
      challenge_questions:
        - 我是否只关注了负面的？
        - 有什么正面的我忽略了？
        - 如果看全貌，评价会不同吗？
      reframe_template: |
        虽然有{negative}，
        但也有{positive}。
        整体来看，情况是{balanced_view}。

    disqualifying_positive:
      name: 否定积极
      description: 将积极经验"不算数"
      examples:
        - "他夸我只是客气"
        - "这次成功只是运气"
        - "他们邀请我只是出于礼貌"
      challenge_questions:
        - 为什么积极的"不算数"？
        - 如果朋友这样想，我会怎么说？
        - 有什么证据支持积极的解读？
      reframe_template: |
        {positive_event}是真实的。
        它可以作为证据，说明{positive_meaning}。
        我选择接受这个积极的体验。

    personalization:
      name: 个人化
      description: 把不完全是自己责任的事归咎于自己
      examples:
        - "孩子成绩不好是我的错"
        - "朋友不开心是因为我"
        - "项目失败都怪我"
      challenge_questions:
        - 这完全是我的责任吗？
        - 还有哪些因素可能影响了结果？
        - 我真的有那么大的控制力吗？
      reframe_template: |
        虽然我可能有{my_contribution}的责任，
        但{situation}受到多种因素影响，
        包括{other_factors}。

    blaming:
      name: 责备
      description: 将所有问题归咎于他人或环境
      examples:
        - "都是他的错"
        - "如果不是这个环境，我早就成功了"
        - "我的问题都是原生家庭造成的"
      challenge_questions:
        - 我有什么责任？
        - 在这个情境中，我能做什么？
        - 责备能帮我解决问题吗？
      reframe_template: |
        虽然{external_factor}确实有影响，
        但我可以选择如何回应。
        在这个情境中，我可以{my_action}。
```

---

## 五、检索策略

### 5.1 意图识别与知识匹配

```yaml
retrieval_strategy:

  intent_classification:
    shadow_work:
      keywords: [阴影, 投射, 讨厌的特质, 压抑, 暗面, 不想看到]
      retrieve: theories/jungian/shadow.md, exercises/shadow_work/

    archetype:
      keywords: [原型, 人格类型, 英雄, 智者, 我是什么类型]
      retrieve: theories/jungian/archetypes.md, assessments/exploration/archetype_inventory.md

    lifestyle:
      keywords: [生活风格, 行为模式, 为什么总是, 习惯]
      retrieve: theories/adlerian/lifestyle.md

    birth_order:
      keywords: [出生顺序, 家庭中的位置, 兄弟姐妹, 排行]
      retrieve: theories/adlerian/birth_order.md

    cognitive:
      keywords: [想法, 思维, 认知, 负面想法, 消极思维]
      retrieve: theories/cbt/distortions.md, exercises/cognitive_restructuring/

    depression:
      keywords: [抑郁, 低落, 没有动力, 悲伤, 无望]
      retrieve: assessments/clinical/phq9.md, psychoeducation/emotions/depression.md

    anxiety:
      keywords: [焦虑, 担心, 紧张, 害怕, 恐慌]
      retrieve: assessments/clinical/gad7.md, psychoeducation/emotions/anxiety.md

    crisis:
      keywords: [自杀, 自伤, 不想活, 结束, 没有意义]
      retrieve: crisis/safety_plans.md, crisis/hotlines.md
      priority: HIGHEST

  context_enhancement:
    user_history:
      - 之前的评估结果
      - 已完成的练习
      - 识别的模式

    session_context:
      - 当前讨论的主题
      - 情绪状态
      - 时间限制
```

### 5.2 渐进式内容呈现

```yaml
progressive_disclosure:

  level_1_intro:
    description: 简短定义和核心概念
    length: 50-100 字
    use_when: 用户首次提及概念

  level_2_explanation:
    description: 详细解释和例子
    length: 200-300 字
    use_when: 用户表示想深入了解

  level_3_application:
    description: 完整内容 + 练习引导
    length: 按需展开
    use_when: 用户准备好进行实践

  example:
    concept: 阴影
    level_1: |
      阴影是你人格中被压抑的部分——
      那些你不想成为或不想让别人看到的特质。
    level_2: |
      [添加形成原因、常见表现、投射概念...]
    level_3: |
      [添加完整阴影工作练习引导...]
```

---

## 六、知识库维护

### 6.1 版本控制

```yaml
versioning:
  format: semantic (MAJOR.MINOR.PATCH)
  changelog: 每次更新记录变更
  review_cycle: 每季度审核内容准确性
```

### 6.2 质量标准

```yaml
quality_criteria:
  accuracy: 基于循证文献
  clarity: 使用易懂语言
  sensitivity: 考虑文化和个人差异
  safety: 包含适当的安全警告
  attribution: 标注理论来源
```

### 6.3 扩展计划

```yaml
future_additions:
  - 依恋理论知识库
  - 创伤知情护理
  - 正念和 ACT 练习
  - 情绪调节技能
  - 人际效能技巧
```
