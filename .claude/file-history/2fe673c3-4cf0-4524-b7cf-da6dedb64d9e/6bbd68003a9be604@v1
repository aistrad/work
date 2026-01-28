# VibeLife V8.1 重构方案

> 日期: 2026-01-20
> 目标: 简化协议执行架构，实现 Chat-First + LLM 驱动

---

## 1. 重构背景

### 1.1 当前问题

| 问题 | 现状 | 影响 |
|-----|------|-----|
| Protocol 工具过多 | start_protocol, advance_protocol_step 等 8 个工具 | 复杂度高，LLM 不一定调用 |
| 状态管理分散 | 前端 + 后端 + 数据库 | 容易丢失上下文 |
| Rule 文件未加载 | _route_scenario 返回默认值 | dankoe.md 没有进入 System Prompt |
| 设计冲突 | 方案 D vs Protocol 工具方案 | 两种方案都没完整实现 |

### 1.2 根本原因

用户说"帮我用 Dan Koe 方法"后，AI 开始问问题，但：
1. `_route_scenario` 返回 "basic_reading"（默认值）
2. `dankoe.md` 没有被加载到 System Prompt
3. LLM 没有协议细节，凭"记忆"执行
4. 后续请求丢失上下文，跳出协议

---

## 2. 重构目标

### 2.1 核心目标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           重构目标                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 简化架构                                                              │
│     • 删除 Protocol 工具，采用方案 D（纯 Prompt 驱动）                    │
│     • Rule 文件 + save_skill_data = 完整协议                             │
│                                                                          │
│  2. 确保 Rule 加载                                                        │
│     • 前端显式传 scenario 参数                                           │
│     • 后端智能路由作为 fallback                                          │
│                                                                          │
│  3. Chat-First 体验                                                       │
│     • Journey/Me 页面只负责展示                                          │
│     • 所有深度交互回到 Chat                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 成功标准

- [ ] 用户点击 Journey [开始设计我的人生] → 正确执行 Dan Koe 6 问
- [ ] 用户在 Chat 中说"帮我用 Dan Koe 方法" → 正确执行 Dan Koe 6 问
- [ ] 协议中断后恢复 → LLM 从对话历史判断进度，继续执行
- [ ] 协议完成 → 数据正确保存到 VibeProfile
- [ ] Journey 页面 → 正确展示保存的数据

---

## 3. 重构清单

### Phase 1: 前端修改（已完成 ✅）

| 任务 | 文件 | 状态 |
|-----|------|------|
| 所有可控入口加 scenario 参数 | `JourneyContent.tsx` | ✅ |
| EmptyJourneyCard 加 scenario 参数 | `EmptyJourneyCard.tsx` | ✅ |

**修改内容**：

```typescript
// 修改前
router.push("/chat?skill=lifecoach&prompt=我想做一次人生重置");

// 修改后
router.push("/chat?skill=lifecoach&scenario=dankoe&prompt=我想做一次人生重置");
```

### Phase 2: 后端 - ChatRequestV5 新增 scenario（已完成 ✅）

| 任务 | 文件 | 状态 |
|-----|------|------|
| 新增 scenario 字段 | chat_v5.py | ✅ |

**修改内容**：

```python
class ChatRequestV5(BaseModel):
    skill: Optional[str] = None
    scenario: Optional[str] = None  # 新增
    # ...
```

### Phase 3: 后端 - 优先使用前端传参（待完成）

| 任务 | 文件 | 状态 |
|-----|------|------|
| 解析 scenario 参数 | chat_v5.py | ⏳ |
| 传递给 AgentContext | chat_v5.py | ⏳ |
| CoreAgent 使用 scenario | core.py | ⏳ |

**修改内容**：

```python
# chat_v5.py - generate() 函数中

# 1. 获取前端传的 scenario
active_scenario = request.scenario

# 2. 如果没有，使用智能路由
if not active_scenario and active_skill:
    active_scenario = await route_scenario_by_tags(active_skill, user_message)

# 3. 传递给 AgentContext
context = AgentContext(
    user_id=str(user_id) if user_id else "guest",
    user_tier=user_tier,
    profile=profile,
    skill_data=skill_data,
    history=history,
    skill=active_skill,
    scenario=active_scenario,  # 新增
    voice_mode=request.voice_mode,
    conversation_id=str(conversation_id)
)
```

### Phase 4: 后端 - 智能路由 fallback（待完成）

| 任务 | 文件 | 状态 |
|-----|------|------|
| 实现 route_scenario_by_tags | chat_v5.py 或 skill_loader.py | ⏳ |

**修改内容**：

```python
# chat_v5.py 或 skill_loader.py

async def route_scenario_by_tags(skill_id: str, message: str) -> Optional[str]:
    """基于 tags 匹配最佳 rule（作为 fallback）"""
    from services.agent.skill_loader import has_rules, load_rule, SKILLS_DIR

    if not has_rules(skill_id):
        return None

    rules_dir = SKILLS_DIR / skill_id / "rules"
    message_lower = message.lower()

    for rule_path in rules_dir.glob("*.md"):
        # 跳过 _index.md 等
        if rule_path.stem.startswith("_"):
            continue
        # 跳过 companion 子目录
        if rule_path.is_dir():
            continue

        rule = load_rule(skill_id, rule_path.stem)
        if rule and rule.tags:
            for tag in rule.tags:
                if tag.lower() in message_lower:
                    logger.info(f"[route_scenario] Matched rule={rule_path.stem} by tag={tag}")
                    return rule_path.stem

    return None
```

### Phase 5: 后端 - AgentContext 新增 scenario（待完成）

