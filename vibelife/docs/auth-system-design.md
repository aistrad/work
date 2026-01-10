# VibeLife 登录体系设计文档 v1.0

> **版本**: 1.0
> **日期**: 2026-01-10
> **状态**: 已实现

---

## 一、核心设计原则

```
游客��先 → 价值先行 → 转化自然
```

用户无需注册即可体验核心价值，在感受到「被理解」后自然转化。

---

## 二、用户身份状态

| 状态 | 标识 | 权限 |
|------|------|------|
| **游客** | session_id (cookie) | 完整 onboarding + 简版报告 |
| **免费用户** | user_id + vibe_id | 简版报告 + 有限次对话/功能 |
| **付费用户** | user_id + subscription | 完整报告 + 无限对话 + 全功能 |

---

## 三、免费用户权限配置

```python
# apps/api/services/identity/usage_limits.py

FREE_USER_LIMITS = {
    "chat_message": {"daily": 10},           # 每日对话次数
    "relationship_analysis": {"total": 3},   # 关系模拟器总次数
    "life_kline": {"total": 3},              # 人生K线查看次数
    "report_generation": {"total": 1},       # 简版报告生成次数
}
```

---

## 四、完整用户流程

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           VibeLife 用户流程                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [游客] Landing Page                                                        │
│      │                                                                      │
│      ▼                                                                      │
│  输入生辰 → AI访谈 → 简版报告 ──────────────────────────────────────┐       │
│      │                                                              │       │
│      │ (后端生成 session_id，存 cookie)                             │       │
│      │                                                              │       │
│      ▼                                                              ▼       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         付费墙 / 注册墙                              │   │
│  │                                                                     │   │
│  │   「解锁完整报告 + 高清海报」                                        │   │
│  │                                                                     │   │
│  │   ┌─────────────────────────────────────────────────────────────┐  │   │
│  │   │  注册方式（统一展示，用户自选）                               │  │   │
│  │   │                                                             │  │   │
│  │   │  [Continue with Google]                                     │  │   │
│  │   │  [Continue with Apple]                                      │  │   │
│  │   │  ─────────── or ───────────                                 │  │   │
│  │   │  [手机号注册]  [邮箱注册]                                     │  │   │
│  │   └─────────────────────────────────────────────────────────────┘  │   │
│  │                                                                     │   │
│  │   已有账号？ [登录]                                                 │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│      │                                                                      │
│      ▼                                                                      │
│  [注册成功] → 自动关联 session 数据                                         │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  「是否立即购买完整报告？」                                          │   │
│  │                                                                     │   │
│  │  [立即购买 ¥19.9]     [稍后再说，先体验]                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│      │                           │                                          │
│      ▼                           ▼                                          │
│  [付费用户]                   [免费用户]                                    │
│  完整报告+全功能              简版报告+有限次数                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 五、技术实现

### 5.1 数据库表

```sql
-- migrations/011_guest_sessions.sql

-- 游客会话表
CREATE TABLE guest_sessions (
    id UUID PRIMARY KEY,
    session_id VARCHAR(32) UNIQUE NOT NULL,  -- gs_xxxxxxxxxxxx
    birth_datetime TIMESTAMPTZ,
    birth_location VARCHAR(255),
    gender VARCHAR(20),
    voice_mode VARCHAR(20) DEFAULT 'warm',
    skill VARCHAR(50),
    interview_responses JSONB DEFAULT '{}',
    focus_areas JSONB DEFAULT '[]',
    converted_user_id UUID REFERENCES vibe_users(id),
    converted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,  -- 30天后过期
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户使用次数表
CREATE TABLE user_usage (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    usage_type VARCHAR(50) NOT NULL,
    count INT DEFAULT 0,
    period_start DATE NOT NULL,
    period_type VARCHAR(20) DEFAULT 'daily',
    UNIQUE(user_id, usage_type, period_start, period_type)
);

-- 密码重置令牌表
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES vibe_users(id),
    token VARCHAR(100) UNIQUE NOT NULL,
    token_type VARCHAR(20) NOT NULL,  -- email | phone
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,  -- 1小时后过期
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.2 后端服务

| 文件 | 说明 |
|------|------|
| `stores/guest_session_repo.py` | 游客会话数据访问层 |
| `stores/usage_repo.py` | 使用次数数据访问层 |
| `stores/password_reset_repo.py` | 密码重置令牌数据访问层 |
| `services/identity/guest_session.py` | 游客会话业务逻辑 |
| `services/identity/usage_limits.py` | 使用次数限制业务逻辑 |
| `services/identity/password_reset.py` | 密码重置业务逻辑 |
| `routes/guest.py` | 游客会话 API 路由 |

### 5.3 API 端点

#### 游客会话

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/api/v1/guest/session` | 创建游客会话 |
| GET | `/api/v1/guest/session` | 获取当前游客会话 |
| PUT | `/api/v1/guest/session/onboarding` | 保存 onboarding 数据 |
| DELETE | `/api/v1/guest/session` | 清除游客会话 |

#### 认证

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/api/v1/auth/register` | 注册（支持 session_id 关联） |
| POST | `/api/v1/auth/login` | 登录 |
| POST | `/api/v1/auth/oauth/google` | Google OAuth 登录 |
| POST | `/api/v1/auth/oauth/apple` | Apple OAuth 登录 |
| POST | `/api/v1/auth/password/reset-request` | 请求密码重置 |
| POST | `/api/v1/auth/password/verify-token` | 验证重置令牌 |
| POST | `/api/v1/auth/password/reset` | 重置密码 |

### 5.4 前端组件

| 文件 | 说明 |
|------|------|
| `hooks/useGuestSession.ts` | 游客会话管理 hook |
| `components/auth/OAuthButtons.tsx` | Google/Apple OAuth 按钮 |
| `components/auth/PurchasePrompt.tsx` | 注册后购买询问弹窗 |
| `app/auth/login/page.tsx` | 登录页面（含 OAuth） |
| `app/auth/register/page.tsx` | 注册页面 |
| `app/auth/forgot-password/page.tsx` | 忘记密码页面 |
| `app/auth/reset-password/page.tsx` | 重置密码页面 |

---

## 六、配置要求

### 6.1 环境变量

```bash
# OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
APPLE_CLIENT_ID=your_apple_client_id
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id

# 前端
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
NEXT_PUBLIC_APPLE_CLIENT_ID=your_apple_client_id
```

### 6.2 CORS 配置

确保 `VIBELIFE_CORS_ORIGINS` 包含前端域名，并启用 `credentials: true`。

---

## 七、访谈决策记录

| 问题 | 决策 |
|------|------|
| 游客数据存储 | 后端临时会话 (session_id)，30天有效期 |
| 地区适配 | 统一展示所有选项，用户自选 |
| 注册+支付 | 先注册 → 再问是否购买 |
| 支付失败 | 账号已创建，可登录看简版 |
| OAuth 关联 | 只看后台数据库，不检测 localStorage |
| 登录入口 | 双入口（导航栏 + 付费墙） |
| 密码找回 | 邮箱/手机都支持 |
| 手机号验证 | 保持「手机号 + 密码」 |
| 国际区号 | 支持所有（第一阶段先不实现） |

---

## 八、后续迭代

- [ ] 国际区号支持
- [ ] 短信验证码登录
- [ ] 微信登录（大陆用户）
- [ ] 邮件发送服务集成
- [ ] 短信发送服务集成
