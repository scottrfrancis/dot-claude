---
description: Resume work from the most recent handoff prompt
argument-hint: (no arguments needed)
allowed-tools: Read, Bash, Glob, Grep
---

Pick up where the last session left off.

## Step 1: Find the handoff file

Search for the most recent `handoff-*.md` file across all tool locations:

1. Check `session-logs/` (shared cross-tool location)
2. Then `.claude/session-logs/` (Claude Code legacy location)
3. Then `.factory/logs/` (Droid legacy location)
4. Then `~/.claude/session-logs/` (global fallback)

Take the most recently modified file across all locations (must be less than 7 days old).

### Workspace-wide fallback (when launched from home / not in a project)

The cwd-relative paths above only work when you launch from inside the project
repo. Handoffs are actually written into each project's `session-logs/` under
`/Volumes/workspace/<repo>/`. So **also run this scan whenever cwd is not a git
repo, or when steps 1–4 found nothing**:

```bash
find /Volumes/workspace -maxdepth 3 -path '*/session-logs/handoff-*.md' -mtime -7 2>/dev/null \
  -exec stat -f '%Sm %N' -t '%Y-%m-%d %H:%M' {} \; | sort -r | head -8
```

Because multiple projects are usually in flight, **do not blindly grab the newest**:
- If exactly one candidate, use it.
- If several across different repos, **list the top few (repo + timestamp + handoff title) and ask the user which to resume.** Newest ≠ what they want.

If no handoff file is found anywhere, say so and suggest running `/lets-go` instead to set session context.

## Step 2: Read the handoff

Read and display the full contents of the handoff file so it is in active context. If the file has YAML frontmatter with a `tool:` field, note which tool created it (e.g., "Picking up from a Cursor session" or "Last session was in Droid").

## Step 3: Quick git sync

Run the same git checks as `/lets-go` — **both dot-repo and project repo**.

### Dot-Repo Sync Check (`~/.claude`)

```bash
git -C ~/.claude fetch origin
git -C ~/.claude rev-list --count HEAD..origin/main   # behind
git -C ~/.claude rev-list --count origin/main..HEAD   # ahead
git -C ~/.claude status --porcelain
```

Alert the user prominently if out of sync:

- **Behind**: "⚠ ~/.claude is {N} commits behind origin — your global config/commands may be stale. Consider `git -C ~/.claude pull`."
- **Ahead**: "~/.claude has {N} unpushed commits — consider pushing to back up your config."
- **Dirty**: "~/.claude has uncommitted changes."

Skip silently if `~/.claude` has no remote or the fetch fails.

### Project repo

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

- **Handoff loaded**: filename consumed and archived (note source tool if from YAML frontmatter)
- **Current state**: branch, sync status, clean/dirty
- **Resuming**: top suggested follow-up item from the handoff
