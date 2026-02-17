---
description: set initial context for a working session
argument-hint: [role with task]
allowed-tools: Write, Bash, Read, LS, Grep, Glob, TodoWrite, Git, Gh
---

as $ARGUMENTS

I'll review the project documentation including:

- README
- ARCHITECTURE.md (if present)
- CONTRIBUTING.md (if present)
- .claude/session-logs (verify auto-loaded handoff context; the SessionStart hook injects the most recent handoff automatically)
- docs/
- plans/
- TODO
- recent commits

Arguments provided: $ARGUMENTS

## Git Sync Protocol

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
