# Vibe v2.0 Code Review 修复计划

> 基于代码审查反馈的修复计划

---

## P0 - 必须立即修复

### 1. vibe.goals 写入位置错误

**问题**：`handlers.py:278/291` 调用 `update_vibe_profile({"goals": ...})`，实际写入到 `vibe.profile.goals`，而非顶层 `vibe.goals`。

**修复**：
```python
# handlers.py:278, 291
# Before
await UnifiedProfileRepository.update_vibe_profile(user_uuid, {"goals": merged[:10]})

# After
await UnifiedProfileRepository.update_by_path(user_uuid, "vibe.goals", current_goals[:10])
```

**文件**: `apps/api/skills/core/tools/handlers.py`

---

## P1 - 一致性/健壮性

### 2. merge 参数未使用

**问题**：`tools.yaml` 暴露 `merge: boolean` 但 handler 未读取。

**修复**：在 save handler 读取 merge 参数
```python
merge = args.get("merge", True)

# vibe.state.* - 默认覆盖
if path.startswith("vibe.state."):
    # merge=True 时合并，merge=False 时覆盖（state 默认覆盖）
    ...

# vibe.profile.* - 默认合并
if path.startswith("vibe.profile."):
    if merge:
        # 深度合并
    else:
        # 直接覆盖
```

**文件**: `apps/api/skills/core/tools/handlers.py`

### 3. 读取返回值空值不一致

**问题**：
- `vibe.profile.xxx` 缺失返回 `{}`
- `vibe.state.xxx` 缺失返回 `None`

**修复**：统一返回 `None`
```python
# handlers.py:434
data = data.get(part, None) if isinstance(data, dict) else None

# handlers.py:443 (已是 None，保持)
```

**文件**: `apps/api/skills/core/tools/handlers.py`

### 4. Timeline 批量追加优化

**问题**：list 传入时逐条写库，多次 IO。

**修复**：合并后单次写入
```python
if path == "vibe.timeline":
    if isinstance(data, dict):
        await UnifiedProfileRepository.append_vibe_timeline(user_uuid, data)
    elif isinstance(data, list):
        # 批量追加：一次读 + 合并 + 一次写
        await UnifiedProfileRepository.append_vibe_timeline_batch(user_uuid, data)
```

**文件**:
- `apps/api/skills/core/tools/handlers.py`
- `apps/api/stores/unified_profile_repo.py` (新增 `append_vibe_timeline_batch`)

---

## P2 - 清洁度/文档

### 5. 清理未使用导入

**文件**: `apps/api/stores/unified_profile_repo.py:42` - 移除 `date`

### 6. 更新文档注释

- `get_vibe_profile` / `get_vibe_current` docstring 更新为 v2.0 术语
- 移除 v13 遗留描述

### 7. 迁移脚本整理

- 只保留 `apps/api/scripts/migrate_vibe_v2.py`
- 删除顶层重复脚本（如存在）
- 添加使用指引到 DESIGN.md

---

## 修改文件清单

| 文件 | 变更 |
|------|------|
| `skills/core/tools/handlers.py` | P0 goals 路径修复, P1 merge参数, P1 空值统一 |
| `stores/unified_profile_repo.py` | P1 批量timeline, P2 清理导入/注释 |

---

## 验证

```bash
# 运行 E2E 测试
export VIBELIFE_DB_URL="..."
python scripts/test_vibe_v2_e2e.py

# 重点验证：
# 1. save vibe.goals 后 read vibe.goals 应返回数据（非 vibe.profile.goals）
# 2. merge=false 时直接覆盖
# 3. 批量 timeline 追加效率
```

---

## 风险说明

- **并发写入 goals**：当前无乐观锁，后续可引入 `expected_updated_at`
- **兼容性**：`get_vibe()` 已有 `profile.goals` 兜底逻辑，修复后不影响读取
