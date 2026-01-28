# 用量统计系统迁移指南

**文档版本**: v2.0
**更新时间**: 2026-01-22
**适用范围**: VibeLife API 后端清理后的用量统计

---

## 一、架构变更概述

### 1.1 迁移原因

**废弃模块**: `apps/api/services/agent/usage_tracker.py`

**废弃原因**:
- 与 Agent 架构耦合过紧
- 功能单一，只支持简单计数
- 不支持成本估算和精细化计费
- 代码重复，维护成本高

**新架构优势**:
- 统一用量服务（独立于 Agent）
- 支持 LLM/Skill/Tool 精确计费
- 内置模型定价表和成本估算
- 支持多维度查询（按技能、按模型、按时间）

### 1.2 架构对比

| 维度 | 旧架构 (usage_tracker.py) | 新架构 (UsageService) |
|---|---|---|
| 位置 | `services/agent/usage_tracker.py` | `services/usage/service.py` |
| 依赖 | 依赖 Agent 模块 | 独立服务 |
| 功能 | 简单计数 | 完整计费系统 |
| 数据表 | 未定义/简单表 | `usage_events` + `skill_usage_log` |
| 成本估算 | ❌ 不支持 | ✅ 内置定价表 |
| 查询能力 | ❌ 弱 | ✅ 多维度聚合查询 |
| 向后兼容 | - | ✅ 提供兼容方法 |

---

## 二、新架构详解

### 2.1 UsageService 核心功能

**文件位置**: `apps/api/services/usage/service.py`

#### 记录方法

```python
from services.usage import UsageService
from uuid import UUID

# 1. 记录 LLM 调用（自动计算成本）
await UsageService.record_llm_call(
    user_id=UUID("..."),
    model="gpt-4o",
    input_tokens=1000,
    output_tokens=500,
    skill_id="bazi",           # 可选
    conversation_id=UUID("..."), # 可选
    metadata={"request_id": "..."}  # 可选
)

# 2. 记录 Skill 使用
await UsageService.record_skill_use(
    user_id=UUID("..."),
    skill_id="bazi",
    conversation_id=UUID("...")  # 可选
)

# 3. 记录 Tool 调用
await UsageService.record_tool_call(
    user_id=UUID("..."),
    tool_name="compute_bazi_chart",
    skill_id="bazi",  # 可选
    conversation_id=UUID("...")  # 可选
)

# 4. 记录对话（向后兼容）
await UsageService.record_conversation(
    user_id=UUID("..."),
    skill_id="bazi",  # 可选
    conversation_id=UUID("...")  # 可选
)
```

#### 查询方法

```python
from datetime import date

# 1. 获取今日用量
daily = await UsageService.get_daily_usage(user_id)
# 返回: {"llm_calls": 10, "conversations": 5, "tokens": 15000, "cost": 0.045}

# 2. 获取本月用量
monthly = await UsageService.get_monthly_usage(user_id)
# 返回: {"llm_calls": 150, "conversations": 80, "tokens": 200000, "cost": 0.60}

# 3. 获取计费汇总
billing = await UsageService.get_billing_summary(
    user_id=user_id,
    start_date=date(2026, 1, 1),
    end_date=date(2026, 2, 1)
)
# 返回: {
#   "llm_calls": 200,
#   "total_input_tokens": 150000,
#   "total_output_tokens": 50000,
#   "total_tokens": 200000,
#   "total_cost": 0.60,
#   "skill_uses": 120,
#   "tool_calls": 85,
#   "conversations": 90
# }

# 4. 按 Skill 统计用量
skill_usage = await UsageService.get_usage_by_skill(
    user_id=user_id,
    month=date(2026, 1, 1)
)
# 返回: [
#   {"skill_id": "bazi", "llm_calls": 80, "tokens": 100000, "cost": 0.30},
#   {"skill_id": "zodiac", "llm_calls": 50, "tokens": 60000, "cost": 0.18},
#   ...
# ]

# 5. 按模型统计用量
model_usage = await UsageService.get_usage_by_model(
    user_id=user_id,
    month=date(2026, 1, 1)
)
# 返回: [
#   {"model": "gpt-4o", "calls": 100, "input_tokens": 80000, "output_tokens": 30000, "cost": 0.35},
#   {"model": "glm-4-flash", "calls": 50, "input_tokens": 40000, "output_tokens": 15000, "cost": 0.0055},
#   ...
# ]
```

