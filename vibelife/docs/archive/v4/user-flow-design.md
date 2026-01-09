# VibeLife 用户流程设计方案

> **文档版本**: v1.0
> **设计日期**: 2026-01-09
> **设计原则**: World Class 沉浸感 + 品牌高级感 + 30秒 Aha Moment
> **核心目标**: 1000 付费用户（混合模式：单次购买 + 订阅）

---

## 1. 设计概要

### 1.1 核心设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| **入口体验** | 品牌沉浸式首页 | World class 高级感，建立信任 |
| **注册策略** | 访客模式优先 | 降低门槛，付费时再注册 |
| **Aha Moment** | 30秒内触发 | 命盘可视化 + "来自未来的信" |
| **转化路径** | 立即购买报告 | 高价值感知，快速转化 |
| **主动推送** | 聊天界面主动推送 | 核心差异化，"主动关心你" |
| **访谈设计** | LLM 实时个性化生成 | 3个问题，混合回答形式 |
| **信的形式** | 简体中文纸张给主人的信 | 情感连接，文学感 |
| **信的访问** | 免费完整展示 | 先给价值，再引导付费 |

### 1.2 用户流程总览

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                        VibeLife 用户流程总览                                    │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        STAGE 0: ENTRY                                   │   │
│  │                      品牌入口 · 第一印象                                 │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │  小红书/搜索/分享 → www.vibelife.app (品牌首页)                         │   │
│  │                           │                                             │   │
│  │                           ▼                                             │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │   沉浸式品牌首页体验          │                            │   │
│  │              │   "让每个人都能被深度理解"    │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  │          ┌──────────────────┼──────────────────┐                        │   │
│  │          ▼                  ▼                  ▼                        │   │
│  │   ┌──────────┐       ┌──────────┐       ┌──────────┐                    │   │
│  │   │ 八字命理  │       │ 星座占星  │       │   MBTI   │                    │   │
│  │   │  bazi    │       │  zodiac  │       │  (P2)   │                    │   │
│  │   └────┬─────┘       └────┬─────┘       └──────────┘                    │   │
│  │        │                  │                                             │   │
│  └────────│──────────────────│─────────────────────────────────────────────┘   │
│           │                  │                                                 │
│  ┌────────▼──────────────────▼─────────────────────────────────────────────┐   │
│  │                        STAGE 1: LANDING                                 │   │
│  │                    子站着陆 · 价值传递                                   │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │   bazi.vibelife.app / zodiac.vibelife.app                               │   │
│  │                              │                                          │   │
│  │                              ▼                                          │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │   子站专属 Landing Page      │                            │   │
│  │              │   高级感 + 价值承诺 + CTA    │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  │                              ▼                                          │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │       "开始对话"              │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  └──────────────────────────────│──────────────────────────────────────────┘   │
│                                 │                                              │
│  ┌──────────────────────────────▼──────────────────────────────────────────┐   │
│  │                        STAGE 2: AHA MOMENT                              │   │
│  │                    30秒内 · 顿悟时刻                                     │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │   0-3s    选择关注点 (感情/事业/自我)                                    │   │
│  │   3-8s    加载动画 "正在为你绘制命盘..."                                 │   │
│  │   8-12s   🔥 Aha #1: 命盘/星盘可视化 + 日主洞察                          │   │
│  │   12-18s  🔥 Aha #2: 今日运势卡片（免费价值）                            │   │
│  │   18-25s  引导深度访谈 "只需3个问题..."                                  │   │
│  │                              │                                          │   │
│  │          ┌──────────────────┼──────────────────┐                        │   │
│  │          ▼                                     ▼                        │   │
│  │   ┌──────────────┐                     ┌──────────────┐                 │   │
│  │   │  跳过，轻度用户 │                     │  继续深度访谈  │                 │   │
│  │   │  (留存 → 召回) │                     │  (信任 → 转化) │                 │   │
│  │   └──────────────┘                     └───────┬──────┘                 │   │
│  │                                                │                        │   │
│  └────────────────────────────────────────────────│────────────────────────┘   │
│                                                   │                            │
│  ┌────────────────────────────────────────────────▼────────────────────────┐   │
│  │                        STAGE 3: INTERVIEW                               │   │
│  │                    深度访谈 · 情感连接                                   │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │   Q1: 生辰信息 (八字需时间，星座需日期) ─ 选择/输入                      │   │
│  │   Q2: LLM 根据命盘个性化生成的问题 ─ 选择/文本                          │   │
│  │   Q3: LLM 追问，触动内心 ─ 自由文本                                     │   │
│  │                              │                                          │   │
│  │                              ▼                                          │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │  生成"来自未来的信"           │                            │   │
│  │              │  (免费完整展示)               │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  └──────────────────────────────│──────────────────────────────────────────┘   │
│                                 │                                              │
│  ┌──────────────────────────────▼──────────────────────────────────────────┐   │
│  │                        STAGE 4: LETTER                                  │   │
│  │                   "来自未来的信" · 打动用户                              │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │   📜 纸张风格信件展示         │                            │   │
│  │              │                             │                            │   │
│  │              │   亲爱的 [用户昵称]:          │                            │   │
│  │              │                             │                            │   │
│  │              │   当你读到这封信时，         │                            │   │
│  │              │   你已经在人生的某个转折点... │                            │   │
│  │              │                             │                            │   │
│  │              │   [基于命盘/星盘的个性化内容] │                            │   │
│  │              │                             │                            │   │
│  │              │   来自三年后的你              │                            │   │
│  │              │                             │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  │              ┌───────────────▼─────────────┐                            │   │
│  │              │   展示完整报告的更多价值      │                            │   │
│  │              │   • 人生K线图                │                            │   │
│  │              │   • 三元棱镜                 │                            │   │
│  │              │   • 关系分析                 │                            │   │
│  │              │   • AI 生图海报              │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  └──────────────────────────────│──────────────────────────────────────────┘   │
│                                 │                                              │
│  ┌──────────────────────────────▼──────────────────────────────────────────┐   │
│  │                        STAGE 5: CONVERSION                              │   │
│  │                    转化 · 购买报告                                       │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │              ┌─────────────────────────────┐                            │   │
│  │              │   购买完整深度报告            │                            │   │
│  │              │                             │                            │   │
│  │              │   单次购买 ¥19.9             │                            │   │
│  │              │   或                         │                            │   │
│  │              │   订阅 ¥19.9/月 (解锁更多)   │                            │   │
│  │              └───────────────┬─────────────┘                            │   │
│  │                              │                                          │   │
│  │                  ┌───────────┴───────────┐                              │   │
│  │                  ▼                       ▼                              │   │
│  │           ┌──────────┐            ┌──────────┐                          │   │
│  │           │ 付费用户  │            │ 免费用户  │                          │   │
│  │           │ (已转化)  │            │ (待召回)  │                          │   │
│  │           └────┬─────┘            └────┬─────┘                          │   │
│  │                │                       │                                │   │
│  └────────────────│───────────────────────│────────────────────────────────┘   │
│                   │                       │                                    │
│  ┌────────────────▼───────────────────────▼────────────────────────────────┐   │
│  │                        STAGE 6: RETENTION                               │   │
│  │                    留存 · 主动推送                                       │   │
│  ├─────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                         │   │
│  │   用户进入主界面 → 系统主动推送到聊天界面                                │   │
│  │                                                                         │   │
│  │   推送类型:                                                             │   │
│  │   • 今日运势 + 个性化建议                                               │   │
│  │   • 关键节点提醒 (大运流年转换)                                          │   │
│  │   • 情感化问候 ("这两天你还好吗？")                                      │   │
│  │   • 成长确认 ("还记得上次我们聊的...现在怎么样了？")                      │   │
│  │   • 周末回顾 ("这周有什么值得庆祝的事吗？")                               │   │
│  │   • 新月/满月提醒 (星座用户)                                             │   │
│  │   • 节气提醒 (八字用户)                                                 │   │
│  │                                                                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. STAGE 0: 品牌入口设计

