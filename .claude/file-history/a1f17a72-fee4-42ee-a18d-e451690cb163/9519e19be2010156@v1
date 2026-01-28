# Fortune AI v3 优化实现计划

## 一、需求分析总结

### 核心改动
1. **Login页面重构** - 添加八字/紫微/星座Tab模式 + 3个验证点 + 注册/登录同时显示
2. **深度八字报告** - 优化现有GLM报告流水线
3. **对话系统** - 已有完整实现，微调A2UI输出
4. **海报生成** - 新增，调用gemini_create_job图片模型
5. **人生K线** - 增强现有trends-tab，添加K线可视化
6. **合并状态/趋势Tab** - 整合status-tab和trends-tab

### 优先级排序
```
P0: Login页面 (入口) → 深度八字报告 (核心价值)
P1: 对话系统优化 → 海报生成 (社交裂变)
P2: K线系统 → 合并Tab (留存)
```

---

## 二、Login页面重构设计

### 2.1 当前结构 (auth.html)
```
┌─────────────────────────────────────────────────────────┐
│ Fortune AI              [已有账号？登录]                 │
├──────────────────────────┬──────────────────────────────┤
│ 左栏: 出生信息表单        │ 右栏: 八字预览卡片            │
│ - 性别/时区              │ - 四柱展示                   │
│ - 出生日期/时间           │ - 五行分布条                 │
│ - 出生地点/经纬度         │ - 日主/强弱/有利             │
│ [生成预览] [保存进入]     │                             │
└──────────────────────────┴──────────────────────────────┘
         ↓ 点击"保存"
┌─────────────────────────────────────────────────────────┐
│ Modal弹窗: [注册保存] [登录] Tab切换                     │
└─────────────────────────────────────────────────────────┘
```

### 2.2 新设计方案
```
┌─────────────────────────────────────────────────────────┐
│ Fortune AI    [八字|紫微|星座] Tab    [登录] [注册]      │
├──────────────────────────┬──────────────────────────────┤
│ 左栏: 输入 + 验证点       │ 右栏: 专业图示 + 预览        │
│                          │                             │
│ ┌──────────────────────┐ │ ┌────────────────────────┐  │
│ │ Tab对应专业图示(SVG)  │ │ │ [当前模式专业命盘图]    │  │
│ └──────────────────────┘ │ │  八字:四柱+五行雷达     │  │
│                          │ │  紫微:命盘12宫          │  │
│ 出生信息输入区            │ │  星座:本命盘轮          │  │
│ - 日期/时间/地点(默认北京) │ └────────────────────────┘  │
│                          │                             │
│ ┌──────────────────────┐ │ ┌────────────────────────┐  │
│ │ 3个「那就是我」验证点  │ │ │ 预览数据卡片           │  │
│ │ ✓ "你是不是经常..."   │ │ │ - 核心特质             │  │
│ │ ✓ "你在人际关系中..." │ │ │ - 优势/盲区            │  │
│ │ ✓ "你面对压力时..."   │ │ │ - 本周运势             │  │
│ └──────────────────────┘ │ └────────────────────────┘  │
│                          │                             │
│ ┌──────────────────────┐ │                             │
│ │ 注册/登录区 (内嵌)     │ │                             │
│ │ 邮箱 [____] 密码[___] │ │                             │
│ │ [注册并保存] [直接登录]│ │                             │
│ └──────────────────────┘ │                             │
└──────────────────────────┴──────────────────────────────┘
```

### 2.3 关键改动点

| 文件 | 改动内容 |
|------|----------|
| `api/templates/auth.html` | 1. 顶部添加八字/紫微/星座 Tab<br>2. 左栏添加验证点卡片<br>3. 左栏底部内嵌注册/登录表单(非弹窗)<br>4. 右栏添加专业命盘图示区 |
| `api/static/auth.js` | 1. Tab切换逻辑<br>2. 验证点生成API调用<br>3. 表单提交逻辑调整 |
| `api/auth_routes.py` | 1. 新增 `/api/auth/validation-points` 生成3个验证点<br>2. 扩展preview支持紫微/星座 |
| `services/auth_service.py` | 验证点生成逻辑 (基于L0 facts) |

### 2.4 专业图示设计 (SVG占位)

```html
<!-- 八字命盘图示 -->
<svg class="chart-bazi">
  <!-- 四柱 + 五行雷达 -->
</svg>

<!-- 紫微命盘图示 -->
<svg class="chart-ziwei">
  <!-- 12宫格布局 -->
</svg>

<!-- 星座本命盘图示 -->
<svg class="chart-astro">
  <!-- 12星座轮 + 行星位置 -->
</svg>
```

---

## 三、深度八字报告优化

### 3.1 当前实现
- 路径: `POST /api/report/bazi/deep/submit`
- 服务: `services/bazi_report_service.py`
- 输出: A2UI格式 + Markdown

### 3.2 优化点
1. **报告结构** - 对齐modul_core_v3.md的6章结构
2. **可追溯性** - 添加facts_hash/rule_ids/kb_refs
3. **处方输出** - 确保≤3条可执行动作 + 承诺邀请
4. **风险边界** - 负面信息必须附带"你可以做什么"

