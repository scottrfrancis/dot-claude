#!/usr/bin/env python3
"""PreToolUse hook: hold the first governed write until its skill is loaded.

Topic guidelines are skills, and Claude Code loads a skill when its description matches the
work. That is likely, not guaranteed, and Scott's requirement is that a guideline he wrote is
used by default. So the first Write/Edit of a governed file type, or the first git commit or
push, in a session is held (exit 2, reason on stderr) until the governing skill has been
loaded through the Skill tool or by reading its SKILL.md.

It asks at most twice per skill per session, so it can delay a write but never loop. Skills
that do not exist on disk are never demanded. Topic skills with no file type (security
hardening, AI patterns, architecture diagrams) still rely on their descriptions.

Opt out with CLAUDE_SKILL_GATE=off, or a .claude/skill-gate-off file in the project.
State lives in $TMPDIR/claude-skill-gate/<session_id>/. Any internal error exits 0.

Register on PreToolUse with matcher "Write|Edit|MultiEdit|Bash|Read|Skill".
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
from pathlib import Path

MAX_ASKS = 2
SKILLS_DIR = Path(os.environ.get("SKILL_GATE_SKILLS_DIR") or Path(__file__).resolve().parent.parent / "skills")

# (pattern on the path, skills it needs). Every matching rule applies.
PATH_RULES: list[tuple[re.Pattern[str], tuple[str, ...]]] = [
    (re.compile(r"\.py$"), ("python",)),
    (re.compile(r"\.go$"), ("golang",)),
    (re.compile(r"\.(ts|tsx|mts|cts)$"), ("typescript",)),
    (re.compile(r"\.(sh|bash)$"), ("shell-scripts",)),
    (re.compile(r"(^|/)(Dockerfile[^/]*|[^/]+\.dockerfile|(docker-)?compose[^/]*\.ya?ml)$"), ("docker",)),
    (re.compile(r"\.(tf|tfvars)$"), ("terraform",)),
    (re.compile(r"\.(md|mdx|markdown)$"), ("prose-style", "markdown-formatting")),
    (re.compile(r"(^|/)(test_[^/]*\.py|[^/]*_test\.(py|go)|[^/]*\.(test|spec)\.[jt]sx?)$|(^|/)(tests|__tests__)/"),
     ("testing",)),
    (re.compile(r"(^|/)\.github/workflows/"), ("ci-local-parity",)),
    (re.compile(r"\.(puml|plantuml|iuml)$"), ("c4-diagramming",)),
    (re.compile(r"(^|/)ADR-\d+[^/]*$|(^|/)docs/decisions/"), ("adr",)),
]

GIT = r"\bgit\s+(?:-C\s+\S+\s+)?"
BASH_RULES: list[tuple[re.Pattern[str], tuple[str, ...]]] = [
    (re.compile(GIT + r"commit\b"), ("conventional-commits", "git-workflow")),
    (re.compile(GIT + r"(?:push\b|checkout\s+-b\b|switch\s+-c\b)"), ("git-workflow",)),
]


def state_dir(session_id: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9_-]", "_", session_id) or "unknown"
    d = Path(os.environ.get("TMPDIR") or tempfile.gettempdir()) / "claude-skill-gate" / safe
    d.mkdir(parents=True, exist_ok=True)
    return d


def mark_loaded(state: Path, skill: str) -> None:
    (state / f"{skill}.loaded").touch()


def skill_from_read(path: str) -> str | None:
    """The skill name if this Read opened a SKILL.md, following symlinks."""
    try:
        p = Path(path).resolve()
    except OSError:
        return None
    if p.name == "SKILL.md" and p.parent.parent.name == "skills":
        return p.parent.name
    return None


def needed_for(tool: str, tool_input: dict) -> list[str]:
    needed: list[str] = []
    if tool in ("Write", "Edit", "MultiEdit"):
        path = str(tool_input.get("file_path") or "")
        for pattern, skills in PATH_RULES:
            if pattern.search(path):
                needed.extend(skills)
    elif tool == "Bash":
        command = str(tool_input.get("command") or "")
        for pattern, skills in BASH_RULES:
            if pattern.search(command):
                needed.extend(skills)
    return list(dict.fromkeys(needed))


def opted_out(cwd: str) -> bool:
    if os.environ.get("CLAUDE_SKILL_GATE", "").lower() in ("off", "0", "false", "no"):
        return True
    here = Path(cwd or ".").resolve()
    for d in (here, *here.parents):
        if (d / ".claude" / "skill-gate-off").exists():
            return True
    return False


def main() -> int:
    event = json.loads(sys.stdin.read() or "{}")
    tool = str(event.get("tool_name") or "")
    tool_input = event.get("tool_input") or {}
    state = state_dir(str(event.get("session_id") or ""))

    if tool == "Skill":
        name = str(tool_input.get("skill") or "").split(":")[-1].strip()
        if name:
            mark_loaded(state, name)
        return 0
    if tool == "Read":
        name = skill_from_read(str(tool_input.get("file_path") or ""))
        if name:
            mark_loaded(state, name)
        return 0
    if opted_out(str(event.get("cwd") or "")):
        return 0

    ask: list[str] = []
    for skill in needed_for(tool, tool_input):
        if not (SKILLS_DIR / skill / "SKILL.md").is_file():
            continue
        if (state / f"{skill}.loaded").exists():
            continue
        asks_file = state / f"{skill}.asks"
        asks = int(asks_file.read_text() or 0) if asks_file.exists() else 0
        if asks >= MAX_ASKS:
            continue
        asks_file.write_text(str(asks + 1))
        ask.append(skill)

    if not ask:
        return 0
    how = "; ".join(f"{s} (Skill tool, or Read {SKILLS_DIR / s / 'SKILL.md'})" for s in ask)
    print(f"skill-gate: load the governing skill(s) first, then retry: {how}. "
          f"Asked at most {MAX_ASKS} times per session; CLAUDE_SKILL_GATE=off disables.",
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # noqa: BLE001 - a broken gate must never block work
        sys.exit(0)
