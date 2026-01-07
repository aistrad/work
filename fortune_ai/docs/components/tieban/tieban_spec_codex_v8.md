# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v8）

**版本**：v8.0  
**范围**：仅 Tieban 12k（完整基于 12,000 条文的独立铁板逻辑）  
**明确排除**：任何 Shaozi/邵子算法、洛阳派 6144 条文与其坐标索引体系  
**优先级**：算法完整性与可复现性 > 工程可落地性 > UI  
**算法与数据真源（SSOT）**：  
- 算法/口诀/密数表/12k 条文：`fortune_ai/docs/tieban/research tieban.md`  
- 命书结构模板：`fortune_ai/docs/tieban/mingshu spec.md`  

---

## 0. v8 变更摘要（相对 v7.1）

1) **交互流程升级：候选命盘展示 → 用户选择锁定**  
   - 系统根据“八字排盘 + 已知事实”生成候选命盘列表（含每个候选对已知事实的命中证据）。  
   - 不再做“系统提问/多轮靠刻”；由用户在候选列表中选择“与事实最符合”的命盘作为最终命盘。  
   - 锁定与命书生成以用户选择为准（并持久化 `selected_candidate_id` 与证据）。

2) **风险收敛：不再“自动锁定第一候选”**  
   - 任何锁定都必须由用户显式选择候选触发；避免因 ETL/救援/分类误差导致的“伪满足锁定”。  
   - 候选列表按“事实命中度”排序，并展示每个事实的命中条文（`verse_id + content_raw + age_start/age_end`）。

3) **条文四列结构与命书年表落地**  
   - 12k 条文按四列入库：`verse_id age_start age_end content_raw`（虚岁区间语义）。  
   - 命书 `annual` 严格基于 `age_start/age_end` 生成年表，并通过 `category` 避免将“六亲定性条文”误当流年事件。

4) **命书输出：固定栏目 + 完整原文 + 可回放**  
   - 输出采用结构化 JSON（SSOT），前端渲染为 Markdown/HTML。  
   - 所有结论都必须带 `verse_id + content_raw`（完整原文）与结构化标签（`fact_meta/category`）。

---

## 1. 系统定义（Tieban 的工程化真相）

Tieban 12k 系统本质是“**时空标准化 + 候选序列生成 + 以六亲事实做序列碰撞收敛 + 锁定刻分 + 编排命书**”：

1) 输入：出生信息（日期/时间/地点/时区）+ 已知事实（父母生肖、兄弟数、配偶等）。  
2) 标准化：TST/EOT/节气边界/时辰交界 → 生成 `pillars_contexts[]`。  
3) 起数：Stem/Hex/DayMut 等引擎输出 `base[]`（基数集合）。  
4) 建候选：对每个 `base` 枚举 `ke=1..8` 得到候选 `(base, ke, context)`；每个候选都对应一个条文序列 `verse_id_sequence`。  
5) 候选命盘展示：基于用户已知事实，为每个候选计算“命中证据/匹配度”，输出候选列表供用户选择。  
6) 用户选择锁定：用户选择候选作为最终命盘，锁定 `selected_candidate_id`、`locked_base/true_ke/locked_context_id`。  
7) 出书：基于锁定候选的条文序列，从 12k 条文检索并按固定栏目编排命书。

---

## 2. 关键概念与不变量

### 2.1 `base / ke / verse_id_sequence`

- `base`：四位数基数（由引擎产生，如四柱天干法得 `2521`）。  
- `ke`：刻位（`1..8`），对应一个时辰（两小时）内的八刻。  
- `base_ke = base + (ke - 1)`：刻位落点。  
- `verse_id_sequence`：从 `base_ke` 起，按 `step=96` 递增直到越界（并跳过空号/避十规则），得到该候选对应的一组条文编号序列。  

**不变量**：同一候选的条文序列是等差序列（步长 96），因此其所有条文 `verse_id % 96` 相同（忽略 holes/避十造成的缺项）。

