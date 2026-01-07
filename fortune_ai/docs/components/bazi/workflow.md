# Bazi/Main 前端到后端执行全链路（E2E）

本文档梳理从前端页面（`/bazi` 与 `/main`）点击按钮发送消息，到后端创建任务、Worker 执行、前端轮询渲染的完整流程。包含关键接口、数据形态与代码锚点，并在需要处配以 ASCII 时序图。

## 快速总览

ASCII 总览（报告生成主链路，包含标准模型与深研模型）：

```
User
  |
  | 1) 点击“生成八字报告”
  v
Browser (/bazi or /main)
  | 2) POST /api/calculate  (standard)
  |    或 POST /api/v2/submit (deep_research/standard)
  v
API (FastAPI)
  | 3) services.task_service.submit_bazi_task_v2(...)
  v
Task Service
  | 3.1 calculate_bazi()
  | 3.2 _build_*_prompt()  ← 使用默认或用户自定义 system_prompt
  | 3.3 create_gemini_job() → 插入 gemini_job/task
  v
Gemini DB (jobs/tasks)
  ^                         \
  | 5) Worker 轮询与执行     \ 4) 返回 {job_id, user_id, bazi}
  |                          \
Worker (a2ui_worker)          \--> Browser 开始轮询
  | 6) 写回 output/status
  v
API
  | 7) GET /api/report/{job_id} 或 /api/v2/report/{job_id}
  v
Browser
  | 8) 渲染报告/阅读模式
  v
User
```

辅助链路：

```
姓名自动回填：
Browser --(name change)--> GET /api/user/by-name --> 返回 birth_fields → 填入表单

System Prompt 预设/历史：
Browser --(onload)--> GET /api/system-prompts  → 预设/历史下拉
Browser --(submit有文本)--> POST /api/system-prompts → 写入本地历史
```

## 1. /bazi 页面：生成八字报告

- 表单提交（区分模型）：
  - standard：POST `/api/calculate`
  - 非 standard（如 deep_research）：POST `/api/v2/submit`

时序图（/bazi → standard）：

```
User -> Browser(/bazi): 点击 “生成八字报告”
Browser -> API: POST /api/calculate {name,gender,year,...,system_prompt?}
API -> TaskService: submit_bazi_task_v2(..., model=standard)
TaskService -> BaziEngine: calculate_bazi(...)
TaskService -> TaskService: _build_standard_prompt(bazi, system_prompt)
TaskService -> GeminiRepo: create_gemini_job(title, tasks)
API --> Browser: {job_id, user_id, bazi, used_default_location}
loop 轮询
  Browser -> API: GET /api/report/{job_id}
  API -> GeminiRepo: get_tasks_by_job_id(job_id)
  API --> Browser: {processing|completed, content/doc_url}
end
Browser -> User: 渲染报告内容
```

时序图（/bazi → deep_research，经 v2）：

```
User -> Browser(/bazi): 点击 “生成八字报告”（模型: deep_research）
Browser -> API: POST /api/v2/submit {openid,src,model,system_prompt?,birth_data}
API -> TaskService: submit_bazi_task_v2(..., model=deep_research)
TaskService -> BaziEngine: calculate_bazi(...)
TaskService -> TaskService: _build_deep_research_prompt(bazi, system_prompt)
TaskService -> GeminiRepo: create_gemini_job(...)
API --> Browser: {job_id, user_id, bazi}
loop 轮询
  Browser -> API: GET /api/v2/report/{job_id}
  API -> GeminiRepo: get_tasks_by_job_id(job_id)
  API --> Browser: {processing|completed, a2ui_data|fallback_md}
end
Browser -> User: 阅读模式/卡片渲染
```

示例请求（standard，经 `/api/calculate`）：

```json
{
  "name": "张三",
  "gender": "男",
  "year": 1990,
  "month": 1,
  "day": 2,
  "hour": 3,
  "minute": 4,
  "location_name": "北京",
  "longitude": 116.4,
  "latitude": 39.9,
  "system_prompt": ""   // 留空则使用后端默认 system prompt
}
```

关键前端代码：
- `api/static/main.js:135` 提交表单；`171` 选择 `/api/v2/submit` 或 `/api/calculate`；`116` 轮询 `/api/report/{job_id}`。
- `api/static/main.js:21` 初始化默认 System Prompt（仅在输入框为空时预填）。
- `api/static/main.js:480` 姓名变更自动回填出生信息。

关键后端代码：
- `api/main.py:771` POST `/api/calculate`（标准模型提交流）
- `api/main.py:814` GET `/api/report/{job_id}`（标准轮询接口）
- `api/main.py:1015` POST `/api/v2/submit`（v2 统一提交流）
- `api/main.py:1073` GET `/api/v2/report/{job_id}`（v2 轮询，优先解析 A2UI）
- `services/task_service.py:55` `_build_standard_prompt()` 使用默认/自定义 system prompt 拼接八字信息
- `services/task_service.py:78` `_build_deep_research_prompt()`
- `services/task_service.py:318` `submit_bazi_task_v2()` 计算八字、构建 prompt、创建 Gemini 任务

默认 System Prompt（后端）：
- `services/task_service.py:21` 常量 `DEFAULT_SYSTEM_PROMPT`
  - 你是一个八字大师，基于以下信息和你的命理知识（滴天髓，《穷通宝鉴》、《三命通会》、《金不换》等经典）深度解盘，并将解盘结果以现代人熟悉的方式返回，语气建设性。

