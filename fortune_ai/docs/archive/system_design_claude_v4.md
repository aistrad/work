# Fortune AI 系统架构设计 v4（基于 idea1.md 深度研究）

**文档类型**：System Design Evolution
**版本**：v4.0
**日期**：2025-12-30
**定位**：基于 Final MVP 的功能扩展与架构优化
**核心理念**：将"赛博玄学"作为低阻力入口，通过"翻译层"将玄学术语转化为积极心理学干预，实现"导航→陪伴→提升"闭环

---

## 0. 进化摘要

### 0.1 从 MVP 到 v4 的关键升级

| 维度 | Final MVP | v4 Evolution |
|------|-----------|--------------|
| 核心闭环 | Clarify→Insight→Prescription→Commitment | **CIA+R**: Clarify→Insight→Action→Reflection（完整心理干预闭环）|
| 玄学定位 | 八字事实+知识库检索 | **翻译层**：玄学术语→积极心理学干预（特洛伊木马策略）|
| 游戏化 | 无 | **Aura Points 能量积分系统**（行为即挖矿）|
| 社交 | 无 | **金星网络**：合盘、能量圈、业力伙伴 |
| 内容节奏 | 4个预设计划 | **东方节律引擎**：24节气+流年+天象自动内容生成 |
| 情绪工具 | 情绪打卡 | **情绪DNA + 阴影工作坊**（深度心理探索）|
| 病毒传播 | 无 | **Cosmic Roast 毒舌解读**（高传播性内容生成）|

### 0.2 新增功能模块总览

```
Fortune AI v4 功能架构
├── 【核心层】CIA+R 闭环引擎
│   ├── Clarify Engine（澄清引擎：情绪识别+玄学语境接纳）
│   ├── Insight Engine（洞察引擎：翻译层+认知重构）
│   ├── Action Engine（行动引擎：仪式化微干预）
│   └── Reflection Engine（反思引擎：成长追踪+闭环验证）
│
├── 【游戏化层】Aura Points 能量系统
│   ├── 正念挖矿（冥想/呼吸积分）
│   ├── 仪式点击（电子木鱼+颂钵）
│   ├── 行为激励（任务完成+连胜）
│   └── 业力账本（PostgreSQL Ledger）
│
├── 【社交层】金星网络
│   ├── 动态合盘（星盘×MBTI 交叉分析）
│   ├── 关系预警（行运触发社交建议）
│   ├── 能量圈（Coven 私密小组）
│   └── 业力伙伴发现（递归关系图谱）
│
├── 【内容层】东方节律引擎
│   ├── 24节气自动内容生成
│   ├── 流年大运触发器
│   ├── 个人纪念日关怀
│   └── 天象事件响应（水逆/满月等）
│
├── 【深度心理层】阴影工作坊
│   ├── 情绪DNA 人格画像
│   ├── 阴影日记（荣格心理学）
│   ├── 认知重构练习
│   └── 自我同情训练
│
└── 【传播层】病毒内容引擎
    ├── Cosmic Roast（毒舌解读）
    ├── Bento Grid 愿景板生成
    ├── Aura Filter（能量滤镜）
    └── 打卡挑战生成器
```

---

## 1. 核心理论框架：翻译层（Translation Matrix）

### 1.1 特洛伊木马策略

用户入口是"低阻力的玄学"，但内核是"高价值的心理干预"：

```
用户语言（玄学）→ 翻译层 → 心理学干预 → 行动处方
```

**关键原则**：
1. **不否定玄学**：先在玄学语境下"积极倾听"，建立治疗联盟
2. **隐喻转化**：将玄学概念转化为心理动力学描述
3. **行动落地**：将"开运仪式"包装为行为激活任务

### 1.2 玄学-心理学映射词典（Translation Matrix）

