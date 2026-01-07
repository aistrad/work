# Mentis 前端交互优化设计文档 v2

> 基于 bp v1.md、system_design_claude_mvp v1.md 及 v1 评审意见

---

## 0. 变更记录

| 版本 | 日期 | 变更内容 |
|-----|------|---------|
| v2 | 2024-12-30 | 补齐路由架构、状态机、动作契约、数据策略；采纳 P0-P2 评审意见 |
| v1 | 2024-12-30 | 初版 |

---

## 1. 路由与信息架构 (P0)

### 1.1 路由定义

| 路由 | 模板 | 角色 | 认证 | 说明 |
|------|------|------|------|------|
| `/main` | bazi2.html | **主入口** | 需登录 | Chat + Workbench 双栏布局 |
| `/login` | login.html | 认证 | 无 | 登录页 |
| `/register` | register.html | 认证 | 无 | 注册页 |
| `/fortune` | a2ui.html | 兼容入口 | 无 | Telegram 链接兼容，计划迁移 |
| `/h5/a2ui` | a2ui.html | 兼容入口 | 无 | 企微 H5 兼容，计划迁移 |
| `/bazi` | index.html | 工具页 | 无 | 八字深度报告（独立工具） |
| `/tieban` | tieban.html | 工具页 | 无 | 铁板神算（独立工具） |

### 1.2 跳转策略

```
用户访问
    │
    ├─ /main ──────────────────┬─ 已登录 → 渲染主页面
    │                          └─ 未登录 → 302 /login
    │
    ├─ /login ─────────────────┬─ 已登录 → 302 /main
    │                          └─ 未登录 → 渲染登录页
    │
    ├─ /fortune, /h5/a2ui ─────── 渲染 a2ui.html (待迁移)
    │                              TODO: 检测登录态后 302 /main
    │
    └─ /bazi, /tieban ─────────── 独立工具页，无跳转
```

### 1.3 迁移计划

**Phase 1 (当前)**
- `/main` 为主入口，登录后默认跳转
- `/fortune`, `/h5/a2ui` 保持兼容

**Phase 2 (后续)**
- `/fortune` 检测登录态，已登录重定向 `/main`
- 新用户从 `/fortune` 引导注册后进入 `/main`

---

## 2. 统一状态机 (P0)

### 2.1 组件状态定义

所有异步组件必须实现以下状态：

```typescript
enum ComponentState {
  IDLE = 'idle',           // 初始/空闲
  LOADING = 'loading',     // 加载中
  SUCCESS = 'success',     // 成功
  EMPTY = 'empty',         // 成功但无数据
  ERROR = 'error',         // 错误
  RETRY = 'retry',         // 重试中
  DISABLED = 'disabled',   // 禁用
}
```

### 2.2 状态 CSS 类规范

```css
/* 状态类命名: {component}--{state} */
.card--loading { }
.card--empty { }
.card--error { }
.card--disabled { opacity: 0.5; pointer-events: none; }

/* 骨架屏 */
.skel {
  background: linear-gradient(90deg, var(--surface-2) 25%, var(--surface) 37%, var(--surface-2) 63%);
  background-size: 400% 100%;
  animation: shine 1.4s ease infinite;
}

/* 错误态 */
.error-state {
  color: var(--warn);
  padding: 16px;
  text-align: center;
}
.error-state__retry {
  margin-top: 8px;
}
```

### 2.3 API 状态映射表

| API | 成功态 | 空态 | 错误态 | 重试策略 |
|-----|--------|------|--------|----------|
| `/api/chat/send` | 渲染 A2UI | N/A | 显示错误+重试 | 手动重试 |
| `/api/bento/today` | 渲染指引 | "暂无指引" | 显示错误+重试 | 自动重试 1次 |
| `/api/bento/actions` | 渲染任务列表 | "暂无任务" | 显示错误 | 自动重试 1次 |
| `/api/plan/active` | 渲染计划 | 显示可加入计划 | 显示错误 | 自动重试 1次 |
| `/api/twin` | 渲染 Twin | N/A (必有数据) | 显示错误 | 自动重试 2次 |
| `/api/jitai/interventions` | 渲染干预 | 不显示 | 静默失败 | 下次轮询 |
| `/api/push/inbox` | 处理推送 | 不显示 | 静默失败 | 下次轮询 |

### 2.4 特殊错误处理

