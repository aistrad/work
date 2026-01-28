# CoreAgent + Skill 基于 VibeProfile V8 架构更新方案

## 概述

基于 VibeProfile V8 三层架构更新 CoreAgent 和 Skill 系统：
1. **删除 Cold Layer** - 废弃的架构冗余
2. **删除 state 字段** - 与 vibe.target.focus 重复
3. **Vibe Layer 双向同步** - skill ↔ vibe 自动同步
4. **数据访问权限控制** - Skill 只能写自己的数据（可选）

## Part 1: 删除 Cold Layer

### 删除文件/代码

| 位置 | 操作 |
|-----|------|
| `stores/migrations/020_cold_layer_tables.sql` | 删除文件 |
| `stores/unified_profile_repo.py` | 删除 `ColdLayerRepository` 类 + `ProfileInsight` / `TimelineEvent` dataclass |
| `workers/profile_extractor.py` | 删除 `timeline_events` 写入逻辑 |

### 数据库清理

```sql
DROP TABLE IF EXISTS vibe_profile_insights;
DROP TABLE IF EXISTS vibe_profile_timeline;
```

## Part 2: 删除 state 字段

### 原因
- `profile.state.focus` 与 `profile.vibe.target.focus` 重复
- `vibe.target.focus` 更丰富 (含 heat_map)，由 profile_extractor 维护

### 删除/修改

| 文件 | 操作 |
|-----|------|
| `stores/unified_profile_repo.py` | 删除 `get_state()`, `update_state()`, `get_focus()`, `add_focus()`, `remove_focus()` |
| `services/proactive/content_generator.py` | 改为读取 `vibe.target.focus` |
| `routes/account.py` | 检查并移除 state 相关逻辑（如有） |

### 数据迁移
无需迁移，`vibe.target.focus` 已由 profile_extractor 自动维护。

---

## Part 3: Vibe 同步增强

### 改动点

| 文件 | 改动 |
|-----|------|
| `stores/unified_profile_repo.py` | 新增 `sync_bazi_to_vibe_insight()` |
| `stores/unified_profile_repo.py` | 新增 `sync_zodiac_to_vibe_insight()` |
| `stores/unified_profile_repo.py` | 修改 `update_skill_data()` 触发同步 |

### 同步逻辑

```
bazi.chart 更新 → 提取日主 → 映射原型 → 写入 vibe.insight.essence.archetype
zodiac.chart 更新 → 提取太阳/上升 → 写入 vibe.insight.essence.traits
lifecoach 更新 → 已有同步到 vibe.target（保留）
```

## Part 4: 访问控制（可选）

### 权限规则

| Skill | 可写 |
|-------|------|
| core | extracted |
| lifecoach | skills.lifecoach, vibe.target |
| bazi | skills.bazi |
| zodiac | skills.zodiac |
| tarot | skills.tarot |
| career | skills.career |

### 实现方式

新建 `services/agent/access_control.py`，在 ToolExecutor 写入前校验。

## 关键文件

1. `stores/unified_profile_repo.py` - 删除 Cold Layer + state + 新增 Vibe 同步
2. `workers/profile_extractor.py` - 删除 Cold Layer 写入
3. `services/proactive/content_generator.py` - 改用 vibe.target.focus
4. `services/agent/access_control.py` - 新建权限控制（可选）

## 验证

```bash
# 删除后检查
psql -c "SELECT count(*) FROM vibe_profile_insights" # 应报错：表不存在

# Vibe 同步验证
python scripts/test_coreagent_claude.py --skill bazi --check-vibe-sync
```

## 未解决问题

1. **数据库表删除** - 需要确认 Cold Layer 表和 state 字段中无重要数据后再删除
2. **迁移脚本清理** - 019/020 迁移文件是否需要修改或标记为废弃
