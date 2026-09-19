#!/usr/bin/env bash
# PreCompact hook: snapshot what compaction is about to summarise away.
#
# Compaction is the moment context is lost. Anything not yet promoted out of the
# conversation — a decision made and not written down, an open question, a conflict awaiting
# an answer — is summarised at best and dropped at worst.
#
# The snapshot is written to disk, deliberately. The additionalContext channel steers what
# survives the summary, but the durable value must not depend on that channel behaving as
# expected: the file is readable afterwards either way, and /pickup and /memorialize can
# find it. If PreCompact is not a supported event on this build, the hook simply never runs
# and nothing else changes.
#
# Advisory only — never blocks compaction, never fails a session.
set -euo pipefail

HOOK_INPUT="$(cat 2>/dev/null || true)"

TRIGGER="manual"
if command -v jq >/dev/null 2>&1 && [ -n "$HOOK_INPUT" ]; then
  TRIGGER="$(printf '%s' "$HOOK_INPUT" | jq -r '.trigger // "manual"' 2>/dev/null || echo manual)"
fi

# Prefer the shared cross-tool location; fall back to the legacy one, then give up quietly.
OUTDIR=""
for d in session-logs .claude/session-logs; do
  if [ -d "$d" ]; then OUTDIR="$d"; break; fi
done
if [ -z "$OUTDIR" ]; then
  mkdir -p session-logs 2>/dev/null && OUTDIR="session-logs" || exit 0
fi

STAMP="$(date +%Y-%m-%dT%H%M%S)"
OUT="$OUTDIR/precompact-$STAMP.md"
# `git rev-parse --abbrev-ref HEAD` prints "HEAD" *and* fails in a repo with no commits, so
# a `|| fallback` appends to real output rather than replacing it. Frontmatter needs exactly
# one line per value.
BRANCH="$(git branch --show-current 2>/dev/null | head -1 || true)"
if [ -z "$BRANCH" ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH="(unborn or detached)"
  else
    BRANCH="(not a git repo)"
  fi
fi

BIN="${HOME}/.claude/bin"
[ -d "$BIN" ] || BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" 2>/dev/null && pwd || echo '')"

CONFORMANCE=""
if [ -n "$BIN" ] && [ -x "$BIN/conformance.sh" ]; then
  CONFORMANCE="$("$BIN/conformance.sh" --project "$PWD" --quiet 2>/dev/null || true)"
fi

{
  printf -- '---\ntool: claude-code\nkind: precompact\ntimestamp: %s\nbranch: %s\ntrigger: %s\n---\n\n' \
    "$STAMP" "$BRANCH" "$TRIGGER"
  printf '# Pre-compaction snapshot\n\n'
  printf 'Written automatically before context was compacted. Deterministic state only —\n'
  printf 'what the conversation held is in the compaction summary, not here.\n\n'
  printf '## Branch\n\n`%s`\n\n' "$BRANCH"
  if [ -n "$CONFORMANCE" ]; then
    printf '## Outstanding at compaction\n\n```\n%s\n```\n\n' "$CONFORMANCE"
  fi
  printf '## Uncommitted at compaction\n\n'
  if git rev-parse --git-dir >/dev/null 2>&1; then
    changed="$(git status --short 2>/dev/null | head -40 || true)"
    if [ -n "$changed" ]; then printf '```\n%s\n```\n' "$changed"; else printf 'Working tree clean.\n'; fi
  else
    printf 'Not a git repository.\n'
  fi
} > "$OUT" 2>/dev/null || exit 0

# Steer the summary as well, where the channel is available. Best-effort: the file above is
# the part that has to work.
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "A pre-compaction snapshot was written to $OUT.

When compacting, preserve in the summary, in this order of priority:
1. Decisions made this session that are not yet written to a file, and the reasoning behind them.
2. Questions put to the user that were never answered.
3. Anything the user asked for that has not been delivered yet.
4. Which files were changed and why — not the mechanics of how.

Discard tool output, command transcripts, and intermediate debugging that led nowhere." \
    '{ hookSpecificOutput: { hookEventName: "PreCompact", additionalContext: $ctx } }' 2>/dev/null || true
fi

exit 0
