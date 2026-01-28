# VibeLife Journey/VibeProfile 优化计划

## 代码分析总结

### 当前架构状态

| 模块 | 版本 | 状态 | 关键问题 |
|------|------|------|---------|
| **CoreAgent** | v10 | ✅ 完善 | 不读取 vibe 层 |
| **UnifiedProfileRepo** | v9 | ✅ 完善 | sync 方法存在但触发时机有限 |
| **ProfileExtractor** | v8 | ⚠️ 可用 | 仅定时运行，非实时 |
| **ProactiveEngine** | v7.6 | ⚠️ 可用 | 只支持单向推送，无关怀对话 |
| **Journey 前端** | - | ✅ 完善 | 组件完整，缺后端聚合 API |

### 数据流分析

```
用户对话 → CoreAgent → save_skill_data → skills.lifecoach
                                      ↓
                          sync_lifecoach_to_vibe_target → vibe.target
                                      ↓
        ProfileExtractor (定时) → vibe.insight + vibe.target (补充)
                                      ↓
                         前端 → ??? → 无聚合端点
```

**核心问题**：
1. **前端无法获取数据**: 没有 `/api/v1/journey` 端点
2. **个性化缺失**: CoreAgent 不读取 vibe.insight，lifecoach 无法融合命盘
3. **数据滞后**: Extractor 只在定时任务运行

---

## 最优先改进的三件事

### P0-1: 后端添加 Journey 聚合 API

**问题**: Journey 前端组件完整，但后端没有聚合端点，前端无法正确展示数据

**文件修改**:
- `apps/api/routes/skills.py` - 添加 journey 端点

**实现**:
```python
@router.get("/api/v1/journey")
async def get_journey_data(user_id: UUID):
    profile = await UnifiedProfileRepository.get_profile(user_id)
    lifecoach = profile.get("skills", {}).get("lifecoach", {})
    vibe_target = profile.get("vibe", {}).get("target", {})

    return {
        "north_star": lifecoach.get("north_star") or vibe_target.get("north_star"),
        "identity": lifecoach.get("identity"),
        "goals": lifecoach.get("goals") or vibe_target.get("goals", []),
        "monthly_boss": lifecoach.get("current", {}).get("month"),
        "weekly": lifecoach.get("current", {}).get("week"),
        "daily_levers": lifecoach.get("current", {}).get("daily"),
        "progress": lifecoach.get("progress", {}),
        "journey_state": compute_journey_state(lifecoach)
    }
```

**验收**: Journey 页面能正确显示四种状态

---

### P0-2: CoreAgent 注入 vibe.insight 实现个性化

**问题**: lifecoach 无法读取 bazi/zodiac 数据，所有用户收到相同建议

**文件修改**:
- `apps/api/services/agent/prompt_builder.py` - 注入 vibe.insight
- `apps/api/skills/lifecoach/SKILL.md` - 添加使用指南

**实现**:
```python
# prompt_builder.py
async def build(self, skill_id, ..., profile, ...):
    ...
    # 对于 lifecoach，注入跨 Skill 洞察
    if skill_id == "lifecoach":
        vibe_insight = profile.get("vibe", {}).get("insight", {})
        if vibe_insight:
            cross_skill_context = self._format_vibe_insight(vibe_insight)
            system_prompt += f"\n\n{cross_skill_context}"
    ...
```

**效果**:
- 之前: "拖延往往源于内心的恐惧"（通用）
- 之后: "以你的特质来看，你天生思虑深远，容易想太多。试试先做再想。"（个性化）

**验收**: 有 bazi 数据的用户，lifecoach 建议能体现其命盘特质

---

### P0-3: 对话结束时触发 vibe 同步

**问题**: ProfileExtractor 只在定时任务运行，数据滞后

**方案**: 在对话结束时触发轻量同步

**文件修改**:
- `apps/api/routes/chat_v5.py` - 对话结束时触发
- `apps/api/stores/unified_profile_repo.py` - 添加轻量同步方法

**实现**:
```python
# chat_v5.py - 在流结束后
async def handle_stream_end(user_id, skill_id):
    if skill_id == "lifecoach":
        # 已有的 sync 会在 update_skill_data 时自动触发
        pass
    # 可选：触发轻量 Extractor
    await trigger_lightweight_extraction(user_id)
```

**验收**: 对话后 Journey 页面立即显示最新数据

---

## 实施顺序

1. **P0-1** (1天) - 添加 Journey API，让前端能工作
2. **P0-2** (1天) - 注入 vibe.insight，实现个性化
3. **P0-3** (0.5天) - 同步机制，确保实时性

## 验证方法

```bash
# 启动测试环境
./scripts/start-test.sh

# 测试 Journey API
curl http://localhost:8100/api/v1/journey -H "Authorization: Bearer <token>"

# 测试个性化（需要有 bazi 数据的用户）
# 1. 发送消息 "我感觉很迷茫"
# 2. 检查 lifecoach 回复是否包含个性化特质

# 测试同步
# 1. 完成 dankoe 协议
# 2. 立即刷新 Journey 页面，检查 north_star 是否更新
```

---

## 未解决问题

1. **Extractor 触发频率**: 每次对话后触发还是有间隔？需要考虑 LLM 成本
2. **vibe.insight 格式**: prompt_builder 如何格式化才能让 LLM 自然使用？
3. **前端缓存**: SWR 刷新间隔是否需要调整？
