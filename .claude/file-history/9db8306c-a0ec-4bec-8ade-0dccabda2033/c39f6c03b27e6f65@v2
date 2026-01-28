# V9 架构优化实施计划

> 基于 `docs/archive/v9/ARCHITECTURE.md` Review 及多方意见整合

## 目标

统一工具 DSL、增强防注入策略、补充执行护栏、完善缓存策略。

---

## P0 任务（Critical）

### 1. tools.yaml 参数修订
**文件**: `apps/api/skills/core/tools/tools.yaml`

- `save.data`: `required: false`, 添加 `nullable: true`
- `remind`: 添加 `timezone`, `rrule`, `quiet_hours` 参数

### 2. 执行护栏
**文件**: `apps/api/services/agent/core.py`

```python
@dataclass
class ExecutionGuardrails:
    max_tool_steps: int = 10
    step_timeout_ms: int = 30000
    total_timeout_ms: int = 180000

# run() 中添加步数检查
if self._tool_step_count >= guardrails.max_tool_steps:
    yield AgentEvent(type="step_limit")
    return
```

### 3. Phase 1 防注入
**文件**: `apps/api/services/agent/skill_loader.py`

```python
def build_phase1_prompt_safe() -> str:
    # 只注入结构化数据 (id, name, triggers)
    parts.append(f"- **{meta.name}** (`{skill_id}`): 触发词 [{triggers}]")
    # 不注入自由文本 description
```

### 4. Skill SKILL.md 格式确认
**状态**: ✅ 全部通过
- core, zodiac, bazi, tarot, synastry, lifecoach, career, mindfulness, psych, vibe_id, jungastro
- 全部 description 包含 `工具：xxx, yyy` 格式

---

## P1 任务（High）

### 5. 缓存策略
**文件**: `apps/api/services/agent/skill_loader.py`

```python
class SkillCache:
    def __init__(self, max_size=50, ttl_seconds=300)
    def get(path) -> Optional[str]  # TTL + SHA 校验
    def set(path, value)  # LRU 淘汰
```

### 6. handlers.py 扩展
**文件**: `apps/api/skills/core/tools/handlers.py`

- `remind`: 处理 timezone/rrule/quiet_hours
- V8 兼容层: 添加 `logger.warning("[V8-COMPAT] ...")`

### 7. ToolRegistry 命名冲突
**文件**: `apps/api/services/agent/tool_registry.py`

```python
# Core 工具优先，按 {skill_id}.{tool_name} 存储
def get_tools_for_skill(skill_id) -> List[Dict]:
    # Core 优先 → 指定 Skill
```

### 8. 架构文档更新
**文件**: `docs/archive/v9/ARCHITECTURE.md`

- 统一 version: "3.0"
- 明确 type 枚举: action | collect | display | search | routing | trigger
- 补充执行护栏配置表
- 补充 Phase 1/2 防注入策略
- 修订 remind/save schema

---

## P2 任务（Medium）

- frontmatter 添加可选 `exposed_tools` 字段
- 热更新 watchman 集成
- lifecoach SKILL.md 拆分（当前 ~345 行）

---

## 文件改动汇总

| 文件 | 优先级 | 改动点 |
|-----|-------|--------|
| `apps/api/skills/core/tools/tools.yaml` | P0 | save/remind 参数 |
| `apps/api/services/agent/core.py` | P0 | 执行护栏 |
| `apps/api/services/agent/skill_loader.py` | P0+P1 | 防注入、缓存 |
| `apps/api/skills/core/tools/handlers.py` | P1 | remind 扩展、V8 日志 |
| `apps/api/services/agent/tool_registry.py` | P1 | 命名冲突处理 |
| `docs/archive/v9/ARCHITECTURE.md` | P1 | 文档更新 |

---

## 未解决问题

1. **时区默认值**: remind.timezone 是否从用户 Profile 读取？
2. **quiet_hours 跨天**: 22:00-08:00 解析为两段？
3. **rrule 上限**: 是否限制最大触发次数？
4. **Phase 1 防注入 A/B 测试**: 移除 description 是否影响路由准确性？

---

## 验证方式

1. **单测**: save(data=null) 删除语义、remind timezone/rrule
2. **集成测试**: 步数上限触发、Phase 1 路由准确性
3. **CI 检查**: Core SKILL.md < 500 tokens

---

## 验收标准

- [ ] tools.yaml version: "3.0" 全部统一
- [ ] save(data=null) 删除功能正常
- [ ] remind 支持 timezone/rrule
- [ ] 步数上限 10 步生效
- [ ] Phase 1 Prompt 不含自由文本
- [ ] V8 兼容层有日志记录
