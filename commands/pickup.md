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

Take the newest across all locations, **ordering and judging freshness by the date in the
filename, never by mtime** (must be less than 7 days old by that date).

mtime is a property of the file on this disk, not of the handoff: git rewrites it, so a clone
or checkout stamps every handoff with the same instant and archived ones look brand new.
Observed 2026-08-20 — five Catalyst-RCM handoffs from 2026-07-06..08 all carried a 2026-08-14
mtime, so every one of them passed a "modified in the last 7 days" filter. Ordering by mtime
also put this command at odds with the `load-handoff-context.sh` SessionStart hook, which
orders by name. Both now read the filename.

The scripts use `[[ ]]` and `find` because they run under zsh as well as bash. In zsh `[ "$fd" \< "$CUTOFF" ]` is a syntax error and an unmatched glob is an error, so the old filter let stale handoffs through (observed 2026-11-03).

```bash
CUTOFF=$(date -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F)
for d in session-logs .claude/session-logs .factory/logs "$HOME/.claude/session-logs"; do
  [ -d "$d" ] || continue
  find "$d" -maxdepth 1 -name 'handoff-????-??-??-*.md' 2>/dev/null | sort -r | while IFS= read -r f; do
    fd=$(basename "$f"); fd=${fd#handoff-}; fd=${fd:0:10}
    [[ "$fd" < "$CUTOFF" ]] || echo "$fd  $f"
  done
done | sort -r | head -5
```

### Workspace-wide fallback (when launched from home / not in a project)

The cwd-relative paths above only work when you launch from inside the project
repo. Handoffs are actually written into each project's `session-logs/` under
`/Volumes/workspace/<repo>/`. So **also run this scan whenever cwd is not a git
repo, or when steps 1–4 found nothing**:

```bash
CUTOFF=$(date -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F)
find /Volumes/workspace -maxdepth 3 -path '*/session-logs/handoff-????-??-??-*.md' 2>/dev/null \
  | while IFS= read -r f; do
      fd=$(basename "$f"); fd=${fd#handoff-}; fd=${fd:0:10}
      [[ "$fd" < "$CUTOFF" ]] || echo "$fd  $f"
    done | sort -r | head -8
```

Same rule as above: the date comes from the filename. The previous version of this scan used
`-mtime -7` plus `stat`, which is what surfaced six-week-old Catalyst handoffs as "recent"
during a 2026-08-20 `/lets-go`.

Because multiple projects are usually in flight, **do not blindly grab the newest**:
- If exactly one candidate, use it.
- If several across different repos, **list the top few (repo + timestamp + handoff title) and ask the user which to resume.** Newest ≠ what they want.

If no handoff file is found anywhere, say so and suggest running `/lets-go` instead to set session context.

## Step 2: Read the handoff

Read and display the full contents of the handoff file so it is in active context. If the file has YAML frontmatter with a `tool:` field, note which tool created it (e.g., "Picking up from a Cursor session" or "Last session was in Droid").

## Step 3: Quick git sync

Run the same git checks as `/lets-go` — **both dot-repo and project repo**.

### Dot-Repo Sync Check (dot-claude)

**Do not probe `~/.claude`.** On profile-based setups `$HOME` is the profile, so `~/.claude` is not the dot-repo and git over ssh cannot find its keys. This block is the one in `/lets-go`.

```bash
# 1. Resolve the REAL dot-repo. First candidate containing a .git wins.
DOTC=""
for c in /Volumes/workspace/dot-claude "$(readlink -f "$HOME/.claude" 2>/dev/null)" \
         "/Users/$(id -un)/.claude" "$HOME/.claude"; do
  [ -n "$c" ] && [ -d "$c/.git" ] && DOTC="$c" && break
done
if [ -z "$DOTC" ]; then echo "dot-claude repo not found — skipping"; else

# 2. git over ssh needs the REAL home, or it looks for keys under the profile dir and
#    fails with: no such identity: <profile>/.ssh/id_rsa
REALHOME="/Users/$(id -un)"

# 3. Fetch, and CHECK IT WORKED. Counts after a failed fetch are stale refs.
if HOME="$REALHOME" git -C "$DOTC" fetch origin 2>&1 \
     | grep -qiE "no such identity|could not read|permission denied|fatal"; then
  echo "⚠ dot-claude fetch FAILED — ahead/behind would be stale; NOT reporting sync state"
else
  echo "dot-claude: $DOTC"
  echo "  behind: $(git -C "$DOTC" rev-list --count HEAD..origin/main)"
  echo "  ahead:  $(git -C "$DOTC" rev-list --count origin/main..HEAD)"
fi
git -C "$DOTC" status --porcelain
fi
```

Alert the user prominently if out of sync:

- **Behind**: "⚠ dot-claude is {N} commits behind origin — your global config/commands may be stale. Consider `git -C {DOTC} pull`."
- **Ahead**: "dot-claude has {N} unpushed commits — consider pushing to back up your config."
- **Dirty**: "dot-claude has uncommitted changes."

If the repo is not found, say so and move on. If the fetch fails, report that and do not report counts, which would be stale.

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
