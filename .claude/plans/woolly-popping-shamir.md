# VibeLife 前端全面优化计划

> **范围**: 聊天页布局优化 + 架构重构 + AI SDK升级 + 冗余清理 + UX增强 + 支付完善 + 认证迁移 + 主动推送
> **基于文档**: matrix-strategy-architecture.md, architecture-decisions.md, user-case-analysis-report.md
> **用户确认日期**: 2026-01-08

---

## 执行摘要

本计划分为8个阶段，目标是：
1. **子域名路由组重构** (bazi/zodiac) - ✅ 优先
2. **聊天页布局优化** (PC端左对齐、边栏可调、输入框) - ✅ 优先
3. **Vercel AI SDK 6 升级** (useChat + Generative UI) - ✅ 优先
4. **认证系统迁移** (Clerk) - ✅ 优先
5. **支付系统完善** (Stripe + Airwallex 双轨) - ✅ 优先
6. **主动推送系统完善** - ✅ 优先
7. **可视化组件增强** (充分利用 AI SDK 6) - ✅ 优先
8. **冗余代码清理** (布局修复时顺带)

**不在本次范围**：
- 统一顶栏 GlobalNav (暂时不需要)
- 行动追踪系统 (不需要)
- MBTI/Attach/Career 路由组 (Phase 2 产品)

---

## Phase 1: 前端架构重构

### 1.1 创建子域名路由组

**目标**: 按 matrix-strategy-architecture.md 要求，建立 `(bazi)/` 和 `(zodiac)/` 路由组

**修改文件**:
```
apps/web/src/app/
├── (www)/                    # 新建 - 品牌索引页
│   ├── layout.tsx
│   └── page.tsx              # 从当前 page.tsx 迁移
│
├── (bazi)/                   # 新建 - Bazi 路由组
│   ├── layout.tsx            # Bazi 专属布局
│   ├── page.tsx              # Bazi 首页
│   ├── chat/page.tsx         # 从 /chat/page.tsx 迁移
│   ├── report/page.tsx
│   ├── report/[id]/page.tsx
│   └── relationship/page.tsx
│
├── (zodiac)/                 # 新建 - Zodiac 路由组
│   ├── layout.tsx            # Zodiac 专属布局
│   ├── page.tsx
│   ├── chat/page.tsx
│   ├── report/page.tsx
│   ├── report/[id]/page.tsx
│   └── relationship/page.tsx
│
├── (shared)/                 # 新建 - 共享路由
│   ├── auth/
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   └── sso-callback/page.tsx
│   ├── interview/page.tsx
│   ├── payment/
│   │   ├── success/page.tsx
│   │   └── cancel/page.tsx
│   └── checkout/[sessionId]/page.tsx
│
└── middleware.ts             # 完善子域名路由
```

### 1.2 实现统一顶栏 GlobalNav

**新建文件**: `apps/web/src/components/core/GlobalNav.tsx`

**功能**:
- VibeLife Logo（链接到 www.vibelife.app）
- Skill 导航（bazi/zodiac，当前 skill 高亮）
- 用户菜单（登录状态/头像/下拉）

### 1.3 完善 middleware.ts

**修改文件**: `apps/web/src/middleware.ts`

**功能**:
- 根据子域名设置 `vibelife_skill` Cookie
- 设置 `x-vibelife-skill` Header
- 支持 bazi/zodiac/www 三个子域名

---

## Phase 2: 聊天页布局优化

### 2.1 PC端聊天内容左对齐

**修改文件**: `apps/web/src/components/chat/ChatContainer.tsx`

```tsx
// Line 132 - ChatEmptyState
// 修改前
<div className="flex flex-col items-center justify-center max-w-xl mx-auto px-4 py-6 w-full">

// 修改后
<div className="flex flex-col max-w-3xl pl-6 pr-4 py-6 w-full">
```

**修改文件**: `apps/web/src/app/globals.css`

```css
/* 消息气泡自适应宽度 */
.chat-bubble {
  @apply rounded-2xl px-4 py-3 animate-fade-in-up;
  max-width: min(80%, 600px);  /* 短消息窄，最大600px */
  width: fit-content;          /* 内容自适应 */
}
```

### 2.2 右侧边栏可调节 + 可折叠

**新建文件**: `apps/web/src/components/layout/ResizablePanel.tsx`

