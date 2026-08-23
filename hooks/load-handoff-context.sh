#!/usr/bin/env bash
# SessionStart hook: Auto-inject most recent handoff context into new sessions.
# Advisory only — never blocks session start.
# Looks for handoff files in shared session-logs/ first, then legacy locations
# (.claude/session-logs/, .factory/logs/), then global ~/.claude/session-logs/.

set -euo pipefail

# Require jq — exit silently if unavailable (hook is advisory only)
if ! command -v jq > /dev/null 2>&1; then
  exit 0
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Only inject on fresh session startup
SOURCE=$(echo "$HOOK_INPUT" | jq -r '.source // empty' 2>/dev/null)
if [[ "$SOURCE" != "startup" ]]; then
  exit 0
fi

CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Freshness cutoff, as a plain ISO date. GNU date first, then BSD/macOS.
# If neither works we cannot judge staleness, so inject nothing rather than risk
# resurfacing an old handoff -- this hook is advisory and silence is the safe default.
CUTOFF=$(date -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F 2>/dev/null || true)
if [[ -z "$CUTOFF" ]]; then
  exit 0
fi

# Find the most recent handoff, checking shared cross-tool location first, then legacy paths.
#
# Both the ordering and the freshness test read the date out of the FILENAME, never mtime.
# mtime is not a property of the handoff, it is a property of the file on this disk, and git
# rewrites it: a clone or checkout stamps every file with the same instant. That made archived
# handoffs look brand new (observed 2026-08-20 -- five Catalyst-RCM handoffs from 2026-07-06..08
# all carrying an 2026-08-14 mtime, so all five passed a "modified in the last 7 days" filter),
# and it made this hook disagree with /pickup, which ordered by mtime while this ordered by name.
# The filename date is stamped once at write time and survives checkouts, so it is authoritative.
HANDOFF_FILE=""
for search_dir in "${CWD}/session-logs" "${CWD}/.claude/session-logs" "${CWD}/.factory/logs" "${HOME}/.claude/session-logs"; do
  if [[ ! -d "$search_dir" ]]; then
    continue
  fi

  CANDIDATE=""
  # Process substitution, not a pipe: `break` here would SIGPIPE the upstream sort and
  # pipefail would then kill the whole hook.
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    base=${f##*/}
    fdate=${base#handoff-}
    fdate=${fdate:0:10}
    # Ignore anything whose name does not carry a real ISO date.
    [[ "$fdate" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
    # ISO dates compare correctly as strings.
    [[ "$fdate" < "$CUTOFF" ]] && continue
    CANDIDATE="$f"
    break
  done < <(find "$search_dir" -maxdepth 1 -name "handoff-*.md" -type f 2>/dev/null | sort -r)

  if [[ -n "$CANDIDATE" ]]; then
    HANDOFF_FILE="$CANDIDATE"
    break
  fi
done

if [[ -z "$HANDOFF_FILE" ]]; then
  exit 0
fi

# Read the handoff content and emit as additionalContext
CONTEXT=$(cat "$HANDOFF_FILE")
FILENAME=$(basename "$HANDOFF_FILE")
PARENT_DIR=$(dirname "$HANDOFF_FILE")

jq -n \
  --arg ctx "Previous session handoff (from ${FILENAME}):"$'\n\n'"${CONTEXT}" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'

# Consume: move to archive so subsequent sessions don't reload stale context
ARCHIVE_DIR="${PARENT_DIR}/archive"
mkdir -p "$ARCHIVE_DIR"
mv "$HANDOFF_FILE" "$ARCHIVE_DIR/" 2>/dev/null || true

exit 0
