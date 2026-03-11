# Testing Strategies

Practical testing guidelines to pair with arch-review's quality gates.

## Test Pyramid

Prioritize by speed and reliability:

1. **Unit tests** — Fast, isolated, no I/O. Cover pure logic, transformations, and edge cases. Aim for ≥85% line coverage on business logic.
2. **Integration tests** — Verify component boundaries: database queries, API endpoints, service interactions. Use real dependencies where practical (testcontainers, in-memory DBs).
3. **E2E tests** — Validate critical user flows only. Keep the count low — these are slow and flaky. Reserve for smoke tests and regression guards.

## What to Test

### Always test
- Public API contracts (inputs, outputs, error responses)
- Business logic with branching (calculations, state machines, validation)
- Error handling paths (what happens when the database is down, the API returns 500, the input is malformed)
- Security boundaries (auth checks, tenant isolation, input sanitization)
- Data transformations (serialization, mapping, format conversion)

### Skip testing
- Framework boilerplate (constructors that just assign fields, getter/setter pass-through)
- Third-party library behavior (trust that `express.Router()` works)
- Private implementation details that will change with refactoring
- Generated code (protobuf stubs, ORM migrations, lockfiles)

## Naming and Structure

```
tests/
  unit/           # Mirror src/ structure
  integration/    # By feature or boundary
  e2e/            # By user flow
  fixtures/       # Shared test data
```

Test names should read as sentences:
- `it("returns 401 when API key is missing")`
- `test_empty_cart_returns_zero_total`
- Not: `test1`, `testFoo`, `it("works")`

## Assertion Patterns

- **One logical assertion per test.** Multiple `expect()` calls are fine if they assert the same behavior (e.g., checking both status code and body).
- **Assert on behavior, not implementation.** Check what the function returns or what side effect occurred, not which internal methods were called.
- **Use precise matchers.** `toEqual` over `toBeTruthy`, `assert x == 5` over `assert x`.

## Test Data

- Use factories or builders for complex objects — avoid copy-pasting fixture blobs
- Keep test data minimal: only include fields relevant to the test case
- Name test data after what it represents: `expiredToken`, `adminUser`, `emptyCart`
- Never use production data or real credentials in tests

## Mocking Guidelines

- **Mock at boundaries**, not internals: HTTP clients, databases, clocks, random generators
- **Prefer fakes over mocks** when the boundary is simple (in-memory store vs. mock with 12 `.expects()`)
- **Never mock what you don't own** without an integration test backing it up
- **Reset mocks between tests** — shared mock state is the #1 source of flaky tests

## Edge Cases to Cover

Every function with inputs should have tests for:
- Empty/zero/null values
- Boundary values (0, -1, MAX_INT, empty string, single character)
- Invalid types (if the language allows it)
- Concurrent access (if applicable)

## CI Integration

- Tests must pass before merge — no exceptions, no "skip in CI" annotations without an expiration date
- Fail fast: run unit tests first, integration second, E2E last
- Set a coverage floor (e.g., 85%) that blocks PRs — but don't chase 100%
- Flaky tests get quarantined immediately, not retried indefinitely

## Framework-Specific Notes

### JavaScript/TypeScript
- Prefer `vitest` or `jest` for unit/integration. `playwright` for E2E.
- Use `msw` (Mock Service Worker) for HTTP mocking — intercepts at the network level, not the import level.

### Python
- Prefer `pytest` with `pytest-cov`. Use `httpx` or `responses` for HTTP mocking.
- Use `conftest.py` fixtures over setUp/tearDown.

### Arduino/PlatformIO
- Use `unity` test framework for unit tests on native platform
- Test hardware-dependent logic behind interfaces that can be faked in native builds
