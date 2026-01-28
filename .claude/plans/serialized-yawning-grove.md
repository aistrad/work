# VibeLife 小红书内容创作运营指南手册 - 实施计划

## 概述

为 VibeLife 设计一份标准级运营手册，核心目标：**综合运营**（品牌认知 → 社群 → 付费转化），变现路径为 **App 引流**。

## 手册结构（9章 + 附录）

```
docs/operations/xiaohongshu/
├── README.md                      # 总览与快速导航
├── 01-account-setup/              # 账号搭建
│   ├── positioning.md             # 定位：AI心理成长陪伴师
│   ├── seven-essentials.md        # 七件套配置模板
│   └── warming-up.md              # 养号规则(3-5天)
├── 02-content-matrix/             # 内容矩阵
│   ├── skill-mapping.md           # 10个Skill→内容映射
│   ├── categories.md              # 四大方向(心理30%/教练25%/情感25%/命理20%)
│   └── calendar-template.md       # 周更7篇日历
├── 03-creation-guide/             # 创作指南
│   ├── hook-formula.md            # 爆款公式：数字+预期+简单
│   ├── copywriting-templates.md   # 10种正文模板
│   └── visual-guidelines.md       # 封面规范(品牌色/尺寸)
├── 04-publishing-rules/           # 发布规范
│   ├── checklist.md               # 发帖前检查清单
│   ├── timing.md                  # 最佳时间(午休/晚高峰)
│   └── compliance.md              # 敏感词规避
├── 05-engagement-growth/          # 互动增长
│   ├── comment-ops.md             # 评论区置顶+回复策略
│   └── dm-conversion.md           # 私信转化SOP
├── 06-app-conversion/             # App引流
│   ├── soft-implant.md            # 自然植入3层级
│   └── hook-design.md             # 钩子设计(免费测试/完整报告)
├── 07-data-optimization/          # 数据复盘
│   ├── metrics.md                 # 核心指标(点赞率3%及格/10%优秀)
│   └── pentagon.md                # 五边形诊断
├── 08-cases/                      # 案例库(按Skill分类)
│   ├── psych-cases.md             # 心理:认知扭曲/焦虑管理
│   ├── lifecoach-cases.md         # 教练:DanKoe/Covey/阳明/了凡
│   ├── zodiac-cases.md            # 星座:配对/运势/水逆
│   └── tarot-cases.md             # 塔罗:每日抽牌/感情占
├── 09-sop-workflows/              # SOP工作流
│   ├── daily-ops.md               # 日常运营流程
│   └── content-production.md      # 内容批量生产流程
└── appendix/
    ├── title-formulas.md          # 50+标题公式
    ├── tools.md                   # 工具推荐(Canva/剪映)
    └── competitors.md             # 对标账号列表
```

## 实施步骤

### Step 1: 创建目录结构
```bash
mkdir -p docs/operations/xiaohongshu/{01..09}-*/templates
mkdir -p docs/operations/xiaohongshu/appendix
mkdir -p assets/xhs/{templates,covers,brand}
```

### Step 2: 核心文件编写（优先级顺序）

| 优先级 | 文件 | 内容要点 |
|-------|------|---------|
| P0 | README.md | 手册入口，快速导航 |
| P0 | 01-account-setup/*.md | 从零起号完整流程 |
| P0 | 02-content-matrix/skill-mapping.md | 10个Skill→内容素材转换 |
| P1 | 03-creation-guide/*.md | 爆款公式+模板库 |
| P1 | 06-app-conversion/*.md | 引流策略（核心变现） |
| P2 | 08-cases/*.md | 按Skill分类的案例库 |
| P2 | 其他章节 | 发布/互动/数据/SOP |

### Step 3: 模板资源准备

需要创建的模板：
1. 简介模板（3套风格）
2. 标题公式库（50+公式）
3. 正文模板（10种类型：自测/干货/星座/塔罗等）
4. 封面检查清单
5. 内容日历（周/月）
6. 私信话术库
7. 日报/周报模板

### Step 4: 案例库设计

按Skill设计案例：

| Skill | 案例数 | 内容方向 |
|-------|-------|---------|
| psych | 3 | 认知扭曲/焦虑管理/情绪调节 |
| lifecoach | 4 | DanKoe重置/Covey习惯/阳明心学/了凡改命 |
| zodiac | 5 | 性格/运势/配对/水逆/月相 |
| tarot | 3 | 每日/感情/知识 |
| bazi | 3 | 五行/性格/运势 |
| synastry | 2 | 星座配对/八字合婚 |
| vibe_id | 2 | 12原型/性格解码 |

## 关键文件路径

| 用途 | 路径 |
|-----|------|
| Skill内容素材 | apps/api/skills/*/SKILL.md |
| 小红书参考 | /home/aiscend/work/docs/xhs/ref/*.md |
| 产品定位 | docs/archive/v8/ARCHITECTURE.md |

## 从零起号时间线

| 阶段 | 时间 | 目标 |
|-----|------|------|
| 准备期 | Week 1 | 注册+七件套+养号+首批内容 |
| 冷启动 | Week 2-4 | 500粉+1篇1000赞爆款 |
| 成长期 | Month 2-3 | 5000粉+私信转化+社群 |
| 稳定期 | Month 4+ | App转化成熟 |

## 验证方式

1. **文档完整性**：所有9章+附录文件存在且非空
2. **模板可用性**：标题公式、正文模板可直接使用
3. **案例实操性**：案例包含完整的标题/正文/引流点
4. **流程可执行**：SOP清单可按步骤执行

## 对标账号研究（新增）

实施时需在小红书搜索并分析以下类型账号：

| 赛道 | 搜索关键词 | 分析维度 |
|-----|-----------|---------|
| 心理成长 | 心理博主、情绪管理、自我成长 | 内容形式/互动率/变现方式 |
| 星座命理 | 星座运势、塔罗、八字 | 爆款标题/封面风格/评论运营 |
| 人生教练 | 人生规划、习惯养成、效率提升 | 账号定位/引流话术/知识付费模式 |
| AI工具类 | AI测试、AI分析 | 产品植入方式/用户反馈 |

**分析模板**（每个对标账号）：
- 账号名/粉丝数/赞藏数
- 内容定位/发帖频率
- 爆款TOP3拆解（标题/封面/正文结构）
- 引流方式/变现模式
- 可借鉴点/差异化机会

产出位置：`appendix/competitors.md`

## 品牌视觉

已有品牌视觉资源，在手册中引用：
- 主色调/辅助色
- Logo使用规范
- 封面模板风格

## 待确认问题

1. **内容生成**：是否需要开发AI辅助生成工具集成各Skill
