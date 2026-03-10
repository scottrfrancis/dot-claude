#!/usr/bin/env bash
# PreToolUse hook: Warn before destructive operations.
# Blocks with exit code 2 (causes Claude to show the message and ask user to confirm).
# Advisory only for non-destructive tools.

set -euo pipefail

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // empty' 2>/dev/null)

# Only inspect Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Examine only the first line of the command, stripped of any -m/--message content.
# Heredoc bodies and commit message text start on line 2+; checking head -1 avoids
# false positives on dangerous-sounding text inside quoted strings or message bodies.
CMD_HEAD=$(echo "$COMMAND" | head -1 | sed 's/ -m .*//; s/ --message .*//' | head -c 200)
GIT_CMD_HEAD="$CMD_HEAD"

# --- Destructive git operations ---
if echo "$GIT_CMD_HEAD" | grep -qE 'git\s+(reset\s+--hard|push\s+.*--force|push\s+-f\b|clean\s+-f|checkout\s+--\s|\brebase\s+.*--abort)'; then
  echo "Safety check: destructive git operation detected — '$(echo "$GIT_CMD_HEAD" | head -c 120)'. Confirm this is intentional." >&2
  exit 2
fi

# --- Force-remove worktrees ---
if echo "$GIT_CMD_HEAD" | grep -qE 'git\s+worktree\s+remove\s+--force'; then
  echo "Safety check: 'git worktree remove --force' will delete uncommitted work in the worktree. Confirm." >&2
  exit 2
fi

# --- Recursive delete ---
if echo "$CMD_HEAD" | grep -qE '\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b|\brm\s+-rf\b|\brm\s+-fr\b'; then
  echo "Safety check: recursive delete detected — '$(echo "$CMD_HEAD" | head -c 120)'. Confirm this is intentional." >&2
  exit 2
fi

# --- Writes to sensitive global config files ---
if echo "$CMD_HEAD" | grep -qE '(>|>>)\s*(~\/\.claude\/settings\.json|~\/\.ssh\/|~\/\.aws\/credentials)'; then
  echo "Safety check: redirect to sensitive config file detected. Confirm this is intentional." >&2
  exit 2
fi

exit 0
