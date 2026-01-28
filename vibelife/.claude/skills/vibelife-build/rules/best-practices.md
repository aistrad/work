# VibeLife Skill 最佳实践

> 从 zodiac, bazi, synastry, psych 等现有 Skill 提取的生产级最佳实践

## 1. 架构原则

### 1.1 LLM 工具路由 (强制)

**禁止** Python 硬编码条件判断路由，**只允许** LLM 工具调用。

```python
# ❌ 错误 - 硬编码路由
if user_intent == "assessment":
    return start_assessment()
elif user_intent == "chart":
    return show_chart()

# ✅ 正确 - LLM 通过 SKILL.md 规则决定调用哪个工具
# 在 SKILL.md 中定义清晰的工具使用规则
```

### 1.2 工具分类

| 类型 | 用途 | 命名规范 | 示例 |
|------|------|----------|------|
| compute | 计算/处理数据 | `calculate_*`, `analyze_*` | `calculate_zodiac` |
| collect | 收集用户输入 | `collect_*_info` | `collect_zodiac_info` |
| display | 渲染卡片 | `show_*` | `show_zodiac_chart` |
| action | 保存/触发 | `save_*`, `start_*` | `save_progress` |

### 1.3 卡片委托模式

所有展示工具都应委托给 `show_card`：

```python
# ✅ Zodiac 示例 - 统一委托模式
@tool_handler("show_zodiac_chart")
async def execute_show_zodiac_chart(args, context):
    # ... 构建 card_data ...

    return await ToolRegistry.execute(
        "show_card",
        {
            "card_type": "custom",
            "data_source": {"type": "inline", "data": card_data},
            "options": {"componentId": "zodiac_chart"}
        },
        context
    )
```

## 2. SKILL.md 最佳实践

### 2.1 强制工具调用规则 (关键!)

必须明确、重复强调，用 **加粗** 和 ⚠️ 标记：

```markdown
**⚠️ 强制工具调用规则（必须遵守）**：
- **禁止编造星盘数据**！必须调用 `calculate_zodiac` 工具计算
- 用户提供出生信息后，**必须**先调用 `calculate_zodiac(birth_date, birth_time, birth_place)`
- 计算完成后，**必须**调用 `show_zodiac_chart` 展示星盘卡片
- **禁止**在文本中直接写星盘分析结果而不调用工具
```

### 2.2 核心能力索引表

使用表格明确优先级和触发场景：

```markdown
| 能力 | 优先级 | 规则文件 | 触发场景 |
|-----|-------|---------|---------|
| 星盘解读 | CRITICAL | `rules/basic-reading.md` | 看星盘、我的星座、本命盘 |
| 行运分析 | HIGH | `rules/transit.md` | 运势、行运、水逆 |
| 合盘分析 | HIGH | `rules/synastry.md` | 合盘、配对、兼容性 |
```

### 2.3 工具快速参考表

分类清晰，一目了然：

```markdown
### 信息收集
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `collect_zodiac_info` | 收集出生信息 | 用户未提供出生日期/时间/地点时 |

### 展示工具
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `show_zodiac_chart` | 展示星盘 | 用户想看星盘、本命盘时 |
```

### 2.4 知识检索策略

提供 Query 模板：

```markdown
| 检索类型 | Query 模式 | 示例 |
|---------|-----------|------|
| 行星解读 | "{planet} in {sign} 性格 特质" | "太阳 金牛座 性格 特质" |
| 宫位解读 | "{planet} {house}宫 含义" | "月亮 第四宫 含义" |
```

## 3. tools.yaml 最佳实践

### 3.1 when_to_call 字段

明确何时调用，提供具体场景：

```yaml
- name: calculate_zodiac
  description: |
    计算用户星盘。使用 Swiss Ephemeris 进行精确天文计算。
    SOP P2 阶段必须调用此工具。
  when_to_call: |
    - 用户提供了出生信息但尚未计算星盘
    - SOP P2 阶段需要计算排盘
    - 需要刷新或重新计算星盘数据
```

