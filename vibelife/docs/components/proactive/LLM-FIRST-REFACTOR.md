# Proactive 模块 LLM-First 重构设计 v3.0

> Version: 3.0 | Date: 2026-01-25
> 目标：将 Proactive 系统升级为 LLM-First + Agent 驱动架构

---

## 概述

本文档定义 Proactive 模块从 v2.0（硬编码架构）到 v3.0（LLM-First + Agent 驱动）的升级方案。核心变化是消除 TriggerDetector 和 ContentGenerator 中的硬编码逻辑，统一复用 CoreAgent 能力。

### 设计原则

| 原则 | v2.0 | v3.0 |
|-----|------|------|
| 触发检测 | 10+ 硬编码 `_detect_*` 方法 | 声明式 conditions + 静态求值优先 |
| 内容生成 | 10+ 硬编码 `_generate_*` 方法 | 调用 CoreAgent Phase 2 |
| 新增功能 | 需要修改 Python 代码 | 只需修改 YAML + rules/*.md |
| 与 Agent 关系 | 独立系统 | 统一架构，复用 Agent |

### LLM-First ≠ 什么都让 LLM 做

**核心理解**：LLM-First 是指**业务逻辑配置化**，由 LLM 解读执行，而非把所有计算都交给 LLM。

```python
# ❌ 错误理解：所有判断都让 LLM 做
conditions_result = await llm.evaluate("检查 birth_info 是否存在")

# ✅ 正确理解：确定性计算由平台做，复杂语义由 LLM 做
if condition.operator in STATIC_OPERATORS:
    result = static_eval(condition, profile)  # 平台计算
else:
    result = await llm.evaluate(condition)    # LLM 推理
```

**分层原则**：
| 层级 | 职责 | 示例 |
|-----|------|------|
| 平台层 | 确定性计算 | cron 匹配、exists 检查、数值比较、时区转换 |
| 配置层 | 声明式规则 | conditions、rules/*.md |
| LLM 层 | 语义推理 | 复杂条件组合、自然语言理解、内容生成 |

---

## 架构对比

### v2.0 架构（当前）

```
┌─────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│ ProactiveWorker │───▶│ ProactiveEngine  │───▶│ TriggerDetector    │
└─────────────────┘    │                  │    │ (643 行硬编码)     │
                       │                  │    │ _detect_birthday() │
                       │                  │    │ _detect_dayun()    │
                       │                  │    │ _check_has_data()  │
                       │                  │    │ ...10+ 方法        │
                       │                  │    └────────────────────┘
                       │                  │    ┌────────────────────┐
                       │                  │───▶│ ContentGenerator   │
                       └──────────────────┘    │ (1037 行硬编码)    │
                                               │ _generate_fortune()│
                                               │ _generate_dayun()  │
                                               │ ...10+ 方法        │
                                               └────────────────────┘
```

### v3.0 架构（目标）

```
┌─────────────────┐    ┌──────────────────────┐    ┌──────────────────┐
│ ProactiveWorker │───▶│ ProactiveOrchestrator│───▶│ TriggerEvaluator │
└─────────────────┘    │ (纯配置加载+分发)    │    │ (LLM 评估触发)   │
                       │                      │    │ - cron 匹配      │
                       │                      │    │ - LLM conditions │
                       │                      │    └──────────────────┘
                       │                      │    ┌──────────────────┐
                       │                      │───▶│ CoreAgent.run()  │
                       └──────────────────────┘    │ (复用 Phase 2)   │
                                                   │ - Skill 工具     │
                                                   │ - Rules 规则     │
                                                   │ - 知识检索       │
                                                   └──────────────────┘
```

---

## 需要删除的硬编码

### TriggerDetector（trigger_detector.py，643 行）

| 方法 | 替代方案 |
|------|---------|
| `_detect_birthday()` | `conditions: [{event: birthday}]` + LLM 评估 |
| `_detect_dayun_change()` | `conditions: [{event: dayun_change}]` + LLM 评估 |
| `_detect_new_year()` | `conditions: [{event: new_year}]` + LLM 评估 |
| `_detect_solar_term()` | `conditions: [{event: solar_term}]` + LLM 评估 |
| `_detect_lunar_phase()` | `conditions: [{event: lunar_phase}]` + LLM 评估 |
| `_detect_mercury_retrograde()` | `conditions: [{event: mercury_retrograde}]` + LLM 评估 |
| `_detect_significant_transit()` | `conditions: [{event: significant_transit}]` + LLM 评估 |
| `_detect_streak_broken()` | `conditions: [{event: streak_broken}]` + LLM 评估 |
| `_check_has_data()` | `conditions: [{data_path: "...", operator: exists}]` |
| `_check_not_checked_in_today()` | `conditions: [{data_path: "...", operator: "!=", value: "{today}"}]` |
| `_check_has_pending_levers()` | `conditions: [{description: "有未完成杠杆"}]` + LLM 评估 |

### ContentGenerator（content_generator.py，1037 行）

| 方法 | 替代方案 |
|------|---------|
| `_generate_daily_fortune()` | `content.rule: rules/proactive/daily-fortune-push.md` + Agent |
| `_generate_dayun_transition()` | `content.rule: rules/proactive/dayun-push.md` + Agent |
| `_generate_fortune_alert()` | `content.rule: rules/proactive/fortune-alert-push.md` + Agent |
| `_generate_daily_horoscope()` | `content.rule: rules/proactive/daily-horoscope-push.md` + Agent |
| `_generate_transit_alert()` | `content.rule: rules/proactive/transit-alert-push.md` + Agent |
| `_generate_lunar_phase()` | `content.rule: rules/proactive/lunar-phase-push.md` + Agent |
| `_generate_solar_term()` | `content.rule: rules/proactive/solar-term-push.md` + Agent |
| `_generate_weekly_summary()` | `content.rule: rules/proactive/weekly-summary-push.md` + Agent |
| `_generate_birthday()` | `content.rule: rules/proactive/birthday-push.md` + Agent |
| `_generate_daily_checkin()` | `content.rule: rules/proactive/daily-checkin-push.md` + Agent |

---

## 配置规范 v3.0

### reminders.yaml 升级格式

```yaml
version: "3.0"  # 标识使用新架构
skill_id: bazi
enabled: true

reminders:
  - id: daily_fortune
    name: 每日运势

    # 触发配置
    trigger:
      type: time_based          # 时间触发保留 cron 匹配
      schedule: "0 8 * * *"
      cooldown_hours: 24

    # 条件配置（声明式，LLM 评估）
    conditions:
      - description: "用户已设定八字信息"
        data_path: "identity.birth_info"
        operator: "exists"
      - description: "今天还未收到运势推送"
        data_path: "notifications.bazi.daily_fortune.last_sent"
        operator: "!="
        value: "{today}"

    # 内容配置（Agent 驱动）
    content:
      rule: rules/proactive/daily-fortune-push.md  # Agent 使用此 Rule
      card_type: DailyFortuneCard
      suggested_prompt: "想了解今天的运势详情？"
      quick_actions:
        - label: "今日宜忌"
          prompt: "今天适合做什么？有什么需要注意的？"
        - label: "开运建议"
          prompt: "今天如何提升运势？"

    priority: medium

# 事件触发示例
  - id: birthday_reminder
    name: 生日提醒

    trigger:
      type: event_based
      event: birthday
      advance_days: [7, 0]      # 提前 7 天和当天

    conditions:
      - description: "用户生日信息存在"
        data_path: "identity.birth_info.date"
        operator: "exists"

    content:
      rule: rules/proactive/birthday-push.md
      card_type: BirthdayCard

# 数据条件触发示例
  - id: daily_checkin
    name: 每日签到提醒

    trigger:
      type: data_condition
      # 不再使用 type: has_data，改为声明式 conditions

    conditions:
      - description: "用户已设定愿景"
        data_path: "lifecoach.north_star.vision"
        operator: "exists"
      - description: "今天还未签到"
        data_path: "lifecoach.progress.last_checkin_date"
        operator: "!="
        value: "{today}"

    content:
      rule: rules/proactive/daily-checkin-push.md

global_config:
  default_push_hour: 8
  cooldown_hours: 24
  max_daily_pushes: 5
  quiet_hours:
    start: 22
    end: 7
```

### conditions 声明式语法

| 字段 | 类型 | 说明 |
|-----|------|------|
| `description` | string | 条件的自然语言描述（LLM 理解用） |
| `data_path` | string | Profile 数据路径（可选） |
| `operator` | string | 操作符：`exists`, `!exists`, `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains` |
| `value` | string/number | 比较值，支持 `{today}`, `{now}`, `{user_timezone}` 等变量 |

**复杂条件示例**：

```yaml
conditions:
  # 数据存在检查
  - description: "用户已设定八字信息"
    data_path: "identity.birth_info"
    operator: "exists"

  # 日期比较
  - description: "今天还未签到"
    data_path: "lifecoach.progress.last_checkin_date"
    operator: "!="
    value: "{today}"

  # 数值阈值
  - description: "运势分数低于 40"
    data_path: "skills.bazi.daily_fortune.score"
    operator: "<"
    value: 40

  # 复杂条件（纯 LLM 评估）
  - description: "用户连续 3 天情绪低落且未进行冥想"
    # 无 data_path，完全由 LLM 评估
```

---

## 核心组件设计

### 1. TriggerEvaluator（静态优先 + LLM 回退）

**文件**: `apps/api/services/proactive/trigger_evaluator.py`

**核心原则**：确定性条件由平台计算，复杂语义才回退 LLM。

```python
"""
TriggerEvaluator - 静态求值优先 + LLM 回退

设计原则:
1. 静态条件（exists/==/!=/>/< 等）由平台直接求值
2. 复杂条件（无 data_path、自然语言描述）才回退 LLM
3. cron 匹配 + 时区处理 + 幂等键

优势:
- 降低延迟与成本
- 降低 LLM 误判风险
- 保持配置驱动的灵活性
"""

from typing import Dict, Any, Tuple, Optional, List
from datetime import datetime, timezone
import croniter
import pytz


# 可静态求值的操作符
STATIC_OPERATORS = {"exists", "!exists", "==", "!=", ">", "<", ">=", "<=", "contains"}


class TriggerEvaluator:
    """静态优先 + LLM 回退的触发评估器"""

    def __init__(self, llm_service=None):
        self.llm_service = llm_service

    async def evaluate(
        self,
        trigger_config: Dict[str, Any],
        profile: Dict[str, Any],
        conditions: Optional[List[Dict]] = None,
        user_timezone: str = "Asia/Shanghai",
    ) -> Tuple[bool, Optional[Dict[str, Any]], Optional[str]]:
        """
        评估触发条件

        Returns:
            (triggered: bool, event_info: Optional[Dict], idempotent_key: Optional[str])
        """
        trigger_type = trigger_config.get("type")

        # 1. 时间触发：确定性 cron 匹配
        if trigger_type == "time_based":
            matched, bucket_key = self._evaluate_cron(
                trigger_config.get("schedule"),
                user_timezone
            )
            if not matched:
                return False, None, None
            # 继续评估 conditions
            if conditions:
                cond_result = await self._evaluate_conditions(conditions, profile)
                return cond_result, None, bucket_key
            return True, None, bucket_key

        # 2. 事件触发：确定性事件检测
        if trigger_type == "event_based":
            return await self._evaluate_event(trigger_config, profile, conditions)

        # 3. 数据条件触发
        if trigger_type == "data_condition":
            result = await self._evaluate_conditions(conditions, profile)
            return result, None, None

        return False, None, None

    def _evaluate_cron(
        self,
        schedule: str,
        user_timezone: str,
    ) -> Tuple[bool, Optional[str]]:
        """
        确定性 cron 匹配（带时区）

        Returns:
            (matched: bool, bucket_key: str) - bucket_key 用于幂等去重
        """
        if not schedule:
            return False, None

        try:
            tz = pytz.timezone(user_timezone)
            now = datetime.now(tz)

            cron = croniter.croniter(schedule, now)
            prev_time = cron.get_prev(datetime)

            # 计算时间桶（分钟级精度）
            bucket_key = prev_time.strftime("%Y-%m-%dT%H:%M")

            # 误差窗口与扫描频率对齐（假设每分钟扫描，误差 ≤60s）
            matched = (now - prev_time).total_seconds() < 60

            return matched, bucket_key
        except Exception:
            return False, None

    async def _evaluate_conditions(
        self,
        conditions: List[Dict],
        profile: Dict[str, Any],
    ) -> bool:
        """
        条件评估：静态优先，LLM 回退

        流程:
        1. 预处理占位符（{today}, {now}）
        2. 静态条件直接求值
        3. 复杂条件回退 LLM
        4. 所有条件 AND 逻辑
        """
        if not conditions:
            return True

        static_conditions = []
        complex_conditions = []

        # 分类条件
        for cond in conditions:
            cond = self._preprocess_condition(cond)  # 替换占位符
            if self._is_static_condition(cond):
                static_conditions.append(cond)
            else:
                complex_conditions.append(cond)

        # 1. 先求值静态条件（短路优化）
        for cond in static_conditions:
            if not self._static_eval(cond, profile):
                return False  # 短路：静态条件不满足，直接返回

        # 2. 静态条件全部通过，再求值复杂条件
        if complex_conditions and self.llm_service:
            return await self._llm_eval_conditions(complex_conditions, profile)

        return True

    def _is_static_condition(self, cond: Dict) -> bool:
        """判断是否为可静态求值的条件"""
        return (
            "data_path" in cond and
            cond.get("operator", "exists") in STATIC_OPERATORS
        )

    def _preprocess_condition(self, cond: Dict) -> Dict:
        """预处理占位符"""
        cond = cond.copy()
        if "value" in cond:
            value = str(cond["value"])
            if "{today}" in value:
                cond["value"] = value.replace("{today}", datetime.now().strftime("%Y-%m-%d"))
            if "{now}" in value:
                cond["value"] = value.replace("{now}", datetime.now().isoformat())
        return cond

    def _static_eval(self, cond: Dict, profile: Dict) -> bool:
        """静态条件求值"""
        data_path = cond.get("data_path", "")
        operator = cond.get("operator", "exists")
        expected = cond.get("value")

        # 获取数据
        actual = self._get_nested_value(profile, data_path)

        # 求值
        if operator == "exists":
            return actual is not None
        if operator == "!exists":
            return actual is None
        if operator == "==":
            return str(actual) == str(expected)
        if operator == "!=":
            return str(actual) != str(expected)
        if operator == ">":
            return float(actual or 0) > float(expected)
        if operator == "<":
            return float(actual or 0) < float(expected)
        if operator == ">=":
            return float(actual or 0) >= float(expected)
        if operator == "<=":
            return float(actual or 0) <= float(expected)
        if operator == "contains":
            return expected in str(actual or "")

        return False

    def _get_nested_value(self, data: Dict, path: str) -> Any:
        """获取嵌套路径的值"""
        keys = path.split(".")
        for key in keys:
            if isinstance(data, dict):
                data = data.get(key)
            else:
                return None
        return data

    async def _llm_eval_conditions(
        self,
        conditions: List[Dict],
        profile: Dict,
    ) -> bool:
        """LLM 评估复杂条件（仅用于无法静态求值的情况）"""
        # 简化 prompt，只发送相关数据
        prompt = f"""判断用户是否满足以下条件（全部满足返回 true）：

条件：
{chr(10).join(f"- {c.get('description', c)}" for c in conditions)}

用户相关数据：
{self._extract_relevant_data(profile, conditions)}

返回 JSON：{{"triggered": true/false, "reason": "..."}}"""

        result = await self.llm_service.evaluate(prompt=prompt)
        return result.get("triggered", False)

    async def _evaluate_event(
        self,
        trigger_config: Dict,
        profile: Dict,
        conditions: Optional[List[Dict]],
    ) -> Tuple[bool, Optional[Dict], Optional[str]]:
        """
        事件触发评估

        优先使用确定性计算（生日、节气等），
        仅对模糊场景回退 LLM。
        """
        event_type = trigger_config.get("event")
        advance_days = trigger_config.get("advance_days", [0])

        # 确定性事件检测
        if event_type == "birthday":
            return self._detect_birthday(profile, advance_days)
        if event_type == "solar_term":
            return self._detect_solar_term(advance_days)

        # 复杂事件回退 LLM
        if self.llm_service:
            return await self._llm_detect_event(event_type, profile, conditions)

        return False, None, None

    def _detect_birthday(
        self,
        profile: Dict,
        advance_days: List[int],
    ) -> Tuple[bool, Optional[Dict], Optional[str]]:
        """确定性生日检测"""
        birth_date_str = self._get_nested_value(profile, "vibe.profile.birth_info.date")
        if not birth_date_str:
            return False, None, None

        try:
            birth = datetime.strptime(birth_date_str, "%Y-%m-%d")
            today = datetime.now()
            this_year_birthday = birth.replace(year=today.year)

            days_until = (this_year_birthday - today).days

            if days_until in advance_days:
                return True, {
                    "event_type": "birthday",
                    "event_date": this_year_birthday.strftime("%Y-%m-%d"),
                    "days_until": days_until,
                }, f"birthday-{this_year_birthday.strftime('%Y-%m-%d')}"

        except Exception:
            pass

        return False, None, None
```

### 2. ProactiveOrchestrator

**文件**: `apps/api/services/proactive/orchestrator.py`

```python
"""
ProactiveOrchestrator - 主动推送编排器

职责:
1. 加载 Skill 级 reminders.yaml 配置
2. 调度触发评估（静态优先 + LLM 回退）
3. 调用 CoreAgent 生成内容
4. 投递通知

平台层硬约束:
- 静默时段检查
- 每日推送上限
- 幂等去重（基于 bucket_key）
- 冷却时间检查
"""

from typing import Dict, List, Optional, Any
from uuid import UUID
from datetime import datetime
import logging

from .trigger_evaluator import TriggerEvaluator
from .agent_adapter import ProactiveAgentAdapter
from .models import ReminderTask, ReminderContent
from services.notification import NotificationService


class ProactiveOrchestrator:
    """主动推送编排器"""

    def __init__(
        self,
        trigger_evaluator: TriggerEvaluator,
        agent_adapter: ProactiveAgentAdapter,
        notification_service: NotificationService,
    ):
        self.trigger_evaluator = trigger_evaluator
        self.agent_adapter = agent_adapter
        self.notification_service = notification_service
        self._skill_configs: Dict[str, Dict] = {}
        self._load_skill_configs()
        self._idempotent_cache: Dict[str, datetime] = {}  # 幂等缓存

    async def run_scheduled_scan(self, dry_run: bool = False) -> List[Dict]:
        """定时扫描入口"""
        results = []
        users = await self._get_users_for_current_hour()

        for user_id, profile in users:
            user_notifications = await self._process_user(user_id, profile, dry_run)
            results.extend(user_notifications)

        return results

    async def _process_user(
        self,
        user_id: UUID,
        profile: Dict,
        dry_run: bool = False,
    ) -> List[Dict]:
        """处理单个用户的所有推送"""
        notifications = []
        user_timezone = profile.get("vibe", {}).get("preferences", {}).get("timezone", "Asia/Shanghai")

        # 0. 静默时段检查（平台硬约束）
        if self._is_quiet_hours(user_timezone):
            logging.debug(f"User {user_id} in quiet hours, skipping")
            return []

        # 0.1 每日推送上限检查
        daily_count = await self._get_daily_push_count(user_id)
        max_daily = self._get_global_config().get("max_daily_pushes", 5)
        if daily_count >= max_daily:
            logging.debug(f"User {user_id} reached daily limit ({max_daily})")
            return []

        for skill_id, config in self._skill_configs.items():
            # 1. 订阅状态检查
            if not await self._should_send_to_user(user_id, skill_id):
                continue

            for reminder in config.get("reminders", []):
                # 2. 触发评估（静态优先 + LLM 回退）
                triggered, event_info, bucket_key = await self.trigger_evaluator.evaluate(
                    trigger_config=reminder.get("trigger", {}),
                    profile=profile,
                    conditions=reminder.get("conditions"),
                    user_timezone=user_timezone,
                )

                if not triggered:
                    continue

                # 3. 幂等检查（基于 bucket_key）
                idempotent_key = f"{user_id}-{skill_id}-{reminder['id']}-{bucket_key}"
                if self._is_duplicate(idempotent_key):
                    logging.debug(f"Duplicate: {idempotent_key}")
                    continue

                # 4. 冷却检查
                if not await self._check_cooldown(user_id, skill_id, reminder["id"]):
                    continue

                # 5. 生成内容（调用 Agent）
                content = await self.agent_adapter.generate_content(
                    user_id=str(user_id),
                    profile=profile,
                    skill_id=skill_id,
                    reminder=reminder,
                    event_info=event_info,
                )

                # 6. 保存通知
                if not dry_run:
                    await self.notification_service.save(
                        user_id=user_id,
                        notification_type=f"{skill_id}_{reminder['id']}",
                        title=content.title,
                        content=content.to_dict(),
                    )
                    self._mark_sent(idempotent_key)

                notifications.append({
                    "user_id": str(user_id),
                    "skill_id": skill_id,
                    "reminder_id": reminder["id"],
                    "title": content.title,
                    "triggered_reason": event_info,  # 记录触发原因
                })

        return notifications

    def _is_quiet_hours(self, user_timezone: str) -> bool:
        """静默时段检查"""
        import pytz
        tz = pytz.timezone(user_timezone)
        now = datetime.now(tz)
        hour = now.hour

        global_config = self._get_global_config()
        quiet_start = global_config.get("quiet_hours", {}).get("start", 22)
        quiet_end = global_config.get("quiet_hours", {}).get("end", 7)

        if quiet_start > quiet_end:  # 跨午夜
            return hour >= quiet_start or hour < quiet_end
        return quiet_start <= hour < quiet_end

    def _is_duplicate(self, idempotent_key: str) -> bool:
        """幂等检查"""
        if idempotent_key in self._idempotent_cache:
            return True
        return False

    def _mark_sent(self, idempotent_key: str):
        """标记已发送"""
        self._idempotent_cache[idempotent_key] = datetime.now()
```

### 3. ProactiveAgentAdapter

**文件**: `apps/api/services/proactive/agent_adapter.py`

```python
"""
ProactiveAgentAdapter - Agent 适配器

职责:
- 封装 Proactive 调用 CoreAgent 的逻辑
- 构建 Proactive 专用 Prompt
- 提取 Agent 输出的结构化内容
"""

from typing import Dict, Any, Optional
from dataclasses import dataclass
import json

from services.agent import create_agent, AgentContext
from .models import ReminderContent


@dataclass
class ProactivePromptConfig:
    """Proactive Prompt 配置"""
    skill_id: str
    reminder_id: str
    rule_path: str
    event_info: Optional[Dict] = None
    profile_summary: Optional[str] = None


class ProactiveAgentAdapter:
    """Agent 适配器"""

    async def generate_content(
        self,
        user_id: str,
        profile: Dict,
        skill_id: str,
        reminder: Dict,
        event_info: Optional[Dict] = None,
    ) -> ReminderContent:
        """
        调用 Agent 生成推送内容

        流程:
        1. 构建 Agent 上下文
        2. 构建 Proactive Prompt
        3. 运行 Agent（非流式）
        4. 提取结构化内容
        """
        # 1. 构建上下文
        context = AgentContext(
            user_id=user_id,
            profile=profile,
            skill=skill_id,
            scenario="proactive",
        )

        # 2. 构建 Prompt
        proactive_prompt = self._build_proactive_prompt(
            reminder=reminder,
            event_info=event_info,
            profile=profile,
        )

        # 3. 运行 Agent（非流式，直接获取结果）
        agent = create_agent(max_iterations=3)
        content_buffer = ""

        async for event in agent.run(proactive_prompt, context):
            if event.type == "content":
                content_buffer += event.data.get("content", "")

        # 4. 提取内容
        return self._extract_content(content_buffer, reminder)

    def _build_proactive_prompt(
        self,
        reminder: Dict,
        event_info: Optional[Dict],
        profile: Dict,
    ) -> str:
        """构建 Proactive Prompt"""
        rule_path = reminder.get("content", {}).get("rule", "")

        prompt_parts = [
            f"# 推送内容生成任务",
            f"",
            f"## 场景",
            f"- 推送类型: {reminder.get('name', reminder['id'])}",
            f"- 规则文件: {rule_path}",
        ]

        if event_info:
            prompt_parts.extend([
                f"",
                f"## 触发事件",
                f"```json",
                json.dumps(event_info, ensure_ascii=False, indent=2),
                f"```",
            ])

        prompt_parts.extend([
            f"",
            f"## 用户画像摘要",
            self._build_profile_summary(profile),
            f"",
            f"## 任务",
            f"1. 读取规则文件 `{rule_path}` 中的生成要求",
            f"2. 根据用户画像和触发事件生成个性化推送内容",
            f"3. 输出 JSON 格式：",
            f"```json",
            f'{{',
            f'  "title": "推送标题（≤20字）",',
            f'  "body": "推送正文（≤100字）",',
            f'  "fortune_hint": "可选，运势提示",',
            f'  "action_tip": "可选，行动建议"',
            f'}}',
            f"```",
        ])

        return "\n".join(prompt_parts)

    def _build_profile_summary(self, profile: Dict) -> str:
        """
        构建用户画像摘要

        统一使用 vibe.* 路径（与 VibeProfile v2.0 一致）
        """
        lines = []
        vibe = profile.get("vibe", {})

        # 身份信息 - vibe.profile.birth_info
        profile_data = vibe.get("profile", {})
        if birth := profile_data.get("birth_info"):
            lines.append(f"- 生日: {birth.get('date')}")

        # 状态 - vibe.state
        state = vibe.get("state", {})
        if focus := state.get("focus"):
            lines.append(f"- 关注领域: {', '.join(focus)}")
        if emotion := state.get("emotion"):
            lines.append(f"- 当前情绪: {emotion}")

        # 目标 - vibe.goals（统一路径）
        goals = vibe.get("goals", [])
        if goals:
            goal_names = [g.get("name", str(g)) for g in goals[:3]]
            lines.append(f"- 目标: {', '.join(goal_names)}")

        return "\n".join(lines) if lines else "（无画像信息）"

    def _extract_content(
        self,
        content_buffer: str,
        reminder: Dict,
    ) -> ReminderContent:
        """
        提取结构化内容

        使用严格校验 + 字段截断 + 兜底模板
        """
        from pydantic import BaseModel, Field, ValidationError

        # Pydantic 模型定义
        class ContentSchema(BaseModel):
            title: str = Field(max_length=20)
            body: str = Field(max_length=200)
            fortune_hint: Optional[str] = Field(None, max_length=50)
            action_tip: Optional[str] = Field(None, max_length=50)

        # 1. 尝试提取 JSON
        data = None
        try:
            import re
            json_match = re.search(r'```json\s*(.*?)\s*```', content_buffer, re.DOTALL)
            if json_match:
                data = json.loads(json_match.group(1))
            else:
                data = json.loads(content_buffer)
        except json.JSONDecodeError:
            logging.warning(f"Failed to parse JSON from content: {content_buffer[:100]}")

        # 2. Pydantic 校验 + 字段截断
        if data:
            try:
                validated = ContentSchema(**data)
                data = validated.model_dump()
            except ValidationError as e:
                logging.warning(f"Content validation failed: {e}")
                # 尝试截断后重试
                data = {
                    "title": str(data.get("title", ""))[:20],
                    "body": str(data.get("body", ""))[:200],
                    "fortune_hint": str(data.get("fortune_hint", ""))[:50] if data.get("fortune_hint") else None,
                    "action_tip": str(data.get("action_tip", ""))[:50] if data.get("action_tip") else None,
                }

        # 3. 兜底模板
        if not data or not data.get("title"):
            data = {
                "title": reminder.get("name", "推送通知"),
                "body": "点击查看详情",
            }
            logging.warning(f"Using fallback template for reminder: {reminder.get('id')}")

        # 附加对话引导
        content_config = reminder.get("content", {})

        return ReminderContent(
            title=data.get("title"),
            body=data.get("body", ""),
            fortune_hint=data.get("fortune_hint"),
            action_tip=data.get("action_tip"),
            card_type=content_config.get("card_type"),
            suggested_prompt=content_config.get("suggested_prompt"),
            quick_actions=content_config.get("quick_actions", []),
        )
```

---

## Proactive Rule 模板

### 模板文件

**文件**: `skills/core/rules/proactive/_template.md`

```markdown
---
id: proactive-{reminder_id}
name: {reminder_name} 推送内容生成
type: proactive
version: 1.0.0
---

# {reminder_name} 推送内容生成

## 场景说明
{场景描述}

## 触发事件
- 事件类型: {event_type}
- 触发条件: {conditions_description}

## 用户画像读取
从 profile 中读取以下信息：
- `identity.birth_info` - 出生信息
- `state.focus` - 关注领域
- `state.emotion` - 当前情绪
- `skills.{skill_id}.*` - Skill 相关数据

## 生成要求

### 标题
- 字数: ≤20 字
- 风格: {风格描述}
- 包含: {必须包含的元素}

### 正文
- 字数: ≤100 字
- 风格: 温暖、个性化
- 结构: {结构要求}

### 可选字段
- `fortune_hint`: 运势提示（如适用）
- `action_tip`: 行动建议

## 语气风格
根据用户 `preferences.voice_mode` 调整：
- `warm`: 温暖关怀型
- `sarcastic`: 毒舌激励型
- `wise`: 智慧洞察型

## 输出格式
```json
{
  "title": "推送标题",
  "body": "推送正文，个性化内容...",
  "fortune_hint": "可选，运势提示",
  "action_tip": "可选，行动建议"
}
```

## 示例

### 示例 1: 标准场景
输入:
- 用户关注: 事业
- 当前情绪: 平静
- 触发事件: {example_event}

输出:
```json
{
  "title": "{example_title}",
  "body": "{example_body}",
  "action_tip": "{example_action_tip}"
}
```
```

### Bazi 每日运势 Rule

**文件**: `skills/bazi/rules/proactive/daily-fortune-push.md`

```markdown
---
id: proactive-daily-fortune
name: 每日运势推送内容生成
type: proactive
skill_id: bazi
---

# 每日运势推送内容生成

## 场景说明
每日早晨为用户推送个性化运势提醒，帮助用户了解当日运势趋势并提供行动建议。

## 数据读取
从 profile 中读取：
- `identity.birth_info` - 八字信息
- `skills.bazi.daily_fortune` - 今日运势数据（如已计算）
- `state.focus` - 关注领域
- `preferences.voice_mode` - 语气偏好

## 生成要求

### 标题
- 字数: ≤15 字
- 包含: 日期感、运势关键词
- 示例: "今日运势 · 事业有突破"

### 正文
- 字数: 60-100 字
- 结构:
  1. 今日运势概述（1句）
  2. 重点关注事项（1句）
  3. 行动建议（1句）
- 风格: 根据 voice_mode 调整

### fortune_hint
- 今日宜/忌（简短）

### action_tip
- 具体可执行的建议

## 语气风格示例

### warm（温暖型）
"今天土气旺盛，适合稳扎稳打。事业上可能遇到贵人相助，记得保持谦逊哦～"

### sarcastic（毒舌型）
"今天运势不错，别浪费了。有贵人送机会上门，这次可别又错过了。"

### wise（智慧型）
"戊土当令，厚德载物。今日宜守不宜攻，静待时机方为上策。"

## 输出格式
```json
{
  "title": "今日运势 · {关键词}",
  "body": "{个性化正文}",
  "fortune_hint": "宜: {宜事} | 忌: {忌事}",
  "action_tip": "{具体建议}"
}
```
```

### Lifecoach 每日签到 Rule

**文件**: `skills/lifecoach/rules/proactive/daily-checkin-push.md`

```markdown
---
id: proactive-daily-checkin
name: 每日签到推送内容生成
type: proactive
skill_id: lifecoach
---

# 每日签到推送内容生成

## 场景说明
每日提醒用户进行签到，以 Future Self 人格进行温暖的问候。

## 数据读取
从 profile 中读取：
- `lifecoach.north_star.vision` - 用户愿景
- `lifecoach.progress.streak_days` - 连续签到天数
- `lifecoach.progress.last_checkin_date` - 上次签到日期
- `state.emotion` - 当前情绪

## 场景判断

### 场景 1: 正常签到（昨天有签到）
- 风格: 日常问候
- 提及: 连续签到天数

### 场景 2: 久别重逢（3-7 天未签到）
- 风格: 温暖欢迎
- 提及: 没关系，重新开始

### 场景 3: 长时间未互动（>7 天）
- 风格: 关心询问
- 不提及: 断签

### 场景 4: 连续签到里程碑（7天/30天/100天）
- 风格: 庆祝
- 提及: 具体成就

## 生成要求

### 标题
- 字数: ≤12 字
- 示例: "早上好！"、"想你了～"、"恭喜连续 7 天！"

### 正文
- 字数: 40-80 字
- 以 Future Self 口吻
- 引导用户签到

## 输出格式
```json
{
  "title": "{场景化标题}",
  "body": "{Future Self 口吻的问候}",
  "action_tip": "点击开始今天的签到"
}
```

## 示例

### 正常签到
```json
{
  "title": "早上好！",
  "body": "连续签到第 15 天了，稳步前进中！今天想和我聊聊最近的进展吗？",
  "action_tip": "开始今日签到"
}
```

### 久别重逢
```json
{
  "title": "好久不见～",
  "body": "几天没见你了，一切都好吗？没关系，每一天都是新的开始。准备好继续了吗？",
  "action_tip": "重新开始"
}
```
```

---

## 文件变更清单

### 新增文件（11个）

| 文件 | 描述 |
|------|------|
| `services/proactive/trigger_evaluator.py` | LLM 触发评估器 |
| `services/proactive/orchestrator.py` | 主动推送编排器 |
| `services/proactive/agent_adapter.py` | Agent 适配器 |
| `services/proactive/models.py` | 数据模型（提取自 engine.py） |
| `skills/core/rules/proactive/_template.md` | Proactive Rule 模板 |
| `skills/bazi/rules/proactive/daily-fortune-push.md` | Bazi 每日运势 Rule |
| `skills/bazi/rules/proactive/birthday-push.md` | Bazi 生日 Rule |
| `skills/lifecoach/rules/proactive/daily-checkin-push.md` | Lifecoach 签到 Rule |
| `skills/zodiac/rules/proactive/daily-horoscope-push.md` | Zodiac 每日星座 Rule |
| `tests/services/proactive/test_trigger_evaluator.py` | 评估器单元测试 |
| `tests/services/proactive/test_orchestrator.py` | 编排器集成测试 |

### 修改文件（5个）

| 文件 | 变更 |
|------|------|
| `workers/proactive_worker.py` | 使用 ProactiveOrchestrator |
| `skills/bazi/reminders.yaml` | 升级到 v3.0 格式 |
| `skills/lifecoach/reminders.yaml` | 升级到 v3.0 格式 |
| `skills/zodiac/reminders.yaml` | 升级到 v3.0 格式 |
| `services/proactive/__init__.py` | 更新导出 |

### 删除文件（2个）

| 文件 | 行数 | 原因 |
|------|------|------|
| `services/proactive/trigger_detector.py` | 643 | 所有检测逻辑 LLM 化 |
| `services/proactive/content_generator.py` | 1037 | 所有生成逻辑 Agent 化 |

---

## 迁移指南

### 1. v2.0 → v3.0 配置迁移

```yaml
# v2.0 (旧)
reminders:
  - id: daily_fortune
    trigger:
      type: time_based
      schedule: "0 8 * * *"
    conditions:
      - type: has_data
        path: "identity.birth_info"
    content:
      generator: rules/daily-fortune.md

# v3.0 (新)
version: "3.0"
reminders:
  - id: daily_fortune
    trigger:
      type: time_based
      schedule: "0 8 * * *"
    conditions:
      - description: "用户已设定八字信息"
        data_path: "identity.birth_info"
        operator: "exists"
    content:
      rule: rules/proactive/daily-fortune-push.md  # 独立的 proactive rule
```

### 2. conditions 迁移对照表

| v2.0 type | v3.0 声明式 |
|-----------|------------|
| `has_data` | `{data_path: "...", operator: "exists"}` |
| `not_checked_in_today` | `{data_path: "...last_checkin_date", operator: "!=", value: "{today}"}` |
| `has_pending_levers` | `{description: "有未完成杠杆"}` |
| 自定义 type | `{description: "..."}` + LLM 评估 |

### 3. generator → rule 迁移

旧的 `content.generator` 指向的 Rule 文件需要重构为 Proactive 专用 Rule：

```
rules/daily-fortune.md (通用 Skill Rule)
    ↓ 提取推送相关部分
rules/proactive/daily-fortune-push.md (Proactive 专用 Rule)
```

---

## 验证方案

### 单元测试

```bash
# 触发评估器测试
pytest tests/services/proactive/test_trigger_evaluator.py -v

# 编排器测试
pytest tests/services/proactive/test_orchestrator.py -v
```

### E2E 验证用例

| 场景 | 预期结果 |
|------|---------|
| Bazi 每日运势 | cron 匹配 → conditions 通过 → Agent 生成 → 通知保存 |
| Lifecoach 签到 | data_condition → LLM 评估 conditions → Agent 生成 → 通知保存 |
| Bazi 生日提醒 | event_based → LLM 检测生日 → Agent 生成 → 通知保存 |
| 新增触发类型 | 只改 YAML + Rule 文件，零代码改动 ✅ |

### 性能验收

| 指标 | 目标 |
|------|------|
| 推送延迟增加 | ≤2 秒 |
| LLM 调用模型 | Haiku（成本优化） |
| 批量处理 | 支持 |

---

## 风险与缓解

| 风险 | 描述 | 缓解措施 |
|------|------|---------|
| LLM 误判触发 | LLM 可能错误评估 conditions | 1. time_based 保留 cron 匹配<br>2. 关键条件添加 fallback |
| Agent 内容质量 | 生成内容不符合预期 | 1. Rule 文件提供详细示例<br>2. JSON Schema 校验 |
| 性能影响 | LLM 调用增加延迟 | 1. 批量处理<br>2. 使用 Haiku |
| 向后兼容 | v2.0 配置无法直接使用 | 1. 支持 version 自动检测<br>2. 渐进迁移 |

---

## 成功标准

- [ ] 新增触发条件只需修改 YAML，零代码改动
- [ ] 新增推送内容只需添加 Rule 文件，零代码改动
- [ ] 删除 trigger_detector.py（643 行）
- [ ] 删除 content_generator.py（1037 行）
- [ ] 所有现有 reminders.yaml 迁移到 v3.0 格式
- [ ] 测试覆盖率 80%+
- [ ] 推送延迟增加 ≤2 秒

---

## 时间线

| 周 | 阶段 | 任务 |
|----|------|------|
| 1 | 基础架构 | TriggerEvaluator + ProactiveOrchestrator + AgentAdapter |
| 2 | Rules 迁移 | Proactive Rule 文件 + reminders.yaml v3.0 |
| 3 | 清理测试 | 删除硬编码 + 单元测试 + E2E 测试 |

---

## 相关文档

- [SPEC.md](./ref/SPEC.md) - v2.0 规范（当前）
- [LLM-FIRST-DESIGN.md](/docs/archive/v9/LLM-FIRST-DESIGN.md) - LLM-First 架构设计
- [ARCHITECTURE.md](/docs/archive/v8/ARCHITECTURE.md) - 系统架构
