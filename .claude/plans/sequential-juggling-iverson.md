# Ultra Analysis Report: CoreAgent v10 深度分析

## 用户确认的优先级

1. **最紧迫**：个性化路由（Phase 1 无画像）
2. **数据融合**：通过 vibe.insight 间接融合命盘数据
3. **Dashboard**：目前在 Chat 空状态中展示，后续决定

---

## 项目理解

CoreAgent v10 是 VibeLife 平台的核心智能体引擎，采用 **Context Engineering** 驱动架构。

**核心设计理念**：
- LLM 驱动路由（禁止 Python 硬编码）
- 分阶段上下文加载（Phase 1 轻量 / Phase 2 完整）
- 断点续传支持（SessionContext + Checkpoint）
- 三层 Profile 架构（Identity + Skills + Vibe）

---

## 时序图：完整数据流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          用户对话数据流                                      │
└─────────────────────────────────────────────────────────────────────────────┘

用户消息
    │
    ▼
┌───────────────┐
│  chat_v5.py   │ ── Phase 1: skill=None 时不加载 Profile
└───────────────┘
    │
    ▼
┌───────────────┐     ┌──────────────────────┐
│   CoreAgent   │────▶│  PromptBuilder.build │
└───────────────┘     └──────────────────────┘
    │                         │
    │                         ▼
    │                 ┌──────────────────────┐
    │                 │ _build_profile_context│ ◀── 读取 profile.vibe.insight
    │                 │                      │     读取 profile.vibe.target
    │                 │ 【问题2】只在 Phase 2  │     读取 profile.identity
    │                 │ 才注入，Phase 1 无画像 │
    │                 └──────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  LLM 调用工具                                                              │
│  └─ activate_skill(skill="lifecoach", rule="dankoe")                      │
│  └─ write_lifecoach_state(section="north_star", data={...})               │
│  └─ show_dankoe({vision, anti_vision, game_elements})                     │
└───────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  write_lifecoach_state → UnifiedProfileRepository.update_skill_data       │
│                                                                            │
│  写入路径: profile.skills.lifecoach.{section}                             │
│                                                                            │
│  【注意】没有自动同步到 profile.vibe.target                               │
└───────────────────────────────────────────────────────────────────────────┘
    │
    │  （无实时同步）
    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  ProfileExtractor (定时任务，每日 04:00)                                   │
│                                                                            │
│  输入: messages 表（最近 30 天）                                           │
│  输出: profile.vibe.insight + profile.vibe.target                         │
│                                                                            │
│  【问题3】数据滞后：新对话内容要等到次日凌晨才能被抽取                     │
└───────────────────────────────────────────────────────────────────────────┘
    │
    │  （隔天）
    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  前端请求                                                                  │
│                                                                            │
│  /api/journey → /api/v1/skills/lifecoach/state_read                       │
│      └─ 返回 skills.lifecoach 数据（north_star, goals 等）                │
│                                                                            │
│  /api/dashboard → MOCK_DATA（无真实数据！）                                │
│      └─ 【问题1】前端无法获取聚合数据                                     │
│                                                                            │
│  /api/profile → /api/v1/account/profile                                   │
│      └─ 返回完整 profile（但前端未充分利用）                              │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 问题识别

### 问题 1：前端数据获取不完整

**现状**：
```
/api/journey        → 存在，读取 skills.lifecoach（可用）
/api/dashboard      → 存在，但返回 MOCK_DATA（无真实数据）
/api/profile        → 存在，返回完整 profile（但前端未解析 vibe）
```

**问题**：
- Dashboard 页面返回硬编码 Mock 数据，用户无法看到真实的 lifecoach 状态
- 没有聚合端点同时返回 `skills.lifecoach` + `vibe.insight` + `vibe.target`

**代码证据** (`apps/web/src/app/api/dashboard/route.ts:27`):
```typescript
const MOCK_DASHBOARD: DashboardDTO = {
  userId: "mock-user",
  // ... 全是硬编码数据
};
```

---

### 问题 2：CoreAgent 个性化不足

