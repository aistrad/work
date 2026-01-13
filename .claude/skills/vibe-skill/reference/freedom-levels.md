# Freedom Levels Guide

## Calibrating Instruction Specificity

Match instruction specificity to task characteristics.

## High Freedom (Text-based guidance)

**When to use**:
- Multiple valid approaches exist
- Context determines best path
- Expert judgment varies case-by-case

**Pattern**:
```markdown
## Code Review Process

1. Analyze code structure
2. Check for potential issues
3. Suggest improvements based on context
4. Consider project conventions
```

**Example domains**: Code review, writing, analysis, research

## Medium Freedom (Templates with parameters)

**When to use**:
- Preferred pattern exists
- Some variation acceptable
- Configuration affects behavior

**Pattern**:
```markdown
## Generate Report

Use this template, customize as needed:

def generate_report(data, format="markdown"):
    # Adapt sections based on findings
```

**Example domains**: Report generation, data processing, API integration

## Low Freedom (Exact scripts, no parameters)

**When to use**:
- Operations are fragile
- Consistency is critical
- Specific sequence required
- Errors are costly

**Pattern**:
```markdown
## Database Migration

Run exactly:
python scripts/migrate.py --verify --backup

Do not modify flags.
```

**Example domains**: Migrations, deployments, security operations

## Decision Framework

Ask these questions:

1. **What's the cost of variation?**
   - Low cost → High freedom
   - High cost → Low freedom

2. **How many valid approaches exist?**
   - Many → High freedom
   - One → Low freedom

3. **Does context change the approach?**
   - Yes → High freedom
   - No → Low freedom

4. **Is this reversible?**
   - Yes → Higher freedom acceptable
   - No → Lower freedom safer
