---
description: Generate session summaries with effectiveness assessment and cross-linking
argument-hint: [topic]
allowed-tools: Write, Bash, Read, Glob, Grep
---

# Session Logger

Create a comprehensive session summary and save it to `.claude/session-logs/` with proper organization.

## Setup

Create the session logs directory if it doesn't exist:

!mkdir -p .claude/session-logs

## Gather Context

Review the conversation history to identify what was accomplished. Also check git status and recent commits for file changes.

Arguments provided: $ARGUMENTS

## Link to Previous Session

Find the most recent session log in `.claude/session-logs/` (excluding `mine-report-*` and `handoff-*` files). If found, add to the header:

```markdown
**Previous Session**: [filename](filename) — [one-line summary from that log's Summary section]
```

This creates a browsable chain across sessions. If no previous session log exists, omit this field.

## Generate Session Summary

Save to: `.claude/session-logs/YYYY-MM-DD-HHMM${topic:+-$topic}.md`

### Required Sections

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
Bullet list of patterns, lessons, or techniques that apply beyond this specific session. Must be genuinely novel — not restatements of existing patterns in `.claude/memory/`.

### Session Effectiveness Assessment

Include a `## Session Effectiveness` section:

- **Goal achieved?** — Yes / Partial / No
- **Blockers encountered** — Obstacles that slowed progress or remain unresolved
- **Process friction** — Points where the workflow felt inefficient or manual steps could be automated
- **Carry-forward items** — Specific tasks for the next session

## Rules

- Only include sections that have content — do not generate empty sections
- File paths must be relative to the project root
- Keep the summary compact (~100 lines). The verbose 250+ line format is deprecated.
- The "Reusable Insights" section should contain genuinely novel observations
- The effectiveness assessment should be honest — partial completion or blockers are valuable data
