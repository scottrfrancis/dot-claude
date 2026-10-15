#!/usr/bin/env bash
# test-pre-tool-safety.sh — tests for hooks/pre-tool-safety.sh, the PreToolUse guard.
#
# Exit 2 means "blocked: Claude shows the message and asks the user". The cases that
# matter most are the ones that used to slip through: git global options before the
# subcommand (`git -C repo push --force`), force hidden in combined short flags or a
# +refspec, and a lease that guards nothing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/pre-tool-safety.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

echo "test-pre-tool-safety.sh"
if [ ! -f "$HOOK" ]; then
  echo "  FAIL hooks/pre-tool-safety.sh is missing"
  echo; echo "0 passed, 1 failed"; exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "  FAIL jq is required (the hook parses its input with it)"
  echo; echo "0 passed, 1 failed"; exit 1
fi

verdict() { # $1 = command; prints the hook's exit code
  jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}' | bash "$HOOK" >/dev/null 2>&1
  echo $?
}
blocks() { local rc; rc=$(verdict "$1"); [ "$rc" = 2 ] && ok "blocks:  $1" || bad "blocks:  $1" "exit $rc"; }
allows() { local rc; rc=$(verdict "$1"); [ "$rc" = 0 ] && ok "allows:  $1" || bad "allows:  $1" "exit $rc"; }

# Force pushes, however they are spelled.
blocks 'git push --force'
blocks 'git push -f origin main'
blocks 'git push origin x --force'
blocks 'git push -uf origin x'
blocks 'git push origin +main'

# Global options before the subcommand must not hide it.
blocks 'git -C repo push --force'
blocks 'git -C "my repo" push -f'
blocks "git -C 'my repo' push -f"
blocks 'git -c core.x=y push --force origin x'
blocks 'git --git-dir=/r/.git push --force'
blocks 'git --no-pager -C repo push --force'
blocks 'git -C repo reset --hard HEAD~1'
blocks 'cd /r && git -C sub clean -fd'

# A lease that names the expected commit, or is paired with --force-if-includes, is the
# safe way to push a rebased branch. A bare lease trusts whatever the last fetch saw.
allows 'git push --force-with-lease=main:abc123 origin main'
allows 'git push --force-with-lease --force-if-includes'
allows 'git push --force-with-lease --force-if-includes origin feat/x'
blocks 'git push --force-with-lease'
blocks 'git push --force-with-lease origin feat/x'
blocks 'git push --force-with-lease=main origin main'

# Ordinary commands stay quiet.
allows 'git push -u origin feat/x'
allows 'git push --follow-tags'
allows 'git push origin feature-f'
allows 'git --no-pager log'
allows 'git -C repo status'
allows 'git commit -m "push --force is mentioned here"'

# The other rules still hold.
blocks 'git reset --hard'
blocks 'rm -rf build'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
