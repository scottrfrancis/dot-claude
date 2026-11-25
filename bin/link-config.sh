#!/usr/bin/env bash
# link-config.sh — link this repo's skills, bin/, doctrine/, memory/ and host.md into profile
# config dirs.
#
# Claude Code loads skills from the active config dir: ~/.claude, or $CLAUDE_CONFIG_DIR. On a
# host that runs profiles, that is a different directory which symlinks parts of this repo
# (CLAUDE.md, commands, hooks, settings.json...) but not skills/ or bin/. Repo skills never
# load there, and commands calling ~/.claude/bin/... fail. Linking skills/ wholesale would
# hide the profile's own skills (Claude Code writes skills/synced there), so each repo skill
# is linked individually.
#
#   link-config.sh [--apply] [CONFIG_DIR...]
#
# Dry run unless --apply. With no CONFIG_DIR, every profile of this repo is found: a
# <home>/.claude-profiles/*/.claude or <home>/.claude-* dir whose CLAUDE.md links to this
# repo's. Never replaces anything it did not create, and removes only dangling links that
# point into this repo's skills/. Re-run after adding or removing a skill.
#
#   LINK_CONFIG_HOME   the login home to search (default: the real one, not a profile $HOME)
set -uo pipefail

APPLY=0
DIRS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) DIRS+=("$1"); shift ;;
  esac
done

REPO="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# Top-level items a profile needs: bin/ for scripts, doctrine/ and host.md for the host
# import, memory/ for the universal memory import. Each only if the repo has it (host.md is
# gitignored and per host).
TOP_ITEMS=(bin doctrine memory host.md)

phys() { (cd -P "$1" 2>/dev/null && pwd -P); }

if [ "${#DIRS[@]}" -eq 0 ]; then
  H="${LINK_CONFIG_HOME:-}"
  if [ -z "$H" ]; then
    u="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
    if [ -d "/Users/$u" ]; then H="/Users/$u"
    else H="$( { getent passwd "$u" | cut -d: -f6; } 2>/dev/null || true)"; H="${H:-$HOME}"
    fi
  fi
  seen=" "
  for d in "$H"/.claude-profiles/*/.claude "$H"/.claude-*; do
    [ -d "$d" ] && [ -L "$d/CLAUDE.md" ] || continue
    target="$(readlink -f "$d/CLAUDE.md" 2>/dev/null || true)"
    [ -n "$target" ] && [ "$(phys "$(dirname "$target")")" = "$REPO" ] || continue
    p="$(phys "$d")"
    case "$seen" in *" $p "*) continue ;; esac
    seen="$seen$p "
    [ "$p" = "$REPO" ] || DIRS+=("$d")
  done
fi

verb() { [ "$APPLY" -eq 1 ] && printf '%s' "$1" || printf 'would %s' "$1"; }
changes=0

link_item() { # $1 = link path, $2 = target
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then return; fi
  if [ -e "$1" ] || [ -L "$1" ]; then
    printf 'skip %s (exists and is not a link to %s)\n' "$1" "$2"
    return
  fi
  printf '%s %s -> %s\n' "$(verb link)" "$1" "$2"
  changes=$((changes + 1))
  if [ "$APPLY" -eq 1 ]; then mkdir -p "$(dirname "$1")" && ln -s "$2" "$1"; fi
}

for d in "${DIRS[@]}"; do
  for item in "${TOP_ITEMS[@]}"; do
    [ -e "$REPO/$item" ] && link_item "$d/$item" "$REPO/$item"
  done
  for s in "$REPO"/skills/*/; do
    name="$(basename "$s")"
    [ "$name" = synced ] && continue
    [ -f "$s/SKILL.md" ] || continue
    link_item "$d/skills/$name" "$REPO/skills/$name"
  done
  # A skill removed from the repo leaves a dangling link behind. Remove only those.
  for l in "$d"/skills/*; do
    [ -L "$l" ] && [ ! -e "$l" ] || continue
    case "$(readlink "$l")" in
      "$REPO/skills/"*)
        printf '%s %s (its skill is gone)\n' "$(verb unlink)" "$l"
        changes=$((changes + 1))
        [ "$APPLY" -eq 1 ] && rm "$l"
        ;;
    esac
  done
done

if [ "$changes" -gt 0 ] && [ "$APPLY" -eq 0 ]; then
  printf '\n%d change(s) planned for %d config dir(s). Re-run with --apply to make them.\n' "$changes" "${#DIRS[@]}"
fi
exit 0
