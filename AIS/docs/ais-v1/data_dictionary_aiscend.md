标题：AIScend 数据字典（v1 相关）

校验说明
- 校验时间：2025-10-29（America/New_York 当地为 2025-10-29）。
- 连接信息：localhost:8224 / 数据库 aiscend / schema public（使用环境变量 PGPASSWORD）。
- 生成方式：通过 information_schema 与 pg_catalog 实时读取；关键表已核对主键/索引/分区结构与列类型。
- 用途范围：覆盖 AIS v1 回测与研究所需的核心表；后续表扩展将按相同格式追加。

全局约定
- 时间：日线日期列为 date（无时区）；created_at/updated_at 多为 timestamp with time zone/without time zone，保持原样。
- 货币：部分表提供 currency 与 *_usd 列；价格与金额单位需结合上下文（real/double precision/numeric）。
- 分区：ticker_price 为分区父表，按年份/区间拆分（见下）。
- 命名：ticker 为文本 ticker 代码；公司主键通常为 id（bigint）。

机读区块（MVP）
以下为“可执行数据字典”的最小示例，供系统在运行时解析为注册表（registry）。请保持 fenced YAML 代码块正确（```yaml ... ```）。

价格-日频-USD（v1）

```yaml
id: price.daily_usd
version: v1
source:
  table: public.ticker_price
  key: [ticker, date]
  fields:
    adj_close: real
    amount_usd: real
    volume: bigint
    currency_convert_usd: real
    mkt_cap_usd: bigint
semantics:
  price_field: adj_close
  execution_price_proxy:
    prefer: amount_usd/volume
    fallback: (open+high+low+close)/4 * currency_convert_usd
  alignment: drop
quality_checks:
  required_fields: [adj_close]
  coverage_threshold_pct: 95
status: verified
owner: research
```

因子：INDMOM 3-1（v1）

```yaml
id: factor.indmom_3_1
version: v1
depends_on: [price.daily_usd@v1]
formula:
  type: momentum_3_1
  params:
    lag_exclude_days: 21
    lag_window_days: 63
io:
  read_only: true
status: verified
owner: research
```

1. ticker_price（父表，分区）
- 用途：日线 OHLCV 及派生市值/金额，作为回测主数据源。
- 主键/索引：
  - PRIMARY KEY (ticker, date, id)（父表）
  - idx_ticker_price_ticker_date（ticker, date）
  - idx_ticker_price_updated（ticker, updated_at DESC）
- 分区结构：
  - 子表（节选）：ticker_price_1965_1969, 1970_1974, …, 2020, 2021, 2022, 2023, 2024, 2025, 2026（共 18 个）。
  - 估算行数（合计）：约 292,208,928 行（pg_class.reltuples 汇总）。
- 列（public.ticker_price）：
  - id bigint NOT NULL
  - ticker text NOT NULL
  - date date NOT NULL
  - open real, low real, high real, close real, adj_close real
  - volume bigint
  - currency text, currency_convert_usd real
  - share_num bigint
  - amount real, amount_usd real, close_usd real
  - mkt_cap bigint, mkt_cap_usd bigint
  - created_at timestamptz, updated_at timestamptz
- 备注：
  - 建议优先使用 adj_close/close_usd（若做跨币种对齐）。
  - 大表查询需使用分区裁剪（按 date 范围）并限制 symbol 数量或使用批量模式。

2. ticker_price_change
- 用途：多周期收益率快照，便于选股/排序与概览。
- 主键/索引：PRIMARY KEY(id)
- 列：
  - id bigint NOT NULL
  - ticker text
  - 1d, 5d, 1m, 3m, 6m, ytd, 1y, 3y, 5y, 10y, max double precision
  - run_time timestamptz
- 备注：
  - 字段名以数字开头（1d/5d…），SQL 中需使用双引号引用。
  - 计算口径需与回测窗口保持一致（避免混淆收盘到收盘 vs. 包含当日）。

