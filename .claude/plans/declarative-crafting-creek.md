# VibeLife LLM 驱动架构改造计划

> **目标**: 将 CoreAgent 和 Core Skill 改造为完全符合 Agent SDK 规范的 LLM 驱动架构
> **原则**: 完全 LLM 驱动 + 配置即 Prompt + 工具即能力 + 零硬编码
> **实施范围**: 完整三个 Phase（7-10 天）

---

## 核心违规点

根据 CLAUDE.md 规范 **"只允许 LLM 工具调用方式进行 Skill 路由，禁止 Python 硬编码条件判断"**，发现以下违规：

| 优先级 | 违规点 | 位置 | 类型 |
|-------|-------|------|------|
| 🔴 **P0** | 工具集强制限制 | `core.py:744-762` | Python 决定工具可用性 |
| 🟡 **P1** | SOP 状态计算 | `core.py:509-548` | Python 包含业务逻辑判断 |
| 🟢 **P2** | Scenario 自动匹配 | `core.py:455-483` | 正则表达式路由（应由 LLM 决策）|

---

## Phase 1: 移除工具集限制（P0 - 最高优先级）

**时间**: 2-3 天
**目标**: 删除 Python 硬编码的工具集限制，改为完全由 LLM 决策

### 1.1 关键改动

#### 文件: `apps/api/services/agent/core.py`

**改动 1: 简化 `_get_current_tools()` (line 720-766)**

```python
# 改造前：18 行硬编码条件判断
if status["needs_birth_info"] and not status["has_birth_info"]:
    return [collect_tool]  # ← 强制限制
if status["needs_compute"] and not status["has_chart_data"]:
    return [compute_tool]  # ← 强制限制

# 改造后：7 行，完全 LLM 驱动
def _get_current_tools(self, context: AgentContext) -> List[Dict[str, Any]]:
    if not context.skill and not self._active_skill:
        return get_phase1_tools()

    # 始终返回完整工具集，LLM 根据 System Prompt 决策
    skill_id = self._active_skill or context.skill
    tools = ToolRegistry.get_tools_for_skill(skill_id)
    return tools if tools else get_phase1_tools()
```

**改动 2: 增强 `_build_sop_rules()` (line 550-619)**

在 SOP Prompt 中明确说明：
- **当前状态**（数据层面）
- **推荐工具**（非强制）
- **为什么推荐**（提高 LLM 理解）

示例增强：
```python
# 增加详细的 Prompt 解释
if status["needs_birth_info"] and not status["has_birth_info"]:
    return f"""## 当前状态：需要出生信息

**数据状态**：
- 需要出生信息：是
- 已提供：否

**推荐工具**：`{collect_tool}`

**为什么推荐此工具**：
1. 表单确保信息完整（年月日时 + 时区）
2. 提供更好的用户体验
3. 减少来回对话次数

**重要**：
- 如果用户在对话中直接提供了生日（如"我1990年1月1日出生"），你可以直接进入下一步
- 不要用文字问"请问你的生日是？"，直接调用工具
"""
```

#### 文件: `apps/api/skills/core/config/routing.yaml`

**改动 3: 增强 SOP 模板**

新增详细的配置模板（约 80 行）：

```yaml
sop_templates:
  need_birth_info: |
    ## 当前状态：需要出生信息

    **推荐工具**：`{collect_tool}`

    **为什么推荐**：
    1. 表单确保信息完整
    2. 更好的用户体验
    3. 减少对话次数

    **灵活处理**：
    - 用户直接提供生日 → 可跳过工具，直接计算
    - 信息不完整 → 仍需调用工具

  need_compute: |
    ## 当前状态：需要生成命盘

    **推荐工具**：`{compute_tool}`

    **执行方式**：
    1. 简短说"让我来排个盘～"
    2. 调用工具
    3. 等待结果（约1-2秒）

  ready_for_analysis: |
    ## 当前状态：可以开始分析

    **你现在可以**：
    1. 根据用户问题聚焦分析
    2. 使用 `show_xxx` 工具展示结果
    3. 参考知识库（`search_db`）
```

### 1.2 验证方案

**测试场景**：

