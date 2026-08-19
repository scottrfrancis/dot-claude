#!/usr/bin/env bash
# conformance.sh — is anything overdue?
#
# Running /mine-sessions costs an LLM pass over every session log. Knowing whether it is
# worth running costs a few stat calls. This is the second thing: a deterministic probe
# whose output is surfaced at session start, when there is attention and intent to act on
# it, rather than at session end when the goal is to leave.
#
# Per guidelines/ai-cron-tool-delegation.md: when a decision turns on a number, compute the
# number here rather than asking a model to estimate it.
#
# Advisory. Always exits 0 — "you have not mined in a while" is not an error. The real
# gates are bin/doctrine.sh check and bin/check-conflict-log.sh.
#
#   conformance.sh [--project DIR] [--quiet]
#
#   MINE_STALE_SESSIONS   sessions since last mine before flagging   (default 10)
#   MINE_STALE_DAYS       days since last mine before flagging       (default 30)
set -euo pipefail

PROJECT="$PWD"
QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'conformance.sh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

STALE_SESSIONS="${MINE_STALE_SESSIONS:-10}"
STALE_DAYS="${MINE_STALE_DAYS:-30}"

# Session records live in the shared cross-tool location first, then legacy paths.
LOGDIR=""
for d in "$PROJECT/session-logs" "$PROJECT/.claude/session-logs" "$PROJECT/.factory/logs"; do
  [ -d "$d" ] && { LOGDIR="$d"; break; }
done

findings=()

# --- mining staleness ----------------------------------------------------
if [ -n "$LOGDIR" ]; then
  # A session log is neither a handoff nor a previous mine report.
  mapfile -t sessions < <(find "$LOGDIR" -maxdepth 1 -type f -name '*.md' \
    ! -name 'handoff-*' ! -name 'mine-report-*' 2>/dev/null | sort)

  latest_mine="$(find "$LOGDIR" -maxdepth 1 -type f -name 'mine-report-*.md' \
    -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"

  if [ "${#sessions[@]}" -gt 0 ]; then
    if [ -z "$latest_mine" ]; then
      findings+=("${#sessions[@]} session log(s) and no mine report — never mined. Run \`/mine-sessions save\`.")
    else
      unmined=0
      for s in "${sessions[@]}"; do [ "$s" -nt "$latest_mine" ] && unmined=$((unmined+1)); done
      age_days=$(( ( $(date +%s) - $(stat -c %Y "$latest_mine" 2>/dev/null || echo 0) ) / 86400 ))
      if [ "$unmined" -ge "$STALE_SESSIONS" ]; then
        findings+=("$unmined session(s) since the last mine report — run \`/mine-sessions now\`.")
      elif [ "$age_days" -ge "$STALE_DAYS" ]; then
        findings+=("last mine report is ${age_days}d old — run \`/mine-sessions now\`.")
      fi
    fi
  fi
fi

# --- conflicts awaiting a decision ---------------------------------------
# A blank Decision means work stopped for an answer that never came. That is the sharpest
# signal here: something is not merely stale, it is blocked.
CONFLICT_LOG="$PROJECT/logs/rule-conflict-log.md"
[ -f "$CONFLICT_LOG" ] || CONFLICT_LOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs/rule-conflict-log.md"
if [ -f "$CONFLICT_LOG" ]; then
  pending="$(awk '
    /^```/ { fenced = !fenced; next }
    fenced { next }
    /^\*\*RC[0-9]{3} —/ { id = substr($0, 3, 5) }
    /^\*\*Decision:\*\*/ {
      rest = $0; sub(/^\*\*Decision:\*\*[[:space:]]*/, "", rest)
      if (id != "" && rest == "") print id
      id = ""
    }' "$CONFLICT_LOG" | paste -sd' ' -)"
  [ -n "$pending" ] && findings+=("conflict(s) awaiting a decision: $pending — see \`logs/rule-conflict-log.md\`.")
fi

# --- output --------------------------------------------------------------
if [ "${#findings[@]}" -eq 0 ]; then
  [ "$QUIET" -eq 1 ] || printf 'conformance: nothing overdue\n'
  exit 0
fi

printf 'conformance — %d item(s) overdue:\n' "${#findings[@]}"
for f in "${findings[@]}"; do printf '  · %s\n' "$f"; done
exit 0
