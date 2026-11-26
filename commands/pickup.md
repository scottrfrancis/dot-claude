---
description: Resume work from the most recent handoff prompt
argument-hint: [handoff path]
allowed-tools: Read, Bash, Glob, Grep
---

Pick up where an earlier session left off. This command is the only reader of handoffs: the
SessionStart hook points at them and leaves them in place.

## 1. Find the handoff

If $ARGUMENTS names a handoff file, use it. Otherwise run the status probe outside the sandbox
(it fetches):

```bash
S="$HOME/.claude/bin/session-status.sh"; [ -x "$S" ] || S=/Volumes/workspace/dot-claude/bin/session-status.sh
"$S" --fetch
```

Its `handoffs` section lists up to three handoffs from the last 7 days, newest first, dated by
filename. Launched outside a repo, it scans every project in the workspace.

- One handoff: use it.
- Several from different projects: list them (project, timestamp, first heading) and ask which to
  resume. The newest is often not the one wanted.
- None: say so and suggest `/lets-go`.

## 2. Read it

Read the whole file. If its frontmatter has a `tool:` field, say which tool wrote it ("Picking up
from a Cursor session").

## 3. Check state

The probe output above covers drift on dot-claude, the project and its nested repos, and any open
timer. Act on it as `/lets-go` describes. Then run `git status -sb` in the project.

## 4. Archive it

Move the handoff to `archive/` beside it, so the probe stops listing it:

```bash
f="<path from step 1>"; mkdir -p "$(dirname "$f")/archive" && mv "$f" "$(dirname "$f")/archive/"
```

## 5. Confirm

Brief bullets: which handoff was loaded and archived (and its source tool), the current state, and
the top follow-up item from the handoff.
