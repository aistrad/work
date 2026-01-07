# AIS v1 规格（Spec v2 重组）— 目标、原则与插件化框架（中文）

最近更新：2025-10-30（America/New_York）

本版为“规格重组”版本，确立 AIS 的目标与原则：
- AIS 提供稳定的框架/流程/规范与接口，不承载具体策略实现；
- 策略以“插件包 + 数据库注册 + 配置引用”方式接入，零改 Core；
- 数据库以单表按行版本化的 `strategy_meta` 落实策略治理；
- 执行后端可插拔（回测/实盘 IB 等）；
- 组合与全局风控由独立模块统一编排；
- 产物/日志/清单与审计为第一等公民，支持完全复现与对账。

## 新增（全局可执行数据字典机制 — Global Executable Data Dictionary, GEDD）

目的
- 以“一个全局、持续更新、可审阅的文档”为唯一入口，统一声明 AiScend 源表/字段与口径；策略/因子在决定用数时优先引用此文档中“已确认（verified）”项；若缺失，再参考 AiScend 数据字典挑选最合适表/列，新增为“待确认（proposed）”并进入审阅闭环。

范围与定位
- 全局人读文档：`docs/aiscend_database_dictionary.md`（不新增新文档）。文档中的机读区块使用 fenced YAML（```yaml ... ```）描述“数据集/因子/策略依赖”的契约，系统据此编译出运行期注册表（registry）。
- 本机制为 AIS 全局通用设施，所有策略/因子均遵循；IndMoment Oversea 仅作为示例。

通用优先级与决策逻辑（Resolver）
1) 命中全局文档中 `status=verified` 的数据集/因子 → 直接使用。
2) 命中 `status=proposed` → 仅允许研究/影子运行，不得进入生产入库路径，并在日志中 WARN 提示。
3) 若未命中 → 参考 AiScend 数据字典内容（同文件的人读章节），生成“proposed”条目（人读摘要 + YAML 机读块）并提交审阅；通过后升级为 `verified`。

机读区块最小字段（MVP）
- dataset：`id`, `version`, `source.table`, `key`, `fields`, `semantics(price_field, execution_price_proxy, alignment)`, `quality_checks(required_fields, coverage_threshold_pct)`, `status`, `owner`。
- factor：`id`, `version`, `depends_on[datasets...]`, `formula(type, params)`, `io(read_only)`, `status`, `owner`。

自修复（Autofix）与强校验（MVP）
- Autofix 安全改（自动应用）：代码块语言标注缺失→补 `yaml`；键名与下划线风格统一（如 `closeUSD`→`close_usd`）；`version` 归一（如 `v1.0`→`v1`）。
- Autofix 建议级（需审阅）：基于 information_schema 的表/列名模糊匹配替换、口径表达式统一（`amount_usd/volume` 与 OHLC×汇率回退）、单位/枚举归一。
- 强校验：关键字段缺失阻断；DB 实查缺表/缺核心列阻断；required_fields 覆盖率不足降级为 `proposed` 并阻断生产路径。

重要约束（人工审核）
- `status: verified` 只能由人工编辑文档设置或修改；程序不得自动将任何条目置为 `verified`，也不得在运行时自动升级条目状态。
- 生产/回测正式通道必须使用 `verified` 条目；如需在研究/影子模式使用 `proposed`，必须显式开启 `AIS_ALLOW_PROPOSED=1`，并在日志中标注风险提示。

运行时集成（MVP 要求）
- Orchestrator 在“DB Health”前后插入 `DictionaryHealth`：加载全局文档→解析为 registry→记录 `dictionary.loaded`/`dictionary.health` 日志→在 manifest 写入 `dictionary_commit` 与 `datasets_used/factors_used`。
- Providers 严禁裸列名扩散：读取 registry 的 `dataset` 合约生成 SQL，按 `fields` 裁剪列、按 `semantics` 施加对齐/执行价 proxy 口径。

人机协同
- 研究者优先从全局文档中选用 `verified` 项；若缺失，新增 `proposed` 条目（人读摘要+YAML），CI 解析器执行 Parse→Lint→Autofix→DB 实查→出具 `autofix_diff.md` 与 `health.json`；评审通过后升级为 `verified`。

EARS 验收条目（节选）
- 当运行编排器时，系统应从 `docs/aiscend_database_dictionary.md` 解析机读区块生成 registry，并在日志输出 `dictionary.loaded`（包含条目数、commit、路径）。
- 当加载 registry 后，系统应对 `price.daily_usd@v1` 数据集执行表/列存在性校验，并在失败时以 ERROR 退出（`dictionary.health`）。
- 当策略运行完成时，系统应在 manifest 写入 `dictionary_commit` 与 `datasets_used/factors_used` 列表。
- 当处于生产/正式回测模式时，系统必须拒绝使用 `status != verified` 的数据集/因子；若设置 `AIS_ALLOW_PROPOSED=1` 则允许影子运行但禁止写入生产表。

本节为当前权威规格；旧版条目仍保留于文档后续章节供参考。

## 新增 — 策略 IR/DSL 契约（权威，v1）

目标
- 将“自然语言策略→结构化中间表示（IR）”固化为唯一入口；后续构建与执行均以 IR 为准。

范围与约束
- 禁止前视：IR 引用的数据集/因子必须来自 GEDD，生产仅允许 `status=verified`。
- 单一事实来源：调仓频率、执行时点、成本、约束、组合逻辑均以 IR 为权威；插件不得自定义外部 I/O。
- 追溯：每次运行必须在 manifest 写入 `ir_version` 与 `ir_sha256`，并将 IR 快照保存于运行目录与数据库。

EARS 验收
- 当解析器接收到自然语言策略时，系统应生成一份 IR（含 meta/frequency/universe/signals/combination/constraints/rebalance/costs/diagnostics/gedd_ref）。
- 当 IR 中引用到任一数据集/因子时，系统应校验其在 GEDD 中存在且满足状态要求；若为 `proposed`，应仅允许影子运行并记录 WARN。
- 当运行开始时，系统应将 IR 快照与 `ir_sha256` 写入 `runs/<run_id>/manifest.json` 与数据库的相应字段。

IR 最小 schema（参考 design.md 中“策略 IR/DSL — 权威契约”示例）。

## 新增 — 回测 I/O 契约（v1）

目标
- 统一回测输入（价格、目标权重、调仓日程、执行假设）与映射逻辑，确保可比与可追溯。

EARS 验收
- 当执行回测时，系统应仅在 `rebalance_dates` 提交订单；无有效价格时顺延至下一交易日并记录日志。
- 当选择价格代理时，系统应优先使用 `amount_usd/volume`，若缺失则回退 `(O+H+L+C)/4×currency_convert_usd`，并在 manifest 记录 `backtest_price_proxy`。
- 当关闭成本时，系统应在 manifest 中将佣金/滑点记录为 0。

## 新增 — 结果 IR 契约（v1）

