# VibeLife v7.0 系统架构重构方案

> Me 页生态系统：VibeID + VibeProfile + 多源融合
>
> 设计师：Claude Ultra Mode
> 日期：2026-01-21
> 版本：v7.0

---

## 一、核心理念

### 1.1 系统定位

```
VibeLife v7.0 = AI原生的个人成长陪伴平台

核心差异化：
- Deep Understanding：理解你这个人，而非只是问题
- Multi-Modal Fusion：融合多源数据（出生时间 + 行为交互）
- Dynamic Evolution：动态演化的人格画像
```

### 1.2 架构全景图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VibeLife v7.0 架构                               │
└─────────────────────────────────────────────────────────────────────────┘

用户层
├─ Me 页（超级聚合页）
│   ├─ VibeID 融合身份卡片（核心展示）
│   ├─ 八字维度（深入链接）
│   ├─ 星座维度（深入链接）
│   ├─ 荣格占星（深入链接）
│   ├─ 紫微斗数（深入链接，未来）
│   └─ 成长轨迹（时间线）
│
├─ Chat 页（对话入口）
│   └─ 所有深度分析通过对话呈现
│
└─ Journey 页（成长旅程）
    └─ 目标、进度、里程碑

═══════════════════════════════════════════════════════════════════════════

融合层（VibeID v7.0）
├─ 多源融合引擎
│   ├─ 出生时间类（Birth-Time Based）
│   │   ├─ Bazi（八字）- 70% 权重
│   │   ├─ Zodiac（星座）- 30% 权重
│   │   ├─ JungAstro（荣格占星）- 心理学视角
│   │   └─ Ziwei（紫微斗数）- 未来扩展
│   │
│   └─ 行为交互类（Behavior-Driven）
│       ├─ 对话分析（Chat）- LLM prompt 驱动
│       ├─ 目标设定（Goals）- LifeCoach skill
│       ├─ 日志记录（Journal）- LifeCoach skill
│       └─ 其他 Skill 交互数据
│
├─ 四维人格模型
│   ├─ Core（灵魂本质）- 八字主导
│   ├─ Inner（内在世界）- 星座主导
│   ├─ Outer（外在呈现）- 星座主导
│   └─ Shadow（阴影倾向）- Core 对立面
│
└─ 动态演化机制
    ├─ 行为观察 → LLM 分析 → 人格微调
    ├─ 时间线事件 → 原型能量变化
    └─ 定期重计算（每月/重大事件）

═══════════════════════════════════════════════════════════════════════════

数据层（VibeProfile）
└─ unified_profiles 表（JSONB）
    ├─ account: 账户信息
    ├─ birth_info: 出生信息（所有命理系统共用）★
    ├─ state: 用户状态（focus）
    ├─ life_context: 生活上下文
    ├─ preferences: 偏好设置
    ├─ skill_data: 各 Skill 计算数据★
    │   ├─ bazi: {...}
    │   ├─ zodiac: {...}
    │   ├─ jungastro: {...}
    │   └─ vibe_id: {...}  # VibeID 融合结果
    ├─ extracted: AI 提取的用户信息★
    │   ├─ facts: 事实信息
    │   ├─ concerns: 关注点
    │   ├─ goals: 目标
    │   ├─ pain_points: 痛点
    │   ├─ life_events: 人生事件
    │   └─ patterns: 行为模式
    └─ skills: 各 Skill 状态（REFACTOR_PLAN Phase 1）

Cold Layer（长期存储）
├─ vibe_profile_insights: AI 生成的洞察
└─ vibe_profile_timeline: 时间线事件
```

---

## 二、VibeID v7.0 重构设计

### 2.1 核心定位升级

**从**：
> "融合八字命理与西方占星的四维人格分析系统"

**升级到**：
> "多源融合的动态人格画像系统"
> - 融合出生时间类数据（八字、星座、荣格占星、紫微）
> - 融合行为交互类数据（对话、目标、日志、其他 Skill）
> - 通过 LLM prompt 驱动的心理模型分析用户行为性格

### 2.2 数据源分类

#### A. 出生时间类（Birth-Time Based）

```python
# 特点：一次计算，长期有效
# 数据来源：unified_profiles.birth_info

class BirthTimeAnalyzer:
    """出生时间类分析器基类"""

    @abstractmethod
    async def analyze(self, birth_info: Dict) -> AnalysisResult:
        """
        基于出生信息进行分析

        Args:
            birth_info: {
                "date": "1990-01-01",
                "time": "12:00",
                "place": "北京",
                "gender": "male",
                "timezone": "Asia/Shanghai"
            }

        Returns:
            AnalysisResult: {
                "primary_archetype": "Creator",
                "archetypes": {...},
                "insights": [...],
                "confidence": 0.85
            }
        """
        pass

# 具体实现
class BaziAnalyzer(BirthTimeAnalyzer):
    """八字分析器"""
    weight: float = 0.70  # 权重 70%

class ZodiacAnalyzer(BirthTimeAnalyzer):
    """星座分析器"""
    weight: float = 0.30  # 权重 30%

class JungAstroAnalyzer(BirthTimeAnalyzer):
    """荣格占星分析器"""
    weight: float = 0.0  # 目前不参与原型融合，提供心理学视角

class ZiweiAnalyzer(BirthTimeAnalyzer):
    """紫微斗数分析器（未来）"""
    weight: float = 0.0  # 未来扩展
