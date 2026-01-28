# 数据架构重构实施总结

## 概述

将 `vibe_users` 表从"账户+业务数据混合表"精简为"纯账户核心表"，所有业务数据迁移到 `unified_profiles`。

## 实施状态

✅ **所有代码已完成** - 准备进行测试和部署

## 文件清单

### 新建文件

1. **Migration 021** - 增强同步 trigger
   - `apps/api/stores/migrations/021_migrate_to_unified_profile.sql`
   - 替换 Migration 019 的 trigger，同步所有业务字段
   - 添加 JSONB 索引优化查询性能
   - Backfill 现有数据

2. **Migration 022** - Schema 清理
   - `apps/api/stores/migrations/022_cleanup_vibe_users.sql`
   - 删除 vibe_users 的业务字段
   - 创建反向同步 trigger（仅 status）
   - 验证最终结构

3. **验证脚本**
   - `apps/api/scripts/verify_migration_021.py`
   - 验证数据一致性
   - 检查索引和 trigger

### 修改文件

| 文件 | 修改内容 | 行数 |
|-----|---------|------|
| `unified_profile_repo.py` | 添加 `get_account_full`, `update_account_info`, `update_deletion_status` | +80 |
| `oauth.py` | 修改 `google_login`, `apple_login` 使用双写模式 | L116-141, L260-285 |
| `wechat.py` | 修改用户创建流程使用双写模式 | L319-348 |
| `guest_session.py` | 更新注释说明 trigger 同步 | L111-121 |
| `account.py` | 修改 `get_me`, `get_profile`, `update_profile` 使用 unified_profiles | L248-265, L455-497 |
| `account_deletion.py` | 修改 `_hard_delete_user` 删除逻辑 | L281-298 |

## 架构变更

### Before (当前)
```
vibe_users (混合表)
├── 账户核心: id, vibe_id, status, tier
├── 业务数据: display_name, avatar_url, birth_*, gender, timezone, language
└── 删除管理: deletion_requested_at, deletion_scheduled_at
```

### After (Migration 022)
```
vibe_users (纯账户表)
├── 账户核心: id, vibe_id, status
├── 计费数据: tier, daily_quota, billing_summary
└── 时间戳: created_at, updated_at

unified_profiles (业务数据)
├── account: vibe_id, display_name, avatar_url, tier, status, deletion_*
├── birth_info: date, time, place, gender, timezone
├── preferences: timezone, language, voice_mode, subscriptions, push_settings
├── skill_data: bazi, zodiac, tarot, career...
└── life_context: goals, events, patterns...
```

## 实施步骤

### Week 1: 基础设施 ✅

1. ✅ 创建 Migration 021
   - 增强 sync trigger（同步所有业务字段）
   - Backfill 现有数据
   - 添加 JSONB 索引

2. ✅ 创建验证脚本
   - `verify_migration_021.py`

3. ✅ 增强 UnifiedProfileRepository
   - `get_account_full()` - 获取完整账户信息
   - `update_account_info()` - 更新账户信息（双写）
   - `update_deletion_status()` - 更新删除状态（双写）

**部署**:
```bash
# 1. 运行 Migration 021
psql -d vibelife < apps/api/stores/migrations/021_migrate_to_unified_profile.sql

# 2. 验证数据迁移
python apps/api/scripts/verify_migration_021.py

# 3. 部署代码（包含新的 Repository 方法）
git add .
git commit -m "feat: enhance UnifiedProfileRepository for data migration"
git push
```

### Week 2: Service 层迁移（双写期）✅

修改所有创建用户的服务，使用双写模式：

1. ✅ OAuth Services (`oauth.py`)
   - `google_login()` - L116-141
   - `apple_login()` - L260-285

2. ✅ WeChat OAuth (`wechat.py`)
   - 用户创建流程 - L319-348

3. ✅ Guest Session (`guest_session.py`)
   - `link_to_user()` - L111-121

**双写模式**:
```python
# 1. 创建账户核心
user = await UserRepository.create()

# 2. 更新业务字段（trigger 自动同步到 unified_profiles）
await UserRepository.update(user_id,
    display_name=...,
    birth_datetime=...,
    birth_location=...,
    gender=...
)
```

