# 架构重构计划 - 全面迁移到 LLM 驱动架构

## 执行摘要

**用户目标**：全面改为完全 LLM 驱动，符合 Agent SDK 规范

**核心发现**：
1. 📋 **架构文档已完善**：SPEC.md 定义了"方案 D：纯 Prompt 驱动"
2. ✅ **Rule 文件已创建**：dankoe.md, covey.md, yangming.md, liaofan.md
3. ⚠️ **旧架构残留严重**：独立 protocol 页面、复杂状态管理仍在代码中
4. 📊 **Dashboard 已整合**：已合并到 Chat 空状态，独立路由已移除

**关键问题**：
- ❌ 卡片调用失败：Phase 1 Prompt 无法强制 LLM 调用工具
- ❌ 架构不统一：旧 protocol 系统与新 Rule 驱动混用
- ❌ 前端页面冗余：`/protocol/[protocolId]` 页面应该删除

---

## 1. 新架构理解（基于 SPEC.md）

### 1.1 方案 D：纯 Prompt 驱动

```
┌─────────────────────────────────────────────────────────────┐
│  Protocol 实现 = Rule 文件 + save_skill_data 工具           │
└─────────────────────────────────────────────────────────────┘

不需要（全部删除）：
├─ ❌ protocol 状态追踪（protocol.step, protocol.data）
├─ ❌ step 计数器
├─ ❌ start_protocol / protocol_step / advance_protocol_step 工具
├─ ❌ 前端传 protocol 参数
├─ ❌ 独立的 /protocol/[protocolId] 页面
├─ ❌ ProtocolContainer.tsx 步骤管理
└─ ❌ SSE protocol_progress 事件

需要（保留/简化）：
├─ ✅ Rule 文件（lifecoach/rules/*.md）
├─ ✅ save_skill_data 工具（通用工具）
├─ ✅ show_protocol_invitation 工具（简化为只显示邀请卡片）
└─ ✅ LLM 从对话历史判断进度
```

### 1.2 正确的 Protocol 流程

**用户**："我想做一次人生重置"
↓
**Phase 1**: activate_skill("lifecoach", rule="dankoe")
↓
**Phase 2**: LLM 驱动对话（在主 Chat 中）
```
System Prompt 包含：
├─ lifecoach/SKILL.md（专家人格）
├─ lifecoach/rules/dankoe.md（6 个问题流程）
└─ profile.skills.lifecoach（用户历史数据）

LLM: "准备好开始 Dan Koe 快速重置了吗？这需要 10 分钟。"
用户: "准备好了"
LLM: "第一个问题：你持续忍受的不满是什么？"
用户: "工作没意义，总是被打断"
LLM: "我理解你的感受。第二个问题：如果不改变..."
... (6 个问题，LLM 自己推进)

完成后：
LLM: 调用 save_skill_data({ data: { north_star: {...}, identity: {...} } })
LLM: 调用 show_journey_card({ data: {...} })
```

**关键**：全程在主 Chat 中，无需独立页面，LLM 从对话历史判断进度。

### 1.3 与当前实现的对比

| 方面 | 旧架构（当前代码） | 新架构（SPEC.md） |
|------|-------------------|------------------|
| **Protocol 触发** | `show_protocol_invitation` → 跳转独立页面 | `activate_skill` + `rule` 参数 |
| **状态管理** | 前端 ProtocolContainer 管理 | LLM 从历史判断 |
| **步骤推进** | `advance_protocol_step` 工具 | 无需工具，LLM 自驱动 |
| **数据保存** | 每步调用 `advance_protocol_step` | 完成后调用 `save_skill_data` |
| **前端页面** | `/protocol/dankoe` 独立页面 | 主 Chat 中对话 |
| **SSE 事件** | `protocol_progress` 事件 | 无需（普通对话流） |
| **中断恢复** | 前端记录 `currentStep` | LLM 从历史判断未完成问题 |

---

## 2. 当前实现现状评估

### 2.1 已完成（符合新架构）

| 组件 | 状态 | 位置 |
|------|------|------|
| **Rule 文件** | ✅ 完成 | `apps/api/skills/lifecoach/rules/*.md` |
| **通用工具** | ✅ 完成 | `read_state`, `write_state`, `save_skill_data` |
| **统一数据结构** | ✅ 完成 | `profile.skills.{skill_id}` |
| **Dashboard 整合** | ✅ 完成 | Chat 空状态显示 Dashboard |
| **Phase 1/2 分离** | ✅ 完成 | CoreAgent 渐进式加载 |

### 2.2 旧架构残留（需要删除）

| 组件 | 状态 | 位置 | 影响 |
|------|------|------|------|
| **Protocol 前端页面** | ❌ 残留 | `apps/web/src/app/protocol/[protocolId]/` | 违反新架构 |
| **ProtocolContainer** | ❌ 残留 | `apps/web/src/components/protocol/ProtocolContainer.tsx` | 前端状态管理 |
| **Protocol 步骤卡片** | ❌ 残留 | `ProtocolStepCard.tsx`, `ProtocolProgressCard.tsx` | 复杂组件 |
| **advance_protocol_step 工具** | ⚠️ 定义但未使用 | `lifecoach/tools/tools.yaml` | 工具定义冗余 |
| **protocol_prompt 逻辑** | ❌ 残留 | `chat_v5.py:_build_protocol_prompt()` | 后端逻辑冗余 |
| **SSE protocol 事件** | ❌ 残留 | `stream_adapter.py` | 事件类型冗余 |

