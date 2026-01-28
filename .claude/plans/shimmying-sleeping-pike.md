# Ultra Analysis Report: Skill IntroCard & 功能卡片覆盖度审计

> **分析日期**: 2026-01-21
> **分析范围**: VibeLife 所有 Skill 的 IntroCard 和功能展示卡片
> **架构版本**: V8.0 (LLM-Driven Architecture)

---

## 执行摘要

**核心发现**:
- **9个后端 Skills**: bazi, zodiac, lifecoach, jungastro, tarot, career, mindfulness, vibe_id, core
- **IntroCard 覆盖率**: 1/8 (12.5%) - 仅 lifecoach 定义了 `show_skill_intro`
- **功能卡片覆盖率**: 4/8 (50%) - bazi, zodiac, lifecoach, jungastro 有完整实现
- **缺失严重**: tarot, career, mindfulness 完全没有前端卡片实现

**架构理解**:
根据 `LLM_DRIVEN_ARCHITECTURE.md`:
- **V8 架构原则**: 完全 LLM 驱动，通过 Rule 文件和 Prompt 工程驱动行为
- **卡片展示机制**: 后端工具定义 `card_type` → 前端 CardRegistry 注册组件 → ShowCard 渲染
- **IntroCard 定位**: 作为 Skill 首次使用引导或功能介绍的通用卡片
- **Fallback 机制**: V7.1 新增通用视图降级（list, tree, table, timeline等）

---

## 详细分析

### 1. Skill IntroCard 覆盖情况

| Skill | show_skill_intro 定义 | 前端 SkillIntroCard | 备注 |
|-------|---------------------|-------------------|------|
| bazi | ✗ | - | **缺失** |
| zodiac | ✗ | - | **缺失** |
| lifecoach | ✓ | ✓ | **唯一完整实现** |
| jungastro | ✗ | - | **缺失** |
| tarot | ✗ | - | **缺失** |
| career | ✗ | - | **缺失** |
| mindfulness | ✗ | - | **缺失** |
| vibe_id | ✗ | - | **缺失** |
| core | N/A | N/A | 全局工具，不适用 |

**关键发现**:
- ✅ `SkillIntroCard` 通用组件已实现（`/apps/web/src/skills/shared/SkillIntroCard/`）
- ✅ lifecoach 是唯一定义并使用 `show_skill_intro` 工具的 skill
- ❌ 其他 7 个 skill 都没有定义 `show_skill_intro` 工具
- ❌ 缺失工具定义意味着 LLM 无法调用 IntroCard

### 2. 功能展示卡片覆盖情况

#### 2.1 bazi (八字) - ✅ 完整实现

**后端定义**:
```yaml
- bazi_chart (展示命盘)
- bazi_fortune (大运流年分析)
- bazi_kline (运势K线图)
- collect_form (收集出生信息)
```

**前端实现**:
```
✓ BaziChartCard.tsx
✓ BaziFortuneCard.tsx
✓ BaziKlineCard.tsx
✓ BaziDailyFortuneCard.tsx (额外实现)
✓ 自动注册到 CardRegistry
```

**状态**: ✅ 完整 - 所有后端定义的 card_type 都有对应前端实现

---

#### 2.2 zodiac (星座) - ✅ 完整实现

**后端定义**:
```yaml
- zodiac_chart (展示星盘)
- zodiac_transit (行运分析)
- zodiac_synastry (合盘分析)
- collect_form (收集出生信息)
```

**前端实现**:
```
✓ ZodiacChartCard.tsx
✓ ZodiacTransitCard.tsx
✓ ZodiacSynastryCard.tsx
✓ ZodiacLunarPhaseCard.tsx (额外实现，后端未定义)
✓ 自动注册到 CardRegistry
```

**状态**: ✅ 完整 - 甚至有额外的 LunarPhaseCard

---

#### 2.3 lifecoach (人生教练) - ✅ 完整实现 + IntroCard