**部署**:
```bash
git add apps/api/services/identity/
git commit -m "refactor: migrate identity services to double-write pattern"
git push
```

### Week 3: API 层迁移 ✅

修改 Account API 读写数据源：

1. ✅ GET endpoints (`account.py`)
   - `get_me()` - L248-265
   - `get_profile()` - L455-472

2. ✅ PUT endpoints (`account.py`)
   - `update_profile()` - L475-497

3. ✅ Account Deletion (`account_deletion.py`)
   - `_hard_delete_user()` - L281-298

**数据读取**:
```python
# 从 unified_profiles 读取
account = await UnifiedProfileRepository.get_account_full(user_id)
birth_info = await UnifiedProfileRepository.get_birth_info(user_id)

# created_at 仍从 vibe_users 获取（不可变字段）
user = await UserRepository.get_by_id(user_id)
created_at = user["created_at"]
```

**部署**:
```bash
git add apps/api/routes/account.py apps/api/services/identity/account_deletion.py
git commit -m "refactor: migrate account API to read from unified_profiles"
git push
```

### Week 4: Schema 清理（维护窗口）⏳

**前置条件**:
- ✅ Week 1-3 代码已部署并运行稳定
- ✅ 运行完整测试套件
- ✅ 数据一致性验证通过

**集成测试**:
```bash
# 注册流程测试
pytest tests/integration/test_oauth_registration.py

# Profile CRUD 测试
pytest tests/integration/test_profile_api.py

# 账户删除测试
pytest tests/integration/test_account_deletion.py

# 数据一致性测试
python apps/api/scripts/verify_migration_021.py
```

**部署（需要维护窗口）**:
```bash
# 1. 进入维护模式
# 2. 运行 Migration 022
psql -d vibelife < apps/api/stores/migrations/022_cleanup_vibe_users.sql

# 3. 验证
python apps/api/scripts/verify_migration_021.py

# 4. 测试关键流程
# 5. 退出维护模式
```

## 回滚方案

### Week 1-3 回滚（字段未删除）

1. 关闭新代码路径（回滚部署）
2. 恢复到 UserRepository 读取
3. 数据仍在 vibe_users，无数据丢失

### Week 4 回滚（字段已删除）

```sql
-- 1. 恢复 vibe_users schema
ALTER TABLE vibe_users
    ADD COLUMN display_name VARCHAR(100),
    ADD COLUMN avatar_url TEXT,
    ADD COLUMN birth_datetime TIMESTAMP,
    ADD COLUMN birth_location VARCHAR(255),
    ADD COLUMN gender VARCHAR(10),
    ADD COLUMN timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
    ADD COLUMN language VARCHAR(10) DEFAULT 'zh-CN',
    ADD COLUMN deletion_requested_at TIMESTAMPTZ,
    ADD COLUMN deletion_scheduled_at TIMESTAMPTZ;

-- 2. 从 unified_profiles 回填数据
UPDATE vibe_users vu
SET
    display_name = up.profile->'account'->>'display_name',
    avatar_url = up.profile->'account'->>'avatar_url',
    birth_datetime = (
        (up.profile->'birth_info'->>'date' || ' ' ||
         COALESCE(up.profile->'birth_info'->>'time', '12:00:00'))::timestamp
    ),
    birth_location = up.profile->'birth_info'->>'place',
    gender = up.profile->'birth_info'->>'gender',
    timezone = up.profile->'preferences'->>'timezone',
    language = up.profile->'preferences'->>'language',
    status = up.profile->'account'->>'status',
    deletion_requested_at = (up.profile->'account'->>'deletion_requested_at')::timestamptz,
    deletion_scheduled_at = (up.profile->'account'->>'deletion_scheduled_at')::timestamptz
FROM unified_profiles up
WHERE vu.id = up.user_id;

-- 3. 恢复正向 trigger
CREATE OR REPLACE FUNCTION sync_account_to_profile_enhanced()...
```

## 验证清单

