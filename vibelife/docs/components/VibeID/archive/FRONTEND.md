# Vibe ID 前端设计

> Version: 7.0 | 2026-01-18

---

## 概述

Vibe ID 前端包含独立页面和可复用组件，支持无登录体验和社交分享。

## 页面结构

```
apps/web/src/
├── app/
│   ├── vibe-id/                        # Vibe ID 独立入口
│   │   ├── page.tsx                    # 主页 (展示已有/引导创建)
│   │   ├── create/
│   │   │   └── page.tsx                # 创建流程页
│   │   ├── [shareCode]/
│   │   │   └── page.tsx                # 分享落地页
│   │   └── match/
│   │       └── page.tsx                # 配对页面
│   │
│   └── onboarding/                     # Onboarding 集成
│       ├── page.tsx
│       └── steps/
│           ├── LandingStep.tsx         # 修改: 集成 Vibe ID 创建
│           └── AhaStep.tsx             # 修改: 展示 Vibe ID 结果
│
├── skills/vibe-id/
│   ├── components/                     # 可复用组件
│   │   ├── VibeIDCard.tsx              # 主卡片 (升级)
│   │   ├── VibeIDCreator.tsx           # 创建组件 (新)
│   │   ├── VibeIDMini.tsx              # 迷你卡片 (新)
│   │   ├── ShareCard.tsx               # 分享卡片预览 (新)
│   │   ├── ShareButton.tsx             # 分享按钮 (新)
│   │   ├── ArchetypeRadar.tsx          # 雷达图 (已有)
│   │   ├── ArchetypeBadge.tsx          # 原型徽章 (已有)
│   │   ├── DimensionRow.tsx            # 四维展示 (已有)
│   │   ├── TagCloud.tsx                # 标签云 (新)
│   │   ├── GrowthCard.tsx              # 成长方向卡片 (新)
│   │   ├── RelationshipCard.tsx        # 关系倾向卡片 (新)
│   │   └── MatchResult.tsx             # 配对结果 (新)
│   │
│   ├── hooks/
│   │   ├── useVibeID.ts                # 获取 Vibe ID (升级)
│   │   ├── useVibeIDCreate.ts          # 创建流程 (新)
│   │   ├── useVibeIDShare.ts           # 分享功能 (新)
│   │   └── useVibeIDMatch.ts           # 配对功能 (新)
│   │
│   ├── tools/
│   │   └── show-vibe-id.tsx            # Tool 处理器 (升级)
│   │
│   ├── constants/
│   │   ├── styles.ts                   # 样式常量 (已有)
│   │   └── archetypes.ts               # 原型���数据 (新)
│   │
│   └── index.ts                        # 导出
│
└── types/
    └── vibe-id.ts                      # TypeScript 类型定义 (新)
```

---

## 页面设计

### 1. 主页 `/vibe-id`

**功能**: 展示已有 Vibe ID 或引导创建

```tsx
// app/vibe-id/page.tsx

export default function VibeIDPage() {
  const { vibeID, isLoading } = useVibeID()

  if (isLoading) return <VibeIDSkeleton />

  // 已有 Vibe ID - 展示完整卡片
  if (vibeID) {
    return (
      <div className="container max-w-lg mx-auto py-8">
        <VibeIDCard data={vibeID} variant="full" />
        <ShareButton vibeID={vibeID} className="mt-6" />
      </div>
    )
  }

  // 未创建 - 引导创建
  return (
    <div className="container max-w-lg mx-auto py-8">
      <VibeIDCreator onComplete={(vibeID) => router.push('/vibe-id')} />
    </div>
  )
}
```

### 2. 创建页 `/vibe-id/create`

