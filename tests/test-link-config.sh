#!/usr/bin/env bash
# test-link-config.sh — tests for bin/link-config.sh
#
# Profile config dirs (HOME-swapped profiles, CLAUDE_CONFIG_DIR dirs) symlink parts of this
# repo but not skills/ or bin/, so repo skills never load there. link-config.sh adds the
# links. It writes outside the repo, so a dry run is the default, and it must never replace
# anything it did not create.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK="$SCRIPT_DIR/../bin/link-config.sh"
REPO="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain: $3 | got: $2" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1" "expected NOT to contain: $3 | got: $2" ;; *) ok "$1" ;; esac; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/link-config.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"

echo "test-link-config.sh"
if [ ! -x "$LINK" ]; then
  echo "  FAIL bin/link-config.sh is missing or not executable"; echo; echo "0 passed, 1 failed"; exit 1
fi

profile() { # $1 = config dir: shaped like a profile of this repo
  mkdir -p "$1" && ln -s "$REPO/CLAUDE.md" "$1/CLAUDE.md"
}
P="$WORK/p1/.claude"; profile "$P"

out="$("$LINK" "$P" 2>&1)"
has "a dry run says what it would link" "$out" "would link $P/skills/testing"
[ ! -e "$P/skills/testing" ] && ok "a dry run changes nothing" || bad "a dry run changes nothing" "$(ls -la "$P/skills")"

"$LINK" --apply "$P" >/dev/null 2>&1
[ "$(readlink "$P/skills/testing")" = "$REPO/skills/testing" ] && ok "--apply links each repo skill by absolute path" \
  || bad "--apply links each repo skill by absolute path" "$(readlink "$P/skills/testing")"
[ "$(readlink "$P/bin")" = "$REPO/bin" ] && ok "--apply links bin/" || bad "--apply links bin/" "$(ls -la "$P")"
[ ! -e "$P/skills/synced" ] && ok "Claude Code's own skills/synced is not linked" || bad "Claude Code's own skills/synced is not linked"
[ "$(readlink "$P/doctrine")" = "$REPO/doctrine" ] && ok "--apply links doctrine/, which host.md imports from" \
  || bad "--apply links doctrine/, which host.md imports from" "$(ls -la "$P")"
[ "$(readlink "$P/memory")" = "$REPO/memory" ] && ok "--apply links memory/, which CLAUDE.md imports from" \
  || bad "--apply links memory/, which CLAUDE.md imports from"
[ "$(readlink "$P/rules")" = "$REPO/rules" ] && ok "--apply links rules/, the path-scoped rules" \
  || bad "--apply links rules/, the path-scoped rules"
if [ -e "$REPO/host.md" ]; then
  [ "$(readlink "$P/host.md")" = "$REPO/host.md" ] && ok "--apply links this host's host.md" || bad "--apply links this host's host.md"
else
  [ ! -e "$P/host.md" ] && [ ! -L "$P/host.md" ] && ok "no host.md in the repo: none is linked" || bad "no host.md in the repo: none is linked"
fi

out="$("$LINK" --apply "$P" 2>&1)"
lacks "a second run has nothing to do" "$out" "link $P"

mkdir -p "$WORK/p2/.claude/skills/testing"; profile "$WORK/p2/.claude"
echo mine > "$WORK/p2/.claude/skills/testing/SKILL.md"
out="$("$LINK" --apply "$WORK/p2/.claude" 2>&1)"
has "an existing skill that is not ours is reported" "$out" "skip $WORK/p2/.claude/skills/testing"
[ "$(cat "$WORK/p2/.claude/skills/testing/SKILL.md")" = mine ] && ok "and left untouched" || bad "and left untouched"

ln -s "$REPO/skills/no-longer-exists" "$P/skills/no-longer-exists"
"$LINK" --apply "$P" >/dev/null 2>&1
[ ! -L "$P/skills/no-longer-exists" ] && ok "a dangling link into the repo's skills is removed" \
  || bad "a dangling link into the repo's skills is removed"
ln -s "$WORK/elsewhere" "$P/skills/foreign"
"$LINK" --apply "$P" >/dev/null 2>&1
[ -L "$P/skills/foreign" ] && ok "a dangling link pointing elsewhere is left alone" \
  || bad "a dangling link pointing elsewhere is left alone"

# Discovery: config dirs whose CLAUDE.md links to this repo, in either profile scheme.
H="$WORK/home"; profile "$H/.claude-profiles/ss/.claude"; profile "$H/.claude-client"
mkdir -p "$H/.claude-unrelated" && echo x > "$H/.claude-unrelated/CLAUDE.md"
out="$(LINK_CONFIG_HOME="$H" "$LINK" 2>&1)"
has "discovers HOME-swapped profiles" "$out" "$H/.claude-profiles/ss/.claude/skills/testing"
has "discovers CLAUDE_CONFIG_DIR-style dirs" "$out" "$H/.claude-client/skills/testing"
lacks "ignores config dirs that are not profiles of this repo" "$out" ".claude-unrelated"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
