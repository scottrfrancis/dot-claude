---
description: Analyze session logs for patterns, metrics, and process improvements
argument-hint: [days:N] [save]
allowed-tools: Read, Bash, Write, Glob, Grep
---

# Mine Session Logs

Analyze session logs to extract patterns, quantitative metrics, and actionable feedback for improving development workflows.

## Arguments

Parse `$ARGUMENTS` for:

- `days:N` — Look back N days (default: 30)
- `save` — Save the analysis report to `.claude/session-logs/mine-report-YYYY-MM-DD.md`

## Step 1: Gather Data

Read all `.md` files in `.claude/session-logs/` modified within the lookback period. Use file timestamps and `**Date**:` frontmatter. Count total sessions, list topics by filename keywords.

## Step 2: Session Metrics

Present:

- Total sessions in period and sessions per week (activity cadence)
- Most common topics (by filename keyword parsing)
- Process changes timeline (skill updates, pattern file changes, memory updates extracted from logs)

## Step 3: Pattern Analysis

Extract from session logs:

- All entries under "Reusable Insights" or "Reusable Patterns" sections — deduplicate by theme
- Patterns that appear in 2+ sessions (reinforced patterns)
- Decisions that were later revisited or contradicted
- Recurring process friction points from "Session Effectiveness" sections

## Step 4: Actionable Recommendations

Based on all analysis, generate prioritized recommendations:

1. **Pattern codification** — if a pattern appears in 3+ sessions but isn't documented in memory files, recommend adding it
2. **Process gaps** — session logs mentioning the same problem repeatedly without a fix
3. **Guideline updates** — newly discovered practices that should become standards
4. **Tool or skill opportunities** — repetitive tasks that could be automated with a new command or hook
5. **Session effectiveness trends** — are blockers becoming more or less frequent? Are goals being achieved?

## Step 5: Output

Present the report with clear section headers and tables. If `save` was specified in arguments, write the full report to `.claude/session-logs/mine-report-YYYY-MM-DD.md`.

## Rules

- Use only data from session logs and memory files — do not fabricate metrics
- When calculating rates, show both ratio and raw numbers
- Round percentages to whole numbers
- If a section has fewer than 3 data points, note this and skip statistical claims
- Always end with the actionable recommendations section
- Keep the report scannable — use tables over long prose
