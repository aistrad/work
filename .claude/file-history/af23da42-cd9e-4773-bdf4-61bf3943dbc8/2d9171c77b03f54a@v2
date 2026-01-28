# VIBELIFE_TOPLEVEL_ARCHITECTURE.md 修改计划

## 执行摘要

简洁调整架构文档的 Skills 分类和 VibeTarget 数据来源说明：
1. jungastro: "西方占星" → "自我认知"（符合其心理学定位）
2. 删除 vibe_insight（系统功能，非对外 skill），保留 vibe_id
3. 补充 VibeTarget 的 north_star 数据结构和来源说明（协议流程 + 对话抽取）

**影响范围**: 4 个文档位置，纯架构文档修改，无代码变更

## 核心理解

### 当前分类问题
- **jungastro**: 定位是"心理占星分析师"，基于荣格心理学框架，核心是自我认知而非占星预测。当前归类在"西方占星"下不准确。
- **vibe_insight**: 是 VibeProfile 的系统功能，用于生成跨维度人格洞察。已有独立的 vibe_id skill 提供对外的人格分析服务。

### VibeTarget 数据来源
当前文档仅说明"来源：对话抽取"，但实际应包含：
- **对话抽取**: ProfileExtractor 自动识别用户目标
- **专门流程**: lifecoach 协议流程生成的 north_star（包含愿景场景、反愿景、目标等）

参考 lifecoach 的 north_star 结构：
```json
{
  "pain_points": ["用户痛点"],
  "anti_vision_scene": "不想要的未来场景",
  "vision_scene": "想要的未来场景",
  "vision_timeframe": "3年后"
}
```

## 修改位置

### 位置1: Skills 分类 (第 32-77 行)

**修改前**:
```
│  西方占星
│  ├─ zodiac: 西方占星（星盘、行运）
│  └─ jungastro: 荣格占星（心理学视角）
│  ─────────────────────────────────────────────────────────┤
│  直觉洞察
│  └─ tarot: 塔罗占卜（当下指引）
│  ─────────────────────────────────────────────────────────┤
│  职业发展
│  └─ career: 职业规划（人岗匹配）
│  ─────────────────────────────────────────────────────────┤
│  自我认知
│  └─ vibe_insight: 人格画像（跨维度融合）
```

**修改后**:
```
│  西方占星
│  └─ zodiac: 西方占星（星盘、行运）
│  ─────────────────────────────────────────────────────────┤
│  直觉洞察
│  └─ tarot: 塔罗占卜（当下指引）
│  ─────────────────────────────────────────────────────────┤
│  职业发展
│  └─ career: 职业规划（人岗匹配）
│  ─────────────────────────────────────────────────────────┤
│  自我认知
│  ├─ vibe_id: 人格画像（东西方融合）
│  └─ jungastro: 荣格占星（心理学视角）
```

**变更说明**:
- jungastro 移至"自我认知"分类
- vibe_insight 删除，替换为实际对外的 vibe_id skill
- 保持分类层级结构一致

### 位置2: VibeTarget 数据来源 (第 251 行)

**修改前**:
```
│  │   来源：对话抽取（用户明确表达的愿望/计划）               │     │
```

**修改后**:
```
│  │   来源：对话抽取 + 专门协议流程                           │     │
│  │   • 对话抽取：ProfileExtractor 自动识别用户目标           │     │
│  │   • 专门流程：协议生成 north_star（lifecoach/mindfulness 等）│     │
│  │     包含愿景场景/反愿景/痛点/身份等结构化目标数据          │     │
```

### 位置3: VibeTarget 数据来源说明 (第 328-332 行)

**修改前**:
```
│  数据来源：                                                       │
│  • 对话抽取：ProfileExtractor 自动识别用户目标                   │
│  • 用户手动：VibeTarget 页直接添加                               │
│  • Lifecoach 对话：深度教练后确认的目标                          │
```

**修改后**:
```
│  数据来源：                                                       │
│  • 专门协议：协议流程生成 north_star（优先级最高）               │
│    - 如 lifecoach 的 6 问协议、mindfulness 的目标设定协议等       │
│    - 包含愿景场景、反愿景、痛点、身份宣言等结构化数据            │
│    - north_star 直接存入 VibeTarget，无需转换                   │
│  • 对话抽取：ProfileExtractor 自动识别用户明确表达的愿望/计划    │
│  • 用户手动：VibeTarget 页直接添加目标                           │
```

### 位置4: VibeTarget 数据结构示例 (第 419-441 行)

在 `vibe_target` 数据结构中增加 `north_star` 字段：

**修改前**:
```json
  "vibe_target": {
    "goals": [...],
    "focus": {...},
    "milestones": {...},
    "updated_at": "2026-01-21T03:00:00Z"
  }
```

**修改后**:
```json
  "vibe_target": {
    "north_star": {
      "vision_scene": "3年后的理想场景描述",
      "anti_vision_scene": "不想要的未来场景",
      "pain_points": ["持续的不满1", "持续的不满2"],
      "vision_timeframe": "3年后",
      "source": "lifecoach"
    },
    "goals": [...],
    "focus": {...},
    "milestones": {...},
    "updated_at": "2026-01-21T03:00:00Z"
  }
```

**修改前**:
```
│  数据来源：                                                       │
│  • 对话抽取：ProfileExtractor 自动识别用户目标                   │
│  • 用户手动：VibeTarget 页直接添加                               │
│  • Lifecoach 对话：深度教练后确认的目标                          │
```

**修改后**:
```
│  数据来源：                                                       │
│  • 专门协议：协议流程生成 north_star（优先级最高）               │
│    - 如 lifecoach 的 6 问协议、mindfulness 的目标设定协议等       │
│    - 包含愿景场景、反愿景、痛点、身份宣言等结构化数据            │
│    - north_star 直接存入 VibeTarget，无需转换                   │
│  • 对话抽取：ProfileExtractor 自动识别用户明确表达的愿望/计划    │
│  • 用户手动：VibeTarget 页直接添加目标                           │
```

## 验证要点

- [ ] Skills 分类层级保持清晰，每个分类下至少有 1 个 skill
- [ ] jungastro 在"自我认知"下，与 vibe_id 并列
- [ ] vibe_insight 完全移除，不再出现在 Skills 列表中
- [ ] "西方占星"分类下只剩 zodiac 一个 skill
- [ ] VibeTarget 数据来源清晰说明两种方式：专门协议 + 对话抽取
- [ ] VibeTarget 数据结构包含 north_star 字段示例
- [ ] 文档整体结构和版本号保持不变（Version 11.3 | 2026-01-21）
- [ ] 所有修改位置的 ASCII 框图格式保持一致

## 实施细节

### 文档风格保持
- 使用 UTF-8 Box Drawing Characters (│ ├ └ ┌ ┐ 等)
- Skills 分类使用层级缩进
- 每个修改点保持原文档的缩进和对齐格式

### 关键概念统一
- north_star: 愿景数据结构（来自协议流程）
- goals: 具体目标列表（来自对话抽取/手动添加）
- vibe_id: 对外 skill（用户可调用）
- vibe_insight: 系统功能（ProfileExtractor 生成）

## 设计决策（已确认）

✅ **vibe_id vs vibe_insight**:
- vibe_id: 对外的 skill，用户可调用
- vibe_insight: 系统内部功能，ProfileExtractor 生成的跨维度洞察

✅ **north_star 来源**: 可来自多个协议流程（lifecoach、mindfulness、career 等），不限于 lifecoach

✅ **数据同步**: north_star 直接作为 VibeTarget 的一部分存储，无需转换
