---
description: Close out a thread — promote what's durable, then confirm it's safe to clear
argument-hint: [topic, if the thread covered more than one]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Memorialize

Close out a line of work so the context can be cleared without losing anything.

This is a different verb from its two neighbours, and the difference is the point:

| Command | Means |
|---|---|
| `/handoff` | "continue this work" — forward-looking, single-use, consumed by `/pickup` |
| `/session-logger` | "what happened" — retrospective narrative of the session |
| **`/memorialize`** | **"this thread is done — keep what's durable, drop the rest"** |

Use it at a context shift: finishing a thread, switching topics, or before compacting or
clearing. It does not replace `/session-logger`; run both when a session ends.

## 1. Separate durable from transient

Review the thread. Sort what was learned into:

- **Durable** — a convention and why it holds, a decision's practical consequence, a
  platform gotcha, where something authoritative lives. Costly to rediscover.
- **Transient** — what was done, in what order, what broke and got fixed. That is
  `/session-logger`'s job; do not duplicate it here.
- **Already captured** — anything the repo answers with `ls`, `grep`, or `git log`. Drop
  it. Per `guidelines/memory.md`, duplicating those creates a copy that drifts, and the
  drifted copy is the one that gets believed.

State the three lists briefly before writing anything.

## 2. Propose memory entries

For each durable fact, draft a line in the `guidelines/memory.md` format: one fact, ending
`[YYYY-MM-DD]` with today's date, provenance after `·` where there is one.

- Target `<project>/.claude/memory/MEMORY.md`, or `memory/MEMORY.md` in this config repo.
- Check each against what MEMORY.md already holds. If a fact is already there, **update its
  date** rather than adding a duplicate. If it contradicts an existing fact, say so and ask
  — do not silently overwrite.
- **Never** write credentials, addresses, personal contact details, or client-identifying
  information. Record a pointer to `kb-mcp` instead. `dot-claude` is public, and a later
  edit does not erase history.

Show the proposed lines and get approval before writing.

## 3. Promote what has hardened

Memory is a staging tier. For each fact, ask whether it belongs higher:

| The fact is… | Promote to |
|---|---|
| a rule that should govern future work | `guidelines/` — propose the file |
| an architectural decision with alternatives considered | `docs/decisions/ADR-NNNN` — offer `/extract-adr` |
| the resolution of two rules contradicting | `logs/rule-conflict-log.md` per `guidelines/rule-conflict-protocol.md` |
| operational truth about a host, service, or the household | the `okf-knowledge` bundle via `kb-mcp` |

Name the candidates; do not promote unprompted. The last row is the one most often skipped —
the central-ops doctrine requires writing back what you learn about the ops state, and a
fact left in MEMORY.md has not been written back.

## 4. Check nothing is left dangling

```bash
~/.claude/bin/conformance.sh --project .
```

Report anything it prints. A conflict still awaiting a decision is the one blocker that
should stop a clear — the thread ended with a question the user never answered.

## 5. Confirm

State plainly: what was written, what was proposed for promotion, and whether it is safe to
clear. If a conflict is undecided, say it is **not** safe to clear and name the `RC###`.

## Rules

- Propose, then write. Every memory change is user-approved.
- Update dates on re-verified facts; do not accumulate near-duplicates.
- Retire a fact that is now false — strike it through under `## Retired` with the date and
  one clause on why — rather than deleting it silently.
- Say nothing about steps that found nothing. A quiet close-out is a good close-out.
