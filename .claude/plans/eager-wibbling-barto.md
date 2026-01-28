# 多用户运维管理体系设计

## 实际环境分析

### GitHub 仓库 (aiscendtech 组织)
| 仓库 | 用途 | 技术栈 | 关联数据库 |
|------|------|--------|-----------|
| vibelife | AI 陪伴平台 | TypeScript/Node.js | vibelife |
| AIS-v1 | 量化回测 | Python | ais, aiscend |
| fortune_ai | 命理分析 | Python | fortune_ai |
| cli_worker | 后台任务 | Python | cli_worker |
| gemini_tool | AI 集成 | Python | gemini |
| financial_analysis | 数据仓库 | Python | aiscend |
| vibelife-core | 基础设施 | Mixed | - |

### PostgreSQL 数据库 (106.37.170.238:8224)
| 数据库 | 表数 | 用途 | 访问需求 |
|--------|------|------|---------|
| vibelife | 47+ | VibeLife 应用 | vibelife 用户读写 |
| aiscend | 50+ | 金融/文档数据 | crawler 读写, 其他只读 |
| ais | 8 | 量化回测 | crawler 读写 |
| fortune_ai | 52 | 命理系统 | vibelife 读写 |
| gemini | 4 | AI 任务 | clawdbot 读写 |
| cli_worker | 5 | 任务队列 | clawdbot 读写 |

### 现有用户
| 用户 | UID | 职责 | 组 |
|------|-----|------|-----|
| aiscend | 1000 | 开发/管理 | sudo, docker |
| base | 1001 | 基础服务 | - |
| crawler | 1002 | 数据抓取 | - |
| liuzhuo | 1003 | 个人 | - |
| vibelife | 1004 | 应用运维 | www-data |
| clawdbot | 1005 | AI 运维 | sudo |

---

## 目标架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    aiscend (开发者/超级管理员)                    │
│  - 所有数据库 superuser                                          │
│  - 所有 GitHub 仓库完全访问                                       │
│  - sudo 权限                                                     │
└─────────────────────────────────────────────────────────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│  clawdbot   │        │  vibelife   │        │  crawler    │
│  AI Ops     │        │  App Ops    │        │  Data Ops   │
├─────────────┤        ├─────────────┤        ├─────────────┤
│ DB: gemini  │        │ DB: vibelife│        │ DB: aiscend │
│     cli_work│        │     fortune │        │     ais     │
│ Repo: ALL   │        │ Repo: vibe* │        │ Repo: AIS   │
│             │        │             │        │     fin_*   │
└─────────────┘        └─────────────┘        └─────────────┘
```

---

## 实施步骤

### Phase 1: 用户组和共享目录

```bash
# 1. 创建用户组
sudo groupadd -f ops-admin    # 管理员组 (aiscend)
sudo groupadd -f ops-ai       # AI 运维 (clawdbot)
sudo groupadd -f ops-app      # 应用运维 (vibelife)
sudo groupadd -f ops-data     # 数据运维 (crawler)
sudo groupadd -f ops-shared   # 所有运维用户

# 2. 分配用户到组
sudo usermod -aG ops-admin,ops-shared aiscend
sudo usermod -aG ops-ai,ops-shared clawdbot
sudo usermod -aG ops-app,ops-shared vibelife
sudo usermod -aG ops-data,ops-shared crawler

