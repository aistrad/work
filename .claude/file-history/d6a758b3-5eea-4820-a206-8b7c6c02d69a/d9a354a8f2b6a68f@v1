# Identity Prism 清理方案

> 创建时间: 2026-01-19
> 原因: identity_prism 为未完成功能，无实际使用，代码和数据将被彻底清除
> 替代方案: VibeID (skill_data.vibe_id) 已实现多维度融合功能

---

## 1. 删除原因

### 1.1 功能未完成
- ✅ 代码实现存在 (`services/identity/prism_generator.py`)
- ❌ 无任何调用入口
- ❌ 生成逻辑从未被触发

### 1.2 已被替代
- **旧方案**: `identity_prism` - 多维度身份融合
- **新方案**: `skill_data.vibe_id` - VibeID Service 实现了相同功能

### 1.3 明确归档
```python
# apps/api/services/report/report_service.py:255
# TODO: PortraitService 已归档，identity_prism 生成功能待重构
```

---

## 2. 影响分析

### 2.1 删除文件

| 文件 | 说明 | 影响 |
|------|------|------|
| `services/identity/prism_generator.py` | 197 行，生成逻辑 | ✅ 无调用，可删 |

### 2.2 修改文件

| 文件 | 修改内容 | 行数 | 影响 |
|------|---------|------|------|
| `stores/unified_profile_repo.py` | 删除 `get_identity_prism()`, `update_identity_prism()` | ~30 行 | ✅ 只有 prism_generator 调用 |
| `services/knowledge/rag_service.py` | 删除 `identity_prism` 读取逻辑 | ~5 行 | ✅ 读取但未使用 |
| `services/report/report_service.py` | 删除 `identity_prism` 读取逻辑 | ~2 行 | ✅ 只读取，未实际使用 |
| `services/agent/skill_loader.py` | 删除上下文中的 `identity_prism` | ~10 行 | ⚠️ 影响 System Prompt（但实际未使用）|
| `services/agent/subagent.py` | 删除上下文中的 `identity_prism` | ~5 行 | ⚠️ 影响 Subagent Prompt（但实际未使用）|

### 2.3 数据库清理

```sql
-- 检查现有数据
SELECT COUNT(*) as total,
       COUNT(CASE WHEN profile ? 'identity_prism' THEN 1 END) as with_prism
FROM unified_profiles;

-- 清理 identity_prism 字段
UPDATE unified_profiles
SET profile = profile - 'identity_prism'
WHERE profile ? 'identity_prism';
```

**影响评估**: 由于该字段从未被主动生成，预计数据量为 0 或极少。

---

## 3. 清理步骤

### Step 1: 备份（可选）

```bash
# 如果担心误删，可先备份 identity_prism 数据
psql -U vibelife -d vibelife -c \
  "COPY (SELECT user_id, profile->'identity_prism' as prism
         FROM unified_profiles
         WHERE profile ? 'identity_prism')
   TO '/tmp/identity_prism_backup.csv' CSV HEADER;"
```

### Step 2: 删除文件

```bash
cd /home/aiscend/work/vibelife/apps/api

# 删除 prism_generator
rm services/identity/prism_generator.py
```

### Step 3: 修改代码

**3.1 unified_profile_repo.py**

删除以下方法：
```python
# Line 175-180
async def get_identity_prism(user_id: UUID) -> Dict[str, Any]:
    """获取 Identity Prism"""
    ...

# Line 355-377
async def update_identity_prism(user_id: UUID, identity_prism: Dict[str, Any]) -> None:
    """更新 Identity Prism (使用 jsonb_set 局部更新)"""
    ...
```

**3.2 rag_service.py**

删除：
```python
# Line 149
identity = profile.get("identity_prism", {})
```

**3.3 report_service.py**

删除：
```python
# Line 255-256
# TODO: PortraitService 已归档，identity_prism 生成功能待重构
identity_prism = profile.get("identity_prism", {})
```

**3.4 skill_loader.py**

删除：
```python
# Line 888-893
# 特殊处理 identity_prism
if user_context.get("identity_prism"):
    prism = user_context['identity_prism']
    ctx_text += f"\n### 身份特征\n"
    ...
```

