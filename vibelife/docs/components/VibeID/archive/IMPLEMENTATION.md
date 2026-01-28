# Vibe ID 实现计划

> Version: 7.0 | 2026-01-18

---

## 概述

本文档定义 Vibe ID v7.0 重构的实现计划，包括文件清单、实现顺序和验收标准。

## 实现范围

### 核心功能

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 极简创建流程 | P0 | 无登录，3分钟完成 |
| 新数据结构 | P0 | v7.0 完整画像 |
| 分享卡片生成 | P0 | 服务端渲染 |
| 分享落地页 | P0 | 裂变入口 |
| localStorage 暂存 | P0 | 无登录体验 |
| 注册后认领 | P1 | 数据迁移 |
| 配��功能 | P1 | 关系匹配 |
| 多样式卡片 | P2 | dark/gradient/minimal |

---

## 文件清单

### 后端 (apps/api/)

#### 新增文件

```
skills/vibe_id/
├── services/
│   ├── identity_engine.py      # 身份计算引擎 (新)
│   ├── card_renderer.py        # 分享卡片渲染 (新)
│   ├── match_engine.py         # 配对引擎 (新)
│   ├── tag_generator.py        # 标签生成器 (新)
│   └── share_code.py           # 分享码生成 (新)
├── assets/
│   ├── fonts/
│   │   ├── NotoSansSC-Bold.ttf
│   │   ├── NotoSansSC-Medium.ttf
│   │   ├── NotoSansSC-Regular.ttf
│   │   └── NotoColorEmoji.ttf
│   ├── logo.png
│   └── logo-white.png
└── data/
    └── archetypes_v7.yaml      # 原型元数据 (升级)
```

#### 修改文件

```
skills/vibe_id/
├── SKILL.md                    # 更新定义
├── models.py                   # 新数据模型
├── config.py                   # 配置更新
├── services/
│   ├── service.py              # 主服务重构
│   ├── fusion_engine.py        # 扩展融合算法
│   ├── explainer.py            # 扩展解释生成
│   └── config_loader.py        # 配置加载更新
└── tools/
    └── handlers.py             # 工具处理器更新

routes/
└── vibe_id.py                  # API 路由重构
```

### 前端 (apps/web/)

#### 新增文件

```
app/vibe-id/
├── page.tsx                    # 主页
├── create/
│   └── page.tsx                # 创建页
├── [shareCode]/
│   └── page.tsx                # 分享落地页
└── match/
    └── page.tsx                # 配对页

skills/vibe-id/
├── components/
│   ├── VibeIDCreator.tsx       # 创建组件
│   ├── VibeIDMini.tsx          # 迷你卡片
│   ├── ShareCard.tsx           # 分享卡片预览
│   ├── ShareButton.tsx         # 分享按钮
│   ├── ShareMenu.tsx           # 分享菜单
│   ├── TagCloud.tsx            # 标签云
│   ├── GrowthCard.tsx          # 成长方向卡片
│   ├── RelationshipCard.tsx    # 关系倾向卡片
│   ├── MatchResult.tsx         # 配对结果
│   ├── BirthInfoForm.tsx       # 出生信息表单
│   └── LoadingAnimation.tsx    # 加载动画
├── hooks/
│   ├── useVibeIDCreate.ts      # 创建流程
│   ├── useVibeIDShare.ts       # 分享功能
│   ├── useVibeIDMatch.ts       # 配对功能
│   └── useVibeIDLocal.ts       # localStorage 管理
└── constants/
    └── archetypes.ts           # 原型元数据

types/
└── vibe-id.ts                  # TypeScript 类型
```

#### 修改文件

```
skills/vibe-id/
├── components/
│   ├── VibeIDCard.tsx          # 升级支持新数据结构
│   ├── ArchetypeRadar.tsx      # 样式优化
│   └── DimensionRow.tsx        # 样式优化
├── hooks/
│   └── useVibeID.ts            # 升级
├── tools/
│   └── show-vibe-id.tsx        # 升级
└── index.ts                    # 导出更新

app/onboarding/
├── steps/
│   ├── LandingStep.tsx         # 集成 Vibe ID 创建
│   └── AhaStep.tsx             # 展示 Vibe ID 结果
└── context.tsx                 # 状态管理更新
```

---

## 实现顺序

### Phase 1: 基础架构 (Day 1-2)

```
1.1 数据模型
    ├── [ ] 创建 types/vibe-id.ts (TypeScript 类型)
    ├── [ ] 更新 skills/vibe_id/models.py (Python 模型)
    └── [ ] 更新 skills/vibe_id/data/archetypes_v7.yaml

1.2 后端服务
    ├── [ ] 创建 services/identity_engine.py
    ├── [ ] 创建 services/tag_generator.py
    ├── [ ] 创建 services/share_code.py
    ├── [ ] 重构 services/service.py
    └── [ ] 扩展 services/fusion_engine.py

1.3 API 路由
    └── [ ] 重构 routes/vibe_id.py
        ├── POST /create
        ├── GET /
        ├── GET /preview
        └── POST /recalculate
```

### Phase 2: 分享卡片 (Day 3-4)

```
2.1 卡片渲染
    ├── [ ] 准备字体文件
    ├── [ ] 准备静态资源 (logo, backgrounds)
    ├── [ ] 创建 services/card_renderer.py
    └── [ ] 实现 default 样式渲染

2.2 API 端点
    ├── [ ] GET /card/{share_code}.png
    └── [ ] POST /card/generate

2.3 前端组件
    ├── [ ] 创建 ShareCard.tsx
    ├── [ ] 创建 ShareButton.tsx
    └── [ ] 创建 ShareMenu.tsx
```