**现状** (`apps/api/services/agent/prompt_builder.py:136-267`):
```python
def _build_profile_context(self, profile, skill_data, skill_id):
    # Layer 1: Identity（基础信息）- ✅ 正常注入
    # Layer 2: Skills（Skill 数据）- ✅ 正常注入
    # Layer 3: Vibe（用户画像）- ⚠️ 有读取但注入不完整
```

**问题**：
1. **Phase 1 无画像**：Skill 路由阶段（Phase 1）完全不加载 Profile，LLM 无法基于用户画像做智能路由
2. **vibe.insight 注入简化**：只注入了 archetype、traits、emotion 等基础字段
3. **lifecoach 不融合命盘**：Lifecoach Skill 无法获取 bazi/zodiac 数据来给出"命理化"建议

**代码证据** (`apps/api/routes/chat_v5.py:96-116`):
```python
async def get_user_context(user_id, skill=None):
    if not skill:
        # Phase 1: Skill 选择阶段，不需要 profile
        return {}, {}  # ← 完全空的！
```

---

### 问题 3：数据同步滞后

**现状**：
```
对话保存到 messages 表
    ↓ （等待）
ProfileExtractor 定时任务（每日 04:00）
    ↓
抽取到 vibe.insight + vibe.target
    ↓
下次对话才能用到新画像
```

**问题**：
- 用户今天完成 Dan Koe 协议，设定了北极星目标
- 直到明天凌晨 ProfileExtractor 运行后，这个目标才会出现在 vibe.target
- 期间 CoreAgent 无法知道用户的新目标

**代码证据** (`apps/api/workers/profile_extractor.py:332`):
```python
async def run_profile_extraction(days: int = 7, batch_size: int = 10):
    """运行 Profile 抽取任务"""
    # 这是定时任务，不是实时同步
```

---

## 建议方案

### 方案 A：实时画像同步（推荐）

```
save_skill_data → Profile 更新
                      ↓ （同步）
              sync_to_vibe_target
                      ↓
              profile.vibe.target 实时更新
```

**实现**：
1. 在 `write_lifecoach_state` 工具中添加 `sync_to_vibe` 逻辑
2. 关键数据（north_star, goals）立即同步到 vibe.target
3. ProfileExtractor 作为补充，处理非结构化对话内容

### 方案 B：Phase 1 轻量画像注入

**实现**：
1. Phase 1 时加载 vibe.target.focus（用户当前关注点）
2. 让 LLM 基于关注点做更智能的 Skill 路由

### 方案 C：Dashboard API 真实数据

**实现**：
1. 创建 `/api/v1/dashboard` 后端端点
2. 聚合返回：skills.lifecoach + vibe.insight + vibe.target + 今日运势
3. 前端 Dashboard 改为调用真实 API

---

## 未解决问题

1. **实时同步 vs 定时抽取的取舍**：实时同步增加写入复杂度，定时抽取有延迟
2. **Phase 1 画像注入的 token 成本**：注入太多会增加延迟
3. **lifecoach 融合命盘的方式**：直接注入 bazi.chart 还是只注入关键特征？
4. **Dashboard 聚合逻辑放前端还是后端**：性能 vs 维护成本
5. **用户期望的"个性化"程度是什么**：是基于命盘还是基于行为？

---

## 实施计划（基于用户确认）

### 整体流程图：P0 与 P1 的关系

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        数据流与两个优化的关系                                 │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────┐
                              │   用户对话       │
                              └────────┬────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           CoreAgent 执行                                      │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  【P1 优化点】PromptBuilder - 统一注入 VibeProfile                       │ │
