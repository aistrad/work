# VibeID v7.0 升级设计

> **升级策略**：在现有 VibeID v6.0 基础上增强体验层，不造新概念
> **核心目标**：让首次揭晓有仪式感，让四维展示更完整

---

## 一、现状盘点

### 1.1 已有能力 (v6.0)

| 模块 | 文件 | 状态 |
|------|------|------|
| 四维计算 | `fusion_engine.py` | ✅ Core/Inner/Outer/Shadow 完整 |
| 八字分析 | `bazi_analyzer.py` | ✅ 格局×用神→原型 |
| 星座分析 | `zodiac_analyzer.py` | ✅ 五点模型→原型 |
| 可解释性 | `explainer.py` | ✅ 但偏分析报告风格 |
| 前端卡片 | `VibeIDCard.tsx` | ✅ 但只强调 Core |
| 12原型数据 | `archetype_metadata.yaml` | ✅ 完整 |

### 1.2 体验缺口

| 缺口 | 问题 | 目标 |
|------|------|------|
| 首次揭晓无仪式感 | 计算完直接展示结果 | 3-5秒仪式动画 |
| 三个特质没有打击点 | superpowers 是优点列表 | 优点+优点+隐秘恐惧 |
| AI 第一句话偏冷 | "你的核心原型是..." | "我看到你是..." |
| 四维展示弱化 | 前端只强调 Core | 四维平等展示 |

---

## 二、升级方案

### 2.1 后端升级

#### 2.1.1 Explainer 增强

**文件**: `apps/api/skills/vibe_id/services/explainer.py`

新增方法：`generate_reveal()`

```python
def generate_reveal(
    self,
    archetypes: Dict[str, Any],
    bazi_analysis: Optional[BaziAnalysis],
    zodiac_analysis: Optional[ZodiacAnalysis]
) -> Dict[str, Any]:
    """
    生成首次揭晓内容

    Returns:
        {
            "core_traits": ["不服输", "追求卓越", "害怕平庸"],
            "ai_first_words": "我看到你是一个英雄...",
            "four_dimensions": {
                "core": {...},
                "inner": {...},
                "outer": {...},
                "shadow": {...}
            }
        }
    """
```

**三个核心特质的生成规则**：

```python
def _generate_core_traits(self, archetype_id: str) -> List[str]:
    """
    生成三个核心特质

    规则：
    - 前两个：从 superpowers 取前两个
    - 第三个：从 core_fear 转换为特质形式

    示例：
    Hero:
      superpowers: [勇气, 决心, 执行力]
      core_fear: 害怕软弱或无能
    → ["不服输", "追求卓越", "害怕平庸"]
    """
    info = get_archetype_info(archetype_id)
    superpowers = info.get("superpowers", [])[:2]

    # 转换 core_fear 为特质
    fear = info.get("core_fear", "")
    fear_trait = self._fear_to_trait(fear)

    return superpowers + [fear_trait]

def _fear_to_trait(self, fear: str) -> str:
    """将恐惧转换为特质形式"""
    # "害怕软弱或无能" → "害怕平庸"
    # "害怕被困住" → "害怕一成不变"
    fear_mapping = {
        "害怕软弱或无能": "害怕平庸",
        "害怕空虚或被困住": "害怕被困住",
        "害怕无知或被欺骗": "害怕看不透",
        "害怕受到惩罚或伤害": "害怕被伤害",
        "害怕无力或被控制": "害怕失去控制",
        "害怕意外的负面后果": "害怕失控",
        "害怕被排斥或孤立": "害怕被排斥",
        "害怕孤独或不被爱": "害怕不被爱",
        "害怕无聊或被忽视": "害怕被忽视",
        "害怕自私或被需要": "害怕被依赖",
        "害怕平庸或无意义": "害怕平庸",
        "害怕混乱或失控": "害怕混乱",
    }
    return fear_mapping.get(fear, fear)
```

**AI 第一句话的生成**：

