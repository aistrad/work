# 铁板神数（Tieban 12k）系统规格说明书（Ultra-Combined v8）

**版本**：v8.0（Ultra-Combined 整合版）
**发布日期**：2025-12-25
**范围**：完整 Tieban 12k 系统（系统架构 + 高级算法详解）
**明确排除**：任何 Shaozi/邵子算法、洛阳派 6144 条文与其坐标索引体系

**优先级**：算法完整性与可复现性 > 工程可落地性 > UI

**算法与数据真源（SSOT）**：
- **主链路算法**：`fortune_ai/docs/tieban/research tieban.md`
  - 四柱天干取数、八卦加则不传密数表、日主变卦（±96×4）
  - 12k 条文库（含年龄语义）
- **高级补充算法**：`fortune_ai/docs/tieban/research tieban 2.md`
  - 太玄配数、前后变卦、八卦滾法（48条文）
- **算法配置种子**：`fortune_ai/docs/tieban/tieban_algo_seed.json`
- **命书结构模板**：`fortune_ai/docs/tieban/mingshu spec.md`

**文档整合说明**：
- 本文档整合了 `tieban_spec_codex_v7.md`（系统架构）与 `tieban_spec_ultra_v7.md`（算法详解）
- 修正了 ultra_v7 中八卦滚法的条文号生成公式（从 ×47 改为 ×100+）
- 所有公式均以研究文档的完整算例为验证依据

---

## 目录

