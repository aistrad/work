# Proactive 模块

主动触达用户，增强粘性和业务转化。

## 文档索引

| 文档 | 说明 |
|-----|------|
| [SPEC.md](./SPEC.md) | 核心设计规范 |
| [reminders-schema.yaml](./reminders-schema.yaml) | reminders.yaml 配置 Schema |
| ref/ | 参考资料 |

## 核心特性

1. **订阅感知** - 根据 Skill 订阅状态决定是否推送
2. **配置独立** - reminders.yaml 独立于 SKILL.md
3. **Skill 级开关** - 简化用户设置
4. **对话引导** - 推送提供一键开始对话入口

## 快速配置

在 `apps/api/skills/{skill_id}/reminders.yaml` 中配置：

```yaml
skill_id: bazi
enabled: true

reminders:
  - id: daily_fortune
    name: 每日运势
    trigger:
      type: time_based
      schedule: "0 4 * * *"
    content:
      generator: rules/daily-fortune.md
      suggested_prompt: "想了解今天的运势详情？"
      quick_actions:
        - label: "今日宜忌"
          prompt: "今天适合做什么？"
```

## 关联模块

- [Skill Management](../skillmanagement/SPEC.md) - 订阅状态来源
- [CoreAgent](../coreagent/) - LLM 内容生成
