# 统一 Skill Data 架构

> Version: 1.0 | 2026-01-20
> 每个 Skill 在 VibeProfile 中单一入口、单一存储空间

---

## 1. 设计目标

```
┌─────────────────���───────────────────────────────────────────────────────────────────┐
│                              设计目标                                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

1. 单一入口
   - 每个 Skill 只有一个数据入口：skill_data.{skill_id}
   - 不再分散到 life_context._paths.{skill_id}、skill_state.{skill_id} 等

2. 自包含
   - Skill 的所有数据都在自己的命名空间内
   - 包括：计算结果、用户状态、协议进度、历史记录

3. 通用工具
   - save_skill_data / get_skill_data 工具适用于所有 Skill
   - Skill 不需要定义自己的保存工具

4. 向后兼容
   - 现有 skill_data 结构保持不变
   - 新增 _state 字段存储运行时状态
```

---

## 2. 数据结构设计

### 2.1 VibeProfile 整体结构

```
VibeProfile
├── basic_info          # 基础信息（姓名、生日等）
├── preferences         # 用户偏好
├── skill_data          # 【核心】所有 Skill 数据
│   ├── bazi            # 八字 Skill 数据
│   ├── zodiac          # 星座 Skill 数据
│   ├── lifecoach       # 生活教练 Skill 数据
│   └── {skill_id}      # 其他 Skill...
└── _meta               # 元数据
```

### 2.2 单个 Skill 数据结构

```yaml
# skill_data.{skill_id} 通用结构

skill_data:
  lifecoach:                    # Skill ID
    # ═══════════════════════════════════════════════════════════════
    # 计算/分析结果（Skill 特定）
    # ═══════════════════════════════════════════════════════════════
    north_star:                 # 北极星愿景
      vision: "..."
      anti_vision: "..."
      pain_points: ["..."]

    identity:                   # 身份转变
      old: "我是那种会拖延的人"
      new: "我是那种说到做到的人"

    # ═══════════════════════════════════════════════════════════════
    # 运行时状态（通用结构）
    # ═══════════════════════════════════════════════════════════════
    _state:
      current_protocol: "dankoe"      # 当前进行中的协议
      protocol_step: 3                # 协议进度（可选，LLM 可自行判断）
      last_interaction: "2026-01-20"  # 最后交互时间

    # ═══════════════════════════════════════════════════════════════
    # 元数据（自动管理）
    # ═══════════════════════════════════════════════════════════════
    _meta:
      version: 5
      created_at: "2026-01-15T10:00:00Z"
      updated_at: "2026-01-20T14:30:00Z"
```

### 2.3 各 Skill 数据示例

```yaml
skill_data:
  # ─────────────────────────────────────────────────────────────────
  # 八字 Skill
  # ─────────────────────────────────────────────────────────────────
  bazi:
    chart:                      # 八字盘
      year: { stem: "甲", branch: "子" }
      month: { stem: "丙", branch: "寅" }
      day: { stem: "戊", branch: "辰" }
      hour: { stem: "庚", branch: "午" }

    analysis:                   # 分析结果
      day_master: "戊土"
      strength: "身旺"
      useful_god: "金水"

    _state:
      last_query: "事业运势"
      last_interaction: "2026-01-20"

    _meta:
      version: 2
      updated_at: "2026-01-20T10:00:00Z"

  # ─────────────────────────────────────────────────────────────────
  # 星座 Skill
  # ─────────────────────────────────────────────────────────────────
  zodiac:
    natal_chart:                # 本命盘
      sun: { sign: "Leo", degree: 15 }
      moon: { sign: "Cancer", degree: 22 }
      ascendant: { sign: "Virgo", degree: 8 }

    current_transits:           # 当前行运
      saturn_return: false
      jupiter_transit: "10th house"

    _state:
      last_interaction: "2026-01-19"

    _meta:
      version: 1
      updated_at: "2026-01-19T16:00:00Z"

  # ─────────────────────────────────────────────────────────────────
  # 生活教练 Skill
  # ─────────────────────────────────────────────────────────────────
  lifecoach:
    north_star:
      vision: "成为独立创业者，时间自由，做有意义的事"
      anti_vision: "继续在大公司打工，每天通勤2小时"
      pain_points:
        - "工作没有意义感"
        - "没有时间陪家人"

    identity:
      old: "我是那种会等待完美时机的人"
      new: "我是那种边做边学的人"

    weekly:
      rocks:                    # 本周大石头
        - task: "完成产品原型"
          status: "in_progress"
        - task: "联系3个潜在客户"
          status: "pending"

    _state:
      current_protocol: null    # 无进行中的协议
      streak: 5                 # 连续打卡天数
      last_interaction: "2026-01-20"

    _meta:
      version: 8
      updated_at: "2026-01-20T14:30:00Z"
```

