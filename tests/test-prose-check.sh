#!/usr/bin/env bash
# test-prose-check.sh — tests for hooks/prose-check.py (PostToolUse)
#
# The prose style is always on, and its mechanical rules can be checked mechanically: the dash
# budget, the corrective frame, bold density. The check judges only what a write added, so an
# edit to a legacy file is not blamed for the file's history.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../hooks/prose-check.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/prose-check.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT

echo "test-prose-check.sh"
if [ ! -f "$CHECK" ]; then
  echo "  FAIL hooks/prose-check.py is missing"; echo; echo "0 passed, 1 failed"; exit 1
fi

# Build the hook JSON in Python so content with quotes and newlines is encoded correctly.
# $1 tool, $2 file, then for Write: content file; for Edit: old file, new file.
run() {
  python3 - "$@" <<'EOF' | python3 "$CHECK" 3>&1 1>/dev/null 2>&3
import json, sys
tool, path = sys.argv[1], sys.argv[2]
ti = {"file_path": path}
if tool == "Write":
    ti["content"] = open(sys.argv[3]).read()
elif tool == "Edit":
    ti["old_string"] = open(sys.argv[3]).read(); ti["new_string"] = open(sys.argv[4]).read()
elif tool == "MultiEdit":
    ti["edits"] = [{"old_string": open(sys.argv[3]).read(), "new_string": open(sys.argv[4]).read()}]
print(json.dumps({"session_id": "s", "hook_event_name": "PostToolUse", "tool_name": tool, "tool_input": ti}))
EOF
}
expect() { # $1 label, $2 rc, then command
  local label="$1" want="$2"; shift 2
  local out rc; out="$("$@")"; rc=$?
  [ "$rc" = "$want" ] && ok "$label" || bad "$label" "rc=$rc want=$want out=$out"
  LAST="$out"
}
filler() { for i in $(seq 1 "$1"); do echo "Plain line $i of prose."; done; }

# Dashes
{ echo "One — two."; echo "Three — four."; echo "Five — six."; filler 7; } > "$WORK/a.md"
expect "three em-dashes in ten lines are flagged" 2 run Write "$WORK/a.md" "$WORK/a.md"
case "$LAST" in *dash*"1, 2, 3"*) ok "with their line numbers" ;; *) bad "with their line numbers" "$LAST" ;; esac

{ echo "One — two."; echo "Three — four."; filler 8; } > "$WORK/b.md"
expect "two em-dashes are within the minimum budget" 0 run Write "$WORK/b.md" "$WORK/b.md"

{ echo "Spaced – en dash."; echo "Double -- hyphen."; echo "And — em."; filler 7; } > "$WORK/c.md"
expect "spaced en-dashes and double hyphens count as dashes" 2 run Write "$WORK/c.md" "$WORK/c.md"

{ echo '---'; echo 'title: a — b'; echo '---'; echo '```'; echo 'x — y — z'; echo '```';
  echo '    indented — code — here'; echo 'Use `a — b` inline.'; echo '| a | b |'; echo '|---|---|'; filler 4; } > "$WORK/d.md"
expect "dashes in frontmatter, fences, indented code and inline code do not count" 0 run Write "$WORK/d.md" "$WORK/d.md"

{ echo "Old — one."; echo "Old — two."; echo "Old — three."; filler 7; } > "$WORK/legacy.md"
echo "Plain line 3 of prose." > "$WORK/old.txt"; echo "Plain line 3 of prose, edited." > "$WORK/new.txt"
expect "an edit that adds no dash to an over-budget legacy file passes" 0 run Edit "$WORK/legacy.md" "$WORK/old.txt" "$WORK/new.txt"
echo "Plain line 3 of prose — edited." > "$WORK/new2.txt"
expect "an edit that adds a dash to an over-budget file is flagged" 2 run Edit "$WORK/legacy.md" "$WORK/old.txt" "$WORK/new2.txt"
expect "MultiEdit edits are judged the same way" 2 run MultiEdit "$WORK/legacy.md" "$WORK/old.txt" "$WORK/new2.txt"

# Corrective frame
{ echo "This is not a bug, it is a feature."; filler 5; } > "$WORK/e.md"
expect "a corrective frame on an added line is flagged" 2 run Write "$WORK/e.md" "$WORK/e.md"
case "$LAST" in *corrective*) ok "and named" ;; *) bad "and named" "$LAST" ;; esac
{ echo "The cache keeps its own copy, but resets nightly."; echo "It is fast, but costly."; filler 4; } > "$WORK/f.md"
expect "possessive its and a plain 'It is X, but Y' are not frames" 0 run Write "$WORK/f.md" "$WORK/f.md"

# Bold
{ echo "**a** **b** **c** **d** **e**"; filler 9; } > "$WORK/g.md"
expect "five bold spans in ten lines are flagged" 2 run Write "$WORK/g.md" "$WORK/g.md"
{ echo "**a** **b** **c**"; filler 9; } > "$WORK/h.md"
expect "three bold spans are within the minimum budget" 0 run Write "$WORK/h.md" "$WORK/h.md"

# Scope
{ echo "<!-- prose-check: off -->"; echo "One — two — three — four."; } > "$WORK/off.md"
expect "a file marked prose-check: off is skipped" 0 run Write "$WORK/off.md" "$WORK/off.md"
{ echo "One — two — three — four."; } > "$WORK/x.txt"
expect "non-Markdown files are skipped" 0 run Write "$WORK/x.txt" "$WORK/x.txt"
mkdir -p "$WORK/node_modules/p"; cp "$WORK/a.md" "$WORK/node_modules/p/a.md"
expect "vendored Markdown is skipped" 0 run Write "$WORK/node_modules/p/a.md" "$WORK/node_modules/p/a.md"

out="$(printf 'not json' | python3 "$CHECK" 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "garbage input exits 0" || bad "garbage input exits 0" "rc=$rc $out"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
