---
description: GraphQL patterns for Java — Spring GraphQL, controller-style schema mapping, DataLoaders, security
applyTo: '**/*Controller*.java,**/*Query*.java,**/*Mutation*.java,**/*DataLoader*.java,**/graphql/**,**/*.graphqls'
---

# Java GraphQL Patterns (Spring for GraphQL)

## Schema Design (Schema-First)

### GraphQL SDL
```graphql
# src/main/resources/graphql/schema.graphqls
type Query {
    producer(id: ID!): Producer
    producers(page: Int = 1, pageSize: Int = 25): ProducerPage!
}

type Mutation {
    createProducer(input: CreateProducerInput!): CreateProducerPayload!
}

type Producer {
    id: ID!
    name: String!
    contactEmail: String!
}

input CreateProducerInput {
    name: String!
    contactEmail: String!
}

type CreateProducerPayload {
    producer: Producer
    success: Boolean!
    message: String
}
```

### Controller-Style Mapping
```java
@Controller
public class ProducerGraphQLController {

    private final ProducerService service;

    // ✅ @QueryMapping maps to Query type fields
    @QueryMapping
    public Producer producer(@Argument UUID id, @AuthenticationPrincipal JwtUser user) {
        return service.getById(id, user.getTenantId());
    }

    @QueryMapping
    public ProducerPage producers(@Argument int page, @Argument int pageSize,
                                   @AuthenticationPrincipal JwtUser user) {
        return service.getPaged(page, pageSize, user.getTenantId());
    }

    // ✅ @MutationMapping maps to Mutation type fields
    @MutationMapping
    @PreAuthorize("hasRole('ADMIN')")
    public CreateProducerPayload createProducer(
            @Argument @Valid CreateProducerInput input,
            @AuthenticationPrincipal JwtUser user) {
        var producer = service.create(input, user.getTenantId());
        return new CreateProducerPayload(producer, true, "Created");
    }
}
```

## DataLoaders (N+1 Prevention)

```java
@Controller
public class OrderGraphQLController {

    // ✅ @BatchMapping batches child resolution automatically
    @BatchMapping
    public Map<Order, Producer> producer(List<Order> orders, ProducerRepository repo) {
        var ids = orders.stream().map(Order::getProducerId).toList();
        var producers = repo.findByIds(ids);     // Single batch query
        var map = producers.stream().collect(Collectors.toMap(Producer::getId, p -> p));
        return orders.stream().collect(Collectors.toMap(o -> o, o -> map.get(o.getProducerId())));
    }
}
```

### Manual DataLoaders
```java
@Configuration
public class DataLoaderRegistration {

    @Bean
    public BatchLoaderRegistry batchLoaderRegistry(ProducerRepository repo) {
        return registry -> registry.forTypePair(UUID.class, Producer.class)
            .registerMappedBatchLoader((ids, env) -> {
                var producers = repo.findByIds(List.copyOf(ids));
                return Mono.just(producers.stream()
                    .collect(Collectors.toMap(Producer::getId, p -> p)));
            });
    }
}
```

## Authentication & Authorization

```java
// ✅ Spring Security applies to GraphQL controllers
@Controller
@PreAuthorize("isAuthenticated()")
public class ProducerGraphQLController { ... }

// ✅ Method-level security
@MutationMapping
@PreAuthorize("hasRole('ADMIN') or #input.tenantId == authentication.principal.tenantId")
public CreateProducerPayload createProducer(@Argument @Valid CreateProducerInput input) { ... }
```

## Input Validation

```java
// ✅ Bean Validation on input types
public record CreateProducerInput(
    @NotBlank @Size(max = 200) String name,
    @NotBlank @Email String contactEmail
) {}

// ✅ @Valid triggers validation in @MutationMapping
@MutationMapping
public CreateProducerPayload createProducer(@Argument @Valid CreateProducerInput input) { ... }
```

## Error Handling

```java
// ✅ Custom exception resolver
@Component
public class GraphQLExceptionResolver extends DataFetcherExceptionResolverAdapter {

    @Override
    protected GraphQLError resolveToSingleError(Throwable ex, DataFetchingEnvironment env) {
        if (ex instanceof NotFoundException) {
            return GraphqlErrorBuilder.newError(env)
                .message("Resource not found")
                .errorType(ErrorType.NOT_FOUND)
                .build();
        }
        // ❌ NEVER leak stack traces
        return GraphqlErrorBuilder.newError(env)
            .message("Internal error")
            .errorType(ErrorType.INTERNAL_ERROR)
            .build();
    }
}
```

## Anti-Patterns

```
❌ Business logic in @QueryMapping/@MutationMapping (delegate to services)
❌ N+1 — using @SchemaMapping without @BatchMapping for child collections
❌ Missing @PreAuthorize on mutations that modify tenant data
❌ Returning JPA entities directly (use DTOs/records)
❌ No input validation (@Valid on @Argument)
❌ Leaking exception details in production error responses
```

## See Also

- `api-patterns.instructions.md` — REST patterns (for hybrid REST+GraphQL)
- `database.instructions.md` — JPA repositories, batch query patterns
- `security.instructions.md` — Spring Security, @PreAuthorize
- `performance.instructions.md` — Caching, virtual threads