**功能**: 极简创建流程，3分钟完成

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          创建流程 (3步)                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Step 1: 输入出生信息                                                        │
│  ════════════════════                                                       │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │     VibeID · 发现你的人格密码                                        │   │
│  │                                                                     │   │
│  │     ┌─────────────────────────────────────────────────────────┐    │   │
│  │     │  出生日期                                                │    │   │
│  │     │  [1990] 年 [05] 月 [15] 日                              │    │   │
│  │     └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                     │   │
│  │     ┌─────────────────────────────────────────────────────────┐    │   │
│  │     │  出生时间 (越准确越好)                                    │    │   │
│  │     │  [08] : [30]                                            │    │   │
│  │     └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                     │   │
│  │     ┌─────────────────────────────────────────────────────────┐    │   │
│  │     │  出生地点 (可选)                                          │    │   │
│  │     │  [北京                                              ▼]  │    │   │
│  │     └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                     │   │
│  │                    [发现我的 Vibe →]                                │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Step 2: 加载动画 (3秒)                                                     │
│  ══════════════════════                                                     │
│                                                                             │
│  ┌────────────────────────────────���────────────────────────────────────┐   │
│  │                                                                     │   │
│  │                    ✨ 正在解读你的命盘...                            │   │
│  │                                                                     │   │
│  │                    [呼吸光晕动画]                                    │   │
│  │                                                                     │   │
│  │                    融合东方命理与西方占星                            │   │
│  │                    发现你的人格密码                                  │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Step 3: 展示结果                                                           │
│  ════════════════                                                           │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │     [VibeIDCard - full variant]                                    │   │
│  │                                                                     │   │
│  │     ─────────────────────────────────────────────────────────────  │   │
│  │                                                                     │   │
│  │     [分享我的 Vibe]        [保存到账号]                             │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3. 分享落地页 `/vibe-id/[shareCode]`

**功能**: 被分享者的入口页面

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          分享落地页                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │     小明 是 探索者 Vibe 🧭                                          │   │
│  │                                                                     │   │
│  │     "好奇心驱动，追求意义，享受探索未知的旅程"                        │   │
│  │                                                                     │   │
│  │     ─────────────────────────────────────────────────────────────  │   │
│  │                                                                     │   │
│  │     Ta 邀请你测测你的 Vibe                                          │   │
│  │                                                                     │   │
│  │                    [测测我的 Vibe →]                                │   │
│  │                                                                     │   │
│  │     ─────────────────────────────────────────────────────────────  │   │
│  │                                                                     │   │
│  │     已有 12,345 人发现了自己的 Vibe                                 │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4. 配对页 `/vibe-id/match`

**功能**: 展示两人配对结果

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          配对结果页                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │     ┌──────────┐              ┌──────────┐                         │   │
│  │     │   🧭     │      💕      │   📚     │                         │   │
│  │     │  探索者  │    85%      │   智者   │                         │   │
│  │     │   你     │              │   Ta     │                         │   │
│  │     └──────────┘              └──────────┘                         │   │
│  │                                                                     │   │
│  │                    灵魂伴侣                                         │   │
│  │                                                                     │   │
│  │     ─────────────────────────────────────────────────────────────  │   │
│  │                                                                     │   │
│  │     💪 你们的优势                                                   │   │
│  │     • 共同的求知欲                                                  │   │
│  │     • 互补的行动与思考                                              │   │
│  │     • 尊重彼此的独立空间                                            │   │
│  │                                                                     │   │
│  │     ⚡ 需要注意                                                     │   │
│  │     • 可能都不擅长处理情感细节                                      │   │
│  │     • 需要学习表达关心                                              │   │
│  │                                                                     │   │
│  │     💡 相处建议                                                     │   │
│  │     多分享你们的发现和思考，这是你们连接的最佳方式。                 │   │
│  │                                                                     │   │
│  │     ─────────────────────────────────────────────────────────────  │   │
│  │                                                                     │   │
│  │     [分享配对结果]        [邀请更多朋友]                            │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 组件设计

### 1. VibeIDCreator (新)

**创建流程组件**

