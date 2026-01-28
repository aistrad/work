# Skill Management API Reference

> API 端点完整文档

---

## 1. 端点总览

| 方法 | 端点 | 描述 | 认证 |
|------|------|------|------|
| GET | `/api/v1/skills` | 获取所有 Skill 列表 | 可选 |
| GET | `/api/v1/skills/{skill_id}` | 获取单个 Skill 详情 | 可选 |
| GET | `/api/v1/skills/subscriptions` | 获取用户订阅列表 | 必须 |
| POST | `/api/v1/skills/{skill_id}/subscribe` | 订阅 Skill | 必须 |
| POST | `/api/v1/skills/{skill_id}/unsubscribe` | 取消订阅 Skill | 必须 |
| POST | `/api/v1/skills/{skill_id}/push` | 切换推送开关 | 必须 |
| GET | `/api/v1/skills/recommendations` | 获取推荐 Skill | 必须 |
| GET | `/api/v1/skills/featured` | 获取精选 Skill | 可选 |

---

## 2. 获取所有 Skill

### GET /api/v1/skills

获取所有可用 Skill 列表，包含元数据和用户订阅状态（如已登录）。

#### 请求

```http
GET /api/v1/skills HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}  # 可选
```

#### 查询参数

| 参数 | 类型 | 必须 | 描述 |
|------|------|------|------|
| `category` | string | 否 | 按分类筛选: `core`, `default`, `professional` |
| `subscribed` | boolean | 否 | 只返回已订阅的 Skill |

#### 响应