**功能**:
- 默认宽度 450px（从 360px 增加）
- 拖拽调节范围 320-600px
- 折叠成 56px 图标条
- 折叠状态显示 Tab 图标

**修改文件**: `apps/web/src/components/layout/AppShell.tsx`

```tsx
// 替换固定宽度 aside
// 修改前
<aside className="hidden lg:block w-[360px] ...">

// 修改后
<ResizablePanel defaultWidth={450} minWidth={320} maxWidth={600}>
  {panelContent}
</ResizablePanel>
```

### 2.3 输入框位置调整

**修改文件**: `apps/web/src/components/chat/ChatInput.tsx`

```tsx
// Line 92 - 与消息区域对齐
// 修改前
<div className="max-w-3xl mx-auto">

// 修改后
<div className="max-w-3xl pl-6 pr-4">  // 左对齐
```

### 2.4 移动端评估

**评估内容**:
- 底部 Tab 切换保持不变
- 聊天页滑动体验
- 输入框键盘弹起时的行为

---

## Phase 3: AI SDK 6 升级

### 3.1 后端 SSE 格式适配

**修改文件**: `apps/api/routes/chat.py`

```python
# 当前格式
data: {"type": "chunk", "content": "你好"}
data: {"type": "done", "conversation_id": "..."}

# AI SDK 要求格式
data: {"type": "text-delta", "textDelta": "你好"}
data: {"type": "finish", "finishReason": "stop", "metadata": {...}}
```

### 3.2 前端改用 useChat

**新建文件**: `apps/web/src/hooks/useVibeChat.ts`

```tsx
import { useChat } from '@ai-sdk/react';

export function useVibeChat(skillId: string, voiceMode: string) {
  return useChat({
    api: '/api/chat',
    body: { skill: skillId, voice_mode: voiceMode },
    streamProtocol: 'data',
    onFinish: (message) => { /* 处理完成 */ },
    onError: (error) => { /* 错误处理 */ },
  });
}
```

**修改文件**: `apps/web/src/components/chat/ChatContainer.tsx`

- 替换自定义 `streamChat()` 为 `useVibeChat()`
- 使用 AI SDK 的消息状态管理
- 实现 voice_mode 传递

### 3.3 Next.js Route Handler

**新建文件**: `apps/web/src/app/api/chat/route.ts`

- 转发请求到 Python 后端
- 转换 SSE 格式为 AI SDK 协议

---

## Phase 4: 冗余代码清理

### 4.1 删除冗余文件

```bash
# 删除完全冗余的 LifeKLine
rm apps/web/src/components/fortune/LifeKLine.tsx
rmdir apps/web/src/components/fortune/

# 删除空目录
rmdir apps/web/src/app/(main)/
rmdir apps/web/src/components/landing/
```

### 4.2 合并 VoiceToggle

**保留**: `apps/web/src/components/ui/VoiceModeToggle.tsx`
**删除**: `apps/web/src/components/ui/VoiceToggle.tsx`

**修改引用**:
- `ChatLayout.tsx`
- `MePanel.tsx`
- `ui/index.ts`

---

## Phase 5: UX 增强

### 5.1 空状态增强

**新建文件**: `apps/web/src/components/greeting/FortunePreview.tsx`

**功能**:
- 今日运势指数（分数 + 趋势箭头）
- 三维度条形图（事业/财运/感情）
- 今日建议一句话

**修改文件**: `apps/web/src/components/chat/ChatContainer.tsx`

- 在 `ChatEmptyState` 中添加 `FortunePreview`

### 5.2 参考 Claude.ai/Gemini 设计

**借鉴点**:
- Claude.ai: 消息左对齐，输入框底部居中，宽度受限
- Gemini: 响应式布局，左侧历史面板可折叠

---

## Phase 6: 支付系统完善

### 6.1 Stripe 集成完善

**修改文件**: `apps/api/services/billing/stripe_service.py`

- 完善订阅创建/取消流程
- Webhook 处理

### 6.2 Airwallex 集成

**新建文件**: `apps/api/services/billing/airwallex_service.py`

- 微信支付/支付宝跨境收单
- Webhook 处理

### 6.3 支付路由

**修改文件**: `apps/api/services/billing/payment_router.py`

