---
description: Multi-environment configuration — Dev/staging/production settings, environment detection, config management
applyTo: '**/.env*,**/config/**,**/settings.py'
---

# Multi-Environment Configuration (Python)

## Environment Hierarchy

| Environment | Purpose | Config Source | Detection |
|-------------|---------|---------------|-----------|
| `development` | Local dev with reload | `.env.development` | `APP_ENV` |
| `staging` | Pre-production validation | `.env.staging` | `APP_ENV` |
| `production` | Live traffic | `.env.production` | `APP_ENV` |
| `testing` | Automated tests | `.env.test` | `APP_ENV` |

## Configuration Loading Order

```
.env                      ← Base defaults (committed, no secrets)
.env.{APP_ENV}            ← Environment-specific overrides
.env.local                ← Local developer overrides (gitignored)
Environment variables     ← Infrastructure overrides (highest priority)
```

## Rules

- **NEVER** put secrets in `.env` files committed to git
- **NEVER** hardcode environment-specific URLs
- **ALWAYS** validate config at startup with Pydantic Settings
- **ALWAYS** add `.env.local` to `.gitignore`
- **ALWAYS** provide `.env.example` with all required keys

## Typed Config with Pydantic

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    app_env: str = "development"
    port: int = 8000
    database_url: str
    redis_url: str | None = None
    cors_origins: list[str] = ["http://localhost:3000"]
    log_level: str = "info"
    debug: bool = False

settings = Settings()
```

## Per-Environment Defaults

```bash
# .env (base — committed)
PORT=8000
LOG_LEVEL=info

# .env.development
DATABASE_URL=postgresql://dev:devpass@localhost:5432/contoso_dev
CORS_ORIGINS=["http://localhost:3000","http://localhost:5173"]
LOG_LEVEL=debug
DEBUG=true

# .env.staging
DATABASE_URL=postgresql://staging-db:5432/contoso_staging
CORS_ORIGINS=["https://staging.contoso.com"]
LOG_LEVEL=info

# .env.production (secrets injected at runtime)
CORS_ORIGINS=["https://contoso.com","https://www.contoso.com"]
LOG_LEVEL=warning
```

## Environment-Conditional Code

```python
# ✅ Use settings object
if settings.app_env == "development":
    app.add_middleware(DebugMiddleware)

# ❌ NEVER scatter os.environ checks
if os.environ.get("APP_ENV") == "production":  # BAD
```

## Health Checks

```python
@app.get("/healthz")
async def liveness():
    return {"status": "ok"}

@app.get("/readyz")
async def readiness():
    db_ok = await check_database()
    status = "ok" if db_ok else "degraded"
    return JSONResponse(
        status_code=200 if db_ok else 503,
        content={"status": status, "db": db_ok},
    )
```

## Database Migrations Per Environment

| Environment | Migration Strategy | Who Runs | Approval |
|-------------|--------------------|----------|---------|
| **development** | `alembic upgrade head` on startup | Developer | None |
| **testing** | `alembic upgrade head` in CI | Pipeline | Auto |
| **staging** | `alembic upgrade head` via CI/CD | Pipeline | Auto |
| **production** | Reviewed SQL via CI/CD | Pipeline | Manual approval gate |

### Environment-Specific Alembic Config
```ini
# alembic.ini — base config (connection string overridden per env)
[alembic]
script_location = alembic
sqlalchemy.url = %(DATABASE_URL)s
```

```python
# alembic/env.py — Read from environment
from src.config import settings

def run_migrations_online():
    connectable = create_async_engine(settings.database_url)
    # ...
```

```bash
# Production: generate SQL for DBA review before applying
alembic upgrade head --sql > migrations.sql
# Review migrations.sql, then apply:
alembic upgrade head
```

- **NEVER** run `alembic downgrade base` in production — use targeted `alembic downgrade -1`
- **ALWAYS** use the same migration files across all environments
- **ALWAYS** generate `--sql` output for production review

---

## See Also

- `database.instructions.md` — Migration strategy, expand-contract, rollback procedures
- `deploy.instructions.md` — Container config, health checks, migration pipeline steps
- `observability.instructions.md` — Per-environment logging and metrics
- `messaging.instructions.md` — Broker config per environment
