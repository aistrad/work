# Description Writing Patterns

## Purpose

The description field is critical for skill discovery. Claude uses it to select the right skill from potentially 100+ available skills.

## Requirements

- Max 1024 characters
- Third person only
- No XML tags
- Include: what it does + when to use it

## Pattern

```
[Action verbs describing capabilities]. Use when [trigger conditions].
```

## Good Examples

**PDF Processing**:
```yaml
description: Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
```

**Git Commit Helper**:
```yaml
description: Generates descriptive commit messages by analyzing git diffs. Use when user asks for help writing commit messages or reviewing staged changes.
```

**BigQuery Analysis**:
```yaml
description: Queries BigQuery datasets, generates reports, analyzes metrics. Use when user mentions BigQuery, data analysis, SQL queries, or specific metric names like ARR, churn, pipeline.
```

## Bad Examples

```yaml
# Too vague
description: Helps with documents

# Missing trigger conditions
description: Processes Excel files and creates charts

# Wrong person (uses "you")
description: You can use this to analyze data

# Wrong person (uses "I")
description: I help users process PDFs
```

## Trigger Phrase Strategy

Include specific phrases users might say:

| Domain | Trigger Phrases |
|--------|-----------------|
| Data | "analyze", "query", "metrics", "report" |
| Documents | "PDF", "Excel", "Word", "spreadsheet" |
| Code | "refactor", "review", "debug", "test" |
| DevOps | "deploy", "CI/CD", "pipeline", "container" |

## Testing Discovery

After writing description, ask:

1. If user says "[trigger phrase]", will Claude select this skill?
2. Are there ambiguous phrases that might match multiple skills?
3. Is the scope clear enough to avoid false positives?