---

## 3. 工具设计

### 3.1 save_skill_data 工具

```yaml
# skills/core/tools/tools.yaml

- name: save_skill_data
  description: |
    保存当前 Skill 的数据到 VibeProfile。

    这是一个通用工具，所有 Skill 都可以使用。
    数据会保存到 VibeProfile.skill_data.{当前skill_id}

    调用时机：
    - 完成一个协议/流程后
    - 用户提供了重要信息需要记住
    - 状态发生变化需要持久化

    数据会自动与现有数据深度合并。

  tool_type: action
  parameters:
    - name: data
      type: object
      required: true
      description: |
        要保存的数据，会与现有数据深度合并。

        示例：
        {
          "north_star": {
            "vision": "成为独立创业者"
          },
          "_state": {
            "current_protocol": null
          }
        }

    - name: replace
      type: boolean
      default: false
      description: |
        是否完全替换（而非合并）。
        默认 false，即深度合并。
```

### 3.2 工具处理器实现

```python
# skills/core/tools/handlers.py

from typing import Dict, Any
from uuid import UUID
from datetime import datetime

@tool_handler("save_skill_data")
async def handle_save_skill_data(args: Dict, context: ToolContext) -> Dict:
    """
    通用的 Skill 数据保存工具

    自动处理：
    - 数据合并
    - 版本递增
    - 时间戳更新
    """
    data = args.get("data", {})
    replace = args.get("replace", False)
    skill_id = context.skill_id

    if not skill_id:
        return {"error": "No active skill", "success": False}

    if not data:
        return {"error": "No data provided", "success": False}

    user_uuid = UUID(context.user_id)

    # 获取现有数据
    current = await UnifiedProfileRepository.get_skill_data(user_uuid, skill_id) or {}

    if replace:
        new_data = data
    else:
        # 深度合并
        new_data = deep_merge(current, data)

    # 自动更新 _meta
    current_meta = current.get("_meta", {})
    new_data["_meta"] = {
        "version": current_meta.get("version", 0) + 1,
        "created_at": current_meta.get("created_at", datetime.utcnow().isoformat()),
        "updated_at": datetime.utcnow().isoformat()
    }

    # 保存
    await UnifiedProfileRepository.update_skill_data(user_uuid, skill_id, new_data)

    return {
        "success": True,
        "skill_id": skill_id,
        "version": new_data["_meta"]["version"]
    }


def deep_merge(base: Dict, update: Dict) -> Dict:
    """
    深度合并两个字典

    规则：
    - 如果 update 中的值是 dict，递归合并
    - 如果 update 中的值是 None，删除该键
    - 否则，update 的值覆盖 base
    """
    result = base.copy()

    for key, value in update.items():
        if value is None:
            # None 表示删除
            result.pop(key, None)
        elif isinstance(value, dict) and isinstance(result.get(key), dict):
            # 递归合并
            result[key] = deep_merge(result[key], value)
        else:
            # 覆盖
            result[key] = value

    return result
```

### 3.3 get_skill_data 工具（可选）

```yaml
# 通常不需要，因为 skill_data 已经在 context 中
# 但某些场景可能需要显式读取

- name: get_skill_data
  description: |
    获取当前 Skill 的数据。

    通常不需要调用，因为 skill_data 已经在 context 中。
    仅在需要刷新数据时使用。

  tool_type: query
  parameters:
    - name: path
      type: string
      required: false
      description: |
        可选的 JSON 路径，如 "north_star.vision"
        不提供则返回整个 skill_data
```

---

## 4. Context 集成

### 4.1 AgentContext 中的 skill_data

```python
# services/agent/core.py

@dataclass
class AgentContext:
    user_id: str
    profile: Dict[str, Any]      # 完整 VibeProfile
    skill_data: Dict[str, Any]   # 当前 Skill 的数据（快捷访问）
    history: List[Dict]
    skill: Optional[str]
    conversation_id: str

    @property
    def current_skill_data(self) -> Dict[str, Any]:
        """获取当前 Skill 的数据"""
        if not self.skill:
            return {}
        return self.profile.get("skill_data", {}).get(self.skill, {})
```

### 4.2 System Prompt 中注入 skill_data

```python
# services/agent/skill_loader.py

def build_skill_context(context: AgentContext) -> str:
    """构建 Skill 上下文，注入到 System Prompt"""

    if not context.skill:
        return ""

    skill_data = context.current_skill_data

    if not skill_data:
        return f"<skill_data skill=\"{context.skill}\">\n无历史数据\n</skill_data>"

    # 过滤掉 _meta，只保留业务数据
    display_data = {k: v for k, v in skill_data.items() if not k.startswith("_")}

    return f"""<skill_data skill="{context.skill}">
{yaml.dump(display_data, allow_unicode=True, default_flow_style=False)}
</skill_data>"""
```

