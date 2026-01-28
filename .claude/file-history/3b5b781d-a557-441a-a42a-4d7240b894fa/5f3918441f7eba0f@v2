# Fortune AI MVP 系统设计文档

**文档类型**：System MVP Design
**产品代号**：`Fortune AI MVP`
**版本**：1.0
**日期**：2025-12-29
**目标读者**：开发团队 / 产品团队
**基线文档**：`system_design_codex_v3.md`
**硬约束**：纯 AI（不引入真人服务）、不做社区、Web 端可落地

---

## 0. 一页结论（给开发）

### 0.1 MVP 定位

> **Fortune AI MVP 是 Web 端可落地的"人生导航、陪伴、提升系统"原型：通过 Chat（积极心理学/Performance Coach 角色）+ 功能区（Bento）的交互范式，用确定性命理计算（八字）+ 结构化知识库 + 心理/成长框架，帮助用户理解"我是谁、我从何处来、我往何处去"，输出可执行的行动处方。**

### 0.2 MVP 核心价值主张

| 用户购买的 | 传统交付 | Fortune AI MVP 交付 |
|---|---|---|
| 确定性与解释框架 | 诗句/结论 | 结构化洞察（why）+ 知识库证据 |
| 行动抓手 | 很少 | 行动处方（ToDo/话术/仪式，≤3条） |
| 陪伴与温度 | 真人强 | **积极心理学/Performance Coach Persona** + 记忆引用 |
| 成长导航 | 无 | 每日推送 + 主动心理学计划引导 |

### 0.3 MVP 范围声明

| 类别 | In Scope（MVP 要做） | Out of Scope（后续阶段） |
|---|---|---|
| 前端 | Chat（Performance Coach）+ Bento 功能区 | 合盘/关系模拟、AIGC 壁纸 |
| 后端-计算 | **完整八字功能**（含知识库增强） | 紫微/铁板/奇门/六爻 |
| 后端-解读 | 命理解释 + 积极心理学 + Performance Coach | 多解读包切换 |
| 交互 | 语言风格三档（标准/温暖/毒舌）、主动服务框架 | 复杂仪式引擎 |
| 数据 | Profile + Timeline + 基础记忆 | 向量记忆检索、跨设备同步 |

---

## 1. 产品哲学与核心机制

### 1.1 核心循环（Main Loop）

```
用户输入/触发
    ↓
[Chat Agent: 积极心理学/Performance Coach]
    ├─ 澄清意图与情绪状态
    ├─ 调用后端专业分析
    └─ 以 Coach 口吻表达结论
    ↓
[交付卡: 结论 + 依据 + 处方]
    ↓
[行动执行 → 反馈闭环]
```

### 1.2 前端 Agent 角色定义

**角色**：积极心理学/Performance Coach
**职责**：
1. **表达者**：将后端专业命理分析转化为积极、赋能的语言
2. **销售/客服**：引导用户完善 Profile、解答产品问题
3. **助教**：引导用户加入主动心理学计划、解释概念

**语言风格三档**：

| 风格 | 适用场景 | 示例语气 |
|---|---|---|
| `standard` | 默认 | 清晰、中性、专业 |
| `warm` | 情绪低落/安抚 | 温暖、共情、支持性 |
| `roast` | 轻娱乐/激励 | 直接、辛辣、带幽默感 |

**禁止项**：恐吓、羞辱、确定性宿命论、负面暗示

### 1.3 交互设计原则

| 原则 | 落地方式 |
|---|---|
| **对话为主** | Chat 是 SSOT（Single Source of Truth），所有输出最终呈现为对话消息 |
| **功能区辅助** | 非语言交互（表单、选择、配置）放在 Bento 功能区 |
| **极简有效** | 最小输入、最大输出价值；避免信息过载 |
| **主动但不打扰** | Push 必须包含 `Why me, why now` + `One action` + `Opt-out` |

---

## 2. 系统功能架构

