# Plan: VibeID v7.0 升级 - 四维 12 原型完整实现

## 目标
1. **四维完整 12 原型**：Core/Inner/Outer/Shadow 每个维度都有 12 原型得分分布
2. **体验增强**：首次揭晓仪式感、三个特质打击点、温暖的 AI 第一句话

## 设计文档
- `docs/archive/v9/VIBEID-UPGRADE-V7.md`

---

## 一、四维 12 原型完整实现

### 现状
- Core: 有 12 原型得分（通过 `fusion_engine._fuse_scores()`）
- Inner: 只有单一 primary 原型
- Outer: 只有单一 primary 原型
- Shadow: 只有单一 primary 原型

### 升级目标
每个维度都要有完整的 12 原型得分：

```python
{
    "archetypes": {
        "core": {
            "primary": "Hero",
            "scores": {"Hero": 100, "Explorer": 45, ...}  # 12个
        },
        "inner": {
            "primary": "Caregiver",
            "scores": {"Caregiver": 100, "Lover": 60, ...}  # 12个
        },
        "outer": {
            "primary": "Outlaw",
            "scores": {"Outlaw": 100, "Magician": 55, ...}  # 12个
        },
        "shadow": {
            "primary": "Innocent",
            "scores": {"Innocent": 100, "Regular": 40, ...}  # 12个
        }
    },
    "overall_scores": {...}  # 综合 12 原型得分（现有）
}
```

### 后端改动

#### 1. fusion_engine.py - 四维得分计算

```python
# 新增方法
def _calculate_core_scores(self, bazi_scores, zodiac_scores, bazi_primary, zodiac_primary):
    """计算 Core 维度的 12 原型得分"""
    # 现有逻辑：70% bazi + 30% zodiac

def _calculate_inner_scores(self, zodiac_analysis):
    """计算 Inner 维度的 12 原型得分"""
    # 基于月亮(75%) + 金星(25%)
    scores = {arch.value: 0.0 for arch in Archetype}
    if zodiac_analysis.moon_sign:
        moon_primary = self._get_moon_archetype(zodiac_analysis.moon_sign)
        scores[moon_primary] += 0.75
    if zodiac_analysis.venus_sign:
        venus_primary = self._get_venus_archetype(zodiac_analysis.venus_sign)
        scores[venus_primary] += 0.25
    return self._normalize_scores(scores)

def _calculate_outer_scores(self, zodiac_analysis):
    """计算 Outer 维度的 12 原型得分"""
    # 基于上升(70%) + 火星(30%)

def _calculate_shadow_scores(self, core_primary):
    """计算 Shadow 维度的 12 原型得分"""
    # 阴影原型得分最高，相关对立原型次之
```

#### 2. service.py - 返回数据结构升级

```python
fusion_result = self.fusion_engine.fuse(...)

vibe_id_data = {
    "version": "7.0",
    "archetypes": {
        "core": {
            **fusion_result["archetypes"]["core"],
            "scores": fusion_result["core_scores"],  # 新增
        },
        "inner": {
            **fusion_result["archetypes"]["inner"],
            "scores": fusion_result["inner_scores"],  # 新增
        },
        "outer": {
            **fusion_result["archetypes"]["outer"],
            "scores": fusion_result["outer_scores"],  # 新增
        },
        "shadow": {
            **fusion_result["archetypes"]["shadow"],
            "scores": fusion_result["shadow_scores"],  # 新增
        },
    },
    "overall_scores": fusion_result["scores"],  # 现有的综合得分
    ...
}
```

---

## 二、体验增强

### 后端改动

#### 3. explainer.py - 新增 generate_reveal()

```python
def generate_reveal(self, archetypes, bazi_analysis, zodiac_analysis):
    return {
        "core_traits": self._generate_core_traits(archetypes["core"]["primary"]),
        "ai_first_words": self._generate_ai_first_words(...),
    }

def _generate_core_traits(self, archetype_id):
    """[优点, 优点, 隐秘恐惧]"""
    info = get_archetype_info(archetype_id)
    return info["superpowers"][:2] + [self._fear_to_trait(info["core_fear"])]
```

#### 4. handlers.py - 新增 show_vibe_id_reveal

```python
@tool_handler("show_vibe_id_reveal")
async def execute_show_vibe_id_reveal(args, context):
    """首次揭晓展示"""
```

### 前端改动

#### 5. 新建组件

| 文件 | 功能 |
|------|------|
| `VibeIDReveal.tsx` | 首次揭晓仪式（3阶段动画）|
| `CoreTraits.tsx` | 三个特质展示 |
| `FourDimensionView.tsx` | 四维展示（每个维度可展开看12原型雷达图）|
| `DimensionRadar.tsx` | 单维度12原型雷达图 |

---

## 文件清单

### 后端 (4 个)

| 文件 | 改动类型 |
|------|---------|
| `fusion_engine.py` | 修改：新增四维得分计算方法 |
| `service.py` | 修改：返回数据增加维度得分 |
| `explainer.py` | 修改：新增 generate_reveal |
| `handlers.py` | 修改：新增 show_vibe_id_reveal |

### 前端 (5 个)

| 文件 | 改动类型 |
|------|---------|
| `VibeIDReveal.tsx` | 新建 |
| `CoreTraits.tsx` | 新建 |
| `FourDimensionView.tsx` | 新建 |
| `DimensionRadar.tsx` | 新建 |
| `show-vibe-id-reveal.tsx` | 新建 |

---

## 验证

1. 计算后每个维度都有 12 原型得分
2. 前端可展示四维雷达图
3. 首次揭晓有仪式动画
4. 三个特质正确显示
5. AI 第一句话温暖个性化
