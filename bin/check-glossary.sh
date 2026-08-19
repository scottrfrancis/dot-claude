#!/usr/bin/env bash
# check-glossary.sh — structural checks on a glossary table.
#
# The glossary stays small on purpose: a row is earned by a term that actually caused a
# misunderstanding, not authored up front. So this checks only what makes a row usable —
# a term defined once, a definition that bottoms out rather than looping, and a definition
# that is not a restatement of the term.
#
# The closure check from the source protocol is deliberately not implemented: requiring
# every term inside a definition to be itself defined cascades into defining ordinary
# English, and at this size that costs more than it catches.
#
#   check-glossary.sh [FILE...]     default: every GLOSSARY.md the current scope resolves
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -gt 0 ]; then
  FILES=("$@")
else
  mapfile -t FILES < <("$SCRIPT_DIR/memory-scope.sh" --kind glossary 2>/dev/null || true)
fi
[ "${#FILES[@]}" -gt 0 ] || { printf 'glossary: no glossary in scope\n'; exit 0; }

findings=0
note() { printf '%s\n' "$1"; findings=$((findings+1)); }

# Strip backticks and surrounding space so `skill` and skill are one term.
norm() { printf '%s' "$1" | tr -d '`' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

# Does TEXT ($2) mention TERM ($1) as a word in its own right? Compared token by token:
# `SKILL.md` and `/mine-sessions` name artifacts and are not the terms `skill` or `mine`
# restating themselves, whereas a bare "deliverable" is.
mentions() {
  local term text
  term="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  text="$(printf '%s' "$2" | tr -d '`' | tr '[:upper:]' '[:lower:]' \
          | tr -c 'a-z0-9_./-' ' ')"
  for tok in $text; do
    tok="${tok%%[.,;:!?]}"
    tok="${tok%/}"
    [ "$tok" = "$term" ] && return 0
  done
  return 1
}

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue

  terms=(); meanings=(); lines=()
  while IFS= read -r row; do
    case "$row" in
      '|'*'|'*) : ;;
      *) continue ;;
    esac
    # Skip the header and its separator.
    case "$row" in *'---'*) continue ;; esac
    t="$(norm "$(printf '%s' "$row" | awk -F'|' '{print $2}')")"
    m="$(norm "$(printf '%s' "$row" | awk -F'|' '{print $3}')")"
    [ -n "$t" ] || continue
    [ "$t" = "Term" ] && continue
    terms+=("$t"); meanings+=("$m")
    lines+=("$(grep -nF -- "$row" "$f" | head -1 | cut -d: -f1)")
  done < "$f"

  n="${#terms[@]}"
  [ "$n" -gt 0 ] || continue

  for i in $(seq 0 $((n-1))); do
    t="${terms[$i]}"; m="${meanings[$i]}"; ln="${lines[$i]}"

    if [ -z "$m" ]; then
      note "$f line $ln: \"$t\" has no meaning — a term with no definition is not an entry"
      continue
    fi

    # Defined twice: two answers to one question.
    for j in $(seq 0 $((n-1))); do
      if [ "$j" -lt "$i" ] && [ "${terms[$j]}" = "$t" ]; then
        note "$f line $ln: \"$t\" is defined more than once"
        break
      fi
    done

    # Self-reference: the definition explains the term with the term.
    if mentions "$t" "$m"; then
      note "$f line $ln: \"$t\" is defined using itself — restate it in concrete terms"
      continue
    fi

    # Cycle: follow references between entries and see whether the chain returns here.
    seen=" $t "
    frontier="$m"
    depth=0
    while [ "$depth" -lt 8 ]; do
      next=""
      for j in $(seq 0 $((n-1))); do
        o="${terms[$j]}"
        case "$seen" in *" $o "*) continue ;; esac
        if mentions "$o" "$frontier"; then
          if mentions "$t" "${meanings[$j]}"; then
            note "$f line $ln: \"$t\" and \"$o\" define each other — the chain cycles and never reaches plain language"
            next=""; break
          fi
          seen="$seen$o "; next="$next ${meanings[$j]}"
        fi
      done
      [ -n "$next" ] || break
      frontier="$next"; depth=$((depth+1))
    done
  done
done

if [ "$findings" -eq 0 ]; then
  printf 'glossary: %d file(s) valid\n' "${#FILES[@]}"
else
  printf '\n%d finding(s). See guidelines/glossary.md.\n' "$findings"
  exit 1
fi