```json
{
  "skills": [
    {
      "id": "bazi",
      "name": "八字命理",
      "description": "融汇《滴天髓》《穷通宝鉴》《子平真诠》等经典的八字命理大师",
      "icon": "🔮",
      "color": "#D4A574",
      "category": "professional",
      "pricing": {
        "type": "premium",
        "trial_messages": 3
      },
      "features": [
        {
          "name": "命盘解读",
          "description": "四柱八字完整分析",
          "icon": "📜",
          "tier": "free"
        },
        {
          "name": "大运流年",
          "description": "十年大运周期分析",
          "icon": "📊",
          "tier": "basic"
        }
      ],
      "showcase": {
        "tagline": "洞察命运玄机，把握人生方向",
        "highlights": ["融汇四大经典", "个性化解读", "运势趋势分析"],
        "demo_prompts": ["帮我看看命盘", "我今年运势如何"]
      },
      "triggers": ["八字", "命理", "生辰", "测算"],
      "user_status": {
        "subscribed": true,
        "push_enabled": true,
        "trial_messages_used": 0,
        "trial_messages_remaining": 3
      }
    },
    {
      "id": "mindfulness",
      "name": "正念导师",
      "description": "3分钟内让你平静下来",
      "icon": "🧘",
      "color": "#10B981",
      "category": "default",
      "pricing": {
        "type": "free"
      },
      "features": [
        {
          "name": "呼吸练习",
          "description": "基础呼吸锚定",
          "tier": "free"
        }
      ],
      "showcase": {
        "tagline": "3分钟内让你平静下来",
        "highlights": ["Headspace 产品精髓", "情绪急救工具"]
      },
      "triggers": ["正念", "冥想", "呼吸", "放松"],
      "user_status": {
        "subscribed": true,
        "push_enabled": true,
        "trial_messages_used": 0,
        "trial_messages_remaining": null
      }
    }
  ],
  "categories": {
    "core": {
      "name": "核心能力",
      "description": "始终激活的基础能力",
      "count": 1
    },
    "default": {
      "name": "基础功能",
      "description": "默认激活，免费使用",
      "count": 2
    },
    "professional": {
      "name": "专业技能",
      "description": "需要订阅的高级功能",
      "count": 5
    }
  },
  "total": 8
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 500 | 服务器内部错误 |

---

## 3. 获取单个 Skill 详情

### GET /api/v1/skills/{skill_id}

获取指定 Skill 的完整详情。

#### 请求

```http
GET /api/v1/skills/bazi HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}  # 可选
```

#### 路径参数

| 参数 | 类型 | 描述 |
|------|------|------|
| `skill_id` | string | Skill ID |

#### 响应

```json
{
  "skill": {
    "id": "bazi",
    "name": "八字命理",
    "version": "3.0.0",
    "description": "融汇《滴天髓》《穷通宝鉴》《子平真诠》等经典的八字命理大师",
    "icon": "🔮",
    "color": "#D4A574",
    "category": "professional",
    "pricing": {
      "type": "premium",
      "trial_messages": 3
    },
    "requires_birth_info": true,
    "requires_compute": true,
    "features": [
      {
        "name": "命盘解读",
        "description": "四柱八字完整分析",
        "icon": "📜",
        "tier": "free"
      },
      {
        "name": "大运流年",
        "description": "十年大运周期分析",
        "icon": "📊",
        "tier": "basic"
      },
      {
        "name": "每日运势",
        "description": "基于流日的每日指引",
        "icon": "🌟",
        "tier": "premium"
      }
    ],
    "showcase": {
      "tagline": "洞察命运玄机，把握人生方向",
      "highlights": ["融汇四大经典", "个性化解读", "运势趋势分析"],
      "preview_image": "/skills/bazi/preview.png",
      "demo_prompts": ["帮我看看命盘", "我今年运势如何", "什么时候适合跳槽"],
      "testimonials": [
        {
          "content": "分析很准确，对我的职业选择很有帮助",
          "author": "用户A"
        }
      ]
    },
    "triggers": ["八字", "命理", "生辰", "测算", "算命", "命盘"],
    "services": [
      {
        "name": "chart",
        "description": "计算八字命盘"
      },
      {
        "name": "fortune",
        "description": "运势分析"
      },
      {
        "name": "daily",
        "description": "每日运势"
      }
    ]
  },
  "user_status": {
    "subscribed": true,
    "push_enabled": true,
    "subscribed_at": "2026-01-15T10:30:00Z",
    "trial_messages_used": 0,
    "trial_messages_remaining": 3,
    "last_used_at": "2026-01-19T08:00:00Z"
  }
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 404 | Skill 不存在 |

---

## 4. 获取用户订阅列表

### GET /api/v1/skills/subscriptions

获取当前用户的所有 Skill 订阅状态。

#### 请求

```http
GET /api/v1/skills/subscriptions HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}
```

#### 响应

```json
{
  "subscriptions": [
    {
      "skill_id": "core",
      "status": "subscribed",
      "push_enabled": true,
      "subscribed_at": null,
      "can_unsubscribe": false,
      "trial_messages_used": 0
    },
    {
      "skill_id": "bazi",
      "status": "subscribed",
      "push_enabled": true,
      "subscribed_at": "2026-01-15T10:30:00Z",
      "can_unsubscribe": true,
      "trial_messages_used": 2
    },
    {
      "skill_id": "mindfulness",
      "status": "subscribed",
      "push_enabled": false,
      "subscribed_at": "2026-01-01T00:00:00Z",
      "can_unsubscribe": true,
      "trial_messages_used": 0
    },
    {
      "skill_id": "zodiac",
      "status": "not_subscribed",
      "push_enabled": false,
      "subscribed_at": null,
      "can_unsubscribe": true,
      "trial_messages_used": 1
    }
  ],
  "summary": {
    "total_subscribed": 3,
    "total_available": 5,
    "push_enabled_count": 2
  }
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 401 | 未认证 |

---

## 5. 订阅 Skill

### POST /api/v1/skills/{skill_id}/subscribe

订阅指定 Skill。

#### 请求

```http
POST /api/v1/skills/bazi/subscribe HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}
Content-Type: application/json

