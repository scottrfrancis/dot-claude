#!/usr/bin/env bash
# test-session-status.sh — tests for bin/session-status.sh
#
# The status probe runs unattended at every session start, and a probe that is wrong reads
# exactly like one that is right. So each case builds real git fixtures (a bare origin and a
# clone) and asserts on what a session would be told.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS="$SCRIPT_DIR/../bin/session-status.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain: $3 | got: $2" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1" "expected NOT to contain: $3 | got: $2" ;; *) ok "$1" ;; esac; }
empty() { [ -z "$2" ] && ok "$1" || bad "$1" "expected no output, got: $2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/session-status.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"

echo "test-session-status.sh"
if [ ! -x "$STATUS" ]; then
  echo "  FAIL bin/session-status.sh is missing or not executable"
  echo; echo "0 passed, 1 failed"; exit 1
fi

g() { git -c user.email=t@t -c user.name=t "$@"; }

# A repo with a bare origin, default branch main, origin/HEAD set, in sync.
mkrepo() { # $1 = path
  mkdir -p "$1" && g -C "$1" init -q -b main && g -C "$1" commit -q --allow-empty -m init
  g clone -q --bare "$1" "$1.origin.git"
  g -C "$1" remote add origin "$1.origin.git"
  g -C "$1" fetch -q origin && g -C "$1" branch -q -u origin/main main
  g -C "$1" remote set-head origin main >/dev/null
}
# Push one commit to $1's origin from a second clone, so $1 falls behind.
advance_origin() { # $1 = repo
  local other="$WORK/other.$RANDOM"
  g clone -q "$1.origin.git" "$other" && g -C "$other" commit -q --allow-empty -m "upstream work" \
    && g -C "$other" push -q origin main
}

# Every probe the repo tests do not exercise is switched off, so output is theirs alone.
export SESSION_STATUS_PUNCH=none SESSION_STATUS_CONFORMANCE=none SESSION_STATUS_SETTINGS=none
export SESSION_STATUS_CONFIG_DIR="$WORK/no-config"
export SESSION_STATUS_HOSTMD=none
export SESSION_STATUS_WORKSPACE="$WORK/no-workspace"
status() { "$STATUS" "$@" 2>/dev/null; }

# --- repo drift -------------------------------------------------------------

DOTC="$WORK/dot-claude"; mkrepo "$DOTC"
PROJ="$WORK/proj"; mkrepo "$PROJ"
export SESSION_STATUS_DOTC="$DOTC"

out="$(cd "$PROJ" && status --fetch)"; rc=$?
empty "everything in sync and clean: prints nothing" "$out"
[ "$rc" -eq 0 ] && ok "exits 0" || bad "exits 0" "rc=$rc"

advance_origin "$DOTC"
out="$(cd "$PROJ" && status --fetch)"
has "dot-claude behind origin is reported after a fetch" "$out" "dot-claude: main behind 1"
lacks "a fetched report does not hedge about freshness" "$out" "as of last fetch"

touch "$PROJ/scratch.txt"
out="$(cd "$PROJ" && status)"
has "uncommitted files in the project are counted" "$out" "proj: 1 uncommitted"
has "without --fetch the counts say they may be stale" "$out" "(as of last fetch)"
rm -f "$PROJ/scratch.txt"

g -C "$PROJ" switch -q -c feat/x
g -C "$PROJ" switch -q main && g -C "$PROJ" commit -q --allow-empty -m "chore(kb): bump pointer" \
  && g -C "$PROJ" switch -q feat/x
out="$(cd "$PROJ" && status --fetch)"
has "a repo off its default branch names the branch" "$out" "on feat/x"
has "local-only commits on the default branch are counted while on another branch" "$out" "main ahead 1"
has "local-only commits are listed by subject" "$out" "chore(kb): bump pointer"
g -C "$PROJ" switch -q main && g -C "$PROJ" push -q origin main

mkdir -p "$PROJ/sub" && g -C "$PROJ/sub" init -q -b main && g -C "$PROJ/sub" commit -q --allow-empty -m x
touch "$PROJ/sub/dirty.txt"
mkdir -p "$PROJ/clean" && g -C "$PROJ/clean" init -q -b main && g -C "$PROJ/clean" commit -q --allow-empty -m x
out="$(cd "$PROJ" && status --fetch)"
has "a dirty nested repo without origin is reported as local only" "$out" "proj/sub: local only, 1 uncommitted"
lacks "a clean nested repo without origin is not reported" "$out" "proj/clean"
rm -rf "$PROJ/sub" "$PROJ/clean"

# A stray or broken .git one level down is not a repo: git walks up to the parent, which
# would then be reported twice under two names (seen in AILab, 2026-11-25).
mkdir -p "$PROJ/stray/.git"; touch "$PROJ/x.txt"
out="$(cd "$PROJ" && status)"
lacks "a broken nested .git does not repeat the parent under another name" "$out" "proj/stray"
rm -rf "$PROJ/stray" "$PROJ/x.txt"

g -C "$DOTC" remote set-url origin "$WORK/does-not-exist.git"
out="$(cd "$PROJ" && status --fetch)"
has "a failed fetch is reported as such" "$out" "dot-claude: fetch FAILED, sync state unknown"
lacks "a failed fetch reports no counts" "$out" "dot-claude: main"
g -C "$DOTC" remote set-url origin "$DOTC.origin.git"

g -C "$DOTC" pull -q --ff-only
touch "$DOTC/x.txt"
out="$(cd "$DOTC" && status --fetch)"
n="$(printf '%s\n' "$out" | grep -c 'uncommitted' || true)"
[ "$n" = 1 ] && ok "when the project is dot-claude it is reported once" \
            || bad "when the project is dot-claude it is reported once" "$out"
rm -f "$DOTC/x.txt"

out="$(cd "$WORK" && SESSION_STATUS_DOTC=none status --fetch)"
empty "outside any repo, with dot-claude skipped, prints nothing" "$out"

# The downstream dot-repos in the workspace are checked too; absent ones are skipped.
DWS="$WORK/dws"; mkdir -p "$DWS"; mkrepo "$DWS/dot-cursor"; mkrepo "$DWS/dot-droid"
touch "$DWS/dot-cursor/x.txt"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_WORKSPACE="$DWS" status --fetch)"
has "a dirty downstream dot-repo is reported" "$out" "dot-cursor: 1 uncommitted"
lacks "a clean downstream dot-repo is not" "$out" "dot-droid"
lacks "an absent downstream dot-repo is skipped silently" "$out" "dot-opencode"
rm -rf "$DWS"

