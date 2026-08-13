#!/usr/bin/env bash
# Stop hook: Remind about session logging and handoff when significant work was done.
# Advisory only — stderr messages, never blocks session end.
# Checks: (1) session log written, (2) handoff written
# Searches both session-logs/ (shared cross-tool) and .claude/session-logs/ (legacy).

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

MODIFIED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || true)
ALL_CHANGES="${MODIFIED_FILES}"$'\n'"${UNTRACKED_FILES}"
TOTAL_CHANGES=$(echo "$ALL_CHANGES" | grep -c '.' 2>/dev/null || true)

if [[ "$TOTAL_CHANGES" -lt 3 ]]; then
  exit 0
fi

# --- Check 1: Session log reminder ---
# Look for a session log created recently (check shared + legacy locations)
RECENT_LOG=""
for log_dir in session-logs .claude/session-logs; do
  RECENT_LOG=$(find "$log_dir" -maxdepth 1 -name "session-*.md" \
    -mtime -1 -type f 2>/dev/null | head -1 || true)
  [[ -n "$RECENT_LOG" ]] && break
done

if [[ -z "$RECENT_LOG" ]]; then
  echo "Session reminder: ${TOTAL_CHANGES} files changed but no session log created. Consider running /session-logger." >&2
fi

# --- Check 2: Handoff reminder ---
if [[ "$TOTAL_CHANGES" -ge 5 ]]; then
  RECENT_HANDOFF=""
  for log_dir in session-logs .claude/session-logs; do
    RECENT_HANDOFF=$(find "$log_dir" -maxdepth 1 -name "handoff-*.md" \
      -mtime -1 -type f 2>/dev/null | head -1 || true)
    [[ -n "$RECENT_HANDOFF" ]] && break
  done

  if [[ -z "$RECENT_HANDOFF" ]]; then
    echo "Handoff reminder: ${TOTAL_CHANGES} files changed. Consider running /handoff to preserve context for the next session." >&2
  fi
fi

# --- Check 3: Action-items pruning reminder (project-agnostic — skips silently if absent) ---
# Looks for the outline-format tracker (see Catalyst-RCM's ACTION_ITEMS.md / lint-action-items skill):
# "#### AI-NNN · done|dropped · title" headings, with a "since YYYY-MM-DD" date on the next line.
if [[ -f "ACTION_ITEMS.md" ]] && grep -q "^## Open / Active" "ACTION_ITEMS.md" 2>/dev/null; then
  TODAY_EPOCH=$(date +%s)
  STALE_COUNT=0
  ITEM_DATES=$(grep -A2 -E "^#### AI-[0-9]+ · (done|dropped) ·" "ACTION_ITEMS.md" 2>/dev/null \
    | grep -oE "since [0-9]{4}-[0-9]{2}-[0-9]{2}" | awk '{print $2}' || true)
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    SINCE_EPOCH=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null) || continue
    DAYS=$(( (TODAY_EPOCH - SINCE_EPOCH) / 86400 ))
    if [[ "$DAYS" -gt 7 ]]; then
      STALE_COUNT=$((STALE_COUNT + 1))
    fi
  done <<< "$ITEM_DATES"

  if [[ "$STALE_COUNT" -gt 0 ]]; then
    echo "Action-items reminder: ${STALE_COUNT} item(s) in ACTION_ITEMS.md are past the 7-day prune window. Consider running /lint-action-items." >&2
  fi
fi

exit 0