目标
- 用稳定的 JSON 结构承载净值、交易、绩效、审计与诊断，便于自动比较与报告生成。

EARS 验收
- 当回测完成时，系统应在 `runs/<run_id>/` 生成“结果 IR”文件（或写入 manifest 的结构化节点），字段包含 run/exec/equity/trades/perf/audit/diagnostics/logs。
- 当开启诊断时，系统应输出分桶表现（by 指定口径与 bins）与稳定性概览（profiles: train/validate/perturb）。
- 当产生任何审计事件（约束命中/风控触发）时，系统应在结果 IR 的 `audit` 节点汇总计数与概要。

## A. 目标与原则（Goals & Principles）
- 框架先行：以配置驱动、可复现的一键流水线为核心；
- 插件解耦：新增/变更策略不修改 Core；
- 追溯合规：结构化日志、Manifest、DB 记录保证复现与审计；
- 单一真源：price_field、对齐策略、风险配置均集中声明；
- 渐进扩展：先日频与 IB 实盘（Paper→Live），再向多策略组合与统一风控演进。

（新增）与 GEDD 的一致性
- 所有取数路径以 GEDD 为契约来源；文档变更必须可追溯并与运行产物对账；破坏性变更以新版本发布并保留宽限期。

【规划】ADC 模式与数据层解耦（暂不启用）
- 方向：引入 ADC（AIS Data Contracts）作为系统与策略消费的数据契约，仅依赖“逻辑数据集 + 字段语义”，不直接依赖 aiscend 的具体表/列。
- 原则：ADC 不反向修改数据源（aiscend）；复杂计算（如 VWAP/TWAP、对齐、as‑of 市值/ADV）在 ADC 层实现（服务计算或策略库预计算），并在 manifest 标注口径与回退（proxy）信息。
- 现状：本阶段读取统一直接来自 aiscend（只读）；写入统一进入 AIS 数据库（见下）。ADC 保留为后续计划，不影响当前读路径。

## B. 架构边界
- AIS Core：流程编排、接口契约（Strategy/Providers/ExecutionBackend/PortfolioCombiner/RiskEngine/Artifacts）、配置校验、日志与审计、DB 追溯、插件装载。
- Strategy Plugin：实现具体打分/选股/权重与调仓日程；可输出内部风控信号；产出 `StrategyOutput`（weights、rebal_dates、diagnostics、risk_signals、weights_after_risk、artifacts）。

（新增）DictionaryHealth/Resolver（全局）
- DictionaryHealth：解析并校验全局文档（表/列/口径必要项），输出健康报告与日志事件；
- Resolver：依据“verified→proposed→生成提案”的优先级解析数据集/因子依赖，为 Providers/策略提供稳定的数据契约。

## C. 执行后端（ExecutionBackend）
- 回测：BacktestSimBackend（Backtrader/Pandas）。
- 实盘：IBBrokerBackend（建议 ib_insync），职责包括合约映射、目标→订单、部分成交处理、状态同步与节流/重试；Paper→Live 灰度。
- 默认执行策略：
  - 实盘（默认）：当日 TWAP 或 VWAP 执行（按配置选择，其一为默认），并在 manifest 记录 `execution_policy`（类型与时间窗）。
  - 回测（默认）：若有 `amount_usd/volume`，以“全日 VWAP”近似成交价；否则使用 `(O+H+L+C)/4 × currency_convert_usd` 作为 TWAP 近似。所有口径须在 manifest 标注 `backtest_price_proxy`。

## D. 组合与风控
- PortfolioCombiner：多策略输出来的“账户级目标权重”合成；资金分配、冲突调解、约束投影。
- RiskEngine（集中配置，分层覆盖）：global→portfolio→strategy-default→strategy-override→ticker-overrides；规则优先级：全局硬 > 策略硬 > 全局软 > 策略软；更保守优先。

## E. 数据与对齐
- 当前阶段读取：统一直接从 aiscend 读取（只读）；包括价格/基准/因子/参考维度等。
- PriceProvider：以 `data.price_field in {adj_close, close_usd}` 与 `data.alignment in {drop, ffill, asof}` 为口径对齐；量纲（volume/amount/mkt_cap_usd）直接来源于 aiscend 的对应列；当发生近似（如 VWAP/TWAP 近似）需在 manifest 标注 `backtest_price_proxy`。
- FactorProvider：按 `factor_meta` 解析精确版本或 ActiveLatest；读取 `factor_value`；材料化写入仅对白名单因子放行。
- BenchmarkProvider：与组合严格对齐。

## F. 产物与清单（Manifest）
- 目录：`runs/<YYYYMMDD_HHMMSS>__<strategy_slug>__<short-hash>/`。
- 文件：`equity_curve__<slug>.csv`、`trades__<slug>.csv`、`perf_report__<slug>.json`、`audit_report__<slug>.json`、`logs/`。
- Manifest 字段：`strategy_slug`、`plugin_package`、`plugin_version`、`entrypoint`、`git_commit`、`code_version`、`run_dir_name`、`risk_profile/risk_config_hash`、风险统计与报告路径；DB `backtest_run.report_paths` 存关键产物相对路径。
  - 执行字段（新增）：`execution_timing`、`execution_policy`（{type: TWAP|VWAP, window: HH:MM-HH:MM, slices?}）、`backtest_price_proxy`（vwap_full_day|ohlc_mean_x_usd）、`open_price_source`（当执行时点=open 且使用 COC 时）。

## K. 执行策略（Execution Policy）— EARS（新增）
1) 当运行在实盘模式时，若未显式指定，系统应默认采用当日 TWAP 或 VWAP 执行策略（可由全局配置选择其一）；并在 manifest 记录 `execution_policy` 的类型与时间窗口（如 09:35-10:35）。
2) 当运行在回测模式且缺少日内数据时，系统应使用 `amount_usd/volume` 作为“全日 VWAP”近似；若该列缺失，则使用 `(O+H+L+C)/4 × currency_convert_usd` 作为 TWAP 近似；两者均需在 manifest 标注 `backtest_price_proxy`。
3) 当选择 execution_timing=open 且启用 COC 时，不应与“当日 TWAP/VWAP 默认”同时生效；若同时配置，系统应按优先级执行 `execution_policy`，并以 WARN 记录冲突，manifest 以最终执行口径为准。
4) 审计报告应包含“执行假设”段，展示 `execution_timing`、`execution_policy`、`backtest_price_proxy`，并提供“成交偏离对账”（如与全日 VWAP 的偏离统计）。

## G. 数据库（治理/运行与写入归口）
- 因子：`factor_meta`/`factor_value`（只增不改，增加追溯字段与索引/分区建议）。
- 策略：仅用 `strategy_meta`（按行版本化；UNIQUE(strategy_name, version)），包含插件字段/参数快照/因子依赖/代码引用/绩效摘要等。
- 运行：`backtest_run/equity/trade`；风控审计：`strategy_risk_signal`、`risk_breach`（全局/组合/策略层）。
- 写入归口：本阶段所有 AIS 的“因子材料化/策略回测结果/审计数据”统一写入 AIS 数据库：
  - 因子材料化：`adc.adc_factor_value`（及可选 `public.factor_meta` 治理副本）；
  - 策略治理与运行：`public.strategy_meta`、`public.backtest_run`、`public.backtest_equity`、`public.backtest_trade`；
  - 风控与产物索引：`public.strategy_risk_signal`、`public.risk_breach`、`public.run_artifact`。
