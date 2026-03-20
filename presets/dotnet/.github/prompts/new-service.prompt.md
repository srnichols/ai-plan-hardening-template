---
description: "Scaffold a new service class with interface, DI registration, structured logging, input validation, and CancellationToken support."
agent: "agent"
tools: [read, edit, search]
---
# Create New Service

Scaffold a service layer class following the strict layered architecture.

## Required Pattern

### Interface (`I{EntityName}Service.cs`)
```csharp
public interface I{EntityName}Service
{
    Task<{EntityName}Dto> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<{EntityName}Dto>> GetAllAsync(CancellationToken ct = default);
    Task<{EntityName}Dto> CreateAsync(Create{EntityName}Request request, CancellationToken ct = default);
    Task<bool> UpdateAsync(Guid id, Update{EntityName}Request request, CancellationToken ct = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken ct = default);
}
```

### Implementation (`{EntityName}Service.cs`)
```csharp
public sealed partial class {EntityName}Service(
    I{EntityName}Repository repository,
    ILogger<{EntityName}Service> logger) : I{EntityName}Service
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Creating {EntityName} — {Name}")]
    partial void LogCreating(string name);

    public async Task<{EntityName}Dto> CreateAsync(Create{EntityName}Request request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);
        LogCreating(request.Name);
        // Validation, business rules, then delegate to repository
        return await repository.InsertAsync(request, ct);
    }
}
```

## Rules

- ALL business logic lives in the service layer — not controllers, not repositories
- Use `ArgumentNullException.ThrowIfNull()` for required parameters
- Use typed exceptions: `ValidationException`, `NotFoundException`, `ConflictException`
- `sealed partial class` for source-generated logging
- `CancellationToken` on every async method
- Register as `Scoped` in DI: `builder.Services.AddScoped<I{EntityName}Service, {EntityName}Service>();`

## Reference Files

- [Architecture principles](../instructions/architecture-principles.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
