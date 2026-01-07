# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v6）

**版本**：v6.0  
**范围**：仅 Tieban 12k（完整基于 12,000 条文的独立铁板逻辑）  
**明确排除**：任何 Shaozi/邵子算法、洛阳派 6144 条文与其坐标索引体系  
**优先级**：算法完整性与可复现性 > 工程便利性 > UI  
**融合基线**：`fortune_ai/docs/tieban/tieban_spec_ultra_v6.md`（胖胖熊体系的增量机制） + `fortune_ai/docs/tieban/tieban_spec_codex_v5.md`（RuleSet SSOT + Kernel 数据模型）  
**注意（源一致性）**：`tieban_spec_ultra_v6.md` 文中提到 “Research Tieban 2”，本仓库对应主文档为 `fortune_ai/docs/research tieban.md`；v6 codex 统一以仓库实际文件为准。

---

## 0. 与 `tieban_spec_ultra_v6.md` 的差异清单（哪些不同 + v6 的取舍）

以下按“差异 → 判断 → v6 采用方式”给出：

1) **“Research Tieban 2”引用**  
   - ultra v6：把“胖胖熊实战体系”称为 Research Tieban 2。  
   - codex v6：统一映射到仓库真实文件 `fortune_ai/docs/research tieban.md`，并要求每个关键表/口诀能在仓库文本中定位与校对。

2) **八卦加则：一卦多数（如 `8387/4245`）**  
   - ultra v6：声明存在“八卦加则密数表”，同一卦可查到多个基数。  
   - v5 codex：仅支持 `Base_B = Head*1000 + SumYao - Tail` 的单值模式（或把多值当作 RuleSet 可扩展）。  
   - v6 取舍：**纳入为一级能力**——Engine‑Hex 先查 `hex_secret_table`（可返回 `base_values[]`），再用公式作为兜底；两者都必须由 RuleSet/物化表提供，代码不硬编码“第二个数怎么来”。

3) **内棚/外棚与线性偏移（`+7n`/`+21` 等救援路径）**  
   - ultra v6：把“内棚/外棚线性偏移”作为关键救援，甚至给出示例 `Base + 7×3`。  
   - v5 codex：仅给出 `secret_jump_search`（秘数跳跃）与 `key_mapping`，未明确“线性偏移族”。  
   - v6 取舍：**纳入为一级救援机制**，但从“示例公式”升级为 RuleSet 配置：`linear_offsets[]`（何时触发、作用范围、步长、次数、与候选筛选条件）；并把“内棚/外棚”定义为 KB 的可标注属性（列/或 fact_meta）。

4) **日主变卦引擎（`±96×depth`）**  
   - ultra v6：新增 Engine‑DayMut（配偶/暴富流年等），深度默认 `4`。  
   - v5 codex：仅把 `+96` 作为主轴，不把“日主变卦”作为独立引擎。  
   - v6 取舍：**纳入为独立引擎**，但不硬绑定其业务语义（“暴富/配偶”）——语义来自条文分类与 `fact_meta`；引擎只负责产生候选 `verse_id` 集合供考刻与出书。

5) **分柱直断（年考父、月考兄、日考妻、时考子）**  
   - ultra v6：把它当作独立引擎（Engine‑PillarCalib），可做 L0 快速过滤。  
   - v5 codex：强调“问题从 KB 的 fact_meta 来”，不提供“柱→六亲”的硬推断路径。  
   - v6 取舍：**保留其“作用域（scope）”思想，但不直接硬推断生肖**：将其落为 RuleSet 的 `pillar_scopes`（哪类事实优先用哪一柱起卦/取数），用于候选生成与题目排序；真正的“断出什么”仍以 12k KB 的条文与 `fact_meta` 碰撞为准。

---

## 1. 系统定义（Tieban 的工程化真相）

Tieban 12k 系统是“**时空坐标校准 + 条文索引检索**”系统：

1) 输入：出生时间/地点/性别 + 可确认事实（父母生肖、兄弟数、先丧、配偶信息等）。  
2) 标准化：TST/EOT/节气边界/时辰交界 → 多套四柱上下文并行。  
3) 候选生成：多引擎（Stem/Hex/DayMut/Offsets/SecretKeys）并行生成 Candidate Pool。  
4) 考刻闭环：从 12k 条文的 `fact_meta` 生成问题 → 答案 → 剪枝收敛 → 锁定 TrueKe + LockedBase(+Key)。  
5) 出书：基于锁定结果从 12k 条文检索编排为结构化命书。  

---

## 2. 总体架构（Fortune Kernel + Tieban Plugin）

沿用 v5 的 Kernel/Plugin 边界，并将 v6 新增机制纳入 Tieban Plugin 的 RuleSet 与引擎集合：