# 3. 创建共享配置目录
sudo mkdir -p /etc/ops/{env,ssh,db}
sudo chmod 750 /etc/ops
sudo chown root:ops-shared /etc/ops
```

### Phase 2: SSH 密钥配置

```bash
# 为运维用户创建 SSH 目录并链接共享密钥
for user in clawdbot vibelife crawler; do
  sudo mkdir -p /home/$user/.ssh
  sudo cp /home/aiscend/.ssh/id_rsa /etc/ops/ssh/
  sudo cp /home/aiscend/.ssh/id_rsa.pub /etc/ops/ssh/
  sudo chmod 640 /etc/ops/ssh/id_rsa
  sudo chown root:ops-shared /etc/ops/ssh/*

  sudo ln -sf /etc/ops/ssh/id_rsa /home/$user/.ssh/id_rsa
  sudo ln -sf /etc/ops/ssh/id_rsa.pub /home/$user/.ssh/id_rsa.pub
  sudo cp /home/aiscend/.ssh/known_hosts /home/$user/.ssh/
  sudo chown -R $user:$user /home/$user/.ssh
  sudo chmod 700 /home/$user/.ssh
done
```

### Phase 3: 数据库用户和权限

```sql
-- 连接到 PostgreSQL 执行
-- psql -h 106.37.170.238 -p 8224 -U postgres

-- 1. 创建运维用户
CREATE USER ops_clawdbot WITH PASSWORD 'clawdbot_secure_pwd';
CREATE USER ops_vibelife WITH PASSWORD 'vibelife_secure_pwd';
CREATE USER ops_crawler WITH PASSWORD 'crawler_secure_pwd';
CREATE USER ops_readonly WITH PASSWORD 'readonly_secure_pwd';

-- 2. clawdbot: gemini + cli_worker 读写
GRANT CONNECT ON DATABASE gemini TO ops_clawdbot;
GRANT CONNECT ON DATABASE cli_worker TO ops_clawdbot;
\c gemini
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_clawdbot;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_clawdbot;
\c cli_worker
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_clawdbot;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_clawdbot;

-- 3. vibelife: vibelife + fortune_ai 读写
GRANT CONNECT ON DATABASE vibelife TO ops_vibelife;
GRANT CONNECT ON DATABASE fortune_ai TO ops_vibelife;
\c vibelife
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_vibelife;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_vibelife;
\c fortune_ai
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_vibelife;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_vibelife;

-- 4. crawler: aiscend + ais 读写
GRANT CONNECT ON DATABASE aiscend TO ops_crawler;
GRANT CONNECT ON DATABASE ais TO ops_crawler;
\c aiscend
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_crawler;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_crawler;
\c ais
GRANT ALL ON ALL TABLES IN SCHEMA public TO ops_crawler;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ops_crawler;

-- 5. 只读用户: 所有数据库只读
GRANT CONNECT ON DATABASE vibelife, aiscend, ais, fortune_ai, gemini, cli_worker TO ops_readonly;
-- (对每个数据库执行)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ops_readonly;
```

### Phase 4: 环境变量配置文件

```bash
# /etc/ops/env/clawdbot.env
cat > /etc/ops/env/clawdbot.env << 'EOF'
# clawdbot 数据库配置
GEMINI_DB_URL=postgresql://ops_clawdbot:clawdbot_secure_pwd@106.37.170.238:8224/gemini
CLI_WORKER_DB_URL=postgresql://ops_clawdbot:clawdbot_secure_pwd@106.37.170.238:8224/cli_worker

# 代理配置
http_proxy=http://127.0.0.1:7890
https_proxy=http://127.0.0.1:7890
EOF

# /etc/ops/env/vibelife.env
cat > /etc/ops/env/vibelife.env << 'EOF'
VIBELIFE_DB_URL=postgresql://ops_vibelife:vibelife_secure_pwd@106.37.170.238:8224/vibelife
FORTUNE_DB_URL=postgresql://ops_vibelife:vibelife_secure_pwd@106.37.170.238:8224/fortune_ai
http_proxy=http://127.0.0.1:7890
https_proxy=http://127.0.0.1:7890
EOF

# /etc/ops/env/crawler.env
cat > /etc/ops/env/crawler.env << 'EOF'
AISCEND_DB_URL=postgresql://ops_crawler:crawler_secure_pwd@106.37.170.238:8224/aiscend
AIS_DB_URL=postgresql://ops_crawler:crawler_secure_pwd@106.37.170.238:8224/ais
http_proxy=http://127.0.0.1:7890
https_proxy=http://127.0.0.1:7890
EOF

# 设置权限
sudo chmod 640 /etc/ops/env/*.env
sudo chown root:ops-clawdbot /etc/ops/env/clawdbot.env
sudo chown root:ops-vibelife /etc/ops/env/vibelife.env
sudo chown root:ops-crawler /etc/ops/env/crawler.env
```

### Phase 5: 用户配置完成脚本

创建 `/usr/local/bin/ops-setup-user`:
```bash
#!/bin/bash
# 用法: ops-setup-user <username> <role>
# role: ai|app|data

user=$1
role=$2

# Git 配置
sudo -u $user git config --global user.name "$user"
sudo -u $user git config --global user.email "$user@aiscend.tech"
sudo -u $user git config --global safe.directory '/opt/vibelife'
sudo -u $user git config --global safe.directory '/home/aiscend/work/*'

# 创建工作目录
sudo mkdir -p /home/$user/work
sudo chown $user:$user /home/$user/work

# 链接环境变量
case $role in
  ai)   sudo ln -sf /etc/ops/env/clawdbot.env /home/$user/.env ;;
  app)  sudo ln -sf /etc/ops/env/vibelife.env /home/$user/.env ;;
  data) sudo ln -sf /etc/ops/env/crawler.env /home/$user/.env ;;
esac

echo "✓ $user ($role) 配置完成"
```

---

## 权限矩阵

| 用户 | vibelife | fortune_ai | aiscend | ais | gemini | cli_worker | GitHub |
|------|----------|------------|---------|-----|--------|------------|--------|
| aiscend | RW | RW | RW | RW | RW | RW | ALL |
| clawdbot | RO | RO | RO | RO | RW | RW | ALL |
| vibelife | RW | RW | RO | - | - | - | vibe* |
| crawler | RO | - | RW | RW | - | - | AIS, fin* |

---

## 验证步骤

1. **SSH 验证**: `sudo -u clawdbot ssh -T git@github.com`
2. **数据库验证**: `sudo -u clawdbot psql $GEMINI_DB_URL -c "\dt"`
3. **Git 验证**: `sudo -u clawdbot git -C /home/aiscend/work/vibelife pull --dry-run`

---

## 已确认决策

1. **密码管理**: 使用环境变量文件 `/etc/ops/env/*.env`，按用户组隔离权限
2. **clawdbot sudo**: 限制为特定命令（systemctl、查看日志、执行运维脚本）
3. **base/liuzhuo**: 保留现状，不纳入本次配置

---

## Phase 6: clawdbot sudo 限制规则

```bash
# /etc/sudoers.d/clawdbot-ops
cat > /tmp/clawdbot-ops << 'EOF'
# clawdbot 限制性 sudo 权限
# 允许以其他运维用户身份执行特定命令

# 服务管理
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl status *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl restart vibelife-*
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl restart crawler-*

# 日志查看
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/journalctl -u vibelife-* *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/journalctl -u crawler-* *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/tail -f /var/log/vibelife/*
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/tail -f /var/log/crawler/*

# 配置检查（只读）
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/cat /home/*/.env
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/cat /etc/ops/env/*

# 健康检查脚本
clawdbot ALL=(vibelife,crawler) NOPASSWD: /opt/vibelife/scripts/healthcheck.sh
clawdbot ALL=(vibelife,crawler) NOPASSWD: /home/*/scripts/healthcheck.sh
EOF

