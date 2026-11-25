# Homelab doctrine

Rules that depend on Scott's homelab: Studio, razer, hasami and dev.local. Each of those hosts
imports this file from its gitignored `~/.claude/host.md`. A host outside the homelab, such as a
client laptop, does not import it, and none of this applies there.

## Environments and the LLM spend gate

- `dev-ai.local` is the LLM for all smoke and functional tests. Use Bedrock, the Anthropic API
  or any other paid model only when Scott asks for it. Test functionality, not output quality:
  a local model's weak prose is not a finding. Detail: `guidelines/environments-and-llm-spend.md`.
- Work happens on Studio, sometimes razer. `dev.local` is both dev and staging, and testing and
  evaluation happen there. Promote to prod only when Scott asks; a green `dev.local` run is not
  that request.

## Time tracking

The local `punch` tool records billable time in `~/.beaufort/data/time.db`, which a push agent
syncs to hasami (`time-push` under launchd on macOS, `beaufort-time-push` as a systemd user timer
on Linux). Remind Scott about timers and never start or stop one yourself, because a timer posts
real billable state. `/punch` drives it, and the session-start status reports an open timer.
Before saying `punch` is absent, check `command -v punch`: inside the Claude Code sandbox it
cannot open its database, which looks like absence and is not.

## Action items

Project agents announce Scott's open action items to Beaufort with `todo_add` on the `beaufort`
MCP, and keep them current with `todo_update` and `todo_close`. Send the headline, a summary and
a link; the project keeps the details. Detail: `guidelines/beaufort-todo-announcements.md`.

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
