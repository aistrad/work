# Fortune AI 八字报告与运势模块设计 v1

**文档类型**：Module Design Specification
**版本**：v1.0
**日期**：2026-01-01
**模块定位**：跑通八字报告生成与运势分析的完整闭环
**工程边界**：对齐 `system_design_final_mvp.md`，前端对齐 `frontend_final_v1.md`

---

## 0. 设计目标与北极星

### 0.1 核心目标

在 Fortune AI 现有架构上，实现用户从「出生信息输入」到「八字报告生成」到「运势分析输出」到「行动处方」的完整闭环。

```
用户输入出生信息 → 真太阳时八字计算 → 知识库检索 → 深度报告生成 → 今日/周/月运势 → 行动处方 → 用户闭环
```

### 0.2 模块边界

本模块聚焦以下功能：

| 功能 | 描述 | 入口 |
|-----|------|-----|
| **八字排盘** | 基于真太阳时计算四柱、十神、神煞、大运流年 | 注册 / Profile 更新 |
| **八字报告** | 深度分析报告（异步生成，支持 `backend=cli\|gemini`） | 工具 Tab / Chat |
| **今日运势** | 基于八字 + 当日干支的每日指引 | Dashboard 概览 / Chat |
| **周/月运势** | 周期性运势分析与建议 | Dashboard 概览 / 探索 Tab |
| **流年运势** | 年度运势预测与关键节点提示 | 探索 Tab / 深度报告 |

### 0.3 与现有系统的关系

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Fortune AI 系统架构                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                   │
│  │   注册流程   │────▶│  八字计算    │────▶│  facts 存储  │                   │
│  │ /api/auth/  │     │ bazi_facts  │     │  snapshot   │                   │
│  └─────────────┘     └─────────────┘     └──────┬──────┘                   │
│                                                  │                          │
│                    ┌─────────────────────────────┴───────────────────────┐  │
│                    │                                                      │  │
│                    ▼                                                      │  │
│  ┌─────────────────────────────┐     ┌────────────────────────────────┐  │
│  │     八字报告模块（新增）       │     │       运势分析模块（新增）       │  │
│  │  • 深度报告生成               │     │  • 今日运势                     │  │
│  │  • CLI/Gemini Backend        │     │  • 周/月运势                    │  │
│  │  • A2UI 输出                 │     │  • 流年运势                     │  │
│  └───────────────┬─────────────┘     └──────────────┬─────────────────┘  │
│                  │                                   │                    │
│                  └───────────────┬───────────────────┘                    │
│                                  │                                        │
│                                  ▼                                        │
│  ┌───────────────────────────────────────────────────────────────────────┐│
│  │                          Chat Agent (GLM/Vercel)                              ││
│  │            facts + kb_refs + rule_ids → A2UI + Guidance Card           ││
│  └───────────────────────────────────────────────────────────────────────┘│
│                                  │                                        │
│                                  ▼                                        │
│  ┌───────────────────────────────────────────────────────────────────────┐│
│  │                    前端渲染（Zone A Chat + Zone B Dashboard）          ││
│  └───────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. 数据模型设计

### 1.1 现有表复用

| 表名 | 用途 | 本模块使用方式 |
|-----|------|--------------|
| `fortune_user` | 用户信息 | 读取出生信息（birthday_local, tz_offset_hours, location, gender） |
| `fortune_bazi_snapshot` | 八字事实快照 | 读取 facts JSON，作为分析基础 |
| `fortune_daily_guidance` | 每日指引 | 存储今日运势卡片 |
| `fortune_external_job` | 外部任务映射 | 跟踪报告生成任务状态 |
| `bazi_kb_chunk` | 知识库 | 检索八字解读依据 |
| `fortune_rule` | 规则库 | 存储运势计算规则 |

### 1.2 新增表：运势快照

```sql
-- 运势快照表（缓存计算结果，避免重复计算）
CREATE TABLE IF NOT EXISTS fortune_yunshi_snapshot (
    snapshot_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
    snapshot_type TEXT NOT NULL CHECK (snapshot_type IN ('daily', 'weekly', 'monthly', 'annual')),
    snapshot_date DATE NOT NULL,          -- 运势所属日期/周一/月一/年初
    bazi_facts_hash TEXT NOT NULL,        -- 关联的八字事实 hash（确保一致性）

    -- 运势分析结果
    analysis JSONB NOT NULL,              -- 完整分析结果
    highlights JSONB NOT NULL DEFAULT '[]', -- 关键亮点（用于概览展示）
    risks JSONB NOT NULL DEFAULT '[]',    -- 风险提示
    prescriptions JSONB NOT NULL DEFAULT '[]', -- 行动处方（≤3 条）

    -- 元数据
    compute_version TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,               -- 过期时间（daily 次日过期）

    UNIQUE (user_id, snapshot_type, snapshot_date, bazi_facts_hash)
);

CREATE INDEX IF NOT EXISTS idx_yunshi_user_type_date ON fortune_yunshi_snapshot
    (user_id, snapshot_type, snapshot_date DESC);
CREATE INDEX IF NOT EXISTS idx_yunshi_expires ON fortune_yunshi_snapshot
    (expires_at) WHERE expires_at IS NOT NULL;
```

### 1.3 新增表：八字报告

```sql
-- 八字深度报告表（独立于 fortune_external_job，存储报告内容）
CREATE TABLE IF NOT EXISTS fortune_bazi_report (
    report_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
    external_job_id BIGINT REFERENCES fortune_external_job(id) ON DELETE SET NULL,

    -- 报告类型与配置
    report_type TEXT NOT NULL DEFAULT 'full' CHECK (report_type IN ('full', 'summary', 'career', 'relationship', 'health')),
    backend TEXT NOT NULL CHECK (backend IN ('cli', 'gemini', 'glm')),
    model TEXT,                           -- 使用的模型
    system_prompt TEXT,                   -- 使用的 system prompt

    -- 输入快照
    bazi_facts_hash TEXT NOT NULL,
    input_context JSONB NOT NULL DEFAULT '{}',  -- 用户额外输入的上下文

    -- 输出内容
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'error')),
    output_markdown TEXT,                 -- Markdown 格式报告
    output_a2ui JSONB,                    -- A2UI 格式输出
    output_summary TEXT,                  -- 一句话摘要

    -- 关键提取（便于检索与展示）
    key_findings JSONB DEFAULT '[]',      -- 核心发现
    prescriptions JSONB DEFAULT '[]',     -- 行动处方

    -- 元数据
    error_message TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,

    -- 版本追溯
    compute_version TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bazi_report_user_time ON fortune_bazi_report
    (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bazi_report_status ON fortune_bazi_report
    (status, created_at DESC);
```

