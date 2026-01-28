# Fortune AI 系统彻底重构方案 v3

**版本**: v3.0 (2026-01-01)
**文档类型**: System Restructure Plan
**状态**: 设计完成，待实施
**核心架构**: Dynamic Profiling & Evolutionary Loop (Soul OS v4.0)
**关联文档**:
- [os_design_v3.md](./os_design_v3.md) - 架构设计
- [system_design_final_mvp_v3.md](../architech/system_design_final_mvp_v3.md) - 系统设计
- [modul_core_v3.md](./modul_core_v3.md) - 模块设计
- [frontend_final_v3.md](../frontend/frontend_final_v3.md) - 前端设计
- [GLOSSARY.md](../GLOSSARY.md) - 术语 SSOT

---

## 一、重构目标与核心理念

### 1.1 重构目标

将 Fortune AI 从 **静态四层架构** 升级为 **进化记忆系统 (Evolutionary Memory System)**：

| 维度 | 现状 (v3.x) | 目标 (v4.0) |
|------|-------------|-------------|
| **画像** | 注册时一次性采集 | 动态丰满，越用越准 |
| **上下文** | System Prompt + User Input | L0 + L1 + History Vector + User Input |
| **记忆** | 对话历史无结构化回写 | Insight Agent 萃取 → L0/L1 反写 |
| **模块** | 硬编码八字模块 | 可插拔多模块 (八字/紫微/星座/CBT/PERMA) |
| **风格** | 单一语气 | 三风格分支 (Standard/Warm/Roast) |
| **模型** | GLM 固定 | 多模型动态切换 (GLM/Gemini/GPT-4o/Claude) |

### 1.2 核心理念

