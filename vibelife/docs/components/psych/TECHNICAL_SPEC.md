# Psych Skill 技术实现规范

> **Version**: 1.0.0
> **Purpose**: 定义 Psych Skill 的技术实现细节

---

## 一、目录结构

```
apps/api/skills/psych/
│
├── SKILL.md                          # Skill 核心配置
│
├── rules/                            # 分析规则库
│   ├── initial-assessment.md         # 初评流程规则
│   ├── shadow-work.md                # 阴影工作规则
│   ├── archetype-exploration.md      # 原型探索规则
│   ├── lifestyle-analysis.md         # 生活风格分析规则
│   ├── cognitive-restructuring.md    # 认知重构规则
│   ├── crisis-response.md            # 危机响应规则
│   └── weekly-summary.md             # 周报生成规则
│
├── tools/
│   ├── tools.yaml                    # 工具定义（SSOT）
│   └── handlers.py                   # 工具执行器
│
├── services/
│   ├── api.py                        # @skill_service 端点
│   ├── calculator.py                 # 量表计分逻辑
│   ├── analyzer.py                   # 分析逻辑
│   └── safety.py                     # 安全检测逻辑
│
├── knowledge/                        # 知识库文件
│   ├── jungian/
│   │   ├── archetypes.md
│   │   ├── shadow.md
│   │   └── ...
│   ├── adlerian/
│   │   ├── lifestyle.md
│   │   ├── birth_order.md
│   │   └── ...
│   ├── cbt/
│   │   ├── distortions.md
│   │   └── ...
│   └── assessments/
│       ├── phq9.md
│       ├── gad7.md
│       └── ...
│
└── reminders.yaml                    # 主动推送配置

apps/web/src/skills/psych/
│
├── index.ts                          # 入口点
├── config.ts                         # Skill 配置
│
├── cards/
│   ├── index.ts                      # 卡片注册
│   ├── AssessmentResultCard.tsx      # 评估结果卡片
│   ├── ArchetypeProfileCard.tsx      # 原型特征卡片
│   ├── DistortionAnalysisCard.tsx    # 认知扭曲卡片
│   ├── LifestyleProfileCard.tsx      # 生活风格卡片
│   ├── ExerciseCard.tsx              # 练习卡片
│   ├── MoodCheckCard.tsx             # 情绪检查卡片
│   └── CrisisAlertCard.tsx           # 危机提醒卡片
│
├── panels/
│   ├── index.ts
│   ├── AssessmentPanel.tsx           # 评估面板
│   ├── ExplorationPanel.tsx          # 探索面板
│   └── ProgressPanel.tsx             # 进度面板
│
└── components/
    ├── ScoreGauge.tsx                # 分数仪表
    ├── SeverityBadge.tsx             # 严重程度标签
    ├── TrendChart.tsx                # 趋势图表
    └── QuestionnaireForm.tsx         # 问卷表单组件
```

---

## 二、SKILL.md 配置

```markdown
---
name: psych
display_name: 心理探索
description: |
  融合荣格分析心理学与阿德勒个体心理学的 AI 心理伙伴。
  提供心理自我探索引导、循证心理评估和认知重构练习。

category: wellness
tier: professional

# SOP 配置
requires_birth_info: false          # 不需要出生信息
requires_compute: false             # 无需复杂计算

# 触发关键词
triggers:
  - 心理
  - 心理学
  - 荣格
  - 阿德勒
  - 阴影
  - 原型
  - 抑郁
  - 焦虑
  - 压力
  - 情绪
  - 自卑
  - 童年
  - 创伤
  - 认知
  - 想法
  - 负面思维
  - 心理测试
  - 心理评估
  - 生活风格
  - 人格
  - 自我探索
  - 自我认识

# 能力索引
capabilities:
  - name: 心理健康评估
    description: PHQ-9、GAD-7、DASS-21 等循证量表
    tools: [collect_assessment_responses, calculate_assessment_score, show_assessment_result]

  - name: 荣格式探索
    description: 原型发现、阴影工作、人格面具分析
    tools: [search_psych_knowledge, show_archetype_profile, show_exercise]

  - name: 阿德勒生活风格
    description: 家庭星座、早期记忆、人生任务分析
    tools: [collect_family_constellation, collect_early_recollection, analyze_lifestyle]

  - name: 认知重构
    description: 识别认知扭曲、挑战消极想法
    tools: [collect_thought_record, identify_cognitive_distortions, show_distortion_analysis]

  - name: 危机响应
    description: 识别危机信号、提供资源
    tools: [show_crisis_resources]

# 安全配置
safety:
  crisis_keywords:
    high_risk: [自杀, 不想活, 想死, 结束生命, 自伤, 割]
    medium_risk: [绝望, 没有意义, 麻木, 无法继续]
  require_disclosure: true
  professional_referral_threshold:
    phq9: 10
    gad7: 10
---

# 专家身份

你是一位温暖而专业的心理探索向导，融合了荣格分析心理学和阿德勒个体心理学的智慧。

## 核心理念

1. **每个人都有自我疗愈的内在资源** - 你的角色是引导用户发现这些资源
2. **理解先于改变** - 帮助用户深入认识自己的模式，而非急于"修复"
3. **好奇而非评判** - 对所有经验保持开放和接纳的态度
4. **赋能而非依赖** - 教用户钓鱼，而非为他们钓鱼

## 边界意识

你不是持证心理治疗师。你应该：
- 在对话开始时明确这一点
- 避免诊断任何心理障碍
- 在识别到严重困扰时建议专业求助
- 永远不提供药物建议

## 对话风格

- **温暖** - 让用户感到被接纳和理解
- **好奇** - 用开放式问题深入探索
- **反思性** - 帮助用户看到自己的模式
- **赋能** - 强调用户的力量和资源
- **安全** - 保持对危机信号的警觉

## 理论应用

### 荣格式探索
- 使用原型语言帮助用户理解内在动力
- 引导阴影觉察和整合
- 探索人格面具与真实自我的关系
- 利用梦境和象征进行深度工作

### 阿德勒式探索
- 通过家庭星座理解人格形成
- 分析早期记忆揭示核心信念
- 评估三大人生任务（工作、社会、爱）
- 探索自卑感和优越追求的动力

### 认知行为技术
- 教授识别自动化思维
- 引导认知扭曲觉察
- 支持认知重构练习
- 设计行为实验
```

