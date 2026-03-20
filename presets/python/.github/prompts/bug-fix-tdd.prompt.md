---
description: "Fix a bug using TDD: reproduce with a failing test first, then implement the fix, then verify."
agent: "agent"
tools: [read, edit, search, execute]
---
# Fix Bug with TDD

Follow the Red-Green-Refactor cycle to fix a bug with a regression test.

## Process

### Step 1: Understand the Bug
- Read the relevant source files
- Identify the root cause
- Determine which layer the bug is in (Router / Service / Repository)

### Step 2: RED — Write Failing Test
```python
@pytest.mark.asyncio
async def test_calculate_discount_rejects_negative_price(service):
    """Regression test for bug #123 — negative prices caused overflow."""
    with pytest.raises(ValidationError, match="price must be positive"):
        await service.calculate_discount(price=-10, percent=20)
```
- Run: `pytest tests/test_{module}.py -k "test_name"` — it MUST fail

### Step 3: GREEN — Implement the Fix
- Write the minimal code to make the test pass
- Fix should be in the correct architectural layer

### Step 4: REFACTOR — Clean Up
- Clean up the fix if needed
- Verify all existing tests pass: `pytest`

### Step 5: Verify
- Run the full test suite: `pytest --tb=short`
- Confirm no regressions

## Architecture Rules

- NO business logic in routes — fix in the service layer
- NO direct DB access in services — fix in the repository layer
- ALL SQL must use parameterized queries

## Reference Files

- [Testing instructions](../instructions/testing.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
