# Backend Refactoring Code Review Report

**Review Date**: 2026-01-01
**Baseline**: `/docs/core/backend_refactoring_plan_v42.md`
**Scope**: Implementation vs Specification Compliance

---

## Executive Summary

| Component | Compliance | Critical Issues |
|-----------|------------|-----------------|
| Next.js Agent Runtime | 80% | Idempotency key generation incomplete |
| FastAPI Internal Routes | 50% | Missing tool logging, commitments, twin updates, transactions |
| Frontend API Client | 75% | Missing run lifecycle calls, correlation_id |
| Skills (Divine) | 85% | Working, minor gaps |
| Skills (Heal/Grow) | 40% | Not integrated with FastAPI |
| Model Provider | 30% | Only GLM, missing Gemini/Claude |

**Overall Assessment**: Core infrastructure is in place but **critical persistence gaps** in FastAPI finalize endpoint will cause data loss.

---

## 1. CRITICAL ISSUES (Must Fix)

### 1.1 FastAPI `/internal/chat/run/finalize` Incomplete

**File**: `/api/internal_routes.py` (lines 170-231)

| Missing Feature | Spec Reference | Impact |
|-----------------|----------------|--------|
| Tool call logging | §2.4.2 lines 548-556 | Tool invocations NOT persisted, no audit trail |
| Commitments write | §2.4.2 lines 559-560 | /heal /grow skill outputs NOT saved |
| Twin updates | §2.4.2 lines 562-564 | L2 layer NOT updated |
| Transaction wrapper | §2.4.2 line 533 | Data consistency risk on partial failure |

**Current code only**:
- Records assistant message ✅
- Returns side_effects strings (no actual DB write) ❌

**Spec requires**:
```python
async with db.transaction():
    # 1. Update run status
    # 2. Write assistant message
    # 3. Write tool_invocations with idempotency_key
    # 4. Write commitments
    # 5. Update twin
```

### 1.2 Idempotency Key Generation Wrong

**File**: `/web-app/src/app/api/chat/route.ts` (line 130)

**Current**:
```typescript
idempotency_key: `${run_id}:${toolLogs.length}:${call.toolName}`
// Uses array index, missing params hash
```

**Spec requires** (§2.6.1):
```typescript
idempotency_key: `${runId}:${stepIndex}:${toolName}:${hash(params)}`
```

**Impact**: maxSteps retries will create duplicate writes.

### 1.3 Heal/Grow Skills Not Integrated

**Files**:
- `/web-app/src/lib/skills/heal-skills.ts`
- `/web-app/src/lib/skills/grow-skills.ts`

**Issue**: Skills return mock data, don't call FastAPI:
```typescript
// heal-skills.ts line 36
// "Note: In a real implementation, this would call the FastAPI backend"

// grow-skills.ts line 22
tempId = `commitment-${Date.now()}`  // Generated ID, not from backend
```

**Impact**: No data persistence for mood check-in, PERMA logging, goal creation.

---

## 2. HIGH PRIORITY ISSUES

### 2.1 Model Provider Incomplete

**File**: `/web-app/src/lib/models/model-provider.ts`

**Implemented**: GLM-4 via OpenAI-compatible API
**Missing**: Gemini and Claude providers (§1.3)

```typescript
// Spec requires:
const google = createGoogleGenerativeAI({ ... });
const anthropic = createAnthropic({ ... });

// package.json missing:
"@ai-sdk/google": "^1.0.0",
"@ai-sdk/anthropic": "^1.0.0"
```

**Impact**: Cannot fulfill "多模型热切换" requirement (§0.2)

### 2.2 Request Schema Mismatch

**File**: `/api/internal_routes.py` (lines 59-69)

**FinalizeRunRequest missing fields**:
- `tool_logs: ToolLog[]` (has `tool_calls` but different schema)
- `commitments: Commitment[]`
- `twin_updates: TwinUpdate`

**Impact**: Agent Runtime cannot send commitments/twin updates to FastAPI.

### 2.3 Context API Schema Different

**File**: `/api/internal_routes.py` (lines 33-41)

**Spec** (§2.4.1):
```typescript
{ l0: {...}, l1: {...}, policy_flags: {...}, history_excerpt: [...] }
```

**Implementation**:
```python
{ user_id, system_prompt, persona_style, user_context, evidence, anti_dependency, history }
```

Flat structure vs nested. Semantically equivalent but structurally different.

---

## 3. MEDIUM PRIORITY ISSUES

### 3.1 Correlation ID Inconsistent

**Issue**: Generated in route.ts but not passed to all internal calls

| Call | Has correlation_id |
|------|-------------------|
| `/internal/context` | ❌ Missing |
| `/internal/chat/run/start` | ✅ Present |
| `/internal/chat/run/finalize` | ✅ Present |

