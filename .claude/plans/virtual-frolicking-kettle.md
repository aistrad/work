# 架构彻底检查与优化方案

## 一、当前架构核心问题

### 1.1 工具爆炸问题

```
当前模式（场景驱动，不可扩展）：

场景1: 职场时机 → 新建 career_timing skill → analyze_career_timing 工具
场景2: 关系天气 → 新建 relationship skill → calculate_relationship_weather 工具
场景3: ??? → 新建 ??? skill → ??? 工具

每个新场景都需要：
1. 新建 Skill 目录
2. 编写 SKILL.md
3. 编写 tools.yaml
4. 编写 handlers.py
5. 更新 routing.yaml

这不是 LLM 驱动，这是"为场景写代码"
```

### 1.2 根本原因：Phase 2 锁定单一 Skill

```python
# core.py L651-670
def _get_current_tools(self, context: AgentContext):
    if not context.skill and not self._active_skill:
        return get_phase1_tools()  # Phase 1: 只有路由工具

    skill_id = self._active_skill or context.skill
    tools = ToolRegistry.get_tools_for_skill(skill_id)  # Phase 2: 只有这个 Skill 的工具
    return tools
```

**问题**：进入 Phase 2 后，LLM 只能看到一个 Skill 的工具，无法同时调用 zodiac.calculate_transit + synastry 数据。

### 1.3 routing.yaml 的 includes 被误用

```yaml
# 当前用法
synastry:
  includes: [bazi, zodiac]  # 包含其他 Skill 的工具
```

这看起来解决了跨 Skill 问题，但实际上：
- 是静态配置，不是 LLM 动态决定
- 导致工具集膨胀
- 每个组合场景都要配置一遍

---

## 二、理想架构（Claude SDK 标准模式）

### 2.1 核心原则

```
Skill = 原子能力单元（有自己的工具集）
LLM = 编排者（决定调用哪些 Skill 的哪些工具）
CoreAgent = 执行引擎（不做决策，只执行）
```

### 2.2 理想数据流

```
用户: "今天和老公相处怎么样"
     ↓
Phase 1: LLM 加载所有 Skills 的 meta（frontmatter 摘要）
     ↓
LLM 思考: 这是关系场景，需要：
  1. 获取用户和伴侣的 birth_info → get_user_profile
  2. 获取用户今日运势 → zodiac.calculate_transit
  3. 获取伴侣今日运势 → zodiac.calculate_transit（for partner）
  4. 获取合盘数据 → synastry 数据（已有）
  5. 综合分析 → LLM 自己做
     ↓
LLM 自主编排现有工具，不需要 relationship skill
     ↓
输出: 自然语言回答 + 可选卡片
```

### 2.3 关键差异

| 维度 | 当前模式 | 理想模式 |
|-----|---------|---------|
| 新场景 | 需要新 Skill + 新工具 | LLM 编排现有 Skill |
| 编排逻辑 | 写在 handlers.py | 在 LLM 思考链中 |
| 工具数量 | 场景越多工具越多 | 保持原子工具集 |
| 可扩展性 | 差 | 极好 |

---

## 三、优化方案：Multi-Skill Mode

### 3.1 核心改动

**引入 "Multi-Skill Mode"**：LLM 可以同时访问多个 Skill 的工具。

```python
# 新增 Phase 类型
class Phase(Enum):
    ROUTING = "routing"      # Phase 1: 只有路由工具
    SINGLE_SKILL = "single"  # Phase 2a: 单 Skill 模式（现有）
    MULTI_SKILL = "multi"    # Phase 2b: 多 Skill 模式（新增）
```

### 3.2 routing.yaml 配置扩展

```yaml
# 新增 composite_intents（组合意图）
composite_intents:
  relationship_daily:
    description: 关系每日场景
    triggers:
      - 今天和老公
      - 今天和老婆
      - 关系天气
    skills: [zodiac, synastry]  # LLM 可以同时使用这些 Skill 的工具
    prompt_hint: |
      这是关系场景。你可以：
      1. 调用 zodiac.calculate_transit 获取双方今日运势
      2. 使用 synastry 已有数据分析关系
      3. 综合生成相处建议
```

### 3.3 CoreAgent 改动

```python
def _get_current_tools(self, context: AgentContext):
    # Phase 1: 路由工具
    if not context.skill and not self._active_skill:
        return get_phase1_tools()

    # Phase 2b: Multi-Skill Mode（新增）
    if context.composite_intent:
        skills = get_composite_skills(context.composite_intent)
        tools = []
        for skill_id in skills:
            tools.extend(ToolRegistry.get_tools_for_skill(skill_id))
        return dedupe_tools(tools)

    # Phase 2a: Single-Skill Mode（现有）
    skill_id = self._active_skill or context.skill
    return ToolRegistry.get_tools_for_skill(skill_id)
```

### 3.4 Phase 1 prompt 增强