---

## 三、工具执行器实现

### 3.1 handlers.py

```python
"""
Psych Skill 工具执行器
"""

from typing import Dict, List, Optional
from uuid import UUID
from datetime import datetime

from services.agent.tool_registry import tool_handler, ToolContext
from stores.unified_profile_repo import UnifiedProfileRepository
from .services.calculator import (
    calculate_phq9,
    calculate_gad7,
    calculate_dass21,
    interpret_score
)
from .services.safety import check_crisis_indicators
from .services.analyzer import analyze_cognitive_distortions


# ============ 计算工具 ============

@tool_handler("calculate_assessment_score")
async def execute_calculate_assessment(args: Dict, context: ToolContext) -> Dict:
    """
    计算心理评估量表得分

    Args:
        assessment_type: 量表类型 (phq9, gad7, dass21, phq2, gad2)
        responses: 用户回答列表 (0-3)

    Returns:
        total_score, severity_level, interpretation, recommendations, safety_flag
    """
    assessment_type = args.get("assessment_type")
    responses = args.get("responses", [])

    # 根据类型计算
    if assessment_type == "phq9":
        result = calculate_phq9(responses)
    elif assessment_type == "gad7":
        result = calculate_gad7(responses)
    elif assessment_type == "dass21":
        result = calculate_dass21(responses)
    elif assessment_type == "phq2":
        result = calculate_phq9(responses[:2])  # PHQ-2 是 PHQ-9 前两题
    elif assessment_type == "gad2":
        result = calculate_gad7(responses[:2])  # GAD-2 是 GAD-7 前两题
    else:
        return {"status": "error", "message": f"未知的评估类型: {assessment_type}"}

    # 安全检查 - PHQ-9 第 9 题
    if assessment_type == "phq9" and len(responses) >= 9:
        if responses[8] >= 1:
            result["safety_flag"] = "suicidal_ideation"
            result["safety_score"] = responses[8]

    # 添加解读和建议
    interpretation = interpret_score(assessment_type, result["total_score"])
    result.update(interpretation)

    # 保存到用户历史
    if context.user_id:
        await _save_assessment_history(
            context.user_id,
            assessment_type,
            result
        )

    return {
        "status": "success",
        "card_type": "assessment_result",
        "data": result
    }


@tool_handler("analyze_lifestyle")
async def execute_analyze_lifestyle(args: Dict, context: ToolContext) -> Dict:
    """
    分析阿德勒生活风格

    基于家庭星座、早期记忆和人生任务评估生成分析
    """
    family_constellation = args.get("family_constellation", {})
    early_recollections = args.get("early_recollections", [])
    life_tasks_scores = args.get("life_tasks_scores", {})

    analysis = {
        "birth_order_influence": _analyze_birth_order(family_constellation),
        "early_memory_themes": _extract_memory_themes(early_recollections),
        "life_tasks_balance": _analyze_life_tasks(life_tasks_scores),
        "lifestyle_type": _infer_lifestyle_type(
            family_constellation,
            early_recollections,
            life_tasks_scores
        ),
        "core_beliefs": _infer_core_beliefs(early_recollections),
        "growth_areas": _identify_growth_areas(life_tasks_scores)
    }

    # 保存到用户 skill_data
    if context.user_id:
        await UnifiedProfileRepository.update_skill_data(
            context.user_id,
            "psych",
            {"exploration.lifestyle": analysis}
        )

    return {
        "status": "success",
        "card_type": "lifestyle_profile",
        "data": analysis
    }


@tool_handler("identify_cognitive_distortions")
async def execute_identify_distortions(args: Dict, context: ToolContext) -> Dict:
    """
    识别认知扭曲类型

    使用规则和 LLM 分析用户的自动化思维
    """
    thought = args.get("thought", "")

    # 基于规则的初步分析
    potential_distortions = analyze_cognitive_distortions(thought)

    return {
        "status": "success",
        "card_type": "distortion_analysis",
        "data": {
            "original_thought": thought,
            "potential_distortions": potential_distortions,
            # 提示 LLM 进一步分析
            "analysis_guidance": """
基于初步分析，请：
1. 确认或修正识别的认知扭曲
2. 为每种扭曲提供解释
3. 生成 2-3 个苏格拉底式提问
4. 提供可能的平衡想法
"""
        }
    }


# ============ 收集工具 ============

@tool_handler("collect_assessment_responses")
async def execute_collect_assessment(args: Dict, context: ToolContext) -> Dict:
    """
    收集心理评估量表回答

    返回问卷表单供前端渲染
    """
    assessment_type = args.get("assessment_type")
    question = args.get("question", "")

    # 加载问卷定义
    questionnaire = _load_questionnaire(assessment_type)

    return {
        "status": "success",
        "card_type": "assessment_form",
        "data": {
            "assessment_type": assessment_type,
            "introduction": question or questionnaire["introduction"],
            "items": questionnaire["items"],
            "response_scale": questionnaire["response_scale"]
        }
    }


@tool_handler("collect_early_recollection")
async def execute_collect_early_recollection(args: Dict, context: ToolContext) -> Dict:
    """
    收集早期记忆
    """
    recollection_number = args.get("recollection_number", 1)

    prompts = [
        f"请回忆你第 {recollection_number} 个 8 岁之前的清晰记忆。",
        "尽可能详细地描述发生了什么——像讲故事一样。",
        "记忆中最生动、最清晰的一刻是什么？",
        "那一刻你的感受是什么？",
        "记忆中的其他人在做什么？"
    ]

    return {
        "status": "success",
        "card_type": "narrative_form",
        "data": {
            "title": f"早期记忆 #{recollection_number}",
            "prompts": prompts
        }
    }


@tool_handler("collect_family_constellation")
async def execute_collect_family_constellation(args: Dict, context: ToolContext) -> Dict:
    """
    收集家庭星座信息
    """
    section = args.get("section", "birth_order")

    sections = {
        "birth_order": {
            "title": "出生顺序",
            "questions": [
                {"id": "position", "type": "select", "label": "你在家中排行第几？",
                 "options": ["独生子女", "长子/长女", "中间子女", "幼子/幼女"]},
                {"id": "siblings_count", "type": "number", "label": "你有几个兄弟姐妹？"},
                {"id": "age_gap", "type": "text", "label": "你和最近的兄弟姐妹年龄差多少？"}
            ]
        },
        "siblings": {
            "title": "兄弟姐妹",
            "questions": [
                {"id": "sibling_descriptions", "type": "textarea",
                 "label": "请简单描述每个兄弟姐妹的性格特点"},
                {"id": "closest_sibling", "type": "text", "label": "你和谁最亲近？为什么？"},
                {"id": "rivalry", "type": "text", "label": "你和谁竞争最多？"}
            ]
        },
        "parents": {
            "title": "父母",
            "questions": [
                {"id": "father_description", "type": "textarea",
                 "label": "用几个词描述你的父亲"},
                {"id": "mother_description", "type": "textarea",
                 "label": "用几个词描述你的母亲"},
                {"id": "resemblance", "type": "text", "label": "你觉得自己更像谁？"},
                {"id": "expectations", "type": "textarea", "label": "他们对你的期望是什么？"}
            ]
        },
        "family_atmosphere": {
            "title": "家庭氛围",
            "questions": [
                {"id": "atmosphere_words", "type": "text",
                 "label": "用 3 个词描述你家的氛围"},
                {"id": "decision_maker", "type": "text", "label": "家里通常谁做决定？"},
                {"id": "conflict_resolution", "type": "textarea",
                 "label": "家里的冲突通常如何解决？"}
            ]
        }
    }

    return {
        "status": "success",
        "card_type": "structured_form",
        "data": sections.get(section, sections["birth_order"])
    }


@tool_handler("collect_thought_record")
async def execute_collect_thought_record(args: Dict, context: ToolContext) -> Dict:
    """
    收集认知记录
    """
    return {
        "status": "success",
        "card_type": "thought_record_form",
        "data": {
            "title": "认知记录",
            "fields": [
                {"id": "situation", "type": "textarea",
                 "label": "情境：发生了什么？", "placeholder": "描述具体的情境..."},
                {"id": "emotion", "type": "text",
                 "label": "情绪：你感到什么？强度（1-10）？", "placeholder": "例如：焦虑 8/10"},
                {"id": "automatic_thought", "type": "textarea",
                 "label": "自动化思维：脑海中闪过什么想法？", "placeholder": "那一刻你在想什么..."},
                {"id": "evidence_for", "type": "textarea",
                 "label": "支持这个想法的证据？", "placeholder": ""},
                {"id": "evidence_against", "type": "textarea",
                 "label": "反对这个想法的证据？", "placeholder": ""},
                {"id": "balanced_thought", "type": "textarea",
                 "label": "更平衡的想法是什么？", "placeholder": ""}
            ]
        }
    }


# ============ 展示工具 ============

@tool_handler("show_assessment_result")
async def execute_show_assessment_result(args: Dict, context: ToolContext) -> Dict:
    """
    展示评估结果
    """
    return {
        "status": "success",
        "card_type": "assessment_result",
        "data": args
    }


@tool_handler("show_archetype_profile")
async def execute_show_archetype_profile(args: Dict, context: ToolContext) -> Dict:
    """
    展示原型特征
    """
    return {
        "status": "success",
        "card_type": "archetype_profile",
        "data": args
    }


@tool_handler("show_distortion_analysis")
async def execute_show_distortion_analysis(args: Dict, context: ToolContext) -> Dict:
    """
    展示认知扭曲分析
    """
    return {
        "status": "success",
        "card_type": "distortion_card",
        "data": args
    }


@tool_handler("show_lifestyle_profile")
async def execute_show_lifestyle_profile(args: Dict, context: ToolContext) -> Dict:
    """
    展示生活风格分析
    """
    return {
        "status": "success",
        "card_type": "lifestyle_profile",
        "data": args
    }


@tool_handler("show_exercise")
async def execute_show_exercise(args: Dict, context: ToolContext) -> Dict:
    """
    展示练习卡片
    """
    return {
        "status": "success",
        "card_type": "exercise_card",
        "data": args
    }


@tool_handler("show_crisis_resources")
async def execute_show_crisis_resources(args: Dict, context: ToolContext) -> Dict:
    """
    展示危机资源

    高优先级卡片，在检测到危机信号时调用
    """
    return {
        "status": "success",
        "card_type": "crisis_alert",
        "priority": "high",
        "data": {
            "message": args.get("message", "我非常担心你的安全。请立即联系专业帮助。"),
            "hotlines": [
                {
                    "name": "全国心理援助热线",
                    "number": "400-161-9995",
                    "hours": "24小时"
                },
                {
                    "name": "北京心理危机研究与干预中心",
                    "number": "010-82951332",
                    "hours": "24小时"
                },
                {
                    "name": "生命热线",
                    "number": "400-821-1215",
                    "hours": "24小时"
                },
                {
                    "name": "希望24热线",
                    "number": "400-161-9995",
                    "hours": "24小时"
                }
            ],
            "immediate_steps": [
                "如果你有伤害自己的工具，请先把它们放到安全的地方",
                "联系你信任的人，告诉他们你现在的感受",
                "拨打上面的热线，专业人员可以帮助你",
                "如果情况紧急，请拨打 120 或前往最近的医院急诊"
            ]
        }
    }


# ============ 搜索工具 ============

@tool_handler("search_psych_knowledge")
async def execute_search_psych_knowledge(args: Dict, context: ToolContext) -> Dict:
    """
    搜索心理学知识库
    """
    query = args.get("query", "")
    category = args.get("category")
    max_results = args.get("max_results", 3)

    # 使用向量搜索或关键词匹配
    results = await _search_knowledge_base(query, category, max_results)

    return {
        "status": "success",
        "results": results
    }


# ============ 操作工具 ============

@tool_handler("save_assessment_history")
async def execute_save_assessment_history(args: Dict, context: ToolContext) -> Dict:
    """
    保存评估历史记录
    """
    if not context.user_id:
        return {"status": "error", "message": "未登录用户"}

    await _save_assessment_history(
        context.user_id,
        args.get("assessment_type"),
        {
            "score": args.get("score"),
            "date": args.get("date", datetime.now().isoformat())
        }
    )

    return {"status": "success"}


@tool_handler("schedule_checkin")
async def execute_schedule_checkin(args: Dict, context: ToolContext) -> Dict:
    """
    设置心理健康检查提醒
    """
    if not context.user_id:
        return {"status": "error", "message": "未登录用户"}

    frequency = args.get("frequency", "weekly")
    reminder_type = args.get("reminder_type", "mood_check")

    await UnifiedProfileRepository.update_skill_data(
        context.user_id,
        "psych",
        {
            f"practices.active_reminders.{reminder_type}": {
                "frequency": frequency,
                "enabled": True,
                "created_at": datetime.now().isoformat()
            }
        }
    )

    return {
        "status": "success",
        "message": f"已设置 {frequency} {reminder_type} 提醒"
    }


# ============ 辅助函数 ============

async def _save_assessment_history(
    user_id: UUID,
    assessment_type: str,
    result: Dict
) -> None:
    """保存评估结果到历史记录"""
    await UnifiedProfileRepository.update_skill_data(
        user_id,
        "psych",
        {
            f"assessments.latest.{assessment_type}": {
                "date": datetime.now().isoformat(),
                "score": result.get("total_score"),
                "severity": result.get("severity_level")
            }
        }
    )
    # 注意：追加到历史数组需要特殊处理，这里简化


def _load_questionnaire(assessment_type: str) -> Dict:
    """加载问卷定义"""
    # 从 knowledge/assessments/{type}.md 加载
    # 这里返回示例结构
    questionnaires = {
        "phq9": {
            "introduction": "接下来我会问你一些关于过去两周感受的问题。",
            "items": [...],  # PHQ-9 题目
            "response_scale": {0: "完全没有", 1: "有几天", 2: "一半以上时间", 3: "几乎每天"}
        },
        # ...
    }
    return questionnaires.get(assessment_type, {})


def _analyze_birth_order(family_constellation: Dict) -> str:
    """分析出生顺序影响"""
    position = family_constellation.get("position", "")
    # 基于位置返回分析
    analyses = {
        "独生子女": "作为独生子女，你可能发展出较强的独立性和成熟度...",
        "长子/长女": "作为长子/长女，你可能有较强的责任感和成就导向...",
        "中间子女": "作为中间子女，你可能发展出灵活性和调解能力...",
        "幼子/幼女": "作为幼子/幼女，你可能有较强的社交魅力和创造力..."
    }
    return analyses.get(position, "")


def _extract_memory_themes(early_recollections: List[Dict]) -> List[str]:
    """从早期记忆中提取主题"""
    # 分析记忆内容，提取反复出现的主题
    # 这里需要 LLM 辅助分析
    return []


def _analyze_life_tasks(life_tasks_scores: Dict) -> Dict:
    """分析人生任务平衡"""
    work = life_tasks_scores.get("work", 5)
    social = life_tasks_scores.get("social", 5)
    love = life_tasks_scores.get("love", 5)

    return {
        "work": {"score": work, "status": "需要关注" if work < 5 else "良好"},
        "social": {"score": social, "status": "需要关注" if social < 5 else "良好"},
        "love": {"score": love, "status": "需要关注" if love < 5 else "良好"},
        "overall_balance": (work + social + love) / 3
    }


def _infer_lifestyle_type(
    family_constellation: Dict,
    early_recollections: List[Dict],
    life_tasks_scores: Dict
) -> str:
    """推断生活风格类型"""
    # 基于阿德勒四种生活风格类型
    # 这里需要更复杂的分析逻辑
    return "socially_useful"  # 默认返回


def _infer_core_beliefs(early_recollections: List[Dict]) -> Dict:
    """从早期记忆推断核心信念"""
    return {
        "self": "待分析",
        "world": "待分析",
        "others": "待分析"
    }


def _identify_growth_areas(life_tasks_scores: Dict) -> List[str]:
    """识别成长领域"""
    areas = []
    if life_tasks_scores.get("work", 5) < 5:
        areas.append("职业发展")
    if life_tasks_scores.get("social", 5) < 5:
        areas.append("社交连接")
    if life_tasks_scores.get("love", 5) < 5:
        areas.append("亲密关系")
    return areas


async def _search_knowledge_base(
    query: str,
    category: Optional[str],
    max_results: int
) -> List[Dict]:
    """搜索知识库"""
    # 实现向量搜索或关键词匹配
    # 从 knowledge/ 目录加载相关内容
    return []
```

