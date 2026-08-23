#!/usr/bin/env bash
# memory-scope.sh — which memory files apply to the current working context?
#
# Work spans several clients and personal projects, and they share some facts but not most.
# Memory is therefore segmented, and the segment is resolved exactly as
# scripts/account-context.sh resolves the billing account: a `.account-context` marker found
# by walking up from the working directory, falling back to the git remote. One resolver,
# so the segment a fact is filed under always matches the account the work is billed to.
#
# Load order, narrowest last (later files win on conflict):
#
#   memory/MEMORY.md                       universal   committed, PUBLIC — no private detail
#   memory/local/MEMORY.md                 personal    gitignored
#   memory/local/<segment>/MEMORY.md       per-client  gitignored
#   <project>/.claude/memory/MEMORY.md     project     lives in the project repo
#
# The property that matters most is what is NOT emitted: a client segment is loaded only
# when the working context resolves to that client. An unknown context loads no client
# memory at all rather than guessing.
#
# Glossary entries are segmented for the same reason and by the same resolver: a term can
# mean one thing for one client and another elsewhere. `--kind glossary` resolves
# GLOSSARY.md under glossary/ instead of MEMORY.md under memory/.
#
#   memory-scope.sh [--project DIR] [--home DIR] [--segment] [--kind memory|glossary]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$PWD"
SEGMENT_ONLY=0
KIND="memory"

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --home)    HOME_DIR="$2"; shift 2 ;;
    --segment) SEGMENT_ONLY=1; shift ;;
    --kind)    KIND="$2"; shift 2 ;;
    -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'memory-scope.sh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

# Resolve to an absolute path first: the walk-up below terminates on "/", and
# `dirname .` is "." forever.
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd || printf '%s' "$PROJECT")"
[ -n "$HOME_DIR" ] && HOME_DIR="$(cd "$HOME_DIR" 2>/dev/null && pwd || printf '%s' "$HOME_DIR")"

# --- resolve the segment -------------------------------------------------
segment=""

# 1. A `.account-context` marker, found by walking up. It beats the remote, for clients
#    whose repos have mixed GitHub ownership but consistent billing.
dir="$PROJECT"
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/.account-context" ]; then
    segment="$(head -1 "$dir/.account-context" 2>/dev/null | tr -d ' \t\r\n' | tr '[:upper:]' '[:lower:]')"
    break
  fi
  dir="$(dirname "$dir")"
done

# 2. Otherwise the git remote.
if [ -z "$segment" ] && [ -d "$PROJECT" ]; then
  remote="$(git -C "$PROJECT" remote get-url origin 2>/dev/null || true)"
  case "$remote" in
    *github.com[:/]brightsign/*)    segment="brightsign" ;;
    *github.com[:/]scottrfrancis/*) segment="scootersoft" ;;
  esac
fi

if [ "$SEGMENT_ONLY" -eq 1 ]; then
  printf '%s\n' "${segment:-unknown}"
  exit 0
fi

# --- emit the applicable files, narrowest last ---------------------------
emit() { [ -f "$1" ] && printf '%s\n' "$1"; return 0; }

case "$KIND" in
  memory)   dir="memory";   file="MEMORY.md" ;;
  glossary) dir="glossary"; file="GLOSSARY.md" ;;
  *) printf 'memory-scope.sh: unknown --kind: %s (expected memory or glossary)\n' "$KIND" >&2; exit 2 ;;
esac

emit "$HOME_DIR/$dir/$file"
emit "$HOME_DIR/$dir/local/$file"
# No segment means no client-specific file. Guessing here is how one client's vocabulary or
# facts reach another.
[ -n "$segment" ] && emit "$HOME_DIR/$dir/local/$segment/$file"
emit "$PROJECT/.claude/$dir/$file"

exit 0
