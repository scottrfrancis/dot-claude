#!/usr/bin/env python3
"""PostToolUse hook: check a Markdown write against the mechanical prose rules.

The prose style (skills/prose-style) is always on. Three of its rules are mechanical enough to
check after every Markdown write:

- the dash budget: em-dashes, spaced en-dashes and " -- " together stay within
  max(2, lines // 40) per file;
- the corrective frame ("is not X, it is Y") on lines the write added;
- bold density: at most max(3, lines // 10) bold spans per file.

Only what the write added is judged. An edit to a legacy file that is already over budget is
flagged only if it adds to the problem. Findings go to stderr with exit 2, which returns them
to the model so it can fix the sentences. Any internal error exits 0.

Skipped: non-Markdown files, anything under node_modules, .git or vendor, and any file that
contains the marker "prose-check: off" (the prose-style skill quotes the patterns it bans).
Files written through Bash heredocs never reach this hook.

Register on PostToolUse with matcher "Write|Edit|MultiEdit".
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

MARKDOWN = {".md", ".mdx", ".markdown"}
SKIP_PARTS = {"node_modules", ".git", "vendor"}

DASH = re.compile(r"—| – | -- ")
BOLD = re.compile(r"\*\*[^*\n]+?\*\*|__[^_\n]+?__")
# Requires a negation: without one, the possessive "its" and a plain "It is X, but Y" matched.
FRAME = re.compile(
    r"\b(?:isn['’]t|is not|not)\s+(?:just |only |merely |about )?[^.;:\n]{1,60}?[,;—]\s*"
    r"(?:but |it['’]s |it is |rather )",
    re.IGNORECASE,
)
TABLE_RULE = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$")
INLINE_CODE = re.compile(r"`[^`\n]*`")


def prose_lines(text: str) -> list[tuple[int, str]]:
    """(line number, text) for lines a reader reads as prose, inline code removed."""
    lines = text.split("\n")
    out: list[tuple[int, str]] = []
    in_front = bool(lines) and lines[0].strip() == "---"
    fenced = False
    for n, line in enumerate(lines, 1):
        if in_front:
            if n > 1 and line.strip() == "---":
                in_front = False
            continue
        if line.lstrip().startswith(("```", "~~~")):
            fenced = not fenced
            continue
        if fenced or line.startswith(("    ", "\t")) or TABLE_RULE.match(line):
            continue
        out.append((n, INLINE_CODE.sub("", line)))
    return out


def count(pattern: re.Pattern[str], text: str) -> int:
    return sum(len(pattern.findall(t)) for _, t in prose_lines(text))


def added_text(tool: str, tool_input: dict) -> tuple[str, str]:
    """(old, new) text for what this write replaced and added."""
    if tool == "Write":
        return "", str(tool_input.get("content") or "")
    if tool == "Edit":
        return str(tool_input.get("old_string") or ""), str(tool_input.get("new_string") or "")
    if tool == "MultiEdit":
        edits = tool_input.get("edits") or []
        return ("\n".join(str(e.get("old_string") or "") for e in edits),
                "\n".join(str(e.get("new_string") or "") for e in edits))
    return "", ""


def findings_for(path: Path, tool: str, tool_input: dict) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    if "prose-check: off" in text:
        return []
    old, new = added_text(tool, tool_input)
    total = text.count("\n") + 1
    file_prose = prose_lines(text)
    found: list[str] = []

    dash_budget = max(2, total // 40)
    dash_lines = [n for n, t in file_prose if DASH.search(t)]
    file_dashes = sum(len(DASH.findall(t)) for _, t in file_prose)
    if count(DASH, new) > count(DASH, old) and file_dashes > dash_budget:
        shown = ", ".join(str(n) for n in dash_lines[:8])
        found.append(f"{file_dashes} dashes (em-dash, spaced en-dash, ' -- ') against a budget of "
                     f"{dash_budget} for {total} lines, on lines {shown}. Make each one a period, "
                     "colon or comma unless it is a real interruption")

    old_lines = {t.strip() for _, t in prose_lines(old)}
    frames = [t.strip() for _, t in prose_lines(new) if t.strip() not in old_lines and FRAME.search(t)]
    if frames:
        quoted = " | ".join(f[:90] for f in frames[:3])
        found.append(f"corrective frame on {len(frames)} added line(s): {quoted}. "
                     "Delete the negated half and state the positive")

    bold_budget = max(3, total // 10)
    file_bold = sum(len(BOLD.findall(t)) for _, t in file_prose)
    if count(BOLD, new) > count(BOLD, old) and file_bold > bold_budget:
        found.append(f"{file_bold} bold spans against a budget of {bold_budget} for {total} lines. "
                     "Keep bold for the one claim a section exists to make")
    return found


def main() -> int:
    event = json.loads(sys.stdin.read() or "{}")
    tool = str(event.get("tool_name") or "")
    tool_input = event.get("tool_input") or {}
    path = Path(str(tool_input.get("file_path") or ""))
    if path.suffix.lower() not in MARKDOWN or SKIP_PARTS & set(path.parts) or not path.is_file():
        return 0
    found = findings_for(path, tool, tool_input)
    if not found:
        return 0
    print(f"prose-check ({path.name}): " + "; ".join(found)
          + ". Rules: the prose-style skill. Rewrite the sentence so the move is gone; "
            "swapping punctuation keeps the tell.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # noqa: BLE001 - a broken check must never block work
        sys.exit(0)
