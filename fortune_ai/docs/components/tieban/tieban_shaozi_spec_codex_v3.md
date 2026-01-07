# Tieban × Shaozi 双核系统规格说明书（Spec Codex v3）

**版本**：v3.0  
**状态**：Draft（规格冻结后可进入实现）  
**范围**：完整描述 `Tieban 12k（铁板）` 与 `Shaozi 6k/6144（邵子）` 的“双核驱动 + 交叉考刻（Calibration）闭环”系统设计，包括：算法边界、数据模型、ETL、API、日志与审计。  
**架构基线**：Context Driven / Pluggable Modules（参见 [os_design_v3.md §1.4](../os/os_design_v3.md#14-context-驱动架构-可插拔模块视图)）  
**最高输入依据（来源文档）**：
- `fortune_ai/docs/tieban shaozi kaoke v5.md`（双核 + 交叉考刻主张）
- `fortune_ai/docs/tieban_spec_codex v2 ultra.md`（起数/考刻/接口雏形）
- `fortune_ai/docs/tieban_spec_codex v2 deep.md`（真太阳时/节气/算法严谨化）
- `fortune_ai/docs/research tieban2.md`（铁板 96 刻、天干取数、合化等）
- `fortune_ai/docs/research tieban3.md`（邵子 12 集×64 组×8 条的编排与规则片段）
- `fortune_ai/docs/洛阳派神数条文.md`（6144 条邵子诗句样本/可作为主条文源）
- `fortune_ai/docs/tieban_kb_design.md`（KB 与 ETL 的工程化方案）

---

## 0. 核心结论（必须先接受的事实）

铁板与邵子不是“同一套库不同算法”，而是**两套同源但异构的系统**：

- **系统 A：Tieban 12k（铁板）**
  - **容量**：约 12,000（或 1..13,000 区间内有效条文）
  - **结构**：线性 `strip_id -> content`，可按 `%96` 与 `+96` 形成“流年流（stream）”
  - **优势**：适合“流年推演/时间轴输出”，以及与“加减秘数”相关的搜索
- **系统 B：Shaozi 6k/6144（邵子）**
  - **容量**：6144（12 集 × 512；512 = 64 组 × 8 条）
  - **结构**：三维坐标 `set_id(集) -> group_id(组) -> line_id(条)` 的矩阵索引
  - **关键约束**：**男女分卷（group 1..32 男；33..64 女）**
  - **优势**：适合“格局总断/定性输出”，且结构确定性可用于辅助铁板考刻

因此 v3 的系统目标不是“用一个算法统一两套库”，而是：

1) **双核分工明确**：Tieban 负责“流年/流月/运势序列”；Shaozi 负责“格局/定性/结构化定位”。  
2) **交叉考刻闭环**：利用 Shaozi 的“确定性矩阵”先锁定刻分候选，再用 Tieban 的六亲事实做精锁与校验。  
3) **可审计与可回放**：每次考刻必须生成“路径记录”，保证可复盘。

---

## 1. 非目标（v3 明确不做）

- 不承诺“玄学准确性”，仅承诺：**算法可执行、输入输出可解释、过程可验证、数据可审计**。
- 不在 v3 中实现真实生产数据库与 ETL 的完整落地代码（可作为 v4 交付）。
- 不在 v3 中“发明缺失条文”（缺失数据必须显式标记，不得 AI 生成替代真源）。

---

## 2. 统一术语（Glossary）

- `Session`：一次从输入到出书的会话（可多轮交互）。
- `Normalization`：输入时间/历法/四柱标准化（含真太阳时、节气边界等）。
- `Ke`：一时辰 8 刻（每刻 15 分钟），记为 `line_id ∈ [1..8]`。
- `Base`：铁板起数得到的基数（如 `2521`），用于 Tieban 引擎检索与推演。
- `Modulo-96`：基数对 96 取模，用于与 96 刻结构对齐（细节因派别可配置）。
- `Secret Keys / 秘数`：铁板考刻时用于“非线性跳跃”的加减因子集合（由资料与配置给出）。
- `Set / 集（set_id）`：邵子 12 集，对应地支：`子=1 ... 亥=12`。
- `Group / 组（group_id）`：邵子每集 64 组（男女分卷：1..32 男；33..64 女）。
- `Line / 条（line_id）`：邵子组内 8 条，对应 8 刻（1..8）。
- `raw_code`：邵子原始编码（如 `1111`、`6124`、`10111` 等）。
- `hexagram_idx`：64 卦序号（1..64），用作“卦气/组”的计算输入（可配置）。