### 1.4 规则库扩展

```sql
-- 运势计算规则
INSERT INTO fortune_rule (rule_id, category, name, body) VALUES

-- 日干支与日主的关系规则
('RULE-DAILY-DAYGAN-V1', 'yunshi_daily', '日干与日主关系', '{
  "description": "当日天干与日主的五行生克关系",
  "relations": {
    "same": {"name": "比肩", "score": 0, "desc": "平稳，宜守成"},
    "generates": {"name": "印绶", "score": 2, "desc": "有助力，贵人运"},
    "generated": {"name": "食伤", "score": 1, "desc": "适合表达、创作"},
    "controls": {"name": "财星", "score": 1, "desc": "适合财务、事业推进"},
    "controlled": {"name": "官杀", "score": -1, "desc": "压力增大，宜谨慎"}
  }
}'::jsonb),

-- 日支与日主的关系规则
('RULE-DAILY-DAYZHI-V1', 'yunshi_daily', '日支与日主关系', '{
  "description": "当日地支与日主的影响",
  "special_branches": {
    "taohua": "桃花日，人际与感情活跃",
    "yima": "驿马日，适合出行与变动",
    "huagai": "华盖日，适合学习与内省",
    "tianyi": "贵人日，易得助力"
  }
}'::jsonb),

-- 流年运势规则
('RULE-LIUNIAN-INTERACTION-V1', 'yunshi_annual', '流年与八字作用', '{
  "description": "流年干支与原局的作用关系",
  "key_interactions": ["天克地冲", "天合地合", "伏吟", "反吟"],
  "scoring": {
    "天克地冲": {"score": -3, "desc": "动荡年份，需谨慎"},
    "天合地合": {"score": 2, "desc": "和谐年份，机遇多"},
    "伏吟": {"score": -1, "desc": "重复模式，易有压力"},
    "反吟": {"score": -2, "desc": "反复变化，不宜大动"}
  }
}'::jsonb)

ON CONFLICT (rule_id) DO UPDATE SET
  category = EXCLUDED.category,
  name = EXCLUDED.name,
  body = EXCLUDED.body,
  updated_at = now();
```

---

## 2. 核心服务设计

### 2.1 运势计算服务 (`services/yunshi_service.py`)

