#!/usr/bin/env bash
# test-install.sh — tests for bin/install.sh
#
# The installer sets a host up from this checkout. It links the repo into each config dir
# Claude Code reads, creates the host's host.md, and enables the hooks plugin in each
# settings.json. It writes outside the repo, so a dry run is the default; it never replaces
# what it did not create, and --check only reads. Every case runs against a fixture checkout
# and a fixture home, so nothing on the host is touched.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain: $3 | got: $2" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1" "expected NOT to contain: $3 | got: $2" ;; *) ok "$1" ;; esac; }
is()    { [ "$2" = "$3" ] && ok "$1" || bad "$1" "expected: $3 | got: $2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-install.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"
TL='~'   # a literal tilde, as settings.json spells hook paths

echo "test-install.sh"
for f in "$REAL/bin/install.sh" "$REAL/bin/link-config.sh"; do
  if [ ! -x "$f" ]; then
    echo "  FAIL $f is missing or not executable"; echo; echo "0 passed, 1 failed"; exit 1
  fi
done
command -v python3 >/dev/null 2>&1 || { echo "  FAIL python3 is required"; echo; echo "0 passed, 1 failed"; exit 1; }

# A fixture checkout: the real installer, hook scripts and marketplace, one of everything else.
mkcheckout() { # $1 = dir
  local r="$1"
  mkdir -p "$r/bin" "$r/skills/testing" "$r/skills/synced/own" "$r/rules" "$r/doctrine" "$r/memory"
  cp "$REAL/bin/install.sh" "$REAL/bin/link-config.sh" "$r/bin/"
  cp -R "$REAL/hooks" "$r/hooks"
  cp -R "$REAL/marketplace" "$r/marketplace"
  printf '# Working rules\n\n@~/.claude/host.md\n' > "$r/CLAUDE.md"
  printf -- '---\nname: testing\n---\n' > "$r/skills/testing/SKILL.md"
  printf 'own\n' > "$r/skills/synced/own/SKILL.md"
  printf -- '---\npaths:\n  - "**/*.sh"\n---\nshell\n' > "$r/rules/shell.md"
  printf '# Homelab doctrine\n' > "$r/doctrine/homelab.md"
  printf -- '- a universal fact\n' > "$r/memory/MEMORY.md"
}
profile() { # $1 = config dir, $2 = checkout: a config dir whose CLAUDE.md comes from $2
  mkdir -p "$1" && ln -s "$2/CLAUDE.md" "$1/CLAUDE.md"
}
# Print a Python expression over the parsed JSON file $1, bound to d.
j() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))' "$1" "$2" 2>&1; }
cmds() { j "$1" '"\n".join(h.get("command","") for ev in d.get("hooks",{}).values() for g in ev for h in g.get("hooks",[]))'; }

# --- links --------------------------------------------------------------------------------
R="$WORK/r1"; mkcheckout "$R"; I="$R/bin/install.sh"
P="$WORK/p1/.claude"; profile "$P" "$R"

out="$("$I" "$P" 2>&1)"
has "links: a dry run says what it would link" "$out" "would link $P/skills/testing"
[ ! -e "$P/skills/testing" ] && [ ! -e "$P/settings.json" ] && ok "links: a dry run changes nothing" \
  || bad "links: a dry run changes nothing" "$(ls -la "$P")"

"$I" --apply "$P" >/dev/null 2>&1
is "links: --apply links each repo skill by absolute path" "$(readlink "$P/skills/testing")" "$R/skills/testing"
is "links: --apply links bin/" "$(readlink "$P/bin")" "$R/bin"
is "links: --apply links doctrine/, which host.md imports from" "$(readlink "$P/doctrine")" "$R/doctrine"
is "links: --apply links memory/, which CLAUDE.md imports from" "$(readlink "$P/memory")" "$R/memory"
is "links: --apply links rules/, the path-scoped rules" "$(readlink "$P/rules")" "$R/rules"
[ ! -e "$P/skills/synced" ] && ok "links: Claude Code's own skills/synced is not linked" \
  || bad "links: Claude Code's own skills/synced is not linked"
[ ! -e "$P/host.md" ] && [ ! -L "$P/host.md" ] && ok "links: no host.md in the checkout, so none is linked" \
  || bad "links: no host.md in the checkout, so none is linked"

out="$("$I" --apply "$P" 2>&1)"
lacks "links: a second run has nothing to link" "$out" "link $P"

