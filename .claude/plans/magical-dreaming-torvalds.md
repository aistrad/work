# 服务器权限收回 + Clawdbot 部署计划

## 目标
1. 移除同事对 aiscend 账号的 SSH 访问
2. 收回 root 权限（重置密码）
3. 创建 clawdbot 账号并部署

---

## Phase 1: 权限收回

### 1.1 移除同事的 aiscend SSH 密钥
```bash
# 备份
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak.$(date +%Y%m%d)

# 编辑移除 lixi 的两个密钥
nano ~/.ssh/authorized_keys
# 删除包含 "lixi" 和 "lixi-MAC" 的两行
# 可选：删除重复的 htdon@AIstra-Laptop（保留一个）
```

### 1.2 重置 root 密码
```bash
sudo passwd root
# 设置你自己知道的新密码
```

### 1.3 验证
```bash
# 确认 authorized_keys 只有你的密钥
cat ~/.ssh/authorized_keys

# 确认 sudo 组只有 aiscend
getent group sudo
```

---

## Phase 2: Clawdbot 部署位置分析

### 方案对比

| 维度 | 服务器部署 | 本地台式机部署 | 混合部署 |
|------|-----------|---------------|---------|
| **可用性** | 24/7 在线 | 需要保持开机 | 24/7 + 本地能力 |
| **隐私性** | 共享环境，同事可能接触 | 完全私有 | 网关在服务器，敏感操作在本地 |
| **本地工具** | 无法执行桌面操作 | 浏览器自动化、iMessage 等 | 两者兼得 |
| **网络** | 固定 IP，稳定 | 家庭网络，可能变化 | 服务器做入口 |
| **资源** | 与 vibelife 等共享 | 独立资源 | 分散负载 |

### 建议：混合部署（推荐）

**架构**：
```
消息平台 → 服务器(clawdbot网关) → 本地台式机(设备节点)
                ↓                        ↓
           消息路由/队列            本地工具执行
```

**优势**：
- 服务器保证 24/7 消息接收
- 本地台式机处理需要桌面环境的任务
- 敏感 token 可以放本地

**如果必须二选一**：
- 需要 24/7 响应 → 服务器
- 需要本地工具/隐私优先 → 本地台式机

---

## Phase 3: Clawdbot 账号创建与部署

### 3.1 创建 clawdbot 用户
```bash
sudo useradd -m -s /bin/bash clawdbot
sudo passwd clawdbot
```

### 3.2 安装 Node.js 22+
```bash
# 切换到 clawdbot 用户
sudo -u clawdbot -i

# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 22
```

### 3.3 安装 Clawdbot
```bash
npm install -g clawdbot@latest
clawdbot onboard --install-daemon
```

### 3.4 配置（~/.clawdbot/clawdbot.json）
- 配置 AI 模型 API key
- 配置消息渠道（WhatsApp/Telegram 等）

---

## 验证清单

- [ ] `ssh lixi@服务器` 被拒绝
- [ ] `sudo passwd root` 已重置
- [ ] `id clawdbot` 用户存在
- [ ] `clawdbot status` 服务运行正常

---

## 已确认

- **部署方式**: 混合部署
  - 服务器：运行 clawdbot 网关（24/7 消息接收）
  - 本地 Windows 台式机：设备节点（本地工具执行）
- **本地系统**: Windows

---

## Phase 4: Windows 设备节点配置

### 4.1 Windows 端安装
```powershell
# 安装 Node.js 22+ (从 nodejs.org 或用 winget)
winget install OpenJS.NodeJS.LTS

# 安装 clawdbot
npm install -g clawdbot@latest

# 作为设备节点连接到服务器网关
clawdbot pair --gateway ws://服务器IP:18789
```

### 4.2 服务器端配置远程访问
```bash
# 方案1: SSH 隧道（推荐，安全）
# 在 Windows 端运行:
ssh -L 18789:127.0.0.1:18789 clawdbot@服务器IP

# 方案2: Tailscale（如果已使用）
clawdbot config set gateway.expose tailscale
```

### 4.3 网络拓扑
```
[WhatsApp/Telegram等]
       ↓
[服务器 clawdbot 网关 :18789]
       ↓ (SSH隧道/Tailscale)
[Windows 设备节点]
       ↓
[浏览器自动化/本地工具]
```
