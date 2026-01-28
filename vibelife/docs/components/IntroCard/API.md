# SkillIntroCard API 设计

> Version: 1.0.0 | 2026-01-20

---

## 1. API 端点

### 1.1 端点列表

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/api/v1/skills/{skill_id}/intro` | 获取 Skill 介绍数据 |
| POST | `/api/v1/skills/{skill_id}/subscribe` | 订阅 Skill |
| DELETE | `/api/v1/skills/{skill_id}/subscribe` | 取消订阅 |
| PATCH | `/api/v1/skills/{skill_id}/settings` | 更新 Skill 设置 |
| POST | `/api/v1/skills/{skill_id}/first-use` | 标记首次使用 |

---

## 2. 端点详情

### 2.1 GET /api/v1/skills/{skill_id}/intro

获取 Skill 介绍卡片所需的完整数据。

**请求**:
```http
GET /api/v1/skills/lifecoach/intro
Authorization: Bearer {token}
```

**响应** (200 OK):
```json
{
  "skill": {
    "id": "lifecoach",
    "name": "Lifecoach",
    "description": "人生教练。支持多种教练方法论（Dan Koe、Covey、王阳明、了凡四训），帮助用户设定目标、突破卡点、持续成长。",
    "version": "3.0.0",
    "category": "professional",
    "icon": "🧭",
    "color": "#10B981",
    "triggers": ["迷茫", "卡住", "拖延", "想改变", "目标", "愿景"],
    "pricing": {
      "type": "premium",
      "trial_messages": 5,
      "credits_per_use": null
    },
    "features": [
      {
        "name": "多方法论支持",
        "description": "Dan Koe、Covey、王阳明、了凡四训",
        "icon": "📚",
        "tier": "free",
        "action": {
          "type": "expand"
        },
        "demo_prompt": "介绍一下你支持的教练方法论"
      },
      {
        "name": "完整教练流程",
        "description": "诊断→设计→执行→复盘",
        "icon": "🎯",
        "tier": "free",
        "action": {
          "type": "send_prompt"
        },
        "demo_prompt": "帮我做一次完整的人生诊断"
      },
      {
        "name": "持续陪伴",
        "description": "每日签到、周复盘、进度追踪",
        "icon": "🤝",
        "tier": "premium",
        "action": {
          "type": "navigate",
          "target": "rule",
          "id": "companion/daily-checkin"
        },
        "demo_prompt": "开始今日签到"
      }
    ],
    "showcase": {
      "tagline": "你的 AI 人生教练，多元智慧助你成长",
      "highlights": [
        "四大教练方法论任选",
        "完整的教练流程",
        "持续陪伴，长期成长"
      ],
      "preview_image": null,
      "demo_prompts": [
        "我感觉很迷茫，不知道该做什么",
        "帮我用 Dan Koe 方法做一次人生重置",
        "我想用了凡四训的方法改变命运"
      ]
    },
    "settings": [
      {
        "key": "push_enabled",
        "name": "每日提醒",
        "type": "toggle",
        "default": true,
        "description": "接收每日签到和复盘提醒"
      },
      {
        "key": "voice_mode",
        "name": "语音模式",
        "type": "select",
        "default": "warm",
        "options": [
          { "value": "warm", "label": "温暖支持" },
          { "value": "direct", "label": "直接挑战" },
          { "value": "playful", "label": "轻松幽默" }
        ]
      },
      {
        "key": "reminder_hour",
        "name": "提醒时间",
        "type": "time",
        "default": "08:00",
        "description": "每日提醒的发送时间"
      }
    ],
    "intro_card": {
      "default_sections": ["header", "features", "quickstart", "pricing"],
      "show_on_first_use": true,
      "cta_text": "开始你的成长之旅"
    }
  },
  "subscription": {
    "skill_id": "lifecoach",
    "status": "trial",
    "push_enabled": true,
    "subscribed_at": null,
    "trial_messages_used": 2,
    "trial_messages_remaining": 3
  },
  "settings": {
    "skill_id": "lifecoach",
    "voice_mode": "warm",
    "reminder_hour": 8,
    "custom_settings": {}
  },
  "is_first_use": false
}
```

**错误响应**:
- 404: Skill 不存在
- 401: 未授权

---

### 2.2 POST /api/v1/skills/{skill_id}/subscribe

订阅 Skill。

**请求**:
```http
POST /api/v1/skills/lifecoach/subscribe
Authorization: Bearer {token}
Content-Type: application/json

