# Phase 12: User Profile & Dashboard — .NET Example

> **Status**: 🟡 HARDENED — Ready for execution  
> **Estimated Effort**: 3 days (12 execution slices)  
> **Risk Level**: Medium (database migration + UI)

---

## Overview

Add user profile management and personalized dashboard to the platform. Users can view and edit their profile, see activity history, and access a personalized dashboard with relevant metrics.

---

## Prerequisites

- [ ] Phase 11 complete (authentication working)
- [ ] Database migrations up to date
- [ ] Integration test infrastructure in place

## Acceptance Criteria

- [ ] Users can view and edit their profile (name, email, avatar)
- [ ] Dashboard shows personalized metrics (last login, activity count)
- [ ] Profile changes are audited in the activity log
- [ ] Multi-tenant isolation — users only see their own tenant's data
- [ ] 90%+ test coverage on new code

---

## Execution Slices

### Slice 12.1 — Database Migration: `user_profiles` Table
**Build command**: `dotnet build`  
**Test command**: `dotnet test --filter "Category=Integration"`

**Tasks**:
1. Create migration `V012__add_user_profiles.sql`
2. Add columns: `display_name`, `avatar_url`, `bio`, `last_login_at`
3. Add RLS policy: `WHERE tenant_id = current_setting('app.tenant_id')`
4. Write integration test: verify RLS blocks cross-tenant access

**Validation Gate**:
```bash
dotnet build                                        # zero errors
dotnet test --filter "Category=Integration"         # all pass
grep -rn "string interpolation" --include="*.cs"    # zero hits in new files
```

**Stop Condition**: If RLS policy fails integration test → STOP, do not proceed.

### Slice 12.2 — Repository Layer: `UserProfileRepository`
**Build command**: `dotnet build`  
**Test command**: `dotnet test --filter "Category=Unit"`

**Tasks**:
1. Create `IUserProfileRepository` interface
2. Implement `UserProfileRepository` (Dapper, parameterized queries)
3. Methods: `GetByUserIdAsync`, `UpdateAsync`, `GetActivitySummaryAsync`
4. Unit tests for all repository methods

**Validation Gate**:
```bash
dotnet build
dotnet test --filter "UserProfile"
```

### Slice 12.3 — Service Layer: `UserProfileService`
**Tasks**:
1. Create `IUserProfileService` interface
2. Implement business logic: validation, avatar URL sanitization
3. Emit `user-profile-updated` event via Dapr pub/sub
4. Unit tests with mocked repository

### Slice 12.4 — GraphQL Types & Resolver
**Tasks**:
1. Add `UserProfileType` in `/GraphQL/Types/`
2. Add `UpdateProfileInput` mutation input  
3. Add resolver with `[Authorize]` and tenant validation
4. Integration test: verify authorization blocks unauthorized access

### Slice 12.5 — Blazor Component: Profile Page
**Tasks**:
1. Create `UserProfile.razor` page
2. Use `PageHeader`, `AdminCard`, `StatCard` components (Phase 4 pattern)
3. Form with validation (display name, bio, avatar upload)
4. Show activity summary in stat cards

### Slice 12.6 — Blazor Component: Dashboard Widgets
**Tasks**:
1. Create `DashboardWidget.razor` reusable component
2. Add personalized widgets: recent activity, quick actions
3. Loading states with `SkeletonLoader`
4. `EmptyState` component for no-data scenarios

---

## Rollback Plan

1. **Database**: Run `V012__add_user_profiles_ROLLBACK.sql` to drop table
2. **Code**: Revert commit (single commit per slice)
3. **Config**: No config changes in this phase

---

## 6 Mandatory Blocks — Verification

| # | Block | Present |
|---|-------|---------|
| 1 | Numbered execution slices with build/test commands | ✅ |
| 2 | Explicit validation gates per slice | ✅ |
| 3 | Stop conditions | ✅ |
| 4 | Rollback plan (3 tiers) | ✅ |
| 5 | Anti-pattern grep commands | ✅ |
| 6 | File-level change manifest | ⬜ (add before execution) |
