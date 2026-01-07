这是一个完整的系统定义与设计文档。该文档基于现有的数据库架构，在不修改任何表结构的前提下，通过**应用层协议封装**实现了微信端 A2UI（Agent to User Interface）交互模式。

---

#AI 八字 Deep Research 系统 (v2.0) - 设计文档##1. 系统概述本系统是一个基于生成式 AI 的深度命理分析平台。它结合了传统算法（真太阳时排盘）与 Deep Research（深度推理模型），通过微信/企业微信生态，为用户提供“即时交互、深度分析、可视化展示”的算命服务。

**核心差异化特性（A2UI）：**
系统不再仅返回文本，而是根据 AI 的分析结果，动态生成可视化 UI 组件（如五行能量图、运势时间轴），实现“Agent 生成界面”。

---

##2. 系统架构设计###2.1 逻辑架构图系统分为三层：**交互层（WeChat A2UI）**、**业务逻辑层（Gateway & Engine）**、**数据与计算层（DB & Worker）**。

###2.2 核心模块说明1. **交互层 (WeChat Frontend)**
* **WeChat Bot**：基于 `WeRoBot` 或企微 API，负责意图识别。当用户触发“算命”时，下发 A2UI 输入组件（H5 卡片）。
* **H5/小程序**：负责精确采集时间（真太阳时参数）、轮询任务状态、解析 JSON 并渲染动态 UI（ECharts 图表、卡片）。


2. **业务逻辑层 (API Gateway)**
* **Bazi Engine**：引入 `lunar-python` 库，负责将用户输入的出生地经纬度与公历时间转换为精确的“真太阳时八字”。
* **Protocol Packer**：**关键模块**。负责将用户元数据（OpenID）打包进数据库的 `title` 字段，并将 AI 的输出解析为前端可读的 JSON。


3. **数据与计算层 (Existing Infrastructure)**
* **DB Manager**：复用现有的 `db_manager.py`，不修改任何代码。
* **Deep Research Worker**：后台进程，监听数据库，执行长文本推理，强制输出 JSON 格式。



---

##3. 数据层协议设计 (零 Schema 变更方案)为了遵守“不修改 `db_manager.py` 和数据库表结构”的约束，我们采用**数据字段复用协议**。

###3.1 `gemini_job` 表复用策略利用 `title` 字段存储“元数据 + 标题”。

* **原定义**：`title` (VARCHAR/TEXT)
* **新协议格式**：`{{JSON_METADATA}}|||{{READABLE_TITLE}}`
* **示例**：
```text
{"uid":"wx_oX9s8d","src":"wechat","ver":"2.0"}|||张三的八字深度报告

```


* **读写方式（合规）**：仅调用 `create_gemini_job(title, tasks)` 创建任务；读取时在应用层按 `|||` 分割字符串。

###3.2 `gemini_task` 表复用策略（只读约束）

* **原定义**：`output_text` (TEXT)
* **新协议格式**：纯 JSON 字符串（严禁 Markdown 代码块包裹）。
* **内容定义**：包含前端渲染所需的组件类型（Component Type）和数据（Data）。
* **合规说明**：作为 gemini 的 user，仅允许“创建 Job（create_gemini_job，参数为 title 与 tasks）与只读轮询结果”。本项目默认严格只读：当 `GEMINI_DB_READONLY=1`（默认值）时，任何 `update_*` 写入接口都会被 integrations/gemini_repo 显式拒绝（抛出 PermissionError），Worker 也不会执行写回操作。

---

##4. A2UI 交互协议定义这是前端与 Deep Research 模型对齐的关键接口文档。

###4.1 输入 A2UI (Input Component)用户在微信点击卡片后，H5 前端收集的数据结构（用于计算真太阳时）：

```json
{
  "user_input": {
    "name": "张三",
    "gender": "male",
    "birth_date": "1995-08-15",
    "birth_time": "14:30",
    "birth_city": "Beijing",
    "longitude": 116.4074 // 用于真太阳时计算
  }
}

```

###4.2 输出 A2UI (Output Component Schema)Deep Research 模型必须输出符合此 Schema 的 JSON。

