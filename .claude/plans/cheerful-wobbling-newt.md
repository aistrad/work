# VibeLife 前端优化实施计划

> **目标**: 完全参照 vibelife spec v3.0，全面优化前端视觉与交互体验
> **范围**: Spec 更新 + 视觉打磨 + 核心组件 + 功能页面
> **预估工时**: 25-35 小时

---

## Phase 0: 更新 Spec v3.0 文档

**文件**: `/home/aiscend/work/vibelife/docs/vibelife spec v3.0.md`

### 需要补充的内容：

1. **新增组件清单** (Part 14 组件清单部分)
   - BaziChart 八字命盘可视化组件规格
   - ZodiacChart 星盘可视化组件规格
   - ScriptCard 话术模板卡片规格

2. **更新前端组件状态** (Part 14)
   - 标注已实现 vs 待实现组件
   - 补充 TriToggle、IdentityPrism 详细规格

3. **补充界面原型** (新增 Part)
   - 移动端主界面布局 (ASCII/描述)
   - PC 端三栏布局详情
   - 人生 K 线页面规格
   - 关系模拟器流程

4. **动效规范细化** (Part 1.3)
   - 呼吸动画频率修正: 4s → 16s
   - ink-reveal 墨水显影动画规格
   - 默认静止原则说明

---

## Phase 1: 视觉体验打磨 (动效修复)

### 1.1 修复呼吸动画频率
**文件**: `apps/web/src/app/globals.css`
- `--breath-duration`: 4s → **16s** (禅意呼吸 0.05-0.1Hz)
- `--float-duration`: 6s → **20s**
- `@keyframes breath`: scale(1.05) → **scale(1.015)** (最大缩放 1.02)

**文件**: `apps/web/tailwind.config.ts`
- 同步更新 animation 时长和 keyframes

### 1.2 添加 ink-reveal 墨水显影动画
**文件**: `apps/web/src/app/globals.css`
```css
@keyframes ink-reveal {
  from { filter: blur(4px); opacity: 0; }
  to { filter: blur(0); opacity: 1; }
}
```

### 1.3 实现「默认静止」原则
**文件**: `apps/web/src/app/globals.css` + `components/core/BreathAura.tsx`
- 光晕默认 `animation-play-state: paused`
- 交互/hover/加载时激活

---

## Phase 2: 核心组件开发

### 2.1 TriToggle 三档物理开关
**新建**: `components/ui/TriToggle.tsx`
- 三选项: Inner / Core / Outer
- framer-motion spring 动画 (stiffness: 500, damping: 30)
- ARIA 无障碍支持

### 2.2 IdentityPrism 三元身份棱镜
**新建**: `components/identity/IdentityPrism.tsx`
- 集成 TriToggle 切换器
- 光晕随视角变化 (Inner 小+慢, Core 静止, Outer 大+快)
- AnimatePresence 内容切换

### 2.3 TransitionOverlay 推演过场
**新建**: `components/core/TransitionOverlay.tsx`
- 1.5-2s 过渡时长
- 技能差异化: 八字=同心环, 星座=星点, MBTI=光谱
- **必须提供「跳过」按钮**

### 2.4 DailyGreeting 每日问候
**新建**: `components/greeting/DailyGreeting.tsx`
- 节气/天象感知
- 今日一步 checkbox
- 左边框渐变装饰

### 2.5 NowNextCard 趋势卡片
**新建**: `components/trend/NowNextCard.tsx`
- 当前阶段 (主题+注意点+可做)
- 下一阶段 (时间+主题)

### 2.6 BaziChart 八字命盘可视化
**新建**: `components/chart/BaziChart.tsx`
- 四柱八字可视化 (年/月/日/时)
- 天干地支 + 五行配色
- 十神标注
- 五行强弱雷达图
- 响应式适配 (PC 横向 / 移动端竖向)

### 2.7 ZodiacChart 星盘可视化
**新建**: `components/chart/ZodiacChart.tsx`
- 星盘轮盘图 (12 宫位 + 行星)
- 相位连线 (主要相位高亮)
- 太阳/月亮/上升标注
- Canvas/SVG 实现
- 简洁版 vs 完整版切换