### 2.1 总体架构（Face / Brain / Body）

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           [Face] 前端 Web Client                         │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌───────────────────────────────────────────────────┐ │
│  │ 左侧栏      │  │                  中央对话区                        │ │
│  │ - 会话历史  │  │  [Chat Thread]                                    │ │
│  │ - 快捷入口  │  │  - 用户消息                                        │ │
│  │ - 计划进度  │  │  - Bot 消息（Coach Persona）                       │ │
│  └─────────────┘  │  - 交付卡（结论/处方/证据）                        │ │
│                   │  - 进度/状态消息                                    │ │
│                   │                                                     │ │
│                   │  [输入区]                                           │ │
│                   │  - 文本输入 + 发送                                  │ │
│                   │  - 语音输入（可选）                                 │ │
│                   └───────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                     右侧功能区（Bento）                             │ │
│  │  ┌─────────────┬─────────────┬─────────────┬─────────────┐        │ │
│  │  │ Tab 1       │ Tab 2       │ Tab 3       │ Tab 4       │        │ │
│  │  │ 个人档案    │ 八字报告    │ 每日指引    │ 成长计划    │        │ │
│  │  └─────────────┴─────────────┴─────────────┴─────────────┘        │ │
│  │                                                                    │ │
│  │  [当前面板内容]                                                     │ │
│  │  - 表单 / 卡片 / 数据展示                                           │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           [Brain] 后端编排层                             │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Orchestrator（编排器）                        │   │
│  │  - Intent Recognition（意图识别）                                │   │
│  │  - Task Brief Construction（任务简报构建）                       │   │
│  │  - Tool/Plugin Routing（工具路由）                               │   │
│  │  - Response Synthesis（响应合成）                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Memory Layer（记忆层）                         │   │
│  │  - L0: PII Vault（高敏信息，加密存储）                            │   │
│  │  - L1: Timeline（Past/Plan/Goal，用户可编辑）                     │   │
│  │  - L2: Tags（动态标签/阶段推断）                                  │   │
│  │  - L3: Conversation（对话历史，脱敏摘要）                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Safety Layer（安全层）                         │   │
│  │  - 输出模板护栏                                                   │   │
│  │  - 危机词检测 → 转介提示                                         │   │
│  │  - 合规审计日志                                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           [Body] 计算与解读层                            │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │             Compute Plugins（确定性计算插件）                     │   │
│  │  ┌───────────────────────────────────────────────────────────┐  │   │
│  │  │  bazi_engine（八字计算）                                   │  │   │
│  │  │  - 真太阳时计算（lunar_python）                            │  │   │
│  │  │  - 四柱推导                                                │  │   │
│  │  │  - 五行分析                                                │  │   │
│  │  │  - 十神关系                                                │  │   │
│  │  │  - 大运/流年计算                                           │  │   │
│  │  │  - 神煞查询                                                │  │   │
│  │  └───────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │             Knowledge Base（结构化知识库）                        │   │
│  │  ┌───────────────────────────────────────────────────────────┐  │   │
│  │  │  bazi_knowledge（八字知识库）                              │  │   │
│  │  │  来源：knowledge/bazi/*.pdf → 结构化 JSON/YAML             │  │   │
│  │  │  - 格局解读规则                                            │  │   │
│  │  │  - 十神组合含义                                            │  │   │
│  │  │  - 五行生克应用                                            │  │   │
│  │  │  - 流年大运解读模板                                        │  │   │
│  │  │  - 行业/职业适配规则                                       │  │   │
│  │  └───────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │             Interpretation Packs（解读包）                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │ metaphysics │  │ psychology  │  │ coach       │             │   │
│  │  │ 命理解释    │  │ 积极心理学  │  │ 绩效教练   │             │   │
│  │  │             │  │ - CBT 框架  │  │ - 7 Habits │             │   │
│  │  │             │  │ - 正念元素  │  │ - SMART目标│             │   │
│  │  │             │  │ - 成长心态  │  │ - 行动处方 │             │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │             Renderer（交付渲染器）                                │   │
│  │  - Guidance Card（交付卡）渲染                                   │   │
│  │  - Markdown 格式化                                               │   │
│  │  - 卡片化组件输出                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 前端功能模块详解

#### 2.2.1 Chat 对话区（Coach Agent）

**功能要点**：
- 作为用户与系统的主交互界面
- 所有结果以对话消息形式呈现
- Coach Persona 贯穿始终

**消息类型**：

| 类型 | 样式 | 用途 |
|---|---|---|
| `user` | 右对齐气泡 | 用户输入 |
| `bot` | 左对齐 + 头像 | Coach 回复 |
| `card` | 卡片样式 | 交付卡（结论/处方） |
| `progress` | 带加载动画 | 任务进度 |
| `system` | 居中小字 | 系统提示 |

**输入增强**：
- 快捷问题建议（基于当前上下文）
- 语音输入（可选）
- 上下文胶囊（显示当前 Profile 摘要）

#### 2.2.2 Bento 功能区（Tab 面板）

**Tab 1：个人档案（Profile）**

```
┌─────────────────────────────────────────────┐
│ 基础信息                                    │
├─────────────────────────────────────────────┤
│ 姓名：[________]    性别：[男▼]            │
│ 出生日期：[____-__-__]                      │
│ 出生时间：[__:__:__]                        │
│ 出生地点：[________] 经度[___] 纬度[___]   │
├─────────────────────────────────────────────┤
│ 八字摘要（自动计算）                        │
│ ┌───┬───┬───┬───┐                          │
│ │年柱│月柱│日柱│时柱│                          │
│ ├───┼───┼───┼───┤                          │
│ │甲子│丙寅│戊辰│壬午│                          │
│ └───┴───┴───┴───┘                          │
│ 五行：金2 木3 水1 火2 土2                   │
├─────────────────────────────────────────────┤
│ 语言风格偏好                                │
│ ○ 标准   ● 温暖   ○ 毒舌                   │
├─────────────────────────────────────────────┤
│ [保存] [校准出生时间]                       │
└─────────────────────────────────────────────┘
```

**Tab 2：八字报告**

```
┌─────────────────────────────────────────────┐
│ 报告类型                                    │
├─────────────────────────────────────────────┤
│ ○ 快速分析（5分钟）                         │
│ ● 深度研究（15分钟）                        │
├─────────────────────────────────────────────┤
│ 分析维度（可多选）                          │
│ ☑ 性格特质    ☑ 事业方向                   │
│ ☑ 财运分析    ☐ 感情婚姻                   │
│ ☐ 健康提示    ☑ 流年运势                   │
├─────────────────────────────────────────────┤
│ 具体问题（可选）                            │
│ [________________________________]         │
├─────────────────────────────────────────────┤
│ [生成报告]                                  │
│                                             │
│ 进度与结果将在左侧对话区呈现                │
└─────────────────────────────────────────────┘
```

**Tab 3：每日指引**

```
┌─────────────────────────────────────────────┐
│ 今日能量卡                     2025-12-29   │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │  今日关键词：【沟通】【耐心】【学习】   │ │
│ │                                         │ │
│ │  能量指数：★★★★☆                      │ │
│ │  适宜：文书工作、学习、内部沟通         │ │
│ │  不宜：重大谈判、冲动决策               │ │
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ 今日行动处方                                │
│ ☐ 1. 上午安排需要专注的工作                │
│ ☐ 2. 重要对话前先深呼吸3次                 │
│ ☐ 3. 记录一个今日小成就                    │
├─────────────────────────────────────────────┤
│ [完成打卡] [查看详细解读]                   │
└─────────────────────────────────────────────┘
```

**Tab 4：成长计划**

```
┌─────────────────────────────────────────────┐
│ 积极心理学计划                              │
├─────────────────────────────────────────────┤
│ 当前计划：21天感恩练习      进度：7/21     │
│ ████████░░░░░░░░░░░░░ 33%                  │
├─────────────────────────────────────────────┤
│ 今日任务                                    │
│ ☐ 写下3件今天感恩的事                      │
│ ☐ 发送一条感谢消息给某人                   │
├─────────────────────────────────────────────┤
│ 可选计划                                    │
│ ┌───────────────┐ ┌───────────────┐        │
│ │ 21天感恩练习 │ │ 7天正念入门  │        │
│ │ ✓ 已加入     │ │ [加入]       │        │
│ └───────────────┘ └───────────────┘        │
│ ┌───────────────┐ ┌───────────────┐        │
│ │ 习惯养成挑战 │ │ 优势发现之旅 │        │
│ │ [加入]       │ │ [加入]       │        │
│ └───────────────┘ └───────────────┘        │
├─────────────────────────────────────────────┤
│ [完成今日任务] [查看历史记录]               │
└─────────────────────────────────────────────┘
```

### 2.3 后端功能模块详解

#### 2.3.1 完整八字功能（Bazi Engine Enhanced）

**现有能力（继承）**：
- 真太阳时计算
- 四柱（年月日时柱）推导
- 五行统计
- 出生时间校准（rectification）

**MVP 新增能力**：

| 能力 | 说明 | 数据来源 |
|---|---|---|
| 十神分析 | 计算日主与各柱关系 | 算法实现 |
| 格局判断 | 识别主要格局类型 | 知识库规则 |
| 大运计算 | 推算十年大运周期 | 算法实现 |
| 流年分析 | 当前流年干支影响 | 算法 + 知识库 |
| 神煞查询 | 主要神煞及含义 | 知识库 |
| 五行喜忌 | 判断喜用神/忌神 | 算法 + 知识库 |

**八字知识库结构**（基于 `knowledge/bazi/`）：

```yaml
# bazi_knowledge.yaml

格局:
  - id: "GJ-001"
    name: "正官格"
    conditions:
      - "月令透正官"
      - "正官不被冲克"
    interpretation:
      性格: "稳重、有责任感、重视规则"
      事业: "适合管理、公职、稳定行业"
      建议: "发挥组织能力，注意避免过于保守"
    evidence_ref: "千里命稿-正官格章节"

十神组合:
  - id: "SS-001"
    pattern: "食神生财"
    meaning: "才华可转化为财富"
    application:
      - "适合创意类、艺术类工作"
      - "副业发展有利"
    evidence_ref: "东方代码启示录-十神章"

流年解读模板:
  - pattern: "流年与日主相合"
    general: "贵人运旺，有合作机会"
    advice: "主动社交，把握合作机会"
```

#### 2.3.2 解读包设计

**积极心理学框架（psychology pack）**：

```yaml
psychology_pack:
  framework: "积极心理学 + CBT 元素"

  core_principles:
    - "关注优势而非缺陷"
    - "强调成长潜力"
    - "提供具体行动路径"
    - "承认困难但强调应对资源"

  reframe_patterns:
    # 将命理语言转化为心理学语言
    - input: "命中财运弱"
      output: "你的财富积累可能需要更系统的规划和耐心培育"
    - input: "官星被克"
      output: "你可能更适合独立工作或创业路径，而非传统晋升通道"
    - input: "伤官见官"
      output: "你有独特的创新思维，但需要学习如何与权威和谐相处"

  strength_mapping:
    # 命理特质 → 积极心理学优势
    比劫旺: ["社交能力", "团队协作", "影响力"]
    食伤旺: ["创造力", "表达能力", "审美"]
    财星旺: ["务实", "目标导向", "资源整合"]
    官印旺: ["责任感", "学习能力", "领导力"]
```

**绩效教练框架（coach pack）**：

```yaml
coach_pack:
  framework: "Performance Coach + 7 Habits"

  action_prescription_template:
    structure:
      - conclusion: "一句话核心洞察"
      - why: "基于命理的依据（用心理学语言）"
      - actions: "≤3条具体行动（SMART 原则）"
      - time_window: "建议执行时间窗口"
      - check_in: "反馈检查点"

  habit_integration:
    # 根据命理特质推荐习惯养成方向
    木旺: "习惯1-积极主动：设定晨间例程"
    火旺: "习惯2-以终为始：愿景板练习"
    土旺: "习惯3-要事第一：时间块管理"
    金旺: "习惯4-双赢思维：利益相关者分析"
    水旺: "习惯5-知彼解己：深度倾听练习"
```

#### 2.3.3 交付卡契约（Guidance Card Contract）

```typescript
interface GuidanceCard {
  // 必填字段
  id: string;                    // 唯一标识
  type: CardType;                // 卡片类型
  conclusion: string;            // 核心结论（1-2句）
  why: string;                   // 依据说明（心理学语言）
  prescriptions: Action[];       // 行动处方（≤3条）
  time_window: string;           // 时间窗口建议

  // 可选字段
  evidence?: Evidence;           // 内部证据（不直接展示给用户）
  risk_boundary?: string;        // 风险边界声明
  related_cards?: string[];      // 关联卡片 ID
}

type CardType =
  | 'daily_guidance'      // 每日指引
  | 'bazi_insight'        // 八字洞察
  | 'action_plan'         // 行动计划
  | 'growth_checkpoint';  // 成长检查点

interface Action {
  content: string;               // 行动内容
  difficulty: 'easy' | 'medium' | 'hard';
  estimated_time?: string;       // 预估时间
  check_method?: string;         // 完成判定方式
}

interface Evidence {
  plugin: string;                // 计算插件来源
  rule_ids: string[];            // 知识库规则 ID
  kb_refs: string[];             // 知识库引用
  computed_at: string;           // 计算时间戳
}
```

---

## 3. 主动服务机制

### 3.1 设计原则

**核心理念**：Push 是"用户订阅的仪式"，不是"平台硬塞的广告"

| 原则 | 实现方式 |
|---|---|
| **Why me, why now** | 每条推送必须解释触发原因 |
| **One action** | 每条推送只包含一个核心行动 |
| **Opt-out** | 一键关闭/调整频率 |
| **时机尊重** | 用户可定制接收时间，静默时段不打扰 |

### 3.2 推送类型

| 类型 | 触发条件 | 内容模板 | 频率 |
|---|---|---|---|
| 每日能量卡 | 用户设定时间 | 今日关键词 + 能量指数 + 1个行动 | 1次/天 |
| 计划提醒 | 加入计划后 | 今日任务提醒 + 进度鼓励 | 1次/天 |
| 关键时点 | 命理事件触发 | 事件解读 + 应对建议 | 按需 |
| 复盘邀请 | 周末 | 本周回顾引导 + 反馈收集 | 1次/周 |

### 3.3 每日推送示例

```
┌─────────────────────────────────────────────┐
│ ☀️ 早安，[用户名]                            │
├─────────────────────────────────────────────┤
│ 【今日能量】                                │
│                                             │
│ 今天是戊辰日，与你的日主形成相生关系。      │
│ 这是一个适合"播种"的日子——                │
│ 启动新项目、学习新技能、建立新习惯。        │
│                                             │
│ 🎯 今日一个行动：                           │
│ 写下一个你想培养的新习惯，哪怕只是一句话。  │
│                                             │
│ [开始今天] [稍后提醒] [关闭推送]            │
└─────────────────────────────────────────────┘
```

### 3.4 积极心理学计划

**计划列表（MVP 版本）**：

| 计划名称 | 周期 | 核心练习 | 来源理论 |
|---|---|---|---|
| 21天感恩练习 | 21天 | 每日记录3件感恩事项 | 积极心理学 |
| 7天正念入门 | 7天 | 每日5分钟呼吸练习 | 正念冥想 |
| 习惯养成挑战 | 30天 | 追踪一个新习惯 | 原子习惯 |
| 优势发现之旅 | 14天 | 识别并应用个人优势 | VIA优势理论 |

**计划结构**：

```yaml
plan:
  id: "PLAN-001"
  name: "21天感恩练习"
  duration_days: 21
  daily_task:
    title: "今日感恩"
    description: "写下3件今天让你感恩的事，可以是大事也可以是小事"
    min_items: 3
    prompts:
      - "今天谁帮助了你？"
      - "今天有什么让你微笑的时刻？"
      - "今天你完成了什么让你自豪的事？"
  milestones:
    - day: 7
      message: "你已经坚持了一周！感恩练习正在重塑你的大脑回路。"
    - day: 14
      message: "两周了！你可能开始注意到自己更容易发现生活中的美好。"
    - day: 21
      message: "恭喜完成！感恩已经成为你的新习惯。考虑继续保持？"
  bazi_integration:
    # 根据八字特点定制提示
    木旺: "你天生敏锐，更容易感知到生活中的新机会——今天注意到了什么？"
    火旺: "你热情洋溢，人际关系是你的宝藏——今天谁让你感到温暖？"
```

---

## 4. 数据架构

### 4.1 数据库 Schema（MVP 增量）

```sql
-- 用户偏好表（新增）
CREATE TABLE fortune_user_preferences (
    user_id INTEGER PRIMARY KEY REFERENCES fortune_user(user_id),
    persona_style VARCHAR(20) DEFAULT 'standard',  -- standard/warm/roast
    push_enabled BOOLEAN DEFAULT true,
    push_time TIME DEFAULT '08:00:00',             -- 每日推送时间
    push_timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '07:00:00',
    active_plans JSONB DEFAULT '[]',               -- 已加入的计划 ID 列表
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 成长计划进度表（新增）
CREATE TABLE fortune_plan_progress (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES fortune_user(user_id),
    plan_id VARCHAR(50) NOT NULL,                  -- 计划标识
    start_date DATE NOT NULL,
    current_day INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'active',           -- active/paused/completed/abandoned
    daily_records JSONB DEFAULT '[]',              -- 每日记录数组
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 每日指引表（新增）
CREATE TABLE fortune_daily_guidance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES fortune_user(user_id),
    guidance_date DATE NOT NULL,
    card_data JSONB NOT NULL,                      -- GuidanceCard JSON
    prescriptions_status JSONB DEFAULT '[]',       -- 处方完成状态
    feedback JSONB,                                -- 用户反馈
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, guidance_date)
);

-- 八字知识库表（新增）
CREATE TABLE bazi_knowledge (
    id VARCHAR(50) PRIMARY KEY,                    -- 如 GJ-001, SS-001
    category VARCHAR(50) NOT NULL,                 -- 格局/十神/神煞/流年
    name VARCHAR(100) NOT NULL,
    conditions JSONB,                              -- 判定条件
    interpretation JSONB NOT NULL,                 -- 解读内容
    evidence_ref TEXT,                             -- 来源引用
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_bazi_knowledge_category ON bazi_knowledge(category);

-- 对话记忆增强（在现有表基础上）
ALTER TABLE fortune_conversation ADD COLUMN IF NOT EXISTS
    extracted_insights JSONB;                      -- 从对话中提取的洞察
ALTER TABLE fortune_conversation ADD COLUMN IF NOT EXISTS
    emotion_tags JSONB;                            -- 情绪标签
```

### 4.2 Profile 数据结构

```typescript
interface UserProfile {
  // 基础信息（L0 PII）
  user_id: number;
  name: string;
  gender: '男' | '女';
  birthday: string;           // YYYY-MM-DD HH:MM:SS
  location: {
    name: string;
    longitude: number;
    latitude: number;
  };

  // 八字信息（计算结果）
  bazi: {
    pillars: {
      year: string;
      month: string;
      day: string;
      hour: string;
    };
    wuxing: {
      金: number;
      木: number;
      水: number;
      火: number;
      土: number;
    };
    day_master: string;       // 日主
    ten_gods: Record<string, string>;  // 十神
    patterns: string[];       // 格局
    favorable_elements: string[];  // 喜用神
  };

  // 偏好设置
  preferences: {
    persona_style: 'standard' | 'warm' | 'roast';
    push_enabled: boolean;
    push_time: string;
    quiet_hours: {
      start: string;
      end: string;
    };
  };

  // 时间线（L1）
  timeline: {
    past_events: Event[];     // 重要过往事件
    current_goals: Goal[];    // 当前目标
    future_plans: Plan[];     // 未来计划
  };

  // 动态标签（L2）
  tags: {
    life_stage: string;       // 人生阶段
    focus_areas: string[];    // 关注领域
    recent_emotions: string[]; // 近期情绪
  };
}
```

---

## 5. API 设计

### 5.1 新增 API 端点

```yaml
# Chat 相关
POST /api/chat/coach:
  description: "Coach Agent 对话（带 Persona）"
  request:
    user_id: integer
    message: string
    persona_style: string?    # 可选覆盖
  response:
    reply: string
    card?: GuidanceCard
    suggestions?: string[]    # 快捷问题建议

# 每日指引
GET /api/daily/guidance:
  description: "获取今日指引卡"
  params:
    user_id: integer
    date?: string            # 默认今天
  response:
    guidance: GuidanceCard
    plan_tasks?: Task[]      # 当前计划任务

POST /api/daily/checkin:
  description: "每日打卡"
  request:
    user_id: integer
    date: string
    completed_actions: string[]
    mood?: string
    notes?: string
  response:
    status: string
    streak: integer          # 连续天数
    encouragement: string    # 鼓励语

# 成长计划
GET /api/plans:
  description: "获取可用计划列表"
  response:
    plans: Plan[]

POST /api/plans/join:
  description: "加入计划"
  request:
    user_id: integer
    plan_id: string
  response:
    progress: PlanProgress

POST /api/plans/record:
  description: "记录计划进度"
  request:
    user_id: integer
    plan_id: string
    daily_record: object
  response:
    progress: PlanProgress
    milestone?: Milestone

# 八字增强
GET /api/bazi/full-analysis:
  description: "完整八字分析（含知识库）"
  params:
    user_id: integer
  response:
    basic: BaziBasic          # 四柱五行
    ten_gods: TenGods         # 十神分析
    patterns: Pattern[]       # 格局判断
    dayun: Dayun[]            # 大运信息
    liunian: Liunian          # 当前流年
    shenshas: Shensha[]       # 神煞
    summary: GuidanceCard     # 综合交付卡

# 用户偏好
GET /api/user/preferences:
  description: "获取用户偏好"
  params:
    user_id: integer
  response:
    preferences: UserPreferences

PUT /api/user/preferences:
  description: "更新用户偏好"
  request:
    user_id: integer
    preferences: Partial<UserPreferences>
  response:
    preferences: UserPreferences
```

### 5.2 Coach Agent Prompt 模板

```python
COACH_SYSTEM_PROMPT = """
你是 Fortune AI 的对话 Agent，角色是积极心理学教练（Performance Coach）。

## 你的职责
1. 用温暖、赋能的语言表达后端的专业命理分析
2. 引导用户理解自己、做出决策、采取行动
3. 作为销售/客服，解答产品问题，引导完善 Profile
4. 作为助教，引导用户加入成长计划

## 当前语言风格：{persona_style}
- standard：清晰、中性、专业
- warm：温暖、共情、支持性
- roast：直接、辛辣、带幽默感（但不伤害）

## 硬性规则
1. 绝不使用恐吓性语言
2. 绝不做确定性宿命论断言
3. 每个洞察必须配合行动建议
4. 负面信息必须包含"但你可以..."的转折

## 用户上下文
姓名：{user_name}
八字摘要：{bazi_summary}
当前关注：{current_focus}
近期情绪：{recent_emotions}
已加入计划：{active_plans}

## 对话历史
{conversation_history}

## 后端分析结果（如有）
{backend_analysis}

请以 Coach 的身份回应用户。
"""
```

---

## 6. 前端技术实现

### 6.1 页面结构（HTML）

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Fortune AI - 人生导航</title>
  <link rel="stylesheet" href="/static/mvp.css" />
</head>
<body>
  <div class="app">
    <!-- 顶栏 -->
    <header class="header">
      <div class="brand">Fortune AI</div>
      <div class="user-pill" id="user-pill">
        <span class="user-name">--</span>
        <span class="user-bazi">--</span>
      </div>
      <div class="actions">
        <button class="btn-icon" id="btn-settings">⚙️</button>
      </div>
    </header>

    <!-- 主布局 -->
    <main class="layout">
      <!-- 左侧栏：会话历史 + 快捷入口 -->
      <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">
          <button class="btn-new" id="btn-new-chat">+ 新对话</button>
        </div>
        <div class="sidebar-section">
          <div class="section-title">快捷入口</div>
          <button class="quick-btn" data-action="daily">📅 今日指引</button>
          <button class="quick-btn" data-action="plan">🌱 成长计划</button>
          <button class="quick-btn" data-action="report">📊 八字报告</button>
        </div>
        <div class="sidebar-section">
          <div class="section-title">历史会话</div>
          <div class="session-list" id="session-list"></div>
        </div>
      </aside>

      <!-- 中央：对话区 -->
      <section class="chat-area">
        <div class="thread" id="thread"></div>
        <div class="input-area">
          <div class="suggestions" id="suggestions"></div>
          <form class="input-form" id="chat-form">
            <button type="button" class="btn-icon" id="btn-tools">+</button>
            <textarea id="input-text" placeholder="说点什么..." rows="1"></textarea>
            <button type="submit" class="btn-send">发送</button>
          </form>
        </div>
      </section>

      <!-- 右侧：功能区 Bento -->
      <aside class="bento" id="bento">
        <nav class="bento-tabs">
          <button class="tab active" data-panel="profile">档案</button>
          <button class="tab" data-panel="report">报告</button>
          <button class="tab" data-panel="daily">每日</button>
          <button class="tab" data-panel="plan">计划</button>
        </nav>
        <div class="bento-panels">
          <!-- Panel: Profile -->
          <div class="panel active" id="panel-profile">
            <!-- 内容见 2.2.2 -->
          </div>
          <!-- Panel: Report -->
          <div class="panel" id="panel-report">
            <!-- 内容见 2.2.2 -->
          </div>
          <!-- Panel: Daily -->
          <div class="panel" id="panel-daily">
            <!-- 内容见 2.2.2 -->
          </div>
          <!-- Panel: Plan -->
          <div class="panel" id="panel-plan">
            <!-- 内容见 2.2.2 -->
          </div>
        </div>
      </aside>
    </main>
  </div>

  <script src="/static/mvp.js"></script>
</body>
</html>
```

### 6.2 响应式设计

```css
/* 移动端适配 */
@media (max-width: 768px) {
  .layout {
    flex-direction: column;
  }

  .sidebar, .bento {
    position: fixed;
    z-index: 100;
    transform: translateX(-100%);
    transition: transform 0.3s;
  }

  .sidebar.open { transform: translateX(0); }
  .bento {
    transform: translateX(100%);
    right: 0;
  }
  .bento.open { transform: translateX(0); }

  .chat-area {
    width: 100%;
    height: 100vh;
  }
}

