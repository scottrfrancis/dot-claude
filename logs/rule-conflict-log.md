# Runtime Conflict Log

Append-only. Records conflicts between durable instructions and how each was resolved, so a
resolution reached once does not have to be reached again. The procedure, the definition of
a conflict, and the adaptations from the source protocol live in
`guidelines/rule-conflict-protocol.md`. Structure is checked by `bin/check-conflict-log.sh`.

Ids are stable: never reused, never renumbered, never backfilled. Entries are appended in
the order the conflicts occurred. Corrections are new entries citing the earlier id, not
edits to it.

**This file is committed to a public repository.** Record no client names, project
specifics, or pasted user input. Where a conflict cannot be described without them, log it
in the project's own gitignored `session-logs/` and keep only the pointer here.

## Entry format

Fields appear in this order and none is omitted. Verbatim quotes go in blockquotes.

```
**RC<NNN> — <YYYY-MM-DD ~HH:MM TZ> — <name>**

**Kind:** rule | pattern

**Tool:** claude-code | copilot | cursor | droid | opencode

**Trigger:** [what surfaced the conflict — no client or project detail]

**Operation:** [one line: what was about to happen]

**Conflicting rules:**

- From `<file>` § <section>:
  > [verbatim quote]
- From `<file>` § <section>:
  > [verbatim quote]

**Conflict explanation:**
[why both cannot hold for this operation]

**Options presented:**

- (a) [drop or amend one instruction]
- (b) [resolve this request only, rule set unchanged]
- (c) [stop]

**Decision:** [choice and timestamp; left blank while awaiting the user]
```

---

(New entries appended below this separator, in order of occurrence.)
