---
paths:
  - "**/*.{sh,bash}"
---

# Shell

- Start with `set -euo pipefail`, find the script's own directory with
  `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, and build paths from it. Quote
  every expansion, check every `cd`, and clean up with `trap ... EXIT`.
- macOS `mktemp -d` ignores `$TMPDIR`, so inside the Claude Code sandbox it fails. Pass a
  template: `mktemp -d "${TMPDIR:-/tmp}/name.XXXXXX"`.
- BSD `wc -l` pads its count with spaces: compare counts with `-eq`, never `=`.
- `grep -c` prints `0` and exits 1 when nothing matches, so `$(grep -c x f || echo 0)` yields
  two lines. Use `n=$(grep -c x f); n=${n:-0}`.
- A hook checks `command -v jq` before using jq and exits 0 without it. A hook must never fail
  a session.
- Quoting, heredocs and nested commands: the `shell-escaping` skill. Structure and examples:
  the `shell-scripts` skill.