# --- handoffs ---------------------------------------------------------------
# Pointed at, never consumed: /pickup is the only reader. Freshness comes from the date in
# the filename, never mtime, because a checkout stamps every file with the same mtime.

export SESSION_STATUS_TODAY=2026-11-25
mkdir -p "$PROJ/session-logs"
printf '# h\n' > "$PROJ/session-logs/handoff-2026-11-24-0900.md"
printf '# old\n' > "$PROJ/session-logs/handoff-2026-11-01-0900.md"   # fresh mtime, old name
out="$(cd "$PROJ" && status)"
has "a fresh handoff is pointed at" "$out" "session-logs/handoff-2026-11-24-0900.md"
lacks "a handoff older than 7 days by its filename is not listed, whatever its mtime" "$out" "handoff-2026-11-01"
[ -f "$PROJ/session-logs/handoff-2026-11-24-0900.md" ] && ok "the handoff is left in place" \
  || bad "the handoff is left in place" "it was moved"

for d in 20 21 22 23; do printf '# h\n' > "$PROJ/session-logs/handoff-2026-11-$d-0900.md"; done
out="$(cd "$PROJ" && status)"
n="$(printf '%s\n' "$out" | grep -c 'handoff-' || true)"
[ "$n" = 3 ] && ok "at most three handoffs are listed" || bad "at most three handoffs are listed" "$out"
lacks "the three listed are the newest" "$out" "handoff-2026-11-21"
rm -rf "$PROJ/session-logs"

mkdir -p "$DOTC/session-logs" && printf '# g\n' > "$DOTC/session-logs/handoff-2026-11-25-0800.md"
out="$(cd "$PROJ" && status)"
has "a handoff in dot-claude's own session-logs is listed" "$out" "dot-claude/session-logs/handoff-2026-11-25-0800.md"
rm -rf "$DOTC/session-logs"

