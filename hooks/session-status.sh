#!/usr/bin/env bash
# SessionStart hook: point the session at what needs attention (repo drift, fresh handoffs,
# an open timer, overdue conformance items, a project's own probe). The work is done by
# bin/session-status.sh --hook; see its header.
#
# Register as ~/.claude/hooks/session-status.sh. Profile-based setups link hooks/ into the
# profile but not bin/, so the path to bin/ is resolved physically from here.
#
# Advisory only: always exits 0.
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 0
[ -x "$here/../bin/session-status.sh" ] || exit 0
exec "$here/../bin/session-status.sh" --hook
