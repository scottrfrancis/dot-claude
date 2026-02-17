# Project Setup Guideline

When starting a new project with Claude Code, use this tiered checklist to bootstrap the right level of infrastructure. Not every project needs full lifecycle tooling — match the investment to the project's complexity and duration.

## How to Choose a Tier

- **Tier 1** — Any project you'll work on for more than one session. Takes 5 minutes.
- **Tier 2** — Projects with ongoing work: multiple sessions, collaboration, or evolving requirements. Takes 15 minutes.
- **Tier 3** — Projects with repeatable domain workflows, measurable outcomes, or multi-step processes that benefit from automation. Build incrementally as patterns emerge.

## Global Hooks (Inherited by All Projects)

These hooks are registered in `~/.claude/settings.json` and fire for every project automatically:

| Hook | Event | What it does |
| ---- | ----- | ------------ |
| `~/.claude/hooks/load-handoff-context.sh` | SessionStart | Auto-injects the most recent handoff file as context on new session startup |
| `~/.claude/hooks/session-end-reminder.sh` | Stop | Reminds about `/session-logger` and `/handoff` when 3+ files changed |

Project-local hooks in `.claude/settings.local.json` layer **on top of** these global hooks — they don't replace them.

## Tier 1: Foundation (All Projects)

- [ ] Create `CLAUDE.md` at project root with: role definition, tone guidance, repository structure overview, key commands or workflows
- [ ] Create `.claude/memory/MEMORY.md` as a context index — even a 5-line file linking to key docs saves context in future sessions
- [ ] Create `.claude/session-logs/` directory — needed for handoff context auto-loading (global SessionStart hook looks here)
- [ ] Verify global commands work (`/lets-go`, `/session-logger`) — these are in `~/.claude/commands/` and require no per-project setup
- [ ] Document branch policy in `CLAUDE.md` if different from the default (e.g., "always work on feature branches, never commit to main directly")

### Tier 1 Directory Structure

```
project/
  CLAUDE.md
  .claude/
    memory/
      MEMORY.md
```

## Tier 2: Tracked Projects

Everything from Tier 1, plus:

- [ ] Create `.claude/settings.local.json` with project-specific permissions (WebFetch domains, tool access, additional directories)
- [ ] Create `.claude/session-logs/` directory for session history
- [ ] Add project-specific hooks if needed — the global Stop hook already covers generic session-end reminders; project hooks add domain-specific checks (e.g., filtering by important file paths, stale data alerts)
- [ ] Run `/lets-go` to verify context loading and sync protocol work correctly
- [ ] Register any project-specific hooks in `.claude/settings.local.json` under the `hooks` key

### Tier 2 Directory Structure

```
project/
  CLAUDE.md
  .claude/
    memory/
      MEMORY.md
    settings.local.json
    session-logs/
    hooks/
      session-end-reminder.sh
```

### Hook Registration Pattern

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-end-reminder.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

## Tier 3: Domain-Specific Lifecycle

Everything from Tier 2, plus these as needed:

- [ ] Custom skills in `.claude/skills/` for repeating workflows (e.g., `/new-lead`, `/archive-lead`)
- [ ] Outcome tracking file (like `WINS.md`) if the project has measurable cycles with success/failure signals
- [ ] Pattern memory file (like `application-patterns.md`) for learned heuristics that should persist across sessions
- [ ] Validation hooks (PostToolUse) for data quality on critical files
- [ ] Domain-specific memory files linked from `MEMORY.md` (e.g., `career-context.md`, `hiring-manager-concerns.md`)

### Tier 3 Directory Structure

```
project/
  CLAUDE.md
  .claude/
    memory/
      MEMORY.md
      domain-context.md
      learned-patterns.md
    settings.local.json
    session-logs/
    hooks/
      session-end-reminder.sh
      validate-critical-file.sh
    skills/
      workflow-name/
        SKILL.md
```

### When to Add Tier 3 Components

Add these incrementally, not all at once:

- **Custom skills**: When you find yourself repeating the same multi-step workflow 3+ times
- **Outcome tracking**: When the project has a measurable feedback loop (applications, deployments, experiments)
- **Pattern memory**: When you notice the same lessons being re-learned across sessions
- **Validation hooks**: When a critical file has a required structure that's easy to break

## Reference Implementation

The resume project at `/Volumes/workspace/blogs/resume/` is the most complete Tier 3 implementation, with:

- 4 custom skills (`new-lead`, `continue-lead`, `process-questionnaire`, `archive-lead`)
- 4 memory files (career context, hiring concerns, application patterns, index)
- 2 hooks (WINS.md validation, session-end reminders with stale alerts)
- Outcome tracking via `WINS.md` with pattern learning feedback loop
- Full session logging with cross-linking and handoff support

## Common Patterns to Reuse

### Stop Hook Template

The session-end-reminder pattern works for any project — just change the file path filter on line 21 to match your project's important directories:

```bash
APP_CHANGES=$(echo "$ALL_CHANGES" | grep -E "^(your/important/paths/)" || true)
```

### Memory Index Template

Start every `MEMORY.md` with:

```markdown
# Project Memory Index

## Key Context
[2-3 sentences about what this project is and current priorities]

## Linked Files
- [topic.md](topic.md) — description
```

### Settings Template

Minimum `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

Add permissions as needed rather than pre-allowing everything.
