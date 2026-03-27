---
description: Generate session summaries with effectiveness assessment and cross-linking
argument-hint: [topic]
allowed-tools: Write, Bash, Read, Glob, Grep
---

# Session Logger

Create a comprehensive session summary and save it to the shared cross-tool session logs directory.

## Setup

Create the logs directory if it doesn't exist. Prefer `session-logs/` (shared cross-tool location); fall back to `.claude/session-logs/` if creation fails:

```bash
mkdir -p session-logs 2>/dev/null || mkdir -p .claude/session-logs
```

## Gather Context

Review the conversation history to identify what was accomplished. Also check git status and recent commits for file changes.

Arguments provided: $ARGUMENTS

## Link to Previous Session

Find the most recent session log in `session-logs/` (then `.claude/session-logs/` as fallback), excluding `mine-report-*` and `handoff-*` files. If found, add to the header:

```markdown
**Previous Session**: [filename](filename) — [one-line summary from that log's Summary section]
```

This creates a browsable chain across sessions. If no previous session log exists, omit this field.

## Generate Session Summary

Save to: `session-logs/session-YYYY-MM-DD-HHMM[-topic].md` (or `.claude/session-logs/` if `session-logs/` is unavailable).

### Required Sections

#### YAML Frontmatter (required for cross-tool compatibility)

```markdown
---
tool: claude-code
timestamp: YYYY-MM-DDTHH:MM:SS-TZ
branch: <current branch from git>
---
```

#### Header

```markdown
# Session Log: [Descriptive Title]

**Date**: YYYY-MM-DD
**Duration**: [Estimated or "continuation session"]
**Topics**: [comma-separated tags]
```

#### Summary
2-3 sentences describing the session's primary accomplishments.

#### Key Activities
Numbered list of major activities with sub-bullets for specifics. Include file paths for files created or modified.

#### Files Modified
Table format: `| File | Change |`

#### Decisions & Rationale
Numbered list of significant decisions with reasoning. Only include decisions that future sessions should know about.

#### Reusable Insights
Bullet list of patterns, lessons, or techniques that apply beyond this specific session.

### Session Effectiveness Assessment

Include a `## Session Effectiveness` section:

- **Goal achieved?** — Yes / Partial / No
- **Blockers encountered** — Obstacles that slowed progress or remain unresolved
- **Process friction** — Points where the workflow felt inefficient
- **Carry-forward items** — Specific tasks for the next session

## Reminder

If `/handoff` hasn't been run yet and 5+ files were changed, remind the user to run it before ending the session.

## Rules

- Only include sections that have content — do not generate empty sections
- File paths must be relative to the project root
- Keep the summary compact (~150 lines)
- The effectiveness assessment should be honest — partial completion or blockers are valuable data
