---
description: Drive the local punch time tracker (start/stop/status/log) for this session
argument-hint: [start|stop|status|log ...] (no args = status)
allowed-tools: Bash
---

# /punch — local time tracking

Thin, project-aware wrapper over the **`punch`** CLI (the local beaufort time-tool).
Records accumulate in `~/.beaufort/data/time.db` on this device and sync to the
central beaufort ingest on hasami — no SSH at call time, works offline.
See [[beaufort-time-tracking]].

Renamed from `b` on 2026-08-14; `b` still works as a symlink.

Arguments provided: $ARGUMENTS

## Resolve `punch` (skip silently if not installed)

`punch` lives in the user's **real login home**, but Claude Code sessions override
`$HOME` to a profile dir — so resolve it explicitly, never via `$HOME`. Try the
passwd db on both platforms, and treat an empty answer as "not found" rather than
building a bogus path:

```bash
P="$(command -v punch 2>/dev/null || command -v b 2>/dev/null)"
if [ -z "$P" ]; then
  U="$(id -un 2>/dev/null || echo "${USER:-}")"
  RH="$( { getent passwd "$U" | cut -d: -f6; } 2>/dev/null )"
  [ -z "$RH" ] && RH="$( { dscl . -read "/Users/$U" NFSHomeDirectory | awk '{print $2}'; } 2>/dev/null )"
  # studio installs to ~/bin, dev.local to ~/.local/bin; `b` is the old name.
  for c in "$RH/bin/punch" "$RH/.local/bin/punch" "$RH/bin/b" "$RH/.local/bin/b"; do
    [ -z "$P" ] && [ -x "$c" ] && P="$c"
  done
fi
[ -z "$P" ] && { echo "punch (time tracker) not installed on this device — nothing to do."; exit 0; }
```

**Report "not installed" only when `$P` is genuinely empty.** On 2026-08-14 the
macOS-only `dscl` fallback returned empty under a sandbox, `$RH/bin/punch`
resolved to `/bin/punch`, and a session reported the tracker missing on a host
where it was installed and on PATH — a wrong claim that reached two committed
documents. If `command -v` found it, it is installed.

## Dispatch on $ARGUMENTS

- **(no args) or `status`** → show open timers:
  ```bash
  "$P" list-open
  ```
  If none are open, report that and suggest a `start` (see below). If one or
  more are open, report each with its elapsed time.

- **`start [project]`** → begin a timer. If no project is given, suggest one
  from the current git repo (`basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`).
  Confirm the customer/project/task with the user if ambiguous, then:
  ```bash
  "$P" start --project "<project>" --task "<short task>" --notes "<session focus>"
  ```
  Pass `--customer` when known. Do **not** invent billable customers — leave
  blank and let central attribution resolve it if unsure.

- **`stop`** → close the open timer(s):
  ```bash
  "$P" stop --notes "<what got done>"
  ```
  If multiple timers are open, disambiguate with `--id TR-NNN` or `--all`.

- **`log ...`** → retroactively record completed work:
  ```bash
  "$P" log --duration "1.5h" --project "<p>" --task "<t>" --notes "<...>"
  ```

- **anything else** → pass straight through to the tool (`list`, `yesterday`,
  `show TR-NNN`, `report`, `history`, `patch`, `delete`, …):
  ```bash
  "$P" $ARGUMENTS
  ```

## Sync (optional)

`punch` writes locally; a push agent ships closed entries to hasami on its own
cadence — the `time-push` launchd agent on macOS, a `beaufort-time-push` systemd
user timer on Linux. To push immediately after a `stop`:

```bash
"$(dirname "$P")/time-push" 2>/dev/null || true
```

## Rules

- This command never posts to Slack — it drives the deterministic local tool
  only (unlike the `bf` Slack client on other devices).
- Reading state (`list-open`) is always safe. For `start`/`stop`, prefer letting
  the user run it in their own terminal if you're unsure of the project/task.
- Keep output terse: the active timer (or "none") and the action taken.
