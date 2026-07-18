# Data-Diode List Control: Black / White / Gray

A reusable pattern for guarding a **one-way egress boundary** — any point where
content crosses from a trusted side to a less-trusted side and *cannot be recalled*:
pushing a config repo to a public remote, emailing a bundle off a client laptop,
posting to an external service, publishing an artifact. The boundary is a *data diode*:
information flows out, nothing flows back to undo a leak.

The failure you're preventing is a **known-bad or unrecognized identifier riding out**
in otherwise-fine content — a client name, a hostname, a person, an internal codename.

## The three lists

| List | Role | Action on match | Who edits |
|---|---|---|---|
| **Blacklist** | deny | **Block** the egress (hard gate) — exact-match/regex patterns of things that must never leave | you |
| **Whitelist** | allow | **Silence** — known-safe names that would otherwise trip the detector | you |
| **Graylist** | pending | **Advise** — seen, classified as neither, awaiting a human decision; each gray is **promotable** to black or white | the tool proposes; you promote |

The blacklist alone is brittle: it only catches what you already thought of. The
graylist is the **discovery mechanism** — it surfaces the *unknown* candidates so the
blacklist can grow *before* the leak, not after.

## The flow

```
        content about to cross the boundary
                        │
              extract candidate identifiers
                        │
        ┌───────────────┼────────────────┐
     in BLACK?       in WHITE?      in neither
        │               │                │
      BLOCK           SILENCE          GRAY  ──►  advise the human
     (abort)         (ignore)                     │
                                        promote ──┴── to BLACK (scrub) or WHITE (safe)
```

- **Detection is fuzzy; blocking is exact.** Detect broadly (proper nouns, CamelCase,
  domains, host/user strings, acronyms) to find *candidates*. Block narrowly (precise
  patterns) so the hard gate never false-positives and gets disabled out of frustration.
- **Grays are advisory, not blocking.** A gray halts nothing — it prints "new candidate,
  decide." Blocking on grays trains people to bypass the gate. Reserve hard failure for
  the blacklist (and optionally a `--strict` CI mode).
- **Promotion is one action, human-owned.** `promote <term> --to black|white`. A gray,
  once promoted, never nags again. Whitelist promotions make the detector quieter over
  time; blacklist promotions make the gate stronger.
- **Record grays so they nag once.** Persist surfaced grays; re-report only genuinely
  new ones. A gate that repeats the same 20 candidates every run gets ignored.

## Design rules

- **Advise before the point of no return**, automatically — a pre-push / pre-send hook,
  not a step people must remember. The whole value is catching the *unremembered* leak.
- **Recall over precision for grays; precision over recall for the blacklist.** When
  unsure whether a candidate identifies someone, surface it (gray) and let the human
  downgrade. When writing a *block* pattern, make it specific — a bare common word as a
  blacklist entry causes false blocks and erodes trust.
- **Seed the whitelist** with the domain's common-safe vocabulary (your tooling names,
  standard tech proper nouns) so day-one noise is low.
- **Two detectors beat one.** A deterministic scanner (fast, hook-friendly, regex) plus
  an LLM/agent pass (context-aware — catches plain-worded names, people, subtle
  references the regex can't). The deterministic one gates every push; the agent one is
  a deeper on-demand review.
- **The lists are secrets-adjacent.** The blacklist literally enumerates the identifiers
  you're hiding — keep list files **local and uncommitted** (the thing you scrub must not
  leak via the scrublist itself). Ship only placeholder `.example` templates.
- **Never a substitute for not-collecting.** Lists are defense-in-depth. The primary
  control is still: don't put the sensitive thing in the artifact in the first place.

## Reference instantiation

The `dot-copilot` field kit implements this pattern for two diodes (git push, and an
emailed bundle off a locked-down client laptop):

- Blacklist → `~/.config/field-kit.scrublist`, enforced by `bin/make-field-bundle.sh`
  (aborts the build on any match).
- Whitelist → `~/.config/field-kit.allowlist`.
- Graylist → `~/.config/field-kit.graylist`, worked by `bin/entity-advisory.py`
  (`--record` to persist grays, `--promote TERM --to scrub|allow` to promote), wired as
  a `pre-push` git hook. The `/scrub-check` prompt is the agent-pass second detector.

## When to reach for it

Any irreversible outbound flow where *unrecognized* sensitive tokens are the risk:
public-repo pushes from work that touches clients, off-box exports from managed devices,
outbound webhooks/emails/artifacts, log shipping. If the flow is reversible or the
sensitive set is small and fully known, a plain blacklist may be enough — the graylist
earns its keep when you *don't* yet know everything that should be blocked.
