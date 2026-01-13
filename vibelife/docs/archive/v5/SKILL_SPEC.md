# VibeLife Skill 系统规范

> Version: 5.1 | 2026-01-13

## 架构

```
CoreAgent
├── SkillLoader (加载 SKILL.md)
├── LLM Client (调用 LLM)
└── Tool System (执行工具)
        │
        ▼
System Prompt = Core Skill + Active Skill(s) + User Profile
```

## 目录结构

```
apps/api/skills/
├── core/           # Core Skill（始终加载）
│   └── SKILL.md
├── bazi/           # 八字 Skill
│   └── SKILL.md
├── zodiac/         # 星座 Skill
│   └── SKILL.md
├── career/         # 职业 Skill（待完善）
│   └── SKILL.md
└── tarot/          # 塔罗 Skill（待完善）
    └── SKILL.md
```

## SKILL.md 格式

```markdown
---
name: skill-name              # 必需，小写+连字符，≤32字符
description: |                # 必需，≤512字符
  技能描述。包含：能做什么、何时使用
version: "1.0"                # 可选
tools:                        # 可选
  - tool_name
---

# Skill 标题

## 能力范围
- 能力 1
- 能力 2

## 分析原则
### 原则 1
说明...

## 表达方式
- 语言风格指南

## 禁止事项
- 不能做的事

## 可用工具
- `tool_name` - 工具描述
```

## Skill 类型

| 类型 | 说明 | 加载时机 |
|------|------|---------|
| Core | 基础对话能力，Vibe 人格 | 始终加载 |
| Professional | 专业领域能力 | 按需加载 |

## 三层加载

| 层级 | 时机 | Token |
|------|------|-------|
| L1: Metadata | 启动时 | ~50/Skill |
| L2: Instructions | 激活时 | <3000 |
| L3: Resources | 按需 | 可变 |

## 工具类型

| 类型 | 说明 | 示例 |
|------|------|------|
| Shared | 所有 Skill 可用 | `show_report`, `request_info` |
| Skill-specific | 特定 Skill 专用 | `show_bazi_chart` |
| System | 系统内部 | `use_skill` |

## API

```python
from services.agent import load_skill, build_system_prompt, reload_skill

skill = load_skill("bazi")
prompt = build_system_prompt(active_skills=["bazi"], include_core=True)
reload_skill("bazi")  # 热重载
```

## CLI

```bash
cd /home/aiscend/work/vibelife/apps/api

python scripts/skill_creator.py create tarot      # 创建
python scripts/skill_creator.py validate bazi    # 验证
python scripts/skill_creator.py list             # 列出
python scripts/skill_creator.py reload bazi      # 热重载
```

## 编写指南

**要做**：
- 清晰的能力边界
- 具体的分析原则（含示例）
- 工具使用说明

**避免**：
- 过度解释（Claude 已知常识）
- 多选项无默认
- 术语堆砌
