# Claude Code Memory

- [infra-ha-control](infra-ha-control.md) — control HA via REST/WS API + token (not just InfluxDB reads); govee2mqtt on mini (api-key-only, Govee 454); B-hyve "Smart Outdoor Timer"

## Personal / Contacts

- **Linda** — Scott's wife. Email: `lindasfrancis88@gmail.com`. Address deliverables meant for her by name. For home-equipment decisions her priority is time + dependability/predictability (see HomeAssistant project memory `user-slo-household`).

## This Config Repo (~/.claude)

- Global config for all projects. Commands in `commands/`, guidelines in `guidelines/`, hooks in `hooks/`
- Active branch convention: `docs/review-YYYY-MM-DD` for doc-only changes, feature branches for everything else
- Session lifecycle: `/lets-go` → work → `/session-logger` → `/handoff` → next session `/pickup`
- Session logs go in `.claude/session-logs/` (project-local) or `~/.claude/session-logs/` (global fallback)

## Command Conventions

- `/autocommit` stages tracked changes (`git add -u`) and commits with AI message by default; `-all` to include untracked; `-n` to confirm before each step
- `/doc-review` audits docs on a `docs/review-YYYY-MM-DD` branch, commits with `docs: review for accuracy, DRY, and clarity`
- `/arch-review` is the skill; `commands/arch-review.md` is the skill definition; `commands/arch-review` (no ext) is an old bash duplicate — see orphaned commands note below

## Key Design Decisions

- `git add -u` not `git add .` in autocommit — avoids accidentally staging untracked files (build artifacts, secrets)
- `-n` flag for confirmation in autocommit (default is commit immediately) — common case is "commit all my changes"
- Hooks are advisory-only: SessionStart injects handoff context; Stop reminds about /session-logger and /handoff
- PreToolUse hook (`hooks/pre-tool-safety.sh`) warns before destructive git/rm operations

## Settings Management

- `settings.json` should have broad global patterns (e.g., `Bash(git:*)`) — NOT specific accumulated one-off commands
- Project-specific permissions belong in `.claude/settings.local.json` per project
- When Claude asks to approve a command that is project-specific, deny it at the global level and add it to project-level settings instead

## Active Projects (as of 2026-03-10)

- `catalyst-rcm-dashboard-bot` — main product, Node/TypeScript + Python backend, AWS ECS Fargate
- `m5-dial-remote` / `dial-water-heater-remote` — Arduino/M5Dial hardware projects, PlatformIO + arduino-cli
- `pitch-projects/golf-club-tracking` — proposal work
- `blogs/resume` — personal site

## Orphaned Commands (needs cleanup)

- `commands/arch-review` (no ext) — appears to be a bash variant; `arch-review.md` is the canonical skill; safe to delete

## Patterns to Reuse

- Hook output format: `jq -n --arg ctx "..." '{hookSpecificOutput: {hookEventName: "...", additionalContext: $ctx}}'`
- BSD-safe find for age: `find DIR -name "*.md" -mtime -1` (days, not minutes — `-mmin` is GNU-specific)
- macOS-safe fallback: check `command -v jq` before using jq in hooks
