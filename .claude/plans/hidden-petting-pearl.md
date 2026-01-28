# VibeProfile 重构计划

> 基于 VibeProfile 规范彻底重构，删除无用代码和数据结构

## 目标

将分散的用户数据表合并到 `unified_profiles.profile` (Single JSONB)，删除废弃表和代码。

## 当前 vs 目标结构

```
当前 (分散)                              目标 (统一)
─────────────────────────────────────────────────────────────────
user_skill_subscriptions  ──────►  preferences.subscribed_skills
user_push_preferences     ──────►  preferences.push_settings
user_data_store          ──────►  life_context (goals/tasks/checkins/reminders)
skill_recommendation_blocks ────►  preferences.blocked_skills
```

## 需要删除的文件

| 文件 | 原因 |
|------|------|
| `stores/skill_subscription_repo.py` | 功能迁移到 VibeProfileRepository |
| `skills/core/services/user_data.py` | 功能迁移到 VibeProfileRepository |

## 需要修改的文件

| 文件 | 改动 |
|------|------|
| `stores/unified_profile_repo.py` | 添加 subscription/push/life_context 方法 |
| `services/proactive/engine.py` | 改用 VibeProfileRepository |
| `services/proactive/trigger_detector.py` | 更新 profile 访问方式 |
| `routes/skills.py` | 改用 VibeProfileRepository |
| `skills/core/services/card.py` | 更新 path 数据源解析 |

## 执行步骤

### Step 1: 扩展 UnifiedProfileRepository

在 `stores/unified_profile_repo.py` 添加：

```python
# Subscription 相关
async def get_subscribed_skills(user_id) -> Dict[str, SkillSubscription]
async def update_skill_subscription(user_id, skill_id, status, push_enabled)
async def get_subscribed_skill_ids(user_id) -> List[str]

# Push 相关
async def get_push_settings(user_id) -> Dict
async def update_push_settings(user_id, settings)

# Life Context 相关 (替代 UserDataService)
async def read_life_context_path(user_id, path) -> Dict
async def write_life_context_path(user_id, path, content)

# Blocked Skills
async def get_blocked_skills(user_id) -> List[str]
async def block_skill(user_id, skill_id)
```

### Step 2: 数据迁移脚本

创建 `scripts/migrate_to_unified_profile.py`：

1. user_skill_subscriptions → preferences.subscribed_skills
2. user_push_preferences → preferences.push_settings
3. user_data_store → life_context
4. skill_recommendation_blocks → preferences.blocked_skills

### Step 3: 更新依赖代码

1. `services/proactive/engine.py` - 改用 VibeProfileRepository
2. `routes/skills.py` - 改用 VibeProfileRepository
3. `skills/core/services/card.py` - 更新 path 数据源

### Step 4: 删除废弃代码

1. 删除 `stores/skill_subscription_repo.py`
2. 删除 `skills/core/services/user_data.py`
3. 清理 imports

### Step 5: 数据库清理 (迁移文件)

创建 `migrations/020_drop_deprecated_tables.sql`：
- DROP TABLE user_skill_subscriptions
- DROP TABLE user_push_preferences
- DROP TABLE user_data_store
- DROP TABLE skill_recommendation_blocks

## 验证方法

1. 运行现有测试: `pytest apps/api/tests/`
2. 手动测试订阅 API: `GET /api/v1/skills/subscriptions`
3. 测试推送系统: `python workers/proactive_worker.py --dry-run`

## 决策

1. **skill_usage_log 表**: ✅ 删除（用户确认）
2. **API 兼容性**: ✅ 保持兼容（见分析）

## API 兼容性分析

### 当前 API 端点 (routes/skills.py)

| 端点 | 响应格式 | 兼容方案 |
|------|---------|---------|
| `GET /skills` | `{skills: [{user_status: {...}}]}` | VibeProfileRepository 返回相同结构 |
| `GET /skills/subscriptions` | `{subscriptions: [...], summary: {...}}` | 保持不变，从 profile.preferences.subscribed_skills 构建 |
| `POST /{skill_id}/subscribe` | `{subscription: {...}}` | 返回相同的 SkillSubscription 结构 |
| `POST /{skill_id}/unsubscribe` | `{subscription: {...}}` | 返回相同的 SkillSubscription 结构 |
| `POST /{skill_id}/push` | `{subscription: {...}}` | 返回相同的 SkillSubscription 结构 |

### 关键数据结构（保持不变）

```python
# SkillSubscription 结构
{
    "skill_id": str,
    "status": str,  # subscribed | unsubscribed
    "push_enabled": bool,
    "subscribed_at": str | None,
    "unsubscribed_at": str | None,
    "trial_messages_used": int
}

# user_status 结构
{
    "subscribed": bool,
    "push_enabled": bool,
    "trial_messages_used": int,
    "trial_messages_remaining": int | None
}
```

### 兼容方案

在 `VibeProfileRepository` 中提供与 `SkillSubscriptionRepository` 相同的接口：

```python
class VibeProfileRepository:
    # 保持相同的返回类型
    async def get_skill_subscription(user_id, skill_id) -> Optional[SkillSubscription]:
        profile = await self.get_profile(user_id)
        subs = profile.get("preferences", {}).get("subscribed_skills", {})
        if skill_id in subs:
            return SkillSubscription(**subs[skill_id])
        return None
```

**结论**: API 响应格式可以保持完全不变，前端无需修改
