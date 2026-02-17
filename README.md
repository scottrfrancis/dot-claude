# Claude Code Infrastructure

Personal infrastructure for consistent, context-aware development across projects with Claude Code. This directory (`~/.claude/`) provides global commands, guidelines, and session management that apply to every project. Individual projects extend this foundation with domain-specific skills, hooks, and memory.

## Theory of Operation

The system operates on three principles:

**1. Sessions are stateful, not disposable.** Every session builds on previous work through persistent memory files, session logs with cross-links, and handoff prompts. A SessionStart hook automatically injects the most recent handoff context; `/lets-go` adds git sync and project overview on top; `/session-logger` captures outcomes at session end; `/handoff` bridges the gap when context fills up mid-work.

**2. Projects declare their own lifecycle.** Global infrastructure (commands, guidelines) provides universal capabilities. Projects layer on domain-specific skills, hooks, memory, and outcome tracking via their `.claude/` directory. A tiered setup model (see `guidelines/project-setup.md`) scales from a minimal `CLAUDE.md` to a full lifecycle system with validation hooks and pattern learning.

**3. Feedback loops close automatically.** Hooks fire on file writes and session end to enforce data quality and prevent lost context. Session logs feed into `/mine-sessions` for pattern extraction. Memory files capture reusable insights that improve future sessions. The system learns from its own output.

### Session Lifecycle

```text
[SessionStart hook]         ← auto: inject most recent handoff context
   ↓
/lets-go                    ← optional: sync git, load project docs, surface alerts
   ↓
  [work]                    ← middle: hooks validate writes, track changes
   ↓
[Stop hook]                 ← auto: remind about /session-logger and /handoff
   ↓
/session-logger             ← end: capture outcomes, cross-link to previous session
/handoff                    ← or: generate continuation prompt if context is full
```

### Information Flow

```text
Session logs  →  /mine-sessions  →  pattern recommendations
     ↓                                      ↓
Memory files  →  reusable patterns   →  process refinement
     ↓                                      ↓
Hooks         ←  validate quality    ←  data enforcement
```

## Directory Structure

```text
~/.claude/
├── CLAUDE.md                    # Global instructions loaded into every session
├── README.md                    # This file — theory of operation and reference
├── settings.json                # Global tool permissions and hook registration
│
├── hooks/                       # Global hooks (fire for every project)
│   ├── load-handoff-context.sh  # SessionStart: auto-inject recent handoff context
│   └── session-end-reminder.sh  # Stop: remind about /session-logger and /handoff
│
├── guidelines/                  # Reusable development standards
│   ├── shell-scripts.md         # Bash best practices: error handling, portability
│   ├── convential-commits.md    # Git commit message format and types
│   ├── readme-documentation.md  # README-centric documentation patterns
│   ├── session-safety.md        # Hardware system session isolation (CRITICAL)
│   ├── ai-patterns.md           # LLM integration: caching, routing, RAG, guardrails
│   ├── project-setup.md         # Tiered checklist for bootstrapping new projects
│   ├── shell-escaping.md        # Shell quoting, TTY handling, VS Code compatibility
│   ├── C4-diagramming.md        # C4 Model PlantUML organization
│   └── markdown-formatting.md   # Spacing and list formatting standards
│
├── commands/                    # Global commands available in every project
│   ├── lets-go.md               # Session initialization with git sync protocol
│   ├── session-logger.md        # Session summary with effectiveness assessment
│   ├── handoff.md               # Continuation prompt for session handoff
│   ├── mine-sessions.md         # Session log analysis and pattern extraction
│   ├── arch-review.md           # Principal Architect review framework
│   ├── arch-review              # (executable companion)
│   ├── commit-manual            # Conventional commit helper
│   ├── autocommit               # AI-powered commit message generator
│   ├── checkpoint-progress      # WIP commit and session state saver
│   ├── session-cleanup          # Pre-session device/process cleanup
│   ├── validate-hw-env          # Hardware environment pre-check
│   └── extract-adr              # Convert logged decisions to ADRs
│
└── projects/                    # Per-project session data (auto-managed)
    └── <encoded-path>/          # Session logs, memory snapshots per project
```

## Commands Reference

### Session Management

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **lets-go** | `/lets-go [role with task]` | Initialize a session: read project docs, run git sync protocol (fetch, compare ahead/behind, recommend pull/push/branch), check recent session logs |
| **session-logger** | `/session-logger [topic]` | Create structured session summary with: activities, decisions, reusable insights, effectiveness assessment. Cross-links to previous session log automatically |
| **handoff** | `/handoff [topic notes]` | Generate forward-looking continuation prompt for the next session. Use when context window is filling up or when pausing work mid-task. Saves to `session-logs/handoff-*.md` |
| **mine-sessions** | `/mine-sessions [days:N] [save]` | Analyze session logs for patterns, metrics, and process improvement recommendations. Extracts reusable insights, tracks decision evolution, identifies process friction |

### Git and Code Quality

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **commit-manual** | `/commit <type> [scope] <description>` | Create a conventional commit with validated type |
| **autocommit** | `/autocommit [-y] [-t type]` | Analyze changes and generate commit message with AI |
| **arch-review** | `/arch-review` | Principal Architect review: AWS/SOLID frameworks, security, testing, AI patterns, technical debt |
| **extract-adr** | `/extract-adr` | Convert significant decisions from session logs into Architecture Decision Records |

