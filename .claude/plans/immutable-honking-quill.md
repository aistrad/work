# VibeLife 语义记忆系统实现计划

> 基于 Clawdbot 深度分析的启发，聚焦于用户优先级最高的语义记忆系统

## 一、背景与启发

### Clawdbot Memory 系统亮点
- SQLite-Vec + Embeddings 本地向量
- 混合搜索（向量 + 关键词）
- 跨会话上下文记忆

### VibeLife 现有基础设施（可复用）
| 组件 | 状态 | 复用方式 |
|------|------|---------|
| `knowledge_chunks_v2` | ✅ 已有 Gemini 3072维向量 + HNSW | 扩展 user_id 字段 |
| `hybrid_search_v2()` | ✅ RRF 混合搜索 SQL 函数 | 直接调用 |
| `unified_profiles.vibe` | ✅ insight/target 结构 | 存储长期记忆摘要 |
| `ProfileCache` | ✅ TTL 缓存 + 前缀失效 | 缓存记忆检索结果 |
| `CaseIndex` | ✅ 标签倒排索引 | 改进为语义匹配 |

---

## 二、架构设计

### 2.1 Memory 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                   VibeLife Memory 系统                       │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: 即时记忆 (会话内)                                  │
│  └─ messages.metadata.context_summary                       │
│  └─ Goal-Anchored History (现有)                            │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: 短期记忆 (会话间，7天 TTL)                         │
│  └─ user_memories 表 (新增)                                 │
│  └─ 向量化 + 语义检索                                       │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: 长期记忆 (永久)                                    │
│  └─ unified_profiles.vibe.insight (现有)                    │
│  └─ LLM 自动聚合的用户洞察                                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流

```
用户对话 → LLM 分析 → 提取记忆片段 → 向量化 → 存储
                                            ↓
新会话开始 → 检索相关记忆 → 注入 System Prompt → LLM 响应
```

---

## 三、实现方案

### 3.1 新增数据库表

```sql
-- apps/api/stores/migrations/xxx_user_memories.sql
CREATE TABLE user_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(user_id),
    skill_id TEXT,                    -- 关联 Skill（可选）
    memory_type TEXT NOT NULL,        -- insight | pattern | preference | fact
    content TEXT NOT NULL,            -- 记忆内容
    embedding vector(3072),           -- Gemini embedding
    importance FLOAT DEFAULT 0.5,     -- 重要性分数 0-1
    access_count INT DEFAULT 0,       -- 访问次数
    last_accessed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,           -- TTL（NULL=永久）
    metadata JSONB DEFAULT '{}',      -- 额外元数据
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_memory_type CHECK (
        memory_type IN ('insight', 'pattern', 'preference', 'fact')
    )
);

-- 向量索引
CREATE INDEX idx_user_memories_vec ON user_memories
    USING hnsw(embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- 复合索引
CREATE INDEX idx_user_memories_user_skill ON user_memories(user_id, skill_id);
CREATE INDEX idx_user_memories_type ON user_memories(user_id, memory_type);
CREATE INDEX idx_user_memories_expires ON user_memories(expires_at) WHERE expires_at IS NOT NULL;
```

### 3.2 核心模块

**文件结构：**
```
apps/api/services/memory/
├── __init__.py
├── semantic_memory.py      # 主服务类
├── memory_extractor.py     # LLM 记忆提取
├── memory_retriever.py     # 语义检索
└── memory_injector.py      # Prompt 注入
```

**核心类设计：**

```python
# apps/api/services/memory/semantic_memory.py
class SemanticMemory:
    """语义记忆系统主服务"""

    async def store_memory(
        self,
        user_id: UUID,
        content: str,
        memory_type: Literal["insight", "pattern", "preference", "fact"],
        skill_id: Optional[str] = None,
        importance: float = 0.5,
        ttl_days: Optional[int] = 7
    ) -> UUID:
        """存储记忆片段"""
        embedding = await self._get_embedding(content)
        # 插入 user_memories 表

    async def recall(
        self,
        user_id: UUID,
        query: str,
        skill_id: Optional[str] = None,
        top_k: int = 5,
        memory_types: Optional[List[str]] = None
    ) -> List[Memory]:
        """语义检索相关记忆"""
        query_embedding = await self._get_embedding(query)
        # 混合搜索：向量 + 类型过滤

    async def extract_from_conversation(
        self,
        user_id: UUID,
        messages: List[Dict],
        skill_id: str
    ) -> List[Memory]:
        """从对话中提取记忆（LLM 调用）"""
        # 调用 LLM 分析对话，提取值得记忆的内容

    async def consolidate_to_profile(
        self,
        user_id: UUID
    ):
        """将高频记忆聚合到 Profile.vibe.insight"""
        # 定期任务：分析 user_memories，更新长期洞察
```

