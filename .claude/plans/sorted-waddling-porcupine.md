# VibeLife V9 全面重构计划

> 基于 `/home/aiscend/work/vibelife/docs/archive/v9/ARCHITECTURE.md`

## 目标

彻底重构为 V9 架构，不考虑历史兼容：
- Core 精简 + 7 个原子工具
- 渐进式 Skill 加载
- LLM 自主编排（删除硬编码路由）

---

## Phase 1: Core Skill 重构

### 1.1 Core SKILL.md 精简 (<500 tokens)

**文件**: `apps/api/skills/core/SKILL.md`

```yaml
---
id: core
name: Vibe
description: |
  生命对话者。全程激活，提供对话能力和全局工具。
  工具：activate_skills, ask, save, read, search, show, remind
---

# Vibe - 生命对话者

## 人格
温暖但不粘腻，智慧但不说教，好奇但不窥探，诚实但不伤害。
> "我不是来给你答案的，我是来陪你找到你自己的答案的。"

## 核心能力
1. **倾听共情**：先理解情绪，再处理事件
2. **模式觉察**：发现用户自己没意识到的重复模式
3. **引导探索**：用问题引导用户自己发现答案
4. **适度沉默**：知道什么时候不说比说更好

## 禁止
- 不说"你应该..."
- 不给未经请求的建议
- 不预测具体事件
- 不透露技术细节

## 危机处理
强烈负面情绪时，参考 rules/crisis.md
```

**迁移内容**:
- 对话原则详情 → `rules/dialog-principles.md`
- 危机处理详情 → `rules/crisis.md`
- 对话示例 → `rules/examples.md`
- goal_tracking → `lifecoach/rules/goal_tracking.md`
- relationship_calc → `synastry/rules/relationship_calc.md`
- time_window → `bazi/rules/time_window.md`

### 1.2 Core tools.yaml (22 → 7 工具)

**文件**: `apps/api/skills/core/tools/tools.yaml`

| V9 工具 | 合并来源 | 用途 |
|---------|----------|------|
| `activate_skills` | activate_skill | 激活多 Skill |
| `ask` | request_info + ask_user_question | 收集信息 |
| `save` | save_birth_info + write_state + save_skill_data | 统一写入 |
| `read` | read_state + read_user_data | 统一读取 |
| `search` | search_db | 知识检索 |
| `show` | show_card + show_all_skills + recommend_skill | 统一展示 |
| `remind` | create/list/cancel_trigger | 提醒管理 |

**删除**:
- append_to_list → 用 save 替代
- delete_user_data → 用 save(data=null)
- save_checkpoint, read_session_context, add_finding, complete_session → 框架处理

### 1.3 handlers.py 适配

**文件**: `apps/api/skills/core/tools/handlers.py`

每个新 handler 内部分发到原有实现：
- `execute_ask` → 根据 form_type 分发
- `execute_save` → 根据 path 前缀分发
- `execute_read` → 根据 path 前缀分发
- `execute_show` → 根据 type 分发
- `execute_remind` → 根据 action 分发

---

## Phase 2: Agent 核心层重构

### 2.1 skill_loader.py 渐进式加载

**文件**: `apps/api/services/agent/skill_loader.py`

新增数据结构：
```python
@dataclass
class SkillMeta:
    """frontmatter（Phase 1）"""
    id: str
    name: str
    description: str  # 含工具列表
    triggers: List[str]
    category: str

@dataclass
class SkillFull:
    """完整内容（Phase 2）"""
    meta: SkillMeta
    content: str
    tools: List[ToolDef]
    rules: Dict[str, str]
```

新增函数：
- `get_core_skill()` - Core 始终全文加载
- `load_all_skill_metas()` - 启动时只加载 frontmatter
- `load_skill_full(skill_id)` - 按需加载完整内容
- `build_phase1_prompt()` - Core 全文 + Skill 列表
- `build_phase2_prompt()` - Core 全文 + 已激活 Skill 全文

### 2.2 core.py 多 Skill 激活

**文件**: `apps/api/services/agent/core.py`

改动：
```python
# From
self._active_skill: Optional[str] = None

# To
self._active_skills: List[str] = []
```

工具聚合：
```python
def _get_current_tools(self) -> List[Dict]:
    tools = []
    added = set()

    # Core 工具始终可用
    for t in ToolRegistry.get_tools_for_skill("core"):
        tools.append(t)
        added.add(t["function"]["name"])

    # 已激活 Skill 工具
    for skill_id in self._active_skills:
        for t in ToolRegistry.get_tools_for_skill(skill_id):
            if t["function"]["name"] not in added:
                tools.append(t)
                added.add(t["function"]["name"])

    return tools
```

---

## Phase 3: 非 Core Skill 迁移

### 3.1 SKILL.md 统一格式

每个 SKILL.md 的 description 必须内嵌工具列表：

