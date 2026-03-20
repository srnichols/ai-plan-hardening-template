# Agents & Automation Architecture

> **Project**: <YOUR PROJECT NAME>  
> **Stack**: Python / FastAPI  
> **Last Updated**: <DATE>

---

## AI Agent Development Standards

**BEFORE writing ANY agent code, read:** `.github/instructions/architecture-principles.instructions.md`

### Priority
1. **Architecture-First** — Follow proper layering (no business logic in workers)
2. **TDD for Business Logic** — Red-Green-Refactor
3. **Typed Error Handling** — No bare except blocks
4. **Type Safety** — No `Any` types without justification

---

## Background Worker Pattern

### Template: Async Worker with Graceful Shutdown

```python
import asyncio
import signal
from contextlib import suppress

class MyWorker:
    def __init__(self, interval_seconds: int = 300):
        self.interval = interval_seconds
        self._running = True

    async def start(self) -> None:
        print("Worker started")
        while self._running:
            try:
                await self.process()
            except Exception:
                print("Worker iteration failed", exc_info=True)
            await asyncio.sleep(self.interval)

    async def process(self) -> None:
        """Override with business logic."""
        ...

    def stop(self) -> None:
        self._running = False


async def main() -> None:
    worker = MyWorker()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, worker.stop)

    await worker.start()

if __name__ == "__main__":
    with suppress(KeyboardInterrupt):
        asyncio.run(main())
```

### Template: Celery Task

```python
from celery import Celery

app = Celery("tasks", broker="redis://localhost:6379/0")

@app.task(bind=True, max_retries=3, default_retry_delay=60)
def process_order(self, order_id: str) -> None:
    try:
        order = order_service.process(order_id)
    except TransientError as exc:
        self.retry(exc=exc)
```

---

## Agent Categories

| Category | Purpose | Pattern |
|----------|---------|---------|
| **Background Workers** | Scheduled processing | asyncio tasks / Celery |
| **Event Processors** | Pub/sub handling | Message broker consumers |
| **Scheduled Tasks** | Cron-like jobs | APScheduler / Celery Beat |

---

## Communication Patterns

### Pub/Sub (Event-Driven)
```
User action → Event published → Worker consumes → State updated
```

### Request/Response
```
Client → FastAPI route → Service → Repository → Database
```

---

## Quick Commands

```bash
# Run worker
python -m app.workers.my_worker

# Run Celery worker
celery -A app.tasks worker --loglevel=info

# Run tests
pytest --tb=short

# Type check
mypy .
```
