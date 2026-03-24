---
description: "Generate a Row-Level Security (RLS) policy for a PostgreSQL table with verification test"
mode: agent
---

# Create RLS Policy

Generate a Row-Level Security policy for a tenant table in PostgreSQL.

## Input
- Table name: (ask the user)
- Existing columns: (check the schema or ask)

## Generate

### 1. Migration SQL
```sql
-- Enable RLS
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;
ALTER TABLE {table_name} FORCE ROW LEVEL SECURITY;

-- Create tenant isolation policy
CREATE POLICY tenant_isolation ON {table_name}
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Performance index
CREATE INDEX IF NOT EXISTS idx_{table_name}_tenant_id
    ON {table_name}(tenant_id);
```

### 2. Rollback SQL
```sql
DROP POLICY IF EXISTS tenant_isolation ON {table_name};
ALTER TABLE {table_name} DISABLE ROW LEVEL SECURITY;
DROP INDEX IF EXISTS idx_{table_name}_tenant_id;
```

### 3. Verification Test
```sql
-- Insert test data for tenant A
SET LOCAL app.tenant_id = '00000000-0000-0000-0000-000000000001';
INSERT INTO {table_name} (id, tenant_id, ...) VALUES (...);

-- Switch to tenant B — should NOT see tenant A's data
SET LOCAL app.tenant_id = '00000000-0000-0000-0000-000000000002';
SELECT COUNT(*) FROM {table_name};
-- Expected: 0

-- Switch back to tenant A — should see their data
SET LOCAL app.tenant_id = '00000000-0000-0000-0000-000000000001';
SELECT COUNT(*) FROM {table_name};
-- Expected: 1

-- Cleanup
DELETE FROM {table_name} WHERE id = ...;
```

## Rules
- ALWAYS include the verification test in the migration
- ALWAYS include rollback SQL
- ALWAYS add the tenant_id index
- NEVER create a tenant table without an RLS policy