**3.5 subagent.py**

删除：
```python
# Line 88-91
# Add identity prism
if context.profile:
    prism = context.profile.get("identity_prism", {})
    if prism:
        parts.append(f"\n## 用户画像\n{json.dumps(prism, ensure_ascii=False)}")
```

### Step 4: 清理数据库

```sql
-- migration: 018_remove_identity_prism.sql
BEGIN;

-- 1. 统计数据
DO $$
DECLARE
    total_profiles INT;
    profiles_with_prism INT;
BEGIN
    SELECT COUNT(*) INTO total_profiles FROM unified_profiles;
    SELECT COUNT(*) INTO profiles_with_prism FROM unified_profiles WHERE profile ? 'identity_prism';

    RAISE NOTICE 'Total profiles: %', total_profiles;
    RAISE NOTICE 'Profiles with identity_prism: %', profiles_with_prism;
END $$;

-- 2. 删除 identity_prism 字段
UPDATE unified_profiles
SET profile = profile - 'identity_prism',
    updated_at = NOW()
WHERE profile ? 'identity_prism';

-- 3. 记录迁移
INSERT INTO migration_log (migration_name, description)
VALUES (
    '018_remove_identity_prism',
    'Removed identity_prism field from unified_profiles (unused feature)'
);

COMMIT;
```

### Step 5: 更新文档

**5.1 SPEC.md**

删除所有 `identity_prism` 引用（如果有）

**5.2 ARCHITECTURE.md**

删除所有 `identity_prism` 引用（如果有）

**5.3 REVIEW.md**

更新：
```diff
- ❌ Missing 1: `identity_prism` 字段无文档
+ ✅ Removed: `identity_prism` 已删除（未完成功能）
```

### Step 6: 运行测试

```bash
# 运行相关测试
pytest apps/api/tests/unit/stores/test_unified_profile_repo.py -v
pytest apps/api/tests/test_core_agent.py -v
pytest apps/api/tests/test_vibe_id_e2e.py -v

# 检查是否有遗漏的引用
grep -r "identity_prism" apps/api --include="*.py"
```

---

## 4. 回滚方案（万一需要）

如果发现有遗漏的依赖，可以临时恢复：

```bash
# 恢复文件
git checkout HEAD -- apps/api/services/identity/prism_generator.py

# 恢复数据（如果做了备份）
psql -U vibelife -d vibelife -c \
  "UPDATE unified_profiles up
   SET profile = jsonb_set(profile, '{identity_prism}', b.prism::jsonb)
   FROM (SELECT user_id, prism FROM backed_up_table) b
   WHERE up.user_id = b.user_id;"
```

---

## 5. 验证清理完成

### 5.1 代码检查

```bash
# 应该无任何输出
grep -r "identity_prism" apps/api --include="*.py"
grep -r "PrismGenerator" apps/api --include="*.py"
grep -r "prism_generator" apps/api --include="*.py"
```

### 5.2 数据库检查

```sql
-- 应该返回 0
SELECT COUNT(*) FROM unified_profiles WHERE profile ? 'identity_prism';
```

### 5.3 测试检查

```bash
# 所有测试应该通过
pytest apps/api/tests/ -v
```

---

## 6. 总结

### 6.1 删除内容

- 1 个文件 (197 行)
- 5 个文件的部分代码 (~50 行)
- 数据库字段清理

### 6.2 替代方案

**VibeID Service** 已实现多维度融合功能：
- 数据位置: `profile.skill_data.vibe_id`
- 融合引擎: `skills/vibe_id/services/fusion_engine.py`
- 主动调用: 通过 Skill API 触发

### 6.3 收益

- ✅ 移除未使用代码
- ✅ 简化 Profile 数据结构
- ✅ 减少维护负担
- ✅ 消除文档与代码不一致

---

## 附录：受影响的 imports

清理后需要检查以下 import 是否还被使用：

```python
# 如果只在 prism_generator.py 中使用，可以删除
from services.identity.prism_generator import PrismGenerator, get_prism_generator
```

检查命令：
```bash
grep -r "from.*prism_generator import\|import.*prism_generator" apps/api --include="*.py"
```
