#!/usr/bin/env bash
# SessionStart hook: surface overdue maintenance at the start of a session.
#
# /mine-sessions, and the conformance work generally, fail by never being invoked. The
# existing Stop hook already nudges about /session-logger and /handoff, and one more
# end-of-session reminder competes with those and with the urge to stop working. Session
# start is where there is both attention and intent to act.
#
# Advisory only — never blocks session start, never fails a session.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

HOOK_INPUT="$(cat)"
[ "$(printf '%s' "$HOOK_INPUT" | jq -r '.source // empty' 2>/dev/null)" = "startup" ] || exit 0

PROBE="${HOME}/.claude/bin/conformance.sh"
[ -x "$PROBE" ] || PROBE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" 2>/dev/null && pwd)/conformance.sh"
[ -x "$PROBE" ] || exit 0

# The probe is advisory and always exits 0; --quiet keeps it silent when nothing is overdue.
REPORT="$("$PROBE" --project "$PWD" --quiet 2>/dev/null)" || exit 0
[ -n "$REPORT" ] || exit 0

jq -n --arg ctx "$REPORT"$'\n\n'"Mention these to the user once, briefly, when the session's first task is settled. Do not act on them unprompted, and do not repeat them later in the session." \
  '{ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $ctx } }'

exit 0
