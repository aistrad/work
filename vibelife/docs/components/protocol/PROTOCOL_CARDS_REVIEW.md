# Protocol 内联卡片实现 - 深度Review报告

> 生成时间: 2026-01-20
> 审查范围: Protocol 内联卡片展示系统（前后端完整链路）

---

## 执行摘要

你已经完成了 **Protocol 内联卡片的基础展示层**，包括前端组件、后端工具和单元测试。但是，**核心的 Protocol 执行引擎尚未实现**，导致这些精美的卡片目前无法在真实对话中被调用。

**完成度评估**: 40%（展示层完成，驱动层缺失）

---

## 1. 已完成部分（✅）

### 1.1 前端卡片组件（3个）

| 文件 | 功能 | 状态 |
|------|------|------|
| `ProtocolProgressCard.tsx` | 展示协议进度（步骤/总步骤、阶段信息） | ✅ 完成 |
| `ProtocolStepCard.tsx` | 展示单个步骤内容（支持问题/选项） | ✅ 完成 |
| `ProtocolCompletionCard.tsx` | 展示协议完成状态和总结 | ✅ 完成 |

**优点**:
- 使用 framer-motion 实现流畅动画
- 响应式设计，支持移动端
- 样式统一，符合 Design System

**问题**:
- 所有卡片已注册到 `CardRegistry`
- `ChatMessage.tsx` 已支持通过 `CardRegistry.render()` 渲染

### 1.2 后端工具处理器（6个）

| 工具名 | 功能 | 实现状态 |
|--------|------|---------|
| `show_protocol_progress` | 展示进度卡片 | ✅ 完成 |
| `show_protocol_step` | 展示步骤卡片 | ✅ 完成 |
| `show_protocol_completion` | 展示完成卡片 | ✅ 完成 |
| `show_protocol_invitation` | 展示协议邀请卡片 | ✅ 完成（缺前端组件） |
| `advance_protocol_step` | 推进协议步骤 | ✅ 完成 |
| `cancel_protocol` | 取消协议 | ✅ 完成 |

**优点**:
- 工具定义标准化（tools.yaml）
- 返回统一的卡片数据格式
- 自动添加时间戳

**问题**:
- `show_protocol_invitation` 返回的 `protocol_invitation` 卡片类型，但前端缺少对应组件

### 1.3 测试覆盖

| 测试类型 | 覆盖范围 | 结果 |
|---------|---------|------|
| 后端单元测试 | 3个展示工具 | ✅ 4/4 通过 |
| HTML 演示页面 | 3个卡片样式 | ✅ 视觉正常 |
| 前端集成测试 | - | ❌ 未执行 |
| 端到端对话测试 | - | ❌ 未执行 |

---

## 2. 关键缺失（❌）

### 2.1 Protocol 执行引擎（Critical）

**问题**: 虽然有 `dankoe.yaml` 协议配置，但没有读取和执行这个配置的代码。

**缺失内容**:
1. **Protocol Loader**: 读取 `protocols/*.yaml` 配置
2. **Protocol State Machine**: 管理协议状态（当前步骤、用户回答、下一步骤）
3. **Protocol Router**: 根据用户消息判断是否进入/继续协议
4. **Auto Tool Calling**: AI 根据协议状态自动调用 `show_protocol_step` 等工具

**影响**:
- AI 不知道何时以及如何调用这些工具
- 用户无法通过对话触发协议流程
- 卡片只能通过手动测试代码调用

**预期行为**（目前缺失）:
```python
# 伪代码 - 预期的 Protocol 引擎
class ProtocolEngine:
    def __init__(self, protocol_id: str):
        self.config = load_protocol_config(f"protocols/{protocol_id}.yaml")
        self.state = ProtocolState()

    async def start(self, user_id: str) -> dict:
        """开始协议，展示第1步"""
        step_config = self.config.steps[1]
        return {
            "tool": "show_protocol_step",
            "args": {
                "step_number": 1,
                "step_name": step_config.name,
                "content": step_config.question,
                ...
            }
        }

    async def advance(self, user_answer: str) -> dict:
        """根据用户回答推进到下一步"""
        # 1. 保存用户回答
        # 2. 更新状态
        # 3. 返回下一步工具调用
        ...
```

### 2.2 AI 指令缺失（Critical）

