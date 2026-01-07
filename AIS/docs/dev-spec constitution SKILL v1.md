---

## **name: dev-spec description: 适用【dev】；当采用规格驱动的 specs 模式进行系统或功能构建/规划/修改时触发；用于从需求澄清→设计→任务拆分→实现→验证的规范化交付；输入包含目标、范围、约束、技术栈与验收口径；输出规格文档、设计稿、任务清单与变更日志；默认先计划，确认后执行。**

# **Overview and Intent**

## **本技能的意图 (Intent of this Skill)**

本技能（Skill）旨在将严格的、规范驱动的软件开发方法论，形式化为一个可供 AI 代理（Agent）执行的、可审计的流程。

**核心理念 (Core Philosophy):** 本流程将“规范”（Specification）视为可执行的蓝图。其核心是“意图驱动开发”（Intent-driven development），首先在 requirements.md 中明确“构建什么”，然后在 design.md 中规划“如何构建”，最后在 tasks.md 中分解“执行步骤”。

本技能的主要功能是充当项目“宪法”的*执行者*，确保 AI 代理的开发活动严格遵守既定规程，防止“代理漂移”（agent drift）或创造性的误解。

## **核心原则 (Core Principles)**

* **1\. 宪法是不可变的第一性原理 (Constitution as Immutable First Principle):** ./claude/specs/CONSTITUTION.md（系统宪法）是项目的最高纲领，定义了不变的愿景、哲学和核心领域架构。所有后续的演进（新功能、修改）都**必须**（MUST）通过“合宪性审查”1。  
* **2\. 规范是唯一的真相来源 (Spec is the Single Source of Truth):** design.md 中的“详细执行流程设计”（Detailed Execution Flow Design）是所有代码实现的**权威参考**1。代码**必须**（MUST）与此设计保持1:1的一致性。  
* **3\. 强制上下文感知 (Mandatory Context-Awareness):** 在开始任何任务之前，**必须**（MANDATORY）对**父级或相关项目目录**进行全面的项目发现和分析1。  
* **4\. 严格的阶段性审批 (Strict Gated Approval):** 工作流程划分为 A/需求、B/设计、C/任务三阶段。每阶段**必须**执行“预览→确认→落盘”：在写入前先输出将写入的文件清单与摘要预览，只有当用户明确选择“确认”时才写入；写入完成后**必须**询问是否进入下一阶段，统一确认选项为\[确认/修改/回退/取消\]1。Workflow 0（上下文分析）为只读且自动执行，不设确认闸门。  
* **5\. 日志和验证的优先性 (Logging and Validation First):** 全面的日志记录（Logging）和计算验证（Computational Validation）不是事后添加的，它们是**需求阶段**的核心组成部分1，并在**设计和实施**中被强制执行1。

# **Quick Start**

## **工作流程触发 (Workflow Invocation)**

这是一个端到端（end-to-end）的规范创建或修改技能。

1. **用户 (Human):** 提出一个系统蓝图(System Spec)，或功能特性想法（feature idea），或修改意见。  
2. **AI代理 (Agent):** (在执行工作流程 0 上下文分析后) **必须**（MUST）首先判断并且向用户确认此想法是**创建新项目**，**创建新功能**还是**修改现有功能**。  
   * **如果创建新项目:** 代理**必须**（MUST）要求用户显式提供 system\_spec\_path（不设默认路径），通读后生成 ./claude/specs/CONSTITUTION.md1；按需与用户确认是否在 ./claude/specs/ 下为各限界上下文（Bounded Contexts）创建子目录（例如 ./claude/specs/\<context\_name\>/）。  
   * **如果创建或修改新功能:** 代理**必须**（MUST）确认这个功能所属模块的目录 ./claude/specs/\<feature\_name\>/，并通读其中所有文件（若存在）。  