---

## 四、服务层实现

### 4.1 calculator.py

```python
"""
心理评估量表计分逻辑
"""

from typing import Dict, List


def calculate_phq9(responses: List[int]) -> Dict:
    """
    计算 PHQ-9 得分

    Args:
        responses: 9 个题目的回答 (0-3)

    Returns:
        total_score, severity_level
    """
    if len(responses) < 9:
        responses = responses + [0] * (9 - len(responses))

    total_score = sum(responses[:9])

    if total_score <= 4:
        severity_level = "无抑郁或极轻微抑郁"
    elif total_score <= 9:
        severity_level = "轻度抑郁"
    elif total_score <= 14:
        severity_level = "中度抑郁"
    elif total_score <= 19:
        severity_level = "中重度抑郁"
    else:
        severity_level = "重度抑郁"

    return {
        "total_score": total_score,
        "severity_level": severity_level,
        "max_score": 27
    }


def calculate_gad7(responses: List[int]) -> Dict:
    """
    计算 GAD-7 得分

    Args:
        responses: 7 个题目的回答 (0-3)

    Returns:
        total_score, severity_level
    """
    if len(responses) < 7:
        responses = responses + [0] * (7 - len(responses))

    total_score = sum(responses[:7])

    if total_score <= 4:
        severity_level = "极轻微焦虑"
    elif total_score <= 9:
        severity_level = "轻度焦虑"
    elif total_score <= 14:
        severity_level = "中度焦虑"
    else:
        severity_level = "重度焦虑"

    return {
        "total_score": total_score,
        "severity_level": severity_level,
        "max_score": 21
    }


def calculate_dass21(responses: List[int]) -> Dict:
    """
    计算 DASS-21 得分

    Args:
        responses: 21 个题目的回答 (0-3)

    Returns:
        depression, anxiety, stress 分量表得分和严重程度
    """
    if len(responses) < 21:
        responses = responses + [0] * (21 - len(responses))

    # DASS-21 题目归属
    # 抑郁: 3, 5, 10, 13, 16, 17, 21 (索引: 2, 4, 9, 12, 15, 16, 20)
    # 焦虑: 2, 4, 7, 9, 15, 19, 20 (索引: 1, 3, 6, 8, 14, 18, 19)
    # 压力: 1, 6, 8, 11, 12, 14, 18 (索引: 0, 5, 7, 10, 11, 13, 17)

    depression_indices = [2, 4, 9, 12, 15, 16, 20]
    anxiety_indices = [1, 3, 6, 8, 14, 18, 19]
    stress_indices = [0, 5, 7, 10, 11, 13, 17]

    depression_raw = sum(responses[i] for i in depression_indices)
    anxiety_raw = sum(responses[i] for i in anxiety_indices)
    stress_raw = sum(responses[i] for i in stress_indices)

    # 乘以 2 得到最终分数
    depression = depression_raw * 2
    anxiety = anxiety_raw * 2
    stress = stress_raw * 2

    def get_depression_severity(score: int) -> str:
        if score <= 9: return "正常"
        elif score <= 13: return "轻度"
        elif score <= 20: return "中度"
        elif score <= 27: return "重度"
        else: return "极重度"

    def get_anxiety_severity(score: int) -> str:
        if score <= 7: return "正常"
        elif score <= 9: return "轻度"
        elif score <= 14: return "中度"
        elif score <= 19: return "重度"
        else: return "极重度"

    def get_stress_severity(score: int) -> str:
        if score <= 14: return "正常"
        elif score <= 18: return "轻度"
        elif score <= 25: return "中度"
        elif score <= 33: return "重度"
        else: return "极重度"

    return {
        "subscales": {
            "depression": {
                "score": depression,
                "severity": get_depression_severity(depression)
            },
            "anxiety": {
                "score": anxiety,
                "severity": get_anxiety_severity(anxiety)
            },
            "stress": {
                "score": stress,
                "severity": get_stress_severity(stress)
            }
        },
        "total_score": depression + anxiety + stress,
        "max_score": 126
    }


def interpret_score(assessment_type: str, total_score: int) -> Dict:
    """
    根据分数生成解读和建议
    """
    interpretations = {
        "phq9": {
            (0, 4): {
                "interpretation": "你目前没有明显的抑郁症状。继续保持健康的生活方式。",
                "recommendations": [
                    "保持规律的作息",
                    "维持社交连接",
                    "定期进行心理健康检查"
                ]
            },
            (5, 9): {
                "interpretation": "你可能正在经历一些轻微的抑郁症状。这在生活压力时期是常见的。",
                "recommendations": [
                    "自我监测，关注症状变化",
                    "尝试规律运动",
                    "与信任的人交流",
                    "如症状持续超过 2 周，考虑咨询专业人士"
                ]
            },
            (10, 14): {
                "interpretation": "你的抑郁症状已达到中度水平。这可能正在影响你的日常生活。",
                "recommendations": [
                    "建议寻求专业心理咨询",
                    "考虑认知行为疗法",
                    "与家人朋友分享你的感受",
                    "保持规律的日常活动"
                ]
            },
            (15, 19): {
                "interpretation": "你的抑郁症状比较严重。积极寻求专业帮助非常重要。",
                "recommendations": [
                    "强烈建议寻求专业治疗",
                    "考虑心理治疗结合必要的药物治疗",
                    "告诉身边的人你需要支持",
                    "避免独处过久"
                ]
            },
            (20, 27): {
                "interpretation": "你正在经历严重的抑郁症状。请尽快寻求专业帮助。",
                "recommendations": [
                    "请立即联系专业心理健康服务",
                    "考虑精神科就诊",
                    "确保有人陪伴和支持你",
                    "如有自伤想法，请立即拨打危机热线"
                ]
            }
        },
        # GAD-7 和 DASS-21 的解读类似...
    }

    assessment_interp = interpretations.get(assessment_type, {})
    for score_range, content in assessment_interp.items():
        if score_range[0] <= total_score <= score_range[1]:
            return content

    return {
        "interpretation": "无法生成解读",
        "recommendations": []
    }
```

