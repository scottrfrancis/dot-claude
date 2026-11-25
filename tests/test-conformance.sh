#!/usr/bin/env bash
# test-conformance.sh — tests for bin/conformance.sh
#
# The probe answers "is anything overdue?" deterministically and cheaply, so that deciding
# whether to run /mine-sessions never costs an LLM pass. It reports; it does not gate.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBE="$SCRIPT_DIR/../bin/conformance.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
check_rc()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected exit $3, got $2"; }
has()    { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to mention '$3' in: $2" ;; esac; }
hasnt()  { case "$2" in *"$3"*) bad "$1" "should not mention '$3': $2" ;; *) ok "$1" ;; esac; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-conformance.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT

reset() { rm -rf "$WORK"/p; mkdir -p "$WORK"/p/session-logs "$WORK"/p/logs "$WORK"/p/memory; log_header > "$WORK"/p/logs/rule-conflict-log.md; }
log_header() { printf '# Runtime Conflict Log\n\n---\n\n(New entries appended below this separator.)\n'; }

session() { printf -- '---\ntool: claude-code\n---\n# Session Log: %s\n' "$1" > "$WORK/p/session-logs/session-$1.md"; }
mined()   { printf '# Mine report\n' > "$WORK/p/session-logs/mine-report-$1.md"; }
conflict() { # $1 id, $2 decision (blank = pending)
  printf '\n**%s — 2026-08-19 ~10:00 EDT — Scott**\n\n**Kind:** rule\n\n**Decision:** %s\n' "$1" "$2" \
    >> "$WORK/p/logs/rule-conflict-log.md"; }

run() { "$PROBE" --project "$WORK/p" --home "$WORK/p" 2>&1; }
rc()  { "$PROBE" --project "$WORK/p" --home "$WORK/p" >/dev/null 2>&1; echo $?; }

echo "test-conformance.sh"
if [ ! -x "$PROBE" ]; then
  echo "  FAIL bin/conformance.sh is missing or not executable — assertions would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# --- it reports, it never gates ------------------------------------------
reset; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do session "$i"; done; conflict RC001 ''
check_rc "always exits 0 — advisory, never a gate" "$(rc)" 0

# --- mining staleness ----------------------------------------------------
reset
hasnt "quiet when there is nothing to mine" "$(run)" "mine-sessions"

reset; for i in 1 2 3; do session "$i"; done
has "flags sessions that have never been mined" "$(run)" "never"

reset; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do session "$i"; done; sleep 0.01; mined 2026-08-19
hasnt "quiet right after a mine report" "$(run)" "/mine-sessions now"

reset; mined 2026-07-01; sleep 0.01; for i in $(seq 1 12); do session "$i"; done
out="$(run)"
has "flags when many sessions have accrued since the last mine" "$out" "12"
has "names the command to run" "$out" "/mine-sessions"

# handoff and mine-report files are not sessions
reset; mined 2026-07-01; sleep 0.01
printf 'x\n' > "$WORK/p/session-logs/handoff-2026-08-19.md"; mined 2026-08-19
hasnt "handoff and mine-report files are not counted as sessions" "$(run)" "1 session"

# --- unresolved conflicts ------------------------------------------------
reset; conflict RC001 '2026-08-19 — chose (a).'
hasnt "quiet when every conflict is decided" "$(run)" "awaiting"

reset; conflict RC001 '2026-08-19 — chose (a).'; conflict RC002 ''
out="$(run)"
has "flags a conflict still awaiting a decision" "$out" "awaiting"
has "names the pending id" "$out" "RC002"
hasnt "does not name a decided conflict" "$out" "RC001 "

# --- memory decay ---------------------------------------------------------
# Memory that only accretes becomes memory that lies. A fact is flagged when it has gone
# unverified too long, or when it carries no verification date at all.
mem() { printf '# Memory\n\n%s\n' "$1" > "$WORK/p/memory/MEMORY.md"; }
today="$(date +%Y-%m-%d)"
old="$(date -d '400 days ago' +%Y-%m-%d 2>/dev/null || date -v-400d +%Y-%m-%d)"

reset
hasnt "quiet when there is no memory file" "$(run)" "memory"

reset; mem "- A fresh fact [$today]"
hasnt "quiet when every fact is fresh" "$(run)" "memory fact"

reset; mem "- A stale fact [$old]"
out="$(run)"
has "flags a fact past the staleness window" "$out" "memory fact"
has "names the guideline to act on" "$out" "MEMORY.md"