3. **AI代理 (Agent):** 自动执行 Workflow 0（只读上下文分析），不会写入或修改任何文件。  
4. **阶段执行约束:** 对 A/需求、B/设计、C/任务，均遵循“预览→确认→落盘”：阶段开始前先展示将写入的文件清单与摘要预览，仅在用户选择“确认”后写入；写入完成后询问是否进入下一阶段，并提供\[确认/修改/回退/取消\]1。  
5. **AI代理 (Agent):** 在获得最终批准后，工作流程结束。所有工件（artifacts）将位于 ./claude/specs/（顶层 CONSTITUTION.md \+ 限界上下文/功能子目录）中。

**注意:** 本技能**只负责**（ONLY）创建或更新规划工件。代码实现是一个独立于此的后续流程。

# **Workflows / Function / Inputs / Outputs**

## **工作流程 0: (强制) 项目上下文分析 (Workflow 0: Mandatory Project Context Analysis)**

* **描述:** 这是在任何规范或编程任务开始之前的\*\*强制性（MANDATORY）\*\*前提步骤1。  
* **触发:** 任何新功能请求的开始。  
* **输入:** 系统蓝图(System Spec)，或功能特性想法（feature idea），或修改意见（隐式输入为**本目录，和父级或相关项目目录**）。  
* **功能 (MANDATORY):**  
  1. 代理**必须**（MUST）彻底阅读并理解**本目录，和父级或相关项目目录**下的**所有**项目1。  
  2. **必须**（MUST）系统地遍历目录，理解现有项目结构和架构。  
  3. **必须**（MUST）识别可重用的组件、库、数据模型、模式、依赖关系和已建立的最佳实践1。  
  4. 代理**必须**（MUST）必须完整读取用户提供的输入，如 system spec 文档，新功能文档，或修改意见；结合对相关项目的理解，返回你对用户的目标，核心原则，资源和技术规约限制，如果是新系统/功能，还包括这个新系统/功能完整的输入，输出，功能及核心流程的理解描述1。  
* **输出:**  
  1. （内部）对用户的目标，核心原则，资源和技术规约限制，如果是新系统/功能，还包括这个新系统/功能完整的输入，输出，功能及核心流程的理解描述。  
  2. **必须**（MUST）在后续的需求、设计和实施阶段，在文档中明确记录（Document）哪些现有组件被重用、借鉴了哪些模式，以及新功能如何与现有系统集成1。

### **下一步 (Next Step)**

* 本步骤为只读且自动执行。完成后，展示阶段 A/需求的“将写入文件清单与摘要预览”，等待用户确认进入阶段 A。

## **新项目流程：宪法生成 (New Project Constitution Flow)**

* **宗旨 (Purpose):** 核心任务是“提炼”和“固化”蓝图中的**第一性原理**与**核心领域**，而不是“创造”需求。此阶段生成的 CONSTITUTION.md（系统宪法）是后续所有**演进式开发**的最高纲领1。  
* **输入 (Inputs):**  
  * system\_spec\_path（必填）：用户显式提供的 System Spec 文件路径；不设默认路径1。  
* **功能 (Functions):**  
  1. **定位与读取 System Spec（MANDATORY）**：严格使用用户提供的 system\_spec\_path 完整读取蓝图全文；除非用户明确要求“列举候选”，否则不进行目录扫描与默认选择1。  
  2. **第一性原理提炼**：从 System Spec 中提炼以下“**不变基石**”与“**演进蓝图**”的核心章节（详见文末 CONSTITUTION.md 模板）：  
     * (不变) 1\. 系统愿景与哲学 (Foundation Vision & Philosophy)  
     * (不变) 2\. 核心领域与架构原则 (Core Domain & Architectural Principles)  
     * (演进) 3\. 战略性领域划分 (Strategic Bounded Contexts)  
     * (演进) 4\. 演进式发展蓝图 (Evolutionary Roadmap & MVP)  
  3. **预览与门控**：在任何写入前输出预览与影响范围1：  
     * 将写入：./claude/specs/CONSTITUTION.md  
     * 变更摘要：各章节要点（每节≤10行）与“优化建议”清单  
     * 可选：拟创建的限界上下文（Bounded Context）目录列表 ./claude/specs/\<context\_name\>/  
     * 仅在用户选择“确认”后落盘。  
  4. **写入策略（幂等）**：  
     * 若 CONSTITUTION.md 不存在：直接创建。  
     * 若已存在：默认不覆盖；生成 CONSTITUTION.draft.\<ts\>.md 并展示 diff，用户选择【保留/合并/覆盖】后再原子替换1。  
  5. **可选模块骨架**：经确认后，可在 ./claude/specs/\<context\_name\>/ 下按需生成 requirements.md、design.md、tasks.md 的空白骨架（含最小头部与占位目录索引）1。  
  6. **可追溯性**：生成 ./claude/specs/constitution.report.json，记录来源路径、哈希、创建时间、章节完整度与模块索引1。  