{
  "push_enabled": true
}
```

#### 路径参数

| 参数 | 类型 | 描述 |
|------|------|------|
| `skill_id` | string | Skill ID |

#### 请求体

| 字段 | 类型 | 必须 | 描述 |
|------|------|------|------|
| `push_enabled` | boolean | 否 | 是否开启推送，默认 true |

#### 响应

```json
{
  "success": true,
  "subscription": {
    "skill_id": "bazi",
    "status": "subscribed",
    "push_enabled": true,
    "subscribed_at": "2026-01-19T10:30:00Z",
    "trial_messages_remaining": 3
  },
  "message": "已成功订阅「八字命理」"
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 400 | 已经订阅该 Skill |
| 401 | 未认证 |
| 402 | 需要 Premium 订阅 |
| 404 | Skill 不存在 |

---

## 6. 取消订阅 Skill

### POST /api/v1/skills/{skill_id}/unsubscribe

取消订阅指定 Skill。

#### 请求

```http
POST /api/v1/skills/bazi/unsubscribe HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}
```

#### 路径参数

| 参数 | 类型 | 描述 |
|------|------|------|
| `skill_id` | string | Skill ID |

#### 响应

```json
{
  "success": true,
  "subscription": {
    "skill_id": "bazi",
    "status": "unsubscribed",
    "push_enabled": false,
    "unsubscribed_at": "2026-01-19T10:30:00Z"
  },
  "message": "已取消订阅「八字命理」"
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 400 | 未订阅该 Skill |
| 400 | Core Skill 不可取消订阅 |
| 401 | 未认证 |
| 404 | Skill 不存在 |

---

## 7. 切换推送开关

### POST /api/v1/skills/{skill_id}/push

切换指定 Skill 的推送开关。

#### 请求

```http
POST /api/v1/skills/bazi/push HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}
Content-Type: application/json

{
  "enabled": false
}
```

#### 路径参数

| 参数 | 类型 | 描述 |
|------|------|------|
| `skill_id` | string | Skill ID |

#### 请求体

| 字段 | 类型 | 必须 | 描述 |
|------|------|------|------|
| `enabled` | boolean | 是 | 是否开启推送 |

#### 响应

```json
{
  "success": true,
  "subscription": {
    "skill_id": "bazi",
    "push_enabled": false
  },
  "message": "已关闭「八字命理」的推送通知"
}
```

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 400 | 未订阅该 Skill |
| 401 | 未认证 |
| 404 | Skill 不存在 |

---

## 8. 获取推荐 Skill

### GET /api/v1/skills/recommendations

基于用户档案和对话历史推荐 Skill。

#### 请求

```http
GET /api/v1/skills/recommendations?limit=3&context=relationship HTTP/1.1
Host: api.vibelife.app
Authorization: Bearer {token}
```

#### 查询参数

| 参数 | 类型 | 必须 | 描述 |
|------|------|------|------|
| `limit` | integer | 否 | 返回数量，默认 3，最大 10 |
| `context` | string | 否 | 当前对话上下文（关键词） |

#### 响应

```json
{
  "recommendations": [
    {
      "skill_id": "zodiac",
      "skill": {
        "id": "zodiac",
        "name": "西方占星",
        "icon": "⭐",
        "color": "#8B5CF6",
        "tagline": "星盘解读，揭示内在意图"
      },
      "reason": "based_on_conversation",
      "context": "你提到了人际关系的困扰。星座合盘分析可以帮你理解你们之间的动力模式。",
      "score": 0.85,
      "trial_messages_remaining": 3
    },
    {
      "skill_id": "mindfulness",
      "skill": {
        "id": "mindfulness",
        "name": "正念导师",
        "icon": "🧘",
        "color": "#10B981",
        "tagline": "3分钟内让你平静下来"
      },
      "reason": "based_on_emotion",
      "context": "感知到你可能有些焦虑，正念练习可以帮助放松。",
      "score": 0.72,
      "trial_messages_remaining": null
    }
  ],
  "generated_at": "2026-01-19T10:30:00Z"
}
```

#### 推荐原因

| reason | 描述 |
|--------|------|
| `based_on_conversation` | 基于对话内容关键词匹配 |
| `based_on_emotion` | 基于情绪检测 |
| `based_on_profile` | 基于用户档案 |
| `based_on_usage` | 基于使用历史 |
| `featured` | 平台精选推荐 |

#### 错误响应

| 状态码 | 描述 |
|--------|------|
| 401 | 未认证 |

---

## 9. 获取精选 Skill

### GET /api/v1/skills/featured

获取平台精选 Skill 列表（用于首页轮播等）。

#### 请求

```http
GET /api/v1/skills/featured HTTP/1.1
Host: api.vibelife.app
```

#### 响应

```json
{
  "featured": [
    {
      "skill_id": "bazi",
      "skill": {
        "id": "bazi",
        "name": "八字命理",
        "icon": "🔮",
        "color": "#D4A574",
        "tagline": "洞察命运玄机，把握人生方向",
        "preview_image": "/skills/bazi/featured.png"
      },
      "position": 1,
      "campaign": null
    },
    {
      "skill_id": "tarot",
      "skill": {
        "id": "tarot",
        "name": "塔罗占卜",
        "icon": "🎴",
        "color": "#EC4899",
        "tagline": "照见内心，获取指引"
      },
      "position": 2,
      "campaign": {
        "title": "新年限时体验",
        "badge": "限时免费"
      }
    }
  ]
}
```

---

## 10. 后端实现参考

### 10.1 路由文件

```python
# routes/skills.py

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, List
from pydantic import BaseModel