3. ticker_base
- 用途：证券基础信息（名称、交易所、行业、公司标识等）。
- 约束/索引：PRIMARY KEY(id)、UNIQUE(ticker)、idx_ticker_base_ticker。
- 关键列：
  - ticker（唯一）、exchange/exchange_short_name、company_name、industry、sector、country、is_etf/is_adr/is_fund、download、updated_at、data_source。
  - 其他：mkt_cap、vol_avg、cik、isin、cusip 等。

4. company_base
- 用途：公司层面的基础信息与统计（与 ticker 可能为一对多）。
- 约束/索引：PRIMARY KEY(id)、UNIQUE(company_name)。
- 关键列：
  - company_name、cik、ticker、exchange_short_name、industry、sector、country、is_adr/is_etf/is_fund、download、updated_at。
  - 金额类：mkt_cap/mkt_cap_usd、currency、currency_convert_usd、amount_avg/amount_avg_usd、vol_avg。

5. company_ticker_map
- 用途：原始公司/代码到标准化公司/代码的映射（含国家/交易所信息）。
- 约束/索引：PRIMARY KEY(id)。
- 关键列：
  - original_company_name/original_ticker/original_country
  - mapped_company_name/mapped_ticker/mapped_country/mapped_ticker_cn
  - company_id、exchange_short_name、cik、currency、country_type、create_date

6. ticker_technical_indicators
- 用途：技术指标快照（价格/均线/布林带/波动/量能等），日级。
- 约束/索引：PRIMARY KEY(ticker, date)；按 ticker、date、updated_at 建索引。
- 列（全量）：
  - ticker varchar(20) NOT NULL
  - date date NOT NULL
  - updated_at timestamp
  - currentprice/currenthigh/currentlow/currentopen numeric(15,2)
  - currentvolume bigint
  - sma10/sma20/sma50/sma200 numeric(15,2)
  - pricetosma10/20/50/200 numeric(8,4)
  - pricevssma10pct/20pct/50pct/200pct numeric(8,2)
  - sma10tosma20/20tosma50/50tosma200/10tosma200 numeric(8,4)
  - stddev10/20/50 numeric(15,4)
  - cv10/20/50 numeric(8,4)
  - bb20upper/middle/lower numeric(15,2)
  - pricetobb20upper/lower numeric(8,4); bb20position numeric(8,4)
  - bb60upper/middle/lower numeric(15,2)
  - pricetobb60upper/lower numeric(8,4); bb60position numeric(8,4)
  - volumesma10/20/50 bigint; volumetosma10/20/50 numeric(8,2); volumestddev20 bigint; volumecv20 numeric(8,4)
  - dailyrange numeric(15,2); dailyrangepct numeric(8,2)
  - high10/20/50/200/1y/3y/5y/10y numeric(15,2)
  - low10/20/50/200/1y/3y/5y/10y numeric(15,2)
  - pricein10drange/20drange/50drange/200drange/1yrange/3yrange/5yrange/10yrange numeric(8,4)

7. mv_industry_momentum_hist
- 用途：行业层面的动量窗口统计（示例列 1M/3M/6M），供行业轮动策略使用。
- 约束/索引：PRIMARY KEY(as_of_date, industry, region)；索引 as_of_date。
- 列：
  - as_of_date date NOT NULL
  - industry text NOT NULL
  - region text NOT NULL
  - tickers_count int
  - chg_1m/chg_3m/chg_6m double precision
  - updated_at timestamp

8. mv_strategy_indmoment_hist
- 用途：以“行业动量”思想筛得的候选个股/标的历史快照与排序，配合回测与事后分析。
- 约束/索引：PRIMARY KEY(as_of_date, ticker)；索引 (as_of_date, industry)、(as_of_date, region)。
- 列：
  - as_of_date date NOT NULL
  - ticker text NOT NULL
  - industry text, region text
  - chg_1m/chg_3m/chg_6m double precision
  - rk_chg_1m/rk_chg_3m/rk_chg_6m int
  - selected_by text[]（被何种规则选中）
  - checklist jsonb（校验清单/理由）
  - updated_at timestamp

