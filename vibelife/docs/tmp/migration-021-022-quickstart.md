# Migration 021-022 快速开始指南

## 5 分钟快速理解

### 做什么？

将 `vibe_users` 表从"大杂烩"变成"纯账户表"：

**Before**: vibe_users 包含账户 + 个人资料 + 偏好 + 删除状态...
**After**: vibe_users 只包含账户核心（id, vibe_id, status）+ 计费信息

所有业务数据搬到 `unified_profiles`（JSONB）。

### 为什么？

1. **职责清晰**: vibe_users = 账户认证，unified_profiles = 业务数据
2. **扩展灵活**: 添加新字段不需要 ALTER TABLE
3. **架构一致**: 与现有 skill_data, life_context 设计统一

### 怎么做？

**4 周渐进式迁移** - 零停机，可随时回滚。

---

## 快速执行（测试环境）

### Step 1: 运行 Migration 021（5 分钟）

```bash
# 1. 运行迁移
cd /home/aiscend/work/vibelife
psql -d vibelife_test < apps/api/stores/migrations/021_migrate_to_unified_profile.sql

# 2. 验证数据
python apps/api/scripts/verify_migration_021.py

# 预期输出:
# ✅ All users have unified_profiles
# ✅ All account fields are consistent
# ✅ All birth_info fields are consistent
# ✅ All preferences are consistent
# ✅ All deletion status fields are consistent
# ✅ All data verified consistent!
```

**Migration 021 做了什么**:
- ✅ 增强 sync trigger（同步所有业务字段）
- ✅ Backfill 现有数据到 unified_profiles
- ✅ 添加 4 个 JSONB 索引优化查询

### Step 2: 部署代码（10 分钟）

```bash
# 已修改的文件都在 git 中，直接部署即可
git add .
git commit -m "feat: migrate business data to unified_profiles (Week 1-3)"
git push

# 重启服务
docker-compose restart api
```

**代码修改摘要**:
- ✅ Week 1: UnifiedProfileRepository 新增 3 个方法
- ✅ Week 2: OAuth/WeChat/Guest 服务使用双写模式
- ✅ Week 3: Account API 从 unified_profiles 读取

### Step 3: 测试（15 分钟）

```bash
# 1. 注册新用户
curl -X POST http://localhost:8000/api/account/auth/oauth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "...", "onboarding": {...}}'

# 2. 获取 Profile
curl -X GET http://localhost:8000/api/account/profile \
  -H "Authorization: Bearer $TOKEN"

# 3. 更新 Profile
curl -X PUT http://localhost:8000/api/account/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"display_name": "测试用户", "timezone": "Asia/Tokyo"}'

# 4. 验证数据一致性
python apps/api/scripts/verify_migration_021.py
```

### Step 4: Schema 清理（可选 - Week 4）

```bash
# ⚠️ 这是破坏性操作，确保 Week 1-3 稳定运行后再执行

# 1. 安排维护窗口（建议凌晨低峰期）
# 2. 运行 Migration 022
psql -d vibelife < apps/api/stores/migrations/022_cleanup_vibe_users.sql

# 预期输出:
# ✓ Safety checks passed
# ✓ Business columns dropped from vibe_users
# ✓ Schema structure is correct!
# ✓ JSONB indexes are in place

# 3. 验证
python apps/api/scripts/verify_migration_021.py

# 4. 测试关键流程
pytest tests/integration/test_account_api.py
```

---

## 详细执行计划

### Week 1: 基础设施 ✅

**目标**: 数据开始双写到 unified_profiles

```bash
# 1. 运行 Migration 021
psql -d vibelife_dev < apps/api/stores/migrations/021_migrate_to_unified_profile.sql

# 2. 验证
python apps/api/scripts/verify_migration_021.py

# 3. 部署 UnifiedProfileRepository 增强
git add apps/api/stores/unified_profile_repo.py
git commit -m "feat(week1): enhance UnifiedProfileRepository for account data"
git push

# 4. 监控
watch -n 60 'python apps/api/scripts/verify_migration_021.py'
```

