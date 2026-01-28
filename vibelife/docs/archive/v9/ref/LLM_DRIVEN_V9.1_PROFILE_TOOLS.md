# VibeLife v9.1 LLM 驱动架构升级 - Profile 工具化

> **版本**: 9.1
> **日期**: 2026-01-24
> **状态**: 设计完成
> **核心变更**: 新增 `get_user_profile` 工具，消除数据预加载硬编码

---

## 1. 问题分析

### 1.1 当前架构与 Claude SDK 的差距

| 维度 | Claude SDK 标准 | VibeLife v9 现状 | 差距 |
|------|----------------|-----------------|------|
| SDK 使用 | `anthropic.Client` | 自建 `LLMClient` 兼容层 | ✓ 可接受 |
| Agentic Loop | `while stop_reason == "tool_use"` | ✓ 流式实现 | 符合 |
| Tool Calling | LLM 决定调用什么工具 | ✓ 工具选择由 LLM | 符合 |
| **数据获取** | LLM 通过工具按需获取 | ❌ Python 预加载 | **不符合** |
| **决策逻辑** | LLM 自主决策 | ❌ Python 硬编码判断 | **不符合** |

### 1.2 硬编码问题清单

#### 问题 1：数据预加载

**位置**: `routes/chat_v5.py:101-126`

```python
# Phase 1: 自动加载轻量 profile
# Phase 2: 自动加载完整 profile + skill_data
profile, skill_data = await get_user_context(user_id, body.skill)
```

**问题**: Python 决定何时加载数据，而不是 LLM 通过工具请求。

#### 问题 2：硬编码 Skill 集合

**位置**: `services/agent/prompt_builder.py:46-47`

```python
BIRTH_INFO_SKILLS = {"bazi", "zodiac", "jungastro"}
```

**问题**: 应该从配置读取或让 LLM 自行判断。

#### 问题 3：硬编码状态判断

**位置**: `services/agent/prompt_builder.py:326-357`

```python
has_chart = bool(data.get("chart") or data.get("cards"))
if has_chart:
    # 跳过计算
```

**问题**: Python 决定是否需要计算，而不是 LLM 根据用户问题决定。

#### 问题 4：数据结构兼容硬编码

**位置**: `chat_v5.py:147-160`, `unified_profile_repo.py:135-138`

```python
if not identity.get("birth_info") and profile.get("birth_info"):
    identity["birth_info"] = profile.get("birth_info")
```

**问题**: 多处重复兼容逻辑，违反 Single Source of Truth。

---

## 2. 目标架构

### 2.1 架构图

```
Claude SDK Pattern (标准 Agentic Loop)
         ↓
    LLMClient (兼容层 - 支持 DeepSeek/GLM/Claude)
         ↓
    多模型后端
```

### 2.2 数据流对比

**v9 现状（硬编码驱动）**:
```
用户: "我的生日是哪天"
         ↓
Python: 检测 Phase 1 → 预加载 profile
         ↓
Python: profile 中有 birth_info → 注入到 prompt
         ↓
LLM: (被动接收) 直接回答
```

**v9.1 目标（LLM 驱动）**:
```
用户: "我的生日是哪天"
         ↓
LLM: (主动思考) "用户问生日，我需要查数据"
         ↓
LLM: → get_user_profile(fields=["identity.birth_info"])
         ↓
Tool: → {"identity": {"birth_info": {"birth_date": "1990-05-15"}}}
         ↓
LLM: "您的生日是 1990 年 5 月 15 日"
```

---

## 3. 核心改动

### 3.1 新增 `get_user_profile` 工具

**文件**: `skills/core/tools/tools.yaml`

```yaml
- name: get_user_profile
  description: |
    获取用户画像数据。当需要了解用户信息时调用。

    ## 何时调用
    - 用户询问自己的生日、星座、八字等个人信息
    - 需要检查用户是否已提供出生信息
    - 需要加载特定 Skill 的已计算数据（命盘、塔罗牌等）

    ## 不要调用
    - 简单打招呼或闲聊
    - 用户在当前消息中已明确提供信息
    - 刚刚调用过，数据未变化

  tool_type: query
  parameters:
    - name: fields
      type: array
      items:
        type: string
      required: true
      description: |
        要获取的字段路径列表，支持：
        - identity.birth_info - 出生信息（日期、时间、地点）
        - identity.display_name - 用户昵称
        - skills.bazi - 八字命盘数据
        - skills.bazi.chart - 八字命盘详情
        - skills.zodiac - 星座星盘数据
        - skills.zodiac.chart - 星盘详情
        - skills.tarot - 塔罗数据
        - vibe.insight - 用户洞察（原型、特质）
        - vibe.target - 用户目标（北极星、愿景）
```

**文件**: `skills/core/tools/handlers.py`

