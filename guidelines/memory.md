# Memory Convention

Durable, non-obvious context that the repository itself does not already capture. This is
the tier between a session log, which evaporates, and a guideline or ADR, which is
permanent.

`dot-opencode`, `dot-cursor`, `dot-droid` and `dot-copilot` all defer to this convention
rather than restating it. It is authored here.

## Location

- A project's memory lives in `<project>/.claude/memory/MEMORY.md`.
- This config repo's own memory lives in `memory/MEMORY.md`.
- Detail too long for one line goes in a sibling file that MEMORY.md links to.

## What belongs

Record a fact when it is durable, non-obvious, and costly to rediscover: a convention and
the reason for it, a decision's practical consequence, a platform gotcha, a pointer to
where something authoritative lives.

Do **not** record what the repo already captures — code structure, file listings, git
history, anything an `ls` or a `grep` answers. Duplicating those creates a second copy that
drifts, and the drifted copy is what gets believed.

## Format

One fact per line, as a list item, ending with the date it was last **verified** — not the
date it was written:

```
- Session logs go in `session-logs/` at the project root — shared cross-tool location [2026-08-19]
- `git add -u` not `git add .` in autocommit — avoids staging untracked artifacts [2026-03-10 · ADR-0004]
```

- `[YYYY-MM-DD]` is required. An undated fact is treated as unverified and flagged.
- Provenance after `·` is optional: an `ADR-NNNN`, an `RC###`, a file, a session.
- Re-verifying a fact updates its date. Nothing else about the line need change.
- Group facts under `##` headings by subject.

## Secrets and personal data

MUST NOT record credentials, addresses, personal contact details, or client-identifying
information. Record a pointer to where the detail authoritatively lives — the `kb-mcp`
knowledge base, or a gitignored location — and read it from there.

This applies whether or not the repository is currently public. `dot-claude` is public, and
history is not erased by a later edit.

## Decay

A memory that only accretes becomes a memory that lies, and a confidently wrong fact is
worse than a missing one because it gets acted on.

- `bin/conformance.sh` reports facts older than `MEMORY_STALE_DAYS` (default 180) and any
  fact carrying no date. The report surfaces at session start.
- Re-verify a flagged fact and update its date, or retire it.
- Retiring moves the line to a `## Retired` section, struck through, with the date and one
  clause on why. Deleting it outright is also fine; the section exists so that a stale copy
  encountered elsewhere can be recognised as stale rather than believed.

## Promotion

Memory is a staging tier, not a destination. When a fact hardens, move it up and leave a
pointer:

| The fact is… | Promote to |
|---|---|
| a rule that should govern future work | `guidelines/` |
| an architectural decision with alternatives considered | `docs/decisions/ADR-NNNN` |
| the resolution of two rules contradicting | `logs/rule-conflict-log.md` |
| operational truth about a host, service, or the household | the `okf-knowledge` bundle, via `kb-mcp` |

The last row is the one most often skipped. The central-ops doctrine requires writing back
what you learn about the ops state; a fact that stays in MEMORY.md is not written back.