- 读取来源：本阶段统一从 aiscend 读取；ADC（`adc.*`）作为后续计划的读取层。

## H. 策略插件示例 — indmoment oversea（季度）
- 插件包：`ais-strategy-indmoment-oversea-qtr`；entry: `ais_strategy_indmoment_oversea_qtr:load`；api_version=v1。
- 依赖因子：R_1m、R_3_1、R_6_1；ADV3m 与 mkt_cap_usd 由 `ticker_price` 口径提供。
- 参数 Schema（示例）：`{ ind_top_n, tkr_top_n_per_industry, overall_max, ind_1m_cap, beta, skip_industries, min_mcap_usd, min_adv3m_usd }`；
- 输出：`weights/rebal_dates/diagnostics`；可选 `risk_signals/weights_after_risk`（事件/波动率/止盈止损）。

验收（EARS 摘要）
- 插件新增无需改 Core；配置校验通过；回测/实盘共用同一策略输出契约；Manifest/DB 追溯完整；日志/审计产物齐备。

## I. 风控配置 JSONSchema（仅接口，暂不实现）

说明：下述 JSONSchema 约束 `risk` 顶层配置结构（集中配置 + 分层覆盖）。具体字段可根据迭代扩展，但基本骨架需保持稳定以便向后兼容。

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "urn:ais-v1:risk-config",
  "title": "AIS v1 RiskEngine Config",
  "type": "object",
  "properties": {
    "risk": {
      "type": "object",
      "required": ["engine", "layers"],
      "properties": {
        "engine": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean", "default": true},
            "evaluation": {
              "type": "array",
              "items": {"type": "string", "enum": ["pre_trade", "in_trade", "post_trade"]},
              "default": ["pre_trade"]
            }
          },
          "additionalProperties": false
        },
        "layers": {
          "type": "object",
          "properties": {
            "global": {"$ref": "#/$defs/ruleSet"},
            "portfolio": {"$ref": "#/$defs/ruleSet"},
            "strategies": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["match", "rules"],
                "properties": {
                  "match": {
                    "type": "object",
                    "properties": {
                      "strategy_name": {"type": "string"},
                      "version": {"type": "string"}
                    },
                    "additionalProperties": false
                  },
                  "rules": {"$ref": "#/$defs/ruleSet/properties/rules"}
                },
                "additionalProperties": false
              },
              "default": []
            },
            "ticker_overrides": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["tickers", "rules"],
                "properties": {
                  "tickers": {"type": "array", "items": {"type": "string"}},
                  "rules": {"$ref": "#/$defs/ruleSet/properties/rules"}
                },
                "additionalProperties": false
              },
              "default": []
            }
          },
          "additionalProperties": false
        }
      },
      "additionalProperties": false
    }
  },
  "$defs": {
    "ruleSet": {
      "type": "object",
      "properties": {
        "rules": {
          "type": "array",
          "items": {"$ref": "#/$defs/rule"},
          "default": []
        }
      },
      "additionalProperties": false
    },
    "rule": {
      "type": "object",
      "required": ["id", "scope", "type"],
      "properties": {
        "id": {"type": "string"},
        "scope": {"type": "string", "enum": ["portfolio", "strategy", "ticker"]},
        "type": {
          "type": "string",
          "enum": [
            "cap_weight", "sl", "tp", "trailing_sl", "vol", "event",
            "turnover_cap", "notional_cap", "order_rate_cap"
          ]
        },
        "params": {"type": "object"},
        "severity": {"type": "string", "enum": ["hard", "soft"], "default": "soft"},
        "priority": {"type": "integer", "minimum": 0, "default": 10},
        "enabled": {"type": "boolean", "default": true}
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

校验规则
- 规则并不限定 `params` 的详细字段（随类型扩展），仅保证类型/范围；引擎在运行时做二次语义校验。
- `evaluation` 控制规则在哪些阶段生效；默认 pre_trade。

## J. 接口契约（仅声明，暂不实现）

J.1 ExecutionBackend（执行后端）
- 目标：对接不同执行通道（回测/IB）；将“账户状态×目标权重”映射为订单/成交与执行报告；保证幂等与可恢复性。
- 接口（示意，Python 风格）
```
class ExecutionBackend:
    def initialize(self, context) -> None: ...
    def sync_account(self) -> AccountState: ...                 # 拉取账户权益、现金、持仓、挂单
    def target_to_orders(self, target: AccountTargetWeights,
                         policy: OrderPolicy) -> list[OrderIntent]: ...
    def submit(self, intents: list[OrderIntent]) -> list[BrokerOrderId]: ...
    def poll_fills(self, since: Optional[datetime]=None) -> list[Fill]: ...
    def reconcile(self) -> ExecutionReport: ...                 # 对账：目标/持仓/挂单/成交差异
    def cancel_open_orders(self, filter: CancelFilter) -> int: ...
    def heartbeat(self) -> None: ...

class AccountTargetWeights:  # 账户级最终目标（组合/风控后）
    weights: pd.DataFrame  # index=date, columns=ticker

class OrderIntent:
    ticker: str
    side: Literal['BUY','SELL']
    qty: float
    price_type: Literal['MKT','LMT']
    limit_price: Optional[float]
    tif: Literal['DAY','OPG','GTC']
    meta: dict

class Fill:
    ts: datetime
    order_id: str
    ticker: str
    side: str
    qty: float
    price: float
    commission: float
    slippage: float

class ExecutionReport:
    orders: list[OrderIntent]
    submitted: list[str]        # broker order ids
    fills: list[Fill]
    rejects: list[dict]
    metrics: dict               # 成交率、平均偏离、费用等
```

J.2 PortfolioCombiner（组合器）
- 目标：多策略输出合成为账户级目标权重，独立于策略插件。
- 接口（示意）
```
class PortfolioCombiner:
    def combine(self, outputs: dict[str, StrategyOutput],
                capital_policy: CapitalPolicy,
                constraints: ConstraintSet) -> AccountTargetWeights: ...

class CapitalPolicy:
    mode: Literal['fixed', 'vol_budget', 'risk_parity']
    params: dict

class ConstraintSet:
    max_weight: float
    sector_caps: dict[str, float]
    country_caps: dict[str, float]
    turnover_cap: float
```

约束
- 本节仅声明接口，不代表具体实现；实际实现需在设计与任务清单确认后进行。

# AIS v1 回测系统 — 需求说明（v0.2，中文）

最近更新：2025-10-29（America/New_York）

## 0. 简介

本文档定义 AIS v1 的最小可用需求：一个“配置驱动、一键运行、可复现”的回测系统，集成 AiScend 的 PostgreSQL 数据库。目标运行环境为 Python 3.11+ 与 PostgreSQL 16+。系统遵循“少即是多”的原则，充分复用成熟开源能力（如 Backtrader 用于回测执行，借鉴 Qlib 的因子数据治理模式，QuantStats/PyFolio 产出指标），聚焦因子与策略版本治理、事务化数据库访问、结构化日志与可审计产物，严格避免功能蔓延。

v1 的范围聚焦：日频股票策略；从 AiScend DB 读取价格与因子数据；基于单一配置文件完成全流程；输出标准化结果（净值曲线、交易明细、绩效报告）。不包含：实盘交易、日内/高频、分布式计算、可视化前端。

### 上下文复用与对齐（可重用组件与模式）
- 数据库配置与连接池：复用 `financial_analysis/fmp-data-downloader/src/postgresql_config.py` 中的 `PostgreSQLConfig`，以及 `financial_analysis/market-cap-calculator/database.py` 中 `DatabaseManager` 的连接池/事务/健康检查模式。
- 结构化日志：借鉴 `financial_analysis/financial-growth-calculator/src/utils/logging_utils.py` 的组件化日志与性能装饰器思路，并与根仓 AGENTS.md 的“JSON+轮转”规范保持一致。
- 数据字典对齐：遵循 `.claude/specs/ais-v1/data_dictionary_aiscend.md` 中的关键表与命名约定（如 `ticker_price`、`ticker_base`、`factor_meta`、`factor_value`、部分 `f_*` 表）。
- 回测引擎：使用 Backtrader，避免重复造轮子（事件循环、组合账户、佣金/滑点挂钩等）。

## 1. 系统级需求

1.1 用户故事
- 作为量化研究员，我希望通过单个配置文件运行回测，以便可靠复现实验并对比策略变体。

1.2 验收标准（EARS）
1) 当提供合法的实验配置文件时，系统应校验配置模式并以唯一 `run_id` 与不可变清单（manifest）启动运行。
2) 当缺失或非法配置项出现时，系统应快速失败并给出可操作的错误提示与修复建议。
3) 当回测运行时，系统应将关键步骤、决策与指标写入结构化日志（见第 8 节），并将产物持久化到版本化的运行目录。
4) 当回测结束时，系统应至少产出：`equity_curve.csv`、`trades.csv`、`perf_report.json|txt`、`manifest.json`、`backtest.log`。
5) 当执行数据库操作时，系统应仅使用事务化与参数化 SQL。

