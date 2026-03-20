---
description: "Scaffold a Spring Data JPA repository with custom queries, pagination, and projections."
agent: "agent"
tools: [read, edit, search]
---
# Create New Repository

Scaffold a data access repository following Spring Data patterns.

## Required Pattern (Spring Data JPA)

```java
public interface {EntityName}Repository extends JpaRepository<{EntityName}, UUID> {

    Optional<{EntityName}> findByName(String name);

    @Query("SELECT e FROM {EntityName} e WHERE e.status = :status ORDER BY e.createdAt DESC")
    Page<{EntityName}> findByStatus(@Param("status") String status, Pageable pageable);

    @Query("SELECT COUNT(e) FROM {EntityName} e WHERE e.createdAt > :since")
    long countSince(@Param("since") Instant since);

    boolean existsByName(String name);
}
```

## Custom Repository (JDBC Template)

When you need full SQL control:

```java
@Repository
@RequiredArgsConstructor
public class {EntityName}CustomRepositoryImpl implements {EntityName}CustomRepository {
    private final JdbcTemplate jdbc;

    public Optional<{EntityName}Dto> findByIdProjected(UUID id) {
        return jdbc.query(
            "SELECT id, name, created_at FROM {entity_name}s WHERE id = ?",
            new Object[]{id},
            rs -> rs.next() ? Optional.of(mapRow(rs)) : Optional.empty()
        );
    }

    private {EntityName}Dto mapRow(ResultSet rs) throws SQLException {
        return new {EntityName}Dto(
            rs.getObject("id", UUID.class),
            rs.getString("name"),
            rs.getObject("created_at", Instant.class)
        );
    }
}
```

## Rules

- Use Spring Data derived queries for simple cases
- Use `@Query` JPQL for complex cases
- Use `JdbcTemplate` only when you need raw SQL control
- NEVER use string concatenation in queries — always `@Param` or `?` placeholders
- Use `Pageable` for all list queries

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
