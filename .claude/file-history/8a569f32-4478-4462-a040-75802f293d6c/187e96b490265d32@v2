# VibeProfile 全方位测试方案

> **版本**: 1.0 | **环境**: 测试环境 (aiscend) | **创建时间**: 2026-01-19

## 测试目标

全方位验证 VibeProfile 数据层的正确性、性能和可靠性,包括:
- 数据库 CRUD 操作
- 缓存机制
- Skill 访问权限
- Proactive 推送流程
- 数据迁移完整性
- API 端到端测试

---

## 测试环境配置

### 数据库连接
```bash
# 使用测试环境数据库
VIBELIFE_DB_URL=postgresql://postgres:<PASSWORD>@106.37.170.238:8224/vibelife
```

### 测试数据准备
```sql
-- 创建测试用户
INSERT INTO vibe_users (id, vibe_id, email, display_name, tier, status)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'VB-TEST0001', 'test1@vibelife.com', '测试用户1', 'free', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'VB-TEST0002', 'test2@vibelife.com', '测试用户2', 'premium', 'active'),
  ('33333333-3333-3333-3333-333333333333', 'VB-TEST0003', 'test3@vibelife.com', '测试用户3', 'free', 'active');

-- 创建初始 Profile
INSERT INTO unified_profiles (user_id, profile)
VALUES
  ('11111111-1111-1111-1111-111111111111', '{
    "account": {
      "vibe_id": "VB-TEST0001",
      "display_name": "测试用户1",
      "email": "test1@vibelife.com",
      "tier": "free",
      "status": "active"
    },
    "identity": {
      "birth_info": {
        "date": "1990-05-15",
        "time": "14:30:00",
        "place": "北京",
        "timezone": "Asia/Shanghai",
        "gender": "male"
      }
    },
    "state": {
      "emotion": "neutral",
      "focus": ["career"],
      "life_stage": "career_growth"
    },
    "preferences": {
      "voice_mode": "warm",
      "language": "zh-CN",
      "push_enabled": true,
      "push_hour": 8,
      "subscribed_skills": ["core", "bazi"],
      "data_retention": {
        "conversations": "1y"
      }
    },
    "skill_data": {},
    "extracted": {
      "facts": ["在互联网公司工作"],
      "goals": ["年底升职"],
      "concerns": ["工作压力"]
    },
    "life_context": {
      "occupation": {
        "title": "产品经理",
        "industry": "互联网"
      },
      "focus_areas": ["career"],
      "goals": [],
      "tasks": [],
      "checkins": {},
      "reminders": []
    }
  }'::jsonb);
```

---

## 测试用例设计

### 1. 数据库层测试 (Unit Tests)

#### 1.1 Profile CRUD 操作

**测试文件**: `apps/api/tests/unit/stores/test_vibe_profile_repo.py`

