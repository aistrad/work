# Protocol 测试脚本问题分析与改进方案

## 执行时间
2026-01-20

## 问题发现

### 现状
`apps/api/scripts/test_protocol_scenarios.py` 存在以下问题：

### ❌ 问题 1: 真实数据库访问，无隔离
- **现象**: 直接写入 `106.37.170.238:8224/vibelife` 数据库
- **影响**: 测试数据污染真实测试环境
- **风险等级**: 🔴 高

### ❌ 问题 2: 测试用户不存在
```python
TEST_USER_COMPLETE = UUID("00000000-0000-0000-0000-000000000001")
TEST_USER_INTERRUPT = UUID("00000000-0000-0000-0000-000000000002")
TEST_USER_CANCEL = UUID("00000000-0000-0000-0000-000000000003")
TEST_USER_BOUNDARY = UUID("00000000-0000-0000-0000-000000000004")
```

**验证结果**（2026-01-20）:
```
00000000-0000-0000-0000-000000000001: 不存在
00000000-0000-0000-0000-000000000002: 不存在
00000000-0000-0000-0000-000000000003: 不存在
00000000-0000-0000-0000-000000000004: 不存在
```

**行为分析**:
- `UnifiedProfileRepository.update_skill_state()` 会自动创建 `unified_profiles` 记录
- **但不会创建** `vibe_users` 记录
- 导致数据不一致（有 profile，无 user）

### ⚠️ 问题 3: 数据清理不完整
```python
async def cleanup_test_user(user_id: UUID):
    await UnifiedProfileRepository.update_skill_state(
        user_id,
        "lifecoach",
        "protocol",
        {"completed": True, "id": None, "step": 0}
    )
```

**问题**:
- 只清理 `protocol` 字段，不删除记录
- 测试数据会永久保留在数据库中
- 重复运行会累积垃圾数据

### ❌ 问题 4: 无事务回滚
- 测试失败后数据不会自动清理
- 需要手动清理或重建数据库

---

## 改进方案

### 方案 A: 使用真实测试用户（推荐）

**优势**: 最接近真实场景，简单可靠

**步骤**:
1. 创建专用测试用户
2. 使用真实 UUID
3. 测试后完全清理数据

**实现**:
```python
# 1. 创建测试用户脚本
# apps/api/scripts/create_test_users.py

import asyncio
from uuid import UUID
from stores.user_repo import UserRepository
from stores.unified_profile_repo import UnifiedProfileRepository

TEST_USERS = [
    {
        "id": UUID("00000000-0000-0000-0000-000000000001"),
        "email": "test-protocol-complete@vibelife.test",
        "vibe_id": "VB-TEST0001",
        "display_name": "测试用户-完整流程"
    },
    {
        "id": UUID("00000000-0000-0000-0000-000000000002"),
        "email": "test-protocol-interrupt@vibelife.test",
        "vibe_id": "VB-TEST0002",
        "display_name": "测试用户-中断恢复"
    },
    {
        "id": UUID("00000000-0000-0000-0000-000000000003"),
        "email": "test-protocol-cancel@vibelife.test",
        "vibe_id": "VB-TEST0003",
        "display_name": "测试用户-协议取消"
    },
    {
        "id": UUID("00000000-0000-0000-0000-000000000004"),
        "email": "test-protocol-boundary@vibelife.test",
        "vibe_id": "VB-TEST0004",
        "display_name": "测试用户-边界情况"
    },
]

async def create_test_users():
    for user in TEST_USERS:
        # 创建 vibe_users 记录
        await UserRepository.create_user(
            user_id=user["id"],
            email=user["email"],
            vibe_id=user["vibe_id"]
        )

        # 创建 unified_profiles 记录
        await UnifiedProfileRepository.create_profile(
            user["id"],
            {
                "account": {
                    "vibe_id": user["vibe_id"],
                    "display_name": user["display_name"],
                    "tier": "free",
                    "status": "active"
                }
            }
        )
        print(f"✅ 创建测试用户: {user['display_name']} ({user['vibe_id']})")

if __name__ == "__main__":
    asyncio.run(create_test_users())
```

**2. 更新测试脚本的清理逻辑**:
```python
async def cleanup_test_user(user_id: UUID):
    """完全清理测试用户数据"""
    try:
        # 清理 lifecoach skill 的所有数据
        await UnifiedProfileRepository.update_skill_state(
            user_id,
            "lifecoach",
            "protocol",
            {}  # 清空整个 protocol section
        )

        # 可选：清空整个 skills.lifecoach
        skill_data = await UnifiedProfileRepository.get_skill_state(user_id, "lifecoach")
        if skill_data:
            await execute(
                """UPDATE unified_profiles
                   SET profile = jsonb_set(
                       profile,
                       '{skills}',
                       (profile -> 'skills') - 'lifecoach'
                   )
                   WHERE user_id = $1""",
                user_id
            )
    except Exception as e:
        print(f"⚠️ 清理失败: {e}")
```

