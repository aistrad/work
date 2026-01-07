# Tieban 模块使用说明（v8 对齐）

本文档面向工程与产品使用，解释 Tieban 模块的 **输入/输出、核心流程、算法机制与可配置项**，并给出 API 用法与常见排错建议。本文与 `docs/tieban/tieban_spec_ultra_ultra_v8.md` 对齐。

---

## 1. 模块定位与输出形态

Tieban 12k 的工程化流程为：

```
输入 → 标准化 → 起数 → 候选池 → 靠刻 → 锁定 → 命书输出
```

- **输入**：出生信息 + 事实（父母生肖、兄弟数等）
- **输出（SSOT）**：结构化 JSON（命书四栏目 + 证据 + 追溯元数据）
- **前端渲染**：从 JSON 显示条文原文与年龄区间

---

## 2. 使用入口

### 2.1 API

**`POST /api/tieban/init`**  
一次性生成候选列表（不锁定）。

**`POST /api/tieban/verify`**  
追加或更新事实，重新筛选候选。

**`POST /api/tieban/select`**  
用户选择某候选进行锁定与出书。

**`GET /api/tieban/report?run_id=...`**  
获取结构化命书 JSON。

**`POST /api/tieban/solve`**  
一键流程：初始化后如果候选唯一则自动锁定并返回报告地址。

---

## 3. 输入与标准化

### 3.1 日期解释
若输入为 `MM/DD/YYYY`，会统一解释为 `YYYY-MM-DD`（如 `02/11/1980 → 1980-02-11`）。

### 3.2 真太阳时（TST）
使用经度校正 + EOT（Equation of Time）计算真太阳时，并以此排四柱。

### 3.3 边界上下文
若出生时间接近节气或时辰边界，会生成多组 `pillars_contexts[]`，用于后续候选合并与比较。

输出字段示例：
```json
{
  "tst_time": "1980-02-11T14:04:03",
  "boundary_flags": ["SOLAR_TERM_EDGE"],
  "pillars_contexts": [
    {"id": "A", "ke_hint": 5, "pillars": {"year":"庚申","month":"戊寅","day":"甲寅","hour":"辛未"}},
    {"id": "B", "ke_hint": 5, "pillars": {"year":"庚申","month":"戊寅","day":"甲寅","hour":"辛未"}}
  ]
}
```

---

## 4. 核心算法机制

### 4.1 Engine‑Stem（四柱天干取数）
- 映射：`甲1 乙6 丙2 丁7 戊3 己8 庚4 辛9 壬5 癸0`
- 顺序：**月 → 日 → 时 → 年**
- 输出：四位数 base

示例：`甲子年 丙寅月 壬申日 丙午时 → 2521`

---

### 4.2 Engine‑Hex（八卦加则密数表）
- 以天干/地支配卦为上/下卦
- 查密数表获得 2 个 base（primary + secondary）
  - 若密数表缺失，可走公式（由 hex_constants）

输出（每柱最多 2 个 base）：
```
year: [primary, secondary]
month: [primary, secondary]
day: [primary, secondary]
hour: [primary, secondary]
```

---

### 4.3 Engine‑DayMut（日主变卦）
- 取日柱 **primary** base
- 计算 `base ± 96 × k`，`k ∈ [-4..4]`
- **默认包含 k=0（本值）**
- secondary 仅在救援阶段启用

---

### 4.4 VerseIdMapping（条文序列）
从 `base_ke = base + (ke - 1)` 生成等差序列：

```
range_min=1001, range_max=13000, step=96
```

应用规则：
- `avoid_ten_rule`: 末位 0 过滤
- `holes`: 显式跳过条文号
- `mode`: `linear` 或 `wrap`
  - `linear`：从 base_norm 递增到 range_max
  - `wrap`：环形回绕至全周期

---

### 4.5 多事实靠刻语义
对某事实 `fact`，若候选序列与 `match_verse_ids(fact)` 有交集，则命中。

```
intersection(candidate.sequence, match_verse_ids(fact)) ≠ ∅
```

**关键点**：不同事实允许命中不同条文，不要求同条文交集。

---

## 5. 候选池、筛选与救援

### 5.1 候选池
对每个上下文：
1) Engine‑Stem/Hex/DayMut 生成 bases  
2) 对每个 base 枚举 ke=1..8  
3) 生成 verse_id_sequence

### 5.2 全事实命中筛选
若提交了 N 个事实，候选需对 **所有事实** 均有命中才保留。

### 5.3 救援链路
当候选为 0 时，依次尝试：
1) `linear_offsets`  
2) `day_mutation.include_secondary=true`  
3) `secret_jump_search`  
若仍为 0 → 返回 conflict。

