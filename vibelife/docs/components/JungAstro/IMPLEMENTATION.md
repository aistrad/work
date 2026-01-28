# JungAstro 实施步骤

## 总览

| Phase | 内容 | 预计时间 |
|-------|------|---------|
| Phase 1 | 基础结构 | Day 1 |
| Phase 2 | 规则文件 | Day 2 |
| Phase 3 | 后端工具 | Day 3 |
| Phase 4 | 前端卡片 | Day 4 |
| Phase 5 | 知识库构建 | Week 2-4 |
| Phase 6 | 测试与优化 | Week 5 |

---

## Phase 1: 基础结构 (Day 1)

### 1.1 创建目录结构

```bash
# 后端 Skill 目录
mkdir -p apps/api/skills/jungastro/{config,rules,tools,services}

# 前端组件目录
mkdir -p apps/web/src/skills/jungastro/{cards,tools,panels,components,styles}

# 知识库目录
mkdir -p /data/vibelife/knowledge/jungastro/{source,converted,extracted}
```

### 1.2 创建 SKILL.md

```bash
# 复制设计文档中的 SKILL.md 内容
cp docs/components/JungAstro/SKILL.md apps/api/skills/jungastro/SKILL.md
```

### 1.3 创建配置文件

**config/planets.yaml**
```yaml
version: "1.0"

planets:
  sun:
    symbol: "☉"
    name_en: "Sun"
    name_cn: "太阳"
    psychological_function: "核心自我、意识中心"
    jungian_concept: "Ego"
    keywords: ["身份认同", "目的感", "创造力", "活力"]

  moon:
    symbol: "☽"
    name_en: "Moon"
    name_cn: "月亮"
    psychological_function: "情感本能、无意识模式"
    jungian_concept: "Personal Unconscious"
    keywords: ["情感需求", "安全感", "内在小孩", "本能反应"]

  # ... 其他行星
```

**config/signs.yaml**
```yaml
version: "1.0"

elements:
  fire:
    name_cn: "火"
    psychological_function: "直觉"
    keywords: ["热情", "行动", "灵感", "勇气"]
  earth:
    name_cn: "土"
    psychological_function: "感觉"
    keywords: ["实际", "稳定", "感官", "物质"]
  air:
    name_cn: "风"
    psychological_function: "思维"
    keywords: ["沟通", "分析", "理念", "连接"]
  water:
    name_cn: "水"
    psychological_function: "情感"
    keywords: ["情感", "直觉", "共情", "深度"]

modalities:
  cardinal:
    name_cn: "开创"
    keywords: ["发起", "领导", "开始"]
  fixed:
    name_cn: "固定"
    keywords: ["稳定", "持续", "深化"]
  mutable:
    name_cn: "变动"
    keywords: ["适应", "灵活", "整合"]

signs:
  aries:
    symbol: "♈"
    name_cn: "白羊座"
    element: "fire"
    modality: "cardinal"
    archetype: "先驱者"
    psychological_expression: "主张个体身份、主动、通过大胆行动领导"

  # ... 其他星座
```

**config/houses.yaml**
```yaml
version: "1.0"

houses:
  1:
    name: "自我之宫"
    theme: "I am"
    psychological_domain: "身份认同"
    development_task: "建立自我形象、发展人格面具"

  # ... 其他宫位
```

**config/aspects.yaml**
```yaml
version: "1.0"

aspects:
  conjunction:
    symbol: "☌"
    name_cn: "合相"
    angle: 0
    orb: 8
    psychological_meaning: "能量融合，强化"

  square:
    symbol: "□"
    name_cn: "刑相"
    angle: 90
    orb: 6
    psychological_meaning: "内在张力，成长动力"

  # ... 其他相位
```

### 1.4 Checklist

- [ ] 创建 `apps/api/skills/jungastro/` 目录
- [ ] 创建 `SKILL.md`
- [ ] 创建 `config/planets.yaml`
- [ ] 创建 `config/signs.yaml`
- [ ] 创建 `config/houses.yaml`
- [ ] 创建 `config/aspects.yaml`
- [ ] 创建 `__init__.py`

---

## Phase 2: 规则文件 (Day 2)

### 2.1 创建规则文件

从 `docs/components/JungAstro/RULES.md` 中提取各规则文件：

```bash
# 创建规则文件
touch apps/api/skills/jungastro/rules/psychological-portrait.md
touch apps/api/skills/jungastro/rules/shadow-work.md
touch apps/api/skills/jungastro/rules/individuation.md
touch apps/api/skills/jungastro/rules/relationship-dynamics.md
```

### 2.2 Checklist

- [ ] 创建 `rules/psychological-portrait.md`
- [ ] 创建 `rules/shadow-work.md`
- [ ] 创建 `rules/individuation.md`
- [ ] 创建 `rules/relationship-dynamics.md`

---

## Phase 3: 后端工具 (Day 3)

### 3.1 创建工具定义

**tools/tools.yaml**

从 `docs/components/JungAstro/TOOLS.md` 复制工具定义。

### 3.2 实现工具执行器