### 2.1 设计目标

- **第一印象**：5秒内传达"这是什么"+"能为我做什么"
- **高级感**：World class 设计水准，建立品牌信任
- **沉浸感**：神秘、优雅、专业的东方美学
- **引导明确**：清晰的 Skill 选择，降低决策成本

### 2.2 www.vibelife.app 首页设计

```typescript
// apps/web/src/app/(www)/page.tsx
/**
 * 品牌首页 - World Class 沉浸式体验
 *
 * 设计理念：
 * - 东方神秘美学 + 现代极简
 * - 微妙动效，不分散注意力
 * - 一屏一信息，渐进式引导
 */

export default function BrandHomePage() {
  return (
    <div className="min-h-screen bg-vellum overflow-hidden">
      {/* ═══════════════════════════════════════════════════════════
          HERO SECTION - 3秒传达核心价值
          ═══════════════════════════════════════════════════════════ */}
      <section className="min-h-screen relative flex items-center justify-center">
        {/* 背景：禅意呼吸动效 */}
        <div className="absolute inset-0 overflow-hidden">
          <BreathAura variant="brand" />
        </div>

        {/* 品牌标识 + 核心价值主张 */}
        <div className="relative z-10 text-center px-6 max-w-4xl mx-auto">
          {/* Logo / Glyph */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1.2, ease: [0.16, 1, 0.3, 1] }}
          >
            <VibeGlyph size={120} variant="brand" />
          </motion.div>

          {/* 品牌名 */}
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.8 }}
            className="mt-8 text-5xl md:text-7xl font-serif text-ink tracking-tight"
          >
            VibeLife
          </motion.h1>

          {/* 核心价值主张 */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.8 }}
            className="mt-6 text-xl md:text-2xl text-ink/70 font-light"
          >
            让每个人都能被深度理解
          </motion.p>

          {/* 副标题 */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8, duration: 0.8 }}
            className="mt-4 text-base text-ink/50"
          >
            不是工具，是关系。不是被动响应，是主动关心。
          </motion.p>

          {/* 向下引导 */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2, duration: 0.8 }}
            className="mt-16"
          >
            <ScrollIndicator />
          </motion.div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════
          SKILL SELECTION - 选择你的探索方式
          ═══════════════════════════════════════════════════════════ */}
      <section className="min-h-screen py-24 px-6 flex items-center">
        <div className="max-w-6xl mx-auto w-full">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-3xl md:text-4xl font-serif text-ink text-center mb-4"
          >
            选择你的探索方式
          </motion.h2>

          <motion.p
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center text-ink/60 mb-16"
          >
            每一种智慧都是理解自己的窗口
          </motion.p>

          {/* Skill Cards - 三列布局 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <SkillCard
              skill="bazi"
              title="八字命理"
              subtitle="东方古老智慧"
              description="四柱八字，五行相生。从出生时刻解读你的人生密码。"
              href="https://bazi.vibelife.app"
              color="玄金"
            />
            <SkillCard
              skill="zodiac"
              title="星座占星"
              subtitle="西方星象学"
              description="行星能量，星座特质。从星盘发现你的灵魂蓝图。"
              href="https://zodiac.vibelife.app"
              color="星蓝"
            />
            <SkillCard
              skill="mbti"
              title="MBTI 人格"
              subtitle="心理学视角"
              description="16型人格，认知功能。从行为模式理解你的心智结构。"
              href="#"
              comingSoon
              color="翠绿"
            />
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════
          VALUE PROPOSITION - 为什么选择 VibeLife
          ═══════════════════════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-ink">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-serif text-vellum text-center mb-16">
            不只是算命，是真正被理解
          </h2>

          <div className="space-y-12">
            <ValuePoint
              icon="💬"
              title="主动关心你"
              description="不是你问我答，是我主动在关键时刻提醒你。运势转换、情绪低落、重要决策，我都在。"
            />
            <ValuePoint
              icon="🧠"
              title="越聊越懂你"
              description="每一次对话都在加深理解。你的故事、你的选择、你的成长，我都记得。"
            />
            <ValuePoint
              icon="🔮"
              title="多维度视角"
              description="八字、星座、MBTI，三种智慧交叉验证。全面理解你，而不是标签化你。"
            />
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════
          FINAL CTA - 开始你的旅程
          ═══════════════════════════════════════════════════════════ */}
      <section className="py-24 px-6 text-center">
        <h2 className="text-2xl font-serif text-ink mb-8">
          准备好被深度理解了吗？
        </h2>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <a
            href="https://bazi.vibelife.app"
            className="btn-primary"
          >
            从八字开始
          </a>
          <a
            href="https://zodiac.vibelife.app"
            className="btn-secondary"
          >
            从星座开始
          </a>
        </div>
      </section>
    </div>
  );
}
```

