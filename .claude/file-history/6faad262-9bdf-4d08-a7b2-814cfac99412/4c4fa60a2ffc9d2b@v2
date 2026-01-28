# VibeLife v3.0 重构计划

> **基于**: vibelife spec v3.0.md
> **重构策略**: 渐进式重构（保留可用组件，逐步替换）
> **数据库**: 全新 Schema
> **主力 LLM**: Zhipu GLM-4
> **部署环境**: 自有服务器

---

## 1. 项目结构重组

### 1.1 目录结构（保持 monorepo）

```
vibelife/
├── apps/
│   ├── api/                    # FastAPI 后端（重构）
│   │   ├── main.py
│   │   ├── routes/             # API 路由
│   │   │   ├── auth.py
│   │   │   ├── chat.py
│   │   │   ├── report.py       # 新增
│   │   │   ├── identity.py     # 新增
│   │   │   ├── relationship.py # 新增
│   │   │   ├── user.py
│   │   │   └── greeting.py     # 新增
│   │   ├── services/           # 业务服务
│   │   │   ├── vibe_engine/    # 核心 AI 引擎
│   │   │   │   ├── agent.py
│   │   │   │   ├── context.py
│   │   │   │   ├── portrait.py
│   │   │   │   └── llm.py
│   │   │   ├── skill/          # 技能服务
│   │   │   │   ├── bazi/
│   │   │   │   └── zodiac/
│   │   │   ├── report/         # 报告生成
│   │   │   ├── identity/       # Identity Prism
│   │   │   ├── relationship/   # 关系模拟器
│   │   │   ├── interview/      # AI 访谈
│   │   │   ├── extraction/     # 信息抽取
│   │   │   └── image/          # AI 生图
│   │   ├── models/             # Pydantic 模型
│   │   ├── stores/             # 数据访问层
│   │   └── tools/              # 计算工具
│   │       ├── bazi/
│   │       └── zodiac/
│   └── web/                    # Next.js 前端（重构）
│       └── src/
│           ├── app/            # App Router 页面
│           │   ├── page.tsx    # 首页 Landing
│           │   ├── chat/       # 对话页
│           │   ├── chart/      # 图表/报告页
│           │   ├── journey/    # 回顾/时间线
│           │   ├── me/         # 个人中心
│           │   ├── relationship/ # 关系模拟器
│           │   └── auth/       # 认证
│           ├── components/     # 组件库
│           │   ├── core/       # 核心视觉组件（保留）
│           │   ├── chat/       # 聊天组件
│           │   ├── identity/   # Identity Prism 组件
│           │   ├── chart/      # K线/图表组件
│           │   ├── relationship/ # 关系组件
│           │   ├── greeting/   # Daily Greeting
│           │   ├── insight/    # 洞察卡片
│           │   └── ui/         # 基础 UI
│           ├── lib/            # 工具库
│           └── stores/         # Zustand 状态
├── migrations/                 # 数据库迁移（全新）
├── knowledge/                  # 知识库（保留）
├── deploy/                     # 部署配置（保留）
└── docker-compose.yml          # Docker 配置（保留）
```

---

## 2. 数据库 Schema 重设计

### 2.1 核心表设计

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vibe_id VARCHAR(50) UNIQUE NOT NULL,  -- 用户唯一标识
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    name VARCHAR(100),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户 Profile (JSONB 存储，按 spec 4.4 设计)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    version INT DEFAULT 1,
    profile JSONB NOT NULL,  -- 完整 Profile JSON
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, version)
);

-- 对话会话
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill VARCHAR(20) NOT NULL,  -- bazi | zodiac
    voice_mode VARCHAR(20) DEFAULT 'warm',  -- warm | sarcastic
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 对话消息
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- user | assistant | system
    content TEXT NOT NULL,
    metadata JSONB,  -- 工具调用、抽取信息等
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 报告
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    skill VARCHAR(20) NOT NULL,
    report_type VARCHAR(20) NOT NULL,  -- brief | full
    content JSONB NOT NULL,  -- 报告结构化内容
    image_url TEXT,  -- AI 生图 URL
    is_paid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 关系分析
