# Onboarding 重构计划 - 增强混合方案

> **方案**: C. 增强混合方案 - 保留 90 秒 Onboarding，将 AhaStep 替换为嵌入式 Chat
> **付费时机**: 移到首次相遇对话结束时
> **设计文档**: `/home/aiscend/work/vibelife/docs/archive/v9/FIRST-MEETING-SKILL-DESIGN.md`
> **状态**: 待实施

---

## 一、架构概览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    重构后的 Onboarding 流程                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [保留] LandingStep (0-15s)     [保留] LoadingStep (15-45s)             │
│  ┌───────────────────────┐     ┌───────────────────────┐               │
│  │ 生日输入              │────▶│ 八字 + 星座计算        │               │
│  │ - 年月日时            │     │ - 并行 API 调用       │               │
│  └───────────────────────┘     └───────────────────────┘               │
│                                          │                              │
│                                          ▼                              │
│  [新增] EmbeddedChatStep (45-180s) ─────────────────────────────────┐   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────────┐│   │
│  │  │ InsightsCard (LLM 生成三个洞察)                             ││   │
│  │  │ • 内在矛盾: "追求自由 vs 渴望控制"                          ││   │
│  │  │ • 外在表现: "执行力强，但可能太直接"                        ││   │
│  │  │ • 当下状态: "想要改变但不知从哪开始"                        ││   │
│  │  │ [说得准 👍] [不太准 👎] [有话想说 💬]                       ││   │
│  │  └─────────────────────────────────────────────────────────────┘│   │
│  │                          ↓ 用户反馈                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐│   │
│  │  │ 自然对话区域 (ChatMessages)                                 ││   │
│  │  │ • Agent 响应反馈                                            ││   │
│  │  │ • 追问/共情对话                                             ││   │
│  │  └─────────────────────────────────────────────────────────────┘│   │
│  │                          ↓ 过渡到引导                           │   │
│  │  ┌─────────────────────────────────────────────────────────────┐│   │
│  │  │ GuidanceCard (三个引导选项)                                 ││   │
│  │  │ [想找到人生方向] [想改善职场/财务] [想改善感情/关系]        ││   │
│  │  └─────────────────────────────────────────────────────────────┘│   │
│  │                          ↓ 结束承诺                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐│   │
│  │  │ "今天的对话我记住了。明天早上8点，我会给你今日运势..."      ││   │
│  │  └─────────────────────────────────────────────────────────────┘│   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                          │                              │
│                                          ▼                              │
│  [移动] ConversionStep (对话结束后) ────────────────────────────────┐   │
│  │ • 付费选项 (月/季/年)                                           │   │
│  │ • "继续免费体验" → /chat                                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 二、步骤变更

| 步骤 | 变更 | 时长 | 说明 |
|------|------|------|------|
| `landing` | 保留 | 0-15s | 生日输入 |
| `loading` | 保留 | 15-45s | 八字+星座计算 |
| `aha` | **删除** | - | 被 embeddedChat 替代 |
| `embeddedChat` | **新增** | 45-180s+ | 嵌入式 Chat，展示 InsightsCard + GuidanceCard |
| `conversion` | 移动 | 结束时 | 付费引导，检测首次相遇完成后触发 |

---

## 三、文件变更清单

### 前端 (apps/web)

| 文件 | 操作 | 说明 |
|------|------|------|
| `src/app/onboarding/types.ts` | 修改 | 将 `'aha'` 改为 `'embeddedChat'` |
| `src/app/onboarding/context.tsx` | 修改 | 更新 STEP_ORDER，移除 aha 相关状态 |
| `src/app/onboarding/page.tsx` | 修改 | 替换 AhaStep 为 EmbeddedChatStep |
| `src/app/onboarding/steps/EmbeddedChatStep.tsx` | **新增** | 嵌入式 Chat（复用 ChatContainer） |
| `src/app/onboarding/steps/AhaStep.tsx` | **删除** | 被 EmbeddedChatStep 替代 |
| `src/app/onboarding/steps/ConversionStep.tsx` | 修改 | 添加首次相遇完成检测 |
| `src/hooks/useVibeChat.ts` | 修改 | SkillId 类型添加 `'onboarding'` |
| `src/types/skill.ts` | 修改 | SkillId 类型添加 `'onboarding'` |
| `src/components/chat/ChatContainer.tsx` | 修改 | 添加 onboarding 完成检测逻辑 |

### 后端 (apps/api) - 验证确认

