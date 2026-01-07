# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v4）

**版本**：v4.0  
**定位**：Tieban 12k 独立引擎（不包含任何 Shaozi 算法/洛阳派 6144 条文）  
**优先级**：算法完整性与可复现性 > 工程便利性 > UI 表现  
**依赖**：真太阳时与节气计算（可复用 `fortune_ai` 的 Bazi 能力，但 Tieban 必须补齐边界分支与可回放的归一化结果）  
**输入依据（仓库内）**：
- `fortune_ai/docs/research tieban.md`（四柱天干法、八卦加则、九十六刻、合化、起运与流月描述等）
- `fortune_ai/docs/research tieban1.md`（皇极经世/大周期相关材料；用于宏观索引的可配置扩展）
- `fortune_ai/docs/tieban v1.md`（术语、刻分/候选/考刻冲突点与工程化提示）
- `fortune_ai/docs/tieban_spec_codex.md`（v2 规格：规则引擎、KB、可回放与治理）
- `fortune_ai/docs/tieban_spec_codex v2 deep.md`（真太阳时/EOT/节气边界的工程严谨化）
- `fortune_ai/docs/tieban_spec_ultra_v3.md`（v3 ultra：双引擎并行、公式化表达、profile/state 架构）
- `fortune_ai/docs/tieban_spec_codex_v3.md`（v3 codex：RuleSet 数据驱动、不臆造缺失表、模块 run/对话历史数据模型）
- `fortune_ai/docs/tieban_kb_design.md`、`fortune_ai/docs/tieban kowledge gemini.md`（KB/ETL 思路）

**重要说明（文档源一致性）**：`tieban_spec_ultra_v3.md` 引用 `research tieban2.md`，但本仓库实际文件为 `fortune_ai/docs/research tieban.md`；v4 统一以 `research tieban.md` 为“胖胖熊实战体系”主来源。

---

## 1. v4 变更摘要（相对 v3 codex / v3 ultra 的融合点）

v4 在保持 `tieban_spec_codex_v3.md` 的“RuleSet 数据驱动、避免臆造缺失表”的基础上，吸收 `tieban_spec_ultra_v3.md` 的长处：

- **公式化补强**：补齐 Engine‑Stem/Engine‑Hexagram 的明确数学表达（便于实现与验算）。
- **知识库补强**：新增可选的 `tieban_hex_constants`（卦常量表）与 `tieban_secret_keys`（秘数表）作为 RuleSet 的物化索引层（可从 RuleSet JSON 导出）。
- **用户模型补强**：引入 account/profile/state 的层次结构（来自 ultra），并与 v3 codex 的“run 记录 + latest 索引 + conversation 入库”融合成最终可扩展模型。
- **边界补强**：在 v3 codex 的“节气边界双盘”之外，补齐 ultra 提到的“时辰交界 fuzzy”策略（分钟级靠近交界点时并行候选）。

---

## 2. 系统目标与边界（Tieban 12k-only）

### 2.1 目标（In）
- 完整 Tieban 12k 引擎闭环：输入标准化 → 候选生成（8刻/96刻）→ 考刻收敛 → 锁定（TrueKe + Base/Key）→ 12k 条文检索与命书编排。
- 多 RuleSet 并行：同一输入可在多个流派/规则集下并行生成候选，靠“事实碰撞”收敛。
- 12k KB + 结构化标签：支持从条文抽取 `fact_meta` 用于反向匹配（考刻的核心）。
- 与 `fortune_ai` 作为并列模块集成：与 `bazi`、未来 `shaozi`、未来扩展模块并列。
- `fortune_user` 系统升级：支持基础信息 + 模块计算信息（run/state/结果）+ 历史对话。

### 2.2 非目标（Out）
- 不引入任何 Shaozi 算法与 6144 条文、分卷/坐标索引等。
- 不依赖 LLM 生成/推断 Tieban 条文 ID；Tieban 计算必须可复现、可验算。

---

## 3. 总体架构（Fortune AI Kernel + Tieban Plugin）

