# Test Sweep Skill

## Trigger
"Run all tests" / "Full test sweep" / "Check test health"

## Steps

### 1. Unit Tests
```bash
./mvnw test
```

### 2. Integration Tests
```bash
./mvnw verify -Pfailsafe
```

### 3. Architecture Tests (if ArchUnit configured)
```bash
./mvnw test -Dtest="*ArchTest"
```

### 4. Coverage
```bash
./mvnw test jacoco:report
# Report at: target/site/jacoco/index.html
```

### 5. Report
```
✅ Unit:        X passed, Y failed, Z skipped
✅ Integration: X passed, Y failed, Z skipped
✅ Arch:        X passed, Y failed, Z skipped
✅ Coverage:    XX%
──────────────────────────────────────────────
Total:          X passed, Y failed, Z skipped
```

## On Failure
- Show failed test names from `target/surefire-reports/`
- Read the failing test source to diagnose
- Suggest fixes (ask before applying)