### 2.2 “多事实”靠刻的正确语义

对某个事实 `fact`（如父鼠），KB 中存在一个 `match_verse_ids(fact)` 集合。

候选 `c` **命中** 该事实，当且仅当：

```
intersection(c.verse_id_sequence, match_verse_ids(fact)) != ∅
```

**关键点**：不同事实允许命中不同条文（父母条文与兄弟条文通常不是同一条），禁止把多事实做“同一条文交集”。

### 2.3 12k 条文四列结构与年龄语义（Verse Record）

`research tieban.md` 的 12k 条文（Verse Block）每行通常为：

```
verse_id age_start age_end content_raw
```

- `verse_id`：条文唯一编号（范围 `1001..13000`）。  
- `age_start/age_end`：虚岁应验区间（用于命书年表与“同岁多条”的排序/展示）。  
  - `0 0`：不限年岁（性格/六亲/总评类常见）  
  - `X 0`：仅 X 岁当年  
  - `X Y`：X..Y 岁区间  
- `content_raw`：断语原文（命书必须展示完整原文）。  

注意：`age_start/age_end` 是条文的“时间标注”，不直接参与靠刻过滤；靠刻以 `fact_meta` 为主。

---

## 3. 总体架构（Fortune Kernel + Tieban Plugin）

沿用 v5/v6 的 Kernel/Plugin 边界（Profile 为 SSOT），v7 仅更新 Tieban 的交互与命书层：

```mermaid
graph TD
  Client[Web/API] --> Gateway[API]
  subgraph Kernel[Fortune Kernel]
    Gateway --> User[fortune_user]
    Gateway --> Profile[fortune_profile (SSOT time+facts)]
    Gateway --> Runs[fortune_user_module_run]
    Gateway --> State[fortune_user_module_state]
    Gateway --> Conv[fortune_user_conversation]
    Profile --> TimeEng[Time Engine (TST/EOT/SolarTerms)]
  end
  subgraph TB[Tieban Plugin]
    Gateway --> TBSolve[/api/tieban/solve (batch verify)/]
    TBSolve --> Norm[input_normalizer]
    Norm --> RuleEng[rule_engine (RuleSet)]
    RuleEng --> Pool[candidate_pool]
    Pool --> Verify[batch_verifier]
    Verify --> KB[(tieban_verses 12k)]
    Verify --> RS[(tieban_rulesets)]
    Verify --> Lock[lock_manager]
    Lock --> Report[report_builder (mingshu)]
    Report --> Runs
    Lock --> Profile
  end
```

---

## 4. 输入标准化（TST + 边界分裂）

### 4.1 日期解释（强制一致）

前端日期输入 `02/11/1980` 统一解释为：`1980-02-11`（`YYYY-MM-DD`）。

### 4.2 标准化输出（必须可回放）

输出写入 `input_snapshot`，至少包含：
- `birth_time_input`（原始输入，含时区）
- `geo`（经纬度；缺省按出生地默认值）
- `tst_time`（真太阳时）
- `pillars_contexts[]`（边界分裂后的候选四柱上下文）
- `boundary_flags`（节气/时辰是否处于边界窗口）

### 4.3 算例（用于回放与验收）

以下算例用于说明“标准化→起数→候选规模”的可复现性（结果以 `research tieban.md` 的表/诀为准）：

- 输入：男，`1980-02-11 14:33:00`，`UTC+8`，北京（经纬度缺省使用城市默认值）  
- 标准化（示例）：经度修正 + EOT 得 `tst_time ≈ 1980-02-11 14:04:03`（示例值；以实现为准）  
- 四柱（按示例 TST）：`庚申`年 `戊寅`月 `甲寅`日 `辛未`时  

Engine‑Stem：  
- 月干 `戊→3`，日干 `甲→1`，时干 `辛→9`，年干 `庚→4`  
- `Base_A = 3194`