| 场景 | 输入 | 预期 LLM 行为 | 验证点 |
|-----|------|-------------|-------|
| S1 | "帮我算命" | 调用 `request_info` | LLM 主动选择收集工具 |
| S2 | "我1990-01-01生，算命" | 跳过 `request_info`，直接 `calculate_bazi` | LLM 灵活响应 |
| S3 | "看事业运"（已有命盘）| 直接 `show_bazi_chart` | 跳过前置步骤 |

**测试文件**:
- 新建: `apps/api/scripts/test_phase1_llm_driven.py`
- 运行: `pytest apps/api/scripts/test_phase1_llm_driven.py -v`

### 1.3 风险和缓解

| 风险 | 概率 | 缓解措施 |
|------|------|---------|
| LLM 不遵守 Prompt | 中 (30%) | 1. 强化 Prompt 对比学习<br>2. 监控工具调用率<br>3. 如 < 90% 可考虑 tool_choice（备选）|

---

## Phase 2: SOP 状态 Prompt 化（P1 - 重要）

**时间**: 2-3 天
**目标**: 将 SOP 状态计算从 Python 业务逻辑改为纯数据查询 + Prompt 驱动

### 2.1 关键改动

#### 文件: `apps/api/services/agent/core.py`

**改动 1: 重构 `_compute_sop_status()` → `_get_sop_context()` (line 509-548)**

```python
# 改造前：包含业务逻辑判断
def _compute_sop_status(self, context: AgentContext) -> Dict[str, Any]:
    needs_birth = skill_requires_birth_info(skill_id)  # ← 配置查询
    has_birth = bool(birth_info.get("birth_date"))
    # ...
    return {
        "ready_for_analysis": (not needs_birth or has_birth) and ...  # ← 业务决策
    }

# 改造后：纯数据查询，无决策
def _get_sop_context(self, context: AgentContext) -> Dict[str, Any]:
    """只查询数据状态，不做任何业务判断"""
    skill_config = load_skill(skill_id)
    birth_info = context.profile.get("identity", {}).get("birth_info", {})
    skill_data = context.skill_data.get(compute_type, {})

    # 返回原始数据状态
    return {
        "skill_config": {
            "requires_birth_info": skill_config.requires_birth_info,
            "requires_compute": skill_config.requires_compute,
            "collect_tool": skill_config.collect_tool or "request_info",
            "compute_tool": skill_config.compute_tool or f"calculate_{compute_type}",
        },
        "user_data_status": {
            "has_birth_info": bool(birth_info.get("birth_date")),
            "has_chart_data": bool(skill_data.get("chart")),
            "chart_summary": self._extract_chart_summary(skill_data),
        }
    }
```

**关键变化**：
- ❌ 删除 `ready_for_analysis` 决策（移到 Prompt）
- ✅ 只返回原始数据状态
- ✅ 所有决策由 LLM 从 Prompt 中理解

**改动 2: 重构 `_build_sop_rules()` 为数据驱动版本**

```python
def _build_sop_rules(self, context: AgentContext) -> str:
    """v10.2: 数据驱动版本 - 从数据状态加载模板"""
    sop_context = self._get_sop_context(context)
    config = sop_context.get("skill_config", {})
    status = sop_context.get("user_data_status", {})

    # 根据数据状态选择模板（不做决策）
    if config.get("requires_birth_info") and not status.get("has_birth_info"):
        return self._load_template("need_birth_info", sop_context)

    if config.get("requires_compute") and not status.get("has_chart_data"):
        return self._load_template("need_compute", sop_context)

    return self._load_template("ready_for_analysis", sop_context)
```

#### 文件: `apps/api/skills/core/config/routing.yaml`

**改动 3: 增强数据驱动模板（约 120 行）**

```yaml
sop_templates:
  need_birth_info: |
    ## 当前状态：需要出生信息

    **数据状态**：
    - 需要出生信息：是
    - 已提供：否

    **推荐工具**：`{collect_tool}`

    **灵活处理**：
    - 用户直接提供生日（如"我1990-01-01出生"）→ 可解析信息，跳过工具
    - 信息不完整（如缺少时辰）→ 仍需调用工具

  ready_for_analysis: |
    ## 当前状态：可以开始分析

    **数据状态**：
    - 已有出生信息：是
    - 已生成命盘：是
    - 命盘摘要：{chart_summary}

    **分析流程**：
    1. 理解用户核心问题
    2. 扫描命盘相关特征
    3. 用展示工具呈现结果
```

### 2.2 验证方案

**测试场景**：