| 任务 | 文件 | 状态 |
|-----|------|------|
| AgentContext 新增 scenario 字段 | core.py | ⏳ |
| build_system_prompt 使用 scenario | core.py | ⏳ |

**修改内容**：

```python
# core.py

@dataclass
class AgentContext:
    user_id: str
    user_tier: str = "free"
    profile: Optional[Dict[str, Any]] = None
    skill_data: Optional[Dict[str, Any]] = None
    history: Optional[List[Dict[str, str]]] = None
    skill: Optional[str] = None
    scenario: Optional[str] = None  # 新增
    conversation_id: Optional[str] = None
    voice_mode: Optional[str] = "warm"

# core.py - _build_system_prompt 中

# 使用 context.scenario 而不是 self._active_scenario
if self._active_skill:
    scenario_id = context.scenario or self._active_scenario
    base_prompt = build_system_prompt(
        self._active_skill,
        scenario_id,  # 使用传入的 scenario
        user_ctx
    )
```

### Phase 6: 删除 Protocol 工具（待完成）

| 任务 | 文件 | 状态 |
|-----|------|------|
| 删除 Protocol 工具定义 | tools/tools.yaml | ⏳ |
| 删除 Protocol handlers | tools/handlers.py | ⏳ |
| 删除 protocols 目录 | protocols/ | ⏳ |
| 删除 chat_v5.py Protocol 逻辑 | chat_v5.py | ⏳ |
| 更新 SKILL.md | SKILL.md | ⏳ |

**需要删除的工具**：
- start_protocol
- continue_protocol
- advance_protocol_step
- cancel_protocol
- show_protocol_invitation
- show_protocol_progress
- show_protocol_step
- show_protocol_completion

**需要删除的文件**：
- apps/api/skills/lifecoach/protocols/dankoe.yaml
- apps/api/skills/lifecoach/protocols/engine.py（如果存在）

**需要删除的 chat_v5.py 代码**：
- load_protocol_config() 函数
- build_protocol_prompt() 函数
- get_protocol_state() 函数
- emit_protocol_progress_event() 函数
- async_generator() 函数
- Protocol 相关的 SSE 事件处理逻辑

---

## 4. 实施步骤

### Step 1: 完成 Phase 3-5（后端核心）

```bash
# 1. 修改 chat_v5.py
# 2. 修改 core.py
# 3. 测试：前端传 scenario 是否生效
```

### Step 2: 测试验证

```bash
# 测试 1: 前端显式传参
curl -X POST http://localhost:8000/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{
    "message": "我想做一次人生重置",
    "skill": "lifecoach",
    "scenario": "dankoe"
  }'

# 预期：System Prompt 包含 dankoe.md 内容

# 测试 2: 智能路由 fallback
curl -X POST http://localhost:8000/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{
    "message": "帮我用 Dan Koe 方法",
    "skill": "lifecoach"
  }'

# 预期：自动匹配到 dankoe，System Prompt 包含 dankoe.md 内容
```

### Step 3: 删除 Protocol 代码（Phase 6）

```bash
# 1. 删除 tools.yaml 中的 Protocol 工具
# 2. 删除 handlers.py 中的 Protocol handlers
# 3. 删除 protocols/ 目录
# 4. 删除 chat_v5.py 中的 Protocol 逻辑
# 5. 更新 SKILL.md，删除 Protocol 执行流程部分
```

### Step 4: 端到端测试

```bash
# 1. 启动测试环境
./scripts/start-test.sh

# 2. 访问 http://localhost:8232
# 3. 进入 Journey 页面
# 4. 点击 [开始设计我的人生]
# 5. 验证 Dan Koe 6 问流程
# 6. 验证数据保存
# 7. 验证 Journey 页面展示
```

---

## 5. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 智能路由匹配不准确 | 用户自由输入可能匹配到错误的 rule | 优先使用前端显式传参；优化 tags |
| 对话历史被截断 | LLM 丢失协议上下文 | 协议对话时增加 history 限制到 20 条 |
| LLM 忘记问某个问题 | 协议不完整 | Rule 文件中明确"必须按顺序完成所有问题" |
| 删除 Protocol 代码影响其他功能 | 系统不稳定 | 分步删除，每步测试 |

---

## 6. 时间估算

| Phase | 任务 | 估算 |
|-------|------|------|
| Phase 1-2 | 前端 + ChatRequestV5 | ✅ 已完成 |
| Phase 3-5 | 后端核心修改 | 1-2 小时 |
| Phase 6 | 删除 Protocol 代码 | 1 小时 |
| 测试 | 端到端测试 | 1 小时 |
| 总计 | | 3-4 小时 |

---

## 7. 后续优化

### 7.1 短期

- 优化 tags 匹配算法（支持优先级）
- 添加日志追踪路由决策
- 增加 history 限制配置

### 7.2 中期

- 支持多 rule 组合（如 dankoe + weekly-review）
- Rule 文件热更新（无需重启）
- 协议执行统计（完成率、中断率）

### 7.3 长期

- 用户自定义协议
- 协议模板市场
- AI 自动生成协议

---

## 8. 总结

本次重构的核心是简化：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           重构前 vs 重构后                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   重构前                              重构后                              │
│   ──────                              ──────                              │
│   8 个 Protocol 工具                  0 个 Protocol 工具                  │
│   前端+后端+数据库状态管理             LLM 自己管理（对话历史）             │
│   protocols/*.yaml 配置               rules/*.md 规则文件                 │
│   复杂的 SSE 事件                     简单的文本流                         │
│                                                                          │
│   Protocol = 工具 + 状态 + 配置       Protocol = Rule + save_skill_data  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

核心原则：让 LLM 做它擅长的事（理解上下文、控制对话流程），让代码做它擅长的事（数据存储、API 调用）。
