# VibeLife V9 系统架构文档

> Version: 9.0 | 2026-01-24
> 核心理念：遵循 Claude Agent SDK 的渐进式 Skill 架构

---

## 1. 架构升级核心

### 1.1 从 V8 到 V9 的关键变化

| 维度 | V8 | V9 |
|------|----|----|
| Skill 加载 | 全量加载 | 渐进式加载（frontmatter → 完整内容） |
| Skill 激活 | 单一 Skill | 多 Skill 并行 |
| 工具调用 | Skill 隔离 | 跨 Skill 编排 |
| 新场景 | 新建 Skill + 工具 | LLM 自主编排现有 Skill |

### 1.2 Claude Agent SDK Skill 架构原则

```
启动时：加载所有 SKILL.md frontmatter (id, name, description, triggers)
       ↓
Phase 1：LLM 看到 Skill 列表 + 描述，选择激活哪个 Skill(s)
       ↓
Phase 2：加载已选 Skill(s) 的完整内容 + tools/rules
```

**核心理念**：
1. **Frontmatter 只加载一次**：轻量，约 100 tokens/Skill
2. **完整内容按需加载**：进入 Skill 后才加载工具定义和规则
3. **Skill 可叠加**：不是互斥的，可以同时激活多个
4. **LLM 自主编排**：不需要为每个场景写新 Skill

---

## 2. Skill 系统

### 2.1 Skill 目录结构

```
skills/{skill_id}/
├── SKILL.md              # Skill 定义（frontmatter + 专家身份）
├── rules/                # 规则文件（按需加载）
│   ├── basic-reading.md
│   └── career.md
├── tools/                # 工具定义
│   ├── tools.yaml        # 工具 Schema
│   └── handlers.py       # 工具执行器
└── services/             # 领域服务
    └── api.py
```

### 2.2 SKILL.md Frontmatter 规范

```yaml
---
id: zodiac
name: 西方占星
version: 2.0.0
description: |
  星盘计算与解读。提供计算工具 calculate_zodiac，
  展示工具 show_zodiac_chart、show_zodiac_transit。
  可与其他 Skill 组合使用。
triggers:
  - 星座
  - 星盘
  - 运势
  - 行运
category: astrology
# 工具摘要（Phase 1 展示，不加载详情）
tools_summary:
  calculate_zodiac: 计算星盘
  show_zodiac_chart: 展示星盘
  show_zodiac_transit: 展示行运
---

# 西方占星 Skill

## 专家身份
...
```

### 2.3 Skill 分层

