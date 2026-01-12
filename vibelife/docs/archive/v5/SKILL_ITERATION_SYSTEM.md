# VibeLife Skill 知识提炼与迭代系统

## 概述

本文档定义了 Skill 知识的自动提炼、迭代和灰度发布机制。

## 架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Knowledge Pipeline                                │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │   Source     │───▶│   Curator    │───▶│  Vectorize   │              │
│  │  (书籍/资料) │    │  (筛选整理)  │    │  (向量化)    │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                 │                        │
│                                                 ▼                        │
│                                          ┌──────────────┐               │
│                                          │  Knowledge   │               │
│                                          │    Store     │               │
│                                          │  (pgvecto)   │               │
│                                          └──────────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
┌────────────────���────────────────────────────────────────────────────────┐
│                        Skill Distillation                                │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │  Knowledge   │───▶│   Distill    │───▶│   SKILL.md   │              │
│  │   Sampler    │    │    Agent     │    │   + Assets   │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
│  从知识库采样         提炼 SOP/方法        生成 Skill 文件               │
│  代表性内容           分析原则/表达        scripts/templates             │
└─────────────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Feedback Loop                                     │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │ Conversation │───▶│   Quality    │───▶│   Insight    │              │
│  │    Logs      │    │   Analyzer   │    │   Extractor  │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                 │                        │
│  对话记录             LLM 分析对话质量         提取改进建议              │
│                       识别问题模式                                       │
└─────────────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Iteration & Release                               │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │   Draft      │───▶│   Canary     │───▶│   Release    │              │
│  │  Generator   │    │   Deploy     │    │   (全量)     │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
│  生成新版本草稿       灰度发布 (5%)         效果好则全量                 │
│  SKILL.v2.md          A/B 测试                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 1. 知识提炼 (Skill Distillation)

### 1.1 Knowledge Sampler

从知识库中采样代表性内容，用于提炼 SOP。

```python
class KnowledgeSampler:
    """从知识库采样代表性内容"""

    async def sample(self, skill_id: str, categories: List[str]) -> List[KnowledgeChunk]:
        """
        采样策略：
        1. 按 category 分层采样
        2. 优先高质量内容（score > 0.8）
        3. 覆盖不同主题
        """
        samples = []
        for category in categories:
            chunks = await self._sample_category(skill_id, category, limit=10)
            samples.extend(chunks)
        return samples
```

### 1.2 Distill Agent

使用 LLM 从知识库内容中提炼 SOP。

```python
DISTILL_PROMPT = """
你是一个专业知识提炼专家。

## 任务
从以下知识库内容中提炼出 {skill_name} 的分析方法和 SOP。

## 知识库内容
{knowledge_samples}

## 输出格式
请输出以下内容：

### 1. 分析 SOP
- 步骤 1: ...
- 步骤 2: ...

### 2. 核心原则
- 原则 1: ...
- 原则 2: ...

### 3. 表达规范
- 应该: ...
- 避免: ...

### 4. 可提取为脚本的逻辑
- 逻辑 1: ... (可用 Python 实现)
- 逻辑 2: ...
"""

class DistillAgent:
    """从知识库提炼 SOP"""

    async def distill(self, skill_id: str) -> DistillResult:
        # 1. 采样知识库
        sampler = KnowledgeSampler()
        samples = await sampler.sample(skill_id, ["methodology", "principles", "examples"])

        # 2. 调用 LLM 提炼
        prompt = DISTILL_PROMPT.format(
            skill_name=skill_id,
            knowledge_samples=self._format_samples(samples)
        )
        result = await self.llm.chat(prompt)

        # 3. 解析输出
        return self._parse_result(result)
```

### 1.3 Asset Generator

将可执行逻辑沉淀为脚本。

