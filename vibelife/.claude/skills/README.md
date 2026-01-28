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

### 4. vibe-manus

**大任务并行处理框架**

使用 Planning with Files + Subagent 模式处理超出 context 窗口的任务。

**核心原理**：
1. **Planning with Files**: 用文件作为"外部记忆"，持久化中间状态
2. **Subagent 并行**: 每个 chunk 由独立 subagent 处理，有独立 context
3. **断点续传**: 支持 /compact 后或新会话继续未完成任务

**适用场景**：
- 知识抽取：大文件分段抽取 Cases/Scenarios
- 代码重构：大规模代码修改
- 批量处理：多文件批量转换/分析
- 长流程任务：需要多轮交互的复杂任务

**触发词**：`vibe-manus`, `大任务`, `并行处理`, `断点续传`, `manus`

**使用示例**：
```bash
# 手动触发
/vibe-manus 抽取《东方代码启示录》中的所有案例

# 继续上次未完成的任务
/vibe-manus --resume

# 强制重新开始
/vibe-manus --force-restart
```

**自动触发条件**：
- 文件大小 > 100KB
- 预估 tokens > 30K
- 任务需要处理 > 10 个独立单元

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
├── vibe-review/          # Codex CLI 自动代码审查、测试与修复
│   └── SKILL.md
└── vibe-manus/           # 大任务并行处理框架
    ├── SKILL.md
    └── templates/
        ├── WORK_STATE.json      # 工作状态模板
        └── SUBAGENT_PROMPT.md   # Subagent prompt 模板
```
