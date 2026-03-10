---
description: Generate a conventional commit message from staged changes and commit
argument-hint: [-y to skip confirmation] [-t <type> to suggest commit type]
allowed-tools: Bash, Read, Glob
---

Generate and apply a conventional commit message for the current staged changes.

Arguments: $ARGUMENTS

## Step 1 — Check what's staged

```bash
git diff --cached --stat
git diff --cached --name-only
```

If nothing is staged, report it and stop:
> "Nothing is staged. Stage specific files with `git add <file>` before running /autocommit."

Do NOT run `git add .` or stage anything automatically. The user is responsible for staging.

## Step 2 — Read the diff for context

```bash
git diff --cached
```

Use this to understand what actually changed, not just file names.

## Step 3 — Generate the commit message

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

## Step 4 — Show and confirm

Display the proposed message clearly. Then:

- If `-y` was passed in arguments: commit immediately without prompting
- Otherwise: ask "Commit with this message? (y/n)"

If confirmed, commit:

```bash
git commit -m "<message>"
```

Use a heredoc for multi-line messages to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>
EOF
)"
```

Report success or failure.
