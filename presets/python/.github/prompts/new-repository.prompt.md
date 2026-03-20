---
description: "Scaffold a repository class with asyncpg/SQLAlchemy, parameterized queries, connection pooling, and pagination."
agent: "agent"
tools: [read, edit, search]
---
# Create New Repository

Scaffold a data access repository following clean architecture.

## Required Pattern (asyncpg)

```python
import asyncpg
from uuid import UUID
from src.models.{entity_name} import {EntityName}, Create{EntityName}Request

class {EntityName}Repository:
    def __init__(self, pool: asyncpg.Pool):
        self._pool = pool

    async def find_by_id(self, id: UUID) -> {EntityName} | None:
        row = await self._pool.fetchrow(
            "SELECT id, name, created_at, updated_at FROM {entity_name}s WHERE id = $1",
            id,
        )
        return {EntityName}(**dict(row)) if row else None

    async def find_all(self, page: int, page_size: int) -> PagedResult[{EntityName}]:
        offset = (page - 1) * page_size
        rows = await self._pool.fetch(
            "SELECT id, name, created_at, updated_at FROM {entity_name}s "
            "ORDER BY created_at DESC LIMIT $1 OFFSET $2",
            page_size, offset,
        )
        count = await self._pool.fetchval("SELECT COUNT(*) FROM {entity_name}s")
        return PagedResult(
            items=[{EntityName}(**dict(r)) for r in rows],
            total=count,
            page=page,
            page_size=page_size,
        )

    async def insert(self, data: Create{EntityName}Request) -> {EntityName}:
        row = await self._pool.fetchrow(
            "INSERT INTO {entity_name}s (name) VALUES ($1) "
            "RETURNING id, name, created_at, updated_at",
            data.name,
        )
        return {EntityName}(**dict(row))

    async def update(self, id: UUID, data: Update{EntityName}Request) -> {EntityName}:
        row = await self._pool.fetchrow(
            "UPDATE {entity_name}s SET name = COALESCE($2, name), updated_at = NOW() "
            "WHERE id = $1 RETURNING id, name, created_at, updated_at",
            id, data.name,
        )
        return {EntityName}(**dict(row))

    async def delete(self, id: UUID) -> None:
        await self._pool.execute("DELETE FROM {entity_name}s WHERE id = $1", id)
```

## Rules

- Repositories handle data access ONLY — no business logic
- ALL SQL uses parameterized queries (`$1`, `$2`) — NEVER f-strings or `.format()`
- Use a shared connection pool (`asyncpg.Pool`)
- Return Pydantic models, not raw dicts
- Use `RETURNING` for insert/update efficiency

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
