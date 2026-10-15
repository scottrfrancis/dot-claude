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

# git's global options come before the subcommand, and every rule below looks for
# `git <subcommand>`, so `git -C repo push --force` used to pass unchecked. Collapse
# -C/-c <value> (quoted or not), --git-dir/--work-tree/--namespace <value> and the
# value-less globals to plain `git`. perl, because BSD and GNU sed disagree on loops.
if command -v perl >/dev/null 2>&1; then
  GIT_CMD_HEAD=$(printf '%s\n' "$CMD_HEAD" | perl -pe '1 while s/\bgit\s+(?:-[Cc]\s+(?:"[^"]*"|'"'"'[^'"'"']*'"'"'|\S+)|--(?:git-dir|work-tree|namespace)(?:=|\s+)\S+|--(?:no-pager|bare|no-replace-objects|literal-pathspecs))\s*/git /')
else
  GIT_CMD_HEAD="$CMD_HEAD"
fi

# A push that overwrites the remote without a real guard: a bare --force, -f alone or
# inside combined short flags (-uf), a +refspec, or a lease that guards nothing.
# A lease is safe when it names the expected commit (--force-with-lease=<ref>:<sha>)
# or is paired with --force-if-includes. A bare lease, or one naming only the ref,
# compares against the remote-tracking ref, which a background fetch may have moved.
force_push() {
  local re='(^|[^[:alnum:]_.-])git[[:space:]]+push([[:space:]].*)?$'
  [[ $1 =~ $re ]] || return 1
  local args=" ${BASH_REMATCH[2]} "
  [[ $args =~ [[:space:]]--force[[:space:]] ]] && return 0
  [[ $args =~ [[:space:]]-[[:alpha:]]*f[[:alpha:]]*[[:space:]] ]] && return 0
  [[ $args =~ [[:space:]]\+[^[:space:]] ]] && return 0
  if [[ $args =~ [[:space:]]--force-with-lease[=[:space:]] ]]; then
    [[ $args =~ [[:space:]]--force-if-includes[[:space:]] ]] && return 1
    [[ $args =~ [[:space:]]--force-with-lease=[^[:space:]:]+:[^[:space:]]+[[:space:]] ]] && return 1
    return 0
  fi
  return 1
}

# --- Destructive git operations ---
if force_push "$GIT_CMD_HEAD"; then
  echo "Safety check: force push without a guarded lease — '$(echo "$CMD_HEAD" | head -c 120)'. Use --force-with-lease=<branch>:<expected sha> (or add --force-if-includes), or confirm this is intentional." >&2
  exit 2
fi
if echo "$GIT_CMD_HEAD" | grep -qE 'git\s+(reset\s+--hard|clean\s+-f|checkout\s+--\s|\brebase\s+.*--abort)'; then
  echo "Safety check: destructive git operation detected — '$(echo "$CMD_HEAD" | head -c 120)'. Confirm this is intentional." >&2
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