### 2.2 模型定价表

**支持的模型** (每 1M tokens, USD):

```python
MODEL_PRICING = {
    # Zhipu GLM
    "glm-4-flash": {"input": 0.1, "output": 0.1},
    "glm-4": {"input": 0.5, "output": 0.5},
    "glm-4-plus": {"input": 1.0, "output": 1.0},

    # DeepSeek
    "deepseek-chat": {"input": 0.14, "output": 0.28},
    "deepseek-reasoner": {"input": 0.55, "output": 2.19},

    # Gemini
    "gemini-flash": {"input": 0.075, "output": 0.3},
    "gemini-2.0-flash": {"input": 0.075, "output": 0.3},
    "gemini-pro": {"input": 0.5, "output": 1.5},

    # Claude
    "claude-sonnet": {"input": 3.0, "output": 15.0},
    "claude-3-5-sonnet": {"input": 3.0, "output": 15.0},
    "claude-opus": {"input": 15.0, "output": 75.0},

    # OpenAI
    "gpt-4o": {"input": 2.5, "output": 10.0},
    "gpt-4o-mini": {"input": 0.15, "output": 0.6},

    # Default (fallback)
    "default": {"input": 0.1, "output": 0.1},
}
```

**成本计算公式**:
```
cost = (input_tokens / 1,000,000) * pricing["input"] +
       (output_tokens / 1,000,000) * pricing["output"]
```

---

## 三、数据库表结构

### 3.1 usage_events 表

**用途**: 记录所有用量事件（LLM 调用、Skill 使用、Tool 调用等）

```sql
CREATE TABLE IF NOT EXISTS usage_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,

    -- 事件类型
    event_type VARCHAR(50) NOT NULL,  -- 'llm_call' | 'skill_use' | 'tool_call' | 'conversation'

    -- LLM 相关（仅 llm_call 类型）
    model VARCHAR(100),
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10, 6) DEFAULT 0,  -- USD

    -- 关联信息
    skill_id VARCHAR(50),
    tool_name VARCHAR(100),
    conversation_id UUID,

    -- 元数据
    metadata JSONB DEFAULT '{}',

    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_usage_events_user_time ON usage_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_events_type ON usage_events(event_type);
CREATE INDEX IF NOT EXISTS idx_usage_events_skill ON usage_events(skill_id);
CREATE INDEX IF NOT EXISTS idx_usage_events_conversation ON usage_events(conversation_id);
```

**注意**: 此表当前可能尚未创建迁移文件，需要创建。

### 3.2 skill_usage_log 表

**用途**: 记录 Skill 行为日志（用于推荐算法）

**位置**: `apps/api/stores/migrations/015_skill_subscriptions.sql`

```sql
CREATE TABLE IF NOT EXISTS skill_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,

    -- 行为类型
    action VARCHAR(50) NOT NULL,  -- chat | tool_call | view_card | subscribe | unsubscribe | try

    -- 元数据
    metadata JSONB DEFAULT '{}',

    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_usage_user_time ON skill_usage_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_skill ON skill_usage_log(skill_id);
CREATE INDEX IF NOT EXISTS idx_usage_action ON skill_usage_log(action);
```

**已创建**: ✅ 此表已在 migration 015 中创建

---

## 四、迁移步骤

### 4.1 创建 usage_events 表迁移

**文件**: `apps/api/stores/migrations/025_create_usage_events.sql`