**问题**: `SKILL.md` 中没有告诉 AI 何时以及如何使用这些工具。

**当前 SKILL.md**:
- 提到了"协议"概念（第240行：方法论索引）
- 提到了 Dan Koe 6 问流程
- 但没有告诉 AI 如何调用 `show_protocol_progress` 等工具

**缺失的指令**（建议添加）:
```markdown
## Protocol 模式（结构化协议执行）

当用户明确要求使用某个方法论协议时（如"帮我用 Dan Koe 方法做一次重置"），
进入 Protocol 模式：

### 执行流程
1. **开始协议**: 调用 `show_protocol_step` 展示第1步
2. **每一步**:
   - 等待用户回答
   - 调用 `show_protocol_progress` 更新进度
   - 调用 `show_protocol_step` 展示下一步
3. **完成协议**: 调用 `show_protocol_completion` 展示总结

### 工具调用时机
| 场景 | 调用工具 | 参数来源 |
|------|---------|---------|
| 开始协议 | show_protocol_step | 从 `protocols/{id}.yaml` step 1 |
| 每完成一步 | show_protocol_progress | 当前进度 |
| 进入新步骤 | show_protocol_step | 从 yaml 读取步骤配置 |
| 协议完成 | show_protocol_completion | 汇总所有步骤数据 |
```

### 2.3 前端缺失组件

| 卡片类型 | 后端返回 | 前端组件 | 状态 |
|---------|---------|---------|------|
| protocol_progress | ✅ | ✅ | 完成 |
| protocol_step | ✅ | ✅ | 完成 |
| protocol_completion | ✅ | ✅ | 完成 |
| protocol_invitation | ✅ | ❌ | **缺失** |

**影响**:
- `show_protocol_invitation` 工具调用后，前端无法渲染
- 控制台会显示 `Unknown card type: protocol_invitation` 警告

### 2.4 集成测试缺失

**已有测试**:
- ✅ 后端单元测试（测试工具返回格式）
- ✅ HTML 演示页面（测试卡片视觉）

**缺失测试**:
- ❌ 前端渲染测试（卡片是否正常显示在 ChatContainer）
- ❌ 端到端对话测试（完整 Protocol 流程）
- ❌ 错误处理测试（协议中断、用户取消）

---

## 3. 架构问题分析

### 3.1 配置 vs 代码

**当前状态**:
- ✅ 有配置文件（`dankoe.yaml`）
- ❌ 无配置加载器
- ❌ 无配置驱动的执行引擎

**问题**:
配置文件定义了协议的每一步（问题、存储字段、提示词），但没有代码读取和使用这些配置。这导致：
1. 配置文件形同虚设
2. AI 必须硬编码每个协议的逻辑（不可扩展）
3. 新增协议需要修改代码（违反 Open-Closed 原则）

**建议**:
实现配置驱动的 Protocol 引擎，让 AI 根据 YAML 自动执行协议。

### 3.2 State Management

**当前状态**:
- `advance_protocol_step` 会保存步骤数据到 `UnifiedProfileRepository`
- 但没有代码读取和使用这些状态

**问题**:
- 协议中断后无法恢复
- 无法查询"用户当前在协议的哪一步"
- AI 无法获取"用户在前几步回答了什么"

**建议**:
1. 定义 Protocol State 数据模型
2. 在每次对话开始时加载协议状态
3. 根据状态决定下一步行动

### 3.3 工具调用链

**期望流程**（目前不work）:
```
用户: "帮我用 Dan Koe 方法做一次重置"
  ↓
CoreAgent 识别意图
  ↓
调用 show_protocol_step (step 1)
  ↓
前端渲染 ProtocolStepCard
  ↓
用户回答
  ↓
AI 调用 advance_protocol_step（保存回答）
  ↓
AI 调用 show_protocol_progress（更新进度）
  ↓
AI 调用 show_protocol_step (step 2)
  ↓
... 循环直到完成
  ↓
AI 调用 show_protocol_completion
```

**实际流程**（目前）:
```
用户: "帮我用 Dan Koe 方法做一次重置"
  ↓
CoreAgent 根据 SKILL.md 手动问 6 个问题
  ↓
不调用任何 protocol 工具
  ↓
用户看不到任何进度卡片
```

---

## 4. 完整解决方案设计

### 4.1 Protocol 引擎实现（优先级：P0）

