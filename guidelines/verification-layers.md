# Verification Layers

A green test suite proves the code is right. It does not prove the system does the thing.
These are the layers between "tests pass" and "the user gets the correct answer", and the
ways each one fails silently.

Companion to [testing.md](testing.md) (how to write the tests) and
[ci-local-parity.md](ci-local-parity.md) (running CI's commands locally).

## 1. Code → image → deploy artefact → running system

**A fix can be correct, fully tested, green in CI, and never reach the running system.**

Learned expensively, 2026-08-26. A per-client config fix had ~40 dedicated tests and had
never taken effect anywhere. `config/` was missing from **both**:

- the `Dockerfile`'s `COPY` lines, and
- the deploy script's **tarball allow-list** (`tar czf ... src/ prompts/ customers/`)

Production therefore had no config directory. The loader returned `None` — not an error, just
a quieter answer — and fell back to a default that produced the exact wrong number the client
had complained about, for a week after they were told it was fixed. Three layers, each
individually green.

Fixing only the Dockerfile would have been worse than useless: `COPY` of a missing directory
**fails the build on the box**.

### Rules

- When a change adds a file the code reads **at runtime**, check three places: the code, the
  image, and the deploy artefact. Any allow-list is a place a file can be forgotten.
- **Lint the allow-lists against each other.** A test that reads the Dockerfile and the deploy
  script and asserts every runtime directory appears in both is cheap and catches this class
  permanently.
- **Verify in the running container, not the repo.** `docker exec … ls /app/config` is the
  only assertion that means anything. Same for prod: query the deployed thing.
- **A deploy that cannot ship what it was asked to ship must fail.** The same script ended its
  `tar` in `2>/dev/null || true`, so a missing path produced a short tarball and a deploy that
  looked like it worked.
- Prefer a config *absence* that is loud. A silent fallback to a default is how this hid.

## 2. Checks that cannot fail

A check that cannot fail is not a check that passes. Recurring shapes:

- **Skip-as-pass.** A guarded test on an unavailable dependency reports "skipped" and the
  suite reports success. Live-integration tests skipped for months on a VM memory cap; a
  never-executed test contained an assertion that could never have passed.
- **Assertions on ambient state.** "The over-budget banner is hidden" only tests anything if
  the test *establishes* that spend is under budget. Otherwise it asserts about whatever the
  previous test left behind.
- **Empty error messages.** Several `httpx` exceptions stringify to `""`, so
  `f"request failed: {exc}"` logs `request failed:` and nothing else. Eighteen simultaneous
  failures told us only the word "failed". Always include the exception **type**.
- **Vacuous iteration.** A test that loops over a discovered set passes trivially when the set
  is empty. Assert the set's size first.
- **Absent-string assertions.** "The output does not contain X" passes when the fixture no
  longer produces anything resembling X. Pin a fixture that *would* fail.

## 3. Detectors and guardrails: fixtures must be real output

If you write a check that refuses output, **every fixture should be a verbatim string from a
real run.** Checks written against imagined text are over-broad in ways you cannot predict.

Four detectors in one project were each caught only by a real generation. The worst refused
the exact behaviour the prompt had asked for — the model declined an invalid comparison *and
explained why*, and the guard flagged the explanation.

- **A gate that refuses correct output is worse than the defect it guards.** It blocks the
  deliverable and teaches everyone to bypass the gate, after which it catches nothing.
- **Measure both directions after every change**: findings on known-good output *and* on
  known-bad. Target zero on good, unchanged on bad. Write both numbers into the commit.
- **Similarity/distance heuristics rarely separate signal from noise.** "A wrong figure sits
  closer to the right one than unrelated data does" failed outright — legitimate values sat
  nearer than real violations, because the comparison pool was dense.
- **Ship an uncertain detector as advisory, not blocking** — out of the enforced set, with a
  test asserting that, so promoting it is a decision rather than a tidied import.
- Say plainly in the tests what the check does **not** catch. Implying coverage you lack is
  the expensive part.

## 4. Suite self-consistency

- **Anything that mutates shared state must restore it.** A suite that set global budget
  limits through the UI and never restored them broke a later test *in the same file*.
- **Ordering dependence is a defect, not a quirk.** Nine tests failed because an earlier one
  reset a budget; all nine passed in isolation in 19 seconds versus 15 minutes in the full
  run. Fix it at the level that owns the state (one setup establishes the run's baseline),
  not per-test.
- **Re-run failures in isolation before diagnosing.** Contention and shared state are the
  usual causes.
- **Inner timeout < outer timeout, always.** An HTTP call given 300s inside a test given 30s
  is killed mid-flight and reports the wrong cause. Likewise a token budget the socket
  timeout cannot outlive.
- **Never let a test suite reach a production host by default.** Any deployed target must be
  named explicitly and fail closed; a default value is the whole risk.

## 5. `$HOME` is not where you think (profile-based setups)

On a machine using Claude Code profiles, **`$HOME` is profile-scoped** — e.g.
`/Users/<you>/.claude-profiles/<profile>` rather than `/Users/<you>`. Two consequences, both
of which silently broke a startup check on 2026-08-26:

- **`$HOME/.claude` is a different real directory from the dot-repo.** Not a symlink to it —
  a separate directory whose subdirectories are mostly symlinked *into* the real one. So it
  looks right, contains the right files, and is **not a git repository**. A sync check probing
  it concludes there is no dot-repo and skips. The session then edited global config for hours
  believing it was unversioned.
- **`~/.ssh` resolves under the profile**, so git-over-ssh fails with
  `no such identity: <profile>/.ssh/id_rsa`. Set `HOME=/Users/$(id -un)` for git operations
  that need ssh.

**Rules**

- Resolve dot-repos by looking for `.git`, across candidates — a known workspace symlink
  (`/Volumes/workspace/dot-claude`), `readlink -f "$HOME/.claude"`, `/Users/$(id -un)/.claude`
  — rather than trusting `$HOME`.
- Never write a path check as "does `$HOME/x` exist"; check what you actually need (here: a
  `.git`).
- The same trap applies to any `~`-relative assumption: `~/.aws`, `~/.ssh`, `~/.config`.

## 6. Non-deterministic tiers

Tests that assert single-sample LLM (or any stochastic) behaviour cannot give a stable
pass/fail.

- Treat them as **advisory**: run them, read them, do not gate on them.
- Assert **causal attribution and structure**, not substring presence. "Does the response
  contain the prior text's first 200 characters" flagged a legitimately similar fresh
  generation; "does it contain the prior text *entirely*" tests the actual contract.
- If a tier keeps failing on a different case each run while wall time grows, you are
  measuring contention, not correctness. Say so and stop tuning.

## Checklist before claiming a fix is live

- [ ] Tests green — and at least one of them could have failed
- [ ] The new/changed runtime file is in the image
- [ ] It is in the deploy artefact / allow-list
- [ ] Verified by querying the **running** system, not the repo
- [ ] The end-user-visible value is correct (read the actual output, not a status field)
- [ ] Rollback path exists and was captured *before* deploying
- [ ] Any `~`/`$HOME` path in the check resolves where you think (see §5)