【新增】1.3 暖启动与调仓日规则（EARS）
1) 当配置中未显式关闭 `data.lookback` 时，系统应默认启用暖启动并向前扩展 `start_date` 至少 90 天，仅用于因子/信号计算，不计入回测时间窗。
2) 当策略频率为“月度”时，系统应以“每月最后一个有数据的交易日”为调仓日，且仅在显式调仓日触发下单（不因权重前推产生日内再平衡）。
3) 当市场过滤为 `region=hk` 时，系统应优先按 `exchange_short_name`（如 HKSE）过滤，未提供交易所时回退按 `country in (Hong Kong/HK/HKG)`。
4) 当回测结束时，系统应生成 `runs/<run_id>/audit_report.json`，包含月度/季度调仓日清单、当期可用标的数、持仓数量与覆盖率（按策略定义）、换手率、费用对账（佣金/滑点 bps 分布）、异常月份提示（含费用均值与配置偏离 >1bps 的告警）。

【新增】1.4 选股逻辑（indmoment oversea — 季度，行业优先）
用户故事：
- 作为策略研究员，我希望采用“行业先行、个股二次筛选”的季度动量方法，并在全球海外市场（排除 CN/HK 交易所）上，严格按照指定口径选择行业与个股，以便得到稳定可复现的组合与可审计的落地数据。

验收标准（EARS）：
1) 当 universe=download=true 且 region=oversea 时，系统应按 `exchange_short_name` 排除 CN/HK 别名（SHH/SSE/SHZ/SZ/SZSE/SHE/HK/HKSE/SEHK/HKEX），并仅纳入在区间内有行情的证券。
2) 当到达季度调仓日（季度最后一个交易日）时，系统应：
   - 先对每个行业统计满足 `mkt_cap_usd>2B AND adv3m_usd>10M` 的个股数量，少于 3 个的行业应被剔除；
   - 在保留行业中，按行业 `R_1m<10%` 过滤；
   - 分别对行业 `R_3_1` 与 `R_6_1` 取 Top5，取并集；若并集>10，则按 `rank_sum → R_6_1 → cap_sum` 截至 10，否则全部纳入；
   - 仅在已选行业内选股：过滤 `r_1m<15% AND mkt_cap_usd>2B AND adv3m_usd>10M`，在每个行业内按策略参数选取若干标的，并按 `rank_sum → r_6_1 → mcap` 排序（可不足目标数量）。
3) 当形成目标权重时，系统应对被选个股等权分配；整体上限=行业数×K（不额外截断）；无候选则当季空仓。
4) 当执行成交价格时，系统应优先使用 `amount_usd/volume` 的当日均价；若缺失则 `(open+high+low+close)/4 * currency_convert_usd` 兜底。
5) 当统计 adv3m_usd 时，系统应以 `ticker_price.amount_usd` 的近 100 自然日均值近似最近 63 个交易日；不得使用 `volume*close_usd` 替代口径。
6) 当统计 mkt_cap_usd 时，系统应优先使用 `f_valuation_multiple.market_cap_usd` 最近期记录（最接近调仓日）；若缺失则回退至 `ticker_price.mkt_cap_usd` 当日值。

## 2. 数据库连接与架构探查

2.1 用户故事
- 作为系统操作者，我希望获得安全、带连接池、可观测的数据库访问，以保证任务稳定与可审计。

2.2 验收标准（EARS）
1) 当初始化时，系统应优先从环境变量（默认 `AISCEND_DB_URL`）加载 DB 设置，若缺失则回退到 `PostgreSQLConfig.get_config("aiscend")`（不得在日志中泄露密钥）。
2) 当获取连接时，系统应通过连接池与上下文管理的事务（BEGIN/COMMIT/ROLLBACK）执行，并对瞬时性错误采用退避重试。
3) 当准备运行时，系统应按数据字典检查必需表与关键列是否存在，并记录健康检查报告。
4) 当执行查询时，系统应仅使用参数化 SQL，且不得申请超出必要的权限。
5) 当发生 DB 错误时，系统应记录“脱敏后的错误上下文”，并以非 0 退出码优雅终止。

## 3. 因子目录（factor_meta）与治理

3.1 用户故事
- 作为量化负责人，我希望以元数据与版本管理登记因子，使结果可追溯至精确的因子定义。

