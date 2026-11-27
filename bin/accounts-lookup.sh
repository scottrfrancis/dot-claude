#!/usr/bin/env bash
# accounts-lookup.sh — look a client up in this host's private accounts table.
#
#   accounts-lookup.sh marker|remote|org VALUE
#
# This repo is public, so client names never appear in it. Each host lists its clients in
# accounts.local at the checkout root, which is gitignored (accounts.local.example shows the
# format). DOT_CLAUDE_ACCOUNTS names another table, which the tests use.
#
# Each rule is one line:  <kind> <match> <account> <segment> <label...>
#   kind     marker: the token in a project's .account-context
#            remote: the project's remote.origin.url
#            org:    oauthAccount.organizationName of the logged-in account
#   match    a shell glob; marker and org compare case-insensitively
#   account  the profile code the account checks expect: ss, al or bs
#   segment  the memory and glossary segment under memory/local/, or - for none
#   label    the rest of the line, shown in banners and warnings
#
# Prints "<account>\t<segment>\t<label>" for the first matching rule, and nothing when no
# rule matches or there is no table. Always exits 0: the account checks must never fail.
set -uo pipefail

kind="${1:-}"
value="${2:-}"
table="${DOT_CLAUDE_ACCOUNTS:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)/accounts.local}"
[ -n "$kind" ] && [ -n "$value" ] && [ -f "$table" ] || exit 0

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
[ "$kind" = remote ] || value="$(lower "$value")"

while read -r k match account segment label; do
  case "$k" in ''|\#*) continue ;; esac
  [ "$k" = "$kind" ] && [ -n "${account:-}" ] || continue
  [ "$kind" = remote ] || match="$(lower "$match")"
  # shellcheck disable=SC2254  # the match is a glob on purpose
  case "$value" in
    $match) printf '%s\t%s\t%s\n' "$account" "${segment:--}" "${label:-}"; exit 0 ;;
  esac
done < "$table"
exit 0
