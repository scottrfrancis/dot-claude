#!/usr/bin/env bash
# session-status.sh — what needs attention at the start of a session?
#
# One deterministic probe in place of the copies /lets-go, /pickup, /handoff and
# /session-logger each used to carry. A model re-reading four prose copies of the same check
# costs tokens every run and lets the copies drift; three of them had drifted into the naive
# `git -C ~/.claude fetch`, which fails on every profile-based host.
#
# Prints only what needs attention, and nothing at all when nothing does. Always exits 0.
#
#   session-status.sh [--fetch] [--hook] [--project DIR]
#
#   --fetch    fetch each repo's origin first so ahead/behind are current (network)
#   --hook     SessionStart hook mode: read the hook JSON on stdin, act only on
#              startup|clear, use its cwd, wrap the report as additionalContext.
#              Never fetches.
#   --project  directory to report on (default: $PWD)
#
# Test seams: SESSION_STATUS_DOTC, SESSION_STATUS_WORKSPACE, SESSION_STATUS_PUNCH,
# SESSION_STATUS_CONFORMANCE and SESSION_STATUS_INSTALL override a path ("none" skips that
# probe); SESSION_STATUS_CONFIG_DIR overrides the config dir install.sh --check reports on;
# SESSION_STATUS_TODAY overrides today's date (YYYY-MM-DD).
set -uo pipefail

FETCH=0
HOOK=0
PROJECT="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --fetch)   FETCH=1; shift ;;
    --hook)    HOOK=1; shift ;;
    --project) PROJECT="${2:-$PWD}"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) shift ;;
  esac
done

# Hook mode reports on the session's cwd from the hook JSON and only at a real start. It
# never touches the network: a hung fetch would stall every session start.
if [ "$HOOK" -eq 1 ]; then
  FETCH=0
  command -v jq >/dev/null 2>&1 || exit 0
  INPUT="$(cat 2>/dev/null || true)"
  case "$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null || true)" in
    startup|clear) ;;
    *) exit 0 ;;
  esac
  cwd="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
  [ -n "$cwd" ] && [ -d "$cwd" ] && PROJECT="$cwd"
fi

REPORT=()
emit() { REPORT+=("$1"); }

# The login home, which is not $HOME on profile-based setups: Claude Code sessions there run
# with HOME=<real home>/.claude-profiles/<profile>. git over ssh needs the real one for its
# keys. The /Users check comes first because dscl returns nothing under the macOS sandbox
# (that made a 2026-08-14 session report an installed tool as missing).
real_home() {
  local u h
  u="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
  if [ -n "$u" ] && [ -d "/Users/$u" ]; then printf '%s\n' "/Users/$u"; return; fi
  h="$( { getent passwd "$u" | cut -d: -f6; } 2>/dev/null || true)"
  [ -z "$h" ] && h="$( { dscl . -read "/Users/$u" NFSHomeDirectory | awk '{print $2}'; } 2>/dev/null || true)"
  printf '%s\n' "${h:-$HOME}"
}
REALHOME="$(real_home)"

phys() { (cd -P "$1" 2>/dev/null && pwd -P); }

# The real dot-claude repo. Never just $HOME/.claude: on a profile-based setup that is a
# different directory full of symlinks into the repo, `git -C` there says "not a git
# repository", and on 2026-08-26 that silently skipped the whole check.
find_dotc() {
  if [ -n "${SESSION_STATUS_DOTC:-}" ]; then
    [ "$SESSION_STATUS_DOTC" = none ] || phys "$SESSION_STATUS_DOTC"
    return
  fi
  local c
  for c in /Volumes/workspace/dot-claude "$(readlink -f "$HOME/.claude" 2>/dev/null)" \
           "$REALHOME/.claude" "$HOME/.claude"; do
    [ -n "$c" ] && [ -e "$c/.git" ] && { phys "$c"; return; }
  done
}

join() { local IFS="$1"; shift; printf '%s' "$*"; }