```

#### B. 行为交互类（Behavior-Driven）

```python
# 特点：动态变化，需定期重新分析
# 数据来源：unified_profiles.extracted + conversation_messages

class BehaviorAnalyzer:
    """行为分析器（LLM prompt 驱动）"""

    async def analyze_from_extracted(
        self,
        user_id: UUID
    ) -> BehaviorInsight:
        """
        基于 extracted 数据分析用户行为性格

        流程：
        1. 读取 unified_profiles.extracted
        2. 构建 LLM prompt（包含所有 extracted 数据）
        3. LLM 分析 → 行为模式、性格特征、原型倾向
        4. 返回 BehaviorInsight
        """
        profile = await UnifiedProfileRepository.get_profile(user_id)
        extracted = profile.get("extracted", {})

        # 构建分析 prompt
        prompt = self._build_analysis_prompt(extracted)

        # LLM 分析
        response = await self.llm.generate(prompt)

        # 解析结果
        return self._parse_behavior_insight(response)

    def _build_analysis_prompt(self, extracted: Dict) -> str:
        """
        构建分析 prompt

        Prompt 示例：
        ---
        基于以下用户信息，分析用户的行为模式和性格特征：

        # 事实信息
        {extracted.facts}

        # 关注点
        {extracted.concerns}

        # 目标
        {extracted.goals}

        # 痛点
        {extracted.pain_points}

        # 人生事件
        {extracted.life_events}

        # 行为模式
        {extracted.patterns}

        请分析：
        1. 核心性格特征（5-7 个关键词）
        2. 主导原型（从 12 原型中选择）
        3. 行为模式（重复出现的模式）
        4. 成长方向（基于当前状态）

        输出格式：JSON
        ---
        """
        return f"""
        基于以下用户信息，分析用户的行为模式和性格特征：

        # 事实信息
        {json.dumps(extracted.get('facts', []), ensure_ascii=False, indent=2)}

        # 关注点
        {json.dumps(extracted.get('concerns', []), ensure_ascii=False, indent=2)}

        # 目标
        {json.dumps(extracted.get('goals', []), ensure_ascii=False, indent=2)}

        # 痛点
        {json.dumps(extracted.get('pain_points', []), ensure_ascii=False, indent=2)}

        # 人生事件
        {json.dumps(extracted.get('life_events', []), ensure_ascii=False, indent=2)}

        # 行为模式
        {json.dumps(extracted.get('patterns', []), ensure_ascii=False, indent=2)}

        请分析：
        1. 核心性格特征（5-7 个关键词）
        2. 主导原型（从 12 原型中选择：Innocent, Explorer, Sage, Hero, Outlaw, Magician, Regular, Lover, Jester, Caregiver, Creator, Ruler）
        3. 行为模式（重复出现的模式）
        4. 成长方向（基于当前状态）

        输出格式：
        {{
            "traits": ["trait1", "trait2", ...],
            "primary_archetype": "archetype_name",
            "behavior_patterns": ["pattern1", "pattern2", ...],
            "growth_direction": "description",
            "confidence": 0.0-1.0
        }}
        """
```

### 2.3 融合引擎架构

#### 可扩展融合引擎设计

```python
# apps/api/skills/vibe_id/services/fusion_engine_v7.py

