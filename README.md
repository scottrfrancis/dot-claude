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
│   ├── session-status.sh        # SessionStart: point at drift, handoffs, timers (bin/session-status.sh)
│   ├── pre-tool-safety.sh       # PreToolUse: block destructive git/rm/config writes
│   └── session-end-reminder.sh  # Stop: remind once per session about /session-logger and /handoff
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
│   ├── session-cleanup          # NPU/GPU box only: kills every Claude process (--kill-all-claude)
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
| **session-cleanup** | `session-cleanup --kill-all-claude` | Dedicated NPU/GPU box only. Kills every Claude process on the machine, then cleans device handles and shared memory. Refuses without the flag |
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

Topic guidelines are skills: each lives in `skills/<name>/SKILL.md`, and `guidelines/<name>.md` is a symlink to it, so every path below still resolves. Claude Code lists each skill by its description and loads it when the work matches. `hooks/skill-gate.py` makes that reliable for the file types it knows: the first `.py`, `.sh`, Markdown, Dockerfile (and so on) write of a session, and the first commit or push, wait until the governing skill is loaded. Skill names are lowercase, so `C4-diagramming.md` is the `c4-diagramming` skill and `2x2-status-report.md` is `status-report-2x2`.

Five stay plain guidelines, read when something points at them: `central-ops-knowledge`, `beaufort-todo-announcements` and `environments-and-llm-spend` (homelab doctrine), `session-safety` (opt-in, one kind of host) and `memory`.

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
| **session-safety.md** | Opt-in, dedicated NPU/GPU boxes only: device contention between sessions |
| **shell-escaping.md** | Complex shell commands — quoting rules, heredocs, VS Code terminal escaping |
| **shell-scripts.md** | Directory management, error handling, and portability |
| **terraform.md** | Module structure, state management, security |
| **testing.md** | Test pyramid, mocking, CI integration, framework-specific notes |
| **typescript.md** | Strict types, functional components, error boundaries |

## Skills

Global skills live in `skills/<name>/SKILL.md`. The topic guidelines above are skills too, hidden from the `/` menu with `user-invocable: false`.

Claude Code loads skills from the active config dir: `~/.claude`, or `$CLAUDE_CONFIG_DIR`. A profile config dir (`~/.claude-profiles/<p>/.claude`, `~/.claude-ailab`) symlinks parts of this repo but not `skills/`, so no repo skill loads there until it is linked. `bin/link-config.sh` adds one link per skill, plus `bin/`, to every config dir whose `CLAUDE.md` links here. It is a dry run unless given `--apply`, and it never replaces what it did not create. Re-run it after adding or removing a skill. `bin/session-status.sh` reports a config dir with missing links.

| Skill | Purpose |
| ----- | ------- |
| **explain-diff-html** | Rich, interactive HTML explanation of a code change, diff, branch, or PR |
| **explain-diff-md** | The same as a single self-contained Markdown file (fits the wiki / OKF knowledge base) |

## Onboarding Guides

| Guide | For |
| ----- | --- |
| [copilot-to-claude-code.md](./guides/copilot-to-claude-code.md) | GitHub Copilot users: mental model shift, setup, session lifecycle, permissions, commands |

## Hosts

CLAUDE.md holds the rules that apply everywhere. What a host adds comes from `~/.claude/host.md`, which CLAUDE.md imports and git ignores. On the homelab hosts (Studio, razer, hasami, dev.local) it holds one line:

```text
@~/.claude/doctrine/homelab.md
```

That file carries the homelab names (the local model and the dev host), time tracking, Beaufort announcements, and the central ops knowledge block. The rules that must hold everywhere stay in CLAUDE.md: paid models and prod promotion only on request, and the design-pattern block. `bin/doctrine.sh` copies both doctrine blocks to the downstream dot-repos, each from whichever of the two files carries it. A host outside the homelab leaves `host.md` empty. Claude Code skips a missing import silently, so `bin/session-status.sh` reports a missing `host.md`, and any import in it that does not resolve.

To set up a homelab host:

