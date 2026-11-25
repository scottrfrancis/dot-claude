#!/usr/bin/env bash
# Deprecated name, kept so hosts whose settings.json still registers it get the new
# behaviour without an edit. Register hooks/session-status.sh instead; delete this file once
# no host registers it.
#
# This hook used to paste the newest handoff into context and move it to archive/, so any
# session started in the directory consumed the handoff meant for the real continuation.
# Handoffs are now pointed at, and /pickup is the only reader.
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 0
[ -x "$here/session-status.sh" ] || exit 0
exec "$here/session-status.sh"
