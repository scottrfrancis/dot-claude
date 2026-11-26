# hooks plugin

The base config's global hook registrations. Before this plugin, each host wrote them into its
own `settings.json` by hand, and a host that missed one, or kept an entry for a script that had
gone, found out only when something broke.

| Event | Matcher | Script | Timeout (s) |
| ----- | ------- | ------ | ----------- |
| SessionStart | `^(startup\|clear)$` | `session-status.sh` | 30 |
| SessionStart | every start | `account-mismatch-warn.sh` | 10 |
| PreToolUse | `Bash` | `pre-tool-safety.sh` | 10 |
| PostToolUse | `Write\|Edit\|MultiEdit` | `prose-check.py` | 10 |
| Stop | every reply | `session-end-reminder.sh` | 10 |

The scripts stay in the repo's `hooks/`. Claude Code serves the plugin in place from the
checkout and runs each command with `CLAUDE_PLUGIN_ROOT` set to this directory, so a command
reaches its script as `${CLAUDE_PLUGIN_ROOT}/../../../hooks/<script>` under any HOME.

`bin/install.sh --apply` turns it on in each `settings.json` and removes the hand-written
registrations it replaces. `tests/test-hooks-plugin.sh` checks the registrations and runs each
command from this directory.
