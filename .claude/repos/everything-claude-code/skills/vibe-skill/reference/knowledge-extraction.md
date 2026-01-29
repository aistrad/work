# Knowledge Extraction Guide

## From Raw Knowledge to Structured Skill

When user provides domain knowledge, extract these elements systematically.

## Step 1: Identify Knowledge Types

| Type | Characteristics | Skill Placement |
|------|-----------------|-----------------|
| **Procedural** | Steps, workflows, sequences | SKILL.md body |
| **Declarative** | Facts, schemas, rules | reference/ files |
| **Heuristic** | Expert judgment, trade-offs | Decision frameworks in SKILL.md |
| **Reference** | API docs, specs, examples | reference/ or examples/ |

## Step 2: Extract Core Elements

### Trigger Conditions
Ask: "When should this skill activate?"

Look for:
- Task types ("when analyzing...", "when creating...")
- File types ("for PDF files", "with Excel data")
- User phrases ("help me with...", "I need to...")
- Domain keywords (specific terms users would mention)

### Key Workflows
Ask: "What steps does an expert follow?"

Extract:
- Main workflow (happy path)
- Alternative paths (edge cases)
- Decision points (where judgment matters)
- Validation steps (how to verify success)

### Failure Modes
Ask: "What goes wrong and how to recover?"

Identify:
- Common mistakes
- Error patterns
- Recovery procedures
- Prevention strategies

## Step 3: Compress Without Losing Essence

### Remove
- Explanations of concepts Claude already knows
- Redundant examples (keep 1-2 best ones)
- Historical context (unless affects current behavior)
- Verbose descriptions (replace with concise patterns)

### Keep
- Domain-specific terminology
- Non-obvious rules and constraints
- Expert heuristics
- Concrete examples of edge cases

### Transform
- Long explanations → Decision trees
- Multiple options → Default + alternatives
- Prose → Structured lists
- Implicit knowledge → Explicit rules

## Step 4: Structure for Progressive Disclosure

```
SKILL.md (loaded when triggered)
├── Quick start (most common case)
├── Core workflow (step-by-step)
├── Decision points (when to branch)
└── Links to reference/ for details

reference/ (loaded as needed)
├── Detailed procedures
├── Edge cases
├── API/schema reference
└── Troubleshooting guide
```

## Example Transformation

**Raw input** (verbose):
```
When working with PDF forms, you need to understand that there are
different types of form fields. Text fields are the most common,
but you also have checkboxes, radio buttons, and signature fields.
The process involves first analyzing the form to identify all fields,
then mapping your data to those fields, then filling them in...
```

**Extracted skill** (concise):
```markdown
## PDF Form Filling

1. Analyze form: `python scripts/analyze_form.py input.pdf`
2. Map data to fields in `fields.json`
3. Validate: `python scripts/validate.py fields.json`
4. Fill: `python scripts/fill_form.py input.pdf fields.json output.pdf`

Field types: text, checkbox, radio, signature
See [reference/form-fields.md](reference/form-fields.md) for details.
```