### 2.8 ScriptCard 话术模板卡片
**新建**: `components/script/ScriptCard.tsx`
- 沟通场景标题 (和好/表白/邀约)
- 2-3 个话术选项
- 一键复制按钮
- 最佳发送时机建议
- 可分享为图片

---

## Phase 3: 功能页面实现

### 3.1 人生 K 线重构 (ECharts)
**文件**: `app/chart/kline/page.tsx` + `components/fortune/LifeKLine.tsx`
- 安装: `npm install echarts echarts-for-react`
- 平滑曲线 + 渐变区域
- markLine 标注当前年份
- markPoint 标注关键节点
- 点击节点展开详情

### 3.2 关系模拟器完善
**新建**: `components/relationship/RelationshipCard.tsx`
- 关系结论 + 沟通方式 + 开场白
- 复制/分享按钮

**文件**: `app/relationship/page.tsx`
- 集成三种输入模式 UI

### 3.3 Chat 页面集成
**文件**: `components/insight/InsightPanel.tsx`
- 顶部集成 DailyGreeting
- 集成 IdentityPrism 组件

**文件**: `app/chat/page.tsx`
- 移动端 DailyGreeting Sheet

---

## Phase 4: 集成与优化

### 4.1 组件导出整合
**文件**: `components/core/index.ts`
- 导出所有新组件

### 4.2 响应式适配
- IdentityPrism: 移动端竖向 TriToggle
- K 线图表: 移动端横向滚动
- RelationshipCard: max-w-sm 居中

### 4.3 性能优化
- ECharts 懒加载 (`dynamic import`)
- 动画元素 `will-change` 优化
- 路由代码分割

---

## 关键文件清单

| 操作 | 文件路径 |
|------|----------|
| **修改** | `apps/web/src/app/globals.css` |
| **修改** | `apps/web/tailwind.config.ts` |
| **修改** | `apps/web/src/components/core/BreathAura.tsx` |
| **修改** | `apps/web/src/components/insight/InsightPanel.tsx` |
| **修改** | `apps/web/src/app/chart/kline/page.tsx` |
| **修改** | `apps/web/src/app/relationship/page.tsx` |
| **修改** | `apps/web/src/app/chat/page.tsx` |
| **新建** | `apps/web/src/components/ui/TriToggle.tsx` |
| **新建** | `apps/web/src/components/identity/IdentityPrism.tsx` |
| **新建** | `apps/web/src/components/core/TransitionOverlay.tsx` |
| **新建** | `apps/web/src/components/greeting/DailyGreeting.tsx` |
| **新建** | `apps/web/src/components/trend/NowNextCard.tsx` |
| **新建** | `apps/web/src/components/relationship/RelationshipCard.tsx` |
| **新建** | `apps/web/src/components/chart/BaziChart.tsx` |
| **新建** | `apps/web/src/components/chart/ZodiacChart.tsx` |
| **新建** | `apps/web/src/components/script/ScriptCard.tsx` |

---

## 执行顺序

```
Phase 0 (更新 Spec v3.0)
    ↓
Phase 1 (动效修复)
    ↓
Phase 2.1 (TriToggle) → Phase 2.2 (IdentityPrism)
Phase 2.6 (BaziChart) ─┬─ Phase 2.7 (ZodiacChart)
                       │
Phase 2.3 (TransitionOverlay)
Phase 2.4 (DailyGreeting)
Phase 2.5 (NowNextCard)
Phase 2.8 (ScriptCard)
    ↓
Phase 3.1 (K 线) ──┬── Phase 3.3 (Chat 集成)
Phase 3.2 (关系) ──┘
    ↓
Phase 4 (集成优化)
```

---

## 参考文档

- Spec: `/home/aiscend/work/vibelife/docs/vibelife spec v3.0.md`
- 设计参考: `/home/aiscend/work/vibelife/docs/reference/vibelife-design-spec-v3.md`
- Demo: `/home/aiscend/work/vibelife/docs/reference/vibelife-v3-demo.html`
