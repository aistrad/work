# CoreAgent 升级重构方案

> Version: 1.0 | 2026-01-20

---

## 1. 架构概览

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CoreAgent 架构                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

用户消息
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ CoreAgent                                                                            │
│                                                                                      │
│  ┌──────────────────────┐      ┌──────────────────────┐                             │
│  │ Phase 1: Skill 选择   │ ──▶ │ Phase 2: Skill 执行   │                             │
│  │ (use_skill 工具)      │      │ (Rule + Tools)       │                             │
│  └──────────────────────┘      └──────────────────────┘                             │
│            │                              │                                          │
│            ▼                              ▼                                          │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │                           AgentContext                                        │   │
│  │  user_id │ profile │ skill_data │ history │ skill │ conversation_id          │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ VibeProfile (PostgreSQL JSONB)                                                       │
│                                                                                      │
│  skill_data.{skill_id}                                                              │
│  ├── {业务数据}                                                                      │
│  ├── _state                                                                         │
│  └── _meta                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 核心设计

### 2.1 Protocol = Rule + Tool

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ 方案 D：纯 Prompt 驱动（推荐）                                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

Protocol 实现 = Rule 文件 + save_skill_data 工具

不需要：
- protocol 状态追踪
- step 计数器
- start_protocol / protocol_step 工具
- 前端传参数

LLM 自己驱动对话，从对话历史判断进度
```

### 2.2 统一 Skill Data

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ 单一入口设计                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

VibeProfile.skill_data.{skill_id}
├── {业务数据}      # Skill 特定（如 north_star, identity）
├── _state          # 运行时状态（如 current_protocol, streak）
└── _meta           # 自动管理（version, updated_at）

示例：
skill_data:
  lifecoach:
    north_star: { vision: "...", anti_vision: "..." }
    identity: { old: "...", new: "..." }
    weekly: { rocks: [...] }
    _state: { last_interaction: "2026-01-20" }
    _meta: { version: 5, updated_at: "..." }
```

---

## 3. 流程图

### 3.1 Protocol 执行流程

```
用户: "我想做一次人生重置"
         │
         ▼
┌────────────────────────┐
│ Phase 1: use_skill     │
│ → skill = "lifecoach"  │
│ → 加载 rules/dankoe.md │
└────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│ Phase 2: LLM 驱动对话                                           │
│                                                                │
│ System Prompt 包含：                                            │
│ - dankoe.md（6 个问题流程）                                      │
│ - skill_data.lifecoach（用户历史数据）                           │
│                                                                │
│ LLM: "准备好了吗？"                                              │
│ 用户: "准备好了"                                                 │
│ LLM: "第一个问题：..."                                           │
│ ... (6 个问题)                                                  │
│                                                                │
│ Tool: save_skill_data({ data: {...} })                         │
│ Tool: show_journey_card({ data: {...} })                       │
└────────────────────────────────────────────────────────────────┘
         │
         ▼
      完成！
```

### 3.2 Context 加载流程

```
请求到达
    │
    ▼
┌─────────────────────────────────────────┐
│ 1. 加载 VibeProfile                      │
│    └─ UnifiedProfileRepository.get()    │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ 2. 加载对话历史                          │
│    └─ ConversationRepository.get()      │
│    └─ 限制 10 条（协议时 20 条）          │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ 3. 构建 AgentContext                     │
│    └─ profile + skill_data + history    │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ 4. 构建 System Prompt                    │
│    └─ SKILL.md + Rules + Context        │
└─────────────────────────────────────────┘
```

---

## 4. 工具设计

### 4.1 save_skill_data

```yaml
name: save_skill_data
description: 保存当前 Skill 数据到 VibeProfile
parameters:
  - name: data
    type: object
    required: true
  - name: replace
    type: boolean
    default: false
```

**处理逻辑：**
1. 深度合并现有数据
2. 自动更新 `_meta.version` 和 `_meta.updated_at`
3. 保存到 `skill_data.{当前skill_id}`

### 4.2 show_journey_card

```yaml
name: show_journey_card
description: 展示 Journey 结果卡片
parameters:
  - name: data
    type: object
    required: true
```

---

## 5. Rule 文件示例

```markdown
# skills/lifecoach/rules/dankoe.md

---
id: dankoe
name: Dan Koe 快速重置
triggers: 人生重置, 设计人生, 快速重置
---

## 流程

6 个问题，按顺序完成：
1. 持续的不满
2. 反愿景场景
3. 愿景场景
4. 放弃的身份
5. 新身份宣言
6. 本周行动

## 完成后

1. 调用 save_skill_data 保存数据
2. 调用 show_journey_card 展示结果

## 中断处理

从对话历史判断进度，继续未完成的问题。
```

---

## 6. 实施清单

```
□ Step 1: 创建 Rule 文件
  └─ apps/api/skills/lifecoach/rules/dankoe.md

□ Step 2: 确认工具注册
  └─ save_skill_data 已在 core/tools/

□ Step 3: 清理旧代码
  └─ 删除 chat_v5.py 中的 protocol 逻辑

□ Step 4: 测试
  └─ 协议启动 → 追问 → 中断恢复 → 完成保存

总改动量 < 100 行
```

---

## 7. 对比

| 项目 | 当前方案 | 方案 D |
|------|----------|--------|
| 新增工具 | 3 | 0（复用） |
| 新增代码 | ~500 行 | ~50 行 |
| 状态管理 | 前端+后端 | 无（LLM 记忆） |
| 前端改动 | 需要 | 无 |
| 复杂度 | 高 | 低 |

---

## 附录：详细文档

- [CONTEXT_MANAGEMENT.md](./CONTEXT_MANAGEMENT.md) - Context 管理机制分析
- [PROTOCOL_DESIGN.md](./PROTOCOL_DESIGN.md) - Protocol 流程设计
- [SKILL_DATA_ARCHITECTURE.md](./SKILL_DATA_ARCHITECTURE.md) - Skill Data 架构
