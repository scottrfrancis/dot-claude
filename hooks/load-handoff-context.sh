#!/usr/bin/env bash
# SessionStart hook: Auto-inject most recent handoff context into new sessions.
# Advisory only — never blocks session start.
# Looks for handoff files in project-local .claude/session-logs/ first,
# then falls back to ~/.claude/session-logs/.

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

# Find most recent handoff file, checking project-local first then global
HANDOFF_FILE=""
for search_dir in "${CWD}/.claude/session-logs" "${HOME}/.claude/session-logs"; do
  if [[ ! -d "$search_dir" ]]; then
    continue
  fi

  # Find handoff files modified within 7 days, most recent first
  # -mtime -7 is POSIX/BSD-safe (days); sort -r picks the most recent by name (YYYY-MM-DD prefix)
  CANDIDATE=$(find "$search_dir" -maxdepth 1 -name "handoff-*.md" -type f -mtime -7 2>/dev/null \
    | sort -r \
    | head -1)

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
