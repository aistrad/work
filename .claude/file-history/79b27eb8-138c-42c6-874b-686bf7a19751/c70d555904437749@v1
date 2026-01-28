# Me 页实施指南

> 快速开始：从设计到代码的完整实施步骤
> 版本：v1.0
> 日期：2026-01-21

---

## 快速开始

### 准备工作

**1. 确认依赖**

```bash
# 检查必要的依赖是否已安装
pnpm list framer-motion  # 动画库
pnpm list lucide-react   # 图标库
pnpm list tailwindcss    # 样式框架
```

**2. 创建目录结构**

```bash
# 进入项目根目录
cd /home/aiscend/work/vibelife

# 创建组件目录
mkdir -p apps/web/src/components/me/shared
mkdir -p apps/web/src/hooks
mkdir -p apps/web/src/types

# 创建后端服务目录
mkdir -p apps/api/services/me
mkdir -p apps/api/routes
```

---

## Phase 1: 数据层实施（2天）

### Step 1.1: 创建 TypeScript 类型定义

```bash
# 创建文件
touch apps/web/src/types/me-page.ts
```

```typescript
// apps/web/src/types/me-page.ts

/**
 * Me 页数据类型定义
 * 基于设计文档 ME_PAGE_DESIGN.md 第五章
 */

// ═══════════════════════════════════════════════════════════════════════════
// 融合身份数据
// ═══════════════════════════════════════════════════════════════════════════

export interface FusedIdentity {
  // 核心本质（一句话）
  essence: string;

  // 主原型（融合后）
  primaryArchetype: string;
  secondaryArchetype?: string;

  // 来源标注
  sources: {
    bazi: {
      dayMaster: string;
      pattern: string;
    };
    zodiac: {
      sun: string;
      ascendant: string;
    };
  };

  // 今日状态
  today: {
    energy: number; // 0-100
    fortuneLevel: 1 | 2 | 3 | 4 | 5;
    insight: string;
  };

  // 元数据
  meta: {
    calculatedAt: string;
    version: string;
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// 维度详情数据
// ═══════════════════════════════════════════════════════════════════════════

export interface BaziDimensionData {
  dayMaster: {
    value: string;
    insight: string;
  };
  pattern: {
    value: string;
    insight: string;
  };
  currentDayun: {
    value: string;
    insight: string;
    endYear: number;
  };
  todayFortune: {
    level: 1 | 2 | 3 | 4 | 5;
    text: string;
  };
}

export interface ZodiacDimensionData {
  sun: {
    value: string;
    insight: string;
  };
  ascendant: {
    value: string;
    insight: string;
  };
  moon?: {
    value: string;
    insight: string;
  };
  todayEnergy: {
    level: 1 | 2 | 3 | 4 | 5;
    text: string;
  };
}

export interface GrowthTimelineData {
  timeline: Array<{
    id: string;
    type: 'breakthrough' | 'evolution' | 'achievement';
    title: string;
    description: string;
    date: string;
    icon: string;
  }>;
}

export interface DimensionDetails {
  bazi: BaziDimensionData;
  zodiac: ZodiacDimensionData;
  growth: GrowthTimelineData;
}

// ═══════════════════════════════════════════════════════════════════════════
// API 响应类型
// ═══════════════════════════════════════════════════════════════════════════

export interface MePageData {
  fusedIdentity: FusedIdentity;
  dimensions: DimensionDetails;
  user: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
    isPro: boolean;
  };
}
```

### Step 1.2: 创建后端服务

```bash
# 创建文件
touch apps/api/services/me/fused_identity.py
touch apps/api/routes/me.py
```