```python
class AssetGenerator:
    """生成 Skill 资产文件"""

    async def generate(self, distill_result: DistillResult, skill_id: str):
        skill_dir = SKILLS_DIR / skill_id

        # 1. 生成 SKILL.md
        skill_md = self._generate_skill_md(distill_result)
        (skill_dir / "SKILL.md").write_text(skill_md)

        # 2. 生成 scripts/
        scripts_dir = skill_dir / "scripts"
        scripts_dir.mkdir(exist_ok=True)

        for logic in distill_result.extractable_logic:
            script = self._generate_script(logic)
            (scripts_dir / f"{logic.name}.py").write_text(script)

        # 3. 生成 templates/
        if distill_result.templates:
            templates_dir = skill_dir / "templates"
            templates_dir.mkdir(exist_ok=True)
            for template in distill_result.templates:
                (templates_dir / f"{template.name}.md").write_text(template.content)
```

## 2. 反馈分析 (Feedback Analysis)

### 2.1 Quality Analyzer

使用 LLM 分析对话质量。

```python
QUALITY_ANALYSIS_PROMPT = """
你是一个对话质量分析专家。

## 任务
分析以下对话，评估 AI 回复的质量。

## 对话记录
{conversation}

## 评估维度
1. 专业准确性 (1-5): 命理/占星知识是否准确
2. 表达清晰度 (1-5): 是否通俗易懂
3. 情感共鸣度 (1-5): 是否有温度
4. 实用性 (1-5): 建议是否可操作
5. 用户满意度推测 (1-5): 基于用户后续反应

## 输出格式
{
  "scores": {...},
  "issues": ["问题1", "问题2"],
  "improvements": ["改进建议1", "改进建议2"],
  "good_patterns": ["值得保留的模式1", ...]
}
"""

class QualityAnalyzer:
    """分析对话质量"""

    async def analyze(self, conversation: Conversation) -> QualityReport:
        prompt = QUALITY_ANALYSIS_PROMPT.format(
            conversation=self._format_conversation(conversation)
        )
        result = await self.llm.chat(prompt)
        return QualityReport.parse(result)

    async def batch_analyze(self, conversations: List[Conversation]) -> BatchReport:
        """批量分析，提取共性问题"""
        reports = []
        for conv in conversations:
            report = await self.analyze(conv)
            reports.append(report)

        return self._aggregate_reports(reports)
```

### 2.2 Insight Extractor

从分析结果中提取改进洞察。

```python
class InsightExtractor:
    """从质量分析中提取改进洞察"""

    async def extract(self, batch_report: BatchReport) -> List[Insight]:
        """
        提取洞察：
        1. 高频问题 → 需要修复
        2. 低分维度 → 需要加强
        3. 好的模式 → 需要保留
        """
        insights = []

        # 高频问题
        for issue, count in batch_report.issue_frequency.items():
            if count > batch_report.total * 0.1:  # 超过 10% 出现
                insights.append(Insight(
                    type="issue",
                    description=issue,
                    frequency=count / batch_report.total,
                    priority="high" if count > batch_report.total * 0.3 else "medium"
                ))

        # 低分维度
        for dim, avg_score in batch_report.avg_scores.items():
            if avg_score < 3.5:
                insights.append(Insight(
                    type="weakness",
                    description=f"{dim} 平均分 {avg_score:.1f}，需要加强",
                    priority="high" if avg_score < 3.0 else "medium"
                ))

        return insights
```

## 3. 迭代发布 (Iteration & Release)

### 3.1 Draft Generator

基于洞察生成新版本草稿。

```python
ITERATION_PROMPT = """
你是一个 Skill 优化专家。

## 当前 SKILL.md
{current_skill}

## 改进洞察
{insights}

## 知识库补充
{knowledge_supplement}

## 任务
基于以上信息，生成改进后的 SKILL.md。

## 要求
1. 保留原有好的部分
2. 针对问题进行改进
3. 补充缺失的知识
4. 不要大幅改变风格
"""

class DraftGenerator:
    """生成新版本草稿"""

    async def generate(
        self,
        skill_id: str,
        insights: List[Insight],
        knowledge_supplement: str
    ) -> SkillDraft:
        current_skill = load_skill(skill_id)

        prompt = ITERATION_PROMPT.format(
            current_skill=current_skill.content,
            insights=self._format_insights(insights),
            knowledge_supplement=knowledge_supplement
        )

        new_content = await self.llm.chat(prompt)

        return SkillDraft(
            skill_id=skill_id,
            version=self._next_version(current_skill),
            content=new_content,
            changes=insights
        )
```

