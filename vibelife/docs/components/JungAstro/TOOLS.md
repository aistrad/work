# JungAstro 工具定义

## tools.yaml

```yaml
version: "1.0"
skill_id: jungastro

# ═══════════════════════════════════════════════════════════════════════════════
# 收集型工具
# ═══════════════════════════════════════════════════════════════════════════════
collect:
  - name: collect_birth_info
    description: |
      收集用户的出生信息以进行荣格心理占星分析。
      当用户想要进行心理占星分析但尚未提供出生信息时调用。
    card_type: birth_form
    card_props:
      title: "心理占星分析"
      subtitle: "请提供您的出生信息"
      form_fields:
        - name: birth_date
          type: date
          required: true
          label: 出生日期
        - name: birth_time
          type: time
          required: true
          label: 出生时间
          hint: 出生时间影响上升星座和宫位，建议查询出生证明
        - name: birth_location
          type: location
          required: true
          label: 出生地点
    parameters:
      - name: question
        type: string
        required: false
        description: 用户的问题或困惑
    when_to_call: 用户想进行心理占星分析但没有提供出生信息时

# ═══════════════════════════════════════════════════════════════════════════════
# 展示型工具
# ═══════════════════════════════════════════════════════════════════════════════
display:
  - name: show_psychological_portrait
    description: |
      展示用户的心理画像分析，包括：
      - 核心自我 (太阳): Ego 意识中心
      - 情感需求 (月亮): Personal Unconscious
      - 人格面具 (上升): Persona
      - 心理功能分布: 元素/模式分析
    card_type: jungastro_portrait
    when_to_call: |
      - 用户说"分析我的心理"
      - 用户说"我的深层性格"
      - 用户想了解心理结构
      - 用户说"心理画像"
    parameters:
      - name: focus
        type: string
        required: false
        description: |
          分析焦点:
          - ego: 核心自我 (太阳)
          - emotions: 情感需求 (月亮)
          - persona: 人格面具 (上升)
          - functions: 心理功能分布
          - full: 完整分析 (默认)
        default: full

  - name: show_shadow_analysis
    description: |
      展示阴影分析，包括：
      - 困难相位识别 (刑相、对冲)
      - 冥王星配置分析
      - 12宫内容分析
      - 内在冲突动力学
      - 整合建议
    card_type: jungastro_shadow
    when_to_call: |
      - 用户问"我的阴影是什么"
      - 用户问"内在冲突"
      - 用户问困难相位的意义
      - 用户提到冥王星
      - 用户问"为什么我总是..."
    parameters:
      - name: aspect
        type: string
        required: false
        description: 特定相位 (如 "sun_square_saturn")
      - name: planet
        type: string
        required: false
        description: 特定行星 (如 "pluto")

  - name: show_individuation_path
    description: |
      展示个体化路径分析，包括：
      - 当前人生阶段
      - 土星周期分析
      - 外行星行运
      - 成长方向建议
    card_type: jungastro_individuation
    when_to_call: |
      - 用户问"我的成长方向"
      - 用户问"土星回归"
      - 用户问"人生阶段"
      - 用户问"中年危机"
      - 用户问"我现在应该做什么"
    parameters:
      - name: cycle
        type: string
        required: false
        description: |
          特定周期:
          - saturn_return: 土星回归 (约29岁、58岁)
          - uranus_opposition: 天王星对冲 (约42岁)
          - chiron_return: 凯龙回归 (约50岁)
          - jupiter_return: 木星回归 (约12年周期)
          - current: 当前阶段 (默认)
        default: current

  - name: show_psychological_functions
    description: |
      展示心理功能分布图，包括：
      - 元素分布 (火/土/风/水)
      - 模式分布 (开创/固定/变动)
      - 行星能量分析
      - 主导功能与劣势功能
    card_type: jungastro_functions
    when_to_call: |
      - 用户问"我的心理功能"
      - 用户问"元素分布"
      - 用户想了解能量类型
      - 用户问"我是什么类型"
    parameters:
      - name: view
        type: string
        required: false
        description: |
          视图类型:
          - elements: 元素分布
          - modalities: 模式分布
          - planets: 行星能量
          - full: 完整分析 (默认)
        default: full

  - name: show_relationship_dynamics
    description: |
      展示关系动力学分析，包括：
      - 7宫分析 (关系模式)
      - 金星/火星配置
      - 投射模式识别
      - 合盘心理分析 (如有对方信息)
    card_type: jungastro_relationship
    when_to_call: |
      - 用户问"我的关系模式"
      - 用户问"为什么我总是吸引..."
      - 用户问"我和TA的心理动力"
      - 用户问"投射"
    parameters:
      - name: partner_birth_date
        type: string
        required: false
        description: 对方出生日期 (用于合盘)
      - name: partner_birth_time
        type: string
        required: false
        description: 对方出生时间
      - name: partner_birth_location
        type: string
        required: false
        description: 对方出生地点
```

---

## handlers.py 结构