```python
def _generate_ai_first_words(
    self,
    archetypes: Dict[str, Any],
    bazi_analysis: Optional[BaziAnalysis],
    zodiac_analysis: Optional[ZodiacAnalysis]
) -> str:
    """
    生成温暖的 AI 第一句话

    模板：
    「我看到你是一个{原型昵称}。

    你的八字{格局简述}，{核心驱动描述}。
    {星座补充}。

    但我也看到，你内心深处{隐秘恐惧}。
    别担心，这是你的引擎，不是你的软弱。」
    """
    core = archetypes.get("core", {})
    primary = core.get("primary", "Regular")
    info = get_archetype_info(primary)

    nickname = info.get("nickname", "")
    core_drive = info.get("core_drive", "")
    core_fear = info.get("core_fear", "")

    # 构建第一句话
    parts = []

    # 开场
    parts.append(f"我看到你是一个{nickname}。")
    parts.append("")

    # 八字描述
    if bazi_analysis:
        parts.append(
            f"你的八字是「{bazi_analysis.pattern}」，{bazi_analysis.archetype_driver}。"
        )

    # 星座补充
    if zodiac_analysis and zodiac_analysis.sun_sign:
        parts.append(
            f"你的太阳{zodiac_analysis.sun_sign}，让这份{core_drive}更加鲜明。"
        )

    # 隐秘恐惧
    parts.append("")
    parts.append(f"但我也看到，你内心深处{core_fear.replace('害怕', '有一个隐秘的恐惧——')}。")
    parts.append("别担心，这是你的引擎，不是你的软弱。")

    return "\n".join(parts)
```

#### 2.1.2 Service 升级

**文件**: `apps/api/skills/vibe_id/services/service.py`

在 `calculate()` 返回结果中增加 `reveal` 字段：

```python
# 7. 构建结果
vibe_id_data = {
    "version": "7.0",
    "calculated_at": datetime.now(timezone.utc).isoformat(),
    "archetypes": fusion_result["archetypes"],
    "scores": fusion_result["scores"],
    "explanation": explanation,

    # v7.0 新增：首次揭晓内容
    "reveal": self.explainer.generate_reveal(
        archetypes=fusion_result["archetypes"],
        bazi_analysis=bazi_analysis,
        zodiac_analysis=zodiac_analysis
    ),

    "source_versions": {
        "bazi": bazi_data.get("version") or bazi_data.get("calculated_at"),
        "zodiac": zodiac_data.get("version") or zodiac_data.get("calculated_at"),
    }
}
```

#### 2.1.3 Tools 新增

**文件**: `apps/api/skills/vibe_id/tools/handlers.py`

新增 `show_vibe_id_reveal` 工具：

```python
@tool_handler("show_vibe_id_reveal")
async def execute_show_vibe_id_reveal(args: Dict[str, Any], context: ToolContext) -> Dict[str, Any]:
    """
    展示 VibeID 首次揭晓（带仪式感）

    与 show_vibe_id 的区别：
    - 包含三个核心特质
    - 包含 AI 第一句话
    - 前端使用仪式动画
    """
    # ... 获取 vibe_id_data

    reveal = vibe_id_data.get("reveal", {})

    return await ToolRegistry.execute(
        "show_card",
        {
            "card_type": "custom",
            "data_source": {
                "type": "inline",
                "data": {
                    "archetypes": vibe_id_data.get("archetypes"),
                    "reveal": reveal,
                }
            },
            "options": {
                "componentId": "vibe_id_reveal",
                "animation": "reveal"  # 告诉前端使用揭晓动画
            }
        },
        context
    )
```

**文件**: `apps/api/skills/vibe_id/tools/tools.yaml`

```yaml
# v7.0 新增
- name: show_vibe_id_reveal
  description: 展示 VibeID 首次揭晓（带仪式感动画）
  type: display
  parameters:
    type: object
    properties: {}
  triggers:
    - 首次计算完成后自动调用
```

---

### 2.2 前端升级

#### 2.2.1 新增揭晓组件

**文件**: `apps/web/src/skills/vibe-id/components/VibeIDReveal.tsx`

