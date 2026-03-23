---
description: GraphQL patterns for .NET — Hot Chocolate, code-first schema, DataLoaders, authorization, multi-tenant resolvers
applyTo: '**/*Query*.cs,**/*Mutation*.cs,**/*Subscription*.cs,**/*DataLoader*.cs,**/*Resolver*.cs,**/*Type.cs,**/GraphQL/**'
---

# .NET GraphQL Patterns (Hot Chocolate)

## Schema Design (Code-First)

### Modular Root Types with ExtendObjectType
```csharp
// ✅ Separate domains into their own query files
[ExtendObjectType(typeof(Query))]
public class ProducerQueries
{
    [Authorize]
    public async Task<Producer?> GetProducerByIdAsync(
        Guid id,
        [Service] IProducerRepository repository,
        CancellationToken ct)
    {
        return await repository.GetByIdAsync(id, ct);
    }

    [UsePaging(IncludeTotalCount = true)]
    [UseFiltering]
    [UseSorting]
    public IQueryable<Producer> GetProducers([Service] IProducerRepository repository)
        => repository.GetQueryable();
}

// ❌ NEVER: One massive Query class with all resolvers
```

### Registration
```csharp
builder.Services
    .AddGraphQLServer()
    .AddQueryType<Query>()
        .AddTypeExtension<ProducerQueries>()
        .AddTypeExtension<UserQueries>()
    .AddMutationType<Mutation>()
        .AddTypeExtension<ProducerMutations>()
    .AddSubscriptionType<Subscription>()
    .AddAuthorization()
    .AddFiltering()
    .AddSorting()
    .AddProjections()
    .AddInMemorySubscriptions()
    .AddMaxExecutionDepthRule(10)
    .AddQueryCostOptions(o => { o.MaxFieldCost = 10; o.MaxTypeCost = 1000; });
```

## DataLoaders (N+1 Prevention)

```csharp
// ✅ Batch load — single query for all requested IDs
public class ProducerByIdDataLoader : BatchDataLoader<Guid, Producer>
{
    private readonly IProducerRepository _repository;

    public ProducerByIdDataLoader(
        IProducerRepository repository,
        IBatchScheduler batchScheduler,
        DataLoaderOptions? options = null)
        : base(batchScheduler, options)
    {
        _repository = repository;
    }

    protected override async Task<IReadOnlyDictionary<Guid, Producer>> LoadBatchAsync(
        IReadOnlyList<Guid> keys,
        CancellationToken ct)
    {
        // ✅ Single batch query — WHERE id = ANY(@Ids)
        var producers = await _repository.GetByIdsAsync(keys, ct);
        return producers.ToDictionary(p => p.Id);
    }
}

// ✅ Usage in resolver
public async Task<Producer?> GetProducerAsync(
    [Parent] Order order,
    ProducerByIdDataLoader loader,
    CancellationToken ct)
{
    return await loader.LoadAsync(order.ProducerId, ct);
}
```

### Non-Negotiable DataLoader Rules
```
❌ NEVER loop through keys with individual queries:
    foreach (var id in keys)
        results.Add(await repo.GetByIdAsync(id, ct));  // N+1!

✅ ALWAYS use a batch query:
    var items = await repo.GetByIdsAsync(keys, ct);     // 1 query

❌ NEVER fetch ALL records then filter in memory:
    var all = await repo.GetAllAsync(ct);
    return all.Where(x => keys.Contains(x.Id));         // Over-fetch!

✅ ALWAYS implement a dedicated batch repository method:
    SELECT * FROM producers WHERE id = ANY(@Ids) AND tenant_id = @TenantId
```

## Authorization

### Attribute-Based
```csharp
// ✅ Always authorize at the resolver level
[Authorize]                                         // Any authenticated user
[Authorize(Roles = new[] { "admin", "producer" })]  // Role-based
[Authorize(Policy = "RequireOrgAdmin")]              // Policy-based

// ❌ NEVER: Unprotected resolvers that access tenant data
public async Task<IEnumerable<User>> GetAllUsersAsync(...) { ... }  // Missing auth!
```

### Multi-Tenant Context
```csharp
// ✅ Extract tenant from JWT via interceptor
public class TenantHttpRequestInterceptor : DefaultHttpRequestInterceptor
{
    public override ValueTask OnCreateAsync(
        HttpContext context,
        IRequestExecutor requestExecutor,
        OperationRequestBuilder requestBuilder,
        CancellationToken ct)
    {
        var tenantId = context.User.FindFirst("tenant_id")?.Value;
        var userId = context.User.FindFirst("sub")?.Value;

        requestBuilder.SetGlobalState("TenantId", tenantId);
        requestBuilder.SetGlobalState("UserId", userId);

        return base.OnCreateAsync(context, requestExecutor, requestBuilder, ct);
    }
}

// ✅ Usage in resolver — always pass tenantId to repository
[Authorize]
public async Task<Producer?> GetProducerAsync(
    Guid id,
    [GlobalState] string tenantId,
    [Service] IProducerRepository repository,
    CancellationToken ct)
{
    return await repository.GetByIdAsync(id, tenantId, ct);
}
```

## Mutation Patterns

