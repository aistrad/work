# Onboarding 表单详细设计 v10.0

> **设计风格**: 「暖阳神秘」+ Linear 精致风格
> **核心理念**: 3个字段 + 1个按钮 = 最低门槛
> **更新日期**: 2026-01-17
> **v10.0 更新**: 深色方案 → 暖色方案 (与前端 v7.1 设计系统统一)

---

## 重要说明

### v10.0 核心变更

| 维度 | v9.0 (旧) | v10.0 (新) |
|------|-----------|------------|
| **背景色** | #0A0A0A → #1A1A2E | #FDFCFA → #FAF8F5 (vellum) |
| **文字色** | #FFFFFF | #1A1814 (ink-900) |
| **卡片背景** | rgba(255,255,255,0.05) + blur | vellum-200 (#F5F2ED) + shadow-card |
| **按钮样式** | 白色背景 | 金色渐变 (gold-500 → gold-600) |
| **输入框** | 深色半透明 | vellum-100 背景 + ink-800 文字 |

### 两层表单设计

**1. Hero区基础表单** (Landing Page内嵌):
- 字段: 出生时间(必填) + 出生地点(可选)
- 目的: 降低首次转化摩擦
- 提交后: 跳转到 `/onboarding` 完成完整流程

**2. Onboarding完整流程** (`/onboarding` 路由):
- Step 1: Loading (计算VibeID)
- Step 2: Aha Moment (展示结果)
- Step 3: Conversion (引导付费/注册)
- Step 4: Auth (登录/注册)

### 设计理念

```
Hero表单 (简化入口)
    ↓
  提交
    ↓
Onboarding完整流程 (深度体验)
```

---

## 一、Hero区集成表单 (v10.0 暖色版)

### 1.1 Hero区表单布局 (Landing Page内嵌)

```
┌──────────────────────────────────────────────────────────────┐
│  [Hero Section - Landing Page]                               │
│  [vellum-50 → vellum-100 渐变背景]             🆕 v10.0     │
│                                                              │
│  [四维原型曼陀罗]                                             │
│                                                              │
│  你是谁？ [ink-900]                                          │
│  发现隐藏在时间里的真实自我 [ink-500]                         │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  [vellum-200 背景 + shadow-card]     🆕 v10.0 │         │
│  │                                                │         │
│  │  请输入你的出生时间 [ink-700]                  │         │
│  │                                                │         │
│  │  [1990] 年 [5] 月 [15] 日 [8] 时             │         │
│  │  [vellum-100 输入框 + ink-800 文字]           │         │
│  │                                                │         │
│  │  出生地点（可选）  [__________]  🔍          │         │
│  │                                                │         │
│  │      [开始90秒自我发现之旅 →]                 │         │
│  │      [gold-500 → gold-600 渐变]    🆕 v10.0  │         │
│  │                                                │         │
│  └────────────────────────────────────────────────┘         │
│  [纸质感卡片, 520px宽]                                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**特点**:
- ✅ **极简**: 仅2个字段 (出生时间必填 + 地点可选)
- ✅ **无跳转**: 在Hero区直接填写
- ✅ **低摩擦**: 减少用户决策成本
- ✅ **暖色调**: 与产品体验一致

---

## 二、Onboarding完整流程 (`/onboarding` 路由)

### 2.1 整体流程

```
用户在Hero提交表单
    ↓
跳转到 /onboarding
    ↓
┌─────────────────────┐
│ Step 1: Loading     │  ← 计算VibeID (2-3秒)
│ 动画 + 进度提示     │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Step 2: Aha Moment  │  ← 展示结果
│ 你的原型 + 维度     │
│ 视觉化呈现          │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Step 3: Conversion  │  ← 价值引导
│ 解锁完整报告        │
│ 付费/注册选项       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Step 4: Auth        │  ← 登录/注册
│ 保存结果            │
└─────────────────────┘
```

### 2.2 为什么保留完整流程？

**Hero表单的局限**:
- 空间有限,无法展示完整价值
- 用户还未建立信任
- 无法深度引导转化

**完整流程的优势**:
- ✅ 专注的沉浸式体验
- ✅ 渐进式价值揭示
- ✅ 精心设计的转化漏斗
- ✅ 完整的4步心理引导

---

## 三、组件设计规格 (v10.0 暖色版)

### 3.1 页面容器

```typescript
export const OnboardingPageSpec = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    padding: { mobile: '20px', desktop: '40px' },
    // v10.0: 暖色渐变背景
    background: 'linear-gradient(180deg, var(--vellum-50) 0%, var(--vellum-100) 100%)'
  }
}
```

### 3.2 标题

```typescript
export const TitleSpec = {
  fontSize: { mobile: '32px', desktop: '48px' },
  fontWeight: '200',
  // v10.0: 墨色文字
  color: 'var(--ink-900)',
  lineHeight: 1.3,
  textAlign: 'center',
  marginBottom: { mobile: '40px', desktop: '60px' },
  animation: {
    name: 'fadeIn',
    duration: '0.8s'
  }
}
```

### 3.3 表单卡片 (v10.0 纸质感设计)

```typescript
export const FormCardSpec = {
  width: '100%',
  maxWidth: '600px',
  // v10.0: 纸质感背景 (不再使用磨砂玻璃)
  background: 'var(--vellum-200)',
  // v10.0: 移除 backdropFilter
  // backdropFilter: 'blur(20px)',
  // v10.0: 无边框，用阴影分隔
  border: 'none',
  borderRadius: '24px',
  padding: { mobile: '32px', desktop: '48px' },
  // v10.0: 暖色多层阴影
  boxShadow: `
    0 0 0 1px rgba(122, 107, 90, 0.04),
    0 2px 4px rgba(122, 107, 90, 0.02),
    0 4px 8px rgba(122, 107, 90, 0.03),
    0 8px 16px rgba(122, 107, 90, 0.04)
  `
}
```

### 3.4 输入字段 (v10.0 暖色版)

#### 出生时间（必填）

```typescript
export const BirthdayInputSpec = {
  layout: {
    display: 'flex',
    gap: '12px',
    marginBottom: '32px'
  },

  // 年份输入 (v10.0)
  yearInput: {
    flex: 1,
    fontSize: '18px',
    fontWeight: '500',
    textAlign: 'center',
    padding: '12px',
    // v10.0: 暖色背景
    background: 'var(--vellum-100)',
    border: 'none',
    borderRadius: '12px',
    // v10.0: 墨色文字
    color: 'var(--ink-800)',
    placeholder: '1990',
    // v10.0: 暖色占位符
    placeholderColor: 'var(--ink-400)',
    maxLength: 4,
    inputMode: 'numeric',
    // v10.0: 聚焦状态
    focus: {
      outline: 'none',
      boxShadow: '0 0 0 2px var(--gold-400)'
    }
  },

  // 月/日/时输入
  smallInput: {
    width: '64px',
    // ... 其他样式同 yearInput
  },

  // 后缀标签 (年/月/日/时)
  suffix: {
    fontSize: '12px',
    // v10.0: 暖色次要文字
    color: 'var(--ink-500)',
    textAlign: 'center',
    marginTop: '4px'
  }
}
```

#### 出生地点（可选）

```typescript
export const LocationInputSpec = {
  container: {
    marginBottom: '32px'
  },

  label: {
    fontSize: '14px',
    fontWeight: '500',
    // v10.0: 暖色标签
    color: 'var(--ink-700)',
    marginBottom: '12px'
  },

  input: {
    width: '100%',
    fontSize: '16px',
    padding: '14px 16px',
    // v10.0: 暖色输入框
    background: 'var(--vellum-100)',
    border: 'none',
    borderRadius: '12px',
    color: 'var(--ink-800)',
    placeholder: '北京',
    icon: '🔍',
    focus: {
      boxShadow: '0 0 0 2px var(--gold-400)'
    }
  },

  hint: {
    fontSize: '12px',
    color: 'var(--ink-500)',
    marginTop: '8px'
  }
}
```

#### 自我介绍（可选）

```typescript
export const IntroInputSpec = {
  input: {
    width: '100%',
    fontSize: '16px',
    padding: '14px 16px',
    // v10.0: 暖色输入框
    background: 'var(--vellum-100)',
    border: 'none',
    borderRadius: '12px',
    color: 'var(--ink-800)',
    placeholder: '一个追求美的产品设计师',
    maxLength: 50,
    focus: {
      boxShadow: '0 0 0 2px var(--gold-400)'
    }
  },

  hint: {
    fontSize: '12px',
    color: 'var(--ink-500)',
    marginTop: '8px'
  }
}
```

### 3.5 提交按钮 (v10.0 金色渐变)

```typescript
export const SubmitButtonSpec = {
  width: '100%',
  fontSize: '18px',
  fontWeight: '500',
  padding: '16px 0',
  borderRadius: '16px',
  border: 'none',
  cursor: 'pointer',
  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',

  // v10.0: 启用状态 - 金色渐变
  enabled: {
    background: 'linear-gradient(135deg, var(--gold-500) 0%, var(--gold-600) 100%)',
    color: '#FFFFFF',
    boxShadow: '0 2px 8px rgba(193, 154, 91, 0.3)',
    hover: {
      transform: 'translateY(-2px)',
      boxShadow: '0 4px 16px rgba(193, 154, 91, 0.4)'
    },
    active: {
      transform: 'translateY(0)',
      boxShadow: '0 2px 8px rgba(193, 154, 91, 0.3)'
    }
  },

  // v10.0: 禁用状态 - 暖色灰
  disabled: {
    background: 'var(--vellum-400)',
    color: 'var(--ink-400)',
    cursor: 'not-allowed',
    boxShadow: 'none'
  }
}
```

---

## 四、v10.0 CSS 变量参考

```css
/* v10.0 暖色系统变量 */
:root {
  /* 羊皮纸色系 (背景) */
  --vellum-50: #FDFCFA;
  --vellum-100: #FAF8F5;
  --vellum-200: #F5F2ED;
  --vellum-300: #EDE9E2;
  --vellum-400: #E2DDD4;
  --vellum-500: #D4CEC3;

  /* 墨色系 (文字) */
  --ink-400: #9A958C;
  --ink-500: #7A756B;
  --ink-600: #5E5A52;
  --ink-700: #433F39;
  --ink-800: #2D2A26;
  --ink-900: #1A1814;

  /* 古金色系 (强调) */
  --gold-400: #D9B577;
  --gold-500: #C19A5B;
  --gold-600: #A07D50;

  /* 暖色阴影 */
  --shadow-card:
    0 0 0 1px rgba(122, 107, 90, 0.04),
    0 2px 4px rgba(122, 107, 90, 0.02),
    0 4px 8px rgba(122, 107, 90, 0.03),
    0 8px 16px rgba(122, 107, 90, 0.04);
}
```

---

## 五、完整代码实现 (v10.0 暖色版)

```css
/* apps/web/src/app/onboarding/onboarding.css - v10.0 暖色版 */

