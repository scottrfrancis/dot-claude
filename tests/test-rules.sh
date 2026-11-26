#!/usr/bin/env bash
# test-rules.sh — structural checks on rules/, the path-scoped user rules.
#
# Claude Code loads ~/.claude/rules/<name>.md when Claude reads, writes or edits a file whose
# path matches the rule's `paths:` globs, including a file it is creating. The rules replace
# hooks/skill-gate.py, so every file type the gate governed must still match a rule, and no
# rule may match everything. A rule whose frontmatter fails to parse is loaded into every
# session as if it had no `paths:`, so the frontmatter shape is checked strictly here.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "test-rules.sh"
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

rules_dir = root / "rules"
rules = sorted(rules_dir.glob("*.md")) if rules_dir.is_dir() else []
check(bool(rules), "rules/ holds rule files", f"{rules_dir} is missing or empty")

# The only frontmatter shape accepted: `paths:` and a list of quoted globs that start with
# `**/`, so they match at any depth below the session's working directory.
ITEM = re.compile(r'^  - "(\*\*/[^"]+)"$')

def parse(path: Path) -> list[str] | None:
    lines = path.read_text().splitlines()
    if len(lines) < 3 or lines[0] != "---" or lines[1] != "paths:":
        return None
    globs = []
    for line in lines[2:]:
        if line == "---":
            return globs or None
        m = ITEM.match(line)
        if not m:
            return None
        globs.append(m.group(1))
    return None

def to_regex(glob: str) -> re.Pattern[str]:
    out, i = "", 0
    while i < len(glob):
        if glob.startswith("**/", i):
            out += "(?:.*/)?"; i += 3
        elif glob.startswith("**", i):
            out += ".*"; i += 2
        elif glob[i] == "*":
            out += "[^/]*"; i += 1
        elif glob[i] == "?":
            out += "[^/]"; i += 1
        elif glob[i] == "{":
            j = glob.index("}", i)
            out += "(?:" + "|".join(re.escape(a) for a in glob[i + 1:j].split(",")) + ")"; i = j + 1
        else:
            out += re.escape(glob[i]); i += 1
    return re.compile(out + r"\Z")

parsed: dict[str, list[str]] = {}
bad_shape = []
for r in rules:
    globs = parse(r)
    if globs is None:
        bad_shape.append(r.name)
    else:
        parsed[r.stem] = globs
check(not bad_shape, "every rule opens with `paths:` and a list of quoted `**/` globs", ", ".join(bad_shape))

try:
    import yaml
    disagree = []
    for r in rules:
        text = r.read_text().split("---")
        try:
            fm = yaml.safe_load(text[1]) if len(text) > 2 else None
        except yaml.YAMLError:  # an unquoted `**` reads as an alias and fails to parse
            fm = None
        if not isinstance(fm, dict) or fm.get("paths") != parsed.get(r.stem):
            disagree.append(r.name)
    check(not disagree, "a YAML parser reads the same globs", ", ".join(disagree))
except ImportError:
    pass

LIMIT = {"markdown": 2048}
big = [f"{r.name} {r.stat().st_size}B" for r in rules if r.stat().st_size > LIMIT.get(r.stem, 1024)]
check(not big, "each rule is under 1KB (Markdown, which carries the prose checklist: 2KB)", ", ".join(big))

def matching(path: str) -> set[str]:
    return {name for name, globs in parsed.items() if any(to_regex(g).match(path) for g in globs)}

# Every file type hooks/skill-gate.py governed, and the rules each should load. Exact sets, so
# a glob that matches too much fails as surely as one that matches too little.
COVER = {
    "src/app.py": {"python"},
    "pkg/api/handler.go": {"golang"},
    "go.mod": {"golang"},
    "web/App.tsx": {"typescript"},
    "lib/util.ts": {"typescript"},
    "bin/run.sh": {"shell"},
    "Dockerfile": {"docker"},
    "services/api/Dockerfile": {"docker"},
    "docker/api.Dockerfile": {"docker"},
    "compose.yaml": {"docker"},
    "deploy/docker-compose.prod.yml": {"docker"},
    "infra/main.tf": {"terraform"},
    "envs/prod.tfvars": {"terraform"},
    "README.md": {"markdown"},
    "docs/guide.mdx": {"markdown"},
    "tests/test_api.py": {"python", "testing"},
    "pkg/api/handler_test.go": {"golang", "testing"},
    "src/a.test.ts": {"typescript", "testing"},
    "tests/test-hooks.sh": {"shell", "testing"},
    ".github/workflows/ci.yml": {"ci"},
    "docs/c4/context.puml": {"diagrams"},
    "docs/decisions/ADR-0001-use-postgres.md": {"markdown", "adr"},
    "src/main.rs": set(),
    "package.json": set(),
}
wrong = [f"{p}: {sorted(matching(p))} != {sorted(want)}" for p, want in COVER.items() if matching(p) != want]
check(not wrong, "each governed file type loads exactly its rules", "; ".join(wrong[:6]))

named = []
for r in rules:
    for s in re.findall(r"`([a-z0-9-]+)` skill", r.read_text()):
        if not (root / "skills" / s / "SKILL.md").is_file():
            named.append(f"{r.name} -> {s}")
check(not named, "every skill a rule names exists", "; ".join(named))

RETIRED = ["python", "typescript", "golang", "docker", "terraform", "markdown-formatting",
           "karpathy-principles"]
left = [s for s in RETIRED if (root / "skills" / s).exists()]
check(not left, "the skills that became rules, and karpathy-principles, are retired", ", ".join(left))
check(not (root / "hooks" / "skill-gate.py").exists(), "hooks/skill-gate.py is retired")

AS_RULE = {"python": "python", "typescript": "typescript", "golang": "golang", "docker": "docker",
           "terraform": "terraform", "markdown-formatting": "markdown"}
unlinked = []
for g, rule in AS_RULE.items():
    p = root / "guidelines" / f"{g}.md"
    if not (p.is_symlink() and p.resolve() == (rules_dir / f"{rule}.md").resolve()):
        unlinked.append(g)
check(not unlinked, "guidelines/<name>.md still resolves, to the rule now", ", ".join(unlinked))
check(not (root / "guidelines" / "karpathy-principles.md").exists() and
      not (root / "guidelines" / "karpathy-principles.md").is_symlink(),
      "guidelines/karpathy-principles.md is gone with its skill")

shell = (rules_dir / "shell.md").read_text() if (rules_dir / "shell.md").exists() else ""
facts = ['mktemp -d "${TMPDIR:-/tmp}/', "wc -l", "grep -c", "command -v jq"]
check(all(f in shell for f in facts), "the shell rule carries the portability facts",
      f"missing: {[f for f in facts if f not in shell]}")
memory = (root / "memory" / "MEMORY.md").read_text()
check("## Shell portability" not in memory, "MEMORY.md no longer carries them in every session")

claude = (root / "CLAUDE.md").read_text()
check("Conventional Commits" in claude and "type(scope): summary" in claude,
      "CLAUDE.md states the commit format the gate used to demand")

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
EOF
