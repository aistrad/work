# VibeLife 合盘功能设计方案

> Version: 1.0 | 2026-01-22
> 状态: 待审批

---

## 1. 产品定位

**「合盘」是 VibeLife 的跨 Skill 关系分析功能**，通过融合多维度命理系统（星座、八字、荣格心理占星等），为用户提供全面的关系洞察。

### 1.1 核心价值

| 差异化 | 说明 |
|--------|------|
| **跨维度融合** | 不只是星座配对，而是星座+八字+荣格的多维分析 |
| **多关系类型** | 支持恋爱、亲子、合伙人、朋友等多种关系 |
| **简单易用** | 输入对方生辰即可，无需对方注册 |

### 1.2 用户场景

- 🔥 **恋爱配对**：想了解和 TA 的缘分
- 👨‍👩‍👧 **亲子关系**：理解孩子，改善亲子沟通
- 🤝 **合伙人评估**：找合伙人前先看看合不合
- 👥 **朋友理解**：深入了解朋友的相处模式

---

## 2. 功能设计

### 2.1 用户流程

```
用户说「想看和 TA 的合盘」
    │
    ├─ 检查是否已保存「关系对象」
    │      │
    │      ├─ 有 → 选择已有对象 或 添加新对象
    │      └─ 无 → 收集对方信息
    │
    ▼
CollectSynastryInfoCard（收集对方信息）
    │ 字段：姓名/昵称、关系类型、出生日期、出生时间（可选）、出生地点
    │
    ▼
确认是否保存关系对象？（可选）
    │
    ▼
根据已订阅的 Skill 生成合盘分析
    │
    ├─ ZodiacSynastryCard（星座合盘）
    ├─ BaziSynastryCard（八字合婚）[NEW]
    ├─ JungastroSynastryCard（荣格关系动力）[NEW]
    └─ ... 其他 Skill 合盘
    │
    ▼
AI 综合解读（基于各 Skill 分析结果）
```

### 2.2 关系类型定义

```typescript
type RelationshipType =
  | 'romantic'      // 恋爱/伴侣
  | 'spouse'        // 配偶
  | 'parent_child'  // 亲子
  | 'sibling'       // 兄弟姐妹
  | 'business'      // 合伙人/同事
  | 'friend';       // 朋友
```

### 2.3 新增卡片

| 卡片 | CardType | 说明 |
|------|----------|------|
| CollectSynastryInfoCard | `collect_synastry_info` | 收集对方信息的表单卡片 |
| SelectRelationshipCard | `select_relationship` | 选择已保存的关系对象 |
| BaziSynastryCard | `bazi_synastry` | 八字合婚分析卡片 |
| JungastroSynastryCard | `jungastro_synastry` | 荣格关系分析卡片（复用现有 `jungastro_relationship`） |
| SynastryOverviewCard | `synastry_overview` | 合盘总览卡片（展示综合评分和各维度摘要） |

---

## 3. 数据结构设计

### 3.1 VibeProfile 扩展（存储关系对象）

```yaml
profile:
  # ... 现有字段 ...

  relationships:  # 新增：关系对象列表
    - id: "rel_001"
      name: "小明"
      relationship_type: "romantic"  # 关系类型
      birth_info:
        date: "1990-05-15"
        time: "14:30"           # 可选
        place: "上海"
        timezone: "Asia/Shanghai"
      created_at: "2026-01-22T10:00:00Z"
      last_synastry_at: "2026-01-22T10:30:00Z"
      notes: "大学同学"         # 用户备注
```

### 3.2 合盘结果存储（conversation 级别）

合盘结果不持久化存储，仅存在于会话消息中。用户可通过对话历史回顾。

后期可扩展：将重要合盘结果保存到 `vibe_profile_timeline`。

---

## 4. 技术实现

### 4.1 新增 Skill: synastry

创建 `apps/api/skills/synastry/` 目录：

```
skills/synastry/
├── SKILL.md              # Skill 定义
├── rules/
│   └── synastry-analysis.md  # 合盘分析 SOP
├── tools/
│   ├── tools.yaml        # 工具定义
│   └── handlers.py       # 工具执行器
└── services/
    └── synastry_engine.py  # 合盘计算引擎
```

### 4.2 工具定义 (tools.yaml)