```tsx
/**
 * VibeID 首次揭晓组件
 *
 * 特点：
 * - 仪式感动画（3-5秒）
 * - 原型图腾揭晓
 * - 三个核心特质
 * - AI 第一句话
 */

interface VibeIDRevealProps {
  data: {
    archetypes: FourDimensionalArchetypes;
    reveal: {
      core_traits: [string, string, string];
      ai_first_words: string;
    };
  };
  onComplete?: () => void;
}

export function VibeIDReveal({ data, onComplete }: VibeIDRevealProps) {
  const [phase, setPhase] = useState<'calculating' | 'revealing' | 'complete'>('calculating');

  // 阶段 1：命盘计算动画 (2秒)
  // 阶段 2：原型揭晓 (1秒)
  // 阶段 3：完成

  return (
    <div className="vibe-id-reveal">
      {phase === 'calculating' && (
        <CalculatingAnimation />
      )}

      {phase === 'revealing' && (
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
        >
          {/* 原型图腾 */}
          <ArchetypeTotem archetype={data.archetypes.core.primary} />

          {/* 三个核心特质 */}
          <CoreTraits traits={data.reveal.core_traits} />
        </motion.div>
      )}

      {phase === 'complete' && (
        <div className="space-y-4">
          {/* AI 第一句话 */}
          <AIFirstWords text={data.reveal.ai_first_words} />

          {/* 四维概览 */}
          <FourDimensionOverview archetypes={data.archetypes} />

          {/* 深入探索按钮 */}
          <button onClick={onComplete}>
            探索我的四维人格 →
          </button>
        </div>
      )}
    </div>
  );
}
```

#### 2.2.2 三个核心特质组件

**文件**: `apps/web/src/skills/vibe-id/components/CoreTraits.tsx`

```tsx
/**
 * 三个核心特质
 *
 * 前两个是优点（绿色/蓝色）
 * 第三个是隐秘恐惧（琥珀色，带微光）
 */

interface CoreTraitsProps {
  traits: [string, string, string];
}

export function CoreTraits({ traits }: CoreTraitsProps) {
  return (
    <div className="flex justify-center gap-4 mt-6">
      {/* 优点 1 */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="px-4 py-2 bg-emerald-50 text-emerald-700 rounded-full text-sm font-medium"
      >
        {traits[0]}
      </motion.div>

      {/* 优点 2 */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="px-4 py-2 bg-sky-50 text-sky-700 rounded-full text-sm font-medium"
      >
        {traits[1]}
      </motion.div>

      {/* 隐秘恐惧 */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="px-4 py-2 bg-amber-50 text-amber-700 rounded-full text-sm font-medium
                   shadow-[0_0_12px_rgba(245,158,11,0.3)]"
      >
        {traits[2]}
      </motion.div>
    </div>
  );
}
```

#### 2.2.3 四维展示增强

**文件**: `apps/web/src/skills/vibe-id/components/FourDimensionView.tsx`

```tsx
/**
 * 四维人格完整展示
 *
 * 平等展示 Core/Inner/Outer/Shadow
 */

interface FourDimensionViewProps {
  archetypes: FourDimensionalArchetypes;
  expanded?: boolean;
}

export function FourDimensionView({ archetypes, expanded = false }: FourDimensionViewProps) {
  const dimensions = [
    {
      key: 'core',
      label: '本质',
      sublabel: '最深层的你',
      icon: '🔥',
      data: archetypes.core,
      color: 'from-red-400 to-orange-500',
    },
    {
      key: 'inner',
      label: '内在',
      sublabel: '情感世界',
      icon: '🌙',
      data: archetypes.inner,
      color: 'from-purple-400 to-indigo-500',
    },
    {
      key: 'outer',
      label: '外在',
      sublabel: '社交面具',
      icon: '⚡',
      data: archetypes.outer,
      color: 'from-cyan-400 to-blue-500',
    },
    {
      key: 'shadow',
      label: '阴影',
      sublabel: '成长潜能',
      icon: '💎',
      data: archetypes.shadow,
      color: 'from-slate-400 to-zinc-500',
    },
  ];

  return (
    <div className="grid grid-cols-2 gap-3">
      {dimensions.map((dim) => (
        <DimensionCard
          key={dim.key}
          label={dim.label}
          sublabel={dim.sublabel}
          icon={dim.icon}
          archetype={dim.data.primary}
          confidence={dim.data.confidence}
          color={dim.color}
          expanded={expanded}
        />
      ))}
    </div>
  );
}
```

