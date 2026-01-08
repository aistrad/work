# VibeLife 30秒 Onboarding 流程原型设计

> **文档版本**: v1.0
> **设计日期**: 2026-01-07
> **设计原则**: Aha Moment 优先，先给价值再要信息
> **核心目标**: 30秒内让用户产生"哇，这东西真准"的顿悟时刻

---

## 1. 设计哲学

### 1.1 传统流程 vs 优化流程对比

```
┌─────────────────────────────────────────────────────────────────┐
│                    传统 Onboarding 流程（问题版）                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   用户进入 → 强制访谈(10个问题) → 等待分析 → 看到结果            │
│       │            │                  │           │             │
│       ▼            ▼                  ▼           ▼             │
│    注册起点    流失率60%+         流失率40%+    Aha Moment      │
│                                                                  │
│   问题：大多数用户在Aha Moment前就流失了                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    优化后 Onboarding 流程                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   用户进入 → 快速选择(1题) → 立即看到命盘 → 今日运势 → 🔥Aha!   │
│       │           │              │            │       │         │
│       ▼           ▼              ▼            ▼       ▼         │
│    注册起点    流失率<10%     流失率<15%   免费价值  顿悟时刻    │
│                                                                  │
│   核心改变：先给价值，建立信任，再要深度信息                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 核心设计原则

| 原则 | 说明 | 实现 |
|------|------|------|
| **30秒法则** | Aha Moment必须在30秒内发生 | 快速问题 + 即时反馈 |
| **价值先行** | 先展示能力，再索取信息 | 命盘预览无需访谈 |
| **渐进式披露** | 信息逐步交换，降低门槛 | 先3题快速，后10题深度 |
| **视觉冲击** | 第一眼必须"哇" | 专业命盘+动态效果 |
| **免费价值明确** | 免费用户也感到物超所值 | 今日运势+轻度解读 |
| **付费触发自然** | 当用户想要更多时才付费 | 主动请求深度分析 |

---

## 2. 秒级流程详解

### 2.1 完整30秒流程时间轴

```
时间轴      用户操作                    系统响应                  设计意图
─────────────────────────────────────────────────────────────────────
 0s        点击"开始对话"               跳转到快速选择页面          降低门槛
  │
 3s        选择今日关注点               立即开始计算命盘            单选降低认知负担
 │          ├─ 感情运势              (后台使用简化的八字算法)
 │          ├─ 职业发展
 │          └─ 自我认知
 │
 8s        看到命盘可视化（加载动画）    "正在为你绘制命盘..."       制造期待感
 │          ▼                                                     │
12s        🔥 Aha Moment #1             "你是丙火日主，            视觉冲击+
 │          专业命盘展示                天生温暖明亮..."            即时个性化
 │            ├─ 四柱八字                                        │
 │            ├─ 五行配色                                        │
 │            └─ 日主突出显示                                    │
 │
18s        看到今日运势卡片             "本周你的贵人运⬆️，        免费价值+
 │          (滚动出现)                 适合主动出击..."            实用建议
 │            ├─ 运势指数(65/100)                               │
 │            ├─ 今日宜忌                                        │
 │            └─ 一句话金句                                     │
 │
25s        自动弹出引导                 "想要更深度解读吗？        自然引导，
 │          (非强制)                    只需3个问题..."            不打断体验
 │           ├─ "继续深度解读"按钮                              │
 │           └─ "暂时先看看"跳过按钮                             │
 │
30s        🔥 Aha Moment #2             用户感受到："这东西        情感连接
 │          (如果点击继续)               真的懂我！"               建立信任
 │          开始深度访谈(3个问题)                                 │
 └─────────────────────────────────────────────────────────────