```
+-----------------------------------------------------------------------------------+
|                            Soul OS Architecture v4.0                              |
|                       (Dynamic Profiling & Evolutionary Loop)                     |
+-----------------------------------------------------------------------------------+
                                       ^
                           1. 交互/响应 (Hot Path < 2s)
+-----------------------------------------------------------------------------------+
|  Interaction Layer (可配置模型层)                                                 |
+-----------------------------------------------------------------------------------+
|  [ Framework: Vercel SDK / LangChain ]                                            |
|  [ LLM Core:  GLM-4 / Gemini / GPT-4o / Claude ]  <-- 动态选择                    |
+-----------------------------------------------------------------------------------+
                                       ^
                                       | 组装后的 Context (Prompt + Data)
+-----------------------------------------------------------------------------------+
|  Context Management v4.0 (上下文管理与路由)                                       |
+-----------------------------------------------------------------------------------+
|   ^                                  ^                                        ^   |
|   | (Inject Style)                   | (Inject Expert Knowledge)              |   |
+---|----------------------------------|----------------------------------------|---+
    |                                  |
+---+----------------------------+ +---+----------------------------------------+---+
| L2: Style Agents (风格/语气)   | | L2: Expert Agents (专家模块/Prompt+知识库)     |
| (Prompt Templates)             | | (Domain Specific Prompts + Knowledge Base)     |
+--------------------------------+ +------------------------------------------------+
|                                | | [可插拔/Pluggable Modules]                     |
|  +----------+ +----------+     | |                                                |
|  | Standard | |  Warm    |     | | +--------+  +--------+  +--------+  +--------+ |
|  | (标准)   | | (温暖)   |     | | |  八字  |  |  紫微  |  |  星座  |  |  CBT   | |
|  +----------+ +----------+     | | | Agent  |  | Agent  |  | Agent  |  | Agent  | |
|  +----------+                  | | +--------+  +--------+  +--------+  +--------+ |
|  |  Roast   |                  | |                                                |
|  | (毒舌)   |                  | | +--------+  +--------+  +--------+             |
|  +----------+                  | | | PERMA  |  | Covey  |  | ...... |             |
|                                | | | Agent  |  | (7Hab) |  | (More) |             |
|                                | | +--------+  +--------+  +--------+             |
+--------------------------------+ +------------------------------------------------+
                                       ^
                                       | 2. 读取对应模块数据 (Hot Path)
                                       | 3. 反写更新 (Cold Path - 异步)
+--------------------------------------+--------------------------------------------+
| L1: Module Data Layer (各模块独立数据层)                                          |
| (Structured Data Schemas / JSON)                                                  |
+-----------------------------------------------------------------------------------+
|  [可插拔/Pluggable Data]                                                          |
|                                                                                   |
|  +-------------+   +-------------+   +-------------+   +-------------+            |
|  | 八字排盘数据|   | 紫微斗数盘  |   | 星座/星盘   |   | PERMA 量表  |            |
|  | (GanZhi)    |   | (Ziwei Map) |   | (Astro map) |   | (Scores)    |            |
|  +-------------+   +-------------+   +-------------+   +-------------+            |
|                                                                                   |
|  +-------------+   +-------------+   +-------------+                              |
|  | Covey 进度  |   | K线数据     |   | 其他业务数据|                              |
|  | (Habits)    |   | (OHLC)      |   | (Ext Data)  |                              |
|  +-------------+   +-------------+   +-------------+                              |
+-----------------------------------------------------------------------------------+
                                       ^
                                       | 基础依赖
+--------------------------------------+--------------------------------------------+
| L0: Base Data Layer (用户基础档案)                                                |
| (Global User Profile - 可反写/动态丰满)                                           |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|   +---------------------+    +---------------------+    +---------------------+   |
|   |      基础信息       |    |       用户偏好      |    |       当前状态      |   |
|   | (Basic Info: DOB/   |    | (Preferences: Tags/ |    | (Status: Mood/      |   |
|   |  Gender/Location)   |    |  Topics/Goals)      |    |  Lifecycle Stage)   |   |
|   +---------------------+    +---------------------+    +---------------------+   |
|                                                                                   |
|                       +---------------------------+                               |
|                       |         历史对话          |                               |
|                       | (Conversation History)    |                               |
|                       +---------------------------+                               |
+-----------------------------------------------------------------------------------+
                                       ^
                                       | 4. 洞察与更新 (Cold Path - 后台异步)
+--------------------------------------+--------------------------------------------+
| Insight & Memory Agent (洞察与记忆算子)                                           |
| (后台运行，从非结构化对话萃取结构化数据)                                          |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|   +-----------------------------------+    +-----------------------------------+   |
|   |   L0 Updates (画像丰满)           |    |   L1 Updates (模块数据积累)       |   |
|   | - profile.job = "PM"              |    | - bazi.运势解读历史              |   |
|   | - style_preference.roast = 0.8    |    | - perma.积极事件记录             |   |
|   | - current_status = "anxious"      |    | - cbt.触发器与应对策略           |   |
|   +-----------------------------------+    +-----------------------------------+   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 二、双路径设计 (Hot/Cold Path)

### 2.1 Hot Path (同步，< 2s)

```
用户输入
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│ Context Manager v4.0                                            │
│                                                                 │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐   │
│  │ L0 Base     │ + │ L1 Module   │ + │ History Vector      │   │
│  │ (画像/状态) │   │ (八字/PERMA)│   │ (相关对话检索)      │   │
│  └─────────────┘   └─────────────┘   └─────────────────────┘   │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ System Prompt + L2 Expert/Style Agent Prompts           │   │
│  └─────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Interaction Layer                                               │
│ [GLM-4 / Gemini / GPT-4o / Claude]                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
                          A2UI 响应
```

### 2.2 Cold Path (异步，后台)

```
对话完成
    │
    ▼ (异步触发)
