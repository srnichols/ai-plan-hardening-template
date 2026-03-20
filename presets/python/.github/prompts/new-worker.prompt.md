---
description: "Scaffold a background worker using Celery, asyncio, or a simple loop with graceful shutdown and health checks."
agent: "agent"
tools: [read, edit, search]
---
# Create New Background Worker

Scaffold a background task/worker process.

## Celery Worker Pattern (Recommended)

```python
from celery import Celery
import structlog

app = Celery('{entity_name}_worker', broker='redis://localhost:6379/0')
logger = structlog.get_logger(__name__)

@app.task(bind=True, max_retries=3, default_retry_delay=60)
def process_{entity_name}(self, data: dict):
    """Process {entity_name} job with automatic retry."""
    logger.info("processing_{entity_name}", data=data)
    try:
        # Business logic here
        result = do_work(data)
        return result
    except TransientError as exc:
        logger.warning("{entity_name}_retry", attempt=self.request.retries, error=str(exc))
        raise self.retry(exc=exc)
    except Exception as exc:
        logger.error("{entity_name}_failed", error=str(exc))
        raise

# Scheduled task
app.conf.beat_schedule = {
    '{entity_name}-cleanup': {
        'task': 'workers.{entity_name}.cleanup_{entity_name}s',
        'schedule': 3600.0,  # Every hour
    },
}
```

## Asyncio Worker Pattern

```python
import asyncio
import signal
import structlog

logger = structlog.get_logger(__name__)

class {EntityName}Worker:
    def __init__(self, service: {EntityName}Service, interval_seconds: int = 60):
        self._service = service
        self._interval = interval_seconds
        self._running = True

    async def start(self):
        logger.info("{entity_name}_worker_started", interval=self._interval)

        while self._running:
            try:
                await self._service.process()
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("{entity_name}_worker_iteration_failed", error=str(exc))
                # Don't reraise — keep the worker alive

            await asyncio.sleep(self._interval)

        logger.info("{entity_name}_worker_stopped")

    def stop(self):
        self._running = False

# Graceful shutdown
async def main():
    worker = {EntityName}Worker(service)
    loop = asyncio.get_event_loop()
    loop.add_signal_handler(signal.SIGTERM, worker.stop)
    await worker.start()
```

## Rules

- Workers must handle errors without crashing the process
- Use structlog for structured logging with context
- Implement graceful shutdown (SIGTERM / SIGINT)
- Add health check endpoints for orchestrator monitoring
- Use Celery for reliable job processing with retry/DLQ

## Reference Files

- [Messaging instructions](../instructions/messaging.instructions.md)
- [Observability instructions](../instructions/observability.instructions.md)
