---
name: vibe-skill
description: Transforms domain knowledge into well-structured Agent Skills. Use when user provides expertise, documentation, or best practices and wants to create a reusable skill. Triggers on phrases like "build a skill", "create skill from", "turn this into a skill".
---

# Vibe Skill - Domain Knowledge to Skill Transformer

## Core Mission

Transform raw domain knowledge into production-ready Agent Skills that embody expert-level capabilities.

## Workflow

### Phase 1: Knowledge Intake

When user provides domain knowledge:

1. **Identify knowledge type**:
   - Procedural (how to do X)
   - Declarative (facts, schemas, rules)
   - Heuristic (expert judgment patterns)
   - Reference (API docs, specifications)

2. **Extract core elements**:
   - Trigger conditions (when should this skill activate?)
   - Key workflows (what steps does an expert follow?)
   - Decision points (where does judgment matter?)
   - Failure modes (what goes wrong and how to recover?)

### Phase 2: Architecture Design

Decide skill structure based on complexity:

**Simple skill** (single workflow, <200 lines):
```
skill-name/
└── SKILL.md
```

**Standard skill** (multiple workflows, reference needed):
```
skill-name/
├── SKILL.md
└── reference/
    └── [domain-specific].md
```

**Complex skill** (scripts, validation, examples):
```
skill-name/
├── SKILL.md
├── reference/
├── scripts/
└── examples/
```

### Phase 3: Content Generation

**SKILL.md structure**:

```yaml
---
name: [lowercase-with-hyphens, max 64 chars]
description: [Third person. What it does + when to use. Max 1024 chars]
---
```

**Body guidelines**:
- Keep under 500 lines
- Lead with quick-start (most common use case)
- Use progressive disclosure (link to reference/ for details)
- Include concrete examples, not abstract explanations

**Freedom calibration** (see [reference/freedom-levels.md](reference/freedom-levels.md)):
- High freedom: Multiple valid approaches, context-dependent
- Medium freedom: Preferred pattern with allowed variations
- Low freedom: Fragile operations, exact steps required

### Phase 4: Validation

Before finalizing, verify:

- [ ] Description includes trigger phrases
- [ ] SKILL.md body < 500 lines
- [ ] No deeply nested references (max 1 level)
- [ ] Examples are concrete, not abstract
- [ ] Terminology is consistent throughout

## Anti-patterns to Avoid

1. **Over-explaining** - Claude already knows common concepts
2. **Multiple options without default** - Pick one, mention alternatives
3. **Time-sensitive info** - Use "old patterns" section instead
4. **Windows paths** - Always use forward slashes

## Output Format

Generate complete skill directory. For each file, output:

```
=== FILE: path/to/file.md ===
[content]
```

User can then save files to `~/.claude/skills/[skill-name]/`