reset; mem "- An undated fact with no date at all"
has "flags an undated fact — unverifiable is not fresh" "$(run)" "undated"

reset; mem "- A fresh fact [$today]
- A stale fact [$old]
- Another stale one [$old]"
case "$(run)" in *"2 memory fact"*) ok "counts only the stale facts" ;;
  *) bad "counts only the stale facts" "$(run)" ;; esac

# Retired facts are struck through on purpose and must not be re-flagged forever.
reset; mem "## Retired

- ~~A retired fact~~ — no longer true [retired $old]"
hasnt "does not flag facts under Retired" "$(run)" "memory fact"

# --- portability: BSD find and stat (macOS) ------------------------------
# macOS find has no -printf and macOS stat has no -c. Until 2026-11-15 the probe used both, so
# on a Mac it exited 1 with no output whenever a mine report existed. These shims refuse the
# GNU-only flags on any platform, so CI on Linux catches a regression too.
BSDBIN="$WORK/bsdbin"; mkdir -p "$BSDBIN"
REALFIND="$(command -v find)"; REALSTAT="$(command -v stat)"
cat > "$BSDBIN/find" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do [ "\$a" = "-printf" ] && { echo "find: -printf: unknown primary or operator" >&2; exit 1; }; done
exec "$REALFIND" "\$@"
EOF
cat > "$BSDBIN/stat" <<EOF
#!/usr/bin/env bash
[ "\$1" = "-c" ] && { echo "stat: illegal option -- c" >&2; exit 1; }
if [ "\$1" = "-f" ] && [ "\$2" = "%m" ]; then
  "$REALSTAT" -c %Y "\$3" 2>/dev/null || "$REALSTAT" -f %m "\$3"; exit
fi
exec "$REALSTAT" "\$@"
EOF
chmod +x "$BSDBIN/find" "$BSDBIN/stat"
bsd_run() { PATH="$BSDBIN:$PATH" "$PROBE" --project "$WORK/p" --home "$WORK/p" 2>&1; }
bsd_rc()  { PATH="$BSDBIN:$PATH" "$PROBE" --project "$WORK/p" --home "$WORK/p" >/dev/null 2>&1; echo $?; }

reset; mined 2026-07-01; sleep 0.01; for i in $(seq 1 12); do session "$i"; done
check_rc "with BSD find and stat, still exits 0" "$(bsd_rc)" 0
has "with BSD find and stat, still counts sessions since the last mine" "$(bsd_run)" "12"

reset; for i in 1 2 3; do session "$i"; done; sleep 0.01; mined 2026-11-15
hasnt "with BSD find and stat, quiet right after a mine report" "$(bsd_run)" "/mine-sessions now"

# --- built-in memory decay -----------------------------------------------
# Claude Code's own memory lives in <root>/<key>/memory/, where the key is the project path
# with every non-alphanumeric replaced by "-". A file's verified date comes from its
# frontmatter; without one, its mtime stands in (this store is not in git, so nothing
# rewrites mtime wholesale the way a checkout does).
reset
KEY="$(printf '%s' "$WORK/p" | sed 's/[^A-Za-z0-9]/-/g')"
MEM="$WORK/auto/$KEY/memory"; mkdir -p "$MEM"
mem() { # $1 file, $2 verified date or ""
  { printf -- '---\nname: %s\ndescription: x\nmetadata:\n  type: project\n' "$1"
    [ -n "$2" ] && printf '  verified: %s\n' "$2"
    printf -- '---\n\nA fact.\n'; } > "$MEM/$1.md"
}
arun() { CLAUDE_MEMORY_ROOT="$WORK/auto" "$PROBE" --project "$WORK/p" --home "$WORK/p" 2>&1; }

mem fresh "$(date +%Y-%m-%d)"
hasnt "built-in memory verified today is not flagged" "$(arun)" "built-in memory"
mem old 2020-01-02
has "a built-in memory file verified long ago is flagged" "$(arun)" "1 built-in memory file(s) unverified since 2020-01-02"
rm -f "$MEM/old.md"
mem undated ""; touch -t 202001010000 "$MEM/undated.md"
has "an undated file falls back to its mtime" "$(arun)" "unverified since 2020-01-01"
touch "$MEM/undated.md"
hasnt "an undated file written recently is not flagged" "$(arun)" "built-in memory"
printf -- '- [x](x.md) — index\n' > "$MEM/MEMORY.md"; touch -t 202001010000 "$MEM/MEMORY.md"
hasnt "the MEMORY.md index is not a fact" "$(arun)" "built-in memory"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
