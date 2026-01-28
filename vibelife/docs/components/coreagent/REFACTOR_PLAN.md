# CoreAgent 重构方案

> 日期: 2026-01-20
> 状态: Draft
> 范围: 协议流、工具设计、Profile 结构

---

## 1. 背景

当前架构存在以下问题：

| 问题 | 现状 | 影响 |
|-----|------|-----|
| Skill 专用工具 | `read_lifecoach_state` / `write_lifecoach_state` | 每个 Skill 需要重复实现 |
| 数据存储分散 | `skill_data` + `life_context._paths` | 区分不清晰，查询复杂 |
| 协议逻辑位置 | 计划放在 CoreAgent | CoreAgent 职责过重 |

---

## 2. 重构目标

1. **工具通用化**：一套工具，所有 Skill 复用
2. **数据结构简化**：统一到 `profile.skills.{skill_id}`
3. **协议逻辑分层**：路由层处理协议，CoreAgent 保持通用

---

## 3. Profile 结构重构

### 3.1 现状

```
profile
├── account
├── birth_info
├── preferences
├── state
│
├── skill_data              # 计算结果
│   ├── bazi: {chart: ...}
│   └── zodiac: {chart: ...}
│
├── life_context            # 用户输入的生活数据
│   └── _paths
│       └── lifecoach: {
│           content: {...},
│           version: 1,
│           updated_at: "..."
│       }
│
└── extracted
```

**问题**：
- `skill_data` vs `life_context` 区分不清晰
- `_paths` 虚拟文件系统过度设计
- lifecoach 数据路径过深：`life_context._paths.lifecoach.content`

### 3.2 目标结构

```
profile
├── account                 # 账户信息
│   ├── vibe_id
│   ├── display_name
│   ├── tier
│   └── status
│
├── birth_info              # 出生信息
│   ├── date
│   ├── time
│   ├── place
│   └── timezone
│
├── preferences             # 用户偏好
│   ├── voice_mode
│   ├── language
│   ├── timezone
│   ├── subscribed_skills
│   ├── push_settings
│   └── blocked_skills
│
├── state                   # 当前状态
│   ├── focus: ["career", "health"]
│   └── updated_at
│
├── skills                  # 统一存储所有 Skill 数据
│   ├── bazi
│   │   ├── chart: {...}           # 计算结果
│   │   ├── insights: [...]        # AI 洞察
│   │   └── _meta: {updated_at}
│   │
│   ├── zodiac
│   │   ├── chart: {...}
│   │   └── _meta: {updated_at}
│   │
│   ├── lifecoach
│   │   ├── system: {...}          # 方法论选择
│   │   ├── north_star: {...}      # 愿景/反愿景
│   │   ├── goals: {...}           # 目标
│   │   ├── current: {...}         # 当前焦点
│   │   ├── progress: {...}        # 进度
│   │   ├── journal: [...]         # 日志
│   │   ├── protocol: {...}        # 协议状态（新增）
│   │   └── _meta: {updated_at}
│   │
│   └── career
│       ├── resume: {...}
│       ├── goals: {...}
│       └── _meta: {updated_at}
│
└── extracted               # AI 抽取的跨 Skill 信息
    ├── facts: [...]
    ├── concerns: [...]
    ├── goals: [...]
    └── patterns: [...]
```

### 3.3 变化总结

| 现状 | 目标 | 说明 |
|-----|------|-----|
| `skill_data.bazi` | `skills.bazi` | 重命名 |
| `life_context._paths.lifecoach.content` | `skills.lifecoach` | 扁平化 |
| 分散存储 | 统一到 `skills` | 简化查询 |

---

## 4. 工具设计重构

### 4.1 现状

```yaml
# lifecoach 专用
- read_lifecoach_state
- write_lifecoach_state
- add_journal_entry
- update_progress

# 如果 career 也需要存储数据...
- read_career_state    # 需要新增
- write_career_state   # 需要新增
```

**问题**：每个 Skill 需要重复实现读写工具

### 4.2 目标：通用工具