```python
import pytest
from uuid import UUID
from stores.unified_profile_repo import UnifiedProfileRepository
from datetime import datetime, date

# 测试用户 ID
TEST_USER_1 = UUID('11111111-1111-1111-1111-111111111111')
TEST_USER_2 = UUID('22222222-2222-2222-2222-222222222222')

@pytest.fixture
async def repo():
    """初始化 Repository"""
    return UnifiedProfileRepository()

class TestProfileRead:
    """测试 Profile 读取操作"""

    async def test_get_profile_complete(self, repo):
        """测试读取完整 Profile"""
        profile = await repo.get_profile(TEST_USER_1)

        assert profile is not None
        assert profile['account']['vibe_id'] == 'VB-TEST0001'
        assert profile['identity']['birth_info']['date'] == '1990-05-15'
        assert 'career' in profile['state']['focus']

    async def test_get_birth_info(self, repo):
        """测试读取 birth_info"""
        birth_info = await repo.get_birth_info(TEST_USER_1)

        assert birth_info['date'] == '1990-05-15'
        assert birth_info['time'] == '14:30:00'
        assert birth_info['timezone'] == 'Asia/Shanghai'

    async def test_get_skill_data(self, repo):
        """测试读取 skill_data"""
        skill_data = await repo.get_skill_data(TEST_USER_1, 'bazi')

        # 首次应该为空字典
        assert skill_data == {} or skill_data is None

    async def test_get_life_context(self, repo):
        """测试读取 life_context"""
        life_context = await repo.get_life_context(TEST_USER_1)

        assert life_context['occupation']['title'] == '产品经理'
        assert life_context['focus_areas'] == ['career']
        assert isinstance(life_context['goals'], list)

    async def test_get_preferences(self, repo):
        """测试读取 preferences"""
        preferences = await repo.get_preferences(TEST_USER_1)

        assert preferences['voice_mode'] == 'warm'
        assert preferences['push_enabled'] is True
        assert preferences['push_hour'] == 8
        assert 'bazi' in preferences['subscribed_skills']

    async def test_get_extracted(self, repo):
        """测试读取 extracted"""
        extracted = await repo.get_extracted(TEST_USER_1)

        assert '在互联网公司工作' in extracted['facts']
        assert '年底升职' in extracted['goals']

class TestProfileWrite:
    """测试 Profile 写入操作"""

    async def test_update_birth_info(self, repo):
        """测试更新 birth_info"""
        new_birth_info = {
            'date': '1992-08-20',
            'time': '10:00:00',
            'place': '上海',
            'timezone': 'Asia/Shanghai',
            'gender': 'female'
        }

        await repo.update_birth_info(TEST_USER_1, new_birth_info)

        # 验证更新
        birth_info = await repo.get_birth_info(TEST_USER_1)
        assert birth_info['date'] == '1992-08-20'
        assert birth_info['place'] == '上海'

    async def test_update_state(self, repo):
        """测试更新 state"""
        new_state = {
            'emotion': 'excited',
            'focus': ['health', 'relationship'],
            'life_stage': 'family_building'
        }

        await repo.update_state(TEST_USER_1, new_state)

        # 验证更新
        profile = await repo.get_profile(TEST_USER_1)
        assert profile['state']['emotion'] == 'excited'
        assert 'health' in profile['state']['focus']

    async def test_update_skill_data(self, repo):
        """测试更新 skill_data"""
        bazi_data = {
            'chart': {
                'year': '庚午',
                'month': '己巳',
                'day': '甲子',
                'hour': '丙寅'
            },
            'daymaster': '甲',
            'strength': '偏弱'
        }

        await repo.update_skill_data(TEST_USER_1, 'bazi', bazi_data)

        # 验证更新
        skill_data = await repo.get_skill_data(TEST_USER_1, 'bazi')
        assert skill_data['daymaster'] == '甲'
        assert skill_data['strength'] == '偏弱'

    async def test_update_preferences(self, repo):
        """测试更新 preferences"""
        new_preferences = {
            'voice_mode': 'professional',
            'push_hour': 20,
            'subscribed_skills': ['core', 'bazi', 'zodiac', 'tarot']
        }

        await repo.update_preferences(TEST_USER_1, new_preferences)

        # 验证更新
        preferences = await repo.get_preferences(TEST_USER_1)
        assert preferences['voice_mode'] == 'professional'
        assert preferences['push_hour'] == 20
        assert 'tarot' in preferences['subscribed_skills']

class TestLifeContext:
    """测试 life_context 操作"""

    async def test_add_goal(self, repo):
        """测试添加目标"""
        goal = {
            'title': '学习英语',
            'category': 'learning',
            'status': 'active',
            'progress': 0.0,
            'deadline': '2026-12-31'
        }

        goal_id = await repo.add_goal(TEST_USER_1, goal)

        # 验证添加
        life_context = await repo.get_life_context(TEST_USER_1)
        goals = life_context['goals']
        assert len(goals) == 1
        assert goals[0]['title'] == '学习英语'
        assert goals[0]['id'] == goal_id

    async def test_update_goal(self, repo):
        """测试更新目标"""
        # 先添加目标
        goal = {'title': '减肥10斤', 'category': 'health', 'status': 'active'}
        goal_id = await repo.add_goal(TEST_USER_1, goal)

        # 更新目标
        updates = {'progress': 0.5, 'status': 'active'}
        await repo.update_goal(TEST_USER_1, goal_id, updates)

        # 验证更新
        life_context = await repo.get_life_context(TEST_USER_1)
        updated_goal = next(g for g in life_context['goals'] if g['id'] == goal_id)
        assert updated_goal['progress'] == 0.5

    async def test_add_task(self, repo):
        """测试添加任务"""
        task = {
            'title': '准备季度汇报',
            'status': 'pending',
            'due_date': '2026-01-25'
        }

        task_id = await repo.add_task(TEST_USER_1, task)

        # 验证添加
        life_context = await repo.get_life_context(TEST_USER_1)
        tasks = life_context['tasks']
        assert len(tasks) == 1
        assert tasks[0]['title'] == '准备季度汇报'

    async def test_add_checkin(self, repo):
        """测试添加打卡"""
        checkin = {
            'mood': 8,
            'energy': 7,
            'notes': '今天很棒'
        }

        today = date.today().isoformat()
        await repo.add_checkin(TEST_USER_1, today, checkin)

        # 验证添加
        life_context = await repo.get_life_context(TEST_USER_1)
        checkins = life_context['checkins']
        assert today in checkins
        assert checkins[today]['mood'] == 8

    async def test_add_reminder(self, repo):
        """测试添加提醒"""
        reminder = {
            'type': 'daily_plan',
            'title': '每日计划提醒',
            'schedule_type': 'daily',
            'trigger_hour': 9,
            'status': 'active'
        }

        reminder_id = await repo.add_reminder(TEST_USER_1, reminder)

        # 验证添加
        life_context = await repo.get_life_context(TEST_USER_1)
        reminders = life_context['reminders']
        assert len(reminders) == 1
        assert reminders[0]['trigger_hour'] == 9

    async def test_checkins_cleanup_30days(self, repo):
        """测试打卡数据只保留 30 天"""
        from datetime import timedelta

        # 添加 35 天的打卡数据
        for i in range(35):
            checkin_date = (date.today() - timedelta(days=i)).isoformat()
            await repo.add_checkin(TEST_USER_1, checkin_date, {
                'mood': 7,
                'energy': 6
            })

        # 执行清理
        await repo.cleanup_old_checkins(TEST_USER_1, keep_days=30)

        # 验证只保留 30 天
        life_context = await repo.get_life_context(TEST_USER_1)
        checkins = life_context['checkins']
        assert len(checkins) <= 30

class TestSkillSubscriptions:
    """测试 Skill 订阅管理"""

    async def test_subscribe_skill(self, repo):
        """测试订阅 Skill"""
        await repo.subscribe(TEST_USER_1, 'zodiac')

        # 验证订阅
        subscription = await repo.get_skill_subscription(TEST_USER_1, 'zodiac')
        assert subscription['status'] == 'subscribed'
        assert subscription['push_enabled'] is True

    async def test_unsubscribe_skill(self, repo):
        """测试取消订阅 Skill"""
        await repo.subscribe(TEST_USER_1, 'tarot')
        await repo.unsubscribe(TEST_USER_1, 'tarot')

        # 验证取消订阅
        subscription = await repo.get_skill_subscription(TEST_USER_1, 'tarot')
        assert subscription['status'] == 'unsubscribed'

    async def test_update_push_enabled(self, repo):
        """测试更新推送开关"""
        await repo.subscribe(TEST_USER_1, 'career')
        await repo.update_push(TEST_USER_1, 'career', False)

        # 验证推送已关闭
        subscription = await repo.get_skill_subscription(TEST_USER_1, 'career')
        assert subscription['push_enabled'] is False

    async def test_get_user_subscriptions(self, repo):
        """测试获取用户所有订阅"""
        subscriptions = await repo.get_user_subscriptions(TEST_USER_1)

        assert isinstance(subscriptions, list)
        assert any(s['skill_id'] == 'core' for s in subscriptions)
        assert any(s['skill_id'] == 'bazi' for s in subscriptions)

    async def test_can_use_skill_core(self, repo):
        """测试 core skill 访问权限 (始终可用)"""
        can_use = await repo.can_use_skill(TEST_USER_1, 'core')
        assert can_use is True

    async def test_can_use_skill_trial(self, repo):
        """测试试用额度"""
        # 首次使用应该可以
        can_use = await repo.can_use_skill(TEST_USER_1, 'zodiac')
        assert can_use is True

        # 增加试用次数
        for _ in range(3):
            await repo.increment_trial_usage(TEST_USER_1, 'zodiac')

        # 超过试用额度后应该不可用 (free 用户)
        can_use = await repo.can_use_skill(TEST_USER_1, 'zodiac')
        assert can_use is False

class TestPushSettings:
    """测试推送设置"""

    async def test_get_push_settings(self, repo):
        """测试获取推送设置"""
        settings = await repo.get_push_settings(TEST_USER_1)

        assert settings['default_push_hour'] == 8
        assert settings['max_daily_pushes'] >= 0

    async def test_upsert_push_settings(self, repo):
        """测试更新推送设置"""
        new_settings = {
            'default_push_hour': 20,
            'max_daily_pushes': 10,
            'quiet_start_hour': 22,
            'quiet_end_hour': 7
        }

        await repo.upsert_push_settings(TEST_USER_1, new_settings)

        # 验证更新
        settings = await repo.get_push_settings(TEST_USER_1)
        assert settings['default_push_hour'] == 20

    async def test_is_in_quiet_hours(self, repo):
        """测试免打扰时段判断"""
        await repo.upsert_push_settings(TEST_USER_1, {
            'quiet_start_hour': 22,
            'quiet_end_hour': 7
        })

        # 23:00 应该在免打扰时段
        is_quiet = await repo.is_in_quiet_hours(TEST_USER_1, 23)
        assert is_quiet is True

        # 10:00 不在免打扰时段
        is_quiet = await repo.is_in_quiet_hours(TEST_USER_1, 10)
        assert is_quiet is False

class TestCache:
    """测试缓存机制"""

    async def test_cache_hit(self, repo):
        """测试缓存命中"""
        from stores.profile_cache import _cache, get_cached_profile

        # 第一次读取 (miss)
        profile1 = await get_cached_profile(TEST_USER_1)

        # 第二次读取 (hit)
        profile2 = await get_cached_profile(TEST_USER_1)

        # 应该是同一个对象
        assert profile1 == profile2
        assert str(TEST_USER_1) in _cache

    async def test_cache_invalidation(self, repo):
        """测试缓存失效"""
        from stores.profile_cache import get_cached_profile, invalidate_cache

        # 读取并缓存
        profile1 = await get_cached_profile(TEST_USER_1)

        # 更新数据
        await repo.update_state(TEST_USER_1, {'emotion': 'happy'})

        # 手动失效缓存
        invalidate_cache(TEST_USER_1)

        # 重新读取
        profile2 = await get_cached_profile(TEST_USER_1)

        # 应该是新数据
        assert profile2['state']['emotion'] == 'happy'

    async def test_cache_ttl(self, repo):
        """测试缓存 TTL (5分钟)"""
        import asyncio
        from stores.profile_cache import get_cached_profile, TTL

        # 读取并缓存
        await get_cached_profile(TEST_USER_1)

        # 等待超过 TTL (模拟)
        # 实际测试中可以 mock 时间或缩短 TTL
        # await asyncio.sleep(TTL + 1)

        # 重新读取应该从数据库获取
        # ...
```