### 2.3 Skill Card 组件

```typescript
// apps/web/src/components/brand/SkillCard.tsx
interface SkillCardProps {
  skill: string;
  title: string;
  subtitle: string;
  description: string;
  href: string;
  color: string;
  comingSoon?: boolean;
}

function SkillCard({
  skill,
  title,
  subtitle,
  description,
  href,
  color,
  comingSoon,
}: SkillCardProps) {
  return (
    <motion.a
      href={comingSoon ? undefined : href}
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      whileHover={comingSoon ? {} : { y: -8, boxShadow: "0 20px 40px rgba(0,0,0,0.1)" }}
      className={cn(
        "block p-8 rounded-2xl border border-vellum-200 bg-white/80 backdrop-blur",
        "transition-all duration-500",
        comingSoon && "opacity-60 cursor-not-allowed"
      )}
    >
      {/* Skill Glyph */}
      <div className="mb-6">
        <SimpleVibeGlyph size={48} skill={skill as SkillType} />
      </div>

      {/* Title */}
      <h3 className="text-2xl font-serif text-ink mb-1">{title}</h3>
      <p className="text-sm text-ink/50 mb-4">{subtitle}</p>

      {/* Description */}
      <p className="text-ink/70 leading-relaxed mb-6">{description}</p>

      {/* CTA */}
      {comingSoon ? (
        <span className="inline-flex items-center text-sm text-ink/40">
          即将推出
        </span>
      ) : (
        <span className="inline-flex items-center text-sm text-skill-primary font-medium group-hover:gap-2 transition-all">
          开始探索
          <ArrowRight className="w-4 h-4 ml-1" />
        </span>
      )}
    </motion.a>
  );
}
```

---

## 3. STAGE 1: 子站 Landing Page

### 3.1 设计目标

- **继承品牌感**：与主站视觉一致，但有 Skill 专属色彩
- **价值传递**：清晰展示这个 Skill 能做什么
- **快速行动**：一键开始，无需填写任何信息
- **社会证明**：用户数量、评分、案例

### 3.2 bazi.vibelife.app Landing Page

