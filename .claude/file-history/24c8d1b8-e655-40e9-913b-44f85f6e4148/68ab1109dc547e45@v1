# Skill Management UI Components

> 前端组件设计规格

---

## 1. 组件总览

```
components/skill/
├── SkillCard.tsx              # Skill 卡片 (多变体)
├── SkillList.tsx              # Skill 列表
├── SkillMarketPage.tsx        # Skill 市场页面
├── SkillDetailPage.tsx        # Skill 详情页
├── SkillRecommendation.tsx    # 对话内推荐卡片
├── SkillSubscriptionToggle.tsx # 订阅开关
├── SkillPushToggle.tsx        # 推送开关
├── SkillSettingsSection.tsx   # 设置页 Skill 管理区块
├── SkillHomeWidget.tsx        # 首页推荐卡片
└── index.ts
```

---

## 2. SkillCard 组件

### 2.1 Props 定义

```typescript
// types/skill.ts

export interface SkillMetadata {
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
  features: Array<{
    name: string;
    description?: string;
    icon?: string;
    tier?: 'free' | 'basic' | 'premium';
  }>;
  showcase: {
    tagline: string;
    highlights: string[];
    preview_image?: string;
    demo_prompts?: string[];
  };
  triggers: string[];
}

export interface SkillUserStatus {
  subscribed: boolean;
  push_enabled: boolean;
  trial_messages_used: number;
  trial_messages_remaining: number;
}

export interface SkillCardProps {
  skill: SkillMetadata;
  variant: 'compact' | 'card' | 'detail' | 'inline';
  userStatus?: SkillUserStatus;
  showActions?: boolean;
  className?: string;

  // 事件回调
  onSubscribe?: () => void;
  onUnsubscribe?: () => void;
  onTogglePush?: (enabled: boolean) => void;
  onTry?: () => void;
  onLearnMore?: () => void;
  onClick?: () => void;
}
```

### 2.2 Compact 变体

用于列表项、快速选择场景。

```tsx
// 高度固定 64px，水平布局

<div className="flex items-center gap-3 p-3 rounded-lg bg-bg-card hover:bg-bg-card-hover transition-colors">
  {/* Icon */}
  <div
    className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
    style={{ backgroundColor: `${skill.color}20` }}
  >
    {skill.icon}
  </div>

  {/* Content */}
  <div className="flex-1 min-w-0">
    <h4 className="text-sm font-medium text-text-primary truncate">
      {skill.name}
    </h4>
    <p className="text-xs text-text-secondary truncate">
      {skill.description}
    </p>
  </div>

  {/* Status / Action */}
  {userStatus?.subscribed ? (
    <span className="px-2 py-0.5 text-xs rounded-full bg-success/10 text-success">
      已订阅
    </span>
  ) : (
    <button className="px-3 py-1 text-xs rounded-full bg-accent text-white">
      订阅
    </button>
  )}
</div>
```

### 2.3 Card 变体

用于市场展示、网格布局。

```tsx
// 宽度自适应，高度 auto

<div className="rounded-xl bg-bg-card border border-border-light overflow-hidden hover:shadow-lg transition-shadow">
  {/* Header */}
  <div
    className="p-4 pb-3"
    style={{ background: `linear-gradient(135deg, ${skill.color}10, ${skill.color}05)` }}
  >
    <div className="flex items-start justify-between">
      <div className="flex items-center gap-3">
        <div
          className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl"
          style={{ backgroundColor: `${skill.color}20` }}
        >
          {skill.icon}
        </div>
        <div>
          <h3 className="font-semibold text-text-primary">{skill.name}</h3>
          <p className="text-xs text-text-secondary">{skill.showcase.tagline}</p>
        </div>
      </div>
      <StatusBadge status={userStatus} category={skill.category} />
    </div>
  </div>

  {/* Features */}
  <div className="px-4 py-3 border-t border-border-light">
    <div className="flex flex-wrap gap-2">
      {skill.features.slice(0, 3).map((feature) => (
        <span
          key={feature.name}
          className="px-2 py-0.5 text-xs rounded-full bg-bg-secondary text-text-secondary"
        >
          {feature.icon} {feature.name}
        </span>
      ))}
    </div>
  </div>

  {/* Actions */}
  <div className="px-4 py-3 border-t border-border-light flex items-center justify-between">
    {userStatus?.subscribed ? (
      <>
        <PushToggle enabled={userStatus.push_enabled} onToggle={onTogglePush} />
        <button
          onClick={onLearnMore}
          className="text-sm text-accent hover:underline"
        >
          查看详情
        </button>
      </>
    ) : (
      <>
        <TrialBadge remaining={skill.pricing.trial_messages} />
        <button
          onClick={onTry}
          className="px-4 py-1.5 text-sm rounded-lg bg-accent text-white hover:bg-accent-hover"
        >
          立即试用
        </button>
      </>
    )}
  </div>
</div>
```

