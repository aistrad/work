# CoreAgent 完全 LLM 驱动架构改造计划

## 输出文档

创建新文件: `/home/aiscend/work/vibelife/docs/archive/v9/LLM_DRIVEN_V9.1_PROFILE_TOOLS.md`

## 目标

采用 **Claude SDK 标准模式**（Agentic Loop + Tool Calling），**底层通过 LLMClient 兼容层**调用多模型。

```
Claude SDK Pattern (标准 Agentic Loop)
         ↓
    LLMClient (兼容层)
         ↓
DeepSeek / GLM / Claude
```

---

## 核心改动

### 1. 新增 `get_user_profile` 工具

**文件**: `skills/core/tools/tools.yaml`

```yaml
- name: get_user_profile
  description: |
    获取用户画像数据。当需要了解用户信息时调用。

    ## 何时调用
    - 用户询问自己的生日/星座/八字
    - 需要检查用户是否有出生信息
    - 需要加载特定 Skill 的数据（命盘、塔罗等）

    ## 不要调用
    - 简单打招呼
    - 用户在消息中已提供信息

  tool_type: query
  parameters:
    - name: fields
      type: array
      items:
        type: string
      description: 要获取的字段路径，如 ["identity.birth_info", "skills.bazi.chart"]
```

**Handler**: `skills/core/tools/handlers.py`

```python
@tool_handler("get_user_profile")
async def execute_get_user_profile(args: Dict, context: ToolContext) -> Dict:
    fields = args.get("fields", [])
    profile = await UnifiedProfileRepository.get_profile(context.user_id)

    result = {}
    for field in fields:
        value = get_nested_value(profile, field)
        if value:
            set_nested_value(result, field, value)

    return {"profile": result, "fields_found": list(result.keys())}
```

### 2. 移除数据预加载

**文件**: `routes/chat_v5.py`

```python
# 改前：Phase 1/2 自动加载
profile, skill_data = await get_user_context(user_id, body.skill)

# 改后：只传 user_id，让 LLM 决定何时获取
context = AgentContext(
    user_id=user_id,
    skill=body.skill,
    # profile 和 skill_data 由 LLM 通过工具获取
)
```

### 3. 移除硬编码集合

**文件**: `services/agent/prompt_builder.py`

```python
# 删除这些硬编码
BIRTH_INFO_SKILLS = {"bazi", "zodiac", "jungastro"}  # 删除

# 改为：LLM 自己判断，或从 routing.yaml 动态读取
```

### 4. 移除 SOP 状态计算

**文件**: `services/agent/prompt_builder.py`

```python
# 删除 _compute_status() 方法
# 删除 _build_sop_rules() 中的状态注入

# 改为：直接告诉 LLM 可用的工具，让它自己判断
```

### 5. 简化 Agentic Loop

**文件**: `services/agent/core.py`

```python
# 目标：符合 Claude SDK 标准模式
async def run(self, context: AgentContext) -> AsyncGenerator:
    messages = self._build_initial_messages(context)
    tools = self._get_all_tools()  # 不再区分 Phase 1/2

    while True:
        # 流式调用 LLM（通过 LLMClient 兼容层）
        response_content = ""
        tool_calls = []

        async for chunk in self.llm.stream(messages, tools):
            if chunk["type"] == "content":
                response_content += chunk["content"]
                yield AgentEvent(type="content", data=chunk)
            elif chunk["type"] == "tool_call":
                tool_calls.append(chunk)

        if not tool_calls:
            break  # 没有工具调用，结束

        # 执行工具
        messages.append({"role": "assistant", "content": response_content, "tool_calls": tool_calls})

        tool_results = []
        for call in tool_calls:
            result = await self.executor.execute(call["tool_name"], call["tool_args"], context)
            tool_results.append({"tool_call_id": call["id"], "content": result})
            yield AgentEvent(type="tool_result", data=result)

        messages.append({"role": "user", "content": tool_results})
```

---

## 文件改动清单

| 文件 | 改动 | 行数 |
|------|------|------|
| `skills/core/tools/tools.yaml` | 新增 `get_user_profile` 工具定义 | +20 |
| `skills/core/tools/handlers.py` | 新增 handler | +25 |
| `services/agent/core.py` | 简化 Agentic Loop，移除 Phase 逻辑 | -150 |
| `services/agent/prompt_builder.py` | 移除硬编码集合和 SOP 状态计算 | -100 |
| `routes/chat_v5.py` | 移除数据预加载 | -30 |
| `stores/unified_profile_repo.py` | 统一数据规范化（已完成） | 0 |

---

## 实施步骤

### Step 1: 新增工具（不破坏现有逻辑）
1. 添加 `get_user_profile` 工具定义
2. 添加 handler
3. 测试工具可用

### Step 2: 更新 System Prompt
1. 在 `routing.yaml` 的 `phase1_prompt` 中添加工具使用指引
2. 告诉 LLM：当需要用户数据时，调用 `get_user_profile`

### Step 3: 移除硬编码
1. 删除 `BIRTH_INFO_SKILLS` 集合
2. 删除 `_compute_status()` 方法
3. 删除 SOP 状态注入逻辑

### Step 4: 移除数据预加载
1. 修改 `chat_v5.py`，不再预加载 profile
2. 修改 `core.py`，移除 Phase 1/2 区分

### Step 5: 测试验证
1. 测试"我的生日是哪天" → LLM 应调用 `get_user_profile`
2. 测试"帮我算命" → LLM 应调用 `activate_skill` + `get_user_profile` + `calculate_bazi`
3. 测试性能影响

---

## 验证方法

```bash
# 1. 启动测试环境
cd apps/api && python main.py

# 2. 测试 get_user_profile 工具
curl -X POST http://localhost:8000/api/v1/chat/v5 \
  -H "Content-Type: application/json" \
  -d '{"message": "我的生日是哪天", "user_id": "test-user"}'

# 预期：LLM 调用 get_user_profile(fields=["identity.birth_info"])

# 3. 测试完整流程
curl -X POST http://localhost:8000/api/v1/chat/v5 \
  -H "Content-Type: application/json" \
  -d '{"message": "帮我看看八字", "user_id": "test-user"}'

# 预期：
# 1. LLM 调用 activate_skill(skill="bazi")
# 2. LLM 调用 get_user_profile(fields=["identity.birth_info", "skills.bazi"])
# 3. LLM 判断是否需要 calculate_bazi
# 4. LLM 调用 show_bazi_chart
```

---

## 风险与回滚

**风险**: 增加 1-2 次工具调用，延迟约 500ms

**回滚方案**: 保留旧代码在 `_legacy` 分支，如有问题可快速切换

**监控指标**:
- 平均工具调用次数
- 响应延迟 P95
- Token 使用量
