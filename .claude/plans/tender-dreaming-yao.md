# Proactive 系统 LLM-First 重构计划

> 完整设计文档: `/home/aiscend/work/vibelife/docs/components/proactive/LLM-FIRST-REFACTOR.md`

## 核心设计已更新

基于 review 意见，文档已更新以下关键点：

### 1. LLM-First ≠ 什么都让 LLM 做
- 确定性计算由平台做（cron、exists、数值比较）
- 复杂语义才回退 LLM

### 2. TriggerEvaluator：静态优先 + LLM 回退
- `STATIC_OPERATORS = {exists, !exists, ==, !=, >, <, >=, <=, contains}`
- 静态条件短路优化
- cron 匹配带时区 + 幂等 bucket_key

### 3. ProactiveOrchestrator：平台硬约束
- 静默时段检查
- 每日推送上限
- 幂等去重（idempotent_key）
- 冷却时间检查

### 4. 画像路径统一到 vibe.*
- `identity.birth_info` → `vibe.profile.birth_info`
- `life_context.goals` → `vibe.goals`

### 5. 内容提取：Pydantic 校验 + 兜底模板
- 结构化输出校验
- 字段截断
- 失败兜底

## 待补充内容（实施时完成）

- [ ] Profile Path Contract 完整章节
- [ ] threshold_based 示例或移除
- [ ] 模型选择矩阵（Haiku vs Sonnet）
- [ ] 测试用例（静态条件/LLM 回退/幂等键/静默时段）

## 验证方案

```bash
pytest tests/services/proactive/ -v
python workers/proactive_worker.py --dry-run
```
