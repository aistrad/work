# Skill 卡片组件优化计划

## 一、当前架构分析

### 组件层级
```
DiscoverContent (探索页面)
├── FeaturedSkillBanner (精选横幅)
├── CategorySection (分类区块)
│   └── SkillShowcaseCard (展示卡片)
│       ├── onClick → router.push(`/skills/${skillId}`) → 详情页
│       └── onSubscribe → subscribe(skillId) → 订阅
└── SkillDetailPage (/skills/[skillId])
    └── handleTry → router.push('/chat?prompt=...')
```

### 当前用户流程问题
根据用户反馈：
- **"获取"按钮目的**：让用户获取使用 skill 的权限（订阅）
- **"点击图标"目的**：直接让用户开始体验（进入 chat，显示 intro card）

**当前问题**：
1. 点击卡片任意位置 → 跳转详情页（多了一步）
2. 点击图标 vs 点击卡片区分不明确
3. 用户无法直接从发现页开始体验

---

## 二、优化方案

### 方案 A：双区域交互（推荐）

**改动点**：`SkillShowcaseCard.tsx`

| 区域 | 点击行为 | 目标 |
|-----|---------|------|
| **图标区域** | 直接进入 chat，激活 intro card | 快速体验 |
| **卡片其他区域** | 跳转详情页 | 了解更多 |
| **"获取"按钮** | 订阅（保持不变） | 获取权限 |

```tsx
// 图标点击 - 直接体验
const handleIconClick = (e: React.MouseEvent) => {
  e.stopPropagation();
  router.push(`/chat?skill=${skill.id}&intro=true`);
};

// 卡片点击 - 详情页
const handleCardClick = () => {
  onClick(); // 保持原有行为
};
```

**优点**：
- 符合用户心智模型（图标=启动应用）
- 兼顾"快速体验"和"详细了解"两种需求
- 改动最小

**缺点**：
- 需要用户学习两种交互方式

### 方案 B：悬停显示快捷按钮

**改动点**：`SkillShowcaseCard.tsx`

卡片 hover 时显示两个按钮：
- 🚀 "开始体验" → 进入 chat
- ℹ️ "了解更多" → 详情页

**优点**：
- 交互意图明确
- 视觉层级清晰

**缺点**：
- 移动端无 hover 状态
- 改动较大

---

## 三、Chat 页面配合改动

### 需要修改的文件
1. `apps/web/src/app/chat/page.tsx`
2. `apps/web/src/components/chat/ChatContainer.tsx`

### 新增 URL 参数支持
```
/chat?skill=zodiac&intro=true
```

当 `intro=true` 时：
1. 自动在对话区显示 `SkillIntroCard`
2. 聚焦输入框等待用户输入
3. 首条消息自动关联该 skill

### ChatContainer 改动
```tsx
// 新增 props
interface ChatContainerProps {
  showIntroCard?: boolean; // 是否显示 intro card
}

// 在空状态时显示 intro card
{showIntroCard && skillId && (
  <SkillIntroCard
    skillId={skillId}
    variant="compact"
    onAction={handleIntroAction}
  />
)}
```

---

## 四、关键文件

| 文件 | 修改内容 |
|-----|---------|
| `apps/web/src/components/discover/SkillShowcaseCard.tsx` | 图标点击事件分离 |
| `apps/web/src/app/chat/page.tsx` | URL 参数解析 |
| `apps/web/src/components/chat/ChatContainer.tsx` | intro card 显示逻辑 |

---

## 五、验证方式

1. **功能验证**
   - 点击图标 → 跳转 `/chat?skill=xxx&intro=true`
   - 点击卡片其他区域 → 跳转 `/skills/xxx`
   - 点击"获取" → 订阅成功

2. **Playwright 测试**
   - 截图对比
   - 点击区域测试

3. **移动端测试**
   - 图标触摸区域 ≥ 44px
   - 长按不触发其他行为

---

## 六、待确认问题

1. **方案选择**：方案 A（双区域）vs 方案 B（悬停按钮）？
2. **未订阅用户**：点击图标是否也应该先提示订阅？
3. **已订阅用户**：是否跳过 intro card 直接进入对话？