WS="$WORK/ws"; mkdir -p "$WS/alpha/session-logs" "$WS/beta/bot/session-logs"
printf '# a\n' > "$WS/alpha/session-logs/handoff-2026-11-23-1000.md"
printf '# b\n' > "$WS/beta/bot/session-logs/handoff-2026-11-22-1000.md"
out="$(cd "$WORK" && SESSION_STATUS_WORKSPACE="$WS" status)"
has "outside a repo, project handoffs across the workspace are listed" "$out" "alpha/session-logs/handoff-2026-11-23-1000.md"
has "the workspace scan reaches nested projects" "$out" "beta/bot/session-logs/handoff-2026-11-22-1000.md"
out="$(cd "$PROJ" && SESSION_STATUS_WORKSPACE="$WS" status)"
lacks "inside a repo, other projects' handoffs are not listed" "$out" "alpha/"

# --- time tracker -----------------------------------------------------------
# Stubs answer like punch (`list-open`) or the older `b` capture CLI (`open` only).
stub() { # $1 = name, $2 = body of a case on "$1"
  printf '#!/usr/bin/env bash\ncase "$1" in\n%s\nesac\n' "$2" > "$WORK/$1"; chmod +x "$WORK/$1"
}
stub punch-open  '  list-open) echo "TR-12 acme/site started 09:10 (elapsed 42m)" ;; *) exit 2 ;;'
stub punch-idle  '  list-open) echo "No open sessions." ;; *) exit 2 ;;'
stub b-old       '  open) echo "TR-7 acme/old running" ;; *) echo "invalid choice" >&2; exit 2 ;;'
stub punch-broke '  *) echo "Traceback: readonly database" >&2; exit 1 ;;'

out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_PUNCH="$WORK/punch-open" status)"
has "an open timer is reported with what punch printed" "$out" "TR-12 acme/site"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_PUNCH="$WORK/punch-idle" status)"
has "an idle tracker says so, so /lets-go can nudge" "$out" "timer: none open"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_PUNCH="$WORK/b-old" status)"
has "the older b CLI's open verb is used when list-open is rejected" "$out" "TR-7 acme/old"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_PUNCH="$WORK/punch-broke" status)"
has "a tracker that fails both verbs is reported as unreadable" "$out" "did not answer"
lacks "a tracker that fails is never reported as idle" "$out" "none open"
lacks "a tracker's traceback does not reach the report" "$out" "Traceback"

# --- conformance, action items, project probe -------------------------------
printf '#!/usr/bin/env bash\necho "conformance — 1 item(s) overdue:"\necho "  · never mined"\n' > "$WORK/conf"
chmod +x "$WORK/conf"
out="$(cd "$PROJ" && SESSION_STATUS_CONFORMANCE="$WORK/conf" status)"
has "conformance findings are included" "$out" "conformance — 1 item(s) overdue"

cat > "$PROJ/ACTION_ITEMS.md" <<'EOF'
## Open / Active

#### AI-001 · done · shipped the thing
since 2026-11-01

#### AI-002 · done · shipped yesterday
since 2026-11-24
EOF
out="$(cd "$PROJ" && status)"
has "action items past the 7-day prune window are counted" "$out" "1 item(s) in ACTION_ITEMS.md past the 7-day prune window"
rm -f "$PROJ/ACTION_ITEMS.md"

mkdir -p "$PROJ/.claude"
printf '#!/usr/bin/env bash\nfor i in $(seq 1 25); do echo "probe line $i"; done\n' > "$PROJ/.claude/session-start.sh"
out="$(cd "$PROJ" && status)"
lacks "a project probe that is not executable is not run" "$out" "probe line"
chmod +x "$PROJ/.claude/session-start.sh"
out="$(cd "$PROJ" && status)"
has "an executable project probe is run" "$out" "probe line 20"
lacks "project probe output is capped at 20 lines" "$out" "probe line 21"
printf '#!/usr/bin/env bash\necho "probe fetch=${SESSION_STATUS_FETCH:-unset}"\n' > "$PROJ/.claude/session-start.sh"
out="$(cd "$PROJ" && status --fetch)"
has "a project probe is told when network work is welcome" "$out" "probe fetch=1"
out="$(cd "$PROJ" && status)"
has "a project probe is told when it is not" "$out" "probe fetch=0"
rm -rf "$PROJ/.claude"

