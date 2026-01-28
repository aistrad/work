---
name: vibe-native
description: Architecture guide for building agent-native applications where AI agents are first-class citizens. Covers five core principles (Parity, Granularity, Composability, Emergent Capability, Improvement), file-based interfaces, execution patterns, and mobile considerations. Use when designing AI-first apps, integrating agents into products, or building agentic systems.
---

# Agent-Native Architecture Guide

## Quick Navigation

| Section | Jump To | Focus |
|---------|---------|-------|
| [5 Principles](#the-five-principles) | Core architecture rules | Must-read |
| [Files Interface](#files-as-universal-interface) | Why files > databases for agents | Design |
| [Execution Patterns](#agent-execution-patterns) | Loops, completion, context | Implementation |
| [Anti-Patterns](#anti-patterns) | What NOT to do | Review |
| [Checklists](#success-criteria) | Validation | Ship |

---

## The Core Question

> Describe an outcome within your domain that you didn't explicitly build.
> Can the agent achieve it through looping and tool composition?
> **If yes—you've built something genuinely agent-native.**

---

## The Five Principles

### 1. Parity

**Agents must accomplish whatever users achieve through the UI.**

Test: Pick any interface action—can the agent achieve that outcome?

Implementation:
- Create capability maps matching UI actions to agent outcomes
- No "orphan UI actions" that agents cannot access
- Agents and users work in identical data spaces

### 2. Granularity

**Tools = atomic primitives. Features = prompts that loop until done.**

| Less Granular (Bad) | More Granular (Good) |
|---------------------|----------------------|
| `processDocument(doc, options)` | `readFile()`, `extractText()`, `summarize()` |
| Bundles judgment into tools | Agent decides via prompting |
| Limits flexibility | Maximum composability |

**Rule**: Domain tools represent single conceptual user actions. Judgment about *what to do* belongs in prompts, not tools.

### 3. Composability

With atomic tools + parity, new features emerge by writing prompts alone.

**Example prompt-as-feature**:
```
Review files modified this week.
Summarize changes.
Suggest three priorities for next week.
```

Agent uses available tools to compose this outcome. No code required.

### 4. Emergent Capability

Agents accomplish **unanticipated tasks** by composing tools creatively.

**Discovery flow**:
1. Build atomic tools
2. Observe user requests
3. Notice patterns emerging
4. Optimize with domain-specific tools or prompts
5. Discover latent demand (don't guess features)

### 5. Improvement Over Time

Applications improve **without shipping code** through:
- Accumulated context (persistent state across sessions)
- Prompt refinement (developer and user levels)
- Agent learning from interactions

---

## Files as Universal Interface

### Why Files Win

| Advantage | Why It Matters |
|-----------|----------------|
| **Already Known** | Agents fluently understand `cat`, `grep`, `mv`, `mkdir` |
| **Inspectable** | Users see, edit, move, delete agent content |
| **Portable** | Export/backup trivial; users own data |
| **Cross-Device** | iCloud sync without servers |
| **Self-Documenting** | `/projects/acme/notes/` > database queries |

### Directory Architecture

```
{entity_type}/{entity_id}/
├── {entity}.json          # Structured data
├── {content_type}.md      # Human-readable content
├── agent_log.md           # Agent reasoning trace
├── full_text.txt          # Primary content
└── {sessionId}.checkpoint # Resume state
```

### The Context.md Pattern

Agents read this file at session start, update as state changes:

```markdown
# Context

## Who I Am
[Agent identity and role]

## What I Know About User
[Preferences, history, patterns]

## What Exists
[Available resources, files, capabilities]

## Recent Activity
[Last actions, current state]

## Guidelines
[Rules, constraints, preferences]
```

**Portable working memory without code changes.**

### Files vs Databases

| Use Files For | Use Databases For |
|---------------|-------------------|
| Content users should read/edit | High-volume structured data |
| Configuration (version control) | Complex queries needed |
| Agent-generated content | Ephemeral state (sessions, caches) |
| Transparency matters | Relational data |
| Large text content | Data needing indexing |

**When in doubt, files—they're more transparent.**

---

## Agent Execution Patterns

### Completion Signals

**Never detect completion heuristically. Use explicit signals.**

```typescript
// Tool result types
.success("Result")   // → continue loop
.error("Message")    // → continue (retry)
.complete("Done")    // → STOP loop
```

Undefined but needed: `pause` (needs user input), `escalate` (human decision), `retry` (transient failure)

### Model Tier Selection

Match intelligence to task:

| Task Type | Model Tier |
|-----------|------------|
| Research, analysis | Balanced (Sonnet) |
| Quick classification | Fast (Haiku) |
| Complex reasoning | Powerful (Opus) |

Don't default to most powerful.

### Partial Completion

Track progress at task level:

```
pending → in_progress → completed
                      → failed
                      → skipped
```

- Checkpoint mid-session
- Resume from interruption
- Mark individual task failures while continuing others

### Context Limits

Design for bounded context windows:
- Tools support iterative refinement (summary → detail → full)
- Agents consolidate learnings mid-session
- Assume context will eventually fill

---

## Graduation Path

Operations move from flexible to optimized:

| Stage | Characteristics | When |
|-------|-----------------|------|
| **Agent + Primitives** | Flexible, proves concept | New capability |
| **Domain Tools** | Faster, agent-orchestrated | Common patterns emerge |
| **Optimized Code** | Fast, deterministic | Hot paths identified |

**Even graduated operations maintain parity**—agents trigger optimizations, fall back to primitives for edge cases.

---

## Anti-Patterns

| Anti-Pattern | Problem |
|--------------|---------|
| **Agent as Router** | Using agent intelligence only to route to pre-built functions wastes capability |
| **Build-Then-Add-Agent** | Limits agents to existing features, kills emergent capability |
| **Request/Response Thinking** | Single-action in-and-out misses the looping advantage |
| **Defensive Tool Design** | Over-constraining inputs prevents unanticipated compositions |
| **Happy Path in Code** | When code handles all edge cases, agents just execute |
| **Workflow-Shaped Tools** | Bundling judgment into tools removes agent decision-making |
| **Orphan UI Actions** | UI capabilities agents cannot achieve violates parity |
| **Context Starvation** | Agents unaware of available resources cannot help |
| **Artificial Capability Limits** | Restricting from vague safety concerns rather than specific risks |
| **Heuristic Completion** | Pattern-matching for completion is fragile |

---

## Success Criteria

### Architecture Checklist

- [ ] Parity achieved across UI actions
- [ ] Atomic tool primitives with domain tool shortcuts
- [ ] Feature addition through prompts (not code)
- [ ] Emergent capability demonstrated
- [ ] Behavior changes come from prompt editing

### Implementation Checklist

- [ ] System prompts include resources and capabilities
- [ ] Shared data spaces for agents and users
- [ ] Immediate UI reflection of agent actions
- [ ] Full CRUD capability per entity
- [ ] Explicit completion signaling

### Product Checklist

- [ ] Simple requests work with zero learning curve
- [ ] Power users extend in unexpected directions
- [ ] Latent demand discovery through observation
- [ ] Approval matches stakes and reversibility

---

## Quick Reference

See [reference/mobile.md](reference/mobile.md) for iOS-specific patterns (checkpointing, background execution, iCloud architecture).

See [reference/implementation.md](reference/implementation.md) for detailed code patterns.