### 2.4 Detail 变体

用于详情页 Hero 区域。

```tsx
// 全宽，高度 200-300px

<div className="relative overflow-hidden rounded-2xl">
  {/* Background */}
  <div
    className="absolute inset-0"
    style={{
      background: `linear-gradient(135deg, ${skill.color}30, ${skill.color}10)`,
    }}
  />

  {/* Content */}
  <div className="relative p-6 md:p-8">
    <div className="flex flex-col md:flex-row md:items-center gap-6">
      {/* Icon */}
      <div
        className="w-20 h-20 rounded-2xl flex items-center justify-center text-4xl shrink-0"
        style={{ backgroundColor: `${skill.color}20` }}
      >
        {skill.icon}
      </div>

      {/* Info */}
      <div className="flex-1">
        <div className="flex items-center gap-2 mb-2">
          <h1 className="text-2xl font-bold text-text-primary">{skill.name}</h1>
          <CategoryBadge category={skill.category} />
        </div>
        <p className="text-text-secondary mb-4">{skill.description}</p>

        {/* Highlights */}
        <div className="flex flex-wrap gap-2">
          {skill.showcase.highlights.map((highlight) => (
            <span
              key={highlight}
              className="px-3 py-1 text-sm rounded-full bg-white/50 text-text-primary"
            >
              {highlight}
            </span>
          ))}
        </div>
      </div>

      {/* Action */}
      <div className="shrink-0">
        {userStatus?.subscribed ? (
          <SubscribedActions
            userStatus={userStatus}
            onTogglePush={onTogglePush}
            onUnsubscribe={onUnsubscribe}
          />
        ) : (
          <SubscribeActions
            pricing={skill.pricing}
            onSubscribe={onSubscribe}
            onTry={onTry}
          />
        )}
      </div>
    </div>
  </div>
</div>
```

### 2.5 Inline 变体

用于对话中内嵌推荐。

```tsx
// 宽度 100%，嵌入对话流

<div className="my-3 p-4 rounded-xl bg-bg-callout border border-border-light">
  <div className="flex items-start gap-3">
    {/* Icon */}
    <div
      className="w-10 h-10 rounded-xl flex items-center justify-center text-xl shrink-0"
      style={{ backgroundColor: `${skill.color}20` }}
    >
      {skill.icon}
    </div>

    {/* Content */}
    <div className="flex-1 min-w-0">
      <div className="flex items-center gap-2 mb-1">
        <span className="text-xs text-accent font-medium">发现相关能力</span>
      </div>
      <h4 className="font-medium text-text-primary">{skill.name}</h4>
      <p className="text-sm text-text-secondary mt-1">{context}</p>

      {/* Actions */}
      <div className="flex items-center gap-2 mt-3">
        <button
          onClick={onTry}
          className="px-3 py-1.5 text-sm rounded-lg bg-accent text-white"
        >
          立即试用
        </button>
        <button
          onClick={onLearnMore}
          className="px-3 py-1.5 text-sm rounded-lg border border-border text-text-secondary hover:bg-bg-secondary"
        >
          了解更多
        </button>
      </div>
    </div>

    {/* Dismiss */}
    <button
      onClick={onDismiss}
      className="text-text-tertiary hover:text-text-secondary"
    >
      <XIcon className="w-4 h-4" />
    </button>
  </div>
</div>
```

