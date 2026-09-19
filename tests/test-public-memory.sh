#!/usr/bin/env bash
# test-public-memory.sh — tests for bin/check-public-memory.sh
#
# dot-claude is a public repository. A personal email address reached it and sat in history.
# This is the gate that stops the next one: it fails the build rather than nudging, because
# a leak is an error and history is not erased by a later edit.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../bin/check-public-memory.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
rc()  { "$CHECK" "$WORK/m.md" >/dev/null 2>&1; echo $?; }
out() { "$CHECK" "$WORK/m.md" 2>&1; }
mem() { printf '# Memory\n\n%s\n' "$1" > "$WORK/m.md"; }
rejects() { mem "$2"; [ "$(rc)" = 1 ] && ok "rejects $1" || bad "rejects $1" "accepted: $2"; }
accepts() { mem "$2"; [ "$(rc)" = 0 ] && ok "accepts $1" || bad "accepts $1" "rejected: $(out)"; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

echo "test-public-memory.sh"
if [ ! -x "$CHECK" ]; then
  echo "  FAIL bin/check-public-memory.sh is missing or not executable — assertions would pass vacuously"
  echo; echo "0 passed, 1 failed"; exit 1
fi

# --- the leak that actually happened -------------------------------------
rejects "an email address"            '- **A person** - a relative. Email: `someone@example.com` [2026-08-19]'
out="$(mem '- mail me at a.b@c.io [2026-08-19]'; out)"
case "$out" in *"line 3"*) ok "names the offending line" ;; *) bad "names the offending line" "$out" ;; esac

# --- other things that must not reach a public repo ----------------------
rejects "a private IPv4 address"      '- The box is at 192.168.1.42 [2026-08-19]'
rejects "a .local hostname"           '- Served from mini.local:8092 [2026-08-19]'
rejects "an AWS access key id"        '- key AKIAIOSFODNN7EXAMPLE [2026-08-19]'
rejects "a bearer/API token shape"    '- token: ghp_A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8 [2026-08-19]'
rejects "a private key header"        '- -----BEGIN RSA PRIVATE KEY----- [2026-08-19]'
rejects "a home path with a username" '- see /Users/sfrancis/workspace/notes.md [2026-08-19]'

# --- ordinary content must not trip it -----------------------------------
accepts "a plain convention"          '- `git add -u` not `git add .` in autocommit [2026-03-10]'
accepts "a pointer to kb-mcp"         '- Household contacts live behind `kb-mcp`, never inline here [2026-08-19]'
accepts "a public repo URL"           '- Upstream is https://github.com/scottrfrancis/dot-claude [2026-08-19]'
accepts "a version-like number"       '- Requires shellcheck 0.9.0 or newer [2026-08-19]'
accepts "a tilde home path"           '- Config lives in ~/.claude/settings.json [2026-08-19]'
# `.local` as a hostname suffix is sensitive; `.local` inside a filename is not.
accepts "a settings.local.json path"  '- Project permissions belong in `.claude/settings.local.json` [2026-08-19]'
accepts "a .local.yml filename"       '- Overrides go in `config.local.yml` [2026-08-19]'
rejects "a LAN host with a port"      '- Served from mini.local:8092 [2026-08-19]'
rejects "a bare LAN host"             '- The probe runs on hasami.local [2026-08-19]'

# An allow marker lets a deliberate, reviewed exception through — with a visible trace.
accepts "an explicit allow marker"    '- Contact team@example.org <!-- public-ok: documented support alias --> [2026-08-19]'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
