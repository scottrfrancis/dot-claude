# Glossary Convention

A glossary is a small table of terms that mean something specific here and something else in
general use. Adapted from the glossary mechanism in Anatoly Volkhover's *Agentic
Spec-Driven Development* reference project.

It is a proto-ontology, but the emphasis is on *proto*. The reference project's glossary has
exactly **one row**. That is not an oversight — it is the discipline working.

## Seed it from collisions, not from a template

The failure mode of glossaries is authoring one up front: a page of definitions written
before anything went wrong, which nobody reads and which rots. The alternative is the same
principle the conflict log runs on — **record at the moment of contention**.

A term earns a row when it has actually caused a misunderstanding: a request read two ways,
a file put in the wrong place because two things share a name, an answer that turned out to
be about a different thing. Until then the term is doing fine without a row.

Sources of new entries, in rough order of how often they fire:

- **A misread request.** The most common. Ask, then record what the term meant here.
- **The conflict protocol.** Category C of the guarded-edits check — *vocabulary mismatch*,
  the same content using a term differently from established usage — is a glossary trigger.
  Some apparent rule conflicts turn out to be two people using one word for two things.
- **`/memorialize`.** Closing out a thread is when a term collision is freshest.
- **A review.** This repo's glossary was seeded from a documented audit, not invented.

Do not add a row for a term that is merely technical or unfamiliar. Unfamiliar is what
documentation is for. A glossary row is for terms whose *ordinary* reading is wrong here.

## Format

| Column | Holds |
|---|---|
| **Term** | The term, in backticks. |
| **Meaning** | What it means here, in plain language. |
| **Anti-meanings** | What it explicitly does **not** mean here. Optional but usually the most useful column. |

Anti-meanings are the part that does the work. A definition competes with an entrenched
default reading; naming that default and ruling it out is more effective than describing the
intended sense and hoping it wins.

## The rule that makes it do anything

A glossary nobody consults is decoration. The behaviour that makes it load-bearing is stated
in `CLAUDE.md`, and it is deliberately two-sided:

- When a prompt uses a glossary term, read it per the **Meaning** column.
- Also ask whether another reading is *contextually plausible* in that specific prompt. If it
  is, **ask** before acting. If it is not, proceed without asking.
- When producing content, use the glossary's term for the concept it covers rather than a
  synonym, and avoid the term when meaning something else.

The second point is what keeps this from becoming friction. A glossary that triggers a
clarifying question every time a listed word appears gets ignored within a week.

## Segments

Vocabulary is segmented exactly as memory is, and for the same reason: `deliverable` means
one thing for one client and another elsewhere.

| File | Scope |
|---|---|
| `glossary/GLOSSARY.md` | universal — committed, and **public** |
| `glossary/local/GLOSSARY.md` | personal — gitignored |
| `glossary/local/<segment>/GLOSSARY.md` | one client — gitignored |
| `<project>/.claude/glossary/GLOSSARY.md` | one project |

`bin/memory-scope.sh --kind glossary` resolves which apply. A client's vocabulary is loaded
only when the working context resolves to that client. Client terminology is often the most
identifying thing in a repo — keep it out of the universal file.

## Checks

`bin/check-glossary.sh` runs in CI and verifies that each row is usable: a term defined
once, a meaning that is not empty, and a definition that bottoms out in ordinary language
rather than looping through other entries.

**Not implemented, deliberately:** the source protocol's *closure check*, which requires
every project term inside a definition to itself be a defined entry. At this size that
cascades into defining ordinary English. The circularity check is kept because a definition
that loops genuinely explains nothing.

## Retiring

A term stops earning its row when the collision stops happening — usually because one of the
two meanings fell out of use. Remove the row. Unlike memory facts, a stale glossary entry is
low-harm; the cost of an over-large glossary is that people stop reading it.
