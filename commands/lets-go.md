---
description: set initial context for a working session
argument-hint: [role with task]
allowed-tools: Write, Bash, Read, LS, Grep, Glob, TodoWrite, Git, Gh
---

as $ARGUMENTS

## Load Handoff Context

The SessionStart hook auto-injects handoff context, but verify it loaded and check for cross-tool handoffs:

1. Look for the most recent `handoff-*.md` file in these locations (check all, take newest):
   - `session-logs/` (shared cross-tool location)
   - `.claude/session-logs/` (Claude Code legacy location)
   - `.factory/logs/` (Droid legacy location)
   - **Workspace-wide fallback** — when cwd is *not* a git repo (e.g. launched from `~`), the
     paths above miss handoffs written into each project's `session-logs/`. Also scan:
     ```bash
     find /Volumes/workspace -maxdepth 3 -path '*/session-logs/handoff-*.md' -mtime -7 2>/dev/null \
       -exec stat -f '%Sm %N' -t '%Y-%m-%d %H:%M' {} \; | sort -r | head -8
     ```
     If several candidates across different repos, list the top few (repo + timestamp) and ask
     which to resume rather than assuming the newest — or just note them and continue.
2. If found and less than 7 days old, read it and incorporate as session context
3. If the file has YAML frontmatter with a `tool:` field, note the source (e.g., "Continuing from a Cursor session")
4. Report: "Loaded handoff context from [filename] ([tool])" or "No recent handoff found"

## Review Project Documentation

I'll review the project documentation including:

- README
- ARCHITECTURE.md (if present)
- CONTRIBUTING.md (if present)
- docs/
- plans/
- TODO
- recent commits

Arguments provided: $ARGUMENTS

## Hook Health Check

Run this before anything else. Check that all three global safety hooks are installed and executable:

```bash
for f in load-handoff-context.sh pre-tool-safety.sh session-end-reminder.sh; do
  test -x ~/.claude/hooks/$f && echo "OK: $f" || echo "MISSING/NOT-EXECUTABLE: $f"
done
grep -q '"SessionStart"' ~/.claude/settings.json && echo "OK: SessionStart" || echo "MISSING: SessionStart in settings.json"
grep -q '"PreToolUse"' ~/.claude/settings.json && echo "OK: PreToolUse" || echo "MISSING: PreToolUse in settings.json"
grep -q '"Stop"' ~/.claude/settings.json && echo "OK: Stop" || echo "MISSING: Stop in settings.json"
```

- **All OK** → include `Hooks: ✓ all installed` in the Ready Output.
- **Any missing** → display a prominent warning block before proceeding:

```
⚠️  HOOK SETUP NEEDED
[list each missing item]

To fix:
- Re-clone dotfiles or copy hook scripts to ~/.claude/hooks/
- chmod +x ~/.claude/hooks/*.sh
- Ensure ~/.claude/settings.json registers SessionStart, PreToolUse, and Stop hooks
```

This is advisory only — continue the session regardless.

## Git Sync Protocol

### Dot-Repo Sync Check (`~/.claude`)

Run this check first, before any project-specific work. Consistent with `/pickup`, `/handoff`, and `/session-logger`.

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

### Other Dot-Repos (Opportunistic)

The user may run sessions from other tools (Cursor, Droid, Copilot) on this machine. If any of those dot-repos are discoverable, run the same `fetch / rev-list / status` pattern against them and report drift with the same behind/ahead/dirty wording. **Skip silently for any repo not installed on this machine** — do not emit errors.

- **dot-droid**: check only if `$HOME/.factory` is a symlink to a git repo. Resolve `readlink -f $HOME/.factory` and take its parent; confirm `.git` exists there.
- **dot-copilot**: check only if a `.github/copilot-instructions.md` (or any `.github/instructions/*.instructions.md`) symlink exists in the current project. Resolve it and walk up until `.git` is found.
- **dot-cursor**: check only if `$DOT_CURSOR_DIR` is set, or if any of `$HOME/workspace/dot-cursor`, `$HOME/dot-cursor`, `/Volumes/workspace/dot-cursor` has a `.git` directory.

### Project repo

Run these checks in order:

1. `git fetch origin` — update remote tracking refs
2. Determine current branch and its upstream tracking branch
3. If no upstream: report "Branch {name} has no upstream tracking — local only"
4. If upstream exists, compute:
   - Behind count: `git rev-list --count HEAD..origin/{branch}`
   - Ahead count: `git rev-list --count origin/{branch}..HEAD`
5. Report state clearly:
   - **In sync**: "Branch {name} is up to date with origin"
   - **Behind only**: "Branch {name} is {N} commits behind origin — recommend `git pull`"
   - **Ahead only**: "Branch {name} is {N} commits ahead — {N} unpushed commits"
   - **Diverged**: "Branch {name} has diverged — {N} ahead, {M} behind — recommend pull + rebase or merge"
6. Check for uncommitted changes (`git status --porcelain`)
   - If dirty + behind: warn "Uncommitted changes AND behind origin — stash first, then pull"
   - If clean + behind: offer to pull automatically
7. If on default branch (main/master) with uncommitted changes: suggest creating a feature branch

## Project Auto-Checks (opportunistic, cheap)

Run only if the corresponding project tooling exists; **skip silently otherwise**. These are token-cheap freshness checks, never LLM ingestion.

- **Gemini meeting transcripts** — if `tools/pull-gemini-notes.sh` exists in the project, run the `fetch-meeting-notes` skill (or the script directly:
  `GOOGLE_WORKSPACE_CLI_CONFIG_DIR=$HOME/.config/gws/ail tools/pull-gemini-notes.sh Catalyst`).
  This pulls any new "Notes by Gemini" Docs from Drive (free — no model tokens). Report newly pulled transcripts in the Ready Output. If new files landed, **suggest** `/harvest-action-items` (do not auto-run — it spends tokens). If `gws auth status` shows expired/no auth, note it briefly and continue. Setup/troubleshooting: the project's `tools/SETUP-gemini-notes.md`.

## Time Tracking Check (opportunistic)

If the local `b` time tracker is installed, surface its state so billable work
gets clocked. **Skip silently if `b` is not present on this device.** See the
`/b` command and [[beaufort-time-tracking]] for the full surface.

```bash
B="$(command -v b 2>/dev/null)"
if [ -z "$B" ]; then
  RH="$(dscl . -read "/Users/$(whoami)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  [ -x "$RH/bin/b" ] && B="$RH/bin/b"
fi
[ -n "$B" ] && "$B" list-open
```

- **A timer is open** → note it in the Ready Output: "⏱ tracking: TR-NNN customer/project (elapsed Xm)". Don't start another.
- **No open timer** + this looks like billable project work → nudge once, advisory: "No active timer — `/b start` to clock this session." Do not auto-start.
- **`b` absent** → say nothing.

## Ready Output

I will confirm when I am ready with a simple "i am ready to claude" and a very short, high-level plan.

output-style: brief, bulleted points
Structure the "ready" response with clear sections:

- Current Status (git, branch, sync state with origin — e.g., "master: 2 behind origin, clean — pull recommended")
- Session Context (role, recent work)
- Project Context (from README, ARCHITECTURE.md, recent session logs)
- Suggested Next Steps (based on TODOs, open issues, uncommitted changes)