{
  "push_enabled": true
}
```

**响应** (200 OK):
```json
{
  "success": true,
  "subscription": {
    "skill_id": "lifecoach",
    "status": "subscribed",
    "push_enabled": true,
    "subscribed_at": "2026-01-20T10:30:00Z",
    "trial_messages_used": 2,
    "trial_messages_remaining": 0
  }
}
```

**错误响应**:
- 402: 需要付费（premium skill 且无有效订阅）
- 409: 已订阅

---

### 2.3 DELETE /api/v1/skills/{skill_id}/subscribe

取消订阅 Skill。

**请求**:
```http
DELETE /api/v1/skills/lifecoach/subscribe
Authorization: Bearer {token}
```

**响应** (200 OK):
```json
{
  "success": true,
  "subscription": {
    "skill_id": "lifecoach",
    "status": "unsubscribed",
    "push_enabled": false,
    "subscribed_at": null,
    "trial_messages_used": 2,
    "trial_messages_remaining": 3
  }
}
```

**错误响应**:
- 400: Core skill 不可取消订阅
- 404: 未订阅

---

### 2.4 PATCH /api/v1/skills/{skill_id}/settings

更新 Skill 设置。

**请求**:
```http
PATCH /api/v1/skills/lifecoach/settings
Authorization: Bearer {token}
Content-Type: application/json

{
  "voice_mode": "direct",
  "reminder_hour": 9,
  "push_enabled": false
}
```

**响应** (200 OK):
```json
{
  "success": true,
  "settings": {
    "skill_id": "lifecoach",
    "voice_mode": "direct",
    "reminder_hour": 9,
    "custom_settings": {}
  },
  "subscription": {
    "skill_id": "lifecoach",
    "status": "subscribed",
    "push_enabled": false,
    "subscribed_at": "2026-01-20T10:30:00Z",
    "trial_messages_used": 2,
    "trial_messages_remaining": 0
  }
}
```

---

### 2.5 POST /api/v1/skills/{skill_id}/first-use

标记用户首次使用某 Skill（用于控制介绍卡片展示）。

**请求**:
```http
POST /api/v1/skills/lifecoach/first-use
Authorization: Bearer {token}
```

**响应** (200 OK):
```json
{
  "success": true,
  "is_first_use": false,
  "first_used_at": "2026-01-20T10:30:00Z"
}
```

---

## 3. 后端实现

### 3.1 路由注册

```python
# routes/skills.py

from fastapi import APIRouter, Depends, HTTPException
from services.agent.skill_loader import load_skill_metadata
from stores.unified_profile_repo import UnifiedProfileRepository

router = APIRouter(prefix="/api/v1/skills", tags=["skills"])


