#!/usr/bin/env bash
# test-hooks.sh — tests for the hook scripts' deterministic parts.
#
# Hooks run unattended and are advisory, so a defect in one is silent by construction.
# These cover the branch detection that got it wrong first time: a repository with no
# commits makes `git rev-parse --abbrev-ref HEAD` print "HEAD" *and* exit non-zero, so a
# `|| fallback` appends the fallback to real output instead of replacing it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRECOMPACT="$SCRIPT_DIR/../hooks/pre-compact-memorialize.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

snapshot() { # run the hook in $1 and print the snapshot it wrote
  ( cd "$1" && printf '{"trigger":"auto"}' | "$PRECOMPACT" >/dev/null 2>&1
    cat session-logs/precompact-*.md 2>/dev/null || cat .claude/session-logs/precompact-*.md 2>/dev/null )
}
branch_line() { snapshot "$1" | awk '/^branch:/ {print; exit}'; }

echo "test-hooks.sh"
if [ ! -x "$PRECOMPACT" ]; then
  echo "  FAIL hooks/pre-compact-memorialize.sh is missing or not executable"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# Frontmatter must stay parseable, so every value has to be exactly one line.
one_line() { # $1 = dir, $2 = label
  d="$WORK/$1"; n="$(snapshot "$d" | awk '/^---$/{c++; next} c==1' | grep -c '^[a-z]*:')"
  t="$(snapshot "$d" | awk '/^---$/{c++; next} c==1' | wc -l)"
  [ "$n" = "$t" ] && ok "$2: frontmatter is one value per line" \
                  || bad "$2: frontmatter is one value per line" "$(snapshot "$d" | head -10)"
}

mkdir -p "$WORK/nogit"; one_line nogit "outside a git repo"

mkdir -p "$WORK/fresh"; ( cd "$WORK/fresh" && git init -q . )
one_line fresh "in a repo with no commits"
case "$(branch_line "$WORK/fresh")" in
  *"not a git repo"*) bad "a repo with no commits is not reported as 'not a git repo'" "$(branch_line "$WORK/fresh")" ;;
  *) ok "a repo with no commits is not reported as 'not a git repo'" ;;
esac

mkdir -p "$WORK/committed"
( cd "$WORK/committed" && git init -q -b feature/x . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m x )
one_line committed "in a repo with commits"
case "$(branch_line "$WORK/committed")" in
  *feature/x*) ok "reports the actual branch name" ;;
  *) bad "reports the actual branch name" "$(branch_line "$WORK/committed")" ;;
esac

# The hook must never break compaction, whatever it finds.
mkdir -p "$WORK/nogit2"
( cd "$WORK/nogit2" && printf '{"trigger":"auto"}' | "$PRECOMPACT" >/dev/null 2>&1 )
[ $? -eq 0 ] && ok "always exits 0 — advisory, never blocks compaction" \
             || bad "always exits 0 — advisory, never blocks compaction"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
