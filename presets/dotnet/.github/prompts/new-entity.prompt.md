---
description: "Scaffold a new database entity end-to-end: migration SQL, repository, service, DTO, controller, and tests."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Database Entity

Scaffold a complete entity from database to API following the layered architecture.

## Required Steps

1. **Create migration SQL** at `Database/migrations/YYYYMMDD_add_{entity_name}.sql`:
   - Table with `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `created_at TIMESTAMPTZ DEFAULT NOW()`, `updated_at TIMESTAMPTZ DEFAULT NOW()`
   - `IF NOT EXISTS` guards for idempotency
   - Appropriate indexes on frequently queried columns

2. **Create DTO** at `src/Models/{EntityName}Dto.cs`:
   - Use `record` type for immutable DTOs
   - PascalCase properties mapping to snake_case columns (if applicable)

3. **Create repository interface** at `src/Repositories/I{EntityName}Repository.cs`

4. **Create repository** at `src/Repositories/{EntityName}Repository.cs`:
   - Use the project's data access pattern (Dapper or EF Core)
   - Parameterized queries only — NEVER string interpolation in SQL
   - `CancellationToken` on all async methods

5. **Create service interface** at `src/Services/I{EntityName}Service.cs`

6. **Create service** at `src/Services/{EntityName}Service.cs`:
   - ALL business logic lives here (not controllers, not repositories)
   - Input validation, duplicate checks, authorization
   - `CancellationToken` on all async methods

7. **Create controller** at `src/Controllers/{EntityName}Controller.cs`:
   - `[ApiController]` with `[Route("api/[controller]")]`
   - `[Authorize]` at class level
   - Delegates ALL work to the service layer
   - Returns `ProblemDetails` for errors

8. **Register DI** in `Program.cs`:
   ```csharp
   builder.Services.AddScoped<I{EntityName}Repository, {EntityName}Repository>();
   builder.Services.AddScoped<I{EntityName}Service, {EntityName}Service>();
   ```

9. **Create tests** — TDD preferred:
   - Unit test for service logic with mocked repository
   - Integration test for repository with real database

10. **Update documentation** if schema changed

## Naming Conventions

- Database columns: `snake_case` (e.g., `created_at`)
- DTO properties: `PascalCase` (e.g., `CreatedAt`)
- Always use explicit column aliases in SELECT: `SELECT created_at AS CreatedAt`

## Example Entity — `Product`

```csharp
// DTO
public record ProductDto(Guid Id, string Name, decimal Price, DateTime CreatedAt);

// Repository
public async Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
{
    const string sql = "SELECT id AS Id, name AS Name, price AS Price, created_at AS CreatedAt FROM products WHERE id = @Id";
    using var connection = await _connectionFactory.CreateConnectionAsync(ct);
    return await connection.QuerySingleOrDefaultAsync<ProductDto>(sql, new { Id = id });
}

// Service
public async Task<ProductDto> CreateAsync(CreateProductRequest request, CancellationToken ct = default)
{
    ArgumentNullException.ThrowIfNull(request);
    // validation, business rules, then delegate to repository
}
```

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
