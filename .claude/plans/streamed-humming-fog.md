# Vibelife 项目架构解析

## 概述

Vibelife 是一个基于 AI 的个性化服务平台，支持多个"技能模块"（bazi八字、zodiac星座、mbti人格）。采用 **Hot & Cold Memory 双层记忆架构** 实现个性化用户体验。

---

## 1. 用户 Profile 数据结构

### 1.1 核心用户表 `vibe_users`

**文件位置:** [apps/api/models/user.py](vibelife/apps/api/models/user.py)

```python
class VibeUser:
    id: UUID                      # 主键
    vibe_id: str                  # 用户友好ID (格式: VB-A1B2C3D4)
    display_name: Optional[str]   # 显示名称
    avatar_url: Optional[str]     # 头像
    birth_datetime: datetime      # 出生时间 (核心数据)
    birth_location: str           # 出生地点
    timezone: str                 # 时区 (默认 Asia/Shanghai)
    language: str                 # 语言 (默认 zh-CN)
    status: str                   # 账户状态
    email_verified: bool
    phone_verified: bool
    created_at, updated_at: datetime
```

### 1.2 技能专属数据 `skill_profiles`

**文件位置:** [apps/api/models/skill.py](vibelife/apps/api/models/skill.py)

```python
class SkillProfile:
    id: UUID
    user_id: UUID                 # 关联用户
    skill_id: str                 # 技能标识: bazi/zodiac/mbti
    profile_data: Dict[str, Any]  # JSONB 灵活存储技能专属数据
    first_use_at: datetime
    last_use_at: datetime
    total_sessions: int           # 使用次数统计
```

**各技能的 profile_data 示例:**
- **bazi**: `{"bazi_chart": {...}, "day_master": "甲木", "palace": "偏印格"}`
- **zodiac**: `{"sun_sign": "Pisces", "rising_sign": "Libra", "moon_sign": "Taurus"}`
- **mbti**: `{"mbti_type": "INFP", "preferences": {...}}`

### 1.3 认证方式 `vibe_user_auth`

支持多种登录方式：email、phone、wechat、apple、google

### 1.4 数据授权 `vibe_data_consents`

跨技能数据共享的细粒度权限控制。

---

## 2. Knowledge Module 数据结构

### 2.1 知识来源

**目录结构:**
```
/knowledge/
├── bazi/           # 八字命理知识 (如：十神基础.md)
├── zodiac/         # 西方占星知识
└── mbti/           # MBTI人格知识
```

### 2.2 知识文档表 `knowledge_documents`

**文件位置:** [migrations/002_knowledge_v2.sql](vibelife/migrations/002_knowledge_v2.sql)

```sql
CREATE TABLE knowledge_documents (
    id UUID PRIMARY KEY,
    skill_id TEXT NOT NULL,        -- bazi/zodiac/mbti
    filename TEXT,
    file_path TEXT,
    file_hash TEXT,                -- MD5 变更检测
    file_type TEXT,                -- pdf/md/txt/epub/docx/html
    content_md TEXT,               -- 转换后的 Markdown
    status TEXT,                   -- pending/processing/completed/failed
    chunk_count INT
);
```

### 2.3 知识块表 `knowledge_chunks_v2`

```sql
CREATE TABLE knowledge_chunks_v2 (
    id UUID PRIMARY KEY,
    document_id UUID,
    skill_id TEXT NOT NULL,
    chunk_index INT,
    content TEXT NOT NULL,
    content_type TEXT,             -- knowledge/qa/summary

    -- 层级路径
    section_path TEXT[],           -- ['十神', '比肩', '特点']
    section_title TEXT,

    -- 元数据
    metadata JSONB,
    has_table BOOLEAN,
    has_list BOOLEAN,
    char_count INT,

    -- 搜索优化
    search_text_preprocessed TEXT,  -- Jieba 分词后文本
    search_vector TSVECTOR,         -- PostgreSQL 全文搜索
    embedding vector(3072)          -- Gemini 向量嵌入
);
```

### 2.4 智能分块算法

**文件位置:** [apps/api/workers/chunker.py](vibelife/apps/api/workers/chunker.py)

**三阶段算法:**
1. **结构解析** - 解析 Markdown 标题层级
2. **智能合并** - 合并 <100 字的小节
3. **安全切分** - 在句子边界切分 >1200 字的块，保留 80 字重叠

