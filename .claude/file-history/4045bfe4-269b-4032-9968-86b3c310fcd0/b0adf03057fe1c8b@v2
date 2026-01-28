# Mentis OS v3.0 代码实现 Review 报告

基于 `/home/aiscend/work/fortune_ai/docs/.specs/claude.md` 规格文档的全面代码审查

---

## 执行摘要

| 维度 | 合规度 | 状态 |
|------|--------|------|
| **数据库 Schema** | 100% | 完整 |
| **后端服务** | 40% | 严重偏离 |
| **API 路由** | 40% | 缺失多个端点 |
| **前端组件** | 78% | 基础完成,交互缺失 |
| **技术栈** | 50% | 多项未采用 |
| **项目结构** | 30% | 未独立构建 |

**总体合规度: ~50%**

---

## 1. 项目结构偏离

### 1.1 位置决策 [严重偏离]

| 项 | 规格要求 | 实际实现 |
|----|---------|---------|
| 项目位置 | `/home/aiscend/work/mentis` (独立) | `/home/aiscend/work/fortune_ai` |
| 数据库 | `mentis` (独立) | 需验证 env |
| fortune_ai | 完整保留不修改 | 已修改 `api/main.py` 等 |

### 1.2 技术栈偏离

| 组件 | 规格 | 实际 | 影响 |
|------|------|------|------|
| Monorepo | pnpm + Turborepo | 无 | 无工作区管理 |
| ORM | Drizzle | psycopg2 原生 | 类型安全降低 |
| 向量存储 | Pinecone | 无 | 无语义搜索 |
| 实时推送 | Pusher | 简单 WebSocket | 无跨客户端推送 |

---

## 2. 后端服务问题 [P0 紧急]

### 2.1 SSE 事件顺序错误

**文件**: `services/stream_processor.py:235-326`

```
规格顺序:
1. stream_created
2. extraction_complete
3. state_update        ← 应在此
4. behavior_match
5. agent_response
6. done

实际顺序:
1. stream_created
2. extraction_complete
3. behavior_match      ← 太早
4. agent_response
5. state_update        ← 太晚
6. done
```

**影响**: 客户端状态不一致,behavior_match 基于旧状态

### 2.2 Emotion Engine 问题

**文件**: `services/emotion_engine.py:47-63`

| 问题 | 规格 | 实际 |
|------|------|------|
| **强度范围** | 1-10 | 只有 4, 6, 7 |
| **强度计算** | 基于内容分析 | 仅检测 `!` 符号 |
| **信心度** | 动态计算 | 硬编码 0.7 |
| **二级情绪** | 应检测 | 永远为空 `[]` |

```python
# 当前实现问题
intensity = 7 if "!" in content else 6  # 范围过小
confidence = 0.7  # 硬编码
secondary = []  # 永远为空
```

### 2.3 Behavior Matcher 问题 [严重]

**文件**: `services/behavior_matcher.py:37-48`

| 问题 | 规格 | 实际 |
|------|------|------|
| **分层策略** | >= 0.85 自动 / 0.60-0.85 确认 / <0.60 忽略 | 全部 0.9 自动 |
| **待办优先** | 优先匹配 action_task | 未检查 |
| **行为数量** | 可扩展 | 仅 3 个硬编码 |

```python
# 当前实现 - 无分层
return BehaviorMatch(
    confidence=0.9,      # 所有匹配都是 0.9
    auto_checkin=True,   # 所有都自动确认
)
```

### 2.4 Intervention Agent 问题 [严重]

**文件**: `services/intervention_agent.py:34-50`

| 问题 | 规格 | 实际 |
|------|------|------|
| **干预类型** | 多种基于情绪/能量 | 仅 1 种 (breathing) |
| **个性化** | 基于用户档案 | 无 |
| **动态奖励** | 根据难度 | 固定 1 |

```python
# 当前实现 - 仅一种干预
if emotion.primary in {"anger", "anxiety"} or energy_score < 40:
    return {"type": "breathing", "momentum_reward": 1}  # 硬编码
```