```python
# apps/api/services/me/fused_identity.py

"""
融合身份服务
负责将 VibeID + 八字 + 星座 融合为一个统一的身份描述
"""

from typing import Dict, Any, Optional
from datetime import datetime

class FusedIdentityService:
    """融合身份服务"""

    @staticmethod
    async def generate(user_id: str) -> Dict[str, Any]:
        """
        生成融合身份数据

        Args:
            user_id: 用户 ID

        Returns:
            融合身份数据字典
        """
        # 1. 读取 VibeID
        from apps.api.skills.vibe_id.services.service import VibeIDService
        vibe_id = await VibeIDService.get_full(user_id)

        # 2. 读取八字
        from apps.api.skills.bazi.services.api import get_bazi_summary
        bazi = await get_bazi_summary(user_id)

        # 3. 读取星座
        from apps.api.skills.zodiac.services.api import get_zodiac_summary
        zodiac = await get_zodiac_summary(user_id)

        # 4. 融合生成 essence
        essence = await FusedIdentityService._generate_essence(
            vibe_id, bazi, zodiac
        )

        # 5. 计算今日状态
        today = await FusedIdentityService._calculate_today_status(
            bazi, zodiac
        )

        return {
            "essence": essence,
            "primary_archetype": vibe_id.get("primary_archetype"),
            "secondary_archetype": vibe_id.get("dimensions", {}).get("inner", {}).get("archetype"),
            "sources": {
                "bazi": {
                    "day_master": bazi.get("day_master"),
                    "pattern": bazi.get("pattern"),
                },
                "zodiac": {
                    "sun": zodiac.get("sun_sign"),
                    "ascendant": zodiac.get("ascendant"),
                },
            },
            "today": today,
            "meta": {
                "calculated_at": datetime.utcnow().isoformat(),
                "version": "v7.0",
            },
        }

    @staticmethod
    async def _generate_essence(
        vibe_id: Dict,
        bazi: Dict,
        zodiac: Dict
    ) -> str:
        """
        融合算法：生成个性化的一句话本质

        核心逻辑：
        - VibeID 提供主原型
        - 八字提供底层特质
        - 星座提供表达方式
        - 融合生成一句话
        """
        primary = vibe_id.get("primary_archetype", "探索者")
        inner = vibe_id.get("dimensions", {}).get("inner", {}).get("archetype", "创造者")

        # 从八字提取特质
        bazi_quality = FusedIdentityService._extract_bazi_quality(
            bazi.get("day_master")
        )

        # 从星座提取表达
        zodiac_expression = FusedIdentityService._extract_zodiac_expression(
            zodiac.get("sun_sign")
        )

        # 构建模板
        essence = f"{primary}的{bazi_quality}，{inner}的{zodiac_expression}"

        return essence

    @staticmethod
    def _extract_bazi_quality(day_master: Optional[str]) -> str:
        """从日主提取核心特质"""
        quality_map = {
            "甲木": "灵魂",
            "乙木": "韧性",
            "丙火": "火焰",
            "丁火": "光芒",
            "戊土": "根基",
            "己土": "包容",
            "庚金": "锋芒",
            "辛金": "精致",
            "壬水": "智慧",
            "癸水": "深度",
        }
        return quality_map.get(day_master, "本质")

    @staticmethod
    def _extract_zodiac_expression(sun_sign: Optional[str]) -> str:
        """从太阳星座提取表达方式"""
        expression_map = {
            "白羊座": "热情",
            "金牛座": "坚韧",
            "双子座": "灵动",
            "巨蟹座": "温柔",
            "狮子座": "光芒",
            "处女座": "细腻",
            "天秤座": "和谐",
            "天蝎座": "深邃",
            "射手座": "自由",
            "摩羯座": "坚毅",
            "水瓶座": "创新",
            "双鱼座": "梦想",
        }
        return expression_map.get(sun_sign, "独特")

    @staticmethod
    async def _calculate_today_status(
        bazi: Dict,
        zodiac: Dict
    ) -> Dict[str, Any]:
        """计算今日状态（能量 + 运势）"""
        # 从八字获取今日运势
        bazi_fortune = bazi.get("today_fortune", {})
        fortune_level = bazi_fortune.get("level", 3)

        # 从星座获取今日能量
        zodiac_energy = zodiac.get("today_energy", {})
        energy_level = zodiac_energy.get("level", 3)

        # 能量计算：星座权重60% + 八字权重40%
        energy = int(energy_level * 12 + fortune_level * 8)

        # 洞察融合
        insight = f"{bazi_fortune.get('text', '')} {zodiac_energy.get('text', '')}".strip()

        return {
            "energy": energy,
            "fortune_level": fortune_level,
            "insight": insight or "今日平稳，保持平常心",
        }
```

