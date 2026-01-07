第一部分：执行蓝图：AIScend 系统架构——从专家知识到自主型阿尔法

1.1 核心使命：连接投资智慧与 AI 技术的桥梁

本 AIS (AI System) 架构设计的最终目标，是严格遵循并实现一个核心使命：将“顶级投资智慧 × 前沿 AI 与数据技术”有效转化为一个系统化的投研决策系统 [用户查询 - 使命]。该系统的设计宗旨是持续创造长期、稳定、低回撤的超额收益，并以高透明度和强治理性为基础，服务于我们的投资策略框架。
这一投资框架融合了四大因子维度：“商业质地 (Business)”、“趋势 (Trend)”、“价值 (Value)”和“动量 (Momentum)”（B/T/V/M）[用户查询 - 投资策略]。这种“量化基本面 (Quantamental)”的混合模式 (1)，在架构层面提出了一个核心的、极具挑战性的张力：
1. 价值 (V) 与动量 (M) 因子：在概念上是高度结构化和数学化的。它们可以相对直接地从结构化数据（例如 aiscend 数据库中的 ticker_price 和 f_valuation_multiple 表 (3)）中派生出来。
2. 商业 (B) 与趋势 (T) 因子：如用户示例（“有远见且富执行力的创始人”、“以客户为中心的文化”、“巨大的竞争优势”）所描述，这些因子本质上是定性的、抽象的和叙事驱动的 (4)。它们并不存在于整洁的数据库列中，而必须从海量的非结构化数据（如 doc_text (3) 中的公司年报、财报电话会议记录、员工评论 (6)）中推断出来。
因此，AIS 的首要技术挑战是实现**“定性分析的系统化”**。系统必须成为一个真正的“量化基本面”引擎，不仅能处理 V/M 因子的数字信号，还能以同等的严谨性、可复现性和规模化，来处理 B/T 因子的定性洞察。
这一挑战直接导向了本架构的核心设计决策：aiscend 数据库 (3) 提供了捕获定性洞察所需的原始非结构化数据（如 doc_text, doc_embedding）和初步结构化的见解（如 segment_entity）。而技能（Skills）机制 (7) 作为“编码化专家知识 (Know‑How)”的承载层，通过 `~/.codex/skills.json` 索引加载，技能内容唯一真源保存在 `AIS/domain/<domain>/skills/<name>/` 目录；这样既可按需懒加载，又可实现版本化与审计。

1.2 代理范式革命：从 agents.md 到动态技能注册中心

传统的 Agentic 工作流，例如依赖于单一、巨大的 agents.md 或 CLAUDE.md 文件 (9) 来注入所有上下文，在面对资产管理领域（用户查询 2.1）的极端复杂性时，会迅速崩溃。一个包含数百个数据处理规则、因子定义和合规检查的单一提示文件是无法维护、无法审计且性能低下的。
用户查询 [用户查询 2.5] 中提出的核心设计理念——即“AIS 系统的设计是以用 Claude Skills 的方式来全局动态管理 know-how”——是解决这一难题的正确且唯一的途径。Skills 机制 (7) 代表了一种架构上的范式转变，它将代理的通用推理引擎（claude-code-cli 基础模型 (10)）与领域特定的专家知识（模块化的、版本化的 Skills (7)）彻底解耦。
Skills 架构采用“渐进式披露”(Progressive Disclosure) 的模式 (12)：
- L1 (元数据)：Agent 启动时预加载 `~/.codex/skills.json` 的 `name/description/path`（不加载正文）。
- L2 (指令)：技能被触发时，依据 `path` 定位并懒加载其 `SKILL.md` 主体（path 可为目录或文件）。
- L3 (代码与资源)：仅在 L2 指令调用时，才执行 `skills/<name>/scripts/` 中的代码或读取 `references/` 资源；产物/审计遵循 AIS 的 SSoT 规则（写 DB）。
这种解耦架构完美地解决了用户提出的四大 Agentic 挑战 [用户查询 2.1-2.4]：
1. 高度专业化：通过创建精炼、单一职责的技能（例如 skill-analyze-moat-from-10k）来解决，而不是依赖一个庞大、无所不包的提示。
2. 高度数据依赖：通过将数据处理规则（例如，如何正确使用 f_income_statement_quarter (3) 中的 reportedCurrency）硬编码到技能的 L3 scripts/ 中来解决。
3. 系统自主运行：通过使这些 Skills 成为可被外部编排框架（详见第三部分）调用的工具 (Tools) 来解决。
4. 知识反思进化：通过使 Skills 本身成为可版本化 (7)、可审计、可独立升级的资产来解决，而无需触动核心 Agent 引擎。

