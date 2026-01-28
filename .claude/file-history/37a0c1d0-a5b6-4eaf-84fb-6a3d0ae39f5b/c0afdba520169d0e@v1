# VibeProfile Extractor - LLM-First 重构设计文档

## 1. 概述

### 1.1 目标

将 VibeProfile Extractor 从独立服务模式转型为 **Agent-Native 架构**，完全符合 LLM-First 原则。

### 1.2 核心变更

| 维度 | Before | After |
|------|--------|-------|
| **触发方式** | cron/hook | LLM 自主调用 save 工具 |
| **配置位置** | `vibe_extract.json` | `core/rules/profile.md` |
| **Merge 逻辑** | Python 硬编码 | LLM 自主决定 |
| **数据结构** | 混乱的多层结构 | 统一的 vibe schema |

---

## 2. Vibe Schema v2.0

### 2.1 Schema 定义

```yaml
# Vibe Profile Schema v2.0
# Agent-Native，LLM 可读的结构定义

version: "2.0"
description: "用户画像数据结构，由 LLM 通过 save 工具写入"

schema:
  vibe:
    profile:
      description: "稳定画像（变化缓慢）"
      fields:
        identity:
          archetypes: ["string"]     # 人格原型，最多 3 个
          traits: ["string"]          # 核心特质，最多 5 个
          style: "string"             # 沟通风格
        context:
          occupation: "string"
          life_stage: "enum:student|early_career|growth|peak|transition"
          interests: ["string"]

    state:
      description: "当前状态（实时变化）"
      fields:
        emotion: "enum:anxious|sad|neutral|content|excited|focused"
        energy: "enum:low|medium|high"
        focus: ["string"]            # 当前关注话题

    goals:
      description: "目标列表"
      type: "array"
      max_items: 10
      item:
        title: "string"
        category: "enum:career|health|relationship|wealth|growth"
        status: "enum:active|paused|completed"

    timeline:
      description: "重要事件（追加存储）"
      type: "array"
      max_items: 100
      item:
        date: "date"
        type: "enum:goal|decision|milestone|life_event"
        event: "string"
```

### 2.2 数据结构对比

**Before（v13 三层存储）**：
```yaml
vibe:
  current:      # Hot Layer
  profile:      # Warm Layer
  timeline:     # Cold Layer
  insight:      # 旧结构遗留
  target:       # 旧结构遗留
  relationship: # 关系数据
```

**After（v2.0 统一结构）**：
```yaml
vibe:
  profile:      # 稳定画像（identity, context）
  state:        # 当前状态（emotion, energy, focus）
  goals:        # 目标列表
  timeline:     # 重要事件
```

---

## 3. LLM 信息保存规则

### 3.1 规则文件位置

`apps/api/skills/core/rules/profile.md`

### 3.2 规则内容

```markdown
# 用户信息保存规则

## 何时保存

当用户在对话中**主动提供**以下信息时，调用 save 保存：

| 用户说 | 保存路径 | 示例数据 |
|-------|---------|---------|
| "我是设计师" | vibe.profile.context.occupation | "设计师" |
| "我现在很焦虑" | vibe.state.emotion | "anxious" |
| "我的目标是..." | vibe.goals | {title, status: "active"} |

## 保存流程

1. **识别信息类型**：判断是稳定特质还是临时状态
2. **读取现有数据**：`read(path="vibe.xxx")`
3. **决定合并方式**：
   - 单值字段（emotion）：直接覆盖
   - 数组字段（goals）：追加或更新
4. **写入数据**：`save(path, merged_data)`

## 不保存的情况

- 第三方信息（"帮我朋友测"）
- 假设性问题（"如果我是..."）
- 临时测试（"试试看"）
```

---

## 4. 工具重构

### 4.1 save 工具增强

**修改文件**：`apps/api/skills/core/tools/tools.yaml`

