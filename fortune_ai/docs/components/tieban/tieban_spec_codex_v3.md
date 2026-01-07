# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v3）

**版本**：v3.0  
**范围**：仅 `Tieban 12k`（以 12,000 条文为核心的独立铁板体系）  
**明确排除**：任何 `Shaozi/邵子` 算法、`洛阳派 6144` 条文与其坐标索引体系  
**目标**：输出一个可落地实现的、算法准确性优先的 Tieban 12k 系统设计（架构、算法、算例、知识库、与 `fortune_ai` 集成、`fortune_user` 可扩展数据模型）  
**架构基线**：Context Driven / Pluggable Modules（参见 [os_design_v3.md §1.4](../os/os_design_v3.md#14-context-驱动架构-可插拔模块视图)）  
**依据文档（仓库内）**：
- `fortune_ai/docs/research tieban.md`
- `fortune_ai/docs/research tieban1.md`
- `fortune_ai/docs/tieban v1.md`
- `fortune_ai/docs/tieban_spec_codex.md`
- `fortune_ai/docs/tieban_spec_codex v2 deep.md`
- `fortune_ai/docs/tieban_spec_codex v2 ultra.md`（仅取 Tieban 部分；本文不采纳其 Shaozi 段落）
- `fortune_ai/docs/tieban_kb_design.md`
- `fortune_ai/docs/tieban kowledge gemini.md`

---

## 0. 执行摘要（Tieban 的工程化定义）

Tieban 12k 系统在工程上定义为一个**“时空坐标校准 + 条文索引检索”**系统：

1) 输入：出生信息（时间/地点/性别）+ 用户可确认的事实（六亲、兄弟数、婚姻、先丧等）。  
2) 计算：对出生时间做历法/真太阳时/节气边界处理，得到标准化四柱；基于 Tieban 规则集计算候选条文索引集合（覆盖 8 刻 / 96 刻结构）。  
3) 校准（考时定刻）：通过“问答碰撞”不断收敛候选，最终锁定 `TrueKe（真刻）` 与 `Base/Key（基础数与钥匙）`。  
4) 输出：从 `12k 条文库`检索并编排为命书（六亲 + 大运/岁/月等序列）。  

Tieban 的准确性来自两个前提：

- **条文库完备**：以真实 12,000 条文为 SSOT（单一真源）。  
- **规则集可版本化**：不同流派的“取数/偏移/遇十不用/钥匙/跳码”必须以数据驱动，不得在代码中臆造硬编码。

---

## 1. 系统边界与非目标

### 1.1 范围（In）
- Tieban 12k 全链路：输入标准化 → 候选生成 → 考刻收敛 → 锁定 → 12k 条文检索 → 报告编排。
- 支持多规则集（RuleSet）并行：同一输入可产生多个候选路径，靠考刻事实收敛。
- 知识库（KB）：条文表 + 结构化标签（用于碰撞）+ 规则表 + ETL 方案（文本→结构化）。
- 作为 `fortune_ai` 的一个并列功能模块（与 `bazi`、未来其他模块并列）。
- `fortune_user` 数据模型升级：支持基础信息 + 多模块计算结果 + 历史对话。

### 1.2 非目标（Out）
- 不引入 Shaozi 的任何坐标索引、分卷、6144 条文、洛阳派条文文件。
- 不依赖 LLM 执行 Tieban 计算（Tieban 模块应为确定性计算 + 数据库检索）。

---

## 2. 术语与统一数据结构（Glossary）

- `RuleSet`：一套可版本化的铁板规则集合（流派/参数/表格/钥匙），例如 `ppx_v1`、`tuenhai_v1`。
- `Ke`：刻；一时辰 8 刻（每刻 15 分钟）。本文统一 `ke_index ∈ [1..8]`。
- `96刻`：12 时辰 × 8 刻 = 96。
- `Base`：核心基础数（可由多算法产生候选），例如四柱天干法得到 `2521`。
- `+96 序列`：以 `Base + 96*n` 形成的条文序列（常用于岁/流年条文索引）。
- `遇十不用`：规则口径为“十位/尾数为 0 的处理策略”，必须配置化。
- `钥匙/秘数`：用于非线性跳跃或修正的数集合（“扣入法/加减秘数”），必须记录为规则数据。
- `Verse`：条文；12k 条文库的基本对象，包含 `verse_id` 与 `content`。
- `fact_meta`：条文结构化标签，用于考刻碰撞，例如 `{"father_zodiac":"子","mother_zodiac":"午"}`。

