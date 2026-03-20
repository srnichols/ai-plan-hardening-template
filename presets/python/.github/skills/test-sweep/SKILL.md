# Test Sweep Skill

## Trigger
"Run all tests" / "Full test sweep" / "Check test health"

## Steps

### 1. Unit Tests
```bash
pytest tests/unit/ -v --tb=short
```

### 2. Integration Tests
```bash
pytest tests/integration/ -v --tb=short
```

### 3. E2E Tests (if available)
```bash
pytest tests/e2e/ -v --tb=short
```

### 4. Lint & Type Check
```bash
ruff check src/
mypy src/
```

### 5. Coverage
```bash
pytest --cov=src --cov-report=term-missing
```

### 6. Report
```
✅ Unit:        X passed, Y failed, Z skipped
✅ Integration: X passed, Y failed, Z skipped
✅ E2E:         X passed, Y failed, Z skipped
✅ Lint:        0 errors
✅ Types:       No errors
✅ Coverage:    XX%
──────────────────────────────────────────────
Total:          X passed, Y failed, Z skipped
```

## On Failure
- Show failed test names and error messages
- Read the failing test source to diagnose
- Suggest fixes (ask before applying)
