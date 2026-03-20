---
description: "Scaffold a Spring REST controller with Bean Validation, ProblemDetail errors, proper status codes, and OpenAPI annotations."
agent: "agent"
tools: [read, edit, search]
---
# Create New Controller

Scaffold a controller following REST conventions and delegating all logic to services.

## Required Pattern

```java
@RestController
@RequestMapping("/api/{entityName}s")
@RequiredArgsConstructor
public class {EntityName}Controller {
    private final {EntityName}Service service;

    @GetMapping("/{id}")
    public ResponseEntity<{EntityName}Dto> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping
    public ResponseEntity<Page<{EntityName}Dto>> getAll(Pageable pageable) {
        return ResponseEntity.ok(service.getAll(pageable));
    }

    @PostMapping
    public ResponseEntity<{EntityName}Dto> create(@Valid @RequestBody Create{EntityName}Request request) {
        var result = service.create(request);
        var location = URI.create("/api/{entityName}s/" + result.id());
        return ResponseEntity.created(location).body(result);
    }

    @PutMapping("/{id}")
    public ResponseEntity<{EntityName}Dto> update(
            @PathVariable UUID id,
            @Valid @RequestBody Update{EntityName}Request request) {
        return ResponseEntity.ok(service.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

## Rules

- Controllers handle HTTP concerns ONLY — no business logic
- Delegate ALL work to services
- Use `@Valid` for Bean Validation on request bodies
- Return proper status codes: 200, 201, 204, 400, 404, 409

## Error Mapping (`@RestControllerAdvice`)

| Exception | HTTP Status |
|-----------|-------------|
| `MethodArgumentNotValidException` | 400 Bad Request |
| `NotFoundException` | 404 Not Found |
| `ConflictException` | 409 Conflict |
| `AccessDeniedException` | 403 Forbidden |

## Reference Files

- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