```python
"""
运势计算服务
- 今日运势：基于八字 + 当日干支
- 周运势：基于本周关键日干支
- 月运势：基于月令与八字的作用
- 流年运势：基于流年干支与八字的作用
"""

from __future__ import annotations
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional
from lunar_python import Lunar, Solar

@dataclass
class DailyYunshi:
    """今日运势结果"""
    date: date
    day_ganzhi: str              # 当日干支
    day_gan_relation: str        # 日干与日主关系（比肩/印绶/食伤/财星/官杀）
    day_zhi_specials: List[str]  # 日支特殊标记（桃花/驿马等）
    score: int                   # 综合评分 (-10 ~ +10)
    highlights: List[str]        # 亮点（≤3 条）
    risks: List[str]             # 风险提示（≤2 条）
    prescriptions: List[Dict]    # 行动处方（≤3 条，含 task_id）
    time_windows: List[Dict]     # 时辰窗口（吉时/凶时）
    evidence: Dict               # 证据（rule_ids + kb_refs）

@dataclass
class AnnualYunshi:
    """流年运势结果"""
    year: int
    liu_nian_ganzhi: str
    da_yun_ganzhi: str           # 当前大运
    key_interactions: List[str]  # 关键作用（天合/天冲等）
    score: int
    themes: List[str]            # 年度主题
    key_months: List[Dict]       # 关键月份提示
    prescriptions: List[Dict]
    evidence: Dict


class YunshiService:
    """运势计算服务"""

    def __init__(self, db_conn, kb_service, rule_store):
        self.db = db_conn
        self.kb = kb_service
        self.rules = rule_store

    def compute_daily_yunshi(
        self,
        user_id: int,
        target_date: Optional[date] = None,
    ) -> DailyYunshi:
        """
        计算今日运势

        流程：
        1. 读取用户 bazi_snapshot (facts)
        2. 计算目标日期的干支
        3. 分析日干与日主的五行关系
        4. 分析日支的特殊标记（桃花/驿马等）
        5. 检索知识库获取解读依据
        6. 生成综合评分与行动处方
        """
        target_date = target_date or date.today()

        # 1. 获取八字事实
        facts = self._get_user_facts(user_id)
        day_master = facts["bazi"]["day_master"]
        shensha = facts["bazi"]["shensha"]

        # 2. 计算当日干支
        solar = Solar.fromDate(target_date)
        lunar = solar.getLunar()
        day_gan = lunar.getDayGan()
        day_zhi = lunar.getDayZhi()
        day_ganzhi = day_gan + day_zhi

        # 3. 分析五行关系
        relation = self._compute_gan_relation(day_master["element"], day_gan)

        # 4. 分析地支特殊标记
        specials = self._check_branch_specials(day_zhi, facts)

        # 5. 检索知识库
        kb_refs = self.kb.search_by_ganzhi(day_ganzhi, limit=5)

        # 6. 计算评分与生成处方
        score = self._compute_daily_score(relation, specials)
        prescriptions = self._generate_daily_prescriptions(
            relation=relation,
            specials=specials,
            score=score,
            user_id=user_id,
        )

        return DailyYunshi(
            date=target_date,
            day_ganzhi=day_ganzhi,
            day_gan_relation=relation["name"],
            day_zhi_specials=specials,
            score=score,
            highlights=self._build_highlights(relation, specials),
            risks=self._build_risks(relation, specials),
            prescriptions=prescriptions,
            time_windows=self._compute_time_windows(day_ganzhi, day_master),
            evidence={
                "rule_ids": ["RULE-DAILY-DAYGAN-V1", "RULE-DAILY-DAYZHI-V1"],
                "kb_refs": kb_refs,
            },
        )

    def compute_annual_yunshi(
        self,
        user_id: int,
        target_year: Optional[int] = None,
    ) -> AnnualYunshi:
        """
        计算流年运势

        流程：
        1. 读取八字事实（含大运）
        2. 获取流年干支
        3. 分析流年与原局的作用
        4. 分析当前大运与流年的叠加
        5. 确定年度主题与关键月份
        6. 生成行动处方
        """
        target_year = target_year or datetime.now().year

        facts = self._get_user_facts(user_id)
        luck = facts["bazi"]["luck"]

        # 获取流年干支
        liu_nian_ganzhi = self._get_liunian_ganzhi(target_year)

        # 获取当前大运
        da_yun = self._get_current_dayun(luck["da_yun"], target_year)

        # 分析作用关系
        interactions = self._analyze_liunian_interactions(
            liu_nian_ganzhi=liu_nian_ganzhi,
            pillars=facts["bazi"]["pillars"],
            da_yun_ganzhi=da_yun["gan_zhi"] if da_yun else "",
        )

        # 计算评分与主题
        score = self._compute_annual_score(interactions)
        themes = self._extract_annual_themes(interactions, facts)

        return AnnualYunshi(
            year=target_year,
            liu_nian_ganzhi=liu_nian_ganzhi,
            da_yun_ganzhi=da_yun["gan_zhi"] if da_yun else "",
            key_interactions=interactions,
            score=score,
            themes=themes,
            key_months=self._identify_key_months(target_year, facts),
            prescriptions=self._generate_annual_prescriptions(themes, score),
            evidence={
                "rule_ids": ["RULE-LIUNIAN-INTERACTION-V1"],
                "kb_refs": [],
            },
        )

    # === 辅助方法 ===

    def _get_user_facts(self, user_id: int) -> Dict[str, Any]:
        """获取用户八字事实快照"""
        from services.bazi_facts import ensure_snapshot_for_user
        snapshot = ensure_snapshot_for_user(user_id)
        return snapshot["facts"]

    def _compute_gan_relation(self, day_master_element: str, target_gan: str) -> Dict:
        """计算天干五行关系"""
        GAN_ELEMENT = {
            "甲": "木", "乙": "木", "丙": "火", "丁": "火",
            "戊": "土", "己": "土", "庚": "金", "辛": "金",
            "壬": "水", "癸": "水",
        }
        ELEMENT_REL = {
            "木": {"generator": "水", "produces": "火", "controls": "土", "controlled_by": "金"},
            "火": {"generator": "木", "produces": "土", "controls": "金", "controlled_by": "水"},
            "土": {"generator": "火", "produces": "金", "controls": "水", "controlled_by": "木"},
            "金": {"generator": "土", "produces": "水", "controls": "木", "controlled_by": "火"},
            "水": {"generator": "金", "produces": "木", "controls": "火", "controlled_by": "土"},
        }

        target_element = GAN_ELEMENT.get(target_gan, "")
        if target_element == day_master_element:
            return {"name": "比肩", "score": 0, "desc": "平稳，宜守成"}

        rel = ELEMENT_REL[day_master_element]
        if target_element == rel["generator"]:
            return {"name": "印绶", "score": 2, "desc": "有助力，贵人运"}
        if target_element == rel["produces"]:
            return {"name": "食伤", "score": 1, "desc": "适合表达、创作"}
        if target_element == rel["controls"]:
            return {"name": "财星", "score": 1, "desc": "适合财务、事业推进"}
        if target_element == rel["controlled_by"]:
            return {"name": "官杀", "score": -1, "desc": "压力增大，宜谨慎"}

        return {"name": "未知", "score": 0, "desc": ""}

    def _check_branch_specials(self, day_zhi: str, facts: Dict) -> List[str]:
        """检查地支特殊标记"""
        specials = []
        shensha = facts["bazi"].get("shensha", [])

        for ss in shensha:
            # 检查当日地支是否命中神煞的触发条件
            # 这里需要根据神煞规则判断
            pass

        return specials

    def _compute_daily_score(self, relation: Dict, specials: List[str]) -> int:
        """计算每日综合评分"""
        score = relation.get("score", 0)

        # 特殊标记加分
        if "贵人日" in specials:
            score += 2
        if "桃花日" in specials:
            score += 1

        return max(-10, min(10, score))

    def _generate_daily_prescriptions(
        self,
        relation: Dict,
        specials: List[str],
        score: int,
        user_id: int,
    ) -> List[Dict]:
        """生成每日行动处方"""
        prescriptions = []

        if relation["name"] == "印绶":
            prescriptions.append({
                "content": "今日贵人运佳，可主动寻求帮助或建立新连接",
                "estimated_minutes": 15,
                "priority": "high",
            })
        elif relation["name"] == "官杀":
            prescriptions.append({
                "content": "今日压力较大，做 3 分钟正念呼吸再处理重要事务",
                "estimated_minutes": 3,
                "priority": "high",
            })

        # 保证至少有一个处方
        if not prescriptions:
            prescriptions.append({
                "content": "回顾今日目标，完成最重要的一件事",
                "estimated_minutes": 5,
                "priority": "medium",
            })

        return prescriptions[:3]  # 最多 3 条
```

### 2.2 八字报告服务 (`services/bazi_report_service.py`)