┌─────────────────────────────────────────────────────────────────┐
│ Insight & Memory Agent                                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 分析最近 N 轮对话                                        │   │
│  │ 萃取：事实/偏好/情绪/状态变化/任务完成                   │   │
│  └───────────────────────────────┬─────────────────────────┘   │
│                                  │                              │
│  ┌───────────────────────────────┼───────────────────────────┐ │
│  │                               │                           │ │
│  ▼                               ▼                           │ │
│  ┌─────────────────┐   ┌─────────────────────────────────┐   │ │
│  │ L0 Updates      │   │ L1 Updates                      │   │ │
│  │ - job = "PM"    │   │ - perma.E += 0.1                │   │ │
│  │ - mood = "anxious"  │ - cbt.trigger = "presentation"  │   │ │
│  └─────────────────┘   └─────────────────────────────────┘   │ │
│                                                               │ │
└───────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    DB 更新 (fortune_user / fortune_*)
```

---

## 三、层次定义与职责

### 3.1 层次对照表

| 层级 | 名称 | 路径 | 可反写 | 职责 | 数据产出 |
|------|------|------|:------:|------|----------|
| **Interaction** | 模型交互层 | Hot | - | 多模型动态选择 (GLM/Gemini/GPT-4o/Claude) | `A2UI`, `Guidance Card` |
| **Context Mgmt** | 上下文组装 v4.0 | Hot | - | 组装 L0+L1+History+Input | `full_context` |
| **Insight Agent** | 洞察与记忆算子 | **Cold** | - | 从对话萃取结构化数据 | `l0_updates`, `l1_updates` |
| **L2 Expert** | 专家模块 | Hot | - | 业务逻辑/知识库 (可插拔) | `kb_refs`, `rule_ids` |
| **L2 Style** | 风格模块 | Hot | - | 语气/人设控制 | `tone` |
| **L1 Module** | 模块数据层 | Hot+Cold | ✅ | 可插拔数据 (八字/PERMA/K线) | `facts`, `perma`, `state_score` |
| **L0 Base** | 用户基座 | Hot+Cold | ✅ | 画像动态丰满 | `profile`, `tags`, `status` |

### 3.2 旧术语映射

| v3.x 术语 | v4.0 架构层级 | 说明 |
|-----------|--------------|------|
| L0 Firmware (数学脑/定数) | L0 Base + L1 Module | 八字计算移入 L1 Module |
| L1 Schema (心理脑/图式) | L1 Module Data | PERMA 移入可插拔模块 |
| L2 Agents (策略/超我) | L2 Expert + Style Agents | 分离为双分支 |
| L3 Synthesis (语言脑/自我) | Context Mgmt + Interaction | 拆分为组装与执行 |
| - (无) | **Insight Agent** | **新增**: Cold Path 洞察算子 |

---

## 四、可插拔模块设计

### 4.1 Expert Agents (L2)

| Agent ID | 名称 | 知识库 | 状态 | 输出 |
|----------|------|--------|:----:|------|
| `bazi` | 八字解读 | `bazi_kb_chunk` | ✅ 已实现 | 格局/大运/神煞分析 |
| `ziwei` | 紫微斗数 | `ziwei_kb_chunk` | ⏳ 待实现 | 12宫/主星/流年分析 |
| `astro` | 星座星盘 | `astro_kb_chunk` | ⏳ 待实现 | 本命盘/行运/合盘 |
| `cbt` | CBT 教练 | `cbt_kb_chunk` | ⏳ 待实现 | 认知重构/行为激活 |
| `perma` | 积极心理 | `perma_kb_chunk` | ✅ 已实现 | 五维评估/干预建议 |
| `covey` | 七习惯教练 | `covey_kb_chunk` | ⏳ 待实现 | 习惯养成/时间管理 |

### 4.2 Style Agents (L2)

| Style ID | 名称 | 语气特征 | 适用场景 |
|----------|------|----------|----------|
| `standard` | 标准 | 专业、客观、温和 | 默认模式 |
| `warm` | 温暖 | 共情、鼓励、治愈 | 情绪低落时 |
| `roast` | 毒舌 | 犀利、幽默、吐槽 | 用户选择/海报生成 |

### 4.3 Module Data (L1)

| Module ID | 名称 | 数据表 | Schema | 可插拔 |
|-----------|------|--------|--------|:------:|
| `bazi` | 八字排盘 | `fortune_bazi_snapshot` | GanZhi/十神/神煞 | ✅ |
| `ziwei` | 紫微斗数 | `fortune_ziwei_snapshot` | 12宫/主星/四化 | ✅ |
| `astro` | 星座星盘 | `fortune_astro_snapshot` | 行星/宫位/相位 | ✅ |
| `perma` | PERMA 量表 | `fortune_checkin` | P-E-R-M-A 五维 | ✅ |
| `kline` | 人生 K 线 | `fortune_kline_daily` | OHLC 蜡烛数据 | ✅ |
| `covey` | 七习惯进度 | `fortune_covey_progress` | 习惯完成率 | ✅ |

---

## 五、代码重构计划

### 5.1 目录结构调整

```
fortune_ai/
├── services/
│   ├── soul_os.py                  # 核心协调器 (重构)
│   │
│   ├── layers/
│   │   ├── __init__.py
│   │   ├── l0_base.py             # L0 用户基座 (新)
│   │   ├── l1_modules/            # L1 可插拔模块 (新)
│   │   │   ├── __init__.py
│   │   │   ├── bazi_module.py
│   │   │   ├── ziwei_module.py    # 待实现
│   │   │   ├── astro_module.py    # 待实现
│   │   │   ├── perma_module.py
│   │   │   ├── kline_module.py
│   │   │   └── covey_module.py    # 待实现
│   │   │
│   │   └── l2_agents/             # L2 双分支 Agents (新)
│   │       ├── __init__.py
│   │       ├── expert/
│   │       │   ├── bazi_agent.py
│   │       │   ├── ziwei_agent.py
│   │       │   ├── cbt_agent.py
│   │       │   └── perma_agent.py
│   │       └── style/
│   │           ├── standard_agent.py
│   │           ├── warm_agent.py
│   │           └── roast_agent.py
│   │
│   ├── context_manager.py         # Context Manager v4.0 (重构)
│   ├── insight_agent.py           # Insight & Memory Agent (新)
│   ├── interaction_layer.py       # 多模型交互层 (新)
│   │
│   └── (existing services...)
│
├── stores/
│   ├── l0_store.py                # L0 数据存储 (新)
│   ├── l1_store.py                # L1 数据存储 (新)
│   └── (existing stores...)
```

### 5.2 核心接口定义

```python
# services/layers/l1_modules/__init__.py

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