@router.get("/{skill_id}/intro")
async def get_skill_intro(
    skill_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """获取 Skill 介绍数据"""
    # 1. 加载 Skill 元数据
    skill = load_skill_metadata(skill_id)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    # 2. 获取用户订阅状态
    profile = await UnifiedProfileRepository.get_profile(user_id)
    subscribed_skills = profile.get("preferences", {}).get("subscribed_skills", {})
    skill_sub = subscribed_skills.get(skill_id, {})

    subscription = None
    if skill_sub:
        subscription = {
            "skill_id": skill_id,
            "status": skill_sub.get("status", "unsubscribed"),
            "push_enabled": skill_sub.get("push_enabled", False),
            "subscribed_at": skill_sub.get("subscribed_at"),
            "trial_messages_used": skill_sub.get("trial_messages_used", 0),
            "trial_messages_remaining": max(0, skill.pricing.trial_messages - skill_sub.get("trial_messages_used", 0)),
        }

    # 3. 获取用户设置
    preferences = profile.get("preferences", {})
    settings = {
        "skill_id": skill_id,
        "voice_mode": preferences.get("voice_mode", "warm"),
        "reminder_hour": preferences.get("push_settings", {}).get("default_push_hour", 8),
        "custom_settings": {},
    }

    # 4. 检查是否首次使用
    first_use_key = f"first_use_{skill_id}"
    is_first_use = not profile.get("_meta", {}).get(first_use_key, False)

    return {
        "skill": skill.to_dict(),
        "subscription": subscription,
        "settings": settings,
        "is_first_use": is_first_use,
    }


@router.post("/{skill_id}/subscribe")
async def subscribe_skill(
    skill_id: str,
    body: SubscribeRequest,
    user_id: str = Depends(get_current_user_id)
):
    """订阅 Skill"""
    await UnifiedProfileRepository.subscribe(
        user_id=user_id,
        skill_id=skill_id,
        push_enabled=body.push_enabled
    )
    # 返回更新后的订阅状态
    ...


@router.delete("/{skill_id}/subscribe")
async def unsubscribe_skill(
    skill_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """取消订阅 Skill"""
    skill = load_skill_metadata(skill_id)
    if skill and skill.category == "core":
        raise HTTPException(status_code=400, detail="Cannot unsubscribe core skill")

    await UnifiedProfileRepository.unsubscribe(user_id=user_id, skill_id=skill_id)
    ...


@router.patch("/{skill_id}/settings")
async def update_skill_settings(
    skill_id: str,
    body: UpdateSettingsRequest,
    user_id: str = Depends(get_current_user_id)
):
    """更新 Skill 设置"""
    updates = body.dict(exclude_unset=True)

    # 更新 voice_mode
    if "voice_mode" in updates:
        await UnifiedProfileRepository.update_preferences(
            user_id=user_id,
            updates={"voice_mode": updates["voice_mode"]}
        )

    # 更新 push_enabled
    if "push_enabled" in updates:
        await UnifiedProfileRepository.update_skill_subscription(
            user_id=user_id,
            skill_id=skill_id,
            updates={"push_enabled": updates["push_enabled"]}
        )

    # 更新 reminder_hour
    if "reminder_hour" in updates:
        await UnifiedProfileRepository.update_push_settings(
            user_id=user_id,
            updates={"default_push_hour": updates["reminder_hour"]}
        )

    ...


@router.post("/{skill_id}/first-use")
async def mark_first_use(
    skill_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """标记首次使用"""
    first_use_key = f"first_use_{skill_id}"
    await UnifiedProfileRepository.update_meta(
        user_id=user_id,
        updates={first_use_key: True, f"{first_use_key}_at": datetime.utcnow().isoformat()}
    )
    ...
```

### 3.2 工具定义

```yaml
# apps/api/skills/core/tools/tools.yaml

- name: show_skill_intro
  description: |
    展示 Skill 介绍导航卡片。
    在以下场景调用：
    1. 用户首次使用某个 Skill
    2. 用户询问"这个 Skill 能做什么"
    3. 用户想了解 Skill 的功能和定价
  tool_type: display
  card_type: skill_intro
  parameters:
    - name: skill_id
      type: string
      required: true
      description: 要展示的 Skill ID
    - name: variant
      type: string
      enum: [full, compact, mini]
      default: compact
      description: |
        卡片变体：
        - full: 完整版，包含所有 sections
        - compact: 精简版，适合对话中展示
        - mini: 迷你版，只有标题和 CTA
    - name: sections
      type: array
      items: string
      description: |
        要显示的 sections，可选值：
        - header: 头部信息
        - features: 功能列表
        - quickstart: 快速开始
        - pricing: 定价信息
        - settings: 设置选项
        不传则使用 Skill 的默认配置
    - name: reason
      type: string
      description: 展示原因，会显示在卡片顶部
```

### 3.3 工具处理器

```python
# apps/api/skills/core/tools/handlers.py

from services.agent.skill_loader import load_skill_metadata

@tool_handler("show_skill_intro")
async def execute_show_skill_intro(args: Dict, context: ToolContext) -> Dict:
    """展示 Skill 介绍卡片"""
    skill_id = args.get("skill_id")
    variant = args.get("variant", "compact")
    sections = args.get("sections")
    reason = args.get("reason")

    # 加载 Skill 元数据
    skill = load_skill_metadata(skill_id)
    if not skill:
        return {"error": f"Skill {skill_id} not found"}

    # 确定要显示的 sections
    if not sections:
        intro_config = getattr(skill, 'intro_card', None)
        if intro_config:
            sections = intro_config.get('default_sections', ['header', 'features', 'quickstart'])
        else:
            sections = ['header', 'features', 'quickstart']

    return {
        "cardType": "skill_intro",
        "data": {
            "skill_id": skill_id,
            "variant": variant,
            "sections": sections,
            "reason": reason,
        }
    }
```

---

## 4. 前端 API 调用

### 4.1 API Client

```typescript
// lib/api/skills.ts

import { SkillIntroData, UserSubscription, UserSkillSettings } from '@/skills/shared/SkillIntroCard/types';

const API_BASE = '/api/v1/skills';

export async function fetchSkillIntro(skillId: string): Promise<SkillIntroData> {
  const response = await fetch(`${API_BASE}/${skillId}/intro`, {
    credentials: 'include',
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch skill intro: ${response.status}`);
  }
  return response.json();
}

export async function subscribeSkill(
  skillId: string,
  pushEnabled: boolean = true
): Promise<{ subscription: UserSubscription }> {
  const response = await fetch(`${API_BASE}/${skillId}/subscribe`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ push_enabled: pushEnabled }),
  });
  if (!response.ok) {
    throw new Error(`Failed to subscribe: ${response.status}`);
  }
  return response.json();
}

export async function unsubscribeSkill(
  skillId: string
): Promise<{ subscription: UserSubscription }> {
  const response = await fetch(`${API_BASE}/${skillId}/subscribe`, {
    method: 'DELETE',
    credentials: 'include',
  });
  if (!response.ok) {
    throw new Error(`Failed to unsubscribe: ${response.status}`);
  }
  return response.json();
}

export async function updateSkillSettings(
  skillId: string,
  settings: Partial<UserSkillSettings & { push_enabled?: boolean }>
): Promise<{ settings: UserSkillSettings; subscription: UserSubscription }> {
  const response = await fetch(`${API_BASE}/${skillId}/settings`, {
    method: 'PATCH',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(settings),
  });
  if (!response.ok) {
    throw new Error(`Failed to update settings: ${response.status}`);
  }
  return response.json();
}

export async function markFirstUse(skillId: string): Promise<void> {
  await fetch(`${API_BASE}/${skillId}/first-use`, {
    method: 'POST',
    credentials: 'include',
  });
}
```

### 4.2 React Query Hooks

```typescript
// skills/shared/SkillIntroCard/hooks/useSkillIntro.ts

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  fetchSkillIntro,
  subscribeSkill,
  unsubscribeSkill,
  updateSkillSettings,
  markFirstUse,
} from '@/lib/api/skills';

export function useSkillIntro(skillId: string) {
  return useQuery({
    queryKey: ['skill-intro', skillId],
    queryFn: () => fetchSkillIntro(skillId),
    staleTime: 5 * 60 * 1000, // 5 分钟
    enabled: !!skillId,
  });
}

export function useSubscribe(skillId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (pushEnabled: boolean) => subscribeSkill(skillId, pushEnabled),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['skill-intro', skillId] });
    },
  });
}

export function useUnsubscribe(skillId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => unsubscribeSkill(skillId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['skill-intro', skillId] });
    },
  });
}

export function useUpdateSettings(skillId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (settings: Parameters<typeof updateSkillSettings>[1]) =>
      updateSkillSettings(skillId, settings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['skill-intro', skillId] });
    },
  });
}

export function useMarkFirstUse(skillId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => markFirstUse(skillId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['skill-intro', skillId] });
    },
  });
}
```
