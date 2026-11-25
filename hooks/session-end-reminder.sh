#!/usr/bin/env bash
# Stop hook: Remind about session logging and handoff when significant work was done.
# Advisory only — stderr messages, never blocks session end.
# Checks: (1) session log written, (2) handoff written
# Searches both session-logs/ (shared cross-tool) and .claude/session-logs/ (legacy).
#
# Stop fires at the end of every reply, not at session end, so this speaks once per
# session_id: a marker under $TMPDIR records that the session has been reminded. Without a
# session_id it falls back to reminding every time.

set -euo pipefail

HOOK_INPUT="$(cat 2>/dev/null || true)"
SESSION_ID="$(printf '%s' "$HOOK_INPUT" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[A-Za-z0-9_-]+"' \
  | head -1 | sed -E 's/.*"([A-Za-z0-9_-]+)"$/\1/' || true)"
MARKER=""
if [[ -n "$SESSION_ID" ]]; then
  MARKER="${TMPDIR:-/tmp}/claude-stop-reminder/$SESSION_ID"
  [[ -e "$MARKER" ]] && exit 0
fi
# Record the reminder only when one was actually given, so a session that starts quiet is
# still reminded once it has changed enough files.
remind() {
  echo "$1" >&2
  if [[ -n "$MARKER" ]]; then
    mkdir -p "$(dirname "$MARKER")" 2>/dev/null && : > "$MARKER" 2>/dev/null || true
  fi
}

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

# Today, for the "was one written this session" checks below. Both of them read the date out
# of the FILENAME rather than mtime: git rewrites mtime, so after a clone or checkout every
# archived log looks like it was written today and these reminders go silent exactly when a
# fresh checkout means they are most needed. (Observed 2026-08-20 in Contoso: five
# handoffs from 2026-07-06..08 all carrying a 2026-08-14 mtime.)
TODAY=$(date +%F)

# --- Check 1: Session log reminder ---
# Look for a session log written today (check shared + legacy locations)
RECENT_LOG=""
for log_dir in session-logs .claude/session-logs; do
  RECENT_LOG=$(ls -1 "$log_dir"/session-"$TODAY"-*.md 2>/dev/null | head -1 || true)
  [[ -n "$RECENT_LOG" ]] && break
done

if [[ -z "$RECENT_LOG" ]]; then
  remind "Session reminder: ${TOTAL_CHANGES} files changed but no session log created. Consider running /session-logger."
fi

# --- Check 2: Handoff reminder ---
if [[ "$TOTAL_CHANGES" -ge 5 ]]; then
  RECENT_HANDOFF=""
  for log_dir in session-logs .claude/session-logs; do
    RECENT_HANDOFF=$(ls -1 "$log_dir"/handoff-"$TODAY"-*.md 2>/dev/null | head -1 || true)
    [[ -n "$RECENT_HANDOFF" ]] && break
  done

  if [[ -z "$RECENT_HANDOFF" ]]; then
    remind "Handoff reminder: ${TOTAL_CHANGES} files changed. Consider running /handoff to preserve context for the next session."
  fi
fi

# --- Check 3: Action-items pruning reminder (project-agnostic — skips silently if absent) ---
# Looks for the outline-format tracker (see Contoso's ACTION_ITEMS.md / lint-action-items skill):
# "#### AI-NNN · done|dropped · title" headings, with a "since YYYY-MM-DD" date on the next line.
if [[ -f "ACTION_ITEMS.md" ]] && grep -q "^## Open / Active" "ACTION_ITEMS.md" 2>/dev/null; then
  TODAY_EPOCH=$(date +%s)
  STALE_COUNT=0
  ITEM_DATES=$(grep -A2 -E "^#### AI-[0-9]+ · (done|dropped) ·" "ACTION_ITEMS.md" 2>/dev/null \
    | grep -oE "since [0-9]{4}-[0-9]{2}-[0-9]{2}" | awk '{print $2}' || true)
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    SINCE_EPOCH=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || date -d "$d" +%s 2>/dev/null) || continue
    DAYS=$(( (TODAY_EPOCH - SINCE_EPOCH) / 86400 ))
    if [[ "$DAYS" -gt 7 ]]; then
      STALE_COUNT=$((STALE_COUNT + 1))
    fi
  done <<< "$ITEM_DATES"

  if [[ "$STALE_COUNT" -gt 0 ]]; then
    remind "Action-items reminder: ${STALE_COUNT} item(s) in ACTION_ITEMS.md are past the 7-day prune window. Consider running /lint-action-items."
  fi
fi

exit 0
