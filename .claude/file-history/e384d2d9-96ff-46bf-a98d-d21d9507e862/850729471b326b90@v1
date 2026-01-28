# Discover 功能问题排查指南

本文档记录了 Discover 功能开发和使用过程中遇到的所有问题及解决方案。

---

## 目录

- [常见问题](#常见问题)
- [Hydration 错误](#hydration-错误)
- [API 错误](#api-错误)
- [样式问题](#样式问题)
- [性能问题](#性能问题)
- [开发工具](#开发工具)

---

## 常见问题

### ❌ 问题 1: 页面一直显示 Loading

**症状:**
```
页面持续显示骨架屏，无法加载内容
```

**原因:**
- API 请求失败
- 网络问题
- 后端服务未启动

**解决方案:**

1. **检查后端服务**
```bash
# 检查后端是否运行
ps aux | grep uvicorn

# 应该看到
uvicorn main:app --port 8100 --reload
```

2. **测试 API**
```bash
# 测试后端 API
curl http://localhost:8100/api/v1/skills

# 测试前端 API Route
curl http://localhost:8232/api/v1/skills
```

3. **查看浏览器控制台**
```javascript
// 打开 DevTools Console
// 查看是否有错误信息
```

4. **检查环境变量**
```bash
# 检查 .env.local
cat apps/web/.env.local

# 应该包含
VIBELIFE_API_INTERNAL=http://127.0.0.1:8100
NEXT_PUBLIC_API_BASE=http://106.37.170.238:8100/api/v1
```

---

### ❌ 问题 2: 404 Not Found - /api/api/v1/skills

**症状:**
```
Failed to load resource: the server responded with a status of 404 (Not Found)
@ http://localhost:8232/api/api/v1/skills
```

**原因:**
URL 路径重复了 `api`，因为 `apiClient` 会自动添加 `/api` 前缀。

**错误代码:**
```typescript
// ❌ 错误
const response = await apiClient.get('/api/v1/skills');
// 实际请求: /api + /api/v1/skills = /api/api/v1/skills
```

**解决方案:**
```typescript
// ✅ 正确
const response = await apiClient.get('/v1/skills');
// 实际请求: /api + /v1/skills = /api/v1/skills
```

**修改文件:**
- `apps/web/src/hooks/useSkillSubscription.ts`
  - `fetchSkills()` - 第 33 行
  - `fetchSubscriptions()` - 第 27 行
  - `fetchRecommendations()` - 第 43 行
  - `subscribe()` - 第 72 行
  - `unsubscribe()` - 第 84 行
  - `togglePush()` - 第 94 行

---

### ❌ 问题 3: "探索"选项未显示

**症状:**
```
导航栏没有"探索"入口，只有"首页"、"对话"、"身份画像"
```

**原因:**
PCLayout 的导航配置未更新。

**解决方案:**

**文件**: `apps/web/src/components/layout/PCLayout.tsx`

```typescript
// ✅ 添加 discover 选项
const NAV_ITEMS = [
  { id: 'home', path: '/', icon: '🏠', label: '首页' },
  { id: 'chat', path: '/chat', icon: '💬', label: '对话' },
  { id: 'discover', path: '/chat?tab=discover', icon: '✨', label: '探索' }, // 新增
  { id: 'identity', path: '/identity', icon: '💎', label: '身份画像' },
]
```

---

### ❌ 问题 4: 点击"探索"显示空白页

**症状:**
```
点击"探索"后页面空白，无内容显示
```

**原因:**
- DiscoverContent 未集成到 AppShell
- ChatPage 未传递 discoverContent prop

**解决方案:**

**1. 更新 AppShell.tsx:**
```typescript
export type TabType = "chat" | "journey" | "discover" | "me";

interface AppShellProps {
  discoverContent?: ReactNode; // 添加
}

// 添加 discover case
switch (activeTab) {
  case "discover":
    return discoverContent || <div>Discover content not configured</div>;
  // ...
}
```

**2. 更新 ChatPage.tsx:**
```typescript
import { DiscoverContent as DiscoverContentComponent } from "@/components/discover";

<AppShell
  discoverContent={
    <Suspense fallback={<DiscoverLoadingFallback />}>
      <DiscoverContent />
    </Suspense>
  }
/>
```

---

## Hydration 错误

### ❌ 错误: Hydration failed because the initial UI does not match

**完整错误:**
```
Error: Hydration failed because the initial UI does not match what was rendered on the server.
Expected server HTML to contain a matching <span> in <div>.
```

**原因:**
服务端渲染和客户端首次渲染的 HTML 不一致，通常是因为：
1. 使用了 `localStorage`
2. 使用了 `new Date()`
3. 使用了浏览器特定 API

### 修复 1: NavBar localStorage

**问题代码:**
```typescript
// ❌ 错误 - 服务端返回 false，客户端可能返回 true
const [isExpanded, setIsExpanded] = useState(() => {
  if (typeof window === "undefined") return false;
  return localStorage.getItem(STORAGE_KEY) === "true";
});
```

**修复代码:**
```typescript
// ✅ 正确 - 服务端和客户端都返回 false，然后在 useEffect 中更新
const [isExpanded, setIsExpanded] = useState(false);

useEffect(() => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved !== null) {
    setIsExpanded(saved === "true");
  }
}, []);
```

**文件**: `apps/web/src/components/layout/NavBar.tsx`

### 修复 2: ResizablePanel usePersistentState

**问题代码:**
```typescript
// ❌ 错误
function usePersistentState<T>(key: string, initialValue: T) {
  const [state, setState] = useState<T>(() => {
    if (typeof window === "undefined") return initialValue;
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });
}
```

**修复代码:**
```typescript
// ✅ 正确
function usePersistentState<T>(key: string, initialValue: T) {
  const [state, setState] = useState<T>(initialValue);

  useEffect(() => {
    const stored = localStorage.getItem(key);
    if (stored) {
      setState(JSON.parse(stored));
    }
  }, [key]);

  const setValue = useCallback((value: T) => {
    setState(value);
    localStorage.setItem(key, JSON.stringify(value));
  }, [key]);

  return [state, setValue];
}
```

**文件**: `apps/web/src/components/layout/ResizablePanel.tsx`

### 修复 3: ChatContainer 时间数据

**问题代码:**
```typescript
// ❌ 错误 - 服务端和客户端的时间可能不同
const [data] = useState(() => getLocalGreetingData(skill));
// getLocalGreetingData 使用 new Date()
```

**修复代码:**
```typescript
// ✅ 正确 - 初始使用默认值，客户端再更新
const [data, setData] = useState(() => ({
  greeting: "新的一天开始了",
  timeOfDay: "morning",
  solarTerm: "立春",
  isoDate: new Date().toISOString().slice(0, 10),
  // ... 其他默认值
}));

useEffect(() => {
  setData(getLocalGreetingData(skill));
}, [skill]);
```

**文件**: `apps/web/src/components/chat/ChatContainer.tsx`

### Hydration 最佳实践

✅ **DO:**
1. 初始状态使用固定默认值
2. 在 `useEffect` 中读取浏览器 API
3. 使用 `'use client'` 标记客户端组件

❌ **DON'T:**
1. 在 `useState` 初始化中使用 `localStorage`
2. 在 `useState` 初始化中使用 `new Date()`
3. 在服务端组件中使用浏览器 API

---

## API 错误

### ❌ 401 Unauthorized

**症状:**
```
Failed to load resource: the server responded with a status of 401 (Unauthorized)
```

**原因:**
- 用户未登录
- Token 失效

**解决方案:**

```typescript
// 在 DiscoverContent 中处理未登录状态
const { user } = useAuth();
const { recommendations } = useSkillRecommendations({
  limit: 3,
  enabled: !!user, // 只有登录时才请求
});

// 推荐区域仅在有数据时显示
{recommendedSkills.length > 0 && (
  <CategorySection title="为你推荐" skills={recommendedSkills} />
)}
```

### ❌ 404 Not Found

**可能原因:**
1. API Route 未创建
2. URL 路径错误
3. 后端端点不存在

**排查步骤:**

```bash
# 1. 检查 API Route 是否存在
ls apps/web/src/app/api/v1/skills/

# 应该看到
route.ts
subscriptions/route.ts
recommendations/route.ts

# 2. 测试 API Route
curl http://localhost:8232/api/v1/skills

# 3. 测试后端 API
curl http://localhost:8100/api/v1/skills

# 4. 检查环境变量
echo $VIBELIFE_API_INTERNAL
```

---

## 样式问题

### ❌ 横向滚动不生效

**症状:**
```
Skill 卡片没有横向滚动，而是换行
```

**原因:**
缺少 `flex-shrink-0` 或滚动容器配置错误

**解决方案:**

```typescript
// ✅ 正确的横向滚动容器
<div className="flex gap-4 overflow-x-auto scrollbar-hide pb-4">
  {skills.map(skill => (
    <SkillShowcaseCard
      key={skill.id}
      skill={skill}
      className="w-80 flex-shrink-0" // 固定宽度 + 不缩小
    />
  ))}
</div>
```

### ❌ 响应式布局失效

**症状:**
```
Mobile 端显示错乱
```

**解决方案:**

```typescript
// 使用 Tailwind 响应式类名
<div className="h-[400px] lg:h-[480px]"> // Mobile: 400px, Desktop: 480px
<div className="px-4 lg:px-8 py-8"> // 响应式内边距
<div className="text-4xl lg:text-5xl"> // 响应式字体
```

---

## 性能问题

### ❌ 页面渲染卡顿

**原因:**
- 组件未使用 `memo`
- 过度渲染
- 大量计算未使用 `useMemo`

**解决方案:**

```typescript
// 1. 使用 memo
const DiscoverContent = memo(function DiscoverContent() {
  // ...
});

// 2. 使用 useMemo 缓存计算
const skillsByCategory = useMemo(() => {
  // 分组逻辑
}, [skills]);

// 3. 使用 useCallback 缓存函数
const handleSubscribe = useCallback(async (skillId: string) => {
  // 订阅逻辑
}, [subscribe, router]);
```

### ❌ API 请求过多

**症状:**
```
Network 面板显示大量重复请求
```

**解决方案:**

```typescript
// 使用 SWR 的 dedupingInterval
useSWR(key, fetcher, {
  dedupingInterval: 5 * 60 * 1000, // 5 分钟内不重复请求
  revalidateOnFocus: false, // 焦点时不重新验证
});
```

---

## 开发工具

### 调试 Skills 数据

```javascript
// 浏览器 Console
// 查看所有 Skills
fetch('/api/v1/skills').then(r => r.json()).then(console.log);

// 查看推荐
fetch('/api/v1/skills/recommendations?limit=5').then(r => r.json()).then(console.log);

// 查看订阅状态
fetch('/api/v1/skills/subscriptions').then(r => r.json()).then(console.log);
```

### 清除缓存

```javascript
// 清除 SWR 缓存
import { mutate } from 'swr';
mutate(() => true); // 清除所有缓存

// 清除特定缓存
mutate('skill-list');
mutate('skill-subscriptions');
```

### 查看 Hydration 错误详情

```bash
# 启用详细错误
# next.config.js
module.exports = {
  reactStrictMode: true,
  // 显示完整的 hydration 错误堆栈
}
```

### 性能分析

```javascript
// React DevTools Profiler
// 1. 打开 React DevTools
// 2. 点击 Profiler 标签
// 3. 点击"Record"
// 4. 操作页面
// 5. 查看渲染时间
```

---

## 快速诊断清单

遇到问题时，按以下顺序检查：

- [ ] 后端服务是否运行？(`ps aux | grep uvicorn`)
- [ ] 前端服务是否运行？(`ps aux | grep next`)
- [ ] API Route 是否创建？(`ls apps/web/src/app/api/v1/skills/`)
- [ ] URL 路径是否正确？(不要重复 `/api`)
- [ ] 浏览器控制台有无错误？
- [ ] Network 面板请求是否成功？
- [ ] 环境变量是否配置？(`cat .env.local`)
- [ ] 组件是否正确集成？(检查 AppShell)
- [ ] Hydration 错误？(检查 localStorage 和时间相关代码)

---

## 获取帮助

如果以上方法都无法解决问题：

1. **查看完整错误堆栈**
```bash
# 查看前端日志
tail -f apps/web/.next/trace

# 查看后端日志
tail -f apps/api/logs/app.log
```

2. **启用调试模式**
```typescript
// 在组件中添加
useEffect(() => {
  console.log('Skills:', skills);
  console.log('Error:', error);
  console.log('Loading:', isLoading);
}, [skills, error, isLoading]);
```

3. **提交 Issue**
包含以下信息：
- 错误截图
- 浏览器控制台输出
- Network 面板截图
- 操作步骤
- 环境信息（OS、Node 版本、浏览器版本）

---

## 相关文档

- [README](./README.md)
- [集成指南](./INTEGRATION.md)
- [组件文档](./COMPONENTS.md)
- [API 文档](./API.md)