**后端定义**:
```yaml
# V3 方法论卡片
- dankoe (Dan Koe 快速重置)
- covey (Covey 角色目标)
- yangming (王阳明心学)
- liaofan (了凡四训)

# 公用卡片
- action_plan (行动计划)
- progress_streak (进度统计)
- protocol_invitation (协议邀请)
- skill_intro (Skill介绍) ✓
```

**前端实现**:
```
✓ DankoeCard.tsx
✓ CoveyCard.tsx
✓ YangmingCard.tsx
✓ LiaofanCard.tsx
✓ ActionPlanCard.tsx
✓ ProgressStreakCard.tsx
✓ ProtocolInvitationCard.tsx
✓ ProtocolProgressCard.tsx
✓ ProtocolStepCard.tsx
✓ ProtocolCompletionCard.tsx
✓ 18个卡片（包含旧版兼容卡片）
✓ 自动注册到 CardRegistry
```

**状态**: ✅ 最完整 - 唯一实现了 IntroCard + 方法论专属卡片

---

#### 2.4 jungastro (荣格占星) - ✅ 完整实现

**后端定义**:
```yaml
- jungastro_portrait (心理画像)
- jungastro_shadow (阴影分析)
- jungastro_individuation (个体化路径)
- jungastro_functions (心理功能分布)
- jungastro_relationship (关系动力学)
- collect_form (收集出生信息)
```

**前端实现**:
```
✓ JungastroPsychologicalPortraitCard.tsx
✓ JungastroShadowAnalysisCard.tsx
✓ JungastroIndividuationPathCard.tsx
✓ JungastroPsychologicalFunctionsCard.tsx
✓ JungastroRelationshipDynamicsCard.tsx
✓ 自动注册到 CardRegistry
```

**状态**: ✅ 完整 - 所有后端定义的 card_type 都有对应前端实现

---

#### 2.5 tarot (塔罗) - ❌ 完全缺失

**后端定义**:
```yaml
- tarot_spread (塔罗牌阵)
  fallback_type: list  # V7.1 降级到列表视图
```

**前端实现**:
```
✗ 无 cards 目录
✗ 无卡片实现
✗ 依赖 fallback 通用列表视图
```

**状态**: ❌ **严重缺失** - 没有任何专用卡片实现

---

#### 2.6 career (职业) - ❌ 完全缺失

**后端定义**:
```yaml
- career_analysis (职业分析)
  fallback_type: list
- personality_profile (人格画像)
  fallback_type: list
```

**前端实现**:
```
✗ 无 cards 目录
✗ 无卡片实现
✗ 依赖 fallback 通用列表视图
```

**状态**: ❌ **严重缺失** - 没有任何专用卡片实现

---

#### 2.7 mindfulness (正念) - ❌ 完全缺失

**后端定义**:
```yaml
- practice_guide (练习引导)
- mindfulness_stats (练习统计)
- streak_celebration (连续打卡庆祝)
- emotion_check (情绪检测)
```

**前端实现**:
```
✗ 无 cards 目录
✗ 无卡片实现
✗ 后端未定义 fallback_type，可能渲染失败
```

**状态**: ❌ **严重缺失** - 没有任何专用卡片实现，且缺少 fallback 配置

---

#### 2.8 vibe_id (人格画像) - ✅ 不需处理

**后端定义**:
```yaml
- custom (vibe_id_card)
- chart (雷达图)
```

**前端实现**:
```
✓ 有 VibeIDCard 组件 (apps/web/src/skills/vibe-id/components/)
✓ 使用 show_vibe_id 工具直接调用
⚠️ 未在 CardRegistry 注册（用户确认不需要处理）
```

**状态**: ✅ **特殊实现** - 有卡片但未遵循标准注册流程，**用户确认保持现状**

---

#### 2.9 core (全局) - ✅ 通用卡片

**后端定义**:
```yaml
- collect_form (收集表单)
- question_card (提问卡片)
- skill_list (Skill列表)
- skill_recommendation (Skill推荐)
```