```python
"""
八字深度报告服务
- 支持 backend=cli|gemini|glm
- 异步生成，轮询状态
- 输出 Markdown + A2UI
"""

from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional
from enum import Enum

class ReportBackend(Enum):
    CLI = "cli"
    GEMINI = "gemini"
    GLM = "glm"

class ReportType(Enum):
    FULL = "full"           # 完整八字报告
    SUMMARY = "summary"     # 摘要版
    CAREER = "career"       # 事业方向
    RELATIONSHIP = "relationship"  # 感情婚姻
    HEALTH = "health"       # 健康养生


@dataclass
class ReportRequest:
    user_id: int
    report_type: ReportType
    backend: ReportBackend
    model: Optional[str] = None
    system_prompt: Optional[str] = None
    extra_context: Optional[Dict] = None


@dataclass
class ReportResult:
    report_id: int
    status: str  # processing | completed | error
    output_markdown: Optional[str] = None
    output_a2ui: Optional[Dict] = None
    output_summary: Optional[str] = None
    key_findings: Optional[list] = None
    prescriptions: Optional[list] = None
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class BaziReportService:
    """八字深度报告服务"""

    # 报告生成 System Prompt
    REPORT_SYSTEM_PROMPT = """你是 Fortune AI 的八字分析师，基于积极心理学与绩效教练框架，为用户提供建设性、可执行的八字分析报告。

【产品定位】
人生导航 / 陪伴 / 提升。你的分析应当：
1. 提供清晰的性格特质与潜能分析
2. 识别发展优势与成长机会
3. 给出具体可执行的行动建议
4. 避免宿命论断言，强调"可调整"与"可发展"

【分析框架】
1. 命局概述：四柱结构、五行分布、日主状态
2. 性格画像：核心特质、优势能力、潜在挑战
3. 发展方向：适合的发展领域与路径
4. 流年提示：近期关键节点与机遇
5. 行动处方：当下最重要的 3 个行动建议

【输出要求】
- 使用积极心理学话术，不恐吓、不定性
- 负面信息必须紧跟"你可以做什么"
- 行动建议必须具体、可执行、有时间边界

【禁止事项】
- 禁止输出确定性宿命论断言（如"一生注定"）
- 禁止编造经典出处
- 禁止涉及医疗/法律/投资具体建议"""

    def __init__(self, db_conn, backend_router, kb_service):
        self.db = db_conn
        self.backend_router = backend_router
        self.kb = kb_service

    async def submit_report(self, request: ReportRequest) -> int:
        """
        提交报告生成任务

        流程：
        1. 获取用户八字事实
        2. 检索相关知识库内容
        3. 构建报告生成 Prompt
        4. 根据 backend 提交任务
        5. 写入 fortune_bazi_report 记录
        6. 返回 report_id
        """
        from services.bazi_facts import ensure_snapshot_for_user

        # 1. 获取八字事实
        snapshot = ensure_snapshot_for_user(request.user_id)
        facts = snapshot["facts"]
        facts_hash = snapshot["facts_hash"]

        # 2. 检索知识库
        kb_refs = await self._search_relevant_kb(facts)

        # 3. 构建 Prompt
        user_prompt = self._build_report_prompt(
            facts=facts,
            report_type=request.report_type,
            kb_refs=kb_refs,
            extra_context=request.extra_context,
        )

        system_prompt = request.system_prompt or self.REPORT_SYSTEM_PROMPT

        # 4. 提交到后端
        if request.backend == ReportBackend.GLM:
            # 同步生成（适用于短报告）
            result = await self._generate_with_glm(
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                model=request.model or "glm-4.7",
            )
            status = "completed"
            external_job_id = None
        else:
            # 异步生成（CLI / Gemini）
            external_job_id = await self.backend_router.submit(
                backend=request.backend.value,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                model=request.model,
            )
            result = None
            status = "processing"

        # 5. 写入记录
        report_id = await self._create_report_record(
            user_id=request.user_id,
            report_type=request.report_type.value,
            backend=request.backend.value,
            model=request.model,
            system_prompt=system_prompt,
            bazi_facts_hash=facts_hash,
            input_context=request.extra_context or {},
            external_job_id=external_job_id,
            status=status,
            result=result,
        )

        return report_id

    async def get_report(self, report_id: int, user_id: int) -> ReportResult:
        """
        获取报告结果

        - 如果是异步任务且未完成，轮询后端状态
        - 完成后更新数据库记录
        """
        record = await self._get_report_record(report_id, user_id)
        if not record:
            raise ValueError("report_not_found")

        if record["status"] == "processing" and record.get("external_job_id"):
            # 轮询后端状态
            backend_status = await self.backend_router.get_status(
                backend=record["backend"],
                job_id=record["external_job_id"],
            )

            if backend_status["status"] == "completed":
                # 更新记录
                await self._update_report_completed(
                    report_id=report_id,
                    output=backend_status["output"],
                )
                record["status"] = "completed"
                record["output_markdown"] = backend_status["output"].get("markdown")
                record["output_a2ui"] = backend_status["output"].get("a2ui")
            elif backend_status["status"] == "error":
                await self._update_report_error(
                    report_id=report_id,
                    error=backend_status.get("error", "unknown_error"),
                )
                record["status"] = "error"
                record["error_message"] = backend_status.get("error")

        return ReportResult(
            report_id=report_id,
            status=record["status"],
            output_markdown=record.get("output_markdown"),
            output_a2ui=record.get("output_a2ui"),
            output_summary=record.get("output_summary"),
            key_findings=record.get("key_findings"),
            prescriptions=record.get("prescriptions"),
            error_message=record.get("error_message"),
            created_at=record.get("created_at"),
            completed_at=record.get("completed_at"),
        )

    def _build_report_prompt(
        self,
        facts: Dict,
        report_type: ReportType,
        kb_refs: list,
        extra_context: Optional[Dict],
    ) -> str:
        """构建报告生成 Prompt"""

        profile = facts.get("profile", {})
        bazi = facts.get("bazi", {})

        prompt_parts = [
            "## 用户八字信息",
            f"- 性别：{profile.get('gender', '')}",
            f"- 出生时间（真太阳时）：{facts.get('solar_time', {}).get('true_solar_time_local', '')}",
            f"- 出生地：{profile.get('location', {}).get('name', '')}",
            "",
            "## 四柱",
            f"- 年柱：{bazi.get('pillars', {}).get('year', '')}",
            f"- 月柱：{bazi.get('pillars', {}).get('month', '')}",
            f"- 日柱：{bazi.get('pillars', {}).get('day', '')}",
            f"- 时柱：{bazi.get('pillars', {}).get('hour', '')}",
            "",
            "## 日主",
            f"- 天干：{bazi.get('day_master', {}).get('gan', '')}",
            f"- 五行：{bazi.get('day_master', {}).get('element', '')}",
            "",
            "## 五行分布",
            str(bazi.get("wuxing_count", {})),
            "",
            "## 旺衰分析",
            f"- 状态：{bazi.get('strength', {}).get('status', '')}",
            f"- 喜用神：{bazi.get('strength', {}).get('favorable_elements', [])}",
            "",
            "## 神煞",
        ]

        for ss in bazi.get("shensha", []):
            prompt_parts.append(f"- {ss.get('name', '')}: {'命中' if ss.get('hit') else '未命中'}")

        prompt_parts.extend([
            "",
            "## 大运",
        ])

        for dy in bazi.get("luck", {}).get("da_yun", [])[:5]:
            prompt_parts.append(
                f"- {dy.get('start_age', '')}-{dy.get('end_age', '')}岁 "
                f"({dy.get('start_year', '')}-{dy.get('end_year', '')}): {dy.get('gan_zhi', '')}"
            )

        # 添加知识库引用
        if kb_refs:
            prompt_parts.extend([
                "",
                "## 相关命理知识参考",
            ])
            for ref in kb_refs[:5]:
                prompt_parts.append(f"- {ref.get('content', '')[:200]}...")

        # 添加用户额外上下文
        if extra_context:
            prompt_parts.extend([
                "",
                "## 用户关注点",
                str(extra_context.get("question", "")),
            ])

        # 根据报告类型添加指引
        type_instructions = {
            ReportType.FULL: "请生成完整的八字分析报告，涵盖性格、事业、感情、健康各方面。",
            ReportType.SUMMARY: "请生成精简的八字摘要，重点突出核心特质与近期建议。",
            ReportType.CAREER: "请重点分析事业发展方向与职业建议。",
            ReportType.RELATIONSHIP: "请重点分析感情婚姻与人际关系。",
            ReportType.HEALTH: "请重点分析健康养生与生活方式建议。",
        }

        prompt_parts.extend([
            "",
            "## 报告要求",
            type_instructions.get(report_type, type_instructions[ReportType.FULL]),
            "",
            "请按以下结构输出报告：",
            "1. 一句话总结（≤50字）",
            "2. 命局概述",
            "3. 核心分析（按报告类型聚焦）",
            "4. 流年提示",
            "5. 行动处方（≤3条，具体可执行）",
        ])

        return "\n".join(prompt_parts)
```

