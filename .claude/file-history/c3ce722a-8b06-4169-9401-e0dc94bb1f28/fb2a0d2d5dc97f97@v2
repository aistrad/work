# VibeProfile 重构后清理清单

> 重构完成后，需要清理的废弃代码、表和文件

---

## 一、数据库表（需手动删除）

根据 `SPEC.md` 第 348-356 行明确指出，以下表已废弃：

### 1. 废弃的表

```sql
-- 1. user_data_store - 已迁移到 unified_profiles.profile.life_context
DROP TABLE IF EXISTS user_data_store CASCADE;

-- 2. user_reminders - 已迁移到 unified_profiles.profile.life_context.reminders
DROP TABLE IF EXISTS user_reminders CASCADE;

-- 3. user_skill_subscriptions - 已迁移到 unified_profiles.profile.preferences.subscribed_skills
DROP TABLE IF EXISTS user_skill_subscriptions CASCADE;

-- 4. user_push_preferences - 已迁移到 unified_profiles.profile.preferences
DROP TABLE IF EXISTS user_push_preferences CASCADE;

-- 5. skill_recommendation_blocks - 已迁移到 unified_profiles.profile.preferences.blocked_skills
DROP TABLE IF EXISTS skill_recommendation_blocks CASCADE;
```

### 2. 表定义位置

这些表的创建脚本位于：
- `apps/api/stores/migrations/007_user_data_store.sql` - user_data_store, user_reminders
- `apps/api/stores/migrations/015_skill_subscriptions.sql` - user_skill_subscriptions, skill_recommendation_blocks
- `apps/api/stores/migrations/016_push_time_preference.sql` - user_push_preferences

### 3. 清理建议

**执行前务必备份！**

```bash
# 1. 备份数据库
pg_dump -h localhost -U postgres -d vibelife > backup_before_cleanup_$(date +%Y%m%d).sql

# 2. 验证数据已完全迁移
psql -d vibelife -c "SELECT COUNT(*) FROM user_data_store;"
psql -d vibelife -c "SELECT COUNT(*) FROM user_reminders;"
psql -d vibelife -c "SELECT COUNT(*) FROM user_skill_subscriptions;"
psql -d vibelife -c "SELECT COUNT(*) FROM user_push_preferences;"
psql -d vibelife -c "SELECT COUNT(*) FROM skill_recommendation_blocks;"

# 3. 执行删除（创建迁移脚本）
# apps/api/stores/migrations/017_drop_legacy_profile_tables.sql
```

---

## 二、已删除的代码文件（git commit 即清理）

以下文件已标记为删除（git status 显示 D），执行 `git commit` 即可清理：

### 1. API Routes（已删除）

```
D  apps/api/routes/bazi.py
D  apps/api/routes/chat.py
D  apps/api/routes/context.py
D  apps/api/routes/fortune.py
D  apps/api/routes/memories.py
D  apps/api/routes/onboarding.py
D  apps/api/routes/relationship.py
D  apps/api/routes/report.py
D  apps/api/routes/zodiac.py
```

### 2. Services（已删除）

```
D  apps/api/services/agent/base.py
D  apps/api/services/agent/fusion_agent.py
D  apps/api/services/agent/orchestrator.py
D  apps/api/services/agent/quota.py
D  apps/api/services/agent/registry.py
D  apps/api/services/agent/skills/__init__.py
D  apps/api/services/agent/skills/bazi_agent.py
D  apps/api/services/agent/skills/zodiac_agent.py
D  apps/api/services/bazi/
D  apps/api/services/extraction/
D  apps/api/services/fortune/
D  apps/api/services/greeting/
D  apps/api/services/interview/
D  apps/api/services/persona/
D  apps/api/services/push/
D  apps/api/services/relationship/
D  apps/api/services/vibe_engine/
D  apps/api/services/zodiac/
```

### 3. Stores/Repositories（已删除）

```
D  apps/api/stores/fortune_repo.py
D  apps/api/stores/password_reset_repo.py
D  apps/api/stores/profile_repo.py
D  apps/api/stores/skill_data_repo.py
D  apps/api/stores/usage_repo.py
```