**tools/handlers.py**

```python
"""
JungAstro Skill 工具执行器
"""

from typing import Dict, Any, Optional
from ..services.interpreter import JungianInterpreter
from ...zodiac.services.calculator import ZodiacCalculator

calculator = ZodiacCalculator()
interpreter = JungianInterpreter()

async def handle_show_psychological_portrait(
    user_id: str,
    focus: str = "full",
    **kwargs
) -> Dict[str, Any]:
    """展示心理画像"""
    chart = await calculator.get_natal_chart(user_id)
    portrait = interpreter.analyze_psychological_portrait(chart, focus)
    return {
        "card_type": "jungastro_portrait",
        "data": portrait
    }

# ... 其他处理函数

TOOL_HANDLERS = {
    "show_psychological_portrait": handle_show_psychological_portrait,
    "show_shadow_analysis": handle_show_shadow_analysis,
    "show_individuation_path": handle_show_individuation_path,
    "show_psychological_functions": handle_show_psychological_functions,
    "show_relationship_dynamics": handle_show_relationship_dynamics,
}
```

### 3.3 实现解读服务

**services/interpreter.py**

```python
"""
荣格心理解读器
"""

from typing import Dict, Any, Optional, List
from ..config import load_config

class JungianInterpreter:
    """荣格心理占星解读器"""

    def __init__(self):
        self.planets_config = load_config("planets")
        self.signs_config = load_config("signs")
        self.houses_config = load_config("houses")
        self.aspects_config = load_config("aspects")

    def analyze_psychological_portrait(
        self,
        chart: Dict[str, Any],
        focus: str = "full"
    ) -> Dict[str, Any]:
        """分析心理画像"""
        result = {}

        # 分析太阳 (Ego)
        result["ego"] = self._analyze_sun(chart)

        # 分析月亮 (Unconscious)
        result["unconscious"] = self._analyze_moon(chart)

        # 分析上升 (Persona)
        result["persona"] = self._analyze_rising(chart)

        # 分析心理功能分布
        result["functions"] = self._analyze_functions(chart)

        # 综合解读
        result["synthesis"] = self._synthesize_portrait(result)

        return result

    def analyze_shadow(
        self,
        chart: Dict[str, Any],
        aspect: Optional[str] = None,
        planet: Optional[str] = None
    ) -> Dict[str, Any]:
        """分析阴影"""
        result = {}

        # 识别困难相位
        result["difficult_aspects"] = self._find_difficult_aspects(chart)

        # 分析冥王星
        result["pluto_analysis"] = self._analyze_pluto(chart)

        # 分析12宫
        result["twelfth_house"] = self._analyze_twelfth_house(chart)

        # 整合建议
        result["integration_path"] = self._suggest_integration(result)

        return result

    # ... 其他分析方法
```

### 3.4 Checklist

- [ ] 创建 `tools/tools.yaml`
- [ ] 实现 `tools/handlers.py`
- [ ] 实现 `services/__init__.py`
- [ ] 实现 `services/interpreter.py`
- [ ] 实现 `services/config_loader.py`
- [ ] 注册到 ToolRegistry

---

## Phase 4: 前端卡片 (Day 4)

### 4.1 创建卡片组件

**cards/PsychologicalPortrait.tsx**

```tsx
import React from 'react';
import { Card } from '@/components/ui/Card';
import { ElementChart } from '../components/ElementChart';
import { ModalityChart } from '../components/ModalityChart';

interface PsychologicalPortraitProps {
  data: {
    ego: { planet: string; sign: string; house: number; description: string };
    unconscious: { planet: string; sign: string; house: number; description: string };
    persona: { sign: string; description: string };
    functions: {
      elements: { fire: number; earth: number; air: number; water: number };
      modalities: { cardinal: number; fixed: number; mutable: number };
      dominant: string;
      inferior: string;
    };
    synthesis: string;
  };
}

export const PsychologicalPortrait: React.FC<PsychologicalPortraitProps> = ({ data }) => {
  return (
    <Card className="jungastro-portrait">
      <div className="portrait-header">
        <h2>🧠 心理画像</h2>
        <span className="subtitle">Psychological Portrait</span>
      </div>

      <div className="portrait-section">
        <div className="section-header">
          <span className="planet-symbol">☉</span>
          <span className="section-title">核心自我 (Ego)</span>
        </div>
        <div className="section-content">
          <div className="placement">太阳 {data.ego.sign} 第{data.ego.house}宫</div>
          <p className="description">{data.ego.description}</p>
        </div>
      </div>

      {/* ... 其他部分 */}

      <div className="functions-section">
        <h3>心理功能分布</h3>
        <div className="charts-container">
          <ElementChart data={data.functions.elements} />
          <ModalityChart data={data.functions.modalities} />
        </div>
      </div>

      <div className="synthesis-section">
        <h3>💡 综合洞察</h3>
        <p>{data.synthesis}</p>
      </div>
    </Card>
  );
};
```

### 4.2 创建辅助组件

**components/ElementChart.tsx**