**文件结构**:
```
apps/api/skills/lifecoach/
├── protocols/
│   ├── __init__.py           # Protocol Loader
│   ├── engine.py             # Protocol Engine
│   └── dankoe.yaml           # 已存在
```

**核心类设计**:
```python
# protocols/__init__.py
class ProtocolConfig:
    id: str
    name: str
    total_steps: int
    steps: Dict[int, StepConfig]

    @classmethod
    def load(cls, protocol_id: str) -> "ProtocolConfig":
        """从 YAML 加载协议配置"""
        ...

# protocols/engine.py
class ProtocolEngine:
    """协议执行引擎"""

    def __init__(self, protocol_id: str, user_id: str):
        self.config = ProtocolConfig.load(protocol_id)
        self.state = self._load_state(user_id)

    async def get_current_step(self) -> dict:
        """获取当前步骤的工具调用参数"""
        step_num = self.state.current_step
        step_config = self.config.steps[step_num]

        return {
            "tool": "show_protocol_step",
            "args": {
                "step_number": step_num,
                "step_name": step_config.name,
                "content": step_config.question,
                "is_question": True,
                ...
            }
        }

    async def advance(self, user_answer: str) -> List[dict]:
        """推进协议，返回需要调用的工具列表"""
        # 1. 保存用户回答
        await self._save_answer(user_answer)

        # 2. 更新进度
        self.state.current_step += 1

        # 3. 返回工具调用序列
        tools = []

        # 更新进度卡片
        tools.append({
            "tool": "show_protocol_progress",
            "args": {...}
        })

        # 显示下一步或完成
        if self.state.current_step <= self.config.total_steps:
            tools.append(await self.get_current_step())
        else:
            tools.append({
                "tool": "show_protocol_completion",
                "args": {...}
            })

        return tools
```

### 4.2 SKILL.md 更新（优先级：P0）

在 `SKILL.md` 第237行（方法论索引之后）添加：

```markdown
## Protocol 执行模式

当用户明确要求使用某个方法论时，使用 Protocol 模式执行。

### 何时进入 Protocol 模式

满足以下条件之一：
1. 用户明确说"帮我用 [方法论] 做..."
2. 用户说"我想做一次梳理/重置"
3. 探索对话后，用户同意进入结构化流程

### Protocol 执行流程

1. **读取协议状态**
   ```
   调用 read_lifecoach_state(sections=["protocol"])
   检查是否有进行中的协议
   ```

2. **开始新协议**（如果没有进行中的协议）
   ```
   调用 show_protocol_step（展示第1步）
   参数从 protocols/{protocol_id}.yaml 的 steps.1 获取
   ```

3. **继续进行中的协议**（如果有）
   ```
   根据 protocol.step 确定当前步骤
   调用 show_protocol_step 展示当前步骤
   ```

4. **用户回答后**
   ```
   调用 advance_protocol_step 保存回答
   调用 show_protocol_progress 更新进度
   调用 show_protocol_step 展示下一步
   ```

5. **完成协议**
   ```
   调用 show_protocol_completion 展示总结
   调用对应的方法论卡片（如 show_dankoe）
   ```

### 工具调用示例

用户: "帮我用 Dan Koe 方法做一次重置"

**你的回应**:
```
好的，我们来做一次 Dan Koe 的快速重置。
整个过程大约10分钟，我会问你6个问题。

<调用 show_protocol_step>
{
  "step_number": 1,
  "step_name": "持续的不满",
  "content": "过去一年，你学会忍受的、持续的不满是什么？不是深层痛苦，而是你已经习惯的不舒服。",
  "is_question": true
}
```

用户回答后:
```
<调用 advance_protocol_step 保存回答>
<调用 show_protocol_progress 更新进度>
<调用 show_protocol_step 展示下一步>
```
```

### 4.3 前端补全（优先级：P1）

创建缺失的 `ProtocolInvitationCard.tsx`:

