#!/usr/bin/env bash
# check-public-memory.sh — refuse to commit sensitive detail to a public repository.
#
# dot-claude is public. A family member's email address reached memory/MEMORY.md and sat in
# git history; a later edit does not erase it. This is a gate, not a nudge: it exits
# non-zero so CI fails before the next one lands.
#
# It scans only files intended to be public: memory/*.md and glossary/*.md. Private segments
# under memory/local/ and glossary/local/ are gitignored and are not scanned — that is where
# this content is supposed to live. Client vocabulary is often the most identifying thing in
# a repo, so the universal glossary is scanned like everything else.
#
#   check-public-memory.sh [FILE...]     default: <repo-root>/memory/*.md
#
# A deliberate, reviewed exception carries an inline marker on the same line:
#   <!-- public-ok: why this is safe -->
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ $# -gt 0 ]; then
  FILES=("$@")
else
  mapfile -t FILES < <({ find "$REPO_ROOT/memory" -maxdepth 1 -type f -name '*.md' 2>/dev/null
                         find "$REPO_ROOT/glossary" -maxdepth 1 -type f -name '*.md' 2>/dev/null; } | sort)
fi

# Pattern and what it catches, separated by ';;'. That delimiter rather than '|', which is
# regex alternation and appears inside several of the patterns. Ordered most-specific first
# so the message names the real reason rather than a generic match.
PATTERNS=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----;;a private key block'
  '\b(AKIA|ASIA)[0-9A-Z]{16}\b;;an AWS access key id'
  '\b(gh[pousr]|xox[baprs])_[A-Za-z0-9]{20,};;an API or bearer token'
  '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b;;an email address'
  '\b(10|127)\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b;;a private IPv4 address'
  '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b;;a private IPv4 address'
  '\b172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}\b;;a private IPv4 address'
  '\b[a-zA-Z0-9-]+\.local(:[0-9]+)?([^A-Za-z0-9.-]|$);;a LAN hostname'
  '(^|[^a-zA-Z0-9])/(Users|home)/[a-z][a-z0-9._-]*;;a home path carrying a username'
)

findings=0

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  rel="${f#"$REPO_ROOT"/}"
  for entry in "${PATTERNS[@]}"; do
    pat="${entry%%;;*}"
    why="${entry#*;;}"
    while IFS=: read -r lineno text; do
      [ -n "$lineno" ] || continue
      # A reviewed exception leaves a visible trace on the line itself.
      case "$text" in *'<!-- public-ok:'*) continue ;; esac
      printf '%s line %s: %s — must not appear in a public repo\n' "$rel" "$lineno" "$why"
      printf '    %s\n' "$(printf '%s' "$text" | sed 's/^[[:space:]]*//' | cut -c1-100)"
      findings=$((findings+1))
    done < <(grep -nE -- "$pat" "$f" || true)
  done
done

if [ "$findings" -eq 0 ]; then
  printf 'public memory: %d file(s) clean\n' "${#FILES[@]}"
else
  printf '\n%d finding(s). Move the detail to a private segment under `memory/local/` (gitignored)\n' "$findings"
  printf 'or to the okf-knowledge bundle behind kb-mcp, and leave a pointer here.\n'
  printf 'A reviewed exception may carry an inline `<!-- public-ok: reason -->` marker.\n'
  exit 1
fi