### 2.5 Context Extraction 问题

**文件**: `services/stream_processor.py:26-44`

| 字段 | 规格 | 实际 |
|------|------|------|
| **scene** | work/home/social/... | 仅 3 种 |
| **trigger** | meeting/deadline/conflict/... | 仅 meeting |
| **target** | boss/colleague/friend/... | 仅 boss |
| **time_of_day** | morning/afternoon/evening/night | 永远 None |

---

## 3. API 路由缺失

### 3.1 已实现

```
/api/v3/stream (POST/GET/DELETE)
/api/v3/user/state (GET)
/api/v3/realtime (WebSocket)
```

### 3.2 缺失端点

```
/api/v3/decode/bazi           # 八字计算
/api/v3/decode/ziwei          # 紫微计算
/api/v3/decode/fortune/today  # 今日运势
/api/v3/evolve/tasks          # 任务列表
/api/v3/evolve/checkin        # 手动打卡
/api/v3/evolve/momentum       # 动量历史
/api/v3/user/profile          # 用户档案
```

---

## 4. 前端问题

### 4.1 功能缺失

| 功能 | 状态 | 文件 |
|------|------|------|
| **语音输入** | 仅 UI 按钮 | `omnibar.tsx:230` |
| **图片输入** | 仅 UI 按钮 | `omnibar.tsx:225` |
| **WebSocket 重连** | 无 | `realtime.ts` |
| **WebSocket 心跳** | 无 | `realtime.ts` |

### 4.2 Store 数据缺失

**文件**: `web-app/src/stores/stream-store.ts`

```typescript
// 规格要求
userState: {
  energyScore: number
  momentum: number
  streakDays: number    // 缺失
  currentMood: string   // 缺失
  auraState: string
}
```

### 4.3 命名不一致

| 规格 | 实现 |
|------|------|
| pendingTasks | actionCards |
| MagicInput | Omnibar |
| streakDays | streak_days (DB有,Store无) |

---

## 5. 数据库 Schema [符合]

**文件**: `migrations/20260104_mentis_v3.sql`

所有 7 个核心表已创建:
- mentis_user
- user_profile
- user_state
- stream_entry
- action_task
- checkin_log
- insight_record

---

## 6. 修复优先级

### P0 紧急 (影响功能完整性)

1. **修复 SSE 事件顺序** - `stream_processor.py`
   - 将 `state_update` 移至 `extraction_complete` 之后

2. **修复 Emotion 强度范围** - `emotion_engine.py`
   - 实现 1-10 范围的强度计算
   - 动态计算 confidence

3. **实现 Behavior Matcher 分层** - `behavior_matcher.py`
   - >= 0.85: auto_checkin=True
   - 0.60-0.85: auto_checkin=False
   - < 0.60: matched=False

4. **添加待办任务优先级** - `behavior_matcher.py`
   - 先检查 action_task 表

5. **实现 time_of_day** - `stream_processor.py`

### P1 高优先级 (影响用户体验)

6. WebSocket 自动重连 + 心跳
7. 语音/图片输入实现
8. 扩展干预策略 (多种类型)
9. Store 补充 streakDays/currentMood
10. 实现缺失 API 端点

### P2 中优先级 (代码质量)

11. 提取配置常量 (消除魔法数字)
12. 添加单元测试
13. 事务管理
14. 类型提示完善

---

## 7. 关键文件清单

| 文件 | 问题 | 优先级 |
|------|------|--------|
| `services/stream_processor.py` | SSE顺序,context提取 | P0 |
| `services/emotion_engine.py` | 强度/信心/二级情绪 | P0 |
| `services/behavior_matcher.py` | 分层/待办优先 | P0 |
| `services/intervention_agent.py` | 单一干预 | P1 |
| `web-app/src/lib/realtime.ts` | 重连/心跳 | P1 |
| `web-app/src/stores/stream-store.ts` | 数据缺失 | P1 |
| `web-app/src/components/chat/omnibar.tsx` | 语音/图片 | P1 |
| `api/stream_routes.py` | 缺失端点 | P1 |

---

