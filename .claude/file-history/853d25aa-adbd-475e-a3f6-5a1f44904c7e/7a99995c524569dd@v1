# Discover API 文档

## 概述

Discover 功能使用 3 个主要 API 端点获取 Skills 数据。

## 架构

```
Frontend (Next.js)
    ↓
API Routes (/api/v1/skills/*)
    ↓
Backend API (FastAPI, port 8100)
    ↓
Database (PostgreSQL)
```

---

## API Endpoints

### 1. GET /api/v1/skills

获取所有 Skills 列表（带用户订阅状态）

#### 请求

**URL**: `GET /api/v1/skills`

**Query Parameters**:
| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `category` | `string` | ❌ | 按分类筛选: `core`, `default`, `professional` |
| `subscribed` | `boolean` | ❌ | 只返回已订阅的 Skills |

**Headers**:
```
Authorization: Bearer <access_token>  (可选)
Content-Type: application/json
```

#### 响应

**成功响应** (200 OK):
```json
{
  "skills": [
    {
      "id": "bazi",
      "name": "八字命理",
      "description": "融汇《滴天髓》《穷通宝鉴》《子平真诠》《东方代码启示录》四大经典的八字命理大师。",
      "version": "1.0.0",
      "category": "professional",
      "icon": "🔮",
      "color": "#D4A574",
      "triggers": ["八字", "命理", "生辰"],
      "pricing": {
        "type": "premium",
        "trial_messages": 3
      },
      "features": [],
      "showcase": {
        "tagline": "",
        "highlights": [],
        "preview_image": null,
        "demo_prompts": []
      },
      "subscription": {
        "auto_subscribe": false,
        "can_unsubscribe": true,
        "push_default": true
      },
      "user_status": {
        "subscribed": false,
        "push_enabled": false,
        "trial_messages_used": 0,
        "trial_messages_remaining": 3
      }
    }
    // ... 更多 Skills
  ],
  "categories": {
    "core": {
      "name": "核心能力",
      "description": "始终激活的基础能力",
      "count": 1
    },
    "default": {
      "name": "基础功能",
      "description": "默认激活，免费使用",
      "count": 1
    },
    "professional": {
      "name": "专业技能",
      "description": "需要订阅的高级功能",
      "count": 6
    }
  },
  "total": 8
}
```

**错误响应**:
- `401 Unauthorized` - 未登录（user_status 将为 null）
- `500 Internal Server Error` - 服务器错误

#### 示例

```bash
# 获取所有 Skills
curl http://localhost:8232/api/v1/skills

# 获取专业技能
curl http://localhost:8232/api/v1/skills?category=professional

# 获取已订阅的 Skills
curl -H "Authorization: Bearer <token>" \
  http://localhost:8232/api/v1/skills?subscribed=true
```

#### 前端使用

```typescript
import { useSkills } from '@/hooks/useSkillSubscription';

function MyComponent() {
  const { skills, categories, total, isLoading, error } = useSkills();

  if (isLoading) return <Loading />;
  if (error) return <Error />;

  return (
    <div>
      <p>总共 {total} 个 Skills</p>
      {skills.map(skill => (
        <SkillCard key={skill.id} skill={skill} />
      ))}
    </div>
  );
}
```

---

### 2. GET /api/v1/skills/subscriptions

获取用户的 Skill 订阅列表

#### 请求

**URL**: `GET /api/v1/skills/subscriptions`

**Headers**:
```
Authorization: Bearer <access_token>  (必需)
Content-Type: application/json
```

#### 响应

**成功响应** (200 OK):
```json
{
  "subscriptions": [
    {
      "skill_id": "bazi",
      "skill_name": "八字命理",
      "status": "subscribed",
      "push_enabled": true,
      "subscribed_at": "2026-01-20T10:30:00Z",
      "can_unsubscribe": true,
      "trial_messages_used": 1
    },
    {
      "skill_id": "core",
      "skill_name": "生命对话者",
      "status": "subscribed",
      "push_enabled": true,
      "subscribed_at": "2026-01-15T08:00:00Z",
      "can_unsubscribe": false,
      "trial_messages_used": 0
    }
  ],
  "summary": {
    "total_subscribed": 2,
    "total_available": 8,
    "push_enabled_count": 2
  }
}
```