### 3.2 参数默认值

提供合理默认值，减少必填项：

```yaml
parameters:
  - name: birth_date
    type: string
    required: false
    description: 出生日期 (YYYY-MM-DD)，不提供时从 profile 读取
  - name: birth_time
    type: string
    required: false
    description: 出生时间 (HH:MM)
    default: "12:00"
  - name: birth_place
    type: string
    required: false
    description: 出生地点
    default: "Shanghai"
```

## 4. handlers.py 最佳实践

### 4.1 数据获取优先级链

```python
# ✅ Zodiac 示例 - 优先级链
profile = context.profile or {}
identity = profile.get("identity", {})
birth_info = identity.get("birth_info", {})

# 优先使用 args 中的参数，否则从 profile 读取
birth_date = args.get("birth_date") or birth_info.get("date")
birth_time = args.get("birth_time") or birth_info.get("time", "12:00")
birth_place = args.get("birth_place") or birth_info.get("place", "Shanghai")
```

### 4.2 前置检查快速失败

```python
# ✅ 快速失败模式
if not birth_date:
    return {
        "status": "error",
        "error": "需要出生日期才能计算星盘",
        "action": "collect_birth_info"  # 提示下一步动作
    }
```

### 4.3 数据自包含原则

后端返回的数据应该完整，前端不需要额外计算：

```python
# ✅ 数据自包含 - Zodiac 示例
card_data = {
    "userId": context.user_id,
    "birthInfo": {
        "date": birth_date,
        "time": birth_time,
        "place": birth_place,
    },
    # 预计算好的中文名称
    "sunSign": chart.get("sun_sign_chinese", chart.get("sun_sign")),
    "moonSign": chart.get("moon_sign_chinese", chart.get("moon_sign")),
    "risingSign": chart.get("rising_sign_chinese", chart.get("rising_sign")),
    # 完整数据
    "planets": chart.get("planets", []),
    "aspects": chart.get("aspects", []),
    "dominantElement": chart.get("dominant_element"),
    "dominantModality": chart.get("dominant_modality"),
    # 完整原始数据供后续使用
    "_chart": chart,
}
```

### 4.4 _hint 内部通信

引导 AI 下一步动作（用户不可见）：

```python
# ✅ _hint 模式 - 引导 AI 行为
if not user_has_birth_info and context.user_id and context.user_id != "guest":
    card_data["_hint"] = {
        "action": "ask_save_birth_info",
        "message": "用户尚未保存出生信息。请询问用户是否保存。",
        "birth_info_to_save": {
            "date": birth_date,
            "time": birth_time,
            "place": birth_place,
        }
    }
```

### 4.5 双数据源支持

支持从 args 或缓存读取：

```python
# ✅ 展示工具双数据源 - Zodiac 示例
@tool_handler("show_zodiac_chart")
async def execute_show_zodiac_chart(args, context):
    """
    支持两种数据来源：
    1. args 参数直接传入（优先）- LLM 从 calculate_zodiac 结果传递
    2. skill_data 缓存（备用）- 从用户数据读取
    """
    # 优先从 args 获取
    chart = {}
    if args.get("sun_sign") or args.get("sunSign"):
        chart = {
            "sun_sign": args.get("sun_sign") or args.get("sunSign"),
            # ...
        }

    # 备用从 skill_data 读取
    if not chart:
        zodiac_data = context.skill_data.get("zodiac", {})
        chart = zodiac_data.get("chart", {})
```

## 5. 前端卡片最佳实践

### 5.1 双格式支持 (关键!)

同时支持 camelCase 和 snake_case：

```typescript
// ✅ ZodiacChartCard 示例 - 类型定义
interface ZodiacChartData {
  userId?: string;
  // 支持两种格式
  birthInfo?: { date?: string; time?: string; place?: string };
  birth_info?: { date?: string; time?: string; place?: string };
  sunSign?: string;
  sun_sign?: string;
  moonSign?: string;
  moon_sign?: string;
}

// ✅ 数据兼容处理
const birthInfo = data.birthInfo || data.birth_info || {};
const sunSign = SIGN_CN[data.sunSign || data.sun_sign || ""] || data.sunSign || data.sun_sign || "";
```

