# Everything Claude Code 安装目录优化

## 目标

将仓库移到 `~/.claude/repos/everything-claude-code/`，并通过符号链接使配置生效。

## 当前状态

- **仓库位置**: `/home/aiscend/work/everything-claude-code/`
- **配置位置**: `~/.claude/` (复制的文件，已过时)
- **问题**: 仓库修改不会同步到 `~/.claude/`

## 实施步骤

### 步骤 1：创建目标目录

```bash
mkdir -p ~/.claude/repos
```

### 步骤 2：将自定义 skill 复制到仓库

```bash
# 12 个自定义 skill
cp -r ~/.claude/skills/better-auth-best-practices /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/notebooklm /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/skills-discovery /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/sync-work /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/ultra /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe-agent /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe-app /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe-native /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe-review /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/vibe-skill /home/aiscend/work/everything-claude-code/skills/
cp -r ~/.claude/skills/web-design-guidelines /home/aiscend/work/everything-claude-code/skills/
```

### 步骤 3：移动仓库到新位置

```bash
mv /home/aiscend/work/everything-claude-code ~/.claude/repos/
```

### 步骤 4：备份并删除旧配置

```bash
mv ~/.claude/commands ~/.claude/commands.bak
mv ~/.claude/skills ~/.claude/skills.bak
mv ~/.claude/agents ~/.claude/agents.bak
mv ~/.claude/rules ~/.claude/rules.bak
```

### 步骤 5：创建符号链接

```bash
ln -s ~/.claude/repos/everything-claude-code/commands ~/.claude/commands
ln -s ~/.claude/repos/everything-claude-code/skills ~/.claude/skills
ln -s ~/.claude/repos/everything-claude-code/agents ~/.claude/agents
ln -s ~/.claude/repos/everything-claude-code/rules ~/.claude/rules
```

### 步骤 6：验证

```bash
# 检查符号链接
ls -la ~/.claude/commands ~/.claude/skills

# 验证 frontmatter 已生效
head -5 ~/.claude/commands/learn.md

# 检查自定义 skill 存在
ls ~/.claude/skills/vibe*
```

### 步骤 7：清理备份（确认正常后）

```bash
rm -rf ~/.claude/commands.bak
rm -rf ~/.claude/skills.bak
rm -rf ~/.claude/agents.bak
rm -rf ~/.claude/rules.bak
```

---

## 最终目录结构

```
~/.claude/
├── repos/
│   └── everything-claude-code/    # 仓库（git 管理）
│       ├── commands/
│       ├── skills/
│       ├── agents/
│       ├── rules/
│       └── ...
├── commands -> repos/everything-claude-code/commands  # 符号链接
├── skills -> repos/everything-claude-code/skills      # 符号链接
├── agents -> repos/everything-claude-code/agents      # 符号链接
├── rules -> repos/everything-claude-code/rules        # 符号链接
├── settings.json
├── plugins/
└── ...
```

## 优点

1. **所有 Claude 相关内容集中在 `~/.claude/`**
2. **修改仓库即时生效**（符号链接）
3. **可通过 git 管理版本**
4. **自定义 skill 统一管理**

## 需要移动的自定义 Skill（12 个）

- better-auth-best-practices
- notebooklm
- skills-discovery
- sync-work
- ultra
- vibe
- vibe-agent
- vibe-app
- vibe-native
- vibe-review
- vibe-skill
- web-design-guidelines
