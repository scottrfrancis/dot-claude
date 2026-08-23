#!/usr/bin/env bash
# Round-trip test for make-release.sh.
#
# Reassembles the emitted chunks with an INDEPENDENT implementation that follows
# the same published contract (payload = lines strictly between the BEGIN/END
# markers, concatenated in part order) and asserts the result is byte-identical
# to the source zip. This validates the data contract that the PowerShell script
# also implements.
#
# Runs twice: once at the real chunk size, once at a tiny chunk size that forces
# a multi-chunk split, because the real payload fits in one chunk and would
# otherwise never exercise the splitting path.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:-$HOME/.claude}"
PASS=0; FAIL=0

check() { # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "  PASS  $1"; PASS=$((PASS+1))
  else echo "  FAIL  $1"; echo "          expected: $2"; echo "          actual:   $3"; FAIL=$((FAIL+1)); fi
}

run_case() { # run_case <label> <chunk_bytes>
  local label="$1" bytes="$2"
  local out="$HERE/.test-out-$bytes"
  echo
  echo "CASE: $label (CHUNK_BYTES=$bytes)"

  bash "$HERE/make-release.sh" "$REPO" "$out" "$bytes" >/dev/null 2>&1 || {
    echo "  FAIL  packager exited non-zero"; FAIL=$((FAIL+1)); return
  }

  local zip manifest
  zip="$(ls "$out"/*.zip)"
  manifest="$(ls "$out"/*-MANIFEST.txt)"

  local want_sha nchunks nfound
  want_sha="$(awk '/^zip sha256/{print $NF}' "$manifest")"
  nchunks="$(awk '/^chunks/{print $3}' "$manifest")"
  nfound="$(ls "$out"/*-part*.txt | wc -l | tr -d ' ')"
  check "chunk count matches manifest" "$nchunks" "$nfound"

  # --- independent reassembly, contract-only ---
  local combined="$out/.combined.b64" rebuilt="$out/.rebuilt.zip"
  : > "$combined"
  # shellcheck disable=SC2045
  for p in $(ls "$out"/*-part*.txt | sort -t- -k5); do
    awk '/^-----BEGIN DOT-CLAUDE CHUNK/{f=1;next} /^-----END DOT-CLAUDE CHUNK/{f=0} f' "$p" >> "$combined"
  done
  openssl base64 -d -in "$combined" -out "$rebuilt"

  local got_sha src_sha
  got_sha="$(openssl dgst -sha256 -r "$rebuilt" | awk '{print $1}')"
  src_sha="$(openssl dgst -sha256 -r "$zip"     | awk '{print $1}')"
  check "reassembled == source zip"    "$src_sha" "$got_sha"
  check "reassembled == manifest sha"  "$want_sha" "$got_sha"

  # --- the archive must actually be a working zip ---
  # Count file entries only: git archive writes directory entries too, which
  # git ls-files never reports, so a raw entry count overstates by the number
  # of directories.
  local listed
  listed="$(unzip -Z1 "$rebuilt" 2>/dev/null | grep -vc '/$')"
  local tracked; tracked="$(git -C "$REPO" ls-files | wc -l | tr -d ' ')"
  check "zip contains all tracked files" "$tracked" "$listed"

  # --- no chunk may exceed the byte budget ---
  local over=0 sz
  for p in "$out"/*-part*.txt; do
    sz="$(wc -c < "$p" | tr -d ' ')"
    [ "$sz" -gt "$bytes" ] && over=$((over+1))
  done
  check "no chunk exceeds CHUNK_BYTES" "0" "$over"

  # --- part 1 must carry the PowerShell script, others must not ---
  local p1; p1="$(ls "$out"/*-part01of*.txt)"
  grep -q 'BEGIN-POWERSHELL' "$p1" && check "part01 carries PS script" "yes" "yes" \
                                   || check "part01 carries PS script" "yes" "no"
  if [ "$nfound" -gt 1 ]; then
    local p2 hasps; p2="$(ls "$out"/*-part02of*.txt)"
    hasps=$(grep -c 'BEGIN-POWERSHELL' "$p2" || true)
    check "part02 is data-only" "0" "$hasps"
  fi

  rm -rf "$out"
}

echo "Round-trip verification for make-release.sh"
run_case "real chunk size"      4000000
run_case "forced multi-chunk"     30000

echo
echo "-----------------------------------------"
echo "PASS: $PASS   FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
