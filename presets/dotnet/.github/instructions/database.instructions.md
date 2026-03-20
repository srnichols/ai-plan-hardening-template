---
description: Database patterns for .NET — Dapper/EF Core, parameterized queries, migration strategy
applyTo: '**/*Repository*.cs,**/*Migration*.cs,**/Database/**,**/*.sql'
---

# .NET Database Patterns

## ORM Strategy

<!-- Choose one and delete the other -->

### Option A: Dapper (Micro-ORM)
```csharp
// Always use parameterized queries
const string sql = "SELECT * FROM users WHERE email = @Email";
var user = await connection.QuerySingleOrDefaultAsync<User>(sql, new { Email = email });
```

### Option B: Entity Framework Core
```csharp
var user = await _context.Users
    .Where(u => u.Email == email)
    .FirstOrDefaultAsync(cancellationToken);
```

## Non-Negotiable Rules

### Parameterized Queries (SQL Injection Prevention)
```csharp
// ❌ NEVER: String interpolation in SQL
var sql = $"SELECT * FROM users WHERE id = '{userId}'";

// ✅ ALWAYS: Parameters
const string sql = "SELECT * FROM users WHERE id = @UserId";
await connection.QueryAsync<User>(sql, new { UserId = userId });
```

### Connection Management
```csharp
// ❌ NEVER: Manual connection creation
using var conn = new NpgsqlConnection(connectionString);

// ✅ ALWAYS: Use DI / connection factory
using var conn = await _connectionFactory.CreateConnectionAsync(cancellationToken);
```

### Async with CancellationToken
```csharp
// ❌ NEVER: Sync database calls
var result = connection.Query<User>(sql);

// ✅ ALWAYS: Async with cancellation
var result = await connection.QueryAsync<User>(sql, cancellationToken: cancellationToken);
```

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Database columns | snake_case | `user_name`, `created_at` |
| C# properties | PascalCase | `UserName`, `CreatedAt` |
| SQL aliases (Dapper) | PascalCase | `SELECT user_name AS UserName` |
