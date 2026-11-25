# Universal memory

Durable, non-obvious facts that hold on every host and every project, and that nothing else in
this repo records. CLAUDE.md imports this file, so every line costs context in every session:
keep it short. Format and rules: `guidelines/memory.md`. Each line ends with the date it was
last verified. `bin/conformance.sh` flags lines older than 180 days.

This repo is public. No personal data, addresses, credentials or client detail.

## Where things live

- Local infrastructure and household facts (hosts, addresses, services, contacts) are never recorded in this repo; read them from the `kb-mcp` MCP, `infra` and `home-ops` bundles. Detail: [infra-ha-control](infra-ha-control.md) [2026-11-25]
- Facts about one project live in that project's built-in memory (`~/.claude/projects/<key>/memory/`), which is per host. A fact that must reach other hosts goes here if it is universal, or to `okf-knowledge` if it is about the ops estate [2026-11-25]

## Claude Code

- Only `@path` imports in CLAUDE.md are loaded into context. A Markdown link there is just text, so anything meant to be in context is imported or made a skill [2026-11-25]
- The global `settings.json` allow list holds broad patterns such as `Bash(git:*)`, never one-off commands; a project's approvals belong in its own `.claude/settings.local.json` [2026-11-25]

## Shell portability

- macOS `/usr/bin/mktemp -d` ignores `$TMPDIR`, so inside the Claude Code sandbox it fails. Pass a template: `mktemp -d "${TMPDIR:-/tmp}/name.XXXXXX"` [2026-11-25]
- BSD `wc -l` pads its count with spaces: compare counts with `-eq`, never `=` [2026-11-25]
- `grep -c` prints `0` and exits 1 when nothing matches, so `$(grep -c x f || echo 0)` yields two lines. Use `n=$(grep -c x f); n=${n:-0}` or `|| true` [2026-11-25]
- Hooks: check `command -v jq` before using jq, and exit 0 without it; a hook must never fail a session [2026-11-25]

## Retired

Facts removed because they were false. Kept briefly so a stale copy elsewhere is recognised.

- ~~`-mmin` is GNU-only~~: macOS `find` supports it [retired 2026-11-25]
- ~~`commands/arch-review` (no ext) is an orphaned bash duplicate needing cleanup~~: the file no longer exists [retired 2026-08-19]
