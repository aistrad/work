# Discover 功能集成指南

本文档详细记录了 Discover 功能从零到一的完整集成过程。

## 📋 集成步骤

### 步骤 1: 创建前端组件

#### 1.1 创建 DiscoverContent 主组件

**文件**: `apps/web/src/components/discover/DiscoverContent.tsx`

```typescript
'use client';

import React, { useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { AlertCircle, Sparkles } from 'lucide-react';
import { FeaturedSkillBanner } from './FeaturedSkillBanner';
import { CategorySection } from './CategorySection';
import { useSkills, useSkillSubscription, useSkillRecommendations } from '@/hooks/useSkillSubscription';
import { useAuth } from '@/providers/AuthProvider';

export function DiscoverContent() {
  const router = useRouter();
  const { user } = useAuth();
  const { skills, categories, isLoading, error } = useSkills();
  const { userStatuses, subscribe, unsubscribe } = useSkillSubscription();
  const { recommendations } = useSkillRecommendations({ limit: 3, enabled: !!user });

  // 按分类分组
  const skillsByCategory = useMemo(() => {
    const grouped = { professional: [], default: [], core: [] };
    for (const skill of skills) {
      if (grouped[skill.category]) {
        grouped[skill.category].push(skill);
      }
    }
    return grouped;
  }, [skills]);

  // 精选 Skill
  const featuredSkill = useMemo(() => {
    return skillsByCategory.professional[0] || skillsByCategory.default[0] || skills[0];
  }, [skillsByCategory, skills]);

  // Loading/Error/Empty 状态处理
  if (isLoading) return <LoadingSkeleton />;
  if (error) return <ErrorState />;
  if (!skills || skills.length === 0) return <EmptyState />;

  return (
    <div className="h-full overflow-y-auto bg-bg-primary">
      <div className="max-w-7xl mx-auto px-4 lg:px-8 py-8 space-y-12">
        {/* 精选横幅 */}
        {featuredSkill && (
          <FeaturedSkillBanner
            skill={featuredSkill}
            campaign={{ title: '精选推荐', badge: '编辑推荐' }}
            onClick={() => router.push(`/skills/${featuredSkill.id}`)}
          />
        )}

        {/* 分类区域 */}
        {skillsByCategory.professional.length > 0 && (
          <CategorySection
            title="专业技能"
            subtitle="深度探索，专业洞察"
            skills={skillsByCategory.professional}
            userStatuses={userStatuses}
            onSkillClick={(id) => router.push(`/skills/${id}`)}
            onSubscribe={subscribe}
          />
        )}

        {/* 其他分类... */}
      </div>
    </div>
  );
}
```

**关键点：**
- 使用 `useSkills()` 获取 Skills 数据
- 使用 `useMemo()` 优化性能
- 完善的 Loading/Error/Empty 状态处理

#### 1.2 创建 FeaturedSkillBanner 组件

**文件**: `apps/web/src/components/discover/FeaturedSkillBanner.tsx`

```typescript
'use client';

import React from 'react';
import { ArrowRight } from 'lucide-react';
import type { SkillMetadata } from '@/types/skill';

interface FeaturedSkillBannerProps {
  skill: SkillMetadata;
  campaign?: {
    title: string;
    subtitle?: string;
    badge?: string;
  };
  onClick: () => void;
}

export function FeaturedSkillBanner({ skill, campaign, onClick }: FeaturedSkillBannerProps) {
  return (
    <div
      onClick={onClick}
      className="relative overflow-hidden rounded-3xl cursor-pointer group h-[400px] lg:h-[480px]"
      style={{
        background: `linear-gradient(135deg, ${skill.color}15 0%, ${skill.color}05 50%, transparent 100%)`,
      }}
    >
      {/* 背景装饰 */}
      <div className="absolute inset-0 opacity-30" style={{
        backgroundImage: `radial-gradient(circle at 80% 20%, ${skill.color}40 0%, transparent 50%)`,
      }} />

      {/* 内容区 */}
      <div className="relative h-full flex flex-col justify-between p-8 lg:p-12">
        {/* 徽章 */}
        {campaign?.badge && (
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-bg-card/80 backdrop-blur-sm w-fit">
            <span className="w-2 h-2 rounded-full bg-accent-primary animate-pulse" />
            <span className="text-sm font-medium text-text-primary">{campaign.badge}</span>
          </div>
        )}

        {/* 主内容 */}
        <div className="space-y-4">
          <div className="text-6xl lg:text-8xl">{skill.icon}</div>
          <div className="space-y-2">
            <p className="text-sm font-medium text-text-secondary">{campaign?.title}</p>
            <h2 className="text-4xl lg:text-5xl font-bold text-text-primary">{skill.name}</h2>
            {campaign?.subtitle && (
              <p className="text-lg text-text-secondary">{campaign.subtitle}</p>
            )}
          </div>
          <p className="text-base text-text-secondary max-w-2xl line-clamp-2">{skill.description}</p>

          {/* CTA 按钮 */}
          <button className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-accent-primary text-text-inverse font-medium hover:bg-accent-primary/90 transition-all group-hover:gap-4">
            <span>立即探索</span>
            <ArrowRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
```

