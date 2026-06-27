#!/usr/bin/env bash
# SessionStart hook: warn when the cwd's expected Claude account doesn't
# match the actually-logged-in oauth account. Advisory only.
#
# Cwd-expected detection mirrors ~/.claude/scripts/account-context.sh:
# .account-context marker beats git remote.
# Actual-account detection reads ~/.claude.json oauthAccount.
# Emits a one-line additionalContext warning on mismatch; silent otherwise.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

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
    brightsign)           expected="bs"; expected_label="BrightSign Enterprise" ;;
    scootersoft|personal) expected="ss"; expected_label="ScooterSoft / Personal" ;;
  esac
else
  case "$remote" in
    *github.com[:/]brightsign/*)    expected="bs"; expected_label="BrightSign Enterprise" ;;
    *github.com[:/]scottrfrancis/*) expected="ss"; expected_label="ScooterSoft / Personal" ;;
  esac
fi

# Ambiguous expected → no warning to emit
case "$expected" in ss|bs|al) ;; *) exit 0 ;; esac

# --- Actual (from ~/.claude.json) ---
[ -f "$HOME/.claude.json" ] || exit 0
org_name=$(jq -r '.oauthAccount.organizationName // ""' "$HOME/.claude.json" 2>/dev/null)
org_type=$(jq -r '.oauthAccount.organizationType // ""' "$HOME/.claude.json" 2>/dev/null)
email=$(jq -r '.oauthAccount.emailAddress // ""' "$HOME/.claude.json" 2>/dev/null)

actual=""
actual_label=""
case "$org_name" in
  BrightSign|Brightsign|brightsign)
    actual="bs"; actual_label="BrightSign Enterprise ($email)" ;;
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
