# Fortune AI 前端交互优化设计文档 v1

> 基于 bp v1.md 商业计划书和 system_design_claude_mvp v1.md 系统设计文档

---

## 1. 设计原则

### 1.1 核心理念
- **Coach > Teaching Assistant > Customer Support > Sales** - 优先级不可逆
- **有效而极简** - 保持"人生导航/陪伴/提升"的产品定位
- **反馈闭环** - 做了事 → 属性变化 → 反馈 → 激励再行动

### 1.2 交互原则
1. **结论先行**: 每个输出必须包含 结论 + 依据 + 处方 + 承诺邀请
2. **行动导向**: 所有内容都要有可点击的下一步动作
3. **正向表达**: 禁止恐吓、羞辱、宿命论；负面信息必须紧接行动处方
4. **即时反馈**: 完成任务后立即展示 Aura 奖励和成长连击

---

## 2. 页面结构优化

### 2.1 主对话页面 `/fortune`

#### 现状
- 左侧对话区 + 右侧 Workbench（Bento/工具/设置）
- 移动端通过 Tab 切换

#### 优化方向

##### 2.1.1 对话区增强
```
┌─────────────────────────────────────────────────┐
│ Header: Fortune AI | 用户头像 | Aura: 1,280 ✦    │
├─────────────────────────────────────────────────┤
│                                                 │
│  [用户消息]                                      │
│                                                 │
│  [AI回复 - A2UI 卡片]                            │
│  ├─ markdown_text (结论/依据/处方)              │
│  ├─ stat_card (可选: 相关数值)                  │
│  └─ action_buttons (必须: 下一步动作)           │
│      • 开始: {具体任务}                         │
│      • 加入今日计划                             │
│      • 打开功能区                               │
│      • 先不需要                                 │
│                                                 │
│  [快捷提问 Chips]                               │
│  • 今日运势 • 本周规划 • 我的优势               │
│                                                 │
├─────────────────────────────────────────────────┤
│ [+] │ 输入你的问题...               │ [发送] │
└─────────────────────────────────────────────────┘
```

##### 2.1.2 新增: 快捷入口区
在输入框上方添加快捷入口，降低用户输入门槛：

```javascript
// 快捷提问配置
const quickPrompts = [
  { label: "今日运势", prompt: "帮我分析今天的运势和注意事项" },
  { label: "本周规划", prompt: "根据我的命盘，帮我规划本周的重点" },
  { label: "我的优势", prompt: "分析我的核心优势和最佳发展方向" },
  { label: "情绪指引", prompt: "我现在情绪有些低落，给我一些建议" },
];
```

##### 2.1.3 对话上下文感知
- 检测用户是否完成 Profile 设置
- 如未完成，首次访问显示引导卡片
- 根据当日 Bento 状态调整快捷入口

### 2.2 Bento 功能区优化

#### 现状结构
```
Bento Tab
├─ 今日指引 (#today-content)
├─ 行动任务 (#actions-content)
└─ 成长计划 (#plan-content)
```

#### 优化: 增加状态可视化

##### 2.2.1 今日指引卡片增强
```html
<div class="bento-today">
  <!-- 日期和状态 -->
  <div class="bento-today__header">
    <span class="date">2024-12-30 周一</span>
    <span class="lunar">农历十一月三十 癸卯日</span>
  </div>

  <!-- 今日评分 -->
  <div class="bento-today__score">
    <div class="score-ring" data-score="78">
      <span class="score-value">78</span>
      <span class="score-label">综合指数</span>
    </div>
  </div>

  <!-- 维度指标 -->
  <div class="bento-today__dimensions">
    <div class="dimension" data-dim="career">
      <span class="dim-icon">💼</span>
      <span class="dim-label">事业</span>
      <div class="dim-bar" style="--value: 85%"></div>
    </div>
    <div class="dimension" data-dim="wealth">
      <span class="dim-icon">💰</span>
      <span class="dim-label">财运</span>
      <div class="dim-bar" style="--value: 72%"></div>
    </div>
    <div class="dimension" data-dim="relationship">
      <span class="dim-icon">❤️</span>
      <span class="dim-label">感情</span>
      <div class="dim-bar" style="--value: 68%"></div>
    </div>
    <div class="dimension" data-dim="health">
      <span class="dim-icon">🏃</span>
      <span class="dim-label">健康</span>
      <div class="dim-bar" style="--value: 80%"></div>
    </div>
  </div>

  <!-- 今日要点 -->
  <div class="bento-today__tips">
    <h4>今日要点</h4>
    <ul>
      <li>宜：主动沟通、推进项目</li>
      <li>忌：冲动决策、大额支出</li>
    </ul>
  </div>
</div>
```

