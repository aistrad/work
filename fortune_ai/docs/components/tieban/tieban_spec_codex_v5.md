# 铁板神算（Tieban 12k）系统规格说明书（Spec Codex v5）

**版本**：v5.0  
**范围**：仅 Tieban 12k（完整基于 12,000 条文的独立铁板逻辑）  
**明确排除**：任何 Shaozi/邵子算法、洛阳派 6144 条文与其坐标索引体系  
**优先级**：算法完整性与可复现性 > 工程便利性 > UI  
**基线融合**：`fortune_ai/docs/tieban/tieban_spec_ultra_v5.md`（公式化与事实锚点） + `fortune_ai/docs/tieban/tieban_spec_codex_v4.md`（RuleSet SSOT 与完整数据模型）  

---

## 0. 与 `tieban_spec_ultra_v5.md` 的主要差异（本文件 v5 的取舍）

本文件在吸收 `tieban_spec_ultra_v5.md` 的长处时，做了以下关键修正与增强：

1) **文档源一致性修正**：统一以仓库存在的 `fortune_ai/docs/research tieban.md`（而非缺失的 `research tieban2.md`）作为“胖胖熊体系”主来源；所有示例与表格必须能在仓库文件中追溯。
2) **避免“过度具体且不可证伪”的示例**：`tieban_spec_ultra_v5.md` 在 L1.5 中把 `3848` 当作“真基数”是示意性的，但容易被误解为硬编码；v5 改为“示例路径/占位符”，并要求所有候选 ID 必须来自 `VerseIdMapping + 12k KB` 的可回放计算。
3) **补齐缺失计算**：`tieban_spec_ultra_v5.md` 的 Engine‑Hex 算例中 `Base_B` 留空；v5 明确给出 `Base_B = 8000 + 390 - 3 = 8387`（在 `SumYao=390` 的前提下）。
4) **RuleSet 仍为 SSOT（不变）**：保留 v4 codex 约束——任何卦常量、秘数、跳码、遇十不用、钥匙映射必须来自 RuleSet（或其导出的物化表），不得在代码中靠经验补全。
5) **“事实锚点”入档（吸收 ultra v5 的强项）**：在 `fortune_profile` 引入 `verified_facts`（已验证事实），并明确其写入时机与结构，用于跨模块复用（Bazi/Ziwei/未来模块）。

---

## 1. 系统定义（Tieban 的工程化真相）

Tieban 12k 系统是一个“**时空坐标校准器 + 条文索引检索器**”：

1) 输入：出生时间/地点/性别 + 可确认的事实（父母生肖、兄弟数、先丧、配偶信息等）。  
2) 标准化：真太阳时（TST）+ 节气边界 + 时辰交界边界 → 产生多套四柱上下文（并行）。  
3) 候选生成：在每个上下文与每个 RuleSet 下，用多引擎并行生成 `Candidate Pool`（包含 ke/base/verse_ids 与分解）。  
4) 考刻闭环：基于 12k 条文的 `fact_meta` 生成问题 → 用户回答 → 剪枝收敛 → 锁定 `TrueKe + LockedBase (+ Key)`。  
5) 出书：从 12k 条文库按锁定结果检索与编排输出结构化命书。  

---

## 2. 总体架构（Fortune Kernel + Tieban Plugin）

### 2.1 Kernel / Plugin 分层

- Fortune Kernel：账号、档案（SSOT time + facts）、运行记录、对话历史、时间引擎（TST/EOT/节气）。  
- Tieban Plugin：输入标准化分裂、RuleSet 解释执行、候选池、考刻 FSM、KB 检索、命书编排。  

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
    FSM --> Report[report_builder]
    Report --> Runs
    FSM --> Profile
  end
