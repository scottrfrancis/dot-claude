#!/usr/bin/env bash
# link-config.sh — the old name of install.sh, which links the config dirs and also creates
# host.md and enables the hooks plugin. Kept so older notes and habits still work.
exec "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/install.sh" "$@"
