# VibeLife 系统测试方案 v1.0

> **版本**: v1.0
> **日期**: 2026-01-09
> **基于文档**: vibelife spec v3.0.md, user-flow-design-v2.1.md, core-algo-review.md
> **测试入口**: http://106.37.170.238:8232/test

---

## 一、测试原则

1. **不改变现有系统设计** - 测试页面仅作为 API 调用入口
2. **不改变生产配置** - 通过服务端代理调用，与生产环境一致
3. **真实运行** - 所有 API 调用真实执行后端代码
4. **手工输入数据** - 支持自定义测试数据

---

## 二、核心流程测试 (9 个流程)

基于 `core-algo-review.md` 定义的 9 个核心流程：

| # | 流程名称 | 测试覆盖 |
|---|---------|---------|
| 1 | Context 构建 | 场景 5 |
| 2 | 深度报告生成 | 场景 4 |
| 3 | RAG 知识库检索 | 场景 5 |
| 4 | AI 访谈 | 场景 3 |
| 5 | 智能信息采集 | 场景 6 |
| 6 | Identity Prism | 场景 4 |
| 7 | 对话流式响应 | 场景 5 |
| 8 | 用户 Profile 累积 | 场景 5 |
| 9 | 关系模拟器/人生K线 | 场景 7, 8 |

---

## 三、测试场景详细设计

### 场景 1: 系统健康检查

**目的**: 验证系统基础设施正常运行

**测试步骤**:
1. 打开测试页面 `http://106.37.170.238:8232/test`
2. 点击 **系统健康** 分类下的按钮

| 测试项 | API 端点 | 预期结果 |
|-------|---------|---------|
| 健康检查 | GET /health | `{"status":"ok","database":"ok"}` |
| 存活探针 | GET /health/live | `{"status":"alive"}` |
| 就绪探针 | GET /health/ready | `{"status":"ready","database":"ok"}` |

**验证点**:
- [ ] API 响应时间 < 500ms
- [ ] 数据库连接正常
- [ ] 服务版本号正确

---

### 场景 2: 新用户 Onboarding 流程

**目的**: 验证新用户首次使用的完整流程

**对应设计**: `user-flow-design-v2.1.md` Stage 1-6

**测试数据**:
```
出生日期: 1990-05-15
出生时间: 10:30
性别: male
出生地点: Beijing, China
经度: 116.4074
纬度: 39.9042
```

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 人格类型列表 | GET /onboarding/personas | 返回 3 个人格 (warm/sharp/wise) |
| 2 | 计算八字 | POST /onboarding/calculate-bazi | 返回四柱、日主、五行 |
| 3 | 生成未来信 | POST /onboarding/generate-letter | 返回个性化信件内容 |
| 4 | 每日问候 | GET /onboarding/daily-greeting | 返回今日问候语 |
| 5 | 今日运势 | GET /onboarding/today-fortune | 返回今日运势 |

**验证点**:
- [ ] 人格类型包含: 暖心向导(warm)、犀利挚友(sharp)、智慧导师(wise)
- [ ] 八字计算返回完整四柱 (年柱/月柱/日柱/时柱)
- [ ] 未来信内容融合命盘特质和人格风格
- [ ] 每日问候包含节气/天象信息

---

### 场景 3: 八字命盘分析

**目的**: 验证八字计算和解读功能

**对应设计**: `vibelife spec v3.0.md` Section 2.2.1

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 八字命盘 | POST /bazi/chart | 返回完整命盘数据 |

**验证点**:
- [ ] 返回 `four_pillars` (四柱)
  - [ ] year (年柱): stem + branch
  - [ ] month (月柱): stem + branch
  - [ ] day (日柱): stem + branch
  - [ ] hour (时柱): stem + branch
- [ ] 返回 `day_master` (日主)
- [ ] 返回 `five_elements` (五行分布)
- [ ] 返回 `ten_gods` (十神关系)
- [ ] 返回 `lunar_date` (农历日期)

**预期输出示例**:
```json
{
  "success": true,
  "chart": {
    "birth_info": {
      "date": "1990-05-15",
      "time": "10:30",
      "gender": "male",
      "lunar_date": "一九九〇年四月廿一"
    },
    "four_pillars": {
      "year": {"stem": "庚", "branch": "午"},
      "month": {"stem": "辛", "branch": "巳"},
      "day": {"stem": "甲", "branch": "子"},
      "hour": {"stem": "己", "branch": "巳"}
    },
    "day_master": {
      "element": "wood",
      "stem": "甲",
      "description": "甲木日主"
    }
  }
}
```

