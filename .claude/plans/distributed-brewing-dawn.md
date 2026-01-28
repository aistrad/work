# Extractor V8 升级方案 - 数据架构对齐

## 目标

将 ProfileExtractor 升级到 V8 三层架构，输出数据写入 `vibe.insight` + `vibe.target`，废弃 `extracted` 字段。

## 当前问题

```
现状：
  profile_extractor.py
    └─ 写入 profile.extracted (旧结构)
    └─ 写入 Cold Layer (vibe_profile_insights/timeline)

期望：
  profile_extractor.py
    └─ 写入 vibe.insight (我是谁)
    └─ 写入 vibe.target (我要成为谁)
    └─ 写入 Cold Layer (保持)
```

## 设计方案

### 1. 数据映射关系

```
旧 extracted 字段              →  新 vibe 结构
────────────────────────────────────────────────
facts.name, facts.occupation   →  identity (不变)
facts.pets, facts.relationships →  vibe.insight.essence.relationships
concerns                       →  vibe.target.focus.heat_map
goals                          →  vibe.target.goals
pain_points                    →  vibe.insight.dynamic.challenges
life_events                    →  Cold Layer (vibe_profile_timeline)
patterns.preferred_topics      →  vibe.insight.pattern.interests
patterns.conversation_style    →  vibe.insight.essence.communication_style
```

### 2. 新 Prompt 结构

```python
EXTRACTION_PROMPT_V8 = """你是一个用户画像分析专家。分析对话记录，提取关键信息。

## 输出格式 (JSON)

{
  "insight": {
    "essence": {
      "archetype": {"primary": "...", "secondary": "..."},
      "traits": [{"trait": "...", "intensity": 0.8}],
      "communication_style": "直接/温和/理性/感性"
    },
    "dynamic": {
      "emotion": {"current": "...", "trend": "stable/improving/declining"},
      "energy": {"level": "low/medium/high"},
      "challenges": ["..."]
    },
    "pattern": {
      "interests": ["..."],
      "behaviors": ["..."],
      "insights": ["..."]
    }
  },
  "target": {
    "goals": [
      {"title": "...", "category": "career/health/...", "status": "in_progress"}
    ],
    "focus": {
      "primary": "...",
      "heat_map": {"career": 0.8, "health": 0.3}
    }
  },
  "timeline_events": [
    {"date": "2024-01", "event": "...", "type": "life_event"}
  ]
}

## 抽取规则

1. **archetype**: 用户核心身份原型（创造者/导师/英雄/照顾者/智者等）
2. **traits**: 从对话中识别的稳定特质（最多5个）
3. **emotion/energy**: 最近对话中的情绪和能量状态
4. **challenges**: 当前面临的困难或痛点
5. **interests**: 反复提及的话题或领域
6. **goals**: 明确表达的目标或愿望
7. **heat_map**: 各领域关注度（0-1）
8. **timeline_events**: 重要人生节点（带日期）

只返回从对话中明确提取到的信息，不要推测。
"""
```

### 3. 核心改动

#### 3.1 修改 `extract_user_profile()` 函数

```python
async def extract_user_profile(user_id: UUID) -> Dict[str, Any]:
    # ... 获取消息 ...

    # 使用新 prompt
    response = await chat(
        messages=[{"role": "user", "content": prompt}],
        system=EXTRACTION_PROMPT_V8,
        ...
    )

    # 解析新结构
    new_data = json.loads(json_match.group())

    # 分别写入 vibe.insight 和 vibe.target
    if "insight" in new_data:
        current_insight = await UnifiedProfileRepository.get_vibe_insight(user_id)
        merged_insight = merge_insight(current_insight, new_data["insight"])
        await UnifiedProfileRepository.update_vibe_insight(user_id, merged_insight)

    if "target" in new_data:
        current_target = await UnifiedProfileRepository.get_vibe_target(user_id)
        merged_target = merge_target(current_target, new_data["target"])
        await UnifiedProfileRepository.update_vibe_target(user_id, merged_target)

    # 写入 Cold Layer (保持不变)
    if "timeline_events" in new_data:
        await _write_to_cold_layer(user_id, new_data["timeline_events"])
```

#### 3.2 新增合并函数

```python
def merge_insight(current: Dict, new: Dict) -> Dict:
    """合并 vibe.insight"""
    result = current.copy() if current else {}

    # essence: 深度合并，新数据优先
    if "essence" in new:
        result["essence"] = {
            **result.get("essence", {}),
            **new["essence"]
        }
        # traits 特殊处理：合并去重，保留最新 5 个
        if "traits" in new["essence"]:
            # ...

    # dynamic: 完全覆盖（状态型数据）
    if "dynamic" in new:
        result["dynamic"] = new["dynamic"]

    # pattern: 追加合并
    if "pattern" in new:
        # interests, behaviors, insights 追加去重
        # ...

    return result


def merge_target(current: Dict, new: Dict) -> Dict:
    """合并 vibe.target"""
    result = current.copy() if current else {}

    # goals: 合并，按 title 去重
    if "goals" in new:
        existing_titles = {g["title"] for g in result.get("goals", [])}
        for goal in new["goals"]:
            if goal["title"] not in existing_titles:
                result.setdefault("goals", []).append(goal)

    # focus: 合并 heat_map
    if "focus" in new:
        result["focus"] = {
            **result.get("focus", {}),
            **new["focus"]
        }

    return result
```

### 4. 完全切换策略（无兼容）

**不再写入 extracted 字段**，完全使用 V8 新结构：

```python
# 只写入 vibe 层
await UnifiedProfileRepository.update_vibe_insight(user_id, merged_insight)
await UnifiedProfileRepository.update_vibe_target(user_id, merged_target)

# 不再调用：
# await UnifiedProfileRepository.update_extracted(user_id, ...)
```

**PromptBuilder 已适配**：优先读取 vibe 层（行 199-265），extracted 回退逻辑将自然废弃。

### 5. 文件改动清单

| 文件 | 改动 |
|-----|------|
| `apps/api/workers/profile_extractor.py` | 核心改动：新 prompt、新输出结构、合并逻辑 |
| `apps/api/stores/unified_profile_repo.py` | 无需改动（接口已存在） |

### 6. 验证方案

```bash
# 1. 单元测试
python -m pytest apps/api/tests/test_profile_extractor.py -v

# 2. 手动测试
python apps/api/workers/profile_extractor.py --user-id <test_user_id>

# 3. 验证数据
psql -c "SELECT profile->'vibe' FROM unified_profiles WHERE user_id = '<test_user_id>'"
```

## 风险与缓解

| 风险 | 缓解措施 |
|-----|---------|
| LLM 输出格式不稳定 | 保留 JSON 解析容错，解析失败时跳过该用户 |
| 性能影响 | 保持批量运行模式，无额外开销 |

## 清理任务

- [ ] 删除 `update_extracted()` 调用
- [ ] 删除 `merge_extracted()` 函数
- [ ] 删除 `get_extracted()` 调用（如有）
- [ ] 后续：清理 PromptBuilder 中的 extracted 回退逻辑