### 4.2 safety.py

```python
"""
安全检测逻辑
"""

from typing import Dict, List, Optional
import re


# 高风险关键词
HIGH_RISK_KEYWORDS = [
    "自杀", "不想活", "想死", "结束生命", "自伤", "割",
    "跳楼", "上吊", "吃药", "活着没意思", "世界没有我会更好"
]

# 中风险关键词
MEDIUM_RISK_KEYWORDS = [
    "绝望", "没有意义", "麻木", "无法继续", "撑不下去",
    "活得好累", "太累了", "不想醒来"
]


def check_crisis_indicators(text: str) -> Dict:
    """
    检查文本中的危机信号

    Returns:
        risk_level: "high", "medium", "low"
        matched_keywords: 匹配到的关键词
        action: 建议的行动
    """
    text_lower = text.lower()

    high_risk_matches = [kw for kw in HIGH_RISK_KEYWORDS if kw in text_lower]
    medium_risk_matches = [kw for kw in MEDIUM_RISK_KEYWORDS if kw in text_lower]

    if high_risk_matches:
        return {
            "risk_level": "high",
            "matched_keywords": high_risk_matches,
            "action": "crisis_protocol"
        }
    elif medium_risk_matches:
        return {
            "risk_level": "medium",
            "matched_keywords": medium_risk_matches,
            "action": "concerned_followup"
        }
    else:
        return {
            "risk_level": "low",
            "matched_keywords": [],
            "action": "continue_normally"
        }


def should_show_crisis_resources(
    text: str,
    phq9_item9_score: Optional[int] = None
) -> bool:
    """
    判断是否应该显示危机资源

    基于文本内容和 PHQ-9 第 9 题得分
    """
    crisis_check = check_crisis_indicators(text)

    # 高风险关键词
    if crisis_check["risk_level"] == "high":
        return True

    # PHQ-9 第 9 题得分 >= 2 (一半以上时间或几乎每天)
    if phq9_item9_score and phq9_item9_score >= 2:
        return True

    return False


def generate_crisis_response(risk_level: str) -> str:
    """
    生成危机响应消息
    """
    if risk_level == "high":
        return """
我非常担心你刚才说的话。
你的安全是最重要的。

请立即联系专业帮助：
🆘 全国心理援助热线：400-161-9995（24小时）
🆘 北京心理危机热线：010-82951332

如果你现在有伤害自己的想法或计划，
请先把可能用来伤害自己的东西放到安全的地方。

你现在安全吗？有人陪在你身边吗？
"""
    elif risk_level == "medium":
        return """
我听到了你说的话，听起来你最近承受了很多。
有时候，当压力太大时，我们可能会有一些让自己害怕的想法。

我想确认一下你现在的状态。
你愿意多告诉我一些吗？

如果你觉得需要专业支持，可以联系：
📞 全国心理援助热线：400-161-9995
"""
    else:
        return ""
```

