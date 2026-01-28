# Discover 功能源代码文件索引

本文档列出了 Discover 功能相关的所有源代码文件及其说明。

---

## 📁 目录结构

```
vibelife/
├── apps/web/src/
│   ├── components/discover/          # Discover 组件目录
│   │   ├── DiscoverContent.tsx       # 主容器组件
│   │   ├── FeaturedSkillBanner.tsx   # 精选横幅
│   │   ├── SkillShowcaseCard.tsx     # Skill 展示卡片
│   │   ├── CategorySection.tsx       # 分类区域
│   │   └── index.ts                  # 导出文件
│   ├── app/api/v1/skills/            # API Routes
│   │   ├── route.ts                  # Skills 列表
│   │   ├── subscriptions/
│   │   │   └── route.ts              # 订阅状态
│   │   └── recommendations/
│   │       └── route.ts              # 智能推荐
│   ├── hooks/
│   │   └── useSkillSubscription.ts   # Skills 数据 Hook
│   ├── components/layout/            # 导航组件
│   │   ├── NavBar.tsx                # PC 导航栏 (修改)
│   │   ├── MobileTabBar.tsx          # Mobile 底栏 (修改)
│   │   ├── AppShell.tsx              # 主布局容器 (修改)
│   │   ├── PCLayout.tsx              # PC 三栏布局 (修改)
│   │   ├── ResizablePanel.tsx        # 可调节面板 (修复 hydration)
│   │   └── ChatContainer.tsx         # 聊天容器 (修复 hydration)
│   └── app/chat/page.tsx             # Chat 页面 (集成入口)
└── docs/components/discovery/        # 文档目录
    ├── README.md                     # 总览
    ├── INTEGRATION.md                # 集成指南
    ├── COMPONENTS.md                 # 组件文档
    ├── API.md                        # API 文档
    ├── TROUBLESHOOTING.md            # 问题排查
    ├── CHANGELOG.md                  # 变更日志
    └── FILES.md                      # 文件索引（本文件）
```

---

## 🆕 新增文件

### 组件文件

#### 1. DiscoverContent.tsx
**路径**: `apps/web/src/components/discover/DiscoverContent.tsx`
**行数**: ~240 行
**作用**: Discover 页面主容器组件
**关键功能**:
- 数据获取（useSkills, useSkillSubscription, useSkillRecommendations）
- 状态管理（Loading/Error/Empty）
- 布局组织（精选横幅 + 分类区域）
- 事件处理（订阅、取消订阅、Skill 点击）

**依赖**:
```typescript
import { useRouter } from 'next/navigation';
import { AlertCircle, Sparkles } from 'lucide-react';
import { FeaturedSkillBanner } from './FeaturedSkillBanner';
import { CategorySection } from './CategorySection';
import { useSkills, useSkillSubscription, useSkillRecommendations } from '@/hooks/useSkillSubscription';
import { useAuth } from '@/providers/AuthProvider';
```

---

#### 2. FeaturedSkillBanner.tsx
**路径**: `apps/web/src/components/discover/FeaturedSkillBanner.tsx`
**行数**: ~80 行
**作用**: App Store 风格精选横幅
**关键功能**:
- 大尺寸视觉展示（400-480px 高度）
- 渐变背景（使用 Skill 品牌色）
- 装饰图案（径向渐变）
- 悬停动画效果

**Props**:
```typescript
interface FeaturedSkillBannerProps {
  skill: SkillMetadata;
  campaign?: {
    title: string;
    subtitle?: string;
    badge?: string;
  };
  onClick: () => void;
}
```

---

#### 3. SkillShowcaseCard.tsx
**路径**: `apps/web/src/components/discover/SkillShowcaseCard.tsx`
**行数**: ~120 行
**作用**: 320px 宽度的 Skill 展示卡片
**关键功能**:
- 固定宽度（320px）横向滚动
- 展示图标、名称、描述
- 订阅状态显示
- 定价信息展示

**Props**:
```typescript
interface SkillShowcaseCardProps {
  skill: SkillMetadata;
  userStatus?: SkillUserStatus;
  onClick: () => void;
  onSubscribe?: () => void;
}
```

---

#### 4. CategorySection.tsx
**路径**: `apps/web/src/components/discover/CategorySection.tsx`
**行数**: ~60 行
**作用**: 分类区域容器（横向滚动）
**关键功能**:
- 标题 + 副标题
- 横向滚动容器
- 调用 SkillShowcaseCard 展示

**Props**:
```typescript
interface CategorySectionProps {
  title: string;
  subtitle?: string;
  skills: SkillMetadata[];
  userStatuses: Record<string, SkillUserStatus>;
  onSkillClick: (skillId: string) => void;
  onSubscribe: (skillId: string) => void;
}
```

---

#### 5. index.ts
**路径**: `apps/web/src/components/discover/index.ts`
**行数**: ~5 行
**作用**: 统一导出所有 Discover 组件

```typescript
export { DiscoverContent } from './DiscoverContent';
export { FeaturedSkillBanner } from './FeaturedSkillBanner';
export { SkillShowcaseCard } from './SkillShowcaseCard';
export { CategorySection } from './CategorySection';
```

