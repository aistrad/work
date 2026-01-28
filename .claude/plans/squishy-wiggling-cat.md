# Discover 页面 Skill 交互优化计划

## 目标
1. **点击卡片** → 进入 Chat，统一展示 Intro Card，开始体验
2. **「获取」按钮** → 订阅流程（考虑付费计费）

---

## 一、点击卡片流程优化

### 当前问题
- 点击卡片跳转到 `/skills/[skillId]` 详情页
- 用户需要多一步才能开始体验

### 优化方案

#### 1.1 修改点击行为
**文件**: `apps/web/src/components/discover/DiscoverContent.tsx:112-114`

```typescript
// 当前
const handleSkillClick = (skillId: string) => {
  router.push(`/skills/${skillId}`);
};

// 优化后：跳转 Chat 并强制显示 Intro Card
const handleSkillClick = (skillId: string) => {
  router.push(`/chat?skill=${skillId}&intro=1`);
};
```

#### 1.2 Chat 页面支持强制显示 Intro Card
**文件**: `apps/web/src/components/chat/ChatContainer.tsx`

当前逻辑只在 `is_first_use=true` 时显示，需要增加 URL 参数支持：

```typescript
// 读取 URL 参数
const searchParams = useSearchParams();
const forceIntro = searchParams.get('intro') === '1';

// 修改显示逻辑
useEffect(() => {
  if (introData?.is_first_use || forceIntro) {
    setShowIntroCard(true);
  }
}, [introData?.is_first_use, forceIntro]);

// 修改关闭逻辑：从 Discover 进入时不标记 first_use
const handleIntroAction = useCallback((action: IntroCardAction) => {
  if (action.type === 'dismiss') {
    setShowIntroCard(false);
    if (!forceIntro) {
      doMarkFirstUse();  // 仅在非强制模式下标记
    }
  } else if (action.type === 'send_prompt') {
    setShowIntroCard(false);
    if (!forceIntro) {
      doMarkFirstUse();
    }
    sendQuickPrompt(action.prompt);
  }
}, [forceIntro, doMarkFirstUse, sendQuickPrompt]);
```

### 用户体验流程

```
Discover 点击卡片
    ↓
跳转 /chat?skill=xxx&intro=1
    ↓
展示 Intro Card (compact 版本)
    ├─ 点击「开始对话」→ 发送示例 prompt
    ├─ 点击关闭 → 显示空聊天界面
    └─ 点击「获取/订阅」→ 触发订阅流程
```

---

## 二、「获取」按钮订阅流程

### 当前实现（已完善，无需大改）
- `SkillShowcaseCard.tsx` 已有「获取」按钮
- `DiscoverContent.tsx` 已实现 `handleSubscribe` 方法
- 后端已实现 Premium 检查和 402 错误

### 需要确认的处理逻辑

#### 2.1 订阅流程图

```
点击「获取」按钮
    ↓
调用 subscribe(skillId)
    ↓
后端检查 Skill 类型
    ├─ FREE Skill → 直接订阅成功
    │
    └─ PREMIUM Skill
        ↓
        检查试用次数
        ├─ 试用未用完 → 允许订阅（试用模式）
        │
        └─ 试用已用完
            ↓
            检查 Premium 会员状态
            ├─ 已是 Premium → 允许订阅
            └─ 不是 Premium → 返回 402 错误
                                ↓
                            前端捕获 402
                                ↓
                            跳转 /membership?reason=skill_subscribe&skill=xxx
```

#### 2.2 现有 402 错误处理
**文件**: `apps/web/src/components/discover/DiscoverContent.tsx:81-99`

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
      const detail = error.response.data?.detail;
      if (detail?.code === 'PREMIUM_REQUIRED') {
        router.push(`/membership?reason=skill_subscribe&skill=${skillId}`);
        return;
      }
    }
    console.error('Subscribe failed:', error);
  }
};
```

---

## 三、关键文件修改清单

| 文件 | 修改内容 |
|------|----------|
| `apps/web/src/components/discover/DiscoverContent.tsx:112-114` | 修改 `handleSkillClick` 跳转到 Chat |
| `apps/web/src/components/chat/ChatContainer.tsx` | 支持 `?intro=1` 参数强制显示 Intro Card |
| `apps/web/src/app/chat/page.tsx` | 传递 `intro` 参数到 ChatContainer |

---

## 四、验证方式

1. **点击卡片测试**
   - 访问 http://106.37.170.238:8232/chat?tab=discover
   - 点击任意 Skill 卡片
   - 应跳转到 `/chat?skill=xxx&intro=1`
   - 应展示 Intro Card

2. **订阅测试（FREE Skill）**
   - 点击 FREE Skill 的「获取」按钮
   - 应订阅成功，留在当前页面
   - 卡片状态应更新为「已订阅」

3. **订阅测试（PREMIUM Skill，试用未用完）**
   - 点击 PREMIUM Skill 的「获取」按钮
   - 应订阅成功（试用模式）

4. **订阅测试（PREMIUM Skill，试用已用完）**
   - 点击试用已用完的 PREMIUM Skill「获取」按钮
   - 应跳转到 `/membership` 页面

---

## 五、已确认决定

1. 点击「获取」后 → 留在当前页面
2. Intro Card 展示策略 → **每次从 Discover 进入都展示**
   - 使用 URL 参数 `?intro=1` 强制显示
   - 关闭 Intro Card 时**不标记** `first_use`（从 Discover 进入时跳过标记）
