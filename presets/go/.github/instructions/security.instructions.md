---
description: Go security patterns — authentication, input validation, secrets management
applyTo: '**/*.go'
---

# Go Security Patterns

## Authentication & Authorization

### JWT Middleware
```go
func JWTAuth(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if token == "" {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }

        claims, err := validateJWT(strings.TrimPrefix(token, "Bearer "))
        if err != nil {
            http.Error(w, "invalid token", http.StatusUnauthorized)
            return
        }

        ctx := context.WithValue(r.Context(), userClaimsKey, claims)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

### Role-Based Access
```go
func RequireRole(role string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            claims := r.Context().Value(userClaimsKey).(*Claims)
            if !claims.HasRole(role) {
                http.Error(w, "forbidden", http.StatusForbidden)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

## Input Validation

### Always validate at handler boundaries
```go
// ❌ NEVER: Trust input
func CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    json.NewDecoder(r.Body).Decode(&req)
    // use req directly...
}

// ✅ ALWAYS: Validate
func CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    if err := req.Validate(); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    // proceed with validated req...
}

// Validation method on request type
func (r CreateUserRequest) Validate() error {
    if strings.TrimSpace(r.Name) == "" {
        return errors.New("name is required")
    }
    if !isValidEmail(r.Email) {
        return errors.New("invalid email format")
    }
    return nil
}
```

## Secrets Management

```go
// ❌ NEVER: Hardcoded secrets
dbPassword := "secret123"

// ✅ ALWAYS: Environment variables
dbPassword := os.Getenv("DB_PASSWORD")
if dbPassword == "" {
    log.Fatal("DB_PASSWORD is required")
}
```

## SQL Injection Prevention

```go
// ❌ NEVER: String formatting
query := fmt.Sprintf("SELECT * FROM users WHERE id = '%s'", id)

// ✅ ALWAYS: Parameterized
query := "SELECT * FROM users WHERE id = $1"
row := db.QueryRowContext(ctx, query, id)
```

## Rate Limiting

```go
func RateLimit(requestsPerSecond int) func(http.Handler) http.Handler {
    limiter := rate.NewLimiter(rate.Limit(requestsPerSecond), requestsPerSecond*2)
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

## Common Vulnerabilities to Prevent

| Vulnerability | Prevention |
|--------------|------------|
| SQL Injection | Parameterized queries only |
| Path Traversal | `filepath.Clean`, validate paths |
| XSS | `html/template` auto-escaping |
| SSRF | Validate URLs, restrict outbound |
| Race Conditions | `go test -race`, proper synchronization |