CREATE TABLE relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id UUID REFERENCES users(id),
    partner_id UUID REFERENCES users(id),  -- 可为空（单人模式）
    partner_info JSONB,  -- 对方基本信息（单人模式）
    skill VARCHAR(20) NOT NULL,
    analysis JSONB NOT NULL,
    share_token VARCHAR(100) UNIQUE,  -- Vibe Link
    privacy_level VARCHAR(20) DEFAULT 'private',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 知识库（向量存储）
CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill VARCHAR(20) NOT NULL,
    category VARCHAR(100),
    content TEXT NOT NULL,
    embedding vector(1024),  -- BGE-M3
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订阅
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plan VARCHAR(20) NOT NULL,  -- monthly | yearly
    status VARCHAR(20) NOT NULL,  -- active | canceled | expired
    started_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 支付记录
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_type VARCHAR(50) NOT NULL,  -- report | subscription
    product_id UUID,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'CNY',
    status VARCHAR(20) NOT NULL,
    provider VARCHAR(20),  -- stripe | wechat | alipay
    provider_payment_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_user_profiles_user ON user_profiles(user_id);
CREATE INDEX idx_conversations_user ON conversations(user_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_reports_user ON reports(user_id);
CREATE INDEX idx_knowledge_skill ON knowledge_chunks(skill);
CREATE INDEX idx_knowledge_embedding ON knowledge_chunks USING ivfflat (embedding vector_cosine_ops);
```

---

## 3. 核心 API 设计

### 3.1 Chat API

```
POST /api/v1/chat/stream
- 流式对话，SSE 响应
- 请求: { conversation_id?, skill, message, voice_mode? }
- 响应: SSE stream

POST /api/v1/chat/upload
- 文件上传 + AI 抽取
- 请求: multipart/form-data
- 响应: { extracted_info, profile_updates }
```

### 3.2 Report API

```
POST /api/v1/report/generate
- 生成报告
- 请求: { skill, level: brief|full }
- 响应: { report_id, content, preview_image? }

POST /api/v1/report/image
- 生成 AI 图像海报
- 请求: { report_id }
- 响应: { image_url }

GET /api/v1/report/{id}
- 获取报告详情
```

### 3.3 Identity API

```
GET /api/v1/identity/prism
- 获取 Identity Prism 三元数据
- 响应: { core, inner, outer }

GET /api/v1/identity/kline
- 获取人生 K 线数据
- 响应: { nodes: [...], current_position }
```

### 3.4 Relationship API

```
POST /api/v1/relationship/analyze
- 单人模式关系分析
- 请求: { partner_info: { birth_date?, zodiac?, animal? } }

POST /api/v1/relationship/invite
- 生成 Vibe Link 邀请
- 请求: { privacy_level }
- 响应: { invite_link, share_token }

POST /api/v1/relationship/accept/{token}
- 接受邀请
```

### 3.5 User API

```
GET /api/v1/user/profile
PUT /api/v1/user/profile
GET /api/v1/user/portrait
POST /api/v1/user/preference
```

### 3.6 Greeting API

```
GET /api/v1/greeting/daily
- 获取每日问候
- 响应: { greeting, fortune_hint, celestial_event? }
```

---

## 4. 前端页面与组件

### 4.1 路由结构

```
/                       # 首页 Landing
/chat                   # 对话页（含 Daily Greeting）
/chart                  # 图表/报告页
/chart/kline            # 人生 K 线
/journey                # 回顾/时间线
/me                     # 个人中心
/relationship           # 关系模拟器入口
/relationship/[id]      # 关系详情页
/auth/login             # 登录
/auth/register          # 注册
```

### 4.2 核心组件清单

| 组件 | 路径 | 状态 |
|------|------|------|
| LuminousPaper | components/core/ | ✅ 保留 |
| VibeGlyph | components/core/ | ✅ 保留 |
| BreathAura | components/core/ | ✅ 保留 |
| InsightCard | components/insight/ | ⚠️ 扩展 |
| InsightPanel | components/insight/ | ⚠️ 扩展 |
| ChatContainer | components/chat/ | ⚠️ 重构 |
| ChatInput | components/chat/ | ⚠️ 重构 |
| ChatMessage | components/chat/ | ⚠️ 重构 |
| VoiceToggle | components/ui/ | ❌ 新建 |
| TriToggle | components/ui/ | ❌ 新建 |
| IdentityPrism | components/identity/ | ❌ 新建 |
| KLineChart | components/chart/ | ❌ 新建 |
| RelationshipSimulator | components/relationship/ | ❌ 新建 |
| RelationshipCard | components/relationship/ | ❌ 新建 |
| DailyGreeting | components/greeting/ | ❌ 新建 |
| FileUploader | components/input/ | ❌ 新建 |
| InterviewModal | components/interview/ | ❌ 新建 |
| ReportViewer | components/report/ | ❌ 新建 |
| PaywallModal | components/billing/ | ❌ 新建 |
| BottomNav | components/layout/ | ❌ 新建 |
| SidePanel | components/layout/ | ❌ 新建 |

### 4.3 布局设计

**移动端**: BottomNav 四 Tab（Chat / Chart / Journey / Me）

**PC端**: 三栏布局
- 左侧导航栏 (64px/200px)
- 中间聊天主区域 (flex-1)
- 右侧 Insight Panel (360px)

---

## 5. 实施阶段

### Phase 1A: 基础重构 (Week 1-2)

#### Week 1: 核心基础

**后端任务:**
1. 创建新的数据库迁移 (001_v3_schema.sql)
2. 重构 Vibe Engine 核心
   - `services/vibe_engine/llm.py` - Zhipu GLM-4 集成
   - `services/vibe_engine/context.py` - Context 构建
   - `services/vibe_engine/portrait.py` - Portrait 管理
3. 重构 Chat API (流式响应)
4. 实现 User Profile CRUD

**前端任务:**
1. 重构页面路由结构
2. 保留并整合 core 组件
3. 重构 ChatContainer/ChatInput/ChatMessage
4. 实现 VoiceToggle (温暖/吐槽切换)

**删除:**
- 清理无关路由和页面
- 删除旧的 reminder/mirror 系统

#### Week 2: 信息采集系统

**后端任务:**
1. 实现 AI 访谈系统
   - `services/interview/interview_service.py`
   - 强制访谈触发逻辑
2. 实现文件上传 + AI 抽取
   - `services/extraction/extractor.py`
   - 支持图片 OCR + Vision LLM
3. Profile 更新与融合逻辑

**前端任务:**
1. 实现 FileUploader 组件
2. 实现 InterviewModal 组件
3. 信息采集表单组件

---

### Phase 1B: 核心功能 (Week 3-4)

#### Week 3: 报告系统

**后端任务:**
1. 报告生成服务
   - `services/report/generator.py`
   - 简版/完整版报告生成
   - 综合判断卷首语生成
2. Report API 实现
3. 八字/星座计算工具完善

**前端任务:**
1. ReportViewer 组件
2. 报告展示页面
3. 付费墙弹窗 (PaywallModal)

#### Week 4: Identity Prism & 人生K线

**后端任务:**
1. Identity Prism 生成服务
   - `services/identity/prism_generator.py`
   - Inner/Core/Outer 三元计算
2. 人生K线数据生成
   - `services/identity/kline_generator.py`
3. Identity API 实现

**前端任务:**
1. IdentityPrism 组件 (含 TriToggle)
2. KLineChart 组件 (Recharts/D3)
3. Chart 页面完善

---

### Phase 1C: 高级功能 (Week 5-6)

#### Week 5: 关系模拟器

**后端任务:**
1. 关系分析服务
   - `services/relationship/analyzer.py`
   - 传统输入模式
   - Vibe Link 双用户模式
2. Relationship API 实现

**前端任务:**
1. RelationshipSimulator 组件
2. RelationshipCard (可分享)
3. 关系页面

#### Week 6: Daily Greeting & 洞察系统

**后端任务:**
1. Daily Greeting 生成
   - `services/greeting/generator.py`
   - 节气/天象/运势
2. Greeting API
3. 洞察卡片系统完善

**前端任务:**
1. DailyGreeting 组件
2. InsightPanel 扩展
3. 布局优化（PC三栏/移动端BottomNav）

---

### Phase 1D: 商业化 (Week 7-8)

#### Week 7: AI 生图 & 支付

**后端任务:**
1. AI 生图集成
   - `services/image/gemini_imagen.py`
   - Nano Banana Prompt 模板
2. 支付集成
   - 微信支付/支付宝
3. 订阅管理

**前端任务:**
1. 海报预览/下载
2. 支付流程
3. 订阅管理页面

#### Week 8: 打磨 & 上线

**任务:**
1. 性能优化
2. 体验打磨
3. 埋点完善
4. 部署上线

---

## 6. 删除清单

### 需要删除的代码:

```
# 后端 - 删除
apps/api/routes/reminders.py       # 推送系统（Phase 2）
apps/api/routes/mirror.py          # 回顾系统（简化）
apps/api/services/reminder/        # 整个目录
apps/api/services/mirror/          # 整个目录
apps/api/services/billing/stripe_service.py  # 用国内支付替代
apps/api/workers/                   # Ingestion Worker（重新实现）

# 前端 - 删除
apps/web/src/app/(bazi)/           # 旧的 Bazi 路由组
apps/web/src/app/(zodiac)/         # 旧的 Zodiac 路由组
apps/web/src/app/bazi/             # 整个目录
apps/web/src/app/zodiac/           # 整个目录
apps/web/src/app/mbti/             # Phase 2 功能

# 数据库
migrations/001_init.sql            # 替换为新 Schema
migrations/002_knowledge_v2.sql    # 合并到新 Schema
migrations/003_user_portraits.sql  # 合并到新 Schema
```

### 保留的代码:

```
# 核心组件
apps/web/src/components/core/LuminousPaper.tsx
apps/web/src/components/core/VibeGlyph.tsx
apps/web/src/components/core/BreathAura.tsx

# 基础设施
docker-compose.yml
deploy/
k8s/
.github/workflows/

# 知识库
knowledge/bazi/
knowledge/zodiac/

# 工具
apps/api/tools/bazi/
apps/api/tools/zodiac/
```

---

## 7. 技术细节

### 7.1 LLM 集成 (Zhipu GLM-4)

```python
# services/vibe_engine/llm.py
from zhipuai import ZhipuAI

class LLMOrchestrator:
    def __init__(self):
        self.client = ZhipuAI(api_key=settings.ZHIPU_API_KEY)

    async def chat_stream(self, messages, system_prompt):
        response = self.client.chat.completions.create(
            model="glm-4-plus",
            messages=[{"role": "system", "content": system_prompt}] + messages,
            stream=True
        )
        for chunk in response:
            yield chunk.choices[0].delta.content
```

### 7.2 Context 构建

```python
# services/vibe_engine/context.py
def build_context(user_id, message, skill):
    # 1. System Prompt (含 Persona + 语气)
    system_prompt = load_system_prompt(skill, user.voice_mode)

    # 2. 话题相关 Profile
    topic = classify_topic(message)
    profile_sections = select_profile_sections(user.profile, topic)

    # 3. 知识库检索
    knowledge = retrieve_knowledge(skill, message, user.chart)

    # 4. 对话历史（原始）
    history = get_recent_messages(user_id, token_budget=8000)

    return {
        "system": system_prompt,
        "context": f"<user_profile>{profile_sections}</user_profile><knowledge>{knowledge}</knowledge>",
        "messages": history + [message]
    }
```

### 7.3 Profile 结构

按 spec 4.4 设计的完整 JSON Schema，存储在 PostgreSQL JSONB 字段中。

---

## 8. 关键文件修改列表

### 后端 (apps/api/)

| 文件 | 操作 | 说明 |
|------|------|------|
| main.py | 修改 | 更新路由注册 |
| routes/chat.py | 重构 | SSE 流式响应 |
| routes/report.py | 新建 | 报告 API |
| routes/identity.py | 新建 | Identity API |
| routes/relationship.py | 新建 | 关系 API |
| routes/greeting.py | 新建 | Greeting API |
| services/vibe_engine/llm.py | 重构 | Zhipu 集成 |
| services/vibe_engine/context.py | 重构 | Context 构建 |
| services/vibe_engine/portrait.py | 重构 | Portrait 管理 |
| services/report/generator.py | 新建 | 报告生成 |
| services/identity/prism.py | 新建 | Identity Prism |
| services/identity/kline.py | 新建 | K线生成 |
| services/relationship/analyzer.py | 新建 | 关系分析 |
| services/interview/interview.py | 新建 | AI 访谈 |
| services/extraction/extractor.py | 新建 | 信息抽取 |
| services/image/imagen.py | 新建 | AI 生图 |
| models/user.py | 重构 | 用户模型 |
| models/report.py | 新建 | 报告模型 |
| stores/db.py | 保留 | 数据库连接 |
| stores/user_repo.py | 重构 | 用户仓库 |

### 前端 (apps/web/src/)

| 文件 | 操作 | 说明 |
|------|------|------|
| app/page.tsx | 重构 | Landing 页 |
| app/chat/page.tsx | 重构 | 对话页 |
| app/chart/page.tsx | 新建 | 图表页 |
| app/chart/kline/page.tsx | 新建 | K线页 |
| app/journey/page.tsx | 新建 | 回顾页 |
| app/me/page.tsx | 新建 | 个人中心 |
| app/relationship/page.tsx | 新建 | 关系入口 |
| components/chat/ChatContainer.tsx | 重构 | 聊天容器 |
| components/chat/VoiceToggle.tsx | 新建 | 语气切换 |
| components/identity/IdentityPrism.tsx | 新建 | 三元视角 |
| components/identity/TriToggle.tsx | 新建 | 三档开关 |
| components/chart/KLineChart.tsx | 新建 | K线图表 |
| components/relationship/Simulator.tsx | 新建 | 关系模拟器 |
| components/greeting/DailyGreeting.tsx | 新建 | 每日问候 |
| components/input/FileUploader.tsx | 新建 | 文件上传 |
| components/interview/Modal.tsx | 新建 | 访谈弹窗 |
| components/report/Viewer.tsx | 新建 | 报告查看 |
| components/billing/Paywall.tsx | 新建 | 付费墙 |
| components/layout/BottomNav.tsx | 新建 | 移动端导航 |
| components/layout/SidePanel.tsx | 新建 | 侧边面板 |

---

## 9. 执行顺序

1. **数据库迁移** - 创建全新 Schema
2. **后端核心** - LLM 集成、Context 构建、Chat API
3. **前端基础** - 路由结构、Chat 组件
4. **信息采集** - AI 访谈、文件上传
5. **报告系统** - 生成、展示
6. **Identity** - Prism、K线
7. **关系模拟器** - 分析、分享
8. **Daily Greeting** - 生成、展示
9. **AI 生图** - Gemini Imagen
10. **支付** - 国内支付集成
11. **打磨上线**

---

*计划版本: 1.0*
*创建日期: 2026-01-07*