```yaml
action:
  - name: save
    description: |
      保存用户信息到 Profile。

      ## 保存规则（LLM 自主执行）

      1. **识别用户信息**：当用户主动提供个人信息时
         - "我是1990年出生" → 用户自己的信息 → 保存
         - "帮我朋友测" → 第三方信息 → 不保存

      2. **读取现有数据**：先调用 read 获取当前值

      3. **决定合并方式**：
         - 覆盖：新值替换旧值
         - 追加：添加到数组（如 goals、traits）
         - 更新：部分字段更新

      4. **调用 save**：写入最终结果

    parameters:
      - name: path
        type: string
        required: true
        description: |
          支持的路径：
          - vibe.profile.identity.archetypes
          - vibe.profile.identity.traits
          - vibe.profile.identity.style
          - vibe.profile.context.occupation
          - vibe.state.emotion
          - vibe.state.energy
          - vibe.state.focus
          - vibe.goals
          - vibe.timeline

      - name: data
        type: any
        required: true
```

### 4.2 路径白名单更新

**修改文件**：`apps/api/services/agent/validators.py`

```python
# 新增 vibe.* 路径支持
SAVE_PATH_WHITELIST = [
    r"^identity\.birth_info$",
    r"^state\.[A-Za-z0-9_\.]+$",
    r"^preferences\.[A-Za-z0-9_\.]+$",
    r"^skills\.[A-Za-z0-9_]+(\.[A-Za-z0-9_\.]+)*$",
    r"^goals(\.[A-Za-z0-9_\.]+)*$",
    # v2.0 新增
    r"^vibe\.profile\.[A-Za-z0-9_\.]+$",
    r"^vibe\.state\.[A-Za-z0-9_]+$",
    r"^vibe\.goals$",
    r"^vibe\.timeline$",
]
```

### 4.3 Handler 简化

**修改文件**：`apps/api/skills/core/tools/handlers.py`

在 `execute_save` 中增加 vibe.* 路径处理：

```python
elif path.startswith("vibe."):
    # v2.0: Vibe 数据由 LLM 直接写入
    # 无复杂 merge 逻辑，LLM 已完成合并决策
    path_parts = path.split(".")

    if len(path_parts) < 2:
        return {"status": "error", "error": "vibe path 格式错误"}

    # 使用 update_by_path 写入
    await UnifiedProfileRepository.update_by_path(user_uuid, path, data)
    await invalidate_profile_cache(user_uuid)

    return {
        "status": "success",
        "message": f"已保存到 {path}",
        "path": path,
    }
```

### 4.4 Repository 新增方法

**修改文件**：`apps/api/stores/unified_profile_repo.py`

```python
@staticmethod
async def update_by_path(user_id: UUID, path: str, data: Any) -> None:
    """
    按路径更新数据（通用方法）

    Args:
        user_id: 用户 ID
        path: 点分隔路径，如 "vibe.profile.identity.traits"
        data: 要写入的数据
    """
    parts = path.split(".")

    # 构建 PostgreSQL 路径数组
    pg_path = "{" + ",".join(parts) + "}"

    exists = await fetchval(
        "SELECT 1 FROM unified_profiles WHERE user_id = $1",
        user_id
    )

    if exists:
        # 确保父路径存在
        for i in range(1, len(parts)):
            parent_path = "{" + ",".join(parts[:i]) + "}"
            await execute(
                f"""UPDATE unified_profiles
                   SET profile = jsonb_set(
                       COALESCE(profile, '{{}}'::jsonb),
                       $2,
                       COALESCE(profile #> $2, '{{}}'::jsonb),
                       true
                   )
                   WHERE user_id = $1""",
                user_id, parts[:i]
            )

        # 写入数据
        await execute(
            """UPDATE unified_profiles
               SET profile = jsonb_set(
                   profile,
                   $2,
                   $3::jsonb,
                   true
               ),
               updated_at = NOW()
               WHERE user_id = $1""",
            user_id, parts, json.dumps(data, ensure_ascii=False, default=str)
        )
    else:
        # 创建新 profile
        initial = {}
        current = initial
        for part in parts[:-1]:
            current[part] = {}
            current = current[part]
        current[parts[-1]] = data

        await UnifiedProfileRepository.create_profile(user_id, initial)
```

