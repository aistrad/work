# VibeLife 聊天页面 LUMINOUS PAPER 优化方案

## 用户需求
- 全部实现（ChatLayout + 空状态优化 + 右侧功能按钮）
- 右侧功能按钮：命盘/档案查看

---

## 修改文件清单

| 文件 | 操作 |
|------|------|
| `apps/web/src/components/chat/ChatLayout.tsx` | **新建** |
| `apps/web/src/components/chat/ChatContainer.tsx` | 修改 |
| `apps/web/src/app/bazi/chat/page.tsx` | 修改 |
| `apps/web/src/app/zodiac/chat/page.tsx` | 修改 |
| `apps/web/src/app/mbti/chat/page.tsx` | 修改 |
| `apps/web/src/app/chat/[skillId]/page.tsx` | 修改 |

---

## 实现步骤

### Step 1: 新建 ChatLayout.tsx

**路径**: `apps/web/src/components/chat/ChatLayout.tsx`

```tsx
"use client";

import Link from "next/link";
import { ArrowLeft, FileText } from "lucide-react";
import { LuminousPaper, VibeGlyph, BreathAura, type SkillType } from "@/components/core";
import { IconButton } from "@/components/ui/Button";

interface ChatLayoutProps {
  skill: SkillType;
  title: string;
  backHref: string;
  onViewProfile?: () => void;
  children: React.ReactNode;
}

const SKILL_CONFIG: Record<SkillType, { profileLabel: string }> = {
  bazi: { profileLabel: "查看命盘" },
  zodiac: { profileLabel: "查看星盘" },
  mbti: { profileLabel: "查看档案" },
  attach: { profileLabel: "查看档案" },
  career: { profileLabel: "查看档案" },
};

export function ChatLayout({
  skill,
  title,
  backHref,
  onViewProfile,
  children,
}: ChatLayoutProps) {
  const config = SKILL_CONFIG[skill];

  return (
    <LuminousPaper skill={skill} variant="default" className="h-screen flex flex-col">
      {/* Background aura */}
      <BreathAura skill={skill} size="xl" position="top" intensity="low" className="opacity-40" />

      {/* Glass Header */}
      <header className="nav">
        <div className="nav-container">
          {/* Left: Back + Logo + Title */}
          <div className="flex items-center gap-3">
            <Link href={backHref} className="nav-link flex items-center gap-1">
              <ArrowLeft className="w-4 h-4" />
              <span>返回</span>
            </Link>
            <div className="flex items-center gap-2">
              <VibeGlyph size="sm" skill={skill} showAura={false} animate={false} />
              <span className="font-serif font-semibold text-foreground">{title}</span>
            </div>
          </div>

          {/* Right: Profile Button */}
          <div className="flex items-center gap-2">
            {onViewProfile && (
              <IconButton
                variant="ghost"
                size="sm"
                onClick={onViewProfile}
                aria-label={config.profileLabel}
              >
                <FileText className="w-5 h-5" />
              </IconButton>
            )}
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex-1 overflow-hidden relative">
        {children}
      </div>
    </LuminousPaper>
  );
}
```

### Step 2: 更新 ChatContainer.tsx

**路径**: `apps/web/src/components/chat/ChatContainer.tsx`

修改空状态部分：

```tsx
// 替换原来的空状态
{messages.length === 0 && (
  <div className="flex flex-col items-center justify-center h-full py-20">
    <VibeGlyph size="lg" skill={skillId as SkillType} showAura animate />
    <h2 className="font-serif text-xl text-foreground mt-8 mb-2">开始对话吧</h2>
    <p className="text-muted-foreground text-center max-w-xs">
      有什么我可以帮到你的？
    </p>
  </div>
)}
```

添加导入：
```tsx
import { VibeGlyph, type SkillType } from "@/components/core";
```

### Step 3: 更新聊天页面

#### bazi/chat/page.tsx
```tsx
import { ChatLayout } from "@/components/chat/ChatLayout";
import { ChatContainer } from "@/components/chat/ChatContainer";

export default function BaziChatPage() {
  return (
    <ChatLayout
      skill="bazi"
      title="八字命理"
      backHref="/bazi"
      onViewProfile={() => console.log("View bazi profile")}
    >
      <ChatContainer skillId="bazi" />
    </ChatLayout>
  );
}
```

#### zodiac/chat/page.tsx
```tsx
import { ChatLayout } from "@/components/chat/ChatLayout";
import { ChatContainer } from "@/components/chat/ChatContainer";

export default function ZodiacChatPage() {
  return (
    <ChatLayout
      skill="zodiac"
      title="星座占星"
      backHref="/zodiac"
      onViewProfile={() => console.log("View zodiac profile")}
    >
      <ChatContainer skillId="zodiac" />
    </ChatLayout>
  );
}
```

#### mbti/chat/page.tsx
```tsx
import { ChatLayout } from "@/components/chat/ChatLayout";
import { ChatContainer } from "@/components/chat/ChatContainer";

export default function MbtiChatPage() {
  return (
    <ChatLayout
      skill="mbti"
      title="MBTI 性格"
      backHref="/mbti"
      onViewProfile={() => console.log("View mbti profile")}
    >
      <ChatContainer skillId="mbti" />
    </ChatLayout>
  );
}
```

#### chat/[skillId]/page.tsx
```tsx
"use client";

import { useParams } from "next/navigation";
import { ChatLayout } from "@/components/chat/ChatLayout";
import { ChatContainer } from "@/components/chat/ChatContainer";
import { type SkillType } from "@/components/core";

const SKILL_CONFIG: Record<string, { name: string; backHref: string }> = {
  bazi: { name: "八字命理", backHref: "/bazi" },
  zodiac: { name: "星座占星", backHref: "/zodiac" },
  mbti: { name: "MBTI 性格", backHref: "/mbti" },
};

export default function ChatPage() {
  const params = useParams();
  const skillId = params.skillId as string;
  const config = SKILL_CONFIG[skillId] || { name: skillId, backHref: "/" };

  return (
    <ChatLayout
      skill={skillId as SkillType}
      title={config.name}
      backHref={config.backHref}
      onViewProfile={() => console.log(`View ${skillId} profile`)}
    >
      <ChatContainer skillId={skillId} />
    </ChatLayout>
  );
}
```

---

## 视觉效果预期

### Before (当前)
- 纯色 Header (amber-600/indigo-600/emerald-600)
- 简单背景色 (amber-50/indigo-50/emerald-50)
- 无品牌元素

### After (优化后)
- **Header**: 玻璃态背景 + VibeGlyph logo + 档案按钮
- **背景**: LUMINOUS PAPER 光纸 + 呼吸光晕
- **空状态**: 居中 VibeGlyph 动画 + 优雅文字
- **整体**: 技能感知的颜色主题 (data-skill 属性)

---

## 执行顺序

1. 新建 `ChatLayout.tsx`
2. 更新 `ChatContainer.tsx` 空状态
3. 更新 `bazi/chat/page.tsx`
4. 更新 `zodiac/chat/page.tsx`
5. 更新 `mbti/chat/page.tsx`
6. 更新 `chat/[skillId]/page.tsx`
7. 测试验证