Tieban 作为 `fortune_ai` 的一个“确定性计算模块”，推荐采用“Kernel + Plugin”的清晰边界：

### 3.1 逻辑架构

```mermaid
graph TD
    Client[用户端 / Web / WeChat] --> API[API Gateway]

    subgraph "Fortune AI Kernel"
        API --> Account[Account / fortune_user]
        API --> Profile[Profile / fortune_profile]
        API --> Conv[Conversation / fortune_user_conversation]
        API --> Run[Runs / fortune_user_module_run]
        API --> State[States / fortune_user_module_state]
        Profile --> TimeEng[Time Engine: TST/EOT/节气]
    end

    subgraph "Tieban Plugin (12k-only)"
        API --> TB_Init[init/candidates]
        TB_Init --> TB_Norm[input_normalizer]
        TB_Norm --> TB_Rules[rule_engine (RuleSet loader)]
        TB_Rules --> TB_Cands[candidates (ke/base/verse_ids)]
        TB_Cands --> TB_FSM[calibration_orchestrator (FSM)]
        TB_FSM --> TB_KB[(tieban_verses 12k)]
        TB_FSM --> TB_RS[(tieban_rulesets)]
        TB_FSM --> TB_Report[report_builder]
    end
```

### 3.2 组件职责（Tieban 内部）

- `tieban.input_normalizer`：时间→真太阳时→节气边界→四柱候选（并行分支）。
- `tieban.rule_engine`：加载 RuleSet，执行 Engine‑Stem / Engine‑Hexagram / 其他方法，生成候选集合（含分解）。
- `tieban.calibration_orchestrator`：考刻状态机；基于 KB 的 `fact_meta` 做问答与收敛。
- `tieban.kb`：12k 条文检索、索引、标签查询。
- `tieban.report_builder`：锁定后输出结构化命书（JSON）。
- `tieban.etl`：条文导入与结构化标签抽取。

---

## 4. 输入标准化（Normalization：真太阳时 + 边界分支）

Tieban 的算法对“刻”敏感，必须把输入标准化结果作为可回放产物写入 run/state。

### 4.1 输入契约（建议）

```json
{
  "name": "张三",
  "gender": "男",
  "birth_local": "1988-08-08 08:30:00",
  "tz_offset_hours": 8,
  "location": {"name":"北京","longitude":116.4074,"latitude":39.9042},
  "known_facts": {
    "parents_zodiac": {"father":"子","mother":"午"},
    "siblings": {"count":2,"rank":1}
  },
  "ruleset_names": ["ppx_v1", "tuenhai_v1"],
  "debug": true
}
```

### 4.2 真太阳时计算口径（TST）

1) 经度修正（LMT）：
```
L_meridian = 15 * tz_offset_hours
delta_minutes = (longitude - L_meridian) * 4
T_lmt = T_local + delta_minutes
```

2) 均时差（EOT）近似（可复现）：
```
theta = 2π(doy - 81) / 365
EOT ≈ 9.87*sin(2*theta) - 7.53*cos(theta) - 1.5*sin(theta)
T_tst = T_lmt + EOT
```

### 4.3 边界策略（必须）

边界分两类，均需并行候选：

1) **节气边界（影响月柱）**：节气交接点前后 `boundary_window_minutes`（默认建议 `15`，由 RuleSet 指定）内，产生 `pillars_prev_term` 与 `pillars_next_term` 两套四柱候选。

2) **时辰交界边界（影响刻/时柱）**：若 `T_tst` 落在时辰交界点前后 `shichen_fuzzy_minutes`（默认建议 `2..5`，由 RuleSet 指定）内，标记 `boundary_shichen_fuzzy=true`，并行计算“本时辰”与“下一时辰”的时柱/刻候选。

### 4.4 标准化输出（必须可回放）

```json
{
  "tst_time": "1988-08-08T08:17:31+08:00",
  "boundary_flags": ["SOLAR_TERM_EDGE", "SHICHEN_EDGE"],
  "pillars_candidates": [
    {"id":"A","pillars":{"year":"甲子","month":"丙寅","day":"壬申","hour":"丙午"}},
    {"id":"B","pillars":{"year":"甲子","month":"丁卯","day":"壬申","hour":"丙午"}}
  ]
}
```

