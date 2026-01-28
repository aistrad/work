# vibelife-xhs 新功能实现方案

## 功能概述

为 vibelife-xhs 小红书自动化内容系统新增两个功能：
1. **每日热点选题** - 获取全球新闻，智能匹配 VibeLife 相关话题
2. **Google Drive 自动上传** - 生成内容自动保存供发布团队使用

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    vibelife-xhs Skill                       │
│  (Claude Code 执行，纯文件驱动)                               │
├─────────────────────────────────────────────────────────────┤
│  SKILL.md          → 新增 `hotspot`, `upload` 命令           │
│  data/hotspots.yaml → 每日热点数据（Worker 写入）              │
│  data/topic-pool.yaml → high_priority 更新                  │
│  rules/hotspot.md    → 热点匹配规则                          │
│  config/gdrive.yaml  → Google Drive 配置                    │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 读取/写入
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Python Workers                           │
│  (apps/api/workers/)                                        │
├─────────────────────────────────────────────────────────────┤
│  hotspot_worker.py   → 06:00 获取新闻 + 写入 hotspots.yaml    │
│  gdrive_worker.py    → 每小时扫描 + 上传 Google Drive         │
└─────────────────────────────────────────────────────────────┘
```

---

## 功能 1：每日热点选题

### 数据流
```
Google News RSS / NewsAPI
        ↓
  hotspot_worker.py (06:00)
        ↓ 关键词预过滤
  data/hotspots.yaml
        ↓ LLM 读取 (hotspot 命令)
  智能匹配 + 评分
        ↓ score >= 8
  data/topic-pool.yaml (high_priority)
```

### 新增文件

| 文件 | 用途 |
|------|------|
| `apps/api/workers/hotspot_worker.py` | 定时获取新闻热点 |
| `apps/api/services/news/fetcher.py` | Google News RSS 解析 |
| `.claude/skills/vibelife-xhs/data/hotspots.yaml` | 热点数据存储 |
| `.claude/skills/vibelife-xhs/rules/hotspot.md` | LLM 匹配规则 |

### 新增命令 `hotspot`

```
读取：data/hotspots.yaml + rules/hotspot.md + topic-pool.yaml
执行：
  1. 逐个评估热点与 Skill 匹配度
  2. 生成选题建议（score >= 7）
  3. 高分选题（>= 8）自动添加到 high_priority
输出：今日热点 + 匹配选题 + 已添加数量
```

---

## 功能 2：Google Drive 上传

### 方案：服务账户 (Service Account)
- 无需用户授权，适合自动化
- 创建共享文件夹，与服务账户邮箱共享

### 文件夹结构
```
VibeLife-XHS/
└── 2026-01/
    ├── 2026-01-27-afternoon-zodiac-v1.md
    ├── 2026-01-27-afternoon-zodiac-v2.md
    └── 2026-01-27-evening-psych-v1.md
```

### 新增文件

| 文件 | 用途 |
|------|------|
| `apps/api/workers/gdrive_worker.py` | 定时上传 Worker |
| `apps/api/services/gdrive/uploader.py` | Google Drive API 封装 |
| `.claude/skills/vibelife-xhs/config/gdrive.yaml` | 上传配置 |

### 新增命令 `upload`

```
读取：config/gdrive.yaml + calendar.yaml
执行：
  1. 扫描 content/ 目录中的 draft 内容
  2. 按配置规则上传到 Google Drive
  3. 更新 calendar.yaml 的 uploaded_at
输出：上传结果统计
```

---

## 设计决策

| 问题 | 选择 | 理由 |
|------|------|------|
| 新闻源 | **Google News RSS** | 免费、稳定、支持中英文 |
| 版本策略 | **全部上传** | 保留所有版本，方便回溯 |
| 自动化 | **高分自动添加** | score >= 8 自动加入 high_priority |

---

## 环境变量 (.env.example)

```bash
# Google Drive 上传
GDRIVE_SERVICE_ACCOUNT_FILE=/path/to/service-account.json
GDRIVE_FOLDER_ID=<共享文件夹ID>
GDRIVE_ENABLED=1
```

---

## Crontab 配置

```cron
# 热点获取 - 每日 06:00
0 6 * * * python3 workers/hotspot_worker.py

# Google Drive 同步 - 每小时
0 * * * * python3 workers/gdrive_worker.py
```

---

## 实现步骤

### Phase 1：热点功能
1. `apps/api/services/news/fetcher.py` - RSS 解析
2. `apps/api/workers/hotspot_worker.py` - 定时任务
3. `.claude/skills/vibelife-xhs/data/hotspots.yaml` - 数据结构
4. `.claude/skills/vibelife-xhs/rules/hotspot.md` - 匹配规则
5. 更新 `SKILL.md` - 添加 `hotspot` 命令

### Phase 2：Google Drive 功能
1. 设置 Google Cloud 服务账户
2. `apps/api/services/gdrive/uploader.py` - 上传服务
3. `apps/api/workers/gdrive_worker.py` - 定时任务
4. `.claude/skills/vibelife-xhs/config/gdrive.yaml` - 配置
5. 更新 `SKILL.md` - 添加 `upload` 命令

### Phase 3：集成测试
1. 端到端测试流程
2. 定时任务验证
3. 错误处理

---

## 验证方式

1. **热点功能测试**
   - 手动运行 `python workers/hotspot_worker.py`
   - 检查 `data/hotspots.yaml` 是否更新
   - 执行 `/vibelife-xhs hotspot` 验证匹配

2. **Google Drive 测试**
   - 生成测试内容
   - 运行 `python workers/gdrive_worker.py`
   - 在 Google Drive 确认文件已上传

---

## 待确认事项

1. **Google Drive 共享文件夹 ID** - 需要创建文件夹并获取 ID
2. **服务账户设置** - 需要在 Google Cloud Console 创建