mkdir -p "$WORK/p2/.claude/skills/testing"; profile "$WORK/p2/.claude" "$R"
echo mine > "$WORK/p2/.claude/skills/testing/SKILL.md"
out="$("$I" --apply "$WORK/p2/.claude" 2>&1)"
has "links: an existing skill that is not ours is reported" "$out" "skip $WORK/p2/.claude/skills/testing"
is "links: and left untouched" "$(cat "$WORK/p2/.claude/skills/testing/SKILL.md")" mine

ln -s "$R/skills/no-longer-exists" "$P/skills/no-longer-exists"
"$I" --apply "$P" >/dev/null 2>&1
[ ! -L "$P/skills/no-longer-exists" ] && ok "links: a dangling link into the checkout's skills is removed" \
  || bad "links: a dangling link into the checkout's skills is removed"
ln -s "$WORK/elsewhere" "$P/skills/foreign"
"$I" --apply "$P" >/dev/null 2>&1
[ -L "$P/skills/foreign" ] && ok "links: a dangling link pointing elsewhere is left alone" \
  || bad "links: a dangling link pointing elsewhere is left alone"

# --- host.md --------------------------------------------------------------------------------
# CLAUDE.md imports ~/.claude/host.md, which git ignores. A homelab host's imports the homelab
# doctrine and any other host's is empty. Only Scott knows which a host is, so the installer
# never guesses.
R2="$WORK/r2"; mkcheckout "$R2"; I2="$R2/bin/install.sh"; P2="$WORK/p3/.claude"; profile "$P2" "$R2"

out="$("$I2" --apply "$P2" 2>&1)"
[ ! -e "$R2/host.md" ] && ok "host.md: without --doctrine, none is made" || bad "host.md: without --doctrine, none is made"
has "host.md: and the output says how to choose" "$out" "--doctrine homelab"

out="$("$I2" --doctrine nosuch --apply "$P2" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "host.md: an unknown doctrine fails the run" || bad "host.md: an unknown doctrine fails the run" "rc=$rc"
has "host.md: and the doctrines there are are named" "$out" "homelab"
[ ! -e "$R2/host.md" ] && ok "host.md: and nothing is made" || bad "host.md: and nothing is made"

"$I2" --doctrine homelab "$P2" >/dev/null 2>&1
[ ! -e "$R2/host.md" ] && ok "host.md: a dry run with --doctrine makes nothing" || bad "host.md: a dry run with --doctrine makes nothing"

"$I2" --doctrine homelab --apply "$P2" >/dev/null 2>&1
is "host.md: --doctrine homelab writes the import line" "$(cat "$R2/host.md" 2>&1)" "@~/.claude/doctrine/homelab.md"
is "host.md: and links it into the config dir in the same run" "$(readlink "$P2/host.md")" "$R2/host.md"

echo mine > "$R2/host.md"
"$I2" --doctrine none --apply "$P2" >/dev/null 2>&1
is "host.md: an existing one is never overwritten" "$(cat "$R2/host.md")" mine

R3="$WORK/r3"; mkcheckout "$R3"; profile "$WORK/p4/.claude" "$R3"
"$R3/bin/install.sh" --doctrine none --apply "$WORK/p4/.claude" >/dev/null 2>&1
[ -f "$R3/host.md" ] && [ ! -s "$R3/host.md" ] && ok "host.md: --doctrine none makes an empty one" \
  || bad "host.md: --doctrine none makes an empty one" "$(ls -la "$R3")"