---

### 2. API 端到端测试 (E2E Tests)

**测试文件**: `apps/api/tests/integration/routes/test_profile_api.py`

```python
import pytest
from httpx import AsyncClient
from main import app

@pytest.fixture
async def client():
    """创建测试客户端"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def auth_headers():
    """模拟认证头"""
    # 使用测试用户的 JWT token
    return {
        'Authorization': 'Bearer test_token_user1'
    }

class TestProfileAPI:
    """测试 Profile API"""

    async def test_get_profile(self, client, auth_headers):
        """测试获取 Profile"""
        response = await client.get('/api/v1/account/profile', headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert data['account']['vibe_id'] == 'VB-TEST0001'
        assert 'identity' in data
        assert 'life_context' in data

    async def test_update_profile(self, client, auth_headers):
        """测试更新 Profile"""
        update_data = {
            'state': {
                'emotion': 'content',
                'focus': ['health', 'career']
            },
            'preferences': {
                'voice_mode': 'calm',
                'push_hour': 18
            }
        }

        response = await client.put(
            '/api/v1/account/profile',
            headers=auth_headers,
            json=update_data
        )

        assert response.status_code == 200

        # 验证更新
        get_response = await client.get('/api/v1/account/profile', headers=auth_headers)
        profile = get_response.json()
        assert profile['state']['emotion'] == 'content'
        assert profile['preferences']['voice_mode'] == 'calm'

    async def test_get_identity_prism(self, client, auth_headers):
        """测试获取 Identity Prism"""
        response = await client.get('/api/v1/account/identity/prism', headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert 'birth_info' in data
        assert 'skill_data' in data

    async def test_export_profile_gdpr(self, client, auth_headers):
        """测试 GDPR 数据导出"""
        response = await client.get('/api/v1/account/profile/export', headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert 'profile' in data
        assert 'conversations' in data
        assert 'billing' in data

class TestSkillsAPI:
    """测试 Skills API"""

    async def test_get_subscriptions(self, client, auth_headers):
        """测试获取订阅列表"""
        response = await client.get('/api/v1/skills/subscriptions', headers=auth_headers)

        assert response.status_code == 200
        subscriptions = response.json()
        assert isinstance(subscriptions, list)
        assert any(s['skill_id'] == 'core' for s in subscriptions)

    async def test_subscribe_skill(self, client, auth_headers):
        """测试订阅 Skill"""
        response = await client.post(
            '/api/v1/skills/zodiac/subscribe',
            headers=auth_headers
        )

        assert response.status_code == 200

        # 验证订阅成功
        get_response = await client.get('/api/v1/skills/subscriptions', headers=auth_headers)
        subscriptions = get_response.json()
        zodiac_sub = next(s for s in subscriptions if s['skill_id'] == 'zodiac')
        assert zodiac_sub['status'] == 'subscribed'

    async def test_unsubscribe_skill(self, client, auth_headers):
        """测试取消订阅 Skill"""
        # 先订阅
        await client.post('/api/v1/skills/tarot/subscribe', headers=auth_headers)

        # 取消订阅
        response = await client.post(
            '/api/v1/skills/tarot/unsubscribe',
            headers=auth_headers
        )

        assert response.status_code == 200

    async def test_update_push_status(self, client, auth_headers):
        """测试更新推送状态"""
        response = await client.post(
            '/api/v1/skills/bazi/push',
            headers=auth_headers,
            json={'enabled': False}
        )

        assert response.status_code == 200
```