### 4. Tools（已删除）

```
D  apps/api/tools/bazi/
D  apps/api/tools/zodiac/
```

### 5. Workers（已删除）

```
D  apps/api/workers/daily_extraction.py
```

### 6. Tests（已删除）

```
D  apps/api/tests/test_bazi_tools.py
D  apps/api/tests/test_chat_api.py
D  apps/api/tests/test_interview.py
D  apps/api/tests/test_knowledge.py
D  apps/api/tests/test_payment.py
D  apps/api/tests/test_relationship.py
D  apps/api/tests/test_v3_integration.py
D  apps/api/tests/test_vibe_engine.py
```

### 7. Skills YAML Methods（已删除）

```
D  apps/api/skills/bazi/methods/*.yaml
D  apps/api/skills/bazi/rules/rules.yaml
D  apps/api/skills/bazi/workflows/main_flow.yaml
D  apps/api/skills/career/methods/*.yaml
D  apps/api/skills/career/rules/rules.yaml
D  apps/api/skills/career/workflows/main_flow.yaml
D  apps/api/skills/tarot/methods/*.yaml
D  apps/api/skills/tarot/rules/rules.yaml
D  apps/api/skills/tarot/workflows/main_flow.yaml
D  apps/api/skills/zodiac/methods/*.yaml
D  apps/api/skills/zodiac/decision_trees/*.yaml
D  apps/api/skills/zodiac/rules/rules.yaml
D  apps/api/skills/zodiac/workflows/main_flow.yaml
D  apps/api/skills/zodiac/templates/comprehensive_reading.yaml
```

### 8. Web Frontend（已删除）

```
D  apps/web/src/app/auth/forgot-password/page.tsx
D  apps/web/src/app/auth/register/page.tsx
D  apps/web/src/app/auth/reset-password/page.tsx
D  apps/web/src/app/bazi/
D  apps/web/src/app/zodiac/
D  apps/web/src/app/onboarding/steps/InterviewStep.tsx
D  apps/web/src/app/onboarding/steps/LetterStep.tsx
D  apps/web/src/app/onboarding/steps/PersonaStep.tsx
D  apps/web/src/components/chart/ZodiacChart.tsx
D  apps/web/src/components/auth/PurchasePrompt.tsx
D  apps/web/src/components/chat/ChatLayout.tsx
D  apps/web/src/components/home/DailyFortuneCard.tsx
D  apps/web/src/components/home/NotificationCenter.tsx
D  apps/web/src/components/insight/InsightPanel.tsx
D  apps/web/src/components/insight/InsightPanelV2.tsx
D  apps/web/src/components/paywall/LockedFeature.tsx
D  apps/web/src/components/relationship/
D  apps/web/src/components/script/
D  apps/web/src/components/trend/KLineFullView.tsx
D  apps/web/src/components/ui/VoiceModeToggle.tsx
D  apps/web/src/components/upload/FileUploader.tsx
D  apps/web/src/hooks/useGuestSession.ts
D  apps/web/src/lib/fetcher.ts
```

---

## 三、需要检查是否还在使用的文件

### 1. 迁移脚本（可能已完成迁移）

- `apps/api/scripts/migrate_to_unified_profile.py` - 检查是否已执行完成，完成后可归档
- `apps/api/scripts/migrate_profiles.py` - 同上

### 2. Playground Test Reports（可删除）

```
D  playwright-report/data/*.zip
D  playwright-report/data/*.webm
D  playwright-report/data/*.png
D  playwright-report/data/*.md
D  playwright-report/trace/*
```

---

## 四、执行清理步骤

### Step 1: 提交已删除的文件

```bash
# 查看待提交的删除
git status | grep "^D"

# 提交所有删除
git add -u
git commit -m "chore: clean up legacy code after VibeProfile refactor

- Remove legacy routes, services, and repositories
- Remove deprecated skill YAML methods
- Remove old web components
- Ref: docs/components/VibeProfile/SPEC.md"
```

