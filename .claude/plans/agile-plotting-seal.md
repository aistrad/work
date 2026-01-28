# Skill 卡片视觉统一优化计划

## 决策
- ✅ 创建共享 CardWrapper 组件
- ✅ 统一所有 70+ 卡片样式

---

## Step 1: 创建 CardWrapper 组件

**文件**: `/apps/web/src/skills/shared/CardWrapper.tsx`

```tsx
interface CardWrapperProps {
  children: React.ReactNode;
  variant?: 'default' | 'amber' | 'orange' | 'pink' | 'cyan' | 'purple' | 'neutral';
  padding?: 'none' | 'sm' | 'md' | 'lg';
  animate?: boolean;
  className?: string;
}
```

**标准样式**:
- 圆角: `rounded-2xl`
- Padding: `p-5` (md)
- 阴影: `shadow-[var(--shadow-card)]`
- 边框: `border`
- 暗黑模式: 自动支持

---

## Step 2: 迁移卡片（按优先级）

### 高优先级 (严重问题)
| 文件 | 问题 |
|------|------|
| shared/SkillIntroCard/index.tsx | 无暗黑模式，按钮定位bug |
| shared/InsightCard.tsx | 无暗黑模式，硬编码颜色 |
| bazi/cards/BaziChartCard.tsx | 无阴影，padding小 |

### 中优先级 (shared 卡片)
- shared/CollectFormCard.tsx - 样式较好，微调
- shared/QuestionCard.tsx
- shared/ShowCard.tsx
- shared/SkillListCard.tsx
- shared/ServiceRecommendationCard.tsx

### 低优先级 (skill 专用卡片)
- zodiac/cards/* (5个)
- synastry/cards/* (9个)
- lifecoach/cards/* (18个)
- psych/cards/* (6个)
- 其他 skill 卡片

---

## Step 3: 配色方案

| Skill | Variant | Light | Dark |
|-------|---------|-------|------|
| Bazi | amber | amber-50/orange-50 | amber-950/30 |
| Zodiac | orange | orange-50/amber-50 | orange-950/30 |
| Synastry | pink | pink-50/purple-50 | pink-950/30 |
| LifeCoach | cyan | cyan-50/blue-50 | cyan-950/30 |
| Psych | purple | purple-50/indigo-50 | purple-950/30 |
| 通用 | neutral | bg-card | bg-card |

---

## 验证方案
1. `pnpm dev` 启动服务
2. Playwright 截图: 亮/暗模式各卡片效果
3. 检查控制台无样式警告

---

## 文件清单 (70+)

```
apps/web/src/skills/
├── shared/
│   ├── CardWrapper.tsx (新建)
│   ├── SkillIntroCard/index.tsx
│   ├── InsightCard.tsx
│   ├── CollectFormCard.tsx
│   ├── QuestionCard.tsx
│   ├── ShowCard.tsx
│   └── ...
├── bazi/cards/*.tsx (4)
├── zodiac/cards/*.tsx (5)
├── synastry/cards/*.tsx (9)
├── lifecoach/cards/*.tsx (18)
├── psych/cards/*.tsx (6)
├── vibe-id/*.tsx (3)
├── tarot/cards/*.tsx (1)
├── career/cards/*.tsx (2)
├── jungastro/cards/*.tsx (5)
├── mindfulness/cards/*.tsx (4)
└── vibelife-skill/cards/*.tsx (2)
```