---

## 3. API 设计

### 3.1 今日运势 API

```yaml
# GET /api/yunshi/today
# 获取今日运势

Response:
  ok: true
  data:
    date: "2026-01-01"
    day_ganzhi: "甲子"
    summary: "今日印绶日，贵人运佳，适合寻求帮助与建立连接"
    score: 7
    highlights:
      - "贵人运佳，有助力"
      - "适合学习与交流"
    risks:
      - "避免冲动决策"
    prescriptions:
      - task_id: "uuid"
        content: "主动联系一位可以帮助你的人"
        estimated_minutes: 15
        priority: "high"
    time_windows:
      - hour: "9-11点"
        quality: "吉"
        suggestion: "适合重要沟通"
    a2ui:
      meta:
        summary: "今日贵人运佳"
      ui_components:
        - type: "markdown_text"
          title: "今日运势"
          data: "### 甲子日 · 印绶\n\n今日贵人运佳..."
        - type: "action_buttons"
          title: "行动"
          data:
            - label: "开始今日任务"
              action:
                type: "start_task"
                task_id: "uuid"
```

### 3.2 八字报告 API

```yaml
# POST /api/report/bazi/submit
# 提交八字报告生成任务

Request:
  backend: "glm"  # cli | gemini | glm
  report_type: "full"  # full | summary | career | relationship | health
  model: "glm-4.7"  # 可选
  system_prompt: ""  # 可选，自定义 system prompt
  extra_context:
    question: "我想了解事业发展方向"  # 用户额外关注点

Response:
  ok: true
  data:
    report_id: 101
    backend: "glm"
    status: "processing"  # processing | completed

---

# GET /api/report/bazi/{report_id}
# 获取报告结果

Response (processing):
  ok: true
  data:
    report_id: 101
    status: "processing"
    created_at: "2026-01-01T10:00:00Z"

Response (completed):
  ok: true
  data:
    report_id: 101
    status: "completed"
    output_summary: "日主丁火，身弱喜木火，适合创意与表达领域发展"
    output_markdown: "# 八字分析报告\n\n## 命局概述..."
    output_a2ui:
      meta:
        summary: "八字深度报告"
      ui_components:
        - type: "markdown_text"
          title: "报告内容"
          data: "..."
        - type: "action_buttons"
          title: "下一步"
          data:
            - label: "保存为资产页"
              action:
                type: "save_as_page"
            - label: "分享报告"
              action:
                type: "share"
    key_findings:
      - "日主丁火，身弱需要生扶"
      - "适合创意、表达、教育领域"
    prescriptions:
      - content: "每周安排 2 小时深度学习时间"
        estimated_minutes: 120
      - content: "本月尝试一次公开表达（分享/演讲）"
        estimated_minutes: 30
    completed_at: "2026-01-01T10:05:00Z"
```

### 3.3 流年运势 API

```yaml
# GET /api/yunshi/annual?year=2026
# 获取流年运势

Response:
  ok: true
  data:
    year: 2026
    liu_nian_ganzhi: "丙午"
    da_yun_ganzhi: "癸未"
    summary: "丙午流年，火旺之年，适合表达与行动"
    score: 6
    themes:
      - "表达与展示"
      - "人际拓展"
      - "事业突破"
    key_months:
      - month: 3
        theme: "贵人月，适合求助"
      - month: 7
        theme: "压力月，宜谨慎"
    prescriptions:
      - content: "上半年重点突破，下半年收尾沉淀"
      - content: "注意情绪管理，避免冲动决策"
    a2ui:
      meta:
        summary: "2026 流年运势"
      ui_components:
        - type: "markdown_text"
          title: "流年概览"
          data: "..."
```

---

## 4. 前端集成设计

