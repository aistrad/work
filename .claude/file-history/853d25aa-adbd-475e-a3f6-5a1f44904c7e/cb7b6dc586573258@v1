# Discover 组件文档

## 组件概览

Discover 功能包含 4 个核心组件：

1. **DiscoverContent** - 主容器组件
2. **FeaturedSkillBanner** - 精选横幅
3. **SkillShowcaseCard** - Skill 展示卡片
4. **CategorySection** - 分类区域

---

## 1. DiscoverContent

### 描述

主容器组件，负责数据获取、状态管理和页面布局。

### Props

无外部 props，内部使用多个 hooks。

### Hooks 使用

```typescript
const { user } = useAuth();
const { skills, categories, isLoading, error } = useSkills();
const { userStatuses, subscribe, unsubscribe } = useSkillSubscription();
const { recommendations } = useSkillRecommendations({ limit: 3, enabled: !!user });
```

### 状态处理

**Loading 状态:**
```typescript
if (isLoading) {
  return <LoadingSkeleton />;
}
```
- 显示骨架屏动画
- 3 个区域的占位符

**Error 状态:**
```typescript
if (error) {
  return <ErrorState />;
}
```
- 红色警告图标
- "加载失败"提示
- 重新加载按钮

**Empty 状态:**
```typescript
if (!skills || skills.length === 0) {
  return <EmptyState />;
}
```
- Sparkles 图标
- "即将推出"提示

### 数据处理

**按分类分组:**
```typescript
const skillsByCategory = useMemo(() => {
  const grouped: Record<string, SkillMetadata[]> = {
    professional: [],
    default: [],
    core: [],
  };
  for (const skill of skills) {
    if (grouped[skill.category]) {
      grouped[skill.category].push(skill);
    }
  }
  return grouped;
}, [skills]);
```

**精选 Skill 选择:**
```typescript
const featuredSkill = useMemo(() => {
  return skillsByCategory.professional[0] ||
         skillsByCategory.default[0] ||
         skills[0];
}, [skillsByCategory, skills]);
```

### 事件处理

**订阅处理:**
```typescript
const handleSubscribe = async (skillId: string) => {
  if (!user) {
    router.push('/auth/login?redirect=/chat');
    return;
  }
  try {
    await subscribe(skillId);
  } catch (error: any) {
    if (error?.response?.status === 402) {
      router.push(`/membership?reason=skill_subscribe&skill=${skillId}`);
    }
  }
};
```

**取消订阅:**
```typescript
const handleUnsubscribe = async (skillId: string) => {
  if (!user) return;
  await unsubscribe(skillId);
};
```

**Skill 点击:**
```typescript
const handleSkillClick = (skillId: string) => {
  router.push(`/skills/${skillId}`);
};
```

### 布局结构

```typescript
<div className="h-full overflow-y-auto bg-bg-primary">
  <div className="max-w-7xl mx-auto px-4 lg:px-8 py-8 space-y-12">
    {/* 精选横幅 */}
    <FeaturedSkillBanner />

    {/* 为你推荐 */}
    {recommendedSkills.length > 0 && <CategorySection />}

    {/* 专业技能 */}
    <CategorySection title="专业技能" skills={professional} />

    {/* 基础功能 */}
    <CategorySection title="基础功能" skills={default} />

    {/* 核心能力 */}
    <CategorySection title="核心能力" skills={core} />
  </div>
</div>
```

### 性能优化

- 使用 `useMemo()` 缓存计算结果
- 使用 `useCallback()` 缓存事件处理器
- SWR 自动缓存和重新验证

---

## 2. FeaturedSkillBanner

### 描述

App Store 风格的精选横幅，用于突出展示推荐 Skill。

### Props

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

### Props 详解

| Prop | 类型 | 必需 | 描述 |
|------|------|------|------|
| `skill` | `SkillMetadata` | ✅ | Skill 元数据对象 |
| `campaign` | `object` | ❌ | 活动信息 |
| `campaign.title` | `string` | ❌ | 主标题（如"精选推荐"） |
| `campaign.subtitle` | `string` | ❌ | 副标题 |
| `campaign.badge` | `string` | ❌ | 徽章文本（如"编辑推荐"） |
| `onClick` | `() => void` | ✅ | 点击事件处理器 |

### 样式规范

**高度:**
- Mobile: `400px`
- Desktop: `480px`

**背景:**
```typescript
background: `linear-gradient(135deg, ${skill.color}15 0%, ${skill.color}05 50%, transparent 100%)`
```

**装饰层:**
```typescript
backgroundImage: `radial-gradient(circle at 80% 20%, ${skill.color}40 0%, transparent 50%)`
```

### 使用示例

```typescript
<FeaturedSkillBanner
  skill={baziSkill}
  campaign={{
    title: '精选推荐',
    subtitle: '开启你的自我探索之旅',
    badge: '编辑推荐',
  }}
  onClick={() => router.push('/skills/bazi')}
/>
```

