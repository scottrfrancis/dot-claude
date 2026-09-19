#!/usr/bin/env bash
# test-conflict-log.sh — tests for bin/check-conflict-log.sh
#
# The conflict log is append-only with stable RC### ids. Those invariants are what make a
# decision citable months later, so they are checked rather than trusted.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../bin/check-conflict-log.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
check_rc() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected exit $3, got $2"; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

header() { cat <<'EOF'
# Runtime Conflict Log

Template and rules live in `guidelines/rule-conflict-protocol.md`.

---

(New entries appended below this separator, in order of occurrence.)
EOF
}

# A complete, well-formed entry.
entry() { # $1 = id, $2 = decision text (may be empty for a pending entry)
  cat <<EOF

**$1 — 2026-08-19 ~14:30 EDT — Scott**

**Kind:** rule

**Tool:** claude-code

**Trigger:** Asked to add a retroactive test for an existing helper.

**Operation:** Write a test after the production code it exercises.

**Conflicting rules:**

- From \`guidelines/testing.md\` § Non-negotiables:
  > No retroactive tests.
- From \`CLAUDE.md\` § Global Behavioral Rules:
  > Red-Green-Refactor TDD is REQUIRED for ALL code changes.

**Conflict explanation:**
Covering existing untested code requires writing a test after the code, which the
no-retroactive-tests rule forbids outright.

**Options presented:**

- (a) Treat it as characterization testing, exempt from the TDD rule.
- (b) Delete and rewrite the helper test-first.
- (c) Stop and leave the helper uncovered.

**Decision:** $2
EOF
}

log() { header > "$WORK/log.md"; for a in "$@"; do printf '%s\n' "$a" >> "$WORK/log.md"; done; }
rc()  { "$CHECK" "$WORK/log.md" >/dev/null 2>&1; echo $?; }
out() { "$CHECK" "$WORK/log.md" 2>&1; }

echo "test-conflict-log.sh"

if [ ! -x "$CHECK" ]; then
  echo "  FAIL bin/check-conflict-log.sh is missing or not executable — assertions would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

log
check_rc "an empty log (template only) is valid" "$(rc)" 0

# The real log documents its own entry format in a fenced block. That template contains a
# literal **RC<NNN> — ...** header, which must not be mistaken for a live entry.
{ header; printf '\n## Entry format\n\n```\n**RC<NNN> — <YYYY-MM-DD ~HH:MM TZ> — <name>**\n\n**Kind:** rule | pattern\n```\n'; } > "$WORK/log.md"
check_rc "a fenced entry-format template is not parsed as an entry" "$(rc)" 0

# ...but a fenced block must not hide a real entry from the check either.
{ header; entry RC001 'x'; printf '\n```\n**RC<NNN> — template — <name>**\n```\n'; } > "$WORK/log.md"
check_rc "a real entry alongside a fenced template still validates" "$(rc)" 0

log "$(entry RC001 '2026-08-19 ~14:40 EDT — chose (a).')"
check_rc "one complete entry is valid" "$(rc)" 0

log "$(entry RC001 '2026-08-19 ~14:40 EDT — chose (a).')" "$(entry RC002 '')"
check_rc "a pending entry with a blank Decision is valid" "$(rc)" 0

log "$(entry RC001 'x')" "$(entry RC001 'y')"
check_rc "a reused id is rejected" "$(rc)" 1
case "$(out)" in *RC001*) ok "the reused id is named" ;; *) bad "the reused id is named" "$(out)" ;; esac

log "$(entry RC001 'x')" "$(entry RC003 'y')"
check_rc "a gap in the sequence is rejected" "$(rc)" 1
case "$(out)" in *RC002*) ok "the missing id is named" ;; *) bad "the missing id is named" "$(out)" ;; esac

log "$(entry RC002 'x')" "$(entry RC001 'y')"
check_rc "out-of-order ids are rejected" "$(rc)" 1

log "$(entry RC1 'x')"
check_rc "a malformed id is rejected" "$(rc)" 1

# Every field carries weight: without Options the entry cannot show what was considered,
# without Conflicting rules it cannot be re-litigated from the record.
for field in Kind Tool Trigger Operation "Conflict explanation" "Options presented"; do
  header > "$WORK/log.md"
  entry RC001 'x' | grep -v "^\*\*$field:\*\*" | grep -v "^\*\*$field:\*\*$" >> "$WORK/log.md"
  check_rc "a missing '$field' field is rejected" "$(rc)" 1
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
