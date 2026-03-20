# How We Plan & Build

> **Purpose**: Overview of the planning and execution pipeline for this project.  
> **Audience**: Developers and AI agents working on roadmap phases.

---

## The Pipeline

Every significant feature follows this flow:

```
Draft Plan → Harden → Execute (slice-by-slice) → Sweep → Review → Done
```

### Key Files

| File | Purpose |
|------|---------|
| [AI-Plan-Hardening-Runbook.md](./AI-Plan-Hardening-Runbook.md) | Full runbook — prompts, templates, worked examples |
| [AI-Plan-Hardening-Runbook-Instructions.md](./AI-Plan-Hardening-Runbook-Instructions.md) | Step-by-step guide with copy-paste prompts |
| [DEPLOYMENT-ROADMAP.md](./DEPLOYMENT-ROADMAP.md) | Master tracker — all phases and status |

### Guardrail Integration

| Guardrail File | When It's Used |
|----------------|----------------|
| `.github/copilot-instructions.md` | Every agent session (loaded first) |
| `.github/instructions/architecture-principles.instructions.md` | Before any code change |
| `.github/instructions/*.instructions.md` | Domain-specific (loaded per-slice via Context Files) |
| `AGENTS.md` | When working with background services/workers |

---

## Quick Start

1. **Add your phase** to `DEPLOYMENT-ROADMAP.md`
2. **Draft a plan** in `docs/plans/Phase-N-YOUR-FEATURE-PLAN.md`
3. **Run the 5-step pipeline** using prompts from the Instructions file
4. **Update guardrails** after completion (new patterns → instruction files)

See the [Instructions file](./AI-Plan-Hardening-Runbook-Instructions.md) for detailed copy-paste prompts.
