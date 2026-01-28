# 小红书自动化内容生产系统

> Claude Code 驱动的每日两更工作流

---

## 已完成

1. ✅ 创建运营手册（9个文件）
2. ✅ 创建自动化数据文件：
   - `automation/WORKFLOW.md` - 工作流说明
   - `automation/calendar.yaml` - 内容日历
   - `automation/topic-pool.yaml` - 选题池
   - `automation/published.yaml` - 发布记录
   - `automation/insights.yaml` - 洞察积累

---

## 待实施：/vibelife-xhs Skill

### 文件位置
`.claude/skills/vibelife-xhs/SKILL.md`

### 命令设计

| 命令 | 功能 | 使用场景 |
|------|------|---------|
| `/vibelife-xhs today` | 规划今日选题 + 生成下午内容 | 早上9点 |
| `/vibelife-xhs generate evening` | 生成晚上内容 | 下午发布后 |
| `/vibelife-xhs generate [topic]` | 指定选题生成 | 灵活生成 |
| `/vibelife-xhs review` | 录入数据 + 复盘 | 晚上 |
| `/vibelife-xhs weekly` | 周度复盘 | 每周日 |
| `/vibelife-xhs pool` | 查看/管理选题池 | 随时 |
| `/vibelife-xhs calendar` | 查看内容日历 | 随时 |

### 核心逻辑

#### /xhs today
1. 读取 `calendar.yaml` 检查今日是否已规划
2. 读取 `topic-pool.yaml` 获取选题池
3. 智能选题（考虑时间节点、Skill轮换、评论挖掘）
4. 读取模板和心法
5. 生成下午内容
6. HKR自检评分
7. 更新 `calendar.yaml`

#### /xhs review
1. 用户提供数据（views/likes/saves/comments）
2. 用户提供评论（文本或截图）
3. 分类评论
4. 提取"想更多"选题 → 加入 `topic-pool.yaml`
5. 四象限诊断
6. 更新 `published.yaml`
7. 输出洞察

---

## 实施步骤

1. 创建 `.claude/skills/vibelife-xhs/SKILL.md`
2. 创建 `.claude/skills/vibelife-xhs/rules/generation-prompt.md`（生成提示词）
3. 创建 `.claude/skills/vibelife-xhs/rules/review-prompt.md`（复盘提示词）

---

## 验证方式

1. 运行 `/vibelife-xhs today` 测试选题和生成
2. 运行 `/vibelife-xhs review` 测试复盘流程
3. 检查 yaml 文件是否正确更新