1.3 融合 AIS v1.0 
(3)
用户提供的 AIS_SYSTEM_DESIGN.txt (3) 文件已经定义了一个卓越的、领域驱动的六域存储库结构（Data, Factor, Strategy, Portfolio, Execution, Risk）和一组相应的 src/ API 协定（例如 src/lean/run.py）。用户查询 [用户查询 3] 明确指出：“AIS 系统调用他们的接口来完成（通过 skills 机制）”。
这一要求揭示了一个健壮的、三层的“稳定栈” (Stable-Stack) 架构：
- L1：执行引擎 (Execution Engines)
  - 描述：经过业界验证的、稳定的开源系统。
  - 示例：用于回测的 Lean 引擎 (3)，用于数据摄取的 Apache NiFi (14)，或用于因子分析的 Alphalens (15)。
- L2：标准化 API 层 (Standardization API)
  - 描述：即 (3) 中的 src/ 目录。这是公司内部的稳定 API 协定，它封装并隔离了 L1 引擎的复杂性。
  - 示例：src/lean/run.py (3) 是系统内部与 Lean 交互的唯一方式。如果 Lean 引擎某天被 Backtrader (16) 替换，只需更新这个 L2 API，所有上层应用均不受影响。
- L3：智能知识层 (Intelligent Know-How)
  - 描述：即 Claude Skills。这是动态的、轻量级的业务逻辑层。
  - 示例：一个 quant-strategy-run-backtest 技能在其 L3 scripts/run.py (7) 中，不会直接导入 lean；它会导入并调用 src.strategy.run.py (L2 API) (3)。
这种分层设计至关重要。它将智能（L3 Skills）与工程（L2 API）分离。这使得 L3 的 Skills 保持轻量级，只专注于*“做什么”（例如，“运行 B/T/V/M 因子的回测”），而将所有复杂的、易变的集成代码（“如何做”*）隔离在 L2 中。claude-code-cli 代理 (9) 只是激活 L3 的“用户”。

表 1：AIS 领域与技能架构矩阵

暂时无法在飞书文档外展示此内容

1.4 “创造者-消费者”飞轮与三类核心用户

用户体验的核心是“用户即是 AIS 系统的创造者，也是消费者使用者” [用户查询 4.3]。基本面 PM、量化 PM 和 CIO 这三类用户 [用户查询 - 标题] 完美地映射了这一“飞轮”效应，并定义了本报告的后续结构：
1. 基本面 PM (创造者 - 智慧)：作为“创造者”，识别定性投资理论。使用 AIS 进行研究，并“创造”出一个可复用的 quant-factor-business 技能——即编码化的投资智慧。
2. 量化 PM (消费者/构建者 - 自动化)：作为“消费者”，使用基本面 PM 的因子技能；作为“构建者”，将其与 V/M 因子结合，构建、回测并“创造”出一个自主运行的 LangGraph 策略——即自动化的投资流程。
3. CIO (消费者/治理者 - 监督)：作为“消费者”，消费所有自主策略的聚合产出（风险和回报）；作为“治理者”，管理策略组合，并作为最终的*“人在回路”(Human-in-the-Loop, HITL)* 批准高风险操作 (19)。
这个飞轮确保了投资智慧（来自 PM）能够被系统化（由量化 PM 构建），并被安全地规模化（由 CIO 监督），从而实现公司的核心使命。
第二部分：基本面基金经理 (PM)：系统化定性阿尔法

本部分的核心是解决用户查询中最具挑战性的任务：将在基本面 PM 头脑中的定性投资理论（“Business”和“Trend”因子），转化为可被 AIS 系统执行、筛选和扩展的系统化因子 [用户查询 - 示例]。
2.1 核心任务：从定性理论到可复用因子

基本面 PM 的任务是“在全球 10000 多只股票中找到这样的公司” [用户查询 - 示例]。这要求 AIS 系统支持两种截然不同但相互关联的工作流：
1. 交互式研究工作流：PM 使用 claude-code-cli (9) 作为其研究助手，对 aiscend 数据库进行深度探索，以形成和验证其投资理论。
2. 自动化因子工作流：PM“创造”[用户查询 4.3] 的最终产物——一个可自主运行的 Claude Skill，该技能封装了其研究过程，并能规模化地应用于全部 10000 只股票，自主产生因子得分。

