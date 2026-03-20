---
description: "Scaffold an Express Router with validation middleware, proper HTTP status codes, and error forwarding."
agent: "agent"
tools: [read, edit, search]
---
# Create New Controller (Express Router)

Scaffold a route handler that follows REST conventions and delegates all logic to services.

## Required Pattern

```typescript
import { Router, Request, Response, NextFunction } from 'express';
import { {EntityName}Service } from '../services/{entityName}Service';
import { authenticate } from '../middleware/auth';

export function create{EntityName}Router(service: {EntityName}Service): Router {
  const router = Router();

  router.get('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const pageSize = parseInt(req.query.pageSize as string) || 20;
      const result = await service.getAll(page, pageSize);
      res.json(result);
    } catch (err) { next(err); }
  });

  router.get('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await service.getById(req.params.id);
      res.json(result);
    } catch (err) { next(err); }
  });

  router.post('/', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await service.create(req.body);
      res.status(201).json(result);
    } catch (err) { next(err); }
  });

  router.put('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await service.update(req.params.id, req.body);
      res.json(result);
    } catch (err) { next(err); }
  });

  router.delete('/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await service.delete(req.params.id);
      res.status(204).send();
    } catch (err) { next(err); }
  });

  return router;
}
```

## Rules

- Routes handle HTTP concerns ONLY — no business logic
- Delegate ALL work to services
- Always forward errors to `next(err)` for the global error handler
- Use `authenticate` middleware for protected routes
- Return proper status codes: 200, 201, 204, 400, 404, 409

## Error Mapping (Global Handler)

| Error Class | HTTP Status |
|-------------|-------------|
| `ZodError` | 400 Bad Request |
| `NotFoundError` | 404 Not Found |
| `ConflictError` | 409 Conflict |
| `UnauthorizedError` | 401 Unauthorized |

## Reference Files

- [API patterns](../instructions/api-patterns.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
