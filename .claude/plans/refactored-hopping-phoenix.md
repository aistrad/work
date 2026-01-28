# Onboarding UX 重构计划 - v7.0

> 基于 DESIGN.md v7.0: 共享框架 + Skill 个性化内容

---

## 核心架构

```
Landing → Loading → Chat
   ↓         ↓        ↓
 Skill 个性化内容层 (bazi/zodiac/dankoe)
```

**本期范围**: bazi, zodiac, dankoe (不含 jungastro)

---

## 关键修复

| 问题 | 当前状态 | 修复 |
|-----|---------|-----|
| LoadingStep 混合调用 | 调用 bazi + zodiac API | 仅调用当前 variant 的 API |
| 进度条起始 | 0% | 40% (Goal-Gradient) |
| BreathAura 遮挡 | z-index 问题 | z-0 + pointer-events-none |
| Landing 输入 | 水平布局 | 垂直堆叠 + 大字体 |
| dankoe 流程 | 跳过 onboarding | 直接到 Chat + 对话收集 |

---

## 文件修改清单

### P0 - 必须修改

| 文件 | 修改 |
|-----|------|
| `apps/web/src/app/onboarding/types.ts` | 新增 Skill 个性化配置类型 |
| `apps/web/src/app/onboarding/steps/LandingStep.tsx` | 1. 修复 BreathAura 层级<br>2. 添加 Curiosity Hook<br>3. 垂直输入布局<br>4. Skill 主题色 |
| `apps/web/src/app/onboarding/steps/LoadingStep.tsx` | 1. Variant-aware API 调用<br>2. 40% 起始进度<br>3. Skill 个性化步骤 |
| `apps/web/src/app/globals.css` | 新增 shimmer, pulse-slow 动画 |

### P1 - 体验优化

| 文件 | 修改 |
|-----|------|
| `apps/web/src/app/onboarding/context.tsx` | variant 切换逻辑优化 |
| `apps/web/src/app/onboarding/steps/EmbeddedChatStep.tsx` | InsightsCard, GuidanceCard 个性化 |

---

## 详细实现

### Step 1: types.ts - 类型扩展

```typescript
// 新增 Skill 个性化配置
export interface SkillOnboardingConfig {
  curiosityHook: string
  subtext: string
  loadingSteps: string[]
  glowColor: string
  icon: string
}

export const SKILL_CONFIGS: Record<'bazi' | 'zodiac' | 'dankoe', SkillOnboardingConfig> = {
  bazi: {
    curiosityHook: '🌲 你的命盘里，写着一个故事',
    subtext: '日主 · 格局 · 大运',
    loadingSteps: ['收到你的生日', '排出四柱八字', '分析日主格局', '计算大运流年', '生成命盘洞察'],
    glowColor: 'rgba(184, 134, 11, 0.12)',
    icon: '🌲',
  },
  zodiac: {
    curiosityHook: '✨ 你的星星，正在说话',
    subtext: '太阳 · 月亮 · 上升',
    loadingSteps: ['收到你的出生信息', '计算行星位置', '解读太阳星座', '解读月亮星座', '解读上升星座'],
    glowColor: 'rgba(99, 102, 241, 0.10)',
    icon: '✨',
  },
  dankoe: {
    curiosityHook: '🔥 准备好改变了吗？',
    subtext: '10 分钟 · 快速重置',
    loadingSteps: [], // 无 loading
    glowColor: 'rgba(249, 115, 22, 0.12)',
    icon: '🔥',
  },
}
```

### Step 2: LandingStep.tsx - 重构

**关键改动:**
1. BreathAura 修复: `z-0 pointer-events-none blur-3xl`
2. 添加 Curiosity Hook 组件
3. 输入区垂直堆叠
4. 使用 SKILL_CONFIGS 获取 variant 内容

```tsx
// BreathAura 修复
<div className="absolute inset-0 z-0 pointer-events-none">
  <div
    className="w-[400px] h-[400px] rounded-full blur-3xl animate-pulse-slow"
    style={{ background: `radial-gradient(circle, ${skillConfig.glowColor} 0%, transparent 70%)` }}
  />
</div>

// Curiosity Hook
<p className="text-center text-lg text-text-primary font-serif animate-fade-in">
  {skillConfig.curiosityHook}
</p>
```

### Step 3: LoadingStep.tsx - 重构

**关键改动:**
1. Variant-aware: 只调用当前 Skill API
2. 40% 起始进度 (前 2 步预完成)
3. 使用 SKILL_CONFIGS.loadingSteps

```tsx
// Variant-aware API 调用
const fetchData = async () => {
  if (variant === 'bazi') {
    await fetch(`${API_BASE}/bazi/chart`, ...)
  } else if (variant === 'zodiac') {
    await fetch(`${API_BASE}/zodiac/chart`, ...)
  }
  // dankoe 不需要 loading
}

// 40% 起始
const INITIAL_PROGRESS = 40
const progress = INITIAL_PROGRESS + ((completedSteps / totalSteps) * 60)
```

### Step 4: globals.css - 动画

```css
/* 进度条光泽 */
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

/* 呼吸光晕 */
@keyframes pulse-slow {
  0%, 100% { opacity: 0.4; transform: scale(1); }
  50% { opacity: 0.6; transform: scale(1.05); }
}
.animate-pulse-slow {
  animation: pulse-slow 4s ease-in-out infinite;
}
```

---

## 验证方法

1. **访问测试**:
   - http://localhost:8232/onboarding (默认 bazi)
   - http://localhost:8232/onboarding?variant=zodiac
   - http://localhost:8232/onboarding?variant=dankoe

2. **视觉检查**:
   - [ ] BreathAura 不遮挡输入
   - [ ] Curiosity Hook 显示正确
   - [ ] 进度条从 40% 开始
   - [ ] 前 2 步显示为已完成

3. **功能检查**:
   - [ ] bazi 只调用 /bazi/chart API
   - [ ] zodiac 只调用 /zodiac/chart API
   - [ ] dankoe 跳过 Loading 直接到 Chat

---

## 不在范围

- InsightsCard/GuidanceCard 完整实现 (P1)
- dankoe 对话收集流程 (P1)
- ConversionStep 优化
- A/B 测试追踪
