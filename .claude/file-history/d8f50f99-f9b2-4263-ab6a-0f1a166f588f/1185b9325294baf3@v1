---
id: content-generation
name: 内容生成
impact: HIGH
impactDescription: 直接产出 Skill 文件，决定最终质量
tags: 生成, SKILL.md, rules, tools, 模板
---

# 内容生成规则

## 适用场景

- 完成架构设计后
- 开始生成 Skill 文件内容
- 需要遵循格式规范

## 分析要点

| 步骤 | 生成内容 | 规范要求 | 优先级 |
|-----|---------|---------|-------|
| 1 | SKILL.md | < 200 行，含能力索引 | 必须 |
| 2 | rules/*.md | Frontmatter + 分析要点表 | 必须 (标准/复杂) |
| 3 | tools/tools.yaml | 工具定义 | 推荐 (复杂) |
| 4 | reference/*.md | 参考文档 | 可选 |

### SKILL.md 生成规范

**Frontmatter**:
```yaml
---
name: {kebab-case, max 64 chars}
description: |
  {一句话描述}。触发词：{词1}、{词2}、{词3}。
---
```

**必须包含的章节**:

| 章节 | 行数限制 | 内容 |
|-----|---------|------|
| 专家身份 | ~20 行 | 核心理念、知识来源 |
| 核心能力索引 | ~30 行 | 能力表格 (能力/优先级/规则文件/触发场景) |
| 工具快速参考 | ~30 行 | 工具表格 (工具/用途/何时调用) |
| 知识检索策略 | ~20 行 | 检索模式表格 |
| 服务原则 | ~15 行 | 5 条原则 |
| 伦理边界 | ~20 行 | 禁止事项 + 输出原则 |
| 详细文档 | ~10 行 | 指向 rules/ 和 reference/ 的链接 |

**能力索引表格模板**:
```markdown
| 能力 | 优先级 | 规则文件 | 触发场景 |
|-----|-------|---------|---------|
| {能力名} | CRITICAL/HIGH/MEDIUM/LOW | `rules/{file}.md` | {触发场景} |
```

### Rule 文件生成规范

**Frontmatter**:
```yaml
---
id: {kebab-case}
name: {中文名称}
impact: CRITICAL/HIGH/MEDIUM/LOW
impactDescription: {影响说明}
tags: {触发词列表，逗号分隔}
---
```

**必须包含的章节**:

```markdown
# {能力名称}规则

## 适用场景
[触发场景描述]

## 分析要点
| 步骤 | 分析要点 | 检索/操作 | 优先级 |
|-----|---------|----------|-------|
| 1 | {要点} | {query/操作} | 必须/推荐/可选 |

## 输出要求
1. **必须产出**: ...
2. **格式要求**: ...
3. **下一步引导**: ...

## 常见问题
[FAQ，可选]
```

### Tools.yaml 生成规范 (可选)

```yaml
tools:
  - name: {snake_case}
    description: {用途描述}
    type: display/search/collect/calculate
    parameters:
      - name: {参数名}
        type: string/integer/boolean
        required: true/false
        description: {参数说明}
    when_to_call: {调用时机}
```

## 输出要求

1. **输出格式**:
   ```
   === FILE: skill-name/SKILL.md ===
   [内容]

   === FILE: skill-name/rules/ability.md ===
   [内容]
   ```

2. **质量检查**:
   - SKILL.md < 200 行
   - 每个 rule 文件有完整 frontmatter
   - 分析要点表格完整
   - 无硬编码的领域知识 (应放 reference/)

3. **下一步引导**:
   - 生成完成后进入「验证优化」能力
   - 提示用户保存文件到 `~/.claude/skills/{skill-name}/`

## 自由度校准

生成内容时，根据任务特性调整指令具体程度：

| 自由度 | 适用场景 | 指令风格 |
|-------|---------|---------|
| 高 | 多种有效方法、依赖上下文 | 文字指导，允许变化 |
| 中 | 有首选模式、允许调整 | 模板 + 参数 |
| 低 | 脆弱操作、必须精确 | 精确脚本，禁止修改 |

**判断问题**:
1. 变化的代价？低→高自由度，高→低自由度
2. 有多少有效方法？多→高自由度，一个→低自由度
3. 可逆吗？是→可接受高自由度，否→低自由度更安全
