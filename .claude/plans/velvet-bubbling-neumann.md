# v3 show_card 统一架构实现计划

## 目标

将 Bazi Skill 展示工具迁移到 v3 统一 show_card 架构，使用委托模式。

## 现状分析

### 已完成的基础设施

| 组件 | 状态 | 文件 |
|------|------|------|
| CardService | ✅ 完整 | `apps/api/skills/core/services/card.py` |
| show_card handler | ✅ 完整 | `apps/api/skills/core/tools/handlers.py` L521-548 |
| 前端 ToolCardRenderer | ✅ 兼容 | `apps/web/src/components/chat/ChatMessage.tsx` |
| ShowCard 组件 | ✅ 支持 custom | `apps/web/src/skills/shared/ShowCard.tsx` |
| VibeID 委托模式 | ✅ 参考实现 | `apps/api/skills/vibe_id/tools/handlers.py` |

### 需要迁移的工具

| 工具 | 当前 cardType | 目标模式 |
|------|--------------|---------|
| show_bazi_chart | bazi_chart | custom + componentId |
| show_bazi_fortune | bazi_fortune | custom + componentId |
| show_bazi_kline | bazi_kline | custom + componentId |

## 实现步骤

### Step 1: 迁移 show_bazi_chart

**文件**: `apps/api/skills/bazi/tools/handlers.py`

**修改 L170-234**:

```python
@tool_handler("show_bazi_chart")
async def execute_show_bazi_chart(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """展示八字命盘图 - V7 委托模式"""
    from services.agent.tool_registry import ToolRegistry

    profile = context.profile or {}
    skill_data = context.skill_data or {}
    birth_info = profile.get("birth_info", {})

    # 检查出生信息
    if not birth_info.get("date"):
        return {
            "status": "error",
            "error": "请先提供出生信息才能查看命盘",
            "need_info": "birth"
        }

    # 获取命盘数据
    bazi_data = skill_data.get("bazi", {})
    chart = bazi_data.get("chart", {})

    if not chart:
        from skills.bazi.services import calculate_bazi
        try:
            chart = calculate_bazi(
                birth_info.get("date"),
                birth_info.get("time", "12:00"),
                birth_info.get("gender", "unknown")
            )
        except Exception as e:
            return {"status": "error", "error": f"命盘计算失败: {str(e)}"}

    # 构建卡片数据
    card_data = {
        "userId": context.user_id,
        "birthInfo": {
            "date": birth_info.get("date"),
            "time": birth_info.get("time", "12:00"),
            "gender": birth_info.get("gender", "unknown"),
        },
        "fourPillars": chart.get("four_pillars", {}),
        "dayMaster": chart.get("day_master", {}),
        "fiveElements": chart.get("five_elements", {}),
        "tenGods": chart.get("ten_gods", []),
        "pattern": chart.get("pattern", {}),
    }

    # 委托给 show_card
    return await ToolRegistry.execute(
        "show_card",
        {
            "card_type": "custom",
            "data_source": {"type": "inline", "data": card_data},
            "options": {"componentId": "bazi_chart"}
        },
        context
    )
```

### Step 2: 迁移 show_bazi_fortune

**修改 L237-278**:

```python
@tool_handler("show_bazi_fortune")
async def execute_show_bazi_fortune(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """展示大运流年分析 - V7 委托模式"""
    from services.agent.tool_registry import ToolRegistry

    computer = get_bazi_computer()
    profile = context.profile or {}
    skill_data = context.skill_data or {}
    birth_info = profile.get("birth_info", {})

    if not birth_info.get("date"):
        return {
            "status": "error",
            "error": "请先提供出生信息才能分析运势",
            "need_info": "birth"
        }

    year = args.get("year") or datetime.now().year

    try:
        full_profile = {"birth_info": birth_info, "skill_data": skill_data}
        kline_data = await computer.generate_kline_data(full_profile)
        annual = await computer.calculate_annual_fortune(full_profile, year)

        card_data = {
            "userId": context.user_id,
            "year": year,
            "cycles": kline_data.get("phases", []),
            "annual": annual,
        }

        return await ToolRegistry.execute(
            "show_card",
            {
                "card_type": "custom",
                "data_source": {"type": "inline", "data": card_data},
                "options": {"componentId": "bazi_fortune"}
            },
            context
        )
    except Exception as e:
        return {"status": "error", "error": f"运势分析失败: {str(e)}"}
```

### Step 3: 迁移 show_bazi_kline

**修改 L281-325**:

```python
@tool_handler("show_bazi_kline")
async def execute_show_bazi_kline(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """展示运势 K 线图 - V7 委托模式"""
    from services.agent.tool_registry import ToolRegistry

    computer = get_bazi_computer()
    start_year = args.get("start_year") or args.get("startYear")
    end_year = args.get("end_year") or args.get("endYear")

    profile = context.profile or {}
    skill_data = context.skill_data or {}
    birth_info = profile.get("birth_info", {})

    if not birth_info.get("date"):
        return {
            "status": "error",
            "error": "请先提供出生信息才能生成运势图",
            "need_info": "birth"
        }

    try:
        year_range = (int(start_year), int(end_year)) if start_year and end_year else None
        full_profile = {"birth_info": birth_info, "skill_data": skill_data}
        kline_data = await computer.generate_kline_data(full_profile, year_range=year_range)

        return await ToolRegistry.execute(
            "show_card",
            {
                "card_type": "custom",
                "data_source": {"type": "inline", "data": kline_data},
                "options": {"componentId": "bazi_kline"}
            },
            context
        )
    except Exception as e:
        return {"status": "error", "error": f"运势图生成失败: {str(e)}"}
```

### Step 4: 验证前端兼容性

**文件**: `apps/web/src/skills/shared/ShowCard.tsx`

验证 custom 分支正确传递 props:
```typescript
case 'custom':
  const customComponentId = componentId || options.componentId;
  const CustomComponent = getCard(customComponentId);
  return <CustomComponent data={data} options={options} />;
```

**文件**: `apps/web/src/skills/bazi/cards/BaziChartCard.tsx`

验证组件接收 `data` prop（当前已兼容）。

## 文件修改清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `apps/api/skills/bazi/tools/handlers.py` | 修改 | 迁移 3 个展示工具到委托模式 |

## 验证方法

1. **单元测试**:
```bash
cd apps/api && python -m pytest tests/test_tool_calling.py -v
```

2. **E2E 测试**:
```bash
cd apps/api && python scripts/test_core_agent.py
# 输入: "看看我的命盘"
# 预期: 返回 cardType: "custom", componentId: "bazi_chart"
```

3. **前端验证**:
- 启动开发服务器
- 确保用户有 birth_info
- 输入 "看看我的命盘"
- 验证 BaziChartCard 正确渲染

## 未解决问题

1. **Zodiac/Tarot/Career Skill**: 后续按需迁移
2. **tools.yaml 更新**: 可选添加 `delegates_to` 声明
