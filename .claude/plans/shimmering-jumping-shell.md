# VibeLife 重构计划

## 项目概述

将 mentis 项目完全重构为 vibelife 全新项目，基于 vibelife spec v2.0 和 v2.1 规范文档实现完整的 Living Companion 生态系统。

### 关键决策
- **项目方式**: 全新项目 at `/home/aiscend/work/vibelife`
- **Phase 1 Skill 站点**: bazi + zodiac + mbti (三个站点)
- **Vibe ID**: 完整实现 (SSO、跨站授权、数据主权)
- **技术栈**: FastAPI + PostgreSQL + pgvector + Next.js 14+

---

## 重构 TODO Plan

### Phase 0: 项目初始化

- [ ] **0.1 创建项目目录结构**
  - 创建 `/home/aiscend/work/vibelife` 根目录
  - 设置 monorepo 结构 (pnpm workspace + Turbo)
  - 初始化 Git 仓库

- [ ] **0.2 后端基础设施初始化**
  - Python 虚拟环境和依赖管理 (poetry/pip)
  - FastAPI 项目骨架
  - PostgreSQL 连接配置 (含 pgvector 扩展)
  - 环境变量配置 (.env)

- [ ] **0.3 前端基础设施初始化**
  - Next.js 14 项目初始化 (App Router)
  - Tailwind CSS + Radix UI 配置
  - TypeScript 配置
  - 共享组件库结构

---

### Phase 1: 数据层 (L6 - Identity & Data Layer)

- [ ] **1.1 数据库 Schema 设计**
  - Vibe ID 核心表 (vibe_user, vibe_profile, auth_provider)
  - Skill Profile 表 (skill_profile_bazi, skill_profile_zodiac, skill_profile_mbti)
  - 数据主权表 (consent_record, data_export_log)
  - 跨站 Session 表 (sso_session, cross_site_token)

- [ ] **1.2 pgvector 知识库表结构**
  - knowledge_chunk (向量化知识块)
  - knowledge_source (知识来源)
  - qa_pair (问答对)
  - 向量索引创建

- [ ] **1.3 数据库迁移脚本**
  - 编写 SQL 迁移文件
  - 执行迁移并验证

---

### Phase 2: Vibe ID 统一身份系统

- [ ] **2.1 认证层实现**
  - Email/Password 认证 (bcrypt hash)
  - Magic Link 认证
  - Social OAuth (WeChat, Apple, Google) - 预留接口
  - JWT Token 管理 (access/refresh)
  - MFA 支持预留

- [ ] **2.2 SSO 跨站登录**
  - id.vibelife.app 认证中心
  - Cross-site token 生成和验证
  - SSO 跳转流程实现
  - Session 同步机制

- [ ] **2.3 数据主权层**
  - Data Vault (加密存储)
  - Consent Manager (授权管理 API)
  - Export Engine (数据导出)
  - Skill 间数据共享授权

- [ ] **2.4 用户画像系统**
  - Core Profile API (跨站共享信息)
  - Skill Profile API (各站独立数据)
  - Cross-Skill Insights 聚合

---

### Phase 3: 核心引擎层 (L5 - Vibe Engine)

- [ ] **3.1 LLM 编排器**
  - 多模型支持 (GLM, Claude API)
  - Prompt 模板管理
  - 上下文窗口管理
  - 流式响应支持

- [ ] **3.2 情绪感知引擎**
  - 规则引擎移植 (8主情绪 + 12次级)
  - LLM 深度分析
  - 混合分析策略

- [ ] **3.3 用户模型系统**
  - 行为模式检测
  - 性格画像构建
  - 偏好学习

- [ ] **3.4 Insight 生成器**
  - Insight 触发规则引擎
  - 4种卡片类型生成 (Discovery, Pattern, Timing, Growth)
  - 置信度评估
  - 冷却期管理

- [ ] **3.5 Vibe Score 系统**
  - 能量分数计算
  - 趋势追踪
  - 历史记录

