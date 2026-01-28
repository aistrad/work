# Skill 重构指南

本指南说明如何将现有的 Scenario 驱动架构重构为 Agentic + Rule 架构。

---

## 1. 重构概述

### 1.1 架构变化

| 维度 | 重构前 | 重构后 |
|-----|-------|-------|
| 场景文件 | 50+ scenarios/*.md | 删除，改用 rules/ |
| 路由方式 | 触发词关键词匹配 | LLM 语义理解 |
| 服务流程 | 预定义 SOP 步骤 | LLM 根据规则自主规划 |
| SKILL.md | 包含场景目录表格 | 包含能力索引表格 |
| 加载方式 | SKILL.md + Scenario 一起加载 | 渐进式按需加载 |

### 1.2 重构目标

1. **精简 SKILL.md**：< 200 行
2. **删除 scenarios/**：归档到 archive/
3. **创建 rules/**：5-10 个核心规则
4. **重构 skill_loader.py**：支持渐进式加载

---

## 2. 重构步骤

### Phase 1: 目录结构调整

```bash
# 1. 创建 rules 目录
mkdir -p skills/{skill_id}/rules

# 2. 归档旧 scenarios
mkdir -p skills/{skill_id}/archive
mv skills/{skill_id}/scenarios skills/{skill_id}/archive/

# 3. 创建规则文件
touch skills/{skill_id}/rules/_index.md
touch skills/{skill_id}/rules/{capability-1}.md
touch skills/{skill_id}/rules/{capability-2}.md
# ... 创建所有规则文件
```

### Phase 2: 分析现有 Scenarios

1. **统计现有场景**：
   ```bash
   ls skills/{skill_id}/scenarios/*.md | wc -l
   ```

2. **分类场景**：将 50+ 场景归类到 5-10 个核心能力

3. **提取分析要点**：从每个场景的 SOP 中提取关键分析步骤

### Phase 3: 编写 Rule 文件

对于每个核心能力，创建对应的 rule 文件：

```markdown
---
id: {capability-id}
name: {能力名称}
impact: {CRITICAL|HIGH|MEDIUM|LOW}
impactDescription: {影响说明}
tags: {触发词列表}
---

# {能力名称}规则

## 适用场景
[合并多个相关场景的描述]

## 分析要点
[从多个场景的 SOP 中提取关键步骤]

## 输出要求
[合并多个场景的输出要求]

## 常见问题
[从多个场景中提取高频问题]
```

### Phase 4: 重写 SKILL.md

1. **删除场景目录表格**
2. **添加核心能力索引表格**
3. **精简到 < 200 行**

**从**：
```markdown
## 场景目录

### Entry（入门级）
| 场景 | 文件 | 触发词 | 计费 | 展示名称 | 图标 | 简介 |
|-----|------|-------|------|---------|------|------|
| 基础解读 | basic_reading.md | 看命盘、算命 | 免费 | ... |
| ... | ... | ... | ... | ... |

### Standard（标准级）
| 场景 | 文件 | 触发词 | 计费 | 展示名称 | 图标 | 简介 | 价值点 |
|-----|------|-------|------|---------|------|------|--------|
| ... | ... | ... | ... | ... | ... | ... | ... |
```

**改为**：
```markdown
## 核心能力索引

| 能力 | 优先级 | 规则文件 | 触发场景 |
|-----|-------|---------|---------|
| 命盘解读 | CRITICAL | `rules/basic-reading.md` | 第一次算命、了解命盘 |
| 事业分析 | HIGH | `rules/career.md` | 事业、职业、跳槽 |
| 感情婚姻 | HIGH | `rules/relationship.md` | 感情、婚姻、桃花 |
| 财运分析 | MEDIUM | `rules/wealth.md` | 财运、投资、求财 |
| 运势预测 | MEDIUM | `rules/fortune.md` | 大运、流年、运势 |
| 合婚配对 | LOW | `rules/compatibility.md` | 合婚、配对 |
```

### Phase 5: 重构 skill_loader.py

#### 5.1 删除的功能

```python
# 删除以下函数
- route_scenario()           # 触发词路由
- load_scenario()            # 场景加载
- parse_scenario_md()        # 场景解析
- get_scenario_triggers()    # 触发词获取
- parse_scenario_triggers()  # 触发词解析
```

#### 5.2 新增的功能

```python
@lru_cache(maxsize=64)
def load_rule(skill_id: str, capability_id: str) -> Optional[str]:
    """
    按需加载分析规则。

    Args:
        skill_id: Skill ID
        capability_id: 能力 ID

    Returns:
        规则文件内容，或 None
    """
    rule_path = SKILLS_DIR / skill_id / "rules" / f"{capability_id}.md"

    if not rule_path.exists():
        return None

    return rule_path.read_text(encoding='utf-8')


def get_capability_index(skill_id: str) -> List[Dict[str, str]]:
    """
    获取能力索引。

    Returns:
        [{"name": "命盘解读", "id": "basic-reading", "impact": "CRITICAL", ...}, ...]
    """
    skill = load_skill(skill_id)
    if not skill:
        return []

    # 从 SKILL.md 解析能力索引表格
    # ...
```

#### 5.3 修改的功能

```python
def build_system_prompt(
    skill_id: str,
    user_context: Optional[Dict] = None
) -> str:
    """
    构建 System Prompt。

    变更: 不再注入 Scenario SOP，只注入 SKILL.md + 用户上下文。
    Rule 由 LLM 按需加载。
    """
    parts = []

    # 1. 加载 SKILL.md (< 200 行)
    skill = load_skill(skill_id)
    if not skill:
        return ""

    # 加载 SKILL.md 全文
    skill_path = SKILLS_DIR / skill_id / "SKILL.md"
    skill_md = skill_path.read_text(encoding='utf-8')
    parts.append(skill_md)

    # 2. 注入用户上下文 (如果有)
    if user_context:
        ctx_text = format_user_context(user_context)
        parts.append(f"\n---\n\n## 用户上下文\n\n{ctx_text}")

    return "\n".join(parts)
```

#### 5.4 更新数据结构

```python
@dataclass
class SkillConfig:
    """Skill 核心配置"""
    id: str
    name: str
    description: str
    expert_persona: str
    capabilities: List[Dict[str, str]]  # 新增：能力索引
    ethics: Dict[str, Any]
    tools: List[str]
    # 删除: scenarios, default_scenario, triggers
```

### Phase 6: 测试验证

1. **加载测试**：
   ```python
   skill = load_skill("bazi")
   assert skill is not None
   assert len(skill.capabilities) >= 5
   ```

2. **规则加载测试**：
   ```python
   rule = load_rule("bazi", "career")
   assert rule is not None
   assert "分析要点" in rule
   ```

3. **System Prompt 测试**：
   ```python
   prompt = build_system_prompt("bazi", {"birth_info": {...}})
   assert len(prompt) < 10000  # 确保不会太长
   assert "核心能力索引" in prompt
   ```

4. **端到端测试**：
   - 测试各种用户问题
   - 验证 LLM 能正确匹配能力
   - 验证 LLM 能按需加载规则

---

## 3. Bazi 重构示例

### 3.1 场景归类

将 50+ scenarios 归类到 6 个核心能力：

| 核心能力 | 合并的场景 |
|---------|----------|
| **命盘解读** | basic_reading.md, personality.md, quick_query.md, wuxing_analysis.md, bindao_ten_gods.md |
| **事业分析** | career.md, shishen_career_matching.md, guanyin_xiangsheng.md, 职业相关场景 |
| **感情婚姻** | relationship.md, female_marriage_shishen.md, male_marriage_shishen.md, rizhi_spouse_analysis.md |
| **财运分析** | wealth.md, bazi_wealth_status_analysis.md, caiguan_shuangmei.md, 财运相关场景 |
| **运势预测** | dayun.md, yearly_fortune.md, bazi_fortune_cycle_analysis.md, 运势相关场景 |
| **合婚配对** | compatibility.md |

### 3.2 新目录结构

```
skills/bazi/
├── SKILL.md                    # < 200 行
├── rules/
│   ├── _index.md
│   ├── basic-reading.md        # 命盘解读
│   ├── career.md               # 事业分析
│   ├── relationship.md         # 感情婚姻
│   ├── wealth.md               # 财运分析
│   ├── fortune.md              # 运势预测
│   └── compatibility.md        # 合婚配对
├── tools/
│   ├── tools.yaml
│   └── handlers.py
├── archive/                    # 归档
│   └── scenarios/              # 旧场景文件
└── metadata.json
```

### 3.3 SKILL.md 对比

**重构前**（172 行，包含场景目录）：
```markdown
## 场景目录

### Entry（入门级）
| 场景 | 文件 | 触发词 | 计费 | 展示名称 | 图标 | 简介 |
|-----|------|-------|------|---------|------|------|
| 基础解读 | basic_reading.md | 看命盘、算命、测算 | 免费 | 基础解读 | 📋 | ... |
| ... (6 行) |

### Standard（标准级）
| 场景 | 文件 | 触发词 | 计费 | 展示名称 | 图标 | 简介 | 价值点 |
|-----|------|-------|------|---------|------|------|--------|
| ... (40+ 行) |

### Professional（专业级）
| 场景 | 文件 | 触发词 | 计费 | 展示名称 | 图标 | 简介 | 价值点 |
|-----|------|-------|------|---------|------|------|--------|
| ... (30+ 行) |
```

**重构后**（< 150 行，包含能力索引）：
```markdown
## 核心能力索引

| 能力 | 优先级 | 规则文件 | 触发场景 |
|-----|-------|---------|---------|
| 命盘解读 | CRITICAL | `rules/basic-reading.md` | 第一次算命、了解命盘、基础分析 |
| 事业分析 | HIGH | `rules/career.md` | 事业、职业、跳槽、升职、工作 |
| 感情婚姻 | HIGH | `rules/relationship.md` | 感情、婚姻、桃花、配偶 |
| 财运分析 | MEDIUM | `rules/wealth.md` | 财运、投资、求财、收入 |
| 运势预测 | MEDIUM | `rules/fortune.md` | 大运、流年、运势、年运 |
| 合婚配对 | LOW | `rules/compatibility.md` | 合婚、配对、双方八字 |

**使用方式**：匹配用户意图后，读取对应规则文件获取详细分析步骤。
```

---

## 4. 验证清单

### 4.1 目录结构检查

- [ ] `rules/` 目录已创建
- [ ] 所有核心能力都有对应的 rule 文件
- [ ] `scenarios/` 已归档到 `archive/`
- [ ] `SKILL.md` 已更新

### 4.2 SKILL.md 检查

- [ ] 行数 < 200 行
- [ ] 场景目录表格已删除
- [ ] 核心能力索引表格已添加
- [ ] 每个能力都有优先级标注
- [ ] 每个能力都指向 rule 文件

### 4.3 Rule 文件检查

- [ ] 每个 rule 文件都有完整的 frontmatter
- [ ] 每个 rule 文件都有分析要点表格
- [ ] 每个分析要点都有检索 Query
- [ ] 每个 rule 文件都有输出要求

### 4.4 skill_loader.py 检查

- [ ] `route_scenario()` 已删除
- [ ] `load_scenario()` 已删除
- [ ] `load_rule()` 已添加
- [ ] `build_system_prompt()` 已更新
- [ ] 不再注入 Scenario SOP

### 4.5 功能测试

- [ ] Skill 加载正常
- [ ] Rule 加载正常
- [ ] System Prompt 构建正常
- [ ] 端到端对话正常

---

## 5. 回滚方案

如果重构出现问题，可以快速回滚：

```bash
# 1. 恢复 scenarios 目录
mv skills/{skill_id}/archive/scenarios skills/{skill_id}/

# 2. 恢复旧版 SKILL.md
git checkout HEAD~1 -- skills/{skill_id}/SKILL.md

# 3. 恢复旧版 skill_loader.py
git checkout HEAD~1 -- apps/api/services/agent/skill_loader.py

# 4. 清除缓存
# 在代码中调用 clear_cache()
```

---

## 6. 常见问题

### Q1: 如何处理复杂场景？

**A**: 复杂场景可以在 rule 的"常见问题"部分提供详细指导，或者拆分为多个分析要点。

### Q2: 如何保证分析质量？

**A**:
1. 分析要点表格确保覆盖关键步骤
2. 检索 Query 确保获取相关知识
3. 输出要求确保调用正确的工具

### Q3: LLM 如何知道加载哪个 rule？

**A**: LLM 根据用户意图和能力索引表格中的"触发场景"列来判断，然后读取对应的 rule 文件。

### Q4: 如何处理跨能力的问题？

**A**: LLM 可以组合多个能力的分析规则，按需加载多个 rule 文件。
