#!/usr/bin/env bash
# account-context.sh — Claude Code statusLine helper.
#
# Reads the JSON status payload on stdin, extracts the current working
# directory, and prints a short banner indicating which Claude
# subscription / account should be in use — AND warns when the
# actually-logged-in oauth account disagrees with what cwd expects.
#
# Detection order for the EXPECTED account:
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
# Detection for the ACTUAL (paying) account reads ~/.claude.json
# oauthAccount.organizationName and organizationType. When expected !=
# actual, the tag is replaced with a loud inverse-red mismatch banner so
# the wrong-account-paying state can't be missed.
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
INV_RED=$'\033[1;7;31m'   # inverse + bold red — used for mismatch warning
RST=$'\033[0m'

# --- Resolve EXPECTED account code (ss|bs|al|other|none) from cwd ---
expected=""
if [ -n "$marker" ]; then
  case "$marker" in
    ailab)               expected="al" ;;
    brightsign)          expected="bs" ;;
    scootersoft|personal) expected="ss" ;;
    *)                   expected="marker:$marker" ;;
  esac
else
  case "$remote" in
    *github.com[:/]brightsign/*)    expected="bs" ;;
    *github.com[:/]scottrfrancis/*) expected="ss" ;;
    '')                              expected="none" ;;
    *)                               expected="other" ;;
  esac
fi

# --- Resolve ACTUAL (logged-in) account code from ~/.claude.json ---
# Conservative mapping; unknowns fall through to "actual_other".
actual=""
actual_label=""
if [ -f "$HOME/.claude.json" ] && command -v jq >/dev/null 2>&1; then
  org_name=$(jq -r '.oauthAccount.organizationName // ""' "$HOME/.claude.json" 2>/dev/null)
  org_type=$(jq -r '.oauthAccount.organizationType // ""' "$HOME/.claude.json" 2>/dev/null)
  case "$org_name" in
    BrightSign|Brightsign|brightsign)
      actual="bs"; actual_label="BrightSign" ;;
    *"AI Lab"*|*"ailab"*|*"AILab"*)
      actual="al"; actual_label="$org_name" ;;
    "")
      # No team org — assume personal Claude Max
      actual="ss"; actual_label="Personal" ;;
    *)
      case "$org_type" in
        claude_individual|claude_max|claude_pro|"")
          actual="ss"; actual_label="${org_name:-Personal}" ;;
        *)
          actual="other"; actual_label="$org_name" ;;
      esac ;;
  esac
fi

# --- Decide if we have an actionable mismatch ---
# Mismatch only when both sides resolve cleanly AND disagree.
# "none"/"other"/"marker:*" expected states are ambiguous — suppress warning.
mismatch=0
if [ -n "$actual" ] && [ "$actual" != "other" ]; then
  case "$expected" in
    ss|bs|al)
      [ "$expected" != "$actual" ] && mismatch=1 ;;
  esac
fi

# --- Render ---
if [ "$mismatch" = "1" ]; then
  # Loud inverse-red warning replaces the normal tag.
  exp_upper=$(printf '%s' "$expected" | tr '[:lower:]' '[:upper:]')
  act_upper=$(printf '%s' "$actual"   | tr '[:lower:]' '[:upper:]')
  printf '%s[!! AUTH MISMATCH: cwd=%s auth=%s (%s) ]%s %s' \
    "$INV_RED" "$exp_upper" "$act_upper" "$actual_label" "$RST" "$repo_short"
else
  case "$expected" in
    al)             printf '%s[AL-Team]%s %s' "$CYN" "$RST" "$repo_short" ;;
    bs)             printf '%s[BS-Enterprise]%s %s' "$RED" "$RST" "$repo_short" ;;
    ss)             printf '%s[SS-Personal]%s %s' "$GRN" "$RST" "$repo_short" ;;
    none)           printf '%s[no-remote]%s' "$DIM" "$RST" ;;
    other)          printf '%s[other]%s %s' "$YEL" "$RST" "$repo_short" ;;
    marker:*)       printf '%s[%s]%s %s' "$YEL" "$expected" "$RST" "$repo_short" ;;
  esac
fi

[ -n "$branch" ] && printf ' %s· %s%s' "$DIM" "$branch" "$RST"

exit 0