### 视觉效果

- 悬停时箭头向右移动（`group-hover:gap-4`）
- 徽章背景模糊效果（`backdrop-blur-sm`）
- 脉冲动画（`animate-pulse`）

---

## 3. SkillShowcaseCard

### 描述

320px 宽度的 Skill 展示卡片，用于横向滚动列表。

### Props

```typescript
interface SkillShowcaseCardProps {
  skill: SkillMetadata;
  userStatus?: SkillUserStatus;
  onClick: () => void;
  onSubscribe?: () => void;
}
```

### Props 详解

| Prop | 类型 | 必需 | 描述 |
|------|------|------|------|
| `skill` | `SkillMetadata` | ✅ | Skill 元数据 |
| `userStatus` | `SkillUserStatus` | ❌ | 用户订阅状态 |
| `onClick` | `() => void` | ✅ | 卡片点击事件 |
| `onSubscribe` | `() => void` | ❌ | 订阅按钮点击事件 |

### SkillMetadata 类型

```typescript
interface SkillMetadata {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
  category: 'core' | 'default' | 'professional';
  pricing: {
    type: 'free' | 'premium' | 'credits';
    trial_messages?: number;
  };
  showcase: {
    tagline: string;
    highlights: string[];
    preview_image?: string;
  };
}
```

### 样式规范

**尺寸:**
- 宽度: `320px` (固定)
- 高度: 自适应（约 `256px`）

**布局:**
```typescript
className="w-80 flex-shrink-0 rounded-2xl bg-bg-card border border-border hover:border-accent-primary transition-all cursor-pointer"
```

### 内容结构

1. **图标区域** - 64x64px, Skill 品牌色背景
2. **标题** - Skill 名称
3. **描述** - 2 行截断
4. **标签栏** - 定价类型、订阅状态
5. **操作按钮** - "获取" / "已订阅"

### 使用示例

```typescript
<SkillShowcaseCard
  skill={baziSkill}
  userStatus={{
    subscribed: true,
    push_enabled: true,
    trial_messages_used: 0,
    trial_messages_remaining: 3,
  }}
  onClick={() => handleSkillClick('bazi')}
  onSubscribe={() => handleSubscribe('bazi')}
/>
```

---

## 4. CategorySection

### 描述

分类区域容器，包含标题和横向滚动的 Skill 列表。

### Props

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

### Props 详解

| Prop | 类型 | 必需 | 描述 |
|------|------|------|------|
| `title` | `string` | ✅ | 分类标题 |
| `subtitle` | `string` | ❌ | 分类副标题 |
| `skills` | `SkillMetadata[]` | ✅ | Skill 列表 |
| `userStatuses` | `Record<string, SkillUserStatus>` | ✅ | 用户状态映射 |
| `onSkillClick` | `(id: string) => void` | ✅ | Skill 点击事件 |
| `onSubscribe` | `(id: string) => void` | ✅ | 订阅事件 |

### 布局结构

```typescript
<div className="space-y-4">
  {/* 标题区 */}
  <div className="flex items-baseline justify-between">
    <h2 className="text-2xl font-bold">{title}</h2>
    {subtitle && <p className="text-text-secondary">{subtitle}</p>}
  </div>

  {/* 横向滚动容器 */}
  <div className="flex gap-4 overflow-x-auto scrollbar-hide pb-4">
    {skills.map(skill => (
      <SkillShowcaseCard
        key={skill.id}
        skill={skill}
        userStatus={userStatuses[skill.id]}
        onClick={() => onSkillClick(skill.id)}
        onSubscribe={() => onSubscribe(skill.id)}
      />
    ))}
  </div>
</div>
```

### 滚动行为

- 使用 `overflow-x-auto` 实现横向滚动
- 使用 `scrollbar-hide` 隐藏滚动条
- 使用 `pb-4` 添加底部内边距

### 使用示例

```typescript
<CategorySection
  title="专业技能"
  subtitle="深度探索，专业洞察"
  skills={professionalSkills}
  userStatuses={userStatuses}
  onSkillClick={handleSkillClick}
  onSubscribe={handleSubscribe}
/>
```

---

## 类型定义

### SkillUserStatus

```typescript
interface SkillUserStatus {
  subscribed: boolean;
  push_enabled: boolean;
  trial_messages_used: number;
  trial_messages_remaining: number | null;
  subscribed_at?: string;
}
```

### SkillListResponse

```typescript
interface SkillListResponse {
  skills: SkillWithUserStatus[];
  categories: {
    core: { name: string; description: string; count: number };
    default: { name: string; description: string; count: number };
    professional: { name: string; description: string; count: number };
  };
  total: number;
}
```

### SkillRecommendation

