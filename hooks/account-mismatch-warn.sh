#!/usr/bin/env bash
# SessionStart hook: warn when the cwd's expected Claude account doesn't
# match the actually-logged-in oauth account. Advisory only.
#
# Cwd-expected detection mirrors ~/.claude/scripts/account-context.sh:
# .account-context marker beats git remote.
# Actual-account detection reads oauthAccount from Claude Code's global config:
# $CLAUDE_CONFIG_DIR/.claude.json when that is set (the claude-profile launcher sets
# it), else ~/.claude.json.
# Emits a one-line additionalContext warning on mismatch; silent otherwise.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

# Clients come from this host's private table (bin/accounts-lookup.sh, reading the gitignored
# accounts.local); the built-in cases below cover only my own accounts.
LOOKUP="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)/bin/accounts-lookup.sh"
lookup() { if [ -x "$LOOKUP" ]; then "$LOOKUP" "$@"; fi; }

HOOK_INPUT=$(cat)
SOURCE=$(echo "$HOOK_INPUT" | jq -r '.source // empty' 2>/dev/null)
[ "$SOURCE" = "startup" ] || exit 0

CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] || CWD="$PWD"

# --- Expected (from cwd) ---
marker=""
dir="$CWD"
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/.account-context" ]; then
    marker=$(head -1 "$dir/.account-context" 2>/dev/null | tr -d ' \t\r\n' | tr '[:upper:]' '[:lower:]')
    break
  fi
  parent=$(dirname "$dir")
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done

remote=$(git -C "$CWD" config --get remote.origin.url 2>/dev/null || true)

expected=""
expected_label=""
if [ -n "$marker" ]; then
  case "$marker" in
    ailab)                expected="al"; expected_label="AI Lab Team" ;;
    scootersoft|personal) expected="ss"; expected_label="ScooterSoft / Personal" ;;
    *)
      row="$(lookup marker "$marker")"
      if [ -n "$row" ]; then expected="${row%%$'\t'*}"; expected_label="${row##*$'\t'}"; fi ;;
  esac
else
  row="$(lookup remote "$remote")"
  if [ -n "$row" ]; then
    expected="${row%%$'\t'*}"; expected_label="${row##*$'\t'}"
  else
    case "$remote" in
      *github.com[:/]scottrfrancis/*) expected="ss"; expected_label="ScooterSoft / Personal" ;;
    esac
  fi
fi

# Ambiguous expected → no warning to emit
case "$expected" in ss|bs|al) ;; *) exit 0 ;; esac

# --- Actual (from Claude Code's global config) ---
CFG="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
[ -f "$CFG" ] || exit 0
org_name=$(jq -r '.oauthAccount.organizationName // ""' "$CFG" 2>/dev/null)
org_type=$(jq -r '.oauthAccount.organizationType // ""' "$CFG" 2>/dev/null)
email=$(jq -r '.oauthAccount.emailAddress // ""' "$CFG" 2>/dev/null)

actual=""
actual_label=""
row="$(lookup org "$org_name")"
if [ -n "$row" ]; then
  actual="${row%%$'\t'*}"; actual_label="${row##*$'\t'} ($email)"
else
  case "$org_name" in
    *"AI Lab"*|*"ailab"*|*"AILab"*)
      actual="al"; actual_label="$org_name ($email)" ;;
    "")
      actual="ss"; actual_label="Personal ($email)" ;;
    *)
      case "$org_type" in
        claude_individual|claude_max|claude_pro|"")
          actual="ss"; actual_label="${org_name:-Personal} ($email)" ;;
        *)
          exit 0 ;;
      esac ;;
  esac
fi

[ "$expected" = "$actual" ] && exit 0

# Mismatch — emit warning context
WARNING=$(cat <<EOF
ACCOUNT MISMATCH WARNING

This workspace ($CWD) expects: $expected_label
But Claude Code is logged into: $actual_label

Per project CLAUDE.md cost-management posture, the wrong account is paying
for this session. To switch:

  /logout
  /login  (with the $expected_label account)
  Reopen Claude Code with this directory as cwd

The statusline tag reflects the EXPECTED account (cwd-derived). The actual
billing account is independent — only logout/login changes it.
EOF
)

jq -n --arg ctx "$WARNING" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

exit 0