# One line for repo $1, labelled $2, when it needs attention: commits on the local default
# branch that origin lacks (or the reverse), uncommitted files, or a checkout off the default
# branch. The counts compare the LOCAL DEFAULT BRANCH with origin's whatever is checked out,
# because background jobs commit to main without pushing: AILab's KB refresher left its main
# 2 ahead and 4 behind for a day on 2026-11-14, unseen by a check of the current branch.
repo_line() {
  local r="$1" label="$2" def br dirty ahead=0 behind=0 stale="" parts=() ab=()
  dirty="$(git -C "$r" status --porcelain --ignore-submodules=dirty 2>/dev/null | grep -c . || true)"
  dirty="${dirty:-0}"

  if ! git -C "$r" remote get-url origin >/dev/null 2>&1; then
    [ "$dirty" -gt 0 ] && emit "$label: local only, $dirty uncommitted"
    return
  fi

  if [ "$FETCH" -eq 1 ]; then
    # A failed fetch leaves the remote-tracking refs where they were, and rev-list then
    # prints counts that look like success and mean nothing. Say it failed instead.
    if ! HOME="$REALHOME" GIT_TERMINAL_PROMPT=0 git -C "$r" fetch -q origin >/dev/null 2>&1; then
      local m="$label: fetch FAILED, sync state unknown"
      [ "$dirty" -gt 0 ] && m="$m; $dirty uncommitted"
      emit "$m"
      return
    fi
  else
    stale=" (as of last fetch)"
  fi

  def="$(git -C "$r" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  def="${def#origin/}"; def="${def:-main}"
  br="$(git -C "$r" branch --show-current 2>/dev/null || true)"

  if [ -z "$br" ]; then parts+=("detached HEAD")
  elif [ "$br" != "$def" ]; then parts+=("on $br")
  fi

  if git -C "$r" rev-parse -q --verify "refs/heads/$def" >/dev/null 2>&1 \
     && git -C "$r" rev-parse -q --verify "refs/remotes/origin/$def" >/dev/null 2>&1; then
    ahead="$(git -C "$r" rev-list --count "origin/$def..$def" 2>/dev/null || echo 0)"
    behind="$(git -C "$r" rev-list --count "$def..origin/$def" 2>/dev/null || echo 0)"
    [ "$ahead" -gt 0 ] && ab+=("ahead $ahead")
    [ "$behind" -gt 0 ] && ab+=("behind $behind")
    [ "${#ab[@]}" -gt 0 ] && parts+=("$def $(join , "${ab[@]}" | sed 's/,/, /g')")
  fi
  [ "$dirty" -gt 0 ] && parts+=("$dirty uncommitted")

  [ "${#parts[@]}" -gt 0 ] || return
  emit "$label: $(join ';' "${parts[@]}" | sed 's/;/; /g')$stale"
  if [ "$ahead" -gt 0 ]; then
    while IFS= read -r c; do emit "    local-only on $def: $c"; done \
      < <(git -C "$r" log --format='%h %s' "origin/$def..$def" 2>/dev/null | head -3)
  fi
}

# --- repos ------------------------------------------------------------------
DOTC="$(find_dotc)"
TOP="$(git -C "$PROJECT" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$TOP" ] && TOP="$(phys "$TOP")"

[ -n "$DOTC" ] && repo_line "$DOTC" "dot-claude"
# The downstream dot-repos that bin/doctrine.sh writes to, where this host has them.
WS="${SESSION_STATUS_WORKSPACE:-/Volumes/workspace}"
if [ "$WS" != none ]; then
  for d in dot-cursor dot-droid dot-copilot dot-opencode; do
    [ -e "$WS/$d/.git" ] && repo_line "$WS/$d" "$d"
  done
fi
if [ -n "$TOP" ]; then
  name="$(basename "$TOP")"
  [ "$TOP" = "$DOTC" ] || repo_line "$TOP" "$name"
  while IFS= read -r gitdir; do
    sub="$(phys "$(dirname "$gitdir")")"
    # A stray or broken .git is not a repo; git would walk up and report the parent again.
    [ "$(phys "$(git -C "$sub" rev-parse --show-toplevel 2>/dev/null || echo /nonexistent)")" = "$sub" ] || continue
    repo_line "$sub" "$name/$(basename "$sub")"
  done < <(find "$TOP" -mindepth 2 -maxdepth 2 -name .git 2>/dev/null | sort)