# --- settings.json --------------------------------------------------------------------------
# Studio's shape: two profiles share one settings.json through symlinks, which registers the
# dot-claude hooks by hand next to the host's own (a terminal status script, herdr).
R4="$WORK/r4"; mkcheckout "$R4"; I4="$R4/bin/install.sh"
H="$WORK/home"
profile "$H/.claude-profiles/ss/.claude" "$R4"; profile "$H/.claude-profiles/al/.claude" "$R4"
# Studio's profiles link hooks/ too, so ~/.claude/hooks/<script> resolves in each.
ln -s "$R4/hooks" "$H/.claude-profiles/ss/.claude/hooks"; ln -s "$R4/hooks" "$H/.claude-profiles/al/.claude/hooks"
mkdir -p "$WORK/elsewhere/.claude/hooks" && : > "$WORK/elsewhere/.claude/hooks/pre-tool-safety.sh"
SHARED="$WORK/shared/settings.json"; mkdir -p "$WORK/shared"
cat > "$SHARED" <<'EOF'
{
  "permissions": { "allow": ["Bash(ls:*)"] },
  "enabledPlugins": { "warp@claude-code-warp": true },
  "hooks": {
    "SessionStart": [
      { "hooks": [
          { "type": "command", "command": "~/.claude/hooks/load-handoff-context.sh", "timeout": 5000 },
          { "type": "command", "command": "~/.claude/hooks/account-mismatch-warn.sh", "timeout": 5000 } ] },
      { "hooks": [ { "type": "command", "command": "/opt/term/cc-status" } ] },
      { "matcher": "compact", "hooks": [ { "type": "command", "command": "~/.claude/hooks/session-status.sh" } ] }
    ],
    "PreToolUse": [
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/pre-tool-safety.sh", "timeout": 5000 } ] },
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "@WORK@/elsewhere/.claude/hooks/pre-tool-safety.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "^(Bash)$", "hooks": [ { "type": "command", "command": "bash '@R4@/hooks/herdr-follow-worktree.sh'" } ] },
      { "matcher": "Write|Edit", "hooks": [ { "type": "command", "command": "python3 ~/.claude/hooks/skill-gate.py" } ] },
      { "matcher": "Write|Edit|MultiEdit", "hooks": [ { "type": "command", "command": "python3 '@R4@/hooks/prose-check.py'" } ] },
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/pre-tool-safety.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/session-end-reminder.sh" } ] },
      { "hooks": [ { "type": "command", "command": "/opt/term/cc-status stop; ~/.claude/hooks/session-end-reminder.sh" } ] }
    ]
  }
}
EOF
sed -i.tmp -e "s|@R4@|$R4|g" -e "s|@WORK@|$WORK|g" "$SHARED" && rm -f "$SHARED.tmp"
chmod 600 "$SHARED"
cp "$SHARED" "$WORK/orig.json"
ln -s "$SHARED" "$H/.claude-profiles/ss/.claude/settings.json"
ln -s "$SHARED" "$H/.claude-profiles/al/.claude/settings.json"

out="$(INSTALL_HOME="$H" "$I4" --doctrine homelab 2>&1)"
has "settings: a dry run says it would enable the hooks plugin" "$out" "would enable hooks@dot-claude in"
has "settings: and remove the registrations the plugin replaces" "$out" "would remove"
n="$(printf '%s\n' "$out" | grep -c 'would enable hooks@dot-claude')"
is "settings: a settings.json two profiles share is planned once" "${n:-0}" 1
cmp -s "$SHARED" "$WORK/orig.json" && ok "settings: a dry run leaves settings.json as it was" \
  || bad "settings: a dry run leaves settings.json as it was"

INSTALL_HOME="$H" "$I4" --doctrine homelab --apply >/dev/null 2>&1
is "settings: --apply enables hooks@dot-claude" "$(j "$SHARED" 'd["enabledPlugins"]["hooks@dot-claude"]')" True
is "settings: and declares the marketplace at the checkout's marketplace/" \
  "$(j "$SHARED" 'd["extraKnownMarketplaces"]["dot-claude"]["source"]')" \
  "{'source': 'directory', 'path': '$R4/marketplace'}"
c="$(cmds "$SHARED")"
is "settings: the hand-written PreToolUse pre-tool-safety.sh is removed" \
  "$(j "$SHARED" 'any(h["command"] == "~/.claude/hooks/pre-tool-safety.sh" for g in d["hooks"]["PreToolUse"] for h in g["hooks"])')" False