```tsx
import React from 'react';

interface ElementChartProps {
  data: {
    fire: number;
    earth: number;
    air: number;
    water: number;
  };
}

export const ElementChart: React.FC<ElementChartProps> = ({ data }) => {
  const elements = [
    { key: 'fire', label: '🔥 火', color: '#E85D4C' },
    { key: 'earth', label: '🌍 土', color: '#7B8B6F' },
    { key: 'air', label: '💨 风', color: '#6B9AC4' },
    { key: 'water', label: '💧 水', color: '#5B7B8B' },
  ];

  return (
    <div className="element-chart">
      <h4>元素分布</h4>
      {elements.map(({ key, label, color }) => (
        <div key={key} className="element-bar">
          <span className="element-label">{label}</span>
          <div className="bar-container">
            <div
              className="bar-fill"
              style={{
                width: `${data[key]}%`,
                backgroundColor: color
              }}
            />
          </div>
          <span className="element-value">{data[key]}%</span>
        </div>
      ))}
    </div>
  );
};
```

### 4.3 注册工具

**tools/index.ts**

```typescript
import { PsychologicalPortrait } from '../cards/PsychologicalPortrait';
import { ShadowAnalysis } from '../cards/ShadowAnalysis';
import { IndividuationPath } from '../cards/IndividuationPath';
import { PsychologicalFunctions } from '../cards/PsychologicalFunctions';
import { RelationshipDynamics } from '../cards/RelationshipDynamics';

export const jungastroTools = {
  show_psychological_portrait: {
    component: PsychologicalPortrait,
    cardType: 'jungastro_portrait',
  },
  show_shadow_analysis: {
    component: ShadowAnalysis,
    cardType: 'jungastro_shadow',
  },
  show_individuation_path: {
    component: IndividuationPath,
    cardType: 'jungastro_individuation',
  },
  show_psychological_functions: {
    component: PsychologicalFunctions,
    cardType: 'jungastro_functions',
  },
  show_relationship_dynamics: {
    component: RelationshipDynamics,
    cardType: 'jungastro_relationship',
  },
};
```

### 4.4 Checklist

- [ ] 创建 `cards/PsychologicalPortrait.tsx`
- [ ] 创建 `cards/ShadowAnalysis.tsx`
- [ ] 创建 `cards/IndividuationPath.tsx`
- [ ] 创建 `cards/PsychologicalFunctions.tsx`
- [ ] 创建 `cards/RelationshipDynamics.tsx`
- [ ] 创建 `components/ElementChart.tsx`
- [ ] 创建 `components/ModalityChart.tsx`
- [ ] 创建 `components/AspectDiagram.tsx`
- [ ] 创建 `tools/index.ts`
- [ ] 注册到 CardRegistry
- [ ] 创建样式文件 `styles/jungastro.css`

---

## Phase 5: 知识库构建 (Week 2-4)

详见 [KNOWLEDGE.md](./KNOWLEDGE.md)

### 5.1 Checklist

- [ ] 收集一级资料 (5本)
- [ ] PDF → Markdown 转换
- [ ] 切块入库
- [ ] Case 抽取 (目标: 50+)
- [ ] Scenario 抽取 (目标: 10+)
- [ ] 检索质量测试

---

## Phase 6: 测试与优化 (Week 5)

### 6.1 功能测试

```bash
# 运行单元测试
cd apps/api
pytest tests/test_jungastro.py -v

# 运行集成测试
pytest tests/test_jungastro_integration.py -v
```

### 6.2 端到端测试

测试场景：

1. **心理画像分析**
   - 输入: "帮我分析一下我的深层心理"
   - 预期: 调用 `show_psychological_portrait`���展示完整心理画像

2. **阴影分析**
   - 输入: "我的阴影是什么？"
   - 预期: 调用 `show_shadow_analysis`，展示阴影分析

3. **土星回归**
   - 输入: "我快30岁了，感觉很迷茫"
   - 预期: 调用 `show_individuation_path(cycle="saturn_return")`

4. **关系模式**
   - 输入: "为什么我总是吸引不合适的人？"
   - 预期: 调用 `show_relationship_dynamics`

### 6.3 Checklist

- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 端到端测试通过
- [ ] 性能测试通过
- [ ] 文档完善

---

## 验证清单

### 后端验证

```bash
# 1. Skill 加载测试
python -c "from services.agent import load_skill; print(load_skill('jungastro'))"

# 2. 工具注册测试
python -c "from services.agent import get_skill_tools; print(get_skill_tools('jungastro'))"

# 3. 知识检索测试
python -c "from services.knowledge import search; print(search('土星 心理功能', skill='jungastro'))"
```

### 前端验证

```bash
# 1. 组件编译测试
cd apps/web
npm run build

# 2. 类型检查
npm run type-check

# 3. 开发服务器测试
npm run dev
# 访问 http://localhost:3000 测试卡片渲染
```

### 集成验证

```bash
# 1. 启动测试环境
cd /home/aiscend/work/vibelife
docker-compose up -d

# 2. 运行 E2E 测试
npm run test:e2e -- --grep "jungastro"
```