---

### Phase 4: 知识引擎层 (L4 - Knowledge Layer)

- [ ] **4.1 知识处理管道**
  - 知识提取 (Extract)
  - 语义分块 (Chunking)
  - 实体关系抽取
  - QA 对生成

- [ ] **4.2 混合检索系统**
  - pgvector 向量检索
  - PostgreSQL 全文检索 (FTS)
  - Reciprocal Rank Fusion (RRF)
  - LLM 相关性评分

- [ ] **4.3 知识库内容**
  - 八字知识库 (theory, patterns, transit, cases)
  - 星座知识库 (zodiac-signs, houses, planets, aspects)
  - MBTI 知识库 (cognitive-functions, 16-types)

---

### Phase 5: Skill Agent 层 (L3 - Skill Agent Layer)

- [ ] **5.1 Agent Runtime 框架**
  - Persona Injector (角色注入)
  - Skill Router (意图路由)
  - Context Builder (上下文构建)
  - Tool Executor (工具执行)

- [ ] **5.2 Skill 定义规范**
  - SKILL.md 解析器
  - SKILL.yaml 配置加载
  - Workflow 引擎
  - Insight Rules 引擎

- [ ] **5.3 Agent 处理流程**
  - Context Assembly
  - Intent Classification
  - Knowledge Retrieval
  - Tool Invocation
  - Insight Generation
  - Response Composition

---

### Phase 6: Skill 工具函数系统

- [ ] **6.1 八字工具 (bazi tools)**
  - bazi.calculator.generate_chart (排盘)
  - bazi.transit.calculate_dayun (大运流年)
  - bazi.pattern.analyze (格局分析)
  - bazi.elements.calculate_strength (五行力量)

- [ ] **6.2 星座工具 (zodiac tools)**
  - zodiac.chart.calculate_natal (本命盘)
  - zodiac.transit.current (当前行星)
  - zodiac.aspects.analyze (相位分析)
  - zodiac.events.mercury_retrograde (水逆计算)

- [ ] **6.3 MBTI 工具 (mbti tools)**
  - mbti.assessment.calculate_type (类型计算)
  - mbti.functions.analyze (认知功能)
  - mbti.compatibility.check (类型兼容)

---

### Phase 7: 体验层 (L2 - Experience Layer)

- [ ] **7.1 The Landing - 零摩擦入口**
  - Landing 页面组件
  - 出生信息输入组件
  - 即时洞察卡片
  - 渐进式注册流程

- [ ] **7.2 Stream - 对话流界面**
  - Stream Feed 组件
  - Message Card 组件
  - Insight Card 组件
  - Quick Actions 组件
  - Omnibar 输入框

- [ ] **7.3 Insight Card 系统**
  - Discovery Card 组件
  - Pattern Card 组件
  - Timing Card 组件
  - Growth Card 组件
  - 卡片动画和交互

- [ ] **7.4 Profile & Settings**
  - 用户资料页面
  - Vibe ID 设置
  - 通知设置
  - 数据隐私设置

---

### Phase 8: 独立站点层 (L1 - Skill Constellation Layer)

- [ ] **8.1 bazi.vibelife.app**
  - 站点路由配置
  - 八字专属 Landing
  - 命盘展示组件
  - 运势日历组件
  - 月运/流年报告

- [ ] **8.2 zodiac.vibelife.app**
  - 站点路由配置
  - 星座专属 Landing
  - 星盘展示组件
  - 水逆提醒组件
  - 周运/月运报告

- [ ] **8.3 mbti.vibelife.app**
  - 站点路由配置
  - MBTI 专属 Landing
  - 类型测评流程
  - 认知功能展示
  - 类型详情页

- [ ] **8.4 共享组件库**
  - 统一导航栏
  - 统一页脚
  - Skill 切换组件
  - 跨站引导组件

---

### Phase 9: 主动智能系统

- [ ] **9.1 Event Calendar**
  - 节气日历数据
  - 星象事件数据
  - 用户事件管理

