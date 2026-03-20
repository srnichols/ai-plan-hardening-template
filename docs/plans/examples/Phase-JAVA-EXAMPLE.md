# Phase 8: Order Processing API — Java Example

> **Status**: 🟡 HARDENED — Ready for execution  
> **Estimated Effort**: 3 days (10 execution slices)  
> **Risk Level**: Medium (database migration + transactional logic)

---

## Overview

Build a RESTful order processing API with Spring Boot. Customers can create orders, view order history, and track order status. Includes idempotent order creation, stock validation, and event publishing for downstream consumers.

---

## Prerequisites

- [ ] Phase 7 complete (product catalog API working)
- [ ] Flyway migrations up to date
- [ ] Testcontainers + MockMvc test infrastructure in place
- [ ] Redis running for caching (Docker Compose)

## Acceptance Criteria

- [ ] Customers can create orders (idempotent via idempotency key)
- [ ] Orders validate product availability before committing
- [ ] Order status transitions: `PENDING` → `CONFIRMED` → `SHIPPED` → `DELIVERED`
- [ ] Order history endpoint with pagination
- [ ] Multi-tenant isolation — customers only see their own tenant's orders
- [ ] 90%+ test coverage on new code

---

## Execution Slices

### Slice 8.1 — Database: Flyway Migration for `orders` and `order_items` Tables
**Build command**: `./gradlew build`  
**Test command**: `./gradlew test --tests "*IntegrationTest*"`

**Tasks**:
1. Create `V008__create_orders_tables.sql` migration
2. Tables: `orders` (id, tenant_id, customer_id, status, total, idempotency_key, created_at) and `order_items` (id, order_id, product_id, quantity, price)
3. Add unique constraint on `(tenant_id, idempotency_key)` for idempotent creation
4. Write integration test: verify tenant isolation with Testcontainers

```sql
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       VARCHAR(50)  NOT NULL,
    customer_id     UUID         NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    total           DECIMAL(12,2) NOT NULL,
    idempotency_key VARCHAR(255),
    created_at      TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT uq_order_idempotency UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX idx_orders_tenant_customer ON orders(tenant_id, customer_id);
```

**Validation Gate**:
```bash
./gradlew build                                          # zero errors
./gradlew test --tests "*IntegrationTest*"               # all pass
grep -rn "DriverManager\|getConnection(" --include="*.java" src/  # zero hits
```

**Stop Condition**: If migration fails or tenant isolation test fails → STOP, do not proceed.

### Slice 8.2 — Repository Layer: `OrderRepository`
**Build command**: `./gradlew build`  
**Test command**: `./gradlew test --tests "*OrderRepository*"`

**Tasks**:
1. Create `Order` entity with JPA annotations (`@Entity`, `@Table`, `@Column`)
2. Create `OrderItem` entity with `@ManyToOne` relationship
3. Create `OrderRepository` extending `JpaRepository`
4. Custom query: `findByTenantIdAndCustomerId` with pagination
5. Unit tests for repository queries using `@DataJpaTest`

### Slice 8.3 — Service Layer: `OrderService`
**Build command**: `./gradlew build`  
**Test command**: `./gradlew test --tests "*OrderService*"`

**Tasks**:
1. Create `OrderService` with constructor injection
2. Business logic: stock validation, total calculation, idempotency check
3. `@Transactional` on write methods only
4. Publish `OrderCreatedEvent` via Spring `ApplicationEventPublisher`
5. Unit tests with Mockito (mocked repository)

```java
@Service
@Transactional(readOnly = true)
public class OrderService {
    private final OrderRepository orderRepository;
    private final ProductService productService;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public OrderDto createOrder(String tenantId, CreateOrderRequest request) {
        // 1. Idempotency check
        // 2. Validate products in stock
        // 3. Calculate total
        // 4. Save order
        // 5. Publish event
    }
}
```

### Slice 8.4 — REST Controller: `OrderController`
**Tasks**:
1. Create `@RestController` with `/api/orders` base path
2. Endpoints: `POST /`, `GET /{id}`, `GET /` (paginated list), `PATCH /{id}/status`
3. Input validation with `@Valid` on request DTOs
4. MockMvc tests for all endpoints

### Slice 8.5 — Order Status State Machine
**Tasks**:
1. Create `OrderStatus` enum with allowed transitions
2. Validate transitions in service layer (e.g., can't go from DELIVERED back to PENDING)
3. Comprehensive table-driven unit tests for all valid/invalid transitions

### Slice 8.6 — Event Listener for Order Notifications
**Tasks**:
1. Create `OrderEventListener` with `@EventListener` + `@Async`
2. Handle `OrderCreatedEvent` — log and notify
3. Unit tests with mocked dependencies

---

## Rollback Plan

1. **Database**: Run `V008__create_orders_tables_ROLLBACK.sql` to drop tables
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
