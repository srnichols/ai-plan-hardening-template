---
description: "Scaffold a repository class with typed queries, parameterized SQL, connection pooling, and pagination."
agent: "agent"
tools: [read, edit, search]
---
# Create New Repository

Scaffold a data access repository following clean architecture.

## Required Pattern (pg / Knex)

```typescript
import { Pool } from 'pg';
import { {EntityName} } from '../models/{entityName}';

export class {EntityName}Repository {
  constructor(private readonly pool: Pool) {}

  async findById(id: string): Promise<{EntityName} | null> {
    const { rows } = await this.pool.query(
      'SELECT id, name, created_at AS "createdAt" FROM {entity_name}s WHERE id = $1',
      [id]
    );
    return rows[0] ?? null;
  }

  async findAll(page: number, pageSize: number): Promise<PagedResult<{EntityName}>> {
    const offset = (page - 1) * pageSize;
    const [{ rows }, { rows: countRows }] = await Promise.all([
      this.pool.query(
        'SELECT id, name, created_at AS "createdAt" FROM {entity_name}s ORDER BY created_at DESC LIMIT $1 OFFSET $2',
        [pageSize, offset]
      ),
      this.pool.query('SELECT COUNT(*)::int AS total FROM {entity_name}s'),
    ]);
    return { items: rows, total: countRows[0].total, page, pageSize };
  }

  async insert(data: Create{EntityName}Request): Promise<{EntityName}> {
    const { rows } = await this.pool.query(
      'INSERT INTO {entity_name}s (name) VALUES ($1) RETURNING id, name, created_at AS "createdAt"',
      [data.name]
    );
    return rows[0];
  }

  async update(id: string, data: Partial<{EntityName}>): Promise<{EntityName}> {
    const { rows } = await this.pool.query(
      'UPDATE {entity_name}s SET name = COALESCE($2, name), updated_at = NOW() WHERE id = $1 RETURNING *',
      [id, data.name]
    );
    return rows[0];
  }

  async delete(id: string): Promise<void> {
    await this.pool.query('DELETE FROM {entity_name}s WHERE id = $1', [id]);
  }
}
```

## Rules

- Repositories handle data access ONLY — no business logic
- ALL SQL uses parameterized queries (`$1`, `$2`) — NEVER template literals with variables
- Use column aliases for camelCase mapping: `created_at AS "createdAt"`
- Use a shared connection pool, never create raw connections
- Return typed results, not `any`

## Reference Files

- [Database instructions](../instructions/database.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