---

## 5. RuleSet 规范（算法完整性的 SSOT）

Tieban 的“算法完整性”= **流程固定 + 表格/钥匙/跳码完整**。

### 5.1 RuleSet 最小必备字段（v4 最终版）

- `name`：规则集名称（例如 `ppx_v1`）
- `time`：
  - `boundary_window_minutes`（节气边界窗口）
  - `shichen_fuzzy_minutes`（时辰交界窗口）
- `stem_number_map`：天干→数字（如 `甲1乙6...癸0`）
- `stem_digit_order`：用于 Engine‑Stem 的拼接顺序（如 `["month","day","hour","year"]`）
- `hehua_rules`：合化规则（含“间隔不化/月令支持/替换为五行数”等）
- `wuxing_number_map`：五行→数字（如 `水1火2木3金4土5`）
- `trigram_map`：
  - `stem_to_trigram`（天干→卦：甲壬=乾、乙癸=坤、丙=艮、丁=兑、戊=坎、己=离、庚=震、辛=巽）
  - `branch_to_trigram`（地支→卦：亥子=坎、寅卯=震、巳午=离、申酉=兑、丑未=坤、辰戌=巽、戌=乾 等；以 RuleSet 为准）
  - `trigram_number`（乾6、兑7、离9、震3、巽4、坎1、艮8、坤2）
- `hex_constants`：卦常量来源（两种方式二选一）
  - `inline`：直接内嵌在 ruleset JSON（适合小规模）
  - `table_ref`：引用 `tieban_hex_constants` 表（适合大规模）
- `avoid_ten_rule`：遇十不用策略（模式 + 参数）
- `ke`：
  - `ke_index_base`：`1..8`（v4 固定）
  - `ke_ranges`：刻→分钟范围定义
  - `ke_selection_rule`：如何从天干数得到“最可能刻”（如 `%8` 余数规则）
- `verse_id_mapping`：中间数→最终 `verse_id` 映射（必须完整）
  - `range`：有效 ID 区间（通常 `1..12000`，或含跳码区间）
  - `holes`：空号/跳码列表（若存在）
  - `key_mapping`：钥匙/密码层（若存在）
  - `secret_keys`：秘数集合（用于搜索/跳跃/修正）

### 5.2 RuleSet JSON 示例（结构示例，非完整表）

```json
{
  "name": "ppx_v1",
  "time": {"boundary_window_minutes": 15, "shichen_fuzzy_minutes": 3},
  "stem_number_map": {"甲":1,"乙":6,"丙":2,"丁":7,"戊":3,"己":8,"庚":4,"辛":9,"壬":5,"癸":0},
  "stem_digit_order": ["month","day","hour","year"],
  "wuxing_number_map": {"水":1,"火":2,"木":3,"金":4,"土":5},
  "hehua_rules": {"rules": "RULE_TABLE_REQUIRED"},
  "trigram_map": {
    "stem_to_trigram": {"甲":"乾","壬":"乾","乙":"坤","癸":"坤","丙":"艮","丁":"兑","戊":"坎","己":"离","庚":"震","辛":"巽"},
    "branch_to_trigram": {"亥":"坎","子":"坎","寅":"震","卯":"震","巳":"离","午":"离","申":"兑","酉":"兑","丑":"坤","未":"坤","辰":"巽","戌":"乾"},
    "trigram_number": {"乾":6,"兑":7,"离":9,"震":3,"巽":4,"坎":1,"艮":8,"坤":2}
  },
  "hex_constants": {"mode":"table_ref","table":"tieban_hex_constants","ruleset":"ppx_v1"},
  "avoid_ten_rule": {"mode":"plus_one"},
  "ke": {
    "ke_index_base": 1,
    "ke_ranges": [
      {"ke":1,"start_minute":0,"end_minute":15},
      {"ke":2,"start_minute":15,"end_minute":30},
      {"ke":3,"start_minute":30,"end_minute":45},
      {"ke":4,"start_minute":45,"end_minute":60},
      {"ke":5,"start_minute":60,"end_minute":75},
      {"ke":6,"start_minute":75,"end_minute":90},
      {"ke":7,"start_minute":90,"end_minute":105},
      {"ke":8,"start_minute":105,"end_minute":120}
    ],
    "ke_selection_rule": {"mode":"stem_sum_mod_8","mod":8,"zero_as":8}
  },
  "verse_id_mapping": {
    "range":{"min":1,"max":12000},
    "holes": [],
    "key_mapping": {"mode":"none"},
    "secret_keys":[1327,1543,5017,133,97,23,41,571,1147,2237]
  }
}
```