from services.agent.skill_loader import SkillLoader
from stores.skill_subscription_repo import SkillSubscriptionRepo
from services.skill_recommendation import SkillRecommendationService
from middleware.auth import get_current_user, get_optional_user

router = APIRouter(prefix="/api/v1/skills", tags=["skills"])


class SubscribeRequest(BaseModel):
    push_enabled: bool = True


class PushToggleRequest(BaseModel):
    enabled: bool


@router.get("")
async def list_skills(
    category: Optional[str] = None,
    subscribed: Optional[bool] = None,
    user=Depends(get_optional_user),
):
    """获取所有 Skill 列表"""
    skills = SkillLoader.get_all_skills()

    # 筛选
    if category:
        skills = [s for s in skills if s["category"] == category]

    # 获取用户订阅状态
    user_statuses = {}
    if user:
        subscriptions = await SkillSubscriptionRepo.get_user_subscriptions(user.id)
        user_statuses = {s.skill_id: s for s in subscriptions}

        if subscribed:
            skills = [s for s in skills if user_statuses.get(s["id"], {}).get("status") == "subscribed"]

    # 附加用户状态
    for skill in skills:
        sub = user_statuses.get(skill["id"])
        skill["user_status"] = {
            "subscribed": sub.status == "subscribed" if sub else False,
            "push_enabled": sub.push_enabled if sub else False,
            "trial_messages_used": sub.trial_messages_used if sub else 0,
            "trial_messages_remaining": (
                skill["pricing"].get("trial_messages", 0) - (sub.trial_messages_used if sub else 0)
            ) if skill["pricing"]["type"] != "free" else None,
        }

    # 分类统计
    categories = {
        "core": {"name": "核心能力", "count": len([s for s in skills if s["category"] == "core"])},
        "default": {"name": "基础功能", "count": len([s for s in skills if s["category"] == "default"])},
        "professional": {"name": "专业技能", "count": len([s for s in skills if s["category"] == "professional"])},
    }

    return {"skills": skills, "categories": categories, "total": len(skills)}


@router.get("/subscriptions")
async def get_subscriptions(user=Depends(get_current_user)):
    """获取用户订阅列表"""
    subscriptions = await SkillSubscriptionRepo.get_user_subscriptions(user.id)

    # 获取 Skill 元数据
    all_skills = SkillLoader.get_all_skills()
    skill_map = {s["id"]: s for s in all_skills}

    result = []
    for skill in all_skills:
        sub = next((s for s in subscriptions if s.skill_id == skill["id"]), None)
        result.append({
            "skill_id": skill["id"],
            "status": sub.status if sub else "not_subscribed",
            "push_enabled": sub.push_enabled if sub else False,
            "subscribed_at": sub.subscribed_at if sub else None,
            "can_unsubscribe": skill["category"] != "core",
            "trial_messages_used": sub.trial_messages_used if sub else 0,
        })

    return {
        "subscriptions": result,
        "summary": {
            "total_subscribed": len([s for s in result if s["status"] == "subscribed"]),
            "total_available": len(all_skills),
            "push_enabled_count": len([s for s in result if s["push_enabled"]]),
        }
    }


