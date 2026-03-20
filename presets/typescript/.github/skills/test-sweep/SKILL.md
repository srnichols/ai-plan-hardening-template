# Test Sweep Skill

## Trigger
"Run all tests" / "Full test sweep" / "Check test health"

## Steps

### 1. Unit Tests
```bash
npx vitest run --reporter=verbose
```

### 2. Integration Tests
```bash
npx vitest run --config vitest.integration.config.ts --reporter=verbose
```

### 3. E2E Tests (if available)
```bash
npx playwright test --reporter=list
```

### 4. Lint
```bash
npx eslint src/ --max-warnings=0
npx tsc --noEmit
```

### 5. Report
Aggregate results:
```
✅ Unit:        X passed, Y failed, Z skipped
✅ Integration: X passed, Y failed, Z skipped
✅ E2E:         X passed, Y failed, Z skipped
✅ Lint:        0 errors, 0 warnings
✅ TypeCheck:   No errors
──────────────────────────────────────────────
Total:          X passed, Y failed, Z skipped
```

## On Failure
- Show failed test names and error messages
- Read the failing test source to diagnose
- Suggest fixes (ask before applying)