```javascript
// 错误类型与处理
const ERROR_HANDLERS = {
  // 认证失效 → 跳转登录
  401: () => { location.href = '/login'; },
  403: () => { location.href = '/login'; },

  // 限流 → 延迟重试
  429: (retryAfter) => {
    const delay = parseInt(retryAfter) * 1000 || 60000;
    return { retry: true, delay };
  },

  // 服务端错误 → 显示错误+重试
  500: () => ({ retry: true, delay: 3000 }),
  502: () => ({ retry: true, delay: 5000 }),
  503: () => ({ retry: true, delay: 5000 }),

  // 网络错误 → 显示离线提示
  0: () => ({ offline: true }),
};
```

### 2.5 离线/断网处理

```html
<!-- 离线提示条 -->
<div class="offline-banner" id="offline-banner" style="display:none">
  <span class="offline-icon">📡</span>
  <span class="offline-text">网络连接已断开，部分功能不可用</span>
  <button class="offline-retry" onclick="location.reload()">重试</button>
</div>
```

```javascript
// 网络状态监听
window.addEventListener('online', () => {
  document.getElementById('offline-banner').style.display = 'none';
  // 触发数据刷新
  refreshAllData();
});

window.addEventListener('offline', () => {
  document.getElementById('offline-banner').style.display = 'flex';
});
```

---

## 3. 动作契约标准化 (P0)

### 3.1 action_buttons 约束

**前端强制规则:**
```javascript
function normalizeActionButtons(buttons) {
  if (!Array.isArray(buttons) || buttons.length === 0) {
    // 无按钮时提供默认
    return [{ label: '好的', action: { type: 'opt_out' }, style: 'ghost' }];
  }

  // 规则: 1 主按钮 + ≤2 次按钮 + 其余折叠
  const primary = buttons.find(b => b.style === 'primary') || buttons[0];
  const secondary = buttons.filter(b => b !== primary).slice(0, 2);
  const collapsed = buttons.filter(b => b !== primary && !secondary.includes(b));

  return {
    primary: { ...primary, style: 'primary' },
    secondary: secondary.map(b => ({ ...b, style: 'ghost' })),
    collapsed: collapsed.length > 0 ? collapsed : null,
  };
}
```

**渲染规则:**
```html
<div class="action-buttons">
  <!-- 主按钮 -->
  <button class="ui-btn ui-btn-primary" data-action="...">
    开始: 10分钟冥想
  </button>

  <!-- 次按钮 (最多2个) -->
  <button class="ui-btn ui-btn-ghost" data-action="...">
    加入今日计划
  </button>
  <button class="ui-btn ui-btn-ghost" data-action="...">
    先不需要
  </button>

  <!-- 折叠按钮 (如有更多) -->
  <button class="ui-btn ui-btn-ghost action-more" aria-expanded="false">
    更多 ▾
  </button>
  <div class="action-dropdown" hidden>
    <!-- 折叠的按钮 -->
  </div>
</div>
```

### 3.2 动作执行契约

```typescript
interface ActionPayload {
  type: ActionType;
  idempotency_key?: string;  // 幂等键，防重复提交
  [key: string]: any;
}

type ActionType =
  | 'start_task'      // 开始任务
  | 'schedule_task'   // 加入计划
  | 'done_task'       // 完成任务
  | 'open_panel'      // 打开面板
  | 'opt_out'         // 先不需要
  | 'send_message'    // 发送消息
  | 'navigate'        // 页面跳转
  ;
```

### 3.3 二次确认规则

| 动作类型 | 需确认 | 确认方式 |
|---------|--------|---------|
| `done_task` | 否 | 直接执行 |
| `start_task` | 否 | 直接执行 |
| `schedule_task` | 否 | 直接执行 |
| `delete_*` | **是** | 弹窗确认 |
| `send_buff` (>100 Aura) | **是** | 弹窗确认金额 |
| `opt_out` | 否 | 直接执行 |

### 3.4 乐观更新与回滚

