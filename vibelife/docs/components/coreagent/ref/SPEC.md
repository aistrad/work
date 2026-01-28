# CoreAgent 上下文构建规范

> Version: 2.1 | 2026-01-20
> 核心改动：分阶段渐进式加载 + Skill 状态持久化

---

## 1. 设计原则

### 1.1 核心理念

**分阶段渐进式加载**：根据对话阶段按需加载上下文，避免不必要的 token 消耗。

| 原则 | 说明 |
|------|------|
| **按需加载** | 只加载当前阶段需要的数据 |
| **数据库优先** | 历史消息从数据库获取，不依赖前端传入 |
| **状态持久化** | Skill 状态同步到 conversation 表，跨请求恢复 |
| **同轮重载** | use_skill 后同一轮内重新构建上下文 |

### 1.2 与 vibe-agent 原则对齐

| vibe-agent 原则 | CoreAgent 实现 |
|----------------|---------------|
| Agentic Loop | 工具调用后获取结果再继续 |
| LLM 自主决策 | use_skill 工具让 LLM 选择 Skill |
| 渐进式加载 | Phase1/Phase2 分阶段加载 |
| Tool Use ACI | 工具定义包含示例和边界情况 |

---

## 2. 两阶段上下文模型

### 2.1 Phase 1: Skill 选择阶段

**触发条件**：`context.skill == None` 且未调用 `use_skill`

**目标**：帮助 LLM 理解用户意图，选择正确的 Skill

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: Skill 选择                                            │
├─────────────────────────────────────────────────────────────────┤
│  历史条数：5 条（从数据库）                                      │
│                                                                 │
│  System Prompt 组成：                                           │
│    ├─ Core Skill 基础人格（精简版）                             │
│    ├─ use_skill 工具定义（含 Skill 目录）                       │
│    └─ 无 profile / 无 Cases / 无 SOP                            │
│                                                                 │
│  Token 预算：~2000 tokens                                       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Phase 2: Skill 执行阶段

**触发条件**：
1. `context.skill` 有值（前端指定）
2. `use_skill` 工具被调用后（同轮切换）

**目标**：提供深度分析所需的完整上下文

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: Skill 执行                                            │
├─────────────────────────────────────────────────────────────────┤
│  历史条数：10 条（从数据库）                                     │
│                                                                 │
│  System Prompt 组成：                                           │
│    ├─ Skill 专家身份                                            │
│    ├─ SOP 规则（配置驱动）                                      │
│    ├─ Cases（倒排索引匹配）                                     │
│    └─ 当前 Skill 需要的数据（见 2.3）                           │
│                                                                 │
│  Token 预算：~8000 tokens                                       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Skill 数据需求映射

每个 Skill 只加载自己需要的数据：

| Skill | 需要的 Profile 字段 | 需要的 skill_data |
|-------|--------------------|--------------------|
| bazi | birth_info | skill_data.bazi |
| zodiac | birth_info | skill_data.zodiac |
| tarot | - | skill_data.tarot |
| career | life_context | skill_data.career |
| lifecoach | life_context, extracted | - |
| core | - | - |

**配置位置**：在 SKILL.md frontmatter 中声明

```yaml
# skills/bazi/SKILL.md
---
name: bazi
requires_birth_info: true
requires_compute: true
compute_type: bazi
profile_fields:
  - birth_info
  - skill_data.bazi
---
```

---

## 3. 历史消息管理

### 3.1 数据源

**唯一数据源**：数据库 `messages` 表

```python
# 删除前端传入机制
# ❌ history = request.get_history()
# ✅ history = await get_conversation_history(conversation_id, limit)
```

### 3.2 历史条数

| 阶段 | 条数 | 说明 |
|------|------|------|
| Phase 1 | 5 条 | 足够理解意图 |
| Phase 2 | 10 条 | 深度分析需要更多上下文 |

### 3.3 Tool 消息处理

数据库存储时保证 tool_calls 和 tool_result 配对完整。
`_filter_valid_history()` 作为防御性检查，过滤孤立消息。

---

## 4. use_skill 同轮重载

### 4.1 流程

```
用户消息: "帮我算个八字"
    │
    ▼
Phase 1 System Prompt (轻量)
    │
    ▼
LLM 调用 use_skill(skill="bazi", scenario="basic_reading")
    │
    ▼
_execute_tool() 检测到 skill 激活
    │
    ├─ 1. 设置 self._active_skill = "bazi"
    ├─ 2. 同步到数据库: UPDATE conversations SET skill = "bazi"  ← v8 新增
    ├─ 3. 加载 birth_info + skill_data.bazi
    ├─ 4. 重新构建 Phase 2 System Prompt
    └─ 5. 更新 messages[0]（system message）
    │
    ▼
返回 tool_result: {"status": "activated", "skill": "bazi", ...}
    │
    ▼
前端显示: "✨ 已激活八字命理"（用户等待反馈）
    │
    ▼
LLM 继续执行（使用新的 System Prompt）
    │
    ▼
深度分析输出
```

### 4.2 Skill 状态持久化（v8 新增）

**问题**：use_skill 激活的 skill 在下一轮请求时丢失（CoreAgent 是无状态的）

**解决方案**：同步到 `conversations.skill` 字段