---

## 五、API 服务端点

### 5.1 api.py

```python
"""
Psych Skill API 服务端点
"""

from typing import Dict
from services.agent.skill_service_registry import skill_service, ServiceContext


@skill_service(
    "psych",
    "assessment",
    description="执行心理健康评估",
    auth_required=True
)
async def psych_assessment(args: Dict, context: ServiceContext) -> Dict:
    """
    执行心理健康评估

    POST /api/v1/skills/psych/assessment
    {
        "assessment_type": "phq9",
        "responses": [0, 1, 2, 1, 0, 1, 2, 1, 0]
    }
    """
    from .tools.handlers import execute_calculate_assessment

    return await execute_calculate_assessment(args, context)


@skill_service(
    "psych",
    "history",
    description="获取评估历史",
    auth_required=True
)
async def psych_history(args: Dict, context: ServiceContext) -> Dict:
    """
    获取用户评估历史

    GET /api/v1/skills/psych/history
    """
    from stores.unified_profile_repo import UnifiedProfileRepository

    psych_data = await UnifiedProfileRepository.get_skill_data(
        context.user_id,
        "psych"
    )

    return {
        "status": "success",
        "data": {
            "assessments": psych_data.get("assessments", {}),
            "exploration": psych_data.get("exploration", {})
        }
    }


@skill_service(
    "psych",
    "trend",
    description="获取评估趋势数据",
    auth_required=True
)
async def psych_trend(args: Dict, context: ServiceContext) -> Dict:
    """
    获取评估分数趋势

    GET /api/v1/skills/psych/trend?type=phq9&days=30
    """
    assessment_type = args.get("type", "phq9")
    days = args.get("days", 30)

    # 实现趋势数据获取
    # ...

    return {
        "status": "success",
        "data": {
            "assessment_type": assessment_type,
            "period_days": days,
            "trend": []  # 趋势数据点
        }
    }
```