---

## 3. 系统架构（完整模块化设计）

### 3.1 组件划分

1) `tieban.input_normalizer`
   - 责任：将输入的行政时间与地点转换为可计算的标准化时间与四柱；处理节气边界、早晚子时等。

2) `tieban.rule_engine`
   - 责任：加载 `RuleSet`（版本化配置），执行“候选生成”算法，输出候选集合（候选条文 ID + 推导分解）。
   - 要求：所有“表格/偏移/遇十不用/钥匙/跳码”均来自 `RuleSet` 数据，不得硬编码猜测。

3) `tieban.calibration_orchestrator`
   - 责任：管理“考时定刻”交互状态机；根据用户事实不断筛选候选并锁定。

4) `tieban.kb`
   - 责任：12k 条文存储、索引与查询；提供 `fact_meta` 的高效检索能力（如父母生肖、兄弟数、先丧等）。

5) `tieban.report_builder`
   - 责任：把锁定结果转成可展示命书结构（六亲、岁/月/大运等），输出结构化 JSON（可由前端渲染）。

6) `tieban.etl`
   - 责任：从原始条文文本导入、清洗、结构化标签抽取、入库、版本管理。

### 3.2 高层数据流

```
Input (name, gender, birth_time, location, known_facts?)
  -> InputNormalizer (TST + 四柱 + 边界)
  -> RuleEngine (RuleSet 并行：生成候选 Ke/Base/VerseIDs)
  -> CalibrationOrchestrator (问答碰撞：facts -> prune candidates)
  -> Lock (true_ke + base + ruleset + evidence)
  -> KB Query (12k verses)
  -> ReportBuilder (命书编排 JSON)
  -> Persist (fortune_user + module_runs + conversation)
```

---

## 4. 输入标准化（时间、真太阳时、四柱）

> 说明：Tieban 对“刻”的敏感度高于八字常规用法；必须优先保证时间标准化的确定性与可复现。

### 4.1 输入契约（API 层）

必填：
- 出生日期时间：`year, month, day, hour, minute, second?`
- 出生地：`longitude, latitude`（至少经度；纬度用于更精细节气/天文算法）
- `tz_offset_hours`：本地时区偏移（默认 `+8`，但必须可显式传入）
- `gender`

可选：
- 已知事实（用于考刻）：父母生肖、兄弟数、排行、先丧、配偶信息等

### 4.2 真太阳时（TST）标准化（建议算法口径）

从 `research tieban1.md` / `tieban_spec_codex v2 deep.md` 归纳的工程口径：

1) **经度修正（LMT）**  
以时区中央经线 `L_meridian = 15 * tz_offset_hours`（东八区=120°）：
```
delta_minutes = (longitude - L_meridian) * 4
T_lmt = T_local + delta_minutes
```

2) **均时差（EOT）**  
采用可复现近似公式（示例）：
```
theta = 2π(doy - 81) / 365
EOT ≈ 9.87*sin(2*theta) - 7.53*cos(theta) - 1.5*sin(theta)   (minutes)
T_tst = T_lmt + EOT
```

3) **节气边界（必须处理）**  
Tieban 规则通常依赖节气月；对节气交接前后窗口（例如 ±15 分钟）必须产生多盘候选：
```
if abs(T_tst - solar_term_transition_time) <= boundary_window:
  pillars_candidates = [pillars_prev_term, pillars_next_term]
else:
  pillars_candidates = [pillars]
```

> 落地建议：实现时可优先复用 `lunar_python` 的干支能力，再补齐 TST/EOT 的显式计算与节气边界分支管理。

---

## 5. Tieban 核心算法（RuleSet 驱动）

Tieban 算法在资料中呈现为多套口诀/表格/流派。v3 的关键策略是：

- 把“算法执行流程”固定下来（工程稳定）。
- 把“具体表格/偏移/钥匙/跳码”交给 RuleSet 数据（学术/流派可迭代）。

### 5.1 RuleSet 的最小组成（必须齐备才算“算法完整”）

一个可运行的 Tieban RuleSet 至少包含：

