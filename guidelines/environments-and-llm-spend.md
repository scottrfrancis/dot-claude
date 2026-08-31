# Environments and the LLM Spend Gate

House style, set 2026-08-31. Where work happens, where it is tested, and which LLM
is allowed to answer.

## The tiers

| tier | box | role |
|---|---|---|
| **work** | Studio (sometimes razer) | edit, commit, iterate |
| **dev + staging** | **`dev.local`** | deploy here for testing and evaluation — the tier that gates prod |
| **prod** | wherever the project ships | reached **only** on an explicit "promote dev to prod" |

### `dev.local` is dev *and* staging

It is not a scratch box. It is where a change earns the right to be promoted, and
a change that has not run there has not been tested.

It is also the only place a measurement is worth trusting. On 2026-08-28 one
*unchanged* test file on the Studio returned 9 passed, then 5 failed, then 4
passed, purely as free memory moved between 12 GB and 179 MB. A bed that answers
differently depending on what else is open is not evidence. `dev.local` is x86
Linux with 62 GB and it is quiet — and where the deploy target is x86 Linux, a
green run there means something a green run on arm64 macOS does not.

### Promotion is asked for, never inferred

**A green `dev.local` run is not authorisation to deploy.** Promotion to prod
happens when the owner explicitly asks for it. This is the same rule as
*deploy merged master, not a branch*: "it passes" authorises nothing by itself.

### Drive the harness from the machine you are working on

The test harness **generally runs from Studio**, driving `dev.local` over ssh.
Occasionally it has to run *on* dev — fine when needed. Prefer Studio-driven, so
the box you are working on stays the control point and you are not editing code in
one place while a shell somewhere else holds the state.

## The LLM spend gate

**`dev-ai.local` is the LLM for ALL smoke tests and functional tests.** Default to
it, every time.

**Use Bedrock, the Anthropic API, or any other cloud/paid LLM ONLY when the owner
specifically asks.** This is a **spend gate**, not a style preference. Do not reach
for a cloud model because it would be faster, or better, or because a local model
gave a mediocre answer.

Corollaries:

- **Test functionality, not output quality.** A local model's prose is irrelevant
  when the assertion is "the pipeline completes". Never report a local model's weak
  writing as a defect.
- **Verify the model tag exists before the run.** The installed set drifts —
  `curl -s http://dev-ai.local:11434/api/tags`. A missing tag is a 404 in the
  middle of a run, not an error at startup. Two committed defaults and one
  remembered "primary model" were all absent on 2026-08-31.
- **Where an agentic/MCP tool loop is involved, tool-calling capability is the
  binding constraint** — not parameter count. Pick the tools-capable tag.
- **A local model cannot prove a specific defect is fixed.** It will not reproduce
  a particular defective sentence on demand. So pair the generated tier with a
  **deterministic seeded tier**: real recorded input in, assert the artefact out.
  The generated tier proves the pipeline works; only the seeded tier proves the fix
  does.
- **This narrows, and never relaxes, data-handling rules.** Where PHI or client
  data is in play, cloud inference still requires the BAA path *when* it is
  authorised. Local inference is additionally attractive here precisely because
  nothing leaves the LAN.

## Shape of a dev stack

Run it in Docker, and:

- **Deps baked, code bind-mounted.** A branch switch has to stay a 3-second
  checkout. If it becomes a 4-minute image build, people stop switching branches to
  check things.
- **Publish every port on `127.0.0.1`**, never `0.0.0.0`, wherever client data is
  served.
- **Set the provider and the model explicitly.** Both usually have code defaults,
  and inheriting them silently is how an eval run grades one model while prod serves
  another. Nothing errors; the numbers just describe a configuration nobody ships.
- **Match the host user** (`HOST_UID`/`HOST_GID`) or the container leaves
  root-owned files in the checkout.
- **Report the configuration, not the ports.** "Something is listening" is the
  weakest reading of health and the one that misleads. See
  [Verification Layers](./verification-layers.md).
- **Probe through the code path that runs in anger, not around it.** A shell probe
  that reaches past the application will measure something else and blame the
  system. On 2026-08-31 three of a new stack's first four "failures" were the checks
  being wrong: a credential the app loads into its own process (invisible to
  `docker exec printenv`, so the probe sent an empty header and got a truthful 401),
  a wrong return type, and `set -o pipefail` plus `grep -q` turning a successful
  match into a failed pipeline. Only one finding was real.

## Related

- [Verification Layers](./verification-layers.md) — the gap between "tests pass"
  and "the system does the thing"; checks that cannot fail.
- [Testing Strategies](./testing.md) — the pyramid, and the subject-drift rule.
- [CI Local Parity](./ci-local-parity.md) — run the exact CI commands locally.
- [Central Ops Knowledge](./central-ops-knowledge.md) — authoritative for LAN host
  addresses. Verify hostnames there, not from memory.