/* 平板适配 */
@media (min-width: 769px) and (max-width: 1024px) {
  .sidebar { width: 200px; }
  .bento { width: 280px; }
}

/* 桌面端 */
@media (min-width: 1025px) {
  .sidebar { width: 240px; }
  .bento { width: 360px; }
}
```

---

## 7. 关键业务流程

### 7.1 新用户首次使用流程

```
用户访问
    │
    ▼
┌─────────────────────────────────┐
│ Coach: 欢迎来到 Fortune AI！    │
│ 我是你的人生导航助手。          │
│ 让我先了解一下你...             │
└─────────────────────────────────┘
    │
    ▼
[引导填写基础信息]
    │ 姓名/性别/出生日期时间/地点
    │
    ▼
[自动计算八字]
    │
    ▼
┌─────────────────────────────────┐
│ Coach: 很高兴认识你，{name}！   │
│ 根据你的八字，你是一个...       │
│ [简短性格描述]                  │
│                                 │
│ 想先了解什么？                  │
│ 1️⃣ 今日运势                     │
│ 2️⃣ 完整八字分析                 │
│ 3️⃣ 开始一个成长计划             │
└─────────────────────────────────┘
    │
    ▼
[根据选择引导下一步]
```

### 7.2 每日使用循环

```
┌──────────────────────────────────────────────────┐
│                   用户日常循环                    │
└──────────────────────────────────────────────────┘
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    ▼                   ▼                   ▼
[推送触发]         [主动访问]         [计划提醒]
    │                   │                   │
    ▼                   ▼                   ▼