2.2 研究铸造厂：aiscend 
(3)
aiscend 数据库 (3) 是实现定性分析系统化的基础。它不仅仅是一个数据仓库，更是通过精心策划的数据表，构建了一个专有的数据护城河 (2)。对于基本面 PM 而言，其价值核心在于非结构化和半结构化数据：
- 非结构化原文：doc_info, doc_text, doc_paragraph。这些表存储了 PM 分析所需的核心“养料”：10-K/10-Q 财报、财报电话会议记录、投资者日演示文稿和新闻稿。
- 语义索引：doc_embedding。该表存储了 voyage_embedding 或 gemini_embedding，是执行高效、上下文感知（RAG）搜索的基础。
- 结构化衍生品：segment_entity 和 portfolio_entity。这是 aiscend 数据库中的“隐藏宝石”。它们代表了对非结构化数据进行AI 预处理和结构化提取的成果。例如，segment_entity (3) 已经包含了“业务分部名称”、“竞争对手代码”、“三年预测 CAGR”和“市场份额”等关键定性信息。portfolio_entity (3) 则存储了“质量评分”、“成长评分”和“投资驱动摘要”。
AIS 系统不仅要消费这些衍生表格，更要能更新和创建它们。例如，当一个自主策略运行时，它的最终输出（例如对某股票的 investment_score 和 primary_investment_driver）应被写回 portfolio_entity 表 (3)，从而丰富数据生态。

2.3 开发“商业质地” (B) 因子：护城河、领导力与文化

为了系统化“商业质地”因子 [用户查询 - 投资策略]，PM 将创建一系列 Claude Skills，每个技能负责评估一个特定的定性方面。

2.3.1 技能：business-factor-moat-analyzer (护城河分析)

- 数据源：doc_text (10-K 报告), segment_entity (竞争对手数据), f_financial_ratios_quarter (财务比率)。
- 方法 (技能指令)：
  1. PM 提示：“@claude 使用 business-factor-moat-analyzer 技能分析 $TICKER 的经济护城河。”
  2. SKILL.md (L2) (7) 指导 Agent 在 doc_embedding (3) 上执行 RAG 搜索，查找 doc_type = '10-K' 且包含“竞争优势”、“定价权”、“网络效应”或“无形资产”的段落。
  3. 指导 Agent 查询 segment_entity (3)，获取该 $TICKER 的 direct_competitor_ticker_1 和 company_market_share。
  4. 指导 Agent 查询 f_financial_ratios_quarter (3)，获取 $TICKER 及其主要竞争对手的 grossprofitmargin (毛利率) 和 returnoncapitalemployed (ROCE)。
  5. SKILL.md (7) 内嵌一个“评估标准 (Rubric)”，要求 LLM 综合上述所有信息（定性文本 + 定量财务数据），并根据 Morningstar 等框架 (4) 输出一个标准化的“护城河评分”（例如：宽、窄、无）。
- 架构价值：此设计实现了真正的“量化基本面” (2)。它迫使 LLM 的定性叙事分析（来自 10-K）必须受到硬性财务数据（ROCE 对比）的约束和验证。该 Skill 本身就是可复用的流程知识 (know-how)，确保了护城河分析在所有股票上的一致性。

2.3.2 技能：business-factor-culture-analyzer (企业文化分析)

- 数据源：外部数据 (如 Glassdoor) + doc_text (财报电话会议记录)。
- 方法 (技能指令)：
  1. 此技能在 L3 (12) 层面捆绑了一个脚本：scripts/scrape_glassdoor.py。
  2. 该脚本不会直接调用 requests (易碎)。它会调用标准化的 L2 API：src/data/external_scraper.py。该 L2 API 负责处理认证、会话和解析，它可能在后台使用了像 Apify 或 Thunderbit 这样的商业级抓取服务 (6)，以确保数据的稳定获取。
  3. SKILL.md 指导 Agent 执行此脚本，获取“外部员工情绪评分”。
  4. 同时，Agent 在 doc_text (3) 中搜索 content_type = 'earnings_call_transcript'，寻找管理层对“文化”、“员工”、“人才流失”的评论。
  5. 技能内置的“评估标准”基于 (a) 外部员工评分 和 (b) 内部管理层关注度，给出一个“文化评分”。
- 架构价值：这展示了 Skills 如何通过捆绑脚本 (7) 和调用 L2 API 来安全地扩展 Agent 的能力，引入全新的、专有的外部数据源。这直接解决了“高度数据依赖和数据 know-how” [用户查询 2.2] 的挑战。

2.3.3 技能：business-factor-leadership-analyzer (领导力分析)

