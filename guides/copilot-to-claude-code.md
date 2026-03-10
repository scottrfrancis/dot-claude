# GitHub Copilot to Claude Code: A Transition Guide

This guide is written for senior engineers who live in GitHub Copilot and are adopting Claude Code. You already know how to code. This is about the tool model shift — what's different, what to set up, and how to work effectively.

---

## The Core Mental Model Shift

| | GitHub Copilot | Claude Code |
|---|---|---|
| **Interaction style** | Inline suggestions; you drive | Conversational agent; it acts |
| **Context window** | File + some surrounding context | Entire codebase + conversation history |
| **Output** | Code completions | Code edits, file writes, shell commands |
| **Session state** | Stateless per keystroke | Stateful across a conversation |
| **Cross-session memory** | None | Via handoff files + MEMORY.md |
| **Autonomous action** | No (suggests only) | Yes (with your approval) |

**The biggest adjustment:** Claude Code doesn't suggest — it *does*. It will edit files, run commands, and commit code. You are approving actions, not accepting completions. This requires you to think about scope and reversibility differently.

---

## Setup: What You Need Before Starting

### 1. Install Claude Code
```bash
npm install -g @anthropic-ai/claude-code
claude  # opens interactive session
```

### 2. Global Config Repo (`~/.claude`)

This repo holds your commands, guidelines, hooks, and memory that apply to *every* project. Think of it as your global Copilot settings, but far more powerful.

```
~/.claude/
├── CLAUDE.md              # Global instructions injected every session
├── commands/              # Custom slash commands (/lets-go, /autocommit, etc.)
├── guidelines/            # Reference docs Claude follows during work
├── hooks/                 # Shell scripts that fire on session events
├── memory/MEMORY.md       # Persistent cross-session notes
└── settings.json          # Permissions model
```

**If using this repo:** Clone it to `~/.claude` and run:
```bash
chmod +x ~/.claude/hooks/*.sh
```

### 3. Per-Project Config

Each project can have its own overlay:
```
your-project/
└── .claude/
    ├── CLAUDE.md              # Project-specific instructions (extends global)
    └── settings.local.json    # Project-specific permissions
```

---

## Sessions: The Key Concept Copilot Doesn't Have

Copilot has no concept of a session. Claude Code does, and it matters for context continuity.

### The Session Lifecycle

```
/lets-go  →  [work]  →  /session-logger  →  /handoff  →  [next session]  →  /pickup
```

**Why this matters:** Claude's context window is large but not infinite. After a multi-hour session, context compresses. The session lifecycle externalizes important state so the next session starts informed, not blank.

### Starting a Session: `/lets-go`

Run this at the start of every session. It:
- Checks your hooks are installed and working
- Fetches origin and reports git sync state on both `~/.claude` and your project
- Flags uncommitted changes, stale branches, diverged state
- Injects previous session context (if a handoff exists)
- Gives you a ready summary

```
/lets-go [optional role/context description]

# Example:
/lets-go principal SDE working on auth service refactor
```

**Copilot equivalent:** There is none. This is new behavior.

### During a Session: Commits

Instead of committing manually, use `/autocommit`:
```
/autocommit          # stage tracked files + AI-generated commit message
/autocommit -n       # same, but confirm before staging and committing
/autocommit -all     # include untracked files (use carefully — avoids .gitignore leaks by default)
```

All commits follow [Conventional Commits](../guidelines/conventional-commits.md) format (`feat:`, `fix:`, `docs:`, etc.).

### Ending a Session: `/session-logger` + `/handoff`

After significant work (3+ files changed):

**`/session-logger`** — Creates a structured log in `.claude/session-logs/`:
- What was done and why
- Files modified
- Decisions made with rationale
- Carry-forward items
- Session effectiveness self-assessment

**`/handoff`** — Creates a `handoff-YYYY-MM-DD-HHMM.md` in `.claude/session-logs/`. This file is auto-loaded at the start of your *next* session by the `SessionStart` hook.