### 4.1 入口与交互流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        用户交互流程                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  入口 1：Dashboard 概览 Tab                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │ │
│  │  │   今日指引卡      │  │   运势卡片        │  │   流年提示        │     │ │
│  │  │   (daily_guidance)│  │   (daily_yunshi) │  │   (annual_hint)  │     │ │
│  │  │                   │  │                   │  │                   │     │ │
│  │  │ 一句话结论        │  │ 今日干支:甲子     │  │ 2026 丙午年      │     │ │
│  │  │ + 行动按钮        │  │ 评分:⭐⭐⭐⭐     │  │ 主题:表达与行动  │     │ │
│  │  │                   │  │ 亮点/风险        │  │                   │     │ │
│  │  │ [查看详情]        │  │ [展开详情]       │  │ [查看流年]       │     │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘     │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  入口 2：探索 Tab - 玄学探索区                                               │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  ┌──────────────────┐  ┌──────────────────┐                           │ │
│  │  │   八字运势        │  │   深度报告        │                           │ │
│  │  │   (bazi_yunshi)   │  │   (bazi_report)   │                           │ │
│  │  │                   │  │                   │                           │ │
│  │  │ 今日/周/月运势    │  │ 生成深度八字报告  │                           │ │
│  │  │                   │  │ ≈5分钟           │                           │ │
│  │  │ [立即查看]        │  │ [开始生成]        │                           │ │
│  │  └──────────────────┘  └──────────────────┘                           │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  入口 3：Chat 对话                                                           │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  用户: "我想看看今天的运势"                                             │ │
│  │  ↓                                                                      │ │
│  │  助手: [返回 A2UI 运势卡 + 行动按钮]                                    │ │
│  │  ↓                                                                      │ │
│  │  用户: "帮我生成一份八字报告"                                           │ │
│  │  ↓                                                                      │ │
│  │  助手: [触发报告生成 + 返回进度提示 + 完成后推送]                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 组件设计

#### 4.2.1 今日运势卡片

```tsx
// components/yunshi/DailyYunshiCard.tsx

interface DailyYunshiCardProps {
  date: string;
  dayGanzhi: string;
  summary: string;
  score: number;
  highlights: string[];
  risks: string[];
  prescriptions: Prescription[];
  onPrescriptionClick: (taskId: string) => void;
}

export function DailyYunshiCard({
  date,
  dayGanzhi,
  summary,
  score,
  highlights,
  risks,
  prescriptions,
  onPrescriptionClick,
}: DailyYunshiCardProps) {
  return (
    <Card className="bg-sidebar hover:shadow-hover transition-shadow">
      {/* 标题区 */}
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-2xl">🌟</span>
            <div>
              <CardTitle className="text-base">今日运势</CardTitle>
              <p className="text-xs text-muted-foreground">
                {date} · {dayGanzhi}
              </p>
            </div>
          </div>
          <ScoreBadge score={score} />
        </div>
      </CardHeader>

      {/* 内容区 */}
      <CardContent className="space-y-3">
        {/* 一句话总结 */}
        <p className="text-sm">{summary}</p>

        {/* 亮点 */}
        {highlights.length > 0 && (
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">亮点</p>
            <ul className="text-sm space-y-1">
              {highlights.map((h, i) => (
                <li key={i} className="flex items-center gap-1">
                  <span className="text-status">✓</span> {h}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* 风险提示 */}
        {risks.length > 0 && (
          <div className="space-y-1">
            <p className="text-xs text-muted-foreground">注意</p>
            <ul className="text-sm space-y-1">
              {risks.map((r, i) => (
                <li key={i} className="flex items-center gap-1">
                  <span className="text-alert">!</span> {r}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* 行动处方 */}
        {prescriptions.length > 0 && (
          <div className="pt-2 border-t border-border">
            <p className="text-xs text-muted-foreground mb-2">今日行动</p>
            <div className="space-y-2">
              {prescriptions.map((p) => (
                <Button
                  key={p.task_id}
                  variant="outline"
                  size="sm"
                  className="w-full justify-start text-left h-auto py-2"
                  onClick={() => onPrescriptionClick(p.task_id)}
                >
                  <div>
                    <p className="text-sm">{p.content}</p>
                    <p className="text-xs text-muted-foreground">
                      约 {p.estimated_minutes} 分钟
                    </p>
                  </div>
                </Button>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

#### 4.2.2 八字报告生成面板

```tsx
// components/report/BaziReportPanel.tsx

interface BaziReportPanelProps {
  onClose: () => void;
}