- 数据源：doc_info (用于定位股东委托书), doc_text (CEO 致股东信)。
- 方法 (技能指令)：
  1. 此技能基于学术研究 (5)，指导 Agent 查找最新的股东委托书 (Proxy Statement, doc_type = 'DEF 14A')。
  2. 分析高管薪酬结构，评估其是否与长期股东价值（例如，3 年 $TSR$）挂钩，而不是短期指标。
  3. 分析 CEO 致股东信 (doc_type = 'ANNUAL_REPORT')，提取其战略重点，评估其“愿景”和“长期主义”。
  4. “评估标准”基于“薪酬一致性”和“战略清晰度”给出“领导力评分”。

2.4 开发“趋势” (T) 因子：行业与景气度

“趋势”因子旨在量化“未来成长空间巨大的行业” [用户查询 - 示例]。
- 技能：trend-factor-growth-analyzer
- 数据源：segment_entity, f_financial_trends (3)。
- 方法 (技能指令)：
  1. 此技能严重依赖 segment_entity (3) 表中的预处理数据。
  2. Agent 被指导查询 segment_entity，获取公司所有业务分部的 three_year_projected_cage (三年预测 CAGR), projected_market_size_three_year (三年后市场规模) 和 company_market_share (当前市场份额)。
  3. 它根据这些数据计算出一个加权的“行业增长评分”。
  4. 关键交叉验证 (Data Know-How)：仅有叙事是不够的。该 Skill 必须执行一步关键的“数据 know-how” [用户查询 2.2] 验证。它会接着查询 f_financial_trends 表 (3)，检查该公司对应业务的实际 revenue 的 current_trend_direction (当前趋势方向) 是否与 segment_entity 中的叙事（高增长预测）相匹配。
- 架构价值：f_financial_trends (3) 表是对财务数据进行时序分析后（可能由 TimesFM 等模型生成）的预计算结果。一个关键的专家知识 (know-how) 就是绝不孤立地相信定性叙事。此 Skill 将“叙事验证”这一专家流程进行了编码，确保了 T 因子的稳健性。

2.5 “固化”工作流：从 Notebook 到可复用技能

基本面 PM 完成研究后，必须能轻松地将其“固化为 skill” [用户查询 4.1]。
- 用户体验 (UX) 工作流：
  1. 创造 (Create)：PM 在其本地 IDE (如 VS Code) 中工作，使用 claude-code-cli (9) 插件。PM 的工作区有一个 CLAUDE.md (9)，向 Agent 提供了 aiscend 数据库 (3) 的 schema 上下文。
  2. 迭代 (Iterate)：在 Agent 的协助下，PM 以交互方式（可能在 Jupyter Notebook 中）开发出一个 Python 脚本，实现了（例如）“护城河评分”的逻辑。
  3. 固化 (Solidify)：PM 对结果满意，发出指令：“@claude，这个逻辑很好。请将其固化为一个新的 'business-factor-moat-analyzer' v0.1 技能。”
  4. Agent 执行 (Handle)：此时，claude-code-cli Agent 会调用另一个技能：即 Anthropic 提供的内置 skill-creator 技能 (7)。
  5. skill-creator 自动执行以下操作：
  6. a.  在 AIS/Factor/business-factor-moat-analyzer/ 3 路径下创建标准化的目录结构 7。
  7. b.  生成一个 SKILL.md 模板，包含 name 和 description 13。
  8. c.  将 PM 的 Python 逻辑重构并移入 scripts/compute.py 7。
  9. d.  调用 L2 API (src/db/client.py 3)，在 factor_meta 表 3 中注册这个新因子。
  10. e.  （关键步骤）在第四部分将设计的 skill_registry 数据库中注册这个新技能。
- 架构价值：这个工作流真正使 PM 成为了“创造者” [用户查询 4.3]，而无需他们成为 DevOps 专家。Agent 通过 skill-creator (7) 负责脚手架工程，让 PM 专注于投资逻辑。这通过将创造流程本身也封装为技能，解决了“高度专业化和流程 know-how” [用户查询 2.1] 的问题。

表 2：B/T/V/M 因子实施蓝图

暂时无法在飞书文档外展示此内容

第三部分：量化基金经理 (PM)：构建自主型与进化型策略

量化 PM 的角色是“构建者”和“工程师”。他们消费基本面 PM 创造的 B/T 因子技能，构建 V/M 因子技能，并将它们组装成可自主运行、可自我进化的投资策略，以“自动建仓和风控” [用户查询 - 示例]。
3.1 量化 PM 的工具箱：验证与扩展因子技能

量化 PM 首先要确保所有因子——无论是定性的还是定量的——都经过了严格的实证检验。
3.1.1 开发 "Value" (V) 和 "Momentum" (M) 技能