---

## 3. SkillList 组件

```typescript
interface SkillListProps {
  skills: SkillMetadata[];
  userStatuses: Record<string, SkillUserStatus>;
  layout: 'list' | 'grid';
  groupBy?: 'category' | 'none';
  showFilters?: boolean;
  onSkillClick: (skillId: string) => void;
  onSubscribe: (skillId: string) => void;
  onUnsubscribe: (skillId: string) => void;
  onTogglePush: (skillId: string, enabled: boolean) => void;
}
```

```tsx
export function SkillList({
  skills,
  userStatuses,
  layout = 'grid',
  groupBy = 'category',
  showFilters = true,
  ...handlers
}: SkillListProps) {
  const [filter, setFilter] = useState<string>('all');

  // 分组逻辑
  const grouped = useMemo(() => {
    if (groupBy === 'none') {
      return { all: skills };
    }
    return groupBy === 'category'
      ? groupByCategory(skills)
      : { all: skills };
  }, [skills, groupBy]);

  return (
    <div className="space-y-6">
      {/* Filters */}
      {showFilters && (
        <div className="flex gap-2 overflow-x-auto pb-2">
          {['all', 'professional', 'default', 'subscribed'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={cn(
                'px-4 py-1.5 text-sm rounded-full whitespace-nowrap transition-colors',
                filter === f
                  ? 'bg-accent text-white'
                  : 'bg-bg-secondary text-text-secondary hover:bg-bg-tertiary'
              )}
            >
              {FILTER_LABELS[f]}
            </button>
          ))}
        </div>
      )}

      {/* Groups */}
      {Object.entries(grouped).map(([group, groupSkills]) => (
        <div key={group}>
          {groupBy !== 'none' && (
            <h2 className="text-lg font-semibold text-text-primary mb-3">
              {CATEGORY_LABELS[group]}
            </h2>
          )}

          <div
            className={cn(
              layout === 'grid'
                ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4'
                : 'space-y-2'
            )}
          >
            {groupSkills
              .filter((s) => filterMatch(s, filter, userStatuses[s.id]))
              .map((skill) => (
                <SkillCard
                  key={skill.id}
                  skill={skill}
                  variant={layout === 'grid' ? 'card' : 'compact'}
                  userStatus={userStatuses[skill.id]}
                  onClick={() => handlers.onSkillClick(skill.id)}
                  onSubscribe={() => handlers.onSubscribe(skill.id)}
                  onUnsubscribe={() => handlers.onUnsubscribe(skill.id)}
                  onTogglePush={(enabled) => handlers.onTogglePush(skill.id, enabled)}
                />
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}
```

---

## 4. SkillRecommendation 组件

对话中的智能推荐卡片。

```typescript
interface SkillRecommendationProps {
  recommendation: {
    skill_id: string;
    reason: 'based_on_conversation' | 'based_on_emotion' | 'based_on_profile';
    context: string;
    score: number;
  };
  skill: SkillMetadata;
  onTry: () => void;
  onLearnMore: () => void;
  onDismiss: () => void;
  onNeverShow: () => void;
}
```

```tsx
export function SkillRecommendation({
  recommendation,
  skill,
  onTry,
  onLearnMore,
  onDismiss,
  onNeverShow,
}: SkillRecommendationProps) {
  return (
    <div className="my-4 animate-slide-in-up">
      {/* 使用 inline 变体的 SkillCard */}
      <SkillCard
        skill={skill}
        variant="inline"
        context={recommendation.context}
        onTry={onTry}
        onLearnMore={onLearnMore}
      />

      {/* 底部操作 */}
      <div className="flex items-center justify-end gap-4 mt-2 px-4">
        <button
          onClick={onNeverShow}
          className="text-xs text-text-tertiary hover:text-text-secondary"
        >
          不再推荐此 Skill
        </button>
        <button
          onClick={onDismiss}
          className="text-xs text-text-tertiary hover:text-text-secondary"
        >
          暂时隐藏
        </button>
      </div>
    </div>
  );
}
```