---

## 3. 总体架构（Dual-Kernel + Orchestrator）

### 3.1 组件

1) `Input Normalizer`
   - 输入：出生时间（行政时间）、地点（经纬度）、性别、可选：已知事实（父母生肖等）
   - 输出：标准化四柱、边界标记、刻分候选窗口

2) `Engine-S (Shaozi Coordinate Engine)`
   - 输入：`set_id`、`gender`、`hexagram_idx`（或等价卦气）、`line_id`
   - 输出：邵子诗句（格局总断候选）与结构化标签（若可解析）

3) `Engine-T (Tieban Arithmetic Engine)`
   - 输入：标准化四柱 + `line_id`（刻分/刻序）+ 规则配置
   - 输出：Tieban 六亲校验候选、锁定 `Base`、以及 `+96` 的推演序列（流年/流月）

4) `Calibration Orchestrator`
   - 管理 Session 状态机、候选集合、交互题目、评分与路径记录

5) `Knowledge Base`
   - `KB_Tieban_12k` 与 `KB_Shaozi_6144` **物理隔离**
   - 额外：规则表与审计表（见 §7）

### 3.2 会话状态机（最小可用）

`INIT`
→ `NORMALIZED`
→ `S_PRELOCK`（Shaozi 先行：确定 set/group，生成 8 条候选）
→ `S_LINE_SELECT`（用户选择最贴近的一条，锁 `line_id`）
→ `T_L1_VERIFY`（Tieban 父母/六亲校验）
→ `T_L2_VERIFY`（兄弟/配偶/先丧等细校）
→ `LOCKED`（锁定 `Base` + `line_id` + 关键中间变量）
→ `REPORT_READY`（双轨出书：总断 + 流年）

任何阶段都允许 `BACKTRACK`（带审计记录）与 `FORK`（产生多候选分支）。

---

## 4. 输入标准化（Normalization）

### 4.1 时间与地点

- 目标：把“行政时间”转换为用于排盘/起数的“标准化时刻”，并显式记录误差与边界。
- 必做：
  - 经度修正（地方平太阳时，LMT）
  - 均时差（EOT）修正（得到真太阳时 TST）
  - 节气交界判定（若落在阈值窗口，生成“上下月双盘并行”）

### 4.2 四柱与边界策略

- 输出字段建议：
  - `pillars_primary`：主盘四柱
  - `pillars_alt`：备选盘四柱（仅边界时存在）
  - `boundary_flags`：如 `SOLAR_TERM_EDGE`, `ZI_HOUR_EDGE` 等
- 执行策略：
  - 边界案例：并行计算两套（或多套）候选，进入后续引擎时保留“候选来源”标签

---

## 5. Engine‑S（邵子坐标引擎）设计

### 5.1 数据结构与编码规则（v3 统一口径）

邵子 6144 的索引一律标准化为：

- `set_id ∈ [1..12]`：按地支顺序：子(1)、丑(2)、…、亥(12)
- `group_id ∈ [1..64]`：每集 64 组
- `line_id ∈ [1..8]`：每组 8 条

`raw_code` 的生成（与 `research tieban3.md` 的编排一致）：

- 定义 `group_x ∈ [1..8]`、`group_y ∈ [1..8]`
- `group_id = (group_y - 1) * 8 + group_x`
- `raw_code = "{set_id}{group_x}{line_id}{group_y}"`
  - 当 `set_id` 为 10..12 时，`raw_code` 为 5 位（例如 `10111`）

> 说明：该规则可直接解释 `子【1】，1111..1181`、`子【9】，1112..1182`、`子【64】，1818..1888` 等编排。

### 5.2 男女分卷（强约束）

- 男命：`group_id ∈ [1..32]`（等价：`group_y ∈ [1..4]`）
- 女命：`group_id ∈ [33..64]`（等价：`group_y ∈ [5..8]`）

任何计算/配置导致越界，必须：
- 记录 `GENDER_SCOPE_VIOLATION`
- 回退到“多候选展示”或要求用户选择