```mermaid
graph TD
  Client[Web/WeChat/API] --> Gateway[API Gateway]
  subgraph Kernel[Fortune Kernel]
    Gateway --> User[fortune_user]
    Gateway --> Profile[fortune_profile (SSOT time+facts)]
    Gateway --> Runs[fortune_user_module_run]
    Gateway --> State[fortune_user_module_state]
    Gateway --> Conv[fortune_user_conversation]
    Profile --> TimeEng[Time Engine (TST/EOT/SolarTerms)]
  end
  subgraph TB[Tieban Plugin]
    Gateway --> TBInit[/api/tieban/init]
    TBInit --> Norm[input_normalizer]
    Norm --> RuleEng[rule_engine (RuleSet interpreter)]
    RuleEng --> Pool[candidate_pool]
    Pool --> FSM[calibration_fsm]
    FSM --> KB[(tieban_verses 12k)]
    FSM --> RS[(tieban_rulesets)]
    RuleEng -.-> HexSecret[(tieban_hex_secret_table)]
    RuleEng -.-> HexConst[(tieban_hex_constants)]
    RuleEng -.-> Keys[(tieban_secret_keys)]
    FSM --> Report[report_builder]
    Report --> Runs
    FSM --> Profile
  end
```

---

## 3. 输入标准化（TST + 双重边界分裂）

沿用 v5（略），并强调标准化输出必须进入 `input_snapshot` 以便回放：

- 真太阳时（TST）：经度修正 + EOT
- 边界分裂：节气交脱窗口 + 时辰交界窗口
- 产物：`pillars_contexts[]`、`boundary_flags[]`、`tst_time`

---

## 4. RuleSet（算法完整性的 SSOT）

### 4.1 v6 规则扩展字段（在 v5 基础上新增）

在 `fortune_ai/docs/tieban/tieban_spec_codex_v5.md` 的 RuleSet 必备字段基础上，v6 新增：

- `hex_secret_table_ref`：指向“八卦加则密数表”（一卦多值）数据源
  - `mode: inline | table_ref`
- `linear_offsets[]`：内棚/外棚线性偏移族定义（用于救援/扣入）
  - 触发条件（哪些 fact/category/阶段）
  - 步长（step）、次数/范围（n_min..n_max）
  - 适用对象（哪些 verse_id/bases/candidate types）
- `day_mutation`：日主变卦引擎参数
  - `enabled`、`depth`（默认 4）、`step`（默认 96）、`source_pillar`（默认 day）
- `pillar_scopes`：事实类别→优先柱位（year/month/day/hour）
  - 例如：`parents -> year`, `siblings -> month`, `spouse -> day`, `children -> hour`

### 4.2 RuleSet 的“多值输出”统一约定

v6 规定：任何引擎的输出统一为“候选数值列表”，随后进入 `VerseIdMapping`：

- Engine‑Stem：输出 `[Base_A, Base_A_alt...]`
- Engine‑Hex：输出 `[Base_B...]`（若有 secret table，输出可多值）
- Engine‑DayMut：输出 `[{base:DayBase + 96*k}...]`

---

## 5. 核心算法（v6：四引擎 + 两类救援）

### 5.1 Engine‑Stem（四柱天干配数）

沿用 v5（略），关键点仍为：
- 顺序强制：月→日→时→年（必须能复现 2521）
- 合化：必须表格化（含“有字间之不化”的拓扑判定输入）

### 5.2 Engine‑Hex（八卦加则：密数表优先 + 公式兜底）

#### 5.2.1 优先：Hex Secret Table（“一卦多数”）

输入：`upper_trigram`, `lower_trigram`, `ruleset_name`

输出：`base_values[]`（例如 `[8387, 4245]`），其来源必须是：
- RuleSet inline（小表）
- 或 `tieban_hex_secret_table` 物化表（大表）

#### 5.2.2 兜底：公式计算

```
Base_B = Head(upper)*1000 + SumYao(hex) - Tail(lower)
```

其中 `SumYao(hex)` 必须来自：
- RuleSet inline 常量
- 或 `tieban_hex_constants` 查表

算例（若 `SumYao=390`，上艮下震）：
`Base_B = 8*1000 + 390 - 3 = 8387`

### 5.3 Engine‑DayMut（日主变卦：±96×depth）

该引擎的职责仅是“生成候选索引集合”，语义由条文 `category/fact_meta` 决定。

配置（RuleSet）：
- `day_mutation.enabled = true`
- `day_mutation.step = 96`
- `day_mutation.depth = 4`
- `day_mutation.source_pillar = day`

候选生成：
```
DayBase = EngineHex(source_pillar=day) -> base_values[]
for b in DayBase:
  for k in [-depth..depth] (k != 0 可配置):
    emit b + step*k
```

### 5.4 “分柱校准”作用域（pillar_scopes：不直接硬断）