---

## 5. SkillSettingsSection 组件

设置页面中的 Skill 管理区块。

```tsx
export function SkillSettingsSection() {
  const { subscriptions, togglePush, unsubscribe } = useSkillSubscription();
  const router = useRouter();

  // 分组：已订阅 vs 可订阅
  const { subscribed, available } = useMemo(() => {
    return {
      subscribed: subscriptions.filter((s) => s.status === 'subscribed'),
      available: subscriptions.filter((s) => s.status !== 'subscribed'),
    };
  }, [subscriptions]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-text-primary">Skill 管理</h2>
        <button
          onClick={() => router.push('/skills')}
          className="text-sm text-accent hover:underline"
        >
          探索更多 →
        </button>
      </div>

      {/* 已订阅 */}
      <div>
        <h3 className="text-sm font-medium text-text-secondary mb-3">
          已订阅 ({subscribed.length})
        </h3>
        <div className="space-y-2">
          {subscribed.map((sub) => (
            <SkillSettingsItem
              key={sub.skill_id}
              subscription={sub}
              onTogglePush={(enabled) => togglePush(sub.skill_id, enabled)}
              onUnsubscribe={() => unsubscribe(sub.skill_id)}
            />
          ))}
        </div>
      </div>

      {/* 可订阅 */}
      {available.length > 0 && (
        <div>
          <h3 className="text-sm font-medium text-text-secondary mb-3">
            可订阅 ({available.length})
          </h3>
          <div className="space-y-2">
            {available.slice(0, 3).map((sub) => (
              <SkillSettingsItem
                key={sub.skill_id}
                subscription={sub}
                variant="available"
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function SkillSettingsItem({
  subscription,
  variant = 'subscribed',
  onTogglePush,
  onUnsubscribe,
}: {
  subscription: SkillSubscription;
  variant?: 'subscribed' | 'available';
  onTogglePush?: (enabled: boolean) => void;
  onUnsubscribe?: () => void;
}) {
  const skill = useSkillMetadata(subscription.skill_id);
  if (!skill) return null;

  const isCore = skill.category === 'core';

  return (
    <div className="flex items-center gap-3 p-3 rounded-lg bg-bg-card">
      {/* Icon */}
      <div
        className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
        style={{ backgroundColor: `${skill.color}20` }}
      >
        {skill.icon}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-text-primary">{skill.name}</span>
          {isCore && (
            <span className="px-1.5 py-0.5 text-xs rounded bg-accent/10 text-accent">
              始终激活
            </span>
          )}
        </div>
        <p className="text-xs text-text-secondary truncate">
          {skill.features.slice(0, 2).map((f) => f.name).join(' · ')}
        </p>
      </div>

      {/* Actions */}
      {variant === 'subscribed' ? (
        <div className="flex items-center gap-3">
          {!isCore && (
            <>
              <div className="flex items-center gap-2">
                <span className="text-xs text-text-tertiary">推送</span>
                <Toggle
                  checked={subscription.push_enabled}
                  onChange={onTogglePush}
                  size="sm"
                />
              </div>
              <button
                onClick={onUnsubscribe}
                className="text-xs text-error hover:underline"
              >
                取消订阅
              </button>
            </>
          )}
        </div>
      ) : (
        <button className="px-3 py-1 text-xs rounded-full bg-accent text-white">
          订阅
        </button>
      )}
    </div>
  );
}
```

---

## 6. SkillHomeWidget 组件

首页侧边栏推荐卡片。

