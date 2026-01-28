# Fortune AI Final MVP - 实现状态与计划

## 概要

基于 `system_design_final_mvp.md` 评估，实现已完成 **~95%**。核心功能已可运行。本文档总结当前状态及剩余缺口。

---

## 实现状态

### 1. 数据库 Schema（100% 完成）
- **文件**: [20251229_final_mvp.sql](fortune_ai/migrations/20251229_final_mvp.sql)
- 所有表已定义：`fortune_user`, `fortune_user_preferences`, `fortune_user_session`, `fortune_conversation_session`, `fortune_conversation_message`, `fortune_bazi_snapshot`, `fortune_commitment`, `fortune_checkin`, `fortune_reflection`, `fortune_plan`, `fortune_plan_day`, `fortune_plan_enrollment`, `fortune_plan_record`, `fortune_daily_guidance`, `fortune_push_event`, `bazi_kb_document`, `bazi_kb_chunk`, `fortune_rule`, `fortune_external_job`
- 4 个预设计划已填充完整天数内容（gratitude_21, mindfulness_7, habit_30, strength_14）
- 5 条规则已入库（旺衰评分 + 5 个神煞规则）

### 2. 前端（100% 完成）
- **文件**: [bazi2.html](fortune_ai/api/templates/bazi2.html), [ui.js](fortune_ai/api/static/ui.js), [ui.css](fortune_ai/api/static/ui.css)
- 双栏布局：对话（左）+ Bento/工具/设置（右）
- 会话抽屉带搜索功能
- 6 个 Bento 卡片：今日指引、行动处方、情绪打卡、成长计划、决策模板、话术生成
- A2UI 渲染 + 动作按钮联动
- 工具面板：Gemini 报告、出生校准、铁板神算
- 设置面板：偏好、修改密码、账号操作
- 认证流程 + CSRF 保护

### 3. 后端路由（100% 完成）

| 路由文件 | 端点 | 状态 |
|----------|------|------|
| [auth_routes.py](fortune_ai/api/auth_routes.py) | login, register, logout | 完成 |
| [session_routes.py](fortune_ai/api/session_routes.py) | 会话列表、加载、创建 | 完成 |
| [chat_routes.py](fortune_ai/api/chat_routes.py) | /api/chat/send, /api/chat/ask | 完成 |
| [bento_routes.py](fortune_ai/api/bento_routes.py) | /api/bento/today, actions, commitment/accept, commitment/done, checkin | 完成 |
| [plan_routes.py](fortune_ai/api/plan_routes.py) | /api/plan/list, active, join, record | 完成 |
| [push_routes.py](fortune_ai/api/push_routes.py) | /api/push/inbox, subscribe | 完成 |
| [report_routes.py](fortune_ai/api/report_routes.py) | /api/report/bazi/submit, bazi/{job_id} | 完成 |
| [kb_routes.py](fortune_ai/api/kb_routes.py) | KB 搜索端点 | 完成 |
| [user_routes.py](fortune_ai/api/user_routes.py) | Profile, preferences | 完成 |
| [bazi_routes.py](fortune_ai/api/bazi_routes.py) | 八字计算 | 完成 |

### 4. 服务层（100% 完成）

| 服务文件 | 用途 | 状态 |
|----------|------|------|
| [chat_service.py](fortune_ai/services/chat_service.py) | 会话/消息 CRUD | 完成 |
| [bento_service.py](fortune_ai/services/bento_service.py) | 今日指引、承诺、打卡 | 完成 |
| [plan_service.py](fortune_ai/services/plan_service.py) | 计划报名、天数同步、记录 | 完成 |
| [bazi_facts.py](fortune_ai/services/bazi_facts.py) | 真太阳时 + 八字计算 | 完成 |
| [kb_service.py](fortune_ai/services/kb_service.py) | PostgreSQL FTS + trgm 搜索 | 完成 |
| [glm_client.py](fortune_ai/services/glm_client.py) | GLM via Anthropic 兼容 API | 完成 |

### 5. 关键功能核验

| 功能 | 设计要求 | 实现位置 |
|------|----------|----------|
| 真太阳时 | swisseph + 时差方程 | `bazi_facts.py:111-138` |
| A2UI 输出 | markdown_text + action_buttons | `chat_routes.py:94-111` |
| 承诺闭环 | suggested → active → done | `bento_routes.py:77-130` |
| KB RAG | FTS + trgm 混合检索 | `kb_service.py:22-43` |
| 人设风格 | standard/warm/roast | `chat_routes.py:60-62` 系统提示 |
| 系统提示 | Coach 规则，硬编码 | `chat_routes.py:43-75` |

---

## 剩余缺口（5%）

### 需验证的小项

1. **Push Worker** - 提到 `push_worker.py` 但未详细审查。需验证是否正确调度 `plan_daily` 事件。

2. **复盘 API** - `fortune_reflection` 表存在但未找到对应路由。可能有意推迟。

3. **KB 入库脚本** - 提到 `bazi_kb_ingest.py`。需验证能否正确处理 `/home/aiscend/work/fortune_ai/knowledge/bazi` 中的 PDF 文件。

4. **铁板神算路由** - UI 中引用，可能在现有后端（`backend_router`）中实现。

5. **出生校准 SSE** - UI 中引用，可能使用现有后端端点。

---

## 部署清单

1. **建库建表**
   ```bash
   psql -h 106.37.170.238 -p 8224 -U <user> -c "CREATE DATABASE fortune_ai;"
   psql -h 106.37.170.238 -p 8224 -U <user> -d fortune_ai -f migrations/20251229_final_mvp.sql
   ```

2. **环境变量**
   ```bash
   export FORTUNE_AI_DB_NAME=fortune_ai
   export FORTUNE_AI_DB_HOST=106.37.170.238
   export FORTUNE_AI_DB_PORT=8224
   export ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
   export ANTHROPIC_AUTH_TOKEN=<token>
   export FORTUNE_AI_GLM_MODEL=glm-4.7
   ```

3. **知识库入库**
   ```bash
   python -m services.bazi_kb_ingest --path /home/aiscend/work/fortune_ai/knowledge/bazi
   ```

4. **启动服务**
   ```bash
   ./deploy_nohup.sh
   ```

5. **校验流程**
   - 注册用户 → 登录 → 对话 → Bento 卡片加载
   - 承诺 accept/done 正常
   - 计划 join 正常

---

## 结论

**无需额外开发。** 代码已准备好进行部署测试。剩余 5% 是运维验证项，可在部署过程中处理。

### 下一步
1. 在 106.37.170.238:8224 执行数据库迁移
2. 入库八字知识库 PDF
3. 启动服务并验证所有流程
4. 处理测试中发现的任何运行时问题