与 B/T 因子不同，V/M 因子是纯粹的定量计算，但它们同样应被封装为 Skills 以实现标准化。
- 技能 (quant-factor-value)：此技能编码了公司对“价值”的特定定义。其 L3 脚本调用 src/factor/compute.py (L2 API) (3)，该 API 负责查询 f_valuation_multiple (3) 以获取 pe_ntm, ev_ebitda_ltm，并查询 f_key_metrics_quarter (3) 以获取 freeCashFlowYield。
- 技能 (quant-factor-momentum)：此技能调用 src/factor/compute.py (3) 来查询 ticker_price (3) 表，并应用标准的 Python 库（如 pandas）计算 3 个月、6 个月和 12 个月价格动量 (25)。

3.1.2 技能：quant-validation-alphalens (自动化因子质检)

这是量化 PM 工作流中的关键质量门控，用于实现“严格分析...及历史回测” [用户查询 4.1]。
- 自动化门控 (Gate)：在 AIS 系统的 CI/CD 流程中，当任何新的因子技能（如 business-factor-moat-analyzer）在 skill_registry（详见第四部分）中被标记为 status = 'beta' 时，此 quant-validation-alphalens 技能将被自动触发。
- 方法 (技能指令)：
  1. 指导 Agent 在 10 年的历史数据上（使用 quant-data-export-to-lean 技能）运行新的“beta”因子技能。
  2. 为 Alphalens (15) 准备所需的因子值和对齐的价格数据 (15)。
  3. 调用 Alphalens (L1) 生成完整的因子分析“泪页”(Tear Sheet) (15)。
  4. 关键智能步骤：指导 Claude Opus 模型（作为 L3 逻辑的一部分）阅读 Alphalens 生成的文本和统计输出（例如，IC 均值、Quintile 收益分布）。
  5. 要求模型以 JSON 格式返回一个结构化的“质检总结”：“该因子是否显示出显著且稳定的 IC？换手率是否过高？Top/Bottom Quintile 收益差是否单调？”
- 架构价值：这创建了一个自动化的因子质量审查流程。它将 (3) 中的 quant-factor "Gate" (3) 从一个手动清单变成了一个可执行的、由 AI 驱动的流程。任何未能通过此 Alphalens 技能验证的因子都不能被提升到 production 状态。

3.2 自主策略的架构：LangGraph 作为编排器

用户查询要求系统能“自动自主运行” [用户查询 2.3, 4.2]，而不是所有行动都由用户对话启动。claude-code-cli (10) 是一个出色的交互式（用户-代理）工具，但对于自主（代理-代理）的、在服务器上长期运行的工作流，我们需要一个多代理编排框架 (Multi-Agent Orchestration Framework) (27)。

3.2.1 编排框架评估 (LangGraph vs. CrewAI vs. AutoGen)

在众多开源框架中 (18)，LangGraph 是满足 AIS 需求的最佳选择。
- AutoGen (29)：专注于灵活的、基于对话的协作。这适用于研究，但不适用于需要严格、可审计执行路径的金融策略。
- CrewAI (30)：优秀，适用于基于角色的、层次化的任务（例如，“分析师”将报告交给“经理”）。但它对于处理投资策略中常见的循环（例如，每月再平衡）和复杂的条件分支（例如，风险熔断）支持不够灵活。
- LangGraph (18)：是构建有状态图 (Stateful Graphs) 的库。这是压倒性的优势，因为投资策略本质上就是一个有状态的图（一个状态机）。
LangGraph 的决定性优势在于其对持久化检查点 (Persistent Checkpoints) 和静态中断 (Static Interrupts) 的原生支持 (33)。这正是实现 CIO 级“人在回路”(HITL) 监督 (19) 所需的技术机制——这在自动交易系统中是不可或缺的合规与安全要求。

表 5：Agent 编排框架对比

暂时无法在飞书文档外展示此内容

3.2.2 自主策略的设计模式 (基于 LangGraph 的代理)