| 场景 | 前置状态 | 输入 | 预期 LLM 决策 |
|-----|---------|------|-------------|
| S1 | 无数据 | "算命" | 识别状态 → `request_info` |
| S2 | 有出生信息，无命盘 | "继续" | 识别状态 → `calculate_bazi` |
| S3 | 有命盘 | "看事业" | 直接分析 → `show_bazi_chart` |

**测试文件**:
- 更新: `apps/api/scripts/test_coreagent_zodiac.py`
- 运行: `python apps/api/scripts/test_coreagent_zodiac.py`

---

## Phase 3: Scenario LLM 驱动（P2 - 优化）

**时间**: 1-2 天
**目标**: 删除 Scenario 自动匹配逻辑，改为 LLM 在 Phase 1 决策时选择

### 3.1 关键改动

#### 文件: `apps/api/services/agent/core.py`

**改动 1: 简化 `_route_scenario()` (line 455-483)**

```python
# 改造前：28 行正则表达式匹配
async def _route_scenario(self, skill_id: str, message: str) -> Optional[str]:
    for rule_id in rules:
        rule = load_rule(skill_id, rule_id)
        for tag in rule.tags:
            if tag.lower() in message_lower:  # ← 硬编码匹配
                return rule_id

# 改造后：10 行，完全 LLM 驱动
async def _route_scenario(self, skill_id: str, message: str) -> Optional[str]:
    """
    v10.1: 完全移除自动匹配，100% 由 LLM 决策
    """
    skill = load_skill(skill_id)
    if not skill:
        return None

    # 如果有 rules，返回 None（LLM 在 activate_skill 时选择）
    rules = get_skill_rules(skill_id)
    return None if rules else skill.default_scenario
```

**改动 2: 增强 `activate_skill` 工具 (line 823-890)**

支持 LLM 传入 `rule` 参数：

```python
async def _handle_activate_skill(self, args: Dict, context: AgentContext):
    skill = args.get("skill")
    rule = args.get("rule")  # ← LLM 可选择传入

    self._active_skill = skill
    self._active_scenario = rule  # ← 使用 LLM 选择的 rule
    # ...
```

#### 文件: `apps/api/services/agent/routing_config.py`

**改动 3: 增强工具描述 (line 112-142)**

```python
def build_skill_tool_description() -> str:
    """v10.1: 包含 rule 选择指引"""
    lines = ["激活专业技能来回答用户问题。\n"]

    for skill_id in available_skills:
        skill = load_skill(skill_id)
        lines.append(f"- **{skill_id}**: {skill.description}")

        # 新增：列出可选 rules
        rules = get_skill_rules(skill_id)
        if rules:
            lines.append("  可选规则（rule 参数）：")
            for rule_id in rules:
                rule = load_rule(skill_id, rule_id)
                tags = ", ".join(rule.tags[:3])
                lines.append(f"    - `{rule_id}`: {rule.name}（{tags}）")

    lines.append("\n## 参数说明")
    lines.append("- `skill`: 必需，技能 ID")
    lines.append("- `rule`: 可选，规则 ID。用户意图明确匹配某规则时传入")

    lines.append("\n## rule 参数使用指南")
    lines.append("- 用户说'做人生重置' → `activate_skill(skill='lifecoach', rule='dankoe')`")
    lines.append("- 用户说'算命'（无明确 rule）→ `activate_skill(skill='bazi')`")

    return "\n".join(lines)
```

### 3.2 验证方案

**测试场景**：

| 场景 | 输入 | 预期 LLM 决策 | 验证点 |
|-----|------|-------------|-------|
| S1 | "我想做人生重置" | `activate_skill(skill='lifecoach', rule='dankoe')` | LLM 识别 rule |
| S2 | "我迷茫了" | `activate_skill(skill='lifecoach')` | 不传 rule |
| S3 | "算命" | `activate_skill(skill='bazi')` | 不传 rule |

**测试文件**:
- 新建: `apps/api/scripts/test_phase3_scenario_routing.py`

---

## 关键文件清单