The hooks remind you automatically:
> "3+ files changed — consider running /session-logger"
> "5+ files changed — consider running /handoff"

### Resuming: `/pickup`

At the start of a session where you had a handoff:
```
/pickup
```
This loads the handoff context, runs a quick git sync, and archives the handoff file. The `SessionStart` hook also auto-injects the most recent handoff if it's less than 7 days old.

---

## Commands vs. Copilot Chat

Copilot has inline chat (`Ctrl+I`) and sidebar chat. Claude Code has slash commands, which are full skill definitions that include tool access, step-by-step instructions, and conventions.

### Key Commands

| Command | What it does |
|---------|-------------|
| `/lets-go` | Session start: hooks check, git sync, context load |
| `/autocommit` | Stage + commit with AI-generated conventional message |
| `/handoff` | Generate continuation prompt for next session |
| `/pickup` | Resume from last handoff |
| `/session-logger` | Create structured session summary |
| `/doc-review` | Audit docs for accuracy, DRY, clarity; commits on a docs branch |
| `/arch-review` | Comprehensive architectural review |
| `/security-audit` | Breach-driven security audit |
| `/editorial-review` | Audit prose for AI writing patterns |
| `/mine-sessions` | Analyze session logs for patterns and metrics |

### Writing Your Own Commands

Commands live in `~/.claude/commands/*.md`. Format:
```markdown
---
description: One-line description of what this command does
argument-hint: [-n to confirm] [-all to include untracked]
allowed-tools: Bash, Read, Glob, Edit
---

Steps Claude follows when this command is invoked...
```

---

## CLAUDE.md: Your Persistent Instructions

This is the closest analog to Copilot's system-level configuration, but more direct. Claude reads `CLAUDE.md` at the start of every session and treats it as standing instructions.

### Global (`~/.claude/CLAUDE.md`)

Put things that apply to all your projects:
- Commit conventions
- Shell and language preferences
- Reminders about branching strategy
- Links to your guidelines library

### Project-Local (`.claude/CLAUDE.md` in the project root)

Put things specific to that codebase:
- Tech stack and architecture notes
- Where tests live, how to run them
- Deployment targets
- Any Claude behaviors to override from global

Claude merges both — project-local wins on conflicts.

---

## MEMORY.md: Cross-Session Notes

Located at `~/.claude/memory/MEMORY.md`. Claude reads this at startup and updates it over time with things worth remembering:

- Key architectural decisions
- Patterns discovered during work
- What certain commands do and why they work that way
- Active projects and their stack

You can also write to it directly:
```
Remember for future sessions: always use pnpm, not npm, in this project
```

**Copilot equivalent:** There is none. Copilot forgets everything when you close the file.

---

## Plan Mode: Think Before You Build

Plan mode is unique to Claude Code — no Copilot equivalent.

When you invoke it (or when Claude decides a task is complex enough):
1. Claude explores the codebase and asks clarifying questions
2. It writes a plan file to `~/.claude/plans/`
3. You review and approve (or ask for changes) before any code is written

**When to use it:**
- New features touching multiple files
- Refactors with non-obvious ripple effects
- Anything where "what are we actually doing?" isn't obvious

**How to trigger it:** Claude Code has a "Plan" button in the UI, or you can preface requests with "plan first before implementing."

---

## Permissions: Approving Actions, Not Completions

This is the biggest workflow change from Copilot. Claude will ask for permission before executing commands that aren't pre-approved.

### How Permissions Work

**Global (`~/.claude/settings.json`):** Broad patterns for all projects:
```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(python3:*)"
    ]
  }
}
```

**Project-local (`.claude/settings.local.json`):** Project-specific approvals:
```json
{
  "permissions": {
    "allow": [
      "Bash(docker-compose up:*)",
      "Bash(./scripts/deploy.sh:*)"
    ]
  }
}
```

