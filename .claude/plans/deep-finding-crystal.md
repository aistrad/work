# Code Review 修复计划

## 概述
根据代码审查反馈，修复 Soul OS 后端和前端的多个问题。

---

## 1. 后端修复 (`services/soul_os.py`)

### 1.1 L0 翻译键位修复 (line 272)
**问题**: `strength.get("status")` 应该使用 `"level"`
**文件**: `/home/aiscend/work/fortune_ai/services/soul_os.py`
**修改**:
```python
# Before (line 272)
status = strength.get("status", "neutral")

# After
status = strength.get("level", "neutral")
```

### 1.2 神煞名称修复 (lines 114-121)
**问题**: 文档要求 "桃花星" 和 "驿马星"，代码中使用 "桃花" 和 "驿马"
**修改**:
```python
# Before
"桃花": {...},
"驿马": {...},

# After
"桃花星": {...},
"驿马星": {...},
```

### 1.3 State Score 正向情绪计分逻辑修复

**问题**: 当前代码假设 intensity 越高表示负面情绪越强，但对于正向情绪（平静、开心等），高强度应该是好的。

#### 修改点 A: L1 PERMA positive_emotion (lines 323-331)
```python
# Before (line 328)
positive_emotion = {
    "score": round(10 - avg_intensity, 1) if checkins else 5.0,  # 反转：低强度=好
    ...
}

# After - 根据情绪类型决定分数方向
positive_moods = ["平静", "兴奋", "开心", "满足", "感恩"]
negative_moods = ["焦虑", "愤怒", "沮丧", "悲伤", "恐惧"]

# 分别计算正负面情绪的平均强度
positive_checkins = [c for c in checkins if c.get("mood") in positive_moods]
negative_checkins = [c for c in checkins if c.get("mood") in negative_moods]

if positive_checkins:
    pos_avg = sum(c.get("intensity", 5) for c in positive_checkins) / len(positive_checkins)
else:
    pos_avg = 0

if negative_checkins:
    neg_avg = sum(c.get("intensity", 5) for c in negative_checkins) / len(negative_checkins)
else:
    neg_avg = 0

# 正向情绪高强度=加分，负向情绪高强度=扣分
score = pos_avg - neg_avg + 5  # 基线5分，范围0-10
positive_emotion = {
    "score": round(max(0, min(10, score)), 1),
    ...
}
```

#### 修改点 B: State Score emotion_signal (lines 494-497)
```python
# Before
if checkin:
    intensity = int(checkin.get("intensity", 5))
    # 反转：intensity 越高（负面越强）→ 分数越低
    emotion_signal = max(0, (10 - intensity)) * 4

# After - 根据情绪类型决定方向
if checkin:
    mood = checkin.get("mood", "")
    intensity = int(checkin.get("intensity", 5))
    positive_moods = ["平静", "兴奋", "开心", "满足", "感恩"]

    if mood in positive_moods:
        # 正向情绪：强度越高越好
        emotion_signal = intensity * 4
    else:
        # 负向情绪：强度越高越差
        emotion_signal = max(0, (10 - intensity)) * 4
```

---

## 2. 前端修复

### 2.1 布局比例修复 (`dual-core-layout.tsx`)
**文件**: `/home/aiscend/work/fortune_ai/web-app/src/components/layout/dual-core-layout.tsx`
**问题**: DEFAULT_RATIO = 0.5 应该是 0.618 (黄金分割)
**修改** (line 14):
```typescript
// Before
const DEFAULT_RATIO = 0.5  // 聊天区占一半，更均衡

// After
const DEFAULT_RATIO = 0.618  // 黄金分割比例
```

### 2.2 Lint 修复 (`omnibar.tsx`)
**文件**: `/home/aiscend/work/fortune_ai/web-app/src/components/chat/omnibar.tsx`
**问题**: Image 组件 lucide-react 图标作为组件使用，但报 alt 属性缺失警告
**修改** (line 136):
```typescript
// Before
<Image className="w-4 h-4 text-muted-foreground" />

// After - 使用 ImageIcon 重命名或改用其他方式
import { Plus, Send, Mic, Image as ImageIcon, FileText, Sparkles } from "lucide-react"
// ...
<ImageIcon className="w-4 h-4 text-muted-foreground" />
```

### 2.3 Lint 修复 (`explore-tab.tsx`)
**验证**: FolderOpen 在 line 72 有使用 `<FolderOpen className="w-4 h-4 text-muted-foreground" />`
**结论**: 这不是真正的 lint 错误，FolderOpen 确实被使用了

---

## 3. 执行顺序

1. 修复 `soul_os.py` 的 L0 翻译键位 (status → level)
2. 修复 `soul_os.py` 的神煞名称 (桃花 → 桃花星)
3. 修复 `soul_os.py` 的 State Score 正向情绪计分逻辑
4. 修复 `dual-core-layout.tsx` 的布局比例
5. 修复 `omnibar.tsx` 的 Image 组件命名
6. 运行 `npm run lint` 验证前端修复
7. 重启后端服务验证

---

## 4. 关键文件清单

- `/home/aiscend/work/fortune_ai/services/soul_os.py` (lines 114, 118, 272, 323-331, 494-497)
- `/home/aiscend/work/fortune_ai/web-app/src/components/layout/dual-core-layout.tsx` (line 14)
- `/home/aiscend/work/fortune_ai/web-app/src/components/chat/omnibar.tsx` (lines 5, 136)
