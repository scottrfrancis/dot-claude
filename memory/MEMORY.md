# Claude Code Memory

Durable, non-obvious facts about this config repo. Format and rules:
`guidelines/memory.md`. Freshness is checked by `bin/conformance.sh`.

Every fact ends with `[YYYY-MM-DD]` — when it was last **verified**, not when it was
written. An undated fact is treated as unverified and flagged. Optional provenance follows
the date: `[2026-08-19 · ADR-0007]`.

**This repo is public.** No personal data, addresses, credentials, or client detail — point
at `kb-mcp` or a gitignored location instead.

## Pointers

- Local infra facts (hosts, addresses, services) are not in this repo — read them from the `kb-mcp` MCP on mini: `infra` bundle for hosts/services, `home-ops` for household [2026-08-19]
- Household and personal contacts, including family email addresses and per-person preferences, live in the `home-ops` bundle behind `kb-mcp` — never inline here [2026-08-19]
- Detail on HA control specifics: [infra-ha-control](infra-ha-control.md) [2026-08-19]

## This Config Repo (`~/.claude`)

- Primary for shared doctrine; `dot-copilot`, `dot-cursor`, `dot-droid`, `dot-opencode` are downstream and receive marker-delimited blocks via `bin/doctrine.sh` [2026-08-19]
- Commands in `commands/`, guidelines in `guidelines/`, hooks in `hooks/`, tests in `tests/`, tools in `bin/` [2026-08-19]
- `CLAUDE.md` carries behavioral rules only; the annotated index lives in `README.md`, which is not loaded into context [2026-08-19]
- Session logs go in `session-logs/` at the project root — shared cross-tool location. `.claude/session-logs/` and `.factory/logs/` are legacy read-only fallbacks [2026-08-19]
- Session lifecycle: `/lets-go` → work → `/session-logger` → `/handoff` → next session `/pickup` [2026-08-19]
- Branch convention: `docs/review-YYYY-MM-DD` for doc-only changes, feature branches otherwise [2026-03-10]

## Command Conventions

- `/autocommit` stages tracked changes (`git add -u`) and commits with an AI message by default; `-all` includes untracked, `-n` confirms before each step [2026-08-19]
- `/doc-review` audits docs on a `docs/review-YYYY-MM-DD` branch, commits with `docs: review for accuracy, DRY, and clarity` [2026-03-10]
- `/extract-adr` reads both session logs and `logs/rule-conflict-log.md`; a resolved conflict entry maps onto the ADR template [2026-08-19]

## Key Design Decisions

- `git add -u` not `git add .` in autocommit — avoids staging untracked build artifacts or secrets [2026-03-10]
- `-n` is opt-in confirmation in autocommit; the common case is "commit all my changes" [2026-03-10]
- Hooks are advisory: SessionStart injects handoff context and reports conformance; Stop reminds about `/session-logger` and `/handoff`; PreToolUse warns before destructive git/rm [2026-08-19]
- `settings.json` is gitignored and carries per-host state, so a fresh clone registers no hooks at all [2026-08-19]
- The File Registry from the agentic-spec method was evaluated and rejected: it cannot drift only under one-agent, mediated-write conditions that do not hold here. Protocol lives in frontmatter instead [2026-08-19 · docs/agent-spec-alignment-review.md Part III]

## Settings Management

- `settings.json` holds broad global patterns (e.g. `Bash(git:*)`), never accumulated one-off commands [2026-03-10]
- Project-specific permissions belong in that project's `.claude/settings.local.json`; deny project-specific approvals at the global level [2026-03-10]

## Active Projects

- `catalyst-rcm-dashboard-bot` — main product, Node/TypeScript + Python backend, AWS ECS Fargate [2026-03-10]
- `m5-dial-remote` / `dial-water-heater-remote` — Arduino/M5Dial, PlatformIO + arduino-cli [2026-03-10]
- `pitch-projects/golf-club-tracking` — proposal work [2026-03-10]
- `blogs/resume` — personal site [2026-03-10]

## Patterns to Reuse

- Hook output: `jq -n --arg ctx "..." '{hookSpecificOutput: {hookEventName: "...", additionalContext: $ctx}}'` [2026-08-19]
- BSD-safe find for age: `find DIR -name "*.md" -mtime -1` — days, not minutes; `-mmin` is GNU-only [2026-03-10]
- macOS-safe: check `command -v jq` before using jq in a hook [2026-03-10]

## Retired

Facts removed once false. Kept briefly so a stale copy elsewhere can be recognised.

- ~~`commands/arch-review` (no ext) is an orphaned bash duplicate needing cleanup~~ — the file no longer exists [retired 2026-08-19]
- ~~Session logs go in `.claude/session-logs/`~~ — superseded by the cross-tool `session-logs/` root location [retired 2026-08-19]
