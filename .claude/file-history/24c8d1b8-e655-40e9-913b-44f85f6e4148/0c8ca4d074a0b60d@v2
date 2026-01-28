# Skill Management System

> 让用户发现、订阅、管理 Skill 的完整系统设计

---

## 文档结构

```
docs/components/skillmanagement/
├── README.md                    # 本文件 - 索引和快速开始
├── SPEC.md                      # 核心规格文档 - 系统架构和设计
├── skill-metadata-schema.yaml   # Skill 元数据 Schema 定义
├── ui-components.md             # 前端 UI 组件设计
├── api-reference.md             # API 端点完整文档
└── migration.sql                # 数据库迁移脚本
```

---

## 快速概览

### 设计决策

| 决策点 | 选择 |
|--------|------|
| 商业模型 | 混合模式 - core 始终激活，default 免费可取消，professional 需订阅 |
| 发现入口 | 四入口全覆盖：市场页面 + 对话推荐 + 设置管理 + 首页卡片 |
| 订阅粒度 | Skill 级别 - 整体订阅/取消 |
| 推送控制 | 简单开关 - 整体开/关某 Skill 的推送 |

### Skill 分类

| 分类 | Skills | 特点 |
|------|--------|------|
| **Core** | core | 始终激活，不可取消 |
| **Default** | mindfulness, lifecoach | 默认激活，免费，可取消 |
| **Professional** | bazi, zodiac, tarot, jungastro, career | 需订阅，有试用次数 |

---

## 实施清单

### Phase 1: 数据模型 (1 天)

- [ ] 执行 `migration.sql` 创建表
- [ ] 创建 `stores/skill_subscription_repo.py`
- [ ] 更新 SkillLoader 解析 SKILL.md 中的新字段

```bash
# 执行迁移
psql $VIBELIFE_DB_URL -f docs/components/skillmanagement/migration.sql
```

### Phase 2: API 开发 (2 天)

- [ ] 扩展 `routes/skills.py` 添加订阅管理端点
- [ ] 创建 `services/skill_recommendation.py`
- [ ] 集成到 `main.py` 路由

**新增端点**:
```
GET  /api/v1/skills/subscriptions
POST /api/v1/skills/{skill_id}/subscribe
POST /api/v1/skills/{skill_id}/unsubscribe
POST /api/v1/skills/{skill_id}/push
GET  /api/v1/skills/recommendations
GET  /api/v1/skills/featured
```

### Phase 3: 前端开发 (3 天)

- [ ] 创建 `components/skill/SkillCard.tsx` (4 变体)
- [ ] 创建 `app/skills/page.tsx` Skill 市场页面
- [ ] 扩展 `settings/page.tsx` 添加 Skill 管理区块
- [ ] 创建 `hooks/useSkillSubscription.ts`
- [ ] 在 `ChatContainer` 中集成推荐卡片

### Phase 4: 主动模块集成 (1 天)

- [ ] 修改 `ProactiveEngine._should_send_to_user()` 检查订阅状态
- [ ] 更新各 Skill 的 `reminders.yaml` 添加 subscription 配置

### Phase 5: 推荐算法 (2 天)

- [ ] 实现触发词匹配
- [ ] 集成情绪检测
- [ ] 首页推荐卡片

---

## 关键文件修改

### 后端

| 文件 | 修改内容 |
|------|----------|
| `routes/skills.py` | 添加订阅管理端点 |
| `stores/skill_subscription_repo.py` | 新建，数据库操作 |
| `services/skill_recommendation.py` | 新建，推荐算法 |
| `services/agent/skill_loader.py` | 解析新的 metadata 字段 |
| `services/proactive/engine.py` | 集成订阅检查 |

### 前端

| 文件 | 修改内容 |
|------|----------|
| `components/skill/*.tsx` | 新建，Skill 相关组件 |
| `app/skills/page.tsx` | 新建，Skill 市场页面 |
| `app/settings/page.tsx` | 添加 Skill 管理区块 |
| `hooks/useSkillSubscription.ts` | 新建，订阅管理 Hook |
| `components/chat/ChatContainer.tsx` | 集成推荐卡片 |

### 配置

| 文件 | 修改内容 |
|------|----------|
| `skills/*/SKILL.md` | 添加 category, pricing, showcase 字段 |
| `skills/*/reminders.yaml` | 添加 subscription 配置 |

---

## SKILL.md 更新示例

每个 Skill 的 `SKILL.md` 需要更新 frontmatter：

```yaml
---
id: bazi
name: 八字命理
version: 3.0.0
description: 融汇四大经典的八字命理大师

# 新增字段
category: professional
icon: "🔮"
color: "#D4A574"

pricing:
  type: premium
  trial_messages: 3

showcase:
  tagline: 洞察命运玄机，把握人生方向
  highlights:
    - 融汇四大经典
    - 个性化解读
    - 运势趋势分析
  demo_prompts:
    - 帮我看看命盘
    - 我今年运势如何

subscription:
  can_unsubscribe: true
  push_default: true
---
```

---

## 验收标准

### 功能验收

- [ ] 用户可以在 Skill 市场页面浏览所有 Skill
- [ ] 用户可以订阅/取消订阅 Professional Skill
- [ ] 用户可以取消订阅 Default Skill（mindfulness, lifecoach）
- [ ] Core Skill 无法取消订阅
- [ ] 用户可以开关每个 Skill 的推送
- [ ] 对话中能智能推荐相关 Skill
- [ ] 首页显示推荐 Skill 卡片
- [ ] 设置页面可以管理所有订阅

### 性能验收

- [ ] Skill 列表 API < 200ms
- [ ] 订阅操作 API < 100ms
- [ ] 推荐 API < 500ms

### 兼容性验收

- [ ] 现有用户自动初始化默认订阅
- [ ] 不影响现有对话功能
- [ ] 不影响现有推送功能

---

## 联系

设计者：Claude (Ultra Deep Analysis Mode)
日期：2026-01-19