┌─────────┐       ┌─────────┐       ┌─────────┐
│今日能量卡│       │ 自由对话 │       │任务完成卡│
└─────────┘       └─────────┘       └─────────┘
    │                   │                   │
    ├───────────────────┴───────────────────┤
    │                                       │
    ▼                                       ▼
[执行行动处方]                        [记录反馈]
    │                                       │
    └───────────────────┬───────────────────┘
                        │
                        ▼
                [数据沉淀到记忆层]
                        │
                        ▼
                [优化下次推荐/分析]
```

### 7.3 八字深度分析流程

```
用户请求深度分析
        │
        ▼
┌───────────────────────────────────────┐
│           Orchestrator 编排           │
└───────────────────────────────────────┘
        │
        ├──────────────────────────────────────────┐
        │                                          │
        ▼                                          ▼
┌───────────────┐                        ┌───────────────┐
│ Bazi Engine   │                        │ Knowledge Base│
│ 确定性计算    │                        │ 规则检索      │
├───────────────┤                        ├───────────────┤
│ - 四柱推导    │                        │ - 格局匹配    │
│ - 十神计算    │                        │ - 十神解读    │
│ - 大运流年    │                        │ - 神煞含义    │
│ - 五行分析    │                        │ - 流年模板    │
└───────────────┘                        └───────────────┘
        │                                          │
        └────────────────┬─────────────────────────┘
                         │
                         ▼
              ┌───────────────────┐
              │ Interpretation    │
              │ 解读包合成        │
              ├───────────────────┤
              │ - 命理解释        │
              │ - 心理学框架      │
              │ - Coach 行动处方  │
              └───────────────────┘
                         │
                         ▼
              ┌───────────────────┐
              │ LLM Synthesis     │
              │ 语言生成          │
              ├───────────────────┤
              │ - Persona 风格    │
              │ - 积极表达        │
              │ - 结构化输出      │
              └───────────────────┘
                         │
                         ▼
              ┌───────────────────┐
              │ Guidance Card     │
              │ 交付卡渲染        │
              └───────────────────┘
                         │
                         ▼
              [返回给用户 + 存储]