---

### 场景 4: 星座星盘分析

**目的**: 验证星盘计算和解读功能

**对应设计**: `vibelife spec v3.0.md` Section 2.2.1

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 星盘计算 | POST /zodiac/chart | 返回完整星盘数据 |
| 2 | 行星过境 | POST /zodiac/transit | 返回当前行星过境 |
| 3 | 合盘分析 | POST /zodiac/synastry | 返回两人兼容性分析 |

**验证点**:
- [ ] 星盘计算返回:
  - [ ] sun_sign (太阳星座)
  - [ ] moon_sign (月亮星座)
  - [ ] rising_sign (上升星座)
  - [ ] planets (行星位置)
  - [ ] houses (宫位)
- [ ] 行星过境返回当前天象影响
- [ ] 合盘分析返回兼容性评分和解读

---

### 场景 5: AI 对话咨询

**目的**: 验证对话系统的完整流程

**对应设计**:
- `vibelife spec v3.0.md` Section 2.2.2
- `core-algo-review.md` Section 2.1 (Context 构建)

**测试数据**:
```
聊天消息: "我最近工作压力很大，想知道今年的事业运势如何？"
技能: bazi
```

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 访客聊天 | POST /chat/guest | 返回 AI 回复 |
| 2 | 对话列表 | GET /chat/conversations | 返回历史对话 (需登录) |

**验证点**:
- [ ] 访客聊天返回:
  - [ ] content (AI 回复内容)
  - [ ] is_guest: true
  - [ ] suggestion (引导注册提示)
- [ ] AI 回复融合:
  - [ ] 命盘特质分析
  - [ ] 当前运势解读
  - [ ] 个性化建议
- [ ] 话题分类正确 (CAREER)

**Context 构建验证**:
- [ ] 话题分类: 识别为职业话题
- [ ] Profile 选择: 包含 career, growth_areas
- [ ] 知识库检索: 检索相关八字知识
- [ ] Voice Mode: 应用选定的人格风格

---

### 场景 6: 深度报告生成

**目的**: 验证报告生成的完整流程

**对应设计**:
- `vibelife spec v3.0.md` Section 2.2.1
- `core-algo-review.md` Section 2.2

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 预览报告 | POST /report/preview | 返回报告序言 |
| 2 | 报告列表 | GET /report/list | 返回用户报告 (需登录) |

**验证点**:
- [ ] 预览报告返回:
  - [ ] prologue (卷首语)
  - [ ] preview_sections (预览章节)
- [ ] 卷首语风格:
  - [ ] 第一人称叙事
  - [ ] 10+ 句详细阐述
  - [ ] 融合命盘特质
  - [ ] 不暴露技术细节

**报告章节结构** (八字):
1. 命盘结构
2. 性格解读
3. 运势分析
4. 行动建议

---

### 场景 7: 运势查询

**目的**: 验证运势计算和展示功能

**对应设计**: `vibelife spec v3.0.md` Section 2.2.5

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 人生K线 | POST /fortune/kline | 返回运势曲线数据 |
| 2 | 年度运势 | POST /fortune/year/2025 | 返回 2025 年运势 |
| 3 | 每日问候 | POST /fortune/greeting | 返回今日问候 |
| 4 | 大运周期 | GET /fortune/cycles | 返回大运列表 (需登录) |

**验证点**:
- [ ] 人生K线返回:
  - [ ] data_points (数据点数组)
  - [ ] 每个点包含: year, score, events
  - [ ] 覆盖过去 10 年到未来 10 年
- [ ] 年度运势返回:
  - [ ] overall_score (总体评分)
  - [ ] monthly_trends (月度趋势)
  - [ ] key_events (关键事件)
- [ ] 每日问候包含:
  - [ ] greeting (问候语)
  - [ ] fortune_summary (运势摘要)
  - [ ] lucky_elements (幸运元素)

---

### 场景 8: 关系分析

**目的**: 验证关系模拟器功能

