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

- **Action-items pruning** — if `ACTION_ITEMS.md` exists at the project root and contains an outline-format `## Open / Active` section (see Catalyst-RCM's `lint-action-items` skill for the format), run:
  ```bash
  grep -A2 -E "^#### AI-[0-9]+ · (done|dropped) ·" ACTION_ITEMS.md | grep -oE "since [0-9]{4}-[0-9]{2}-[0-9]{2}" | awk '{print $2}' | while read -r d; do
    se=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null) || continue
    days=$(( ($(date +%s) - se) / 86400 ))
    [ "$days" -gt 7 ] && echo "$d ($days days)"
  done
  ```
  Free — no model tokens. If any dates print, note the count in the Ready Output ("N item(s) past the 7-day prune window") and **suggest** `/lint-action-items` (do not auto-run). No standing cron for this — deliberate, per user preference (2026-08-09): reminder-only at session start/end, not scheduled automation. The `Stop` hook (`session-end-reminder.sh`) carries the matching session-end reminder.

- **Local dev stack health** — if the project has a runner script exposing a `status` verb
  (e.g. Catalyst-RCM's `tools/run-dashboard.sh`), run it and report the result. Free — no model
  tokens. **Report the configuration, not just the ports.** "Something is listening" is the
  weakest possible reading of health, and it is the one that misleads: on 2026-08-14 the Client
  Dashboard was up, serving pages, passing every port check, and failing every chat query with
  `could not resolve credentials from session`, because the runner set `LLM_PROVIDER=bedrock`
  without `AWS_PROFILE` and `~/.aws` has no `[default]`. Credentials resolve lazily inside the
  first LLM call, so nothing surfaced until a human typed a question.

  The three things worth a line each in the Ready Output:

  - **Age and commit** — a server older than the branch tip serves stale code and silently
    invalidates anything that talks to it over HTTP.
  - **Provider + credentials** — which LLM provider the *running process* has (read it off the
    pid, not from the current shell — they drift), and whether its credentials actually resolve.
  - **Sidecar services** — MCP servers the runner does not itself start. A missing calculator MCP
    doesn't fail; it changes the answers, which is worse.

  If the check reports a problem, say so plainly in the Ready Output rather than burying it, and
  offer the restart. Do not auto-restart — a running server may be mid-test.

## Time Tracking Check (opportunistic)

If the local `punch` time tracker is installed, surface its state so billable work
gets clocked. **Skip silently if `punch` is not present on this device.** See the
`/punch` command and [[beaufort-time-tracking]] for the full surface.

```bash
P="$(command -v punch 2>/dev/null || command -v b 2>/dev/null)"
if [ -z "$P" ]; then
  U="$(id -un 2>/dev/null || echo "${USER:-}")"
  RH="$( { getent passwd "$U" | cut -d: -f6; } 2>/dev/null )"        # Linux
  [ -z "$RH" ] && RH="$( { dscl . -read "/Users/$U" NFSHomeDirectory | awk '{print $2}'; } 2>/dev/null )"  # macOS
  for c in "$RH/bin/punch" "$RH/.local/bin/punch" "$RH/bin/b" "$RH/.local/bin/b"; do
    [ -z "$P" ] && [ -x "$c" ] && P="$c"
  done
fi
[ -n "$P" ] && "$P" list-open
```

- **A timer is open** → note it in the Ready Output: "⏱ tracking: TR-NNN customer/project (elapsed Xm)". Don't start another.
- **No open timer** + this looks like billable project work → nudge once, advisory: "No active timer — `/punch start` to clock this session." Do not auto-start.
- **`punch` absent** → say nothing.

**Only claim it's absent when `$P` is genuinely empty.** The old version of this
check used the macOS-only `dscl`, which returns empty under a sandbox and made
`$RH/bin/b` resolve to `/bin/b` — so on 2026-08-14 a session reported the tracker
missing on a host where it was installed and on PATH, and that wrong claim reached
two committed documents. If `command -v` found it, it is installed.

## Ready Output

I will confirm when I am ready with a simple "i am ready to claude" and a very short, high-level plan.

output-style: brief, bulleted points
Structure the "ready" response with clear sections:

- Current Status (git, branch, sync state with origin — e.g., "master: 2 behind origin, clean — pull recommended")
- Session Context (role, recent work)
- Project Context (from README, ARCHITECTURE.md, recent session logs)
- Suggested Next Steps (based on TODOs, open issues, uncommitted changes)