### 3.2 Canary Deploy

灰度发布机制。

```python
class CanaryDeploy:
    """灰度发布管理"""

    def __init__(self, redis_client):
        self.redis = redis_client

    async def deploy(self, draft: SkillDraft, canary_percent: float = 0.05):
        """
        部署灰度版本

        Args:
            draft: 新版本草稿
            canary_percent: 灰度比例 (默认 5%)
        """
        # 1. 保存草稿到 canary 目录
        canary_path = SKILLS_DIR / draft.skill_id / f"SKILL.v{draft.version}.md"
        canary_path.write_text(draft.content)

        # 2. 设置灰度配置
        await self.redis.hset(f"skill:canary:{draft.skill_id}", {
            "version": draft.version,
            "percent": canary_percent,
            "deployed_at": datetime.now().isoformat()
        })

    async def get_skill_version(self, skill_id: str, user_id: str) -> str:
        """
        获取用户应该使用的 Skill 版本

        基于 user_id hash 决定是否使用灰度版本
        """
        canary = await self.redis.hgetall(f"skill:canary:{skill_id}")
        if not canary:
            return "stable"

        # 基于 user_id 决定是否灰度
        user_hash = hash(user_id) % 100
        if user_hash < canary["percent"] * 100:
            return canary["version"]
        return "stable"

    async def promote(self, skill_id: str, version: str):
        """将灰度版本提升为正式版本"""
        canary_path = SKILLS_DIR / skill_id / f"SKILL.v{version}.md"
        stable_path = SKILLS_DIR / skill_id / "SKILL.md"

        # 备份当前版本
        backup_path = SKILLS_DIR / skill_id / f"SKILL.backup.{datetime.now().strftime('%Y%m%d')}.md"
        shutil.copy(stable_path, backup_path)

        # 提升灰度版本
        shutil.copy(canary_path, stable_path)

        # 清除灰度配置
        await self.redis.delete(f"skill:canary:{skill_id}")

    async def rollback(self, skill_id: str):
        """回滚灰度版本"""
        await self.redis.delete(f"skill:canary:{skill_id}")
```

### 3.3 A/B Metrics

灰度效果评估。

```python
class ABMetrics:
    """A/B 测试指标收集"""

    async def record(self, skill_id: str, version: str, conversation_id: str, quality_score: float):
        """记录对话质量分数"""
        await self.redis.lpush(
            f"skill:metrics:{skill_id}:{version}",
            json.dumps({
                "conversation_id": conversation_id,
                "score": quality_score,
                "timestamp": datetime.now().isoformat()
            })
        )

    async def compare(self, skill_id: str) -> ABCompareResult:
        """比较稳定版和灰度版的效果"""
        stable_scores = await self._get_scores(skill_id, "stable")
        canary = await self.redis.hgetall(f"skill:canary:{skill_id}")

        if not canary:
            return None

        canary_scores = await self._get_scores(skill_id, canary["version"])

        return ABCompareResult(
            stable_avg=sum(stable_scores) / len(stable_scores) if stable_scores else 0,
            canary_avg=sum(canary_scores) / len(canary_scores) if canary_scores else 0,
            stable_count=len(stable_scores),
            canary_count=len(canary_scores),
            improvement=(canary_avg - stable_avg) / stable_avg if stable_avg > 0 else 0
        )
```

## 4. 完整流程

### 4.1 初始提炼流程

