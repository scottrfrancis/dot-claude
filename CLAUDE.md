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
  say so when you use an exemption. A test written after the code does not count as test-first:
  flag it in review.
- Before building something non-trivial, state the assumptions it rests on, and ask when one
  is a guess.
- Mention dead code you come across; delete it only when it is part of the task.
- When two patterns or rules contradict, pick one (usually the newer or better tested), say
  why, and flag the other for cleanup. Blending them produces a third pattern nobody chose. The
  rule-conflict-protocol skill covers recording the decision.
- Put temporary scripts and test programs in a temp directory, never in the project.

## Spending and deploys

- Use paid models (Bedrock, the Anthropic API, any cloud LLM) only when Scott asks. Smoke and
  functional tests run on a local model, which the host's doctrine names.
- Promote to prod only when Scott asks. A green run on a test environment is not that request.

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

<!-- design-patterns: begin -->
## Design-pattern discipline

Before designing a non-trivial component, or coining a new mechanism/abstraction:

- **Consult the pattern library first** — the `dot-patterns` corpus (GoF index with house
  stances, personal patterns, vetted mixins). On the LAN: the **patterns MCP** at `mini.local:8093` (search/read_file), or read the
  vault checkout `/Volumes/workspace/dot-patterns` directly. Off-LAN: the installed skills
  / your local `dot-patterns` checkout.
- **Name the pattern you apply** ("this is Strategy" / "the data-diode black/white/gray") in
  your plan and PR so reviewers share the vocabulary.
- **Don't reinvent what the library names.** Reuse an applicable pattern; if you deviate, say why.
- **If you coin something reusable, flag it for capture** rather than letting it evaporate.
- Prefer the GoF house stances (composition over inheritance; Strategy over if-ladders;
  avoid Singleton/Visitor) unless there's a stated reason.
<!-- design-patterns: end -->