3.2 验收标准（EARS）
1) 当新因子被批准时，系统应在 `factor_meta` 新增记录，包含名称、类别、公式描述、参数（JSONB）、适用范围、更新频率、版本、作者、时间戳与状态。
2) 当因子公式/参数变化时，系统应创建新版本（新增行或版本号升级），不得覆盖历史定义。
3) 当按名称查询因子时，系统应解析到具体版本；若存在歧义，系统应要求显式选择版本并给出警告。
4) 当因子被退役时，系统应更新状态且保留历史记录以保证可复现性。

## 4. 因子值（factor_value）读取

4.1 用户故事
- 作为回测执行者，我希望按日期区间与样本空间高效获取因子序列，使运行既高效又可复现。

4.2 验收标准（EARS）
1) 当运行请求因子值时，系统应从 AiScend 数据库的 `factor_value` 表按 `factor_id` 与配置的时间范围和样本空间读取，并在可用时利用分区/索引。
2) 当覆盖缺口存在时，系统应记录 WARN（含缺失数量），并根据配置选择丢弃缺失资产或使用默认值回补。
3) 当加载大范围数据时，系统应采用分块/流式读取限制内存占用，并记录每块耗时。
4) 当请求多个因子时，系统应按日期与资产对齐，并在 INFO 中记录对齐损失（被丢弃的行数）。

## 5. 策略注册与版本管理

5.1 用户故事
- 作为策略所有者，我希望策略定义与版本可被登记，且与依赖的因子版本显式关联，使每次运行都能完全归因。

5.2 验收标准（EARS）
1) 当创建或更新策略版本时，系统应在 `strategy_meta` 表新增一行（按行版本化）：包含 `strategy_name`、`version`、分类/方向/频率、插件字段（`plugin_package/plugin_version/entrypoint/api_version`）、`param_snapshot` 与 `factors_used`（因子依赖列表，支持 `version` 或 `policy=ActiveLatest`）、`code_ref`、`perf_summary` 等。
2) 当查询策略定义时，系统应通过 `(strategy_name, version)` 唯一键定位具体实现；查询某策略所有版本时，按 `strategy_name` 过滤并按 `created_at`/`version` 排序。
3) 当回测运行时，系统应在 manifest 记录所用策略 `(strategy_name, version)` 与全部因子版本（或当时解析的 ActiveLatest 具体版本）。

## 6. 配置模型（实验配置）

6.1 用户故事
- 作为研究员，我希望用单一 YAML/JSON 文件定义实验，使引擎无需改代码即可完成全流程编排。

6.2 必需配置段（最小集）
- `experiment`：`name`、`owner`、`run_id`（自动或外部给定）、`seed`、`notes`。
- `data`：`start_date`、`end_date`、`calendar`、`universe`（过滤条件：交易所/行业/国家/TopN；默认=AiScend 数据库中的全部可用标的，含 ADR/ETF/非美股等）、`benchmark`（默认待确认，建议=SPY）。
- `factors`：`{name, version, parameters?}` 列表。
- `signals`：可选信号预处理/标准化（如 z-score、winsorize）。
- `strategy`：`{plugin, version, params}`，以插件包与版本为唯一来源（零改 Core），示例插件见“策略插件示例”章节；核心规范不预设通用参数（如 top_k），所有参数以具体策略设计为准；
- `costs`：佣金、滑点模型、做空/借券约束（v1 可默认为多头）。
- `rebalance`：频率（如日/周/月/季），执行时点假设（收盘/开盘/次日开盘）。当采用 Backtrader “cheat‑on‑open” 假设时，必须在 manifest 标注该假设与参数。
- `risk`：单票上限、换手上限、行业上限（v1 可选，默认关闭）。
- `output`：输出目录、产物选择（表/图）、保留天数。
- `logging`：日志级别覆盖、输出端选择（控制台/文件）、运行标签。

6.3 验收标准（EARS）
1) 当加载配置时，系统应按 JSONSchema 校验并生成可读的校验报告。
2) 当缺省字段出现时，系统应应用文档化默认值并在 INFO 记录（例如 `universe` 默认=AiScend 全部；`benchmark` 若未指定则按约定默认，见下条）。
3) 当 `strategy.plugin` 不存在或版本不兼容时，系统应快速失败并提示可用插件与版本范围；当插件 `api_version` 与 Core 不兼容时拒绝运行。
4) 当 `benchmark` 未指定时，系统应采用默认基准（待确认，建议=SPY，来源表建议=`ticker_price` 的 SPY 序列）；当 `run_id` 与现有目录冲突时，系统应拒绝覆盖，除非显式设置 `allow_overwrite: true`。

## 7. 回测编排与产物

7.1 用户故事
- 作为用户，我希望引擎以确定性管道从数据准备到指标与产物的全流程执行，使结果可对比、可复现。

7.2 流程步骤（最小集）
1) 数据准备：加载价格与样本空间；对齐交易日历；加载基准。
2) 因子加载：读取因子序列；可选预处理；与交易日/样本空间对齐。
3) 信号转权重：由策略插件根据 `params` 产出 `weights/rebal_dates/diagnostics`（必要时 `risk_signals/weights_after_risk`）。
4) 执行模拟：通过 ExecutionBackend（回测=Backtrader/Pandas）完成订单/成交/费用/滑点仿真；若执行时点=开盘且采用“cheat‑on‑open”，需在 manifest 记录。
5) 指标与报告：生成日度净值曲线；计算核心指标（至少：年化、波动、最大回撤、Sharpe）。
6) 产物落地：写出 `equity_curve.csv`、`trades.csv`、`perf_report.json|txt`、`manifest.json`（含配置、代码版本、因子/策略版本）、`backtest.log`。

7.3 验收标准（EARS）
1) 当管道执行时，系统应记录各阶段的开始/结束与耗时，并记录阶段成功/失败状态。
2) 当启用成本模型时，系统应在成交与 PnL 中反映费用/滑点，并在 manifest 中记录关键假设（成本模型基线待确认，建议=固定佣金+固定 bps 滑点）。
3) 当生成报告时，系统应对齐文档中引用的 GitHub 开源库（如 QuantStats/PyFolio）的“默认核心指标”集合输出；最小集应包含：年化收益（CAGR）、波动率、Sharpe、最大回撤、胜率、交易笔数、换手率。
4) 当运行结束时，系统应仅在所有强制产物存在且通过基本一致性校验（非空、长度对齐）后以 0 码退出。

## 8. 强制日志与监控要求

8.1 必须记录的事件/动作
- 运行生命周期：开始/结束、配置路径与哈希、解析后的默认值、随机种子、`run_id`。
- DB 交互：连接获取/归还、查询形状（脱敏）、耗时、返回行数；架构健康检查结果。
- 流程阶段：开始/结束/耗时；阶段输入/输出规模；对齐/过滤导致的丢弃行数。
- 策略摘要：调仓日期、目标构成/持仓前N摘要（按策略定义）、约束触发、换手率。
- 错误与告警：校验失败、数据覆盖缺口、数值异常。
- 性能指标：阶段耗时、可选内存快照、I/O 吞吐。

