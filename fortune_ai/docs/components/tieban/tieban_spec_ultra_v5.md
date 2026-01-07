这是一个基于 **Spec Codex v4**（工程架构与配置驱动）与 **Spec Ultra v3**（算法深度与事实锚点）的最终融合优化版规格说明书。

### 1. 差异分析与最终取舍策略 (Optimization Strategy)

在设计 v5 之前，对 v3 和 v4 进行了深度对比，取舍如下：

| 维度 | v4 Codex (参考版) 设计 | v3 Ultra (前版) 设计 | **v5 最终取舍与优化** |
| --- | --- | --- | --- |
| **系统边界** | 仅 Tieban 12k，排除 Shaozi。 | 仅 Tieban 12k，排除 Shaozi。 | **保持一致**。确认 Tieban 12k 为独立核心，不与 Shaozi 混用。 |
| **算法驱动** | **纯配置驱动 (RuleSet JSON)**。代码仅作解释器，禁止硬编码（如爻权表）。 | **逻辑代码 + 参数配置**。核心公式写在代码里。 | **采纳 v4**。铁板流派极其复杂（如起卦法差异），必须将**公式逻辑**也抽象为配置（或引用物化表），实现“代码无业务”。 |
| **输入处理** | **双重边界并行**（节气+时辰）。 | 仅节气边界。 | **采纳 v4**。高精度算命必须处理“时辰交界”（如 8:59 分）的歧义，生成 `List<Context>` 并行计算，由考刻事实反推真时辰。 |
| **用户模型** | Account-Profile-Run-State 5层模型。 | User-State 扁平模型 + `verified_facts`。 | **融合升级**。采用 v4 的 **5层表结构** 以支持系统级扩展，同时**强制**在 `Profile` 表中引入 v3 的 **`verified_facts` (已验证事实)** 字段，确立铁板作为“全系统事实校验器”的地位。 |
| **知识库** | JSONB + 物化辅助表。 | 纯 JSONB。 | **融合**。核心规则存 JSON，但 **64卦常量表** 和 **秘数表** 建议物化为 DB 表，方便 SQL 关联查询和维护。 |

---

# 铁板神数（Tieban 12k）独立系统规格说明书 (Spec Ultra v5)

**文件名**: `tieban_spec_ultra_v5.md`
**版本**: 5.0 (Final Architecture)
**定位**: `fortune_ai` 生态中的**高精度时空校准与流年推演插件**。
**排他性声明**: 本系统**仅包含**铁板 12k 逻辑，**严禁引入**任何邵子神数（Shaozi/6144）算法。

---

## 1. 系统总体架构 (System Architecture)

系统采用 **Fortune Kernel (公共基座)** 与 **Tieban Plugin (业务插件)** 分离的架构。

### 1.1 逻辑架构图

```mermaid
graph TD
    Client[WeChat / Web / API] --> Gateway[API Gateway]

    subgraph "Fortune AI Kernel (公共基座)"
        Gateway --> AccountMgr[账号与鉴权]
        Gateway --> ProfileMgr[档案管理 (SSOT Time & Facts)]
        Gateway --> HistoryMgr[会话与运行记录]
        ProfileMgr --> TimeEng[天文引擎 (TST/EOT/SolarTerms)]
    end

    subgraph "Tieban Plugin (12k 独立引擎)"
        Gateway -- /api/tieban/* --> TB_Ctrl[Controller]
        
        TB_Ctrl --> InputNorm[Input Normalizer (边界分裂)]
        InputNorm --> RuleEng[Rule Interpreter]
        
        RuleEng -- Load Config --> DB_Rules[(RuleSets JSON)]
        DB_Rules -.-> DB_Hex[(Hex Constants)]
        RuleEng -- Parallel Calc --> Cands[Candidate Pool]
        
        Cands --> CalibFSM[考刻状态机 (FSM)]
        CalibFSM -- Fact Query --> DB_KB[(Tieban 12k DB)]
        
        CalibFSM -- Lock TrueKe --> ReportEng[命书编排]
        ReportEng -- Write Facts --> ProfileMgr
    end

```

---

## 2. Fortune User 数据模型升级 (Kernel Layer)

为了容纳 Tieban 及未来模块（Bazi, Ziwei），用户数据模型升级为 **Account-Profile-State-Run-Conversation** 5 层结构。

### 2.1 账号层：`fortune_user` (Account)

仅存储登录凭证，与具体算命业务解耦。

```sql
CREATE TABLE fortune_user (
    user_id SERIAL PRIMARY KEY,
    openid TEXT UNIQUE,                 -- WeChat OpenID / AuthID
    platform TEXT,                      -- 'wechat', 'web'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

```