Engine‑Hex（八卦加则密数表，两数）：  
- 年 `庚申`：上卦 `震`、下卦 `艮` → `[3382,4542]`  
- 月 `戊寅`：上卦 `坎`、下卦 `震` → `[1387,2645]`  
- 日 `甲寅`：上卦 `乾`、下卦 `震` → `[6387,3945]`  
- 时 `辛未`：上卦 `巽`、下卦 `艮` → `[4352,3942]`

Engine‑DayMut（严格模式：仅日柱 primary）：  
- `6387 ± 96×k, k∈{-4..4}` → 9 个基数（含原值）

候选池规模（示例）：  
- 严格模式：`bases≈17`（`Stem 1 + Hex 8 + DayMut(Primary) 8` 去重后）→ `17×8=136` 候选  
- 宽松/救援：若 `include_secondary=true`，则日柱 secondary 也做 `±96×4`，总 bases≈25 → `25×8=200` 候选（与现有 UI “200 条候选”一致）

---

## 5. RuleSet（算法完整性的 SSOT）

v7 保持 v6 的 RuleSet 思路，但补齐与 `research tieban.md` 对齐的关键字段：

### 5.1 必备字段（最小集）

- `verse_id_mapping`：`range_min=1001, range_max=13000, step=96, holes[]`  
- `avoid_ten_rule`：`mode=skip_last_digit_0`（可选）  
- `stem_digit_map`：四柱天干取数（`甲1 乙6 丙2 丁7 戊3 己8 庚4 辛9 壬5 癸0`）  
- `trigram_map`：
  - `stem_to_trigram`：`甲/壬→乾, 丁→兑, 己→离, 庚→震, 辛→巽, 戊→坎, 丙→艮, 乙/癸→坤`
  - `branch_to_trigram`：`卯/酉→乾, 辰→兑, 巳/午→离, 寅→震, 戌→巽, 子/亥→坎, 未/申→艮, 丑→坤`
- `hex_secret_table_ref`：八卦加则密数表（`(upper,lower)->[primary,secondary]`）
- `day_mutation`：
  - `enabled`
  - `step=96`
  - `depth=4`
  - `source="day_hex_primary"`（默认）
  - `include_secondary=false`（默认；可作为救援扩大）

### 5.2 可选字段

- `linear_offsets[]`（内棚/外棚线性偏移族；救援用）
- `secret_jump_search` + `secret_keys_ref`（秘数跳跃；救援用）
- `pillar_scopes`（事实类别→优先柱位，用于起数/排序，不允许绕过 KB 直接断事）

---

## 6. 核心算法（以 research tieban.md 为准）

### 6.1 Engine‑Stem（四柱天干取数）

取数表（`research tieban.md` “以下公布四柱天干的不传密数”）：

| 天干 | 甲 | 乙 | 丙 | 丁 | 戊 | 己 | 庚 | 辛 | 壬 | 癸 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 数 | 1 | 6 | 2 | 7 | 3 | 8 | 4 | 9 | 5 | 0 |

排列顺序（强制）：**月 → 日 → 时 → 年**  

输出：`Base_A = digit(月干) digit(日干) digit(时干) digit(年干)`（四位拼接为整数）

> 该规则必须能复现示例：`甲子年 丙寅月 壬申日 丙午时` → `2521`。

### 6.2 Engine‑Hex（八卦加则：密数表）

八卦映射（`research tieban.md` “壬甲从乾数…”）：
- 天干配卦：`壬/甲=乾，乙/癸=坤，庚=震，辛=巽，己=离，戊=坎，丙=艮，丁=兑`
- 地支配卦：`亥/子=坎，寅=震，巳/午=离，卯/酉=乾，辰=兑，未/申=艮，戌=巽，丑=坤`

密数表（`research tieban.md` “以下是：八卦加则的不传密数”）定义：

```
(upper_trigram, lower_trigram) -> [base_primary, base_secondary]
```

引擎输出：四柱逐柱取值，产出最多 `4 × 2` 个 `base`（去重后入候选池）。

