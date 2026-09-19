#!/usr/bin/env bash
# test-glossary.sh — tests for bin/check-glossary.sh
#
# The glossary is small on purpose: a row is earned by a term that actually caused a
# misunderstanding. What has to hold is that each row is usable — a term defined once, a
# definition that bottoms out rather than looping, and a real definition rather than a
# restatement of the term.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../bin/check-glossary.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
rc()  { "$CHECK" "$WORK/g.md" >/dev/null 2>&1; echo $?; }
out() { "$CHECK" "$WORK/g.md" 2>&1; }
gl()  { { printf '# Glossary\n\n| Term | Meaning | Anti-meanings |\n|---|---|---|\n'; printf '%s\n' "$1"; } > "$WORK/g.md"; }
good() { gl "$2"; [ "$(rc)" = 0 ] && ok "accepts $1" || bad "accepts $1" "$(out)"; }
poor() { gl "$2"; [ "$(rc)" = 1 ] && ok "rejects $1" || bad "rejects $1" "accepted: $2"; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

echo "test-glossary.sh"
if [ ! -x "$CHECK" ]; then
  echo "  FAIL bin/check-glossary.sh is missing or not executable — assertions would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

good "a well-formed row" '| `skill` | A `SKILL.md` package under `skills/`. | Not a Cursor `.mdc` rule; not a Copilot instruction. |'
good "an empty glossary"  ''
good "a row with no anti-meanings" '| `mine` | Running `/mine-sessions` over the session logs. | |'

# A term defined twice gives two answers to one question.
poor "a duplicate term" '| `skill` | One thing. | |
| `skill` | Another thing. | |'
gl '| `skill` | One thing. | |
| `skill` | Another. | |'
case "$(out)" in *skill*) ok "names the duplicated term" ;; *) bad "names the duplicated term" "$(out)" ;; esac

# A definition that uses the term it defines explains nothing.
poor "a self-referential definition" '| `deliverable` | The deliverable produced for a client. | |'

# ...and one that loops through another entry explains nothing either.
poor "a two-step definition cycle" '| `artifact` | Whatever a `deliverable` produces. | |
| `deliverable` | Whatever an `artifact` is. | |'
gl '| `artifact` | Whatever a `deliverable` produces. | |
| `deliverable` | Whatever an `artifact` is. | |'
case "$(out)" in *cycl*|*loop*) ok "reports it as a cycle" ;; *) bad "reports it as a cycle" "$(out)" ;; esac

# A chain that bottoms out in ordinary language is fine.
good "a chain that terminates" '| `bundle` | A directory of markdown served by `kb-mcp`. | |
| `kb-mcp` | The read-only filesystem MCP on the LAN. | |'

poor "an empty meaning" '| `thing` |  | |'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