* **输出 (Outputs):**  
  * ./claude/specs/CONSTITUTION.md  
  * 可选的 ./claude/specs/\<context\_name\>/ 目录骨架  
  * ./claude/specs/constitution.report.json

## **新功能流程：规范化交付 (New Feature Flow)**

* **范围:** 适用于在已存在的 ./claude/specs/CONSTITUTION.md 基础上，在某个“限界上下文”（Bounded Context） 内新增功能。  
* **路径:** 依次执行“工作流程 1/2/3”，产物均落在 ./claude/specs/\<feature\_name\>/ 下（requirements.md → design.md → tasks.md），并在必要时将模块索引登记/更新到 CONSTITUTION.md 的“结构映射”1。  
* **前置检查 (MANDATORY):** **必须**（MUST）执行“合宪性审查”：加载 CONSTITUTION.md，校验新功能是否违背“核心领域与架构原则”1。

## **修改流程：合宪性审查与变更记录 (Modify Flow)**

* **输入:**  
  * ./claude/specs/\<feature\_name\>/ 目标模块路径  
  * 变更动机与范围说明（必须可追溯到需求/缺陷/风险）1  
* **功能:**  
  1. **加载文档**：读取 ./claude/specs/CONSTITUTION.md 与目标模块的 requirements.md / design.md / tasks.md1。  
  2. **合宪性校验 (MANDATORY)**：评估拟变更是否违背“不变基石”（愿景、核心领域、架构原则、技术约束）1；如存在冲突，**必须**（MUST）停止并向用户报告冲突，寻求决策。  
  3. **差异预览**：生成各文件的差异摘要；写入前展示“影响范围 \+ 关键变更”1。  
  4. **变更记录**：在 ./claude/specs/changes/YYYYMMDD-\<slug\>.md 写入变更说明（动机、决策、评审者、受影响模块、回滚方案）；更新模块索引1。  
  5. **门控**：遵循“预览→确认→落盘”，对覆盖性写入一律先生成 \*.draft.\<ts\>.md 并要求明确确认1。  
* **输出:** 更新后的模块文档与变更记录文件。

## **工作流程 1: 需求收集 (Workflow 1: Requirements Gathering)**

* **描述:** 创建或迭代 requirements.md 文件，直到用户批准。  
* **输入:** 用户的初始功能想法；./claude/specs/CONSTITUTION.md 已存在且目标模块目录（./claude/specs/\<feature\_name\>/）已确认。  
* **功能:**  
  1. **合宪性审查 (MANDATORY):** **必须**（MUST）加载 CONSTITUTION.md，确保本需求在对应的“限界上下文”（Bounded Context） 边界内，且不违背“不变基石”1。  
  2. **必须**（MUST）**加载或创建** ./claude/specs/{feature\_name}/requirements.md 文件1。  
  3. **必须**（MUST）根据功能想法，**加载现有文档进行修改**（如果修改）或**生成初始版本**（如果新建）。不得（MUST NOT）在未加载或生成文档前先进行顺序提问1。  
  4. **必须**（MUST）遵循特定格式，包括：  
     * 用户故事（User Story）1。  
     * 使用 **EARS 格式**（Easy Approach to Requirements Syntax）的验收标准1。  
  5. **必须**（MUST）包含一个**强制性的日志记录要求 (Mandatory logging requirements)** 部分1，详细说明需要记录的事件、日志级别（DEBUG, INFO, WARN, ERROR, FATAL）、格式、保留策略等。  
  6. 代理**必须**（MUST）专注于核心需求，避免功能蔓延（feature creep）1。  
