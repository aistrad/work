# Tieban 前端 → 后端执行流程（/tieban）

> 目的：描述从 `/tieban` 页面点击按钮到后端执行、数据落库与命书输出的完整链路；含关键调用、状态与数据结构。

---

## 1. 总览（端到端）

```
┌──────────────┐   click/submit    ┌──────────────┐   POST /api/tieban/init   ┌──────────────────────┐
│  tieban.html │ ────────────────▶ │  tieban.js   │ ────────────────────────▶ │  api.main (FastAPI)  │
└──────────────┘                   └──────────────┘                          └──────────┬───────────┘
                                                                                          │
                                                                                          │ init_tieban
                                                                                          ▼
                                                                                 ┌──────────────────────┐
                                                                                 │ services/tieban/*    │
                                                                                 │ - normalizer         │
                                                                                 │ - candidate_pool      │
                                                                                 │ - store               │
                                                                                 └──────────┬───────────┘
                                                                                          │
                                                                                          │  returns candidates + state_version
                                                                                          ▼
┌──────────────┐   render candidates ┌──────────────┐                          ┌──────────────────────┐
│  tieban.html │ ◀────────────────── │  tieban.js   │                          │  Client sees list    │
└──────────────┘                      └──────────────┘                          └──────────────────────┘

   user selects candidate

┌──────────────┐  click candidate   ┌──────────────┐   POST /api/tieban/select ┌──────────────────────┐
│  tieban.html │ ────────────────▶  │  tieban.js   │ ────────────────────────▶ │  api.main (FastAPI)  │
└──────────────┘                    └──────────────┘                          └──────────┬───────────┘
                                                                                         │
                                                                                         │ select_tieban
                                                                                         ▼
                                                                                ┌──────────────────────┐
                                                                                │ services/tieban/*    │
                                                                                │ - report_builder     │
                                                                                │ - roll_engine        │
                                                                                │ - store              │
                                                                                └──────────┬───────────┘
                                                                                         │
                                                                                         │ returns report
                                                                                         ▼
┌──────────────┐  render report  ┌──────────────┐
│  tieban.html │ ◀────────────── │  tieban.js   │
└──────────────┘                 └──────────────┘
```

---

## 2. 前端触发点

### 2.1 页面入口
- URL：`/tieban`
- 模板：`api/templates/tieban.html`
- 静态脚本：`/static/tieban.js`

### 2.2 事件与行为

```
[用户输入姓名]
      │
      ▼
  (自动预填) ── GET /api/user/by-name?name=...
      │
      ▼
[点击“开始考刻”]
      │
      ▼
POST /api/tieban/init  →  返回候选命盘列表
      │
      ▼
[点击“选择此命盘”]
      │
      ▼
POST /api/tieban/select → 返回命书
```

- 预填逻辑：`api/static/tieban.js` 中对姓名输入做防抖查询 `GET /api/user/by-name`，返回后填充性别/日期/时间/地点/经纬度。
- 考刻按钮：表单提交触发 `POST /api/tieban/init`。
- 候选锁定：点击候选卡片触发 `POST /api/tieban/select`。

---

## 3. 后端 API 与核心处理

### 3.1 `/api/tieban/init`

**入口**：`api/main.py` → `services/tieban/service.py:init_tieban`

**关键步骤（ASCII 流程）**

```
输入 (name, gender, date, time, tz, location, known_facts)
   │
   ▼
normalize_input()  →  PillarsContext[] (边界时间考虑)
   │
   ▼
ETL ruleset + tables (tieban ruleset/secret table/constants)
   │
   ▼
build_candidate_pool()  →  candidates (base, ke, verse_ids)
   │
   ▼
rank_candidates() + evidence preview (fact_meta 交集)
   │
   ▼
store.create_profile + store.create_module_run
   │
   ▼
返回 candidates + state_version
```

**输出（关键字段）**
- `run_id`
- `candidates[]`
- `state_version`
- `pillars_contexts[]`

> 当前逻辑：若传入 `known_facts`，候选列表仅返回 `hit_count > 0` 的命盘（有命中证据）。

---

### 3.2 `/api/tieban/select`

**入口**：`api/main.py` → `services/tieban/service.py:select_tieban`

**关键步骤（ASCII 流程）**

```
输入 (run_id, candidate_id, state_version)
   │
   ▼
校验 state_version + 必填事实命中
   │
   ▼
build_report() → 合并 grid verses + generated verses
   │
   ▼
roll_engine.generate_additional_verses()
   │  ├─ front_back  (前后卦取数)
   │  └─ fourmen_roll (四门变/八卦滚)
   ▼
store.update_run_report() + store.update_profile_verified_facts()
   │
   ▼
返回 report
```

**输出（关键字段）**
- `report.locked_base`
- `report.true_ke`
- `report.locked_context_id`
- `report.generated_sources`（`front_back`、`fourmen_roll`）
- `report.sections[]`（命书结构）

---

## 4. 数据与存储

```
fortune_user
  └─ name / birthday / location / gender / ...

fortune_profile
  └─ verified_facts (锁定证据 + context_id)

fortune_user_module_run
  └─ input_snapshot / output_report

fortune_user_module_state
  └─ candidate_pool / status / facts / evidence
```

- `GET /api/user/by-name` 从 `fortune_user` 读取。
- Tieban 引擎运行后产物落在 `fortune_user_module_run` 与 `fortune_user_module_state`。

---

## 5. 前端-后端交互点（简表）

| 交互点 | 方法 | 触发 | 后端处理 | 返回 |
| --- | --- | --- | --- | --- |
| `/api/user/by-name` | GET | 姓名输入 | 读取 `fortune_user` | 生日/性别/地点等 |
| `/api/tieban/init` | POST | 点击“开始考刻” | 起盘+候选 | 候选列表 |
| `/api/tieban/select` | POST | 选择候选 | 锁定+命书 | 命书 JSON |

---

## 6. 可观测性（日志）

- `tieban_pool_build`：候选池构建统计
- `tieban_verify`：事实更新 / candidate ranking
- `tieban_front_back`：前后卦生成
- `tieban_roll_generate`：四门变/八卦滚生成

---

## 7. 关键文件索引

- 前端：`api/templates/tieban.html`, `api/static/tieban.js`, `api/static/tieban.css`
- API：`api/main.py`
- Tieban 核心：`services/tieban/service.py`, `services/tieban/report_builder.py`, `services/tieban/roll_engine.py`
- 存储：`services/tieban/store.py`, `user_store.py`
- 规则/ETL：`services/tieban/etl.py`, `docs/tieban/research tieban.md`

