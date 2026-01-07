# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v7）

**版本**：v7.1  
**范围**：仅 Tieban 12k（完整基于 12,000 条文的独立铁板逻辑）  
**明确排除**：任何 Shaozi/邵子算法、洛阳派 6144 条文与其坐标索引体系  
**优先级**：算法完整性与可复现性 > 工程可落地性 > UI  
**算法与数据真源（SSOT）**：  
- 算法/口诀/密数表/12k 条文：`fortune_ai/docs/tieban/research tieban.md`  
- 命书结构模板：`fortune_ai/docs/tieban/mingshu spec.md`  

---

## 0. v7 变更摘要（相对 v6）

1) **真实算法对齐（research tieban.md）**  
   - 明确 `96` 的核心地位（`12时辰 × 8刻 = 96刻`；`12000 / 96 = 125`）。  
   - 明确 `base + (ke-1)` 的起数方式，并以 `step=96` 生成条文序列。  
   - “八卦加则不传密数表”定义为 **(上卦, 下卦) → 两个基数**（primary/secondary）。  
   - “日主变卦”默认以 **日柱八卦加则 primary 基数** 做 `±96 × 4`（可配置扩大为 secondary 作为救援）。

2) **六亲靠刻交互：从多轮问答改为一次性提交（Batch Verify）**  
   - 用户一次性提交已知事实（不再逐题交互）。  
   - 系统返回：候选数、命中证据（每个事实命中哪条条文）、是否满足锁定条件、若未锁定则返回建议补充的事实字段（不强制下一题）。

3) **锁定（Lock）门槛升级：必须命中“父 + 母 + 兄弟数”组合**  
   - 仅当 `father_zodiac + mother_zodiac + siblings_count` 三类事实均可在同一候选序列中找到命中证据，且候选收敛到唯一候选（或唯一 `true_ke`）时，允许锁定。

4) **命书输出：按 `mingshu spec.md` 固定栏目，且展示完整条文原文**  
   - 输出采用结构化 JSON（SSOT），前端渲染为 Markdown/HTML。  
   - 所有结论都必须带 `verse_id + content_raw`（完整原文）与结构化标签（`fact_meta/category`）。

5) **条文四列结构入库（年龄语义）**  
   - `research tieban.md` 的条文行统一视为四列：`verse_id age_start age_end content_raw`。  
   - `age_start/age_end` 解释为虚岁应验区间：`0 0`（不限年岁）、`X 0`（仅 X 岁）、`X Y`（X..Y 岁）。  
   - 命书 `annual` 栏目必须以 `age_start/age_end` 生成年表，不再依赖关键词猜测。

---

## 1. 系统定义（Tieban 的工程化真相）

Tieban 12k 系统本质是“**时空标准化 + 候选序列生成 + 以六亲事实做序列碰撞收敛 + 锁定刻分 + 编排命书**”：

1) 输入：出生信息（日期/时间/地点/时区）+ 已知事实（父母生肖、兄弟数、配偶等）。  
2) 标准化：TST/EOT/节气边界/时辰交界 → 生成 `pillars_contexts[]`。  
3) 起数：Stem/Hex/DayMut 等引擎输出 `base[]`（基数集合）。  
4) 建候选：对每个 `base` 枚举 `ke=1..8` 得到候选 `(base, ke, context)`；每个候选都对应一个条文序列 `verse_id_sequence`。  
5) 靠刻：将用户提交的事实映射到 KB 中的 `match_verse_ids`，对候选做“序列包含性碰撞”收敛。  
6) 锁定：满足最小锁定条件后锁定 `true_ke (+ locked_base + locked_context_id)`。  
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

## 3.1 前端 UI 布局约定（v7.1）

- 左列（`tb-form-card`）：
  - `#tieban-form`（起盘输入 / 已知事实）
  - `#tb-status`（运行状态，始终保留且可隐藏/显示）
  - `#tb-report`（命书输出，始终保留且可隐藏/显示）
- 右列（`tb-side`）：
  - `#tb-question-block`（靠刻问题交互，显示/隐藏由后端返回控制）
  - `#rectify-result-section`（校准结果与明细）

以上 ID 为唯一真源，任何脚本仅以 ID 选择，不应依赖节点在 DOM 中的位置或父子层级。

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