---

## 六、前端组件实现

### 6.1 卡片注册

```typescript
// apps/web/src/skills/psych/cards/index.ts

import { registerCard } from '@/lib/cardRegistry';

// 同步注册
import AssessmentResultCard from './AssessmentResultCard';
import ArchetypeProfileCard from './ArchetypeProfileCard';
import DistortionAnalysisCard from './DistortionAnalysisCard';
import LifestyleProfileCard from './LifestyleProfileCard';
import ExerciseCard from './ExerciseCard';
import MoodCheckCard from './MoodCheckCard';
import CrisisAlertCard from './CrisisAlertCard';

// 注册卡片
registerCard('assessment_result', AssessmentResultCard);
registerCard('archetype_profile', ArchetypeProfileCard);
registerCard('distortion_card', DistortionAnalysisCard);
registerCard('lifestyle_profile', LifestyleProfileCard);
registerCard('exercise_card', ExerciseCard);
registerCard('mood_check_form', MoodCheckCard);
registerCard('crisis_alert', CrisisAlertCard);

// 表单类卡片
registerCard('assessment_form', AssessmentFormCard);
registerCard('narrative_form', NarrativeFormCard);
registerCard('structured_form', StructuredFormCard);
registerCard('thought_record_form', ThoughtRecordFormCard);
```