##### 2.2.2 行动任务卡片重设计
```html
<div class="bento-actions">
  <!-- 进行中任务 - 高亮显示 -->
  <div class="action-section active">
    <h4>🔥 进行中</h4>
    <div class="action-card action-card--active">
      <div class="action-card__content">
        <span class="action-title">完成项目提案初稿</span>
        <span class="action-meta">来自今日对话</span>
      </div>
      <div class="action-card__actions">
        <button class="ui-btn ui-btn-primary" data-action="done_task">
          ✓ 完成
        </button>
      </div>
    </div>
  </div>

  <!-- 待处理任务 -->
  <div class="action-section pending">
    <h4>📋 建议任务</h4>
    <div class="action-card">
      <div class="action-card__content">
        <span class="action-title">10分钟冥想</span>
        <span class="action-meta">情绪调节 · 预计5分钟</span>
      </div>
      <div class="action-card__actions">
        <button class="ui-btn ui-btn-ghost" data-action="start_task">
          开始
        </button>
        <button class="ui-btn ui-btn-ghost" data-action="schedule_task">
          稍后
        </button>
      </div>
    </div>
  </div>
</div>
```

##### 2.2.3 任务完成反馈弹层
```html
<!-- 完成任务后的即时反馈 -->
<div class="reward-toast" id="reward-toast">
  <div class="reward-toast__content">
    <div class="reward-icon">✨</div>
    <div class="reward-text">
      <span class="reward-title">任务完成！</span>
      <span class="reward-detail">+10 Aura · 连续成长 3 天</span>
    </div>
  </div>
  <div class="reward-toast__progress">
    <div class="progress-bar"></div>
  </div>
</div>
```

### 2.3 Twin 数字孪生展示

#### 新增: 个人画像页

基于 `/api/twin` 数据，创建可视化的个人画像页面。

