# Fortune AI 系统顶层设计文档 v2.0

**文档类型**: 系统顶层设计 (System Top-Level Design)
**代号**: Fortune AI (Project Celestia / DaoMind)
**版本**: 2.0
**日期**: 2025-12-24
**密级**: 核心机密
**目标读者**: 高层决策者 (C-Level), 产品经理 (PM), 核心开发团队 (Dev Team)

---

## 1. 执行摘要 (Executive Summary)

**Fortune AI** 不仅仅是一个算命工具，它是为不确定时代打造的 **“AI 原生人生导航系统 (AI-Native Life Navigation OS)”**。

本项目融合了东方命理哲学的深度（八字、紫微、铁板、奇门）与西方管理科学的效能（7 Habits, Stoicism），利用最前沿的 **Agentic AI** 技术，构建一个完全去人工化、但具备真人级共情与深度的数字伴侣。

**核心差异化：**
1.  **全知全能的数字孪生**：基于深度记忆架构，构建用户的“过去-现在-未来”全景视图。
2.  **客户经理式交互**：前端不仅仅是仪表盘，更是一个智能 Agent，像私人银行家一样理解需求、调度后台资源、交付结构化方案。
3.  **模块化计算中台**：可插拔的计算引擎（从八字到铁板神数）与可配置的解读人格（从孔子到斯多噶），实现千人千面的决策支持。
4.  **纯 AI 闭环**：坚决不引入真人服务，通过算力换人力，用 Agent 深度推理解决复杂咨询需求。

---

## 2. 核心战略与价值主张 (Strategic Core)

### 2.1 核心价值主张 (UVRA)

| 维度 | 定义 |
| :--- | :--- |
| **User (用户)** | 25-40岁，面临职业/情感/存在主义危机的都市“焦虑优化者”。 |
| **Value (价值)** | **决策支持 + 人生导航 + 焦虑消解**。<br>回答终极哲学问题：“我是谁（Profile），我从何处来（History），我往何处去（Goal）”。 |
| **Reason (理由)** | 唯一结合了“多维命理计算”+“深度心理学/管理学框架”+“长期记忆”的 AI 系统。 |
| **Advantage (优势)** | 比真人更全知（记忆力），比传统 APP 更具行动力（行动处方），比通用 AI 更懂玄学逻辑（混合 RAG）。 |

### 2.2 北极星指标 (North Star Metric)

**周活跃深度决策数 (Weekly Active Deep Decisions, WADD)**

*定义*：用户在系统中不仅查看了运势，还完成了至少一次“深度交互闭环”。
*   **闭环标准**：提出问题 -> AI 分析 -> 生成行动处方 -> 用户确认/执行/反馈。
*   *理由*：这代表用户真正将 Fortune AI 作为“外脑”参与了生活决策，而非仅仅作为娱乐消遣。

---

## 3. 用户画像与深度需求 (Persona & Deep Needs)

### 3.1 核心用户画像：The Anxious Optimizer

他们不迷信，但迷茫。他们需要的不是一个“算命先生”，而是一个**“拥有上帝视角的麦肯锡顾问”**。

| 属性 | 描述 |
| :--- | :--- |
| **核心痛点** | **决策瘫痪** (Decision Paralysis) & **存在主义焦虑** (Existential Anxiety)。 |
| **显性需求** | “告诉我下周面试穿什么颜色？”（短期战术） |
| **隐性需求** | “告诉我我这辈子到底适合做什么？”（长期战略） |
| **交互偏好** | 拒绝黑箱，需要逻辑解释；拒绝说教，需要共情陪伴；拒绝繁琐，需要直观可视化。 |

### 3.2 需求分层模型 (The Needs Pyramid)

1.  **L1 信息层 (Information)**：精准的命理数据（排盘、流年）。
2.  **L2 解释层 (Interpretation)**：将数据翻译为“人话”（如：伤官见官 = 创新与体制的冲突）。
3.  **L3 决策层 (Decision Support)**：基于解释给出选项（Option A/B/C）。
4.  **L4 行动层 (Action Prescription)**：具体的执行清单（To-Do List）。
5.  **L5 意义层 (Meaning)**：将当下困难升华为人生英雄之旅的一部分（斯多噶/儒家视角）。

---

## 4. 系统架构设计 (System Architecture)

本系统采用 **“大脑-身体-面孔”** 三层仿生架构，强调模块化与可配置性。