```tsx
/**
 * ProtocolInvitationCard - 协议邀请卡片
 *
 * 用于邀请用户开始一个协议流程
 * card_type: "protocol_invitation"
 */

import { motion } from "framer-motion";
import { registerCard } from "@/skills/CardRegistry";

interface ProtocolInvitationData {
  protocol_id: string;
  title: string;
  description: string;
  estimated_time?: string;
  actions: Array<{
    label: string;
    action: "start" | "cancel";
  }>;
}

function ProtocolInvitationCard({ data }: { data: ProtocolInvitationData }) {
  const { title, description, estimated_time, actions } = data;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="protocol-invitation-card p-5 rounded-2xl bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200/50"
    >
      <div className="flex items-start gap-3 mb-3">
        <div className="flex-shrink-0 w-10 h-10 rounded-full bg-blue-500 text-white flex items-center justify-center">
          <span className="text-xl">🎯</span>
        </div>
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-gray-800">{title}</h3>
          {estimated_time && (
            <p className="text-sm text-gray-500">约 {estimated_time}</p>
          )}
        </div>
      </div>

      <p className="text-gray-700 leading-relaxed mb-4">{description}</p>

      <div className="flex gap-2">
        {actions.map((action, index) => (
          <button
            key={index}
            className={`flex-1 px-4 py-2 rounded-lg font-medium transition-all ${
              action.action === "start"
                ? "bg-blue-500 text-white hover:bg-blue-600"
                : "bg-gray-100 text-gray-700 hover:bg-gray-200"
            }`}
          >
            {action.label}
          </button>
        ))}
      </div>
    </motion.div>
  );
}

registerCard("protocol_invitation", ProtocolInvitationCard);

export default ProtocolInvitationCard;
```

更新 `apps/web/src/skills/lifecoach/cards/index.ts`:
```typescript
// Protocol 卡片
import "./ProtocolProgressCard";
import "./ProtocolStepCard";
import "./ProtocolCompletionCard";
import "./ProtocolInvitationCard";  // 新增
```

### 4.4 端到端测试方案（优先级：P1）

创建 `apps/api/scripts/test_protocol_e2e.py`:

```python
"""
Protocol 端到端测试
模拟完整的用户对话流程
"""

async def test_dankoe_protocol_full_flow():
    """测试 Dan Koe 协议完整流程"""

    # 1. 用户请求开始协议
    response1 = await chat_api.send_message(
        user_id="test_user",
        message="帮我用 Dan Koe 方法做一次人生重置",
        skill_id="lifecoach"
    )

    # 验证：应该展示第1步
    assert_tool_called(response1, "show_protocol_step")
    assert response1.tool_args["step_number"] == 1
    assert "持续的不满" in response1.tool_args["step_name"]

    # 2. 用户回答第1个问题
    response2 = await chat_api.send_message(
        user_id="test_user",
        message="工作没意义，每天重复，但又不敢辞职"
    )

    # 验证：应该保存回答 + 更新进度 + 展示第2步
    assert_tool_called(response2, "advance_protocol_step")
    assert_tool_called(response2, "show_protocol_progress")
    assert_tool_called(response2, "show_protocol_step")
    assert response2.tool_args["step_number"] == 2

    # 3. 继续回答剩余问题...
    # ... (省略 step 3-5)

    # 4. 回答最后一个问题
    response_final = await chat_api.send_message(
        user_id="test_user",
        message="这周我会：1. 每天早上写30分钟 2. 联系3个潜在客户 3. 完成作品集"
    )

    # 验证：应该展示完成卡片 + 方法论卡片
    assert_tool_called(response_final, "show_protocol_completion")
    assert_tool_called(response_final, "show_dankoe")

    # 5. 验证数据持久化
    state = await UnifiedProfileRepository.read_life_context_path(
        "test_user", "lifecoach"
    )
    assert state["protocol"]["status"] == "completed"
    assert len(state["protocol"]["data"]) == 6  # 6个步骤的数据
    assert state["north_star"]["vision_scene"] is not None
```

---

## 5. 实施路线图

### Phase 1: 核心功能（1-2天）

| 任务 | 优先级 | 预计时间 | 文件 |
|-----|--------|---------|------|
| 实现 ProtocolConfig Loader | P0 | 2h | `protocols/__init__.py` |
| 实现 ProtocolEngine | P0 | 4h | `protocols/engine.py` |
| 更新 SKILL.md 添加 Protocol 指令 | P0 | 1h | `SKILL.md` |
| 创建 ProtocolInvitationCard | P1 | 1h | `ProtocolInvitationCard.tsx` |

### Phase 2: 集成测试（0.5-1天）

