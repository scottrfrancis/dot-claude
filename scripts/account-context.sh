#!/usr/bin/env bash
# account-context.sh — Claude Code statusLine helper.
#
# Reads the JSON status payload on stdin, extracts the current working
# directory, and prints a short banner indicating which Claude
# subscription / account should be in use.
#
# Detection order:
#   1) Walk up from cwd looking for a `.account-context` file. If found,
#      the first non-empty token in it is the answer:
#        ailab        →  AI Lab team subscription          (cyan, [AL-Team])
#        brightsign   →  BrightSign Enterprise sub         (red,  [BS-Enterprise])
#        scootersoft  →  ScooterSoft / personal Claude Max (green,[SS-Personal])
#      The marker beats the git remote — use it for clients with mixed
#      GitHub ownership (e.g., a workspace where some repos belong to the
#      client, some to me, but billing is consistent).
#
#   2) If no marker is found, fall back to the git remote:
#        github.com[:/]brightsign/...     →  BrightSign Enterprise
#        github.com[:/]scottrfrancis/...  →  ScooterSoft / personal Claude Max
#        anything else / no remote        →  [other] / [no-remote]
#
# Output is intentionally short — statuslines truncate aggressively.

set -u

# Pull cwd from the JSON Claude Code sends in. Fall back to $PWD if absent.
payload=$(cat 2>/dev/null || true)
cwd=""
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
  cwd=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // ""' 2>/dev/null)
fi
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd="$PWD"

# Walk up looking for a .account-context marker.
marker=""
dir="$cwd"
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/.account-context" ]; then
    marker=$(head -1 "$dir/.account-context" 2>/dev/null | tr -d ' \t\r\n' | tr '[:upper:]' '[:lower:]')
    break
  fi
  parent=$(dirname "$dir")
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done

remote=$(git -C "$cwd" config --get remote.origin.url 2>/dev/null || true)
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || true)

# Format the repo's short path (org/name) from any common remote URL form.
repo_short=""
case "$remote" in
  git@github.com:*)        repo_short="${remote#git@github.com:}" ;;
  https://github.com/*)    repo_short="${remote#https://github.com/}" ;;
  ssh://git@github.com/*)  repo_short="${remote#ssh://git@github.com/}" ;;
  *)                       repo_short="$remote" ;;
esac
repo_short="${repo_short%.git}"

# ANSI color escapes (bold + color)
RED=$'\033[1;31m'
GRN=$'\033[1;32m'
YEL=$'\033[1;33m'
CYN=$'\033[1;36m'
DIM=$'\033[2m'
RST=$'\033[0m'

# Marker takes precedence; remote is the fallback.
if [ -n "$marker" ]; then
  case "$marker" in
    ailab)
      printf '%s[AL-Team]%s %s' "$CYN" "$RST" "$repo_short"
      ;;
    brightsign)
      printf '%s[BS-Enterprise]%s %s' "$RED" "$RST" "$repo_short"
      ;;
    scootersoft|personal)
      printf '%s[SS-Personal]%s %s' "$GRN" "$RST" "$repo_short"
      ;;
    *)
      printf '%s[marker:%s]%s %s' "$YEL" "$marker" "$RST" "$repo_short"
      ;;
  esac
else
  case "$remote" in
    *github.com[:/]brightsign/*)
      printf '%s[BS-Enterprise]%s %s' "$RED" "$RST" "$repo_short"
      ;;
    *github.com[:/]scottrfrancis/*)
      printf '%s[SS-Personal]%s %s' "$GRN" "$RST" "$repo_short"
      ;;
    '')
      printf '%s[no-remote]%s' "$DIM" "$RST"
      ;;
    *)
      printf '%s[other]%s %s' "$YEL" "$RST" "$repo_short"
      ;;
  esac
fi

[ -n "$branch" ] && printf ' %s· %s%s' "$DIM" "$branch" "$RST"
