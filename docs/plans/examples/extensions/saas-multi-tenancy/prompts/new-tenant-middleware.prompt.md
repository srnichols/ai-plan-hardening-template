---
description: "Scaffold tenant validation middleware with JWT extraction, context injection, and access validation"
mode: agent
---

# Add Tenant Validation Middleware

Create a middleware that extracts tenant context from incoming requests,
validates access, and injects it for downstream layers.

## What to Build

1. **TenantValidationMiddleware** — ASP.NET Core middleware that:
   - Extracts `tenant_id` from JWT claims (primary)
   - Falls back to `X-Tenant-Id` header (for service-to-service calls)
   - Validates the user has access to the requested tenant
   - Sets `HttpContext.Items["TenantId"]` for downstream use
   - Returns 403 if tenant access denied, 400 if tenant_id missing

2. **ITenantService** — Interface for tenant context:
   ```csharp
   public interface ITenantService
   {
       Task<Guid> GetCurrentTenantIdAsync(CancellationToken ct = default);
       Task<bool> ValidateTenantAccessAsync(Guid userId, Guid tenantId, CancellationToken ct = default);
   }
   ```

3. **Registration** — In `Program.cs`:
   ```csharp
   app.UseAuthentication();
   app.UseAuthorization();
   app.UseTenantValidation(); // After auth, before controllers
   ```

## Validation Rules

- Tenant extraction order: JWT claim → Header → 400 Bad Request
- Skip validation for health check endpoints (`/health`, `/ready`)
- Skip validation for public endpoints marked with `[AllowAnonymous]`
- Log tenant context with every request (structured logging)
- Include `tenant_id` in the correlation context for distributed tracing

## Testing

Write integration tests that verify:
- Valid tenant in JWT → 200 OK
- No tenant in JWT → 400 Bad Request
- Wrong tenant (no access) → 403 Forbidden
- Health endpoints bypass tenant check