```javascript
async function executeAction(action, button) {
  const idempotencyKey = action.idempotency_key || `${action.type}_${Date.now()}`;

  // 1. 乐观更新 UI
  const originalState = captureButtonState(button);
  setButtonState(button, 'loading');

  try {
    // 2. 发送请求
    const result = await apiJson(getActionEndpoint(action), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Idempotency-Key': idempotencyKey,
        ...csrfHeaders(),
      },
      body: JSON.stringify(action),
    });

    // 3. 成功态
    setButtonState(button, 'success');
    trackActionComplete(action, result);  // 埋点

    // 4. 触发反馈 (如有奖励)
    if (result.rewards) {
      showRewardFeedback(result.rewards);
    }

    return result;

  } catch (error) {
    // 5. 回滚 UI
    restoreButtonState(button, originalState);
    trackActionError(action, error);  // 埋点

    // 6. 显示错误
    showActionError(error);
    throw error;
  }
}
```

### 3.5 埋点闭环

```javascript
// 动作埋点规范
function trackActionClick(action) {
  track('action_click', {
    action_type: action.type,
    task_id: action.task_id,
    source: 'chat' | 'bento' | 'push',
    timestamp: Date.now(),
  });
}

function trackActionComplete(action, result) {
  track('action_complete', {
    action_type: action.type,
    task_id: action.task_id,
    latency_ms: Date.now() - action._startTime,
    rewards: result.rewards,
  });
}

function trackActionError(action, error) {
  track('action_error', {
    action_type: action.type,
    task_id: action.task_id,
    error_code: error.code,
    error_message: error.message,
  });
}
```

---

## 4. 数据策略升级 (P0)

### 4.1 预加载策略

**替换 Promise.all 为 allSettled + 渐进渲染:**

```javascript
async function initPage() {
  // 关键数据优先
  const criticalPromises = [
    { key: 'profile', fn: () => apiJson('/api/user/profile') },
    { key: 'today', fn: () => apiJson('/api/bento/today') },
  ];

  // 次要数据延后
  const secondaryPromises = [
    { key: 'actions', fn: () => apiJson('/api/bento/actions') },
    { key: 'plan', fn: () => apiJson('/api/plan/active') },
    { key: 'twin', fn: () => apiJson('/api/twin') },
  ];

  // 后台数据
  const backgroundPromises = [
    { key: 'interventions', fn: () => apiJson('/api/jitai/interventions') },
    { key: 'sessions', fn: () => apiJson('/api/session/list?limit=20') },
  ];

  // 阶段1: 关键数据
  const criticalResults = await Promise.allSettled(
    criticalPromises.map(p => p.fn())
  );
  criticalPromises.forEach((p, i) => {
    const result = criticalResults[i];
    if (result.status === 'fulfilled') {
      renderSection(p.key, result.value);
    } else {
      renderSectionError(p.key, result.reason);
    }
  });

  // 阶段2: 次要数据 (不阻塞)
  Promise.allSettled(secondaryPromises.map(p => p.fn()))
    .then(results => {
      secondaryPromises.forEach((p, i) => {
        const result = results[i];
        if (result.status === 'fulfilled') {
          renderSection(p.key, result.value);
        } else {
          renderSectionError(p.key, result.reason);
        }
      });
    });

  // 阶段3: 后台数据 (静默失败)
  Promise.allSettled(backgroundPromises.map(p => p.fn()))
    .then(results => {
      backgroundPromises.forEach((p, i) => {
        if (results[i].status === 'fulfilled') {
          renderSection(p.key, results[i].value);
        }
        // 后台数据失败不显示错误
      });
    });
}
```

### 4.2 轮询策略

```javascript
class SmartPoller {
  constructor(options) {
    this.baseInterval = options.interval || 60000;
    this.maxInterval = options.maxInterval || 300000;
    this.currentInterval = this.baseInterval;
    this.failCount = 0;
    this.isVisible = true;
    this.timer = null;

    // 可见性监听
    document.addEventListener('visibilitychange', () => {
      this.isVisible = document.visibilityState === 'visible';
      if (this.isVisible) {
        this.resetInterval();
        this.poll(); // 立即轮询
      }
    });
  }

  async poll() {
    if (!this.isVisible) return;

    try {
      await this.fetchFn();
      this.resetInterval();
    } catch (error) {
      this.backoff();
    }

    this.scheduleNext();
  }

  backoff() {
    this.failCount++;
    // 指数退避: 60s → 120s → 240s → max 300s
    this.currentInterval = Math.min(
      this.baseInterval * Math.pow(2, this.failCount),
      this.maxInterval
    );
  }

  resetInterval() {
    this.failCount = 0;
    this.currentInterval = this.baseInterval;
  }

  scheduleNext() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(() => this.poll(), this.currentInterval);
  }

  start(fetchFn) {
    this.fetchFn = fetchFn;
    this.poll();
  }

  stop() {
    if (this.timer) clearTimeout(this.timer);
  }
}

// 使用
const pushPoller = new SmartPoller({ interval: 60000, maxInterval: 300000 });
pushPoller.start(() => pollPushInbox());

const jitaiPoller = new SmartPoller({ interval: 300000, maxInterval: 600000 });
jitaiPoller.start(() => pollInterventions());
```