---

### 3. Proactive Worker 测试

**测试文件**: `apps/api/tests/integration/workers/test_proactive_worker.py`

```python
import pytest
from workers.proactive_worker import ProactiveWorker
from stores.unified_profile_repo import UnifiedProfileRepository

class TestProactiveWorker:
    """测试 Proactive Worker"""

    async def test_get_users_for_push(self):
        """测试获取需要推送的用户 (按小时)"""
        repo = UnifiedProfileRepository()

        # 获取 8 点推送的用户
        users = await repo.get_users_for_push(push_hour=8)

        assert isinstance(users, list)
        # TEST_USER_1 设置了 push_hour=8
        assert any(u['user_id'] == '11111111-1111-1111-1111-111111111111' for u in users)

    async def test_daily_scan(self):
        """测试每日扫描"""
        worker = ProactiveWorker()

        # 执行每日扫描
        result = await worker.daily_scan()

        assert result['scanned_users'] > 0
        assert result['notifications_created'] >= 0

    async def test_reminder_trigger(self):
        """测试提醒触发"""
        repo = UnifiedProfileRepository()

        # 添加一个每日提醒
        await repo.add_reminder(TEST_USER_1, {
            'type': 'daily_plan',
            'title': '每日计划',
            'schedule_type': 'daily',
            'trigger_hour': 9,
            'status': 'active'
        })

        # 获取 9 点需要提醒的用户
        users = await repo.get_users_with_reminders(trigger_hour=9)

        assert any(u['user_id'] == str(TEST_USER_1) for u in users)

    async def test_notification_delivery(self):
        """测试通知投递"""
        worker = ProactiveWorker()

        # 模拟当前小时投递
        from datetime import datetime
        current_hour = datetime.now().hour

        result = await worker.deliver_notifications(current_hour)

        assert 'delivered_count' in result
```

