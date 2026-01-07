# 铁板神数独立系统规格说明书 (Tieban Spec Ultra v3)

**文件名**: `tieban_spec_ultra_v3.md`  
**版本**: v3.0 (Independent Tieban Edition)  
**状态**: Final Design  
**架构基线**: Context Driven / Pluggable Modules（参见 [os_design_v3.md §1.4](../os/os_design_v3.md#14-context-驱动架构-可插拔模块视图)）  
**核心目标**: 构建一个仅基于 12,000 条文、算术推演逻辑和考刻闭环的独立命理引擎。  
**依赖模块**: `Global_Time_Engine` (真太阳时计算)  

---

## 0. 设计说明

这是一个基于所有铁板神数（Tieban 12k）核心资料（特别是 `research tieban2.md` 胖胖熊实战体系）重构的**独立铁板神数系统**深度设计文档。

本设计完全**剥离了邵子神数（Shaozi）的坐标逻辑**，专注于铁板神数特有的**算术流（Arithmetic Stream）**、**考刻分（Calibration）与 12,000 条文线性流**。同时，针对 `fortune_ai` 系统的扩展性，重构了用户模型设计，使其能同时容纳 Bazi, Tieban, Shaozi 等多个独立模块。

---

## 1. 系统总体架构 (System Architecture)

Tieban 模块被设计为 `fortune_ai` 系统中的一个**高精度时空校准与推演插件**。它不依赖其他模块，但在数据层与其他模块共享用户的基础生物档案。

### 1.1 逻辑架构图

```mermaid
graph TD
    Client[用户端 / WeChat UI] --> API[API Gateway]
    
    subgraph "Fortune AI Kernel (核心层)"
        API --> ProfileMgr[档案管理 (User Profiles)]
        API --> StateMgr[状态管理 (Module States)]
        ProfileMgr --> TimeEng[天文学引擎 (真太阳时)]
    end
    
    subgraph "Tieban Engine (独立插件)"
        StateMgr --> TB_Controller[Tieban Controller]
        
        TB_Controller --> PreCalc[预处理: 边界判定]
        PreCalc --> Algo_A[引擎A: 四柱天干配数]
        PreCalc --> Algo_B[引擎B: 八卦加则]
        
        Algo_A & Algo_B --> CalibMachine[考刻状态机 (FSM)]
        
        CalibMachine --> KB_Keys[(秘数表)]
        CalibMachine --> KB_Strips[(条文库 12k)]
        
        CalibMachine -- 锁定真刻 --> StreamEng[流年推演引擎]
        StreamEng --> KB_Strips
    end

```

---

## 2. 详细算法设计 (Step-by-Step Algorithms)

本系统并不依赖单一公式，而是通过**双引擎并行**生成“候选基数池”，再通过考刻筛选。

### 2.1 预处理：天文时间校准

* **输入**: 用户出生钟表时间 ，出生地经度 。
* **公式**: 
* **边界策略**: 若  落在时辰交界点（如 08:58） 分钟内，标记 `boundary_fuzzy=True`，需同时计算 **本时辰** 和 **下一时辰** 的四柱，生成两组基数池并行验证。

### 2.2 引擎 A：胖胖熊四柱天干配数法 (Engine-Stem)

*来源：`research tieban2.md*`
*用途：主要用于生成流年大运链表，是推演命运的主轴。*

**算法逻辑**:

1. **映射表 ()**:
`{甲:1, 乙:6, 丙:2, 丁:7, 戊:3, 己:8, 庚:4, 辛:9, 壬:5, 癸:0}`
2. **特殊权重顺序**:
铁板排序为：**月 -> 日 -> 时 -> 年**。
权重向量：
3. **计算公式**:
$$ Base_A = (Map(月干) \times 1000) + (Map(日干) \times 100) + (Map(时干) \times 10) + Map(年干) $$
4. **合化修正**:
若 `(月干, 日干)` 构成合化（如甲己合土），且月令支持，则生成变种基数 ，使用五行生数（水1/火2/木3/金4/土5）替换原映射值。

### 2.3 引擎 B：正宗八卦加则法 (Engine-Hexagram)

*来源：`research tieban2.md*`
*用途：精度极高，用于生成六亲考刻的锚点。*

**算法逻辑**:

1. **单柱化卦**:
针对四柱中的特定柱（如月柱或日柱）进行化卦。
* **上卦**: 天干对应卦 (甲壬=乾, 乙癸=坤, 丙=艮, 丁=兑, 戊=坎, 己=离, 庚=震, 辛=巽)
* **下卦**: 地支对应卦 (亥子=坎, 寅卯=震, 巳午=离, 申酉=兑, 辰戌=巽, 丑未=坤)


2. **计算公式**:
$$ Base_B = (Head(上卦) \times 1000) + Sum_{Yao}(全卦) - Tail(下卦) $$
* **Head/Tail**: `乾6, 兑7, 离9, 震3, 巽4, 坎1, 艮8, 坤2`
* ****: 查常量表（如水雷屯=390，或360）。



### 2.4 算例演示 (Step-by-Step Walkthrough)

**案例**: 王小明
**八字**: **甲子年 丙寅月 壬申日 丙午时**

#### Step 1: 引擎 A 计算

1. **排序**: 月(丙) -> 日(壬) -> 时(丙) -> 年(甲)
2. **映射**: 丙=2, 壬=5, 丙=2, 甲=1
3. **组合**: 
4. **结果**: 基数 **2521**。

#### Step 2: 引擎 B 计算 (以月柱丙寅为例)

1. **化卦**:
* 天干丙 -> 艮卦 (8)
* 地支寅 -> 震卦 (3)
* 组合 -> **山雷颐**


2. **参数**:
* Head(艮) = 8
* Tail(震) = 3
* Sum(山雷颐) = 390 (查表值)


3. **计算**:
$$ Base_B = (8 \times 1000) + 390 - 3 = \mathbf{8387} $$

#### Step 3: 考刻闭环 (The Loop)

系统生成候选池 。

1. **L1 粗筛 (Modulo 8)**:
* 计算 。对应刻分条文（如“父鼠母马”）。
* **交互**: "您的父母生肖是鼠和马吗？"
* **用户反馈**: "不是"。


2. **L1.5 秘数搜索**:
* 引入秘数 。
* 尝试 。
* 查库 ID 3848: "兄弟二人，我居长"。
* **交互**: "修正推算：您是否有兄弟二人，且您是老大？"
* **用户反馈**: "是的"。


3. **L2 锁定**:
* 锁定 **真基数 = 3848**。
* 锁定 **真刻分 = 3848对应的刻度**。



---

## 3. 知识库设计 (Knowledge Base)

数据库设计必须支持**算法反向搜索**（即根据含义找条文）。

### 3.1 数据库 Schema (PostgreSQL)

```sql
-- 1. 铁板条文主表 (Tieban 12k)
CREATE TABLE tieban_strips_12k (
    strip_id INT PRIMARY KEY,       -- 1 - 13000
    content TEXT NOT NULL,          -- "父鼠母马，先天定数"
    
    -- 核心分类
    category VARCHAR(20),           -- 'PARENTS', 'SIBLINGS', 'SPOUSE', 'FORTUNE'
    
    -- 结构化逻辑标签 (JSONB - 算法反向匹配的核心)
    -- 示例: {"f": "ZI", "m": "WU"} (父鼠母马)
    -- 示例: {"siblings": 2, "rank": 1} (兄弟二人我居长)
    logic_tags JSONB, 
    
    -- 算术索引
    mod_96 INT GENERATED ALWAYS AS (strip_id % 96) STORED -- 用于流年链表快速索引
);

-- 索引
CREATE INDEX idx_tieban_tags ON tieban_strips_12k USING gin (logic_tags);

-- 2. 秘数表
CREATE TABLE tieban_secret_keys (
    key_id SERIAL PRIMARY KEY,
    val INT NOT NULL                -- e.g., 1327, -1543
);

-- 3. 八卦常量表
CREATE TABLE tieban_hex_constants (
    hex_code VARCHAR(20) PRIMARY KEY, -- "GEN-ZHEN" (上艮下震)
    total_yao INT                     -- 390
);

```

---

## 4. Fortune User 系统升级设计 (Universal Container)

为了容纳 Bazi, Tieban, Shaozi 以及未来的模块，用户系统必须从“单一用户表”升级为 **“账号-档案-状态”三层架构**。

### 4.1 架构升级图

```
[FortuneUser (Account)] 
      |
      +-- 1:N --> [UserProfile (Biological Entity)]
                        |
                        +-- 1:1 --> [ModuleState: Bazi]
                        +-- 1:1 --> [ModuleState: Tieban]
                        +-- 1:1 --> [ModuleState: Shaozi]

```

### 4.2 数据库 Schema 升级

**1. 账号层 (`fortune_users`)**
仅存储登录与鉴权信息。

```sql
CREATE TABLE fortune_users (
    user_id UUID PRIMARY KEY,
    wechat_openid VARCHAR(64) UNIQUE,
    created_at TIMESTAMP
);

```

**2. 档案层 (`user_profiles`)**
存储物理世界的客观事实。支持一个账号管理多个档案（如自己、配偶、子女）。

```sql
CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY,
    user_id UUID REFERENCES fortune_users(user_id),
    name VARCHAR(50),
    gender VARCHAR(10),
    
    -- 统一的时空锚点 (不可变)
    birth_time_input TIMESTAMP,     -- 用户输入的钟表时间
    birth_geo JSONB,                -- {lat, lon, city}
    true_solar_time TIMESTAMP,      -- 系统计算的真太阳时 (所有模块共用)
    
    relation_tag VARCHAR(20)        -- 'SELF', 'SPOUSE', 'CHILD'
);

```

**3. 状态层 (`user_module_states`) - 核心扩展点**
存储各算命模块的**计算中间态**和**结果指针**。

```sql
CREATE TABLE user_module_states (
    state_id UUID PRIMARY KEY,
    profile_id UUID REFERENCES user_profiles(profile_id),
    
    module_code VARCHAR(20),        -- 'BAZI', 'TIEBAN_12K', 'SHAOZI_6K'
    status VARCHAR(20),             -- 'INIT', 'CALIBRATING', 'LOCKED'
    
    -- 模块专用数据容器 (Schema-less JSONB)
    -- 铁板存: { "base_candidates": [2521, 8387], "true_base": 3848, "offset": 1327 }
    -- 八字存: { "pillars": ["甲子", ...], "pattern": "从财格" }
    state_data JSONB,
    
    updated_at TIMESTAMP,
    UNIQUE(profile_id, module_code)
);

```

### 4.3 升级优势

1. **隔离性**: 铁板模块的考刻过程（如“正在确认父母”）不会干扰邵子模块的计算。
2. **复用性**: 所有模块共享 `user_profiles` 中的 `true_solar_time`，避免重复调用天文算法。
3. **扩展性**: 未来增加“紫微斗数”，只需插入 `module_code='ZIWEI'` 的状态记录。

---

## 5. 接口设计 (API Spec)

### 5.1 初始化 (`POST /api/tieban/init`)

* **Input**: `profile_id`
* **Logic**:
1. 获取真太阳时。
2. 运行 Engine A & B 生成基数池。
3. 生成第一轮考刻题（L1）。


* **Output**: `{ "state_id": "...", "question": "父鼠母马?", "options": [...] }`

### 5.2 提交验证 (`POST /api/tieban/verify`)

* **Input**: `{ "state_id": "...", "selected_option": 9003 }`
* **Logic**:
1. 若命中：更新 `state_data.true_base`，状态改为 `LOCKED`。
2. 若未命中：触发 L1.5 秘数搜索，返回下一轮问题。



### 5.3 获取报告 (`GET /api/tieban/timeline`)

* **Input**: `state_id`
* **Logic**:
1. 读取 `true_base`。
2. 运行 `Rollout Engine` (base + age*96)。
3. 查库返回完整时间轴。
