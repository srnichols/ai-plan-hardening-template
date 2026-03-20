---
description: "Scaffold a background worker using Spring @Scheduled, @Async, or Spring Batch with health checks and graceful shutdown."
agent: "agent"
tools: [read, edit, search]
---
# Create New Background Worker

Scaffold a scheduled background task following Spring patterns.

## @Scheduled Pattern (Simple)

```java
@Component
@RequiredArgsConstructor
public class {EntityName}Worker {
    private final {EntityName}Service service;
    private static final Logger log = LoggerFactory.getLogger({EntityName}Worker.class);

    @Scheduled(fixedDelayString = "${worker.{entityName}.interval:60000}")
    public void process() {
        log.info("Starting {entityName} processing");
        try {
            service.processAll();
            log.info("Completed {entityName} processing");
        } catch (Exception ex) {
            log.error("Failed {entityName} processing", ex);
            // Don't rethrow — scheduler will retry on next interval
        }
    }
}
```

## @Async Worker Pattern (Concurrent)

```java
@Service
@RequiredArgsConstructor
public class {EntityName}AsyncWorker {
    private final {EntityName}Service service;
    private static final Logger log = LoggerFactory.getLogger({EntityName}AsyncWorker.class);

    @Async("workerExecutor")
    @EventListener(ApplicationReadyEvent.class)
    public void startProcessing() {
        log.info("{EntityName}Worker started");
        while (!Thread.currentThread().isInterrupted()) {
            try {
                service.processNext();
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception ex) {
                log.error("{EntityName}Worker iteration failed", ex);
            }
        }
        log.info("{EntityName}Worker stopped");
    }
}
```

## Health Check

```java
@Component
@RequiredArgsConstructor
public class {EntityName}WorkerHealthIndicator implements HealthIndicator {
    @Override
    public Health health() {
        var lastRun = /* get last successful run */;
        var isHealthy = Duration.between(lastRun, Instant.now()).toMinutes() < 15;
        return isHealthy
            ? Health.up().withDetail("lastRun", lastRun).build()
            : Health.down().withDetail("lastRun", lastRun).build();
    }
}
```

## Configuration

```yaml
# application.yml
worker:
  {entityName}:
    interval: 60000       # 1 minute
    enabled: true
spring:
  task:
    scheduling:
      pool:
        size: 5
```

## Rules

- Workers must catch and log exceptions — never let them crash the scheduler
- Use configurable intervals via properties
- Add health indicators for orchestrator monitoring
- Use `@Scheduled` for simple periodic tasks
- Use `@Async` + custom executor for long-running workers

## Reference Files

- [Messaging instructions](../instructions/messaging.instructions.md)
- [Observability instructions](../instructions/observability.instructions.md)