```typescript
interface SkillRecommendation {
  skill_id: string;
  skill: {
    id: string;
    name: string;
    icon: string;
    color: string;
    tagline: string;
  };
  reason: string;
  context: string;
  score: number;
  trial_messages_remaining: number | null;
}
```

---

## Hooks 使用

### useSkills

```typescript
const { skills, categories, total, isLoading, error, refresh } = useSkills(category?);
```

**返回值:**
- `skills`: Skill 数组
- `categories`: 分类统计
- `total`: 总数
- `isLoading`: 加载状态
- `error`: 错误对象
- `refresh`: 刷新函数

### useSkillSubscription

```typescript
const {
  subscriptions,
  summary,
  userStatuses,
  subscribe,
  unsubscribe,
  togglePush,
  isSubscribed,
  isPushEnabled,
  isLoading,
  error,
} = useSkillSubscription();
```

**返回值:**
- `subscriptions`: 订阅列表
- `summary`: 统计摘要
- `userStatuses`: 状态映射
- `subscribe(skillId, pushEnabled?)`: 订阅函数
- `unsubscribe(skillId)`: 取消订阅函数
- `togglePush(skillId, enabled)`: 切换推送
- `isSubscribed(skillId)`: 检查是否订阅
- `isPushEnabled(skillId)`: 检查推送是否开启

### useSkillRecommendations

```typescript
const { recommendations, generatedAt, isLoading, error, refresh } =
  useSkillRecommendations({ limit: 3, context?: string, enabled?: boolean });
```

**参数:**
- `limit`: 返回数量（默认 3，最大 10）
- `context`: 上下文关键词
- `enabled`: 是否启用（默认 true）

**返回值:**
- `recommendations`: 推荐列表
- `generatedAt`: 生成时间
- `isLoading`: 加载状态
- `error`: 错误对象
- `refresh`: 刷新函数

---

## 样式规范

### Tailwind 类名约定

**背景:**
- 主背景: `bg-bg-primary`
- 卡片背景: `bg-bg-card`
- 次要背景: `bg-bg-secondary`

**文本:**
- 主文本: `text-text-primary`
- 次要文本: `text-text-secondary`
- 反色文本: `text-text-inverse`

**边框:**
- 默认边框: `border-border`
- 主色边框: `border-accent-primary`

**圆角:**
- 小圆角: `rounded-lg` (8px)
- 中圆角: `rounded-2xl` (16px)
- 大圆角: `rounded-3xl` (24px)
- 全圆角: `rounded-full`

**间距:**
- 小间距: `gap-2` / `space-y-2` (8px)
- 中间距: `gap-4` / `space-y-4` (16px)
- 大间距: `gap-8` / `space-y-8` (32px)
- 超大间距: `space-y-12` (48px)

### 响应式断点

```typescript
// Mobile
// 默认样式

// Tablet
lg: // ≥1024px

// Desktop
xl: // ≥1280px
```

---

## 性能优化

### 1. 组件 Memo化

```typescript
const DiscoverContent = memo(function DiscoverContent() {
  // ...
});
```

### 2. useMemo 缓存计算

```typescript
const skillsByCategory = useMemo(() => {
  // 分组逻辑
}, [skills]);
```

### 3. useCallback 缓存函数

```typescript
const handleSubscribe = useCallback(async (skillId: string) => {
  // 订阅逻辑
}, [subscribe, router, user]);
```

### 4. SWR 缓存策略

```typescript
useSWR(key, fetcher, {
  revalidateOnFocus: false,
  dedupingInterval: 5 * 60 * 1000, // 5 分钟去重
});
```

### 5. Suspense 懒加载

```typescript
<Suspense fallback={<DiscoverLoadingFallback />}>
  <DiscoverContent />
</Suspense>
```

---

## 最佳实践

1. **始终处理 Loading/Error/Empty 状态**
2. **使用 TypeScript 类型检查**
3. **组件单一职责原则**
4. **合理使用 Memo 和 Callback**
5. **保持组件可测试性**
6. **遵循 Tailwind CSS 规范**
7. **使用语义化 HTML 标签**
8. **确保无障碍访问（a11y）**

---

## 测试建议

### 单元测试

```typescript
describe('DiscoverContent', () => {
  it('should render loading state', () => {
    // 测试 Loading 状态
  });

  it('should render error state', () => {
    // 测试 Error 状态
  });

  it('should render skills correctly', () => {
    // 测试正常渲染
  });
});
```

### 集成测试

```typescript
describe('Discover Flow', () => {
  it('should navigate to skill detail', () => {
    // 测试导航流程
  });

  it('should subscribe to skill', () => {
    // 测试订阅流程
  });
});
```

---

## 相关文档

- [集成指南](./INTEGRATION.md)
- [API 文档](./API.md)
- [问题排查](./TROUBLESHOOTING.md)
