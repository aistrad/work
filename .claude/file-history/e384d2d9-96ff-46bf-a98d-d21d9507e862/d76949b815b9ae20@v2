# Discover 功能文档

VibeLife Skill 探索页面 - App Store 风格的 Skill 发现与订阅系统

## 📋 目录

- [概述](#概述)
- [功能特性](#功能特性)
- [架构设计](#架构设计)
- [快速开始](#快速开始)
- [相关文档](#相关文档)

## 概述

Discover 页面是 VibeLife V9.1 新增的 Skill 探索入口，参考 Apple App Store 设计语言，提供直观优雅的 Skill 发现、浏览和订阅体验。

**版本**: V9.1
**状态**: ✅ 已完成
**发布日期**: 2026-01-21

## 功能特性

### 🎨 用户界面

- **App Store 风格设计**
  - 精选横幅（400-480px 高度）
  - 横向滚动卡片（320px 宽度）
  - 分类区域组织
  - 渐变背景 + 品牌色系统

- **响应式布局**
  - PC 端三栏布局（≥1024px）
  - Mobile 端单栏切换（<1024px）
  - 完全适配不同屏幕尺寸

- **完善的状态处理**
  - Loading 状态（骨架屏动画）
  - Error 状态（红色警告 + 重载按钮）
  - Empty 状态（Sparkles 图标 + 提示）

### 📱 导航入口

**PC 左侧栏** (NavBar.tsx)
```
┌────────┐
│  首页  │
│  对话  │
│  探索  │ ← 新增（位于旅程和我的之间）
│  我的  │
└────────┘
```

**Mobile 底栏** (MobileTabBar.tsx)
```
┌─────┬─────┬─────┬─────┐
│ 对话 │ 旅程 │ 探索 │ 我的 │
└─────┴─────┴─────┴─────┘
              ↑ 新增
```

### 🔮 内容展示

**8 个 Skills 分为 3 个分类：**

| 分类 | Skills | 数量 |
|-----|--------|------|
| **核心能力** | 生命对话者 | 1 |
| **基础功能** | 正念导师 | 1 |
| **专业技能** | 八字命理、西方占星、塔罗占卜、荣格心理占星、职业规划、VibeID 人格画像 | 6 |

**展示区域：**
1. 精选横幅 - 大尺寸视觉冲击
2. 为你推荐 - 智能推荐（需登录）
3. 专业技能 - 横向滚动展示
4. 基础功能 - 实用工具
5. 核心能力 - 始终激活

## 架构设计

### 技术栈

- **前端框架**: Next.js 14.2.35 + React 18
- **状态管理**: SWR（数据获取）
- **样式方案**: Tailwind CSS + CSS Modules
- **动画库**: Framer Motion（部分）
- **类型检查**: TypeScript 5.x

### 文件结构

```
apps/web/src/
├── components/discover/
│   ├── DiscoverContent.tsx         # 主页面组件
│   ├── FeaturedSkillBanner.tsx     # 精选横幅
│   ├── SkillShowcaseCard.tsx       # Skill 展示卡片
│   ├── CategorySection.tsx         # 分类区域
│   └── index.ts                    # 导出文件
├── app/api/v1/skills/
│   ├── route.ts                    # Skills 列表 API
│   ├── subscriptions/route.ts      # 订阅状态 API
│   └── recommendations/route.ts    # 推荐 API
├── hooks/
│   └── useSkillSubscription.ts     # Skills 数据 Hook
├── components/layout/
│   ├── NavBar.tsx                  # PC 导航栏
│   ├── MobileTabBar.tsx            # Mobile 底栏
│   ├── AppShell.tsx                # 主布局容器
│   └── PCLayout.tsx                # PC 三栏布局
└── app/chat/page.tsx               # Chat 页面（集成入口）
```

### 数据流

```
Backend API (port 8100)
    ↓
Next.js API Routes (/api/v1/skills)
    ↓
SWR Hook (useSkills)
    ↓
DiscoverContent Component
    ↓
User Interface
```

## 快速开始

### 1. 启动服务

```bash
# 启动后端 API（端口 8100）
cd apps/api
uvicorn main:app --host 0.0.0.0 --port 8100 --reload

# 启动前端（端口 8232）
cd apps/web
pnpm dev --port 8232
```

### 2. 访问页面

1. 打开浏览器：`http://localhost:8232`
2. 点击左侧导航的 **"✨ 探索"** 或底部的 **"探索 Skills"**
3. 查看完整的 Skill 探索页面

### 3. 验证功能

```bash
# 测试 Skills API
curl http://localhost:8232/api/v1/skills | jq

# 预期输出
{
  "total": 8,
  "skills": [...],
  "categories": {
    "core": { "count": 1 },
    "default": { "count": 1 },
    "professional": { "count": 6 }
  }
}
```

## 相关文档

- [集成指南](./INTEGRATION.md) - 完整的集成步骤
- [组件文档](./COMPONENTS.md) - 组件 API 和使用说明
- [API 文档](./API.md) - 后端 API 接口说明
- [问题排查](./TROUBLESHOOTING.md) - 常见问题和解决方案
- [变更日志](./CHANGELOG.md) - 版本更新记录

## 设计亮点

✨ **App Store 风格** - 参考 Apple 设计语言
🎨 **品牌色系统** - 每个 Skill 使用自己的主题色
📱 **完全响应式** - PC 三栏布局 / Mobile 单栏切换
⚡ **性能优化** - Suspense 懒加载 + SWR 缓存
🛡️ **健壮性** - 完整的 Loading/Error/Empty 状态
🔧 **可维护性** - 模块化组件 + TypeScript 类型安全

## 许可证

Copyright © 2026 VibeLife. All rights reserved.
