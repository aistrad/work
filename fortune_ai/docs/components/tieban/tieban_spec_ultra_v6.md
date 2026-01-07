这是一个基于 **Spec Codex v4** (架构规范)、**Spec Ultra v5** (事实锚点) 以及 **Research Tieban 2 (胖胖熊实战体系)** 的最终融合优化版规格书。

**本版本 (v6) 的核心突破**在于将“胖胖熊”资料中零散的“口诀”和“密数”彻底工程化，特别是：

1. **四柱取数的特殊顺序**：确认为 **月→日→时→年** (复现基数 2521)。
2. **八卦加则密数表**：引入“一卦多数”的查表机制 (复现 8387/4245)。
3. **内棚/外棚线性偏移**：复原了基于 `+7n` 或 `+21` 的推导逻辑 (解决考刻不准时的救援)。
4. **日主变卦扩展**：固化了日主 `±96×4` 的暴富/配偶流年算法。

---

# 铁板神算（Tieban 12k）系统规格说明书 (Spec Ultra v6)

**文件名**: `tieban_spec_ultra_v6.md`
**版本**: 6.0 (The Definitive PPX Implementation)
**范围**: 仅 Tieban 12k（胖胖熊实战体系），**严禁**引入邵子（Shaozi/6144）逻辑。
**基线文档**: `fortune_ai/docs/tieban_spec_codex_v4.md` + `research tieban.md`

---

## 0. 核心算法差异与最终决策 (Optimization Decisions)

基于 `research tieban.md` 的深度研读，v6 对前序版本做出了以下修正：

| 维度 | v4/v5 假设 | **v6 最终决策 (基于胖胖熊实战)** | **工程意义** |
| --- | --- | --- | --- |
| **四柱顺序** | 泛指 (通常年月日時) | **强制锁定：月 -> 日 -> 时 -> 年** | 只有此顺序才能复现算例 `2521`。 |
| **八卦算法** | 纯公式计算 | **密数表 (Lookup) + 公式 (Formula)** | 附件给出了《八卦加则不传密数表》，一个卦象对应两个基数 (如艮震->8387, 4245)，纯公式无法产出第二个数。 |
| **内棚/外棚** | 未涉及 | **线性偏移 (Linear Offset)** | 附件揭示外棚条文是基于内棚条文 `+ (7 × n)` 生成的。这是解决“考刻不准”的关键救援路径。 |
| **日主变卦** | 泛指 Engine-Hex | **独立引擎 (Engine-DayMut)** | 日主化卦有独立的扩展逻辑 (`±96 × 4`)，专用于断配偶与暴富流年。 |
| **考刻逻辑** | 统一计算考父 | **分柱直断 (Pillar-Specific)** | 年柱考父、月柱考兄、日柱考妻、时柱考子。 |

---

## 1. 系统定义 (System Definition)

Tieban 12k v6 是一个**基于“多维算术推演”与“事实扣入”的时空坐标校准系统**。

* **多维推演**: 同时运行“四柱天干”、“八卦加则”、“日主变卦”等多套算法，生成候选基数池。
* **事实扣入 (Kou Ru)**: 通过 FSM (状态机) 将候选基数对应的断语与用户事实 (六亲生肖) 进行碰撞。
* **线性救援**: 当主算法失效时，启动“内棚偏移”与“16组秘数”进行全域搜索。

---

## 2. 总体架构 (Kernel + Plugin)

