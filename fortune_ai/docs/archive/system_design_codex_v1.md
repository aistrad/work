# system_design_codex_v1

基于 `docs/architech/concenpt design.md`、`docs/architech/survey real expert.md`、`docs/architech/survey social.md`、`docs/architech/survey other product.md` 的交叉分析，形成该系统顶层设计。本文统一将产品代号称为 **DaoMind**。

## 1. 核心战略与价值主张 (Strategic Core)

- **市场空白与机会点**：竞品在“情绪价值、仪式感与行动抓手”上存在断层，AI产品偏冷、易幻觉、缺少可执行建议，而真人服务的高信任与高温度无法规模化（见 `docs/architech/survey real expert.md`）；社交平台用户期待“高颜值、可分享、可参与的仪式化内容”，且视觉资产具备传播性（见 `docs/architech/survey social.md`）；主流产品仍偏解释或报告，缺乏“行动处方”和“主动服务”闭环（见 `docs/architech/survey other product.md`）。机会在于：以确定性算法保证可信度，以主动服务和仪式化任务承接情绪与决策，在关键时刻提供“可执行”的陪伴（见 `docs/architech/concenpt design.md`）。
- **核心价值主张 (UVRA)**：**用可验证的命理计算与可执行的行动处方，把“被动算命”升级为“主动陪伴式决策支持”，让用户在关键时刻被理解并获得具体行动路径。**（基于 `docs/architech/survey real expert.md` 与 `docs/architech/concenpt design.md`）
- **北极星指标 (North Star Metric)**：**每周完成一次“主动推送 → 行动处方 → 情绪反馈”闭环的用户数（或比例）**，衡量系统是否真正把“解释”转化为“行动与陪伴”（与 `docs/architech/survey social.md` 的仪式化趋势及 `docs/architech/survey other product.md` 的行动缺口相对应）。

## 2. 用户画像与需求洞察 (Persona & Needs)

- **核心用户画像**（基于真人服务洞察与社交舆情）：
  - **P1：情绪波动的都市年轻人（以女性为主）**：高频使用小红书/TikTok，重视视觉表达与社交货币；对“被看见、被理解”有强需求，愿意通过仪式与内容来安抚焦虑（见 `docs/architech/survey social.md`）。
  - **P2：关键决策型用户（职业/情感/财务）**：关注解释的逻辑链与决策背书，希望“给出可执行方案”，并对隐私与可信度高度敏感（见 `docs/architech/survey real expert.md` 与 `docs/architech/survey other product.md`）。

- **痛点-痒点-爽点分析**：
  - **痛点**（必须解决）：AI结论偏冷且不稳定、缺乏行动抓手；真人服务价格高、效率低、难持续（见 `docs/architech/survey real expert.md`）。
  - **痒点**（潜意识欲望）：身份认同与社交展示需求、对“好运壁纸/仪式互动”的迷恋、希望通过“参与动作”获得掌控感（见 `docs/architech/survey social.md`）。
  - **爽点**（即时满足）：主动推送命中当下情绪 + 给出可执行清单 + 生成高颜值可分享内容（见 `docs/architech/concenpt design.md` 与 `docs/architech/survey social.md`）。

- **用户旅程地图 (User Journey)**：
  1. **触发与发现**：被社交内容种草或处于情绪低谷（情绪：好奇/焦虑）。
  2. **入门与信任建立**：填写生辰/偏好，看到可信算法与隐私承诺（情绪：谨慎/期待）。
  3. **首次高价值输出**：个性化报告与情绪共情文案（情绪：被看见）。
  4. **主动服务介入**：关键时刻推送“运势预警 + 行动处方 + 仪式任务”（情绪：安心/掌控）。
  5. **深度互动与复访**：关系实验室、情感咨询、长期记忆回顾（情绪：依赖/信任）。
  - **Moment of Truth**：**首次主动推送准确命中用户情绪，并给出可执行行动与温度表达的瞬间**（与 `docs/architech/concenpt design.md` 的“主动服务”理念与 `docs/architech/survey real expert.md` 的“温度差异”对应）。

## 3. 系统功能架构设计 (Functional Architecture)

- **前台 (Client-Side)**
  - **个性化入门**：生辰采集、偏好与语气选择（严师/温柔）。
  - **神谕流与视觉资产**：每日运势卡、好运壁纸、灵宠/头像生成。
  - **主动服务中心**：关键星象/运势触发的推送与提醒。
  - **AI顾问对话**：多人格对话、情境问答、可解释行动建议。
  - **行动处方与仪式**：电子木鱼、冥想音频、任务清单、完成反馈。
  - **关系实验室**：合盘、幽灵档案、关系剧本与沟通建议。
  - **情绪日志与回顾**：心情追踪、周期回看、成长叙事。
  - **社交分享与接龙**：好运接龙、分享卡片、社交裂变入口。