```mermaid
graph TD
    User[用户] <--> Client[前端交互层 (The Face)]
    Client <--> Gateway[API 网关]
    Gateway <--> AgentLayer[智能代理编排层 (The Brain)]
    
    subgraph "The Brain: 智能代理编排层"
        ManagerAgent[客户经理 Agent]
        ReasoningEngine[深度推理引擎]
        MemorySystem[记忆系统]
    end
    
    AgentLayer <--> CalcLayer[计算服务中台 (The Body)]
    
    subgraph "The Body: 计算服务中台"
        direction TB
        subgraph "命理计算插件组"
            Bazi[八字引擎]
            Ziwei[紫微斗数]
            Astro[西方星盘]
            Tieban[铁板神数]
            Qimen[奇门遁甲]
        end
        
        subgraph "解读模型插件组"
            Psych[心理学模型]
            Coach[7 Habits/高绩效]
            Philo[孔子/斯多噶]
        end
    end
    
    AgentLayer <--> DataLayer[数据持久层]
```

### 4.1 前端交互层 (The Face): 现代感 Bento + 智能对话

前端不再是简单的功能堆砌，而是 **“仪表盘 + 客户经理”** 的双核模式。

#### 4.1.1 Bento Grid 仪表盘 (The Dashboard)
利用 **Neo-Brutalism** 风格与 **Nano Banana** 生成技术，打造高颜值的“人生驾驶舱”。

| 模块 (Bento Box) | 功能描述 | 视觉表现 |
| :--- | :--- | :--- |
| **今日能量卡** | 核心运势概览 | 3D 动态图腾 (如：燃烧的宝剑代表“行动日”) |
| **行动处方** | 今日 To-Do List | 清单样式，打钩后有粒子特效 |
| **能量 K 线** | 运势波动趋势 | 类似股市 K 线，标注高低点 |
| **灵宠状态** | 用户的数字投射 | 根据运势变化的 3D Avatar (如：雨天撑伞) |

#### 4.1.2 智能交互对话 (The Client Manager)
**核心理念**：这不是一个简单的 Chatbot，而是一个 **“私人银行客户经理”**。
*   **职责**：
    1.  **理解需求**：通过多轮对话澄清用户模糊的意图（如：“我最近很烦” -> “是工作压力还是情感困扰？”）。
    2.  **任务转化**：将自然语言转化为后端计算任务（Task Dispatching）。
    3.  **结果交付**：将后端复杂的计算结果，封装成易读的“卡片”或“报告”推给用户。

### 4.2 智能代理编排层 (The Brain): 深度思考与记忆

#### 4.2.1 记忆架构 (Memory Architecture)
这是 Fortune AI 的灵魂。

*   **静态档案 (Profile)**：
    *   **核心真实信息**：生辰、出生地、性别。
    *   **标签系统 (Tags)**：`#INTJ`, `#伤官格`, `#创业者`, `#焦虑型依恋`。
*   **动态时间轴 (Timeline)**：
    *   **过往历史 (History)**：用户确认过的关键人生节点（2018年分手、2021年升职）。用于**回溯验证 (Hindsight Validation)**。
    *   **未来计划 (Future)**：用户输入的近期目标（下周面试、明年买房）。
*   **深度记忆 (Deep Memory)**：
    *   **对话摘要**：向量化存储的历史对话。
    *   **情绪日志**：长期的情绪波动曲线。

#### 4.2.2 深度推理引擎 (Reasoning Engine)
替代真人的关键。当用户提出复杂问题时，系统不直接回答，而是进入 **“慢思考模式” (System 2 Thinking)**。
*   **流程**：拆解问题 -> 调用多个计算引擎 -> 交叉验证 -> 综合生成报告。

### 4.3 计算服务中台 (The Body): 模块化与可扩展

后端采用 **插件化架构 (Plugin Architecture)**，允许灵活配置不同的计算与解读模块。

#### 4.3.1 计算插件组 (Calculators)
| 插件名 | 适用场景 | 输出数据示例 |
| :--- | :--- | :--- |
| **八字 (Bazi)** | 宏观格局、性格底色、大运流年 | `{"structure": "伤官配印", "element_balance": {"fire": 80}}` |
| **紫微 (Ziwei)** | 细节事件、人际关系、十二宫位 | `{"career_palace": ["紫微", "七杀"], "stars": ["天马"]}` |
| **星盘 (Astro)** | 心理动机、潜意识、每日行运 | `{"aspects": ["Moon square Saturn"], "transit": "Mercury Retrograde"}` |
| **铁板神数 (Tieban)** | **[新增]** 精确的数理推演、六亲考刻 | `{"verdict_code": 1234, "text": "父属虎母属龙"}` |
| **奇门遁甲 (Qimen)** | **[新增]** 战术决策、方位选择、短期成败 | `{"direction": "South-East", "action": "Ambush"}` |

