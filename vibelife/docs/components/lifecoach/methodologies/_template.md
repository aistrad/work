# 方法论协议模板

> 使用此模板创建新的教练方法论协议

---

## Frontmatter 模板

```yaml
---
id: {methodology-id}           # kebab-case，如 dankoe, covey, yangming
name: {方法论名称}              # 如 "Dan Koe 一日重置协议"
impact: HIGH                   # HIGH (完整协议)
impactDescription: {一句话说明} # 如 "完整的人生重置流程"
tags: {触发词}                  # 逗号分隔，如 "反愿景, 愿景, 游戏化"
origin: {来源}                  # 如 "Dan Koe《How to Fix Your Entire Life》"
card_types: [{卡片类型}]        # 如 [VisionMapCard, LifeGameCard]
---
```

---

## 正文结构

```markdown
# {方法论名称}

## 核心理念

> "{核心引用 - 来自原著或创始人}"

**三个核心信念**：
1. **{信念1名称}**：{一句话解释}
2. **{信念2名称}**：{一句话解释}
3. **{信念3名称}**：{一句话解释}

## 协议流程

### Stage 1: 诊断 - {阶段名称}

**目的**：{这个阶段要达成什么}

**核心问题**：
| # | 问题 | 目的 |
|---|-----|------|
| 1 | {问题1} | {目的1} |
| 2 | {问题2} | {目的2} |
| 3 | {问题3} | {目的3} |

**输出**：
- 调用 `{工具名}`
- 写入 `{数据字段}`

### Stage 2: 设计 - {阶段名称}

**目的**：{这个阶段要达成什么}

**核心问题**：
| # | 问题 |
|---|-----|
| 1 | {问题1} |
| 2 | {问题2} |

**输出**：
- 写入 `north_star.{字段}`
- 调用 `show_{卡片}`

### Stage 3: 执行 - {阶段名称}

**目的**：{这个阶段要达成什么}

**核心问题**：
| # | 问题 |
|---|-----|
| 1 | {问题1} |
| 2 | {问题2} |

**输出**：
- 写入 `roadmap`, `current`
- 调用 `show_action_plan`

### Stage 4: 复盘 - {阶段名称}

**目的**：{这个阶段要达成什么}

**核心问题**：
| # | 问题 |
|---|-----|
| 1 | {问题1} |
| 2 | {问题2} |

**输出**：
- 写入 `journal`, `progress`
- 调用 `show_progress_streak`

## 数据映射

| 本方法论概念 | 通用字段 | 说明 |
|------------|---------|------|
| {概念1} | north_star.vision | {说明} |
| {概念2} | north_star.anti_vision | {说明} |
| {概念3} | identity.target | {说明} |
| {概念4} | current.month | {说明} |
| {概念5} | current.daily | {说明} |

## 特定卡片

| 卡片类型 | 用途 | 数据来源 |
|---------|------|---------|
| {CardType1} | {用途} | {数据字段} |
| {CardType2} | {用途} | {数据字段} |

## 启动前：读取状态

**必须先调用** `read_lifecoach_state(sections=["system", "north_star"])`

检查：
- `system.active_framework` 是否已选择其他方法论
- 是否已有相关数据（询问是更新还是从头开始）

## 完成后：写入状态

**必须调用**：
1. `write_lifecoach_state(section="system", data={"active_framework": "{id}"})`
2. `write_lifecoach_state(section="north_star", data={...})`
3. `write_lifecoach_state(section="identity", data={...})`
4. `write_lifecoach_state(section="current", data={...})`

## 适用人群

- {人群1}
- {人群2}
- {人群3}

## 不适用场景

- {场景1}
- {场景2}
```

---

## 检查清单

创建新方法论协议时，确保：

- [ ] Frontmatter 完整（id, name, impact, tags, origin, card_types）
- [ ] 核心理念包含 3 个信念
- [ ] 协议流程包含 4 个阶段
- [ ] 每个阶段有核心问题和输出
- [ ] 数据映射表完整
- [ ] 特定卡片定义清晰
- [ ] 启动前/完成后的工具调用明确
- [ ] 适用人群和不适用场景清晰
