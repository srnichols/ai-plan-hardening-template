---
description: "Scaffold a new database entity end-to-end: migration SQL, model, repository, service, handler, and tests."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Database Entity

Scaffold a complete entity from database to API following Go layered architecture.

## Required Steps

1. **Create migration** at `migrations/YYYYMMDD_add_{entity_name}.up.sql`:
   ```sql
   CREATE TABLE IF NOT EXISTS {entity_name}s (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       name VARCHAR(255) NOT NULL,
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   CREATE INDEX IF NOT EXISTS idx_{entity_name}s_name ON {entity_name}s(name);
   ```

2. **Create model** at `internal/model/{entity_name}.go`:
   ```go
   type {EntityName} struct {
       ID        uuid.UUID `json:"id" db:"id"`
       Name      string    `json:"name" db:"name"`
       CreatedAt time.Time `json:"createdAt" db:"created_at"`
       UpdatedAt time.Time `json:"updatedAt" db:"updated_at"`
   }

   type Create{EntityName}Request struct {
       Name string `json:"name" validate:"required,min=1,max=255"`
   }
   ```

3. **Create repository** at `internal/repository/{entity_name}_repo.go`
4. **Create service** at `internal/service/{entity_name}_service.go`
5. **Create handler** at `internal/handler/{entity_name}_handler.go`
6. **Register routes** in router setup
7. **Create tests** — unit + integration

## Example — Contoso Product

```go
// Repository
type ProductRepository struct {
    db *pgxpool.Pool
}

func (r *ProductRepository) FindByID(ctx context.Context, id uuid.UUID) (*model.Product, error) {
    var p model.Product
    err := r.db.QueryRow(ctx,
        "SELECT id, name, created_at, updated_at FROM products WHERE id = $1", id,
    ).Scan(&p.ID, &p.Name, &p.CreatedAt, &p.UpdatedAt)
    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }
    return &p, err
}

// Service
type ProductService struct {
    repo *ProductRepository
    log  *slog.Logger
}

func (s *ProductService) GetByID(ctx context.Context, id uuid.UUID) (*model.Product, error) {
    p, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("get product %s: %w", id, err)
    }
    return p, nil
}

// Handler
func (h *ProductHandler) GetByID(w http.ResponseWriter, r *http.Request) {
    id, err := uuid.Parse(chi.URLParam(r, "id"))
    if err != nil {
        writeProblem(w, http.StatusBadRequest, "invalid id format")
        return
    }
    product, err := h.service.GetByID(r.Context(), id)
    if errors.Is(err, ErrNotFound) {
        writeProblem(w, http.StatusNotFound, "product not found")
        return
    }
    writeJSON(w, http.StatusOK, product)
}
```

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