1. Clone this repo to `~/.claude`, or link it there.
2. Create `host.md` in the checkout itself: `printf '@~/.claude/doctrine/homelab.md\n' > <checkout>/host.md`. On a host with swapped-HOME profiles, `~/.claude` inside a profile is the profile's own directory, so a file written there reaches only that profile.
3. Register the hooks (see Hook Registration Pattern below), and set `"cleanupPeriodDays": 90` in `settings.json` so transcripts last long enough for `/mine-sessions` and usage reviews.
4. On a host with profiles, run `<checkout>/bin/link-config.sh`, then again with `--apply`. Use the full path: a profile has no `~/.claude/bin` until link-config has run. It links `host.md`, `doctrine/`, `memory/`, `bin/` and every skill into each profile.
5. Start a session. The status block should be silent, and `/memory` should list `host.md` and `doctrine/homelab.md`.

## Hooks System

Hooks are shell scripts that fire on specific Claude Code events. They operate at two levels:

- **Global** (`~/.claude/settings.json`): Fire for every project. Handle session lifecycle automation.
- **Project** (`.claude/settings.local.json`): Add domain-specific checks. Layer on top of global hooks.

### Global Hooks

| Event | Hook | What It Does |
| ----- | ---- | ------------ |
| **SessionStart** | `session-status.sh` | Runs `bin/session-status.sh --hook` on `startup` and `clear`. Points at what needs attention and is silent otherwise: drift on dot-claude, the downstream dot-repos, the project and its nested repos (no fetch); handoffs from the last 7 days, without reading or moving them; an open `punch` timer; hooks missing from `settings.json`; overdue conformance items; stale `ACTION_ITEMS.md` entries; and the output of an executable `.claude/session-start.sh` in the project. `load-handoff-context.sh` is a deprecated alias for it. |
| **PreToolUse** | `pre-tool-safety.sh` | Blocks (exit 2) destructive operations: `git reset --hard`, `git push --force`, `git worktree remove --force`, `rm -rf`, and redirects to sensitive config files. Prompts for user confirmation before proceeding. |
| **PreCompact** | `pre-compact-memorialize.sh` | Snapshots branch, outstanding conformance items and uncommitted files before context is compacted, and steers what the summary preserves. Advisory. |
| **SessionStart** | `account-mismatch-warn.sh` | Warns when the cwd's expected Claude account (`.account-context` marker, else git remote) does not match the logged-in oauth account. Advisory only; silent on match; needs `jq`. |
| **PreToolUse** | `skill-gate.py` | Holds the first write of a governed file type (`.py`, `.go`, `.ts`, `.sh`, `.tf`, Dockerfile, tests, Markdown, workflows, `.puml`, ADRs), and the first `git commit` or `push`, until the governing skill is loaded through the Skill tool or a Read of its `SKILL.md`. Asks at most twice per skill per session. Off with `CLAUDE_SKILL_GATE=off` or a project `.claude/skill-gate-off`. |
| **PostToolUse** | `prose-check.py` | After a Markdown write, checks the mechanical prose rules: the dash budget `max(2, lines/40)`, the corrective frame on added lines, and bold density. Judges only what the write added, and returns findings to the model (exit 2). A file containing `prose-check: off` is skipped. |
| **Stop** | `session-end-reminder.sh` | Stop fires after every reply, so this speaks once per session: it reminds about `/session-logger` (3+ files changed) and `/handoff` (5+ files changed) when neither has been run today. Also reminds about `/lint-action-items` when an outline-format `ACTION_ITEMS.md` has items past the 7-day prune window. |

**Not currently registered:** `hooks/log-session-tokens`, a `SessionEnd` hook appending token usage to `~/.factory/token-ledger.json` keyed by `project:branch`. It is the ledger writer that `guidelines/pr-token-tracking.md` and `/pr-tokens` read from — both are inert until it is wired into `settings.json`.

**`settings.json` is deliberately gitignored** (per-host and account state), so a fresh clone has the hook *scripts* but no registration. Register them after cloning or the hooks silently never fire.

### Project Hook Types