```python
# apps/api/routes/me.py

"""
Me 页 API 路由
"""

from fastapi import APIRouter, Depends
from apps.api.services.me.fused_identity import FusedIdentityService
from apps.api.dependencies import get_current_user

router = APIRouter(prefix="/api/v1/me", tags=["me"])

@router.get("/fused-identity")
async def get_fused_identity(user = Depends(get_current_user)):
    """
    获取融合身份数据

    Returns:
        融合身份数据（包含 essence、原型、来源等）
    """
    data = await FusedIdentityService.generate(user.id)
    return {"status": "success", "data": data}

@router.get("/dimension-details")
async def get_dimension_details(user = Depends(get_current_user)):
    """
    获取维度详情数据

    Returns:
        八字、星座、成长轨迹的详细数据
    """
    # TODO: 实现维度详情聚合
    # 目前返回模拟数据
    return {
        "status": "success",
        "data": {
            "bazi": {
                "day_master": {"value": "甲木", "insight": "生命能量的根基"},
                "pattern": {"value": "食神格", "insight": "创造与表达的天赋"},
                "current_dayun": {"value": "丙火", "insight": "创造力爆发期", "end_year": 2030},
                "today_fortune": {"level": 4, "text": "甲子日，水气旺盛，适合沟通学习"},
            },
            "zodiac": {
                "sun": {"value": "水瓶座", "insight": "创新思维的源泉"},
                "ascendant": {"value": "天秤座", "insight": "和谐表达的方式"},
                "today_energy": {"level": 4, "text": "水星顺行，沟通顺畅"},
            },
            "growth": {
                "timeline": [
                    {
                        "id": "1",
                        "type": "breakthrough",
                        "title": "突破时刻",
                        "description": "完成了人生重置协议",
                        "date": "2026-01-18T00:00:00Z",
                        "icon": "🌟",
                    }
                ]
            },
        },
    }
```

### Step 1.3: 注册路由

```python
# apps/api/main.py

from fastapi import FastAPI
from apps.api.routes import me  # 新增

app = FastAPI()

# 注册路由
app.include_router(me.router)  # 新增
# ... 其他路由
```

### Step 1.4: 创建前端 Hook

```bash
touch apps/web/src/hooks/useMePageData.ts
```

```typescript
// apps/web/src/hooks/useMePageData.ts

'use client';

import { useState, useEffect } from 'react';
import type { FusedIdentity, DimensionDetails } from '@/types/me-page';

export function useMePageData() {
  const [fusedIdentity, setFusedIdentity] = useState<FusedIdentity | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);

        // 并行获取两个接口
        const [identityRes, dimensionsRes] = await Promise.all([
          fetch('/api/v1/me/fused-identity'),
          fetch('/api/v1/me/dimension-details'),
        ]);

        if (!identityRes.ok || !dimensionsRes.ok) {
          throw new Error('Failed to fetch me page data');
        }

        const identityData = await identityRes.json();
        const dimensionsData = await dimensionsRes.json();

        setFusedIdentity(identityData.data);
        setDimensions(dimensionsData.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  return {
    fusedIdentity,
    dimensions,
    user: { name: '用户', isPro: false }, // TODO: 从实际 user context 获取
    loading,
    error,
  };
}
```

**验收检查**：

```bash
# 启动后端
cd apps/api
python -m uvicorn main:app --reload

# 测试 API（新终端）
curl http://localhost:8000/api/v1/me/fused-identity

# 预期输出：
# {
#   "status": "success",
#   "data": {
#     "essence": "创造者的灵魂，探索者的心",
#     ...
#   }
# }
```

