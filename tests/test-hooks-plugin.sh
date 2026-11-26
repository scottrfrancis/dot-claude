#!/usr/bin/env bash
# test-hooks-plugin.sh — tests for the hooks plugin, marketplace/plugins/hooks
#
# The plugin carries the global hook registrations that each host used to write into its
# settings.json by hand. Claude Code serves it in place from the checkout and runs each command
# with CLAUDE_PLUGIN_ROOT set to the plugin's directory, so the commands reach the scripts in
# the repo's hooks/ through that variable. A command that names a missing script fails on
# every event it is registered for, and in PreToolUse a failing `python3 gone.py` blocks every
# tool call, so each command is run here as Claude Code would run it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -P "$SCRIPT_DIR/.." && pwd -P)"
PLUGIN="$REPO/marketplace/plugins/hooks"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; return 0; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-hooks-plugin.XXXXXX")"; trap 'rm -rf "$WORK"' EXIT
WORK="$(cd -P "$WORK" && pwd -P)"

echo "test-hooks-plugin.sh"
command -v python3 >/dev/null 2>&1 || { echo "  FAIL python3 is required"; echo; echo "0 passed, 1 failed"; exit 1; }

# --- structure ------------------------------------------------------------------------------
while IFS=$'\t' read -r verdict name detail; do
  if [ "$verdict" = ok ]; then ok "$name"; else bad "$name" "$detail"; fi
done < <(python3 - "$REPO" <<'EOF'
import json, os, re, sys
repo = sys.argv[1]
plugin = os.path.join(repo, "marketplace", "plugins", "hooks")

def check(cond, name, detail=""):
    print(f"{'ok' if cond else 'bad'}\t{name}\t{detail}")

def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        return {"_error": str(e)}

mkt = load(os.path.join(repo, "marketplace", ".claude-plugin", "marketplace.json"))
entry = next((p for p in mkt.get("plugins", []) if p.get("name") == "hooks"), {})
check(entry.get("source") == "./plugins/hooks", "the dot-claude marketplace serves hooks from ./plugins/hooks", json.dumps(entry))

meta = load(os.path.join(plugin, ".claude-plugin", "plugin.json"))
check(meta.get("name") == "hooks" and bool(meta.get("version")), "plugin.json names the plugin hooks and gives a version", json.dumps(meta)[:200])

hj = load(os.path.join(plugin, "hooks", "hooks.json"))
events = hj.get("hooks", {})
check(isinstance(events, dict) and events, "hooks/hooks.json parses and registers hooks", hj.get("_error", ""))

regs = []  # (event, matcher, command, timeout)
for ev, groups in events.items():
    for g in groups:
        for h in g.get("hooks", []):
            regs.append((ev, g.get("matcher"), h.get("command", ""), h.get("timeout")))

CMD = re.compile(r'^(python3 )?"\$\{CLAUDE_PLUGIN_ROOT\}/\.\./\.\./\.\./hooks/([\w.-]+)"$')
shapes = [CMD.match(c) for _, _, c, _ in regs]
check(all(shapes), 'every command runs "${CLAUDE_PLUGIN_ROOT}/../../../hooks/<script>", quoted',
      "; ".join(c for (_, _, c, _), m in zip(regs, shapes) if not m))
names = [m.group(2) for m in shapes if m]
missing = [n for n in names if not os.path.isfile(os.path.join(repo, "hooks", n))]
check(not missing, "every script a command names exists in hooks/", ", ".join(missing))
noexec = [n for n, m in zip(names, [m for m in shapes if m])
          if not m.group(1) and not os.access(os.path.join(repo, "hooks", n), os.X_OK)]
check(not noexec, "every script run without an interpreter is executable", ", ".join(noexec))

def reg(ev, script):
    return [(m, t) for e, m, c, t in regs if e == ev and c.endswith(f'/hooks/{script}"')]

check(reg("SessionStart", "session-status.sh") == [("^(startup|clear)$", 30)],
      "SessionStart runs session-status.sh on startup and clear, with 30 seconds", str(reg("SessionStart", "session-status.sh")))
check(reg("SessionStart", "account-mismatch-warn.sh") == [(None, 10)],
      "SessionStart runs account-mismatch-warn.sh on every start, with 10 seconds", str(reg("SessionStart", "account-mismatch-warn.sh")))
check(reg("PreToolUse", "pre-tool-safety.sh") == [("Bash", 10)],
      "PreToolUse runs pre-tool-safety.sh on Bash, with 10 seconds", str(reg("PreToolUse", "pre-tool-safety.sh")))
check(reg("PostToolUse", "prose-check.py") == [("Write|Edit|MultiEdit", 10)],
      "PostToolUse runs prose-check.py on writes, with 10 seconds", str(reg("PostToolUse", "prose-check.py")))
check(reg("Stop", "session-end-reminder.sh") == [(None, 10)],
      "Stop runs session-end-reminder.sh, with 10 seconds", str(reg("Stop", "session-end-reminder.sh")))
check(len(regs) == 5, "the plugin registers those five and nothing else", str([(e, c) for e, _, c, _ in regs]))
retired = [n for n in names if n in ("load-handoff-context.sh", "skill-gate.py", "log-session-tokens")]
check(not retired, "no retired script is registered", ", ".join(retired))
EOF
)

