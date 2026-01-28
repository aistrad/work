# VibeLife V6.8 系统架构文档

> Version: 6.8 | 2026-01-15
> 基于深度分析生成的系统架构文档

---

## 1. 顶层系统架构图

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           VibeLife V6.8 系统架构                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         Frontend Layer (Next.js 14)                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │   │
│  │  │ useVibeChat  │  │ CardRegistry │  │useToolSchema │  │AuthProvider │  │   │
│  │  │ (AI SDK 4.x) │  │ (动态卡片)    │  │ (工具Schema) │  │ (认证状态)   │  │   │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘  └─────────────┘  │   │
│  │         │                                                                │   │
│  │         │ SSE Stream (AI SDK Data Protocol)                              │   │
│  │         ▼                                                                │   │
│  │  ┌──────────────────────────────────────────────────────────────────┐   │   │
│  │  │              Next.js Rewrites Proxy                               │   │   │
│  │  │              /api/v1/* → Python API                               │   │   │
│  │  └──────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         Backend Layer (FastAPI)                          │   │
│  │                                                                          │   │
│  │  ┌────────────────────────────────────────────────────────────────┐     │   │
│  │  │                    API Routes Layer (精简)                      │     │   │
│  │  │                                                                 │     │   │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │     │   │
│  │  │  │ chat_v5.py   │  │ skills.py    │  │ 平台服务 (3个文件)    │  │     │   │
│  │  │  │              │  │              │  │                      │  │     │   │
│  │  │  │ CoreAgent    │  │ Skill        │  │ • account.py         │  │     │   │
│  │  │  │ 对话入口     │  │ Gateway      │  │   (auth+users+id)    │  │     │   │
│  │  │  │              │  │ (配置驱动)   │  │ • commerce.py        │  │     │   │
│  │  │  │ 独立路由     │  │ 统一路由     │  │   (pay+bill+entitle) │  │     │   │
│  │  │  │              │  │              │  │ • notifications.py   │  │     │   │
│  │  │  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │     │   │
│  │  └─────────┼─────────────────┼────────────────────┼───────────────┘     │   │
│  │            │                 │                    │                      │   │
│  │            ▼                 ▼                    ▼                      │   │
│  │  ┌────────────────────────────────────────────────────────────────┐     │   │
│  │  │                    Service Layer                                │     │   │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │     │   │
│  │  │  │  CoreAgent   │  │ SkillService │  │  Platform Services   │  │     │   │
│  │  │  │  (core.py)   │  │ Registry     │  │                      │  │     │   │
│  │  │  │              │  │ (自动发现)   │  │ • Identity           │  │     │   │
│  │  │  │ - Agentic    │  │              │  │ • Billing            │  │     │   │
│  │  │  │   Loop       │  │ - Bazi       │  │ • Entitlement        │  │     │   │
│  │  │  │ - Tool Use   │  │ - Zodiac     │  │ • Notification       │  │     │   │
│  │  │  │ - SOP引擎    │  │ - Tarot      │  │                      │  │     │   │
│  │  │  │              │  │ - Career     │  │                      │  │     │   │
│  │  │  └──────────────┘  └──────────────┘  └──────────────────────┘  │     │   │
│  │  └────────────────────────────────────────────────────────────────┘     │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         Skill Layer (DDD架构)                            │   │
│  │                                                                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───��─────────┐  ┌─────────────┐     │   │
│  │  │  skills/    │  │  skills/    │  │  skills/    │  │  skills/    │     │   │
│  │  │  bazi/      │  │  zodiac/    │  │  tarot/     │  │  career/    │     │   │
│  │  │             │  │             │  │             │  │             │     │   │
│  │  │ ├─SKILL.md  │  │ ├─SKILL.md  │  │ ├─SKILL.md  │  │ ├─SKILL.md  │     │   │
│  │  │ ├─services/ │  │ ├─services/ │  │ ├─tools/    │  │ ├─tools/    │     │   │
│  │  │ │ ├─api.py  │  │ │ ├─api.py  │  │ │ ├─yaml    │  │ │ ├─yaml    │     │   │
│  │  │ │ ├─calc.py │  │ │ ├─calc.py │  │ │ └─handler │  │ │ └─handler │     │   │
│  │  │ │ └─comp.py │  │ │ └─comp.py │  │ └─scenarios │  │ └─scenarios │     │   │
│  │  │ ├─tools/    │  │ ├─tools/    │  │             │  │             │     │   │
│  │  │ └─scenarios │  │ └─scenarios │  │             │  │             │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         Data Layer                                       │   │
│  │                                                                          │   │
│  │  ┌──────────────────────────┐  ┌──────────────────────────────────┐     │   │
│  │  │   PostgreSQL 16          │  │   Local Embedding                 │     │   │
│  │  │   (pgvector 扩展)        │  │   BAAI/bge-m3 (CUDA)              │     │   │
│  │  │                          │  │   1024维向量                       │     │   │
│  │  │   - unified_profiles     │  │                                   │     │   │
│  │  │   - conversations        │  │   用途:                           │     │   │
│  │  │   - messages             │  │   - 知识检索                       │     │   │
│  │  │   - knowledge_chunks     │  │   - 案例匹配                       │     │   │
│  │  │   - cases                │  │   - 场景路由                       │     │   │
│  │  │   - subscriptions        │  │                                   │     │   │
│  │  │   - payments             │  └──────────────────────────────────┘     │   │
│  │  └──────────────────────────┘                                           │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         External Services                                │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │   │
│  │  │ Zhipu    │  │ DeepSeek │  │ Claude   │  │ Gemini   │  │ Stripe   │  │   │
│  │  │ GLM-4.7  │  │ V3       │  │ Opus     │  │ 2.5      │  │ Payment  │  │   │
│  │  │ (主对话) │  │ (推理)   │  │ (备选)   │  │ (生图)   │  │          │  │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    Background Workers (不暴露 API)                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │   │
│  │  │ Proactive    │  │ Profile      │  │ Ingestion    │                   │   │
│  │  │ Worker       │  │ Extractor    │  │ Worker       │                   │   │
│  │  │ (主动推送)   │  │ (画像抽取)   │  │ (知识入库)   │                   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. API 路由架构

### 2.1 路由文件结构 (精简后)

```
routes/
├── chat_v5.py          # 对话入口 - CoreAgent (独立)
├── skills.py           # Skill Gateway - 配置驱动 (统一)
├── account.py          # 用户域 - auth + users + identity (合并)
├── commerce.py         # 支付域 - payment + billing + entitlement (合并)
├── notifications.py    # 通知域 (独立)
├── health.py           # 健康检查
└── tools.py            # 工具 Schema API

删除 (迁移到 skills.py):
├── bazi.py
├── zodiac.py
└── （已合并：fortune 路由迁入 skills.py）
```

### 2.2 API 端点设计

| 类型 | 端点 | 处理方式 | 说明 |
|------|------|----------|------|
| **对话** | `/chat/v5/stream` | CoreAgent | 独立路由，流式 SSE |
| **Skill** | `/skills/{skill_id}/{action}` | SkillServiceRegistry | 配置驱动，自动发现 |
| **用户** | `/account/*` | 代码驱动 | auth/users/identity 合并 |
| **支付** | `/commerce/*` | 代码驱动 | payment/billing/entitlement 合并 |
| **通知** | `/notifications/*` | 代码驱动 | 推送结果查询 |

### 2.3 Skill Gateway 详细设计

```
/api/v1/skills/{skill_id}/{action}

示例:
├── /skills/bazi/chart        # 八字命盘
├── /skills/bazi/fortune      # 八字运势
├── /skills/bazi/kline        # 运势K线
├── /skills/zodiac/chart      # 星盘
├── /skills/zodiac/transit    # 行运
├── /skills/tarot/draw        # 抽牌
└── /skills/career/assess     # 职业评估

新增 Skill 只需:
1. 创建 skills/{new_skill}/services/api.py
2. 添加 @skill_service 装饰的方法
无需修改 routes/ 或 main.py
```

### 2.4 SkillServiceRegistry 实现

```python
class SkillServiceRegistry:
    """统一 Skill 服务注册表 - 配置驱动"""
    
    _services: Dict[tuple, Callable] = {}  # {(skill_id, action): handler}
    
    @classmethod
    def initialize()                       # 自动发现所有 Skill
    @classmethod
    async def execute(skill_id, action, args, context) -> Dict
    @classmethod
    def list_services(skill_id) -> list

def skill_service(skill_id: str, action: str):
    """装饰器 - 自动注册服务"""
    
# 使用示例
@skill_service("bazi", "chart")
async def get_bazi_chart(args, context) -> Dict:
    return calculate_bazi(...)
```

---

## 3. 核心时序图

### 3.1 对话流程

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────┐
│ Browser │     │  Next.js    │     │ Python API  │     │  CoreAgent  │     │ LLM API │
└────┬────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └────┬────┘
     │                 │                   │                   │                 │
     │ 1. sendMessage  │                   │                   │                 │
     │ POST /chat/v5/  │                   │                   │                 │
     │ stream          │                   │                   │                 │
     │────────────────>│                   │                   │                 │
     │                 │ 2. rewrites       │                   │                 │
     │                 │──────────────────>│                   │                 │
     │                 │                   │ 3. 配额检查       │                 │
     │                 │                   │──────┐            │                 │
     │                 │                   │<─────┘            │                 │
     │                 │                   │ 4. 获取用户上下文 │                 │
     │                 │                   │──────┐            │                 │
     │                 │                   │<─────┘            │                 │
     │                 │                   │ 5. CoreAgent.run()│                 │
     │                 │                   │────��─────────────>│                 │
     │                 │                   │                   │ 6. LLM调用     │
     │                 │                   │                   │────────────────>│
     │                 │                   │                   │<────────────────│
     │                 │                   │                   │ 7. Tool执行?   │
     │                 │                   │                   │──────┐         │
     │                 │                   │                   │<─────┘         │
     │                 │                   │ 8. SSE事件流     │                 │
     │                 │                   │<──────────────────│                 │
     │                 │ 9. 转发SSE       │                   │                 │
     │                 │<──────────────────│                   │                 │
     │ 10. 渲染消息    │                   │                   │                 │
     │<────────────────│                   │                   │                 │
```

### 3.2 Skill 数据服务流程

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Browser │     │  Next.js    │     │ skills.py   │     │ SkillService│
└────┬────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
     │                 │                   │                   │
     │ 1. POST         │                   │                   │
     │ /skills/bazi/   │                   │                   │
     │ chart           │                   │                   │
     │────────────────>│                   │                   │
     │                 │ 2. rewrites       │                   │
     │                 │──────────────────>│                   │
     │                 │                   │ 3. Registry       │
     │                 │                   │    .execute()     │
     │                 │                   │──────────────────>│
     │                 │                   │                   │
     │                 │                   │                   │ 4. 计算命盘
     │                 │                   │                   │──────┐
     │                 │                   │                   │<─────┘
     │                 │                   │ 5. 返回结果       │
     │                 │                   │<──────────────────│
     │                 │ 6. JSON响应      │                   │
     │                 │<──────────────────│                   │
     │ 7. 渲染数据     │                   │                   │
     │<────────────────│                   │                   │
```

---

## 4. 关键程序和数据结构

### 4.1 CoreAgent (`services/agent/core.py`)

```python
class CoreAgent:
    """CoreAgent v6 - Agentic Loop 实现"""
    
    llm: LLMClient                    # LLM 客户端
    knowledge_repo: KnowledgeRepository  # 知识库
    max_iterations: int = 10          # 最大迭代次数
    
    async def run(message, context) -> AsyncGenerator[AgentEvent]
    async def _build_system_prompt(message, context) -> str
    async def _execute_tool(tool_name, tool_args, context) -> Dict

@dataclass
class AgentContext:
    user_id: str
    user_tier: str = "free"
    profile: Dict[str, Any]
    skill_data: Dict[str, Any]
    history: List[Dict[str, str]]
    skill: Optional[str]
    scenario: Optional[str]
    voice_mode: str = "warm"
```

### 4.2 ToolRegistry (`services/agent/tool_registry.py`)

```python
class UnifiedToolRegistry:
    """统一工具注册表 - 用于 CoreAgent Tool Use"""
    
    _tool_defs: Dict[str, ToolDef] = {}   # 工具定义
    _handlers: Dict[str, ToolHandler] = {} # 工具执行器
    
    @classmethod
    def get_tools_for_skill(skill_id) -> List[Dict]
    @classmethod
    async def execute(tool_name, args, context) -> Dict

def tool_handler(tool_name: str):
    """装饰器 - 自动注册工具"""
```

### 4.3 统一 Profile (`stores/unified_profile_repo.py`)

```python
class UnifiedProfileRepository:
    """统一 Profile 数据访问层"""
    
    # 读取
    async def get_profile(user_id) -> Dict
    async def get_birth_info(user_id) -> Dict
    async def get_skill_data(user_id, skill) -> Dict
    async def get_extracted(user_id) -> Dict
    
    # 写入 (使用 jsonb_set 局部更新)
    async def update_birth_info(user_id, birth_info)
    async def update_skill_data(user_id, skill, data)
    async def update_extracted(user_id, extracted)
```

---

## 5. 数据流

### 5.1 对话数据流

```
用户输入 → useVibeChat → /chat/v5/stream
                              │
                              ├─ [A] 配额检查 (QuotaTracker)
                              │
                              ├─ [B] CoreAgent 处理
                              │      ├─ 构建 context (profile + skill_data)
                              │      ├─ LLM 调用 (GLM/DeepSeek)
                              │      ├─ Tool calling + 执行
                              │      └─ 流式输出 SSE
                              │
                              └─ [C] 保存消息 + 记录配额
                              │
                              ▼
                    SSE 响应 (AI SDK Protocol)
                              │
                              ▼
                    Browser 渲染
```

### 5.2 Profile 数据流

```
用户对话 → messages 表
    ↓
profile_extractor (每日凌晨3点)
    ↓
unified_profiles.profile.extracted
    ↓
CoreAgent._build_system_prompt() → 传递完整 profile
    ↓
skill_loader.build_system_prompt() → 自动格式化注入
    ↓
LLM System Prompt (包含 facts/concerns/goals/pain_points/life_events)
```

---

## 6. 新增 Skill 流程

```
新增 Tarot Skill:

1. 创建目录结构
   skills/tarot/
   ├── SKILL.md              # Skill 定义
   ├── services/
   │   ├── __init__.py
   │   ├── api.py            # @skill_service 装饰的 API
   │   └── calculator.py     # 业务逻辑
   ├── tools/
   │   ├── tools.yaml        # 工具定义
   │   └── handlers.py       # @tool_handler 装饰的执行器
   └── scenarios/            # 场景定义

2. 无需修改:
   - routes/*.py
   - main.py
   
   SkillServiceRegistry 和 ToolRegistry 自动发现
```

---

## 7. 设计原则

| 原则 | 说明 |
|------|------|
| **对话独立** | chat-v5 保持独立，不与其他 API 混淆 |
| **Skill 配置驱动** | 新增 Skill 无需改路由，自动发现 |
| **平台代码驱动** | 认证/支付等安全敏感功能保持代码控制 |
| **后台不暴露** | Worker 进程不暴露 API，内部调度 |
| **Single Source of Truth** | 工具定义 YAML、模型配置 YAML |

---

## 8. 与旧架构对比

| 方面 | 旧架构 | 新架构 |
|------|--------|--------|
| 路由文件数 | 17+ 个 | 6 个 |
| 新增 Skill | 改 3 处 | 改 1 处 |
| Skill API | 分散 (bazi.py, zodiac.py...) | 统一 (skills.py) |
| 平台 API | 分散 (7个文件) | 合并 (3个文件) |
| 注册方式 | 手动 import | 自动发现 |
