# 跨技能调用规范设计（LLM-First v1）

## 一、问题回顾

### 1.1 jungastro 不调用工具的根因

`jungastro/SKILL.md` 缺少跨技能工具声明，导致 `calculate_zodiac` 工具不在可用列表中。

### 1.2 当前架构的问题

| 问题 | 影响 |
|------|------|
| 调用方自行声明 `external_tools` | Provider 无法控制谁能访问、如何计费 |
| 直接 `from skills.xxx.services import` | 紧耦合，绕过框架 |
| `requires_skill_data` 直读数据路径 | Consumer 与 Provider 内部结构强耦合 |
| 无版本协商 | Provider 演进时 Consumer 无感知 |
| 无循环依赖检测 | 可能产生死锁或无限递归 |

---

## 二、新模型：Provider/Consumer 双向契约

### 2.1 核心理念

```
┌─────────────────────────────────────────────────────────────────┐
│  Provider (被调用方)                                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ exports:                                                     ││
│  │   tools: [calculate_zodiac, get_chart_snapshot]             ││
│  │   contracts: { calculate_zodiac: {input_schema, output_schema} }│
│  │   access: { requires_subscription: true, rate_limit: 100/day }│
│  │   api_version: "1.0"                                         ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    框架验证: imports ⊆ exports
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Consumer (调用方)                                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ imports:                                                     ││
│  │   - from: zodiac                                            ││
│  │     tools: [calculate_zodiac]                               ││
│  │     min_version: "1.0"                                       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 设计原则

1. **Provider 控制权**：被调用方决定"开放什么、谁能访问、如何计费"
2. **显式契约**：所有跨技能交互都有 Schema 定义，可静态校验
3. **解耦演进**：通过 accessor 工具隔离内部数据结构
4. **运行时治理**：订阅/配额/审计在网关层统一处理

---

## 三、Provider（被调用方）规范

### 3.1 SKILL.md frontmatter

```yaml
# zodiac/SKILL.md
---
id: zodiac
name: 西方占星
version: 3.0.0

# ══════════════════════════════════════════════════════════════
# 对外导出能力
# ══════════════════════════════════════════════════════════════
exports:
  # API 版本（语义化，major.minor）
  api_version: "1.0"

  # 导出的工具（其他 Skill 可调用）
  tools:
    - name: calculate_zodiac
      description: 计算星盘
      # 入参/出参 Schema（用于 CI 校验和类型生成）
      input_schema:
        type: object
        required: [birth_date]
        properties:
          birth_date: { type: string, format: date }
          birth_time: { type: string, pattern: "^\\d{2}:\\d{2}$" }
          birth_place: { type: string }
      output_schema:
        type: object
        properties:
          chart: { type: object }
          sun_sign: { type: string }
          moon_sign: { type: string }

    - name: get_chart_snapshot
      description: 获取星盘快照（只读，用于跨技能数据共享）
      input_schema:
        type: object
        properties:
          include_aspects: { type: boolean, default: false }
      output_schema:
        type: object
        properties:
          sun_sign: { type: string }
          moon_sign: { type: string }
          rising_sign: { type: string }
          planets: { type: array }

  # 访问控制
  access:
    requires_subscription: true
    free_tools:
      - get_chart_snapshot  # 免费开放的只读工具
    rate_limit:
      calculate_zodiac: 50/day
      get_chart_snapshot: unlimited

  # 弃用声明（可选）
  deprecated:
    - tool: old_calculate_chart
      removal_date: "2026-06-01"
      replacement: calculate_zodiac
---
```

### 3.2 关键约束

| 约束 | 说明 |
|------|------|
| 工具名全局唯一 | 建议命名空间化：`zodiac_calculate_zodiac` 或注册时自动加前缀 |
| Schema 必填 | 每个导出工具必须有 `input_schema` 和 `output_schema` |
| 版本语义化 | `api_version` 变更规则：breaking change = major+1 |
| 弃用窗口 | 删除/改名工具前必须声明弃用期（≥30 天） |

---

## 四、Consumer（调用方）规范

### 4.1 SKILL.md frontmatter

```yaml
# jungastro/SKILL.md
---
id: jungastro
name: 荣格心理占星
version: 3.0.0

# ══════════════════════════════════════════════════════════════
# 从其他 Skill 引用的能力
# ══════════════════════════════════════════════════════════════
imports:
  - from: zodiac
    tools:
      - calculate_zodiac
      - get_chart_snapshot
    min_version: "1.0"  # 要求 zodiac.exports.api_version >= 1.0
