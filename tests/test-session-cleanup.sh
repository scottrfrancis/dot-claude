#!/usr/bin/env bash
# test-session-cleanup.sh — tests for commands/session-cleanup
#
# session-cleanup kills every process whose command line contains "claude". On a host
# running several sessions, worktree agents, herdr panes or the desktop app, that is all of
# them, including the session that ran it. It must refuse unless asked by name.
#
# Every command the script could run is resolved from a PATH holding only a logging stub,
# so even a broken guard cannot kill anything here.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP="$SCRIPT_DIR/../commands/session-cleanup"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/session-cleanup.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
for c in pkill docker rm find; do
  printf '#!/bin/sh\necho "%s $*" >> "%s/calls"\n' "$c" "$WORK" > "$WORK/bin/$c"
  chmod +x "$WORK/bin/$c"
done
run() { PATH="$WORK/bin" /bin/bash "$CLEANUP" "$@" 2>&1; }

echo "test-session-cleanup.sh"

: > "$WORK/calls"; out="$(run)"; rc=$?
[ "$rc" -ne 0 ] && ok "refuses without --kill-all-claude" || bad "refuses without --kill-all-claude" "rc=$rc"
[ ! -s "$WORK/calls" ] && ok "kills nothing when it refuses" || bad "kills nothing when it refuses" "$(cat "$WORK/calls")"
case "$out" in *--kill-all-claude*) ok "says which flag runs it" ;; *) bad "says which flag runs it" "$out" ;; esac

: > "$WORK/calls"; run --yes >/dev/null
[ ! -s "$WORK/calls" ] && ok "any other argument is refused too" || bad "any other argument is refused too" "$(cat "$WORK/calls")"

: > "$WORK/calls"; run --kill-all-claude >/dev/null
grep -q '^pkill' "$WORK/calls" && ok "runs when asked by name" || bad "runs when asked by name" "$(cat "$WORK/calls")"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
