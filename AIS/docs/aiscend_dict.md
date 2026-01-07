
## 目录
- [company_base](#company_base)
- [doc_info](#doc_info)
- [doc_text](#doc_text)
- [doc_json](#doc_json)
- [doc_paragraph](#doc_paragraph)
- [doc_embedding](#doc_embedding)
- [search_result](#search_result)
- [ticker_price](#ticker_price)
- [index_price](#index_price)
- [f_balance_sheet_statement_quarter](#f_balance_sheet_statement_quarter)
- [f_balance_sheet_statement_year](#f_balance_sheet_statement_year)
- [f_balance_sheet_statement_quarter_predict](#f_balance_sheet_statement_quarter_predict)
- [f_cash_flow_statement_quarter](#f_cash_flow_statement_quarter)
- [f_cash_flow_statement_year](#f_cash_flow_statement_year)
- [f_cash_flow_statement_quarter_predict](#f_cash_flow_statement_quarter_predict)
- [f_income_statement_quarter](#f_income_statement_quarter)
- [f_income_statement_year](#f_income_statement_year)
- [f_income_statement_quarter_predict](#f_income_statement_quarter_predict)
- [f_growth_income_statement_*](#f_growth_income_statement_)
- [f_growth_balance_sheet_statement_*](#f_growth_balance_sheet_statement_)
- [f_growth_cash_flow_statement_*](#f_growth_cash_flow_statement_)
- [f_financial_growth_*](#f_financial_growth_)
- [f_financial_ratios_*](#f_financial_ratios_)
- [f_financial_trends](#f_financial_trends)
- [f_key_metrics_*](#f_key_metrics_)
- [f_earning_calendar](#f_earning_calendar)
- [f_enterprise_values_*](#f_enterprise_values_)
- [f_percentile](#f_percentile)
- [f_percentile1](#f_percentile1)
- [f_valuation_financial_quarter](#f_valuation_financial_quarter)
- [f_valuation_multiple](#f_valuation_multiple)
- [f_valuation_versions](#f_valuation_versions)
- [portfolio_entity](#portfolio_entity)
- [segment_entity](#segment_entity)
- [mv_info_growth](#mv_info_growth)
- [mv_info_growth_test](#mv_info_growth_test)
- [mv_info_quality](#mv_info_quality)
- [mv_info_technical](#mv_info_technical)

## 公司基础信息表

### `company_base`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 表主键，自增 ID，用于唯一标识公司记录。 |
| cik | text | 是 | 美国 SEC 中央索引键（CIK），用于对应 SEC 披露主体。 |
| ticker | text | 是 | 公司在交易所的股票代码，兼作跨表关联主键。 |
| exchange_short_name | text | 是 | 交易所简称，例如 NASDAQ、NYSE，用于识别上市市场。 |
| company_name | text | 是 | 公司法定名称或常用英文名。 |
| mkt_cap | bigint | 是 | 市值（本币），通常来自最新行情或批量更新。 |
| currency | text | 是 | 财务数据主币种，例如 USD、CNY，用于换算。 |
| industry | text | 是 | 行业分类（FMP/内部映射），用于行业分析。 |
| website | text | 是 | 公司官网地址。 |
| description | text | 是 | 公司业务简介，方便快速了解主营业务。 |
| ceo | text | 是 | 首席执行官姓名。 |
| sector | text | 是 | 更高一级的行业部门分类，例如 Technology。 |
| country | text | 是 | 公司注册地或运营主体所在国家。 |
| full_time_employees | text | 是 | 全职员工数量描述（原始文本）。 |
| phone | text | 是 | 公司官方联系电话。 |
| address | text | 是 | 公司注册地址。 |
| city | text | 是 | 注册城市。 |
| state | text | 是 | 注册州/省。 |
| zip | text | 是 | 邮政编码。 |
| is_adr | boolean | 是 | 是否为美国存托凭证（ADR）。 |
| interest | boolean | 是 | 标记是否为重点跟踪公司，用于内部筛选。 |
| download | boolean | 是 | 是否允许被批量下载/处理，配合任务管理。 |
| create_date | timestamp without time zone | 是 | 记录创建时间。 |
| is_etf | boolean | 是 | 是否为 ETF 产品，默认 false。 |
| is_fund | boolean | 是 | 是否为基金产品，默认 false。 |
| currency_convert_usd | real | 是 | 货币对 USD 的换算比例，用于统一度量。 |
| mkt_cap_usd | bigint | 是 | 市值折算为美元的数值，便于跨市场比较。 |
| price | real | 是 | 最新股价（本币）。 |
| vol_avg | bigint | 是 | 平均成交量（通常按 3 个月或 10 日平均）。 |
| amount_avg | bigint | 是 | 平均成交额（本币）。 |
| amount_avg_usd | bigint | 是 | 平均成交额换算美元。 |
| is_filtered | boolean | 是 | 是否通过内部质量筛选；false 表示未筛选或不满足。 |
| report_frequency | character | 是 | 报表发布频率标记：Y 年报、Q 季报等。 |
| updated_at | timestamp without time zone | 是 | 最近一次同步时间，用于增量刷新。 |

## 文档元数据与全文表

### `doc_info`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 表主键，自增 ID。 |
| content_type | text | 是 | 原始文件的内容类型，例如 transcript、press release。 |
| original_ticker | text | 是 | 文档源头标注的股票代码，用于初始匹配。 |
| original_company_name | text | 是 | 文档源头显示的公司名称。 |
| country | text | 是 | 文档关联的国家/地区。 |
| title | text | 是 | 文档标题。 |
| year | text | 是 | 文档对应年份（字符串存储以兼容特殊值）。 |
| quarter | text | 是 | 文档对应季度（如 Q1、FY）。 |
| author | text | 是 | 文档作者或发布主体。 |
| transcript_type | text | 是 | 会议纪要类型，如 earnings_call、investor_day。 |
| data_url | text | 是 | 原始数据下载地址。 |
| author_url | text | 是 | 作者主页或来源链接。 |
| publish_time | timestamp with time zone | 是 | 文档外部发布时间。 |
| run_time | timestamp with time zone | 是 | 内部抓取或处理时间。 |
| content_time | timestamp with time zone | 是 | 文档内容发生时间（如会议召开时间）。 |
| topic | text | 是 | 文档主题标签。 |
| company_url | text | 是 | 公司相关页面链接。 |
| summary | text | 是 | 文档摘要（中文或英文）。 |
| text_len | integer | 是 | 正文字符长度，默认 -1 表示未计算。 |
| ticker | text | 是 | 内部统一的股票代码，经过映射校准。 |
| company_name | text | 是 | 内部统一的公司名称。 |
| file_path | text | 是 | 第一份原文文件存储路径。 |
| file_path1 | text | 是 | 附加文件路径 1。 |
| file_path2 | text | 是 | 附加文件路径 2。 |
| file_path3 | text | 是 | 附加文件路径 3。 |
| file_path4 | text | 是 | 附加文件路径 4。 |
| file_path5 | text | 是 | 附加文件路径 5。 |
| file_path6 | text | 是 | 附加文件路径 6。 |
| file_num | integer | 是 | 文件数量计数，默认 0。 |
| suggestion | text | 是 | 对文档处理的建议或人工备注。 |
| doc_type | text | 是 | 文档类型标签（如 sec_filing、earnings_call_transcript）。 |

### `doc_text`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 表主键。 |
| doc_id | bigint | 是 | 对应 `doc_info.id`，标记文档来源。 |
| doc_type | text | 是 | 文档类型，与 `doc_info.doc_type` 对齐。 |
| content_type | text | 是 | 内容类别（正文、问答等）。 |
| ticker | text | 是 | 统一股票代码。 |
| publish_time | timestamp with time zone | 是 | 文档发布时间。 |
| year_quarter | text | 是 | 年季度组合（例如 2024Q1）。 |
| author | text | 是 | 文档作者。 |
| paragraph_num | integer | 是 | 段落编号或顺序。 |
| doc_text | text | 是 | 文档原文内容（按段落或全文存储）。 |
| run_time | timestamp with time zone | 是 | 解析入库时间。 |
| file_idx | integer | 是 | 文件序号，用于定位原文件片段。 |
| company_name | text | 是 | 统一公司名称。 |
| analysis_time | timestamp with time zone | 是 | 后续算法分析时间。 |
| process_flag | integer | 否 | 处理状态标记：0 未处理，1 已处理等。 |

### `doc_json`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 表主键。 |
| file_idx | integer | 是 | 文件序号，默认 0。 |
| doc_type | text | 是 | 文档类型。 |
| content_type | text | 是 | 内容类别。 |
| ticker | text | 是 | 统一股票代码。 |
| title | text | 是 | 文档标题。 |
| report | text | 是 | 结构化后的 JSON 串（字符串形式存储）。 |
| year_quarter | text | 是 | 年季度标识。 |
| author | text | 是 | 作者或发布主体。 |
| publish_time | text | 是 | 原始发布时间（字符串，兼容不同格式）。 |
| run_time | timestamp with time zone | 是 | 解析入库时间。 |
| company_name | character varying | 是 | 公司名称。 |
| doc_ids | text | 是 | 关联的 `doc_info` ID 列表。 |
| value_score | double precision | 是 | 文档自动打分（如价值评级）。 |
| run_time_ori | timestamp with time zone | 是 | 原始抓取时间。 |
| version | text | 是 | 文档解析版本号。 |
| gemini_embedding | USER-DEFINED | 是 | 文本向量（pgvector 类型），用于语义检索。 |
| prompt_tokens | integer | 是 | 生成摘要时消耗的 token 数。 |
| segment_flag | integer | 是 | 分段标记，0 表示未分段。 |
| time_end | timestamp with time zone | 是 | 文档内容结束时间。 |

### `doc_paragraph`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 主键，自增 ID。 |
| doc_id | bigint | 是 | 对应 `doc_info.id`，表明段落所属文档。 |
| doc_type | text | 是 | 文档类型，与 `doc_info.doc_type` 同步。 |
| content_type | text | 是 | 内容类别（正文、问答、附录等）。 |
| ticker | text | 是 | 统一股票代码。 |
| publish_time | timestamp with time zone | 是 | 文档发布时间。 |
| year_quarter | text | 是 | 年度+季度标识（如 2024Q1）。 |
| author | text | 是 | 段落作者或讲话人。 |
| paragraph_title | text | 是 | 段落标题（若存在）。 |
| paragraph_idx | integer | 是 | 段落顺序编号，从 0/1 开始。 |
| paragraph_offset | integer | 是 | 段落在全文中的字符偏移。 |
| paragraph_len | integer | 是 | 段落字符长度。 |
| paragraph_text | text | 是 | 段落原文内容。 |
| run_time | timestamp with time zone | 是 | 入库时间。 |
| embedding_chunk_num | integer | 是 | 该段被切分出的向量块数量，默认 -1 表示未生成。 |
| drop_chunk_num | integer | 是 | 被丢弃的向量块数量，默认 -1 表示未统计。 |
| file_idx | integer | 是 | 原始文件索引，默认 0。 |
| company_name | text | 是 | 统一公司名称。 |

### `doc_embedding`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 主键，自增 ID。 |
| doc_paragraph_id | bigint | 是 | 关联 `doc_paragraph.id`，指向来源段落。 |
| doc_id | bigint | 是 | 文档主键。 |
| doc_type | text | 是 | 文档类型。 |
| content_type | text | 是 | 内容类别。 |
| ticker | text | 是 | 股票代码。 |
| publish_time | timestamp with time zone | 是 | 段落发布时间。 |
| year_quarter | text | 是 | 报告期。 |
| author | text | 是 | 段落作者或讲话人。 |
| paragraph_idx | integer | 是 | 段落编号。 |
| paragraph_offset | integer | 是 | 段落在全文中的偏移。 |
| paragraph_len | integer | 是 | 段落字符长度。 |
| paragraph_title | text | 是 | 段落标题。 |
| chunk_idx | integer | 是 | 嵌入切分块编号。 |
| chunk_type | text | 是 | 切分类型（例如 sentence、summary）。 |
| chunk_text | text | 是 | 切分后的文本内容。 |
| chunk_offset | integer | 是 | 切分块在段落中的字符偏移。 |
| chunk_len | integer | 是 | 切分块长度。 |
| chunk_sentence_num | integer | 是 | 切分块包含的句子数量。 |
| chunk_token | integer | 是 | 切分块 token 数，用于控制模型调用长度。 |
| voyage_embedding | USER-DEFINED | 是 | Voyage 模型生成的向量表示。 |
| gemini_embedding | USER-DEFINED | 是 | Gemini 模型生成的向量表示。 |
| text_search_tsv | tsvector | 是 | PG 全文检索向量，用于混合查询。 |
| run_time | timestamp with time zone | 是 | 嵌入入库时间。 |
| file_idx | integer | 是 | 原始文件索引，默认为 0。 |
| company_name | text | 是 | 公司名称。 |

### `search_result`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 是 | 主键，向量检索结果 ID。 |
| ticker | text | 是 | 关联股票代码。 |
| type | text | 是 | 结果类型（如 document、segment、portfolio）。 |
| name | text | 是 | 结果展示名称。 |
| query | text | 是 | 触发该结果的原始查询。 |
| gemini_embedding | USER-DEFINED | 是 | 查询或结果的向量表示，用于缓存相似度。 |

## 行情价格表

### `ticker_price`
`ticker_price` 为分区表，按年份拆分存储历史行情。字段定义对主表与子分区通用。

| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 主键，自增 ID。 |
| ticker | text | 否 | 股票代码。 |
| date | date | 否 | 交易日期。 |
| open | real | 是 | 当日开盘价（本币）。 |
| low | real | 是 | 当日最低价。 |
| high | real | 是 | 当日最高价。 |
| close | real | 是 | 收盘价。 |
| adj_close | real | 是 | 前复权收盘价。 |
| volume | bigint | 是 | 成交量。 |
| currency | text | 是 | 行情币种。 |
| currency_convert_usd | real | 是 | 折算美元的汇率。 |
| share_num | bigint | 是 | 自由流通股数（若可得）。 |
| amount | real | 是 | 成交额（本币）。 |
| amount_usd | real | 是 | 成交额（美元）。 |
| close_usd | real | 是 | 收盘价折算美元。 |
| created_at | timestamp with time zone | 是 | 入库时间。 |
| updated_at | timestamp with time zone | 是 | 最近更新时间。 |

### `index_price`
`index_price` 为指数行情分区表，按年份拆分存储各类市场指数（如标普500、纳指、沪深300等）的日频价格。字段设计与 `ticker_price` 基本一致，但以 `index_code` 作为主关联键，适用于无个股层级属性的指数类资产。

| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 主键，自增 ID。 |
| index_code | text | 否 | 指数代码（如 ^GSPC、NDX、IXIC、000300.SH）。 |
| index_name | text | 是 | 指数名称（如 S&P 500、NASDAQ 100、沪深300）。 |
| date | date | 否 | 交易日期。 |
| open | real | 是 | 当日开盘价（本币）。 |
| low | real | 是 | 当日最低价。 |
| high | real | 是 | 当日最高价。 |
| close | real | 是 | 收盘价。 |
| adj_close | real | 是 | 复权收盘价/等效调整价（若来源支持，否则可为空）。 |
| volume | bigint | 是 | 成交量（多数指数无此字段，可缺省为 0 或 NULL）。 |
| currency | text | 是 | 行情币种。 |
| currency_convert_usd | real | 是 | 折算美元的汇率。 |
| close_usd | real | 是 | 收盘价折算美元，用于跨市场比较。 |
| created_at | timestamp with time zone | 是 | 入库时间。 |
| updated_at | timestamp with time zone | 是 | 最近更新时间。 |

## 财务报表明细表（f_* 系列）

此系列表主要承载 FMP/自研的财务报表与衍生指标。按季度、年度以及预测版本分类。

> 说明：所有名称包含 `_predict` 的表均为对应原始表基于 TimesFM 模型生成的未来预测数据，字段结构与实际值保持一致，仅数值来源于预测结果。

### `f_balance_sheet_statement_quarter`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键，自增 ID。 |
| ticker | text | 否 | 股票代码。 |
| run_time | timestamp without time zone | 是 | 数据写入时间，默认当前时间。 |
| date | timestamp without time zone | 是 | 报表对应日期（季度末）。 |
| symbol | text | 是 | 股票代码（冗余自 FMP 原文）。 |
| reportedCurrency | text | 是 | 报表币种。 |
| cik | text | 是 | SEC CIK。 |
| fillingDate | timestamp without time zone | 是 | 向监管披露的提交日期。 |
| acceptedDate | timestamp without time zone | 是 | SEC 接受日期。 |
| calendarYear | text | 是 | 日历年（字符串存储）。 |
| period | text | 是 | 报告期标识：FY、Q1 等。 |
| cashAndCashEquivalents | bigint | 是 | 现金及现金等价物。 |
| shortTermInvestments | bigint | 是 | 短期投资。 |
| cashAndShortTermInvestments | bigint | 是 | 现金与短期投资合计。 |
| netReceivables | bigint | 是 | 应收账款净额。 |
| inventory | bigint | 是 | 存货。 |
| otherCurrentAssets | bigint | 是 | 其他流动资产。 |
| totalCurrentAssets | bigint | 是 | 流动资产合计。 |
| propertyPlantEquipmentNet | bigint | 是 | 固定资产净额。 |
| goodwill | bigint | 是 | 商誉。 |
| intangibleAssets | bigint | 是 | 无形资产。 |
| goodwillAndIntangibleAssets | bigint | 是 | 商誉及无形资产合计。 |
| longTermInvestments | bigint | 是 | 长期投资。 |
| taxAssets | bigint | 是 | 递延所得税资产等税务资产。 |
| otherNonCurrentAssets | bigint | 是 | 其他非流动资产。 |
| totalNonCurrentAssets | bigint | 是 | 非流动资产合计。 |
| otherAssets | bigint | 是 | 其他资产。 |
| totalAssets | bigint | 是 | 资产总计。 |
| accountPayables | bigint | 是 | 应付账款。 |
| shortTermDebt | bigint | 是 | 短期债务。 |
| taxPayables | bigint | 是 | 应交税费。 |
| deferredRevenue | bigint | 是 | 递延收入（短期）。 |
| otherCurrentLiabilities | bigint | 是 | 其他流动负债。 |
| totalCurrentLiabilities | bigint | 是 | 流动负债合计。 |
| longTermDebt | bigint | 是 | 长期债务。 |
| deferredRevenueNonCurrent | bigint | 是 | 递延收入（长期）。 |
| deferredTaxLiabilitiesNonCurrent | bigint | 是 | 递延所得税负债。 |
| otherNonCurrentLiabilities | bigint | 是 | 其他非流动负债。 |
| totalNonCurrentLiabilities | bigint | 是 | 非流动负债合计。 |
| otherLiabilities | bigint | 是 | 其他负债。 |
| capitalLeaseObligations | bigint | 是 | 融资租赁义务。 |
| totalLiabilities | bigint | 是 | 负债合计。 |
| preferredStock | bigint | 是 | 优先股账面价值。 |
| commonStock | bigint | 是 | 普通股账面价值。 |
| retainedEarnings | bigint | 是 | 留存收益。 |
| accumulatedOtherComprehensiveIncomeLoss | bigint | 是 | 其他综合收益累积额。 |
| othertotalStockholdersEquity | bigint | 是 | 其他股东权益项目。 |
| totalStockholdersEquity | bigint | 是 | 股东权益合计。 |
| totalEquity | bigint | 是 | 权益总计。 |
| totalLiabilitiesAndStockholdersEquity | bigint | 是 | 负债及股东权益总计。 |
| minorityInterest | bigint | 是 | 少数股东权益。 |
| totalLiabilitiesAndTotalEquity | bigint | 是 | 负债加权益总计（冗余字段）。 |
| totalInvestments | bigint | 是 | 投资资产合计。 |
| totalDebt | bigint | 是 | 总债务（短+长期）。 |
| netDebt | bigint | 是 | 净债务（总债务-现金）。 |
| link | text | 是 | FMP 原始链接。 |
| finalLink | text | 是 | FMP 最终报表下载链接。 |
| finallink | character varying | 是 | 同 finalLink，大小写变体兼容。 |

### `f_balance_sheet_statement_year`
结构与季度表一致，`date` 为年度报表日期，用于年报数据存档。

### `f_balance_sheet_statement_quarter_predict`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键。 |
| ticker | character varying | 否 | 股票代码。 |
| prediction_date | timestamp without time zone | 是 | 预测生成日期。 |
| fiscal_year | integer | 否 | 预测所属财年。 |
| fiscal_quarter | integer | 否 | 预测所属季度（1-4）。 |
| quarter_end_date | timestamp without time zone | 是 | 预测假设的季度截止日。 |
| cashAndCashEquivalents | bigint | 是 | 预测期末现金及现金等价物，含义同实际表。 |
| shortTermInvestments | bigint | 是 | 预测短期投资。 |
| cashAndShortTermInvestments | bigint | 是 | 预测现金与短期投资合计。 |
| netReceivables | bigint | 是 | 预测应收账款净额。 |
| inventory | bigint | 是 | 预测存货。 |
| otherCurrentAssets | bigint | 是 | 预测其他流动资产。 |
| totalCurrentAssets | bigint | 是 | 预测流动资产合计。 |
| propertyPlantEquipmentNet | bigint | 是 | 预测固定资产净额。 |
| goodwill | bigint | 是 | 预测商誉。 |
| intangibleAssets | bigint | 是 | 预测无形资产。 |
| goodwillAndIntangibleAssets | bigint | 是 | 预测商誉及无形资产合计。 |
| longTermInvestments | bigint | 是 | 预测长期投资。 |
| taxAssets | bigint | 是 | 预测税务资产。 |
| otherNonCurrentAssets | bigint | 是 | 预测其他非流动资产。 |
| totalNonCurrentAssets | bigint | 是 | 预测非流动资产合计。 |
| otherAssets | bigint | 是 | 预测其他资产。 |
| totalAssets | bigint | 是 | 预测资产总计。 |
| accountPayables | bigint | 是 | 预测应付账款。 |
| shortTermDebt | bigint | 是 | 预测短期债务。 |
| taxPayables | bigint | 是 | 预测应交税费。 |
| deferredRevenue | bigint | 是 | 预测递延收入（短期）。 |
| otherCurrentLiabilities | bigint | 是 | 预测其他流动负债。 |
| totalCurrentLiabilities | bigint | 是 | 预测流动负债合计。 |
| longTermDebt | bigint | 是 | 预测长期债务。 |
| deferredRevenueNonCurrent | bigint | 是 | 预测递延收入（长期）。 |
| deferredTaxLiabilitiesNonCurrent | bigint | 是 | 预测递延所得税负债。 |
| otherNonCurrentLiabilities | bigint | 是 | 预测其他非流动负债。 |
| totalNonCurrentLiabilities | bigint | 是 | 预测非流动负债合计。 |
| otherLiabilities | bigint | 是 | 预测其他负债。 |
| capitalLeaseObligations | bigint | 是 | 预测融资租赁义务。 |
| totalLiabilities | bigint | 是 | 预测负债合计。 |
| preferredStock | bigint | 是 | 预测优先股账面价值。 |
| commonStock | bigint | 是 | 预测普通股账面价值。 |
| retainedEarnings | bigint | 是 | 预测留存收益。 |
| accumulatedOtherComprehensiveIncomeLoss | bigint | 是 | 预测其他综合收益。 |
| othertotalStockholdersEquity | bigint | 是 | 预测其他股东权益项目。 |
| totalStockholdersEquity | bigint | 是 | 预测股东权益合计。 |
| totalEquity | bigint | 是 | 预测权益总计。 |
| totalLiabilitiesAndStockholdersEquity | bigint | 是 | 预测负债及股东权益总计。 |
| minorityInterest | bigint | 是 | 预测少数股东权益。 |
| totalLiabilitiesAndTotalEquity | bigint | 是 | 预测负债加权益总计。 |
| totalInvestments | bigint | 是 | 预测投资资产合计。 |
| totalDebt | bigint | 是 | 预测总债务。 |
| netDebt | bigint | 是 | 预测净债务。 |
| link | text | 是 | 预测数据来源链接。 |
| finalLink | text | 是 | 预测数据最终链接。 |
| finallink | character varying | 是 | 链接兼容字段。 |

### `f_cash_flow_statement_quarter`
现金流量表季度版，字段涵盖经营、投资、筹资现金流以及辅助指标。

| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键。 |
| ticker | text | 否 | 股票代码。 |
| run_time | timestamp without time zone | 是 | 写入时间。 |
| date | timestamp without time zone | 是 | 报表日期。 |
| symbol | text | 是 | 股票代码（冗余）。 |
| reportedCurrency | text | 是 | 报表币种。 |
| cik | text | 是 | SEC CIK。 |
| fillingDate | timestamp without time zone | 是 | 提交日期。 |
| acceptedDate | timestamp without time zone | 是 | 接受日期。 |
| calendarYear | text | 是 | 日历年。 |
| period | text | 是 | 报告期。 |
| netIncome | bigint | 是 | 净利润。 |
| depreciationAndAmortization | bigint | 是 | 折旧与摊销。 |
| deferredIncomeTax | bigint | 是 | 递延所得税对现金流的影响。 |
| stockBasedCompensation | bigint | 是 | 股权激励费用。 |
| changeInWorkingCapital | bigint | 是 | 营运资本变动。 |
| accountsReceivables | bigint | 是 | 应收账款变动。 |
| inventory | bigint | 是 | 存货变动。 |
| accountsPayables | bigint | 是 | 应付账款变动。 |
| otherWorkingCapital | bigint | 是 | 其他营运资本变动。 |
| otherNonCashItems | bigint | 是 | 其他非现金项目。 |
| netCashProvidedByOperatingActivities | bigint | 是 | 经营活动现金流净额。 |
| investmentsInPropertyPlantAndEquipment | bigint | 是 | 资本支出。 |
| acquisitionsNet | bigint | 是 | 并购净支出。 |
| purchasesOfInvestments | bigint | 是 | 投资支付现金。 |
| salesMaturitiesOfInvestments | bigint | 是 | 投资回收现金。 |
| otherInvestingActivites | bigint | 是 | 其他投资活动。 |
| netCashUsedForInvestingActivites | bigint | 是 | 投资活动现金流净额。 |
| debtRepayment | bigint | 是 | 偿还债务。 |
| commonStockIssued | bigint | 是 | 发行普通股获得现金。 |
| commonStockRepurchased | bigint | 是 | 回购股份支出。 |
| dividendsPaid | bigint | 是 | 支付股息。 |
| otherFinancingActivites | bigint | 是 | 其他筹资活动。 |
| netCashUsedProvidedByFinancingActivities | bigint | 是 | 筹资活动现金流净额。 |
| effectOfForexChangesOnCash | bigint | 是 | 汇率变动影响。 |
| netChangeInCash | bigint | 是 | 现金及等价物净变动。 |
| cashAtEndOfPeriod | bigint | 是 | 期末现金。 |
| cashAtBeginningOfPeriod | bigint | 是 | 期初现金。 |
| operatingCashFlow | bigint | 是 | 经营现金流。 |
| capitalExpenditure | bigint | 是 | 资本支出（冗余）。 |
| freeCashFlow | bigint | 是 | 自由现金流。 |
| link | text | 是 | FMP 链接。 |
| finalLink | text | 是 | FMP 最终链接。 |
| finallink | character varying | 是 | 链接兼容字段。 |

### `f_cash_flow_statement_year`
与季度表结构相同，数据为年报口径。

### `f_cash_flow_statement_quarter_predict`
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键。 |
| ticker | character varying | 否 | 股票代码。 |
| prediction_date | timestamp without time zone | 是 | 预测生成时间。 |
| fiscal_year | integer | 否 | 预测财年。 |
| fiscal_quarter | integer | 否 | 预测季度。 |
| quarter_end_date | timestamp without time zone | 是 | 预测季度截止日。 |
| netIncome | bigint | 是 | 预测净利润。 |
| depreciationAndAmortization | bigint | 是 | 预测折旧与摊销。 |
| deferredIncomeTax | bigint | 是 | 预测递延所得税影响。 |
| stockBasedCompensation | bigint | 是 | 预测股权激励费用。 |
| changeInWorkingCapital | bigint | 是 | 预测营运资本变动。 |
| accountsReceivables | bigint | 是 | 预测应收账款变动。 |
| inventory | bigint | 是 | 预测存货变动。 |
| accountsPayables | bigint | 是 | 预测应付账款变动。 |
| otherWorkingCapital | bigint | 是 | 预测其他营运资本变动。 |
| otherNonCashItems | bigint | 是 | 预测其他非现金项目。 |
| netCashProvidedByOperatingActivities | bigint | 是 | 预测经营活动现金流。 |
| investmentsInPropertyPlantAndEquipment | bigint | 是 | 预测资本支出。 |
| acquisitionsNet | bigint | 是 | 预测并购净支出。 |
| purchasesOfInvestments | bigint | 是 | 预测投资支付。 |
| salesMaturitiesOfInvestments | bigint | 是 | 预测投资回收。 |
| otherInvestingActivites | bigint | 是 | 预测其他投资活动现金流。 |
| netCashUsedForInvestingActivites | bigint | 是 | 预测投资活动现金流净额。 |
| debtRepayment | bigint | 是 | 预测偿还债务。 |
| commonStockIssued | bigint | 是 | 预测发行普通股现金流。 |
| commonStockRepurchased | bigint | 是 | 预测回购股份支出。 |
| dividendsPaid | bigint | 是 | 预测股息支出。 |
| otherFinancingActivites | bigint | 是 | 预测其他筹资活动现金流。 |
| netCashUsedProvidedByFinancingActivities | bigint | 是 | 预测筹资活动现金流净额。 |
| effectOfForexChangesOnCash | bigint | 是 | 预测汇率变动影响。 |
| netChangeInCash | bigint | 是 | 预测现金净变动。 |
| cashAtEndOfPeriod | bigint | 是 | 预测期末现金。 |
| cashAtBeginningOfPeriod | bigint | 是 | 预测期初现金。 |
| operatingCashFlow | bigint | 是 | 预测经营现金流。 |
| capitalExpenditure | bigint | 是 | 预测资本支出（冗余）。 |
| freeCashFlow | bigint | 是 | 预测自由现金流。 |
| link | text | 是 | 预测数据来源链接。 |
| finalLink | text | 是 | 预测数据最终链接。 |
| finallink | character varying | 是 | 链接兼容字段。 |

### `f_income_statement_quarter`
利润表季度版，关键字段如下：

| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键。 |
| ticker | text | 否 | 股票代码。 |
| run_time | timestamp without time zone | 是 | 写入时间。 |
| date | timestamp without time zone | 是 | 报告期结束日。 |
| symbol | text | 是 | 股票代码。 |
| reportedCurrency | text | 是 | 报表币种。 |
| cik | text | 是 | SEC CIK。 |
| fillingDate | timestamp without time zone | 是 | 提交日期。 |
| acceptedDate | timestamp without time zone | 是 | 接受日期。 |
| calendarYear | text | 是 | 日历年。 |
| period | text | 是 | 报告期标识。 |
| revenue | bigint | 是 | 营业收入。 |
| costOfRevenue | bigint | 是 | 营业成本。 |
| grossProfit | bigint | 是 | 毛利润。 |
| grossProfitRatio | numeric | 是 | 毛利率。 |
| researchAndDevelopmentExpenses | bigint | 是 | 研发费用。 |
| generalAndAdministrativeExpenses | bigint | 是 | 管理费用。 |
| sellingGeneralAndAdministrativeExpenses | bigint | 是 | 销售及管理费用。 |
| sellingAndMarketingExpenses | bigint | 是 | 销售营销费用。 |
| otherExpenses | bigint | 是 | 其他综合费用。 |
| operatingExpenses | bigint | 是 | 营业费用合计。 |
| costAndExpenses | bigint | 是 | 成本及费用总计。 |
| interestExpense | bigint | 是 | 利息支出。 |
| depreciationAndAmortization | bigint | 是 | 折旧摊销。 |
| ebitda | bigint | 是 | EBITDA。 |
| ebitdaratio | numeric | 是 | EBITDA 利润率。 |
| operatingIncome | bigint | 是 | 营业利润。 |
| operatingIncomeRatio | numeric | 是 | 营业利润率。 |
| totalOtherIncomeExpensesNet | bigint | 是 | 其他收益/损失净额。 |
| incomeBeforeTax | bigint | 是 | 税前利润。 |
| incomeBeforeTaxRatio | numeric | 是 | 税前利润率。 |
| incomeTaxExpense | bigint | 是 | 所得税费用。 |
| netIncome | bigint | 是 | 净利润。 |
| netIncomeRatio | numeric | 是 | 净利率。 |
| eps | numeric | 是 | 每股收益（基础）。 |
| epsdiluted | numeric | 是 | 稀释每股收益。 |
| weightedAverageShsOut | bigint | 是 | 加权平均流通股数。 |
| weightedAverageShsOutDil | bigint | 是 | 稀释加权平均股数。 |
| link | text | 是 | FMP 链接。 |
| finalLink | text | 是 | 最终链接。 |
| finallink | character varying | 是 | 链接兼容字段。 |

### 其他 `f_income_statement_*`
- `f_income_statement_year`：字段同上，存储年度数据。
- `f_income_statement_quarter_predict`：新增 `prediction_date`、`fiscal_year`、`fiscal_quarter`、`quarter_end_date`，其余字段同利润表实际项，表示预测值。

<a id="f_growth_income_statement_"></a>
### `f_growth_income_statement_*`
用于存储利润表增长率。字段与 `f_income_statement_*` 对应指标相呼应：

公共字段：`id`（自增）、`ticker`、`run_time`、`date`/`prediction_date`、`calendarYear`、`period` 等。

核心字段释义如下：

| 字段名 | 含义 |
| --- | --- |
| `revenueGrowth` | 营业收入同比增长率。 |
| `grossProfitGrowth` | 毛利润同比增长率。 |
| `ebitgrowth` | EBIT 同比增长率。 |
| `operatingIncomeGrowth` | 营业利润同比增长率。 |
| `netIncomeGrowth` | 净利润同比增长率。 |
| `epsgrowth` | 基础每股收益同比增长率。 |
| `epsdilutedGrowth` | 稀释每股收益同比增长率。 |
| `weightedAverageSharesGrowth` | 加权平均流通股数同比变化。 |
| `weightedAverageSharesDilutedGrowth` | 稀释股数同比变化。 |
| `dividendsperShareGrowth` | 每股股息同比增长率。 |
| `operatingCashFlowGrowth` | 经营现金流同比增长率。 |
| `freeCashFlowGrowth` | 自由现金流同比增长率。 |
| `tenYRevenueGrowthPerShare` / `fiveYRevenueGrowthPerShare` / `threeYRevenueGrowthPerShare` | 过去 10/5/3 年每股收入复合增长率。 |
| `tenYOperatingCFGrowthPerShare` / `fiveYOperatingCFGrowthPerShare` / `threeYOperatingCFGrowthPerShare` | 过去 10/5/3 年每股经营现金流复合增长率。 |
| `tenYNetIncomeGrowthPerShare` / `fiveYNetIncomeGrowthPerShare` / `threeYNetIncomeGrowthPerShare` | 过去 10/5/3 年每股净利润复合增长率。 |
| `tenYShareholdersEquityGrowthPerShare` / `fiveYShareholdersEquityGrowthPerShare` / `threeYShareholdersEquityGrowthPerShare` | 过去 10/5/3 年每股股东权益复合增长率。 |
| `tenYDividendperShareGrowthPerShare` / `fiveYDividendperShareGrowthPerShare` / `threeYDividendperShareGrowthPerShare` | 过去 10/5/3 年每股股息复合增长率。 |
| `receivablesGrowth` | 应收账款增长率。 |
| `inventoryGrowth` | 存货增长率。 |
| `assetGrowth` | 资产总额增长率。 |
| `bookValueperShareGrowth` | 每股账面价值增长率。 |
| `debtGrowth` | 总债务增长率。 |
| `rdexpenseGrowth` | 研发费用增长率。 |
| `sgaexpensesGrowth` | 销管费用增长率。 |

说明：
- `_quarter` 与 `_year` 表区分季度/年度数据。
- `_quarter_predict` 版本包含上述字段的预测值，并追加 `prediction_date`、`fiscal_year`、`fiscal_quarter`、`quarter_end_date`。

<a id="f_growth_balance_sheet_statement_"></a>
### `f_growth_balance_sheet_statement_*`
衡量资产负债表关键项目的同比变化。

共性字段与原始资产负债表一致，核心增长指标包括：
- `cashAndCashEquivalentsGrowth`
- `shortTermInvestmentsGrowth`
- `netReceivablesGrowth`
- `inventoryGrowth`
- `totalCurrentAssetsGrowth`
- `totalAssetsGrowth`
- `totalLiabilitiesGrowth`
- `totalStockholdersEquityGrowth`
- `totalDebtGrowth`
- `netDebtGrowth`

解释：每个字段表示环比或同比增长率，用于评估资产与负债结构变化趋势。`_predict` 版本同样包含 `prediction_date`、`fiscal_year`、`fiscal_quarter`。

<a id="f_growth_cash_flow_statement_"></a>
### `f_growth_cash_flow_statement_*`
衡量现金流项目的同比变化，字段与现金流量表对应，例如：
- `netIncomeGrowth`
- `operatingCashFlowGrowth`
- `freeCashFlowGrowth`
- `capitalExpenditureGrowth`
- `netCashProvidedByOperatingActivitiesGrowth`
- `netCashUsedForInvestingActivitesGrowth`
- `netCashUsedProvidedByFinancingActivitiesGrowth`

同样分季度、年度与预测版本。

<a id="f_financial_ratios_"></a>
### `f_financial_ratios_*`
包含常用财务比率：
- 流动性：`currentratio`, `quickratio`, `cashratio`。
- 营运效率：`daysofsalesoutstanding`, `daysofinventoryoutstanding`, `inventoryturnover`, `assetturnover` 等。
- 盈利能力：`grossprofitmargin`, `operatingprofitmargin`, `netprofitmargin`, `returnonassets`, `returnonequity`, `returnoncapitalemployed`。
- 资本结构：`debtratio`, `debtequityratio`, `longtermdebttocapitalization`, `totaldebttocapitalization`。
- 现金流比率：`operatingcashflowpershare`, `freecashflowpershare`, `cashflowcoverageratios` 等。
- 估值倍数：`pricebookvalueratio`, `pricetosalesratio`, `priceearningsratio`, `enterprisevaluemultiple`。
- 股息指标：`dividendyield`, `dividendpayoutratio`。

核心指标释义如下（季度/年度/预测表字段一致，预测版为模型估计值）：

| 字段名 | 数据类型 | 含义 |
| --- | --- | --- |
| currentRatio | numeric | 流动资产 / 流动负债，衡量短期偿债能力。 |
| quickRatio | numeric | (流动资产-存货) / 流动负债，反映速动偿债能力。 |
| cashRatio | numeric | 现金及等价物 / 流动负债，检验极端情况下偿债能力。 |
| daysOfSalesOutstanding | numeric | 应收账款回收天数，越低表示回款效率高。 |
| daysOfInventoryOutstanding | numeric | 存货周转天数。 |
| operatingCycle | numeric | 经营周期 = 应收周转天数 + 存货周转天数。 |
| daysOfPayablesOutstanding | numeric | 应付账款周转天数。 |
| cashConversionCycle | numeric | 现金转换周期 = 经营周期 - 应付周转天数。 |
| grossProfitMargin | numeric | 毛利润 / 收入。 |
| operatingProfitMargin | numeric | 营业利润 / 收入。 |
| pretaxProfitMargin | numeric | 税前利润 / 收入。 |
| netProfitMargin | numeric | 净利润 / 收入。 |
| effectiveTaxRate | numeric | 所得税费用 / 税前利润。 |
| returnOnAssets | numeric | 净利润 / 总资产。 |
| returnOnEquity | numeric | 净利润 / 股东权益。 |
| returnOnCapitalEmployed | numeric | EBIT / (总资产-流动负债)。 |
| netIncomePerEBT | numeric | 净利润 / 税前利润，衡量税后留存比例。 |
| ebtPerEbit | numeric | 税前利润 / EBIT，反映利息负担。 |
| ebitPerRevenue | numeric | EBIT / 收入。 |
| debtRatio | numeric | 总负债 / 总资产。 |
| debtEquityRatio | numeric | 总负债 / 股东权益。 |
| longTermDebtToCapitalization | numeric | 长期债务 / (长期债务+股权)。 |
| totalDebtToCapitalization | numeric | 总债务 / (总债务+股权)。 |
| interestCoverage | numeric | EBIT / 利息费用。 |
| cashFlowToDebtRatio | numeric | 经营现金流 / 总债务。 |
| companyEquityMultiplier | numeric | 总资产 / 权益，衡量财务杠杆。 |
| receivablesTurnover | numeric | 收入 / 平均应收账款。 |
| payablesTurnover | numeric | 销货成本 / 平均应付账款。 |
| inventoryTurnover | numeric | 销货成本 / 平均存货。 |
| fixedAssetTurnover | numeric | 收入 / 固定资产净额。 |
| assetTurnover | numeric | 收入 / 总资产。 |
| operatingCashFlowPerShare | numeric | 经营现金流 / 流通股数。 |
| freeCashFlowPerShare | numeric | 自由现金流 / 流通股数。 |
| cashPerShare | numeric | 现金及等价物 / 流通股数。 |
| payoutRatio | numeric | 股息 / 净利润。 |
| operatingCashFlowSalesRatio | numeric | 经营现金流 / 收入。 |
| freeCashFlowOperatingCashFlowRatio | numeric | 自由现金流 / 经营现金流。 |
| cashFlowCoverageRatios | numeric | 经营现金流 / 利息支出。 |
| shortTermCoverageRatios | numeric | 经营现金流 / 短期债务。 |
| capitalExpenditureCoverageRatio | numeric | 经营现金流 / 资本支出。 |
| dividendPaidAndCapexCoverageRatio | numeric | 经营现金流 / (股息+资本支出)。 |
| dividendPayoutRatio | numeric | 同 `payoutRatio`，部分来源提供的 alternative 算法。 |
| priceBookValueRatio | numeric | 每股价格 / 每股账面价值。 |
| priceToBookRatio | numeric | 同上（兼容字段）。 |
| priceToSalesRatio | numeric | 市值 / 收入。 |
| priceEarningsRatio | numeric | 市值 / 净利润（或每股价 / EPS）。 |
| priceToFreeCashFlowsRatio | numeric | 市值 / 自由现金流。 |
| priceToOperatingCashFlowsRatio | numeric | 市值 / 经营现金流。 |
| priceCashFlowRatio | numeric | 每股价格 / 每股现金流。 |
| priceEarningsToGrowthRatio | numeric | PEG 值，PE / 盈利增长。 |
| priceSalesRatio | numeric | 每股价格 / 每股收入。 |
| dividendYield | numeric | 股息收益率。 |
| enterpriseValueMultiple | numeric | 企业价值 / EBITDA。 |
| priceFairValue | numeric | FMP 估算的合理价值倍数。 |

季度、年度与预测表结构保持一致，预测表新增 `prediction_date`、`fiscal_year`、`fiscal_quarter` 列，数值由模型生成。

### `f_financial_trends`
| 字段名 | 含义 |
| --- | --- |
| `id` | 主键，自增。 |
| `ticker` | 股票代码。 |
| `table_name` | 指标来源表（如 `f_income_statement_year` 或对应的 `_predict` 表）。 |
| `column_name` | 指标名称（如 `revenue`、`netIncome`）。 |
| `current_trend_direction` | 当前趋势方向（1 向上，-1 向下，0 平稳）。 |
| `current_trend_aggregate_growth` | 当前趋势累计增速。 |
| `current_trend_duration_total_q` | 当前趋势已持续季度数。 |
| `current_trend_duration_future_q` | 当前趋势预计可持续的季度数。 |
| `current_trend_start_quarter` | 当前趋势起始季度（YYYYQ 格式）。 |
| `next_trend_direction` | 下一趋势方向预测。 |
| `next_trend_aggregate_growth` | 下一趋势累计增速预测。 |
| `next_trend_duration_q` | 下一趋势预计持续季度数。 |
| `next_trend_start_quarter` | 下一趋势预计起始季度。 |
| `updated_at` | 更新时间。 |

该表基于各类 `_predict` 预测表的结果对未来趋势进行统一建模，便于在选股逻辑中直接读取未来变化趋势。

<a id="f_key_metrics_"></a>
### `f_key_metrics_*`
囊括每股指标、估值倍数、资本结构以及营运效率等关键指标。预测表同样包含 `prediction_date`、`fiscal_year`、`fiscal_quarter`，其余字段意义与实际值一致。

主要字段释义如下（季度/年度表一致，预测表为模型估计）：

| 字段名 | 数据类型 | 含义 |
| --- | --- | --- |
| revenuePerShare | numeric | 每股收入。 |
| netIncomePerShare | numeric | 每股净利润。 |
| operatingCashFlowPerShare | numeric | 每股经营现金流。 |
| freeCashFlowPerShare | numeric | 每股自由现金流。 |
| cashPerShare | numeric | 每股现金及等价物。 |
| bookValuePerShare | numeric | 每股账面价值。 |
| tangibleBookValuePerShare | numeric | 每股有形资产账面价值。 |
| shareholdersEquityPerShare | numeric | 每股股东权益。 |
| interestDebtPerShare | numeric | 每股计息债务。 |
| marketCap | bigint | 市值。 |
| enterpriseValue | bigint | 企业价值。 |
| peRatio | numeric | 市盈率。 |
| priceToSalesRatio | numeric | 市销率。 |
| pocfratio | numeric | 市场价格 / 经营现金流。 |
| pfcfRatio | numeric | 市场价格 / 自由现金流。 |
| pbRatio | numeric | 市净率。 |
| ptbRatio | numeric | 账面价值 / 股价（PB 倒数）。 |
| evToSales | numeric | 企业价值 / 销售额。 |
| enterpriseValueOverEBITDA | numeric | 企业价值 / EBITDA。 |
| evToOperatingCashFlow | numeric | 企业价值 / 经营现金流。 |
| evToFreeCashFlow | numeric | 企业价值 / 自由现金流。 |
| earningsYield | numeric | 盈利收益率（EPS/股价）。 |
| freeCashFlowYield | numeric | 自由现金流收益率。 |
| debtToEquity | numeric | 负债权益比。 |
| debtToAssets | numeric | 负债资产比。 |
| netDebtToEBITDA | numeric | 净债务 / EBITDA。 |
| currentRatio | numeric | 流动比率。 |
| interestCoverage | bigint | 利息保障倍数。 |
| incomeQuality | numeric | 净利润 / 经营现金流，用于衡量利润质量。 |
| dividendYield | numeric | 股息收益率。 |
| payoutRatio | numeric | 股息支付率。 |
| salesGeneralAndAdministrativeToRevenue | bigint | 销售及管理费用占收入比例（数值型，按原始数据）。 |
| researchAndDdevelopementToRevenue | numeric | 研发费用占收入比例。 |
| intangiblesToTotalAssets | bigint | 无形资产占总资产比例。 |
| capexToOperatingCashFlow | numeric | 资本支出占经营现金流比例。 |
| capexToRevenue | numeric | 资本支出占收入比例。 |
| capexToDepreciation | numeric | 资本支出 / 折旧。 |
| stockBasedCompensationToRevenue | numeric | 股权激励费用占收入比例。 |
| grahamNumber | numeric | 格雷厄姆估值指标。 |
| roic | numeric | 投入资本回报率。 |
| returnOnTangibleAssets | numeric | 有形资产回报率。 |
| grahamNetNet | numeric | 净净资产估值指标。 |
| workingCapital | bigint | 营运资本。 |
| tangibleAssetValue | bigint | 有形资产价值。 |
| netCurrentAssetValue | bigint | 净流动资产价值。 |
| investedCapital | bigint | 投入资本。 |
| averageReceivables | bigint | 平均应收账款。 |
| averagePayables | bigint | 平均应付账款。 |
| averageInventory | bigint | 平均存货。 |
| daysSalesOutstanding | numeric | 销售回款天数。 |
| daysPayablesOutstanding | numeric | 应付账款周转天数。 |
| daysOfInventoryOnHand | numeric | 存货周转天数。 |
| receivablesTurnover | numeric | 应收账款周转率。 |
| payablesTurnover | numeric | 应付账款周转率。 |
| inventoryTurnover | numeric | 存货周转率。 |
| roe | numeric | 净资产收益率。 |
| capexPerShare | numeric | 每股资本支出。 |

### `f_earning_calendar`
| 字段名 | 含义 |
| --- | --- |
| `id` | 主键。 |
| `date` | 财报发布日期。 |
| `symbol` | 股票代码。 |
| `eps` | 公司指引或预期 EPS。 |
| `eps_estimated` | 市场一致预期 EPS。 |
| `time` | 发布时段（BMO 开盘前 / AMC 收盘后）。 |
| `revenue` | 公司指引或预期营收。 |
| `revenue_estimated` | 市场一致预期营收。 |
| `fiscal_date_ending` | 对应财报截止日期。 |
| `updated_from_date` | 最近同步来源的日期。 |
| `data_source` | 数据来源（例如 FMP_v3）。 |
| `api_type` | API 类型标识。 |
| `download_time` | 下载时间戳。 |
| `confidence_score` | 置信度评分。 |
| `is_confirmed` | 公布时间是否已确认。 |

### `f_percentile`
广义分位数表，用于记录各指标的历史统计区间（percentile、最大最小值等），字段包括：
| 字段名 | 含义 |
| --- | --- |
| `ticker` | 股票代码。 |
| `metric_name` | 指标名称（如 `pe_ltm`）。 |
| `lookback_years` | 回溯年限。 |
| `latest_value` | 最近实际值。 |
| `percentile` | 当前值在历史样本中的百分位。 |
| `median`、`average`、`std_dev` | 历史统计指标。 |
| `min_value`、`percentile_20`、`percentile_80`、`max_value` | 历史区间。 |
| `data_points_count` | 样本点数量。 |
| `latest_date` | 最新数据日期。 |
| `updated_at` | 更新时间。 |

`f_percentile1` 为改进版，结构类似但 `ticker` 字段为 `character varying(20)`。

### `f_valuation_financial_quarter`
用于估值模型的标准化财务报表（以美元折算）：
| 字段名 | 含义 |
| --- | --- |
| `ticker` | 股票代码。 |
| `fiscal_year`, `fiscal_quarter`, `quarter_end_date` | 报告期信息。 |
| `report_date` | 报告发布日期。 |
| `revenue`, `net_income`, `operating_income`, `ebitda` | 关键损益指标（本币）。 |
| `total_debt`, `cash_and_equivalents`, `total_equity` | 资产负债指标。 |
| 对应 `_usd` 字段 | 将上述指标按 `reported_currency` 与 `market_currency` 折算为美元。 |
| `reported_currency`, `market_currency` | 报表币种与市场计价币种。 |
| `report_frequency` | 报告频率（Q/FY）。 |
| `data_source` | 数据来源标识。 |
| `job_id` | 数据任务批次。 |
| `created_at`, `updated_at` | 生成与更新时间。 |

### `f_valuation_multiple`
| 字段名 | 含义 |
| --- | --- |
| `ticker` | 股票代码。 |
| `calculation_date` | 倍数计算日期。 |
| `price` | 当日股价。 |
| `market_cap`, `enterprise_value` | 市值、企业价值。 |
| `pe_ltm`, `pe_ntm`, `pe_2y`, `pe_3y` | 市盈率（滚动、未来 12 个月、过去/未来 2-3 年）。 |
| `pb_ltm` | 市净率。 |
| `ev_sales_*`, `ev_ebit_*`, `ev_ebitda_*` | EV 与销售/EBIT/EBITDA 倍数，含 LTM、NTM、2Y、3Y 等。 |
| `market_cap_usd`, `enterprise_value_usd` | 折算美元的估值。 |
| `weightedAverageShsOut` | 加权平均股本。 |
| `market_cap_currency`, `reported_currency` | 市值计价币种、报表币种。 |
| `updated_at` | 更新时间。 |

### `portfolio_entity`
基于公司公告与结构化信息抽取结果，为单个公司生成的投资要点与多维评分快照。
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | bigint | 否 | 主键，自增 ID。 |
| ticker | text | 是 | 组合成分对应的股票代码。 |
| name | text | 是 | 展示名称（通常为公司简称）。 |
| price | numeric | 是 | 最新价格，由 `currency` 指定币种。 |
| market_cap | numeric | 是 | 当前市值。 |
| target_market_cap_base | numeric | 是 | 基准情景下的目标市值。 |
| target_market_cap_base_changed | numeric | 是 | 经人工或模型修正后的目标市值。 |
| return_base | numeric | 是 | 基准情景预期收益率。 |
| quality_score | numeric | 是 | 质量维度评分。 |
| growth_score | numeric | 是 | 成长维度评分。 |
| valuation_score | numeric | 是 | 估值维度评分。 |
| revenue_cagr | numeric | 是 | 收入复合增长率（默认口径）。 |
| operating_profit_cagr | numeric | 是 | 营业利润复合增长率。 |
| title | text | 是 | 组合条目展示标题。 |
| publish_time | text | 是 | 对外展示时间（字符串格式，兼容多源数据）。 |
| score_update_time | timestamp without time zone | 是 | 最近一次评分更新时间。 |
| version | text | 是 | 数据版本号。 |
| quality_score_3 | numeric | 是 | 质量评分（v3 算法版本）。 |
| growth_score_3 | numeric | 是 | 成长评分（v3 算法版本）。 |
| revenue_cagr_1 | numeric | 是 | 收入 CAGR（1 年窗口或 v1 模型）。 |
| quality_score_4 | numeric | 是 | 质量评分（v4 算法版本）。 |
| growth_score_4 | numeric | 是 | 成长评分（v4 算法版本）。 |
| valuation_score_4 | numeric | 是 | 估值评分（v4 算法版本）。 |
| revenue_cagr_4 | numeric | 是 | 收入 CAGR（v4 模型）。 |
| operating_profit_cagr_4 | numeric | 是 | 营业利润 CAGR（v4 模型）。 |
| trend_score | numeric | 是 | 技术/趋势评分。 |
| investment_score | numeric | 是 | 综合投资评分（最终排序依据）。 |
| primary_investment_type | text | 是 | 主投资类型（如 long、short）。 |
| secondary_investment_type | text | 是 | 次级策略或标签。 |
| short_candidate | text | 是 | 是否为做空候选（文本或 Y/N）。 |
| primary_investment_driver | text | 是 | 投资驱动摘要。 |
| gemini_embedding | USER-DEFINED | 是 | 组合说明嵌入向量。 |
| currency | text | 是 | 金额字段所用币种。 |
| is_changed | integer | 是 | 相比上一版本是否变更（0/1）。 |
| embdeing_is_updated | integer | 是 | 嵌入向量是否已更新（0/1）。 |
| quality_report | text | 是 | 质量分析英文版。 |
| quality_report_cn | text | 是 | 质量分析中文版。 |
| quality | integer | 是 | 质量评级分段。 |
| growth | integer | 是 | 成长评级分段。 |
| segment_flag | integer | 是 | 是否已关联分部信息。 |
| source | text | 是 | 数据来源或生成流程说明。 |

### `segment_entity`
对公司公告及分部披露信息进行抽取与评分，生成分业务线的量化指标与估值辅助数据。
| 字段名 | 数据类型 | 可为空 | 业务含义 |
| --- | --- | --- | --- |
| id | integer | 否 | 主键，自增 ID。 |
| ticker | text | 是 | 股票代码。 |
| company_name | text | 是 | 公司名称。 |
| segment_name | text | 是 | 业务分部名称。 |
| segment_quality_score | numeric | 是 | 分部质量评分。 |
| three_year_cagr | numeric | 是 | 最近三年收入 CAGR。 |
| contribution_to_total_growth | numeric | 是 | 对公司整体增长的贡献度。 |
| segment_contribution_to_marketcap_change | numeric | 是 | 对公司市值变化的贡献。 |
| products_and_services | text | 是 | 分部主要产品与服务说明。 |
| revenue_most_recent_fy | numeric | 是 | 最近财年的分部收入（本币）。 |
| revenue_most_recent_fy_usd | numeric | 是 | 最近财年收入折算美元。 |
| revenue_contribution | numeric | 是 | 分部收入占比。 |
| profit_margin | numeric | 是 | 分部利润率。 |
| operating_profit | numeric | 是 | 分部营业利润。 |
| operating_profit_usd | numeric | 是 | 分部营业利润（美元）。 |
| historical_growth | numeric | 是 | 历史增长率。 |
| projected_growth | numeric | 是 | 模型预测增长率。 |
| industry | text | 是 | 分部所属行业。 |
| current_market_size | numeric | 是 | 当前市场规模。 |
| current_market_size_usd | numeric | 是 | 当前市场规模（美元）。 |
| projected_market_size_three_year | numeric | 是 | 三年后预测市场规模。 |
| projected_market_size_three_year_usd | numeric | 是 | 三年后预测市场规模（美元）。 |
| three_year_projected_cage | numeric | 是 | 三年预测 CAGR（字段名沿用原拼写）。 |
| long_term_tam_five_year | numeric | 是 | 五年期长期 TAM。 |
| long_term_tam_five_year_usd | numeric | 是 | 五年期 TAM（美元）。 |
| company_market_share | numeric | 是 | 当前市场份额。 |
| long_term_market_share_target | numeric | 是 | 长期目标市场份额。 |
| competitive_advantages | text | 是 | 核心竞争优势总结。 |
| direct_competitor_1/2/3 | text | 是 | 主要竞争对手名称。 |
| direct_competitor_ticker_1/2/3 | text | 是 | 竞争对手股票代码。 |
| direct_competitor_company_name_1/2/3 | text | 是 | 竞争对手公司全名。 |
| key_customer_1/2/3 | text | 是 | 关键客户名称。 |
| key_customer_ticker_1/2/3 | text | 是 | 关键客户股票代码。 |
| key_customer_company_name_1/2/3 | text | 是 | 关键客户公司名称。 |
| key_supplier_1/2/3 | text | 是 | 核心供应商名称。 |
| key_supplier_ticker_1/2/3 | text | 是 | 核心供应商股票代码。 |
| key_supplier_company_name_1/2/3 | text | 是 | 核心供应商公司名称。 |
| sales_channel_1/2/3 | text | 是 | 主要销售渠道。 |
| key_positive_market_trend_1/2/3 | jsonb | 是 | 积极市场趋势（结构化 JSON）。 |
| key_negative_market_trend_1/2/3 | jsonb | 是 | 消极市场趋势（结构化 JSON）。 |
| terminal_revenue | numeric | 是 | 终值收入预测（本币）。 |
| terminal_revenue_usd | numeric | 是 | 终值收入预测（美元）。 |
| terminal_ebitda_margin | numeric | 是 | 终值 EBITDA 利润率。 |
| terminal_ebitda | numeric | 是 | 终值 EBITDA。 |
| terminal_ebitda_usd | numeric | 是 | 终值 EBITDA（美元）。 |
| terminal_multiple | numeric | 是 | 终值估值倍数。 |
| terminal_valuation | numeric | 是 | 终值估值。 |
| terminal_valuation_usd | numeric | 是 | 终值估值（美元）。 |
| expected_value_impact | numeric | 是 | 对公司估值的预期影响。 |
| segment_enterprise_value | numeric | 是 | 分部企业价值估算。 |
| segment_enterprise_value_usd | numeric | 是 | 分部企业价值（美元）。 |
| segment_specific_formula | text | 是 | 估值或增长计算公式说明。 |
| segment_content | text | 是 | 分部详细分析（英文）。 |
| segment_content_cn | text | 是 | 分部详细分析（中文）。 |
| gemini_embedding | USER-DEFINED | 是 | 分部文本嵌入向量。 |
| run_time | timestamp with time zone | 是 | 数据写入时间。 |
| version | text | 是 | 数据版本。 |
| title | text | 是 | 报告标题。 |
| quality_id | integer | 是 | 关联质量报告 ID。 |
| growth_id | integer | 是 | 关联成长报告 ID。 |
| currency | character varying | 是 | 金额字段使用的币种。 |
| conversion_rate | numeric | 是 | 本币对美元汇率。 |
| conversion_date | timestamp without time zone | 是 | 汇率更新时间。 |
| new_column_name | integer | 是 | 预留/调试字段。 |
| flag_debug | integer | 是 | 调试标记。 |

## 估值与衍生指标表

除上述财务明细外，数据库还有以下常用支撑表，可在此文档基础上追加章节：
- `f_financial_trends`：指标长表，适合统一查询。 |
- `f_percentile`：历史分位数。 |
- `f_valuation_*`：估值结果与版本管理。 |
- `portfolio_entity`：组合评分与投资结论快照。 |
- `segment_entity`：业务分部分析与估值拆分。 |j
