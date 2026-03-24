# Instructions for Copilot

> **Project**: <YOUR PROJECT NAME>  
> **Stack**: <YOUR TECH STACK>  
> **Last Updated**: <DATE>

---

## Architecture Principles

**BEFORE making ANY code changes, read:** `.github/instructions/architecture-principles.instructions.md`

### Core Principles (Non-Negotiable)
1. **Architecture-First** — Ask 5 questions before coding
2. **Separation of Concerns** — Controller → Service → Repository
3. **Best Practices Over Speed** — Enterprise-grade, not hacky
4. **TDD for Business Logic** — Red-Green-Refactor
5. **Type Safety** — Explicit types everywhere

---

## Project Overview

<!-- Fill in your project details -->

**Description**: (What your app does)

**Tech Stack**:
- Frontend: (React / Blazor / Vue / etc.)
- Backend: (Node.js / .NET / Python / etc.)
- Database: (PostgreSQL / MongoDB / etc.)
- Testing: (Vitest / xUnit / pytest / etc.)

**Architecture**:
- (Key patterns your project uses)
- (How layers are organized)
- (How services communicate)

---

## Quick Commands

```bash
# Build
<YOUR BUILD COMMAND>

# Test
<YOUR TEST COMMAND>

# Lint
<YOUR LINT COMMAND>

# Start dev
<YOUR DEV COMMAND>
```

---

## Coding Standards

<!-- Add your project-specific standards here -->

### Style
- (naming conventions)
- (file organization)
- (import ordering)

### Database
- (ORM/query patterns)
- (migration strategy)

### Testing
- (test framework and patterns)
- (coverage requirements)

---

## Planning & Execution

This project uses the **Plan Forge Pipeline** for feature development.

- **Runbook**: `docs/plans/AI-Plan-Hardening-Runbook.md`
- **Instructions**: `docs/plans/AI-Plan-Hardening-Runbook-Instructions.md`
- **Roadmap**: `docs/plans/DEPLOYMENT-ROADMAP.md`
- **VS Code Guide**: `docs/COPILOT-VSCODE-GUIDE.md`

### Pipeline Prompts

| Prompt | Purpose |
|--------|---------|
| `step0-specify-feature.prompt.md` | Define what & why before planning |
| `step1-preflight-check.prompt.md` | Verify prerequisites |
| `step2-harden-plan.prompt.md` | Harden plan into execution contract |
| `step3-execute-slice.prompt.md` | Execute slices with validation gates |
| `step4-completeness-sweep.prompt.md` | Eliminate TODOs, stubs, mocks |
| `step5-review-gate.prompt.md` | Independent review & drift detection |
| `project-profile.prompt.md` | Generate project-specific guardrails |

### Instruction Files

| File | Domain |
|------|--------|
| `architecture-principles.instructions.md` | Core architecture rules (universal baseline) |
| `project-profile.instructions.md` | Project-specific quality standards (generate with `project-profile.prompt.md`) |
| `git-workflow.instructions.md` | Commit conventions |
| (add your domain files here) | |

---

## Git Workflow

After completing changes:
```bash
git add -A
git commit -m "<type>(<scope>): <description>"
git push origin main
```

See `.github/instructions/git-workflow.instructions.md` for commit types.
