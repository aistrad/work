# Knowledge Base v2 设计文档

> Version: 2.4 | 2026-01-19
> 核心理念：从原文抽取 Cases，存入数据库，倒排索引 + Context Build

---

## 1. 核心概念

**Cases**：从原文 LLM 抽取的结构化案例

- 存储在数据库中（不存文件）
- 用于相似案例参考、推理示范
- 通过 `rule_ids` 关联到 `skills/{skill}/rules/` 下的规则文件

---

## 2. Case 数据模型

### 数据库表：`skill_cases`

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(64) | 案例 ID，如 `case_bazi_001` |
| skill_id | VARCHAR(32) | 所属 Skill |
| name | VARCHAR(128) | 案例名称 |
| tags | TEXT[] | 特征标签（用于倒排索引匹配） |
| rule_ids | TEXT[] | 关联的规则 ID |
| content | TEXT | 案例正文（Markdown） |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### 示例数据

```json
{
  "id": "case_bazi_001",
  "skill_id": "bazi",
  "name": "戊土身强正官格",
  "tags": ["戊土", "身强", "正官格", "管理"],
  "rule_ids": ["career", "basic-reading"],
  "content": "# 戊土身强正官格案例\n\n## 命盘\n年: 甲子 | 月: 丙寅 | 日: 戊辰 | 时: 壬子 | 男\n\n## 分析\n日主戊土生于寅月，辰土为根，身强。\n壬水正官透出，无伤无破，正官格成立。\n\n## 指导\n- 身强用官，适合管理、公职类工作\n- 正官格主贵，事业有成\n- 宜走水运、金运"
}
```

---

## 3. 目录结构

```
skills/{skill}/
├── SKILL.md              # Skill 定义
└── rules/                # 人工定义的规则（已有）
    ├── basic-reading.md
    ├── career.md
    └── ...
```

> Cases 只存数据库，不存文件

---

## 4. 倒排索引

### 索引结构（内存缓存）

```python
# Case 索引：tag → case_ids
CASE_INDEX = {
    "bazi": {
        "戊土": ["case_001", "case_005"],
        "身强": ["case_001", "case_003"],
        "正官格": ["case_001"],
        "甲木": ["case_002", "case_004"],
    }
}

# Case-Rule 关联：case_id → rule_ids
CASE_RULE_MAP = {
    "case_001": ["career", "basic-reading"],
    "case_002": ["relationship"],
}
```

### 匹配逻辑

```python
def match_cases(skill_id: str, features: Dict, rule_id: str = None) -> List[str]:
    """基于命盘特征匹配 Cases"""
    index = CASE_INDEX[skill_id]
    scores = {}

    # 特征匹配
    for key, value in features.items():
        if value in index:
            for case_id in index[value]:
                scores[case_id] = scores.get(case_id, 0) + 1

    # 如果指定了 rule_id，优先返回关联的 case
    if rule_id:
        for case_id, rule_ids in CASE_RULE_MAP.items():
            if rule_id in rule_ids and case_id in scores:
                scores[case_id] += 2  # 关联加分

    return sorted(scores, key=lambda x: -scores[x])[:2]
```

---

## 5. Context Build

```python
async def _build_system_prompt(self, message: str, context: AgentContext) -> str:
    parts = []

    # 1. Skill 基础
    skill = load_skill(self._active_skill)
    parts.append(f"# {skill.name}\n\n{skill.expert_persona}")

    # 2. 匹配 Cases → 从数据库加载正文
    if context.skill_data:
        features = extract_features(context.skill_data)
        matched_case_ids = match_cases(self._active_skill, features)
        if matched_case_ids:
            parts.append("\n---\n## 相关案例\n")
            cases = await case_repo.get_by_ids(matched_case_ids)
            for case in cases:
                parts.append(f"### {case.name}\n{case.content}\n")

    # 3. 用户上下文
    if context.profile:
        parts.append(format_user_context(context))

    return "\n".join(parts)
```

