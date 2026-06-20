# Tool Delegation for LLM-Driven Cron Skills

When a recurring autonomous task runs an LLM against a procedure that must
produce numbers (counts, sums, totals, percentages, money), the LLM will
get the numbers wrong at a measurable rate even when explicitly told to
use a tool. The fix is to take the math out of the LLM's hands entirely:
a deterministic CLI helper produces the canonical answer, and the LLM's
job is to paraphrase around it.

This pattern emerged from a single investigation on `openclaw` + Ollama +
`qwen3.6:35b-a3b`. Baseline math-correctness across 20 morning-kata runs:
**15%**. After applying the pattern to two cron skills: **100% on n=6**,
no regression in run latency or output quality.

## When this pattern applies

- The skill is **scheduled and unattended** — no human catches errors
  immediately.
- The skill emits a **number that has to be right** — a count, a sum, a
  total, a percentage, an invoice amount.
- The skill runs against a **local LLM** (Ollama, llama.cpp). Frontier
  hosted models have higher tool-call fidelity but the pattern still
  helps as defense-in-depth.
- The output **flows directly to a user channel** (Slack, email,
  dashboard) without a human review step.

## When it does NOT apply

- Qualitative outputs (ideation, narrative, summaries). No deterministic
  answer to delegate to.
- Interactive sessions where a human reads the output and catches errors.
- Skills where the LLM's job is already pure orchestration of
  deterministic tools (no inline reasoning over numbers).

## The recipe

### 1. Build a deterministic helper script

Reads the source-of-truth datastore, applies the skill's grouping/
filtering/rounding rules, emits a single integer or a single JSON blob
to stdout. Goes in your tools directory next to existing helpers.

Examples from the originating investigation:
- `kata-count`: prints one integer — the canonical item count for the
  morning kata. Reads `queue.db`, applies the bucket-membership rules
  from the skill, prints `13`.
- `retro-stats`: prints a JSON object with per-customer and grand totals
  for the weekly retro. Crucially, totals are **sum-of-raw-then-round**,
  not sum-of-rounded — the latter is a real bug source.

The script must be:
- **Idempotent** — running it twice gives the same answer.
- **Side-effect-free** — read-only.
- **Fast** — under a second; the LLM is going to wait on it.
- **Self-documenting** — top-of-file docstring explains what it computes
  and why, including which failure mode it prevents.

### 2. Wire it into the cron via `payload.message`, not via SKILL.md

This is the part that took the longest to learn. Most cron schedulers
let you append text to a skill's procedure file (SKILL.md / AGENTS.md /
similar) — but in many systems (openclaw with `lightContext: true`
specifically), workspace files are NOT included in the model's system
prompt. The model only sees them if it explicitly reads them. And it
often won't.

The reliable channel is the cron's **trigger message itself** — the user
message that fires the skill. That always reaches the model.

```sh
openclaw cron edit morning-kata --message 'Run the morning-kata skill.
Follow SKILL.md at ~/.openclaw/workspace/skills/morning-kata/SKILL.md
exactly. CRITICAL — for the "Total: N items" line, exec
~/.openclaw/workspace/tools/kata-count and use its single-integer stdout
verbatim. Do NOT count bullets yourself; it reads queue.db and is the
source of truth.'
```

Anatomy of the CRITICAL clause:
- **Imperative trigger word.** `CRITICAL —` or similar. Catches the
  model's attention before tool selection.
- **The exact failure being prevented.** Not "for math operations" but
  "for the Total: N items line." Specific, concrete, falsifiable.
- **The exact tool invocation.** Full absolute path, exact args. No
  ambiguity about which tool or how to call it.
- **An explicit negation of the failure mode.** "Do NOT count bullets
  yourself." Reinforces.
- **A trust signal.** "It reads queue.db and is the source of truth."
  Tells the model the helper is authoritative — its number wins.

### 3. Add a post-hoc validator

Even with the fix, write a validator that re-runs the math on the
delivered output and reports mismatch. Two reasons:

1. **Measurement.** You need a pass-rate signal so you know whether the
   fix is working over time, surviving model updates, surviving prompt
   changes.