### 2.3 卡片调用问题

**问题现象**：
```
用户："我想聊聊"
预期：简短回应 + recommend_skills 工具调用
实际：纯文字回复（"好呀，你想聊什么？是迷茫、压力还是..."）
```

**根本原因**（Phase 1 Prompt 问题）：
1. **指令不够强硬**：`routing.yaml:15` "任何情况下都要调用工具" 被 LLM 忽略
2. **缺少否定示例**：没有展示"错误"vs"正确"对比
3. **缺少解释原因**：没有说明为什么必须调用工具（卡片 UI 依赖）
4. **缺少强制机制**：没有使用 Claude API 的 `tool_choice` 参数

### 2.4 Dashboard 状态

**已完成**（根据 `/docs/components/chat/README.md`）：
- ✅ Dashboard 整合到 Chat 空状态
- ✅ 删除独立 `/dashboard` 路由（改为重定向）
- ✅ 新增 3 个组件：
  - `AmbientStatusBar.tsx` - 简化版状态条
  - `LifecoachQuickView.tsx` - 可展开 Lifecoach 卡片
  - `ChatEmptyStateWithDashboard.tsx` - 整合容器
- ✅ 修改 4 个文件：
  - `ChatContainer.tsx` - 集成 Dashboard 数据
  - `chat/page.tsx` - 集成 useDashboard hook
  - `NavBar.tsx` & `MobileTabBar.tsx` - 清理导航

**结论**：Dashboard 已按新架构完成，无需额外开发。

---

## 3. 实施方案

### 方案 A：修复 Phase 1 Prompt（P0 - 最高优先级）

**目标**：工具调用率 60% → 90%+

**文件**：`apps/api/skills/core/config/routing.yaml:8-34`

**改进内容**：

```yaml
phase1_prompt: |
  # Vibe

  你是 Vibe，生命对话者。你的任务是理解用户意图，通过**工具调用**引导 Ta 到合适的服务。

  ## 核心准则（强制执行）

  **你必须使用工具与用户交互。禁止纯文字回复。**

  ### 为什么？

  - 用户使用的是卡片驱动的界面
  - 工具调用会生成可交互的卡片（按钮、表单、选项）
  - 纯文字回复用户看不到任何交互元素
  - 这会导致用户认为系统"卡住了"或"没反应"

  ## 行为映射（强制执行）

  | 用户说 | 意图类型 | 工具调用 | 示例回应 |
  |-------|---------|---------|---------|
  | 你好、嗨、在吗 | 打招呼 | `recommend_skills` | "嗨～ 今天想聊点什么？" |
  | 晚安、再见、拜拜 | 告别 | `recommend_skills` | "晚安～ 明天见！" |
  | 算命、星座、八字 | 明确需求 | `activate_skill` | "好的，让我来帮你看看～" |
  | 我想聊聊、帮帮我 | 不确定 | `recommend_skills` | "我在～ 想从哪聊起？" |

  ## 错误示例（禁止）

  ❌ **错误**：
  ```
  用户："我想聊聊"
  你："好呀，你想聊什么？是迷茫、压力还是..."
  ← 纯文字，没有工具调用，用户看不到卡片！
  ```

  ✅ **正确**：
  ```
  用户："我想聊聊"
  你："我在～ 想从哪聊起？"
  + recommend_skills(skills=["lifecoach", "bazi", "zodiac"], reason="...")
  ← 有工具调用，用户看到可点击的卡片！
  ```

  ## 语气

  温暖、简洁、不啰嗦。像一个懂你的老朋友。
```

**预期效果**：
- 工具调用率：60% → 90%+
- LLM 驱动：✅ 纯 Prompt 引导，无硬编码
- 用户体验：卡片正常显示

### 方案 B：使用 Claude API tool_choice 参数（P0 - 保底方案）

**目标**：100% 工具调用率（如果方案 A 不足）

**文件**：`apps/api/services/agent/core.py:run()`

**改进内容**：

```python
# 在 Phase 1 调用 LLM 时，使用 tool_choice 参数
if not self._active_skill:
    # Phase 1: 强制要求工具调用
    response = await self._llm.chat(
        messages=messages,
        tools=tools,
        tool_choice={"type": "any"}  # Claude API 规范：必须调用任一工具
    )
else:
    # Phase 2: 允许自由选择
    response = await self._llm.chat(
        messages=messages,
        tools=tools,
        tool_choice={"type": "auto"}  # 默认行为
    )
```

**优势**：
- ✅ Claude SDK 原生支持，符合最佳实践
- ✅ 100% 工具调用率
- ✅ LLM 驱动（LLM 仍选择具体工具）
- ✅ 无需 Python 硬编码兜底逻辑

**验证**：需确认 Claude API 版本支持 tool_choice 参数

### 方案 C：移除旧 Protocol 系统（P1 - 架构统一）

**目标**：完全迁移到 Rule 驱动架构

