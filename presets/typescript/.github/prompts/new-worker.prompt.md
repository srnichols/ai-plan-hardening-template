---
description: "Scaffold a background worker using BullMQ, node-cron, or a simple interval loop with graceful shutdown."
agent: "agent"
tools: [read, edit, search]
---
# Create New Background Worker

Scaffold a background job or worker process.

## BullMQ Worker Pattern (Recommended)

```typescript
import { Worker, Queue, Job } from 'bullmq';
import { Logger } from 'pino';

const QUEUE_NAME = '{entity-name}-processing';

// Producer — enqueue jobs
export const {entityName}Queue = new Queue(QUEUE_NAME, { connection: redisConfig });

// Worker — process jobs
export function create{EntityName}Worker(logger: Logger): Worker {
  return new Worker(
    QUEUE_NAME,
    async (job: Job<{EntityName}JobData>) => {
      logger.info({ jobId: job.id, data: job.data }, 'Processing {entityName} job');

      try {
        // Business logic here
        await process{EntityName}(job.data);
      } catch (err) {
        logger.error({ err, jobId: job.id }, '{EntityName} job failed');
        throw err; // BullMQ will retry based on config
      }
    },
    {
      connection: redisConfig,
      concurrency: 5,
      limiter: { max: 100, duration: 60_000 },
    }
  );
}
```

## Simple Interval Worker

```typescript
export class {EntityName}Worker {
  private running = false;
  private intervalMs: number;

  constructor(
    private readonly service: {EntityName}Service,
    private readonly logger: Logger,
    intervalMs = 60_000
  ) {
    this.intervalMs = intervalMs;
  }

  async start(): Promise<void> {
    this.running = true;
    this.logger.info({ interval: this.intervalMs }, '{EntityName}Worker started');

    while (this.running) {
      try {
        await this.service.process();
      } catch (err) {
        this.logger.error({ err }, '{EntityName}Worker iteration failed');
        // Don't rethrow — keep the worker alive
      }
      await new Promise((resolve) => setTimeout(resolve, this.intervalMs));
    }
  }

  stop(): void {
    this.running = false;
    this.logger.info('{EntityName}Worker stopping');
  }
}
```

## Graceful Shutdown

```typescript
const worker = create{EntityName}Worker(logger);

process.on('SIGTERM', async () => {
  logger.info('SIGTERM received — closing worker');
  await worker.close();
  process.exit(0);
});
```

## Rules

- Workers must handle errors without crashing the process
- Use structured logging with context objects
- Implement graceful shutdown (`SIGTERM` / `SIGINT`)
- Add health check endpoints so orchestrators know the worker is alive
- Use BullMQ for reliable job processing with retry/DLQ

## Reference Files

- [Messaging instructions](../instructions/messaging.instructions.md)
- [Observability instructions](../instructions/observability.instructions.md)