```yaml
# 通用数据工具（所有 Skill 共享）
- name: read_state
  description: 读取当前 Skill 的用户状态
  type: data
  parameters:
    - name: sections
      type: array
      description: 要读取的部分（不传则读取全部）

- name: write_state
  description: 写入当前 Skill 的用户状态（深度合并）
  type: data
  parameters:
    - name: section
      type: string
      required: true
      description: 要写入的部分
    - name: data
      type: object
      required: true
      description: 要写入的数据

- name: append_to_list
  description: 向列表追加条目（如日志、记录）
  type: data
  parameters:
    - name: path
      type: string
      required: true
      description: 列表路径，如 "journal" 或 "progress.milestones"
    - name: entry
      type: object
      required: true
      description: 要追加的条目
    - name: max_items
      type: integer
      default: 100
      description: 列表最大长度（超出则删除最旧的）
```

### 4.3 实现

```python
# services/agent/global_handlers.py

from services.agent.tool_registry import tool_handler, ToolContext
from stores.unified_profile_repo import UnifiedProfileRepository


@tool_handler("read_state")
async def read_state(args: Dict, context: ToolContext) -> Dict:
    """
    通用状态读取 - 自动使用当前 skill_id

    LLM 不需要传 skill_id，从 context 自动获取
    """
    skill_id = context.skill_id
    if not skill_id:
        return {"status": "error", "message": "No active skill"}

    sections = args.get("sections")

    data = await UnifiedProfileRepository.get_skill_state(
        context.user_id,
        skill_id
    )

    if not data:
        return {
            "status": "empty",
            "message": f"尚未建立 {skill_id} 数据",
            "data": {}
        }

    if sections:
        result = {k: v for k, v in data.items() if k in sections}
    else:
        result = data

    return {
        "status": "success",
        "data": result,
        "skill_id": skill_id
    }


@tool_handler("write_state")
async def write_state(args: Dict, context: ToolContext) -> Dict:
    """
    通用状态写入 - 自动使用当前 skill_id

    支持深度合并，不会覆盖未指定的字段
    """
    skill_id = context.skill_id
    if not skill_id:
        return {"status": "error", "message": "No active skill"}

    section = args.get("section")
    data = args.get("data")

    if not section or not data:
        return {"status": "error", "message": "Missing section or data"}

    await UnifiedProfileRepository.update_skill_state(
        context.user_id,
        skill_id,
        section,
        data
    )

    return {
        "status": "success",
        "message": f"已保存 {section}",
        "skill_id": skill_id
    }


@tool_handler("append_to_list")
async def append_to_list(args: Dict, context: ToolContext) -> Dict:
    """
    向列表追加条目

    用于日志、记录等场景
    """
    skill_id = context.skill_id
    if not skill_id:
        return {"status": "error", "message": "No active skill"}

    path = args.get("path")
    entry = args.get("entry")
    max_items = args.get("max_items", 100)

    if not path or not entry:
        return {"status": "error", "message": "Missing path or entry"}

    # 添加时间戳
    entry["_created_at"] = datetime.utcnow().isoformat()

    await UnifiedProfileRepository.append_to_skill_list(
        context.user_id,
        skill_id,
        path,
        entry,
        max_items
    )

    return {
        "status": "success",
        "message": f"已添加到 {path}",
        "skill_id": skill_id
    }
```

### 4.4 Repository 扩展