```json
{
  "meta": {
    "score": 88,
    "summary": "大器晚成，中年发迹之造。"
  },
  "ui_components": [
    {
      "type": "wuxing_chart",
      "title": "五行能量分布",
      "data": [
        {"name": "金", "value": 15, "color": "#FFD700"},
        {"name": "木", "value": 45, "color": "#228B22"},
        {"name": "水", "value": 20, "color": "#1E90FF"},
        {"name": "火", "value": 10, "color": "#FF4500"},
        {"name": "土", "value": 10, "color": "#8B4513"}
      ]
    },
    {
      "type": "timeline_card",
      "title": "未来五年流年大运",
      "data": [
        {"year": 2025, "event": "乙巳年", "desc": "伤官见官，注意口舌纠纷...", "sentiment": "negative"},
        {"year": 2026, "event": "丙午年", "desc": "财星高照，利于投资...", "sentiment": "positive"}
      ]
    },
    {
      "type": "markdown_text",
      "title": "深度性格剖析",
      "data": "## 内在潜意识\n日主甲木生于寅月，得令而旺..."
    }
  ]
}

```

###4.3 Prompt 规范（原典限定 Standard）

后台创建 `model=standard` 的任务时，必须使用“原典限定”提示词：

- 角色：你是中国传统命理大师。
- 仅可引用原典：《滴天髓》《三命通会》《穷通宝鉴》。不得参考或臆造其他文献。
- 输出：结构化 Markdown，建议包含：总论、用神与格局（注明引用书名）、性情与才能、事业/财运/健康建议、不确定性与分歧。
- 输入：八字四柱文本与经纬度（地点名称可选）。

Worker 收到 `standard` 模型任务后，需将模型返回的 Markdown 转换为 A2UI JSON（`markdown_text` 组件），写入 `gemini_task.output_text` 并置 `status=10`。

---

##5. 详细业务流程实现###步骤 1：用户触发与输入 (Input Phase)1. 用户在微信发送：“帮我算算”。
2. 后端识别意图，返回 H5 卡片链接：`https://app.com/bazi/input?openid=USER_123`。
3. 用户在 H5 填写生日与出生地。
4. **计算真太阳时**（后端 Bazi Engine）：
* 输入：公历 1990-01-01 12:00, 经度 87.6 (乌鲁木齐)。
* 计算：平太阳时 12:00 -> 地方真太阳时 约 09:50 -> 转换为八字排盘。



###步骤 2：任务创建与数据库写入 (Injection Phase)1. 后端将排盘结果（四柱：庚午年...）组装成 Prompt。
2. **Prompt 注入要求**：
* System Prompt: "你是一个算命专家，请严格按照以下 JSON Schema 输出..."。
* User Prompt: "八字为：[排盘数据]。请分析。"


3. **调用 `create_gemini_job`**：
```python
# 伪代码（仅调用 create_gemini_job，禁止直接 insert）
meta = json.dumps({"openid": "USER_123"})
title = f"{meta}|||张三的八字报告"
tasks = [{"model": "deep_research", "task_name": "analysis", "prompt": prompt_content, ...}]
create_gemini_job(title, tasks)

```



###步骤 3：Deep Research 执行 (Execution Phase)
1. 后台 Worker 轮询 `status=0` 的任务（只读）。
2. 若在合规授权下（`GEMINI_DB_READONLY=0`），LLM 推理完成后会写回 `output_text` 并更新状态；默认只读模式下，不会有任何写入动作。

###步骤 4：结果渲染 (Rendering Phase)1. H5 前端轮询接口 `/api/report/{job_id}`。
2. 接口读取 `gemini_task.output_text`（只读）。
3. 接口尝试 `json.loads()` 解析数据。
4. H5 前端根据 `ui_components` 数组：
* 遇到 `wuxing_chart` -> 调用 ECharts 渲染饼图。
* 遇到 `timeline_card` -> 渲染垂直时间轴。
* 遇到 `markdown_text` -> 渲染富文本。



---

##6. 接口 API 定义 (FastAPI)###6.1 提交任务`POST /api/v2/submit`

* **Request**:
```json
{ "openid": "wx_123", "birth_data": { ... } }

```


* **Process**:
1. 计算真太阳时。
2. 构造 Prompt。
3. `create_gemini_job(packed_title, tasks)`。


* **Response**: `{ "job_id": 55, "eta_seconds": 120 }`

###6.2 查询结果`GET /api/v2/report/{job_id}`

* **Process**:
1. `get_gemini_job_by_id(job_id)`。
2. 校验 `packed_title` 中的 openid 是否匹配当前用户。
3. `get_tasks_by_job_id(job_id)`。
4. 若 `status=10`，解析 `output_text` 为 JSON。


* **Response**:
```json
{
    "status": "completed",
    "a2ui_data": { ...JSON_OBJECT... } // 前端直接用这个渲染
}

```



---