lacks "settings: so is one named by its absolute path in this checkout" "$c" "$R4/hooks/prose-check.py"
has "settings: a script of the same name in another directory stays" "$c" "$WORK/elsewhere/.claude/hooks/pre-tool-safety.sh"
has "settings: a covered script registered for another matcher stays" "$c" "$TL/.claude/hooks/session-status.sh"
n="$(printf '%s\n' "$c" | grep -cF "$TL/.claude/hooks/pre-tool-safety.sh")"
is "settings: a covered script registered for another event stays" "${n:-0}" 1
has "settings: a compound command stays whole" "$c" "/opt/term/cc-status stop; ~/.claude/hooks/session-end-reminder.sh"
n="$(printf '%s\n' "$c" | grep -c 'session-end-reminder')"
is "settings: and the plain session-end-reminder.sh" "${n:-0}" 1
lacks "settings: and account-mismatch-warn.sh" "$c" "account-mismatch-warn"
lacks "settings: and the old load-handoff-context.sh alias" "$c" "load-handoff-context"
lacks "settings: and the retired skill gate" "$c" "skill-gate"
has "settings: the host's own hooks stay" "$c" "/opt/term/cc-status"
has "settings: including a dot-claude hook the plugin does not carry" "$c" "herdr-follow-worktree.sh"
is "settings: a group left with no hooks is dropped" "$(j "$SHARED" 'len(d["hooks"]["PreToolUse"])')" 1
is "settings: other settings are kept" "$(j "$SHARED" 'd["permissions"]["allow"][0]')" "Bash(ls:*)"
is "settings: other plugins are kept" "$(j "$SHARED" 'd["enabledPlugins"]["warp@claude-code-warp"]')" True
[ -L "$H/.claude-profiles/ss/.claude/settings.json" ] && ok "settings: a shared settings.json stays a link" \
  || bad "settings: a shared settings.json stays a link"
is "settings: and keeps its permissions" "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$SHARED")" 0o600
baks=("$WORK"/shared/settings.json.*.bak)
is "settings: a settings.json two profiles share is backed up once" "${#baks[@]}" 1
cmp -s "${baks[0]}" "$WORK/orig.json" && ok "settings: the backup holds the original" \
  || bad "settings: the backup holds the original"

out="$(INSTALL_HOME="$H" "$I4" --apply 2>&1)"
lacks "settings: a second run has nothing to change" "$out" "settings.json"
baks=("$WORK"/shared/settings.json.*.bak)
is "settings: and writes no second backup" "${#baks[@]}" 1

P5="$WORK/p5/.claude"; profile "$P5" "$R4"
"$I4" --apply "$P5" >/dev/null 2>&1
is "settings: a config dir with no settings.json gets one that enables the plugin" \
  "$(j "$P5/settings.json" 'd["enabledPlugins"]["hooks@dot-claude"]')" True

P11="$WORK/p11/.claude"; profile "$P11" "$R4"
printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"~/.claude/hooks/session-end-reminder.sh"}]}]}}\n' > "$P11/settings.json"
"$I4" --apply "$P11" >/dev/null 2>&1
is "settings: an event left with no hooks is dropped" "$(j "$P11/settings.json" '"Stop" in d.get("hooks", {})')" False
P12="$WORK/p12/.claude"; profile "$P12" "$R4"
printf '{"enabledPlugins":{"hooks@dot-claude":true},"extraKnownMarketplaces":{"dot-claude":{"source":{"source":"directory","path":"%s"}}},"hooks":{"PostToolUse":[{"hooks":[{"type":"command","command":"python3 ~/.claude/hooks/skill-gate.py"}]}]}}\n' "$R4/marketplace" > "$P12/settings.json"
"$I4" --apply "$P12" >/dev/null 2>&1
lacks "settings: a retired script registered alone is removed" "$(cmds "$P12/settings.json")" "skill-gate"

P6="$WORK/p6/.claude"; profile "$P6" "$R4"; printf '{not json\n' > "$P6/settings.json"
out="$("$I4" --apply "$P6" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "settings: a settings.json that is not JSON fails the run" \
  || bad "settings: a settings.json that is not JSON fails the run" "rc=$rc"
has "settings: and is named" "$out" "$P6/settings.json"
is "settings: and is left as it was" "$(cat "$P6/settings.json")" "{not json"

# A checkout that moved leaves the marketplace pointing at the old path.
P7="$WORK/p7/.claude"; profile "$P7" "$R4"
printf '{"extraKnownMarketplaces":{"dot-claude":{"source":{"source":"directory","path":"/old/checkout/marketplace"}}},"enabledPlugins":{"hooks@dot-claude":true}}\n' > "$P7/settings.json"
"$I4" --apply "$P7" >/dev/null 2>&1
is "settings: a marketplace declared at an old path is moved to this checkout" \
  "$(j "$P7/settings.json" 'd["extraKnownMarketplaces"]["dot-claude"]["source"]["path"]')" "$R4/marketplace"

