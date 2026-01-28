# Skill 架构升级计划

> 两阶段升级：统一配置框架 → Skill Store 平台化

## 输出文档

已输出到 `/docs/archive/v9/`:
1. `skill-routing-framework.md` - 统一配置框架（近期）
2. `skill-store-architecture.md` - Skill Store 平台化（长期）

---

## 阶段一：统一配置框架

### 核心模型

```yaml
skill_data: [...]   # 加载哪些 Skill 的数据
includes: [...]     # 加载哪些 Skill 的工具
```

### 改动文件

| 文件 | 改动 |
|------|------|
| `routing.yaml` | 迁入所有 Skill 配置 |
| `routing_config.py` | 新增查询函数 |
| `profile_cache.py` | 使用统一查询 |
| `tool_registry.py` | 支持 includes |
| `SKILL.md` | 简化为纯 prompt |

---

## 阶段二：Skill Store 平台化

### 实施路径

```
Phase 1: 用户私有 Skill（个人助手定制）
    ↓
Phase 2: Skill Store（创作者发布，用户订阅）
    ↓
Phase 3: 全功能型（可写 Python handler）
```

### 核心组件

1. **Skill Registry**：数据库存储 + 版本管理
2. **Skill Studio**：Web 创作工具
3. **Skill Store**：发现和分发平台
4. **Sandbox**：安全执行环境
5. **Review System**：审核系统
6. **Billing Split**：创作者分成

### 设计决策

- 能力边界：全功能型（可写 Python handler）
- 商业模式：平台抽成 30%
- 私有 Skill：个人助手定制

---

## 详细文档位置

- 统一配置框架：`/docs/archive/v9/skill-routing-framework.md`
- Skill Store 架构：`/docs/archive/v9/skill-store-architecture.md`
