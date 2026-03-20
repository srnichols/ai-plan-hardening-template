---
description: "Scaffold a new database entity end-to-end: Alembic migration, SQLAlchemy/raw SQL model, repository, service, FastAPI router, and tests."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Database Entity

Scaffold a complete entity from database to API following the layered architecture.

## Required Steps

1. **Create Alembic migration**:
   ```bash
   alembic revision --autogenerate -m "add_{entity_name}_table"
   ```
   Or manual migration at `alembic/versions/YYYYMMDD_add_{entity_name}.py`:
   ```python
   def upgrade():
       op.create_table(
           '{entity_name}s',
           sa.Column('id', sa.UUID(), primary_key=True, server_default=sa.text('gen_random_uuid()')),
           sa.Column('name', sa.String(255), nullable=False),
           sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()')),
           sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()')),
       )
       op.create_index('ix_{entity_name}s_name', '{entity_name}s', ['name'])
   ```

2. **Create model** at `src/models/{entity_name}.py`:
   ```python
   from pydantic import BaseModel, Field
   from uuid import UUID
   from datetime import datetime

   class {EntityName}(BaseModel):
       id: UUID
       name: str
       created_at: datetime
       updated_at: datetime

   class Create{EntityName}Request(BaseModel):
       name: str = Field(..., min_length=1, max_length=255)
   ```

3. **Create repository** at `src/repositories/{entity_name}_repository.py`
4. **Create service** at `src/services/{entity_name}_service.py`
5. **Create router** at `src/routes/{entity_name}_routes.py`
6. **Create tests** at `tests/test_{entity_name}.py`

## Example — Contoso Product

```python
# Repository
class ProductRepository:
    def __init__(self, pool: asyncpg.Pool):
        self._pool = pool

    async def find_by_id(self, id: UUID) -> Product | None:
        row = await self._pool.fetchrow(
            "SELECT id, name, created_at, updated_at FROM products WHERE id = $1", id
        )
        return Product(**row) if row else None

# Service
class ProductService:
    def __init__(self, repo: ProductRepository):
        self._repo = repo

    async def get_by_id(self, id: UUID) -> Product:
        product = await self._repo.find_by_id(id)
        if not product:
            raise NotFoundError(f"Product {id} not found")
        return product

# Router
router = APIRouter(prefix="/products", tags=["products"])

@router.get("/{id}", response_model=Product)
async def get_product(id: UUID, service: ProductService = Depends(get_product_service)):
    return await service.get_by_id(id)
```

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
