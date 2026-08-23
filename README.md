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
│   ├── pre-tool-safety.sh       # PreToolUse: block destructive git/rm/config writes
│   └── session-end-reminder.sh  # Stop: remind about /session-logger and /handoff
│
├── guidelines/                  # Reusable development standards
│   ├── shell-scripts.md         # Bash best practices: error handling, portability
│   ├── conventional-commits.md  # Git commit message format and types
│   ├── readme-documentation.md  # README-centric documentation patterns
│   ├── session-safety.md        # Hardware system session isolation (CRITICAL)
│   ├── ai-patterns.md           # LLM integration: caching, routing, RAG, guardrails
│   ├── project-setup.md         # Tiered checklist for bootstrapping new projects
│   ├── shell-escaping.md        # Shell quoting, TTY handling, VS Code compatibility
│   ├── C4-diagramming.md        # C4 Model PlantUML organization
│   ├── markdown-formatting.md   # Spacing and list formatting standards
│   ├── prose-style.md           # Anti-AI-smell rules: punctuation, sentence variation, word choice
│   ├── prototype-hygiene.md     # Ship clean: config over code, stable docs, PRs over branches
│   └── security-hardening.md    # Defense-in-depth patterns grounded in breach analysis
│
├── commands/                    # Global commands available in every project
│   ├── lets-go.md               # Session initialization with git sync protocol
│   ├── session-logger.md        # Session summary with effectiveness assessment
│   ├── handoff.md               # Continuation prompt for session handoff
│   ├── mine-sessions.md         # Session log analysis and pattern extraction
│   ├── arch-review.md           # Principal Architect review framework
│   ├── doc-review.md            # Documentation audit: accuracy, DRY, clarity
│   ├── editorial-review.md      # Prose audit: AI tells, voice/tone refinement
│   ├── security-audit.md        # Breach-driven security audit for web apps
│   ├── pickup.md                # Resume from the most recent handoff prompt
│   ├── commit-manual            # Conventional commit helper
│   ├── autocommit.md            # AI-powered commit message generator
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
| **memorialize** | `/memorialize [topic]` | Close out a thread at a context shift: sort durable from transient, propose dated MEMORY.md entries, name promotion candidates (guideline / ADR / `okf-knowledge`), then confirm whether it is safe to clear |
| **mine-sessions** | `/mine-sessions [days:N] [save]` | Analyze session logs for patterns, metrics, and process improvement recommendations. Extracts reusable insights, tracks decision evolution, identifies process friction |
| **pickup** | `/pickup` | Resume from the most recent handoff: load handoff file, quick git sync, archive the handoff so it isn't re-injected next session |

### Git and Code Quality

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **commit-manual** | `/commit <type> [scope] <description>` | Create a conventional commit with validated type |
| **autocommit** | `/autocommit [-n] [-t type] [-all]` | Stage tracked changes and commit with an AI-generated conventional commit message; `-n` prompts for confirmation |
| **arch-review** | `/arch-review` | Principal Architect review: AWS/SOLID frameworks, security, testing, AI patterns, technical debt |
| **extract-adr** | `/extract-adr` | Convert significant decisions from session logs into Architecture Decision Records |
| **doc-review** | `/doc-review` | Audit project documentation for accuracy, DRY, and clarity; commit fixes on a `docs/review-*` branch |
| **editorial-review** | `/editorial-review [style]` | Audit prose for AI-generated patterns; refine toward a target voice or style |
| **security-audit** | `/security-audit` | Breach-driven security audit: OWASP top 10, secrets exposure, injection, auth weaknesses |

### System Operations

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **checkpoint-progress** | `/checkpoint-progress <root> <message>` | Create WIP commit and log session state |
| **session-cleanup** | `/session-cleanup` | Kill stale processes, validate device access, clean shared memory |
| **validate-hw-env** | `/validate-hw-env` | Pre-check hardware environment safety before testing |

### Also Available

Every remaining command in `~/.claude/commands/`.