# On a host without profiles, ~/.claude is the checkout and its settings.json is the one to edit.
R5="$WORK/r5"; mkcheckout "$R5"; H5="$WORK/home5"; mkdir -p "$H5"; ln -s "$R5" "$H5/.claude"
out="$(INSTALL_HOME="$H5" "$R5/bin/install.sh" --doctrine none --apply 2>&1)"
is "settings: when ~/.claude is the checkout, its own settings.json enables the plugin" \
  "$(j "$R5/settings.json" 'd["enabledPlugins"]["hooks@dot-claude"]')" True
lacks "settings: and the checkout is not linked into itself" "$out" "$H5/.claude/bin"

# --- --check ------------------------------------------------------------------------------
out="$(INSTALL_HOME="$H" "$I4" --check 2>&1)"; rc=$?
is "check: after an install, --check prints nothing" "$out" ""
is "check: and exits 0" "$rc" 0
printf '{"hooks":{}}\n' > "$WORK/broken.json"; cp "$SHARED" "$WORK/shared.keep"; cp "$WORK/broken.json" "$SHARED"
out="$(INSTALL_HOME="$H" "$I4" --check 2>&1)"
n="$(printf '%s\n' "$out" | grep -c 'is not enabled in')"
is "check: a settings.json two profiles share is reported once" "${n:-0}" 1
cp "$WORK/shared.keep" "$SHARED"

P8="$WORK/p8/.claude"; profile "$P8" "$R4"
before="$(cd "$WORK/p8" && find . | sort)"
out="$("$I4" --check "$P8" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "check: exits non-zero when something needs fixing" || bad "check: exits non-zero when something needs fixing"
is "check: and changes nothing" "$(cd "$WORK/p8" && find . | sort)" "$before"
has "check: unlinked skills are counted" "$out" "skills: 1 of 1 dot-claude skills are not linked into $P8"
has "check: a missing rules/ is named" "$out" "rules: $P8 has no rules/"
has "check: missing bin/, doctrine/ and memory/ are named" "$out" "bin/, doctrine/, memory/"
has "check: a config dir whose host.md is not linked is named" "$out" "host.md: $P8/host.md is missing"
has "check: a missing settings.json is named" "$out" "no $P8/settings.json"
has "check: each line gives the command that fixes that config dir" "$out" "run $R4/bin/install.sh --apply $P8"

NO="$WORK/other/.claude-server"; mkdir -p "$NO"; echo "its own rules" > "$NO/CLAUDE.md"
out="$("$I4" --check "$NO" 2>&1)"; rc=$?
is "check: a config dir that is not this checkout's is not checked" "$out" ""
is "check: and passes" "$rc" 0
out="$("$I4" --apply "$NO" 2>&1)"
has "apply: a config dir that is not this checkout's is skipped, with the reason" "$out" "skip $NO"
[ ! -e "$NO/skills" ] && [ ! -e "$NO/settings.json" ] && ok "apply: and nothing is written there" \
  || bad "apply: and nothing is written there" "$(ls -la "$NO")"

R6="$WORK/r6"; mkcheckout "$R6"; P9="$WORK/p9/.claude"; profile "$P9" "$R6"
out="$("$R6/bin/install.sh" --check "$P9" 2>&1)"
has "check: a checkout with no host.md is named, with both ways to make one" "$out" "--doctrine homelab --apply on a homelab host, or --doctrine none"
printf '@/nonexistent/doctrine.md\n' > "$R6/host.md"; "$R6/bin/install.sh" --apply "$P9" >/dev/null 2>&1
out="$("$R6/bin/install.sh" --check "$P9" 2>&1)"
has "check: a host.md import that does not resolve is named" "$out" "imports /nonexistent/doctrine.md, which does not exist"

printf '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"~/.claude/hooks/pre-tool-safety.sh"}]}]}}\n' > "$P9/settings.json"
out="$("$R6/bin/install.sh" --check "$P9" 2>&1)"
has "check: a settings.json without the plugin is named" "$out" "hooks@dot-claude) is not enabled in $P9/settings.json"
has "check: along with what it registers by hand" "$out" "registers pre-tool-safety.sh by hand"

python3 - "$P9/settings.json" "$R6/marketplace" <<'EOF'
import json, sys
p, m = sys.argv[1:3]
d = json.load(open(p))
d["enabledPlugins"] = {"hooks@dot-claude": True}
d["extraKnownMarketplaces"] = {"dot-claude": {"source": {"source": "directory", "path": m}}}
d["hooks"]["Stop"] = [{"hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/gone.py"},
                                  {"type": "command", "command": "~/.claude/hooks/here.sh"}]}]