```yaml
phase1_prompt: |
  # Vibe

  ## 识别用户意图

  ### 单一意图 → 激活单个 Skill
  - "帮我看八字" → activate_skill(skill="bazi")
  - "今天运势" → activate_skill(skill="zodiac")

  ### 组合意图 → 激活 Multi-Skill Mode
  - "今天和老公相处" → activate_composite(intent="relationship_daily")
  - "跳槽时机" → activate_composite(intent="career_timing")

  {composite_intents_list}  # 动态注入可用的组合意图
```

---

## 四、极简方案（最小改动）

如果不想大改架构，可以采用更极简的方案：

### 4.1 让 Phase 1 做更多事

不进入 Phase 2，让 Phase 1 的 LLM 直接调用多个 Skill 的工具。

```yaml
# routing.yaml 修改
phase1_tools:
  - activate_skill        # 激活单 Skill（进入 Phase 2）
  - get_user_profile      # 获取用户数据
  - zodiac.calculate_transit  # 直接暴露 zodiac 的计算工具
  - zodiac.show_transit       # 直接暴露 zodiac 的展示工具
  - synastry.get_result       # 直接暴露 synastry 的查询工具
  # ... 更多原子工具
```

### 4.2 Phase 1 成为"通用 Agent"

```
Phase 1（通用模式）：
- 可以调用所有 Skill 的"查询"和"计算"工具
- 不需要激活特定 Skill
- LLM 自己编排

Phase 2（专家模式）：
- 只在需要深度分析时进入
- 加载专家身份（SKILL.md）
- 加载专业规则（rules/*.md）
```

### 4.3 工具分类

```yaml
# 工具分为三类
tool_categories:
  # 1. 通用工具（Phase 1 可用）
  universal:
    - get_user_profile
    - show_card
    - save_data

  # 2. 计算工具（Phase 1 可用）
  compute:
    - zodiac.calculate_transit
    - zodiac.calculate_chart
    - bazi.calculate_chart
    - synastry.calculate

  # 3. 专家工具（只在 Phase 2 可用）
  expert:
    - zodiac.deep_analysis
    - bazi.fortune_prediction
    - lifecoach.protocol_guide
```

---

## 五、推荐方案：渐进式演进

### Step 1: 暴露原子计算工具到 Phase 1

**改动点**：
- 修改 `get_phase1_tools()` 返回更多工具
- 在 routing.yaml 中配置哪些工具是 "universal"

**验证**：
- 用户说"今天和老公相处怎么样"
- Phase 1 LLM 直接调用 zodiac.calculate_transit × 2
- 不需要新建 relationship skill

### Step 2: 添加 composite_intents 配置

**改动点**：
- routing.yaml 添加 `composite_intents` 配置
- Phase 1 prompt 中展示可用的组合意图
- LLM 可以调用 `activate_composite(intent=xxx)`

**验证**：
- 用户说"跳槽时机分析"
- LLM 识别为 composite intent
- 同时获得 bazi + zodiac + career 的工具

### Step 3: 重构现有 Skill（可选）

**改动点**：
- 将 `analyze_career_timing` 拆分为原子工具
- 删除场景特定的工具
- 让 LLM 自己组合

---

## 六、架构对比

```
当前架构：
┌─────────────────────────────────────────┐
│ Phase 1: 路由 (4 个工具)                 │
│   → activate_skill → Phase 2            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Phase 2: 单 Skill (该 Skill 的所有工具)  │
│   → 只能用一个 Skill 的能力              │
└─────────────────────────────────────────┘

优化后架构：
┌─────────────────────────────────────────┐
│ Phase 1: 通用 Agent                      │
│   - 路由工具                             │
│   - 通用工具 (get_user_profile, ...)    │
│   - 计算工具 (zodiac.transit, ...)      │
│   → 可以直接完成大部分任务               │
│   → activate_skill → Phase 2 (可选)     │
└─────────────────────────────────────────┘
                  ↓ (可选)
┌─────────────────────────────────────────┐
│ Phase 2: 专家模式                        │
│   → 深度分析、协议引导等专业场景         │
└─────────────────────────────────────────┘
```

---

## 七、文件改动清单

| 文件 | 改动 | 优先级 |
|-----|------|--------|
| `routing.yaml` | 添加 `universal_tools` 和 `composite_intents` | P0 |
| `core.py` | 修改 `_get_current_tools` 返回更多工具 | P0 |
| `prompt_builder.py` | Phase 1 prompt 中注入 Skills meta | P1 |
| `tool_registry.py` | 添加 `get_universal_tools()` 方法 | P1 |
| 删除 | career_timing skill 等场景特定 Skill | P2 |

---

## 八、验证标准

优化后，以下场景应该不需要新建 Skill：

1. **关系天气**：LLM 调用 zodiac.transit × 2 + 已有 synastry 数据
2. **职场时机**：LLM 调用 bazi.chart + zodiac.transit + 自己分析
3. **情侣匹配**：LLM 调用 synastry.calculate + zodiac 数据
4. **每日运势**：LLM 调用 zodiac.transit + bazi.daily

**判断标准**：
- 如果需要新建 handlers.py 中的函数 → 架构问题
- 如果只需要配置 + LLM 编排 → 架构正确
