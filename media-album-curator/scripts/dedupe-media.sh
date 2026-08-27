#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: dedupe-media.sh <source-dir> [--delete]

Find exact duplicate media files by sha256 hash. Dry-run by default.
When deleting, keeps a preferred file per duplicate group:
  1. name without suffixes like -2, -3, " copy"
  2. older creation/change time
  3. shorter path

Supported extensions: jpg, jpeg, png, heic, mov, mp4
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

src=$1
mode=${2:-}

if [[ ! -d "$src" ]]; then
  echo "source directory not found: $src" >&2
  exit 2
fi

if [[ -n "$mode" && "$mode" != "--delete" ]]; then
  echo "unknown option: $mode" >&2
  usage >&2
  exit 2
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/dedupe-media.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

hashes="$tmp/hashes.tsv"
: > "$hashes"
find -L "$src" -maxdepth 1 -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
  -iname '*.heic' -o -iname '*.mov' -o -iname '*.mp4' \
\) -print0 | while IFS= read -r -d '' file; do
  shasum -a 256 "$file" >> "$hashes"
done

if [[ ! -s "$hashes" ]]; then
  echo "No media files found."
  exit 0
fi

python3 - "$hashes" "$mode" <<'PY'
import os
import re
import sys
from collections import defaultdict

hashes_path, mode = sys.argv[1], sys.argv[2]
groups = defaultdict(list)

with open(hashes_path, "r", encoding="utf-8") as f:
    for line in f:
        digest, path = line.rstrip("\n").split("  ", 1)
        groups[digest].append(path)

def score(path):
    base = os.path.basename(path).lower()
    suffix_penalty = 0
    if re.search(r"(-\d+| copy| copy \d+)\.[^.]+$", base):
        suffix_penalty = 1
    try:
        ctime = os.stat(path).st_ctime
    except FileNotFoundError:
        ctime = 0
    return (suffix_penalty, ctime, len(path), path)

delete = mode == "--delete"
duplicate_groups = 0
delete_count = 0

for digest, paths in sorted(groups.items()):
    if len(paths) < 2:
        continue
    duplicate_groups += 1
    keep = sorted(paths, key=score)[0]
    victims = [p for p in paths if p != keep]
    print(f"\nHASH {digest}")
    print(f"KEEP {keep}")
    for victim in victims:
        print(f"DELETE {victim}")
        delete_count += 1
        if delete:
            try:
                os.remove(victim)
            except FileNotFoundError:
                pass

print(f"\nduplicate groups: {duplicate_groups}")
print(f"{'deleted' if delete else 'would delete'}: {delete_count}")
PY
