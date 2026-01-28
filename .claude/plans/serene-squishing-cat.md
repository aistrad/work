# 聊天历史功能实现计划

## 目标
实现类似 ChatGPT / Claude.ai 的聊天历史功能：
- 侧边栏显示所有历史会话
- 会话自动命名
- 重命名、删除

---

## 当前状态

### 已有的后端能力 ✅
- `conversation_repo.py` - 会话 CRUD 操作
- `message_repo.py` - 消息查询、搜索
- 数据库表 `conversations`（含 `title` 字段）、`messages`

### 缺失的功能 ❌
- 前端侧边栏组件
- 会话列表 API 端点
- 会话切换逻辑
- 自动标题生成

---

## Phase 1: 后端 API

### 1.1 新建路由文件
**文件**: `apps/api/routes/conversations.py`

```python
GET  /api/v1/conversations              # 获取会话列表
POST /api/v1/conversations              # 创建会话
GET  /api/v1/conversations/{id}         # 获取单个会话（含消息）
PATCH /api/v1/conversations/{id}        # 重命名
DELETE /api/v1/conversations/{id}       # 删除
GET  /api/v1/conversations/search?q=xx  # 搜索
```

### 1.2 会话列表响应格式
```json
{
  "conversations": [
    {"id": "uuid", "title": "八字命理分析", "skill": "bazi", "updated_at": "..."}
  ],
  "total": 25
}
```
- 按 `updated_at` 降序排列（最新在前）
- 不做时间分组，简化实现

### 1.3 标题自动生成
- 首次对话后，用 LLM 生成 4-8 字标题
- 或截取首条消息前 10 字 + "..."

---

## Phase 2: 前端侧边栏

### 2.1 组件结构
```
components/chat/ConversationSidebar/
  index.tsx              # 主容器
  ConversationList.tsx   # 会话列表（按更新时间排序）
  ConversationItem.tsx   # 单个会话项（含操作菜单）
  NewChatButton.tsx      # 新建按钮
```

### 2.2 布局方案

**PC (>=1024px)**
```
┌───────┬──────────────┬────────────────────────────┐
│NavBar │ Sidebar      │ ChatContainer              │
│64px   │ 260px        │ flex-1                     │
└───────┴──────────────┴────────────────────────────┘
```

**Mobile (<1024px)**
- 左上角汉堡菜单触发抽屉
- 抽屉从左侧滑入，覆盖 70% 宽度

### 2.3 状态管理
- **SWR**: 会话列表数据
- **URL**: `?conversation_id=xxx`
- **LocalStorage**: 侧边栏展开/折叠状态

---

## Phase 3: 交互流程

### 3.1 切换会话
1. 点击侧边栏会话
2. URL 更新为 `/chat?conversation_id=xxx`
3. ChatContainer 加载对应历史消息

### 3.2 新建会话
1. 点击 "New Chat"
2. 清空 URL 参数 → `/chat`
3. 生成新 conversation_id
4. 显示空状态

### 3.3 删除会话
- 软删除：设置 `is_active=false`
- 从列表移除，不真正删除数据

---

## 关键文件清单

| 操作 | 文件路径 |
|-----|---------|
| 新建 | `apps/api/routes/conversations.py` |
| 修改 | `apps/api/main.py` - 注册路由 |
| 新建 | `apps/web/src/components/chat/ConversationSidebar/index.tsx` |
| 新建 | `apps/web/src/components/chat/ConversationSidebar/ConversationList.tsx` |
| 新建 | `apps/web/src/components/chat/ConversationSidebar/ConversationItem.tsx` |
| 新建 | `apps/web/src/components/chat/ConversationSidebar/NewChatButton.tsx` |
| 新建 | `apps/web/src/hooks/useConversations.ts` |
| 修改 | `apps/web/src/components/layout/AppShell.tsx` - 集成侧边栏 |
| 修改 | `apps/web/src/app/chat/page.tsx` - 处理 conversation_id |
| 修改 | `apps/web/src/hooks/useVibeChat.ts` - 加载历史消息 |

---

## 验证方式

1. **API 测试**: `curl /api/v1/conversations` 返回会话列表
2. **UI 测试**: PC 端看到侧边栏，移动端抽屉正常
3. **切换测试**: 点击历史会话，加载对应消息
4. **新建测试**: 点击 New Chat，开始新对话
5. **删除测试**: 删除会话后列表更新

---

## 设计决策

| 决策项 | 选择 | 说明 |
|-------|------|-----|
| 移动端交互 | 抽屉覆盖 70% | 类似 ChatGPT，点击背景可关闭 |
| 标题生成 | LLM 自动生成 | AI 生成 4-8 字标题，首次回复后触发 |
| 搜索功能 | 暂不实现 | 后续迭代添加 |
| 分页方式 | 无限滚动 | 自动加载更多 |
| 删除方式 | 软删除 | `is_active=false`，保留数据 |

---

## 实现顺序

1. **Phase 1**: 后端 API（会话列表、标题生成）
2. **Phase 2**: 前端侧边栏组件（PC 端）
3. **Phase 3**: 移动端适配（抽屉交互）
4. **Phase 4**: 会话切换逻辑整合
