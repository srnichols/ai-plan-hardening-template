---
description: Row-Level Security (RLS) patterns for PostgreSQL — policy creation, testing, migration safety
applyTo: '**/*.sql'
---

# Row-Level Security Patterns

## Standard RLS Policy

Every tenant table MUST have RLS enabled with a policy:

```sql
-- 1. Enable RLS on the table
ALTER TABLE entity_name ENABLE ROW LEVEL SECURITY;

-- 2. Create isolation policy
CREATE POLICY tenant_isolation ON entity_name
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- 3. Force RLS for table owner too (prevents bypass)
ALTER TABLE entity_name FORCE ROW LEVEL SECURITY;
```

## Setting Tenant Context in Application

Before executing queries, set the tenant context:
```sql
SET LOCAL app.tenant_id = '<tenant-uuid>';
```

In application code (Dapper example):
```csharp
await connection.ExecuteAsync(
    "SET LOCAL app.tenant_id = @TenantId",
    new { TenantId = currentTenantId });
```

## Migration Safety Rules

1. **New tables**: ALWAYS include RLS policy in the same migration that creates the table
2. **Never create a tenant table without RLS** — if data has a `tenant_id` column, it needs a policy
3. **Test RLS in migration**: Include a verification query that confirms the policy works
4. **Rollback**: DROP POLICY must precede DROP TABLE in rollback scripts

## RLS Verification Test Pattern

```sql
-- Set tenant A context
SET LOCAL app.tenant_id = '<tenant-a-uuid>';

-- Insert test data for tenant A
INSERT INTO entity_name (id, tenant_id, name) VALUES (gen_random_uuid(), '<tenant-a-uuid>', 'Tenant A Data');

-- Set tenant B context
SET LOCAL app.tenant_id = '<tenant-b-uuid>';

-- This SELECT should return 0 rows (tenant B cannot see tenant A's data)
SELECT COUNT(*) FROM entity_name WHERE name = 'Tenant A Data';
-- Expected: 0
```

## Index Requirements

Every tenant table needs a tenant_id index for RLS performance:
```sql
CREATE INDEX idx_entity_name_tenant_id ON entity_name(tenant_id);
```

For frequently filtered columns, add composite indexes:
```sql
CREATE INDEX idx_entity_name_tenant_status ON entity_name(tenant_id, status);
```

## Common Mistakes

- **Forgetting to enable RLS** — table created but no policy applied
- **Using `current_user` instead of `current_setting`** — application connections often share a single DB user
- **Not forcing RLS for table owner** — `ALTER TABLE ... FORCE ROW LEVEL SECURITY` prevents bypass
- **Missing RLS on junction tables** — `user_roles` needs RLS if it contains `tenant_id`
- **SELECT * across tenants in admin queries** — use a separate non-RLS connection or bypass role