**设计要点：**
- 400-480px 高度（响应式）
- 渐变背景使用 Skill 品牌色
- 悬停动画效果

#### 1.3 创建 SkillShowcaseCard 组件

**文件**: `apps/web/src/components/discover/SkillShowcaseCard.tsx`

**规格：**
- 宽度：320px
- 高度：自适应
- 展示内容：图标、名称、描述、订阅状态、定价

#### 1.4 创建 CategorySection 组件

**文件**: `apps/web/src/components/discover/CategorySection.tsx`

**功能：**
- 分类标题 + 副标题
- 横向滚动容器
- 调用 SkillShowcaseCard 展示

### 步骤 2: 创建 API Routes

#### 2.1 Skills 列表 API

**文件**: `apps/web/src/app/api/v1/skills/route.ts`

```typescript
import { NextRequest, NextResponse } from "next/server";
import { getInternalApiUrl } from "@/lib/backend-config";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const backendUrl = getInternalApiUrl("/api/v1/skills");
    const url = new URL(backendUrl);

    // 转发查询参数
    searchParams.forEach((value, key) => {
      url.searchParams.append(key, value);
    });

    // 转发 Authorization header
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    const auth = request.headers.get("Authorization");
    if (auth) headers["Authorization"] = auth;

    const response = await fetch(url.toString(), {
      method: "GET",
      headers,
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error("Skills API error:", error);
    return NextResponse.json(
      { error: "Failed to fetch skills" },
      { status: 500 }
    );
  }
}
```

**关键点：**
- 代理后端 API（避免 CORS）
- 转发查询参数和认证头
- 错误处理

#### 2.2 订阅状态 API

**文件**: `apps/web/src/app/api/v1/skills/subscriptions/route.ts`

同上结构，代理 `/api/v1/skills/subscriptions`

#### 2.3 推荐 API

**文件**: `apps/web/src/app/api/v1/skills/recommendations/route.ts`

同上结构，代理 `/api/v1/skills/recommendations`

### 步骤 3: 修复 useSkillSubscription Hook

**问题**: API 路径重复（`/api/api/v1/skills`）

**文件**: `apps/web/src/hooks/useSkillSubscription.ts`

**修复前：**
```typescript
const response = await apiClient.get('/api/v1/skills');
```

**修复后：**
```typescript
const response = await apiClient.get('/v1/skills');
// apiClient 会自动加上 /api 前缀
// 最终请求: /api/v1/skills ✅
```

**修改位置：**
- `fetchSkills()` - 第33行
- `fetchSubscriptions()` - 第27行
- `fetchRecommendations()` - 第43行
- `subscribe()` - 第72行
- `unsubscribe()` - 第84行
- `togglePush()` - 第94行

### 步骤 4: 集成导航入口

#### 4.1 更新 PCLayout 导航

**文件**: `apps/web/src/components/layout/PCLayout.tsx`

```typescript
const NAV_ITEMS = [
  { id: 'home', path: '/', icon: '🏠', label: '首页' },
  { id: 'chat', path: '/chat', icon: '💬', label: '对话' },
  { id: 'discover', path: '/chat?tab=discover', icon: '✨', label: '探索' }, // 新增
  { id: 'identity', path: '/identity', icon: '💎', label: '身份画像' },
]
```

#### 4.2 更新 AppShell 支持 discover tab

**文件**: `apps/web/src/components/layout/AppShell.tsx`

```typescript
// V9.1: 4 entry points - Chat / Journey / Discover / Me
export type TabType = "chat" | "journey" | "discover" | "me";

interface AppShellProps {
  skill: SkillType;
  children: ReactNode;
  journeyContent?: ReactNode;
  discoverContent?: ReactNode; // 新增
  meContent?: ReactNode;
  defaultTab?: TabType;
}
```

#### 4.3 更新 NavBar 和 MobileTabBar