"""
VibeID v7.0 融合引擎

核心特性：
1. 插件化架构：支持动态注册分析器
2. 权重配置化：权重可通过配置文件调整
3. 分层融合：出生时间类 + 行为交互类分别融合
4. 动态调整：根据数据完整度动态调整权重
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from uuid import UUID

@dataclass
class AnalysisResult:
    """分析结果"""
    primary_archetype: str
    archetypes: Dict[str, float]  # archetype -> score
    insights: List[str]
    confidence: float
    metadata: Dict[str, Any]

@dataclass
class FusionConfig:
    """融合配置"""
    analyzers: List[Dict[str, Any]]  # [{"type": "bazi", "weight": 0.7, ...}]
    consistency_bonus: float = 0.15
    min_confidence: float = 0.5

class PluggableFusionEngine:
    """可扩展融合引擎"""

    def __init__(self, config: FusionConfig):
        self.config = config
        self.analyzers: List[tuple[BirthTimeAnalyzer, float]] = []
        self.behavior_analyzer: Optional[BehaviorAnalyzer] = None

    def register_analyzer(
        self,
        analyzer: BirthTimeAnalyzer,
        weight: float
    ):
        """注册出生时间类分析器"""
        self.analyzers.append((analyzer, weight))

    def set_behavior_analyzer(self, analyzer: BehaviorAnalyzer):
        """设置行为分析器"""
        self.behavior_analyzer = analyzer

    async def fuse(self, user_id: UUID) -> Dict[str, Any]:
        """
        融合分析

        流程：
        1. 运行所有出生时间类分析器
        2. 运行行为分析器（如果有足够数据）
        3. 加权融合所有结果
        4. 生成四维人格模型
        5. 计算一致性奖励
        6. 返回融合结果
        """
        # 1. 获取出生信息
        birth_info = await UnifiedProfileRepository.get_birth_info(user_id)
        if not birth_info:
            raise ValueError("No birth_info found")

        # 2. 运行出生时间类分析器
        birth_results = []
        total_weight = 0
        for analyzer, weight in self.analyzers:
            result = await analyzer.analyze(birth_info)
            birth_results.append((result, weight))
            total_weight += weight

        # 归一化权重
        birth_results = [
            (result, weight / total_weight)
            for result, weight in birth_results
        ]

        # 3. 运行行为分析器（可选）
        behavior_result = None
        if self.behavior_analyzer:
            behavior_result = await self.behavior_analyzer.analyze_from_extracted(user_id)

        # 4. 融合所有结果
        fused = self._fuse_results(birth_results, behavior_result)

        # 5. 生成四维人格模型
        four_dimensions = self._generate_four_dimensions(fused, birth_results)

        # 6. 保存到 skill_data.vibe_id
        await self._save_fused_result(user_id, fused, four_dimensions)

        return {
            "fused": fused,
            "four_dimensions": four_dimensions,
            "birth_results": [r.to_dict() for r, _ in birth_results],
            "behavior_result": behavior_result.to_dict() if behavior_result else None
        }

    def _fuse_results(
        self,
        birth_results: List[tuple[AnalysisResult, float]],
        behavior_result: Optional[BehaviorInsight]
    ) -> Dict[str, Any]:
        """
        加权融合所有结果

        策略：
        1. 出生时间类：加权平均原型分数
        2. 行为交互类：调整原型分数（+/- 调整量）
        3. 一致性奖励：如果多个系统指向同一原型，增加分数
        """
        # 初始化原型分数
        archetype_scores = {}

        # 1. 融合出生时间类结果
        for result, weight in birth_results:
            for archetype, score in result.archetypes.items():
                archetype_scores[archetype] = archetype_scores.get(archetype, 0) + score * weight

        # 2. 融合行为交互类结果（如果有）
        if behavior_result:
            # 行为结果作为"调整量"，而非直接权重
            behavior_archetype = behavior_result.primary_archetype
            if behavior_archetype in archetype_scores:
                # 如果行为分析的主原型与出生时间类一致，增强
                archetype_scores[behavior_archetype] *= 1.2
            else:
                # 否则，新增该原型（较低权重）
                archetype_scores[behavior_archetype] = 0.3

        # 3. 一致性奖励
        # 如果多个系统的主原型一致，增加分数
        primary_archetypes = [r.primary_archetype for r, _ in birth_results]
        if len(set(primary_archetypes)) == 1:  # 所有系统一致
            consistent_archetype = primary_archetypes[0]
            archetype_scores[consistent_archetype] *= (1 + self.config.consistency_bonus)

        # 4. 归一化分数
        total_score = sum(archetype_scores.values())
        normalized_scores = {
            k: v / total_score
            for k, v in archetype_scores.items()
        }

        # 5. 选择主原型
        primary_archetype = max(normalized_scores.items(), key=lambda x: x[1])[0]

        return {
            "primary_archetype": primary_archetype,
            "archetype_scores": normalized_scores,
            "confidence": self._calculate_confidence(birth_results, behavior_result)
        }

    def _generate_four_dimensions(
        self,
        fused: Dict,
        birth_results: List[tuple[AnalysisResult, float]]
    ) -> Dict[str, Any]:
        """
        生成四维人格模型

        策略：
        - Core (灵魂本质): 融合结果的主原型
        - Inner (内在世界): 从星座的月亮+金星推导
        - Outer (外在呈现): 从星座的上升+火星推导
        - Shadow (阴影倾向): Core 的对立面
        """
        from ..models import get_shadow_archetype

        primary = fused["primary_archetype"]

        # 从 birth_results 中找星座分析结果
        zodiac_result = next(
            (r for r, _ in birth_results if isinstance(r.metadata.get("analyzer"), str) and "zodiac" in r.metadata["analyzer"].lower()),
            None
        )

        # Inner: 星座的内在原型
        inner_archetype = zodiac_result.metadata.get("inner_archetype") if zodiac_result else primary

        # Outer: 星座的外在原型
        outer_archetype = zodiac_result.metadata.get("outer_archetype") if zodiac_result else primary

        # Shadow: Core 的对立面
        shadow_archetype, tension = get_shadow_archetype(primary)

        return {
            "core": {
                "archetype": primary,
                "description": f"{primary}的灵魂本质",
                "source": "fused_from_bazi_zodiac"
            },
            "inner": {
                "archetype": inner_archetype,
                "description": f"{inner_archetype}的内在世界",
                "source": "zodiac_moon_venus"
            },
            "outer": {
                "archetype": outer_archetype,
                "description": f"{outer_archetype}的外在呈现",
                "source": "zodiac_ascendant_mars"
            },
            "shadow": {
                "archetype": shadow_archetype,
                "tension": tension,
                "description": f"{shadow_archetype}的阴影倾向",
                "source": "core_opposite"
            }
        }

    async def _save_fused_result(
        self,
        user_id: UUID,
        fused: Dict,
        four_dimensions: Dict
    ):
        """保存融合结果到 skill_data.vibe_id"""
        await UnifiedProfileRepository.update_skill_data(
            user_id,
            "vibe_id",
            {
                "fused": fused,
                "four_dimensions": four_dimensions,
                "version": "7.0",
                "updated_at": datetime.utcnow().isoformat()
            }
        )

    def _calculate_confidence(
        self,
        birth_results: List[tuple[AnalysisResult, float]],
        behavior_result: Optional[BehaviorInsight]
    ) -> float:
        """
        计算融合结果的置信度

        因素：
        1. 各系统的置信度
        2. 系统间的一致性
        3. 行为分析的置信度（如果有）
        """
        # 加权平均出生时间类系统的置信度
        birth_confidence = sum(r.confidence * w for r, w in birth_results)

        # 一致性加成
        primary_archetypes = [r.primary_archetype for r, _ in birth_results]
        consistency = len(set(primary_archetypes)) / len(primary_archetypes)
        consistency_bonus = (1 - consistency) * 0.2  # 越一致，加成越高

        # 行为分析加成
        behavior_bonus = 0
        if behavior_result:
            behavior_bonus = behavior_result.confidence * 0.1

        total = birth_confidence + consistency_bonus + behavior_bonus
        return min(total, 1.0)
```

### 2.4 配置文件驱动

```yaml
# apps/api/skills/vibe_id/config/fusion_config.yaml

fusion_v7:
  # 分析器配置
  analyzers:
    - type: bazi
      weight: 0.70
      enabled: true

    - type: zodiac
      weight: 0.30
      enabled: true

    - type: jungastro
      weight: 0.0  # 不参与融合，仅提供心理学视角
      enabled: true

    - type: ziwei
      weight: 0.0  # 未来扩展
      enabled: false

  # 行为分析
  behavior_analysis:
    enabled: true
    min_extracted_items: 5  # 至少 5 条 extracted 数据才进行分析
    weight: 0.2  # 行为分析的调整权重

  # 一致性奖励
  consistency_bonus: 0.15

  # 最小置信度
  min_confidence: 0.5

  # 重新计算触发条件
  recalculation_triggers:
    - on_birth_info_update: true
    - on_major_life_event: true
    - periodic_interval_days: 30  # 每 30 天重新计算
```

### 2.5 VibeID Service API

```python
# apps/api/skills/vibe_id/services/service.py

class VibeIDService:
    """VibeID v7.0 服务"""

    @staticmethod
    async def generate(user_id: UUID, force_recalculate: bool = False) -> Dict[str, Any]:
        """
        生成 VibeID

        Args:
            user_id: 用户 ID
            force_recalculate: 是否强制重新计算

        Returns:
            {
                "fused": {...},
                "four_dimensions": {...},
                "birth_results": [...],
                "behavior_result": {...},
                "meta": {
                    "version": "7.0",
                    "calculated_at": "...",
                    "confidence": 0.85
                }
            }
        """
        # 1. 检查是否需要重新计算
        if not force_recalculate:
            cached = await VibeIDService._get_cached_result(user_id)
            if cached and VibeIDService._is_cache_valid(cached):
                return cached

        # 2. 初始化融合引擎
        config = await VibeIDService._load_fusion_config()
        engine = PluggableFusionEngine(config)

        # 3. 注册分析器
        for analyzer_config in config.analyzers:
            if not analyzer_config.get("enabled"):
                continue

            analyzer = VibeIDService._create_analyzer(analyzer_config["type"])
            engine.register_analyzer(analyzer, analyzer_config["weight"])

        # 4. 设置行为分析器
        if config.behavior_analysis.get("enabled"):
            behavior_analyzer = BehaviorAnalyzer()
            engine.set_behavior_analyzer(behavior_analyzer)

        # 5. 执行融合
        result = await engine.fuse(user_id)

        # 6. 添加元数据
        result["meta"] = {
            "version": "7.0",
            "calculated_at": datetime.utcnow().isoformat(),
            "confidence": result["fused"]["confidence"]
        }

        return result

    @staticmethod
    async def get_full(user_id: UUID) -> Dict[str, Any]:
        """
        获取完整 VibeID 数据

        Returns:
            {
                "primary_archetype": "Creator",
                "dimensions": {
                    "core": {...},
                    "inner": {...},
                    "outer": {...},
                    "shadow": {...}
                },
                "archetypes": {...},  # 所有原型分数
                "confidence": 0.85,
                "version": "7.0",
                "calculated_at": "..."
            }
        """
        skill_data = await UnifiedProfileRepository.get_skill_data(user_id, "vibe_id")

        if not skill_data:
            # 如果没有数据，触发生成
            await VibeIDService.generate(user_id)
            skill_data = await UnifiedProfileRepository.get_skill_data(user_id, "vibe_id")

        return {
            "primary_archetype": skill_data["fused"]["primary_archetype"],
            "dimensions": skill_data["four_dimensions"],
            "archetypes": skill_data["fused"]["archetype_scores"],
            "confidence": skill_data["fused"]["confidence"],
            "version": skill_data.get("version", "7.0"),
            "calculated_at": skill_data.get("updated_at")
        }

    @staticmethod
    def _create_analyzer(analyzer_type: str) -> BirthTimeAnalyzer:
        """创建分析器实例"""
        if analyzer_type == "bazi":
            from .analyzers.bazi_analyzer import BaziAnalyzer
            return BaziAnalyzer()
        elif analyzer_type == "zodiac":
            from .analyzers.zodiac_analyzer import ZodiacAnalyzer
            return ZodiacAnalyzer()
        elif analyzer_type == "jungastro":
            from .analyzers.jungastro_analyzer import JungAstroAnalyzer
            return JungAstroAnalyzer()
        # 未来扩展：ziwei
        else:
            raise ValueError(f"Unknown analyzer type: {analyzer_type}")
```

---

## 三、Me 页超级聚合架构

### 3.1 定位：以 VibeID 为核心的超级聚合页

```
Me 页 = VibeLife 的"数字镜子"

核心理念：
- 一句话告诉你"你是谁"（VibeID 融合身份）
- 提供深入到各个细分 skill 的链接
- 展示动态演化的成长轨迹
```

### 3.2 信息架构

```
Me 页结构

┌─────────────────────────────────────────┐
│  Layer 0: 用户信息                       │
│  └─ 头像 + 昵称 + Pro 标识               │
├─────────────────────────────────────────┤
│  Layer 1: VibeID 融合身份卡片 ★核心★     │
│  ├─ 主原型徽章："创造者 · 探索者"        │
│  ├─ 一句话本质："创造者的灵魂，探索者的心"│
│  ├─ 融合来源：                          │
│  │   "融合自八字（甲木·食神格）         │
│  │    × 星座（水瓶·天秤）               │
│  │    × 行为观察（目标导向、创新思维）"  │
│  ├─ 今日状态：能量 85% | 运势 ⭐⭐⭐⭐  │
│  └─ [探索更多维度 ↓]                    │
├─────────────────────────────────────────┤
│  Layer 2: 维度详情（展开）               │
│  │                                       │
│  ├─ 🌙 八字维度（出生时间类）            │
│  │   ├─ 日主、格局、大运                │
│  │   ├─ 今日运势                        │
│  │   └─ [深度分析 → /chat?skill=bazi]   │
│  │                                       │
│  ├─ ⭐ 星座维度（出生时间类）            │
│  │   ├─ 太阳、月亮、上升                │
│  │   ├─ 今日能量                        │
│  │   └─ [深度分析 → /chat?skill=zodiac] │
│  │                                       │
│  ├─ 🧠 荣格占星（心理学视角）            │
│  │   ├─ 心理原型、成长阶段               │
│  │   └─ [深度分析 → /chat?skill=jungastro]│
│  │                                       │
│  ├─ 🔮 紫微斗数（未来）                  │
│  │   ├─ 命宫、福德宫、官禄宫             │
│  │   └─ [深度分析 → /chat?skill=ziwei]  │
│  │                                       │
│  └─ 🌱 成长轨迹（行为交互类）            │
│      ├─ 时间线节点（最近 3 个）          │
│      │   ├─ 🌟 突破时刻                 │
│      │   ├─ 💡 原型演化                 │
│      │   └─ 🎯 目标达成                 │
│      └─ [查看完整旅程 → /journey]       │
├─────────────────────────────────────────┤
│  Layer 3: 设置（折叠）                   │
│  └─ 语气模式、通知、账户管理             │
└─────────────────────────────────────────┘
```

### 3.3 数据流设计

#### 选择：后端统一接口（BFF 模式）

```python
# apps/api/routes/me.py

"""
Me 页 BFF (Backend for Frontend)