* **门控 (GATING):**  
  1. 写入前预览：先输出“将写入文件清单与摘要预览”，提示：将写入:./claude/specs/{feature\_name}/requirements.md；是否执行？\[确认/修改/取消\]；仅在选择“确认”时执行写入1。  
  2. 写入后审批：代理**必须**使用 userInput（reason: spec-requirements-review）请求审批1；若未获明确批准，依据反馈修改并再次预览与确认。  
  3. 阶段结束闸门：需求已落盘。询问“是否进入阶段 B/设计？”；选项\[确认/回退/取消\]1。  
* **输出:** 经用户批准的 ./claude/specs/{feature\_name}/requirements.md。

## **工作流程 2: 设计文档创建 (Workflow 2: Design Document Creation)**

* **描述:** 基于已批准的需求，创建或更新全面的 design.md。  
* **输入:** 经批准的 requirements.md。  
* **功能:**  
  1. **合宪性审查 (MANDATORY):** **必须**（MUST）加载 CONSTITUTION.md，确保本设计严格遵循“核心领域与架构原则”以及“技术约束”1。  
  2. **必须**（MUST）**加载或创建** ./claude/specs/{feature\_name}/design.md 文件1。  
  3. **必须**（MUST）在 design.md 中包含以下**所有**部分1：  
     * Overview  
     * Architecture (必须说明如何符合 CONSTITUTION.md 中的架构原则)  
     * **Detailed Execution Flow Design (这是最关键的部分)** 1  
     * Components and Interfaces  
     * Data Models  
     * Directory Structure (必须分离核心代码、测试和临时文件)1  
     * Logging Architecture (全面的日志设计)1  
     * Error Handling  
     * Testing Strategy  
     * Documentation Synchronization Plan  
  4. **详细执行流程设计 (Detailed Execution Flow Design):** 此部分**必须**（MUST）作为所有代码修改的**权威参考**1。**必须**（MUST）包含：操作的逐步流程、决策点（branching logic）、错误处理路径、数据流、**每个操作步骤的日志记录点和日志级别**1、以及性能监控点。  
* **门控 (GATING):**  
  1. 写入前预览：展示设计大纲、关键接口/表结构与数据流预览，提示：将写入:./claude/specs/{feature\_name}/design.md；是否执行？\[确认/修改/回退/取消\]；仅在选择“确认”时写入1。  
  2. 写入后审批：代理**必须**使用 userInput（reason: spec-design-review）请求审批1；未获明确批准则依据反馈修订并再次预览与确认。  
  3. 阶段结束闸门：设计已落盘。询问“是否进入阶段 C/任务？”；选项\[确认/回退/取消\]1。  
* **输出:** 经用户批准的 ./claude/specs/{feature\_name}/design.md。

## **工作流程 3: 实施规划 (Workflow 3: Implementation Planning)**

