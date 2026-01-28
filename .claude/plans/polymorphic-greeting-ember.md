# Auth System: Email Verification + Bot Protection

## 需求
1. ✅ 保留 Google/Apple OAuth
2. ❌ 移除微信扫码登录
3. ➕ 邮箱密码注册（需邮箱验证，Resend 发送）
4. 🛡️ Cloudflare Turnstile 防机器人

## Registration Flow
```
1. 输入邮箱/密码 → Turnstile 验证 → 发送验证码 (Resend)
2. 输入 6 位验证码 → 验证成功 → 创建账户 → 返回 JWT
```

## Files to Create

### Backend
| File | Purpose |
|------|---------|
| `apps/api/services/identity/email_auth.py` | 邮箱注册/登录/验证服务 |
| `migrations/026_email_verification.sql` | 验证码存储表 |

### Frontend
| File | Purpose |
|------|---------|
| `apps/web/src/components/auth/EmailAuthForm.tsx` | 邮箱注册/登录表单 |
| `apps/web/src/app/api/auth/email/register/route.ts` | 注册代理 |
| `apps/web/src/app/api/auth/email/verify/route.ts` | 验证代理 |
| `apps/web/src/app/api/auth/email/login/route.ts` | 登录代理 |

## Files to Modify

### Backend
| File | Change |
|------|--------|
| `apps/api/services/identity/oauth.py` | 添加 `verify_turnstile()` |
| `apps/api/routes/account.py` | 移除微信，添加邮箱端点 |
| `apps/api/requirements.txt` | 添加 `resend` |

### Frontend
| File | Change |
|------|--------|
| `apps/web/package.json` | 添加 `@marsidev/react-turnstile` |
| `apps/web/src/components/auth/OAuthButtons.tsx` | 移除微信，添加 Turnstile |

---

## Implementation

### Database Migration (026_email_verification.sql)
```sql
CREATE TABLE email_verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,  -- 暂存密码
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_verification_email ON email_verification_codes(email);
CREATE INDEX idx_email_verification_expires ON email_verification_codes(expires_at);
```

### Backend: email_auth.py
```python
import os
import secrets
import bcrypt
import resend
from datetime import datetime, timedelta, timezone

resend.api_key = os.getenv("RESEND_API_KEY")
CF_SECRET_KEY = os.getenv("CF_SECRET_KEY", "")

class EmailAuthService:
    CODE_EXPIRY_MINUTES = 10

    @classmethod
    async def verify_turnstile(cls, token: str, ip: str) -> bool:
        if not CF_SECRET_KEY:
            return True
        async with httpx.AsyncClient() as client:
            res = await client.post(
                "https://challenges.cloudflare.com/turnstile/v0/siteverify",
                data={"secret": CF_SECRET_KEY, "response": token, "remoteip": ip}
            )
            return res.json().get("success", False)

    @classmethod
    async def send_verification_code(cls, email: str, password: str, turnstile_token: str, ip: str):
        """Step 1: 发送验证码"""
        # Turnstile 验证
        if not await cls.verify_turnstile(turnstile_token, ip):
            raise ValueError("人机验证失败")

        # 检查邮箱是否已注册
        existing = await UserRepository.get_auth_by_identifier("email", email)
        if existing:
            raise ValueError("该邮箱已注册")

        # 生成 6 位验证码
        code = "".join([str(secrets.randbelow(10)) for _ in range(6)])
        password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=cls.CODE_EXPIRY_MINUTES)

        # 存储验证码（覆盖旧的）
        async with get_connection() as conn:
            await conn.execute("""
                INSERT INTO email_verification_codes (email, code, password_hash, expires_at)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (email) DO UPDATE SET code = $2, password_hash = $3, expires_at = $4
            """, email.lower(), code, password_hash, expires_at)

        # 用 Resend 发送邮件
        resend.Emails.send({
            "from": os.getenv("RESEND_FROM", "VibeLife <noreply@vibelife.app>"),
            "to": email,
            "subject": "VibeLife 验证码",
            "html": f"""
                <h2>您的验证码</h2>
                <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px;">{code}</p>
                <p>验证码 {cls.CODE_EXPIRY_MINUTES} 分钟内有效</p>
            """
        })

        return {"success": True, "message": "验证码已发送"}

    @classmethod
    async def verify_code_and_register(cls, email: str, code: str):
        """Step 2: 验证码验证并创建账户"""
        async with get_connection() as conn:
            row = await conn.fetchrow("""
                SELECT code, password_hash, expires_at FROM email_verification_codes
                WHERE email = $1
            """, email.lower())

        if not row:
            raise ValueError("验证码不存在")
        if row["expires_at"] < datetime.now(timezone.utc):
            raise ValueError("验证码已过期")
        if row["code"] != code:
            raise ValueError("验证码错误")

        # 删除验证码
        async with get_connection() as conn:
            await conn.execute("DELETE FROM email_verification_codes WHERE email = $1", email.lower())

        # 创建用户
        user = await UserRepository.create()
        await UserRepository.create_auth(
            user_id=user["id"],
            auth_type="email",
            auth_identifier=email.lower(),
            auth_credential=row["password_hash"]
        )

        # 返回 JWT
        return {
            "access_token": JWTService.create_access_token(str(user["id"]), user["vibe_id"]),
            "refresh_token": JWTService.create_refresh_token(str(user["id"]), user["vibe_id"]),
            "user": {"user_id": str(user["id"]), "vibe_id": user["vibe_id"]}
        }

    @classmethod
    async def login(cls, email: str, password: str, turnstile_token: str, ip: str):
        """邮箱密码登录"""
        if not await cls.verify_turnstile(turnstile_token, ip):
            raise ValueError("人机验证失败")

        auth = await UserRepository.get_auth_by_identifier("email", email)
        if not auth:
            raise ValueError("邮箱或密码错误")

        if not bcrypt.checkpw(password.encode(), auth["auth_credential"].encode()):
            raise ValueError("邮箱或密码错误")

        user = await UserRepository.get_by_id(auth["user_id"])
        return {
            "access_token": JWTService.create_access_token(str(user["id"]), user["vibe_id"]),
            "refresh_token": JWTService.create_refresh_token(str(user["id"]), user["vibe_id"]),
            "user": {"user_id": str(user["id"]), "vibe_id": user["vibe_id"]}
        }
```

