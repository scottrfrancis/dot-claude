# Working rules

These apply to every project on every host. Topic guidance lives in skills, which load when the
work matches them. README.md indexes the skills, commands, hooks and tooling, and records why
things are the way they are.

@~/.claude/host.md
@~/.claude/memory/MEMORY.md

## Branches

- At the start of a session or a run of tasks, remind Scott where the repo stands: the current
  branch and its status, and whether to pull, push, branch or delete one. He works across many
  repos and often starts without syncing. The SessionStart status block has the facts, and
  `/lets-go` fetches before reporting.
- Never commit or push a default branch. When asked to push from one, suggest a branch first.
- When Scott says a PR has merged, prompt him to pull and delete the merged branch.

## Code

- Write the test first for code that has behaviour: a failing test, the least code that passes
  it, then a refactor with the tests green. The test has to fail when the behaviour breaks, so
  apply the testing skill's mutation check. Spikes, pure config and generated code are exempt;
  say so when you use an exemption.
- When two patterns or rules contradict, pick one (usually the newer or better tested), say
  why, and flag the other for cleanup. Blending them produces a third pattern nobody chose. The
  rule-conflict-protocol skill covers recording the decision.
- Put temporary scripts and test programs in a temp directory, never in the project.

## Writing

Everything a person reads follows the prose-style skill: chat replies, commit and PR bodies,
docs, READMEs and ADRs. Technical writing gets no exemption; one knowledge bundle written under
that exemption reached 2,190 em-dashes. The costliest misses are em-dashes where a period, colon
or comma would do, documents that narrate their own edits, and bold used as a highlighter. When
a sentence sets up a claim only to deny it, delete the denied half, including when it is split
across two sentences.

## Safety

Session safety (`guidelines/session-safety.md`) applies only to a dedicated NPU/GPU box whose
project CLAUDE.md opts in. Never run `session-cleanup` anywhere else: it kills every Claude
process on the machine, this session included.