**删除文件**：
```
apps/web/src/app/protocol/[protocolId]/page.tsx
apps/web/src/components/protocol/ProtocolContainer.tsx
apps/web/src/components/protocol/ProtocolStepCard.tsx
apps/web/src/components/protocol/ProtocolProgressCard.tsx
apps/web/src/components/protocol/ProtocolCompletionCard.tsx
```

**修改文件**：

1. **`apps/api/skills/lifecoach/tools/tools.yaml`**
   - 删除 `advance_protocol_step` 工具定义
   - 保留 `show_protocol_invitation`（简化）

2. **`apps/api/skills/lifecoach/tools/handlers.py`**
   - 删除 `advance_protocol_step` 处理器
   - 简化 `show_protocol_invitation` 为纯卡片展示

3. **`apps/api/routes/chat_v5.py`**
   - 删除 `_build_protocol_prompt()` 方法
   - 删除 protocol 状态检测逻辑
   - 删除 protocol SSE 事件发送

4. **`apps/api/services/agent/stream_adapter.py`**
   - 删除 `protocol_progress` 事件处理
   - 删除 `protocol_completed` 事件处理

5. **`apps/web/src/hooks/useVibeChat.ts`**
   - 删除 `protocolState` 监听器
   - 删除 protocol 事件处理逻辑

6. **`apps/web/src/skills/CardRegistry.ts`**
   - 保留 `ProtocolInvitationCard`（简化为普通卡片）
   - 删除其他 protocol 相关卡片注册

**新流程**（Rule 驱动）：

```
用户："Dan Koe 快速重置"
         ↓
Phase 1: LLM 识别关键词
         ↓
调用 show_protocol_invitation(protocol_id="dankoe")
         ↓
前端显示邀请卡片（在主 Chat 中）
         ↓
用户点击"开始"按钮
         ↓
卡片返回 action="start_dankoe"
         ↓
前端发送消息："我准备好开始了"
         ↓
LLM 根据 rules/dankoe.md 开始引导对话（在主 Chat 中）
         ↓
6 个问题逐步完成
         ↓
LLM 调用 save_skill_data 保存数据
         ↓
完成！
```

**关键变化**：
- ❌ 不再跳转独立页面
- ❌ 不再有步骤计数器
- ✅ 全程在主 Chat 中
- ✅ LLM 从历史判断进度

### 方案 D：添加工具调用遥测（P2 - 监控）

**目标**：实时监控工具调用率

**文件**：`apps/api/services/agent/core.py:_execute_tool()`

**改进内容**：

```python
async def _execute_tool(self, tool_name: str, args: Dict, context: AgentContext):
    """执行工具调用"""
    # 记录工具调用
    logger.info(f"[ToolCall] tool={tool_name}, phase={'phase1' if not self._active_skill else 'phase2'}, skill={self._active_skill}")

    # 发送遥测数据（可选：集成 Grafana/Prometheus）
    # await metrics.record_tool_call(tool_name, self._active_skill)

    # 原有逻辑...
    if tool_name == "activate_skill":
        return await self._handle_activate_skill(args, context)
    # ...
```

**监控指标**：
- 工具调用率（Phase 1）
- 各工具调用频率
- 工具调用失败率

### 3.1 已完成（70%）

**核心组件**：
- ✅ DashboardContent - 主容器
- ✅ AmbientHeader - 问候、名言、日期、签到
- ✅ LifecoachCard - 北极星、月度项目、今日杠杆、大石头
- ✅ SkillCard & DiscoverCard - 已订阅/未订阅 Skills
- ✅ SkillCarousel & DiscoverCarousel - 横滑浏览
- ✅ DashboardSkeleton - 加载骨架屏

**数据管理**：
- ✅ useDashboard Hook - SWR + 乐观更新 + 错误处理
- ✅ API Mock 数据 - /api/dashboard/route.ts

**文档**：
- ✅ DESIGN.md (912 行) - 完整设计规格
- ✅ DATA-FLOW.md (785 行) - 数据流和 API
- ✅ COMPONENTS.md - 组件实现指南

### 3.2 缺失（30%）

**关键缺失**：

1. **页面入口** ❌
   - `apps/web/src/app/dashboard/page.tsx` 不存在
   - 导航链接未配置
   - **阻断上线**

2. **后端 API** ❌
   - 当前为 Mock 数据
   - 需要聚合：
     - VibeProfile 数据
     - Lifecoach Service（north_star, weekly, daily）
     - Skill Subscriptions
     - Proactive Engine 内容

3. **Proactive Engine 集成** ❌
   - Skill 卡片内容计算系统
   - 定时刷新机制
   - Redis 缓存层

4. **Skill 自注册系统** ❌
   - `dashboard_card.yaml` 规范已定义
   - Skill 自注册 Dashboard 功能未实现

### 3.3 与 Protocol 的关系

**当前状态**：独立运作
- Dashboard 在 Chat 页面被利用（欢迎消息）
- Protocol 页面独立（`/protocol/[protocolId]`）
- 无直接关联