### 5.2 映射表集中定义

支持多种输入格式：

```typescript
// ✅ ZodiacChartCard 示例 - 映射表
const SIGN_CN: Record<string, string> = {
  aries: "白羊座", Aries: "白羊座", 白羊座: "白羊座",
  taurus: "金牛座", Taurus: "金牛座", 金牛座: "金牛座",
  // ...
};

const PLANET_SYMBOLS: Record<string, string> = {
  太阳: "☀️", 月亮: "🌙", 水星: "☿", 金星: "♀", 火星: "♂",
  // ...
};
```

### 5.3 文件结构规范

```typescript
// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Component
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Register to CardRegistry
// ═══════════════════════════════════════════════════════════════════════════
```

### 5.4 懒加载注册

在 initCards.ts 中使用 registerLazyCard：

```typescript
// ✅ 懒加载注册 - 减少初始 bundle
registerLazyCard(CARD_TYPES.ZODIAC_CHART, () => import('./zodiac/cards/ZodiacChartCard'));
registerLazyCard(CARD_TYPES.ZODIAC_TRANSIT, () => import('./zodiac/cards/ZodiacTransitCard'));

// ❌ 不要同步导入
// import ZodiacChartCard from './zodiac/cards/ZodiacChartCard';
// registerCard(CARD_TYPES.ZODIAC_CHART, ZodiacChartCard);
```

## 6. 规则文件最佳实践

### 6.1 YAML Frontmatter

```markdown
---
id: basic-reading
name: 星盘解读
impact: CRITICAL
impactDescription: 最高频需求，用户了解占星的入口
tags: 看星盘, 我的星座, 本命盘, 完整分析
---
```

### 6.2 分析要点表

明确步骤、Query 和优先级：

```markdown
| 步骤 | 分析要点 | 检索 Query | 优先级 |
|-----|---------|-----------|-------|
| 1 | 太阳星座分析 | "太阳 {sign} 性格 核心自我" | 必须 |
| 2 | 月亮星座分析 | "月亮 {sign} 情感需求 内在" | 必须 |
| 3 | 上升星座分析 | "上升 {sign} 外在表现 第一印象" | 必须 |
| 4 | 元素分布分析 | "元素分布 {dominant_element}" | 推荐 |
```

### 6.3 输出要求

```markdown
## 输出要求

1. **必须调用**：
   - `show_zodiac_chart` 展示星盘图
   - `show_card` 展示核心洞察（不超过 4 点）

2. **内容要求**：
   - 先展示"三位一体"（太阳/月亮/上升）
   - 用通俗语言解释每个位置的含义
   - 避免过多术语，保持亲和力

3. **引导方向**：
   - 询问用户是否想深入了解某个方面
   - 引导到行运分析（"想看看最近运势吗？"）
```

## 7. 检查清单

### 后端 SKILL.md
- [ ] 包含强制工具调用规则（加粗 + ⚠️）
- [ ] 包含核心能力索引表
- [ ] 包含工具快速参考表
- [ ] 包含知识检索策略
- [ ] 包含伦理边界

### 后端 tools.yaml
- [ ] 包含 when_to_call 字段
- [ ] 分为 compute/collect/display 三类
- [ ] 参数有合理默认值

### 后端 handlers.py
- [ ] 使用数据优先级链
- [ ] 有前置检查快速失败
- [ ] 数据自包含
- [ ] 支持 _hint 通信
- [ ] 统一委托 show_card

### 前端卡片
- [ ] 支持 camelCase 和 snake_case
- [ ] 映射表集中定义
- [ ] 使用懒加载注册
- [ ] 文件结构清晰

### 规则文件
- [ ] 有 YAML frontmatter
- [ ] 有分析要点表
- [ ] 有输出要求
- [ ] 有常见问题

## 8. 参考示例