### 5.3 坐标计算（默认推荐：可配置）

Engine‑S 需要把输入映射为 `(set_id, group_id, line_id)`：

1) `set_id`（集）
   - 默认：由出生年支确定（子..亥 → 1..12）
   - 边界：若四柱候选多套，则各套产生各自 `set_id` 分支

2) `group_id`（组）
   - 输入：`hexagram_idx ∈ [1..64]`（卦气/卦序）
   - 默认映射（可配置）：
     - `male_group = ((hexagram_idx - 1) % 32) + 1`
     - `female_group = ((hexagram_idx - 1) % 32) + 33`
     - 根据性别选其一
   - 注：`hexagram_idx` 的计算方法允许多策略并存（见 §10 配置）

3) `line_id`（条）
   - 默认：由刻分/刻序确定（1..8）
   - 在“交叉考刻”中，`line_id`通常先由用户在 8 条候选中选择产生

### 5.4 输出与交互（Shaozi 先行的产品形态）

Engine‑S 的最小交互输出：
- 给定 `(set_id, group_id)`，返回 8 条候选（`line_id=1..8`）
- 前端展示为“格局/性情”风格的 8 段诗句，让用户选“最贴近的一段”
- 用户选择 → 锁定 `line_id`，进入 Tieban 精锁

---

## 6. Engine‑T（铁板算术引擎）设计

### 6.1 多起数并行（候选基数池）

铁板起数流派与细节可能不完备，v3 采用“并行候选 + 校验收敛”的工程策略：

- `BaseCandidates = { (base, method_id, confidence, trace) ... }`
- 初始生成建议至少包含：
  - 四柱天干取数（`research tieban2.md` 的 `甲1 乙6 ... 癸0`，且顺序为“月日时年”）
  - 合化修正（甲己合、乙庚合、丙辛合、丁壬合等；是否化、何时化由配置）
  - 其他派别/表格法（若后续补齐，可增量加入）

### 6.2 与 96 刻结构对齐

铁板强依赖 `96`：
- 12 时辰 × 8 刻 = 96
- `Base` 与 `%96` 的余数可用来对齐“刻位/窗口”

v3 约定：
- 任何需要“刻位”时一律使用 `line_id ∈ [1..8]`（与 Shaozi 对齐）
- 若某派别需要更细（“分”），必须在 v3 的配置层扩展，不得在引擎内硬编码

### 6.3 秘数跳跃（非线性搜索）

当 Tieban 的 L1（父母）校验未命中时，允许触发“秘数跳跃”以扩大搜索：

- 输入：`base_candidate`、`secret_keys[]`、`search_budget`
- 输出：扩展候选集合（带来源标记 `SECRET_KEY_JUMP`）

约束：
- 仅作用于 `KB_Tieban_12k`
- 每次跳跃必须写入审计轨迹（避免“算着算着变成另一本书”）

---

## 7. 数据层设计（SSOT 与物理隔离）

### 7.1 `kb_shaozi_6144`（Shaozi）

建议 Schema（逻辑）：

- `set_id INT NOT NULL`（1..12）
- `group_id INT NOT NULL`（1..64）
- `line_id INT NOT NULL`（1..8）
- `raw_code TEXT NOT NULL`（如 `1111`、`10111`）
- `content TEXT NOT NULL`（四句七言/或逗号分隔的原文）
- `gender_scope TEXT NOT NULL`（`M`/`F`）
- `hexagram_idx INT NULL`（可选，若后续能映射）
- `source TEXT NOT NULL`（来源标记：`luoyang`/`research3`/等）
- `PRIMARY KEY (set_id, group_id, line_id)`
- `UNIQUE (raw_code)`

`gender_scope` 的派生规则：
- `group_id <= 32 => 'M'`
- `group_id >= 33 => 'F'`

### 7.2 `kb_tieban_12k`（Tieban）

建议 Schema（逻辑）：

- `strip_id INT PRIMARY KEY`
- `content TEXT NOT NULL`
- `category TEXT NULL`（如 `PARENTS`/`SIBLINGS`/`SPOUSE`/`FORTUNE`/`OTHER`）
- `tags JSON NULL`（结构化：生肖/人数/年龄/吉凶等）
- `remainder_96 INT NULL`（可物化：`strip_id % 96` 或规则决定）
- `source TEXT NOT NULL`