```tsx
// skills/vibe-id/components/VibeIDCreator.tsx

interface VibeIDCreatorProps {
  invitedBy?: string              // 邀请人 share_code
  onComplete: (vibeID: VibeID) => void
  onCancel?: () => void
  className?: string
}

export function VibeIDCreator({
  invitedBy,
  onComplete,
  onCancel,
  className
}: VibeIDCreatorProps) {
  const [step, setStep] = useState<'input' | 'loading' | 'result'>('input')
  const [birthInfo, setBirthInfo] = useState<BirthInfo | null>(null)
  const [vibeID, setVibeID] = useState<VibeID | null>(null)

  const { create, isCreating } = useVibeIDCreate()

  const handleSubmit = async (info: BirthInfo) => {
    setBirthInfo(info)
    setStep('loading')

    const result = await create({
      ...info,
      invited_by: invitedBy
    })

    if (result.success) {
      setVibeID(result.data.vibe_id)
      // 保存到 localStorage (无登录场景)
      saveToLocalStorage(result.data)
      setStep('result')
    }
  }

  return (
    <div className={cn('vibe-id-creator', className)}>
      {step === 'input' && (
        <BirthInfoForm onSubmit={handleSubmit} onCancel={onCancel} />
      )}
      {step === 'loading' && (
        <LoadingAnimation />
      )}
      {step === 'result' && vibeID && (
        <ResultView vibeID={vibeID} onComplete={() => onComplete(vibeID)} />
      )}
    </div>
  )
}
```

### 2. VibeIDCard (升级)

**主卡片组件 - 支持新数据结构**

```tsx
// skills/vibe-id/components/VibeIDCard.tsx

interface VibeIDCardProps {
  data: VibeID
  variant?: 'full' | 'compact' | 'mini'
  showDimensions?: boolean
  showTags?: boolean
  showGrowth?: boolean
  showRelationship?: boolean
  showUnderlying?: boolean
  className?: string
  onExplore?: () => void
  onShare?: () => void
}

export function VibeIDCard({
  data,
  variant = 'full',
  showDimensions = true,
  showTags = true,
  showGrowth = true,
  showRelationship = false,
  showUnderlying = true,
  className,
  onExplore,
  onShare
}: VibeIDCardProps) {
  // ... 实现
}
```

### 3. ShareCard (新)

**分享卡片预览组件**

```tsx
// skills/vibe-id/components/ShareCard.tsx

interface ShareCardProps {
  vibeID: VibeID
  style?: 'default' | 'dark' | 'gradient' | 'minimal'
  showQR?: boolean
  className?: string
}

export function ShareCard({
  vibeID,
  style = 'default',
  showQR = true,
  className
}: ShareCardProps) {
  const { identity, tags, share } = vibeID

  return (
    <div className={cn('share-card', `share-card--${style}`, className)}>
      {/* 头部 - 原型展示 */}
      <div className="share-card__header">
        <div className="share-card__avatar">
          <span className="text-5xl">{identity.primary_emoji}</span>
        </div>
        <div className="share-card__identity">
          <span className="share-card__label">我是</span>
          <h2 className="share-card__archetype">
            {identity.primary_tagline} Vibe
          </h2>
        </div>
      </div>

      {/* 标语 */}
      <p className="share-card__slogan">
        "{identity.primary_slogan}"
      </p>

      {/* 标签 */}
      <div className="share-card__tags">
        {tags.slice(0, 4).map(tag => (
          <span key={tag.id} className="share-card__tag">
            {tag.emoji} {tag.label} {tag.score}%
          </span>
        ))}
      </div>

      {/* 底部 */}
      <div className="share-card__footer">
        <span>扫码测测你的 Vibe</span>
        {showQR && <QRCode value={`https://vibelife.app/vibe-id/${share.share_code}`} />}
        <span className="share-card__brand">VibeLife</span>
      </div>
    </div>
  )
}
```

### 4. TagCloud (新)

**标签云组件**

```tsx
// skills/vibe-id/components/TagCloud.tsx

