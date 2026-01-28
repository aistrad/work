# Journey API Documentation

Journey API 代理到后端 lifecoach skill_data，用于读写用户的人生规划数据。

## API Endpoints

### GET /api/journey

读取用户的 lifecoach skill_data。

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```typescript
{
  status: "success" | "empty" | "error",
  message?: string,
  data: LifecoachSkillData,
  version?: number,
  updated_at?: string
}
```

**Backend Mapping:**
- 内部调用: `POST /api/v1/skills/lifecoach/state_read`
- 读取的 sections: `["system", "north_star", "identity", "current", "progress"]`

### POST /api/journey

写入用户的 lifecoach skill_data。

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```typescript
{
  args: {
    section: string,
    data: object
  }
}
```

**Response:**
```typescript
{
  status: "success" | "error",
  message?: string,
  data?: LifecoachSkillData,
  version?: number,
  updated_at?: string
}
```

**Backend Mapping:**
- 内部调用: `POST /api/v1/skills/lifecoach/state_write`

## Usage Examples

### 读取 Journey 数据

```typescript
const response = await fetch('/api/journey', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const { data } = await response.json();
console.log(data.north_star, data.weekly, data.daily_levers);
```

### 更新周大石头

```typescript
await fetch('/api/journey', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    args: {
      section: 'current',
      data: {
        week: {
          rocks: [
            { id: '1', task: '完成项目文档', status: 'completed' },
            { id: '2', task: '运动3次', status: 'in_progress' }
          ]
        }
      }
    }
  })
});
```

### 更新月度 Boss 进度

```typescript
await fetch('/api/journey', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    args: {
      section: 'current',
      data: {
        month: {
          milestones: updatedMilestones,
          progress: 60
        }
      }
    }
  })
});
```

## Error Handling

### 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

**原因:** 缺少 Authorization header

### 500 Internal Server Error
```json
{
  "status": "error",
  "message": "Failed to fetch journey data"
}
```

**原因:** 后端 lifecoach state API 调用失败

## Implementation Notes

1. **Proxy Pattern**: Journey API 作为代理层，简化前端调用
2. **Authorization**: 所有请求必须携带有效的 Authorization header
3. **Backend Dependency**: 依赖后端 `/api/v1/skills/lifecoach/state_read` 和 `state_write` 接口
4. **Error Handling**: 前端应处理网络错误和后端错误，实现乐观更新时需要 rollback 机制

## Related Files

- **API Route**: `/apps/web/src/app/api/journey/route.ts`
- **Types**: `/apps/web/src/types/journey.ts`
- **Hook**: `/apps/web/src/hooks/useJourneyData.ts`
- **Backend API**: `/apps/api/routes/skills.py` (lifecoach state_read/state_write)