---
```

### 4.2 关键约束

| 约束 | 说明 |
|------|------|
| 禁止直接 import 服务 | 禁止 `from skills.zodiac.services import xxx` |
| 禁止跨写 | 只能写入 `skills.<self>.*`，不能写入 `skills.<other>.*` |
| 只读数据通过 accessor | 需要读取其他 Skill 数据时，调用对方的 accessor 工具 |
| 持久化自负责 | 计算结果保存到自己的命名空间 |

### 4.3 调用方式

```python
# ❌ 禁止：直接导入
from skills.zodiac.services import calculate_zodiac

# ✅ 正确：通过 ToolRegistry 调用（异步）
from services.agent.tool_registry import ToolRegistry

async def get_zodiac_chart(context: ToolContext):
    # 输入自给（从 context.profile.identity 获取，不依赖 skills.zodiac.*）
    birth_info = context.profile.get("identity", {}).get("birth_info", {})

    result = await ToolRegistry.execute(
        "calculate_zodiac",
        {
            "birth_date": birth_info.get("date"),
            "birth_time": birth_info.get("time"),
            "birth_place": birth_info.get("place"),
        },
        context
    )

    if result.get("error") == "subscription_required":
        # 引导订阅
        return await ToolRegistry.execute("show", {
            "type": "card",
            "card_type": "subscribe",
            "data": {"skill_id": "zodiac"}
        }, context)

    # 结果保存到自己的命名空间
    await ToolRegistry.execute("save", {
        "path": "skills.jungastro.zodiac_chart",  # 自己的空间
        "data": result.get("chart")
    }, context)

    return result
```

---

## 五、框架职责

### 5.1 启动时/CI 校验

```python
def validate_skill_imports():
    """校验所有 Skill 的 imports 是否合法"""
    errors = []

    for consumer in all_skills:
        for imp in consumer.imports:
            provider = load_skill(imp.from_skill)

            # 1. Provider 是否存在
            if not provider:
                errors.append(f"{consumer.id}: 引用的 {imp.from_skill} 不存在")
                continue

            # 2. 工具是否在 exports 中
            for tool in imp.tools:
                if tool not in [t.name for t in provider.exports.tools]:
                    errors.append(f"{consumer.id}: {tool} 未在 {provider.id}.exports.tools 中")

            # 3. 版本兼容性
            if imp.min_version and provider.exports.api_version < imp.min_version:
                errors.append(f"{consumer.id}: 要求 {provider.id} >= {imp.min_version}，实际 {provider.exports.api_version}")

            # 4. Schema 校验（可选，详细模式）
            # validate_schemas(consumer, provider, imp.tools)

    # 5. 循环依赖检测
    if has_cycle(build_dependency_graph(all_skills)):
        errors.append("检测到循环依赖")

    return errors
```

### 5.2 运行时访问控制

```python
async def execute_imported_tool(tool_name, args, context):
    """执行跨技能工具调用"""
    provider_skill = get_tool_provider(tool_name)
    consumer_skill = context.skill_id

    # 1. 验证 import 声明
    if not is_tool_imported(consumer_skill, provider_skill, tool_name):
        return {"error": "tool_not_imported", "message": f"{tool_name} 未在 {consumer_skill} 的 imports 中"}

    # 2. 订阅检查
    access = provider_skill.exports.access
    if access.requires_subscription and tool_name not in access.free_tools:
        if not user_has_subscription(context.user_id, provider_skill.id):
            return {
                "error": "subscription_required",
                "skill_id": provider_skill.id,
                "action": "show_subscribe_card"
            }

    # 3. 配额检查
    rate_limit = access.rate_limit.get(tool_name)
    if rate_limit and is_rate_limited(context.user_id, tool_name, rate_limit):
        return {"error": "rate_limited", "retry_after": get_retry_after(...)}

    # 4. 执行工具
    result = await ToolRegistry._execute_internal(tool_name, args, context)

    # 5. 审计日志
    log_cross_skill_call(consumer_skill, provider_skill, tool_name, result)

    return result
```

### 5.3 LLM 工具集构建

```python
def get_tools_for_skill(skill_id: str) -> List[Dict]:
    """获取 Skill 可用的工具列表"""
    skill = load_skill(skill_id)
    tools = []

    # 1. Core 工具（始终可用）
    tools.extend(get_core_tools())

    # 2. 自身工具
    tools.extend(get_skill_own_tools(skill_id))

    # 3. 已授权的 imported 工具
    for imp in skill.imports:
        provider = load_skill(imp.from_skill)
        for tool_name in imp.tools:
            # 只添加 Provider exports 中存在的工具
            tool_def = get_tool_from_exports(provider, tool_name)
            if tool_def:
                tools.append(tool_def.to_openai_format())

    return tools
