---
description: GraphQL patterns for TypeScript — Apollo Server, code-first schema, DataLoaders, auth middleware
applyTo: '**/*resolver*,**/*schema*,**/*typeDef*,**/*Query*,**/*Mutation*,**/graphql/**'
---

# TypeScript GraphQL Patterns (Apollo Server)

## Schema Design

### Code-First with Type Definitions
```typescript
// ✅ Modular type definitions — one file per domain
// schema/producer.ts
export const producerTypeDefs = gql`
  type Producer {
    id: ID!
    name: String!
    contactEmail: String!
    tenantId: String!
  }

  extend type Query {
    producer(id: ID!): Producer
    producers(page: Int = 1, pageSize: Int = 25): ProducerPage!
  }

  extend type Mutation {
    createProducer(input: CreateProducerInput!): CreateProducerPayload!
  }

  input CreateProducerInput {
    name: String!
    contactEmail: String!
  }

  type CreateProducerPayload {
    producer: Producer
    success: Boolean!
    message: String
  }
`;
```

### Resolver Structure
```typescript
// ✅ Resolvers delegate to services — no business logic here
export const producerResolvers: Resolvers = {
  Query: {
    producer: async (_, { id }, { services, tenantId }) => {
      return services.producer.getById(id, tenantId);
    },
    producers: async (_, { page, pageSize }, { services, tenantId }) => {
      return services.producer.getPaged(page, pageSize, tenantId);
    },
  },
  Mutation: {
    createProducer: async (_, { input }, { services, tenantId, userId }) => {
      const parsed = CreateProducerSchema.safeParse(input);
      if (!parsed.success) {
        return { producer: null, success: false, message: parsed.error.message };
      }
      const producer = await services.producer.create(parsed.data, tenantId);
      return { producer, success: true, message: 'Created' };
    },
  },
};
```

## DataLoaders (N+1 Prevention)

```typescript
import DataLoader from 'dataloader';

// ✅ Batch load — single query for all requested IDs
function createProducerLoader(repo: ProducerRepository, tenantId: string) {
  return new DataLoader<string, Producer | null>(async (ids) => {
    const producers = await repo.getByIds([...ids], tenantId);
    const map = new Map(producers.map(p => [p.id, p]));
    return ids.map(id => map.get(id) ?? null);
  });
}

// ✅ Create loaders per-request in context factory
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    const { userId, tenantId } = extractClaims(req);
    return {
      userId,
      tenantId,
      loaders: {
        producer: createProducerLoader(producerRepo, tenantId),
      },
    };
  },
});

// ✅ Usage in resolver
Producer: {
  owner: (parent, _, { loaders }) => loaders.user.load(parent.ownerId),
}
```

### DataLoader Rules
```
❌ NEVER create DataLoaders outside request context (shared state across requests!)
❌ NEVER loop with individual queries inside batch function
✅ ALWAYS return results in same order as input keys
✅ ALWAYS scope batch queries by tenantId
```

## Authentication & Authorization

```typescript
// ✅ Extract claims in context factory
function buildContext({ req }: { req: Request }): Context {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) throw new AuthenticationError('Token required');

  const claims = verifyJWT(token);
  return {
    userId: claims.sub,
    tenantId: claims.tenant_id,
    roles: claims.roles ?? [],
  };
}

// ✅ Auth directive or middleware
function requireRole(role: string) {
  return (resolver: Function) => async (parent: any, args: any, ctx: Context, info: any) => {
    if (!ctx.roles.includes(role)) {
      throw new ForbiddenError('Insufficient permissions');
    }
    return resolver(parent, args, ctx, info);
  };
}
```

## Input Validation (Zod)

```typescript
import { z } from 'zod';

const CreateProducerSchema = z.object({
  name: z.string().min(1).max(200),
  contactEmail: z.string().email(),
});

// ✅ Validate in mutation resolver before calling service
const parsed = CreateProducerSchema.safeParse(input);
if (!parsed.success) {
  return { success: false, errors: parsed.error.flatten().fieldErrors };
}
```

## Error Handling

```typescript
// ✅ Format errors for production — never leak stack traces
const server = new ApolloServer({
  formatError: (err) => {
    if (process.env.NODE_ENV === 'production') {
      if (err.extensions?.code === 'INTERNAL_SERVER_ERROR') {
        return new Error('An unexpected error occurred');
      }
    }
    return err;
  },
});
```

## Query Depth & Complexity

```typescript
import depthLimit from 'graphql-depth-limit';
import { createComplexityLimitRule } from 'graphql-validation-complexity';

const server = new ApolloServer({
  validationRules: [
    depthLimit(10),
    createComplexityLimitRule(1000),
  ],
});
```

## Anti-Patterns

```
❌ Business logic in resolvers (delegate to services)
❌ DataLoaders created outside request scope (shared state!)
❌ Missing tenantId filtering in DataLoader batch functions
❌ No input validation (validate with Zod before service calls)
❌ Returning ORM/database entities directly (use typed response objects)
❌ No query depth or complexity limits (DoS via deeply nested queries)
❌ Stack traces in production error responses
```

## See Also

- `api-patterns.instructions.md` — REST patterns (for hybrid REST+GraphQL APIs)
- `database.instructions.md` — Repository patterns, parameterized queries
- `security.instructions.md` — JWT validation, Zod schemas
- `performance.instructions.md` — Async patterns, connection pooling