## 2. /main 页面：工作台生成报告 + 对话

### 2.1 生成八字报告（工作台右侧）

```
User -> Browser(/main): 提交右侧 report-form
Browser -> API: POST /api/v2/submit {openid,src,model,system_prompt?,birth_data}
...（与 §1 v2 流程相同）...
Browser -> Thread: 在左侧对话流显示进度与“阅读模式”按钮
```

关键前端代码：
- `api/static/ui.js:181` 监听 `#report-form` 提交，POST `/api/v2/submit`，随后轮询 `/api/v2/report/{job_id}` 并在对话流中展示摘要与“阅读模式”。

### 2.2 主输入框“提问”（对话 → 统一走 Gemini 任务）

```
User -> Browser(/main): 在底部输入框提交
Browser -> API: POST /api/chat/ask {name?,session_id?,system_prompt?,messages[],model}
API -> GeminiRepo: create_gemini_job(... task_name=chat ...)
API --> Browser: {status:processing, job_id, audit_id}
loop 轮询
  Browser -> API: GET /api/v2/report/{job_id}
  API --> Browser: {processing|completed, a2ui_data|md}
end
Browser -> User: 渲染对话回复
```

请求体（简化）：

```json
{
  "name": "张三",
  "session_id": "optional",
  "system_prompt": "可选",
  "messages": [
    {"role": "user", "text": "近两年事业如何？"}
  ],
  "model": "standard"
}
```

关键前后端代码：
- `api/static/ui.js:119` 监听 `#ask-form` → POST `/api/chat/ask`，随后轮询 `/api/v2/report/{job_id}`。
- `api/main.py:530` POST `/api/chat/ask` 将对话拼装为 prompt 创建 Gemini 任务。

（注）项目同时保留了 `/api/bazi/ask` 与 `/api/bazi/ask/stream` 的按八字“提问”接口，用于流式或同步回答，但 `/main` 默认主输入框走 `/api/chat/ask` 统一任务流。

## 3. 辅助能力与数据

### 3.1 姓名自动回填

```
Browser(/bazi) --(name change)--> GET /api/user/by-name?name=...  → {found, user, birth_fields}
Browser: 将 birth_fields.date/time/location/经纬度写回表单；gender 规范化为“男/女”
```

- 前端：`api/static/main.js:480`（监听并回填）
- 后端：`api/main.py:467` GET `/api/user/by-name`

### 3.2 System Prompt 预设与历史

- 前端加载：`api/static/main.js:87` GET `/api/system-prompts?openid=web`
- 前端写入：`api/static/main.js:102` POST `/api/system-prompts`
- 后端：`api/main.py:690` GET，`api/main.py:704` POST
- 预设来源：`services/prompt_store.py:61` `get_presets()`

## 4. Worker 执行与状态机（简述）

```
create_gemini_job → gemini_job/task 入库
Worker(a2ui_worker) 周期性拉取任务（过滤关键词/只读策略）
→ 调用 LLM / 引擎 → 写回 task.output_text / status
→ API 轮询接口从 DB 读取并返回给前端
```

- 启停脚本：`scripts/deploy_nohup.sh`（同时拉起 API 与 Worker）。
- DB 适配：`integrations/gemini_repo.py` 根据环境优先级加载外部/内置 db_manager，并暴露 `create_gemini_job/get_tasks_by_job_id` 等。

## 5. 本地/联调 快速验证

```bash
# 1) 重启服务（同时跑 API 与 Worker）
bash scripts/deploy_nohup.sh

# 2) /bazi 标准流
curl -sS -X POST http://127.0.0.1:8230/api/calculate \
  -H 'Content-Type: application/json' \
  -d '{"name":"测试","gender":"男","year":1990,"month":1,"day":2,"hour":3,"minute":4,"location_name":"北京"}'

# 3) v2 流（deep_research）
curl -sS -X POST http://127.0.0.1:8230/api/v2/submit \
  -H 'Content-Type: application/json' \
  -d '{"openid":"web","src":"web","model":"deep_research","birth_data":{"name":"测试","gender":"女","year":1995,"month":5,"day":6,"hour":7,"minute":8,"location_name":"上海"}}'

# 4) 轮询
curl -sS http://127.0.0.1:8230/api/report/<job_id>
curl -sS http://127.0.0.1:8230/api/v2/report/<job_id>

# 5) /main 提问（chat）
curl -sS -X POST http://127.0.0.1:8230/api/chat/ask \
  -H 'Content-Type: application/json' \
  -d '{"name":"测试","messages":[{"role":"user","text":"今年事业如何提升？"}],"model":"standard"}'
```

## 6. 备注

- 默认 System Prompt 已在前后端统一：
  - 后端缺省：`services/task_service.py:21` `DEFAULT_SYSTEM_PROMPT`
  - /bazi 页面预填：`api/static/main.js:21`
- 若请求体携带非空 `system_prompt`，后端按“完全透传 + 八字数据块”拼接，不追加默认模板。
- `/main` 的主输入框走 `/api/chat/ask`，与 `/api/bazi/ask` 并存；如需切换为八字问答风格，可参考 `api/main.py:590` 的 SSE 流实现（占位/示例）。

—

更新：2025-12-23

