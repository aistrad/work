# 用户认证系统重构计划

## 目标
- 仅保留 Google、Apple、微信扫码三种 OAuth 登录
- 移除邮箱/密码登录（手机短信预留但暂不启用）
- 单一登录方式（每个账户只能用一种方式登录）
- 完整账户注销功能（GDPR 合规，30天后硬删除）

---

## Phase 1: 数据库迁移

### 新建迁移文件
**`apps/api/stores/migrations/007_auth_refactor.sql`**
```sql
-- 微信扫码会话表
CREATE TABLE wechat_login_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id VARCHAR(64) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    openid VARCHAR(64),
    unionid VARCHAR(64),
    user_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
);

-- 账户注销字段
ALTER TABLE vibe_users
ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS deletion_scheduled_at TIMESTAMP;

-- 索引
CREATE INDEX idx_wechat_sessions_scene ON wechat_login_sessions(scene_id);
CREATE INDEX idx_users_pending_deletion ON vibe_users(status, deletion_scheduled_at)
WHERE status = 'pending_deletion';
```

---

## Phase 2: 后端 - 微信扫码登录

### 新建文件
1. **`apps/api/services/identity/wechat.py`** - 微信 OAuth 服务
   - `generate_qrcode()` - 生成二维码 URL
   - `poll_status(scene_id)` - 轮询扫码状态
   - `handle_callback(code)` - 处理微信回调
   - `wechat_login(openid, user_info)` - 创建/登录用户

### 修改文件
2. **`apps/api/routes/account.py`** - 新增端点
   - `GET /account/auth/wechat/qrcode` - 获取二维码
   - `GET /account/auth/wechat/status/{scene_id}` - 轮询状态
   - `POST /account/auth/wechat/callback` - 微信回调

3. **`.env.example`** - 新增配置
   ```
   WECHAT_APP_ID=
   WECHAT_APP_SECRET=
   ```

---

## Phase 3: 后端 - 单一登录方式限制

### 修改文件
1. **`apps/api/services/identity/oauth.py`** (L82-95, L211-223)
   - 删除"链接已有账户"逻辑
   - 新增检查：如果邮箱已注册其他方式，返回错误

2. **`apps/api/stores/user_repo.py`** - 新增方法
   - `get_user_auth_count(user_id)` - 获取认证方式数量

---

## Phase 4: 后端 - 移除邮箱密码认证

### 删除文件
- `apps/api/services/identity/password_reset.py`
- `apps/api/stores/password_reset_repo.py`

### 修改文件
1. **`apps/api/services/identity/auth.py`**
   - 删除 `register()` 方法
   - 删除 `login()` 方法
   - 保留 `refresh_token()` 和依赖函数

2. **`apps/api/routes/account.py`**
   - 删除端点：`/auth/register`, `/auth/login`
   - 删除端点：`/auth/password/reset-request`, `/auth/password/reset`
   - 删除模型：`RegisterRequest`, `LoginRequest`, `PasswordResetRequest`

3. **`apps/api/services/identity/__init__.py`**
   - 移除 `PasswordResetService` 导出

---

## Phase 5: 后端 - 账户注销功能

### 新建文件
1. **`apps/api/services/identity/account_deletion.py`**
   - `request_deletion(user_id)` - 请求注销（软删除）
   - `cancel_deletion(user_id)` - 取消注销
   - `process_scheduled_deletions()` - 处理到期硬删除

2. **`apps/api/workers/account_deletion_worker.py`**
   - 后台 Worker，每小时检查并执行硬删除

### 修改文件
3. **`apps/api/routes/account.py`** - 新增端点
   - `POST /account/auth/delete-account` - 请求注销
   - `POST /account/auth/cancel-deletion` - 取消注销
   - `GET /account/auth/deletion-status` - 查询状态

4. **`apps/api/main.py`** - 启动 Worker

---

## Phase 6: 前端 - 登录页面重构

