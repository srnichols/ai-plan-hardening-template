---
description: "Scaffold a new database entity end-to-end: Flyway migration, JPA entity, repository, service, controller, and tests."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Database Entity

Scaffold a complete entity from database to API following Spring layered architecture.

## Required Steps

1. **Create Flyway migration** at `src/main/resources/db/migration/V{N}__{description}.sql`:
   ```sql
   CREATE TABLE IF NOT EXISTS {entity_name}s (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       name VARCHAR(255) NOT NULL,
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   CREATE INDEX IF NOT EXISTS idx_{entity_name}s_name ON {entity_name}s(name);
   ```

2. **Create JPA entity** at `src/main/java/com/contoso/model/{EntityName}.java`:
   ```java
   @Entity
   @Table(name = "{entity_name}s")
   public class {EntityName} {
       @Id @GeneratedValue(strategy = GenerationType.UUID)
       private UUID id;

       @Column(nullable = false)
       private String name;

       @Column(name = "created_at", updatable = false)
       private Instant createdAt;

       @Column(name = "updated_at")
       private Instant updatedAt;
   }
   ```

3. **Create repository** at `src/main/java/com/contoso/repository/{EntityName}Repository.java`:
   ```java
   public interface {EntityName}Repository extends JpaRepository<{EntityName}, UUID> {
       Optional<{EntityName}> findByName(String name);
   }
   ```

4. **Create DTO** at `src/main/java/com/contoso/dto/{EntityName}Dto.java`:
   ```java
   public record {EntityName}Dto(UUID id, String name, Instant createdAt) {}
   public record Create{EntityName}Request(@NotBlank @Size(max = 255) String name) {}
   ```

5. **Create service** at `src/main/java/com/contoso/service/{EntityName}Service.java`

6. **Create controller** at `src/main/java/com/contoso/controller/{EntityName}Controller.java`

7. **Create tests** — TDD preferred:
   - Unit test for service
   - `@DataJpaTest` for repository
   - `@SpringBootTest` integration test

## Example — Contoso Product

```java
@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository repository;
    private static final Logger log = LoggerFactory.getLogger(ProductService.class);

    public ProductDto getById(UUID id) {
        return repository.findById(id)
            .map(this::toDto)
            .orElseThrow(() -> new NotFoundException("Product " + id + " not found"));
    }

    public ProductDto create(CreateProductRequest request) {
        log.info("Creating product: {}", request.name());
        var entity = new Product();
        entity.setName(request.name());
        return toDto(repository.save(entity));
    }
}
```

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