**前端实现**:
```
✓ CollectFormCard (通用组件)
✓ SkillListCard (边界控制)
✓ SkillRecommendationCard (推荐卡片)
✓ question_card (未实现专用组件，应使用通用form)
```

**状态**: ✅ 作为全局工具，使用通用卡片是合理的

---

## 架构洞察

### 1. IntroCard 机制分析

**现状**:
```typescript
// 前端已有完整的 SkillIntroCard 组件
/apps/web/src/skills/shared/SkillIntroCard/
├── index.tsx (主组件，支持 full/compact/mini 变体)
├── Header.tsx
├── FeatureList.tsx
├── QuickStart.tsx
├── PricingSection.tsx
├── SettingsSection.tsx
└── hooks/
    └── useSkillIntro.ts (数据获取)

// 后端仅 lifecoach 定义了工具
lifecoach/tools/tools.yaml:
  - name: show_skill_intro
    card_type: skill_intro
    parameters:
      - name: variant (full/compact/mini)
      - name: reason (展示原因)
```

**问题根源**:
1. ✅ **前端组件已就绪** - SkillIntroCard 是一个成熟的通用组件
2. ❌ **工具定义缺失** - 除 lifecoach 外，其他 skill 没有定义 `show_skill_intro` 工具
3. ❌ **LLM 无法调用** - 没有工具定义，LLM 不知道可以展示 IntroCard

**设计意图**:
从 `lifecoach/tools/tools.yaml` 的定义可见，IntroCard 的设计意图是:
- **触发场景**: 首次使用、用户问"有什么功能"、功能介绍
- **数据驱动**: 从后端 API 获取 skill 元数据、订阅状态、功能列表
- **交互能力**: 支持展开特性、发送 demo prompt、订阅管理

### 2. 卡片实现架构

**标准流程** (bazi, zodiac, lifecoach, jungastro):
```
1. 后端定义工具 (tools.yaml):
   - name: show_bazi_chart
   - card_type: bazi_chart

2. 前端创建卡片组件:
   - BaziChartCard.tsx
   - registerCard("bazi_chart", BaziChartCard)

3. 自动注册 (cards/index.ts):
   - import "./BaziChartCard"  # 导入即注册

4. ShowCard 渲染:
   - LLM 调用 show_bazi_chart
   - 后端返回 {cardType: "bazi_chart", data: {...}}
   - 前端 ShowCard 从 CardRegistry 获取组件渲染
```

**Fallback 机制** (tarot, career):
```
1. 后端定义 fallback_type:
   - card_type: tarot_spread
   - fallback_type: list

2. ShowCard 降级:
   - 如果 CardRegistry 没有 "tarot_spread"
   - 使用通用 ListView 渲染 data.items
```

**特殊实现** (vibe_id):
```
1. 直接使用自定义组件，未注册到 CardRegistry
2. 通过 show_vibe_id 工具直接调用
3. 不符合标准卡片架构，但仍可工作
```

### 3. 与 LLM-Driven 架构的关系

根据 `LLM_DRIVEN_ARCHITECTURE.md`:

**Phase 1 (路由层)**:
- LLM 使用 `activate_skill(skill_id)` 激活 skill
- **可能调用 `show_skill_intro`** (如果需要向用户介绍功能)

**Phase 2 (执行层)**:
- LLM 根据 SKILL.md + Rule.md 执行任务
- 调用 display 工具展示卡片
- **IntroCard 属于 Phase 2 的工具集**

**工具可用性** (SOP驱动):
```python
# 当前 SOP 算法 (apps/api/services/agent/core.py)
if needs_birth_info and not has_birth_info:
    return [collect_tool]  # P1: 只能收集
elif needs_compute and not has_chart_data:
    return [compute_tool]  # P2: 只能计算
else:
    return all_skill_tools  # P3+: 包含 show_skill_intro
```

