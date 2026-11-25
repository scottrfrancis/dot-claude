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
   - **Handoffs.** Mention them. Read one only through `/pickup`, or when the user picks it.
   - **`timer: none open`** on billable project work: suggest `/punch start` once. Never start or
     stop a timer yourself.
   - **Hooks, conformance, action items.** Mention once. Offer `/mine-sessions` or
     `/lint-action-items`; they spend tokens, so never run them unprompted.

2. Take the role in the arguments.
3. Read the project's README, and its CLAUDE.md or AGENTS.md if present. Read other docs when the
   task needs them.
4. Reply "i am ready to claude", then brief bullets: current state (branch, anything the probe
   flagged), the task as understood, and a short plan.
