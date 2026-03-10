#!/usr/bin/env bash
# Stop hook: Remind about session logging and handoff when significant work was done.
# Advisory only — stderr messages, never blocks session end.
# Checks: (1) session log written, (2) handoff written

set -euo pipefail

# Read hook input from stdin
cat > /dev/null

# Require git
if ! command -v git > /dev/null 2>&1; then
  exit 0
fi

# Must be in a git repo to detect changes
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  exit 0
fi

# .claude/session-logs must exist or checks are meaningless
if [[ ! -d ".claude/session-logs" ]]; then
  exit 0
fi

MODIFIED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || true)
ALL_CHANGES="${MODIFIED_FILES}"$'\n'"${UNTRACKED_FILES}"
TOTAL_CHANGES=$(echo "$ALL_CHANGES" | grep -c '.' 2>/dev/null || true)

if [[ "$TOTAL_CHANGES" -lt 3 ]]; then
  exit 0
fi

# --- Check 1: Session log reminder ---
# Look for a session log created today (mtime -1 = within 24h; BSD/macOS + GNU compatible)
# Excludes handoff and mine-report files
RECENT_LOG=$(find .claude/session-logs -maxdepth 1 -name "*.md" \
  ! -name "handoff-*" ! -name "mine-report-*" \
  -mtime -1 -type f 2>/dev/null | head -1 || true)

if [[ -z "$RECENT_LOG" ]]; then
  echo "Session reminder: ${TOTAL_CHANGES} files changed but no session log created. Consider running /session-logger." >&2
fi

# --- Check 2: Handoff reminder ---
if [[ "$TOTAL_CHANGES" -ge 5 ]]; then
  RECENT_HANDOFF=$(find .claude/session-logs -maxdepth 1 -name "handoff-*.md" \
    -mtime -1 -type f 2>/dev/null | head -1 || true)

  if [[ -z "$RECENT_HANDOFF" ]]; then
    echo "Handoff reminder: ${TOTAL_CHANGES} files changed. Consider running /handoff to preserve context for the next session." >&2
  fi
fi

exit 0