---

## Phase 2: 核心视觉组件（3天）

### Step 2.1: 配置 Tailwind 配色

```javascript
// apps/web/tailwind.config.js

module.exports = {
  theme: {
    extend: {
      colors: {
        // Me 页专属配色
        vellum: {
          50: '#FDFBF7',
          100: '#F9F5ED',
          200: '#F0E9D9',
          300: '#E4D9C1',
          400: '#D4C5A6',
        },
        ink: {
          500: '#5C4A3A',
          600: '#4A3A2A',
          700: '#3A2A1A',
          800: '#2A1A0A',
        },
      },
      boxShadow: {
        'card': '0 8px 30px rgba(139, 92, 46, 0.08)',
        'card-hover': '0 12px 40px rgba(139, 92, 46, 0.12)',
      },
    },
  },
}
```

### Step 2.2: 创建原型徽章组件

```bash
touch apps/web/src/components/me/shared/ArchetypeBadge.tsx
```

```tsx
// apps/web/src/components/me/shared/ArchetypeBadge.tsx

import { cn } from '@/lib/utils';

const ARCHETYPE_EMOJIS: Record<string, string> = {
  '创造者': '🎨',
  '探索者': '🧭',
  '智者': '📚',
  '英雄': '⚔️',
  '统治者': '👑',
  '叛逆者': '⚡',
  '魔法师': '✨',
  '凡人': '🤝',
  '情人': '💖',
  '愚者': '🎭',
  '照顾者': '🤗',
  '天真者': '🌸',
};

export function ArchetypeBadge({
  archetype,
  variant = 'primary'
}: {
  archetype: string;
  variant?: 'primary' | 'secondary';
}) {
  const isPrimary = variant === 'primary';
  const emoji = ARCHETYPE_EMOJIS[archetype] || '✨';

  return (
    <div className={cn(
      "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full",
      "text-sm font-medium",
      isPrimary ? [
        "bg-gradient-to-r from-amber-100/80 to-orange-100/60",
        "text-amber-800",
        "border border-amber-200/50"
      ] : [
        "bg-gradient-to-r from-blue-50/80 to-purple-50/60",
        "text-blue-700",
        "border border-blue-200/40"
      ]
    )}>
      <span className={isPrimary ? "text-amber-600" : "text-blue-500"}>
        {emoji}
      </span>
      <span>{archetype}</span>
    </div>
  );
}
```

### Step 2.3: 创建融合身份卡片

```bash
touch apps/web/src/components/me/FusedIdentityCard.tsx
```

**完整代码见设计文档 `ME_PAGE_DESIGN.md` 第 3.1 节**

### Step 2.4: 创建共享组件

```bash
touch apps/web/src/components/me/shared/DataRow.tsx
touch apps/web/src/components/me/shared/DimensionCard.tsx
```

**完整代码见设计文档 `ME_PAGE_DESIGN.md` 第 3.4 节**

**验收检查**：

```bash
# 启动开发服务器
cd apps/web
pnpm dev

# 访问 Storybook（如果有）或创建测试页面
# http://localhost:3000/test/me-components

# 检查清单：
# - [ ] 融合身份卡片渲染正确
# - [ ] 徽章颜色符合设计稿
# - [ ] 羊皮纸渐变背景显示正常
# - [ ] 动画流畅（展开/折叠）
```

---

## Phase 3: 维度详情组件（2天）

### Step 3.1: 创建八字维度组件

```bash
touch apps/web/src/components/me/BaziDimension.tsx
```