**关键洞察**:
- show_skill_intro 应该在 **P3+ 阶段可用**（数据准备完成后）
- 或者作为 **P0 阶段**（首次介绍，无需数据）
- 当前实现中，show_skill_intro 没有被 SOP 特殊处理

---

## 问题识别

### P0 - 严重问题

#### 1. IntroCard 工具定义缺失
**影响范围**: 7/8 skills (除 lifecoach 外)
**问题**: LLM 无法调用 show_skill_intro，用户无法通过 AI 对话获取 Skill 介绍
**根本原因**: 工具定义未标准化到所有 skill

#### 2. 核心 Skill 无卡片实现
**影响范围**: tarot, career, mindfulness
**问题**:
- tarot, career 依赖 fallback (list视图)，体验降级
- mindfulness 缺少 fallback 配置，可能渲染失败
**根本原因**: 前端开发未完成

#### 3. ~~vibe_id 未遵循标准架构~~ (用户确认不需处理)
**影响范围**: vibe_id
**问题**: 卡片未注册到 CardRegistry，不符合 V7 卡片架构规范
**根本原因**: 特殊实现，未统一
**状态**: **用户确认保持现状，无需修改**

### P1 - 重要问题

#### 4. IntroCard 使用场景不明确
**问题**:
- 是首次使用引导？还是功能列表？
- 何时调用？P0 (介绍) 还是 P3+ (完成数据后)?
- 是否应该在 skill 列表页展示？

#### 5. 缺少统一的 Skill 元数据管理
**问题**:
- IntroCard 需要从 API 获取数据 (`/api/v1/skills/{skill_id}/intro`)
- 后端是否实现了此 API？
- Skill 的功能列表、demo prompts 等数据从哪里来？

---

## 建议方案

### 方案 A: 快速补全 (推荐)

**目标**: 最小成本让所有 skill 有基础的 IntroCard

**实施步骤**:

1. **标准化工具定义** (P0 - 1天)
   ```yaml
   # 在每个 skill/tools/tools.yaml 添加:
   display:
     - name: show_skill_intro
       description: |
         展示 Skill 介绍卡片。用于首次使用或用户想了解功能时。
       card_type: skill_intro
       when_to_call: |
         - 用户首次使用此 Skill 时
         - 用户问"这个能做什么"、"有什么功能"时
         - 用户说"介绍一下"、"帮助"时
       parameters:
         - name: variant
           type: string
           enum: [full, compact, mini]
           default: compact
         - name: reason
           type: string
           description: 展示原因
   ```

2. **补全后端 API** (P0 - 2天)
   ```python
   # apps/api/routes/skills.py
   @router.get("/skills/{skill_id}/intro")
   async def get_skill_intro(skill_id: str, user_id: str):
       """
       获取 Skill 介绍数据
       返回: {skill, subscription, settings}
       """
       # 从 SKILL.md + tools.yaml 读取元数据
       # 查询用户订阅状态
       # 返回结构化数据
   ```

3. **修复 mindfulness fallback** (P1 - 0.5天)
   ```yaml
   # mindfulness/tools/tools.yaml
   - name: show_practice_guide
     card_type: practice_guide
     fallback_type: list  # 添加降级
   ```

~~4. **统一 vibe_id 架构** (P1 - 1天)~~ (用户确认不需要)

**总计**: 3.5 天 (移除 vibe_id 项)
**覆盖率提升**: IntroCard 12.5% → 100%

---

### 方案 B: 完整实现 (理想)

**目标**: 为所有 skill 实现专用卡片，提升用户体验

**实施步骤**:

1. **执行方案 A** (4.5天)

2. **实现 tarot 专用卡片** (P1 - 3天)
   ```
   - TarotSpreadCard.tsx (牌阵可视化)
   - 卡牌翻转动画
   - 牌义解读展示
   ```

3. **实现 career 专用卡片** (P2 - 3天)
   ```
   - CareerAnalysisCard.tsx (职业方向分析)
   - PersonalityProfileCard.tsx (人格画像)
   - 雷达图/进度条可视化
   ```

