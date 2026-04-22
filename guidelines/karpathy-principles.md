# Karpathy Principles — Deltas

Andrej Karpathy's [viral observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls were distilled by [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) into four principles: *Think Before Coding*, *Simplicity First*, *Surgical Changes*, *Goal-Driven Execution*.

Two of those four are already enforced by the Claude Code system prompt (simplicity, don't-over-abstract, no speculative error handling) and by `testing.md` (RED-GREEN-REFACTOR as mandatory, stronger than Karpathy's "consider tests-first"). This file captures only the **deltas** — the rules not already covered.

## Delta 1: Surface Assumptions Before Implementing

Karpathy's core insight: *LLMs pick an interpretation silently and run with it.* The existing system prompt covers this for exploratory questions ("2-3 sentences + tradeoff") but not for implementation tasks.

Before writing code for a non-trivial task:

- **State assumptions explicitly.** If the request has more than one reasonable interpretation, name them and pick one with a reason — or ask.
- **If the request implies scope, call it out.** "Export users" → all users or a subset? File or API? Which fields? Ask before coding, not after.
- **If a simpler path exists, say so.** Don't silently follow the user's suggestion if it's overkill — present the simpler option and let the user redirect.
- **If confused, stop.** Name what's unclear. "I'm unsure whether X means Y or Z" beats guessing.

**The test:** Could another engineer read the request and build something materially different? If yes, surface the fork before committing to one branch.

## Delta 2: Match Existing Style; Mention Don't Delete

Karpathy: *"Match existing style, even if you'd do it differently. If you notice unrelated dead code, mention it — don't delete it."*

The system prompt says "delete unused code completely" — this applies to **orphans your changes create**, not pre-existing code. Reconciling:

- **Orphans from your changes:** delete them. Unused imports, variables, functions made dead by your edit are yours to clean up.
- **Pre-existing dead code:** mention it in your summary, don't delete it silently. The user may know something you don't (planned use, historical context, external callers).
- **Style drift:** if the file uses single quotes / no type hints / snake_case, keep it. Don't "improve" on the way through. One-off style choices inside your own new code are fine; reformatting surrounding code is not.
- **Comment/whitespace edits:** only if directly needed for your change. Touching every line you read expands the diff and hides the actual change.

**The test:** Every line in your diff should trace to the stated task. A reviewer asking "why did this line change?" for any hunk should get an answer tied directly to the request.

## See Also

- `testing.md` — Goal-Driven Execution is covered here as mandatory RED-GREEN-REFACTOR, stronger than Karpathy's version.
- `prototype-hygiene.md` — Simplicity First in practice: config over code, no stale state in docs, PRs over branches.
- System prompt (unchangeable) already enforces: no speculative features, no abstractions for single-use code, no error handling for impossible scenarios, no comments for the obvious.