│  │                                                                          │ │
│  │  所有阶段都注入:                                                          │ │
│  │  ├─ identity (用户基础信息)                                              │ │
│  │  ├─ vibe.insight (我是谁: archetype, chart_features, emotion)           │ │
│  │  └─ vibe.target (我要成为谁: north_star, goals, focus)                  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                       │                                       │
│                                       ▼                                       │
│                              LLM 生成回复                                     │
│                                       │                                       │
│                                       ▼                                       │
│                              调用 Skill 工具                                  │
│                     (calculate_bazi, write_lifecoach_state, ...)             │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                     UnifiedProfileRepository                                  │
│                                                                               │
│  update_skill_data(user_id, "bazi", {chart: {...}})                          │
│                          │                                                    │
│                          ▼                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  【P0 优化点】配置驱动同步                                                │ │
│  │                                                                          │ │
│  │  Before (硬编码):                After (配置驱动):                        │ │
│  │  if skill == "bazi":             config = load_sync_config()             │ │
│  │    sync_bazi_to_insight()        sync_skill_to_vibe(config, skill)       │ │
│  │  elif skill == "zodiac":                                                 │ │
│  │    sync_zodiac_to_insight()      配置文件: config/vibe_sync.yaml         │ │
│  │  elif skill == "lifecoach":                                              │ │
│  │    sync_lifecoach_to_target()                                            │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                          │                                                    │
│                          ▼                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  写入 skills.{skill_id}                                                  │ │
│  │       ↓ (自动触发)                                                        │ │
│  │  同步到 vibe.insight 或 vibe.target                                       │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ 下次对话
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  PromptBuilder 读取更新后的 vibe.insight / vibe.target                        │
│  → LLM 获得最新的用户画像                                                     │
└──────────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                              P0 与 P1 的关系
═══════════════════════════════════════════════════════════════════════════════

P0 (写入端优化)                         P1 (读取端优化)
┌─────────────────────────┐            ┌─────────────────────────┐
│ Skill 数据 → Vibe 同步   │            │ Vibe 数据 → Prompt 注入  │
│                         │            │                         │
│ 配置驱动，替代硬编码      │ ────────▶  │ 统一注入，不区分 Phase   │
│                         │   同步后   │                         │
│ vibe_sync.yaml          │   的数据   │ _build_vibe_context()   │
└─────────────────────────┘            └─────────────────────────┘

        ┌───────────────────────────────────────────────────────┐
        │                    VibeProfile                         │
        │                                                        │
        │  identity: {birth_info, display_name}                 │
        │                                                        │
        │  vibe:                                                 │
        │    insight: {essence, dynamic, pattern}  ◀── P0 写入   │
        │    target: {north_star, goals, focus}    ◀── P0 写入   │
        │                                                        │
        │               │                                        │
        │               ▼                                        │
        │         P1 统一读取                                    │
        └───────────────────────────────────────────────────────┘
```

---

### P0: Skill → Vibe 同步配置化（架构优化）

**目标**：将硬编码的 if-elif 同步逻辑改为配置驱动

**当前代码位置**：
- `apps/api/stores/unified_profile_repo.py:391-397` - 硬编码同步

**当前问题**：
```python
# 硬编码，违反开闭原则
if skill == "lifecoach":
    await sync_lifecoach_to_vibe_target(user_id)
elif skill == "bazi":
    await sync_bazi_to_vibe_insight(user_id)
elif skill == "zodiac":
    await sync_zodiac_to_vibe_insight(user_id)
```

**方案：Vibe 端配置驱动**

#### 1. 新建配置文件

```yaml
# config/vibe_sync.yaml

# Vibe 层统一定义：哪些 Skill 数据同步到 Vibe
# 位置：config/ 目录（与 models.yaml 同级）

version: "1.0"

# 同步目标定义
targets:
  insight:
    path: vibe.insight
    description: 用户画像（我是谁）
  target:
    path: vibe.target
    description: 用户目标（我要成为谁）

# Skill 同步映射
mappings:
  bazi:
    target: insight
    trigger: chart  # 当 skills.bazi.chart 有值时触发
    sync:
      # 命盘特征 → chart_features
      - source: chart.day_master
        dest: essence.chart_features.bazi.day_master
      - source: chart.five_elements
        dest: essence.chart_features.bazi.five_elements
      - source: chart.pattern
        dest: essence.chart_features.bazi.pattern
    # 原型映射（特殊处理）
    archetype:
      source_field: chart.day_master.element
      mapping:
        wood: {primary: "成长者", traits: ["创新", "进取", "仁慈"]}
        fire: {primary: "表达者", traits: ["热情", "领导", "直觉"]}
        earth: {primary: "稳定者", traits: ["务实", "包容", "信守"]}
        metal: {primary: "完善者", traits: ["精准", "公正", "坚韧"]}
        water: {primary: "智慧者", traits: ["灵活", "深思", "洞察"]}

  zodiac:
    target: insight
    trigger: chart
    sync:
      - source: chart.sun_sign
        dest: essence.chart_features.zodiac.sun_sign
      - source: chart.moon_sign
        dest: essence.chart_features.zodiac.moon_sign
      - source: chart.rising_sign
        dest: essence.chart_features.zodiac.rising_sign
      - source: chart.dominant_element
        dest: essence.chart_features.zodiac.dominant_element
    traits:
      source_field: chart.sun_sign
      # 星座 → 特质映射（简化版，完整版在代码中）

  lifecoach:
    target: target
    trigger: north_star  # 当有 north_star 时触发
    sync:
      - source: north_star
        dest: north_star
      - source: goals
        dest: goals
      - source: progress
        dest: milestones.streak
    focus:
      source_field: current.month.goal_id
      dest: focus.primary

  # 未来扩展
  jungastro:
    target: insight
    trigger: analysis
    sync:
      - source: analysis.archetype
        dest: essence.archetype.jung