| 玄学概念 | 传统含义 | 心理学重构 | 干预策略 |
|---------|---------|-----------|---------|
| 七杀 | 动荡、压力、小人 | 高唤醒状态 + 攻击性驱力 | 升华：高强度运动或攻克难关 |
| 伤官 | 叛逆、才华横溢但傲慢 | 创造性不从众 + 未被满足的认可需求 | 心流体验：无评价的创造性活动 |
| 劫财 | 破财、被背叛、竞争 | 边界模糊 + 社交比较 | 自我关怀 + 边界确立 |
| 水星逆行 | 沟通失效、设备故障 | 认知过载 + 注意力缺陷 | 正念暂停 + STOP 技术 |
| 桃花 | 异性缘、滥情 | 亲和需求 + 多巴胺活跃 | 积极建设性回应 + 深度倾听 |
| 土星回归 | 27-30岁人生转折 | 成年初显期责任危机 | 生命OKR + 严厉的爱通知 |
| 显化 | 吸引力法则 | 自我实现的预言 + RAS激活 | WOOP思维工具 |
| 华盖 | 孤独、艺术天赋 | 内向型创造力 + 需要独处充电 | 独处仪式 + 创作任务 |

### 1.3 数据库扩展：翻译层表

```sql
CREATE TABLE IF NOT EXISTS fortune_translation_matrix (
  id BIGSERIAL PRIMARY KEY,
  metaphysics_concept TEXT NOT NULL,        -- 玄学概念（如"七杀"）
  metaphysics_category TEXT NOT NULL,       -- 类别（bazi_shishen/shensha/transit）
  traditional_meaning TEXT NOT NULL,        -- 传统含义
  psych_reframe TEXT NOT NULL,             -- 心理学重构
  psych_category TEXT NOT NULL,            -- 心理学类别（CBT/SFBT/positive_psych）
  intervention_strategy TEXT NOT NULL,      -- 干预策略
  intervention_examples JSONB NOT NULL,     -- 示例话术和任务
  embedding Vector(1536),                   -- 语义向量（用于RAG检索）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (metaphysics_concept, metaphysics_category)
);

CREATE INDEX IF NOT EXISTS idx_translation_matrix_category
  ON fortune_translation_matrix (metaphysics_category);
CREATE INDEX IF NOT EXISTS idx_translation_matrix_embedding
  ON fortune_translation_matrix USING ivfflat (embedding vector_cosine_ops);
```

---

## 2. 游戏化层：Aura Points 能量系统

### 2.1 设计原理

借鉴"电子木鱼"的成瘾机制，建立完整的内部经济系统。积分获取必须通过"有意义的精神劳动"，赋予价值感。

### 2.2 积分获取机制

| 行为类别 | 积分规则 | 心理学依据 |
|---------|---------|-----------|
| 正念挖矿 | 冥想1分钟 = 10 Aura | 专注力训练奖励 |
| 仪式点击 | 木鱼/颂钵点击 = 1 Aura（每日上限500）| 重复行为减压 |
| 任务完成 | 每日任务 = 50-100 Aura | 行为激活强化 |
| 连胜奖励 | 连续打卡×天数倍数 | 损失厌恶+习惯养成 |
| 阴影日记 | 每篇 = 80 Aura | 深度自我探索激励 |
| 反思总结 | 周/月复盘 = 200 Aura | 元认知培养 |

### 2.3 积分消耗场景

| 消耗类型 | 积分成本 | 用途 |
|---------|---------|------|
| 主题皮肤 | 500-2000 | 个性化装饰 |
| 深度合盘 | 300 | 关系分析报告 |
| AI提问次数 | 50/次 | 超出免费额度 |
| 连胜修复 | 200 | 恢复中断的打卡 |
| 能量抵押 | 可变 | 目标承诺机制 |

### 2.4 数据库设计：业力账本（Ledger Pattern）

