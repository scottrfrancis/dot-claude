---
description: Stage changed files and commit with an AI-generated conventional commit message
argument-hint: [-y to skip confirmation] [-t type to suggest commit type] [-all to include untracked files]
allowed-tools: Bash, Read, Glob
---

Stage tracked changes and commit with a generated conventional commit message.

Arguments: $ARGUMENTS

## Step 1 — Check what's staged

```bash
git diff --cached --name-only
```

**If files are already staged:** skip Step 2 and go directly to Step 3.

**If nothing is staged:** check for unstaged changes:

```bash
git status --porcelain
```

If nothing is staged AND the working tree is clean, report:
> "Nothing to commit. Working tree is clean."
and stop.

## Step 2 — Stage changes (only when nothing was pre-staged)

Show the user a summary of what will be staged:

```
Files to be staged (tracked changes):
  M  src/foo.ts
  M  src/bar.ts
```

If `-all` was passed, also include untracked files in the summary and stage them too:

```
New files to be staged (-all):
  ?? new-file.ts
```

If `-all` was NOT passed and there are untracked files, list them separately as skipped:

```
Untracked files (skipped — use -all to include them):
  ?? new-file.ts
```

Then stage. Without `-all` use `git add -u` (tracked modifications and deletions only). With `-all` use `git add -A` (everything, including untracked files).

- If `-y` was passed: stage without prompting
- Otherwise: ask "Stage these files and generate commit message? (y/n)"
  - If "n": stop without staging or committing

## Step 3 — Read the diff for context

```bash
git diff --cached
```

Use this to understand what actually changed, not just file names.

## Step 4 — Generate the commit message

Follow `~/.claude/guidelines/conventional-commits.md`. The format is:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- Subject line: under 72 characters, present tense, imperative mood, no trailing period
- If `-t <type>` was passed in arguments, use that type
- Include a body only if the why isn't obvious from the subject
- Add `BREAKING CHANGE:` footer if applicable

## Step 5 — Show and confirm

Display the proposed message clearly. Then:

- If `-y` was passed: commit immediately without prompting
- Otherwise: ask "Commit with this message? (y/n)"
  - If "n": stop (changes remain staged so the user can commit manually)

If confirmed, commit using a heredoc to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>
EOF
)"
```

Report success or failure.