### 新建文件
1. **`apps/web/src/components/auth/WechatLoginButton.tsx`**
2. **`apps/web/src/components/auth/WechatQRModal.tsx`**

### 修改文件
3. **`apps/web/src/app/auth/login/page.tsx`**
   - 删除 `LoginForm` 组件（邮箱密码表单）
   - 删除 `AuthDivider`
   - 新增 `WechatLoginButton`

4. **`apps/web/src/components/auth/OAuthButtons.tsx`**
   - 新增微信按钮

5. **`apps/web/src/lib/api.ts`**
   - 删除：`register()`, `login()`, `requestPasswordReset()`, `resetPassword()`
   - 新增：`getWechatQRCode()`, `pollWechatStatus()`

6. **`apps/web/src/providers/AuthProvider.tsx`**
   - 删除：`login`, `register`, `registerWithSession` 方法

### 删除文件
- `apps/web/src/app/auth/register/page.tsx`
- `apps/web/src/app/auth/forgot-password/page.tsx`
- `apps/web/src/app/auth/reset-password/page.tsx`
- `apps/web/src/app/api/auth/login/route.ts`
- `apps/web/src/app/api/auth/register/route.ts`

---

## Phase 7: 前端 - 账户注销 UI

### 修改文件
1. **`apps/web/src/app/settings/page.tsx`**
   - 新增"账户管理"菜单项
   - 新增注销确认流程

### 新建文件
2. **`apps/web/src/components/settings/AccountDeletionSection.tsx`**

---

## Phase 8: 测试更新

### 修改文件
1. **`apps/api/tests/integration/routes/test_account.py`**
   - 删除：`TestRegisterEndpoint`, `TestLoginEndpoint`, `TestPasswordResetEndpoints`
   - 新增：`TestWechatOAuthEndpoint`, `TestAccountDeletionEndpoints`
   - 修改：OAuth 测试添加单一登录方式验证

### 新建文件
2. **`apps/api/tests/integration/routes/test_wechat_oauth.py`**
3. **`apps/api/tests/integration/routes/test_account_deletion.py`**

---

## 关键文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `apps/api/services/identity/wechat.py` | 新建 | 微信 OAuth 服务 |
| `apps/api/services/identity/account_deletion.py` | 新建 | 账户注销服务 |
| `apps/api/workers/account_deletion_worker.py` | 新建 | 硬删除 Worker |
| `apps/api/routes/account.py` | 修改 | 路由增删 |
| `apps/api/services/identity/oauth.py` | 修改 | 单一登录限制 |
| `apps/api/services/identity/auth.py` | 修改 | 删除密码认证 |
| `apps/web/src/app/auth/login/page.tsx` | 修改 | 纯 OAuth 登录 |
| `apps/web/src/components/auth/WechatQRModal.tsx` | 新建 | 微信二维码弹窗 |

---

## 验证步骤

### 后端测试
```bash
cd apps/api
pytest tests/integration/routes/test_account.py -v
pytest tests/integration/routes/test_wechat_oauth.py -v
pytest tests/integration/routes/test_account_deletion.py -v
```

### 前端测试
```bash
cd apps/web
pnpm dev
# 访问 http://localhost:3000/auth/login
# 验证: 只显示 Google/Apple/微信按钮，无邮箱密码表单
```

### E2E 测试
```bash
# 测试完整登录流程
npx playwright test tests/e2e/auth.spec.ts
```

### 手动验证
1. Google OAuth 登录 → 成功创建新用户
2. 同邮箱 Apple OAuth → 应返回错误（单一登录方式）
3. 微信扫码登录 → 生成二维码 → 轮询 → 登录成功
4. 账户注销 → 30天等待期 → 取消注销
5. 账户注销 → Worker 硬删除验证

---

## 未解决问题

1. **微信开放平台配置** - 需要确认是否已有网站应用审核
2. **现有用户迁移** - 已用邮箱密码注册的用户如何处理？建议：保留一个月过渡期
3. **短信服务商** - 手机短信备用功能使用哪个服务商？
