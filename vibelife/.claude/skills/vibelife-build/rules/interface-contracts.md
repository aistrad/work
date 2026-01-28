---
id: interface-contracts
name: 接口契约文档
impact: HIGH
tags: 接口, CoreAgent, VibeProfile, CardRegistry, 契约
---

# VibeLife 接口契约文档 v10.3

本文档定义 Skill 与平台各组件之间的接口契约。

---

## 1. CoreAgent 接口

### 1.1 @tool_handler 装饰器

**位置**: `apps/api/services/agent/tool_registry.py:300`

```python
from services.agent.tool_registry import tool_handler, ToolContext

@tool_handler("tool_name")
async def execute_tool_name(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """
    工具执行器

    Args:
        args: LLM 传入的工具参数
        context: 工具执行上下文

    Returns:
        Dict: 工具执行结果
    """
    pass
```

### 1.2 ToolContext 数据结构

**位置**: `apps/api/services/agent/tool_registry.py:44`

```python
@dataclass
class ToolContext:
    user_id: str                        # 用户 ID
    user_tier: str = "free"             # 用户等级 (free/premium/vip)
    profile: Dict[str, Any] = field(default_factory=dict)    # 用户 Profile
    skill_data: Dict[str, Any] = field(default_factory=dict) # Skill 数据
    skill_id: Optional[str] = None      # 当前 Skill ID
    scenario_id: Optional[str] = None   # 当前场景 ID
    conversation_id: Optional[str] = None  # 会话 ID
```

### 1.3 ToolResult 返回格式

#### 成功返回（展示卡片）

```python
return {
    "status": "success",
    "cardType": "xxx_chart",    # 前端卡片类型
    "data": { ... }             # 卡片数据
}
```

#### 成功返回（使用 show_card 委托）

```python
from services.agent.tool_registry import ToolRegistry

return await ToolRegistry.execute(
    "show_card",
    {
        "card_type": "custom",
        "data_source": {"type": "inline", "data": card_data},
        "options": {"componentId": "xxx_chart"}
    },
    context
)
```

#### 错误返回

```python
return {
    "status": "error",
    "error": "错误描述",
    "action": "suggested_tool"  # 建议下一步工具
}
```

#### 收集信息返回

```python
return {
    "status": "collecting",
    "cardType": "collect_form",
    "formType": "birth_info",
    "title": "请填写信息",
    "description": "说明文字",
    "fields": [
        {"id": "field1", "label": "标签", "type": "text", "required": True},
        {"id": "field2", "label": "日期", "type": "date", "required": True},
    ],
}
```

### 1.4 should_reload_context 语义

**位置**: `apps/api/services/agent/core.py:444`

当工具返回 `should_reload_context: True` 时：
1. CoreAgent 从工具结果中提取 `skill` 和 `rule`
2. 更新 `self._active_skill` 和 `self._active_scenario`
3. 重新构建 System Prompt（进入 Phase 2）

```python
# 工具返回
return {
    "status": "success",
    "should_reload_context": True,
    "skill": "zodiac",
    "rule": "natal_chart"
}
```

---

## 2. VibeProfile 接口

### 2.1 Profile 三层结构

**位置**: `apps/api/stores/unified_profile_repo.py`

```python
{
    "account": {
        "vibe_id": "VB-A1B2C3D4",
        "status": "active"
    },
    "identity": {
        "birth_info": {
            "date": "1990-01-15",
            "time": "14:30",
            "place": "Shanghai",
            "timezone": "Asia/Shanghai"
        }
    },
    "skills": {
        "zodiac": {
            "chart": { ... },
            "last_calculated": "2025-01-15T10:00:00Z"
        },
        "bazi": {
            "chart": { ... },
            "last_calculated": "2025-01-15T10:00:00Z"
        }
    },
    "vibe": {
        "insight": {
            "archetype": "探索者",
            "traits": ["好奇心强", "追求自由"]
        },
        "target": {
            "focus": ["career", "relationship"]
        }
    }
}
```

### 2.2 读取方法

```python
from stores.unified_profile_repo import UnifiedProfileRepository

# 获取出生信息
birth_info = await UnifiedProfileRepository.get_birth_info(user_id)
# 返回: {"date": "1990-01-15", "time": "14:30", "place": "Shanghai"}

# 获取单个 Skill 数据
skill_data = await UnifiedProfileRepository.get_skill(user_id, "zodiac")
# 返回: {"chart": {...}, "last_calculated": "..."}

# 获取所有 Skills 数据
all_skills = await UnifiedProfileRepository.get_skills(user_id)
# 返回: {"zodiac": {...}, "bazi": {...}}

# 获取 Vibe 数据
vibe = await UnifiedProfileRepository.get_vibe(user_id)
# 返回: {"insight": {...}, "target": {...}}

# 获取 Vibe Insight
insight = await UnifiedProfileRepository.get_vibe_insight(user_id)
# 返回: {"archetype": "探索者", "traits": [...]}

# 获取 Vibe Target
target = await UnifiedProfileRepository.get_vibe_target(user_id)
# 返回: {"focus": ["career", "relationship"]}
```

### 2.3 写入方法