### 2.2 档案层：`fortune_profile` (Physical Entity)

**核心表**。存储物理世界的客观事实，是所有算命模块的**单一事实来源 (SSOT)**。

```sql
CREATE TABLE fortune_profile (
    profile_id UUID PRIMARY KEY,
    user_id INT REFERENCES fortune_user(user_id),
    name TEXT NOT NULL,
    gender VARCHAR(10),                 -- 'M', 'F'
    
    -- 原始输入
    birth_time_input TIMESTAMPTZ NOT NULL,
    birth_geo JSONB,                    -- {lat, lon, city_name}
    
    -- SSOT: 系统计算的归一化真太阳时 (所有模块共用)
    true_solar_time TIMESTAMPTZ,        
    
    -- **核心升级**: 跨模块事实锚点 (Verified Facts)
    -- 存储 Tieban 考刻确认的事实，供 Bazi/Ziwei 模块复用
    -- 例: {"parents": {"f_zodiac":"ZI", "m_zodiac":"WU"}, "siblings": {"count":2}}
    verified_facts JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

```

### 2.3 状态层：`fortune_user_module_state` (Interactive Context)

存储“正在进行中”的交互状态，支持断点续算。

```sql
CREATE TABLE fortune_user_module_state (
    profile_id UUID REFERENCES fortune_profile(profile_id),
    module_code TEXT NOT NULL,          -- 'tieban_12k'
    status TEXT,                        -- 'INIT', 'L1_VERIFY', 'LOCKED'
    current_step INT,
    
    -- 上下文容器: 存储 Candidates (多盘), Question History
    context_data JSONB, 
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (profile_id, module_code)
);

```

### 2.4 运行记录层：`fortune_user_module_run` (Immutable History)

存储每次完整计算的快照（用于审计与回溯）。

```sql
CREATE TABLE fortune_user_module_run (
    run_id UUID PRIMARY KEY,
    profile_id UUID REFERENCES fortune_profile(profile_id),
    module_code TEXT,
    ruleset_name TEXT,                  -- 记录当时用的流派版本 (e.g., 'ppx_v1')
    
    input_snapshot JSONB,               -- 当时的输入参数 (含 TST/Boundary 判定结果)
    output_report JSONB,                -- 最终生成的结构化命书 (Timeline)
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

```

### 2.5 对话层：`fortune_user_conversation` (Chat Log)

```sql
CREATE TABLE fortune_user_conversation (
    message_id UUID PRIMARY KEY,
    run_id UUID REFERENCES fortune_user_module_run(run_id), -- 关联某次运行
    role VARCHAR(20),                   -- 'user', 'assistant'
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

```

---

## 3. Tieban 知识库设计 (Knowledge Base)

### 3.1 核心条文表：`tieban_verses`

```sql
CREATE TABLE tieban_verses (
    verse_id INT PRIMARY KEY,           -- 1 - 13000
    content_raw TEXT NOT NULL,          -- "父鼠母马，先天定数"
    
    -- 核心分类
    category VARCHAR(20),               -- 'PARENTS', 'SIBLINGS', 'FORTUNE'
    
    -- 结构化标签 (算法反向搜索的核心)
    -- 例: {"f_zodiac": "ZI", "m_zodiac": "WU"}
    fact_meta JSONB, 
    
    -- 算术索引 (优化 +96 推演性能)
    mod_96 INT GENERATED ALWAYS AS (verse_id % 96) STORED
);
CREATE INDEX idx_tb_meta ON tieban_verses USING GIN (fact_meta);

```

### 3.2 规则集表：`tieban_rulesets`

Tieban 的核心不是代码，而是配置。

```sql
CREATE TABLE tieban_rulesets (
    ruleset_id VARCHAR(50) PRIMARY KEY, -- 'ppx_v1', 'tuenhai_v1'
    config JSONB NOT NULL,              -- 包含 StemMap, HexFormula, SecretKeys
    description TEXT
);

```

### 3.3 辅助物化表

用于存储大规模常量，避免 JSON 过大。

```sql
-- 卦气常量表 (用于 Engine-Hexagram 查表)
CREATE TABLE tieban_hex_constants (
    ruleset_id VARCHAR(50),
    hex_code VARCHAR(20),               -- 'KAN-ZHEN' (上坎下震)
    sum_yao INT,                        -- 390
    PRIMARY KEY (ruleset_id, hex_code)
);

```

---

## 4. 详细算法与 Step-by-Step 算例

本系统通过 `RuleSet` 驱动 **Engine-Stem** 和 **Engine-Hexagram** 并行计算。