2. **Defense in depth.** If the model regresses, the validator catches
   the wrong number BEFORE it stays in front of a human.

The validator reads the delivered text (cron summary, Slack post,
trajectory file — whichever your runtime gives you access to), parses
the structured part, and compares against a fresh computation from the
source-of-truth datastore.

## Lessons from the false starts

These are the high-cost wrong turns from the originating investigation.
Encoding them so the next person doesn't repeat them.

### Don't bundle fixes

When you have multiple plausible interventions (model swap, prompt edit,
tool surface trim, validator), apply ONE, measure, then decide. Bundling
makes the next failure un-diagnosable. The temptation is to pick the
flashiest one (e.g., model swap) first; the right order is highest
leverage × lowest risk first (validator → prompt edit → model swap).
See also `~/.claude/projects/*/memory/feedback_one-change-at-a-time.md`.

### Don't trust direct-test results to predict nested behavior

Models that ace a direct "sum these numbers using `calculator__calculate`"
prompt can still fail to call the tool when the same need is buried at
step 6 of a 12-step procedure. Multi-hop instruction-following degrades
sharply on local models. The deterministic helper sidesteps this entirely
because the cron payload — not the procedure file — does the pointing.

### Don't assume your workspace files reach the model

Many cron systems run skills with a "lightweight" context mode that
strips workspace files from the system prompt. Verify by inspecting the
actual prompt the model received. If a rule lives in a file the model
never sees, the rule does not exist for that runtime path.

### Don't assume a bigger model is a better model

Swapping from a 35B MoE (low math fidelity) to a 32B dense (better
tool-call fidelity in research) produced a regression: the dense model
started spawning subagents for cron skills, the subagent did the work
correctly, but the parent → subagent → cron-delivery chain dropped the
output. The new model improved on the dimension being measured (tool
selection) while regressing on the dimension that matters (delivery).
Always measure end-to-end, not by the metric you're optimizing for.

### Don't fix what isn't measurably broken

After two skills got fixed with this pattern, the third one — kaikaku —
showed no measurable failures across 6 historical runs. Don't apply the
recipe by default. Audit first; intervene only where the failure rate
justifies it. Cargo-culting the pattern is itself a failure mode.

## The minimum viable rollout

For each skill that fits the "applies" criteria above:

1. **Audit recent runs.** Compute the failure rate against a re-derived
   ground truth. Below ~20%? Skip; the fix is more risk than the failure.
2. **Build the helper.** Single file in your tools dir. Top-comment
   names the specific failure mode it prevents.
3. **Edit the cron payload.** Add a CRITICAL clause pointing at the
   helper with full path and explicit negation.
4. **Trigger 5 manual runs.** Validate each. You're looking for ≥80%
   pass rate to declare the fix working.
5. **Wire the validator into a recurring check** (post-cron, daily,
   whatever cadence catches regressions before they pile up).
6. **Wait for the next scheduled run** to confirm the fix survives the
   transition from manual-trigger context to scheduled-trigger context.

Total effort per skill: ~30 min for the helper + 5 min for the cron
edit + 5 min for the validation runs. The validator is a one-time
investment shared across skills.

## What this pattern doesn't fix

- Output truncation by the runtime (some cron systems cap the summary
  field at N chars). The delivered text is still correct; the
  diagnostic preview is what's truncated.
- Stochastic refusal — the LLM occasionally bails with `[Skipped]` or
  `[no scheduled reminders]` before doing any work. That's a separate
  failure mode requiring a different fix (retry policy, prompt
  hardening, or model swap).
- Quality of qualitative output (ideation, narrative). The math
  delegation pattern has nothing to say about whether the kaikaku ideas
  are good.

## See also

- `~/.claude/guidelines/ai-patterns.md` — Alex Ewerlöf's broader AI
  systems-engineering pattern catalog. This file is a specific
  instantiation of his "Composition" + "Validation" patterns for the
  cron-skill use case.
- `~/.claude/projects/*/memory/feedback_one-change-at-a-time.md` —
  measurement discipline that made this investigation tractable.
- `~/.claude/projects/*/memory/project_openclaw-cron-context.md` —
  openclaw-specific finding about lightContext stripping workspace
  files.