9. 其他与 v1 相关视图/表（摘要）
- portfolio_entity：研究/报告用的实体汇总（含多类评分、财务派生字段、嵌入向量等）。
- v_*：若作研究报告/筛选条件参考，可按需扩展入库接口；v1 回测不直接依赖。

使用建议（与 v1 需求对齐）
- 价格读取：优先按日期范围使用分区裁剪，并限制一次标的数量；超阈值用批处理。
- 收益口径：若使用 ticker_price_change，需在实验配置中明确窗口定义与是否跳过最近一期（如 5-1 月）。
- 行业映射：行业使用 company_base/ticker_base 的 industry 字段或独立行业映射表（若后续新增），保持与 mv_* 表一致。
- 货币与复权：跨币种研究建议统一使用 *_usd 与 adj_close；在实验清单中记录口径。

校验记录（关键事实）
- ticker_price 为分区父表，存在 18 个子表（1965_1969 … 2026）。
- ticker_technical_indicators 主键 (ticker, date)，指标列 76 项（见上完整列表）。
- mv_industry_momentum_hist 主键 (as_of_date, industry, region)。
- mv_strategy_indmoment_hist 主键 (as_of_date, ticker)。
- 估算行数：ticker_price（全部分区）约 2.92 亿行；ticker_price_change 约 1,019,957 行；ticker_base 约 72,558 行；company_base 约 74,593 行。

与需求的对应关系
- 统一数据访问：本字典固定关键字段/键与用途，供 src/core 与 src/services 的数据层实现做依据。
- 防止前视：时间列类型与主键说明为因子/回测的“仅用当期前数据”提供约束依据。
- 日志与审计：读取这些表时应输出查询规模、分区命中与缺口告警。

补充（v1 策略口径，重要）
- ADV3m（3 个月日均成交额，美元）：严格以 `ticker_price.amount_usd` 计算均值；窗口以自然日向前约 100 天近似 63 个交易日，SQL 口径：`AVG(amount_usd)`（自动忽略 NULL）。不再以 `volume*close_usd` 兜底。
- 市值 market_cap_usd（as‑of）：优先 `f_valuation_multiple.market_cap_usd` 最近期值（按 `ABS(f.date - as_of)` 最小）；缺失回退到 `ticker_price.mkt_cap_usd` 当日值。
- 执行价（回测）：默认“当日均价”（`amount_usd/volume`）；缺失回退 `(open+high+low+close)/4 * currency_convert_usd`。
- 调仓日：以“最后交易日”替代“日历月末/季末”，遇节假日顺延下一交易日；测试断言统一更新。

## 新增 — 因子/策略治理与运行域 Schema（面向插件化）

以下在不改变既有语义的前提下进行“只增不改”的最小增强设计；如与历史查询存在冲突，建议以 VIEW 做兼容。

### 1) 因子治理（微调）

factor_meta（保留文档定义，新增状态与索引建议）

```sql
CREATE TABLE IF NOT EXISTS factor_meta (
  factor_id SERIAL PRIMARY KEY,
  factor_name VARCHAR(50) NOT NULL,
  category VARCHAR(50) NOT NULL,
  formula_description TEXT NOT NULL,
  parameters JSONB,
  applicable_universe VARCHAR(50) NOT NULL,
  update_frequency VARCHAR(20) NOT NULL,
  version VARCHAR(10) NOT NULL,
  author VARCHAR(50),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  update_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status VARCHAR(20) NOT NULL DEFAULT 'Active'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_factor_meta_name_version ON factor_meta(factor_name, version);
CREATE INDEX IF NOT EXISTS ix_factor_meta_name ON factor_meta(factor_name);
```