---

## 5. 删除旧代码

### 5.1 删除文件

| 文件 | 说明 |
|------|------|
| `apps/api/services/vibe/extractor.py` | 旧 VibeExtractor |
| `apps/api/workers/profile_extractor.py` | 旧 ProfileExtractor Worker |
| `apps/api/config/vibe_extract.json` | 旧配置文件 |

### 5.2 清理引用

**`apps/api/services/vibe/__init__.py`**：
- 移除 `from .extractor import VibeExtractor, get_extractor`

**`apps/api/stores/unified_profile_repo.py`**：
- 移除 `update_vibe_current`（已被通用 `update_by_path` 替代）
- 移除 `update_vibe_profile`（同上）
- 保留 `append_vibe_timeline`（追加逻辑特殊）

---

## 6. 数据迁移

### 6.1 迁移脚本

**文件**：`scripts/migrate_vibe_v2.py`

```python
"""
Vibe Profile v2.0 迁移脚本

将旧的 vibe 结构迁移到新结构：
- vibe.current → vibe.state
- vibe.profile → vibe.profile（结构调整）
- vibe.insight → 合并到 vibe.profile.identity
- vibe.target → vibe.goals
"""

import asyncio
import logging
from uuid import UUID
from stores.unified_profile_repo import UnifiedProfileRepository
from stores.db import fetch

logger = logging.getLogger(__name__)


async def migrate_user(user_id: UUID) -> bool:
    """迁移单个用户的 vibe 数据"""
    try:
        profile = await UnifiedProfileRepository.get_profile(user_id)
        if not profile:
            return False

        old_vibe = profile.get("vibe", {})
        if not old_vibe:
            return False

        # 构建新结构
        new_vibe = {
            "profile": {
                "identity": {
                    "archetypes": extract_archetypes(old_vibe),
                    "traits": extract_traits(old_vibe),
                    "style": old_vibe.get("insight", {}).get("essence", {}).get("communication_style")
                },
                "context": {
                    "occupation": old_vibe.get("profile", {}).get("context", {}).get("occupation"),
                    "life_stage": old_vibe.get("profile", {}).get("context", {}).get("life_stage"),
                    "interests": old_vibe.get("profile", {}).get("context", {}).get("interests", [])
                }
            },
            "state": {
                "emotion": old_vibe.get("current", {}).get("emotion"),
                "energy": old_vibe.get("current", {}).get("energy"),
                "focus": old_vibe.get("current", {}).get("focus", [])
            },
            "goals": merge_goals(old_vibe),
            "timeline": old_vibe.get("timeline", [])
        }

        # 清理 None 值
        new_vibe = clean_none_values(new_vibe)

        # 更新
        await UnifiedProfileRepository.update_profile(user_id, {"vibe": new_vibe})
        logger.info(f"Migrated user {user_id}")
        return True

    except Exception as e:
        logger.error(f"Failed to migrate user {user_id}: {e}")
        return False


def extract_archetypes(old_vibe: dict) -> list:
    """从旧结构提取人格原型"""
    insight = old_vibe.get("insight", {})
    essence = insight.get("essence", {})

    archetypes = []
    if essence.get("archetype"):
        archetypes.append(essence["archetype"])
    if essence.get("secondary_archetype"):
        archetypes.append(essence["secondary_archetype"])

    return archetypes[:3]


def extract_traits(old_vibe: dict) -> list:
    """从旧结构提取核心特质"""
    insight = old_vibe.get("insight", {})
    essence = insight.get("essence", {})

    traits = essence.get("core_traits", [])
    if isinstance(traits, list):
        return traits[:5]
    return []


def merge_goals(old_vibe: dict) -> list:
    """合并目标数据"""
    goals = []

    # 从 target.goals 提取
    target = old_vibe.get("target", {})
    if target.get("goals"):
        for goal in target["goals"]:
            if isinstance(goal, dict):
                goals.append({
                    "title": goal.get("title") or goal.get("description", ""),
                    "category": goal.get("category", "growth"),
                    "status": goal.get("status", "active")
                })

    # 从 profile.goals 提取（如果存在）
    profile_goals = old_vibe.get("profile", {}).get("goals", [])
    for goal in profile_goals:
        if isinstance(goal, dict) and goal.get("title"):
            # 检查是否重复
            if not any(g["title"] == goal["title"] for g in goals):
                goals.append({
                    "title": goal["title"],
                    "category": goal.get("category", "growth"),
                    "status": goal.get("status", "active")
                })

    return goals[:10]


def clean_none_values(d: dict) -> dict:
    """递归清理 None 值"""
    if not isinstance(d, dict):
        return d

    return {
        k: clean_none_values(v) if isinstance(v, dict) else v
        for k, v in d.items()
        if v is not None and v != [] and v != {}
    }


async def migrate_all():
    """迁移所有用户"""
    rows = await fetch("SELECT user_id FROM unified_profiles")

    success = 0
    failed = 0

    for row in rows:
        if await migrate_user(row["user_id"]):
            success += 1
        else:
            failed += 1

    logger.info(f"Migration complete: {success} success, {failed} failed")


if __name__ == "__main__":
    asyncio.run(migrate_all())
```