```sql
CREATE TABLE IF NOT EXISTS fortune_aura_ledger (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit')),
  amount INTEGER NOT NULL CHECK (amount > 0),
  source TEXT NOT NULL,                    -- 来源（mining/ritual/task/purchase/penalty）
  reason TEXT NOT NULL,                    -- 原因描述
  balance_after INTEGER NOT NULL,          -- 交易后余额
  reference_id UUID,                       -- 关联对象ID（task_id/checkin_id等）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_aura_ledger_user_time
  ON fortune_aura_ledger (user_id, created_at DESC);

-- 用户余额缓存视图（物化视图提升查询性能）
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_aura_balance AS
SELECT
  user_id,
  SUM(CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END) AS balance,
  COUNT(*) FILTER (WHERE transaction_type = 'credit') AS total_credits,
  COUNT(*) FILTER (WHERE transaction_type = 'debit') AS total_debits,
  MAX(created_at) AS last_transaction_at
FROM fortune_aura_ledger
GROUP BY user_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_aura_balance_user ON mv_aura_balance (user_id);

-- 仪式点击记录（电子木鱼）
CREATE TABLE IF NOT EXISTS fortune_ritual_tap (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  ritual_type TEXT NOT NULL CHECK (ritual_type IN ('muyu', 'bowl', 'crystal')),
  tap_count INTEGER NOT NULL DEFAULT 1,
  session_duration_seconds INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ritual_tap_user_day
  ON fortune_ritual_tap (user_id, (created_at::date));
```

---

## 3. 社交层：金星网络

### 3.1 动态合盘系统

超越传统静态合盘，引入实时能量共振：

```sql
CREATE TABLE IF NOT EXISTS fortune_synastry (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  partner_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN ('friend', 'partner', 'family', 'colleague')),
  compatibility_score NUMERIC(5,2),        -- 整体匹配度 0-100
  dimension_scores JSONB NOT NULL,         -- 各维度分数（情感/沟通/价值观/成长）
  synastry_aspects JSONB NOT NULL,         -- 星盘相位详情
  mbti_cross_analysis JSONB,               -- MBTI交叉分析（可选）
  last_computed_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, partner_id)
);

-- 关系预警事件
CREATE TABLE IF NOT EXISTS fortune_relationship_alert (
  id BIGSERIAL PRIMARY KEY,
  synastry_id BIGINT NOT NULL REFERENCES fortune_synastry(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN ('transit', 'conflict', 'opportunity')),
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  suggested_action TEXT,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_relationship_alert_valid
  ON fortune_relationship_alert (synastry_id, valid_from, valid_until)
  WHERE acknowledged_at IS NULL;
```

### 3.2 能量圈（Coven）

支持3-5人私密小组，共同显化与状态共享：

```sql
CREATE TABLE IF NOT EXISTS fortune_coven (
  coven_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  intention TEXT NOT NULL,                 -- 共同意图/目标
  created_by BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  max_members INTEGER NOT NULL DEFAULT 5,
  energy_pool INTEGER NOT NULL DEFAULT 0,  -- 公共能量池
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fortune_coven_member (
  coven_id UUID NOT NULL REFERENCES fortune_coven(coven_id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('creator', 'admin', 'member')),
  contribution_points INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (coven_id, user_id)
);

-- 小组共同显化目标
CREATE TABLE IF NOT EXISTS fortune_coven_goal (
  id BIGSERIAL PRIMARY KEY,
  coven_id UUID NOT NULL REFERENCES fortune_coven(coven_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_date DATE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'achieved', 'abandoned')),
  required_energy INTEGER NOT NULL DEFAULT 1000,
  current_energy INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 3.3 业力伙伴发现（递归查询）

利用 PostgreSQL 递归 CTE 发现"朋友的朋友"中的高匹配度用户：

```sql
-- 递归查询示例：发现二阶关系中的潜在业力伙伴
WITH RECURSIVE friend_network AS (
  -- 一阶好友
  SELECT partner_id AS user_id, 1 AS depth
  FROM fortune_synastry
  WHERE user_id = :current_user_id AND relationship_type = 'friend'

  UNION

  -- 二阶好友（朋友的朋友）
  SELECT s.partner_id, fn.depth + 1
  FROM friend_network fn
  JOIN fortune_synastry s ON s.user_id = fn.user_id
  WHERE fn.depth < 2
    AND s.partner_id != :current_user_id
    AND s.relationship_type = 'friend'
)
SELECT DISTINCT fn.user_id, fn.depth,
       -- 计算与当前用户的潜在匹配度（需要调用合盘计算函数）
       u.name, u.bazi_digest
