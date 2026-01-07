# Tieban Report Schema (v7)

## 顶层字段
- `run_id`: UUID
- `ruleset_name`: 规则集名称
- `locked_base`: 锁定基数
- `true_ke`: 真刻（1..8）
- `locked_context_id`: 锁定上下文（边界分裂时必须存在）
- `input_snapshot`: 标准化输入快照（可回放）
- `evidence`: 锁定证据（必须包含父/母/兄弟）
- `sections`: 数组（固定顺序）

## sections
0) `cover`
- `title`: 封面与卷首
- `data`: 命主信息、八字排盘、核心参数（含 `locked_base/true_ke/locked_context_id`）

1) `calibration`
- `title`: 考刻定分
- `data`: 数组（证据条文），每项包含：
  - `verse_id`
  - `content_raw`（完整原文，必填）
  - `age_start`（虚岁起始，0 表示不限）
  - `age_end`（虚岁结束，0 表示单年/不限）
  - `category`
  - `fact_meta`

2) `kinship`
- `title`: 先天六亲断语
- `data`: 对象（固定小节：父母/夫妻/子息与兄弟），每个小节包含条文数组；条文结构同上

3) `annual`
- `title`: 流年大运批导
- `data`: 数组（年表行），每项包含：
  - `age`（可选：展开行时使用，表示具体虚岁）
  - `age_start`（必填：条文标注起始虚岁）
  - `age_end`（必填：条文标注结束虚岁）
  - `year_ganzhi`（可选）
  - `verse_id`
  - `content_raw`（完整原文，必填）
  - `note`（可选）