```python
from typing import Dict, Any, List
from stores.unified_profile_repo import UnifiedProfileRepository
from services.agent.tool_registry import tool_handler, ToolContext


@tool_handler("get_user_profile")
async def execute_get_user_profile(args: Dict, context: ToolContext) -> Dict:
    """
    LLM 驱动的 Profile 获取工具

    v9.1 设计原则：
    - LLM 决定何时获取数据（不预加载）
    - LLM 指定需要哪些字段（按需查询）
    - 返回结构化数据供 LLM 分析
    """
    fields = args.get("fields", [])

    if not context.user_id:
        return {
            "error": "未登录，无法获取用户数据",
            "profile": {},
            "hint": "请先引导用户登录"
        }

    # 获取完整 profile（已在 get_profile 中统一规范化数据结构）
    profile = await UnifiedProfileRepository.get_profile(context.user_id)
    if not profile:
        return {
            "profile": {},
            "fields_found": [],
            "fields_missing": fields,
            "hint": "用户尚未创建档案"
        }

    # 按需提取字段
    result = {}
    fields_found = []
    fields_missing = []

    for field in fields:
        value = _get_nested_value(profile, field)
        if value is not None:
            _set_nested_value(result, field, value)
            fields_found.append(field)
        else:
            fields_missing.append(field)

    return {
        "profile": result,
        "fields_found": fields_found,
        "fields_missing": fields_missing
    }


def _get_nested_value(obj: Dict, path: str) -> Any:
    """
    获取嵌套字段值

    示例：
    - _get_nested_value(profile, "identity.birth_info") → {...}
    - _get_nested_value(profile, "skills.bazi.chart") → {...}
    """
    keys = path.split(".")
    current = obj
    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None
    return current


def _set_nested_value(obj: Dict, path: str, value: Any) -> None:
    """设置嵌套字段值"""
    keys = path.split(".")
    current = obj
    for key in keys[:-1]:
        current = current.setdefault(key, {})
    current[keys[-1]] = value
```

### 3.2 移除数据预加载

**文件**: `routes/chat_v5.py`

```python
# ═══════════════════════════════════════════════════════════════
# v9.1 改动：移除数据预加载
# ═══════════════════════════════════════════════════════════════

# 改前：
async def chat_v5_handler(body: ChatRequest):
    profile, skill_data = await get_user_context(user_id, body.skill)
    context = AgentContext(
        user_id=user_id,
        skill=body.skill,
        profile=profile,      # 预加载
        skill_data=skill_data  # 预加载
    )

# 改后：
async def chat_v5_handler(body: ChatRequest):
    # 不预加载 profile，让 LLM 通过 get_user_profile 工具按需获取
    context = AgentContext(
        user_id=user_id,
        skill=body.skill,
        # profile 和 skill_data 由 LLM 通过工具获取
    )
```

### 3.3 移除硬编码集合

**文件**: `services/agent/prompt_builder.py`

```python
# ═══════════════════════════════════════════════════════════════
# v9.1 改动：删除硬编码集合
# ═══════════════════════════════════════════════════════════════

# 删除这些行：
BIRTH_INFO_SKILLS = {"bazi", "zodiac", "jungastro"}  # 删除
PORTRAIT_FULL_SKILLS = {"lifecoach", "career"}       # 删除

# 不再需要，因为：
# 1. LLM 通过 get_user_profile 按需获取数据
# 2. Skill 的数据需求在 routing.yaml 中配置
# 3. LLM 根据工具描述自行判断何时获取
```

### 3.4 移除 SOP 状态计算

**文件**: `services/agent/prompt_builder.py`

```python
# ═══════════════════════════════════════════════════════════════
# v9.1 改动：删除 Python 状态计算
# ═══════════════════════════════════════════════════════════════

# 删除 _compute_status() 方法
# 删除 _build_sop_rules() 中的状态注入逻辑

# 改为：在 System Prompt 中告诉 LLM 可用的工具
# LLM 自己决定是否需要获取数据、是否需要计算
```

### 3.5 简化 Agentic Loop

**文件**: `services/agent/core.py`

```python
class CoreAgent:
    """
    v9.1 简化版 CoreAgent

    符合 Claude SDK 标准 Agentic Loop：
    while has_tool_use:
        response = llm.create(messages, tools)
        results = execute_tools(response.tool_use)
        messages.append(results)
    """

    async def run(self, context: AgentContext) -> AsyncGenerator[AgentEvent, None]:
        messages = self._build_initial_messages(context)
        tools = self._get_all_tools()  # 统一工具集，不再区分 Phase 1/2

        while True:
            # 流式调用 LLM
            response_content = ""
            tool_calls = []

            async for chunk in self.llm.stream(messages, tools):
                if chunk["type"] == "content":
                    response_content += chunk["content"]
                    yield AgentEvent(type="content", data=chunk)
                elif chunk["type"] == "tool_call":
                    tool_calls.append(chunk)

            # 没有工具调用则结束
            if not tool_calls:
                break

            # 执行工具
            messages.append({
                "role": "assistant",
                "content": response_content,
                "tool_calls": tool_calls
            })

            tool_results = []
            for call in tool_calls:
                result = await self.executor.execute(
                    call["tool_name"],
                    call["tool_args"],
                    context
                )
                tool_results.append({
                    "tool_call_id": call["id"],
                    "content": json.dumps(result, ensure_ascii=False)
                })
                yield AgentEvent(type="tool_result", data=result)

            messages.append({"role": "user", "content": tool_results})

    def _get_all_tools(self) -> List[Dict]:
        """
        v9.1：统一工具集

        不再区分 Phase 1/2，所有工具对 LLM 可见：
        - get_user_profile: LLM 按需获取用户数据
        - activate_skills: LLM 路由到专业 Skill
        - Skill 专属工具: calculate_xxx, show_xxx 等
        """
        return ToolRegistry.get_all_tools()
```

