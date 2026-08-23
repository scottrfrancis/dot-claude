# Claude Code Project Guidelines

This directory contains consistent guidance for all my projects with Claude Code.

## Branch Policy and Strategy

The user works on multiple projects that have different repositories, policies and strategies.  The user is also forgetful to update the local repository when starting sessions.

REMIND the user to consider the appropriate branching strategy when starting a session or a series of tasks.  This reminder should include

- current branch and status
- suggestions to pull, push, create or delete branches

## Session Safety (CRITICAL)

On NPU/GPU hardware hosts, read `guidelines/session-safety.md` and run session cleanup
before starting. Concurrent sessions cause device contention and context loss requiring a
restart. Does not apply to ordinary development machines.

## Where Things Live

This file is in context on every turn, so it carries behavioral rules only. The annotated
indexes — what each guideline, command, skill and hook is for — live in `README.md`, which
is **not** loaded into context. Keep them there.

**Guidelines** (`~/.claude/guidelines/`) — on-demand standards. Read the relevant one
*before* the matching task; they are not auto-loaded. Filenames are self-describing:

`2x2-status-report` · `C4-diagramming` · `adr` · `ai-cron-tool-delegation` · `ai-patterns` ·
`architecture-diagrams` · `central-ops-knowledge` · `ci-local-parity` ·
`conventional-commits` · `data-diode-list-control` · `docker` · `docx-conversion` ·
`git-workflow` · `glossary` · `golang` · `karpathy-principles` · `markdown-formatting` · `memory` ·
`pr-token-tracking` · `project-setup` · `prose-style` · `prototype-hygiene` · `python` ·
`readme-documentation` ·
`rule-conflict-protocol` · `security-hardening` · `session-safety` · `shell-escaping` ·
`shell-scripts` · `terraform` · `testing` · `typescript`

**Commands** (`~/.claude/commands/`) — invoke as `/<name>`:

`arch-review` · `assumptions` · `autocommit` · `babysit-pr` · `build-pdf` ·
`checkpoint-progress` · `commit-manual` · `constitution` · `design-review` ·
`discovery-init` · `doc-review` · `editorial-review` · `export-prompts` · `extract-adr` ·
`gherkin` · `handoff` · `interview-to-spec` · `lets-go` · `link-sweep` · `memorialize` · `mine-sessions` ·
`pickup` · `pr-tokens` · `punch` · `review-pr` · `security-audit` · `session-cleanup` ·
`session-logger` · `trace-check` · `validate-hw-env`

**Skills** (`~/.claude/skills/<name>/SKILL.md`) — `explain-diff-html` · `explain-diff-md`.

**Hooks** (`~/.claude/hooks/`) — registered in `~/.claude/settings.json`, which is
gitignored, so a fresh clone has the scripts but no registration and they silently never
fire. `conformance-report.sh` (SessionStart) surfaces overdue mining and undecided
conflicts; `/lets-go` runs the same probe directly, so the deliberate path works even
unregistered. `log-session-tokens` is not registered at all, which leaves `/pr-tokens` and
`guidelines/pr-token-tracking.md` inert until it is wired in.

## Precedence

A project's own `CLAUDE.md` extends this file; a project needing an exception to a global
guideline records it in `<project>/.claude/overrides.md`, which wins over the guideline it
names. Where two instruction files both apply, the one closest to the file being edited
wins. Surface the conflict rather than blending the two — see **Global Behavioral Rules**.

## Downstream Repos

**This repo is primary.** `dot-copilot`, `dot-cursor`, `dot-droid`, and `dot-opencode` are
downstream: shared doctrine is authored here and propagated outward. They are never read
back as a source of truth for it.

Shared doctrine lives between HTML-comment markers — `<!-- <block>: begin -->` … `<!-- <block>: end -->`.
Two blocks propagate today: `central-ops-knowledge` and `design-patterns`. Targets are
listed in `doctrine/targets.conf`.

- Edit a shared block **here**, in `CLAUDE.md`, and never in a downstream copy — a
  downstream edit is overwritten on the next sync, silently.