```sql
-- VibeLife Migration 025: Create usage_events table
-- Purpose: Unified usage tracking with billing support
-- Date: 2026-01-22

CREATE TABLE IF NOT EXISTS usage_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,

    -- Event type
    event_type VARCHAR(50) NOT NULL,  -- 'llm_call' | 'skill_use' | 'tool_call' | 'conversation'

    -- LLM fields (for llm_call events)
    model VARCHAR(100),
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10, 6) DEFAULT 0,  -- USD

    -- Relations
    skill_id VARCHAR(50),
    tool_name VARCHAR(100),
    conversation_id UUID,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_usage_events_user_time
    ON usage_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_events_type
    ON usage_events(event_type);
CREATE INDEX IF NOT EXISTS idx_usage_events_skill
    ON usage_events(skill_id)
    WHERE skill_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_usage_events_conversation
    ON usage_events(conversation_id)
    WHERE conversation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_usage_events_model
    ON usage_events(model)
    WHERE model IS NOT NULL;

-- Partitioning (optional, for high volume)
-- CREATE TABLE usage_events_2026_01 PARTITION OF usage_events
--     FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

**执行迁移**:
```bash
# 方式 1: 手动执行
psql $VIBELIFE_DB_URL -f apps/api/stores/migrations/025_create_usage_events.sql

# 方式 2: 通过迁移脚本
python apps/api/scripts/run_migration_025.py
```

### 4.2 代码迁移

#### 旧代码 (usage_tracker.py)

```python
# ❌ 废弃写法
from services.agent.usage_tracker import UsageTracker

await UsageTracker.record(user_id, "llm_call", metadata={...})
usage = await UsageTracker.get_usage(user_id)
```

#### 新代码 (UsageService)

```python
# ✅ 新写法
from services.usage import UsageService
from uuid import UUID

# 记录 LLM 调用
await UsageService.record_llm_call(
    user_id=UUID(user_id),
    model="gpt-4o",
    input_tokens=1000,
    output_tokens=500,
    skill_id="bazi"
)

# 查询用量
usage = await UsageService.get_monthly_usage(UUID(user_id))
```

### 4.3 Agent 中的配额检查

**当前实现**: `apps/api/services/agent/__init__.py`

```python
class QuotaTracker:
    """简化配额追踪 - 委托到 UsageService"""

    @classmethod
    async def check(cls, user_id: str, tier: str):
        """检查配额"""
        if tier == "vip":
            return True, ""

        from services.usage import UsageService
        from uuid import UUID

        try:
            usage = await UsageService.get_monthly_usage(UUID(user_id))
            limits = TIER_LIMITS.get(tier, TIER_LIMITS["free"])

            if limits["calls"] > 0 and usage["llm_calls"] >= limits["calls"]:
                return False, "本月对话次数已用完"
            return True, ""
        except Exception:
            return True, ""

    @classmethod
    async def record(cls, user_id: str, usage: dict):
        """记录用量 - 已由 UsageService 处理"""
        pass
```

**说明**:
- `QuotaTracker` 只是一个轻量级代理
- 实际用量记录由 `UsageService` 在 LLM 调用时完成
- `record()` 方法保留用于向后兼容，但不做任何操作

---

## 五、使用示例

### 5.1 在 Chat 路由中集成

**文件**: `apps/api/routes/chat_v5.py`

```python
from services.agent import QuotaTracker
from services.usage import UsageService

@router.post("/stream")
async def chat_stream(request: ChatRequest, user: CurrentUser = Depends(get_optional_user)):
    # 1. 入口配额检查
    quota_ok, quota_message = await QuotaTracker.check(
        user_id=str(user.user_id),
        tier=user.tier
    )

    if not quota_ok:
        # 返回配额超限错误
        return EventSourceResponse(_quota_exceeded_response(quota_message, user.tier))

    # 2. 创建 Agent 并执行
    agent = create_agent()
    async for event in agent.run(...):
        # Stream events to client
        yield event

    # 3. 记录 LLM 用量（由 Agent 内部完成）
    # UsageService.record_llm_call() 在 LLMClient 中自动调用
