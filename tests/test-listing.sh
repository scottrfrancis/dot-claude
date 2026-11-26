#!/usr/bin/env bash
# test-listing.sh — what the skill listing costs, and which commands it offers the model.
#
# Every session lists each model-invocable skill and command by its description, inside a
# budget of 1% of the context window, and drops the least-used descriptions first. So:
# descriptions stay short and lead with when to use them; commands only Scott starts are
# user-only (disable-model-invocation), which takes them out of the listing; the heavy reviews
# run in a forked context so their reading stays out of the working session; and the SDLC set
# lives in an optional plugin that a project enables.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "test-listing.sh"
python3 - "$ROOT" <<'EOF'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
passed = failed = 0

def check(ok: bool, label: str, detail: str = "") -> None:
    global passed, failed
    if ok:
        passed += 1
        print(f"  ok   {label}")
    else:
        failed += 1
        print(f"  FAIL {label}")
        if detail:
            print(f"       {detail}")

def frontmatter(path: Path) -> dict | None:
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "---":
        return None
    out = {}
    for line in lines[1:]:
        if line == "---":
            return out
        m = re.match(r"^([A-Za-z-]+):\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip().strip('"')
    return None

MAX = 200
SDLC = ["discovery-init", "interview-to-spec", "design-review", "trace-check", "constitution",
        "assumptions", "gherkin"]
USER_ONLY = ["arch-review", "doc-review", "security-audit", "review-pr", "mine-sessions",
             "memorialize", "autocommit", "punch", "build-pdf"]
FORKED = ["arch-review", "doc-review", "security-audit", "review-pr", "mine-sessions"]
# Claude starts these itself, or /lets-go offers them and runs them on a yes. /babysit-pr and
# /link-sweep run under /loop, and a scheduled fire passes a user-only command to Claude as
# plain text without running it (docs: scheduled-tasks, "Run a prompt repeatedly with /loop").
MODEL = ["lets-go", "pickup", "handoff", "session-logger", "editorial-review", "babysit-pr",
         "link-sweep"]

skills = sorted(p for p in (root / "skills").glob("*/SKILL.md") if p.parent.name != "synced")
commands = sorted((root / "commands").glob("*.md"))
plugin = root / "marketplace" / "plugins" / "sdlc"
plugin_cmds = sorted((plugin / "commands").glob("*.md"))

nofm = [str(p.relative_to(root)) for p in commands + plugin_cmds if frontmatter(p) is None
        or not frontmatter(p).get("description")]
check(not nofm, "every command has frontmatter with a description", ", ".join(nofm))

long = [f"{p.relative_to(root)} ({len(d)})" for p in skills + commands + plugin_cmds
        if (d := (frontmatter(p) or {}).get("description", "")) and len(d) > MAX]
check(not long, f"every description is at most {MAX} characters", ", ".join(long))

trig = [p.parent.name for p in skills
        if not re.match(r"Use (when|before) ", (frontmatter(p) or {}).get("description", ""))]
check(not trig, "every skill description leads with when to use it", ", ".join(trig))

def fm(name: str) -> dict:
    p = root / "commands" / f"{name}.md"
    return (frontmatter(p) or {}) if p.exists() else {}

missing = [c for c in USER_ONLY + MODEL if not (root / "commands" / f"{c}.md").exists()]
check(not missing, "the commands named here exist", ", ".join(missing))
notuser = [c for c in USER_ONLY if fm(c).get("disable-model-invocation") != "true"]
check(not notuser, "commands only Scott starts are user-only", ", ".join(notuser))
notfork = [c for c in FORKED if fm(c).get("context") != "fork"]
check(not notfork, "the heavy reviews run in a forked context", ", ".join(notfork))
blocked = [c for c in MODEL if fm(c).get("disable-model-invocation") == "true"]
check(not blocked, "the core loop stays model-invocable", ", ".join(blocked))

left = [c for c in SDLC if (root / "commands" / f"{c}.md").exists()]
check(not left, "the SDLC commands are out of commands/", ", ".join(left))
moved = sorted(p.stem for p in plugin_cmds)
check(moved == sorted(SDLC), "the sdlc plugin carries all seven", f"{moved}")

try:
    mkt = json.loads((root / "marketplace" / ".claude-plugin" / "marketplace.json").read_text())
    entry = next((p for p in mkt.get("plugins", []) if p.get("name") == "sdlc"), {})
    ok = mkt.get("name") == "dot-claude" and entry.get("source") == "./plugins/sdlc"
    check(ok, "marketplace.json names the dot-claude marketplace and serves sdlc from ./plugins/sdlc",
          json.dumps(mkt)[:200])
except (OSError, ValueError) as e:
    check(False, "marketplace.json names the dot-claude marketplace and serves sdlc from ./plugins/sdlc", str(e))
try:
    meta = json.loads((plugin / ".claude-plugin" / "plugin.json").read_text())
    check(meta.get("name") == "sdlc", "plugin.json names the plugin sdlc", json.dumps(meta)[:200])
except (OSError, ValueError) as e:
    check(False, "plugin.json names the plugin sdlc", str(e))

# Inside a plugin a command is typed /sdlc:<name>, so a bare /gherkin in its text is stale.
bare = re.compile(r"(?<![\w:/.-])/(" + "|".join(SDLC) + r")\b")
stale = [f"{p.name}:{i}" for p in plugin_cmds for i, line in enumerate(p.read_text().splitlines(), 1)
         if bare.search(line)]
check(not stale, "plugin commands refer to each other as /sdlc:<name>", ", ".join(stale[:8]))

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
EOF