.onboarding-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 40px 20px;
  /* v10.0: 暖色渐变背景 */
  background: linear-gradient(180deg, var(--vellum-50) 0%, var(--vellum-100) 100%);
  position: relative;
}

/* 标题 */
.onboarding-title {
  text-align: center;
  margin-bottom: 60px;
}

.onboarding-title h1,
.onboarding-title h2 {
  font-size: 48px;
  font-weight: 200;
  /* v10.0: 墨色文字 */
  color: var(--ink-900);
  line-height: 1.3;
  margin: 0;
}

@media (max-width: 768px) {
  .onboarding-title h1,
  .onboarding-title h2 {
    font-size: 32px;
  }
}

/* 表单卡片 - v10.0 纸质感设计 */
.form-card {
  width: 100%;
  max-width: 600px;
  /* v10.0: 纸质感背景 */
  background: var(--vellum-200);
  /* 移除磨砂玻璃效果 */
  border: none;
  border-radius: 24px;
  padding: 48px;
  /* v10.0: 暖色多层阴影 */
  box-shadow: var(--shadow-card);
}

@media (max-width: 768px) {
  .form-card {
    padding: 32px 24px;
  }
}

/* 表单字段 */
.form-field {
  margin-bottom: 32px;
}

.field-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  /* v10.0: 暖色标签 */
  color: var(--ink-700);
  margin-bottom: 12px;
}

