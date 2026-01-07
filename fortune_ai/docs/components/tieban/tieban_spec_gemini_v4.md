# 铁板神算 (Tieban) 系统设计规格书 v4.0

**版本**: 4.0
**日期**: 2025-12-22
**状态**: 正式设计
**适用范围**: Fortune AI 系统 Tieban 独立模块

---

## 1. 系统概述 (System Overview)

铁板神算 (Tieban) 是中国古代术数中精度最高、逻辑最封闭的命理系统之一。不同于子平八字（Bazi）侧重五行生克的模拟量分析，铁板神算本质上是一个基于**多变量哈希 (Multi-variable Hashing)** 的离散化条文索引系统。

本设计 v4.0 旨在构建一个**完全独立**的 Tieban 模块，不依赖 Shaozi 算法，拥有独立的运算逻辑、条文数据库（12,000条）和考刻验证流程。同时, 本设计将阐述如何将 Tieban 融入 Fortune AI 的整体架构，实现多模块共存与用户系统的升级。

### 1.1 核心价值
*   **高精度验证**: 通过“考刻分”机制，将出生时间锁定至“分”级，输出确定性的六亲（父母、兄弟、配偶）特征。
*   **确定性推演**: 一旦“基数 (Base Code)”锁定，一生的流年轨迹即为确定性序列，提供具体的吉凶描述。
*   **数字化复原**: 将传统的算盘口诀转化为计算机可执行的确定性算法。

---

## 2. 系统架构设计 (System Architecture)

系统采用分层微服务/模块化架构，嵌入 Fortune AI 整体生态。

```mermaid
graph TD
    User[用户/客户端] --> API[统一网关 (Fortune API)]
    API --> Manager[任务调度 (Task Manager)]
    
    subgraph "Fortune AI Core"
        Store[用户中心 (User Store)]
        KB[通用知识库]
    end
    
    subgraph "Tieban Module (Independent)"
        Engine[运算引擎 (Calc Engine)]
        Calibrator[考刻交互 (Calibration)]
        Projector[推演引擎 (Projection)]
        TiebanKB[铁板数据库 (12000条文)]
    end
    
    Manager -- 1.请求考刻 --> Calibrator
    Calibrator -- 读写 --> TiebanKB
    Calibrator -- 更新状态 --> Store
    
    Manager -- 2.请求推演 --> Projector
    Projector -- 调用 --> Engine
    Engine -- 查表 --> TiebanKB
    Projector -- 生成报告 --> Manager
```

### 2.1 模块职责
1.  **Tieban Engine (运算引擎)**: 负责太玄数计算、干支转码、八卦加则运算。提供纯函数式的计算服务。
2.  **Calibrator (考刻交互)**: 负责生成“刻分假设”，与用户进行多轮问答（父母生肖、兄弟数量等），锁定 `Verified_Ke`。
3.  **Projector (推演引擎)**: 基于锁定的刻分和基数，批量生成终身流年条文。
4.  **Tieban KB (知识库)**: 存储 12,000 条文、太玄数映射表、八卦加则参数表。

---

## 3. 核心算法与计算流程 (Algorithms)

铁板神算的核心在于求出查询条文的 **索引数 (Index/ID)**。

### 3.1 基础常量定义

**太玄数映射 (Taixuan Map)**:
```python
TAIXUAN = {
    "甲": 9, "己": 9, "子": 9, "午": 9,
    "乙": 8, "庚": 8, "丑": 8, "未": 8,
    "丙": 7, "辛": 7, "寅": 7, "申": 7,
    "丁": 6, "壬": 6, "卯": 6, "酉": 6,
    "戊": 5, "癸": 5, "辰": 5, "戌": 5,
    "巳": 4, "亥": 4
}
```

**八卦加则基数 (Hexagram Base)**:
*   上卦数 (Head): 乾6, 兑7, 离9, 震3, 巽4, 坎1, 艮8, 坤2
*   下卦数 (Tail): 同上 (作为运算中的减项或尾数)

### 3.2 算法一：八卦加则法 (Verification / 考刻专用)

此算法用于反推基数，生成父母条文供验证。

**Step-by-Step 计算过程**:

1.  **起卦 (Cast Hexagram)**:
    *   将四柱（年、月、日、时）的天干地支数相加，取余起卦。或直接使用“先天卦序”：
    *   例：日干支为 **壬申**。
    *   壬(6) + 申(7) = 13。
    *   上卦: 13 % 8 = 5 (巽)
    *   下卦: (13 + 时支数) % 8 ... (此处可依据具体流派调整，假设为 坎)
    *   得卦: **风水涣 (巽上坎下)**。

2.  **计算基数 (Calculate Base)**:
    *   口诀: “爻从三十起 (Base=3000), 巽卦四为头 (Head=4), 坎卦一为尾 (Tail=1)”。
    *   **公式**: $Base = 3000 + (Head \times 100) + (Tail \times 1) + Adjustment$
    *   初算: $3000 + 400 + 1 = 3401$。

3.  **引入刻分 (Apply Ke/Fen)**:
    *   一时辰分8刻，每刻对应一个修正值 $K_i$ (0~7)。
    *   假设出生在 **巳时三刻** ($K=2$)。
    *   修正公式: $Index = Base + (K \times Step)$ (Step通常为6或12)
    *   $Index = 3401 + (2 \times 6) = 3413$。

4.  **查库**: 查询 ID=3413 的条文。
    *   若库中 3413 内容为: “父蛇母猪”，与用户事实不符，则尝试下一刻 K=3。

### 3.3 算法二：四柱天干滚盘法 (Projection / 流年专用)

此算法用于在锁定基数后，推导一生的流年。

