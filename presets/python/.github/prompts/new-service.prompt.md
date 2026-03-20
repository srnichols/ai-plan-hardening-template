---
description: "Scaffold a new service class with typed errors, Pydantic validation, structured logging, and dependency injection."
agent: "agent"
tools: [read, edit, search]
---
# Create New Service

Scaffold a service layer class following clean architecture.

## Required Pattern

```python
import structlog
from uuid import UUID
from src.models.{entity_name} import {EntityName}, Create{EntityName}Request
from src.repositories.{entity_name}_repository import {EntityName}Repository
from src.errors import NotFoundError, ValidationError

logger = structlog.get_logger(__name__)

class {EntityName}Service:
    def __init__(self, repo: {EntityName}Repository):
        self._repo = repo

    async def get_by_id(self, id: UUID) -> {EntityName}:
        entity = await self._repo.find_by_id(id)
        if not entity:
            raise NotFoundError(f"{EntityName} {id} not found")
        return entity

    async def get_all(self, page: int = 1, page_size: int = 20) -> PagedResult[{EntityName}]:
        return await self._repo.find_all(page, page_size)

    async def create(self, request: Create{EntityName}Request) -> {EntityName}:
        logger.info("creating_{entity_name}", name=request.name)
        # Business rules, duplicate checks, etc.
        return await self._repo.insert(request)

    async def update(self, id: UUID, request: Update{EntityName}Request) -> {EntityName}:
        await self.get_by_id(id)  # Raises NotFoundError if missing
        return await self._repo.update(id, request)

    async def delete(self, id: UUID) -> None:
        await self.get_by_id(id)
        await self._repo.delete(id)
```

## Rules

- ALL business logic lives in the service layer — not routes, not repositories
- Pydantic validates input at the boundary (models with `Field` constraints)
- Raise typed exceptions: `NotFoundError`, `ValidationError`, `ConflictError`
- Use structlog for structured logging with context
- Services are stateless — inject dependencies via constructor

## FastAPI Dependency Injection

```python
def get_{entity_name}_service(
    pool: asyncpg.Pool = Depends(get_pool),
) -> {EntityName}Service:
    repo = {EntityName}Repository(pool)
    return {EntityName}Service(repo)
```

## Reference Files

- [Architecture principles](../instructions/architecture-principles.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
