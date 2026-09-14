#!/usr/bin/env bash
# Report the actual wiki/raw ingest posture of every repo under a workspace.
#
# Written 2026-09-14, after a PHI disclosure and a client credential both
# reached git through the same mechanism: automated mail ingest writing verbatim
# into a *tracked* wiki/raw tree.
#
# The reason this script exists rather than a doc: every repo's .gitignore
# carried the marker `# wiki-mixin: begin v1.0`, and that one version string
# covered three materially different policies —
#
#   Catalyst-Athletics, HomeAssistant : wiki/raw entirely ignored
#   Brightsign                        : raw tracked, only mp4/mov/zip/mp3 out
#   Catalyst-RCM                      : raw tracked, all attachment binaries out
#
# So "is this repo patched?" could not be answered by looking at the version.
# It is answered by looking at what is actually tracked, which is what this does.
#
# Usage:  wiki-raw-audit.sh [workspace-root]        # default /Volumes/workspace
#         wiki-raw-audit.sh --binaries-only         # only repos tracking binaries
#
# Exit 1 if any repo tracks attachment binaries under wiki/raw, so it can gate a
# cron or a pre-flight rather than only inform a human.
set -euo pipefail

ROOT="${1:-/Volumes/workspace}"
[ "${1:-}" = "--binaries-only" ] && { ROOT="/Volumes/workspace"; ONLY_BAD=1; }
ONLY_BAD="${ONLY_BAD:-0}"

# The formats clinical and contractual documents actually arrive in. Deliberately
# not "all binaries": the 2026-08-15 rule excluded mp4/mov/zip for repository
# SIZE and said nothing about these, which is exactly the gap that let ten
# operative reports through.
BIN_RE='\.(pdf|docx?|xlsx?|xlsb|pptx?|jpe?g|png|gif|tiff?|dat|eml|msg)$'

bad=0
printf '%-28s %8s %9s %9s  %s\n' REPO RAW-FILES BINARIES IGNORED POSTURE
printf '%-28s %8s %9s %9s  %s\n' "---------------------------" "--------" "---------" "---------" "-------"

for d in "$ROOT"/*/; do
    [ -d "$d/.git" ] || continue
    [ -d "$d/wiki/raw" ] || continue
    name=$(basename "$d")

    tracked=$(git -C "$d" ls-files wiki/raw 2>/dev/null | wc -l | tr -d ' ')
    bins=$(git -C "$d" ls-files wiki/raw 2>/dev/null | grep -icE "$BIN_RE" || true)
    # Does .gitignore exclude the document formats? Probe one, don't read rules.
    if git -C "$d" check-ignore -q "wiki/raw/probe.pdf" 2>/dev/null; then
        ignored=yes
    else
        ignored=NO
    fi

    if [ "$tracked" -eq 0 ]; then
        posture="ok — raw not tracked at all"
    elif [ "$bins" -gt 0 ]; then
        posture="** TRACKS $bins BINARIES — the pre-incident posture **"
        bad=1
    elif [ "$ignored" = "NO" ]; then
        posture="at risk — no binary rule; clean only by luck"
        bad=1
    else
        posture="ok — text tracked, binaries excluded"
    fi

    if [ "$ONLY_BAD" = "1" ] && [ "${posture:0:2}" = "ok" ]; then continue; fi
    printf '%-28s %8s %9s %9s  %s\n' "$name" "$tracked" "$bins" "$ignored" "$posture"
done

echo
if [ "$bad" -eq 1 ]; then
    cat <<'EOF'
At least one repo tracks client documents under wiki/raw, or has no rule
preventing it. Apply the mixin block from ~/.claude/mixins/wiki-raw/gitignore
and `git rm --cached` anything already tracked.

Removing it at the tip does not remove it from history. Decide that separately:
a rewrite on a shared branch breaks other clones, and for a private repo with
known collaborators the honest answer is often "leave history, rotate the
secret, record why".
EOF
    exit 1
fi
echo "Every repo with a wiki/raw tree keeps client documents out of git."
