# VibeID 数据迁移方案

> Version: 1.0 | 2026-01-19

## 1. 迁移概述

### 1.1 迁移目标

将 VibeID 数据从 `skill_data.vibe_id` 提升到 `unified_profiles.vibe_id` 顶层字段。

### 1.2 迁移范围

| 项目 | 说明 |
|-----|------|
| 数据库 | unified_profiles 表 |
| 影响用户 | 所有已计算 VibeID 的用户 |
| 预计数量 | 需要查询确认 |

### 1.3 迁移策略

采用**渐进式迁移**策略：

1. **Phase 1**: 新增顶层字段，双写
2. **Phase 2**: 读取优先使用顶层字段
3. **Phase 3**: 清理旧数据

---

## 2. 迁移步骤

### 2.1 Phase 1: 双写期

#### 2.1.1 数据库迁移脚本

```sql
-- 迁移脚本: 001_migrate_vibe_id_to_top_level.sql

-- 1. 将现有 skill_data.vibe_id 复制到顶层
UPDATE unified_profiles
SET vibe_id = skill_data->'vibe_id'
WHERE skill_data->'vibe_id' IS NOT NULL
  AND vibe_id IS NULL;

-- 2. 添加 evolution 字段（如果不存在）
UPDATE unified_profiles
SET vibe_id = vibe_id || jsonb_build_object(
  'evolution', jsonb_build_array(
    jsonb_build_object(
      'id', 'evo_migration',
      'timestamp', vibe_id->>'calculated_at',
      'trigger', 'initial_calculation',
      'snapshot', jsonb_build_object(
        'primary_archetype', vibe_id->'archetypes'->'core'->>'primary',
        'scores', vibe_id->'scores'
      ),
      'delta', null,
      'insight', '从 v6 迁移的初始数据'
    )
  )
)
WHERE vibe_id IS NOT NULL
  AND vibe_id->'evolution' IS NULL;

-- 3. 添加 primary_archetype 字段（简化呈现）
UPDATE unified_profiles
SET vibe_id = vibe_id || jsonb_build_object(
  'primary_archetype', vibe_id->'archetypes'->'core'->>'primary'
)
WHERE vibe_id IS NOT NULL
  AND vibe_id->>'primary_archetype' IS NULL;

-- 4. 添加 archetype_signature 字段
-- 注意: 这需要根据原型生成，建议用 Python 脚本处理
```

#### 2.1.2 Python 迁移脚本

```python
# scripts/migrate_vibe_id.py

import asyncio
import logging
from uuid import UUID
from stores.db import get_connection
from skills.vibe_id.services.explainer import Explainer

logger = logging.getLogger(__name__)

# 原型签名模板
SIGNATURE_TEMPLATES = {
    ("Explorer", "Lover"): "追求自由的灵魂，内心渴望深度连接",
    ("Explorer", "Sage"): "追求自由的智者，渴望理解世界的真相",
    ("Hero", "Sage"): "勇于征服的战士，追求真理与智慧",
    ("Caregiver", "Creator"): "温暖守护的心，渴望创造独特价值",
    # ... 更多组合
}

def generate_signature(core_archetype: str, inner_archetype: str) -> str:
    """生成人格金句"""
    key = (core_archetype, inner_archetype)
    if key in SIGNATURE_TEMPLATES:
        return SIGNATURE_TEMPLATES[key]

    # 默认模板
    explainer = Explainer()
    return explainer.generate_signature(core_archetype, inner_archetype)


async def migrate_user(user_id: UUID, profile: dict) -> bool:
    """迁移单个用户"""
    try:
        skill_data = profile.get("skill_data", {})
        old_vibe_id = skill_data.get("vibe_id")

        if not old_vibe_id:
            return False  # 没有旧数据

        # 构建新数据结构
        archetypes = old_vibe_id.get("archetypes", {})
        core = archetypes.get("core", {})
        inner = archetypes.get("inner", {})

        new_vibe_id = {
            "version": "7.0",
            "calculated_at": old_vibe_id.get("calculated_at"),
            "updated_at": old_vibe_id.get("calculated_at"),

            # 简化呈现
            "primary_archetype": core.get("primary"),
            "archetype_signature": generate_signature(
                core.get("primary", "Regular"),
                inner.get("primary", "Regular")
            ),

            # 四维原型（重命名）
            "dimensions": {
                "core": core,
                "inner": inner,
                "outer": archetypes.get("outer", {}),
                "shadow": archetypes.get("shadow", {})
            },

            # 12原型能量
            "scores": old_vibe_id.get("scores", {}),

            # 演化历史（初始化）
            "evolution": [{
                "id": "evo_migration",
                "timestamp": old_vibe_id.get("calculated_at"),
                "trigger": "initial_calculation",
                "snapshot": {
                    "primary_archetype": core.get("primary"),
                    "scores": old_vibe_id.get("scores", {})
                },
                "delta": None,
                "insight": "从 v6 迁移的初始数据"
            }],

            # 来源追溯
            "sources": old_vibe_id.get("source_versions", {})
        }

        # 写入数据库
        async with get_connection() as conn:
            await conn.execute("""
                UPDATE unified_profiles
                SET vibe_id = $1
                WHERE user_id = $2
            """, new_vibe_id, user_id)

        return True

    except Exception as e:
        logger.error(f"Failed to migrate user {user_id}: {e}")
        return False


async def run_migration(batch_size: int = 100, dry_run: bool = True):
    """执行迁移"""
    logger.info(f"Starting VibeID migration (dry_run={dry_run})")

    # 查询需要迁移的用户
    async with get_connection() as conn:
        rows = await conn.fetch("""
            SELECT user_id, skill_data, vibe_id
            FROM unified_profiles
            WHERE skill_data->'vibe_id' IS NOT NULL
              AND (vibe_id IS NULL OR vibe_id->>'version' != '7.0')
        """)

    total = len(rows)
    success = 0
    failed = 0

    logger.info(f"Found {total} users to migrate")

    for row in rows:
        user_id = row["user_id"]
        profile = {"skill_data": row["skill_data"]}

        if dry_run:
            logger.info(f"[DRY RUN] Would migrate user {user_id}")
            success += 1
        else:
            if await migrate_user(user_id, profile):
                success += 1
            else:
                failed += 1

        if (success + failed) % batch_size == 0:
            logger.info(f"Progress: {success + failed}/{total}")

    logger.info(f"Migration complete: {success} success, {failed} failed")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Dry run mode")
    parser.add_argument("--batch-size", type=int, default=100)
    args = parser.parse_args()

    asyncio.run(run_migration(
        batch_size=args.batch_size,
        dry_run=args.dry_run
    ))
```