量化 PM 将一个新策略定义为一个 LangGraph 图。
- 示例：“B/T/V/M” 自主策略图 (State Graph)：
  1. 节点 trigger：由定时器（例如，每月第一个交易日）触发。
  2. 节点 run_factors：此节点通过 v1/skills API (7) 调用一系列 Claude Skills：business-factor-moat-analyzer, trend-factor-growth-analyzer, quant-factor-value 和 quant-factor-momentum。
  3. 节点 combine_factors：图中的一个 Python 节点，将四个因子得分聚合成一个最终的 investment_score，并更新 portfolio_entity (3)。
  4. 节点 construct_portfolio：调用 quant-portfolio-core-mmvo 技能 (3)，该技能进而调用 src/portfolio/optimizer.py (L2 API) (3)，以计算目标权重。
  5. 节点 check_risk：调用 quant-risk-basic 技能 (3)，该技能进而调用 src/risk/manager.py (L2 API) (3)。
  6. 条件边 risk_gate：如果 risk_event (3) 被触发 -> 则路由到节点 halt_and_alert_cio。
  7. 节点 generate_orders：如果风险检查通过 -> 则继续。
  8. 节点 human_in_the_loop_gate (关键控制点)：这是架构层面的风险控制。图在此处使用 LangGraph 的“中断”功能暂停 (33)。它将建议的交易写入 portfolio_alloc 表 (3)，状态为 status = 'pending_approval'。然后，图休眠，等待人工批准。
  9. 节点 execute_trades：（仅在收到人工批准后）调用 quant-execution-vwap 技能 (3) 以执行交易。
- 架构价值：此架构完美地平衡了“自主运行” [用户查询 2.3] 与绝对控制 (20)。Claude Skills 是可复用的“知识工具”，而 LangGraph 是使用这些工具的“自主工人”。

3.3 进化循环：编码化反思

用户查询要求“所有流程数据 know-how 还要根据市场环境不断反思进化” [用户查询 2.4]。这是对“自我修正”或“反思”(Reflection) 机制 (36) 的要求。
- “元代理” (Meta-Agent) 设计：
  1. 当一个 LangGraph 策略完成一次运行（例如，一次年度回测，或一个月的实盘交易）后，其性能被完整记录在 run_equity, run_trade 和 run_metric 表 (3) 中。
  2. 设计一个新的自主 Agent，称为**“元代理”或“反思代理” (Reflector Agent)** (37)。
  3. 此“元代理”被设置为在每次策略运行结束时自动触发。它的唯一工作是批评刚刚完成的运行。
  4. “元代理”使用一个专有技能：quant-analysis-reflector。
  5. 技能指令 (Prompt)：“你是一名资深量化 PM。你的策略刚刚产生了这份 run_metric (3) 报告。MaxDD (最大回撤) 为 15%，而 risk/basic/limits.json (3) 中定义的策略风险上限为 10%。请分析 run_trade (3) 日志。是什么导致了这次超额回撤？是对‘动量’因子的过度暴露吗？是某只个股的风险事件吗？请为 Strategy/ 配置 (3) 或 quant-portfolio-core-mmvo 技能的约束 (3) 提出一个具体的、可执行的修改建议。”
- 架构价值 (进化飞轮)：
  1. 这创建了一个有据可查的、闭环的进化循环。“元代理”的输出不是一个聊天消息，而是一个自动生成的、针对策略配置文件的 Git Pull Request。
  2. 量化 PM 的角色从“手动调参”转变为“审查元代理的优化建议”。
  3. 这完全实现了 [用户查询 2.4] 的要求。策略“know-how”（LangGraph 定义）基于市场反馈（回测结果），通过一个 AI 代理（元代理）的编码化反思（quant-analysis-reflector 技能）而不断进化。

第四部分：首席投资官 (CIO)：治理多代理投资组合

CIO 的核心职责是“管理流程，做好组合配置和风控” [用户查询 - 示例]。在 AIS 架构下，CIO 的角色发生了根本性转变：他们不再仅仅管理一个股票投资组合，而是管理一个自主策略（Agent）投资组合。

4.1 新使命：从投资组合经理到 Agent 机群（Fleet）治理者

当“整个基金都用这种模式运作，会有 10 个甚至几十个”自主策略时 [用户查询 - 示例]，CIO 面临着全新的系统性风险 (39)，包括：
- 级联失败 (Cascading Failures)：一个 quant-data 技能中的 Bug 可能导致错误的因子数据，进而污染数十个依赖它的自主策略 (39)。
- 代理蔓延 (Agent Sprawl)：未经协调的代理可能导致重复工作、资源（云成本、API 调用）枯竭 (39)。
- 内容漂移 (Content Drift)：模型输出（例如“护城河评分”）的质量可能随时间悄然下降，导致合规风险 (39)。
因此，CIO 的首要任务是建立一个强大的治理与控制框架 (40)。

4.2 AIS 治理与控制框架

治理不能仅仅依赖于 Agent 的提示（例如，“请注意安全”）；它必须被构建在系统架构之中 (41)。

4.2.1 skill_registry 数据库 (关键新组件)

