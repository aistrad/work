# VibeLife V6.8 重构任务清单

> 基于架构文档的重构计划
> 目标：从 21 个路由文件精简到 6 个，彻底清理过期代码

---

## 当前状态 → 目标状态

```
当前 routes/ (21个文件):
├── chat_v5.py          ✅ 保留
├── chat.py             🗑️ 删除
├── context.py          🗑️ 删除
├── auth.py             🔄 → account.py
├── users.py            🔄 → account.py
├── identity.py         🔄 → account.py
├── guest.py            🔄 → account.py
├── payment.py          🔄 → commerce.py
├── billing.py          🔄 → commerce.py
├── entitlement.py      🔄 → commerce.py
├── bazi.py             🔄 → skills.py
├── zodiac.py           🔄 → skills.py
├── fortune.py          ✅ 已删除（统一迁入 skills.py）
├── onboarding.py       🔄 → skills.py
├── relationship.py     🔄 → skills.py (各skill自己的relationship)
├── report.py           🗑️ 删除
├── memories.py         🗑️ 删除
├── notifications.py    ✅ 保留
├── health.py           ✅ 保留
├── tools.py            ✅ 保留
└── knowledge_builder.py 🤔 内部工具，不暴露

目标 routes/ (6个文件):
├── chat_v5.py          # 对话入口 (CoreAgent)
├── skills.py           # Skill Gateway (配置驱动)
├── account.py          # 用户域 (auth+users+identity+guest)
├── commerce.py         # 支付域 (payment+billing+entitlement)
├── notifications.py    # 通知域
├── health.py           # 健康检查
└── tools.py            # 工具 Schema
```

---

## Phase 1: 基础设施

### Task 1.1: 创建 SkillServiceRegistry
```
文件: services/agent/skill_service_registry.py

功能:
- 类似 ToolRegistry 的自动发现机制
- @skill_service 装饰器
- execute(skill_id, action, args, context) 方法

依赖: 无
```

### Task 1.2: 创建 routes/skills.py
```
文件: routes/skills.py

端点:
- POST /api/v1/skills/{skill_id}/{action}
- GET /api/v1/skills/{skill_id}/services

依赖: Task 1.1
```

---

## Phase 2: Skill API 迁移

### Task 2.1: 创建 skills/bazi/services/api.py
```
从以下文件迁移:
- routes/bazi.py
- routes/fortune.py (已删除)
- routes/onboarding.py (bazi 部分)

端点:
- @skill_service("bazi", "chart") - 命盘
- @skill_service("bazi", "fortune") - 运势
- @skill_service("bazi", "kline") - K线
- @skill_service("bazi", "dayun") - 大运
- @skill_service("bazi", "relationship") - 八字合婚

依赖: Task 1.1
```

### Task 2.2: 创建 skills/zodiac/services/api.py
```
从以下文件迁移:
- routes/zodiac.py
- routes/fortune.py (已删除)

端点:
- @skill_service("zodiac", "chart") - 星盘
- @skill_service("zodiac", "transit") - 行运
- @skill_service("zodiac", "events") - 星象事件
- @skill_service("zodiac", "fortune") - 星座运势
- @skill_service("zodiac", "relationship") - 星座配对

依赖: Task 1.1
```

### Task 2.3: 创建 skills/tarot/services/api.py
```
端点:
- @skill_service("tarot", "draw") - 抽牌
- @skill_service("tarot", "spread") - 牌阵
- @skill_service("tarot", "interpret") - 解读

依赖: Task 1.1
```

### Task 2.4: 创建 skills/career/services/api.py
```
端点:
- @skill_service("career", "assess") - 职业评估
- @skill_service("career", "match") - 职业匹配

依赖: Task 1.1
```

---

## Phase 3: 平台服务合并

### Task 3.1: 创建 routes/account.py
```
合并文件:
- routes/auth.py
- routes/users.py
- routes/identity.py
- routes/guest.py

端点:
- POST /account/login
- POST /account/register
- POST /account/logout
- POST /account/refresh
- GET /account/profile
- PUT /account/profile
- POST /account/guest/session
- POST /account/identity/link
- GET /account/identity/providers
```

