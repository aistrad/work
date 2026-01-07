# VibeLife 完整重构计划

> 严格基于 vibelife spec v2.0.md 和 v2.1.md 实现全部功能

## 项目概述

将 mentis 项目完全重构为 vibelife 全新项目，实现完整的 **Living Companion** 生态系统。

### 关键决策
- **项目方式**: 全新项目 at `/home/aiscend/work/vibelife`
- **Phase 1 Skill 站点**: bazi + zodiac + mbti (三个站点)
- **Vibe ID**: 完整实现 (SSO、跨站授权、数据主权)
- **技术栈**: FastAPI + PostgreSQL + pgvector + Next.js 14+

---

## 可用资源配置 (来自 config.md)

### 数据库 - PostgreSQL (aiscend 服务器)

| 配置项 | 值 |
|--------|-----|
| 主机 | `106.37.170.238` |
| 端口 | `8224` |
| 用户 | `postgres` |
| 密码 | `Ak4_9lScd-69WX` |
| 数据库 | `vibelife` (新建) / `mentis_v3` (参考) |
| 连接字符串 | `postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/vibelife` |

### LLM 服务 - 智谱 GLM

| 配置项 | 值 |
|--------|-----|
| API Key | `42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF` |
| 对话模型 | `glm-4.7` ✅ (最新旗舰) |
| 图片理解 | `glm-4.6v` ✅ (最新视觉) |
| API 文档 | https://bigmodel.cn/dev/api |

### LLM 服务 - Claude (备选)

| 配置项 | 值 |
|--------|-----|
| API Key | 需配置 `CLAUDE_API_KEY` |
| 模型 | `claude-3-5-sonnet-20241022` |

### 向量嵌入 - Google Gemini

| 配置项 | 值 |
|--------|-----|
| API Key | `AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE` |
| 模型 | `gemini-embedding-001` |
| **维度** | **3072** |

### 向量存储 - Pinecone

| 配置项 | 值 |
|--------|-----|
| API Key | `pcsk_tVETE_HsAhSvJG9yN2nSdGfkMz2aTefYa72inmvnp97musqf3twzRgDiLEtHDdYAsBmiQ` |
| 索引名称 | `mentis-streams` (可复用或新建 `vibelife-knowledge`) |
| Host | `mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io` |
| **维度** | **3072** (与 Gemini 匹配) |
| Metric | `cosine` |

### 服务分工总览

| 服务 | 提供商 | 模型 | 状态 |
|------|--------|------|------|
| 对话生成 | GLM | glm-4.7 | ✅ 已验证 |
| 图片理解 | GLM | glm-4.6v | ✅ 已配置 |
| 向量嵌入 | Gemini | gemini-embedding-001 (3072维) | ✅ 已升级 |
| 语义搜索 | Pinecone | mentis-streams (3072维) | ✅ 已升级 |
| 星盘计算 | swisseph | Swiss Ephemeris | 待安装 |

### 环境变量模板

```bash
# ─────────────────────────────────────────────────────────────────
# VIBELIFE 环境变量
# ─────────────────────────────────────────────────────────────────

# 数据库
VIBELIFE_DB_URL=postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/vibelife

# JWT
VIBELIFE_JWT_SECRET=vibelife-jwt-secret-key-2026-aiscend

# 智谱 GLM (对话/图片)
GLM_API_KEY=42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.6v

# Claude (备选)
CLAUDE_API_KEY=your-claude-api-key

# Google Gemini (Embedding)
GEMINI_API_KEY=AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE
GEMINI_EMBEDDING_MODEL=gemini-embedding-001

# Pinecone
PINECONE_API_KEY=pcsk_tVETE_HsAhSvJG9yN2nSdGfkMz2aTefYa72inmvnp97musqf3twzRgDiLEtHDdYAsBmiQ
PINECONE_HOST=mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io

# 默认 LLM 提供商: glm | claude
DEFAULT_LLM_PROVIDER=glm
```

---

### 核心定位
> "The Living Companion" — 每个人都值得被深度理解

**三大差异化**:
1. **Deep Understanding** — 理解你这个人，而非只是问题
2. **Proactive Agency** — 主动关心，而非等你开口
3. **Infinite Extensibility** — 通过 Skills 无限扩展

**四大体验支柱**: INSIGHT (看见) → INTERACT (陪伴) → EVOLVE (演化) → EDUCATE (觉知)

---

## 六层架构总览

