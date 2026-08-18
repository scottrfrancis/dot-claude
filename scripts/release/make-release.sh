#!/usr/bin/env bash
# Package the dot-claude repo as base64 .txt chunks for email delivery.
#
# Produces, in OUT_DIR:
#   <base>.zip                        the release archive (git archive of HEAD)
#   <base>-partNNofMM.txt             base64 chunks, each <= CHUNK_BYTES of encoded text
#   <base>-MANIFEST.txt               hashes + chunk inventory (send separately if you can)
#
# Chunk 1 carries the PowerShell reassembly script in its header. Every chunk
# delimits its payload with BEGIN/END markers so headers can never corrupt data.
#
# Usage: make-release.sh [REPO] [OUT_DIR] [CHUNK_BYTES]

set -euo pipefail

OUT_DIR="${2:-$(dirname "$0")/out}"
CHUNK_BYTES="${3:-4000000}"   # 4 MB of *encoded* text, not source bytes

command -v git >/dev/null    || { echo "git not found" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl not found" >&2; exit 1; }

# Resolve the repo. $HOME/.claude is NOT reliable here: profile routing
# (CLAUDE_CONFIG_DIR / a per-account $HOME) points it at a tree of symlinks
# into the canonical checkout, which is not itself a git repo. So probe the
# candidates and take the first that really is one.
is_repo() { [ -n "$1" ] && git -C "$1" rev-parse --git-dir >/dev/null 2>&1; }

if [ -n "${1:-}" ]; then
  REPO="$1"
  is_repo "$REPO" || { echo "Not a git repository: $REPO" >&2; exit 1; }
else
  REAL_HOME="$(dscl . -read "/Users/$(whoami)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  REPO=""
  for c in "$HOME/.claude" "$REAL_HOME/.claude" "$HOME/workspace/dot-claude" "/Volumes/workspace/dot-claude"; do
    if is_repo "$c"; then REPO="$c"; break; fi
  done
  [ -n "$REPO" ] || {
    echo "Could not locate the dot-claude git repository." >&2
    echo "Tried: \$HOME/.claude, \$REAL_HOME/.claude, ~/workspace/dot-claude, /Volumes/workspace/dot-claude" >&2
    echo "Pass the path explicitly: make-release.sh /path/to/.claude" >&2
    exit 1
  }
fi

# Follow symlinks to the real checkout so the archive and the reported paths agree.
REPO="$(git -C "$REPO" rev-parse --show-toplevel)"
echo "Repository: $REPO" >&2

# --- Identify the source commit --------------------------------------------
SHA_FULL="$(git -C "$REPO" rev-parse HEAD)"
SHA="$(git -C "$REPO" rev-parse --short HEAD)"
DATE="$(git -C "$REPO" show -s --format=%cs HEAD)"
BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
BASE="dot-claude-${DATE}-${SHA}"

if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "WARNING: working tree is dirty; archive reflects HEAD, not your working tree." >&2
fi

rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
ZIP="$OUT_DIR/$BASE.zip"

# --- Build the archive (tracked files only -> no secrets by construction) ---
git -C "$REPO" archive --format=zip -o "$ZIP" HEAD
FILE_COUNT="$(git -C "$REPO" ls-files | wc -l | tr -d ' ')"
ZIP_BYTES="$(wc -c < "$ZIP" | tr -d ' ')"
ZIP_SHA="$(openssl dgst -sha256 -r "$ZIP" | awk '{print $1}')"

# --- Encode. openssl wraps at 64 cols, which email clients never re-wrap. ---
B64="$OUT_DIR/.$BASE.b64"
openssl base64 -in "$ZIP" -out "$B64"

# Lines per chunk, derived from the byte budget (65 = 64 chars + newline).
# Reserve 8 KB in chunk 1 for the PowerShell header.
LINES_PER_CHUNK=$(( (CHUNK_BYTES - 8192) / 65 ))
[ "$LINES_PER_CHUNK" -lt 1 ] && { echo "CHUNK_BYTES too small" >&2; exit 1; }

split -l "$LINES_PER_CHUNK" "$B64" "$OUT_DIR/.raw-"
NCHUNKS=$(ls "$OUT_DIR"/.raw-* | wc -l | tr -d ' ')
MM=$(printf '%02d' "$NCHUNKS")

# --- Emit chunks ------------------------------------------------------------
i=0
for raw in "$OUT_DIR"/.raw-*; do
  i=$((i + 1))
  NN=$(printf '%02d' "$i")
  PART="$OUT_DIR/${BASE}-part${NN}of${MM}.txt"

  if [ "$i" -eq 1 ]; then
    sed -e "s|@@BASE@@|$BASE|g" \
        -e "s|@@NCHUNKS@@|$NCHUNKS|g" \
        -e "s|@@ZIPSHA@@|$ZIP_SHA|g" \
        -e "s|@@ZIPBYTES@@|$ZIP_BYTES|g" \
        -e "s|@@SHAFULL@@|$SHA_FULL|g" \
        -e "s|@@BRANCH@@|$BRANCH|g" \
        -e "s|@@DATE@@|$DATE|g" \
        -e "s|@@FILECOUNT@@|$FILE_COUNT|g" \
        "$(dirname "$0")/header.ps1.tmpl" > "$PART"
  else
    {
      echo "# $BASE - chunk $i of $NCHUNKS"
      echo "# Data chunk only. The reassembly script is in part01of${MM}.txt."
      echo "# Do not edit, re-wrap, or reformat the lines below."
      echo
    } > "$PART"
  fi

  {
    echo "-----BEGIN DOT-CLAUDE CHUNK ${i}/${NCHUNKS}-----"
    cat "$raw"
    echo "-----END DOT-CLAUDE CHUNK ${i}/${NCHUNKS}-----"
  } >> "$PART"
done

rm -f "$OUT_DIR"/.raw-* "$B64"

# --- Manifest ---------------------------------------------------------------
{
  echo "dot-claude release manifest"
  echo "==========================="
  echo "archive      : $BASE.zip"
  echo "source commit: $SHA_FULL"
  echo "branch       : $BRANCH  (committed $DATE)"
  echo "tracked files: $FILE_COUNT"
  echo "zip bytes    : $ZIP_BYTES"
  echo "zip sha256   : $ZIP_SHA"
  echo "chunks       : $NCHUNKS  (<= $CHUNK_BYTES bytes of encoded text each)"
  echo
  echo "chunk sha256 (verify each attachment survived transit):"
  for p in "$OUT_DIR/${BASE}"-part*.txt; do
    printf '  %-44s %s  %s bytes\n' "$(basename "$p")" \
      "$(openssl dgst -sha256 -r "$p" | awk '{print $1}')" "$(wc -c < "$p" | tr -d ' ')"
  done
} > "$OUT_DIR/${BASE}-MANIFEST.txt"

cat "$OUT_DIR/${BASE}-MANIFEST.txt"