FROM friend_network fn
JOIN fortune_user u ON u.user_id = fn.user_id
WHERE fn.user_id NOT IN (
  SELECT partner_id FROM fortune_synastry WHERE user_id = :current_user_id
)
ORDER BY fn.depth, fn.user_id
LIMIT 10;
```

---

## 4. 内容层：东方节律引擎

### 4.1 24节气自动内容系统

```sql
CREATE TABLE IF NOT EXISTS fortune_solar_term_content (
  id BIGSERIAL PRIMARY KEY,
  solar_term TEXT NOT NULL,                -- 节气名称（立春/雨水/...）
  solar_term_index INTEGER NOT NULL CHECK (solar_term_index BETWEEN 1 AND 24),
  theme TEXT NOT NULL,                     -- 主题（如"播种新计划"）
  psychology_focus TEXT NOT NULL,          -- 心理学关注点
  meditation_guide TEXT,                   -- 冥想引导文本
  ritual_suggestion TEXT,                  -- 仪式建议
  action_prompt TEXT NOT NULL,             -- 行动提示
  avoid_prompt TEXT,                       -- 避免提示
  imagery JSONB,                           -- 意象描述（用于生成）
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (solar_term)
);

-- 预置24节气内容
INSERT INTO fortune_solar_term_content (solar_term, solar_term_index, theme, psychology_focus, action_prompt, avoid_prompt) VALUES
('立春', 1, '万物新生', '目标设定与希望培养', '制定今年的成长目标', '避免延续旧习惯'),
('雨水', 2, '滋润生长', '自我滋养与情感流动', '给自己一个小奖励', '避免压抑情绪'),
('惊蛰', 3, '破土而出', '突破舒适区', '尝试一件新事物', '避免继续拖延'),
('春分', 4, '昼夜平衡', '内在平衡', '进行一次平衡冥想', '避免过度劳累'),
('清明', 5, '清新明朗', '断舍离与清理', '整理物理或心理空间', '避免囤积负面情绪'),
('谷雨', 6, '雨生百谷', '耐心等待', '为目标持续浇水', '避免急于求成'),
('立夏', 7, '万物生长', '能量释放', '进行户外运动', '避免封闭自己'),
('小满', 8, '小有收获', '感恩练习', '记录三件值得感恩的事', '避免贪多'),
('芒种', 9, '播种希望', '行动力启动', '开始一个小项目', '避免只想不做'),
('夏至', 10, '阳气最盛', '表达与展现', '分享你的成果', '避免过度消耗'),
('小暑', 11, '热浪初至', '情绪管理', '练习情绪降温技巧', '避免冲动决策'),
('大暑', 12, '酷暑当头', '耐力与坚持', '给自己设定一个小挑战', '避免放弃'),
('立秋', 13, '秋意初现', '收获盘点', '回顾上半年成果', '避免忽视努力'),
('处暑', 14, '暑气渐消', '过渡与适应', '调整节奏迎接变化', '避免抗拒转变'),
('白露', 15, '露珠晶莹', '细节关注', '完善一个进行中的项目', '避免忽视小事'),
('秋分', 16, '昼夜再平', '关系平衡', '修复一段关系', '避免失衡'),
('寒露', 17, '寒意渐浓', '内省开始', '写一篇自我对话', '避免逃避反思'),
('霜降', 18, '初霜降临', '准备与储备', '为挑战做准备', '避免仓促应对'),
('立冬', 19, '冬季开始', '能量收敛', '减少社交，专注内在', '避免过度消耗'),
('小雪', 20, '初雪飘落', '情绪沉淀', '进行一次阴影工作', '避免压抑'),
('大雪', 21, '大雪纷飞', '深度休息', '给自己一个完整的休息日', '避免透支'),
('冬至', 22, '阴极阳生', '与阴影对话', '接纳自己的不完美', '避免自我批判'),
('小寒', 23, '寒气渐盛', '坚韧培养', '回顾一次克服困难的经历', '避免怀疑自己'),
('大寒', 24, '寒冬最深', '年度复盘', '完成年度成长总结', '避免忘记感恩')
ON CONFLICT (solar_term) DO NOTHING;
```

### 4.2 流年大运触发器

基于用户八字 facts 中的大运流年信息，自动生成个性化内容推送：

```sql
CREATE TABLE IF NOT EXISTS fortune_transit_trigger (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  trigger_type TEXT NOT NULL CHECK (trigger_type IN ('dayun_start', 'liunian_start', 'monthly_pillar', 'chong_tai_sui', 'fan_tai_sui')),
  trigger_date DATE NOT NULL,
  gan_zhi TEXT NOT NULL,                   -- 干支
  psychological_theme TEXT NOT NULL,        -- 心理主题
  guidance_card JSONB,                     -- 生成的指导卡片
  notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, trigger_type, trigger_date)
);