# --- hook registration ------------------------------------------------------
# settings.json is gitignored and per host, so a fresh clone or a new host registers nothing.
SET="$WORK/settings.json"
printf '{"hooks":{"SessionStart":[{"hooks":[{"command":"~/.claude/hooks/session-status.sh"}]}],"PreToolUse":[{"hooks":[{"command":"~/.claude/hooks/pre-tool-safety.sh"}]}],"Stop":[{"hooks":[{"command":"~/.claude/hooks/session-end-reminder.sh"}]}],"PostToolUse":[{"hooks":[{"command":"python3 ~/.claude/hooks/prose-check.py"}]}],"X":[{"hooks":[{"command":"python3 ~/.claude/hooks/skill-gate.py"}]}]}}' > "$SET"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_SETTINGS="$SET" status)"
empty "hooks: a settings.json registering all three hooks is not mentioned" "$out"

sed 's/pre-tool-safety/something-else/' "$SET" > "$SET.2"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_SETTINGS="$SET.2" status)"
has "hooks: a missing registration is named" "$out" "pre-tool-safety.sh"
sed 's/skill-gate/other-gate/' "$SET" > "$SET.4"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_SETTINGS="$SET.4" status)"
has "hooks: the skill gate counts as a core hook" "$out" "skill-gate.py"

sed 's/session-status\.sh/load-handoff-context.sh/' "$SET" > "$SET.3"
out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_SETTINGS="$SET.3" status)"
has "hooks: the old SessionStart name is flagged for re-registration" "$out" "load-handoff-context.sh"

out="$(cd "$WORK" && SESSION_STATUS_DOTC=none SESSION_STATUS_SETTINGS="$WORK/absent.json" status)"
has "hooks: a host with no settings.json is told it registers nothing" "$out" "no hooks are registered"
export SESSION_STATUS_SETTINGS=none

# --- host.md ----------------------------------------------------------------
# CLAUDE.md imports ~/.claude/host.md, which on a homelab host imports doctrine/homelab.md.
# A missing file is skipped silently by Claude Code, so the probe says so instead.
out="$(cd "$WORK" && SESSION_STATUS_HOSTMD="$WORK/absent-host.md" status)"
has "host.md: a host without one is told it loads no host doctrine" "$out" "host.md"
printf '# host\n@%s/doctrine/homelab.md\n' "$WORK/hd" > "$WORK/host.md"
out="$(cd "$WORK" && SESSION_STATUS_HOSTMD="$WORK/host.md" status)"
has "host.md: an import that does not resolve is named" "$out" "$WORK/hd/doctrine/homelab.md"
mkdir -p "$WORK/hd/doctrine" && touch "$WORK/hd/doctrine/homelab.md"
out="$(cd "$WORK" && SESSION_STATUS_HOSTMD="$WORK/host.md" status)"
lacks "host.md: a host.md whose imports resolve is not mentioned" "$out" "host.md"
printf '@~/.claude/doctrine/homelab.md\n' > "$WORK/host2.md"; mkdir -p "$WORK/h2/.claude/doctrine"; touch "$WORK/h2/.claude/doctrine/homelab.md"
out="$(cd "$WORK" && HOME="$WORK/h2" SESSION_STATUS_HOSTMD="$WORK/host2.md" status)"
lacks "host.md: ~ in an import means \$HOME" "$out" "host.md"
rm -rf "$WORK/hd" "$WORK/h2" "$WORK/host.md" "$WORK/host2.md"