---

### API Routes

#### 6. /api/v1/skills/route.ts
**路径**: `apps/web/src/app/api/v1/skills/route.ts`
**行数**: ~48 行
**作用**: Skills 列表 API 代理
**端点**: `GET /api/v1/skills`
**功能**:
- 代理后端 `/api/v1/skills` 端点
- 转发查询参数（category, subscribed）
- 转发 Authorization header
- 错误处理

---

#### 7. /api/v1/skills/subscriptions/route.ts
**路径**: `apps/web/src/app/api/v1/skills/subscriptions/route.ts`
**行数**: ~48 行
**作用**: 订阅状态 API 代理
**端点**: `GET /api/v1/skills/subscriptions`
**功能**:
- 代理后端订阅端点
- 需要认证
- 返回用户订阅列表和统计

---

#### 8. /api/v1/skills/recommendations/route.ts
**路径**: `apps/web/src/app/api/v1/skills/recommendations/route.ts`
**行数**: ~48 行
**作用**: 智能推荐 API 代理
**端点**: `GET /api/v1/skills/recommendations`
**功能**:
- 代理后端推荐端点
- 支持 limit 和 context 参数
- 需要认证

---

## 🔧 修改的文件

### 导航相关

#### 9. NavBar.tsx
**路径**: `apps/web/src/components/layout/NavBar.tsx`
**修改内容**:

1. **添加 discover 导航项** (第 54-73 行):
```typescript
const NAV_ITEMS: NavItem[] = [
  { id: "chat", icon: MessageSquare, label: "对话" },
  { id: "journey", icon: Compass, label: "旅程" },
  { id: "discover", icon: Sparkles, label: "探索" }, // 新增
  { id: "me", icon: User, label: "我的" },
];
```

2. **修复 localStorage hydration** (第 88-100 行):
```typescript
// 修改前
const [isExpanded, setIsExpanded] = useState(() => {
  return localStorage.getItem(STORAGE_KEY) === "true";
});

// 修改后
const [isExpanded, setIsExpanded] = useState(false);
useEffect(() => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved !== null) {
    setIsExpanded(saved === "true");
  }
}, []);
```

---

#### 10. MobileTabBar.tsx
**路径**: `apps/web/src/components/layout/MobileTabBar.tsx`
**修改内容**:

**添加 discover tab** (第 30-50 行):
```typescript
const TAB_ITEMS: TabItem[] = [
  { id: "chat", icon: MessageSquare, label: "对话" },
  { id: "journey", icon: Compass, label: "旅程" },
  { id: "discover", icon: Sparkles, label: "探索" }, // 新增
  { id: "me", icon: User, label: "我的" },
];
```

---

#### 11. AppShell.tsx
**路径**: `apps/web/src/components/layout/AppShell.tsx`
**修改内容**:

1. **扩展 TabType** (第 30 行):
```typescript
// 修改前
export type TabType = "chat" | "journey" | "me";

// 修改后
export type TabType = "chat" | "journey" | "discover" | "me";
```

2. **添加 discoverContent prop** (第 40-50 行):
```typescript
interface AppShellProps {
  skill: SkillType;
  children: ReactNode;
  journeyContent?: ReactNode;
  discoverContent?: ReactNode; // 新增
  meContent?: ReactNode;
  defaultTab?: TabType;
}
```

3. **添加 discover case** (第 120-130 行):
```typescript
switch (activeTab) {
  case "discover":
    return discoverContent || <div>Discover not configured</div>;
  // ...
}
```

---

#### 12. PCLayout.tsx
**路径**: `apps/web/src/components/layout/PCLayout.tsx`
**修改内容**:

**更新 NAV_ITEMS** (第 30-35 行):
```typescript
const NAV_ITEMS = [
  { id: 'home', path: '/', icon: '🏠', label: '首页' },
  { id: 'chat', path: '/chat', icon: '💬', label: '对话' },
  { id: 'discover', path: '/chat?tab=discover', icon: '✨', label: '探索' }, // 新增
  { id: 'identity', path: '/identity', icon: '💎', label: '身份画像' },
]
```

---

### Hydration 修复

#### 13. ResizablePanel.tsx
**路径**: `apps/web/src/components/layout/ResizablePanel.tsx`
**修改内容**:

**修复 usePersistentState hook** (第 60-85 行):
```typescript
// 修改前
function usePersistentState<T>(key: string, initialValue: T) {
  const [state, setState] = useState<T>(() => {
    if (typeof window === "undefined") return initialValue;
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });
}

// 修改后
function usePersistentState<T>(key: string, initialValue: T) {
  const [state, setState] = useState<T>(initialValue);

  useEffect(() => {
    const stored = localStorage.getItem(key);
    if (stored) {
      setState(JSON.parse(stored));
    }
  }, [key]);

  // ...
}
```

---

#### 14. ChatContainer.tsx
**路径**: `apps/web/src/components/chat/ChatContainer.tsx`
**修改内容**:

