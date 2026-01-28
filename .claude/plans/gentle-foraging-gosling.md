# Bazi Skill 全栈重构计划

> 基于 vibe-skill v7.0 架构，将 bazi skill 从 scenario 驱动重构为 agentic + rule 架构

---

## 目标

将 bazi skill 从 **122 个 scenarios** 精简为 **6 个 rules**，参考 zodiac 结构：
- SKILL.md < 200 行（当前 172 行）
- LLM 语义理解路由（替代触发词匹配）
- 工具定义清晰，包含 `when_to_call`

---

## 重构范围

| 组件 | 变更类型 | 说明 |
|-----|---------|------|
| SKILL.md | 重写 | 删除场景目录，改为能力索引 |
| scenarios/ | 归档 | 移动到 `_archive/` |
| rules/ | 新建 | 6 个规则文件 |
| tools/tools.yaml | 重构 | 统一参数命名，添加 when_to_call |
| tools/handlers.py | 重构 | 移除 demo fallback，统一错误处理 |
| skill_loader.py | 修改 | 新增 load_rule、RuleConfig |

---

## Phase 1: 目录结构调整

```bash
# 1. 创建 rules 目录
mkdir -p apps/api/skills/bazi/rules

# 2. 归档 scenarios
mkdir -p apps/api/skills/bazi/scenarios/_archive
mv apps/api/skills/bazi/scenarios/*.md apps/api/skills/bazi/scenarios/_archive/
```

**结果**：
```
skills/bazi/
├── SKILL.md
├── rules/                    # 新建
│   ├── basic-reading.md
│   ├── career.md
│   ├── relationship.md
│   ├── wealth.md
│   ├── fortune.md
│   └── compatibility.md
├── scenarios/
│   └── _archive/             # 归档 122 个文件
├── tools/
└── services/
```

---

## Phase 2: 创建 6 个 Rules 文件

### 2.1 rules/basic-reading.md (CRITICAL)
- 合并：basic_reading, personality, quick_query, 综合分析
- 分析要点：日主分析、身强身弱、格局识别、五行分布、用神确定

### 2.2 rules/career.md (HIGH)
- 合并：career, shishen_career_matching, 官杀分析
- 分析要点：官杀星、食伤配置、印星分析、用神五行行业

### 2.3 rules/relationship.md (HIGH)
- 合并：relationship, 配偶分析, 六亲分析
- 分析要点：日支分析、夫/妻星、桃花分析、婚姻时机

### 2.4 rules/wealth.md (MEDIUM)
- 合并：wealth, 财星分析, 格局分析
- 分析要点：财星分析、财多身弱、食伤生财、比劫争财

### 2.5 rules/fortune.md (MEDIUM)
- 合并：dayun, yearly_fortune, 大运流年
- 分析要点：当前大运、流年影响、冲合刑害、转运时机

### 2.6 rules/compatibility.md (LOW)
- 合并：compatibility
- 分析要点：日主五行、年柱纳音、日支配对、婚配建议

---

## Phase 3: 重写 SKILL.md

**目标**：< 150 行

**结构**：
```markdown
---
name: bazi
description: 八字命理专家...触发词：八字、命理...
---

# 八字命理 Skill

## 专家身份 (~20行)
## 核心能力索引 (~15行，6个能力)
## 工具快速参考 (~25行)
## 知识检索策略 (~15行)
## 服务原则 (~10行)
## 伦理边界 (~15行)
## 详细文档 (~5行)
```

---

## Phase 4: 重构工具系统

### 4.1 tools.yaml 改进

| 改进点 | 说明 |
|-------|------|
| 参数命名 | 统一 snake_case |
| when_to_call | 每个工具添加明确调用时机 |
| 类型标注 | collect/compute/display 分类 |

### 4.2 handlers.py 改进

| 改进点 | 说明 |
|-------|------|
| 移除 demo fallback | 返回明确错误 |
| 统一参数获取 | `_get_birth_info()` 辅助函数 |
| 详细日志 | 增加日志记录 |

---

## Phase 5: 修改 skill_loader.py

### 5.1 新增数据结构

```python
@dataclass
class RuleConfig:
    id: str
    name: str
    impact: str  # CRITICAL/HIGH/MEDIUM/LOW
    impact_description: str
    tags: List[str]
    content: str
    analysis_steps: List[Dict]
    output_requirements: str
    common_questions: str
```

### 5.2 新增函数

| 函数 | 说明 |
|-----|------|
| `parse_rule_md()` | 解析 rules/*.md |
| `load_rule()` | 加载规则配置（缓存） |
| `route_to_rule()` | 规则路由 |

### 5.3 修改函数

| 函数 | 修改 |
|-----|------|
| `build_system_prompt()` | 支持 rule 架构 |
| `get_skill_scenarios()` | 优先返回 rules |
| `clear_cache()` | 清理 rule 缓存 |

---

## Phase 6: 测试验证

### 6.1 单元测试
```bash
pytest tests/test_bazi_skill_refactor.py -v
```

### 6.2 集成测试
```bash
pytest tests/test_bazi_e2e.py -v
```

### 6.3 手动测试清单
- [ ] "帮我算命" → 弹出收集表单
- [ ] "看命盘" → 展示命盘卡片
- [ ] "今年运势" → 展示大运流年卡片
- [ ] "适合什么工作" → 路由到 career 规则
- [ ] 无出生信息 → 返回错误（非 demo 数据）

---

## 关键文件

| 文件 | 操作 |
|-----|------|
| `apps/api/skills/bazi/SKILL.md` | 重写 |
| `apps/api/skills/bazi/rules/*.md` | 新建 6 个 |
| `apps/api/skills/bazi/tools/tools.yaml` | 重构 |
| `apps/api/skills/bazi/tools/handlers.py` | 重构 |
| `apps/api/services/agent/skill_loader.py` | 修改 |
| `apps/api/skills/zodiac/rules/*.md` | 参考模板 |

---

## 未解决问题

1. **前端适配**：服务目录展示是否依赖场景表格？需确认。
2. **规则路由精度**：当前用关键词匹配，是否需要向量检索？
3. **知识库 Query 变量替换**：rules 中的 Query 模板如何动态填充？

---

## 执行顺序

1. Phase 1: 目录结构调整（5 min）
2. Phase 2: 创建 6 个 rules 文件（30 min）
3. Phase 3: 重写 SKILL.md（15 min）
4. Phase 4: 重构工具系统（20 min）
5. Phase 5: 修改 skill_loader.py（30 min）
6. Phase 6: 测试验证（20 min）

**总计**：约 2 小时