| Command | Invocation | Purpose |
| ------- | --------- | ------- |
| **assumptions** | `/assumptions` | Track hypothesis-driven assumptions (if-true/if-false/fallback) in ASSUMPTIONS-TRACKER.md |
| **babysit-pr** | `/babysit-pr` | Monitor a PR for check results, reviews, and merge readiness; pairs with `/loop` |
| **build-pdf** | `/build-pdf` | Build a PDF from ordered markdown sections via the `md2pdf` CLI and a `report.yaml` manifest |
| **constitution** | `/constitution` | Generate CONSTITUTION.md + WORKFLOWS.md (principles, Definition of Done, quality gates) |
| **design-review** | `/design-review` | Review design deliverables for consistency, terminology alignment, cross-document reference integrity |
| **discovery-init** | `/discovery-init` | Scaffold a Spec-Driven Development project: artifact templates, glossary, constitution, traceability chain |
| **export-prompts** | `/export-prompts` | Python: export AI agent prompt history (Droid + Claude Code sessions) to markdown, by date or range |
| **gherkin** | `/gherkin` | Draft Gherkin acceptance scenarios from a requirement or FR-### |
| **interview-to-spec** | `/interview-to-spec` | Convert interview notes into readout, FR-### requirements, Gherkin scenarios, and tracker updates |
| **link-sweep** | `/link-sweep` | One target per invocation of the federation link audit; designed to run under `/loop` |
| **pr-tokens** | `/pr-tokens` | Python: format the current branch's token usage as a PR-description snippet (see `guidelines/pr-token-tracking.md`) |
| **punch** | `/punch` | Drive the local `punch` time tracker (start/stop/status/log); project-aware, syncs to hasami via the time-push agent. Renamed from `/b` on 2026-08-14; `b` remains a symlink |
| **review-pr** | `/review-pr` | PR code review: bugs, security, missing tests, style; works with PR numbers or branches |
| **trace-check** | `/trace-check` | Validate bidirectional traceability across requirements, feature files, scenarios, and tests |

## Guidelines Reference

On-demand reference standards in `~/.claude/guidelines/`. Read the relevant one *before* the matching task — they are not auto-loaded.

| Guideline | When to Apply |
| --------- | ------------ |
| **2x2-status-report.md** | Quad-chart format for short weekly status reports (Last week / This week / Risks / Asks); SA-org tradition, not the canonical Amazon WBR |
| **C4-diagramming.md** | PlantUML file organization for C4 diagrams (modular includes, C1/C2/C3 layout, boundary conflicts) |
| **adr.md** | Canonical Architecture Decision Record convention: docs/decisions/ADR-NNNN, numbering, status lifecycle, FR-### traceability |
| **ai-cron-tool-delegation.md** | When a cron skill must produce a number, build a deterministic helper and wire it via cron payload — not via SKILL.md or AGENTS.md |
| **ai-patterns.md** | LLM integration patterns: caching, routing, guardrails, RAG |
| **architecture-diagrams.md** | AWS reference-diagram visual conventions (numbered flow, icon/color rules, boundaries, critique rubric, reference assets); GCP/multi-cloud adaptation; companion to C4-diagramming.md |
| **central-ops-knowledge.md** | The vision + doctrine for the central, authoritative, dynamic+archival ops-knowledge state (`okf-knowledge` bundle + wiki, served live via the `kb-mcp` filesystem MCP + `kb-static` browse on mini; Hazel/OpenWebUI is one client); consult-before-acting, write-back. Propagated to all AI tools. |
| **ci-local-parity.md** | Run exact CI commands locally before pushing; install all scanners; budget for pre-existing issues |
| **conventional-commits.md** | Standardized commit message format |
| **data-diode-list-control.md** | Black/white/gray list pattern for one-way egress boundaries (scrub/allow/pending-promotable); the gray list discovers unknowns before they leak |
| **docker.md** | Multi-stage builds, security, layer optimization |
| **docx-conversion.md** | python-docx over pandoc; color palette, typography, hyperlinks |
| **git-workflow.md** | Branch + PR discipline; never commit/push main; stacked-PR handling |
| **glossary.md** | Terms that mean something specific here — seeded from real collisions, anti-meanings, segmented like memory |
| **golang.md** | JSON response safety (no fmt.Fprintf), gosec patterns, G104 triage |
| **karpathy-principles.md** | Deltas not already covered: surface assumptions before implementing; match existing style; mention don't delete pre-existing dead code; read before you write |
| **markdown-formatting.md** | Spacing rules for generated Markdown: blank lines around lists, paragraph separation, consistent bullet markers |
| **pr-token-tracking.md** | Include AI token usage in PR descriptions, read from the branch-keyed ledger |
| **project-setup.md** | Tiered checklist for bootstrapping new projects with hooks, memory, and session tooling |
| **memory.md** | Recording durable non-obvious context — one dated fact per line, no personal data, decay and promotion rules |
| **prose-style.md** | Anti-AI-smell rules for narrative writing: punctuation, sentence variation, transitions, word choice |
| **prototype-hygiene.md** | Ship clean from day one: config over code, stable docs over stale state, PRs over branches |
| **python.md** | Type hints, error handling, testing patterns |
| **readme-documentation.md** | Organizing project documentation with README as central hub |
| **rule-conflict-protocol.md** | Two instructions or two codebase patterns requiring incompatible things — stop, log to `logs/rule-conflict-log.md`, present at least three options |
| **security-hardening.md** | Defense-in-depth patterns grounded in real-world breach analysis |
| **session-safety.md** | **CRITICAL** - Prevent session hangs and context loss on hardware systems |
| **shell-escaping.md** | Complex shell commands — quoting rules, heredocs, VS Code terminal escaping |
| **shell-scripts.md** | Directory management, error handling, and portability |
| **terraform.md** | Module structure, state management, security |
| **testing.md** | Test pyramid, mocking, CI integration, framework-specific notes |
| **typescript.md** | Strict types, functional components, error boundaries |