---

## 6. 核心算法（v4：明确公式 + 不臆造缺失表）

Tieban 采用“多引擎并行 → 考刻收敛”的总体策略：

- Engine‑Stem：四柱天干配数（用于 Base 主轴与 `+96` 推演）
- Engine‑Hexagram：八卦加则（用于六亲考刻锚点）
- Ke/96 刻规则：用于“考时定刻”的候选结构化生成

### 6.1 Engine‑Stem（四柱天干配数法）

#### 6.1.1 公式定义（吸收 ultra 的表达）

设 `Map` 为 `stem_number_map`，`Order` 为 `stem_digit_order=["month","day","hour","year"]`：

```
Base_A = Map(month_stem)*1000 + Map(day_stem)*100 + Map(hour_stem)*10 + Map(year_stem)
```

#### 6.1.2 Step-by-step 算例：Base_A=2521（来自文档示例）

八字：`甲子年 丙寅月 壬申日 丙午时`

1) 取月干：`丙 → 2`
2) 取日干：`壬 → 5`
3) 取时干：`丙 → 2`
4) 取年干：`甲 → 1`
5) 代入：`Base_A = 2*1000 + 5*100 + 2*10 + 1 = 2521`

#### 6.1.3 `+96` 推演序列（条文索引主轴）

```
Seq(n) = Base_A + 96*n
```

示例（来自文档展示片段）：
`2521, 2617, 2713, 2809, 2905, 3001, 3097, ...`

> v4 不规定每个 `n` 对应“年龄/年份”的精确映射（资料存在派别差异），要求作为 RuleSet 的 `timeline_mapping` 组件配置化；但 `+96` 作为索引递推结构是确定的。

#### 6.1.4 合化修正（HeHua）

合化的作用是生成 `Base_A_alt`（备用基数），并行进入考刻收敛：

1) 依据 `hehua_rules` 判定哪些柱位的天干对参与合化（例如月干与日干、或按派别定义）
2) 依据月令/干支条件判定是否“化”
3) 若成立：将参与合化的天干数字替换为其五行数字（`wuxing_number_map`）
4) 生成 `Base_A_alt` 与 `Base_A` 并行

> v4 强制：合化规则必须在 RuleSet 中以表格形式给出（包含“不化条件：某字间之”等），否则不得在实现中凭空推断。

### 6.2 Engine‑Hexagram（八卦加则）

#### 6.2.1 化卦（上卦/下卦）

- 上卦：由天干映射（`stem_to_trigram`）
- 下卦：由地支映射（`branch_to_trigram`）

#### 6.2.2 关键公式（吸收 ultra 的表达）

设：
- `Head(upper)` 为 `trigram_number[upper]`
- `Tail(lower)` 为 `trigram_number[lower]`
- `SumYao(hex)` 为整卦爻权和（来自 `hex_constants`：查表）

则：
```
Base_B = Head(upper)*1000 + SumYao(hex) - Tail(lower)
```

#### 6.2.3 Step-by-step 算例 1：上坎下震（文档示例）→ 1387

已知：`upper=坎(1)`，`lower=震(3)`，`SumYao=390`

1) `Head(坎)*1000 = 1*1000 = 1000`
2) `1000 + 390 - 3 = 1387`

#### 6.2.4 Step-by-step 算例 2：上艮下震（ultra 示例）→ 8387