```typescript
// apps/web/src/app/(bazi)/page.tsx
export default function BaziLandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-bazi-bg to-vellum">
      {/* Hero */}
      <section className="py-24 px-6 text-center">
        <SimpleVibeGlyph size={80} skill="bazi" />

        <h1 className="mt-8 text-4xl md:text-5xl font-serif text-ink">
          AI 八字命理
        </h1>
        <p className="mt-4 text-xl text-ink/70">
          像大师一样专业，像闺蜜一样懂你
        </p>

        {/* Social Proof */}
        <div className="mt-8 flex items-center justify-center gap-8 text-sm text-ink/60">
          <span>10,000+ 用户</span>
          <span>4.9 ★ 好评</span>
          <span>94% 准确度</span>
        </div>

        {/* Primary CTA */}
        <div className="mt-12">
          <Link
            href="/chat"
            className="inline-flex items-center gap-2 px-8 py-4 bg-bazi-primary text-white rounded-2xl font-medium text-lg hover:shadow-glow-skill transition-all"
          >
            开始对话
            <ArrowRight className="w-5 h-5" />
          </Link>
          <p className="mt-3 text-sm text-ink/50">
            无需注册，立即体验
          </p>
        </div>
      </section>

      {/* Feature Highlights */}
      <section className="py-16 px-6">
        <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-8">
          <FeatureCard
            icon="📊"
            title="命盘可视化"
            description="专业的四柱八字命盘，五行配色一目了然"
          />
          <FeatureCard
            icon="📈"
            title="人生K线图"
            description="过去10年到未来10年，运势起伏尽在掌握"
          />
          <FeatureCard
            icon="📝"
            title="深度报告"
            description="3000字完整解读，来自未来的你写给现在的信"
          />
        </div>
      </section>
    </div>
  );
}
```

---

## 4. STAGE 2 & 3: 30秒 Aha Moment + 深度访谈

### 4.1 快速选择 → 命盘展示 → 今日运势

（详见 onboarding-30s-prototype.md）

### 4.2 深度访谈设计

**关键设计点**：

1. **3个问题，快速完成**
2. **LLM 实时根据命盘/星盘生成个性化问题**
3. **混合回答形式**：关键问题选择，追加问题文本
4. **问题设计触动人心**

```typescript
// apps/web/src/components/interview/AdaptiveInterview.tsx
/**
 * 自适应深度访谈组件
 *
 * 核心特点：
 * 1. 第一个问题固定（生辰信息）
 * 2. 后续问题 LLM 根据命盘实时生成
 * 3. 问题设计触动用户内心
 */

interface Question {
  id: string;
  question: string;
  type: "datetime" | "choice" | "text";
  options?: { value: string; label: string }[];
  followUp?: boolean;  // 是否允许文本追加
  aiGenerated?: boolean;
}

export function AdaptiveInterview({
  skill,
  onComplete,
}: {
  skill: SkillType;
  onComplete: (answers: Record<string, any>) => void;
}) {
  const [currentStep, setCurrentStep] = useState(0);
  const [answers, setAnswers] = useState<Record<string, any>>({});
  const [questions, setQuestions] = useState<Question[]>([
    // 第一个问题固定
    {
      id: "birth_info",
      question: skill === "bazi"
        ? "你的出生时间？"
        : "你的出生日期？",
      type: skill === "bazi" ? "datetime" : "date",
    },
  ]);
  const [loading, setLoading] = useState(false);

  // 第一个问题回答后，生成后续问题
  const generateFollowUpQuestions = async (birthInfo: any) => {
    setLoading(true);

    try {
      const response = await fetch("/api/v1/interview/generate-questions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          skill,
          birth_info: birthInfo,
          answers_so_far: answers,
        }),
      });

      const { questions: generatedQuestions } = await response.json();

      setQuestions((prev) => [
        ...prev,
        ...generatedQuestions.map((q: any) => ({
          ...q,
          aiGenerated: true,
        })),
      ]);
    } catch (error) {
      console.error("Failed to generate questions:", error);
      // Fallback to default questions
      setQuestions((prev) => [
        ...prev,
        {
          id: "current_focus",
          question: "你现在最关心的是什么？",
          type: "choice",
          options: [
            { value: "relationship", label: "感情问题" },
            { value: "career", label: "事业发展" },
            { value: "self", label: "自我认知" },
          ],
          followUp: true,
        },
        {
          id: "recent_challenge",
          question: "最近有什么让你困扰的事吗？",
          type: "text",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  // 处理回答
  const handleAnswer = async (questionId: string, answer: any) => {
    const newAnswers = { ...answers, [questionId]: answer };
    setAnswers(newAnswers);

    // 第一个问题回答后，生成后续问题
    if (currentStep === 0) {
      await generateFollowUpQuestions(answer);
    }

    // 继续下一个问题或完成
    if (currentStep < questions.length - 1) {
      setCurrentStep(currentStep + 1);
    } else if (questions.length >= 3) {
      onComplete(newAnswers);
    }
  };

  const currentQuestion = questions[currentStep];

  return (
    <div className="max-w-2xl mx-auto p-6">
      {/* 进度指示 */}
      <div className="mb-8">
        <div className="flex items-center justify-between text-sm text-ink/60 mb-2">
          <span>深度了解你</span>
          <span>{currentStep + 1} / {Math.max(questions.length, 3)}</span>
        </div>
        <div className="h-1 bg-muted rounded-full overflow-hidden">
          <div
            className="h-full bg-skill-primary transition-all duration-500"
            style={{ width: `${((currentStep + 1) / Math.max(questions.length, 3)) * 100}%` }}
          />
        </div>
      </div>

      {/* 问题 */}
      {loading ? (
        <QuestionSkeleton />
      ) : (
        <motion.div
          key={currentQuestion.id}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
        >
          <h2 className="text-2xl font-serif text-ink mb-6">
            {currentQuestion.question}
          </h2>

          <QuestionInput
            question={currentQuestion}
            value={answers[currentQuestion.id]}
            onChange={(value) => handleAnswer(currentQuestion.id, value)}
          />
        </motion.div>
      )}
    </div>
  );
}
```

