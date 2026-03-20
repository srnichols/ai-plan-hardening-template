---
description: "Scaffold a repository class with interface, parameterized queries, connection management, and async patterns."
agent: "agent"
tools: [read, edit, search]
---
# Create New Repository

Scaffold a data access repository following clean architecture.

## Required Pattern

### Interface (`I{EntityName}Repository.cs`)
```csharp
public interface I{EntityName}Repository
{
    Task<{EntityName}Dto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<{EntityName}Dto>> GetAllAsync(int page, int pageSize, CancellationToken ct = default);
    Task<{EntityName}Dto> InsertAsync(Create{EntityName}Request request, CancellationToken ct = default);
    Task<bool> UpdateAsync(Guid id, Update{EntityName}Request request, CancellationToken ct = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken ct = default);
}
```

### Dapper Implementation (`{EntityName}Repository.cs`)
```csharp
public sealed class {EntityName}Repository(IDbConnectionFactory connectionFactory) : I{EntityName}Repository
{
    public async Task<{EntityName}Dto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        const string sql = """
            SELECT id AS Id, name AS Name, created_at AS CreatedAt
            FROM {entity_name}s
            WHERE id = @Id
            """;
        using var connection = await connectionFactory.CreateConnectionAsync(ct);
        return await connection.QuerySingleOrDefaultAsync<{EntityName}Dto>(sql, new { Id = id });
    }
}
```

### EF Core Implementation (`{EntityName}Repository.cs`)
```csharp
public sealed class {EntityName}Repository(AppDbContext context) : I{EntityName}Repository
{
    public async Task<{EntityName}Dto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        return await context.{EntityName}s
            .Where(e => e.Id == id)
            .Select(e => new {EntityName}Dto(e.Id, e.Name, e.CreatedAt))
            .FirstOrDefaultAsync(ct);
    }
}
```

## Rules

- Repositories handle data access ONLY — no business logic
- ALL SQL uses parameterized queries (`@Param`) — NEVER string interpolation
- `CancellationToken` on every async method
- Use `using` or `await using` for connection disposal
- Use explicit column aliases: `SELECT snake_col AS PascalProp`
- Register as `Scoped` in DI

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