#### 4.3.2 解读模型插件组 (Interpreters)
将计算结果“翻译”为用户能听懂的建议。

| 模型名 | 核心哲学 | 适用 Persona |
| :--- | :--- | :--- |
| **Metaphysics** | 传统命理 | 标准风格 |
| **Psychology** | CBT (认知行为疗法) | 温暖疗愈风格 |
| **Performance** | 7 Habits / High Performance Coach | 专业教练风格 |
| **Philosophy** | 孔子 (入世) / 斯多噶 (出世) | 智者/Roast 风格 |

---

## 5. 核心功能特色深度解析 (Core Features Deep Dive)

### 5.1 用户 Profile 与全景人生 (The Digital Twin)

系统构建一个可视化的 **“全景人生时间轴”**。

*   **过去 (The Past)**：
    *   **功能**：系统自动标记命理上的“转折年”（如换大运），询问用户“2019年是否发生了变动？”
    *   **价值**：通过准确“算准”过去，建立极高的信任壁垒。
*   **现在 (The Present)**：
    *   **功能**：实时能量状态（Energy Level）。
    *   **价值**：情绪确认与当下指引。
*   **未来 (The Future)**：
    *   **功能**：基于“目标（Goal）”的路径规划。用户设定“3年内上市”，系统基于运势计算最佳路径（如：2025年适合融资，2026年适合扩张）。
    *   **价值**：将玄学转化为战略规划工具。

### 5.2 决策支持与行动处方 (Action Prescription)

**拒绝模棱两可，提供可执行的清单。**

*   **场景**：用户问“明天去谈生意怎么样？”
*   **计算**：
    *   *奇门*：开门在西北，吉。
    *   *八字*：日主坐财，但有比劫争夺。
    *   *Coach模型*：建议双赢思维 (Win-Win)。
*   **交付 (Action Card)**：
    *   **结论**：⭐⭐⭐⭐ (吉带凶)
    *   **行动处方**：
        1.  ✅ **方位**：坐在会议室的西北角。
        2.  ✅ **策略**：先谈利益分配（化解比劫争财）。
        3.  ✅ **心态**：保持斯多噶式的冷静，对方可能会压价。
        4.  ✅ **穿搭**：穿黑色衣服（水）通关金木之战。

### 5.3 社交属性与关系模拟 (Relationship Simulation)

**关系实验室 (Bond Lab)**：不仅仅是合盘打分，而是 **Agent 对战模拟**。

*   **功能**：用户导入老板/伴侣的生日。
*   **模拟**：用户输入“我想提涨薪”。
*   **AI 推演**：
    *   系统生成“老板 Agent”（基于老板八字：七杀格，脾气暴躁，吃软不吃硬）。
    *   系统生成“用户 Agent”。
    *   **模拟对话**：AI 模拟两人对话 10 个回合，预测老板的反应（“他会拍桌子，但内心会动摇”）。
*   **输出**：最佳沟通话术脚本。

### 5.4 主动服务 (Proactive Service)

**宇宙瞭望塔 (Cosmic Watchtower)**：

*   **机制**：后台 24/7 监控星象与用户命盘的交互。
*   **触发**：检测到“水星逆行”或“流年冲克”。
*   **推送**：
    *   *Notification*：“⚠️ 沟通预警：下周水逆开始，你的合同建议在周五前签署。”
    *   *Action*：点击一键生成“水逆退散符”壁纸。

---

## 6. 关键业务流程 (Key Business Flows)

### 6.1 深度咨询闭环 (The Deep Consultation Loop)

此流程完全替代真人专家服务。

```ascii
+------------+      +------------------+      +-----------------------+
| User Query | ---> | Client Manager   | ---> | Intent Classification |
| "我该离职吗?"|      | (Chat Interface) |      | (Career / Crisis)     |
+------------+      +------------------+      +-----------+-----------+
                                                          |
                                                          v
                                              +-----------------------+
                                              | Reasoning Engine      |
                                              | (System 2 Thinking)   |
                                              +-----------+-----------+
                                                          |
            +----------------------+----------------------+----------------------+
            v                      v                      v                      v
    +-------+-------+      +-------+-------+      +-------+-------+      +-------+-------+
    | Bazi Engine   |      | Tieban Engine |      | Memory System |      | Coach Model   |
    | (Career Luck) |      | (Fate Code)   |      | (Past Trauma) |      | (SWOT Analysis)|
    +-------+-------+      +-------+-------+      +-------+-------+      +-------+-------+
            |                      |                      |                      |
            +----------------------+----------------------+----------------------+
                                                          |
                                                          v
                                              +-----------------------+
                                              | Synthesis & Generation|
                                              | (Persona: Professional)|
                                              +-----------+-----------+
                                                          |
                                                          v
                                              +-----------------------+
                                              | Delivery (Bento Card) |
                                              | 1. Analysis (Why)     |
                                              | 2. Decision (Yes/No)  |
                                              | 3. Action Plan (How)  |
                                              +-----------------------+
```