- [ ] **9.2 Reminder Scheduler**
  - Cron Job 调度
  - 事件扫描
  - 用户匹配

- [ ] **9.3 Content Generator**
  - 个性化内容生成
  - Persona Guidelines 应用
  - 模板渲染

- [ ] **9.4 Notification Delivery**
  - In-App 通知
  - Push 通知 (预留)
  - 用户偏好设置

---

### Phase 10: Skill Mirror 系统

- [ ] **10.1 月运回顾卡 (Bazi)**
  - 回顾内容生成
  - 卡片 UI 组件
  - 分享功能

- [ ] **10.2 周运回顾卡 (Zodiac)**
  - 回顾内容生成
  - 卡片 UI 组件
  - 分享功能

- [ ] **10.3 可分享卡片**
  - 卡片图片生成
  - 多尺寸支持
  - 分享链接生成

---

### Phase 11: 测试与文档

- [ ] **11.1 单元测试**
  - 后端 API 测试
  - 工具函数测试
  - 前端组件测试

- [ ] **11.2 集成测试**
  - 跨站 SSO 流程测试
  - Agent 处理流程测试
  - 知识检索测试

- [ ] **11.3 文档**
  - API 文档 (OpenAPI)
  - Skill 开发指南
  - 部署文档

---

### Phase 12: 部署与上线

- [ ] **12.1 部署配置**
  - Docker 容器化
  - 域名配置 (*.vibelife.app)
  - SSL 证书

- [ ] **12.2 CI/CD 流水线**
  - GitHub Actions 配置
  - 自动化测试
  - 自动部署

---

## 技术架构

```
/vibelife/
├── apps/
│   ├── api/                    # FastAPI 后端
│   │   ├── main.py
│   │   ├── routes/
│   │   │   ├── auth/           # Vibe ID 认证
│   │   │   ├── skill/          # Skill Agent API
│   │   │   ├── stream/         # Stream API
│   │   │   └── insight/        # Insight API
│   │   ├── services/
│   │   │   ├── vibe_engine/    # L5 核心引擎
│   │   │   ├── knowledge/      # L4 知识引擎
│   │   │   ├── agent/          # L3 Agent 系统
│   │   │   └── identity/       # Vibe ID 服务
│   │   └── stores/
│   │       └── db.py           # PostgreSQL + pgvector
│   │
│   ├── web/                    # Next.js 14 主站
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   ├── (auth)/     # 认证页面
│   │   │   │   ├── (bazi)/     # 八字站点
│   │   │   │   ├── (zodiac)/   # 星座站点
│   │   │   │   └── (mbti)/     # MBTI 站点
│   │   │   ├── components/
│   │   │   │   ├── landing/
│   │   │   │   ├── stream/
│   │   │   │   ├── insight/
│   │   │   │   └── shared/
│   │   │   └── lib/
│   │   └── tailwind.config.ts
│   │
│   └── id/                     # Vibe ID 认证中心
│       └── ...
│
├── packages/
│   ├── skills/                 # Skill 定义
│   │   ├── bazi/
│   │   │   ├── SKILL.md
│   │   │   ├── scripts/
│   │   │   ├── references/
│   │   │   └── assets/
│   │   ├── zodiac/
│   │   └── mbti/
│   │
│   ├── knowledge/              # 知识库
│   │   ├── bazi/
│   │   ├── zodiac/
│   │   └── mbti/
│   │
│   └── shared/                 # 共享代码
│       ├── types/
│       └── utils/
│
├── migrations/                 # 数据库迁移
├── docs/                       # 文档
├── tests/                      # 测试
├── package.json                # Monorepo 配置
├── pnpm-workspace.yaml
├── turbo.json
└── docker-compose.yml
```

---

## 执行策略

每个 Phase 完成后:
1. 自我测试验证功能
2. `/compact` 压缩上下文
3. 继续下一个 Phase

预计总共 12 个 Phase，每个 Phase 包含多个子任务。
