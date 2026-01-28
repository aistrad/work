# Vibe 能力边界配置化 v2.0

## 设计目标

将能力边界规则从 Python 硬编码迁移到 YAML 配置，实现：
- 单一配置源（Single Source of Truth）
- 便于非开发者调整规则
- Phase 1 和 Phase 2 共用通用规则

## 核心原则

| 用户问题类型 | Phase 1 | Phase 2 |
|------------|---------|---------|
| **Profile 有数据** | 直接回答 | 直接回答 |
| **Skill 有能力** | 激活 | 用工具执行 |
| **体系外问题** | 友好回避 | 友好回避 |

## 配置架构

### 文件结构

```
apps/api/
├── skills/core/config/routing.yaml    # 配置文件
└── services/agent/
    ├── routing_config.py              # 配置加载 + inject_placeholders()
    └── skill_loader.py                # 使用配置（删除硬编码）
```

### routing.yaml 配置

```yaml
boundary_rules:
  shared: |
    ## 能力边界
    ### Profile 查询 → 直接回答
    ### 体系外问题 → 友好回避

  phase2: |
    ### Skill 边界意识
    **你现在是 {skill_id} 专家**
    ...
```

### 占位符使用

| 占位符 | 说明 | 使用位置 |
|-------|------|---------|
| `{boundary_rules_shared}` | 通用边界规则 | phase1_prompt, ready_for_analysis |
| `{boundary_rules_phase2}` | Phase 2 专属规则 | ready_for_analysis |
| `{skill_id}` | 当前 Skill ID | phase2 规则中 |

## API

### inject_placeholders()

```python
from services.agent.routing_config import inject_placeholders

# 基本用法
result = inject_placeholders(template, {"skill_id": "bazi"})

# 自动注入边界规则
result = inject_placeholders(sop_template, {"skill_id": skill_id})
```

### get_boundary_rules()

```python
from services.agent.routing_config import get_boundary_rules

rules = get_boundary_rules()
# {"shared": "...", "phase2": "..."}
```

## 验证场景

### Phase 1

| 输入 | 期望行为 |
|-----|---------|
| "我的生日" | 直接返回日期（从 Profile 读取） |
| "帮我分析八字" | `activate_skills(skills=["bazi"])` |
| "你是什么模型" | 友好回避 |

### Phase 2 (在 bazi 中)

| 输入 | 期望行为 |
|-----|---------|
| "我的生日是什么" | 直接返回（不调工具） |
| "继续分析" | 用 bazi 工具 |
| "帮我看星座" | `activate_skills(skills=["zodiac"])` |
| "你是什么模型" | 友好回避 |

## 变更记录

- v2.0 (2025-01-24): 初始配置化实现
  - 从 skill_loader.py 移除硬编码 boundary_text
  - 在 routing.yaml 添加 boundary_rules 配置
  - 实现 inject_placeholders() 函数
