# Phase 5: Background Task Queue — Python Example

> **Status**: 🟡 HARDENED — Ready for execution  
> **Estimated Effort**: 2 days (6 execution slices)  
> **Risk Level**: Low-Medium (Celery + database)

---

## Overview

Add a background task queue for asynchronous processing: email sending, report generation, and data import jobs. Uses Celery with Redis as the broker and PostgreSQL for result storage.

---

## Prerequisites

- [ ] Phase 4 complete (core CRUD API working)
- [ ] Redis running (Docker Compose)
- [ ] Alembic migrations up to date
- [ ] Test infrastructure (pytest, httpx) working

## Acceptance Criteria

- [ ] Celery worker processes tasks from Redis queue
- [ ] Three task types: email, report generation, data import
- [ ] Task status tracking (pending, running, completed, failed)
- [ ] API endpoint to submit tasks and check status
- [ ] Retry logic with exponential backoff
- [ ] 90%+ test coverage on new code

---

## Execution Slices

### Slice 5.1 — Database: `tasks` Table + Alembic Migration
**Build command**: `mypy .`  
**Test command**: `pytest --tb=short`

**Tasks**:
1. Create Alembic migration: `alembic revision --autogenerate -m "add_tasks_table"`
2. Model: `id`, `tenant_id`, `type`, `status`, `payload` (JSONB), `result`, `created_at`, `completed_at`
3. Add index on `(tenant_id, status)` for efficient queries
4. Write integration test: verify tenant isolation

```python
class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    tenant_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False)  # "email" | "report" | "import"
    status: Mapped[str] = mapped_column(String(20), default="pending")
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    result: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
```

**Validation Gate**:
```bash
mypy .                                              # zero errors
pytest --tb=short                                   # all pass
grep -rn "type: ignore\|Any" --include="*.py" app/  # minimal in new files
```

**Stop Condition**: If migration fails or tenant isolation test fails → STOP.

### Slice 5.2 — Celery Configuration
**Build command**: `mypy .`  
**Test command**: `pytest tests/test_celery_config.py`

**Tasks**:
1. Create `app/celery_app.py` with Redis broker config
2. Configure task serialization (JSON only — no pickle for security)
3. Set up task routes: `email.*` → `email-queue`, `report.*` → `report-queue`
4. Health check endpoint for Celery worker status
5. Unit test: verify configuration loads correctly

```python
from celery import Celery

celery_app = Celery(
    "tasks",
    broker=settings.redis_url,
    backend=settings.celery_result_backend,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)
```

### Slice 5.3 — Task Service Layer
**Tasks**:
1. Create `TaskService` with typed interface
2. Methods: `submit_task`, `get_status`, `list_tasks`, `cancel_task`
3. All methods require `tenant_id` parameter
4. Pydantic models for task input/output
5. Unit tests with mocked repository

### Slice 5.4 — Celery Task Implementations
**Tasks**:
1. `send_email_task` — Sends email via SMTP/API
2. `generate_report_task` — Creates PDF report
3. `import_data_task` — Processes CSV upload
4. Each task: retry with backoff (3 attempts, 60s delay)
5. Unit tests with mocked external services

```python
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_email_task(self, tenant_id: str, payload: dict) -> dict:
    try:
        result = email_service.send(payload)
        task_service.mark_completed(self.request.id, tenant_id, result)
        return result
    except TransientError as exc:
        self.retry(exc=exc)
    except Exception as exc:
        task_service.mark_failed(self.request.id, tenant_id, str(exc))
        raise
```

### Slice 5.5 — API Endpoints
**Tasks**:
1. `POST /api/tasks` — Submit a new task
2. `GET /api/tasks/{id}` — Get task status
3. `GET /api/tasks` — List tasks (paginated, filtered by tenant)
4. `DELETE /api/tasks/{id}` — Cancel pending task
5. Pydantic validation on all inputs
6. API integration tests

### Slice 5.6 — Worker Health + Monitoring
**Tasks**:
1. Health check: `GET /health/worker` — Celery ping
2. Prometheus metrics: task count, duration, failure rate
3. Structured logging for task lifecycle events
4. Integration test: submit task → verify completion

---

## Rollback Plan

1. **Database**: `alembic downgrade -1` to drop tasks table
2. **Code**: Revert commit (single commit per slice)
3. **Config**: Remove Celery config from `docker-compose.yml`

---

## Anti-Pattern Checks

```bash
# Run after each slice
grep -rn "type: ignore" --include="*.py" app/tasks/    # must be 0
grep -rn "except:" --include="*.py" app/               # must be 0 (no bare except)
grep -rn "pickle" --include="*.py" app/                # must be 0 (security)
grep -rn "Any" --include="*.py" app/tasks/             # must be 0
```

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
