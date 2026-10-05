#!/usr/bin/env bash
# test-pre-tool-safety.sh — which Bash commands hooks/pre-tool-safety.sh stops.
#
# The hook exits 2 (Claude shows the message and asks the user) for destructive
# commands and 0 otherwise. A wrong answer is silent in both directions: a block
# on a safe command trains everyone to route around the hook, and a pass on a
# destructive one is the thing the hook exists to catch. So each case states
# which way it must go, and the allowed list is as much the point as the blocked.
#
# Pinned here:
#   - `git push --force-with-lease` is allowed in every form. It overwrites the
#     remote only if the remote is still where we last saw it; a bare --force,
#     -f (alone or inside combined short flags) and a +refspec are not, and stay
#     blocked.
#   - git's global options (-C <path>, -c <k=v>, --git-dir, --work-tree) come
#     before the subcommand, and every rule used to require `git` immediately
#     followed by it, so `git -C repo push --force` and `git -C repo reset --hard`
#     went through unchecked.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/pre-tool-safety.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

echo "test-pre-tool-safety.sh"
if [ ! -x "$HOOK" ]; then
  echo "  FAIL hooks/pre-tool-safety.sh is missing or not executable"
  echo; echo "0 passed, 1 failed"; exit 1
fi
command -v jq >/dev/null || { echo "  FAIL jq is required"; exit 1; }

run() { # exit code of the hook for one Bash command
  jq -n --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | "$HOOK" >/dev/null 2>&1
  echo $?
}
blocked() { local rc; rc=$(run "$1"); [ "$rc" = 2 ] && ok "blocks:  $1" || bad "blocks:  $1" "exit $rc, want 2"; }
allowed() { local rc; rc=$(run "$1"); [ "$rc" = 0 ] && ok "allows:  $1" || bad "allows:  $1" "exit $rc, want 0"; }

# ── force pushes that overwrite unconditionally: blocked ─────────────
blocked 'git push --force origin feat/x'
blocked 'git push origin feat/x --force'
blocked 'git push -f origin feat/x'
blocked 'git push -uf origin feat/x'
blocked 'git push origin +feat/x'
blocked 'git push origin +HEAD:main'
blocked 'git push --force-with-lease --force origin feat/x'
blocked 'cd /repo && git push --force origin feat/x'

# ── git's global options before the subcommand ───────────────────────
blocked 'git -C /repo push --force origin feat/x'
blocked 'git -C "/path with space/repo" push -f origin feat/x'
blocked 'git -c core.editor=true push --force origin feat/x'
blocked 'git --git-dir=/repo/.git push --force origin feat/x'
blocked 'git -C /repo reset --hard HEAD~1'
blocked 'git -C /repo clean -fdx'

# ── the other rules, unchanged ───────────────────────────────────────
blocked 'git reset --hard origin/main'
blocked 'git clean -fd'
blocked 'git checkout -- src/app.py'
blocked 'git worktree remove --force ../wt'
blocked 'rm -rf /tmp/build'

# ── force-with-lease, in every form: allowed ─────────────────────────
allowed 'git push --force-with-lease origin feat/x'
allowed 'git push --force-with-lease=feat/x origin feat/x'
allowed 'git push --force-with-lease=feat/x:e478e17 origin feat/x'
allowed 'git push --force-with-lease --force-if-includes origin feat/x'
allowed 'git -C /repo push --force-with-lease=feat/x:e478e17 origin feat/x'

# ── ordinary commands: allowed ───────────────────────────────────────
allowed 'git push origin feat/x'
allowed 'git push -u origin feat/x'
allowed 'git push --follow-tags origin main'
allowed 'git push origin feat/force-fix'
allowed 'git -C /repo status --short'
allowed 'git commit -m "do not --force anything"'
allowed 'git reset --soft HEAD~1'
allowed 'echo git push --force-with-lease'

echo; echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
