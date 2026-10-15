#!/usr/bin/env bash
# herdr-follow-worktree.sh — make herdr follow the git worktrees a Claude session creates.
#
# Registered for SessionStart, SessionEnd and PostToolUse (Bash|EnterWorktree|ExitWorktree).
# Inside herdr (HERDR_ENV=1) it compares `git worktree list` for the session's repo with
# what it has already handed to herdr, opens each new linked worktree as a workspace
# (`herdr worktree open --no-focus`), and closes the workspace of one that is gone.
# herdr is only contacted when the set of worktrees changes.
#
# Subagent worktrees are never followed: Claude Code locks them with the reason
# "claude agent <name> (pid ...)" (session worktrees get "claude session ..."), and the
# path is remembered as ignored so it stays skipped after the lock is released.
#
# Advisory by design: prints nothing, always exits 0. Setup notes:
# okf-knowledge infra/runbooks/herdr-setup.md.
set -u

input="$(cat 2>/dev/null || true)"

[ "${HERDR_ENV:-}" = "1" ] || exit 0
HERDR="${HERDR_FOLLOW_HERDR:-herdr}"
command -v "$HERDR" >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# cwd and agent_id from the hook input; a subagent's own tool calls never sync.
fields="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print(d.get("cwd") or "")
print(d.get("agent_id") or "")
' 2>/dev/null)" || exit 0
cwd="$(printf '%s\n' "$fields" | sed -n 1p)"
agent_id="$(printf '%s\n' "$fields" | sed -n 2p)"
[ -z "$agent_id" ] || exit 0
[ -n "$cwd" ] || cwd="$PWD"
[ -d "$cwd" ] || exit 0

common="$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
[ -n "$common" ] || exit 0

# Linked worktrees as "path<TAB>lock reason"; the first record is the main checkout.
porcelain="$(git -C "$cwd" worktree list --porcelain 2>/dev/null)" || exit 0
main="$(printf '%s\n' "$porcelain" | awk '/^worktree /{sub(/^worktree /, ""); print; exit}')"
current="$(printf '%s\n' "$porcelain" | awk '
  function flush() { if (n > 1 && path != "" && !bare && !prunable) printf "%s\t%s\n", path, lock }
  /^worktree / { flush(); n++; path = substr($0, 10); lock = ""; bare = 0; prunable = 0; next }
  /^locked/    { lock = substr($0, 8); next }
  /^bare/      { bare = 1; next }
  /^prunable/  { prunable = 1; next }
  END          { flush() }')"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-follow-worktree"
state="$state_dir/$(printf '%s' "$common" | cksum | cut -d' ' -f1).tsv"
mkdir -p "$state_dir" 2>/dev/null || exit 0
[ -f "$state" ] || : >"$state" 2>/dev/null || exit 0

# State lines: "followed<TAB>path<TAB>workspace_id" or "ignored<TAB>path".
in_state()   { awk -F'\t' -v p="$1" '$2 == p {found = 1} END {exit !found}' "$state"; }
in_current() { printf '%s\n' "$current" | awk -F'\t' -v p="$1" '$1 == p {found = 1} END {exit !found}'; }

next_state="$(mktemp "${TMPDIR:-/tmp}/herdr-follow.XXXXXX")" || exit 0
trap 'rm -f "$next_state"' EXIT

# Drop worktrees that are gone; close the workspace if it still shows that checkout.
while IFS=$'\t' read -r status path ws; do
  [ -n "$path" ] || continue
  if in_current "$path"; then
    printf '%s\t%s\t%s\n' "$status" "$path" "$ws" >>"$next_state"
    continue
  fi
  [ "$status" = "followed" ] && [ -n "$ws" ] || continue
  shown="$("$HERDR" workspace get "$ws" 2>/dev/null | python3 -c '
import json, sys
try:
    w = json.load(sys.stdin)["result"]["workspace"]
    print(w.get("worktree", {}).get("checkout_path", ""))
except Exception:
    pass
' 2>/dev/null)"
  [ "$shown" = "$path" ] && "$HERDR" workspace close "$ws" >/dev/null 2>&1
done <"$state"

# Open what is new.
while IFS=$'\t' read -r path lock; do
  [ -n "$path" ] || continue
  in_state "$path" && continue
  case "$lock" in
    "claude agent "*) printf 'ignored\t%s\t\n' "$path" >>"$next_state"; continue ;;
  esac
  ws="$("$HERDR" worktree open --cwd "$main" --path "$path" --label "$(basename "$path")" --no-focus 2>/dev/null \
        | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin)["result"]["workspace"]["workspace_id"])
except Exception:
    pass
' 2>/dev/null)"
  [ -n "$ws" ] && printf 'followed\t%s\t%s\n' "$path" "$ws" >>"$next_state"
done <<<"$current"

cmp -s "$next_state" "$state" || mv "$next_state" "$state" 2>/dev/null
exit 0
