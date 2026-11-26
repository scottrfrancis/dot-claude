#!/usr/bin/env bash
# test-account-detect.sh — tests for how the account checks find the logged-in account.
#
# Two scripts compare the account a directory expects with the one Claude Code is logged
# into: hooks/account-mismatch-warn.sh (SessionStart) and scripts/account-context.sh
# (statusline). Both read oauthAccount from Claude Code's global config file.
#
# Claude Code keeps that file at $CLAUDE_CONFIG_DIR/.claude.json when the variable is set,
# and at $HOME/.claude.json otherwise. The claude-profile launcher sets CLAUDE_CONFIG_DIR
# so each profile gets its own keychain login, so a check that reads $HOME/.claude.json
# reads a stale record and reports the wrong account.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/account-mismatch-warn.sh"
STATUS="$SCRIPT_DIR/../scripts/account-context.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

echo "test-account-detect.sh"
for f in "$HOOK" "$STATUS"; do
  if [ ! -x "$f" ]; then
    echo "  FAIL $f is missing or not executable"
    echo; echo "0 passed, 1 failed"; exit 1
  fi
done
command -v jq >/dev/null 2>&1 || { echo "  FAIL jq is required"; echo; echo "0 passed, 1 failed"; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-account-detect.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT

# A directory that expects the AI Lab account.
mkdir -p "$WORK/project"; echo ailab > "$WORK/project/.account-context"

account_file() { # $1 = dir, $2 = org name, $3 = org type
  mkdir -p "$1"
  jq -n --arg n "$2" --arg t "$3" \
    '{oauthAccount:{emailAddress:"t@example.com",organizationName:$n,organizationType:$t}}' \
    > "$1/.claude.json"
}
account_file "$WORK/personal" "t@example.com's Organization" claude_max
account_file "$WORK/ailab"    "The AI Lab"                   claude_team

hook() { # $1 = HOME, $2 = CLAUDE_CONFIG_DIR ("" = unset); prints the hook's output
  printf '{"source":"startup","cwd":"%s"}' "$WORK/project" \
    | if [ -n "$2" ]; then env HOME="$1" CLAUDE_CONFIG_DIR="$2" "$HOOK"
      else env -u CLAUDE_CONFIG_DIR HOME="$1" "$HOOK"; fi 2>&1
}
status() { # $1 = HOME, $2 = CLAUDE_CONFIG_DIR ("" = unset); prints the statusline
  printf '{"cwd":"%s"}' "$WORK/project" \
    | if [ -n "$2" ]; then env HOME="$1" CLAUDE_CONFIG_DIR="$2" "$STATUS"
      else env -u CLAUDE_CONFIG_DIR HOME="$1" "$STATUS"; fi 2>&1
}

# --- The hook ---
out="$(hook "$WORK/personal" "$WORK/ailab")"
case "$out" in
  *MISMATCH*) bad "hook: reads the account from CLAUDE_CONFIG_DIR, not HOME" "$out" ;;
  *) ok "hook: reads the account from CLAUDE_CONFIG_DIR, not HOME" ;;
esac

out="$(hook "$WORK/ailab" "$WORK/personal")"
case "$out" in
  *MISMATCH*) ok "hook: warns when CLAUDE_CONFIG_DIR holds the wrong account" ;;
  *) bad "hook: warns when CLAUDE_CONFIG_DIR holds the wrong account" "$out" ;;
esac

out="$(hook "$WORK/ailab" "")"
case "$out" in
  *MISMATCH*) bad "hook: with CLAUDE_CONFIG_DIR unset, reads HOME (right account)" "$out" ;;
  *) ok "hook: with CLAUDE_CONFIG_DIR unset, reads HOME (right account)" ;;
esac

out="$(hook "$WORK/personal" "")"
case "$out" in
  *MISMATCH*) ok "hook: with CLAUDE_CONFIG_DIR unset, reads HOME (wrong account)" ;;
  *) bad "hook: with CLAUDE_CONFIG_DIR unset, reads HOME (wrong account)" "$out" ;;
esac

# --- The statusline ---
out="$(status "$WORK/personal" "$WORK/ailab")"
case "$out" in
  *"AUTH MISMATCH"*) bad "statusline: reads the account from CLAUDE_CONFIG_DIR, not HOME" "$out" ;;
  *"[AL-Team]"*) ok "statusline: reads the account from CLAUDE_CONFIG_DIR, not HOME" ;;
  *) bad "statusline: reads the account from CLAUDE_CONFIG_DIR, not HOME" "$out" ;;
esac

out="$(status "$WORK/ailab" "$WORK/personal")"
case "$out" in
  *"AUTH MISMATCH"*) ok "statusline: warns when CLAUDE_CONFIG_DIR holds the wrong account" ;;
  *) bad "statusline: warns when CLAUDE_CONFIG_DIR holds the wrong account" "$out" ;;
esac

out="$(status "$WORK/personal" "")"
case "$out" in
  *"AUTH MISMATCH"*) ok "statusline: with CLAUDE_CONFIG_DIR unset, reads HOME" ;;
  *) bad "statusline: with CLAUDE_CONFIG_DIR unset, reads HOME" "$out" ;;
esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