```tsx
// apps/web/src/components/me/BaziDimension.tsx

import { ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { BaziDimensionData } from '@/types/me-page';
import { DataRow } from './shared/DataRow';

export function BaziDimension({
  data,
  onAnalyze
}: {
  data: BaziDimensionData;
  onAnalyze: () => void;
}) {
  const fortuneStars = '⭐'.repeat(data.todayFortune.level);

  return (
    <div className={cn(
      "p-5 rounded-xl",
      "bg-gradient-to-br from-amber-50/50 to-orange-50/50",
      "border border-amber-200/30",
      "shadow-card"
    )}>

      {/* 标题 */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <span className="text-2xl">🌙</span>
          <h3 className="font-serif text-lg font-semibold text-foreground">
            八字维度
          </h3>
        </div>
        <span className="text-xs text-muted-foreground px-2 py-1 bg-white/50 rounded-full">
          我的底层密码
        </span>
      </div>

      {/* 数据行 */}
      <dl className="space-y-2 mb-4">
        <DataRow
          label="日主"
          value={data.dayMaster.value}
          insight={data.dayMaster.insight}
        />
        <DataRow
          label="格局"
          value={data.pattern.value}
          insight={data.pattern.insight}
        />
        <DataRow
          label="当前大运"
          value={data.currentDayun.value}
          insight={`${data.currentDayun.insight}（至${data.currentDayun.endYear}）`}
        />
      </dl>

      {/* 今日运势 */}
      <div className="p-3 rounded-lg bg-amber-50/50 border border-amber-200/30 mb-3">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-xs font-medium text-amber-700">今日运势</span>
          <span className="text-sm">{fortuneStars}</span>
        </div>
        <p className="text-sm text-ink-700 leading-relaxed">
          {data.todayFortune.text}
        </p>
      </div>

      {/* CTA */}
      <button
        onClick={onAnalyze}
        className="w-full flex items-center justify-center gap-1 py-2 text-sm text-amber-700 hover:text-amber-800 font-medium transition-colors group"
      >
        <span>深度分析</span>
        <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
      </button>
    </div>
  );
}
```

### Step 3.2: 创建星座维度组件

```bash
touch apps/web/src/components/me/ZodiacDimension.tsx
```

**代码结构类似 BaziDimension，将主题色改为紫色系**

### Step 3.3: 创建成长轨迹组件

```bash
touch apps/web/src/components/me/GrowthTimeline.tsx
```

```tsx
// apps/web/src/components/me/GrowthTimeline.tsx

import { ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { GrowthTimelineData } from '@/types/me-page';

function TimelineNode({
  icon,
  title,
  description,
  date
}: {
  icon: string;
  title: string;
  description: string;
  date: string;
}) {
  const relativeDate = formatRelativeDate(date);

  return (
    <div className="flex gap-3">
      {/* 图标 */}
      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-xl flex-shrink-0">
        {icon}
      </div>

      {/* 内容 */}
      <div className="flex-1">
        <div className="flex items-center justify-between mb-1">
          <h4 className="text-sm font-medium text-foreground">{title}</h4>
          <span className="text-xs text-muted-foreground">{relativeDate}</span>
        </div>
        <p className="text-sm text-ink-600/80 leading-relaxed">
          {description}
        </p>
      </div>
    </div>
  );
}

export function GrowthTimeline({
  data,
  onReview
}: {
  data: GrowthTimelineData;
  onReview: () => void;
}) {
  return (
    <div className={cn(
      "p-5 rounded-xl",
      "bg-gradient-to-br from-blue-50/50 to-cyan-50/50",
      "border border-blue-200/30",
      "shadow-card"
    )}>

      {/* 标题 */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-2xl">🌱</span>
        <h3 className="font-serif text-lg font-semibold text-foreground">
          成长轨迹
        </h3>
      </div>

      {/* 时间线节点（最近3个）*/}
      <div className="space-y-3 mb-4">
        {data.timeline.slice(0, 3).map((node) => (
          <TimelineNode key={node.id} {...node} />
        ))}
      </div>

      {/* CTA */}
      <button
        onClick={onReview}
        className="w-full flex items-center justify-center gap-1 py-2 text-sm text-blue-700 hover:text-blue-800 font-medium transition-colors group"
      >
        <span>查看完整旅程</span>
        <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
      </button>
    </div>
  );
}

function formatRelativeDate(isoDate: string): string {
  const date = new Date(isoDate);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return '今天';
  if (diffDays === 1) return '昨天';
  if (diffDays < 7) return `${diffDays}天前`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)}周前`;
  return `${Math.floor(diffDays / 30)}个月前`;
}
```

---

## Phase 4: 页面整合（1天）

### Step 4.1: 创建维度详情容器

```bash
touch apps/web/src/components/me/DimensionDetails.tsx
```

```tsx
// apps/web/src/components/me/DimensionDetails.tsx

