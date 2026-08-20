---
description: Generate session summaries with effectiveness assessment and cross-linking
argument-hint: [topic]
allowed-tools: Write, Bash, Read, Glob, Grep
---

# Session Logger

Create a comprehensive session summary and save it to the shared cross-tool session logs directory.

## Setup

Create the logs directory if it doesn't exist. Prefer `session-logs/` (shared cross-tool location); fall back to `.claude/session-logs/` if creation fails:

```bash
mkdir -p session-logs 2>/dev/null || mkdir -p .claude/session-logs
```

## Gather Context

Review the conversation history to identify what was accomplished. Also check git status and recent commits for file changes.

Arguments provided: $ARGUMENTS

## Dot-Repo Sync Check (`~/.claude`)

As part of end-of-session hygiene, verify the global Claude Code config at `~/.claude` is in sync with its GitHub origin. This is consistent with `/lets-go`, `/pickup`, and `/handoff`.

```bash
git -C ~/.claude fetch origin
git -C ~/.claude rev-list --count HEAD..origin/main   # behind
git -C ~/.claude rev-list --count origin/main..HEAD   # ahead
git -C ~/.claude status --porcelain
```

Alert the user prominently if out of sync, and note the state in the `## Session Effectiveness` section under `Process friction` if drift is detected:

- **Behind**: "⚠ ~/.claude is {N} commits behind origin — your global config/commands may be stale. Consider `git -C ~/.claude pull`."
- **Ahead**: "~/.claude has {N} unpushed commits — consider pushing to back up your config."
- **Dirty**: "~/.claude has uncommitted changes."

Skip silently if `~/.claude` has no remote or the fetch fails.

## Link to Previous Session

Find the most recent session log in `session-logs/` (then `.claude/session-logs/` as fallback), excluding `mine-report-*` and `handoff-*` files. If found, add to the header:

```markdown
**Previous Session**: [filename](filename) — [one-line summary from that log's Summary section]
```

This creates a browsable chain across sessions. If no previous session log exists, omit this field.

**Do not link a log written earlier the same session** — see "Same-Day Log Check" below. The
chain is meant to step back one *session*, not one invocation.

## Same-Day Log Check (do this before writing anything)

This command does not know whether it has already run this session. Invoked twice in one
day it will happily write a second log, which fragments the record and breaks the
`Previous Session` chain — the newer entry links to one written an hour earlier rather
than to the previous *session*.

Check for an existing log from today first:

```bash
DIR=session-logs; [ -d "$DIR" ] || DIR=.claude/session-logs
ls -t "$DIR"/session-$(date +%F)-*.md 2>/dev/null | head -3
```

- **Nothing today** → normal path, write a new log.
- **A log from today exists** → default to **extending it**, not adding a second file.
  Read it, work out what has happened since it was written (usually by diffing your
  memory of the session against its `## Key Activities`), and add only the delta:
  append to `Key Activities`, add any new `Decisions & Rationale` / `Reusable Insights`,
  and refresh `Session Effectiveness` — especially `Carry-forward items`, which go stale
  fastest. Keep one entry per session.
- **Genuinely a distinct session on the same day** (different project, or a real break with
  unrelated work) → a second file is right. Give it a distinguishing `-topic` suffix so the
  two are told apart at a glance, and link the earlier one as `Previous Session`.

When extending, say so plainly in the response ("the log was already current; added X")
rather than implying a fresh log was generated.

## Generate Session Summary

Save to: `session-logs/session-YYYY-MM-DD-HHMM[-topic].md` (or `.claude/session-logs/` if `session-logs/` is unavailable).

### Required Sections

#### YAML Frontmatter (required for cross-tool compatibility)

```markdown
---
tool: claude-code
timestamp: YYYY-MM-DDTHH:MM:SS-TZ
branch: <current branch from git>
---
```

#### Header

```markdown
# Session Log: [Descriptive Title]

**Date**: YYYY-MM-DD
**Duration**: [Estimated or "continuation session"]
**Topics**: [comma-separated tags]
```

#### Summary
2-3 sentences describing the session's primary accomplishments.

#### Key Activities
Numbered list of major activities with sub-bullets for specifics. Include file paths for files created or modified.

#### Files Modified
Table format: `| File | Change |`

#### Decisions & Rationale
Numbered list of significant decisions with reasoning. Only include decisions that future sessions should know about.

#### Reusable Insights
Bullet list of patterns, lessons, or techniques that apply beyond this specific session.

### Session Effectiveness Assessment

Include a `## Session Effectiveness` section:

- **Goal achieved?** — Yes / Partial / No
- **Blockers encountered** — Obstacles that slowed progress or remain unresolved
- **Process friction** — Points where the workflow felt inefficient
- **Carry-forward items** — Specific tasks for the next session

## Time Tracking (opportunistic)

If the local `b` time tracker is installed, check for an open timer and fold
the session's tracked time into the log. **Skip silently if `b` is absent.**

```bash
B="$(command -v b 2>/dev/null)"
if [ -z "$B" ]; then
  RH="$(dscl . -read "/Users/$(whoami)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  [ -x "$RH/bin/b" ] && B="$RH/bin/b"
fi
[ -n "$B" ] && { "$B" list-open; "$B" yesterday 2>/dev/null; }
```

- **A timer is still open** → remind: "⏱ TR-NNN is still running — `/b stop` to close it." (Don't stop it automatically.)
- Note total tracked time for this session in the `## Session Effectiveness` section when a relevant entry exists.

## Reminder

If `/handoff` hasn't been run yet and 5+ files were changed, remind the user to run it before ending the session.

## Rules

- **One log per session.** If today already has one, extend it — see "Same-Day Log Check"
- Only include sections that have content — do not generate empty sections
- File paths must be relative to the project root
- Keep the summary compact (~150 lines) — an extended log may exceed this; prefer refreshing
  stale content over appending indefinitely
- The effectiveness assessment should be honest — partial completion or blockers are valuable data
