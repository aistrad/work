# Profile 分层架构实施记录

> 基于 v5 核心改动分析的 Profile 数据分层重构
>
> 创建日期：2026-01-11
> 版本：v5.3

---

## 一、执行摘要

### 背景

原有架构中，命盘数据（八字、星座）存储在 `user_profiles.basic` 字段中，导致：
1. 数据耦合：用户基础信息与 Skill 特定数据混在一起
2. 扩展困难：新增 Skill（如 MBTI）需要修改 basic 结构
3. 缓存效率低：任何字段更新都需要失效整个 Profile 缓存

### 解决方案

采用「混合模式」分层架构：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Profile 分层架构 v2.0                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   user_profiles 表（共享层）                                                │
│   ─────────────────────────────────────────────────────────────────────    │
│   • basic: 用户基础信息 + 关键字段副本                                      │
│     - birth_datetime, gender, name（通用）                                  │
│     - day_master_element, sun_sign, moon_sign（关键字段副本）               │
│   • life_context: 生活背景                                                  │
│   • ai_insights: AI 洞察                                                    │
│   • identity_prism: 多维身份融合                                            │
│   • preferences: 用户偏好                                                   │
│                                                                             │
│   user_skill_data 表（Skill 层）                                            │
│   ─────────────────────────────────────────────────────────────────────    │
│   • user_id, skill, data (JSONB)                                            │
│   • bazi: 完整八字命盘数据                                                  │
│   • zodiac: 完整星盘数据                                                    │
│   • 未来可扩展：mbti, numerology 等                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、数据库变更

### 2.1 新增表：user_skill_data

**迁移文件**：`migrations/014_user_skill_data.sql`

```sql
CREATE TABLE user_skill_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill VARCHAR(50) NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    input_hash VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, skill)
);

CREATE INDEX idx_user_skill_data_user ON user_skill_data(user_id);
CREATE INDEX idx_user_skill_data_skill ON user_skill_data(skill);
CREATE INDEX idx_user_skill_data_hash ON user_skill_data(input_hash);
```

### 2.2 数据结构示例

**bazi skill data**:
```json
{
  "chart": {
    "four_pillars": {...},
    "day_master": {"stem": "甲", "element": "wood"},
    "pattern": {"name": "正官格", "strength": "strong"},
    "five_elements": {"wood": 2, "fire": 1, "earth": 2, "metal": 1, "water": 2},
    "ten_gods": [...]
  }
}
```

**zodiac skill data**:
```json
{
  "chart": {
    "sun_sign": "金牛座",
    "moon_sign": "巨蟹座",
    "rising_sign": "处女座",
    "planets": [...],
    "aspects": [...],
    "dominant_element": "土",
    "dominant_modality": "固定"
  }
}
```

---

## 三、代码变更

### 3.1 新增文件

| 文件 | 说明 |
|------|------|
| `stores/skill_data_repo.py` | Skill 数据存储层，支持 CRUD 和 input_hash 校验 |
| `migrations/014_user_skill_data.sql` | 数据库迁移文件 |

### 3.2 修改文件

| 文件 | 变更说明 |
|------|----------|
| `services/vibe_engine/profile_cache.py` | 新增合并缓存支持 (profile + skill_data) |
| `services/vibe_engine/context.py` | 支持从 skill_data 读取命盘数据 |
| `services/vibe_engine/tool_executor.py` | 支持从 skill_data 读取命盘数据 |
| `routes/bazi.py` | 命盘数据存储到 user_skill_data 表 |
| `routes/zodiac.py` | 星盘数据存储到 user_skill_data 表 |
| `routes/chat.py` | 传递 skill_data 给 context.build() 和 execute_ui_tool() |
| `stores/__init__.py` | 导出 skill_data_repo |

---

## 四、缓存策略

### 4.1 合并缓存

采用「方案 A: 合并缓存」，将 profile 和 skill_data 一起缓存：

```python
async def get_cached_profile_with_skill(user_id: UUID, skill: str) -> Dict:
    """
    返回结构：
    {
        "profile": {...},        # user_profiles 表数据
        "skill_data": {...}      # user_skill_data 表数据
    }
    """
    cache_key = f"{user_id}:{skill}"
    # ...
```