### System Operations

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **checkpoint-progress** | `/checkpoint-progress <root> <message>` | Create WIP commit and log session state |
| **session-cleanup** | `/session-cleanup` | Kill stale processes, validate device access, clean shared memory |
| **validate-hw-env** | `/validate-hw-env` | Pre-check hardware environment safety before testing |

## Guidelines Reference

| Guideline | When to Apply |
| --------- | ------------ |
| **project-setup.md** | Starting any new project — tiered checklist (Foundation → Tracked → Domain-Specific) |
| **shell-scripts.md** | Writing any bash script — directory detection, `set -euo pipefail`, cleanup traps |
| **convential-commits.md** | Every git commit — `type(scope): description` format |
| **readme-documentation.md** | Organizing project documentation — README as central hub |
| **session-safety.md** | **CRITICAL** — hardware systems only. Prevents device contention across sessions |
| **ai-patterns.md** | Building LLM integrations — 17 patterns: structured prompting, caching, routing, RAG, security |
| **shell-escaping.md** | Complex shell commands — quoting rules, heredocs, VS Code terminal escaping |
| **C4-diagramming.md** | Architecture diagrams — modular PlantUML with C4 Model levels |
| **markdown-formatting.md** | All markdown files — blank line rules, list spacing |

## Hooks System

Hooks are shell scripts that fire on specific Claude Code events. They operate at two levels:

- **Global** (`~/.claude/settings.json`): Fire for every project. Handle session lifecycle automation.
- **Project** (`.claude/settings.local.json`): Add domain-specific checks. Layer on top of global hooks.

### Global Hooks

| Event | Hook | What It Does |
| ----- | ---- | ------------ |
| **SessionStart** | `load-handoff-context.sh` | Auto-injects the most recent `handoff-*.md` as context on new session startup. Checks project-local `.claude/session-logs/` first, then global. Skips files >7 days old. |
| **Stop** | `session-end-reminder.sh` | Reminds about `/session-logger` (3+ files changed) and `/handoff` (5+ files changed) when neither has been run in the last 2 hours. |

### Project Hook Types

| Event | When It Fires | Use Case |
| ----- | ------------ | -------- |
| **PostToolUse** | After Write/Edit/MultiEdit | Validate file structure, enforce data quality rules |
| **Stop** | Session ending | Domain-specific reminders (stale data, unprocessed inbox) |

### Hook Design Rules

- **Advisory only** — hooks warn on stderr but never block operations (exit 0 always)
- **Fast** — 5-second timeout; no network calls, no heavy computation
- **Defensive** — `set -euo pipefail`, drain stdin with `cat > /dev/null` or `jq`, guard all greps with `|| true`
- **Context injection** — SessionStart hooks can output JSON with `additionalContext` to inject text into Claude's context

### Hook Registration Pattern

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/script.sh", "timeout": 5000 }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{ "type": "command", "command": ".claude/hooks/script.sh", "timeout": 5000 }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": ".claude/hooks/script.sh", "timeout": 5000 }]
      }
    ]
  }
}
```

## Setting Up a New Project

Follow `guidelines/project-setup.md` for the full checklist. The short version:

**Tier 1 (all projects):** Create `CLAUDE.md` at project root, `.claude/memory/MEMORY.md` for persistent context, and `.claude/session-logs/` for handoff auto-loading. Global commands (`/lets-go`, `/session-logger`, `/handoff`) and global hooks (SessionStart context injection, Stop reminders) work immediately with no per-project setup.

**Tier 2 (tracked projects):** Add `.claude/settings.local.json` for permissions and hook registration. Add a Stop hook for session-end reminders. Create `.claude/session-logs/` directory.

**Tier 3 (domain lifecycle):** Add custom skills in `.claude/skills/`, outcome tracking files, pattern memory, and validation hooks. Build these incrementally as workflows emerge — not all at once.

### Extending Base Commands (The `super()` Pattern)

Project commands shadow global commands of the same name — there's no automatic composition. But the global file still exists on disk. A project can delegate to the base and add domain logic:

```markdown
# Project .claude/commands/lets-go.md
---
description: Session init with domain-specific dashboard
---

## Base Protocol
Read and follow the session initialization protocol defined in ~/.claude/commands/lets-go.md.

## Domain Extensions
After the base protocol completes, additionally:
- Check domain-specific tracking files...
- Surface project-specific alerts...
```

This gives each project a single `/lets-go` entry point while keeping the base class clean. Projects that don't need extensions inherit the global version unchanged.

## Permissions Model

Permissions operate at two levels:

- **Global** (`~/.claude/settings.json`): Whitelists commonly used tools across all projects — git operations, package managers, AWS CLI, Docker, language runtimes
- **Project** (`.claude/settings.local.json`): Adds project-specific permissions (WebFetch domains, tool access, additional directories) and hook configuration

Project settings supplement global settings. Both use the same format:

```json
{
  "permissions": {
    "allow": ["Bash(git:*)", "WebFetch(domain:example.com)"],
    "deny": []
  }
}
```