### 3.3 改动文件
| 文件 | 改动 |
|------|------|
| `services/bazi_report_service.py` | 1. `_build_report_prompt()` 增加6章结构指引<br>2. 输出添加facts_hash字段<br>3. 处方提取优化 |

---

## 四、海报生成系统 (新增)

### 4.1 架构设计
```
用户触发海报生成
     │
     ▼
POST /api/poster/generate
     │
     ├─ 1. 读取用户Profile + 当前上下文
     ├─ 2. 生成吐槽文案 (GLM)
     ├─ 3. 调用 gemini_create_job (图片模型)
     │      - model: gemini-2.0-flash-exp (支持图片)
     │      - prompt: 海报设计指令 + 文案 + 用户数据
     ├─ 4. 返回job_id，前端轮询
     └─ 5. 完成后返回image_url
```

### 4.2 新增文件
| 文件 | 内容 |
|------|------|
| `services/poster_service.py` | 海报生成服务<br>- `generate_poster(user_id, type, context)`<br>- 调用gemini_create_job |
| `api/poster_routes.py` | 海报API路由<br>- `POST /api/poster/generate`<br>- `GET /api/poster/{job_id}` |

### 4.3 海报类型
```python
PosterType = Literal[
    'personality',   # 性格吐槽
    'mood',          # 情绪吐槽
    'fortune',       # 运势吐槽
    'pairing',       # 合盘吐槽
    'achievement',   # 成就打卡
    'help'           # 求助呼唤
]
```

---

## 五、人生K线系统

### 5.1 当前状态
- `web-app/src/components/dashboard/tabs/trends-tab.tsx` - 线性图表
- `api/dashboard_routes.py` - `/api/dashboard/trends` 返回历史分数

### 5.2 增强设计
```
现有线图 → K线蜡烛图
         │
         ├─ 每日OHLC: open(早), high(峰值), low(谷值), close(晚)
         ├─ 颜色: 绿涨/红跌/橙波动
         ├─ 悬停: 显示当日事件 + drivers
         └─ 时间尺度: 日/周/月切换
```

### 5.3 改动文件
| 文件 | 改动 |
|------|------|
| `api/dashboard_routes.py` | `/api/dashboard/kline` 新端点，返回OHLC数据 |
| `services/soul_os.py` | `calculate_daily_kline()` 计算每日开高低收 |
| `web-app/.../trends-tab.tsx` | 替换为K线蜡烛图组件 |

---

## 六、合并状态/趋势Tab

### 6.1 当前结构
```
Dashboard
├── status-tab.tsx  (L0/L1/StateScore)
└── trends-tab.tsx  (历史趋势图)
```

### 6.2 合并方案: 状态为主 + 趋势折叠区
```
新 Dashboard Tab
├── 顶部: StateScore环形图 + 三信号条
├── 中部: PERMA雷达图 (可点击展开)
├── 底部: K线趋势图 (默认折叠，可展开)
└── 事件时间线 (横向滚动)
```

### 6.3 改动文件
| 文件 | 改动 |
|------|------|
| `web-app/.../dashboard/` | 合并status-tab和trends-tab为unified-tab |
| `api/dashboard_routes.py` | 优化overview端点，包含所有必要数据 |

---

## 七、实施顺序

### Phase 1: Login页面 (P0)
```
1. auth.html 添加Tab结构
2. auth.js Tab切换逻辑
3. auth_routes.py 验证点API
4. SVG命盘图示占位
5. 内嵌注册/登录表单
```

### Phase 2: 深度报告 (P0)
```
1. bazi_report_service.py prompt优化
2. 6章结构输出
3. facts_hash/处方/风险边界
```

### Phase 3: 海报生成 (P1)
```
1. poster_service.py 新建
2. poster_routes.py 新建
3. gemini_create_job 图片模型调用
4. 前端海报预览组件
```

### Phase 4: K线系统 (P2)
```
1. dashboard_routes.py kline端点
2. soul_os.py OHLC计算
3. 前端K线组件
```

### Phase 5: Tab合并 (P2)
```
1. 合并status-tab + trends-tab
2. 优化数据加载
```

---

## 八、关键文件清单

### 需要修改
- `/api/templates/auth.html` - Login页面重构
- `/api/static/auth.js` - Login逻辑
- `/api/auth_routes.py` - 验证点API
- `/services/bazi_report_service.py` - 报告优化
- `/api/dashboard_routes.py` - K线端点
- `/services/soul_os.py` - OHLC计算
- `/web-app/src/components/dashboard/tabs/` - 前端组件

### 需要新增
- `/services/poster_service.py` - 海报服务
- `/api/poster_routes.py` - 海报API
- `/web-app/src/components/kline/` - K线组件

---

## 九、modul_core_v3.md 文档更新

根据以上实现计划，需要同步更新v3文档：
1. 添加Login页面流程图
2. 细化海报生成技术方案
3. 补充K线OHLC数据结构
4. 更新API端点清单