问题：33 中的 ~/.codex/skills.json 只是一个本地索引。在一个拥有数百个技能、涉及数十名 PM 的组织中，这种基于文件的管理方式是不可持续、无法审计和极其危险的。
解决方案：必须在 aiscend 数据库中创建一个新的、权威的 skill_registry 表。这是所有“know-how”的“单一事实来源”(Single Source of Truth)。
表 3：skill_registry 数据库模式设计

暂时无法在飞书文档外展示此内容

4.2.2 agent_strategy_registry 数据库 (关键新组件)

问题：如果 Skills 是“弹药”，那么自主策略（LangGraph）就是“武器”。CIO 必须有一个所有“武器”的清单。
解决方案：创建一个 agent_strategy_registry 表，用于跟踪机群中的每一个自主策略。
表 4：agent_strategy_registry 数据库模式设计

暂时无法在飞书文档外展示此内容

4.2.3 架构化的“人在回路”(HITL) 工作流

这两个注册中心是实现架构化治理（而非提示化治理）的关键。
- 工作流：
  1. 一个 Skill（例如 quant-execution-vwap (3)）在 skill_registry [表3] 中被其所有者标记：tags = ['high-risk-execution']。
  2. LangGraph 编排器（第三部分）在执行其 execute_trades 节点之前，必须查询 skill_registry 以获取 quant-execution-vwap 技能的元数据。
  3. 编排器检测到 high-risk-execution 标签。
  4. 无论 Agent 的提示是什么，LangGraph 的图逻辑都会强制执行 interrupt (33)，进入 paused_hitl 状态 (33)。
  5. 此状态变更会更新 agent_strategy_registry [表4] 中的 status 字段。
  6. CIO 仪表板（见 4.3）的“治理队列”被触发，向 CIO 或交易员显示一个待处理任务。
  7. CIO/交易员审查 portfolio_alloc (3) 表中的待审交易，并在仪表板上点击“批准”。
  8. 该操作会更新 LangGraph 的状态，使其从中断点恢复执行。
- 架构价值：这是一个“工具调用守门人”(Tool-Call Gatekeeper) (3) 和“超越循环的人”(Human-above-the-Loop) (20) 的典范。治理（标签）与执行（中断）在架构层面被强制关联，实现了绝对的、可审计的控制。

4.3 CIO 指挥中心仪表板 (Command Dashboard) 设计

CIO 需要一个“单一窗口”(Single Pane of Glass) (49) 来监督这个复杂的多代理生态系统 (42)。这个仪表板必须融合投资指标和技术指标。

4.3.1 可观测性技术栈 (Observability Tech Stack)

没有任何一个工具能单独完成此任务。需要一个联邦式的仪表板架构：
1. Langfuse (用于 Agent 可观测性)：Langfuse (53) 是一个开源的 LLM 工程平台。它将用于追踪 (Trace) 每一个 LangGraph 策略的执行。CIO 可以深入挖掘任何一次运行，查看每一步的提示、Token 成本、延迟、Skill 调用以及“元代理”的反思输出。
2. Grafana (用于系统与投资组合可观测性)：Grafana (55) 将作为主要的只读仪表板 UI。它将配置多个数据源：
  - aiscend 数据库：用于展示 run_equity (PnL), risk_event (风险事件) (3) 等投资指标。
  - Langfuse 数据库：用于展示聚合的 AI 成本、Agent 错误率等技术指标 (53)。
3. Streamlit (用于 HITL 交互)：Streamlit (55) 将用于构建可写的、轻量级的 Web 应用。当 CIO 在 Grafana 仪表板上看到一个“待批准”任务时，他们点击链接会跳转到一个 Streamlit 应用，该应用会读取 portfolio_alloc (3)，显示待处理交易，并提供“批准/拒绝”按钮。

表 6：CIO 指挥中心仪表板：KPI 与监控技术栈

暂时无法在飞书文档外展示此内容

第五部分：实施蓝图与核心组件推荐

本部分提供了实现上述架构所需的关键开源技术栈的选型推荐。
5.1 数据摄取层 (Data 领域)