1) `stem_number_map`（四柱天干取数表）
2) `stem_number_order`（月→日→时→年 或其他顺序）
3) `hehua_rules`（天干合化与条件）
4) `wuxing_number_map`（五行→数字映射，例如 水1火2木3金4土5）
5) `ke_definition`（一时辰 8 刻的编号与时间段定义）
6) `ke_selection_rule`（如何从四柱推导 ke_index；如“天干数和除以 8 取余”）
7) `jiaze_trigram_number`（八卦数字：坎1、坤2、震3、巽4、乾6、兑7、艮8、离9 等）
8) `jiaze_yao_weights`（爻权：从三十起的累加规则）
9) `avoid_ten_rule`（遇十不用的处理策略）
10) `verse_id_mapping`（把中间数映射为 `verse_id` 的规则：是否需要钥匙、是否有跳码、范围归一化）
11) `secret_keys`（秘数/钥匙集合及其用途：跳跃/偏移/解密）
12) `fact_extraction_patterns`（从条文抽取 fact_meta 的正则与字典）

### 5.2 算法族 A：四柱天干取数法（Fat Bear / 市面常见）

#### 5.2.1 核心映射表（来自 `research tieban.md`）

天干配数：
```
甲1 乙6 丙2 丁7 戊3 己8 庚4 辛9 壬5 癸0
```

取数顺序（资料示例口径）：**月干 → 日干 → 时干 → 年干**。

#### 5.2.2 Step-by-step 算例：Base=2521（严格按文档示例）

输入四柱（示例）：
- 年：甲子
- 月：丙寅
- 日：壬申
- 时：丙午

步骤：
1) 取月干 `丙 → 2`
2) 取日干 `壬 → 5`
3) 取时干 `丙 → 2`
4) 取年干 `甲 → 1`
5) 拼接得到 `Base = 2521`

#### 5.2.3 `+96` 推演（流年/岁序列索引）

按资料示例，生成：
```
2521
2521 + 96 = 2617
2617 + 96 = 2713
...
```

示例序列片段（来自文档展示）：
- `2521`
- `2617`
- `2713`
- `2809`
- `2905`
- `3001`
- `3097`

> 说明：这些数字在“完整 12k 条文库”存在时，直接作为 `verse_id` 进行检索并输出条文。

### 5.3 算法族 B：天干合化修正（五行合化）

资料给出合化条件（节选口径，必须 RuleSet 化）：
- `甲(阳木) + 己(阴土) -> 合化土`：非 `辰戌丑未月` 不化；`午月` 亦可能化；“有戊字间之不化”等细则
- `乙(阴木) + 庚(阳金) -> 合化金`：非 `巳酉丑月` 不化；`申月`亦可能化；“有甲字间之不化”
- `丙(阳火) + 辛(阴金) -> 合化水`：非 `申子辰月` 不化；`亥月`亦可能化；“有庚字间之不化”
- `丁(阴火) + 壬(阳水) -> 合化木`：非 `亥卯未月` 不化；`寅月`亦可能化；“有丙字间之不化”
- `戊(阳土) + 癸(阴水) -> 合化火`：非 `寅午戌月` 不化；`巳月`亦可能化；“有壬字间之不化”

工程化计算步骤（不臆造数值，只定义流程）：
1) 根据四柱天干序列生成 `digits_raw = [d_month, d_day, d_hour, d_year]`
2) 扫描相邻/对应位置的合化对（RuleSet 指定“合化作用的柱位对”）
3) 判定月令条件是否满足合化
4) 若合化成立，把参与合化的天干数字映射到五行数字（RuleSet 的 `wuxing_number_map`）
5) 产生备用 `Base_alt`，与 `Base_raw` 并行进入考刻收敛

### 5.4 算法族 C：八卦加则（JiaZe）

该算法在资料中给出了可复现的数值过程，v3 固化为 RuleSet 驱动算法。

#### 5.4.1 八卦数字（示例口径）

“乾6、兑7、离9、震3、巽4、坎1、艮8、坤2”（用于千位/头尾处理）。

#### 5.4.2 爻权累加（“爻从三十起”）

以示例卦 `水雷屯`（上坎下震）为例，文档给出累加：
```
30 + 30 + 60 + 90 + 120 + 60 = 390
```

> 规则如何从卦爻得到每一爻权值，必须以 RuleSet 表格形式固化（`jiaze_yao_weights`）。

#### 5.4.3 Step-by-step 算例：上坎下震 -> 1387

输入：`上卦=坎(1)`、`下卦=震(3)`，爻权和 `sum_yao=390`

步骤：
1) 千位加上上卦数：`1000 + 390 = 1390`
2) 再减下卦数：`1390 - 3 = 1387`

得到 `1387`（作为中间数或候选索引，具体如何映射到 `verse_id` 由 RuleSet 的 `verse_id_mapping` 决定）。