### 3.2 Tool Execution Context Missing

**File**: Skills `execute()` functions

**Current**:
```typescript
execute: async ({ birth_datetime, ... }, { abortSignal })
```

**Should receive** (§2.6.1):
```typescript
execute: async (params, { runId, stepIndex, abortSignal })
```

**Impact**: Cannot generate proper idempotency keys in skill code.

### 3.3 Action Button Type Safety

**File**: `/web-app/src/lib/types/a2ui-card.ts` (line 20)

**Current**:
```typescript
action: string;  // Allows any string
```

**Spec requires** (§2.5.3):
```typescript
action: 'accept' | 'done' | 'skip' | 'checkin' | 'navigate' | 'share';
```

### 3.4 Frontend Missing Run Lifecycle

**File**: `/web-app/src/lib/api.ts`

`streamChatMessageNew()` doesn't call:
- `POST /internal/chat/run/start` before streaming
- `POST /internal/chat/run/finalize` after streaming

Note: This is handled server-side in route.ts, so frontend doesn't need it. But frontend should handle X-Session-Id header consistently.

---

## 4. LOW PRIORITY ISSUES

| Issue | Location | Note |
|-------|----------|------|
| Latency tracking placeholder | route.ts line 1026 | `latency_ms: 0 // TODO` |
| Missing card types | a2ui-card.ts | error_toast, kline_chart, insight_card |
| CSRF token not in new stream | api.ts line 550 | OK for same-origin |
| Service token validation | internal_routes.py | Depends on Nginx config |

---

## 5. WHAT'S WORKING WELL

### ✅ Security (§0.5)
- userId NOT passed from frontend ✅
- Session cookie transparency ✅
- Session ownership validation ✅

### ✅ Run Lifecycle Structure (§0.6.1)
- Three-phase: start → stream → finalize ✅
- Tool results staged in memory ✅
- Finalize called in onFinish ✅

### ✅ Agent Runtime Architecture (§0.4)
- Next.js API Route pattern ✅
- Vercel AI SDK usage ✅
- FastAPI for data services ✅

### ✅ Frontend Integration
- USE_NEW_RUNTIME flag ✅
- Vercel AI SDK stream parsing ✅
- ToolInvocation types ✅
- Smart router function ✅

### ✅ Divine Skills
- FastAPI integration working ✅
- A2UI card returns ✅
- Zod validation ✅

---

## 6. RECOMMENDED FIX PRIORITY

### Phase 1: Critical (Day 1-2)
1. **Complete FastAPI finalize endpoint**:
   - Add tool_logs table and persistence
   - Add commitments persistence (call bento_service)
   - Add twin_updates persistence
   - Wrap in transaction

2. **Update FinalizeRunRequest schema**:
   - Add `tool_logs: List[ToolLog]`
   - Add `commitments: List[Commitment]`
   - Add `twin_updates: Optional[TwinUpdate]`

3. **Fix idempotency key generation**:
   - Add params hash
   - Use step index from Vercel AI SDK

### Phase 2: High (Day 3-4)
4. **Complete Heal/Grow skills**:
   - Replace mock returns with FastAPI calls
   - Add proper error handling

5. **Add multi-model providers**:
   - Install @ai-sdk/google, @ai-sdk/anthropic
   - Configure in model-provider.ts

### Phase 3: Medium (Day 5)
6. **Consistency cleanup**:
   - Add correlation_id to all internal calls
   - Add action type enum constraint
   - Add missing card types

---

## 7. FILES TO MODIFY

| File | Priority | Changes |
|------|----------|---------|
| `/api/internal_routes.py` | Critical | Complete finalize endpoint, update schemas |
| `/web-app/src/app/api/chat/route.ts` | Critical | Fix idempotency key |
| `/web-app/src/lib/skills/heal-skills.ts` | High | Add FastAPI integration |
| `/web-app/src/lib/skills/grow-skills.ts` | High | Add FastAPI integration |
| `/web-app/src/lib/models/model-provider.ts` | High | Add Gemini/Claude |
| `/web-app/package.json` | High | Add @ai-sdk/google, @ai-sdk/anthropic |
| `/web-app/src/lib/types/a2ui-card.ts` | Medium | Add action enum |

---

## 8. TESTING CHECKLIST

Before production, verify:
- [ ] Tool invocations persisted to database
- [ ] Commitments visible in dashboard after chat
- [ ] Twin state updated after /grow skills
- [ ] maxSteps=5 doesn't create duplicates
- [ ] Stream interruption doesn't leave corrupted state
- [ ] Multi-model switching works
- [ ] Correlation ID appears in all logs
