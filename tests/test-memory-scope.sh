#!/usr/bin/env bash
# test-memory-scope.sh — tests for bin/memory-scope.sh
#
# Work spans several clients and personal projects. Facts learned for one client must never
# be loaded while working for another, so the resolver's most important property is what it
# does NOT emit.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCOPE="$SCRIPT_DIR/../bin/memory-scope.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected '$3' in: $2" ;; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1" "must NOT contain '$3': $2" ;; *) ok "$1" ;; esac; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

setup() {
  rm -rf "$WORK"/h "$WORK"/p
  mkdir -p "$WORK"/h/memory/local/ailab "$WORK"/h/memory/local/brightsign \
           "$WORK"/h/memory/local/scootersoft "$WORK"/p/.claude/memory
  echo x > "$WORK"/h/memory/MEMORY.md
  echo x > "$WORK"/h/memory/local/MEMORY.md
  echo x > "$WORK"/h/memory/local/ailab/MEMORY.md
  echo x > "$WORK"/h/memory/local/brightsign/MEMORY.md
  echo x > "$WORK"/h/memory/local/scootersoft/MEMORY.md
  echo x > "$WORK"/p/.claude/memory/MEMORY.md
}
run() { "$SCOPE" --home "$WORK/h" --project "$WORK/p" "$@" 2>&1; }

echo "test-memory-scope.sh"
# A relative path must terminate the marker walk-up. "dirname ." is "." forever.
setup
if timeout 5 "$SCOPE" --home "$WORK/h" --project . --segment >/dev/null 2>&1; then
  ok "a relative --project terminates"
else
  [ $? -eq 124 ] && bad "a relative --project terminates" "hung — walk-up did not terminate" \
                 || ok "a relative --project terminates"
fi
if [ ! -x "$SCOPE" ]; then
  echo "  FAIL bin/memory-scope.sh is missing or not executable — assertions would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# --- segment comes from the .account-context marker ----------------------
setup; echo ailab > "$WORK"/p/.account-context
out="$(run)"
has   "loads the universal segment"            "$out" "h/memory/MEMORY.md"
has   "loads the private personal segment"     "$out" "local/MEMORY.md"
has   "loads the matching client segment"      "$out" "local/ailab/MEMORY.md"
has   "loads project memory"                   "$out" "p/.claude/memory/MEMORY.md"
hasnt "NEVER loads a non-matching client"      "$out" "brightsign"
hasnt "NEVER loads another non-matching one"   "$out" "scootersoft"
has   "reports the resolved segment"           "$(run --segment)" "ailab"

# the marker is found by walking up, as account-context.sh does
setup; echo brightsign > "$WORK"/p/.account-context; mkdir -p "$WORK"/p/sub/deep
out="$("$SCOPE" --home "$WORK/h" --project "$WORK/p/sub/deep" 2>&1)"
has   "walks up to find the marker"            "$out" "local/brightsign/MEMORY.md"
hasnt "still excludes the others"              "$out" "ailab"

# --- git remote is the fallback ------------------------------------------
setup; ( cd "$WORK"/p && git init -q . && git remote add origin https://github.com/scottrfrancis/x.git )
has   "falls back to the git remote"           "$(run --segment)" "scootersoft"

setup; ( cd "$WORK"/p && git init -q . && git remote add origin https://github.com/brightsign/y.git )
has   "maps a client remote to its segment"    "$(run --segment)" "brightsign"

# --- unknown context loads nothing client-specific -----------------------
setup
out="$(run)"
hasnt "an unknown context loads no client memory (a)" "$out" "ailab"
hasnt "an unknown context loads no client memory (b)" "$out" "brightsign"
hasnt "an unknown context loads no client memory (c)" "$out" "scootersoft"
has   "but still loads the universal segment"  "$out" "h/memory/MEMORY.md"

# --- only files that exist are emitted -----------------------------------
setup; echo ailab > "$WORK"/p/.account-context; rm "$WORK"/h/memory/local/ailab/MEMORY.md
hasnt "skips a segment file that does not exist" "$(run)" "local/ailab"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