### Task 3.2: 创建 routes/commerce.py
```
合并文件:
- routes/payment.py
- routes/billing.py
- routes/entitlement.py

端点:
- POST /commerce/payment/create-session
- POST /commerce/payment/webhook
- GET /commerce/billing/subscription
- GET /commerce/billing/invoices
- GET /commerce/entitlement/check
- POST /commerce/entitlement/consume
```

---

## Phase 4: 彻底清理

### Task 4.1: 删除过期路由文件
```
删除:
- routes/chat.py (旧版���话)
- routes/context.py (已废弃)
- routes/report.py (不需要)
- routes/memories.py (不需要)
- routes/bazi.py (迁移后)
- routes/zodiac.py (迁移后)
- routes/fortune.py (迁移后)
- routes/onboarding.py (迁移后)
- routes/relationship.py (迁移后)
- routes/auth.py (合并后)
- routes/users.py (合并后)
- routes/identity.py (合并后)
- routes/guest.py (合并后)
- routes/payment.py (合并后)
- routes/billing.py (合并后)
- routes/entitlement.py (合并后)
```

### Task 4.2: 清理过期服务代码
```
检查并删除:
- services/vibe_engine/ 中的过期文件
- services/ 中未使用的模块
- stores/ 中未使用的 repo
```

### Task 4.3: 清理过期数据结构
```
检查数据库表:
- 删除未使用的表
- 清理 unified_profiles 中的过期字段
- 更新迁移脚本
```

### Task 4.4: 更新 main.py
```
修改:
- 移除旧路由 import (16个)
- 添加新路由 import (2个: skills, account, commerce)
- 初始化 SkillServiceRegistry
- 清理未使用的 import
```

### Task 4.5: 更新前端调用
```
修改:
- 更新 API 调用路径
- /bazi/* → /skills/bazi/*
- /zodiac/* → /skills/zodiac/*
- /auth/* → /account/*
- /payment/* → /commerce/payment/*
```

---

## 执行顺序

```
┌─────────────────────────────────────────────────────────────┐
│ Week 1: 基础设施 + Skill 迁移                                │
├─────────────────────────────────────────────────────────────┤
│ Day 1: Task 1.1 (SkillServiceRegistry)                      │
│ Day 2: Task 1.2 (routes/skills.py) + 测试                   │
│ Day 3: Task 2.1 (bazi/api.py)                               │
│ Day 4: Task 2.2 (zodiac/api.py)                             │
│ Day 5: Task 2.3, 2.4 (tarot, career) + 测试                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Week 2: 平台服务 + 清理                                      │
├─────────────────────────────────────────────────────────────┤
│ Day 1: Task 3.1 (account.py)                                │
│ Day 2: Task 3.2 (commerce.py) + 测试                        │
│ Day 3: Task 4.1, 4.2 (删除过期��件)                         │
│ Day 4: Task 4.3, 4.4 (清理数据结构 + main.py)               │
│ Day 5: Task 4.5 (前端更新) + 全面测试                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 检查清单

### Phase 1 完成标准
- [ ] SkillServiceRegistry 可以自动发现 skill
- [ ] /skills/{skill_id}/{action} 端点可用
- [ ] 单元测试通过

### Phase 2 完成标准
- [ ] 所有 bazi API 迁移完成
- [ ] 所有 zodiac API 迁移完成
- [ ] 前端可以通过��端点访问
- [ ] 旧端点仍然可用（兼容期）

### Phase 3 完成标准
- [ ] account.py 包含所有用户功能
- [ ] commerce.py 包含所有支付功能
- [ ] 认证流程正常
- [ ] 支付流程正常

### Phase 4 完成标准
- [ ] 所有过期文件已删除
- [ ] main.py 只注册新路由
- [ ] 无未使用的 import
- [ ] 数据库无冗余表
- [ ] 前端全部使用新 API
- [ ] 所有测试通过

---

## 风险缓解

| 风险 | 缓解措施 |
|------|----------|
| 前端依赖旧 API | Phase 2-3 期间保持旧端点，添加 deprecation warning |
| 数据丢失 | 清理前备份数据库 |
| 功能遗漏 | 每个 Task 完成后对比旧代码 |
| 测试不足 | 每个 Phase 完成后运行完整测试套件 |

---

## 相关文档

- [VibeLife V6.8 系统架构文档](./VibeLife%20V6.8%20系统架构文档.md)
- [SPEC-v6.md](./SPEC-v6.md)
