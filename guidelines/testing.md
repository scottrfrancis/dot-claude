# Testing Strategies

Practical testing guidelines to pair with arch-review's quality gates.

## Red-Green-Refactor TDD (REQUIRED — ALWAYS)

**Red-Green-Refactor TDD is mandatory for every code change.** No production code is written without a failing test first. This applies to bug fixes, new features, and refactors alike. There is no "I'll add tests later." Tests come first, always.

The cycle — repeat for every behavior:

1. **🔴 RED** — Write a failing test that expresses the desired behavior. Run it and confirm it fails for the right reason (the behavior is missing, not a typo/compile error). Do NOT write any production code yet.
2. **🟢 GREEN** — Write the minimum production code needed to make the failing test pass. Resist adding logic the current test doesn't require.
3. **🔵 REFACTOR** — With all tests green, clean up the code: remove duplication, improve names, clarify structure. Tests must stay green throughout. Refactor production and test code alike.

### Non-negotiable rules

- **Never** write production code without a corresponding failing test first.
- **Never** write more than one failing test at a time.
- **Never** add production logic beyond what the currently-failing test demands.
- **Always** run the test between RED and GREEN to verify it actually fails (and fails for the right reason).
- **Always** keep the cycle short — minutes, not hours. If a cycle runs long, the increment is too big; split it.
- **No retroactive tests.** Tests added after the production code they exercise do not count as TDD and must be flagged in code review.

### When TDD feels hard

If you are tempted to skip TDD because "this is trivial" or "I already know the answer": write the test anyway. The discipline catches design smells, enforces small increments, and produces the coverage the codebase needs.

If the test is hard to write, that is signal: the design is probably coupled, or the behavior is under-specified. Fix the design before fixing the test.

### Narrow exceptions

These are the only cases where writing code before a test is acceptable:

- **Spikes** — exploratory code in `/tmp` or a scratch branch, explicitly labeled as throwaway. Any production code derived from a spike must be re-built via TDD; the spike itself is discarded.
- **Pure config changes** — no behavior, no tests required (but verify with an integration or smoke test where practical).
- **Generated code** — protobuf stubs, ORM migrations, lockfiles. Trust the generator; test the consumer.

If you think you have another exception, you do not. Write the test.

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
