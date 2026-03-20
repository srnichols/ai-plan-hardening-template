# Agents & Automation Architecture

> **Project**: <YOUR PROJECT NAME>  
> **Stack**: .NET / C# / ASP.NET Core  
> **Last Updated**: <DATE>

---

## AI Agent Development Standards

**BEFORE writing ANY agent code, read:** `.github/instructions/architecture-principles.instructions.md`

### Priority
1. **Architecture-First** — Follow proper layering (no business logic in workers)
2. **TDD for Business Logic** — Red-Green-Refactor
3. **Typed Error Handling** — No empty catch blocks
4. **Async with CancellationToken** — All async methods

---

## Background Worker Pattern

### Template: BackgroundService with PeriodicTimer

```csharp
public class MyWorker(ILogger<MyWorker> logger, IServiceScopeFactory scopeFactory) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(5));

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var service = scope.ServiceProvider.GetRequiredService<IMyService>();
                await service.ProcessAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogError(ex, "Worker iteration failed");
            }
        }
    }
}
```

---

## Agent Categories

| Category | Purpose | Pattern |
|----------|---------|---------|
| **Background Workers** | Scheduled processing | `BackgroundService` + `PeriodicTimer` |
| **Event Processors** | Pub/sub message handling | Dapr / MassTransit / raw message broker |
| **Health Monitors** | System health checks | `IHostedService` + health check endpoints |

---

## Communication Patterns

### Pub/Sub (Event-Driven)
```
User action → Event published → Worker processes → State updated
```

### Request/Response (Direct)
```
API → Service → Repository → Database
```

### Real-Time (SignalR / WebSocket)
```
Server event → Hub → Connected clients
```

---

## Quick Commands

```bash
# Run specific worker
dotnet run --project MyWorker/

# Run tests for workers
dotnet test --filter "Category=Workers"

# Build all
dotnet build
```