**NavBar.tsx** (PC导航):
```typescript
const NAV_ITEMS: NavItem[] = [
  { id: "chat", icon: MessageSquare, label: "对话" },
  { id: "journey", icon: Compass, label: "旅程" },
  { id: "discover", icon: Sparkles, label: "探索" }, // 新增
  { id: "me", icon: User, label: "我的" },
];
```

**MobileTabBar.tsx** (Mobile导航):
```typescript
const TAB_ITEMS: TabItem[] = [
  { id: "chat", icon: MessageSquare, label: "对话" },
  { id: "journey", icon: Compass, label: "旅程" },
  { id: "discover", icon: Sparkles, label: "探索" }, // 新增
  { id: "me", icon: User, label: "我的" },
];
```

#### 4.4 集成到 ChatPage

**文件**: `apps/web/src/app/chat/page.tsx`

```typescript
import { DiscoverContent as DiscoverContentComponent } from "@/components/discover";

const DiscoverContent = memo(function DiscoverContent() {
  return <DiscoverContentComponent />;
});

// 在 AppShell 中使用
<AppShell
  skill={skill}
  journeyContent={<Suspense><JourneyContent /></Suspense>}
  discoverContent={<Suspense><DiscoverContent /></Suspense>} {/* 新增 */}
  meContent={<Suspense><MeContent /></Suspense>}
>
```

### 步骤 5: 修复 Hydration 错误

#### 5.1 修复 NavBar localStorage 问题

**文件**: `apps/web/src/components/layout/NavBar.tsx`

**问题**: 初始化时从 localStorage 读取导致服务端和客户端不一致

**修复前:**
```typescript
const [isExpanded, setIsExpanded] = useState(() => {
  if (typeof window === "undefined") return false;
  return localStorage.getItem(STORAGE_KEY) === "true";
});
```

**修复后:**
```typescript
const [isExpanded, setIsExpanded] = useState(false);

useEffect(() => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved !== null) {
    setIsExpanded(saved === "true");
  }
}, []);
```

#### 5.2 修复 ResizablePanel usePersistentState

**文件**: `apps/web/src/components/layout/ResizablePanel.tsx`

**修复前:**
```typescript
const [state, setState] = useState<T>(() => {
  if (typeof window === "undefined") return initialValue;
  const stored = localStorage.getItem(key);
  return stored ? JSON.parse(stored) : initialValue;
});
```

**修复后:**
```typescript
const [state, setState] = useState<T>(initialValue);

useEffect(() => {
  const stored = localStorage.getItem(key);
  if (stored) {
    setState(JSON.parse(stored));
  }
}, [key]);
```

#### 5.3 修复 ChatContainer 时间数据

**文件**: `apps/web/src/components/chat/ChatContainer.tsx`

**问题**: `new Date()` 导致服务端和客户端时间不同

**修复后:**
```typescript
const [data, setData] = useState(() => ({
  greeting: "新的一天开始了",
  timeOfDay: "morning",
  // ... 默认值
}));

useEffect(() => {
  setData(getLocalGreetingData(skill));
}, [skill]);
```

## 验证步骤

### 1. 启动服务

```bash
# 后端
cd apps/api
uvicorn main:app --port 8100 --reload

# 前端
cd apps/web
pnpm dev --port 8232
```

### 2. 测试 API

```bash
# 测试 Skills 列表
curl http://localhost:8232/api/v1/skills | jq

# 预期输出
{
  "total": 8,
  "skills": [...],
  "categories": {...}
}
```

### 3. 浏览器验证

1. 访问 `http://localhost:8232`
2. 点击"探索"选项卡
3. 检查页面内容：
   - ✅ 精选横幅显示
   - ✅ 8 个 Skills 分类展示
   - ✅ 无 hydration 错误
   - ✅ 无 404 错误

### 4. 功能测试

- [ ] 精选横幅点击跳转
- [ ] Skill 卡片点击查看详情
- [ ] 订阅/取消订阅功能
- [ ] 横向滚动流畅
- [ ] 响应式布局正常

## 常见问题

见 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## 下一步

- [ ] 添加搜索功能
- [ ] 添加筛选功能
- [ ] 添加排序选项
- [ ] 优化加载性能
- [ ] 添加埋点统计

## 总结

本次集成涉及：
- ✅ 4 个新组件
- ✅ 3 个 API Routes
- ✅ 6 个文件修改
- ✅ 3 个 Hydration 修复
- ✅ 完整的导航集成

总代码行数：约 1200 行
总耗时：约 4 小时