| Event | When It Fires | Use Case |
| ----- | ------------ | -------- |
| **PostToolUse** | After Write/Edit/MultiEdit | Validate file structure, enforce data quality rules |
| **Stop** | Session ending | Domain-specific reminders (stale data, unprocessed inbox) |

### Hook Design Rules

- **Advisory by default** — most hooks warn on stderr and exit 0; PreToolUse hooks may exit 2 to block an operation and prompt the user to confirm
- **Fast** — no network calls, no heavy computation. `timeout` is in seconds: 10 is plenty for a local check (a registered `5000` is 83 minutes)
- **Defensive** — `set -euo pipefail`, drain stdin with `cat > /dev/null` or `jq`, guard all greps with `|| true`
- **Context injection** — SessionStart hooks can output JSON with `additionalContext` to inject text into Claude's context

### Hook Registration Pattern

`settings.json` is gitignored, so each host registers its own hooks. The global set:

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "^(startup|clear)$",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/session-status.sh", "timeout": 30 }] },
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/account-mismatch-warn.sh", "timeout": 10 }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-tool-safety.sh", "timeout": 10 }] },
      { "matcher": "Write|Edit|MultiEdit|Bash|Read|Skill",
        "hooks": [{ "type": "command", "command": "python3 ~/.claude/hooks/skill-gate.py", "timeout": 10 }] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit|MultiEdit",
        "hooks": [{ "type": "command", "command": "python3 ~/.claude/hooks/prose-check.py", "timeout": 10 }] }
    ],
    "PreCompact": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-compact-memorialize.sh", "timeout": 30 }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/session-end-reminder.sh", "timeout": 10 }] }
    ]
  }
}
```

Keep host-specific entries (herdr, iTerm status) alongside these. A project adds its own in `.claude/settings.local.json`, with paths relative to the project.

## Contributing to Guidelines

1. Update guidelines when you discover new patterns or best practices
2. Include both positive examples (do this) and negative examples (avoid this)
3. Explain the reasoning behind each guideline
4. Keep guidelines concise but comprehensive

Durable behavioral rules belong in `CLAUDE.md`, which is loaded on every turn. Reference
detail, indexes, and anything addressed to a human belong here.

## Setting Up a New Project

Follow `guidelines/project-setup.md` for the full checklist. The short version:

**Tier 1 (all projects):** Create `CLAUDE.md` at project root, `.claude/memory/MEMORY.md` for persistent context, and `session-logs/` for session logs and handoffs. Global commands (`/lets-go`, `/session-logger`, `/handoff`, `/pickup`) and global hooks (the session-start status, Stop reminders) work immediately with no per-project setup.

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

## Cross-Tool Session Protocol

Session logs are written to `session-logs/` at the project root — a shared location accessible by Claude Code, Cursor, Copilot, and Droid. Legacy locations (`.claude/session-logs/`, `.factory/logs/`) are searched as fallbacks.

All session logs and handoff files include YAML frontmatter with a `tool:` field (e.g., `tool: claude-code`) so any receiving tool knows the source. This enables cross-tool session continuity — a handoff written in Cursor can be picked up by Claude Code, and vice versa.

## Conformance Tooling

Deterministic shell checks under `bin/`, no model tokens. Each has a suite in `tests/`, and
`.github/workflows/validate.yml` runs them on every push.

- `bin/conformance.sh --project . --quiet` - the entry point: reports conflicts awaiting a
  decision and whether `/mine-sessions` is overdue. `/lets-go` runs it as a session-start probe.
- `bin/doctrine.sh check|sync` - propagate marker-delimited doctrine blocks from this repo to the
  downstream `dot-*` repos listed in `doctrine/targets.conf`. dot-claude is primary; downstream
  copies are replaced from it and are never a source.
- `bin/check-glossary.sh`, `bin/check-conflict-log.sh`, `bin/check-public-memory.sh`,
  `bin/memory-scope.sh` - the individual tiers.

## Changelog

- 2026-11-25: Port the findings of a laptop fork's audit. CLAUDE.md drops from 27KB to about 4KB of
  rules: homelab rules and the central ops block move to `doctrine/homelab.md`, imported through a
  gitignored per-host `host.md`, while the paid-model and prod rules and the design-pattern block
  stay in CLAUDE.md so no host can lose them. The command index, hooks, tooling and this
  changelog live here. `memory/MEMORY.md` is pruned to facts recorded nowhere else and imported, so it loads.
  Absolute wording (REQUIRED, CRITICAL, "you do not have another exception") becomes rules with
  reasons. Earlier in the same port: `bin/session-status.sh` replaced the duplicated session
  probes, handoffs became pointers, `session-cleanup` stopped killing every session, and 31
  topic guidelines became skills with a skill gate and a prose check.

- 2026-09-19: Take the additive half of the agent-spec work (PR #12, open since 2026-08-18): the
  conformance tooling under `bin/` with seven test suites and a CI workflow, the rule-conflict /
  memory-scope / glossary guidelines, `/memorialize`, and two hooks. Its 245-line CLAUDE.md
  restructure was dropped: it predated the always-on prose style and the ingest-hygiene
  guideline, and replaying it would have fought newer work. Closed PR #11 (`/b` -> `/punch`) as
  superseded -- that rename reached main another way


- 2026-09-10: Prose style adds three sections from a reader's feedback on the eval-spend series: the corrective frame and its disguises, plain register (no epigram kickers, staged reveals or fragment runs), and concrete nouns (an abstract-noun watch list, with "edge" first). Adds the principle that a rule names a move, so rewording the move keeps the tell, plus a candidate-finder grep and a noun counter. `/editorial-review` audits for all three. Propagated to dot-cursor, dot-droid, dot-copilot and dot-opencode, which were still on the text from before 2026-09-02

- 2026-09-02: Prose style becomes **always on, all written output**, and the "does not apply to technical documentation" exemption is removed. That exemption let one knowledge bundle reach 2,190 em-dashes across 56 files before it was noticed. Adds a testable em-dash threshold, a **state-what-is** rule (documents do not narrate their own edit history), and bold discipline

- 2026-08-31: House style for environments + the LLM spend gate — Studio works, dev.local is dev AND staging, prod only on explicit promotion; dev-ai.local for all smoke/functional tests, cloud LLMs gated on an explicit ask

- 2025-01-31: Initial setup with shell script guidelines
- 2026-02-17: Establish as pure base class — remove project-specific content, document extension pattern
- 2026-03-10: Add PreToolUse safety hook; create MEMORY.md; clean up settings.json; document checkpoint-progress and extract-adr
- 2026-03-10: Add guides/ directory; copilot-to-claude-code.md onboarding guide
- 2026-03-11: Add /review-pr and /babysit-pr commands; add testing guideline
- 2026-03-27: Cross-tool session sync — session-logs/ as shared primary location, YAML frontmatter with tool: field, multi-location search in all commands/hooks, project docs integration (docs/guidelines/, docs/adr/, AGENTS.md) in review commands
- 2026-05-11: Add surface-conflicts global rule; karpathy-principles "read before you write" delta; testing.md "tests must be able to fail" section; prototype-hygiene.md "fail loud" rule
- 2026-05-21: Add 2x2-status-report guideline (quad-chart weekly status; disambiguates from canonical Amazon WBR)
- 2026-08-13: Completeness audit — index 8 previously undocumented guidelines/commands, add a Skills section, document the `account-mismatch-warn` hook and the unregistered `log-session-tokens`, note that gitignored `settings.json` means a fresh clone has no hook registration
- 2026-06-30: Add `/b` command + time-tracking touchpoints in `/lets-go`, `/session-logger`, `/handoff` (remind-don't-auto policy); local `b` time-tool on studio-3 → `time-push` → hasami ingest (`bronze.time_entry`, `task_raw`)
- 2026-08-14: Rename `b` → `punch` (`b` kept as a symlink); fix the tracker-detection snippet in all three commands — the macOS-only `dscl` lookup returned empty under a sandbox and reported "not installed" on a host that had it. Now tries `getent` then `dscl`, and treats an empty home as not-found rather than building `/bin/punch`. Installed on dev.local
