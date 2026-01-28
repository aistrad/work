# Plan: Vibe 能力边界配置化 v2.0

## 设计文档
`docs/archive/v9/VIBE_CAPABILITY_BOUNDARY.md`

## 核心原则

| 用户问题类型 | Phase 1 | Phase 2 |
|------------|---------|---------|
| **Profile 有数据** | 直接回答 | 直接回答 |
| **Skill 有能力** | 激活 | 用工具执行 |
| **体系外问题** | 友好回避 | 友好回避 |

## 占位符方案

所有内容在 YAML 中定义，Python 只做"读取 → 替换占位符"。

### 修改文件

| 文件 | 改动 |
|-----|------|
| `routing.yaml` | 增加占位符 + `boundary_rules` 配置 |
| `routing_config.py` | `inject_placeholders()` 支持新占位符 |
| `skill_loader.py` | 删除硬编码 1101-1151 行 |

### 配置结构

```yaml
# routing.yaml

phase1_prompt: |
  # Vibe
  ...
  {boundary_rules_shared}    # 占位符
  ## 路由规则
  ...

sop_templates:
  ready_for_analysis: |
    ...
    {boundary_rules_shared}
    {boundary_rules_phase2}
    ...

boundary_rules:
  shared: |
    ## 能力边界
    ### Profile 查询 → 直接回答
    ### 体系外问题 → 友好回避

  phase2: |
    ### Skill 边界意识
    ...
```

## 验证

### Phase 1
- "我的生日" → 直接返回日期
- "帮我分析八字" → activate_skill

### Phase 2 (在 bazi 中)
- "我的生日是什么" → 直接返回（不调工具）
- "继续分析" → 用 bazi 工具
- "你是什么模型" → 友好回避
