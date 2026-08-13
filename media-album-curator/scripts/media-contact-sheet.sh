#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: media-contact-sheet.sh <source-dir> <work-dir> [--today YYYY-MM-DD] [--frames N]

Create contact sheets for local photo/video album review.

Outputs:
  <work-dir>/photos/*.jpg              photo thumbnails
  <work-dir>/videos/<name>/frame_*.jpg video frames
  <work-dir>/videos/*_strip.jpg        video frame strips
  <work-dir>/contact/photos_*.jpg      photo contact sheets
  <work-dir>/contact/videos_*.jpg      video contact sheets

Supported photo inputs: jpg, jpeg, png, heic
Supported video inputs: mov, mp4

Use --today to include files whose creation/change date matches YYYY-MM-DD.
Without --today, all supported files in source-dir are considered.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
  usage
  exit 0
fi

src=$1
work=$2
shift 2
today=""
frames=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --today)
      today=${2:?--today requires YYYY-MM-DD}
      shift 2
      ;;
    --frames)
      frames=${2:?--frames requires a number}
      shift 2
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for tool in ffmpeg ffprobe magick; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing required tool: $tool" >&2
    exit 2
  fi
done

if [[ ! -d "$src" ]]; then
  echo "source directory not found: $src" >&2
  exit 2
fi

mkdir -p "$work/photos" "$work/videos" "$work/contact"

matches_date() {
  local path=$1
  [[ -z "$today" ]] && return 0
  [[ "$(stat -f '%SB' -t '%Y-%m-%d' "$path")" == "$today" ]] && return 0
  [[ "$(stat -f '%Sc' -t '%Y-%m-%d' "$path")" == "$today" ]] && return 0
  [[ "$(stat -f '%Sm' -t '%Y-%m-%d' "$path")" == "$today" ]]
}

convert_photo() {
  local input=$1
  local output=$2
  local ext
  ext=$(printf '%s' "${input##*.}" | tr '[:upper:]' '[:lower:]')
  if [[ "$ext" == "heic" ]]; then
    if command -v sips >/dev/null 2>&1; then
      sips -s format jpeg -s formatOptions 88 -Z 1400 "$input" --out "$output" >/dev/null
    else
      magick "$input" -auto-orient -resize '1400x1400>' -strip -quality 88 "$output"
    fi
  else
    magick "$input" -auto-orient -resize '1400x1400>' -strip -quality 88 "$output"
  fi
}

find -L "$src" -maxdepth 1 -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' \
\) -print0 | while IFS= read -r -d '' file; do
  matches_date "$file" || continue
  base=$(basename "$file")
  convert_photo "$file" "$work/photos/${base%.*}.jpg" || true
done

find -L "$src" -maxdepth 1 -type f \( -iname '*.mov' -o -iname '*.mp4' \) -print0 | while IFS= read -r -d '' file; do
  matches_date "$file" || continue
  base=$(basename "$file")
  stem=${base%.*}
  dir="$work/videos/$stem"
  mkdir -p "$dir"
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$file" | awk '{printf "%.3f", $1}')
  for idx in $(seq 1 "$frames"); do
    ts=$(awk -v d="$duration" -v i="$idx" -v n="$frames" 'BEGIN{printf "%.3f", d*i/(n+1)}')
    ffmpeg -hide_banner -loglevel error -ss "$ts" -i "$file" -frames:v 1 -vf 'scale=900:-1' -q:v 3 "$dir/frame_$(printf %02d "$idx").jpg" || true
  done
  magick montage "$dir"/frame_*.jpg -tile "${frames}x1" -geometry 360x360+8+8 -background white "$work/videos/${stem}_strip.jpg" 2>/dev/null || true
done

make_sheets() {
  local kind=$1
  local pattern=$2
  local max=$3
  local geometry=$4
  local tile=$5
  local batch=1
  local count=0
  local files=()

  while IFS= read -r file; do
    files+=("$file")
    count=$((count + 1))
    if [[ "$count" -eq "$max" ]]; then
      magick montage "${files[@]}" -label '%t' -tile "$tile" -geometry "$geometry" -background white "$work/contact/${kind}_${batch}.jpg"
      batch=$((batch + 1))
      count=0
      files=()
    fi
  done < <(find "$work" -path "$pattern" -type f | sort)

  if [[ "${#files[@]}" -gt 0 ]]; then
    magick montage "${files[@]}" -label '%t' -tile "$tile" -geometry "$geometry" -background white "$work/contact/${kind}_${batch}.jpg"
  fi
}

make_sheets photos "$work/photos/*.jpg" 30 '230x230+14+36' '5x'
make_sheets videos "$work/videos/*_strip.jpg" 18 '520x230+14+40' '3x'

printf 'photo thumbnails: '
find "$work/photos" -maxdepth 1 -type f -name '*.jpg' | wc -l
printf 'video strips: '
find "$work/videos" -maxdepth 1 -type f -name '*_strip.jpg' | wc -l
printf 'contact sheets:\n'
find "$work/contact" -maxdepth 1 -type f | sort