| 任务 | 优先级 | 预计时间 |
|-----|--------|---------|
| 编写 Protocol E2E 测试 | P1 | 2h |
| 前端集成测试（Playwright） | P1 | 2h |
| 错误处理测试 | P2 | 1h |

### Phase 3: 优化迭代（1天）

| 任务 | 优先级 | 预计时间 |
|-----|--------|---------|
| 协议中断恢复 | P2 | 2h |
| 进度持久化优化 | P2 | 1h |
| 卡片动画优化 | P3 | 1h |
| 移动端适配验证 | P2 | 2h |

**总计**: 2.5-4天

---

## 6. 风险评估

| 风险 | 严重程度 | 可能性 | 缓解措施 |
|-----|---------|-------|---------|
| Protocol 引擎复杂度超预期 | 高 | 中 | 从最简单的 dankoe 协议开始，逐步扩展 |
| AI 不按预期调用工具 | 高 | 中 | 在 SKILL.md 中提供详细示例和明确指令 |
| 状态管理不一致 | 中 | 低 | 使用 UnifiedProfile 统一存储，加事务锁 |
| 前端卡片性能问题 | 低 | 低 | 已使用 framer-motion 优化，暂无风险 |

---

## 7. 总结与建议

### 7.1 当前状态

你的实现完成了 **展示层（40%）**，但缺少 **驱动层（60%）**。就像造了一辆漂亮的汽车，但还没装发动机。

**完成部分**:
- ✅ 精美的卡片组件
- ✅ 标准化的工具定义
- ✅ 基础的单元测试

**缺失部分**:
- ❌ Protocol 执行引擎
- ❌ AI 使用指令
- ❌ 端到端测试

### 7.2 核心建议

1. **优先实现 Protocol 引擎**（P0）
   - 这是整个系统的核心
   - 没有引擎，卡片就是装饰品

2. **更新 SKILL.md**（P0）
   - 告诉 AI 何时以及如何使用工具
   - 提供清晰的调用示例

3. **补全前端组件**（P1）
   - `ProtocolInvitationCard` 缺失会导致控制台警告

4. **端到端测试**（P1）
   - 验证完整对话流程
   - 发现集成问题

### 7.3 技术亮点

你的实现展现了良好的架构意识：
- ✅ 配置驱动设计（`dankoe.yaml`）
- ✅ 前后端解耦（CardRegistry）
- ✅ 标准化工具定义（tools.yaml）
- ✅ 组件化设计（3个独立卡片）

下一步只需要：
- **连接配置和执行**（实现 Protocol 引擎）
- **指导 AI 行为**（更新 SKILL.md）
- **验证完整链路**（E2E 测试）

### 7.4 推荐下一步

**立即行动**:
1. 实现 `protocols/engine.py`（2-4小时）
2. 更新 `SKILL.md`（1小时）
3. 运行端到端测试验证（1小时）

**预期效果**:
- 用户说"帮我用 Dan Koe 方法做一次重置"
- AI 自动展示第1步卡片
- 用户回答后，AI 自动推进到下一步
- 完成后展示漂亮的总结卡片

---

## 附录：关键代码位置

| 类别 | 文件路径 | 状态 |
|-----|---------|------|
| 前端卡片 | `apps/web/src/skills/lifecoach/cards/Protocol*.tsx` | ✅ 完成 |
| 卡片注册 | `apps/web/src/skills/lifecoach/cards/index.ts` | ✅ 完成 |
| 后端工具 | `apps/api/skills/lifecoach/tools/handlers.py` | ✅ 完成 |
| 工具定义 | `apps/api/skills/lifecoach/tools/tools.yaml` | ✅ 完成 |
| 协议配置 | `apps/api/skills/lifecoach/protocols/dankoe.yaml` | ✅ 存在 |
| Protocol 引擎 | `apps/api/skills/lifecoach/protocols/engine.py` | ❌ 缺失 |
| AI 指令 | `apps/api/skills/lifecoach/SKILL.md` | ⚠️ 需更新 |
| 前端渲染 | `apps/web/src/components/chat/ChatMessage.tsx` | ✅ 支持 |
| E2E 测试 | `apps/api/scripts/test_protocol_e2e.py` | ❌ 缺失 |

---

**报告生成**: Claude Code Ultra Analysis Mode
**下一步**: 等待用户确认实施方案
