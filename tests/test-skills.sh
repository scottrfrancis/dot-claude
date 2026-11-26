#!/usr/bin/env bash
# test-skills.sh — structural checks on skills/ and the guideline symlinks into it.
#
# Topic guidelines are skills, so Claude Code loads each one when its description matches the
# work, or path-scoped rules (rules/, checked by test-rules.sh), which load with a matching file.
# guidelines/<name>.md stays as a symlink to the skill or rule so commands, cross-references and
# downstream repos keep resolving. A skill whose frontmatter does not parse is silently never
# offered, and a moved file's relative links break silently, so both are checked here.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "test-skills.sh"
python3 - "$ROOT" <<'EOF'
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

# Guidelines that stay plain files: homelab doctrine, the opt-in hardware guideline, and the
# memory convention that bin/memory-scope.sh documents.
KEPT = {"central-ops-knowledge", "beaufort-todo-announcements", "environments-and-llm-spend",
        "session-safety", "memory"}
# Links that are examples inside sample documents, meant to be unresolved.
EXAMPLE_LINKS = {("readme-documentation", "docs/configuration.md")}

def frontmatter(text: str) -> dict:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return {}
    out = {}
    for line in lines[1:]:
        if line == "---":
            return out
        m = re.match(r"^([A-Za-z-]+):\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2)
    return {}

skills = sorted(p for p in (root / "skills").glob("*/SKILL.md") if p.parent.name != "synced")
bad_fm, bad_name, bad_desc = [], [], []
for s in skills:
    fm = frontmatter(s.read_text())
    if not fm:
        bad_fm.append(s.parent.name)
        continue
    if fm.get("name") != s.parent.name or not re.fullmatch(r"[a-z0-9-]+", fm.get("name", "")):
        bad_name.append(s.parent.name)
    d = fm.get("description", "")
    quoted = len(d) >= 2 and d[0] == d[-1] and d[0] in "\"'"
    if not d or (": " in d and not quoted) or (" #" in d and not quoted):
        bad_desc.append(s.parent.name)
check(not bad_fm, "every skill opens with YAML frontmatter", ", ".join(bad_fm))
check(not bad_name, "every skill name is lowercase and matches its directory", ", ".join(bad_name))
check(not bad_desc, "every description is present, and quoted where YAML needs it", ", ".join(bad_desc))

plain, linked, as_rule, wrong = set(), set(), set(), []
for g in sorted((root / "guidelines").glob("*.md")):
    if g.is_symlink():
        target = g.resolve()
        if target.name == "SKILL.md" and target.parent.parent == (root / "skills").resolve():
            linked.add(g.stem)
        elif target.parent == (root / "rules").resolve() and target.is_file():
            as_rule.add(g.stem)
        else:
            wrong.append(f"{g.name} -> {target}")
    else:
        plain.add(g.stem)
check(not wrong, "every guideline symlink resolves to a skill's SKILL.md or a rule", "; ".join(wrong))
check(plain == KEPT, "exactly the homelab and opt-in guidelines stay plain files",
      f"plain but expected a skill: {sorted(plain - KEPT)}; expected plain: {sorted(KEPT - plain)}")
check(len(linked) >= 24 and len(as_rule) >= 6, "the topic guidelines are skills or rules",
      f"{len(linked)} skills, {len(as_rule)} rules")

hidden = []
for name in linked:
    target = (root / "guidelines" / f"{name}.md").resolve()
    if frontmatter(target.read_text()).get("user-invocable") != "false":
        hidden.append(target.parent.name)
check(not hidden, "guideline skills stay out of the / menu (user-invocable: false)", ", ".join(hidden))

link = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
broken = []
for s in skills + [root / "guidelines" / f"{k}.md" for k in KEPT]:
    fenced = False
    for i, line in enumerate(s.read_text().splitlines(), 1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        for t in link.findall(re.sub(r"`[^`]*`", "", line)):
            if re.match(r"^(https?:|mailto:|#)", t):
                continue
            p = t.split("#")[0]
            if not p or (s.parent.name, p) in EXAMPLE_LINKS:
                continue
            if not (s.parent / p).exists():
                broken.append(f"{s.relative_to(root)}:{i} -> {t}")
check(not broken, "every relative link in a skill or kept guideline resolves", "; ".join(broken[:8]))

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
EOF