### Step 2: 创建数据库清理迁移

创建 `apps/api/stores/migrations/017_drop_legacy_profile_tables.sql`：

```sql
-- VibeProfile 重构后清理废弃表
-- Ref: docs/components/VibeProfile/SPEC.md Section 6

-- 确认数据已迁移（打印行数供确认）
DO $$
DECLARE
    user_data_count INT;
    user_reminders_count INT;
    user_subscriptions_count INT;
    user_push_prefs_count INT;
    skill_blocks_count INT;
BEGIN
    SELECT COUNT(*) INTO user_data_count FROM user_data_store;
    SELECT COUNT(*) INTO user_reminders_count FROM user_reminders;
    SELECT COUNT(*) INTO user_subscriptions_count FROM user_skill_subscriptions;
    SELECT COUNT(*) INTO user_push_prefs_count FROM user_push_preferences;
    SELECT COUNT(*) INTO skill_blocks_count FROM skill_recommendation_blocks;

    RAISE NOTICE 'user_data_store: % rows', user_data_count;
    RAISE NOTICE 'user_reminders: % rows', user_reminders_count;
    RAISE NOTICE 'user_skill_subscriptions: % rows', user_subscriptions_count;
    RAISE NOTICE 'user_push_preferences: % rows', user_push_prefs_count;
    RAISE NOTICE 'skill_recommendation_blocks: % rows', skill_blocks_count;
END $$;

-- 删除废弃表
DROP TABLE IF EXISTS user_data_store CASCADE;
DROP TABLE IF EXISTS user_reminders CASCADE;
DROP TABLE IF EXISTS user_skill_subscriptions CASCADE;
DROP TABLE IF EXISTS user_push_preferences CASCADE;
DROP TABLE IF EXISTS skill_recommendation_blocks CASCADE;

-- 记录清理日志
COMMENT ON DATABASE vibelife IS 'Legacy profile tables dropped on 2026-01-19';
```

### Step 3: 执行迁移

```bash
# 测试环境执行
psql -d vibelife_test -f apps/api/stores/migrations/017_drop_legacy_profile_tables.sql

# 生产环境（务必先备份！）
pg_dump -h localhost -U postgres -d vibelife > backup_$(date +%Y%m%d_%H%M%S).sql
psql -d vibelife -f apps/api/stores/migrations/017_drop_legacy_profile_tables.sql
```

### Step 4: 验证系统正常

```bash
# 运行测试
pytest apps/api/tests/ -v

# 启动 API 检查无错误
./apps/api/start_api.sh
```

---

## 五、预期收益

### 代码库大小

- **删除文件数量**: ~120+ 个文件
- **减少代码行数**: ~15,000+ 行

### 数据库简化

- **删除表数量**: 5 个
- **统一入口**: `unified_profiles.profile` JSONB

### 维护成本

- **Repository 统一**: 从 10+ 个 repo 减少到 `VibeProfileRepository`
- **数据一致性**: 从多表关联改为单表 JSONB，避免数据不一致

---

## 六、Rollback Plan

如果清理后发现问题：

```bash
# 1. 恢复数据库
psql -d vibelife < backup_YYYYMMDD_HHMMSS.sql

# 2. 恢复代码
git revert <commit-hash>

# 3. 重新部署
./deploy.sh
```

---

## 检查清单

- [ ] **备份数据库** - 执行前务必完整备份
- [ ] **验证迁移完成** - 确认所有数据已迁移到 `unified_profiles`
- [ ] **测试环境验证** - 在测试环境先执行清理
- [ ] **运行完整测试** - 确保所有测试通过
- [ ] **提交代码删除** - `git commit` 提交已删除的文件
- [ ] **执行数据库迁移** - 删除废弃表
- [ ] **生产环境验证** - 监控日志，确保无错误
- [ ] **归档迁移脚本** - 将迁移脚本移到 archive 目录

---

**最后更新**: 2026-01-19
**负责人**: @vibelife-team
**参考文档**: `docs/components/VibeProfile/SPEC.md`
