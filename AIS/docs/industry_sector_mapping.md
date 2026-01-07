# Industry–Sector mapping with market caps and top companies

Generated: 2025-11-28T06:53:39Z (UTC)

- Source table: `public.company_base`
- Filters: exclude empty `industry/sector`; exclude `is_etf`=true, `is_fund`=true; require `mkt_cap_usd>0`
- Aggregations: total is SUM(`mkt_cap_usd`) per (industry, sector); TOP1/2/3 by `mkt_cap_usd`
- Pairs included: 290

| industry | sector | total_mkt_cap_usd | top1_company | top1_mkt_cap_usd | top2_company | top2_mkt_cap_usd | top3_company | top3_mkt_cap_usd |
|---|---|---:|---|---:|---|---:|---|---:|
| Agricultural Farm Products | Basic Materials | 53191319 | Vikas Lifecare Limited | 53191319 |  |  |  |  |
| Agricultural Inputs | Basic Materials | 341523895493 | E. I. du Pont de Nemours and Company | 60616250218 | Corteva, Inc. | 48468178500 | Nutrien Ltd. | 27157900770 |
| Aluminum | Basic Materials | 175998308802 | China Hongqiao Group Limited | 26814273526 | Hindalco Industries Limited | 17657903321 | Aluminum Corporation of China Limited | 16964217009 |
| Basic Materials | Basic Materials | 199357810 | IMURA & Co.,Ltd. | 66242719 | Okayama Paper Industries Co., Ltd. | 46490068 | Heiwa Paper Co.,Ltd. | 27800790 |
| Chemicals | Basic Materials | 843660420947 | Shin-Etsu Chemical Co., Ltd. | 62318871944 | BASF Se | 47328237579 | Saudi Basic Industries Corporation | 46120576500 |
| Chemicals - Specialty | Basic Materials | 1715757141604 | It-chem | 251660000000 | Linde plc | 222379432080 | L'Air Liquide S.A. | 117605312294 |
| Conglomerates | Basic Materials | 1325608338 | OCI Company Ltd. | 1325608338 |  |  |  |  |
| Construction | Basic Materials | 6645892345 | Louisiana-Pacific Corporation | 6608180936 | Sahyadri Industries Limited | 37711409 |  |  |
| Construction Materials | Basic Materials | 2996649449802 | Daiwa Heavy Industry Co., Ltd. | 2066412196079 | Jsw Cement Ltd. | 208757669879 | CRH plc | 74280974046 |
| Consumer Cyclical | Basic Materials | 215016172 | HsinLi Chemical Industrial Corp. | 215016172 |  |  |  |  |
| Copper | Basic Materials | 191420618593 | Freeport-McMoRan Inc. | 60133694000 | Antofagasta plc | 26836790252 | First Quantum Minerals Ltd. | 14403608438 |
| Drug Manufacturers - Specialty & Generic | Basic Materials | 841731000 | Radius Recycling, Inc. | 841731000 |  |  |  |  |
| Gold | Basic Materials | 848937027169 | Newmont Corporation | 76774740000 | Zijin Mining Group Company Limited | 74793472221 | Agnico Eagle Mines Limited | 68556202102 |
| Industrial - Machinery | Basic Materials | 40286947800 | Barrick Mining Corporation | 40286947800 |  |  |  |  |
| Industrial Materials | Basic Materials | 1692159062010 | BHP Group Limited | 133979878177 | Rio Tinto Group | 104679433412 | The Sherwin-Williams Company | 87805109280 |
| Industrial - Pollution & Treatment Controls | Basic Materials | 333312234 | Aduro Clean Technologies Inc. | 333312234 |  |  |  |  |
| Industrials | Basic Materials | 117500606 | Omni-Plus System Limited | 117500606 |  |  |  |  |
| Oil & Gas Energy | Basic Materials | 515348060 | Green Plains Inc. | 515348060 |  |  |  |  |
| Other Precious Metals | Basic Materials | 194659723466 | Auxico Resources Canada Inc. | 49884394458 | PT Amman Mineral Internasional Tbk | 38741695654 | Fresnillo plc | 16858365806 |
| Paper, Lumber & Forest Products | Basic Materials | 186340378920 | Klabin S.A. | 25057772257 | UPM-Kymmene Oyj | 15056588936 | Suzano S.A. | 12440908565 |
| Shell Companies | Basic Materials | 2476399763 | USA Rare Earth Inc | 1480258368 | MAC Copper Ltd | 996141395 |  |  |
| Silver | Basic Materials | 35702308818 | Silver Bear Resources Plc | 13060356117 | Pan American Silver Corp. | 11571938550 | MAG Silver Corp. | 2395191600 |
| Specialty Business Services | Basic Materials | 153956789 | Avantium N.V. | 153956789 |  |  |  |  |
| Steel | Basic Materials | 593158598938 | JSW Steel Limited | 29269516053 | ArcelorMittal S.A. | 25587072000 | Tata Steel Limited | 22493186758 |
| Advertising Agencies | Communication Services | 160447903294 | Publicis Groupe S.A. | 22810722505 | Focus Media Information Technology Co., Ltd. | 15761177242 | Omnicom Group Inc. | 14130155620 |
| Broadcasting | Communication Services | 140095001848 | Comcast Holdings Corp. | 57639189934 | RTL Group S.A. | 6694191542 | Nippon Television Holdings, Inc. | 6274606423 |
| Electronic Gaming & Multimedia | Communication Services | 94467514 | DarkIris Inc. Class A Ordinary Shares | 90043000 | Winvia Entertainment Plc | 2956632 | AlphaGen Intelligence Corp. | 1467882 |
| Entertainment | Communication Services | 1206623646037 | Netflix, Inc. | 515638846440 | The Walt Disney Company | 202141269900 | Universal Music Group N.V. | 58683673012 |
| Gambling, Resorts & Casinos | Communication Services | 32029438 | Lottery.com Inc. | 32029438 |  |  |  |  |
| Information & Communication | Communication Services | 49864927 | PostPrime Inc | 49864927 |  |  |  |  |
| Internet Content & Information | Communication Services | 5882843848601 | Alphabet Inc. | 2449870653514 | Meta Platforms, Inc. | 1932452651241 | Tencent Holdings Limited | 649169737997 |
| Media & Entertainment | Communication Services | 189805633970 | Spotify Technology S.A. | 145131035487 | Charter Communications, Inc. | 35356593840 | TX Group AG | 3008114051 |
| Publishing | Communication Services | 221809808966 | IDW Media Holdings, Inc. | 108001959912 | Informa plc | 15201648660 | The New York Times Company | 10052564550 |
| Shell Companies | Communication Services | 2198431217 | MNTN Inc. | 2170645142 | Stran & Company, Inc. | 27786075 |  |  |
| Software - Services | Communication Services | 19881208280 | Twilio Inc. | 19881208280 |  |  |  |  |
| Specialty Business Services | Communication Services | 87998557148 | RELX Plc | 87998557148 |  |  |  |  |
| Technology | Communication Services | 1185811472 | COVER Corporation | 973594108 | Note Inc. | 158399694 | Excite Holdings Co., Ltd. | 42493320 |
| Telecommunications Services | Communication Services | 3421403369657 | T-Mobile US, Inc. | 275705391600 | China Mobile Limited | 229268367328 | AT&T Inc. 5.35% GLB NTS 66 | 203694724014 |
| Apparel - Footwear & Accessories | Consumer Cyclical | 254393744196 | NIKE, Inc. | 109793084780 | adidas AG | 40928077955 | ASICS Corporation | 17374612405 |
| Apparel - Manufacturers | Consumer Cyclical | 358675278756 | H & M Hennes & Mauritz AB (publ) | 23590329942 | Ralph Lauren Corporation | 18131465395 | Moncler S.p.A. | 15075012590 |
| Apparel - Retail | Consumer Cyclical | 840089971128 | Hermès International Société en commandite par actions | 280661818709 | The TJX Companies, Inc. | 146558999400 | Fast Retailing Co., Ltd. | 96151768596 |
| Auto - Dealerships | Consumer Cyclical | 177975332373 | Copart, Inc. | 44662773840 | D'Ieteren Group S.A. | 11563088396 | Penske Automotive Group, Inc. | 11546542277 |
| Auto - Manufacturers | Consumer Cyclical | 2931227309736 | Tesla, Inc. | 1060325818000 | Toyota Motor Corporation | 245032772052 | BYD Company Limited | 125705739062 |
| Auto - Parts | Consumer Cyclical | 970774968294 | DENSO Corporation | 40149810281 | Bridgestone Corporation | 30058727802 | Compagnie Générale des Établissements Michelin Société en commandite par actions | 25829913800 |
| Auto - Recreational Vehicles | Consumer Cyclical | 38808279270 | Zhejiang Cfmoto Power Co.,Ltd | 5412298082 | Thor Industries, Inc. | 5050085712 | Loncin Motor Co., Ltd. | 3830427031 |
| Beverages - Non-Alcoholic | Consumer Cyclical | 5256781289 | Chagee Holdings Limited American Depositary Shares | 5256781289 |  |  |  |  |
| Construction | Consumer Cyclical | 7121183198 | Installed Building Products, Inc. | 7121183198 |  |  |  |  |
| Consumer Cyclical | Consumer Cyclical | 7881653451 | Lai Yih Footwear Co., Ltd. | 2353556221 | Azzas 2154 S.A. | 1562712373 | Wiselink Co., Ltd. | 967323861 |
| Department Stores | Consumer Cyclical | 292291054268 | Aeon Co., Ltd. | 33584940073 | SM Investments Corporation | 19091356200 | Falabella S.A. | 13113966345 |
| Food Distribution | Consumer Cyclical | 26430378 | Integra Essentia Limited | 26430378 |  |  |  |  |
| Furnishings, Fixtures & Appliances | Consumer Cyclical | 475463088015 | Midea Group | 82828460291 | Midea Group Co., Ltd. | 74956946909 | Gree Electric Appliances, Inc. of Zhuhai | 36465000239 |
| Gambling, Resorts & Casinos | Consumer Cyclical | 365591018015 | Flutter Entertainment plc | 50046215469 | Aristocrat Leisure Limited | 28833438008 | Galaxy Entertainment Group Limited | 22698036729 |
| Hardware, Equipment & Parts | Consumer Cyclical | 85416767 | ACTIA Group S.A. | 85416767 |  |  |  |  |
| Home Improvement | Consumer Cyclical | 630852961981 | The Home Depot, Inc. | 385882824800 | Lowe's Companies, Inc. | 135149623700 | Wesfarmers Limited | 66870368267 |
| Household & Personal Products | Consumer Cyclical | 124257 | Artistmss International Group Inc. | 124257 |  |  |  |  |
| Industrial - Capital Goods | Consumer Cyclical | 17325869657 | Knorr-Bremse AG | 17325869657 |  |  |  |  |
| Industrial - Distribution | Consumer Cyclical | 28850952 | Satu Visi Putra Tbk. | 28134787 | Mafia Trends Limited | 716165 |  |  |
| Leisure | Consumer Cyclical | 391457760661 | Pop Mart International Group Limited | 47039654837 | Carnival Corporation & plc | 38484143336 | Oriental Land Co., Ltd. | 35826909957 |
| Luxury Goods | Consumer Cyclical | 674008910127 | LVMH Moët Hennessy - Louis Vuitton, Société Européenne | 277470246824 | Compagnie Financière Richemont S.A. | 108284060952 | Christian Dior SE | 94159322374 |
| Manufacturing - Textiles | Consumer Cyclical | 1090926525 | Sanathan Textiles Ltd. | 467160962 | Pashupati Cotspin Ltd. | 144110045 | R&B Denims Ltd | 125344015 |
| Media & Entertainment | Consumer Cyclical | 23605313277 | DraftKings Inc. | 22352721440 | ZEAL Network SE | 1193784864 | Nicco Parks & Resorts Limited | 58806973 |
| Packaging & Containers | Consumer Cyclical | 311159681890 | International Paper Company | 25101740100 | International Paper Company PFD $4 | 24494630830 | Smurfit Westrock Plc | 23238877306 |
| Paper, Lumber & Forest Products | Consumer Cyclical | 392249668 | Greenpanel Industries Limited | 392249668 |  |  |  |  |
| Personal Products & Services | Consumer Cyclical | 94683019574 | Rollins, Inc. | 28419289600 | Service Corporation International | 11292124800 | Puig Brands S.A. | 10919728202 |
| Residential Construction | Consumer Cyclical | 213650268637 | Lennar Corporation | 31689584291 | PulteGroup, Inc. | 23999328720 | NVR, Inc. | 23118460665 |
| Restaurants | Consumer Cyclical | 1043065254085 | McDonald's Corporation | 218406829850 | McDonald's Corp | 212098227434 | Starbucks Corporation | 107889816000 |
| Specialty Business Services | Consumer Cyclical | 8385000 | Incordex Corp. | 8385000 |  |  |  |  |
| Specialty Retail | Consumer Cyclical | 4453347199915 | Amazon.com, Inc. | 2364166116000 | Alibaba Group Holding Limited | 291321644454 | PDD Holdings Inc. | 158680930470 |
| Technology | Consumer Cyclical | 23285021 | ReYuu Japan Inc. | 23285021 |  |  |  |  |
| Travel Lodging | Consumer Cyclical | 371144815572 | Marriott International, Inc. | 74937945600 | Hilton Worldwide Holdings Inc. | 65956996000 | Las Vegas Sands Corp. | 36128074020 |
| Travel Services | Consumer Cyclical | 548630173158 | Booking Holdings Inc. | 175205002509 | Royal Caribbean Cruises Ltd. | 94641375600 | Airbnb, Inc. | 80193365760 |
| Agricultural Farm Products | Consumer Defensive | 339786745947 | Muyuan Foods Co., Ltd. | 35497392675 | Archer-Daniels-Midland Company | 27799647040 | Tyson Foods, Inc. | 20056136713 |
| Agricultural Inputs | Consumer Defensive | 1251651036 | Kaveri Seed Company Limited | 643252720 | Arabian Mills for Food Products | 608398316 |  |  |
| Apparel - Retail | Consumer Defensive | 179718403 | Leifheit AG | 179718403 |  |  |  |  |
| Beverages - Alcoholic | Consumer Defensive | 411101404902 | Anheuser-Busch InBev SA/NV | 132818042486 | Ambev S.A. | 38785304184 | Eastroc Beverage (Group) Co.,Ltd. | 21644080928 |
| Beverages - Non-Alcoholic | Consumer Defensive | 1231226250331 | Coca-Cola Co | 303721156663 | The Coca-Cola Company | 302762351800 | PepsiCo, Inc. | 198804106800 |
| Beverages - Wineries & Distilleries | Consumer Defensive | 668868672767 | Kweichow Moutai Co., Ltd. | 251061615566 | Wuliangye Yibin Co.,Ltd. | 66879100446 | Diageo plc | 60406128444 |
| Capital Markets | Consumer Defensive | 17320637 | TCTM Kids IT Education Inc ADR | 17320637 |  |  |  |  |
| Chemicals - Specialty | Consumer Defensive | 380712964 | S H Kelkar and Company Limited | 380712964 |  |  |  |  |
| Department Stores | Consumer Defensive | 2078142784 | Lenta International public joint-stock company | 2078142784 |  |  |  |  |
| Discount Stores | Consumer Defensive | 1536760517084 | Walmart Inc. | 827808966600 | Costco Wholesale Corporation | 435042067460 | Wal-Mart de México, S.A.B. de C.V. | 55030521780 |
| Drug Manufacturers - Specialty & Generic | Consumer Defensive | 145258800 | Safety Shot, Inc. | 145258800 |  |  |  |  |
| Education Technology | Consumer Defensive | 242325000 | Ruanyun Edai Technology Inc. Ordinary shares | 242325000 |  |  |  |  |
| Education & Training Services | Consumer Defensive | 101243658837 | New Oriental Education & Technology Group Inc. | 7453651456 | TAL Education Group | 6998002678 | Stride, Inc. | 6504557185 |
| Food Confectioners | Consumer Defensive | 243318398638 | Mondelez International, Inc. | 90067679200 | The Hershey Company | 38010843188 | Chocoladefabriken Lindt & Sprüngli AG | 37844408199 |
| Food Distribution | Consumer Defensive | 156815770377 | Sysco Corporation | 39095248800 | US Foods Holding Corp. | 18521881000 | Jerónimo Martins, SGPS, S.A. | 15359337501 |
| Grocery Stores | Consumer Defensive | 538363333950 | Loblaw Companies Limited | 49464996845 | The Kroger Co. | 49432926720 | Ross Stores Inc | 48665761319 |
| Healthcare | Consumer Defensive | 102151721 | Wel-Dish.Incorporated | 92240201 | Petgo Corporation | 9911520 |  |  |
| Household & Personal Products | Consumer Defensive | 1501201829772 | The Procter & Gamble Company | 359910335400 | L'Oréal S.A. | 239140182437 | Unilever PLC | 148533435179 |
| Industrials | Consumer Defensive | 181456160 | DKSH Holdings (Malaysia) Berhad | 181456160 |  |  |  |  |
| Packaged Foods | Consumer Defensive | 1427907692356 | Nestlé S.A. | 248071748201 | Danone S.A. | 54086464224 | The Kraft Heinz Company | 32856736000 |
| Software - Services | Consumer Defensive | 4594687540 | Adecoagro S.A. | 4594687540 |  |  |  |  |
| Specialty Business Services | Consumer Defensive | 19670243 | Golden Crest Education & Servi | 19670243 |  |  |  |  |
| Specialty Chemicals | Consumer Defensive | 285320415 | Solesence, Inc. Common Stock | 285320415 |  |  |  |  |
| Specialty Retail | Consumer Defensive | 25598658720 | Dollar General Corporation | 25598658720 |  |  |  |  |
| Tobacco | Consumer Defensive | 701640054613 | Philip Morris International Inc. | 264900486200 | British American Tobacco p.l.c. | 124479554444 | Altria Group, Inc. | 108124845500 |
| Coal | Energy | 457090880527 | China Shenhua Energy Company Limited | 99856940204 | PT Bayan Resources Tbk | 38071807168 | Adani Enterprises Limited | 34156665898 |
| Copper | Energy | 148653228 | GreenX Metals Limited | 148653228 |  |  |  |  |
| Energy | Energy | 26638109687 | Expand Energy Corporation | 23609794440 | Brava Energia S.A. | 1774944746 | Diversified Energy Company PLC | 717056188 |
| General Utilities | Energy | 174885887 | 7C Solarparken AG | 174885887 |  |  |  |  |
| Industrial - Machinery | Energy | 2148709200 | Oceaneering International, Inc. | 2148709200 |  |  |  |  |
| Oil & Gas Drilling | Energy | 33420180358 | Sinopec Oilfield Service Corporation | 4454650233 | Ades Holding Co. | 4359759076 | Noble Corporation Plc | 4287141000 |
| Oil & Gas Energy | Energy | 490147065823 | ConocoPhillips | 118552923100 | Marathon Petroleum Corporation | 49102270200 | Phillips 66 | 48211993200 |
| Oil & Gas E&P | Energy | 97099513 | Beacon Energy plc | 97099513 |  |  |  |  |
| Oil & Gas Equipment & Services | Energy | 492146552326 | Texas Gulf Energy, Incorporated | 227486430000 | Schlumberger Limited | 49333596900 | Tenaris S.A. | 18786017536 |
| Oil & Gas Exploration & Production | Energy | 782298096502 | CNOOC Limited | 117214806900 | Canadian Natural Resources Limited | 65444241028 | EOG Resources, Inc. | 63464112360 |
| Oil & Gas Integrated | Energy | 3893353507125 | Saudi Arabian Oil Company | 1569172908016 | Exxon Mobil Corporation | 486601452400 | Chevron Corporation | 317365923900 |
| Oil & Gas Midstream | Energy | 1084028914506 | Enbridge Inc. | 102523657465 | Enbridge Inc | 101626917756 | Enbridge Inc. CUM RED PREF Series B | 100289598892 |
| Oil & Gas Refining & Marketing | Energy | 479710880207 | Reliance Industries Limited | 215213958275 | Indian Oil Corporation Limited | 22821698849 | Bharat Petroleum Corporation Limited | 16500635335 |
| Renewable Utilities | Energy | 2328816902 | Shanghai REFIRE Group Ltd | 2328816902 |  |  |  |  |
| Semiconductors | Energy | 19802604600 | First Solar, Inc. | 19802604600 |  |  |  |  |
| Shell Companies | Energy | 706699070 | Granite Ridge Resources, Inc | 706699070 |  |  |  |  |
| Solar | Energy | 77837519284 | Waaree Energies Ltd | 10122094069 | Nextracker Inc. | 8317054753 | JA Solar Technology Co., Ltd. | 5396657618 |
| Uranium | Energy | 43265097031 | JSC National Atomic Company Kazatomprom | 11476547250 | Anfield Energy Inc. | 6899620000 | Uranium Energy Corp. | 4523472820 |
| Asset Management | Financial Services | 2508043778158 | National Securities Depository | 255077608625 | Blackstone Inc. | 204449197814 | BlackRock, Inc. | 174287102220 |
| Asset Management, Banking, Cryptocurrency, Financial Services, FinTech | Financial Services | 9633131255 | Galaxy Digital | 9633131255 |  |  |  |  |
| Asset Management - Bonds | Financial Services | 3656367270 | ABF Pan Asia Bond Index Fund | 3656367270 |  |  |  |  |
| Asset Management - Cryptocurrency | Financial Services | 1913938026 | Coincheck Group N.V. | 694625149 | Ethzilla Corp. | 505012190 | Bitcoin Group SE | 268643229 |
| Asset Management - Global | Financial Services | 93584391932 | Apollo Global Management, Inc. | 83363829780 | HarbourVest Global Private Equity Ltd. | 2696901850 | BBGI Global Infrastructure S.A. | 1360612612 |
| Asset Management - Income | Financial Services | 11587537218 | JPMorgan Global Growth & Income plc | 4441628648 | JPMorgan European Growth & Income plc | 706231456 | Plato Income Maximiser Limited | 694042019 |
| Asset Management - Leveraged | Financial Services | 1389215246 | S&P 500 VIX Short-term Futures Index (0930-1600 EST) | 1376696085 | BetaPro S&P 500 VIX Short-Term Futures ETF | 12519161 |  |  |
| Banks | Financial Services | 238081076840 | UniCredit S.p.A. | 122490751147 | Erste Group Bank AG | 38800842999 | Regions Financial Corporation | 22236315360 |
| Banks - Diversified | Financial Services | 6338885525499 | JPMorgan Chase & Co. | 809743453300 | Bank of America Corporation PFD SER B 7% | 384386389425 | Industrial & Commercial Bank of China Ltd. | 357525567100 |
| Banks - Regional | Financial Services | 6075419072665 | HDFC Bank Limited | 173778950890 | China Merchants Bank Co., Ltd. | 157086849104 | ICICI Bank Limited | 117331119183 |
| Biotechnology | Financial Services | 83909547 | Dominari Holdings Inc. | 83909547 |  |  |  |  |
| Construction Materials | Financial Services | 59436 | Sulja Bros Building Supplies Ltd. | 59436 |  |  |  |  |
| Financial - Capital Markets | Financial Services | 2068530522509 | Morgan Stanley | 229706537600 | The Goldman Sachs Group, Inc. | 218343575670 | The Goldman Sachs Group, Inc. PFD 1/1000 C | 217919794316 |
| Financial - Conglomerates | Financial Services | 151452969677 | Bajaj Finserv Ltd. | 37443529433 | TPG Operating Group II, L.P. 6.950% Fixed-Rate Junior Subordinated Notes due 2064 | 19987439473 | CNPC Capital Company Limited | 14676567869 |
| Financial Conglomerates | Financial Services | 304622850 | Archimedes Tech SPAC Partners II Co. Ordinary Shares | 302705700 | CO2 Energy Transition Corp. | 1917150 |  |  |
| Financial - Credit Services | Financial Services | 2412967336777 | Visa Inc. | 689312938598 | Mastercard Incorporated | 515322403680 | American Express Company | 216843790020 |
| Financial - Data & Stock Exchanges | Financial Services | 882861796644 | S&P Global Inc. | 171749568000 | Intercontinental Exchange, Inc. | 106923886400 | Coinbase Global, Inc. | 106920052726 |
| Financial - Diversified | Financial Services | 574669206962 | KKR & Co. Inc. | 127067894140 | CME Group Inc. | 101701993170 | Moody's Corporation | 92443026000 |
| Financial - Mortgages | Financial Services | 234046793914 | Sammaan Capital Limited | 111954370591 | Rocket Companies, Inc. | 38133687098 | Federal National Mortgage Association | 11511414600 |
| Financial Services | Financial Services | 21155648992 | Bajaj Housing Finance Limited | 11552724761 | Rakuten Bank, Ltd. | 8832088734 | FP Partner Inc. | 333033805 |
| Insurance - Brokers | Financial Services | 368049968517 | Marsh & McLennan Companies, Inc. | 100129060080 | Aon plc | 79120416000 | Arthur J. Gallagher & Co. | 78940264000 |
| Insurance - Diversified | Financial Services | 2138953307021 | Berkshire Hathaway Inc. | 1006189762976 | Allianz SE | 164028074193 | Axa S.A. | 106313918982 |
| Insurance-Diversified | Financial Services | 16367974020 | Brookfield Wealth Solutions Ltd. | 16367974020 |  |  |  |  |
| Insurance - Life | Financial Services | 1500792694842 | h Ping An Ins HK SDR2to1 | 143246182702 | China Life Insurance Company Limited | 142001608705 | Ping An Insurance (Group) Company of China, Ltd. | 138873563836 |
| Insurance - Property & Casualty | Financial Services | 1076031509096 | The Progressive Corporation | 144506380590 | Chubb Limited | 108140675600 | Tokio Marine Holdings, Inc. | 81381249793 |
| Insurance - Reinsurance | Financial Services | 250217116376 | Münchener Rückversicherungs-Gesellschaft AG in München | 85159706070 | Swiss Re AG | 54455673563 | Hannover Rück SE | 37462550074 |
| Insurance - Specialty | Financial Services | 105308242696 | Fidelity National Financial, Inc. | 15997780000 | Assurant, Inc. | 10306256521 | Ryan Specialty Holdings, Inc. | 8331842970 |
| Investment - Banking & Investment Services | Financial Services | 142707064669 | Brookfield Finance Inc. 4.50% P | 107422092652 | Stifel Financial Corporation 5.20% Senior Notes due 2047 | 11151248838 | Ladenburg Thalmann Financial Services Inc. 6.50% NT 27 | 4522190931 |
| Investment Trusts/Mutual Funds | Financial Services | 4991133983 | iShares U.S. Thematic Rotation Active ETF | 4991133983 |  |  |  |  |
| Medical - Healthcare Plans | Financial Services | 73378507200 | The Cigna Group | 73378507200 |  |  |  |  |
| Real Estate - Development | Financial Services | 1415583091 | IRSA Inversiones y Representaciones Sociedad Anónima WT | 1415583091 |  |  |  |  |
| REIT - Specialty | Financial Services | 3109161720 | Hannon Armstrong Sustainable Infrastructure Capital, Inc. | 3109161720 |  |  |  |  |
| Services | Financial Services | 34083963 | Integroup Inc | 34083963 |  |  |  |  |
| Shell Companies | Financial Services | 63472937695 | ACG Acquisition Company Limited | 14619922876 | Intellegence Parking Group Limited | 2837659650 | KAT Exploration Inc. | 1925983450 |
| Software - Application | Financial Services | 4187564124 | Riot Platforms, Inc. | 4026365280 | Brockhaus Technologies AG | 161198844 |  |  |
| Software - Services | Financial Services | 5441741784 | Bread Financial Holdings, Inc. | 2845087104 | The Western Union Company | 2596654680 |  |  |
| Special Purpose Acquisition Company (SPAC) | Financial Services | 298365461 | Gesher Acquisition Corp. II Units | 215420814 | UY Scuti Acquisition Corp. Units | 68811807 | Stellar V Capital Corp. Warrant | 7147733 |
| Technology | Financial Services | 238995921 | Transaction Media Networks Inc. | 132261930 | NETSTARS Co.,Ltd. | 106733991 |  |  |
| Biotechnology | Healthcare | 1751781333563 | Novo Nordisk A/S | 226816148265 | Vertex Pharmaceuticals Incorporated | 120399273450 | CSL Limited | 82471339184 |
| Care Facilities | Healthcare | 2513471418 | Dr. Soliman Abdel Kader Fakeeh Hospital Company | 2513471418 |  |  |  |  |
| Drug Manufacturers - General | Healthcare | 3652343379460 | Eli Lilly and Company | 607366092960 | Johnson & Johnson | 417044113100 | AbbVie Inc. | 349835520000 |
| Drug Manufacturers - Specialty & Generic | Healthcare | 1026101902586 | MERCK Kommanditgesellschaft auf Aktien | 55995207705 | Sun Pharmaceutical Industries Limited | 45826077298 | Haleon plc | 45428570630 |
| Hardware, Equipment & Parts | Healthcare | 504919875 | Lumibird S.A. | 504919875 |  |  |  |  |
| Healthcare | Healthcare | 11134085208 | Sagility India Limited | 2413292374 | Claritev Corporation | 933751827 | Universal Vision Biotechnology Co., Ltd. | 601071236 |
| Industrial Materials | Healthcare | 9901971 | Evolva Holding S.A. | 9901971 |  |  |  |  |
| Medical - Care Facilities | Healthcare | 548070700528 | HCA Healthcare, Inc. | 89294450340 | Revitalist Lifestyle and Wellness Ltd. | 38899718321 | Fresenius SE & Co. KGaA | 28687867060 |
| Medical - Devices | Healthcare | 1050543559782 | Abbott Laboratories | 233708968800 | Boston Scientific Corporation | 152827695000 | Medtronic plc | 119003428800 |
| Medical - Diagnostics & Research | Healthcare | 4208065877571 | Genetic Technologies Limited | 3643792902500 | Danaher Corporation | 143611389120 | IDEXX Laboratories, Inc. | 52647892882 |
| Medical - Distribution | Healthcare | 232302462618 | Cencora, Inc. | 55264751990 | Cencora | 55063290780 | Cardinal Health, Inc. | 37570146570 |
| Medical - Distribution, | Healthcare | 161 | MedAvail Holdings, Inc. | 161 |  |  |  |  |
| Medical - Equipment & Services | Healthcare | 638824613136 | Intuitive Surgical, Inc. | 170993052000 | Stryker Corporation | 144351477060 | McKesson Corporation | 83508316320 |
| Medical - Healthcare Information Services | Healthcare | 219278651815 | Veeva Systems Inc. | 46188401800 | GE HealthCare Technologies Inc. | 32872466880 | Pro Medicus Limited | 21414356259 |
| Medical-Healthcare Information Services | Healthcare | 1563903262 | Indegene Limited | 1563903262 |  |  |  |  |
| Medical - Healthcare Plans | Healthcare | 745502603761 | UnitedHealth Group Inc | 229163217617 | UnitedHealth Group Incorporated | 227692140000 | Cigna Corporation | 86231677953 |
| Medical - Instruments & Supplies | Healthcare | 803981935998 | EssilorLuxottica S.A. | 136158751344 | Menicon Co Ltd | 107816588366 | HOYA Corporation | 44600006216 |
| Medical/Nursing Services | Healthcare | 1465323 | NAYA Biosciences, Inc. | 1465323 |  |  |  |  |
| Medical - Pharmaceuticals | Healthcare | 694626374033 | Thermo Fisher Scientific Inc. | 173973400640 | Zoetis Inc. | 65601398800 | Regeneron Pharmaceuticals, Inc. | 59761324000 |
| Medical - Specialties | Healthcare | 5577277063 | Seegene, Inc. | 997337818 | Shenzhen Lifotronic Technology Co., Ltd. | 844576757 | L&C Bio Co., Ltd | 601257651 |
| Personal Products & Services | Healthcare | 19627969 | Niks Professional Ltd | 19627969 |  |  |  |  |
| Pharmaceutical | Healthcare | 95770432 | Chordia Therapeutics Inc. | 95770432 |  |  |  |  |
| Software - Application | Healthcare | 84998874 | Mach7 Technologies Limited | 58293352 | OneMedNet Corporation | 26705522 |  |  |
| Aerospace & Defense | Industrials | 2604958978754 | GE Aerospace | 291631604400 | RTX Corporation | 207286304400 | The Boeing Company | 173250920960 |
| Agricultural - Machinery | Industrials | 667156180306 | Caterpillar Inc. | 201619337350 | AB Volvo (publ) | 60926941868 | Daimler Truck Holding AG | 37021955888 |
| Airlines, Airports & Air Services | Industrials | 694592116864 | STARLUX Airlines Co., Ltd. | 62960751206 | Aena S.M.E., S.A. | 42759338400 | Delta Air Lines, Inc. | 35024130720 |
| Apparel - Footwear & Accessories | Industrials | 9723657 | AKI India Limited | 9723657 |  |  |  |  |
| Apparel - Manufacturers | Industrials | 38243292 | Manomay Tex India Limited | 33282819 | Icon Energy Corp. | 4960473 |  |  |
| Apparel - Retail | Industrials | 1514587011 | Forbo Holding AG | 1514587011 |  |  |  |  |
| Auto - Parts | Industrials | 1668628124 | Fuji Corporation | 1668628124 |  |  |  |  |
| Biotechnology | Industrials | 3697574093 | Jiangsu Zenergy Battery Technologies Group Co., Ltd. | 3697574093 |  |  |  |  |
| Business Equipment & Supplies | Industrials | 127358383779 | FUJIFILM Holdings Corporation | 28384521239 | Cintas Corp | 20430110850 | Avery Dennison Corporation | 13320037096 |
| Chemicals | Industrials | 668569511 | Schweiter Technologies AG | 668569511 |  |  |  |  |
| Conglomerates | Industrials | 1255890644751 | Hitachi, Ltd. | 138266165372 | Honeywell International Inc. | 137334570070 | Mitsubishi Corporation | 84204555115 |
| Construction | Industrials | 613517482934 | Trane Technologies plc | 95701476350 | Carrier Global Corporation | 63698133000 | Compagnie de Saint-Gobain S.A. | 57653370831 |
| Construction Materials | Industrials | 58454095745 | M & B Engineering Ltd. | 26613924191 | BirlaNu Limited | 14667804590 | Allegion plc | 14056505910 |
| Consulting Services | Industrials | 170580745068 | Experian plc | 47474344499 | Sgs S.A. | 20175518144 | TransUnion | 17707320000 |
| Consumer Cyclical | Industrials | 197179423 | King Chou Marine Technology Co., Ltd. | 136145783 | King's Metal Fiber Technologies Co., Ltd. | 36236149 | AZEARTH Corporation | 24797491 |
| Education & Training Services | Industrials | 49542597 | Altharwah Albashariyyah Co. | 49542597 |  |  |  |  |
| Electrical Equipment & Parts | Industrials | 1269831285191 | Contemporary Amperex Technology Co., Limited | 160914418428 | ABB Ltd | 121469567774 | Delta Electronics (Thailand) Public Company Limited | 55628312157 |
| Engineering & Construction | Industrials | 1514465465474 | Sri Lotus Developers and Realt | 93932698984 | Sri Lotus Devlprs N Rty L | 93742150440 | Vinci S.A. | 81952020174 |
| Environmental Services | Industrials | 108734692 | Leaf Global Environmental Services Co. | 108734692 |  |  |  |  |
| General Transportation | Industrials | 63549217740 | C.H. Robinson Worldwide Inc | 18106136860 | Expeditors International of Washington, Inc. | 16259836040 | Southwest Airlines Co. | 15713624960 |
| Hardware, Equipment & Parts | Industrials | 2635779542 | Landis+Gyr Group AG | 2420621382 | IKIO Lighting Limited | 185796318 | ClearSign Technologies Corporation | 29361842 |
| Healthcare | Industrials | 13963693 | D & M Company Co., Ltd. | 13963693 |  |  |  |  |
| Industrial - Capital Goods | Industrials | 585435297527 | Deere & Company | 138221975990 | Parker-Hannifin Corporation | 93520718200 | General Dynamics Corporation | 84498771090 |
| Industrial - Distribution | Industrials | 339589779923 | Fastenal Company | 55075243600 | W.W. Grainger, Inc. | 45446808186 | Ferguson plc | 44129051416 |
| Industrial - Infrastructure Operations | Industrials | 201657808531 | Ferrovial SE | 38263124636 | Transurban Group | 28045866459 | Salik Company P.J.S.C. | 13233294000 |
| Industrial - Machinery | Industrials | 3433584719391 | Siemens AG | 212403512771 | Lam Research Corp. R | 206124257500 | Schneider Electric S.E. | 147500480007 |
| Industrial Materials | Industrials | 383364792 | Mohammed Hadi Al Rasheed and Partners Co. | 383364792 |  |  |  |  |
| Industrial - Pollution & Treatment Controls | Industrials | 96120651455 | Veralto Corporation | 26726922468 | Federal Signal Corporation | 7622696341 | Zurn Elkay Water Solutions Corporation | 7399140480 |
| Industrials | Industrials | 369901949 | Otec Corporation | 182986787 | TOBA, Inc. | 100384392 | Naito & Co., Ltd. | 49320077 |
| Industrial - Specialties | Industrials | 8517997530 | SICC Co., Ltd. | 3678168450 | Acuren Corporation | 1356886920 | ELANTAS Beck India Limited | 1260565152 |
| Information & Communication | Industrials | 607977795 | Institute for Q-shu Pioneers of Space, Inc | 607977795 |  |  |  |  |
| Integrated Freight & Logistics | Industrials | 577655678241 | United Parcel Service, Inc. | 73391960300 | Dsv A/S | 57116870265 | Deutsche Post AG | 54830032635 |
| Manufacturing - Metal Fabrication | Industrials | 190675908901 | Carpenter Technology Corporation | 13837649814 | ATI Inc. | 10264349040 | Mueller Industries, Inc. | 9861245080 |
| Manufacturing - Miscellaneous | Industrials | 1539837851 | Hawkins Cookers Limited | 584154429 | Raoom Trading Co. | 218336062 | Morganite Crucible (India) Limited | 100382829 |
| Manufacturing - Textiles | Industrials | 4097911152 | Magnera Corp. | 452476000 | Zhejiang Xidamen New Material Co.,Ltd. | 361686912 | ZhongWang Fabric Co., Ltd. | 354472800 |
| Manufacturing - Tools & Accessories | Industrials | 182790480532 | Techtronic Industries Company Limited | 21878754911 | Snap-on Incorporated | 16786182120 | Lincoln Electric Holdings, Inc. | 13317006053 |
| Marine Shipping | Industrials | 503750898449 | A.P. Møller - Mærsk A/S | 34901798907 | Adani Ports and Special Economic Zone Limited | 33907736935 | COSCO SHIPPING Holdings Co., Ltd. | 33047930473 |
| Media & Entertainment | Industrials | 1364821262 | Karnov Group AB (publ) | 1364821262 |  |  |  |  |
| Paper, Lumber & Forest Products | Industrials | 1260184271 | Tarkett S.A. | 1260184271 |  |  |  |  |
| Railroads | Industrials | 761355412277 | Union Pacific Corporation | 132046286400 | Canadian Pacific Railway Limited | 72128949120 | CSX Corporation | 66051440400 |
| Rental & Leasing Services | Industrials | 273302051942 | United Rentals, Inc. | 55832190171 | Ashtead Group plc | 29145361743 | AerCap Holdings N.V. | 19464746080 |
| Security & Protection Services | Industrials | 153263510944 | ASSA ABLOY AB (publ) | 36165976088 | SECOM Co., Ltd. | 16303491896 | Securitas AB (publ) | 8480357668 |
| Semiconductors | Industrials | 551626529 | PVA TePla AG | 551626529 |  |  |  |  |
| Shell Companies | Industrials | 32470449609 | Symbotic Inc. | 32470449609 |  |  |  |  |
| Software - Services | Industrials | 56787743800 | Verisk Analytics, Inc. | 37030063600 | Global Payments Inc. | 19754280000 | LogicMark, Inc. | 3400200 |
| Solar | Industrials | 20063322 | Gensol Engineering Limited | 20063322 |  |  |  |  |
| Specialty Business Services | Industrials | 30425710547090 | Estore Corporation | 29923802340507 | Cintas Corporation | 91364884490 | Thomson Reuters Corporation | 89721706447 |
| Specialty Retail | Industrials | 12802066884 | Hikari Tsushin, Inc. | 12802066884 |  |  |  |  |
| Staffing & Employment Services | Industrials | 342735945057 | Automatic Data Processing, Inc. | 124139371860 | Recruit Holdings Co., Ltd. | 89026312755 | Paychex, Inc. | 50862850360 |
| Steel | Industrials | 138577567 | Electrotherm (India) Limited | 138577567 |  |  |  |  |
| Trucking | Industrials | 95166051525 | Old Dominion Freight Line, Inc. | 35445542250 | Saia, Inc. | 8170778520 | TFI International Inc. | 7187240511 |
| Waste Management | Industrials | 382869979467 | Waste Management, Inc. | 94701304700 | Republic Services, Inc. | 73436325360 | Waste Connections, Inc. | 48421630620 |
| Wholesale Distributors | Industrials | 57134375 | HomesToLife Ltd | 57134375 |  |  |  |  |
| Software – Application | Information Technology | 489315954 | NETWORK PEOPLE SRV TECH L | 489315954 |  |  |  |  |
| Financial - Diversified | Real Estate | 501822417 | Invesco Mortgage Capital Inc. | 501822417 |  |  |  |  |
| Oil & Gas Exploration & Production | Real Estate | 21159335 | Real Messenger Corporation | 21159335 |  |  |  |  |
| Real Estate | Real Estate | 104147006 | Yoshicon Co.,Ltd. | 104147006 |  |  |  |  |
| Real Estate - Development | Real Estate | 644512885502 | Emaar Properties PJSC | 37183481963 | Sun Hung Kai Properties Limited | 34739571885 | China Resources Land Limited | 27209028592 |
| Real Estate - Diversified | Real Estate | 264111486891 | Mitsui Fudosan Co., Ltd. | 29268235011 | Mitsubishi Estate Co., Ltd. | 25827077290 | Henderson Land Development Company Limited | 17307213993 |
| Real Estate - General | Real Estate | 264546998670 | Equinix, Inc. | 75962036800 | Ventas, Inc. | 31163076470 | Iron Mountain Incorporated | 30262663080 |
| Real Estate - Services | Real Estate | 624348673159 | CBRE Group, Inc. | 46325517000 | CoStar Group, Inc. | 40034925000 | Vonovia SE | 27595856415 |
| REIT - Diversified | Real Estate | 285614981051 | Goodman Group | 46956383047 | VICI Properties Inc. | 34765759000 | Stockland | 8801525197 |
| REIT - Healthcare Facilities | Real Estate | 173425201894 | Welltower Inc. | 109883554560 | Healthpeak Properties, Inc. | 12727490240 | American Healthcare REIT, Inc. | 6461215368 |
| REIT - Hotel & Motel | Real Estate | 61698713087 | STAR SM Real Estate Investment Trust Incorporated | 15927578700 | Host Hotels & Resorts, Inc. | 10884372660 | Ryman Hospitality Properties, Inc. | 6350861305 |
| REIT - Industrial | Real Estate | 349392885865 | Prologis, Inc. | 98077697840 | Public Storage | 50722365030 | Extra Space Storage Inc. | 29560992300 |
| REIT - Mortgage | Real Estate | 61462145553 | Annaly Capital Management, Inc. | 13226765600 | AGNC Investment Corp. | 9844348500 | Starwood Property Trust, Inc. | 7374784200 |
| REIT - Office | Real Estate | 176047562676 | Digital Realty Trust, Inc. | 57635043830 | Nippon Building Fund Incorporation | 8200552920 | Gecina S.A. | 8034336722 |
| REIT - Residential | Real Estate | 204223542173 | AvalonBay Communities, Inc. | 28751217600 | Equity Residential | 25486643520 | Invitation Homes Inc. | 19773734740 |
| REIT - Retail | Real Estate | 358528792180 | Simon Property Group, Inc. | 53835955810 | Realty Income Corporation | 52152870000 | Unibail-Rodamco-Westfield SE | 14798866770 |
| REIT - Specialty | Real Estate | 198866245101 | American Tower Corporation | 102634575120 | Crown Castle Inc. | 45505465500 | Lamar Advertising Company | 13093968869 |
| Telecommunications Services | Real Estate | 24476368484 | Cellnex Telecom, S.A. | 24476368484 |  |  |  |  |
| Analytics, Artificial Intelligence (AI), Machine Learning, Natural Language Processing | Technology | 73854376 | LightOn | 73854376 |  |  |  |  |
| Apparel - Retail | Technology | 506501552 | Turtle Beach Corporation | 315895552 | Vuzix Corporation | 190606000 |  |  |
| Asset Management | Technology | 19303937337 | Grab Holdings Limited | 19298643200 | GigCapital4, Inc. | 5294137 |  |  |
| Asset Management - Cryptocurrency | Technology | 30042432 | C2 Blockchain, Inc. | 30042432 |  |  |  |  |
| Chemicals - Specialty | Technology | 1415808350 | Daqo New Energy Corp. | 1415808350 |  |  |  |  |
| Communication Equipment | Technology | 1252657229319 | Cisco Systems, Inc. | 284288400000 | Cisco Systems Inc | 281883156985 | Foxconn Industrial Internet Co., Ltd. | 101150947416 |
| Computer Hardware | Technology | 791138932670 | Arista Networks, Inc. | 174798945600 | Sarcos Technology and Robotics Corporation | 115570677593 | Quanta Computer Inc. | 37471024938 |
| Consulting Services | Technology | 24705309 | Digital Research Company | 24705309 |  |  |  |  |
| Consumer Electronics | Technology | 4492761997567 | Apple Inc. | 3425525730000 | Samsung Electronics Co., Ltd. | 332327883268 | Xiaomi Corporation | 191811191001 |
| Education & Training Services | Technology | 52600658 | Horizon Educational Co. | 52600658 |  |  |  |  |
| Electrical Equipment & Parts | Technology | 7157306213 | SentinelOne, Inc. | 6239464000 | Sterlite Technologies Limited | 703263742 | Airtificial Intelligence Structures, S.A. | 214578471 |
| Electronic Gaming & Multimedia | Technology | 411792515917 | Roblox Corporation | 87302017687 | NetEase, Inc. | 82867929264 | Take-Two Interactive Software, Inc. | 40097591790 |
| Electronics & Computer Distribution | Technology | 149 | ADDvantage Technologies Group, Inc. | 149 |  |  |  |  |
| Financial - Capital Markets | Technology | 6516758896 | CleanSpark, Inc. | 3320758080 | Applied Digital Corporation | 3196000816 |  |  |
| General Transportation | Technology | 192898055300 | Uber Technologies, Inc. | 187285185200 | Lyft, Inc. | 5612870100 |  |  |
| Hardware, Equipment & Parts | Technology | 2068198233296 | Amphenol Corporation | 133031808000 | Keyence Corporation | 95467817141 | Dell Technologies Inc. | 93416473365 |
| Healthcare | Technology | 250513768 | eWeLL Co.,Ltd. | 250513768 |  |  |  |  |
| Industrial - Capital Goods | Technology | 19405428299 | Fortive Corporation | 17463785920 | Invisio AB (publ) | 1887696880 | Prodways Group S.A. | 53945499 |
| Industrial - Machinery | Technology | 423660189 | Stemmer Imaging AG | 408728970 | Catalyst Crew Technologies Corp. | 14931219 |  |  |
| Industrials | Technology | 52744130 | Howteh Technology Co., Ltd. | 52744130 |  |  |  |  |
| Information & Communication | Technology | 30349630 | Nyle Inc | 30349630 |  |  |  |  |
| Information & Communication |  | Technology | 47169914 | S&J Corp | 47169914 |  |  |  |
| Information Technology Consultancy | Technology | 327455200 | Siddhi Acquisition Corp Unit | 327455200 |  |  |  |  |
| Information Technology Services | Technology | 1453984402233 | International Business Machines Corporation | 235003613320 | Tata Consultancy Services Limited | 129600741428 | Infosys Limited | 67151752704 |
| Internet Software/Services | Technology | 6114693620 | Amentum Holdings, Inc. | 6114693620 |  |  |  |  |
| Media & Entertainment | Technology | 236593741692 | Nintendo Co., Ltd. | 113174284739 | Electronic Arts Inc. | 41944701480 | Live Nation Entertainment Inc | 39448725186 |
| Semiconductors | Technology | 10824657820014 | NVIDIA Corporation | 4457880000000 | Broadcom Inc. | 1434417245900 | Taiwan Semiconductor Manufacturing Company Limited | 1258353497928 |
| Software - Application | Technology | 3182607582160 | Sap Se | 340202952000 | Salesforce, Inc. | 236600440000 | Intuit Inc. | 208931303000 |
| Software – Application | Technology | 28660685795 | MicroStrategy Incorporated 10.00% Series A Perpetual Strife Preferred Stock | 28660685795 |  |  |  |  |
| Software - Infrastructure | Technology | 6285264496813 | Microsoft Corporation | 3880412066800 | Oracle Corporation | 702347941500 | Palantir Technologies Inc. | 423073653600 |
| Software - Services | Technology | 919409831140 | Adobe Inc. | 156729174000 | Accenture plc | 154181031620 | Synopsys, Inc. | 114619954480 |
| Solar | Technology | 4536258708 | SHENZHEN SOFARSOLA | 1986110733 | Vikram Solar Ltd. | 1291103953 | KALYON GUNES TEKNOLOJILERI | 711133750 |
| Technology | Technology | 3882628849 | ABEJA, Inc. | 296287091 | Macnica Galaxy Inc. | 273803803 | Arent Inc. | 251914627 |
| Technology Distributors | Technology | 91672757476 | TD SYNNEX Corporation | 12300359598 | Unisplendour Corporation Limited | 9913266086 | Rexel S.A. | 9077868258 |
| Diversified Utilities | Utilities | 725096182021 | Iberdrola, S.A. | 118367890743 | Enel S.p.A. | 93652025827 | Engie S.A. | 56284643182 |
| General Utilities | Utilities | 653654089891 | NextEra Energy, Inc. | 149113188900 | Southern Company | 100525435364 | American Electric Power Co Inc | 57716251297 |
| Independent Power Producers | Utilities | 528165940148 | China Yangtze Power Co., Ltd. | 95333196586 | Vistra Corp. | 68585783840 | ACWA POWER Company | 49983481319 |
| Industrial - Machinery | Utilities | 12327427683 | Suzlon Energy Limited | 9877058391 | Inox Wind Limited | 2450369292 |  |  |
| Oil & Gas Exploration & Production | Utilities | 146720865 | Orrön Energy AB (publ) | 146720865 |  |  |  |  |
| Regulated Electric | Utilities | 1880413053966 | Southern Company (The) Series 2 | 106225490354 | The Southern Company JR 2017B NT 77 | 105061998015 | The Southern Company | 104300794000 |
| Regulated Gas | Utilities | 319079048667 | Naturgy Energy Group, S.A. | 30206152600 | Atmos Energy Corporation | 26095330730 | Snam S.p.A. | 20100772550 |
| Regulated Water | Utilities | 143799083095 | American Water Works Company, Inc. | 28346944320 | Companhia de Saneamento Básico do Estado de São Paulo - SABESP | 14035735543 | Severn Trent Plc | 10909630706 |
| Renewable Utilities | Utilities | 884116347981 | GE Vernova Inc. | 177159216878 | Constellation Energy Corporation | 106079239666 | PT Barito Renewables Energy Tbk | 65311664019 |
| Water Utilities | Utilities | 1164686333 | Miahona Co. | 1164686333 |  |  |  |  |
