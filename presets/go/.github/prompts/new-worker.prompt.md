---
description: "Scaffold a background worker using goroutines, errgroup, graceful shutdown, and health checks."
agent: "agent"
tools: [read, edit, search]
---
# Create New Background Worker

Scaffold a background worker following Go concurrency patterns.

## Required Pattern

```go
package worker

import (
    "context"
    "log/slog"
    "time"

    "github.com/contoso/app/internal/service"
)

type {EntityName}Worker struct {
    service  *service.{EntityName}Service
    log      *slog.Logger
    interval time.Duration
}

func New{EntityName}Worker(svc *service.{EntityName}Service, log *slog.Logger, interval time.Duration) *{EntityName}Worker {
    return &{EntityName}Worker{service: svc, log: log, interval: interval}
}

func (w *{EntityName}Worker) Run(ctx context.Context) error {
    w.log.Info("{entityName} worker started", "interval", w.interval)
    ticker := time.NewTicker(w.interval)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            w.log.Info("{entityName} worker stopping")
            return ctx.Err()
        case <-ticker.C:
            if err := w.process(ctx); err != nil {
                w.log.Error("{entityName} worker iteration failed", "error", err)
                // Don't return — keep the worker alive
            }
        }
    }
}

func (w *{EntityName}Worker) process(ctx context.Context) error {
    return w.service.ProcessAll(ctx)
}
```

## Starting with errgroup

```go
func main() {
    g, ctx := errgroup.WithContext(context.Background())

    // HTTP server
    g.Go(func() error { return server.ListenAndServe() })

    // Background worker
    g.Go(func() error { return worker.Run(ctx) })

    // Graceful shutdown
    g.Go(func() error {
        <-ctx.Done()
        return server.Shutdown(context.Background())
    })

    if err := g.Wait(); err != nil {
        slog.Error("exit", "error", err)
    }
}
```

## Health Check

```go
func (w *{EntityName}Worker) Health() bool {
    w.mu.RLock()
    defer w.mu.RUnlock()
    return time.Since(w.lastRun) < w.interval*3
}
```

## Rules

- Use `context.Context` for cancellation and graceful shutdown
- Use `time.Ticker` (not `time.Sleep`) for interval-based work
- Never let panics or errors kill the worker — recover and log
- Use `errgroup` to coordinate multiple goroutines
- Add health check methods so HTTP handlers can report worker status

## Reference Files

- [Messaging instructions](../instructions/messaging.instructions.md)
- [Observability instructions](../instructions/observability.instructions.md)
