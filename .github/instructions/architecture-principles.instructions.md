---
description: Core architecture principles — Architecture-First Approach, Separation of Concerns, TDD, Best Practices over Quick Wins. READ BEFORE any code changes.
applyTo: '**'
priority: critical
---

# Architecture-First Engineering Principles

> **Priority**: CRITICAL — Read before ANY code changes  
> **Applies to**: ALL files

---

## AI Agent Instructions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STOP! Before writing ANY code, you MUST:                                   │
│                                                                             │
│  1. ✅ Read this file (architecture-principles.instructions.md)             │
│  2. ✅ Follow the Decision Framework below                                  │
│  3. ✅ Apply Separation of Concerns                                         │
│  4. ✅ Consider TDD for business logic                                      │
│  5. ✅ Check existing patterns first (DON'T reinvent)                       │
│                                                                             │
│  🚨 RED FLAGS that MUST stop you:                                           │
│  ❌ "quick fix" → STOP, find proper solution                                │
│  ❌ "copy-paste" → STOP, create reusable abstraction                        │
│  ❌ "skip types" → STOP, add proper types                                   │
│  ❌ "we'll refactor later" → STOP, do it right now                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## The 5 Questions Before Writing ANY Code

### 1. Does this code BELONG in this file/layer?

| Layer | Responsibility |
|-------|---------------|
| **Controllers / Routes** | HTTP handling only — no business logic |
| **Services** | Business logic only — no data access |
| **Repositories / Data Access** | Database queries only — no business rules |
| **Components / Views** | UI rendering only — no side effects |

### 2. Does a PATTERN already exist for this?

- Search existing codebase for similar functionality
- Check `.github/instructions/*.instructions.md` files
- Follow existing patterns — don't create new approaches

### 3. Will this SCALE appropriately?

- Consider high-volume data scenarios
- Consider concurrent users
- Consider future feature additions

### 4. Is this TESTABLE?

- Can business logic be unit tested in isolation?
- Are dependencies injectable?
- Are side effects isolated and mockable?
- **Have I written the test first?** (TDD for business logic)

### 5. HOW will this FAIL?

- What if the database is unavailable?
- What if the API returns an error?
- What if the user provides invalid input?
- Add proper error handling for ALL failure modes

---

## Separation of Concerns

### The 4-Layer Architecture

```
┌─────────────────────────────┐
│  PRESENTATION               │  Components, Pages, Views
│  (render UI, handle events) │  ❌ No business logic
├─────────────────────────────┤
│  API / CONTROLLERS          │  Routes, Endpoints
│  (HTTP handling only)       │  ❌ No business logic, no SQL
├─────────────────────────────┤
│  SERVICES                   │  Business Logic
│  (validation, orchestration)│  ❌ No SQL, no HTTP
├─────────────────────────────┤
│  DATA ACCESS                │  Repositories, ORM queries
│  (database operations only) │  ❌ No business rules
└─────────────────────────────┘
```

---

## Non-Negotiable Best Practices

### Type Safety
- **No `any`** (TypeScript) / **No `dynamic`** (C#) / **No `Any`** (Python) when type is known
- Explicit types on function signatures
- Use generics over type assertions

### Error Handling
- No empty catch blocks — always log or handle
- Use typed error classes, not generic exceptions
- Return structured error responses (RFC 7807 ProblemDetails or equivalent)

### Async Patterns
- All I/O operations must be async
- Never block on async operations (no `.Result`, `.Wait()`, `asyncio.run()` in async context)
- Support cancellation where the platform provides it

### Security
- Parameterized queries — never string interpolation in SQL
- Input validation at system boundaries
- No secrets in code — use environment variables or secret managers

### Testing
- TDD for business logic: Red → Green → Refactor
- Integration tests for data access
- E2E tests for critical user flows

---

## Decision Framework

```
New code needed?
  │
  ├─ Does it exist already? → YES → Reuse it
  │                          → NO ──┐
  │                                  │
  ├─ Which layer? ──► Controller (HTTP) │ Service (logic) │ Repository (data) │ Component (UI)
  │                                  │
  ├─ Does a pattern exist? → YES → Follow the pattern
  │                         → NO → Create pattern, document in instructions.md
  │
  ├─ Is it testable? → NO → Refactor until it is
  │
  └─ How will it fail? → Add error handling for each case
```

---

## Code Review Checklist

Before suggesting code changes, verify:

- [ ] Code is in the correct layer
- [ ] Follows existing patterns
- [ ] All types explicit (no `any`/`dynamic`/`object`)
- [ ] Error handling is comprehensive
- [ ] Input validated at boundaries
- [ ] Tests included for new features
- [ ] No sync-over-async patterns
- [ ] Security best practices followed