**对应设计**: `vibelife spec v3.0.md` Section 2.2.4

**测试数据**:
```
Person A: 1990-05-15, male
Person B: 1992-08-20, female
```

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 关系分析 | POST /relationship/analyze | 返回兼容性分析 |
| 2 | 创建VibeLink | POST /relationship/vibe-link | 返回邀请链接 (需登录) |

**验证点**:
- [ ] 关系分析返回:
  - [ ] compatibility_score (兼容性评分 0-100)
  - [ ] strengths (优势领域)
  - [ ] challenges (挑战领域)
  - [ ] advice (相处建议)
- [ ] 分析维度:
  - [ ] 性格契合度
  - [ ] 沟通模式
  - [ ] 价值观匹配
  - [ ] 长期发展潜力

---

### 场景 9: 支付与订阅

**目的**: 验证支付相关功能

**对应设计**: `vibelife spec v3.0.md` 定价策略

**测试步骤**:

| 步骤 | 测试项 | API 端点 | 预期结果 |
|-----|-------|---------|---------|
| 1 | 产品列表 | GET /payment/products | 返回可购买产品 |
| 2 | 订阅计划 | GET /billing/plans | 返回订阅计划 |
| 3 | 我的订阅 | GET /billing/subscription/me | 返回当前订阅 (需登录) |

**验证点**:
- [ ] 产品列表包含:
  - [ ] 完整报告 (¥19.9)
  - [ ] 月度订阅 (¥19.9/月)
  - [ ] 年度订阅 (¥159/年)
- [ ] 订阅计划包含:
  - [ ] 免费版功能
  - [ ] Pro 版功能
  - [ ] 价格信息

---

## 四、用户流程端到端测试

### E2E 测试 1: 新用户完整体验

**模拟**: 用户从 Landing Page 到付费转化的完整流程

**步骤**:
1. 输入出生信息 → `POST /onboarding/calculate-bazi`
2. 查看人格选择 → `GET /onboarding/personas`
3. 选择人格后生成信 → `POST /onboarding/generate-letter`
4. 查看今日运势 → `GET /onboarding/today-fortune`
5. 进入对话 → `POST /chat/guest`
6. 查看报告预览 → `POST /report/preview`

**预期转化点**: 用户在看到报告预览后产生付费意愿

---

### E2E 测试 2: 老用户日常使用

**模拟**: 已注册用户的日常使用场景

**步骤** (需登录):
1. 查看每日问候 → `POST /fortune/greeting`
2. 查看今日运势 → `GET /onboarding/today-fortune`
3. 进行对话咨询 → `POST /chat/`
4. 查看人生K线 → `POST /fortune/kline`
5. 查看历史报告 → `GET /report/list`

---

### E2E 测试 3: 关系分析场景

**模拟**: 用户想了解与另一人的关系

**步骤**:
1. 输入双方出生信息
2. 进行关系分析 → `POST /relationship/analyze`
3. 查看星座合盘 → `POST /zodiac/synastry`
4. 进行对话咨询 → `POST /chat/guest` (消息: "我和 TA 合适吗？")

---

## 五、测试检查清单

### 功能完整性

- [ ] 所有 P0 功能可正常调用
- [ ] 返回数据结构符合设计规格
- [ ] 错误处理正确 (401/403/404/500)

### 数据准确性

- [ ] 八字计算结果正确
- [ ] 星盘计算结果正确
- [ ] 运势数据合理

### 用户体验

- [ ] API 响应时间 < 3s (普通请求)
- [ ] AI 生成响应时间 < 10s
- [ ] 错误信息友好

### 安全性

- [ ] 需登录接口正确返回 401
- [ ] 用户数据隔离正确

---

## 六、测试执行记录

| 日期 | 测试场景 | 测试人 | 结果 | 备注 |
|-----|---------|-------|------|------|
| | | | | |

---

## 七、已知问题与待修复

| 问题 | 优先级 | 状态 | 备注 |
|-----|-------|------|------|
| | | | |

---

## 附录: 测试页面使用说明

1. 访问 `http://106.37.170.238:8232/test`
2. 在左侧"测试数据"区域输入出生信息
3. 点击对应功能按钮执行测试
4. 在右侧查看 API 返回结果
5. 绿色 ✓ 表示成功，红色 ✗ 表示失败