.required {
  color: var(--element-fire);
}

/* 生日输入组 */
.birthday-inputs {
  display: flex;
  gap: 12px;
}

.input-wrapper {
  flex: 1;
  min-width: 0;
}

.input-wrapper:first-child {
  flex: 2;
}

/* 输入框 - v10.0 暖色版 */
.input-field {
  width: 100%;
  font-size: 18px;
  font-weight: 500;
  text-align: center;
  padding: 12px;
  /* v10.0: 暖色背景 */
  background: var(--vellum-100);
  border: none;
  border-radius: 12px;
  /* v10.0: 墨色文字 */
  color: var(--ink-800);
  transition: all 0.2s ease;
}

.input-field::placeholder {
  /* v10.0: 暖色占位符 */
  color: var(--ink-400);
}

.input-field:focus {
  outline: none;
  /* v10.0: 金色聚焦边框 */
  box-shadow: 0 0 0 2px var(--gold-400);
}

/* 小输入框 */
.small-input {
  width: 64px;
}

/* 输入后缀 */
.input-suffix {
  display: block;
  font-size: 12px;
  /* v10.0: 暖色次要文字 */
  color: var(--ink-500);
  text-align: center;
  margin-top: 4px;
}

/* 带图标的输入框 */
.input-with-icon {
  position: relative;
}

