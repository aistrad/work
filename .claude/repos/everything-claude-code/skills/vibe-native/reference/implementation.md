# Agent-Native Implementation Patterns

## Shared Workspace

**Rule**: Agents and users work in identical data spaces, not separated sandboxes.

Benefits:
- Users inspect agent work directly
- Agents build on user creations
- No synchronization layers
- Complete transparency

```
/workspace/              # Same for both
├── projects/
│   └── acme/
│       ├── notes.md     # User created
│       └── summary.md   # Agent created
└── context.md           # Shared state
```

---

## Context Injection

System prompts should include:

```markdown
## Available Resources
- 15 project folders in /projects/
- 3 active documents in /inbox/
- User preferences in /config/settings.json

## Capabilities
You can: create files, read files, search content,
organize folders, generate summaries

## Recent Activity
- Last session: organized /inbox/ (2 hours ago)
- User modified: /projects/acme/notes.md (30 min ago)
```

**For long sessions**: Refresh context so agents stay current with user changes.

---

## Agent-to-UI Communication

Stream these events:

| Event Type | Purpose |
|------------|---------|
| `thinking` | Show agent is working |
| `tool_start` | Current tool being used |
| `tool_result` | What tool returned |
| `text` | Agent response streaming |
| `status` | State changes |

**Silent agents feel broken**—visible progress builds trust.

---

## Dynamic Capability Discovery

Instead of static tool mappings, build tools that discover capabilities at runtime.

```typescript
// Static (limited)
const tools = {
  createNote: createNoteFunction,
  readNote: readNoteFunction,
  // Must add each manually
}

// Dynamic (agent-native)
const tools = {
  discoverCapabilities: () => scanAPIEndpoints(),
  executeAction: (action, params) => callEndpoint(action, params),
  // Handles new endpoints automatically
}
```

**Use dynamic discovery for**:
- External APIs offering full user-level access
- Systems adding capabilities over time
- Unrestricted agent access goals

**Use static mapping for**:
- Intentionally constrained agents
- Limited scope by design

---

## CRUD Completeness Audit

For every entity, verify:

| Entity | Create | Read | Update | Delete |
|--------|--------|------|--------|--------|
| Project | ✓ | ✓ | ✓ | ✓ |
| Note | ✓ | ✓ | ✓ | ✓ |
| Task | ✓ | ✓ | ? | ? |

**Common failure**: Agents can create and read but not update or delete—leaving them unable to help with modifications or cleanup.

---

## Approval & User Agency

Match approval requirements to stakes:

| Action Type | Approval Level |
|-------------|----------------|
| Low-stakes, reversible (file organization) | Auto-apply |
| Medium-stakes (content generation) | Show preview |
| High-stakes, irreversible (sending emails) | Explicit approval |

---

## Tool Design Principles

### Atomic Primitives

```typescript
// Good: Atomic
readFile(path)
writeFile(path, content)
listDirectory(path)
searchContent(query)

// Bad: Workflow-shaped
processAndOrganizeFiles(folder, rules)  // Bundles judgment
```

### Domain Tool Graduation

When patterns emerge, add domain tools:

```typescript
// Started as: agent loops with primitives
// Pattern noticed: users often summarize all notes in a project
// Graduated to: domain tool

summarizeProject(projectId)  // Still calls primitives internally
                             // But faster, agent-orchestrated
```

**Keep primitives available**—domain tools are shortcuts, not gates.

---

## Self-Modification Legibility

When agents modify their own behavior:

1. **Visibility**: User can see what changed
2. **Understandable**: Effects are clear
3. **Rollback**: Easy to undo

```markdown
## Agent Modified: preferences.md
Changed: "Summarize in 3 bullets" → "Summarize in 5 bullets"
Reason: User asked for more detail twice
[Undo] [Keep]
```
