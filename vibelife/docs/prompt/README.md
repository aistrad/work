# CoreAgent Prompt 导出

> 导出时间: 2026-01-13

本目录包含 CoreAgent 系统的所有 prompt 文件。

## 目录结构

```
prompt/
├── README.md                    # 本文件
├── CORE_AGENT.md               # CoreAgent 核心逻辑说明
├── skills/
│   ├── core.md                 # Core Skill - 生命对话者
│   ├── bazi.md                 # Bazi Skill - 八字命理
│   ├── zodiac.md               # Zodiac Skill - 西方占星
│   ├── career.md               # Career Skill - 职业发展
│   └── tarot.md                # Tarot Skill - 塔罗解读
```

## Prompt 组装流程

CoreAgent 的 system prompt 按以下顺序组装：

1. **Core Skill** (始终加载) - 定义 Vibe 的人格和基础能力
2. **技能触发规则** (无激活技能时) - 动态生成的关键词触发规则
3. **专业 Skill** (激活后) - bazi/zodiac/career/tarot
4. **用户上下文**:
   - birth_info (出生信息)
   - identity_prism (身份棱镜)
   - life_context (生活上下文)
   - portrait (近期画像 - Hot Memory)
   - recent_insights (洞察记忆 - Cold Memory)
   - skill_data (命盘数据)

## 工具系统

### use_skill 工具 (路由工具)

当无技能激活时，CoreAgent 提供 `use_skill` 工具让 LLM 自主选择技能：

```json
{
  "name": "use_skill",
  "parameters": {
    "skills": ["bazi", "zodiac", "career", "tarot"],
    "topic": ["career", "relationship", "fortune", "health", "self", "general"],
    "birth_info_provided": boolean
  }
}
```

### 技能专属工具

每个技能激活后会加载对应的展示工具：

| Skill | 工具 |
|-------|------|
| bazi | show_bazi_chart, show_bazi_fortune, show_bazi_kline |
| zodiac | show_zodiac_chart, show_zodiac_transit, show_zodiac_synastry |
| career | show_career_analysis, show_personality_profile |
| tarot | show_tarot_card |
| 通用 | show_report, show_insight |

## 关键设计原则

1. **工具定义 ≠ 工具调用** - 必须在 SKILL.md 中明确工具调用规则
2. **Hybrid Skill Switching** - 前端可指定技能，也可让 LLM 自主选择
3. **工具调用决策框架**:
   - 信息完整 + 意图明确 → 立即调用工具
   - 缺少信息 → 对话询问
   - 意图模糊 → 对话澄清
