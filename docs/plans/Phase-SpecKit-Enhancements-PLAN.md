# Phase: Spec-Kit-Inspired Enhancements

> **Status**: ✅ COMPLETE — All three features implemented  
> **Estimated Effort**: 2–3 days across 3 features  
> **Risk Level**: Low (additive — no breaking changes to existing pipeline)  
> **Inspiration**: Lessons learned from Spec-Kit's SDD methodology

---

## Overview

Three enhancements that strengthen the front end of the pipeline (before hardening begins) and make the existing 5-step workflow self-documenting. All three are additive — nothing in the existing pipeline changes. Teams that skip these steps still get the same hardening pipeline they have today.

### Design Principle: Layered Guardrails

The user's goal (paraphrased): *"Many dev teams using AI tools don't have strong technical backgrounds, so they don't know what to ask or what industry standards to apply. But a fintech app isn't the same as a marketing site — teams need to tweak things."*

The solution is a **two-layer guardrail model**:

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Universal Baseline (ships with preset)        │
│  architecture-principles, security, testing, etc.       │
│  "You get these whether you ask for them or not"        │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Project Profile (generated per-project)       │
│  Performance targets, coverage thresholds, UX bar,      │
│  domain rules, compliance requirements                  │
│  "You customize these to match YOUR project's needs"    │
└─────────────────────────────────────────────────────────┘
```

Layer 1 ensures less experienced teams get industry-standard guardrails by default. Layer 2 lets experienced teams dial in project-specific constraints. Neither replaces the other.

---

## Feature 1: Specify-Before-You-Harden Phase (Step 0)

### Problem

The pipeline currently starts at hardening (Step 1–2). But where does the plan come from? Today the user writes a rough plan and immediately enters the hardening pass. If the *requirements themselves* are vague, the hardening pass can polish the structure but can't fill in missing intent. Less experienced teams often don't know what to specify.

### Solution

Add a **"Step 0: Specify"** prompt template that walks users through describing *what* they want and *why* — before any technical planning begins. Embed `[NEEDS CLARIFICATION]` as a first-class marker convention that the hardening pass checks for and refuses to proceed if any remain.

### What Gets Built

1. **New prompt template**: `.github/prompts/step0-specify-feature.prompt.md`
   - Guided interview format — asks the user structured questions
   - Sections: Problem Statement, User Scenarios, Acceptance Criteria, Edge Cases, Out of Scope, Open Questions
   - Every "I don't know yet" answer gets tagged `[NEEDS CLARIFICATION]`
   - Output: a spec section that becomes the front matter of the Phase Plan

2. **Clarification marker convention**: `[NEEDS CLARIFICATION]`
   - Hardening pass (Step 2) scans for these markers
   - If any remain unresolved → STOP, don't proceed to execution
   - Marker format: `[NEEDS CLARIFICATION: brief description of what's unclear]`

3. **Update to existing hardening prompt** (Step 2 in Runbook-Instructions.md)
   - Add a check: "Scan the plan for `[NEEDS CLARIFICATION]` markers. If any exist, list them and STOP. Do not proceed with hardening until all markers are resolved."

4. **Update to docs/plans/README.md** — Add Step 0 to the pipeline diagram

### Prompt Template Design

The prompt should handle two user types:
- **Experienced teams**: Fill in sections quickly, few or no markers
- **Less experienced teams**: The structured questions surface things they hadn't thought about

```
Sections in step0-specify-feature.prompt.md:

1. PROBLEM STATEMENT
   "What problem does this feature solve? Who has this problem?"
   
2. USER SCENARIOS  
   "Describe 2-3 concrete scenarios of a user using this feature, 
    step by step. What do they see? What do they click? What happens?"

3. ACCEPTANCE CRITERIA
   "How will you know this feature is done? List measurable criteria."
   "If you're not sure, write: [NEEDS CLARIFICATION: what done looks like]"

4. EDGE CASES & ERROR STATES
   "What could go wrong? What if the user does something unexpected?"
   "What if the database is down? What if the input is invalid?"

5. OUT OF SCOPE
   "What does this feature explicitly NOT do? What's deferred to later?"

6. OPEN QUESTIONS
   "List anything you're unsure about. Each one becomes a 
    [NEEDS CLARIFICATION] marker that must be resolved before hardening."
```

### Files Changed

| File | Action | Description |
|------|--------|-------------|
| `.github/prompts/step0-specify-feature.prompt.md` | **CREATE** | New prompt template for the specify phase |
| `docs/plans/AI-Plan-Hardening-Runbook-Instructions.md` | **EDIT** | Add Step 0 before Step 1, add marker check to Step 2 |
| `docs/plans/AI-Plan-Hardening-Runbook.md` | **EDIT** | Add Step 0 to the pipeline diagram and Table of Contents |
| `docs/plans/README.md` | **EDIT** | Update pipeline diagram to show Step 0 |
| `docs/plans/examples/` | **EDIT** | Add a brief "Specify" front matter to one example (TypeScript) to show the pattern |

### Non-Goals

- This does NOT replace the hardening pass — it feeds into it
- This does NOT require a CLI tool — it's a prompt template
- This does NOT force teams to use it — teams can skip directly to Step 1 if they already have clear requirements

---

## Feature 2: Per-Project Profile

### Problem

The universal `architecture-principles.instructions.md` is a great safety net for teams that don't know industry standards. But it's the same for every project. A fintech API with strict latency SLAs and a marketing landing page with accessibility requirements have very different quality bars. Today there's no structured way to declare *project-specific* non-negotiables.

### Solution

Add a **"Project Profile"** prompt template that interviews the user once at project setup time and generates a `project-profile.instructions.md` file. This sits *alongside* the universal principles (doesn't replace them) and gets loaded into every agent session.

### The Two-Layer Model

```
Load Order (every agent session):
1. .github/copilot-instructions.md          ← Project overview (always loaded)
2. architecture-principles.instructions.md   ← Universal baseline (Layer 1)
3. project-profile.instructions.md           ← Project-specific (Layer 2)
4. domain-specific instructions              ← Per-file-type (existing behavior)
```

**If they conflict**: The project profile overrides the universal baseline for that specific project. Example: universal says "TDD for business logic" → profile says "TDD for ALL code including infrastructure" → profile wins.

### What Gets Built

1. **New prompt template**: `.github/prompts/project-profile.prompt.md`
   - Interview-style: asks questions about the project's specific needs
   - Categories: Code Quality, Testing, Performance, Security, UX/Accessibility, Compliance, Domain Rules
   - Each category has a sensible default from the universal baseline
   - User can accept defaults, tighten them, or add project-specific rules
   - Output: generates `.github/instructions/project-profile.instructions.md`

2. **Generated instruction file**: `.github/instructions/project-profile.instructions.md`
   - YAML frontmatter: `applyTo: '**'` (loads for all files, like architecture-principles)
   - Structured sections matching the interview categories
   - Each section shows: universal baseline default → project override (if any)
   - Concise — should be under 100 lines to stay within context budget

3. **Update setup wizard** (`setup.ps1` / `setup.sh`)
   - After preset copy, mention: "Run the Project Profile prompt to customize guardrails for your project"
   - Don't auto-run it — just inform the user it exists

4. **Update CUSTOMIZATION.md** — Document the two-layer model

### Profile Interview Categories

```
CATEGORY 1: CODE QUALITY
  Default: "No any/dynamic, explicit types, no empty catch blocks"
  Ask: "Any additional type safety rules? Stricter lint rules? 
        Banned patterns specific to your project?"

CATEGORY 2: TESTING
  Default: "TDD for business logic, integration tests for data access"
  Ask: "What's your coverage target? (e.g., 80%, 90%, or no target)
        Which test frameworks? Any required test types 
        (e.g., contract tests, load tests)?"

CATEGORY 3: PERFORMANCE
  Default: "All I/O async, no sync-over-async"  
  Ask: "Any latency SLAs? (e.g., P95 < 200ms for API responses)
        Memory budgets? Concurrent user targets?
        Response time thresholds?"

CATEGORY 4: SECURITY & COMPLIANCE
  Default: "Parameterized queries, input validation, no secrets in code"
  Ask: "Compliance requirements? (SOC2, HIPAA, PCI-DSS, GDPR, FedRAMP)
        Data classification levels? 
        Required security scanning tools?"

CATEGORY 5: ARCHITECTURE CONSTRAINTS
  Default: "4-layer architecture (Presentation → API → Service → Data)"
  Ask: "Any deviations from the 4-layer model?
        Specific patterns required? (CQRS, Event Sourcing, Hexagonal)
        Service communication rules? (sync only, async only, mixed)"

CATEGORY 6: UX & ACCESSIBILITY
  Default: (none — stack-dependent)
  Ask: "WCAG compliance level? (A, AA, AAA, or none)
        Supported browsers/devices?
        i18n/l10n requirements?"

CATEGORY 7: DOMAIN-SPECIFIC RULES
  Default: (none)
  Ask: "Any domain rules the AI must always follow?
        (e.g., 'All monetary values use decimal, never float',
         'All timestamps are UTC', 'Multi-tenant: every query filters by tenantId')"
```

### Files Changed

| File | Action | Description |
|------|--------|-------------|
| `.github/prompts/project-profile.prompt.md` | **CREATE** | New prompt template for project profile generation |
| `CUSTOMIZATION.md` | **EDIT** | Add "Two-Layer Guardrails" section explaining the model |
| `setup.ps1` | **EDIT** | Add post-install message about project profile prompt |
| `setup.sh` | **EDIT** | Same message for bash users |
| `templates/copilot-instructions.md.template` | **EDIT** | Add reference to project-profile.instructions.md |
| `docs/plans/README.md` | **EDIT** | Mention project profile in guardrail integration table |

### Non-Goals

- Does NOT replace universal `architecture-principles.instructions.md` — supplements it
- Does NOT require re-running for every phase — run once, update as needed
- Does NOT generate code — generates an instruction file only
- Does NOT require all categories be answered — defaults are fine for any skipped

### Example Output

For a fintech API project, the generated `project-profile.instructions.md` might look like:

```markdown
---
description: Project-specific quality standards and constraints — supplements universal architecture principles
applyTo: '**'
priority: HIGH
---

# Project Profile — FinTrack API

## Code Quality
- Universal baseline applies (no `any`, explicit types, no empty catch blocks)
- **Additional**: All public methods must have JSDoc comments
- **Additional**: No default exports — named exports only

## Testing
- Coverage target: **90% line coverage** (enforced in CI)
- Required: unit tests, integration tests, contract tests (Pact)
- Load tests required before each release (k6, P95 < 200ms)

## Performance  
- API response P95: **< 200ms**
- Database query budget: **< 50ms per query**
- No N+1 queries — all relationships eagerly loaded or batched

## Security & Compliance
- **SOC2 Type II** compliance required
- All PII fields encrypted at rest (AES-256)
- Audit log for all data mutations (who, what, when)
- No secrets in environment variables — use Azure Key Vault

## Architecture
- CQRS pattern for all domain aggregates
- Event sourcing for financial transactions
- All inter-service communication via Azure Service Bus (no direct HTTP)

## Domain Rules
- All monetary values: `Decimal` type, never `float` or `double`
- All timestamps: UTC, ISO 8601 format
- Multi-tenant: every database query MUST include `tenantId` filter
```

---

## Feature 3: Pipeline Step Prompts (Discoverable Workflow)

### Problem

The 5-step pipeline is powerful but lives inside documentation. Users must read the Runbook Instructions, find the right prompt block, and copy-paste it. There's no way to *discover* the pipeline by browsing available prompt templates. Less experienced teams may not even realize there are 5 steps.

### Solution

Create a set of **sequentially numbered prompt templates** that make the pipeline self-documenting. Users browse `.github/prompts/` in VS Code's file picker and see the workflow as a numbered sequence. Existing scaffolding prompts (new-entity, new-service, etc.) remain — they're used *within* Step 3.

### What Gets Built

1. **New pipeline prompt templates** (one per step):

   | Prompt File | Pipeline Step | Purpose |
   |-------------|---------------|---------|
   | `step0-specify-feature.prompt.md` | Step 0 (new) | Specify what & why — covered in Feature 1 |
   | `step1-preflight-check.prompt.md` | Step 1 | Pre-flight checks — extracted from Runbook Instructions |
   | `step2-harden-plan.prompt.md` | Step 2 | Hardening pass — extracted from Runbook Instructions |
   | `step3-execute-slice.prompt.md` | Step 3 | Slice execution — extracted from Runbook Instructions |
   | `step4-completeness-sweep.prompt.md` | Step 4 | Completeness sweep — extracted from Runbook Instructions |
   | `step5-review-gate.prompt.md` | Step 5 | Independent review — extracted from Runbook Instructions |

2. **Each prompt contains**:
   - YAML frontmatter with `description` explaining the step
   - The step's purpose and when to use it
   - Variables the user fills in (e.g., `{{PLAN_FILE}}`, `{{SLICE_NUMBER}}`)
   - The actual prompt text (same content as the copy-paste blocks in Runbook Instructions)
   - Brief "Next Step" pointer to the next prompt in the sequence

3. **Naming convention**: `step<N>-<name>.prompt.md` sorts alphabetically in the file picker, so the workflow reads top-to-bottom

4. **Update Runbook Instructions** — Each step's copy-paste block gets a note: *"This prompt is also available as a template: `.github/prompts/step<N>-<name>.prompt.md`"*

5. **Update docs/plans/README.md** — New "Pipeline Prompt Templates" section

### Relationship to Existing Prompts

```
.github/prompts/
├── step0-specify-feature.prompt.md      ← NEW: Pipeline step 0
├── step1-preflight-check.prompt.md      ← NEW: Pipeline step 1
├── step2-harden-plan.prompt.md          ← NEW: Pipeline step 2
├── step3-execute-slice.prompt.md        ← NEW: Pipeline step 3
├── step4-completeness-sweep.prompt.md   ← NEW: Pipeline step 4
├── step5-review-gate.prompt.md          ← NEW: Pipeline step 5
├── project-profile.prompt.md            ← NEW: One-time setup (Feature 2)
│
├── new-entity.prompt.md                 ← EXISTING: Used within Step 3
├── new-service.prompt.md                ← EXISTING: Used within Step 3
├── new-controller.prompt.md             ← EXISTING: Used within Step 3
├── bug-fix-tdd.prompt.md               ← EXISTING: Used within Step 3
├── new-worker.prompt.md                 ← EXISTING: Used within Step 3
├── new-test.prompt.md                   ← EXISTING: Used within Step 3
├── new-repository.prompt.md             ← EXISTING: Used within Step 3
├── ... (other scaffolding prompts)      ← EXISTING: Used within Step 3
```

Pipeline prompts are the **workflow**. Scaffolding prompts are **recipes** used during execution.

### Files Changed

| File | Action | Description |
|------|--------|-------------|
| `.github/prompts/step1-preflight-check.prompt.md` | **CREATE** | Extract from Runbook Instructions Step 1 |
| `.github/prompts/step2-harden-plan.prompt.md` | **CREATE** | Extract from Runbook Instructions Step 2 |
| `.github/prompts/step3-execute-slice.prompt.md` | **CREATE** | Extract from Runbook Instructions Step 3 |
| `.github/prompts/step4-completeness-sweep.prompt.md` | **CREATE** | Extract from Runbook Instructions Step 4 |
| `.github/prompts/step5-review-gate.prompt.md` | **CREATE** | Extract from Runbook Instructions Step 5 |
| `docs/plans/AI-Plan-Hardening-Runbook-Instructions.md` | **EDIT** | Add "also available as prompt template" notes |
| `docs/plans/README.md` | **EDIT** | Add Pipeline Prompt Templates section |
| Preset AGENTS.md files (`presets/*/AGENTS.md`) | **EDIT** | Reference pipeline prompts in the pipeline agents table |

### Non-Goals

- Does NOT remove copy-paste prompts from the Runbook Instructions — both paths work
- Does NOT change the 5-step pipeline logic — same prompts, just packaged differently
- Does NOT add new functionality to any step — pure packaging/discoverability improvement

---

## Execution Order

These three features are **independent** and can be built in any order. However, the recommended sequence is:

```
Feature 3 (Pipeline Prompts)     ← Lowest risk, highest immediate visibility
   ↓
Feature 1 (Specify Phase)        ← New content, adds Step 0 to pipeline
   ↓
Feature 2 (Project Profile)      ← Most complex, touches setup wizard
```

**Rationale**: Feature 3 is pure extraction (existing prompts → template files), so it's the safest starting point. Feature 1 adds new content but doesn't touch core infrastructure. Feature 2 is the most impactful but also touches the setup wizard and introduces the two-layer concept.

---

## What Does NOT Change

- The 5-step pipeline (Steps 1–5) — identical behavior
- Existing guardrail instruction files — untouched
- Existing scaffolding prompt templates — untouched  
- Existing agent definitions — untouched
- Existing skills — untouched
- Setup wizard core logic — only adds a post-install message
- Preset content — referenced but not modified (pipeline prompts go in shared, not per-preset)

---

## Success Criteria

| Feature | How We Know It Worked |
|---------|----------------------|
| Step 0 Specify | Less experienced teams produce clearer plans with fewer ambiguities reaching the hardening pass |
| Project Profile | Teams can customize quality bars without editing universal guardrails; profile loads alongside architecture-principles |
| Pipeline Prompts | Users discover the workflow by browsing `.github/prompts/`; numbered sequence reads as a tutorial |

---

## Open Questions

- [ ] Should pipeline prompt templates live in `presets/shared/` and get copied by setup.ps1, or ship as part of core (always present)?
  - **Recommendation**: Core — they're stack-independent
- [ ] Should the project profile prompt be part of the setup wizard (interactive step) or a separate prompt the user runs later?
  - **Recommendation**: Separate prompt, run after setup — keeps setup wizard simple
- [ ] Should `[NEEDS CLARIFICATION]` markers be checked by the pre-flight step (Step 1) or the hardening step (Step 2)?
  - **Recommendation**: Step 2 (hardening) — that's where plan quality is assessed
