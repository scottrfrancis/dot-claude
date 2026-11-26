#!/usr/bin/env bash
# doctrine.sh — propagate marker-delimited doctrine blocks from dot-claude to the
# downstream dot-* repos, or verify that they are already in sync.
#
# dot-claude is primary. Every block lives, authoritatively, between
#   <!-- <block>: begin -->  and  <!-- <block>: end -->
# in exactly one primary file: CLAUDE.md for universal doctrine, which loads on every host, or
# doctrine/homelab.md for homelab doctrine, which homelab hosts import through host.md. Downstream
# copies are replaced from it; they are never a source. A block in two primaries is an error.
#
#   doctrine.sh check   report every target that differs, is missing the block, or
#                       carries malformed markers; exit 1 if any finding
#   doctrine.sh sync    rewrite each target's block from its primary
#
#   --primary FILE      repeatable; default: <repo-root>/CLAUDE.md and doctrine/homelab.md
#   --targets FILE      default: <repo-root>/doctrine/targets.conf
#
# Target paths resolve relative to the current directory, which is expected to be the
# workspace holding the sibling dot-* checkouts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PRIMARIES=()
TARGETS="$REPO_ROOT/doctrine/targets.conf"
MODE=""

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --primary) PRIMARIES+=("$2"); shift 2 ;;
    --targets) TARGETS="$2"; shift 2 ;;
    check|sync) MODE="$1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'doctrine.sh: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[ "${#PRIMARIES[@]}" -gt 0 ] || PRIMARIES=("$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/doctrine/homelab.md")

[ -n "$MODE" ]     || { printf 'doctrine.sh: expected "check" or "sync"\n' >&2; exit 2; }
for p in "${PRIMARIES[@]}"; do
  [ -f "$p" ] || { printf 'doctrine.sh: primary not found: %s\n' "$p" >&2; exit 2; }
done
[ -f "$TARGETS" ]  || { printf 'doctrine.sh: targets file not found: %s\n' "$TARGETS" >&2; exit 2; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctrine.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Print the body of BLOCK in FILE — the lines strictly between its markers.
# A marker is recognized with or without a stray backslash, so that a file written with
# the malformed `<\!--` form is still parsed rather than silently reported as missing.
extract() {
  awk -v block="$2" '
    function canon(l) { gsub(/\\/, "", l); return l }
    canon($0) == "<!-- " block ": begin -->" { inside = 1; next }
    canon($0) == "<!-- " block ": end -->"   { inside = 0; next }
    inside { print }
  ' "$1"
}

# Exit 0 if FILE carries both markers for BLOCK, in order.
has_block() {
  awk -v block="$2" '
    function canon(l) { gsub(/\\/, "", l); return l }
    canon($0) == "<!-- " block ": begin -->" { begun = 1 }
    canon($0) == "<!-- " block ": end -->" && begun { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1"
}

# Exit 0 if FILE's markers for BLOCK use the malformed `<\!--` form. Such a line is not
# an HTML comment: it renders as visible text and hides from tooling matching the real form.
has_escaped_markers() {
  grep -qE '^<\\+!-- '"$2"': (begin|end) -->$' "$1"
}

# Replace BLOCK's body in FILE with BODY_FILE's contents, restoring canonical markers.
replace() {
  local file="$1" block="$2" body="$3" out="$TMP/out.$$"
  awk -v block="$block" -v bodyfile="$body" '
    function canon(l) { gsub(/\\/, "", l); return l }
    canon($0) == "<!-- " block ": begin -->" {
      print "<!-- " block ": begin -->"
      while ((getline line < bodyfile) > 0) print line
      close(bodyfile)
      inside = 1; next
    }
    canon($0) == "<!-- " block ": end -->" {
      print "<!-- " block ": end -->"; inside = 0; next
    }
    !inside { print }
  ' "$file" > "$out"
  # Preserve mtime when nothing changed, so sync is a genuine no-op on in-sync targets.
  if cmp -s "$file" "$out"; then rm -f "$out"; else mv "$out" "$file"; fi
}

# Print the one primary that carries BLOCK. None, or more than one, is a setup error.
primary_for() {
  local p found=()
  for p in "${PRIMARIES[@]}"; do has_block "$p" "$1" && found+=("$p"); done
  case "${#found[@]}" in
    1) printf '%s\n' "${found[0]}" ;;
    0) printf 'block "%s" not found in any primary: %s\n' "$1" "${PRIMARIES[*]}" >&2; return 2 ;;
    *) printf 'block "%s" found in more than one primary: %s\n' "$1" "${found[*]}" >&2; return 2 ;;
  esac
}

findings=0
synced=0

while IFS= read -r line; do
  line="${line%%#*}"                                   # strip comments
  line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$line" ] || continue

  block="$(printf '%s' "$line" | cut -d'|' -f1 | sed 's/[[:space:]]*$//')"
  path="$(printf '%s'  "$line" | cut -d'|' -f2- | sed 's/^[[:space:]]*//')"

  if [ ! -f "$path" ]; then
    printf '%s: file not found\n' "$path"; findings=$((findings+1)); continue
  fi
  if ! primary="$(primary_for "$block")"; then exit 2; fi

  extract "$primary" "$block" > "$TMP/primary.body"

  if ! has_block "$path" "$block"; then
    if [ "$MODE" = check ]; then
      printf '%s: missing block "%s"\n' "$path" "$block"; findings=$((findings+1))
    else
      printf '%s: missing block "%s" — cannot sync, add the markers first\n' "$path" "$block" >&2
      findings=$((findings+1))
    fi
    continue
  fi

  extract "$path" "$block" > "$TMP/target.body"
  escaped=0; has_escaped_markers "$path" "$block" && escaped=1

  if [ "$MODE" = check ]; then
    if [ "$escaped" = 1 ]; then
      printf '%s: malformed markers for "%s" (`<\\!--` is not an HTML comment)\n' "$path" "$block"
      findings=$((findings+1))
    elif ! cmp -s "$TMP/primary.body" "$TMP/target.body"; then
      printf '%s: block "%s" differs from primary\n' "$path" "$block"
      findings=$((findings+1))
    fi
  else
    if [ "$escaped" = 1 ] || ! cmp -s "$TMP/primary.body" "$TMP/target.body"; then
      replace "$path" "$block" "$TMP/primary.body"
      printf '%s: synced "%s"\n' "$path" "$block"
      synced=$((synced+1))
    fi
  fi
done < "$TARGETS"

if [ "$MODE" = check ]; then
  [ "$findings" -eq 0 ] || { printf '\n%d finding(s).\n' "$findings"; exit 1; }
  printf 'All doctrine blocks in sync with %s\n' "${PRIMARIES[*]}"
else
  [ "$findings" -eq 0 ] || exit 1
  printf '%d block(s) synced.\n' "$synced"
fi
