---
description: "Monitor a PR until it merges, fails checks, or gets reviewed"
argument-hint: "<PR number>"
allowed-tools: ["Bash", "Read"]
---

Monitor a pull request and report status changes.

Arguments: $ARGUMENTS

## Step 1 — Validate the PR

If no PR number was provided, try to find one for the current branch:

```bash
gh pr view --json number,title,state,url
```

If no PR exists, report "No PR found for the current branch" and stop.

## Step 2 — Get current status

Run:

```bash
gh pr view $PR --json title,state,url,reviewDecision,statusCheckRollup,mergeable,reviews
```

Report the current state clearly:

```
PR #123: <title>
URL: <url>
State: <OPEN/MERGED/CLOSED>
Checks: <X passing, Y failing, Z pending>
Reviews: <summary of review decisions>
Mergeable: <yes/no/conflicting>
```

## Step 3 — Evaluate and advise

Based on the status:

- **All checks pass + approved**: "Ready to merge. Want me to merge it?"
- **Checks failing**: Show which checks failed and offer to investigate with `gh run view <id> --log-failed`
- **Review requested/changes requested**: Summarize reviewer comments with `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
- **Merge conflicts**: Report the conflict and suggest resolution
- **Still pending**: Report what's still running

## Step 4 — Ongoing monitoring (if invoked via /loop)

If this command is running on a loop, only report when something changes from the previous check. Don't repeat "still pending" on every cycle.

On status change, summarize what changed:
- "Check `lint` just failed — was passing last cycle"
- "PR was just approved by @reviewer"
- "All checks now passing — ready to merge"