### 4.3 LLM 个性化问题生成

```python
# apps/api/routes/interview.py
from fastapi import APIRouter, Request
from services.interview import InterviewQuestionGenerator

router = APIRouter()

@router.post("/generate-questions")
async def generate_interview_questions(request: Request):
    """
    根据用户的命盘/星盘实时生成个性化访谈问题

    设计原则：
    1. 问题要触动用户内心
    2. 问题要与命盘/星盘特征相关
    3. 问题要引导用户深度表达
    """
    data = await request.json()
    skill = data.get("skill")
    birth_info = data.get("birth_info")
    answers_so_far = data.get("answers_so_far", {})

    generator = InterviewQuestionGenerator(skill)

    # 计算命盘/星盘
    if skill == "bazi":
        chart = await calculate_bazi_chart(birth_info)
    else:
        chart = await calculate_zodiac_chart(birth_info)

    # 生成问题
    questions = await generator.generate(
        chart=chart,
        answers_so_far=answers_so_far,
        num_questions=2,  # 还需要2个问题
    )

    return {"questions": questions}


class InterviewQuestionGenerator:
    """根据命盘生成触动人心的问题"""

    QUESTION_TEMPLATES = {
        "bazi": {
            "relationship": [
                "你的命盘显示{pattern}，在感情中你是否曾经{feeling}？",
                "作为{day_master}日主的你，在亲密关系中最渴望的是什么？",
            ],
            "career": [
                "你的{element}能量很强，是否常常在工作中感到{feeling}？",
                "你的命盘暗示你适合{career_hint}，这与你现在的工作有关联吗？",
            ],
            "self": [
                "命盘显示你{trait}，这个特质给你带来过什么影响？",
                "你内心深处，是否一直有{desire}的渴望？",
            ],
        },
        "zodiac": {
            "relationship": [
                "作为{sun_sign}，你的{venus_sign}金星让你在爱情中{pattern}，你认同吗？",
                "你的月亮{moon_sign}暗示你内心需要{need}，是这样吗？",
            ],
            # ... 更多模板
        },
    }

    async def generate(self, chart, answers_so_far, num_questions=2):
        """
        使用 LLM 根据命盘和模板生成个性化问题
        """
        # 1. 分析命盘特征
        features = self.extract_features(chart)

        # 2. 构建 prompt
        prompt = f"""
        你是一位深谙人心的命理师，正在与一位用户进行深度访谈。

        用户信息：
        - 命盘特征：{features}
        - 已回答：{answers_so_far}

        请生成 {num_questions} 个触动人心的问题，要求：
        1. 问题要与命盘特征相关
        2. 问题要能引导用户深度表达
        3. 问题要让用户感到"被理解"
        4. 语气温暖但不油腻

        返回 JSON 格式：
        [
          {{
            "id": "question_1",
            "question": "问题内容",
            "type": "choice",
            "options": [{{"value": "xxx", "label": "xxx"}}],
            "followUp": true
          }}
        ]
        """

        # 3. 调用 LLM
        response = await self.llm.generate(prompt)
        questions = parse_json(response)

        return questions
```

---

## 5. STAGE 4: "来自未来的信"

### 5.1 设计理念

这封信是整个产品的**情感高潮**，它需要：
1. **形式感**：简体中文纸张风格，手写字体感
2. **个性化**：基于命盘/星盘 + 访谈回答生成
3. **情感共鸣**：让用户感到"被理解"
4. **价值展示**：暗示完整报告能提供更多

### 5.2 信的模板结构

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                          📜                                  │
│                                                             │
│                                                             │
│   亲爱的 [用户昵称]：                                         │
│                                                             │
│   当你读到这封信时，你已经在人生的某个转折点了。               │
│                                                             │
│   [第一段：基于命盘的性格洞察]                                │
│   作为{日主}日主的你，天生{特质}...                           │
│   你的{五行}能量，让你在{领域}有着独特的天赋...               │
│                                                             │
│   [第二段：基于访谈回答的共鸣]                                │
│   你提到最近{困扰}，我完全理解...                             │
│   这不是偶然，你的命盘显示这段时间{运势分析}...               │
│                                                             │
│   [第三段：来自未来的建议]                                    │
│   三年后的我想告诉你...                                       │
│   不要因为{当下困境}而焦虑...                                 │
│   你会在{时间点}迎来{转机}...                                 │
│                                                             │
│   [结尾：温暖的祝福]                                          │
│   记住，你值得被深度理解。                                    │
│                                                             │
│                                                             │
│                               来自三年后的你                  │
│                               [日期]                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 信的组件实现