职责：
1. 聚合多个 skill 的数据
2. 适配前端数据格式
3. 提供缓存优化
"""

from fastapi import APIRouter, Depends
from services.me.aggregator import MePageAggregator
from dependencies import get_current_user

router = APIRouter(prefix="/api/v1/me", tags=["me"])

@router.get("/complete")
async def get_me_page_data(user = Depends(get_current_user)):
    """
    获取 Me 页完整数据（单一接口）

    Returns:
        {
            "fused_identity": {
                "essence": "创造者的灵魂，探索者的心",
                "primary_archetype": "Creator",
                "secondary_archetype": "Explorer",
                "sources": {
                    "bazi": {"day_master": "甲木", "pattern": "食神格"},
                    "zodiac": {"sun": "水瓶座", "ascendant": "天秤座"},
                    "behavior": {"traits": ["创新思维", "目标导向"]}
                },
                "today": {
                    "energy": 85,
                    "fortune_level": 4,
                    "insight": "甲子日，水气旺盛..."
                },
                "meta": {
                    "calculated_at": "...",
                    "version": "7.0",
                    "confidence": 0.85
                }
            },
            "dimension_details": {
                "bazi": {...},
                "zodiac": {...},
                "jungastro": {...},
                "ziwei": {...},  // 未来
                "growth": {
                    "timeline": [...]
                }
            },
            "user": {
                "id": "...",
                "name": "...",
                "avatar": "...",
                "isPro": true
            }
        }
    """
    aggregator = MePageAggregator()
    return await aggregator.aggregate(user.id)
```

#### Me 页数据聚合器

```python
# apps/api/services/me/aggregator.py

"""
Me 页数据聚合器