```

#### 2. 新建同步执行器

```python
# services/vibe/sync_executor.py

"""
Vibe 同步执行器 - 配置驱动的 Skill → Vibe 同步

职责：
1. 加载 vibe_sync.yaml 配置
2. 根据配置执行字段映射
3. 处理特殊逻辑（archetype、traits）
"""

import yaml
import logging
from typing import Dict, Any, Optional
from pathlib import Path

logger = logging.getLogger(__name__)

# 配置缓存
_sync_config: Optional[Dict] = None


def load_sync_config() -> Dict:
    """加载同步配置"""
    global _sync_config
    if _sync_config is None:
        config_path = Path(__file__).parent.parent.parent / "config" / "vibe_sync.yaml"
        with open(config_path) as f:
            _sync_config = yaml.safe_load(f)
    return _sync_config


def get_nested_value(data: Dict, path: str) -> Any:
    """从嵌套字典中获取值，支持点号路径"""
    keys = path.split(".")
    value = data
    for key in keys:
        if isinstance(value, dict):
            value = value.get(key)
        else:
            return None
    return value


def set_nested_value(data: Dict, path: str, value: Any) -> None:
    """设置嵌套字典的值，支持点号路径"""
    keys = path.split(".")
    for key in keys[:-1]:
        data = data.setdefault(key, {})
    data[keys[-1]] = value


async def sync_skill_to_vibe(
    user_id: UUID,
    skill_id: str,
    skill_data: Dict[str, Any]
) -> bool:
    """
    根据配置同步 Skill 数据到 Vibe

    Returns:
        bool: 是否执行了同步
    """
    config = load_sync_config()
    mapping = config.get("mappings", {}).get(skill_id)

    if not mapping:
        logger.debug(f"No vibe sync config for skill: {skill_id}")
        return False

    # 检查触发条件
    trigger_field = mapping.get("trigger")
    if trigger_field and not get_nested_value(skill_data, trigger_field):
        logger.debug(f"Trigger field {trigger_field} not present, skipping sync")
        return False

    target = mapping.get("target")  # "insight" or "target"

    # 获取当前 vibe 数据
    if target == "insight":
        current_vibe = await UnifiedProfileRepository.get_vibe_insight(user_id)
    else:
        current_vibe = await UnifiedProfileRepository.get_vibe_target(user_id)

    current_vibe = current_vibe or {}

    # 执行字段映射
    for sync_rule in mapping.get("sync", []):
        source_path = sync_rule["source"]
        dest_path = sync_rule["dest"]
        value = get_nested_value(skill_data, source_path)
        if value is not None:
            set_nested_value(current_vibe, dest_path, value)

    # 处理 archetype 映射（bazi 特有）
    if "archetype" in mapping:
        arch_config = mapping["archetype"]
        source_value = get_nested_value(skill_data, arch_config["source_field"])
        if source_value and source_value in arch_config["mapping"]:
            arch_data = arch_config["mapping"][source_value]
            current_vibe.setdefault("essence", {})["archetype"] = {
                "primary": arch_data["primary"],
                "source": skill_id,
            }
            # 合并 traits
            # ... (traits 合并逻辑)

    # 写回 vibe
    if target == "insight":
        await UnifiedProfileRepository.update_vibe_insight(user_id, current_vibe)
    else:
        await UnifiedProfileRepository.update_vibe_target(user_id, current_vibe)

    logger.info(f"Synced {skill_id} to vibe.{target} for user {user_id}")
    return True