4. **实现 mindfulness 专用卡片** (P2 - 4天)
   ```
   - PracticeGuideCard.tsx (分步引导，带计时器)
   - MindfulnessStatsCard.tsx (统计图表)
   - StreakCelebrationCard.tsx (庆祝动画)
   - EmotionCheckCard.tsx (情绪检测)
   ```

**总计**: 14.5 天
**覆盖率提升**: 功能卡片 50% → 100%

---

### 方案 C: 渐进优化 (折中)

**目标**: 先补全 IntroCard，逐步实现核心 skill 的专用卡片

**优先级**:
1. **P0**: 所有 skill 添加 show_skill_intro 工具定义 (1天)
2. **P0**: 实现后端 `/skills/{skill_id}/intro` API (2天)
3. **P1**: tarot 专用卡片 (3天) - 体验提升最明显
4. **P2**: mindfulness 专用卡片 (4天) - 练习引导需要交互
5. **P3**: career 可继续使用 fallback (暂缓)

**总计**: 9 天 (移除 vibe_id 项)
**覆盖率提升**: IntroCard 100%, 关键 skill 卡片补全

---

## 下一步行动

### 立即行动 (P0)

1. **补全工具定义** (1天)
   - 在 bazi, zodiac, jungastro, tarot, career, mindfulness, vibe_id 的 tools.yaml 中添加 show_skill_intro
   - 复制 lifecoach 的定义模板

2. **实现后端 API** (2天)
   - 实现 `/api/v1/skills/{skill_id}/intro` 端点
   - 从 SKILL.md + tools.yaml 解析元数据
   - 返回标准化的 IntroCard 数据结构

3. **修复 mindfulness fallback** (0.5天)
   - 为所有 mindfulness 工具添加 fallback_type

### 短期行动 (P1 - 1周内)

4. ~~**统一 vibe_id 架构**~~ (用户确认不需要)
   - ~~注册到 CardRegistry~~
   - ~~符合标准卡片流程~~

5. **实现 tarot 专用卡片** (3天)
   - TarotSpreadCard 可视化
   - 提升核心功能体验

### 中期行动 (P2 - 2周内)

6. **实现 mindfulness 专用卡片** (4天)
   - 练习引导卡片（交互式）
   - 统计和庆祝卡片

7. **评估 career 卡片优先级**
   - 调研用户使用数据
   - 决定是否投入开发

---

## 关键指标

### 当前状态
- IntroCard 覆盖率: **12.5%** (1/8)
- 功能卡片覆盖率: **50%** (4/8)
- 完全缺失卡片的 skill: **3个** (tarot, career, mindfulness)

### 方案 A 目标 (3.5天后)
- IntroCard 覆盖率: **100%** ✓
- 功能卡片覆盖率: **50%** (不变)
- 所有 skill 至少有 fallback 机制 ✓

### 方案 B 目标 (14.5天后)
- IntroCard 覆盖率: **100%** ✓
- 功能卡片覆盖率: **100%** ✓
- 所有 skill 专用卡片齐全 ✓

### 方案 C 目标 (9天后)
- IntroCard 覆盖率: **100%** ✓
- 功能卡片覆盖率: **75%** (6/8)
- 核心 skill 体验提升 ✓

---

## 未解决的问题

### 需要用户明确的问题:

1. **IntroCard 的使用场景**
   - 是首次使用的 onboarding 卡片？
   - 是 skill 列表/发现页的展示卡片？
   - 是对话中可调用的功能介绍？
   - 三者都需要？

2. **卡片开发优先级**
   - tarot, career, mindfulness 哪个更重要？
   - 基于什么标准（用户量、业务价值、体验提升）？

3. **Skill 元数据来源**
   - 功能列表、demo prompts 从哪里维护？
   - 是否需要建立 Skill Catalog 数据模型？
   - 还是直接从 SKILL.md + tools.yaml 解析？