职责：
1. 调用 VibeID.generate() 获取融合身份
2. 调用各 skill 获取维度详情
3. 聚合成统一的 Me 页数据格式
"""

class MePageAggregator:
    """Me 页数据聚合器"""

    async def aggregate(self, user_id: UUID) -> Dict[str, Any]:
        """
        聚合 Me 页数据

        流程：
        1. 调用 VibeID.generate() 获取融合结果
        2. 并行调用各 skill 获取详情
        3. 聚合成统一格式
        4. 返回给前端
        """
        # 1. 获取融合身份
        vibe_id = await VibeIDService.get_full(user_id)
        fused_identity = await self._build_fused_identity(user_id, vibe_id)

        # 2. 并行获取维度详情
        dimension_details = await self._get_dimension_details(user_id)

        # 3. 获取用户信息
        account = await UnifiedProfileRepository.get_account_full(user_id)

        return {
            "fused_identity": fused_identity,
            "dimension_details": dimension_details,
            "user": {
                "id": str(user_id),
                "name": account.get("display_name"),
                "avatar": account.get("avatar_url"),
                "isPro": account.get("tier") in ["pro", "enterprise"]
            }
        }

    async def _build_fused_identity(
        self,
        user_id: UUID,
        vibe_id: Dict
    ) -> Dict[str, Any]:
        """
        构建融合身份数据

        包括：
        - essence: 一句话本质
        - primary_archetype: 主原型
        - secondary_archetype: 次原型
        - sources: 融合来源（八字、星座、行为）
        - today: 今日状态（能量、运势）
        - meta: 元数据
        """
        # 生成一句话本质
        essence = await self._generate_essence(user_id, vibe_id)

        # 获取今日状态
        today = await self._get_today_status(user_id)

        # 获取融合来源
        sources = await self._get_fusion_sources(user_id)

        return {
            "essence": essence,
            "primary_archetype": vibe_id["primary_archetype"],
            "secondary_archetype": vibe_id["dimensions"]["inner"]["archetype"],
            "sources": sources,
            "today": today,
            "meta": {
                "calculated_at": vibe_id.get("calculated_at"),
                "version": vibe_id.get("version", "7.0"),
                "confidence": vibe_id.get("confidence", 0.8)
            }
        }

    async def _generate_essence(
        self,
        user_id: UUID,
        vibe_id: Dict
    ) -> str:
        """
        生成一句话本质

        策略：
        1. 从 VibeID 读取主原型和次原型
        2. 从八字读取日主特质
        3. 从星座读取表达方式
        4. 从行为数据读取核心特征（如果有）
        5. 融合生成一句话

        示例：
        - "创造者的灵魂，探索者的心"
        - "智者的深度，英雄的勇气"
        - "探索者的好奇，照顾者的温暖"
        """
        primary = vibe_id["primary_archetype"]
        inner = vibe_id["dimensions"]["inner"]["archetype"]

        # 从八字提取特质
        bazi_data = await UnifiedProfileRepository.get_skill_data(user_id, "bazi")
        bazi_quality = self._extract_bazi_quality(bazi_data.get("day_master"))

        # 从星座提取表达
        zodiac_data = await UnifiedProfileRepository.get_skill_data(user_id, "zodiac")
        zodiac_expression = self._extract_zodiac_expression(zodiac_data.get("sun_sign"))

        # 构建模板（可以用 LLM 生成更个性化的文案）
        essence = f"{primary}的{bazi_quality}，{inner}的{zodiac_expression}"

        return essence

    async def _get_dimension_details(self, user_id: UUID) -> Dict[str, Any]:
        """
        获取维度详情

        并行调用：
        - BaziService.get_summary()
        - ZodiacService.get_summary()
        - JungAstroService.get_summary()
        - GrowthTimelineService.get_recent_events()
        """
        # 并行获取
        bazi, zodiac, jungastro, growth = await asyncio.gather(
            self._get_bazi_dimension(user_id),
            self._get_zodiac_dimension(user_id),
            self._get_jungastro_dimension(user_id),
            self._get_growth_dimension(user_id)
        )

        return {
            "bazi": bazi,
            "zodiac": zodiac,
            "jungastro": jungastro,
            # "ziwei": ziwei,  # 未来
            "growth": growth
        }
```

---

## 四、与 VibeProfile 深度融合

### 4.1 数据结构利用

```python
# unified_profiles.profile 结构利用

{
    "account": {...},  # 已有，直接使用

    "birth_info": {...},  # ★ 核心共享数据
    # 所有出生时间类 skill 共享此数据
    # bazi, zodiac, jungastro, ziwei 都从这里读取

    "state": {
        "focus": [...],  # 用户当前关注话题
        "updated_at": "..."
    },

    "life_context": {...},  # 生活上下文

    "preferences": {
        "voice_mode": "warm",
        "subscribed_skills": {...}  # 已有，直接使用
    },

    "skill_data": {  # ★ 各 Skill 计算结果
        "bazi": {
            "chart": {...},
            "dayun": {...},
            "fortune_cache": {...}
        },
        "zodiac": {
            "chart": {...},
            "transits": {...}
        },
        "jungastro": {
            "psychological_profile": {...}
        },
        "vibe_id": {  # ★ VibeID 融合结果
            "fused": {
                "primary_archetype": "Creator",
                "archetype_scores": {...},
                "confidence": 0.85
            },
            "four_dimensions": {
                "core": {...},
                "inner": {...},
                "outer": {...},
                "shadow": {...}
            },
            "version": "7.0",
            "updated_at": "..."
        }
        // 未来：ziwei
    },

    "extracted": {  # ★ 行为交互类数据（AI 提取）
        "facts": [
            "28岁，互联网行业产品经理",
            "北京工作，老家山东",
            ...
        ],
        "concerns": [
            "职业发展瓶颈",
            "工作生活平衡",
            ...
        ],
        "goals": [
            "3年内晋升高级产品经理",
            "建立个人品牌",
            ...
        ],
        "pain_points": [
            "经常加班，缺少时间学习",
            "团队沟通效率低",
            ...
        ],
        "life_events": [
            {
                "date": "2023-06",
                "event": "跳槽到新公司",
                "impact": "工作压力增大"
            },
            ...
        ],
        "patterns": [
            "遇到问题时倾向于自己解决，不愿求助",
            "设定目标后容易半途而废",
            ...
        ]
    }
}
```

### 4.2 数据流转

```
用户交互 → extracted 更新 → VibeID 重新计算 → Me 页刷新

流程：
1. 用户在 Chat 中对话
2. ProfileExtractor worker 提取用户信息 → 更新 extracted
3. VibeID 监听 extracted 变化 → 触发重新计算（如果达到阈值）
4. Me 页读取最新的 VibeID 数据 → 展示更新后的融合身份
```

#### 自动更新触发机制

```python
# apps/api/workers/vibe_id_updater.py

"""
VibeID 自动更新 Worker