@router.post("/{skill_id}/subscribe")
async def subscribe_skill(
    skill_id: str,
    request: SubscribeRequest,
    user=Depends(get_current_user),
):
    """订阅 Skill"""
    skill = SkillLoader.get_skill(skill_id)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    # 检查是否已订阅
    existing = await SkillSubscriptionRepo.get(user.id, skill_id)
    if existing and existing.status == "subscribed":
        raise HTTPException(status_code=400, detail="Already subscribed")

    # 检查是否需要 Premium
    if skill["pricing"]["type"] == "premium" and not user.is_premium:
        # 检查试用次数
        trial_used = existing.trial_messages_used if existing else 0
        trial_limit = skill["pricing"].get("trial_messages", 0)
        if trial_used >= trial_limit:
            raise HTTPException(status_code=402, detail="Premium subscription required")

    # 创建/更新订阅
    subscription = await SkillSubscriptionRepo.subscribe(
        user_id=user.id,
        skill_id=skill_id,
        push_enabled=request.push_enabled,
    )

    return {
        "success": True,
        "subscription": subscription,
        "message": f"已成功订阅「{skill['name']}」",
    }


@router.post("/{skill_id}/unsubscribe")
async def unsubscribe_skill(skill_id: str, user=Depends(get_current_user)):
    """取消订阅 Skill"""
    skill = SkillLoader.get_skill(skill_id)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    # Core Skill 不可取消
    if skill["category"] == "core":
        raise HTTPException(status_code=400, detail="Core skill cannot be unsubscribed")

    # 检查是否已订阅
    existing = await SkillSubscriptionRepo.get(user.id, skill_id)
    if not existing or existing.status != "subscribed":
        raise HTTPException(status_code=400, detail="Not subscribed")

    # 更新订阅
    subscription = await SkillSubscriptionRepo.unsubscribe(user.id, skill_id)

    return {
        "success": True,
        "subscription": subscription,
        "message": f"已取消订阅「{skill['name']}」",
    }


@router.post("/{skill_id}/push")
async def toggle_push(
    skill_id: str,
    request: PushToggleRequest,
    user=Depends(get_current_user),
):
    """切换推送开关"""
    skill = SkillLoader.get_skill(skill_id)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    # 检查是否已订阅
    existing = await SkillSubscriptionRepo.get(user.id, skill_id)
    if not existing or existing.status != "subscribed":
        raise HTTPException(status_code=400, detail="Not subscribed")

    # 更新推送状态
    subscription = await SkillSubscriptionRepo.update_push(
        user_id=user.id,
        skill_id=skill_id,
        enabled=request.enabled,
    )

    action = "开启" if request.enabled else "关闭"
    return {
        "success": True,
        "subscription": subscription,
        "message": f"已{action}「{skill['name']}」的推送通知",
    }


@router.get("/recommendations")
async def get_recommendations(
    limit: int = Query(default=3, le=10),
    context: Optional[str] = None,
    user=Depends(get_current_user),
):
    """获取推荐 Skill"""
    recommendations = await SkillRecommendationService.get_recommendations(
        user_id=user.id,
        limit=limit,
        context=context,
    )

    return {
        "recommendations": recommendations,
        "generated_at": datetime.utcnow().isoformat(),
    }


@router.get("/featured")
async def get_featured():
    """获取精选 Skill"""
    # 可以从数据库或配置读取
    featured = [
        {"skill_id": "bazi", "position": 1, "campaign": None},
        {"skill_id": "zodiac", "position": 2, "campaign": None},
        {"skill_id": "tarot", "position": 3, "campaign": {"title": "新年限时体验", "badge": "限时免费"}},
    ]

    # 附加 Skill 信息
    for item in featured:
        skill = SkillLoader.get_skill(item["skill_id"])
        if skill:
            item["skill"] = {
                "id": skill["id"],
                "name": skill["name"],
                "icon": skill.get("icon", "💡"),
                "color": skill.get("color", "#6B7280"),
                "tagline": skill.get("showcase", {}).get("tagline", ""),
                "preview_image": skill.get("showcase", {}).get("preview_image"),
            }

    return {"featured": featured}