```mermaid
graph TD
    Client[WeChat / API] --> Gateway[API Gateway]

    subgraph "Fortune Kernel (公共基座)"
        Gateway --> ProfileMgr[Profile Manager (SSOT)]
        ProfileMgr --> DB_Profile[(fortune_profile)]
        ProfileMgr --> TimeEng[Time Engine (TST & Boundary)]
        
        Note over DB_Profile: 存储 True Solar Time 和 Verified Facts
    end

    subgraph "Tieban Plugin (PPX Engine)"
        Gateway -- /api/tieban --> Ctrl[Controller]
        
        Ctrl --> Norm[Input Normalizer]
        Norm -- 1. 拓扑四柱 & 边界分裂 --> Contexts[Pillars Contexts]
        
        Ctrl --> RuleEng[Rule Interpreter]
        RuleEng -- 2. Load Config --> RS[(RuleSet: PPX_v1)]
        RS -.-> HexTable[(Hex Secret Table)]
        
        subgraph "Quad-Engine Core"
            RuleEng --> Eng_Stem[A: Stem Math (流年)]
            RuleEng --> Eng_Hex[B: Hex Lookup (大运)]
            RuleEng --> Eng_Pillar[C: Pillar Calibration (六亲)]
            RuleEng --> Eng_Day[D: Day Mutation (变卦)]
        end
        
        Eng_Stem & Eng_Hex & Eng_Pillar & Eng_Day --> Pool[Candidate Pool]
        
        Pool --> FSM[Calibration FSM]
        FSM -- 3. Query & Offset --> KB[(Tieban 12k DB)]
        FSM -- 4. Verify & Lock --> ProfileMgr
        
        FSM -- 5. Report --> ReportBuilder
    end

```

---

## 3. 详细算法与算例 (Algorithms)

所有算法参数（映射表、权重、常量）必须由 `RuleSet` 定义，代码只负责执行逻辑。

### 3.1 预处理：拓扑四柱与边界 (Input Normalization)

* **TST**: 。
* **边界分裂**: 节气交脱 分，时辰交界 分。生成 `List<PillarsContext>`。
* **拓扑感知**: 四柱数据结构需记录相对位置，以支持“有字间之不化”的逻辑。

### 3.2 Engine A：胖胖熊四柱天干法 (Stem Method)

**最高依据**: `research tieban.md` - "四柱天干取数诀"

1. **映射**: `{甲1, 乙6, 丙2, 丁7, 戊3, 己8, 庚4, 辛9, 壬5, 癸0}`
2. **权重顺序 (核心)**: **月(1000) -> 日(100) -> 时(10) -> 年(1)**
3. **合化 (HeHua)**:
* 检查 `hehua_rules` (如乙庚合化金)。
* **拓扑干扰**: 检查四柱中是否有干扰字 (如乙庚合，见甲不化)。
* *Action*: 若合化成功，生成 `Base_Alt` (替换为五行数)。


4. **算例 (复现)**:
* 八字: 甲子年 丙寅月 壬申日 丙午时
* 取数: 丙(2) 壬(5) 丙(2) 甲(1) -> **2521**
* 推演: `2521 (+96) -> 2617 -> 2713...`



### 3.3 Engine B：八卦加则法 (Hexagram Method)

**最高依据**: `research tieban.md` - "八卦加则大公开" & "密数表"

1. **起卦**: 按 RuleSet (通常取月柱或年柱)。
2. **密数查表 (优先)**:
* 查询 `tieban_hex_secret_table`。
* 例: `Upper=艮, Lower=震` -> 查表得 **[8387, 4245]**。


3. **公式兜底**:
* 
* `SumYao` (爻从三十起): 查 `tieban_hex_constants` 表 (如 390)。
* 例: 。



### 3.4 Engine C：四柱直断考六亲 (Pillar Calibration)

**最高依据**: `research tieban.md` - "四柱化卦十二地断考六亲"

1. **策略**: 依据 `pillar_calibration_map` (年考父, 月考兄, 日考妻, 时考子)。
2. **逻辑**: 针对单柱 (如年柱) 起卦，结合当前刻分 (Ke 1-8) 动爻，直接断出生肖。
3. **用途**: 作为 L0 级过滤器，快速剔除错误的边界上下文。

### 3.5 Engine D：日主变卦法 (Day Mutation)

**最高依据**: `research tieban.md` - "日主变卦取数诀"

