---
description: Multi-environment configuration — Dev/staging/production settings, Spring profiles, config management
applyTo: '**/application*.{yml,yaml,properties}'
---

# Multi-Environment Configuration (Java/Spring Boot)

## Environment Hierarchy

| Environment | Purpose | Config File | Profile |
|-------------|---------|-------------|---------|
| `dev` | Local development | `application-dev.yml` | `spring.profiles.active=dev` |
| `staging` | Pre-production | `application-staging.yml` | `spring.profiles.active=staging` |
| `prod` | Live traffic | `application-prod.yml` | `spring.profiles.active=prod` |
| `test` | Automated tests | `application-test.yml` | `spring.profiles.active=test` |

## Configuration Loading Order

```
application.yml               ← Base (all environments)
application-{profile}.yml     ← Profile-specific overrides
Environment variables          ← Infrastructure overrides (highest priority)
```

## Rules

- **NEVER** put secrets in `application.yml` committed to git
- **NEVER** hardcode environment-specific URLs
- **ALWAYS** use Spring profiles for per-environment config
- **ALWAYS** use `@ConfigurationProperties` for typed config access
- Environment variables override YAML: `SPRING_DATASOURCE_URL` → `spring.datasource.url`

## Typed Configuration

```java
@ConfigurationProperties(prefix = "app")
@Validated
public record AppConfig(
    @NotBlank String environment,
    @NotNull CorsConfig cors,
    @NotNull DatabaseConfig database
) {
    public record CorsConfig(List<String> origins) {}
    public record DatabaseConfig(@NotBlank String url) {}
}
```

## Per-Environment Settings

```yaml
# application.yml (base)
server:
  port: 8080
logging:
  level:
    root: INFO

# application-dev.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/contoso_dev
    username: dev
    password: devpass
logging:
  level:
    root: DEBUG
app:
  cors:
    origins:
      - http://localhost:3000

# application-staging.yml
spring:
  datasource:
    url: jdbc:postgresql://staging-db:5432/contoso_staging
app:
  cors:
    origins:
      - https://staging.contoso.com

# application-prod.yml (secrets from env vars or Vault)
logging:
  level:
    root: WARN
app:
  cors:
    origins:
      - https://contoso.com
      - https://www.contoso.com
```

## Environment-Conditional Code

```java
// ✅ Use @Profile for environment-specific beans
@Configuration
@Profile("dev")
public class DevConfig {
    @Bean
    public DataSeeder dataSeeder() { return new DataSeeder(); }
}

// ❌ NEVER check env with string comparison
if ("prod".equals(System.getenv("APP_ENV"))) // BAD
```

## Health Checks (Actuator)

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true  # /actuator/health/liveness, /actuator/health/readiness
```

## Database Migrations Per Environment

| Environment | Migration Strategy | Who Runs | Approval |
|-------------|--------------------|----------|---------|
| **dev** | Flyway auto-migrate on startup | Spring Boot | None |
| **test** | Flyway auto-migrate in test profile | Spring Boot | Auto |
| **staging** | Flyway auto-migrate or pipeline step | Pipeline / Spring | Auto |
| **prod** | Pipeline step with manual approval | Pipeline | Manual approval gate |

### Per-Profile Flyway Config
```yaml
# application-dev.yml — auto-migrate on startup
spring:
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true        # First-time Flyway adoption convenience

# application-staging.yml
spring:
  flyway:
    enabled: true
    validate-on-migrate: true        # Fail if checksums don't match
    baseline-on-migrate: false

# application-prod.yml — auto-migrate disabled; run via pipeline step
spring:
  flyway:
    enabled: false                   # Migrations run as a separate pipeline step
    validate-on-migrate: true
```

```bash
# CI/CD pipeline step for production
mvn flyway:validate -Dflyway.url=$DATABASE_URL
mvn flyway:migrate -Dflyway.url=$DATABASE_URL -Dflyway.user=$DB_USER -Dflyway.password=$DB_PASSWORD
mvn flyway:info -Dflyway.url=$DATABASE_URL
```

- **NEVER** enable `baseline-on-migrate` in production
- **ALWAYS** use the same migration files across all profiles
- **ALWAYS** validate checksums before migrating (`validate-on-migrate: true`)

---

## See Also

- `database.instructions.md` — Migration strategy, expand-contract, rollback procedures
- `deploy.instructions.md` — Container config, health checks, migration pipeline steps
- `observability.instructions.md` — Per-environment logging and metrics
- `messaging.instructions.md` — Broker config per environment