### 4.2 缓存失效策略

| 场景 | 失效范围 |
|------|----------|
| profile 更新 | 失效 `{user_id}:*` 所有缓存 |
| skill_data 更新 | 只失效 `{user_id}:{skill}` 缓存 |

### 4.3 input_hash 机制

避免重复计算命盘：

```python
input_hash = compute_input_hash(birth_datetime, gender, location)

# 检查是否需要重新计算
needs_recalc = await skill_data_repo.check_needs_recalculate(
    user_id, "bazi", input_hash
)
if not needs_recalc:
    # 直接返回缓存的命盘数据
    return existing_chart
```

---

## 五、数据流

### 5.1 命盘计算流程

```
用户请求计算八字
       │
       ▼
┌──────────────────┐
│ 计算 input_hash  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     是      ┌──────────────────┐
│ 检查是否需要重算 │ ──────────▶ │ 返回缓存的命盘   │
└────────┬─────────┘             └──────────────────┘
         │ 否
         ▼
┌──────────────────┐
│ 计算八字命盘     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 存储到           │
│ user_skill_data  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 同步关键字段到   │
│ profile.basic    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 失效相关缓存     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 返回命盘数据     │
└──────────────────┘
```

### 5.2 对话 Context 构建流程

```
用户发送消息
       │
       ▼
┌──────────────────┐
│ 获取合并缓存     │
│ (profile +       │
│  skill_data)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 智能裁剪 Profile │
│ - Layer 1: basic │
│ - Layer 2: skill │
│ - Layer 3: life  │
│ - Layer 4: ai    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 构建 Context     │
│ 注入 LLM         │
��──────────────────┘
```

---

## 六、影响范围

### 6.1 受影响的模块

| 优先级 | 模块 | 影响说明 |
|--------|------|----------|
| 高 | tool_executor.py | 读取 basic.four_pillars, basic.sun_sign 等 |
| 高 | context.py | ✅ 已实现分层读取 |
| 高 | prism_generator.py | 存储 contribution 到 basic.{dimension} |
| 高 | kline_service.py | 读取 basic.birth_year, basic.day_master_element |
| 中 | portrait.py | 读取 basic.bazi_chart, basic.sun_sign 等 |
| 中 | rag_service.py | 读取 basic.day_master, basic.pattern 等 |
| 中 | greeting_service.py | 读取 basic.day_master_element |
| 中 | content_generator.py | 读取 basic.day_master_element |
| 低 | relationship_service.py | 读取 basic.element_tendency |
| 低 | vibe_link.py | 读取 basic.day_master_element, basic.zodiac_sign |
| 低 | report_service.py | 读取 basic.bazi_chart |
| 低 | image_generator.py | 读取 basic.day_master_element, basic.zodiac_sign |

### 6.2 兼容性

- **向后兼容**：所有读取 profile.basic 的代码仍然可以工作（关键字段副本）
- **渐进迁移**：新代码优先从 skill_data 读取，回退到 profile.basic

---

## 七、部署步骤

1. **运行数据库迁移**
   ```bash
   psql -d vibelife -f migrations/014_user_skill_data.sql
   ```

2. **部署 API 更新**
   - 新增 skill_data_repo.py
   - 更新 profile_cache.py
   - 更新 context.py
   - 更新 tool_executor.py
   - 更新 routes/bazi.py
   - 更新 routes/zodiac.py
   - 更新 routes/chat.py

3. **数据迁移（可选）**
   - 将现有 profile.basic.bazi 数据迁移到 user_skill_data 表
   - 将现有 profile.basic.zodiac 数据迁移到 user_skill_data 表

---

## 八、测试要点

1. **命盘计算**
   - 新用户首次计算八字，数据应存储到 user_skill_data 表
   - 同一用户再次计算（相同出生信息），应返回缓存数据
   - 修改出生信息后重新计算，应更新 user_skill_data 表

2. **对话 Context**
   - 对话中应能正确读取命盘数据
   - 切换 Skill 后应读取对应的命盘数据

3. **缓存**
   - 更新 profile 后，所有相关缓存应失效
   - 更新 skill_data 后，只有对应 skill 的缓存应失效

---

*文档版本：v5.3*
*创建日期：2026-01-11*
*作者：AI Code Review*