1. **对象**: 仅针对 **日柱** 起卦得出的基数 (如 6382)。
2. **扩展**: 前后加减 96 各四次。
* 
* 算例:  (妻命属木);  (乙酉骤富)。



---

## 4. 知识库设计 (Data Schema)

### 4.1 核心数据库

```sql
-- 条文表 (支持内棚标记)
CREATE TABLE tieban_verses_12k (
    verse_id INT PRIMARY KEY,
    content_raw TEXT,
    fact_meta JSONB,            -- {"f":"ZI", "m":"WU"}
    is_internal_shelf BOOLEAN,  -- 是否为内棚条文
    mod_96 INT GENERATED ALWAYS AS (verse_id % 96) STORED
);

-- 八卦加则密数表 (PPX 特有，支持一卦多数)
CREATE TABLE tieban_hex_secret_table (
    ruleset_name TEXT,
    upper_trigram TEXT,         -- '艮'
    lower_trigram TEXT,         -- '震'
    base_values INT[],          -- [8387, 4245]
    PRIMARY KEY (ruleset_name, upper_trigram, lower_trigram)
);

-- 规则集 (JSON 配置)
CREATE TABLE tieban_rulesets (
    ruleset_name TEXT PRIMARY KEY, 
    config JSONB 
);

```

### 4.2 RuleSet JSON 示例 (PPX_v1)

```json
{
  "name": "ppx_v1",
  "stem_digit_order": ["month", "day", "hour", "year"],
  "pillar_calibration_map": {"year": "father", "month": "siblings", "day": "spouse", "hour": "children"},
  "hehua_topology": {
    "乙+庚": {"blocker": "甲", "support": ["巳","酉","丑","申"]}
  },
  "day_mutation_depth": 4,
  "linear_offsets": [{"base_mod": 3, "step": 7}], 
  "secret_keys": [1327, 1543, 5017, 133, 97, 23, 41, 571, 1147, 2237]
}

```

---

## 5. 考刻 FSM 与 扣入逻辑 (Calibration & Deduction)

### 5.1 FSM 流程

1. **INIT**: 运行所有 Engine，生成 `Pool`。
2. **L1_YEAR (考父)**:
* 调用 **Engine C (Year Pillar)**。
* 提问: "父亲生肖是？" -> 锁定初步 `Ke`。


3. **L1.5_OFFSET (内棚扣入)**:
* 若 L1 命中 `9003(父鼠)` 但用户反馈是“父母同鼠”。
* **Action**: 应用线性偏移 `Base + (7 × 3) = 9024` (原文逻辑)。
* **Result**: 自动修正为 `9024`，无需用户再次输入。


4. **L2_DAY (考妻)**:
* 调用 **Engine D (Day Mut)**。
* 提问: "配偶生肖/姓氏？" (如 6478 妻命属木)。


5. **LOCK**: 锁定 `True_Base`，写入 Profile。

---

## 6. Fortune Profile 升级 (Verified Facts)

Tieban 作为全系统的 **"Fact Validator"**。

```sql
CREATE TABLE fortune_profile (
    profile_id UUID PRIMARY KEY,
    -- ... (Standard Fields)
    true_solar_time TIMESTAMPTZ,
    
    -- SSOT Facts: 由 Tieban 考刻锁定
    verified_facts JSONB DEFAULT '{}'::jsonb
    -- {
    --   "parents": {"f":"ZI", "m":"WU"},
    --   "siblings": {"count": 2},
    --   "tieban_lock": {"ke": 3, "base": 2521}
    -- }
);

```

---

## 7. 验收标准

1. **算法复现**:
* Engine-Stem: 必须得出 **2521** (王小明)。
* Engine-Hex: 必须通过查表得出 **[8387, 4245]**。
* Engine-Day: 必须得出 **6670** (6382 + 96×3)。


2. **扣入逻辑**:
* 能演示 `9003 (父鼠)` -> `9024 (父母鼠)` 的自动推导。


3. **事实回写**:
* 考刻结束后，`fortune_profile.verified_facts` 必须被正确更新。