## 8. 执行计划

### 用户决策
- **项目位置**: 迁移到独立 `/home/aiscend/work/mentis` 目录
- **修复范围**: 修复所有 P0 问题

---

### 阶段 1: 项目迁移 (创建独立目录)

#### 1.1 创建项目结构
```bash
mkdir -p /home/aiscend/work/mentis
cd /home/aiscend/work/mentis

# 创建目录结构
mkdir -p apps/web/src/{app,components,lib,stores}
mkdir -p packages/{decode-modules,reframe-modules,evolve-modules}
mkdir -p services api stores migrations scripts docs
```

#### 1.2 迁移核心文件
| 源文件 (fortune_ai) | 目标位置 (mentis) |
|---------------------|-------------------|
| `services/stream_processor.py` | `services/stream_processor.py` |
| `services/emotion_engine.py` | `services/emotion_engine.py` |
| `services/behavior_matcher.py` | `services/behavior_matcher.py` |
| `services/intervention_agent.py` | `services/intervention_agent.py` |
| `api/stream_routes.py` | `api/stream_routes.py` |
| `api/realtime_routes.py` | `api/realtime_routes.py` |
| `stores/mentis_db.py` | `stores/mentis_db.py` |
| `migrations/20260104_mentis_v3.sql` | `migrations/001_init.sql` |
| `web-app/src/components/stream/*` | `apps/web/src/components/stream/*` |
| `web-app/src/components/hud/*` | `apps/web/src/components/hud/*` |
| `web-app/src/lib/mentis-stream.ts` | `apps/web/src/lib/stream.ts` |
| `web-app/src/lib/realtime.ts` | `apps/web/src/lib/realtime.ts` |
| `web-app/src/stores/stream-store.ts` | `apps/web/src/stores/stream.ts` |

---

### 阶段 2: 修复 P0 问题

#### 2.1 修复 SSE 事件顺序
**文件**: `services/stream_processor.py`

**修改内容**:
```python
# 修复前 (错误顺序):
# 1. stream_created
# 2. extraction_complete
# 3. behavior_match      ← 太早
# 4. agent_response
# 5. state_update        ← 太晚
# 6. done

# 修复后 (正确顺序):
# 1. stream_created
# 2. extraction_complete
# 3. state_update        ← 移到这里
# 4. behavior_match
# 5. agent_response
# 6. done
```

**具体改动**:
- 将 `yield state_update` (原 line ~317) 移至 `extraction_complete` 之后
- 确保 behavior_match 和 agent_response 使用最新状态

#### 2.2 修复 Emotion Engine 强度范围
**文件**: `services/emotion_engine.py`

**修改内容**:
```python
# 修复前:
intensity = 7 if "!" in content else 6  # 只有 6, 7

# 修复后:
def calculate_intensity(text: str, emotion: str) -> int:
    """计算情绪强度 1-10"""
    base = 5
    # 感叹号 +2
    exclamation_count = text.count("!") + text.count("！")
    base += min(exclamation_count, 2)
    # 重复词 +1
    if has_repeated_words(text):
        base += 1
    # 大写/全大写 +1
    if text.isupper():
        base += 1
    # 关键词密度调整
    keyword_density = calculate_keyword_density(text, emotion)
    base += int(keyword_density * 2)
    return max(1, min(10, base))
```

```python
# 修复前:
confidence = 0.7  # 硬编码

# 修复后:
def calculate_confidence(text: str, matched_keywords: list) -> float:
    """动态计算置信度"""
    if not matched_keywords:
        return 0.3
    # 基础置信度
    base = 0.5
    # 匹配关键词数量
    base += min(len(matched_keywords) * 0.1, 0.3)
    # 上下文明确性
    if has_clear_context(text):
        base += 0.1
    return min(0.95, base)
```