| 功能 | 参考文件 |
|------|---------|
| SKILL.md | `apps/api/skills/zodiac/SKILL.md` |
| tools.yaml | `apps/api/skills/zodiac/tools/tools.yaml` |
| handlers.py | `apps/api/skills/zodiac/tools/handlers.py` |
| rules | `apps/api/skills/zodiac/rules/basic-reading.md` |
| 前端卡片 | `apps/web/src/skills/zodiac/cards/ZodiacChartCard.tsx` |

---

# 高级模式 (从 lifecoach 提取)

> 以下模式适用于需要复杂流程、多方法论、长期陪伴的 Skill

## 9. Protocol Pattern（协议模式）

**应用场景**：需要引导用户完成结构化多步流程（如工作坊、评估、方法论执行）

### 9.1 协议执行流程

```
┌─────────────────────────────────────────────────────────────┐
│ 用户在主 Chat 表达意图                                       │
│ 触发词: "我很迷茫" / "帮我做个计划"                          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ AI 判断 → 调用 show_protocol_invitation 工具                │
│ {                                                           │
│   "protocol_id": "dankoe",                                 │
│   "title": "Dan Koe 快速重置",                             │
│   "estimated_time": "10分钟",                              │
│   "total_steps": 6                                         │
│ }                                                           │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 前端展示 ProtocolInvitationCard                             │
│ ┌──────────────────────────────────────────────┐           │
│ │ 🎯 Dan Koe 快速重置                          │           │
│ │ ⏱️ 约 10分钟    📋 6 个问题                  │           │
│ │ [开始 →]    [先聊聊]                         │           │
│ └──────────────────────────────────────────────┘           │
└────────────────────┬────────────────────────────────────────┘
                     ↓ 用户点击 [开始]
┌─────────────────────────────────────────────────────────────┐
│ 前端导航到 /protocol/{protocol_id} (专属页面)               │
│ - 沉浸式体验，不受主 Chat 干扰                              │
│ - 展示进度 (Step 1/6)                                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 协议完成 → 一次性保存数据 → 展示结果卡片                    │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 邀请卡片设计

**关键原则**：降低用户进入结构化流程的心理阻力

```tsx
// ProtocolInvitationCard 核心设计
interface ProtocolInvitationData {
  protocol_id: string;
  title: string;
  description: string;
  estimated_time: string;
  total_steps: number;
}

// 必须提供两个选择
buttons: [
  { label: "开始 →", action: "navigate_to_protocol" },  // 主要
  { label: "先聊聊", action: "continue_chat" }          // 次要
]
```

### 9.3 一次性保存原则

```python
# ✅ 正确 - 协议完成后一次性保存
async def handle_protocol_completion(protocol_id, all_answers):
    # 等所有问题完成后统一保存
    await write_skill_state("north_star", {...})
    await write_skill_state("identity", {...})
    await write_skill_state("current", {...})

    # 展示结果卡片
    return await show_result_card(...)

# ❌ 错误 - 每个问题都保存
# 原因：可能产生不完整状态，影响后续读取
```

### 9.4 中断恢复支持

```python
# 协议启动前检查
async def check_protocol_state(protocol_id):
    data = await read_skill_state()

    # 检查是否有未完成的协议
    if data.get("_protocol_in_progress"):
        completed_steps = data.get("_completed_steps", 0)
        return {
            "action": "resume",
            "from_step": completed_steps + 1
        }

    return {"action": "start_fresh"}