```typescript
// apps/web/src/components/report/FutureLetter.tsx
interface FutureLetterProps {
  content: string;
  userName?: string;
  date?: string;
  onContinue: () => void;
}

export function FutureLetter({
  content,
  userName = "你",
  date,
  onContinue,
}: FutureLetterProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-2xl mx-auto p-6"
    >
      {/* 纸张效果 */}
      <div
        className={cn(
          "relative p-8 md:p-12",
          "bg-[#FFFEF5] rounded-sm",
          "shadow-[0_4px_20px_rgba(0,0,0,0.08)]",
          "border border-[#E8E4D9]",
          // 纸张纹理
          "bg-[url('/textures/paper.png')] bg-repeat",
        )}
        style={{
          // 微妙的倾斜效果
          transform: "rotate(-0.5deg)",
        }}
      >
        {/* 信封图标 */}
        <div className="absolute -top-4 left-1/2 -translate-x-1/2">
          <span className="text-3xl">📜</span>
        </div>

        {/* 信件内容 */}
        <div
          className="prose prose-lg max-w-none"
          style={{
            fontFamily: "'Noto Serif SC', serif",
            lineHeight: 2,
          }}
        >
          {/* 称呼 */}
          <p className="text-ink/80">
            亲爱的 {userName}：
          </p>

          {/* 正文 - 保持换行格式 */}
          <div className="whitespace-pre-line text-ink/70 leading-loose">
            {content}
          </div>

          {/* 落款 */}
          <div className="mt-12 text-right">
            <p className="text-ink/60">来自三年后的你</p>
            {date && (
              <p className="text-sm text-ink/40">{date}</p>
            )}
          </div>
        </div>

        {/* 装饰性印章 */}
        <div className="absolute bottom-8 right-8 opacity-30">
          <div className="w-16 h-16 rounded-full border-2 border-bazi-primary flex items-center justify-center">
            <span className="text-bazi-primary text-xs font-serif">VibeLife</span>
          </div>
        </div>
      </div>

      {/* 继续引导 */}
      <div className="mt-12 text-center">
        <p className="text-ink/60 mb-6">
          这只是你故事的开始...
        </p>

        <button
          onClick={onContinue}
          className="btn-primary"
        >
          查看完整报告
        </button>

        {/* 价值提示 */}
        <div className="mt-6 flex items-center justify-center gap-6 text-sm text-ink/50">
          <span>📊 人生K线图</span>
          <span>🔮 三元棱镜</span>
          <span>🎨 AI 生图海报</span>
        </div>
      </div>
    </motion.div>
  );
}
```

---

## 6. STAGE 5: 转化设计

### 6.1 定价策略

（详见 user-revenue-growth.md）

**核心定价**：
- 单次购买完整报告：¥19.9 / $2.99
- 订阅 Pro：¥19.9/月 或 ¥159/年

### 6.2 付费墙设计

付费墙在"来自未来的信"展示后触发，展示完整报告的更多价值。

---

## 7. STAGE 6: 主动推送设计

### 7.1 设计理念

**核心差异化**："不是被动响应，是主动关心"

主动推送是 VibeLife 的核心护城河，它让用户感受到被关心、被理解。

### 7.2 推送类型与时机