### 4.3 SSE/WebSocket 演进路径

**当前: 轮询**
```
客户端 ──(每60s)──> /api/push/inbox
客户端 ──(每300s)──> /api/jitai/interventions
```

**Phase 2: SSE**
```
客户端 ──(建立连接)──> /api/events/stream
服务端 ──(推送)──> event: push\ndata: {...}
服务端 ──(推送)──> event: jitai\ndata: {...}
```

```javascript
// SSE 客户端
function connectEventStream() {
  const es = new EventSource('/api/events/stream');

  es.addEventListener('push', (e) => {
    const data = JSON.parse(e.data);
    handlePushEvent(data);
  });

  es.addEventListener('jitai', (e) => {
    const data = JSON.parse(e.data);
    handleJitaiIntervention(data);
  });

  es.onerror = () => {
    // 断线重连 (浏览器自动处理，但加入指数退避)
    setTimeout(() => connectEventStream(), 5000);
  };
}
```

**Phase 3: WebSocket (如需双向通信)**
- 实时聊天
- 协作功能
- 更低延迟需求

---

## 5. 快捷入口情境化 (P1)

### 5.1 动态排序逻辑

```javascript
function getContextualQuickPrompts(userContext) {
  const prompts = [];

  // 1. Profile 完整度检查
  if (!userContext.profile.birthday_local) {
    prompts.push({
      label: '完善出生信息',
      prompt: null,  // 打开设置面板
      action: { type: 'open_panel', panel: 'settings' },
      priority: 100,
    });
  }

  // 2. 今日状态
  if (userContext.today?.score < 60) {
    prompts.push({
      label: '今日注意事项',
      prompt: '今天的运势评分较低，请帮我分析需要注意什么',
      priority: 90,
    });
  }

  // 3. 有进行中任务
  if (userContext.actions?.some(a => a.status === 'active')) {
    prompts.push({
      label: '任务进度',
      prompt: '帮我回顾一下今天的任务完成情况',
      priority: 80,
    });
  }

  // 4. 最近对话主题
  const recentTopics = userContext.recentTopics || [];
  if (recentTopics.includes('career')) {
    prompts.push({
      label: '事业发展',
      prompt: '继续聊聊我的事业发展方向',
      priority: 70,
    });
  }

  // 5. 默认选项
  const defaults = [
    { label: '今日运势', prompt: '帮我分析今天的运势和注意事项', priority: 50 },
    { label: '本周规划', prompt: '根据我的命盘，帮我规划本周的重点', priority: 40 },
    { label: '我的优势', prompt: '分析我的核心优势和最佳发展方向', priority: 30 },
  ];

  prompts.push(...defaults);

  // 按优先级排序，取前4个
  return prompts
    .sort((a, b) => b.priority - a.priority)
    .slice(0, 4);
}
```

### 5.2 交互增强

```html
<div class="quick-prompts" id="quick-prompts">
  <!-- 动态生成 -->
  <button class="quick-prompt-chip"
          data-prompt="帮我分析今天的运势"
          data-action="fill">
    今日运势
  </button>
</div>
```

```javascript
// 点击: 一键填充不立刻发送
document.querySelectorAll('.quick-prompt-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    const prompt = chip.dataset.prompt;
    if (prompt) {
      document.getElementById('ask-text').value = prompt;
      document.getElementById('ask-text').focus();
    }
  });

  // 长按: 编辑/置顶/隐藏
  let pressTimer;
  chip.addEventListener('touchstart', () => {
    pressTimer = setTimeout(() => showChipMenu(chip), 500);
  });
  chip.addEventListener('touchend', () => {
    clearTimeout(pressTimer);
  });
});

function showChipMenu(chip) {
  // 显示菜单: 编辑 | 置顶 | 隐藏
  const menu = document.createElement('div');
  menu.className = 'chip-menu';
  menu.innerHTML = `
    <button data-action="edit">编辑</button>
    <button data-action="pin">置顶</button>
    <button data-action="hide">隐藏</button>
  `;
  // ...
}
```

