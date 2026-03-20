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
- Determine which layer the bug is in (Route / Service / Repository)

### Step 2: RED — Write Failing Test
- Create a test that reproduces the exact bug scenario
- Run the test — it MUST fail (proving the bug exists)
- Use descriptive name: `it('should {expected} when {condition}')`

```typescript
it('should throw ValidationError when price is negative', async () => {
  await expect(service.create({ name: 'Test', price: -1 }))
    .rejects.toThrow(ValidationError);
});
```

### Step 3: GREEN — Implement the Fix
- Write the minimal code to make the test pass
- Fix should be in the correct architectural layer
- Use proper error handling (no empty catch blocks)

### Step 4: REFACTOR — Clean Up
- Clean up the fix if needed
- Verify all existing tests still pass: `npm test`

### Step 5: Verify
- Run the full test suite to check for regressions
- Confirm the original bug scenario is resolved

## Architecture Rules

- NO business logic in routes — fix in the service layer
- NO direct DB access in services — fix in the repository layer
- ALL errors must be typed (`NotFoundError`, `ValidationError`)

## Reference Files

- [Testing instructions](../instructions/testing.instructions.md)
- [Error handling](../instructions/errorhandling.instructions.md)