---

### 4. 数据迁移测试

**测试文件**: `apps/api/tests/integration/migrations/test_profile_migration.py`

```python
import pytest

class TestProfileMigration:
    """测试数据迁移完整性"""

    async def test_migrate_subscribed_skills(self):
        """测试 subscribed_skills 迁移"""
        # 1. 准备旧数据 (user_skill_subscriptions)
        # 2. 运行迁移脚本
        # 3. 验证 unified_profiles.profile.preferences.subscribed_skills
        pass

    async def test_migrate_push_preferences(self):
        """测试 push_preferences 迁移"""
        # 1. 准备旧数据 (user_push_preferences)
        # 2. 运行迁移脚本
        # 3. 验证 unified_profiles.profile.preferences.push_settings
        pass

    async def test_migrate_goals(self):
        """测试 goals 迁移"""
        # 1. 准备旧数据 (user_data_store, data_type='goals')
        # 2. 运行迁移脚本
        # 3. 验证 unified_profiles.profile.life_context.goals
        pass

    async def test_migrate_checkins_30days_only(self):
        """测试 checkins 迁移只保留 30 天"""
        # 1. 准备 60 天的 checkins 数据
        # 2. 运行迁移脚本
        # 3. 验证只有 30 天被迁移
        pass
```

---

### 5. Skill 访问权限测试

