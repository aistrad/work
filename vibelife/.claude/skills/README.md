# VibeLife Skills

## 概述

VibeLife 项目的 Claude Code Skills 集合。

## 可用 Skills

### 1. vibelife-skill

**一站式知识库与专家系统构建工具**

整合资料搜寻、格式转换、向量化入库、SOP提取、Skill优化的完整流程。

**五个阶段**：
1. **Phase 1: CURATE** - 资料搜寻与获取
2. **Phase 2: CONVERT** - 格式转换与清洗
3. **Phase 3: VECTORIZE** - 向量化入库
4. **Phase 4: EXTRACT** - 专家知识提取
5. **Phase 5: OPTIMIZE** - 迭代优化

**触发词**：`vibelife-skill`, `建库`, `建skill`, `知识库构建`, `skill构建`

**使用示例**：
```bash
# 全流程执行
vibelife-skill --theme career --input "职业规划书单"

# 单阶段执行
vibelife-skill --phase vectorize --theme career --input /path/to/converted/
vibelife-skill --phase extract --theme career
```

### 2. vibelife-test

**测试环境管理工具**

快速启动/停止/查看测试环境状态。

**端口**：
- API: 8100
- Web: 8232

**触发词**：`vibelife-test`, `测试环境`, `启动测试`, `停止测试`

### 3. vibe-review

**Codex CLI 驱动的自动代码审查、测试与修复工具**

收集当前对话上下文中的代码，传给 Codex 审查、测试与修复，后台循环直到无错误。

**工作流程**：
1. 收集对话上下文中涉及的代码文件
2. 组装 Agent Prompt，使用 Task 工具后台启动（`run_in_background: true`）
3. Agent 每轮调用 `codex exec --full-auto` 执行审查 → 测试 → 修复（最多 5 轮）
4. 任务完成后输出报告，用户通过 `/tasks` 查看

**触发词**：`vibe-review`, `代码审查`, `review`, `codex review`

**使用示例**：
```bash
# 审查对话中涉及的代码
/vibe-review

# 指定额外文件
/vibe-review apps/api/services/identity/auth.py

# 指定审查重点
/vibe-review "检查安全性"
```

## 目录结构

```
/data/vibelife/knowledge/{theme}/
├── candidates/           # 候选文件（按来源分类）
│   ├── github/
│   ├── archive_org/
│   └── other/
├── source/               # 原始文件（PDF/EPUB等）
└── converted/            # 转换后的 MD 文件
    └── *.converted.md    # 统一命名格式
```

## Skill 文件位置

```
/home/aiscend/work/vibelife/.claude/skills/
├── README.md             # 本文件
├── vibelife-skill/       # 一站式知识库构建工具
│   └── SKILL.md
├── vibelife-test/        # 测试环境管理工具
│   └── SKILL.md
└── vibe-review/          # Codex CLI 自动代码审查、测试与修复
    └── SKILL.md
```