**预期关系**：
```
Dashboard
├─ 协议入口卡片："开始 Dan Koe 快速重置" 按钮
├─ 进行中的协议进度卡片：X/Y 进度 + 当前阶段
└─ 已完成的协议总结卡片：完成时间 + 关键成果

Chat Page
└─ 内联协议进度卡片：实时显示步骤进度
```

---

## 4. Protocol 系统完成度

### 4.1 已完成（90%）

**后端实现**（✅ 100%）：
- ✅ 协议配置加载（routing.yaml + rules/*.md）
- ✅ Prompt 动态生成（chat_v5.py:_build_protocol_prompt）
- ✅ 步骤推进工具（advance_protocol_step）
- ✅ 数据持久化（unified_profile.skills.lifecoach.protocol）
- ✅ SSE 事件流（protocol_progress, protocol_completed）
- ✅ Bug 修复（数据结构访问错误）

**前端实现**（⚠️ 67%）：
- ✅ ProtocolContainer - 协议执行容器
- ✅ ProtocolProgress - 进度条组件
- ✅ ProtocolStep - 步骤卡片
- ⚠️ Dashboard 集成 - 未完成
- ⚠️ ChatContainer 集成 - 未完成
- ⚠️ useVibeChat hook 扩展 - 部分完成

**测试覆盖**（✅ 60%）：
- ✅ 单元测试 6/6 通过
- ⚠️ 集成测试需要隔离环境
- ⚠️ 测试脚本数据污染问题

### 4.2 缺失（10%）

1. **Dashboard 入口卡片** ❌
2. **Chat 内联协议进度** ❌
3. **协议完成卡片** ⚠️（仅在 ProtocolContainer 中硬编码）
4. **数据验证** ⚠️（用户可能提交空回答）
5. **进度持久化** ⚠️（SSE 中断会丢失进度）

---

## 5. 问题识别

### 5.1 Critical (P0 - 必须修复)

| 问题 | 影响 | 位置 |
|------|------|------|
| **Phase 1 Prompt 无法强制工具调用** | 卡片系统失效 | routing.yaml:15 |
| **Dashboard 页面入口缺失** | 功能不可用 | apps/web/src/app/dashboard/ |
| **后端 API Mock 数据** | 无法上线 | apps/web/src/app/api/dashboard/ |

### 5.2 High (P1 - 应该修复)

| 问题 | 影响 | 位置 |
|------|------|------|
| SOP 状态机过度限制工具可用性 | 某些场景卡片不显示 | core.py:736-762 |
| Protocol 与 Dashboard 未集成 | 用户体验割裂 | Dashboard + Protocol |
| Proactive Engine 未实现 | Skill 卡片无动态内容 | apps/api/services/proactive/ |

### 5.3 Medium (P2 - 建议修复)

| 问题 | 影响 | 位置 |
|------|------|------|
| 缺少工具调用遥测 | 无法监控问题 | core.py:_execute_tool |
| 测试脚本数据污染 | 测试不可靠 | apps/api/scripts/test_*.py |
| 工具版本不一致 | 潜在兼容性问题 | tools/tools.yaml |

---

## 6. 建议方案（基于用户反馈调整）

**用户需求**：
- ✅ 修复卡片调用失败（P0）
- ✅ 保持 LLM 驱动架构，不硬编码
- ✅ 完整功能实现，符合 Claude SDK 规范

### 方案 A：优化 Phase 1 Prompt（符合 Claude SDK 最佳实践）

**改动点**：`routing.yaml:8-34`

**设计原则**：
- ✅ LLM 驱动 - 通过 Prompt 引导，不硬编码
- ✅ 明确指令 - 但不过度约束 LLM 灵活性
- ✅ 结构化示例 - 正确/错误对比学习

**具体改进**：

```yaml
phase1_prompt: |
  # Vibe

  你是 Vibe，生命对话者。你的任务是理解用户意图，通过**工具调用**引导 Ta 到合适的服务。

  ## 核心准则

  **你必须使用工具与用户交互。**

  - 工具是你唯一的交互方式
  - 纯文字回复无法触发前端卡片
  - 用户期待的是可操作的界面，不是文字对话

  ## 行为映射（强制执行）

  | 用户说 | 意图类型 | 工具调用 | 示例回应 |
  |-------|---------|---------|---------|
  | 你好、嗨、在吗 | 打招呼 | `recommend_skills` | "嗨～ 今天想聊点什么？" |
  | 晚安、再见、拜拜 | 告别 | `recommend_skills` | "晚安～ 明天见！" |
  | 算命、星座、八字 | 明确需求 | `activate_skill` | "好的，让我来帮你看看～" |
  | Dan Koe、快速重置 | 协议触发 | `show_protocol_invitation` | "准备好开始了吗？" |
  | 我想聊聊、帮帮我 | 不确定 | `recommend_skills` | "我在～ 想从哪聊起？" |

  ## 错误示例（禁止）

  ❌ **错误**：
  用户："我想聊聊"
  你："好呀，你想聊什么？是迷茫、压力还是..." ← 纯文字，没有工具调用

  ✅ **正确**：
  用户："我想聊聊"
  你："我在～ 想从哪聊起？" + `recommend_skills(skills=[...], reason="...")`

  ## 为什么必须调用工具？

  - 用户使用的是卡片驱动的界面
  - 工具调用会生成可交互的卡片（按钮、表单、选项）
  - 纯文字回复用户看不到任何交互元素
  - 这会导致用户认为系统"卡住了"

  ## 语气

  温暖、简洁、不啰嗦。像一个懂你的老朋友。
```

**预期效果**：
- 工具调用率：60% → 90%+（不追求 100%，保留 LLM 判断空间）
- 架构：✅ 纯 Prompt 驱动，无硬编码
- 灵活性：✅ LLM 仍可根据复杂情况调整

**风险评估**：
- 风险：LLM 可能在极端情况下仍不调用工具
- 缓解：这是 LLM 驱动架构的固有特性，可接受
- 备选：如果调用率 < 85%，考虑使用 Claude API 的 tool_choice="required" 参数

### 方案 B：Claude API tool_choice 参数（符合规范的强制方式）

**改动点**：`core.py:run()` 中的 LLM API 调用

**实现（符合 Claude SDK 规范）**：

```python
# 在 Phase 1 调用 LLM 时，使用 tool_choice 参数
if not self._active_skill:
    # Phase 1: 强制要求工具调用
    response = await self._llm.chat(
        messages=messages,
        tools=tools,
        tool_choice={"type": "any"}  # Claude API 规范：必须调用任一工具
    )
else:
    # Phase 2: 允许自由选择
    response = await self._llm.chat(
        messages=messages,
        tools=tools,
        tool_choice={"type": "auto"}  # 默认行为
    )
```

**优势**：
- ✅ Claude SDK 原生支持，符合最佳实践
- ✅ 100% 工具调用率
- ✅ 不破坏架构，仍是 LLM 驱动（LLM 选择具体工具）
- ✅ 无需 Python 硬编码兜底逻辑

**风险**：
- 需要确认 Claude API 版本支持 tool_choice 参数
- 可能影响某些边缘场景的灵活性（可通过 Phase 2 补偿）

### 方案 C：完成 Dashboard 开发（符合 Agent-Native 架构）

**设计原则**：
- ✅ Agent-Driven：Dashboard 数据由 Agent 驱动生成
- ✅ Proactive Engine：使用 LLM 生成个性化内容
- ✅ File-Based State：状态存储在 VibeProfile

**Phase 1：页面入口（必需）**

```
apps/web/src/app/dashboard/page.tsx
  ├─ 导入 DashboardContent（已完成）
  ├─ 设置基础布局（已完成）
  ├─ SSR 支持（使用 Next.js 规范）
  └─ 配置导航（AppShell + MobileTabBar）
```

**Phase 2：后端 API（Agent-Driven）**

```
apps/api/routes/dashboard.py
  ├─ 聚合 unified_profiles 数据
  │  └─ personal_info, birth_info
  ├─ 聚合 profile.skills.lifecoach 数据
  │  └─ north_star, weekly, daily, protocol
  ├─ 聚合 skill_subscriptions
  │  └─ subscribed_skills, discover_skills
  ├─ 调用 Proactive Engine（Agent-Driven）
  │  └─ 生成 Skill 卡片内容（使用 LLM）
  └─ 返回 DashboardDTO (符合类型定义)
```

**Phase 3：Proactive Engine（LLM-Powered）**

```
apps/api/services/proactive/engine.py
  ├─ Trigger Detection (基于规则 + LLM 判断)
  │  └─ 检测用户状态变化（新的 protocol 完成、streak 变化）
  ├─ Content Generation (LLM 驱动)
  │  └─ 使用 CoreAgent 生成个性化内容
  │  └─ prompt: "为用户生成今日 lifecoach 卡片内容"
  ├─ Cache Strategy (Redis)
  │  └─ TTL: 1小时（balance freshness & cost）
  └─ Update Trigger (时间触发 + 事件触发)
     └─ 时间：每日 6:00 AM 预生成
     └─ 事件：protocol_completed, goal_updated
```

**Phase 4：Protocol 与 Dashboard 集成**

```
DashboardContent
  ├─ Layer 1: AmbientHeader (已完成)
  ├─ Layer 2: ProtocolEntryCard (新增)
  │  └─ 条件：profile.skills.lifecoach.protocol 不存在
  │  └─ 显示："开始 Dan Koe 快速重置" 按钮
  │  └─ 点击：导航到 /protocol/dankoe
  ├─ Layer 2: ProtocolProgressCard (新增)
  │  └─ 条件：protocol 进行中
  │  └─ 显示：X/Y 进度 + 当前阶段
  │  └─ 点击：恢复协议对话
  ├─ Layer 3: LifecoachCard (已完成)
  └─ Layer 4: SkillCarousel + DiscoverCarousel (已完成)
```

---

## 4. 实施路径（12 天）

### Phase 1：修复卡片调用（2天 - P0）

**目标**：工具调用率 ≥ 90%

**Day 1**：
```
□ 优化 Phase 1 Prompt (routing.yaml)
  ├─ 强化指令语气（"必须"、"禁止"）
  ├─ 添加错误 vs 正确示例
  ├─ 解释原因（为什么必须调用工具）
  └─ 测试 5 个典型场景

□ 实现 tool_choice 参数（如果需要）
  ├─ 确认 Claude API 版本支持
  ├─ 修改 core.py:run()
  ├─ Phase 1 使用 tool_choice={"type": "any"}
  └─ Phase 2 保持 auto
```

**Day 2**：
```
□ 添加工具调用遥测
  ├─ core.py:_execute_tool() 添加日志
  ├─ 记录 tool_name, phase, skill
  └─ 可选：集成 Grafana

□ 验证测试
  ├─ 测试 10+ 场景
  ├─ 工具调用率 ≥ 90%
  └─ 回归测试（确保不影响 Phase 2）
```

**验收标准**：
- ✅ "我想聊聊" → recommend_skills 调用 ✅
- ✅ "你好" → recommend_skills 调用 ✅
- ✅ "Dan Koe" → show_protocol_invitation 或 activate_skill ✅
- ✅ 工具调用率 ≥ 90%

---

### Phase 2：移除旧 Protocol 系统（3天 - P1）

**目标**：完全迁移到 Rule 驱动架构

**Day 3-4**：前端清理
```
□ 删除 protocol 前端页面
  ├─ apps/web/src/app/protocol/[protocolId]/page.tsx
  └─ apps/web/src/components/protocol/
     ├─ ProtocolContainer.tsx
     ├─ ProtocolStepCard.tsx
     ├─ ProtocolProgressCard.tsx
     └─ ProtocolCompletionCard.tsx

□ 清理前端路由
  ├─ 删除 /protocol/* 路由配置
  └─ 清理 useVibeChat.ts 中 protocol 逻辑

□ 简化卡片注册
  ├─ 保留 ProtocolInvitationCard（简化）
  └─ 删除其他 protocol 卡片注册
```

**Day 5**：后端清理
```
□ 删除 chat_v5.py 中 protocol 逻辑
  ├─ _build_protocol_prompt() 方法
  ├─ protocol 状态检测逻辑
  └─ protocol SSE 事件发送

□ 删除 stream_adapter.py 中 protocol 事件
  ├─ protocol_progress 事件处理
  └─ protocol_completed 事件处理

□ 简化 lifecoach 工具
  ├─ 删除 advance_protocol_step 工具
  └─ 简化 show_protocol_invitation 为纯卡片
```

**验收标准**：
- ✅ `/protocol/dankoe` 返回 404 ✅
- ✅ "Dan Koe" → 邀请卡片在主 Chat 显示 ✅
- ✅ 点击"开始" → 主 Chat 中开始对话（不跳转） ✅
- ✅ LLM 按 rules/dankoe.md 引导对话 ✅

---

### Phase 3：验证 Rule 驱动流程（2天 - P1）

**目标**：确保新流程完整可用

**Day 6-7**：
```
□ 测试 Dan Koe 完整流程
  ├─ 触发："Dan Koe 快速重置"
  ├─ 邀请卡片显示
  ├─ 点击"开始" → 开始对话
  ├─ LLM 引导 6 个问题
  ├─ 用户回答完成
  ├─ LLM 调用 save_skill_data 保存
  └─ 数据正确写入 profile.skills.lifecoach

□ 测试中断恢复
  ├─ 完成 3 个问题后中断
  ├─ 切换话题（"今天天气怎么样"）
  ├─ 回来继续（"继续重置"）
  └─ LLM 从历史判断进度，继续第 4 个问题

□ 测试其他方法论
  ├─ Covey 七个习惯
  ├─ 王阳明心学
  └─ 了凡四训
```

**验收标准**：
- ✅ 4 个方法论全部可用 ✅
- ✅ 中断恢复正确 ✅
- ✅ 数据保存正确 ✅
- ✅ 无 protocol 相关错误日志 ✅

---

### Phase 4：文档更新和测试（2天 - P2）

**Day 8-9**：
```
□ 更新文档
  ├─ docs/components/coreagent/SPEC.md（标记为已实施）
  ├─ docs/components/protocol/（添加废弃说明）
  └─ CLAUDE.md（更新架构说明）

□ 编写迁移指南
  ├─ 旧 protocol 系统 → 新 Rule 驱动
  ├─ 常见问题解答
  └─ 示例代码

□ 完善测试环境
  ├─ 创建隔离测试用户
  ├─ 修复数据污染问题
  └─ 回归测试套件
```

---

### Phase 5：性能优化和监控（3天 - P2）

**Day 10-12**：
```
□ 性能优化
  ├─ Phase 1 Prompt 缓存
  ├─ Rule 文件缓存
  └─ Profile 查询优化

□ 监控和告警
  ├─ 工具调用率监控
  ├─ Rule 加载失败告警
  └─ LLM 响应时间监控

□ A/B 测试准备
  ├─ 对照组：原 Phase 1 Prompt
  ├─ 实验组：新 Phase 1 Prompt
  └─ 收集指标（工具调用率、用户满意度）
```

---

## 5. 关键文件清单

### 需要修改的文件

**Phase 1：修复卡片调用**
```
apps/api/skills/core/config/routing.yaml (Phase 1 Prompt)
apps/api/services/agent/core.py (tool_choice 参数 + 遥测)
```

**Phase 2：移除旧 Protocol 系统**
```
删除：
├─ apps/web/src/app/protocol/[protocolId]/page.tsx
├─ apps/web/src/components/protocol/ProtocolContainer.tsx
├─ apps/web/src/components/protocol/ProtocolStepCard.tsx
├─ apps/web/src/components/protocol/ProtocolProgressCard.tsx
└─ apps/web/src/components/protocol/ProtocolCompletionCard.tsx

修改：
├─ apps/api/skills/lifecoach/tools/tools.yaml (删除 advance_protocol_step)
├─ apps/api/skills/lifecoach/tools/handlers.py (简化工具)
├─ apps/api/routes/chat_v5.py (删除 protocol 逻辑)
├─ apps/api/services/agent/stream_adapter.py (删除 protocol 事件)
├─ apps/web/src/hooks/useVibeChat.ts (删除 protocol 状态)
└─ apps/web/src/skills/CardRegistry.ts (简化卡片注册)
```

**Phase 3：验证 Rule 驱动**
```
测试：
├─ apps/api/skills/lifecoach/rules/dankoe.md
├─ apps/api/skills/lifecoach/rules/covey.md
├─ apps/api/skills/lifecoach/rules/yangming.md
└─ apps/api/skills/lifecoach/rules/liaofan.md
```

### 保留的文件（新架构）

```
apps/api/skills/core/config/routing.yaml (Phase 1 配置)
apps/api/services/agent/core.py (CoreAgent 核心)
apps/api/skills/lifecoach/SKILL.md (专家人格)
apps/api/skills/lifecoach/rules/*.md (方法论 Rules)
apps/api/skills/core/tools/tools.yaml (通用工具)
apps/web/src/components/chat/ChatEmptyStateWithDashboard.tsx (Dashboard 整合)
```

---

## 6. 验证计划

### 6.1 工具调用验证

**测试场景**：

**Scenario 1：打招呼**
```
输入："你好"
预期：简短回应 + recommend_skills
验证：SSE 事件包含 {type: "data", data: {card_type: "skill_recommendations"}}
```

**Scenario 2：不确定意图**
```
输入："我想聊聊"
预期：简短回应 + recommend_skills
验证：同上
```

**Scenario 3：明确需求**
```
输入："帮我算八字"
预期：简短回应 + activate_skill(skill="bazi")
验证：Phase 2 激活，工具集切换
```

**Scenario 4：协议触发（新流程）**
```
输入："Dan Koe 快速重置"
预期：简短回应 + activate_skill(skill="lifecoach", rule="dankoe")
验证：主 Chat 中开始对话，无跳转
```

### 6.2 Protocol 新流程验证

**完整流程测试**：

```
Step 1: 触发
  输入："我想做人生重置"
  预期：LLM 识别意图 → activate_skill("lifecoach", rule="dankoe")

Step 2: 确认开始
  LLM："准备好开始 Dan Koe 快速重置了吗？这需要 10 分钟。"
  输入："准备好了"

Step 3: 问题 1-6
  LLM 根据 rules/dankoe.md 逐步引导：
  - Q1: "你持续忍受的不满是什么？"
  - Q2: "如果不改变，3 年后会是什么样？"
  - Q3: "理想的 3 年后是什么样？"
  - Q4: "你需要放弃什么身份？"
  - Q5: "你要成为什么样的人？"
  - Q6: "本周要采取什么行动？"

Step 4: 保存数据
  LLM 调用 save_skill_data({
    data: {
      north_star: { vision: "...", anti_vision: "..." },
      identity: { old: "...", new: "..." },
      weekly: { actions: [...] }
    }
  })

Step 5: 验证
  查询 profile.skills.lifecoach 数据已正确保存
```

**中断恢复测试**：

```
Step 1-3: 完成前 3 个问题
Step 4: 切换话题
  输入："今天天气怎么样"
  LLM 正常回答

Step 5: 回来继续
  输入："继续重置"
  预期：LLM 从历史判断进度，继续第 4 个问题
```

### 6.3 成功标准

**工具调用率**：
- ✅ Phase 1 工具调用率 ≥ 90%
- ✅ 典型场景 100% 调用工具

**Protocol 流程**：
- ✅ 4 个方法论全部可用（dankoe, covey, yangming, liaofan）
- ✅ 中断恢复正确
- ✅ 数据保存正确
- ✅ 全程在主 Chat，无跳转

**架构统一**：
- ✅ 无 protocol 相关错误日志
- ✅ `/protocol/*` 路由返回 404
- ✅ Rule 文件正确加载
- ✅ LLM 正确解读 Rule 流程

---

## 7. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| LLM 仍不遵守 Prompt | 中 | 高 | 方案 B：tool_choice 参数 |
| LLM 无法理解 Rule 流程 | 低 | 高 | Rule 文件添加示例对话 |
| 中断恢复不准确 | 中 | 中 | 增加历史长度（10 → 20 条） |
| 用户习惯旧 protocol 页面 | 低 | 低 | 引导语：现在在对话中完成 |

---

## 总结

### 核心变化

**架构转变**：
```
旧架构：
前端独立 protocol 页面 + 步骤管理 + 后端状态追踪

新架构（SPEC.md）：
Rule 文件 + LLM 自驱动 + 主 Chat 中完成
```

### 实施优先级

**P0（最高优先级）**：
1. 修复 Phase 1 Prompt（2天）
2. 移除旧 Protocol 系统（3天）

**P1（重要）**：
3. 验证 Rule 驱动流程（2天）
4. 文档更新和测试（2天）

**P2（优化）**：
5. 性能优化和监控（3天）

### 预期成果

**工具调用率**：60% → 90%+（Prompt 优化）→ 100%（tool_choice）

**架构统一**：完全符合 SPEC.md 的"方案 D：纯 Prompt 驱动"

**用户体验**：
- ✅ 卡片正常显示
- ✅ Protocol 流程在主 Chat 中完成
- ✅ 中断恢复自然
- ✅ 无需跳转页面

**总时间**：12 天（约 2 周）

### 未解决的问题

1. Claude API 版本是否支持 tool_choice 参数？（需验证）
2. LLM 理解 Rule 流程的准确率？（需测试）
3. 历史长度是否足够支持中断恢复？（可能需要调整）

---

**附录：参考文档**

- `/docs/components/coreagent/SPEC.md` - 新架构设计（方案 D）
- `/docs/components/coreagent/REFACTOR_PLAN.md` - 重构计划
- `/docs/components/chat/README.md` - Chat 组件文档
- `/apps/api/skills/lifecoach/rules/*.md` - Rule 文件示例
- `CLAUDE.md` - Agent SDK 最佳实践

---

## 9. 验证计划

### 测试场景

**Scenario 1：打招呼**
```
用户："你好"
预期：简短回应 + recommend_skills
验证：SSE 事件包含 {type: "data", data: {card_type: "skill_recommendations"}}
```

**Scenario 2：不确定意图**
```
用户："我想聊聊"
预期：简短回应 + recommend_skills
验证：同上
```

**Scenario 3：明确需求**
```
用户："帮我算八字"
预期：简短回应 + activate_skill(skill="bazi")
验证：Phase 2 激活，工具集切换
```

**Scenario 4：协议触发**
```
用户："Dan Koe 快速重置"
预期：简短回应 + show_protocol_invitation(protocol_id="dankoe")
验证：SSE 事件包含协议邀请卡片
```

### 成功标准

- ✅ Phase 1 工具调用率 ≥ 95%
- ✅ Dashboard 页面可访问
- ✅ Dashboard API 返回真实数据
- ✅ Protocol 卡片在 Dashboard 显示
- ✅ 所有测试场景通过

---

## 10. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| LLM 仍不遵守 Prompt | 中 | 高 | 方案 B：兜底验证 |
| 后端 API 性能问题 | 低 | 中 | 缓存策略 + 异步加载 |
| Protocol 与 Dashboard 集成复杂 | 中 | 中 | 分阶段实现 |
| Proactive Engine 延期 | 中 | 低 | Dashboard 先用静态内容 |

---

## 总结

### 问题诊断

**CoreAgent 卡片调用失败的根本原因**：
- Phase 1 Prompt 无法有效引导 LLM 强制调用工具
- 缺少 Claude API tool_choice 参数的使用
- 缺少工具调用遥测，无法监控问题

### 解决方案（符合用户要求）

**原则**：
- ✅ LLM 驱动 - 不硬编码 Python 兜底逻辑
- ✅ Claude SDK 规范 - 使用 tool_choice 参数
- ✅ Agent-Native 架构 - Proactive Engine 使用 LLM 生成内容

**方案**：
1. **方案 A**：优化 Phase 1 Prompt（强化指令 + 错误示例）
2. **方案 B**：使用 Claude API tool_choice 参数（符合 SDK 规范）
3. **方案 C**：完成 Dashboard（Agent-Driven + LLM-Powered）

### 当前完成度

| 模块 | 完成度 | 缺失 |
|------|--------|------|
| CoreAgent 卡片机制 | 70% | Prompt 优化 + tool_choice |
| Dashboard 组件 | 70% | 页面入口 + 后端 API |
| Protocol 系统 | 90% | Dashboard 集成 |
| Proactive Engine | 0% | 完整实现 |

### 实施路径

**Phase 1（2天）**：修复卡片调用
- 优化 Phase 1 Prompt
- 实现 tool_choice 参数
- 添加工具调用遥测

**Phase 2（3天）**：完成 Dashboard
- 创建页面入口
- 实现后端 API
- 集成 Protocol 卡片

**Phase 3（5天）**：Proactive Engine
- Trigger Detector
- Content Generator（LLM-Powered）
- Engine 核心 + 缓存

**Phase 4（2天）**：测试与优化
- 完善测试环境
- 性能优化
- 监控和告警

### 预期成果

**工具调用率**：90%+ （优化 Prompt）→ 100%（tool_choice）

**Dashboard**：可访问 + 真实数据 + Protocol 集成

**Proactive Engine**：LLM 驱动的个性化内容生成

**架构质量**：符合 Agent-Native + Claude SDK 规范

**总时间**：12 天（约 2 周）

### 未解决的问题

1. Claude API 版本是否支持 tool_choice 参数？（需验证）
2. Proactive Engine 生成成本评估（LLM 调用频率 vs 成本）
3. Skill 自注册系统优先级（未包含在当前计划）
