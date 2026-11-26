#!/usr/bin/env bash
# test-skill-gate.sh — tests for hooks/skill-gate.py (PreToolUse)
#
# Scott's requirement: "if i went to the trouble to specify the guideline, i want it used by
# default." Skills load when their description matches, which is likely and not guaranteed, so
# the gate holds the first write of a governed file type (or the first commit) until the
# governing skill has been loaded. It asks at most twice per skill, so it cannot loop.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../hooks/skill-gate.py"
REPO="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/skill-gate.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"
mkdir -p "$WORK/tmp" "$WORK/proj"

echo "test-skill-gate.sh"
if [ ! -f "$GATE" ]; then
  echo "  FAIL hooks/skill-gate.py is missing"; echo; echo "0 passed, 1 failed"; exit 1
fi

SID=s1
# $1 tool, $2 tool_input JSON; prints stderr; exit status is the hook's.
gate() {
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' \
    "$SID" "$WORK/proj" "$1" "$2" | TMPDIR="$WORK/tmp" python3 "$GATE" 3>&1 1>/dev/null 2>&3
}
write() { gate Write "{\"file_path\":\"$WORK/proj/$1\",\"content\":\"x\"}"; }
bash_cmd() { gate Bash "{\"command\":\"$1\"}"; }
expect() { # $1 label, $2 expected rc, then the command
  local label="$1" want="$2"; shift 2
  local out rc; out="$("$@")"; rc=$?
  [ "$rc" = "$want" ] && ok "$label" || bad "$label" "rc=$rc want=$want out=$out"
  LAST="$out"
}

expect "the first .py write is held" 2 write app.py
case "$LAST" in *python*SKILL.md*) ok "the message names the skill and how to load it" ;;
  *) bad "the message names the skill and how to load it" "$LAST" ;; esac
expect "a Read of the skill's SKILL.md is never blocked" 0 gate Read "{\"file_path\":\"$REPO/skills/python/SKILL.md\"}"
expect "after that Read the .py write passes" 0 write app.py

SID=s2
expect "a new session is held again" 2 write app.py
expect "a Read through the guideline symlink counts" 0 gate Read "{\"file_path\":\"$REPO/guidelines/python.md\"}"
expect "and unblocks it" 0 write app.py

SID=s3
expect "the Skill tool is never blocked" 0 gate Skill '{"skill":"dot-claude:shell-scripts"}'
expect "and loading via the Skill tool (plugin prefix stripped) unblocks" 0 write run.sh

SID=s4
expect "a Markdown write is held" 2 write notes.md
case "$LAST" in *prose-style*markdown-formatting*|*markdown-formatting*prose-style*) ok "Markdown needs both prose skills" ;;
  *) bad "Markdown needs both prose skills" "$LAST" ;; esac
gate Skill '{"skill":"prose-style"}' >/dev/null
expect "one of two loaded still holds it" 2 write notes.md
case "$LAST" in *prose-style*) bad "and names only the missing one" "$LAST" ;; *) ok "and names only the missing one" ;; esac

SID=s5
expect "the first commit is held" 2 bash_cmd 'git -C /x commit -m wip'
expect "the second is held" 2 bash_cmd 'git commit -m wip'
expect "the third goes through: it asks at most twice" 0 bash_cmd 'git commit -m wip'
expect "a push needs git-workflow, already asked twice, so it passes" 0 bash_cmd 'git push origin HEAD'

SID=s6
expect "an unrelated command passes" 0 bash_cmd 'ls -la'
expect "an ungoverned file type passes" 0 write data.csv
expect "a test file also needs the testing skill" 2 write tests/test_app.py
case "$LAST" in *testing*) ok "and names it" ;; *) bad "and names it" "$LAST" ;; esac

SID=s7
out="$(printf '{"session_id":"s7","cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s/proj/a.py"}}' "$WORK" "$WORK" \
  | CLAUDE_SKILL_GATE=off TMPDIR="$WORK/tmp" python3 "$GATE" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "CLAUDE_SKILL_GATE=off turns it off" || bad "CLAUDE_SKILL_GATE=off turns it off" "rc=$rc $out"
mkdir -p "$WORK/proj/.claude" && touch "$WORK/proj/.claude/skill-gate-off"
expect "a project's .claude/skill-gate-off turns it off" 0 write sub/a.py
rm -f "$WORK/proj/.claude/skill-gate-off"

SID=s8
mkdir -p "$WORK/skills/python" && touch "$WORK/skills/python/SKILL.md"
out="$(printf '{"session_id":"s8","cwd":"%s/proj","tool_name":"Write","tool_input":{"file_path":"%s/proj/x.go"}}' "$WORK" "$WORK" \
  | SKILL_GATE_SKILLS_DIR="$WORK/skills" TMPDIR="$WORK/tmp" python3 "$GATE" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "a skill that does not exist on disk is not demanded" || bad "a skill that does not exist on disk is not demanded" "$out"

out="$(printf 'not json' | TMPDIR="$WORK/tmp" python3 "$GATE" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "garbage input exits 0" || bad "garbage input exits 0" "rc=$rc $out"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
