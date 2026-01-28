# 测试用户配置指南

## 当前设置

**默认测试用户**: `iaaichina@163.com` (Vibe ID: `VB-YRZ5YYVR`)

这个用户目前在以下位置被引用：
- 📄 文档: `docs/deployment-test.md` (作为示例)
- 📄 文档: `docs/config-test.md` (作为示例)
- 🌐 前端: `apps/web/src/app/auth/dev-login/page.tsx` (现在已设置为默认值)

---

## 如何修改默认测试用户

### 方案 1: 修改前端默认值（推荐）

编辑文件: `apps/web/src/app/auth/dev-login/page.tsx`

```typescript
export default function DevLoginPage() {
  const router = useRouter();
  // 默认测试用户 - 可以在这里修改
  const DEFAULT_TEST_EMAIL = "iaaichina@163.com"; // ← 修改这里
  const DEFAULT_TEST_VIBE_ID = ""; // 或者使用 Vibe ID: VB-YRZ5YYVR

  const [email, setEmail] = useState(DEFAULT_TEST_EMAIL);
  const [vibeId, setVibeId] = useState(DEFAULT_TEST_VIBE_ID);
  // ...
}
```

修改后需要重启前端服务：

```bash
cd /home/aiscend/work/vibelife/apps/web
pnpm build
nohup pnpm start -H 0.0.0.0 -p 8232 > /tmp/vibelife-web-8232.log 2>&1 &
```

### 方案 2: 创建新的测试用户

使用管理脚本创建新的测试用户：

```bash
cd /home/aiscend/work/vibelife/apps/api

# 查看当前测试用户
python scripts/manage_test_user.py

# 列出所有测试用户
python scripts/manage_test_user.py list

# 创建新测试用户（交互式）
python scripts/manage_test_user.py create
```

创建完成后，将新的邮箱地址更新到前端配置中。

### 方案 3: 使用环境变量（灵活方案）

如果想要更灵活的配置，可以使用环境变量：

1. 修改前端代码使用环境变量：

```typescript
// apps/web/src/app/auth/dev-login/page.tsx
const DEFAULT_TEST_EMAIL = process.env.NEXT_PUBLIC_DEV_LOGIN_EMAIL || "";
const DEFAULT_TEST_VIBE_ID = process.env.NEXT_PUBLIC_DEV_LOGIN_VIBE_ID || "";
```

2. 在 `.env.local` 中设置：

```bash
# apps/web/.env.local
NEXT_PUBLIC_DEV_LOGIN_EMAIL=your-test@example.com
NEXT_PUBLIC_DEV_LOGIN_VIBE_ID=VB-XXXXXXXX
```

---

## 测试用户管理脚本使用

### 基本命令

```bash
cd /home/aiscend/work/vibelife/apps/api

# 显示当前默认测试用户
python scripts/manage_test_user.py

# 列出所有测试用户
python scripts/manage_test_user.py list

# 创建新测试用户
python scripts/manage_test_user.py create
```

### 创建测试用户示例

```bash
$ python scripts/manage_test_user.py create

请输入邮箱地址 (例如: test@example.com): dev@vibelife.com
请输入显示名称 (可选): 开发测试

✅ 测试用户创建成功!
   Email: dev@vibelife.com
   Vibe ID: VB-TEST12AB34CD
   Display Name: 开发测试
   User ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

💡 你可以使用这个邮箱在 dev-login 页面登录
```

---

## 快速切换测试用户

如果你需要频繁切换不同的测试用户：

### 创建快捷登录脚本

```bash
# ~/dev-login.sh
#!/bin/bash
# 快速 dev-login 脚本

EMAIL="${1:-iaaichina@163.com}"

curl -X POST http://127.0.0.1:8100/api/v1/account/auth/dev-login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\"}" \
  | jq .

echo ""
echo "✅ 登录成功! 使用 email: $EMAIL"
```

使用方式：

```bash
chmod +x ~/dev-login.sh

# 使用默认邮箱
~/dev-login.sh

# 使用指定邮箱
~/dev-login.sh dev@vibelife.com
```

---

## 注意事项

1. **安全性**: Dev Login 仅在非生产环境可用（`VIBELIFE_ENV != production`）
2. **前端缓存**: 修改后需要重新构建前端（`pnpm build`）
3. **数据库**: 确保测试用户存在于数据库中
4. **多用户测试**: 可以创建多个测试用户用于不同场景

---

## 常见问题

### Q: 为什么我修改了代码但没有生效？

A: 需要重新构建前端：

```bash
cd /home/aiscend/work/vibelife/apps/web
pnpm build
pkill -f "next.*8232"
nohup pnpm start -H 0.0.0.0 -p 8232 > /tmp/vibelife-web-8232.log 2>&1 &
```

### Q: 如何重置测试用户？

A: 可以通过 SQL 直接修改：

```bash
PGPASSWORD="<PASSWORD>" psql -h 106.37.170.238 -p 8224 -U postgres -d vibelife

-- 查看用户
SELECT ua.auth_identifier, u.vibe_id, up.profile->'account'->>'display_name'
FROM vibe_user_auth ua
JOIN vibe_users u ON ua.user_id = u.id
LEFT JOIN unified_profiles up ON ua.user_id = up.user_id
WHERE ua.auth_identifier = 'iaaichina@163.com';

-- 修改显示名称
UPDATE unified_profiles
SET profile = jsonb_set(profile, '{account,display_name}', '"新名称"'::jsonb)
WHERE user_id = (
  SELECT user_id FROM vibe_user_auth WHERE auth_identifier = 'iaaichina@163.com'
);
```

### Q: 我想使用 Vibe ID 而不是邮箱登录？

A: 修改前端默认值：

```typescript
const DEFAULT_TEST_EMAIL = "";
const DEFAULT_TEST_VIBE_ID = "VB-YRZ5YYVR"; // 使用 Vibe ID
```

---

## 相关文件

- 前端登录页面: `apps/web/src/app/auth/dev-login/page.tsx`
- 后端登录接口: `apps/api/routes/account.py` (line 379-450)
- 用户管理脚本: `apps/api/scripts/manage_test_user.py`
- 部署文档: `docs/deployment-test.md`