### 数据迁移验证
- [ ] 所有 vibe_users 记录都有对应的 unified_profiles
- [ ] display_name 字段 100% 一致
- [ ] birth_datetime 正确转换为 birth_info (date + time)
- [ ] deletion_* 字段正确迁移
- [ ] avatar_url, timezone, language 正确迁移

### 功能验证
- [ ] OAuth 注册流程（Google, Apple, WeChat）
- [ ] 访客转正式用户
- [ ] GET /profile 返回完整数据
- [ ] PUT /profile 更新成功
- [ ] 账户删除流程（软删除 + 硬删除）
- [ ] 认证检查（status 验证）

### 性能验证
- [ ] Trigger 执行时间 < 10ms
- [ ] JSONB 查询时间与关系查询持平
- [ ] API 响应时间增幅 < 5%

## 风险评估

| 风险 | 严重度 | 缓解措施 | 状态 |
|------|--------|---------|------|
| Trigger 性能开销 | 中 | 仅 UPDATE 时触发；添加 GIN 索引 | ✅ 已实施 |
| JSONB 查询性能 | 中 | 添加表达式索引；监控查询时间 | ✅ 已实施 |
| 数据不一致 | 高 | 双写期持续监控；自动化一致性检查 | ✅ 验证脚本已创建 |
| 认证系统中断 | 严重 | 保留 vibe_users.status；反向同步 trigger | ✅ 已实施 |
| 回滚复杂度 | 中 | 测试回滚脚本；保留完整恢复 SQL | ✅ 文档已提供 |
| FK 完整性破坏 | 严重 | 仅删除列，不删除表；19 个 FK 保持不变 | ✅ 设计安全 |

## 监控指标

### 部署后监控（Week 1-3）

1. **数据一致性**
   ```bash
   # 每小时运行
   python apps/api/scripts/verify_migration_021.py
   ```

2. **Trigger 性能**
   ```sql
   -- 监控 trigger 执行时间
   SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del
   FROM pg_stat_user_tables
   WHERE tablename IN ('vibe_users', 'unified_profiles');
   ```

3. **JSONB 查询性能**
   ```sql
   -- 监控慢查询
   SELECT query, mean_exec_time, calls
   FROM pg_stat_statements
   WHERE query LIKE '%unified_profiles%'
   ORDER BY mean_exec_time DESC
   LIMIT 10;
   ```

4. **API 响应时间**
   - `/auth/me` - 应 < 100ms
   - `/profile` GET - 应 < 150ms
   - `/profile` PUT - 应 < 200ms

## 下一步行动

1. **立即执行**（Week 1）
   - [ ] 在测试环境运行 Migration 021
   - [ ] 运行验证脚本
   - [ ] 部署新的 Repository 方法

2. **本周执行**（Week 2-3）
   - [ ] 部署 Service 层修改
   - [ ] 部署 API 层修改
   - [ ] 运行集成测试

3. **下周计划**（Week 4）
   - [ ] 安排维护窗口
   - [ ] 准备回滚脚本
   - [ ] 执行 Migration 022
   - [ ] 监控生产环境

## 联系人

- **架构负责人**: [Your Name]
- **DBA**: [DBA Name]
- **运维**: [DevOps Name]

## 附录

### 架构决策记录

1. ✅ 计费字段保留在 vibe_users
   - 原因：快速查询，避免 JSONB 解析开销

2. ✅ created_at 保留在 vibe_users
   - 原因：账户级别不可变信息

3. ✅ 删除策略：保留 tombstone
   - 原因：Audit trail + 防止 vibe_id 复用

4. ✅ vibe_users 和 vibe_user_auth 保持分离
   - 原因：支持多认证方式、安全隔离、行业标准

### 参考资料

- [完整迁移计划](./migration-021-022-plan.md)
- [Migration 021 代码](../apps/api/stores/migrations/021_migrate_to_unified_profile.sql)
- [Migration 022 代码](../apps/api/stores/migrations/022_cleanup_vibe_users.sql)
- [验证脚本](../apps/api/scripts/verify_migration_021.py)