CREATE INDEX IF NOT EXISTS idx_transit_trigger_pending
  ON fortune_transit_trigger (trigger_date, notified_at)
  WHERE notified_at IS NULL;
```

### 4.3 个人纪念日关怀

```sql
CREATE TABLE IF NOT EXISTS fortune_personal_milestone (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  milestone_type TEXT NOT NULL CHECK (milestone_type IN ('birthday', 'anniversary', 'registration', 'custom')),
  milestone_date DATE NOT NULL,
  title TEXT NOT NULL,
  annual_recurrence BOOLEAN NOT NULL DEFAULT TRUE,
  last_celebrated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_personal_milestone_upcoming
  ON fortune_personal_milestone (user_id, milestone_date);
```

---

## 5. 深度心理层：阴影工作坊

### 5.1 情绪DNA人格画像

基于用户交互历史，构建动态心理画像：

```sql
CREATE TABLE IF NOT EXISTS fortune_emotion_dna (
  user_id BIGINT PRIMARY KEY REFERENCES fortune_user(user_id) ON DELETE CASCADE,

  -- 大五人格倾向（0-1）
  openness NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  conscientiousness NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  extraversion NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  agreeableness NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  neuroticism NUMERIC(3,2) NOT NULL DEFAULT 0.5,

  -- 情绪模式
  dominant_emotions JSONB NOT NULL DEFAULT '[]'::jsonb,       -- 主导情绪列表
  emotional_triggers JSONB NOT NULL DEFAULT '[]'::jsonb,      -- 情绪触发因素
  coping_styles JSONB NOT NULL DEFAULT '[]'::jsonb,           -- 应对风格

  -- 成长型/固定型思维倾向（-1到1）
  growth_mindset_score NUMERIC(3,2) NOT NULL DEFAULT 0.0,

  -- 心理资源评估
  self_efficacy_score NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  resilience_score NUMERIC(3,2) NOT NULL DEFAULT 0.5,
  social_support_score NUMERIC(3,2) NOT NULL DEFAULT 0.5,

  -- 命理人格向量（用于匹配）
  fate_vector Vector(256),

  last_computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 5.2 阴影日记系统

基于荣格心理学的阴影整合练习：

```sql
CREATE TABLE IF NOT EXISTS fortune_shadow_journal (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,

  -- 日记内容
  prompt TEXT NOT NULL,                    -- AI提供的提示词
  user_response TEXT NOT NULL,             -- 用户回应

  -- AI分析
  emotion_keywords JSONB,                  -- 情绪关键词提取
  shadow_themes JSONB,                     -- 阴影主题识别
  reframe_suggestion TEXT,                 -- 认知重构建议

  -- 可视化
  emotion_mandala_url TEXT,                -- 生成的情绪曼陀罗图

  -- 积分
  aura_rewarded INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shadow_journal_user_time
  ON fortune_shadow_journal (user_id, created_at DESC);

-- 阴影日记提示词库
CREATE TABLE IF NOT EXISTS fortune_shadow_prompts (
  id BIGSERIAL PRIMARY KEY,
  category TEXT NOT NULL CHECK (category IN ('self_criticism', 'relationship', 'fear', 'desire', 'anger', 'shame')),
  prompt_text TEXT NOT NULL,
  psychological_basis TEXT NOT NULL,       -- 心理学依据
  difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 预置阴影提示词
INSERT INTO fortune_shadow_prompts (category, prompt_text, psychological_basis, difficulty_level) VALUES
('self_criticism', '你最讨厌别人的什么特质？这反映了你被压抑的哪一部分？', '荣格阴影投射理论', 3),
('fear', '如果明天就是世界末日，你今天最后悔没做什么？', '存在主义心理学', 4),
('relationship', '在关系中，你最害怕被发现的一面是什么？', '依恋理论', 4),
('desire', '如果没有任何限制，你最想成为什么样的人？', '自我实现理论', 2),
('anger', '你最近一次感到愤怒是什么时候？愤怒下面藏着什么情绪？', '情绪分层理论', 3),
('shame', '有什么是你从来没有告诉过任何人的？', '脆弱力量理论', 5)
ON CONFLICT DO NOTHING;
```

---

## 6. 传播层：病毒内容引擎

### 6.1 Cosmic Roast（毒舌解读）

利用 LLM 生成极具传播性的"毒舌"报告：

```sql
CREATE TABLE IF NOT EXISTS fortune_cosmic_roast (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,

  -- 解读内容
  roast_text TEXT NOT NULL,                -- 毒舌文案
  roast_level INTEGER NOT NULL CHECK (roast_level BETWEEN 1 AND 10),  -- 辛辣程度

  -- 生成参数
  based_on JSONB NOT NULL,                 -- 基于的数据（八字/行为等）

  -- 分享
  share_image_url TEXT,                    -- 生成的分享图片
  share_count INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Roast 模板库
CREATE TABLE IF NOT EXISTS fortune_roast_templates (
  id BIGSERIAL PRIMARY KEY,
  target_pattern TEXT NOT NULL,            -- 匹配模式（如 "shishen:shangguan"）
  template_text TEXT NOT NULL,             -- 模板文案（含占位符）
  tone TEXT NOT NULL CHECK (tone IN ('playful', 'sarcastic', 'savage')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 6.2 Bento Grid 愿景板生成

```sql
CREATE TABLE IF NOT EXISTS fortune_vision_board (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES fortune_user(user_id) ON DELETE CASCADE,

  -- 内容
  title TEXT NOT NULL,
  grid_layout JSONB NOT NULL,              -- Bento Grid 布局配置
  components JSONB NOT NULL,               -- 各模块内容

  -- 生成结果
  image_url TEXT,
  widget_config JSONB,                     -- iOS/Android 小组件配置

  -- 统计
  view_count INTEGER NOT NULL DEFAULT 0,
  share_count INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## 7. API 扩展设计

### 7.1 翻译层 API

```
POST /api/translate/metaphysics-to-psychology
请求：{"concept": "七杀", "user_context": {...}}
响应：{"reframe": "...", "intervention": "...", "tasks": [...]}
```

### 7.2 游戏化 API

```
GET /api/aura/balance                      # 获取当前积分余额
POST /api/aura/ritual-tap                  # 仪式点击（木鱼/颂钵）
GET /api/aura/ledger?limit=20              # 查看业力账本
POST /api/aura/pledge                      # 能量抵押（目标承诺）
```

### 7.3 社交 API

```
POST /api/synastry/calculate               # 计算合盘
GET /api/synastry/{partner_id}             # 获取合盘结果
GET /api/synastry/alerts                   # 获取关系预警
POST /api/coven/create                     # 创建能量圈
POST /api/coven/{id}/contribute            # 贡献能量
GET /api/karma-partners/discover           # 发现业力伙伴
```

### 7.4 内容节律 API

```
GET /api/rhythm/today                      # 今日节律（节气+天象+个人）
GET /api/rhythm/solar-term/current         # 当前节气内容
GET /api/rhythm/transit/upcoming           # 即将到来的行运事件
```

### 7.5 深度心理 API

```
GET /api/emotion-dna                       # 获取情绪DNA画像
POST /api/shadow/journal                   # 提交阴影日记
GET /api/shadow/prompts                    # 获取今日提示词
POST /api/shadow/reframe                   # 认知重构练习
```

### 7.6 病毒内容 API

```
POST /api/viral/cosmic-roast               # 生成毒舌解读
POST /api/viral/vision-board               # 生成愿景板
GET /api/viral/share-image/{type}/{id}     # 获取分享图片
```

---

## 8. GLM System Prompt 扩展

### 8.1 翻译层增强 Prompt

```text
【翻译层规则（必须遵守）】
1) 当用户使用玄学语言时，先在玄学语境下"积极倾听"建立联盟
2) 使用翻译矩阵将玄学概念转化为心理学术语，但保持神秘感的语言风格
3) 每个玄学概念必须对应一个具体的心理干预策略
4) 禁止宿命论断言；将"预测"转化为"可能性"和"成长契机"
5) 输出的行动建议包装为"开运仪式"或"能量校准"

【翻译示例】
用户："我有七杀焦虑怎么办？"
响应框架：
- 共情接纳："七杀的能量确实带来压力感，这种高强度的驱力正在激活你的战斗模式。"
- 心理重构："从心理学角度，这代表你内在有强烈的成就动机，但可能过度自我要求。"
- 行动处方："将这股能量升华：今天做一个15分钟的高强度运动，或者攻克一个你一直拖延的小任务。"
```

### 8.2 Cosmic Roast Prompt

```text
【Cosmic Roast 角色】
你是一位毒舌但有爱的宇宙真相使者。用幽默、讽刺但不伤害的语言指出用户的痛点。

【规则】
1) 毒舌是为了唤醒，不是伤害
2) 每个批评后必须有建设性的转化
3) 可以调侃行为，但不能否定人格
4) 语言风格参考：犀利的闺蜜吐槽 + 宇宙智慧的高度

【示例】
输入：用户有伤官过旺
输出："你的星盘显示你是个自我表达欲极强的戏精，说白了就是控制不住要展示自己有多聪明。好消息是你确实聪明，坏消息是别人可能已经累了。今日开运任务：闭嘴听别人说完一句话。"
```

---

## 9. 实施路线图

### Phase 1：核心增强（2周）
- 翻译层数据库 + 基础映射词典
- Aura Points 账本系统
- 情绪DNA基础框架

### Phase 2：游戏化上线（2周）
- 仪式点击（电子木鱼）
- 正念挖矿
- 连胜系统

### Phase 3：社交层（3周）
- 合盘计算引擎
- 关系预警系统
- 能量圈功能

### Phase 4：内容节律（2周）
- 24节气内容系统
- 流年触发器
- 个人纪念日

### Phase 5：病毒传播（2周）
- Cosmic Roast 生成
- Bento Grid 愿景板
- 分享图片生成

---

## 10. 技术债务与风险

### 10.1 需要处理的技术点

| 风险点 | 缓解措施 |
|--------|---------|
| pgvector 扩展未安装 | 检查并安装 `CREATE EXTENSION IF NOT EXISTS vector;` |
| 物化视图刷新延迟 | 设置定时任务 `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
| LLM 生成内容不稳定 | 建立内容审核机制 + 敏感词过滤 |
| 游戏化可能导致沉迷 | 实施反依赖机制（每日上限、熔断提醒）|

### 10.2 反依赖设计

```sql
-- 用户使用频次监控
CREATE TABLE IF NOT EXISTS fortune_usage_monitor (
  user_id BIGINT PRIMARY KEY REFERENCES fortune_user(user_id) ON DELETE CASCADE,
  daily_chat_count INTEGER NOT NULL DEFAULT 0,
  daily_divination_count INTEGER NOT NULL DEFAULT 0,
  same_question_streak INTEGER NOT NULL DEFAULT 0,
  last_activity_at TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 熔断规则
-- 同一问题连续问3次 → 强制给行动实验
-- 当日咨询超5次 → 提示"信息足够，先行动"
-- 连续使用超30分钟 → 温柔提醒休息
```

---

## 11. 总结

v4 架构通过引入"翻译层"理念，将 Fortune AI 从单纯的"八字+对话"产品升级为"赛博玄学×积极心理学"的深度心理服务系统。核心创新包括：

1. **特洛伊木马策略**：用玄学作为低阻力入口，内核是科学的心理干预
2. **完整CIA+R闭环**：澄清→洞察→行动→反思，形成真正的成长飞轮
3. **游戏化驱动**：Aura Points 赋予行为价值感，提升用户粘性
4. **社交网络效应**：合盘、能量圈增加关系锁定
5. **自动化内容引擎**：节气+天象+个人节奏，让产品永远有话说
6. **病毒传播基因**：Cosmic Roast等功能天然适合社交分享

这一架构既保持了 Final MVP 的稳健基础，又为产品注入了强大的差异化竞争力和增长潜力。
