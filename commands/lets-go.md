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

## Ready Output

I will confirm when I am ready with a simple "i am ready to claude" and a very short, high-level plan.

output-style: brief, bulleted points
Structure the "ready" response with clear sections:

- Current Status (git, branch, sync state with origin — e.g., "master: 2 behind origin, clean — pull recommended")
- Session Context (role, recent work)
- Project Context (from README, ARCHITECTURE.md, recent session logs)
- Suggested Next Steps (based on TODOs, open issues, uncommitted changes)