**测试文件**: `apps/api/tests/integration/skills/test_skill_access.py`

```python
import pytest
from services.agent.core import CoreAgent

class TestSkillAccess:
    """测试 Skill 访问权限"""

    async def test_core_skill_read_all(self):
        """测试 core skill 可以读取全部 Profile"""
        # Core skill 应该可以读取所有字段
        pass

    async def test_core_skill_write_limited(self):
        """测试 core skill 只能写 state, extracted"""
        # Core skill 应该可以写 state, extracted
        # 但不能写 identity, skill_data
        pass

    async def test_bazi_skill_read_limited(self):
        """测试 bazi skill 只能读 identity, state"""
        # Bazi skill 应该可以读 identity, state
        # 但不能读 life_context
        pass

    async def test_bazi_skill_write_own_data(self):
        """测试 bazi skill 只能写自己的 skill_data"""
        # Bazi skill 应该可以写 skill_data.bazi
        # 但不能写 skill_data.zodiac
        pass
```

---

### 6. 性能测试

**测试文件**: `apps/api/tests/performance/test_profile_performance.py`

```python
import pytest
import asyncio
from time import time

class TestProfilePerformance:
    """测试 Profile 性能"""

    async def test_read_performance_with_cache(self):
        """测试缓存读取性能"""
        repo = UnifiedProfileRepository()

        # 第一次读取 (miss)
        start = time()
        await repo.get_profile(TEST_USER_1)
        first_read_time = time() - start

        # 第二次读取 (hit)
        start = time()
        await repo.get_profile(TEST_USER_1)
        cached_read_time = time() - start

        # 缓存读取应该明显更快
        assert cached_read_time < first_read_time * 0.5

    async def test_concurrent_reads(self):
        """测试并发读取"""
        repo = UnifiedProfileRepository()

        # 100 个并发读取
        tasks = [repo.get_profile(TEST_USER_1) for _ in range(100)]

        start = time()
        results = await asyncio.gather(*tasks)
        duration = time() - start

        assert len(results) == 100
        assert duration < 1.0  # 应该在 1 秒内完成

    async def test_jsonb_update_performance(self):
        """测试 JSONB 部分更新性能"""
        repo = UnifiedProfileRepository()

        # 10 次更新
        start = time()
        for i in range(10):
            await repo.update_state(TEST_USER_1, {'emotion': f'state_{i}'})
        duration = time() - start

        # 平均每次更新应该在 100ms 内
        avg_time = duration / 10
        assert avg_time < 0.1

    async def test_profile_size_limits(self):
        """测试 Profile 大小限制"""
        repo = UnifiedProfileRepository()

        # 添加 20 个 goals (达到上限)
        for i in range(20):
            await repo.add_goal(TEST_USER_1, {
                'title': f'目标 {i}',
                'category': 'test'
            })

        # 第 21 个应该失败
        with pytest.raises(Exception):
            await repo.add_goal(TEST_USER_1, {
                'title': '超额目标',
                'category': 'test'
            })
```