```

### 2.2 关键状态机设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户状态转换                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   STATE_NEW (新用户)                                            │
│        │                                                        │
│        ▼ 选择关注点                                             │
│   STATE_QUICK_ANSWER (快速回答)                                  │
│        │                                                        │
│        ▼ 看到命盘预览                                           │
│   STATE_AHA_VISUAL (视觉顿悟)                                    │
│        │                                                        │
│        ▼ 看到今日运势                                           │
│   STATE_AHA_VALUE (价值顿悟)                                     │
│        │                                                        │
│        ├── 跳过 ──► STATE_LIGHT_USER (轻度用户)                 │
│        │           - 继续浏览                                   │
│        │           - 可能分享                                   │
│        │           - 未来可能转化                               │
│        │                                                        │
│        └── 继续 ──► STATE_DEEP_INTERVIEW (深度访谈)             │
│                    │                                            │
│                    ▼ 完成3个核心问题                            │
│                STATE_ENGAGED (已投入用户)                        │
│                        │                                        │
│                        ▼ 看到付费墙                             │
│                    STATE_CONVERT (转化决策)                     │
│                        ├── 付费 ──► PAID_USER                   │
│                        └── 离开 ──► 记录行为，后续召回           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 页面级交互设计

### 3.1 Landing 页面优化

**目标**: 5秒内传达"这是什么"+"能为我做什么"

```typescript
// apps/web/src/app/(bazi)/page.tsx
export default function BaziLandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-50 to-vellum">
      {/* Hero Section - 3秒传达核心价值 */}
      <section className="container mx-auto px-4 py-16 text-center">
        <h1 className="text-5xl font-serif text-ink mb-4">
          AI 八字命理
        </h1>
        <p className="text-xl text-ink/70 mb-8">
          像大师一样专业，像闺蜜一样懂你
        </p>

        {/* 3个快速问题 - 降低门槛 */}
        <QuickSelectionCard />
      </section>

      {/* 社会证明 - 建立信任 */}
      <section className="py-8 border-t border-vellum-200">
        <SocialProof stats={{
          users: "10,000+",
          accuracy: "94%满意",
          rating: "4.9星"
        }} />
      </section>
    </div>
  );
}
```

### 3.2 快速选择组件（关键组件）

```typescript
// apps/web/src/components/onboarding/QuickSelectionCard.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useSkill } from '@/providers/SkillProvider';

const FOCUS_OPTIONS = [
  {
    id: 'relationship',
    label: '感情运势',
    icon: '❤️',
    description: '爱情、婚姻、桃花',
    color: 'from-rose-400 to-pink-500'
  },
  {
    id: 'career',
    label: '职业发展',
    icon: '💼',
    description: '事业、财运、升职',
    color: 'from-blue-400 to-indigo-500'
  },
  {
    id: 'self',
    label: '自我认知',
    icon: '🔮',
    description: '性格、天赋、使命',
    color: 'from-purple-400 to-violet-500'
  }
];

export function QuickSelectionCard() {
  const [selected, setSelected] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { skill } = useSkill();

  const handleSelect = async (focusId: string) => {
    setSelected(focusId);
    setLoading(true);

    // 立即跳转到命盘预览页面（不需要等待）
    // 使用简化的生日计算（默认为今日，后续可调整）
    router.push(`/${skill}/preview?focus=${focusId}`);
  };

  return (
    <div className="max-w-2xl mx-auto">
      <h2 className="text-2xl font-medium text-ink mb-6">
        你今天最想了解什么？
      </h2>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {FOCUS_OPTIONS.map((option) => (
          <button
            key={option.id}
            onClick={() => handleSelect(option.id)}
            disabled={loading}
            className={`
              relative p-6 rounded-2xl border-2 transition-all
              ${selected === option.id
                ? `border-ink bg-gradient-to-br ${option.color} text-white`
                : 'border-vellum-300 hover:border-ink/30 bg-white'
              }
              ${loading ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
            `}
          >
            <div className="text-4xl mb-3">{option.icon}</div>
            <div className="text-lg font-medium mb-1">{option.label}</div>
            <div className={`text-sm ${selected === option.id ? 'text-white/90' : 'text-ink/60'}`}>
              {option.description}
            </div>

            {loading && selected === option.id && (
              <div className="absolute inset-0 flex items-center justify-center bg-white/20 rounded-2xl">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white" />
              </div>
            )}
          </button>
        ))}
      </div>

      <p className="text-sm text-ink/50 mt-4">
        无需填写任何信息，立即查看你的命盘
      </p>
    </div>
  );
}
```

### 3.3 命盘预览页面（Aha Moment #1）

**这是最重要的页面，必须在12秒内展示**

```typescript
// apps/web/src/app/(bazi)/preview/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { BaziChart } from '@/components/bazi/BaziChart';
import { FortuneCard } from '@/components/fortune/FortuneCard';
import { DeepInterviewModal } from '@/components/interview/DeepInterviewModal';