---

## 6. 奖励反馈可解释化 (P1)

### 6.1 增强 Toast 结构

```html
<div class="reward-toast" id="reward-toast">
  <div class="reward-toast__header">
    <span class="reward-icon">✨</span>
    <span class="reward-title">任务完成！</span>
  </div>

  <div class="reward-toast__body">
    <!-- Aura 奖励 -->
    <div class="reward-row">
      <span class="reward-label">获得</span>
      <span class="reward-value">+10 Aura</span>
    </div>

    <!-- 连击天数 -->
    <div class="reward-row">
      <span class="reward-label">成长连击</span>
      <span class="reward-value">🔥 7 天</span>
    </div>

    <!-- 维度变化 (可解释) -->
    <div class="reward-dimensions">
      <div class="dim-change positive">
        <span class="dim-name">事业</span>
        <span class="dim-delta">+2</span>
        <span class="dim-reason">完成工作任务</span>
      </div>
      <div class="dim-change positive">
        <span class="dim-name">健康</span>
        <span class="dim-delta">+1</span>
        <span class="dim-reason">规律作息</span>
      </div>
    </div>
  </div>

  <!-- 安静模式入口 -->
  <button class="reward-toast__quiet" id="enable-quiet-mode">
    减少动效提示
  </button>
</div>
```

### 6.2 安静模式

```javascript
// 用户偏好
const quietMode = localStorage.getItem('reward_quiet_mode') === 'true';

function showRewardFeedback(rewards) {
  if (quietMode) {
    // 安静模式: 仅显示简短提示
    showMinimalToast(`+${rewards.aura_earned} Aura`);
    return;
  }

  // 完整模式
  showFullRewardToast(rewards);
}

// 启用安静模式
document.getElementById('enable-quiet-mode')?.addEventListener('click', () => {
  localStorage.setItem('reward_quiet_mode', 'true');
  hideToast();
});
```

---

## 7. 情绪打卡优化 (P1)

### 7.1 二维情绪盘 (愉悦 × 唤醒)

```
        高唤醒
           ↑
   焦虑 ──┼── 兴奋
           │
低愉悦 ←──┼──→ 高愉悦
           │
   低落 ──┼── 平静
           ↓
        低唤醒
```

```html
<div class="mood-wheel" id="mood-wheel">
  <div class="mood-wheel__grid">
    <!-- 8个情绪区域 -->
    <button class="mood-zone" data-valence="1" data-arousal="1" data-mood="excited">
      😆 兴奋
    </button>
    <button class="mood-zone" data-valence="1" data-arousal="0" data-mood="happy">
      😊 开心
    </button>
    <button class="mood-zone" data-valence="1" data-arousal="-1" data-mood="calm">
      😌 平静
    </button>
    <button class="mood-zone" data-valence="0" data-arousal="-1" data-mood="tired">
      😴 疲惫
    </button>
    <button class="mood-zone" data-valence="-1" data-arousal="-1" data-mood="sad">
      😢 低落
    </button>
    <button class="mood-zone" data-valence="-1" data-arousal="0" data-mood="upset">
      😞 沮丧
    </button>
    <button class="mood-zone" data-valence="-1" data-arousal="1" data-mood="anxious">
      😰 焦虑
    </button>
    <button class="mood-zone" data-valence="0" data-arousal="1" data-mood="alert">
      😳 紧张
    </button>
  </div>

  <!-- 选中后的强度调节 -->
  <div class="mood-intensity" id="mood-intensity" hidden>
    <label>程度</label>
    <input type="range" min="1" max="10" value="5" />
  </div>
</div>
```

### 7.2 默认展示上次状态

```javascript
async function initMoodCheckin() {
  // 获取上次打卡
  const lastCheckin = await getLastCheckin();

  if (lastCheckin) {
    // 显示上次状态
    document.getElementById('last-mood-display').innerHTML = `
      <div class="last-mood">
        <span class="last-mood__label">上次心情</span>
        <span class="last-mood__value">${lastCheckin.mood} (${lastCheckin.intensity}/10)</span>
        <span class="last-mood__time">${formatTime(lastCheckin.created_at)}</span>
      </div>
      <div class="suggested-action">
        <span>建议动作:</span>
        <button class="ui-btn ui-btn-ghost" data-action="start_task"
                data-task-id="${lastCheckin.suggested_task_id}">
          ${lastCheckin.suggested_action}
        </button>
      </div>
    `;
  }
}
```