---

## 测试执行

### 运行所有测试
```bash
cd /home/aiscend/work/vibelife/apps/api

# 运行所有 VibeProfile 相关测试
pytest tests/ -v -k "profile or vibe_profile" --tb=short

# 运行单个测试文件
pytest tests/unit/stores/test_vibe_profile_repo.py -v

# 运行特定测试类
pytest tests/unit/stores/test_vibe_profile_repo.py::TestProfileRead -v

# 生成覆盖率报告
pytest tests/ --cov=stores.unified_profile_repo --cov-report=html
```

### 性能测试
```bash
# 运行性能测试
pytest tests/performance/test_profile_performance.py -v --durations=10
```

---

## 测试数据清理

```sql
-- 清理测试数据
DELETE FROM unified_profiles WHERE user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
);

DELETE FROM vibe_users WHERE vibe_id LIKE 'VB-TEST%';
DELETE FROM conversations WHERE user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
);
```

---

## 测试覆盖率目标

| 模块 | 目标覆盖率 |
|------|-----------|
| UnifiedProfileRepository | 90% |
| ProfileCache | 85% |
| Profile API Routes | 85% |
| Proactive Worker | 80% |
| Migration Scripts | 75% |

---

## 真实场景测试用例

### 场景 1: 新用户注册完整流程
1. 创建用户账户
2. 初始化 Profile
3. 完成 onboarding 填写 birth_info
4. 订阅第一个 skill (bazi)
5. 生成 bazi chart
6. 保存到 skill_data.bazi

### 场景 2: 用户添加目标并打卡
1. 用户添加目标 "每周运动3次"
2. 添加提醒 (每天 20:00)
3. 每天打卡记录
4. 30 天后自动清理旧打卡数据

### 场景 3: Premium 用户订阅多个 Skill
1. 用户升级到 Premium
2. 订阅 zodiac, tarot, career
3. 设置推送时间为 8:00
4. 每日自动生成运势推送

### 场景 4: 数据导出 (GDPR)
1. 用户请求导出数据
2. 导出完整 Profile
3. 导出所有对话历史
4. 导出支付记录
5. 生成 JSON 文件

---

## 监控指标

### 数据库性能
- Profile 读取平均响应时间 < 50ms (有缓存)
- Profile 读取平均响应时间 < 200ms (无缓存)
- JSONB 更新平均响应时间 < 100ms
- 并发读取 QPS > 1000

### 缓存效率
- 缓存命中率 > 80%
- 缓存失效及时性 < 5s

### 数据大小
- 单个 Profile JSONB 大小 < 20KB
- 95% 用户 Profile < 15KB

---

## 问题排查清单

### Profile 读取失败
- [ ] 检查数据库连接
- [ ] 检查 user_id 是否存在
- [ ] 检查 JSONB 格式是否正确
- [ ] 检查缓存是否异常

### Profile 更新失败
- [ ] 检查 JSONB 路径是否正确
- [ ] 检查数据类型是否匹配
- [ ] 检查约束条件 (如 goals 数量限制)
- [ ] 检查缓存是否已失效

### Proactive 推送未触发
- [ ] 检查用户 push_enabled 状态
- [ ] 检查 push_hour 设置
- [ ] 检查 subscribed_skills 列表
- [ ] 检查 Worker 是否正常运行
- [ ] 检查免打扰时段设置

---

## 附录: 测试环境搭建脚本

```bash
#!/bin/bash
# setup_test_env.sh

# 1. 创建测试数据库
psql $VIBELIFE_DB_URL -c "CREATE DATABASE vibelife_test;"

# 2. 运行迁移
cd /home/aiscend/work/vibelife/apps/api
alembic upgrade head

# 3. 创建测试用户
psql $VIBELIFE_DB_URL -f tests/fixtures/test_users.sql

# 4. 安装测试依赖
pip install pytest pytest-asyncio pytest-cov httpx

# 5. 运行测试
pytest tests/ -v --cov
```