class BaseModule(ABC):
    """L1 可插拔模块基类"""

    module_id: str
    table_name: str

    @abstractmethod
    async def get_data(self, user_id: str) -> Dict[str, Any]:
        """Hot Path: 读取模块数据"""
        pass

    @abstractmethod
    async def update_data(self, user_id: str, updates: Dict[str, Any]) -> None:
        """Cold Path: Insight Agent 反写"""
        pass

    @abstractmethod
    def to_context(self, data: Dict[str, Any]) -> str:
        """将模块数据转换为 Context 片段"""
        pass


# services/layers/l2_agents/__init__.py

class BaseExpertAgent(ABC):
    """L2 专家模块基类"""

    agent_id: str
    kb_table: str

    @abstractmethod
    async def get_system_prompt(self, context: Dict[str, Any]) -> str:
        """生成专家模块的 System Prompt"""
        pass

    @abstractmethod
    async def search_kb(self, query: str) -> List[Dict]:
        """知识库检索"""
        pass


class BaseStyleAgent(ABC):
    """L2 风格模块基类"""

    style_id: str

    @abstractmethod
    def get_style_prompt(self) -> str:
        """获取风格指令"""
        pass

    @abstractmethod
    def transform_output(self, output: str) -> str:
        """可选: 输出风格转换"""
        pass
```

### 5.3 Context Manager v4.0

```python
# services/context_manager.py

class ContextManagerV4:
    """
    上下文组装工厂 v4.0

    组装顺序:
    1. L0 Base Data (画像/状态)
    2. L1 Module Data (相关模块)
    3. History Vector Search (相关对话)
    4. L2 Expert Agent Prompt
    5. L2 Style Agent Prompt
    6. User Input
    """

    async def build_context(
        self,
        user_id: str,
        user_input: str,
        active_modules: List[str],
        style: str = "standard"
    ) -> Dict[str, Any]:
        """
        构建完整上下文

        Returns:
            {
                "system_prompt": str,
                "l0_data": Dict,
                "l1_data": Dict,
                "history_refs": List[Dict],
                "full_context": str
            }
        """
        # 1. L0 Base Data
        l0_data = await self.l0_store.get_profile(user_id)

        # 2. L1 Module Data (仅加载激活的模块)
        l1_data = {}
        for module_id in active_modules:
            module = self.module_registry.get(module_id)
            if module:
                l1_data[module_id] = await module.get_data(user_id)

        # 3. History Vector Search
        history_refs = await self.vector_store.search(
            user_id=user_id,
            query=user_input,
            limit=5
        )

        # 4. L2 Expert Prompts
        expert_prompts = []
        for module_id in active_modules:
            agent = self.expert_registry.get(module_id)
            if agent:
                prompt = await agent.get_system_prompt(l1_data.get(module_id, {}))
                expert_prompts.append(prompt)

        # 5. L2 Style Prompt
        style_agent = self.style_registry.get(style, self.style_registry["standard"])
        style_prompt = style_agent.get_style_prompt()

        # 6. 组装
        full_context = self._assemble(
            l0_data=l0_data,
            l1_data=l1_data,
            history_refs=history_refs,
            expert_prompts=expert_prompts,
            style_prompt=style_prompt,
            user_input=user_input
        )

        return {
            "system_prompt": full_context,
            "l0_data": l0_data,
            "l1_data": l1_data,
            "history_refs": history_refs,
            "full_context": full_context
        }
```

### 5.4 Insight Agent

```python
# services/insight_agent.py

