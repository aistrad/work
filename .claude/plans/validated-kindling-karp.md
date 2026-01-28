# VIBE Skills Review Plan

## Executive Summary

Review the VIBE skills framework (`/home/aiscend/.claude/skills/`) against Claude skill standards and best practices to identify gaps, inconsistencies, and improvement opportunities.

---

## Skills Overview

| Skill | Purpose | Trigger Words | Status |
|-------|---------|---------------|--------|
| **vibe** | Meta-orchestrator, routes to phase skills | vibe, 产品, 项目, 创业, idea, 需求 | Core |
| **discovery** | User needs mining, PMF validation | 用户需求, 痛点, PMF, 目标用户 | Phase 1 |
| **design** | Product + technical architecture design | 架构, 数据模型, API, 系统设计 | Phase 2 |
| **build** | Modular implementation, code quality | 实现, 代码, 测试, 开发, 编码 | Phase 3 |
| **content** | Content-driven user acquisition | 推广, 渠道, 获客, SEO, 小红书 | Phase 4 |
| **growth** | User growth & monetization | 留存, 变现, 付费, AARRR | Phase 5 |
| **dev-spec** | Spec-driven development workflow | dev, 规格, spec, 需求 | Advanced |
| **quant-strategy** | Quantitative investment research | quant, 投资, 回测, 风控 | Domain |
| **vibeknowledge** | Knowledge base sync & processing | vibeknowledge, sync, ingest | Utility |
| **sync-work** | Work directory sync to GitHub | sync-work, sync, push | Utility |
| **cc-refresh** | Claude Code alias management | cc-refresh, glm, claude | Utility |

---

## Review Criteria

### 1. Structural Consistency

**Current State:**
- ✅ All skills have `SKILL.md` with frontmatter (name, description, trigger words)
- ⚠️ Only `dev-spec`, `quant-strategy`, `vibeknowledge`, `cc-refresh` have `workflow.yaml`
- ⚠️ Empty directory: `vibe/phases/`
- ⚠️ Inconsistent directory structures (some have `references/`, some `assets/`, some both)

**Best Practice (from dev-spec/cc-refresh):**
```yaml
# workflow.yaml structure
steps:
  - name: step-name
    script: scripts/script.sh
    input_schema: schemas/input.json
    output_schema: schemas/output.json
```

**Issues to Address:**
- [ ] Add `workflow.yaml` to vibe, discovery, design, build, content, growth, sync-work
- [ ] Standardize directory structure (decide: `assets/` vs `references/` vs both)
- [ ] Populate or remove `vibe/phases/`
- [ ] Add input/output JSON schemas for all workflow steps

---

### 2. Content Quality Standards

**Current Strengths:**
- ✅ Clear persona definitions in all phase skills
- ✅ Rich methodology sections (JTBD, DDD, AARRR, EARS)
- ✅ Visual diagrams (ASCII art) for architecture
- ✅ Detailed output templates (6-8 sections)

**Best Practice Comparison:**

| Element | VIBE Skills | dev-spec (Best) | Gap |
|---------|-------------|-----------------|-----|
| Traceability | ❌ Only in dev-spec | ✅ REQ-ID ↔ HOS-REF | Add to all |
| Logging | ❌ Only dev-spec/quant | ✅ Event-level-field table | Add to all |
| Error Handling | ⚠️ Only vibe has explicit | ✅ Per-skill scenarios | Add to all |
| Examples | ❌ Most lack examples | ⚠️ Some have | Add to all |
| Completion Criteria | ✅ 6-7 checkpoints | ✅ Clear DoD | Standardize |

**Issues to Address:**
- [ ] Add traceability (ID/REF mapping) to all phase skills
- [ ] Add logging architecture to all skills
- [ ] Add explicit error handling sections to all skills
- [ ] Add concrete examples for each workflow

---

### 3. Security & Best Practices

**Current State:**
- ✅ `dev-spec` has action zones (green/yellow/red)
- ✅ `dev-spec` has security practices (no hardcoded credentials)
- ⚠️ `cc-refresh` has hardcoded API endpoints in documentation

**Best Practice (from dev-spec):**
```yaml
# Action zones
- 🟢 Green (auto-approve): file reads, diffs, reports
- 🟡 Yellow (one-confirm): create dirs, network requests
- 🔴 Red (per-confirm): deletes, force push, production changes
```

**Issues to Address:**
- [ ] Remove/hardcode credentials in cc-refresh documentation
- [ ] Add action zones to all write-capable skills
- [ ] Add rollback strategy to all skills (only quant-strategy has it)
- [ ] Add permission models for file operations

