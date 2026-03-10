---
description: Review project documentation for accuracy, DRY, clarity, and new-member accessibility; commit on a docs branch
argument-hint: (no arguments needed)
allowed-tools: Read, Bash, Glob, Grep, Write, Edit, Git
---

Audit and improve this project's documentation, then commit changes on a dedicated branch.

## Phase 1 — Inventory

Find all documentation files in this priority order:

1. `README.md` (root)
2. `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CHANGELOG.md` (root, whichever exist)
3. `docs/**/*.md` (recursive)

Exclude: `node_modules/`, `.git/`, `.claude/session-logs/`, `.claude/memory/`, any generated or vendored directory.

List the files found and their count before proceeding. If more than 20 files are found,
note that lower-priority files may be skipped if context runs short.

## Phase 2 — Gather code ground truth

Before reading any docs, collect the facts you'll use to verify accuracy:

- Scripts and commands: read `package.json` (scripts section), `Makefile`, `pyproject.toml`, or equivalent
- Directory structure: `ls -1` at the repo root and any key subdirectories mentioned in docs
- Config files referenced in docs: `.env.example`, `docker-compose.yml`, etc.

This is your source of truth for cross-referencing. Do not rely on what docs say — verify against the code.

## Phase 3 — Review and edit each file

Work through each file in priority order. Apply these criteria:

### Accuracy — cross-reference against Phase 2 facts

- File paths mentioned in docs: do they exist?
- Commands and scripts: do they match the actual scripts in `package.json` / `Makefile` / etc.?
- Architecture descriptions: do they match the actual directory structure?
- Prerequisite versions: are they current and consistent across files?

Fix what you can verify. If accuracy is uncertain, add an inline comment `<!-- TODO: verify -->` and note it in the final summary — do not silently remove or guess.

### DRY — eliminate duplication across files

- Identical or near-identical setup steps, prerequisites, or explanations duplicated across files
- Consolidate: keep the content in the most appropriate file, replace duplicates with a cross-reference link
- Note what was merged and where in the final summary

### History narration — remove it

Git handles history. Remove:

- "We used to...", "Previously...", "As of v2...", "This replaced..."
- Changelog-style entries inside README or ARCHITECTURE
- Motivation paragraphs for past decisions that are no longer relevant

Keep: rationale for current decisions that isn't obvious from the code.

### Clarity and new-member accessibility

- Is there a clear "start here" or getting-started path near the top of README?
- Are prerequisites listed before they're needed?
- Are project-specific acronyms or terms defined on first use?
- Are code blocks fenced with the correct language identifier (` ```bash `, ` ```json `, etc.)?
- Are section headings descriptive — not just "Overview" or "Notes" with opaque content?

### Do not

- Rewrite content when technical accuracy is uncertain — flag it instead
- Change meaning, only improve clarity and structure
- Edit `.claude/`, `session-logs/`, generated files, or `CHANGELOG.md` entries (that file is history by design)

## Phase 4 — Commit

1. Determine today's date (YYYY-MM-DD format)
2. Create branch: `git checkout -b docs/review-YYYY-MM-DD`
   - If the branch already exists, try `docs/review-YYYY-MM-DD-2`, `-3`, etc.
3. Stage only the `*.md` files that were changed (`git add <file>` explicitly, not `git add .`)
4. Commit in logical groupings (e.g., separate commit for root-level docs vs. `docs/` subdirectory):
   ```
   docs: review for accuracy, DRY, and clarity
   ```
5. Do not push — leave that to the user

## Phase 5 — Summary

Output a concise summary:

- **Branch**: name of the branch created
- **Files changed**: list with one-line description of what changed in each
- **Issues fixed**: stale paths, duplicate sections consolidated, history narration removed, etc.
- **Flagged for human review**: items with `<!-- TODO: verify -->` that need a decision
- **Suggested next step**: `git push -u origin docs/review-YYYY-MM-DD` then `gh pr create`