```python
# 保存 Skill 数据（只写入 skills.{skill}）
await UnifiedProfileRepository.update_skill(
    user_id,
    skill="zodiac",
    data={"chart": {...}, "last_calculated": "..."}
)
```

### 2.4 从 ToolContext 读取

```python
@tool_handler("calculate_zodiac")
async def execute_calculate_zodiac(args, context):
    # 读取 profile
    profile = context.profile or {}

    # 读取 identity.birth_info
    identity = profile.get("identity", {})
    birth_info = identity.get("birth_info", {})

    birth_date = birth_info.get("date")
    birth_time = birth_info.get("time", "12:00")
    birth_place = birth_info.get("place", "Shanghai")

    # 读取 skills.xxx
    skill_data = context.skill_data or {}
    zodiac_data = skill_data.get("zodiac", {})
```

---

## 3. CardRegistry 接口

### 3.1 注册卡片组件

**位置**: `apps/web/src/skills/CardRegistry.ts`

```typescript
import { registerCard, registerLazyCard } from "@/skills/CardRegistry";

// 方式一：直接注册
registerCard("xxx_chart", XxxChartCard);

// 方式二：懒加载注册（推荐大型组件）
registerLazyCard("xxx_chart", () => import("./cards/XxxChartCard"));
```

### 3.2 卡片组件 Props 契约

```typescript
interface CardProps {
  data: any;                           // 后端返回的数据
  onSubmit?: (answer: string) => void; // 交互式卡片回调
}

function XxxCard({ data, onSubmit }: CardProps) {
  return <div>...</div>;
}
```

### 3.3 card_type 命名规范

| 格式 | 说明 | 示例 |
|-----|------|------|
| `{skill}_{type}` | Skill 专属卡片 | `zodiac_chart`, `bazi_fortune` |
| `collect_form` | 收集表单 | 通用 |
| `insight_card` | 洞察卡片 | 通用 |
| `custom` + `componentId` | 自定义组件 | `{cardType: "custom", componentId: "xxx"}` |

### 3.4 注册入口

**位置**: `apps/web/src/skills/initCards.ts`

```typescript
// 导入即注册
import './zodiac/cards';
import './bazi/cards';
import './xxx/cards';  // 新增 Skill 卡片
```

### 3.5 CardRegistry API

```typescript
// 注册卡片
registerCard(cardType: string, Component: React.FC<any>): void

// 懒加载注册
registerLazyCard(cardType: string, loader: () => Promise<{default: React.FC}>): void

// 检查是否注册
CardRegistry.has(cardType: string): boolean

// 渲染卡片
CardRegistry.render(cardType: string, props: any): ReactNode

// 获取已注册类型
CardRegistry.getTypes(): string[]
```

---

## 4. 数据流完整示例

### 4.1 后端 → 前端 数据流

```
┌─────────────────────────────────────────────────────────────────┐
│ handlers.py                                                     │
│                                                                 │
│ @tool_handler("calculate_zodiac")                               │
│ async def execute_calculate_zodiac(args, context):              │
│     chart = calc_zodiac(birth_date, birth_time, birth_place)    │
│     return await ToolRegistry.execute("show_card", {            │
│         "card_type": "custom",                                  │
│         "data_source": {"type": "inline", "data": card_data},   │
│         "options": {"componentId": "zodiac_chart"}              │
│     }, context)                                                 │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ SSE Stream
                          │ [[TOOL:calculate_zodiac:{"cardType":"custom",...}]]
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ ChatMessage.tsx → ToolCardRenderer                              │
│                                                                 │
│ 1. 解析工具调用: [[TOOL:xxx:{"cardType":"yyy",...}]]            │
│ 2. 提取 cardType 和 componentId                                 │
│ 3. 从 CardRegistry 获取组件                                      │
│ 4. 渲染卡片: CardRegistry.render(cardType, {data, onSubmit})    │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 交互式卡片回调

```typescript
// ChatMessage.tsx
const handleQuestionSubmit = (answer: string) => {
  if (onSendMessage) {
    onSendMessage(answer);  // 发送到聊天 API
  }
};

// 渲染时传递回调
CardRegistry.render(cardType, {
  data: toolData,
  onSubmit: handleQuestionSubmit,
});
```

---

## 5. 检查清单

### CoreAgent 接口检查

- [ ] 使用 `@tool_handler("tool_name")` 装饰器
- [ ] 函数签名: `async def xxx(args: Dict, context: ToolContext) -> Dict`
- [ ] 成功返回包含 `status: "success"` 和 `cardType`
- [ ] 错误返回包含 `status: "error"` 和 `error`

### VibeProfile 接口检查

- [ ] 从 `context.profile` 读取用户数据
- [ ] 使用 `UnifiedProfileRepository.update_skill()` 写入数据
- [ ] 路径正确: `identity.birth_info`, `skills.{skill}`, `vibe.insight`

### CardRegistry 接口检查

- [ ] 在 `apps/web/src/skills/{skill}/cards/` 创建组件
- [ ] 调用 `registerCard(cardType, Component)`
- [ ] 在 `initCards.ts` 中导入
- [ ] 组件 Props 包含 `data` 和可选的 `onSubmit`
