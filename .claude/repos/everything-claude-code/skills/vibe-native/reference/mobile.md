# Agent-Native Mobile Architecture

## Mobile Unique Advantages

- Native file system for agent work
- Rich context access (HealthKit, location, photos, calendars)
- Local apps with self-modifying capabilities
- iCloud synchronization without servers

## Central Challenge

Agents require extended execution (minutes to hours), but **iOS backgrounds apps after seconds** and may kill them for memory recovery.

---

## iOS Storage Architecture

### iCloud-First Approach

Priority order:
1. **iCloud Container** (preferred): `iCloud.com.{bundleId}/Documents/`
2. **Local Documents** (fallback): `~/Documents/`
3. **Migration layer**: Auto-migrate local → iCloud when available

---

## Checkpoint & Resume Pattern

### What to Store

```json
{
  "agentType": "research",
  "messages": [...],
  "iterationCount": 5,
  "taskList": [
    {"id": "1", "status": "completed"},
    {"id": "2", "status": "in_progress"},
    {"id": "3", "status": "pending"}
  ],
  "customState": {...},
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### When to Checkpoint

- On app backgrounding (critical)
- After each tool result
- Periodically during long operations

### Resume Flow

```
1. Load interrupted sessions
2. Filter by validity (1-hour default expiry)
3. Show resume prompt to user
4. Restore messages and state
5. Continue loop
6. Delete checkpoint on dismiss/complete
```

---

## Background Execution

iOS provides ~30 seconds of background time.

**Use it for**:
1. Complete current tool call
2. Checkpoint state
3. Transition gracefully to backgrounded status

**Never assume** you'll get more time. Always be checkpoint-ready.

---

## On-Device vs Cloud

| On-Device | Cloud |
|-----------|-------|
| Orchestration | LLM calls via API |
| Tool execution (files, photos, HealthKit) | Optional checkpoint syncing |
| Local checkpoints | Long-running agent orchestration |

---

## Conflict Management

For iCloud-synced files:

| Strategy | Use Case |
|----------|----------|
| **Atomic writes (last-write-wins)** | Simple, but lossy |
| **iCloud conflict monitoring** | Creates conflict copies |
| **Check before writing** | Skip if modified |
| **Separate spaces** | Agent outputs to `/drafts/` |
| **Append-only logs** | Never overwrites |
| **File locking** | Explicit coordination |

**Practical guidance**: Logs and status files rarely conflict. For user-edited content, keep agent output separate or use explicit handling.