# --- each command runs from the plugin root ---------------------------------------------------
cmd_for() { # $1 = script name: the command hooks.json registers for it
  python3 - "$PLUGIN/hooks/hooks.json" "$1" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
for groups in d["hooks"].values():
    for g in groups:
        for h in g["hooks"]:
            if h["command"].endswith(f'/hooks/{sys.argv[2]}"'):
                print(h["command"]); sys.exit(0)
EOF
}
run() { # $1 = script, $2 = hook JSON: run its command as Claude Code would; print output and rc
  local c; c="$(cmd_for "$1")"
  printf '%s' "$2" | env HOME="$WORK/home" CLAUDE_PLUGIN_ROOT="$PLUGIN" \
    SESSION_STATUS_PUNCH=none SESSION_STATUS_CONFORMANCE=none SESSION_STATUS_INSTALL=none \
    SESSION_STATUS_DOTC=none SESSION_STATUS_WORKSPACE="$WORK/no-workspace" sh -c "$c" 2>&1
  echo "rc=$?"
}
mkdir -p "$WORK/home/.claude" "$WORK/proj"

# A project probe gives the status block a line to report, so a command that never reaches
# bin/session-status.sh (it exits 0 silently when it cannot) shows up as missing output.
mkdir -p "$WORK/proj/.claude"
printf '#!/usr/bin/env bash\necho "probe-from-plugin"\n' > "$WORK/proj/.claude/session-start.sh"
chmod +x "$WORK/proj/.claude/session-start.sh"
out="$(run session-status.sh "{\"source\":\"startup\",\"cwd\":\"$WORK/proj\"}")"
case "$out" in
  *probe-from-plugin*"rc=0") ok "session-status.sh runs from the plugin and reports at startup" ;;
  *) bad "session-status.sh runs from the plugin and reports at startup" "$out" ;;
esac
out="$(run session-status.sh "{\"source\":\"resume\",\"cwd\":\"$WORK/proj\"}")"
[ "$out" = "rc=0" ] && ok "session-status.sh is silent on resume" || bad "session-status.sh is silent on resume" "$out"

out="$(run pre-tool-safety.sh "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"rm -rf $WORK/proj\"},\"cwd\":\"$WORK/proj\"}")"
case "$out" in *"rc=2") ok "pre-tool-safety.sh runs from the plugin and blocks rm -rf" ;; *) bad "pre-tool-safety.sh runs from the plugin and blocks rm -rf" "$out" ;; esac
out="$(run pre-tool-safety.sh "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"},\"cwd\":\"$WORK/proj\"}")"
[ "$out" = "rc=0" ] && ok "pre-tool-safety.sh lets ls through" || bad "pre-tool-safety.sh lets ls through" "$out"

out="$(run prose-check.py "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$WORK/proj/a.txt\",\"content\":\"x\"}}")"
[ "$out" = "rc=0" ] && ok "prose-check.py runs from the plugin and passes a non-Markdown write" || bad "prose-check.py runs from the plugin and passes a non-Markdown write" "$out"

out="$(run session-end-reminder.sh "{\"cwd\":\"$WORK/proj\"}")"
case "$out" in *"rc=0") ok "session-end-reminder.sh runs from the plugin" ;; *) bad "session-end-reminder.sh runs from the plugin" "$out" ;; esac

out="$(run account-mismatch-warn.sh "{\"source\":\"startup\",\"cwd\":\"$WORK/proj\"}")"
case "$out" in *"rc=0") ok "account-mismatch-warn.sh runs from the plugin" ;; *) bad "account-mismatch-warn.sh runs from the plugin" "$out" ;; esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
