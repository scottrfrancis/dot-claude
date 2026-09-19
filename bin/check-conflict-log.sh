#!/usr/bin/env bash
# check-conflict-log.sh — validate the runtime conflict log's structural invariants.
#
# The log is append-only and its RC### ids are stable, so a decision stays citable months
# after it was made. That only holds if ids are unique, gapless, and in order, and if each
# entry carries the fields needed to re-litigate it from the record alone. This checks that;
# it does not judge the content.
#
#   check-conflict-log.sh [LOG]     default: <repo-root>/logs/rule-conflict-log.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${1:-$(cd "$SCRIPT_DIR/.." && pwd)/logs/rule-conflict-log.md}"

[ -f "$LOG" ] || { printf 'check-conflict-log.sh: log not found: %s\n' "$LOG" >&2; exit 2; }

findings=0
note() { printf '%s\n' "$1"; findings=$((findings+1)); }

# Entry headers look like: **RC007 — 2026-08-19 ~14:30 EDT — Scott**
# The log documents its own format in a fenced block containing a literal RC<NNN> header;
# fenced content is illustrative, so it is skipped rather than parsed as a live entry.
mapfile -t headers < <(
  awk '/^```/ { fenced = !fenced; next }
       !fenced && /^\*\*RC[^—]*—/ { print NR ":" $0 }' "$LOG"
)

expected=1
seen=""
for h in "${headers[@]}"; do
  lineno="${h%%:*}"
  text="${h#*:}"
  id="$(printf '%s' "$text" | sed -E 's/^\*\*(RC[A-Za-z0-9]*).*/\1/')"

  if ! printf '%s' "$id" | grep -qE '^RC[0-9]{3}$'; then
    note "line $lineno: malformed id \"$id\" — expected RC### (three digits)"
    continue
  fi

  case " $seen " in *" $id "*) note "line $lineno: id $id is reused — ids are stable and never repeat"; continue ;; esac
  seen="$seen $id"

  n=$((10#${id#RC}))
  if [ "$n" -lt "$expected" ]; then
    note "line $lineno: $id is out of order — entries are appended in occurrence order"
  elif [ "$n" -gt "$expected" ]; then
    missing=""
    i="$expected"
    while [ "$i" -lt "$n" ]; do missing="$missing RC$(printf '%03d' "$i")"; i=$((i+1)); done
    note "line $lineno: gap before $id — missing$missing (ids are never skipped or renumbered)"
  fi
  [ "$n" -ge "$expected" ] && expected=$((n+1))

  # Field presence, scoped to this entry: from its header to the next one or EOF.
  next="$(awk -v s="$lineno" '
    /^```/ { fenced = !fenced; next }
    !fenced && NR>s && /^\*\*RC[^—]*—/ { print NR; exit }' "$LOG")"
  end="${next:-$(wc -l < "$LOG")}"
  body="$(sed -n "${lineno},${end}p" "$LOG")"

  for field in Kind Tool Trigger Operation "Conflicting rules" "Conflict explanation" \
               "Options presented" Decision; do
    printf '%s' "$body" | grep -qF "**$field:**" \
      || note "line $lineno ($id): missing required field \"$field\""
  done
done

if [ "$findings" -eq 0 ]; then
  printf '%s: %d entr%s, structure valid\n' "$LOG" "${#headers[@]}" \
    "$([ "${#headers[@]}" -eq 1 ] && echo y || echo ies)"
else
  printf '\n%d finding(s).\n' "$findings"
  exit 1
fi
