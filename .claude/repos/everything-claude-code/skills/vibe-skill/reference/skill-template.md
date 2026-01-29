# Skill Template

## Minimal Skill (Single File)

```markdown
---
name: example-skill
description: Does X and Y. Use when user mentions Z or asks about W.
---

# Example Skill

## Quick Start

[Most common use case - 3-5 lines]

## Workflow

1. Step one
2. Step two
3. Step three

## Examples

**Input**: [concrete example]
**Output**: [expected result]
```

## Standard Skill (With References)

```
skill-name/
├── SKILL.md
└── reference/
    └── details.md
```

**SKILL.md**:
```markdown
---
name: skill-name
description: [What + When, third person, max 1024 chars]
---

# Skill Name

## Quick Start
[Most common case]

## Core Workflow
1. [Step]
2. [Step]
3. [Step]

## Advanced
See [reference/details.md](reference/details.md) for:
- Edge cases
- Configuration options
- Troubleshooting
```

## Complex Skill (Full Structure)

```
skill-name/
├── SKILL.md
├── reference/
│   ├── api.md
│   └── troubleshooting.md
├── scripts/
│   ├── validate.py
│   └── process.py
└── examples/
    └── sample-input.json
```

**SKILL.md**:
```markdown
---
name: skill-name
description: [Comprehensive description with trigger phrases]
---

# Skill Name

## Quick Start

Run: `python scripts/process.py input.json`

## Workflow

### Step 1: Validate
python scripts/validate.py input.json

### Step 2: Process
python scripts/process.py input.json output.json

### Step 3: Verify
Check output.json for expected structure.

## Reference
- [API Documentation](reference/api.md)
- [Troubleshooting Guide](reference/troubleshooting.md)

## Examples
See [examples/](examples/) for sample inputs.
```

## Checklist Before Finalizing

- [ ] name: lowercase, hyphens, max 64 chars
- [ ] description: third person, what + when, max 1024 chars
- [ ] SKILL.md body: < 500 lines
- [ ] Quick start: covers most common case
- [ ] References: max 1 level deep
- [ ] Examples: concrete, not abstract
- [ ] Terminology: consistent throughout