## Skills

Global skills in `~/.claude/skills/<name>/SKILL.md`, available in every project.

| Skill | Purpose |
| ----- | ------- |
| **explain-diff-html** | Rich, interactive HTML explanation of a code change, diff, branch, or PR |
| **explain-diff-md** | The same as a single self-contained Markdown file (fits the wiki / OKF knowledge base) |

## Onboarding Guides

| Guide | For |
| ----- | --- |
| [copilot-to-claude-code.md](./guides/copilot-to-claude-code.md) | GitHub Copilot users: mental model shift, setup, session lifecycle, permissions, commands |

## Hooks System

Hooks are shell scripts that fire on specific Claude Code events. They operate at two levels:

- **Global** (`~/.claude/settings.json`): Fire for every project. Handle session lifecycle automation.
- **Project** (`.claude/settings.local.json`): Add domain-specific checks. Layer on top of global hooks.

### Global Hooks

| Event | Hook | What It Does |
| ----- | ---- | ------------ |
| **SessionStart** | `load-handoff-context.sh` | Auto-injects the most recent `handoff-*.md` as context on new session startup. Checks project-local `.claude/session-logs/` first, then global. Skips files >7 days old. |
| **PreToolUse** | `pre-tool-safety.sh` | Blocks (exit 2) destructive operations: `git reset --hard`, `git push --force`, `git worktree remove --force`, `rm -rf`, and redirects to sensitive config files. Prompts for user confirmation before proceeding. |
| **PreCompact** | `pre-compact-memorialize.sh` | Snapshots branch, outstanding conformance items and uncommitted files before context is compacted, and steers what the summary preserves. Advisory. |
| **SessionStart** | `conformance-report.sh` | Surfaces overdue maintenance at session start — conflicts still awaiting a decision, and whether `/mine-sessions` is overdue. Runs `bin/conformance.sh`, which is deterministic and costs no tokens. Advisory; silent when nothing is overdue. |
| **SessionStart** | `account-mismatch-warn.sh` | Warns when the cwd's expected Claude account (`.account-context` marker, else git remote) does not match the logged-in oauth account. Advisory only; silent on match; needs `jq`. |
| **Stop** | `session-end-reminder.sh` | Reminds about `/session-logger` (3+ files changed) and `/handoff` (5+ files changed) when neither has been run today. Also reminds about `/lint-action-items` when an outline-format `ACTION_ITEMS.md` has items past the 7-day prune window. |

**Not currently registered:** `hooks/log-session-tokens`, a `SessionEnd` hook appending token usage to `~/.factory/token-ledger.json` keyed by `project:branch`. It is the ledger writer that `guidelines/pr-token-tracking.md` and `/pr-tokens` read from — both are inert until it is wired into `settings.json`.

**`settings.json` is deliberately gitignored** (per-host and account state), so a fresh clone has the hook *scripts* but no registration. Register them after cloning or the hooks silently never fire.

### Project Hook Types

| Event | When It Fires | Use Case |
| ----- | ------------ | -------- |
| **PostToolUse** | After Write/Edit/MultiEdit | Validate file structure, enforce data quality rules |
| **Stop** | Session ending | Domain-specific reminders (stale data, unprocessed inbox) |

### Hook Design Rules

- **Advisory by default** — most hooks warn on stderr and exit 0; PreToolUse hooks may exit 2 to block an operation and prompt the user to confirm
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

## Contributing to Guidelines

1. Update guidelines when you discover new patterns or best practices
2. Include both positive examples (do this) and negative examples (avoid this)
3. Explain the reasoning behind each guideline
4. Keep guidelines concise but comprehensive

Durable behavioral rules belong in `CLAUDE.md`, which is loaded on every turn. Reference
detail, indexes, and anything addressed to a human belong here.

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
