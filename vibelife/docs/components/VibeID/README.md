# VibeID 模块

用户身份核心 - VibeLife 的"数字身份证"。

## 文档索引

| 文档 | 说明 |
|-----|------|
| [SPEC.md](./SPEC.md) | 核心设计规范 |
| [DATA-MODEL.md](./DATA-MODEL.md) | 数据模型设计 |
| [MIGRATION.md](./MIGRATION.md) | 迁移方案 |

## 核心定位

VibeID 是 VibeLife 北极星愿景"让每一个人，都拥有一个真正懂自己的存在"的**具象化载体**。

### 从 Skill 到身份核心

| 维度 | v6 (当前) | v7 (目标) |
|-----|----------|----------|
| 角色 | 派生 Skill | **用户身份核心** |
| 数据位置 | `skill_data.vibe_id` | `unified_profiles.vibe_id` |
| 生命周期 | 一次计算 | **持续演化** |
| 整合度 | 独立展示 | **全栈整合** |
| 呈现 | 四维+12原型 | **单一主原���** |

## 核心特性

1. **身份核心** - 所有 Skill 围绕 VibeID 展开，AI 始终"懂你"
2. **动态演化** - 对话驱动 + 周期驱动 + 用户驱动的混合演化
3. **全栈整合** - Prompt 注入 + Proactive 联动 + 数据层融合
4. **简化呈现** - 单一主原型 + 人格金句，降低理解门槛

## 关联模块

- [CoreAgent](../coreagent/) - Prompt 层注入 VibeID 摘要
- [Proactive](../proactive/) - 演化事件触发推送
- [Skill Management](../skillmanagement/) - VibeID 作为 Core 层能力