---

## 4. 文件改动清单

| 文件 | 改动内容 | 预估行数 |
|------|---------|---------|
| `skills/core/tools/tools.yaml` | 新增 `get_user_profile` 定义 | +30 |
| `skills/core/tools/handlers.py` | 新增 handler 实现 | +60 |
| `services/agent/core.py` | 简化 Agentic Loop，移除 Phase 逻辑 | -150 |
| `services/agent/prompt_builder.py` | 移除硬编码集合和状态计算 | -100 |
| `routes/chat_v5.py` | 移除数据预加载逻辑 | -30 |
| `skills/core/config/routing.yaml` | 更新 prompt，添加工具指引 | +20 |

**净效果**: 减少约 170 行硬编码逻辑

---

## 5. System Prompt 更新

**文件**: `skills/core/config/routing.yaml`

```yaml
phase1_prompt: |
  # Vibe

  你是 Vibe，生命对话者。

  ## 可用工具

  ### get_user_profile
  当需要了解用户信息时调用（生日、命盘、目标等）。
  - 用户问"我的生日" → get_user_profile(fields=["identity.birth_info"])
  - 用户问"我的八字" → get_user_profile(fields=["identity.birth_info", "skills.bazi"])

  ### activate_skills
  当用户意图明确时，激活专业技能。

  ### recommend_skills
  当用户意图模糊时，推荐相关服务。

  ## 处理流程

  1. 理解用户意图
  2. 如需用户数据 → 调用 get_user_profile
  3. 如需专业分析 → 调用 activate_skills
  4. 如用户迷茫 → 调用 recommend_skills

  {user_portrait}
  {subscribed_skills}
  {boundary_rules_shared}
```

---

## 6. 实施计划

### Step 1: 新增工具（不破坏现有逻辑）

```bash
# 1. 添加工具定义
# skills/core/tools/tools.yaml

# 2. 添加 handler
# skills/core/tools/handlers.py

# 3. 测试
curl -X POST http://localhost:8100/api/v1/tools/execute \
  -d '{"tool": "get_user_profile", "args": {"fields": ["identity.birth_info"]}}'
```

### Step 2: 更新 System Prompt

```bash
# 更新 routing.yaml
# 添加 get_user_profile 使用指引
```

### Step 3: 移除硬编码（逐步）

```bash
# 1. 删除 BIRTH_INFO_SKILLS
# 2. 删除 _compute_status()
# 3. 简化数据预加载
```

### Step 4: 测试验证

```bash
# 测试 1：用户问生日
curl -X POST http://localhost:8100/api/v1/chat/v5 \
  -d '{"message": "我的生日是哪天"}'
# 预期：LLM 调用 get_user_profile

# 测试 2：用户要看八字
curl -X POST http://localhost:8100/api/v1/chat/v5 \
  -d '{"message": "帮我看看八字"}'
# 预期：activate_skills → get_user_profile → calculate_bazi → show_bazi_chart
```

---

## 7. 风险与回滚

### 7.1 风险评估

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| 延迟增加 500ms | 用户体验 | 高 | 工具结果缓存 |
| LLM 忘记调用工具 | 功能缺失 | 中 | Prompt 强化 |
| Token 成本增加 | 费用 | 高 | 监控 + 预算 |

### 7.2 回滚方案

```bash
# 保留分支
git checkout -b v9-before-profile-tool

# 如有问题
git checkout v9-before-profile-tool
```

### 7.3 监控指标

```yaml
metrics:
  - avg_tool_calls_per_session  # 平均工具调用次数
  - response_latency_p95        # 响应延迟 P95
  - token_usage_per_session     # 每会话 Token 用量
  - get_user_profile_hit_rate   # 工具调用命中率
```

---

## 8. 总结

### 8.1 v9.1 核心价值

1. **完全 LLM 驱动** - 数据获取由 LLM 决定，不再硬编码
2. **符合 Claude SDK** - 标准 Agentic Loop 模式
3. **代码简化** - 减少 170 行硬编码逻辑
4. **灵活性提升** - LLM 可根据上下文智能决策

### 8.2 与 v9 的关系

```
v9（LLM 驱动架构）
  ├─ Protocol 系统（Rule 文件 + LLM 记忆）
  ├─ VibeProfile 提取（配置驱动 + LLM 执行）
  └─ v9.1 新增：Profile 工具化（get_user_profile）
```

### 8.3 下一步

1. 实施 Step 1（新增工具）
2. 观察 LLM 使用模式
3. 逐步移除硬编码
4. 监控性能影响