interface TagCloudProps {
  tags: VibeIDTag[]
  maxTags?: number
  variant?: 'default' | 'compact'
  className?: string
}

export function TagCloud({
  tags,
  maxTags = 5,
  variant = 'default',
  className
}: TagCloudProps) {
  const displayTags = tags.slice(0, maxTags)

  return (
    <div className={cn('tag-cloud', `tag-cloud--${variant}`, className)}>
      {displayTags.map(tag => (
        <div
          key={tag.id}
          className="tag-cloud__item"
          style={{ '--score': tag.score } as React.CSSProperties}
        >
          <span className="tag-cloud__emoji">{tag.emoji}</span>
          <span className="tag-cloud__label">{tag.label}</span>
          {variant === 'default' && (
            <span className="tag-cloud__score">{tag.score}%</span>
          )}
        </div>
      ))}
    </div>
  )
}
```

### 5. ShareButton (新)

**分享按钮组件**

```tsx
// skills/vibe-id/components/ShareButton.tsx

interface ShareButtonProps {
  vibeID: VibeID
  variant?: 'primary' | 'secondary' | 'icon'
  className?: string
}

export function ShareButton({
  vibeID,
  variant = 'primary',
  className
}: ShareButtonProps) {
  const { share, isSharing, shareToWeChat, shareToWeibo, copyLink, downloadCard } = useVibeIDShare(vibeID)
  const [showMenu, setShowMenu] = useState(false)

  return (
    <div className={cn('share-button', className)}>
      <button
        onClick={() => setShowMenu(true)}
        className={cn('share-button__trigger', `share-button__trigger--${variant}`)}
      >
        <ShareIcon />
        {variant !== 'icon' && <span>分享我的 Vibe</span>}
      </button>

      {showMenu && (
        <ShareMenu
          onWeChat={shareToWeChat}
          onWeibo={shareToWeibo}
          onCopyLink={copyLink}
          onDownload={downloadCard}
          onClose={() => setShowMenu(false)}
        />
      )}
    </div>
  )
}
```

---

## Hooks 设计

### 1. useVibeID (升级)

```tsx
// skills/vibe-id/hooks/useVibeID.ts

interface UseVibeIDReturn {
  vibeID: VibeID | null
  isLoading: boolean
  error: Error | null
  refetch: () => Promise<void>
}

export function useVibeID(): UseVibeIDReturn {
  const { user } = useAuth()

  // 优先从服务器获取
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['vibe-id', user?.id],
    queryFn: () => fetchVibeID(),
    enabled: !!user,
  })

  // 未登录时从 localStorage 获取
  const localVibeID = useMemo(() => {
    if (!user) {
      return getFromLocalStorage()
    }
    return null
  }, [user])

  return {
    vibeID: data?.vibe_id || localVibeID,
    isLoading,
    error,
    refetch
  }
}
```

### 2. useVibeIDCreate (新)

```tsx
// skills/vibe-id/hooks/useVibeIDCreate.ts

interface BirthInfo {
  birth_date: string
  birth_time: string
  birth_place?: string
  gender?: string
}

interface CreateOptions extends BirthInfo {
  invited_by?: string
}

interface UseVibeIDCreateReturn {
  create: (options: CreateOptions) => Promise<CreateResult>
  isCreating: boolean
  error: Error | null
}

export function useVibeIDCreate(): UseVibeIDCreateReturn {
  const [isCreating, setIsCreating] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  const create = async (options: CreateOptions) => {
    setIsCreating(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/vibe-id/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(options)
      })

      const result = await response.json()

      if (result.status === 'success') {
        // 保存到 localStorage
        saveVibeIDToLocal(result.data)
        return { success: true, data: result.data }
      } else {
        throw new Error(result.message)
      }
    } catch (err) {
      setError(err as Error)
      return { success: false, error: err }
    } finally {
      setIsCreating(false)
    }
  }

  return { create, isCreating, error }
}
```

### 3. useVibeIDShare (新)

```tsx
// skills/vibe-id/hooks/useVibeIDShare.ts