### 6.3 Engine‑DayMut（日主变卦：±96×4）

依据 `research tieban.md`：日柱化卦后取两数中的**第一数**（primary），做前后加减 `96` 各四次。

默认配置（严格模式）：
- `source="day_hex_primary"`
- `depth=4`
- 输出 `base = primary + 96*k`，`k ∈ {-4,-3,-2,-1,0,1,2,3,4}`

可选扩大（救援/宽松模式）：
- `include_secondary=true` 时，secondary 也做同样的 `±96×4`，但必须在 trace 中标记为救援来源，避免污染“严格复盘”。

---

## 7. VerseIdMapping（刻位 → 条文序列）

### 7.1 映射规则（与实现一致）

```
base_ke = base + (ke - 1)
base_norm = normalize_to_range(base_ke, range_min=1001, range_max=13000)
sequence = [base_norm, base_norm+96, base_norm+192, ...] within range
sequence = sequence - holes
sequence = apply(avoid_ten_rule)  # 可选：末位为0者剔除
```

### 7.2 96 与“八刻分”

`research tieban.md` 给出：  
- 一天 `12` 时辰  
- 一时辰 `8` 刻  
=> 一天共 `96` 刻（`12 × 8`）  

因此：`verse_id % 96` 可作为候选序列的快速索引键（工程优化用）。

> 注意：v7 只把 `ke=1..8` 作为刻位索引；更细的“分”（分钟级）需要甲乙斗宫等更高阶算法，属于后续扩展。

---

## 8. 候选命盘展示与用户选择（Selection-First）

### 8.1 输入（facts，用户已知事实）

`facts` 统一为结构化字段（入库前归一化）：

- 建议优先提供（候选排序最有效）：
  - `father_zodiac` / `mother_zodiac`（输入可为中文生肖/地支/枚举；服务端统一归一化）
  - `siblings_count`
- 可选提供（用于更高匹配度）：
  - `spouse_zodiac`
  - 其他由 ETL 能稳定抽取的事实字段

### 8.2 候选命盘生成与匹配（Match & Rank）

1) 生成候选池：`pillars_contexts × (engine_stem/engine_hex/day_mutation) × ke(1..8)`。  
2) 对每个候选 `c=(base,ke,context)` 计算事实命中：  
   - 从 KB 构建 `fact_index`（基于候选池涉及的 `verse_id` 子集即可）。  
   - 对每个 fact 执行“序列包含性命中”：`intersection(c.sequence, match_set) != ∅`。  
   - 记录证据：`evidence[field] = matched_verses[]`（包含 `verse_id/content_raw/age_start/age_end`）。  
3) 为每个候选计算 `score`（按事实权重累加；缺省：父/母/兄弟权重更高）。  
4) 按 `score` 与稳定键排序，输出 Top-N 候选命盘列表给用户展示；支持“显示更多/显示全部”。

### 8.3 扩展搜索（可选救援，显式触发）

候选命盘展示模式下，救援不再自动触发，避免“扩大到伪满足”。  
当用户明确选择“扩大搜索空间”时才执行（并在 UI 明示“可能降低可靠性”）：
1) `linear_offsets`（如 `+7n/+21`）  
2) `day_mutation.include_secondary=true`（可选：仅当规则集声明）  
3) `secret_jump_search`（秘数跳跃）

### 8.4 锁定（Lock by Selection）

锁定由用户显式触发：用户在候选列表中选择 `selected_candidate_id`。  

锁定时必须写入：
- `selected_candidate_id`（可回放）
- `locked_base`、`true_ke`、`locked_context_id`
- `facts`（用户提交的已知事实，归一化后）
- `evidence`（每个 fact 的命中条文列表；可为空，但必须显式记录“未命中”）
- `ruleset_hash/kb_snapshot_id/source_digest`

---

## 9. 命书输出（按 mingshu spec 固定栏目 + 完整条文原文）

