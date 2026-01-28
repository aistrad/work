# Plan: 更新 LLM-First 方法论到 CLAUDE.md 和 vibe-agent

## 目标

将 **Claude Agent SDK 核心方法论** 更新到：
1. `/home/aiscend/work/vibelife/CLAUDE.md` - 项目级架构约束
2. `/home/aiscend/work/vibelife/.claude/skills/vibe-agent/SKILL.md` - Agent 设计方法论

## 核心方法论（从根本上避免硬编码）

### Agentic Loop 本质
```
用户消息 → LLM 思考 → 工具调用 → 环境反馈 → LLM 继续思考
```
**关键**：不要用代码硬编码决策逻辑，让 LLM 自己判断

### LLM 驱动三层次

| Level | 名称 | 实践 |
|-------|------|------|
| 🟢 L1 | Prompt 工程 | System Prompt 指导工具调用 |
| 🟡 L2 | 声明式配置 | YAML/Markdown 配置，代码只加载执行 |
| 🔴 L3 | LLM 自主编排 | 从历史推断状态，无步骤计数器 |

### 从根本上避免硬编码的 5 大技巧

1. **配置文件驱动**：YAML/Markdown 配置 + 动态加载
2. **渐进式加载**：Phase 1 轻量 → Phase 2 完整
3. **LLM 决策**：Prompt 引导，LLM 自判
4. **通用工具 + 注入**：context 自动传递参数
5. **Rule 文件 + 历史推断**：LLM 读取历史自动推断状态

---

## 修改内容

### 1. CLAUDE.md（重写 Agent SDK 章节）

```markdown
## Agent SDK Best Practices

### LLM-First 架构（强制）

**核心原则**：让 LLM 做决策，系统提供工具和数据，通过配置和 Prompt 引导而非代码硬编码。

#### Agentic Loop 本质
```
用户消息 → LLM 思考 → 工具调用 → 环境反馈 → LLM 继续
```
不要用代码硬编码决策逻辑，让 LLM 自己判断。

#### 三层架构

| 维度 | 硬编码（禁止） | LLM 驱动（正确） |
|------|--------------|----------------|
| 路由 | `if "关键词" in msg:` | LLM 读 SKILL.md triggers |
| 状态 | `_compute_status()` | LLM 从历史推断 |
| 流程 | `step = 1, 2, 3` | Rule 文件 + LLM 自推进 |
| 配置 | Python 常量 | YAML/Markdown 文件 |

#### 渐进式加载

- **Phase 1**：Core + Skill 列表（轻量）
- **Phase 2**：已选 Skill 全文 + tools + rules（完整）

#### 配置位置

| 规则类型 | 位置 | 示例 |
|---------|------|------|
| Skill 触发词 | SKILL.md frontmatter | `triggers: [八字, 命理]` |
| SOP 流程 | rules/*.md | 步骤定义 |
| 工具属性 | tools.yaml | `_should_checkpoint: true` |
| 案例 | cases/ 或 DB | Prompt 注入 |
```

### 2. vibe-agent/SKILL.md（新增方法论章节）

在核心原则后插入：

```markdown
---

## LLM-First 方法论

### 从根本上避免硬编码

**问题**：为什么会写出 `if "关键词" in message:` 这样的代码？
**根因**：没有理解 Agentic Loop——LLM 本身就是最好的状态机。

### 5 大技巧

| # | 技巧 | 实施 | 效果 |
|---|------|------|------|
| 1 | 配置文件驱动 | YAML/Markdown + 动态加载 | 避免常量硬编码 |
| 2 | 渐进式加载 | Phase 1 轻量 → Phase 2 完整 | 避免初始化爆炸 |
| 3 | LLM 决策 | Prompt 引导，LLM 自判 | 避免条件判断 |
| 4 | 通用工具 + 注入 | context 自动传参 | 避免重复工具 |
| 5 | Rule + 历史推断 | LLM 读历史自动推断状态 | 避免状态机 |

### 反模式 vs 正确模式

#### 路由
```python
# ❌ 硬编码
if "算命" in message:
    skill = "bazi"

# ✅ LLM 驱动
# LLM 读 SKILL.md triggers，调用 activate_skills(["bazi"])
```

#### 状态
```python
# ❌ 硬编码
def _compute_status(profile, skill_data):
    if skill_data.get("chart"):
        return "ready"

# ✅ LLM 驱动
# SKILL.md: "如果 profile 已有出生信息，可直接分析"
# LLM 从历史判断，无需 _compute_status()
```

#### 流程
```python
# ❌ 硬编码
class Protocol:
    def __init__(self):
        self.step = 0  # 硬编码状态

# ✅ LLM 驱动
# rules/dankoe.md 定义流程
# LLM 读历史："已完成问题 1-3，继续问题 4"
```

### 架构审查清单

- [ ] 是否让 LLM 自己决策，而非硬编码逻辑？
- [ ] 配置是否全部在 YAML/Markdown 中？
- [ ] 是否使用 Phase 1 + Phase 2 渐进式加载？
- [ ] 是否让 LLM 从历史推断进度，而非维护 step？
- [ ] SKILL.md 是否包含明确的工具调用规则表？
```

---

## 验证

1. 检查 CLAUDE.md 新章节与项目架构一致
2. 检查 vibe-agent 方法论章节逻辑完整
3. 测试：新开发者能否根据文档避免硬编码

## 关键文件

- `/home/aiscend/work/vibelife/CLAUDE.md`
- `/home/aiscend/work/vibelife/.claude/skills/vibe-agent/SKILL.md`