### 6.2 核心卡片组件

```typescript
// AssessmentResultCard.tsx

'use client';

import { Card, CardHeader, CardBody } from '@/components/ui/Card';
import { Progress } from '@/components/ui/Progress';
import { Badge } from '@/components/ui/Badge';
import { cn } from '@/lib/utils';

interface AssessmentResultCardProps {
  data: {
    assessment_type: 'phq9' | 'gad7' | 'dass21';
    total_score: number;
    max_score: number;
    severity_level: string;
    subscales?: {
      depression?: { score: number; severity: string };
      anxiety?: { score: number; severity: string };
      stress?: { score: number; severity: string };
    };
    interpretation: string;
    recommendations: string[];
    safety_flag?: string;
  };
}

const ASSESSMENT_NAMES = {
  phq9: '患者健康问卷-9 (PHQ-9)',
  gad7: '广泛性焦虑障碍-7 (GAD-7)',
  dass21: '抑郁焦虑压力量表-21 (DASS-21)',
};

const SEVERITY_COLORS = {
  '无抑郁或极轻微抑郁': 'bg-green-500',
  '极轻微焦虑': 'bg-green-500',
  '正常': 'bg-green-500',
  '轻度': 'bg-yellow-500',
  '轻度抑郁': 'bg-yellow-500',
  '轻度焦虑': 'bg-yellow-500',
  '中度': 'bg-orange-500',
  '中度抑郁': 'bg-orange-500',
  '中度焦虑': 'bg-orange-500',
  '中重度抑郁': 'bg-red-500',
  '重度': 'bg-red-600',
  '重度抑郁': 'bg-red-600',
  '重度焦虑': 'bg-red-600',
  '极重度': 'bg-red-800',
};

export default function AssessmentResultCard({ data }: AssessmentResultCardProps) {
  const {
    assessment_type,
    total_score,
    max_score,
    severity_level,
    subscales,
    interpretation,
    recommendations,
    safety_flag,
  } = data;

  const percentage = Math.round((total_score / max_score) * 100);
  const severityColor = SEVERITY_COLORS[severity_level] || 'bg-gray-500';

  return (
    <Card className="assessment-result max-w-md">
      <CardHeader className="pb-2">
        <h3 className="text-lg font-semibold">
          {ASSESSMENT_NAMES[assessment_type]}
        </h3>
      </CardHeader>

      <CardBody className="space-y-4">
        {/* 总分显示 */}
        <div className="text-center">
          <div className="text-4xl font-bold">
            {total_score}
            <span className="text-lg text-muted-foreground">/{max_score}</span>
          </div>
          <Badge className={cn('mt-2', severityColor)}>
            {severity_level}
          </Badge>
        </div>

        {/* 进度条 */}
        <Progress value={percentage} className="h-2" />

        {/* DASS-21 分量表 */}
        {subscales && (
          <div className="space-y-2">
            <h4 className="text-sm font-medium">分量表得分</h4>
            {subscales.depression && (
              <SubscaleRow
                label="抑郁"
                score={subscales.depression.score}
                severity={subscales.depression.severity}
                maxScore={42}
              />
            )}
            {subscales.anxiety && (
              <SubscaleRow
                label="焦虑"
                score={subscales.anxiety.score}
                severity={subscales.anxiety.severity}
                maxScore={42}
              />
            )}
            {subscales.stress && (
              <SubscaleRow
                label="压力"
                score={subscales.stress.score}
                severity={subscales.stress.severity}
                maxScore={42}
              />
            )}
          </div>
        )}

        {/* 解读 */}
        <div className="bg-muted p-3 rounded-lg">
          <p className="text-sm">{interpretation}</p>
        </div>

        {/* 建议 */}
        {recommendations.length > 0 && (
          <div>
            <h4 className="text-sm font-medium mb-2">建议</h4>
            <ul className="text-sm space-y-1">
              {recommendations.map((rec, idx) => (
                <li key={idx} className="flex items-start gap-2">
                  <span className="text-muted-foreground">•</span>
                  {rec}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* 安全提醒 */}
        {safety_flag && <SafetyAlert flag={safety_flag} />}
      </CardBody>
    </Card>
  );
}

function SubscaleRow({
  label,
  score,
  severity,
  maxScore,
}: {
  label: string;
  score: number;
  severity: string;
  maxScore: number;
}) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span>{label}</span>
      <div className="flex items-center gap-2">
        <span>{score}/{maxScore}</span>
        <Badge variant="outline" className="text-xs">
          {severity}
        </Badge>
      </div>
    </div>
  );
}

function SafetyAlert({ flag }: { flag: string }) {
  if (flag !== 'suicidal_ideation') return null;

  return (
    <div className="bg-red-50 border border-red-200 p-3 rounded-lg">
      <p className="text-sm text-red-800">
        <strong>重要提醒：</strong>
        如果你有伤害自己的想法，请立即联系专业帮助。
      </p>
      <p className="text-sm text-red-700 mt-1">
        🆘 全国心理援助热线：400-161-9995
      </p>
    </div>
  );
}
```