8.2 日志级别
- DEBUG：研发诊断；详细输入/输出规模。
- INFO：生命周期、默认值、阶段边界、计数与耗时。
- WARN：可恢复异常（覆盖缺口、约束触发导致丢弃等）。
- ERROR：不可恢复错误；DB 错误；校验错误。
- FATAL：需要立即终止的系统级失败。

8.3 日志格式与结构
- 推荐 JSON 行格式，字段包含：`timestamp`、`level`、`component`、`run_id`、`message`，以及上下文字段（如 `stage`、`rows_in`、`rows_out`、`duration_ms`）。
- 时间戳使用 ISO 8601，时区处理一致。
- 组件名稳定（如 `db`、`orchestrator`、`strategy`、`metrics`）。

8.4 日志保留与轮转
- 同时支持按大小（如 50MB）与按天轮转；默认保留 ≥ 14 天，可配置。
- 输出端可配置：控制台（开发）、文件（默认），外部日志服务钩子可留作未来扩展（v1 非必需）。

8.5 性能监控
- 对每个主要阶段记录 `start_ts`、`end_ts`、`duration_ms`。
- 长任务期间按固定步长输出进度（如每处理 N 个交易日）。
- 在 `perf_report.json` 中提供概要性能段。

## 9. 错误处理要求

9.1 验收标准（EARS）
1) 当发生关键配置/数据库错误时，系统应终止运行，写出错误摘要并以非 0 退出。
2) 当出现数据对齐缺口时，系统应在配置允许时继续（丢弃受影响数据）或以清晰信息终止。
3) 当检测到溢出/NaN 等数值异常时，系统应隔离异常行并按配置选择 WARN 报告或终止。

## 10. 性能、可扩展与资源安全

10.1 验收标准（EARS）
1) 当查询大表（如 `ticker_price`、`factor_value`）时，系统应采用分块/流式读取，并将内存占用控制在可配置阈值之下。
2) 当执行计算时，系统仅在不破坏确定性的前提下启用“尴尬并行”的步骤；v1 缺省关闭并行与复杂风控（不纳入单票/行业上限等约束）。
3) 当任一步骤超出可配置时间预算时，系统应输出 WARN 与诊断建议（例如缩小样本/区间）。

## 11. 安全与合规

11.1 验收标准（EARS）
1) 当读取 DB 凭据时，系统应优先使用环境变量，并禁止在日志中输出秘密。
2) 当写入产物时，系统应校验并限制路径到允许范围内。
3) 当加载第三方库时，系统应在 manifest 记录其版本以保证可复现性。

## 12. 项目结构与文档

12.1 验收标准（EARS）
1) 当初始化项目时，系统应遵循目录结构：`src/{core,models,services,utils}`、`config/`、`tests/{unit,integration,fixtures}`、`logs/`、`docs/`（统一文档目录）、`scripts/`、`temp/`、`.claude/specs/`。`doc/` 目录废弃，所有文档合并入 `docs/`。
2) 当生成设计与实施文档时，系统应与“详细执行流设计”保持同步。
3) 当创建 AIS v1 子项目时，应在根目录放置父项目的 AGENTS.md。

【新增】12.3 文档目录合并规范
- 统一文档目录为 `docs/`；`doc/` 目录标记为废弃（Deprecated），不再新增内容；
- 迁移策略：将 `doc/` 下历史文档合并进入 `docs/`，并更新规范/配置/脚本中的路径引用；
- 兼容期：在 `doc/` 留存一个 `README.MOVED.md` 指向 `docs/`（实现阶段执行）；
- 产物/示例：所有设计文档、运维手册、变更日志、数据库字典等统一存放在 `docs/`；规范引用路径统一为 `docs/...`。

## 13. 测试要求（v1）

13.1 验收标准（EARS）
1) 当运行单元测试时，系统应验证配置模式、数据库健康检查（只读）与最小样本管道连通性。
2) 当运行集成测试时，系统应在事务或测试 schema 内操作，且不得修改生产表。
3) 当对样例净值曲线计算指标时，系统应在容差范围内匹配参考值。

## 14. v1 范围外
- 实盘交易与券商连接。
- 日内数据与高频执行模型。
- 分布式编排（Airflow/Prefect 等）与多节点计算。
- 可视化前端与 Web 服务。
- 复杂风险模型（如因子风险分解）以及任何风控限额（单票/行业上限等）。

## 15. 待确认问题（请给出选择或范围）
- 基准：默认基准（如 SPY/等权）与来源表？建议默认=SPY；来源=AiScend `ticker_price`（SPY 的 `close_usd/adj_close`）。
- 成本：是否以“固定佣金 + 固定 bps 滑点”作为 v1 初始模型？建议=是（参数值可在配置中设定）。

---

附录 A — 最小配置示例（示意）

```yaml
experiment:
  name: ind-mom-top5
  owner: alice
  seed: 42

data:
  start_date: 2015-01-01
  end_date: 2024-12-31
  calendar: NYSE
  universe:
    exchange: NYSE,NASDAQ
    min_mkt_cap_usd: 1e9
  benchmark: SPY

factors:
  - name: IND_MOM_5_1
    version: "1.0"

signals:
  - type: zscore
    params: {winsor: 3.0}

strategy:
  plugin: ais-strategy-example
  version: "1.0.0"
  params: {}

rebalance:
  frequency: monthly
  execution_timing: open  # 如采用 Backtrader cheat-on-open，需在 manifest 标注

costs:
  commission_bps: 5
  slippage_bps: 5

output:
  base_dir: runs/
  keep_days: 14

logging:
  level: INFO
  sinks: [console, file]
```

---

日志要求摘要（强制）
- 级别：DEBUG、INFO、WARN、ERROR、FATAL。
- 格式：JSON 行，ISO 时间；包含组件与 `run_id`。
- 轮转：按大小/按天；默认保留 ≥ 14 天。
- 性能：记录阶段耗时；周期性进度；可选内存快照。
- 错误追踪：包含异常类型、消息与脱敏上下文。
- 审计溯源：记录关键决策（样本规模、因子覆盖、目标构成/持仓前N等）。

---

## 16. 新增 — 架构边界与策略插件化（规范）

16.1 框架/策略分离（强制）
- 新增或变更策略不得修改 AIS Core 源码；必须以“插件包 + 数据库注册 + 配置引用”的方式接入。
- AIS Core 职责：流程编排、接口契约（Strategy/Provider/Artifacts）、配置约束（JSONSchema）、结构化日志、产物与审计、DB 事务与追溯、插件装载。
- Strategy 插件职责：实现打分/选股/权重与调仓日程；提供参数 Schema、依赖因子清单与诊断/审计输出；产出标准化 `StrategyOutput`。