#### 5.4.4 Step-by-step 算例：上卦于前下卦于后 -> 2645

文档示例将卦中三爻的“干支太玄值”求和后拼接：

上卦坎三爻（示例）：
- `戊子：5+9=14`
- `戊戌：5+5=10`
- `戊申：5+7=12`
上卦合计：`14+10+12=26`

下卦震三爻（示例）：
- `庚辰：8+5=13`
- `庚寅：8+7=15`
- `庚子：8+9=17`
下卦合计：`13+15+17=45`

拼接得到：`2645`

> 该过程依赖 `TAIXUAN_MAP`（干支→数）与“六爻排盘”结果；落地实现必须定义“如何从四柱起卦并得到六爻干支”的具体规则（RuleSet / 查表）。

### 5.5 算法族 D：八刻/九十六刻考刻（考时定刻）

资料给出一种关键口径：**以四柱天干数相加除以 8，余数确定刻**。

#### 5.5.1 ke_index 选择（资料口径）

1) 取四柱天干数（可按 `stem_number_map`）并求和 `S_stem`
2) `r = S_stem % 8`
3) 若 `r == 0`，则 `ke_index = 8`，否则 `ke_index = r`

这条规则用于：
- 直接给出一个“最可能刻位”的候选
- 或者作为 8 刻候选的排序依据（先问最可能刻位）

#### 5.5.2 8 刻候选生成（工程化定义）

完整 Tieban 系统必须能对一个时辰生成 8 个刻位候选，并为每个刻位生成用于碰撞的 `verse_id` 集合：

```
for ke in 1..8:
  for method in enabled_methods:
    numbers = method.compute_numbers(pillars, ke, ruleset)
    verse_ids = ruleset.verse_id_mapping(numbers, ke, ...)
    candidates.append({ke, method, verse_ids, breakdown})
```

> “从 ke 到具体 `verse_id`”在资料中大量依赖口传/表格。v3 不臆造：要求将其落为 RuleSet 的表数据，并在 KB 中用真实 12k 条文验证（考刻碰撞成功率作为验收指标）。

### 5.6 “遇十不用”（配置化，不臆造）

规则文本存在“遇十当不用/遇十不须用”。v3 规定为 RuleSet 配置项：

`avoid_ten_rule` 可选策略示例（实现时只能在 RuleSet 里选一种）：
- `none`：不处理
- `skip`：遇到候选数某位为 10 或尾数为 0 则跳过并取下一候选
- `plus_one`：若 `n % 10 == 0` 则 `n = n + 1`
- `carry`：按特定口径进位（需表格定义）

---

## 6. 考刻（Calibration）状态机与交互

Tieban 的“完整性”不等于“一次计算给出最终命断”，而是必须实现考刻闭环。

### 6.1 状态机（最小可用）

`INIT`
→ `NORMALIZED`
→ `CANDIDATES_READY`（8 刻/96 刻候选生成完成）
→ `L1_VERIFY`（父母/六亲核心事实碰撞）
→ `L2_VERIFY`（兄弟/配偶/先丧等次级事实碰撞）
→ `LOCKED`（锁定真刻与基础数/钥匙）
→ `REPORT_READY`

### 6.2 问题生成（从 KB 中来）

要做到“基于 12k 条文”而不是臆造，系统的提问必须来自 KB 的 `fact_meta`：

- L1（强区分度、高可靠）：父母生肖、双亲存亡先后
- L2（中区分度）：兄弟姐妹数量/排行、配偶属相/姓氏（若条文含）、子女数
- 其他：重大事件类条文（若可结构化）

问答流程建议：
1) 为每个候选 `ke` 拉取对应 `verse_ids` 的条文并抽取 `fact_meta`
2) 合并成“可问问题集”（同一问题去重）
3) 选择区分度最高的问题先问（信息增益最大）

---

## 7. 知识库设计（Tieban 12k：数据库 + JSON 格式）

### 7.1 PostgreSQL 逻辑模型（建议）

#### 7.1.1 12k 条文表