```

### 10.2 数据库操作

```python
# stores/skill_subscription_repo.py

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, List
from uuid import UUID

from stores.db import get_connection


@dataclass
class SkillSubscription:
    skill_id: str
    status: str
    push_enabled: bool
    subscribed_at: Optional[datetime]
    unsubscribed_at: Optional[datetime]
    trial_messages_used: int


class SkillSubscriptionRepo:

    @staticmethod
    async def get(user_id: UUID, skill_id: str) -> Optional[SkillSubscription]:
        """获取单个订阅"""
        query = """
            SELECT skill_id, status, push_enabled, subscribed_at, unsubscribed_at, trial_messages_used
            FROM user_skill_subscriptions
            WHERE user_id = $1 AND skill_id = $2
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id)
            if row:
                return SkillSubscription(**dict(row))
        return None

    @staticmethod
    async def get_user_subscriptions(user_id: UUID) -> List[SkillSubscription]:
        """获取用户所有订阅"""
        query = """
            SELECT skill_id, status, push_enabled, subscribed_at, unsubscribed_at, trial_messages_used
            FROM user_skill_subscriptions
            WHERE user_id = $1
        """
        async with get_connection() as conn:
            rows = await conn.fetch(query, user_id)
            return [SkillSubscription(**dict(row)) for row in rows]

    @staticmethod
    async def subscribe(user_id: UUID, skill_id: str, push_enabled: bool = True) -> SkillSubscription:
        """订阅 Skill"""
        query = """
            INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled, subscribed_at)
            VALUES ($1, $2, 'subscribed', $3, now())
            ON CONFLICT (user_id, skill_id)
            DO UPDATE SET status = 'subscribed', push_enabled = $3, subscribed_at = now(), updated_at = now()
            RETURNING skill_id, status, push_enabled, subscribed_at, unsubscribed_at, trial_messages_used
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id, push_enabled)
            return SkillSubscription(**dict(row))

    @staticmethod
    async def unsubscribe(user_id: UUID, skill_id: str) -> SkillSubscription:
        """取消订阅 Skill"""
        query = """
            UPDATE user_skill_subscriptions
            SET status = 'unsubscribed', push_enabled = false, unsubscribed_at = now(), updated_at = now()
            WHERE user_id = $1 AND skill_id = $2
            RETURNING skill_id, status, push_enabled, subscribed_at, unsubscribed_at, trial_messages_used
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id)
            return SkillSubscription(**dict(row))

    @staticmethod
    async def update_push(user_id: UUID, skill_id: str, enabled: bool) -> SkillSubscription:
        """更新推送状态"""
        query = """
            UPDATE user_skill_subscriptions
            SET push_enabled = $3, updated_at = now()
            WHERE user_id = $1 AND skill_id = $2
            RETURNING skill_id, status, push_enabled, subscribed_at, unsubscribed_at, trial_messages_used
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id, enabled)
            return SkillSubscription(**dict(row))

    @staticmethod
    async def increment_trial_usage(user_id: UUID, skill_id: str) -> int:
        """增加试用次数"""
        query = """
            INSERT INTO user_skill_subscriptions (user_id, skill_id, trial_messages_used)
            VALUES ($1, $2, 1)
            ON CONFLICT (user_id, skill_id)
            DO UPDATE SET trial_messages_used = user_skill_subscriptions.trial_messages_used + 1, updated_at = now()
            RETURNING trial_messages_used
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id)
            return row["trial_messages_used"]

    @staticmethod
    async def is_push_enabled(user_id: UUID, skill_id: str) -> bool:
        """检查推送是否开启（用于 ProactiveEngine）"""
        query = """
            SELECT push_enabled
            FROM user_skill_subscriptions
            WHERE user_id = $1 AND skill_id = $2 AND status = 'subscribed'
        """
        async with get_connection() as conn:
            row = await conn.fetchrow(query, user_id, skill_id)
            return row["push_enabled"] if row else False
```