- **中台 (Business Logic / Service Layer)**
  - **用户画像与长期记忆**：情绪状态机、偏好与生命周期管理。
  - **确定性命理引擎**：八字/紫微/占星/六爻计算与可解释输出。
  - **触发与规则引擎**：主动服务策略、事件调度、优先级控制。
  - **RAG知识库**：古籍与现代心理文本的混合检索。
  - **LLM编排与语气控制**：工具调度、人格化输出、结构化生成。
  - **视觉生成服务**：高一致性风格的AIGC图像生成与缓存。
  - **行动处方引擎**：将运势转化为任务清单与仪式行动。
  - **社交图谱与分享**：关系链、隐私边界、可分享素材管理。
  - **合规与风控**：内容安全、反迷信与反恐吓话术守护。
  - **支付与订阅**：会员、报告付费、虚拟资产与积分。

- **后台 (Admin / Operations)**
  - **内容与规则配置**：文案库、触发阈值、提示词模板管理。
  - **合规审查与黑词库**：风险话术审核、审计记录。
  - **专家与真人服务管理**：认证、排班、质检与复盘。
  - **运营与增长**：活动配置、裂变链路与A/B实验。
  - **数据分析与监控**：漏斗、留存、北极星指标看板。

## 4. 关键业务流程设计 (Key Business Flows)

1) **主动服务闭环（从“提醒”到“行动”）**
   - 计算引擎每日批处理/实时触发，生成个体化“运势事件”。
   - 规则引擎筛选重要事件并匹配“行动处方 + 温度文案”。
   - LLM结合RAG输出“可解释建议”，推送至用户。
   - 用户完成仪式/任务（冥想、沟通话术、今日宜忌清单）。
   - 记录情绪反馈与结果，更新个性化模型。
   - **自动化替代真人环节**：把真人“主动提醒+安抚+建议”转化为可规模化的主动推送与行动任务，同时保留“关怀语气”（见 `docs/architech/concenpt design.md` 与 `docs/architech/survey real expert.md`）。

2) **情感危机深度咨询（AI分诊 + 人机协同）**
   - 用户进入“情感求助”，系统用导问卡收集关键情境（替代冷读的显式化问法）。
   - 确定性命理引擎输出结构化事实；RAG提供解释背景。
   - LLM生成“情绪共情 + 行动计划 + 风险提示”三段式建议。
   - 高风险或高价值请求触发真人专家可选入口，系统提供上下文摘要。
   - **自动化保持温度**：通过情绪回访与语气选择维持“被陪伴”的感觉（见 `docs/architech/survey real expert.md`）。

## 5. 技术架构原则 (Technical Architecture Principles)

- **系统稳定性与扩展性**：
  - **确定性计算与生成式服务分层**，核心命理计算服务可独立扩展；LLM与AIGC服务采用异步队列与缓存，确保高并发下的稳定响应（见 `docs/architech/concenpt design.md`）。
  - **事件驱动架构**：主动服务采用事件流与定时调度，避免实时高峰拥塞；多端推送采用幂等机制与降级策略。
  - **可解释性与一致性**：关键结论必须可回溯到算法与知识库证据，减少“幻觉”造成的信任损耗（见 `docs/architech/survey real expert.md`）。

- **数据隐私与安全**：
  - **最小化采集 + 本地化处理优先**：生辰与地理信息加密存储，敏感字段本地/私有云处理，避免外泄风险（见 `docs/architech/concenpt design.md` 与 `docs/architech/survey real expert.md`）。
  - **合规护栏**：对“恐吓、宿命论、赌博引导”等内容进行规则拦截与提示替换，维护合法边界（见 `docs/architech/survey real expert.md`）。
  - **用户可控权利**：清晰的同意流程、可撤回授权与数据删除机制，建立信任感。

## 6. 差异化竞争壁垒 (The Moat)

- **“确定性算法 + 主动服务 + 行动处方”三位一体**：解决“AI冷、真人贵”的结构性矛盾（见 `docs/architech/survey real expert.md` 与 `docs/architech/concenpt design.md`）。
- **仪式化体验与高颜值内容资产**：将社交平台的“好运壁纸/接龙/电子功德”转化为产品内循环与裂变（见 `docs/architech/survey social.md`）。
- **长期记忆与情绪数据网络效应**：越用越懂用户，形成高迁移成本与信任粘性（见 `docs/architech/survey other product.md`）。
- **合规与信任护城河**：以心理咨询式表达替代迷信话术，降低监管与口碑风险（见 `docs/architech/survey real expert.md`）。
