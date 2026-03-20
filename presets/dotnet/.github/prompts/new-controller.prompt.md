---
description: "Scaffold a REST API controller with authorization, ProblemDetails error handling, proper HTTP status codes, and CancellationToken."
agent: "agent"
tools: [read, edit, search]
---
# Create New API Controller

Scaffold a controller that follows REST conventions and delegates all logic to services.

## Required Pattern

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class {EntityName}Controller(
    I{EntityName}Service service,
    ILogger<{EntityName}Controller> logger) : ControllerBase
{
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof({EntityName}Dto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await service.GetByIdAsync(id, ct);
        return result is not null ? Ok(result) : NotFound();
    }

    [HttpPost]
    [ProducesResponseType(typeof({EntityName}Dto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] Create{EntityName}Request request, CancellationToken ct)
    {
        var result = await service.CreateAsync(request, ct);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] Update{EntityName}Request request, CancellationToken ct)
    {
        var success = await service.UpdateAsync(id, request, ct);
        return success ? NoContent() : NotFound();
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await service.DeleteAsync(id, ct);
        return NoContent();
    }
}
```

## Rules

- Controllers handle HTTP concerns ONLY — no business logic
- Delegate ALL work to services via DI
- Return `ProblemDetails` for errors (RFC 9457)
- Use `[ProducesResponseType]` for OpenAPI documentation
- `CancellationToken` on every action method
- Use `[Authorize]` at class level, `[AllowAnonymous]` where needed

## Error Mapping

| Exception | HTTP Status |
|-----------|-------------|
| `ValidationException` | 400 Bad Request |
| `NotFoundException` | 404 Not Found |
| `ConflictException` | 409 Conflict |
| `UnauthorizedAccessException` | 403 Forbidden |

## Reference Files

- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