export function BaziReportPanel({ onClose }: BaziReportPanelProps) {
  const [reportType, setReportType] = useState<ReportType>('full');
  const [backend, setBackend] = useState<ReportBackend>('glm');
  const [question, setQuestion] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'completed' | 'error'>('idle');
  const [report, setReport] = useState<ReportResult | null>(null);

  const handleSubmit = async () => {
    setStatus('loading');
    try {
      const { report_id } = await api.post('/api/report/bazi/submit', {
        report_type: reportType,
        backend,
        extra_context: question ? { question } : undefined,
      });

      // 轮询结果
      const result = await pollReportStatus(report_id);
      setReport(result);
      setStatus('completed');
    } catch (error) {
      setStatus('error');
      toast.error('报告生成失败，请重试');
    }
  };

  return (
    <Sheet open onOpenChange={onClose}>
      <SheetContent className="w-full sm:max-w-xl overflow-y-auto">
        <SheetHeader>
          <SheetTitle>生成八字报告</SheetTitle>
          <SheetDescription>
            基于你的八字，生成个性化分析报告
          </SheetDescription>
        </SheetHeader>

        {status === 'idle' && (
          <div className="space-y-6 py-4">
            {/* 报告类型选择 */}
            <div className="space-y-2">
              <Label>报告类型</Label>
              <RadioGroup value={reportType} onValueChange={setReportType}>
                <div className="grid grid-cols-2 gap-2">
                  <RadioItem value="full" label="完整报告" desc="全面分析" />
                  <RadioItem value="summary" label="精简版" desc="核心要点" />
                  <RadioItem value="career" label="事业方向" desc="职业发展" />
                  <RadioItem value="relationship" label="感情婚姻" desc="人际关系" />
                </div>
              </RadioGroup>
            </div>

            {/* 额外问题 */}
            <div className="space-y-2">
              <Label>你想了解什么？（可选）</Label>
              <Textarea
                placeholder="例如：我想了解事业发展方向..."
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
                rows={3}
              />
            </div>

            {/* 生成按钮 */}
            <Button onClick={handleSubmit} className="w-full">
              开始生成
            </Button>

            <p className="text-xs text-muted-foreground text-center">
              预计需要 3-5 分钟
            </p>
          </div>
        )}

        {status === 'loading' && (
          <div className="py-12 text-center space-y-4">
            <Loader className="animate-spin mx-auto h-8 w-8" />
            <p>正在生成报告...</p>
            <p className="text-sm text-muted-foreground">
              正在分析八字信息，请稍候
            </p>
          </div>
        )}

        {status === 'completed' && report && (
          <div className="py-4 space-y-4">
            {/* 报告摘要 */}
            <div className="p-4 bg-advice rounded-lg">
              <p className="text-sm font-medium">{report.output_summary}</p>
            </div>

            {/* 报告内容 */}
            <div className="prose prose-sm max-w-none">
              <ReactMarkdown>{report.output_markdown}</ReactMarkdown>
            </div>

            {/* 行动处方 */}
            {report.prescriptions && (
              <div className="space-y-2">
                <h4 className="font-medium">行动处方</h4>
                {report.prescriptions.map((p, i) => (
                  <div key={i} className="p-3 bg-sidebar rounded-lg">
                    <p className="text-sm">{p.content}</p>
                  </div>
                ))}
              </div>
            )}

            {/* 操作按钮 */}
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => saveAsPage(report)}>
                保存为资产页
              </Button>
              <Button variant="outline" onClick={() => shareReport(report)}>
                分享
              </Button>
            </div>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
```

### 4.3 Dashboard 探索 Tab 集成

```tsx
// app/(main)/dashboard/explore/page.tsx

export default function ExplorePage() {
  return (
    <div className="space-y-6">
      {/* 玄学探索区 */}
      <section>
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <span>✨</span> 玄学探索
        </h2>
        <div className="grid grid-cols-2 gap-4">
          {/* 八字运势卡片 */}
          <ExploreCard
            icon="🌟"
            title="八字运势"
            description="今日运势详解"
            onClick={() => router.push('/dashboard/explore/yunshi')}
          />

          {/* 深度报告卡片 */}
          <ExploreCard
            icon="📊"
            title="深度报告"
            description="生成八字分析报告"
            onClick={() => setShowReportPanel(true)}
          />

          {/* 塔罗占卜 */}
          <ExploreCard
            icon="🎴"
            title="塔罗占卜"
            description="今日运势指引"
            onClick={() => router.push('/dashboard/explore/tarot')}
          />

          {/* 星盘解读 */}
          <ExploreCard
            icon="⭐"
            title="星盘解读"
            description="本周星象分析"
            onClick={() => router.push('/dashboard/explore/astro')}
          />
        </div>
      </section>

      {/* 修习课程区 */}
      <section>
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <span>📚</span> 修习课程
        </h2>
        <PlanList />
      </section>

      {/* 报告生成面板 */}
      {showReportPanel && (
        <BaziReportPanel onClose={() => setShowReportPanel(false)} />
      )}
    </div>
  );
}
```

---

## 5. Chat 集成设计

### 5.1 意图识别与路由

```python
# services/chat_service.py 扩展

YUNSHI_INTENTS = [
    r"今[天日].*运势",
    r"运势.*怎么样",
    r"今[天日].*适合",
    r"看[看一]下?运势",
    r"本[周月年].*运势",
    r"流年.*运势",
]

REPORT_INTENTS = [
    r"八字.*报告",
    r"生成.*报告",
    r"分析.*八字",
    r"详细.*分析",
    r"深度.*报告",
]

def detect_yunshi_intent(message: str) -> Optional[str]:
    """检测运势相关意图"""
    import re
    for pattern in YUNSHI_INTENTS:
        if re.search(pattern, message):
            if "周" in message:
                return "weekly"
            if "月" in message:
                return "monthly"
            if "年" in message or "流年" in message:
                return "annual"
            return "daily"
    return None

def detect_report_intent(message: str) -> bool:
    """检测报告生成意图"""
    import re
    return any(re.search(p, message) for p in REPORT_INTENTS)
```

### 5.2 Chat 处理流程

```python
async def handle_chat_message(
    user_id: int,
    session_id: str,
    message: str,
) -> Dict:
    """处理聊天消息"""

    # 1. 检测运势意图
    yunshi_intent = detect_yunshi_intent(message)
    if yunshi_intent:
        return await handle_yunshi_query(user_id, yunshi_intent)

    # 2. 检测报告意图
    if detect_report_intent(message):
        return await handle_report_query(user_id, session_id)

    # 3. 默认 GLM 对话
    return await handle_general_chat(user_id, session_id, message)


async def handle_yunshi_query(user_id: int, intent: str) -> Dict:
    """处理运势查询"""
    yunshi_service = YunshiService(...)

    if intent == "daily":
        yunshi = yunshi_service.compute_daily_yunshi(user_id)
        return {
            "type": "yunshi",
            "a2ui": build_yunshi_a2ui(yunshi),
            "suggested_tasks": [
                {"task_id": str(uuid4()), **p} for p in yunshi.prescriptions
            ],
        }
    elif intent == "annual":
        yunshi = yunshi_service.compute_annual_yunshi(user_id)
        return {
            "type": "yunshi",
            "a2ui": build_annual_yunshi_a2ui(yunshi),
            "suggested_tasks": [],
        }
    # ... 其他类型


async def handle_report_query(user_id: int, session_id: str) -> Dict:
    """处理报告生成请求"""
    return {
        "type": "report_prompt",
        "a2ui": {
            "meta": {"summary": "生成八字报告"},
            "ui_components": [
                {
                    "type": "markdown_text",
                    "title": "八字报告",
                    "data": "我可以为你生成一份详细的八字分析报告。报告包括：\n\n"
                           "1. 命局概述与性格画像\n"
                           "2. 发展方向与优势分析\n"
                           "3. 流年运势与关键节点\n"
                           "4. 个性化行动建议\n\n"
                           "预计需要 3-5 分钟生成。",
                },
                {
                    "type": "action_buttons",
                    "title": "选择",
                    "data": [
                        {"label": "生成完整报告", "action": {"type": "open_panel", "panel": "bazi_report"}},
                        {"label": "生成精简版", "action": {"type": "submit_report", "report_type": "summary"}},
                        {"label": "暂不需要", "action": {"type": "opt_out"}},
                    ],
                },
            ],
        },
    }
```

---

## 6. 实施计划

### Phase 1：核心数据与 API（1 周）

| 任务 | 描述 | 交付物 |
|-----|------|-------|
| 数据库迁移 | 创建 `fortune_yunshi_snapshot`、`fortune_bazi_report` 表 | DDL 脚本 |
| 规则库扩展 | 添加运势计算规则 | SQL Insert |
| 运势计算服务 | 实现 `YunshiService` 核心方法 | `yunshi_service.py` |
| 今日运势 API | `GET /api/yunshi/today` | 可测试 API |

### Phase 2：报告生成（1 周）

| 任务 | 描述 | 交付物 |
|-----|------|-------|
| 报告服务 | 实现 `BaziReportService` | `bazi_report_service.py` |
| GLM 报告生成 | 支持 `backend=glm` 同步生成 | 集成测试 |
| CLI/Gemini 集成 | 支持异步报告生成 | backend_router 扩展 |
| 报告 API | `POST/GET /api/report/bazi/*` | 可测试 API |

### Phase 3：前端集成（1 周）

| 任务 | 描述 | 交付物 |
|-----|------|-------|
| 今日运势卡片 | Dashboard 概览 Tab 集成 | React 组件 |
| 探索 Tab 改造 | 玄学探索区 + 报告入口 | 页面改造 |
| 报告生成面板 | Sheet 组件 + 轮询逻辑 | React 组件 |
| A2UI 渲染增强 | 支持运势相关 A2UI | 渲染器扩展 |

### Phase 4：Chat 集成与优化（1 周）

| 任务 | 描述 | 交付物 |
|-----|------|-------|
| 意图识别 | 运势/报告意图检测 | chat_service 扩展 |
| Chat 路由 | 运势查询→运势卡片 | 处理流程 |
| 报告触发 | Chat 中触发报告生成 | 集成测试 |
| 端到端测试 | 完整闭环验证 | 测试报告 |

---

## 7. 验收标准

### 7.1 功能验收

| 场景 | 预期结果 |
|-----|---------|
| 用户查看今日运势 | 显示当日干支、评分、亮点、风险、行动处方 |
| 用户在 Chat 问"今天运势" | 返回今日运势 A2UI 卡片 + 可点击按钮 |
| 用户生成八字报告 | 3-5 分钟内生成完整 Markdown 报告 + 处方 |
| 用户点击处方按钮 | 处方转为任务并可跟踪完成 |
| 用户查看流年运势 | 显示年度主题、关键月份、行动建议 |

### 7.2 技术验收

| 指标 | 标准 |
|-----|------|
| 今日运势 API 响应时间 | ≤ 500ms |
| 报告生成时间（GLM） | ≤ 60s |
| A2UI action_buttons 渲染 | 100% 可点击 |
| 缓存命中率 | ≥ 80%（同日同用户） |

### 7.3 闭环验收

```sql
-- 运势→行动闭环完成率
SELECT
  COUNT(DISTINCT c.user_id) AS users_with_yunshi_task_done,
  COUNT(DISTINCT y.user_id) AS users_viewed_yunshi
FROM fortune_yunshi_snapshot y
LEFT JOIN fortune_commitment c ON
  c.user_id = y.user_id
  AND c.source = 'yunshi'
  AND c.status = 'done'
  AND c.created_at::date = y.snapshot_date
WHERE y.snapshot_type = 'daily'
  AND y.snapshot_date >= CURRENT_DATE - INTERVAL '7 days';
```

---

## 附录 A：A2UI 输出示例

### 今日运势 A2UI

```json
{
  "meta": {
    "summary": "今日印绶日，贵人运佳"
  },
  "ui_components": [
    {
      "type": "markdown_text",
      "title": "今日运势",
      "data": "### 2026年1月1日 · 甲子日 · 印绶\n\n**综合评分：⭐⭐⭐⭐ (7/10)**\n\n#### 亮点\n- ✓ 贵人运佳，有助力\n- ✓ 适合学习与交流\n\n#### 注意\n- ! 避免冲动决策\n\n#### 时辰提示\n- 🕘 9-11点：适合重要沟通\n- 🕑 13-15点：适合学习思考"
    },
    {
      "type": "action_buttons",
      "title": "今日行动",
      "data": [
        {
          "label": "主动联系一位贵人",
          "action": {
            "type": "start_task",
            "task_id": "4aa0f0e2-acde-4e2f-acde-0c3c0d9610e1"
          }
        },
        {
          "label": "加入今日计划",
          "action": {
            "type": "schedule_task",
            "task_id": "4aa0f0e2-acde-4e2f-acde-0c3c0d9610e1"
          }
        },
        {
          "label": "查看详细分析",
          "action": {
            "type": "open_panel",
            "panel": "yunshi_detail"
          }
        }
      ]
    }
  ]
}
```

---

## 附录 B：与现有代码的对接点

| 现有文件 | 对接方式 |
|---------|---------|
| `services/bazi_facts.py` | 直接调用 `ensure_snapshot_for_user()` 获取八字事实 |
| `services/kb_service.py` | 调用知识库检索获取解读依据 |
| `services/chat_service.py` | 扩展意图识别与路由逻辑 |
| `services/task_service.py` | 将处方写入 `fortune_commitment` |
| `integrations/backend_router.py` | 调用异步报告生成 |
| `api/dashboard_routes.py` | 新增 `/api/yunshi/*` 路由 |
| `api/bazi_routes.py` | 扩展 `/api/report/bazi/*` 路由 |

---

*本文档为 Fortune AI 八字报告与运势模块的完整设计，对齐 `system_design_final_mvp.md` 架构与 `frontend_final_v1.md` 前端规范。*