.input-icon {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
}

/* 字段提示 */
.field-hint {
  font-size: 12px;
  /* v10.0: 暖色提示文字 */
  color: var(--ink-500);
  margin-top: 8px;
}

/* 分隔线 - v10.0 */
.divider {
  height: 1px;
  /* v10.0: 暖色分隔线 */
  background: var(--vellum-400);
  margin: 32px 0;
}

/* 提交按钮 - v10.0 金色渐变 */
.submit-button {
  width: 100%;
  font-size: 18px;
  font-weight: 500;
  padding: 16px 0;
  border-radius: 16px;
  border: none;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.submit-button.enabled {
  /* v10.0: 金色渐变 */
  background: linear-gradient(135deg, var(--gold-500) 0%, var(--gold-600) 100%);
  color: #FFFFFF;
  box-shadow: 0 2px 8px rgba(193, 154, 91, 0.3);
}

.submit-button.enabled:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(193, 154, 91, 0.4);
}

.submit-button.disabled {
  /* v10.0: 暖色禁用状态 */
  background: var(--vellum-400);
  color: var(--ink-400);
  cursor: not-allowed;
}

/* 隐私提示 */
.privacy-hint {
  font-size: 12px;
  /* v10.0: 暖色次要文字 */
  color: var(--ink-400);
  text-align: center;
  margin-top: 16px;
}

/* 返回按钮 */
.back-button {
  margin-top: 32px;
  font-size: 14px;
  /* v10.0: 暖色链接 */
  color: var(--ink-500);
  background: none;
  border: none;
  cursor: pointer;
  transition: color 0.2s ease;
}

.back-button:hover {
  color: var(--ink-800);
}
```

---

## 六、交互细节

### 6.1 输入验证

```typescript
// 实时验证逻辑
const validateBirthday = (year: string, month: string, day: string) => {
  const y = parseInt(year)
  const m = parseInt(month)
  const d = parseInt(day)

  // 年份范围: 1900-2100
  if (year.length !== 4 || y < 1900 || y > 2100) return false

  // 月份范围: 1-12
  if (m < 1 || m > 12) return false

  // 日期范围: 1-31 (简化版,不考虑大小月)
  if (d < 1 || d > 31) return false

  return true
}
```

### 6.2 自动聚焦

```typescript
// 输入完成后自动聚焦下一个字段
const handleYearChange = (value: string) => {
  setYear(value)
  if (value.length === 4) {
    monthRef.current?.focus()
  }
}
```

### 6.3 回车提交

```typescript
const handleKeyDown = (e: React.KeyboardEvent) => {
  if (e.key === 'Enter' && isValid) {
    handleSubmit()
  }
}
```

---

## 七、v10.0 关键变更总结

| 元素 | v9.0 (深色) | v10.0 (暖色) |
|------|-------------|--------------|
| 页面背景 | #0A0A0A → #1A1A2E | vellum-50 → vellum-100 |
| 标题颜色 | #FFFFFF | ink-900 |
| 卡片背景 | rgba(255,255,255,0.05) + blur | vellum-200 + shadow-card |
| 输入框背景 | rgba(255,255,255,0.05) | vellum-100 |
| 输入框文字 | #FFFFFF | ink-800 |
| 输入框聚焦 | border 变亮 | gold-400 边框阴影 |
| 按钮启用 | 白色背景 | gold-500→gold-600 渐变 |
| 按钮禁用 | rgba(255,255,255,0.1) | vellum-400 |
| 分隔线 | rgba(255,255,255,0.1) | vellum-400 |

---

**文档结束**