```

---

## 8. 北极星指标（MVP 版本）

### 8.1 L1 北极星：WCG（Weekly Closed-loop Guidance）

**定义**：用户在一周内完成一次"触发 → 指引 → 行动 → 反馈"闭环

| 闭环要素 | MVP 判定口径 |
|---|---|
| Trigger | 每日推送点击 / 用户发起对话 / 打开指引卡 |
| Guidance | 生成并展示 GuidanceCard |
| Action | 勾选完成 ≥1 个处方项 |
| Feedback | 记录完成/情绪反馈 |

**MVP 目标**：`WCG > 0.3/周人`（30% 周活用户完成闭环）

### 8.2 L2 过程指标

| 指标 | 定义 | MVP 目标 |
|---|---|---|
| DAU/MAU | 日活/月活比 | > 20% |
| Profile 完整度 | 填写完整基础信息的用户比例 | > 80% |
| 推送点击率 | 每日推送的点击率 | > 15% |
| 计划参与率 | 加入任一计划的用户比例 | > 30% |
| 计划完成率 | 完成计划的用户/加入用户 | > 20% |

### 8.3 L3 质量指标

| 指标 | 定义 | MVP 目标 |
|---|---|---|
| NPS | 净推荐值 | > 30 |
| 幻觉投诉率 | 用户反馈"不准"的比例 | < 5% |
| 负面情绪触发率 | 回复导致用户情绪恶化的比例 | < 1% |

---

## 9. 技术实现路线

### 9.1 MVP 开发任务清单

**Phase 1：基础设施（Week 1-2）**

- [ ] 数据库 Schema 迁移（新增表）
- [ ] 八字知识库结构化（PDF → YAML/JSON）
- [ ] Bazi Engine 增强（十神/格局/大运/神煞）
- [ ] 知识库检索服务实现

**Phase 2：后端 API（Week 2-3）**

- [ ] Coach Agent Prompt 模板设计
- [ ] `/api/chat/coach` 实现
- [ ] `/api/daily/guidance` 实现
- [ ] `/api/plans/*` 系列实现
- [ ] `/api/bazi/full-analysis` 实现
- [ ] 用户偏好 API 实现

**Phase 3：前端重构（Week 3-4）**

- [ ] 新 MVP 页面框架（Chat + Bento）
- [ ] Profile 面板实现
- [ ] 八字报告面板实现
- [ ] 每日指引面板实现
- [ ] 成长计划面板实现
- [ ] 响应式适配

**Phase 4：主动服务（Week 4-5）**

- [ ] 推送调度器实现
- [ ] 每日能量卡生成逻辑
- [ ] 计划提醒逻辑
- [ ] 推送偏好管理

**Phase 5：测试与优化（Week 5-6）**

- [ ] 单元测试覆盖
- [ ] 集成测试
- [ ] Persona 风格 A/B 测试
- [ ] 性能优化
- [ ] 埋点与指标看板

### 9.2 技术栈确认

| 层 | 技术选型 | 说明 |
|---|---|---|
| 前端 | HTML/CSS/JS（原生） | 继承现有架构，渐进增强 |
| 后端 | FastAPI（Python） | 继承现有架构 |
| 数据库 | PostgreSQL | 继承现有架构 |
| LLM | Gemini / Claude | 通过 backend_router 切换 |
| 八字计算 | lunar_python | 继承现有实现 |
| 知识库 | YAML/JSON + PostgreSQL | 新增结构化存储 |

---

## 10. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|---|---|---|
| 知识库质量不足 | 解读不准确 | 专家审核 + 用户反馈迭代 |
| Persona 风格不当 | 用户体验差 | A/B 测试 + 默认保守风格 |
| 推送打扰用户 | 用户流失 | 默认关闭 + 明确 Opt-in |
| LLM 幻觉 | 信任度下降 | 结构化 RAG + 证据绑定 |
| 负面情绪触发 | 舆情风险 | 危机词检测 + 转介提示 |

---

## 11. 附录

### 11.1 参考文档

- `system_design_codex_v3.md` - 顶层设计基线
- `qa1.md` - 产品 Q&A
- `knowledge/bazi/*.pdf` - 八字知识来源

### 11.2 术语表

| 术语 | 定义 |
|---|---|
| Coach Agent | 前端对话 AI 角色，积极心理学/Performance Coach 定位 |
| Bento | 功能区 UI 范式，多 Tab 面板布局 |
| Guidance Card | 交付卡，包含结论/依据/处方的结构化输出 |
| WCG | Weekly Closed-loop Guidance，周度闭环指引 |
| Persona | 语言风格配置（standard/warm/roast） |
| Timeline | 用户人生时间线（Past/Plan/Goal） |

### 11.3 变更日志

| 版本 | 日期 | 作者 | 变更 |
|---|---|---|---|
| 1.0 | 2025-12-29 | Claude | 初版 MVP 设计 |
