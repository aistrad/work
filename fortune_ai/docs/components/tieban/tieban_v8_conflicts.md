# Tieban v8 冲突项配置说明

本说明记录 v8 规格中存在争议或多解的实现点，并给出可配置开关与默认值。默认值以本项目实现为准；若与 v8 HOS（`docs/tieban/tieban_spec_ultra_ultra_v8.md`）不同，会在条目中明确标注。

## 1) 互卦/错卦定义冲突
**背景**：v8 文档指出“互卦定义差异”，并以算例结果选择“错卦（六爻全反）”。

**配置**（算法种子）：
- 文件：`docs/tieban/tieban_algo_seed.json`
- 键：`roll_policy.first_hex`
- 可选值：
  - `opposite`：以错卦为第一卦（六爻全反）
  - `mutual`：以互卦为第一卦（2-4/3-5 爻互卦）

**默认值**：`opposite`

---

## 2) verse_id_sequence 是否回绕
**背景**：v8 伪代码示意为“从 base_norm 递增至 range_max”，而现有实现曾采用环形回绕。

**配置**（规则集）：
- 位置：`tieban_rulesets.rules.verse_id_mapping.mode`
- 可选值：
  - `linear`：线性递增至 `range_max`（不回绕）
  - `wrap`：整环回绕（覆盖全周期）

**默认值**：`linear`

---

## 3) generated_sources 命名与启用范围
**背景**：v8 文档示例为 `front_back/roll_48`，历史实现存在 `fourmen` 变体。

**配置**（算法种子）：
- 文件：`docs/tieban/tieban_algo_seed.json`
- 键：`generated_sources`
- 可选键：
  - `front_back`：前后卦两条
  - `roll_48`：八卦滚法 48 条
  - `fourmen`：四门变（可选扩展）

**默认值**：
```json
{ "front_back": true, "roll_48": true, "fourmen": false }
```

---

## 4) 锁定必填事实字段（与 v8 存在偏离）
**背景**：v8 HOS 将 `father_zodiac + mother_zodiac + siblings_count` 作为最小锁定门槛；但本项目产品交互要求“兄弟数不作为必选项”，因此将“锁定必填字段”做成可配置。

**配置**（规则集）：
- 位置：`tieban_rulesets.rules.lock.required_fields`
- 类型：字符串数组

**默认值（本项目）**：
```json
["father_zodiac", "mother_zodiac"]
```

**如需恢复 v8 门槛**：
```json
["father_zodiac", "mother_zodiac", "siblings_count"]
```

---

## 5) 变更与追溯
- 本文档与 v8 HOS 同步更新。
- 若线上规则集或算法种子改动，请在 `tieban_rulesets.rules` 与 `tieban_algo_seed.json` 中同步写明配置值。