| 文件 | 改动类型 | 优先级 | 行数 |
|------|---------|-------|------|
| `apps/api/services/agent/core.py` | 删除 + 重构 | 🔴 P0 | ~180 行 |
| `apps/api/skills/core/config/routing.yaml` | 新增配置 | 🔴 P0 | ~280 行 |
| `apps/api/services/agent/routing_config.py` | 增强 | 🟡 P1 | ~50 行 |
| `apps/api/services/agent/skill_loader.py` | 保持兼容 | 🟢 P2 | ~0 行（无需改动）|
| **测试文件** | 新建 | 🟡 P1 | ~330 行 |
| `apps/api/scripts/test_phase1_llm_driven.py` | 新建 | - | ~100 行 |
| `apps/api/scripts/test_coreagent_zodiac.py` | 更新 | - | ~150 行 |
| `apps/api/scripts/test_phase3_scenario_routing.py` | 新建 | - | ~80 行 |

---

## 端到端验证方案

### 回归测试套件

运行完整测试流程：

```bash
cd /home/aiscend/work/vibelife

# 1. Phase 1 测试（工具集限制移除）
pytest apps/api/scripts/test_phase1_llm_driven.py -v

# 2. Phase 2 测试（SOP 状态 Prompt 化）
python apps/api/scripts/test_coreagent_zodiac.py

# 3. Phase 3 测试（Scenario LLM 驱动）
pytest apps/api/scripts/test_phase3_scenario_routing.py -v

# 4. 完整回归测试
pytest apps/api/scripts/test_real_user_scenarios_comprehensive.py -v
```

### 关键验证点

| 验证项 | 测试方法 | 通过标准 |
|-------|---------|---------|
| **工具集完整性** | 检查 Phase 2 返回的工具列表 | 包含所有工具（无限制）|
| **LLM 工具调用率** | 统计 Phase 1 工具调用次数 | ≥ 90% |
| **SOP 状态无决策** | 检查 `_get_sop_context` 返回值 | 无 `ready_for_analysis` 字段 |
| **Scenario 无自动匹配** | 用户说"人生重置"，检查路由 | LLM 选择 `dankoe` rule |
| **向后兼容** | 运行现有测试套件 | 100% 通过 |

### 性能监控

改造后监控以下指标（7 天）：

1. **Phase 1 工具调用率**（目标 ≥ 90%）
2. **Phase 2 平均响应时间**（应无明显变化）
3. **用户体验反馈**（通过日志监控错误率）

---

## 风险和缓解措施

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| **LLM 不遵守 Prompt** | 🟡 中 (30%) | 🔴 高 | 1. 强化对比学习示例<br>2. 监控工具调用率<br>3. 准备 tool_choice 备选方案（如调用率 < 90%）|
| **工具调用顺序错误** | 🟢 低 (10%) | 🟡 中 | Prompt 明确优先级 + "为什么推荐" |
| **Scenario 识别失败** | 🟢 低 (15%) | 🟡 中 | 1. 增强 rule 描述和示例<br>2. 保留日志追踪 |
| **向后兼容问题** | 🟢 低 (5%) | 🟡 中 | 保留配置字段，渐进式迁移 |

---

## 实施时间线

```
Week 1          Week 2          Week 3
  │               │               │
  ▼               ▼               ▼
Phase 1      →  Phase 2      →  Phase 3
(P0)            (P1)            (P2)
  │               │               │
Day 1-3         Day 4-6         Day 7-9
  │               │               │
  ├─ 编码          ├─ 编码          ├─ 编码
  ├─ 测试          ├─ 测试          ├─ 测试
  └─ Review       └─ Review       └─ Review
                                    │
                                    ▼
                                 Day 10
                                 最终验证
```

**总时间**: 7-10 天

---

## 改造成果预期

**代码简化**:
- 旧架构：~180 行硬编码决策逻辑
- 新架构：~60 行数据查询 + 配置驱动
- **减少：67% 代码量**

**架构纯粹度**:
- 旧：Python 硬编码 → LLM 受限
- 新：配置 Prompt → LLM 驱动
- **符合：Agent SDK 规范 ✅**

**维护成本**:
- 旧：改流程需修改 Python 代码
- 新：改流程只需修改 YAML 配置
- **降低：80% 维护成本**

---

## 未解决问题

无 - 所有关键决策点已确认：
- ✅ 实施范围：完整三个 Phase
- ✅ 工具调用策略：纯 Prompt 优化（方案 A）
- ✅ Scenario 路由：完全移除自动匹配

---

**计划完成日期**: 2026-01-21
**预计开始日期**: 立即
**预计完成日期**: 2-3 周