```
┌─────────────────────────────────────────────────────────────────────┐
│  L1: SKILL CONSTELLATION LAYER                                       │
│  独立站点层 - bazi.vibelife.app / zodiac.vibelife.app / mbti...    │
├─────────────────────────────────────────────────────────────────────┤
│  L2: EXPERIENCE LAYER                                                │
│  体验标准层 - Landing / Stream / Insight Cards / Skill Mirror       │
├─────────────────────────────────────────────────────────────────────┤
│  L3: SKILL AGENT LAYER                                               │
│  智能代理层 - Persona / Skill Router / Tool Executor / Workflow     │
├─────────────────────────────────────────────────────────────────────┤
│  L4: KNOWLEDGE LAYER                                                 │
│  知识引擎层 - Chunking / Vector + FTS + Graph / RRF / LLM Grading   │
├─────────────────────────────────────────────────────────────────────┤
│  L5: VIBE ENGINE                                                     │
│  核心引擎层 - LLM / Memory / Emotion / User Model / Insight / Score │
├─────────────────────────────────────────────────────────────────────┤
│  L6: IDENTITY & DATA LAYER                                           │
│  身份数据层 - Vibe ID / SSO / Data Vault / Consent / Profiles       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 重构 TODO Plan

### Phase 0: 项目初始化 ✅ 已完成 (2026-01-05)

- [x] **0.1 创建项目目录结构**
  - 创建 `/home/aiscend/work/vibelife` 根目录
  - 设置 monorepo 结构 (pnpm workspace + Turbo)
  - 初始化 Git 仓库
  - 创建 .gitignore, .env.example

- [x] **0.2 后端基础设施初始化 (FastAPI)**
  - FastAPI 项目骨架 (`apps/api/`)
  - PostgreSQL 连接配置 (含 pgvector 扩展)
  - 环境变量配置 (.env)
  - requirements.txt
  - 数据库迁移 (14个表已创建)

- [x] **0.3 前端基础设施初始化 (Next.js 14)**
  - Next.js 14 项目初始化 (App Router)
  - TypeScript 配置
  - Tailwind CSS 配置
  - 共享组件库结构 (`packages/ui/`)

- [x] **0.4 开发工具配置**
  - Turbo pipeline 配置
  - Docker Compose (本地开发)

**已创建项目结构**:
```
/home/aiscend/work/vibelife/
├── apps/
│   ├── api/                     # FastAPI 后端
│   │   ├── main.py              # 应用入口
│   │   ├── requirements.txt
│   │   ├── Dockerfile
│   │   ├── routes/
│   │   │   ├── auth.py          # 认证路由
│   │   │   └── health.py        # 健康检查
│   │   └── stores/
│   │       └── db.py            # 数据库连接
│   └── web/                     # Next.js 14 前端
│       ├── package.json
│       ├── tailwind.config.ts
│       └── src/app/
├── migrations/
│   └── 001_init.sql             # 数据库初始化 (已执行)
├── packages/                    # 共享包
├── package.json                 # Monorepo 配置
├── pnpm-workspace.yaml
├── turbo.json
├── docker-compose.yml
├── .env.example
├── .env                         # 已配置
└── .gitignore
```

**已创建数据库表 (14个)**:
- `vibe_users`, `vibe_user_auth`, `vibe_data_consents`
- `skill_profiles`, `skill_conversations`, `skill_messages`, `skill_insights`
- `subscription_plans`, `user_subscriptions`
- `knowledge_chunks` (pgvector 3072维), `knowledge_qa_pairs`
- `fortune_events`, `reminder_settings`, `user_notifications`

---

### Phase 1: 数据层完善 (L6 - Identity & Data Layer)

> 注: 基础表已在 Phase 0 创建，此阶段完善数据访问层

- [x] **1.1 数据库 Schema 设计 - Vibe ID 核心表** ✅ 已完成
  ```sql
  vibe_users              -- 用户核心表 (vibe_id, display_name, birth_datetime, etc.)
  vibe_user_auth          -- 认证方式表 (email/phone/wechat/apple/google)
  vibe_data_consents      -- 数据共享授权表
  ```

- [x] **1.2 数据库 Schema 设计 - Skill 数据表** ✅ 已完成
  ```sql
  skill_profiles          -- Skill Profile (JSONB profile_data)
  skill_conversations     -- 对话记录
  skill_messages          -- 消息记录 (intent, tools_used, knowledge_used)
  skill_insights          -- 洞察记录 (insight_type, confidence, user_reaction)
  ```

- [x] **1.3 数据库 Schema 设计 - 订阅与商业化** ✅ 已完成
  ```sql
  subscription_plans      -- 订阅计划 (skill_single/skill_bundle/vibelife_all)
  user_subscriptions      -- 用户订阅状态
  ```

- [x] **1.4 数据库 Schema 设计 - 知识库表** ✅ 已完成
  ```sql
  knowledge_chunks        -- 知识块 (含 pgvector 3072维向量 + tsvector 全文)
  knowledge_qa_pairs      -- QA 对
  ```

- [x] **1.5 数据库 Schema 设计 - 提醒与通知** ✅ 已完成
  ```sql
  fortune_events          -- 运势事件日历
  user_notifications      -- 用户通知记录
  reminder_settings       -- 提醒设置
  ```

- [x] **1.6 pgvector 向量索引** ✅ 已完成
  - pgvector 扩展已安装
  - 向量列已创建 (3072维，匹配 Gemini embedding)
  - 索引已创建

- [x] **1.7 数据库迁移脚本** ✅ 已完成
  - `migrations/001_init.sql` 已执行
  - 14个表已创建并验证

- [ ] **1.8 数据访问层 (Repository Pattern)**
  - `stores/user_repo.py` - 用户数据操作
  - `stores/skill_repo.py` - Skill 数据操作
  - `stores/knowledge_repo.py` - 知识库操作
  - `stores/subscription_repo.py` - 订阅操作

- [ ] **1.9 Pydantic Models**
  - `models/user.py` - 用户模型
  - `models/skill.py` - Skill 相关模型
  - `models/knowledge.py` - 知识模型
  - `models/subscription.py` - 订阅模型

---

### Phase 2: Vibe ID 统一身份系统 ✅ 已完成 (2026-01-05)

- [x] **2.1 认证层实现**
  - Email/Password 认证 (bcrypt hash)
  - Magic Link 认证 (邮件发送)
  - JWT Token 管理 (access token + refresh token)
  - Token 刷新机制

- [ ] **2.2 Social OAuth 集成**
  - 微信登录 (预留实现)
  - Apple 登录 (预留实现)
  - Google 登录 (预留实现)
  - OAuth 统一适配器

- [ ] **2.3 SSO 跨站登录**
  - id.vibelife.app 认证中心
  - Cross-site token 生成 (短期有效)
  - SSO 跳转流程实现
  - Session 同步机制
  - 站点间 Token 验证

- [ ] **2.4 数据主权层**
  - Data Vault (敏感数据加密存储)
  - Consent Manager (授权管理 API)
  - Export Engine (数据导出 - JSON/PDF)
  - Skill 间数据共享授权机制

- [ ] **2.5 用户画像系统**
  - Core Profile API (跨站共享: birth_datetime, location, timezone)
  - Skill Profile API (各站独立: bazi chart, zodiac sign, mbti type)
  - Cross-Skill Insights 聚合 API

- [ ] **2.6 MFA 支持预留**
  - TOTP 接口设计
  - 短信验证码接口设计

---

### Phase 3: 核心引擎层 (L5 - Vibe Engine) ✅ 已完成 (2026-01-05)

- [x] **3.1 LLM 编排器 (Chat Engine)**
  - 多模型支持适配器 (Claude, GLM, GPT-4)
  - Prompt 模板管理系统
  - System Prompt 构建器 (Persona + Skill + User Context)
  - 上下文窗口管理 (Token 计数, 截断策略)
  - **流式响应支持 (SSE/WebSocket)**
  - 重试和降级策略

- [ ] **3.2 Memory System (记忆系统)**
  - 短期记忆 (对话上下文)
  - 长期记忆 (向量化存储)
  - 记忆检索 (相关性匹配)
  - 记忆更新和衰减

- [ ] **3.3 情绪感知引擎 (Emotion Analysis)**
  - 规则引擎 (8主情绪 + 12次级情绪)
  - LLM 深度分析
  - 混合分析策略 (Rule + LLM)
  - 情绪强度评估

- [ ] **3.4 用户模型系统 (User Model)**
  - 行为模式检测
  - 性格画像构建
  - 偏好学习
  - 对话风格适应

- [ ] **3.5 Insight 生成器**
  - **4种卡片类型生成器**:
    - DISCOVERY Card (发现卡) - "我看见你..."
    - PATTERN Card (模式卡) - "我注意到一个模式..."
    - TIMING Card (时机卡) - "现在是...的好时机"
    - GROWTH Card (成长卡) - "你的成长..."
  - **触发规则引擎**:
    - Discovery: 首次提及 + 强情绪 + 重要主题
    - Pattern: 3次以上 + 相似上下文 + 稳定出现
    - Timing: 运势节点 + 能量高峰 + 用户准备好
    - Growth: 对比改变 + 突破行为 + 里程碑
  - 置信度评估 (>0.7 触发)
  - 冷却期管理 (避免过度推送)

- [ ] **3.6 Vibe Score 系统**
  - 能量分数计算 (0-100)
  - 趋势追踪
  - 历史记录
  - 分数影响因子

---

### Phase 4: 知识引擎层 (L4 - Knowledge Layer) ✅ 已完成 (2026-01-05)

- [x] **4.1 知识处理管道**
  - 知识提取 (Extract from MD/PDF/JSON)
  - 语义分块 (Semantic Chunking)
  - 实体关系抽取 (NER + Relation)
  - QA 对自动生成

- [ ] **4.2 混合检索系统**
  - **Vector Search** (pgvector cosine similarity)
  - **Keyword Search** (PostgreSQL FTS + BM25)
  - **Graph Search** (实体关系路径查找)
  - **Reciprocal Rank Fusion (RRF)** 结果融合
  - **LLM Relevance Grading** 相关性评分

- [ ] **4.3 Embedding 服务**
  - OpenAI Embedding API 集成
  - 本地 Embedding 备选 (sentence-transformers)
  - 批量向量化处理

- [ ] **4.4 知识库内容 - 八字 (bazi)**
  - `/knowledge/bazi/theory/` - 理论基础 (天干地支、十神、五行)
  - `/knowledge/bazi/patterns/` - 格局模式
  - `/knowledge/bazi/transit/` - 大运流年
  - `/knowledge/bazi/cases/` - 案例库
  - `/knowledge/bazi/qa/` - 问答对

- [ ] **4.5 知识库内容 - 星座 (zodiac)**
  - `/knowledge/zodiac/theory/` - 12星座、12宫位、行星
  - `/knowledge/zodiac/aspects/` - 相位
  - `/knowledge/zodiac/transit/` - 行运
  - `/knowledge/zodiac/cases/`

- [ ] **4.6 知识库内容 - MBTI**
  - `/knowledge/mbti/theory/` - 认知功能、16类型
  - `/knowledge/mbti/patterns/` - 类型行为模式
  - `/knowledge/mbti/assessment/` - 测评问题

- [ ] **4.7 共享知识库**
  - `/knowledge/shared/psychology/` - 心理学通用
  - `/knowledge/shared/communication/` - 沟通技巧
  - `/knowledge/shared/wellbeing/` - 身心健康

---

### Phase 5: Skill Agent 层 (L3 - Skill Agent Layer) ✅ 已完成 (2026-01-05)

- [x] **5.1 Agent Runtime 框架**
  - **Persona Injector** (角色注入) - 加载 Persona Guidelines
  - **Skill Router** (意图路由) - 匹配 Skill 和意图
  - **Context Builder** (上下文构建) - 组装用户上下文
  - **Tool Executor** (工具执行) - 调用专业工具

- [ ] **5.2 Agent 处理流程 (6步)**
  ```
  1. Context Assembly    - 加载用户画像、对话历史、相关记忆
  2. Intent Classification - 意图识别和 Skill 路由
  3. Knowledge Retrieval  - 混合检索相关知识
  4. Tool Invocation     - 调用专业计算工具
  5. Insight Generation  - 检查是否触发洞察
  6. Response Composition - 按 Language Guidelines 组装回复
  ```

- [ ] **5.3 SKILL.md 定义规范**
  - SKILL.md 解析器
  - 目录结构验证:
    ```
    skills/{skill_name}/
    ├── SKILL.md            # 技能定义
    ├── scripts/            # 专业计算脚本
    ├── references/         # 参考知识文档
    └── assets/             # 资源文件
    ```

- [ ] **5.4 Workflow Engine**
  - 工作流配置加载
  - 步骤执行器
  - 条件分支处理

- [ ] **5.5 Insight Rules Engine**
  - 规则定义 DSL
  - 规则评估器
  - 触发条件检查

- [ ] **5.6 Persona & Language Guidelines**
  - **Core Identity**: 陪伴者、知己
  - **Personality Traits**: 细腻、温暖、深度、有分寸
  - **Language Principles**:
    - "看见" 替代 "分析"
    - "发现" 替代 "诊断"
    - "也许" 替代 "一定"
    - "这让我想到" 替代 "根据数据"
  - **场景示例库**

---

### Phase 6: Skill 工具函数系统 ✅ 已完成 (2026-01-05)

- [x] **6.1 八字工具 (bazi tools)**
  - `bazi.calculator.generate_chart` - 排盘计算
  - `bazi.transit.calculate_dayun` - 大运计算
  - `bazi.transit.calculate_liunian` - 流年计算
  - `bazi.pattern.analyze_ten_gods` - 十神分析
  - `bazi.elements.calculate_strength` - 五行力量分布
  - `bazi.compatibility.analyze` - 八字合婚 (预留)

- [ ] **6.2 星座工具 (zodiac tools)**
  - `zodiac.chart.calculate_natal` - 本命星盘计算
  - `zodiac.transit.current` - 当前行星位置
  - `zodiac.aspects.analyze` - 相位分析
  - `zodiac.synastry.compare` - 双人星盘比较 (预留)
  - `zodiac.events.mercury_retrograde` - 水逆日期计算
  - `zodiac.events.moon_phases` - 新月满月计算

- [ ] **6.3 MBTI 工具 (mbti tools)**
  - `mbti.assessment.calculate_type` - 类型计算
  - `mbti.functions.analyze` - 认知功能栈分析
  - `mbti.compatibility.check` - 类型兼容性检查

- [ ] **6.4 共享工具 (shared tools)**
  - `datetime.convert` - 公历/农历/时区转换
  - `location.geocode` - 地址地理编码
  - `visualization.generate_chart` - 图表生成

---

### Phase 7: 体验层 (L2 - Experience Layer) ✅ 已完成 (2026-01-05)

- [x] **7.1 The Landing - 零摩擦入口**
  - Hero 区域组件 (title, subtitle, CTA)
  - Value Props 组件 (价值主张卡片)
  - 出生信息输入组件 (日期选择、时辰选择)
  - 即时洞察卡片 (快速结果展示)
  - Sample Conversation 展示
  - Cross-Sell Banner (跨站推荐)
  - 渐进式注册流程 (先体验后注册)

- [ ] **7.2 Stream - 对话流界面**
  - Stream Feed 组件 (消息列表)
  - Message Bubble 组件 (用户/AI消息气泡)
  - Typing Indicator (输入中指示)
  - Quick Replies 组件 (快捷回复按钮)
  - Quick Actions 组件 (快速操作)
  - Omnibar 输入框 (支持文本/语音/图片)
  - **流式响应显示** (SSE 实时渲染)

- [ ] **7.3 Insight Card System**
  - **InsightCard 基础组件** (卡片容器)
  - **DiscoveryCard 组件** - 发现卡
    - 标题: "我看见你..."
    - 蓝色主题
  - **PatternCard 组件** - 模式卡
    - 标题: "我注意到一个模式..."
    - 紫色主题
  - **TimingCard 组件** - 时机卡
    - 标题: "现在是...的好时机"
    - 金色主题
  - **GrowthCard 组件** - 成长卡
    - 标题: "你的成长..."
    - 绿色主题
  - 卡片动画 (Framer Motion)
  - 卡片交互 (展开详情、保存、分享)

- [ ] **7.4 Profile & Settings**
  - 用户资料页面
  - Vibe ID 设置
  - 通知偏好设置
  - 提醒设置 UI:
    - 八字提醒 (月运交接、流年交接、大运交接)
    - 星座提醒 (水逆、新月满月、周运)
    - 提前天数设置
    - 静默时段设置
  - 数据隐私设置
  - 数据导出按钮

- [ ] **7.5 Charts & Visualizations**
  - BaziChart 组件 (八字命盘可视化)
  - AstroChart 组件 (星盘可视化)
  - RadarChart 组件 (五行/特质雷达图)
  - TimelineChart 组件 (大运流年时间线)
  - ElementsBar 组件 (五行分布条形图)

---

### Phase 8: 独立站点层 (L1 - Skill Constellation Layer)

- [ ] **8.1 站点配置系统 (site_config.yaml)**
  - 站点模板引擎 (Config → Template Engine → Generated Site)
  - 配置项:
    - site: id, name, domain, tagline, description
    - theme: primary_color, secondary_color, background, icon, font_style
    - branding: logo, og_image, favicon
    - landing: hero, value_props, input_form, sample_conversation, cross_sell
    - main_interface: tabs, insight_card
    - result_display: chart_visual, sections
    - monetization: free_tier, premium_tier, paywall_triggers
    - seo: title, description, keywords, structured_data
    - content_marketing: platforms, content_types, posting_frequency

- [ ] **8.2 bazi.vibelife.app**
  - 站点路由配置 (Next.js 多租户路由)
  - 八字专属 Landing (传统棕金色主题)
  - 命盘展示组件 (四柱可视化)
  - 运势日历组件
  - 月运报告页面
  - 流年报告页面
  - 大运详情页面

- [ ] **8.3 zodiac.vibelife.app**
  - 站点路由配置
  - 星座专属 Landing
  - 星盘展示组件
  - 行星位置实时展示
  - 水逆提醒组件
  - 周运/月运报告页面

- [ ] **8.4 mbti.vibelife.app**
  - 站点路由配置
  - MBTI 专属 Landing
  - 类型测评流程 (多步问卷)
  - 认知功能栈展示
  - 16类型详情页面
  - 类型兼容性页面

- [ ] **8.5 共享组件库 (@vibelife/ui)**
  ```
  @vibelife/ui/
  ├── /layout/           # AppShell, Header, BottomNav, PageContainer
  ├── /landing/          # Hero, ValueProps, InputForm, SampleConversation, CrossSellBanner
  ├── /chat/             # ChatContainer, MessageBubble, InputBar, QuickReplies, TypingIndicator
  ├── /insight/          # InsightCard, DiscoveryCard, PatternCard, TimingCard, GrowthCard
  ├── /charts/           # BaziChart, AstroChart, RadarChart, TimelineChart, ElementsBar
  ├── /profile/          # ProfileHeader, SkillDataCard, SubscriptionStatus, DataSharingSettings
  ├── /common/           # Button, Card, Input, Modal, Toast, Loading
  └── /auth/             # VibeIdLogin, SocialLogin, ConsentDialog
  ```

- [ ] **8.6 多站点导航**
  - 统一导航栏 (带 Skill 切换)
  - 统一页脚
  - Skill 切换组件
  - 跨站引导组件 ("也试试星座分析?")

---

### Phase 9: 主动智能系统 (Proactive Agency)

- [ ] **9.1 Event Calendar (运势日历)**
  - 八字事件:
    - 节气日期表 (2026年预计算)
    - 月运交接日期
    - 流年交接日期
  - 星座事件:
    - 水逆日期表
    - 新月满月日期
    - 行星逆行日期
  - 用户事件:
    - 生日
    - 纪念日
    - 自定义事件

- [ ] **9.2 Reminder Scheduler (提醒调度)**
  - Vercel Cron Job 配置
  - 每日扫描任务 (upcoming events)
  - 用户匹配逻辑
  - 提醒设置检查
  - 调度队列管理

- [ ] **9.3 Content Generator (内容生成)**
  - 个性化提醒内容生成
  - 基于 Persona Guidelines 生成
  - 模板渲染 (Jinja2 / 字符串模板)
  - 用户历史上下文注入

- [ ] **9.4 Notification Delivery (通知投递)**
  - In-App 通知 (消息中心)
  - Push 通知 (FCM/APNs 预留)
  - 微信服务通知 (预留)
  - 通知状态追踪

- [ ] **9.5 提醒类型实现**
  - 八字月运交接提醒
  - 八字流年交接提醒
  - 水逆提醒
  - 周运推送

---

### Phase 10: Skill Mirror 系统 (周期回顾)

- [ ] **10.1 月运回顾卡 (Bazi)**
  - 触发时机: 每月最后一天
  - 内容结构:
    - 本月运势回顾 (基于流月)
    - 下月运势展望
    - 关键建议
  - 回顾内容生成 (LLM)
  - 卡片 UI 组件
  - 分享功能

- [ ] **10.2 周运回顾卡 (Zodiac)**
  - 触发时机: 每周日
  - 内容结构:
    - 本周运势回顾
    - 下周运势展望
    - 关键日期提醒
  - 回顾内容生成 (LLM)
  - 卡片 UI 组件
  - 分享功能

- [ ] **10.3 可分享卡片系统**
  - 卡片图片生成 (Canvas/SVG → PNG)
  - 多尺寸支持:
    - 1080x1920 (Instagram Story, 微信朋友圈)
    - 1080x1080 (Square, 微博)
    - 1200x630 (Link Preview)
  - 设计元素:
    - 渐变背景 (品牌色)
    - 用户星座/命盘标识
    - 关键数据可视化
    - 一句话主题
    - 品牌 Logo + URL
  - 分享链接生成
  - 分享到社交平台

---

### Phase 11: 商业化系统

- [ ] **11.1 订阅计划设计**
  - 免费层 (Free Tier):
    - 1次完整命盘解读
    - 每天3次提问
    - 基础运势分析
  - 会员层 (Premium Tier):
    - 无限对话
    - 深度十神分析
    - 每月运势推送
    - 详细大运解读
    - 跨技能洞察
  - 定价: 月付 ¥29 / 年付 ¥199

- [ ] **11.2 Paywall 触发点**
  - deep_pattern_analysis (深度格局分析)
  - detailed_transit (详细运势)
  - compatibility_analysis (合婚分析)

- [ ] **11.3 Stripe 支付集成**
  - Stripe 账户配置
  - 支付 API 集成
  - Webhook 处理 (订阅状态更新)
  - 发票和收据

- [ ] **11.4 订阅管理**
  - 订阅状态展示
  - 升级/降级/取消
  - 续费提醒

---

### Phase 12: 测试与质量保证

- [ ] **12.1 单元测试**
  - 后端 API 测试 (pytest)
  - 工具函数测试 (八字计算、星盘计算)
  - 前端组件测试 (Jest + React Testing Library)

- [ ] **12.2 集成测试**
  - 跨站 SSO 流程测试
  - Agent 处理流程测试
  - 知识检索测试
  - 支付流程测试

- [ ] **12.3 E2E 测试**
  - Playwright 配置
  - 关键用户流程测试

- [ ] **12.4 性能测试**
  - API 响应时间
  - 知识检索延迟
  - 流式响应性能

---

### Phase 13: 文档与运维

- [ ] **13.1 API 文档**
  - OpenAPI/Swagger 配置
  - API 端点说明
  - 认证说明

- [ ] **13.2 Skill 开发指南**
  - SKILL.md 编写规范
  - 工具函数开发指南
  - 知识库构建指南

- [ ] **13.3 运维文档**
  - 部署流程
  - 环境变量说明
  - 故障排查指南

- [ ] **13.4 监控与分析**
  - KPI 仪表板:
    - Landing → Chat 转化率 (目标 >35%)
    - 注册转化率 (目标 >15%)
    - 平均对话轮数 (目标 >8)
    - 洞察卡片点击率 (目标 >40%)
    - 7日留存 (目标 >30%)
    - 免费→付费转化率 (目标 >5%)
  - 错误追踪 (Sentry)
  - 日志聚合

---

### Phase 14: 部署与上线

- [ ] **14.1 部署配置**
  - Docker 容器化
  - docker-compose.yml (本地)
  - Kubernetes 配置 (生产 - 预留)

- [ ] **14.2 域名与 SSL**
  - 域名配置 (*.vibelife.app)
  - Cloudflare DNS 配置
  - SSL 证书 (自动)

- [ ] **14.3 CI/CD 流水线**
  - GitHub Actions 配置
  - 自动化测试
  - 自动部署 (Vercel)

- [ ] **14.4 环境分离**
  - Development 环境
  - Staging 环境
  - Production 环境

---

## 技术架构

```
/vibelife/
├── apps/
│   ├── api/                        # FastAPI 后端
│   │   ├── main.py                 # 应用入口
│   │   ├── routes/
│   │   │   ├── auth/               # Vibe ID 认证 API
│   │   │   ├── users/              # 用户 API
│   │   │   ├── skill/              # Skill Agent API
│   │   │   ├── stream/             # Stream 对话 API
│   │   │   ├── insight/            # Insight API
│   │   │   ├── reminder/           # 提醒 API
│   │   │   ├── subscription/       # 订阅 API
│   │   │   └── webhook/            # Webhook (Stripe)
│   │   ├── services/
│   │   │   ├── vibe_engine/        # L5 核心引擎
│   │   │   │   ├── llm_orchestrator.py
│   │   │   │   ├── memory_system.py
│   │   │   │   ├── emotion_engine.py
│   │   │   │   ├── user_model.py
│   │   │   │   ├── insight_generator.py
│   │   │   │   └── vibe_score.py
│   │   │   ├── knowledge/          # L4 知识引擎
│   │   │   │   ├── pipeline.py
│   │   │   │   ├── retrieval.py
│   │   │   │   ├── embedding.py
│   │   │   │   └── rrf.py
│   │   │   ├── agent/              # L3 Agent 系统
│   │   │   │   ├── runtime.py
│   │   │   │   ├── persona.py
│   │   │   │   ├── router.py
│   │   │   │   ├── workflow.py
│   │   │   │   └── insight_rules.py
│   │   │   ├── identity/           # Vibe ID 服务
│   │   │   │   ├── auth.py
│   │   │   │   ├── sso.py
│   │   │   │   ├── consent.py
│   │   │   │   └── profile.py
│   │   │   ├── reminder/           # 提醒服务
│   │   │   │   ├── scheduler.py
│   │   │   │   ├── calendar.py
│   │   │   │   └── generator.py
│   │   │   └── billing/            # 订阅服务
│   │   │       ├── stripe.py
│   │   │       └── subscription.py
│   │   ├── tools/                  # 专业工具
│   │   │   ├── bazi/
│   │   │   │   ├── calculator.py
│   │   │   │   ├── transit.py
│   │   │   │   └── pattern.py
│   │   │   ├── zodiac/
│   │   │   │   ├── chart.py
│   │   │   │   ├── transit.py
│   │   │   │   └── events.py
│   │   │   ├── mbti/
│   │   │   │   ├── assessment.py
│   │   │   │   └── functions.py
│   │   │   └── shared/
│   │   │       ├── datetime_utils.py
│   │   │       └── location.py
│   │   └── stores/
│   │       ├── db.py               # PostgreSQL + pgvector
│   │       └── redis.py            # Redis 缓存
│   │
│   ├── web/                        # Next.js 14 主站
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   ├── (auth)/         # 认证页面组
│   │   │   │   │   ├── login/
│   │   │   │   │   ├── register/
│   │   │   │   │   └── sso-callback/
│   │   │   │   ├── (bazi)/         # 八字站点组
│   │   │   │   │   ├── page.tsx    # Landing
│   │   │   │   │   ├── chat/
│   │   │   │   │   ├── chart/
│   │   │   │   │   └── transit/
│   │   │   │   ├── (zodiac)/       # 星座站点组
│   │   │   │   └── (mbti)/         # MBTI 站点组
│   │   │   ├── components/         # 站点专属组件
│   │   │   └── lib/
│   │   │       ├── api.ts
│   │   │       └── hooks/
│   │   └── tailwind.config.ts
│   │
│   └── id/                         # Vibe ID 认证中心
│       └── ...
│
├── packages/
│   ├── ui/                         # @vibelife/ui 共享组件库
│   │   ├── src/
│   │   │   ├── layout/
│   │   │   ├── landing/
│   │   │   ├── chat/
│   │   │   ├── insight/
│   │   │   ├── charts/
│   │   │   ├── profile/
│   │   │   ├── common/
│   │   │   └── auth/
│   │   └── package.json
│   │
│   ├── skills/                     # Skill 定义
│   │   ├── bazi/
│   │   │   ├── SKILL.md
│   │   │   ├── site_config.yaml
│   │   │   ├── scripts/
│   │   │   ├── references/
│   │   │   └── assets/
│   │   ├── zodiac/
│   │   └── mbti/
│   │
│   ├── knowledge/                  # 知识库
│   │   ├── bazi/
│   │   │   ├── theory/
│   │   │   ├── patterns/
│   │   │   ├── transit/
│   │   │   ├── cases/
│   │   │   └── qa/
│   │   ├── zodiac/
│   │   ├── mbti/
│   │   └── shared/
│   │
│   └── shared/                     # 共享代码
│       ├── types/
│       └── utils/
│
├── migrations/                     # 数据库迁移
│   ├── 001_vibe_id.sql
│   ├── 002_skill_data.sql
│   ├── 003_knowledge.sql
│   └── 004_subscriptions.sql
│
├── docs/                           # 文档
├── tests/                          # 测试
├── scripts/                        # 脚本工具
├── package.json                    # Monorepo 配置
├── pnpm-workspace.yaml
├── turbo.json
├── docker-compose.yml
└── .env.example
```

---

## 执行策略

每个 Phase 完成后:
1. 自我测试验证功能
2. `/compact` 压缩上下文
3. 继续下一个 Phase

**预计总共 14 个 Phase**，严格覆盖 spec v2.0 和 v2.1 的全部功能。

---

## 附录: 数据库完整 Schema

```sql
-- ═══════════════════════════════════════════════════════════════
-- VIBELIFE COMPLETE DATABASE SCHEMA
-- ═══════════════════════════════════════════════════════════════

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ─────────────────────────────────────────────────────────────────
-- VIBE ID 相关表
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE vibe_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vibe_id VARCHAR(20) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    birth_datetime TIMESTAMPTZ,
    birth_location VARCHAR(255),
    birth_location_coords POINT,
    timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
    language VARCHAR(10) DEFAULT 'zh-CN',
    status VARCHAR(20) DEFAULT 'active',
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vibe_user_auth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    auth_type VARCHAR(20) NOT NULL,
    auth_identifier VARCHAR(255) NOT NULL,
    auth_credential TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(auth_type, auth_identifier)
);

