# Architecture Decision Records (ADRs)

The single canonical ADR convention for this workspace. Every ADR — hand-written,
extracted from a session log (`/extract-adr`), or created via `/adr` — MUST follow it.
This is the format the spec-driven toolkit (`constitution`, `design-review`,
`trace-check`) reads and validates.

## Location & filename

- **Canonical directory:** `docs/decisions/`
- **Filename:** `ADR-NNNN-kebab-slug.md` — zero-padded 4-digit number, then a short
  kebab-case slug. Example: `docs/decisions/ADR-0007-postgres-over-dynamo.md`.
- **Legacy read path:** tools also *read* `docs/adr/` for back-compat, but *write* new
  ADRs to `docs/decisions/`. If a project already uses `docs/adr/`, keep writing there
  for consistency — pick one per project and don't split.

## Numbering

- Sequential from `0001`, never reused, never renumbered — the number is a permanent ID.
- A new ADR takes `max(existing) + 1`. When unsure, `grep -ro 'ADR-[0-9]\{4\}' docs | sort -u | tail -1`.
- Superseding a decision creates a **new** ADR with a new number; it does not edit the old one.

## Status lifecycle

`Proposed` → `Accepted` → (`Deprecated` | `Superseded by ADR-NNNN`) — or `Rejected`.

- **Proposed** — drafted, under discussion.
- **Accepted** — the decision in force. **Once Accepted, an ADR is immutable** except for
  its Status line. Change your mind by writing a new ADR that supersedes it.
- **Superseded by ADR-NNNN** — replaced; link forward to the replacement (which links back).
- **Deprecated** — no longer relevant, not replaced.
- **Rejected** — considered and declined (still recorded — the reasoning is the value).

## Template (use verbatim)

```markdown
# ADR-NNNN: <short imperative title>

- **Status:** Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-NNNN
- **Date:** YYYY-MM-DD
- **Deciders:** <who made the call>
- **Related requirements:** FR-###, FR-###   <!-- traceability; omit if none -->
- **Related ADRs:** ADR-NNNN (supersedes), ADR-NNNN (related)   <!-- omit if none -->

## Context

The forces at play: the problem, constraints, and what makes this decision necessary.
State facts and requirements, not the choice yet. If it traces to a requirement or an
assumption (ASSUMPTIONS-TRACKER A##), name it here.

## Decision

The choice, in active voice: "We will …". One decision per ADR.

## Consequences

What becomes true because of this decision — good and bad, both required:

- **Positive:** what this enables or simplifies.
- **Negative:** what it costs, constrains, or risks.
- **Neutral:** follow-on work, things now locked in.

## Alternatives considered

Each realistic option and the one-line reason it lost. (Rejected ADRs make this the
main body.)
```

## Rules that must hold

- **One decision per ADR.** Two decisions → two ADRs.
- **Immutable once Accepted** — supersede, don't rewrite. History is the point.
- **Consequences are mandatory** and must include the negative ones; an ADR with only
  upside is incomplete.
- **Link into traceability** where the project uses FR-### requirements — an ADR that
  implements or constrains a requirement names it, so `trace-check` can see the link.
- Keep them short. An ADR is a decision record, not a design doc; link out to the design.