---

### 2.3 SKILL.md 更新

**文件**: `apps/api/skills/vibe_id/SKILL.md`

```yaml
---
id: vibe_id
name: VibeID 人格画像
version: 7.0.0  # 升级版本
# ... 其他不变
---

## 工具使用规则

### 首次计算 VibeID

当用户**首次**计算 VibeID 时：

1. 调用 `calculate_vibe_id`
2. 调用 `show_vibe_id_reveal`  ← v7.0 新增：使用揭晓展示

### 查看已有 VibeID

当用户**再次**查看 VibeID 时：

1. 调用 `show_vibe_id`（不使用揭晓动画）

### 工具列表

| 工具 | 类型 | 用途 | 版本 |
|-----|------|------|------|
| calculate_vibe_id | compute | 计算四维人格画像 | v6.0 |
| show_vibe_id | display | 展示人格画像卡片 | v6.0 |
| show_vibe_id_reveal | display | 首次揭晓（带仪式感） | **v7.0** |
| show_archetype_radar | display | 展示12原型雷达图 | v6.0 |
| get_archetype_info | compute | 获取原型详细信息 | v6.0 |
```

---

## 三、数据结构

### 3.1 v7.0 VibeID 数据

```typescript
interface VibeIDData {
  version: "7.0";
  calculated_at: string;

  // 四维原型（保持不变）
  archetypes: {
    core: DimensionArchetype;
    inner: DimensionArchetype;
    outer: DimensionArchetype;
    shadow: DimensionArchetype;
  };

  // 12原型得分（保持不变）
  scores: Record<string, number>;

  // 可解释性（保持不变）
  explanation: Explanation;

  // v7.0 新增：首次揭晓内容
  reveal: {
    core_traits: [string, string, string];  // [优点, 优点, 隐秘恐惧]
    ai_first_words: string;                 // 温暖的 AI 第一句话
    four_dimensions_summary: string;        // 四维概述
  };

  source_versions: {
    bazi: string;
    zodiac: string;
  };
}
```

---

## 四、用户体验流程

### 4.1 首次计算

```
用户: 「分析我的人格」
         ↓
LLM 调用 calculate_vibe_id
         ↓
后端计算 + 生成 reveal 内容
         ↓
LLM 调用 show_vibe_id_reveal  ← 首次用揭晓展示
         ↓
前端展示：
  Phase 1: 命盘计算动画 (2秒)
  Phase 2: 原型图腾揭晓 (1秒)
           + 三个核心特质淡入
  Phase 3: AI 第一句话 + 四维概览
```

### 4.2 再次查看

```
用户: 「我的人格是什么」
         ↓
LLM 调用 show_vibe_id  ← 非首次，直接展示
         ↓
前端展示 VibeIDCard（无揭晓动画）
```

---

## 五、实施清单

### 后端

- [ ] `explainer.py`: 新增 `generate_reveal()` 方法
- [ ] `explainer.py`: 新增 `_generate_core_traits()` 方法
- [ ] `explainer.py`: 新增 `_generate_ai_first_words()` 方法
- [ ] `service.py`: 在返回数据中增加 `reveal` 字段
- [ ] `handlers.py`: 新增 `show_vibe_id_reveal` 工具
- [ ] `tools.yaml`: 注册新工具
- [ ] `SKILL.md`: 更新版本和工具文档

### 前端

- [ ] `VibeIDReveal.tsx`: 首次揭晓组件
- [ ] `CoreTraits.tsx`: 三个核心特质组件
- [ ] `FourDimensionView.tsx`: 四维展示增强
- [ ] `show-vibe-id-reveal.tsx`: 揭晓工具卡片
- [ ] `index.ts`: 导出新组件

---

## 六、不变的部分

以下保持不变，确保向后兼容：

- 四维计算算法 (`fusion_engine.py`)
- 八字/星座分析器
- 12原型元数据
- 现有的 `show_vibe_id` 工具
- 现有的 `VibeIDCard` 组件
- 数据存储结构（只增加 `reveal` 字段）


resend
apikey： re_4uPXyW72_3htvzoG7T5bYHYvb29iGeB7p