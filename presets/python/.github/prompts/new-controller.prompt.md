---
description: "Scaffold a FastAPI router with Pydantic models, Depends injection, proper status codes, and error handling."
agent: "agent"
tools: [read, edit, search]
---
# Create New Controller (FastAPI Router)

Scaffold a route handler that follows REST conventions and delegates all logic to services.

## Required Pattern

```python
from fastapi import APIRouter, Depends, HTTPException, status
from uuid import UUID
from src.models.{entity_name} import {EntityName}, Create{EntityName}Request, Update{EntityName}Request
from src.services.{entity_name}_service import {EntityName}Service

router = APIRouter(prefix="/{entity_name}s", tags=["{entity_name}s"])

@router.get("/", response_model=PagedResult[{EntityName}])
async def list_{entity_name}s(
    page: int = 1,
    page_size: int = 20,
    service: {EntityName}Service = Depends(get_{entity_name}_service),
):
    return await service.get_all(page, page_size)

@router.get("/{id}", response_model={EntityName})
async def get_{entity_name}(
    id: UUID,
    service: {EntityName}Service = Depends(get_{entity_name}_service),
):
    return await service.get_by_id(id)

@router.post("/", response_model={EntityName}, status_code=status.HTTP_201_CREATED)
async def create_{entity_name}(
    request: Create{EntityName}Request,
    service: {EntityName}Service = Depends(get_{entity_name}_service),
):
    return await service.create(request)

@router.put("/{id}", response_model={EntityName})
async def update_{entity_name}(
    id: UUID,
    request: Update{EntityName}Request,
    service: {EntityName}Service = Depends(get_{entity_name}_service),
):
    return await service.update(id, request)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_{entity_name}(
    id: UUID,
    service: {EntityName}Service = Depends(get_{entity_name}_service),
):
    await service.delete(id)
```

## Rules

- Routes handle HTTP concerns ONLY — no business logic
- Delegate ALL work to services via `Depends()`
- Use Pydantic models for request/response typing
- Return proper status codes: 200, 201, 204, 400, 404, 409

## Error Mapping (Exception Handler)

| Exception | HTTP Status |
|-----------|-------------|
| `ValidationError` (Pydantic) | 422 Unprocessable Entity |
| `NotFoundError` | 404 Not Found |
| `ConflictError` | 409 Conflict |
| `UnauthorizedError` | 401 Unauthorized |

## Reference Files

- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
