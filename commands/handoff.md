---
description: Generate a continuation prompt for seamless session handoff
argument-hint: [topic notes]
allowed-tools: Read, Bash, Glob, Grep, Write
---

# Session Handoff

Generate a continuation prompt capturing current session state for the next session. This is forward-looking — what should the next session know and do — unlike `/session-logger` which documents what happened.

## Gather State

1. Review conversation history for: completed tasks, in-progress work, decisions made, pending items
2. Run `git status` and `git diff --stat` for uncommitted changes
3. Check `git log --oneline -5` for recent commits this session
4. Read any active TODO lists or plan files
5. Check for recent session logs (`session-logs/` then `.claude/session-logs/`) for additional context

Arguments provided: $ARGUMENTS

## Dot-Repo Sync Check (`~/.claude`)

Before generating the handoff, verify the global Claude Code config at `~/.claude` is in sync with its GitHub origin. This catches stale or uncommitted config that the next session should know about.

```bash
git -C ~/.claude fetch origin
git -C ~/.claude rev-list --count HEAD..origin/main   # behind
git -C ~/.claude rev-list --count origin/main..HEAD   # ahead
git -C ~/.claude status --porcelain
```

Alert the user prominently if out of sync, and note the state in the `## Blockers / Risks` section of the handoff if drift is detected:

- **Behind**: "⚠ ~/.claude is {N} commits behind origin — your global config/commands may be stale. Consider `git -C ~/.claude pull`."
- **Ahead**: "~/.claude has {N} unpushed commits — consider pushing to back up your config."
- **Dirty**: "~/.claude has uncommitted changes."

Skip silently if `~/.claude` has no remote or the fetch fails.

## Generate Continuation Prompt

Write to `session-logs/handoff-YYYY-MM-DD-HHMM.md` using the current date and time. If `session-logs/` does not exist, create it. If creation fails, fall back to `.claude/session-logs/`.

The file MUST include YAML frontmatter for cross-tool compatibility. Populate `branch`, `dirty`, and `files_changed` from git status:

```markdown
---
tool: claude-code
timestamp: YYYY-MM-DDTHH:MM:SS-TZ
branch: <current branch from git>
dirty: <true if uncommitted changes, false otherwise>
files_changed: <count of uncommitted changed files>
---

## Completed This Session
[Numbered list of completed tasks with specifics — file paths, decisions, outcomes]

## Current State
[Branch, uncommitted changes, work-in-progress items]
[On {branch} with {N} uncommitted changes from this session]

## In Progress
[Tasks started but not completed, with current status and what remains]

## Suggested Follow-Up
[Prioritized next steps — what to do first in the next session]

## Key Decisions
[Decisions that affect future work — rationale included so the next session doesn't revisit them]

## Blockers / Risks
[Anything the next session needs to be aware of]
```

The YAML frontmatter is required — it identifies the source tool so any receiving tool (Cursor, Copilot, Droid) knows where the handoff came from.

## Reminder

If `/session-logger` hasn't been run yet and 3+ files were changed, remind the user to run it before ending the session.

## Rules

- Keep to ~50-80 lines — scannable, not exhaustive
- Include file paths for anything created or modified
- The continuation prompt must be self-contained — a new session reading only this text should have full context to continue
- Bias toward actionable items over narrative
- Do not fabricate or assume tasks — only include work that actually happened in this session
- If the user provided topic notes in $ARGUMENTS, incorporate them as additional context