```yaml
version: "1.0"
skill_id: synastry

collect:
  - name: collect_synastry_info
    description: 收集合盘对象的信息
    card_type: collect_synastry_info
    parameters:
      - name: person_name
        type: string
        required: true
      - name: relationship_type
        type: string
        enum: [romantic, spouse, parent_child, sibling, business, friend]
        required: true
      - name: birth_date
        type: string
        format: date
        required: true
      - name: birth_time
        type: string
        format: time
        required: false
      - name: birth_place
        type: string
        required: true

  - name: select_relationship
    description: 选择已保存的关系对象
    card_type: select_relationship

compute:
  - name: calculate_synastry
    description: 计算合盘分析（自动调用各 Skill 的合盘计算）
    parameters:
      - name: person1_id
        type: string
        description: 用户ID或"self"
      - name: person2_birth_info
        type: object
        required: true
      - name: relationship_type
        type: string
        required: true

display:
  - name: show_synastry_overview
    description: 展示合盘总览
    card_type: synastry_overview

  - name: show_zodiac_synastry
    description: 展示星座合盘详情
    card_type: zodiac_synastry

  - name: show_bazi_synastry
    description: 展示八字合婚详情
    card_type: bazi_synastry

  - name: show_jungastro_synastry
    description: 展示荣格关系分析
    card_type: jungastro_synastry

action:
  - name: save_relationship
    description: 保存关系对象到用户档案
    parameters:
      - name: relationship
        type: object
        required: true
```

### 4.3 合盘计算引擎 (synastry_engine.py)

```python
class SynastryEngine:
    """轻度融合的合盘引擎 - 各 Skill 独立计算，最后 AI 综合"""

    async def calculate(
        self,
        user_profile: dict,
        partner_birth_info: dict,
        relationship_type: str,
        subscribed_skills: list[str]
    ) -> SynastryResult:
        results = {}

        # 1. 星座合盘（如果订阅了 zodiac）
        if "zodiac" in subscribed_skills:
            results["zodiac"] = await self._calc_zodiac_synastry(
                user_profile["skills"]["zodiac"]["chart"],
                partner_birth_info
            )

        # 2. 八字合婚（如果订阅了 bazi）
        if "bazi" in subscribed_skills:
            results["bazi"] = await self._calc_bazi_synastry(
                user_profile["skills"]["bazi"]["chart"],
                partner_birth_info
            )

        # 3. 荣格关系分析（如果订阅了 jungastro）
        if "jungastro" in subscribed_skills:
            results["jungastro"] = await self._calc_jungastro_synastry(
                user_profile["skills"]["jungastro"],
                partner_birth_info,
                relationship_type
            )

        # 4. 生成综合评分（取各维度加权平均）
        overview = self._generate_overview(results, relationship_type)

        return SynastryResult(
            overview=overview,
            skill_results=results,
            relationship_type=relationship_type
        )
```

### 4.4 前端卡片

**CollectSynastryInfoCard** - 收集对方信息

```typescript
// apps/web/src/skills/synastry/cards/CollectSynastryInfoCard.tsx
const RELATIONSHIP_OPTIONS = [
  { value: 'romantic', label: '恋人/约会对象', icon: '💕' },
  { value: 'spouse', label: '配偶/伴侣', icon: '💍' },
  { value: 'parent_child', label: '亲子', icon: '👨‍👧' },
  { value: 'sibling', label: '兄弟姐妹', icon: '👫' },
  { value: 'business', label: '合伙人/同事', icon: '🤝' },
  { value: 'friend', label: '朋友', icon: '👥' },
];

// 表单字段：关系类型选择 + 姓名 + 出生信息
```

**BaziSynastryCard** - 八字合婚

```typescript
// apps/web/src/skills/synastry/cards/BaziSynastryCard.tsx
interface BaziSynastryData {
  person1: { name: string; dayMaster: DayMaster; fourPillars: FourPillars };
  person2: { name: string; dayMaster: DayMaster; fourPillars: FourPillars };
  compatibility: {
    overall: number;        // 综合评分
    dayMasterHarmony: number;  // 日主相合
    fiveElementBalance: number; // 五行互补
    tenGodInteraction: number;  // 十神互动
  };
  analysis: {
    strengths: string[];    // 相合之处
    challenges: string[];   // 需要注意
    advice: string[];       // 相处建议
  };
}
```

**SynastryOverviewCard** - 合盘总览

```typescript
// apps/web/src/skills/synastry/cards/SynastryOverviewCard.tsx
interface SynastryOverviewData {
  person1: { name: string };
  person2: { name: string };
  relationshipType: RelationshipType;
  overallScore: number;
  dimensions: Array<{
    skill: string;        // zodiac | bazi | jungastro
    name: string;         // 星座 | 八字 | 荣格
    score: number;
    summary: string;      // 一句话总结
    icon: string;
  }>;
  aiSummary: string;      // AI 综合解读
}
```