v6 将 ultra 的“年考父/月考兄/日考妻/时考子”落为 **优先起数/起卦作用域**：

- 生成 L1（父母类）候选时：优先用 `year` pillar 起卦/取数产生 `verse_ids`，并优先选择 `category=PARENTS` 的条文进入问题空间。
- 生成 L2（配偶类）候选时：优先用 `day` pillar。

禁止：直接从 pillar 计算“生肖答案”绕过 KB；所有断语必须最终落在 `tieban_verses` 的可检索条文上。

### 5.5 两类救援机制

#### 5.5.1 线性偏移救援（linear_offsets：内棚/外棚）

用于“主候选命中但细节不对/或需要外棚拓展”的场景：

```
for each candidate verse_id in current_pool:
  if meets trigger (stage/category/fact):
    for n in [n_min..n_max]:
      emit verse_id + step*n
```

其中：
- `step` 与 `n_min..n_max` 由 RuleSet 定义（支持 `+7n`、`+21` 等）
- “内棚/外棚”建议作为 KB 标签或列（例如 `shelf="internal"|"external"`），用于限制偏移的应用范围

#### 5.5.2 秘数跳跃救援（secret_keys）

保留 v5 的 `secret_jump_search`：当 L1 全部不命中时扩大搜索空间；秘数来源为 RuleSet（或 `tieban_secret_keys` 物化表）。

---

## 6. 考刻 FSM（基于 KB 生成问题）

沿用 v5（略），新增两点：

1) **L0 过滤（可选）**：利用 `pillar_scopes` 先从“父母类/兄弟类/配偶类”候选中做初筛，减少问题数。  
2) **L1.5 双救援并存**：先尝试 `linear_offsets`（若规则集声明存在内棚/外棚映射），不行再进入 `secret_jump_search`。  

LOCKED 时必须回写：
- `fortune_profile.verified_facts`
- `fortune_user_module_run.output_report`

---

## 7. 知识库与规则库（SQL v6：吸收 ultra v6 的新增表）

### 7.1 12k 条文表（增加可选内棚标记）

```sql
CREATE TABLE IF NOT EXISTS tieban_verses (
  verse_id     INT PRIMARY KEY,
  content_raw  TEXT NOT NULL,
  category     TEXT,
  fact_meta    JSONB,
  shelf        TEXT, -- 可选: "internal" | "external"
  mod_96       INT GENERATED ALWAYS AS (verse_id % 96) STORED
);
CREATE INDEX IF NOT EXISTS idx_tb_fact_meta ON tieban_verses USING GIN (fact_meta);
CREATE INDEX IF NOT EXISTS idx_tb_mod96 ON tieban_verses(mod_96);
```

### 7.2 八卦加则密数表（新增：一卦多值）

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_secret_table (
  ruleset_name   TEXT NOT NULL,
  upper_trigram  TEXT NOT NULL,
  lower_trigram  TEXT NOT NULL,
  base_values    INT[] NOT NULL,   -- e.g. {8387,4245}
  PRIMARY KEY (ruleset_name, upper_trigram, lower_trigram)
);
```

### 7.3 卦常量表与秘数表（保留）

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_constants (
  ruleset_name TEXT NOT NULL,
  hex_code     TEXT NOT NULL,
  sum_yao      INT NOT NULL,
  PRIMARY KEY (ruleset_name, hex_code)
);

CREATE TABLE IF NOT EXISTS tieban_secret_keys (
  ruleset_name TEXT NOT NULL,
  val          INT NOT NULL,
  purpose      TEXT,
  PRIMARY KEY (ruleset_name, val)
);
```

### 7.4 RuleSet（SSOT）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_name TEXT PRIMARY KEY,
  rules        JSONB NOT NULL,
  description  TEXT
);
```

---

## 8. Fortune 数据模型（沿用 v5：Account-Profile-State-Run-Conversation）

本节沿用 `fortune_ai/docs/tieban/tieban_spec_codex_v5.md` 的最终模型，并保留 `fortune_profile.verified_facts` 作为跨模块事实锚点。

---

## 9. API（建议，沿用 v5）

- `POST /api/tieban/init`
- `POST /api/tieban/verify`
- `POST /api/tieban/lock`
- `GET /api/tieban/report?run_id=...`

---

## 10. v6 验收标准（新增项）

在 v5 基础上新增：

1) **Hex Secret Table 能产出多值**：对某个卦输入能返回 `base_values[]`（例如 `[8387,4245]`），并进入候选池与 FSM。  
2) **线性偏移救援可控**：当触发条件满足时，能按 RuleSet 定义生成 `verse_id + step*n` 的候选，并能被 KB 事实碰撞收敛。  
3) **DayMut 引擎可复现**：在给定 `DayBase` 的前提下，能生成 `±96×depth` 的候选集合（depth 默认 4）。  