### 7.3 会话与审计（强制）

必须落库（或至少落盘）：

`calibration_sessions`
- `session_id`
- `inputs`（脱敏）
- `normalized_result`（含边界分支信息）
- `chosen_engine_s`（set/group/line 与选择理由）
- `chosen_engine_t`（base 与方法、关键参数）
- `answers`（用户反馈）
- `trace`（完整路径：每次候选生成/淘汰/跳跃/回退）
- `final_lock`（Base + line_id + 关键变量）
- `created_at` / `updated_at`

---

## 8. 交叉考刻闭环（Dual-Kernel Calibration）

### 8.1 核心原则

1) **S 先行锁刻**：先用 Shaozi 的“8 条候选”让用户锁定 `line_id`（刻）。  
2) **T 精锁校验**：把 `line_id` 作为强约束输入 Tieban，优先命中六亲事实（父母生肖等）。  
3) **双向复核**：Tieban 锁定后，反向检查 Shaozi 输出是否“落在性别分卷与集内一致”。  

### 8.2 推荐交互流程（MVP）

1) 用户输入：出生信息（时间/地点/性别）
2) 系统标准化四柱，若边界则并行
3) Engine‑S：
   - 计算 `set_id`
   - 计算 `group_id`（若 `hexagram_idx` 不确定，先走“默认值 + 可切换候选”）
   - 拉取 8 条（line 1..8）→ 展示给用户
4) 用户选择最贴近的一条 → 锁定 `line_id`
5) Engine‑T：
   - 生成 `BaseCandidates`
   - 根据 `line_id` 与规则产生 L1 校验题（父母生肖/双亲存亡等）
   - 用户反馈 → 收敛 Base
6) 若 L1 未收敛：
   - 触发秘数跳跃或扩大窗口（含回退与分支）
7) 锁定后出书：
   - 卷一（总断/格局）：来自 Shaozi
   - 卷二（流年/时间轴）：来自 Tieban（`+96` 或等价推演）

---

## 9. ETL 方案（从文档到结构化库）

### 9.1 Shaozi 6144（推荐默认）

**主条文源**：`fortune_ai/docs/洛阳派神数条文.md`  
**规则/索引源**：`fortune_ai/docs/research tieban3.md`

解析要点：
- 从 `洛阳派神数条文.md` 解析 `raw_code` 开头的条文行（如 `1111 ...`、`11112 ...`）
- 将 `raw_code` 解析为 `(set_id, group_x, line_id, group_y)`：
  - 对于 `set_id`：
    - 若长度 4：`set_id = int(raw_code[0])`
    - 若长度 5：`set_id = int(raw_code[0:2])`
  - `group_x`：紧随 `set_id` 后一位
  - `line_id`：再后一位
  - `group_y`：最后一位
  - `group_id = (group_y-1)*8 + group_x`
- 计算 `gender_scope`（由 group_id）
- 建议保存 `content_raw` 与 `content_clean` 两份（清洗只做标点与空白归一）

### 9.2 Tieban 12k

v3 只规定“结构与规则”，条文采集可后续补齐：

- 从公开资料或已汇总文档中抽取 `strip_id + content`
- 用规则抽取结构化标签（最低限度）：
  - 父母生肖：`父(.)母(.)` 或同义结构（需兼容繁体/异体）
  - 兄弟/姐妹数：包含数字的短语
  - 年龄/岁运：`xx岁`、`xx年` 等
- 标记缺失：
  - 若某些号位缺条文，必须 `status=MISSING`，不可生成替代文本

---

## 10. 配置与可插拔策略

### 10.1 `hexagram_idx` 的来源（可插拔）

由于“卦气/卦序”计算的派别差异大，v3 要求：

- 引擎仅接受 `hexagram_idx`（或等价变量），**不强耦合其计算细节**
- 提供至少三种策略入口：
  1) `manual`：用户/操作员直接给出 `hexagram_idx`
  2) `bazi_to_hexagram_v1`：基于四柱的某种可复现映射（后续补齐）
  3) `candidate_set`：并行多个 `hexagram_idx` 候选，通过 Shaozi 8 条交互先行收敛

### 10.2 96 刻与刻序映射