```

---

## 3. 输入标准化（TST + 双重边界分裂）

### 3.1 输入契约（建议）

```json
{
  "profile_id": "uuid",
  "birth_local": "1988-08-08 08:30:00",
  "tz_offset_hours": 8,
  "location": {"name":"北京","longitude":116.4074,"latitude":39.9042},
  "gender": "M",
  "known_facts": {"parents_zodiac":{"father":"子","mother":"午"}},
  "ruleset_names": ["ppx_v1"],
  "debug": true
}
```

### 3.2 真太阳时（TST）口径（可复现）

1) 经度修正（地方平太阳时 LMT）：
```
L_meridian = 15 * tz_offset_hours
delta_minutes = (longitude - L_meridian) * 4
T_lmt = T_local + delta_minutes
```

2) 均时差（EOT）近似：
```
theta = 2π(doy - 81) / 365
EOT ≈ 9.87*sin(2*theta) - 7.53*cos(theta) - 1.5*sin(theta)
T_tst = T_lmt + EOT
```

### 3.3 双重边界分裂（必须）

RuleSet 必须定义两个窗口：
- `boundary_window_minutes`：节气交接边界（影响月柱）
- `shichen_fuzzy_minutes`：时辰交界边界（影响时柱/刻）

输出：`pillars_contexts[]`（最多 4 份上下文）：
- 正常：1 份
- 仅节气边界：2 份
- 仅时辰边界：2 份
- 双重边界：4 份

标准化输出必须可回放并写入 run/state：
```json
{
  "tst_time": "1988-08-08T08:17:31+08:00",
  "boundary_flags": ["SOLAR_TERM_EDGE", "SHICHEN_EDGE"],
  "pillars_contexts": [
    {"id":"A","pillars":{"year":"甲子","month":"丙寅","day":"壬申","hour":"丙午"}},
    {"id":"B","pillars":{"year":"甲子","month":"丁卯","day":"壬申","hour":"丙午"}}
  ]
}
```

---

## 4. RuleSet（算法完整性的 SSOT）

### 4.1 RuleSet 必备字段（v5 最终口径）

v5 沿用 v4 codex，并增加 `verified_facts_schema`（事实锚点结构约束）：

- `name`
- `time.boundary_window_minutes`
- `time.shichen_fuzzy_minutes`
- `stem_number_map`
- `stem_digit_order`
- `hehua_rules`（表格化，禁止空口）
- `wuxing_number_map`
- `trigram_map.stem_to_trigram`
- `trigram_map.branch_to_trigram`
- `trigram_map.trigram_number`
- `hex_constants`（inline 或 table_ref）
- `avoid_ten_rule`
- `ke.ke_ranges`
- `ke.ke_selection_rule`（stem_sum_mod_8 等）
- `verse_id_mapping`（range + holes + key_mapping + secret_keys）
- `verified_facts_schema`（定义允许写入 profile 的事实结构）

### 4.2 规则存储与物化（取长补短）

SSOT：`tieban_rulesets.rules`（JSONB 全量配置）。  
可选物化：
- `tieban_hex_constants`：`SumYao` 查表加速与维护
- `tieban_secret_keys`：秘数集合与用途维护

物化表由 RuleSet 导出生成；运行时以 RuleSet 为裁决源。

---

## 5. 算法（Engine‑Stem + Engine‑Hex + Ke/96 + Mapping）

### 5.1 Engine‑Stem：四柱天干配数法（明确公式 + 算例）

映射（示例口径）：
```
甲1 乙6 丙2 丁7 戊3 己8 庚4 辛9 壬5 癸0
```

公式（顺序由 RuleSet 的 `stem_digit_order` 决定，常见为月→日→时→年）：
```
Base_A = Map(month_stem)*1000 + Map(day_stem)*100 + Map(hour_stem)*10 + Map(year_stem)
```

Step-by-step 算例（王小明示例）：`甲子年 丙寅月 壬申日 丙午时`
1) 月干 `丙→2`
2) 日干 `壬→5`
3) 时干 `丙→2`
4) 年干 `甲→1`
5) `Base_A = 2*1000 + 5*100 + 2*10 + 1 = 2521`

`+96` 递推主轴：
```
Seq(n) = Base_A + 96*n
```

合化修正（HeHua）：
- 是否化、何柱对生效、替换为五行数、间隔不化条件，必须全由 `hehua_rules` 表驱动；
- 输出 `Base_A_alt[]` 与 `Base_A` 并行进入候选池。

### 5.2 Engine‑Hex：八卦加则（明确公式 + 算例）

化卦（示例口径，必须来自 RuleSet）：
- 上卦：天干→卦（`stem_to_trigram`）
- 下卦：地支→卦（`branch_to_trigram`）

公式：
```
Base_B = Head(upper)*1000 + SumYao(hex) - Tail(lower)
```

其中：
- `Head/Tail` 取自 `trigram_number`
- `SumYao(hex)` 取自 `hex_constants`（inline 或 `tieban_hex_constants` 查表）

算例（上艮下震，`SumYao=390`）：
1) `Head(艮)=8`
2) `Tail(震)=3`
3) `Base_B = 8*1000 + 390 - 3 = 8387`

> v5 仍不把“变知六八止/世应/变卦/遇十不用”的细则硬编码；必须由 RuleSet 二次规则层提供显式参数/表格。

### 5.3 Ke 与 96 刻（考刻骨架）

“最可能刻”口径（资料口径）：
1) 取四柱天干数和 `S_stem`
2) `r = S_stem % 8`
3) `ke = (r == 0 ? 8 : r)`

8 刻候选生成：
对每个 `pillars_context`、每个 `ruleset`：
```
for ke in 1..8:
  bases = EngineStem(...) + EngineHex(...) + ...
  verse_ids = VerseIdMapping(bases, ke, ruleset)
  emit candidate