**错误响应**:
- `401 Unauthorized` - 未登录或 token 失效
- `500 Internal Server Error` - 服务器错误

#### 示例

```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:8232/api/v1/skills/subscriptions
```

#### 前端使用

```typescript
import { useSkillSubscription } from '@/hooks/useSkillSubscription';

function MySubscriptions() {
  const { subscriptions, summary, isLoading } = useSkillSubscription();

  return (
    <div>
      <h2>我的订阅 ({summary?.total_subscribed})</h2>
      {subscriptions.map(sub => (
        <div key={sub.skill_id}>
          <h3>{sub.skill_name}</h3>
          <p>状态: {sub.status}</p>
          <p>推送: {sub.push_enabled ? '开启' : '关闭'}</p>
        </div>
      ))}
    </div>
  );
}
```

---

### 3. GET /api/v1/skills/recommendations

获取智能推荐的 Skills

#### 请求

**URL**: `GET /api/v1/skills/recommendations`

**Query Parameters**:
| 参数 | 类型 | 必需 | 默认值 | 描述 |
|------|------|------|--------|------|
| `limit` | `number` | ❌ | `3` | 返回数量，最大 10 |
| `context` | `string` | ❌ | - | 上下文关键词 |

**Headers**:
```
Authorization: Bearer <access_token>  (必需)
Content-Type: application/json
```

#### 响应

**成功响应** (200 OK):
```json
{
  "recommendations": [
    {
      "skill_id": "bazi",
      "skill": {
        "id": "bazi",
        "name": "八字命理",
        "icon": "🔮",
        "color": "#D4A574",
        "tagline": ""
      },
      "reason": "based_on_conversation",
      "context": "你提到了「命理」，八字命理可以帮助你。",
      "score": 0.8,
      "trial_messages_remaining": 3
    },
    {
      "skill_id": "zodiac",
      "skill": {
        "id": "zodiac",
        "name": "西方占星",
        "icon": "⭐",
        "color": "#8B5CF6",
        "tagline": ""
      },
      "reason": "featured",
      "context": "试试「西方占星」，",
      "score": 0.8,
      "trial_messages_remaining": 3
    }
  ],
  "generated_at": "2026-01-21T10:30:00Z"
}
```

**推荐原因** (`reason`):
- `featured` - 精选推荐
- `based_on_conversation` - 基于对话上下文
- `popular` - 热门推荐
- `similar` - 相似 Skills

**错误响应**:
- `401 Unauthorized` - 未登录或 token 失效
- `400 Bad Request` - 参数错误
- `500 Internal Server Error` - 服务器错误

#### 示例

```bash
# 获取 3 个推荐
curl -H "Authorization: Bearer <token>" \
  http://localhost:8232/api/v1/skills/recommendations?limit=3

# 基于上下文推荐
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8232/api/v1/skills/recommendations?limit=5&context=命理"
```

#### 前端使用

```typescript
import { useSkillRecommendations } from '@/hooks/useSkillSubscription';

function RecommendedSkills() {
  const { user } = useAuth();
  const { recommendations, isLoading } = useSkillRecommendations({
    limit: 3,
    enabled: !!user,
  });

  if (!user) return <LoginPrompt />;
  if (isLoading) return <Loading />;

  return (
    <div>
      <h2>为你推荐</h2>
      {recommendations.map(rec => (
        <SkillCard
          key={rec.skill_id}
          skill={rec.skill}
          reason={rec.context}
        />
      ))}
    </div>
  );
}
```

---

## 其他 Skill API

### POST /api/v1/skills/{skill_id}/subscribe

订阅 Skill

**请求体**:
```json
{
  "push_enabled": true
}
```

**响应**:
```json
{
  "success": true,
  "subscription": { /* 订阅详情 */ },
  "message": "已成功订阅「八字命理」"
}
```

**错误**:
- `400 Bad Request` - 已订阅
- `402 Payment Required` - 需要 Premium 会员
- `404 Not Found` - Skill 不存在

---

### POST /api/v1/skills/{skill_id}/unsubscribe

取消订阅 Skill

**响应**:
```json
{
  "success": true,
  "subscription": { /* 订阅详情 */ },
  "message": "已取消订阅「八字命理」"
}
```

