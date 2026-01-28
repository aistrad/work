# Me页面优化 - 集成指南

本指南说明如何将优化后的Me页面集成到现有系统中。

## 📋 改动概览

### 1. NavBar 左边栏
- ✅ 删除了通知区域
- ✅ 简化为单一的展开/收起控制
- ✅ 应用React最佳实践（Lazy State + Functional setState）

### 2. Me页面组件
- ✅ 新增 `BaziSummaryCard` - 八字命盘摘要卡片
- ✅ 新增 `ZodiacSummaryCard` - 星座星图摘要卡片
- ✅ 重构 `MePanel` - 整合自我认知内容

---

## 🔧 集成步骤

### Step 1: 数据准备

MePanel现在需要三种数据：VibeID、八字、星座。你需要准备数据获取逻辑。

#### 1.1 八字数据获取

```typescript
// 示例：从API获取八字数据
import { type BaziData } from '@/components/me';

async function fetchBaziData(userId: string): Promise<BaziData | null> {
  try {
    const response = await fetch(`/api/bazi/${userId}/summary`);
    if (!response.ok) return null;

    const data = await response.json();

    // 转换为BaziData格式
    return {
      dayMaster: data.day_master,        // 如 "甲木"
      pattern: data.pattern,             // 如 "食神格"
      todayFortune: data.today_fortune,  // 今日运势文案
      fortuneLevel: data.fortune_level,  // 1-5
    };
  } catch (error) {
    console.error('Failed to fetch bazi data:', error);
    return null;
  }
}
```

#### 1.2 星座数据获取

```typescript
// 示例：从API获取星座数据
import { type ZodiacData } from '@/components/me';

async function fetchZodiacData(userId: string): Promise<ZodiacData | null> {
  try {
    const response = await fetch(`/api/zodiac/${userId}/summary`);
    if (!response.ok) return null;

    const data = await response.json();

    // 转换为ZodiacData格式
    return {
      sunSign: data.sun_sign,         // 如 "水瓶座"
      ascendant: data.ascendant,      // 如 "天秤座"
      todayEnergy: data.today_energy, // 今日能量文案
      energyLevel: data.energy_level, // 1-5
    };
  } catch (error) {
    console.error('Failed to fetch zodiac data:', error);
    return null;
  }
}
```

#### 1.3 VibeID数据获取

```typescript
// VibeID数据类型需要从vibe-id模块导入
// import { type VibeIDDisplay } from '@/types/vibe-id';

async function fetchVibeIdData(userId: string): Promise<any | null> {
  try {
    const response = await fetch(`/api/vibe-id/${userId}`);
    if (!response.ok) return null;
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch vibe-id data:', error);
    return null;
  }
}
```

---

### Step 2: 在AppShell中集成

找到 `apps/web/src/components/layout/AppShell.tsx`，更新MePanel的调用：

```typescript
// AppShell.tsx

import { MePanel } from './panels/MePanel';
import { type BaziData, type ZodiacData } from '@/components/me';

export function AppShell({ ... }) {
  // 获取数据（可以用SWR或React Query）
  const { data: baziData } = useSWR<BaziData | null>(
    user ? `/api/bazi/${user.id}/summary` : null,
    fetcher
  );

  const { data: zodiacData } = useSWR<ZodiacData | null>(
    user ? `/api/zodiac/${user.id}/summary` : null,
    fetcher
  );

  const { data: vibeIdData } = useSWR(
    user ? `/api/vibe-id/${user.id}` : null,
    fetcher
  );

  // 在渲染MePanel时传入数据
  return (
    <MePanel
      skill={currentSkill}
      user={user}
      vibeIdData={vibeIdData}
      baziData={baziData}
      zodiacData={zodiacData}
      voiceMode={voiceMode}
      onVoiceModeChange={handleVoiceModeChange}
      onEditProfile={handleEditProfile}
      onManageSubscription={handleManageSubscription}
      onNotificationSettings={handleNotificationSettings}
      onLogout={handleLogout}
    />
  );
}
```

---

### Step 3: 数据加载状态处理

建议使用Skeleton组件处理加载状态：

```typescript
import {
  BaziSummaryCard,
  BaziSummaryCardSkeleton,
  ZodiacSummaryCard,
  ZodiacSummaryCardSkeleton,
} from '@/components/me';

// 在MePanel中渲染
{isLoadingBazi ? (
  <BaziSummaryCardSkeleton />
) : (
  <BaziSummaryCard
    data={baziData}
    onExplore={handleExploreBazi}
  />
)}
```

---

## 📊 数据字段说明

### BaziData
```typescript
{
  dayMaster: string;      // 日主，如 "甲木"
  pattern: string;        // 格局，如 "食神格"
  todayFortune: string;   // 今日运势文案，如 "偏财旺，贵人运强"
  fortuneLevel: 1 | 2 | 3 | 4 | 5;  // 运势等级，对应星级
}
```

### ZodiacData
```typescript
{
  sunSign: string;        // 太阳星座，如 "水瓶座"
  ascendant: string;      // 上升星座，如 "天秤座"
  todayEnergy: string;    // 今日能量文案，如 "灵感爆发"
  energyLevel: 1 | 2 | 3 | 4 | 5;  // 能量等级，对应图标
}
```

---

## 🎨 视觉效果

### 八字卡片
- 渐变色：amber-50 → orange-50
- 图标：🌙
- 今日运势显示星级（⭐）

### 星座卡片
- 渐变色：purple-50 → blue-50
- 图标：⭐
- 今日能量显示emoji（💫 ✨ 🌟 ⭐ 💥）

### 设置区域
- 默认折叠
- 点击标题展开/收起
- 使用animate-fade-in动画

---

## 🔍 测试建议

1. **空状态测试**：确保未登录或无数据时显示正确
2. **数据加载测试**：验证Skeleton和真实数据的切换
3. **点击跳转测试**：确认"查看详情"跳转到正确页面
4. **折叠交互测试**：验证设置区域的展开/收起
5. **响应式测试**：检查移动端和PC端的显示效果

---

## 📝 后续优化建议

1. **性能优化**
   - 考虑使用React Query进行数据缓存
   - 实现数据预加载（在用户hover时）

2. **用户体验**
   - 添加数据刷新功能
   - 考虑添加"分享我的VibeID"功能

3. **数据丰富**
   - 扩展更多Skill的摘要卡片
   - 添加成长轨迹图表

---

## 🐛 常见问题

### Q: VibeIDCard组件找不到？
A: 确保VibeID模块已正确安装，路径应为 `@/skills/vibe-id/components/VibeIDCard`

### Q: 类型错误：找不到BaziData？
A: 确保从正确路径导入：`import { type BaziData } from '@/components/me'`

### Q: animate-fade-in样式不生效？
A: 该动画已在tailwind.config.ts中定义，确保Tailwind正确编译

### Q: 数据为null时显示什么？
A: 组件会自动显示空状态，引导用户"开始测算"

---

## 📦 文件清单

新增文件：
- `apps/web/src/components/me/BaziSummaryCard.tsx`
- `apps/web/src/components/me/ZodiacSummaryCard.tsx`
- `apps/web/src/components/me/index.tsx`
- `apps/web/src/components/me/INTEGRATION_GUIDE.md`（本文件）

修改文件：
- `apps/web/src/components/layout/NavBar.tsx`（删除通知）
- `apps/web/src/components/layout/panels/MePanel.tsx`（整合自我认知）

---

**需要帮助？** 查看组件源码中的详细注释，或参考 VibeIDCard 的使用方式。
