# Agent-Spec Alignment Review — the five dot-* config repos

**Date:** 2026-08-18
**Scope:** `dot-claude`, `dot-copilot`, `dot-cursor`, `dot-droid`, `dot-opencode`
**Status:** review only — no config files changed by this document.

> **Update (2026-08-19):** the intended source was **`agentic-spec.com`** — Volkhover's
> *Agentic Spec-Driven Development* — not `agent-spec.com`. Its full project archive was
> supplied directly and is reviewed against in **Part II**, which is the substantive half
> of this document. Part I below remains valid as a format and consistency audit; read it
> as the evidence Part II explains.

## Read this first: the originally-named source was unreachable

`agent-spec.com` is **blocked by this session's egress proxy** (`CONNECT tunnel
failed, response 403`). Per the proxy runbook a 403 is an organization policy
denial, not a transient error, so it was not retried or routed around.

Two things are worth knowing before acting on the request:

- Search indexing shows the site titled **"agent-spec [PRE ALPHA IDEATION]"** and
  its body marked **"UNDER MAINTENANCE"**. Only two pages are indexed (`/` and
  `/guide/`).
- The indexed description is a **standardized protocol for agent-to-agent
  communication and interoperability** — message patterns, authentication,
  coordination between agents. That is a different layer from what these five
  repos are: *agent instruction and configuration files*. There is no evidence
  it specifies `AGENTS.md`, `SKILL.md`, rule files, or slash commands at all.

So the review below is run against the specs that actually govern these files —
the **AGENTS.md open format**, the **Agent Skills / `SKILL.md`** convention, and
each vendor's own frontmatter contract (Copilot `applyTo`, Cursor `.mdc`, Claude
Code slash-command frontmatter). If `agent-spec.com` was meant literally, paste
its contents and this review can be re-run against them; if the intended target
was `agents.md` or the Agent Skills spec, this *is* that review.

---

## Summary of findings

| # | Finding | Kind | Repos affected | Priority |
|---|---|---|---|---|
| A1 | No canonical `AGENTS.md`; five hand-synced instruction files instead | Inclusion | all but `dot-opencode` | High |
| A2 | Shared doctrine sits in repo-meta `CLAUDE.md`, never reaches the shipped deliverable | Replacement | copilot, cursor, droid | High |
| A3 | Design-pattern discipline exists in exactly one file, in no deliverable | Inclusion | all | Medium |
| B1 | Central-ops doctrine block ~7 weeks stale in 4 of 5 repos | Replacement | copilot, cursor, droid, opencode | High |
| B2 | `dot-claude` version history out of chronological order | Redaction | claude | Low |
| C1 | `pr-token-tracking.instructions.md` has Skill frontmatter, no `applyTo` — never fires | Replacement | copilot | High |
| C2 | `security-audit.md` description is the placeholder string `security-audit` | Replacement | opencode | Medium |
| C3 | 7 SDLC **commands** shipped in the Cursor **rules** slot with no `globs`/`alwaysApply` | Replacement | cursor | High |
| C4 | Skill `description` fields split into two incompatible styles; ~20 can't auto-fire | Replacement | droid (+claude) | High |
| C5 | 9 of 24 slash commands have no frontmatter; two cite non-existent tool names | Replacement | claude | Medium |
| D1 | Always-loaded `CLAUDE.md` is 19.5 KB, ~60% of it a catalogue | Redaction | claude | High |
| D2 | Hardware session-safety marked CRITICAL and always loaded, applies to few projects | Redaction | claude, copilot, opencode | Medium |
| D3 | "Standalone, no `~/.claude/` dependency" contradicted by a `~/.claude/` pointer | Redaction | copilot, cursor | Low |
| E1 | No doctrine-sync tooling in 2 of 5 repos, no drift check in any | Inclusion | all | High |
| E2 | No repo has CI; only `dot-opencode` has a validator, and it only parses JSONC | Inclusion | all | High |
| E3 | "README is not loaded into context" convention stated in only one repo | Inclusion | all but opencode | Medium |
| E4 | No build/test/lint commands in any shipped instruction file | Inclusion | all | Medium |
| E5 | Nested-file precedence rule undocumented | Inclusion | all | Low |

---

## A. Structural alignment

### A1 — Make `AGENTS.md` canonical; demote `CLAUDE.md` to a pointer *(inclusion)*

`AGENTS.md` is the format 30+ agents read, including Codex, Copilot, Cursor,
Gemini CLI, Jules, Factory, Aider, Zed and Windsurf. Today only `dot-opencode`
ships one. The other four each maintain a differently-worded instruction file
with substantially overlapping content:

```
dot-claude/CLAUDE.md                          231 lines  19,560 bytes
dot-cursor/CLAUDE.md                          100 lines   6,426 bytes
dot-opencode/AGENTS.md                        106 lines   6,201 bytes
dot-droid/CLAUDE.md                            69 lines   4,546 bytes
dot-copilot/copilot/copilot-instructions.md    71 lines   4,464 bytes
dot-copilot/CLAUDE.md                          66 lines   4,128 bytes
```

Five sources of truth for one set of rules is why findings B1 and A2 exist.

**Recommend:** in each repo, `AGENTS.md` becomes the single authored file, and
`CLAUDE.md` becomes either a symlink or a one-line import (`@AGENTS.md`). The
vendor-specific deliverable (`copilot-instructions.md`, `.cursor/rules/`,
`.factory/skills/`) is then *generated* from it rather than hand-maintained.
`dot-cursor/templates/AGENTS.md.template` already shows the intended shape — the
gap is that the repos don't eat their own dog food.

### A2 — Shared doctrine never reaches the shipped deliverable *(replacement)*

The Central Ops Knowledge block is present in `dot-copilot/CLAUDE.md`,
`dot-cursor/CLAUDE.md` and `dot-droid/CLAUDE.md` — but those files instruct an
agent **working on the dotfiles repo**. They are not installed anywhere. Checking
what actually ships:

| Repo | Deliverable | Carries the doctrine? |
|---|---|---|
| dot-opencode | `AGENTS.md` | yes |
| dot-copilot | `copilot/copilot-instructions.md` | **no** |
| dot-cursor | `templates/AGENTS.md.template` | **no** |
| dot-droid | `.factory/skills/`, `.factory/droids/` | **no** |

So `dot-claude/CLAUDE.md:53` — "Propagated to all AI tools" — is false for
Copilot, Cursor, and Droid users. Every project installing those configs is
missing consult-before-acting and write-back.

**Recommend:** move the marker-delimited block out of each repo's meta
`CLAUDE.md` and into the file that actually installs. Keep the meta copy only if
editing the repo genuinely needs it.

### A3 — Design-pattern discipline is orphaned *(inclusion)*

`grep -rl "dot-patterns"` across all five repos returns exactly one file:
`dot-claude/CLAUDE.md`. The section instructs agents to consult the pattern
library before designing a component and to name the pattern in plans and PRs.
It reaches no other tool and no deliverable.

**Recommend:** wrap it in `<!-- design-patterns: begin/end -->` markers like the
ops block, and propagate it into all five deliverables via the sync tool in E1.

---

## B. Stale content

### B1 — The central-ops block points four tools at a moved repository *(replacement)*

`dot-claude` records that infra content was **promoted out of
`HomeAssistant/home-ops/` into the `okf-knowledge` bundle on 2026-07-01**, with
the vault as authority and clones on hasami and Studio. The other four repos
still carry the pre-move text:

> It lives in the **HomeAssistant repo** (`/Volumes/workspace/HomeAssistant/` → `home-ops/` OKF bundle + `wiki/`)

Present in `dot-copilot/CLAUDE.md:49`, `dot-cursor/CLAUDE.md:83`,
`dot-droid/CLAUDE.md:52`, `dot-opencode/AGENTS.md:89`. Those four also lack the
current rule 1, which tells an agent how to reach the KB on-LAN via `kb-mcp`
versus off-LAN from a checkout — precisely the sentence that makes the doctrine
actionable when the MCP isn't reachable.

**Recommend:** replace the block verbatim in all four with `dot-claude`'s current
text. This is a copy-paste, and E1 exists so it doesn't happen again.

### B2 — Version history is out of order *(redaction)*

`dot-claude/CLAUDE.md` lists `2026-08-13` before `2026-06-30` in its final
section. The section also duplicates what `git log` already holds, in a file
loaded on every turn.

**Recommend:** delete the Version History section. `guidelines/prototype-hygiene.md`
already argues for stable docs over stale state; git is the history.

---

## C. Frontmatter defects

### C1 — A Copilot instruction that Copilot will never apply *(replacement)*

`dot-copilot/copilot/instructions/pr-token-tracking.instructions.md`:

```yaml
---
name: pr-token-tracking
description: Include AI token usage in PR descriptions. Use when creating or updating pull requests.
---
```

That is Agent-Skill frontmatter in a Copilot instructions file. It is the only
one of 27 instruction files with **no `applyTo:`** — a conversion that was never
finished. Copilot keys auto-application off `applyTo`, so this rule is inert.

**Recommend:**

```yaml
---
applyTo: "**"
description: Include AI token usage in PR descriptions, read from the branch-keyed ledger
---
```

Worth noting the rule it encodes is *already* inert upstream: `dot-claude/CLAUDE.md`
records that `hooks/log-session-tokens` — the ledger writer — is not registered in
`settings.json`. Fixing the frontmatter without wiring the hook just makes an
agent look for a ledger that no one writes.

### C2 — Placeholder description *(replacement)*

`dot-opencode/commands/security-audit.md` has `description: security-audit`. It
is the only command in the repo whose description restates its filename.

**Recommend:** `description: Breach-driven security audit for web applications` —
matching the text `dot-claude/CLAUDE.md` already uses for the same command.

### C3 — Commands shipped as rules *(replacement)*

Seven `dot-cursor/templates/*.mdc` files have neither `globs` nor `alwaysApply`:
`assumptions`, `constitution`, `design-review`, `discovery-init`, `gherkin`,
`interview-to-spec`, `trace-check`. Without either field, Cursor cannot decide
when to attach them.

All seven are *commands* — user-invoked procedures — pushed into the *rules*
slot during the SDLC harvest. `dot-opencode` and `dot-claude` correctly ship the
same seven as commands, and `dot-cursor` already has a `.cursor/commands/`
directory holding `explain-diff-html` and `explain-diff-md`.

**Recommend:** move all seven to `.cursor/commands/`. Reserve `templates/*.mdc`
for genuine standards that carry `globs` or `alwaysApply: true`. Then reconcile
`docs/concept-mapping.md`, which currently maps commands to Cursor agents.

### C4 — Two incompatible skill-description styles *(replacement)*

`dot-droid/.factory/skills/` splits cleanly in two:

*Topic-label style (~20 skills)* — `C4-diagramming`, `ai-patterns`,
`ci-local-parity`, `conventional-commits`, `docker`, `docx-conversion`,
`git-workflow`, `golang`, `karpathy-principles`, `markdown-formatting`, `md2pdf`,
`project-setup`, `prose-style`, `prototype-hygiene`, `python`,
`readme-documentation`, `security-hardening`, `session-safety`, `shell-escaping`,
`shell-scripts`, `terraform`, `testing`, `typescript`:

```yaml
description: "C4 Model PlantUML organization for architecture diagrams"
```

*Trigger style (~6 skills)* — `adr`, `assumptions`, `constitution`, `gherkin`,
`pr-token-tracking`, `explain-diff-html`, `explain-diff-md`:

```yaml
description: >
  The canonical Architecture Decision Record convention — location, numbering,
  status lifecycle, and template. Use when writing, extracting, or reviewing an
  ADR so every decision record has the same shape.
```

`description` is the **only** field the model sees when deciding whether to load
a skill. A noun phrase with no trigger gives it nothing to match against, so the
first group effectively never auto-fires; it only works if a human names it. The
same split exists in `dot-claude` between `skills/` (trigger style) and the
`guidelines/` index entries (label style).

This is the "surface conflicts; don't average them" rule applying to the repos
themselves — two idioms, pick one. The trigger style is the more recent and the
one the spec is built around.

**Recommend:** rewrite every skill description as *`<what it does>. Use when
<concrete trigger>.`* Quoting style should settle too — half use `"quoted"`, half
bare, half block scalars.

### C5 — Slash-command frontmatter gaps *(replacement)*

In `dot-claude/commands/`, 9 of 24 have **no frontmatter at all**: `assumptions`,
`constitution`, `design-review`, `discovery-init`, `gherkin`, `interview-to-spec`,
`link-sweep`, `security-audit`, `trace-check` — again the SDLC harvest. They ship
no `description` (so `/help` shows nothing) and no `allowed-tools`.

Two further problems in the ones that *do* have frontmatter:

- **Non-existent tool names.** `lets-go.md` declares
  `allowed-tools: Write, Bash, Read, LS, Grep, Glob, TodoWrite, Git, Gh` and
  `doc-review.md` declares `..., Write, Edit, Git`. `Git` and `Gh` are not Claude
  Code tools; git and `gh` run through `Bash`. Unrecognized names are ignored, so
  these commands are quietly running with a narrower grant than intended.
- **Two YAML styles.** `arch-review`, `babysit-pr` and `review-pr` use
  `allowed-tools: ["Bash", "Read"]`; every other command uses the bare comma
  form. Pick the bare form — it's the documented one and the majority here.

---

## D. Redactions

### D1 — `dot-claude/CLAUDE.md` is a 19.5 KB catalogue loaded on every turn

231 lines, of which roughly 140 are index entries: 29 guidelines, 24 commands,
5 hooks, 2 skills, plus a version history — each with a one-line annotation. That
is ~4–5k tokens re-sent on every turn in every project, to describe files the
model can list on demand and must open anyway to use.

`dot-opencode/AGENTS.md` already states the correct principle and should be the
model:

> Kept deliberately lean — this file is in context on every turn, so it carries
> only behavioral rules and pointers. Reference detail (the full command and
> guideline indexes …) lives in `README.md`, which is **not** loaded into context.

**Recommend:** cut the annotated indexes down to bare topic lists (as
`dot-opencode` does), move every annotation into `README.md`, and keep only
behavioral rules, branch policy, cross-tool protocol, and the two doctrine blocks
in the always-loaded file. Target under 100 lines.

### D2 — Hardware session-safety is CRITICAL-tagged and always loaded

`Session Safety (CRITICAL)` gets a top-level section in `dot-claude/CLAUDE.md`,
`dot-copilot/copilot-instructions.md` and `dot-opencode/AGENTS.md`, but it only
applies to NPU/GPU development hosts. On every other project it is priority noise,
and its CRITICAL tag competes with the rules that always apply.

**Recommend:** reduce to one conditional line pointing at the guideline —
"On NPU/GPU hardware hosts, read `session-safety` before starting; concurrent
sessions cause device contention." Let the guideline carry the detail.

### D3 — "Standalone" claim contradicted three paragraphs later

`dot-copilot/CLAUDE.md` states the repo "**does not require Claude Code, a local
`dot-claude` checkout, or `~/.claude/` to be installed** — at authoring time or
runtime." `dot-cursor/CLAUDE.md` makes the same claim. Both then close the
central-ops block with:

> Full doctrine: `~/.claude/guidelines/central-ops-knowledge.md`.

**Recommend:** in those two repos, point at the in-repo copy, or drop the pointer.
An agent that believes the standalone claim will not look there anyway.

---

## E. Inclusions

### E1 — Marker-block sync tool and a drift check

`dot-cursor/bin/sync-from-dot-claude.sh` and `dot-droid/bin/sync-from-dot-claude.sh`
exist; `dot-copilot` and `dot-opencode` have nothing, and `dot-copilot/CLAUDE.md`
explicitly forbids treating any repo as upstream. So doctrine propagates by hand
across five repos, which is exactly how B1 and A2 happened.

**Recommend:** one script that rewrites content between named markers
(`central-ops-knowledge`, `design-patterns`) into each repo's deliverable, plus a
`--check` mode that exits non-zero on divergence. Cheap, and it turns a silent
7-week drift into a failing check.

### E2 — CI, and a frontmatter validator

None of the five repos has `.github/workflows/`. The only validation anywhere is
`dot-opencode/scripts/validate.sh`, which checks that JSONC parses — nothing
checks the markdown these repos exist to ship. Every defect in section C is
mechanically detectable:

- frontmatter present and parseable on every `SKILL.md`, `*.instructions.md`,
  `*.mdc`, and command file;
- required key per file type (`applyTo` for Copilot, `globs` or `alwaysApply` for
  Cursor `.mdc`, `name` + `description` for skills);
- `description` non-empty and not equal to the filename (catches C2);
- `allowed-tools` entries drawn from the real tool list (catches C5);
- doctrine markers byte-identical across repos (catches B1).

This is doubly worth flagging because `guidelines/ci-local-parity.md` and
`guidelines/testing.md` require exactly this discipline of every *other* project.
The repos that publish the rule don't run it.

### E3 — State the "README is not loaded" convention everywhere

Only `dot-opencode/AGENTS.md` says it. Without the sentence, the next edit
re-grows the catalogue in the always-loaded file — which is how D1 happened.

### E4 — Build/test/lint commands in the instruction file

The AGENTS.md convention expects the file to tell an agent how to build, test,
and lint. None of the five deliverables does; `dot-cursor/templates/AGENTS.md.template`
has a `Common Tasks` heading with `(command)` placeholders. For these repos the
real answers exist — `bash -n`/`shellcheck` on `install.sh` and `bin/*`,
`scripts/validate.sh` in `dot-opencode`, and the validator from E2.

### E5 — Document nested-file precedence

Agents walk up the tree and merge every `AGENTS.md` they find, closest file
winning on conflict. None of the five states this, and `dot-opencode/AGENTS.md`
is the only one that even mentions per-project files extending the base. Worth one
line in each, since these configs are explicitly designed to be extended per project.

---

## Suggested order of work

1. **B1** — replace the four stale doctrine blocks (copy-paste, removes an active
   wrong answer).
2. **C1, C2** — two frontmatter fixes that make dead config live.
3. **E1** — the sync + `--check` tool, so B1 cannot recur.
4. **C3, C4, C5** — frontmatter normalization, mechanical and independent.
5. **D1, D2, B2** — trim the always-loaded file; measure the before/after size.
6. **A1, A2, A3** — the `AGENTS.md` consolidation. Largest change, and cheapest
   once E1 exists to do the propagation.
7. **E2** — CI, once there is a settled shape to validate against.


---

# Part II — reviewed against Agentic Spec-Driven Development

**Added 2026-08-19.** The intended source was `agentic-spec.com` — Anatoly Volkhover's
*Agentic Spec-Driven Development* — not `agent-spec.com`. That domain is blocked by the
same egress policy, but the site's **full project archive** was supplied directly: the
companion site specified, built, and regenerated under its own method. This part is
grounded in that archive, not in search summaries.

The archive is the method demonstrated on itself: a root `CLAUDE.md` of durable rules and
a File Registry; four bootstrap protocol files (`rule-analysis.md`,
`rule-conflict-protocol.md`, `disambiguate.md`, `regen-all.md`); nine `specs/`; two
append-only `logs/`; and generated `artifacts/`.

Part I asked whether these repos conform to the file formats agents read. This part asks
the harder question: **do they have a mechanism that keeps a body of agent instructions
correct as it grows?** Part I found six defects. Part II is largely the observation that
this method has a named mechanism for each of them.

## The method in one page

| Mechanism | What it does |
|---|---|
| **Project Intent** | A stated purpose. Input that doesn't align with it stops work until relevance is established or the user issues a blind override. |
| **File Registry** | Every file carries a **Type** (`rules`/`log`/`spec`/`view`/`asset`), a **Protocol**, an Extension, a Subfolder, a Description, and — where the Protocol demands — Dependencies and Instructions. All four sets are closed; adding a value needs explicit approval. Inventory changes hit the registry *before* the file system. |
| **Protocols** | `read-only`, `append-only`, `editable`, `generated`, `guarded`. The Protocol, not convention, decides how an agent may touch the file. |
| **Guarded Edits** | Before writing a `guarded` file, check the change against that file and *every other* `guarded` file for six categories: (A) direct contradictions, (B) duplicates, (C) vocabulary mismatch, (D) reference integrity, (E) scope drift, (F) rationale conflicts. Any finding blocks the write. Resolutions re-run the check in a loop until clean. An override is recorded as an inline comment beside the change — a visible, permanent trace. |
| **Artifacts** | A `generated` file is never hand-edited, and never *read* except while regenerating it. A change request against one is routed to its Dependencies, or to its Instructions file if the generation procedure itself is at issue. Regeneration is manual only, topologically ordered, never a side effect. |
| **Intake Logging** | Every user input recorded verbatim, append-only, before the work. No AI output in the log, no announcement that logging happened. Each entry lists the other files the turn modified. |
| **Rule Conflicts** | Overlap is not conflict. On real incompatibility: stop before producing anything, append an entry to an append-only log under a stable `RC###` id, present the rules verbatim with sources and at least three options, and never infer a resolution. |
| **Rule Analysis** | Every rule add/edit/remove runs a protocol: list the rule's explicit *and implicit* intents, flag conflicts against the whole rule set, verify formatting, verify every file reference resolves in the registry. Removal is blocked while other rules still reference the rule. |
| **Glossary** | Term / Meaning / **Anti-meanings**. Entry changes run a **closure check** (every project term inside a definition is itself defined) and a **circularity check** (no definition chain loops back). |
| **Rationale in place** | Specs carry a **Rationale** block beside each decision, and record superseded decisions inline. |
| **Rule formatting** | Group under H2. One requirement per rule. MUST/SHOULD/MAY. **Pair every prohibition with the recommended alternative.** Long detail moves to a referenced file. Cite files by registered name only. |

## G1 — There is no File Registry, and every Part I defect is a symptom *(inclusion)*

This is the finding. Everything else in Part II follows from it.

The five repos ship roughly 29 guidelines, 24 commands, 27 Copilot instructions, 28 droid
skills, 50 Cursor templates, 5 hooks, and a handful of scripts — with **no inventory, no
type, no protocol, and no dependency edges**. Nothing anywhere declares what a given file
*is* or how an agent may touch it. Re-read the Part I findings against that:

| Part I finding | The registry mechanism that addresses it |
|---|---|
| B1 — doctrine block 7 weeks stale in 4 repos | `guarded`: category A/B findings block the write |
| A2 — doctrine never reaches the deliverables | Description **non-overlap** + reference resolution |
| C1 — Copilot instruction with Skill frontmatter | Type discipline: a `rules` file carries its format |
| C3 — 7 commands in Cursor's rules directory | **Path discipline** — registered location is the location |
| C5 — `allowed-tools: Git, Gh`, tools that don't exist | **Undefined References** — stop, don't infer |
| D1 — 19.5 KB of catalogue on every turn | The registry *is* the catalogue, and it is structured |
| E1 — hand-propagation across five repos | Dependencies + Instructions make propagation mechanical |
| `log-session-tokens` unregistered and inert | Registration is what makes a file real |

Eight independent defects, one missing mechanism. Part I's recommendations were each a
hand-rolled partial substitute for it: the marker-sync tool with `--check` (E1) is a weak
`guarded`; the frontmatter validator (E2) is a weak type discipline; "move annotations to
README" (D1) is a registry without the structure that makes one useful.

**Recommend:** add a File Registry to `dot-claude` first, as one table in the always-loaded
file, with the Type/Protocol/Description/Dependencies/Instructions columns. Start with the
files that already hurt: the doctrine blocks (`guarded`), the generated Cursor and Droid
output (`generated`, with `sync-from-dot-claude.sh` as Instructions), the token ledger
(`log`, `append-only`), and the hooks. Do not attempt all 160 files at once.

## G2 — The doctrine blocks are the textbook `guarded` case *(replacement)*

Finding B1 — the central-ops block wrong in four of five repos for seven weeks — is
category **A (direct contradiction)** and **B (duplicate)** of the Guarded Edits Protocol,
which is exactly what that protocol exists to catch. The design-pattern block (A3) is
category **E (scope drift)**: content that belongs in every deliverable, living in one.

The method's answer is not a sync script. It is that a `guarded` file cannot be written
until the proposed content has been checked against every other `guarded` file, and that
an accepted inconsistency leaves an inline comment recording the acceptance — as
`specs/errata-flow.md` does, where a superseded design decision is preserved in place:

```
<!-- Override applied 2026-05-22 per Guarded Edits Protocol: the previous version
     of this spec specified an on-site editable preview ... The current Step 5
     supersedes that decision per explicit user instruction; ... -->
```

Nothing in these five repos records *that* a divergence was accepted, so a reader cannot
distinguish deliberate variation from drift. That ambiguity is why B1 survived seven weeks:
four stale copies and one current one look exactly like four tool-specific variants.

**Recommend:** mark the doctrine blocks `guarded`, and make E1's `--check` mode report the
six categories rather than a plain diff. Where a repo genuinely needs a different wording,
record the override inline instead of letting it read as drift.

## G3 — Generated files are generated by nothing declared *(replacement)*

`dot-cursor/bin/migrate-to-cursor.sh` generates `.cursor/rules/*.mdc` from guidelines.
`dot-cursor/bin/sync-from-dot-claude.sh` and `dot-droid/bin/sync-from-dot-claude.sh`
propagate content. But **no file declares itself generated, names its sources, or names
the procedure that produces it.** So a hand-edit to a `.mdc` is indistinguishable from an
authored one until the next run silently overwrites it — and `dot-copilot/CLAUDE.md`
responds to that risk by forbidding sync entirely ("`copilot/` is the source of truth; do
not treat any other repo as upstream"), which is how it ended up with the stale doctrine
block in B1.

The method's three rules are the fix, and the third is the one worth stealing:

1. A change request against a generated file routes to its **Dependencies** — or to its
   **Instructions** file when the generation procedure itself is what's wrong.
2. Never *read* a generated file except while regenerating it. Reading generated output
   invites reasoning from a stale rendering instead of the source.
3. Regeneration is **manual and explicit**, topologically ordered by the dependency graph,
   with the plan presented for approval before anything is written.

That last one is what makes generation safe to adopt: nothing is regenerated as a side
effect of unrelated work, so a sync script stops being a thing you're afraid to run.

**Recommend:** declare the Cursor `.mdc` files and the Droid skills `generated`, with the
guidelines as Dependencies and the sync script as Instructions. Then `dot-copilot` can
rejoin the propagation graph instead of opting out of it — which resolves the A2/B1 cluster
at its root rather than per-incident.

## G4 — The conflict rule has the principle and none of the machinery *(inclusion)*

`dot-claude/CLAUDE.md` states:

> **Surface conflicts; don't average them.** When two patterns in the codebase contradict
> … pick one — usually the more recent or more tested — explain why, and flag the other
> for cleanup. Blending two patterns produces a third that nobody intended.

That is the right rule, and Part I found it is the single most-violated one in these repos
(C4's two skill-description styles, C5's two `allowed-tools` styles, five instruction-file
dialects). The method supplies what the sentence lacks:

- **A definition that excludes false positives** — overlap is not conflict; only genuine
  incompatibility triggers the protocol. Without this a conflict rule fires constantly and
  gets ignored.
- **A stop condition** — halt *before* producing anything that depends on the conflicting
  rules, rather than deciding and explaining afterwards.
- **An append-only log with stable `RC###` ids**, carrying the triggering input verbatim,
  both rules quoted with their source files and sections, why they cannot both hold, the
  options offered, and the decision.
- **At least three options**, one of which is always "stop".

The log is the part that matters most here. Without it the same conflict is re-litigated
every session and the resolution is lost — which is precisely what "pick one and flag the
other for cleanup" produces when nobody records the flag.

**Recommend:** add `logs/rule-conflict-log.md` and a `rule-conflict-protocol.md` to
`dot-claude`, and narrow the existing rule to genuine incompatibility. The four SDLC
skills already carry the harder half of this discipline; the conflict log is cheap.

## G5 — Rationale lives in a different directory from the decision *(inclusion)*

`specs/errata-flow.md` carries a **Rationale** block beside nearly every decision — why a
single entry point rather than per-chapter buttons, why the TOC is always expanded, why
the explanation is required and the correction optional, why drafts are discarded on
cancel, why submission is a `mailto:` handoff rather than a server endpoint. An agent
regenerating that page cannot reach the decision without reading why it holds.

These repos put rationale in ADRs under `docs/decisions/`, linked by FR-###. That is the
right convention for *architectural* decisions and `guidelines/adr.md` is well specified.
But it means the day-to-day reasons — why `allowed-tools` is bare-comma, why session logs
carry a `tool:` field, why `settings.json` is gitignored — are either absent or a long way
from the thing they explain. `guidelines/karpathy-principles.md` already reaches for this
instinct ("mention, don't delete, pre-existing dead code"); inline Rationale is the
stronger form.

**Recommend:** keep ADRs for architectural decisions, and add Rationale blocks to the
guidelines and commands for local ones. Where a rule reverses an earlier one, record the
supersession inline rather than silently replacing the text — category F of the Guarded
Edits check exists because contradictory rationales are otherwise invisible.

## G6 — A glossary with anti-meanings, and two cheap checks *(inclusion)*

The method's glossary carries an **Anti-meanings** column — what the term explicitly does
*not* mean here — populated when a project meaning collides with an entrenched default.
The reference project needs exactly one row:

| Term | Meaning | Anti-meanings |
|---|---|---|
| `page` | A printed-book page number. | Not a URL; not a site-page identifier. |

Entry changes run a **closure check** (every project term used inside a definition is
itself defined) and a **circularity check** (no chain of definitions loops back on itself).

These repos have no global glossary, and they have live vocabulary collisions that one
would catch. *Knowledge base* means the `okf-knowledge` bundle in `dot-claude` and the
`HomeAssistant`/`home-ops` repo in the other four (B1). *Skill* means a `SKILL.md` in
`dot-claude` and `dot-droid`, a `.mdc` rule in `dot-cursor`, and an `.instructions.md` in
`dot-copilot`. *Command*, *rule*, and *instruction* are each used for two different things
across the set — which is category **C (vocabulary mismatch)** of the Guarded Edits check,
and a direct cause of C3, where seven commands ended up filed as rules.

**Recommend:** a short glossary in the shared doctrine block — `knowledge base`, `skill`,
`command`, `rule`, `guideline`, `deliverable` — with anti-meanings where the tools disagree.
Six rows would remove a standing source of miscategorization.

## G7 — A correction to Part I on context budget

Part I finding **D1** flagged `dot-claude/CLAUDE.md` at 231 lines / 19.5 KB as too large
for a file loaded on every turn. The reference project's `CLAUDE.md` is **292 lines /
33 KB** — half again as large.

So size was the wrong measure, and D1's framing needs correcting. The method spends its
whole budget on durable rules and a structured registry: every line is either enforceable
behavior or a routing table an agent uses to decide where to read and write.
`dot-claude/CLAUDE.md` spends roughly 60% of its lines on annotated catalogues of files the
model can enumerate with `ls` and must open anyway to use.

**The recommendation is unchanged and the reasoning is stronger.** Cut the annotated
indexes; then spend the reclaimed budget on a File Registry (G1) rather than banking it.
A large always-loaded file is not the problem. A large always-loaded file that carries
prose instead of enforceable structure is.

## G8 — Rule formatting conventions worth adopting wholesale *(inclusion)*

`rule-analysis.md` states six conventions for durable rules. Five are already roughly
honored across these repos. The other is not, and is the most useful:

> (d) Pair every prohibition with the recommended alternative.

Spot-checking the guidelines, most prohibitions stand alone — "never commit to main",
"no `fmt.Fprintf` for JSON responses", "don't use pandoc". Each has an intended
alternative that a reader has to already know. The other five are worth stating explicitly
anyway, since they double as the acceptance criteria for E2's validator: group under H2,
one requirement per rule, MUST/SHOULD/MAY markers, long detail moved to a referenced file,
and files cited by registered name rather than by description or alias.

**Recommend:** adopt all six in `guidelines/`, and add the pair-every-prohibition rule to
the checks in E2. It is mechanically detectable: a MUST NOT with no adjacent alternative.

## Revised order of work

Part I's ordering holds for the format defects. G1 changes what comes after them:

1. **B1** — replace the four stale doctrine blocks. Still first; still an active wrong answer.
2. **C1, C2** — the two frontmatter fixes that make dead config live.
3. **G1 (first pass)** — a File Registry in `dot-claude` covering the doctrine blocks, the
   generated Cursor/Droid output, the hooks, and the token ledger. Everything below depends
   on it.
4. **G2, G3** — mark the doctrine blocks `guarded` and the tool output `generated`; E1's
   sync tool becomes the Instructions file rather than a bolt-on. Supersedes Part I's E1.
5. **C3, C4, C5** — frontmatter and placement normalization, now with registered paths to
   normalize *to*.
6. **G6, G8** — the glossary and the six rule-formatting conventions. Both are inputs to E2.
7. **D1 + G7** — trim the catalogue; the registry from step 3 replaces it.
8. **E2** — CI, validating the registry and the formatting conventions rather than an
   ad-hoc list of frontmatter keys.
9. **G4, G5** — the conflict log and inline Rationale. Lowest urgency, longest payoff.
10. **A1** — the `AGENTS.md` consolidation, last, once there is a registry to consolidate.

---

# Part III — Verdict

Part II mapped eight Part I defects onto the missing File Registry (G1). That
overweighted it. Re-checking each against the cheapest mechanism that would actually
have caught it:

| Part I defect | Cheapest thing that catches it | Registry needed? |
|---|---|---|
| B1 doctrine stale in 4 repos | marker-block byte-compare in CI | no |
| A2 doctrine absent from deliverables | target list in the sync tool | no |
| C1 Skill frontmatter in a Copilot file | frontmatter validator | no |
| C3 commands filed as Cursor rules | validator: no `globs`/`alwaysApply` ⇒ not a rule | no |
| C5 `allowed-tools: Git, Gh` | validator against the real tool list | no |
| D1 19.5 KB catalogue every turn | delete the catalogue | **registry makes it worse** |
| E1 hand-propagation across repos | declare generated-from **in the file** | no |
| `log-session-tokens` unregistered | — | marginal |

Six of eight are frontmatter plus a validator. G1 is downgraded accordingly.

## Reject: the File Registry as a table

The registry is load-bearing in the reference project because of an assumption that does
not hold here: **one agent, one repo, every write mediated by explicit approval.** Under
that assumption the table cannot drift, so other rules may safely depend on it — and the
**Reference resolution** rule does exactly that, requiring resolution against the registry
and forbidding a disk check.

These five repos are edited by hand, by five different tools, across several machines,
and — decisively — they are *templates installed into other projects*. A registry
describing `dot-claude`'s own inventory does not travel with the install. It would become
a second source of truth that nothing enforces, and a stale registry under a
don't-check-disk rule produces confidently wrong behavior. That is a worse failure mode
than the present one.

It is also the same object Part I recommended deleting. D1 says: remove the annotated
catalogue from the always-loaded file because it goes stale and duplicates `ls`. The File
Registry is that catalogue with more columns.

**Frontmatter is a distributed registry that cannot drift, because it lives in the file it
describes** — and the tools already read it. Prefer it wherever the two overlap. Type,
Extension, and Subfolder are derivable from the path; Description is already a frontmatter
field.

## Adopt

1. **`Protocol` as a frontmatter field** — the one idea in the registry that is not
   derivable from the filesystem, and the one worth taking. Two values carry nearly all
   the value:
   - `generated: {from: [...], via: <script>}` — settles G3. Makes it visible that a
     `.mdc` is output, names its sources, and lets `dot-copilot` rejoin the propagation
     graph instead of opting out of it.
   - `guarded: <group>` — settles G2/B1. The doctrine blocks declare their group; CI
     compares them.
2. **The rule-conflict log** — `logs/rule-conflict-log.md`, append-only, stable `RC###`
   ids. Cheap, and it repairs a rule already present and already violated (G4): without a
   log, "pick one and flag the other for cleanup" loses the flag between sessions.
3. **The rule-formatting conventions** — all six, especially *pair every prohibition with
   the recommended alternative*. Free, and mechanically checkable in the E2 validator.

## Adapt

4. **Guarded Edits — as CI, not as an interactive loop.** Categories A and B
   (contradiction, duplicate) are a byte-compare of marker blocks. C (vocabulary) needs the
   glossary below. D (reference integrity) the validator already does. E and F (scope
   drift, rationale conflict) are human judgment — skip them. Keep the *inline override
   comment*: it is the part that distinguishes deliberate variation from drift, which is
   why B1 survived seven weeks.
5. **Glossary with anti-meanings — a table, not a protocol.** About six rows in the shared
   doctrine block: `knowledge base`, `skill`, `command`, `rule`, `guideline`, `deliverable`.
   Drop the closure and circularity checks; at six rows they are ceremony.
6. **Inline Rationale — for local rules only.** ADRs stay for architectural decisions.
   Rationale blocks go next to guideline and command rules, where a separate ADR would be
   overkill and the "why" is currently absent.

## Reject

7. **The File Registry table** — above.
8. **Intake logging** (every input verbatim, append-only, AI output excluded). It exists to
   reconstruct why a spec says what it says. `session-logs/` are deliberately summaries,
   and that is the right choice for cross-tool handoff. Different problem.
9. **The approval gates** — "MUST be recorded only after explicit user approval" on rule
   changes, glossary changes, inventory changes, description changes. The method earns that
   friction because the spec *is* the product and a defect ships. These guidelines are
   advisory prose read by an LLM; a wrong one costs a bad suggestion. Git review is the
   approval gate.
10. **The input-relevance gate** (refuse off-intent work until relevance is established).
    Correct for a single-purpose website project. Wrong for a general-purpose base class
    whose whole job is to apply across unrelated projects.

## Where these repos are already ahead

The reference project has **no traceability mechanism at all** — no requirement IDs, no
coverage check, nothing resembling `/trace-check` or the FR-### chain. It has no
cross-tool story, having only ever had one tool. It has no prose or formatting standards.
The SDLC toolkit and the ADR convention are more rigorous than anything in the archive;
they are just, per Part I finding F1, not wired in.

## Net

Take `Protocol` in frontmatter, the conflict log, the six formatting conventions, the
glossary table, and the override comment. Leave the registry, the intake log, and the
approval ceremony. The ordering in Part II stands with step 3 replaced: instead of a File
Registry, add `generated:` and `guarded:` frontmatter to the files that already hurt.