---

## 3. 用户记忆系统 (Hot & Cold Memory)

### 3.1 Hot Memory: 用户画像 `user_portraits`

**文件位置:** [apps/api/services/vibe_engine/portrait_service.py](vibelife/apps/api/services/vibe_engine/portrait_service.py)

```sql
CREATE TABLE user_portraits (
    id UUID PRIMARY KEY,
    user_id UUID,
    skill_id TEXT,
    portrait_text TEXT,           -- 自然语言描述
    based_on_messages INT,        -- 基于多少条消息
    last_message_id UUID,
    generated_at TIMESTAMPTZ,
    version INT                   -- 乐观锁版本
);
```

**画像结构 (4 部分):**
- 📌 **Facts** - 确定事实 (只增不删)
- 🌊 **State** - 当前情绪/状态
- 💡 **Preferences** - 沟通偏好
- 🎯 **Focus** - 当前关注点

**更新机制:** 每 10 条消息触发后台更新

### 3.2 Cold Memory: 洞察 `skill_insights`

**文件位置:** [apps/api/services/vibe_engine/insight_generator.py](vibelife/apps/api/services/vibe_engine/insight_generator.py)

```python
class Insight:
    id: UUID
    user_id: UUID
    skill_id: str
    insight_type: str             # discovery/pattern/timing/growth
    title: str
    content: str
    evidence: Dict
    confidence: float
    embedding: vector             # 用于跨技能语义检索
    user_reaction: str            # helpful/not_helpful/saved
```

**4 种洞察类型及冷却时间:**
| 类型 | 含义 | 冷却 |
|------|------|------|
| DISCOVERY | 新发现的用户特征 | 24h |
| PATTERN | 重复行为模式 | 72h |
| TIMING | 时机建议 | 48h |
| GROWTH | 成长突破 | 168h |

**LLM 驱动判断:** 使用 LLM 判断对话是否包含有价值的洞察，而非规则匹配

---

## 4. Agent 运行机制

### 4.1 核心入口: AgentRuntime

**文件位置:** [apps/api/services/agent/runtime.py](vibelife/apps/api/services/agent/runtime.py)

**处理流水线 (7 阶段):**

```
用户消息
    ↓
1. Context Assembly - 组装上下文
   ├─ Hot Memory (用户画像)
   ├─ Buffer (最近 10 条对话)
   ├─ Cold Memory (相关洞察，支持跨技能)
   └─ Knowledge (RAG 知识检索)
    ↓
2. Intent Classification - 意图分类 (SkillRouter)
    ↓
3. Knowledge Retrieval - 知识检索
    ↓
4. Tool Invocation - 调用技能工具
    ↓
5. Emotion Analysis - 情绪分析
    ↓
6. Response Generation - 生成回复
    ↓
7. Background Tasks - 后台任务 (异步)
   ├─ Portrait Update (每10条)
   └─ Insight Generation (LLM判断)
```

### 4.2 意图分类: SkillRouter

**文件位置:** [apps/api/services/agent/router.py](vibelife/apps/api/services/agent/router.py)

**40+ 意图类型:**
- 通用: GREETING, FAREWELL, HELP, UNKNOWN
- 八字: BAZI_CHART, BAZI_DAYUN, BAZI_LIUNIAN, BAZI_PERSONALITY...
- 星座: ZODIAC_NATAL, ZODIAC_TRANSIT, ZODIAC_WEEKLY...
- MBTI: MBTI_TEST, MBTI_TYPE, MBTI_FUNCTIONS...
- 跨技能: EMOTIONAL, ADVICE, CURIOSITY

### 4.3 System Prompt 构建

**组装顺序:**
1. **Persona** - 角色定义
2. **Hot Memory** - 用户画像
3. **Cold Memory** - 相关历史洞察 (跨技能)
4. **Knowledge** - RAG 知识上下文
5. **User Context** - 基础信息 (姓名、生辰)
6. **Guidelines** - 情境指导

---

## 5. 数据更新机制

### 5.1 实时更新

| 数据 | 触发时机 | 存储位置 |
|------|----------|----------|
| 消息 | 每次对话 | skill_messages |
| 对话 | 新会话开始 | skill_conversations |
| Profile | 用户信息变更 | skill_profiles |