- 根据用户地区和支付方式路由到 Stripe/Airwallex

### 6.4 删除 Mock 支付

**修改文件**: `apps/api/routes/payment.py`

- 删除 `/mock-pay` 端点
- 修复支付数据内存存储问题

---

## Phase 7: 认证系统迁移 (Clerk)

### 7.1 当前状态

- 自定义 `AuthProvider` + JWT
- `apps/api/services/identity/jwt.py` 处理认证

### 7.2 迁移步骤

**前端**:
```bash
npm install @clerk/nextjs
```

**新建文件**: `apps/web/src/middleware.ts` (更新)
```tsx
import { clerkMiddleware } from '@clerk/nextjs/server';
export default clerkMiddleware();
```

**修改文件**: `apps/web/src/app/layout.tsx`
```tsx
import { ClerkProvider } from '@clerk/nextjs';
// 替换现有 AuthProvider
```

**后端**:
- 安装 `clerk-backend-api`
- 修改 `apps/api/services/identity/jwt.py` 验证 Clerk JWT

### 7.3 用户数据迁移

- 导出现有用户
- 导入到 Clerk
- 更新数据库用户 ID 关联

---

## Phase 8: 主动推送系统完善

### 8.1 当前状态

- `services/reminder/` 框架存在
- 7种提醒类型已定义 (包括水逆 `MERCURY_RETROGRADE`)
- 触发逻辑未完整
- 推送通道未接入

### 8.2 完善步骤

**Step 1: 接入星历数据源**
```python
# apps/api/data/ephemeris.json
{
  "mercury_retrograde": [
    {"start": "2026-01-25", "end": "2026-02-15"},
    {"start": "2026-05-19", "end": "2026-06-12"},
    ...
  ],
  "lunar_phases": [...]
}
```

**Step 2: 完善 scheduler.py**
```python
# apps/api/services/reminder/scheduler.py
async def check_upcoming_events():
    # 检查水逆
    # 检查月相
    # 检查用户生日
    # 检查运势转折点
```

**Step 3: 实现个性化内容生成**
```python
# apps/api/services/reminder/generator.py
async def generate_reminder_content(user, event_type):
    # 读取用户 portrait
    # 读取用户命盘/星座
    # LLM 生成个性化内容
```

**Step 4: 接入推送通道**
- Web Push (优先)
- 应用内 Inbox
- 微信推送 (Phase 2)

**Step 5: 用户偏好设置 UI**
- 推送开关
- 推送频率
- 推送内容类型选择

---

## Phase 9: 可视化组件增强 (AI SDK 6 Generative UI)

### 9.1 目标

充分利用 Vercel AI SDK 6 的 Generative UI 能力，在聊天流中动态渲染图表组件。

### 9.2 实现方案

**定义 UI 组件映射**:
```tsx
// apps/web/src/app/api/chat/route.ts
import { streamUI } from 'ai/rsc';

const result = await streamUI({
  model: ...,
  messages: ...,
  tools: {
    renderBaziChart: {
      description: '渲染八字命盘',
      parameters: z.object({ ... }),
      generate: async function* (args) {
        yield <BaziChartSkeleton />;
        return <BaziChart data={args} />;
      }
    },
    renderKLine: {
      description: '渲染人生K线图',
      parameters: z.object({ ... }),
      generate: async function* (args) {
        yield <KLineSkeleton />;
        return <LifeKLine data={args} />;
      }
    }
  }
});
```

### 9.3 现有组件

- `BaziChart.tsx` (200行) - 八字命盘 SVG
- `ZodiacChart.tsx` (283行) - 星座盘 SVG
- `LifeKLine.tsx` (393行) - ECharts K线图

### 9.4 增强方向

1. 添加 Skeleton 加载状态
2. 支持交互式点击展开详情
3. 图表与对话上下文关联
4. 推演过场动画 (TransitionOverlay)

---

## 关键文件清单

### 新建文件