---

### 4. Cross-Cutting Concerns

**Missing Components:**

| Component | Current State | Target |
|-----------|---------------|--------|
| Examples | Empty dirs | Concrete workflows |
| Tests | Empty dirs | Test scenarios |
| Changelogs | Only vibeknowledge | All skills |
| Versioning | None | Semantic versioning |
| Interdependencies | Informal | Formal contracts |
| Shared templates | Duplicated | Common library |

**Issues to Address:**
- [ ] Populate `examples/` with real workflow examples
- [ ] Add `tests/` with test scenarios and expected outputs
- [ ] Add `CHANGELOG.md` to all skills
- [ ] Define versioning strategy (semantic versioning)
- [ ] Document skill interdependencies (data flow contracts)
- [ ] Extract shared templates to common library

---

### 5. Documentation Standards

**Current Conventions:**
- ✅ Multi-language: Chinese primary, English technical terms
- ✅ Visual structure: ASCII art boxes/diagrams
- ✅ Code examples: TypeScript/Python/bash
- ✅ Tables: Structured data presentation
- ✅ Naming: kebab-case files, UPPER_SNAKE_CASE variables

**Best Practice to Maintain:**
- Keep Chinese + English technical terms pattern
- Use ASCII diagrams for architecture
- Include code examples in TypeScript/Python
- Use tables for structured data

---

## Detailed Review by Skill

### **vibe** (Meta-orchestrator)

**Strengths:**
- ✅ Clear phase architecture diagram
- ✅ Intent routing rules with keyword mapping
- ✅ State management (roadmap.md, _index.md)
- ✅ Interaction templates (first-time, continuing, switching)

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No input/output schemas
- ⚠️ Empty `phases/` directory

**Recommendations:**
1. Add `workflow.yaml` for routing logic
2. Define schemas for state files (roadmap, _index)
3. Populate or remove `phases/`
4. Add error handling examples for ambiguous intents

---

### **discovery** (Phase 1)

**Strengths:**
- ✅ 5-round deep interview flow
- ✅ JTBD framework
- ✅ YC PMF validation framework
- ✅ Comprehensive output template (6 sections)

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No examples
- ❌ No traceability to downstream phases

**Recommendations:**
1. Add `workflow.yaml` for interview flow
2. Add example interview transcripts
3. Add REQ-ID system linking to design phase

---

### **design** (Phase 2)

**Strengths:**
- ✅ 6-step design flow
- ✅ DDD + C4 model methodology
- ✅ ER diagram templates
- ✅ API specification format

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No examples
- ❌ No traceability from discovery requirements

**Recommendations:**
1. Add `workflow.yaml` for design steps
2. Add example design documents
3. Link design decisions to discovery REQ-IDs

---

### **build** (Phase 3)

**Strengths:**
- ✅ 5-step development flow
- ✅ Code quality standards (naming, structure, error handling)
- ✅ TypeScript code examples
- ✅ Module-based implementation

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No TDD examples
- ❌ No traceability to design specs

**Recommendations:**
1. Add `workflow.yaml` for module implementation
2. Add TDD workflow examples
3. Link code modules to design document sections

---

### **content** (Phase 4)

**Strengths:**
- ✅ 5-step strategy flow
- ✅ Content funnel (TOFU/MOFU/BOFU)
- ✅ Platform-specific strategies (小红书, 抖音, SEO)
- ✅ Landing Page design template

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No content examples
- ❌ No metrics definitions

**Recommendations:**
1. Add `workflow.yaml` for content strategy
2. Add example content pieces
3. Define standard metrics for each platform

---

### **growth** (Phase 5)

**Strengths:**
- ✅ 6-step strategy flow
- ✅ AARRR pirate metrics
- ✅ North Star Metric framework
- ✅ Growth flywheel concept
- ✅ ICE scoring for experiments

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No experiment examples
- ❌ No monitoring dashboard spec

**Recommendations:**
1. Add `workflow.yaml` for growth experiments
2. Add example experiment designs
3. Define monitoring dashboard structure

---

### **dev-spec** (Advanced - Reference Standard)

**Strengths:**
- ✅ `workflow.yaml` with 4 workflows
- ✅ EARS syntax for requirements
- ✅ HOS-REF traceability
- ✅ Logging architecture (event-level-field table)
- ✅ Action zones (green/yellow/red)
- ✅ Security practices
- ✅ TDD-first task ordering

