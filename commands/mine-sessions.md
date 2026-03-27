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
- `save` — Save the analysis report to `session-logs/mine-report-YYYY-MM-DD.md`

## Step 1: Gather Data

Read all `.md` files modified within the lookback period from these locations (check all, merge results):

1. `session-logs/` (shared cross-tool location)
2. `.claude/session-logs/` (Claude Code legacy location)
3. `.factory/logs/` (Droid legacy location)

If files have YAML frontmatter with a `tool:` field, track which tool generated each log — this enables per-tool metrics. Use file timestamps and `**Date**:` frontmatter. Count total sessions, list topics by filename keywords.

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

## Step 4: Guideline Coverage Gap

If `docs/guidelines/` exists, read all guideline files to know the current rule set.

Cross-reference each "Reusable Insight" and "Reinforced Pattern" from Step 3 against the guidelines:

- If an insight appears in 2+ sessions but is NOT in any guideline file — **flag as candidate rule** with the recommended guideline file to add it to
- If an insight IS already in a guideline file — note as "already codified"
- If a decision appears significant but isn't in `docs/adr/` — **flag as ADR candidate**

This is the highest-value output — it closes the loop between daily session work and the project's accumulated rules.

## Step 5: Actionable Recommendations

Based on all analysis, generate prioritized recommendations:

1. **Guideline gaps** — insights that should be added to `docs/guidelines/` (from Step 4)
2. **ADR candidates** — decisions that should be formalized in `docs/adr/`
3. **Pattern codification** — if a pattern appears in 3+ sessions but isn't documented anywhere, recommend where to add it
4. **Process gaps** — session logs mentioning the same problem repeatedly without a fix
5. **Tool or skill opportunities** — repetitive tasks that could be automated with a new command or hook
6. **Session effectiveness trends** — are blockers becoming more or less frequent? Are goals being achieved?

## Step 6: Output

Present the report with clear section headers and tables. If `save` was specified in arguments, write the full report to `session-logs/mine-report-YYYY-MM-DD.md` (fallback: `.claude/session-logs/mine-report-YYYY-MM-DD.md`).

## Rules

- Use only data from session logs and memory files — do not fabricate metrics
- When calculating rates, show both ratio and raw numbers
- Round percentages to whole numbers
- If a section has fewer than 3 data points, note this and skip statistical claims
- Always end with the actionable recommendations section
- Keep the report scannable — use tables over long prose
