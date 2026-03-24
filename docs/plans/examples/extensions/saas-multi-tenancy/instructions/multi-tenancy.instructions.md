---
description: Multi-tenant isolation patterns — middleware, query safety, cache scoping, event context, and cross-tenant prevention
applyTo: '**'
---

# Multi-Tenancy Isolation Rules

## Tenant Context Flow

Every request must carry tenant context through all layers:

```
JWT Token (contains tenant_id claim)
  ↓
Tenant Validation Middleware (extracts + validates)
  ↓
HttpContext.Items["TenantId"] (injected for the request)
  ↓
Service Layer (reads via ITenantService.GetCurrentTenantIdAsync())
  ↓
Repository Layer (includes tenant_id in every query)
  ↓
Database (RLS policy enforces isolation at storage level)
```

## Rules

### Query Safety
1. **ALL queries MUST include `WHERE tenant_id = @TenantId`** — no exceptions except global reference tables
2. **Global reference tables** (no tenant_id): document these explicitly (e.g., `users`, `system_config`, `subscription_plans`)
3. **JOIN queries**: Always filter on tenant_id in the WHERE clause, not just the JOIN condition
4. **Subqueries**: Inner queries must also include tenant_id filter
5. **Aggregate queries**: GROUP BY must include tenant_id, or filter to a single tenant first

### Caching
6. **ALL cache keys MUST include tenant ID**: `tenant:{tenantId}:entity:{entityId}`
7. **Cache invalidation**: When updating tenant data, clear that tenant's cache only — never flush all
8. **Shared cache entries** (non-tenant): Use a `global:` prefix to distinguish from tenant-scoped keys
9. **Cache TTL**: Tenant-specific data should use shorter TTLs than global data

### Events & Messaging
10. **ALL published events MUST include tenant context**: `TenantId` property in the event payload
11. **Event subscribers**: Validate tenant context before processing — reject events without tenant_id
12. **Topic naming**: Include tenant scope in topic structure (e.g., `events.{entity}.{action}`)
13. **Dead letter queues**: Log tenant context when events fail for debugging

### API Layer
14. **Middleware validates tenant access** on every request — no lazy loading of tenant context
15. **Error responses**: Never include cross-tenant data in error messages
16. **Admin endpoints**: Cross-tenant queries only via explicitly authorized admin roles
17. **Rate limiting**: Apply per-tenant limits, not global limits

### SignalR / Real-Time
18. **Hub groups MUST be tenant-scoped**: `tenant-{tenantId}` group naming
19. **Broadcast scope**: Never broadcast to all connections — always to tenant group
20. **Connection tracking**: Log tenant context with connection ID for debugging

## Known Exception Pattern

For reference tables that are genuinely global (no tenant_id column):
```sql
-- Users exist globally, associated to tenants via junction table
SELECT u.* FROM users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.tenant_id = @TenantId
```
Document all reference tables in your Project Principles.
