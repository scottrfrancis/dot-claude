# Central Ops Knowledge — doctrine (canonical)

The vision, stated by Scott: **build up a central, authoritative ops-knowledge state that is
usable dynamically by all the humans and AIs on the LAN, as well as anyone taking over
anything. Dynamic, but archival.**

This is the single source of truth for that doctrine. Every AI tool's global instructions
(`~/.claude/CLAUDE.md`, the `dot-*` repos' `CLAUDE.md`/`AGENTS.md`) carry a short pointer
block to it.

## What it is

| Property | Meaning |
|----------|---------|
| **Central** | One knowledge base, not scattered across heads, configs, and chat logs. |
| **Authoritative** | The place you trust for "what is this and *why*." |
| **Dynamic** | Live and current — queryable in real time by any human or AI on the LAN, and kept fresh by self-tracking probes. |
| **Archival** | Durable, portable, hand-off-able to anyone taking over any subsystem (succession is one mode). |

## Where it lives

- **Knowledge base:** the **HomeAssistant repo** — `/Volumes/workspace/HomeAssistant/`:
  the **`successor-bundle/`** (OKF v0.1 bundle) + **`wiki/`** (Karpathy wiki).
- **Dynamic access:** the **Librarian RAG** (pgvector @ vault:5433, Ollama @ dev-ai) with
  **Hazel** (OpenWebUI on `mini.local`) as the household front-end. One corpus.
- **Stays current via:** the `tools/*-scan.sh` self-tracking probes (network, resilience,
  equipment, automations) — run weekly on `mini`.

## Operating rules for every agent (Claude, OpenCode, Codex, Cursor, Droid, Copilot…)

1. **Consult before you act on infrastructure.** Before stopping, changing, or "cleaning up"
   a service, host, container, or config, check the knowledge base for **what it is and
   *why*.** Stale assumptions cause outages.
   - *Cautionary tale (2026-06-19):* an agent disabled the "Gonkulator" MCP stack on `mini`
     on stale "client project concluded" intent — while it was live for a hasami project.
     The knowledge to prevent that belongs here, consulted first.
2. **Write back.** When you learn or change something about the ops state, **record it (or
   flag it)** in the knowledge base so it stays current. Session-only knowledge is lost.
3. **OKF form.** Plain markdown + YAML frontmatter, **secrets-never** (pointers only),
   conformant so any tool/agent or human can read it.
4. **Local-first / WAN-tolerant.** Prefer local LLM/files/Kiwix; the knowledge and the
   assistant must work with the internet down and subscriptions lapsed.
5. **Respect boundaries.** Household/help surfaces stay **LAN-only**; don't touch non-Scott
   tailnet hosts (e.g. Alice's Mac) without asking.