factor_value（保留长表，新增可选追溯字段与索引）

```sql
CREATE TABLE IF NOT EXISTS factor_value (
  id BIGSERIAL PRIMARY KEY,
  factor_id INT NOT NULL REFERENCES factor_meta(factor_id),
  date DATE NOT NULL,
  asset_id VARCHAR(50) NOT NULL,
  value NUMERIC(18,6) NOT NULL,
  version VARCHAR(10),
  source VARCHAR(50),            -- 可选：vendor/self
  currency VARCHAR(8),           -- 可选
  adjustment VARCHAR(20),        -- 可选：adj/na
  quality_flag VARCHAR(20),      -- 可选
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_factor_value_key ON factor_value(factor_id, date, asset_id);
CREATE INDEX IF NOT EXISTS ix_factor_value_date ON factor_value(date);
CREATE INDEX IF NOT EXISTS ix_factor_value_asset ON factor_value(asset_id);
```

分区建议：按年或按 (factor_id,date) 范围；维护策略：定期 VACUUM/ANALYZE 与索引重建计划。

### 2) 策略治理（支持插件化与追溯）

策略治理采用“单表按行版本化”模型：每个策略版本占据 `strategy_meta` 一行；不再单独维护 `strategy_version` 与 `strategy_factor_map` 表。

strategy_meta（主档+版本化，一体化结构）

```sql
CREATE TABLE IF NOT EXISTS strategy_meta (
  strategy_id SERIAL PRIMARY KEY,
  strategy_name VARCHAR(100) NOT NULL,
  version VARCHAR(20) NOT NULL,              -- 语义化版本；与名称构成唯一键
  category VARCHAR(50),
  subcategory VARCHAR(50),
  frequency VARCHAR(20),
  direction VARCHAR(20),
  status VARCHAR(20) NOT NULL DEFAULT 'Developing',
  author VARCHAR(50),
  description TEXT,
  documentation VARCHAR(200),
  notes TEXT,
  -- 插件化所需：
  plugin_package VARCHAR(100) NOT NULL,      -- 如 ais-strategy-indmoment-oversea-qtr
  plugin_version VARCHAR(50) NOT NULL,       -- 插件自身版本
  entrypoint VARCHAR(120) NOT NULL,          -- pkg.module:load
  api_version VARCHAR(10) NOT NULL,          -- 如 v1
  -- 参数与依赖：
  param_snapshot JSONB,                      -- 参数快照（JSONSchema 校验后记录）
  factors_used JSONB,                        -- 因子依赖列表：[{name, version|policy}，policy 支持 'ActiveLatest']
  -- 追溯与绩效摘要：
  code_ref VARCHAR(64),                      -- git commit/tag
  perf_summary JSONB,                        -- 回测摘要（示例：CAGR/Sharpe/MDD/WinRate/...）
  perf_file VARCHAR(200),                    -- 详细报告路径（可为空）
  config_file VARCHAR(200),                  -- 示例/参数配置路径
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_strategy_meta_name_version ON strategy_meta(strategy_name, version);
CREATE INDEX IF NOT EXISTS ix_strategy_meta_status ON strategy_meta(status);
```

### 3) 运行域（结果、产物与清单）

backtest_run（新增清单扩展字段）

```sql
CREATE TABLE IF NOT EXISTS backtest_run (
  run_id TEXT PRIMARY KEY,
  experiment_name TEXT,
  start_date DATE,
  end_date DATE,
  benchmark TEXT,
  config_hash TEXT,
  strategy_name TEXT,
  plugin_package TEXT,
  plugin_version TEXT,
  params JSONB,
  factors JSONB,
  perf JSONB,
  report_paths JSONB,   -- {equity, trades, perf_report, audit_report}
  git_commit TEXT,
  code_version TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

backtest_equity / backtest_trade（保持现有结构，建议补索引）

```sql
CREATE TABLE IF NOT EXISTS backtest_equity (
  run_id TEXT,
  date DATE,
  nav NUMERIC,
  PRIMARY KEY (run_id, date)
);
CREATE INDEX IF NOT EXISTS ix_bte_run ON backtest_equity(run_id);