---

## 6. Case 抽取流程

### 抽取 Prompt

```markdown
从以下文本中抽取案例。

## 当前 Skill: {skill_id}

## 可用的 Rules（用于 rule_ids 关联）
{rules_list}

## 输出格式（JSON）
[
  {
    "id": "case_{skill}_{序号}",
    "name": "案例名称",
    "tags": ["特征1", "特征2", "特征3"],
    "rule_ids": ["关联规则1", "关联规则2"],
    "content": "# 案例名称\n\n## 命盘/背景\n...\n\n## 分析\n...\n\n## 指导\n..."
  }
]

## 注意事项
1. tags 应包含命盘特征（如日主、身强身弱、格局）
2. rule_ids 必须从上方 Rules 列表中选择，选择最相关的 1-3 个
3. content 要包含完整的分析推理过程

## 待分析文本
{text}
```

### 抽取脚本

```python
class CaseExtractor:
    def __init__(self, skill_id: str, case_repo: CaseRepository):
        self.skill_id = skill_id
        self.case_repo = case_repo
        self.available_rules = get_skill_rules(skill_id)

    async def extract_from_file(self, md_path: Path) -> List[Case]:
        content = md_path.read_text()
        rules_list = "\n".join(f"- {r}" for r in self.available_rules)

        prompt = CASE_EXTRACTION_PROMPT.format(
            skill_id=self.skill_id,
            rules_list=rules_list,
            text=content[:8000]
        )

        response = await self._call_llm(prompt)
        return self._parse_cases(response)

    async def save_cases(self, cases: List[Case]):
        """保存到数据库"""
        for case in cases:
            case.skill_id = self.skill_id
            await self.case_repo.upsert(case)
```

---

## 7. 构建流程

```bash
# Stage 0: 格式转换
python scripts/build_knowledge.py --skill bazi --stages 0

# Stage 1: 抽取 Cases → 存入数据库
python scripts/build_knowledge.py --skill bazi --stages 1
```

### Stage 0: 格式转换
```
source/*.pdf → converted/*.md
```

### Stage 1: 抽取 Cases
```
converted/*.md → LLM 抽取 → 数据库 skill_cases 表
```

---

## 8. 数据流图

```
┌─────────────────────────────────────────────────────────────┐
│                    Knowledge System v2                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  原文 (data/knowledge/{skill}/source/)              │    │
│  └────────────────────┬────────────────────────────────┘    │
│                       │                                      │
│                       ▼ LLM 抽取                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  数据库: skill_cases 表                              │    │
│  │  - id, skill_id, name, tags, rule_ids, content     │    │
│  └────────────────────┬────────────────────────────────┘    │
│                       │                                      │
│                       │ tags                                 │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Case 倒排索引（内存缓存）                           │    │
│  │  tag → case_ids                                     │    │
│  └────────────────────┬────────────────────────────────┘    │
│                       │                                      │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Context Builder                                     │    │
│  │  用户命盘特征 → 匹配 Cases → 从 DB 加载正文         │    │
│  └────────────────────┬────────────────────────────────┘    │
│                       │                                      │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  System Prompt                                       │    │
│  │  # Skill                                            │    │
│  │  ## 相关案例                                         │    │
│  │  ## 用户上下文                                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. 实现清单

### 新增
- `stores/case_repo.py` - Case 数据库 Repository
- `services/agent/case_index.py` - Case 倒排索引（内存缓存）
- `workers/case_extractor_v2.py` - Case 抽取器（存数据库）

### 修改
- `services/agent/core.py` - 修改 `_build_system_prompt`，加入 Case 匹配
- `stores/db.py` - 添加 `skill_cases` 表

### 删除
- `workers/chunker.py`
- `workers/ingestion.py`
- `workers/scenario_extractor.py`
- `services/knowledge/retrieval.py`
- `services/knowledge/embedding.py`
- `services/knowledge/repository.py` 中的 `search_knowledge`
