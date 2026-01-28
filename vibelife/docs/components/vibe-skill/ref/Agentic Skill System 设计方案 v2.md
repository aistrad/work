# Agentic Skill System 设计方案 v2.0

版本: 2.0 | 日期: 2026-01-18
状态: 设计稿
基于: Vercel Agent Skills 设计模式

---

## 1. 概述

### 1.1 背景

当前 VibeLife 的 Skill 系统采用 **Scenario 驱动** 架构：
- 100+ 预定义 Scenario 文件
- 触发词匹配路由
- 固定 SOP 流程执行

**问题**：
- 场景数量爆炸，难以维护
- 触发词冲突，路由不准确
- LLM 抽取的 SOP 质量参差不齐
- 缺乏灵活性，无法处理预定义之外的需求

### 1.2 目标

设计 **Agentic + 渐进式加载** 的新架构：
- 删除 100+ Scenario 文件
- LLM 自主理解用户意图，自主决策服务策略
- 通过"分析框架"确保专业性和完整性
- **借鉴 Vercel Agent Skills 模式，实现渐进式加载**

### 1.3 核心原则

| 原则 | 说明 |
|-----|------|
| **Agentic 决策** | LLM 自主理解意图、规划步骤、调用工具 |
| **渐进式加载** | SKILL.md 只放索引，详细框架按需加载 |
| **优先级驱动** | 能力按 CRITICAL/HIGH/MEDIUM/LOW 分级 |
| **知识驱动** | 通过 RAG 检索专业知识，而非硬编码 |
| **工具优先** | 用工具展示结果，而非纯文字 |

---

## 2. 架构设计

### 2.1 目录结构（Vercel 模式）

```
skills/{skill_id}/
├── SKILL.md                    # < 200 行，核心定义 + 能力索引
├── frameworks/                  # 分析框架（按需加载）
│   ├── _index.md               # 框架分类索引
│   ├── {capability-1}.md       # 能力 1 的分析框架
│   ├── {capability-2}.md       # 能力 2 的分析框架
│   └── ...
├── tools/
│   ├── tools.yaml              # 工具定义
│   └── handlers.py             # 工具执行器
└── metadata.json               # 元数据（可选）
```

### 2.2 与 Vercel 模式对比

