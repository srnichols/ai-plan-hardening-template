---
description: "Scaffold Go test files with table-driven tests, testify assertions, testcontainers, and proper naming."
agent: "agent"
tools: [read, edit, search, execute]
---
# Create New Test

Scaffold test files following Go testing conventions.

## Test Naming Convention

```
Test{Function}_{Condition}
```

Examples:
- `TestCreateProduct_WithEmptyName`
- `TestGetByID_WhenNotFound`
- `TestCalculateTotal_WithDiscount`

## Unit Test Pattern (Table-Driven)

```go
func Test{EntityName}Service_GetByID(t *testing.T) {
    tests := []struct {
        name      string
        id        uuid.UUID
        mockSetup func(*mockRepo)
        want      *model.{EntityName}
        wantErr   error
    }{
        {
            name: "returns entity when found",
            id:   uuid.MustParse("550e8400-e29b-41d4-a716-446655440000"),
            mockSetup: func(m *mockRepo) {
                m.findByIDResult = &model.{EntityName}{ID: uuid.MustParse("550e8400-e29b-41d4-a716-446655440000"), Name: "Test"}
            },
            want: &model.{EntityName}{ID: uuid.MustParse("550e8400-e29b-41d4-a716-446655440000"), Name: "Test"},
        },
        {
            name: "returns error when not found",
            id:   uuid.New(),
            mockSetup: func(m *mockRepo) {
                m.findByIDErr = repository.ErrNotFound
            },
            wantErr: repository.ErrNotFound,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := &mockRepo{}
            tt.mockSetup(repo)
            svc := service.New{EntityName}Service(repo, slog.Default())

            got, err := svc.GetByID(context.Background(), tt.id)

            if tt.wantErr != nil {
                assert.ErrorIs(t, err, tt.wantErr)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want.Name, got.Name)
        })
    }
}
```

## Integration Test Pattern (Testcontainers)

```go
func TestRepository_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    ctx := context.Background()
    postgres, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "postgres:16-alpine",
            ExposedPorts: []string{"5432/tcp"},
            Env:          map[string]string{"POSTGRES_DB": "test", "POSTGRES_PASSWORD": "test"},
            WaitingFor:   wait.ForListeningPort("5432/tcp"),
        },
        Started: true,
    })
    require.NoError(t, err)
    t.Cleanup(func() { _ = postgres.Terminate(ctx) })

    // Connect and run migrations, then test
}
```

## Reference Files

- [Testing instructions](../instructions/testing.instructions.md)
- [Architecture principles](../instructions/architecture-principles.instructions.md)
