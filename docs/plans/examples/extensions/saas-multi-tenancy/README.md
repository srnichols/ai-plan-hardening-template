# SaaS Multi-Tenancy Extension

> **Purpose**: Adds multi-tenant isolation guardrails to any SaaS project.
> Covers database RLS, middleware patterns, cache scoping, event context,
> and cross-tenant prevention.

## What's Included

| Type | File | Purpose |
|------|------|---------|
| **Instruction** | `multi-tenancy.instructions.md` | 20 rules for tenant isolation across all layers |
| **Instruction** | `rls-patterns.instructions.md` | PostgreSQL RLS policy patterns, migration safety, verification tests |
| **Agent** | `tenant-isolation-reviewer.agent.md` | Read-only auditor checking 25+ isolation points across 6 layers |
| **Prompt** | `new-tenant-middleware.prompt.md` | Scaffolds tenant validation middleware with JWT extraction |
| **Prompt** | `new-rls-policy.prompt.md` | Generates RLS policy + rollback + verification test for any table |

## Installation

### Manual
```bash
cp -r saas-multi-tenancy/ .forge/extensions/saas-multi-tenancy/
cp instructions/* .github/instructions/
cp agents/* .github/agents/
cp prompts/* .github/prompts/
```

### Using CLI
```bash
pforge ext install docs/plans/examples/extensions/saas-multi-tenancy
```

## When to Use This Extension

- You're building a **multi-tenant SaaS platform** with shared infrastructure
- Your database is **PostgreSQL** (RLS patterns are PostgreSQL-specific)
- You need to **enforce tenant isolation** at every layer
- You want an **auditor agent** that catches cross-tenant leaks before they ship

## What This Extension Does NOT Cover

- Single-tenant applications (not needed)
- Database-per-tenant isolation (different pattern — no RLS needed)
- Schema-per-tenant isolation (different pattern)
- Non-PostgreSQL RLS (SQL Server, MySQL have different syntax)
