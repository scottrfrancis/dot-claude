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

# --- Clients come from the private table, accounts.local ---
# This repo is public, so no client name lives in it. Each host lists its clients in a
# gitignored accounts.local at the checkout root; DOT_CLAUDE_ACCOUNTS points both scripts at
# a fixture table here.
TABLE="$WORK/accounts.local"
cat > "$TABLE" <<'EOF'
# kind    match                      account  segment   label
marker    clientco                   bs       clientco  Clientco Enterprise
remote    *github.com[:/]clientco/*  bs       clientco  Clientco Enterprise
org       clientco                   bs       -         Clientco Enterprise
EOF
account_file "$WORK/client" "Clientco" claude_enterprise
mkdir -p "$WORK/cmark" "$WORK/cremote"; echo clientco > "$WORK/cmark/.account-context"
git -C "$WORK/cremote" init -q && git -C "$WORK/cremote" remote add origin git@github.com:clientco/app.git

hookc() { # $1 = cwd, $2 = CLAUDE_CONFIG_DIR, $3 = table; prints the hook's output
  printf '{"source":"startup","cwd":"%s"}' "$1" \
    | env HOME="$WORK/personal" CLAUDE_CONFIG_DIR="$2" DOT_CLAUDE_ACCOUNTS="$3" "$HOOK" 2>&1
}
statusc() { # same arguments; prints the statusline
  printf '{"cwd":"%s"}' "$1" \
    | env HOME="$WORK/personal" CLAUDE_CONFIG_DIR="$2" DOT_CLAUDE_ACCOUNTS="$3" "$STATUS" 2>&1
}

out="$(hookc "$WORK/cmark" "$WORK/client" "$TABLE")"
case "$out" in
  *MISMATCH*) bad "hook: a client marker from the table matches that client's login" "$out" ;;
  *) ok "hook: a client marker from the table matches that client's login" ;;
esac

out="$(hookc "$WORK/cmark" "$WORK/personal" "$TABLE")"
case "$out" in
  *MISMATCH*"Clientco Enterprise"*) ok "hook: a client marker from the table warns on another login, with the table's label" ;;
  *) bad "hook: a client marker from the table warns on another login, with the table's label" "$out" ;;
esac

out="$(hookc "$WORK/cremote" "$WORK/personal" "$TABLE")"
case "$out" in
  *MISMATCH*"Clientco Enterprise"*) ok "hook: a client remote from the table expects that client's account" ;;
  *) bad "hook: a client remote from the table expects that client's account" "$out" ;;
esac

out="$(hookc "$WORK/cremote" "$WORK/personal" "$WORK/no-such-table")"
case "$out" in
  *MISMATCH*) bad "hook: without the table, a client remote is unknown and gives no warning" "$out" ;;
  *) ok "hook: without the table, a client remote is unknown and gives no warning" ;;
esac

out="$(hookc "$WORK/project" "$WORK/client" "$TABLE")"
case "$out" in
  *MISMATCH*"Clientco Enterprise (t@example.com)"*) ok "hook: a client login found in the table is named in the warning" ;;
  *) bad "hook: a client login found in the table is named in the warning" "$out" ;;
esac

LOOKUP="$SCRIPT_DIR/../bin/accounts-lookup.sh"
out="$(DOT_CLAUDE_ACCOUNTS="$TABLE" "$LOOKUP" remote clientco)"
[ -z "$out" ] && ok "lookup: a value matches only rules of its own kind" \
  || bad "lookup: a value matches only rules of its own kind" "$out"
out="$(DOT_CLAUDE_ACCOUNTS="$TABLE" "$LOOKUP" org CLIENTCO)"
[ "$out" = "$(printf 'bs\t-\tClientco Enterprise')" ] && ok "lookup: prints account, segment and label for an org, ignoring case" \
  || bad "lookup: prints account, segment and label for an org, ignoring case" "$out"

printf 'org  ClientCo  bs  -  Mixed Case Rule\n' > "$WORK/mixed.local"
out="$(DOT_CLAUDE_ACCOUNTS="$WORK/mixed.local" "$LOOKUP" org clientco)"
case "$out" in
  *"Mixed Case Rule"*) ok "lookup: a rule written in mixed case still matches" ;;
  *) bad "lookup: a rule written in mixed case still matches" "$out" ;;
esac

out="$(statusc "$WORK/cmark" "$WORK/client" "$TABLE")"
case "$out" in
  *"AUTH MISMATCH"*) bad "statusline: a client marker from the table shows that client's tag" "$out" ;;
  *"[BS-Enterprise]"*) ok "statusline: a client marker from the table shows that client's tag" ;;
  *) bad "statusline: a client marker from the table shows that client's tag" "$out" ;;
esac

out="$(statusc "$WORK/project" "$WORK/client" "$TABLE")"
case "$out" in
  *"AUTH MISMATCH"*"Clientco Enterprise"*) ok "statusline: a client login found in the table is named in the mismatch" ;;
  *) bad "statusline: a client login found in the table is named in the mismatch" "$out" ;;
esac

out="$(statusc "$WORK/cremote" "$WORK/personal" "$WORK/no-such-table")"
case "$out" in
  *"[other]"*) ok "statusline: without the table, a client remote shows as other" ;;
  *) bad "statusline: without the table, a client remote shows as other" "$out" ;;
esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