interface UseVibeIDShareReturn {
  shareToWeChat: () => Promise<void>
  shareToWeibo: () => Promise<void>
  copyLink: () => Promise<void>
  downloadCard: () => Promise<void>
  isSharing: boolean
}

export function useVibeIDShare(vibeID: VibeID): UseVibeIDShareReturn {
  const [isSharing, setIsSharing] = useState(false)

  const shareToWeChat = async () => {
    // 调用微信 JS-SDK
  }

  const shareToWeibo = async () => {
    const url = `https://vibelife.app/vibe-id/${vibeID.share.share_code}`
    const text = vibeID.share.share_text
    window.open(`https://service.weibo.com/share/share.php?url=${encodeURIComponent(url)}&title=${encodeURIComponent(text)}`)
  }

  const copyLink = async () => {
    const url = `https://vibelife.app/vibe-id/${vibeID.share.share_code}`
    await navigator.clipboard.writeText(url)
    toast.success('链接已复制')
  }

  const downloadCard = async () => {
    const cardUrl = vibeID.share.card_url
    const response = await fetch(cardUrl)
    const blob = await response.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `vibe-id-${vibeID.share.share_code}.png`
    a.click()
  }

  return { shareToWeChat, shareToWeibo, copyLink, downloadCard, isSharing }
}
```

---

## localStorage 数据结构

```typescript
// 无登录场景下的本地存储

interface LocalVibeIDData {
  vibe_id: VibeID
  share_code: string
  created_at: string
  expires_at: string           // 7天后过期
  birth_info: BirthInfo        // 保存出生信息用于注册后迁移
}

// 存储 key
const VIBE_ID_LOCAL_KEY = 'vibelife_vibe_id'

// 保存
function saveVibeIDToLocal(data: LocalVibeIDData) {
  localStorage.setItem(VIBE_ID_LOCAL_KEY, JSON.stringify({
    ...data,
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
  }))
}

// 读取
function getVibeIDFromLocal(): LocalVibeIDData | null {
  const raw = localStorage.getItem(VIBE_ID_LOCAL_KEY)
  if (!raw) return null

  const data = JSON.parse(raw)

  // 检查过期
  if (new Date(data.expires_at) < new Date()) {
    localStorage.removeItem(VIBE_ID_LOCAL_KEY)
    return null
  }

  return data
}

// 清除 (注册后调用)
function clearVibeIDLocal() {
  localStorage.removeItem(VIBE_ID_LOCAL_KEY)
}
```

---

## 样式设计

### 颜色系统

```css
/* 原型颜色 */
:root {
  --archetype-innocent: #FFE4E1;
  --archetype-explorer: #E6F3FF;
  --archetype-sage: #F0E6FF;
  --archetype-hero: #FFE6E6;
  --archetype-outlaw: #2D2D2D;
  --archetype-magician: #E6FFE6;
  --archetype-regular: #F5F5DC;
  --archetype-lover: #FFE6F0;
  --archetype-jester: #FFFACD;
  --archetype-caregiver: #E6FFF0;
  --archetype-creator: #FFF0E6;
  --archetype-ruler: #E6E6FF;
}
```

### 动画

```css
/* 呼吸光晕动画 */
@keyframes vibe-breathe {
  0%, 100% {
    transform: scale(1);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.1);
    opacity: 1;
  }
}

.vibe-aura {
  animation: vibe-breathe 3s ease-in-out infinite;
}

/* 结果揭示动画 */
@keyframes vibe-reveal {
  0% {
    opacity: 0;
    transform: translateY(20px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

.vibe-reveal {
  animation: vibe-reveal 0.6s ease-out forwards;
}
```
