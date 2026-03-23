---
description: GraphQL patterns for Python — Strawberry, code-first schema, DataLoaders, auth, multi-tenant resolvers
applyTo: '**/*schema*,**/*resolver*,**/*query*,**/*mutation*,**/graphql/**'
---

# Python GraphQL Patterns (Strawberry)

## Schema Design (Code-First)

### Typed Schema with Strawberry
```python
import strawberry
from strawberry.types import Info

@strawberry.type
class Producer:
    id: strawberry.ID
    name: str
    contact_email: str
    tenant_id: str

@strawberry.input
class CreateProducerInput:
    name: str
    contact_email: str

@strawberry.type
class CreateProducerPayload:
    producer: Producer | None
    success: bool
    message: str | None = None

# ✅ Modular — extend Query per domain
@strawberry.type
class Query:
    @strawberry.field
    async def producer(self, info: Info, id: strawberry.ID) -> Producer | None:
        tenant_id = info.context["tenant_id"]
        return await info.context["repo"].get_by_id(id, tenant_id)

    @strawberry.field
    async def producers(
        self, info: Info, page: int = 1, page_size: int = 25
    ) -> list[Producer]:
        tenant_id = info.context["tenant_id"]
        return await info.context["repo"].get_paged(page, page_size, tenant_id)

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_producer(
        self, info: Info, input: CreateProducerInput
    ) -> CreateProducerPayload:
        tenant_id = info.context["tenant_id"]
        producer = await info.context["service"].create(input, tenant_id)
        return CreateProducerPayload(producer=producer, success=True, message="Created")
```

## DataLoaders (N+1 Prevention)

```python
from strawberry.dataloader import DataLoader

# ✅ Batch load — single query for all requested IDs
async def load_producers(keys: list[str]) -> list[Producer | None]:
    producers = await repo.get_by_ids(keys)
    mapping = {p.id: p for p in producers}
    return [mapping.get(key) for key in keys]

# ✅ Create loader per-request in context
async def get_context(request: Request) -> dict:
    claims = extract_claims(request)
    return {
        "user_id": claims["sub"],
        "tenant_id": claims["tenant_id"],
        "producer_loader": DataLoader(load_fn=load_producers),
    }

# ✅ Usage in resolver
@strawberry.field
async def producer(self, info: Info) -> Producer | None:
    return await info.context["producer_loader"].load(self.producer_id)
```

### DataLoader Rules
```
❌ NEVER loop through keys with individual queries (N+1 in batch!)
✅ ALWAYS return results in same order as input keys
✅ ALWAYS scope batch queries by tenant_id
✅ ALWAYS create loaders per-request (not global)
```

## Authentication & Multi-Tenancy

```python
from strawberry.permission import BasePermission

# ✅ Permission class for authorization
class IsAuthenticated(BasePermission):
    message = "Authentication required"

    async def has_permission(self, source, info: Info, **kwargs) -> bool:
        return info.context.get("user_id") is not None

class RequireRole(BasePermission):
    message = "Insufficient permissions"

    def __init__(self, role: str):
        self.role = role

    async def has_permission(self, source, info: Info, **kwargs) -> bool:
        return self.role in info.context.get("roles", [])

# ✅ Usage
@strawberry.field(permission_classes=[IsAuthenticated])
async def producer(self, info: Info, id: strawberry.ID) -> Producer | None:
    tenant_id = info.context["tenant_id"]  # Always pass tenant scope
    return await info.context["repo"].get_by_id(id, tenant_id)
```

## Input Validation (Pydantic)

```python
from pydantic import BaseModel, EmailStr, Field

class CreateProducerInput(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    contact_email: EmailStr

# ✅ Validate in mutation before calling service
@strawberry.mutation
async def create_producer(self, info: Info, input: CreateProducerInput) -> CreateProducerPayload:
    try:
        validated = CreateProducerInput.model_validate(input.__dict__)
    except ValidationError as e:
        return CreateProducerPayload(producer=None, success=False, message=str(e))
    return await info.context["service"].create(validated, info.context["tenant_id"])
```

## Error Handling

```python
# ✅ Custom error types — never leak exceptions in production
from strawberry.extensions import SchemaExtension

class ErrorLoggingExtension(SchemaExtension):
    def on_execute(self):
        yield
        result = self.execution_context.result
        if result and result.errors:
            for error in result.errors:
                logger.error("GraphQL error: %s", error.message, exc_info=error.original_error)

schema = strawberry.Schema(
    query=Query,
    mutation=Mutation,
    extensions=[ErrorLoggingExtension],
)
```

## Query Depth Limiting

```python
from strawberry.extensions import QueryDepthLimiter

schema = strawberry.Schema(
    query=Query,
    extensions=[QueryDepthLimiter(max_depth=10)],
)
```

## Anti-Patterns

```
❌ Business logic in resolvers (delegate to services)
❌ DataLoaders shared across requests (create per-request)
❌ Missing tenant_id in DataLoader batch queries
❌ Returning ORM models directly (use Strawberry types or Pydantic)
❌ No query depth limits (allows malicious deep queries)
❌ Bare except in resolvers (log then return structured error)
```

## See Also

- `api-patterns.instructions.md` — REST patterns (for hybrid REST+GraphQL)
- `database.instructions.md` — SQLAlchemy, parameterized queries
- `security.instructions.md` — JWT validation, Pydantic input schemas
- `performance.instructions.md` — Async concurrency, connection pooling