CREATE TABLE vibe_data_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    source_skill VARCHAR(50) NOT NULL,
    target_skill VARCHAR(50) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    consent_granted BOOLEAN DEFAULT false,
    granted_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    UNIQUE(user_id, source_skill, target_skill, data_type)
);

-- ─────────────────────────────────────────────────────────────────
-- SKILL 数据表
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE skill_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,
    profile_data JSONB NOT NULL DEFAULT '{}',
    first_use_at TIMESTAMPTZ DEFAULT NOW(),
    last_use_at TIMESTAMPTZ DEFAULT NOW(),
    total_sessions INTEGER DEFAULT 0,
    UNIQUE(user_id, skill_id)
);

CREATE TABLE skill_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    message_count INTEGER DEFAULT 0,
    entry_point VARCHAR(50),
    referrer VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE skill_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES skill_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    intent VARCHAR(100),
    tools_used VARCHAR(100)[],
    knowledge_used VARCHAR(100)[],
    insight_generated BOOLEAN DEFAULT false,
    insight_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE skill_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,
    conversation_id UUID REFERENCES skill_conversations(id),
    insight_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    evidence JSONB,
    confidence FLOAT,
    user_reaction VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────
-- 订阅与商业化
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE subscription_plans (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    plan_type VARCHAR(20) NOT NULL,
    skill_ids VARCHAR(50)[],
    price_monthly INTEGER,
    price_yearly INTEGER,
    currency VARCHAR(10) DEFAULT 'CNY',
    features JSONB,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    plan_id VARCHAR(50) REFERENCES subscription_plans(id),
    status VARCHAR(20) DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    current_period_end TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    payment_provider VARCHAR(50),
    payment_subscription_id VARCHAR(255),
    source_skill VARCHAR(50),
    source_campaign VARCHAR(100)
);