```
┌────────┐     ┌────────┐     ┌──────────┐     ┌────────────┐
│ 前端   │     │chat_v5 │     │CoreAgent │     │conversation│
└───┬────┘     └───┬────┘     └────┬─────┘     └─────┬──────┘
    │              │               │                  │
    │ 请求1: "算八字" │              │                  │
    │ skill=null   │               │                  │
    │─────────────▶│               │                  │
    │              │ run(skill=null)                  │
    │              │──────────────▶│                  │
    │              │               │ use_skill(bazi)  │
    │              │               │ UPDATE skill     │
    │              │               │─────────────────▶│ skill="bazi"
    │◀─────────────────────────────│                  │
    │              │               │                  │
    │ 请求2: "继续" │               │                  │
    │ skill=null   │               │                  │
    │─────────────▶│               │                  │
    │              │ 查 conversation│                  │
    │              │──────────────────────────────────▶│
    │              │ skill="bazi" ✅│                  │
    │              │◀──────────────────────────────────│
    │              │ run(skill="bazi")                │
    │              │──────────────▶│                  │
```

**实现位置**：
- `core.py:_handle_use_skill()` - 同步 skill 到数据库
- `chat_v5.py:generate()` - 从 conversation 恢复 skill

### 4.3 前端显示

use_skill 返回的 tool_result 触发前端显示激活状态：

```typescript
// 前端处理 tool_result
if (toolResult.name === "use_skill" && toolResult.result.status === "activated") {
  showSkillActivation(toolResult.result.skill);
}
```

---

## 5. System Prompt 构建

### 5.1 Phase 1 Prompt 结构

```markdown
# Vibe - 生命对话者

你是 Vibe，一个生命对话者。

## 你的能力
- 深度倾听和情绪感知
- 引导用户探索自我
- 根据需要激活专业技能

## 工具使用
当用户需要专业分析时，使用 use_skill 工具激活对应技能。

[use_skill 工具定义，含 Skill 目录]
```

### 5.2 Phase 2 Prompt 结构

```markdown
# {Skill Name} - {Expert Persona}

{Skill 专家身份描述}

## SOP 执行规则
{根据配置动态生成}

## 相关案例
{Case 匹配结果}

## 用户数据
### 出生信息
{birth_info}

### 命盘数据
{skill_data.{skill}}

## 工具调用规则
{Skill 特定的工具调用规则}
```

---

## 6. 接口变更

### 6.1 ChatRequestV5

```python
class ChatRequestV5(BaseModel):
    message: Optional[str] = None
    messages: Optional[list[MessageItem]] = None  # 保留但不用于 history
    conversation_id: Optional[UUID] = None
    skill: Optional[str] = None
    voice_mode: Optional[str] = None

    def get_user_message(self) -> str:
        """提取用户消息"""
        if self.message:
            return self.message
        if self.messages:
            for msg in reversed(self.messages):
                if msg.role == "user":
                    return msg.content
        return ""

    # 删除 get_history() 方法
```

### 6.2 AgentContext

```python
@dataclass
class AgentContext:
    user_id: str
    user_tier: str = "free"
    profile: Optional[Dict[str, Any]] = None      # Phase 2 才加载
    skill_data: Optional[Dict[str, Any]] = None   # Phase 2 才加载，只含当前 skill
    history: Optional[List[Dict[str, str]]] = None  # 从数据库获取
    skill: Optional[str] = None
    scenario: Optional[str] = None
    conversation_id: Optional[str] = None
    voice_mode: Optional[str] = "warm"
```

---

## 7. 性能预期

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| Phase 1 System Prompt | ~5000 tokens | ~2000 tokens |
| Phase 2 System Prompt | ~8000 tokens | ~6000 tokens |
| 首 Token 时间 (TTFT) | ~800ms | ~500ms |
| 数据库查询 | 1 次（全量 profile） | 按需查询 |

---

## 8. 迁移计划

### Phase 1: 历史来源改造
1. 删除 `request.get_history()` 调用
2. 使用 `get_conversation_history()` 从数据库获取
3. 测试历史消息正确性

### Phase 2: 分阶段加载
1. 修改 `_build_system_prompt()` 支持 lightweight 模式
2. 修改 `_build_initial_messages()` 根据阶段选择历史条数
3. 测试 Phase 1/Phase 2 切换

### Phase 3: use_skill 同轮重载
1. 修改 `_execute_tool()` 检测 skill 激活
2. 实现同轮 System Prompt 重载
3. 测试完整流程

---

## 附录

### A. 相关文件

| 文件 | 说明 |
|------|------|
| `services/agent/core.py` | CoreAgent 主逻辑 |
| `services/agent/skill_loader.py` | Skill 加载和 Prompt 构建 |
| `routes/chat_v5.py` | Chat API 入口 |
| `stores/message_repo.py` | 消息存储 |
| `stores/unified_profile_repo.py` | Profile 数据访问 |
| `stores/conversation_repo.py` | Conversation 存储（含 skill 状态） |

### B. 版本历史

- **v2.1** (2026-01-20): Skill 状态持久化，use_skill 同步到 conversation 表
- **v2.0** (2026-01-20): 分阶段渐进式加载，历史来源改为数据库
- **v1.0** (2026-01-15): 初始版本