* **描述:** 基于已批准的设计，创建或更新可操作的 tasks.md 编码任务清单。  
* **输入:** 经批准的 design.md。  
* **功能:**  
  1. **必须**（MUST）**加载或创建** ./claude/specs/{feature\_name}/tasks.md 文件1。  
  2. **必须**（MUST）将设计文档转换为一系列用于代码生成LLM的**严格的测试驱动 (strict test-driven)** 提示1。  
  3. **必须**（MUST）将 tasks.md 格式化为**编号的复选框列表**（最多两级层次结构）1。  
  4. **自动测试与验证 (Automated Testing & Validation):**  
     * tasks.md **必须**（MUST）遵循TDD（测试驱动开发）方法。  
     * 对于每个功能组件或关键逻辑，任务必须（MUST）按以下顺序明确定义1：  
       a. 任务：自动生成单元测试/集成测试（例如，使用 pytest）。  
       b. 任务：编写/修改实现代码。  
       c. 任务：执行（运行）生成的测试并验证结果，确保代码通过测试并符合“详细执行流程设计”中定义的计算验证要求。  
  5. 每个任务项**必须**（MUST）是可操作的（编写、修改、测试代码），并**必须**（MUST）包含1：  
     * 对 requirements.md 中具体需求的引用。  
     * 关于文件放置位置的**目录组织说明**。  
     * **直接映射到 design.md 中“详细执行流程设计”的特定步骤**。  
  6. **必须**（MUST）包含用于**全面计算验证 (Comprehensive computational validation)** 和**内存安全 (Memory safety / overflow prevention)** 的特定测试任务1。  
  7. **分阶段的代码审查和验证 (Phased Code Review and Validation):** tasks.md **必须**（MUST）被划分为逻辑阶段或主要功能里程碑。  
     * 在每个阶段的末尾，**必须**（MUST）包含一个**强制性的“阶段性审查”任务** (Mandatory Phase Review task)。  
     * 此审查任务必须（MUST）明确指示对该阶段实现的代码进行验证，确保1：  
       a. 代码与设计的1:1一致性审查 (Design-to-Code Consistency Review)。  
       b. 实际代码执行完全（exactly）遵循“详细执行流程设计”的相关步骤。  
* **门控 (GATING):**  
  1. 写入前预览：展示里程碑（M0/M1/M2）与 DoD、任务清单摘要，提示：将写入:./claude/specs/{feature\_name}/tasks.md，并在 changelog.md 追加记录；是否执行？\[确认/修改/回退/取消\]；仅在选择“确认”时写入并追加变更记录1。  
  2. 写入后审批：代理**必须**使用 userInput（reason: spec-tasks-review）请求审批1；未获明确批准则依据反馈修订并再次预览与确认。  
  3. 阶段结束：流程完成；或选择\[回退\]返回设计阶段进行修订，或\[取消\]终止1。  
* **输出:** 经用户批准的 ./claude/specs/{feature\_name}/tasks.md。

## **工作流程 4: 工作流程结束 (Workflow 4: Workflow Completion)**

* **描述:** 在 tasks.md 获得批准后，本技能的工作即告完成。  
* **功能:**  
  1. 代理**必须**（MUST）停止，并**不得**（MUST NOT）尝试执行 tasks.md 中的任何任务1。  
  2. 代理**必须**（MUST）明确通知用户："This workflow is ONLY for creating design and planning artifacts. The actual implementation... should be done through a separate workflow. You can begin executing tasks by opening the tasks.md file."1。  
* **输出:** 流程终止。

## **交互模板 (Interaction Templates)**

* 标准确认提示（写入前一律先展示）  
  将写入: \<paths\>；关键变更: \<summary\>。是否执行？\[确认/修改/回退/取消\] 1  
* 选项语义  
  * 确认：执行写入（幂等；覆盖前展示差异）。  
  * 修改：停留在当前阶段，接受修订后再次生成预览。  
  * 回退：返回上一阶段并以其文档为真源进入修订流。  
  * 取消：立即终止，不做任何写入。 1

## **写入安全 (Write Safety & Idempotency)**

* 作用域：仅写入 ./claude/specs/（顶层 CONSTITUTION.md 与 ./claude/specs/{\<context\_name\>...}/ 模块子目录）；不改动代码实现或其他技能文件1。  
* 幂等策略：写入前展示 diff；必要时生成带时间戳的备份；采用原子写入避免中断1。  
* 日志与遮蔽：确认提示与日志中隐藏密钥等敏感信息1。

# **Scripts / Reference / Best Practices / Integration Points**

## **最佳实践与核心原则 (Best Practices & Core Principles) (Mandatory Reference)**

