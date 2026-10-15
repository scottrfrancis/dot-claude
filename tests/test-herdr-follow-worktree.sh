#!/usr/bin/env bash
# test-herdr-follow-worktree.sh — tests for hooks/herdr-follow-worktree.sh.
#
# The hook makes herdr follow the git worktrees a Claude session creates, so the sidebar
# shows them without pre-creating anything. herdr is replaced by a stub that logs its
# arguments and answers like herdr 0.9.3 does, so these run anywhere, CI included.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/herdr-follow-worktree.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/herdr-follow.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"

echo "test-herdr-follow-worktree.sh"
if [ ! -x "$HOOK" ]; then
  echo "  FAIL hooks/herdr-follow-worktree.sh is missing or not executable"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# Stub herdr: logs one line per call; `worktree open` answers with a workspace id,
# `workspace get` reports the checkout path recorded at open time.
STUB="$WORK/herdr"; LOG="$WORK/herdr.log"
cat >"$STUB" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HERDR_STUB_LOG"
[ -n "${HERDR_STUB_FAIL:-}" ] && { echo '{"error":{"code":"boom"}}'; exit 1; }
case "$1 $2" in
  "worktree open")
    p=""; while [ $# -gt 0 ]; do [ "$1" = --path ] && p="$2"; shift; done
    n=$(( $(cat "$HERDR_STUB_LOG.ws" 2>/dev/null | wc -l) + 1 ))
    printf '%s\t%s\n' "ws$n" "$p" >>"$HERDR_STUB_LOG.ws"
    printf '{"result":{"already_open":false,"workspace":{"workspace_id":"ws%s"}}}\n' "$n" ;;
  "workspace get")
    p=$(awk -F'\t' -v id="$3" '$1==id {print $2}' "$HERDR_STUB_LOG.ws" 2>/dev/null)
    printf '{"result":{"workspace":{"workspace_id":"%s","worktree":{"checkout_path":"%s"}}}}\n' "$3" "$p" ;;
  *) echo '{"result":{"type":"ok"}}' ;;
esac
EOF
chmod +x "$STUB"

export HERDR_STUB_LOG="$LOG" XDG_STATE_HOME="$WORK/state"
g() { git -c user.email=t@t -c user.name=t "$@"; }

REPO="$WORK/repo"
mkdir -p "$REPO" && ( cd "$REPO" && git init -q -b main . && g commit -q --allow-empty -m init )

run() { # $1 = cwd, $2 = extra JSON fields; prints the hook's stdout
  printf '{"hook_event_name":"PostToolUse","tool_name":"Bash","cwd":"%s"%s}' "$1" "${2:-}" \
    | HERDR_ENV=1 HERDR_FOLLOW_HERDR="$STUB" "$HOOK"
}
calls() { cat "$LOG" 2>/dev/null; }
reset_log() { : >"$LOG"; }

# Outside herdr nothing happens at all.
g -C "$REPO" worktree add -q -b one "$WORK/wt-one" 2>/dev/null
reset_log
out=$(printf '{"cwd":"%s"}' "$REPO" | HERDR_FOLLOW_HERDR="$STUB" "$HOOK"); rc=$?
[ $rc -eq 0 ] && [ -z "$out" ] && [ -z "$(calls)" ] \
  && ok "outside herdr (HERDR_ENV unset): no herdr calls, no output, exit 0" \
  || bad "outside herdr (HERDR_ENV unset): no herdr calls, no output, exit 0" "rc=$rc out=$out calls=$(calls)"

# A new linked worktree is opened in herdr, without focus, against its repo.
reset_log; out=$(run "$REPO"); rc=$?
case "$(calls)" in
  *"worktree open"*"--cwd $REPO"*"--path $WORK/wt-one"*"--no-focus"*) ok "a new worktree is opened in herdr without focus" ;;
  *) bad "a new worktree is opened in herdr without focus" "$(calls)" ;;
esac
[ $rc -eq 0 ] && [ -z "$out" ] && ok "prints nothing and exits 0" || bad "prints nothing and exits 0" "rc=$rc out=$out"
grep -q -- "--path $REPO " "$LOG" && bad "the main checkout is never opened" "$(calls)" || ok "the main checkout is never opened"

# Nothing new: herdr is not contacted.
reset_log; run "$REPO" >/dev/null
[ -z "$(calls)" ] && ok "a worktree already followed is not opened again" || bad "a worktree already followed is not opened again" "$(calls)"