```

## 10. Methodology Pattern（多方法论模式）

**应用场景**：在一个 Skill 中集成多个完全不同的方法论（如 lifecoach 的 Dankoe/Covey/阳明/了凡）

### 10.1 统一四阶段框架

所有方法论遵循相同的流程框架：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    诊断      │────▶│    设计      │────▶│    执行      │────▶│    复盘      │
│ (Diagnosis)  │     │   (Design)   │     │ (Execution)  │     │  (Review)    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

### 10.2 方法论差异化实现

```python
# 每个方法论的差异化配置
METHODOLOGIES = {
    "dankoe": {
        "diagnosis": "持续不满 → 反愿景场景",
        "design": "旧身份 → 新身份",
        "execution": "游戏化行动",
        "review": "游戏进度",
        "tags": ["反愿景", "游戏化", "迷茫", "拖延"],
    },
    "covey": {
        "diagnosis": "效能诊断",
        "design": "使命宣言 + 角色目标",
        "execution": "大石头周计划",
        "review": "角色平衡评分",
        "tags": ["使命", "角色", "大石头", "时间管理"],
    },
}
```

### 10.3 统一数据映射

```python
# 所有方法论保存到相同的字段结构
COMMON_DATA_MODEL = {
    "north_star": {
        "vision_statement": str,     # 愿景/使命/志向
        "vision_scene": str,         # 场景描述
        "anti_vision_scene": str,    # 反愿景（可选）
        "principles": list,          # 核心原则
    },
    "identity": {
        "current": str,              # 当前状态
        "target": str,               # 目标状态
    },
    "goals": list,                   # 目标列表
    "current": {
        "week": {...},               # 周计划
        "daily": {...},              # 日计划
    },
    "journal": list,                 # 复盘记录
    "progress": {...},               # 进度统计
}
```

### 10.4 基于 Tags 的智能路由

```python
# 方法论自动匹配
def match_methodology(user_input: str) -> str:
    for method_id, config in METHODOLOGIES.items():
        for tag in config["tags"]:
            if tag in user_input:
                return method_id
    return None  # 需要进一步探索

# 使用示例
user_says = "我很迷茫，不知道人生方向"
matched = match_methodology(user_says)  # → "dankoe"
```

## 11. Companion Pattern（陪伴模式）

**应用场景**：长期用户保留、行为强化、周期性互动

### 11.1 多触发点设计

```python
COMPANION_TRIGGERS = {
    "daily_checkin": {
        "time": "08:00",
        "rule": "rules/daily-checkin.md",
        "persona": "future_self",
        "proactive": True,
    },
    "weekly_review": {
        "time": "周日 20:00",
        "rule": "rules/weekly-review.md",
        "proactive": True,
    },
    "monthly_review": {
        "time": "月初",
        "rule": "rules/monthly-review.md",
        "proactive": True,
    },
}
```

### 11.2 Future Self Persona

```python
# 基于用户愿景动态生成问候
def generate_future_self_greeting(vision_scene: str, days_since_checkin: int) -> str:
    # 根据愿景场景生成 Persona
    if "海边" in vision_scene:
        greeting = "早上好！我是在海边醒来的你。今天的海风很舒服..."
    elif "自由职业" in vision_scene:
        greeting = "早上好！我是时间自由的你。刚泡好咖啡..."
    else:
        greeting = f"早上好！我是{vision_timeframe}的你..."

    # 根据互动间隔调整语气
    if days_since_checkin == 1:
        greeting += "\n你昨天说要做X，进展怎么样？"
    elif days_since_checkin > 7:
        greeting = "好久不见！也许现在的你有了新的想法？"

    return greeting
```

### 11.3 选择权保护

```python
# ✅ 陪伴是"服务"，不是"要求"
COMPANION_PRINCIPLES = {
    # 不强制用户
    "always_offer_rest": True,

    # 对话选项
    "choices_on_checkin": ["聊聊", "今天休息"],
    "choices_on_reunion": ["聊聊最近", "继续之前的"],
    "choices_on_long_absence": ["重新开始", "继续之前的"],

    # 语气调整
    "never_say": ["请签到", "你断签了", "必须完成"],
    "always_say": ["早上好", "好久不见", "休息也是前进的一部分"],
}
```

### 11.4 进度追踪

```python
# 多维度进度模型
PROGRESS_MODEL = {
    "checkin": {
        "current_streak": int,       # 当前连续天数
        "longest_streak": int,       # 历史最高
        "total_checkins": int,       # 总签到次数
    },
    "action": {
        "completed_levers": list,    # 完成的每日任务
        "completed_rocks": list,     # 完成的周任务
        "completion_rate": float,    # 完成率
    },
    "insight": {
        "journal_entries": list,     # 复盘记录
        "patterns_discovered": list, # 发现的模式
    },
}
```

## 12. State Management Pattern（深度合并状态管理）

**应用场景**：管理复杂的多维度用户状态

### 12.1 读写分离

```python
# 数据工具设计
DATA_TOOLS = {
    "read_skill_state": "读取指定 sections",
    "write_skill_state": "写入指定 section（深度合并）",
    "add_journal_entry": "添加日志记录",
    "update_progress": "更新进度统计",
}
```

### 12.2 深度合并实现

```python
def deep_merge(base: dict, update: dict) -> dict:
    """递归合并字典，保留 base 中的其他字段"""
    result = base.copy()
    for key, value in update.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        elif value is not None:
            result[key] = value
    return result