# --- skill links ------------------------------------------------------------
# A profile config dir that lacks links to dot-claude's skills never loads them.
mkdir -p "$DOTC/skills/alpha" "$DOTC/skills/beta" "$DOTC/skills/synced"
touch "$DOTC/skills/alpha/SKILL.md" "$DOTC/skills/beta/SKILL.md"
CFG="$WORK/cfg"; mkdir -p "$CFG/skills"
out="$(cd "$WORK" && SESSION_STATUS_CONFIG_DIR="$CFG" status)"
has "skills: a profile missing dot-claude's skills is told how many and what to run" "$out" "2 of 2 dot-claude skills are not linked"
has "skills: and what to run" "$out" "link-config.sh --apply"
ln -s "$DOTC/skills/alpha" "$CFG/skills/alpha"; ln -s "$DOTC/skills/beta" "$CFG/skills/beta"
out="$(cd "$WORK" && SESSION_STATUS_CONFIG_DIR="$CFG" status)"
lacks "skills: a fully linked profile is not mentioned" "$out" "skills:"
out="$(cd "$WORK" && SESSION_STATUS_CONFIG_DIR="$DOTC" status)"
lacks "skills: dot-claude itself as the config dir needs no links" "$out" "skills:"
rm -rf "$DOTC/skills" "$CFG"

# --- hook mode --------------------------------------------------------------
hookjson() { printf '{"session_id":"s1","hook_event_name":"SessionStart","source":"%s","cwd":"%s"}' "$1" "$2"; }
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null; }
evt() { jq -r '.hookSpecificOutput.hookEventName // empty' 2>/dev/null; }

if ! command -v jq >/dev/null 2>&1; then
  bad "jq is available for the hook-mode tests" "install jq"
else
  touch "$PROJ/scratch.txt"
  out="$(cd "$WORK" && hookjson resume "$PROJ" | status --hook)"
  empty "hook: a resumed session gets nothing" "$out"

  out="$(cd "$WORK" && hookjson startup "$PROJ" | status --hook)"
  [ "$(printf '%s' "$out" | evt)" = SessionStart ] && ok "hook: startup emits SessionStart JSON" \
    || bad "hook: startup emits SessionStart JSON" "$out"
  has "hook: the report is about the hook's cwd, not the shell's" "$(printf '%s' "$out" | ctx)" "proj: 1 uncommitted"

  out="$(cd "$WORK" && hookjson clear "$PROJ" | status --hook)"
  has "hook: /clear also gets the report" "$(printf '%s' "$out" | ctx)" "proj: 1 uncommitted"

  advance_origin "$PROJ"
  out="$(cd "$WORK" && hookjson startup "$PROJ" | status --hook --fetch)"
  lacks "hook: never fetches, even when asked" "$(printf '%s' "$out" | ctx)" "behind"
  rm -f "$PROJ/scratch.txt"; g -C "$PROJ" pull -q --ff-only

  out="$(cd "$WORK" && hookjson startup "$PROJ" | SESSION_STATUS_PUNCH="$WORK/punch-idle" status --hook)"
  empty "hook: a clean project and an idle timer produce no output at all" "$out"

  out="$(cd "$WORK" && printf 'not json' | status --hook)"; rc=$?
  empty "hook: garbage input produces nothing" "$out"
  [ "$rc" -eq 0 ] && ok "hook: garbage input still exits 0" || bad "hook: garbage input still exits 0" "rc=$rc"

  # Profile-based hosts reach hooks/ through a symlinked directory and have no bin/ beside it.
  PROFILE="$WORK/profile/.claude"; mkdir -p "$PROFILE"
  ln -s "$(cd -P "$SCRIPT_DIR/../hooks" && pwd -P)" "$PROFILE/hooks"
  mkdir -p "$PROJ/session-logs" && printf '# h\n' > "$PROJ/session-logs/handoff-2026-11-25-0700.md"
  out="$(cd "$WORK" && hookjson startup "$PROJ" | "$PROFILE/hooks/session-status.sh" 2>/dev/null)"
  has "hook entry point works through a symlinked hooks dir" "$(printf '%s' "$out" | ctx)" "handoff-2026-11-25-0700.md"

  out="$(cd "$WORK" && hookjson startup "$PROJ" | "$PROFILE/hooks/load-handoff-context.sh" 2>/dev/null)"
  has "the old load-handoff-context.sh registration now points instead of injecting" \
    "$(printf '%s' "$out" | ctx)" "handoff-2026-11-25-0700.md"
  lacks "the old registration no longer pastes the handoff's content" "$(printf '%s' "$out" | ctx)" "Previous session handoff"
  [ -f "$PROJ/session-logs/handoff-2026-11-25-0700.md" ] && ok "the old registration no longer archives the handoff" \
    || bad "the old registration no longer archives the handoff" "it was moved"
  rm -rf "$PROJ/session-logs"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
