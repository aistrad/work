# Sector market caps and top companies

Generated: 2025-11-28T06:59:06Z (UTC)

- Source table: `public.company_base`
- Filters: exclude empty `sector`; exclude `is_etf`=true, `is_fund`=true; require `mkt_cap_usd>0`
- Aggregation: total is SUM(`mkt_cap_usd`) per sector; TOP1/2/3 by `mkt_cap_usd`
- Sectors included: 13

| sector | total_mkt_cap_usd | top1_company | top1_mkt_cap_usd | top2_company | top2_mkt_cap_usd | top3_company | top3_mkt_cap_usd |
|---|---:|---|---:|---|---:|---|---:|
| Industrials | 47782399086436 | Estore Corporation | 29923802340507 | GE Aerospace | 291631604400 | Siemens AG | 212403512771 |
| Technology | 32337803689597 | NVIDIA Corporation | 4457880000000 | Microsoft Corporation | 3880412066800 | Apple Inc. | 3425525730000 |
| Financial Services | 27612478232733 | Berkshire Hathaway Inc. | 1006189762976 | JPMorgan Chase & Co. | 809743453300 | Visa Inc. | 689312938598 |
| Healthcare | 15632760900374 | Genetic Technologies Limited | 3643792902500 | Eli Lilly and Company | 607366092960 | Johnson & Johnson | 417044113100 |
| Consumer Cyclical | 15531469731017 | Amazon.com, Inc. | 2364166116000 | Tesla, Inc. | 1060325818000 | The Home Depot, Inc. | 385882824800 |
| Communication Services | 11339048043699 | Alphabet Inc. | 2449870653514 | Meta Platforms, Inc. | 1932452651241 | Tencent Holdings Limited | 649169737997 |
| Basic Materials | 9886422647127 | Daiwa Heavy Industry Co., Ltd. | 2066412196079 | It-chem | 251660000000 | Linde plc | 222379432080 |
| Consumer Defensive | 8910293037711 | Walmart Inc. | 827808966600 | Costco Wholesale Corporation | 435042067460 | The Procter & Gamble Company | 359910335400 |
| Energy | 7892411922979 | Saudi Arabian Oil Company | 1569172908016 | Exxon Mobil Corporation | 486601452400 | Chevron Corporation | 317365923900 |
| Utilities | 5316913285881 | GE Vernova Inc. | 177159216878 | NextEra Energy, Inc. | 149113188900 | NextEra Energy, Inc. Series N J | 148232939794 |
| Real Estate | 3705967584646 | Welltower Inc. | 109883554560 | American Tower Corporation | 102634575120 | Prologis, Inc. | 98077697840 |
| 0.0 | 4246586232 | Ecopro Mat | 2626050533 | Yonz Technology Co.,Ltd. | 709757104 | Iffe Futura, S.A. | 444705504 |
| Information Technology | 489315954 | NETWORK PEOPLE SRV TECH L | 489315954 |  |  |  |  |
