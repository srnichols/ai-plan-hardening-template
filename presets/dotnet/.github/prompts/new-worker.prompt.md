---
description: "Scaffold a background worker using BackgroundService with PeriodicTimer, structured logging, graceful shutdown, and health checks."
agent: "agent"
tools: [read, edit, search]
---
# Create New Background Worker

Scaffold a hosted background service following .NET patterns.

## Required Pattern

```csharp
public sealed partial class {Name}Worker(
    IServiceScopeFactory scopeFactory,
    ILogger<{Name}Worker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    [LoggerMessage(Level = LogLevel.Information, Message = "{Name}Worker started — interval {Interval}")]
    partial void LogStarted(TimeSpan interval);

    [LoggerMessage(Level = LogLevel.Error, Message = "{Name}Worker iteration failed")]
    partial void LogIterationFailed(Exception ex);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        LogStarted(Interval);
        using var timer = new PeriodicTimer(Interval);

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var service = scope.ServiceProvider.GetRequiredService<I{Name}Service>();
                await service.ProcessAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break; // Graceful shutdown
            }
            catch (Exception ex)
            {
                LogIterationFailed(ex);
                // Don't rethrow — keep the worker alive
            }
        }
    }
}
```

## Registration

```csharp
// In Program.cs
builder.Services.AddHostedService<{Name}Worker>();
builder.Services.AddScoped<I{Name}Service, {Name}Service>();
```

## Health Check Integration

```csharp
public class {Name}HealthCheck(/* state */) : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, CancellationToken ct = default)
    {
        var lastRun = /* get last successful run time */;
        var isHealthy = DateTime.UtcNow - lastRun < TimeSpan.FromMinutes(15);
        return Task.FromResult(isHealthy
            ? HealthCheckResult.Healthy($"Last run: {lastRun}")
            : HealthCheckResult.Unhealthy($"Last run: {lastRun}"));
    }
}
```

## Rules

- Use `PeriodicTimer` (not `Task.Delay`) for interval-based work
- Create a new DI scope per iteration (`IServiceScopeFactory`)
- Never let exceptions kill the worker — catch and log
- Respect `CancellationToken` for graceful shutdown
- Add a health check so orchestrators know the worker is alive
- Use source-generated logging for hot-path messages

## Reference Files

- [Messaging instructions](../instructions/messaging.instructions.md)
- [Observability instructions](../instructions/observability.instructions.md)
