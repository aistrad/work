---
name: vibelife-skill
description: |
  Vibe Skill - 一站式知识库与专家系统构建工具。
  整合资料搜寻、格式转换、向量化入库、SOP提取、Skill优化的完整流程。
  触发词：vibelife-skill, 建库, 建skill, 知识库构建, skill构建
---

# Vibe Skill - 一站式知识库与专家系统构建工具

## 概述

Vibe Skill 整合了以下功能模块，提供从原始资料到可用专家系统的完整流程：

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VIBE-SKILL 完整流程                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [输入源]                                                            │
│     │                                                               │
│     ├── PDF/EPUB/DOCX/HTML/TXT/MD                                   │
│     ├── 网页 URL                                                     │
│     └── 主题关键词（自动搜索）                                         │
│                                                                     │
│     ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Phase 1: CURATE - 资料搜寻与获取                              │   │
│  │   • 多源搜索（GitHub、Google、Archive.org、Kanripo）          │   │
│  │   • 质量评估（完整性、准确性、来源可信度）                      │   │
│  │   • 下载与分类存储                                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│     │                                                               │
│     ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Phase 2: CONVERT - 格式转换与清洗                             │   │
│  │   • PDF → MD（OCR + 结构识别）                                │   │
│  │   • EPUB/DOCX/HTML → MD                                       │   │
│  │   • 清洗：去噪、修复乱码、标准化格式                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│     │                                                               │
│     ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Phase 3: VECTORIZE - 向量化入库                               │   │
│  │   • 智能分块（语义边界识别）                                   │   │
│  │   • Embedding 生成                                            │   │
│  │   • 向量数据库存储                                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│     │                                                               │
│     ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Phase 4: EXTRACT - 专家知识提取                               │   │
│  │   • 生成专家 Meta（role, backstory, methodology）             │   │
│  │   • 提取 Methods（具体分析方法）                               │   │
│  │   • 提取 Workflows（分析流程）                                 │   │
│  │   • 提取 Rules（判断规则）                                     │   │
│  │   • 创建 Decision Trees（决策树）                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│     │                                                               │
│     ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Phase 5: OPTIMIZE - 迭代优化                                  │   │
│  │   • 搜索 GitHub 开源项目增强能力（计算库、API、知识库）        │   │
│  │   • 规则去重与合并                                            │   │
│  │   • 过滤常识性内容                                            │   │
│  │   • 补充缺失规则                                              │   │
│  │   • 验证规则一致性                                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│     │                                                               │
│     ▼                                                               │
│  [输出]                                                             │
│     ├── /data/vibelife/knowledge/{theme}/          # 知识库文件     │
│     └── /apps/api/skills/{skill}/                  # Skill 配置     │
│           ├── SKILL.md                             # 专家 Meta      │
│           ├── methods/*.yaml                       # 方法库         │
│           ├── workflows/main_flow.yaml             # 工作流         │
│           ├── rules/rules.yaml                     # 规则库         │
│           ├── decision_trees/*.yaml                # 决策树         │
│           └── templates/*.yaml                     # 模板库         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 输入参数

| 参数 | 必填 | 说明 | 示例 |
|------|------|------|------|
| **--phase** | N | 执行阶段（默认 all） | `curate`, `convert`, `vectorize`, `extract`, `optimize`, `all` |
| **--theme** | Y | 主题/skill 名称 | `bazi`, `zodiac`, `mbti` |
| **--input** | N | 输入源（文件/目录/URL/关键词） | `/path/to/file.pdf`, `https://...`, `子平真诠` |
| **--target** | N | 输出目录 | `/data/vibelife/knowledge/bazi` |

---

## 执行模式

### 模式 A：全流程（默认）

```bash
vibe-skill --theme bazi --input "八字经典书单"
```

执行 Phase 1-5 完整流程。

### 模式 B：单阶段执行

```bash
# 仅搜寻资料
vibe-skill --phase curate --theme bazi --input "子平真诠"

# 仅转换格式
vibe-skill --phase convert --theme bazi --input /path/to/file.pdf

# 仅向量化
vibe-skill --phase vectorize --theme bazi --input /path/to/converted/

# 仅提取知识
vibe-skill --phase extract --theme bazi

# 仅优化
vibe-skill --phase optimize --theme bazi
```

### 模式 C：从指定阶段开始

```bash
# 从转换阶段开始（跳过搜寻）
vibe-skill --phase convert,vectorize,extract,optimize --theme bazi --input /path/to/files/
```

---

## Phase 1: CURATE - 资料搜寻与获取

### 数据源

**本地数据源**：
- 用户提供的文件（PDF/EPUB/DOCX/HTML/TXT/MD）
- 用户提供的 URL

**外部数据源**（按优先级排序）：

| 优先级 | 数据源 | 类型 | 适用领域 | 访问方式 |
|-------|--------|------|---------|---------|
| ⭐⭐⭐⭐⭐ | **GitHub** | MD/PDF/代码 | 通用 | WebFetch（主要） |
| ⭐⭐⭐⭐ | HuggingFace Datasets | 结构化数据 | AI/ML | 参考 |
| ⭐⭐⭐⭐ | Wikisource | 公版书籍 | 古典文献 | 参考 |
| ⭐⭐⭐⭐ | Project Gutenberg | 英文公版书 | 西方经典 | 参考 |
| ⭐⭐⭐⭐ | Ctext.org | 中文古籍 | 国学经典 | 参考 |
| ⭐⭐⭐ | arXiv | 学术论文 | 科研领域 | 参考 |
| ⭐⭐⭐ | Semantic Scholar | 学术论文 | 科研领域 | 参考 |
| ⭐⭐⭐ | Archive.org | PDF/扫描件 | 历史文献 | 参考 |
| ⭐⭐⭐ | Kanripo | 中文古籍 | 国学经典 | 参考 |

> **注意**：以 GitHub 为主要外部数据源（可直接 WebFetch），其他数据源仅作为参考或备选。

### 搜索策略

**优先级 1: GitHub（主要）**
```bash
# 直接获取 raw 文件
WebFetch "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{file}"

# 搜索仓库
WebFetch "https://github.com/search?q={主题}+{关键词}&type=repositories"
WebFetch "https://github.com/topics/{theme}"
```

**优先级 2: Google 搜索（辅助）**
```bash
google_search "{书名} site:github.com filetype:md"
google_search "{书名} filetype:pdf"
```

**优先级 3: 其他数据源（参考）**
```bash
# 仅在 GitHub 找不到时使用
google_search "{书名} site:archive.org"
google_search "{书名} site:ctext.org"
```

### 质量标准

| 维度 | 合格标准 |
|------|---------|
| 完整性 | 包含完整目录和主要章节 |
| 准确性 | 无明显乱码、OCR错误 |
| 来源可信 | 来自可信来源 |
| 可读性 | 格式清晰，便于机器读取 |

### 输出

```
/data/vibelife/knowledge/{theme}/
├── candidates/           # 候选文件
│   ├── github/
│   ├── archive_org/
│   └── other/
└── selected/             # 选出的最佳版本
```

### ✅ Phase 1 自检流程

**执行命令**：
```bash
# 检查文件数量和大小
echo "=== Phase 1 自检 ===" && \
ls -la /data/vibelife/knowledge/{theme}/selected/ 2>/dev/null | head -20 && \
echo "文件数量:" && ls /data/vibelife/knowledge/{theme}/selected/ 2>/dev/null | wc -l && \
echo "总大小:" && du -sh /data/vibelife/knowledge/{theme}/selected/ 2>/dev/null
```

**合格标准**：
| 检查项 | 合格标准 | 不合格处理 |
|-------|---------|-----------|
| 文件数量 | ≥ 1 个文件 | 重新搜索或手动提供文件 |
| 单文件大小 | ≥ 50KB | 检查文件完整性，可能是空文件 |
| 文件格式 | PDF/EPUB/DOCX/MD/TXT | 转换或重新获取 |

**不合格时**：
- 文件数量为 0：检查搜索关键词，尝试其他数据源
- 文件过小：可能是下载失败或空文件，重新下载
- 格式不支持：尝试其他版本或手动转换

---

## Phase 2: CONVERT - 格式转换与清洗

### 支持格式

| 输入格式 | 转换方法 | 输出格式 |
|---------|---------|---------|
| PDF | marker-pdf / PyMuPDF + OCR | MD |
| EPUB | ebooklib | MD |
| DOCX | python-docx | MD |
| HTML | BeautifulSoup | MD |
| TXT | 直接处理 | MD |

### 清洗规则

1. **去噪**：移除页眉页脚、水印、广告
2. **修复乱码**：检测并修复编码问题
3. **标准化格式**：统一标题层级、列表格式
4. **分章节**：按章节拆分大文件

### 输出

```
/data/vibelife/knowledge/{theme}/converted/
├── {book_name}.converted.md
└── ...
```

### ✅ Phase 2 自检流程

**执行命令**：
```bash
# 检查转换结果
echo "=== Phase 2 自检 ===" && \
echo "转换后文件数量:" && ls /data/vibelife/knowledge/{theme}/converted/*.converted.md 2>/dev/null | wc -l && \
echo "各文件大小:" && ls -lh /data/vibelife/knowledge/{theme}/converted/*.converted.md 2>/dev/null && \
echo "总大小:" && du -sh /data/vibelife/knowledge/{theme}/converted/ 2>/dev/null && \
echo "空文件检查:" && find /data/vibelife/knowledge/{theme}/converted/ -name "*.converted.md" -size -50k 2>/dev/null
```

**合格标准**：
| 检查项 | 合格标准 | 不合格处理 |
|-------|---------|-----------|
| 转换成功率 | 100%（所有源文件都有对应 .converted.md） | 检查失败文件，重新转换 |
| 单文件大小 | ≥ 50KB | 检查转换质量，可能是空转换 |
| 内容完整性 | 包含标题、章节结构 | 检查 OCR 质量或源文件 |
| 乱码检查 | 无明显乱码 | 重新转换或修复编码 |

**不合格时**：
- 转换失败：检查源文件格式，尝试其他转换工具
- 文件过小：可能是 OCR 失败或源文件加密，检查源文件
- 乱码：检查编码，尝试指定正确编码重新转换
- 结构丢失：检查 PDF 是否为扫描件，可能需要 OCR

---

## Phase 3: VECTORIZE - 向量化入库

### 分块策略

```yaml
chunking:
  method: semantic  # semantic | fixed | paragraph
  max_tokens: 512
  overlap: 50
  preserve_headers: true
```

### 执行

```python
from workers.ingestion import IngestionWorker

worker = IngestionWorker()
result = await worker.process_file(
    file_path=file_path,
    skill_id=skill_id
)
```

### 输出

- 向量数据库中的 chunks
- 元数据索引

### ✅ Phase 3 自检流程

**执行命令**：
```bash
# 检查向量化结果（需要数据库连接）
PGPASSWORD='Ak4_9lScd-69WX' psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife -c "
SELECT
  skill_id,
  COUNT(*) as total_docs,
  COUNT(*) FILTER (WHERE status = 'completed') as completed,
  COUNT(*) FILTER (WHERE status = 'failed') as failed,
  COUNT(*) FILTER (WHERE status = 'pending') as pending,
  COUNT(*) FILTER (WHERE status = 'processing') as processing,
  SUM(chunk_count) as total_chunks,
  COUNT(*) FILTER (WHERE chunk_count > 0) as docs_with_chunks
FROM knowledge_documents
WHERE skill_id = '{theme}'
GROUP BY skill_id;
"
```

**合格标准**：
| 检查项 | 合格标准 | 不合格处理 |
|-------|---------|-----------|
| 文件数 = 数据库记录数 | 完全匹配 | 检查遗漏文件，重新入库 |
| completed 状态 | = total_docs | 检查 failed/processing 记录 |
| failed 状态 | = 0 | 查看错误日志，修复后重试 |
| processing 状态 | = 0 | 可能是 worker 中断，手动修复状态 |
| docs_with_chunks | = total_docs | 检查 chunk_count=0 的文件 |
| total_chunks | > 0 且合理 | 检查分块逻辑 |

**不合格时**：
- 有 failed 记录：查看错误原因，修复后重新处理
- 有 processing 记录：worker 被中断，手动更新状态为 pending 重试
- chunk_count = 0：文件可能为空或格式问题，检查源文件
- 记录数不匹配：检查是否有文件未入库

**修复 processing 状态**：
```sql
UPDATE knowledge_documents
SET status = 'completed'
WHERE skill_id = '{theme}' AND status = 'processing' AND chunk_count > 0;
```

---

## Phase 4: EXTRACT - 专家知识提取（含迭代优化）

### 执行流程（Claude Code 直接执行）

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Phase 4 执行流程图                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Step 1: 读取知识库文件                                              │
│     │                                                               │
│     └── Read /data/vibelife/knowledge/{theme}/converted/*.md        │
│                                                                     │
│     ▼                                                               │
│  Step 2: 逐文件提取（对每个 .converted.md 文件）                      │
│     │                                                               │
│     ├── 2.1 提取 Methods（方法论）                                   │
│     ├── 2.2 提取 Workflows（流程步骤）                               │
│     └── 2.3 提取 Rules（判断规则）                                   │
│                                                                     │
│     ▼                                                               │
│  Step 3: 合并多文件结果                                              │
│     │                                                               │
│     ├── 3.1 相似方法合并                                            │
│     ├── 3.2 流程步骤排序                                            │
│     └── 3.3 规则去重（保留冲突观点）                                 │
│                                                                     │
│     ▼                                                               │
│  Step 4: 生成初版 Skill 文件                                        │
│     │                                                               │
│     ├── SKILL.md（专家 Meta）                                       │
│     ├── methods/*.yaml                                              │
│     ├── workflows/main_flow.yaml                                    │
│     └── rules/rules.yaml                                            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              ⭐ 迭代优化循环（重复 2-3 轮）                    │   │
│  ├─────────────────────────────────────────────────────────────┤   │
│  │                                                             │   │
│  │  Step 5: 质量评估                                           │   │
│  │     │                                                       │   │
│  │     ├── 5.1 判断是否为常识 → 标记删除                        │   │
│  │     ├── 5.2 判断是否有错误 → 标记修正                        │   │
│  │     └── 5.3 识别遗漏的深度知识 → missing_hints              │   │
│  │                                                             │   │
│  │     ▼                                                       │   │
│  │  Step 6: 执行优化                                           │   │
│  │     │                                                       │   │
│  │     ├── 6.1 删除常识性规则                                  │   │
│  │     ├── 6.2 修正错误规则                                    │   │
│  │     └── 6.3 去重合并相似规则                                │   │
│  │                                                             │   │
│  │     ▼                                                       │   │
│  │  Step 7: 回读原文补充提取 ⭐ 关键步骤                        │   │
│  │     │                                                       │   │
│  │     ├── 7.1 根据 missing_hints 确定需要深挖的主题           │   │
│  │     ├── 7.2 重新读取 converted/*.md 原文                    │   │
│  │     ├── 7.3 针对性提取遗漏的深度知识                        │   │
│  │     └── 7.4 合并新提取的规则到 rules.yaml                   │   │
│  │                                                             │   │
│  │     ▼                                                       │   │
│  │  [检查] 规则数量 ≥ 50 且质量达标？                           │   │
│  │     │                                                       │   │
│  │     ├── 否 → 返回 Step 5 继续迭代                           │   │
│  │     └── 是 → 退出循环                                       │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│     ▼                                                               │
│  Step 8: 输出最终 Skill 文件                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 1: 读取知识库文件

```bash
# 列出所有待处理文件
ls /data/vibelife/knowledge/{theme}/converted/*.converted.md
```

### Step 2: 逐文件提取

**对每个文件执行以下提取 Prompt**：

```
你是 {role}。

## 背景
{backstory}

## 任务：从文档中提取专家级深度 Knowhow

### 什么是深度 Knowhow
- ✅ 大模型不知道的专业经验
- ✅ 具体的判断标准和阈值
- ✅ 反直觉的洞察
- ✅ 实战中的"坑"和技巧
- ❌ 不是：概念定义、通用流程、教科书知识

### 提取三类内容

**1. Methods（方法论）**
如何做某事的具体步骤，必须有可操作性。

**2. Workflows（流程片段）**
分析的先后顺序，步骤之间有依赖关系。

**3. Rules（判断规则）**
IF-THEN 形式的经验判断，必须有具体条件和结论。

### 排除标准
- 纯概念定义
- 没有具体判断标准的泛泛描述
- 大模型已知的常识

## 文档内容
文件名: {file_name}

{document_content}

## 输出格式
请输出 JSON 格式：
```json
{
  "methods": [
    {"name": "方法名称", "trigger": "何时使用", "steps": ["步骤1", "步骤2"], "source_hint": "来源段落"}
  ],
  "workflow_steps": [
    {"order": 1, "name": "步骤名", "description": "描述", "depends_on": null}
  ],
  "rules": [
    {"condition": "具体条件", "conclusion": "具体结论", "confidence": "high/medium/low", "source_hint": "来源"}
  ]
}
```
```

### Step 3: 合并多文件结果

**合并规则**：
- **Methods 合并**：相似方法（名称或步骤相似）合并为一个，保留最完整的步骤描述
- **Workflows 合并**：合并成一个统一的主分析流程，按逻辑顺序排列
- **Rules 合并**：相同条件的规则去重；如果不同来源有冲突观点，保留两者并标注来源

### Step 4: 生成初版 Skill 文件

**输出目录结构**：
```
/home/aiscend/work/vibelife/apps/api/skills/{skill}/
├── SKILL.md              # 专家 Meta（role, goal, backstory, methodology）
├── meta.json             # 元数据（method_count, rule_count 等）
├── methods/              # 方法库
│   └── {method_name}.yaml
├── workflows/            # 工作流
│   └── main_flow.yaml
├── rules/                # 规则库
│   └── rules.yaml
├── decision_trees/       # 决策树
│   └── *.yaml
└── templates/            # 模板库
    └── *.yaml
```

---

### ⭐ 迭代优化循环（Step 5-7，重复 2-3 轮）

### Step 5: 质量评估

**评估 Prompt**：

```
你是知识工程专家。请评估以下从 {domain} 知识库中提取的内容质量。

## 评估标准

**深度 Knowhow 的定义**：
- 大模型训练数据中不太可能包含的专业经验
- 有具体条件（如具体参数、组合、名称）的规则
- 反直觉的洞察
- 实战中的"坑"和技巧

**常识的定义**（应删除）：
- 大模型已知的基础知识
- 教科书上的标准定义
- 没有具体条件的泛泛描述

**错误的定义**：
- 事实性错误
- 逻辑矛盾

## 待评估内容

### Methods
{methods}

### Rules
{rules}

## 请输出评估报告

```json
{
  "keep": {
    "methods": ["保留的方法名1", "保留的方法名2"],
    "rules": ["保留的规则条件1", "保留的规则条件2"]
  },
  "remove": {
    "methods": [{"name": "方法名", "reason": "删除原因"}],
    "rules": [{"condition": "规则条件", "reason": "删除原因"}]
  },
  "errors": [
    {"item": "错误内容", "error": "错误描述", "correction": "正确内容"}
  ],
  "missing_hints": [
    "可能遗漏的深度 knowhow 描述（具体到主题/章节）"
  ]
}
```
```

### Step 6: 执行优化

**优化操作**：

1. **删除常识性规则**：移除评估报告中 `remove` 列表的内容
2. **修正错误规则**：根据 `errors` 列表修正
3. **去重合并**：
   - 相同条件的规则合并
   - 相似方法合并，保留最完整版本

### Step 7: 回读原文补充提取 ⭐ 关键步骤

**执行流程**：

```bash
# 1. 列出知识库原文
ls /data/vibelife/knowledge/{theme}/converted/*.converted.md
```

**针对性提取 Prompt**：

```
你是 {role}。

## 任务：针对性补充提取

根据质量评估报告，以下主题的深度知识可能被遗漏：
{missing_hints}

请重新阅读以下文档，专门针对上述主题提取深度 Knowhow。

## 文档内容
文件名: {file_name}

{document_content}

## 提取要求
- 只提取与 missing_hints 相关的内容
- 必须是深度经验，不是常识
- 必须有具体条件和结论

## 输出格式
```json
{
  "rules": [
    {"condition": "具体条件", "conclusion": "具体结论", "confidence": "high/medium/low", "source_hint": "来源"}
  ]
}
```
```

**合并新规则**：将新提取的规则合并到 `rules/rules.yaml`，注意去重。

### Step 8: 检查是否达标

**达标标准**：
- 规则数量 ≥ 50 条
- 常识性规则占比 < 10%
- 所有规则都有来源标注

**未达标**：返回 Step 5 继续迭代（最多 3 轮）

---

### 深度 Knowhow 标准

**要提取**：
- 大模型不知道的专业经验
- 具体判断标准和阈值
- 反直觉洞察
- 实战经验总结
- 特殊情况处理

**不要提取**：
- 概念定义
- 教科书知识
- 常识性内容
- 泛泛而谈的描述

### 输出

```
/apps/api/skills/{skill}/
├── SKILL.md
├── methods/
│   └── *.yaml
├── workflows/
│   └── main_flow.yaml
├── rules/
│   └── rules.yaml
├── decision_trees/
│   └── *.yaml
└── templates/
    └── *.yaml
```

### ✅ Phase 4 自检流程

**执行命令**：
```bash
# 检查提取结果
echo "=== Phase 4 自检 ===" && \
SKILL_DIR="/home/aiscend/work/vibelife/apps/api/skills/{skill}" && \
echo "SKILL.md 存在:" && ls -la $SKILL_DIR/SKILL.md 2>/dev/null && \
echo "Methods 文件数:" && ls $SKILL_DIR/methods/*.yaml 2>/dev/null | wc -l && \
echo "Workflows 文件数:" && ls $SKILL_DIR/workflows/*.yaml 2>/dev/null | wc -l && \
echo "Rules 文件:" && ls -la $SKILL_DIR/rules/rules.yaml 2>/dev/null && \
echo "Decision Trees 文件数:" && ls $SKILL_DIR/decision_trees/*.yaml 2>/dev/null | wc -l && \
echo "Rules 数量:" && grep -c "^  - id:" $SKILL_DIR/rules/rules.yaml 2>/dev/null
```

**合格标准**：
| 检查项 | 合格标准 | 不合格处理 |
|-------|---------|-----------|
| SKILL.md | 存在且 > 1KB | 重新生成专家 Meta |
| methods/ | ≥ 3 个 yaml 文件 | 补充提取方法 |
| workflows/ | ≥ 1 个 yaml 文件 | 创建主工作流 |
| rules/rules.yaml | 存在且规则数 ≥ 50 | 补充规则提取 |
| decision_trees/ | ≥ 1 个 yaml 文件 | 创建决策树 |

**内容质量检查**：
```bash
# 检查 SKILL.md 是否包含必要字段
grep -E "^## (Role|Backstory|Methodology)" $SKILL_DIR/SKILL.md

# 检查 rules.yaml 是否有来源标注
grep -c "sources:" $SKILL_DIR/rules/rules.yaml

# 检查是否有空规则
grep -A2 "condition:" $SKILL_DIR/rules/rules.yaml | grep -c '""'
```

**不合格时**：
- SKILL.md 缺失：重新执行专家 Meta 提取
- 规则数量不足：继续从知识库提取更多规则
- 缺少来源标注：补充规则来源
- 有空规则：删除或补充空规则内容

---

## Phase 5: OPTIMIZE - GitHub 开源项目增强

### 概述

Phase 5 专注于通过搜索和整合 GitHub 开源项目来增强 Skill 能力，包括：
- 计算库（提供精确计算能力）
- 知识库（补充规则和解读）
- API 参考（架构设计参考）
- 可视化组件（图表、报告模板）

### 执行流程（Claude Code 直接执行）

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Phase 5 执行流程图                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Step 1: 搜索 GitHub 开源项目                                       │
│     │                                                               │
│     ├── 1.1 搜索主题相关的计算库                                    │
│     ├── 1.2 搜索主题相关的知识库/规则库                             │
│     ├── 1.3 搜索主题相关的 API 实现                                 │
│     └── 1.4 搜索主题相关的可视化组件                                │
│                                                                     │
│     ▼                                                               │
│  Step 2: 评估项目质量                                               │
│     │                                                               │
│     ├── 2.1 Stars 数量（>100 优先）                                 │
│     ├── 2.2 最近更新时间（活跃维护）                                │
│     ├── 2.3 许可证（MIT/Apache 优先）                               │
│     └── 2.4 文档完整度和代码质量                                    │
│                                                                     │
│     ▼                                                               │
│  Step 3: 从开源项目提取知识                                         │
│     │                                                               │
│     ├── 3.1 阅读项目文档和源码                                      │
│     ├── 3.2 提取规则和解读逻辑                                      │
│     └── 3.3 合并到 rules.yaml                                       │
│                                                                     │
│     ▼                                                               │
│  Step 4: 生成整合方案                                               │
│     │                                                               │
│     ├── 4.1 确定计算库集成方式                                      │
│     ├── 4.2 设计 API 调用接口                                       │
│     └── 4.3 生成 GITHUB_RESOURCES.md                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 1: 搜索 GitHub 开源项目

**搜索策略**：

```bash
# 搜索主题相关的开源项目
WebSearch "github {theme} python library"
WebSearch "github {theme} calculator"
WebSearch "github {theme} api"

# 直接访问 GitHub
WebFetch "https://github.com/topics/{theme}"
WebFetch "https://github.com/search?q={theme}+python&type=repositories"
```

**搜索关键词示例**：
| 主题 | 搜索关键词 |
|------|-----------|
| zodiac | astrology python, horoscope api, natal chart |
| bazi | bazi calculator, four pillars, chinese astrology |
| tarot | tarot python, tarot api, tarot meanings |
| career | mbti python, personality test, career assessment |

### Step 2: 评估项目质量

**评估维度**：
| 维度 | 优先级 | 标准 |
|------|--------|------|
| Stars | ⭐⭐⭐ | >100 优先，>1000 重点关注 |
| 更新时间 | ⭐⭐⭐ | 6个月内有更新 |
| 许可证 | ⭐⭐ | MIT/Apache/BSD 优先 |
| 文档 | ⭐⭐ | 有 README 和使用示例 |
| 代码质量 | ⭐ | 有测试、结构清晰 |

### Step 3: 从开源项目提取知识

**提取 Prompt**：

```
你是 {role}。

## 任务：从开源项目提取专家知识

以下是 GitHub 项目 {project_name} 的源码/文档内容。
请从中提取可用于 {skill} 的规则和解读逻辑。

## 项目内容
{project_content}

## 提取要求
- 提取具体的判断规则（IF-THEN 形式）
- 提取解读模板和表达方式
- 标注来源为 "GitHub: {project_name}"

## 输出格式
```json
{
  "rules": [
    {"condition": "具体条件", "conclusion": "具体结论", "confidence": "high", "source": "GitHub: {project_name}"}
  ],
  "interpretations": [
    {"topic": "主题", "template": "解读模板", "source": "GitHub: {project_name}"}
  ]
}
```
```

### Step 4: 生成整合方案

**GITHUB_RESOURCES.md 模板**：

```markdown
# {skill} GitHub 开源资源整合方案

## 计算库

### {library_name}
- **URL**: https://github.com/xxx/xxx
- **Stars**: xxx
- **许可证**: MIT
- **用途**: 提供 xxx 计算能力
- **集成方式**: pip install xxx
- **关键 API**:
  ```python
  from xxx import Calculator
  result = Calculator.calculate(params)
  ```

## 知识库

### {knowledge_repo_name}
- **URL**: https://github.com/xxx/xxx
- **提取规则数**: xx 条
- **主要内容**: xxx 解读规则

## API 参考

### {api_project_name}
- **URL**: https://github.com/xxx/xxx
- **参考价值**: API 设计模式、数据结构

## 可视化组件

### {viz_project_name}
- **URL**: https://github.com/xxx/xxx
- **用途**: xxx 图表渲染

## 整合优先级

1. **高优先级**: {library_name} - 核心计算能力
2. **中优先级**: {knowledge_repo_name} - 补充规则
3. **低优先级**: {viz_project_name} - 可视化增强
```

### 质量检查

```yaml
quality_checks:
  - name: 规则数量
    min: 50
    target: 100+

  - name: 规则覆盖度
    categories:
      - 核心规则
      - 进阶规则
      - 特殊情况

  - name: 深度评分
    criteria:
      - 非常识性
      - 具体可操作
      - 有来源支撑
```

### ✅ Phase 5 自检流程

**执行命令**：
```bash
# 检查 GitHub 资源整合结果
echo "=== Phase 5 自检 ===" && \
SKILL_DIR="/home/aiscend/work/vibelife/apps/api/skills/{skill}" && \
echo "GITHUB_RESOURCES.md 存在:" && ls -la $SKILL_DIR/GITHUB_RESOURCES.md 2>/dev/null && \
echo "GITHUB_RESOURCES.md 大小:" && wc -l $SKILL_DIR/GITHUB_RESOURCES.md 2>/dev/null && \
echo "从 GitHub 提取的规则数:" && grep -c "GitHub:" $SKILL_DIR/rules/rules.yaml 2>/dev/null
```

**合格标准**：
| 检查项 | 合格标准 | 不合格处理 |
|-------|---------|-----------|
| GITHUB_RESOURCES.md | 存在且 > 50 行 | 补充搜索更多项目 |
| 计算库 | 至少找到 1 个可用库 | 扩大搜索范围 |
| 从 GitHub 提取的规则 | ≥ 10 条 | 深入阅读项目源码 |

**不合格时**：
- 未找到相关项目：尝试其他搜索关键词
- 项目质量不佳：降低 Stars 要求，或寻找小众但专业的项目
- 提取规则少：深入阅读项目的核心逻辑代码

---

## 使用示例

### 示例 1：从零构建 MBTI Skill

```bash
# 全流程执行
vibe-skill --theme mbti --input "MBTI personality type books"

# 执行流程：
# Phase 1: 搜索 MBTI 相关书籍 → 下载到 candidates/
# Phase 2: PDF → MD 转换 → 存储到 converted/
# Phase 3: 向量化入库
# Phase 4: 提取专家知识 → 生成 SKILL.md, methods/, rules/
# Phase 5: 优化规则

# 输出：
# ✅ 知识库：/data/vibelife/knowledge/mbti/
# ✅ Skill：/apps/api/skills/mbti/
```

### 示例 2：从本地文件构建

```bash
# 跳过搜寻，直接从本地文件开始
vibe-skill --phase convert,vectorize,extract,optimize \
           --theme career \
           --input /path/to/career_books/

# 执行流程：
# Phase 2: 转换所有文件
# Phase 3: 向量化入库
# Phase 4: 提取专家知识
# Phase 5: 优化规则
```

### 示例 3：仅优化现有 Skill

```bash
# 对已有的 zodiac skill 进行优化
vibe-skill --phase optimize --theme zodiac

# 执行流程：
# Phase 5: 分析现有规则 → 去重 → 补充 → 验证
```

### 示例 4：批量处理书单

```bash
# 提供书单文件
vibe-skill --theme bazi --input /path/to/booklist.txt

# booklist.txt 格式：
# 子平真诠
# 滴天髓
# 穷通宝鉴
# ...
```

---

## 目录结构

### 知识库目录

```
/data/vibelife/knowledge/
└── {theme}/
    ├── candidates/           # 候选文件（按来源分类）
    │   ├── github/
    │   ├── archive_org/
    │   └── other/
    ├── selected/             # 选出的最佳版本
    ├── source/               # 原始文件（PDF/EPUB等）
    └── converted/            # 转换后的 MD 文件
        └── *.converted.md    # 统一命名格式
```

### Skill 目录

```
/home/aiscend/work/vibelife/apps/api/skills/
└── {skill}/
    ├── SKILL.md              # 专家 Meta
    ├── meta.json             # 元数据
    ├── methods/              # 方法库
    │   └── *.yaml
    ├── workflows/            # 工作流
    │   └── main_flow.yaml
    ├── rules/                # 规则库
    │   └── rules.yaml
    ├── decision_trees/       # 决策树
    │   └── *.yaml
    └── templates/            # 模板库
        └── *.yaml
```

---

## 核心原则

1. **质量优先**：只入库高质量内容，拒绝低质量或空结构
2. **深度优先**：提取大模型不知道的专业知识，过滤常识
3. **可追溯**：所有规则标注来源
4. **可迭代**：支持增量更新和优化
5. **模块化**：各阶段可独立执行

---

## 禁止行为

1. **禁止创建骨架/占位文件**
2. **禁止入库空内容**（文件大小 < 50KB）
3. **禁止猜测/编写内容**
4. **禁止跳过质量评估**
5. **禁止提取常识性规则**
6. **禁止无来源的规则**