1.  **四柱取数**:
    *   年(Y), 月(M), 日(D), 时(H) 的天干太玄数。
    *   例：甲(9) 子(9) | 丙(7) 寅(7) | ...
    *   $Sum = \sum T(Stem) + \sum T(Branch)$

2.  **大运流转**:
    *   起运基数 $B_{luck} = Verified\_Base$ (来自考刻结果)。
    *   每10年一大运，大运数 $Luck_n = B_{luck} + (n \times 96)$ (模12000)。

3.  **流年细推**:
    *   某流年 (如 2025 乙巳):
    *   $Year\_Val = T(乙) + T(巳) = 8 + 4 = 12$。
    *   $Fortune\_ID = Luck_n \pm Year\_Val$ (阳男阴女加，阴男阳女减)。
    *   **结果**: 得到该年的条文 ID，如 5678 "财源广进"。

---

## 4. 知识库设计 (Knowledge Base)

独立于 Shaozi 洛阳条文，Tieban 拥有自己的 12,000 条文库。

### 4.1 数据库 Schema (SQL)

```sql
-- 铁板条文主表
CREATE TABLE tieban_verses (
    id INTEGER PRIMARY KEY,          -- 1 ~ 12000
    content TEXT NOT NULL,           -- 条文内容 "父鼠母马..."
    category VARCHAR(20),            -- 类型: VERIFICATION, FORTUNE, CHARACTER
    
    -- 结构化元数据 (用于考刻匹配)
    meta_info JSONB,                 
    -- 示例: {"F": "子", "M": "午", "siblings": 3, "age": 35}
    
    source_version VARCHAR(50)       -- 版本来源 (e.g., "Jiangnan_12k")
);

-- 索引加速查询
CREATE INDEX idx_tieban_meta ON tieban_verses USING GIN (meta_info);

-- 算法参数配置表 (支持多流派切换)
CREATE TABLE tieban_rules (
    rule_key VARCHAR(50) PRIMARY KEY,
    rule_value JSONB
);
-- 示例: key="hexagram_base_map", value={"Qian": 6000, "Kun": 2000...}
```

### 4.2 JSON 数据结构示例

**条文数据 (Verse)**:
```json
{
  "id": 3413,
  "content": "父命属蛇母属猪，门前枯树凤来仪。",
  "category": "VERIFICATION",
  "meta_info": {
    "parents": {
      "father": "巳",
      "mother": "亥"
    }
  }
}
```

---

## 5. User System Upgrade (fortune_user 2.0)

为了容纳 Bazi, Tieban, Shaozi 等多个并列模块，`fortune_user` 表需要从单一的“八字用户”升级为“综合命理用户”。

### 5.1 数据库变更策略

不建议为每个模块建立单独的 User 表，而是利用 JSONB 的灵活性在主表中存储各模块的**状态 (State)**。

**Schema Update**:
```sql
ALTER TABLE fortune_user
    -- 基础人口学特征 (所有模块通用)
    ADD COLUMN IF NOT EXISTS gender VARCHAR(10),        -- 'M'/'F'
    ADD COLUMN IF NOT EXISTS birth_precision INTEGER,   -- 出生时间精度等级 (1:时辰, 2:刻, 3:分)
    
    -- 模块化状态存储 (核心设计)
    ADD COLUMN IF NOT EXISTS module_states JSONB;
```

### 5.2 `module_states` 数据结构

```json
{
  "bazi": {
    "structure": "食神制杀",
    "strength": "Strong"
  },
  "tieban": {
    "status": "CALIBRATED",      // UNINIT, CALIBRATING, CALIBRATED
    "base_code": 3413,           // 锁定的核心命数
    "verified_ke": 2,            // 锁定的刻分 (0-7)
    "verified_fen": 5,           // 锁定的分 (0-14, optional)
    "verification_log": [        // 考刻历史
      {"q": "parents", "a": "snake_pig", "timestamp": "..."}
    ]
  },
  "shaozi": {
    "status": "UNINIT",
    "sound_code": "gong_yin"     // 声音考刻结果
  }
}
```

### 5.3 兼容性与扩展性
*   **兼容性**: 旧代码读取 `bazi_digest` 不受影响。新 Tieban 模块只需读写 `module_states['tieban']`。
*   **扩展性**: 未来增加 `Ziwei` (紫微斗数) 模块，只需在 JSON 中增加 `ziwei` 键，无需修改表结构。

---

## 6. 集成实施计划 (Implementation Plan)

### Phase 1: 基础建设
1.  建立 `tieban_verses` 表，并导入 12,000 条文数据（需ETL脚本清洗）。
2.  更新 `fortune_user` 表结构，添加 `module_states`。

### Phase 2: 引擎开发
1.  实现 `TiebanEngine` 类：
    *   `get_taixuan_sum(pillars)`
    *   `get_hexagram_code(pillars)`
2.  实现考刻逻辑：`generate_calibration_options(pillars) -> List[Option]`。

### Phase 3: 业务流程
1.  开发 API `/api/tieban/calibrate`：前端展示父母生肖选项。
2.  开发 API `/api/tieban/lock`：用户确认后，写入 `module_states['tieban']`。
3.  开发 API `/api/tieban/timeline`：基于锁定参数，输出流年列表。

### Phase 4: 前端适配
1.  在用户详情页增加 "Tieban Calibration" Tab。
2.  设计交互式向导：选择父母生肖 -> 锁定刻分 -> 展示终身运势。

---

## 7. 结语

本设计 v4.0 确立了 Tieban 作为 Fortune AI 独立一等公民的地位。通过精细的考刻算法和灵活的 JSON 状态存储，我们能够在不破坏现有架构的前提下，引入这一高精度的中国传统预测系统。

```