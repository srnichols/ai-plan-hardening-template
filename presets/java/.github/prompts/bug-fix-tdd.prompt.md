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
- Determine which layer the bug is in (Controller / Service / Repository)

### Step 2: RED — Write Failing Test
```java
@Test
void calculateDiscount_WhenNegativePrice_ShouldThrowValidationException() {
    // Regression test for bug #123
    assertThatThrownBy(() -> service.calculateDiscount(-10.0, 20))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("price must be positive");
}
```
- Run: `./mvnw test -pl module -Dtest="{TestClass}#test_name"` — it MUST fail

### Step 3: GREEN — Implement the Fix
- Write the minimal code to make the test pass
- Fix should be in the correct architectural layer

### Step 4: REFACTOR — Clean Up
- Clean up the fix if needed
- Verify all existing tests pass: `./mvnw test`

### Step 5: Verify
- Run the full test suite: `./mvnw verify`
- Confirm no regressions

## Architecture Rules

- NO business logic in controllers — fix in the service layer
- NO direct DB access in services — fix in the repository layer
- Use Bean Validation for input constraints
- Use `@Transactional` for data consistency

## Reference Files

- [Testing instructions](../instructions/testing.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
