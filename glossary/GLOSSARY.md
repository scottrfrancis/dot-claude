# Glossary

Terms that mean something specific here and something else in general use. A row is earned
by a term that actually caused a misunderstanding — see `guidelines/glossary.md`. This file
is small on purpose and stays that way.

Universal segment: true regardless of which client the work is for. Client-specific
vocabulary belongs in `glossary/local/<segment>/GLOSSARY.md`, which is gitignored.

| Term | Meaning | Anti-meanings |
|---|---|---|
| `guideline` | An on-demand standard in `guidelines/`, read before the matching task and not auto-loaded. | Not an always-loaded rule — those live in `CLAUDE.md`. Not a Cursor rule or a Copilot instruction file. |
| `rule` | A durable instruction that governs behaviour, carried in `CLAUDE.md` or a file it references. | Not a Cursor `.mdc`. Not a business rule, validation rule, or parsing rule inside a project's domain. |
| `command` | A user-invoked procedure in `commands/`, called as `/name`. | Not a shell command. Not a Cursor rule filed in the rules directory. Not a Copilot prompt file. |
| `skill` | A packaged capability as `skills/<name>/SKILL.md`. | Not a Cursor `.mdc` rule; not a Copilot `.instructions.md`; not a Droid droid. |
| `doctrine` | Shared content propagated from this repo to the downstream repos between `begin`/`end` markers. | Not general policy or philosophy. Not anything hand-copied — if it is not marker-delimited it is not doctrine. |
| `deliverable` | The file a downstream repo actually installs into a user's project. | Not this repo's own `CLAUDE.md`, which guides work *on* the repo and installs nowhere. |
| `segment` | A memory or glossary scope resolved from `.account-context` or the git remote — one client, or personal. | Not a code or data partition. Not a market segment. |
| `knowledge base` | The `okf-knowledge` bundle, served read-only by `kb-mcp` on the LAN. | Not the old `HomeAssistant/home-ops` location, which it was promoted out of on 2026-07-01. Not this repo's `memory/`. |
