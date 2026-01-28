# Discover 功能文档中心

**版本**: V9.2
**最后更新**: 2026-01-21
**状态**: ✅ 已完成并优化

---

## 📚 快速导航

### 🎯 主文档

**[DESIGN.md](./DESIGN.md)** - **完整设计文档**（推荐首先阅读）
> 包含完整的设计概述、架构设计、组件设计、交互设计、技术决策和优化记录

---

## 📋 功能概述

Discover 是 VibeLife 的 **Skill 探索页面**，采用 **App Store 风格**设计，让用户能够：

- 🔍 浏览和发现所有可用的 Skills
- 💫 查看精选推荐的 Skill
- 📱 横向滚动浏览不同分类的 Skills
- ✨ 快速订阅感兴趣的 Skills
- 🎯 获得基于使用习惯的个性化推荐

---

## ✨ 核心功能

### 1. 精选横幅
- App Store 风格大尺寸横幅（400-480px 高度）
- 渐变背景 + 品牌色系统
- 点击跳转 Skill 详情页

### 2. 分类展示
- **专业技能** - 6 个专业 Skills（八字、占星、塔罗等）
- **核心能力** - 2 个核心 Skills（生命对话者、正念导师）

### 3. 横向滚动（V9.2 优化）
- 触摸设备：手指滑动
- 鼠标设备：**拖拽滚动**（新增）
- 滚轮设备：Shift + 滚轮

### 4. Skill 卡片
- 320px 宽度固定卡片
- 显示图标、名称、描述、定价
- 订阅状态展示
- 点击查看详情 / 快速订阅

---

## 🚀 最新更新 (V9.2)

### ✅ 鼠标拖拽滚动
- 桌面端用户可以用鼠标拖拽横向滚动
- grab/grabbing cursor 视觉反馈
- 智能区分拖拽和点击（移动 > 5px 才算拖拽）

### ✅ 合并分类
- 将"基础功能"和"核心能力"合并为单一"核心能力"section
- 优化信息架构，提升视觉紧凑度

### ✅ 点击事件修复
- 修复 Skill 卡片点击跳转
- 修复"获取"按钮订阅功能
- 修复精选横幅点击跳转

---

## 📖 详细文档

### 设计和架构

- **[DESIGN.md](./DESIGN.md)** - 完整设计文档
  - 设计概述和原则
  - 架构设计
  - 组件设计详解
  - 交互设计流程
  - 数据流设计
  - 技术决策记录
  - 优化记录
  - 未来规划

### 参考文档（ref/ 目录）

#### 快速开始
- **[README.md](./ref/README.md)** - 功能总览和快速开始
- **[SUMMARY.md](./ref/SUMMARY.md)** - 完成报告和交付成果

#### 开发指南
- **[INTEGRATION.md](./ref/INTEGRATION.md)** - 完整集成步骤
- **[COMPONENTS.md](./ref/COMPONENTS.md)** - 组件 API 文档
- **[API.md](./ref/API.md)** - 后端 API 文档

#### 维护参考
- **[TROUBLESHOOTING.md](./ref/TROUBLESHOOTING.md)** - 问题排查指南
- **[CHANGELOG.md](./ref/CHANGELOG.md)** - 版本变更记录
- **[FILES.md](./ref/FILES.md)** - 源代码文件索引
- **[INDEX.md](./ref/INDEX.md)** - 文档导航索引

---

## 🏗️ 技术栈

### 前端
- **Next.js 14.2.35** - React 框架 (App Router)
- **TypeScript** - 类型安全
- **Tailwind CSS** - 样式框架
- **SWR** - 数据获取和缓存

### 后端
- **FastAPI** - Python API 框架
- **端口**: 8100

### 测试
- **Playwright** - E2E 测试

---

## 📁 代码结构