```typescript
// CrisisAlertCard.tsx

'use client';

import { Card, CardBody } from '@/components/ui/Card';
import { AlertTriangle, Phone } from 'lucide-react';

interface CrisisAlertCardProps {
  data: {
    message: string;
    hotlines: Array<{
      name: string;
      number: string;
      hours: string;
    }>;
    immediate_steps: string[];
  };
}

export default function CrisisAlertCard({ data }: CrisisAlertCardProps) {
  const { message, hotlines, immediate_steps } = data;

  return (
    <Card className="border-red-500 border-2 bg-red-50">
      <CardBody className="space-y-4">
        {/* 警告图标和消息 */}
        <div className="flex items-start gap-3">
          <AlertTriangle className="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5" />
          <p className="text-red-800 font-medium">{message}</p>
        </div>

        {/* 危机热线 */}
        <div className="space-y-2">
          <h4 className="font-semibold text-red-800">立即联系专业帮助：</h4>
          {hotlines.map((hotline, idx) => (
            <a
              key={idx}
              href={`tel:${hotline.number}`}
              className="flex items-center gap-3 p-3 bg-white rounded-lg border border-red-200 hover:bg-red-100 transition-colors"
            >
              <Phone className="w-5 h-5 text-red-600" />
              <div>
                <div className="font-medium text-red-800">{hotline.name}</div>
                <div className="text-lg font-bold text-red-600">
                  {hotline.number}
                </div>
                <div className="text-sm text-red-500">{hotline.hours}</div>
              </div>
            </a>
          ))}
        </div>

        {/* 立即行动 */}
        <div className="space-y-2">
          <h4 className="font-semibold text-red-800">你现在可以做的：</h4>
          <ul className="space-y-2">
            {immediate_steps.map((step, idx) => (
              <li
                key={idx}
                className="flex items-start gap-2 text-sm text-red-700"
              >
                <span className="font-bold">{idx + 1}.</span>
                {step}
              </li>
            ))}
          </ul>
        </div>
      </CardBody>
    </Card>
  );
}
```

---

## 七、数据库迁移

```sql
-- migrations/xxx_psych_skill_setup.sql

-- 添加 psych skill 的默认数据结构
-- 主要数据存储在 unified_profiles.profile.skill_data.psych JSONB 中

-- 创建评估历史索引（可选，用于分析查询）
CREATE INDEX IF NOT EXISTS idx_unified_profiles_psych_assessments
ON unified_profiles ((profile->'skill_data'->'psych'->'assessments'->'latest'));

-- 评估类型枚举（用于验证）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'psych_assessment_type') THEN
        CREATE TYPE psych_assessment_type AS ENUM (
            'phq9', 'gad7', 'dass21', 'phq2', 'gad2'
        );
    END IF;
END$$;

-- 可选：创建独立的评估历史表（用于大规模分析）
CREATE TABLE IF NOT EXISTS psych_assessment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    assessment_type psych_assessment_type NOT NULL,
    total_score INTEGER NOT NULL,
    severity_level TEXT NOT NULL,
    responses JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 索引
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_psych_history_user_type
ON psych_assessment_history (user_id, assessment_type, created_at DESC);
```

---

这份技术实现规范定义了 Psych Skill 的完整实现细节，包括：

1. **目录结构** - 后端和前端的完整文件组织
2. **SKILL.md 配置** - 核心配置和专家身份定义
3. **工具执行器** - Python handlers 完整实现
4. **服务层** - 量表计分、安全检测等核心逻辑
5. **API 端点** - @skill_service 装饰器定义
6. **前端组件** - React/TypeScript 卡片实现
7. **数据库迁移** - SQL 脚本
