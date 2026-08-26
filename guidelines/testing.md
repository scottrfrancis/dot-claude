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

## Tests Must Be Able to Fail

A passing test is only meaningful if it could fail when the behavior under test is broken. Common false-greens:

- Auth function returns a hardcoded constant. 12 tests assert on that constant. All pass. Production breaks the moment auth has to actually decide.
- The test mocks the very function it claims to test. The mock returns the expected value. The test passes regardless of the implementation.
- The test asserts on the input it just provided (`expect(result.name).toBe(input.name)`) without checking that any real work happened in between.
- Setup creates the exact state the test asserts on, with no transformation in between.

Tests must encode **why** the behavior matters, not just **what** the function does today. A test that can't fail when business logic changes is wrong.

**The mutation check:** for any non-trivial test, ask: "if I changed the production logic to return the wrong answer, would this test fail?" If you can't name a specific edit that would flip RED, the test is asserting on the wrong thing.

This is also the discipline that protects the RED step. A test that would have passed against an empty function body wasn't a real RED — and the GREEN code that follows isn't anchored to anything.

**A skip is not a pass.** A guarded test on an unavailable dependency reports "skipped" and the suite reports success. Live-integration tests have skipped for months on a VM memory cap, and a never-executed test has contained an assertion that could never have passed. Check *why* anything skips before trusting a green run.

See [verification-layers.md](verification-layers.md) for the layers past the suite — image, deploy artefact, running system — and for detector/guardrail tests, whose fixtures must be verbatim real output.

## A Gate Can Be Wrong (the subject-drift rule)

The section above protects against a test that *cannot fail*. This one protects against a test that **fails for the wrong reason, or passes on the wrong subject** — a more expensive failure, because it looks like diligence.

Every instance has the same shape: **the assertion's subject drifted from the property it names, and nothing checks the proxy still tracks the property.**

| The gate names | The subject actually was |
|---|---|
| "column X does not exist" | that *a prompt says so* — never the table |
| "external access is closed" | a connection the test built, not the one the app builds |
| "the attack did not succeed" | `'--' in string` — which also matches the *defence* |
| "the user can see it" | a DOM node exists (`count() >= 1`) |
| "the model performs" | a model configuration that was never shipped |
| "no login required" | a bare framework app with none of the real middleware |

Four rules, in the order they catch things:

**1. Ground truth, never restatement.** A gate about the data must query the data; a gate about the product must run the product's own path. *If the assertion would still pass with the product replaced by a text file, it is testing prose.* The worst case: a gate that asserts a claim **locks the claim in**. One test demanded that the rules say a real column did not exist — a hypothesis from an issue, written into a gate before anyone queried the table — and that gate is why the falsehood outlived every review of it.

**2. Both directions, always.** We are disciplined about "can this fail?" and undisciplined about "can this *wrongly* fail?" Every gate needs a **must-not-fire corpus**: real, valid outputs it has to accept, taken from actual product output rather than imagined. An adversarial gate once failed a model that had correctly neutralised an injection *and written a comment explaining how* — the comment contained the forbidden token. The attack failed; the gate called it a success.

**3. Verify on the shipped path.** A fix or a check verified in isolation is not verified. One flag was recorded as "verified, ordinary queries unaffected" — true of the queries tested, false of the ones the app actually issues, and following it would have taken the site down. Ask what the check ran *against*, not just what it returned. The full chain — code, image,
deploy artefact, running system — is owned by
[verification-layers.md §1](verification-layers.md); this rule is only the drift it causes.

**4. Hypotheses must declare themselves.** When a gate encodes a theory rather than a measurement, say so in the test and carry the one command that settles it:

```python
# GH #26 THEORY, not measured. Settle with:
#   SELECT COUNT(DISTINCT plan_type) FROM last_12_months
```

Anyone who reads it once runs it. The cheapest of the four, and the one that stops a guess hardening into a fact.

**The short version:** *a gate that has never been shown to wrongly fail is half-tested, and a gate that asserts a document is not a gate.*

### Corollary: prove which system you tested

A suite can be green against the wrong server entirely. Port checks cannot catch this — a colleague's server, or your own from a different worktree, answers identically. Have the system state its own identity (commit, tree, pid) on an unauthenticated endpoint, and have the harness assert it **before the first assertion**. The same endpoint answers "is the fix actually deployed?", which is usually a harder question than it sounds.

## Test Pyramid

Prioritize by speed and reliability:

1. **Unit tests** — Fast, isolated, no I/O. Cover pure logic, transformations, and edge cases. Aim for ≥85% line coverage on business logic.
2. **Integration tests** — Verify component boundaries: database queries, API endpoints, service interactions. Use real dependencies where practical (testcontainers, in-memory DBs).
3. **E2E tests** — Validate critical user flows only. Keep the count low — these are slow and flaky. Reserve for smoke tests and regression guards.
4. **UX tests** — REQUIRED as the final tier. See below. E2E asks "did the system do the right thing?"; UX asks "could the user perceive it?" Those are different questions and the second one is not implied by the first.

## UX Testing Is a Required Final Tier

**Every user-facing feature ships with a test that asserts what the user can actually perceive, driven through the real browser.** This is not optional and it is not covered by the tier above it.

The distinction that makes it necessary: a test can confirm the system behaved correctly and still miss that the user cannot see the result. Presence in the DOM is not visibility. `locator(sel).count()` counts nodes regardless of scroll position, viewport clipping, `overflow: hidden`, zero height, `opacity: 0`, or a covering element — so a count-based assertion **passes against a visibly broken page**.

**This was learned expensively.** A chat tool answered every follow-up question correctly in 10–15s, and the user reported *"the question just disappears but nothing is returned."* The transcript was a fixed-height scroll box that nothing ever scrolled, so answers rendered ~790px below the fold. Every functional test passed. Every count assertion passed. The bug reached the client. **It was catchable — a single Playwright assertion on scroll geometry would have caught it before the deploy**, and it existed for months before anyone looked.

### What a UX test asserts

- **Visibility, not existence** — `getBoundingClientRect()` against the container's rect, or `expect(locator).toBeInViewport()`
- **Nothing stranded** — `scrollHeight - clientHeight - scrollTop ≈ 0` after content that should bring itself into view
- **Reachability** — the control can be tabbed to, is not covered, and is inside the clickable area
- **The real gesture** — press Enter if that's what users press; don't click the button when the keyboard path runs different code
- **Perceptible state change** — after an action, something the user can see is different

### Rules

- **Drive the actual control.** Injecting state or calling the handler directly tests the layer beneath the bug.
- **Assert on geometry and visibility, never on element counts,** whenever the complaint is "nothing happened" or "it disappeared."
- **Test the second interaction, not just the first.** Most UX defects live past turn one — a first action starts from an empty, unscrolled, uncluttered state that the second never sees. If your harness only ever builds the first interaction, it cannot see this class of bug at all.
- **When output size changes materially, re-run the UX tier.** Making a response *complete* can make it tall enough to push the next thing off-screen. A correctness fix can create a UX regression.

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
