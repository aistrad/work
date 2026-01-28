# VibeLife Chat 功能优化 - Top 3 优先改进

> 基于文档深度阅读 + 8232 实际测试 + 代码深度探索
> 日期: 2026-01-22
> 排除：卡片渲染问题（已有人在做）

---

## 一、问题诊断总结

### 实测发现的核心问题

| 问题 | 影响程度 | 用户感知 |
|------|---------|---------|
| **Skill 路由失控** | ⭐⭐⭐⭐⭐ | 用户在八字页面问运势，却跳到塔罗 |
| **Dashboard 是 Mock 数据** | ⭐⭐⭐⭐ | 用户看到的不是自己的真实数据 |
| **主动推送可能未运行** | ⭐⭐⭐ | 用户没有收到个性化的主动关怀 |

---

## 二、Top 3 优先改进

### P0: 修复 Phase 2 Skill 边界意识（最紧急）

**问题现象**：
用户在 `/chat?skill=bazi` 页面输入"帮我看看今天运势"，LLM 却调用 `activate_skill(skill=tarot)` 切换到塔罗。

**根本原因**（代码分析）：
1. **Phase 2 System Prompt 缺少显式上下文标记**
   - `prompt_builder.py` 没有注入"你现在在 {skill_id} Skill 内"
   - LLM 不知道自己应该优先使用当前 Skill 的工具

2. **边界意识规则只在特定状态注入**
   - `routing.yaml` 的边界意识规则只在 `ready_for_analysis` 状态下注入
   - 如果用户还在 `need_birth_info` 阶段，边界意识规则不会出现

3. **bazi 有 daily-fortune 规则但未被匹配**
   - `apps/api/skills/bazi/rules/daily-fortune.md` 存在
   - tags 包含"今日运势、每日、今天、日运"
   - 但 LLM 选择了 tarot 而非 bazi 的工具

**解决方案**：

修改 `apps/api/services/agent/prompt_builder.py`：

```python
# 在 build() 方法的 Phase 2 分支中添加显式上下文标记
def build(self, ...) -> str:
    if skill_id:
        # 新增：显式 Skill 上下文标记
        skill_context = f"""
## 当前技能模式：{skill_id}

你现在是 {skill_name} 专家，正在为用户提供 {skill_name} 相关服务。
用户的请求应该优先使用当前 Skill 的工具处理。

**重要**：除非用户明确要求切换（如"我想看星座"、"换一个"），否则不要调用 activate_skill。
"""
        prompt_parts.insert(0, skill_context)
```

**关键文件**：
- `apps/api/services/agent/prompt_builder.py` - 添加显式上下文
- `apps/api/services/agent/skill_loader.py:1101-1122` - 边界规则注入逻辑
- `apps/api/config/routing.yaml:243-263` - 边界意识模板

**验证方法**：
1. 重启 API 服务
2. 访问 `/chat?skill=bazi`
3. 输入"帮我看看今天运势"
4. 预期：使用 bazi 的 show_bazi_fortune 工具，不切换 skill

---

### P1: Dashboard 接入真实数据（重要）

**问题现象**：
Dashboard 欢迎消息显示的是硬编码的 Mock 数据，不是用户真实的目标、习惯、运势。

**根本原因**：
`apps/web/src/app/api/dashboard/route.ts` 使用 Mock 数据：
```typescript
// ⚠️ TODO: Replace with actual backend proxy
const MOCK_DASHBOARD: DashboardDTO = {
  userId: "mock-user",
  lifecoach: {
    northStar: "成为一个有影响力的创作者",  // 硬编码！
    // ...
  }
}
```

**后端数据已就绪**（探索发现）：
- `unified_profiles.profile.vibe.target` 包含用户真实目标
- `unified_profiles.profile.skills.lifecoach` 包含 north_star、goals
- `unified_profiles.profile.skills.bazi.daily_fortune` 包含今日运势
- Profile 三层架构完整：Identity → Skills → Vibe

**解决方案**：

1. 后端新增 Dashboard API（或修改现有）：
```python
# apps/api/routes/dashboard.py
@router.get("/dashboard")
async def get_dashboard(user_id: UUID = Depends(get_current_user)):
    profile = await UnifiedProfileRepository.get_profile(user_id)

    return {
        "ambient": await generate_ambient_greeting(profile),
        "status": await get_user_status(user_id),
        "lifecoach": extract_lifecoach_summary(profile),
        "mySkills": await get_subscribed_skills_summary(user_id, profile),
        "discover": get_discoverable_skills()
    }
```

