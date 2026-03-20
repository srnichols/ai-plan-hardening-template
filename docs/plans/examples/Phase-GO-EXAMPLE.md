# Phase 6: REST API & Middleware — Go Example

> **Status**: 🟡 HARDENED — Ready for execution  
> **Estimated Effort**: 2 days (8 execution slices)  
> **Risk Level**: Medium (middleware chain + database integration)

---

## Overview

Build a RESTful API for user management with Chi router, middleware chain (logging, auth, rate limiting), PostgreSQL persistence via pgx, and structured JSON error responses. Follows standard Go project layout.

---

## Prerequisites

- [ ] Phase 5 complete (database schema + migrations applied)
- [ ] PostgreSQL running (Docker Compose)
- [ ] `golang-migrate` CLI installed for migrations
- [ ] `golangci-lint` configured

## Acceptance Criteria

- [ ] CRUD endpoints for users (`GET`, `POST`, `PUT`, `DELETE`)
- [ ] JWT authentication middleware
- [ ] Rate limiting middleware (token bucket)
- [ ] Structured error responses (JSON, consistent format)
- [ ] Multi-tenant isolation via tenant_id in all queries
- [ ] `go test -race ./...` passes with zero races
- [ ] `golangci-lint run` passes cleanly

---

## Execution Slices

### Slice 6.1 — Database: Migration for `users` Table
**Build command**: `go build ./...`  
**Test command**: `go test -short ./...`

**Tasks**:
1. Create `migrations/000001_create_users.up.sql` and `.down.sql`
2. Columns: `id` (UUID), `tenant_id`, `name`, `email`, `created_at`, `updated_at`
3. Add unique constraint on `(tenant_id, email)`
4. Integration test: verify tenant isolation via separate connections

```sql
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  VARCHAR(50)  NOT NULL,
    name       VARCHAR(255) NOT NULL,
    email      VARCHAR(255) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT uq_users_tenant_email UNIQUE (tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
```

**Validation Gate**:
```bash
go build ./...                                           # zero errors
go vet ./...                                             # zero warnings
go test -short ./...                                     # all pass
grep -rn 'fmt.Sprintf.*SELECT\|fmt.Sprintf.*INSERT' --include="*.go"  # zero hits
```

**Stop Condition**: If migration fails or tenant isolation test fails → STOP.

### Slice 6.2 — Repository Layer: `UserRepository`
**Build command**: `go build ./...`  
**Test command**: `go test ./internal/repository/...`

**Tasks**:
1. Define `UserRepository` interface in `internal/domain/`
2. Implement `pgxUserRepository` in `internal/repository/`
3. Methods: `FindByID`, `FindByTenantID` (paginated), `Create`, `Update`, `Delete`
4. All methods accept `context.Context` as first param
5. Table-driven tests with `testcontainers-go`

```go
type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID, tenantID string) (*User, error)
    FindByTenantID(ctx context.Context, tenantID string, limit, offset int) ([]User, error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id uuid.UUID, tenantID string) error
}
```

### Slice 6.3 — Service Layer: `UserService`
**Build command**: `go build ./...`  
**Test command**: `go test ./internal/service/...`

**Tasks**:
1. Create `UserService` struct accepting `UserRepository` interface
2. Business logic: email validation, duplicate checking, input sanitization
3. Return domain errors (not HTTP errors) — handler maps to status codes
4. Table-driven unit tests with fake repository

### Slice 6.4 — HTTP Handlers
**Tasks**:
1. Create `UserHandler` with Chi router subroutes
2. Parse and validate requests, call service, write JSON responses
3. Consistent error response format: `{"error": "message", "code": "NOT_FOUND"}`
4. `httptest` tests for all handlers

### Slice 6.5 — Auth Middleware (JWT)
**Tasks**:
1. Create JWT validation middleware
2. Extract tenant_id from JWT claims, inject into context
3. Unit test: verify unauthorized requests are rejected

### Slice 6.6 — Rate Limiting Middleware
**Tasks**:
1. Token bucket rate limiter (`golang.org/x/time/rate`)
2. Per-IP or per-tenant limiting (configurable)
3. Return `429 Too Many Requests` with `Retry-After` header

### Slice 6.7 — Middleware Chain & Router Setup
**Tasks**:
1. Wire all middleware in correct order: logging → rate limit → auth → handler
2. Register routes in `cmd/server/main.go`
3. Add `/health` and `/ready` endpoints
4. Integration test: full request through middleware chain

### Slice 6.8 — Structured Logging (slog)
**Tasks**:
1. Configure `slog` with JSON handler for production
2. Request ID middleware (inject into context + log)
3. Log all requests with method, path, status, duration

---

## Rollback Plan

1. **Database**: `migrate -path migrations -database "$DATABASE_URL" down 1`
2. **Code**: Revert commit (single commit per slice)
3. **Config**: No config changes in this phase

---

## 6 Mandatory Blocks — Verification

| # | Block | Present |
|---|-------|---------|
| 1 | Numbered execution slices with build/test commands | ✅ |
| 2 | Explicit validation gates per slice | ✅ |
| 3 | Stop conditions | ✅ |
| 4 | Rollback plan (3 tiers) | ✅ |
| 5 | Anti-pattern grep commands | ✅ |
| 6 | File-level change manifest | ⬜ (add before execution) |