'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { BaziDimension } from './BaziDimension';
import { ZodiacDimension } from './ZodiacDimension';
import { GrowthTimeline } from './GrowthTimeline';
import type { DimensionDetails as DimensionDetailsType } from '@/types/me-page';

export function DimensionDetails({
  expanded,
  data,
  onBaziAnalyze,
  onZodiacAnalyze,
  onGrowthReview
}: {
  expanded: boolean;
  data: DimensionDetailsType | null;
  onBaziAnalyze: () => void;
  onZodiacAnalyze: () => void;
  onGrowthReview: () => void;
}) {
  if (!data) return null;

  return (
    <AnimatePresence>
      {expanded && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: 'auto', opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          transition={{
            duration: 0.4,
            ease: [0.4, 0, 0.2, 1]
          }}
          className="overflow-hidden space-y-4"
        >
          <BaziDimension data={data.bazi} onAnalyze={onBaziAnalyze} />
          <ZodiacDimension data={data.zodiac} onAnalyze={onZodiacAnalyze} />
          <GrowthTimeline data={data.growth} onReview={onGrowthReview} />
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

### Step 4.2: 创建主页面组件

```bash
touch apps/web/src/components/me/MePage.tsx
```

```tsx
// apps/web/src/components/me/MePage.tsx

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useMePageData } from '@/hooks/useMePageData';
import { FusedIdentityCard } from './FusedIdentityCard';
import { DimensionDetails } from './DimensionDetails';
import { UserInfoCard } from './UserInfoCard';
import { SettingsSection } from './SettingsSection';
import { MePageSkeleton } from './MePageSkeleton';

export function MePage() {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const { fusedIdentity, dimensions, user, loading, error } = useMePageData();

  if (loading) return <MePageSkeleton />;
  if (error) return <div>Error: {error}</div>;
  if (!fusedIdentity || !dimensions) return <div>No data</div>;

  return (
    <div className="me-page h-full overflow-y-auto p-5 space-y-5">

      {/* Layer 0: 用户信息 */}
      <UserInfoCard user={user} />

      {/* Layer 1: 融合身份卡片 */}
      <FusedIdentityCard
        data={fusedIdentity}
        expanded={expanded}
        onToggle={() => setExpanded(!expanded)}
      />

      {/* Layer 2: 维度详情（展开层）*/}
      <DimensionDetails
        expanded={expanded}
        data={dimensions}
        onBaziAnalyze={() => router.push('/chat?skill=bazi&prompt=详细分析我的八字')}
        onZodiacAnalyze={() => router.push('/chat?skill=zodiac&prompt=分析我的星盘')}
        onGrowthReview={() => router.push('/chat?skill=lifecoach&prompt=回顾成长')}
      />

      {/* Layer 3: 设置（折叠）*/}
      <SettingsSection />

    </div>
  );
}
```

### Step 4.3: 更新路由

```tsx
// apps/web/src/app/page.tsx (或在 AppShell 的 MePanel 中)

import { MePage } from '@/components/me/MePage';

export default function Page() {
  return <MePage />;
}
```

---

## Phase 5: 打磨优化（1天）

### Step 5.1: 添加骨架屏

```bash
touch apps/web/src/components/me/MePageSkeleton.tsx
```

```tsx
// apps/web/src/components/me/MePageSkeleton.tsx

export function MePageSkeleton() {
  return (
    <div className="me-page h-full overflow-y-auto p-5 space-y-5 animate-pulse">
      {/* 用户卡片骨架 */}
      <div className="h-24 bg-vellum-100 rounded-xl" />

      {/* 融合身份卡片骨架 */}
      <div className="h-64 bg-gradient-to-br from-vellum-50 to-vellum-100 rounded-2xl" />
    </div>
  );
}
```

### Step 5.2: 性能优化

```tsx
// 使用 React.memo 优化组件
import { memo } from 'react';

export const BaziDimension = memo(function BaziDimension({ data, onAnalyze }) {
  // ...
});

// 使用 useMemo 缓存计算
const fortuneStars = useMemo(
  () => '⭐'.repeat(data.todayFortune.level),
  [data.todayFortune.level]
);
```

### Step 5.3: 可访问性

```tsx
// 添加 ARIA 标签
<button
  onClick={onToggle}
  aria-expanded={expanded}
  aria-label={expanded ? '收起详情' : '展开详情'}
>
  {expanded ? '收起' : '探索更多维度'}
</button>

// 添加键盘导航
<div
  role="button"
  tabIndex={0}
  onKeyDown={(e) => e.key === 'Enter' && onAnalyze()}
  onClick={onAnalyze}
>
  深度分析
</div>
```

---

## 验收清单

### 功能完整性

- [ ] API 返回正确的融合身份数据
- [ ] 融合身份卡片渲染正确
- [ ] 展开/折叠动画流畅
- [ ] 三个维度卡片（八字、星座、成长）显示正确
- [ ] 点击"深度分析"正确跳转到 Chat 页
- [ ] 加载态/空态/错误态处理完善

### 视觉还原度

- [ ] 羊皮纸质感正确（渐变背景）
- [ ] 原型徽章颜色符合设计稿
- [ ] 文字渐变效果正确
- [ ] 阴影层次清晰
- [ ] 移动端适配完成

### 性能指标

- [ ] Lighthouse 性能评分 > 90
- [ ] 首屏加载时间 < 2s
- [ ] 动画帧率稳定 60fps
- [ ] 无内存泄漏

### 可访问性

- [ ] 键盘导航可用
- [ ] ARIA 标签完整
- [ ] 颜色对比度符合 WCAG AA 标准
- [ ] 屏幕阅读器友好

---

## 常见问题

### Q1: 融合算法生成的文案太模板化怎么办？

**A**: 可以考虑使用 LLM 动态生成。修改 `_generate_essence` 方法：

```python
async def _generate_essence(vibe_id, bazi, zodiac) -> str:
    # 调用 LLM 生成个性化文案
    prompt = f"""
    用户的特征：
    - 主原型：{vibe_id.primary_archetype}
    - 八字日主：{bazi.day_master}
    - 太阳星座：{zodiac.sun_sign}

    请生成一句话（不超过15字）描述用户的本质，要求：
    1. 有诗意和美感
    2. 不使用模板化语言
    3. 体现个性化
    """
    essence = await call_llm(prompt)
    return essence
```

### Q2: 动画卡顿怎么优化？

**A**: 检查以下几点：
1. 使用 `will-change` CSS 属性
2. 避免在动画期间修改 layout
3. 使用 `transform` 和 `opacity` 而非 `height`

```tsx
<motion.div
  style={{ willChange: 'transform, opacity' }}
  initial={{ transform: 'scaleY(0)', opacity: 0 }}
  animate={{ transform: 'scaleY(1)', opacity: 1 }}
>
```

### Q3: 如何快速测试组件？

**A**: 创建独立测试页面：

```tsx
// apps/web/src/app/test/me/page.tsx

import { FusedIdentityCard } from '@/components/me/FusedIdentityCard';

const mockData = {
  essence: "创造者的灵魂，探索者的心",
  primaryArchetype: "创造者",
  secondaryArchetype: "探索者",
  // ... 更多模拟数据
};

export default function TestPage() {
  return (
    <div className="p-10">
      <FusedIdentityCard
        data={mockData}
        expanded={false}
        onToggle={() => console.log('toggle')}
      />
    </div>
  );
}
```

---

**下一步**：开始 Phase 1 实施！🚀
