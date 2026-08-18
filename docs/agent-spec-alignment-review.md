# Agent-Spec Alignment Review — the five dot-* config repos

**Date:** 2026-08-18
**Scope:** `dot-claude`, `dot-copilot`, `dot-cursor`, `dot-droid`, `dot-opencode`
**Status:** review only — no config files changed by this document.

## Read this first: the requested source was unreachable

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