### 6.2 迁移步骤

1. **备份数据**：
   ```sql
   CREATE TABLE unified_profiles_backup AS SELECT * FROM unified_profiles;
   ```

2. **运行迁移**：
   ```bash
   python scripts/migrate_vibe_v2.py
   ```

3. **验证迁移**：
   ```sql
   SELECT user_id,
          profile->'vibe'->'profile' IS NOT NULL as has_profile,
          profile->'vibe'->'state' IS NOT NULL as has_state
   FROM unified_profiles
   LIMIT 10;
   ```

---

## 7. 实施文件清单

### 7.1 新建文件

| 文件 | 说明 |
|------|------|
| `services/agent/schemas/vibe.yaml` | Vibe 数据结构定义 |
| `skills/core/rules/profile.md` | LLM 信息保存规则 |
| `scripts/migrate_vibe_v2.py` | 数据迁移脚本 |

### 7.2 修改文件

| 文件 | 变更 |
|------|------|
| `skills/core/tools/tools.yaml` | 增强 save 工具描述，增加 vibe.* 路径 |
| `skills/core/tools/handlers.py` | 增加 vibe.* 路径处理逻辑 |
| `services/agent/validators.py` | 扩展路径白名单 |
| `stores/unified_profile_repo.py` | 增加 `update_by_path` 方法 |

### 7.3 删除文件

| 文件 | 说明 |
|------|------|
| `services/vibe/extractor.py` | 旧 VibeExtractor |
| `workers/profile_extractor.py` | 旧 ProfileExtractor |
| `config/vibe_extract.json` | 旧配置文件 |

---

## 8. 验证清单

- [ ] LLM 能正确识别用户信息并调用 save
- [ ] save 工具正确写入新的 vibe 结构
- [ ] read 工具能读取任意 vibe 路径
- [ ] 路径白名单正确拦截非法路径
- [ ] 旧数据成功迁移到新结构
- [ ] 无 extractor worker 残留
- [ ] 无 vibe_extract.json 残留

---

## 9. 设计决策记录

| 决策点 | 选择 | 说明 |
|--------|------|------|
| 深度分析 | **移除** | 只保存用户主动提供的信息，不做推断 |
| Skill 同步 | **移除** | Skill 数据独立存储在 `skills.{id}`，不同步到 vibe |
| Schema 校验 | **轻量** | 路径白名单 + 基本类型检查，不做复杂 JSON Schema |
| 事件检测 | **移除** | 事件由用户明确表达时保存，不自动检测 |
| Merge 策略 | **LLM 决策** | 由 LLM 读取现有数据后自主决定合并方式 |
| 触发方式 | **实时** | LLM 在对话中实时调用 save，无后台任务 |