- [0. v8 版本说明](#0-v8-版本说明)
- [第一部分：系统架构](#第一部分系统架构)
  - [1. 系统定义](#1-系统定义)
  - [2. 关键概念与不变量](#2-关键概念与不变量)
  - [3. 总体架构](#3-总体架构)
  - [4. 输入标准化](#4-输入标准化)
  - [5. RuleSet 设计](#5-ruleset-设计)
  - [6. 主链路核心算法](#6-主链路核心算法)
  - [7. VerseIdMapping](#7-verseidmapping)
  - [8. 六亲靠刻](#8-六亲靠刻)
  - [9. 命书输出](#9-命书输出)
  - [10. 数据库设计](#10-数据库设计)
  - [11. API 设计](#11-api-设计)
- [第二部分：高级算法详解](#第二部分高级算法详解)
  - [12. 太玄取数算法](#12-太玄取数算法)
  - [13. 前后卦取数算法](#13-前后卦取数算法)
  - [14. 八卦滚法算法](#14-八卦滚法算法)
- [第三部分：实施指南](#第三部分实施指南)
  - [15. 实施路线图](#15-实施路线图)
  - [16. 测试规范](#16-测试规范)
- [附录](#附录)
  - [A. 关键数据表](#a-关键数据表)
  - [B. 验收标准](#b-验收标准)

---

## 0. v8 版本说明

### 0.1 相对 v7 的重大变更

1. **文档整合**
   - 合并 codex_v7（系统架构）与 ultra_v7（算法详解）为统一文档
   - 消除两个文档间的重复内容和冲突描述
   - 统一术语和符号约定

2. **八卦滚法公式修正** ⚠️ 关键变更
   - **修正前（ultra_v7 错误）**：`verse_id = arrange1 × 47 + hidden_number`
   - **修正后（v8 正确）**：使用 ×100+ 组合公式
   - **验证依据**：research tieban 2.md line 375-409（完整48条算例）
   - **示例**：
     ```
     57×100+26=5726  （第一卦：风山渐）
     13×100+93=1393 （第二卦：天火同人）
     42×100+84=4284 （第三卦：雷泽归妹）
     ...（共48条）
     ```

3. **算法体系定位明确化**
   - 主链路算法（stem/hex/daymut）：用于 ke 锁定
   - 高级补充算法（太玄/前后卦/八卦滚）：仅用于命书内容增强，不参与 ke 锁定

4. **新增内容**
   - 详细的算法伪代码（来自 ultra_v7）
   - 完整的计算示例和验证用例
   - 统一的测试规范和验收标准

### 0.2 版本历史

| 版本 | 日期 | 主要变更 | 来源 |
|------|------|---------|------|
| v7.2 | 2025-12-24 | 系统架构规格（codex版） | codex_v7.md |
| v7.1 | 2025-12-25 | 算法详解（ultra版，×47公式） | ultra_v7.md |
| **v8.0** | **2025-12-25** | **整合版，修正八卦滚法公式** | **本文档** |

### 0.3 已知问题与限制

1. **八卦滚法的隐藏秘数系统**
   - research tieban.md 中存在 ×47 公式和隐藏秘数系统
   - 但与 research tieban 2.md 的 ×100+ 公式冲突
   - v8 采用有完整算例验证的 ×100+ 公式
   - ×47 公式可能为不同流派或文档错误，暂不采用

2. **互卦定义差异**
   - 传统定义：2-4爻为内卦，3-5爻为外卦
   - research tieban 2.md 例一结果与"错卦"（六爻全反）一致
   - v8 以实际算例为准，采用错卦定义以保证可复现性

---

# 第一部分：系统架构

## 1. 系统定义

### 1.1 Tieban 的工程化真相

Tieban 12k 系统本质是"**时空标准化 + 候选序列生成 + 以六亲事实做序列碰撞收敛 + 锁定刻分 + 编排命书**"：

```
输入 → 标准化 → 起数 → 建候选 → 靠刻 → 锁定 → 出书
 ↓      ↓        ↓       ↓       ↓      ↓      ↓
出生   TST/   bases  (base,  facts  true_ke  命书
信息   边界    []     ke)     碰撞   (锁定)  JSON
```

**详细流程**：

1) **输入**：出生信息（日期/时间/地点/时区）+ 已知事实（父母生肖、兄弟数、配偶等）

2) **标准化**：TST/EOT/节气边界/时辰交界 → 生成 `pillars_contexts[]`

3) **起数**：Stem/Hex/DayMut 等引擎输出 `base[]`（基数集合）

4) **建候选**：对每个 `base` 枚举 `ke=1..8` 得到候选 `(base, ke, context)`；每个候选都对应一个条文序列 `verse_id_sequence`

5) **靠刻**：将用户提交的事实映射到 KB 中的 `match_verse_ids`，对候选做"序列包含性碰撞"收敛

6) **锁定**：满足最小锁定条件后锁定 `true_ke (+ locked_base + locked_context_id)`

7) **出书**：基于锁定候选的条文序列（Grid Verses）+ 补充算法生成的条文（Generated Verses），合并检索 12k 条文并按固定栏目编排命书

### 1.2 算法体系分层

```
┌─────────────────────────────────────────────────┐
│  命书输出层 (mingshu)                            │
│  - 固定栏目：封面/考刻/六亲/流年                 │
└─────────────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────────────┐
│  补充算法层 (roll_engine) - 不参与 ke 锁定        │
│  - 太玄取数 → 前后卦取数 → 八卦滚法 (48条)        │
└─────────────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────────────┐
│  主链路算法层 (engines) - 用于 ke 锁定            │
│  - Engine-Stem (四柱天干)                        │
│  - Engine-Hex (八卦加则密数表)                   │
│  - Engine-DayMut (日主变卦 ±96×4)                │
└─────────────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────────────┐
│  输入标准化层 (time_engine)                      │
│  - TST/EOT → 节气/时辰边界 → pillars_contexts[]  │
└─────────────────────────────────────────────────┘
```

**关键原则**：
- 主链路算法用于 **ke 锁定**（核心）
- 补充算法仅用于 **命书内容增强**（辅助）
- 补充算法输出对所有 ke 相同，因此不能用于锁定判定

---

## 2. 关键概念与不变量

### 2.1 `base / ke / verse_id_sequence`

- **`base`**：四位数基数（由引擎产生，如四柱天干法得 `2521`）
- **`ke`**：刻位（`1..8`），对应一个时辰（两小时）内的八刻
- **`base_ke = base + (ke - 1)`**：刻位落点
- **`verse_id_sequence`**：从 `base_ke` 起，按 `step=96` 递增直到越界（并跳过空号/避十规则），得到该候选对应的一组条文编号序列

**不变量**：同一候选的条文序列是等差序列（步长 96），因此其所有条文 `verse_id % 96` 相同（忽略 holes/避十造成的缺项）。

### 2.2 "多事实"靠刻的正确语义

对某个事实 `fact`（如父鼠），KB 中存在一个 `match_verse_ids(fact)` 集合。

候选 `c` **命中** 该事实，当且仅当：

```
intersection(c.verse_id_sequence, match_verse_ids(fact)) != ∅
```

**关键点**：不同事实允许命中不同条文（父母条文与兄弟条文通常不是同一条），禁止把多事实做"同一条文交集"。

### 2.3 12k 条文四列结构与年龄语义

`research tieban.md` 的 12k 条文（Verse Block）每行通常为：

```
verse_id age_start age_end content_raw
```

- **`verse_id`**：条文唯一编号（范围 `1001..13000`）
- **`age_start/age_end`**：虚岁应验区间（用于命书年表与"同岁多条"的排序/展示）
  - `0 0`：不限年岁（性格/六亲/总评类常见）
  - `X 0`：仅 X 岁当年
  - `X Y`：X..Y 岁区间
- **`content_raw`**：断语原文（命书必须展示完整原文）

**注意**：`age_start/age_end` 是条文的"时间标注"，不直接参与靠刻过滤；靠刻以 `fact_meta` 为主。

---

## 3. 总体架构

### 3.1 Kernel/Plugin 边界

沿用 v5/v6 的 Kernel/Plugin 边界（Profile 为 SSOT），v8 仅更新 Tieban 的交互与命书层：

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
    Report --> RollEng[roll_engine (补充算法)]
    RollEng --> AlgoSeed[(algo_seed.json)]
  end
```

### 3.2 前端 UI 布局约定

- **左列**（`tb-form-card`）：
  - `#tieban-form`（起盘输入 / 已知事实）
  - `#tb-status`（运行状态，始终保留且可隐藏/显示）
  - `#tb-report`（命书输出，始终保留且可隐藏/显示）

- **右列**（`tb-side`）：
  - `#tb-question-block`（靠刻问题交互，显示/隐藏由后端返回控制）
  - `#rectify-result-section`（校准结果与明细）

以上 ID 为唯一真源，任何脚本仅以 ID 选择，不应依赖节点在 DOM 中的位置或父子层级。

---

## 4. 输入标准化

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

以下算例用于说明"标准化→起数→候选规模"的可复现性（结果以 `research tieban.md` 的表/诀为准）：

**输入**：男，`1980-02-11 14:33:00`，`UTC+8`，北京（经纬度缺省使用城市默认值）

**标准化（示例）**：经度修正 + EOT 得 `tst_time ≈ 1980-02-11 14:04:03`（示例值；以实现为准）

**四柱（按示例 TST）**：`庚申`年 `戊寅`月 `甲寅`日 `辛未`时

**Engine‑Stem**：
- 月干 `戊→3`，日干 `甲→1`，时干 `辛→9`，年干 `庚→4`
- `Base_A = 3194`

**Engine‑Hex（八卦加则密数表，两数）**：
- 年 `庚申`：上卦 `震`、下卦 `艮` → `[3382,4542]`
- 月 `戊寅`：上卦 `坎`、下卦 `震` → `[1387,2645]`
- 日 `甲寅`：上卦 `乾`、下卦 `震` → `[6387,3945]`
- 时 `辛未`：上卦 `巽`、下卦 `艮` → `[4352,3942]`

**Engine‑DayMut（严格模式：仅日柱 primary）**：
- `6387 ± 96×k, k∈{-4..4}` → 9 个基数（含原值）

**候选池规模（示例）**：
- **严格模式**：`bases≈17`（`Stem 1 + Hex 8 + DayMut(Primary) 8` 去重后）→ `17×8=136` 候选
- **宽松/救援**：若 `include_secondary=true`，则日柱 secondary 也做 `±96×4`，总 bases≈25 → `25×8=200` 候选（与现有 UI "200 条候选"一致）

---

## 5. RuleSet 设计

v8 保持 v6/v7 的 RuleSet 思路，但补齐与 `research tieban.md` 对齐的关键字段。

### 5.1 必备字段（最小集）

```json
{
  "verse_id_mapping": {
    "range_min": 1001,
    "range_max": 13000,
    "step": 96,
    "holes": []
  },
  "avoid_ten_rule": {
    "mode": "skip_last_digit_0"
  },
  "stem_digit_map": {
    "甲": 1, "乙": 6, "丙": 2, "丁": 7, "戊": 3,
    "己": 8, "庚": 4, "辛": 9, "壬": 5, "癸": 0
  },
  "trigram_map": {
    "stem_to_trigram": {
      "甲": "乾", "壬": "乾", "丁": "兑", "己": "离",
      "庚": "震", "辛": "巽", "戊": "坎", "丙": "艮",
      "乙": "坤", "癸": "坤"
    },
    "branch_to_trigram": {
      "卯": "乾", "酉": "乾", "辰": "兑",
      "巳": "离", "午": "离", "寅": "震",
      "戌": "巽", "子": "坎", "亥": "坎",
      "未": "艮", "申": "艮", "丑": "坤"
    }
  },
  "hex_secret_table_ref": "八卦加则密数表 (upper,lower)->[primary,secondary]",
  "day_mutation": {
    "enabled": true,
    "step": 96,
    "depth": 4,
    "source": "day_hex_primary",
    "include_secondary": false
  }
}
```

### 5.2 可选字段

- `linear_offsets[]`（内棚/外棚线性偏移族；救援用）
- `secret_jump_search` + `secret_keys_ref`（秘数跳跃；救援用）
- `pillar_scopes`（事实类别→优先柱位，用于起数/排序，不允许绕过 KB 直接断事）
- `algo_seed_ref`（可选：八卦滾/前后卦算法种子表路径；默认 `docs/tieban/tieban_algo_seed.json`）
- `generated_sources`（可选：命书阶段启用哪些补充条文生成器，如 `front_back/roll_48`；默认启用）

---

## 6. 主链路核心算法

### 6.1 Engine‑Stem（四柱天干取数）

**来源**：research tieban.md "以下公布四柱天干的不传密数"

**取数表**：

| 天干 | 甲 | 乙 | 丙 | 丁 | 戊 | 己 | 庚 | 辛 | 壬 | 癸 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 数 | 1 | 6 | 2 | 7 | 3 | 8 | 4 | 9 | 5 | 0 |

**排列顺序（强制）**：**月 → 日 → 时 → 年**

**输出**：`Base_A = digit(月干) digit(日干) digit(时干) digit(年干)`（四位拼接为整数）

> 该规则必须能复现示例：`甲子年 丙寅月 壬申日 丙午时` → `2521`。

**实现示例**：

```python
def engine_stem(pillars: Dict[str, str]) -> int:
    """
    四柱天干取数引擎

    Args:
        pillars: {"year": "甲子", "month": "丙寅", "day": "壬申", "hour": "丙午"}

    Returns:
        四位数基数

    示例:
        >>> engine_stem({"year": "甲子", "month": "丙寅", "day": "壬申", "hour": "丙午"})
        2521
    """
    stem_map = {
        "甲": 1, "乙": 6, "丙": 2, "丁": 7, "戊": 3,
        "己": 8, "庚": 4, "辛": 9, "壬": 5, "癸": 0
    }

    order = ["month", "day", "hour", "year"]
    digits = []

    for pillar in order:
        stem = pillars[pillar][0]  # 取天干
        digits.append(str(stem_map[stem]))

    return int("".join(digits))
```

### 6.2 Engine‑Hex（八卦加则：密数表）

**八卦映射**（research tieban.md "壬甲从乾数…"）：

- **天干配卦**：`壬/甲=乾，乙/癸=坤，庚=震，辛=巽，己=离，戊=坎，丙=艮，丁=兑`
- **地支配卦**：`亥/子=坎，寅=震，巳/午=离，卯/酉=乾，辰=兑，未/申=艮，戌=巽，丑=坤`

**密数表**（research tieban.md "以下是：八卦加则的不传密数"）定义：

```
(upper_trigram, lower_trigram) -> [base_primary, base_secondary]
```

**引擎输出**：四柱逐柱取值，产出最多 `4 × 2` 个 `base`（去重后入候选池）。

**实现示例**：

```python
def engine_hex(pillars: Dict[str, str], ruleset: Dict) -> List[int]:
    """
    八卦加则密数表引擎

    Args:
        pillars: {"year": "甲子", "month": "丙寅", "day": "壬申", "hour": "丙午"}
        ruleset: 包含 trigram_map 和 hex_secret_table

    Returns:
        基数列表 [primary1, secondary1, primary2, secondary2, ...]
    """
    stem_to_trigram = ruleset["trigram_map"]["stem_to_trigram"]
    branch_to_trigram = ruleset["trigram_map"]["branch_to_trigram"]
    hex_secret_table = ruleset["hex_secret_table"]

    bases = []

    for pillar_name in ["year", "month", "day", "hour"]:
        pillar = pillars[pillar_name]
        stem, branch = pillar[0], pillar[1]

        upper_trigram = stem_to_trigram[stem]
        lower_trigram = branch_to_trigram[branch]

        base_values = hex_secret_table[upper_trigram][lower_trigram]
        bases.extend(base_values)  # [primary, secondary]

    return bases
```

### 6.3 Engine‑DayMut（日主变卦：±96×4）

**来源**：research tieban.md

依据 `research tieban.md`：日柱化卦后取两数中的**第一数**（primary），做前后加减 `96` 各四次。

**默认配置（严格模式）**：
- `source="day_hex_primary"`
- `depth=4`
- 输出 `base = primary + 96*k`，`k ∈ {-4,-3,-2,-1,0,1,2,3,4}`

**可选扩大（救援/宽松模式）**：
- `include_secondary=true` 时，secondary 也做同样的 `±96×4`，但必须在 trace 中标记为救援来源，避免污染"严格复盘"。

**实现示例**：

```python
def engine_day_mutation(
    pillars: Dict[str, str],
    ruleset: Dict,
    include_secondary: bool = False
) -> List[int]:
    """
    日主变卦引擎

    Args:
        pillars: {"year": "甲子", ...}
        ruleset: 包含 day_mutation 配置
        include_secondary: 是否包含 secondary 数

    Returns:
        基数列表 [primary-384, primary-288, ..., primary, ..., primary+384]
    """
    day_pillar = pillars["day"]

    # 获取日柱的八卦加则基数
    day_bases = engine_hex({"day": day_pillar}, ruleset)
    primary = day_bases[0]  # 第一数
    secondary = day_bases[1]  # 第二数

    bases = []
    step = ruleset["day_mutation"]["step"]
    depth = ruleset["day_mutation"]["depth"]

    # Primary ±96×4
    for k in range(-depth, depth + 1):
        bases.append(primary + step * k)

    # Secondary ±96×4（可选）
    if include_secondary:
        for k in range(-depth, depth + 1):
            bases.append(secondary + step * k)

    return bases
```

---

## 7. VerseIdMapping

### 7.1 映射规则（与实现一致）

```python
def generate_verse_sequence(base: int, ke: int, ruleset: Dict) -> List[int]:
    """
    从 base 和 ke 生成条文序列

    Args:
        base: 四位数基数
        ke: 刻位 (1-8)
        ruleset: RuleSet 配置

    Returns:
        条文ID序列
    """
    range_min = ruleset["verse_id_mapping"]["range_min"]
    range_max = ruleset["verse_id_mapping"]["range_max"]
    step = ruleset["verse_id_mapping"]["step"]
    holes = ruleset["verse_id_mapping"]["holes"]

    # 计算 base_ke
    base_ke = base + (ke - 1)

    # 归一化到范围
    base_norm = normalize_to_range(base_ke, range_min, range_max)

    # 生成等差序列
    sequence = []
    current = base_norm
    while current <= range_max:
        if current not in holes:
            sequence.append(current)
        current += step

    # 应用避十规则（可选）
    if ruleset.get("avoid_ten_rule"):
        sequence = [v for v in sequence if v % 10 != 0]

    return sequence
```

### 7.2 96 与"八刻分"

`research tieban.md` 给出：
- 一天 `12` 时辰
- 一时辰 `8` 刻
=> 一天共 `96` 刻（`12 × 8`）

因此：`verse_id % 96` 可作为候选序列的快速索引键（工程优化用）。

> 注意：v8 只把 `ke=1..8` 作为刻位索引；更细的"分"（分钟级）需要甲乙斗宫等更高阶算法，属于后续扩展。

---

## 8. 六亲靠刻

### 8.1 输入（facts）

`facts` 统一为结构化字段（入库前归一化）：

- **必填**（用于锁定门槛）：
  - `father_zodiac`（十二支枚举，如 `ZI/CHOU/...`）
  - `mother_zodiac`
  - `siblings_count`（整数）

- **选填**（用于加速收敛/提高置信度）：
  - `spouse_zodiac`
  - `children_count`
  - 其他由 ETL 能稳定抽取的事实字段

### 8.2 校验流程

1) 对每个 fact，从 KB 取 `match_verse_ids(fact)`（由 `fact_meta` 索引支持）。

2) 对每个候选 `c=(base,ke,context)`：
   - 计算/缓存 `c.sequence`（或以 `mod_96` 做快速判定后再精确查 holes/避十）。
   - 对每个 fact 执行"序列包含性命中"判定：命中即可，不要求同条文。

3) 保留满足所有已提交 facts 的候选。

4) 若候选为 0：进入救援（按优先级），并将救援来源写入 trace；救援后仍为 0 则返回冲突报告（提示用户核对输入事实/出生信息/边界上下文）。

### 8.3 救援优先级（必须可解释、可回放）

`facts` 校验失败（候选=0）时：
1) `linear_offsets`（如 `+7n/+21`）
2) `day_mutation.include_secondary=true`（可选：仅当规则集声明）
3) `secret_jump_search`（秘数跳跃）
4) 仍失败：返回 `conflict`（不锁定）

### 8.4 最小锁定条件（v8 强制）

只有同时满足以下条件才允许锁定：

1) `father_zodiac + mother_zodiac + siblings_count` 三类事实均已提交；
2) 对锁定候选能各自找到命中证据（每个事实至少 1 条命中条文 `verse_id`）；
3) 候选收敛到：
   - **唯一候选**（唯一 `(base, ke, context_id)`），或
   - （可选策略）唯一 `true_ke`（所有剩余候选 `ke` 相同，但 base 仍多；此时仅锁 `true_ke`，命书需标注"局未唯一"并禁止输出强断）

锁定时必须写入：
- `locked_base`、`true_ke`、`locked_context_id`
- `evidence`：`{fact_key: {value, matched_verse_ids[]}}`
- `ruleset_hash/kb_snapshot_id/source_digest`

---

## 9. 命书输出

### 9.1 输出形态

- **SSOT**：结构化 JSON（存入 `fortune_user_module_run.output_report`）。
- **渲染**：前端按固定栏目渲染为 Markdown/HTML（可折叠展示，但 JSON 必须包含完整原文）。

### 9.2 固定栏目（与 `mingshu spec.md` 对齐）

#### 1) 封面与卷首（Cover & Preamble）
- 命主信息（姓名/性别）
- 八字排盘（年/月/日/时；含纳音可选）
- 核心参数（阴历可选；`true_ke`；`locked_base`；`locked_context_id`）

#### 2) 考刻定分（Calibration & Verification）
- "已锁定候选"：`locked_base/true_ke`
- "六亲验证条文"：至少包含父、母、兄弟三类证据
- 每条证据展示：`verse_id + content_raw(完整原文)` + `fact_meta`

#### 3) 先天六亲断语（Innate Fate & Kinship）
- 父母宫 / 夫妻宫 / 子息与兄弟（固定小节）
- 选条文规则：优先从锁定候选序列（Grid Verses）中取条文；可追加 `generated_sources` 生成的条文（Generated Verses）作为补充，但必须标注来源，且**不得用于锁定证据**。

#### 4) 流年大运批导（Annual Luck Predictions）
- 输出格式采用表格：年龄/流年干支/条文编码/原文/备注
- 选条文原则：在"锁定候选序列 + generated_sources"的合并条文池中，以 `age_start/age_end` 为唯一时间来源生成年表：
  - `age_start=0 AND age_end=0`：默认不进入年表（进入 `summary/kinship` 等栏目）。
  - `X 0`：落在 X 岁。
  - `X Y`：落在 X..Y 岁区间（年表中可展开为逐岁行，或以区间行展示，取决于前端呈现策略）。
- 若同岁/同区间出现多条：优先展示"支持度更高"的条文（例如来自多引擎/多来源重复命中的条文；无支持度时按 `verse_id` 稳定排序），并在报告中保留全部条文以便复盘。

### 9.3 命书 JSON Schema（v8 建议）

**顶层**：
```json
{
  "run_id": "uuid",
  "ruleset_name": "ppx_v6",
  "locked_base": 6387,
  "true_ke": 3,
  "locked_context_id": "ctx_001",
  "input_snapshot": {...},
  "evidence": {
    "father_zodiac": {"value": "ZI", "matched_verse_ids": [9134]},
    "mother_zodiac": {"value": "HAI", "matched_verse_ids": [9134]},
    "siblings_count": {"value": 2, "matched_verse_ids": [6926]}
  },
  "generated_sources": {
    "front_back": [3788, 2664],
    "roll_48": [5726, 5748, 2657, ...]
  },
  "sections": [
    {"type": "cover", "content": {...}},
    {"type": "calibration", "content": {...}},
    {"type": "kinship", "content": {...}},
    {"type": "annual", "content": {...}}
  ]
}
```

**每条条文（统一结构）**：
```json
{
  "verse_id": 9134,
  "content_raw": "父鼠母猪，先天定数",
  "age_start": 0,
  "age_end": 0,
  "category": "kinship",
  "fact_meta": {
    "father_zodiac": "ZI",
    "mother_zodiac": "HAI"
  },
  "source": "grid",  // "grid" | "generated"
  "confidence": "high"
}
```

---

## 10. 数据库设计

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

### 10.3 RuleSet（SSOT）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_name TEXT PRIMARY KEY,
  rules        JSONB NOT NULL,
  description  TEXT
);
```

### 10.4 KB 与证据的 JSON 约定

**`tieban_verses.fact_meta`（归一化后）**：

- 生肖字段统一为地支枚举：`ZI/CHOU/YIN/MAO/CHEN/SI/WU/WEI/SHEN/YOU/XU/HAI`
- 中文生肖到枚举映射：`鼠=ZI, 牛=CHOU, 虎=YIN, 兔=MAO, 龙=CHEN, 蛇=SI, 马=WU, 羊=WEI, 猴=SHEN, 鸡=YOU, 狗=XU, 猪=HAI`

**示例**：
```json
{
  "father_zodiac": "ZI",
  "mother_zodiac": "HAI",
  "source_ref": {"file": "fortune_ai/docs/tieban/research tieban.md", "line": 11967}
}
```

---

## 11. API 设计

### 11.1 `POST /api/tieban/solve`

**请求**：出生信息 + `facts`（一次性提交）

**响应（未锁定）**：
```json
{
  "candidate_stats": {
    "total_candidates": 136,
    "contexts_count": 1
  },
  "evidence": {
    "father_zodiac": {
      "value": "ZI",
      "matched_verse_ids": [9134, 10256]
    },
    "mother_zodiac": {
      "value": "HAI",
      "matched_verse_ids": [9134]
    },
    "siblings_count": {
      "value": 2,
      "matched_verse_ids": []
    }
  },
  "lock": null,
  "suggested_fields": ["siblings_count"]
}
```

**响应（已锁定）**：
```json
{
  "lock": {
    "locked_base": 6387,
    "true_ke": 3,
    "locked_context_id": "ctx_001"
  },
  "report_url": "/api/tieban/report/{run_id}"
}
```

### 11.2 兼容接口（保留 v6 的 init/verify 但语义升级）

- `POST /api/tieban/init`：仅生成上下文与候选池（不出题）
- `POST /api/tieban/verify`：允许一次提交多个 facts（不再返回"下一题"）

---

# 第二部分：高级算法详解

## 12. 太玄取数算法

### 12.1 算法描述

**目的**：将天干地支转换为太玄数，为前后卦取数和八卦滚法提供基础数据

**来源**：
- research tieban 2.md "太玄配数诀"（line 103）
- services/tieban/roll_engine.py 中的实现

**复杂度**：⭐ 简单

**依赖**：无

### 12.2 核心口诀

```
太玄配数诀：
甲己子午九，乙庚丑未八，丙辛寅申七，
丁壬卯酉六，戊癸辰戌五，巳亥单四数。
```

### 12.3 数据结构

#### 输入

```python
{
    "pillars": {
        "year": "庚戌",
        "month": "己丑",
        "day": "壬申",
        "hour": "丙午"
    }
}
```

#### 太玄映射表

```python
taixuan_map = {
    # 天干
    "甲": 9, "己": 9,
    "乙": 8, "庚": 8,
    "丙": 7, "辛": 7,
    "丁": 6, "壬": 6,
    "戊": 5, "癸": 5,

    # 地支
    "子": 9, "午": 9,
    "丑": 8, "未": 8,
    "寅": 7, "申": 7,
    "卯": 6, "酉": 6,
    "辰": 5, "戌": 5,
    "巳": 4, "亥": 4
}
```

#### 输出

```python
{
    "year": {"stem": 8, "branch": 5, "sum": 13},
    "month": {"stem": 9, "branch": 8, "sum": 17},
    "day": {"stem": 6, "branch": 7, "sum": 13},
    "hour": {"stem": 7, "branch": 9, "sum": 16}
}
```

### 12.4 算法逻辑

```python
def engine_taixuan(pillars: Dict[str, str]) -> Dict[str, Dict[str, int]]:
    """
    太玄取数引擎

    Args:
        pillars: {"year": "庚戌", "month": "己丑", "day": "壬申", "hour": "丙午"}

    Returns:
        {"year": {"stem": 8, "branch": 5, "sum": 13}, ...}

    规则（research tieban 2.md line 103）:
        甲己子午九，乙庚丑未八，丙辛寅申七，
        丁壬卯酉六，戊癸辰戌五，巳亥单四数
    """
    taixuan_map = {
        # 天干
        "甲": 9, "己": 9,
        "乙": 8, "庚": 8,
        "丙": 7, "辛": 7,
        "丁": 6, "壬": 6,
        "戊": 5, "癸": 5,

        # 地支
        "子": 9, "午": 9,
        "丑": 8, "未": 8,
        "寅": 7, "申": 7,
        "卯": 6, "酉": 6,
        "辰": 5, "戌": 5,
        "巳": 4, "亥": 4
    }

    result = {}

    for pillar_name, pillar in pillars.items():
        stem, branch = pillar[0], pillar[1]

        stem_tx = taixuan_map[stem]
        branch_tx = taixuan_map[branch]

        result[pillar_name] = {
            "stem": stem_tx,
            "branch": branch_tx,
            "sum": stem_tx + branch_tx
        }

    return result
```

### 12.5 计算示例

**输入**：
```python
pillars = {
    "year": "庚戌",   # 庚=8, 戌=5
    "month": "己丑",  # 己=9, 丑=8
    "day": "壬申",    # 壬=6, 申=7
    "hour": "丙午"    # 丙=7, 午=9
}
```

**输出**：
```python
{
    "year": {"stem": 8, "branch": 5, "sum": 13},
    "month": {"stem": 9, "branch": 8, "sum": 17},
    "day": {"stem": 6, "branch": 7, "sum": 13},
    "hour": {"stem": 7, "branch": 9, "sum": 16}
}
```

---

## 13. 前后卦取数算法

### 13.1 算法描述

**目的**：生成前卦（六亲）和后卦（运程），拼装为2位条文号

**来源**：
- research tieban 2.md "前后变卦取数诀"（line 81/178）
- services/tieban/roll_engine.py 中的 generate_front_back_verses()

**复杂度**：⭐⭐ 中等

**依赖**：`engine_taixuan`

### 13.2 核心口诀

```
前后变卦取数诀：
干支化数数化卦，月前日后甲己九。
若然查得刻中数，信手拈来可成章。
```

### 13.3 数据结构

#### 输入

```python
{
    "pillars": {
        "year": "辛丑",
        "month": "庚寅",
        "day": "丙子",
        "hour": "己丑"
    },
    "taixuan_map": {...},  # 来自 engine_taixuan
    "luoshu_trigram": {...},
    "center_policy": "yang_male_kun"  # 阳男阴女寄坤；阴男阳女寄艮
}
```

#### 输出

```python
{
    "front_hex": {
        "upper_trigram": "艮",     # 上卦（前卦）
        "lower_trigram": "震",     # 下卦
        "hex_name": "山雷颐",
        "upper_number": 7,
        "lower_number": 4,
        "source": "year+month"
    },
    "back_hex": {
        "upper_trigram": "乾",     # 上卦（后卦）
        "lower_trigram": "乾",
        "hex_name": "乾为天",
        "upper_number": 6,
        "lower_number": 6,
        "source": "day+hour"
    },
    "verse_ids": [3788, 2664],     # 生成的条文号
    "mutation_hex": {              # 互卦
        "front_mut_upper": "坤",
        "front_mut_lower": "兑",
        "back_mut_upper": "乾",
        "back_mut_lower": "乾"
    }
}
```

### 13.4 算法逻辑

#### 步骤1: 前卦（六亲）计算

```python
def calculate_front_hex(
    year_taixuan: Dict[str, int],
    month_taixuan: Dict[str, int],
    luoshu_trigram: Dict[int, str],
    center_policy: str
) -> Dict[str, Any]:
    """
    前卦（六亲）: 年柱+月柱

    规则:
    1. 上卦 = rem8(tx(year_stem) + tx(year_branch))
    2. 下卦 = rem8(tx(month_stem) + tx(month_branch))
    3. 数字→卦：用 luoshu_trigram，5为"中宫"，按center_policy寄宫
    """
    # 计算上下卦数字（余8，0视为8）
    u_digit = (year_taixuan["stem"] + year_taixuan["branch"]) % 8
    l_digit = (month_taixuan["stem"] + month_taixuan["branch"]) % 8

    u_digit = 8 if u_digit == 0 else u_digit
    l_digit = 8 if l_digit == 0 else l_digit

    # 数字转卦
    upper_trigram = luoshu_trigram.get(u_digit)
    lower_trigram = luoshu_trigram.get(l_digit)

    # 处理中宫(5)
    if upper_trigram == "中宫":
        upper_trigram = apply_center_policy(5, center_policy)
    if lower_trigram == "中宫":
        lower_trigram = apply_center_policy(5, center_policy)

    return {
        "upper_trigram": upper_trigram,
        "lower_trigram": lower_trigram,
        "upper_number": u_digit,
        "lower_number": l_digit,
        "hex_name": f"{upper_trigram}{lower_trigram}",
        "source": "year+month"
    }
```

#### 步骤2: 后卦（运程）计算

```python
def calculate_back_hex(
    day_taixuan: Dict[str, int],
    hour_taixuan: Dict[str, int],
    luoshu_trigram: Dict[int, str],
    center_policy: str
) -> Dict[str, Any]:
    """
    后卦（运程）: 日柱+时柱

    规则（"去十不用"）:
    1. 上卦 = strip_tens(tx(day_stem) + tx(day_branch))
    2. 下卦 = strip_tens(tx(hour_stem) + tx(hour_branch))
    3. strip_tens: 优先取个位；若个位为0则取十位

    示例: 17 → 7, 10 → 1, 20 → 2
    """
    def strip_tens(x: int) -> int:
        ones = x % 10
        return ones if ones != 0 else x // 10

    # 计算上下卦数字（去十）
    u_digit = strip_tens(day_taixuan["stem"] + day_taixuan["branch"])
    l_digit = strip_tens(hour_taixuan["stem"] + hour_taixuan["branch"])

    # 确保范围 1-8
    u_digit = u_digit % 8
    l_digit = l_digit % 8
    u_digit = 8 if u_digit == 0 else u_digit
    l_digit = 8 if l_digit == 0 else l_digit

    # 数字转卦
    upper_trigram = luoshu_trigram.get(u_digit)
    lower_trigram = luoshu_trigram.get(l_digit)

    # 处理中宫
    if upper_trigram == "中宫":
        upper_trigram = apply_center_policy(5, center_policy)
    if lower_trigram == "中宫":
        lower_trigram = apply_center_policy(5, center_policy)

    return {
        "upper_trigram": upper_trigram,
        "lower_trigram": lower_trigram,
        "upper_number": u_digit,
        "lower_number": l_digit,
        "hex_name": f"{upper_trigram}{lower_trigram}",
        "source": "day+hour"
    }
```

#### 步骤3: 条文号组装

```python
def assemble_verse_id(
    hex_data: Dict[str, Any],
    luoshu_numbers: Dict[str, int]
) -> int:
    """
    条文号组装规则:

    1. 百位(H) = luoshu_numbers[upper_trigram]
    2. 千位(K) = strip_tens(H + 6)
    3. 十位(T) = 互卦(2-4爻)的 luoshu_numbers[lower_trigram]
    4. 个位(O) = 互卦(3-5爻)的 luoshu_numbers[upper_trigram]

    verse_id = K*1000 + H*100 + T*10 + O

    归一化: 若超出 [1001, 13000]，按 12000 周期调整
    """
    upper = hex_data["upper_trigram"]
    lower = hex_data["lower_trigram"]

    # 百位
    H = luoshu_numbers[upper]

    # 千位（去十）
    K = (H + 6) % 10
    if K == 0:
        K = (H + 6) // 10 % 10

    # 互卦（2-4爻为内卦，3-5爻为外卦）
    # 注意：v8 以错卦（六爻全反）为准，以保证可复现性
    mutation = get_mutation_hex(upper, lower)

    T = luoshu_numbers[mutation["lower"]]  # 十位
    O = luoshu_numbers[mutation["upper"]]  # 个位

    # 组装
    verse_id = K * 1000 + H * 100 + T * 10 + O

    # 归一化到 [1001, 13000]
    while verse_id > 13000:
        verse_id -= 12000
    while verse_id < 1001:
        verse_id += 12000

    return verse_id
```

### 13.5 完整算法实现

```python
def engine_front_back_hex(
    pillars: Dict[str, str],
    taixuan_map: Dict[str, int],
    luoshu_trigram: Dict[int, str],
    luoshu_numbers: Dict[str, int],
    center_policy: str
) -> Dict[str, Any]:
    """
    前后卦取数引擎（完整流程）

    Returns:
        {
            "front_hex": {...},
            "back_hex": {...},
            "verse_ids": [vid_front, vid_back],
            "mutation_hex": {...}
        }
    """
    # 步骤1: 计算太玄数
    taixuan_data = engine_taixuan(pillars)

    # 步骤2: 前卦（年+月）
    front_hex = calculate_front_hex(
        taixuan_data["year"],
        taixuan_data["month"],
        luoshu_trigram,
        center_policy
    )

    # 步骤3: 后卦（日+时）
    back_hex = calculate_back_hex(
        taixuan_data["day"],
        taixuan_data["hour"],
        luoshu_trigram,
        center_policy
    )

    # 步骤4: 条文号组装
    vid_front = assemble_verse_id(front_hex, luoshu_numbers)
    vid_back = assemble_verse_id(back_hex, luoshu_numbers)

    # 步骤5: 互卦计算
    mutation_hex = {
        "front_mut_upper": get_mutation_trigram(front_hex["upper"], front_hex["lower"])["upper"],
        "front_mut_lower": get_mutation_trigram(front_hex["upper"], front_hex["lower"])["lower"],
        "back_mut_upper": get_mutation_trigram(back_hex["upper"], back_hex["lower"])["upper"],
        "back_mut_lower": get_mutation_trigram(back_hex["upper"], back_hex["lower"])["lower"]
    }

    return {
        "front_hex": front_hex,
        "back_hex": back_hex,
        "verse_ids": [vid_front, vid_back],
        "mutation_hex": mutation_hex
    }
```

---

## 14. 八卦滚法算法

### 14.1 算法描述

**目的**：从基本卦推导出8个卦，每个卦生成6条条文号，共48条

**来源**：
- research tieban 2.md line 214-409
- services/tieban/roll_engine.py 中的 generate_roll_verses()

**复杂度**：⭐⭐⭐⭐⭐ 复杂

**依赖**：`engine_taixuan`

**⚠️ 关键修正（v8）**：
- **错误公式**（ultra_v7）：`verse_id = arrange1 × 47 + hidden_number`
- **正确公式**（v8）：使用 ×100+ 组合公式
- **验证依据**：research tieban 2.md line 375-409（完整48条算例）

### 14.2 数据结构

#### 输入

```python
{
    "base_hex": "天地否",
    "base_number": 4410,
    "birth_year": "乙丑",
    "yuan_yun": "下元",
    "gender": "male",
    "taixuan_map": {...},
    "trigram_maps": {
        "luoshu_trigram": {...},
        "arrange": {...},      # 八卦排列洛书数序
        "xian_tian": {...},    # 先天八卦洛书数序
        "hou_tian": {...}      # 后天八卦洛书数序
    },
    "basic_sequence_table": {...}
}
```

#### 输出

```python
{
    "hexes": [
        {
            "order": 1,
            "name": "风山渐",
            "arrange_numbers": [57, 26, 48],
            "verse_ids": [5726, 5748, 2657, 2648, 4857, 4826]
        },
        # ... 共8个卦
    ],
    "total_verses": 48,
    "verse_ids": [...]
}
```

### 14.3 算法流程

#### 阶段1-4: 生成前四卦

```python
def generate_first_4_hexes(
    base_hex: Tuple[str, str],  # (upper, lower)
    val: int
) -> List[Tuple[str, str]]:
    """
    生成前四卦

    Args:
        base_hex: 基本卦 (上卦, 下卦)，如 ("乾", "坤")
        val: 基本数序 + year_modifier

    Returns:
        [(hex1_upper, hex1_lower), (hex2_upper, hex2_lower), ...]

    规则:
    1. 第一卦：基本卦 2-4爻为内卦，3-5爻为外卦
    2. 第二卦：val % 9 决定变爻（余0翻3与6）
    3. 第三卦：第一卦的错卦（六爻全反）
    4. 第四卦：第二卦的错卦
    """
    upper, lower = base_hex

    # 第一卦：互卦法（2-4爻内卦，3-5爻外卦）
    hex1_upper = lower  # 简化示例，实际需根据爻位推导
    hex1_lower = lower
    hex1 = (hex1_upper, hex1_lower)

    # 第二卦：变爻法（%9）
    r9 = val % 9
    hex2 = mutate_hex_by_yao(base_hex, r9, divisor=9)

    # 第三卦：第一卦的错卦
    hex3 = get_opposite_hex(hex1)

    # 第四卦：第二卦的错卦
    hex4 = get_opposite_hex(hex2)

    return [hex1, hex2, hex3, hex4]
```

#### 阶段5-8: 生成后四卦

```python
def generate_last_4_hexes(
    first_4_hexes: List[Tuple[str, str]],
    val: int
) -> List[Tuple[str, str]]:
    """
    生成后四卦

    规则:
    1. val % 6 得到变爻位置（余0视为6）
    2. 对前四卦：变指定爻 + 上下卦对调

    Returns:
        [(hex5_upper, hex5_lower), ..., (hex8_upper, hex8_lower)]
    """
    r6 = val % 6
    r6 = 6 if r6 == 0 else r6

    last_4_hexes = []

    for hex_upper, hex_lower in first_4_hexes:
        # 变爻
        mutated = mutate_hex_by_yao((hex_upper, hex_lower), r6, divisor=6)

        # 上下卦对调
        swapped = (mutated[1], mutated[0])

        last_4_hexes.append(swapped)

    return last_4_hexes
```

#### 阶段9: 生成48条文号（×100+ 公式）

```python
def generate_48_verse_ids(
    hexes: List[Tuple[str, str]],
    trigram_maps: Dict[str, Dict[str, int]]
) -> List[int]:
    """
    从8个卦生成48个条文号

    ⚠️ 使用 ×100+ 公式（research tieban 2.md line 269-283, 375-409）

    对每个卦:
        arrange = A[upper]*10 + A[lower]
        xian_tian = X[upper]*10 + X[lower]
        hou_tian = H[upper]*10 + H[lower]

    生成6条:
        1. arrange*100 + xian_tian
        2. arrange*100 + hou_tian
        3. xian_tian*100 + arrange
        4. xian_tian*100 + hou_tian
        5. hou_tian*100 + arrange
        6. hou_tian*100 + xian_tian

    总计: 8卦 × 6条 = 48条

    验证: research tieban 2.md line 375-409
        ① 57×100+26=5726  ② 13×100+93=1393  ③ 42×100+84=4284
        ① 57×100+48=5748  ② 13×100+69=1369  ③ 42×100+37=4237
        ...
    """
    all_verse_ids = []

    A = trigram_maps["arrange"]  # 八卦排列洛书数序
    X = trigram_maps["xian_tian"]  # 先天八卦洛书数序
    H = trigram_maps["hou_tian"]  # 后天八卦洛书数序

    for upper, lower in hexes:
        # 三组数序
        arrange = A[upper] * 10 + A[lower]
        xian_tian = X[upper] * 10 + X[lower]
        hou_tian = H[upper] * 10 + H[lower]

        # 6条组合
        verse_ids = [
            arrange * 100 + xian_tian,
            arrange * 100 + hou_tian,
            xian_tian * 100 + arrange,
            xian_tian * 100 + hou_tian,
            hou_tian * 100 + arrange,
            hou_tian * 100 + xian_tian
        ]

        # 归一化到 [1001, 13000]
        normalized = []
        for vid in verse_ids:
            while vid > 13000:
                vid -= 12000
            while vid < 1001:
                vid += 12000
            normalized.append(vid)

        all_verse_ids.extend(normalized)

    return all_verse_ids
```

### 14.4 完整算法实现

```python
def engine_baigua_roll(
    base_hex: str,
    base_number: int,
    birth_year: str,
    yuan_yun: str,
    gender: str,
    taixuan_map: Dict[str, int],
    trigram_maps: Dict[str, Any],
    basic_sequence_table: Dict[str, Dict[str, int]]
) -> Dict[str, Any]:
    """
    八卦滚法引擎（完整流程）

    Returns:
        {
            "hexes": [...],
            "total_verses": 48,
            "verse_ids": [...]
        }
    """
    # 步骤1: 求基本卦
    basic_hex = get_basic_hex(pillars, taixuan_map, trigram_maps)

    # 步骤2: 基本数序
    basic_sequence = get_basic_sequence(basic_hex, basic_sequence_table)

    # 步骤3: 出生年修正数
    year_modifier = get_year_modifier(birth_year, yuan_yun, gender, taixuan_map)

    # 步骤4: 计算值
    val = basic_sequence + year_modifier

    # 步骤5-8: 生成8个卦
    first_4 = generate_first_4_hexes(basic_hex, val)
    last_4 = generate_last_4_hexes(first_4, val)
    all_8_hexes = first_4 + last_4

    # 步骤9: 生成48条文
    verse_ids = generate_48_verse_ids(all_8_hexes, trigram_maps)

    # 构建输出结构
    hexes_output = []
    for i, (upper, lower) in enumerate(all_8_hexes, 1):
        A = trigram_maps["arrange"]
        X = trigram_maps["xian_tian"]
        H = trigram_maps["hou_tian"]

        arrange = A[upper] * 10 + A[lower]
        xian_tian = X[upper] * 10 + X[lower]
        hou_tian = H[upper] * 10 + H[lower]

        start_idx = (i - 1) * 6
        end_idx = start_idx + 6
        hex_verses = verse_ids[start_idx:end_idx]

        hexes_output.append({
            "order": i,
            "name": f"{upper}{lower}",
            "arrange_numbers": [arrange, xian_tian, hou_tian],
            "verse_ids": hex_verses
        })

    return {
        "hexes": hexes_output,
        "total_verses": 48,
        "verse_ids": verse_ids,
        "source": "research tieban 2.md line 214-409"
    }
```

### 14.5 完整验证示例

**来源**：research tieban 2.md line 285-409

**输入数据**:
```python
{
    "base_hex": "天地否",
    "base_number": 4410,
    "birth_year": "乙丑",
    "yuan_yun": "下元",
    "gender": "male"
}
```

**8个卦的推导**:
```python
# 基本卦：天地否
# 基本数序：4410
# 出生年修正：下元乙丑 → 8×10 + 8×1 = 88
# val = 4410 + 88 = 4498

# 第一卦：风山渐（互卦法）
# 第二卦：天火同人（4498 % 9 = 4 → 变4爻）
# 第三卦：雷泽归妹（第一卦的错卦）
# 第四卦：地水师（第二卦的错卦）
# 第五至八卦：4498 % 6 = 4 → 变4爻 + 上下对调
```

**三组数序**（research tieban 2.md line 341-371）:
```python
第一卦（风山渐）: arrange=57, xian_tian=26, hou_tian=48
第二卦（天火同人）: arrange=13, xian_tian=93, hou_tian=69
第三卦（雷泽归妹）: arrange=42, xian_tian=84, hou_tian=37
第四卦（地水师）: arrange=86, xian_tian=17, hou_tian=21
第五卦（山天大畜）: arrange=71, xian_tian=69, hou_tian=86
第六卦（火风鼎）: arrange=35, xian_tian=32, hou_tian=94
第七卦（泽地萃）: arrange=28, xian_tian=41, hou_tian=72
第八卦（水雷屯）: arrange=64, xian_tian=78, hou_tian=13
```

**48条文号**（research tieban 2.md line 375-409）:
```
① 57×100+26=5726   ② 13×100+93=1393   ③ 42×100+84=4284
① 57×100+48=5748   ② 13×100+69=1369   ③ 42×100+37=4237
① 26×100+57=2657   ② 93×100+13=9313   ③ 84×100+42=8442
① 26×100+48=2648   ② 93×100+69=9369   ③ 84×100+37=8437
① 48×100+57=4857   ② 69×100+13=6913   ③ 37×100+42=3742
① 48×100+26=4826   ② 69×100+93=6993   ③ 37×100+84=3784

④ 86×100+17=8617   ⑤ 71×100+69=7169   ⑥ 35×100+32=3532
④ 86×100+21=8621   ⑤ 71×100+86=7186   ⑥ 35×100+94=3594
④ 17×100+86=1786   ⑤ 69×100+71=6971   ⑥ 32×100+35=3235
④ 17×100+21=1721   ⑤ 69×100+86=6986   ⑥ 32×100+94=3294
④ 21×100+86=2186   ⑤ 86×100+71=8671   ⑥ 94×100+35=9435
④ 21×100+17=2117   ⑤ 86×100+69=8669   ⑥ 94×100+32=9432

⑦ 28×100+41=2841   ⑧ 64×100+78=6478
⑦ 28×100+72=2872   ⑧ 64×100+13=6413
⑦ 41×100+28=4128   ⑧ 78×100+64=7864
⑦ 41×100+72=4172   ⑧ 78×100+13=7813
⑦ 72×100+28=7228   ⑧ 13×100+78=1378
⑦ 72×100+41=7241   ⑧ 13×100+64=1364
```

**输出结果**:
```python
{
    "hexes": [
        {"order": 1, "name": "风山渐", "arrange_numbers": [57, 26, 48],
         "verse_ids": [5726, 5748, 2657, 2648, 4857, 4826]},
        {"order": 2, "name": "天火同人", "arrange_numbers": [13, 93, 69],
         "verse_ids": [1393, 1369, 9313, 9369, 6913, 6993]},
        # ... 共8个卦
    ],
    "total_verses": 48,
    "verse_ids": [5726, 5748, 2657, ...],  # 48个条文号
    "source": "research tieban 2.md line 285-409",
    "verified": True
}
```

---

# 第三部分：实施指南

## 15. 实施路线图

### 15.1 Phase 1: 主链路验证（1-2天）

**目标**：验证现有主链路算法的正确性

**任务**：
1. 验证 Engine-Stem 与 research tieban.md 一致性
2. 验证 Engine-Hex 密数表数据完整性
3. 验证 Engine-DayMut ±96×4 实现
4. 运行现有测试套件，确保全部通过

**验收标准**：
- 所有现有测试通过
- 算例（1980-02-11）结果与文档一致

### 15.2 Phase 2: 高级算法实现（5-7天）

**任务**：
1. 实现太玄取数引擎（engine_taixuan）
   - 完成 ETL 解析太玄映射表
   - 单元测试覆盖所有干支组合

2. 实现前后卦取数引擎（engine_front_back_hex）
   - 完成前卦/后卦计算逻辑
   - 实现条文号组装（含归一化）
   - 金标准测试：验证2条条文号生成

3. 实现八卦滚法引擎（engine_baigua_roll）
   - 完成8卦推导逻辑
   - 实现 ×100+ 公式生成48条文
   - **金标准测试**：使用 research tieban 2.md line 375-409 的48条算例

**验收标准**：
- 每个引擎独立测试通过
- 八卦滚法48条与文档完全一致
- 代码覆盖率 > 90%

### 15.3 Phase 3: 集成测试（3-5天）

**任务**：
1. 集成 roll_engine 到主流程
2. 验证补充算法不参与 ke 锁定
3. 端到端测试：完整流程（输入→锁定→命书）
4. 性能测试：确保响应时间 < 5秒

**验收标准**：
- 端到端测试通过
- 命书包含 Grid + Generated 条文
- 补充条文正确标注来源

### 15.4 Phase 4: UI 与优化（2-3天）

**任务**：
1. 更新 UI 布局（左列固定状态/报告）
2. 优化靠刻交互（批量提交模式）
3. 添加算法来源标注
4. 性能优化（缓存、并行计算）

**验收标准**：
- UI 布局符合规范
- 用户体验流畅
- 性能达标

---

## 16. 测试规范

### 16.1 单元测试结构

```yaml
tests/
  test_tieban/
    test_engines.py           # 主链路引擎测试
      test_engine_stem.py
      test_engine_hex.py
      test_engine_day_mut.py
    test_roll_engines.py      # 补充算法引擎测试
      test_engine_taixuan.py
      test_engine_front_back.py
      test_engine_baigua_roll.py
    test_integration.py        # 集成测试
      test_full_flow.py
      test_lock_conditions.py
    test_gold_standard.py      # 金标准测试
      test_baigua_roll_48.py  # 八卦滚法48条验证
```

### 16.2 金标准测试用例

#### 太玄取数

```yaml
test_case: taixuan_complete_mapping
source: "research tieban 2.md line 103"
input:
  year: "庚戌"
expected:
  year_stem: 8
  year_branch: 5
  year_sum: 13
```

#### 前后卦取数

```yaml
test_case: front_back_verse_ids
source: "research tieban 2.md line 81-178"
input:
  pillars: {...}
expected:
  front_verse_id: 3788
  back_verse_id: 2664
```

#### 八卦滚法（最重要）

```yaml
test_case: baigua_roll_48_verses
source: "research tieban 2.md line 375-409"
input:
  base_hex: "天地否"
  base_number: 4410
  birth_year: "乙丑"
  yuan_yun: "下元"
expected:
  total_verses: 48
  verse_ids:
    - 5726  # 第一卦第一条
    - 5748
    - 2657
    - 2648
    - 4857
    - 4826
    - 1393  # 第二卦第一条
    - 1369
    - 9313
    - 9369
    - 6913
    - 6993
    # ... 共48条
  verification: "与 line 375-409 完全一致"
```

### 16.3 集成测试

```yaml
test_case: full_flow_with_generated_verses
input:
  birth_time: "1980-02-11 14:33:00"
  timezone: "UTC+8"
  location: "北京"
  facts:
    father_zodiac: "ZI"
    mother_zodiac: "HAI"
    siblings_count: 2
expected:
  lock:
    locked_base: 6387  # 示例
    true_ke: 3
  report:
    generated_sources:
      front_back: [3788, 2664]
      roll_48: [5726, 5748, ...]  # 48条
    sections:
      - type: "cover"
      - type: "calibration"
      - type: "kinship"
      - type: "annual"
```

---

# 附录

## A. 关键数据表

### A.1 太玄数映射表

```python
TAIXUAN_MAP = {
    # 天干
    "甲": 9, "己": 9,
    "乙": 8, "庚": 8,
    "丙": 7, "辛": 7,
    "丁": 6, "壬": 6,
    "戊": 5, "癸": 5,

    # 地支
    "子": 9, "午": 9,
    "丑": 8, "未": 8,
    "寅": 7, "申": 7,
    "卯": 6, "酉": 6,
    "辰": 5, "戌": 5,
    "巳": 4, "亥": 4
}
```

### A.2 后天洛书数映射

```python
LUOSHU_TRIGRAM = {
    1: "坎", 2: "坤", 3: "震", 4: "巽",
    5: "中宫", 6: "乾", 7: "兑", 8: "艮", 0: "中宫"  # 余8视作0
}

LUOSHU_NUMBERS = {
    "坎": 1, "坤": 2, "震": 3, "巽": 4,
    "中宫": 5, "乾": 6, "兑": 7, "艮": 8
}
```

### A.3 三组数序示例

| 卦 | 八卦排列 | 先天八卦 | 后天八卦 |
|---|:---:|:---:|:---:|
| 乾 | 11 | 11 | 16 |
| 坤 | 22 | 22 | 21 |
| 震 | 33 | 34 | 13 |
| 巽 | 44 | 43 | 34 |
| 坎 | 55 | 52 | 25 |
| 离 | 66 | 65 | 62 |
| 艮 | 77 | 78 | 87 |
| 兑 | 88 | 87 | 78 |

### A.4 变爻映射表

**除9变爻**：
```python
MUTATION_9 = {
    1: [1], 2: [2], 3: [3], 4: [4], 5: [5], 6: [6],
    7: [1, 4],  # 翻1与4
    8: [2, 5],  # 翻2与5
    0: [3, 6]   # 翻3与6
}
```

**除6变爻**：
```python
MUTATION_6 = {
    1: [1], 2: [2], 3: [3], 4: [4], 5: [5],
    0: [6]  # 余0视作6
}
```

### A.5 基本数序表（八卦基本配数）

```python
BASIC_SEQUENCE_TABLE = {
    "乾": {"upper": 1, "lower": 1},  # 乾→11，组合11
    "坤": {"upper": 2, "lower": 2},  # 坤→22，组合22
    # ... 完整表见 tieban_algo_seed.json
}
```

---

## B. 验收标准

### B.1 算法正确性

1. ✅ 主链路算法（stem/hex/daymut）与 research tieban.md 一致
2. ✅ 太玄取数与 research tieban 2.md line 103 一致
3. ✅ 八卦滚法48条与 research tieban 2.md line 375-409 **完全一致**
4. ✅ 所有金标准测试通过

### B.2 系统完整性

1. ✅ 输入标准化可回放（TST/EOT/边界）
2. ✅ 六亲靠刻满足锁定门槛（父+母+兄弟）
3. ✅ 命书输出包含完整条文原文
4. ✅ 固定栏目齐全（封面/考刻/六亲/流年）

### B.3 架构一致性

1. ✅ 补充算法不参与 ke 锁定
2. ✅ 补充条文正确标注来源（grid vs generated）
3. ✅ RuleSet 为 SSOT
4. ✅ 数据库 schema 符合规范

### B.4 性能与质量

1. ✅ 端到端响应时间 < 5秒
2. ✅ 单元测试覆盖率 > 90%
3. ✅ 所有 API 接口符合规范
4. ✅ UI 布局符合 v8 约定

---

## 结语

**v8.0（Ultra-Combined）整合版**综合了：

1. **系统架构**（来自 codex_v7）：完整的工程化设计
2. **算法详解**（来自 ultra_v7）：详细的伪代码和实现逻辑
3. **公式修正**：八卦滚法使用有完整算例验证的 ×100+ 公式

**关键成果**：
- 统一的文档体系
- 验证的算法实现
- 清晰的实施路径
- 完整的测试规范

**下一步行动**：
1. 按照 Phase 1-4 实施路线图逐步推进
2. 使用金标准测试确保算法正确性
3. 持续验证与研究文档的一致性

---

**文档版本**: v8.0（Ultra-Combined）
**最后更新**: 2025-12-25
**维护者**: Claude + 用户协作
**状态**: ✅ 整合完成，待实施验证