CREATE TABLE IF NOT EXISTS backtest_trade (
  run_id TEXT,
  date DATE,
  ticker TEXT,
  side TEXT,
  quantity NUMERIC,
  price NUMERIC,
  commission NUMERIC,
  slippage NUMERIC
);
CREATE INDEX IF NOT EXISTS ix_btt_run_date ON backtest_trade(run_id, date);
```

run_artifact（可选统一产物索引）

```sql
CREATE TABLE IF NOT EXISTS run_artifact (
  run_id TEXT,
  type TEXT,
  path TEXT,
  sha256 TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ra_run ON run_artifact(run_id);
```

兼容性策略：
- 原字段/表保持不变；新增字段仅补充追溯与插件信息。
- 历史查询如依赖旧字段名，可通过 VIEW 提供兼容映射。

### 4) 风控审计（策略内部风控与账户级风控的运行日志）

strategy_risk_signal（策略内部风控信号，运行期记录）

```sql
CREATE TABLE IF NOT EXISTS strategy_risk_signal (
  run_id TEXT NOT NULL,
  ts TIMESTAMPTZ NOT NULL,
  date DATE NOT NULL,
  strategy_name TEXT NOT NULL,
  version TEXT NOT NULL,
  ticker TEXT NOT NULL,
  type TEXT NOT NULL,            -- sl/tp/trailing_sl/vol/event
  params JSONB,                  -- 阈值、窗口、事件元数据
  action TEXT NOT NULL,          -- close/reduce_to/cap_to/freeze
  target_weight NUMERIC,         -- 当 action=reduce_to/cap_to 时有效
  hard BOOLEAN DEFAULT FALSE,
  reason TEXT,
  PRIMARY KEY (run_id, ts, ticker, type)
);
CREATE INDEX IF NOT EXISTS ix_srs_run ON strategy_risk_signal(run_id);
CREATE INDEX IF NOT EXISTS ix_srs_date ON strategy_risk_signal(date);
```

risk_breach（账户级/组合级风控触发日志）

```sql
CREATE TABLE IF NOT EXISTS risk_breach (
  run_id TEXT,
  ts TIMESTAMPTZ NOT NULL,
  scope TEXT NOT NULL,           -- account/portfolio/strategy/ticker
  rule_id TEXT,                  -- 规则ID（与配置匹配）
  key TEXT NOT NULL,             -- 规则键（如 max_weight/turnover/day_limit）
  value NUMERIC,                 -- 触发时的数值
  limit NUMERIC,                 -- 阈值
  action TEXT,                   -- 动作（如 cap/close/reject）
  severity TEXT,                 -- hard/soft
  source TEXT,                   -- global/strategy/portfolio
  details JSONB
);
CREATE INDEX IF NOT EXISTS ix_rb_run ON risk_breach(run_id);
CREATE INDEX IF NOT EXISTS ix_rb_ts ON risk_breach(ts);
```

---

## AIS 策略数据库（ADC + 策略治理/运行）

原则
- 与 aiscend 完全解耦：aiscend 仅为只读基础源；AIS 承载 ADC 落地与策略治理/运行/审计。
- ADC 不反向要求源表改造；复杂计算（VWAP/TWAP、FX、as‑of 对齐、ADV 等）在 LDC 层实现（服务计算或 AIS 预计算）。

核心表（见 db/ddl/ais_db_init.sql）
- ADC（schema=adc）：
  - `adc_prices_daily(date, ticker, close/adj_close/open/high/low, volume, currency, fx_to_usd, close_usd, amount_usd, mkt_cap_usd, quality_flag, src_ts)`
  - `adc_exec_vwap_day(date, ticker, vwap_day_usd, notional, volume, quality_flag, src_ts)`
  - `adc_benchmark_daily(date, bench_code, close_usd, ret, src_ts)`
  - `adc_factor_value(date, ticker|security_id, factor_name, factor_version, value, quality_flag, src_ts)`
  - `adc_security_ref(security_id, ticker, exchange_code, sector, industry, country, currency_base, alias_json, src_ts)`
- 策略治理与运行（schema=public）：
  - `strategy_meta`（按行版本化）、`backtest_run`、`backtest_equity`、`backtest_trade`、`strategy_risk_signal`、`risk_breach`、`run_artifact`。

迁移与初始化
- 创建数据库与表：`scripts/create_ais_db.sh`（使用与 aiscend 相同连接配置，仅变更 DB 名）；
- 可选迁移现有策略结果表：`db/ddl/migrate_strategy_tables_to_ais.sql`（使用 dblink 或 COPY）。

Provider 路由
- 优先读取 AIS（ADC 落地）→ LDC 服务计算（运行时）→ aiscend 直读（明确允许时降级），并在 manifest.ais_data_contracts 标注来源与 proxy。

---

—— 数据字典完 ——

附录 A：doc* 文档相关表

范围与用途
- 覆盖：doc_info、doc_text、doc_json、doc_paragraph、doc_embedding、doc_json_error，以及临时表 doc_info_tmp、doc_text_tmp。
- 用途：公司文本资料与分段、向量化嵌入、生成式摘要与错误记录，支持质化研究与段落级检索。

公共主键/关联
- 主键：多为 id（bigint/integer）。
- 关联：doc_text/doc_paragraph 与 doc_info 通过 doc_id 关联；doc_embedding 通过 doc_paragraph_id/doc_id 关联；均可携带 ticker/company_name/publish_time 等上下文。

字段要点（已对照信息架构）
- doc_info：内容元数据（content_type、original_*、publish_time、title、summary、text_len、file_path*、doc_type、doc_source、last_match_attempt_at 等）。
- doc_text：段落化文本（paragraph_num、doc_text、analysis_time、process_flag 等）。
- doc_paragraph：段落明细（paragraph_title/idx/offset/len、embedding_chunk_num/drop_chunk_num 等）。
- doc_embedding：段落/切片嵌入（voyage_embedding/gemini_embedding、chunk_*、tsvector 检索字段）。
- doc_json：结构化报告/摘要（report、version、prompt_tokens、segment_flag、gemini_embedding 等）。
- doc_json_error：生成失败记录（generate_type、reason、source、doc_ids、version 等）。
- 临时表 *_tmp：与正式表结构近似，供导入/预处理。

备注
- 嵌入列类型为向量（USER-DEFINED/vector），需要对应扩展（如 pgvector）。
- 文本时间列多为 timestamptz；year_quarter 多为文本。
- 生产查询建议仅读正式表；临时表用于落地与人工校验流程。

附录 B：*_entity 实体汇总表

包含对象
- portfolio_entity、segment_entity、segment_entity_comparable、segment_entity_test。

用途与键
- 用途：面向研究/报告的实体级综合视图，承载评分、分部信息、文本内容与嵌入等，便于下游 mv_info* 物化视图构建。
- 键与关联：id 主键；按 ticker/company_name 关联公司维度；时间列 score_update_time/publish_time 供快照。

字段要点
- portfolio_entity：price/market_cap/score 系列、embedding、quality_report（中英文）、source/segment_flag 等。
- segment_entity*：分部名称与分部维度指标（贡献度、利润率、份额、TAM、竞争对手、客户/供应商/渠道、趋势 JSON、终值与估值假设等），并保留分部文本与 embedding。

注意
- *_entity 为“实体汇总表”，逻辑上类似数据仓库宽表，更新策略需关注 run_time/updated_at 字段；作为 mv_info* 的上游来源。

附录 C：f* 财务与估值相关表

包含对象（节选）
- 核心报表：f_income_statement_{quarter,year}、f_balance_sheet_statement_{quarter,year}、f_cash_flow_statement_{quarter,year}
- 增长派生：f_growth_{income_statement,balance_sheet_statement,cash_flow_statement}_{quarter,year}
- 关键指标：f_key_metrics_{quarter,year} 及 predict
- 财务比率：f_financial_ratios_{quarter,year} 及 predict
- 估值相关：f_enterprise_values_{quarter,year}、f_valuation_financial_quarter、f_valuation_financial_quarter_growth、f_valuation_multiple、f_valuation_versions
- 其他：f_earning_calendar、f_financial_trends、f_percentile、f_news_release

通用字段与键（大多数表）
- id（integer/bigint）、ticker（text/varchar）、date（date/timestamp）、period（文本：FY/Q*）、calendarYear、symbol、reportedCurrency、run_time、updated_at。
- 其他均为数值类科目/比率/预测指标列，数量较多（~40–120）。

查询与使用建议
- 读取单表时优先选择所需列，避免 SELECT *。
- 年/季表口径注意统一（period、calendarYear 与 date 类型有差异）。
- predict 表为预测口径，避免与实际历史指标混用；实验清单应记录口径。

附录 D：mv_info* 实体物化视图（非数据表）

包含对象
- mv_info_quality、mv_info_trend、mv_info_momentum、mv_info_growth、mv_info_valuation、mv_info_total_return、mv_info_technical（relkind='m'，物化视图）。
- 相关历史表：mv_info_momentum_hist（普通表，记录 as_of_date/ticker 的动量历史）。

公共维度/键
- ticker、company_name、sector、industry、exchange、region（具体视图可能略有不同）。
- 时间戳：updated_at。

字段家族（示例）
- mv_info_quality：ROE/ROIC/各类利润率、杠杆与周转指标、分部质量分数与集中度、质量报告（中/英）。
- mv_info_trend：收入/净利/EBITDA/EPS/毛利率/经营性现金流/FCF/ROE/ROIC 等“当前/下一期”的趋势、累计变化与持续时长。
- mv_info_momentum：多周期收益（1D/5D/1M/3M/6M/YTD/1Y/3Y/5Y/10Y/MAX）、成交额强度偏离、总市值变动等。
- mv_info_growth：多口径增长（N季度/N年/CAGR）、研发/资本开支/现金流等子项增长；portfolio_growth_score。
- mv_info_valuation：PE/EVx（LTM/NTM）及分位点、EV/Sales/EBIT/EBITDA 等。
- mv_info_total_return：股东回报拆解（股息/回购/净偿债/期权费用）与前瞻假设、估值倍数变动与 3Y 总回报。
- mv_info_technical：SMA10/20/50/200、样本量与计算时间戳。

刷新与一致性
- 物化视图需定期刷新（REFRESH MATERIALIZED VIEW），v1 文档仅记录结构与用途；刷新策略在实现阶段定义（调度/依赖）。
- mv_info* 来源于 *_entity 与 f* 等基表融合，字段定义需与来源表口径一致。

获取完整列清单的 SQL 模板
- 基表/视图：
  ```sql
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='<表名>'
  ORDER BY ordinal_position;
  ```
- 物化视图（information_schema 不返回列时）：
  ```sql
  SELECT a.attname AS column,
         pg_catalog.format_type(a.atttypid,a.atttypmod) AS type
  FROM pg_attribute a
  JOIN pg_class c ON a.attrelid=c.oid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE a.attnum>0 AND NOT a.attisdropped
    AND n.nspname='public'
    AND c.relkind='m'
    AND c.relname='<物化视图名>'
  ORDER BY a.attnum;
  ```
