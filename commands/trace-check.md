# Traceability Validator

Scan the project's specification and test artifacts to validate bidirectional traceability. Produce a coverage report identifying orphans, broken links, and gaps.

## Phase 1: Discover Artifacts

Scan for each artifact type (skip categories that don't exist):

1. **Requirements**: Search for `FR-` patterns in `docs/deliverables/D1.7*`, `docs/design/SRS.md`, `docs/deliverables/*Requirements*`
2. **Feature files**: `docs/requirements/*.feature`, `docs/specs/**/*.feature`, `docs/internal/features/**/*.feature`
3. **UX screens**: `docs/design/ux-design/*.md`, `docs/design/ux-design/*.png`
4. **ADRs**: `docs/decisions/ADR-*.md`, `docs/adr/ADR-*.md`
5. **Test files**: `tests/**/*.py`, `tests/**/*.ts`, `tests/**/*.js`, `src/**/test_*.py`, `src/**/*.test.ts`
6. **Traceability matrix**: `docs/TRACEABILITY-MATRIX.md`, `docs/traceability/MATRIX.md`

Report counts for each category before proceeding.

## Phase 2: Forward Traceability (Source → Test)

### Requirements → Feature Files
- For each `FR-###` or `FR-X.X` found in requirements docs, search for a matching `@fr-###` or `@fr-X.X` tag in feature files
- Report: covered count, uncovered count, list of uncovered requirement IDs

### Feature Files → Scenarios
- For each `.feature` file, count the scenarios it contains
- Check that each scenario has at least one `@fr-*` tag
- Report: scenarios with tags, scenarios without tags

### Scenarios → Tests
- For each feature file, search for corresponding test files (by name pattern or tag)
- This is best-effort: look for test files whose name matches the feature file name, or that import/reference the feature
- Report: features with test coverage, features without

## Phase 3: Reverse Traceability (Test → Source)

### Feature Files → Requirements
- For each `@fr-*` tag in feature files, verify the referenced requirement exists in the requirements documents
- Report: valid references, dangling references (tags pointing to non-existent requirements)

### UX Screens → Requirements
- If UX screen files have FR-### references, verify they resolve
- Report coverage or note if UX-to-FR mapping doesn't exist

## Phase 4: Cross-Reference Integrity

Scan all markdown files in `docs/` for internal links (`[text](path)` and `[text](path#anchor)`):
- Verify the target file exists (relative to the source file)
- For anchor links, verify the heading exists in the target file
- Report: total links checked, broken file links, broken anchor links

## Phase 5: ADR Consistency

If ADRs exist:
- List each ADR with its Status (Proposed, Accepted, Deprecated, Superseded)
- Flag any ADR with Status: Proposed that is older than 30 days (stale proposal)
- Check if ADR files referenced in other documents actually exist

## Phase 6: Produce Report

Generate a markdown report. If the project has a `docs/` directory, save to `docs/traceability-report-YYYY-MM-DD.md`. Otherwise, print to stdout.

### Report Structure

```markdown
# Traceability Report — [Date]

## Artifact Inventory
| Type | Count | Location |
|------|-------|----------|

## Forward Traceability (Source → Test)
| Source | Target | Covered | Missing | Coverage |
|--------|--------|---------|---------|----------|

### Uncovered Requirements
[List of FR-### IDs with no feature file coverage]

### Untagged Scenarios
[List of scenarios missing @fr-* tags, with file:line]

## Reverse Traceability (Test → Source)
| Direction | Valid | Dangling | Coverage |
|-----------|-------|----------|----------|

### Dangling References
[Feature file tags pointing to non-existent requirements]

## Cross-Reference Integrity
| Total Links | Valid | Broken File | Broken Anchor |
|-------------|-------|-------------|---------------|

### Broken Links
[Source file:line → target (reason)]

## ADR Status
| ADR | Title | Status | Age | Issues |
|-----|-------|--------|-----|--------|

## Verdict
[PASS / WARN / FAIL with summary statistics]
- Forward coverage: X%
- Reverse coverage: X%
- Broken links: N
- Orphans: N
```

## Rules

- This is strictly read-only — never modify any project files
- Report what exists, not what should exist
- If a category has zero artifacts, note it as "Not found" rather than reporting 0% coverage
- Be precise about file paths in the report so findings are actionable
- For large projects (100+ feature files), summarize by directory rather than listing every file