```
┌─────────────────────────────────────────────────┐
│ 我的数字孪生                                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────┐                               │
│  │   头像区     │   张三                        │
│  │  (五行属性)  │   日主: 甲木 · 身强           │
│  └─────────────┘   成长连击: 7 天 🔥            │
│                                                 │
│  ── L3 维度评分 ──                              │
│                                                 │
│  ┌──────────────────────────────────────┐      │
│  │        事业 ━━━━━━━━━━━━━━ 85        │      │
│  │        财富 ━━━━━━━━━━━━ 72          │      │
│  │        感情 ━━━━━━━━━━━ 68           │      │
│  │        健康 ━━━━━━━━━━━━━ 80         │      │
│  │        人际 ━━━━━━━━━━━━━━━ 88       │      │
│  │        成长 ━━━━━━━━━━━━━━ 82        │      │
│  └──────────────────────────────────────┘      │
│                                                 │
│  ── 近期变化 ──                                 │
│  • 事业维度 +5 (完成了3个工作任务)              │
│  • 健康维度 +3 (坚持运动计划5天)                │
│                                                 │
│  [查看完整分析] [分享我的画像]                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 2.4 社交功能入口

#### 新增: 社交 Tab
```
社交 Tab
├─ 好友列表 (GET /api/social/friends)
├─ 能量互送 (POST /api/social/buff)
├─ 合盘分析 (POST /api/social/compatibility)
└─ 祈福链 (GET/POST /api/social/chain/*)
```

#### 好友卡片设计
```html
<div class="friend-card">
  <div class="friend-avatar">
    <img src="..." alt="好友头像" />
    <span class="friend-element fire">火</span>
  </div>
  <div class="friend-info">
    <span class="friend-name">李四</span>
    <span class="friend-relation">互补关系 · 合盘 85分</span>
  </div>
  <div class="friend-actions">
    <button class="ui-btn ui-btn-ghost" data-action="send_buff">
      送能量 ⚡
    </button>
    <button class="ui-btn ui-btn-ghost" data-action="view_compatibility">
      查看合盘
    </button>
  </div>
</div>
```

---

## 3. 新增交互流程

### 3.1 首次用户引导流程

```
1. 登录/注册
   ↓
2. Profile 设置引导
   ├─ 基本信息 (姓名、性别)
   ├─ 出生信息 (日期、时间、地点)
   └─ 偏好设置 (风格、推送)
   ↓
3. 八字计算 & Twin 初始化
   ↓
4. 欢迎对话 (展示核心命理特点)
   ↓
5. 首个任务推荐
```

#### 引导卡片组件
```html
<div class="onboarding-card">
  <div class="onboarding-card__step">
    <span class="step-number">1</span>
    <span class="step-total">/ 3</span>
  </div>
  <h3>设置你的出生信息</h3>
  <p class="onboarding-card__desc">
    精确的出生时间能让我为你提供更准确的命理分析
  </p>
  <form class="onboarding-form" id="birth-form">
    <div class="ui-grid-2">
      <label>出生日期
        <input type="date" name="birthday" required />
      </label>
      <label>出生时间
        <input type="time" name="birthtime" step="1" required />
      </label>
    </div>
    <label>出生地点
      <input type="text" name="location" placeholder="城市名称" />
    </label>
    <div class="onboarding-actions">
      <button type="button" class="ui-btn ui-btn-ghost" id="skip-step">
        稍后设置
      </button>
      <button type="submit" class="ui-btn ui-btn-primary">
        下一步
      </button>
    </div>
  </form>
</div>
```

### 3.2 情绪打卡流程优化

#### 现状
- 简单表单: 情绪 + 强度 + 备注

#### 优化: 情绪选择器可视化

```html
<div class="mood-picker">
  <h4>此刻的心情是？</h4>

  <!-- 情绪图标选择 -->
  <div class="mood-icons">
    <button class="mood-icon" data-mood="happy" data-intensity="8">
      😊 开心
    </button>
    <button class="mood-icon" data-mood="calm" data-intensity="6">
      😌 平静
    </button>
    <button class="mood-icon" data-mood="anxious" data-intensity="4">
      😰 焦虑
    </button>
    <button class="mood-icon" data-mood="sad" data-intensity="3">
      😢 低落
    </button>
    <button class="mood-icon" data-mood="angry" data-intensity="2">
      😤 烦躁
    </button>
  </div>

  <!-- 强度滑块 -->
  <div class="mood-intensity">
    <label>强度</label>
    <input type="range" min="1" max="10" value="5" />
    <span class="intensity-value">5</span>
  </div>

  <!-- 快速备注 -->
  <div class="mood-note">
    <input type="text" placeholder="发生了什么？(可选)" />
  </div>

  <button class="ui-btn ui-btn-primary" id="submit-mood">
    记录心情
  </button>
</div>
```

### 3.3 JITAI 主动干预展示

当 `/api/jitai/interventions` 返回待处理干预时，以非侵入方式展示：

```html
<!-- 干预提示卡片 - 出现在对话区顶部 -->
<div class="jitai-intervention" data-intervention-id="123">
  <div class="intervention-content">
    <span class="intervention-icon">💡</span>
    <div class="intervention-text">
      <span class="intervention-title">适合做决策的时机</span>
      <span class="intervention-body">
        当前时辰对你的思维清晰度有利，适合处理重要决策
      </span>
    </div>
  </div>
  <div class="intervention-actions">
    <button class="ui-btn ui-btn-ghost" data-action="click">
      查看建议
    </button>
    <button class="intervention-dismiss" data-action="dismiss">
      ✕
    </button>
  </div>
</div>
```

### 3.4 成长计划进度展示

```html
<div class="plan-progress">
  <div class="plan-header">
    <h4>21天正念计划</h4>
    <span class="plan-status">进行中 · Day 7/21</span>
  </div>

  <!-- 进度可视化 -->
  <div class="plan-calendar">
    <div class="day completed">1</div>
    <div class="day completed">2</div>
    <div class="day completed">3</div>
    <div class="day completed">4</div>
    <div class="day completed">5</div>
    <div class="day completed">6</div>
    <div class="day current">7</div>
    <div class="day">8</div>
    <!-- ... -->
  </div>

  <!-- 今日任务 -->
  <div class="plan-today">
    <h5>今日: 身体扫描冥想</h5>
    <p class="plan-instruction">
      找一个安静的地方坐下，闭上眼睛，从脚趾开始，
      逐渐将注意力移动到身体的每个部位...
    </p>
    <div class="plan-actions">
      <button class="ui-btn ui-btn-primary" id="plan-done">
        ✓ 我完成了
      </button>
    </div>
  </div>
</div>
```

---

## 4. API 集成优化

### 4.1 数据预加载策略

```javascript
// 页面加载时并行请求
async function initPage() {
  const [
    profile,
    today,
    actions,
    plan,
    interventions,
    twin,
  ] = await Promise.all([
    apiJson("/api/user/profile"),
    apiJson("/api/bento/today"),
    apiJson("/api/bento/actions"),
    apiJson("/api/plan/active"),
    apiJson("/api/jitai/interventions"),
    apiJson("/api/twin"),
  ]);

  // 渲染各区域
  renderProfile(profile);
  renderToday(today);
  renderActions(actions);
  renderPlan(plan);
  renderInterventions(interventions);
  renderTwinSummary(twin);
}
```

### 4.2 实时更新机制

```javascript
// WebSocket 或 Polling 策略
const UPDATE_INTERVAL = 60 * 1000; // 1分钟

// 推送消息轮询
async function pollUpdates() {
  try {
    // 获取推送消息
    const pushData = await apiJson("/api/push/inbox?limit=3");
    handlePushEvents(pushData.events);

    // 获取最新干预
    const jitaiData = await apiJson("/api/jitai/interventions");
    handleInterventions(jitaiData.interventions);
  } catch (e) {
    console.warn("Poll failed:", e);
  }
}

setInterval(pollUpdates, UPDATE_INTERVAL);
```

### 4.3 任务完成反馈增强

```javascript
async function completeTask(taskId) {
  const result = await apiJson("/api/bento/commitment/done", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...csrfHeaders() },
    body: JSON.stringify({ task_id: taskId }),
  });

  // 展示奖励反馈
  showRewardToast({
    auraEarned: result.rewards.aura_earned,
    newStreak: result.rewards.new_streak,
  });

  // 刷新相关数据
  await Promise.all([
    loadActions(),
    loadTwin(), // 刷新 Twin 显示最新维度变化
  ]);
}

function showRewardToast({ auraEarned, newStreak }) {
  const toast = document.getElementById("reward-toast");
  toast.querySelector(".reward-detail").textContent =
    `+${auraEarned} Aura · 连续成长 ${newStreak} 天`;
  toast.classList.add("show");

  setTimeout(() => {
    toast.classList.remove("show");
  }, 3000);
}
```

---

## 5. 移动端适配优化

### 5.1 Tab 切换交互
保持现有的 Chat / Workbench Tab 切换模式，但优化以下细节：

```css
/* 移动端底部导航优化 */
@media (max-width: 1080px) {
  .ui-mobile-tabs {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 8px 16px env(safe-area-inset-bottom);
    background: var(--surface);
    border-top: 1px solid var(--line);
    z-index: 30;
  }

  .ui-input {
    bottom: calc(60px + env(safe-area-inset-bottom));
  }
}
```

### 5.2 快捷操作浮层

在移动端，将常用操作以浮动按钮形式展示：

```html
<!-- 移动端快捷操作 -->
<div class="mobile-fab-group" id="mobile-fabs">
  <button class="mobile-fab mobile-fab--main" id="fab-main">
    <span class="fab-icon">+</span>
  </button>
  <div class="mobile-fab-menu">
    <button class="mobile-fab mobile-fab--item" data-action="checkin">
      😊 情绪打卡
    </button>
    <button class="mobile-fab mobile-fab--item" data-action="today">
      📅 今日指引
    </button>
    <button class="mobile-fab mobile-fab--item" data-action="plan">
      🎯 成长计划
    </button>
  </div>
</div>
```

---

## 6. 性能优化

### 6.1 A2UI 渲染优化
```javascript
// 使用 DocumentFragment 批量渲染
function renderA2UI(a2ui) {
  const fragment = document.createDocumentFragment();
  const comps = a2ui?.ui_components || [];

  for (const comp of comps) {
    const el = createComponent(comp);
    if (el) fragment.appendChild(el);
  }

  return fragment;
}
```

### 6.2 列表虚拟化
对于长列表（如会话历史），使用虚拟滚动：

```javascript
// 简单的虚拟滚动实现
class VirtualList {
  constructor(container, itemHeight, renderItem) {
    this.container = container;
    this.itemHeight = itemHeight;
    this.renderItem = renderItem;
    this.data = [];
    this.visibleStart = 0;
    this.visibleEnd = 0;

    container.addEventListener("scroll", this.onScroll.bind(this));
  }

  setData(data) {
    this.data = data;
    this.render();
  }

  onScroll() {
    requestAnimationFrame(() => this.render());
  }

  render() {
    const scrollTop = this.container.scrollTop;
    const viewportHeight = this.container.clientHeight;

    this.visibleStart = Math.floor(scrollTop / this.itemHeight);
    this.visibleEnd = Math.min(
      this.data.length,
      Math.ceil((scrollTop + viewportHeight) / this.itemHeight) + 1
    );

    // 只渲染可见项
    // ...
  }
}
```

---

## 7. 实现优先级

### Phase 1: 核心交互优化 (1周)
- [ ] 快捷提问入口
- [ ] 任务完成奖励反馈
- [ ] 情绪打卡可视化
- [ ] JITAI 干预展示

### Phase 2: 功能增强 (2周)
- [ ] Twin 数字孪生可视化
- [ ] 成长计划进度展示
- [ ] 引导流程优化

### Phase 3: 社交功能 (2周)
- [ ] 好友列表
- [ ] 能量互送
- [ ] 合盘分析入口

### Phase 4: 体验打磨 (持续)
- [ ] 性能优化
- [ ] 动画细节
- [ ] 错误处理

---

## 8. 附录: A2UI 组件清单

基于现有 `renderA2UI` 函数，支持的组件类型：

| 组件类型 | 用途 | 数据格式 |
|---------|------|---------|
| `markdown_text` | 富文本内容 | `string` |
| `plain_text` | 纯文本 | `string` |
| `action_buttons` | 操作按钮组 | `[{label, action}]` |
| `quick_replies` | 快捷回复 | `[string]` 或 `[{text}]` |
| `stat_card` | 数据统计卡片 | `[{label, value, unit?, trend?}]` |
| `progress_bar` | 进度条 | `{current, total, label?}` |
| `list_view` | 列表视图 | `[{title, subtitle?, icon?, action?}]` |
| `key_value` | 键值对展示 | `[{key, value}]` |
| `divider` | 分隔线 | 无 |
| `spacer` | 间距 | `{height}` |

---

*文档版本: v1.0*
*更新日期: 2024-12-30*
*作者: Claude Code*