# 使用示例
existing = {"north_star": {"vision": "A"}, "identity": {"current": "B"}}
update = {"north_star": {"anti_vision": "C"}}
result = deep_merge(existing, update)
# → {"north_star": {"vision": "A", "anti_vision": "C"}, "identity": {"current": "B"}}
```

### 12.3 自动计算字段

```python
# 保存时自动计算派生字段
async def write_skill_state(section: str, data: dict):
    existing = await read_skill_state()
    existing[section] = deep_merge(existing.get(section, {}), data)

    # 自动计算
    if section == "goals":
        existing["_focus_heatmap"] = calculate_focus(existing["goals"])
    if "roles" in existing.get(section, {}):
        existing["balance_score"] = calculate_balance_score(existing["goals"])

    # 添加元数据
    existing["_last_updated"] = now()
    existing["_last_section"] = section

    await save(existing)
```

### 12.4 幂等性保证

```python
# 确保重复调用结果一致
async def add_journal_entry(entry_type: str, content: str):
    entries = await read_skill_state(["journal"])

    # 检查是否已存在相同记录
    today = date.today().isoformat()
    existing = [e for e in entries if e["date"] == today and e["type"] == entry_type]

    if existing:
        return {"status": "already_done", "message": "今天已经记录过了"}

    # 添加新记录
    new_entry = {
        "id": str(uuid4()),
        "date": today,
        "type": entry_type,
        "content": content,
    }
    entries.append(new_entry)

    await write_skill_state("journal", entries)
    return {"status": "success"}
```

---

## 13. 高级模式检查清单

### Protocol Pattern
- [ ] 有 `show_protocol_invitation` 工具
- [ ] 邀请卡片提供"先聊聊"选项
- [ ] 协议在专属页面 `/protocol/{id}` 执行
- [ ] 一次性保存，避免不完整状态
- [ ] 支持中断恢复

### Methodology Pattern
- [ ] 统一四阶段框架（诊断→设计→执行→复盘）
- [ ] 每个方法论有独立 MD 文件和卡片
- [ ] 数据映射到通用字段
- [ ] 基于 tags 的智能路由

### Companion Pattern
- [ ] 多触发点（每日/每周/每月）
- [ ] Future Self Persona 动态生成
- [ ] 始终提供"休息"选项
- [ ] 进度追踪（连续天数、完成率）

### State Management
- [ ] 读写分离的数据工具
- [ ] 深度合并实现
- [ ] 自动计算派生字段
- [ ] 幂等性保证

## 14. 完整参考示例

| 模式 | 参考文件 |
|------|---------|
| Protocol | `apps/api/skills/lifecoach/tools/handlers.py` (show_protocol_invitation) |
| Methodology | `apps/api/skills/lifecoach/rules/dankoe.md`, `covey.md` |
| Companion | `apps/api/skills/lifecoach/rules/daily-checkin.md` |
| State Management | `apps/api/skills/lifecoach/tools/handlers.py` (read/write_lifecoach_state) |
| 前端卡片 | `apps/web/src/skills/lifecoach/cards/DankoeCard.tsx` |