已知：`upper=艮(8)`，`lower=震(3)`，`SumYao=390`

1) `Head(艮)*1000 = 8*1000 = 8000`
2) `8000 + 390 - 3 = 8387`

#### 6.2.5 “变知六八止 / 世应两同俦 / 遇十不用”

这些属于“二次规则层”，v4 规定：
- 任何“变卦/世应/六八止/遇十不用”的实现必须由 RuleSet 的显式参数与表格驱动；
- 不允许在实现中把口诀翻译成未经验证的固定公式。

落地建议：
- 把 `SumYao`、`变卦规则`、`世应规则`、`遇十不用规则` 全部纳入 RuleSet，并在 `tieban_rulesets.rules` 中版本化。

### 6.3 Ke 与 96 刻结构（考时定刻的骨架）

#### 6.3.1 “最可能刻”计算（资料口径）

资料给出的可复现口径：
1) 取四柱天干数字之和 `S_stem`
2) `r = S_stem % 8`
3) `ke_index = (r == 0 ? 8 : r)`

该结果用于：
- 排序（先问最可能刻）
- 或作为候选初始化的“默认刻”

#### 6.3.2 8 刻候选生成（工程口径）

对每个四柱候选 `pillars_candidate`，对每个 RuleSet：

```
for ke in 1..8:
  bases = [
    EngineStem(pillars_candidate, ruleset) -> Base_A + Base_A_alt...
    EngineHexagram(pillars_candidate, ruleset, selected_pillar_scope) -> Base_B...
    ... (可扩展)
  ]
  verse_ids = VerseIdMapping(bases, ke, ruleset)
  candidates.append({pillars_id, ruleset, ke, bases, verse_ids, breakdown})
```

> 其中 `VerseIdMapping` 是“算法完整性”的硬门槛：必须把中间数映射到 12k 条文 ID；没有这层就无法完成“基于 12000 条文”的考刻闭环。

### 6.4 VerseIdMapping（中间数→12k 条文 ID）

v4 把映射分三层（可叠加），全部必须可配置：

1) `range_normalize`：把数值归一到有效区间（例如 `1..12000`），并处理 `holes`（空号/跳码）。
2) `key_mapping`：密码/钥匙层（例如 `ID_actual = f_key(ID_calc, K_final)` 的机制，来自 `tieban_spec_codex v2 deep.md` 的描述）。
3) `secret_jump_search`：秘数跳跃搜索（考刻失败时扩大搜索空间），来源为 `secret_keys`。

> v4 规定：若 RuleSet 未提供 `key_mapping` 与 `holes`，实现只能采用 `mode=none`，不能凭经验“猜一个偏移”。

---

## 7. 考刻闭环（Calibration FSM：从 KB 生成问题）

### 7.1 状态机（建议）

`INIT`
→ `NORMALIZED`
→ `CANDIDATES_READY`
→ `L1_VERIFY`（父母/双亲等高区分事实）
→ `L1_SECRET_SEARCH`（可选：秘数跳跃）
→ `L2_VERIFY`（兄弟/配偶/先丧/子女等）
→ `LOCKED`（TrueKe + LockedBase + Ruleset + Evidence）
→ `REPORT_READY`

### 7.2 关键原则：问题必须来自 KB 的 `fact_meta`

实现上必须做到：

1) 对当前候选集合中的 `verse_ids` 批量读取条文  
2) 聚合其 `fact_meta` 形成“可问问题空间”  
3) 选择区分度最高的问题（信息增益最大）  

示例问题类型（可扩展）：
- `parents_zodiac`：父/母生肖
- `siblings_count` / `rank`
- `spouse_zodiac` / `spouse_surname`（若条文可抽取）
- `parent_death_order`（先丧父/先丧母）

### 7.3 收敛算法（不臆造，给出工程定义）

候选对象建议结构：
```json
{
  "candidate_id":"uuid",
  "pillars_id":"A",
  "ruleset":"ppx_v1",
  "ke":2,
  "bases":[{"type":"stem","value":2521},{"type":"hex","value":8387}],
  "verse_ids":[2521, 8387, 3001],
  "breakdown": {"...":"..."}
}
```

