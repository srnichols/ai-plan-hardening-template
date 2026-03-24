# How We Plan & Build

> **Purpose**: Overview of the planning and execution pipeline for this project.  
> **Audience**: Developers and AI agents working on roadmap phases.

---

## The Pipeline

Every significant feature follows this flow:

```mermaid
flowchart LR
    S0["Specify<br/><i>optional</i>"] --> S1["Draft Plan"]
    S1 --> S2["Harden"]
    S2 --> S3["Execute<br/><i>slice by slice</i>"]
    S3 --> S4["Sweep"]
    S4 --> S5["Review"]
    S5 --> Done["✅ Ship"]

    style S0 fill:#FFF3CD,stroke:#C9A800,color:#333
    style S1 fill:#D1ECF1,stroke:#0C5460,color:#333
    style S2 fill:#D1ECF1,stroke:#0C5460,color:#333
    style S3 fill:#D4EDDA,stroke:#155724,color:#333
    style S4 fill:#D4EDDA,stroke:#155724,color:#333
    style S5 fill:#F8D7DA,stroke:#721C24,color:#333
    style Done fill:#D4EDDA,stroke:#155724,color:#333
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
| `.github/instructions/project-profile.instructions.md` | Every session (project-specific quality standards — see CUSTOMIZATION.md) |
| `.github/instructions/*.instructions.md` | Domain-specific (loaded per-slice via Context Files) |
| `AGENTS.md` | When working with background services/workers |

### Agentic Capabilities

| Resource | Location | Purpose |
|----------|----------|---------|
| **Pipeline Prompts** (7) | `.github/prompts/step*.prompt.md` | Step-by-step pipeline workflow (Step 0–5 + Project Profile) |
| **Scaffolding Prompts** | `.github/prompts/*.prompt.md` | Recipes for entities, services, tests, workers |
| **Agent Definitions** (11) | `.github/agents/*.agent.md` | Specialized reviewers (security, architecture, API contracts, multi-tenancy, etc.) |
| **Skills** (3) | `.github/skills/*/SKILL.md` | Multi-step procedures (migrations, deploys, test sweeps) |

> **AI Agent Discoverability**: Agents can list `.github/prompts/`, `.github/agents/`, and `.github/skills/` to discover all available capabilities. The `copilot-instructions.md` file catalogs everything.

---

## Quick Start

1. **Specify your feature** (optional): use `.github/prompts/step0-specify-feature.prompt.md`
2. **Add your phase** to `DEPLOYMENT-ROADMAP.md`
3. **Draft a plan** in `docs/plans/Phase-N-YOUR-FEATURE-PLAN.md`
4. **Run the pipeline** using prompts from `.github/prompts/step1-*.prompt.md` through `step5-*.prompt.md`
5. **Use scaffolding prompts** during execution for consistent code (`#file:.github/prompts/new-entity.prompt.md`)
6. **Run agent definitions** for focused audits (`#file:.github/agents/security-reviewer.agent.md`)
7. **Update guardrails** after completion (new patterns → instruction files)

See the [Instructions file](./AI-Plan-Hardening-Runbook-Instructions.md) for detailed copy-paste prompts.
