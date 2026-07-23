# Link Sweep — one iteration of the federation link audit

Work exactly **one target** of the link audit per invocation (designed to run under
`/loop`). Plan + fix policy: `/Volumes/workspace/okf-knowledge/inbox/link-audit/PLAN.md`.
State: `/Volumes/workspace/okf-knowledge/inbox/link-audit/state.json`.

## Steps

1. **Sync first**: `git -C /Volumes/workspace/okf-knowledge pull -q` and
   `git -C /Volumes/workspace/HomeAssistant pull -q` (other agents write these repos).
2. **Read `state.json`**; pick the FIRST target with `"status": "pending"`. If none:
   the sweep is complete — if `final-report` was already done, just say so and, if
   running under /loop, END THE LOOP (ScheduleWakeup stop). Set the chosen target to
   `"in-progress"` immediately (crash-safe).
3. **Run its `cmd`** from `/Volumes/workspace/okf-knowledge`. Read every finding.
4. **Fix findings** per PLAN.md's fix policy (§Fix policy — repoint > rewrite > archive.org;
   never delete pages; ambiguous → append to `inbox/link-audit/NEEDS-SCOTT.md`).
   External-URL targets: 403/429 from bot-hostile domains are usually fine — eyeball,
   don't churn. LAN targets: consult the infra bundle for a service's current home
   before "fixing" a URL (the service may have moved, or the page may be historical —
   incident/log pages describing a dead service at the time are CORRECT; leave them).
5. **Re-run the cmd** — confirm clean (or only accepted/NEEDS-SCOTT residue remains).
6. **Lint + render** if the HomeAssistant repo was touched: `python3 tools/kb-lint.py`,
   `python3 tools/okf-lint.py`, `python3 tools/okf-render.py home-ops site`.
7. **Commit + push** each touched repo:
   `docs(<repo>): link-sweep <target-id> — <N> fixed, <M> flagged`.
8. **Update `state.json`**: target → `"done"`, add `"fixed": N, "flagged": M,
   "notes": "<one line>"`. Commit+push state (okf-knowledge).
9. **Report** one short paragraph: target, findings, fixes, flags, what's next.

## Target `final-report` (the last iteration)

Synthesize all targets' counts/notes into `inbox/link-audit/REPORT.md` (totals by class,
NEEDS-SCOTT list inline, follow-up suggestions — e.g. wiring `audit.py` into kb-lint or
the Monday hasami cron for continuous checking). Commit+push. Then END THE LOOP
(ScheduleWakeup stop if under /loop) and tell Scott the sweep is complete.

## Guardrails

- One target per invocation — even if it looks quick, stop after step 9.
- Never `git push --force`, never delete md files, never edit generated pages by hand
  (fix their **generators/TSVs** instead: network-annotations.tsv, equipment-extra.tsv).
- health bundle pages are sensitive (git-crypt) — edit links only, touch nothing clinical.
- If a `cmd` errors (tool bug), fix `infra/tooling/link-audit/audit.py` (tests first:
  `test_audit.py`), commit the tool fix, and retry the target in the SAME iteration.