### 5.2 异步后台更新

| 数据 | 触发条件 | 执行方式 |
|------|----------|----------|
| 用户画像 | 每 10 条消息 | asyncio.create_task() |
| 洞察生成 | LLM 判断有价值时 | asyncio.create_task() |

### 5.3 知识同步

**文件位置:** [apps/api/scripts/sync_knowledge.py](vibelife/apps/api/scripts/sync_knowledge.py)

- 每日 4:00 AM 扫描 /knowledge/ 目录
- MD5 哈希检测文件变更
- 新/变更文件 → pending → 分块 → 嵌入 → completed

---

## 6. 检索机制

### 6.1 混合检索 (Hybrid Search)

**文件位置:** [apps/api/services/knowledge/retrieval.py](vibelife/apps/api/services/knowledge/retrieval.py)

```
用户查询
    ↓
├─ Jieba 分词 (中文优化)
├─ Gemini 向量嵌入 (1536维)
    ↓
├─ 向量检索 (70% 权重)
├─ 全文检索 (30% 权重)
    ↓
└─ RRF 融合排序
   score = 0.7/(60+rank_vec) + 0.3/(60+rank_fts)
```

### 6.2 跨技能洞察检索

Cold Memory 支持跨技能语义检索：
- 在 bazi 对话中可检索到 mbti 的相关洞察
- 阈值: 0.70 相似度

---

## 7. 关键文件路径

| 模块 | 文件路径 |
|------|----------|
| 用户模型 | vibelife/apps/api/models/user.py |
| 技能模型 | vibelife/apps/api/models/skill.py |
| 知识模型 | vibelife/apps/api/models/knowledge.py |
| Agent 运行时 | vibelife/apps/api/services/agent/runtime.py |
| 意图路由 | vibelife/apps/api/services/agent/router.py |
| 画像服务 | vibelife/apps/api/services/vibe_engine/portrait_service.py |
| 洞察生成 | vibelife/apps/api/services/vibe_engine/insight_generator.py |
| 知识检索 | vibelife/apps/api/services/knowledge/retrieval.py |
| 智能分块 | vibelife/apps/api/workers/chunker.py |
| DB Schema | vibelife/migrations/001_init.sql, 002_knowledge_v2.sql, 003_user_portraits.sql |
| 设计文档 | vibelife/docs/user-data-context-design.md |

---

## 8. 架构图示

```
┌─────────────────────────────────────────────────────────┐
│                      用户层                              │
│  vibe_users ─┬─ skill_profiles (bazi/zodiac/mbti)       │
│              ├─ vibe_user_auth (多种登录)                │
│              └─ vibe_data_consents (数据授权)            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    记忆层 (Memory)                       │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Hot Memory    │  │   Cold Memory   │              │
│  │ (user_portraits)│  │ (skill_insights)│              │
│  │ 自然语言画像     │  │ 向量化洞察       │              │
│  │ 每10条消息更新   │  │ LLM判断生成      │              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  知识层 (Knowledge)                      │
│  knowledge_documents → knowledge_chunks_v2              │
│  ├─ bazi/十神基础.md                                    │
│  ├─ zodiac/*.md                                         │
│  └─ mbti/*.md                                           │
│  Jieba分词 + Gemini向量 + 混合检索                       │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Agent 层 (Runtime)                     │
│  AgentRuntime.process_message()                         │
│  1. 组装上下文 (Hot+Cold+Knowledge+Buffer)               │
│  2. 意图分类 (SkillRouter)                               │
│  3. 知识检索 (RetrievalService)                          │
│  4. 工具调用 (技能专属工具)                               │
│  5. 情绪分析 (EmotionEngine)                             │
│  6. 回复生成 (LLMOrchestrator: GLM/Claude)               │
│  7. 后台任务 (画像更新 + 洞察生成)                        │
└─────────────────────────────────────────────────────────┘
```

---

## 总结

Vibelife 采用了成熟的 RAG + Memory 架构：
- **用户数据**: 核心信息 + 技能专属 JSONB 灵活存储
- **知识模块**: 多格式支持、智能分块、混合检索
- **记忆系统**: Hot Memory (画像) + Cold Memory (洞察) 双层设计
- **Agent**: 7 阶段流水线，异步后台更新，跨技能上下文