# Running from inside a linked worktree finds the same repo.
g -C "$REPO" worktree add -q -b two "$WORK/wt-two" 2>/dev/null
reset_log; run "$WORK/wt-one" >/dev/null
case "$(calls)" in
  *"--path $WORK/wt-two"*) ok "works when the session's cwd is itself a linked worktree" ;;
  *) bad "works when the session's cwd is itself a linked worktree" "$(calls)" ;;
esac

# Subagent worktrees: Claude locks them with "claude agent ..."; never follow them,
# not even after the agent finishes and the lock is released.
g -C "$REPO" worktree add -q -b agent "$WORK/wt-agent" 2>/dev/null
g -C "$REPO" worktree lock --reason "claude agent agent-a1 (pid 1)" "$WORK/wt-agent"
reset_log; run "$REPO" >/dev/null
grep -q -- "--path $WORK/wt-agent" "$LOG" && bad "a subagent worktree (lock 'claude agent') is skipped" "$(calls)" \
                                          || ok "a subagent worktree (lock 'claude agent') is skipped"
g -C "$REPO" worktree unlock "$WORK/wt-agent"
reset_log; run "$REPO" >/dev/null
grep -q -- "--path $WORK/wt-agent" "$LOG" && bad "a subagent worktree stays skipped after its lock is released" "$(calls)" \
                                          || ok "a subagent worktree stays skipped after its lock is released"

# Session worktrees (claude -w, EnterWorktree) carry "claude session ..." and are followed.
g -C "$REPO" worktree add -q -b sess "$WORK/wt-sess" 2>/dev/null
g -C "$REPO" worktree lock --reason "claude session sess (pid 2)" "$WORK/wt-sess"
reset_log; run "$REPO" >/dev/null
grep -q -- "--path $WORK/wt-sess" "$LOG" && ok "a session worktree (lock 'claude session') is followed" \
                                         || bad "a session worktree (lock 'claude session') is followed" "$(calls)"

# Tool calls made by a subagent never trigger a sync.
g -C "$REPO" worktree add -q -b three "$WORK/wt-three" 2>/dev/null
reset_log; run "$REPO" ',"agent_id":"a1","agent_type":"Explore"' >/dev/null
[ -z "$(calls)" ] && ok "a subagent's own tool calls are ignored" || bad "a subagent's own tool calls are ignored" "$(calls)"

# A failed open is not remembered, so the next sync retries it.
reset_log; HERDR_STUB_FAIL=1 run "$REPO" >/dev/null; rc=$?
[ $rc -eq 0 ] && ok "a failing herdr still exits 0" || bad "a failing herdr still exits 0" "rc=$rc"
reset_log; run "$REPO" >/dev/null
grep -q -- "--path $WORK/wt-three" "$LOG" && ok "a failed open is retried on the next sync" \
                                          || bad "a failed open is retried on the next sync" "$(calls)"

# When a followed worktree is removed, its herdr workspace is closed.
id=$(awk -F'\t' -v p="$WORK/wt-two" '$2==p {print $1}' "$LOG.ws" | tail -1)
g -C "$REPO" worktree remove "$WORK/wt-two"
reset_log; run "$REPO" >/dev/null
grep -q "workspace close $id" "$LOG" && ok "a removed worktree's workspace is closed" \
                                     || bad "a removed worktree's workspace is closed" "id=$id calls=$(calls)"
grep -q "workspace close" "$LOG" && [ "$(grep -c 'workspace close' "$LOG")" -eq 1 ] \
  && ok "only that workspace is closed" || bad "only that workspace is closed" "$(calls)"

# A workspace id that now belongs to some other checkout is left alone.
g -C "$REPO" worktree remove "$WORK/wt-three"
id3=$(awk -F'\t' -v p="$WORK/wt-three" '$2==p {print $1}' "$LOG.ws" | tail -1)
awk -F'\t' -v id="$id3" -v w="$WORK" 'BEGIN{OFS="\t"} $1==id {$2=w"/elsewhere"} {print}' "$LOG.ws" >"$LOG.ws.new" && mv "$LOG.ws.new" "$LOG.ws"
reset_log; run "$REPO" >/dev/null
grep -q "workspace close" "$LOG" && bad "a reused workspace id is not closed" "$(calls)" || ok "a reused workspace id is not closed"

# Outside any git repo: silent no-op.
mkdir -p "$WORK/plain"; reset_log; out=$(run "$WORK/plain"); rc=$?
[ $rc -eq 0 ] && [ -z "$out" ] && [ -z "$(calls)" ] && ok "outside a git repo: silent no-op" \
  || bad "outside a git repo: silent no-op" "rc=$rc out=$out calls=$(calls)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
