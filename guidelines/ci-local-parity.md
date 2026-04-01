# CI Local Parity

When adding or modifying CI workflows, run every CI command locally before pushing.

## Rules

1. **No "it'll run in CI" shortcuts.** If a scanner/linter is in the workflow, install it locally and run it first. The first CI failure is public and blocks the PR.

2. **Full-project linters ≠ pre-commit hooks.** Pre-commit checks changed files only. CI runs against the whole project. Pre-existing issues in untouched files will fail CI but pass pre-commit. Run both:
   ```bash
   pre-commit run --all-files   # changed-file hooks
   npm run lint                 # full project
   eslint .                     # full project (if different from npm run lint)
   ```

3. **Install every CI tool locally:**
   ```bash
   # Python
   pip install bandit pip-audit pytest-cov

   # Go
   go install github.com/securego/gosec/v2/cmd/gosec@latest

   # Frontend
   npm audit --audit-level=high
   ```

4. **Match CI flags exactly.** If CI runs `gosec -severity medium ./...`, run that locally — not just `gosec ./...`. If CI runs `bandit -ll`, run `-ll` not default.

5. **Budget for pre-existing issues.** Adding a linter to a mature codebase always surfaces existing violations. Plan a "fix pre-existing issues" commit before the CI PR, not after.

## Checklist for new CI workflows

Before pushing:
- [ ] Every CI command runs locally with the same flags
- [ ] Full-project lint passes (not just pre-commit)
- [ ] Security scanners installed and run locally
- [ ] Pre-existing issues fixed or thresholds set intentionally
- [ ] CI workflow tested on a branch PR (not just merged to main)