- Run from the workspace holding the sibling checkouts:
  - `dot-claude/bin/doctrine.sh check` — report every downstream block that differs, is
    missing, or has malformed markers. Exits non-zero on any finding.
  - `dot-claude/bin/doctrine.sh sync` — rewrite downstream blocks from this file.
- A block that must legitimately differ downstream records why, inline, next to the
  divergence. Undocumented divergence reads as drift — which is how the ops-knowledge
  block went seven weeks stale in four repos.
- Introducing a block to a new file means adding its marker pair there first; the tool
  refuses to guess placement.

## Repo Checks

Run before pushing (`guidelines/ci-local-parity.md` — these are exactly what CI runs):

```bash
bash tests/test-doctrine.sh                       # test suite
find bin tests -name '*.sh' -print0 | xargs -0 shellcheck --severity=warning
find bin hooks scripts commands tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

## Cross-Tool Session Protocol

Session logs are written to `session-logs/` at the project root — a shared location accessible by Claude Code, Cursor, Copilot, and Droid. Legacy locations (`.claude/session-logs/`, `.factory/logs/`) are searched as fallbacks.

All session logs and handoff files include YAML frontmatter with a `tool:` field (e.g., `tool: claude-code`) so any receiving tool knows the source. This enables cross-tool session continuity — a handoff written in Cursor can be picked up by Claude Code, and vice versa.

## Global Behavioral Rules

- **Red-Green-Refactor TDD is REQUIRED for ALL code changes.** Always write a failing test first (RED), then the minimum production code to pass (GREEN), then refactor with tests green. No production code without a failing test. No retroactive tests. See [Testing Strategies](./guidelines/testing.md) for the full cycle, non-negotiable rules, and the (narrow) exceptions.
- **Durable facts get recorded, dated, segmented, and promoted.** Non-obvious context the
  repo does not already capture goes in memory — one fact per line, ending with the date it
  was last verified. Memory is segmented by client: `bin/memory-scope.sh` resolves which
  files the current context loads, and a client's facts are never loaded for another client.
  File a fact in the narrowest segment that fits. `memory/MEMORY.md` is **public**: never put
  credentials, addresses, hostnames, or personal detail there — point at `kb-mcp`, or use a
  gitignored segment under `memory/local/`. Re-verify or retire a fact rather than letting it stand
  undated: a confidently wrong fact is worse than a missing one. When a fact hardens,
  promote it — to a guideline, an ADR, or the `okf-knowledge` bundle — and leave a pointer.
  See `guidelines/memory.md`.
- **Read glossary terms as the glossary defines them — and ask when another reading fits.**
  `glossary/GLOSSARY.md` and the segments `bin/memory-scope.sh --kind glossary` resolves list
  terms that mean something specific here. When a prompt uses one, take the glossary meaning;
  but where a different reading is genuinely plausible in that prompt's context, ask before
  acting rather than assuming. When writing, use the glossary's term for the concept it
  covers, and avoid it when meaning something else. Add a row only when a term has actually
  caused a misunderstanding. See `guidelines/glossary.md`.
- **Architecture decisions get an ADR.** `guidelines/adr.md` is the single canonical
  convention — `docs/decisions/ADR-NNNN`, sequential numbering, status lifecycle, FR-###
  traceability. Read it before writing, extracting, or reviewing a decision record; do not
  invent a local format. Nine commands depend on it. Local reasoning that does not warrant
  an ADR goes inline, next to what it explains.
- **Surface conflicts; don't average them.** Blending two contradictory patterns produces a
  third nobody intended. When two instructions or two established codebase patterns require
  incompatible things and you cannot satisfy both, **stop before producing anything that
  depends on them**, follow `guidelines/rule-conflict-protocol.md`, and log the conflict to
  `logs/rule-conflict-log.md`. Present the conflicting text verbatim with its sources and at
  least three options, one of which is to stop; do not infer a resolution. Check the log
  first — if the same conflict is already recorded, apply its decision instead of
  re-litigating. Overlap is not conflict: several rules applying to one operation without
  contradicting each other is the normal case.
- Create temporary test scripts and programs in `/tmp`, not in the project directory
- When the user reports a PR has been merged, prompt them to update the local repository (pull, delete merged branch)
- When asked to push to a repo, suggest a new branch if the current branch is the default (main/master)
- **Time tracking** — the local `punch` tool (beaufort time-tool) tracks billable/work time; records accumulate in `~/.beaufort/data/time.db` and sync to hasami via a push agent — `time-push` launchd on macOS, `beaufort-time-push` systemd user timer on Linux (local-first, no runtime SSH). `/lets-go` surfaces any open timer and nudges (advisory) when none is running on project work; `/session-logger` and `/handoff` remind to `/punch stop`. **Remind, never auto-start/stop** — starting a timer posts real billable state. Use `/punch` to drive it. Skip silently on devices where `punch` isn't installed — but **verify before claiming absence**: the old macOS-only `dscl` detection returned empty under a sandbox and reported the tracker missing on a host that had it (2026-08-14). Installed on studio-3 and dev.local; `b` still works as a symlink.

<!-- central-ops-knowledge: begin -->
## Central Ops Knowledge (shared doctrine — all my AI tools)

I maintain ONE central, authoritative **ops-knowledge state** for my homelab/home: **dynamic**
(live, current, queryable by every human and AI on the LAN) and **archival** (durable,
portable, hand-off-able to anyone taking over anything). It lives in the **`okf-knowledge` bundle**
(vault-authoritative `vault:/volume1/gitrepos/okf-knowledge.git`; clones: hasami `~/okf-knowledge`,
Studio `/Volumes/workspace/okf-knowledge`; `wiki/` alongside — infra content promoted from the older
`HomeAssistant/home-ops/` on 2026-07-01), is surfaced
live to agents via the read-only **`kb-mcp` filesystem MCP** (`mini.local:8092`, tools
`search`/`read_file`/`list_dir`; registered in **Hazel**/OpenWebUI and reusable by any MCP
client) and to humans via **`kb-static`** browse (`mini.local:8090`), and kept current by the
`tools/*-scan.sh` self-tracking probes. (Ingesting the bundle into the **Librarian RAG** is on
indefinite hold — the MCP reads markdown live, no re-index.) Full doctrine:
`~/.claude/guidelines/central-ops-knowledge.md`.

Operating rules for every agent (Claude, OpenCode, Codex, Cursor, Droid, Copilot…):
1. **Consult before acting on infrastructure** — before stopping/changing a service, host, or
   config, check the knowledge base for "what is this and *why*." Stale assumptions cause outages.
   On the LAN, query it live via the `kb-mcp` MCP (or read the `okf-knowledge` bundle markdown
   directly — on hasami: `~/okf-knowledge/`, e.g. `infra/`); off-LAN, read the repo checkout.
2. **Write back** — when you learn or change something about the ops state, record or flag it so
   it stays current. Session-only knowledge is lost.
3. **OKF form** — plain markdown + YAML, **no secrets** (pointers only), conformant for any tool.
4. **Local-first / WAN-tolerant** — prefer local LLM/files/Kiwix; must work with the internet down.
5. **Respect boundaries** — household surfaces LAN-only; don't touch non-Scott tailnet hosts.
<!-- central-ops-knowledge: end -->

<!-- design-patterns: begin -->
## Design-pattern discipline

Before designing a non-trivial component, or coining a new mechanism/abstraction:

- **Consult the pattern library first** — the `dot-patterns` corpus (GoF index with house
  stances, personal patterns, vetted mixins). On the LAN: the **patterns MCP** at `mini.local:8093` (search/read_file), or read the
  vault checkout `/Volumes/workspace/dot-patterns` directly. Off-LAN: the installed skills
  / your local `dot-patterns` checkout.
- **Name the pattern you apply** ("this is Strategy" / "the data-diode black/white/gray") in
  your plan and PR so reviewers share the vocabulary.
- **Don't reinvent what the library names.** Reuse an applicable pattern; if you deviate, say why.
- **If you coin something reusable, flag it for capture** rather than letting it evaporate.
- Prefer the GoF house stances (composition over inheritance; Strategy over if-ladders;
  avoid Singleton/Visitor) unless there's a stated reason.
<!-- design-patterns: end -->