```

### 5.4 VerseIdMapping（中间数→12k 条文 ID）

v5 规定映射必须至少可配置三层：
1) `range_normalize`（归一到有效区间，处理 holes）
2) `key_mapping`（钥匙/密码层，若存在）
3) `secret_jump_search`（秘数跳跃搜索：用于考刻失败时扩大搜索空间）

禁止：把某个“秘数 + 某个 offset + 某个真基数”的结果写死在算法里。

---

## 6. 考刻 FSM（从 KB 生成问题，收敛候选）

### 6.1 状态机

`INIT`
→ `NORMALIZED`
→ `CANDIDATES_READY`
→ `L1_VERIFY`
→ `L1_SECRET_SEARCH`（可选）
→ `L2_VERIFY`
→ `LOCKED`
→ `REPORT_READY`

### 6.2 L1/L2 的“问题来源”与选择策略

问题必须来自 `tieban_verses.fact_meta` 的可结构化事实（示例）：
- `parents_zodiac`（父母生肖）
- `siblings_count/rank`
- `parent_death_order`
- `spouse_*`（如果条文可抽取）

选择策略（工程定义）：
1) 对每个候选的 `verse_ids` 拉取 `fact_meta`
2) 聚合成“问题空间”
3) 选择区分度最大的问题先问（信息增益最大）

### 6.3 LOCKED 产物（必须写入 run/state）

锁定必须产出：
- `true_ke`
- `locked_base`（以及 base 来源：stem/hex/合化/钥匙链路）
- `ruleset_name`
- `evidence`（用于回放：问题与答案、候选剪枝轨迹）

---

## 7. 知识库（12k）与规则库（SQL）

### 7.1 `tieban_verses`

```sql
CREATE TABLE IF NOT EXISTS tieban_verses (
  verse_id     INT PRIMARY KEY,    -- 1..12000（或 RuleSet 定义的有效区间）
  content_raw  TEXT NOT NULL,
  category     TEXT,
  fact_meta    JSONB,
  mod_96       INT GENERATED ALWAYS AS (verse_id % 96) STORED
);
CREATE INDEX IF NOT EXISTS idx_tb_fact_meta ON tieban_verses USING GIN (fact_meta);
CREATE INDEX IF NOT EXISTS idx_tb_mod96 ON tieban_verses(mod_96);
```

### 7.2 `tieban_rulesets`（SSOT）

```sql
CREATE TABLE IF NOT EXISTS tieban_rulesets (
  ruleset_name TEXT PRIMARY KEY,  -- "ppx_v1"
  rules        JSONB NOT NULL,
  description  TEXT
);
```

### 7.3 物化表（可选）

```sql
CREATE TABLE IF NOT EXISTS tieban_hex_constants (
  ruleset_name TEXT NOT NULL,
  hex_code     TEXT NOT NULL,     -- "GEN-ZHEN"
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

---

## 8. Fortune 数据模型（v5 最终版：Account-Profile-State-Run-Conversation）

v5 在 v4 codex 模型上吸收 ultra v5 的“verified_facts 写入 Profile”的优势。

### 8.1 `fortune_user`（账号）

```sql
CREATE TABLE IF NOT EXISTS fortune_user (
  user_id     SERIAL PRIMARY KEY,
  openid      TEXT UNIQUE,
  platform    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 8.2 `fortune_profile`（档案：SSOT time + verified facts）

```sql
CREATE TABLE IF NOT EXISTS fortune_profile (
  profile_id        UUID PRIMARY KEY,
  user_id           INT NOT NULL REFERENCES fortune_user(user_id),
  name              TEXT NOT NULL,
  gender            TEXT,
  birth_time_input  TIMESTAMPTZ NOT NULL,
  tz_offset_hours   FLOAT8,
  location          JSONB,
  true_solar_time   TIMESTAMPTZ,
  bazi_pillars      JSONB,
  verified_facts    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

`verified_facts` 写入约束：
- 仅写入 RuleSet 定义的 `verified_facts_schema` 中允许的字段；
- 写入发生在 Tieban `LOCKED` 时（由 `calibration_fsm` 触发）。

### 8.3 `fortune_user_module_state`（交互状态）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_state (
  profile_id   UUID NOT NULL REFERENCES fortune_profile(profile_id),
  module_code  TEXT NOT NULL,      -- "tieban_12k"
  status       TEXT NOT NULL,
  current_step INT,
  context_data JSONB NOT NULL,     -- candidates/questions/answers/partial locks
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (profile_id, module_code)
);
```

### 8.4 `fortune_user_module_run`（不可变快照）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_module_run (
  run_id          UUID PRIMARY KEY,
  profile_id      UUID NOT NULL REFERENCES fortune_profile(profile_id),
  module_code     TEXT NOT NULL,
  ruleset_name    TEXT,
  input_snapshot  JSONB NOT NULL,
  output_report   JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 8.5 `fortune_user_conversation`（历史对话）

```sql
CREATE TABLE IF NOT EXISTS fortune_user_conversation (
  message_id  UUID PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES fortune_user(user_id),
  profile_id  UUID REFERENCES fortune_profile(profile_id),
  run_id      UUID REFERENCES fortune_user_module_run(run_id),
  role        TEXT NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 9. API（建议）

| Method | Endpoint | 描述 |
| --- | --- | --- |
| `POST` | `/api/tieban/init` | 标准化+候选生成，返回第一轮问题 |
| `POST` | `/api/tieban/verify` | 提交事实答案，返回下一轮/或锁定 |
| `POST` | `/api/tieban/lock` | 显式锁定（可选；通常 verify 收敛后自动锁定） |
| `GET` | `/api/tieban/report?run_id=...` | 获取结构化命书 |

---

## 10. 验收标准（以可复现为准）

- 能复现 `Base_A=2521` 与 `+96` 序列生成。
- 在提供 `hex_constants(sum_yao)` 的前提下，能复现 `Base_B=8387` 的算例。
- 12k 条文库入库后：`fact_meta` 至少覆盖父母生肖（L1 必需），使考刻 FSM 可运行并能锁定输出。