### Input Records + Typed Payloads
```csharp
// ✅ Immutable input types
public record CreateProducerInput(
    string Name,
    string ContactEmail,
    decimal? Latitude,
    decimal? Longitude);

// ✅ Typed response payload (not raw entity)
public record CreateProducerPayload(
    Producer? Producer,
    bool Success,
    string? Message,
    IReadOnlyList<string>? Errors = null);

// ✅ Mutation with validation
[Authorize(Policy = "RequireOrgAdmin")]
public async Task<CreateProducerPayload> CreateProducerAsync(
    CreateProducerInput input,
    [GlobalState] string tenantId,
    [Service] IProducerService service,
    CancellationToken ct)
{
    // Validate at boundary
    if (string.IsNullOrWhiteSpace(input.Name))
        return new(null, false, "Name is required", ["Name cannot be empty"]);

    var producer = await service.CreateAsync(input, tenantId, ct);
    return new(producer, true, "Producer created");
}
```

### Input Validation
```csharp
// ✅ BEST: FluentValidation with Hot Chocolate
public class CreateProducerInputValidator : AbstractValidator<CreateProducerInput>
{
    public CreateProducerInputValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.ContactEmail).NotEmpty().EmailAddress();
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90).When(x => x.Latitude.HasValue);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180).When(x => x.Longitude.HasValue);
    }
}

// Register: .AddFluentValidation()
```

## Subscriptions (Real-Time)

```csharp
// ✅ Tenant-scoped topics
[Subscribe]
[Topic("producer_updated_{tenantId}")]
[Authorize]
public ProducerUpdatedEvent OnProducerUpdated(
    [EventMessage] ProducerUpdatedEvent evt,
    string tenantId)
{
    return evt;
}

// ✅ Publishing from a mutation or service
await eventSender.SendAsync(
    $"producer_updated_{tenantId}",
    new ProducerUpdatedEvent(producer.Id, producer.Name),
    ct);
```

## Error Handling

### Error Filter
```csharp
public class GraphQLErrorFilter : IErrorFilter
{
    private readonly IHostEnvironment _env;

    public GraphQLErrorFilter(IHostEnvironment env) => _env = env;

    public IError OnError(IError error)
    {
        // ❌ NEVER expose exception details in production
        if (_env.IsProduction())
        {
            return error.WithMessage(error.Code switch
            {
                "AUTH_NOT_AUTHENTICATED" => "Authentication required",
                "AUTH_NOT_AUTHORIZED"    => "Insufficient permissions",
                _                        => "An unexpected error occurred"
            });
        }
        return error;
    }
}
```

### Registration
```csharp
builder.Services
    .AddGraphQLServer()
    .AddErrorFilter<GraphQLErrorFilter>()
    // ❌ NEVER in production:
    // .ModifyRequestOptions(o => o.IncludeExceptionDetails = true)
    ;
```

## Query Complexity & Depth Limiting

```csharp
// ✅ Protect against expensive queries
builder.Services
    .AddGraphQLServer()
    .AddMaxExecutionDepthRule(10)       // Prevent deeply nested queries
    .SetPagingOptions(new PagingOptions
    {
        MaxPageSize = 100,              // Cap page size
        DefaultPageSize = 25,
        IncludeTotalCount = true,
    });
```

## Pagination

```csharp
// ✅ Cursor-based (Relay spec — preferred for large datasets)
[UsePaging(IncludeTotalCount = true)]
public IQueryable<Producer> GetProducers([Service] IProducerRepository repository)
    => repository.GetQueryable();

// ✅ Offset-based (simpler, fine for admin screens)
[UseOffsetPaging(IncludeTotalCount = true)]
public IQueryable<Order> GetOrders([Service] IOrderRepository repository)
    => repository.GetQueryable();
```

## Observability

```csharp
// ✅ Diagnostic event listener for tracing and metrics
public class GraphQLDiagnosticListener : ExecutionDiagnosticEventListener
{
    public override IDisposable ExecuteRequest(IRequestContext context)
    {
        var start = Stopwatch.GetTimestamp();
        return new ActionDisposable(() =>
        {
            var elapsed = Stopwatch.GetElapsedTime(start);
            if (elapsed > TimeSpan.FromSeconds(1))
                logger.LogWarning("Slow GraphQL query: {Elapsed}ms", elapsed.TotalMilliseconds);
        });
    }
}
```

## Anti-Patterns

```
❌ Business logic in resolvers (resolvers are the API layer — delegate to services)
❌ DataLoaders that loop through keys with individual queries (N+1)
❌ Missing [Authorize] on resolvers accessing tenant data
❌ Passing full EF/ORM entities as GraphQL types (use DTOs/records)
❌ IncludeExceptionDetails = true in production (leaks stack traces)
❌ No MaxExecutionDepthRule (allows malicious deep queries)
❌ No pagination on collection resolvers (unbounded result sets)
❌ Subscriptions without authorization (any client can listen)
❌ Missing tenantId in DataLoader batch queries (cross-tenant data leak)
```

## See Also

- `api-patterns.instructions.md` — REST patterns, ProblemDetails (when using hybrid REST+GraphQL)
- `database.instructions.md` — Repository patterns, parameterized queries
- `security.instructions.md` — JWT validation, authorization policies
- `performance.instructions.md` — Hot-path optimization, DataLoader batching
- `observability.instructions.md` — Distributed tracing integration