```
┌─────────────────────────────────────────────────────────────┐
│  Core Layer (始终激活)                                       │
│  └─ core: 生命对话者 - AI 的灵魂                             │
├─────────────────────────────────────────────────────────────┤
│  Default Layer (默认激活，可取消)                            │
│  ├─ mindfulness: 正念导师                                    │
│  └─ lifecoach: 人生教练                                      │
├─────────────────────────────────────────────────────────────┤
│  Professional Layer (需订阅)                                 │
│  ├─ bazi: 八字命理                                          │
│  ├─ zodiac: 西方占星                                        │
│  ├─ synastry: 关系合盘                                      │
│  ├─ tarot: 塔罗占卜                                         │
│  ├─ jungastro: 荣格占星                                     │
│  └─ career: 职业规划                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. CoreAgent 架构

### 3.1 两阶段执行流程

```
用户消息
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Skill 选择（轻量上下文）                            │
│                                                              │
│  System Prompt 包含：                                        │
│  - Core Skill 人格                                          │
│  - 所有 Skill 的 frontmatter（id, name, description）        │
│  - 工具摘要（tools_summary）                                 │
│  - 用户画像（轻量版）                                        │
│                                                              │
│  可用工具：                                                  │
│  - activate_skills(skills: List[str])  ← 支持多 Skill！      │
│  - recommend_skills                                          │
│  - show_protocol_invitation                                  │
└─────────────────────────────────────────────────────────────┘
    │
    │ LLM 调用 activate_skills(["zodiac", "bazi"])
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: Skill 执行（完整上下文）                            │
│                                                              │
│  System Prompt 包含：                                        │
│  - 已激活 Skill 的完整 SKILL.md 内容                         │
│  - 相关 rules/*.md                                          │
│  - 用户 Profile + Skill Data                                │
│  - SOP 规则                                                  │
│                                                              │
│  可用工具：                                                  │
│  - 已激活 Skill 的所有工具                                   │
│  - 全局工具（core/tools）                                    │
│  - activate_skills（支持动态切换）                           │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
流式输出（AI SDK Data Stream Protocol）
```

### 3.2 关键代码变更

#### skill_loader.py

```python
@dataclass
class SkillMeta:
    """轻量元数据（Phase 1）"""
    id: str
    name: str
    description: str
    triggers: List[str]
    category: str
    tools_summary: Dict[str, str]  # {tool_name: brief_desc}

@dataclass
class SkillFull:
    """完整内容（Phase 2）"""
    meta: SkillMeta
    content: str  # 完整 Markdown
    tools: List[ToolDef]  # 从 tools/tools.yaml 加载
    rules: Dict[str, str]  # 从 rules/*.md 加载

# 启动时调用
_skill_metas: Dict[str, SkillMeta] = {}

def load_all_skill_metas() -> Dict[str, SkillMeta]:
    """启动时加载所有 Skill 的 frontmatter"""
    global _skill_metas
    if _skill_metas:
        return _skill_metas

    for skill_dir in SKILLS_DIR.iterdir():
        if skill_dir.is_dir():
            skill_md = skill_dir / "SKILL.md"
            if skill_md.exists():
                meta = _parse_frontmatter(skill_md)
                _skill_metas[meta.id] = meta

    return _skill_metas

def load_skill_full(skill_id: str) -> Optional[SkillFull]:
    """Phase 2 按需加载完整内容"""
    meta = _skill_metas.get(skill_id)
    if not meta:
        return None

    skill_dir = SKILLS_DIR / skill_id

    # 加载完整 SKILL.md 内容
    content = (skill_dir / "SKILL.md").read_text()

    # 加载工具
    tools = load_skill_tools(skill_id)

    # 加载规则
    rules = {}
    rules_dir = skill_dir / "rules"
    if rules_dir.exists():
        for rule_file in rules_dir.glob("*.md"):
            rules[rule_file.stem] = rule_file.read_text()

    return SkillFull(meta=meta, content=content, tools=tools, rules=rules)
```

#### core.py

```python
def build_phase1_tools() -> List[Dict[str, Any]]:
    """Phase 1 路由工具 - 支持多 Skill 激活"""
    skill_metas = load_all_skill_metas()
    available_skills = [s for s in skill_metas.keys() if s != "core"]

    return [
        {
            "type": "function",
            "function": {
                "name": "activate_skills",
                "description": build_skills_description(skill_metas),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "skills": {
                            "type": "array",
                            "items": {"type": "string", "enum": available_skills},
                            "description": "要激活的 Skill ID 列表（1-3个）"
                        },
                        "reason": {
                            "type": "string",
                            "description": "激活原因"
                        }
                    },
                    "required": ["skills"]
                }
            }
        },
        # ... 其他路由工具
    ]

def _get_current_tools(self, context: AgentContext) -> List[Dict[str, Any]]:
    """获取当前可用工具"""
    if not self._active_skills:
        return get_phase1_tools()

    tools = []
    added_tool_names = set()

    # 加载所有已激活 Skill 的工具
    for skill_id in self._active_skills:
        skill_tools = ToolRegistry.get_tools_for_skill(skill_id)
        for tool in skill_tools:
            tool_name = tool.get("function", {}).get("name")
            if tool_name and tool_name not in added_tool_names:
                tools.append(tool)
                added_tool_names.add(tool_name)

    # 添加 activate_skills 工具（支持动态切换）
    tools.append(get_phase1_tools()[0])

    return tools
```

#### prompt_builder.py

```python
def _build_phase1_skills_context(self) -> str:
    """构建 Phase 1 Skill 列表上下文"""
    skill_metas = load_all_skill_metas()

    lines = ["## 可用 Skill\n"]

    for skill_id, meta in skill_metas.items():
        if skill_id == "core":
            continue

        lines.append(f"### {meta.name} ({skill_id})")
        lines.append(f"{meta.description}")

        if meta.tools_summary:
            lines.append("工具：")
            for tool, desc in meta.tools_summary.items():
                lines.append(f"  - {tool}: {desc}")

        lines.append("")

    return "\n".join(lines)
```

---

## 4. 场景处理示例

### 4.1 "今天和老公相处怎么样"

**V8 流程（错误）**：
```
需要新建 relationship_weather Skill
  ↓
写 calculate_relationship_weather 工具
  ↓
工具内部 import zodiac, synastry
  ↓
❌ 每个新场景都要重复这个过程
```

**V9 流程（正确）**：
```
Phase 1 LLM 思考：
  - 这是关系问题 → synastry Skill
  - 需要今日行运 → zodiac Skill
  - 结论：activate_skills(["zodiac"])

Phase 2：
  - 加载 zodiac 完整内容 + 工具
  - LLM 调用：
    1. calculate_zodiac(用户, today)
    2. calculate_zodiac(伴侣, today)
  - 综合分析行运对关系的影响
  - ✅ 不需要新 Skill！
```

### 4.2 "帮我看看职业运势"

```
Phase 1：activate_skills(["bazi", "career"])

Phase 2：
  - 加载 bazi + career 的工具
  - 调用 calculate_bazi → 获取命盘
  - 调用 show_career_analysis → 综合分析
  - ✅ 不需要 includes 配置
```

### 4.3 "我想看合盘"

```
Phase 1：activate_skills(["synastry"])

Phase 2：
  - 使用 synastry 的完整 SOP
  - ✅ 现有功能不受影响
```

---

## 5. 数据模型（继承 V8）

### 5.1 VibeProfile 结构

继承 V8 的 UserDataSpace 设计，无变化：

```yaml
profile:
  account: { vibe_id, display_name, tier, status }
  identity:
    birth_info: { date, time, place, timezone, gender }
  state:
    emotion: "neutral"
    focus: ["career"]
  preferences:
    voice_mode: "warm"
    subscribed_skills: { bazi: {...}, zodiac: {...} }
  skill_data:
    bazi: { chart, features }
    zodiac: { chart, current_transits }
  extracted: { facts, goals, concerns }
  life_context: { goals, tasks, reminders }
```

---

## 6. 迁移路径

### 6.1 Step 1: SKILL.md frontmatter 规范化

为每个 SKILL.md 添加 `tools_summary` 字段：

```yaml
---
id: bazi
name: 八字命理
# ... 其他字段
tools_summary:
  calculate_bazi: 计算八字命盘
  show_bazi_chart: 展示八字命盘
  show_bazi_fortune: 展示大运流年
---
```

### 6.2 Step 2: skill_loader.py 改造

- 新增 `SkillMeta` 和 `SkillFull` 数据类
- 新增 `load_all_skill_metas()` 函数
- 修改 `load_skill()` → `load_skill_full()`

### 6.3 Step 3: core.py 多 Skill 支持

- `activate_skill` → `activate_skills`
- `_active_skill` → `_active_skills: List[str]`
- `_get_current_tools()` 支持多 Skill 工具合并

### 6.4 Step 4: prompt_builder.py 更新

- Phase 1 prompt 注入 Skill 列表和工具摘要
- Phase 2 prompt 支持多 Skill 内容合并

### 6.5 Step 5: 移除 includes 配置

- `routing.yaml` 中的 `includes` 字段不再需要
- 改为动态加载

---

## 7. 验证方法

### 7.1 测试用例

| 场景 | 预期行为 |
|------|---------|
| "今天和老公相处怎么样" | LLM 激活 zodiac，调用 calculate_zodiac(用户) + calculate_zodiac(伴侣) |
| "帮我看看职业运势" | LLM 激活 bazi + career，综合分析 |
| "我想看合盘" | LLM 激活 synastry，使用完整 SOP |
| "帮我算命" | LLM 激活 bazi，正常流程 |

### 7.2 回归测试

- 所有现有 Skill 单独使用时行为不变
- 工具调用结果格式不变
- 前端卡片渲染不受影响

---

## 8. 关键文件路径

| 文件 | 改动类型 |
|------|---------|
| `apps/api/services/agent/skill_loader.py` | 新增分层加载逻辑 |
| `apps/api/services/agent/core.py` | 多 Skill 激活支持 |
| `apps/api/services/agent/prompt_builder.py` | Phase 1 上下文构建 |
| `apps/api/services/agent/tool_registry.py` | 多 Skill 工具合并 |
| `apps/api/skills/*/SKILL.md` | 添加 tools_summary |

---

## 附录

### A. 版本历史

- **V9.0** (2026-01-24):
  - 渐进式 Skill 加载（frontmatter → 完整内容）
  - 多 Skill 并行激活
  - LLM 自主编排，无需新建 Skill

- **V8.0** (2026-01-19):
  - VibeProfile 整合
  - Knowledge v2（Case 倒排索引）

### B. synastry Skill 定位

两种模式共存：
1. **独立 Skill**：用户说"看合盘" → activate_skills(["synastry"])
2. **LLM 编排**：用户说"今天和老公相处" → LLM 调用 zodiac 工具自行分析

无需选择，系统自动适配。