```

### 5.2 在 Skill 中记录工具调用

```python
from services.usage import UsageService

async def compute_bazi_chart(user_id: str, birth_info: dict):
    """计算八字命盘"""

    # 执行计算...
    chart = calculate_chart(birth_info)

    # 记录 Tool 调用
    await UsageService.record_tool_call(
        user_id=UUID(user_id),
        tool_name="compute_bazi_chart",
        skill_id="bazi"
    )

    return chart
```

### 5.3 查询用户用量（管理后台）

```python
from services.usage import UsageService
from datetime import date

async def get_user_billing_report(user_id: str):
    """获取用户计费报告"""

    # 本月用量
    monthly = await UsageService.get_monthly_usage(UUID(user_id))

    # 按 Skill 统计
    skill_breakdown = await UsageService.get_usage_by_skill(
        user_id=UUID(user_id),
        month=date.today()
    )

    # 按模型统计
    model_breakdown = await UsageService.get_usage_by_model(
        user_id=UUID(user_id),
        month=date.today()
    )

    return {
        "summary": monthly,
        "by_skill": skill_breakdown,
        "by_model": model_breakdown
    }
```

---

## 六、测试验证

### 6.1 单元测试

**文件**: `apps/api/tests/unit/services/test_usage_service.py`

```python
import pytest
from services.usage import UsageService
from uuid import uuid4

@pytest.mark.asyncio
async def test_record_llm_call():
    """测试记录 LLM 调用"""
    user_id = uuid4()

    await UsageService.record_llm_call(
        user_id=user_id,
        model="gpt-4o",
        input_tokens=1000,
        output_tokens=500,
        skill_id="bazi"
    )

    # 验证记录
    usage = await UsageService.get_daily_usage(user_id)
    assert usage["llm_calls"] >= 1
    assert usage["tokens"] >= 1500

@pytest.mark.asyncio
async def test_cost_estimation():
    """测试成本估算"""
    user_id = uuid4()

    # 记录 GPT-4o 调用
    await UsageService.record_llm_call(
        user_id=user_id,
        model="gpt-4o",
        input_tokens=1_000_000,  # 1M tokens
        output_tokens=500_000     # 0.5M tokens
    )

    # 验证成本
    usage = await UsageService.get_monthly_usage(user_id)
    expected_cost = (1.0 * 2.5) + (0.5 * 10.0)  # $2.5 + $5.0 = $7.5
    assert abs(usage["cost"] - expected_cost) < 0.01
```

### 6.2 集成测试

```bash
# 启动测试环境
bash scripts/start-test.sh

# 执行测试
cd apps/api
pytest tests/unit/services/test_usage_service.py -v
```

### 6.3 E2E 测试

```python
import asyncio
from services.usage import UsageService
from uuid import UUID

async def test_e2e_usage_tracking():
    """端到端测试：模拟完整对话流程"""
    user_id = UUID("test-user-id")

    # 1. 记录对话
    await UsageService.record_conversation(
        user_id=user_id,
        skill_id="bazi"
    )

    # 2. 记录 LLM 调用
    await UsageService.record_llm_call(
        user_id=user_id,
        model="glm-4-flash",
        input_tokens=800,
        output_tokens=400,
        skill_id="bazi"
    )

    # 3. 记录 Tool 调用
    await UsageService.record_tool_call(
        user_id=user_id,
        tool_name="compute_bazi_chart",
        skill_id="bazi"
    )

    # 4. 验证用量
    usage = await UsageService.get_daily_usage(user_id)

    print(f"Today's usage: {usage}")
    assert usage["llm_calls"] == 1
    assert usage["conversations"] == 1
    assert usage["tokens"] == 1200
    assert usage["cost"] > 0

if __name__ == "__main__":
    asyncio.run(test_e2e_usage_tracking())