- `ke_sequence`（1..8 对应的象意/卦序）允许配置
- 默认只保证“编号一致性”，不在 v3 中固化“1刻必对应某卦”的断言

### 10.3 秘数集合与搜索预算

- `secret_keys[]`、`max_branches`、`max_questions` 必须配置化
- 每次运行必须写入：实际使用了哪些秘数、产生了哪些候选、淘汰原因

---

## 11. API（建议形态，兼容 v2 ultra 的 session 风格）

### 11.1 初始化

`POST /api/tieban_shaozi/init`

输入（示例）：
```json
{
  "birth_time": "1988-08-08 08:30",
  "birth_place": {"lat": 30.5, "lon": 114.3},
  "gender": "M",
  "known_facts": {"parents_zodiac": null}
}
```

输出（示例）：
```json
{
  "session_id": "xyz",
  "normalized": {"boundary_flags": []},
  "shaozi": {
    "set_id": 1,
    "group_id": 5,
    "candidates": [
      {"line_id": 1, "raw_code": "1511", "content": "..."},
      {"line_id": 2, "raw_code": "1521", "content": "..."}
    ]
  }
}
```

### 11.2 选择 Shaozi 条（锁刻）

`POST /api/tieban_shaozi/select_shaozi_line`

```json
{
  "session_id": "xyz",
  "line_id": 2
}
```

输出：进入 Tieban 校验问题

### 11.3 提交校验（Tieban L1/L2）

`POST /api/tieban_shaozi/verify`

```json
{
  "session_id": "xyz",
  "answers": {
    "PARENTS": "父牛母羊",
    "SIBLINGS": "兄弟二人"
  }
}
```

输出（示例）：
```json
{
  "status": "LOCKED",
  "final": {"line_id": 2, "base": 2521},
  "trace_id": "trace-abc"
}
```

### 11.4 出书

`POST /api/tieban_shaozi/report`

输出：
- `volume_1`：Shaozi 总断（含 raw_code 与坐标）
- `volume_2`：Tieban 流年序列（含每步推演依据与条文 ID）

---

## 12. 日志与可观测性（必须）

### 12.1 关键事件（最小集合）

- `SESSION_CREATED`
- `INPUT_NORMALIZED`（含边界分支）
- `SHAOZI_GROUP_SELECTED` / `SHAOZI_LINE_SELECTED`
- `TIEBAN_CANDIDATES_GENERATED`（含方法与数量）
- `QUESTION_ASKED` / `ANSWER_RECEIVED`
- `SECRET_KEY_JUMP_APPLIED`
- `CANDIDATE_PRUNED`（淘汰原因必须可读）
- `LOCK_FINALIZED`
- `REPORT_GENERATED`

### 12.2 幂等与回放

- 任何一次 Session 必须可“回放”：给定同样输入与同样答案序列，应得到同样输出（在同一版本规则下）。
- 规则/数据版本必须写入 `trace`，避免“换了规则还想复现旧结果”。

---

## 13. 测试与验收（面向工程实现）

### 13.1 单元测试（建议）

- Shaozi 编码解析：
  - 输入 `1111` → `set_id=1, group_id=1, line_id=1`
  - 输入 `10111` → `set_id=10, group_id=1, line_id=1`
- 男女分卷：
  - `group_id=32 => M`；`group_id=33 => F`
- group_id 计算：
  - `group_x=8, group_y=8 => group_id=64`

### 13.2 集成测试（建议）

- 给定一个固定的 `set_id/group_id`，返回 8 条候选且 `raw_code` 单调覆盖 `line_id 1..8`
- Tieban 校验流程在“答案序列固定”时可复现 `LOCKED`

---

## 14. 开放问题（v3 需要显式留口）

1) `hexagram_idx` 的“权威计算法”尚未冻结：v3 先用可插拔 + 交互收敛策略。
2) Tieban 12k 条文全量数据与“加减秘数全集”需进一步工程化收集与版本化管理。
3) “刻分更细到分”的流派支持：后续可扩展 `line_id` 的细粒度层级（例如 `fen_id`）。

---

## 15. 版本记录

- v3.0：确立双核（Tieban 12k + Shaozi 6144）物理隔离；定义 Shaozi 编码与 group_id 计算口径；定义交叉考刻闭环与审计要求。