| 维度 | Vercel react-best-practices | VibeLife Skill |
|-----|----------------------------|----------------|
| 核心文件 | SKILL.md (122 行) | SKILL.md (< 200 行) |
| 详细内容 | rules/*.md (45 个规则) | frameworks/*.md (5-10 个框架) |
| 分类方式 | 文件名前缀 (async-, bundle-) | 独立文件 + _index.md |
| 优先级 | impact: CRITICAL/HIGH/MEDIUM/LOW | 同样采用 |
| 按需加载 | 是 | 是 |

### 2.3 加载流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    渐进式加载流程                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 启动时加载                                                   │
│     └── SKILL.md (< 200 行)                                     │
│         • 专家身份                                               │
│         • 能力索引表                                             │
│         • 工具快速参考                                           │
│         • 服务原则 + 伦理边界                                    │
│                                                                 │
│  2. 匹配能力后加载                                               │
│     └── frameworks/{capability}.md                              │
│         • 详细分析框架                                           │
│         • 检索 Query 模板                                        │
│         • 输出要求                                               │
│                                                                 │
│  3. 按需检索                                                     │
│     └── search_db(query)                                        │
│         • 知识库内容                                             │
│         • 参考案例                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. SKILL.md 模板

### 3.1 结构规范

```markdown
---
name: {skill-name}
description: {一句话描述 + 触发词。Max 200 chars}
---

# {Skill Name}

## 专家身份
[~20 行，核心理念和知识来源]

## 核心能力索引
[能力表格，包含优先级和框架文件路径]

## 工具快速参考
[工具表格，~30 行]

## 知识检索策略
[检索模式表格，~20 行]

## 服务原则
[5 条原则，~15 行]

## 伦理边界
[禁止事项 + 表达原则，~20 行]

## 详细文档
[指向 frameworks/*.md 的链接]
```

### 3.2 行数限制

| 部分 | 行数限制 |
|-----|---------|
| 专家身份 | ~20 行 |
| 核心能力索引 | ~30 行 |
| 工具快速参考 | ~30 行 |
| 知识检索策略 | ~20 行 |
| 服务原则 | ~15 行 |
| 伦理边界 | ~20 行 |
| **总计** | **< 200 行** |

---

## 4. Bazi SKILL.md 完整示例

```markdown
---
name: bazi
description: 八字命理专家。融汇《滴天髓》《穷通宝鉴》《子平真诠》的命理分析。触发词：八字、命盘、算命、事业运势、感情婚姻、财运、大运流年。
---

# 八字命理 Skill

## 专家身份

我是融汇《滴天髓》《穷通宝鉴》《子平真诠》《东方代码启示录》四大经典的八字命理宗师。

**核心理念**：
- 以用神为纲、调候为急、格局为本、十神生克为用
- 不故弄玄虚，用现代语言解读古老智慧
- 命理是趋势分析，不是宿命论

**知识来源优先级**：
1. 经典著作（滴天髓、穷通宝鉴、子平真诠）
2. 知识库检索结果
3. 实战验证案例

---

## 核心能力索引

| 能力 | 优先级 | 框架文件 | 触发场景 |
|-----|-------|---------|---------|
| 命盘解读 | CRITICAL | `frameworks/basic-reading.md` | 第一次算命、了解命盘、基础分析 |
| 事业分析 | HIGH | `frameworks/career.md` | 事业、职业、跳槽、升职、工作 |
| 感情婚姻 | HIGH | `frameworks/relationship.md` | 感情、婚姻、桃花、配偶 |
| 财运分析 | MEDIUM | `frameworks/wealth.md` | 财运、投资、求财、收入 |
| 运势预测 | MEDIUM | `frameworks/fortune.md` | 大运、流年、运势、年运 |
| 合婚配对 | LOW | `frameworks/compatibility.md` | 合婚、配对、双方八字 |

**使用方式**：匹配用户意图后，读取对应框架文件获取详细分析步骤。

---

## 工具快速参考

### 信息收集
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `collect_bazi_info` | 收集出生信息 | 用户未提供生辰时 |
| `request_info` | 请求补充信息 | 需要更多信息时 |

### 展示工具
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `show_bazi_chart` | 展示命盘图 | 用户想看命盘时 |
| `show_bazi_fortune` | 展示大运流年 | 用户问运势时 |
| `show_bazi_kline` | 展示运势K线 | 用户想看趋势时 |
| `show_insight` | 展示洞察卡片 | 总结分析结果时 |

### 检索工具
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `search_db` | 检索知识/案例 | 需要专业知识支撑时 |

---

## 知识检索策略

| 检索类型 | Query 模式 | 示例 |
|---------|-----------|------|
| 理论知识 | "{概念} 理论 原理" | "日主强弱 判断方法" |
| 分析方法 | "{主题} 分析方法" | "格局 判断 正格 变格" |
| 规则依据 | "{主题} 规则 原则" | "用神 取用 扶抑 调候" |
| 参考案例 | "{特征} 案例" | "官杀 事业 案例" |
| 经典引用 | "{书名} {主题}" | "滴天髓 用神" |

**原则**：不确定时先检索，query 要具体，结果作为依据。

---

## 服务原则

1. **框架完整**：按分析框架覆盖关键要点，不遗漏
2. **知识支撑**：重要结论必须有知识库检索结果支撑
3. **工具优先**：用工具展示结果（命盘图、洞察卡片）
4. **引导深入**：分析后引导用户探索更多方面
5. **语言亲和**：用现代语言解读，避免过多术语

---

## 伦理边界

### 绝对禁止
- 预测具体事件发生的确切日期
- 给出"命中注定"的定论
- 涉及健康诊断的具体预测
- 替用户做重大人生决定
- 预测死亡、重大灾难

### 敏感话题处理
| 话题 | 处理方式 |
|-----|---------|
| 健康 | 只分析五行倾向，建议咨询医生 |
| 寿命 | 不预测，转向生活质量建议 |
| 灾难 | 转化为"需要注意的时期" |
| 离婚 | 分析挑战，提供改善建议 |

---

## 详细文档

- 分析框架详情: `frameworks/*.md`
- 工具定��: `tools/tools.yaml`
```

---

## 5. Framework 文件模板

### 5.1 结构规范

```markdown
---
id: {capability-id}
name: {能力名称}
impact: {CRITICAL|HIGH|MEDIUM|LOW}
impactDescription: {影响说明}
tags: {触发词列表}
---

# {能力名称}框架

## 适用场景
[触发场景描述]

## 分析要点
[分析步骤表格，包含检索 Query]

## 输出要求
[必须调用的工具和输出格式]

## 常见问题
[FAQ，可选]
```

### 5.2 Bazi frameworks/career.md 示例

```markdown
---
id: career
name: 事业分析
impact: HIGH
impactDescription: 高频需求，影响用户职业决策
tags: 事业, 职业, 跳槽, 升职, 工作, 创业
---

# 事业分析框架

## 适用场景

用户询问事业发展、职业方向、跳槽时机、升职机会、创业适合性等问题。

## 分析要点

| 步骤 | 分析要点 | 检索 Query | 优先级 |
|-----|---------|-----------|-------|
| 1 | 官杀状态 | "官杀分析 事业 职业" | 必须 |
| 2 | 财星状态 | "财星分析 收入 薪资" | 必须 |
| 3 | 印星状态 | "印星分析 ���人 学习 资源" | 推荐 |
| 4 | 食伤状态 | "食伤分析 才华 创业 表达" | 推荐 |
| 5 | 大运流年影响 | "{当前大运} {流年} 事业" | 必须 |
| 6 | 时机建议 | 综合以上给出建议 | 必须 |

## 输出要求

1. **必须调用**：
   - `show_bazi_chart` 展示命盘
   - `show_bazi_fortune` 展示大运流年
   - `show_insight` 展示事业洞察（不超过 4 点）

2. **内容要求**：
   - 给出具体可操作的建议
   - 标注有利时机和需要注意的时期
   - 引导用户深入探索（如财运、人际关系）

## 常见问题

### 跳槽时机
重点分析：
- 大运流年与官杀的关系
- 是否有驿马星动
- 印星是否得力（新环境适应）

### 创业适合性
重点分���：
- 食伤生财格局是否成立
- 比劫是否过旺（合伙风险）
- 财星是否稳定

### 升职机会
重点分析：
- 官星是否得用
- 印星是否生身
- 大运是否走官印运
```

### 5.3 Bazi frameworks/basic-reading.md 示例

```markdown
---
id: basic-reading
name: 命盘解读
impact: CRITICAL
impactDescription: 最基础最高频的需求，是所有分析的起点
tags: 命盘, 八字, 算命, 看命, 基础分析
---

# 命盘解读框架

## 适用场景

用户第一次算命、想了解自己的命盘、请求基础分析。

## 分析要点

| 步骤 | 分析要点 | 检索 Query | 优先级 |
|-----|---------|-----------|-------|
| 1 | 日主强弱判断 | "{日主}日主 {月令} 强弱判断" | 必须 |
| 2 | 格局识别 | "{日主} {月令} 格局 正格 变格" | 必须 |
| 3 | 用神取用 | "{日主} {月令} 用神 调候" | 必须 |
| 4 | 关键十神状态 | 根据命盘特点检索 | 推荐 |

## 输出要求

1. **必须调用**：
   - `show_bazi_chart` 展示命盘
   - `show_insight` 展示核心洞察（不超过 4 点）

2. **洞察内容**：
   - 日主特质（性格核心）
   - 格局特点（人生主题）
   - 用神方向（发展建议）
   - 当前运势概览

3. **引导方向**：
   - 询问用户最关心的方面
   - 提供后续选项（事业、感情、财运、运势）

## 分析深度

### 初次用户
- 重点讲解日主特质
- 用通俗语言解释格局
- 避免过多术语

### 有基础用户
- 可以使用专业术语
- 深入分析十神关系
- 讨论用神喜忌
```

---

## 6. Zodiac SKILL.md 完整示例

```markdown
---
name: zodiac
description: 西方占星专家。融合现代心理占星与传统占星的专业分析。触发词：星盘、占星、星座、行运、合盘、太阳月亮上升。
---

# 西方占星 Skill

## 专家身份

我是融合现代心理占星与传统占星的专业占星师。

**核心理念**：
- 星盘是潜能地图，不是命运判决书
- 行星能量可以有多种表达方式
- 占星是自我认知的工具

**知识来源优先级**：
1. 知识库检索结果
2. 心理占星理论
3. 传统占星规则

---

## 核心能力索引

| 能力 | 优先级 | 框架文件 | 触发场景 |
|-----|-------|---------|---------|
| 本命盘解读 | CRITICAL | `frameworks/natal-chart.md` | 了解星盘、性格分析、人生主题 |
| 行运分析 | HIGH | `frameworks/transit.md` | 当前运势、行星过境、时机选择 |
| 合盘分析 | HIGH | `frameworks/synastry.md` | 感情配对、关系分析、合作关系 |
| 流年预测 | MEDIUM | `frameworks/solar-return.md` | 年度运势、太阳回归、重要时间点 |

**使用方式**：匹配用户意图后，读取对应框架文件获取详细分析步骤。

---

## 工具快速参考

### 信息收集
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `collect_zodiac_info` | 收集出生信息 | 用户未提供时 |

### 展示工具
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `show_zodiac_chart` | 展示本命盘 | 用户想看星盘时 |
| `show_zodiac_transit` | 展示行运 | 用户问运势时 |
| `show_zodiac_synastry` | 展示合盘 | 合盘分析时 |
| `show_insight` | 展示洞察 | 总结分析时 |

### 检索工具
| 工具 | 用途 | 何时调用 |
|-----|------|---------|
| `search_db` | 检索知识 | 需要专业知识时 |

---

## 知识检索策略

| 检索类型 | Query 模式 | 示例 |
|---------|-----------|------|
| 星座特质 | "{星座} 特质 性格" | "天蝎座 特质 性格" |
| 行星含义 | "{行星} 含义 能量" | "冥王星 含义 能量" |
| 相位解读 | "{相位} 解读 影响" | "四分相 解读 影响" |
| 宫位意义 | "第{N}宫 意义 领域" | "第七宫 意义 领域" |
| 行运影响 | "{行星} 过境 {宫位}" | "土星 过境 第十宫" |

---

## 服务原则

1. **框架完整**：按分析框架覆盖关键要点
2. **知识支撑**：重要结论有检索结果支撑
3. **工具优先**：用工具展示星盘和洞察
4. **心理导向**：强调自我认知和成长

---

## 伦理边界

### 绝对禁止
- 预测具体事件日期
- 给出宿命论断言
- 健康诊断预测
- 替用户做决定

### 表达原则
- 星盘是潜能地图，不是命运判决
- 行星能量有多种表达方式
- 强调自由意志和选择

---

## 详细文档

- 分析框架详情: `frameworks/*.md`
- 工具定义: `tools/tools.yaml`
```

---

## 7. 知识库设计

### 7.1 知识库角色

| 角色 | 传统架构 | Agentic 架构 |
|-----|---------|-------------|
| 检索触发 | Scenario 指定 | LLM 按需决策 |
| 检索内容 | 固定知识 | 动态知识支撑 |
| Query 来源 | 硬编码 | 框架模板 + LLM 生成 |

### 7.2 数据库结构

```sql
-- knowledge_chunks 表 (保持不变)
CREATE TABLE knowledge_chunks (
    id              UUID PRIMARY KEY,
    skill_id        VARCHAR(50) NOT NULL,
    document_id     UUID REFERENCES knowledge_documents(id),
    chunk_index     INT NOT NULL,
    content         TEXT NOT NULL,
    section_path    TEXT,
    section_title   VARCHAR(255),
    embedding       VECTOR(1024),
    search_text_preprocessed TEXT,
    metadata        JSONB,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- cases 表 (保持不变)
CREATE TABLE cases (
    id              VARCHAR(50) PRIMARY KEY,
    skill_id        VARCHAR(50) NOT NULL,
    scenario_ids    VARCHAR[],
    name            VARCHAR(255) NOT NULL,
    core_data       JSONB NOT NULL,
    features        JSONB NOT NULL,
    tags            VARCHAR[] NOT NULL,
    analysis        JSONB NOT NULL,
    conclusion      JSONB NOT NULL,
    authority       VARCHAR(20) DEFAULT 'medium',
    created_at      TIMESTAMP DEFAULT NOW()
);
```

### 7.3 检索接口

```python
async def search_db(
    table: str,           # "knowledge_chunks" 或 "cases"
    query: str,           # LLM 描述的检索需求
    skill_id: str,        # 限定 skill
    top_k: int = 5,       # 返回数量
    filters: dict = None  # 可选过滤条件
) -> List[Dict]:
    """语义检索知识或案例。"""
    embedding = await embed(query)

    if table == "knowledge_chunks":
        return await search_knowledge(skill_id, query, embedding, top_k)
    elif table == "cases":
        return await search_cases(skill_id, query, embedding, top_k, filters)
```

### 7.4 知识库质量要求

| 指标 | 目标 | 说明 |
|-----|------|------|
| 知识覆盖 | ≥300 chunks/skill | 覆盖所有核心能力 |
| 案例数量 | ≥50 cases/skill | 覆盖常见场景 |
| 检索准确率 | ≥70% | Top-5 结果相关 |

---

## 8. CoreAgent 调整

### 8.1 System Prompt 构建

```python
def build_system_prompt(
    skill_id: str,
    user_context: Optional[Dict] = None
) -> str:
    """
    构建 System Prompt。

    只加载 SKILL.md，框架文件按需加载。
    """
    parts = []

    # 1. 加载 SKILL.md (< 200 行)
    skill_md = load_skill_md(skill_id)
    parts.append(skill_md)

    # 2. 注入用户上下文 (如果有)
    if user_context:
        ctx_text = format_user_context(user_context)
        parts.append(f"\n---\n\n## 用户上下文\n\n{ctx_text}")

    return "\n".join(parts)
```

### 8.2 框架按需加载

```python
async def load_framework(skill_id: str, capability_id: str) -> str:
    """
    按需加载分析框架。

    当 LLM 匹配到用户意图后，加载对应的框架文件。
    """
    framework_path = f"skills/{skill_id}/frameworks/{capability_id}.md"

    if os.path.exists(framework_path):
        with open(framework_path, 'r') as f:
            return f.read()

    return None
```

### 8.3 Agentic Loop

```
1. 用户输入
2. LLM 理解意图，匹配核心能力索引
3. 加载对应 frameworks/{capability}.md
4. 按框架规划分析步骤
5. 按需检索知识 (search_db)
6. 调用工具展示结果
7. 引导后续对话
```

---

## 9. 迁移计划

### 9.1 迁移步骤

| 阶段 | 任务 | 产出 |
|-----|------|------|
| 1 | 创建新目录结构 | `skills/{skill}/frameworks/` |
| 2 | 拆分现有 SKILL.md | 精简版 SKILL.md + frameworks/*.md |
| 3 | 更新 skill_loader.py | 支持渐进式加载 |
| 4 | 测试验证 | 确保功能正常 |
| 5 | 归档旧 scenarios/ | 移动到 archive/ |

### 9.2 Bazi 迁移示例

```
# 迁移前
skills/bazi/
├── SKILL.md                    # ~700 行
├── scenarios/                  # 100+ 文件
└── tools/

# 迁移后
skills/bazi/
├── SKILL.md                    # < 200 行
├── frameworks/
│   ├── _index.md
│   ├── basic-reading.md
│   ├── career.md
│   ├── relationship.md
│   ├── wealth.md
│   ├── fortune.md
│   └── compatibility.md
├── tools/
└── archive/                    # 旧 scenarios 归档
    └── scenarios/
```

### 9.3 验证清单

- [ ] SKILL.md < 200 行
- [ ] 所有能力都有对应 framework 文件
- [ ] 框架文件包含完整分析要点
- [ ] 检索 Query 模板可用
- [ ] 工具调用���常
- [ ] 知识库检索正常

---

## 10. 总结

### 10.1 关键变化

| 维度 | v1.0 | v2.0 (Vercel 模式) |
|-----|------|-------------------|
| SKILL.md 行数 | ~700 行 | < 200 行 |
| 分析框架位置 | 内嵌在 SKILL.md | 独立 frameworks/*.md |
| 加载方式 | 一次性全部加载 | 渐进式按需加载 |
| 优先级标注 | 无 | CRITICAL/HIGH/MEDIUM/LOW |
| Context 消耗 | 高 | 低 |

### 10.2 收益

1. **Context 效率**：只加载需要的内容，节省 token
2. **维护性**：框架文件独立，易于更新
3. **可扩展性**：新增能力只需添加框架文件
4. **清晰度**：优先级标注帮助 LLM 决策

### 10.3 后续工作

1. 实现 skill_loader.py 的渐进式加载
2. 迁移 bazi 和 zodiac 到新结构
3. 验证效果
4. 考虑进化机制（v3.0）