**修复时间数据 hydration** (第 244-266 行):
```typescript
// 修改前
const [data] = useState(() => getLocalGreetingData(skill));

// 修改后
const [data, setData] = useState(() => ({
  greeting: "新的一天开始了",
  timeOfDay: "morning",
  // ... 默认值
}));

useEffect(() => {
  setData(getLocalGreetingData(skill));
}, [skill]);
```

---

### Hooks

#### 15. useSkillSubscription.ts
**路径**: `apps/web/src/hooks/useSkillSubscription.ts`
**修改内容**:

**修复 API 路径** (多处):
```typescript
// 修改前
const response = await apiClient.get('/api/v1/skills');

// 修改后
const response = await apiClient.get('/v1/skills');
// apiClient 会自动添加 /api 前缀
```

**修改位置**:
- `fetchSkills()` - 第 33 行
- `fetchSubscriptions()` - 第 27 行
- `fetchRecommendations()` - 第 43 行
- `subscribe()` - 第 72 行
- `unsubscribe()` - 第 84 行
- `togglePush()` - 第 94 行

---

### 集成入口

#### 16. ChatPage.tsx (page.tsx)
**路径**: `apps/web/src/app/chat/page.tsx`
**修改内容**:

1. **导入 DiscoverContent** (第 29 行):
```typescript
import { DiscoverContent as DiscoverContentComponent } from "@/components/discover";
```

2. **创建 memo 组件** (第 376-378 行):
```typescript
const DiscoverContent = memo(function DiscoverContent() {
  return <DiscoverContentComponent />;
});
```

3. **集成到 AppShell** (第 416-420 行):
```typescript
<AppShell
  skill={skill}
  journeyContent={<Suspense><JourneyContent /></Suspense>}
  discoverContent={<Suspense><DiscoverContent /></Suspense>} {/* 新增 */}
  meContent={<Suspense><MeContent /></Suspense>}
>
```

---

## 📚 文档文件

#### 17-22. 文档集合
**路径**: `docs/components/discovery/`

| 文件 | 行数 | 说明 |
|------|------|------|
| README.md | ~150 | 总览文档 |
| INTEGRATION.md | ~400 | 集成指南 |
| COMPONENTS.md | ~500 | 组件文档 |
| API.md | ~400 | API 文档 |
| TROUBLESHOOTING.md | ~350 | 问题排查 |
| CHANGELOG.md | ~250 | 变更日志 |
| FILES.md | ~300 | 文件索引（本文件） |

---

## 📊 统计总结

### 代码文件

| 类型 | 文件数 | 代码行数 |
|------|--------|----------|
| 新增组件 | 5 | ~500 |
| 新增 API Routes | 3 | ~150 |
| 修改组件 | 6 | ~300 |
| 修改 Hooks | 1 | ~50 |
| **总计** | **15** | **~1000** |

### 文档文件

| 类型 | 文件数 | 行数 |
|------|--------|------|
| 文档 | 7 | ~2350 |

### 总体统计

- **总文件数**: 22 个
- **代码行数**: ~1000 行
- **文档行数**: ~2350 行
- **总行数**: **~3350 行**

---

## 🔗 文件关系图

```
ChatPage (page.tsx)
    ↓
AppShell.tsx
    ↓
DiscoverContent.tsx
    ├─→ FeaturedSkillBanner.tsx
    ├─→ CategorySection.tsx
    │       ↓
    │   SkillShowcaseCard.tsx
    └─→ useSkillSubscription.ts
            ↓
        /api/v1/skills/* (API Routes)
            ↓
        Backend API (port 8100)

NavBar.tsx ─────────┐
MobileTabBar.tsx ───┼─→ 导航到 /chat?tab=discover
PCLayout.tsx ───────┘
```

---

## 🔍 快速查找

### 按功能查找

**组件相关:**
- 主容器: `DiscoverContent.tsx`
- 精选横幅: `FeaturedSkillBanner.tsx`
- Skill 卡片: `SkillShowcaseCard.tsx`
- 分类区域: `CategorySection.tsx`

**API 相关:**
- Skills 列表: `/api/v1/skills/route.ts`
- 订阅状态: `/api/v1/skills/subscriptions/route.ts`
- 智能推荐: `/api/v1/skills/recommendations/route.ts`

**导航相关:**
- PC 导航: `NavBar.tsx`
- Mobile 导航: `MobileTabBar.tsx`
- 布局容器: `AppShell.tsx`
- PC 布局: `PCLayout.tsx`

**数据相关:**
- Hooks: `useSkillSubscription.ts`

**Bug 修复:**
- Hydration 1: `NavBar.tsx`
- Hydration 2: `ResizablePanel.tsx`
- Hydration 3: `ChatContainer.tsx`
- API 路径: `useSkillSubscription.ts`

---

## 📝 备注

1. 所有新增的 `.tsx` 文件都使用 `'use client'` 指令
2. 所有组件都有完整的 TypeScript 类型定义
3. 所有 API Routes 都包含错误处理
4. 所有修改都保持向后兼容

---

## 相关文档

- [README](./README.md)
- [集成指南](./INTEGRATION.md)
- [组件文档](./COMPONENTS.md)
- [API 文档](./API.md)
- [问题排查](./TROUBLESHOOTING.md)
- [变更日志](./CHANGELOG.md)
