---
name: infra-ha-control
description: Do not record local infrastructure facts in this repo — read them from the LAN-local kb-mcp MCP serving the OKF bundle federation
metadata:
  type: reference
---

**This repo is public. Local infrastructure facts do not belong here** — not hostnames,
addresses, ports, account names, device inventories, or access paths. This file previously
carried a Home Assistant control/access map and has been redacted.

**Read local infrastructure from the `kb-mcp` MCP server**, LAN-local on **mini**. It is a
read-only filesystem MCP over the whole OKF federation, with tools `list_bundles`,
`search`, `read_file`, and `list_dir`. Endpoint and doctrine: `CLAUDE.md` §"Central Ops
Knowledge". Start with `list_bundles`; the registry bundle `knowledge-index` is the
discovery entry point.

- **`infra`** — **the authoritative record for hostnames, addresses, services, networks,
  databases, and the host fleet.** Check here first for what a host or service is and
  *why*, before changing anything. Home Assistant's host and agent-access facts live here
  too, in `hosts.md`.
- **`home-ops`** — household operations: HA automations, equipment, runbooks, emergency
  and howto guides, and credential *pointers* (never secret values).
- Other bundles (`health`, `finance-estate`, `career`, `writing`, isolated `client:*`)
  exist; enumerate rather than assume.

Off-LAN, read the repo checkouts instead. Either way the rule is the same: **consult
before acting on infrastructure, and write findings back to the KB** — not into this repo.
New facts go to `inbox/` as `status: proposed` for triage; don't auto-merge.

Secrets are never in the KB or in memory. It records what a credential unlocks and where
it is kept; retrieve the value from the household password manager.