class InsightAgent:
    """
    洞察与记忆算子 (Cold Path)

    职责:
    1. 从非结构化对话萃取结构化数据
    2. 更新 L0 画像 (事实/偏好/状态)
    3. 更新 L1 模块数据 (进度/记录)
    """

    async def analyze_and_update(
        self,
        user_id: str,
        conversation_id: str,
        recent_messages: List[Dict]
    ) -> Dict[str, Any]:
        """
        分析对话并更新 L0/L1

        触发条件:
        - 对话结束后
        - 定时任务 (每小时)

        Returns:
            {
                "l0_updates": {...},
                "l1_updates": {...}
            }
        """
        # 1. 构建分析 Prompt
        analysis_prompt = self._build_analysis_prompt(recent_messages)

        # 2. 调用 LLM 进行萃取
        extraction = await self.llm.extract_structured(
            prompt=analysis_prompt,
            schema=InsightExtractionSchema
        )

        # 3. 更新 L0
        if extraction.profile_updates:
            await self.l0_store.update_profile(user_id, extraction.profile_updates)

        if extraction.preference_updates:
            await self.l0_store.update_preferences(user_id, extraction.preference_updates)

        if extraction.status_updates:
            await self.l0_store.update_status(user_id, extraction.status_updates)

        # 4. 更新 L1
        for module_id, updates in extraction.module_updates.items():
            module = self.module_registry.get(module_id)
            if module:
                await module.update_data(user_id, updates)

        return {
            "l0_updates": {
                "profile": extraction.profile_updates,
                "preferences": extraction.preference_updates,
                "status": extraction.status_updates
            },
            "l1_updates": extraction.module_updates
        }

    def _build_analysis_prompt(self, messages: List[Dict]) -> str:
        """构建洞察分析 Prompt"""
        return f"""
分析以下对话，萃取用户信息更新：

## 对话内容
{self._format_messages(messages)}

## 萃取任务

### L0 画像更新
- 职业/身份 (如果用户提及)
- 兴趣偏好 (如果可推断)
- 当前状态/情绪 (如果明显)

### L1 模块数据更新
- 任务完成情况
- 情绪事件记录
- CBT 触发器识别
- 目标进度变化

请以 JSON 格式返回萃取结果。
"""
```

---

## 六、数据库 Schema 变更

### 6.1 L0 Base Data 扩展

```sql
-- 20260101_l0_expansion.sql

-- 用户画像动态字段 (JSONB)
ALTER TABLE fortune_user
ADD COLUMN IF NOT EXISTS dynamic_profile JSONB DEFAULT '{}';

-- 用户偏好扩展
ALTER TABLE fortune_user_preferences
ADD COLUMN IF NOT EXISTS style_preference JSONB DEFAULT '{"default": "standard"}',
ADD COLUMN IF NOT EXISTS active_modules TEXT[] DEFAULT ARRAY['bazi', 'perma'],
ADD COLUMN IF NOT EXISTS insight_enabled BOOLEAN DEFAULT TRUE;

-- 用户状态表 (Cold Path 更新)
CREATE TABLE IF NOT EXISTS fortune_user_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES fortune_user(id),
    current_mood TEXT,
    mood_intensity FLOAT,
    lifecycle_stage TEXT,
    recent_topics TEXT[],
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by TEXT DEFAULT 'insight_agent'
);

CREATE INDEX idx_user_status_user ON fortune_user_status(user_id);
```

### 6.2 L1 Module Data 新表

```sql
-- 20260101_l1_modules.sql

-- 紫微斗数快照 (待实现)
CREATE TABLE IF NOT EXISTS fortune_ziwei_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES fortune_user(id),
    palace_data JSONB NOT NULL,  -- 12宫数据
    major_stars JSONB,           -- 主星配置
    transformations JSONB,       -- 四化信息
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 星座星盘快照 (待实现)
CREATE TABLE IF NOT EXISTS fortune_astro_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES fortune_user(id),
    natal_chart JSONB NOT NULL,  -- 本命盘
    planets JSONB,               -- 行星位置
    houses JSONB,                -- 宫位信息
    aspects JSONB,               -- 相位信息
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Covey 七习惯进度 (待实现)
CREATE TABLE IF NOT EXISTS fortune_covey_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES fortune_user(id),
    habit_id INT NOT NULL,       -- 1-7
    progress FLOAT DEFAULT 0,    -- 0-100
    last_practice TIMESTAMPTZ,
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insight Agent 更新日志
CREATE TABLE IF NOT EXISTS fortune_insight_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL REFERENCES fortune_user(id),
    conversation_id UUID,
    l0_updates JSONB,
    l1_updates JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 七、实施路线图