---

## 5. 订阅与付费

### 5.1 Skill 层级

```yaml
# skills/synastry/SKILL.md
skill_id: synastry
name: 关系合盘
category: professional  # 需订阅
price_tier: premium     # 高级订阅

dependencies:
  # 至少需要订阅一个命理 Skill 才能使用对应维度的合盘
  optional:
    - zodiac   # 有则显示星座合盘
    - bazi     # 有则显示八字合婚
    - jungastro # 有则显示荣格关系
```

### 5.2 用户权益

| 用户等级 | 合盘功能 |
|---------|---------|
| 免费用户 | 可使用 3 次试用，展示简化结果 |
| Synastry 订阅 | 解锁完整合盘功能 |
| 需额外订阅对应 Skill | 才能看到该维度详情（如八字合婚需订阅 bazi） |

---

## 6. 实现计划

### Phase 1: 核心功能 (MVP)

1. **数据层**
   - [ ] 扩展 VibeProfile 结构，添加 `relationships` 字段
   - [ ] 更新 `UnifiedProfileRepository` 添加关系对象 CRUD

2. **后端**
   - [ ] 创建 `synastry` Skill 目录和配置
   - [ ] 实现 `SynastryEngine` 合盘计算引擎
   - [ ] 实现工具：collect_synastry_info, calculate_synastry
   - [ ] 实现工具：show_synastry_overview, show_zodiac_synastry
   - [ ] 扩展 zodiac 的 synastry 计算（复用现有）

3. **前端**
   - [ ] CollectSynastryInfoCard（收集对方信息）
   - [ ] SelectRelationshipCard（选择已保存对象）
   - [ ] SynastryOverviewCard（合盘总览）
   - [ ] 复用 ZodiacSynastryCard（已有）

### Phase 2: 扩展维度

4. **八字合婚**
   - [ ] 实现 `_calc_bazi_synastry` 计算逻辑
   - [ ] BaziSynastryCard 前端卡片

5. **荣格关系**
   - [ ] 实现 `_calc_jungastro_synastry` 计算逻辑
   - [ ] JungastroSynastryCard（或复用 jungastro_relationship）

### Phase 3: 增强功能

6. **邀请注册**（可选）
   - [ ] 生成邀请链接
   - [ ] 对方注册后自动关联

7. **关系追踪**（后期）
   - [ ] 保存重要合盘到 timeline
   - [ ] 关系阶段变化追踪

---

## 7. 关键文件清单

| 类型 | 文件路径 | 操作 |
|------|---------|------|
| 数据层 | `apps/api/stores/unified_profile_repo.py` | 修改 |
| Skill 配置 | `apps/api/skills/synastry/SKILL.md` | 新增 |
| 工具定义 | `apps/api/skills/synastry/tools/tools.yaml` | 新增 |
| 工具执行器 | `apps/api/skills/synastry/tools/handlers.py` | 新增 |
| 合盘引擎 | `apps/api/skills/synastry/services/synastry_engine.py` | 新增 |
| 前端卡片 | `apps/web/src/skills/synastry/cards/*.tsx` | 新增 |
| 卡片注册 | `apps/web/src/skills/initCards.ts` | 修改 |

---

## 8. 验证计划

1. **单元测试**
   - 合盘计算引擎的各维度计算逻辑
   - 关系对象的存储和读取

2. **集成测试**
   - 完整合盘流程：收集信息 → 计算 → 展示
   - 多关系类型的正确处理

3. **端到端测试**（Playwright）
   - 用户输入对方信息，完成合盘
   - 保存关系对象，下次可选择
   - 订阅权限验证

---

## 9. 未解决问题

1. **八字合婚算法**：是否有现成的算法库，还是需要自研？
2. **荣格关系分析**：如何从单人的心理画像推导两人关系动力？
3. **评分权重**：各维度（星座/八字/荣格）在综合评分中的权重如何分配？
4. **隐私考虑**：存储他人出生信息是否需要额外的隐私声明？

---

## 10. 产品亮点总结

| 亮点 | 说明 |
|------|------|
| 🌟 **跨维度融合** | 业界首个融合东西方命理的合盘系统 |
| 🎯 **多关系场景** | 不只是恋爱，还有亲子、合伙人、朋友 |
| 💾 **关系管理** | 保存重要的人，随时查看合盘 |
| 🤖 **AI 综合解读** | 不只是分数，还有 AI 的深度解读和建议 |