### Phase 3: 创建流程 (Day 5-6)

```
3.1 前端页面
    ├── [ ] 创建 app/vibe-id/page.tsx
    ├── [ ] 创建 app/vibe-id/create/page.tsx
    └── [ ] 创建 app/vibe-id/[shareCode]/page.tsx

3.2 组件
    ├── [ ] 创建 VibeIDCreator.tsx
    ├── [ ] 创建 BirthInfoForm.tsx
    ├── [ ] 创建 LoadingAnimation.tsx
    └── [ ] 升级 VibeIDCard.tsx

3.3 Hooks
    ├── [ ] 创建 useVibeIDCreate.ts
    ├── [ ] 创建 useVibeIDLocal.ts
    └── [ ] 升级 useVibeID.ts
```

### Phase 4: 裂变功能 (Day 7-8)

```
4.1 分享落地页
    ├── [ ] 完善 app/vibe-id/[shareCode]/page.tsx
    └── [ ] 实现邀请人信息展示

4.2 分享功能
    ├── [ ] 创建 useVibeIDShare.ts
    ├── [ ] 实现微信分享
    ├── [ ] 实现微博分享
    └── [ ] 实现链接复制

4.3 邀请追踪
    ├── [ ] GET /invite/{share_code}
    └── [ ] 邀请计数更新
```

### Phase 5: 配对功能 (Day 9-10)

```
5.1 后端
    ├── [ ] 创建 services/match_engine.py
    └── [ ] POST /match

5.2 前端
    ├── [ ] 创建 app/vibe-id/match/page.tsx
    ├── [ ] 创建 MatchResult.tsx
    └── [ ] 创建 useVibeIDMatch.ts
```

### Phase 6: 集成优化 (Day 11-12)

```
6.1 Onboarding 集成
    ├── [ ] 修改 LandingStep.tsx
    └── [ ] 修改 AhaStep.tsx

6.2 注册认领
    ├── [ ] POST /claim
    └── [ ] 注册流程集成

6.3 其他组件
    ├── [ ] 创建 TagCloud.tsx
    ├── [ ] 创建 GrowthCard.tsx
    └── [ ] 创建 RelationshipCard.tsx

6.4 多样式卡片
    ├── [ ] 实现 dark 样式
    ├── [ ] 实现 gradient 样式
    └── [ ] 实现 minimal 样式
```

---

## 验收标准

### P0 功能验收

| 功能 | 验收标准 |
|------|----------|
| 极简创建 | 输入生日+时间，3秒内返回结果 |
| 无登录体验 | 不登录可完成创建和查看 |
| 数据结构 | 包含 identity, dimensions, scores, tags, relationship, growth |
| 分享卡片 | 生成 750x1334 PNG，包含原型、标语、标签、二维码 |
| 分享落地页 | 展示邀请人信息，引导创建 |
| localStorage | 数据保存7天，注册后可迁移 |

### P1 功能验收

| 功能 | 验收标准 |
|------|----------|
| 注册认领 | 注册后自动迁移 localStorage 数据 |
| 配对功能 | 计算匹配度，展示优势/挑战/建议 |
| 邀请追踪 | 记录邀请来源，统计邀请人数 |

### P2 功能验收

| 功能 | 验收标准 |
|------|----------|
| 多样式卡片 | 支持 default/dark/gradient/minimal 四种样式 |
| 小红书优化 | minimal 样式为 1080x1080 正方形 |

---

## 测试计划

### 单元测试

```python
# tests/test_vibe_id_v7.py

class TestVibeIDService:
    async def test_create_vibe_id(self):
        """测试创建 Vibe ID"""
        pass

    async def test_generate_share_code(self):
        """测试分享码生成"""
        pass

    async def test_card_render(self):
        """测试卡片渲染"""
        pass

class TestMatchEngine:
    async def test_calculate_match(self):
        """测试配对计算"""
        pass
```

### E2E 测试

```typescript
// tests/vibe-id.spec.ts

test('创建 Vibe ID 流程', async ({ page }) => {
  await page.goto('/vibe-id/create')
  await page.fill('[name="birth_date"]', '1990-05-15')
  await page.fill('[name="birth_time"]', '08:30')
  await page.click('button[type="submit"]')
  await expect(page.locator('.vibe-id-card')).toBeVisible()
})

test('分享落地页', async ({ page }) => {
  await page.goto('/vibe-id/VB7X9K')
  await expect(page.locator('.inviter-info')).toBeVisible()
  await page.click('button:has-text("测测我的 Vibe")')
  await expect(page).toHaveURL('/vibe-id/create')
})
```

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 字体文件过大 | 卡片渲染慢 | 使用子集化字体 |
| 分享码碰撞 | 数据覆盖 | 生成前检查唯一性 |
| localStorage 丢失 | 用户数据丢失 | 提示用户注册保存 |
| 微信分享限制 | 无法直接分享 | 引导保存图片后分享 |

---

## 依赖项

### Python 依赖

```
Pillow>=10.0.0
qrcode>=7.4.0
```

### 字体文件

- Noto Sans SC (Google Fonts, OFL License)
- Noto Color Emoji (Google Fonts, OFL License)

---

## 回滚计划

如果 v7.0 出现严重问题：

1. 保留 v6.0 代码在 `skills/vibe_id_v6/` 目录
2. API 路由支持版本切换
3. 前端通过 feature flag 控制版本

```python
# 版本切换
VIBE_ID_VERSION = os.getenv("VIBE_ID_VERSION", "7.0")

if VIBE_ID_VERSION == "6.0":
    from skills.vibe_id_v6 import VibeIDService
else:
    from skills.vibe_id import VibeIDService
```