#### 2.1.3 Service 层双写

```python
# services/vibe_id/service.py

class VibeIDService:
    async def calculate(self, user_id: UUID, force: bool = False) -> Dict[str, Any]:
        # ... 计算逻辑 ...

        # 双写: 同时写入顶层和 skill_data
        async with get_connection() as conn:
            # 写入顶层 vibe_id
            await conn.execute("""
                UPDATE unified_profiles
                SET vibe_id = $1
                WHERE user_id = $2
            """, vibe_id_data, user_id)

            # 同时写入 skill_data.vibe_id (向后兼容)
            await conn.execute("""
                UPDATE unified_profiles
                SET skill_data = jsonb_set(
                    COALESCE(skill_data, '{}'::jsonb),
                    '{vibe_id}',
                    $1
                )
                WHERE user_id = $2
            """, vibe_id_data, user_id)

        return {"status": "success", "data": vibe_id_data}
```

### 2.2 Phase 2: 读取优先

#### 2.2.1 读取逻辑

```python
async def get_vibe_id(user_id: UUID) -> Optional[Dict[str, Any]]:
    """
    获取 VibeID（优先顶层字段）

    读取优先级:
    1. unified_profiles.vibe_id (v7)
    2. unified_profiles.skill_data.vibe_id (v6, 向后兼容)
    """
    async with get_connection() as conn:
        row = await conn.fetchrow("""
            SELECT vibe_id, skill_data->'vibe_id' as old_vibe_id
            FROM unified_profiles
            WHERE user_id = $1
        """, user_id)

    if not row:
        return None

    # 优先使用顶层字段
    if row["vibe_id"]:
        return row["vibe_id"]

    # 回退到旧位置
    if row["old_vibe_id"]:
        return row["old_vibe_id"]

    return None
```

### 2.3 Phase 3: 清理旧数据

在确认所有读取都使用顶层字段后，清理 `skill_data.vibe_id`：

```sql
-- 清理脚本: 002_cleanup_old_vibe_id.sql

-- 1. 确认所有数据已迁移
SELECT COUNT(*) as not_migrated
FROM unified_profiles
WHERE skill_data->'vibe_id' IS NOT NULL
  AND vibe_id IS NULL;

-- 如果 not_migrated = 0，执行清理

-- 2. 删除 skill_data.vibe_id
UPDATE unified_profiles
SET skill_data = skill_data - 'vibe_id'
WHERE skill_data->'vibe_id' IS NOT NULL;
```

---

## 3. 回滚方案

### 3.1 Phase 1 回滚

如果双写期发现问题：

```sql
-- 回滚: 清空顶层 vibe_id
UPDATE unified_profiles
SET vibe_id = NULL
WHERE vibe_id IS NOT NULL;
```

### 3.2 Phase 2 回滚

修改读取逻辑，优先使用 `skill_data.vibe_id`。

### 3.3 Phase 3 回滚

从备份恢复 `skill_data.vibe_id`（需要提前备份）。

---

## 4. 验证清单

### 4.1 迁移前

- [ ] 备份 unified_profiles 表
- [ ] 统计需要迁移的用户数量
- [ ] 在测试环境验证迁移脚本

### 4.2 迁移中

- [ ] 监控数据库性能
- [ ] 检查迁移进度
- [ ] 验证数据完整性

### 4.3 迁移后

- [ ] 验证顶层 vibe_id 数据正确
- [ ] 验证 API 读取正常
- [ ] 验证前端展示正常
- [ ] 验证 Prompt 注入正常

---

## 5. 时间线

| 阶段 | 时间 | 说明 |
|-----|------|------|
| Phase 1 | Day 1-3 | 双写期，执行迁移脚本 |
| Phase 2 | Day 4-7 | 读取优先顶层字段，观察 |
| Phase 3 | Day 8+ | 确认无问题后清理旧数据 |

---

## 6. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 迁移脚本错误 | 数据丢失 | 提前备份，dry-run 验证 |
| 性能问题 | 服务降级 | 分批执行，低峰期操作 |
| 兼容性问题 | 功能异常 | 双写期充分测试 |
| 回滚失败 | 数据不一致 | 保留备份，准备回滚脚本 |