```sql
CREATE TABLE IF NOT EXISTS tieban_verses (
  verse_id       INT PRIMARY KEY,              -- 1..12000（或含跳码区间）
  content_raw    TEXT NOT NULL,                -- 原始条文
  content_clean  TEXT,                         -- 清洗后（可选）
  category       TEXT,                         -- PARENTS / SIBLINGS / SPOUSE / CHILDREN / FORTUNE / OTHER
  fact_meta      JSONB,                        -- 结构化标签（用于考刻碰撞）
  remainder_96   INT,                          -- verse_id % 96（可选物化索引）
  source         TEXT,                         -- 数据来源/版本号/文件标记
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tieban_verses_remainder96 ON tieban_verses(remainder_96);
CREATE INDEX IF NOT EXISTS idx_tieban_verses_category ON tieban_verses(category);
CREATE INDEX IF NOT EXISTS idx_tieban_verses_fact_meta ON tieban_verses USING GIN (fact_meta);
```

#### 7.1.2 RuleSet（版本化规则）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_id   SERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,         -- e.g. "ppx_v1"
  description  TEXT,
  rules        JSONB NOT NULL,               -- 全量规则（表格/参数/钥匙）
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

> 说明：v3 选择把规则作为 `rules JSONB` 存在一行里，方便整体版本冻结与回滚。

### 7.2 JSONL 与 JSON 交换格式（推荐）

#### 7.2.1 `tieban_verses.jsonl`（每行一条）

```json
{"verse_id":3520,"content_raw":"父命属鼠母属马...","category":"PARENTS","fact_meta":{"father_zodiac":"子","mother_zodiac":"午"},"source":"import_v1"}
```

字段约束（建议）：
- `verse_id`：int
- `content_raw`：string
- `category`：string（可空）
- `fact_meta`：object（可空）
- `source`：string

#### 7.2.2 `ruleset.json`（整包规则）

```json
{
  "name": "ppx_v1",
  "stem_number_map": {"甲":1,"乙":6,"丙":2,"丁":7,"戊":3,"己":8,"庚":4,"辛":9,"壬":5,"癸":0},
  "stem_number_order": ["month","day","hour","year"],
  "wuxing_number_map": {"水":1,"火":2,"木":3,"金":4,"土":5},
  "avoid_ten_rule": {"mode":"plus_one"},
  "secret_keys": [1327,1543,5017,133,97,23,41,571,1147,2237],
  "jiaze": {
    "trigram_number": {"乾":6,"兑":7,"离":9,"震":3,"巽":4,"坎":1,"艮":8,"坤":2},
    "yao_weights": "RULE_TABLE_REQUIRED"
  },
  "verse_id_mapping": {
    "mode": "direct_or_keyed",
    "range": {"min":1,"max":12000}
  }
}
```

> 注意：`yao_weights`、`verse_id_mapping` 的细节必须以表/函数数据化补齐，v3 不用猜测代替。

---

## 8. 作为 `fortune_ai` 并列功能模块的集成设计

### 8.1 模块并列（建议统一命名）

`fortune_ai` 业务模块建议统一为：
- `bazi`：排盘与基础命理（现有）
- `rectification`：校准出生时间（现有）
- `tieban`：铁板神算（新增）
- `...`：未来模块（如紫微、梅花、塔罗等）

### 8.2 Tieban API（建议）

1) 生成候选（8 刻/96 刻）
- `POST /api/tieban/candidates`

2) 提交事实，收敛候选
- `POST /api/tieban/verify`

3) 锁定结果并生成命书结构化输出
- `POST /api/tieban/lock`
- `POST /api/tieban/report`

### 8.3 Tieban 与现有 `bazi_engine` 的关系

现状：
- `fortune_ai/services/bazi_engine.py` 提供四柱（干支）与五行摘要，但目前未显式暴露真太阳时与节气边界分支细节。

v3 要求 Tieban 模块的输入标准化必须产出：
- `tst_time`（真太阳时）
- `pillars_candidates[]`（边界时多盘）
- `boundary_flags[]`

若现有 `bazi_engine` 暂不提供这些字段，Tieban 模块应在自身 `input_normalizer` 内补齐，不得把分钟级误差吞掉。

---

## 9. `fortune_user` 数据模型升级（支持：基础信息 + 多模块计算信息 + 历史对话）

> 目标：把“用户基础信息”与“模块运行结果/历史”结构化管理，避免把所有东西塞进 `fortune_user` 单表。

### 9.1 `fortune_user`（保持为基础档案）

现有：
- `fortune_ai/migrations/20251216_fortune_user.sql`
- `fortune_ai/migrations/20251218_fortune_user_v2.sql`

v3 建议把 `fortune_user` 定义为“稳定的基础信息表”，字段建议：
- `user_id`、`name`、`gender`、`birthday`、`location`
- 可选：`bazi_digest`（作为跨模块的基础键）

> `gemini_url` 不再作为用户档案的核心字段：它应属于某次“模块运行”的产物。