16.2 策略接口（API v1）
- 发现：Python entry points 组名 `ais.strategies`；每个插件暴露 `load(params: dict) -> Strategy` 工厂函数。
- Strategy：
  - `plan(context) -> StrategyPlan`（可选）：校验依赖因子与输入口径，返回需求与约束（例如 price_field、对齐策略）。
  - `compute(context, providers) -> StrategyOutput`：返回 `weights: DataFrame`、`rebal_dates: list[Timestamp]`、`diagnostics: dict`、`artifacts: list[ArtifactSpec]`。
- Context：`run_id`、`date_range/start/end`、`universe`、`calendar`、`engine_config`、`costs`、`rebalance`、`price_field`、`logging_adapter`。
- Providers：
  - `PriceProvider.load(field, tickers, start, end, lookback)`（支持 `adj_close|close_usd`，统一对齐策略 `drop|ffill|asof`）。
  - `FactorProvider.resolve(specs)`、`FactorProvider.load(ids,tickers,start,end)`；材料化写入仅对白名单因子放行（幂等、事务化）。

16.3 参数与依赖治理
- 参数 Schema 由插件内置（JSONSchema），Core 校验并将参数哈希写入 manifest/DB。
- 依赖因子由插件声明（名称+版本或 `ActiveLatest` 政策），Core 负责解析与可用性校验。

16.4 生命周期与门禁
- 生命周期：`Developing → Simulating → Approved → Deprecated → Retired`；生产仅允许 `Approved`。
- 质量门禁：单元测试≥80% 覆盖关键逻辑；固定样例净值得到一致；审计日志字段齐备；资源与时长限制配置完备。

---

## 17. 新增 — 回测产物命名与清单（Manifest）规范

17.1 目录命名
- 规则：`runs/<YYYYMMDD_HHMMSS>__<strategy_slug>__<short-hash>/`；`strategy_slug` 来源于策略注册名/插件包名的小写短横线形式；`short-hash` 保证唯一。
- 兼容：数据库主键 `run_id` 可保持现有生成逻辑；目录名与 `run_id` 可分离，需在 manifest 中记录双向映射字段。

17.2 文件命名
- `equity_curve__<strategy_slug>.csv`、`trades__<strategy_slug>.csv`、`perf_report__<strategy_slug>.json`、`audit_report__<strategy_slug>.json`；日志仍置于 `logs/` 子目录。

17.3 Manifest 新增字段
- 必含：`strategy_slug`、`plugin_package`、`plugin_version`、`entrypoint`、`git_commit`、`code_version`、`run_dir_name`。
- DB 映射：`backtest_run.report_paths` 存储上述关键产物相对路径，便于检索与比对。

---

## 18. 新增 — 数据访问与多市场对齐

18.1 价格与量纲
- 价格字段以 `data.price_field` 为唯一真源（`adj_close|close_usd`）；策略如需量与金额，统一从 `aiscend.public.ticker_price` 提供 `volume/amount/amount_usd/mkt_cap_usd` 等列。

18.2 对齐策略
- 统一配置 `data.alignment = drop|ffill|asof`；默认“各自日历计算→回对齐”，跨市场更稳健；基准序列由 `BenchmarkProvider` 输出，与组合严格按最终交易日对齐。

---

## 19. 新增 — 策略内部风控（可选，规范化接入，受全局风控统筹）

19.1 目标与范围
- 在不修改 AIS Core 与执行后端的前提下，允许策略插件输出“内部风控信号”，对自身持仓进行细粒度管理（如止盈、止损、波动率阈值、事件回避等）。
- 策略内部风控纳入全局 RiskEngine 统一编排：由 RiskEngine 读取策略输出（`risk_signals/weights_after_risk`）与全局风控配置，决定最终执行权重；插件保持零改动。

19.2 能力清单（最小可用集）
- 止损（Stop Loss）：当标的从建仓以来最大回撤超过阈值/从成本价下跌超过阈值时，将目标权重降为 0 或降低至最小权重。
- 止盈（Take Profit）：当标的收益达到阈值时，触发减仓或清仓；支持“分级止盈”（分段落袋）。
- 追踪止损（Trailing Stop）：随浮动收益抬升止损阈值，保护已得收益。
- 波动率护栏（Volatility Guard）：当 N 日年化波动率超过阈值/单日跳变超过阈值时，降权或清仓；支持“冷静期 Cooling-off”。
- 事件回避（Event Guard）：在财报日/停牌/高风险事件窗口前后 N 天减仓/清仓；事件来源可来自 DB（如 `f_earning_calendar`、`news_release`）或策略自评估信号。

19.3 接口契约（对 StrategyOutput 的扩展）
- 在不改变既有字段的基础上，新增：
  - `risk_signals: List[RiskSignal]`：逐标的风控信号。
  - `weights_after_risk: DataFrame`：应用内部风控后的目标权重（index=date, columns=ticker）。
- RiskSignal 规范：
  - `ts`（时间戳，ISO8601）
  - `ticker`
  - `type` ∈ {`sl`, `tp`, `trailing_sl`, `vol`, `event`}
  - `params`（JSON：阈值、窗口、事件元数据等）
  - `action` ∈ {`close`, `reduce_to`, `cap_to`, `freeze`}
  - `target_weight`（当 action=reduce_to/cap_to 时必填）
  - `hard`（bool，true 表示“硬性”内部约束）
  - `reason`（字符串，审计说明）

19.4 行为与优先级（EARS）
1) 当策略输出 `weights_after_risk` 时，RiskEngine 应先合并策略内部结果与其 `risk_signals`，再与全局/组合/账户级规则叠加，输出最终权重；若缺失，则以 `weights` 为准。
2) 同一标的同一日多个信号合并优先级：全局硬规则（global hard）> 策略硬规则（strategy hard）> 全局软规则（global soft）> 策略软规则（strategy soft）> freeze；并记录合并规则于审计。
3) 当内部风控与账户级/组合级风控冲突时，最终执行权重应满足更“保守”的一侧（权重更低/更接近 0）。

19.5 配置与 Manifest（EARS）
1) 当启用策略内部风控时，推荐将规则以全局配置形式维护（见 §20），策略端可仅输出 `risk_signals` 建议项；如策略需要自身特有阈值，可在全局配置的“策略覆盖层”声明，不嵌入插件代码。
2) 当运行结束时，manifest 必须包含：`risk_profile` 摘要（来源于全局配置与策略覆盖层）、`risk_signal_count`、`hard_action_count`、`freeze_days` 等统计字段与配置哈希。
3) 当产出审计报告时，应新增 `risk_events__<strategy_slug>.csv`（或纳入 `audit_report__<strategy_slug>.json` 的 `risk_section`），记录所有 RiskSignal 明细与汇总统计，并标注来源（global/strategy）。

19.6 日志与审计（EARS）
1) 当内部风控触发时，策略应记录日志事件 `risk.signal`（DEBUG/INFO），包含 `ticker/type/params/action/target_weight`。
2) 当权重因内部风控发生变化时，系统应记录 `risk.apply`（INFO），包含“前后权重差异/被影响标的/原因摘要”。
3) 当发生硬性 `close`/`cap` 时，应额外记录 WARN，并在审计报告中单列“硬限制”汇总。