## 8. 六亲靠刻：一次性提交（Batch Verify）

### 8.1 输入（facts）

`facts` 统一为结构化字段（入库前归一化）：

- 必填（用于锁定门槛）：
  - `father_zodiac`（十二支枚举，如 `ZI/CHOU/...`）
  - `mother_zodiac`
  - `siblings_count`（整数）
- 选填（用于加速收敛/提高置信度）：
  - `spouse_zodiac`
  - `children_count`
  - 其他由 ETL 能稳定抽取的事实字段

### 8.2 校验流程

1) 对每个 fact，从 KB 取 `match_verse_ids(fact)`（由 `fact_meta` 索引支持）。  
2) 对每个候选 `c=(base,ke,context)`：  
   - 计算/缓存 `c.sequence`（或以 `mod_96` 做快速判定后再精确查 holes/避十）。  
   - 对每个 fact 执行“序列包含性命中”判定：命中即可，不要求同条文。  
3) 保留满足所有已提交 facts 的候选。  
4) 若候选为 0：进入救援（按优先级），并将救援来源写入 trace；救援后仍为 0 则返回冲突报告（提示用户核对输入事实/出生信息/边界上下文）。

### 8.3 救援优先级（必须可解释、可回放）

`facts` 校验失败（候选=0）时：
1) `linear_offsets`（如 `+7n/+21`）  
2) `day_mutation.include_secondary=true`（可选：仅当规则集声明）  
3) `secret_jump_search`（秘数跳跃）  
4) 仍失败：返回 `conflict`（不锁定）

### 8.4 最小锁定条件（v7 强制）

只有同时满足以下条件才允许锁定：

1) `father_zodiac + mother_zodiac + siblings_count` 三类事实均已提交；  
2) 对锁定候选能各自找到命中证据（每个事实至少 1 条命中条文 `verse_id`）；  
3) 候选收敛到：
   - **唯一候选**（唯一 `(base, ke, context_id)`），或
   - （可选策略）唯一 `true_ke`（所有剩余候选 `ke` 相同，但 base 仍多；此时仅锁 `true_ke`，命书需标注“局未唯一”并禁止输出强断）

锁定时必须写入：
- `locked_base`、`true_ke`、`locked_context_id`
- `evidence`：`{fact_key: {value, matched_verse_ids[]}}`
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

## 11. API（v7：一次性提交为主）

### 11.1 `POST /api/tieban/solve`

请求：出生信息 + `facts`（一次性提交）

响应（未锁定）：
- `candidate_stats`（候选数、上下文数）
- `evidence`（每个 fact 的命中 verse_id[]，可能为空）
- `lock`：`null`
- `suggested_fields[]`（建议补充哪些事实字段；不强制问答）

响应（已锁定）：
- `lock`：`{locked_base,true_ke,locked_context_id}`
- `report`：可选（或提供 `GET /api/tieban/report` 拉取）

### 11.2 兼容接口（保留 v6 的 init/verify 但语义升级）

- `POST /api/tieban/init`：仅生成上下文与候选池（不出题）  
- `POST /api/tieban/verify`：允许一次提交多个 facts（不再返回“下一题”）  

---

## 12. 验收标准（v7 新增/强化）

1) **多事实语义正确**：父母生肖与兄弟数允许命中不同条文；不得要求“同一条文同时满足多个事实”。  
2) **最小锁定门槛**：未提交（或无法命中）`father_zodiac/mother_zodiac/siblings_count` 任一项，禁止锁定。  
3) **命书完整原文**：命书中引用的每条条文必须包含 `content_raw` 完整原文。  
4) **栏目固定**：命书输出固定四大部分（封面/考刻/六亲/流年），缺项用“未命中/暂无证据”占位，不得省略栏目。  
5) **可回放**：同一输入（含 ruleset/kb 指纹）得到一致的候选与锁定结果。
6) **UI 布局调整（不影响算法）**  
   - Web 界面将“运行状态（状态提示/进度）”与“命书输出（报告）”固定展示在“开始考刻”按钮下方的左侧表单区块内；  
   - 右侧仅保留“考刻问题交互（可选）”与“校准结果/明细”，互不覆盖，互不替换；  
   - 这样既便于在输入阶段实时观察状态与报告，也不会干扰右侧的靠刻问题流程。
