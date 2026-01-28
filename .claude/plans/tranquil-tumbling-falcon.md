# 修复所有 Skill 日期占位符 + 最佳实践文档化

## 问题根因

System Prompt 没有告诉 LLM 当前日期，LLM 用知识截止日期（2024）生成文字。

## 修改清单

### 1. 核心：`prompt_builder.py` 增强占位符

**文件**：`apps/api/services/agent/prompt_builder.py` (L23-30)

```python
from datetime import datetime

def inject_placeholders(template: str, context: Optional[Dict[str, Any]] = None) -> str:
    if not template:
        return template
    replacements = dict(context or {})
    # 系统占位符
    replacements["current_year"] = str(datetime.now().year)
    replacements["current_date"] = datetime.now().strftime("%Y-%m-%d")
    result = template
    for k, v in replacements.items():
        result = result.replace("{" + k + "}", str(v))
    return result
```

### 2. 需要日期的 Skill 添加占位符

在以下 SKILL.md 的 frontmatter 后添加：

```markdown
## 系统信息

当前日期：{current_date}，当前年份：{current_year}年
```

**需要修改的 Skill**：
- `bazi/SKILL.md` - 大运流年分析
- `zodiac/SKILL.md` - 星座运势
- `lifecoach/SKILL.md` - 每日签到、习惯追踪
- `tarot/SKILL.md` - 运势解读（可选）
- `jungastro/SKILL.md` - 行运分析

**不需要的 Skill**（与日期无关）：
- `core/SKILL.md` - 核心路由
- `vibe_id/SKILL.md` - 人格分析
- `psych/SKILL.md` - 心理咨询
- `career/SKILL.md` - 职业分析
- `synastry/SKILL.md` - 合盘分析
- `mindfulness/SKILL.md` - 冥想

### 3. 更新 vibelife CLAUDE.md

添加到 `CLAUDE.md` 的 LLM-First 架构部分：

```markdown
#### 系统占位符

| 占位符 | 值 | 用途 |
|-------|---|-----|
| `{current_year}` | 2026 | 避免 LLM 用知识截止日期 |
| `{current_date}` | 2026-01-25 | 日期相关判断 |

在需要日期的 SKILL.md 中添加：
```markdown
## 系统信息
当前日期：{current_date}，当前年份：{current_year}年
```
```

### 4. 更新 vibe-agent Skill

**文件**：`~/.claude/skills/vibe-agent/SKILL.md`

在"常见问题与解决方案"部分添加：

```markdown
### 7. LLM 使用错误年份

**问题**：LLM 生成的文字使用 2024 年而非当前年份。

**原因**：LLM 依赖知识截止日期，不知道当前时间。

**解决方案**：通过占位符注入当前日期

```python
# prompt_builder.py
def inject_placeholders(template, context=None):
    replacements = dict(context or {})
    replacements["current_year"] = str(datetime.now().year)
    replacements["current_date"] = datetime.now().strftime("%Y-%m-%d")
    ...
```

在 SKILL.md 中使用：
```markdown
## 系统信息
当前日期：{current_date}，当前年份：{current_year}年
```
```

## 验证

1. 重启 API
2. 测试 bazi："看看我今年的运势" → 确认使用 2026 年
3. 测试 zodiac："今天运势" → 确认使用 2026-01-25
4. 测试 lifecoach："签到" → 确认日期正确
