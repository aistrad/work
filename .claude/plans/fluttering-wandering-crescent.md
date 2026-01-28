# 隐私合盘配对系统实现计划

## 目标

解决合盘双方都不想透露出生信息的隐私痛点，实现两种模式：
1. **Vibe 配对码**：双方都是用户，通过配对码互相合盘
2. **VibeLink 邀请链接**：一方生成链接邀请新用户

## 核心原则

- 双方都必须同意才能合盘
- 合盘结果**不展示任何原始出生数据**
- 每人可单独删除自己的合盘记录

## 设计决策

- **配对码**：直接复用现有 Vibe ID (VB-XXXXXXXX)，无需新建
- **通知方式**：支持微信卡片消息
- **邀请页风格**：密影海报风格，神秘感设计，强调"有人想和你看缘分"

---

## 数据库设计

### 新表 1: `pairing_requests`

```sql
CREATE TABLE pairing_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES vibe_users(id),
    target_vibe_id VARCHAR(20) NOT NULL,
    target_user_id UUID REFERENCES vibe_users(id),
    relationship_type VARCHAR(50) NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',  -- pending/accepted/rejected/expired
    expires_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 新表 2: `synastry_results`

```sql
CREATE TABLE synastry_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES vibe_users(id),
    partner_id UUID NOT NULL REFERENCES vibe_users(id),
    relationship_type VARCHAR(50) NOT NULL,
    partner_display_name VARCHAR(100),
    overall_score INT NOT NULL,
    overall_label VARCHAR(50),
    dimensions JSONB DEFAULT '[]',
    strengths JSONB DEFAULT '[]',
    challenges JSONB DEFAULT '[]',
    advice JSONB DEFAULT '[]',
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(owner_id, partner_id)
);
```

### 新表 3: `invite_links`

```sql
CREATE TABLE invite_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES vibe_users(id),
    token VARCHAR(32) UNIQUE NOT NULL,
    relationship_type VARCHAR(50) NOT NULL,
    invite_message TEXT,
    status VARCHAR(20) DEFAULT 'active',  -- active/used/expired
    used_by_id UUID REFERENCES vibe_users(id),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## API 端点设计

### 配对请求 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/pairing/request` | 发起配对请求 |
| POST | `/api/v1/pairing/accept` | 接受配对请求 |
| POST | `/api/v1/pairing/reject` | 拒绝配对请求 |
| GET | `/api/v1/pairing/pending` | 获取待处理请求 |

### 邀请链接 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/v1/pairing/link` | 生成邀请链接 |
| GET | `/api/v1/pairing/link/:token` | 获取邀请信息（公开） |
| POST | `/api/v1/pairing/link/:token/accept` | 接受邀请 |

---

## 前端组件

### 新页面

| 路径 | 描述 |
|------|------|
| `/shared/invite/[token]` | 邀请链接页面（密影海报风格） |

### 新卡片组件

| 组件 | 文件路径 | 用途 |
|------|----------|------|
| `PairingCodeCard` | `apps/web/src/skills/synastry/cards/PairingCodeCard.tsx` | 显示配对码 + 复制/分享 |
| `PairingRequestCard` | `apps/web/src/skills/synastry/cards/PairingRequestCard.tsx` | 显示待处理请求 + 同意/拒绝 |
| `PairingInviteCard` | `apps/web/src/skills/synastry/cards/PairingInviteCard.tsx` | 生成邀请链接 |
| `PairingSynastryResultCard` | `apps/web/src/skills/synastry/cards/PairingSynastryResultCard.tsx` | 隐私安全的结果展示 |

---

## 工具定义

在 `apps/api/skills/synastry/tools/tools.yaml` 添加：

```yaml
- name: show_pairing_code
  description: 显示用户的 Vibe 配对码
  card_type: pairing_code

- name: request_pairing
  description: 向另一用户发起配对请求
  parameters:
    - target_vibe_id (required)
    - relationship_type (required)
    - message (optional)

- name: show_pairing_requests
  description: 显示待处理的配对请求
  card_type: pairing_request_list

- name: accept_pairing_request
  description: 接受配对请求并计算合盘
  parameters:
    - request_id (required)

- name: generate_invite_link
  description: 生成一次性邀请链接
  parameters:
    - relationship_type (required)
    - message (optional)
```

---

## 实现步骤

### Phase 1: 数据库 & 后端基础

1. 创建数据库迁移文件 `migrations/023_pairing_system.sql`
2. 创建 `apps/api/stores/pairing_repo.py` - 数据访问层
3. 创建 `apps/api/services/pairing/service.py` - 业务逻辑
4. 创建 `apps/api/routes/pairing.py` - API 路由
5. 扩展通知类型支持 `pairing_request`, `pairing_accepted`

### Phase 2: 配对码功能（Mode 1）

6. 创建 `PairingCodeCard.tsx` 组件
7. 创建 `PairingRequestCard.tsx` 组件
8. 创建 `PairingSynastryResultCard.tsx` 组件
9. 添加工具 handlers (`show_pairing_code`, `request_pairing`, `accept_pairing_request`)
10. 更新 SKILL.md 工作流

### Phase 3: 邀请链接功能（Mode 2）

11. 创建 `/shared/invite/[token]/page.tsx` 邀请页面
12. 创建 `PairingInviteCard.tsx` 组件
13. 添加工具 handler (`generate_invite_link`)
14. 处理新用户注册后自动触发合盘

---

## 关键文件

| 文件 | 修改类型 |
|------|----------|
| `migrations/023_pairing_system.sql` | 新建 |
| `apps/api/stores/pairing_repo.py` | 新建 |
| `apps/api/services/pairing/service.py` | 新建 |
| `apps/api/routes/pairing.py` | 新建 |
| `apps/api/skills/synastry/tools/tools.yaml` | 修改 |
| `apps/api/skills/synastry/tools/handlers.py` | 修改 |
| `apps/api/skills/synastry/SKILL.md` | 修改 |
| `apps/api/services/reminder/notification.py` | 修改 |
| `apps/web/src/skills/synastry/cards/PairingCodeCard.tsx` | 新建 |
| `apps/web/src/skills/synastry/cards/PairingRequestCard.tsx` | 新建 |
| `apps/web/src/skills/synastry/cards/PairingInviteCard.tsx` | 新建 |
| `apps/web/src/skills/synastry/cards/PairingSynastryResultCard.tsx` | 新建 |
| `apps/web/src/app/shared/invite/[token]/page.tsx` | 新建 |

---

## 用户流程

### 配对码流程

```
A 说"显示我的配对码" → 展示 PairingCodeCard (VB-XXXXXXXX)
A 把配对码发给 B（微信等）
B 说"和 VB-XXXXXXXX 合盘" → 系统发通知给 A
A 收到通知，点击"同意" → 系统计算合盘
双方同时看到 PairingSynastryResultCard（无出生信息）
```

### 邀请链接流程

```
A 说"生成邀请链接" → 展示 PairingInviteCard (链接 + 二维码)
A 把链接发给 B
B 打开链接 → 看到邀请页面 + 注册按钮
B 注册并填写出生信息 → 系统自动计算合盘
双方同时收到结果
```

---

## 验证方式

1. 运行数据库迁移，检查表创建成功
2. 调用 API 测试配对请求流程
3. 前端测试卡片组件渲染
4. 端到端测试：两个用户完成配对并查看结果
5. 验证结果页面**不显示任何出生日期/时间/地点**

---

## 未解决问题

- [ ] 每日配对请求数量限制（建议 10/天）
- [ ] 是否支持屏蔽特定用户
- [ ] 邀请链接有效期（建议 7 天）
