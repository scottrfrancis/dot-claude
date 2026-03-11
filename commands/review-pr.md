---
description: "Review a PR diff for bugs, security issues, missing tests, and style"
argument-hint: "[PR number or branch name] [-base main]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

Review a pull request for bugs, security issues, missing tests, and code quality.

Arguments: $ARGUMENTS

## Step 1 — Resolve the diff

Determine what to review based on arguments:

- **PR number** (e.g., `123`): Run `gh pr diff 123` and `gh pr view 123 --json title,body,baseRefName,headRefName`
- **Branch name** (e.g., `feature/foo`): Run `git diff main...feature/foo`
- **No arguments**: Run `git diff main...HEAD` to review the current branch against `main`
- **`-base <branch>`**: Use the specified base branch instead of `main`

Also run `git log --oneline main...HEAD` (or equivalent) to see commit history for context.

If the diff is empty, report "No changes to review" and stop.

## Step 2 — Read changed files for full context

For each file with non-trivial changes, read the full file (not just the diff) to understand surrounding context. This is critical for catching:

- Functions that are called but now behave differently
- Missing null checks that the diff alone doesn't reveal
- Import changes that affect other consumers

Skip reading files for trivial changes (whitespace, comment-only, lockfile updates).

## Step 3 — Review checklist

Evaluate the diff against each category. Only report findings — skip categories with no issues.

### Bugs & Logic Errors
- Off-by-one errors, incorrect comparisons, swapped arguments
- Unhandled null/undefined, missing error propagation
- Race conditions, state mutations in unexpected order
- Broken control flow (early returns that skip cleanup, missing breaks)

### Security (OWASP Top 10)
- Injection: SQL, command, path traversal, template injection
- Auth: missing or weakened auth checks, hardcoded secrets, default credentials
- Data exposure: sensitive data in logs, error messages, or API responses
- XSS: unsanitized user input in HTML/JSX output

### Missing Tests
- New public functions or API endpoints without test coverage
- Changed behavior that existing tests don't cover
- Edge cases visible in the diff (empty arrays, null inputs, boundary values)
- Removed or weakened test assertions

### API & Contract Changes
- Breaking changes to public APIs, function signatures, or database schemas
- Changed return types or response shapes without migration
- Removed or renamed exports that other modules may depend on

### Style & Conventions
- Only flag issues that affect correctness or maintainability
- Naming that obscures intent, misleading comments, dead code
- Do NOT flag formatting preferences — defer to linters

## Step 4 — Output the review

Format as a PR review comment. Group findings by file.

```
## PR Review: <title or branch>

### Summary
<1-2 sentence overall assessment: approve, request changes, or comment>

### Findings

#### `path/to/file.ts`

| # | Severity | Line | Finding | Suggestion |
|---|----------|------|---------|------------|
| 1 | HIGH | 42 | Description | Fix |

#### `path/to/other.ts`
...

### Verdict

**Approve** / **Request Changes** / **Comment**
<Brief justification>
```

Severity levels:
- **HIGH** — Bugs, security vulnerabilities, data loss risks. Must fix before merge.
- **MEDIUM** — Missing tests, potential issues under edge cases, breaking API changes. Should fix.
- **LOW** — Style, naming, dead code. Nice to fix.

If there are no findings, say so clearly:
> Looks good. No issues found.