### 9.1 输出形态

- SSOT：结构化 JSON（存入 `fortune_user_module_run.output_report`）。  
- 渲染：前端按固定栏目渲染为 Markdown/HTML（可折叠展示，但 JSON 必须包含完整原文）。  

### 9.2 固定栏目（与 `mingshu spec.md` 对齐）

1) **封面与卷首（Cover & Preamble）**  
   - 命主信息（姓名/性别）  
   - 八字排盘（年/月/日/时；含纳音可选）  
   - 核心参数（阴历可选；`true_ke`；`locked_base`；`locked_context_id`）

2) **考刻定分（Calibration & Verification）**  
   - “已锁定候选”：`locked_base/true_ke`  
   - “六亲验证条文”：至少包含父、母、兄弟三类证据  
   - 每条证据展示：`verse_id + content_raw(完整原文)` + `fact_meta`  

3) **先天六亲断语（Innate Fate & Kinship）**  
   - 父母宫 / 夫妻宫 / 子息与兄弟（固定小节）  
   - 选条文规则：**只能从锁定候选序列中取条文**；优先取与已验证事实同类的条文，其次取同栏目高权重条文。  

4) **流年大运批导（Annual Luck Predictions）**  
   - 输出格式采用表格：年龄/流年干支/条文编码/原文/备注  
   - 选条文原则：以 `age_start/age_end` 为唯一时间来源生成年表：  
     - `age_start=0 AND age_end=0`：默认不进入年表（进入 `summary/kinship` 等栏目）。  
     - `X 0`：落在 X 岁。  
     - `X Y`：落在 X..Y 岁区间（年表中可展开为逐岁行，或以区间行展示，取决于前端呈现策略）。  
   - 若同岁/同区间出现多条：优先展示“支持度更高”的条文（例如来自多引擎/多来源重复命中的条文；无支持度时按 `verse_id` 稳定排序），并在报告中保留全部条文以便复盘。

### 9.3 命书 JSON Schema（v7 建议）

顶层：
- `run_id`
- `ruleset_name`
- `locked_base`
- `true_ke`
- `locked_context_id`
- `input_snapshot`
- `evidence`（必含父/母/兄弟）
- `sections[]`（固定顺序：cover, calibration, kinship, annual）

每条条文（统一结构）：
- `verse_id`
- `content_raw`（完整原文）
- `age_start`（虚岁起始，0 表示不限）
- `age_end`（虚岁结束，0 表示单年/不限，语义见 §2.3）
- `category`
- `fact_meta`

---

## 10. 数据库与知识库设计（SQL / JSON）

### 10.1 12k 条文表（支持靠刻与出书）

```sql
CREATE TABLE IF NOT EXISTS tieban_verses (
  verse_id     INT PRIMARY KEY,
  age_start    SMALLINT NOT NULL DEFAULT 0,
  age_end      SMALLINT NOT NULL DEFAULT 0,
  content_raw  TEXT NOT NULL,
  category     TEXT,
  fact_meta    JSONB,
  shelf        TEXT, -- 可选: "internal" | "external"
  mod_96       INT GENERATED ALWAYS AS (verse_id % 96) STORED
);
CREATE INDEX IF NOT EXISTS idx_tb_fact_meta ON tieban_verses USING GIN (fact_meta);
CREATE INDEX IF NOT EXISTS idx_tb_mod96 ON tieban_verses(mod_96);
CREATE INDEX IF NOT EXISTS idx_tb_age_start ON tieban_verses(age_start);
CREATE INDEX IF NOT EXISTS idx_tb_age_range ON tieban_verses(age_start, age_end);
```