**错误**:
- `400 Bad Request` - 未订阅或不可取消订阅（核心 Skill）
- `404 Not Found` - Skill 不存在

---

### POST /api/v1/skills/{skill_id}/push

切换推送开关

**请求体**:
```json
{
  "enabled": true
}
```

**响应**:
```json
{
  "success": true,
  "subscription": { /* 订阅详情 */ },
  "message": "已开启「八字命理」的推送通知"
}
```

---

## 数据类型

### SkillMetadata

```typescript
interface SkillMetadata {
  id: string;
  name: string;
  description: string;
  version?: string;
  icon: string;
  color: string;
  category: 'core' | 'default' | 'professional';
  triggers: string[];
  pricing: {
    type: 'free' | 'premium' | 'credits';
    trial_messages?: number;
    credits_per_use?: number;
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
  subscription: {
    auto_subscribe: boolean;
    can_unsubscribe: boolean;
    push_default: boolean;
  };
}
```

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

### SkillSubscription

```typescript
interface SkillSubscription {
  skill_id: string;
  skill_name?: string;
  status: 'subscribed' | 'unsubscribed' | 'not_subscribed';
  push_enabled: boolean;
  subscribed_at: string | null;
  can_unsubscribe: boolean;
  trial_messages_used: number;
}
```

---

## 错误处理

### 错误码

| 状态码 | 说明 | 处理方式 |
|--------|------|----------|
| `400` | 请求参数错误 | 检查请求参数 |
| `401` | 未登录或 token 失效 | 跳转登录页 |
| `402` | 需要 Premium 会员 | 跳转会员页 |
| `404` | 资源不存在 | 显示错误提示 |
| `500` | 服务器错误 | 显示错误提示，提供重试 |

### 前端错误处理

```typescript
try {
  await subscribe(skillId);
} catch (error: any) {
  if (error?.response?.status === 401) {
    router.push('/auth/login');
  } else if (error?.response?.status === 402) {
    const detail = error.response.data?.detail;
    if (detail?.code === 'PREMIUM_REQUIRED') {
      router.push(`/membership?skill=${skillId}`);
    }
  } else {
    toast.error('订阅失败，请稍后重试');
  }
}
```

---

## 缓存策略

### SWR 配置

```typescript
useSWR(key, fetcher, {
  revalidateOnFocus: false,        // 焦点时不重新验证
  revalidateOnReconnect: true,     // 重连时重新验证
  dedupingInterval: 5 * 60 * 1000, // 5 分钟去重
  shouldRetryOnError: false,       // 错误时不重试
});
```

### 缓存失效

```typescript
import { mutate } from 'swr';

// 订阅后刷新缓存
await subscribe(skillId);
mutate('skill-list');
mutate('skill-subscriptions');

// 手动刷新
const { refresh } = useSkills();
refresh();
```

---

## 性能优化

### 1. 预加载

```typescript
// 预加载 Skills 数据
useEffect(() => {
  const prefetch = async () => {
    await fetch('/api/v1/skills');
  };
  prefetch();
}, []);
```

### 2. 分页加载

```typescript
// 未来支持分页
const { skills, hasMore, loadMore } = useSkills({
  page: 1,
  pageSize: 20,
});
```

### 3. 增量更新

```typescript
// 只更新变化的 Skills
mutate('skill-list', (currentData) => {
  return {
    ...currentData,
    skills: currentData.skills.map(skill =>
      skill.id === updatedSkill.id ? updatedSkill : skill
    ),
  };
}, false);
```

---

## 测试

### API 测试

```bash
# 测试 Skills 列表
npm run test:api -- skills.test.ts

# 测试订阅功能
npm run test:api -- subscription.test.ts
```

### Mock 数据

```typescript
const mockSkills = [
  {
    id: 'bazi',
    name: '八字命理',
    category: 'professional',
    // ...
  },
];

jest.mock('@/hooks/useSkillSubscription', () => ({
  useSkills: () => ({
    skills: mockSkills,
    isLoading: false,
    error: null,
  }),
}));
```

---

## 相关文档

- [README](./README.md)
- [集成指南](./INTEGRATION.md)
- [组件文档](./COMPONENTS.md)
- [问题排查](./TROUBLESHOOTING.md)