fi

# --- handoffs ---------------------------------------------------------------
# Pointed at, never read or moved: /pickup is the only consumer. The SessionStart hook this
# replaces injected the newest handoff and archived it, so any session started in the
# directory (a quick side question) swallowed the handoff meant for the real continuation.
#
# Freshness comes from the date in the FILENAME, never mtime: git stamps every file with the
# checkout time, and on 2026-08-20 that made five six-week-old Contoso handoffs look new.
TODAY="${SESSION_STATUS_TODAY:-$(date +%F)}"
CUTOFF="$(date -d "$TODAY -7 days" +%F 2>/dev/null \
          || date -j -v-7d -f '%Y-%m-%d' "$TODAY" +%F 2>/dev/null || true)"
if [ -n "$CUTOFF" ]; then
  dirs=()
  for base in "$PROJECT" ${TOP:+"$TOP"}; do
    dirs+=("$base/session-logs" "$base/.claude/session-logs" "$base/.factory/logs")
  done
  [ -n "$DOTC" ] && dirs+=("$DOTC/session-logs")
  dirs+=("$HOME/.claude/session-logs")
  # Launched outside any repo (from ~, say), the cwd-relative paths find nothing, and the
  # handoffs live in each project's own session-logs/.
  if [ -z "$TOP" ] && [ "$WS" != none ]; then
    for d in "$WS"/*/session-logs "$WS"/*/*/session-logs; do dirs+=("$d"); done
  fi

  handoffs=()
  while IFS= read -r f; do handoffs+=("$f"); done < <(
    for d in "${dirs[@]}"; do
      [ -d "$d" ] || continue
      for f in "$d"/handoff-????-??-??-*.md; do
        [ -f "$f" ] || continue
        b="${f##*/}"; fd="${b#handoff-}"; fd="${fd:0:10}"
        [ "$fd" \< "$CUTOFF" ] && continue
        printf '%s\t%s/%s\n' "$b" "$(phys "$d")" "$b"
      done
    done | sort -u | sort -r -t "$(printf '\t')" -k1,1 | cut -f2 | head -3)

  if [ "${#handoffs[@]}" -gt 0 ]; then
    emit "handoffs (newest first; /pickup reads one and archives it):"
    for f in "${handoffs[@]}"; do
      shown="$f"
      [ -n "$TOP" ] && case "$f" in "$TOP"/*) shown="${f#"$TOP"/}" ;; esac
      emit "    $shown"
    done
  fi
fi

# --- install state --------------------------------------------------------
# bin/install.sh --check holds the config checks: the skill, rules/ and doctrine links, host.md
# and its imports, and the hooks plugin in settings.json, each with the command that fixes it.
# It runs here for the session's own config dir.
CFG="${SESSION_STATUS_CONFIG_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"
INSTALL="${SESSION_STATUS_INSTALL:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/install.sh}"
if [ "$INSTALL" != none ] && [ -x "$INSTALL" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && emit "$line"
  done < <(INSTALL_HOME="$REALHOME" "$INSTALL" --check "$CFG" 2>/dev/null)
fi

# --- time tracker -----------------------------------------------------------
# Reports, never starts or stops: a timer posts real billable state. Absent means `$P` is
# empty, nothing else. `punch` answers `list-open`; the older `b` capture CLI still on some
# hosts answers only `open` (a 2026-10-15 session on hasami called the tracker absent because
# it knew one verb). A tracker that answers neither is reported as unreadable, never idle:
# under the macOS sandbox punch cannot open its database and exits with a traceback.
find_punch() {
  if [ -n "${SESSION_STATUS_PUNCH:-}" ]; then
    [ "$SESSION_STATUS_PUNCH" = none ] || printf '%s\n' "$SESSION_STATUS_PUNCH"
    return
  fi
  local p c
  p="$(command -v punch 2>/dev/null || command -v b 2>/dev/null || true)"
  if [ -z "$p" ]; then
    for c in "$REALHOME/bin/punch" "$REALHOME/.local/bin/punch" "$REALHOME/bin/b" "$REALHOME/.local/bin/b"; do
      [ -x "$c" ] && { p="$c"; break; }
    done
  fi
  printf '%s\n' "$p"
}
P="$(find_punch)"
if [ -n "$P" ]; then
  if out="$("$P" list-open 2>/dev/null)" || out="$("$P" open 2>/dev/null)"; then
    if [ -z "$out" ] || printf '%s' "$out" | grep -qi '^no open'; then
      [ "$HOOK" -eq 1 ] || emit "timer: none open"
    else
      emit "timer (open):"
      while IFS= read -r l; do emit "    $l"; done < <(printf '%s\n' "$out" | head -3)
    fi
  else
    emit "timer: $P is installed but did not answer list-open or open; run it yourself before assuming no timer"
  fi
fi

# --- conformance ------------------------------------------------------------
SELF_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
CONF="${SESSION_STATUS_CONFORMANCE:-$SELF_DIR/conformance.sh}"
if [ "$CONF" != none ] && [ -x "$CONF" ]; then
  while IFS= read -r l; do [ -n "$l" ] && emit "$l"; done \
    < <("$CONF" --project "${TOP:-$PROJECT}" --quiet 2>/dev/null || true)
fi

# --- action items -----------------------------------------------------------
# The outline-format tracker (Contoso's lint-action-items skill): a closed item whose
# "since" date is more than 7 days old is due for pruning. Reminder only, by preference.
epoch() { date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || true; }
AI_FILE="${TOP:-$PROJECT}/ACTION_ITEMS.md"
if [ -f "$AI_FILE" ] && grep -q '^## Open / Active' "$AI_FILE" 2>/dev/null; then
  now="$(epoch "$TODAY")"; stale_items=0
  while IFS= read -r d; do
    e="$(epoch "$d")"
    [ -n "$e" ] && [ -n "$now" ] && [ $(( (now - e) / 86400 )) -gt 7 ] && stale_items=$((stale_items + 1))
  done < <(grep -A2 -E '^#### AI-[0-9]+ · (done|dropped) ·' "$AI_FILE" 2>/dev/null \
             | grep -oE 'since [0-9]{4}-[0-9]{2}-[0-9]{2}' | awk '{print $2}')
  [ "$stale_items" -gt 0 ] && \
    emit "$stale_items item(s) in ACTION_ITEMS.md past the 7-day prune window; /lint-action-items prunes them"
fi

# --- project probe ----------------------------------------------------------
# Project-specific checks (Contoso's dev-stack health, AILab's KB refresher) live in the
# project, in an executable .claude/session-start.sh, so this script stays generic. The probe
# gets SESSION_STATUS_FETCH=1 on an explicit start (/lets-go, /pickup), where network work such
# as a Drive pull is welcome, and 0 from the hook, which fires on every session start.
PROBE="${TOP:-$PROJECT}/.claude/session-start.sh"
if [ -f "$PROBE" ] && [ -x "$PROBE" ]; then
  secs=15; [ "$FETCH" -eq 1 ] && secs=90
  T=""
  if command -v timeout >/dev/null 2>&1; then T="timeout $secs"
  elif command -v gtimeout >/dev/null 2>&1; then T="gtimeout $secs"
  fi
  while IFS= read -r l; do emit "$l"; done \
    < <(cd "${TOP:-$PROJECT}" && SESSION_STATUS_FETCH="$FETCH" $T "$PROBE" 2>&1 | head -20)
fi

# --- output -----------------------------------------------------------------
[ "${#REPORT[@]}" -gt 0 ] || exit 0
if [ "$HOOK" -eq 1 ]; then
  body="$(printf '%s\n' "${REPORT[@]}")"
  jq -n --arg ctx "Session status (bin/session-status.sh, no fetch):
$body

Mention what matters here to the user once, briefly, after their first request is clear. Do not act on it unprompted. Handoffs are pointers only: /pickup reads one and archives it." \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}' 2>/dev/null || true
  exit 0
fi
printf '%s\n' "${REPORT[@]}"
exit 0
