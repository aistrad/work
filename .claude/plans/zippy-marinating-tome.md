# V9 LLM-First 架构落地计划

## 用户决策

- ✅ **完全删除 routing.yaml**
- ✅ **现在迁移协议到 lifecoach/rules/**
- ✅ **现在合并工具到 show**

## 执行步骤

### Step 1: 更新架构文档
`docs/archive/v9/ARCHITECTURE.md` 补充：
- routing.yaml 删除说明
- skill_loader 索引机制
- 订阅同步流程
- 协议迁移规范

### Step 2: 删除 routing.yaml
- 删除 `apps/api/skills/core/config/routing.yaml`
- 移除 routing_config.py 中的读取逻辑（或保持空回退）

### Step 3: skill_loader 实现索引
- `load_all_skill_metas()` 从 SKILL.md frontmatter 解析
- 内存缓存 + 版本控制

### Step 4: prompt_builder 重构
- Phase 1: Core 精简 + Skill metas 列表
- 移除 routing_config 依赖

### Step 5: 工具精简
- 移除 show_skill_intro / recommend_skills
- 统一到 show(type=skill_list|recommendation)

### Step 6: 协议迁移
- 新建 lifecoach/rules/dankoe.md
- 新建 lifecoach/rules/covey.md
- 新建 lifecoach/rules/yangming.md
- 新建 lifecoach/rules/liaofan.md

### Step 7: 验证
- E2E: "帮我看星座" → activate_skills
- E2E: "我能做什么" → show(type="skill_list")
- E2E: "Dan Koe" → lifecoach → 协议卡片

## 关键文件

| 文件 | 操作 |
|------|------|
| `docs/archive/v9/ARCHITECTURE.md` | 更新 |
| `apps/api/skills/core/config/routing.yaml` | 删除 |
| `apps/api/services/agent/skill_loader.py` | 修改 |
| `apps/api/services/agent/prompt_builder.py` | 修改 |
| `apps/api/services/agent/core.py` | 修改 |
| `apps/api/services/agent/routing_config.py` | 修改/弃用 |
| `apps/api/skills/lifecoach/rules/*.md` | 新建 |