19.7 测试与验收（EARS）
1) 当输入构造了止损/止盈/波动率/事件样例时，单元测试应断言 `weights_after_risk` 与 `risk_signals` 的正确性（阈值、排序、优先级）。
2) 当进行端到端回测时，审计报告应包含正确的 Risk 段落与统计；样例测试对关键天数的权重变化进行断言。
3) 当禁用内部风控时，`weights_after_risk` 应与 `weights` 等同，且 `risk_signals` 为空。

---

## 20. 新增 — 全局风控模块（RiskEngine）与配置管理

20.1 目标
- 将风控规则以“声明式配置”集中管理，支持全局/组合/策略/标的多层覆盖；RiskEngine 统一编排执行，产生日志与审计记录；不要求策略插件改动。

20.2 配置层级与合并
- 层级（从低到高覆盖）：`global` → `portfolio` → `strategy-default` → `strategy-override`（按 `strategy_name/version` 匹配）→ `ticker-overrides`。
- 规则优先级：硬规则（hard） > 软规则（soft）；相同层级多条规则按 `priority` 数值排序；合并冲突时取“更保守”的结果（更低权重/更严格动作）。

20.3 规则模型（示例）
```yaml
risk:
  engine:
    enabled: true
    evaluation: [pre_trade, in_trade, post_trade]   # 可选阶段
  layers:
    global:
      rules:
        - id: max_single_weight
          scope: portfolio
          type: cap_weight
          params: { max: 0.05 }
          severity: hard
          priority: 10
    strategies:
      - match: { strategy_name: indmoment-oversea-qtr, version: ">=1.2" }
        rules:
          - id: trailing_sl
            scope: strategy
            type: trailing_sl
            params: { window: 60, trail: 0.10 }
            severity: soft
            priority: 20
```

20.4 规则类型（最小集）
- `cap_weight`（权重上限）、`sl`（止损）、`tp`（止盈）、`trailing_sl`、`vol`（波动率护栏）、`event`（事件回避）、`turnover_cap`（换手上限）、`notional_cap`（名义金额上限）、`order_rate_cap`（下单速率）。

20.5 执行时序
1) 计算基础权重（策略输出 `weights`）；
2) 合并策略内部风控（`weights_after_risk/risk_signals`）；
3) 应用 RiskEngine 的策略层规则；
4) 组合层合成目标权重（如启用 PortfolioCombiner）；
5) 应用组合/账户层规则；
6) 生成最终执行权重 → 提交至执行后端（回测/实盘）。

20.6 Manifest 与审计
- Manifest：写入 `risk_config_hash`、`risk_layers_applied`、`rule_counts{hard,soft}`、`breach_counts`；
- 审计：输出 `risk_breach` 与 `strategy_risk_signal` 表/文件；按规则 `id` 串联查询与追溯。
## L. AIS 策略数据库（新增）

目标
- 将策略消费的数据（ADC 落地）与策略产生的结果/审计完全收口到 AIS 数据库，避免对 aiscend 的写入与强绑定。

连接
- AIS 与 aiscend 使用相同主机/端口/用户名密码（临时一致），数据库名为 `ais`；环境变量 `AIS_DB_URL` 与 `AISCEND_DB_URL` 并存。

表与分区（摘录，详见数据字典）
- ADC（后续计划的读取层）：`adc_prices_daily`、`adc_exec_vwap_day`、`adc_benchmark_daily`、`adc_factor_value`、`adc_security_ref`（按日期/标的分区与索引）。
- 现阶段写入层：`strategy_meta`、`backtest_run`、`backtest_equity`、`backtest_trade`、`strategy_risk_signal`、`risk_breach`、`run_artifact`、以及“因子材料化”`adc.adc_factor_value`。

口径与约束
- ADC 不反向要求数据源改造；当源缺失导致近似/回退时，必须在 manifest 标记 `backtest_price_proxy/alignment_used/fx_policy` 等。
- Provider 的读取优先级：AIS（LDC 落地）→ ADC 服务计算（运行时）→ aiscend 直读（仅在明确允许降级时）。

---

## 新增 — 自然语言解析与策略构建（NL Orchestrator + Strategy Builder）

目标
- 将“自然语言策略输入”标准化为“策略 IR/DSL”的唯一入口；再由构建器将 IR 渲染为配置与最小插件骨架，实现“契约先于实现”。

范围与约束
- 解析层（NL Orchestrator）仅输出 IR 与“最少澄清问题清单”，不得直连数据或下游执行。
- 构建层（Strategy Builder）仅消费 IR，渲染 config 与最小插件骨架；插件只能调用白名单 Providers，不得裸 SQL/外部 IO。

EARS 验收（节选）
- 当系统接收自然语言策略时，应输出一份机读 IR（见“策略 IR/DSL 契约”）并产生“最少澄清问题清单”（若必要）。
- 当 IR 通过 GEDD 校验后，构建器应渲染出配置文件与最小策略插件骨架（如需），参数与 IR 一一对应。
- 当 IR 引用到 `status!=verified` 的数据集/因子时，系统应只允许影子运行并输出 WARN，且默认禁止写入生产表。

## 新增 — 策略包交付规范（v1）

目标
- 将策略作为“可移植包”交付，统一评审与复用边界。

EARS 验收
- 当接入新策略时，交付物应包含：docs（人读说明）/specs（IR 与 profiles）/src（插件）/configs（渲染配置）/reports（基线产物）/tests（单测/集成）。
- 当策略被加载时，应通过 entry_points 组 `ais.strategies` 暴露 `load(params)->Strategy`，并校验 `api_version`。
- 当策略运行完成时，应在 manifest 与 DB 中记录 `strategy_slug/plugin_package/plugin_version/entrypoint` 等元信息。

## 新增 — 黄金路径（NL→IR→Builder→Core）EARS

EARS 验收
- 当自然语言策略被提交时，系统应先完成 IR 生成与 GEDD 校验；若存在不确定口径，应返回“最少澄清问题清单”。
- 当 IR 渲染完成后，系统应保存 IR 快照与哈希到 `runs/<run_id>/` 与数据库，并开始回测执行。
- 当执行完成时，应同时产出结果 IR、产物文件（equity/trades/perf/audit/logs）与 manifest，并写入 DB 追溯条目。

## 新增 — 日志与追溯（Manifest/DB）细化

EARS 验收
- 当运行开始时，系统应在 manifest 记录：`ir_version/ir_sha256`、`gedd.commit/datasets_used/factors_used`、`execution_timing`、`backtest_price_proxy`、`costs_bps`、`risk_profile` 概要。
- 当运行结束时，系统应保证 `runs/<run_id>/` 存在所有强制产物，且 manifest 中的校验和与实际文件一致。
- 当发生错误时，系统应输出结构化日志（JSON Lines）并以 ERROR 级别终止，保证事务回滚与资源释放。
