---
paths:
  - "**/.github/workflows/*.{yml,yaml}"
---

# CI workflows

Load the `ci-local-parity` skill before changing a workflow. In short: install every scanner
the workflow runs, run its exact commands and flags locally before pushing, and run full-project
linters as well as the changed-file hooks. Adding a linter to an existing codebase surfaces old
violations, so fix those in a commit before the one that adds the check.