```python
# 修复前:
secondary = []  # 永远为空

# 修复后:
def detect_secondary_emotions(text: str, primary: str) -> list:
    """检测二级情绪"""
    SECONDARY_KEYWORDS = {
        "frustration": ["烦", "郁闷", "受够"],
        "helplessness": ["无力", "无奈", "没办法"],
        # ...更多
    }
    secondary = []
    for emotion, keywords in SECONDARY_KEYWORDS.items():
        if emotion != primary and any(k in text for k in keywords):
            secondary.append(emotion)
    return secondary[:3]  # 最多3个
```

#### 2.3 实现 Behavior Matcher 分层策略
**文件**: `services/behavior_matcher.py`

**修改内容**:
```python
# 修复前:
return BehaviorMatch(confidence=0.9, auto_checkin=True)  # 所有都是 0.9

# 修复后:
THRESHOLDS = {
    "AUTO_CHECKIN": 0.85,
    "CONFIRM_CARD": 0.60,
}

def calculate_match_confidence(text: str, behavior: dict) -> float:
    """计算匹配置信度"""
    content = text.lower()
    # 完全匹配: 0.90-0.95
    for alias in behavior["aliases"]:
        if alias == content or f"了{alias}" in content:
            return 0.92
    # 包含匹配: 0.75-0.85
    for alias in behavior["aliases"]:
        if alias in content:
            return 0.78
    # 模糊匹配: 0.60-0.75
    for alias in behavior["aliases"]:
        if fuzzy_match(alias, content) > 0.8:
            return 0.65
    return 0.0

def match_behavior(text: str, user_id: str = None) -> BehaviorMatch:
    # 1. 优先检查待办任务
    if user_id:
        pending_tasks = get_pending_tasks(user_id)
        for task in pending_tasks:
            if task_matches_text(task, text):
                return BehaviorMatch(
                    matched=True,
                    behavior=task["type"],
                    confidence=0.90,
                    auto_checkin=True,
                    task_id=task["id"],
                )

    # 2. 匹配行为库
    for behavior in BEHAVIOR_LIBRARY:
        conf = calculate_match_confidence(text, behavior)
        if conf >= THRESHOLDS["AUTO_CHECKIN"]:
            return BehaviorMatch(matched=True, confidence=conf, auto_checkin=True)
        elif conf >= THRESHOLDS["CONFIRM_CARD"]:
            return BehaviorMatch(matched=True, confidence=conf, auto_checkin=False)

    return BehaviorMatch(matched=False, confidence=0.0, auto_checkin=False)
```

#### 2.4 实现 time_of_day 上下文提取
**文件**: `services/stream_processor.py`

**修改内容**:
```python
from datetime import datetime

def extract_context(text: str) -> Dict[str, Any]:
    # ... existing code ...

    # 添加 time_of_day
    hour = datetime.now().hour
    if 5 <= hour < 12:
        time_of_day = "morning"
    elif 12 <= hour < 17:
        time_of_day = "afternoon"
    elif 17 <= hour < 21:
        time_of_day = "evening"
    else:
        time_of_day = "night"

    return {
        "scene": scene,
        "trigger": trigger,
        "target": target,
        "time_of_day": time_of_day,
    }
```

#### 2.5 添加 Mentis DB 初始化
**文件**: `api/main.py`

**修改内容**:
```python
@app.on_event("startup")
def startup():
    # ... existing code ...

    # 添加 Mentis DB 初始化
    from stores.mentis_db import init_pool
    init_pool()
```

---

### 阶段 3: 验证修复

1. 单元测试 SSE 事件顺序
2. 测试 Emotion Engine 强度范围 (1-10)
3. 测试 Behavior Matcher 分层 (auto/confirm/ignore)
4. 测试 time_of_day 提取
5. 端到端测试完整 Stream 流程

---

## 9. 审查结论

Mentis OS v3.0 的实现在**数据库层**完全符合规格,但在**服务层和交互层**存在显著偏离:

1. **核心逻辑过度简化**: Emotion/Behavior/Intervention 仅实现了最基础功能
2. **SSE 事件契约违规**: 事件顺序与规格不符
3. **前端交互不完整**: 语音/图片输入仅有 UI
4. **技术栈未对齐**: 未采用 Pinecone/Pusher/Drizzle

建议在投入生产前优先完成 P0 级修复项。
