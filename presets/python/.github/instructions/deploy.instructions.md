---
description: Python deployment patterns — Docker, uvicorn, CI/CD
applyTo: '**/Dockerfile,**/docker-compose*,**/*.yml,**/*.yaml'
---

# Python Deployment Patterns

## Docker

### Multi-stage Dockerfile (FastAPI)
```dockerfile
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

FROM base AS build
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .

FROM base AS runtime
WORKDIR /app
COPY --from=build /app/.venv /app/.venv
COPY --from=build /app/src ./src
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose
```yaml
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://app:secret@db:5432/app
    depends_on:
      - db
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

## Build Commands

| Command | Purpose |
|---------|---------|
| `uv sync` | Install dependencies |
| `uvicorn src.main:app --reload` | Dev server |
| `pytest --tb=short` | Run tests |
| `mypy .` | Type checking |
| `ruff check .` | Linting |
| `ruff format .` | Code formatting |
| `alembic upgrade head` | Apply DB migrations |
| `docker compose up -d` | Start infrastructure |

## Environment Variables

```bash
# .env.example (commit this, NOT .env)
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
JWT_SECRET=change-me-in-production
DEBUG=false
```

## Health Check

```python
@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": settings.app_version}
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
    build: .
    command: ["alembic", "upgrade", "head"]
    environment:
      - DATABASE_URL=postgresql+asyncpg://app:secret@db:5432/app
    depends_on:
      db:
        condition: service_healthy
  api:
    build: .
    depends_on:
      migrate:
        condition: service_completed_successfully   # App starts only after migration succeeds
```

### CI/CD Pipeline Step
```bash
# Check current migration state
alembic current

# Generate SQL for review (dry-run)
alembic upgrade head --sql > migrations.sql

# Apply pending migrations
alembic upgrade head
```

- **NEVER** deploy app code before migrations complete
- **ALWAYS** have a rollback plan — see `database.instructions.md` for rollback procedures
- **ALWAYS** backup before applying migrations to production

---

## See Also

- `database.instructions.md` — Migration strategy, expand-contract, rollback procedures
- `dapr.instructions.md` — Dapr sidecar deployment, component configuration
- `multi-environment.instructions.md` — Per-environment configuration, migration config per env
- `observability.instructions.md` — Health checks, readiness probes
- `security.instructions.md` — Secrets management, TLS
