#!/usr/bin/env bash
# test-session-end-reminder.sh — tests for hooks/session-end-reminder.sh
#
# The hook is registered on Stop, which fires at the end of every reply, not once per
# session. A reminder repeated every turn is noise, so it speaks once per session_id.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/session-end-reminder.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/stop-reminder.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"; mkdir -p "$REPO"
git -C "$REPO" init -q -b main && git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m x
touch "$REPO/a" "$REPO/b" "$REPO/c"

stop() { # $1 = JSON on stdin; prints what the hook said
  (cd "$REPO" && printf '%s' "$1" | TMPDIR="$WORK/tmp" "$HOOK" 2>&1)
}

echo "test-session-end-reminder.sh"
mkdir -p "$WORK/tmp"

first="$(stop '{"session_id":"abc-1","hook_event_name":"Stop"}')"
case "$first" in *session-logger*) ok "reminds on the first stop of a session" ;; *) bad "reminds on the first stop of a session" "$first" ;; esac

second="$(stop '{"session_id":"abc-1","hook_event_name":"Stop"}')"
[ -z "$second" ] && ok "stays quiet on later stops in the same session" || bad "stays quiet on later stops in the same session" "$second"

other="$(stop '{"session_id":"xyz-2","hook_event_name":"Stop"}')"
case "$other" in *session-logger*) ok "a different session is reminded" ;; *) bad "a different session is reminded" "$other" ;; esac

rm -f "$REPO/a" "$REPO/b" "$REPO/c"
quiet="$(stop '{"session_id":"few-3","hook_event_name":"Stop"}')"
touch "$REPO/a" "$REPO/b" "$REPO/c"
later="$(stop '{"session_id":"few-3","hook_event_name":"Stop"}')"
case "$later" in *session-logger*) ok "a session that had nothing to remind about is reminded once there is" ;;
  *) bad "a session that had nothing to remind about is reminded once there is" "quiet=[$quiet] later=[$later]" ;; esac

stop 'not json' >/dev/null; rc=$?
[ "$rc" -eq 0 ] && ok "garbage input exits 0" || bad "garbage input exits 0" "rc=$rc"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