```python
# stores/unified_profile_repo.py

class UnifiedProfileRepository:

    @staticmethod
    async def get_skill_state(user_id: UUID, skill_id: str) -> Dict:
        """获取 Skill 状态"""
        profile = await UnifiedProfileRepository.get_profile(user_id)
        if not profile:
            return {}
        return profile.get("skills", {}).get(skill_id, {})

    @staticmethod
    async def update_skill_state(
        user_id: UUID,
        skill_id: str,
        section: str,
        data: Dict
    ) -> None:
        """
        更新 Skill 状态（深度合并）

        使用 jsonb_set + || 实现深度合并
        """
        exists = await fetchval(
            "SELECT 1 FROM unified_profiles WHERE user_id = $1",
            user_id
        )

        if exists:
            # 使用 || 操作符进行深度合并
            await execute(
                """UPDATE unified_profiles
                   SET profile = jsonb_set(
                       jsonb_set(
                           jsonb_set(
                               COALESCE(profile, '{}'::jsonb),
                               '{skills}',
                               COALESCE(profile -> 'skills', '{}'::jsonb)
                           ),
                           ARRAY['skills', $2],
                           COALESCE(profile -> 'skills' -> $2, '{}'::jsonb)
                       ),
                       ARRAY['skills', $2, $3],
                       COALESCE(profile -> 'skills' -> $2 -> $3, '{}'::jsonb) || $4::jsonb
                   ),
                   updated_at = NOW()
                   WHERE user_id = $1""",
                user_id, skill_id, section, json.dumps(data, ensure_ascii=False, default=str)
            )
        else:
            await UnifiedProfileRepository.create_profile(
                user_id,
                {"skills": {skill_id: {section: data}}}
            )

        await UnifiedProfileRepository._invalidate_cache(user_id, skill_id)

    @staticmethod
    async def append_to_skill_list(
        user_id: UUID,
        skill_id: str,
        path: str,
        entry: Dict,
        max_items: int = 100
    ) -> None:
        """
        向 Skill 数据中的列表追加条目

        Args:
            path: 列表路径，如 "journal" 或 "progress.milestones"
        """
        # 获取当前数据
        skill_data = await UnifiedProfileRepository.get_skill_state(user_id, skill_id)

        # 解析路径
        parts = path.split(".")
        current = skill_data
        for part in parts[:-1]:
            current = current.setdefault(part, {})

        # 获取或创建列表
        list_key = parts[-1]
        current_list = current.get(list_key, [])
        if not isinstance(current_list, list):
            current_list = []

        # 追加并限制长度
        current_list = [entry] + current_list[:max_items - 1]
        current[list_key] = current_list

        # 写回
        await UnifiedProfileRepository.update_skill_state(
            user_id, skill_id, parts[0],
            skill_data.get(parts[0], {}) if len(parts) > 1 else {list_key: current_list}
        )
```

---

## 5. 协议流设计

### 5.1 设计决策

| 问题 | 决策 | 理由 |
|-----|------|-----|
| 协议触发机制 | 后端工具调用 (`show_protocol_invitation`) | 只有后端知道用户是否适合该协议 |
| 进度数据来源 | SSE 自定义事件 (`protocol_progress`) | 实时更新，不污染消息流 |
| 协议中断恢复 | 自动继续 + 友好提示 | 用户体验最佳 |
| 协议完成过渡 | 无缝过渡，数据永久保存 | 协议结果可复用 |

### 5.2 架构分层

```
┌─────────────────────────────────────────────────────────────┐
│  chat_v5.py (路由层)                                        │
│  ├── 检测协议状态                                           │
│  ├── 构建 protocol_prompt                                   │
│  ├── 发送 protocol_progress SSE 事件                        │
│  └── 检测步骤完成，更新协议状态                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  CoreAgent (执行层)                                         │
│  ├── 接收 context.protocol_prompt                           │
│  ├── 执行 LLM 对话                                          │
│  └── 返回 AgentEvent 流                                     │
└─────────────────────────────────────────────────────────────┘
```

**原则**：CoreAgent 不感知协议逻辑，只负责执行

### 5.3 协议状态存储

```json
// profile.skills.lifecoach.protocol
{
  "id": "dankoe",
  "step": 2,
  "total_steps": 6,
  "started_at": "2026-01-20T10:00:00Z",
  "data": {
    "step_1": { "pain_points": ["工作没意义"] },
    "step_2": { "anti_vision_scene": "..." }
  },
  "completed": false
}
```

### 5.4 SSE 事件扩展

