# Dashboard → Chat 整合方案总览

> **版本**: V9.0
> **日期**: 2026-01-21
> **状态**: ✅ 已完成

---

## 📋 目录

1. [整合目标](#整合目标)
2. [架构变更](#架构变更)
3. [新增组件](#新增组件)
4. [修改文件](#修改文件)
5. [删除文件](#删除文件)
6. [用户体验](#用户体验)
7. [技术细节](#技术细节)
8. [测试清单](#测试清单)

---

## 🎯 整合目标

### 业务目标
1. **提升 Chat 空状态价值**: 从单一 VibeGlyph 升级为全功能仪表盘
2. **减少路由跳转**: 用户无需切换 Tab，在 Chat 中即可完成所有操作
3. **增强用户粘性**: 空状态展示关键信息，引导用户互动

### 技术目标
1. **组件复用**: 充分利用 Dashboard 现有组件库
2. **代码简化**: 移除冗余路由，统一入口
3. **性能优化**: 预加载数据，减少等待时间

---

## 🏗️ 架构变更

### 导航结构

**变更前** (V8):
```
5 个导航入口: Dashboard / Chat / Discover / Journey / Me
默认首页: /dashboard
```

**变更后** (V9):
```
4 个导航入口: Chat / Discover / Journey / Me
默认首页: /chat
Dashboard 整合到 Chat 空状态
```

### 页面布局

**Chat 空状态 (V9)**:
```
┌─────────────────────────────────────────┐
│  🌅 DailyGreeting                        │
│  - 问候、节气、日期                     │
│  - 运势指数、今日一步                   │
│  - VibeGlyph（居中）                     │
│                                          │
│  📊 AmbientStatusBar                     │
│  - 连续天数、能量、签到状态             │
│                                          │
│  🧭 LifecoachQuickView                   │
│  - 北极星、月度进度、杠杆、大石头       │
│  - 可展开查看详情                       │
│                                          │
│  🎴 MySkillsCarousel                     │
│  - 已订阅 Skills 横滑展示               │
│  - 点击发送预设 prompt                  │
└─────────────────────────────────────────┘
```

**Chat 对话中**:
```
┌─────────────────────────────────────────┐
│  💬 Message List                         │
│  - 用户消息                             │
│  - AI 回复                              │
│                                          │
│  Dashboard 完全隐藏                      │
└─────────────────────────────────────────┘
```

---

## 📦 新增组件

### 1. AmbientStatusBar
**文件**: `apps/web/src/components/chat/AmbientStatusBar.tsx`

**功能**: 简化版状态条，横向展示核心指标

**Props**:
```typescript
interface AmbientStatusBarProps {
  status: StatusData;           // 状态数据
  onCheckIn: () => Promise<unknown>;  // 签到回调
  className?: string;
}
```

**特性**:
- 🔥 连续天数（带火焰数量动态显示）
- 💪 能量值（百分比）
- ✓ 签到状态（已签到/未签到）
- 🎯 签到按钮（未签到时显示）

---

### 2. LifecoachQuickView
**文件**: `apps/web/src/components/chat/LifecoachQuickView.tsx`

**功能**: 可展开的 Lifecoach 卡片

**Props**:
```typescript
interface LifecoachQuickViewProps {
  data: LifecoachData;                         // Lifecoach 数据
  onToggleLever: (leverId: string) => Promise<void>;  // 杠杆打勾
  onToggleRock: (rockId: string) => Promise<void>;    // 大石头打勾
  onClickNorthStar?: () => void;               // 北极星点击
  className?: string;
}
```

**特性**:
- **折叠状态**: 显示关键指标摘要（北极星、月度进度、杠杆、大石头）
- **展开状态**: 显示完整 LifecoachCard（点击原地展开）
- **交互**: 支持杠杆/大石头打勾操作

---

### 3. ChatEmptyStateWithDashboard
**文件**: `apps/web/src/components/chat/ChatEmptyStateWithDashboard.tsx`

**功能**: 整合所有组件的空状态容器

**Props**:
```typescript
interface ChatEmptyStateWithDashboardProps {
  skill: SkillType;
  dashboardData?: DashboardDTO | null;
  isDashboardLoading?: boolean;
  onQuickPrompt?: (prompt: string) => void;
  onCheckIn: () => Promise<void>;
  onToggleLever: (leverId: string) => Promise<void>;
  onToggleRock: (rockId: string) => Promise<void>;
  dailyGreeting: DailyGreetingData;
  className?: string;
}
```

**布局顺序**:
1. DailyGreeting（问候、运势、VibeGlyph）
2. AmbientStatusBar（状态条）
3. LifecoachQuickView（Lifecoach 摘要）
4. MySkillsCarousel（Skills 横滑）

---

## 🔧 修改文件

### 1. ChatContainer.tsx
**位置**: `apps/web/src/components/chat/ChatContainer.tsx`

**变更**:
- ✅ 添加 Dashboard 相关 props
- ✅ 集成 `ChatEmptyStateWithDashboard`
- ✅ 空状态时展示 Dashboard，对话时隐藏

**新增 Props**:
```typescript
interface ChatContainerProps {
  // ... 原有 props
  dashboardData?: DashboardDTO | null;
  isDashboardLoading?: boolean;
  onCheckIn?: () => Promise<void>;
  onToggleLever?: (leverId: string) => Promise<void>;
  onToggleRock?: (rockId: string) => Promise<void>;
}
```

---

### 2. chat/page.tsx
**位置**: `apps/web/src/app/chat/page.tsx`

**变更**:
- ✅ 集成 `useDashboard` hook
- ✅ 预加载 Dashboard 数据
- ✅ 传递数据和回调给 ChatContainer

**代码示例**:
```typescript
const ChatContent = memo(function ChatContent() {
  const { dashboard, isLoading, checkIn, toggleLever, toggleRock } = useDashboard();

  return (
    <ChatContainer
      // ... 原有 props
      dashboardData={dashboard}
      isDashboardLoading={isLoading}
      onCheckIn={checkIn}
      onToggleLever={toggleLever}
      onToggleRock={toggleRock}
    />
  );
});
```

---

### 3. NavBar.tsx & MobileTabBar.tsx
**位置**: `apps/web/src/components/layout/`

**变更**:
- ✅ 移除未使用的 `LayoutDashboard` 图标导入
- ✅ 更新注释说明 V9 变更

---

### 4. app/page.tsx
**位置**: `apps/web/src/app/page.tsx`

**变更**:
- ✅ 已登录用户重定向从 `/dashboard` 改为 `/chat`
- ✅ 更新注释为 V9 说明

---

## 🗑️ 删除文件

### 1. /dashboard 路由
**文件**:
- `apps/web/src/app/dashboard/page.tsx` → 改为重定向到 /chat
- `apps/web/src/app/dashboard/loading.tsx` → 删除

**原因**: Dashboard 功能已完全整合到 Chat

---

## ✨ 用户体验

### 核心特性

1. **无缝融合**
   - DailyGreeting + Dashboard 和谐共存
   - 信息密度高但不拥挤
   - 视觉层次清晰

2. **快速操作**
   - 签到：一键完成，连续天数即时更新
   - 杠杆/大石头：直接打勾，无需跳转
   - Skills：点击卡片自动发送 prompt 开启对话

3. **智能隐藏**
   - 对话开始后自动隐藏 Dashboard
   - 回归纯对话界面
   - 刷新后重新显示

4. **预加载**
   - Dashboard 数据预先加载
   - 无需等待，即时展示

### 交互设计

#### 1. My Skills 卡片点击
**行为**: 自动发送预设 prompt 开启对话

**映射关系**:
```typescript
const promptMap = {
  bazi: "帮我看看今日运势",
  zodiac: "查看我的星盘运势",
  tarot: "帮我抽一张塔罗牌",
  career: "分析我的职业发展",
  lifecoach: "查看我的人生仪表盘",
};
```

#### 2. Lifecoach 展开/收起
**行为**: 点击原地切换，保持上下文

**状态**:
- 折叠: 显示摘要（⭐ 北极星 | 📊 月度 60% | ☀️ 杠杆 2/3）
- 展开: 显示完整卡片（可打勾、查看详情）

#### 3. 签到操作
**行为**: 即时反馈，连续天数动态更新

**流程**:
1. 点击"开始今天"按钮
2. 显示"签到中..."
3. 成功后按钮消失，显示"✓ 已签到"
4. 连续天数 +1，火焰数量更新

---

## 🔍 技术细节

### 数据流

```
API /dashboard
  ↓
useDashboard hook
  ├─ dashboard: DashboardDTO
  ├─ isLoading: boolean
  ├─ checkIn(): Promise<void>
  ├─ toggleLever(id): Promise<void>
  └─ toggleRock(id): Promise<void>
  ↓
ChatContent
  ↓
ChatContainer (props)
  ↓
ChatEmptyStateWithDashboard
  ↓
各子组件
  ├─ AmbientStatusBar
  ├─ LifecoachQuickView
  └─ MySkillsCarousel
```

### 状态管理

**DailyGreeting 状态**:
```typescript
const dailyData = useDailyGreeting(skill);
const [actionCompleted, setActionCompleted] = useState(false);

// 本地存储
const actionKey = `vibelife-daily-action:${skill}:${isoDate}`;
localStorage.setItem(actionKey, actionCompleted ? "1" : "0");
```

**Dashboard 状态**:
```typescript
const {
  dashboard,      // 完整数据
  isLoading,      // 加载状态
  checkIn,        // 签到操作
  toggleLever,    // 杠杆打勾
  toggleRock,     // 大石头打勾
} = useDashboard();
```

### 性能优化

1. **预加载**: Chat 页面加载时立即获取 Dashboard 数据
2. **Memo**: 所有子组件使用 `memo` 包裹，避免不必要的重渲染
3. **懒加载**: 骨架屏占位，数据到达后平滑渲染
4. **条件渲染**: `messages.length === 0` 控制 Dashboard 显示/隐藏

---

## 📊 测试清单

### 功能测试

- [ ] **空状态展示**
  - [ ] DailyGreeting 显示正常
  - [ ] VibeGlyph 居中显示，有呼吸动画
  - [ ] AmbientStatusBar 显示连续天数、能量、签到状态
  - [ ] LifecoachQuickView 显示折叠版摘要
  - [ ] My Skills Carousel 横向滚动显示

- [ ] **交互测试**
  - [ ] 签到按钮：点击后显示"签到成功"，连续天数+1
  - [ ] Lifecoach 展开：点击 `LIFECOACH ▼` 展开完整卡片
  - [ ] Lifecoach 收起：展开后点击 `▲` 收起
  - [ ] 杠杆打勾：在展开的 Lifecoach 中，点击杠杆项前的 `□` 变为 `✓`
  - [ ] Skills 卡片：点击 Bazi 卡片 → 自动发送"帮我看看今日运势"

- [ ] **对话后隐藏**
  - [ ] 发送任意消息后，Dashboard 组件完全隐藏
  - [ ] 仅显示对话界面
  - [ ] 刷新页面后，Dashboard 重新出现

- [ ] **响应式**
  - [ ] PC 端（≥1024px）：所有组件垂直排列，居中显示
  - [ ] 移动端（<1024px）：同样布局，适配小屏幕

### 性能测试

- [ ] Dashboard 数据加载时间 < 500ms
- [ ] 空状态渲染时间 < 100ms
- [ ] 对话开始后 Dashboard 隐藏时间 < 50ms

### 兼容性测试

- [ ] Chrome/Edge（最新版）
- [ ] Firefox（最新版）
- [ ] Safari（最新版）
- [ ] 移动端浏览器（iOS Safari, Chrome Mobile）

---

## 📈 实施成果

| 指标 | 结果 |
|------|------|
| 新增组件 | 3 个 |
| 修改文件 | 4 个 |
| 删除文件 | 2 个 |
| 代码行数 | +~400 行 |
| 实施时间 | 2 小时 |
| 构建状态 | ✅ 成功 |

---

## 🚀 后续优化建议

### 短期（1-2 周）
1. **动画优化**: 添加 Dashboard 组件出现/消失的过渡动画
2. **骨架屏**: Dashboard 加载时显示更精细的骨架屏
3. **缓存策略**: Dashboard 数据缓存到 localStorage，减少加载时间

### 中期（1 个月）
1. **个性化**: 根据用户习惯调整 Dashboard 组件顺序
2. **A/B 测试**: 测试不同布局对用户互动的影响
3. **数据埋点**: 收集用户行为数据，优化 prompt 映射

### 长期（3 个月）
1. **AI 推荐**: 根据用户画像智能推荐 Skills
2. **动态内容**: Dashboard 内容根据时间、节气、用户状态动态调整
3. **跨端同步**: Dashboard 状态在多设备间同步

---

**文档维护者**: Claude Sonnet 4.5
**最后更新**: 2026-01-21