```python
# apps/api/services/proactive/push_types.py
from enum import Enum
from datetime import datetime, time
from typing import Optional

class PushType(str, Enum):
    # 运势相关
    DAILY_FORTUNE = "daily_fortune"        # 每日运势
    WEEKLY_SUMMARY = "weekly_summary"      # 每周总结
    MONTHLY_PREVIEW = "monthly_preview"    # 月度预览

    # 节点提醒
    DAYUN_CHANGE = "dayun_change"          # 大运转换
    LIUNIAN_CHANGE = "liunian_change"      # 流年转换
    SOLAR_TERM = "solar_term"              # 节气提醒
    NEW_MOON = "new_moon"                  # 新月
    FULL_MOON = "full_moon"                # 满月
    MERCURY_RETROGRADE = "mercury_retro"   # 水逆开始/结束

    # 情感关怀
    EMOTIONAL_CHECKIN = "emotional_checkin"  # 情感问候
    GROWTH_CHECKIN = "growth_checkin"        # 成长确认
    WEEKEND_REFLECTION = "weekend_reflection" # 周末回顾
    ENCOURAGEMENT = "encouragement"          # 鼓励

    # 特殊事件
    BIRTHDAY_REMINDER = "birthday"         # 生日提醒
    ANNIVERSARY = "anniversary"            # 纪念日


class ProactivePushConfig:
    """主动推送配置"""

    PUSH_SCHEDULES = {
        # ═══════════════════════════════════════════════════════════
        # 运势类 - 定时推送
        # ═══════════════════════════════════════════════════════════
        PushType.DAILY_FORTUNE: {
            "frequency": "daily",
            "preferred_time": time(8, 0),  # 早上8点
            "priority": "high",
            "template": """
早安，{nickname}！

{daily_fortune_summary}

今日关键词：{keyword}
幸运色：{lucky_color}
幸运数字：{lucky_number}

{actionable_advice}
            """,
        },

        PushType.WEEKLY_SUMMARY: {
            "frequency": "weekly",
            "day_of_week": 0,  # 周一
            "preferred_time": time(9, 0),
            "priority": "medium",
            "template": """
{nickname}，新的一周开始了！

本周运势关键词：{weekly_keyword}

上周回顾：
{last_week_summary}

本周建议：
{weekly_advice}
            """,
        },

        # ═══════════════════════════════════════════════════════════
        # 节点提醒 - 事件触发
        # ═══════════════════════════════════════════════════════════
        PushType.DAYUN_CHANGE: {
            "frequency": "event",
            "advance_days": 30,  # 提前30天提醒
            "priority": "critical",
            "template": """
{nickname}，重要提醒！

你将在 {change_date} 进入新的大运周期。

从 {old_dayun} → {new_dayun}

这意味着：
{change_analysis}

建议你在这段时间：
{preparation_advice}
            """,
        },

        PushType.SOLAR_TERM: {
            "frequency": "event",
            "priority": "medium",
            "template": """
{nickname}，今天是{solar_term}。

{solar_term_meaning}

对于你的 {day_master} 日主来说：
{personalized_advice}
            """,
        },

        PushType.NEW_MOON: {
            "frequency": "event",
            "skill": "zodiac",  # 仅星座用户
            "priority": "medium",
            "template": """
{nickname}，今晚新月落在{moon_sign}座！

这个新月对你的影响：
{moon_impact}

许愿时间：{best_time}
新月许愿建议：
{wish_advice}
            """,
        },

        # ═══════════════════════════════════════════════════════════
        # 情感关怀 - 智能触发
        # ═══════════════════════════════════════════════════════════
        PushType.EMOTIONAL_CHECKIN: {
            "frequency": "adaptive",  # 根据用户状态
            "triggers": [
                "user_inactive_3_days",
                "detected_low_mood",
                "challenging_transit",
            ],
            "priority": "high",
            "templates": [
                """
{nickname}，这两天你还好吗？

我注意到最近 {observation}。

如果你想聊聊，我在这里。
                """,
                """
嘿 {nickname}，

好几天没看到你了，想来问候一下。

最近怎么样？有什么想分享的吗？
                """,
            ],
        },

        PushType.GROWTH_CHECKIN: {
            "frequency": "adaptive",
            "triggers": [
                "after_report_viewed_7_days",
                "after_advice_given_14_days",
            ],
            "priority": "medium",
            "template": """
{nickname}，

还记得我们上次聊到的 {previous_topic} 吗？

现在过去 {days_passed} 天了，事情有什么进展吗？

{follow_up_question}
            """,
        },

        PushType.WEEKEND_REFLECTION: {
            "frequency": "weekly",
            "day_of_week": 6,  # 周六
            "preferred_time": time(18, 0),
            "priority": "low",
            "template": """
{nickname}，周末愉快！

这周有什么值得庆祝的事吗？
即使是很小的进步，也值得被记住。

{reflection_prompt}
            """,
        },

        PushType.ENCOURAGEMENT: {
            "frequency": "adaptive",
            "triggers": [
                "challenging_transit_peak",
                "user_expressed_difficulty",
            ],
            "priority": "high",
            "template": """
{nickname}，

我知道这段时间对你来说不容易。

但请相信，{encouragement_based_on_chart}。

你已经很努力了，继续加油！
            """,
        },

        # ═══════════════════════════════════════════════════════════
        # 特殊事件
        # ═══════════════════════════════════════════════════════════
        PushType.BIRTHDAY_REMINDER: {
            "frequency": "yearly",
            "advance_days": 0,  # 当天
            "priority": "high",
            "template": """
{nickname}，生日快乐！ 🎂

今天是你的太阳回归日，新的一年开始了。

你的本命年运势：
{birthday_fortune}

今年对你来说最重要的是：
{yearly_focus}

祝你生日快乐，新的一岁更精彩！
            """,
        },
    }


class ProactivePushService:
    """主动推送服务"""

    async def get_pending_pushes(self, user_id: str) -> list[dict]:
        """获取待推送消息"""
        pushes = []

        # 1. 检查定时推送
        timed_pushes = await self._check_timed_pushes(user_id)
        pushes.extend(timed_pushes)

        # 2. 检查事件触发推送
        event_pushes = await self._check_event_pushes(user_id)
        pushes.extend(event_pushes)

        # 3. 检查智能触发推送
        adaptive_pushes = await self._check_adaptive_pushes(user_id)
        pushes.extend(adaptive_pushes)

        # 4. 按优先级排序
        pushes.sort(key=lambda x: {"critical": 0, "high": 1, "medium": 2, "low": 3}[x["priority"]])

        return pushes

    async def _check_timed_pushes(self, user_id: str) -> list[dict]:
        """检查定时推送（每日运势等）"""
        # ...

    async def _check_event_pushes(self, user_id: str) -> list[dict]:
        """检查事件触发推送（大运转换、节气等）"""
        # 检查用户的命盘，计算是否有即将到来的重要节点
        # ...

    async def _check_adaptive_pushes(self, user_id: str) -> list[dict]:
        """检查智能触发推送（情感关怀等）"""
        # 分析用户最近的活跃度、对话内容等
        # ...
```