```tsx
export function SkillHomeWidget() {
  const { recommendations, isLoading } = useSkillRecommendations();
  const router = useRouter();

  if (isLoading) {
    return <SkillHomeWidgetSkeleton />;
  }

  if (!recommendations || recommendations.length === 0) {
    return null;
  }

  const topRecommendation = recommendations[0];
  const skill = useSkillMetadata(topRecommendation.skill_id);

  if (!skill) return null;

  return (
    <Card variant="default" padding="md" className="mb-4">
      <div className="flex items-center gap-2 mb-3">
        <span className="text-sm">💡</span>
        <h3 className="text-sm font-semibold text-text-primary">为你推荐</h3>
      </div>

      <div
        className="p-3 rounded-xl cursor-pointer hover:bg-bg-secondary transition-colors"
        style={{ background: `linear-gradient(135deg, ${skill.color}10, transparent)` }}
        onClick={() => router.push(`/skills/${skill.id}`)}
      >
        <div className="flex items-center gap-3 mb-2">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
            style={{ backgroundColor: `${skill.color}20` }}
          >
            {skill.icon}
          </div>
          <div>
            <h4 className="font-medium text-text-primary">{skill.name}</h4>
            <p className="text-xs text-text-secondary">{skill.showcase.tagline}</p>
          </div>
        </div>

        <p className="text-sm text-text-secondary mb-3">
          {topRecommendation.context}
        </p>

        <div className="flex items-center justify-between">
          <span className="text-xs text-text-tertiary">
            {skill.pricing.trial_messages} 条免费体验
          </span>
          <span className="text-xs text-accent font-medium">
            立即体验 →
          </span>
        </div>
      </div>

      <button
        onClick={() => router.push('/skills')}
        className="w-full mt-3 text-xs text-text-secondary hover:text-accent text-center"
      >
        查看全部 Skill →
      </button>
    </Card>
  );
}
```

---

## 7. Hooks

### 7.1 useSkillSubscription

```typescript
// hooks/useSkillSubscription.ts

export function useSkillSubscription() {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // 获取订阅列表
  const { data: subscriptions = [], isLoading } = useQuery({
    queryKey: ['skill-subscriptions', user?.id],
    queryFn: () => api.get('/skills/subscriptions').then((r) => r.data.subscriptions),
    enabled: !!user,
  });

  // 订阅
  const subscribeMutation = useMutation({
    mutationFn: (skillId: string) => api.post(`/skills/${skillId}/subscribe`),
    onSuccess: () => queryClient.invalidateQueries(['skill-subscriptions']),
  });

  // 取消订阅
  const unsubscribeMutation = useMutation({
    mutationFn: (skillId: string) => api.post(`/skills/${skillId}/unsubscribe`),
    onSuccess: () => queryClient.invalidateQueries(['skill-subscriptions']),
  });

  // 切换推送
  const togglePushMutation = useMutation({
    mutationFn: ({ skillId, enabled }: { skillId: string; enabled: boolean }) =>
      api.post(`/skills/${skillId}/push`, { enabled }),
    onSuccess: () => queryClient.invalidateQueries(['skill-subscriptions']),
  });

  return {
    subscriptions,
    isLoading,
    subscribe: (skillId: string) => subscribeMutation.mutateAsync(skillId),
    unsubscribe: (skillId: string) => unsubscribeMutation.mutateAsync(skillId),
    togglePush: (skillId: string, enabled: boolean) =>
      togglePushMutation.mutateAsync({ skillId, enabled }),
    isSubscribed: (skillId: string) =>
      subscriptions.some((s) => s.skill_id === skillId && s.status === 'subscribed'),
    isPushEnabled: (skillId: string) =>
      subscriptions.find((s) => s.skill_id === skillId)?.push_enabled ?? false,
  };
}
```

### 7.2 useSkillRecommendations

