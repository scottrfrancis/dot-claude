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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/pre-tool-safety.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"
mkdir -p "$WORK/plain"   # not a git repo, so no branch rule applies
HERE="$WORK/plain"

verdict() { # $1 = command; prints 2 (blocked), ask (the user is asked) or 0 (allowed)
  local out rc
  out="$(jq -n --arg c "$1" --arg d "$HERE" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}' \
    | bash "$HOOK" 2>/dev/null)"; rc=$?
  if [ "$rc" = 0 ] && [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)" = ask ]; then
    echo ask
  else
    echo "$rc"
  fi
}
blocks() { local rc; rc=$(verdict "$1"); [ "$rc" = 2 ] && ok "blocks:  $1" || bad "blocks:  $1" "got $rc"; }
allows() { local rc; rc=$(verdict "$1"); [ "$rc" = 0 ] && ok "allows:  $1" || bad "allows:  $1" "got $rc"; }
asks()   { local rc; rc=$(verdict "$1"); [ "$rc" = ask ] && ok "asks:    $1" || bad "asks:    $1" "got $rc"; }

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

# --- killing sessions by pattern --------------------------------------------
# Every Claude Code session, worktree agent and herdr pane on a host matches "claude", the
# session running the command included.
blocks 'pkill -f claude'
blocks 'pkill -9 -f "claude"'
blocks 'killall claude'
blocks 'cd /tmp && pkill -f Claude'
blocks 'pgrep -f claude | xargs kill'
blocks 'pgrep -f claude | xargs -r kill -9'
allows 'pkill -f my-dev-server'
allows 'pgrep -fl claude'
allows 'ps aux | grep claude'
blocks 'pkill -f "claude --resume"'
blocks "pkill -f 'node.*claude'"
blocks 'pkill -u scott -f claude'
blocks '/usr/bin/pkill claude'
blocks 'sudo killall Claude'
blocks 'kill $(pgrep -f claude)'
# A targeted kill whose path or name merely contains "claude" is fine; the sandbox's temp
# directory is /tmp/claude-<uid>, so every scratch server lives under one.
allows 'pkill -f /private/tmp/claude-502/x/server.py'
allows 'pkill -f /Volumes/workspace/dot-claude/tools/server.sh'
allows 'pkill -f claude-mem-worker'
allows 'echo pkill claude'

# A long command (a heredoc body, a generated script) must not skip the checks.
long="$(printf 'git push --force origin main\n'; seq 1 20000)"
blocks_long() { local rc; rc=$(verdict "$long"); [ "$rc" = 2 ] && ok "blocks:  a force push followed by 20000 lines" || bad "blocks:  a force push followed by 20000 lines" "got $rc"; }
blocks_long
# Only the message is dropped before the checks, not everything after the first -m.
blocks 'python3 -m pytest && git push --force'
allows 'git commit -m "note: rm -rf is risky'

# session-cleanup kills every Claude process on the machine. It refuses without its flag;
# with the flag the user decides.
blocks 'session-cleanup'
blocks "$HOME/.claude/commands/session-cleanup"
blocks 'tools/session-cleanup --dry-run'
asks   'session-cleanup --kill-all-claude'
allows 'grep -n session-cleanup README.md'

# --- commits and pushes on a default branch --------------------------------
# Never commit or push a default branch; a repo that does so by design answers the prompt.
G=(-c user.email=t@t -c user.name=t -c init.defaultBranch=main)
git "${G[@]}" init -q --bare "$WORK/origin.git"
git "${G[@]}" clone -q "$WORK/origin.git" "$WORK/c" 2>/dev/null
git -C "$WORK/c" "${G[@]}" commit -q --allow-empty -m init && git -C "$WORK/c" push -q origin main 2>/dev/null
git -C "$WORK/c" remote set-head origin -a >/dev/null 2>&1
git "${G[@]}" clone -q "$WORK/origin.git" "$WORK/c2" 2>/dev/null       # stays on main
git "${G[@]}" init -q --bare --initial-branch=trunk "$WORK/trunk.git"
git "${G[@]}" clone -q "$WORK/trunk.git" "$WORK/t" 2>/dev/null
git -C "$WORK/t" "${G[@]}" checkout -q -b trunk 2>/dev/null; git -C "$WORK/t" "${G[@]}" commit -q --allow-empty -m init
git -C "$WORK/t" push -q origin trunk 2>/dev/null; git -C "$WORK/t" remote set-head origin -a >/dev/null 2>&1
git "${G[@]}" init -q "$WORK/n" && git -C "$WORK/n" "${G[@]}" commit -q --allow-empty -m init   # no remote

HERE="$WORK/c"
asks   'git commit -m "x"'
asks   'git add -A && git commit'
asks   'git push'
asks   'git push origin'
asks   'git push -u origin main'
asks   'git push origin HEAD'
allows 'git status'
allows 'git checkout -b feat/x'

git -C "$WORK/c" checkout -q -b feat/x
allows 'git commit -m "x"'
allows 'git push -u origin feat/x'
allows 'git push origin HEAD'
asks   'git push origin main'
asks   'git push origin feat/x:main'
asks   'git push origin HEAD:refs/heads/main'
asks   'git push --all'

allows 'git push --tags'
allows 'git push origin --tags'
asks   'git commit -m x && git push origin HEAD:main'

HERE="$WORK/c2"
allows 'git push --tags'
blocks 'git commit -m x && pkill -f claude'   # a block in one segment beats an ask in another
allows "export X=1 && cd $WORK/c && git commit -m x"
HERE="$WORK/c"
asks   "source /dev/null; cd $WORK/c2 && git commit -m x"

HERE="$WORK/plain"
asks   "cd $WORK && git -C c2 commit -m x"
asks   "git -c user.name=x -C $WORK/c2 commit -m x"
asks   "git -C $WORK/c2 commit -m x"
allows "git -C $WORK/c commit -m x"
asks   "cd $WORK/c2 && git commit -m x"
allows "cd $WORK/c && git add -A && git commit -m x"
allows "cd $WORK/c2 && git checkout -b feat/y && git commit -m x"
asks   "git -C $WORK/c2 push -o ci.skip origin"
asks   "git -C $WORK/c2 push -o ci.skip origin main"
allows "git -C $WORK/c2 push -o ci.skip origin feat/y"

HERE="$WORK/t"
asks   'git commit -m "on trunk, the default here"'
git -C "$WORK/t" checkout -q -b main
allows 'git commit -m "main is an ordinary branch here"'

HERE="$WORK/n"
asks   'git commit -m "no remote: main counts as default"'
git -C "$WORK/n" checkout -q --detach
allows 'git commit -m "detached HEAD"'
HERE="$WORK/plain"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