**3. 添加测试前检查**:
```python
async def verify_test_users_exist():
    """验证测试用户存在"""
    test_users = [
        TEST_USER_COMPLETE,
        TEST_USER_INTERRUPT,
        TEST_USER_CANCEL,
        TEST_USER_BOUNDARY,
    ]

    for user_id in test_users:
        user = await UserRepository.get_by_id(user_id)
        if not user:
            raise RuntimeError(
                f"测试用户 {user_id} 不存在！\n"
                f"请先运行: python scripts/create_test_users.py"
            )

    print("✅ 所有测试用户已就绪")
```

---

### 方案 B: 使用测试数据库（完全隔离）

**优势**: 完全隔离，不污染任何数据

**步骤**:
1. 创建专用测试数据库 `vibelife_test`
2. 每次测试前重置数据库
3. 测试后销毁数据库

**实现**:
```python
# apps/api/scripts/test_protocol_scenarios.py

import os

# 设置测试数据库
os.environ["VIBELIFE_DB_URL"] = "postgresql://postgres:PASSWORD@106.37.170.238:8224/vibelife_test"

async def setup_test_db():
    """初始化测试数据库"""
    # 创建测试用户
    await create_test_users()

async def teardown_test_db():
    """清理测试数据库"""
    # 删除所有测试数据
    await execute("TRUNCATE TABLE unified_profiles, vibe_users, conversations, messages CASCADE")
```

**缺点**: 需要额外的数据库配置和维护

---

### 方案 C: Mock Repository（单元测试）

**优势**: 完全不访问数据库，快速执行

**步骤**:
1. Mock `UnifiedProfileRepository` 的所有方法
2. 使用内存字典模拟数据存储
3. 测试完成后自动清理

**实现**:
```python
from unittest.mock import AsyncMock, patch

# In-memory storage
_mock_profiles = {}

async def mock_update_skill_state(user_id, skill_id, section, data):
    if user_id not in _mock_profiles:
        _mock_profiles[user_id] = {"skills": {}}
    if skill_id not in _mock_profiles[user_id]["skills"]:
        _mock_profiles[user_id]["skills"][skill_id] = {}
    _mock_profiles[user_id]["skills"][skill_id][section] = data

async def mock_get_skill_state(user_id, skill_id):
    return _mock_profiles.get(user_id, {}).get("skills", {}).get(skill_id, {})

# 在测试中使用
with patch.object(
    UnifiedProfileRepository,
    "update_skill_state",
    side_effect=mock_update_skill_state
):
    # 运行测试
    await test_scenario_complete_flow()
```

**缺点**: 不能测试真实数据库行为（如 JSON 合并、SQL 语法等）

---

## 推荐方案

**立即采用**: **方案 A - 使用真实测试用户**

**原因**:
1. ✅ 测试真实数据库行为（JSON 合并、索引、约束等）
2. ✅ 实现简单，只需创建一次测试用户
3. ✅ 可靠性高，接近生产环境
4. ✅ 易于调试（可直接查询数据库）

**后续考虑**: 方案 B（完全隔离的测试数据库）用于 CI/CD 流程

---

## 行动计划

### P0 - 立即执行
1. ✅ 分析问题（已完成）
2. 创建 `scripts/create_test_users.py`
3. 运行脚本创建测试用户
4. 更新 `test_protocol_scenarios.py` 的清理逻辑
5. 添加测试前的用户验证

### P1 - 短期优化
1. 添加完整的数据清理逻辑
2. 添加测试报告生成功能
3. 记录测试覆盖率

### P2 - 长期规划
1. 搭建专用测试数据库（CI/CD）
2. 集成到自动化测试流程
3. 添加性能基准测试

---

## 测试执行建议

### 当前状态
**不建议直接运行** `python scripts/test_protocol_scenarios.py`

**原因**:
- 会创建孤立的 `unified_profiles` 记录（无对应 `vibe_users`）
- 数据清理不完整
- 可能导致数据不一致

### 正确流程
1. 先创建测试用户：
   ```bash
   python scripts/create_test_users.py
   ```

2. 再运行测试：
   ```bash
   python scripts/test_protocol_scenarios.py
   ```

3. 验证数据清理：
   ```bash
   psql $VIBELIFE_DB_URL -c "
   SELECT profile -> 'skills' -> 'lifecoach'
   FROM unified_profiles
   WHERE user_id = '00000000-0000-0000-0000-000000000001'
   "
   ```

---

## 结论

虽然 `test_protocol_scenarios.py` 设计完善（5个场景覆盖全面），但**当前不适合直接运行**，需要先完成测试用户创建和清理逻辑改进。

**下一步**: 创建 `create_test_users.py` 并改进清理逻辑，然后再执行测试。
