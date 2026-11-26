#!/usr/bin/env python3
"""Read Claude Code session transcripts: token usage for a branch, and usage per session.

Claude Code keeps each session as JSONL in <config dir>/projects/<key>/<session>.jsonl, with
subagents under <session>/subagents/. Assistant records carry cwd, gitBranch, the model and
message.usage, and a streamed reply is several records with one message id, so each id is
counted once. Transcripts last cleanupPeriodDays (the README sets 90).

  transcripts.py tokens [--repo DIR] [--branch B] [--pr N] [--format md|json]
      Tokens for one branch of one repo: records whose gitBranch is B and whose cwd is inside
      a worktree of the repo. --pr N also counts, in full, every session linked to PR N of the
      repo's GitHub remote, which catches work driven from another directory.
  transcripts.py usage [--days N | --since YYYY-MM-DD] [--project DIR] [--format md|json]
      Sessions active in the window, the slash commands typed and the skills Claude invoked,
      each counted once per session, and tokens per project. /mine-sessions reads this.

Transcripts are read from every config dir on the host: ~/.claude, $CLAUDE_CONFIG_DIR,
~/.claude-profiles/*/.claude and ~/.claude-*. Add others with --projects-dir.
TRANSCRIPTS_HOME replaces the login home and ignores $CLAUDE_CONFIG_DIR (a test seam).
"""

from __future__ import annotations

import argparse
import json
import os
import pwd
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path

FIELDS = (("input", "input_tokens"), ("output", "output_tokens"),
          ("cache_write", "cache_creation_input_tokens"), ("cache_read", "cache_read_input_tokens"))
COMMAND = re.compile(r"<command-name>/([A-Za-z0-9:_-]+)</command-name>")


def key(path: str | Path) -> str:
    """The projects/ directory name Claude Code derives from a cwd."""
    return re.sub(r"[^A-Za-z0-9]", "-", str(path))


def projects_dirs(extra: list[str]) -> list[Path]:
    seam = os.environ.get("TRANSCRIPTS_HOME")
    if seam:
        home = Path(seam)
    else:
        try:
            home = Path(pwd.getpwuid(os.getuid()).pw_dir)
        except KeyError:
            home = Path.home()
    cands = [home / ".claude", *sorted(home.glob(".claude-profiles/*/.claude")),
             *sorted(p for p in home.glob(".claude-*") if p.name != ".claude-profiles")]
    if not seam and os.environ.get("CLAUDE_CONFIG_DIR"):
        cands.append(Path(os.environ["CLAUDE_CONFIG_DIR"]))
    out, seen = [], set()
    for c in [*(c / "projects" for c in cands), *map(Path, extra)]:
        try:
            real = c.resolve()
        except OSError:
            continue
        if c.is_dir() and real not in seen:
            seen.add(real)
            out.append(c)
    return out


def records(files: list[Path], needle: str = ""):
    """(file, record) for each JSON line, skipping lines without `needle` before parsing."""
    for f in files:
        try:
            with f.open(encoding="utf-8", errors="replace") as fh:
                for line in fh:
                    if needle and needle not in line:
                        continue
                    try:
                        yield f, json.loads(line)
                    except ValueError:
                        continue
        except OSError:
            continue


def jsonl_under(dirs: list[Path]) -> list[Path]:
    return sorted(p for d in dirs for p in d.rglob("*.jsonl"))


@dataclass
class Tally:
    total: Counter = field(default_factory=Counter)
    models: dict = field(default_factory=lambda: defaultdict(Counter))
    sessions: set = field(default_factory=set)
    seen: set = field(default_factory=set)

    def add(self, rec: dict) -> None:
        msg = rec.get("message") or {}
        usage = msg.get("usage") or {}
        mid = msg.get("id") or rec.get("requestId") or rec.get("uuid")
        if not usage or mid in self.seen:
            return
        self.seen.add(mid)
        self.sessions.add(rec.get("sessionId") or "?")
        model = msg.get("model") or "unknown"
        for name, src in FIELDS:
            n = int(usage.get(src) or 0)
            self.total[name] += n
            self.models[model][name] += n