**验收标准**:
- [ ] Migration 021 执行成功
- [ ] 验证脚本全部通过
- [ ] 所有用户数据在 vibe_users 和 unified_profiles 中一致

### Week 2: Service 层迁移 ✅

**目标**: 新用户创建使用双写模式

```bash
# 1. 部署 Service 层修改
git add apps/api/services/identity/
git commit -m "feat(week2): migrate identity services to double-write pattern"
git push

# 2. 测试注册流程
# Google OAuth
curl -X POST .../auth/oauth/google -d '{"id_token": "..."}'

# Apple OAuth
curl -X POST .../auth/oauth/apple -d '{"id_token": "..."}'

# WeChat OAuth
curl -X POST .../auth/wechat/callback -d '{"code": "..."}'

# 3. 验证新用户数据
python apps/api/scripts/verify_migration_021.py
```

**验收标准**:
- [ ] 新注册用户数据正确同步到 unified_profiles
- [ ] 现有用户不受影响
- [ ] 认证流程正常

### Week 3: API 层迁移 ✅

**目标**: API 从 unified_profiles 读取数据

```bash
# 1. 部署 API 层修改
git add apps/api/routes/account.py apps/api/services/identity/account_deletion.py
git commit -m "feat(week3): migrate account API to read from unified_profiles"
git push

# 2. 测试 API 端点
# GET /auth/me
curl -X GET .../auth/me -H "Authorization: Bearer $TOKEN"

# GET /profile
curl -X GET .../profile -H "Authorization: Bearer $TOKEN"

# PUT /profile
curl -X PUT .../profile -H "Authorization: Bearer $TOKEN" \
  -d '{"display_name": "New Name"}'

# DELETE account
curl -X POST .../delete -H "Authorization: Bearer $TOKEN"

# 3. 性能测试
ab -n 1000 -c 10 http://localhost:8000/api/account/profile

# 4. 验证
python apps/api/scripts/verify_migration_021.py
```

**验收标准**:
- [ ] GET /auth/me, GET /profile 返回正确数据
- [ ] PUT /profile 更新成功
- [ ] 账户删除流程正常
- [ ] API 响应时间无明显增加（< 5%）

### Week 4: Schema 清理 ⏳

**目标**: 删除 vibe_users 的业务字段

```bash
# ⚠️ 破坏性操作 - 需要维护窗口

# 1. 准备回滚脚本
cat > /tmp/rollback_022.sql << 'EOF'
-- 见 migration-021-022-summary.md 的回滚方案
ALTER TABLE vibe_users ADD COLUMN display_name VARCHAR(100);
-- ...
EOF

# 2. 进入维护模式
# 停止接收新流量

# 3. 最后一次数据验证
python apps/api/scripts/verify_migration_021.py

# 4. 运行 Migration 022
psql -d vibelife < apps/api/stores/migrations/022_cleanup_vibe_users.sql

# 5. 验证最终结构
psql -d vibelife -c "\d vibe_users"
# 预期：仅 8 列（id, vibe_id, status, tier, daily_quota, billing_summary, created_at, updated_at）

# 6. 集成测试
pytest tests/integration/

# 7. 退出维护模式
```

**验收标准**:
- [ ] vibe_users 仅保留 8 列
- [ ] 所有集成测试通过
- [ ] 应用运行正常
- [ ] 数据一致性验证通过

---

## 常见问题

### Q1: Migration 021 执行失败怎么办？