~~4. **vibe_id 特殊架构**~~ (已确认)
   - ~~是否需要统一到标准架构？~~ **用户确认：不需要，保持现状**
   - ~~还是保持特殊实现（有历史原因）？~~

---

## 附录

### A. 完整卡片清单

```
# 已实现专用卡片 (31个)

## bazi (4个)
- BaziChartCard
- BaziFortuneCard
- BaziKlineCard
- BaziDailyFortuneCard

## zodiac (4个)
- ZodiacChartCard
- ZodiacTransitCard
- ZodiacSynastryCard
- ZodiacLunarPhaseCard

## lifecoach (18个)
- DankoeCard
- CoveyCard
- YangmingCard
- LiaofanCard
- ActionPlanCard
- ProgressStreakCard
- ProtocolInvitationCard
- ProtocolProgressCard
- ProtocolStepCard
- ProtocolCompletionCard
- LifeRoadmapCard (旧)
- RoleBalanceCard (旧)
- WeeklyRocksCard (旧)
- DailyLeversCard (旧)
- PatternInsightCard (旧)
- VisionMapCard (旧)
- IdentityDesignCard (旧)
- LifeGameCard (旧)

## jungastro (5个)
- JungastroPsychologicalPortraitCard
- JungastroShadowAnalysisCard
- JungastroIndividuationPathCard
- JungastroPsychologicalFunctionsCard
- JungastroRelationshipDynamicsCard

# 缺失专用卡片 (9个)

## tarot (1个)
- TarotSpreadCard ❌

## career (2个)
- CareerAnalysisCard ❌
- PersonalityProfileCard ❌

## mindfulness (4个)
- PracticeGuideCard ❌
- MindfulnessStatsCard ❌
- StreakCelebrationCard ❌
- EmotionCheckCard ❌

## vibe_id (2个)
- VibeIDCard ⚠️ (已实现但未注册)
- VibeIDRadarCard ⚠️ (已实现但未注册)
```

### B. 标准工具定义模板

```yaml
# skills/{skill_id}/tools/tools.yaml

display:
  - name: show_skill_intro
    description: |
      展示 Skill 介绍卡片。用于首次使用或用户想了解功能时。
      卡片包含：功能介绍、快速开始提示、订阅状态。
    type: display
    card_type: skill_intro
    when_to_call: |
      - 用户首次使用此 Skill 时
      - 用户问"这个能做什么"、"有什么功能"时
      - 用户说"介绍一下"、"帮助"时
    parameters:
      - name: variant
        type: string
        enum: [full, compact, mini]
        default: compact
        description: 卡片变体（full=完整版, compact=精简版, mini=迷你版）
      - name: reason
        type: string
        description: 展示原因（如"首次使用"、"功能介绍"）
```

### C. IntroCard API 数据结构

```typescript
// GET /api/v1/skills/{skill_id}/intro

interface SkillIntroResponse {
  skill: {
    id: string;
    name: string;
    icon: string;
    color: string;
    showcase: {
      tagline: string;
      description: string;
      demo_prompts: string[];
    };
    features: Array<{
      name: string;
      description: string;
      icon?: string;
      demo_prompt?: string;
    }>;
    pricing: {
      tier: "free" | "pro" | "vip";
      trial_messages: number;
    };
    settings?: Array<{
      key: string;
      label: string;
      type: "boolean" | "select";
      options?: Array<{value: string; label: string}>;
    }>;
    intro_card?: {
      default_sections: Array<"header" | "features" | "quickstart" | "pricing" | "settings">;
      cta_text?: string;
    };
  };
  subscription: {
    status: "subscribed" | "unsubscribed" | "trial";
    push_enabled: boolean;
    trial_messages_used: number;
  };
  settings: Record<string, any>;
  is_first_use: boolean;
}
```

---

**报告完成时间**: 2026-01-21
**分析工具**: Claude Ultra Deep Analysis Mode
**数据来源**: VibeLife 代码库 (V8.0)
**建议优先级**: 方案 A (快速补全) → 方案 C (渐进优化)
