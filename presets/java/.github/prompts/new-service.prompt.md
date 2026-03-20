---
description: "Scaffold a Spring service with interface, transaction management, validation, structured logging, and exception handling."
agent: "agent"
tools: [read, edit, search]
---
# Create New Service

Scaffold a service layer class following Spring patterns.

## Required Pattern

```java
public interface {EntityName}Service {
    {EntityName}Dto getById(UUID id);
    Page<{EntityName}Dto> getAll(Pageable pageable);
    {EntityName}Dto create(Create{EntityName}Request request);
    {EntityName}Dto update(UUID id, Update{EntityName}Request request);
    void delete(UUID id);
}
```

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class {EntityName}ServiceImpl implements {EntityName}Service {
    private final {EntityName}Repository repository;
    private static final Logger log = LoggerFactory.getLogger({EntityName}ServiceImpl.class);

    @Override
    public {EntityName}Dto getById(UUID id) {
        return repository.findById(id)
            .map(this::toDto)
            .orElseThrow(() -> new NotFoundException("{EntityName} " + id + " not found"));
    }

    @Override
    @Transactional
    public {EntityName}Dto create(Create{EntityName}Request request) {
        log.info("Creating {entityName}: {}", request.name());
        // Business validation, duplicate checks, etc.
        var entity = new {EntityName}();
        entity.setName(request.name());
        return toDto(repository.save(entity));
    }

    private {EntityName}Dto toDto({EntityName} entity) {
        return new {EntityName}Dto(entity.getId(), entity.getName(), entity.getCreatedAt());
    }
}
```

## Rules

- ALL business logic lives in the service layer — not controllers, not repositories
- Use `@Transactional(readOnly = true)` at class level, `@Transactional` on write methods
- Throw typed exceptions: `NotFoundException`, `ValidationException`, `ConflictException`
- Use Bean Validation on request DTOs (`@NotBlank`, `@Size`, `@Valid`)
- Use SLF4J for structured logging with parameters, not string concatenation

## Reference Files

- [Architecture principles](../instructions/architecture-principles.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