```

---

## 七、注意事项

### 7.1 向后兼容性

✅ **兼容方法已提供**:

```python
# 旧代码仍可工作（通过兼容方法）
await UsageService.record_usage(
    user_id=UUID(user_id),
    usage_type="conversation",
    metadata={"skill": "bazi"}
)
```

但建议尽快迁移到新的 API:
```python
# 推荐使用新 API
await UsageService.record_conversation(
    user_id=UUID(user_id),
    skill_id="bazi"
)
```

### 7.2 性能优化

**高并发场景**:
- 使用异步记录（已实现）
- 记录失败不阻塞主流程
- 考虑批量插入（未来优化）

**大数据量场景**:
- 启用表分区（按月）
- 定期归档历史数据
- 使用物化视图加速查询

**示例：启用分区**:
```sql
-- 创建分区表
CREATE TABLE usage_events_2026_01 PARTITION OF usage_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE usage_events_2026_02 PARTITION OF usage_events
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

### 7.3 数据隐私

- 敏感信息不存储在 `metadata` 中
- 支持用户删除时级联删除用量数据
- 定期审计用量数据访问日志

---

## 八、FAQ

### Q1: 为什么要删除 usage_tracker.py?

**A**: 旧的 `usage_tracker.py` 功能单一，只能做简单计数，不支持：
- 成本估算
- 多维度查询
- LLM token 统计
- 精细化计费

新的 `UsageService` 是完整的计费系统，支持所有上述功能。

### Q2: usage_events 表还没创建怎么办?

**A**: 执行迁移文件创建表（见 4.1 节）。如果暂时不需要详细用量，系统会优雅降级，不影响核心功能。

### Q3: 现有代码需要修改吗?

**A**: 不需要。`QuotaTracker` 已经自动委托到 `UsageService`，现有代码无需修改。但建议新代码直接使用 `UsageService`。

### Q4: 如何添加新的模型定价?

**A**: 编辑 `services/usage/service.py` 中的 `MODEL_PRICING` 字典:

```python
MODEL_PRICING = {
    # ... existing models

    # 添加新模型
    "new-model-name": {"input": 0.5, "output": 1.0},
}
```

### Q5: 如何查询某个用户的总费用?

**A**: 使用 `get_billing_summary()`:

```python
from datetime import date

billing = await UsageService.get_billing_summary(
    user_id=UUID(user_id),
    start_date=date(2026, 1, 1),
    end_date=date(2026, 2, 1)
)

total_cost = billing["total_cost"]  # USD
```

---

## 九、下一步

### 9.1 立即执行

- [ ] 创建 `025_create_usage_events.sql` 迁移文件
- [ ] 执行数据库迁移
- [ ] 验证 `UsageService` 功能
- [ ] 提交旧 `usage_tracker.py` 的删除

### 9.2 未来优化

- [ ] 添加批量记录 API（减少数据库写入）
- [ ] 实现用量配额告警
- [ ] 创建用量分析 Dashboard
- [ ] 导出用量报表 API
- [ ] 集成计费系统（Stripe/Paddle）

---

## 十、相关资源

### 代码文件

- **新实现**: `apps/api/services/usage/service.py`
- **Agent 集成**: `apps/api/services/agent/__init__.py` (QuotaTracker)
- **Chat 路由**: `apps/api/routes/chat_v5.py`
- **测试**: `apps/api/tests/unit/services/test_usage_service.py`

### 数据库迁移

- **Skill 日志**: `apps/api/stores/migrations/015_skill_subscriptions.sql`
- **用量事件**: `apps/api/stores/migrations/025_create_usage_events.sql` (待创建)

### 文档

- **冗余代码分析**: `REDUNDANT_CODE_ANALYSIS.md`
- **架构文档**: `docs/archive/v8/ARCHITECTURE.md`

---

**维护者**: VibeLife 后端团队
**联系方式**: 见项目 README
**最后更新**: 2026-01-22