### 4.3 完整 System Prompt 结构

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              System Prompt 结构                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘

Phase 2 (Skill 执行阶段):

┌─────────────────────────────────────────────────────────────────────────────────────┐
│ 1. Base Prompt (SKILL.md)                                                           │
│    - Skill 基础指令                                                                  │
│    - 角色定义                                                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ 2. Rules (rules/*.md)                                                               │
│    - 场景规则                                                                        │
│    - 协议流程（如 dankoe.md）                                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ 3. User Context                                                                     │
│    ┌─────────────────────────────────────────────────────────────────────────────┐  │
│    │ <user_profile>                                                              │  │
│    │   name: 张三                                                                │  │
│    │   birth_date: 1990-05-15                                                    │  │
│    │ </user_profile>                                                             │  │
│    │                                                                             │  │
│    │ <skill_data skill="lifecoach">                                              │  │
│    │   north_star:                                                               │  │
│    │     vision: "成为独立创业者"                                                 │  │
│    │     anti_vision: "继续打工"                                                  │  │
│    │   identity:                                                                 │  │
│    │     old: "我是那种会拖延的人"                                                │  │
│    │     new: "我是那种说到做到的人"                                              │  │
│    │   weekly:                                                                   │  │
│    │     rocks:                                                                  │  │
│    │       - task: "完成产品原型"                                                 │  │
│    │         status: "in_progress"                                               │  │
│    │ </skill_data>                                                               │  │
│    └─────────────────────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ 4. Tools                                                                            │
│    - save_skill_data                                                                │
│    - show_journey_card                                                              │
│    - Skill 特定工具...                                                              │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. 协议流程示例

### 5.1 Dan Koe 快速重置完整流程

```
用户: "我想做一次人生重置"
                │
                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Skill 选择                                                                  │
│                                                                                      │
│ LLM 调用 use_skill(skill="lifecoach")                                               │
│ → 加载 lifecoach SKILL.md + rules/dankoe.md                                         │
│ → 加载 skill_data.lifecoach 到 context                                              │
└─────────────────────────────────────────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ Phase 2: 协议执行（LLM 驱动）                                                         │
│                                                                                      │
│ System Prompt 包含：                                                                 │
│ - dankoe.md 中的 6 个问题流程                                                        │
│ - 用户现有的 skill_data（如果有）                                                    │
│                                                                                      │
│ LLM: "好的，我们来做一次快速重置。准备好了吗？"                                        │
│ 用户: "准备好了"                                                                     │
│ LLM: "第一个问题：过去一年，你持续的不满是什么？"                                      │
│ 用户: "工作没意义"                                                                   │
│ LLM: "这个感觉持续多久了？"                                                          │
│ 用户: "两年了"                                                                       │
│ LLM: "两年了，确实很长。第二个问题：如果5年后什么都不改变..."                          │
│ ...                                                                                  │
│ (6 个问题完成)                                                                       │
│                                                                                      │
│ LLM 调用 save_skill_data:                                                           │
│ {                                                                                   │
│   "data": {                                                                         │
│     "north_star": {                                                                 │
│       "vision": "成为独立创业者，时间自由",                                          │
│       "anti_vision": "继续在大公司打工，每天通勤2小时",                               │
│       "pain_points": ["工作没有意义感", "没有时间陪家人"]                             │
│     },                                                                              │
│     "identity": {                                                                   │
│       "old": "我是那种会等待完美时机的人",                                           │
│       "new": "我是那种边做边学的人"                                                  │
│     },                                                                              │
│     "weekly": {                                                                     │
│       "rocks": [                                                                    │
│         {"task": "完成产品原型", "status": "pending"},                              │
│         {"task": "联系3个潜在客户", "status": "pending"}                            │
│       ]                                                                             │
│     },                                                                              │
│     "_state": {                                                                     │
│       "current_protocol": null,                                                     │
│       "last_interaction": "2026-01-20"                                              │
│     }                                                                               │
│   }                                                                                 │
│ }                                                                                   │
│                                                                                      │
│ LLM 调用 show_journey_card 展示结果                                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘
                │
                ▼
            完成！
```

### 5.2 后续对话读取数据

```
用户: "我上次设定的愿景是什么？"
                │
                ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ CoreAgent 加载 context                                                               │
│                                                                                      │
│ skill_data.lifecoach 已在 System Prompt 中：                                         │
│                                                                                      │
│ <skill_data skill="lifecoach">                                                      │
│   north_star:                                                                       │
│     vision: "成为独立创业者，时间自由"                                               │
│     anti_vision: "继续在大公司打工，每天通勤2小时"                                    │
│   identity:                                                                         │
│     old: "我是那种会等待完美时机的人"                                                │
│     new: "我是那种边做边学的人"                                                      │
│ </skill_data>                                                                       │
│                                                                                      │
│ LLM 直接从 context 读取，回答：                                                       │
│ "你上次设定的愿景是：成为独立创业者，时间自由。                                        │
│  你想成为的新身份是：边做边学的人。"                                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. 迁移方案

### 6.1 从 life_context._paths 迁移

```python
# 迁移脚本示例

async def migrate_life_context_to_skill_data(user_uuid: UUID):
    """
    将旧的 life_context._paths 数据迁移到 skill_data
    """
    profile = await UnifiedProfileRepository.get_profile(user_uuid)

    if not profile:
        return

    life_context = profile.get("life_context", {})
    paths = life_context.get("_paths", {})

    if not paths:
        return

    # 迁移 lifecoach 数据
    if "lifecoach" in paths:
        old_data = paths["lifecoach"]
        new_data = {
            "north_star": old_data.get("north_star", {}),
            "identity": old_data.get("identity", {}),
            "weekly": old_data.get("current", {}).get("week", {}),
            "_meta": {
                "version": 1,
                "migrated_from": "life_context._paths",
                "migrated_at": datetime.utcnow().isoformat()
            }
        }
        await UnifiedProfileRepository.update_skill_data(user_uuid, "lifecoach", new_data)

    # 清理旧数据（可选）
    # await UnifiedProfileRepository.remove_life_context_paths(user_uuid)
```

### 6.2 兼容性处理

```python
# 在 skill_loader.py 中添加兼容性处理

def get_skill_data_with_fallback(profile: Dict, skill_id: str) -> Dict:
    """
    获取 skill_data，兼容旧的 life_context._paths 结构
    """
    # 优先从新位置读取
    skill_data = profile.get("skill_data", {}).get(skill_id, {})

    if skill_data:
        return skill_data

    # 回退到旧位置
    life_context = profile.get("life_context", {})
    paths = life_context.get("_paths", {})

    return paths.get(skill_id, {})
```

---

## 7. 最佳实践

### 7.1 数据设计原则

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              数据设计原则                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

1. 扁平优于嵌套
   ✅ skill_data.lifecoach.vision
   ❌ skill_data.lifecoach.goals.long_term.vision.description

2. 语义化命名
   ✅ north_star, identity, weekly
   ❌ data1, config, misc

3. 状态与数据分离
   - 业务数据：north_star, identity, weekly
   - 运行时状态：_state.current_protocol, _state.streak
   - 元数据：_meta.version, _meta.updated_at

4. 可选字段使用 null
   - 未设置的字段不存储
   - 显式清除使用 null

5. 数组使用对象数组
   ✅ rocks: [{task: "...", status: "..."}]
   ❌ rocks: ["task1", "task2"]
```

### 7.2 工具调用最佳实践

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              工具调用最佳实践                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

1. 增量更新
   只传递需要更新的字段，利用深度合并：

   save_skill_data({
     "data": {
       "weekly": {
         "rocks": [...]  // 只更新 weekly.rocks
       }
     }
   })

2. 协议完成时一次性保存
   不要每个问题都保存，协议完成后一次性保存所有数据

3. 状态更新
   使用 _state 字段存储运行时状态：

   save_skill_data({
     "data": {
       "_state": {
         "current_protocol": null,  // 协议完成
         "last_interaction": "2026-01-20"
       }
     }
   })

4. 删除字段
   使用 null 值删除字段：

   save_skill_data({
     "data": {
       "deprecated_field": null  // 删除此字段
     }
   })
```

---

## 8. 总结

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              架构总结                                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

核心设计：
─────────
每个 Skill 在 VibeProfile.skill_data.{skill_id} 有且仅有一个数据入口

数据结构：
─────────
skill_data.{skill_id}
├── {业务数据}      # Skill 特定的数据
├── _state          # 运行时状态
└── _meta           # 元数据（自动管理）

工具：
─────────
- save_skill_data   # 通用保存工具，所有 Skill 共用
- get_skill_data    # 可选，通常不需要

优势：
─────────
1. 简单 - 单一入口，无需记忆多个存储位置
2. 通用 - 一套工具适用所有 Skill
3. 灵活 - 深度合并支持增量更新
4. 可追溯 - _meta 自动记录版本和时间

与 Protocol 的关系：
─────────
Protocol（如 Dan Koe 快速重置）完成后，调用 save_skill_data 保存结果。
LLM 驱动对话流程，工具只负责持久化。
```
