---
title: FMP Downloader — Requirements
version: 0.1.0
owner: aiscend
created: 2025-11-06
status: Draft
---

# Overview
面向投研的数据下载程序，封装 Financial Modeling Prep (FMP) HTTP API，提供库与 CLI 两种用法，支持灵活端点、参数化与批量符号下载，并提供限流、重试、结构化日志与可复现输出。

# Goals
- 通过通用端点适配实现“任意 v3/stable 端点”的下载与参数传递。
- 支持 `--symbols` 批量下载，自动分页/游标。
- 内建可靠性：会话复用、指数退避、HTTP/网关错误自动重试、速率限制。
- 输出可复现：JSONL/CSV（可选 Parquet），伴随元数据与运行日志。
- 简洁集成：作为库导入或通过 CLI 运行；最小依赖（首版仅 `requests`）。

# Non-Goals
- 不内建数据库持久化（PostgreSQL/SQLite）；如需可在后续扩展。
- 不提供策略计算与因子工程；本组件仅负责数据采集。

# Context & Reuse
- 现有可复用资产：
  - `work/financial_analysis/fmp-data-downloader/src/fmp_bulk_downloader_v6.py`：批量下载与限流/分页策略（参考封装思路）。
  - `work/financial_analysis/fmp-data-downloader/src/news_press_ingestion.py`：基础常量、分页与 API Key 处理（`STABLE_BASE`/`API_V3_BASE`）。
  - `work/financial_analysis/fmp-data-downloader/src/utils/logger`：可参考日志格式与分级策略。
- 复用策略：以“薄封装”原则提取共性，避免拷贝大体量逻辑；本项目提供独立、无副作用的轻量客户端与 CLI。

# Functional Requirements
- Endpoint 通用访问：`GET /{base}/{path}`，支持 `v3` 与 `stable`，`--endpoint v3/quote` 或 `stable/news/stock-latest`。
- 参数传递：`--params key=value` 多次出现；数组自动拆分或以逗号分隔。
- 批量符号：`--symbols AAPL,MSFT` 或通过 `--symbols-file`；自动为每个符号调用并合并。
- 分页支持：识别 `page/limit` 或 `from/to` 风格，直到空页或达上限。
- 输出：
  - `--format jsonl|csv`（默认 jsonl）。
  - `--outfile path` 或 stdout；附加 `--metadata path.json` 写入运行上下文（endpoint、参数、时间、版本、计数）。

# Non-Functional Requirements
- 可靠性：
  - 重试：幂等 GET，网络错误/429/5xx 指数退避（抖动），最大重试次数可配置。
  - 限流：全局 `--max-per-min`，默认 30；线程安全令牌桶或简单 sleep 间隔。
- 观察性：
  - 结构化日志：JSON 行日志，关键事件（请求、重试、错误、产出计数）。
  - 可审计：保存请求样本（可选，红action 关键字段）。
- 可移植性：仅依赖 `requests`；Python 3.9+。

# Auth
- 使用 FMP API Key：优先级 `--api-key` > `FMP_API_KEY` 环境变量 > `~/.config/fmp_dl/.env`。
- 以查询参数 `apikey` 传递（符合 FMP 约定）。

# Rate Limits
- 默认 `--max-per-min 30`；可按账号配额调整。
- 自动在每次成功请求后进行节流；遇到 `429` 提升退避时间。

# Error Handling
- 错误分类：
  - 客户端：`400/404` 记录并跳过当前符号或页。
  - 速率限制：`429` 记录、退避并重试。
  - 服务器错误：`5xx` 退避重试。
  - 解析错误：输出原始响应片段用于诊断。
- 失败策略：可配置 `--fail-fast` 或 `--keep-going`（默认）。

# CLI
- Commands
  - `configure`：交互式写入 `~/.config/fmp_dl/.env`。
  - `get`：通用端点下载。
  - `quotes`：便捷获取 `v3/quote`（支持 `--symbols`）。
  - `historical`：`v3/historical-price-full`（`--from --to --serietype`）。
- Common Options
  - `--endpoint`, `--base v3|stable`, `--params k=v`*, `--symbols`, `--symbols-file`。
  - `--api-key`, `--max-per-min`, `--retries`, `--timeout`。
  - `--format`, `--outfile`, `--metadata`，`--fail-fast`。

# Configuration
- `~/.config/fmp_dl/.env` 示例：
  - `FMP_API_KEY=xxxxx`
  - `MAX_PER_MIN=30`

# Outputs
- 目录结构：
  - `./data/{endpoint}/run_{YYYYMMDD_HHMMSS}/part-*.jsonl|csv`
  - `./data/{endpoint}/run_.../metadata.json`

# Validation
- 验收用例：
  - `get --endpoint v3/quote --symbols AAPL,MSFT` 返回两条以上记录；无 4xx/5xx；元数据计数匹配。
  - `historical --symbols AAPL --from 2024-01-01 --to 2024-01-31` 返回区间数据；空响应时记录原因。
  - 触发 `429` 时不崩溃并成功恢复继续下载。

# Security
- 日志中遮蔽 `apikey`；元数据保留字段但进行红action。

# Open Questions
- 是否内置 Parquet 输出（需 `pyarrow`）？
- 预置端点是否增加财报类（`income-statement`, `balance-sheet-statement`）？
- 默认 `--max-per-min` 是否按你账号配额调整？