**Rule of thumb:** Approve patterns at the global level. Approve specific one-off commands at the project level. Never let specific commands accumulate in the global file — it becomes unmanageable.

### Safety Hooks

Three hooks run automatically to guard dangerous operations:

**PreToolUse** (`pre-tool-safety.sh`): Intercepts and warns before:
- `git reset --hard`
- `git push --force`
- `rm -rf` and recursive deletes
- Writes to sensitive config files (`~/.ssh`, `~/.aws`)

**SessionStart** (`load-handoff-context.sh`): Auto-loads the previous session's handoff.

**Stop** (`session-end-reminder.sh`): Reminds you to log and hand off if significant work was done.

These are **advisory** — they warn but don't block. You stay in control.

---

## Context: What Claude Knows and When

| Context source | When it's loaded | How to update it |
|----------------|-----------------|-----------------|
| `CLAUDE.md` (global) | Every session | Edit `~/.claude/CLAUDE.md` |
| `CLAUDE.md` (project) | Every session in that project | Edit `.claude/CLAUDE.md` |
| `MEMORY.md` | Every session | Claude updates it; or edit directly |
| Handoff file | On `/pickup` or SessionStart hook | Created by `/handoff` |
| Open files in IDE | Real-time | Open files in your editor |
| Codebase | On-demand via tools | Claude searches when needed |

**Practical tip:** If you're starting a new area of the codebase Claude hasn't seen, explicitly say: "Read `src/auth/` and understand the existing patterns before making changes." Claude will explore before acting.

---

## Workflow Comparison: A Real Task

**With Copilot:**
1. Open file, start typing
2. Accept or reject inline completions
3. Move to next file, repeat
4. `git add -A && git commit -m "feat: add auth middleware"`

**With Claude Code:**
1. `/lets-go` — sync state, load context
2. "Add JWT middleware to the Express routes in `src/routes/`. Follow the existing pattern in `src/middleware/`."
3. Claude reads the existing middleware, proposes what it will do, writes the code
4. Review the diff in your IDE
5. `/autocommit` — AI-generated conventional commit
6. (end of session) `/session-logger` → `/handoff`

The Claude version does more autonomous work. Your job shifts from typing to **reviewing and steering**.

---

## Common Gotchas for Copilot Users

**"Claude isn't suggesting completions"**
It doesn't. Describe what you want in natural language. The interface is conversation, not completion.

**"I accepted a change I didn't want"**
Before complex operations, say "show me what you're planning to do" or enable plan mode. You can always `git diff` and `git checkout .` if needed.

**"Claude forgot what we were doing"**
Run `/handoff` at the end of sessions and `/pickup` at the start. The hooks automate most of this.

**"I keep approving the same commands"**
Add broad patterns to `settings.json` instead of approving one-off. See the Permissions section above.

**"Claude is making too many changes at once"**
Break the request into smaller tasks. "First, just read the existing auth code and tell me what you see" before "now add the new feature."

**"The session got confused"**
Start fresh with `/lets-go`. This re-anchors context with git state and project structure.

---

## Quick Reference

```bash
# Start of every session
/lets-go

# Commit changes
/autocommit            # tracked files only (safe default)
/autocommit -all       # include untracked

# End of session (if significant work done)
/session-logger
/handoff

# Start of next session
/pickup

# Reviews
/doc-review
/arch-review
/security-audit

# When you want Claude to plan before acting
# (prefix your request)
"Plan first, then implement: ..."
```

---

## Further Reading

- [Conventional Commits](../guidelines/conventional-commits.md) — commit message format
- [Shell Script Best Practices](../guidelines/shell-scripts.md) — if Claude writes bash
- [Project Setup](../guidelines/project-setup.md) — bootstrapping a new project with this workflow
- [Prototype Hygiene](../guidelines/prototype-hygiene.md) — keep the codebase clean as you iterate
- [Session Safety](../guidelines/session-safety.md) — critical if working with hardware (GPU/NPU)