收敛规则：
- 用户回答某个事实 `F` 后，过滤所有“不包含可满足 F 的 verse”的候选；
- 若剩余候选仍多，继续从剩余候选的 `fact_meta` 生成下一题；
- 直到候选唯一或达到阈值（然后进入“人工选择/增加事实”）。

---

## 8. 知识库设计（12k 条文 + 规则 + 物化表）

### 8.1 核心表：12k 条文

```sql
CREATE TABLE IF NOT EXISTS tieban_verses (
  verse_id       INT PRIMARY KEY,
  content_raw    TEXT NOT NULL,
  content_clean  TEXT,
  category       TEXT,
  fact_meta      JSONB,
  remainder_96   INT,
  source         TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tieban_verses_remainder96 ON tieban_verses(remainder_96);
CREATE INDEX IF NOT EXISTS idx_tieban_verses_category ON tieban_verses(category);
CREATE INDEX IF NOT EXISTS idx_tieban_verses_fact_meta ON tieban_verses USING GIN (fact_meta);
```

### 8.2 规则集表（SSOT）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_id   SERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  description  TEXT,
  rules        JSONB NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 8.3 物化表（可选：从 RuleSet 导出，提升查询/治理）

#### 8.3.1 卦常量表（SumYao 查表）

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_constants (
  ruleset_name  TEXT NOT NULL,
  upper_trigram TEXT NOT NULL,     -- e.g. "坎"
  lower_trigram TEXT NOT NULL,     -- e.g. "震"
  hex_code      TEXT NOT NULL,     -- e.g. "KAN-ZHEN"
  sum_yao       INT NOT NULL,      -- e.g. 390
  PRIMARY KEY (ruleset_name, hex_code)
);
```

#### 8.3.2 秘数表（可选）

```sql
CREATE TABLE IF NOT EXISTS tieban_secret_keys (
  ruleset_name  TEXT NOT NULL,
  val           INT NOT NULL,
  purpose       TEXT,             -- "jump" / "decrypt" / "offset"...
  PRIMARY KEY (ruleset_name, val)
);
```

> 规范：物化表不是 SSOT；SSOT 始终是 `tieban_rulesets.rules`。

---

## 9. ETL：12k 条文导入与结构化标签抽取

v4 只定义“必须产物与约束”，不规定你从哪里拿到 12k 正文：

### 9.1 必须产物
- `tieban_verses.jsonl`：每行一条条文（见 v3 codex）
- `fact_meta` 抽取规则（正则 + 归一化字典）必须版本化（随 RuleSet）

### 9.2 最小抽取集（建议优先）
- 父母生肖：`父(.)母(.)`、`父命属(.)母命属(.)` 等（需兼容繁体/异体）
- 兄弟/姐妹人数与排行：中文数字解析（“兄弟二人我居长”等）
- 先丧父/先丧母

---

## 10. 作为 `fortune_ai` 并列模块的 API 设计（建议）

v4 统一 ultra 与 codex 的接口思想：

1) 初始化（标准化 + 候选生成）
- `POST /api/tieban/init`（或 `/api/tieban/candidates`）

2) 提交事实（收敛）
- `POST /api/tieban/verify`

3) 锁定（固化 run/state）
- `POST /api/tieban/lock`

4) 获取命书（结构化 JSON）
- `GET /api/tieban/report?run_id=...`

---

## 11. `fortune_user` 最终升级方案（融合 ultra 的 profile/state 与 codex 的 run/history/conversation）

v4 选择“账号（user）-档案（profile）-状态（state）-运行（run）-对话（conversation）”的完整模型：

### 11.1 账号：`fortune_user`（作为 account，稳定标识）

> v4 不要求立刻迁移现有代码；但从“最终模型”视角，`fortune_user` 应承载账号层（openid/渠道等）。

```sql
CREATE TABLE IF NOT EXISTS fortune_user (
  user_id     SERIAL PRIMARY KEY,
  openid      TEXT UNIQUE,
  src         TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.2 档案：`fortune_profile`（物理世界实体，可一账号多档案）

```sql
CREATE TABLE IF NOT EXISTS fortune_profile (
  profile_id        UUID PRIMARY KEY,
  user_id           INT NOT NULL REFERENCES fortune_user(user_id),
  name              TEXT NOT NULL,
  gender            TEXT,
  birth_time_input  TIMESTAMPTZ NOT NULL,
  tz_offset_hours   FLOAT8,
  location          JSONB,                    -- {name, longitude, latitude}
  true_solar_time   TIMESTAMPTZ,              -- 归一化结果（所有模块共用）
  bazi_pillars      JSONB,                    -- 可选缓存：{year,month,day,hour}
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.3 模块状态：`fortune_user_module_state`（每 profile 每模块一条，承载中间态）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_state (
  profile_id    UUID NOT NULL REFERENCES fortune_profile(profile_id),
  module_name   TEXT NOT NULL,               -- "bazi" | "tieban" | ...
  status        TEXT NOT NULL,               -- INIT/CANDIDATES/L1_VERIFY/LOCKED...
  state_json    JSONB NOT NULL,              -- 中间态容器（Tieban: candidates/answers/lock）
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (profile_id, module_name)
);
```

### 11.4 模块运行记录：`fortune_user_module_run`（不可变运行快照）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_run (
  run_id        UUID PRIMARY KEY,
  profile_id    UUID NOT NULL REFERENCES fortune_profile(profile_id),
  module_name   TEXT NOT NULL,
  ruleset_name  TEXT,
  status        TEXT NOT NULL,               -- created/running/done/failed
  input_json    JSONB NOT NULL,
  output_json   JSONB,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fumr_profile_module_time ON fortune_user_module_run(profile_id, module_name, started_at DESC);
```

### 11.5 最新结果索引：`fortune_user_module_latest`

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_latest (
  profile_id    UUID NOT NULL REFERENCES fortune_profile(profile_id),
  module_name   TEXT NOT NULL,
  run_id        UUID NOT NULL REFERENCES fortune_user_module_run(run_id),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (profile_id, module_name)
);
```

### 11.6 历史对话：`fortune_user_conversation`

```sql
CREATE TABLE IF NOT EXISTS fortune_user_conversation (
  message_id     UUID PRIMARY KEY,
  user_id        INT NOT NULL REFERENCES fortune_user(user_id),
  profile_id     UUID REFERENCES fortune_profile(profile_id),
  related_run_id UUID REFERENCES fortune_user_module_run(run_id),
  role           TEXT NOT NULL,              -- user/assistant/system
  model          TEXT,
  content        TEXT NOT NULL,
  meta           JSONB,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fuc_user_time ON fortune_user_conversation(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fuc_profile_time ON fortune_user_conversation(profile_id, created_at DESC);
```

> 该设计覆盖你提出的三类需求：基础信息（user/profile）、模块计算信息（state/run/latest）、历史对话（conversation）。

---

## 12. 验收标准（v4 以可复现为准）

### 12.1 算法可复现
- Engine‑Stem 必须复现 `Base_A=2521` 算例与 `+96` 序列。
- Engine‑Hexagram 必须在给定 `SumYao` 常量表的前提下复现：
  - `KAN-ZHEN -> 1387`
  - `GEN-ZHEN -> 8387`

### 12.2 数据完整性
- `tieban_verses` 达到 12k（或有效区间+缺失清单）。
- `fact_meta` 至少覆盖“父母生肖”这一 L1 核心事实，保证考刻可运行。

### 12.3 考刻闭环可运行
- 能从 KB 生成问题并根据答案收敛候选；最终产出 `LOCKED` 结构化输出。

---

## 附录 A：TAIXUAN_MAP（干支→数）

```
甲/己/子/午 = 9
乙/庚/丑/未 = 8
丙/辛/寅/申 = 7
丁/壬/卯/酉 = 6
戊/癸/辰/戌 = 5
巳/亥 = 4
```