```python
# services/agent/stream_adapter.py

class AISDKv6Adapter(BaseStreamAdapter):
    async def adapt(self, events: AsyncGenerator[AgentEvent, None]):
        # ... 现有逻辑 ...

        async for event in events:
            # ... 现有事件处理 ...

            elif event.type == "protocol_progress":
                # 协议进度更新
                yield self._format({
                    "type": "data",
                    "data": ["protocol_progress", {
                        "protocol_id": event.data.get("protocol_id"),
                        "step": event.data.get("step"),
                        "total_steps": event.data.get("total_steps"),
                        "phase": event.data.get("phase"),
                        "progress": event.data.get("progress"),
                        "step_name": event.data.get("step_name"),
                    }]
                })

            elif event.type == "protocol_completed":
                yield self._format({
                    "type": "data",
                    "data": ["protocol_completed", {
                        "protocol_id": event.data.get("protocol_id"),
                        "summary": event.data.get("summary"),
                    }]
                })
```

### 5.5 协议工具

```yaml
# 协议专用工具（lifecoach）
- name: show_protocol_invitation
  description: 向用户推荐开始一个协议
  type: display
  parameters:
    - name: protocol_id
      type: string
      required: true
    - name: title
      type: string
      required: true
    - name: description
      type: string
      required: true
    - name: estimated_time
      type: string
    - name: actions
      type: array
      required: true
      description: "[{label: '开始重置', value: 'start'}, {label: '稍后再说', value: 'later'}]"

- name: advance_protocol_step
  description: 完成当前协议步骤，保存数据并进入下一步
  type: data
  parameters:
    - name: step_data
      type: object
      required: true
      description: 当前步骤收集的数据
    - name: step_summary
      type: string
      description: 对用户回答的简短总结

- name: cancel_protocol
  description: 取消当前协议
  type: data
  parameters:
    - name: reason
      type: string
      description: 取消原因
```

---

## 6. 迁移计划

### Phase 1: 添加通用工具（无破坏性）

```
1. 添加 read_state / write_state / append_to_list 到 global_handlers.py
2. 添加 get_skill_state / update_skill_state 到 unified_profile_repo.py
3. 在 core skill 的 tools.yaml 中注册通用工具
4. lifecoach 专用工具暂时保留（兼容）
```

### Phase 2: 数据迁移

```sql
-- 将 skill_data 迁移到 skills
UPDATE unified_profiles
SET profile = jsonb_set(
    profile,
    '{skills}',
    COALESCE(profile -> 'skill_data', '{}'::jsonb)
)
WHERE profile -> 'skill_data' IS NOT NULL;

-- 将 life_context._paths.lifecoach 迁移到 skills.lifecoach
UPDATE unified_profiles
SET profile = jsonb_set(
    profile,
    '{skills, lifecoach}',
    COALESCE(
        profile -> 'skills' -> 'lifecoach',
        '{}'::jsonb
    ) || COALESCE(
        profile -> 'life_context' -> '_paths' -> 'lifecoach' -> 'content',
        '{}'::jsonb
    )
)
WHERE profile -> 'life_context' -> '_paths' -> 'lifecoach' IS NOT NULL;
```

### Phase 3: 清理

```
1. 删除 read_lifecoach_state / write_lifecoach_state
2. 删除 life_context 相关代码
3. 删除 skill_data 相关代码（改用 skills）
4. 更新所有引用
```

---

## 7. 未解决问题

1. **协议超时处理**：用户离开1小时后回来，是否需要重新确认？
2. **多协议支持**：如果用户同时在进行多个协议（如 dankoe + covey），如何处理？
3. **协议数据导出**：完成后的数据如何展示？是否需要生成报告？
4. **前端 AI SDK 版本**：需要确认 AI SDK 4.x 如何处理自定义 data 事件

---

## 8. 参考

- [PROTOCOL_DESIGN.md](./PROTOCOL_DESIGN.md) - 协议流详细设计
- [SKILL_DATA_ARCHITECTURE.md](./SKILL_DATA_ARCHITECTURE.md) - Skill 数据架构
- [dankoe.yaml](/apps/api/skills/lifecoach/protocols/dankoe.yaml) - Dan Koe 协议配置