```

#### 3. 修改 Repository

```python
# unified_profile_repo.py

async def update_skill_data(user_id: UUID, skill: str, data: Dict) -> None:
    # ... 现有保存逻辑 ...

    # Skill → Vibe 同步（配置驱动，替代硬编码 if-elif）
    from services.vibe.sync_executor import sync_skill_to_vibe
    await sync_skill_to_vibe(user_id, skill, data)
```

#### 4. 文件结构

```
apps/api/
├── config/
│   ├── models.yaml          # 现有
│   └── vibe_sync.yaml       # 🆕 Vibe 同步配置
├── services/
│   └── vibe/                # 🆕 Vibe 服务模块
│       ├── __init__.py
│       └── sync_executor.py # 🆕 同步执行器
└── stores/
    └── unified_profile_repo.py  # 修改：调用 sync_executor
```

---

### P1: 统一 VibeProfile 注入（简化）

**目标**：所有阶段统一注入用户基础信息 + vibe（insight + target），不区分 Phase 1/Phase 2

**当前问题**：
```python
# chat_v5.py - Phase 1 不加载任何 Profile
async def get_user_context(user_id, skill=None):
    if not skill:
        return {}, {}  # ← 空的！
```

**简化方案**：

#### 1. 修改 chat_v5.py - 统一加载 VibeProfile

```python
# chat_v5.py

async def get_user_context(user_id: Optional[UUID], skill: Optional[str] = None) -> tuple:
    """
    获取用户上下文（统一加载，不区分 Phase）

    返回:
    - profile: {identity, vibe}  # 基础信息 + 画像
    - skill_data: {skill_id: {...}}  # Skill 专属数据（仅 Phase 2）
    """
    if not user_id:
        return {}, {}

    try:
        # 统一加载基础 Profile（identity + vibe）
        profile = await get_vibe_profile(user_id)

        # Phase 2: 额外加载 Skill 专属数据
        skill_data = {}
        if skill:
            result = await get_cached_profile_with_skill(user_id, skill)
            skill_data = result.get("skill_data", {})

        return profile, skill_data
    except Exception as e:
        logger.error(f"Failed to get user context: {e}")
        return {}, {}


async def get_vibe_profile(user_id: UUID) -> Dict[str, Any]:
    """
    获取 VibeProfile（所有阶段通用）

    返回: {identity, vibe}
    """
    from stores.unified_profile_repo import UnifiedProfileRepository

    full_profile = await UnifiedProfileRepository.get_profile(user_id)
    if not full_profile:
        return {}

    # 只返回 identity + vibe，不返回 skills
    return {
        "identity": full_profile.get("identity", {}),
        "vibe": full_profile.get("vibe", {}),
        "preferences": full_profile.get("preferences", {}),
    }
```

#### 2. 修改 prompt_builder.py - 统一注入方法

```python
# prompt_builder.py

