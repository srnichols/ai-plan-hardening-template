# Agents & Automation Architecture

> **Project**: <YOUR PROJECT NAME>  
> **Stack**: Go  
> **Last Updated**: <DATE>

---

## AI Agent Development Standards

**BEFORE writing ANY agent code, read:** `.github/instructions/architecture-principles.instructions.md`

### Priority
1. **Architecture-First** — Follow proper layering (no business logic in workers)
2. **TDD for Business Logic** — Red-Green-Refactor
3. **Error Handling** — Always handle errors; no `_` for error returns
4. **Context Propagation** — Pass `context.Context` for cancellation and deadlines

---

## Background Worker Pattern

### Template: Goroutine with Ticker

```go
type Worker struct {
    logger  *slog.Logger
    service MyService
}

func (w *Worker) Run(ctx context.Context) error {
    ticker := time.NewTicker(5 * time.Minute)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            w.logger.Info("worker shutting down")
            return ctx.Err()
        case <-ticker.C:
            if err := w.service.ProcessPending(ctx); err != nil {
                w.logger.Error("worker iteration failed", "error", err)
            }
        }
    }
}
```

### Template: Channel Consumer

```go
func (w *Worker) Consume(ctx context.Context, events <-chan Event) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case event, ok := <-events:
            if !ok {
                return nil // channel closed
            }
            if err := w.processEvent(ctx, event); err != nil {
                w.logger.Error("failed to process event",
                    "event_id", event.ID, "error", err)
            }
        }
    }
}
```

---

## Agent Categories

| Category | Purpose | Pattern |
|----------|---------|---------|
| **Ticker Workers** | Periodic processing | Goroutine + `time.Ticker` |
| **Channel Consumers** | Event/message processing | Goroutine + `<-chan` |
| **HTTP Workers** | Webhook/callback handling | `http.Handler` |
| **Health Monitors** | System health checks | `/health` + `/ready` endpoints |

---

## Communication Patterns

### Channel-Based (In-Process)
```
Producer goroutine → channel → Consumer goroutine
```

### Message Queue (NATS / RabbitMQ / Kafka)
```
Publisher → Broker → Subscriber goroutine
```

### Request/Response (HTTP)
```
Handler → Service → Repository → Database
```

---

## Structured Concurrency (errgroup)

```go
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error { return worker1.Run(ctx) })
g.Go(func() error { return worker2.Run(ctx) })
g.Go(func() error { return httpServer.Serve(ctx) })

if err := g.Wait(); err != nil {
    log.Fatal("service stopped", "error", err)
}
```

---

## Quick Commands

```bash
# Run the server
go run ./cmd/server/

# Run specific worker tests
go test -run TestWorker ./internal/worker/...

# Build all
go build ./...
```