```python
"""
JungAstro Skill 工具执行器

复用 zodiac skill 的计算服务，添加荣格心理学解读层。
"""

from typing import Dict, Any, Optional
from ..services.interpreter import JungianInterpreter
from ...zodiac.services.calculator import ZodiacCalculator

# 复用 zodiac 计算器
calculator = ZodiacCalculator()

# 荣格解读器
interpreter = JungianInterpreter()


async def handle_show_psychological_portrait(
    user_id: str,
    focus: str = "full",
    **kwargs
) -> Dict[str, Any]:
    """
    展示心理画像

    Returns:
        {
            "card_type": "jungastro_portrait",
            "data": {
                "ego": {...},           # 太阳分析
                "unconscious": {...},   # 月亮分析
                "persona": {...},       # 上升分析
                "functions": {...},     # 功能分布
                "synthesis": "..."      # 综合解读
            }
        }
    """
    # 1. 获取用户星盘数据
    chart = await calculator.get_natal_chart(user_id)

    # 2. 荣格心理解读
    portrait = interpreter.analyze_psychological_portrait(chart, focus)

    return {
        "card_type": "jungastro_portrait",
        "data": portrait
    }


async def handle_show_shadow_analysis(
    user_id: str,
    aspect: Optional[str] = None,
    planet: Optional[str] = None,
    **kwargs
) -> Dict[str, Any]:
    """
    展示阴影分析

    Returns:
        {
            "card_type": "jungastro_shadow",
            "data": {
                "difficult_aspects": [...],  # 困难相位列表
                "pluto_analysis": {...},     # 冥王星配置
                "twelfth_house": {...},      # 12宫分析
                "shadow_patterns": [...],    # 阴影模式
                "integration_path": "..."    # 整合建议
            }
        }
    """
    chart = await calculator.get_natal_chart(user_id)
    shadow = interpreter.analyze_shadow(chart, aspect, planet)

    return {
        "card_type": "jungastro_shadow",
        "data": shadow
    }


async def handle_show_individuation_path(
    user_id: str,
    cycle: str = "current",
    **kwargs
) -> Dict[str, Any]:
    """
    展示个体化路径

    Returns:
        {
            "card_type": "jungastro_individuation",
            "data": {
                "current_stage": {...},      # 当前阶段
                "saturn_cycle": {...},       # 土星周期
                "outer_planet_transits": [...],  # 外行星行运
                "growth_direction": "...",   # 成长方向
                "integration_tasks": [...]   # 整合任务
            }
        }
    """
    chart = await calculator.get_natal_chart(user_id)
    current_transits = await calculator.get_current_transits()

    individuation = interpreter.analyze_individuation(
        chart, current_transits, cycle
    )

    return {
        "card_type": "jungastro_individuation",
        "data": individuation
    }


async def handle_show_psychological_functions(
    user_id: str,
    view: str = "full",
    **kwargs
) -> Dict[str, Any]:
    """
    展示心理功能分布

    Returns:
        {
            "card_type": "jungastro_functions",
            "data": {
                "elements": {
                    "fire": 3, "earth": 2, "air": 4, "water": 1
                },
                "modalities": {
                    "cardinal": 2, "fixed": 5, "mutable": 3
                },
                "dominant_function": "thinking",
                "inferior_function": "feeling",
                "balance_suggestions": [...]
            }
        }
    """
    chart = await calculator.get_natal_chart(user_id)
    functions = interpreter.analyze_psychological_functions(chart, view)

    return {
        "card_type": "jungastro_functions",
        "data": functions
    }


async def handle_show_relationship_dynamics(
    user_id: str,
    partner_birth_date: Optional[str] = None,
    partner_birth_time: Optional[str] = None,
    partner_birth_location: Optional[str] = None,
    **kwargs
) -> Dict[str, Any]:
    """
    展示关系动力学

    Returns:
        {
            "card_type": "jungastro_relationship",
            "data": {
                "seventh_house": {...},      # 7宫分析
                "venus_mars": {...},         # 金星火星配置
                "projection_patterns": [...], # 投射模式
                "synastry": {...}            # 合盘分析 (如有)
            }
        }
    """
    chart = await calculator.get_natal_chart(user_id)

    partner_chart = None
    if partner_birth_date:
        partner_chart = calculator.calculate_chart(
            partner_birth_date,
            partner_birth_time,
            partner_birth_location
        )

    dynamics = interpreter.analyze_relationship_dynamics(
        chart, partner_chart
    )

    return {
        "card_type": "jungastro_relationship",
        "data": dynamics
    }


# 工具注册表
TOOL_HANDLERS = {
    "show_psychological_portrait": handle_show_psychological_portrait,
    "show_shadow_analysis": handle_show_shadow_analysis,
    "show_individuation_path": handle_show_individuation_path,
    "show_psychological_functions": handle_show_psychological_functions,
    "show_relationship_dynamics": handle_show_relationship_dynamics,
}
```

---

## 工具调用示例

### 场景 1: 用户想了解深层心理

```
用户: "帮我分析一下我的深层心理"

Agent 调用:
show_psychological_portrait(focus="full")

返回卡片: jungastro_portrait
```

### 场景 2: 用户问内在冲突

```
用户: "为什么我总是自我怀疑？"

Agent 调用:
1. search_db(query="自我怀疑 土星 太阳 心理")
2. show_shadow_analysis(aspect="sun_square_saturn")

返回卡片: jungastro_shadow
```

### 场景 3: 用户问成长方向

```
用户: "我快30岁了，感觉很迷茫"

Agent 调用:
show_individuation_path(cycle="saturn_return")

返回卡片: jungastro_individuation
```

### 场景 4: 用户问关系模式

```
用户: "为什么我总是吸引不合适的人？"

Agent 调用:
1. search_db(query="7宫 关系模式 投射")
2. show_relationship_dynamics()

返回卡片: jungastro_relationship
```