### 7.1 Phase 1: 基础重构 (Week 1-2)

| 任务 | 优先级 | 状态 | 负责模块 |
|------|:------:|:----:|----------|
| 创建 `layers/` 目录结构 | P0 | ⏳ | 架构 |
| 实现 `BaseModule` 抽象类 | P0 | ⏳ | L1 |
| 迁移 `bazi_module.py` | P0 | ⏳ | L1 |
| 迁移 `perma_module.py` | P0 | ⏳ | L1 |
| 实现 `l0_base.py` | P0 | ⏳ | L0 |
| 实现 `ContextManagerV4` | P0 | ⏳ | Context |

### 7.2 Phase 2: Cold Path 实现 (Week 2-3)

| 任务 | 优先级 | 状态 | 负责模块 |
|------|:------:|:----:|----------|
| 实现 `InsightAgent` | P0 | ⏳ | Insight |
| 创建 `fortune_insight_log` 表 | P0 | ⏳ | DB |
| 实现 L0 反写接口 | P1 | ⏳ | L0 |
| 实现 L1 反写接口 | P1 | ⏳ | L1 |
| 添加后台任务触发 | P1 | ⏳ | Infra |

### 7.3 Phase 3: 多模块扩展 (Week 3-4)

| 任务 | 优先级 | 状态 | 负责模块 |
|------|:------:|:----:|----------|
| 实现 `ziwei_module.py` | P2 | ⏳ | L1 |
| 实现 `astro_module.py` | P2 | ⏳ | L1 |
| 实现 `covey_module.py` | P2 | ⏳ | L1 |
| 创建对应知识库表 | P2 | ⏳ | DB |
| 实现对应 Expert Agents | P2 | ⏳ | L2 |

### 7.4 Phase 4: 风格系统 (Week 4-5)

| 任务 | 优先级 | 状态 | 负责模块 |
|------|:------:|:----:|----------|
| 实现 `standard_agent.py` | P1 | ⏳ | L2 Style |
| 实现 `warm_agent.py` | P1 | ⏳ | L2 Style |
| 实现 `roast_agent.py` | P1 | ⏳ | L2 Style |
| 前端风格切换 UI | P1 | ⏳ | Frontend |
| 用户偏好保存 | P1 | ⏳ | L0 |

### 7.5 Phase 5: 多模型支持 (Week 5-6)

| 任务 | 优先级 | 状态 | 负责模块 |
|------|:------:|:----:|----------|
| 实现 `interaction_layer.py` | P1 | ⏳ | Interaction |
| 集成 Gemini | P2 | ⏳ | Interaction |
| 集成 GPT-4o | P2 | ⏳ | Interaction |
| 集成 Claude | P2 | ⏳ | Interaction |
| 模型路由策略 | P2 | ⏳ | Interaction |

---

## 八、风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| Cold Path 延迟导致数据不一致 | 中 | 中 | 添加版本号/时间戳，前端乐观更新 |
| Insight Agent 萃取质量不稳定 | 高 | 中 | 人工审核抽样，置信度阈值 |
| 模块热插拔导致依赖问题 | 中 | 低 | 严格接口定义，模块注册机制 |
| 多模型切换成本控制 | 高 | 中 | 分层路由，默认 GLM，高价值场景用 Claude |
| 画像数据隐私合规 | 高 | 低 | 用户可查看/删除，数据脱敏 |

---

## 九、验收标准

### 9.1 功能验收

| 功能 | 验收条件 |
|------|----------|
| Hot Path | 对话响应 < 2s，上下文完整包含 L0+L1 |
| Cold Path | Insight Agent 后台运行，L0/L1 正确更新 |
| 模块可插拔 | 新增模块仅需实现接口，无需修改核心代码 |
| 风格切换 | 用户可选 standard/warm/roast，输出风格明显不同 |
| 画像丰满 | 使用 7 天后，用户画像自动补充 ≥3 个字段 |

### 9.2 性能验收

| 指标 | 目标 |
|------|------|
| Hot Path P95 延迟 | < 2000ms |
| Cold Path 处理延迟 | < 30s |
| Context 组装延迟 | < 200ms |
| Vector Search 延迟 | < 100ms |

---

## 十、版本历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-01 | v3.0 | 初始版本，定义 v4.0 Evolutionary Memory 架构重构方案 |
