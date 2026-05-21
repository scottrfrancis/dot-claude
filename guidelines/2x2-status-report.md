# 2x2 Weekly Status Report

Quad-chart format for short, recurring status updates. Originally surfaced for the Damar engagement's Thursday status report (copy/paste into a Google Doc), but applicable to any short weekly write-up where the goal is "one screen, four boxes, ship it."

## Format

A 2x2 *conceptually* — four quadrants of equal weight — rendered in the document as **four H2 sections with bullets, in this order**: Last week → This week → Risks → Asks.

```markdown
## Last week
- ...
- ...
- ...

## This week
- ...
- ...
- ...

## Risks
- ...
- ...
- ...

## Asks
- ...
- ...
- ...
```

**~3 bullets per section**, fragment-style. One screen total when rendered.

### Why not a literal table

Tried it on 2026-05-21. A markdown 2x2 table with `<br>` line breaks pasted via Google Docs' "Paste from Markdown" splits each `<br>` into its own row — turning a 4-cell 2x2 into ~16 rows of fragmented sentences with most cells empty. **Do not use a literal markdown table.** The hierarchical-section form pastes cleanly and reads the same.

### Pasting into Google Docs

In Google Docs: **Tools → Preferences → Enable Markdown** (one-time). Then for each paste: **right-click → "Paste from Markdown"** (or Edit menu). Plain Ctrl/⌘+V leaves it as raw text — must be the right-click path. No keyboard shortcut as of mid-2026.

With Paste-from-Markdown on, the H2 sections render as Google Docs headings and the bullets render as native lists.

## Conventions

- **Short bullets, not sentences.** Imagine reading on a phone. Verb-first fragments.
- **Asks must be actionable for someone else.** Name the person if relevant, name the artifact or decision needed, give a due date if there is one. "Awaiting feedback" is not an Ask; "Need Ryan's sign-off on Option B by Tuesday" is.
- **Risks describe uncertainty, not history.** If something is now resolved, it belongs in *Last week* as a win, not in Risks.
- **No headers, no preamble, no trailer.** The 2x2 is the document. Don't wrap it in prose. The reader scans the four boxes and is done.
- **No metrics chart** in the 2x2. If a metric is essential, name it in a bullet (one number, one delta — e.g. "GCS feed restored, +180 chunks/day"). For data-heavy weekly review, that's a separate format (the canonical WBR — see Origin below).

## Cadence

- Weekly, default Thursday.
- Copy/paste into a Google Doc the client/PM maintains. Don't add commentary outside the grid.

## Origin and disambiguation

This format is **not** the canonical Amazon Weekly Business Review (WBR). The WBR is a 30–60 minute meeting walking through 6–12 graphs and tables in a fixed visual language; it is data-review, not narrative. Cedric Chin's deep-dive at [commoncog.com](https://commoncog.com/the-amazon-weekly-business-review/) is authoritative on the WBR proper.

The 2x2 status report is a **quad-chart status summary** — a separate tradition shared across Solutions Architect and consulting orgs (Cisco, IBM, defense/gov consultancies). It is WBR-*influenced* in cadence (regular synthesis) and discipline (no rambling), but the layout and weight are quad-chart, not WBR.

The "Amazon 2x2" attribution appears in some second-hand sources (e.g. a Scribd template) but doesn't show up in primary WBR documentation — likely a conflation. When users say "Amazon 2x2," they usually mean *this* format: a quad-chart summary done at a WBR-style cadence.

## When to use vs. not use

**Use the 2x2 when:**
- Weekly cadence, single stakeholder or small group reads it.
- The reader wants synthesis, not data.
- The writer needs a hard constraint to keep the update from sprawling.

**Use something else when:**
- The reader wants the data (then do a WBR-style metrics review with 6-12 graphs).
- The cadence is daily (then a stand-up note, not a structured doc).
- The audience is hostile or unfamiliar (then a 1-pager narrative with context).

## References

- [The Amazon Weekly Business Review — Cedric Chin / Commoncog](https://commoncog.com/the-amazon-weekly-business-review/) — authoritative on what the canonical WBR is (and is not a 2x2).
- [Mastering Weekly Business Reviews — Paul Duvall](https://www.paulmduvall.com/mastering-weekly-business-reviews-insights-from-amazons-iconic-wbr/) — notes the 2x2-style summarization some teams use alongside WBR.
- [Quad Chart definition & templates — LeanDataPoint](https://leandatapoint.com/resources/quad-chart) — generic quad-chart anatomy and history.
- [Decoding ABCD Reporting in Project Management — ProjectManagement.com](https://www.projectmanagement.com/blog-post/24696/decoding-abcd-reporting-in-project-management) — alternative quad-chart variant (Accomplishments / Better-still / Concerns / Direction).

## Discovery context

Format confirmed by Scott Francis on 2026-05-21 during the Damar engagement; per Scott, the layout came from a Solutions Architect group, possibly Cisco-rooted. Live search did *not* find a canonical Cisco SA spec, but the quadrant labels (Last week / This week / Risks / Asks) match the SA-org status-report pattern that's common across multiple firms.

Hierarchical-section rendering chosen (over literal 2x2 markdown table) after the first paste-into-Google-Docs attempt that same day shredded the table on import. Section form is functionally identical (same four quadrants, same content) and survives the paste cleanly.