```bash
# 查看错误信息
tail -f /var/log/postgresql/postgresql.log

# 常见错误：
# 1. 权限不足 -> 使用 superuser 执行
# 2. 列不存在 -> 检查 vibe_users schema
# 3. 数据类型冲突 -> 检查 birth_datetime 格式

# 回滚 Migration 021
BEGIN;
DROP TRIGGER IF EXISTS trigger_sync_account_to_profile ON vibe_users;
DROP FUNCTION IF EXISTS sync_account_to_profile_enhanced();
-- 恢复 Migration 019 的 trigger
ROLLBACK;
```

### Q2: 验证脚本报告数据不一致？

```bash
# 查看详细不一致信息
python apps/api/scripts/verify_migration_021.py 2>&1 | grep "Mismatch"

# 手动修复不一致（示例）
psql -d vibelife << 'EOF'
UPDATE unified_profiles up
SET profile = jsonb_set(
    profile,
    '{account,display_name}',
    to_jsonb((SELECT display_name FROM vibe_users WHERE id = up.user_id))
)
WHERE user_id IN (
    SELECT id FROM vibe_users vu
    WHERE vu.display_name IS DISTINCT FROM (up.profile->'account'->>'display_name')
);
EOF

# 重新验证
python apps/api/scripts/verify_migration_021.py
```

### Q3: JSONB 查询性能慢？

```sql
-- 检查索引是否创建
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'unified_profiles'
AND indexname LIKE 'idx_profile%';

-- 分析查询计划
EXPLAIN ANALYZE
SELECT * FROM unified_profiles
WHERE profile->'account'->>'status' = 'active';

-- 如果索引未使用，强制使用
SET enable_seqscan = off;
```

### Q4: 如何回滚到 Migration 021 之前？

```bash
# Week 1-3 回滚（字段未删除）
# 1. 回滚代码部署
git revert <commit-hash>
git push

# 2. 应用会继续从 vibe_users 读取，数据无损失

# Week 4 回滚（字段已删除）
# 1. 执行回滚脚本（见 migration-021-022-summary.md）
psql -d vibelife < /tmp/rollback_022.sql

# 2. 回滚代码
git revert <commit-hash>
git push
```

---

## 监控检查清单

### 部署后立即检查（0-1小时）

- [ ] 应用日志无错误
- [ ] 新用户注册成功
- [ ] Profile API 响应正常
- [ ] 数据一致性验证通过

### 每日检查（Week 1-3）

```bash
# 每天运行一次
python apps/api/scripts/verify_migration_021.py > /tmp/verify_$(date +%Y%m%d).log

# 检查 Trigger 性能
psql -d vibelife << 'EOF'
SELECT
    schemaname,
    tablename,
    n_tup_upd AS updates,
    n_tup_del AS deletes
FROM pg_stat_user_tables
WHERE tablename IN ('vibe_users', 'unified_profiles');
EOF

# 检查慢查询
psql -d vibelife << 'EOF'
SELECT
    query,
    mean_exec_time,
    calls
FROM pg_stat_statements
WHERE query LIKE '%unified_profiles%'
ORDER BY mean_exec_time DESC
LIMIT 5;
EOF
```

### 每周检查（Week 1-3）

- [ ] API 响应时间趋势
- [ ] 数据库磁盘使用
- [ ] JSONB 索引大小
- [ ] Trigger 执行统计

---

## 紧急联系

**如果遇到生产问题**:

1. 立即回滚代码部署
2. 联系 DBA 检查数据一致性
3. 查看应用日志和数据库日志
4. 如有数据丢失，从 unified_profiles 恢复到 vibe_users

**联系人**:
- 架构: [Your Name]
- DBA: [DBA Name]
- 运维: [DevOps Name]

---

## 总结

这是一个**渐进式、零停机**的数据架构重构：

✅ **Week 1**: 数据开始双写
✅ **Week 2**: 新用户使用新模式
✅ **Week 3**: API 切换到新数据源
⏳ **Week 4**: 清理旧字段（可选）

**任何阶段都可以安全回滚！**

开始执行？ → [Step 1: 运行 Migration 021](#step-1-运行-migration-0215-分钟)
