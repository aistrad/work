# Vibe Diary 功能优化实现计划

## 概述

基于 `/home/aiscend/work/mentis/docs/Vibe Diary.md` 规格，实现三大核心功能：
1. **Daily Digest** - 每日精美日记
2. **Life Connect** - 生活信息连接
3. **Share Cards** - 社交分享卡

同时将情绪引擎升级为 LLM 驱动。

---

## Phase 1: LLM 情绪引擎增强 (3-4天)

### 后端任务

#### 1.1 创建 LLM 情绪引擎
**文件**: `services/llm_emotion_engine.py`
```python
# 核心函数
async def analyze_with_llm(text: str) -> LLMEmotionResult
async def hybrid_emotion_analyze(text: str, user_id: str) -> LLMEmotionResult
```

#### 1.2 创建 Prompt 模板系统
**文件**: `services/prompts.py`
- emotion_analysis prompt
- digest_prose prompt
- entity_extraction prompt

#### 1.3 修改流处理器
**文件**: `services/stream_processor.py`
- 集成混合分析模式
- 高强度(>=7)或低置信度(<0.7)时调用 LLM

#### 1.4 数据库扩展
```sql
ALTER TABLE stream_entry ADD COLUMN llm_emotion JSONB;
ALTER TABLE stream_entry ADD COLUMN extracted_entities UUID[];
```

### 前端任务
- 更新 `stream-card.tsx` 显示 LLM 分析结果

---

## Phase 2: Daily Digest 功能 (4-5天)

### 后端任务

#### 2.1 创建数据表
```sql
CREATE TABLE daily_digest (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES mentis_user(id),
    date DATE NOT NULL,
    title TEXT,
    summary TEXT,
    prose TEXT,
    style VARCHAR(50) DEFAULT 'minimal',
    emotion_trajectory JSONB,
    energy_curve JSONB,
    key_tags TEXT[],
    stream_ids UUID[],
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);
```

#### 2.2 创建 Digest 服务
**文件**: `services/daily_digest_service.py`
```python
async def generate_daily_digest(user_id, date, config) -> dict
async def get_emotion_trajectory(user_id, date) -> List
async def get_energy_curve(user_id, date) -> List
```

#### 2.3 创建 API 路由
**文件**: `api/digest_routes.py`
- `GET /v3/digest` - 列表
- `GET /v3/digest/{date}` - 详情
- `POST /v3/digest/{date}/generate` - 生成
- `PUT /v3/digest/{id}/style` - 换风格

### 前端任务
**目录**: `apps/web/src/components/digest/`
- `digest-viewer.tsx` - 日记查看器
- `emotion-timeline.tsx` - 情绪时间线
- `energy-curve.tsx` - 能量曲线
- `style-selector.tsx` - 风格选择器 (minimal/artistic/magazine/warm)

---

## Phase 3: Life Connect 功能 (5-6天)

### 后端任务

#### 3.1 创建数据表
```sql
CREATE TABLE life_entity (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES mentis_user(id),
    entity_type VARCHAR(30),  -- people/event/todo/goal/place
    name TEXT NOT NULL,
    metadata JSONB,
    source_stream_ids UUID[],
    confirmed BOOLEAN DEFAULT FALSE,
    mention_count INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 3.2 创建 Life Connect 服务
**文件**: `services/life_connect_service.py`
```python
async def extract_entities_from_stream(stream_id, content, llm_result) -> List
async def merge_or_create_entity(user_id, entity) -> dict
async def get_pending_confirmations(user_id) -> List
async def confirm_entity(user_id, entity_id, confirmed) -> dict
```

#### 3.3 创建 API 路由
**文件**: `api/entity_routes.py`
- `GET /v3/entities` - 实体列表
- `GET /v3/entities/pending` - 待确认
- `POST /v3/entities/{id}/confirm` - 确认
- `POST /v3/entities/{id}/dismiss` - 拒绝

### 前端任务
**目录**: `apps/web/src/components/life/`
- `entity-list.tsx` - 实体列表
- `entity-card.tsx` - 实体卡片
- `confirm-dialog.tsx` - 确认弹窗
- `people-section.tsx` - 人物板块
- `todos-section.tsx` - 待办板块

---

## Phase 4: Share Cards 功能 (4-5天)

### 后端任务

#### 4.1 创建数据表
```sql
CREATE TABLE share_card (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES mentis_user(id),
    card_type VARCHAR(30),  -- moment/daily/milestone/insight
    title TEXT,
    content TEXT,
    template VARCHAR(50),
    privacy_settings JSONB,
    share_token VARCHAR(64) UNIQUE,
    is_public BOOLEAN DEFAULT FALSE,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 4.2 创建 Share Card 服务
**文件**: `services/share_card_service.py`
```python
async def create_share_card(user_id, card_type, source_id, template) -> dict
async def apply_privacy_redaction(content, entities) -> tuple
async def generate_card_image(card_id, format) -> str
async def create_share_link(card_id) -> str
```

#### 4.3 创建 API 路由
**文件**: `api/share_routes.py`
- `POST /v3/share/card` - 创建卡片
- `GET /v3/share/cards` - 我的卡片
- `POST /v3/share/cards/{id}/image` - 生成图片
- `POST /v3/share/cards/{id}/publish` - 发布
- `GET /v3/public/{token}` - 公开访问

### 前端任务
**目录**: `apps/web/src/components/share/`
- `card-creator.tsx` - 卡片创建器
- `card-preview.tsx` - 卡片预览
- `template-picker.tsx` - 模板选择
- `privacy-settings.tsx` - 隐私设置

---

## Phase 5: 集成测试与优化 (2-3天)

1. 端到端测试
2. 性能优化 (LLM 调用缓存)
3. 错误处理完善
4. 更新 `docs/config.md`

---

## 关键技术决策

| 决策点 | 方案 |
|-------|------|
| LLM 调用 | GLM-4-Flash (主) + Gemini Flash (备) |
| 混合模式 | 规则快速识别 + LLM 深度分析 |
| 图片生成 | Playwright 渲染 HTML → 截图 |
| 向量搜索 | Pinecone + Gemini Embedding (3072维) |

---

## 关键文件清单

### 需修改
- `services/stream_processor.py` - 集成 LLM 和实体抽取
- `services/glm_service.py` - 添加结构化输出
- `stores/mentis_db.py` - 支持新表操作
- `api/main.py` - 注册新路由

### 需创建
- `services/llm_emotion_engine.py`
- `services/prompts.py`
- `services/daily_digest_service.py`
- `services/life_connect_service.py`
- `services/share_card_service.py`
- `api/digest_routes.py`
- `api/entity_routes.py`
- `api/share_routes.py`

### 数据库
- 新建 3 个表: `daily_digest`, `life_entity`, `share_card`
- 扩展 `stream_entry` 表

---

## 预估工期

| Phase | 天数 | 内容 |
|-------|------|------|
| Phase 1 | 3-4 | LLM 情绪引擎 |
| Phase 2 | 4-5 | Daily Digest |
| Phase 3 | 5-6 | Life Connect |
| Phase 4 | 4-5 | Share Cards |
| Phase 5 | 2-3 | 测试优化 |
| **总计** | **18-23天** | |