export default function BaziPreviewPage() {
  const searchParams = useSearchParams();
  const focus = searchParams.get('focus') || 'self';

  const [loading, setLoading] = useState(true);
  const [showInterview, setShowInterview] = useState(false);
  const [baziData, setBaziData] = useState(null);

  useEffect(() => {
    // 快速计算八字（使用默认生日或简化算法）
    const calculateQuickBazi = async () => {
      // 模拟加载时间（制造期待感）
      await new Promise(resolve => setTimeout(resolve, 1500));

      // 调用后端快速计算API
      const response = await fetch('/api/v1/bazi/quick-calculate', {
        method: 'POST',
        body: JSON.stringify({ focus })
      });

      const data = await response.json();
      setBaziData(data);
      setLoading(false);
    };

    calculateQuickBazi();
  }, [focus]);

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-50 to-vellum">
      {/* Aha Moment #1: 命盘可视化 */}
      <section className="container mx-auto px-4 py-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-serif text-ink mb-2">
            你的命盘
          </h1>
          <p className="text-lg text-ink/70">
            {baziData.dayMasterInsight}
          </p>
        </div>

        {/* 专业命盘 - 视觉冲击 */}
        <div className="max-w-4xl mx-auto mb-8">
          <BaziChart
            data={baziData.chart}
            highlight="dayMaster"
            animated={true}
          />
        </div>

        {/* Aha Moment #2: 今日运势 - 免费价值 */}
        <div className="max-w-2xl mx-auto mb-12">
          <FortuneCard
            focus={focus}
            dailyFortune={baziData.dailyFortune}
            lite={true}
          />
        </div>

        {/* 自然引导：想要更深度解读吗？ */}
        <div className="max-w-2xl mx-auto">
          <DeepGuideCard
            onContinue={() => setShowInterview(true)}
            onSkip={() => {/* 跳过，记录为轻度用户 */}}
          />
        </div>
      </section>

      {/* 深度访谈模态框 */}
      {showInterview && (
        <DeepInterviewModal
          focus={focus}
          onClose={() => setShowInterview(false)}
          onComplete={(fullProfile) => {
            // 跳转到完整报告页面
            router.push(`/${skill}/report?profile=${fullProfile.id}`);
          }}
        />
      )}
    </div>
  );
}

// 加载屏幕（制造期待感）
function LoadingScreen() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-amber-50 to-vellum">
      <div className="text-center">
        <div className="relative w-24 h-24 mx-auto mb-6">
          {/* VibeGlyph 动画 */}
          <div className="absolute inset-0 animate-spin">
            <VibeGlyph />
          </div>
        </div>
        <h2 className="text-2xl font-serif text-ink mb-2">
          正在为你绘制命盘...
        </h2>
        <p className="text-ink/60">
          分析你的五行能量分布
        </p>
      </div>
    </div>
  );
}
```

### 3.4 深度引导卡片

```typescript
// apps/web/src/components/onboarding/DeepGuideCard.tsx
'use client';

import { useState } from 'react';

