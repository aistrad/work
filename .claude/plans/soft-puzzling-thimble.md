# VibeLife Landing Page 配色方案升级计划

## 一、升级目标

基于深度访谈结论，本次配色升级需达成：

1. **保持温暖人文基调** — 道林纸质感背景不变
2. **强调色从陶土红 → 高级灰棕** — 更内敛、更 Linear 风格
3. **12原型饱和度提升 10-15%** — 保持 Morandi 灰调但更"可见"
4. **增加层次感** — 通过更强的明暗对比解决"太平"的问题

---

## 二、配色系统升级方案

### 2.1 强调色系统 (核心变更)

| 变量 | 当前值 | 升级值 | 说明 |
|------|--------|--------|------|
| `--accent-primary` | #E16259 (陶土红) | **#7A6B5A** (高级灰棕) | CTA、链接、焦点 |
| `--accent-hover` | #C94D44 | **#6B5C4B** | hover 状态 |
| `--accent-active` | - | **#5C4D3C** | 点击态 |
| `--accent-muted` | #F5E6E4 | **rgba(122,107,90,0.08)** | 淡化背景 |
| `--focus-ring` | rgba(225,98,89,0.3) | **rgba(122,107,90,0.3)** | 焦点环 |

### 2.2 12原型配色 (饱和度提升)

当前 Morandi 版本 → 提升约 12% 饱和度：

| 原型 | 当前值 | 升级值 | 渐变终点 |
|------|--------|--------|----------|
| Innocent | #F5C6C6 | **#F2B8B8** | #FDF0F0 |
| Sage | #9B8AA6 | **#9480A8** | #E8E0EB |
| Explorer | #8FBFC9 | **#7DB8C5** | #E4F2F5 |
| Outlaw | #A65D5D | **#A8524F** | #E8D5D5 |
| Magician | #8B7BA8 | **#8570AB** | #E0DAE8 |
| Hero | #D4736C | **#D46560** | #F5E0DE |
| Lover | #D4899A | **#D47D90** | #F5E6EA |
| Jester | #E5B86D | **#E5AD58** | #FAF0DD |
| Regular | #7DA07D | **#6F9A6F** | #E2EFE2 |
| Caregiver | #8FC9A0 | **#80C494** | #E5F5EA |
| Ruler | #C9A66B | **#C99D58** | #F7F0E0 |
| Creator | #6B9BC3 | **#5C94C3** | #E0ECF5 |

### 2.3 背景与层次增强

保持当前背景系统，增加对比层次：

| 变量 | 值 | 用途 |
|------|------|------|
| `--bg-primary` | #F9F9F7 (保持) | 主背景 |
| `--bg-secondary` | **#F2F1EE** (从 v7.1 引入) | 次级面板、section 交替 |
| `--bg-tertiary` | **#ECEAE6** (新增) | 更深层级、对比区域 |
| `--bg-elevated` | #FFFFFF (保持) | 卡片/浮层 |

### 2.4 神秘感元素 (可选增强)

引入 mystic 色系作为辅助强调：

| 变量 | 值 | 用途 |
|------|------|------|
| `--mystic-500` | #8E7FA0 | Orb 光晕、心理学 section |
| `--mystic-300` | #D2CBDC | 淡化装饰 |
| `--shadow-glow` | 0 0 20px rgba(142,127,160,0.15) | 神秘光晕效果 |

---

## 三、待修改文件清单

### 主要文件 (3 个)

1. **`/home/aiscend/work/vibelife/docs/prd/landingpage/LandingPage-Design-v1.md`**
   - 更新 1.1 配色方案 CSS 变量定义
   - 更新 12原型卡片数据中的 color 和 gradient 字段

2. **`/home/aiscend/work/vibelife/docs/prd/landingpage/LandingPage-Components.md`**
   - 更新全局 CSS Variables 定义
   - 更新 ARCHETYPE_CARDS_DATA 中的 color 和 gradient

3. **`/home/aiscend/work/vibelife/docs/prd/landingpage/LandingPage-Assets.md`**
   - 更新十二、配色速查表 (v7.1) 部分
   - 确保与升级方案一致

---

## 四、升级后配色对照

```
视觉效果对比：

【升级前】                    【升级后】
陶土红 #E16259 (鲜艳)    →   灰棕 #7A6B5A (内敛)
├─ 热情、活力                 ├─ 沉稳、高级
├─ 视觉冲击强                 ├─ 与背景融合度高
└─ 明显的色彩跳跃             └─ 整体更和谐统一

原型色 (低饱和)           →   原型色 (中饱和)
├─ #F5C6C6 Innocent          ├─ #F2B8B8 (+12%)
├─ 太淡、辨识度低             ├─ 清晰可见、仍保灰调
└─ hover 才显色               └─ 默认即有存在感
```

---

## 五、验证清单

升级完成后需验证：

1. [ ] 所有 CSS 变量在三份文档中定义一致
2. [ ] 12原型的 color 和 gradient 字段已更新
3. [ ] CTA 按钮样式使用新强调色
4. [ ] WCAG AA 对比度检查通过
5. [ ] 配色速查表与实际变量一致

---

## 六、未解决问题

1. **神秘紫的具体使用场景** — 需要在实现时决定是否在心理学 section 或 Orb 上使用
2. **品牌辨识符号** — 用户选择暂不设计，后续可单独讨论
3. **深色 Section 变体** — 可考虑后续版本增加深色背景 section 增强节奏感