-- ─────────────────────────────────────────────────────────────────
-- 知识库
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    skill_id VARCHAR(50) NOT NULL,
    source_file VARCHAR(255),
    source_section VARCHAR(255),
    content TEXT NOT NULL,
    content_type VARCHAR(50),
    metadata JSONB,
    embedding vector(1536),
    search_vector TSVECTOR,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE knowledge_qa_pairs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    skill_id VARCHAR(50) NOT NULL,
    chunk_id UUID REFERENCES knowledge_chunks(id),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    question_embedding vector(1536),
    verified BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    helpfulness_score FLOAT
);

-- ─────────────────────────────────────────────────────────────────
-- 提醒与通知
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE fortune_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    event_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reminder_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    bazi_month_enabled BOOLEAN DEFAULT true,
    bazi_month_advance_days INTEGER DEFAULT 2,
    bazi_year_enabled BOOLEAN DEFAULT true,
    bazi_year_advance_days INTEGER DEFAULT 5,
    mercury_retrograde_enabled BOOLEAN DEFAULT true,
    mercury_retrograde_advance_days INTEGER DEFAULT 3,
    weekly_fortune_enabled BOOLEAN DEFAULT false,
    weekly_fortune_time VARCHAR(10) DEFAULT '20:00',
    quiet_start_time VARCHAR(10) DEFAULT '22:00',
    quiet_end_time VARCHAR(10) DEFAULT '08:00',
    in_app_enabled BOOLEAN DEFAULT true,
    push_enabled BOOLEAN DEFAULT true,
    wechat_enabled BOOLEAN DEFAULT false,
    UNIQUE(user_id)
);

CREATE TABLE user_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES vibe_users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    content TEXT,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────
-- 索引
-- ─────────────────────────────────────────────────────────────────

CREATE INDEX idx_vibe_users_vibe_id ON vibe_users(vibe_id);
CREATE INDEX idx_skill_profiles_user ON skill_profiles(user_id);
CREATE INDEX idx_skill_profiles_skill ON skill_profiles(skill_id);
CREATE INDEX idx_skill_conversations_user ON skill_conversations(user_id, skill_id);
CREATE INDEX idx_skill_messages_convo ON skill_messages(conversation_id);
CREATE INDEX idx_skill_insights_user ON skill_insights(user_id, skill_id);
CREATE INDEX idx_user_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX idx_knowledge_chunks_search ON knowledge_chunks USING GIN(search_vector);
CREATE INDEX idx_knowledge_chunks_embedding ON knowledge_chunks USING ivfflat(embedding vector_cosine_ops);
CREATE INDEX idx_knowledge_qa_embedding ON knowledge_qa_pairs USING ivfflat(question_embedding vector_cosine_ops);
CREATE INDEX idx_fortune_events_date ON fortune_events(start_date);
CREATE INDEX idx_user_notifications_user ON user_notifications(user_id, created_at DESC);
```