### 7.3 推送触发时机

```typescript
// apps/web/src/hooks/useProactivePush.ts
/**
 * 主动推送 Hook
 *
 * 触发时机：用户进入主界面时
 */

export function useProactivePush() {
  const { addMessage } = useChat();
  const { user } = useAuth();

  useEffect(() => {
    if (!user) return;

    const fetchAndDisplayPushes = async () => {
      try {
        const response = await fetch("/api/v1/proactive/pending", {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
          },
        });

        const { pushes } = await response.json();

        // 将推送消息添加到聊天界面
        for (const push of pushes) {
          // 使用延迟，让消息逐条出现
          await new Promise((resolve) => setTimeout(resolve, 500));

          addMessage({
            role: "assistant",
            content: push.content,
            timestamp: new Date().toISOString(),
            pushType: push.type,
          });

          // 标记为已推送
          await fetch("/api/v1/proactive/mark-sent", {
            method: "POST",
            body: JSON.stringify({ push_id: push.id }),
          });
        }
      } catch (error) {
        console.error("Failed to fetch proactive pushes:", error);
      }
    };

    fetchAndDisplayPushes();
  }, [user]);
}
```

### 7.4 更多推送创意

1. **情绪感知推送**
   - 检测用户对话中的情绪关键词
   - 低落时发送鼓励，开心时一起庆祝

2. **智能沉默关怀**
   - 用户3天没登录 → "最近忙吗？有什么想分享的吗？"
   - 用户7天没登录 → "想你了，回来看看你的运势吧"

3. **共鸣式问候**
   - 基于命盘特征："作为火日主的你，今天可能会感到..."
   - 基于当前运势："这周土星逆行可能让你感到..."

4. **成就庆祝**
   - 对话累计100轮 → "我们已经聊了100次了，谢谢你的信任"
   - 订阅满一年 → "一年了，我们一起走过了..."

5. **季节性问候**
   - 春节："新年快乐，你的新年运势..."
   - 中秋："月圆人团圆，今晚的月亮对你的影响..."

---

## 8. 实施路线图

### Phase 1 (Week 1-2): 核心流程

```
前端
├── [ ] www.vibelife.app 品牌首页
├── [ ] 子站 Landing Page (bazi/zodiac)
├── [ ] 30秒 Aha Moment 流程
├── [ ] 自适应访谈组件
├── [ ] "来自未来的信" 组件
└── [ ] 付费墙组件

后端
├── [ ] 访谈问题生成 API
├── [ ] "来自未来的信" 生成 API
├── [ ] 报告生成 API
└── [ ] 访客用户状态管理

数据追踪
├── [ ] 漏斗埋点
├── [ ] Aha Moment 时间追踪
└── [ ] 转化率追踪
```

### Phase 2 (Week 3-4): 主动推送

```
后端
├── [ ] 推送类型定义
├── [ ] 推送调度器
├── [ ] 智能触发逻辑
└── [ ] 推送模板管理

前端
├── [ ] 聊天界面推送展示
├── [ ] 推送通知 Hook
└── [ ] 推送设置页面
```

### Phase 3 (Week 5-6): 优化迭代

```
数据分析
├── [ ] 漏斗分析
├── [ ] 推送效果分析
└── [ ] 用户反馈收集

优化
├── [ ] 访谈问题优化
├── [ ] "来自未来的信" 模板优化
├── [ ] 推送时机优化
└── [ ] 转化率优化
```

---

## 9. 成功指标

### 9.1 核心 KPI

| 指标 | 目标 | 计算方式 |
|------|------|----------|
| Time to Aha | < 30秒 | 首次进入到看到命盘的时间 |
| Aha 完成率 | > 70% | 进入用户中看到命盘的比例 |
| 访谈完成率 | > 50% | 开始访谈的用户中完成的比例 |
| 信阅读率 | > 80% | 生成信的用户中阅读的比例 |
| 转化率 | > 5% | 看到信的用户中付费的比例 |
| 日活留存 | > 40% | 次日返回的用户比例 |
| 推送点击率 | > 30% | 收到推送后点击的比例 |

### 9.2 健康度指标

| 指标 | 健康范围 | 预警线 |
|------|----------|--------|
| Free-to-Paid 转化 | 3-8% | < 2% |
| 付费用户留存 | > 60% | < 40% |
| 推送打开率 | > 25% | < 15% |
| NPS | > 40 | < 20 |

---

## 10. 总结

这份用户流程设计方案综合了：
1. **品牌沉浸式入口**：World class 高级感
2. **30秒 Aha Moment**：快速价值交付
3. **个性化深度访谈**：LLM 实时生成触动人心的问题
4. **"来自未来的信"**：情感高潮，免费完整展示
5. **主动推送系统**：核心差异化，让用户感受被关心

实施后预期：
- 首次访问到 Aha Moment：< 30秒
- 访谈完成率：> 50%
- 付费转化率：> 5%
- 日活留存：> 40%

---

*文档由深度访谈综合设计，如需修改请继续讨论。*