| 文件 | 操作 | 说明 |
|------|------|------|
| `skills/onboarding/SKILL.md` | 验证 | 确认 4-phase 流程正确 |
| `skills/onboarding/tools/tools.yaml` | 验证 | 确认工具定义完整 |
| `skills/onboarding/rules/*.md` | 验证 | 确认规则文件正确 |

---

## 四、关键实现

### 4.1 EmbeddedChatStep.tsx (新增)

**设计原则**: 完全复用 ChatContainer 组件，与 /chat 页面风格 100% 一致

```tsx
'use client';

/**
 * EmbeddedChatStep - 首次相遇嵌入式对话
 *
 * 设计原则：
 * - 复用 ChatContainer，保持与 /chat 页面完全一致的 UI
 * - 使用 LuminousPaper + BreathAura 背景
 * - 自动触发 onboarding skill
 * - 检测首次相遇完成后跳转 ConversionStep
 */

import { useEffect, useMemo, useState, useRef } from 'react';
import dynamic from 'next/dynamic';
import { useOnboarding } from '../context';
import { LuminousPaper, BreathAura } from '@/components/core';

// 动态导入 ChatContainer，与 /chat 页面一致
const ChatContainer = dynamic(
  () => import('@/components/chat/ChatContainer').then(mod => ({ default: mod.ChatContainer })),
  { ssr: false, loading: () => <ChatLoadingFallback /> }
);

function ChatLoadingFallback() {
  return (
    <div className="flex-1 flex items-center justify-center">
      <div className="flex flex-col items-center gap-3">
        <div className="w-12 h-12 rounded-full bg-accent-primary/10 animate-pulse flex items-center justify-center">
          <span className="text-2xl">✨</span>
        </div>
        <p className="text-text-secondary text-sm">正在准备首次相遇...</p>
      </div>
    </div>
  );
}

export default function EmbeddedChatStep() {
  const { state, nextStep } = useOnboarding();
  const [conversationId, setConversationId] = useState<string | undefined>();
  const hasStartedRef = useRef(false);

  // 检测首次相遇完成的标志（通过 conversationId 变化或消息内容）
  // 后端会在完成时设置 profile.vibe.onboarding_completed = true
  // 这里通过检测后端返回的特定关键词来判断

  const handleConversationStart = (id: string) => {
    setConversationId(id);
  };

  // 初始消息 - 自动触发 onboarding skill
  const initialPrompt = hasStartedRef.current ? undefined : '开始';

  useEffect(() => {
    hasStartedRef.current = true;
  }, []);

  // 注意：首次相遇完成的检测逻辑在 ChatContainer 内部处理
  // 通过监听后端返回的承诺消息关键词，在 ChatMessage 渲染时检测
  // 这里我们通过 URL 变化或 localStorage 标记来检测完成

  useEffect(() => {
    // 监听 localStorage 中的 onboarding_completed 标记
    const checkComplete = () => {
      const completed = localStorage.getItem('vibelife_onboarding_chat_completed');
      if (completed === 'true') {
        localStorage.removeItem('vibelife_onboarding_chat_completed');
        setTimeout(() => nextStep(), 2000);
      }
    };

    // 每秒检查一次
    const interval = setInterval(checkComplete, 1000);
    return () => clearInterval(interval);
  }, [nextStep]);

  return (
    <LuminousPaper skill="bazi" variant="default" className="min-h-screen">
      {/* 呼吸光晕背景 - 与 /chat 页面一致 */}
      <BreathAura
        skill="bazi"
        intensity="low"
        className="fixed inset-0 pointer-events-none"
      />

      {/* 嵌入式 Chat - 完全复用 ChatContainer */}
      <div className="relative z-10 h-screen flex flex-col">
        <ChatContainer
          skillId="onboarding"
          skill="bazi"  // UI 主题
          initialPrompt={initialPrompt}
          onConversationStart={handleConversationStart}
          onInitialPromptSent={() => {
            // 初始消息已发送
          }}
        />
      </div>
    </LuminousPaper>
  );
}
```

**关键点**：
1. 完全复用 `ChatContainer` 组件，UI 与 /chat 页面 100% 一致
2. 使用 `LuminousPaper` + `BreathAura` 背景层
3. 通过 `skillId="onboarding"` 指定技能
4. 通过 `initialPrompt="开始"` 自动触发首次相遇
5. 首次相遇完成检测通过 localStorage 标记（后端在承诺消息后设置）

### 4.2 types.ts 修改

```typescript
// 删除 'aha'，添加 'embeddedChat'
export type OnboardingStep =
  | 'landing'
  | 'loading'
  | 'embeddedChat'  // 替代 aha
  | 'conversion';
```