sudo visudo -cf /tmp/clawdbot-ops && sudo cp /tmp/clawdbot-ops /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/clawdbot-ops
```

---

## 完整执行脚本

将所有步骤合并为一个可执行脚本 `/tmp/setup_ops_system.sh`:

```bash
#!/bin/bash
set -e

echo "=== Phase 1: 用户组 ==="
sudo groupadd -f ops-admin
sudo groupadd -f ops-ai
sudo groupadd -f ops-app
sudo groupadd -f ops-data
sudo groupadd -f ops-shared

sudo usermod -aG ops-admin,ops-shared aiscend
sudo usermod -aG ops-ai,ops-shared clawdbot
sudo usermod -aG ops-app,ops-shared vibelife
sudo usermod -aG ops-data,ops-shared crawler

echo "=== Phase 2: 共享目录 ==="
sudo mkdir -p /etc/ops/{env,ssh,db}
sudo chmod 750 /etc/ops
sudo chown root:ops-shared /etc/ops

echo "=== Phase 3: SSH 密钥 ==="
sudo cp /home/aiscend/.ssh/id_rsa /etc/ops/ssh/
sudo cp /home/aiscend/.ssh/id_rsa.pub /etc/ops/ssh/
sudo chmod 640 /etc/ops/ssh/id_rsa
sudo chmod 644 /etc/ops/ssh/id_rsa.pub
sudo chown root:ops-shared /etc/ops/ssh/*

for user in clawdbot vibelife crawler; do
  sudo mkdir -p /home/$user/.ssh
  sudo ln -sf /etc/ops/ssh/id_rsa /home/$user/.ssh/id_rsa
  sudo ln -sf /etc/ops/ssh/id_rsa.pub /home/$user/.ssh/id_rsa.pub
  sudo cp /home/aiscend/.ssh/known_hosts /home/$user/.ssh/ 2>/dev/null || true
  sudo chown -R $user:$user /home/$user/.ssh
  sudo chmod 700 /home/$user/.ssh

  # Git 配置
  sudo -u $user git config --global user.name "$user"
  sudo -u $user git config --global user.email "$user@aiscend.tech"
  sudo -u $user git config --global safe.directory '/opt/vibelife'
  sudo -u $user git config --global safe.directory '/home/aiscend/work/vibelife'
done

echo "=== Phase 4: 环境变量 ==="
# (环境变量内容在执行数据库配置后填写实际密码)

echo "=== Phase 5: sudo 限制 ==="
cat > /tmp/clawdbot-ops << 'SUDOERS'
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl status *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl restart vibelife-*
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/systemctl restart crawler-*
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/journalctl -u vibelife-* *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/journalctl -u crawler-* *
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/tail -f /var/log/*
clawdbot ALL=(vibelife,crawler) NOPASSWD: /usr/bin/cat /etc/ops/env/*
SUDOERS

sudo visudo -cf /tmp/clawdbot-ops && sudo cp /tmp/clawdbot-ops /etc/sudoers.d/clawdbot-ops
sudo chmod 440 /etc/sudoers.d/clawdbot-ops

# 移除 clawdbot 的完整 sudo
sudo deluser clawdbot sudo 2>/dev/null || true

echo "=== 验证 ==="
for user in clawdbot vibelife crawler; do
  echo "--- $user ---"
  echo "Groups: $(groups $user)"
  echo "SSH: $(sudo -u $user ssh -T git@github.com 2>&1 | head -1)"
done

echo "=== 完成 ==="
echo "下一步: 执行数据库 SQL 创建用户并更新 /etc/ops/env/*.env"
```