| 文件 | 用途 |
|------|------|
| `apps/web/src/app/(www)/layout.tsx` | 主站布局 |
| `apps/web/src/app/(bazi)/layout.tsx` | Bazi 专属布局 |
| `apps/web/src/app/(zodiac)/layout.tsx` | Zodiac 专属布局 |
| `apps/web/src/components/layout/ResizablePanel.tsx` | 可调节边栏 |
| `apps/web/src/hooks/useVibeChat.ts` | AI SDK useChat 封装 |
| `apps/web/src/app/api/chat/route.ts` | Next.js Route Handler (Generative UI) |
| `apps/web/src/components/greeting/FortunePreview.tsx` | 运势预览卡片 |
| `apps/api/services/billing/airwallex_service.py` | Airwallex 服务 |
| `apps/api/data/ephemeris.json` | 星历数据源 |
| `apps/web/src/components/chart/BaziChartSkeleton.tsx` | 图表加载骨架 |
| `apps/web/src/components/chart/KLineSkeleton.tsx` | K线加载骨架 |

### 修改文件

| 文件 | 修改内容 |
|------|---------|
| `apps/web/src/middleware.ts` | 完善子域名路由 + Clerk 集成 |
| `apps/web/src/app/layout.tsx` | 集成 ClerkProvider |
| `apps/web/src/components/layout/AppShell.tsx` | 集成 ResizablePanel |
| `apps/web/src/components/chat/ChatContainer.tsx` | 左对齐 + useChat + 空状态增强 |
| `apps/web/src/components/chat/ChatInput.tsx` | 输入框左对齐 |
| `apps/web/src/app/globals.css` | 消息自适应宽度 |
| `apps/api/routes/chat.py` | SSE 格式适配 AI SDK |
| `apps/api/routes/payment.py` | 删除 mock-pay |
| `apps/api/services/billing/stripe_service.py` | 完善 Stripe |
| `apps/api/services/identity/jwt.py` | 验证 Clerk JWT |
| `apps/api/services/reminder/scheduler.py` | 完善触发逻辑 |
| `apps/api/services/reminder/generator.py` | 个性化内容生成 |
| `apps/api/services/reminder/notification.py` | Web Push 接入 |

### 删除文件

| 文件 | 原因 |
|------|------|
| `apps/web/src/components/fortune/LifeKLine.tsx` | 被 trend 版本替代 |
| `apps/web/src/components/ui/VoiceToggle.tsx` | 与 VoiceModeToggle 重复 |
| `apps/web/src/app/(main)/` | 空目录 |
| `apps/web/src/components/landing/` | 空目录 |

---

## 执行顺序建议

```
Week 1: 架构基础
├── Phase 1.1: 创建路由组骨架
├── Phase 1.2: 实现 GlobalNav
├── Phase 4: 清理冗余代码
└── Phase 2.1: 聊天内容左对齐

Week 2: 布局完善
├── Phase 2.2: ResizablePanel 实现
├── Phase 2.3: 输入框位置调整
├── Phase 2.4: 移动端评估
└── Phase 5.1: 空状态增强

Week 3: AI SDK + 支付
├── Phase 3.1: 后端 SSE 适配
├── Phase 3.2: 前端 useChat 集成
├── Phase 6.1-6.2: Stripe/Airwallex 完善
└── Phase 6.3-6.4: 支付路由 + 删除 Mock
```

---

## 验证方案

### 功能验证

1. **子域名路由**
   - 访问 bazi.vibelife.local → 显示 Bazi 页面
   - 访问 zodiac.vibelife.local → 显示 Zodiac 页面
   - Cookie `vibelife_skill` 正确设置

2. **布局验证**
   - PC 端聊天内容左对齐
   - 右侧边栏可拖拽调节 (320-600px)
   - 边栏可折叠成图标条
   - 输入框与消息区域对齐

3. **AI SDK 验证**
   - 流式响应正常
   - voice_mode 传递正确
   - 错误处理正常

4. **支付验证**
   - Stripe Checkout 流程正常
   - Airwallex 跨境支付正常
   - Webhook 处理正确

### 视觉验证

- 参考 Claude.ai 截图对比布局
- 移动端各 Tab 切换正常
- 空状态运势预览显示正确

---

## 风险与注意事项

1. **路由组重构风险**
   - 现有页面链接可能失效
   - 需要更新所有内部链接

2. **AI SDK 升级风险**
   - 需要同时修改前后端
   - 测试流式响应兼容性

3. **支付系统风险**
   - Airwallex 需要申请开通
   - 国内用户需要跨境收单资质

4. **冗余清理风险**
   - 确认删除文件无其他引用
   - 检查 import 语句