### Backend Endpoints (account.py)
```python
# 发送验证码
@router.post("/auth/email/register")
async def email_register(request: EmailRegisterRequest, req: Request):
    result = await EmailAuthService.send_verification_code(
        request.email, request.password, request.turnstile_token, get_client_ip(req)
    )
    return result

# 验证码验证
@router.post("/auth/email/verify")
async def email_verify(request: EmailVerifyRequest):
    result = await EmailAuthService.verify_code_and_register(request.email, request.code)
    return result

# 登录
@router.post("/auth/email/login")
async def email_login(request: EmailLoginRequest, req: Request):
    result = await EmailAuthService.login(
        request.email, request.password, request.turnstile_token, get_client_ip(req)
    )
    return result
```

### Frontend: EmailAuthForm.tsx
```tsx
"use client";
import { useState } from "react";
import { Turnstile } from "@marsidev/react-turnstile";

type Step = "input" | "verify";

export function EmailAuthForm() {
  const [mode, setMode] = useState<"login" | "register">("login");
  const [step, setStep] = useState<Step>("input");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [turnstileToken, setTurnstileToken] = useState("");

  const handleRegister = async () => {
    // Step 1: 发送验证码
    const res = await fetch("/api/auth/email/register", {
      method: "POST",
      body: JSON.stringify({ email, password, turnstile_token: turnstileToken })
    });
    if (res.ok) setStep("verify");
  };

  const handleVerify = async () => {
    // Step 2: 验证码验证
    const res = await fetch("/api/auth/email/verify", {
      method: "POST",
      body: JSON.stringify({ email, code })
    });
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem("vibelife_access_token", data.access_token);
      window.location.href = "/chat";
    }
  };

  const handleLogin = async () => {
    const res = await fetch("/api/auth/email/login", {
      method: "POST",
      body: JSON.stringify({ email, password, turnstile_token: turnstileToken })
    });
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem("vibelife_access_token", data.access_token);
      window.location.href = "/chat";
    }
  };

  if (step === "verify") {
    return (
      <div>
        <p>验证码已发送至 {email}</p>
        <input value={code} onChange={e => setCode(e.target.value)} placeholder="6位验证码" />
        <button onClick={handleVerify}>验证</button>
      </div>
    );
  }

  return (
    <form>
      <input type="email" value={email} onChange={...} placeholder="邮箱" />
      <input type="password" value={password} onChange={...} placeholder="密码" />
      <Turnstile siteKey={...} onSuccess={setTurnstileToken} />

      {mode === "register" ? (
        <button onClick={handleRegister}>注册</button>
      ) : (
        <button onClick={handleLogin}>登录</button>
      )}
    </form>
  );
}
```

---

## Environment Variables
```env
# Backend
CF_SECRET_KEY=0x...
RESEND_API_KEY=re_...
RESEND_FROM=VibeLife <noreply@vibelife.app>

# Frontend
NEXT_PUBLIC_CF_SITE_KEY=0x...
```

## Resend Setup
1. 注册 [Resend](https://resend.com) (免费 100 emails/day)
2. 添加并验证域名 vibelife.app
3. 获取 API Key

## Verification
1. 注册流程：输入邮箱密码 → 收到验证码 → 验证成功 → 登录
2. 登录流程：已注册用户可直接登录
3. Turnstile：无感验证拦截机器人
4. 错误处理：重复邮箱、错误验证码、过期验证码

## Documentation
实现完成后，输出文档到：`/home/aiscend/work/vibelife/docs/components/auth/`
