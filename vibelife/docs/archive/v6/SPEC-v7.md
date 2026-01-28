# VibeLife V7 Architecture Specification

> Version: 7.0 | 2026-01-15
> 基于 V6.8 重构，统一 API 架构

---

## 1. 系统概述

VibeLife 是一个 AI 驱动的命理咨询平台，支持八字、星座、塔罗、职业咨询等多种技能。

### 1.1 核心特性

- **CoreAgent**: 基于 Anthropic Agent 设计原则的对话引擎
- **Skill System**: 配置驱动的技能系统，支持自动发现
- **Tool Calling**: 统一的工具注册和执行机制
- **Knowledge Base**: 基于 RAG 的知识检索系统

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| **Simplicity** | 保持简单，避免过度工程 |
| **Config-Driven** | Skill 层配置驱动，平台层代码驱动 |
| **Single Source of Truth** | 工具定义、模型配置等只有一个数据源 |
| **DDD** | 领域驱动设计，每个 Skill 独立管理自己的服务 |

---

## 2. 系统架构

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VibeLife V7 Architecture                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐         │
│  │   Browser    │────▶│   Next.js    │────▶│  Python API  │         │
│  │  (AI SDK 6)  │     │   (Proxy)    │     │  (FastAPI)   │         │
│  └──────────────┘     └──────────────┘     └──────────────┘         │
│                                                   │                  │
│                              ┌────────────────────┼────────────────┐ │
│                              │                    ▼                │ │
│                              │  ┌─────────────────────────────┐    │ │
│                              │  │         API Routes          │    │ │
│                              │  │  (7 routers, 49 endpoints)  │    │ │
│                              │  └─────────────────────────────┘    │ │
│                              │         │              │            │ │
│                              │    ┌────┴────┐   ┌────┴────┐       │ │
│                              │    ▼         ▼   ▼         ▼       │ │
│                              │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │ │
│                              │ │Chat │ │Skill│ │Acct │ │Comm │   │ │
│                              │ │ V5  │ │Gate │ │ ount│ │erce │   │ │
│                              │ └──┬──┘ └──┬──┘ └─────┘ └─────┘   │ │
│                              │    │       │                       │ │
│                              │    ▼       ▼                       │ │
│                              │ ┌─────────────────────────────┐    │ │
│                              │ │        CoreAgent            │    │ │
│                              │ │  (Agentic Loop + Tools)     │    │ │
│                              │ └─────────────────────────────┘    │ │
│                              │              │                     │ │
│                              │    ┌─────────┼─────────┐          │ │
│                              │    ▼         ▼         ▼          │ │
│                              │ ┌─────┐ ┌─────────┐ ┌─────────┐   │ │
│                              │ │Tool │ │  Skill  │ │Knowledge│   │ │
│                              │ │Reg. │ │ Service │ │   RAG   │   │ │
│                              │ └─────┘ │Registry │ └─────────┘   │ │
│                              │         └─────────┘               │ │
│                              │              │                     │ │
│                              │    ┌─────────┼─────────┐          │ │
│                              │    ▼         ▼         ▼          │ │
│                              │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │ │
│                              │ │Bazi │ │Zodiac│ │Tarot│ │Career│  │ │
│                              │ │Skill│ │Skill │ │Skill│ │Skill │  │ │
│                              │ └─────┘ └─────┘ └─────┘ └─────┘  │ │
│                              └───────────────────────────────────┘ │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                        Data Layer                             │   │
│  │  PostgreSQL (unified_profiles, messages, knowledge_chunks)    │   │
│  └──────────────────────────────────────────────────────────────┘   │
└────────────────────────────���────────────────────────────────────────┘
```

### 2.2 API 路由架构 (V7 重构)

```
routes/ (7 个核心路由文件)
├── health.py           # 健康检查 (3 routes)
├── chat_v5.py          # CoreAgent 对话入口 (2 routes)
├── tools.py            # 工具 Schema API (3 routes)
├── skills.py           # Skill Gateway - 配置驱动 (4 routes)
├── account.py          # 用户域 - 代码驱动 (17 routes)
├── commerce.py         # 支付域 - 代码驱动 (14 routes)
└── notifications.py    # 通知域 (4 routes)
```

### 2.3 API 端点映射

| 域 | 端点前缀 | 说明 |
|----|----------|------|
| **Chat** | `/api/v1/chat/v5/*` | CoreAgent 对话 |
| **Skills** | `/api/v1/skills/{skill}/{action}` | 统一 Skill Gateway |
| **Account** | `/api/v1/account/*` | 认证、用户、访客、身份 |
| **Commerce** | `/api/v1/commerce/*` | 支付、订阅、权益 |
| **Tools** | `/api/v1/tools/*` | 工具 Schema |
| **Notifications** | `/api/v1/notifications/*` | ��知管理 |

---

## 3. 核心组件

### 3.1 SkillServiceRegistry (配置驱动)

统一的 Skill 服务注册表，支持自动发现。

**文件**: `services/agent/skill_service_registry.py`

```python
# 使用 @skill_service 装饰器注册服务
@skill_service("bazi", "chart", description="计算八字命盘")
async def get_bazi_chart(args: Dict, context: ServiceContext) -> Dict:
    return {"chart": ...}

# 执行服务
result = await SkillServiceRegistry.execute("bazi", "chart", args, context)
```

**自动发现机制**:
- 扫描 `skills/{skill_id}/services/api.py`
- 自动注册带 `@skill_service` 装饰器的函数
- 无需修改 main.py 即可添加新 Skill

**当前注册的服务** (18 个):

| Skill | Services |
|-------|----------|
| bazi | chart, fortune, daily, kline, cycles |
| zodiac | chart, transit, daily, events, synastry |
| tarot | draw, spread, card, spreads |
| career | analysis, profile, match, assessments |

### 3.2 ToolRegistry (工具注册)

统一的工具注册表，支持自动发现。

**文件**: `services/agent/tool_registry.py`

```python
# 使用 @tool_handler 装饰器注册工具
@tool_handler("show_bazi_chart")
async def execute_show_bazi_chart(args: Dict, context: ToolContext) -> Dict:
    return {"cardType": "bazi_chart", ...}
```

**工具定义**: `skills/{skill}/tools/tools.yaml`
**工具执行器**: `skills/{skill}/tools/handlers.py`

### 3.3 CoreAgent (对话引擎)

基于 Anthropic Agent 设计原则的对话引擎。

**文件**: `services/agent/core.py`

**核心流程**:
```
用户消息 → CoreAgent.stream()
    ↓
1. 构建 System Prompt (注入 Skill + Profile)
2. LLM 调用 (支持 Tool Calling)
3. 工具执行 (ToolRegistry.execute)
4. 流式输出 (AI SDK 6 Data Stream Protocol)
```

### 3.4 Knowledge RAG

基于向量检索的知识库系统。

**文件**: `services/knowledge/repository.py`

**Embedding**: BAAI/bge-m3 (本地部署)

```python
# 检索知识
chunks = await KnowledgeRepository.search(
    query="甲木日主性格",
    skill_id="bazi",
    top_k=5
)
```

---

## 4. 目录结构

```
apps/api/
├── main.py                           # FastAPI 入口
├── config/
│   └── models.yaml                   # LLM 模型配置 (唯一数据源)
├── routes/                           # API 路由 (7 个文件)
│   ├── health.py
│   ├── chat_v5.py
│   ├── tools.py
│   ├── skills.py                     # Skill Gateway
│   ├── account.py                    # 用户域
│   ├── commerce.py                   # 支付域
│   └── notifications.py
├── services/
│   ├── agent/
│   │   ├── core.py                   # CoreAgent
│   │   ├── tool_registry.py          # ToolRegistry
│   │   ├── skill_service_registry.py # SkillServiceRegistry (V7 新增)
│   │   ├── skill_loader.py           # Skill 加载器
│   │   └── global_handlers.py        # 全局工具处理器
│   ├── knowledge/
│   │   ├── repository.py             # 知识库
│   │   └── embedding.py              # Embedding 服务
│   ├── billing/
│   │   ├── stripe_service.py         # Stripe 集成
│   │   └── subscription.py           # 订阅管理
│   ├── identity/
│   │   ├── auth.py                   # 认证服务
│   │   └── guest_session.py          # 访客会话
│   └── entitlement/
│       └── __init__.py               # 权益服务
├── skills/                           # Skill 定义 (DDD 架构)
│   ├── core/
│   │   ├── SKILL.md                  # Core Skill 定义
│   │   ├── tools/
│   │   │   ├── tools.yaml
│   │   │   └── handlers.py
│   │   └── reminders.yaml
│   ├── bazi/
│   │   ├── SKILL.md                  # Bazi Skill 定义
│   │   ├── services/                 # 领域服务 (V6.7 DDD)
│   │   │   ├── __init__.py
│   │   │   ├── api.py                # API 服务 (V7 新增)
│   │   │   ├── calculator.py
│   │   │   └── computer.py
│   │   ├── tools/
│   │   │   ├── tools.yaml
│   │   │   └── handlers.py
│   │   └── scenarios/
│   ├── zodiac/
│   │   ├── SKILL.md
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── api.py                # API 服务 (V7 新增)
│   │   │   ├── calculator.py
│   │   │   ├── computer.py
│   │   │   └── events.py
│   │   ├── tools/
│   │   └── scenarios/
│   ├── tarot/
│   │   ├── SKILL.md
│   │   ├── services/
│   │   │   └── api.py                # API 服务 (V7 新增)
│   │   └── tools/
│   └── career/
│       ├── SKILL.md
│       ├── services/
│       │   └── api.py                # API 服务 (V7 新增)
│       └── tools/
├── stores/                           # 数据访问层
│   ├── db.py                         # 数据库连接
│   ├── unified_profile_repo.py       # 用户档案
│   └── payment_repo.py               # 支付记录
└── workers/                          # 后台任务
    ├── ingestion.py                  # 知识入库
    └── profile_extractor.py          # Profile 抽取
```

---

## 5. 配置说明

### 5.1 环境变量

```bash
# 数据库
DATABASE_URL=postgresql://postgres:password@127.0.0.1:8224/vibelife

# LLM API Keys
DEEPSEEK_API_KEY=sk-xxx
GLM_API_KEY=xxx
ANTHROPIC_API_KEY=sk-ant-xxx

# Stripe
STRIPE_SECRET_KEY=sk_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# 应用配置
VIBELIFE_API_PORT=8000
VIBELIFE_CORS_ORIGINS=http://localhost:3000
VIBELIFE_WORKER_ENABLED=1
```

### 5.2 LLM 模型配置

**唯一配置源**: `config/models.yaml`

```yaml
providers:
  deepseek:
    base_url: https://api.deepseek.com/anthropic
    api_key_env: DEEPSEEK_API_KEY
    is_anthropic_compatible: true
  glm:
    base_url: https://open.bigmodel.cn/api/anthropic/v1
    api_key_env: GLM_API_KEY
    is_anthropic_compatible: true

routing:
  chat:
    free: deepseek-chat
    paid: deepseek-chat
    fallback: [glm-4.7]
```

### 5.3 数据库配置

```
PostgreSQL 16
- 主机: 127.0.0.1
- 端口: 8224
- 数据库: vibelife
- 连接串: postgresql://postgres:Ak4_9lScd-69WX@127.0.0.1:8224/vibelife
```

---

## 6. 开发指南

### 6.1 添加新 Skill

1. **创建目录结构**:
```bash
mkdir -p skills/newskill/{services,tools,scenarios}
```

2. **创建 SKILL.md**:
```markdown
# NewSkill

## 角色定义
你是一个专业的 XXX 顾问...

## 工具列表
- show_xxx_result: 展示结果
```

3. **创建 API 服务** (`skills/newskill/services/api.py`):
```python
from services.agent.skill_service_registry import skill_service, ServiceContext

@skill_service("newskill", "action", description="执行操作")
async def newskill_action(args: Dict, context: ServiceContext) -> Dict:
    return {"status": "success", "data": ...}
```

4. **创建工具** (`skills/newskill/tools/`):
```yaml
# tools.yaml
- name: show_xxx_result
  description: 展示 XXX 结果
  parameters:
    type: object
    properties:
      data:
        type: object
```

```python
# handlers.py
@tool_handler("show_xxx_result")
async def execute_show_xxx_result(args: Dict, context: ToolContext) -> Dict:
    return {"cardType": "xxx_result", **args}
```

5. **重启服务** - 自动发现新 Skill

### 6.2 添加新 API 端点

**Skill 相关**: 使用 `@skill_service` 装饰器，自动注册到 Skill Gateway

**平台相关**: 直接在 `routes/account.py` 或 `routes/commerce.py` 添加

### 6.3 测试

```bash
# 启动测试环境
./scripts/start-test.sh

# 测试 API
curl http://127.0.0.1:8100/api/v1/skills/bazi/chart \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"args": {"birth_date": "1990-01-01"}}'

# 测试 Skill 服务
python -c "
from services.agent.skill_service_registry import SkillServiceRegistry
SkillServiceRegistry.initialize()
print(SkillServiceRegistry.list_services())
"
```

---

## 7. 运维指南

### 7.1 部署环境

| 环境 | API 端口 | Web 端口 | 说明 |
|------|----------|----------|------|
| 测试 (aiscend) | 8100 | 8232 | 开发测试 |
| 生产 (vibelife) | 8000 | 3000 | 正式环境 |

### 7.2 启动服务

```bash
# 测试环境
cd /home/aiscend/work/vibelife/apps/api
./start_api.sh

# 生产环境
cd /home/vibelife/vibelife/apps/api
./start_api.sh
```

### 7.3 定时任务

```cron
# Profile 抽取 (每日凌晨3点)
0 3 * * * cd /home/vibelife/vibelife/apps/api && python workers/profile_extractor.py

# 知识库更新 (每周一凌晨4点)
0 4 * * 1 cd /home/vibelife/vibelife/apps/api && python scripts/build_knowledge.py
```

### 7.4 监控检查

```bash
# 健康检查
curl http://127.0.0.1:8000/health

# 查看日志
tail -f /tmp/vibelife/logs/api_requests.log

# 检查服务状态
python -c "
from main import app
print(f'Routes: {len(app.routes)}')
from services.agent.skill_service_registry import SkillServiceRegistry
SkillServiceRegistry.initialize()
print(f'Skills: {SkillServiceRegistry.list_skills()}')
print(f'Services: {len(SkillServiceRegistry.list_services())}')
"
```

---

## 8. API 参考

### 8.1 Skill Gateway

**列出所有 Skill**:
```
GET /api/v1/skills
Response: {"skills": ["bazi", "zodiac", "tarot", "career"]}
```

**列出 Skill 服务**:
```
GET /api/v1/skills/{skill_id}/services
Response: {"skill_id": "bazi", "services": [...]}
```

**执行 Skill 服务**:
```
POST /api/v1/skills/{skill_id}/{action}
Body: {"args": {...}}
Response: {"status": "success", ...}
```

### 8.2 Account API

| 端点 | 方法 | 说明 |
|------|------|------|
| `/account/auth/register` | POST | 注册 |
| `/account/auth/login` | POST | 登录 |
| `/account/auth/refresh` | POST | 刷新 Token |
| `/account/auth/logout` | POST | 登出 |
| `/account/auth/me` | GET | 当前用户 |
| `/account/auth/oauth/google` | POST | Google 登录 |
| `/account/auth/oauth/apple` | POST | Apple 登录 |
| `/account/profile` | GET/PUT | 用户资料 |
| `/account/guest/session` | POST/GET | 访客会话 |
| `/account/identity/prism` | GET | 身份棱镜 |

### 8.3 Commerce API

| 端点 | 方法 | 说明 |
|------|------|------|
| `/commerce/payment/config` | GET | Stripe 配置 |
| `/commerce/payment/pricing` | GET | 定价信息 |
| `/commerce/payment/create-checkout` | POST | 创建支付 |
| `/commerce/payment/verify` | POST | 验证支付 |
| `/commerce/payment/webhook` | POST | Stripe Webhook |
| `/commerce/billing/plans` | GET | 订阅计划 |
| `/commerce/billing/subscription/me` | GET | 我的订阅 |
| `/commerce/entitlement` | GET | 权益信息 |
| `/commerce/entitlement/can-chat` | GET | 检查对话权限 |

### 8.4 Chat API

```
POST /api/v1/chat/v5/stream
Headers: Authorization: Bearer {token}
Body: {
  "messages": [{"role": "user", "content": "..."}],
  "skill": "bazi",
  "voice_mode": "warm"
}
Response: SSE (AI SDK 6 Data Stream Protocol)
```

---

## 9. 变更日志

### V7.1 (2026-01-18)

**LLM 自动路由**:
- 前端统一入口不再传递 `skillId`，由 LLM 根据用户消息自动选择 Skill
- CoreAgent 通过 `use_skill` 工具让 LLM 决定使用哪个 Skill
- 每个 Skill 在 SKILL.md 中定义触发词，用于构建 `use_skill` 工具描述

**ShowCard Fallback 机制**:
- 实现"专用优先，通用兜底"的卡片渲染策略
- 新增 `fallbackType` 属性，支持显式指定降级类型
- 智能推断逻辑：根据 data/items/nodes/events/fields 等属性自动选择通用视图
- 通用视图类型：list, tree, table, timeline, form, select, chart, progress, counter, modal, toast, custom

**前端改动**:
- `useVibeChat.ts`: skillId 改为可选参数，不传时让 LLM 自动路由
- `ChatContainer.tsx`: 新增 displaySkill 用于 UI 展示，区分路由和展示
- `chat/page.tsx`: 主聊天页面使用自动路由模式
- `ShowCard.tsx`: 实现 fallback 机制，优先使用注册的专用组件，不存在时降级到通用视图

**架构优化**:
- 减少前端开发成本：新 Skill 无需开发专用卡片即可使用通用视图
- 渐进式增强：可随时为特定 cardType 添加专用组件覆盖通用视图

---

### V7.0 (2026-01-15)

**重大变更**:
- 创建 `SkillServiceRegistry` 实现 Skill 服务自动发现
- 创建统一 Skill Gateway (`/api/v1/skills/{skill_id}/{action}`)
- 合并 auth + users + identity + guest → `account.py`
- 合并 payment + billing + entitlement → `commerce.py`
- 删除 16 个旧路由文件，路由文件从 25 个精简到 9 个

**新增文件**:
- `services/agent/skill_service_registry.py`
- `routes/skills.py`
- `routes/account.py`
- `routes/commerce.py`
- `skills/*/services/api.py` (4 个 Skill)

**删除文件**:
- `routes/auth.py`
- `routes/users.py`
- `routes/identity.py`
- `routes/guest.py`
- `routes/payment.py`
- `routes/billing.py`
- `routes/entitlement.py`
- `routes/bazi.py`
- `routes/zodiac.py`
（已删除）
- `routes/onboarding.py`
- `routes/relationship.py`
- `routes/report.py`
- `routes/memories.py`
- `routes/chat.py`
- `routes/context.py`

---

## 10. 附录

### 10.1 AI SDK 6 Data Stream Protocol

后端 SSE 输出格式:
```
0:"text chunk"           # 文本块
9:{"toolCallId":"..."}   # 工具调用开始
a:{"toolCallId":"..."}   # 工具调用结果
e:{"finishReason":"..."}  # 完成
d:{"finishReason":"..."}  # 结束
```

### 10.2 Anthropic 兼容 API

| Provider | Base URL | 模型 |
|----------|----------|------|
| DeepSeek | `https://api.deepseek.com/anthropic` | deepseek-chat |
| GLM | `https://open.bigmodel.cn/api/anthropic/v1` | glm-4.7 |

### 10.3 数据库表结构

**核心表**:
- `users`: 用户基本信息
- `unified_profiles`: 用户档案 (profile + skill_data)
- `messages`: 对话消息
- `conversations`: 对话会话
- `knowledge_chunks`: 知识块
- `subscriptions`: 订阅记录
- `payments`: 支付记录