```

---

## 六、迁移路径

### Phase 0：规范发布（当前）

- [ ] 完成本规范文档
- [ ] 定义 SKILL.md frontmatter JSON Schema
- [ ] 发布开发指引

### Phase 1：兼容期

- [ ] `external_tools` 作为 `imports.tools` 的别名（CI 警告，不报错）
- [ ] jungastro 添加 `imports: [{from: zodiac, tools: [calculate_zodiac]}]`
- [ ] zodiac 添加 `exports: {tools: [calculate_zodiac], ...}`
- [ ] 标注现有直接 import 为"待整改"

### Phase 2：强制期

- [ ] CI 强制校验 imports ⊆ exports
- [ ] 运行时拦截未授权的跨技能调用
- [ ] 直接 import 产生 lint 错误

### Phase 3：收口

- [ ] 移除所有直接 import
- [ ] 统一使用 accessor 工具替代 data_paths
- [ ] 废弃 `requires_skill_data` 和旧版 `external_tools`

---

## 七、jungastro/zodiac 落地示例

### 7.1 zodiac/SKILL.md 变更

```yaml
# 新增 exports 部分
exports:
  api_version: "1.0"
  tools:
    - name: calculate_zodiac
      description: 计算星盘
      input_schema: { ... }
      output_schema: { ... }
    - name: get_chart_snapshot
      description: 获取星盘快照（只读）
      input_schema: { ... }
      output_schema: { ... }
  access:
    requires_subscription: true
    free_tools: [get_chart_snapshot]
```

### 7.2 jungastro/SKILL.md 变更

```yaml
# 替换 external_tools 为 imports
imports:
  - from: zodiac
    tools:
      - calculate_zodiac
      - get_chart_snapshot
    min_version: "1.0"

# 移除 requires_skill_data（改用 accessor 工具）
# requires_skill_data:   # ← 删除
#   - zodiac
```

### 7.3 jungastro/handlers.py 变更

```python
# 移除直接 import（标注待整改）
# from skills.zodiac.services import calculate_zodiac  # TODO: 整改为工具调用

# 改为通过 ToolRegistry 调用
async def get_zodiac_chart(context: ToolContext):
    # 优先读取缓存
    cached = await ToolRegistry.execute("read", {
        "path": "skills.jungastro.zodiac_chart"
    }, context)

    if cached.get("data"):
        return cached["data"]

    # 调用 zodiac 的计算工具
    birth_info = context.profile.get("identity", {}).get("birth_info", {})
    result = await ToolRegistry.execute("calculate_zodiac", {
        "birth_date": birth_info.get("date"),
        "birth_time": birth_info.get("time", "12:00"),
        "birth_place": birth_info.get("place", "Beijing"),
    }, context)

    # 处理订阅限制
    if result.get("error") == "subscription_required":
        return result

    # 缓存到自己的命名空间
    await ToolRegistry.execute("save", {
        "path": "skills.jungastro.zodiac_chart",
        "data": result.get("chart")
    }, context)

    return result.get("chart")
```

---

## 八、风险与注意点

| 风险 | 缓解措施 |
|------|---------|
| **data_paths 耦合** | 限制为 public_state，提供 accessor 工具作为替代 |
| **工具名冲突** | 注册时自动加命名空间前缀，CI 校验唯一性 |
| **循环依赖** | CI 检测，必要时用只读快照工具打破环 |
| **版本不兼容** | 强制 api_version + min_version 校验，弃用窗口 ≥30 天 |
| **订阅绕过** | 运行时网关统一拦截，不依赖 Consumer 自觉 |
| **性能损耗** | 提供缓存机制，accessor 工具返回轻量快照 |

---

## 九、验收检查清单

- [ ] LLM 工具集 = 自身工具 ∪ 授权 imports（未授权不出现）
- [ ] 未订阅 zodiac 时，jungastro 调用 calculate_zodiac 返回 subscription_required
- [ ] zodiac 内部数据演进不破坏 jungastro（通过 accessor 工具保证）
- [ ] Provider 删除导出工具后，依赖的 Consumer 在 CI 立刻报错
- [ ] 无循环依赖
- [ ] 所有跨技能调用有审计日志