* **1\. 执行流程一致性 (Execution Flow Consistency)**  
  * Detailed Execution Flow Design 是**权威规范**1。  
  * **任何**（Any）代码修改都**必须**（MUST）伴随对执行流程设计的相应更新1。  
  * **必须**（MUST）包含验证任务，以核实实际程序执行与文档化的流程在**每一步**都完全匹配1。  
* **2\. 全面的日志记录 (Comprehensive Logging)**  
  * **必须**（MUST）实施 design.md 中设计的日志架构1。  
  * 日志级别 (Log Levels): **必须**（MUST）支持 DEBUG, INFO, WARN, ERROR, FATAL1。  
  * 结构化日志 (Structured Logging): **必须**（MUST）使用一致的格式（推荐JSON），包含时间戳、级别、组件名和消息1。  
  * **必须**（MUST）记录性能指标、执行时间、详细的错误堆栈跟踪和审计跟踪 (Audit Trail)1。  
* **3\. 严格的测试与验证 (Rigorous Testing and Validation)**  
  * **必须**（MUST）实施严格的**逐步计算验证 (Step-by-Step Calculation Verification)**，核实1：  
    * 每个计算步骤都符合需求的数学预期。  
    * 业务逻辑符合规定的业务规则。  
    * 算法实现符合算法设计规范。  
  * **必须**（MUST）实施**内存安全 (Memory Safety)** 和**资源管理**验证，以防止1：  
    * 内存溢出 (Buffer overflows, stack overflows, heap overflows)。  
    * 资源泄漏 (Memory leaks, file handle leaks)。

## **参考: 项目与目录结构 (Reference: Project & Directory Structure)**

(内容同 1，未修改)

## **参考: 技术栈与数据库 (Reference: Technology Stack & Database)**

(内容同 1，未修改)

## **参考: 权限设置 (Reference: Permission Settings) (Action Directives)**

(内容同 1，未修改)

## **集成点 (Integration Points)**

* **userInput 工具:**  
  * spec-constitution-review (用于批准宪法 \- **新流程需要**)  
  * spec-requirements-review (用于批准需求)1  
  * spec-design-review (用于批准设计)1  
  * spec-tasks-review (用于批准任务)1  
* **文件 I/O:**  
  * （读/写）./claude/specs/CONSTITUTION.md 与 ./claude/specs/{\<context\_name\>...}/  
* **System Spec 提供:**  
  * 新项目场景下，system\_spec\_path 必须由用户显式输入；不设任何默认路径。若用户要求，可辅助列举 docs/ 等目录的候选文件供选择，但不自动选取1。  
* **项目上下文 (Project Context):**  
  * （只读）**父级或相关项目目录**  
    1

## **【已优化】Templates: CONSTITUTION.md（系统宪法）**

用途：作为从用户项目蓝图到整个项目实施的最高纲领文件；位置：./claude/specs/CONSTITUTION.md。  
优化说明：此模板已根据“不变基石”与“演进式架构”的原则重构。第一部分定义了不可变的第一性原理，第二部分定义了系统如何演进。

Front‑matter（可选）

\---  
source: \<system\_spec\_path\>  
created\_at: \<ISO8601\>  
hash: \<sha256-of-source\>  
\---

# **第一部分：不变的基石 (The Immutable Foundation)**

*此部分定义了系统的“第一性原理”。它们在项目的整个生命周期中都应保持稳定。所有“第二部分”的演进都不得违背此处的原则。*

## **1\. 系统愿景与哲学 (Foundation Vision & Philosophy)**

* **愿景 (Vision):** \<从 system spec 精炼的、一句话的最终目标。例如：构建一个“半自主”的、由AI增强的“Cyborg 投研平台”1。\>  
* **哲学 (Philosophy):** \<系统的核心价值观或交互范式。例如：“人机协同 (HITL) 优于完全自主”；“事前治理优于事后审计”1；“明确确认再开始执行”1。\>

## **2\. 核心领域与架构原则 (Core Domain & Architectural Principles)**

