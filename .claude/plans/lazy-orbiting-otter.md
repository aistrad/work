# Chat 页面 UX 提升计划

## 目标
1. 独立头像系统 - 每个 Skill 有独特的专家形象
2. 专家介绍卡 - 首次进入展示专家自我介绍

---

## Phase 1: 类型定义与头像组件

### 1.1 扩展 SkillPlugin 类型
**文件**: `apps/web/src/skills/types.ts`

```typescript
export interface ExpertProfile {
  expertise: string[];    // 专长标签
  style: string;          // 风格描述
  greeting: string;       // 首次问候语
}

// SkillPlugin 新增字段
expert?: ExpertProfile;
// 专家名称直接复用 skill.name（八字命理、星座占星、人生教练）
// 头像直接复用 icon + theme，无需额外图片
```

### 1.2 创建 ExpertAvatar 组件
**新建**: `apps/web/src/components/core/ExpertAvatar.tsx`

复用现有 Lucide 图标，增强视觉效果：
- 圆形背景 + skill 主题色渐变
- 图标居中显示，白色
- 支持 sm(24px)/md(32px)/lg(40px) 尺寸
- 可选外发光效果

```tsx
// 设计效果示意
<div className="rounded-full bg-gradient-to-br from-primary to-secondary p-1.5 shadow-glow">
  <IconComponent className="text-white" size={iconSize} />
</div>
```

### 1.3 各 Skill 头像配置

| Skill | 图标 | 主色 | 显示名称（复用 skill.name） |
|-------|------|------|---------------------------|
| bazi | Compass | #B8860B | 八字命理 |
| zodiac | Star | #6366F1 | 星座占星 |
| lifecoach | Sparkles | #9B59B6 | 人生教练 |

**无需外部图片资源**，直接使用 Lucide 图标 + CSS 渐变背景

---

## Phase 2: 各 Skill 配置

**修改文件**:
- `apps/web/src/skills/bazi/config.ts`
- `apps/web/src/skills/zodiac/config.ts`
- `apps/web/src/skills/lifecoach/config.ts`

每个 config 添加 expert 配置：

**bazi**:
```typescript
expert: {
  expertise: ["运势分析", "事业规划", "婚姻匹配"],
  style: "深思熟虑，古典智慧",
  greeting: "千年智慧，为您解读生命密码。"
}
```

**zodiac**:
```typescript
expert: {
  expertise: ["星盘解读", "运势预测", "关系合盘"],
  style: "温和神秘，充满想象",
  greeting: "让星辰为您揭示命运的密码。"
}
```

**lifecoach**:
```typescript
expert: {
  expertise: ["目标管理", "习惯养成", "突破瓶颈"],
  style: "直接高效，激励人心",
  greeting: "陪你一起成长，找到前进的方向。"
}
```

---

## Phase 3: ChatMessage 集成

**文件**: `apps/web/src/components/chat/ChatMessage.tsx`

1. 导入 ExpertAvatar 替换 SimpleVibeGlyph
2. 根据 skill 从 registry 获取专家头像

```typescript
// 头像替换
<ExpertAvatar skill={skill} size="md" />
```

---

## Phase 4: 专家介绍卡（复用现有 SkillIntroCard）

**已有组件**: `apps/web/src/skills/shared/SkillIntroCard/`
- 支持 full/compact/mini 三种变体
- 已有 `is_first_use` 检测和 `doMarkFirstUse()` 方法
- 数据通过 `useSkillIntro(skillId)` hook 从 API 获取

### 4.1 在 ChatContainer 中集成
**文件**: `apps/web/src/components/chat/ChatContainer.tsx`

在空状态时，首次进入 skill 展示 SkillIntroCard (compact 变体)：

```typescript
import SkillIntroCard from '@/skills/shared/SkillIntroCard';

// 在 ChatEmptyState 或 ChatContainer 中
{isFirstUse && (
  <SkillIntroCard
    skillId={displaySkill}
    variant="compact"
    dismissible
    onAction={(action) => {
      if (action.type === 'dismiss') setShowIntro(false);
      if (action.type === 'send_prompt') handleQuickPrompt(action.prompt);
    }}
  />
)}
```

### 4.2 可选增强：Header 展示 greeting
如需在 Header 中显示 expert.greeting，可修改：
- `apps/web/src/skills/shared/SkillIntroCard/Header.tsx`
- 在 tagline 下方添加 greeting 显示

---

## 文件修改清单

| 文件 | 操作 |
|-----|-----|
| `skills/types.ts` | 新增 ExpertProfile 接口 |
| `components/core/ExpertAvatar.tsx` | 新建 |
| `components/core/index.ts` | 导出 ExpertAvatar |
| `skills/bazi/config.ts` | 添加 expert |
| `skills/zodiac/config.ts` | 添加 expert |
| `skills/lifecoach/config.ts` | 添加 expert |
| `components/chat/ChatMessage.tsx` | 使用 ExpertAvatar |
| `components/chat/ChatContainer.tsx` | 首次进入展示 SkillIntroCard |
| `skills/shared/SkillIntroCard/Header.tsx` | (可选) 显示 greeting |

---

## 验证方法

1. 启动测试环境: `pnpm dev`
2. 访问 `/chat` 页面
3. 验证点：
   - [ ] 首次进入显示专家介绍卡
   - [ ] 点击开始对话后介绍卡消失
   - [ ] 消息头像显示 skill 对应的图标+渐变背景
   - [ ] 不同 skill 头像颜色/图标不同
   - [ ] 切换 skill 时新 skill 也显示介绍卡

---

## 未解决问题

1. **后端配合** - 语气/称呼定制需要后端 prompt 调整（不在本次前端范围）