### 7.3 危机兜底入口

```html
<!-- 情绪打卡底部固定 -->
<div class="mood-crisis-link">
  <a href="#" id="crisis-help">
    如果你正在经历困难时刻，点这里获取帮助 →
  </a>
</div>
```

```javascript
document.getElementById('crisis-help')?.addEventListener('click', (e) => {
  e.preventDefault();

  // 显示危机资源
  showModal({
    title: '获取帮助',
    content: `
      <p>如果你正在经历情绪困扰，以下资源可能对你有帮助：</p>
      <ul>
        <li>全国心理援助热线: 400-161-9995</li>
        <li>北京心理危机研究与干预中心: 010-82951332</li>
        <li>生命热线: 400-821-1215</li>
      </ul>
      <p>记住，寻求帮助是勇敢的表现。</p>
    `,
  });

  // 埋点
  track('crisis_help_clicked');
});
```

---

## 8. JITAI 可控性 (P1)

### 8.1 干预卡片标准结构

```html
<div class="jitai-card" data-intervention-id="123">
  <div class="jitai-card__content">
    <span class="jitai-icon">💡</span>
    <div class="jitai-text">
      <span class="jitai-title">适合做决策的时机</span>
      <span class="jitai-body">当前时辰对你的思维清晰度有利</span>
    </div>
  </div>

  <div class="jitai-card__actions">
    <!-- 主动作 -->
    <button class="ui-btn ui-btn-ghost" data-action="click">
      查看建议
    </button>

    <!-- 控制三件套 -->
    <div class="jitai-controls">
      <button class="jitai-snooze" data-action="snooze" title="稍后提醒">
        ⏰
      </button>
      <button class="jitai-quiet" data-action="quiet_today" title="今天不再提示">
        🔕
      </button>
      <button class="jitai-why" data-action="explain" title="为什么现在">
        ❓
      </button>
      <button class="jitai-dismiss" data-action="dismiss" title="关闭">
        ✕
      </button>
    </div>
  </div>
</div>
```

### 8.2 频控规则

```javascript
const JITAI_LIMITS = {
  maxPerHour: 2,
  maxPerDay: 6,
  minInterval: 30 * 60 * 1000,  // 30分钟
  quietUntil: null,  // 用户设置的静默截止时间
};

function shouldShowIntervention(intervention) {
  const now = Date.now();
  const state = getJitaiState();

  // 检查静默期
  if (state.quietUntil && now < state.quietUntil) {
    return false;
  }

  // 检查最小间隔
  if (state.lastShown && now - state.lastShown < JITAI_LIMITS.minInterval) {
    return false;
  }

  // 检查小时限制
  const hourCount = state.hourHistory.filter(t => now - t < 3600000).length;
  if (hourCount >= JITAI_LIMITS.maxPerHour) {
    return false;
  }

  // 检查每日限制
  const dayCount = state.dayHistory.filter(t => isSameDay(t, now)).length;
  if (dayCount >= JITAI_LIMITS.maxPerDay) {
    return false;
  }

  return true;
}
```

### 8.3 控制动作处理

```javascript
async function handleJitaiAction(interventionId, action) {
  switch (action) {
    case 'snooze':
      // 稍后提醒 (30分钟后)
      await apiJson(`/api/jitai/interventions/${interventionId}/snooze`, {
        method: 'POST',
        body: JSON.stringify({ snooze_minutes: 30 }),
      });
      hideIntervention(interventionId);
      break;

    case 'quiet_today':
      // 今天不再提示
      setJitaiQuietUntil(getEndOfDay());
      hideIntervention(interventionId);
      showToast('今天不再显示干预提示');
      break;

    case 'explain':
      // 为什么现在
      const explanation = await apiJson(
        `/api/jitai/interventions/${interventionId}/explain`
      );
      showModal({
        title: '为什么现在提示',
        content: explanation.reason,
      });
      break;

    case 'dismiss':
      await apiJson(`/api/jitai/interventions/${interventionId}/dismiss`, {
        method: 'POST',
      });
      hideIntervention(interventionId);
      break;
  }
}
```

---

## 9. Twin/社交隐私设计 (P2)

### 9.1 Twin 渐进披露