### 5.4 候选“已发生条文”预览（选盘辅助）
为帮助用户在“未锁定”阶段对照过往经历，候选返回字段包含：
- `occurred_preview`: 从该候选 **Grid 条文序列**中抽取“已发生/正在发生”的条文预览
- `occurred_preview_as_of_age`: 计算预览时使用的虚岁（默认 `当前年份 - 出生年份 + 1`）

筛选规则：
- `age_start/age_end != 0/0`
- `age_start <= occurred_preview_as_of_age`
- 默认排除已用于 `evidence_preview` 展示的条文（避免重复）

---

## 6. 锁定规则

### 6.1 必填事实（可配置）
锁定必填事实由 ruleset 配置决定：
- 配置：`tieban_rulesets.rules.lock.required_fields`
- 默认：`father_zodiac`、`mother_zodiac`（`siblings_count` 为可选事实）

前端提示：若锁定时缺少必填事实，状态栏会提示用户补充缺失字段后再锁定。

### 6.2 证据
每个必填事实至少 1 条条文命中；证据写入 `evidence`。

### 6.3 唯一性
仅允许以下两种锁定：
- **唯一候选**  
- **唯一 true_ke**（仅锁 ke，base 不唯一）

`lock_mode` 用于标注锁定类型：
```
unique_candidate | unique_ke
```

---

## 7. 命书输出结构

### 7.1 四固定栏目
1) 封面与卷首  
2) 考刻定分  
3) 先天六亲断语  
4) 流年大运批导

### 7.2 年表年龄来源
年表严格使用 `tieban_verses.age_start/age_end`，`0/0` 不入年表。

### 7.3 Generated vs Grid
补充算法条文标记 `source="generated:..."`，主链路条文标记 `source="grid"`。  
Generated 条文 **不得**用于锁定证据。

---

## 8. 高级算法（补充引擎）

### 8.1 太玄取数（Taixuan）
将干支映射为太玄数，为前后卦与八卦滚法提供基础。

### 8.2 前后卦取数（Front/Back）
生成两条条文号，并归一化至 `1001..13000`。

### 8.3 八卦滚法（Roll 48）
8 卦 × 每卦 6 条，使用 **×100+ 组合公式**：

```
arrange = A[upper]*10 + A[lower]
xian    = X[upper]*10 + X[lower]
hou     = H[upper]*10 + H[lower]

6 条：
arrange*100 + xian
arrange*100 + hou
xian*100 + arrange
xian*100 + hou
hou*100 + arrange
hou*100 + xian
```

### 8.4 冲突项配置
见 `docs/tieban/tieban_v8_conflicts.md`：
- `roll_policy.first_hex`：`opposite` / `mutual`
- `verse_id_mapping.mode`：`linear` / `wrap`
- `generated_sources`：`front_back` / `roll_48` / `fourmen`

---

## 9. 配置与规则集

### 9.1 RuleSet 核心字段
```
stem_number_map
stem_digit_order
trigram_map
taixuan_hex        # 太玄取数起卦（先天/后天 4 位基数），可选增强候选覆盖面；可选 ke_adjust=1327*(ke-1)*2
hex_secret_table_ref
hex_constants_ref
day_mutation
verse_id_mapping
avoid_ten_rule
linear_offsets
secret_jump_search
candidate_pool  # max_candidates/max_return/evidence_preview_limit/occurred_preview_limit
```

### 9.2 算法种子
`docs/tieban/tieban_algo_seed.json` 用于：
- 太玄映射
- 三组数序（arrange / xian_tian / hou_tian）
- roll_policy / generated_sources

---

## 10. API 示例

### 10.1 /api/tieban/init
```json
{
  "name": "张三",
  "gender": "男",
  "date": "1980-02-11",
  "time": "14:33:00",
  "tz_offset_hours": 8,
  "location_name": "北京",
  "known_facts": {"father_zodiac": "ZI", "mother_zodiac": "HAI", "siblings_count": 2}
}
```

### 10.2 /api/tieban/select
```json
{
  "run_id": "run_xxx",
  "candidate_id": "A:6387:3",
  "state_version": "2025-12-25T12:00:00"
}
```

---

## 11. 常见错误与排查

- `missing_required_facts`：缺少必填事实（服务端返回时可能附带缺失字段列表）  
- `required_fact_not_matched`：事实未命中条文  
- `lock_not_unique`：候选或 true_ke 未唯一  
- `conflict=true`：救援链路后仍无法命中  

排查顺序：
1) 检查事实字段是否规范化（生肖枚举/数字字段）  
2) 检查 rule set 是否加载正确  
3) 对照 `tieban_v8_conflicts.md` 的配置项  

---

## 12. 代码位置索引

- 核心流程：`services/tieban/service.py`
- 标准化：`services/tieban/normalizer.py`
- 引擎：`services/tieban/engines.py`
- 映射：`services/tieban/mapping.py`
- 高级算法：`services/tieban/roll_engine.py`
- 命书输出：`services/tieban/report_builder.py`
- API 路由：`api/main.py`