```
apps/web/src/
├── components/discover/           # Discover 组件
│   ├── DiscoverContent.tsx        # 主容器 (~240 行)
│   ├── FeaturedSkillBanner.tsx    # 精选横幅 (~80 行)
│   ├── SkillShowcaseCard.tsx      # Skill 卡片 (~137 行)
│   ├── CategorySection.tsx        # 分类区域 (~129 行) ✨V9.2优化
│   └── index.ts                   # 导出文件
├── app/api/v1/skills/             # API Routes
│   ├── route.ts                   # Skills 列表
│   ├── subscriptions/route.ts     # 订阅状态
│   └── recommendations/route.ts   # 智能推荐
└── hooks/
    └── useSkillSubscription.ts    # Skills 数据 Hook
```

---

## 🎯 快速开始

### 访问页面

**PC 端**:
```
首页 → 对话 → 探索
```

**Mobile 端**:
```
底部导航栏：对话 | 旅程 | 探索 | 我的
```

**直接访问**:
```
http://localhost:8232/chat?tab=discover
```

### 开发环境

```bash
# 1. 启动后端服务（端口 8100）
cd apps/api
uvicorn main:app --port 8100 --reload

# 2. 启动前端服务（端口 8232）
cd apps/web
pnpm dev

# 3. 访问
open http://localhost:8232/chat?tab=discover
```

### 测试

```bash
# E2E 测试
cd apps/web
npx playwright test
```

---

## 🐛 常见问题

### 页面显示空白？

**检查清单**:
1. 后端服务是否运行？`ps aux | grep uvicorn`
2. 前端服务是否运行？`ps aux | grep next`
3. API 是否正常？`curl http://localhost:8100/api/v1/skills`
4. 浏览器控制台有错误吗？

### 点击无效？

**V9.2 已修复**:
- ✅ Skill 卡片点击
- ✅ "获取"按钮点击
- ✅ 精选横幅点击

### 无法鼠标拖拽滚动？

**V9.2 已支持**:
- 鼠标按住拖拽即可横向滚动
- 如果点击误触发拖拽，增大移动阈值（当前 5px）

详细问题排查请参考 **[TROUBLESHOOTING.md](./ref/TROUBLESHOOTING.md)**

---

## 📊 性能指标

- **首次加载**: < 2s
- **交互响应**: < 100ms
- **滚动流畅度**: 60fps
- **无 Hydration 错误**: ✅
- **无 Console 错误**: ✅

---

## 🔮 未来规划

### V9.3
- [ ] 搜索功能
- [ ] 高级筛选
- [ ] 排序选项
- [ ] Skill 详情页优化

### V9.4
- [ ] 用户评价和评分
- [ ] 相关 Skills 推荐
- [ ] Skill 对比功能
- [ ] 收藏夹功能

### V10.0
- [ ] Skill 市场（第三方开发者）
- [ ] AI 推荐算法优化
- [ ] A/B 测试框架

---

## 📞 获取帮助

### 文档
1. 阅读 [DESIGN.md](./DESIGN.md) 了解设计细节
2. 查看 [TROUBLESHOOTING.md](./ref/TROUBLESHOOTING.md) 排查问题
3. 参考 [INTEGRATION.md](./ref/INTEGRATION.md) 集成步骤

### 支持
- 📖 查阅文档
- 🐛 提交 GitHub Issue
- 💬 联系开发团队

---

## 👥 贡献者

- **开发**: Claude (Anthropic)
- **需求**: VibeLife Product Team
- **设计参考**: Apple App Store

---

## 📄 许可证

Copyright © 2026 VibeLife. All rights reserved.

---

## 📝 更新日志

### V9.2 - 2026-01-21
- ✨ 新增鼠标拖拽滚动功能
- 🔧 合并"基础功能"和"核心能力"分类
- 🐛 修复所有点击事件问题

### V9.1 - 2026-01-21
- 🎉 初始版本发布
- ✨ App Store 风格设计
- 🔧 完整 API 集成
- 🐛 修复 Hydration 错误

---

**文档维护**: Claude (Anthropic)
**版本**: V9.2
**最后更新**: 2026-01-21