### 9.2 模块注册表（未来扩展的 SSOT）

```sql
CREATE TABLE IF NOT EXISTS fortune_module (
  module_name   TEXT PRIMARY KEY,                 -- e.g. "bazi" | "tieban"
  description   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 9.3 用户-模块运行记录（计算信息与结果）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_run (
  run_id        UUID PRIMARY KEY,
  user_id       INT NOT NULL REFERENCES fortune_user(user_id),
  module_name   TEXT NOT NULL REFERENCES fortune_module(module_name),
  ruleset_name  TEXT,                             -- tieban 可用；bazi 可空
  status        TEXT NOT NULL,                     -- created/running/done/failed
  input_json    JSONB NOT NULL,                    -- 模块输入（可包含 birth_data/facts）
  output_json   JSONB,                             -- 模块输出（结构化报告）
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fumr_user_module_time ON fortune_user_module_run(user_id, module_name, started_at DESC);
```

### 9.4 用户模块最新结果索引（便于快速展示）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_latest (
  user_id       INT NOT NULL REFERENCES fortune_user(user_id),
  module_name   TEXT NOT NULL REFERENCES fortune_module(module_name),
  run_id        UUID NOT NULL REFERENCES fortune_user_module_run(run_id),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, module_name)
);
```

### 9.5 历史对话（Conversation）入库

现状：`fortune_ai/services/conversation_store.py` 以本地 `jsonl` 文件方式保存对话。  
v3 要求“表格设计需要支持历史对话信息”，建议新增表：

```sql
CREATE TABLE IF NOT EXISTS fortune_user_conversation (
  message_id    UUID PRIMARY KEY,
  user_id       INT NOT NULL REFERENCES fortune_user(user_id),
  related_run_id UUID NULL REFERENCES fortune_user_module_run(run_id),
  role          TEXT NOT NULL,                     -- user/assistant/system
  model         TEXT,                              -- 可选
  content       TEXT NOT NULL,
  meta          JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fuc_user_time ON fortune_user_conversation(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fuc_run_time ON fortune_user_conversation(related_run_id, created_at);
```

> 迁移策略：可保留文件存储作为兼容层，但新产生的对话建议同步写入该表，形成统一历史检索能力。

---

## 10. Tieban 输出（结构化命书 JSON 规范）

Tieban 模块输出建议为“可渲染 JSON”，而非纯文本（便于前端 UI 与后续模块编排）。

最小输出结构（示例）：
```json
{
  "module": "tieban",
  "ruleset": "ppx_v1",
  "lock": {
    "true_ke": 2,
    "base_candidates": [{"base":2521,"method":"stem_digits","confidence":0.7}],
    "locked_base": 2521
  },
  "evidence": {
    "facts_used": {"parents_zodiac":{"father":"子","mother":"午"}},
    "matched_verses": [3520, 2617]
  },
  "report": {
    "parents": [{"verse_id":3520,"text":"..."}],
    "siblings": [],
    "timeline": [{"age":23,"verse_id":3001,"text":"..."}]
  }
}
```

---

## 11. 验收标准（以准确性为主）

### 11.1 数据验收（KB）
- `tieban_verses` 入库条数达到 12,000（或规则集定义的有效区间并明确缺失列表）。
- 至少完成以下 `fact_meta` 覆盖率目标（工程可操作）：
  - 父母生肖标签覆盖率 ≥ 90%（能被规则匹配到的条文集合内）
  - 兄弟/姐妹人数标签覆盖率 ≥ 70%

### 11.2 算法验收（RuleSet）
- RuleSet 全量配置可被加载并通过自检（schema 校验 + 表格完备性检查）。
- 能复现本文算例：
  - `Base=2521`（四柱天干取数示例）
  - `+96` 推演序列一致
  - `八卦加则 1387/2645` 的计算过程一致（在提供必要起卦/六爻输入前提下）

### 11.3 交互验收（考刻闭环）
- 对于带有 `parents_zodiac` 输入的用户，系统能在 1~3 个问题内显著收敛候选（指标可用“候选规模减少率”衡量）。

---

## 12. 附录：TAIXUAN_MAP（干支→数）

用于八卦加则、干支数理的基础映射（来自文档口诀）：
```
甲/己/子/午 = 9
乙/庚/丑/未 = 8
丙/辛/寅/申 = 7
丁/壬/卯/酉 = 6
戊/癸/辰/戌 = 5
巳/亥 = 4
```