### 10.2 八卦加则密数表（两数）

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_secret_table (
  ruleset_name   TEXT NOT NULL,
  upper_trigram  TEXT NOT NULL,
  lower_trigram  TEXT NOT NULL,
  base_values    INT[] NOT NULL, -- length=2, [primary, secondary]
  PRIMARY KEY (ruleset_name, upper_trigram, lower_trigram)
);
```

### 10.3 秘数表（救援/扩展，可选）

用于 `secret_jump_search` 等救援能力；是否启用由 RuleSet 决定。

```sql
CREATE TABLE IF NOT EXISTS tieban_secret_keys (
  ruleset_name TEXT NOT NULL,
  val          INT NOT NULL,
  purpose      TEXT,
  PRIMARY KEY (ruleset_name, val)
);
```

### 10.4 卦常量表（可选）

预留给 `research tieban.md` 中“八卦加则例”的长算法推导；v7.1 默认不依赖该表。

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_constants (
  ruleset_name TEXT NOT NULL,
  hex_code     TEXT NOT NULL,
  sum_yao      INT NOT NULL,
  PRIMARY KEY (ruleset_name, hex_code)
);
```

### 10.5 RuleSet（SSOT）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_name TEXT PRIMARY KEY,
  rules        JSONB NOT NULL,
  description  TEXT
);
```

### 10.4 KB 与证据的 JSON 约定（建议）

**`tieban_verses.fact_meta`（归一化后）**：

- 生肖字段统一为地支枚举：`ZI/CHOU/YIN/MAO/CHEN/SI/WU/WEI/SHEN/YOU/XU/HAI`  
- 中文生肖到枚举映射：`鼠=ZI, 牛=CHOU, 虎=YIN, 兔=MAO, 龙=CHEN, 蛇=SI, 马=WU, 羊=WEI, 猴=SHEN, 鸡=YOU, 狗=XU, 猪=HAI`

示例：`9134 父鼠母猪，先天定数`
```json
{
  "father_zodiac": "ZI",
  "mother_zodiac": "HAI",
  "source_ref": {"file": "fortune_ai/docs/tieban/research tieban.md", "line": 11967}
}
```

示例：`6926 兄弟二人，同父各母`
```json
{
  "siblings_count": 2,
  "source_ref": {"file": "fortune_ai/docs/tieban/research tieban.md", "line": 9759}
}
```

**`report.evidence`（锁定证据）**：
```json
{
  "father_zodiac": {"value": "ZI", "matched_verse_ids": [9134]},
  "mother_zodiac": {"value": "HAI", "matched_verse_ids": [9134]},
  "siblings_count": {"value": 2, "matched_verse_ids": [6926]}
}
```

---

## 11. API（v8：候选展示与选择为主）

### 11.1 `POST /api/tieban/init`

请求：出生信息 + `known_facts`（一次性提交）

响应：
- `run_id/profile_id/state_version`
- `boundary_flags/pillars_contexts`
- `candidate_stats`
- `candidates[]`（候选命盘列表，含 `candidate_id/score/pillars/base/ke/evidence_preview`）

### 11.2 `POST /api/tieban/select`

请求：`run_id + candidate_id + state_version`  
响应：锁定结果 + `report`（或返回 `report_id` 再拉取）

### 11.3 `POST /api/tieban/verify`（可选：更新已知事实并重排候选）

用途：用户修改/补充事实后刷新候选列表（不出题、不自动锁定）。  
请求：`run_id + answers(事实字段) + state_version`  
响应：更新后的 `candidates[]`（排序变化）与 `state_version`

---

## 12. 验收标准（v7 新增/强化）

1) **多事实语义正确**：父母生肖与兄弟数允许命中不同条文；不得要求“同一条文同时满足多个事实”。  
2) **最小锁定门槛**：未提交（或无法命中）`father_zodiac/mother_zodiac/siblings_count` 任一项，禁止锁定。  
3) **命书完整原文**：命书中引用的每条条文必须包含 `content_raw` 完整原文。  
4) **栏目固定**：命书输出固定四大部分（封面/考刻/六亲/流年），缺项用“未命中/暂无证据”占位，不得省略栏目。  
5) **可回放**：同一输入（含 ruleset/kb 指纹）得到一致的候选与锁定结果。
