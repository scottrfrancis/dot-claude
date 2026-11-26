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

# --- Killing Claude sessions by pattern ---
# Every Claude Code session, worktree agent and herdr pane on the host matches "claude",
# the session running the command included.
if printf '%s\n' "$CMD_HEAD" | grep -qiE '(^|[;&|[:space:]])(pkill|killall)[[:space:]][^;&|]*claude|pgrep[^;&|]*claude[^;&|]*\|[[:space:]]*xargs[^;&|]*[[:space:]]kill'; then
  echo "Safety check: this kills every process matching 'claude', which ends every Claude Code session on the host, this one included. Kill a specific PID instead." >&2
  exit 2
fi

# The user is asked; the reason is shown in the permission prompt.
ask() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}

# --- session-cleanup, run as a command ---
# It kills every Claude process on the machine and refuses without --kill-all-claude.
CLEANUP_RE='(^|[;&|])[[:space:]]*((sudo|bash|sh|env)[[:space:]]+)*([^[:space:];&|]*/)?session-cleanup([[:space:]]|$)'
if printf '%s\n' "$CMD_HEAD" | grep -qE "$CLEANUP_RE"; then
  if [[ $CMD_HEAD == *--kill-all-claude* ]]; then
    ask "session-cleanup --kill-all-claude kills every Claude process on this machine, this session included. Run it only on a dedicated NPU/GPU box."
  fi
  echo "Safety check: session-cleanup kills every Claude process on the machine and runs only with --kill-all-claude, on a dedicated NPU/GPU box. Ask Scott before running it." >&2
  exit 2
fi

# --- Commits and pushes on a default branch ---
# Never commit or push a default branch. This asks rather than blocks, so a repo that
# commits to its default branch by design (an engagement umbrella) is one approval away.
# The repo is the one git will act on: `git -C <dir>`, a leading `cd <dir> &&`, or the cwd.
RE_COMMIT='(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)'
RE_PUSH='(^|[;&|[:space:]])git[[:space:]]+push([[:space:]][^;&|]*)?'
RE_NEWBRANCH='git[[:space:]]+(checkout|switch)[[:space:]]+-[bBcC][[:space:]]'
is_commit=0; is_push=0; push_args=""
[[ $GIT_CMD_HEAD =~ $RE_COMMIT ]] && ! [[ $GIT_CMD_HEAD =~ $RE_NEWBRANCH ]] && is_commit=1
if [[ $GIT_CMD_HEAD =~ $RE_PUSH ]]; then is_push=1; push_args="${BASH_REMATCH[2]}"; fi

if { [ "$is_commit" -eq 1 ] || [ "$is_push" -eq 1 ]; } && command -v git >/dev/null 2>&1; then
  CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  dir="${CWD:-$PWD}"
  q="(\"[^\"]*\"|'[^']*'|[^[:space:];&|]+)"
  re_c="(^|[;&|[:space:]])git[[:space:]]+-C[[:space:]]+${q}"
  re_cd="^[[:space:]]*cd[[:space:]]+${q}[[:space:]]*(&&|;)"
  p=""
  if [[ $CMD_HEAD =~ $re_c ]]; then p="${BASH_REMATCH[2]}"
  elif [[ $CMD_HEAD =~ $re_cd ]]; then p="${BASH_REMATCH[1]}"
  fi
  if [ -n "$p" ]; then
    p="${p#\"}"; p="${p%\"}"; p="${p#\'}"; p="${p%\'}"
    case "$p" in \~) p="$HOME" ;; \~/*) p="$HOME/${p#\~/}" ;; /*) ;; *) p="$dir/$p" ;; esac
    dir="$p"
  fi
  if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
    default=$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    default="${default#origin/}"
    is_default() { # no origin/HEAD: main and master count as default
      [ -n "$1" ] || return 1
      if [ -n "$default" ]; then [ "$1" = "$default" ]; else [ "$1" = main ] || [ "$1" = master ]; fi
    }
    if [ "$is_commit" -eq 1 ] && is_default "$branch"; then
      ask "This commits on $branch, the default branch of $dir. Branch first, unless this repo commits to $branch by design."
    fi
    if [ "$is_push" -eq 1 ]; then
      read -r -a toks <<< "$push_args"
      pos=(); skip=0; all=0
      for t in ${toks[@]+"${toks[@]}"}; do
        if [ "$skip" -eq 1 ]; then skip=0; continue; fi
        case "$t" in
          --all|--mirror) all=1 ;;
          -o|--push-option|--repo|--receive-pack|--exec) skip=1 ;;
          -*) ;;
          *) pos+=("$t") ;;
        esac
      done
      dsts=()
      if [ "$all" -eq 1 ]; then dsts+=("${default:-main}")
      elif [ "${#pos[@]}" -le 1 ]; then dsts+=("$branch")
      else
        for r in "${pos[@]:1}"; do
          r="${r#+}"
          case "$r" in *:*) d="${r#*:}" ;; *) d="$r" ;; esac
          [ "$d" = HEAD ] && d="$branch"
          dsts+=("${d#refs/heads/}")
        done
      fi
      for d in "${dsts[@]}"; do
        is_default "$d" && ask "This pushes to $d, the default branch of $dir. Push a branch and open a PR, unless this repo pushes to $d by design."
      done
    fi
  fi
fi

exit 0