### 6.2 每日启动仪式 (Daily Ritual)

1.  **Push**：早晨 8:00 推送“今日能量日报”。
2.  **Open**：用户打开 APP，看到 Nano Banana 生成的专属“能量图腾”。
3.  **Check**：查看今日 To-Do (如：宜冥想，忌争吵)。
4.  **Interact**：点击完成“电子木鱼” 3 分钟（获得能量币）。
5.  **Share**：生成今日运势海报分享至朋友圈（社交裂变）。

---

## 7. 技术架构原则 (Technical Architecture Principles)

### 7.1 混合 RAG (Hybrid RAG)

*   **问题**：通用 LLM 不懂玄学逻辑，容易胡说八道。
*   **方案**：
    *   **结构化知识图谱 (Graph)**：存储“子午冲”、“伤官见官”等硬规则。
    *   **向量检索 (Vector)**：存储《滴天髓》、《斯多噶哲学》等软文本。
    *   **流程**：先通过计算引擎得出“结构化结论”（如：Score=60, Pattern=Clash），再利用 RAG 检索对应解释，最后由 LLM 润色输出。

### 7.2 模块化后端 (Modular Backend)

*   **接口标准化**：所有计算插件（八字、紫微、铁板）必须输出标准 JSON 格式。
    *   `Input: {dob, gender, location}`
    *   `Output: {energy_score, keywords[], events[], suggestions[]}`
*   **配置中心**：运营人员可动态配置“解读风格”。例如，情人节期间，将所有用户的默认 Persona 调整为“温暖风格”，并增加“奇门桃花”计算模块的权重。

### 7.3 数据隐私 (Privacy)

*   **本地化脱敏**：用户的生辰八字在传输给 LLM 前，转换为匿名 Token（如 `User_A_Chart_Data`），LLM 只负责解释，不接触原始 PII。
*   **遗忘权**：用户可一键“焚毁”所有过往记录（物理删除）。

---

## 8. 路线图 (Roadmap)

| 阶段 | 目标 | 核心交付物 |
| :--- | :--- | :--- |
| **Phase 1: MVP** | **建立信任** | 核心八字/紫微计算引擎，Bento 仪表盘，基础 RAG 解读。 |
| **Phase 2: Agent** | **深度交互** | 上线“客户经理” Agent，接入记忆系统，实现多轮对话咨询。 |
| **Phase 3: Matrix** | **全维覆盖** | 接入铁板、奇门插件，上线关系模拟器，完善行动处方闭环。 |
| **Phase 4: Ecosystem**| **生态化** | 开放 API 给第三方开发者（如：冥想 APP 接入运势数据）。 |

---

## 9. 附录：数据结构示例

### 9.1 用户档案 (User Profile Schema)

```json
{
  "user_id": "u_123456",
  "basic_info": {
    "dob": "1990-05-20T14:30:00Z",
    "gender": "female",
    "pob": "Shanghai"
  },
  "tags": ["#ENTJ", "#HighAchiever", "#WeakFire"],
  "timeline": {
    "history": [
      {"year": 2018, "event": "breakup", "verified": true},
      {"year": 2022, "event": "promotion", "verified": true}
    ],
    "future_goals": [
      {"target_date": "2026", "goal": "IPO", "priority": "high"}
    ]
  },
  "memory_embeddings": "vector_ref_id_..."
}
```

### 9.2 行动处方 (Action Prescription Schema)

```json
{
  "date": "2025-12-25",
  "overall_score": 85,
  "theme": "Innovation",
  "tasks": [
    {
      "type": "action",
      "title": "发起头脑风暴",
      "reason": "今日伤官星旺，利于打破常规",
      "source": "Bazi_Engine"
    },
    {
      "type": "ritual",
      "title": "正念冥想 5分钟",
      "reason": "缓解火金相克的焦躁",
      "source": "Psych_Model"
    }
  ]
}
```
```

<!--
[PROMPT_SUGGESTION]请基于v2文档的架构，为“关系模拟器”功能生成一段详细的Mermaid序列图，展示用户输入、Agent模拟对战、以及最终话术生成的完整技术流程。[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]请为“铁板神数”计算插件设计一个详细的Python类接口定义（Interface Definition），包含输入参数、核心计算方法和标准化的输出JSON格式。[/PROMPT_SUGGESTION]
