#!/usr/bin/env bash
# account-context.sh — Claude Code statusLine helper.
#
# Reads the JSON status payload on stdin, extracts the current working
# directory, looks at the git remote (if any), and prints a short banner
# indicating which Claude subscription / account should be in use.
#
# Detection rule (per user direction, 2026-05-06):
#   - git remote.origin.url matches  github.com[:/]brightsign/*  →  BrightSign Enterprise
#   - any other remote (or none)                                  →  ScooterSoft / personal Claude Max
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
DIM=$'\033[2m'
RST=$'\033[0m'

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

[ -n "$branch" ] && printf ' %s· %s%s' "$DIM" "$branch" "$RST"