### 3.3 集成点

**1. ToolExecutor 集成（记忆存储触发）：**
```python
# apps/api/services/agent/tool_executor.py
async def execute(self, ...):
    result = await handler(...)

    # 新增：检查是否需要存储记忆
    if result.get("_should_memorize"):
        await self.memory.store_memory(
            user_id=context.user_id,
            content=result.get("_memory_content"),
            memory_type=result.get("_memory_type", "insight"),
            skill_id=context.skill_id
        )
```

**2. PromptBuilder 集成（记忆注入）：**
```python
# apps/api/services/agent/prompt_builder.py
async def build(self, ...):
    # 现有代码...

    # 新增：检索并注入相关记忆
    if user_message:
        memories = await self.memory.recall(
            user_id=user_id,
            query=user_message,
            skill_id=skill_id,
            top_k=3
        )
        if memories:
            prompt += self._format_memories_section(memories)
```

**3. 会话结束 Hook（自动提取）：**
```python
# apps/api/services/agent/core.py
async def _on_conversation_end(self, ...):
    # 提取本次会话的记忆
    await self.memory.extract_from_conversation(
        user_id=user_id,
        messages=conversation_messages,
        skill_id=active_skill
    )
```

### 3.4 新增工具

```yaml
# apps/api/skills/core/tools/tools.yaml
- name: remember
  description: 主动记住重要信息
  parameters:
    content:
      type: string
      description: 要记住的内容
    importance:
      type: number
      description: 重要性 0-1
      default: 0.7
  _should_memorize: true
  _memory_type: "fact"

- name: recall_memory
  description: 回忆用户相关记忆
  parameters:
    query:
      type: string
      description: 要回忆的主题
    top_k:
      type: integer
      default: 3
```

---

## 四、关键文件修改

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `stores/migrations/xxx_user_memories.sql` | 新增 | 记忆表 + 索引 |
| `stores/memory_repo.py` | 新增 | 数据访问层 |
| `services/memory/__init__.py` | 新增 | 模块入口 |
| `services/memory/semantic_memory.py` | 新增 | 主服务 |
| `services/memory/memory_extractor.py` | 新增 | LLM 提取 |
| `services/agent/tool_executor.py` | 修改 | 添加记忆存储触发 |
| `services/agent/prompt_builder.py` | 修改 | 添加记忆注入 |
| `services/agent/core.py` | 修改 | 添加会话结束 hook |
| `skills/core/tools/tools.yaml` | 修改 | 添加 remember/recall 工具 |
| `skills/core/tools/handlers.py` | 修改 | 工具实现 |

---

## 五、验证方案

### 5.1 单元测试
```bash
# 测试记忆存储
pytest apps/api/tests/services/memory/test_semantic_memory.py

# 测试向量检索
pytest apps/api/tests/stores/test_memory_repo.py
```

### 5.2 集成测试
```bash
# 测试完整流程
pytest apps/api/tests/integration/test_memory_flow.py
```

### 5.3 E2E 验证场景
1. **存储验证**：对话中说"我喜欢咖啡"→ 检查 user_memories 表
2. **检索验证**：新会话问"我喜欢什么饮料"→ 应返回相关记忆
3. **注入验证**：检查 LLM System Prompt 包含记忆段落
4. **TTL 验证**：7 天后记忆自动过期

---

## 六、待确认问题

1. **Embedding 服务选择**：继续用 Gemini 还是切换到 OpenAI？
2. **记忆提取频率**：每次对话结束还是定期批量？
3. **记忆容量限制**：每用户最多存储多少条记忆？
4. **隐私控制**：用户是否需要查看/删除记忆的能力？