```python
async def initial_distill(skill_id: str):
    """从知识库初始提炼 Skill"""

    # 1. 采样知识库
    sampler = KnowledgeSampler()
    samples = await sampler.sample(skill_id, ["methodology", "principles", "examples"])

    # 2. 提炼 SOP
    distiller = DistillAgent()
    result = await distiller.distill(skill_id)

    # 3. 生成资产
    generator = AssetGenerator()
    await generator.generate(result, skill_id)

    print(f"✓ Skill {skill_id} 初始提炼完成")
```

### 4.2 迭代更新流程

```python
async def iterate_skill(skill_id: str, conversation_ids: List[str]):
    """基于对话反馈迭代 Skill"""

    # 1. 批量分析对话质量
    analyzer = QualityAnalyzer()
    conversations = await load_conversations(conversation_ids)
    batch_report = await analyzer.batch_analyze(conversations)

    # 2. 提取改进洞察
    extractor = InsightExtractor()
    insights = await extractor.extract(batch_report)

    if not insights:
        print("没有发现需要改进的问题")
        return

    # 3. 从知识库补充相关知识
    knowledge = await RAGService.get_knowledge(
        query=" ".join([i.description for i in insights]),
        skill_id=skill_id,
        top_k=10
    )

    # 4. 生成新版本草稿
    generator = DraftGenerator()
    draft = await generator.generate(skill_id, insights, knowledge)

    # 5. 灰度发布
    canary = CanaryDeploy(redis_client)
    await canary.deploy(draft, canary_percent=0.05)

    print(f"✓ Skill {skill_id} v{draft.version} 已灰度发布 (5%)")
```

### 4.3 灰度评估流程

```python
async def evaluate_canary(skill_id: str):
    """评估灰度效果"""

    metrics = ABMetrics(redis_client)
    result = await metrics.compare(skill_id)

    if not result:
        print("没有灰度版本")
        return

    print(f"稳定版平均分: {result.stable_avg:.2f} ({result.stable_count} 次对话)")
    print(f"灰度版平均分: {result.canary_avg:.2f} ({result.canary_count} 次对话)")
    print(f"提升: {result.improvement:.1%}")

    # 自动决策
    if result.canary_count >= 100 and result.improvement > 0.05:
        print("建议: 灰度版效果显著提升，可以全量发布")
    elif result.canary_count >= 100 and result.improvement < -0.05:
        print("建议: 灰度版效果下降，建议回滚")
    else:
        print("建议: 继续观察，数据量不足")
```

## 5. Skill 目录结构（完整版）

```
apps/api/skills/
├── bazi/
│   ├── SKILL.md              # 当前稳定版
│   ├── SKILL.v2.md           # 灰度版本 (可选)
│   ├── SKILL.backup.*.md     # 历史备份
│   ├── scripts/              # 可执行脚本
│   │   ├── analyze_pattern.py
│   │   └── calculate_fortune.py
│   ├── templates/            # 模板文件
│   │   ├── report_template.md
│   │   └── greeting_template.md
│   └── assets/               # 其他资产
│       └── ten_gods_table.json
├── zodiac/
│   └── ...
└── core/
    └── ...
```

## 6. CLI 命令

```bash
# 初始提炼
python -m skills.cli distill bazi

# 分析对话质量
python -m skills.cli analyze bazi --days 7

# 生成迭代草稿
python -m skills.cli iterate bazi

# 灰度发布
python -m skills.cli canary deploy bazi --percent 5

# 查看灰度效果
python -m skills.cli canary status bazi

# 全量发布
python -m skills.cli canary promote bazi

# 回滚
python -m skills.cli canary rollback bazi
```

## 7. 配置

```yaml
# config/skill_iteration.yaml
distill:
  sample_size: 50           # 每个类别采样数量
  categories:               # 采样类别
    - methodology
    - principles
    - examples
    - cases

feedback:
  min_conversations: 100    # 最小分析对话数
  analysis_batch_size: 20   # 批量分析大小

canary:
  default_percent: 0.05     # 默认灰度比例
  min_samples: 100          # 最小样本数才能评估
  promote_threshold: 0.05   # 提升阈值 (5%)
  rollback_threshold: -0.05 # 回滚阈值 (-5%)
```