**Gaps:**
- ⚠️ No examples in `examples/`
- ⚠️ No tests in `tests/`

**Recommendations:**
1. Populate `examples/` with spec derivations
2. Add test scenarios for each workflow

---

### **quant-strategy** (Domain)

**Strengths:**
- ✅ `workflow.yaml` with 6 steps
- ✅ Evidence-first principle
- ✅ Input/output schemas defined
- ✅ Rollback capability
- ✅ Checklists for entry/exit criteria

**Gaps:**
- ⚠️ No examples in `examples/`
- ⚠️ No tests in `tests/`

**Recommendations:**
1. Add backtest examples
2. Add validation test scenarios

---

### **vibeknowledge** (Utility)

**Strengths:**
- ✅ `workflow.yaml` with 4 workflows
- ✅ BAAI/bge-m3 embedding config
- ✅ Database schema defined
- ✅ Troubleshooting guide
- ✅ Detailed changelog

**Gaps:**
- ⚠️ No examples
- ⚠️ No tests

**Recommendations:**
1. Add example sync/ingest runs
2. Add test scenarios for each workflow

---

### **sync-work** (Utility)

**Strengths:**
- ✅ Clear sync scope
- ✅ GitHub repo defined
- ✅ Shell scripts for sync/push/status

**Gaps:**
- ❌ No `workflow.yaml`
- ❌ No input/output schemas
- ⚠️ Hardcoded paths in documentation

**Recommendations:**
1. Add `workflow.yaml` for sync workflows
2. Define schemas for sync state
3. Make paths configurable via environment variables

---

### **cc-refresh** (Utility)

**Strengths:**
- ✅ `workflow.yaml` with 3 workflows
- ✅ Input/output schemas defined
- ✅ Environment variable reference table
- ✅ Troubleshooting guide
- ✅ Multiple alias configs

**Gaps:**
- ⚠️ Hardcoded API endpoints in docs (security concern)
- ⚠️ No examples
- ⚠️ No tests

**Recommendations:**
1. Replace hardcoded endpoints with placeholders
2. Add example alias switches
3. Add verification test scenarios

---

## Priority Action Items

### High Priority (Structural)
1. **Add workflow.yaml to all skills** - Standardize workflow execution
2. **Add input/output schemas** - Formal validation of I/O
3. **Define skill interdependencies** - Document data flow between skills

### High Priority (Quality)
4. **Add traceability to phase skills** - REQ-ID system linking phases
5. **Add logging architecture** - Event-level-field tables
6. **Add error handling sections** - Per-skill error scenarios

### Medium Priority (Content)
7. **Populate examples/** - Concrete workflow examples
8. **Add tests/** - Test scenarios and expected outputs
9. **Add CHANGELOG.md** - Version tracking

### Low Priority (Enhancement)
10. **Extract shared templates** - Common template library
11. **Add action zones** - Permission models for write operations
12. **Remove hardcoded values** - Security hardening

---

## Verification Plan

After implementing changes, verify by:

1. **Structure Check**
   ```bash
   # Verify all skills have required files
   for skill in /home/aiscend/.claude/skills/*/; do
     echo "Checking $skill"
     ls -la "$skill/SKILL.md"
     ls -la "$skill/workflow.yaml" 2>/dev/null || echo "Missing workflow.yaml"
   done
   ```

2. **Schema Validation**
   ```bash
   # Validate JSON schemas
   find /home/aiscend/.claude/skills/*/schemas -name "*.json" -exec jq empty {} \;
   ```

3. **Workflow Testing**
   - Test each skill's workflow with sample inputs
   - Verify output matches expected schemas
   - Check traceability links work

4. **Documentation Review**
   - All skills have consistent sections
   - Examples are clear and runnable
   - Error scenarios are documented

---

## Success Criteria

The review is complete when:

- ✅ All skills have `workflow.yaml`
- ✅ All workflow steps have input/output schemas
- ✅ All phase skills have traceability (ID/REF mapping)
- ✅ All skills have error handling sections
- ✅ All skills have at least one example
- ✅ `examples/` and `tests/` directories are populated
- ✅ No hardcoded credentials in documentation
- ✅ Directory structure is consistent across skills
- ✅ Skill interdependencies are documented

---

## References

- **Best Practice Skills**: `dev-spec`, `quant-strategy`, `cc-refresh`
- **Skill Creator Guide**: `document-skills:skill-creator`
- **Frontmatter Standard**: YAML `name` + `description` with trigger words
- **Workflow Standard**: `workflow.yaml` with steps, scripts, schemas