def git(repo: str, *args: str) -> str:
    try:
        r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, timeout=10)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def worktrees(repo: str) -> list[str]:
    out = [line[9:] for line in git(repo, "worktree", "list", "--porcelain").splitlines()
           if line.startswith("worktree ")]
    top = git(repo, "rev-parse", "--show-toplevel")
    paths = out or ([top] if top else [])
    return sorted({str(Path(p).resolve()) for p in paths} | set(paths))


def github_slug(repo: str) -> str:
    url = git(repo, "remote", "get-url", "origin")
    m = re.search(r"github\.com[:/]+([^/]+/[^/]+?)(?:\.git)?/?$", url)
    return m.group(1) if m else ""


def inside(cwd: str, roots: list[str]) -> bool:
    return any(cwd == r or cwd.startswith(r.rstrip("/") + "/") for r in roots)


def tokens(args: argparse.Namespace) -> dict:
    repo = args.repo or "."
    branch = args.branch or git(repo, "symbolic-ref", "--quiet", "--short", "HEAD")
    if not branch:
        sys.exit("transcripts.py: no branch (detached HEAD?); pass --branch")
    roots = worktrees(repo)
    if not roots:
        sys.exit(f"transcripts.py: {repo} is not a git repository")
    dirs = projects_dirs(args.projects_dir)
    keys = [key(r) for r in roots]
    own = [p for d in dirs for p in d.iterdir()
           if p.is_dir() and any(p.name == k or p.name.startswith(k + "-") for k in keys)]
    tally = Tally()
    for _, rec in records(jsonl_under(own), '"usage"'):
        if rec.get("type") == "assistant" and rec.get("gitBranch") == branch \
                and inside(str(rec.get("cwd") or ""), roots):
            tally.add(rec)

    shared: set[str] = set()
    if args.pr:
        slug = github_slug(repo)
        target = (slug, args.pr)
        linked: dict[str, set] = defaultdict(set)   # session -> {(repo, pr)}, any repo
        files_by_session: dict[str, set] = defaultdict(set)
        for f, rec in records(jsonl_under(dirs), '"pr-link"'):
            if rec.get("type") == "pr-link":
                sid = rec.get("sessionId") or ""
                linked[sid].add((rec.get("prRepository") or "", int(rec.get("prNumber") or 0)))
                files_by_session[sid].add(f)
        for sid, prs in linked.items():
            if target not in prs:
                continue
            if len(prs) > 1:
                shared.add(sid)
            files = {p for f in files_by_session[sid]
                     for p in [f, *sorted((f.parent / f.stem / "subagents").glob("*.jsonl"))]}
            for _, rec in records(sorted(files), '"usage"'):
                if rec.get("type") == "assistant" and rec.get("sessionId") == sid:
                    tally.add(rec)

    return {"repo": roots[0], "branch": branch, "pr": args.pr, "sessions": sorted(tally.sessions),
            "shared": sorted(shared), "total": dict(tally.total),
            "models": {m: dict(c) for m, c in sorted(tally.models.items())}}


