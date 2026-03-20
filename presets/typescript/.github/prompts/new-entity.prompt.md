---
description: "Scaffold a new database entity end-to-end: migration, model, repository, service, controller, and tests."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Database Entity

Scaffold a complete entity from database to API following the layered architecture.

## Required Steps

1. **Create migration** at `src/migrations/YYYYMMDD_add_{entity_name}.ts`:
   ```typescript
   import { Knex } from 'knex';
   export async function up(knex: Knex): Promise<void> {
     await knex.schema.createTable('{entity_name}s', (table) => {
       table.uuid('id').primary().defaultTo(knex.fn.uuid());
       table.string('name').notNullable();
       table.timestamps(true, true); // created_at, updated_at
       table.index(['name']);
     });
   }
   export async function down(knex: Knex): Promise<void> {
     await knex.schema.dropTableIfExists('{entity_name}s');
   }
   ```

2. **Create model/interface** at `src/models/{entityName}.ts`:
   ```typescript
   export interface {EntityName} {
     id: string;
     name: string;
     createdAt: Date;
     updatedAt: Date;
   }
   export interface Create{EntityName}Request {
     name: string;
   }
   ```

3. **Create repository** at `src/repositories/{entityName}Repository.ts`:
   - Use parameterized queries — NEVER string interpolation in SQL
   - Return typed results

4. **Create service** at `src/services/{entityName}Service.ts`:
   - ALL business logic lives here
   - Input validation with Zod
   - Throws typed errors (`NotFoundError`, `ValidationError`)

5. **Create controller/router** at `src/routes/{entityName}Routes.ts`:
   - Express Router with proper HTTP methods
   - Delegates ALL work to the service layer
   - Returns proper status codes

6. **Create tests** at `src/__tests__/{entityName}.test.ts`:
   - Unit test for service with mocked repository
   - Integration test for repository with real database

## Example — Contoso Product

```typescript
// Model
export interface Product { id: string; name: string; price: number; createdAt: Date; }

// Repository
export class ProductRepository {
  async findById(id: string): Promise<Product | null> {
    const [row] = await db.query('SELECT * FROM products WHERE id = $1', [id]);
    return row ?? null;
  }
}

// Service
export class ProductService {
  constructor(private repo: ProductRepository) {}
  async getById(id: string): Promise<Product> {
    const product = await this.repo.findById(id);
    if (!product) throw new NotFoundError(`Product ${id} not found`);
    return product;
  }
}
```

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