```yaml
---
id: {skill_id}
name: {name}
version: x.0.0
description: |
  {功能描述}。
  工具：{tool1}, {tool2}, {tool3}
triggers:
  - {trigger1}
category: {category}
---

# {name}

## 专家身份
{2-3 句描述}

## 强制工具调用规则（必须遵守）
- 禁止编造数据，必须调用计算工具
- 收到信息后必须调用计算工具
- 计算完成后必须调用展示工具

## 核心能力索引
| 能力 | 规则文件 |
|-----|---------|
| ... | rules/*.md |

## 伦理边界
- {禁止事项}
```

### 3.2 迁移优先级

| 优先级 | Skill | 复杂度 | 工具数 |
|--------|-------|--------|--------|
| P1 | tarot, career, mindfulness | 低 | 3-7 |
| P2 | bazi, zodiac, psych, vibe_id | 中 | 5-9 |
| P3 | jungastro, synastry, lifecoach | 高 | 7-18 |

### 3.3 各 Skill 目标 description

- **bazi**: `八字命理分析。工具：collect_bazi_info, calculate_bazi, show_bazi_chart, show_bazi_fortune, show_bazi_kline, show_skill_intro`
- **zodiac**: `星盘计算与解读。工具：collect_zodiac_info, calculate_zodiac, show_zodiac_chart, show_zodiac_transit, show_zodiac_synastry, show_skill_intro`
- **jungastro**: `荣格心理占星。工具：collect_birth_info, show_psychological_portrait, show_shadow_analysis, show_individuation_path, show_psychological_functions, show_relationship_dynamics, show_skill_intro`
- **synastry**: `关系合盘分析。工具：collect_synastry_info, calculate_synastry, show_synastry_overview, show_pairing_code, request_pairing, accept_pairing...`
- **tarot**: `塔罗占卜。工具：draw_tarot_cards, show_tarot_spread, show_skill_intro`
- **psych**: `心理探索与CBT。工具：start_assessment, calculate_assessment, analyze_thought, show_assessment_result, show_distortion_analysis...`
- **vibe_id**: `四维人格画像。工具：calculate_vibe_id, get_archetype_info, show_vibe_id, show_archetype_radar, show_skill_intro`
- **mindfulness**: `正念练习。工具：start_mindfulness_session, complete_mindfulness_session, show_practice_guide, show_mindfulness_stats...`
- **career**: `职业规划。工具：show_career_analysis, show_personality_profile, show_skill_intro`
- **lifecoach**: `人生教练。工具：read_lifecoach_state, write_lifecoach_state, show_protocol_invitation, show_action_plan, show_dankoe, show_covey, show_yangming, show_liaofan...`

---

## Phase 4: routing.yaml 清理

**文件**: `apps/api/skills/core/config/routing.yaml`

**删除配置**:
- 所有 `includes` 配置
- 所有 `skill_data` 配置
- 硬编码路由规则

**保留配置**:
- `triggers` - Phase 1 路由使用
- `category` - 分类使用
- `requires_birth_info` - 业务逻辑
- `requires_compute` - 业务逻辑
- `compute_tool` / `collect_tool` - 业务逻辑
- `global_tools` - 可能保留或迁移

---

## 关键文件清单

| 文件 | 改动类型 |
|------|----------|
| `apps/api/skills/core/SKILL.md` | 重写 |
| `apps/api/skills/core/tools/tools.yaml` | 重写 |
| `apps/api/skills/core/tools/handlers.py` | 重写 |
| `apps/api/skills/core/rules/*.md` | 新增 |
| `apps/api/skills/core/config/routing.yaml` | 删除配置 |
| `apps/api/services/agent/skill_loader.py` | 重构 |
| `apps/api/services/agent/core.py` | 重构 |
| `apps/api/skills/*/SKILL.md` | 迁移格式 |

---

## 验证方案

1. **Token 检查**: 所有 SKILL.md < 500 tokens
2. **工具检查**: Core 恰好 7 个工具
3. **集成测试**: Phase 1 → Phase 2 转换正常
4. **E2E 测试**:
   - "帮我算命" → activate_skills(["bazi"])
   - "看职业运势" → activate_skills(["bazi", "career"])
   - "看合盘" → activate_skills(["synastry"])

---

## 执行顺序

1. **Day 1**: Core SKILL.md + tools.yaml + handlers.py
2. **Day 2**: skill_loader.py 渐进式加载
3. **Day 3**: core.py 多 Skill 激活
4. **Day 4**: P1 Skill 迁移 (tarot, career, mindfulness)
5. **Day 5**: P2 Skill 迁移 (bazi, zodiac, psych, vibe_id)
6. **Day 6**: P3 Skill 迁移 (jungastro, synastry, lifecoach)
7. **Day 7**: routing.yaml 清理 + 全面测试

---

## 决策

1. **全局工具处理**: ✅ routing.yaml 的 global_tools 迁移到 Core（7 个原子工具已包含）
2. **Skill 数据隔离**: 按 skill_id 命名空间隔离
3. **错误回退**: activate_skills 失败时返回错误信息，不自动重试