* **核心领域 (Core Domain):** \<定义系统存在的根本理由和最关键的业务逻辑。例如：AISCend 的核心领域是“L3/L2/L1分层治理模型”1本身，它隔离了智能、接口和执行。\>  
* **架构特性 (Architectural Characteristics):** \<支撑核心领域所需的、不可协商的非功能性需求。\>  
  * **可审计性 (Auditability):** aiscend PostgreSQL 数据库是唯一的、基于PostgreSQL的数据基石与单一事实来源 (SSOT)1。所有操作必须可追溯1。  
  * **安全性 (Security):** 严格执行 HITL 审批闸门1。  
  * **可演进性 (Evolvability):** 架构必须支持通过“限界上下文”进行增量式、解耦的功能扩展。  
* **技术规约 (Immutable Constraints):** \<必须执行（MUST）和严格禁止（FORBID）的技术决策。\>  
  * MUST: L3 必须使用 codex Agent 编排框架1。  
  * MUST: L1 必须使用本地部署的 QuantConnect Lean1。  
  * FORBID: 严禁使用 langgraph 等全自主代理方案1。

# **第二部分：演进式架构与发展蓝图 (The Evolutionary Architecture)**

*此部分定义了系统“如何”随时间演进。所有内容都必须符合“第一部分”的约束。*

## **3\. 战略性领域划分 (Strategic Bounded Contexts)**

*基于 DDD，系统被划分为以下独立的“限界上下文”，每个上下文都可以独立演进。*

* **上下文 A：**  
  * **职责:** \<此上下文的核心职责。例如：处理“量化基本面” (Quantamental) 策略1。\>  
  * **映射:** ./claude/specs/strategy-vf/  
* **上下文 B：**  
  * **职责:** \<例如：处理“规则驱动” (Rule-heavy) 的量化策略1。\>  
  * **映射:** ./claude/specs/strategy-s-b2/  
* **上下文 C：**  
  * **职责:** \<例如：处理“元组合管理”和“IB API交易执行”1。\>  
  * **映射:** ./claude/specs/execution/  
* **(更多上下文...)**

## **4\. 演进式发展蓝图 (Evolutionary Roadmap)**

*此蓝图规划了“限界上下文”的交付顺序，从 MVP 开始，所有步骤均由“第一部分”的愿景指导。*

* **MVP (最小可行产品):**  
  * **目标:** \<验证“第一部分”核心愿景所需的最简功能闭环。例如：实现一个“上下文C”的单一交易，该交易由“L3 Codex”发起，经“L2 API”传递，由“L1 Lean”执行，并包含完整的“HITL审批”1。\>  
  * **核心特性:** \<实现 MVP 目标所需的核心特性列表。\>  
* **Phase 1 (第一阶段):**  
  * **目标:** \<例如：上线第一个创收的“限界上下文A (Strategy-VF)”1。\>  
  * **核心特性:** \<...列表...\>  
* **Phase 2 (第二阶段):**  
  * **目标:** \<例如：上线“限界上下文B (Strategy-S-B2)”1，验证架构对不同类型策略的兼容性。\>  
  * **核心特性:** \<...列表...\>  
* **未来愿景 (Future Vision):** \<高阶目标，例如：开放“限界上下文”接口，允许第三方PM开发自己的策略。\>

## **5\. 变更治理与合宪性审查 (Change Governance)**

* **治理流程:** 所有对 CONSTITUTION.md 之外的模块（requirements.md, design.md）的“新增”或“修改”**必须**（MUST）触发“合宪性审查”流程（见 dev-spec 的“修改流程”）1。  
* **审查依据:** 审查**必须**（MUST）验证变更是否：  
  1. 违背“第一部分”的任何“愿景、哲学、原则或规约”？  
  2. 破坏了“第二部分”已定义的“限界上下文” 之间的边界？  
* **宪法修正:** 对 CONSTITUTION.md（特别是第一部分）的任何修改都**必须**（MUST）通过最高级别的人工审批（例如CTO/PM），并重新触发所有上下文的合规性基线。

#### **Works cited**

1. AIscend system spec.txt