export function DeepGuideCard({ onContinue, onSkip }) {
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;

  return (
    <div className="bg-white rounded-2xl shadow-lg border border-vellum-200 p-8">
      <div className="flex items-start gap-6">
        {/* AI 头像 */}
        <div className="flex-shrink-0">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-3xl">
            🔮
          </div>
        </div>

        {/* 引导文案 */}
        <div className="flex-1">
          <h3 className="text-xl font-serif text-ink mb-2">
            想要更深度解读吗？
          </h3>
          <p className="text-ink/70 mb-4">
            我刚为你生成了基础命盘，但如果能了解你的出生时间，
            我可以为你提供更精准的性格分析、人生K线和完整的解读报告。
          </p>

          {/* 价值承诺 */}
          <div className="grid grid-cols-3 gap-4 mb-6">
            <div className="text-center p-3 bg-vellum-50 rounded-lg">
              <div className="text-2xl mb-1">📊</div>
              <div className="text-sm text-ink/70">人生K线图</div>
            </div>
            <div className="text-center p-3 bg-vellum-50 rounded-lg">
              <div className="text-2xl mb-1">🔮</div>
              <div className="text-sm text-ink/70">三元棱镜</div>
            </div>
            <div className="text-center p-3 bg-vellum-50 rounded-lg">
              <div className="text-2xl mb-1">📝</div>
              <div className="text-sm text-ink/70">完整报告</div>
            </div>
          </div>

          {/* 行动按钮 */}
          <div className="flex gap-3">
            <button
              onClick={onContinue}
              className="flex-1 bg-gradient-to-r from-amber-500 to-orange-500 text-white px-6 py-3 rounded-xl font-medium hover:shadow-lg transition-all"
            >
              只需3个问题，继续深度解读 →
            </button>
            <button
              onClick={() => {
                onSkip();
                setDismissed(true);
              }}
              className="px-6 py-3 text-ink/60 hover:text-ink transition-colors"
            >
              暂时先看看
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### 3.5 深度访谈流程（简化版）

```typescript
// apps/web/src/components/interview/DeepInterviewModal.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

const QUESTIONS = [
  {
    id: 'birth_datetime',
    question: '你的出生时间？',
    type: 'datetime',
    required: true,
    placeholder: '选择或输入你的出生时间',
    explanation: '准确的出生时间能让命盘更精确'
  },
  {
    id: 'birth_location',
    question: '你的出生地点？',
    type: 'location',
    required: true,
    placeholder: '输入城市或选择地点',
    explanation: '出生地点影响时区计算'
  },
  {
    id: 'current_focus',
    question: '你现在最关心的是什么？',
    type: 'choice',
    required: true,
    options: [
      { value: 'relationship', label: '感情问题' },
      { value: 'career', label: '事业发展' },
      { value: 'fortune', label: '财运运势' },
      { value: 'health', label: '健康养生' },
      { value: 'growth', label: '个人成长' }
    ]
  }
];

export function DeepInterviewModal({ focus, onClose, onComplete }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [answers, setAnswers] = useState({});
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const currentQuestion = QUESTIONS[currentStep];
  const progress = ((currentStep + 1) / QUESTIONS.length) * 100;

  const handleNext = async (answer) => {
    const newAnswers = { ...answers, [currentQuestion.id]: answer };
    setAnswers(newAnswers);

    if (currentStep < QUESTIONS.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // 完成访谈，提交到后端
      setLoading(true);
      try {
        const response = await fetch('/api/v1/interview/complete', {
          method: 'POST',
          body: JSON.stringify({
            skill: 'bazi',
            answers: newAnswers,
            focus
          })
        });

        const { profile_id, report_id } = await response.json();
        onComplete({ id: profile_id, report_id });
      } catch (error) {
        console.error('Interview submission failed:', error);
      } finally {
        setLoading(false);
      }
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
        {/* 头部：进度条 */}
        <div className="px-6 py-4 border-b border-vellum-200">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-ink/60">
              深度解读 {currentStep + 1}/{QUESTIONS.length}
            </span>
            <button onClick={onClose} className="text-ink/60 hover:text-ink">
              ✕
            </button>
          </div>
          <div className="w-full bg-vellum-200 rounded-full h-2">
            <div
              className="bg-gradient-to-r from-amber-500 to-orange-500 h-2 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* 问题内容 */}
        <div className="p-6">
          <h2 className="text-2xl font-serif text-ink mb-2">
            {currentQuestion.question}
          </h2>
          {currentQuestion.explanation && (
            <p className="text-ink/60 mb-6">
              {currentQuestion.explanation}
            </p>
          )}

          {/* 根据问题类型渲染不同的输入组件 */}
          <QuestionInput
            question={currentQuestion}
            value={answers[currentQuestion.id]}
            onChange={(value) => handleNext(value)}
          />
        </div>

        {/* 底部：导航 */}
        <div className="px-6 py-4 bg-vellum-50 border-t border-vellum-200">
          <div className="flex justify-between">
            <button
              onClick={() => setCurrentStep(Math.max(0, currentStep - 1))}
              disabled={currentStep === 0}
              className="px-4 py-2 text-ink/60 hover:text-ink disabled:opacity-50"
            >
              ← 上一步
            </button>
            <div className="flex gap-2">
              {QUESTIONS.map((_, idx) => (
                <div
                  key={idx}
                  className={`w-2 h-2 rounded-full ${
                    idx === currentStep
                      ? 'bg-amber-500'
                      : idx < currentStep
                      ? 'bg-amber-200'
                      : 'bg-vellum-300'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## 4. 后端 API 设计

### 4.1 快速计算 API（无访谈）

```python
# apps/api/routes/bazi.py
from fastapi import APIRouter, HTTPException
from services.bazi import BaziCalculator
from services.fortune import FortuneGenerator
from pydantic import BaseModel

router = APIRouter()

class QuickCalculateRequest(BaseModel):
    focus: str  # 'relationship', 'career', 'self'

@router.post("/quick-calculate")
async def quick_calculate(request: QuickCalculateRequest):
    """
    快速八字计算（无需完整出生信息）
    使用简化算法或默认值，确保12秒内返回
    """

    try:
        # 1. 使用今日日期或简化八字计算
        calculator = BaziCalculator()
        quick_chart = calculator.calculate_quick(
            use_today=True,  # 使用今日作为示例
            focus=request.focus
        )

        # 2. 生成日主洞察
        day_master_insight = calculator.get_day_master_insight(
            quick_chart['day_master']
        )

        # 3. 生成今日运势（免费价值）
        fortune_gen = FortuneGenerator()
        daily_fortune = fortune_gen.generate_daily_fortune(
            quick_chart,
            focus=request.focus,
            lite=True  # Lite版本
        )

        return {
            "chart": quick_chart,
            "dayMasterInsight": day_master_insight,
            "dailyFortune": daily_fortune,
            "is_lite": True,  # 标记为简化版
            "upgrade_prompt": "提供出生时间可获得更精准分析"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### 4.2 深度访谈提交 API

```python
# apps/api/routes/interview.py
from fastapi import APIRouter, HTTPException, Request
from services.interview import InterviewService
from services.portrait import PortraitService
from pydantic import BaseModel

router = APIRouter()

class InterviewCompleteRequest(BaseModel):
    skill: str
    answers: dict
    focus: str

@router.post("/complete")
async def complete_interview(
    request: Request,
    interview_data: InterviewCompleteRequest
):
    """
    完成深度访谈，创建完整用户画像
    """
    user_id = request.state.user_id

    try:
        # 1. 保存访谈数据
        interview_service = InterviewService()
        interview = await interview_service.save_interview(
            user_id=user_id,
            skill=interview_data.skill,
            answers=interview_data.answers
        )

        # 2. 构建完整用户画像
        portrait_service = PortraitService()
        profile = await portrait_service.create_profile(
            user_id=user_id,
            skill=interview_data.skill,
            interview_id=interview.id,
            focus=interview_data.focus
        )

        # 3. 生成完整报告（后台任务）
        report_id = await generate_full_report(
            user_id=user_id,
            profile_id=profile.id,
            skill=interview_data.skill
        )

        return {
            "profile_id": profile.id,
            "report_id": report_id,
            "redirect_to": f"/{interview_data.skill}/report?id={report_id}"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 5. A/B 测试框架

### 5.1 关键测试变量

```python
# apps/api/services/experiment.py
from enum import Enum

class OnboardingVariant(Enum):
    CONTROL = "control"  # 原版：强制访谈
    VARIANT_A = "quick_first"  # 快速选择优先
    VARIANT_B = "visual_first"  # 可视化优先
    VARIANT_C = "fortune_first"  # 运势优先

class ExperimentConfig:
    ONBOARDING_EXPERIMENT = {
        "name": "onboarding_flow_optimization",
        "variants": [
            {
                "id": OnboardingVariant.CONTROL,
                "weight": 0.2,  # 20% 用户
                "flow": "interview_first"
            },
            {
                "id": OnboardingVariant.VARIANT_A,
                "weight": 0.4,  # 40% 用户
                "flow": "quick_selection_first"
            },
            {
                "id": OnboardingVariant.VARIANT_B,
                "weight": 0.2,  # 20% 用户
                "flow": "visual_preview_first"
            },
            {
                "id": OnboardingVariant.VARIANT_C,
                "weight": 0.2,  # 20% 用户
                "flow": "daily_fortune_first"
            }
        ],
        "metrics": [
            "time_to_aha",
            "aha_completion_rate",
            "interview_start_rate",
            "interview_completion_rate",
            "free_to_paid_conversion"
        ]
    }
```

### 5.2 前端变体实现

```typescript
// apps/web/src/components/onboarding/OnboardingFlow.tsx
'use client';

import { useExperiment } from '@/hooks/useExperiment';
import { QuickSelectionFlow } from './QuickSelectionFlow';
import { VisualFirstFlow } from './VisualFirstFlow';
import { InterviewFirstFlow } from './InterviewFirstFlow';

export function OnboardingFlow() {
  const { variant } = useExperiment('onboarding_flow_optimization');

  switch (variant) {
    case 'quick_first':
      return <QuickSelectionFlow />;
    case 'visual_first':
      return <VisualFirstFlow />;
    case 'fortune_first':
      return <FortuneFirstFlow />;
    case 'control':
    default:
      return <InterviewFirstFlow />;
  }
}
```

---

## 6. 数据追踪埋点

### 6.1 关键事件定义

```typescript
// apps/web/src/lib/analytics.ts
export interface OnboardingEvent {
  event_name: string;
  timestamp: number;
  user_id?: string;
  session_id: string;
  properties: Record<string, any>;
}

export const ONBOARDING_EVENTS = {
  // 漏斗顶部
  ONBOARDING_START: 'onboarding_start',

  // 快速选择阶段
  QUICK_SELECTION_SHOW: 'quick_selection_show',
  QUICK_SELECTION_CLICK: 'quick_selection_click',

  // 命盘预览阶段
  CHART_PREVIEW_START_LOAD: 'chart_preview_start_load',
  CHART_PREVIEW_SHOWN: 'chart_preview_shown',
  CHART_PREVIEW_INTERACTION: 'chart_preview_interaction',

  // 今日运势阶段
  DAILY_FORTUNE_SHOWN: 'daily_fortune_shown',
  DAILY_FORTUNE_SHARE: 'daily_fortune_share',

  // 深度访谈阶段
  DEEP_GUIDE_SHOW: 'deep_guide_show',
  DEEP_GUIDE_CONTINUE: 'deep_guide_continue',
  DEEP_GUIDE_SKIP: 'deep_guide_skip',

  // 访谈流程
  INTERVIEW_START: 'interview_start',
  INTERVIEW_STEP_COMPLETE: 'interview_step_complete',
  INTERVIEW_COMPLETE: 'interview_complete',

  // Aha Moment
  AHA_MOMENT_VISUAL: 'aha_moment_visual',
  AHA_MOMENT_VALUE: 'aha_moment_value',

  // 转化
  PAYWALL_SHOW: 'paywall_show',
  PAYWALL_CLICK_UPGRADE: 'paywall_click_upgrade',
  PAYWALL_COMPLETE: 'paywall_complete'
};

// 使用示例
export function trackOnboardingEvent(
  eventName: string,
  properties: Record<string, any> = {}
) {
  const event: OnboardingEvent = {
    event_name: eventName,
    timestamp: Date.now(),
    session_id: getSessionId(),
    properties: {
      ...properties,
      variant: getCurrentVariant(),
      referrer: document.referrer,
      utm_source: getUTMParameter('utm_source'),
      utm_medium: getUTMParameter('utm_medium'),
      utm_campaign: getUTMParameter('utm_campaign')
    }
  };

  // 发送到分析平台
  analytics.track(eventName, event);
}
```

### 6.2 关键指标计算

```python
# apps/api/services/analytics/metrics.py
from datetime import datetime, timedelta

class OnboardingMetrics:
    """Onboarding 关键指标计算"""

    def calculate_time_to_aha(self, user_id: str) -> float:
        """
        计算从注册到 Aha Moment 的时间
        目标：< 30秒
        """
        start_time = self.get_event_time(user_id, 'onboarding_start')
        aha_time = self.get_event_time(
            user_id,
            'aha_moment_value'  # 以看到今日运势为准
        )

        if start_time and aha_time:
            return (aha_time - start_time).total_seconds()
        return None

    def calculate_aha_completion_rate(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> float:
        """
        Aha Moment 完成率
        目标：> 70%
        """
        started = self.count_users_with_event(
            'onboarding_start',
            start_date,
            end_date
        )
        aha_moment = self.count_users_with_event(
            'aha_moment_value',
            start_date,
            end_date
        )

        return (aha_moment / started * 100) if started > 0 else 0

    def calculate_interview_start_rate(self) -> float:
        """
        深度访谈启动率
        目标：> 40%（从 Aha Moment）
        """
        aha_users = self.get_users_with_event('aha_moment_value')
        interview_users = self.get_users_with_event('interview_start')

        return (len(interview_users) / len(aha_users) * 100) if aha_users else 0

    def calculate_drop_off_points(self) -> dict:
        """
        流失点分析
        """
        funnel = {
            'start': self.count_users_with_event('onboarding_start'),
            'quick_select': self.count_users_with_event('quick_selection_click'),
            'chart_preview': self.count_users_with_event('chart_preview_shown'),
            'aha_value': self.count_users_with_event('aha_moment_value'),
            'deep_guide': self.count_users_with_event('deep_guide_show'),
            'interview_start': self.count_users_with_event('interview_start'),
            'interview_complete': self.count_users_with_event('interview_complete')
        }

        drop_off = {}
        prev_count = None

        for step, count in funnel.items():
            if prev_count:
                drop_off[step] = {
                    'count': count,
                    'drop_off_count': prev_count - count,
                    'drop_off_rate': ((prev_count - count) / prev_count * 100)
                }
            prev_count = count

        return drop_off
```

---

## 7. 移动端优化

### 7.1 移动端关键差异

```css
/* apps/web/src/styles/mobile-onboarding.css */
/* 基于70%流量来自移动端的优化 */

@media (max-width: 768px) {
  /* 快速选择卡片：垂直堆叠 */
  .quick-selection-grid {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  /* 命盘可视化：全屏展示 */
  .chart-preview {
    position: fixed;
    inset: 0;
    z-index: 50;
  }

  /* 深度引导：底部卡片 */
  .deep-guide-card {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    border-radius: 20px 20px 0 0;
    box-shadow: 0 -4px 20px rgba(0,0,0,0.1);
  }

  /* 按钮：拇指友好 */
  .action-button {
    min-height: 48px;
    font-size: 16px;
  }

  /* 运势卡片：可滑动 */
  .fortune-card {
    scroll-snap-type: x mandatory;
    overflow-x: scroll;
  }
}
```

### 7.2 PWA 支持

```typescript
// apps/web/public/manifest.json
{
  "name": "VibeLife - AI 八字命理",
  "short_name": "VibeLife",
  "description": "像大师一样专业，像闺蜜一样懂你",
  "start_url": "/?source=pwa",
  "display": "standalone",
  "background_color": "#FAF9F7",
  "theme_color": "#D97706",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["lifestyle", "entertainment"],
  "shortcuts": [
    {
      "name": "今日运势",
      "short_name": "运势",
      "description": "查看今日运势",
      "url": "/bazi/fortune?source=pwa",
      "icons": [{ "src": "/icons/fortune.png", "sizes": "96x96" }]
    },
    {
      "name": "开始对话",
      "short_name": "对话",
      "description": "与AI命理师对话",
      "url": "/bazi/chat?source=pwa",
      "icons": [{ "src": "/icons/chat.png", "sizes": "96x96" }]
    }
  ]
}
```

---

## 8. 实施检查清单

### Week 1: 核心流程

```
前端开发
├── [ ] QuickSelectionCard 组件
├── [ ] 命盘预览页面（BaziPreviewPage）
├── [ ] FortuneCard 组件（Lite版本）
├── [ ] DeepGuideCard 组件
├── [ ] DeepInterviewModal 组件
└── [ ] 移动端适配

后端开发
├── [ ] POST /api/v1/bazi/quick-calculate
├── [ ] POST /api/v1/interview/complete
├── [ ] 简化八字计算逻辑
└── [ ] Lite版运势生成逻辑

数据追踪
├── [ ] 埋点事件定义
├── [ ] Analytics 集成
└── [ ] Dashboard 搭建
```

### Week 2: A/B 测试

```
实验配置
├── [ ] A/B测试框架搭建
├── [ ] 变体流量分配
├── [ ] 控制组实现
└── [ ] 实验指标定义

数据验证
├── [ ] 时间追踪准确性
├── [ ] 事件触发验证
└── [ ] 漏斗数据可视化
```

### Week 3: 优化迭代

```
数据分析
├── [ ] Week 1 数据回顾
├── [ ] 流失点识别
├── [ ] 用户反馈收集
└── [ ] 优化方案设计

快速迭代
├── [ ] 文案优化
├── [ ] 加载速度优化
├── [ ] UI微调
└── [ ] 移动端体验提升
```

---

## 9. 成功标准

### 9.1 北极星指标

```python
SUCCESS_METRICS = {
    "time_to_aha": {
        "target": "< 30秒",
        "current": "待测量",
        "status": "关键指标"
    },
    "aha_completion_rate": {
        "target": "> 70%",
        "current": "待测量",
        "status": "关键指标"
    },
    "interview_start_rate": {
        "target": "> 40%",
        "current": "待测量",
        "status": "重要指标"
    },
    "free_user_satisfaction": {
        "target": "> 60%",
        "current": "待测量",
        "status": "重要指标"
    }
}
```

### 9.2 阶段性目标

| 阶段 | 时间 | 目标 | 验证方式 |
|------|------|------|----------|
| **MVP上线** | Week 1 | 30秒Aha Moment达成率 >50% | 数据追踪 |
| **优化迭代** | Week 2 | 30秒Aha Moment达成率 >70% | A/B测试 |
| **PMF验证** | Week 4 | 次日留存 >40% | 留存分析 |

---

## 10. 风险与缓解

| 风险 | 影响 | 缓解策略 |
|------|------|----------|
| 简化算法准确度低 | 用户质疑专业性 | 明确标注"预览版"，引导完整访谈 |
| 移动端加载慢 | 流失率上升 | 图表懒加载、骨架屏、CDN加速 |
| 用户不愿意给信息 | 转化率低 | 分步索取，先给价值再要信息 |
| A/B测试流量不足 | 结果不显著 | 集中流量，快速决策 |

---

## 附录：技术栈参考

```
Frontend
────────
• Next.js 14 (App Router)
• Framer Motion (动画)
• React Hook Form (表单)
• Zustand (状态管理)

Backend
───────
• FastAPI (Python)
• Redis (缓存)
• PostgreSQL (持久化)

Analytics
─────────
• Mixpanel/Amplitude (事件追踪)
• Supabase (用户数据)
• Google Analytics 4 (网页分析)
```
