# 邮箱注册登录实现计划

## 需求
- 邮箱 + 密码注册（注册时必须验证邮箱）
- 邮箱 + 密码登录
- 密码重置

## 架构分析

### Better Auth 评估
Better Auth 是 TypeScript 框架，**不适用于本项目**（Python FastAPI 后端）。应基于现有架构扩展。

### 现有可复用组件
| 组件 | 文件 | 复用方式 |
|------|------|----------|
| JWT 服务 | `services/identity/jwt.py` | 直接复用，生成 access/refresh token |
| 密码哈希 | `stores/user_repo.py:28-54` | **已实现 bcrypt**，直接调用 |
| 用户创建 | `stores/user_repo.py` | 复用 `create_user()` |
| 认证路由 | `routes/account.py` | 添加邮箱端点 |
| OAuth 模式 | `services/identity/oauth.py` | 参考注册/登录流程 |

### 需新增组件
| 组件 | 文件 | 说明 |
|------|------|------|
| 验证码表 | `migrations/021_email_verification.sql` | 存储邮箱验证码 |
| 邮件发送 | `services/notification/email_sender.py` | SMTP 发送验证码 |
| 邮箱认证服务 | `services/identity/email.py` | 注册/登录/重置逻辑 |
| 前端表单 | `components/auth/Email*.tsx` | 登录/注册/重置表单 |

### 单一登录策略
现有系统强制每个邮箱只能用一种登录方式（见 `oauth.py` 冲突检查）。邮箱认证需遵循此策略：
- 已用 OAuth 注册的邮箱不能再用密码注册
- 已用密码注册的邮箱不能再用 OAuth 登录

## 实现步骤

### Phase 1: 后端
1. **创建邮箱认证服务** - `apps/api/services/identity/email.py`
   - `register(email, password)` - 注册（无验证码）
   - `login(email, password)` - 登录
   - 复用现有 `user_repo.hash_password()` 和 `verify_password()`

2. **添加邮箱认证路由** - `apps/api/routes/account.py`
   - `POST /account/auth/email/register` - 限流 5次/小时/IP
   - `POST /account/auth/email/login` - 限流 10次/分钟/IP

3. **添加限流中间件** - 使用 `slowapi`
   ```python
   @limiter.limit("5/hour")  # 注册
   @limiter.limit("10/minute")  # 登录
   ```

### Phase 2: 前端
4. **创建邮箱登录表单** - `apps/web/src/components/auth/EmailLoginForm.tsx`
   - 邮箱输入、密码输入、登录按钮

5. **创建邮箱注册表单** - `apps/web/src/components/auth/EmailRegisterForm.tsx`
   - 邮箱输入、密码输入（8字符+）、确认密码、注册按钮

6. **更新登录页面** - `apps/web/src/app/auth/login/page.tsx`
   - 添加邮箱登录表单（与 OAuth 并列）

7. **创建注册页面** - `apps/web/src/app/auth/register/page.tsx`

8. **更新 API 客户端** - `apps/web/src/lib/api.ts`
   - 添加 `emailRegister()`, `emailLogin()`

## 安全措施（无需额外服务）
| 措施 | 实现 | 说明 |
|------|------|------|
| 登录限流 | slowapi | 10次/分钟/IP |
| 注册限流 | slowapi | 5次/小时/IP |
| 密码强度 | 前后端校验 | ≥8字符 |
| 邮箱校验 | email-validator | 严格格式验证 |
| 密码哈希 | bcrypt（已有） | 安全存储 |

## 验证方式
1. 启动测试环境 (`/vibelife-test start`)
2. 测试注册: 输入邮箱+密码 -> 注册成功 -> 自动登录
3. 测试登录: 输入邮箱+密码 -> 登录成功
4. 测试限流: 连续失败登录 -> 被限制
5. 测试冲突: 已注册邮箱再注册 -> 提示已存在

## 配置需求
无额外配置，使用现有 JWT 和 bcrypt

## 后续可扩展
- 邮箱验证（需邮件服务）
- 密码重置（需邮件服务）
- reCAPTCHA/hCaptcha