2. 前端 API route 改为代理后端：
```typescript
// apps/web/src/app/api/dashboard/route.ts
export async function GET(request: NextRequest) {
  const token = getToken(request);
  const res = await fetch(`${BACKEND_URL}/api/v1/dashboard`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  return NextResponse.json(await res.json());
}
```

**关键文件**：
- `apps/api/routes/dashboard.py` - 新建或修改
- `apps/web/src/app/api/dashboard/route.ts` - 改为代理
- `apps/api/stores/unified_profile_repo.py` - 数据读取

**验证方法**：
1. 用真实用户登录（有 lifecoach 数据的用户）
2. 访问 `/chat`
3. 预期：看到真实的 north_star、goals、daily_fortune

---

### P2: 验证并启用 Proactive Engine（提升体验）

**问题现象**：
Proactive Engine 架构完整，但不确定 Worker/Cron 是否在运行。用户可能没有收到主动推送。

**探索发现**：
- `apps/api/services/proactive/engine.py` - 完整实现 ✅
- `apps/api/services/proactive/trigger_detector.py` - 三种触发类型 ✅
- `apps/api/services/proactive/content_generator.py` - 三层内容生成 ✅
- 各 Skill 的 `reminders.yaml` 配置完整 ✅
- **但**：需要验证是否有 Cron Job 调用 `ProactiveEngine.run_once()`

**解决方案**：

1. 检查现有 Worker：
```bash
grep -r "ProactiveEngine" apps/api/workers/
grep -r "run_once\|run_scheduled" apps/api/
cat apps/api/scripts/crontab.example
```

2. 如果没有，添加定时任务：
```python
# apps/api/workers/proactive_worker.py
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@scheduler.scheduled_job('cron', hour='*')  # 每小时运行
async def run_proactive_scan():
    engine = ProactiveEngine()
    tasks = await engine.run_scheduled_scan()
    await engine.process_tasks(tasks)

scheduler.start()
```

3. 或在 crontab 中添加：
```bash
# 每小时运行 Proactive Engine
0 * * * * cd /opt/vibelife/apps/api && python -m workers.proactive_worker
```

**关键文件**：
- `apps/api/workers/proactive_worker.py` - 新建或检查
- `apps/api/scripts/crontab.example` - 检查配置
- `apps/api/services/proactive/engine.py` - 入口方法

**验证方法**：
1. 手动运行 `python -c "from services.proactive.engine import ProactiveEngine; ..."`
2. 检查 `notifications` 表是否有新数据
3. 用户登录后检查是否能看到通知

---

## 三、实施顺序

```
Day 1: P0 - Phase 2 边界意识修复
  ├─ 修改 prompt_builder.py 添加显式上下文
  ├─ 确保边界意识规则在所有状态下注入
  └─ 测试验证

Day 2: P1 - Dashboard 真实数据接入
  ├─ 后端 Dashboard API 实现
  ├─ 前端代理修改
  └─ 测试验证

Day 3: P2 - Proactive Engine 验证
  ├─ 检查现有 Worker 配置
  ├─ 如需要，添加 Cron Job
  └─ 测试推送流程
```

---

## 四、验证 Checklist

### P0 验证
- [ ] 在 `/chat?skill=bazi` 输入"今日运势"
- [ ] 确认使用 bazi 工具而非切换到 tarot
- [ ] 确认控制台无 activate_skill 调用（除非用户明确要求）

### P1 验证
- [ ] 用有 lifecoach 数据的用户登录
- [ ] 确认 Dashboard 显示真实的 north_star
- [ ] 确认 mySkills 显示真实的订阅技能数据

### P2 验证
- [ ] 确认 Cron Job 正在运行
- [ ] 检查 notifications 表有数据
- [ ] 用户能看到并响应通知

---

## 五、风险与注意事项

1. **P0 修改可能影响其他场景**
   - 需要测试用户明确要求切换时是否仍能正常切换
   - 测试 Phase 1 路由是否不受影响

2. **P1 需要后端 API 支持**
   - 如果后端 `/api/v1/dashboard` 不存在，需要新建
   - 需要处理用户未登录/数据不完整的 fallback

3. **P2 需要服务器配置权限**
   - 添加 Cron Job 可能需要运维配合
   - 需要监控推送频率，避免打扰用户
