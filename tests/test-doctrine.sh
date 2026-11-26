#!/usr/bin/env bash
# test-doctrine.sh — tests for bin/doctrine.sh (marker-block propagation).
#
# dot-claude is primary; every other dot-* repo is downstream. These tests build a
# throwaway workspace so they never touch the real repos.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCTRINE="$SCRIPT_DIR/../bin/doctrine.sh"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
check_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected [$3], got [$2]"; }
check_rc() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected exit $3, got $2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-doctrine.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Build a fixture workspace: one primary, three downstream targets.
new_workspace() {
  rm -rf "$WORK"/ws; mkdir -p "$WORK"/ws/{primary,down-a,down-b,down-c}
  cat > "$WORK"/ws/primary/CLAUDE.md <<'EOF'
# Primary

Intro prose that is not part of any block.

<!-- doctrine-x: begin -->
## Doctrine X

Canonical text, revision 2.
<!-- doctrine-x: end -->

Trailing prose.
EOF
  # down-a: matches the primary exactly
  cat > "$WORK"/ws/down-a/CLAUDE.md <<'EOF'
# A

<!-- doctrine-x: begin -->
## Doctrine X

Canonical text, revision 2.
<!-- doctrine-x: end -->
EOF
  # down-b: carries a stale copy
  cat > "$WORK"/ws/down-b/CLAUDE.md <<'EOF'
# B

<!-- doctrine-x: begin -->
## Doctrine X

Stale text, revision 1.
<!-- doctrine-x: end -->
EOF
  # down-c: markers are backslash-escaped, as all five real repos are
  cat > "$WORK"/ws/down-c/CLAUDE.md <<'EOF'
# C

<\!-- doctrine-x: begin -->
## Doctrine X

Canonical text, revision 2.
<\!-- doctrine-x: end -->
EOF
  cat > "$WORK"/ws/targets.conf <<'EOF'
# block | path relative to workspace root
doctrine-x | down-a/CLAUDE.md
doctrine-x | down-b/CLAUDE.md
doctrine-x | down-c/CLAUDE.md
EOF
}

run() { ( cd "$WORK/ws" && "$DOCTRINE" --primary primary/CLAUDE.md --targets targets.conf "$@" ) 2>&1; }
rc()  { ( cd "$WORK/ws" && "$DOCTRINE" --primary primary/CLAUDE.md --targets targets.conf "$@" ) >/dev/null 2>&1; echo $?; }

echo "test-doctrine.sh"

if [ ! -x "$DOCTRINE" ]; then
  echo "  FAIL bin/doctrine.sh is missing or not executable — every assertion below would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# --- check ---------------------------------------------------------------
new_workspace
check_rc "check exits non-zero when any target is out of sync" "$(rc check)" 1

out="$(new_workspace; run check)"
case "$out" in *down-b/CLAUDE.md*) ok "check names the stale target" ;;
  *) bad "check names the stale target" "$out" ;; esac
case "$out" in
  *"down-b/CLAUDE.md"*) case "$out" in *down-a/CLAUDE.md*) bad "check stays quiet about the in-sync target" "$out" ;;
      *) ok "check stays quiet about the in-sync target" ;; esac ;;
  *) bad "check stays quiet about the in-sync target" "check produced no findings at all: $out" ;;
esac

# A backslash-escaped marker is not an HTML comment: it renders as visible text and
# defeats any tooling that looks for the real form. Treat it as a defect, not a match.
case "$out" in *down-c/CLAUDE.md*) ok "check flags backslash-escaped markers" ;;
  *) bad "check flags backslash-escaped markers" "$out" ;; esac

# --- missing block -------------------------------------------------------
new_workspace
mkdir -p "$WORK"/ws/down-d
printf '# D\n\nno block here\n' > "$WORK"/ws/down-d/CLAUDE.md
echo 'doctrine-x | down-d/CLAUDE.md' >> "$WORK"/ws/targets.conf
out="$(run check)"
case "$out" in *down-d/CLAUDE.md*) ok "check reports a target missing the block entirely" ;;
  *) bad "check reports a target missing the block entirely" "$out" ;; esac

# --- sync ----------------------------------------------------------------
new_workspace
run sync >/dev/null
check_rc "check passes after sync" "$(rc check)" 0

new_workspace; run sync >/dev/null
grep -q 'Canonical text, revision 2' "$WORK"/ws/down-b/CLAUDE.md \
  && ok "sync replaces stale downstream content" || bad "sync replaces stale downstream content"
grep -q 'Stale text' "$WORK"/ws/down-b/CLAUDE.md \
  && bad "sync removes the superseded text" || ok "sync removes the superseded text"
grep -q '^# B' "$WORK"/ws/down-b/CLAUDE.md \
  && ok "sync preserves content outside the block" || bad "sync preserves content outside the block"
grep -q '<\\!--' "$WORK"/ws/down-c/CLAUDE.md \
  && bad "sync repairs backslash-escaped markers" || ok "sync repairs backslash-escaped markers"

