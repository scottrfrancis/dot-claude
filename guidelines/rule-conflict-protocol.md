# Runtime Conflict Protocol

What to do when two durable instructions require incompatible things and you cannot satisfy
both. Adapted from the conflict protocol in Anatoly Volkhover's *Agentic Spec-Driven
Development* reference project; the adaptations are noted at the end.

The point is not ceremony. It is that a resolution reached once should not have to be
reached again. Without a log, "pick one and flag the other for cleanup" loses the flag the
moment the session ends, and the same argument runs again next month.

## What counts

A **conflict** exists when two or more durable instructions require incompatible behavior
for the operation in hand, and satisfying one means violating the other.

Two kinds, both logged:

- `rule` — two instructions contradict. A guideline against `CLAUDE.md`, a project
  `overrides.md` against a global guideline, two guidelines pointing opposite ways.
- `pattern` — two established patterns in a codebase contradict, and the code must pick
  one. Two error-handling styles, two test idioms, two competing abstractions.

**Overlap is not conflict.** Several rules applying to one operation without contradicting
each other is the normal case and MUST NOT trigger this protocol. A protocol that fires on
every overlap gets ignored, which costs more than not having it.

**One-off ambiguity is not conflict.** If the instructions are merely unclear, ask.

**A vocabulary mismatch is a glossary trigger.** When two instructions appear to contradict
but are in fact using one word for two things, the fix is a glossary row, not a dropped
rule. Record it per `guidelines/glossary.md` and log the conflict as resolved by
disambiguation, citing the term.

## Procedure

### 1. Stop

Stop before producing or modifying anything that depends on the conflicting instructions.
Do not decide first and explain afterwards — the explanation is worth far less once the
work is already done in one direction.

### 2. Log

Append an entry to `logs/rule-conflict-log.md` in the template's format, with the next
sequential `RC###` id. Ids are stable: never reused, never renumbered, never backfilled.
Writing this entry is itself exempt from the protocol.

Run `bin/check-conflict-log.sh` afterwards; it validates ids and required fields.

### 3. Present

Show the user:

- Each conflicting instruction, quoted verbatim, with its source file and section.
- The operation that surfaced it.
- Why both cannot hold for this operation.
- **At least three options**, one of which is always to stop. Typically: drop or amend one
  instruction; resolve just this once without changing the rule set; stop.

Then ask, and wait. Do not infer the answer, silently prefer one instruction, or resolve by
guessing intent.

### 4. Record the decision

Fill the entry's `Decision:` line with the choice and its timestamp.

- Changing an instruction is a rule edit — the change goes through review like any other,
  and the entry is the rationale for it.
- A one-off resolution applies to that request only. Do not generalize it into a new rule
  unless explicitly told to.
- On stop, halt and produce nothing further.

## Before opening a new entry

Read the existing log. If the same conflict is already recorded, cite that entry and apply
its decision rather than re-litigating — that reuse is the whole return on keeping the log.
If the decision no longer fits, open a new entry that references the old id by number.

## Adaptations from the source protocol

- **No verbatim user input.** The source logs the triggering input word for word; it lives
  in a private repo. This repo is public, so entries record a `Trigger` — enough to
  understand what surfaced the conflict — with no client names, project specifics, or
  pasted content. When a conflict cannot be described without such detail, log it in the
  project's own `session-logs/`, which is gitignored, and record only the pointer here.
- **A `Tool` field.** The source had one agent. These instructions are shared across Claude
  Code, Copilot, Cursor, Droid, and OpenCode, and the same contradiction will surface in
  each. Recording which tool hit it shows whether a conflict is general or tool-specific.
- **A `Kind` field.** The source covers rule conflicts only. `pattern` extends the same
  discipline to the contradicting-codebase-patterns case, which was already a global rule
  here but had nowhere to persist its resolution.
- **No approval gate on logging.** The source requires explicit approval before recording.
  Log first, then present: an append-only record of a conflict is not a change to the rule
  set, and pausing to ask permission to write it discards the entry if the session dies.
