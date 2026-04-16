---
name: pr-token-tracking
description: Include AI token usage in PR descriptions. Use when creating or updating pull requests.
---

# PR Token Tracking

When creating a pull request, always include token usage data in the PR description.

## How it works

Token usage is automatically logged to `~/.factory/token-ledger.json` at the end of each session via a `SessionEnd` hook. The ledger is keyed by `project:branch`.

## When creating a PR

1. Run the `/pr-tokens` command (or execute `~/.factory/commands/pr-tokens` directly) to get the token summary for the current branch.
2. Append the output to the **bottom** of the PR description body. The output is a collapsible `<details>` section that won't clutter the PR.
3. If no token data exists yet (e.g., this is the first session), note that in the PR description instead.

## After a PR is merged

Run `/pr-tokens --reset` to clear the ledger for that branch so it doesn't accumulate stale data.

## Format

The token summary renders as a collapsible section:

```
<details>
<summary>AI Token Usage</summary>

**Branch:** `project:feature-branch`
**Sessions:** 3
**Estimated cost:** $4.52

| Metric | Count |
|--------|-------|
| Input tokens | 1.2M |
| Output tokens | 45.3K |
| Cache creation | 2.1M |
| Cache read | 8.4M |
| Thinking tokens | 12.1K |

**Models used:** claude-opus-4-6

</details>
```
