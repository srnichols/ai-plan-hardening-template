---
description: TypeScript deployment patterns — Docker, pnpm monorepo, CI/CD
applyTo: '**/Dockerfile,**/docker-compose*,**/*.yml,**/*.yaml,**/k8s/**'
---

# TypeScript Deployment Patterns

## Docker

### Multi-stage Dockerfile (pnpm monorepo)
```dockerfile
FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM base AS build
WORKDIR /app
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api/package.json ./apps/api/
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
COPY . .
RUN pnpm --filter @myapp/api build

FROM base AS runtime
WORKDIR /app
COPY --from=build /app/apps/api/dist ./dist
COPY --from=build /app/node_modules ./node_modules
EXPOSE 4000
CMD ["node", "dist/server.js"]
```

### Docker Compose
```yaml
services:
  api:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=postgresql://app:secret@db:5432/app
    depends_on:
      - db
  web:
    build:
      context: .
      dockerfile: apps/web/Dockerfile
    ports:
      - "3000:3000"
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
```

## Build Commands

| Command | Purpose |
|---------|---------|
| `pnpm build` | Build all packages |
| `pnpm test` | Run all tests |
| `pnpm test -- --run` | Run tests without watch |
| `pnpm lint` | Lint all packages |
| `pnpm dev` | Start dev servers |
| `docker compose up -d` | Start all services |

## Environment Variables

```bash
# .env.example (commit this, NOT .env)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
JWT_SECRET=change-me-in-production
NODE_ENV=development
```

## Database Migration Deployment

**Migrations MUST run before the new app version starts serving traffic.**

### Pipeline Order
```
1. Build & test ──► 2. Run migrations ──► 3. Health check ──► 4. Deploy app ──► 5. Smoke test
                         ▲                     ▲
                    Fail = abort           Fail = rollback
```

### Docker Compose (Development)
```yaml
services:
  migrate:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
    command: ["npx", "prisma", "migrate", "deploy"]
    environment:
      - DATABASE_URL=postgresql://app:secret@db:5432/app
    depends_on:
      db:
        condition: service_healthy
  api:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
    depends_on:
      migrate:
        condition: service_completed_successfully   # App starts only after migration succeeds
```

### CI/CD Pipeline Step
```bash
# Check migration status
npx prisma migrate status

# Apply pending migrations (production-safe, forward-only)
npx prisma migrate deploy

# Generate client
npx prisma generate
```

- **NEVER** deploy app code before migrations complete
- **NEVER** use `prisma db push` in CI/CD — it can drop data
- **ALWAYS** have a rollback plan — see `database.instructions.md` for rollback procedures

---

## See Also

- `database.instructions.md` — Migration strategy, expand-contract, rollback procedures
- `dapr.instructions.md` — Dapr sidecar deployment, component configuration
- `multi-environment.instructions.md` — Per-environment configuration, migration config per env
- `observability.instructions.md` — Health checks, readiness probes
- `security.instructions.md` — Secrets management, TLS
