---
kind: Strategy
slug: <strategy-slug>
version: 1.0.0
universe:
  # either tickers or a DB query reference
  tickers: [XLC, XLY, XLP, XLE, XLF, XLV, XLI, XLB, XLRE, XLK, XLU]
  # db_query: 'SELECT ticker FROM universe_table WHERE tag = :tag'
parameters:
  j1_lookback_days: 126
  j2_lookback_days: 63
  skip_days: 21
  rebalance_frequency_days: 90
  max_holdings: 3
switches:
  enable_vix_switch: false
  enable_abs_momentum_filter: false
  enable_asset_vol_filter: false
objectives:
  primary: SharpeRatio
  direction: maximize
  constraints:
    - { metric: Drawdown, op: '<=', value: 0.35 }
data:
  source: aiscend
  root: data/
  qc_contract:
    time_format: 'YYYYMMDD 00:00'
    map_factor_alignment: true
orchestration:
  engine: lean-local
  docker_image: quantconnect/lean@sha256:cfb27f...
  outputs:
    backtests_dir: strategy/<strategy-slug>/qc/backtests
    runs_dir: strategy/<strategy-slug>/runs
    optimize_dir: strategy/<strategy-slug>/optimize
    reports_dir: strategy/<strategy-slug>/reports
---

# Overview
（中文）简述策略目标、适用市场、核心思想与收益/风险特征。

# Execution Flow
（中文）按步骤描述：取数→计算→排名→发信号→组合→执行→风控；注明日志与监控点。

# Reporting
（中文）要求的指标、曲线、危机年份切片与对比基准。