### 4.3 context.tsx 修改

```typescript
const STEP_ORDER: OnboardingStep[] = [
  'landing',
  'loading',
  'embeddedChat',  // 替代 aha
  'conversion',
];
```

### 4.4 page.tsx 修改

```typescript
const EmbeddedChatStep = dynamic(() => import('./steps/EmbeddedChatStep'), {
  loading: () => <LoadingSkeleton />,
  ssr: false
});

// 在 renderStep 中
{state.step === 'embeddedChat' && <EmbeddedChatStep />}
```

### 4.5 useVibeChat.ts 修改

```typescript
export type SkillId =
  | 'bazi'
  | 'zodiac'
  | 'tarot'
  | 'career'
  | 'lifecoach'
  | 'jungastro'
  | 'synastry'
  | 'psych'
  | 'vibe_id'
  | 'mindfulness'
  | 'onboarding';  // 新增
```

---

## 五、数据流

```
LandingStep
    │ setBirthInfo({ year, month, day, hour })
    ▼
LoadingStep
    │ 1. POST /api/v1/bazi/chart
    │ 2. POST /api/v1/zodiac/chart
    │ setBaziData({ ... })
    ▼
EmbeddedChatStep
    │ 1. useVibeChat({ skillId: 'onboarding' })
    │ 2. sendMessage('开始') 触发 onboarding skill
    │ 3. 后端返回 InsightsCard (show tool)
    │ 4. 用户反馈 → 后端处理 → GuidanceCard
    │ 5. 用户选择 → 后端发送承诺消息
    │ 6. 检测到承诺关键词 → nextStep()
    ▼
ConversionStep
    │ 展示付费选项
    │ "继续免费体验" → router.push('/chat')
    ▼
/chat (正常对话)
```

---

## 六、后端交互

### 6.1 首次相遇触发

前端发送 `开始` 消息，后端 onboarding skill 自动接管：

1. **Phase 1**: 调用 `generate_insights` 工具，基于 bazi+zodiac 生成三个洞察
2. **Phase 1**: 调用 `show` 工具返回 InsightsCard
3. **Phase 2**: 收集用户反馈，调用 `save` 存储
4. **Phase 3**: 调用 `show` 返回 GuidanceCard
5. **Phase 4**: 用户选择后，发送承诺消息，调用 `remind` 设置推送

### 6.2 Profile 更新

首次相遇完成后，后端更新：
```json
{
  "vibe": {
    "onboarding_completed": true,
    "onboarding": {
      "feedback": "accurate",
      "guidance": "life_direction",
      "completed_at": "2026-01-26T12:00:00Z"
    }
  }
}
```

---

## 七、验证步骤

### 7.1 手动测试清单

- [ ] LandingStep 正常收集生日信息
- [ ] LoadingStep 正常计算八字/星座
- [ ] EmbeddedChatStep 自动触发 onboarding skill
- [ ] InsightsCard 显示三个个性化洞察
- [ ] 反馈按钮（准/不准/想说）正常工作
- [ ] GuidanceCard 显示三个引导选项
- [ ] 选择后 Agent 发送承诺消息
- [ ] 检测到承诺后自动跳转 ConversionStep
- [ ] 付费选项正常显示
- [ ] "继续免费体验" 跳转到 /chat
- [ ] Profile 标记 onboarding_completed

### 7.2 测试命令

```bash
# 1. 启动测试环境
bash /home/aiscend/work/vibelife/scripts/start-test.sh

# 2. 访问 onboarding 页面
# http://106.37.170.238:8232/onboarding

# 3. 检查后端日志
tail -f /data/vibelife/logs/test/api.log | grep onboarding
```

---

## 八、风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| 嵌入式 Chat 滚动问题 | 使用 `flex flex-col` + `overflow-y-auto` |
| 移动端键盘遮挡 | 固定输入框在底部，消息区域滚动 |
| 网络错误导致卡住 | 添加重试按钮和错误提示 |
| 首次相遇检测误判 | 使用多个关键词 + 后端显式信号 |

---

## 九、实施顺序

1. **修改类型定义** - types.ts, useVibeChat.ts
2. **修改 context** - 更新 STEP_ORDER
3. **创建 EmbeddedChatStep** - 新组件
4. **修改 page.tsx** - 替换渲染逻辑
5. **删除 AhaStep** - 清理旧代码
6. **修改 ConversionStep** - 调整跳转逻辑
7. **E2E 测试** - 完整流程验证
