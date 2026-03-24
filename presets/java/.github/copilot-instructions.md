# Instructions for Copilot — Java Project

> **Stack**: Java 21+ / Spring Boot / Gradle or Maven  
> **Last Updated**: <DATE>

---

## Architecture Principles

**BEFORE any code changes, read:** `.github/instructions/architecture-principles.instructions.md`

### Core Rules
1. **Architecture-First** — Ask 5 questions before coding
2. **Separation of Concerns** — Controller → Service → Repository (strict)
3. **Best Practices Over Speed** — Even if it takes longer
4. **TDD for Business Logic** — Red-Green-Refactor
5. **Type Safety** — No raw types, no `Object` when concrete type is known

### Red Flags
```
❌ "quick fix"           → STOP, find proper solution
❌ "copy-paste"          → STOP, create reusable abstraction
❌ "skip types"          → STOP, add proper types
❌ "we'll refactor later" → STOP, do it right now
```

---

## Project Overview

**Description**: <!-- What your app does -->

**Tech Stack**:
- Java 21+ (LTS)
- Spring Boot 3.x
- Spring Security (authentication & authorization)
- PostgreSQL (or your DB) with Spring Data JPA / JDBC
- Gradle (or Maven) for build
- Docker / Kubernetes

---

## Coding Standards

### Java Style
- **Records**: Use for DTOs and immutable data (`record UserDto(String name, String email) {}`)
- **Sealed classes**: Use for restricted hierarchies where appropriate
- **Pattern matching**: Use `instanceof` pattern matching (Java 21+)
- **Text blocks**: Use `"""` for multi-line strings (SQL, JSON)
- **Null safety**: Use `Optional<T>` for return types, `@Nullable`/`@NonNull` annotations
- **var**: Only use when type is obvious from right-hand side

### Spring Conventions
- **Constructor injection**: Always prefer over `@Autowired` field injection
- **@Transactional**: On service layer only — never on controllers or repositories
- **@RestController** vs **@Controller**: Use `@RestController` for APIs, `@Controller` for views
- **Profiles**: Use `@Profile` for environment-specific beans (`dev`, `staging`, `prod`)
- **Config properties**: Use `@ConfigurationProperties` with record types

### Performance
- **Virtual threads** (Java 21+): Enable via `spring.threads.virtual.enabled=true`
- **Connection pooling**: HikariCP (Spring Boot default)
- **Caching**: Use `@Cacheable` with explicit cache names
- **Lazy loading**: Be explicit about JPA fetch strategies to prevent N+1

### Database
- **Parameterized queries**: Always use `?` placeholders or named params — never concatenation
- **Migrations**: Flyway or Liquibase (never manual DDL)
- **Naming**: `snake_case` for columns, `PascalCase` for entities, explicit `@Column` mappings
- **CancellationToken equivalent**: Not built-in; design for reasonable timeouts instead

### Testing
- **JUnit 5** for unit tests
- **Testcontainers** for integration tests with real database
- **MockMvc / WebTestClient** for API integration tests
- **Mockito** for unit test mocking

---

## Quick Commands

```bash
# Gradle
./gradlew build                            # Build
./gradlew test                             # All tests
./gradlew test --tests "*UnitTest*"        # Unit tests only
./gradlew test --tests "*IntegrationTest*" # Integration only
./gradlew bootRun                          # Start app

# Maven
mvn clean install                          # Build
mvn test                                   # All tests
mvn test -Dtest="*UnitTest*"              # Unit tests only
mvn spring-boot:run                        # Start app

# Docker
docker compose up -d                       # Start all services
```

---

## Planning & Execution

This project uses the **Plan Forge Pipeline**:
- **Runbook**: `docs/plans/AI-Plan-Hardening-Runbook.md`
- **Instructions**: `docs/plans/AI-Plan-Hardening-Runbook-Instructions.md`
- **Roadmap**: `docs/plans/DEPLOYMENT-ROADMAP.md`

### Instruction Files

| File | Domain |
|------|--------|
| `architecture-principles.instructions.md` | Core architecture rules |
| `database.instructions.md` | JPA/JDBC, Flyway, query patterns |
| `testing.instructions.md` | JUnit 5, Testcontainers, MockMvc |
| `security.instructions.md` | Spring Security, input validation |
| `deploy.instructions.md` | Docker, K8s, Gradle/Maven |
| `git-workflow.instructions.md` | Commit conventions |

---

## Code Review Checklist

Before submitting code, verify:
- [ ] No raw SQL concatenation (use parameterized queries)
- [ ] Constructor injection (no `@Autowired` on fields)
- [ ] `@Transactional` on service layer only
- [ ] Proper exception handling (no empty catch blocks)
- [ ] Input validation at controller layer (`@Valid`, `@Validated`)
- [ ] Tests included for new features
- [ ] No hardcoded secrets — use environment variables or config
