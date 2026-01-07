Purpose
  - 作为 Codex 全局规范，统一“索引预加载→基于任务与上下文选择→先懒加载正文和制定计划→经确认后再开始执行”的技能工作流，并内置 Skills Creator 能力，确保高相关、可控与可审计。

Scope & Precedence
  - 适用范围：所有 Codex 工作区与用户主目录。
  - 不得违背“索引预加载 / 选择后加载 / 显式确认计划再执行”三大原则。
  - Skills索引 ~/.codex/skills.json
  - Skills文件目录 ~/.claude/skills

Language & Typography
  - 标题、小节名与键名使用英文；正文内容使用中文。
  - 代码、命令、路径使用等宽英文并用反引号包裹。
  - 禁止中英混排的标题与键名；统一使用 SKILL.md（大写）作为技能主文档文件名。

Index Preload (必读)
  - 每次 Codex 启动或新会话创建时，必须立即在后台异步预加载 ~/.codex/skills.json，构建只读内存索引；
  - 仅全量载入技能元数据（如 name/description/version 等），不读取任何技能正文；

Triggers & Selection
  - 精确触发词：当用户输入包含精确词 skill 时，必须启动技能机制，依据用户意图与目标从内存索引选取合适技能；若无匹配，明确告知“暂无合适技能”。其他情况下 Agent 可基于上下文按 best‑effort 原则自发决定是否建议候选技能。
  - 选择并计划：复述目标，加载你选的最为匹配的SKILL.md的全文，展开并注入到上下文,结合用户输入制定计划

Confirmation & Execution
  - 用户确认选择的技能及计划，按照SKILL.md其中的指示开始执行。
  - 在重要或可能改写数据的操作前，先输出 1–2 句预告说明（影响范围、输入输出、幂等策略）。

Skills Creator (Integrated)
  - 目标：“创建/更新/删除/打包/索引维护/校验”统一流程与安全边界。
  - 命令约定（均需以 skill 精确触发；默认只干跑）：
      - skill create <name> [--desc ...] [--tags ...] [--scope user|project] [--simulate|--apply]
      - skill update <name> [--field value...] [--simulate|--apply]
      - skill remove <name> [--archive|--apply]
      - skill rename <old> <new> [--simulate|--apply]
      - skill template <name> [--print]（仅输出模板，不写入）
      - skill lint [<name>|--all]（结构校验）
      - skill index [--verify|--rebuild]（索引核对/重建，只读优先）
      - skill package <name> [-o <zip>]（只读打包）
  - 命名规范：<role>-<skill>（kebab‑case，≤64 字符）；目录名=name；与 SKILL.md: name 一致。
  - 创建流程（分级执行）：
      - 校验 ID 与命名 → 生成 SKILL.md front‑matter（最小三键）与正文骨架 → 计划写入路径（~/.claude/skills/<name> ）→ 更新Skills索引 ~/.codex/skills.json。
  - 更新/重命名：
      - 同步校验 front‑matter 与目录名一致性，变更时自动生成索引更新。
      - 重命名需维护“旧名→新名”映射并告知潜在引用方。
  - 删除（安全优先）：
      - 默认逻辑删除：从索引移除并移动至 ~/.claude/skills/_archive/<name>-<ts>；物理删除需再次确认。
  - 索引维护（双向一致）：
      - 写入前对 ~/.codex/skills.json 做备份→校验 schema→原子替换；失败回滚。
      - 任何目录变更必须同步索引；任何索引变更必须有目录对应，保证强一致。
  - 校验门槛：
      - skill lint 必须通过（front‑matter 三键、固定段落、命名一致、描述长度≤200 中文字符、可选键格式合法）方可进入 apply。
  - 审计与版本：
      - 变更均写入 JSONL 审计，记录差异摘要与校验和；version 采用语义化版本；Changelog 段记录要点。

Other Commands
  - 发现与规划（不读取正文）：
      - 用户输入：list skills, 输出内存中预加载的skill列表。
      - 用户输入：update skills, 遍历~/.claude/skills中所有SKILL.MD，读取并更新技能的Frontmatter(元数据)到~/.codex/skills.json，不得改变skills.json的format, 并刷新内存中预加载的skill列表。
        <examaple>
        ---
        name: dev-spec
        description: 所有与specs模式的系统构建、规划、编程相关的工作。
        version: 0.1.0
        ---
        </examaple>
      - 用户输入：skill plan <brief-goal> → 输出候选清单与计划草案，等待确认。
  - 选择与加载（读取正文）：
      - 用户输入：skill <skill name> → 读取并加载 <skill name>/SKILL.md，指定执行计划，等到用户明确确认再执行。


Creation & Governance
  - 新建/更新/删除技能时，必须把~/.claude/skills中的Frontmatter(元数据)更新到 ~/.codex/skills.json。
  - 命名规范：<role>-<skill>（kebab-case，≤64 字符）；目录名需与 name 一致。
  - 变更日志：建议在 SKILL.md 的 Changelog 段记录版本与要点。

Security
  - 默认最小权限：禁网、禁安装新包，不写系统目录。
  - 需要提升权限时，必须在预告中明确说明范围与风险，并记录到审计日志。

Rationale (关键机制回顾)
  - 预加载索引是为“快而准”的候选筛选与解释服务；不读取正文避免早期上下文污染。
  - 仅在用户确认你选择的skill和计划之后，才按SKILL.md中的指令执行。