# VibeLife 项目深度代码审查报告

> **审查日期**: 2026-01-08
> **审查范围**: 后端 API、前端 Web、数据库、基础设施
> **审查方法**: 三个并行 Explore Agent 深度分析

---

## 执行摘要

| 维度 | 评分 | 说明 |
|------|------|------|
| **后端完成度** | 75% | 核心引擎完备，但持久化和支付有缺口 |
| **前端完成度** | 45% | 组件存在但大量未接入页面 |
| **安全性** | ⚠️ 中风险 | 多个 Critical 级安全问题 |
| **数据库** | 60% | Schema 与代码不匹配 |
| **支付系统** | 30% | 骨架阶段，未配置密钥 |

---

## 已修复问题清单

### CRITICAL 安全问题 (已修复)

| # | 问题 | 文件 | 修复方案 |
|---|------|------|----------|
| 1 | 硬编码 JWT 密钥 | `services/identity/jwt.py` | 移除默认值，强制环境变量 |
| 2 | 硬编码数据库密码 | `stores/db.py` | 移除默认值，强制环境变量 |
| 3 | 敏感端点缺少认证 | `routes/billing.py` | 添加 `get_current_user` 依赖 + 权限验证 |
| 4 | 开发支付绕过端点暴露 | `routes/payment.py` | 添加 `_is_development_mode()` 检查 |

### HIGH 优先级问题 (已修复)

| # | 问题 | 文件 | 修复方案 |
|---|------|------|----------|
| 5 | 异常被静默吞掉 | `routes/chat.py` | 添加 logging.error 记录异常 |
| 6 | Webhook 签名验证缺失 | `routes/payment.py` | Airwallex webhook 添加 HMAC-SHA256 签名验证 |
| 7 | 前端 Token 刷新 bug | `lib/api.ts` | 刷新后重新获取 token 而非使用旧变量 |

---

## 修复详情

### 1. JWT 密钥安全 (`jwt.py`)

**修复前:**
```python
SECRET = os.getenv("VIBELIFE_JWT_SECRET", "dev-secret-key-change-in-production")
```

**修复后:**
```python
@classmethod
def _get_secret(cls) -> str:
    secret = os.getenv("VIBELIFE_JWT_SECRET")
    if not secret:
        raise RuntimeError("CRITICAL: VIBELIFE_JWT_SECRET environment variable is not set.")
    return secret
```

### 2. 数据库连接安全 (`db.py`)

**修复前:**
```python
return os.getenv("VIBELIFE_DB_URL", "postgresql://postgres:password@localhost:5432/vibelife")
```

**修复后:**
```python
def get_db_url() -> str:
    db_url = os.getenv("VIBELIFE_DB_URL")
    if not db_url:
        raise RuntimeError("CRITICAL: VIBELIFE_DB_URL environment variable is not set.")
    return db_url
```

### 3. Billing 端点认证 (`billing.py`)

**修复前:**
```python
@router.get("/subscription/{user_id}")
async def get_user_subscription(user_id: str):
    # 任何人可查询任意用户
```

**修复后:**
```python
@router.get("/subscription/{user_id}")
async def get_user_subscription(
    user_id: str,
    current_user: CurrentUser = Depends(get_current_user)
):
    if str(current_user.user_id) != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
```

### 4. 开发端点保护 (`payment.py`)

**修复前:**
```python
@router.post("/dev-complete")
async def dev_complete_payment(session_id: str = Query(...)):
    # 生产环境也可访问
```

**修复后:**
```python
def _is_development_mode() -> bool:
    env = os.getenv("VIBELIFE_ENV", "production").lower()
    return env in ("development", "dev", "local")

@router.post("/dev-complete")
async def dev_complete_payment(session_id: str = Query(...)):
    if not _is_development_mode():
        raise HTTPException(status_code=403, detail="Only available in development mode")
```

### 5. 异常日志记录 (`chat.py`)

**修复前:**
```python
except Exception:
    pass  # 静默吞掉
```

**修复后:**
```python
except Exception as e:
    import logging
    logging.error(f"Failed to get user profile for {user_id}: {e}")
```

### 6. Airwallex Webhook 签名验证 (`payment.py`)

**新增:**
```python
airwallex_webhook_secret = os.getenv("AIRWALLEX_WEBHOOK_SECRET")
if airwallex_webhook_secret:
    expected_signature = hmac.new(
        airwallex_webhook_secret.encode(),
        (timestamp + payload.decode()).encode(),
        hashlib.sha256
    ).hexdigest()
    if not hmac.compare_digest(signature, expected_signature):
        raise HTTPException(status_code=400, detail="Invalid signature")
```

### 7. 前端 Token 刷新 (`api.ts`)

**修复前:**
```typescript
if (refreshed) {
    headers["Authorization"] = `Bearer ${accessToken}`;  // 使用旧 token
}
```

**修复后:**
```typescript
if (refreshed) {
    const { accessToken: newAccessToken } = getTokens();  // 获取新 token
    const newHeaders = { ...headers, "Authorization": `Bearer ${newAccessToken}` };
}
```

---

## 待修复问题 (后续迭代)

### 数据库问题

| # | 问题 | 说明 |
|---|------|------|
| 1 | 表名不匹配 | 代码用 `vibe_users`，Schema 定义 `users` |
| 2 | 向量维度混乱 | 1024/1536/3072 三种维度混用 |
| 3 | 无事务支持 | 所有 DB 操作无事务包装 |
| 4 | 缺失表 | `skill_profiles`, `skill_conversations` 等 |

### 前端问题

| # | 问题 | 说明 |
|---|------|------|
| 1 | 流式响应未实现 | ChatContainer 使用同步 fetch |
| 2 | ~12 个组件未接入 | LifeKLine, IdentityPrism 等 |
| 3 | 聊天消息无持久化 | 导航后丢失 |

### 支付系统

| # | 问题 | 说明 |
|---|------|------|
| 1 | Stripe 密钥未配置 | `.env` 中被注释 |
| 2 | 订阅管理是 stub | 返回 mock 数据 |

---

## 环境变量要求

修复后，以下环境变量**必须**设置：

```bash
# 必需 (无默认值)
VIBELIFE_JWT_SECRET=<强随机密钥>
VIBELIFE_DB_URL=postgresql://user:pass@host:5432/vibelife

# 生产环境必需
VIBELIFE_ENV=production
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
AIRWALLEX_WEBHOOK_SECRET=<webhook密钥>
```

---

## 修改文件清单

| 文件 | 修改类型 |
|------|----------|
| `apps/api/services/identity/jwt.py` | 安全加固 |
| `apps/api/stores/db.py` | 安全加固 |
| `apps/api/routes/billing.py` | 添加认证 |
| `apps/api/routes/payment.py` | 安全加固 + Webhook 验证 |
| `apps/api/routes/chat.py` | 异常处理 |
| `apps/web/src/lib/api.ts` | Token 刷新修复 |

---

## 总结

本次代码审查发现并修复了 **7 个关键问题**，包括：
- 4 个 CRITICAL 安全漏洞
- 3 个 HIGH 优先级 bug

剩余问题主要集中在数据库 Schema 一致性、前端组件接入、支付系统完善等方面，建议在后续迭代中逐步解决。