职责：
1. 监听 extracted 数据变化
2. 达到阈值时触发 VibeID 重新计算
3. 记录演化事件到 timeline
"""

class VibeIDUpdater:
    """VibeID 自动更新器"""

    async def check_and_update(self, user_id: UUID):
        """
        检查并更新 VibeID

        触发条件：
        1. extracted 数据新增 >= 5 条
        2. 距离上次计算 >= 30 天
        3. 发生重大人生事件
        """
        # 1. 检查是否需要更新
        if not await self._should_update(user_id):
            return

        # 2. 保存旧的 VibeID（用于对比）
        old_vibe_id = await UnifiedProfileRepository.get_skill_data(user_id, "vibe_id")

        # 3. 重新计算 VibeID
        await VibeIDService.generate(user_id, force_recalculate=True)

        # 4. 获取新的 VibeID
        new_vibe_id = await UnifiedProfileRepository.get_skill_data(user_id, "vibe_id")

        # 5. 对比变化
        changes = self._detect_changes(old_vibe_id, new_vibe_id)

        # 6. 如果有显著变化，记录到 timeline
        if changes["significant"]:
            await self._record_evolution_event(user_id, changes)

    async def _should_update(self, user_id: UUID) -> bool:
        """判断是否应该更新"""
        # 读取上次更新时间
        vibe_id = await UnifiedProfileRepository.get_skill_data(user_id, "vibe_id")
        last_update = vibe_id.get("updated_at") if vibe_id else None

        if not last_update:
            return True

        # 检查时间间隔
        last_update_dt = datetime.fromisoformat(last_update)
        days_since = (datetime.utcnow() - last_update_dt).days

        if days_since >= 30:
            return True

        # 检查 extracted 数据新增量
        # TODO: 实现 extracted 变化追踪

        return False

    def _detect_changes(
        self,
        old: Optional[Dict],
        new: Dict
    ) -> Dict[str, Any]:
        """
        检测变化

        Returns:
            {
                "significant": bool,
                "primary_archetype_changed": bool,
                "archetype_score_changes": {...},
                "confidence_change": float
            }
        """
        if not old:
            return {"significant": True, "reason": "first_calculation"}

        old_primary = old["fused"]["primary_archetype"]
        new_primary = new["fused"]["primary_archetype"]

        # 主原型变化 = 显著变化
        if old_primary != new_primary:
            return {
                "significant": True,
                "primary_archetype_changed": True,
                "old_primary": old_primary,
                "new_primary": new_primary
            }

        # 原型分数变化 > 10% = 显著变化
        old_scores = old["fused"]["archetype_scores"]
        new_scores = new["fused"]["archetype_scores"]

        max_change = max(
            abs(new_scores.get(k, 0) - old_scores.get(k, 0))
            for k in set(old_scores.keys()) | set(new_scores.keys())
        )

        if max_change > 0.1:
            return {
                "significant": True,
                "archetype_score_changes": {
                    k: new_scores.get(k, 0) - old_scores.get(k, 0)
                    for k in set(old_scores.keys()) | set(new_scores.keys())
                }
            }

        return {"significant": False}

    async def _record_evolution_event(
        self,
        user_id: UUID,
        changes: Dict
    ):
        """记录演化事件到 timeline"""
        from stores.unified_profile_repo import ColdLayerRepository

        if changes.get("primary_archetype_changed"):
            # 主原型变化
            title = f"原型演化：{changes['old_primary']} → {changes['new_primary']}"
            await ColdLayerRepository.add_timeline_event(
                user_id=user_id,
                event_type="archetype_evolution",
                event_date=date.today(),
                title=title,
                data=changes,
                skill_id="vibe_id"
            )
        elif changes.get("archetype_score_changes"):
            # 原型能量变化
            max_change_archetype = max(
                changes["archetype_score_changes"].items(),
                key=lambda x: abs(x[1])
            )
            title = f"原型能量变化：{max_change_archetype[0]} {'+' if max_change_archetype[1] > 0 else ''}{max_change_archetype[1]:.1%}"
            await ColdLayerRepository.add_timeline_event(
                user_id=user_id,
                event_type="archetype_energy_shift",
                event_date=date.today(),
                title=title,
                data=changes,
                skill_id="vibe_id"
            )
```

---

## 五、未来扩展：紫微斗数融合

### 5.1 紫微分析器接口

```python
# apps/api/skills/ziwei/analyzer.py (未来实现)

class ZiweiAnalyzer(BirthTimeAnalyzer):
    """紫微斗数分析器"""

    weight: float = 0.0  # 初期不参与融合，仅提供独立分析

    async def analyze(self, birth_info: Dict) -> AnalysisResult:
        """
        基于出生信息计算紫微命盘

        流程：
        1. 计算命宫、福德宫、官禄宫等 12 宫
        2. 安排主星、辅星
        3. 推导原型倾向
        4. 返回分析结果
        """
        # TODO: 实现紫微计算逻辑
        pass
```

### 5.2 融合策略（未来）

```yaml
# 当紫微成熟后，可调整权重

fusion_v7:
  analyzers:
    - type: bazi
      weight: 0.50  # 降低

    - type: zodiac
      weight: 0.25  # 降低

    - type: ziwei
      weight: 0.25  # 新增
      enabled: true
```

---

## 六、实施路线图

### Phase 1: VibeID v7.0 融合引擎重构（5 天）

**Day 1-2**: 架构搭建
- [ ] 创建 `fusion_engine_v7.py`
- [ ] 实现 `PluggableFusionEngine`
- [ ] 实现 `BirthTimeAnalyzer` 基类
- [ ] 实现 `BehaviorAnalyzer`

**Day 3**: 分析器迁移
- [ ] 重构 `BaziAnalyzer`（继承新基类）
- [ ] 重构 `ZodiacAnalyzer`（继承新基类）
- [ ] 创建 `JungAstroAnalyzer`（基础版）

**Day 4**: 融合逻辑
- [ ] 实现加权融合算法
- [ ] 实现一致性奖励
- [ ] 实现置信度计算
- [ ] 实现四维人格生成

**Day 5**: 测试与优化
- [ ] 单元测试
- [ ] 集成测试
- [ ] 性能优化

---

### Phase 2: Me 页超级聚合实现（4 天）

**Day 1**: 后端 BFF
- [ ] 创建 `/api/v1/me/complete` 接口
- [ ] 实现 `MePageAggregator`
- [ ] 实现 `_generate_essence()` 算法

**Day 2**: 前端组件
- [ ] 重构 `FusedIdentityCard`（包含行为来源）
- [ ] 实现 `JungAstroDimension` 组件
- [ ] 调整 `GrowthTimeline`（读取 Cold Layer）

**Day 3**: 数据流整合
- [ ] 实现 `useMePageData()` hook（调用新接口）
- [ ] 实现缓存策略
- [ ] 实现 Loading/Error 状态

**Day 4**: 测试与打磨
- [ ] E2E 测试
- [ ] 视觉打磨
- [ ] 性能优化

---

### Phase 3: 行为分析与自动更新（3 天）

**Day 1**: 行为分析
- [ ] 实现 `BehaviorAnalyzer._build_analysis_prompt()`
- [ ] 实现 `BehaviorAnalyzer.analyze_from_extracted()`
- [ ] 测试 LLM 分析质量

**Day 2**: 自动更新机制
- [ ] 创建 `VibeIDUpdater` worker
- [ ] 实现 `_should_update()` 逻辑
- [ ] 实现 `_detect_changes()` 逻辑

**Day 3**: Timeline 集成
- [ ] 实现 `_record_evolution_event()`
- [ ] 测试完整更新流程
- [ ] 调整触发阈值

---

**总工作量**：约 **12 天**

---

## 七、关键决策记录

### 决策 1: 为什么采用插件化融合引擎？

**问题**：如何支持未来扩展（紫微、六爻等）？

**决策**：插件化架构 + 配置驱动

**理由**：
1. **可扩展性**：新增系统只需实现 `BirthTimeAnalyzer` 接口
2. **灵活性**：权重可通过配置文件调整
3. **可维护性**：各系统独立，不互相影响

---

### 决策 2: 为什么行为分析不参与权重融合？

**问题**：行为分析应该如何影响最终结果？

**决策**：行为分析作为"调整量"，而非直接权重

**理由**：
1. **出生时间类 = 底层本质**：相对稳定
2. **行为交互类 = 表层表现**：容易变化
3. **调整量模式**：在底层本质基础上微调，避免过度波动

---

### 决策 3: 为什么 Me 页采用 BFF 模式？

**问题**：前端聚合 vs 后端聚合？

**决策**：后端统一接口（BFF 模式）

**理由**：
1. **单一数据源**：避免前端多次请求
2. **一致性保证**：后端统一融合逻辑
3. **缓存优化**：后端可实现跨请求缓存

---

## 八、成功指标

### 技术指标

| 指标 | 目标 |
|-----|------|
| VibeID 计算时间 | < 2s |
| Me 页加载时间 | < 1.5s |
| 融合置信度 | > 0.7 |
| 数据一致性 | 100% |

### 产品指标

| 指标 | 当前 | 目标 | 提升 |
|-----|-----|-----|-----|
| Me 页停留时长 | ~20s | **> 60s** | +200% |
| 展开率 | ~30% | **> 70%** | +133% |
| 跳转 Skill 率 | ~10% | **> 40%** | +300% |
| 用户回访率（7天）| ~20% | **> 50%** | +150% |

### 用户反馈期望

- "Me 页终于能看懂我了"
- "一句话就说清了我的本质"
- "每次打开都能发现新的洞察"
- "成长轨迹让我看到了自己的演化"

---

**文档完成时间**：2026-01-21
**设计师**：Claude Ultra Mode
**状态**：✅ Ready for Implementation

**下一步**：开始 Phase 1 实施！🚀