- 挑战：Data 模块需要从外部源 [用户查询 1] 摄取高度多样化（结构化财务数据、非结构化 10-K、新闻流）的数据到 aiscend 数据库 (3)。
- 非结构化数据 (财报, 新闻, 记录)：对于文件和事件流，推荐使用如 Apache NiFi (14) 这样的数据流自动化工具，或 Airbyte (17) 这样的数据集成平台。它们专为处理“下载和初步处理” [用户查询 1] 而设计，可用于填充 doc_info 和 doc_text (3)。
- 结构化数据 (市场, 财务)：对于来自标准数据供应商（FMP (3)）的批量数据，推荐使用标准的 ELT 工具，如 Meltano (14)，来填充 f_* 系列财务表。
- 语义验证 (Data Know-How)：为了编码“数据 know-how” [用户查询 2.2] 并防止数据损坏 (58)，应在摄取管道中使用语义验证。推荐使用 Python 库 Instructor (59)。当从财报中提取数据到 doc_json (3) 时，Instructor 的 llm_validator (59) 可以使用 LLM 来验证提取的 JSON 在语义上是否与源文本匹配（例如，“确保提取的‘收入’字段确实是‘总收入’，而不是‘净收入’”）。

5.2 回测与执行层 (Strategy & Execution 领域)

- 挑战：需要一个可靠的、可被 Skills 调用的执行引擎 [用户查询 3]。
- 回测引擎：(3)(3) 中提到的 Lean 引擎是一个优秀的选择。关键在于坚持 L2 API 架构：quant-strategy 技能必须调用 src/strategy/run.py (3)，而不是直接与 Lean 交互。
- 核心“Know-How”脚本：src/data/lean_export.py (3) 脚本至关重要。它负责将 aiscend (3) 的数据格式化为 Lean 所需的格式。这个脚本本身就是一种数据 know-how，它应该被一个 quant-data-export-to-lean 技能所封装和调用，以确保所有回测使用完全一致的数据。

5.3 Agent 托管与部署平台

- 未言明的挑战：第三部分设计的 100 多个自主 LangGraph 策略，在生产环境中运行在哪里？
- 选项 1：公有云平台：如 Google Vertex AI Agent Builder (60)。
  - 优点：可扩展、受管理。
  - 缺点：供应商锁定；对于一家其全部竞争优势 (IP) 都体现在 Skills 和 aiscend 数据中的基金而言，存在无法接受的数据隐私和 IP 风险。
- 选项 2：开源、自托管平台：如 LocalAI / LocalAGI (61) 或 Huginn (62)。
  - 优点：MIT/Apache 2.0 许可 (61)，完全私有化 (61)，提供 OpenAI 兼容的 API，允许在本地硬件上运行 Agent。
  - 缺点：需要更多的 DevOps 维护。
- 架构推荐：
  - 短期 (原型验证)：立即采用 LocalAI (61)。它使团队能够在安全的、隔离的环境中快速原型化和托管自主 Agent，而不会泄露任何专有数据或技能 (Know-How)。
  - 长期 (生产)：在私有云（例如 AWS VPC 或本地）的 Kubernetes (K8s) 集群上构建一个自定义的 Agent 托管平台。每个 LangGraph 策略 [表4] 作为一个工作流（例如，使用 Argo Workflows）被动态实例化为一个 K8s Pod 集群。这种方法结合了 LocalAI 的隐私性和 Vertex AI 的可扩展性。

5.4 结论性架构愿景：AIScend 作为一个动态投资知识图谱

本报告设计的 AIS 系统，其最终形态远不止是一套工具的集合。通过引入 skill_registry [表3] 和 agent_strategy_registry [表4]，整个 AIS 平台转变为一个统一的、可查询的投资知识图谱 (Investment Knowledge Graph)。
在这个图谱中：
- 节点 (Nodes) 包括：aiscend 表、src/ API、Skills、自主 Agent 策略以及 PM (用户)。
- 边 (Edges) 是由 dependencies [表3] 和 linked_skill_versions [表4] 字段定义的依赖关系。
这种架构将公司的核心智力资产——即“顶尖投资智慧” [用户查询 - 使命]——从分散在 PM 头脑中、Jupyter Notebook 和“一次性”脚本中的隐性知识，转变为一个集中、可审计、可治理的显性数字资产。
CIO 不再需要猜测。他们可以直接查询这个知识图谱，以获得架构层面的答案：
- “如果我们弃用 quant-factor-momentum v1.2 [表3]，哪些正在运行的自主策略 [表4] 会受到影响？”
- “显示所有依赖 business-factor-culture 技能（由即将离职的 PM X 拥有 [表3]）的策略。”
- “追溯上周导致 risk_event (3) 的交易：它是由哪个 Agent [表4] 触发的？该 Agent 当时调用了哪个版本的 quant-risk 技能 [表3]？”
这个设计最终实现了公司的使命。它创造了一个活的、进化的系统，其中投资智慧 (Skills) 和自动化流程 (Agents) 被统一管理，使公司能够以传统方法无法企及的规模和严谨性，去发现、验证和执行产生阿尔法（Alpha）的策略。