class PromptBuilder:

    async def build(self, skill_id, rule_id, message, profile, skill_data, ...):
        parts = []

        # 1. Skill/Phase 1 基础 Prompt
        if skill_id:
            base_prompt = build_system_prompt(skill_id, rule_id, ...)
            parts.append(base_prompt)
        else:
            parts.append(get_phase1_prompt())

        # 2. 【统一注入】VibeProfile 上下文（所有阶段）
        vibe_context = self._build_vibe_context(profile)
        if vibe_context:
            parts.append(vibe_context)

        # 3. Skill 专属数据（仅 Phase 2）
        if skill_id and skill_data:
            skill_context = self._build_skill_data_context(skill_id, skill_data)
            if skill_context:
                parts.append(skill_context)

        # 4. 会话恢复上下文（如有）
        if session_context and session_context.has_checkpoint:
            parts.append(session_context.to_prompt_context())

        return "\n".join(parts)

    def _build_vibe_context(self, profile: Optional[Dict]) -> str:
        """
        构建 VibeProfile 上下文（所有阶段通用）

        注入内容:
        - identity: 用户基础信息（姓名、出生信息）
        - vibe.insight: 我是谁（archetype, chart_features, emotion）
        - vibe.target: 我要成为谁（north_star, goals, focus）
        """
        if not profile:
            return ""

        lines = ["\n## 用户画像\n"]

        # === Identity（基础信息）===
        identity = profile.get("identity", {})
        if identity.get("display_name"):
            lines.append(f"**用户**: {identity['display_name']}")

        birth_info = identity.get("birth_info", {})
        if birth_info.get("birth_date"):
            lines.append(f"**出生**: {birth_info.get('birth_date')} {birth_info.get('birth_time', '')}")

        # === Vibe.Insight（我是谁）===
        vibe = profile.get("vibe", {})
        insight = vibe.get("insight", {})

        if insight:
            essence = insight.get("essence", {})

            # 原型
            archetype = essence.get("archetype", {})
            if archetype.get("primary"):
                lines.append(f"**人格原型**: {archetype['primary']}")

            # 命盘特征
            chart_features = essence.get("chart_features", {})
            if chart_features:
                features = []
                if "bazi" in chart_features:
                    dm = chart_features["bazi"].get("day_master", {})
                    if dm.get("stem"):
                        features.append(f"八字日主{dm['stem']}")
                if "zodiac" in chart_features:
                    sun = chart_features["zodiac"].get("sun_sign")
                    if sun:
                        features.append(f"太阳{sun}")
                if features:
                    lines.append(f"**命盘**: {', '.join(features)}")

            # 当前状态
            dynamic = insight.get("dynamic", {})
            emotion = dynamic.get("emotion", {})
            if emotion.get("current"):
                lines.append(f"**情绪**: {emotion['current']}")

        # === Vibe.Target（我要成为谁）===
        target = vibe.get("target", {})

        if target:
            # 北极星
            north_star = target.get("north_star", {})
            vision = north_star.get("vision_scene") or north_star.get("statement")
            if vision:
                lines.append(f"**愿景**: {vision[:80]}{'...' if len(str(vision)) > 80 else ''}")

            # 当前目标
            goals = target.get("goals", [])
            active = [g.get("title") for g in goals if g.get("status") == "in_progress"][:3]
            if active:
                lines.append(f"**目标**: {', '.join(active)}")

            # 关注领域
            focus = target.get("focus", {})
            if focus.get("primary"):
                lines.append(f"**关注**: {focus['primary']}")

        if len(lines) == 1:  # 只有标题，没有内容
            return ""

        return "\n".join(lines)

    def _build_skill_data_context(self, skill_id: str, skill_data: Dict) -> str:
        """构建 Skill 专属数据上下文（仅 Phase 2）"""
        # 保留现有 _build_profile_context 中 Layer 2 的逻辑
        # ...
```

#### 3. 数据注入对比

| 阶段 | Before | After |
|------|--------|-------|
| Phase 1 (路由) | 不加载任何 Profile | identity + vibe (insight + target) |
| Phase 2 (执行) | identity + skills + vibe | identity + vibe + skill_data |

**Token 估算**：
- identity: ~30 tokens
- vibe.insight: ~50 tokens
- vibe.target: ~70 tokens
- **总计: ~150 tokens**（所有阶段统一）

**预期效果**：
- Phase 1：LLM 基于用户画像做智能 Skill 路由
- Phase 2：LLM 在 Skill 执行时也能参考用户画像
- 代码简化：不再区分两套加载逻辑

---

## 文件修改清单

### P0: Skill → Vibe 同步配置化（写入端）

| 文件 | 修改内容 |
|------|----------|
| `apps/api/config/vibe_sync.yaml` | **新建**：Vibe 同步配置 |
| `apps/api/services/vibe/__init__.py` | **新建**：Vibe 服务模块 |
| `apps/api/services/vibe/sync_executor.py` | **新建**：配置驱动的同步执行器 |
| `apps/api/stores/unified_profile_repo.py` | **修改**：删除硬编码 if-elif，调用 `sync_skill_to_vibe` |

### P1: 统一 VibeProfile 注入（读取端）

| 文件 | 修改内容 |
|------|----------|
| `apps/api/routes/chat_v5.py` | **修改**：`get_user_context` 统一加载 identity + vibe |
| `apps/api/services/agent/prompt_builder.py` | **新增**：`_build_vibe_context` 方法（替代分散的注入逻辑）|

### 可删除/简化的代码

| 文件 | 删除内容 |
|------|----------|
| `unified_profile_repo.py` | `sync_lifecoach_to_vibe_target` 方法 |
| `unified_profile_repo.py` | `sync_bazi_to_vibe_insight` 方法 |
| `unified_profile_repo.py` | `sync_zodiac_to_vibe_insight` 方法 |
| `prompt_builder.py` | `_build_profile_context` 中的分散注入逻辑（合并到 `_build_vibe_context`）|

---

## 验证方案

### 1. P0: 配置驱动同步测试

```python
# apps/api/scripts/test_vibe_sync.py

