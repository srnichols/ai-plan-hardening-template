---
description: "Scaffold a new service class with typed errors, input validation (Zod), structured logging, and dependency injection."
agent: "agent"
tools: [read, edit, search]
---
# Create New Service

Scaffold a service layer class following clean architecture.

## Required Pattern

```typescript
import { Logger } from 'pino';
import { z } from 'zod';
import { NotFoundError, ValidationError } from '../errors';
import { {EntityName}Repository } from '../repositories/{entityName}Repository';

// Validation schemas
const Create{EntityName}Schema = z.object({
  name: z.string().min(1).max(255),
  // ... fields
});

export class {EntityName}Service {
  constructor(
    private readonly repo: {EntityName}Repository,
    private readonly logger: Logger
  ) {}

  async getById(id: string): Promise<{EntityName}> {
    const entity = await this.repo.findById(id);
    if (!entity) throw new NotFoundError(`{EntityName} ${id} not found`);
    return entity;
  }

  async getAll(page = 1, pageSize = 20): Promise<PagedResult<{EntityName}>> {
    return this.repo.findAll(page, pageSize);
  }

  async create(input: unknown): Promise<{EntityName}> {
    const data = Create{EntityName}Schema.parse(input); // throws ZodError
    this.logger.info({ name: data.name }, 'Creating {entityName}');
    return this.repo.insert(data);
  }

  async update(id: string, input: unknown): Promise<{EntityName}> {
    await this.getById(id); // Throws NotFoundError if missing
    const data = Update{EntityName}Schema.parse(input);
    return this.repo.update(id, data);
  }

  async delete(id: string): Promise<void> {
    await this.getById(id);
    await this.repo.delete(id);
  }
}
```

## Rules

- ALL business logic lives in the service layer — not routes, not repositories
- Validate input with Zod schemas at service boundary
- Throw typed errors: `NotFoundError`, `ValidationError`, `ConflictError`
- Use structured logging (pino) with context objects, not string interpolation
- Services are stateless — inject dependencies via constructor

## Reference Files

- [Architecture principles](../instructions/architecture-principles.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
