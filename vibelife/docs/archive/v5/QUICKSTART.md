# VibeLife Skill 快速入门指南

## 5 分钟创建你的第一个 Skill

### 步骤 1: 使用 Skill Creator

```bash
cd /home/aiscend/work/vibelife/apps/api
python scripts/skill_creator.py create tarot --display-name "塔罗牌" --description "塔罗牌占卜分析"
```

输出:
```
✓ 创建 Skill: tarot
ℹ   目录: apps/api/skills/tarot
ℹ   文件: apps/api/skills/tarot/SKILL.md

下一步:
  1. 编辑 SKILL.md 完善内容
  2. 在 services/vibe_engine/tools.py 中添加工具定义
  3. 运行 python skill_creator.py validate tarot 验证
```

### 步骤 2: 编辑 SKILL.md

```markdown
---
name: tarot
description: |
  塔罗牌占卜分析专家。提供牌阵解读、牌义分析、指引建议。
  当用户询问塔罗、占卜、抽牌等话题时使用。
---

# Tarot Skill - 塔罗牌占卜

## 能力范围

- 单牌解读
- 三牌阵（过去-现在-未来）
- 凯尔特十字牌阵
- 牌义深度分析

## 分析原则

### 以问题为导向

先理解用户的问题，再选择合适的牌阵。

### 正逆位解读

- 正位：能量顺畅流动
- 逆位：能量受阻或内化

### 整体解读

不孤立看单张牌，要看牌与牌之间的关系。

## 表达方式

- 用故事性的语言描述牌面
- 结合用户的具体问题
- 给出可操作的建议

## 禁止事项

- 不做绝对化预测
- 不恐吓用户
- 不替用户做决定

## 可用工具

- `show_tarot_spread` - 展示牌阵
- `show_tarot_card` - 展示单张牌
- `search_knowledge` - 检索塔罗知识库
```

### 步骤 3: 添加工具定义

编辑 `services/vibe_engine/tools.py`:

```python
# Tarot 专属工具
SHOW_TAROT_SPREAD_TOOL = {
    "type": "function",
    "function": {
        "name": "show_tarot_spread",
        "description": "展示塔罗牌阵",
        "parameters": {
            "type": "object",
            "properties": {
                "spread_type": {
                    "type": "string",
                    "enum": ["single", "three_card", "celtic_cross"],
                    "description": "牌阵类型"
                },
                "question": {
                    "type": "string",
                    "description": "用户的问题"
                }
            },
            "required": ["spread_type"]
        }
    }
}

TAROT_TOOLS = [SHOW_TAROT_SPREAD_TOOL]

# 更新 get_tools_for_skill 函数
def get_tools_for_skill(skill: str) -> List[Dict[str, Any]]:
    tools = SHARED_TOOLS.copy()
    if skill == "bazi":
        tools.extend(BAZI_TOOLS)
    elif skill == "zodiac":
        tools.extend(ZODIAC_TOOLS)
    elif skill == "tarot":  # 新增
        tools.extend(TAROT_TOOLS)
    return tools
```

### 步骤 4: 更新 use_skill 工具

编辑 `services/agent/core.py`:

```python
USE_SKILL_TOOL = {
    "type": "function",
    "function": {
        "name": "use_skill",
        "parameters": {
            "type": "object",
            "properties": {
                "skills": {
                    "type": "array",
                    "items": {
                        "type": "string",
                        "enum": ["bazi", "zodiac", "tarot"]  # 添加 tarot
                    }
                },
                # ...
            }
        }
    }
}
```

### 步骤 5: 验证

```bash
python scripts/skill_creator.py validate tarot
```

输出:
```
✓ Skill 'tarot' 验证通过
```

### 步骤 6: 测试

```bash
# 启动 API 服务
cd apps/api && python main.py

# 测试对话
curl -X POST http://localhost:8000/chat/v5/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "帮我抽一张塔罗牌"}'
```

## 进阶：添加前端支持

### 1. 创建 Skill 配置

`apps/web/src/skills/tarot/config.ts`:

```typescript
export const tarotConfig: SkillConfig = {
  id: "tarot",
  name: "塔罗牌",
  icon: Sparkles,
  theme: { primary: "#8B5CF6" },
  quickPrompts: ["帮我抽一张牌", "三牌阵看看我的感情"]
};
```

### 2. 创建工具组件

`apps/web/src/skills/tarot/tools/show-tarot-spread.tsx`:

```typescript
export const showTarotSpreadTool: ToolDefinition = {
  name: "show_tarot_spread",

  render(result) {
    return <TarotSpreadCard spread={result} />;
  },

  toModelOutput(result) {
    return `已展示${result.spreadType}牌阵`;
  }
};
```

## 常见问题

### Q: Skill 没有被加载？

检查:
1. SKILL.md 文件是否存在
2. frontmatter 格式是否正确
3. name 字段是否与目录名一致

### Q: 工具没有被调用？

检查:
1. 工具是否在 `get_tools_for_skill` 中注册
2. SKILL.md 中是否说明了工具用途
3. use_skill 的 enum 是否包含新 Skill

### Q: 如何调试？

```python
from services.agent import load_skill, build_system_prompt

# 检查 Skill 加载
skill = load_skill("tarot")
print(skill.name, skill.description)

# 检查 System Prompt
prompt = build_system_prompt(["tarot"])
print(prompt)
```

## 下一步

- 阅读 [VIBELIFE_SKILL_SPEC.md](VIBELIFE_SKILL_SPEC.md) 了解完整规范
- 阅读 [VIBELIFE_AGENT_SPEC.md](VIBELIFE_AGENT_SPEC.md) 了解 Agent 架构
- 参考现有 Skill: `skills/bazi/SKILL.md`, `skills/zodiac/SKILL.md`