def human(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def tokens_md(d: dict) -> str:
    if not d["sessions"]:
        return (f"No Claude Code transcript records for `{d['branch']}` in {d['repo']}. "
                "Records count when a session's working directory is inside a worktree of the "
                "repo on that branch; --pr N also counts sessions linked to the PR.")
    row = lambda name, c: "| " + " | ".join([name] + [human(c.get(f, 0)) for f, _ in FIELDS]) + " |"
    lines = ["<details>", "<summary>AI token usage</summary>", "",
             f"**Branch:** `{d['branch']}`" + (f" (PR #{d['pr']})" if d["pr"] else ""),
             f"**Sessions:** {len(d['sessions'])}", "",
             "| Model | Input | Output | Cache write | Cache read |",
             "| ----- | ----- | ------ | ----------- | ---------- |"]
    lines += [row(m, c) for m, c in d["models"].items()]
    lines.append(row("Total", d["total"]))
    lines.append("")
    if d["shared"]:
        lines.append(f"Sessions that also worked on other PRs, counted in full here: "
                     f"{len(d['shared'])}.")
        lines.append("")
    lines += ["Read from Claude Code transcripts by `bin/transcripts.py`.", "", "</details>"]
    return "\n".join(lines)


def usage(args: argparse.Namespace) -> dict:
    if args.since:
        since = datetime.strptime(args.since, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    else:
        since = datetime.now(timezone.utc) - timedelta(days=args.days)
    cutoff = since.strftime("%Y-%m-%dT%H:%M:%S")
    root = str(Path(args.project).resolve()) if args.project else ""
    active, cmds, skills = set(), defaultdict(set), defaultdict(set)
    per_project: dict[str, Tally] = defaultdict(Tally)
    files = [f for f in jsonl_under(projects_dirs(args.projects_dir))
             if f.stat().st_mtime >= since.timestamp()]   # untouched since: nothing in window
    for _, rec in records(files):
        if rec.get("type") not in ("user", "assistant") or str(rec.get("timestamp") or "") < cutoff:
            continue
        cwd = str(rec.get("cwd") or "")
        if root and not inside(cwd, [root]):
            continue
        sid = rec.get("sessionId") or "?"
        active.add(sid)
        msg = rec.get("message") or {}
        content = msg.get("content")
        if rec["type"] == "user" and not rec.get("isSidechain"):
            text = content if isinstance(content, str) else json.dumps(content)
            for c in COMMAND.findall(text):
                cmds[c].add(sid)
        elif rec["type"] == "assistant":
            per_project[cwd].add(rec)
            for b in content if isinstance(content, list) else []:
                if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Skill":
                    name = str((b.get("input") or {}).get("skill") or "")
                    if name:
                        skills[name].add(sid)
    count = lambda d: dict(sorted(((k, len(v)) for k, v in d.items()), key=lambda kv: (-kv[1], kv[0])))
    return {"since": since.date().isoformat(), "sessions": len(active), "commands": count(cmds),
            "skills": count(skills),
            "projects": {p: {"sessions": len(t.sessions), **dict(t.total)}
                         for p, t in sorted(per_project.items())}}


def usage_md(d: dict) -> str:
    out = [f"Claude Code sessions active since {d['since']}: {d['sessions']}", ""]
    for title, key_ in (("Command typed", "commands"), ("Skill invoked by Claude", "skills")):
        out += [f"| {title} | Sessions |", "| --- | --- |"]
        out += [f"| {k} | {v} |" for k, v in d[key_].items()] or ["| (none) | 0 |"]
        out.append("")
    out += ["| Project directory | Sessions | Output tokens |", "| --- | --- | --- |"]
    out += [f"| {p} | {v['sessions']} | {human(v.get('output', 0))} |" for p, v in d["projects"].items()]
    return "\n".join(out)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("tokens")
    t.add_argument("--repo")
    t.add_argument("--branch")
    t.add_argument("--pr", type=int)
    u = sub.add_parser("usage")
    g = u.add_mutually_exclusive_group()
    g.add_argument("--days", type=int, default=30)
    g.add_argument("--since")
    u.add_argument("--project")
    for p in (t, u):
        p.add_argument("--format", choices=("md", "json"), default="md")
        p.add_argument("--projects-dir", action="append", default=[])
    args = ap.parse_args(argv)
    if args.cmd == "tokens":
        d = tokens(args)
        print(json.dumps(d, indent=2) if args.format == "json" else tokens_md(d))
    else:
        d = usage(args)
        print(json.dumps(d, indent=2) if args.format == "json" else usage_md(d))
    return 0


if __name__ == "__main__":
    sys.exit(main())