```typescript
// hooks/useSkillRecommendations.ts

export function useSkillRecommendations(options?: {
  limit?: number;
  context?: string;
}) {
  const { user } = useAuth();

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['skill-recommendations', user?.id, options?.context],
    queryFn: () =>
      api
        .get('/skills/recommendations', {
          params: { limit: options?.limit, context: options?.context },
        })
        .then((r) => r.data.recommendations),
    enabled: !!user,
    staleTime: 5 * 60 * 1000, // 5 分钟缓存
  });

  return {
    recommendations: data,
    isLoading,
    refresh: refetch,
  };
}
```

---

## 8. 页面组件

### 8.1 Skill 市场页面

```tsx
// app/skills/page.tsx

export default function SkillMarketPage() {
  const { data: skills, isLoading } = useSkills();
  const { subscriptions } = useSkillSubscription();
  const router = useRouter();

  const userStatuses = useMemo(() => {
    return subscriptions.reduce((acc, sub) => {
      acc[sub.skill_id] = {
        subscribed: sub.status === 'subscribed',
        push_enabled: sub.push_enabled,
        trial_messages_used: sub.trial_messages_used,
        trial_messages_remaining:
          (skills?.find((s) => s.id === sub.skill_id)?.pricing.trial_messages ?? 0) -
          sub.trial_messages_used,
      };
      return acc;
    }, {} as Record<string, SkillUserStatus>);
  }, [subscriptions, skills]);

  return (
    <PageLayout
      title="探索 Skill"
      breadcrumb={[{ label: '首页', href: '/' }, { label: '探索 Skill' }]}
    >
      {/* Featured Section */}
      <section className="mb-8">
        <h2 className="text-lg font-semibold text-text-primary mb-4">精选推荐</h2>
        <FeaturedSkillCarousel skills={skills?.filter((s) => s.featured)} />
      </section>

      {/* All Skills */}
      <section>
        <SkillList
          skills={skills ?? []}
          userStatuses={userStatuses}
          layout="grid"
          groupBy="category"
          showFilters
          onSkillClick={(id) => router.push(`/skills/${id}`)}
          onSubscribe={handleSubscribe}
          onUnsubscribe={handleUnsubscribe}
          onTogglePush={handleTogglePush}
        />
      </section>
    </PageLayout>
  );
}
```

---

## 9. 动画与交互

### 9.1 CSS 动画

```css
/* globals.css */

/* 卡片出现动画 */
@keyframes slide-in-up {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-slide-in-up {
  animation: slide-in-up 0.3s ease-out;
}

/* 推荐卡片脉动效果 */
@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 0 0 var(--skill-color, #6366f1)20;
  }
  50% {
    box-shadow: 0 0 0 8px var(--skill-color, #6366f1)00;
  }
}

.animate-pulse-glow {
  animation: pulse-glow 2s ease-in-out infinite;
}

/* 开关切换 */
.toggle-switch {
  transition: background-color 0.2s ease;
}

.toggle-switch-thumb {
  transition: transform 0.2s ease;
}
```

### 9.2 交互反馈

```typescript
// 订阅成功 Toast
toast.success(`已订阅「${skill.name}」`, {
  description: '开始探索新能力吧！',
  action: {
    label: '立即体验',
    onClick: () => router.push('/chat'),
  },
});

// 取消订阅确认
const confirmed = await confirm({
  title: `确定取消订阅「${skill.name}」？`,
  description: '取消后将无法继续使用该 Skill 的功能和推送。',
  confirmText: '取消订阅',
  cancelText: '保留订阅',
  variant: 'warning',
});
```

---

## 10. 响应式设计

| 断点 | Skill 市场 | 卡片变体 | 列布局 |
|------|-----------|---------|--------|
| < 640px | 单列 | compact | 1 |
| 640-1024px | 双列 | card | 2 |
| > 1024px | 三列 | card | 3 |

```tsx
// 响应式网格
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  {skills.map((skill) => (
    <SkillCard key={skill.id} skill={skill} variant="card" />
  ))}
</div>

// 移动端使用 compact 变体
<div className="sm:hidden space-y-2">
  {skills.map((skill) => (
    <SkillCard key={skill.id} skill={skill} variant="compact" />
  ))}
</div>
```
