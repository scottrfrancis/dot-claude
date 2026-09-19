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

WORK="$(mktemp -d)"
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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
