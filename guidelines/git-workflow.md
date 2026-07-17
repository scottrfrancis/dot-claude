# Git Workflow

This project uses a **branch + PR** workflow. Direct pushes to `main`
are prohibited. This rule is the enforcement layer the agent must
honour on every interaction.

## Hard rules — never violate without explicit user override

1. **Never `git commit` on `main`.** Before any commit, run
   `git branch --show-current`. If the result is `main`, stop and
   create a branch:
   ```
   git switch -c <type>/<slug> origin/main
   ```
   Only then commit.

2. **Never `git push origin main`.** Push to a feature branch only.
   `git push -u origin HEAD` after a `git switch -c` does the right
   thing.

3. **Never `git push --force` to `main`.** Don't even `--force-with-lease`
   to `main`. On feature branches, `--force-with-lease` is OK after
   rebase.

4. **Never rewrite `main`'s history.** No `git rebase -i` that touches
   `main`, no `git reset --hard` of `main`, no `git filter-branch` /
   `git filter-repo` on `main`.

## Branch naming (Conventional Commits types)

`<type>/<kebab-slug>` — types match
[Conventional Commits](https://www.conventionalcommits.org/):
`feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`,
`style`, `chore`, `revert`.

## Commit messages (on any branch)

Conventional Commits:
```
type(scope): imperative description under 72 chars

Optional body explaining why, not what.

Optional footer: Fixes #123, BREAKING CHANGE: ...
```

## PR flow

1. Open PR with `gh pr create --fill` (or `gh pr create --title "<type>: <desc>" --body "..."`).
2. PR title **must** use Conventional Commits format.
3. Merge with **squash** (`gh pr merge --squash --delete-branch`).

## Stacked PRs — prefer to avoid; when unavoidable, agent handles merge

**Default: avoid stacking.** Land the parent PR first, sync `main`,
then branch the child off fresh `main`.

**When stacking is genuinely needed:**

- Be explicit in the child PR body: "Stacked on #<n>. Review after parent lands."
- Agent handles the merge sequence atomically.

### Stacked-merge sequence

**Critical:** merge the parent WITHOUT `--delete-branch`.

```bash
# 1. Merge parent (keep branch alive)
gh pr merge <parent-num> --squash

# 2. Retarget child to main
gh pr edit <child-num> --base main

# 3. Verify
gh pr view <child-num> --json baseRefName

# 4. Merge child
gh pr merge <child-num> --squash --delete-branch

# 5. Cleanup parent branch
git push origin --delete <parent-branch>

# 6. Sync
git fetch origin --prune && git switch main && git pull
```

## Self-merge policy

| PR scope | Agent may self-merge? |
| -------- | --------------------- |
| Doc-only (no code files) | **Yes**, after user's explicit approval. |
| Touches code, tests, config | **No.** Wait for human approval. |
| Touches agent rules | **No** — always wait for human approval. |

## Handling auto-formatter drift

If `git status` shows unintended modifications, revert before staging:

```bash
git checkout -- <path-to-unrelated-file>
```

## When this rule conflicts with user intent

Stop and surface the conflict explicitly. Offer the PR path as default.
Only bypass on unambiguous override.
