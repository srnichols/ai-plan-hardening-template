---
description: .NET deployment patterns — Docker, Kubernetes, CI/CD
applyTo: '**/Dockerfile,**/docker-compose*,**/*.yml,**/*.yaml,**/k8s/**'
---

# .NET Deployment Patterns

## Docker

### Multi-stage Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS runtime
WORKDIR /app
COPY --from=build /app .
EXPOSE 8080
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

### Docker Compose
```yaml
services:
  api:
    build: .
    ports:
      - "5000:8080"
    environment:
      - ConnectionStrings__Default=Host=db;Database=app;Username=app;Password=secret
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
```

## Build Commands

| Command | Purpose |
|---------|---------|
| `dotnet build` | Compile the solution |
| `dotnet test` | Run all tests |
| `dotnet test --filter "Category=Unit"` | Unit tests only |
| `dotnet publish -c Release` | Build for deployment |
| `docker compose up -d` | Start all services |

## Health Checks

```csharp
builder.Services.AddHealthChecks()
    .AddNpgSql(connectionString)
    .AddRedis(redisConnectionString);

app.MapHealthChecks("/health");

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
    command: ["dotnet", "ef", "database", "update", "--project", "src/MyApp.Data"]
    environment:
      - ConnectionStrings__Default=Host=db;Database=app;Username=app;Password=secret
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
# Generate and review idempotent SQL
dotnet ef migrations script --idempotent -o migrations.sql --project src/MyApp.Data

# Apply to target environment
dotnet ef database update --project src/MyApp.Data
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