async def test_config_driven_sync():
    """测试配置驱动的 Skill → Vibe 同步"""
    user_id = await create_test_user()

    # 1. 保存 bazi 数据（触发配置驱动同步）
    await UnifiedProfileRepository.update_skill_data(user_id, "bazi", {
        "chart": {"day_master": {"stem": "甲", "element": "wood"}}
    })

    # 2. 验证 vibe.insight 已同步
    insight = await UnifiedProfileRepository.get_vibe_insight(user_id)
    assert insight["essence"]["chart_features"]["bazi"]["day_master"]["stem"] == "甲"
    assert insight["essence"]["archetype"]["primary"] == "成长者"

    # 3. 保存 lifecoach 数据
    await UnifiedProfileRepository.update_skill_data(user_id, "lifecoach", {
        "north_star": {"vision_scene": "成为独立创作者"}
    })

    # 4. 验证 vibe.target 已同步
    target = await UnifiedProfileRepository.get_vibe_target(user_id)
    assert target["north_star"]["vision_scene"] == "成为独立创作者"

    print("✅ P0: Config-driven sync test passed")
```

### 2. P1: 统一 VibeProfile 注入测试

```python
async def test_unified_vibe_injection():
    """测试所有阶段都注入 VibeProfile"""
    user_id = await create_test_user()

    # 设置用户画像
    await set_user_vibe(user_id, {
        "insight": {"essence": {"archetype": {"primary": "成长者"}}},
        "target": {"focus": {"primary": "career"}, "goals": [{"title": "转行"}]}
    })

    # Phase 1: 发送模糊消息（无 skill 参数）
    # 验证 System Prompt 中包含用户画像
    prompt = await build_system_prompt(user_id, skill_id=None)
    assert "成长者" in prompt
    assert "career" in prompt or "转行" in prompt

    # Phase 2: 指定 skill
    prompt = await build_system_prompt(user_id, skill_id="lifecoach")
    assert "成长者" in prompt  # 仍然包含画像

    print("✅ P1: Unified vibe injection test passed")
```

### 3. 端到端测试

```python
async def test_e2e_vibe_flow():
    """完整流程：写入 → 同步 → 读取 → 注入"""
    user_id = await create_test_user()

    # 1. 计算八字 → P0 自动同步到 vibe.insight
    await send_chat(user_id, "帮我排八字", skill="bazi")

    # 2. 新对话（Phase 1）→ P1 注入画像，LLM 应该知道用户是"成长者"
    response = await send_chat(user_id, "最近有点迷茫")
    # 验证路由结果考虑了用户画像

    # 3. 设置目标 → P0 自动同步到 vibe.target
    await send_chat(user_id, "帮我设定北极星", skill="lifecoach")

    # 4. 验证画像完整
    profile = await get_profile(user_id)
    assert profile["vibe"]["insight"]["essence"]["archetype"]["primary"] == "成长者"
    assert profile["vibe"]["target"]["north_star"] is not None

    print("✅ E2E test passed")
```

---

## 未解决问题

1. **archetype 映射冲突**：如果 bazi 和 zodiac 都计算了 archetype，以谁为准？
   - 建议：配置中定义优先级（bazi > zodiac）
2. **traits 合并策略**：多来源的 traits 如何合并？
   - 建议：保留 source 字段，按 intensity 排序
3. **配置热更新**：是否需要支持不重启服务更新配置？
   - 建议：暂不支持，需要重启
4. **迁移策略**：如何迁移现有 `sync_xxx` 方法中的逻辑到配置？
   - 建议：先保留方法，配置驱动后逐步删除
