---
description: set initial context for a working session
argument-hint: [role with task]
allowed-tools: Bash, Read, Grep, Glob
---

as $ARGUMENTS

1. Run the status probe outside the sandbox. It fetches, and the sandbox blocks both the fetch
   and the time tracker's database.

   ```bash
   S="$HOME/.claude/bin/session-status.sh"; [ -x "$S" ] || S=/Volumes/workspace/dot-claude/bin/session-status.sh
   "$S" --fetch
   ```

   It prints only what needs attention, and nothing when all is well. How to act on each line:

   - **Drift on a default branch.** Local-only commits: suggest `git pull --rebase`, then a push.
     Behind only and clean: offer `git pull --ff-only`. Ask before pushing a default branch, every
     time, and never reset.
   - **`fetch FAILED`.** Say the sync state is unknown. Never report it as in sync.
   - **Off the default branch.** Name the branch in the branch reminder.
   - **Handoffs.** When one is from the last two days and belongs to this repo, offer `/pickup`
     and wait for the answer. Otherwise mention them. Read one only through `/pickup`, or when the
     user picks it; parallel sessions in the same repo must not take each other's handoffs.
   - **`timer: none open`** on billable project work: suggest `/punch start` once. Never start or
     stop a timer yourself.
   - **Hooks, conformance, action items.** Mention once. Offer `/mine-sessions` or
     `/lint-action-items`; they spend tokens, so never run them unprompted.

2. Take the role in the arguments.
3. Read the project's README, and its CLAUDE.md or AGENTS.md if present. Read other docs when the
   task needs them.
4. Find where work left off. Each of these is cheap; skip any that does not exist.
   - `git log --oneline -8` on the current branch.
   - The newest session log in `session-logs/` (or the legacy `.claude/session-logs/`), skipping
     `handoff-*` and `mine-report-*` files: read its summary and next steps only.
   - Open items in `TODO*`, `plans/` or `ACTION_ITEMS.md` at the project root.
5. Reply "i am ready to claude", then brief bullets:
   - Current state: branch, sync, and anything the probe flagged.
   - Recent work: what the commits and the newest session log say was last done.
   - Task: the task as understood from the arguments.
   - Suggested next steps: from the session log's next steps, open items and uncommitted
     changes, then a short plan.