json.dump(d, open(p, "w"))
EOF
mkdir -p "$WORK/p9/.claude/hooks" && : > "$WORK/p9/.claude/hooks/here.sh" && : > "$WORK/p9/.claude/hooks/mine.sh"
python3 - "$P9/settings.json" <<'EOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["hooks"]["Notification"] = [{"hooks": [
    {"type": "command", "command": '"$HOME"/.claude/hooks/mine.sh'},
    {"type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/project.sh"},
    {"type": "command", "command": "curl -s http://127.0.0.1:8099/hooks/notify"},
    {"type": "command", "command": "python3 ~/.claude/hooks/skill-gate.py"}]}]
json.dump(d, open(p, "w"))
EOF
out="$("$R6/bin/install.sh" --check "$P9" 2>&1)"
has "check: a hook registered both by hand and by the plugin runs twice" "$out" "pre-tool-safety.sh by hand as well as through the plugin"
has "check: a registered script that does not exist is named" "$out" "registers ~/.claude/hooks/gone.py, which does not exist"
lacks "check: a registered script that exists is not" "$out" "here.sh"
lacks "check: a script reached through \"\$HOME\" is resolved, and exists" "$out" "mine.sh"
lacks "check: a path behind another variable is not guessed at" "$out" "project.sh"
lacks "check: a URL is not a script path" "$out" "notify"
has "check: the retired skill gate registered by hand is called retired" "$out" "registers the retired skill-gate.py"
lacks "check: and is not said to run twice" "$out" "skill-gate.py by hand as well"

# --- discovery and the old name -------------------------------------------------------------
H2="$WORK/home2"; profile "$H2/.claude-profiles/ss/.claude" "$R"; profile "$H2/.claude-client" "$R"
mkdir -p "$H2/.claude-unrelated" && echo x > "$H2/.claude-unrelated/CLAUDE.md"
out="$(INSTALL_HOME="$H2" "$I" 2>&1)"
has "discovery: finds HOME-swapped profiles" "$out" "$H2/.claude-profiles/ss/.claude/skills/testing"
has "discovery: finds CLAUDE_CONFIG_DIR-style dirs" "$out" "$H2/.claude-client/skills/testing"
lacks "discovery: ignores config dirs that are not this checkout's" "$out" ".claude-unrelated"
out="$(LINK_CONFIG_HOME="$H2" "$R/bin/link-config.sh" 2>&1)"
has "link-config.sh still works, as the old name of install.sh" "$out" "would link $H2/.claude-client/skills/testing"

out="$(python3 - "$I" <<'EOF'
import subprocess, sys
try:
    r = subprocess.run([sys.argv[1], "--apply", "--doctrine"], capture_output=True, text=True, timeout=10)
    print(f"rc={r.returncode} {r.stdout}{r.stderr}")
except subprocess.TimeoutExpired:
    print("hung")
EOF
)"
lacks "args: --doctrine with no value does not hang" "$out" "hung"
lacks "args: and fails" "$out" "rc=0 "
has "args: and says it needs a value" "$out" "needs a value"

R7="$WORK/r7"; mkcheckout "$R7"; mkdir -p "$WORK/empty-home"
for sh in bash /bin/bash; do
  command -v "$sh" >/dev/null 2>&1 || continue
  out="$(INSTALL_HOME="$WORK/empty-home" "$sh" "$R7/bin/install.sh" --doctrine homelab --apply 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && ok "discovery: no config dir found fails the run ($sh)" || bad "discovery: no config dir found fails the run ($sh)" "rc=$rc"
  has "discovery: and says so ($sh)" "$out" "no config dir"
  lacks "discovery: without a crash ($sh)" "$out" "unbound variable"
  [ ! -e "$R7/host.md" ] && ok "discovery: and creates no host.md ($sh)" || bad "discovery: and creates no host.md ($sh)"
done

ln -s "$R" "$WORK/r1-alias"
P10="$WORK/p10/.claude"; profile "$P10" "$R"; mkdir -p "$P10/skills"; ln -s "$WORK/r1-alias/skills/testing" "$P10/skills/testing"
out="$("$I" --apply "$P10" 2>&1)"
lacks "links: a link to the same place spelled another way is not reported as foreign" "$out" "skip $P10/skills/testing"

out="$("$I" --help 2>&1)"
has "--help prints the usage" "$out" "install.sh [--apply | --check]"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
