---
description: Resume work from the most recent handoff prompt
argument-hint: (no arguments needed)
allowed-tools: Read, Bash, Glob, Grep
---

Pick up where the last session left off.

## Step 1: Find the handoff file

Search for the most recent `handoff-*.md` modified within the last 7 days.
Check project-local `.claude/session-logs/` first, then `~/.claude/session-logs/`.
Use the same priority order as the SessionStart hook.

```bash
# Project-local first
find "$(pwd)/.claude/session-logs" -maxdepth 1 -name "handoff-*.md" -type f -mtime -7 2>/dev/null | sort -r | head -1

# Fallback: global
find "$HOME/.claude/session-logs" -maxdepth 1 -name "handoff-*.md" -type f -mtime -7 2>/dev/null | sort -r | head -1
```

If no handoff file is found, say so and suggest running `/lets-go` instead to set session context.

## Step 2: Read the handoff

Read and display the full contents of the handoff file so it is in active context.

## Step 3: Quick git sync

Run the same git checks as `/lets-go`:

1. `git fetch origin` (silent)
2. Report current branch and upstream state:
   - Behind: `git rev-list --count HEAD..origin/{branch}`
   - Ahead: `git rev-list --count origin/{branch}..HEAD`
3. Check for uncommitted changes (`git status --porcelain`)

Report clearly: branch name, sync state, dirty/clean.

## Step 4: Archive the handoff

Move the file to the `archive/` subdirectory in the same parent directory so the
SessionStart hook does not re-inject it on the next true session launch.

```bash
HANDOFF_FILE="<path from step 1>"
ARCHIVE_DIR="$(dirname "$HANDOFF_FILE")/archive"
mkdir -p "$ARCHIVE_DIR"
mv "$HANDOFF_FILE" "$ARCHIVE_DIR/"
```

## Step 5: Confirm readiness

Output a brief "ready to continue" summary with these sections:

- **Handoff loaded**: filename consumed and archived
- **Current state**: branch, sync status, clean/dirty
- **Resuming**: top suggested follow-up item from the handoff
