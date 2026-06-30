---
description: Drive the local b time tracker (start/stop/status/log) for this session
argument-hint: [start|stop|status|log ...] (no args = status)
allowed-tools: Bash
---

# /b — local time tracking

Thin, project-aware wrapper over the **`b`** CLI (the local beaufort time-tool).
Records accumulate in `~/.beaufort/data/time.db` on this device and sync to the
central beaufort ingest on hasami via the `time-push` launchd agent — no SSH at
call time, works offline. See [[beaufort-time-tracking]].

Arguments provided: $ARGUMENTS

## Resolve `b` (skip silently if not installed)

`b` lives in the user's real login home, but Claude Code sessions override
`$HOME` to a profile dir — so resolve it explicitly, never via `$HOME`:

```bash
B="$(command -v b 2>/dev/null)"
if [ -z "$B" ]; then
  RH="$(dscl . -read "/Users/$(whoami)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  [ -x "$RH/bin/b" ] && B="$RH/bin/b"
fi
[ -z "$B" ] && { echo "b (time tracker) not installed on this device — nothing to do."; exit 0; }
```

## Dispatch on $ARGUMENTS

- **(no args) or `status`** → show open timers:
  ```bash
  "$B" list-open
  ```
  If none are open, report that and suggest a `start` (see below). If one or
  more are open, report each with its elapsed time.

- **`start [project]`** → begin a timer. If no project is given, suggest one
  from the current git repo (`basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`).
  Confirm the customer/project/task with the user if ambiguous, then:
  ```bash
  "$B" start --project "<project>" --task "<short task>" --notes "<session focus>"
  ```
  Pass `--customer` when known. Do **not** invent billable customers — leave
  blank and let central attribution resolve it if unsure.

- **`stop`** → close the open timer(s):
  ```bash
  "$B" stop --notes "<what got done>"
  ```
  If multiple timers are open, disambiguate with `--id TR-NNN` or `--all`.

- **`log ...`** → retroactively record completed work:
  ```bash
  "$B" log --duration "1.5h" --project "<p>" --task "<t>" --notes "<...>"
  ```

- **anything else** → pass straight through to the tool (`list`, `yesterday`,
  `show TR-NNN`, `report`, `history`, `patch`, `delete`, …):
  ```bash
  "$B" $ARGUMENTS
  ```

## Sync (optional)

`b` writes locally; the `time-push` launchd agent ships closed entries to hasami
on its own cadence. To push immediately after a `stop`, run the wrapper:
```bash
"$(dirname "$B")/time-push" 2>/dev/null || true
```

## Rules

- This command never posts to Slack — it drives the deterministic local tool
  only (unlike the `bf` Slack client on other devices).
- Reading state (`list-open`) is always safe. For `start`/`stop`, prefer letting
  the user run it in their own terminal if you're unsure of the project/task.
- Keep output terse: the active timer (or "none") and the action taken.