# sync must not disturb a target that is already correct
new_workspace
before="$(cat "$WORK"/ws/down-a/CLAUDE.md)"; run sync >/dev/null
check_eq "sync leaves an in-sync target byte-identical" "$(cat "$WORK"/ws/down-a/CLAUDE.md)" "$before"

# --- primary is never a target ------------------------------------------
new_workspace
before="$(cat "$WORK"/ws/primary/CLAUDE.md)"; run sync >/dev/null
check_eq "sync never rewrites the primary" "$(cat "$WORK"/ws/primary/CLAUDE.md)" "$before"

# --- several primaries ---------------------------------------------------
# Universal doctrine lives in CLAUDE.md and homelab doctrine in doctrine/homelab.md, so each
# block is read from whichever primary carries it. A block in two primaries is ambiguous.
new_workspace
mkdir -p "$WORK"/ws/second "$WORK"/ws/down-y
printf '# Second\n\n<!-- doctrine-y: begin -->\nDoctrine Y, canonical.\n<!-- doctrine-y: end -->\n' \
  > "$WORK"/ws/second/homelab.md
printf '# Y\n\n<!-- doctrine-y: begin -->\nDoctrine Y, stale.\n<!-- doctrine-y: end -->\n' \
  > "$WORK"/ws/down-y/CLAUDE.md
printf 'doctrine-x | down-a/CLAUDE.md\ndoctrine-y | down-y/CLAUDE.md\n' > "$WORK"/ws/targets.conf
run2() { ( cd "$WORK/ws" && "$DOCTRINE" --primary primary/CLAUDE.md --primary second/homelab.md --targets targets.conf "$@" ) 2>&1; }
rc2()  { ( cd "$WORK/ws" && "$DOCTRINE" --primary primary/CLAUDE.md --primary second/homelab.md --targets targets.conf "$@" ) >/dev/null 2>&1; echo $?; }
out="$(run2 check)"
case "$out" in *"down-y/CLAUDE.md: block \"doctrine-y\" differs"*) ok "check reads a block from the second primary" ;;
  *) bad "check reads a block from the second primary" "$out" ;; esac
case "$out" in *down-a/CLAUDE.md*) bad "a block in the first primary still matches" "$out" ;;
  *) ok "a block in the first primary still matches" ;; esac
run2 sync >/dev/null
grep -q 'Doctrine Y, canonical' "$WORK"/ws/down-y/CLAUDE.md \
  && ok "sync copies a block from the second primary" || bad "sync copies a block from the second primary"
check_rc "check passes after syncing from two primaries" "$(rc2 check)" 0

printf '\n<!-- doctrine-y: begin -->\nDoctrine Y, rival.\n<!-- doctrine-y: end -->\n' >> "$WORK"/ws/primary/CLAUDE.md
check_rc "a block in two primaries is an error" "$(rc2 check)" 2
case "$(run2 check)" in *"more than one primary"*) ok "the error says the block has two homes" ;;
  *) bad "the error says the block has two homes" "$(run2 check)" ;; esac

# --- the real primaries --------------------------------------------------
# Design-pattern discipline is universal, so it lives in CLAUDE.md, which loads on every host.
# Central ops knowledge is homelab doctrine, in doctrine/homelab.md, imported through host.md.
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
in_file() { grep -qx "<!-- $1: begin -->" "$2" 2>/dev/null; }
in_file design-patterns "$ROOT/CLAUDE.md" \
  && ok "CLAUDE.md carries design-patterns" || bad "CLAUDE.md carries design-patterns"
in_file central-ops-knowledge "$ROOT/doctrine/homelab.md" \
  && ok "doctrine/homelab.md carries central-ops-knowledge" || bad "doctrine/homelab.md carries central-ops-knowledge"
for b in $(awk -F'|' '/^[a-z]/ { gsub(/ /, "", $1); print $1 }' "$ROOT/doctrine/targets.conf" | sort -u); do
  n=0
  for f in "$ROOT/CLAUDE.md" "$ROOT/doctrine/homelab.md"; do in_file "$b" "$f" && n=$((n+1)); done
  check_eq "$b has exactly one home among the primaries" "$n" 1
done

rm -rf "$WORK"/real; mkdir -p "$WORK"/real/down; : > "$WORK"/real/targets.conf
for pair in design-patterns:CLAUDE.md central-ops-knowledge:doctrine/homelab.md; do
  b="${pair%%:*}"; src="$ROOT/${pair#*:}"
  { echo "<!-- $b: begin -->"
    awk -v b="$b" '$0=="<!-- "b": begin -->"{f=1;next} $0=="<!-- "b": end -->"{f=0} f' "$src" 2>/dev/null
    echo "<!-- $b: end -->"; echo; } >> "$WORK"/real/down/CLAUDE.md
  echo "$b | down/CLAUDE.md" >> "$WORK"/real/targets.conf
done
( cd "$WORK"/real && "$DOCTRINE" check --targets "$WORK"/real/targets.conf >/dev/null 2>&1 ); rc=$?
check_rc "the default primaries are CLAUDE.md and doctrine/homelab.md" "$rc" 0

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
