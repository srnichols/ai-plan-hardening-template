---
description: Multi-environment configuration — Dev/staging/production settings, environment detection, config management
applyTo: '**/appsettings*.json,**/Program.cs'
---

# Multi-Environment Configuration (.NET)

## Environment Hierarchy

| Environment | Purpose | Config File | Detection |
|-------------|---------|-------------|-----------|
| `Development` | Local dev with hot reload | `appsettings.Development.json` | `ASPNETCORE_ENVIRONMENT` |
| `Staging` | Pre-production validation | `appsettings.Staging.json` | `ASPNETCORE_ENVIRONMENT` |
| `Production` | Live traffic | `appsettings.Production.json` | `ASPNETCORE_ENVIRONMENT` |

## Configuration Loading Order

```
appsettings.json                  ← Base (all environments)
appsettings.{Environment}.json    ← Environment-specific overrides
Environment variables             ← Infrastructure overrides (highest priority)
User secrets (dev only)           ← Local developer secrets
```

## Rules

- **NEVER** put secrets in `appsettings.json` — use User Secrets (dev) or Key Vault (prod)
- **NEVER** hardcode environment-specific URLs — use config per environment
- **ALWAYS** have a base `appsettings.json` with sensible defaults
- **ALWAYS** use `IOptions<T>` / `IOptionsSnapshot<T>` for typed config
- Environment variables override JSON settings (12-factor app)

## Per-Environment Settings

```json
// appsettings.Development.json
{
  "ConnectionStrings": {
    "Database": "Host=localhost;Port=5432;Database=contoso_dev;Username=dev;Password=devpass"
  },
  "Logging": { "LogLevel": { "Default": "Debug" } },
  "Cors": { "Origins": ["http://localhost:3000", "http://localhost:5173"] }
}

// appsettings.Staging.json
{
  "ConnectionStrings": {
    "Database": "Host=staging-db;Port=5432;Database=contoso_staging"
  },
  "Logging": { "LogLevel": { "Default": "Information" } },
  "Cors": { "Origins": ["https://staging.contoso.com"] }
}

// appsettings.Production.json
{
  "ConnectionStrings": {
    "Database": "" // Injected via environment variable or Key Vault
  },
  "Logging": { "LogLevel": { "Default": "Warning" } },
  "Cors": { "Origins": ["https://contoso.com", "https://www.contoso.com"] }
}
```

## Environment-Conditional Code

```csharp
// ✅ Use IHostEnvironment for branching
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseDeveloperExceptionPage();
}

// ❌ NEVER check environment with string comparison
if (Environment.GetEnvironmentVariable("ENV") == "prod") // BAD
```

## Feature Flags by Environment

Use feature flags (not env checks) for gradual rollouts:
```csharp
builder.Services.AddFeatureManagement(builder.Configuration.GetSection("FeatureFlags"));
```

## Health Checks

Every environment must expose health endpoints:
```csharp
app.MapHealthChecks("/healthz");        // Liveness
app.MapHealthChecks("/readyz", new()    // Readiness (checks dependencies)
{
    Predicate = check => check.Tags.Contains("ready")
});
```

## Database Migrations Per Environment

| Environment | Migration Strategy | Who Runs | Approval |
|-------------|--------------------|----------|---------|
| **Development** | `dotnet ef database update` on startup | Developer | None |
| **Staging** | Idempotent SQL script via CI/CD | Pipeline | Auto |
| **Production** | Reviewed SQL script via CI/CD | Pipeline | Manual approval gate |

### Environment-Specific Migration Config
```json
// appsettings.Development.json — auto-migrate on startup (dev convenience)
{ "Database": { "AutoMigrate": true } }

// appsettings.Staging.json — migrations run via pipeline step
{ "Database": { "AutoMigrate": false } }

// appsettings.Production.json — NEVER auto-migrate in production
{ "Database": { "AutoMigrate": false } }
```

```csharp
// Program.cs — conditional auto-migration
if (app.Configuration.GetValue<bool>("Database:AutoMigrate"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}
```

- **NEVER** enable auto-migration in production — always use reviewed pipeline steps
- **ALWAYS** use the same migration scripts across all environments — no env-specific SQL
- Connection strings per environment are already handled by the config hierarchy above

---

## See Also

- `database.instructions.md` — Migration strategy, expand-contract, rollback procedures
- `deploy.instructions.md` — Container config, health checks, migration pipeline steps
- `observability.instructions.md` — Per-environment logging and metrics
- `messaging.instructions.md` — Broker config per environment