```
Level 1 - 摘要视图 (默认)
┌─────────────────────────────────┐
│ 我的状态                         │
│ 综合指数: 78 · 成长连击: 7天      │
│ [查看详情]                       │
└─────────────────────────────────┘

Level 2 - 变化视图 (点击展开)
┌─────────────────────────────────┐
│ 近期变化                         │
│ • 事业 +5 (完成3个工作任务)       │
│ • 健康 +3 (坚持运动计划5天)       │
│ [查看完整分析]                   │
└─────────────────────────────────┘

Level 3 - 完整视图 (明确请求)
┌─────────────────────────────────┐
│ 数字孪生详情                     │
│ L1: 命理基础                     │
│ L2: 动态状态                     │
│ L3: 维度评分 (带置信度)          │
│                                 │
│ ⚠️ 部分数据基于推断，仅供参考      │
└─────────────────────────────────┘
```

### 9.2 不确定性展示

```html
<div class="twin-dimension">
  <span class="dim-name">事业发展</span>
  <div class="dim-score-bar">
    <div class="dim-score-fill" style="width: 85%"></div>
    <!-- 置信区间 -->
    <div class="dim-confidence" style="left: 80%; width: 10%"></div>
  </div>
  <span class="dim-score">85</span>
  <span class="dim-confidence-label" title="基于近7天数据推断">
    ±5
  </span>
</div>
```

### 9.3 社交隐私默认值

```javascript
const DEFAULT_PRIVACY = {
  // Twin 数据
  twin_visible_to_friends: false,
  twin_visible_dimensions: [],  // 默认不公开任何维度

  // 分享
  share_require_confirm: true,  // 每次分享需确认
  share_expire_hours: 168,      // 分享链接7天过期

  // 好友
  friend_request_mode: 'approve',  // 需手动同意
  compatibility_visible: false,    // 合盘结果默认不公开
};

// 分享前确认
async function createShareCard(cardType, content) {
  const confirmed = await showConfirmDialog({
    title: '确认分享',
    message: '此内容将生成可分享的链接，有效期7天。确定分享吗？',
    confirmText: '分享',
    cancelText: '取消',
  });

  if (!confirmed) return null;

  return apiJson('/api/social/share', {
    method: 'POST',
    body: JSON.stringify({ card_type: cardType, content }),
  });
}
```

---

## 10. 端到端验收清单

### 10.1 核心流程

- [ ] 登录 → 跳转 /main
- [ ] 首次用户 → 显示引导
- [ ] Profile 不完整 → 显示提示
- [ ] 发送消息 → 显示加载态 → 渲染 A2UI
- [ ] 点击动作按钮 → 乐观更新 → 成功/回滚
- [ ] 完成任务 → 奖励反馈 → 刷新数据
- [ ] 断网 → 显示离线提示 → 恢复后刷新
- [ ] 限流 → 显示提示 → 延迟重试

### 10.2 状态覆盖

- [ ] 对话卡片: loading / success / error
- [ ] Bento 今日: loading / success / empty / error
- [ ] Bento 任务: loading / success / empty / error
- [ ] 成长计划: loading / success(有计划) / success(无计划) / error
- [ ] Twin: loading / success / error
- [ ] JITAI: 频控 / 静默 / 显示 / 关闭

### 10.3 Playwright 测试点

```javascript
// 示例测试
test('complete task flow', async ({ page }) => {
  // 登录
  await page.goto('/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password');
  await page.click('button[type="submit"]');

  // 等待主页面
  await page.waitForURL('/main');

  // 发送消息
  await page.fill('#ask-text', '今天适合做什么');
  await page.click('#ask-btn');

  // 等待响应
  await page.waitForSelector('.msg-bot.card');

  // 点击任务按钮
  const actionBtn = page.locator('.a2ui-btn[data-action*="start_task"]').first();
  await actionBtn.click();

  // 验证奖励反馈
  await page.waitForSelector('.reward-toast.show');

  // 验证任务列表更新
  await page.waitForSelector('#actions-content .action-card--active');
});
```

---

## 附录 A: 文件变更清单

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `api/static/ui.js` | 修改 | 状态机、动作契约、数据策略 |
| `api/static/ui.css` | 修改 | 状态类样式 |
| `api/templates/bazi2.html` | 修改 | 离线提示、奖励弹层 |
| `api/main.py` | 修改 | /fortune 跳转逻辑 (Phase 2) |

---

*文档版本: v2.0*
*更新日期: 2024-12-30*
*评审状态: 待评审*