### 4.1 预处理：边界分裂 (Input Normalization)

Tieban 必须处理时间的模糊性，生成 **四柱上下文列表 (`List<PillarsContext>`)**。

1. **TST 计算**:
$$ T_{TST} = T_{Clock} + (Lon - 120^\circ) \times 4\text{min} + EOT(Day) $$
2. **边界探测**:
* **节气边界**: 若  在节气交脱点  分钟内  生成 `[上月四柱, 本月四柱]`。
* **时辰边界**: 若  在时辰交界点（如 09:00） 分钟内  生成 `[本时四柱, 下时四柱]`。


3. **组合输出**:
* 正常情况: `[Pillars_A]`
* 双重边界: `[Pillars_A, Pillars_B, Pillars_C, Pillars_D]` (最多4组上下文)



### 4.2 引擎 A：四柱天干配数 (Engine-Stem)

**逻辑**: 基于 `RuleSet` 定义的映射表和权重，计算基数。

* **配置**:
* `stem_map`: `{甲:1, 乙:6, 丙:2, ...}`
* `order`: `['month', 'day', 'hour', 'year']` (**注意权重顺序**)
* `weights`: `[1000, 100, 10, 1]`


* **算例 (王小明: 甲子/丙寅/壬申/丙午)**:
1. Month (丙) 
2. Day (壬) 
3. Hour (丙) 
4. Year (甲) 
5. **Base_A = 2521**


* **合化修正**: 若月日干合化（如甲己合土），RuleSet 定义是否生成 `Base_A_Alt`（用五行数替换）。

### 4.3 引擎 B：八卦加则 (Engine-Hex)

**逻辑**: 将四柱转化为卦象，查表计算基数。

* **配置**:
* `trigram_source`: `'month'` (取月柱起卦)
* `trigram_map`: `{天干:卦, 地支:卦}`
* `hex_formula`: `Head(Upper)*1000 + SumYao(Hex) - Tail(Lower)`


* **算例 (上艮下震, 卦气390)**:
1. Head(艮) = 8
2. SumYao(山雷颐) = 390 (查 `tieban_hex_constants`)
3. Tail(震) = 3
4. **Base_B** = 



### 4.4 考刻状态机 (Calibration FSM)

1. **候选生成**: 将所有 Context 和 Engine 的结果聚合为 `Candidate Pool`。
2. **L1_VERIFY (父母生肖)**:
* 聚合 Pool 中所有 Base 的 `l1_verse_id`。
* **Action**: 提问用户 "您的父母生肖是..."
* **Feedback**: 用户选择 "父鼠母马"。系统剔除不匹配的 Context。


3. **L1.5 秘数救援**:
* *触发*: 若用户选 "以上都不是"。
* *动作*: 对剩余 Candidate 应用 `RuleSet.secret_keys` (如 `+1327`)。
* *生成*: 新的候选条文 (通常是兄弟/排行类)。
* *展示*: "修正推算：您是否有兄弟二人，且是老大？"


4. **LOCKED (锁定)**:
* 当 Candidate 唯一，或用户确认某条文。
* **关键动作**:
1. 锁定 `True_Base` 和 `True_Ke`。
2. **回写 Profile**: 将确认的事实写入 `fortune_profile.verified_facts`。





---

## 5. API 接口定义

遵循 RESTful 风格，路径前缀 `/api/tieban`。

| Method | Endpoint | Payload | Response | 描述 |
| --- | --- | --- | --- | --- |
| **POST** | `/init` | `{profile_id, ruleset?}` | `{run_id, status, question, options}` | 初始化计算，返回第一轮问题 |
| **POST** | `/verify` | `{run_id, option_id}` | `{status, question?, options?}` | 提交答案，返回下一轮或锁定状态 |
| **GET** | `/report` | `?run_id=...` | `{timeline: [...], base_info}` | 获取最终结构化命书 |

---

## 6. ETL 与实施计划

1. **数据清洗**:
* 源: 12,000 条文文本。
* 目标: `tieban_verses` 表。
* **关键**: 编写正则提取 `fact_meta`。需覆盖：父母生肖、父母存亡、兄弟数量、兄弟排行。


2. **规则配置**:
* 将 `research tieban.md` 中的表格（天干数、卦气数、秘数）转录为 `ppx_v1.json`。
* **禁止硬编码**: 代码中不得出现 `if stem == '甲': return 1`，必须查 RuleSet。


3. **系统集成**:
* 升级 `fortune_profile` 表结构，增加 `verified_facts`。
* 对接 `TimeEngine` 获取 TST。